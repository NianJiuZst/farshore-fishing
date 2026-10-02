#!/usr/bin/env python3
"""Farshore original mesh angler. Run: blender --background --python tools/art3d/build_angler.py
All forms, weights, and performances are authored here. No image planes or external assets.
"""
import bpy, math, os, json
from mathutils import Vector, Matrix, Quaternion
from math import sin, cos, pi
ROOT=os.path.abspath(os.path.join(os.path.dirname(__file__),'../..'))
OUT=os.path.join(ROOT,'build/angler-review'); os.makedirs(OUT,exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
for data in list(bpy.data.materials): bpy.data.materials.remove(data)
bpy.context.preferences.filepaths.save_version=0
scene=bpy.context.scene; scene.render.engine='CYCLES'; scene.cycles.samples=64; scene.cycles.use_denoising=False
scene.render.resolution_x=1000; scene.render.resolution_y=1200; scene.render.resolution_percentage=100
scene.world.color=(.16,.18,.22); scene.render.image_settings.file_format='PNG'; scene.view_settings.view_transform='AgX'
M={}
def mat(name,color,rough=.6,metal=0):
 m=bpy.data.materials.new(name); m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*color,1); p.inputs['Roughness'].default_value=rough; p.inputs['Metallic'].default_value=metal
 M[name]=m; return m
mat('Jacket · glacial teal',(.035,.23,.235),.68)
mat('Jacket · highlight panels',(.065,.31,.30),.72)
mat('Jacket · seam binding',(.021,.10,.12),.8)
mat('Shirt · warm sandstone',(.61,.58,.47),.85)
mat('Shirt · seam',(.38,.36,.29),.87)
mat('Trousers · umber canvas',(.22,.17,.125),.84)
mat('Trousers · reinforced knees',(.165,.135,.108),.88)
mat('Boots · oiled leather',(.15,.079,.039),.52)
mat('Boots · rubber sole',(.032,.037,.034),.9)
mat('Boots · laces',(.54,.43,.26),.9)
mat('Skin · warm tan',(.55,.32,.205),.54)
mat('Skin · cheeks',(.50,.255,.16),.63)
mat('Skin · lip',(.32,.135,.096),.58)
mat('Hair · chestnut',(.075,.046,.027),.9)
mat('Eyes · ivory',(.78,.75,.64),.35)
mat('Eyes · hazel',(.095,.115,.059),.33)
mat('Eyes · pupil',(.006,.009,.008),.23)
mat('Stitch · flax',(.58,.47,.29),.85)
mat('Metal · antique brass',(.48,.32,.12),.35,.65)
mat('Cap · ochre badge',(.70,.38,.11),.69)
mat('Review · backdrop',(.075,.11,.135),.82)
mesh_objects=[]; bone_spec={}
def mesh(name,verts,faces,material,weights=None,subd=0):
 data=bpy.data.meshes.new(name); data.from_pydata(verts,[],faces); data.update()
 obj=bpy.data.objects.new(name,data); scene.collection.objects.link(obj); obj.data.materials.append(M[material]); mesh_objects.append(obj)
 for p in data.polygons: p.use_smooth=True
 if weights:
  names=set(k for d in weights for k in d)
  for n in names:
   g=obj.vertex_groups.new(name=n)
   for i,d in enumerate(weights):
    if d.get(n,0)>0: g.add([i],d[n],'REPLACE')
 if subd:
  mod=obj.modifiers.new('Tailored surface smoothing','SUBSURF'); mod.levels=subd; mod.render_levels=subd
 return obj

def ellipsoid(name,center,scale,material,bone,segments=24,rings=14,rotation=None):
 verts=[]; faces=[]; C=Vector(center); R=rotation if rotation else Matrix.Identity(3)
 for j in range(rings+1):
  t=pi*j/rings
  for i in range(segments):
   a=2*pi*i/segments; v=Vector((sin(t)*cos(a)*scale[0],sin(t)*sin(a)*scale[1],cos(t)*scale[2])); verts.append(tuple(C+R@v))
 for j in range(rings):
  for i in range(segments):
   a=j*segments+i; b=j*segments+(i+1)%segments; faces.append((a+segments,b+segments,b,a))
 return mesh(name,verts,faces,material,[{bone:1} for _ in verts] if bone else None)

def rings_z(name,rings,material,wfun,segments=32,subd=1):
 verts=[]; faces=[]; weights=[]
 for j,(x,y,z,rx,ry) in enumerate(rings):
  for i in range(segments):
   a=2*pi*i/segments; verts.append((x+rx*cos(a),y+ry*sin(a),z)); weights.append(wfun(z,j))
 for j in range(len(rings)-1):
  for i in range(segments):
   a=j*segments+i; b=j*segments+(i+1)%segments; faces.append((a,b,b+segments,a+segments))
 faces += [tuple(reversed(range(segments))),tuple((len(rings)-1)*segments+i for i in range(segments))]
 return mesh(name,verts,faces,material,weights,subd)

