"""Left-eyed adult olive flounder. Ocular side is +Z in Blender, not mirrored eyes."""
import math
import numpy as np
from mathutils import Vector
PROFILE={
'id':'olive_flounder','flatfish':True,'mirror_y':True,'ocular_side':'left','bend_axis':'vertical','swim_amplitude':.65,
'sections':[(-.34,.026,.008,.006,0),(-.275,.070,.014,.010,0),(-.16,.147,.022,.013,.001),(-.02,.186,.027,.016,.001),(.12,.181,.030,.017,.002),(.235,.143,.029,.016,.003),(.32,.10,.025,.014,.002),(.395,.057,.018,.011,0),(.447,.022,.010,.008,-.001),(.468,.009,.004,.004,-.001)],
'skin':{'back':(.255,.255,.145),'side':(.35,.335,.205),'belly':(.79,.78,.66),'pattern':'flatfish','variation':.13,'mottle_amount':.53,'spot_color':(.15,.17,.09),'spot_count':145,'spot_radius':(.002,.006)},
'fin_color':(.40,.37,.225),'fin_pattern':'spots','roughness':.67,'specular':.16,'coat':.015,'normal_strength':.16,'head_start':.86,'head_end':.96,
'morphology':['Adult left-eyed flatfish, both eyes on pigmented upper ocular side','Volumetric flattened asymmetric head and white blind underside','Long continuous dorsal and anal margins, dorsal beginning beside head','Large oblique mouth, nonforked caudal fin','Olive marbling and small dark spots rather than orange plaice spots'],
'sources':['https://www.fishbase.se/summary/Paralichthys-olivaceus.html','https://swfsc-publications.fisheries.noaa.gov/publications/CR/2025/2025Purcell2.pdf']}

def anatomy(f):
    # Dorsal corresponds to the fish's anatomical upper edge after lying on its blind side.
    # Split into contiguous rig segments so long margins ripple instead of rigid hinge flapping.
    for side,label in [(1,'Dorsal'),(-1,'Anal')]:
        limits=[(.405,.19),(.19,-.06),(-.06,-.31)] if side==1 else [(.315,.10),(.10,-.12),(-.12,-.31)]
        for index,(a,b) in enumerate(limits):
            roots=[];edge=[]
            for j in range(10):
                x=a+(b-a)*j/9;p=f.surface(x,side*math.pi/2,-.001);roots.append(p)
                extent=.014+.036*max(0,1-(x/.45)**2)
                edge.append((x-.01,p.y+side*extent,.002+math.sin(j/9*math.pi)*.002))
            f.fin(label+'_%d'%index,roots,edge,parent='spine_front' if index==0 else ('spine_mid' if index==1 else 'spine_rear'),rays=20)
    f.fin('Caudal',[(-.338,.022,0),(-.338,0,0),(-.338,-.022,0)],[(-.444,.074,.001),(-.486,.077,0),(-.502,.045,0),(-.506,0,0),(-.496,-.045,0),(-.475,-.075,0),(-.432,-.070,0)],bone='caudal',parent='tail',rays=27)
    # Upper visible pectoral and a smaller blind-side fin, not two identical raised shoulders.
    f.fin('Pectoral_ocular',[f.surface(x,math.asin(y/f.surface(x,math.pi/2).y),-.0008) for x,y in [(.218,-.013),(.184,-.030)]],[(.216,-.012,.031),(.167,-.001,.056),(.107,-.024,.052),(.132,-.055,.032),(.182,-.034,.028)],parent='spine_front',rays=17)
    f.fin('Pectoral_blind',[f.surface(x,math.pi-math.asin(y/f.surface(x,math.pi/2).y),-.0008) for x,y in [(.217,.004),(.179,.018)]],[(.216,.004,-.017),(.145,.028,-.025),(.122,.058,-.024),(.183,.027,-.016)],parent='spine_front',rays=13)
    # Both eye sockets on upper surface; different X/Y positions preserve adult asymmetry.
    f.eye('MigratedEye',(.352,.043,.018),(0,.12,.993),radius=.011,iris=(.52,.405,.17))
    f.eye('LowerOcularEye',(.322,-.004,.026),(0,-.10,.995),radius=.012,iris=(.52,.405,.17))
    # Top-surface cheek crescent behind the eye pair.
    pts=[(.257-.028*math.sin(t),-.021+.070*math.cos(t),.027-.004*math.cos(t)) for t in [math.pi*i/28 for i in range(29)]]
    f.gill('ocular',pts,width=.0011)
    pts2=[(.267-.016*math.sin(t),.013+.057*math.cos(t),-.017) for t in [math.pi*i/20 for i in range(21)]]
    f.gill('blind',pts2,width=.00065)
    # Oblique large terminal mouth and a sculpted lower jaw slab, genuinely asymmetric in plan.
    sections=np.array([(.377,-.026,.013,.005,-.003),(.399,-.028,.022,.009,-.004),(.425,-.024,.023,.010,-.005),(.450,-.014,.018,.007,-.004),(.466,-.001,.005,.003,-.001)])
    verts=[];faces=[];uv=[];N,M=28,30
    for i,x in enumerate(np.linspace(.377,.466,M+1)):
        cy,wy,h,cz=[np.interp(x,sections[:,0],sections[:,k]) for k in range(1,5)]
        for j in range(N+1):
            t=math.tau*j/N;verts.append((x,cy+wy*math.sin(t),cz+h*math.cos(t)));uv.append(((x+.34)/(.468+.34),j/N))
    for i in range(M):
        for j in range(N):a=i*(N+1)+j;faces.append((a,a+1,a+N+2,a+N+1))
    faces.extend((tuple(reversed(range(N+1))),tuple(M*(N+1)+j for j in range(N+1))))
    f.mesh('OrganicAsymmetricLowerJaw',verts,faces,f.mats['skin'],uv,weight='jaw')
    f.tube('ObliqueMouthSeam',[(.469,.009,.002),(.446,-.023,.008),(.419,-.046,.008),(.387,-.057,.010)],.00165,f.mats['dark'],'head',8)
    f.tube('SubtleLowerLip',[(.465,.007,-.003),(.439,-.028,-.004),(.416,-.049,-.006),(.387,-.060,-.007)],.0008,f.mats['edge'],'jaw',7)
