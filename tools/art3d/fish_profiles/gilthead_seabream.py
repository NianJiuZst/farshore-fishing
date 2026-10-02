"""Sparus aurata: curved forehead, gold interorbital band, red-edged black opercular blotch."""
import math
import numpy as np
from fish_profiles.japanese_whiting import paired,median,caudal,eyes,gills,mouth,crest

def pigment(u,v,upper,color,height,rough):
    # Map the transverse gold forehead band over dorsal surface between both eyes.
    gold=np.exp(-((u-.873)/.018)**2)*np.clip((upper-.56)*5,0,1)
    color=color*(1-gold[:,:,None]) + np.array([.86,.67,.15])*gold[:,:,None]
    blot=np.exp(-((u-.745)/.028)**4-((upper-.70)/.105)**4)
    red=np.exp(-((u-.743)/.025)**2-((upper-.52)/.070)**2)
    color=color*(1-red[:,:,None]*.62)+np.array([.63,.20,.15])*red[:,:,None]*.62
    color*=1-blot[:,:,None]*.94
    lines=np.maximum(0,np.cos(v*math.tau*23))**20*np.clip((.73-u)*12,0,1)
    color*=1-.10*lines[:,:,None]
    return color,height,rough
PROFILE={'id':'gilthead_seabream','sections':[(-.343,.021,.038,.034,0),(-.259,.037,.080,.069,0),(-.139,.060,.141,.118,.004),(-.011,.079,.189,.148,.008),(.115,.083,.210,.154,.011),(.225,.077,.202,.132,.009),(.309,.061,.157,.095,.004),(.393,.039,.079,.043,-.005),(.470,.023,.022,.020,-.024)],'skin':{'back':(.39,.45,.42),'side':(.72,.74,.65),'belly':(.86,.85,.72),'pattern':'fine_scales','scale_columns':78,'scale_rows':33,'variation':.03},'custom_skin':pigment,'fin_color':(.43,.47,.39),'roughness':.40,'normal_strength':.20,'head_start':.77,'head_end':.88,'morphology':['Deep oval compressed body and smoothly curved steep forehead with small eyes','Golden transverse band between eyes; black upper opercular blotch edged red below','Low small slightly oblique mouth with thick lips','Eleven-spined continuous dorsal, long pointed pectorals and forked tail'],'sources':['https://www.fao.org/fishery/docs/DOCUMENT/aquaculture/CulturedSpecies/file/en/en_giltheadseabr.htm']}
def anatomy(f):
    crest(f,'DorsalSpiny',.242,-.096,[.017,.044,.071,.084,.081,.077,.069,.061,.052,.046,.039],notch=.019)
    median(f,'DorsalSoft',-.098,-.283,[(-.098,0,.184),(-.144,0,.197),(-.229,0,.147),(-.285,0,.062)],'spine_rear',26)
    median(f,'Anal',-.105,-.276,[(-.105,0,-.129),(-.141,0,-.191),(-.226,0,-.148),(-.277,0,-.059)],'spine_rear',24,upper=False)
    caudal(f,[(-.387,.075),(-.507,.164),(-.479,.074),(-.421,0),(-.482,-.074),(-.509,-.160),(-.387,-.068)],29)
    paired(f,'Pectoral',.264,.202,1.98,.066,.193,-.086,rays=22)
    paired(f,'Pelvic',.178,.119,2.56,.046,.092,-.083,rays=16)
    eyes(f,.366,1.08,.0148,(.57,.50,.27));gills(f,.277,.039,.0013);mouth(f,.473,.021,-.024,.006,.0028)
