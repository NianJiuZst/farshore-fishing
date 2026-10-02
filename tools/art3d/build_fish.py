#!/usr/bin/env python3
"""Original Farshore fish: deterministic volumetric meshes, packed PBR maps, rigs.
Run: blender -b --python tools/art3d/build_fish.py -- [--species all|common_carp|alligator_gar]
Output only in declared fish asset and review paths. No external artwork is sampled.
"""
import bpy, bmesh, math, sys, os, json, argparse, random
import numpy as np
from mathutils import Vector
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
REV=ROOT/'ownbuild/fish3d-review'
for p in (ROOT/'art_masters/3d',ROOT/'game/assets/3d',REV): p.mkdir(parents=True,exist_ok=True)
TAU=math.tau
MESHES=[]
WEIGHTS={}
SPEC=''
PROFILES=[]

def mat(name,color,rough=.38,metal=0.0):
    m=bpy.data.materials.new(name); m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF'); p.inputs['Base Color'].default_value=(*color,1)
    p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
    p.inputs['Coat Weight'].default_value=.13;p.inputs['Coat Roughness'].default_value=.25
    return m

def packed_image(name,array,noncolor=False):
    h,w=array.shape[:2]; image=bpy.data.images.new(name,width=w,height=h,alpha=True)
    if noncolor:image.colorspace_settings.name='Non-Color'
    rgba=np.ones((h,w,4),dtype=np.float32);rgba[:,:,:array.shape[2]]=array
    image.pixels.foreach_set(rgba.ravel()); image.pack();return image

def texture_material(spec,fin=False):
    # UV atlas painted analytically at production resolution; normals use the same sculpted height.
    W,H=(1024,512) if fin else (2048,1024)
    u,v=np.meshgrid(np.arange(W,dtype=np.float32)/W,np.arange(H,dtype=np.float32)/H)
    rng=np.random.default_rng(621 if spec=='common_carp' else 737)
    noise=rng.random((H,W),dtype=np.float32)-.5
    if fin:
        t=v; shade=.80+.20*np.sin(u*TAU*17)**8
        if spec=='common_carp':
            base=np.array([.44,.265,.112]);tip=np.array([.22,.15,.085])
        else:base=np.array([.50,.47,.305]);tip=np.array([.27,.27,.19])
        col=base[None,None,:]*(1-t[:,:,None]*.60)+tip[None,None,:]*(t[:,:,None]*.60)
        col=np.broadcast_to(col,(H,W,3)).copy()*shade[:,:,None]
        height=.12*np.sin(u*TAU*17)**12*(.3+.7*t)
        if spec=='alligator_gar':
            spots=np.zeros((H,W))
            for i in range(38):
                cx,cy=rng.uniform(0,1),rng.uniform(.22,.95)
                r=rng.uniform(.023,.047)
                spots=np.maximum(spots,np.exp(-(((u-cx)/r)**2+((v-cy)/(r*.7))**2)*2))
            col*=1-.77*spots[:,:,None]
        rough=.49+.08*noise
    else:
        # v=0 is upper midline; body profile uses y=sin(theta), z=cos(theta).
        upper=(np.cos(v*TAU)+1)*.5
        side=np.array([.55,.365,.115]) if spec=='common_carp' else np.array([.43,.425,.235])
        belly=np.array([.77,.65,.39]) if spec=='common_carp' else np.array([.72,.715,.54])
        back=np.array([.14,.175,.095]) if spec=='common_carp' else np.array([.135,.17,.105])
        col=np.where((upper<.5)[:,:,None],belly[None,None,:]*(1-upper[:,:,None]*2)+side[None,None,:]*upper[:,:,None]*2,side[None,None,:]*(2-upper[:,:,None]*2)+back[None,None,:]*(upper[:,:,None]*2-1))
        head=np.clip((u-(.70 if spec=='common_carp' else .66))/.080,0,1)
        if spec=='common_carp':
            row=np.floor(v*22); sy=(v*22)%1-.5
            sx=(u*35+(row%2)*.5)%1-.5
            edge=.49-1.94*sy*sy
            d=sx-edge
            seam=np.exp(-(d/.035)**2)
            rim=np.exp(-((d+.058)/.04)**2)
            rings=(.5+.5*np.cos((d+.08)*65))*.055*np.exp(-((d+.14)/.18)**2)
            cells=(np.sin(np.floor(u*35+(row%2)*.5)*48.23+row*21.18)*1453.23)%1
            height=(.43+rim*.23-seam*.55+rings)*(1-head)
            col*= (1-.37*seam[:,:,None]*(1-head[:,:,None]))
            col+=rim[:,:,None]*(1-head[:,:,None])*np.array([.13,.09,.03])
            col*=1+(.27*(cells-.5)*(1-head))[:,:,None]
        else:
            a=u*46+v*17;b=u*46-v*17
            da=np.minimum(a%1,1-a%1);db=np.minimum(b%1,1-b%1)
            seam=np.exp(-(np.minimum(da,db)/.045)**2)
            cells=(np.sin(np.floor(a)*38.2+np.floor(b)*61.7)*413.91)%1
            height=(.38+.12*np.sin(a%1*math.pi)*np.sin(b%1*math.pi)-seam*.36)*(1-head)
            col*=1-.45*seam[:,:,None]*(1-head[:,:,None])
            col*=1+(.31*(cells-.5)*(1-head))[:,:,None]
            # Subtle adult flank flecks: avoid juvenile leopard pattern across the whole torso.
            speck=np.maximum(0,np.sin(u*153+np.cos(v*66))*np.cos(v*191-u*53)-.70)/.30
            col*=1-.28*speck[:,:,None]*(.3+.7*upper[:,:,None])
        # Slight lateral-line pigment, pore flecks and irregular head mottling.
        lat=np.exp(-((np.abs(np.cos(v*TAU))-.13)/.025)**2)*(1-head)
        col*=1-.12*lat[:,:,None]
        mottle=(np.sin(u*173+np.cos(v*89))*np.sin(v*211-u*61)+np.sin(u*591+v*129)*.3)
        col*=1+(.078*mottle+.028*noise)[:,:,None]
        headpores=np.maximum(0,np.sin(u*359)*np.sin(v*249)-.77)*head
        col*=1-.50*headpores[:,:,None]
        height+=noise*.023+mottle*.014*head
        rough=.36+.11*upper+.055*noise+.05*head
    col=np.clip(col,0,1)
    color=packed_image(spec+('_fin' if fin else '_skin')+'_basecolor',col)
    # Tangent-space normals: enough bevel definition to read, without glittering aliasing.
    gy,gx=np.gradient(height); strength=15 if fin else 23
    nx=-gx*strength;ny=-gy*strength;nz=np.ones_like(nx)
    norm=np.sqrt(nx*nx+ny*ny+nz*nz)
    normal=packed_image(spec+('_fin' if fin else '_skin')+'_normal',np.stack((nx/norm*.5+.5,ny/norm*.5+.5,nz/norm*.5+.5),axis=2),True)
    rm=packed_image(spec+('_fin' if fin else '_skin')+'_roughness',np.repeat(rough[:,:,None],3,axis=2),True)
    m=mat(spec+('_FinMembrane' if fin else '_ScaledSkin'),(.5,.4,.2),.42,.02)
    ns=m.node_tree.nodes;lk=m.node_tree.links;p=ns.get('Principled BSDF')
    for im,socket in ((color,'Base Color'),(rm,'Roughness')):
        tex=ns.new('ShaderNodeTexImage');tex.image=im;lk.new(tex.outputs['Color'],p.inputs[socket])
    tex=ns.new('ShaderNodeTexImage');tex.image=normal;n=ns.new('ShaderNodeNormalMap');n.inputs['Strength'].default_value=.34 if not fin else .25;lk.new(tex.outputs['Color'],n.inputs['Color']);lk.new(n.outputs['Normal'],p.inputs['Normal'])
    return m

