#!/usr/bin/env python3
"""Build lossless derivatives and source metadata from generated PNGs; never draws fish."""
from pathlib import Path
from PIL import Image
import json, hashlib, shutil, subprocess
root=Path(__file__).resolve().parent
repo=root.parent.parent
specs=json.loads((root/'generation_specs.json').read_text())
endpoints=json.loads((root/'manual_endpoints.json').read_text())
fish={f['species_id']:f for filename in ('fish_e.json','fish_f.json') for f in json.loads((repo/'game/data'/filename).read_text())}
assert set(specs)==set(endpoints)=={p.stem for p in (root/'masters').glob('*.png')}
assert len(specs)==30
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
entries=[]; provenance=[]; revisions=[]
for sid in sorted(specs):
 p=root/'masters'/f'{sid}.png'; im=Image.open(p)
 assert im.mode=='RGBA' and im.width>=1536
 alpha=im.getchannel('A'); bbox=alpha.point(lambda x:255 if x>=24 else 0).getbbox()
 assert bbox and alpha.getextrema()[0]==0
 assert 0<bbox[0]<bbox[2]<im.width and 0<bbox[1]<bbox[3]<im.height
 ep=endpoints[sid]; w,h=im.size
 for xy in (ep['nose'],ep['tail']):assert alpha.getpixel(tuple(xy))>=24
 assert ep['nose'][0]<ep['tail'][0]
 runtime=root/'runtime'/p.name;shutil.copy2(p,runtime)
 thumb=root/'thumbs'/f'{sid}_thumb.png'
 subprocess.run(['magick',str(p),'-filter','Lanczos','-resize','512x512>',str(thumb)],check=True)
 ti=Image.open(thumb).convert('RGBA');ta=ti.getchannel('A');tb=ta.point(lambda x:255 if x>=24 else 0).getbbox()
 assert ti.width==512
 shutil.copy2(p,repo/'game/assets/fish'/p.name);shutil.copy2(thumb,repo/'game/assets/fish'/thumb.name)
 sp=specs[sid]; f=fish[sid]
 entry={'species_id':sid,'name':f['name'],'scientific_name':f['scientific_name'],'master':'masters/'+p.name,'runtime':'runtime/'+p.name,'thumb':'thumbs/'+thumb.name,'width':w,'height':h,'thumb_width':ti.width,'thumb_height':ti.height,'thumb_subject_bbox_px':list(tb),'thumb_sha256':sha(thumb),'subject_bbox_px':list(bbox),'subject_bbox_normalized':[bbox[0]/w,bbox[1]/h,bbox[2]/w,bbox[3]/h],'nose_normalized':[ep['nose'][0]/w,ep['nose'][1]/h],'tail_normalized':[ep['tail'][0]/w,ep['tail'][1]/h],'ruler_extent_normalized':[ep['nose'][0]/w,ep['tail'][0]/w],'alpha_threshold_for_bbox':24,'sha256':sha(p),'transparent_fraction':alpha.histogram()[0]/(w*h),'orientation':'head_left_tail_right','morphology_reference':f['morphology'],'fact_sources':sp['sources']}
 entries.append(entry)
 prompts=[(root/f'{sid}_prompt.txt').read_text().strip()]
 for rp in sorted(root.glob(sid+'_revision*_prompt.txt'), key=lambda p: (p.name!=sid+'_revision_prompt.txt',p.name)):prompts.append(rp.read_text().strip())
 prov={'species_id':sid,'master_path':'masters/'+p.name,'master_sha256':sha(p),'prompt':prompts[0],'revision_prompts':prompts[1:],'anatomy_review':'Generated full-body output visually reviewed for orientation, silhouette, species-specific head/fins/tail/color and safe framing; alpha inspected numerically and on #edf0e4 review composites. Coordinates selected at alpha-extremal anatomical nose/bill and tail tissue after visual review. Illustrative review, not scientific certification.','biological_reference_sources':sp['sources']}
 provenance.append(prov)
 for old in sorted((root/'revision_history').glob(sid+'_*.png')):revisions.append({'species_id':sid,'path':str(old.relative_to(root)),'sha256':sha(old),'status':'superseded_not_for_runtime','final_master_sha256':sha(p)})
manifest={'format_version':1,'generated_on':'2026-10-04','generator':'OpenAI built-in imagegen','purpose':'Photorealistic illustrative fish encyclopedia and catch-card assets, not actual wildlife photographs or diagnostic scientific plates.','orientation':'Head left, tail right; hammerhead cephalofoils have natural slight visible foreshortening.','variants':'Full runtime PNGs are byte-identical to accepted generated masters. Lossless RGBA PNG thumbnails use ImageMagick Lanczos to maximum 512 pixels. No procedural fish drawing, recoloring, upscaling or species-reuse substitution.','coordinate_system':'Normalized coordinates are relative to full original canvas. Bboxes [left,top,right,bottom] have exclusive right/bottom edges. Ruler spans foremost anatomical nose/bill to farthest natural tail tip; no whisker extension.','complete':True,'asset_count':30,'assets':entries}
(root/'asset_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
provenance_doc={'generator':'OpenAI built-in imagegen','generated_date':'2026-10-04','generation_type':'30 separate species-specific original generations plus targeted imagegen revisions; no atlas, reused different-species image or procedural replacement.','originals_preserved':True,'copyright_provenance':'New AI-generated artwork created for Farshore Fishing. No third-party fish photograph was downloaded or embedded. Biological sources inform species morphology and make no image licensing claim. No Creative Commons or public-domain status asserted.','image_source_note':'Accepted generated PNG bytes preserved in masters and runtime. Prompts, biological references, revision originals and SHA256 identities are recorded. Private provider paths/output hints are not distributed.','assets':provenance}
(root/'art_provenance.json').write_text(json.dumps(provenance_doc,ensure_ascii=False,indent=2)+'\n')
(root/'revision_history.json').write_text(json.dumps({'revisions':revisions},ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'asset_count':len(entries),'full_widths':[min(e['width'] for e in entries),max(e['width'] for e in entries)],'master_bytes':sum((root/e['master']).stat().st_size for e in entries),'revision_count':len(revisions),'manifest_sha256':sha(root/'asset_manifest.json')}))
