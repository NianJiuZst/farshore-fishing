#!/usr/bin/env python3
"""Build the realistic Farshore angler from the packed, CC0 MakeHuman source.
Run with Blender 4.3: blender -b --python tools/art3d/build_angler.py
Set ANGLER_CANDIDATE=1 to write only review outputs; see docs/ASSETS_3D_ANGLER.md.
"""
import bpy,os,math,json
from mathutils import Vector,Matrix
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),'../..'))
OUT=os.environ.get('ANGLER_REVIEW_DIR',ROOT+'/build/angler-realistic/final');os.makedirs(OUT,exist_ok=True)
CANDIDATE=os.environ.get('ANGLER_CANDIDATE','0')=='1'
MASTER_PATH=OUT+'/angler.blend' if CANDIDATE else ROOT+'/art_masters/3d/angler.blend'
GLB_PATH=OUT+'/angler.glb' if CANDIDATE else ROOT+'/game/assets/3d/angler.glb'
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.open_mainfile(filepath=ROOT+'/art_masters/3d/angler_human_source.blend')
sources=[o for o in bpy.context.scene.objects if o.type=='MESH']; source_rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
source_rig.name='MPFB_source_rig'
# Keep only the forearm/hand skin below the fitted cuffs. The authored clothing
# mask remains active on torso and legs to prevent skin breaking through jeans.
human=next(o for o in sources if o.name=='Human')
human_groups={g.index:g.name for g in human.vertex_groups}
keep_wrists=[]
for vertex in human.data.vertices:
 if any((human_groups[g.group].startswith(('hand_','index_','middle_','ring_','pinky_','thumb_')) and g.weight>.01)or(human_groups[g.group].startswith('lowerarm_')and g.weight>.75)for g in vertex.groups):keep_wrists.append(vertex.index)
human.vertex_groups['Delete.male_casualsuit05'].remove(keep_wrists)
# Get a fully evaluated mesh, with the exact source weights and all supplied UVs.
bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get()
meshes=[]
for o in sources:
 for m in o.modifiers:
  if m.type=='ARMATURE':m.show_viewport=False

  if m.type=='SUBSURF':m.levels=1
bpy.context.view_layer.update()
for o in sources:
 ev=o.evaluated_get(deps);new=bpy.data.meshes.new_from_object(ev,preserve_all_data_layers=True,depsgraph=deps)
 o.modifiers.clear();o.data=new; meshes.append(o)
 if 'male_casualsuit05' in o.name:
  import bmesh
  bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.0002);bm.to_mesh(o.data);bm.free()
# Build the existing runtime skeleton and five native performances.
import sys
sys.path.insert(0,os.path.dirname(__file__))
from angler_motion import create_rig
rig,socket=create_rig();rig.animation_data.action=None
for tr in rig.animation_data.nla_tracks:tr.mute=True
for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
rig.location=(0,0,0)
rot=Matrix.Rotation(math.pi,4,'Z')
# Rest transformations for each source deformation group.
bmap={'Root':'root','pelvis':'pelvis','spine_01':'spine','spine_02':'spine','spine_03':'chest','neck_01':'neck','head':'head'}
trans={}
def bone_world(n):
 b=source_rig.data.bones[n];return rot@(source_rig.matrix_world@b.head_local),rot@(source_rig.matrix_world@b.tail_local)
def transform_segment(n,h,t,scale_length=True):
 sh,st=bone_world(n);R=(st-sh).rotation_difference(t-h).to_matrix().to_4x4()
 if scale_length:
  axis=(st-sh).normalized();ratio=(t-h).length/(st-sh).length
  S=Matrix.Identity(3)
  for i in range(3):
   for j in range(3):S[i][j]+=(ratio-1)*axis[i]*axis[j]
  R=R@S.to_4x4()
 return Matrix.Translation(h)@R@Matrix.Translation(-sh)
# Preserve natural head/neck proportions, with small depth alignment only.
for n in bmap:
 trans[n]=Matrix.Identity(4)
 if n=='head':trans[n]=Matrix.Translation((0,-.012,0))
 if n=='neck_01':trans[n]=Matrix.Translation((0,-.005,0))
