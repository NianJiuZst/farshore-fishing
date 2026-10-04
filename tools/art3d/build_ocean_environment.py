"""Original open-ocean island geometry, Blender 4.3+. Never rewrites legacy assets.
Run blender -b -t 4 --python tools/art3d/build_ocean_environment.py -- --region pacific_ocean
The ocean is rendered by the existing Godot water shader, not baked into the GLB.
"""
import bpy, math, random, sys, argparse, json, hashlib
from mathutils import Vector
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--region',choices=['pacific_ocean','atlantic_ocean','indian_ocean'],required=True)
a=p.parse_args(sys.argv[sys.argv.index('--')+1:]); region=a.region
rng=random.Random({'pacific_ocean':90401,'atlantic_ocean':90402,'indian_ocean':90403}[region])
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
M={}
SURFACES=[]
def material(name,color,roughness=.82):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 n=m.node_tree.nodes.get('Principled BSDF');n.inputs['Base Color'].default_value=(*color,1);n.inputs['Roughness'].default_value=roughness;M[name]=m
for n,c in {'Sand':(.70,.66,.47),'Stone':(.30,.37,.39),'Cliff':(.24,.28,.29),'Bark':(.32,.25,.15),'BarkLight':(.49,.39,.25),'FoliageDeep':(.10,.26,.17),'FoliageGreen':(.19,.37,.18),'FoliageSun':(.38,.48,.23),'CoralLimestone':(.65,.59,.44),'BasaltDark':(.16,.20,.22),'CliffHeather':(.34,.37,.28)}.items():material(n,c)
def P(v):return (v[0],-v[2],v[1])
def mesh(name,verts,faces,mat):
 me=bpy.data.meshes.new(name);me.from_pydata([P(v) for v in verts],[],faces);me.materials.append(M[mat]);me.update()
 ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob);return ob
def tube(name,pts,radii,mat,sides=9):
 vs=[];fs=[];pts=[Vector(x) for x in pts]
 for i,v in enumerate(pts):
  axis=(pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)]).normalized();side=axis.cross(Vector((0,1,0)))
  if side.length<.01:side=axis.cross(Vector((1,0,0)))
  side.normalize();up=side.cross(axis).normalized()
  for j in range(sides):vs.append(tuple(v+radii[i]*(side*math.cos(j*math.tau/sides)+up*math.sin(j*math.tau/sides))))
 for i in range(len(pts)-1):
  for j in range(sides):fs.append((i*sides+j,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,(i+1)*sides+j))
 fs.extend([tuple(reversed(range(sides))),tuple((len(pts)-1)*sides+j for j in range(sides))]);return mesh(name,vs,fs,mat)
def island(cx,cz,rx,rz,height,phase=0,atoll=False):
 # Five independently irregular rings create a real sloping shoreline and summit.
 SURFACES.append((cx,cz,rx,rz,height,atoll))
 vs=[];N=80;R=9
 for ring in range(R):
  t=ring/(R-1)
  for i in range(N):
   ang=i*math.tau/N;noise=1+.06*math.sin(ang*5+phase)+.035*math.cos(ang*9-phase)
   rad=.015+t
   y=height*max(0,1-t*t)**1.6-.50*t+math.sin(ang*4+phase)*height*.065*math.sin(t*math.pi)
   if atoll:y=height*math.sin(t*math.pi)**1.2-.6*(1-t)-.40*t
   vs.append((cx+math.cos(ang)*rx*rad*noise,y,cz+math.sin(ang)*rz*rad*noise))
 fs=[]
 vs.append((cx,-.6 if atoll else height,cz)); center=len(vs)-1
 for i in range(N):fs.append((center,(i+1)%N,i))
 for j in range(R-1):
  for i in range(N):fs.append((j*N+i,j*N+(i+1)%N,(j+1)*N+(i+1)%N,(j+1)*N+i))
 ob=mesh('Island body',vs,fs,'Sand' if region=='indian_ocean' else 'Cliff' if region=='atlantic_ocean' else 'Stone')
 for poly in ob.data.polygons:poly.use_smooth=True
 # A separate warm shoreline ribbon retains geological detail under runtime PBR.
 for k in range(35):
  ang=rng.random()*math.tau;r=.75+rng.random()*.23;x=cx+math.cos(ang)*rx*r;z=cz+math.sin(ang)*rz*r
  rock(x,height*max(0,1-r*r)**1.6-.50*r,z,rng.uniform(.6,2.6),rng.uniform(.5,1.5),'CoralLimestone' if region=='indian_ocean' else 'BasaltDark' if region=='pacific_ocean' else 'Cliff')
 return height
def rock(x,y,z,s,sy,mat):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=P((x,y,z)));o=bpy.context.object;o.name='Original weathered boulder';o.scale=(s,s*.8,sy)
 for v in o.data.vertices:v.co*=rng.uniform(.85,1.13)
 o.data.materials.append(M[mat]);return o
def ground(x,z):
 values=[-1.0]
 for cx,cz,rx,rz,height,atoll in SURFACES:
  t=math.sqrt(((x-cx)/rx)**2+((z-cz)/rz)**2)
  if t<1:
   values.append(height*math.sin(t*math.pi)**1.2-.6*(1-t)-.4*t if atoll else height*max(0,1-t*t)**1.6-.5*t)
 return max(values)