def mesh(name,verts,faces,material,uv=None,weight=None):
    me=bpy.data.meshes.new(name);me.from_pydata(verts,[],faces);me.update()
    ob=bpy.data.objects.new(name,me);bpy.context.collection.objects.link(ob);me.materials.append(material)
    for p in me.polygons:p.use_smooth=True
    if uv:
        layer=me.uv_layers.new(name='UVMap')
        for poly in me.polygons:
            for li,vi in zip(poly.loop_indices,poly.vertices):layer.data[li].uv=uv[vi]
    MESHES.append(ob);WEIGHTS[ob.name]=weight
    return ob

def interp(x):
    # Shape-preserving cubic Hermite smooth rings. Broad cheek and belly are an authored profile.
    arr=PROFILES
    for i in range(len(arr)-1):
        if arr[i][0]<=x<=arr[i+1][0]:
            a,b=arr[i],arr[i+1];t=(x-a[0])/(b[0]-a[0]);out=[]
            for j in range(1,5):
                p0=arr[max(0,i-1)];p3=arr[min(len(arr)-1,i+2)]
                m1=(b[j]-p0[j])/(b[0]-p0[0]);m2=(p3[j]-a[j])/(p3[0]-a[0])
                val=(2*t**3-3*t*t+1)*a[j]+(t**3-2*t*t+t)*(b[0]-a[0])*m1+(-2*t**3+3*t*t)*b[j]+(t**3-t*t)*(b[0]-a[0])*m2
                out.append(max(.001,val) if j<4 else val)
            return out
    return list(arr[0 if x<arr[0][0] else -1][1:])

def surface(x,theta,inflate=0):
    w,top,bot,cz=interp(x);c=math.cos(theta);s=math.sin(theta)
    return Vector((x,(w+inflate)*s,cz+((top if c>=0 else bot)+inflate)*c))