rod=Vector((0,.84,.54)).normalized();toward=Vector((0,rod.z,-rod.y))
for side,sign in [('R',1),('L',-1)]:
 s=side.lower()
 for sn,tn in [('clavicle','clavicle'),('upperarm','upper_arm'),('lowerarm','forearm'),('hand','hand'),('thigh','thigh'),('calf','shin'),('foot','foot'),('ball','foot')]:bmap[sn+'_'+s]=tn+'.'+side
 for sn,tn in [('upperarm','upper_arm'),('lowerarm','forearm'),('thigh','thigh'),('calf','shin')]:
  tb=rig.data.bones[tn+'.'+side];h=tb.head_local.copy();t=tb.tail_local.copy()
  if sn=='lowerarm':t+=Vector((sign*.032,0,0))+toward*.04
  trans[sn+'_'+s]=transform_segment(sn+'_'+s,h,t)
 trans['clavicle_'+s]=Matrix.Identity(4)
 # Translate feet to the new stance without changing a boot's natural proportions.
 sh,st=bone_world('foot_'+s);trans['foot_'+s]=Matrix.Translation((sign*.123-sh.x,0,0))
 trans['ball_'+s]=trans['foot_'+s]
 # Retain connected human palms, sculpt the closed grip from their 15 phalange bones.
 wr=rig.data.bones['hand.'+side].head_local.copy();sw,_=bone_world('hand_'+s)
 index,_=bone_world('index_01_'+s);pinky,_=bone_world('pinky_01_'+s);middle,_=bone_world('middle_01_'+s)
 sy=(middle-sw).normalized();sx=index-pinky;sx=(sx-sy*sx.dot(sy)).normalized();sz=sx.cross(sy).normalized()
 tx=sign*rod;ty=-toward;tz=tx.cross(ty).normalized()
 A=Matrix((tx,ty,tz)).transposed()@Matrix((sx,sy,sz)).transposed().inverted()
 handM=Matrix.Translation(wr+Vector((sign*.032,0,0))+toward*.045)@A.to_4x4()@Matrix.Translation(-sw)
 trans['hand_'+s]=handM
 for f,tn in [('index','finger_1'),('middle','finger_2'),('ring','finger_3'),('pinky','finger_4')]:
  sh,_=bone_world(f+'_01_'+s);base=handM@sh
  base.x=wr.x+sign*.032
  # MCP positions retain the human hand's width along the rod.
  axial=(base-wr).dot(rod);base=wr+rod*axial+Vector((sign*.032,0,0))-toward*.033
  points=[base,wr+rod*axial+Vector((sign*.005,0,0))-toward*.035,wr+rod*axial-Vector((sign*.023,0,0))-toward*.014,wr+rod*axial-Vector((sign*.018,0,0))+toward*.011]
  for j in range(3):
   n=f+'_'+str(j+1).zfill(2)+'_'+s;bmap[n]=tn+'.'+side;trans[n]=transform_segment(n,points[j],points[j+1])
 # Opposing thumb sits diagonally across the top of the grip.
 th,_=bone_world('thumb_01_'+s);base=handM@th
 pts=[base,wr+rod*.050+Vector((sign*.018,0,0))+toward*.016,wr+rod*.042-Vector((sign*.007,0,0))+toward*.020,wr+rod*.019-Vector((sign*.015,0,0))+toward*.005]
 for j in range(3):
  n='thumb_'+str(j+1).zfill(2)+'_'+s;bmap[n]='thumb.'+side;trans[n]=transform_segment(n,pts[j],pts[j+1])
