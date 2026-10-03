"""Original Farshore 30-bone rig and five analytically solved fishing performances.
The formal character retains the runtime interface; the cast wind-up is in front of
the natural-width field jacket so the support hand clears the opposite sleeve.
"""
import bpy, math
from math import sin,cos,pi
from mathutils import Vector, Matrix
bone_spec={}
def bone(name,head,tail,parent=None): bone_spec[name]=(Vector(head),Vector(tail),parent)
# Rest pose: both hands form a single longitudinal two-handed fishing grip.
bone('root',(0,0,0),(0,0,.16))
bone('pelvis',(0,0,.83),(0,0,1.02),'root'); bone('spine',(0,0,1.02),(0,0,1.22),'pelvis'); bone('chest',(0,0,1.22),(0,0,1.42),'spine'); bone('neck',(0,0,1.42),(0,.01,1.51),'chest'); bone('head',(0,.01,1.51),(0,.025,1.73),'neck')
rod_dir=Vector((0,.84,.54)).normalized(); handR=Vector((.115,.40,1.14)); handL=handR-rod_dir*.18
for sign,s in [(1,'R'),(-1,'L')]:
 shoulder=Vector((sign*.195,0,1.385)); hand=handR if s=='R' else handL
 # Equal bilateral anatomy. Rest elbows are solved from real segment lengths, not guessed.
 upper_length=.305; forearm_length=.270; axis=(hand-shoulder).normalized(); dist=(hand-shoulder).length
 along=(upper_length**2-forearm_length**2+dist**2)/(2*dist)
 pole=Vector((sign*.5,-.1,-.9)); bend=(pole-axis*pole.dot(axis)).normalized()
 elbow=shoulder+axis*along+bend*math.sqrt(upper_length**2-along**2)
 bone('clavicle.'+s,(sign*.055,0,1.405),shoulder,'chest'); bone('upper_arm.'+s,shoulder,elbow,'clavicle.'+s); bone('forearm.'+s,elbow,hand,'upper_arm.'+s); bone('hand.'+s,hand,hand+rod_dir*.09,'forearm.'+s)
 bone('thigh.'+s,(sign*.09,-.015,.895),(sign*.108,.018,.49),'pelvis'); bone('shin.'+s,(sign*.108,.018,.49),(sign*.123,-.012,.12),'thigh.'+s); bone('foot.'+s,(sign*.123,-.012,.12),(sign*.123,.16,.08),'shin.'+s)

for sign,side in [(1,'R'),(-1,'L')]:
 wr=bone_spec['hand.'+side][0];d=rod_dir;across=Vector((1,0,0));toward=-across.cross(d).normalized()
 for f in range(4):
  base=wr+d*((f-1.5)*.019+.038)+across*sign*.042
  end=base-across*sign*.065+toward*.011
  bone(f'finger_{f+1}.{side}',base,end,'hand.'+side)
 bone('thumb.'+side,wr+d*.068+across*sign*.035,wr+d*.061-across*sign*.019+toward*.025,'hand.'+side)