def sweep(name,points,radii,material,bones,segments=16,subd=1):
 P=[Vector(p) for p in points]; verts=[]; faces=[]; weights=[]
 for j,p in enumerate(P):
  tangent=(P[min(j+1,len(P)-1)]-P[max(0,j-1)]).normalized(); side=tangent.cross(Vector((0,1,0)))
  if side.length<.05: side=tangent.cross(Vector((1,0,0)))
  side.normalize(); up=tangent.cross(side).normalized(); r=radii[j]; r=(r,r) if isinstance(r,(int,float)) else r
  for i in range(segments):
   a=2*pi*i/segments; verts.append(tuple(p+side*r[0]*cos(a)+up*r[1]*sin(a))); weights.append(bones[j] if isinstance(bones,list) else {bones:1})
 for j in range(len(P)-1):
  for i in range(segments):
   a=j*segments+i; b=j*segments+(i+1)%segments; faces.append((a,b,b+segments,a+segments))
 faces += [tuple(reversed(range(segments))),tuple((len(P)-1)*segments+i for i in range(segments))]
 return mesh(name,verts,faces,material,weights,subd)

def line(name,points,radius,material,bone):
 return sweep(name,points,[radius]*len(points),material,bone,segments=8,subd=0)

def panel(name,points,material,bone,thickness=.005,bevel=.01):
 verts=[tuple(Vector(p)+Vector((0,s*thickness/2,0))) for s in (-1,1) for p in points]; n=len(points)
 faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
 o=mesh(name,verts,faces,material,[{bone:1} for _ in verts]); mod=o.modifiers.new('Soft sewn edges','BEVEL'); mod.width=bevel; mod.segments=3
 o.modifiers.new('Panel normals','WEIGHTED_NORMAL'); return o

def bone(name,head,tail,parent=None): bone_spec[name]=(Vector(head),Vector(tail),parent)
# Rest pose: both hands form a single longitudinal two-handed fishing grip.
bone('root',(0,0,0),(0,0,.16))
bone('pelvis',(0,0,.83),(0,0,1.02),'root'); bone('spine',(0,0,1.02),(0,0,1.22),'pelvis'); bone('chest',(0,0,1.22),(0,0,1.42),'spine'); bone('neck',(0,0,1.42),(0,.01,1.51),'chest'); bone('head',(0,.01,1.51),(0,.025,1.73),'neck')
rod_dir=Vector((0,.84,.54)).normalized(); handR=Vector((.115,.40,1.14)); handL=handR-rod_dir*.18
for sign,s in [(1,'R'),(-1,'L')]:
 shoulder=Vector((sign*.235,0,1.355)); elbow=Vector((sign*.31,.12,1.105)); hand=handR if s=='R' else handL
 bone('clavicle.'+s,(sign*.045,0,1.36),shoulder,'chest'); bone('upper_arm.'+s,shoulder,elbow,'clavicle.'+s); bone('forearm.'+s,elbow,hand,'upper_arm.'+s); bone('hand.'+s,hand,hand+rod_dir*.09,'forearm.'+s)
 bone('thigh.'+s,(sign*.115,0,.88),(sign*.125,.016,.48),'pelvis'); bone('shin.'+s,(sign*.125,.016,.48),(sign*.135,-.015,.12),'thigh.'+s); bone('foot.'+s,(sign*.135,-.015,.12),(sign*.135,.16,.08),'shin.'+s)
# Full skinned pelvis and torso, sewn structured vest over the inner shirt.
rings_z('Canvas seat and hips',[(0,0,.79,.15,.097),(0,0,.80,.165,.107),(0,0,.91,.183,.115),(0,0,.995,.156,.10)],'Trousers · umber canvas',lambda z,j:{'pelvis':1})
rings_z('Sandstone shirt body',[(0,0,.98,.147,.09),(0,0,1.05,.168,.105),(0,0,1.25,.19,.098),(0,0,1.36,.18,.08),(0,0,1.415,.07,.058)],'Shirt · warm sandstone',lambda z,j:{'spine':max(0,min(1,(1.30-z)/.25)),'chest':max(0,min(1,(z-1.05)/.25))})
# Vest has custom open front seam with contrasting central shirt visible.
verts=[]; faces=[]; weights=[]
bodyrings=[(.995,.163,.106),(1.01,.172,.116),(1.075,.18,.121),(1.20,.204,.123),(1.315,.215,.116),(1.365,.198,.100),(1.405,.078,.074)]
for j,(z,rx,ry) in enumerate(bodyrings):
 for i in range(41):
  a=pi/2+.13+(2*pi-.26)*i/40
  verts.append((rx*cos(a),ry*sin(a),z))
  chest=max(0,min(1,(z-1.08)/.21)); weights.append({'spine':1-chest,'chest':chest})
