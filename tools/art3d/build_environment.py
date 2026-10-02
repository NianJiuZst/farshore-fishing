"""Original managed Mississippi oxbow environment. Blender 4.3+, no downloaded assets.
Run: blender -b --python tools/art3d/build_environment.py
Model coordinate contract is Godot meters: +Y up, dock faces -Z.
"""
import bpy, math, random, json
from pathlib import Path
from mathutils import Vector
R = random.Random(81207)
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT/'game/assets/3d/environment'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
M = {}
def mat(name, color, rough=.8, metallic=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=(*color,1)
    bs.inputs['Roughness'].default_value=rough; bs.inputs['Metallic'].default_value=metallic
    M[name]=m; return m
for n,c in {'DockHoney':(.39,.245,.112),'DockPale':(.47,.315,.166),'DockWeathered':(.31,.216,.13),'WoodEndgrain':(.23,.15,.085),'Iron':(.105,.15,.155),'Rope':(.44,.38,.255),'Bark':(.20,.17,.105),'BarkLight':(.29,.25,.155),'FoliageDeep':(.075,.18,.115),'FoliageGreen':(.15,.285,.13),'FoliageSun':(.29,.38,.15),'FoliageGold':(.385,.405,.20),'Grass':(.25,.32,.155),'GrassDry':(.43,.41,.215),'Soil':(.30,.245,.155),'Mud':(.195,.20,.145),'Sand':(.49,.435,.285),'Stone':(.32,.36,.315),'StoneWarm':(.40,.39,.30),'Reed':(.28,.32,.12),'Cattail':(.20,.115,.055),'Canvas':(.70,.62,.37),'Enamel':(.14,.33,.30),'Paper':(.82,.78,.59)}.items(): mat(n,c,.36 if n=='Enamel' else .85,.65 if n=='Iron' else 0)
def P(p): return Vector((p[0],-p[2],p[1]))
def mesh(name, verts, faces, material):
    me=bpy.data.meshes.new(name); me.from_pydata([P(v) for v in verts],[],faces); me.materials.append(M[material]); me.update()
    o=bpy.data.objects.new(name,me); bpy.context.collection.objects.link(o); return o
def box(name, p, size, material, bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1,location=P(p)); o=bpy.context.object; o.name=name
    o.dimensions=(size[0],size[2],size[1]); bpy.ops.object.transform_apply(location=False, rotation=False, scale=True); o.data.materials.append(M[material])
    if bevel:
        mod=o.modifiers.new('Soft crafted edge','BEVEL'); mod.width=bevel; mod.segments=1; bpy.context.view_layer.objects.active=o; bpy.ops.object.modifier_apply(modifier=mod.name)
    return o
def tube(name, points, radii, material, sides=7):
    pts=[Vector(p) for p in points]; vs=[]; fs=[]
    for i,p in enumerate(pts):
        axis=(pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)]).normalized(); a=axis.cross(Vector((0,1,0)))
        if a.length<.01:a=axis.cross(Vector((1,0,0)))
        a.normalize(); b=axis.cross(a).normalized()
        for j in range(sides):vs.append(tuple(p+radii[i]*(a*math.cos(j*math.tau/sides)+b*math.sin(j*math.tau/sides))))
    for i in range(len(pts)-1):
        for j in range(sides):fs.append((i*sides+j,i*sides+(j+1)%sides,(i+1)*sides+(j+1)%sides,(i+1)*sides+j))
    fs+=[tuple(reversed(range(sides))),tuple((len(pts)-1)*sides+j for j in range(sides))]
    return mesh(name,vs,fs,material)
def blob(name, p, size, material, subdivisions=1, distort=.12):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions,radius=1,location=P(p));o=bpy.context.object;o.name=name
    for v in o.data.vertices:
        v.co *= R.uniform(1-distort,1+distort)
    o.scale=(size[0],size[2],size[1]);o.data.materials.append(M[material]); return o

