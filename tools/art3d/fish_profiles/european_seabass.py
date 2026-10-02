"""Original Dicentrarchus labrax with two visibly separate dorsal fins."""
import math
import numpy as np
from mathutils import Vector
from fish_profiles.japanese_whiting import paired,median,caudal,eyes,gills

def pigment(u,v,upper,color,height,rough):
    opercle=np.exp(-((u-.743)/.023)**2-((upper-.73)/.11)**2)
    color*=1-.66*opercle[:,:,None]
    return color,height,rough
PROFILE={'id':'european_seabass','sections':[(-.356,.019,.034,.030,0),(-.275,.031,.053,.043,0),(-.157,.048,.084,.068,.002),(-.02,.063,.107,.087,.002),(.12,.067,.118,.094,.002),(.245,.062,.112,.080,.004),(.329,.050,.083,.056,.003),(.408,.036,.040,.028,0),(.476,.021,.017,.015,-.007)],'skin':{'back':(.26,.34,.39),'side':(.71,.75,.76),'belly':(.85,.86,.78),'pattern':'fine_scales','scale_columns':70,'scale_rows':33,'variation':.025,'lateral_line':(.45,.50,.52),'lateral_curve':.15,'lateral_arch':.11},'custom_skin':pigment,'fin_color':(.47,.51,.51),'roughness':.37,'head_start':.72,'head_end':.84,'normal_strength':.16,'morphology':['Adult silver-grey body with blue-grey back and no juvenile flank spots','Two separate dorsal fins: compact first with nine hard spines, distinct second soft fin','Moderately forked tail and broad terminal mouth; lower jaw only slightly projecting','Diffuse opercular spot and two flat opercular spines per side'],'sources':['https://www.fao.org/fishery/docs/CDrom/aquaculture/I1129m/file/en/en_europeanseabass.htm','https://www.marlin.ac.uk/species/detail/2127']}
def anatomy(f):
    xs=np.linspace(.223,.005,9);edge=[]
    for i,x in enumerate(xs):
        p=f.surface(float(x),0,-.001);h=.025+.091*math.sin(math.pi*(i+1)/10);edge.append((x,0,p.z+h))
        if i<8:edge.append(((x+xs[i+1])/2,0,p.z+h-.032))
    median(f,'DorsalFirst',.223,.003,edge,'spine_front',31)
    median(f,'DorsalSecond',-.045,-.265,[(-.045,0,.101),(-.085,0,.182),(-.149,0,.169),(-.236,0,.117),(-.266,0,.052)],'spine_mid',23)
    median(f,'Anal',-.119,-.271,[(-.119,0,-.077),(-.153,0,-.146),(-.215,0,-.139),(-.271,0,-.040)],'spine_rear',21,upper=False)
    caudal(f,[(-.394,.065),(-.501,.132),(-.479,.067),(-.427,0),(-.482,-.069),(-.503,-.128),(-.394,-.058)],28)
    paired(f,'Pectoral',.269,.222,1.93,.056,.112,-.030,rays=19)
    paired(f,'Pelvic',.169,.127,2.50,.043,.078,-.050,rays=15)
    eyes(f,.376,1.15,.0148,(.63,.59,.34));gills(f,.288,.030,.0010)
    f.ellipsoid('MouthInterior',(.478,0,-.008),(.0025,.020,.014),f.mats['dark'],'head')
    f.ellipsoid('LowerJaw',(.441,0,-.024),(.050,.026,.013),f.mats['skin'],'jaw')
    for sign,tag in ((-1,'R'),(1,'L')):
        f.tube('TerminalMouth'+tag,[(.480,sign*.016,-.004),(.440,sign*.030,-.014),(.370,sign*.047,-.027)],[.0020,.0024,.0011],f.mats['dark'],'head',8)
        f.tube('LowerLip'+tag,[(.489,0,-.012),(.478,sign*.018,-.023),(.429,sign*.029,-.036),(.376,sign*.039,-.034)],[.0021,.0024,.0020,.0013],f.mats['lip'],'jaw',8)
        for theta in (1.02,1.42):
            p=f.surface(.279,sign*theta,.001);f.tube('OpercularSpine'+tag+str(theta),[p,p+Vector((-.020,sign*.004,.002))],[.0022,.00015],f.mats['edge'],'head',7)