for o in meshes:
 groups={g.index:g.name for g in o.vertex_groups};assign=[]
 for v in o.data.vertices:
  p=rot@(o.matrix_world@v.co);weighted=[(groups[g.group],g.weight)for g in v.groups if groups[g.group] in trans and g.weight>.00001]
  if 'male_casualsuit05' in o.name:
   # A field jacket cuff follows the forearm, never the gripping fingers.
   weighted=[(('lowerarm_'+n[-1]) if n.startswith(('hand_','index_','middle_','ring_','pinky_','thumb_')) else n,w)for n,w in weighted]
   for side in ['r','l']:
    sh,st=bone_world('lowerarm_'+side);axis=(st-sh).normalized();along=(p-sh).dot(axis)
    if any(n=='lowerarm_'+side for n,w in weighted):
     shorten=max(0,min(1,(along-(st-sh).length+.08)/.08))*.040
     p-=axis*shorten
  total=sum(w for n,w in weighted)
  if total==0:weighted=[('head',1)];total=1
  out=Vector((0,0,0));target={}
  for n,w in weighted:
   out+=(trans[n]@p)*(w/total);dest=bmap[n];target[dest]=target.get(dest,0)+w/total
  v.co=out;assign.append(target)
 o.parent=None;o.matrix_world=Matrix.Identity(4);o.vertex_groups.clear()
 for name in set(n for d in assign for n in d):
  vg=o.vertex_groups.new(name=name)
  for i,d in enumerate(assign):
   if name in d:vg.add([i],d[name],'REPLACE')
 for p in o.data.polygons:p.use_smooth=True
 o.parent=rig
 if o.name=='Human':
  polish=o.vertex_groups.new(name='Wrist surface polish')
  for vertex,target in zip(o.data.vertices,assign):
   weight=max(target.get('hand.R',0),target.get('hand.L',0))
   if weight>.02:polish.add([vertex.index],weight,'REPLACE')
  smooth=o.modifiers.new('Relax retargeted wrist transitions','SMOOTH');smooth.factor=.6;smooth.iterations=5;smooth.vertex_group=polish.name
 mod=o.modifiers.new('Farshore skeletal deformation','ARMATURE');mod.object=rig
bpy.data.objects.remove(source_rig,do_unlink=True)
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=int(os.environ.get("ANGLER_SAMPLES","64"));scene.cycles.use_denoising=False
scene.render.resolution_x=900;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX'
world=bpy.data.worlds.new('Review world');world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.18,.22,.26,1);world.node_tree.nodes['Background'].inputs[1].default_value=.4;scene.world=world
for name,loc,power,size in [('Key',(3,4,5),450,4),('Fill',(-3,2,2.5),300,3),('Rim',(1,-3,3),450,2)]:
 d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.001));ground=bpy.context.object;ground.name='REVIEW ONLY studio floor';m=bpy.data.materials.new('Slate floor');m.diffuse_color=(.055,.085,.105,1);ground.data.materials.append(m)
d=bpy.data.cameras.new('ReviewCamera');cam=bpy.data.objects.new('ReviewCamera',d);scene.collection.objects.link(cam);scene.camera=cam;d.type='ORTHO';d.ortho_scale=2.15

# Preview only rod follows the real socket.
mat=bpy.data.materials.new('Rod graphite');mat.diffuse_color=(.025,.035,.03,1)
for name,start,end,r in [('grip',(0,-.20,0),(0,.18,0),.016),('shaft',(0,.18,0),(0,1.7,0),.005)]:
 a=Vector(start);b=Vector(end);bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=r,depth=(b-a).length);o=bpy.context.object;o.name='REVIEW ONLY '+name;o.parent=socket;o.location=(a+b)/2;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();o.data.materials.append(mat)