for j in range(len(bodyrings)-1):
 for i in range(40): a=j*41+i; faces.append((a,a+1,a+42,a+41))
vest=mesh('Tailored open front fishing vest',verts,faces,'Jacket · glacial teal',weights,1)
sol=vest.modifiers.new('Bound textile thickness','SOLIDIFY'); sol.thickness=.008
# Inner zipper, piping and gathered lower welt.
line('Zipper center',[(0,.113,1.014),(0,.132,1.16),(0,.115,1.32),(0,.078,1.396)],.004,'Metal · antique brass','chest')
for sign,s in [(1,'R'),(-1,'L')]:
 line('Front vest piping '+s,[(sign*.022,.116,1.012),(sign*.025,.126,1.19),(sign*.030,.114,1.325),(sign*.028,.076,1.405)],.006,'Jacket · seam binding','chest')
 #panel('Shoulder reinforcement '+s,[(sign*.064,.076,1.385),(sign*.182,.084,1.36),(sign*.185,.112,1.305),(sign*.073,.113,1.305)],'Jacket · highlight panels','chest',.006,.012)
 x=sign*.105
 panel('Expandable chest pocket '+s,[(x-.052,.121,1.18),(x+.052,.121,1.18),(x+.06,.13,1.294),(x-.052,.13,1.294)],'Jacket · highlight panels','chest',.022,.009)
 panel('Chest pocket flap '+s,[(x-.056,.149,1.279),(x,.155,1.263),(x+.056,.149,1.28),(x+.056,.141,1.306),(x-.056,.141,1.306)],'Jacket · glacial teal','chest',.008,.006)
 ellipsoid('Pocket snap '+s,(x,.163,1.282),(.006,.004,.006),'Metal · antique brass','chest',12,8)
 panel('Lower hand warmer pocket '+s,[(x-.06,.116,1.031),(x+.055,.116,1.031),(x+.067,.132,1.131),(x-.051,.132,1.147)],'Jacket · highlight panels','spine',.012,.012)
 line('Pocket stitch '+s,[(x-.05,.142,1.06),(x+.042,.142,1.06),(x+.051,.145,1.12)],.0015,'Stitch · flax','spine')
# Padded raised collar split at throat.
for sign,s in [(1,'R'),(-1,'L')]:
 panel('Standing collar '+s,[(sign*.031,.076,1.38),(sign*.082,.035,1.395),(sign*.082,.025,1.453),(sign*.037,.073,1.445)],'Jacket · seam binding','neck',.018,.009)
# Belt sewn at waist, brass buckle and loops.
rings_z('Canvas belt',[(0,0,.956,.172,.11),(0,0,.972,.171,.112),(0,0,.985,.167,.106)],'Boots · oiled leather',lambda z,j:{'pelvis':1},32,0)
panel('Belt buckle',[(-.026,.119,.958),(.026,.119,.958),(.026,.119,.985),(-.026,.119,.985)],'Metal · antique brass','pelvis',.008,.004)
for x in [-.13,-.07,.07,.13]: line('Belt loop',[(x,.094,.948),(x,.119,.989)],.008,'Trousers · umber canvas','pelvis')
# Legs are tapered, asymmetrically creased volumes with anatomical knees.
for sign,s in [(1,'R'),(-1,'L')]:
 x=sign*.123
 pts=[(sign*.109,0,.895),(sign*.112,0,.86),(sign*.12,0,.735),(sign*.126,.012,.59),(sign*.127,.016,.50),(sign*.127,.007,.455),(sign*.13,-.013,.33),(sign*.136,-.015,.21),(sign*.136,-.015,.18)]
 radii=[(.09,.097),(.097,.105),(.085,.092),(.073,.077),(.075,.069),(.066,.066),(.058,.058),(.06,.053),(.058,.052)]
 w=[]
 for p in pts:
  t=max(0,min(1,(p[2]-.44)/.12)); w.append({'thigh.'+s:t,'shin.'+s:1-t})
 sweep('Tailored trouser leg '+s,pts,radii,'Trousers · umber canvas',w,24,1)
 ellipsoid('Reinforced articulated knee '+s,(x,.062,.495),(.062,.020,.088),'Trousers · reinforced knees','shin.'+s,24,12)
 line('Trouser outer seam '+s,[(sign*.203,0,.855),(sign*.202,-.005,.74),(sign*.192,-.009,.60),(sign*.186,-.013,.51)],.0024,'Stitch · flax','thigh.'+s)
 for z in [.355,.29]: line('Natural canvas crease '+s,[(x-.042,.031,z+.009),(x-.015,.047,z),(x+.038,.033,z+.004)],.004,'Trousers · reinforced knees','shin.'+s)
 # Shaped leather boot upper and rubber toe/sole.
 rings_z('Leather ankle boot '+s,[(x,.012,.056,.073,.145),(x,.018,.084,.078,.146),(x,.025,.112,.074,.132),(x,.0,.155,.059,.072),(x,-.01,.207,.061,.062),(x,-.01,.225,.056,.06)],'Boots · oiled leather',lambda z,j,ss=s:{'foot.'+ss:1},32,1)
 rings_z('Durable tread sole '+s,[(x,.018,.018,.076,.15),(x,.021,.025,.081,.153),(x,.021,.057,.081,.153),(x,.019,.069,.074,.146)],'Boots · rubber sole',lambda z,j,ss=s:{'foot.'+ss:1},32,1)
 for i in range(4):
  z=.118+i*.019; y=.082-i*.011
  line('Crossed boot lace '+s,[(x-.027,y,z),(x+.026,y+.005,z+.010)],.0034,'Boots · laces','foot.'+s)
  line('Crossed boot lace '+s,[(x+.027,y,z),(x-.026,y+.005,z+.010)],.0034,'Boots · laces','foot.'+s)
  for d in [-1,1]: ellipsoid('Brass lace eyelet',(x+d*.029,y-.002,z),(.004,.004,.004),'Metal · antique brass','foot.'+s,10,6)
 for yy in [-.07,-.025,.02,.065,.11]:
  line('Sole tread '+s,[(x-.066,yy,.029),(x+.066,yy,.029)],.007,'Boots · rubber sole','foot.'+s)
