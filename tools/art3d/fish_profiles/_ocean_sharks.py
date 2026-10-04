"""Small shared construction tools for eight independently proportioned shark profiles.
Authored anatomy only; no downloaded geometry, textures, or shared-pipeline edits.
"""
import math
import numpy as np


def shark_skin(back, side, belly, tiger=False):
    """Fine placoid grain and restrained countershading, never bony-fish scale tiles."""
    def paint(u, v, upper, color, height, rough):
        # Boundary is lower than midline, and slightly uneven like natural pigmentation.
        boundary = .34 + .018*np.sin(u*24) + .007*np.sin(u*81)
        blend = np.clip((upper-boundary)/.10, 0, 1)
        shade = np.clip((upper-.52)/.48, 0, 1)
        dorsal = np.array(side)[None,None,:]*(1-shade[:,:,None])+np.array(back)[None,None,:]*shade[:,:,None]
        color = np.array(belly)[None,None,:]*(1-blend[:,:,None])+dorsal*blend[:,:,None]
        grain = np.sin(u*1903+np.sin(v*779))*np.cos(v*1733-u*431)
        color *= 1+.014*grain[:,:,None]
        height = .006*grain
        if tiger:
            # Irregular vertical bars fade into the lower flank; adult-like rather than orange tiger fur.
            phase = u*math.tau*17 + .68*np.sin(v*math.tau*2.5) + .25*np.sin(u*39)
            bars = np.maximum(0,np.cos(phase))**5
            gate = np.clip((upper-.39)/.28,0,1)*np.clip((.83-u)/.08,0,1)*np.clip((u-.10)/.10,0,1)
            color *= 1-.57*(bars*gate)[:,:,None]
        return color,height,rough
    return paint


def _fin(f,name,roots,edge,parent='spine_mid',bone=None,white=False,white_span=(.26,.62)):
    # Color the actual membrane/ray faces, rather than floating overlays that can
    # intersect the independently tessellated curved fin on the opposite side.
    import build_fish as core
    before=len(core.MESHES);mat=f.mats['fin']
    ob=f.fin(name,roots,edge,parent=parent,bone=bone,rays=14,material=mat,ray_material=mat)
    if white:
        ivory=f.material('NaturalWhiteFinTips',(.84,.85,.78),.51)
        for item_index,item in enumerate(core.MESHES[before:]):
            item.data.materials.append(ivory);slot=len(item.data.materials)-1
            uvs=item.data.uv_layers.active.data
            for poly in item.data.polygons:
                v=sum(float(uvs[li].uv.y) for li in poly.loop_indices)/len(poly.loop_indices)
                u=(sum(float(uvs[li].uv.x) for li in poly.loop_indices)/len(poly.loop_indices)
                   if item_index==0 else (item_index-1)/13)
                boundary=.74+.05*math.sin(u*40*.83)
                if white_span[0]<=u<=white_span[1] and v>=boundary:
                    poly.material_index=slot
    return ob


def _median(f,name,a,b,edge,ventral=False,parent='spine_mid',white=False,span=(.26,.62)):
    theta=math.pi if ventral else 0
    roots=[f.surface(float(x),theta,-.0005) for x in np.linspace(a,b,22)]
    edge=[tuple(roots[0])]+list(edge)+[tuple(roots[-1])]
    return _fin(f,name,roots,edge,parent,white=white,white_span=span)


def _paired(f,name,a,b,theta_a,theta_b,points,parent='spine_front',white=False):
    for sign in (-1,1):
        tag='L' if sign<0 else 'R'
        roots=[f.surface(float(x),sign*float(th),-.0005) for x,th in zip(np.linspace(a,b,18),np.linspace(theta_a,theta_b,18))]
        edge=[tuple(roots[0])]+[(x,sign*y,z) for x,y,z in points]+[tuple(roots[-1])]
        _fin(f,name+tag,roots,edge,parent,white=white,white_span=(.25,.66))


