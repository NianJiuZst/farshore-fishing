"""Abramis brama: high thin body, small head, long anal, deep forked gray tail."""
from fish_profiles._freshwater import paired_fin,median_fin,caudal,eye_pair,gill_pair,small_mouth
PROFILE={'id':'common_bream','sections':[(-.35,.012,.026,.024,0),(-.277,.028,.066,.064,0),(-.185,.044,.123,.126,.001),(-.065,.055,.199,.173,.004),(.065,.060,.236,.187,.006),(.192,.056,.212,.152,.003),(.284,.043,.145,.103,-.006),(.362,.027,.076,.054,-.016),(.426,.019,.037,.027,-.017),(.475,.009,.012,.012,-.018)],'skin':{'back':(.225,.245,.20),'side':(.55,.555,.46),'belly':(.76,.74,.60),'pattern':'fine_scales','scale_columns':56,'scale_rows':28,'variation':.055},'fin_color':(.255,.29,.27),'roughness':.47,'head_start':.76,'head_end':.86,'swim_amplitude':.80,'morphology':['Very deep and thin laterally compressed bronze-silver body','Small downturned protrusible mouth and small head','Long anal-fin base with dark gray membrane','High short dorsal and deeply forked caudal','No barbels; body much deeper than roach or rudd'],'sources':['https://www.fishbase.se/summary/Abramis-brama']}
def anatomy(f):
 median_fin(f,'Dorsal',.07,-.055,[(.072,0,.242),(.016,0,.360),(-.022,0,.298),(-.066,0,.194)],'spine_mid',20)
 median_fin(f,'Anal',.00,-.286,[(.001,0,-.184),(-.065,0,-.293),(-.145,0,-.255),(-.229,0,-.161),(-.288,0,-.061)],'spine_mid',34,upper=False)
 caudal(f,-.347,.025,[(-.438,.11),(-.515,.169),(-.486,.075),(-.414,.0),(-.478,-.076),(-.504,-.161),(-.431,-.097)],28)
 paired_fin(f,'Pectoral',.268,.213,2.06,.052,.098,-.118,'spine_front',19)
 paired_fin(f,'Pelvic',.067,.019,2.55,.04,.068,-.07,'spine_mid',17)
 eye_pair(f,.371,1.09,.0102,(.58,.48,.25));gill_pair(f,.309,.0010,.027);small_mouth(f,.476,.010,-.024,radius=.0014)
