"""Original Sillago japonica geometry. Sources guide anatomy; no source imagery is embedded."""
import math
import numpy as np
from mathutils import Vector

def paired(f,name,front,rear,theta,reach,sweep,drop,parent='spine_front',rays=18,material=None):
    for sign,tag in ((-1,'R'),(1,'L')):
        roots=[f.surface(float(x),sign*theta,-.0012) for x in np.linspace(front,rear,17)]
        m=roots[len(roots)//2]
        edge=[roots[0],m+Vector((-sweep*.45,sign*reach*.78,drop*.4)),m+Vector((-sweep,sign*reach,drop)),roots[-1]+Vector((-sweep*.60,sign*reach*.26,drop*.70)),roots[-1]]
        f.fin(name+'_'+tag,roots,edge,parent=parent,rays=rays,material=material)

def median(f,name,front,rear,edge,parent='spine_mid',rays=23,material=None,upper=True):
    roots=[f.surface(float(x),0 if upper else math.pi,-.0012) for x in np.linspace(front,rear,31)]
    return f.fin(name,roots,edge,parent=parent,rays=rays,material=material)

def caudal(f,outline,rays=27):
    x,w,h,d,z=f.sections[0]
    f.fin('Caudal',[(x+.0003,0,z+h*.91),(x+.0003,0,z),(x+.0003,0,z-d*.91)],[(xx,0,zz) for xx,zz in outline],bone='caudal',parent='tail',rays=rays)

def eyes(f,x,theta,radius,iris):
    for sign,tag in ((-1,'R'),(1,'L')):
        p=f.surface(x,sign*theta,.0003);f.eye('Eye_'+tag,p,(0,sign*math.sin(theta),math.cos(theta)),radius,iris)

def gills(f,x,reach=.027,width=.001):
    for sign,tag in ((-1,'R'),(1,'L')):
        pts=[f.surface(x-reach*math.sin(t*math.pi),sign*(.40+2.16*t),.0003) for t in np.linspace(0,1,37)]
        f.gill(tag,pts,width)

def mouth(f,x,width,z,depth=.004,radius=.0014):
    up=[];low=[]
    for t in np.linspace(0,math.pi,27):
        y=width*math.cos(t);xx=x+.0017*math.sin(t)
        up.append((xx,y,z+depth*math.sin(t)));low.append((xx,y,z-depth*math.sin(t)))
    f.tube('MouthOpening',[(x,-width,z),(x+.001,0,z),(x,width,z)],radius*.75,f.mats['dark'],'head',7)
    f.tube('UpperLip',up,radius,f.mats['lip'],'head',8);f.tube('LowerLip',low,radius,f.mats['lip'],'jaw',8)

PROFILE={'id':'japanese_whiting','sections':[(-.365,.010,.018,.016,0),(-.29,.017,.030,.025,0),(-.17,.026,.043,.033,.001),(-.03,.035,.060,.045,.002),(.11,.039,.067,.051,.001),(.24,.033,.063,.040,.002),(.325,.024,.051,.027,.001),(.395,.014,.034,.016,0),(.474,.009,.015,.010,-.005),(.487,.006,.008,.007,-.008)],'skin':{'back':(.60,.52,.38),'side':(.79,.77,.64),'belly':(.91,.90,.80),'pattern':'fine_scales','scale_columns':73,'scale_rows':30,'variation':.025,'lateral_line':(.69,.66,.54),'lateral_curve':.11},'fin_color':(.75,.73,.61),'roughness':.43,'normal_strength':.16,'head_start':.73,'head_end':.85,'morphology':['Slender subcylindrical sand-whiting body with pointed elongated snout and small terminal mouth','Separate first XI-spined dorsal and long low second dorsal with 21-23 soft rays','Long low anal opposite second dorsal; shallow-emarginate rather than deeply forked tail','Pale sandy dorsum and silvery cream sides, pale fins'],'sources':['https://fishdb.sinica.edu.tw/taxon/382628-fishdb']}

def anatomy(f):
    median(f,'Dorsal_first',.238,.052,[(.237,0,.064),(.211,0,.144),(.166,0,.132),(.10,0,.102),(.052,0,.061)],'spine_front',22)
    median(f,'Dorsal_second',.022,-.291,[(.022,0,.059),(-.014,0,.103),(-.129,0,.080),(-.249,0,.050),(-.291,0,.030)],'spine_mid',25)
    median(f,'Anal',.010,-.287,[(.010,0,-.041),(-.018,0,-.089),(-.127,0,-.068),(-.245,0,-.043),(-.287,0,-.025)],'spine_mid',25,upper=False)
    caudal(f,[(-.395,.036),(-.483,.073),(-.500,.064),(-.468,.017),(-.463,0),(-.472,-.024),(-.500,-.065),(-.481,-.074),(-.395,-.035)],26)
    paired(f,'Pectoral',.27,.235,1.89,.043,.092,-.025,rays=18)
    paired(f,'Pelvic',.203,.175,2.58,.028,.061,-.026,rays=12)
    eyes(f,.371,1.15,.0105,(.64,.53,.28));gills(f,.282,.020,.0008);mouth(f,.488,.0067,-.008,.0027,.0012)
    f.ellipsoid('SmallTerminalOralCavity',(.489,0,-.008),(.001,.0054,.0023),f.mats['dark'],'head')
    for sign,tag in ((-1,'R'),(1,'L')):
        f.tube('SmallObliqueMouthCrease'+tag,[(.490,sign*.004,-.008),(.484,sign*.0067,-.011),(.472,sign*.009,-.014)],[.0010,.0011,.0006],f.mats['dark'],'head',7)
    # Short opercular point, no chin barbels.
    for sign in (-1,1):
        p=f.surface(.266,sign*1.06,.0005);f.tube('OpercularPoint'+str(sign),[p,p+Vector((-.018,sign*.003,.003))],[.002,.0002],f.mats['edge'],'head',7)

# Mechanical fin loft helper reused by independently authored species, not a body template.
def crest(f,name,front,rear,heights,parent='spine_front',notch=.018,material=None):
    xs=np.linspace(front,rear,len(heights));edge=[]
    for i,(x,h) in enumerate(zip(xs,heights)):
        p=f.surface(float(x),0,-.0012);edge.append((x,0,p.z+h))
        if i<len(xs)-1:edge.append(((x+xs[i+1])/2,0,p.z+max(.004,h-notch)))
    median(f,name,front,rear,edge,parent,3*len(heights)+2,material)
