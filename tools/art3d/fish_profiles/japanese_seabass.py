"""Original adult Lateolabrax japonicus; not the densely spotted L. maculatus."""
import math
import numpy as np
from mathutils import Vector
from fish_profiles.japanese_whiting import paired,median,caudal,eyes,gills
PROFILE={'id':'japanese_seabass','sections':[(-.365,.018,.031,.028,0),(-.28,.027,.046,.039,0),(-.15,.043,.076,.060,.002),(-.02,.059,.106,.083,.003),(.116,.065,.125,.092,.004),(.241,.060,.115,.079,.003),(.332,.048,.086,.055,.003),(.416,.033,.043,.025,0),(.478,.018,.012,.012,-.008)],'skin':{'back':(.27,.36,.31),'side':(.68,.73,.66),'belly':(.84,.85,.74),'pattern':'fine_scales','scale_columns':76,'scale_rows':34,'variation':.025,'lateral_line':(.41,.47,.40),'lateral_curve':.13,'lateral_arch':.12},'fin_color':(.47,.52,.44),'roughness':.39,'head_start':.72,'head_end':.84,'normal_strength':.18,'morphology':['Elongated silver-green adult Japanese seabass with no dense flank spotting','Thirteen-spined dorsal joined through deep notch to elongated soft dorsal','Large oblique mouth and slightly projecting lower jaw','Forked caudal and short anal fin beneath rear soft dorsal'],'sources':['https://www.fishbase.se/summary/Lateolabrax_japonicus.html','https://www.museum.kagoshima-u.ac.jp/ichthy/INHFJ_2022_026_034.pdf']}
def anatomy(f):
    xs=np.linspace(.215,-.102,13);edge=[]
    for i,x in enumerate(xs):
        p=f.surface(float(x),0,-.001);h=.025+.087*math.sin(math.pi*(i+1)/14);edge.append((x,0,p.z+h))
        if i<12:edge.append(((x+xs[i+1])/2,0,p.z+h-.026))
    median(f,'DorsalSpiny',.215,-.109,edge,'spine_front',43)
    median(f,'DorsalSoft',-.111,-.300,[(-.111,0,.083),(-.150,0,.166),(-.219,0,.151),(-.277,0,.099),(-.301,0,.042)],'spine_rear',23)
    median(f,'Anal',-.148,-.280,[(-.148,0,-.060),(-.187,0,-.142),(-.252,0,-.115),(-.282,0,-.036)],'spine_rear',18,upper=False)
    caudal(f,[(-.405,.062),(-.510,.131),(-.493,.068),(-.434,.0),(-.496,-.070),(-.509,-.128),(-.406,-.057)],28)
    paired(f,'Pectoral',.272,.220,1.91,.051,.106,-.035,rays=20)
    paired(f,'Pelvic',.184,.142,2.55,.038,.071,-.049,rays=15)
    eyes(f,.373,1.13,.0145,(.61,.58,.35));gills(f,.281,.031,.0011)
    f.ellipsoid('MouthCavity',(.480,0,-.008),(.0028,.017,.012),f.mats['dark'],'head')
    f.ellipsoid('LowerJaw',(.446,0,-.023),(.049,.023,.012),f.mats['skin'],'jaw')
    for sign,tag in ((-1,'R'),(1,'L')):
        f.tube('Maxilla'+tag,[(.483,sign*.013,-.003),(.440,sign*.027,-.009),(.375,sign*.045,-.027),(.336,sign*.047,-.027)],[.0022,.0025,.0020,.0012],f.mats['dark'],'head',8)
        f.tube('LowerLip'+tag,[(.493,0,-.014),(.478,sign*.016,-.019),(.429,sign*.028,-.032),(.365,sign*.039,-.034)],[.0020,.0024,.0021,.0012],f.mats['lip'],'jaw',8)
        p=f.surface(.270,sign*1.15,.001);f.tube('OpercularSpine'+tag,[p,p+Vector((-.016,sign*.005,.002))],[.0020,.0002],f.mats['edge'],'head',7)
