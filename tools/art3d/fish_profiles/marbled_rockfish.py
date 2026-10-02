"""Original Sebastiscus marmoratus: robust rockfish, twelve dorsal spines, mottled skin."""
import math
import numpy as np
from mathutils import Vector
from fish_profiles.japanese_whiting import paired,median,caudal,eyes,gills

def pigment(u,v,upper,color,height,rough):
    # Irregular warm-brown saddles and pale speckles restricted to lower flanks.
    n=np.sin(u*49+np.sin(v*29)*1.1)*np.cos(v*36-u*15)+.35*np.sin(u*115+v*79)
    dark=np.clip((n+.10)*1.10,0,1)*np.clip((upper-.19)*1.7,0,1)
    color=color*(1-dark[:,:,None]*.69)
    cream=(np.maximum(0,np.sin(u*349+v*197)*np.cos(u*127-v*337)-.72)/.28)*np.clip((.68-upper)*4,0,1)
    color=color*(1-cream[:,:,None]*.60)+np.array([.76,.68,.48])*cream[:,:,None]*.60
    return color,height+n*.008,rough
PROFILE={'id':'marbled_rockfish','sections':[(-.346,.022,.040,.034,0),(-.275,.035,.070,.054,.002),(-.16,.060,.110,.080,.003),(-.035,.078,.145,.105,.006),(.09,.087,.161,.124,.002),(.222,.084,.149,.113,.005),(.321,.073,.123,.091,.004),(.403,.051,.077,.046,.001),(.468,.028,.027,.028,-.014)],'skin':{'back':(.43,.25,.15),'side':(.66,.42,.25),'belly':(.70,.60,.43),'pattern':'fine_scales','scale_columns':79,'scale_rows':36,'variation':.06},'custom_skin':pigment,'fin_color':(.53,.32,.19),'fin_pattern':'spots','roughness':.51,'normal_strength':.23,'head_start':.65,'head_end':.79,'morphology':['Moderately deep stout body with broad bony head and large oblique mouth','Continuous notched dorsal with twelve anterior spines and rounded soft rear','Broad fan-shaped pectorals, rounded caudal, short three-spined anal','Irregular reddish-brown saddles; pale spotting below lateral line only','No suborbital ridge or suborbital spine and no skin flap in pectoral axil'],'sources':['https://fishesofaustralia.net.au/home/species/3136','https://www.frontiersin.org/journals/marine-science/articles/10.3389/fmars.2022.912129/full']}
def anatomy(f):
    xs=np.linspace(.254,-.129,12);edge=[]
    for i,x in enumerate(xs):
        p=f.surface(float(x),0,-.001);h=.033+.092*math.sin(math.pi*(i+.7)/13)
        edge.append((x,0,p.z+h))
        if i<11:edge.append(((x+xs[i+1])/2,0,p.z+h-.046))
    median(f,'Dorsal_spiny',.254,-.133,edge,'spine_front',43)
    median(f,'Dorsal_soft',-.138,-.284,[(-.138,0,.119),(-.158,0,.190),(-.232,0,.178),(-.276,0,.131),(-.285,0,.065)],'spine_rear',22)
    median(f,'Anal',-.116,-.274,[(-.116,0,-.085),(-.146,0,-.149),(-.205,0,-.167),(-.256,0,-.123),(-.274,0,-.053)],'spine_rear',17,upper=False)
    caudal(f,[(-.374,.060),(-.451,.101),(-.500,.085),(-.520,.040),(-.524,0),(-.520,-.036),(-.500,-.081),(-.449,-.096),(-.374,-.056)],29)
    paired(f,'BroadPectoral',.269,.189,1.91,.103,.171,-.086,rays=25)
    paired(f,'Pelvic',.187,.127,2.59,.054,.088,-.061,rays=15)
    eyes(f,.345,1.05,.0205,(.67,.41,.12));gills(f,.253,.047,.0016)
    dark=f.mats['dark'];lip=f.material('RockfishFleshyLip',(.45,.28,.20),.50)
    f.ellipsoid('MouthInterior',(.470,0,-.012),(.003,.026,.023),dark,'head')
    f.ellipsoid('LowerJaw',(.425,0,-.041),(.063,.032,.018),f.mats['skin'],'jaw')
    for sign,tag in ((-1,'R'),(1,'L')):
        pts=[(.475,sign*.025,-.003),(.433,sign*.042,-.006),(.385,sign*.058,-.022),(.332,sign*.067,-.040)]
        f.tube('MaxillaryCrease'+tag,pts,.0020,dark,'head',8)
        f.tube('UpperLip'+tag,[(.473,0,.006),(.473,sign*.021,.004),(.421,sign*.046,-.004),(.365,sign*.062,-.029)],[.0030,.0034,.003,.0018],lip,'head',8)
        f.tube('LowerLip'+tag,[(.489,0,-.031),(.472,sign*.026,-.035),(.422,sign*.038,-.048),(.366,sign*.050,-.047)],[.0030,.0034,.0028,.0020],lip,'jaw',8)
        # Low supraorbital crest, intentionally no false suborbital horn.
        f.tube('SupraorbitalRim'+tag,[f.surface(x,sign*.62,.001) for x in (.387,.370,.345,.317)],[.003,.004,.004,.002],f.mats['edge'],'head',8)