def body(material):
    n,m=90,48;verts=[];faces=[];uv=[]
    lo,hi=PROFILES[0][0],PROFILES[-1][0]
    for i in range(n+1):
        x=lo+(hi-lo)*i/n
        for j in range(m+1):
            th=TAU*j/m;verts.append(surface(x,th));uv.append((i/n,j/m))
    for i in range(n):
        for j in range(m):
            a=i*(m+1)+j;faces.append((a,a+1,a+m+2,a+m+1))
    faces.extend((tuple(range(m,-1,-1)),tuple(n*(m+1)+j for j in range(m+1))))
    return mesh('Body_SculptedLoft',verts,faces,material,uv,'spine')

def tube(name,points,radius,material,weight='spine',rings=7):
    verts=[];faces=[];uv=[];p=[Vector(a) for a in points]
    for i,pt in enumerate(p):
        tan=(p[min(i+1,len(p)-1)]-p[max(i-1,0)]).normalized()
        u=tan.cross(Vector((0,0,1)))
        if u.length<.1:u=tan.cross(Vector((0,1,0)))
        u.normalize();v=tan.cross(u).normalized()
        rr=radius if isinstance(radius,(int,float)) else radius[i]
        for j in range(rings):
            verts.append(pt+rr*(u*math.cos(j*TAU/rings)+v*math.sin(j*TAU/rings)));uv.append((j/rings,i/max(1,len(p)-1)))
    for i in range(len(p)-1):
        for j in range(rings):
            a=i*rings+j;b=i*rings+(j+1)%rings;faces.append((a,b,b+rings,a+rings))
    faces.append(tuple(reversed(range(rings))));faces.append(tuple((len(p)-1)*rings+j for j in range(rings)))
    return mesh(name,verts,faces,material,uv,weight)

def sphere(name,loc,scale,material,weight='head',seg=24,rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg,ring_count=rings,location=loc)
    o=bpy.context.object;o.name=name;o.scale=scale;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    o.data.materials.append(material)
    for p in o.data.polygons:p.use_smooth=True
    MESHES.append(o);WEIGHTS[o.name]=weight;return o

def resample(points,count):
    control=[Vector(p) for p in points];ps=[]
    for i in range(len(control)-1):
        p0=control[max(0,i-1)];p1=control[i];p2=control[i+1];p3=control[min(len(control)-1,i+2)]
        for t in np.linspace(0,1,12,endpoint=False):
            ps.append(.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t))
    ps.append(control[-1]);ds=[0]
    for a,b in zip(ps,ps[1:]):ds.append(ds[-1]+(b-a).length)
    out=[]
    for q in np.linspace(0,ds[-1],count):
        k=next((k for k in range(len(ds)-1) if ds[k]<=q<=ds[k+1]),len(ds)-2)
        out.append(ps[k].lerp(ps[k+1],(q-ds[k])/max(1e-9,ds[k+1]-ds[k])))
    return out

def fin(name,rootline,edge,bone,material,raymat,rays=18,paired=False):
    roots=resample(rootline,rays);edges=resample(edge,rays)
    v=[];uv=[];f=[];steps=7
    for i in range(rays):
        for j in range(steps):
            t=j/(steps-1);p=roots[i].lerp(edges[i],t)
            # A slight sail camber keeps fins dimensional, with a solid fine rim.
            p.y+=math.sin(math.pi*t)*.003*math.sin(i*math.pi/(rays-1))
            v.append(p);uv.append((i/(rays-1),t))
    for i in range(rays-1):
        for j in range(steps-1):
            a=i*steps+j;f.append((a,a+steps,a+steps+1,a+1))
    ob=mesh(name+'_Membrane',v,f,material,uv,('fin',bone))
    bpy.context.view_layer.objects.active=ob;ob.select_set(True)
    sol=ob.modifiers.new('Membrane thickness','SOLIDIFY');sol.thickness=.0007;sol.offset=0
    bpy.ops.object.modifier_apply(modifier=sol.name);ob.select_set(False)
    # Genuine raised thin segmented rays; every ray follows the same deformation weights.
    for i in range(rays):
        pts=[]
        for j in range(6):
            t=j/5;p=roots[i].lerp(edges[i],t)
            p.y+=math.sin(math.pi*t)*.003*math.sin(i*math.pi/(rays-1))
            pts.append(p)
        tube(name+'_Ray%02d'%i,pts,[.00078*(1-j/5*.76) for j in range(6)],raymat,('fin',bone),5)
    return ob

