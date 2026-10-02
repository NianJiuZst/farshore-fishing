#!/usr/bin/env python3
"""Read-only full-catalog artifact audit; no Blender/Godot import or asset mutation."""
from pathlib import Path
import argparse,json,hashlib,struct
import numpy as np
VIEWS=('hero','top','side','underside','pose_swim','pose_struggle','pose_breach','pose_landed')

def visual_review_status(review,glb_hash,master_hash):
    """Accept the documented family schemas, never infer review from image presence."""
    candidates=[]
    for name in ('review_signoff.json','visual_review.json'):
        path=review/name
        if not path.exists():continue
        errors=[]
        try:
            record=json.loads(path.read_text())
            passed=(record.get('status')=='reviewed_pass' or record.get('visual_result')=='pass' or record.get('visual_review')=='pass')
            if not passed:errors.append('No explicit visual pass status')
            if record.get('glb_sha256',record.get('canonical_glb_sha256'))!=glb_hash:errors.append('Canonical GLB hash missing or stale')
            recorded_master=record.get('master_sha256',record.get('canonical_blend_sha256'))
            if recorded_master is not None and recorded_master!=master_hash:errors.append('Canonical master hash stale')
            reviewed=record.get('reviewed_views',{})
            hashes=dict(reviewed) if isinstance(reviewed,dict) else dict(record.get('view_hashes',{}))
            images=record.get('images',[])
            if images:hashes.update({im['view']:im.get('sha256') for im in images})
            if isinstance(reviewed,list) and any(v not in reviewed for v in VIEWS):errors.append('Reviewed-view list incomplete')
            for view in VIEWS:
                image=review/(view+'.png')
                if not image.exists():errors.append('Missing reviewed image: '+view)
                elif hashes.get(view)!=hashlib.sha256(image.read_bytes()).hexdigest():errors.append('Reviewed image hash missing or stale: '+view)
        except (ValueError,TypeError,KeyError) as error:errors.append('Unreadable review record: '+str(error))
        candidate={'record':name,'passed':not errors,'failures':errors}
        if not errors:return candidate
        candidates.append(candidate)
    return candidates[0] if candidates else {'record':None,'passed':False,'failures':['Missing hash-bound visual review']}
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--require-reviews',action='store_true',help='Also fail for absent, incomplete or stale hash-bound eight-view visual acceptance')
    args=parser.parse_args()
    ROOT=Path(__file__).resolve().parents[2]
    ids=[r['species_id'] for letter in 'abcd' for r in json.loads((ROOT/f'game/data/fish_{letter}.json').read_text())]
    assert len(ids)==44 and len(set(ids))==44
    rows=[];failures=[];geometry={}
    for species in ids:
        row={'species':species,'failures':[]};path=ROOT/'game/assets/3d'/f'{species}.glb';master=ROOT/'art_masters/3d'/f'{species}.blend';review=ROOT/'ownbuild/fish3d-catalog'/species
        if not path.exists() or not master.exists():row['failures'].append('Missing canonical GLB/master');rows.append(row);continue
        data=path.read_bytes();row['glb_bytes']=len(data);row['glb_sha256']=hashlib.sha256(data).hexdigest();row['master_sha256']=hashlib.sha256(master.read_bytes()).hexdigest()
        assert data[:4]==b'glTF' and struct.unpack_from('<I',data,8)[0]==len(data),species
        jlen=struct.unpack_from('<I',data,12)[0];doc=json.loads(data[20:20+jlen]);binbase=20+jlen+8
        def accessor(index):
            a=doc['accessors'][index];view=doc['bufferViews'][a['bufferView']];kind={5120:'i1',5121:'u1',5122:'<i2',5123:'<u2',5125:'<u4',5126:'<f4'}[a['componentType']];width={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']];dtype=np.dtype(kind);stride=view.get('byteStride',width*dtype.itemsize)
            value=np.ndarray((a['count'],width),dtype=dtype,buffer=data,offset=binbase+view.get('byteOffset',0)+a.get('byteOffset',0),strides=(stride,dtype.itemsize))
            if a.get('normalized') and kind!='<f4':value=value.astype(np.float32)/np.iinfo(dtype).max
            return value
        names={a['name'] for a in doc.get('animations',[])};row['clips']=sorted(names)
        if not {'swim','struggle','breach','landed'}<=names:row['failures'].append('Missing named clips')
        if not doc.get('skins'):row['failures'].append('No weighted skin')
        if any('skin' not in n for n in doc['nodes'] if 'mesh' in n):row['failures'].append('Unskinned mesh node')
        row['bones']=len(doc['skins'][0]['joints']) if doc.get('skins') else 0;row['triangles']=0;shapes=[];bounds=[];minimum=1;maximum=1
        for mesh in doc.get('meshes',[]):
            for p in mesh['primitives']:
                attrs=p['attributes'];v=accessor(attrs['POSITION']);bounds.append((v.min(0),v.max(0)));shapes.append(hashlib.sha256(np.round(v,7).tobytes()).hexdigest())
                if 'JOINTS_0' not in attrs or 'WEIGHTS_0' not in attrs:row['failures'].append('Missing skin attributes');continue
                weights=accessor(attrs['WEIGHTS_0']).sum(1);minimum=min(minimum,float(weights.min()));maximum=max(maximum,float(weights.max()))
                if 'indices' in p:row['triangles']+=int(doc['accessors'][p['indices']]['count'])//3
        row['weight_sum_range']=[minimum,maximum]
        if minimum<.999 or maximum>1.001:row['failures'].append('Invalid weight sums')
        lo=np.min([a for a,b in bounds],axis=0);hi=np.max([b for a,b in bounds],axis=0);row['rest_size_xyz']=(hi-lo).tolist()
        if abs(float(hi[0]-lo[0])-1)>.001:row['failures'].append('Not normalized 1m length')
        if min(float(hi[1]-lo[1]),float(hi[2]-lo[2]))<.02:row['failures'].append('Suspiciously flat complete model')
        signature=hashlib.sha256(''.join(sorted(shapes)).encode()).hexdigest();row['geometry_signature']=signature;geometry.setdefault(signature,[]).append(species)
        for animation in doc.get('animations',[]):
            for channel in animation['channels']:
                target=channel['target'];node=doc['nodes'][target['node']]
                if node.get('name') in ('root','FishRig') and target['path']=='translation':
                    out=accessor(animation['samplers'][channel['sampler']]['output'])
                    if np.max(np.ptp(out,axis=0))>1e-6:row['failures'].append('Varying root motion: '+animation['name'])
        report_path=review/'validation.json'
        if not report_path.exists():row['failures'].append('Missing evaluated contact/loop report')
        else:
            report=json.loads(report_path.read_text());row['contact_failures']=report.get('failures',[])
            if report.get('failures'):row['failures'].append('Contact/loop report failed')
            groups=report.get('attachments',{}).get('groups',{})
            if not groups:row['failures'].append('Missing contact groups')
            else:row['max_attachment_distance_m']=max(g['max_distance_m'] for g in groups.values());row['attachment_groups']=len(groups)
            if report.get('glb_sha256') and report['glb_sha256']!=row['glb_sha256']:row['failures'].append('Contact report GLB hash stale')
            if report.get('master_sha256') and report['master_sha256']!=row['master_sha256']:row['failures'].append('Contact report master hash stale')
        if (review/'manifest.json').exists():
            manifest=json.loads((review/'manifest.json').read_text())
            if manifest.get('glb_sha256')!=row['glb_sha256']:row['failures'].append('Manifest GLB hash stale')
        row['required_views_present']=[n for n in VIEWS if (review/(n+'.png')).exists()]
        row['visual_review']=visual_review_status(review,row['glb_sha256'],row['master_sha256'])
        rows.append(row)
    for sig,members in geometry.items():
        if len(members)>1:failures.append('Duplicate exact geometry: '+', '.join(members))
    failures.extend(r['species']+': '+x for r in rows for x in r['failures'])
    review_failures=[r['species']+': '+x for r in rows for x in r.get('visual_review',{'failures':['Missing model review']})['failures']]
    result={'expected':44,'generated':sum('glb_sha256' in r for r in rows),'artifact_contact_pass':sum(not r['failures'] for r in rows),'required_views_present_count':sum(len(r.get('required_views_present',[])) for r in rows),'required_views_total':352,'visual_review_pass':sum(r.get('visual_review',{}).get('passed',False) for r in rows),'visual_review_failures':review_failures,'review_gate_required':args.require_reviews,'maximum_attachment_distance_m':max(r.get('max_attachment_distance_m',0) for r in rows),'failures':failures,'species':rows}
    out=ROOT/'ownbuild/fish3d-catalog/catalog_audit.json';out.write_text(json.dumps(result,indent=2));print(json.dumps({k:v for k,v in result.items() if k!='species'},indent=2))
    raise SystemExit(bool(failures or (args.require_reviews and review_failures)))

if __name__ == "__main__":
    main()
