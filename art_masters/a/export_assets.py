import json,shutil,hashlib
from pathlib import Path
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[2]
recs=json.loads((root/'art_masters/a/generation_records.json').read_text())
species={x['species_id']:x for x in json.loads((root/'game/data/fish_a.json').read_text())}
manifest=[]
for r in recs:
 id=r['species_id'];src=Path(r['source_file'])
 master=root/f'art_masters/a/{id}.png'
 if not master.exists():
  assert src.is_file(),src
  shutil.copy2(src,master)
 im=Image.open(master).convert('RGBA');alpha=im.getchannel('A');assert alpha.getextrema()[0]==0
 runtime=im.copy();runtime.thumbnail((1024,1024),Image.Resampling.LANCZOS);runtime.save(root/f'game/assets/fish/{id}.png',optimize=True)
 thumb=im.copy();thumb.thumbnail((256,256),Image.Resampling.LANCZOS);thumb.save(root/f'game/assets/fish/{id}_thumb.png',optimize=True)
 manifest.append(dict(asset_id=id,usage='fish codex detail and catch display',runtime_path=f'game/assets/fish/{id}.png',thumbnail_path=f'game/assets/fish/{id}_thumb.png',master_path=f'art_masters/a/{id}.png',master_dimensions=list(im.size),runtime_dimensions=list(runtime.size),thumbnail_dimensions=list(thumb.size),alpha_extrema=list(alpha.getextrema()),alpha_zero_fraction=alpha.histogram()[0]/(im.width*im.height),generation_method='OpenAI built-in image_gen; one species per call',generation_prompt=r['prompt'],generation_edits=r.get('edits',[]),reference_sources=species[id]['sources'],reference_images_used=[],license_status='Original AI-generated artwork; no external photographs copied or embedded. Provider terms apply; no claim of guaranteed exclusivity or copyrightability. Source webpages referenced for facts only.',review_status='visual_review_completed',anatomy_review=r.get('review','Complete left-facing species-specific silhouette, mouth, fins, markings and normal eye checked; illustrative rather than diagnostic plate.'),used_by=species[id]['art'],sha256=hashlib.sha256((root/f'game/assets/fish/{id}.png').read_bytes()).hexdigest()))
(root/'docs/ASSETS_A.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
# Review sheet is internal QA only, not a runtime image or substitute artwork.
w=1000;h=((len(recs)+1)//2)*280
sheet=Image.new('RGB',(w,h),'#eee9dc');draw=ImageDraw.Draw(sheet)
for i,r in enumerate(recs):
 im=Image.open(root/f"game/assets/fish/{r['species_id']}.png").convert('RGBA');im.thumbnail((470,235),Image.Resampling.LANCZOS)
 x=(i%2)*500+15;y=(i//2)*280+25;sheet.paste(im,(x+(470-im.width)//2,y),im);draw.text((x,y-20),r['species_id'],fill='#273d39')
sheet.save(root/'art_masters/a/review_sheet.png')
print(json.dumps([{'id':m['asset_id'],'alpha':m['alpha_extrema'],'zero':round(m['alpha_zero_fraction'],3),'size':m['runtime_dimensions']} for m in manifest]))
