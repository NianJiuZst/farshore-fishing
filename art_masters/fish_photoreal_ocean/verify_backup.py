#!/usr/bin/env python3
"""Read-only verification for the thirty-ocean-species artwork archive."""
from pathlib import Path
from PIL import Image
import json,hashlib
root=Path(__file__).resolve().parent
repo=root.parent.parent
manifest=json.loads((root/'asset_manifest.json').read_text())
provenance=json.loads((root/'art_provenance.json').read_text())
endpoints=json.loads((root/'manual_endpoints.json').read_text())
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(label,test):
 checks.append({'check':label,'passed':bool(test)})
 if not test:raise AssertionError(label)
ids={e['species_id'] for e in manifest['assets']}
check('complete30',manifest['complete'] and manifest['asset_count']==30 and len(ids)==30)
check('exact master set',ids=={p.stem for p in (root/'masters').glob('*.png')})
check('exact runtime set',ids=={p.stem for p in (root/'runtime').glob('*.png')})
check('exact thumb set',{i+'_thumb' for i in ids}=={p.stem for p in (root/'thumbs').glob('*.png')})
prov={p['species_id']:p for p in provenance['assets']}
check('provenance coverage',set(prov)==ids)
for e in manifest['assets']:
 sid=e['species_id'];master=root/e['master'];runtime=root/e['runtime'];thumb=root/e['thumb']
 check(sid+' full source hash',sha(master)==sha(runtime)==e['sha256']==prov[sid]['master_sha256'])
 check(sid+' thumb hash',sha(thumb)==e['thumb_sha256'])
 im=Image.open(master);ti=Image.open(thumb)
 check(sid+' native high resolution',im.mode=='RGBA' and im.width>=1536 and im.size==(e['width'],e['height']))
 check(sid+' lossless thumb dimensions',ti.mode=='RGBA' and ti.width==512 and ti.size==(e['thumb_width'],e['thumb_height']))
 a=im.getchannel('A');box=a.point(lambda x:255 if x>=24 else 0).getbbox()
 check(sid+' transparent subject',a.getextrema()[0]==0 and box and 0<box[0]<box[2]<im.width and 0<box[1]<box[3]<im.height)
 check(sid+' alpha bounds',list(box)==e['subject_bbox_px'])
 check(sid+' normalized bounds',all(abs(x-y)<1e-12 for x,y in zip(e['subject_bbox_normalized'],[box[0]/im.width,box[1]/im.height,box[2]/im.width,box[3]/im.height])))
 for key in ('nose','tail'):
  xy=endpoints[sid][key]
  check(sid+' '+key+' endpoint',a.getpixel(tuple(xy))>=24 and all(abs(x-y)<1e-12 for x,y in zip(e[key+'_normalized'],[xy[0]/im.width,xy[1]/im.height])))
 check(sid+' ruler and orientation',e['ruler_extent_normalized']==[e['nose_normalized'][0],e['tail_normalized'][0]] and e['nose_normalized'][0]<e['tail_normalized'][0] and e['orientation']=='head_left_tail_right')
 check(sid+' prompt and sources',bool(prov[sid]['prompt']) and e['fact_sources']==prov[sid]['biological_reference_sources'] and bool(e['fact_sources']))
 check(sid+' canonical copies',sha(repo/'game/assets/fish'/master.name)==e['sha256'] and sha(repo/'game/assets/fish'/thumb.name)==e['thumb_sha256'])
for r in json.loads((root/'revision_history.json').read_text())['revisions']:
 check(r['path']+' history hash',sha(root/r['path'])==r['sha256'] and r['status']=='superseded_not_for_runtime')
print(json.dumps({'asset_count':len(ids),'checks':len(checks),'passed':sum(c['passed'] for c in checks),'complete':True}))
