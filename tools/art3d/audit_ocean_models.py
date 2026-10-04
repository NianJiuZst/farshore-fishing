#!/usr/bin/env python3
"""Audit the actual 37 newly authored GLBs, including bind and motion data.

Run after build_ocean_diversity.py. This checks binary accessor payloads rather than
trusting the registry or model statistics. It does not claim GPU/device QA.
"""
import argparse
import hashlib
import json
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SIZES = {"SCALAR":1,"VEC2":2,"VEC3":3,"VEC4":4,"MAT4":16}
FORMATS = {5126:"f",5125:"I",5123:"H"}


def glb_read(path):
    raw=path.read_bytes();magic,version,length=struct.unpack_from("<4sII",raw)
    assert (magic,version,length)==(b"glTF",2,len(raw)), "invalid GLB header"
    size,kind=struct.unpack_from("<I4s",raw,12);assert kind==b"JSON"
    doc=json.loads(raw[20:20+size]);binsize,binkind=struct.unpack_from("<I4s",raw,20+size);assert binkind==b"BIN\0"
    binary=raw[28+size:28+size+binsize]
    assert len(binary)==binsize and doc["buffers"][0]["byteLength"]<=len(binary)
    return raw,doc,binary


def values(doc,binary,ai):
    a=doc["accessors"][ai];view=doc["bufferViews"][a["bufferView"]]
    typ=a["type"];fmt=FORMATS[a["componentType"]];n=SIZES[typ]
    start=view.get("byteOffset",0)+a.get("byteOffset",0);stride=view.get("byteStride",struct.calcsize("<"+fmt*n))
    return [struct.unpack_from("<"+fmt*n,binary,start+i*stride) for i in range(a["count"])]


def audit(profile):
    sid=profile["id"];path=ROOT/"game/assets/3d"/(sid+".glb");raw,doc,binary=glb_read(path)
    assert doc.get("extras",{}).get("species_id")==sid,"wrong species payload"
    assert doc.get("extras",{}).get("editable_source")=="tools/art3d/ocean_profiles.json"
    skins=doc["skins"];assert len(skins)==1 and len(skins[0]["joints"])>=12
    joints=skins[0]["joints"];ibm=values(doc,binary,skins[0]["inverseBindMatrices"])
    assert len(ibm)==len(joints)
    parent={child:i for i,node in enumerate(doc["nodes"]) for child in node.get("children",[])}
    def world_origin(i):
        origin=list(doc["nodes"][i].get("translation",[0,0,0]))
        if i in parent:
            above=world_origin(parent[i]);origin=[x+y for x,y in zip(origin,above)]
        return origin
    for i,node in enumerate(joints):
        p=world_origin(node);matrix=ibm[i]
        assert all(abs(matrix[12+k]+p[k])<2e-6 for k in range(3)),"incorrect skin bind inverse"
        assert all(abs(matrix[k]-v)<1e-6 for k,v in ((0,1),(5,1),(10,1),(15,1)))
    pos=[];total_vertices=0;total_triangles=0;weight_count=0;geometry=hashlib.sha256();zero_normals=0
    for mesh in doc["meshes"]:
        for prim in mesh["primitives"]:
            attrs=prim["attributes"];assert set(("POSITION","NORMAL","TEXCOORD_0","JOINTS_0","WEIGHTS_0")).issubset(attrs)
            vertices=values(doc,binary,attrs["POSITION"]);normals=values(doc,binary,attrs["NORMAL"])
            uv=values(doc,binary,attrs["TEXCOORD_0"]);jj=values(doc,binary,attrs["JOINTS_0"]);ww=values(doc,binary,attrs["WEIGHTS_0"])
            assert len(vertices)==len(normals)==len(uv)==len(jj)==len(ww)
            indices=[r[0] for r in values(doc,binary,prim["indices"])];assert len(indices)%3==0 and min(indices)>=0 and max(indices)<len(vertices)
            referenced=set(indices)
            for k,(v,n,j,w) in enumerate(zip(vertices,normals,jj,ww)):
                assert all(math.isfinite(x) for x in v+n+w),"non-finite geometry or weights"
                assert abs(sum(w)-1)<2e-6 and min(w)>=0 and max(j)<len(joints),"invalid joint weights"
                length=math.sqrt(sum(x*x for x in n))
                if length<.01:zero_normals+=1;assert k not in referenced,"referenced zero normal"
                else:assert abs(length-1)<2e-4,"non-unit vertex normal"
            pos+=vertices;total_vertices+=len(vertices);total_triangles+=len(indices)//3;weight_count+=len(ww)
            geometry.update(struct.pack("<"+"f"*(len(vertices)*3),*(x for v in vertices for x in v)))
            geometry.update(struct.pack("<"+"I"*len(indices),*indices))
    lo=[min(v[k] for v in pos) for k in range(3)];hi=[max(v[k] for v in pos) for k in range(3)]
    assert abs(lo[0]+.5)<2e-6 and abs(hi[0]-.5)<2e-6,"length not centered and normalized to 1m"
    assert total_vertices>9000 and total_triangles>15000,"mesh unexpectedly incomplete"
    clips={a["name"]:a for a in doc["animations"]};assert set(clips)=={"swim","struggle","breach","landed"}
    moving_tracks={};durations={}
    for name,anim in clips.items():
        moved=0
        assert len(anim["channels"])==len(joints),"clip missing rig joints"
        for channel in anim["channels"]:
            assert channel["target"]["node"] in joints and channel["target"]["path"]=="rotation"
            sampler=anim["samplers"][channel["sampler"]];times=values(doc,binary,sampler["input"]);rots=values(doc,binary,sampler["output"])
            assert len(times)==len(rots)>=24 and times[0][0]==0
            assert all(a[0]<b[0] for a,b in zip(times,times[1:]))
            assert all(abs(sum(x*x for x in q)-1)<2e-6 for q in rots),"non-unit animation quaternion"
            assert max(abs(x-y) for x,y in zip(rots[0],rots[-1]))<2e-6,"loop discontinuity"
            if max(abs(x-y) for r in rots for x,y in zip(r,rots[0]))>.001:moved+=1
            durations[name]=times[-1][0]
        assert moved>=8,"clip has no meaningful bone animation"
        moving_tracks[name]=moved
    for im in doc["images"]:
        view=doc["bufferViews"][im["bufferView"]];offset=view.get("byteOffset",0)
        assert im.get("mimeType")=="image/png" and binary[offset:offset+8]==b"\x89PNG\r\n\x1a\n"
    assert len(doc["images"])==6,"body and fin PBR texture triplets missing"
    features=doc["extras"]["anatomical_features"]
    if sid=="blue_whale":
        assert any("HorizontalFluke" in f for f in features) and sum("VentralRorqualPleat" in f for f in features)==31
        assert sum("PairedBlowhole" in f for f in features)==2
        assert not any("RaisedRay" in f for f in features),"mammal incorrectly uses fish fin rays"
        assert not any("Operculum" in f for f in features),"whale has fish gill"
    if sid=="barreleye":
        assert "TransparentCranialShield" in features and sum("GreenTubularEye" in f for f in features)==2
        assert sum("OlfactoryCapsule" in f for f in features)==2
    if profile["kind"]=="flatfish":assert sum("UpwardIris" in f for f in features)==2
    if sid=="russells_oarfish":assert not any(f["kind"] in ("caudal","anal") for f in profile["fins"])
    return {"species_id":sid,"glb_sha256":hashlib.sha256(raw).hexdigest(),"geometry_sha256":geometry.hexdigest(),"profile_sha256":hashlib.sha256(json.dumps(profile,sort_keys=True).encode()).hexdigest(),"vertices":total_vertices,"triangles":total_triangles,"weighted_vertices":weight_count,"bones":len(joints),"clips_seconds":durations,"moving_tracks":moving_tracks,"dimensions_m":[b-a for a,b in zip(lo,hi)],"surfaces":sum(len(m["primitives"]) for m in doc["meshes"]),"embedded_pbr_images":len(doc["images"]),"unused_pole_vertices":zero_normals,"bytes":len(raw)}