def make_bones(spec):
    bpy.ops.object.armature_add(enter_editmode=True,location=(0,0,0));a=bpy.context.object;a.name='FishRig'
    eb=a.data.edit_bones;eb.remove(eb[0])
    def bone(n,h,t,parent=None):
        b=eb.new(n);b.head=h;b.tail=t
        if parent:b.parent=eb[parent]
        return b
    bone('root',(0,0,0),(0,0,.08))
    bone('head',(.24,0,0),(.46,0,0),'root')
    bone('spine_front',(.24,0,0),(.04,0,0),'root')
    bone('spine_mid',(.04,0,0),(-.15,0,0),'spine_front')
    bone('spine_rear',(-.15,0,0),(-.30,0,0),'spine_mid')
    bone('tail',(-.30,0,0),(-.44,0,0),'spine_rear')
    bone('caudal',(-.37,0,0),(-.49,0,0),'tail')
    if spec=='common_carp':
        p=(.25,.068,-.071);pel=(.005,.055,-.13);dor=(.11,0,.15);ana=(-.21,0,-.09)
        jh,jt=(.385,0,-.027),(.49,0,-.025);g=(.285,.07,.015)
    else:
        p=(.165,.049,-.036);pel=(-.085,.044,-.05);dor=(-.26,0,.048);ana=(-.28,0,-.044)
        jh,jt=(.252,0,-.014),(.491,0,-.019);g=(.197,.055,0)
    for side in (-1,1):
        suffix='L' if side==1 else 'R'
        bone('pectoral_'+suffix,(p[0],p[1]*side,p[2]),(p[0]-.09,(p[1]+.065)*side,p[2]-.07),'spine_front')
        bone('pelvic_'+suffix,(pel[0],pel[1]*side,pel[2]),(pel[0]-.09,(pel[1]+.045)*side,pel[2]-.045),'spine_mid')
        bone('gill_'+suffix,(g[0],side*g[1],g[2]),(g[0]-.025,side*(g[1]+.012),g[2]-.04),'head')
    bone('dorsal',dor,(dor[0]-.10,0,dor[2]+.075),'spine_mid' if spec=='common_carp' else 'spine_rear')
    bone('anal',ana,(ana[0]-.05,0,ana[2]-.065),'spine_rear')
    bone('jaw',jh,jt,'head')
    bpy.ops.object.mode_set(mode='OBJECT');a.show_in_front=True
    return a

def spine_weights(x):
    centers=[(.35,'head'),(.17,'spine_front'),(-.035,'spine_mid'),(-.205,'spine_rear'),(-.335,'tail'),(-.45,'caudal')]
    if x>=centers[0][0]:return {'head':1}
    if x<=centers[-1][0]:return {'caudal':1}
    for (a,an),(b,bn) in zip(centers,centers[1:]):
        if b<=x<=a:
            t=(a-x)/(a-b);t=t*t*(3-2*t);return {an:1-t,bn:t}

def bind(rig):
    for o in MESHES:
        kind=WEIGHTS[o.name]; groups={b.name:o.vertex_groups.new(name=b.name) for b in rig.data.bones}
        fin_t={}
        if isinstance(kind,tuple) and o.data.uv_layers:
            uvdata=o.data.uv_layers.active.data
            for poly in o.data.polygons:
                for li,vi in zip(poly.loop_indices,poly.vertices):fin_t[vi]=float(uvdata[li].uv.y)
        for v in o.data.vertices:
            if kind=='spine':
                w=spine_weights(v.co.x)
                if SPEC=='common_carp' and v.co.x>.37 and v.co.z<-.006:
                    jaw=min(1,max(0,(v.co.x-.37)/.10))*min(1,max(0,(-.006-v.co.z)/.032))*.85
                    w={k:val*(1-jaw) for k,val in w.items()};w['jaw']=jaw
            elif isinstance(kind,tuple):
                bn=kind[1]
                # Anchor the membrane to the traveling backbone, with progressive flexibility.
                t=min(1,max(0,fin_t.get(v.index,0)))
                w=spine_weights(v.co.x)
                w={k:val*(1-.70*t) for k,val in w.items()};w[bn]=w.get(bn,0)+.70*t
            else:w={kind:1}
            for k,val in w.items():
                if val>1e-4:groups[k].add([v.index],val,'REPLACE')
        mod=o.modifiers.new('Skin deformation','ARMATURE');mod.object=rig;o.parent=rig

def eyes(spec,mats):
    x=.350 if spec=='common_carp' else .263;z=.036 if spec=='common_carp' else .016
    w,top,bot,cz=interp(x);y=w*math.sqrt(max(0,1-((z-cz)/top)**2))-.001
    r=.012 if spec=='common_carp' else .0085
    for side in (-1,1):
        # Sockets recess into the head; near-spherical glossy eyes sit under a fleshy rim.
        sphere('EyeSocket_'+str(side),(x,side*y,z),(r*1.27,r*.40,r*1.2),mats['socket'])
        sphere('Iris_'+str(side),(x+.001,side*(y+r*.28),z),(r,r*.28,r),mats['iris'])
        sphere('Pupil_'+str(side),(x+.002,side*(y+r*.50),z),(r*.51,r*.12,r*.56),mats['pupil'])
        # Single catchlight is physical geometry; not a billboard.
        sphere('EyeGlint_'+str(side),(x+.005,side*(y+r*.61),z+r*.25),(r*.11,r*.035,r*.10),mats['glint'])
        points=[]
        for i in range(33):
            th=TAU*i/32;points.append((x+r*1.13*math.cos(th),side*(y+r*.26),z+r*1.11*math.sin(th)))
        tube('OrbitalRim_'+str(side),points,.0011,mats['edge'],'head',6)

