from pathlib import Path
from PIL import Image
import json,hashlib,subprocess,shutil
root=Path(__file__).resolve().parent
# Existing manifest is the self-contained source of names, morphology and fact URLs.
prior_manifest=json.loads((root/'asset_manifest.json').read_text())
source={f['species_id']:{'name':f['name'],'scientific_name':f['scientific_name'],'morphology':f['morphology_reference'],'sources':f['fact_sources']} for f in prior_manifest['assets']}
master_ids={p.stem for p in (root/'masters').glob('*.png')}
if len(source)!=44 or master_ids!=set(source):
 raise ValueError('Expected all 44 manifest species and matching master PNGs before rebuilding')
# Manually reviewed body endpoints in original image pixels; excludes any barbels.
manual={
 'common_carp':{'nose':[23,509],'tail':[1752,229]},
 'alligator_gar':{'nose':[27,348],'tail':[2023,155]},
 'chinese_sturgeon':{'nose':[13,413],'tail':[2158,57]},
 'olive_flounder':{'nose':[25,458],'tail':[1750,464]}
}
extra=root/'manual_endpoints.json'
if extra.exists(): manual.update(json.loads(extra.read_text()))
entries=[]
for p in sorted((root/'masters').glob('*.png')):
 sid=p.stem
 if sid not in source: continue
 im=Image.open(p); a=im.getchannel('A'); w,h=im.size
 # Ignore numerically negligible alpha residue in generated transparent background.
 box=a.point(lambda x:255 if x>=24 else 0).getbbox()
 runtime=root/'runtime'/p.name; runtime.parent.mkdir(exist_ok=True)
 shutil.copy2(p,runtime)
 thumb=root/'thumbs'/(sid+'_thumb.png'); thumb.parent.mkdir(exist_ok=True)
 subprocess.run(['magick',str(p),'-resize','512x512>',str(thumb)],check=True)
 ti=Image.open(thumb); ta=ti.getchannel('A'); tb=ta.point(lambda x:255 if x>=24 else 0).getbbox()
 ep=manual.get(sid)
 entries.append({'species_id':sid,'name':source[sid]['name'],'scientific_name':source[sid]['scientific_name'],'master':'masters/'+p.name,'runtime':'runtime/'+p.name,'thumb':'thumbs/'+thumb.name,'width':w,'height':h,'thumb_width':ti.width,'thumb_height':ti.height,'thumb_subject_bbox_px':list(tb),'thumb_sha256':hashlib.sha256(thumb.read_bytes()).hexdigest(),'subject_bbox_px':list(box),'subject_bbox_normalized':[box[0]/w,box[1]/h,box[2]/w,box[3]/h],'nose_normalized':([ep['nose'][0]/w,ep['nose'][1]/h] if ep else None),'tail_normalized':([ep['tail'][0]/w,ep['tail'][1]/h] if ep else None),'ruler_extent_normalized':([ep['nose'][0]/w,ep['tail'][0]/w] if ep else None),'alpha_threshold_for_bbox':24,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'transparent_fraction':a.histogram()[0]/(w*h),'morphology_reference':source[sid]['morphology'],'fact_sources':source[sid]['sources']})
manifest={'format_version':1,'generated_on':'2026-10-02','generator':'OpenAI built-in imagegen','purpose':'Photorealistic illustrative encyclopedia and catch-card fish assets. Not diagnostic scientific plates or wild photographs.','orientation':'Head left, tail right except right-eyed European plaice; flatfish shown natural ocular side','variants':'Runtime PNG retains all master pixels and alpha. Thumbnails are Lanczos downscaled by ImageMagick to max512px. No generated imagery is replaced by procedural drawing.','coordinate_system':'All normalized values are relative to full original/runtime canvas, not subject bounding box. Bboxes are [left,top,right,bottom] with right/bottom exclusive. Ruler uses nose/tail x coordinates, excludes whisker extension.','complete':len(entries)==44,'asset_count':len(entries),'assets':entries}
(root/'asset_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
print(json.dumps({'asset_count':len(entries),'missing_endpoint_ids':[e['species_id'] for e in entries if e['nose_normalized'] is None],'total_master_bytes':sum(p.stat().st_size for p in (root/'masters').glob('*.png'))}))