def create_rig():
 global scene, rig, armdata, bind, FPS
 scene=bpy.context.scene
 armdata=bpy.data.armatures.new('FarshoreAnglerSkeleton'); rig=bpy.data.objects.new('AnglerRig',armdata); scene.collection.objects.link(rig)
 bpy.context.view_layer.objects.active=rig; rig.select_set(True); bpy.ops.object.mode_set(mode='EDIT')
 for n,(h,t,parent) in bone_spec.items():
  b=armdata.edit_bones.new(n); b.head=h; b.tail=t
  if parent: b.parent=armdata.edit_bones[parent]
  # Stable roll is essential for predictable exported animation.
  b.align_roll(Vector((0,-rod_dir.z,rod_dir.y)) if n.startswith('hand.') else Vector((0,1,0)))
 bpy.ops.object.mode_set(mode='OBJECT'); rig.show_in_front=True
 # Socket is a real glTF node parented to the right hand. Local Blender +Y -> Godot -Z.
 socket=bpy.data.objects.new('RodSocket',None); scene.collection.objects.link(socket); socket.empty_display_type='ARROWS'; socket.empty_display_size=.12
 socket.parent=rig; socket.parent_type='BONE'; socket.parent_bone='hand.R'
 # Child-of-bone includes its length translation, so solve using the explicit parent matrix.
 bpy.context.view_layer.update(); pb=rig.pose.bones['hand.R']
 # Node axes: x lateral, y rod direction, z cross. This exports to a Godot basis with -Z toward tip.
 xaxis=Vector((1,0,0)); yaxis=rod_dir; zaxis=xaxis.cross(yaxis).normalized(); xaxis=yaxis.cross(zaxis).normalized()
 S=Matrix(((xaxis.x,yaxis.x,zaxis.x,handR.x),(xaxis.y,yaxis.y,zaxis.y,handR.y),(xaxis.z,yaxis.z,zaxis.z,handR.z),(0,0,0,1)))
 parentworld=rig.matrix_world@pb.matrix@Matrix.Translation((0,pb.length,0)); socket.matrix_basis=parentworld.inverted()@S
 bind={n:b.matrix_local.copy() for n,b in armdata.bones.items()}
 rig.animation_data_create();FPS=30;scene.render.fps=FPS
 bake_animations()
 return rig,socket
def set_local_euler(n,angles):
 p=rig.pose.bones[n]; p.rotation_mode='XYZ'; p.rotation_euler=angles

def pose_world(n,m):
 pb=rig.pose.bones[n]; par=pb.parent
 if par:
  local=bind[par.name].inverted()@bind[n]
  pb.matrix_basis=local.inverted()@par.matrix.inverted()@m
 else: pb.matrix_basis=bind[n].inverted()@m

def oriented_bone(n,head,tail,rollhint=Vector((0,1,0))):
 Y=(tail-head).normalized(); X=Y.cross(rollhint)
 if X.length<.02: X=Y.cross(Vector((1,0,0)))
 X.normalize(); Z=X.cross(Y).normalized()
 m=Matrix(((X.x,Y.x,Z.x,head.x),(X.y,Y.y,Z.y,head.y),(X.z,Y.z,Z.z,head.z),(0,0,0,1)))
 pose_world(n,m)

def lerpkeys(keys,t):
 for i in range(len(keys)-1):
  if keys[i][0]<=t<=keys[i+1][0]:
   a=keys[i]; b=keys[i+1]; u=(t-a[0])/(b[0]-a[0]); u=u*u*(3-2*u)
   return [a[j]+(b[j]-a[j])*u for j in range(1,len(a))]
 return list(keys[-1][1:])

