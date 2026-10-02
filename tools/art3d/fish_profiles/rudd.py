"""Scardinius erythrophthalmus: deeper gold body, upturned mouth, posterior dorsal."""
from fish_profiles._freshwater import paired_fin,median_fin,caudal,eye_pair,gill_pair,small_mouth
PROFILE={'id':'rudd','sections':[(-.36,.012,.031,.026,0),(-.278,.026,.061,.049,0),(-.165,.047,.105,.080,.002),(-.02,.061,.149,.112,.004),(.12,.064,.157,.118,.005),(.244,.054,.122,.087,.007),(.339,.039,.079,.050,.007),(.414,.024,.044,.022,.009),(.473,.010,.019,.012,.010)],'skin':{'back':(.20,.245,.12),'side':(.64,.565,.27),'belly':(.81,.77,.54),'pattern':'scales','scale_columns':39,'scale_rows':24,'variation':.066},'fin_color':(.63,.175,.055),'roughness':.44,'head_start':.74,'head_end':.86,'morphology':['Deeper golden-silver body than roach','Upturned small mouth and forward lower lip','Dorsal starts clearly behind pelvic origin','Bright scarlet lower fins and caudal','No barbels; red-orange iris'],'sources':['https://www.fishbase.se/summary/2951']}
def anatomy(f):
 dorsal=f.material('RuddDorsalAmber',(.46,.32,.135),.52)
 median_fin(f,'Dorsal',-.034,-.162,[(-.031,0,.146),(-.065,0,.264),(-.119,0,.202),(-.166,0,.105)],'spine_mid',19,dorsal)
 median_fin(f,'Anal',-.164,-.273,[(-.165,0,-.081),(-.205,0,-.166),(-.288,0,-.114),(-.278,0,-.050)],'spine_rear',18,upper=False)
 caudal(f,-.357,.029,[(-.441,.111),(-.509,.157),(-.481,.073),(-.426,0),(-.481,-.075),(-.508,-.141),(-.441,-.102)],28)
 paired_fin(f,'Pectoral',.275,.225,2.12,.057,.082,-.090,'spine_front',18)
 paired_fin(f,'Pelvic',.065,.018,2.44,.047,.068,-.076,'spine_mid',17)
 eye_pair(f,.369,1.1,.0113,(.73,.26,.03));gill_pair(f,.294,.0011,.029);small_mouth(f,.475,.012,.022,angle=1.2,radius=.0014)
