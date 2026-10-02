"""Micropterus nigricans. Original adult largemouth model; maxilla genuinely extends behind eye."""
import math
import numpy as np
from fish_profiles.japanese_whiting import paired,median,caudal,eyes,gills

def pigment(u,v,upper,color,height,rough):
    latitude=np.cos(v*math.tau);stripe=np.exp(-((latitude-.015)/.155)**2)
    broken=np.clip(.67+.33*np.cos(u*89+np.sin(v*27)),0,1)*np.clip((.88-u)*12,0,1)
    color*=1-(stripe*broken*.82)[:,:,None]
    freckles=np.maximum(0,np.sin(u*231+v*93)*np.cos(u*87-v*173)-.62)*np.clip((upper-.38)*2,0,1)
    color*=1-freckles[:,:,None]*.65
    return color,height,rough
PROFILE={'id':'largemouth_bass','sections':[(-.345,.022,.037,.033,0),(-.28,.031,.059,.051,0),(-.17,.049,.092,.077,.002),(-.045,.066,.121,.098,.004),(.08,.074,.137,.107,.005),(.202,.072,.130,.096,.005),(.299,.065,.108,.078,.003),(.391,.050,.061,.039,-.001),(.466,.030,.019,.020,-.012)],'skin':{'back':(.18,.28,.12),'side':(.45,.58,.25),'belly':(.81,.80,.59),'pattern':'scales','scale_columns':62,'scale_rows':29,'variation':.035},'custom_skin':pigment,'fin_color':(.42,.46,.22),'head_start':.69,'head_end':.81,'roughness':.46,'normal_strength':.21,'morphology':['Adult olive-green elongated sunfish body and broken dark horizontal lateral stripe','Very large oblique mouth; upper jaw reaches posterior to the eye','Deep notch between low spiny dorsal and high rounded soft dorsal','Wide slightly emarginate tail and rounded rather than spear-like pectorals'],'sources':['https://www.dnr.sc.gov/fish/species/largemouthbass.html','https://www.dnr.state.mn.us/minnaqua/speciesprofile/largemouthbass.html','https://dnr.maryland.gov/fisheries/Documents/Reg_Changes/LargemouthBass_ScientificRenaming.pdf']}
def anatomy(f):
    xs=np.linspace(.189,-.071,10);edge=[]
    for i,x in enumerate(xs):
        p=f.surface(float(x),0,-.001);h=.016+.062*math.sin(math.pi*(i+1)/11);edge.append((x,0,p.z+h))
        if i<9:edge.append(((x+xs[i+1])/2,0,p.z+h-.021))
    median(f,'DorsalHard',.189,-.079,edge,'spine_front',31)
    median(f,'DorsalSoft',-.082,-.280,[(-.082,0,.110),(-.119,0,.203),(-.191,0,.205),(-.255,0,.144),(-.281,0,.055)],'spine_rear',24)
    median(f,'Anal',-.126,-.263,[(-.126,0,-.076),(-.155,0,-.155),(-.218,0,-.150),(-.261,0,-.048)],'spine_rear',21,upper=False)
    caudal(f,[(-.377,.062),(-.464,.111),(-.508,.090),(-.492,.032),(-.479,0),(-.497,-.038),(-.510,-.094),(-.465,-.110),(-.376,-.059)],29)
    paired(f,'Pectoral',.249,.194,1.92,.057,.101,-.044,rays=20)
    paired(f,'Pelvic',.172,.124,2.53,.047,.085,-.060,rays=16)
    eyes(f,.359,1.12,.0158,(.43,.36,.16));gills(f,.246,.036,.0012)
    f.ellipsoid('WideMouthInterior',(.468,0,-.012),(.003,.029,.022),f.mats['dark'],'head')
    f.ellipsoid('StrongLowerJaw',(.429,0,-.037),(.067,.037,.020),f.mats['skin'],'jaw')
    for sign,tag in ((-1,'R'),(1,'L')):
        # Posterior maxillary end x=.288 is behind eye center x=.359.
        pts=[(.473,sign*.026,-.005),(.430,sign*.041,-.010),(.356,sign*.059,-.040),(.288,sign*.063,-.038)]
        f.tube('LongMaxillaryOpening'+tag,pts,[.0027,.0030,.0030,.0016],f.mats['dark'],'head',8)
        f.tube('UpperLip'+tag,[(.474,0,.001),(.469,sign*.026,.001),(.422,sign*.044,-.008),(.354,sign*.060,-.035)],[.0028,.0034,.0030,.0020],f.mats['lip'],'head',8)
        f.tube('LowerLip'+tag,[(.492,0,-.023),(.478,sign*.027,-.032),(.422,sign*.037,-.052),(.330,sign*.054,-.048)],[.0027,.0032,.0028,.0018],f.mats['lip'],'jaw',8)
