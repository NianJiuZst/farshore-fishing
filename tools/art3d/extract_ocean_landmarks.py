#!/usr/bin/env python3
"""Extract precise normalized mouth anchors from tagged canonical Blender body vertices.
Transforms Blender author coordinates to runtime glTF/Godot coordinates; touches new entries only.
"""
import bpy,sys,json,argparse,os
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from fish_pipeline import load_profile
p=argparse.ArgumentParser();p.add_argument('--species',nargs='+',required=True);p.add_argument('--write',action='store_true');a=p.parse_args(sys.argv[sys.argv.index('--')+1:]);rows={}
for sid in a.species:
 profile=load_profile(sid).PROFILE;assert 'mouth_anchor' in profile,sid+' missing authored mouth anchor'
 bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art_masters/3d'/f'{sid}.blend'))
 body=[];complete=[]
 for ob in bpy.data.objects:
  if ob.type!='MESH' or not ob.parent or ob.parent.name!='FishRig':continue
  complete.extend(v.co.copy() for v in ob.data.vertices)
  tags=ob.data.attributes.get('fs_body_surface')
  if tags:body.extend(v.co.copy() for i,v in enumerate(ob.data.vertices) if tags.data[i].value==1)
 assert body,sid+' has no tagged authoring body'
 lo=min(v.x for v in body);hi=max(v.x for v in body);section_lo=profile['sections'][0][0];section_hi=profile['sections'][-1][0]
 scale=(hi-lo)/(section_hi-section_lo);offset=section_lo-lo/scale
 x,y,z=profile['mouth_anchor'];anchor=[(x-offset)*scale,z*scale,-y*scale]
 bounds=[(min(v[i] for v in complete),max(v[i] for v in complete)) for i in range(3)]
 assert bounds[0][0]<=anchor[0]<=bounds[0][1] and bounds[2][0]<=anchor[1]<=bounds[2][1]
 rows[sid]={'mouth_offset_normalized':[round(v,7) for v in anchor],'author_mouth_anchor':list(profile['mouth_anchor']),'normalization_scale':scale,'normalization_x_offset':offset}
if a.write:
 registry=ROOT/'game/data/fish_3d.json';doc=json.loads(registry.read_text())
 for sid,row in rows.items():doc['models'][sid]['mouth_offset_normalized']=row['mouth_offset_normalized']
 temporary=registry.with_suffix('.json.tmp');temporary.write_text(json.dumps(doc,indent=2,ensure_ascii=False)+'\n');os.replace(temporary,registry)
out=ROOT/'art_masters/reports/ocean_mouth_landmarks.json';out.parent.mkdir(exist_ok=True,parents=True);out.write_text(json.dumps(rows,indent=2));print(json.dumps(rows,indent=2))