def gills(spec,mats):
    for side in (-1,1):
        # Raised posterior operculum crescent, pinned to an independently animated gill bone.
        pts=[]
        if spec=='common_carp':
            for t in np.linspace(0,1,25):
                x=.287-.046*math.sin(math.pi*t)+.012*t;theta=(.35+2.35*t)*side
                pts.append(surface(x,theta,.0014))
        else:
            for t in np.linspace(0,1,25):
                x=.218-.026*math.sin(math.pi*t);theta=(.38+2.34*t)*side
                pts.append(surface(x,theta,.0012))
        bone='gill_L' if side==1 else 'gill_R'
        tube('OperculumGroove_'+str(side),pts,.0019 if spec=='common_carp' else .0012,mats['socket'],bone,6)
        inset=[p+Vector((.004,0,0)) for p in pts]
        tube('OperculumEdge_'+str(side),inset,.0014 if spec=='common_carp' else .0010,mats['edge'],bone,6)

def mouth(spec,mats):
    if spec=='common_carp':
        # Small fleshy protrusible mouth, without a cartoon smile or mammalian teeth.
        sphere('MouthCavity',(.478,0,-.012),(.010,.018,.010),mats['socket'],'head')
        for upper in (True,False):
            pts=[]
            for t in np.linspace(0,math.pi,20):
                pts.append((.481+.006*math.sin(t),.020*math.cos(t),-.012+(1 if upper else -1)*.009*math.sin(t)))
            tube('UpperLip' if upper else 'LowerLip',pts,.0025,mats['lip'],'head' if upper else 'jaw',8)
        for side in (-1,1):
            for short in (False,True):
                x=.465 if short else .452;yy=side*(.026 if short else .032)
                pts=[(x,yy,-.013),(x-.004,yy+side*.008,-.029),(x-.011,yy+side*.008,-.050 if not short else -.036),(x-.021,yy+side*.004,-.054 if not short else -.042)]
                tube(('SmallBarbel' if short else 'LongBarbel')+str(side),resample(pts,15),np.linspace(.0026,.0005,15).tolist(),mats['lip'],'jaw',7)
        # Two nostrils above snout.
        for side in (-1,1):sphere('Naris'+str(side),(.421,side*.033,.035),(.004,.0015,.0025),mats['socket'],'head',16,8)
    else:
        # Broad alligator-like upper snout and a separate flattened articulated lower jaw.
        verts=[];uv=[];faces=[];n=24;m=32
        for i in range(n+1):
            t=i/n;x=.255+t*.239;width=.042*(1-t)+.032*t
            if t>.9:width*=1-.34*(t-.9)/.1
            for j in range(m+1):
                a=TAU*j/m;verts.append((x,width*math.sin(a),-.016+.008*math.cos(a)));uv.append((.76+t*.24,j/m))
        for i in range(n):
            for j in range(m):
                a=i*(m+1)+j;faces.append((a,a+1,a+m+2,a+m+1))
        faces.extend([tuple(reversed(range(m+1))),tuple(n*(m+1)+j for j in range(m+1))])
        mesh('LowerJaw_Sculpt',verts,faces,mats['skin'],uv,'jaw')
        for side in (-1,1):
            pts=[]
            for t in np.linspace(0,1,35):
                x=.26+t*.233;w=.042*(1-t)+.032*t
                if t>.9:w*=1-.34*(t-.9)/.1
                pts.append((x,side*w,-.007))
            tube('JawSeam'+str(side),pts,.0012,mats['socket'],'head',6)
            tube('LowerJawLip'+str(side),[(p[0],p[1],p[2]-.004) for p in pts],.001,mats['edge'],'jaw',6)
            # Fine conical teeth rather than oversized monster fangs.
            for i in range(18):
                t=.15+i/19*.80;x=.26+t*.23;w=.042*(1-t)+.032*t
                bpy.ops.mesh.primitive_cone_add(vertices=6,radius1=.0013,radius2=.00015,depth=.0038,location=(x,side*w,-.0086))
                o=bpy.context.object;o.name='Dentition'+str(side)+'_%02d'%i;bpy.ops.object.transform_apply(location=True,rotation=True,scale=True);o.data.materials.append(mats['tooth']);MESHES.append(o);WEIGHTS[o.name]='jaw'
        for side in (-1,1):sphere('Naris'+str(side),(.467,side*.022,.011),(.004,.0018,.0018),mats['socket'],'head',16,8)