def _caudal(f,edge,white=False,white_span=(.62,.87)):
    # Curved root wraps the closed body's tail end instead of floating behind it.
    x=f.sections[0][0]+.0007
    roots=[f.surface(x,math.pi,-.0005),f.surface(x,math.pi/2,-.0005),f.surface(x,0,-.0005)]
    roots[1].y=0
    return _fin(f,'HeterocercalCaudal',roots,edge,'tail','caudal',white,white_span)


def _cephalofoil(f,kind):
    """Closed, flattened cephalofoil volume with species-specific leading-edge notches."""
    if kind=='great':
        outline=[(.359,0),(.377,-.080),(.391,-.164),(.410,-.244),(.444,-.254),(.482,-.247),(.490,-.172),(.493,-.087),(.482,0),(.493,.087),(.490,.172),(.482,.247),(.444,.254),(.410,.244),(.391,.164),(.377,.080)]
        thickness=.020;eyex=.454;eyey=.249
    else:
        outline=[(.354,0),(.369,-.076),(.375,-.143),(.384,-.209),(.409,-.233),(.444,-.232),(.469,-.204),(.462,-.159),(.490,-.097),(.500,-.054),(.480,0),(.500,.054),(.490,.097),(.462,.159),(.469,.204),(.444,.232),(.409,.233),(.384,.209),(.375,.143),(.369,.076)]
        thickness=.017;eyex=.428;eyey=.230
    # Primary references constrain head width to 23-27% TL (great) / 24-30% TL (scalloped).
    transverse_scale=.575 if kind=='great' else .65
    outline=[(x,y*transverse_scale) for x,y in outline];eyey*=transverse_scale
    center=(.416,0)
    vertices=[];uv=[];faces=[];N=len(outline);rings=5
    for sign in (1,-1):
        for ring in range(rings):
            t=.03+.97*ring/(rings-1)
            for x,y in outline:
                px=center[0]+(x-center[0])*t;py=y*t
                z=sign*thickness*math.sqrt(max(.07,1-t*t))
                vertices.append((px,py,z));uv.append(((px-f.sections[0][0])/(f.sections[-1][0]-f.sections[0][0]),0 if sign>0 else .5))
    for s in range(2):
        base=s*rings*N
        for r in range(rings-1):
            for i in range(N):
                a=base+r*N+i;b=base+r*N+(i+1)%N
                faces.append((a,b,b+N,a+N) if s==0 else (a+N,b+N,b,a))
        faces.append(tuple(base+i for i in range(N-1,-1,-1)) if s==0 else tuple(base+i for i in range(N)))
    for i in range(N):
        a=(rings-1)*N+i;b=(rings-1)*N+(i+1)%N;c=(2*rings-1)*N+(i+1)%N;d=(2*rings-1)*N+i
        faces.append((a,b,c,d))
    f.mesh('BroadCephalofoil_'+kind,vertices,faces,f.mats['skin'],uv,'head')
    for sign in (-1,1):
        tag='L' if sign<0 else 'R'
        f.eye('DistalHammerEye'+tag,(eyex,sign*eyey,.001),(0,sign,0),.010,iris=(.19,.18,.15))
        # Small nostrils sit on the underside near the lateral head tips.
        f.ellipsoid('CephalofoilNostril'+tag,(eyex+.018,sign*(eyey-.025*transverse_scale),-.009),(.008,.0025,.002),f.mats['dark'],'head')
    # Mouth is on the underside of the central head, not stretched across the hammer.
    pts=[(.436-.047*t*t,.046*t,-.019) for t in np.linspace(-1,1,25)]
    f.tube('VentralHammerMouth',pts,.0018,f.mats['dark'],'head',7)
    f.tube('VentralHammerLip',[(x,y,z-.0013) for x,y,z in pts],.0011,f.mats['lip'],'head',6)


