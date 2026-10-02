#!/usr/bin/env python3
"""Independent binary audit of every expected fish GLB, with an explicit full-release gate.
Geometry uniqueness is a duplicate-file guard, not a substitute for anatomy review.
"""
from pathlib import Path
import argparse, hashlib, json, math, struct
from content_3d_contract import glb_contract

COMPONENTS={5120:('b',1),5121:('B',1),5122:('h',2),5123:('H',2),5125:('I',4),5126:('f',4)}
WIDTHS={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}

def unpack_glb(path):
    raw=path.read_bytes(); doc=None; binary=None; at=12
    while at<len(raw):
        size,kind=struct.unpack_from('<II',raw,at); chunk=raw[at+8:at+8+size]
        if kind==0x4e4f534a:doc=json.loads(chunk)
        elif kind==0x004e4942:binary=chunk
        at+=size+8
    assert doc is not None and binary is not None,'GLB needs JSON and embedded binary'
    return doc,binary

def accessor(doc,binary,index):
    a=doc['accessors'][index]; assert 'sparse' not in a,'Sparse accessor needs explicit support'
    view=doc['bufferViews'][a['bufferView']]; fmt,n=COMPONENTS[a['componentType']]; w=WIDTHS[a['type']]
    offset=view.get('byteOffset',0)+a.get('byteOffset',0); stride=view.get('byteStride',n*w)
    rows=[struct.unpack_from('<'+fmt*w,binary,offset+i*stride) for i in range(a['count'])]
    if a.get('normalized'):
        maximum={5121:255,5123:65535}.get(a['componentType'])
        assert maximum,'Unsupported normalized component'
        rows=[tuple(v/maximum for v in row) for row in rows]
    return rows

def audit(path,clips):
    summary=glb_contract(path,clips); doc,binary=unpack_glb(path)
    geometry=hashlib.sha256(); weights=[]; triangles=0
    for mesh in doc['meshes']:
        for p in mesh['primitives']:
            attrs=p.get('attributes',{}); assert 'POSITION' in attrs,'No real vertex geometry'
            positions=accessor(doc,binary,attrs['POSITION'])
            assert all(all(math.isfinite(v) for v in row) for row in positions),'Non-finite vertices'
            for row in positions:geometry.update(struct.pack('<3f',*row))
            if p.get('mode',4)==4:
                triangles+=(doc['accessors'][p['indices']]['count'] if 'indices' in p else len(positions))//3
            if 'WEIGHTS_0' in attrs:
                rows=accessor(doc,binary,attrs['WEIGHTS_0']); assert len(rows)==len(positions)
                assert all(all(math.isfinite(v) and 0<=v<=1.00001 for v in row) for row in rows)
                sums=[sum(row) for row in rows]; assert all(abs(v-1)<0.001 for v in sums),'Unnormalized skin weights'
                weights.extend(sums)
    assert triangles>=1000,'Insufficient real fish geometry'
    durations={}
    for animation in doc.get('animations',[]):
        if animation.get('name') not in clips:continue
        ends=[]
        for sample in animation['samplers']:
            times=[v[0] for v in accessor(doc,binary,sample['input'])]
            assert all(math.isfinite(t) for t in times) and all(a<=b for a,b in zip(times,times[1:]))
            ends.append(times[-1]-times[0])
        durations[animation['name']]=max(ends)
    for name,duration in {'swim':2.0,'struggle':1.2,'breach':1.4,'landed':3.0}.items():
        assert abs(durations[name]-duration)<0.04,f'Unexpected {name} duration'
    summary.update(geometry_sha256=geometry.hexdigest(),triangles=triangles,weight_sum_min=min(weights),weight_sum_max=max(weights),clip_seconds=durations)
    return summary

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--project',type=Path,default=Path('game'));ap.add_argument('--output',type=Path,required=True);ap.add_argument('--require-all',action='store_true');args=ap.parse_args()
    manifest=json.loads((args.project/'data/fish_3d.json').read_text()); catalog={}
    for p in sorted((args.project/'data').glob('fish_[abcd].json')):
        catalog.update({x['species_id']:x for x in json.loads(p.read_text())})
    assert set(catalog)==set(manifest['models']) and len(catalog)==44
    report={'required_species':44,'full_release_gate':args.require_all,'models':{},'missing':[],'failures':[],'scope':'Independent binary geometry, weighted skin, animation sampling and duplicate-geometry audit; anatomy and rendered appearance require separate visual review.'}
    seen={}
    for id,info in manifest['models'].items():
        path=args.project/info['scene'].removeprefix('res://')
        if not path.is_file():report['missing'].append(id);continue
        try:
            result=audit(path,manifest['required_animation_clips']);digest=result['geometry_sha256']
            assert digest not in seen,f'Geometry identical to {seen.get(digest)}'
            seen[digest]=id;report['models'][id]=result
        except Exception as exc:report['failures'].append({'species':id,'reason':str(exc)})
    report['full_catalog_complete']=not report['missing'] and not report['failures'] and len(report['models'])==44
    args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({'checked_models':len(report['models']),'missing':len(report['missing']),'failures':report['failures'],'full_catalog_complete':report['full_catalog_complete'],'full_release_gate':args.require_all}))
    return int(bool(report['failures']) or (args.require_all and not report['full_catalog_complete']))
if __name__=='__main__':raise SystemExit(main())
