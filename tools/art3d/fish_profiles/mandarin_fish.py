"""Siniperca chuatsi, original deep-bodied Chinese freshwater perch; not marine mandarin dragonet."""
import math
import numpy as np
from mathutils import Vector
from fish_profiles.japanese_whiting import paired,median,caudal,eyes,gills

def pigment(u,v,upper,color,height,rough):
    n=np.sin(u*45+np.sin(v*19)*1.8)*np.cos(v*21-u*23)+.28*np.sin(u*133+v*91)
    blot=np.clip((n-.13)*1.90,0,1)*np.clip((upper-.13)*2.1,0,1)
    color=color*(1-blot[:,:,None]*.86)
    head=np.clip((u-.72)*6,0,1);slash=np.exp(-((abs(np.cos(v*math.tau))-.45-.18*np.sin(u*12))/.062)**2)*head
    color*=1-.75*slash[:,:,None]
    return color,height,rough
PROFILE={'id':'mandarin_fish','sections':[(-.344,.021,.033,.030,0),(-.265,.030,.060,.048,0),(-.16,.050,.101,.073,.003),(-.045,.068,.145,.096,.005),(.095,.077,.166,.107,.007),(.221,.073,.150,.098,.010),(.313,.064,.114,.073,.008),(.403,.047,.060,.039,.001),(.471,.024,.015,.017,-.013)],'skin':{'back':(.37,.34,.15),'side':(.72,.63,.28),'belly':(.81,.74,.50),'pattern':'fine_scales','scale_columns':88,'scale_rows':37,'variation':.04},'custom_skin':pigment,'fin_color':(.58,.51,.25),'fin_pattern':'spots','head_start':.71,'head_end':.83,'roughness':.44,'normal_strength':.20,'morphology':['Compressed high-backed body, broad oblique predatory mouth with protruding lower jaw','Brown-yellow fine-scaled sides with irregular dark blotches and eye-to-mouth markings','Hard-spined anterior dorsal and tall rounded soft posterior dorsal joined at a notch','Rounded caudal and pectorals; gill cover with two flat rear spines per side'],'sources':['https://www.fao.org/fishery/docs/CDrom/aquaculture/I1129m/file/en/en_mandarinfish.htm']}
def anatomy(f):
    xs=np.linspace(.239,-.102,12);edge=[]
    for i,x in enumerate(xs):
        p=f.surface(float(x),0,-.001);h=.022+.095*math.sin(math.pi*(i+1)/14);edge.append((x,0,p.z+h))
        if i<11:edge.append(((x+xs[i+1])/2,0,p.z+h-.038))
    median(f,'DorsalSpiny',.239,-.106,edge,'spine_front',41)
    median(f,'DorsalSoft',-.109,-.282,[(-.109,0,.139),(-.146,0,.233),(-.211,0,.224),(-.267,0,.135),(-.282,0,.052)],'spine_rear',24)
    median(f,'Anal',-.146,-.273,[(-.146,0,-.075),(-.173,0,-.139),(-.227,0,-.151),(-.265,0,-.106),(-.273,0,-.043)],'spine_rear',19,upper=False)
    caudal(f,[(-.375,.062),(-.462,.097),(-.513,.062),(-.524,.0),(-.507,-.067),(-.459,-.095),(-.376,-.059)],28)
    paired(f,'Pectoral',.258,.196,1.98,.066,.103,-.053,rays=21)
    paired(f,'Pelvic',.189,.134,2.58,.045,.080,-.060,rays=16)
    eyes(f,.355,1.08,.0165,(.72,.47,.10));gills(f,.273,.038,.0013)
    f.ellipsoid('MouthRecess',(.473,0,-.017),(.003,.024,.019),f.mats['dark'],'head')
    f.ellipsoid('ProtrudingLowerJaw',(.438,0,-.034),(.061,.030,.017),f.mats['skin'],'jaw')
    for sign,tag in ((-1,'R'),(1,'L')):
        f.tube('Maxilla'+tag,[(.473,sign*.022,-.010),(.432,sign*.041,-.008),(.372,sign*.059,-.025),(.320,sign*.063,-.032)],[.0028,.0030,.0025,.0015],f.mats['dark'],'head',8)
        f.tube('LowerLip'+tag,[(.496,0,-.024),(.481,sign*.023,-.027),(.430,sign*.035,-.045),(.362,sign*.050,-.045)],[.0024,.0030,.0027,.0016],f.mats['lip'],'jaw',8)
        for t in (1.02,1.55):
            p=f.surface(.248,sign*t,.001);f.tube('OpercularSpine'+tag+str(t),[p,p+Vector((-.030,sign*.008,.004))],[.0032,.0002],f.mats['edge'],'head',7)
