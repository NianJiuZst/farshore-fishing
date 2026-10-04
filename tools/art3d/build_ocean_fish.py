#!/usr/bin/env python3
"""Build only the new ocean roster, retaining compressed editable masters and full review views."""
import argparse,json,sys
from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).parent))
import fish_pipeline as pipeline
OCEAN_SPECIES = ('atlantic_bluefin_tuna', 'pacific_bluefin_tuna', 'yellowfin_tuna', 'bigeye_tuna', 'albacore', 'skipjack_tuna', 'mahi_mahi', 'wahoo', 'swordfish', 'blue_marlin', 'striped_marlin', 'indo_pacific_sailfish', 'great_barracuda', 'giant_trevally', 'greater_amberjack', 'cobia', 'roosterfish', 'red_snapper', 'giant_grouper', 'dogtooth_tuna', 'yellowtail_kingfish', 'opah', 'great_white_shark', 'scalloped_hammerhead', 'great_hammerhead', 'blue_shark', 'shortfin_mako', 'tiger_shark', 'oceanic_whitetip_shark', 'whitetip_reef_shark')
p=argparse.ArgumentParser();p.add_argument('--species',required=True);p.add_argument('--render',action='store_true');p.add_argument('--review-only',action='store_true');p.add_argument('--samples',type=int,default=20);p.add_argument('--views',default='');args=p.parse_args(sys.argv[sys.argv.index('--')+1:])
assert args.species in OCEAN_SPECIES, 'Ocean builder cannot overwrite legacy species'
if args.review_only:
 module=pipeline.load_profile(args.species);bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art_masters/3d'/f'{args.species}.blend'))
 fish=pipeline.Fish.__new__(pipeline.Fish);fish.profile=module.PROFILE;fish.species=args.species;fish.review=ROOT/'ownbuild/fish3d-catalog'/args.species;fish.rig_object=bpy.data.objects['FishRig'];fish.camera=bpy.data.objects['REVIEW_Camera']
else:
 module=pipeline.load_profile(args.species);module.PROFILE['compress_master']=True
 fish=pipeline.Fish(module.PROFILE);module.anatomy(fish);fish.export()
if args.render or args.review_only:
 bpy.context.scene.render.resolution_x=900;bpy.context.scene.render.resolution_y=600;bpy.context.scene.cycles.use_denoising=False
 fish.render(args.samples,set(args.views.split(',')) if args.views else None)