# Fuse the custom sculpted pant sections into one continuous tailored cloth surface.
parts=[o for o in mesh_objects if o.name.startswith(('Canvas seat','Tailored trouser leg'))]
bpy.ops.object.select_all(action='DESELECT')
for o in parts:
 bpy.context.view_layer.objects.active=o
 for mod in list(o.modifiers): bpy.ops.object.modifier_apply(modifier=mod.name)
 o.select_set(True)
bpy.context.view_layer.objects.active=parts[0]; bpy.ops.object.join(); pants=parts[0]; pants.name='Continuous tailored canvas trousers'
mesh_objects=[o for o in mesh_objects if o not in parts]+[pants]
mod=pants.modifiers.new('Continuous cloth topology','REMESH'); mod.mode='VOXEL'; mod.voxel_size=.007; mod.use_smooth_shade=True; bpy.ops.object.modifier_apply(modifier=mod.name)
mod=pants.modifiers.new('Soft cloth transitions','SMOOTH'); mod.factor=.8; mod.iterations=6; bpy.ops.object.modifier_apply(modifier=mod.name)
mod=pants.modifiers.new('Mobile cloth topology','DECIMATE'); mod.ratio=.44; bpy.ops.object.modifier_apply(modifier=mod.name)
pants.vertex_groups.clear()
for n in ['pelvis','thigh.R','shin.R','thigh.L','shin.L']: pants.vertex_groups.new(name=n)
for v in pants.data.vertices:
 s='R' if v.co.x>=0 else 'L'; z=v.co.z; hip=max(0,min(1,(z-.79)/.11)); thigh=max(0,min(1,(z-.44)/.12))
 for n,w in [('pelvis',hip),('thigh.'+s,(1-hip)*thigh),('shin.'+s,(1-hip)*(1-thigh))]:
  if w>0:pants.vertex_groups[n].add([v.index],w,'REPLACE')

