"""Original five-scute-row Chinese sturgeon, ventral mouth and four barbels."""
import math
import numpy as np
from mathutils import Vector
PROFILE={
'id':'chinese_sturgeon',
'sections':[(-.365,.012,.019,.014,.001),(-.31,.020,.030,.022,0),(-.23,.032,.045,.032,0),(-.10,.048,.067,.042,.001),(.04,.061,.078,.047,.002),(.17,.062,.070,.043,.001),(.26,.052,.042,.026,-.001),(.32,.043,.027,.016,-.003),(.40,.027,.015,.009,-.006),(.474,.006,.007,.005,-.006)],
'skin':{'back':(.15,.19,.195),'side':(.38,.405,.39),'belly':(.73,.72,.61),'pattern':'smooth','variation':.085},
'fin_color':(.33,.36,.35),'roughness':.51,'swim_amplitude':.86,
'morphology':['Five longitudinal rows of actual bony scutes','Flattened pointed rostrum, mouth strictly on underside','Exactly four short underside barbels anterior to ventral mouth','Posterior dorsal and anal fins, upper caudal lobe conspicuously longer','Gray dorsum and light underside, no dense cycloid scales'],
'sources':['https://www.fisheries.noaa.gov/species/chinese-sturgeon','https://repository.library.noaa.gov/view/noaa/16217/noaa_16217_DS1.pdf']}

def anatomy(f):
    f.fin('Dorsal',[f.surface(float(x),0,-.0012) for x in np.linspace(-.205,-.29,18)],[(-.198,0,.052),(-.24,0,.125),(-.271,0,.121),(-.316,0,.042)],bone='dorsal',parent='spine_rear',rays=21)
    f.fin('Anal',[f.surface(float(x),math.pi,-.0012) for x in np.linspace(-.254,-.32,18)],[(-.251,0,-.03),(-.289,0,-.083),(-.34,0,-.072),(-.346,0,-.023)],bone='anal',parent='spine_rear',rays=17)
    # Strongly heterocercal: axial upper lobe is substantially longer than lower.
    f.fin('Caudal',[(-.363,0,.017),(-.363,0,.001),(-.363,0,-.011)],[(-.418,0,.068),(-.501,0,.192),(-.486,0,.091),(-.443,0,.021),(-.480,0,-.058),(-.418,0,-.038)],bone='caudal',parent='tail',rays=27)
    for side in (-1,1):
        sn='L' if side>0 else 'R'
        f.fin('Pectoral_'+sn,[f.surface(float(x),side*2.20,-.0012) for x in np.linspace(.21,.16,16)],[(.211,side*.045,-.022),(.13,side*.124,-.068),(.067,side*.13,-.084),(.083,side*.085,-.064),(.153,side*.050,-.035)],parent='spine_front',rays=22)
        f.fin('Pelvic_'+sn,[f.surface(float(x),side*2.42,-.0012) for x in np.linspace(-.115,-.16,16)],[(-.11,side*.032,-.035),(-.17,side*.081,-.071),(-.229,side*.070,-.072),(-.205,side*.033,-.032)],parent='spine_rear',rays=17)
        x=.292;theta=side*1.03;p=f.surface(x,theta,.0008);f.eye('Eye_'+sn,p,(0,side*.83,.55),radius=.009,iris=(.44,.35,.16))
        pts=[f.surface(.244-.026*math.sin(t),side*(.35+2.10*t/math.pi),.0006) for t in [math.pi*i/24 for i in range(25)]]
        f.gill(sn,pts,width=.0009)
    # Raised five-row armor, with species-like variation in plate size along the body.
    for row,theta,count in [('dorsal',0,15),('left',1.24,30),('right',-1.24,30),('ventral_L',2.39,14),('ventral_R',-2.39,14)]:
        for i in range(count):
            x=-.30+(.535*i/(count-1));shape=.60+.40*math.sin(math.pi*i/(count-1))
            f.scute(row+'_Scute%02d'%i,x,theta,length=(.032 if row=='dorsal' else .021)*shape,width=(.018 if row=='dorsal' else .014)*shape,height=(.0048 if row=='dorsal' else .0024)*shape)
    # Ventral circular/retractile feeding mouth, never a terminal predatory jaw.
    dark=f.mats['dark'];lip=f.mats['lip']
    f.ellipsoid('VentralMouthRecess',(.299,0,-.025),(.021,.015,.0024),dark,'jaw')
    pts=[(.299+.022*math.cos(t),.016*math.sin(t),-.026) for t in [math.tau*i/40 for i in range(41)]]
    f.tube('VentralMouthLip',pts,.0015,lip,'jaw',8)
    # Four discrete barbels in a transverse row between snout tip and mouth.
    for i,y in enumerate((-.025,-.008,.008,.025)):
        x=.359;pts=[(x,y,-.016),(x+.002,y,-.027),(x+.006,y*.97,-.048),(x+.004,y*.96,-.060)]
        f.tube('RostralBarbel_%d'%i,pts,[.0023,.0020,.0011,.00035],lip,'head',9)
    # Small rostral nostrils; no mammalian fangs or external round lip rings.
    for side in (-1,1):f.ellipsoid('Naris_'+str(side),(.326,side*.032,.005),(.003,.0015,.0013),dark,'head')
