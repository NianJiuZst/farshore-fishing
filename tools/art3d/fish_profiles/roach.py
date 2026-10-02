"""Rutilus rutilus: slender silver form, red iris, aligned dorsal/pelvic origins."""
from fish_profiles._freshwater import paired_fin,median_fin,caudal,eye_pair,gill_pair,small_mouth
PROFILE={'id':'roach','sections':[(-.36,.010,.027,.023,0),(-.285,.023,.051,.044,0),(-.17,.038,.084,.070,.002),(-.035,.052,.118,.088,.003),(.10,.057,.128,.090,.004),(.235,.052,.103,.077,.003),(.335,.039,.073,.051,0),(.41,.025,.039,.029,-.003),(.475,.009,.012,.01,-.005)],'skin':{'back':(.23,.29,.25),'side':(.63,.69,.66),'belly':(.84,.85,.75),'pattern':'scales','scale_columns':42,'scale_rows':25,'variation':.055},'fin_color':(.40,.365,.275),'roughness':.42,'head_start':.73,'head_end':.86,'morphology':['Slender laterally compressed silver body','Red iris and orange-red lower fins','Terminal small mouth, no barbels','Dorsal origin nearly aligned above pelvic origin','Forked caudal and normal-length anal fin'],'sources':['https://www.fishbase.se/Summary/Rutilus-rutilus']}
def anatomy(f):
 lower=f.material('OrangeLowerFins',(.74,.235,.065),.50)
 median_fin(f,'Dorsal',.052,-.099,[(.054,0,.132),(.018,0,.241),(-.035,0,.207),(-.104,0,.098)],'spine_mid',20)
 median_fin(f,'Anal',-.145,-.252,[(-.145,0,-.073),(-.19,0,-.142),(-.263,0,-.105),(-.263,0,-.046)],'spine_rear',17,lower,False)
 caudal(f,-.357,.026,[(-.444,.102),(-.512,.142),(-.486,.073),(-.426,0),(-.485,-.068),(-.507,-.13),(-.442,-.092)],28)
 paired_fin(f,'Pectoral',.267,.223,2.06,.056,.083,-.080,'spine_front',18,lower)
 paired_fin(f,'Pelvic',.050,.008,2.40,.043,.068,-.060,'spine_mid',16,lower)
 eye_pair(f,.374,1.12,.0108,(.79,.21,.043));gill_pair(f,.300,.001,.029);small_mouth(f,.476,.011,-.004,radius=.0012)