# Arms, continuous skinned and shaped sleeves with rolled cuffs.
for sign,s in [(1,'R'),(-1,'L')]:
 sh,el=bone_spec['upper_arm.'+s][:2]; wr=bone_spec['hand.'+s][0]
 pts=[sh+(sh-el).normalized()*.028,sh,sh.lerp(el,.40),sh.lerp(el,.62),sh.lerp(el,.69),sh.lerp(el,.77),sh.lerp(el,.87),el,el.lerp(wr,.22),el.lerp(wr,.61),el.lerp(wr,.82),el.lerp(wr,.84)]
 radii=[(.02,.022),(.076,.082),(.072,.074),(.062,.065),(.066,.067),(.058,.06),(.061,.060),(.061,.058),(.06,.056),(.047,.048),(.042,.046),(.045,.049)]
 weights=[{'upper_arm.'+s:1}]*6+[{'upper_arm.'+s:.85,'forearm.'+s:.15},{'upper_arm.'+s:.5,'forearm.'+s:.5},{'upper_arm.'+s:.1,'forearm.'+s:.9}]+[{'forearm.'+s:1}]*3
 sweep('Sculpted shirt sleeve '+s,pts,radii,'Shirt · warm sandstone',weights,24,1)
 cuffpts=[el.lerp(wr,.77),el.lerp(wr,.79),el.lerp(wr,.87),el.lerp(wr,.885)]
 sweep('Rolled stitched cuff '+s,cuffpts,[.05,.053,.05,.045],'Shirt · seam','forearm.'+s,24,1)
 sweep('Exposed wrist '+s,[el.lerp(wr,.83),el.lerp(wr,.91),wr,wr+rod_dir*.03],[.034,.034,.035,.036],'Skin · warm tan','hand.'+s,20,1)
 # Palm local geometry follows grip direction, each fingertip wraps around the invisible handle.
 d=rod_dir; side=Vector((1,0,0)); toward=-side.cross(d).normalized()
 R=Matrix(((side.x,d.x,toward.x),(side.y,d.y,toward.y),(side.z,d.z,toward.z)))
 palm_center=wr+side*(.018 if s=='R' else -.018)+d*.035
 ellipsoid('Anatomical palm '+s,palm_center,(.032,.049,.025),'Skin · warm tan','hand.'+s,24,14,R)
 for f in range(4):
  offset=(f-1.5)*.019; base=wr+d*(offset+.038)+side*sign*.042
  finger=[base,base-side*sign*.013+toward*.026,base-side*sign*.049+toward*.029,base-side*sign*.065+toward*.011]
  fname=f'finger_{f+1}.{s}'; bone(fname,finger[0],finger[-1],'hand.'+s)
  sweep('Curled finger '+str(f+1)+s,finger,[.0105,.010,.009,.0078],'Skin · warm tan',fname,12,1)
  nailpos=finger[-1]+toward*.004
  ellipsoid('Subtle fingernail '+str(f+1)+s,nailpos,(.006,.007,.0025),'Shirt · warm sandstone',fname,12,8,R)
 thumb=[wr+d*.068+side*sign*.035,wr+d*.086+side*sign*.002+toward*.02,wr+d*.061-side*sign*.019+toward*.025]
 bone('thumb.'+s,thumb[0],thumb[-1],'hand.'+s)
 sweep('Wrapped opposing thumb '+s,thumb,[.015,.013,.010],'Skin · warm tan','thumb.'+s,14,1)
# Head: shaped skull/jaw, cheek planes, eye socket forms, ears, nose, and restrained facial hair.
sweep('Neck',[(0,0,1.40),(0,.003,1.455),(0,.009,1.51)],[.058,.058,.067],'Skin · warm tan','neck',24,1)
rings_z('Sculpted head',[(0,.023,1.462,.043,.045),(0,.024,1.475,.061,.059),(0,.020,1.50,.078,.072),(0,.015,1.535,.088,.081),(0,.013,1.575,.098,.085),(0,.005,1.62,.102,.09),(0,.001,1.665,.094,.084),(0,-.003,1.701,.071,.066),(0,-.003,1.716,.037,.04)],'Skin · warm tan',lambda z,j:{'head':1},40,1)
for sign,s in [(1,'R'),(-1,'L')]:
 ellipsoid('Ear '+s,(sign*.101,.004,1.575),(.018,.023,.038),'Skin · warm tan','head',24,14)
 ellipsoid('Ear inner fold '+s,(sign*.111,.019,1.576),(.008,.010,.024),'Skin · cheeks','head',20,12)
 #ellipsoid('Cheek plane '+s,(sign*.054,.073,1.553),(.031,.007,.030),'Skin · warm tan','head',24,14)
 # small almond eyes sitting underneath eyebrows and sculpted upper eyelid.
 ellipsoid('Eye white '+s,(sign*.041,.090,1.606),(.024,.0085,.013),'Eyes · ivory','head',24,14)
 ellipsoid('Hazel iris '+s,(sign*.040,.0983,1.6055),(.009,.0035,.010),'Eyes · hazel','head',20,12)
 ellipsoid('Pupil '+s,(sign*.040,.101,1.6055),(.0045,.0017,.0066),'Eyes · pupil','head',16,10)
 ellipsoid('Eye light '+s,(sign*.037,.1025,1.609),(.0018,.001,.002),'Eyes · ivory','head',10,6)
 line('Upper eyelid '+s,[(sign*.018,.094,1.608),(sign*.032,.100,1.620),(sign*.048,.098,1.62),(sign*.064,.09,1.608)],.0037,'Skin · cheeks','head')
 line('Character eyebrow '+s,[(sign*.019,.091,1.63),(sign*.035,.10,1.635),(sign*.055,.094,1.632),(sign*.069,.082,1.624)],.0055,'Hair · chestnut','head')
 # Sideburns and beard sides sculpt to jaw.
 ellipsoid('Sideburn '+s,(sign*.084,.023,1.583),(.007,.015,.028),'Hair · chestnut','head',20,12)
 #line('Jaw beard edge '+s,[(sign*.079,.046,1.547),(sign*.075,.051,1.509),(sign*.052,.064,1.482),(sign*.012,.072,1.472)],.010,'Hair · chestnut','head')
