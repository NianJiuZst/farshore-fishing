#!/usr/bin/env python3
"""Archive inspected new-ocean model evidence; refuses stale or incomplete visual signoff."""
from pathlib import Path
import argparse,hashlib,json,subprocess,sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from audit_fish_catalog_3d import audit
sys.path.insert(0,str(Path(__file__).parent))
from audit_fish_catalog import visual_review_status,VIEWS
p=argparse.ArgumentParser();p.add_argument('species',nargs='+');p.add_argument('--baseline',default='1afda37');args=p.parse_args();baseline=subprocess.check_output(['git','rev-parse',args.baseline],cwd=ROOT,text=True).strip();assert len(args.species)==len(set(args.species))==30
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
registry=json.loads((ROOT/'game/data/fish_3d.json').read_text());report_dir=ROOT/'art_masters/reports/ocean_fish3d';report_dir.mkdir(parents=True,exist_ok=True)
rows=[];geometry=set()
for sid in args.species:
 runtime=ROOT/'game/assets/3d'/f'{sid}.glb';master=ROOT/'art_masters/3d'/f'{sid}.blend';review=ROOT/'ownbuild/fish3d-catalog'/sid
 binary=audit(runtime,registry['required_animation_clips']);assert binary['geometry_sha256'] not in geometry;geometry.add(binary['geometry_sha256'])
 visual=visual_review_status(review,sha(runtime),sha(master));assert visual['passed'],(sid,visual)
 manifest=json.loads((review/'manifest.json').read_text());validation=json.loads((review/'validation.json').read_text());signoff=json.loads((review/visual['record']).read_text())
 assert validation['failures']==[] and validation['glb_sha256']==sha(runtime) and validation['master_sha256']==sha(master)
 sheet=ROOT/'art_masters/reports/ocean_contact_sheets'/f'{sid}.jpg';assert sheet.is_file()
 row={'species':sid,'status':'passed','binary':binary,'authoring_master':{'path':str(master.relative_to(ROOT)),'sha256':sha(master),'bytes':master.stat().st_size,'compression':'Blender native zstd'},'manifest':manifest,'evaluated_animation_and_attachment_validation':validation,'visual_review':signoff,'contact_sheet':{'path':str(sheet.relative_to(ROOT)),'sha256':sha(sheet)},'mouth_offset_normalized':registry['models'][sid]['mouth_offset_normalized']}
 (report_dir/f'{sid}.json').write_text(json.dumps(row,indent=2));rows.append(row)
# Use the explicitly preserved user baseline, never a newer integration/backup commit.
tracked=[name for name in subprocess.check_output(['git','ls-tree','-r','--name-only',baseline],cwd=ROOT,text=True).splitlines() if (name.startswith('game/assets/3d/') and name.endswith('.glb')) or (name.startswith('art_masters/3d/') and name.endswith('.blend'))];preserved={}
for name in tracked:
 original=subprocess.check_output(['git','show',baseline+':'+name],cwd=ROOT);expected=hashlib.sha256(original).hexdigest();assert sha(ROOT/name)==expected,'Existing artifact changed: '+name;preserved[name]=expected
original_registry=subprocess.check_output(['git','show',baseline+':game/data/fish_3d.json'],cwd=ROOT,text=True);old=json.loads(original_registry)
assert len(old['models'])==44 and all(registry['models'][sid]==entry for sid,entry in old['models'].items())
assert (ROOT/'game/data/fish_3d.json').read_text().startswith(original_registry[:-9]),'Original registry entry bytes changed'
summary={'status':'passed','preserved_baseline_commit':baseline,'new_species_count':30,'all_species_count':len(registry['models']),'distinct_geometry_count':len(geometry),'rendered_review_views':len(rows)*len(VIEWS),'visually_reviewed_models':len(rows),'required_clips':registry['required_animation_clips'],'new_glb_bytes':sum(r['binary']['bytes'] for r in rows),'new_master_bytes':sum(r['authoring_master']['bytes'] for r in rows),'preserved_existing_registry_entries':44,'preserved_existing_artifact_count':len(preserved),'preserved_existing_artifact_sha256':preserved,'species_reports':[str((report_dir/f'{sid}.json').relative_to(ROOT)) for sid in args.species]}
(ROOT/'art_masters/reports/ocean_fish3d_qa.json').write_text(json.dumps(summary,indent=2));print(json.dumps({k:v for k,v in summary.items() if k not in ('preserved_existing_artifact_sha256','species_reports')},indent=2))
