"""Esox lucius: flattened duckbill, posterior paired median fins, pale flank ovals."""
import math,numpy as np
from mathutils import Vector
from fish_profiles._freshwater import paired_fin,median_fin,caudal,eye_pair,gill_pair,jaw_loft

def paint(u,v,upper,color,height,rough):
    # Pale irregular lateral ovals, distinctly different from dark-spotted gar.
    rng=np.random.default_rng(51017);mask=np.zeros_like(u)
    for row,center in enumerate((.18,.25,.32,.68,.75,.82)):
        for i in range(31):
            x=.04+i*.023+rng.uniform(-.006,.006);y=center+rng.uniform(-.013,.013);rx=rng.uniform(.006,.012);ry=rng.uniform(.009,.016)
            patch=np.exp(-2*(((u-x)/rx)**2+((v-y)/ry)**2));mask=np.maximum(mask,patch)
    mask*=np.clip((.78-u)/.06,0,1);light=np.array([.77,.72,.41]);color=color*(1-mask[:,:,None]*.88)+light*mask[:,:,None]*.88
    return color,height,rough
PROFILE={'id':'northern_pike','sections':[(-.37,.011,.023,.020,0),(-.30,.020,.041,.035,0),(-.20,.031,.055,.044,.001),(-.065,.041,.066,.050,.002),(.08,.044,.068,.051,.002),(.19,.043,.058,.044,.001),(.28,.040,.036,.027,0),(.34,.034,.020,.015,-.003),(.42,.031,.012,.008,-.005),(.48,.023,.008,.006,-.005)],'skin':{'back':(.14,.20,.095),'side':(.33,.39,.17),'belly':(.76,.74,.51),'pattern':'fine_scales','scale_columns':84,'scale_rows':32,'variation':.075},'custom_skin':paint,'fin_color':(.46,.37,.19),'fin_pattern':'spots','roughness':.48,'head_start':.75,'head_end':.84,'swim_amplitude':.88,'morphology':['Elongate torpedo body with broad flat duckbill snout','Large long mouth and slightly projecting lower jaw','Dorsal and anal fins both far back near forked tail','Pale irregular lateral ovals on olive body, fine scales','No barbels and no adipose fin'],'sources':['https://home.nps.gov/miss/learn/nature/northern-pike.htm','https://www.fishbase.se/summary/258']}
def anatomy(f):
    median_fin(f,'Dorsal',-.19,-.31,[(-.19,0,.056),(-.235,0,.129),(-.283,0,.129),(-.335,0,.040)],'spine_rear',23)
    median_fin(f,'Anal',-.22,-.32,[(-.218,0,-.041),(-.258,0,-.117),(-.315,0,-.109),(-.34,0,-.036)],'spine_rear',23,upper=False)
    caudal(f,-.367,.023,[(-.446,.078),(-.515,.133),(-.496,.068),(-.437,.004),(-.493,-.071),(-.512,-.118),(-.435,-.072)],29)
    paired_fin(f,'Pectoral',.222,.169,2.08,.061,.076,-.061,'spine_front',18)
    paired_fin(f,'Pelvic',-.025,-.066,2.36,.048,.064,-.065,'spine_mid',16)
    eye_pair(f,.315,1.08,.0085,(.59,.52,.22));gill_pair(f,.254,.0009,.022)
    jaw_loft(f,'DuckbillLowerJaw',[(.276,0,.032,.011,-.018),(.35,0,.031,.009,-.018),(.433,0,.029,.007,-.015),(.486,0,.019,.004,-.012)])
    for sign in (-1,1):
        pts=[(.288,sign*.035,-.002),(.34,sign*.035,-.006),(.415,sign*.033,-.007),(.482,sign*.021,-.008)]
        f.tube('LongMouthSeam'+str(sign),pts,.0011,f.mats['dark'],'head',7)
        f.ellipsoid('RostralNaris'+str(sign),(.413,sign*.023,.006),(.0033,.0012,.001),f.mats['dark'])
