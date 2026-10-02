"""Oblada melanura. Independent slender, big-eyed sparid with white-edged black saddle."""
import math
import numpy as np
from fish_profiles.japanese_whiting import paired,median,caudal,eyes,gills,mouth,crest

def pigment(u,v,upper,color,height,rough):
    # A saddle rather than full belly ring, with a distinct white perimeter.
    shape=((u-.070)/.040)**4+((upper-.72)/.52)**4
    white=np.exp(-shape*.50);black=np.exp(-shape*2.2)
    color=color*(1-white[:,:,None]) + np.array([.92,.94,.90])*white[:,:,None]
    color=color*(1-black[:,:,None]*.98)+np.array([.022,.028,.027])*black[:,:,None]*.98
    lines=np.maximum(0,np.cos(v*math.tau*21))**18*np.clip((.78-u)*9,0,1)*np.clip((u-.13)*20,0,1)
    color*=1-.18*lines[:,:,None]
    return color,height,rough
PROFILE={'id':'saddled_seabream','sections':[(-.355,.018,.034,.029,0),(-.268,.029,.064,.051,0),(-.146,.048,.108,.085,.002),(-.020,.063,.139,.109,.004),(.119,.067,.156,.116,.004),(.247,.060,.141,.095,.003),(.334,.044,.103,.060,.001),(.411,.028,.051,.025,.001),(.481,.014,.019,.013,-.001)],'skin':{'back':(.37,.44,.48),'side':(.74,.79,.78),'belly':(.88,.89,.81),'pattern':'fine_scales','scale_columns':65,'scale_rows':30,'variation':.025},'custom_skin':pigment,'fin_color':(.58,.62,.59),'roughness':.39,'normal_strength':.18,'head_start':.75,'head_end':.86,'morphology':['Oblong, less deep-bodied bream with short snout and proportionally large eyes','Small oblique upturned terminal mouth','White-bordered black caudal-peduncle saddle; fine longitudinal dark flank lines','Continuous dorsal with eleven spines and deeply forked uncoloured tail'],'sources':['https://doris.ffessm.fr/Especes/Oblada-melanura-Oblade-720']}
def anatomy(f):
    crest(f,'DorsalSpiny',.228,-.063,[.019,.046,.065,.071,.069,.062,.055,.049,.043,.038,.032],notch=.015)
    median(f,'DorsalSoft',-.065,-.280,[(-.065,0,.157),(-.110,0,.181),(-.216,0,.124),(-.280,0,.054)],'spine_mid',25)
    median(f,'Anal',-.066,-.269,[(-.066,0,-.104),(-.111,0,-.164),(-.217,0,-.113),(-.270,0,-.043)],'spine_mid',25,upper=False)
    caudal(f,[(-.397,.063),(-.513,.147),(-.488,.069),(-.421,0),(-.491,-.066),(-.511,-.142),(-.397,-.058)],28)
    paired(f,'Pectoral',.287,.232,1.95,.054,.143,-.055,rays=20)
    paired(f,'Pelvic',.191,.146,2.51,.042,.081,-.055,rays=15)
    eyes(f,.374,1.17,.0235,(.63,.59,.38));gills(f,.292,.029,.0010);mouth(f,.484,.014,.000,.0045,.0016)
    # Lower lip projects slightly upward beyond upper-lip plane.
    f.ellipsoid('UpturnedChin',(.473,0,-.008),(.018,.013,.009),f.mats['skin'],'jaw')