# Convex nose with readable bridge and nostrils, not painted features.
ellipsoid('Nose bridge',(0,.094,1.586),(.015,.022,.041),'Skin · warm tan','head',24,14)
ellipsoid('Nose tip',(0,.118,1.572),(.024,.024,.017),'Skin · warm tan','head',24,14)
for x in [-.018,.018]:
 ellipsoid('Nose wing',(x,.104,1.567),(.012,.016,.012),'Skin · warm tan','head',20,12)
 ellipsoid('Nostril',(x*.85,.117,1.561),(.006,.004,.003),'Skin · lip','head',16,8)
line('Quiet smile',[(-.036,.09,1.529),(-.020,.097,1.526),(0,.099,1.525),(.021,.096,1.528),(.034,.09,1.534)],.0028,'Skin · lip','head')
ellipsoid('Lower lip',(0,.092,1.519),(.023,.009,.005),'Skin · cheeks','head',24,10)
#ellipsoid('Chin beard',(0,.066,1.479),(.035,.015,.013),'Hair · chestnut','head',24,12)
# Hair cap visible under a stitched fisherman cap. Hat brim is curved volumetric mesh.
rings_z('Hair under cap',[(0,-.014,1.627,.100,.078),(0,-.015,1.668,.099,.082),(0,-.02,1.704,.070,.061)],'Hair · chestnut',lambda z,j:{'head':1},32,1)
rings_z('Six panel fishing cap',[(0,-.002,1.652,.109,.094),(0,-.007,1.67,.111,.098),(0,-.013,1.712,.096,.089),(0,-.013,1.747,.063,.061),(0,-.013,1.758,.018,.019)],'Jacket · glacial teal',lambda z,j:{'head':1},40,1)
# Crown seam detail along meridians.
for a in [0,pi/3,2*pi/3,pi,4*pi/3,5*pi/3]:
 line('Cap crown sewn seam',[(.11*cos(a),-.007+.096*sin(a),1.668),(.096*cos(a),-.013+.089*sin(a),1.714),(.060*cos(a),-.013+.058*sin(a),1.747),(0,-.013,1.76)],.0014,'Jacket · highlight panels','head')
ellipsoid('Cap button',(0,-.013,1.762),(.009,.009,.005),'Jacket · seam binding','head',16,8)
verts=[]; faces=[]
for layer in [0,1]:
 for j in range(5):
  t=j/4
  for i in range(25):
   u=(i/24*2-1); x=.116*u*(1-.08*t); y=.055+t*(.140*math.sqrt(max(0,1-u*u))+.014); z=1.659-.024*t-.013*u*u+layer*.007
   verts.append((x,y,z))
for layer in [0,1]:
 for j in range(4):
  for i in range(24):
   a=layer*125+j*25+i; faces.append((a,a+1,a+26,a+25))
for j in [0,4]:
 for i in range(24): a=j*25+i; faces.append((a,a+1,a+126,a+125))
for i in [0,24]:
 for j in range(4): a=j*25+i; faces.append((a,a+25,a+150,a+125))
mesh('Sculpted curved cap visor',verts,faces,'Jacket · seam binding',[{'head':1} for _ in verts],1)
# Small diamond brand-free stitched patch and fish emblem.
#panel('Ochre cap patch',[(-.027,.083,1.681),(0,.092,1.668),(.027,.083,1.681),(.024,.072,1.71),(-.024,.072,1.71)],'Cap · ochre badge','head',.003,.004)
#ellipsoid('Cap patch fish',(0,.094,1.688),(.015,.002,.0055),'Stitch · flax','head',16,8)
#panel('Cap fish tail',[(-.015,.094,1.688),(-.023,.093,1.694),(-.023,.094,1.682)],'Stitch · flax','head',.002,.001)
# A tiny original fishing fly pinned to the chest.
line('Pocket fly hook',[(.145,.16,1.25),(.151,.165,1.233),(.143,.167,1.23),(.139,.165,1.24)],.0018,'Metal · antique brass','chest')
ellipsoid('Pocket fly body',(.145,.167,1.253),(.005,.006,.015),'Cap · ochre badge','chest',16,8)
for d in [-1,1]: line('Fly feather',[(.145,.165,1.25),(.145+d*.012,.165,1.266),(.145+d*.006,.165,1.274)],.0018,'Stitch · flax','chest')
# Build the deformation skeleton.
armdata=bpy.data.armatures.new('FarshoreAnglerSkeleton'); rig=bpy.data.objects.new('AnglerRig',armdata); scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig; rig.select_set(True); bpy.ops.object.mode_set(mode='EDIT')
for n,(h,t,parent) in bone_spec.items():
 b=armdata.edit_bones.new(n); b.head=h; b.tail=t
 if parent: b.parent=armdata.edit_bones[parent]
 # Stable roll is essential for predictable exported animation.
 b.align_roll(Vector((0,-rod_dir.z,rod_dir.y)) if n.startswith('hand.') else Vector((0,1,0)))
