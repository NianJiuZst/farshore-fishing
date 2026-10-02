"""Pagrus major: original high, convex-naped red porgy with blue speckling."""
import math
import numpy as np
from fish_profiles.japanese_whiting import paired,median,caudal,eyes,gills,mouth,crest
PROFILE={'id':'red_seabream','sections':[(-.346,.019,.035,.030,0),(-.273,.032,.071,.058,0),(-.154,.053,.128,.102,.005),(-.025,.071,.173,.130,.009),(.108,.076,.195,.143,.013),(.222,.069,.184,.129,.013),(.315,.054,.140,.095,.008),(.404,.032,.067,.041,0),(.475,.016,.020,.017,-.018)],'skin':{'back':(.69,.32,.26),'side':(.85,.59,.52),'belly':(.92,.80,.70),'pattern':'scales','scale_columns':56,'scale_rows':27,'feature':'spots','spot_color':(.15,.42,.60),'spot_count':125,'spot_radius':(.0025,.0056),'spot_u_range':(.10,.79),'variation':.025},'fin_color':(.68,.36,.32),'roughness':.40,'head_start':.72,'head_end':.86,'normal_strength':.22,'morphology':['Deep compressed red-pink sparid, distinct bulged convex nape','Small terminal mouth and stout jaw ending well forward of eye','Fine blue spots across rose sides; pink-silver belly','Continuous spiny dorsal, pointed pectorals and strongly forked caudal'],'sources':['https://ciesm.org/atlas_preview/Pagrusmajor.php','https://fishdb.sinica.edu.tw/chi/species.php?science=Pagrus+major']}
def anatomy(f):
    crest(f,'DorsalSpiny',.242,-.088,[.010,.020,.053,.071,.076,.072,.067,.060,.052,.044,.033],notch=.018)
    median(f,'DorsalSoft',-.089,-.281,[(-.089,0,.180),(-.133,0,.201),(-.213,0,.163),(-.279,0,.061)],'spine_rear',24)
    median(f,'Anal',-.108,-.268,[(-.108,0,-.118),(-.154,0,-.182),(-.223,0,-.140),(-.271,0,-.051)],'spine_rear',20,upper=False)
    caudal(f,[(-.383,.066),(-.511,.164),(-.493,.085),(-.421,0),(-.493,-.083),(-.509,-.157),(-.382,-.059)],29)
    paired(f,'Pectoral',.272,.212,1.96,.067,.191,-.084,rays=21)
    paired(f,'Pelvic',.169,.123,2.59,.045,.087,-.084,rays=15)
    eyes(f,.362,1.08,.0180,(.72,.40,.13));gills(f,.282,.034,.0012);mouth(f,.477,.015,-.018,.006,.0020)
