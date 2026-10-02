"""Pagellus erythrinus: long straight-pointed snout, delicate pink body, upper blue speckles."""
import math
import numpy as np
from fish_profiles.japanese_whiting import paired,median,caudal,eyes,gills,mouth,crest

def pigment(u,v,upper,color,height,rough):
    dots=np.maximum(0,np.sin(u*421+np.cos((v*math.tau*8)))*np.cos((v*math.tau*50)-u*27)-.81)/.19
    dots*=np.clip((upper-.48)*4,0,1)*np.clip((.82-u)*14,0,1)
    color=color*(1-dots[:,:,None]*.82)+np.array([.19,.44,.66])*dots[:,:,None]*.82
    red=np.exp(-((u-.744)/.019)**2-((upper-.74)/.13)**2)
    color=color*(1-red[:,:,None]*.74)+np.array([.70,.18,.14])*red[:,:,None]*.74
    return color,height,rough
PROFILE={'id':'common_pandora','sections':[(-.351,.017,.033,.029,0),(-.264,.032,.070,.058,0),(-.143,.052,.123,.099,.002),(-.016,.065,.160,.123,.004),(.109,.068,.176,.132,.005),(.226,.060,.159,.113,.005),(.321,.046,.112,.072,.002),(.404,.027,.059,.030,-.003),(.482,.011,.014,.010,-.016)],'skin':{'back':(.70,.43,.41),'side':(.86,.68,.65),'belly':(.92,.84,.78),'pattern':'scales','scale_columns':60,'scale_rows':29,'variation':.025},'custom_skin':pigment,'fin_color':(.75,.47,.42),'roughness':.40,'normal_strength':.19,'head_start':.77,'head_end':.88,'morphology':['Oval compressed pink-silver body with longer almost straight snout, unlike convex-naped red seabream','Small low oblique mouth; snout exceeds twice eye diameter','Fine blue speckles concentrated on upper body and red upper opercular edge','Continuous twelve-spined dorsal, very long pointed pectorals and forked tail without white tips'],'sources':['https://doris.ffessm.fr/Especes/Pagellus-erythrinus-Pageot-commun-2771','https://www.fao.org/fishery/docs/CDrom/ARTFIMED/ArtFiWeb/descript/Species/SPAPAERY.HTML']}
def anatomy(f):
    crest(f,'DorsalSpiny',.228,-.109,[.015,.032,.047,.060,.063,.061,.058,.054,.049,.043,.038,.030],notch=.015)
    median(f,'DorsalSoft',-.111,-.290,[(-.111,0,.147),(-.148,0,.169),(-.237,0,.112),(-.291,0,.045)],'spine_rear',23)
    median(f,'Anal',-.135,-.272,[(-.135,0,-.099),(-.166,0,-.159),(-.232,0,-.118),(-.273,0,-.050)],'spine_rear',19,upper=False)
    caudal(f,[(-.391,.062),(-.512,.148),(-.488,.070),(-.422,0),(-.490,-.073),(-.511,-.148),(-.391,-.058)],28)
    paired(f,'LongPectoral',.270,.209,1.91,.054,.224,-.080,rays=23)
    paired(f,'Pelvic',.173,.123,2.56,.040,.085,-.064,rays=15)
    eyes(f,.350,1.10,.0168,(.73,.46,.28));gills(f,.272,.031,.0011);mouth(f,.484,.010,-.017,.0042,.0016)