def palm(x,z,h,lean):
 base=ground(x,z)-.18
 pts=[(x+lean*t*t,base+h*t,z+.22*math.sin(t*2)) for t in [i/14 for i in range(15)]]
 tube('Palm curved trunk',pts,[.18*(1-i/25) for i in range(15)],'Bark',12)
 for j in range(11):
  t=.12+j*.07;p=Vector((x+lean*t*t,base+h*t,z+.22*math.sin(t*2)));tube('Palm growth rings',[tuple(p-Vector((0,.025,0))),tuple(p+Vector((0,.025,0)))],[.18*(1-t*.6)]*2,'BarkLight',12)
 crown=Vector(pts[-1])
 for j in range(10):
  ang=j*math.tau/10;L=h*rng.uniform(.36,.48);heading=Vector((math.cos(ang),0,math.sin(ang)));side=Vector((-math.sin(ang),0,math.cos(ang)))
  curve=[crown+heading*(L*t)+Vector((0,L*(.27*math.sin(t*math.pi)-.30*t*t),0)) for t in [i/12 for i in range(13)]]
  tube('Palm leaf central rib',[tuple(v) for v in curve],[.035*(1-i/15) for i in range(13)],'FoliageGreen',5)
  for i in range(1,12):
   t=i/12;width=L*.19*math.sin(t*math.pi)**.65
   for sign in [-1,1]:
    base=curve[i];tip=base+side*(width*sign)+heading*(L*.085)+Vector((0,-width*.28,0));ridge=(base+tip)/2+Vector((0,.035,0));w=heading*L*.058
    mesh('Palm individual closed leaflet',[tuple(base-w),tuple(base+w),tuple(tip),tuple(ridge),tuple(ridge-Vector((0,.018,0)))],[(0,1,3),(1,2,3),(2,0,3),(1,0,4),(2,1,4),(0,2,4)],'FoliageSun' if j%3==0 else 'FoliageGreen')
def scrub(x,y,z,scale):
 y=ground(x,z)-.15
 for i in range(18):
  a=rng.random()*math.tau;t=rng.uniform(.2,1);q=(x+math.cos(a)*scale*t,y+scale*.3+t*.2,z+math.sin(a)*scale*t)
  rock(*q,scale*.30,scale*.27,'CliffHeather')
if region=='pacific_ocean':
 island(-70,-100,39,46,17,.8);island(113,-165,43,25,23,1.9);island(-170,-295,60,28,34,3.5)
 for x,z,h,l in [(-61,-76,8,1.2),(-75,-87,9,-.8),(-53,-110,10,1.5),(-83,-109,8,.7),(100,-155,9,-.6),(122,-168,10,1.2)]:palm(x,z,h,l)
 for i in range(18):rock(-45+rng.uniform(-10,14),-1.1,-55+rng.uniform(-14,15),rng.uniform(.4,1.2),rng.uniform(.5,1.3),'CoralLimestone')
elif region=='atlantic_ocean':
 island(-105,-128,55,48,26,.1);island(138,-230,67,30,36,2.0);island(-220,-370,76,42,45,3.0)
 for i in range(45):
  x=-105+rng.uniform(-25,25);z=-125+rng.uniform(-22,22);scrub(x,17+rng.uniform(-2,2),z,rng.uniform(.7,1.8))
 # Separate eroded basalt sea stacks on the shelf, absent tropical palms.
 for x,z,rx,rz,h in [(-47,-83,6,8,11),(-53,-101,4,6,15),(62,-145,5,5,8)]:island(x,z,rx,rz,h,.7)
else:
 island(-66,-112,46,37,2.4,.2,True);island(117,-220,62,28,3.2,2,True);island(-185,-320,69,22,3.4,2.6,True)
 for x,z,h,l in [(-44,-102,7,.8),(-49,-98,8,-.8),(-69,-82,9,1.3),(-77,-82,7,-.8),(-83,-131,8,1.1),(-68,-142,9,.7),(111,-199,9,-1.3),(127,-199,8,.9)]:palm(x,z,h,l)
 for i in range(24):rock(-26+rng.uniform(-9,8),-.5,-69+rng.uniform(-12,12),rng.uniform(.4,1.0),rng.uniform(.3,.8),'CoralLimestone')
# Preserve named material batches so existing runtime PBR/foliage adaptation works.
for name in M:
 obs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials and o.data.materials[0].name==name]
 if not obs:continue
 bpy.ops.object.select_all(action='DESELECT')
 for o in obs:o.select_set(True)
 bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();o=obs[0];o.name=name
 bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 for p in o.data.polygons:p.use_smooth=True
 mod=o.modifiers.new('Deterministic triangles','TRIANGULATE');bpy.ops.object.modifier_apply(modifier=mod.name)
triangles=sum(len(o.data.polygons) for o in bpy.context.scene.objects if o.type=='MESH')
out=ROOT/'game/assets/3d/environment';out.mkdir(parents=True,exist_ok=True)
master=ROOT/'art_masters/3d'/('region_'+region+'.blend');bpy.ops.wm.save_as_mainfile(filepath=str(master),compress=False)
path=out/('region_'+region+'.glb');bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',export_animations=False,export_yup=True,export_materials='EXPORT',export_apply=True)
report={'region_id':region,'triangles':triangles,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'authoring':'Original deterministic island, sea-stack, palm and reef geometry. Fictional composite ocean scenery, not a mapped real locality.','master':str(master.relative_to(ROOT)),'up':'+Y','unit':'meter'}
(out/('region_'+region+'.json')).write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print(json.dumps(report),flush=True)