def fins(spec,m):
    F,R=m['fin'],m['ray']
    if spec=='common_carp':
        # Dorsal long base, rising front ray followed by gently scalloped trailing sail.
        fin('Dorsal',[(.17,0,.166),(.05,0,.173),(-.10,0,.128),(-.23,0,.071)],[(.18,0,.17),(.11,0,.284),(.038,0,.249),(-.06,0,.210),(-.17,0,.161),(-.251,0,.094)],'dorsal',F,R,27)
        fin('Anal',[(-.14,0,-.120),(-.23,0,-.085)], [(-.145,0,-.123),(-.207,0,-.207),(-.285,0,-.174),(-.266,0,-.095)],'anal',F,R,14)
        # Deep fork, two balanced lobes; cross-sectional thickness is real geometry.
        fin('Caudal',[(-.324,0,.045),(-.35,0,0),(-.324,0,-.045)],[(-.405,0,.128),(-.500,0,.174),(-.490,0,.116),(-.420,0,.008),(-.468,0,-.105),(-.490,0,-.164),(-.408,0,-.119)],'caudal',F,R,28)
        for side in (-1,1):
            s='L' if side==1 else 'R'
            fin('Pectoral_'+s,[(.267,side*.058,-.067),(.233,side*.067,-.088)],[(.264,side*.065,-.072),(.219,side*.142,-.133),(.147,side*.165,-.180),(.119,side*.12,-.182),(.200,side*.078,-.107)],'pectoral_'+s,F,R,17,True)
            fin('Pelvic_'+s,[(.034,side*.043,-.133),(-.009,side*.048,-.139)],[(.035,side*.046,-.135),(-.024,side*.093,-.221),(-.092,side*.107,-.232),(-.110,side*.064,-.194),(-.038,side*.051,-.143)],'pelvic_'+s,F,R,14,True)
    else:
        fin('Dorsal',[(-.215,0,.052),(-.327,0,.024)],[(-.212,0,.052),(-.253,0,.123),(-.294,0,.134),(-.333,0,.098),(-.363,0,.029)],'dorsal',F,R,18)
        fin('Anal',[(-.245,0,-.048),(-.333,0,-.024)],[(-.246,0,-.047),(-.289,0,-.108),(-.334,0,-.101),(-.363,0,-.046)],'anal',F,R,16)
        # Abbreviate heterocercal gar caudal: slightly extended upper axial lobe, rounded posterior edge.
        fin('Caudal',[(-.371,0,.026),(-.394,0,.005),(-.371,0,-.024)],[(-.427,0,.072),(-.475,0,.101),(-.497,0,.071),(-.500,0,.022),(-.495,0,-.029),(-.475,0,-.079),(-.448,0,-.083),(-.407,0,-.048)],'caudal',F,R,26)
        for side in (-1,1):
            s='L' if side==1 else 'R'
            fin('Pectoral_'+s,[(.177,side*.041,-.029),(.141,side*.048,-.039)],[(.177,side*.043,-.028),(.137,side*.105,-.091),(.090,side*.11,-.099),(.086,side*.075,-.087),(.133,side*.048,-.041)],'pectoral_'+s,F,R,16,True)
            fin('Pelvic_'+s,[(-.053,side*.041,-.047),(-.092,side*.041,-.049)],[(-.053,side*.042,-.048),(-.102,side*.090,-.101),(-.158,side*.080,-.109),(-.147,side*.045,-.070),(-.103,side*.041,-.05)],'pelvic_'+s,F,R,14,True)

def animate(rig):
    rig.animation_data_create();fps=30
    # Local bones run +/-X: their local Z is the Blender world-up axis for lateral swimming.
    clips={'swim':(60,.12),'struggle':(36,.39),'breach':(42,.27),'landed':(90,.025)}
    for name,(duration,amp) in clips.items():
        action=bpy.data.actions.new(name);rig.animation_data.action=action
        for f in range(1,duration+2):
            t=(f-1)/duration;wave=TAU*t
            for b in rig.pose.bones:b.rotation_mode='XYZ';b.rotation_euler=(0,0,0);b.location=(0,0,0)
            # Several delayed joints generate a traveling bend, rather than rigid fish rotation.
            for i,bn in enumerate(('head','spine_front','spine_mid','spine_rear','tail','caudal')):
                strength=[-.17,.24,.65,1.0,1.1,.65][i]
                rig.pose.bones[bn].rotation_euler.z=amp*strength*math.sin(wave-i*.63)
                if name=='struggle':rig.pose.bones[bn].rotation_euler.x=amp*.15*math.sin(wave*2-i*.42)
                if name=='breach':rig.pose.bones[bn].rotation_euler.x=amp*.32*math.sin(wave-i*.32)
            for side in ('L','R'):
                sg=1 if side=='L' else -1
                rig.pose.bones['pectoral_'+side].rotation_euler.y=sg*(.09 if name=='landed' else .20)*math.sin(wave+(0 if side=='L' else .55))
                rig.pose.bones['pectoral_'+side].rotation_euler.z=.06*math.cos(wave)
                rig.pose.bones['pelvic_'+side].rotation_euler.y=sg*.10*math.sin(wave-.6)
                rig.pose.bones['gill_'+side].rotation_euler.y=sg*(.045 if name=='landed' else .021)*(.5+.5*math.sin(wave*2))
            rig.pose.bones['dorsal'].rotation_euler.y=.055*math.sin(wave-1.2)
            rig.pose.bones['anal'].rotation_euler.y=-.07*math.sin(wave-1.5)
            rig.pose.bones['jaw'].rotation_euler.x=-(.085 if name in ('struggle','landed') else .028)*(.5+.5*math.sin(wave*2+.4))
            # Root carries no forward or world-arc movement: gameplay supplies trajectory.
            for b in rig.pose.bones:
                b.keyframe_insert(data_path='rotation_euler',frame=f,group=b.name)
        for fc in action.fcurves:
            for k in fc.keyframe_points:k.interpolation='LINEAR'
        track=rig.animation_data.nla_tracks.new();track.name=name;strip=track.strips.new(name,1,action);strip.action_frame_start=1;strip.action_frame_end=duration+1
        track.mute=True
        action['loop']=True;action['duration_seconds']=duration/fps
    rig.animation_data.action=None
    rig['clips']='swim, struggle, breach, landed';rig['forward_axis']='+X';rig['rest_total_length_m']=1.0
    for b in rig.pose.bones:b.rotation_euler=(0,0,0)


