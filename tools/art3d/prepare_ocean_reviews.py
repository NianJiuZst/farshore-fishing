#!/usr/bin/env python3
"""Prepare eight-view ocean contact sheets and hash indexes, never auto-approve art."""
from pathlib import Path
import argparse,json,hashlib
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[2]
VIEWS=('hero','side','top','underside','pose_swim','pose_struggle','pose_breach','pose_landed')
p=argparse.ArgumentParser();p.add_argument('species',nargs='+');a=p.parse_args()
font_path='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
font=ImageFont.truetype(font_path,17);title=ImageFont.truetype(font_path,25)
out=ROOT/'art_masters/reports/ocean_contact_sheets';out.mkdir(parents=True,exist_ok=True)
for sid in a.species:
 review=ROOT/'ownbuild/fish3d-catalog'/sid
 if any(not (review/(v+'.png')).exists() for v in VIEWS):continue
 sheet=Image.new('RGB',(1800,708),(18,29,37));draw=ImageDraw.Draw(sheet);draw.text((18,10),sid.replace('_',' ').upper(),font=title,fill=(230,239,241))
 hashes={}
 for i,v in enumerate(VIEWS):
  path=review/(v+'.png');im=Image.open(path).convert('RGB');im.thumbnail((448,298))
  x=(i%4)*450;y=48+(i//4)*330;sheet.paste(im,(x,y));draw.text((x+10,y+302),v,font=font,fill=(223,236,239));hashes[v]=hashlib.sha256(path.read_bytes()).hexdigest()
 sheet.save(out/(sid+'.jpg'),quality=92)
 record={'species':sid,'status':'awaiting_visual_review','glb_sha256':hashlib.sha256((ROOT/'game/assets/3d'/f'{sid}.glb').read_bytes()).hexdigest(),'master_sha256':hashlib.sha256((ROOT/'art_masters/3d'/f'{sid}.blend').read_bytes()).hexdigest(),'view_hashes':hashes}
 (review/'review_candidate.json').write_text(json.dumps(record,indent=2))
 print(sid)
if len(a.species)==30 and all((ROOT/'ownbuild/fish3d-catalog'/sid/'hero.png').is_file() for sid in a.species):
 overview=Image.new('RGB',(1800,1640),(18,29,37));draw=ImageDraw.Draw(overview);draw.text((20,12),'FARSHORE | 30 OCEAN SPECIES | ORIGINAL ANIMATED 3D MODELS',font=title,fill=(233,241,243))
 for i,sid in enumerate(a.species):
  im=Image.open(ROOT/'ownbuild/fish3d-catalog'/sid/'hero.png').convert('RGB');im.thumbnail((358,238));x=(i%5)*360;y=55+(i//5)*263;overview.paste(im,(x,y));draw.text((x+7,y+240),sid.replace('_',' '),font=font,fill=(223,236,239))
 overview.save(ROOT/'art_masters/reports/ocean_species_overview.jpg',quality=94)