bpy.ops.object.mode_set(mode='OBJECT'); rig.show_in_front=True
for obj in mesh_objects:
 if not len(obj.vertex_groups): continue
 mod=obj.modifiers.new('Farshore skeletal deformation','ARMATURE'); mod.object=rig; obj.parent=rig
# Socket is a real glTF node parented to the right hand. Local Blender +Y -> Godot -Z.
socket=bpy.data.objects.new('RodSocket',None); scene.collection.objects.link(socket); socket.empty_display_type='ARROWS'; socket.empty_display_size=.12
socket.parent=rig; socket.parent_type='BONE'; socket.parent_bone='hand.R'
# Child-of-bone includes its length translation, so solve using the explicit parent matrix.
bpy.context.view_layer.update(); pb=rig.pose.bones['hand.R']
# Node axes: x lateral, y rod direction, z cross. This exports to a Godot basis with -Z toward tip.
xaxis=Vector((1,0,0)); yaxis=rod_dir; zaxis=xaxis.cross(yaxis).normalized(); xaxis=yaxis.cross(zaxis).normalized()
S=Matrix(((xaxis.x,yaxis.x,zaxis.x,handR.x),(xaxis.y,yaxis.y,zaxis.y,handR.y),(xaxis.z,yaxis.z,zaxis.z,handR.z),(0,0,0,1)))
parentworld=rig.matrix_world@pb.matrix@Matrix.Translation((0,pb.length,0)); socket.matrix_basis=parentworld.inverted()@S
# Animation: analytical two-bone arms keep both hands locked to one rigid handle.
rig.animation_data_create(); FPS=30; scene.render.fps=FPS
bind={n:b.matrix_local.copy() for n,b in armdata.bones.items()}

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
  v=lerpkeys([(0,.115,.40,1.14,.572,0,0),(.34,.16,.28,1.35,1.22,-.055,-.11),(.78,.18,.075,1.55,2.14,-.13,-.21),(1.0,.16,.105,1.57,1.97,-.1,-.16),(1.20,.115,.50,1.32,.48,.12,.09),(1.42,.105,.53,1.20,.20,.075,.04),(1.78,.115,.44,1.14,.45,.025,0),(2.2,.115,.40,1.14,.572,0,0)],t)
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
  elbowhint=Vector((sign*.75,-.14,-.7)); perp=(elbowhint-axis*elbowhint.dot(axis)).normalized(); elbow=shoulder+axis*along+perp*height
  oriented_bone(n,shoulder,elbow); bpy.context.view_layer.update(); oriented_bone('forearm.'+s,elbow,wrist); bpy.context.view_layer.update()
  # Hand orientation is shared with the rod, keeping contact consistent throughout casting.
  oriented_bone('hand.'+s,wrist,wrist+d*.09,Vector((0,-d.z,d.y))); bpy.context.view_layer.update()
 # All channels baked on the actual deformation bones.

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
# Master includes neutral studio cameras and lights. The exported asset excludes those.
world=bpy.data.worlds.new('Slate studio world'); world.use_nodes=True; world.node_tree.nodes['Background'].inputs[0].default_value=(.20,.25,.29,1); world.node_tree.nodes['Background'].inputs[1].default_value=.35; scene.world=world

def area(name,loc,power,color,size):
 data=bpy.data.lights.new(name,'AREA'); data.energy=power; data.color=color; data.shape='DISK'; data.size=size
 o=bpy.data.objects.new(name,data); scene.collection.objects.link(o); o.location=loc; o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
area('Large warm softbox',(3,4,5),450,(1,.83,.65),4); area('Cool bounce',(-3,2,2.5),300,(.62,.82,1),3); area('Rim light',(1,-3,3),500,(.75,.9,1),2)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,0)); ground=bpy.context.object; ground.name='REVIEW ONLY studio floor'; ground.data.materials.append(M['Review · backdrop'])
data=bpy.data.cameras.new('ReviewCamera'); cam=bpy.data.objects.new('ReviewCamera',data); scene.collection.objects.link(cam); scene.camera=cam; data.type='ORTHO'; data.ortho_scale=2.15

def camera(loc,target=(0,.08,.9)):
 cam.location=loc; cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()

def render(name,loc,clip='idle',frame=1):
 rig.animation_data.action=bpy.data.actions[clip]; scene.frame_set(frame); bpy.context.view_layer.update(); camera(loc); scene.render.filepath=os.path.join(OUT,name+'.png'); bpy.ops.render.render(write_still=True)