def setup_scene():
    s=bpy.context.scene;s.render.engine='CYCLES';s.cycles.samples=32;s.cycles.use_denoising=False
    s.render.resolution_x=1200;s.render.resolution_y=800;s.render.resolution_percentage=100
    s.world=bpy.data.worlds.new("ReviewWorld")
    s.world.color=(.16,.16,.16)
    s.view_settings.view_transform='AgX'
    # Product-photo neutral lighting preserves species identity, with no underwater color cast.
    world=s.world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.10,.13,.14,1);world.node_tree.nodes['Background'].inputs[1].default_value=.40
    def area(name,loc,power,color,size):
        bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.name=name;o.data.energy=power;o.data.color=color;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(Vector((0,0,0))-o.location).to_track_quat('-Z','Y').to_euler()
    area('Key_Softbox',(.35,-.8,1.3),80,(1,.91,.76),1.3)
    area('Fill_Softbox',(-.5,.65,.5),65,(.64,.81,1),1.1)
    area('Rim_Softbox',(.1,.8,1.1),95,(1,.91,.72),.7)
    # Backdrop is review-only and excluded from GLB.
    bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.31 if SPEC=='common_carp' else -.16));o=bpy.context.object;o.name='REVIEW_Backdrop';o.data.materials.append(mat('Backdrop',(.022,.037,.046),.9))
    bpy.ops.object.camera_add(location=(.55,-1.7,.47));cam=bpy.context.object;cam.name='REVIEW_Camera';cam.data.type='ORTHO';cam.data.ortho_scale=1.32;s.camera=cam
    return cam

def point_cam(cam,position,target=(0,0,.025),ortho=1.25):
    cam.location=position;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=ortho

def render_views(rig,cam,spec):
    s=bpy.context.scene
    # No action = rest pose; inspect perspective and orthogonal silhouettes.
    for name,position in [('hero',(.62,-1.8,.45)),('side',(0,-2,.08)),('top',(0,0,2)),('front',(2,-.04,.06)),('rear',(-2,-.20,.12))]:
        point_cam(cam,position)
        if name=='top':cam.rotation_euler=(0,0,0)
        s.render.filepath=str(REV/(spec+'_'+name+'.png'));bpy.ops.render.render(write_still=True)
    for clip,frames in [('swim',[1,16,31,46]),('struggle',[1,10,19,28]),('breach',[1,11,22,32]),('landed',[1,24,46,69])]:
        rig.animation_data.action=bpy.data.actions[clip]
        for f in frames:
            s.frame_set(f);point_cam(cam,(.40,-1.8,.63));s.cycles.samples=20;s.render.resolution_x=800;s.render.resolution_y=534;s.render.filepath=str(REV/(spec+'_'+clip+'_%03d.png'%f));bpy.ops.render.render(write_still=True)
    rig.animation_data.action=None
    for b in rig.pose.bones:b.rotation_euler=(0,0,0)
    s.frame_set(1);s.render.resolution_x=1200;s.render.resolution_y=800

