"""Acanthopagrus schlegelii: original dark stout-jawed bream with steep forehead."""
import math
import numpy as np
from fish_profiles.japanese_whiting import paired,median,caudal,eyes,gills,mouth,crest

def pigment(u,v,upper,color,height,rough):
    bands=(.5+.5*np.cos(u*math.tau*7))**9*np.clip((.8-u)*8,0,1)*np.clip((upper-.2)*2,0,1)
    color*=1-.15*bands[:,:,None]
    return color,height,rough
PROFILE={'id':'black_seabream','sections':[(-.345,.021,.039,.034,0),(-.264,.034,.072,.060,0),(-.145,.056,.127,.105,.003),(-.014,.073,.177,.134,.007),(.115,.079,.204,.146,.011),(.235,.075,.190,.126,.010),(.322,.059,.143,.089,.004),(.390,.043,.075,.045,-.003),(.470,.023,.023,.021,-.019)],'skin':{'back':(.18,.24,.24),'side':(.45,.51,.49),'belly':(.71,.73,.66),'pattern':'scales','scale_columns':53,'scale_rows':27,'variation':.045,'lateral_line':(.25,.31,.30),'lateral_curve':.19,'lateral_arch':.16},'custom_skin':pigment,'fin_color':(.24,.31,.29),'roughness':.45,'head_start':.73,'head_end':.86,'normal_strength':.24,'morphology':['High compressed dark-silver body with steep forehead and rounded powerful nape','Small thick-lipped terminal mouth, robust shell-crushing jaw','Faint broad adult bars under large dark-edged scales','Long continuous spiny dorsal and forked dark caudal, dark pelvic fins'],'sources':['https://fishdb.sinica.edu.tw/mobi/species.php?science=Acanthopagrus+schlegelii']}
def anatomy(f):
    crest(f,'DorsalSpiny',.248,-.098,[.013,.034,.062,.089,.094,.091,.080,.070,.058,.051,.043],notch=.021)
    median(f,'DorsalSoft',-.100,-.278,[(-.1,0,.172),(-.139,0,.187),(-.215,0,.142),(-.278,0,.062)],'spine_rear',24)
    median(f,'Anal',-.117,-.276,[(-.117,0,-.115),(-.157,0,-.181),(-.223,0,-.135),(-.276,0,-.052)],'spine_rear',21,upper=False)
    caudal(f,[(-.390,.074),(-.508,.158),(-.487,.076),(-.420,0),(-.490,-.079),(-.510,-.153),(-.389,-.068)],28)
    paired(f,'Pectoral',.272,.213,1.99,.065,.177,-.077,rays=21)
    paired(f,'Pelvic',.172,.115,2.57,.050,.085,-.080,rays=16)
    eyes(f,.364,1.11,.0168,(.38,.36,.24));gills(f,.283,.040,.0013);mouth(f,.473,.021,-.020,.007,.0027)
