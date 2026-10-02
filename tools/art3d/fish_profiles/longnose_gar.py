"""Lepisosteus osseus: very narrow long snout and thin armored body, not broad alligator-gar head."""
import math
from fish_profiles._freshwater import paired_fin,median_fin,caudal,eye_pair,gill_pair,jaw_loft
PROFILE={'id':'longnose_gar','sections':[(-.39,.009,.014,.012,0),(-.315,.021,.032,.027,0),(-.205,.029,.041,.034,0),(-.05,.035,.046,.038,.001),(.09,.033,.043,.034,.001),(.17,.029,.033,.022,0),(.227,.022,.022,.014,0),(.270,.009,.010,.006,-.003),(.36,.0062,.005,.0038,-.004),(.475,.0046,.0038,.0027,-.004),(.511,.0023,.0026,.002,-.004)],'skin':{'back':(.21,.245,.12),'side':(.49,.50,.31),'belly':(.77,.765,.59),'pattern':'diamond','scale_columns':69,'feature':'spots','spot_count':100,'spot_radius':(.002,.006),'variation':.095},'fin_color':(.47,.45,.29),'fin_pattern':'spots','roughness':.49,'head_start':.67,'head_end':.75,'swim_amplitude':.80,'morphology':['Needle-narrow snout more than twice remaining head length','Thin elongate armored body with fine diamond-shaped scales','Dark side and tail spots, rear dorsal and anal','Rounded slightly asymmetric tail, no barbels','Distinct from broad-snouted robust alligator gar'],'sources':['https://www.nps.gov/miss/learn/nature/long-nosed-gar-lepisosteus-osseus.htm','https://dnr.sc.gov/fish/species/longnosegar.html']}
def anatomy(f):
 median_fin(f,'Dorsal',-.251,-.333,[(-.25,0,.038),(-.278,0,.101),(-.313,0,.104),(-.354,0,.020)],'spine_rear',19)
 median_fin(f,'Anal',-.275,-.344,[(-.273,0,-.029),(-.304,0,-.086),(-.346,0,-.071),(-.364,0,-.016)],'spine_rear',17,upper=False)
 caudal(f,-.385,.016,[(-.449,.068),(-.497,.085),(-.521,.043),(-.521,-.011),(-.499,-.062),(-.462,-.064),(-.418,-.036)],27)
 paired_fin(f,'Pectoral',.158,.122,2.12,.049,.062,-.048,'spine_front',16)
 paired_fin(f,'Pelvic',-.094,-.134,2.45,.040,.052,-.049,'spine_rear',15)
 eye_pair(f,.235,1.04,.0065,(.61,.47,.16));gill_pair(f,.188,.00075,.016)
 jaw_loft(f,'NeedleLowerJaw',[(.23,0,.017,.0055,-.014),(.28,0,.008,.0035,-.011),(.38,0,.0055,.0026,-.009),(.512,0,.0025,.0017,-.007)])
 for s in (-1,1):f.tube('NeedleMouthSeam'+str(s),[(.239,s*.018,-.008),(.28,s*.008,-.006),(.38,s*.006,-.005),(.511,s*.0025,-.0045)],.00065,f.mats['dark'],'head',6)