def _face(f,plan):
    if plan.get('hammer'):
        _cephalofoil(f,plan['hammer'])
    else:
        for sign in (-1,1):
            tag='L' if sign<0 else 'R'
            ex,theta,r=plan['eye']
            center=f.surface(ex,sign*theta,.0008)
            if plan.get('eye_shape'):
                import build_fish as core
                before=len(core.MESHES)
            f.eye('SharkEye'+tag,center,(0,sign*.98,.12),r,iris=plan.get('iris',(.12,.14,.13)))
            if plan.get('eye_shape'):
                sx,sz=plan['eye_shape']
                for ob in core.MESHES[before:]:
                    for v in ob.data.vertices:
                        v.co.x=center.x+(v.co.x-center.x)*sx
                        v.co.z=center.z+(v.co.z-center.z)*sz
            nx,nt=plan.get('nostril',(ex+.044,2.25))
            f.ellipsoid('Nostril'+tag,f.surface(nx,sign*nt,.001),(.004,.0023,.0018),f.mats['dark'],'head')
        front,back,angle=plan['mouth']
        pts=[f.surface(front-(front-back)*float(t)**2,math.pi+float(t)*angle,.0007) for t in np.linspace(-1,1,31)]
        f.tube('VentralUShapedMouth',pts,.0019,f.mats['dark'],'head',8)
        f.tube('SubtleLowerLip',[(p.x,p.y,p.z-.001) for p in pts],.0013,f.mats['lip'],'head',7)
        if plan.get('teeth'):
            # Discrete teeth in the anterior mouth, avoiding an exaggerated open grin.
            for k,t in enumerate(np.linspace(-.82,.82,11)):
                x=front-(front-back)*float(t)**2;p=f.surface(x,math.pi+float(t)*angle,.0014)
                broad=plan['teeth']=='triangular';half=.0033 if broad else .0016
                vs=[(p.x-half,p.y-.001,p.z),(p.x+half,p.y+.001,p.z),(p.x-.0005,p.y,p.z-(.006 if broad else .008))]
                f.mesh('VisibleTooth%02d'%k,vs,[(0,1,2)],f.mats['tooth'],weight='head')
    # Exactly five narrow, curved gill slits per side, ahead of pectoral origin.
    base,spacing,low,high=plan['gills']
    for sign in (-1,1):
        tag='L' if sign<0 else 'R'
        for i in range(5):
            gx=base-i*spacing
            pts=[f.surface(gx+.008*((float(th)-1.55)/.9)**2,sign*float(th),.0008) for th in np.linspace(low,high,19)]
            f.gill('GillSlit'+tag+str(i+1),pts,.00115)


def anatomy(f,plan):
    # These calls consume explicitly authored per-species fin plans and torso cross-sections.
    _face(f,plan)
    a,b,edge=plan['dorsal'];_median(f,'FirstDorsal',a,b,edge,parent='spine_front',white=plan.get('white_dorsal',False))
    a,b,edge=plan['second'];_median(f,'SecondDorsal',a,b,edge,parent='spine_rear')
    a,b,edge=plan['anal'];_median(f,'Anal',a,b,edge,True,'spine_rear')
    a,b,ta,tb,edge=plan['pectoral'];_paired(f,'Pectoral',a,b,ta,tb,edge,white=plan.get('white_pectoral',False))
    a,b,ta,tb,edge=plan['pelvic'];_paired(f,'Pelvic',a,b,ta,tb,edge,'spine_rear')
    _caudal(f,plan['tail'],plan.get('white_tail',False),plan.get('white_tail_span',(.61,.88)))
    if plan.get('keel'):
        mat=f.material('CaudalKeelPigment',tuple(np.array(f.profile['skin']['side'])*.86),.49)
        for sign in (-1,1):
            pts=[f.surface(float(x),sign*math.pi/2,.001) for x in np.linspace(-.27,-.382,16)]
            rr=[.001+.004*math.sin(i/15*math.pi) for i in range(16)]
            f.tube('StrongLateralCaudalKeel'+str(sign),pts,rr,mat,'spine',7)
    if plan.get('interdorsal'):
        a,b=plan['interdorsal'];pts=[f.surface(float(x),0,.0004) for x in np.linspace(a,b,19)]
        f.tube('LowInterdorsalRidge',pts,.0016,f.mats['edge'],'spine',6)
