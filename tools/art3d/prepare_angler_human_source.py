#!/usr/bin/env python3
"""Optional source rebuild using pinned, official MPFB and the CC0 system asset pack.
The ordinary runtime build needs only Blender and the committed packed source.
See docs/ASSETS_3D_ANGLER_LICENSES.md for setup and exact input provenance.
"""
import sys,os,bpy,addon_utils,json,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
MPFB=Path(os.environ['MPFB_SOURCE_DIR']).resolve()
ASSETS=Path(os.environ['MAKEHUMAN_ASSET_DIR']).resolve()
PIN='afb9f530a7c2741dedb8df0ebae2e0b183caec21'
if subprocess.check_output(['git','-C',str(MPFB),'rev-parse','HEAD'],text=True).strip()!=PIN:raise RuntimeError('Use the pinned official MPFB commit '+PIN)
AUTHORING=ROOT/'build/mpfb-authoring';AUTHORING.mkdir(parents=True,exist_ok=True)
from mathutils import Vector
sys.path.insert(0,str(MPFB/'src'))
bpy.utils.extension_path_user=lambda package,**kw:str(AUTHORING)
addon_utils.enable('mpfb',default_set=True)
from mpfb.services.humanservice import HumanService
from mpfb.services.targetservice import TargetService
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
macro=TargetService.get_default_macro_info_dict();macro.update(gender=1.0,age=.55,muscle=.58,weight=.47,proportions=.55)
macro['race']={'caucasian':.75,'asian':.20,'african':.05}
h=HumanService.create_human(macro_detail_dict=macro)
rig=HumanService.add_builtin_rig(h,'game_engine')
assets=str(ASSETS)
HumanService.set_character_skin(assets+'/skins/middleage_caucasian_male/middleage_caucasian_male.mhmat',h,skin_type='GAMEENGINE')
for category,n,atype in [('eyes','low-poly','Eyes'),('eyebrows','eyebrow001','Eyebrows'),('hair','short02','Hair'),('clothes','male_casualsuit05','Clothes'),('clothes','shoes02','Clothes')]:
 p=assets+'/'+category+'/'+n+'/'+n+'.mhclo'
 if category=='eyes':p=assets+'/eyes/'+n+'/'+n+'.mhclo'
 print('ASSET',p,flush=True)
 HumanService.add_mhclo_asset(p,h,asset_type=atype,material_type='GAMEENGINE',subdiv_levels=1 if category!='hair' else 0)
print('BONES',json.dumps({b.name:{'head':list(rig.matrix_world@b.head_local),'tail':list(rig.matrix_world@b.tail_local)}for b in rig.data.bones}),flush=True)
# Editable generation source retains MPFB shape controls and weight groups, packed assets.
for image in bpy.data.images:
 if image.source=='FILE':image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art_masters/3d/angler_human_source.blend'),compress=False)