# Evaluate modifiers for glTF and statistics; retain non-destructive editable master.
rig.animation_data.action=bpy.data.actions['idle']; scene.frame_set(1)
bpy.context.view_layer.update()
lowest=min((o.matrix_world@Vector(c)).z for o in mesh_objects for c in o.bound_box)
rig.location.z=-lowest
bpy.context.view_layer.update()
for tr in rig.animation_data.nla_tracks: tr.mute=False
# One runtime mesh with a material surface for each shared material.
bpy.ops.object.select_all(action='DESELECT')
exports=[]
for source in mesh_objects:
 copy=source.copy(); copy.data=source.data.copy(); scene.collection.objects.link(copy); copy.name='Runtime_'+source.name
 bpy.context.view_layer.objects.active=copy; copy.select_set(True)
 for mod in list(copy.modifiers):
  if mod.type!='ARMATURE':bpy.ops.object.modifier_apply(modifier=mod.name)
 copy.select_set(False); exports.append(copy)
for o in exports:o.select_set(True)
bpy.context.view_layer.objects.active=exports[0]; bpy.ops.object.join(); runtime=exports[0]; runtime.name='Angler_Skinned_Mesh'
# Joining duplicates material slots; remove duplicate slots without changing face assignment.
unique=[]; remap={}
for i,m in enumerate(runtime.data.materials):
 if m not in unique:unique.append(m)
 remap[i]=unique.index(m)
inds=[remap[p.material_index] for p in runtime.data.polygons]
runtime.data.materials.clear()
for m in unique:runtime.data.materials.append(m)
for p,i in zip(runtime.data.polygons,inds):p.material_index=i
rig.select_set(True); socket.select_set(True); bpy.context.view_layer.objects.active=rig
os.makedirs(os.path.join(ROOT,'game/assets/3d'),exist_ok=True); os.makedirs(os.path.join(ROOT,'art_masters/3d'),exist_ok=True)
bpy.ops.export_scene.gltf(filepath=os.path.join(ROOT,'game/assets/3d/angler.glb'),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_nla_strips=True,export_skins=True,export_apply=True,export_force_sampling=True,export_frame_range=False,export_anim_slide_to_zero=True,export_def_bones=True,export_yup=True,export_morph=False,export_cameras=False,export_lights=False)
bpy.data.objects.remove(runtime,do_unlink=True)
for tr in rig.animation_data.nla_tracks: tr.mute=True
rig.animation_data.action=bpy.data.actions['idle']; scene.frame_set(1); camera((2.5,4,2.2))
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT,'art_masters/3d/angler.blend'))
# Persist topology/statistics and honest review evidence.
deps=bpy.context.evaluated_depsgraph_get(); triangles=0
for o in mesh_objects:
 ev=o.evaluated_get(deps); me=ev.to_mesh(); me.calc_loop_triangles(); triangles+=len(me.loop_triangles); ev.to_mesh_clear()
with open(os.path.join(OUT,'stats.json'),'w') as f: json.dump({'triangles':triangles,'mesh_objects':len(mesh_objects),'bones':len(bone_spec),'clips_seconds':clips,'height_m':round(1.767-lowest,4),'front_godot':'-Z','socket':'AnglerRig/Skeleton3D/hand_R/RodSocket; use recursive node lookup','materials':list(M)},f,indent=2)
print('ASSET_STATS',triangles,len(mesh_objects),len(bone_spec),flush=True)
# A simple review-only fishing handle makes hand/rod contact inspectable in renders.
preview=sweep('REVIEW ONLY rod grip',[(0,-.25,0),(0,-.23,0),(0,.18,0),(0,.20,0)],[.015,.018,.018,.011],'Boots · oiled leather','hand.R',16,0)
preview.parent=socket; preview.matrix_parent_inverse=Matrix.Identity(4); preview.matrix_basis=Matrix.Identity(4)
shaft=sweep('REVIEW ONLY rod shaft',[(0,.18,0),(0,.60,0),(0,1.15,-.025),(0,1.65,-.09)],[.009,.008,.005,.002],'Jacket · seam binding','hand.R',12,0)
shaft.parent=socket; shaft.matrix_parent_inverse=Matrix.Identity(4); shaft.matrix_basis=Matrix.Identity(4)

render('01-three-quarter',(2.5,4,2.15))
render('02-front',(0,4,1.75))
render('03-back',(2.5,-4,2.15))
render('04-cast-windup',(2.5,4,2.15),'cast',24)
render('05-cast-release',(2.5,4,2.15),'cast',37)
render('06-reel',(2.5,4,2.15),'reel',16)
render('07-lift',(2.5,4,2.15),'lift',29)
print('ANGLER_BUILD_COMPLETE',flush=True)