def perform(clip,t,duration):
 for p in rig.pose.bones:
  p.rotation_mode='QUATERNION'; p.rotation_quaternion=(1,0,0,0); p.location=(0,0,0); p.scale=(1,1,1)
 phase=t/duration*2*pi
 target=handR.copy(); d=rod_dir.copy(); chestlean=0; twist=0
 if clip=='cast':
  # seconds, right hand x/y/z, rod elevation in radians, lean, axial twist
  v=lerpkeys([(0,.115,.40,1.14,.572,0,0),(.34,.16,.28,1.35,1.22,-.055,-.11),(.78,.03,.35,1.53,2.14,-.13,-.21),(1.0,.02,.37,1.54,1.97,-.1,-.16),(1.20,.115,.50,1.32,.48,.12,.09),(1.42,.105,.53,1.20,.20,.075,.04),(1.78,.115,.44,1.14,.45,.025,0),(2.2,.115,.40,1.14,.572,0,0)],t)
  target=Vector(v[:3]); d=Vector((0,cos(v[3]),sin(v[3]))); chestlean=v[4]; twist=v[5]
 elif clip=='lift':
  v=lerpkeys([(0,.115,.40,1.14,.572,0),(0.35,.12,.39,1.30,.9,-.05),(.9,.14,.27,1.49,1.32,-.105),(1.45,.12,.26,1.47,1.27,-.09),(2.0,.115,.40,1.14,.572,0)],t)
  target=Vector(v[:3]); d=Vector((0,cos(v[3]),sin(v[3]))); chestlean=v[4]
 elif clip=='reel':
  target+=Vector((.007*sin(phase),.013*cos(phase),.026*sin(phase))); d=Vector((0,cos(.66+.035*sin(phase)),sin(.66+.035*sin(phase)))); chestlean=-.035+.022*sin(phase); twist=.018*sin(phase)
 elif clip=='wait':
  target+=Vector((.005*sin(phase),.009*sin(phase),.005*cos(phase))); chestlean=.01*sin(phase)
 else:
  target+=Vector((.006*sin(phase),.006*sin(phase),.009*sin(phase))); chestlean=.009*sin(phase); twist=.009*sin(phase)
 # Blender front is +Y. Negative x rotation leans into water; positive leans back.
 set_local_euler('spine',(chestlean*.38,0,twist*.45)); set_local_euler('chest',(chestlean*.62,0,twist*.55)); set_local_euler('head',(-chestlean*.25,.01*sin(phase),-.012*sin(phase)))
 bpy.context.view_layer.update()
 for sign,s in [(1,'R'),(-1,'L')]:
  n='upper_arm.'+s; parent=rig.pose.bones['clavicle.'+s]; shoulder=(parent.matrix@(bind[parent.name].inverted()@bind[n])).translation
  wrist=target if s=='R' else target-d*.18
  if clip=='reel' and s=='L':
   # Free left hand follows a 5.2 cm crank circle; right remains on the grip.
   crank_phase=t*2*pi*1.5
   wrist=target-d*.085+Vector((-.08,.046*cos(crank_phase),.046*sin(crank_phase)))
  a=(bone_spec[n][1]-bone_spec[n][0]).length; b=(bone_spec['forearm.'+s][1]-bone_spec['forearm.'+s][0]).length
  V=wrist-shoulder; dist=min(V.length,a+b-.001); axis=V.normalized()
  along=(a*a-b*b+dist*dist)/(2*dist); height=math.sqrt(max(0,a*a-along*along))
  elbowhint=Vector((sign*.5,-.1,-.9)); perp=(elbowhint-axis*elbowhint.dot(axis)).normalized(); elbow=shoulder+axis*along+perp*height
  oriented_bone(n,shoulder,elbow); bpy.context.view_layer.update(); oriented_bone('forearm.'+s,elbow,wrist); bpy.context.view_layer.update()
  # Hand orientation is shared with the rod, keeping contact consistent throughout casting.
  oriented_bone('hand.'+s,wrist,wrist+d*.09,Vector((0,-d.z,d.y))); bpy.context.view_layer.update()
 # All channels baked on the actual deformation bones.


def bake_animations():
 clips={'idle':3.2,'cast':2.2,'wait':4.0,'reel':2.0,'lift':2.0}
 for clip,dur in clips.items():
  action=bpy.data.actions.new(clip); rig.animation_data.action=action
  count=round(dur*FPS)
  for i in range(count+1):
   scene.frame_set(i+1); perform(clip,i/FPS,dur)
   for p in rig.pose.bones:
    # Store consistent quaternion curves, avoiding rotation mode ambiguity.
    if p.rotation_mode!='QUATERNION':
     q=p.rotation_euler.to_quaternion(); p.rotation_mode='QUATERNION'; p.rotation_quaternion=q
    p.keyframe_insert('location',frame=i+1,group=p.name); p.keyframe_insert('rotation_quaternion',frame=i+1,group=p.name); p.keyframe_insert('scale',frame=i+1,group=p.name)
  for fc in action.fcurves:
   for k in fc.keyframe_points:k.interpolation='LINEAR'
  action.use_fake_user=True
  track=rig.animation_data.nla_tracks.new(); track.name=clip; st=track.strips.new(clip,1,action); track.mute=True
 rig.animation_data.action=bpy.data.actions['idle']; scene.frame_set(1); scene.frame_end=97
