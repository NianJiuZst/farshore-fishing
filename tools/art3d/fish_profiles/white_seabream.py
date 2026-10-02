"""Diplodus sargus. Original deep silver sar, open saddle, black opercular edge and lower fins."""
import math
import numpy as np
from fish_profiles.japanese_whiting import paired,median,caudal,eyes,gills,mouth,crest

def pigment(u,v,upper,color,height,rough):
    saddle=np.exp(-((u-.074)/.039)**4)*np.clip((upper-.19)*7,0,1)
    edge=np.exp(-((u-.735)/.014)**2)*np.clip((.90-upper)*6,0,1)*np.clip((upper-.22)*6,0,1)
    bars=(np.maximum(0,np.cos(u*math.tau*9)))**9*np.clip((.73-u)*10,0,1)*np.clip((u-.16)*20,0,1)
    color*=1-(.93*saddle+.73*edge+.15*bars).clip(0,.95)[:,:,None]
    return color,height,rough
PROFILE={'id':'white_seabream','sections':[(-.338,.020,.037,.033,0),(-.257,.036,.082,.067,0),(-.139,.058,.142,.116,.006),(-.012,.076,.191,.149,.010),(.111,.082,.212,.161,.011),(.233,.076,.197,.139,.009),(.321,.058,.144,.098,.006),(.401,.036,.067,.042,-.001),(.472,.017,.020,.017,-.016)],'skin':{'back':(.39,.44,.45),'side':(.76,.78,.72),'belly':(.88,.88,.79),'pattern':'scales','scale_columns':57,'scale_rows':28,'variation':.035},'custom_skin':pigment,'fin_color':(.45,.49,.46),'roughness':.42,'normal_strength':.22,'head_start':.76,'head_end':.87,'morphology':['Deep compressed silver body with high curved dorsal contour','Black caudal saddle that does not reach the underside of peduncle','Black opercular margin and dark pelvic fins; restrained adult vertical bars','Short small mouth with incisor-like front teeth and forked tail'],'sources':['https://doris.ffessm.fr/Especes/Diplodus-sargus-Sar-commun-de-Mediterranee-463']}
def anatomy(f):
    crest(f,'DorsalSpiny',.244,-.095,[.017,.038,.061,.078,.080,.078,.071,.064,.056,.047,.039],notch=.019)
    median(f,'DorsalSoft',-.097,-.275,[(-.097,0,.187),(-.139,0,.203),(-.229,0,.145),(-.276,0,.065)],'spine_rear',25)
    median(f,'Anal',-.094,-.266,[(-.094,0,-.140),(-.135,0,-.199),(-.216,0,-.153),(-.267,0,-.061)],'spine_rear',23,upper=False)
    caudal(f,[(-.377,.073),(-.505,.158),(-.479,.075),(-.415,0),(-.482,-.079),(-.506,-.156),(-.377,-.066)],29)
    paired(f,'Pectoral',.274,.213,1.99,.062,.174,-.071,rays=21)
    dark=f.material('DarkPelvics',(.16,.21,.20),.48)
    paired(f,'Pelvic',.180,.123,2.59,.045,.087,-.082,rays=15,material=dark)
    eyes(f,.370,1.09,.0185,(.64,.56,.31));gills(f,.285,.037,.0011);mouth(f,.475,.017,-.016,.0053,.0022)
