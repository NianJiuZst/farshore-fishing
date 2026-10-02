"""Make labeled QA montages from unchanged actual saved-master render evidence."""
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[3]
IDS='japanese_whiting marbled_rockfish mandarin_fish largemouth_bass japanese_seabass european_seabass red_seabream black_seabream gilthead_seabream saddled_seabream white_seabream annular_seabream common_pandora red_mullet painted_comber'.split()
VIEWS=['hero','side','top','underside','pose_swim','pose_struggle','pose_breach','pose_landed']
for species in IDS:
    r=ROOT/'ownbuild/fish3d-catalog'/species;b=ROOT/'art_masters/3d'/(species+'.blend');images=[r/(v+'.png') for v in VIEWS]
    n=sum(p.exists() and p.stat().st_mtime>b.stat().st_mtime for p in images)
    print(species,n,'visual signoff exists' if (r/'visual_review.json').exists() else 'not signed off')
    if n!=8:continue
    target=r/'review_contact_sheet.jpg'
    if target.exists() and target.stat().st_mtime>max(p.stat().st_mtime for p in images):continue
    out=Image.new('RGB',(1200,1720),(25,29,32));d=ImageDraw.Draw(out)
    for i,(v,p) in enumerate(zip(VIEWS,images)):
        im=Image.open(p).convert('RGB');im.thumbnail((600,400));x=i%2*600;y=i//2*430;out.paste(im,(x,y+27));d.text((x+12,y+8),species+' / '+v,fill=(236,238,235))
    out.save(target,quality=90)
