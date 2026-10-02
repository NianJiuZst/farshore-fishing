"""Mullus barbatus: original red mullet with abrupt forehead and paired sensory chin barbels."""
import math
import numpy as np
from mathutils import Vector
from fish_profiles.japanese_whiting import paired,median,caudal,eyes,gills,mouth
PROFILE={'id':'red_mullet','sections':[(-.356,.017,.030,.024,0),(-.273,.027,.048,.036,0),(-.146,.043,.077,.049,.006),(-.012,.056,.098,.059,.005),(.123,.062,.115,.063,.006),(.253,.063,.116,.067,.005),(.347,.056,.101,.060,.004),(.415,.043,.085,.048,.001),(.468,.027,.063,.028,-.006),(.488,.016,.015,.013,-.034)],'skin':{'back':(.67,.41,.37),'side':(.85,.65,.59),'belly':(.90,.85,.75),'pattern':'scales','scale_columns':37,'scale_rows':23,'variation':.035,'lateral_line':(.69,.44,.39),'lateral_curve':.17,'lateral_arch':.10},'fin_color':(.80,.67,.55),'roughness':.43,'normal_strength':.24,'head_start':.75,'head_end':.88,'morphology':['Elongated relatively flat-bellied body and abrupt blunt forehead above small low mouth','Exactly two white sensory chin barbels, no longer than pectoral fins','Two clearly separated dorsals, unstriped pale first dorsal and unstriped forked caudal','Large easily shed-looking scales, pink-silver sides; no opercular spine'],'sources':['https://doris.ffessm.fr/Especes/Mullus-barbatus-Rouget-de-vase-579','https://www.fao.org/4/x0170f/x0170f55.pdf']}
def anatomy(f):
    median(f,'DorsalFirst',.203,.035,[(.203,0,.116),(.168,0,.236),(.121,0,.212),(.035,0,.096)],'spine_front',18)
    median(f,'DorsalSecond',-.102,-.278,[(-.102,0,.086),(-.143,0,.146),(-.240,0,.101),(-.279,0,.042)],'spine_rear',20)
    median(f,'Anal',-.128,-.262,[(-.128,0,-.045),(-.155,0,-.108),(-.232,0,-.084),(-.263,0,-.031)],'spine_rear',18,upper=False)
    caudal(f,[(-.397,.057),(-.509,.134),(-.488,.059),(-.424,0),(-.491,-.061),(-.509,-.126),(-.397,-.051)],27)
    paired(f,'Pectoral',.283,.237,1.93,.053,.137,-.035,rays=20)
    paired(f,'Pelvic',.196,.152,2.58,.033,.079,-.043,rays=14)
    eyes(f,.395,1.09,.0193,(.74,.47,.20));gills(f,.296,.034,.0011);mouth(f,.491,.016,-.034,.0042,.0018)
    white=f.material('IvoryChinBarbels',(.86,.84,.69),.51)
    for sign,tag in ((-1,'R'),(1,'L')):
        root=f.surface(.445,sign*2.84,-.0012);pts=[]
        for t in np.linspace(0,1,23):pts.append(root+Vector((-.108*t,sign*.021*t,-.079*math.sin(t*math.pi*.6))))
        ob=f.tube('SensoryChinBarbel'+tag,pts,np.linspace(.0018,.00020,len(pts)).tolist(),white,('fin','jaw'),8)
        # Persistent tags extend the same deformation contact gate to each barbel root.
        aid=len(f.attachment_groups)+1;f.attachment_groups[aid]={'name':'ChinBarbel_'+tag,'bone':'jaw'}
        marker=ob.data.attributes.new('fs_attachment','INT','POINT');kind=ob.data.attributes.new('fs_attachment_kind','INT','POINT')
        for i in range(8):marker.data[i].value=aid;kind.data[i].value=2
