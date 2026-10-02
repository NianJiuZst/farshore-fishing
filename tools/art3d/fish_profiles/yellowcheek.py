"""Elopichthys bambusa: pointed predatory cyprinid, no barbels, yellow cheeks, deep fork."""
import numpy as np
from fish_profiles._freshwater import paired_fin,median_fin,caudal,eye_pair,gill_pair,jaw_loft

def paint(u,v,upper,color,height,rough):
    mask=np.exp(-((u-.78)/.075)**2)*np.exp(-((abs(np.cos(v*np.pi*2))-.28)/.35)**2)
    c=np.array([.66,.57,.23]);color=color*(1-mask[:,:,None]*.48)+c*mask[:,:,None]*.48
    return color,height,rough
PROFILE={'id':'yellowcheek','sections':[(-.365,.012,.024,.021,0),(-.29,.026,.049,.040,0),(-.18,.037,.066,.052,.001),(-.04,.045,.081,.062,.001),(.095,.050,.087,.061,.002),(.211,.047,.080,.051,.003),(.307,.036,.046,.031,.001),(.379,.025,.025,.017,-.002),(.453,.016,.012,.008,-.004),(.482,.008,.006,.004,-.004)],'skin':{'back':(.24,.29,.225),'side':(.62,.67,.56),'belly':(.84,.84,.72),'pattern':'fine_scales','scale_columns':78,'scale_rows':32,'variation':.065},'custom_skin':paint,'fin_color':(.46,.465,.30),'roughness':.43,'head_start':.72,'head_end':.85,'swim_amplitude':.92,'morphology':['Long pointed head and large terminal predatory mouth','No barbels; pale yellow cheeks and lower fins','Small dorsal beginning behind pelvic fins','Deeply forked tail and streamlined fine-scaled body','Not a pike: pointed unflattened snout and central small dorsal'],'sources':['https://dfz.jl.gov.cn/jltc/201805/t20180502_5217576.html','https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=3216']}
def anatomy(f):
 lower=f.material('YellowLowerFins',(.61,.55,.26),.51)
 median_fin(f,'Dorsal',-.063,-.160,[(-.062,0,.079),(-.099,0,.164),(-.137,0,.140),(-.169,0,.063)],'spine_mid',19)
 median_fin(f,'Anal',-.194,-.274,[(-.195,0,-.048),(-.235,0,-.112),(-.284,0,-.086),(-.288,0,-.032)],'spine_rear',17,lower,False)
 caudal(f,-.362,.023,[(-.438,.092),(-.515,.145),(-.489,.073),(-.414,.0),(-.484,-.071),(-.51,-.136),(-.432,-.082)],28)
 paired_fin(f,'Pectoral',.244,.196,2.09,.054,.088,-.066,'spine_front',19,lower)
 paired_fin(f,'Pelvic',.019,-.023,2.46,.040,.064,-.058,'spine_mid',17,lower)
 eye_pair(f,.333,1.08,.0092,(.53,.48,.21));gill_pair(f,.271,.00095,.024)
 jaw_loft(f,'ProjectedLowerJaw',[(.313,0,.027,.010,-.016),(.384,0,.022,.009,-.018),(.458,0,.015,.0045,-.013),(.488,0,.006,.0025,-.008)])
 for s in (-1,1):f.tube('LongGape'+str(s),[(.322,s*.030,-.004),(.369,s*.026,-.010),(.447,s*.017,-.009),(.486,s*.006,-.006)],.0010,f.mats['dark'],'head',7)