def leaf_crown(center, radii, h, material, count=170, willow=False):
    # A shaded inner branch canopy plus hundreds of individual curved, closed leaves.
    # No opacity cards, sprite textures, or billboard forest meshes.
    center=Vector(center); rx,ry,rz=radii
    verts=[]; faces=[]
    for k in range(count):
        a=R.random()*math.tau; v=R.uniform(-.95,.95); radial=math.sqrt(1-v*v)
        r=R.uniform(.74,1.10)
        q=center+Vector((rx*radial*math.cos(a),ry*v,rz*radial*math.sin(a)))*r
        # Leaves are cupped along the midrib and twist away from their branch.
        direction=Vector((math.cos(a),R.uniform(-.9,.65),math.sin(a))).normalized()
        side=direction.cross(Vector((0,1,0))).normalized()
        if side.length<.1: side=Vector((1,0,0))
        up=side.cross(direction).normalized()
        length=R.uniform(.22,.37)*(1.08 if willow else 1.0)
        width=length*(.21 if willow else R.uniform(.28,.40))
        base=len(verts)
        points=[q,q+direction*length*.44+side*width,q+direction*length+up*length*.08,q+direction*length*.44-side*width,q+direction*length*.45+up*length*.12,q+direction*length*.44-up*.005]
        verts += [tuple(p) for p in points]
        faces += [(base+0,base+1,base+4),(base+1,base+2,base+4),(base+2,base+3,base+4),(base+3,base+0,base+4),(base+1,base+0,base+5),(base+2,base+1,base+5),(base+3,base+2,base+5),(base+0,base+3,base+5)]
    mesh('Foliage individual curved leaves',verts,faces,material)

# Dock: separate physically beveled planks, bearer beams, bolts, submerged pilings.
for z in [-1.25,.4,2.05,3.7]:
    box('Bearer',(-.55,.35,z),(3.9,.24,.18),'WoodEndgrain',.025)
    for x in [-2.27,1.18]:
        tube('Dock piling',[(x,-1.8,z),(x,1.03,z)],[.12,.106],'DockWeathered',10)
        tube('Piling cap',[(x,1.015,z),(x,1.075,z)],[.135,.135],'DockPale',10)
        # Four wraps of real round mooring rope.
        for ring in range(4):
            pts=[(x+.125*math.cos(a*math.tau/20),.82+ring*.018,z+.125*math.sin(a*math.tau/20)) for a in range(21)]
            tube('Rope wraps',pts,[.012]*21,'Rope',5)
for i in range(23):
    z=-1.5+i*.235
    for j in range(2):
        x=-1.41+j*1.72
        o=box('Dock plank', (x,.51+R.uniform(-.003,.003),z),(1.69,.14,.219),R.choice(['DockHoney','DockPale','DockWeathered']),.012)
        for bx in [x-.69,x+.69]:
            for bz in [z-.065,z+.065]:
                tube('Dock nail',[(bx,.581,bz),(bx,.584,bz)],[.012,.012],'Iron',6)
        # Long inset narrow grain reveals are actual dark geometry, deliberately sparse.
        if i%2==0:
            box('Weathered grain',(x+R.uniform(-.3,.3),.582,z+R.uniform(-.07,.07)),(R.uniform(.35,1.05),.002,.005),'WoodEndgrain')
# One side railing leaves cast view open.
for z in [.4,2.05,3.7]: box('Rail post',(-2.27,1.13,z),(.10,1.12,.10),'DockWeathered',.014)
for y in [1.18,1.69]:box('Dock handrail',(-2.27,y,2.03),(.14,.09,3.48),'DockHoney',.018)
# Tackle crate in rear corner; lid, slats and hardware.
box('Tackle crate',(.62,.82,2.7),(.63,.45,.48),'Enamel',.04)
box('Tackle lid',(.62,1.06,2.7),(.68,.065,.51),'Canvas',.02)
for z in [2.49,2.91]:box('Crate latch',(.62,.98,z),(.07,.12,.018),'Iron',.01)
tube('Crate handle',[(.4,1.1,2.7),(.4,1.19,2.7),(.8,1.19,2.7),(.8,1.1,2.7)],[.025]*4,'Iron')
# Bucket modeled with open mouth/rim and handle.
def bucket(x,z):
    n=20; vs=[]
    for y,r in [(0.59,.19),(.98,.24),(.98,.217),(.61,.168)]:
        vs += [(x+r*math.cos(i*math.tau/n),y,z+r*math.sin(i*math.tau/n)) for i in range(n)]
    fs=[]
    for ring in range(3):
        for i in range(n):fs.append((ring*n+i,ring*n+(i+1)%n,(ring+1)*n+(i+1)%n,(ring+1)*n+i))
    fs.append(tuple(3*n+i for i in range(n)));mesh('Open enamel bucket',vs,fs,'Enamel')
    pts=[(x+.244*math.cos(t*math.pi/20),.98+.28*math.sin(t*math.pi/20),z) for t in range(21)]
    tube('Bucket handle',pts,[.009]*21,'Iron',6)