def repair_unused_normals(profile):
    """Match the builder's safe +Y normal on unused duplicate sphere poles."""
    path=ROOT/"game/assets/3d"/(profile["id"]+".glb");raw,doc,binary=glb_read(path)
    data=bytearray(raw);js_size=struct.unpack_from("<I",raw,12)[0];bin_start=28+js_size;repaired=0
    for mesh in doc["meshes"]:
        for prim in mesh["primitives"]:
            ai=prim["attributes"]["NORMAL"];a=doc["accessors"][ai];view=doc["bufferViews"][a["bufferView"]]
            normals=values(doc,binary,ai);used={r[0] for r in values(doc,binary,prim["indices"])}
            for i,n in enumerate(normals):
                if sum(x*x for x in n)<1e-12:
                    assert i not in used,"refusing to conceal a referenced zero normal"
                    offset=bin_start+view.get("byteOffset",0)+a.get("byteOffset",0)+i*12
                    struct.pack_into("<fff",data,offset,0,1,0);repaired+=1
    if repaired:
        path.write_bytes(data)
        statpath=ROOT/"ownbuild/ocean-model-review"/(profile["id"]+"_stats.json")
        if statpath.is_file():
            stats=json.loads(statpath.read_text());stats["sha256"]=hashlib.sha256(data).hexdigest();statpath.write_text(json.dumps(stats,indent=2)+"\n")
    return repaired


def main():
    parser=argparse.ArgumentParser();parser.add_argument("--species",default="all");parser.add_argument("--repair-unused-normals",action="store_true");args=parser.parse_args()
    source=ROOT/"tools/art3d/ocean_profiles.json";profiles=json.loads(source.read_text())["species"]
    assert len(profiles)==37 and len({p["id"] for p in profiles})==37
    chosen=profiles if args.species=="all" else [p for p in profiles if p["id"] in args.species.split(",")]
    reports=[];errors=[]
    for p in chosen:
        try:
            if args.repair_unused_normals:repair_unused_normals(p)
            reports.append(audit(p))
        except (AssertionError,KeyError,FileNotFoundError) as e:errors.append(p["id"]+": "+str(e))
    if not errors:
        assert len({r["geometry_sha256"] for r in reports})==len(reports),"duplicate new geometry"
    report={"schema_version":1,"source_profile_file":"tools/art3d/ocean_profiles.json","source_profile_file_sha256":hashlib.sha256(source.read_bytes()).hexdigest(),"generator_file":"tools/art3d/build_ocean_diversity.py","generator_file_sha256":hashlib.sha256((ROOT/"tools/art3d/build_ocean_diversity.py").read_bytes()).hexdigest(),"models":reports,"errors":errors,"scope":"Binary structure, geometry, skin binding, animated joint data, anatomical presence and centered rest length. Imported Godot and GPU rendering are separate evidence."}
    dest=ROOT/"ownbuild/ocean-model-review/binary_audit.json";dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(json.dumps(report,indent=2)+"\n")
    for e in errors:print("OCEAN_MODEL_AUDIT_FAIL "+e)
    print("OCEAN_MODEL_AUDIT: %s/%s actual GLB models; errors=%s"%(len(reports),len(chosen),len(errors)))
    if errors:raise SystemExit(1)


if __name__=="__main__":main()
