"""Original native 3D regional environment and fishing stations, Blender4.3+.
Shared builder: --region lake|japan|norway|med|bayou|yangtze or --station dock|rock|boat.
Only the selected biome or station is authored/exported in each invocation.
All geometry is original; optional runtime CC0 PBR textures are credited separately.
"""
import bpy, math, random, json, sys, argparse
from pathlib import Path
from mathutils import Vector
R = random.Random(81207)
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT/'game/assets/3d/environment'
OUT.mkdir(parents=True, exist_ok=True)
parser=argparse.ArgumentParser()
parser.add_argument('--region',choices=['lake','japan','norway','med','bayou','yangtze'],default='bayou')
parser.add_argument('--station',choices=['dock','rock','boat'])
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
REGION=args.region
PROFILES={
 'lake':dict(width=17,height=1.8,widen=.005,coast=False,style='broad',trees=13,reeds=52,rocks=48,leaf_density=.98),
 'japan':dict(width=11.5,height=7.0,widen=.24,coast=True,style='pine',trees=10,reeds=0,rocks=95,leaf_density=.98),
 'norway':dict(width=13,height=55,widen=.035,coast=True,style='pine',trees=12,reeds=0,rocks=62,leaf_density=1.0),
 'med':dict(width=15,height=7.5,widen=.26,coast=True,style='olive',trees=10,reeds=0,rocks=75,leaf_density=.94),
 'bayou':dict(width=9.8,height=.95,widen=0,coast=False,style='broad',trees=14,reeds=45,rocks=36,leaf_density=1.0),
 'yangtze':dict(width=26,height=1.2,widen=.12,coast=False,style='broad',trees=9,reeds=30,rocks=48,leaf_density=.94),
}
CFG=PROFILES[REGION]
R.seed({'lake':81111,'japan':82222,'norway':83333,'med':84444,'bayou':81207,'yangtze':86666}[REGION])
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
M = {}
def mat(name, color, rough=.8, metallic=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=(*color,1)
    bs.inputs['Roughness'].default_value=rough; bs.inputs['Metallic'].default_value=metallic
    M[name]=m; return m
for n,c in {'DockHoney':(.39,.245,.112),'DockPale':(.47,.315,.166),'DockWeathered':(.31,.216,.13),'WoodEndgrain':(.23,.15,.085),'Iron':(.105,.15,.155),'Rope':(.44,.38,.255),'Bark':(.20,.17,.105),'BarkLight':(.29,.25,.155),'FoliageDeep':(.075,.18,.115),'FoliageGreen':(.15,.285,.13),'FoliageSun':(.29,.38,.15),'FoliageGold':(.385,.405,.20),'Grass':(.25,.32,.155),'GrassDry':(.43,.41,.215),'Soil':(.30,.245,.155),'Mud':(.195,.20,.145),'Sand':(.49,.435,.285),'Stone':(.32,.36,.315),'StoneWarm':(.40,.39,.30),'Reed':(.28,.32,.12),'Cattail':(.20,.115,.055),'Canvas':(.70,.62,.37),'Enamel':(.14,.33,.30),'Paper':(.82,.78,.59)}.items(): mat(n,c,.36 if n=='Enamel' else .85,.65 if n=='Iron' else 0)
mat('Cliff',(.29,.32,.31),.91)
mat('Roof',(.10,.14,.17),.82)
mat('HarborRed',(.37,.08,.055),.85)
mat('Plaster',(.68,.67,.57),.82)
mat('NavyHull',(.055,.12,.16),.34,.16)
mat('WarmStone',(.53,.46,.32),.88)
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
    # Hundreds of individual curved, closed leaves, with no primitive canopy shell.
    # No opacity cards, sprite textures, or billboard forest meshes.
    center=Vector(center); rx,ry,rz=radii
    verts=[]; faces=[]
    for k in range(int(count*CFG["leaf_density"])):
        a=R.random()*math.tau; v=R.uniform(-.95,.95); radial=math.sqrt(1-v*v)
        r=R.uniform(.50,1.04)
        q=center+Vector((rx*radial*math.cos(a),ry*v,rz*radial*math.sin(a)))*r
        # Leaves are cupped along the midrib and twist away from their branch.
        direction=Vector((math.cos(a),R.uniform(-.9,.65),math.sin(a))).normalized()
        side=direction.cross(Vector((0,1,0))).normalized()
        if side.length<.1: side=Vector((1,0,0))
        up=side.cross(direction).normalized()
        length=R.uniform(.25,.40) if CFG['style']=='pine' else R.uniform(.30,.47)*(1.05 if willow else 1.0)
        width=length*(.24 if CFG['style']=='pine' else (.19 if CFG['style']=='olive' else (.21 if willow else R.uniform(.28,.40))))
        base=len(verts)
        points=[q,q+direction*length*.44+side*width,q+direction*length+up*length*.08,q+direction*length*.44-side*width,q+direction*length*.45+up*length*.12,q+direction*length*.44-up*.005]
        verts += [tuple(p) for p in points]
        faces += [(base+0,base+1,base+4),(base+1,base+2,base+4),(base+2,base+3,base+4),(base+3,base+0,base+4),(base+1,base+0,base+5),(base+2,base+1,base+5),(base+3,base+2,base+5),(base+0,base+3,base+5)]
    mesh('Foliage individual curved leaves',verts,faces,material)


def build_dock():
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

    for x in [3.0,4.1]:box('Sign post',(x,.95,5.7),(.08,1.4,.08),'DockWeathered',.01)
    box('Fishery sign',(3.55,1.55,5.7),(1.34,.56,.075),'Enamel',.03)

def add_crate():
    box('Tackle crate',(.55,.81,2.6),(.63,.45,.48),'Enamel',.035)
    box('Tackle lid',(.55,1.05,2.6),(.68,.065,.51),'Canvas',.02)
    tube('Tackle handle',[(.34,1.1,2.6),(.34,1.18,2.6),(.75,1.18,2.6),(.75,1.1,2.6)],[.022]*4,'Iron',6)

def build_rock_station():
    # Level central footing, irregular solid rock apron reaching below the water.
    n=28;vs=[]
    for ring in range(3):
        for i in range(n):
            a=i*math.tau/n;rad=1+R.uniform(-.07,.07)
            rx=(2.15 if ring<2 else 1.7)*rad;rz=(3.15 if ring<2 else 2.8)*rad
            y=.584 if ring==0 else (-.1 if ring==1 else -1.45)
            vs.append((-.55+math.cos(a)*rx,y,1.1+math.sin(a)*rz))
    fs=[tuple(reversed(range(n)))]
    for r in range(2):
        for i in range(n):fs.append((r*n+i,r*n+(i+1)%n,(r+1)*n+(i+1)%n,(r+1)*n+i))
    mesh('Rock fishing ledge',vs,fs,'WarmStone')

def build_boat_station():
    # Full three-dimensional molded hull, broad stable fishing deck, stern motor.
    ribs=[(-2.95,.04),(-2.35,.88),(-1.1,1.44),(.4,1.57),(2.3,1.57),(3.55,1.43)]
    vs=[];fs=[]
    for z,w in ribs:
        vs += [(-.55-w,.82,z),(-.55-w*.98,.15,z),(-.55-w*.68,-.44,z),(-.55-w*.14,-.57,z),(-.55+w*.14,-.57,z),(-.55+w*.68,-.44,z),(-.55+w*.98,.15,z),(-.55+w,.82,z)]
    for r in range(len(ribs)-1):
        for j in range(7):fs.append((r*8+j,r*8+j+1,(r+1)*8+j+1,(r+1)*8+j))
    fs += [tuple(reversed(range(8))),tuple((len(ribs)-1)*8+j for j in range(8))]
    mesh('Closed fishing boat hull',vs,fs,'NavyHull')
    deck=[(-.55-w,.584,z) for z,w in ribs]+[(-.55+w,.584,z) for z,w in reversed(ribs)]
    mesh('Timber fishing deck',deck,[tuple(range(len(deck)))],'DockPale')
    for side in [-1,1]:
        pts=[(-.55+side*w,.83,z) for z,w in ribs]
        tube('Boat gunwale',pts,[.058]*len(pts),'Plaster',10)
        tube('Boat lower strake',[(-.55+side*w*.98,.19,z) for z,w in ribs],[.025]*len(pts),'Iron',8)
    box('Stern seat',(-.55,.91,2.72),(2.56,.12,.48),'DockHoney',.035)
    for x in [-1.6,.5]:box('Seat support',(x,.70,2.72),(.10,.33,.35),'Iron',.018)
    box('Outboard casing',(-.55,.58,3.82),(.58,.71,.40),'NavyHull',.09)
    tube('Outboard shaft',[(-.55,.3,3.91),(-.55,-.45,3.91)],[.045,.038],'Iron',10)
    box('Outboard propeller',(-.55,-.42,3.92),(.46,.065,.09),'Iron',.02)
    add_crate()

def bank_edge(z,side):
    width=CFG['width']+1.9*math.sin(z*.065)+1.4*math.cos(z*.14)+max(0,-z)*CFG['widen']
    return side*width

def ground_height(x,z):
    if z<-100 and not CFG['coast']:return .55+min((-z-100)*.012,.6)
    edge=abs(bank_edge(z,1));d=max(0,abs(x)-edge)
    if CFG['height']>20:
        value=-.20+d*.20 if d<5 else .8+CFG['height']*pow(min((d-5)/29,1),.72)
        variation=(math.sin(z*.11+x*.12)*1.9+math.sin(z*.49+x*.33)*.48)*min(d/12,1)
    elif CFG['coast']:
        value=-.24+CFG['height']*pow(min(d/17,1),.72)
        variation=(math.sin(z*.25+x*.33)*.75+math.sin(z*.77)*.22)*min(d/4,1)
    else:
        value=-.20 if d<.1 else .22+min(d/14,1)*CFG['height']
        variation=.19*math.sin(x*.32+z*.18)+.09*math.cos(z*.8)
    return value+variation

def build_terrain():
    rows=61;cols=22
    for side in [-1,1]:
        vs=[];fs=[]
        for iz in range(rows):
            z=8-iz*2.6;edge=bank_edge(z,side)
            for ix in range(cols):
                x=edge+side*ix*3.1;vs.append((x,ground_height(x,z),z))
        for iz in range(rows-1):
            for ix in range(cols-1):
                a=iz*cols+ix;fs.append((a,a+1,a+cols+1,a+cols) if side==1 else (a+cols,a+cols+1,a+1,a))
        mesh('Continuous sculpted bank',vs,fs,'Cliff' if CFG['coast'] else 'Grass')
        vs=[];fs=[]
        for iz in range(rows):
            z=8-iz*2.6;edge=bank_edge(z,side)
            vs.extend([(edge-side*.70,-.28,z),(edge+side*.66,.10+math.sin(z*.3)*.05,z)])
        for iz in range(rows-1):
            a=iz*2;fs.append((a,a+1,a+3,a+2) if side==1 else (a+2,a+3,a+1,a))
        mesh('Wet sculpted shoreline',vs,fs,'Stone' if CFG['coast'] else 'Mud')
    mesh('Walk-in land',[(-60,.06,3.8),(-9,.04,2.8),(-4,.18,3.6),(2,.25,4.3),(12,.05,3.5),(60,.03,4),(60,.42,38),(-60,.42,38)],[(0,1,2,3,4,5,6,7)],'Cliff' if CFG['coast'] else 'Soil')
    if not CFG['coast']:
        mesh('Far low shore',[(-95,-.08,-96),(95,-.08,-96),(95,.55,-108),(-95,.55,-108),(-95,1.0,-150),(95,1.0,-150)],[(0,1,2,3),(3,2,5,4)],'Grass')

def pine(x,z,h):
    y=ground_height(x,z)+.02;root=Vector((x,y,z));lean=R.uniform(-.35,.35)
    tube('Conifer trunk',[root,root+Vector((lean*.4,h*.50,0)),root+Vector((lean,h,0))],[h*.025,h*.015,.012],'Bark',12)
    layers=6
    for layer in range(layers):
        level=(.47 if REGION=='japan' else .24)+layer*(.078 if REGION=='japan' else .12)
        reach=h*(.32 if REGION=='japan' else .26)*(1-layer/(layers+1))
        for j in range(5):
            a=j*math.tau/5+layer*.76;start=root+Vector((lean*.4,h*level,0));end=root+Vector((math.cos(a)*reach,h*level-.08,math.sin(a)*reach))
            tube('Conifer bough',[start,(start+end)*.5+Vector((0,-.12,0)),end],[h*.012,h*.007,.009],'BarkLight',7)
            center=start.lerp(end,.66)+Vector((0,h*.04,0))
            leaf_crown(center,(max(.22,reach*.51),h*.075,max(.22,reach*.42)),h,R.choice(['FoliageDeep','FoliageGreen','FoliageSun']),135 if z>-45 else 100)
def tree(x,z,h,willow=False):
    if CFG['style']=='pine':return pine(x,z,h)
    y=ground_height(x,z)+.02; root=Vector((x,y,z)); lean=R.uniform(-.5,.5)
    tube('Trunk',[root,root+Vector((lean*.3,h*.46,0)),root+Vector((lean,h*.88,.18))],[h*.055,h*.033,h*.009],'Bark',14)
    # Buttress-root flares, highly characteristic river trees.
    for j in range(5 if REGION=='bayou' else 2):
        a=j*math.tau/5
        tube('Buttress root',[(x+math.cos(a)*h*.12,y,z+math.sin(a)*h*.12),(x,y+h*.3,z)],[h*.025,h*.037],'Bark',10)
    count=9 if willow else 7
    for j in range(count):
        a=j*2.4; level=.44+(j/count)*.42; reach=h*R.uniform(.22,.37)
        end=root+Vector((math.cos(a)*reach+lean,h*level,math.sin(a)*reach))
        tube('Limb',[root+Vector((lean*.5,h*level*.66,0)),end],[h*.025,h*.007],'BarkLight',10)
        c=end+Vector((0,h*.11,0));r=h*R.uniform(.18,.27)
        leaf_crown(c,(r*1.25,r*.68,r),h,R.choice(['FoliageGreen','FoliageSun','FoliageGold']),460 if z>-40 else (195 if z>-85 else 120),willow)
        if willow:
            for k in range(4):
                theta=a+k*1.4;hang=c+Vector((math.cos(theta)*r*.67,-h*.19,math.sin(theta)*r*.67))
                leaf_crown(hang,(r*.37,h*.24,r*.35),h,'FoliageGreen',60,True)
    leaf_crown(root+Vector((lean,h*.93,0)),(h*.24,h*.18,h*.24),h,'FoliageSun',400 if z>-40 else (195 if z>-85 else 120),willow)

def add_house(x,z):
    y=ground_height(x,z);w=3.0;d=3.9;h=2.8
    box('Red timber harbor cabin',(x,y+h/2,z),(w,h,d),'HarborRed',.045)
    top=[Vector(v) for v in [(x-w*.59,y+h,z-d*.59),(x,y+h+1.35,z-d*.59),(x+w*.59,y+h,z-d*.59),(x-w*.59,y+h,z+d*.59),(x,y+h+1.35,z+d*.59),(x+w*.59,y+h,z+d*.59)]]
    # Two solid roof slabs: overhanging eaves, visible thickness and beveled edges.
    for order in [(0,3,4,1),(1,4,5,2)]:
        q=[top[i] for i in order];normal=(q[1]-q[0]).cross(q[2]-q[0]).normalized()
        vs=q+[p-normal*.14 for p in q]
        faces=[(0,1,2,3),(7,6,5,4)]+[(i,i+4,(i+1)%4+4,(i+1)%4) for i in range(4)]
        ob=mesh('Solid eaved roof',vs,faces,'Roof');bpy.context.view_layer.objects.active=ob
        bevel=ob.modifiers.new('Rounded roof edge','BEVEL');bevel.width=.024;bevel.segments=1;bpy.ops.object.modifier_apply(modifier=bevel.name)
    mesh('Timber gables',top,[(0,1,2),(3,5,4)],'HarborRed')
    for xx in [x-.83,x+.83]:
        box('Window casing',(xx,y+1.68,z+d/2+.035),(.73,.87,.11),'Plaster',.014)
        box('Window glass',(xx,y+1.68,z+d/2+.10),(.54,.67,.015),'Iron')
        box('Window vertical mullion',(xx,y+1.68,z+d/2+.123),(.038,.68,.028),'Plaster',.006)
        box('Window horizontal mullion',(xx,y+1.68,z+d/2+.127),(.55,.038,.028),'Plaster',.006)
    box('Door casing',(x,y+.95,z+d/2+.06),(.76,1.90,.10),'Plaster',.018)
    box('Timber door',(x,y+.94,z+d/2+.121),(.57,1.73,.032),'DockWeathered',.012)
    blob('Door handle',(x+.19,y+.95,z+d/2+.164),(.033,.033,.033),'Iron',2,0)
    box('Stone threshold',(x,y+.085,z+d/2+.27),(.98,.17,.68),'Stone',.04)

def add_lighthouse():
    z=-28;x=bank_edge(z,-1)-3.0;y=ground_height(x,z)
    tube('Lighthouse shaft',[(x,y,z),(x,y+7.0,z)],[.91,.63],'Plaster',24)
    for yy in [y+1.4,y+3.8]:tube('Lighthouse painted band',[(x,yy,z),(x,yy+.52,z)],[.87-(yy-y)*.038,.87-(yy-y+.52)*.038],'HarborRed',24)
    tube('Lantern deck',[(x,y+7.02,z),(x,y+7.18,z)],[.97,.97],'Iron',24)
    tube('Lantern housing',[(x,y+7.2,z),(x,y+8.25,z)],[.68,.68],'Enamel',16)
    tube('Lantern roof',[(x,y+8.25,z),(x,y+8.85,z)],[.98,.07],'Roof',24)
    for j in range(8):
        a=j*math.tau/8;tube('Lantern upright',[(x+math.cos(a)*.71,y+7.17,z+math.sin(a)*.71),(x+math.cos(a)*.71,y+8.26,z+math.sin(a)*.71)],[.038,.038],'Iron',6)

def add_sandbar(x,z):
    n=36;vs=[(x,.29,z)];fs=[]
    for ring in range(1,6):
        f=ring/5
        for i in range(n):
            a=i*math.tau/n;r=f*(1+.07*math.sin(a*5)+.035*math.cos(a*9))
            vs.append((x+math.cos(a)*9*r,.30*(1-f*f)-.12*f,z+math.sin(a)*16*r))
    for i in range(n):fs.append((0,1+(i+1)%n,1+i))
    for ring in range(1,5):
        for i in range(n):
            a=1+(ring-1)*n+i;b=1+(ring-1)*n+(i+1)%n;c=1+ring*n+i;d=1+ring*n+(i+1)%n;fs.append((a,b,d,c))
    mesh('Organic alluvial sandbar',vs,fs,'Sand')

def build_region():
    build_terrain()
    for side in [-1,1]:
        for i in range(CFG['trees']):
            z=3-i*8.0+R.uniform(-2,2);x=bank_edge(z,side)+side*R.uniform(2.6,7.5)
            h=R.uniform(3.1,5.4) if REGION=='med' else R.uniform(5.1,8.3)
            tree(x,z,h,REGION=='bayou' and i%4==0)
        for i in range(max(6,CFG['trees']//2)):
            z=-10-i*13.0;x=bank_edge(z,side)+side*R.uniform(11,23)
            tree(x,z,R.uniform(4.3,7.4),False)
    if not CFG['coast']:
        for i in range(25):tree(-74+i*6.1+R.uniform(-1,1),-110+R.uniform(-4,2),R.uniform(4.6,7.5),REGION=='bayou' and i%7==0)
    if REGION in ['lake','bayou']:tree(-6.4,3.2,7.8,REGION=='bayou')
    for side in [-1,1]:
        for i in range(CFG['rocks']):
            z=5-R.random()*126;x=bank_edge(z,side)+side*R.uniform(-.20,2.6);y=ground_height(x,z)
            size=R.uniform(.30,1.8 if CFG['coast'] else .72)
            blob('Shore boulder',(x,y-.1,z),(size,R.uniform(.45,.9)*size,size*R.uniform(.75,1.3)),R.choice(['Stone','StoneWarm']),2,.13)
        for i in range(CFG['reeds']):
            z=4-i*2.3+R.uniform(-1,1);x=bank_edge(z,side)+side*R.uniform(-.12,.9)
            for k in range(5):
                xx=x+R.uniform(-.45,.45);zz=z+R.uniform(-.45,.45);h=R.uniform(.45,1.1)
                tube('Reed stem',[(xx,-.02,zz),(xx+.07,h*.7,zz),(xx+.08,h,zz)],[.014,.01,.004],'Reed',5)
                if k%3==0:tube('Cattail head',[(xx+.078,h*.8,zz),(xx+.08,h*1.02,zz)],[.036,.03],'Cattail',6)
                for a in [R.random()*math.tau,R.random()*math.tau]:
                    end=(xx+math.cos(a)*h*.28,h*.56,zz+math.sin(a)*h*.28);mid=(xx+math.cos(a)*h*.16,h*.85,zz+math.sin(a)*h*.16)
                    mesh('Curved reed leaf',[(xx-.024,.01,zz),(xx+.024,.01,zz),(mid[0]+.025,mid[1],mid[2]),end,(mid[0]-.025,mid[1],mid[2])],[(0,1,2,3,4),(4,3,2,1,0)],'Reed')
    if REGION=='japan':add_lighthouse()
    if REGION=='norway':
        for z in [-10,-19,-29]:add_house(bank_edge(z,-1)-2.6,z)
    if REGION=='med':
        for i in range(15):
            z=-5-i*.86;x=bank_edge(z,-1)-1.1;y=ground_height(x,z)
            for row in range(3):box('Dry stone harbor wall',(x,y+.19+row*.34,z+R.uniform(-.08,.08)),(.66,.32,.80),'WarmStone',.055)
    if REGION=='yangtze':add_sandbar(-2,-42)

if args.station=='dock':build_dock()
elif args.station=='rock':build_rock_station()
elif args.station=='boat':build_boat_station()
else:build_region()
# Merge by material only after building the chosen biome. Runtime never builds all maps.
for material in list(M):
    objs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials and o.data.materials[0].name==material]
    if not objs:continue
    bpy.ops.object.select_all(action='DESELECT')
    for ob in objs:ob.select_set(True)
    bpy.context.view_layer.objects.active=objs[0];bpy.ops.object.join();ob=objs[0];ob.name=material
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    for poly in ob.data.polygons:poly.use_smooth=material in ['Bark','BarkLight','Enamel','Iron','Rope','Cliff','Stone','StoneWarm','WarmStone','NavyHull'] or material.startswith('Foliage')
    mod=ob.modifiers.new('Deterministic triangles','TRIANGULATE');bpy.ops.object.modifier_apply(modifier=mod.name)
triangles=sum(len(o.data.polygons) for o in bpy.context.scene.objects if o.type=='MESH')
objects=sum(o.type=='MESH' for o in bpy.context.scene.objects)
filename='station_'+args.station if args.station else 'region_'+REGION
bpy.ops.export_scene.gltf(filepath=str(OUT/(filename+'.glb')),export_format='GLB',export_animations=False,export_yup=True,export_materials='EXPORT',export_apply=True)
report={'asset':filename+'.glb','region':REGION if not args.station else None,'station':args.station,'authoring':'Original deterministic parametric Blender geometry; no third-party mesh','triangles':triangles,'mesh_nodes':objects,'unit':'meter','up':'+Y','view_direction':'-Z','runtime_surface_textures':'Separately credited CC0 HDRI, timber and rock PBR maps','profile':CFG if not args.station else {},'build':'blender -b -t 4 --python tools/art3d/build_environment.py -- '+('--station '+args.station if args.station else '--region '+REGION)}
(OUT/(filename+'.json')).write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report),flush=True)