bucket(-1.77,1.93)
# Shoreline channels: river opens away from viewer with low alluvial banks, not mountains.
def bank_edge(z, side):
    return side*(9.8+1.9*math.sin(z*.065)+1.4*math.cos(z*.14))
for side in [-1,1]:
    vs=[];fs=[];rows=47;cols=7
    for iz in range(rows):
        z=8-iz*2.6;edge=bank_edge(z,side)
        for ix in range(cols):
            d=ix*5.5
            x=edge+side*d
            y=(-.20 if ix==0 else .25+min(d/14,1)*.72)+.19*math.sin(x*.32+z*.18)+.09*math.cos(z*.8)
            vs.append((x,y,z))
    for iz in range(rows-1):
        for ix in range(cols-1):
            a=iz*cols+ix;fs.append((a,a+1,a+cols+1,a+cols) if side==1 else (a+cols,a+cols+1,a+1,a))
    mesh('Alluvial bank',vs,fs,'Grass')
    # Mud shoal ribbon between wet edge and dry ground.
    vs=[];fs=[]
    for iz in range(rows):
        z=8-iz*2.6;edge=bank_edge(z,side)
        vs.extend([(edge-side*.75,-.28,z),(edge+side*.6,.13+math.sin(z*.3)*.06,z)])
    for iz in range(rows-1):
        a=iz*2;fs.append((a,a+1,a+3,a+2) if side==1 else (a+2,a+3,a+1,a))
    mesh('Wet bank',vs,fs,'Mud')
# Walk-in landing ground at foreground.
mesh('Near shore',[(-40,.04,3.8),(-9,.04,2.8),(-4,.18,3.6),(2,.25,4.3),(12,.05,3.5),(40,.03,4.0),(40,.42,35),(-40,.42,35)],[(0,1,2,3,4,5,6,7)],'Soil')
# Branch-built deciduous/cypress silhouettes with layered irregular crowns.
def tree(x,z,h,willow=False):
    y=.42; root=Vector((x,y,z)); lean=R.uniform(-.5,.5)
    tube('Trunk',[root,root+Vector((lean*.3,h*.46,0)),root+Vector((lean,h*.88,.18))],[h*.055,h*.033,h*.009],'Bark',14)
    # Buttress-root flares, highly characteristic river trees.
    for j in range(5):
        a=j*math.tau/5
        tube('Buttress root',[(x+math.cos(a)*h*.12,y,z+math.sin(a)*h*.12),(x,y+h*.3,z)],[h*.025,h*.037],'Bark',10)
    count=9 if willow else 7
    for j in range(count):
        a=j*2.4; level=.44+(j/count)*.42; reach=h*R.uniform(.22,.37)
        end=root+Vector((math.cos(a)*reach+lean,h*level,math.sin(a)*reach))
        tube('Limb',[root+Vector((lean*.5,h*level*.66,0)),end],[h*.025,h*.007],'BarkLight',10)
        c=end+Vector((0,h*.11,0));r=h*R.uniform(.18,.27)
        leaf_crown(c,(r*1.25,r*.68,r),h,R.choice(['FoliageGreen','FoliageSun','FoliageGold']),400 if z>-40 else (160 if z>-85 else 90),willow)
        if willow:
            for k in range(4):
                theta=a+k*1.4;hang=c+Vector((math.cos(theta)*r*.67,-h*.19,math.sin(theta)*r*.67))
                leaf_crown(hang,(r*.37,h*.24,r*.35),h,'FoliageGreen',60,True)
    leaf_crown(root+Vector((lean,h*.93,0)),(h*.24,h*.18,h*.24),h,'FoliageSun',340 if z>-40 else (160 if z>-85 else 90),willow)
for side in [-1,1]:
    for i in range(14):
        z=3-i*7.2+R.uniform(-2,2);x=bank_edge(z,side)+side*R.uniform(2.0,8.0)
        tree(x,z,R.uniform(4.8,8.4),i%4==0)
    for i in range(15):
        z=-15-i*6; x=bank_edge(z,side)+side*R.uniform(12,25)
        tree(x,z,R.uniform(5,9),False)
# A real low far shore and tree row end the oxbow; no giant primitive ridge wall.
mesh('Far low bank',[(-90,-.08,-93),(90,-.08,-93),(90,.55,-106),(-90,.55,-106),(-90,.7,-145),(90,.7,-145)],[(0,1,2,3),(3,2,5,4)],'Grass')
for i in range(25):
    tree(-74+i*6.1+R.uniform(-1,1),-108+R.uniform(-4,4),R.uniform(4.8,7.7),i%7==0)
