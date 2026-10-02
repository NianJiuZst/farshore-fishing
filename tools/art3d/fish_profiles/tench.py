"""Tinca tinca: robust olive body, tiny embedded scales, red eye, rounded fins and two barbels."""
from fish_profiles._freshwater import paired_fin,median_fin,caudal,eye_pair,gill_pair,small_mouth,taper_barbel
PROFILE={'id':'tench','sections':[(-.35,.027,.047,.045,0),(-.27,.039,.071,.066,0),(-.16,.060,.112,.099,.002),(-.01,.075,.144,.12,.004),(.135,.08,.150,.113,.004),(.255,.07,.123,.095,.003),(.343,.057,.085,.065,-.001),(.41,.039,.052,.039,-.007),(.47,.017,.024,.019,-.012)],'skin':{'back':(.105,.155,.055),'side':(.32,.355,.10),'belly':(.65,.575,.23),'pattern':'fine_scales','scale_columns':98,'scale_rows':40,'variation':.095},'fin_color':(.32,.31,.13),'roughness':.43,'head_start':.73,'head_end':.84,'swim_amplitude':.78,'morphology':['Thick olive-green rounded body and minute embedded scales','Small red eyes, thick lips and one short barbel pair','Rounded dorsal/paired/anal fins and near-square shallowly concave tail','Thick caudal peduncle rather than a thin forked-tail stalk'],'sources':['https://www.fishbase.se/summary/tinca-tinca.html']}
def anatomy(f):
 median_fin(f,'Dorsal',.058,-.098,[(.06,0,.153),(.006,0,.256),(-.052,0,.256),(-.117,0,.126)],'spine_mid',22)
 median_fin(f,'Anal',-.175,-.285,[(-.175,0,-.097),(-.211,0,-.171),(-.272,0,-.164),(-.309,0,-.057)],'spine_rear',20,upper=False)
 caudal(f,-.347,.044,[(-.437,.117),(-.490,.114),(-.495,.052),(-.473,0),(-.496,-.059),(-.479,-.113),(-.424,-.113)],29)
 paired_fin(f,'Pectoral',.267,.210,2.10,.068,.092,-.094,'spine_front',21)
 paired_fin(f,'Pelvic',.062,.008,2.45,.049,.067,-.070,'spine_mid',20)
 eye_pair(f,.368,1.13,.0093,(.66,.15,.027));gill_pair(f,.287,.0011,.029);small_mouth(f,.474,.016,-.014,radius=.0020)
 for s in (-1,1):taper_barbel(f,'MouthBarbel'+str(s),[(.450,s*.027,-.016),(.445,s*.035,-.030),(.435,s*.037,-.046)],.00165)