def render(n,loc,clip='idle',f=1):
 rig.animation_data.action=bpy.data.actions[clip];scene.frame_set(f);cam.location=loc;cam.rotation_euler=(Vector((0,.05,.9))-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=OUT+'/'+n+'.png';bpy.ops.render.render(write_still=True)
# Practical rough fabrics, skin, and worn outdoor footwear.
for material in bpy.data.materials:
 if material.use_nodes:
  for node in material.node_tree.nodes:
   if node.type=='BSDF_PRINCIPLED':
    node.inputs['Roughness'].default_value=.82 if any(n in material.name.lower()for n in ['suit','shoes','short02'])else .57
    # MPFB's game material wires Alpha even for fully opaque maps. Exporting
    # those as BLEND disables depth writes in Godot and corrupts this joined
    # mesh's surface order. Solid surfaces must be genuinely opaque; authored
    # eye/hair/brow cutouts use a node-based clip that glTF exports as MASK.
    alpha=node.inputs['Alpha'];links=material.node_tree.links
    cutout=any(name in material.name.lower()for name in ['low-poly','eyebrow','short02'])
    incoming=alpha.links[0].from_socket if alpha.is_linked else None
    for link in list(alpha.links):links.remove(link)
    if cutout and incoming is not None:
     clip=material.node_tree.nodes.new('ShaderNodeMath');clip.name='Depth-writing alpha cutout';clip.operation='GREATER_THAN';clip.inputs[1].default_value=.35
     links.new(incoming,clip.inputs[0]);links.new(clip.outputs[0],alpha)
    else:alpha.default_value=1.0
    material.surface_render_method='DITHERED'
# Ground via visible geometry bounds.
rig.animation_data.action=bpy.data.actions['idle'];scene.frame_set(1);bpy.context.view_layer.update()
lowest=min((o.matrix_world@v).z for o in meshes for v in [Vector(c)for c in o.bound_box]);rig.location.z=-lowest
for im in bpy.data.images:
 if im.source=='FILE' and im.packed_file is None:im.pack()
# Remove unused data inherited from the source generator and pack selected textures.
bpy.context.preferences.filepaths.save_version=0
bpy.ops.outliner.orphans_purge(do_local_ids=True,do_linked_ids=True,do_recursive=True)
cam.location=(2.5,4,2.1);cam.rotation_euler=(Vector((0,.05,.9))-cam.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.wm.save_as_mainfile(filepath=MASTER_PATH,compress=False)
# Export one batched skinned mesh and a real bone-attached RodSocket.
bpy.ops.object.select_all(action='DESELECT');runtime_parts=[]
for source in meshes:
 obj=source.copy();obj.data=source.data.copy();scene.collection.objects.link(obj)
 for modifier in list(obj.modifiers):
  if modifier.type!='ARMATURE':
   bpy.context.view_layer.objects.active=obj;obj.select_set(True);bpy.ops.object.modifier_apply(modifier=modifier.name);obj.select_set(False)
 obj.select_set(True);runtime_parts.append(obj)
bpy.context.view_layer.objects.active=runtime_parts[0];bpy.ops.object.join();runtime=runtime_parts[0];runtime.name='Angler_Skinned_Mesh'
rig.select_set(True);socket.select_set(True);bpy.context.view_layer.objects.active=rig
for track in rig.animation_data.nla_tracks:track.mute=False
bpy.ops.export_scene.gltf(filepath=GLB_PATH,export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_nla_strips=True,export_skins=True,export_apply=True,export_force_sampling=True,export_frame_range=False,export_anim_slide_to_zero=True,export_def_bones=True,export_yup=True,export_morph=False,export_cameras=False,export_lights=False)
triangles=sum(len(p.vertices)-2 for p in runtime.data.polygons)
images=[{'name':im.name,'width':im.size[0],'height':im.size[1]}for im in bpy.data.images if im.packed_file]
with open(OUT+'/stats.json','w')as file:json.dump({'triangles':triangles,'bones':len(rig.data.bones),'materials':len(runtime.data.materials),'textures':images,'glb_bytes':os.path.getsize(GLB_PATH),'clips':{'idle':3.2,'cast':2.2,'wait':4.0,'reel':2.0,'lift':2.0}},file,indent=2)
bpy.data.objects.remove(runtime,do_unlink=True)
for track in rig.animation_data.nla_tracks:track.mute=True
if os.environ.get('ANGLER_SKIP_RENDERS')=='1':raise SystemExit(0)
render('front',(0,4,1.3));render('side',(4,0,1.3));render('cast',(2.5,4,2.1),'cast',24);render('cast-side',(4,0,1.5),'cast',24);render('release',(2.5,4,2.1),'cast',37);render('fight',(2.5,4,2.1),'reel',16);render('lift',(2.5,4,2.1),'lift',29)
# A near view makes cuff edges and both closed grips reviewable.
cam.data.ortho_scale=.8;scene.render.resolution_x=1200;scene.render.resolution_y=900
rig.animation_data.action=bpy.data.actions['cast'];scene.frame_set(24)
target=Vector((.02,.36,1.4));cam.location=target+Vector((2,3,1));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=OUT+'/grip-close.png';bpy.ops.render.render(write_still=True)
print('ANGLER_BUILD_COMPLETE',flush=True)