# A closer hero tree frames left edge; taller field catches sunset shadows.
tree(-6.4,3.2,7.8,True)
# Rocks and multiblade reed/cattail clumps, actual geometry on both riverbanks.
for side in [-1,1]:
    for i in range(38):
        z=4-i*2.3+R.uniform(-1,1); x=bank_edge(z,side)+side*R.uniform(-.15,1.8)
        if i%3==0:blob('Shore stone',(x,.02,z),(R.uniform(.25,.72),R.uniform(.2,.44),R.uniform(.3,.7)),R.choice(['Stone','StoneWarm']),1,.16)
        for k in range(5):
            xx=x+R.uniform(-.5,.5);zz=z+R.uniform(-.5,.5);h=R.uniform(.4,1.1)
            tube('Reed stem',[(xx,-.02,zz),(xx+.07,h*.7,zz),(xx+.08,h,zz)],[.014,.01,.004],'Reed',5)
            if k%3==0:
                tube('Cattail head',[(xx+.078,h*.8,zz),(xx+.08,h*1.02,zz)],[.036,.03],'Cattail',6)
            for a in [R.random()*math.tau,R.random()*math.tau]:
                end=(xx+math.cos(a)*h*.28,h*.56,zz+math.sin(a)*h*.28)
                mid=(xx+math.cos(a)*h*.16,h*.85,zz+math.sin(a)*h*.16)
                verts=[(xx-.024,.01,zz),(xx+.024,.01,zz),(mid[0]+.025,mid[1],mid[2]),end,(mid[0]-.025,mid[1],mid[2])]
                ob=mesh('Reed leaf',verts,[(0,1,2,3,4),(4,3,2,1,0)],'Reed')
# Detail clumps near dock front for spatial grounding.
for i in range(22):
    side=-1 if i%2 else 1;x=side*R.uniform(3.0,5.5);z=R.uniform(2.8,5.5)
    for k in range(3):
        a=R.random()*math.tau;h=R.uniform(.35,.85)
        tube('Foreground rush',[(x,.12,z),(x+math.cos(a)*.14,h*.7,z),(x+math.cos(a)*.3,h,z+math.sin(a)*.3)],[.018,.013,.003],'GrassDry',5)
# Small managed fishery marker on rear bank, no baked text/2D backdrop.
for x in [3.0,4.1]:box('Sign post',(x,.95,5.7),(.08,1.4,.08),'DockWeathered',.01)
box('Fishery sign',(3.55,1.55,5.7),(1.34,.56,.075),'Enamel',.03)
# Consolidate by material to a small draw-call count; preserve leaf materials for wind shader.
for material in list(M):
    objs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials and o.data.materials[0].name==material]
    if not objs:continue
    bpy.ops.object.select_all(action='DESELECT')
    for ob in objs:ob.select_set(True)
    bpy.context.view_layer.objects.active=objs[0];bpy.ops.object.join();ob=objs[0];ob.name=material
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    # Weighted visual softness on crafted hard edges; crowns remain low-poly textured by topology.
    for p in ob.data.polygons:p.use_smooth=material in ['Bark','BarkLight','Enamel','Iron','Rope'] or material.startswith('Foliage')
    # Triangulate consistent winding and import topology.
    mod=ob.modifiers.new('Deterministic triangles','TRIANGULATE');bpy.ops.object.modifier_apply(modifier=mod.name)
triangles=sum(len(o.data.polygons) for o in bpy.context.scene.objects if o.type=='MESH')
objects=sum(o.type=='MESH' for o in bpy.context.scene.objects)
bpy.ops.export_scene.gltf(filepath=str(OUT/'managed_oxbow.glb'),export_format='GLB',export_animations=False,export_yup=True,export_materials='EXPORT',export_apply=True)
report={'asset':'managed_oxbow.glb','authoring':'Original deterministic parametric Blender mesh construction; no third-party model or texture input','seed':81207,'triangles':triangles,'mesh_nodes':objects,'unit':'meter','up':'+Y','view_direction':'-Z','location':'Managed Mississippi oxbow test fishery; intentionally low alluvial banks','water':'Separate real-time stage surface','build':'blender -b --python tools/art3d/build_environment.py'}
(OUT/'manifest.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report))
