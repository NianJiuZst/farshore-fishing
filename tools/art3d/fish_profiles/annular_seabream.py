"""Diplodus annularis, distinct small oval bream with near-complete black peduncle ring."""
import math
import numpy as np
from fish_profiles.japanese_whiting import paired,median,caudal,eyes,gills,mouth,crest

def pigment(u,v,upper,color,height,rough):
    ring=np.exp(-((u-.077)/.035)**4)*(.83+.17*upper)
    color=color*(1-ring[:,:,None]*.96)+np.array([.035,.039,.025])*ring[:,:,None]*.96
    # Yellow wash towards head, with no juvenile vertical stripes.
    yellow=np.exp(-((u-.77)/.21)**2)*np.clip((upper-.50)*2,0,1)*.28
    color=color*(1-yellow[:,:,None])+np.array([.80,.72,.28])*yellow[:,:,None]
    return color,height,rough
PROFILE={'id':'annular_seabream','sections':[(-.347,.018,.033,.031,0),(-.266,.032,.070,.060,0),(-.142,.054,.130,.108,.004),(-.012,.071,.172,.138,.007),(.123,.073,.186,.145,.008),(.243,.065,.172,.121,.007),(.331,.046,.119,.078,.002),(.414,.027,.055,.029,-.002),(.478,.013,.014,.013,-.012)],'skin':{'back':(.49,.52,.34),'side':(.77,.79,.57),'belly':(.87,.87,.69),'pattern':'fine_scales','scale_columns':57,'scale_rows':29,'variation':.025},'custom_skin':pigment,'fin_color':(.65,.66,.47),'roughness':.43,'normal_strength':.19,'head_start':.75,'head_end':.86,'morphology':['Small oval compressed silver-yellow bream with tapered head and small mouth','Nearly closed black ring around caudal peduncle, unlike open white-seabream saddle','Yellow pelvic fins and yellow anterior anal fin','Continuous moderately raised dorsal, proportionally narrow forked tail, no adult flank bars'],'sources':['https://doris.ffessm.fr/Especes/Diplodus-annularis-Sparaillon-487']}
def anatomy(f):
    crest(f,'DorsalSpiny',.238,-.097,[.014,.031,.054,.069,.072,.067,.060,.052,.046,.040,.033],notch=.016)
    median(f,'DorsalSoft',-.099,-.283,[(-.099,0,.164),(-.135,0,.180),(-.228,0,.122),(-.284,0,.055)],'spine_rear',24)
    yellow=f.material('YellowLowerFins',(.80,.66,.12),.48)
    anal=median(f,'Anal',-.091,-.272,[(-.091,0,-.122),(-.131,0,-.177),(-.212,0,-.139),(-.273,0,-.052)],'spine_rear',22,material=yellow,upper=False)
    # Diagnostic yellow is confined to the anterior anal membrane.
    anal.data.materials.append(f.mats['fin'])
    for poly in anal.data.polygons:
        if sum(anal.data.vertices[i].co.x for i in poly.vertices)/len(poly.vertices)<-.173:poly.material_index=1
    caudal(f,[(-.386,.062),(-.509,.143),(-.485,.068),(-.419,0),(-.486,-.070),(-.507,-.138),(-.386,-.058)],27)
    paired(f,'Pectoral',.277,.223,1.98,.056,.158,-.065,rays=20)
    paired(f,'Pelvic',.184,.136,2.58,.042,.079,-.065,rays=15,material=yellow)
    eyes(f,.372,1.12,.0194,(.70,.58,.25));gills(f,.291,.033,.0011);mouth(f,.480,.013,-.012,.0044,.0017)
