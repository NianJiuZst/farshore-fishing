"""Deep-bodied Carassius carassius, convex long dorsal, no barbels, shallow tail notch."""
from fish_profiles._freshwater import paired_fin,median_fin,caudal,eye_pair,gill_pair,small_mouth
PROFILE={'id':'crucian_carp','sections':[(-.353,.018,.032,.031,0),(-.28,.032,.073,.069,0),(-.18,.063,.134,.12,.002),(-.04,.085,.185,.15,.004),(.10,.087,.199,.155,.006),(.225,.077,.172,.126,.004),(.315,.059,.117,.091,0),(.387,.039,.069,.053,-.008),(.449,.024,.033,.027,-.013),(.476,.011,.013,.014,-.015)],'skin':{'back':(.245,.23,.11),'side':(.63,.49,.225),'belly':(.80,.69,.40),'pattern':'scales','scale_columns':33,'scale_rows':22,'variation':.065},'fin_color':(.51,.36,.17),'roughness':.47,'head_start':.70,'head_end':.83,'swim_amplitude':.8,'morphology':['Short high laterally compressed bronze body','No mouth barbels','Long dorsal with convex upper contour','Rounded paired fins and shallowly notched caudal','Small terminal mouth and short blunt snout'],'sources':['https://www.fishbase.se/summary/270']}
def anatomy(f):
 median_fin(f,'Dorsal',.20,-.25,[(.20,0,.183),(.14,0,.260),(.035,0,.292),(-.08,0,.244),(-.195,0,.163),(-.253,0,.092)],'spine_mid',32)
 median_fin(f,'Anal',-.12,-.245,[(-.121,0,-.130),(-.17,0,-.23),(-.25,0,-.211),(-.278,0,-.09)],'spine_rear',18,upper=False)
 caudal(f,-.35,.032,[(-.434,.117),(-.506,.125),(-.492,.065),(-.464,.005),(-.492,-.061),(-.505,-.117),(-.433,-.119)],28)
 paired_fin(f,'Pectoral',.266,.213,2.12,.071,.087,-.093,'spine_front',19)
 paired_fin(f,'Pelvic',.045,-.002,2.48,.052,.073,-.057,'spine_mid',18)
 eye_pair(f,.367,1.14,.0115,(.56,.365,.12));gill_pair(f,.296,.0011,.035);small_mouth(f,.477,.013,-.016,radius=.0016)