def build(spec,render=True):
    global SPEC,PROFILES,MESHES,WEIGHTS
    SPEC=spec;MESHES=[];WEIGHTS={}
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version=0
    s=bpy.context.scene;s.render.fps=30;s.frame_start=1;s.frame_end=91
    # tuples: x, half-width, top height, bottom depth, center height.
    if spec=='common_carp':
        PROFILES=[(-.350,.012,.025,.023,0),(-.310,.022,.045,.041,0),(-.235,.035,.077,.080,.001),(-.13,.064,.124,.123,.005),(.0,.082,.165,.142,.008),(.14,.090,.165,.126,.005),(.245,.079,.135,.105,.002),(.32,.066,.093,.080,-.002),(.385,.048,.061,.059,-.01),(.435,.031,.036,.034,-.012),(.470,.018,.021,.019,-.012)]
    else:
        PROFILES=[(-.395,.010,.016,.015,.006),(-.35,.023,.028,.025,.003),(-.28,.037,.047,.045,.003),(-.16,.050,.064,.057,.003),(.00,.059,.073,.060,.003),(.135,.057,.066,.050,.002),(.215,.051,.054,.034,0),(.265,.046,.037,.019,.002),(.31,.043,.023,.014,.002),(.39,.040,.017,.008,.003),(.465,.033,.013,.007,.003),(.494,.019,.009,.007,.003)]
    skin=texture_material(spec);fm=texture_material(spec,True)
    m={'skin':skin,'fin':fm,'ray':mat('FinRays',(.35,.24,.12) if spec=='common_carp' else (.36,.35,.235),.54),'edge':mat('GillAndEyeRim',(.35,.27,.11) if spec=='common_carp' else (.36,.375,.26),.42),'socket':mat('MouthGillOcclusion',(.035,.040,.026),.59),'iris':mat('AntiqueGoldIris',(.67,.42,.105),.26,.13),'pupil':mat('ObsidianPupil',(.004,.007,.006),.12),'glint':mat('EyeReflection',(.72,.81,.74),.1),'lip':mat('CarpLips',(.52,.31,.145),.46),'tooth':mat('IvoryDentition',(.71,.72,.50),.43)}
    body(skin);fins(spec,m);eyes(spec,m);gills(spec,m);mouth(spec,m)
    # Consolidate parts sharing material+weight type to keep draw calls practical.
    # Geometry retains local topology; weighting is computed after all authoring.
    for o in MESHES:
        bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free()
    rig=make_bones(spec);bind(rig)
    # Scale all data and bones so actual nose-to-tail bounding length is exactly 1.0m.
    minx=min(v.co.x for o in MESHES for v in o.data.vertices);maxx=max(v.co.x for o in MESHES for v in o.data.vertices)
    scale=1/(maxx-minx);offset=(maxx+minx)/2
    for o in MESHES:
        for v in o.data.vertices:v.co.x=(v.co.x-offset)*scale;v.co.y*=scale;v.co.z*=scale
    bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
    for b in rig.data.edit_bones:
        for attr in ('head','tail'):
            p=getattr(b,attr);setattr(b,attr,((p.x-offset)*scale,p.y*scale,p.z*scale))
    bpy.ops.object.mode_set(mode='OBJECT')
    # Merge skinned parts per material (same rig) for ten bounded surfaces, avoiding ray drawcall explosion.
    merged=[]
    by_material={}
    for o in MESHES:by_material.setdefault(o.data.materials[0],[]).append(o)
    for material,group in by_material.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in group:o.select_set(True)
        bpy.context.view_layer.objects.active=group[0];bpy.ops.object.join();o=bpy.context.object;o.name=material.name+'_Geometry';merged.append(o)
    MESHES=merged
    animate(rig)
    for o in MESHES:
        o.data.calc_loop_triangles()
    stats={'species':spec,'native_blender_axes':{'forward':'+X','up':'+Z'},'glb_godot_axes':{'forward':'+X','up':'+Y'},'length_m':1.0,'vertices':sum(len(o.data.vertices) for o in MESHES),'triangles':sum(len(o.data.loop_triangles) for o in MESHES),'meshes':len(MESHES),'materials':len(set(o.data.materials[0].name for o in MESHES)),'bones':[b.name for b in rig.data.bones],'clips':{a.name:float((a.frame_range.y-a.frame_range.x)/30) for a in bpy.data.actions},'texture_images':[{'name':im.name,'dimensions':list(im.size)} for im in bpy.data.images]}
    # Export only model and rig, never lights/camera/backdrop.
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
    for o in MESHES:o.select_set(True)
    bpy.context.view_layer.objects.active=rig
    filepath=ROOT/'game/assets/3d'/f'{spec}.glb'
    bpy.ops.export_scene.gltf(filepath=str(filepath),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_frame_range=False,export_anim_slide_to_zero=True,export_nla_strips=True,export_skins=True,export_all_influences=False,export_def_bones=True,export_extras=True,export_materials='EXPORT',export_cameras=False,export_lights=False)
    stats['glb_bytes']=filepath.stat().st_size
    (REV/(spec+'_stats.json')).write_text(json.dumps(stats,indent=2))
    cam=setup_scene();point_cam(cam,(.62,-1.8,.45));bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art_masters/3d'/f'{spec}.blend'))
    print('FISH_READY '+json.dumps(stats),flush=True)
    if render:render_views(rig,cam,spec)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--species',default='all');p.add_argument('--no-render',action='store_true');p.add_argument('--review-existing',action='store_true');args=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    for spec in (['common_carp','alligator_gar'] if args.species=='all' else [args.species]):
        if args.review_existing:
            SPEC=spec;bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art_masters/3d'/f'{spec}.blend'));render_views(bpy.data.objects['FishRig'],bpy.data.objects['REVIEW_Camera'],spec)
        else:build(spec,not args.no_render)
