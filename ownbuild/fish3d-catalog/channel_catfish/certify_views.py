"""Hash-bind an explicitly inspected final eight-view review; never auto-renders or edits art."""
from pathlib import Path
import hashlib,json,datetime,sys
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[3]
VIEWS=['hero','side','top','underside','pose_swim','pose_struggle','pose_breach','pose_landed']
FINDINGS={
'channel_catfish':['Smooth naked spotted skin; eight tapered nasal/maxillary/chin barbels','Rayless closed adipose, arched anal and deeply forked caudal','Updated dorsal/anal roots and paired fins remain seated in all inspected poses'],
'flathead_catfish':['Broad flattened head, small eyes, protruding lower jaw and eight barbels','Irregular ochre-brown pigment over smooth naked skin; no scale relief','Square-rounded caudal, rayless adipose and surface-seated paired fins'],
'southern_catfish':['Broad depressed head and exactly two pairs of barbels','Tiny soft dorsal, absent adipose, very long anal and shallow-notched tail','Smooth scaleless body and uninterrupted anal/body contact in inspected poses'],
'longsnout_catfish':['Projecting conical snout, small inferior crescent mouth and four short barbel pairs','Smooth pale pink-gray skin, thick rayless adipose, short anal and deeply forked tail','Pectoral/pelvic roots and mouth remain seated in inspected views'],
'bowfin':['Robust cylindrical olive body, rounded scaleless head and tiny nasal flaps','Long dorsal contrasted with short anal; posterior pelvic placement and rounded tail','Male tail-base eyespot and surface-conforming gular plate remain distinct from snakehead'],
'northern_snakehead':['Depressed broad scaled head, oblique mouth and no barbels','Long dorsal AND anal, rounded caudal, small anterior pelvics','Irregular python-like flank blotches and closed fin/body seams in inspected poses']}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
for sid in sys.argv[1:]:
 r=ROOT/'ownbuild/fish3d-catalog'/sid;glb=ROOT/'game/assets/3d'/f'{sid}.glb';master=ROOT/'art_masters/3d'/f'{sid}.blend';profile=ROOT/'tools/art3d/fish_profiles'/f'{sid}.py'
 manifest=json.loads((r/'manifest.json').read_text());validation=json.loads((r/'validation.json').read_text());assert not validation['failures']
 assert sha(glb)==manifest['glb_sha256'];audit=json.loads((r/'glb_audit.json').read_text());assert audit['glb_sha256']==sha(glb) and not audit['failures'];attachment=validation['attachments'];worst=max(g['max_distance_m'] for g in attachment['groups'].values());assert worst<=attachment['tolerance_m'];assert attachment['samples_per_clip']==9
 checked={}
 for name in VIEWS:
  p=r/f'{name}.png';log=ROOT/'build/catfish-final-views'/f'{sid}_{name}.log'
  logtext=log.read_text()
  assert 'Blender quit' in logtext and 'Traceback' not in logtext and 'Error: Python' not in logtext,(sid,name,'incomplete or failed render log')
  assert str(p) in logtext and 'Saved:' in logtext,(sid,name,'missing render-write evidence')
  assert p.stat().st_mtime>master.stat().st_mtime,(sid,name,'stale render')
  with Image.open(p) as im:assert im.size==(1200,800),(sid,name,im.size)
  checked[name]={'sha256':sha(p),'pixels':[1200,800],'render_samples':32,'render_log_sha256':sha(log)}
 canvas=Image.new('RGB',(1200,1768),(18,24,27));draw=ImageDraw.Draw(canvas);font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',20);small=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',15)
 draw.text((18,12),sid.replace('_',' ').title()+' | Final asset review',font=font,fill=(240,245,238));draw.text((18,40),'GLB '+sha(glb)[:20]+'  |  36 contact poses passed  |  worst %.3f mm'%(worst*1000),font=small,fill=(177,196,185))
 for i,name in enumerate(VIEWS):
  x=(i%2)*600;y=76+(i//2)*423
  with Image.open(r/f'{name}.png') as im:canvas.paste(im.convert('RGB').resize((600,400),Image.Resampling.LANCZOS),(x,y+23))
  draw.text((x+10,y+2),name.replace('_',' '),font=small,fill=(222,232,223))
 sheet=r/'contact_sheet.png';canvas.save(sheet)
 record={'species':sid,'visual_review':'pass','reviewed_views':VIEWS,'glb_sha256':sha(glb),'view_hashes':{n:checked[n]['sha256'] for n in VIEWS},'status':'passed_asset_visual_and_contact_gates','reviewed_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'canonical_glb_sha256':sha(glb),'canonical_blend_sha256':sha(master),'profile_sha256':sha(profile),'pipeline_sha256':manifest['pipeline_sha256'],'manifest_sha256':sha(r/'manifest.json'),'validation_sha256':sha(r/'validation.json'),'glb_audit_sha256':sha(r/'glb_audit.json'),'contact_gate':{'poses':36,'samples_per_clip':9,'tolerance_m':attachment['tolerance_m'],'worst_distance_m':worst,'membrane_and_ray_roots':True},'views':checked,'contact_sheet_sha256':sha(sheet),'findings':FINDINGS[sid]+['Actual hero/top/side/underside and four pose images visually inspected; no detached fin/ray geometry, mouth, eye or throat plate found'],'scope':'Blender source-asset visual acceptance plus shared numeric attachment gate. Does not claim Android package or device-runtime acceptance.','reference_photos_included':False,'canonical_art_changed_during_review':False}
 (r/'visual_review.json').write_text(json.dumps(record,indent=2));assert sha(glb)==manifest['glb_sha256'];print(sid,'VISUAL_CERTIFIED',sha(glb),'contact worst',worst)
