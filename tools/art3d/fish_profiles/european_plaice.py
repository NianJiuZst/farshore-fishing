"""Right-eyed European plaice: deep oval outline, small mouth, orange spots, six head knobs."""
import math
PROFILE={
'id':'european_plaice','flatfish':True,'ocular_side':'right','bend_axis':'vertical','swim_amplitude':.62,
'sections':[(-.345,.024,.008,.006,0),(-.27,.084,.017,.010,0),(-.15,.178,.026,.013,.001),(-.01,.223,.033,.017,.002),(.125,.215,.035,.019,.002),(.235,.166,.033,.017,.002),(.323,.105,.027,.014,.002),(.397,.049,.017,.009,.001),(.438,.018,.010,.006,0),(.458,.006,.003,.003,0)],
'skin':{'back':(.275,.225,.135),'side':(.35,.29,.185),'belly':(.83,.815,.73),'pattern':'flatfish','variation':.10,'mottle_amount':.26,'spot_color':(.63,.255,.050),'spot_count':47,'spot_radius':(.006,.014)},
'fin_color':(.44,.36,.225),'roughness':.67,'specular':.16,'coat':.015,'normal_strength':.16,'head_start':.84,'head_end':.96,
'morphology':['Adult right-eyed flatfish: both eyes on upper right ocular side, dorsal margin +Y','Deep oval body broader than olive flounder, with white eyeless underside','Bright orange-red spots across brown upper side','Small terminal mouth, six low bony knobs from eye region toward gill opening','Continuous long dorsal/anal margins, rounded caudal fin'],
'sources':['https://www.marlin.ac.uk/species/detail/2172','https://biotic.marlin.ac.uk/data/species/6202','https://fish-commercial-names.ec.europa.eu/fish-names/species/pleuronectes-platessa_en']}

def anatomy(f):
    for side,label in [(1,'Dorsal'),(-1,'Anal')]:
        limits=[(.395,.15),(.15,-.09),(-.09,-.312)] if side==1 else [(.315,.09),(.09,-.12),(-.12,-.31)]
        for index,(a,b) in enumerate(limits):
            roots=[];edges=[]
            for j in range(11):
                x=a+(b-a)*j/10;p=f.surface(x,side*math.pi/2,-.001);roots.append(p)
                extent=.012+.032*max(0,1-(x/.43)**2);edges.append((x-.008,p.y+side*extent,.002))
            f.fin(label+'_%d'%index,roots,edges,parent='spine_front' if index==0 else ('spine_mid' if index==1 else 'spine_rear'),rays=21)
    f.fin('Caudal',[(-.343,.020,0),(-.343,0,0),(-.343,-.020,0)],[(-.445,.077,0),(-.485,.074,0),(-.507,.038,0),(-.511,-.008,0),(-.491,-.056,0),(-.458,-.077,0),(-.425,-.064,0)],bone='caudal',parent='tail',rays=28)
    f.fin('Pectoral_ocular',[f.surface(x,math.asin(y/f.surface(x,math.pi/2).y),-.0008) for x,y in [(.220,-.012),(.183,-.031)]],[(.219,-.012,.034),(.163,.011,.056),(.104,-.009,.054),(.126,-.049,.035),(.181,-.035,.031)],parent='spine_front',rays=18)
    f.fin('Pectoral_blind',[f.surface(x,math.pi-math.asin(y/f.surface(x,math.pi/2).y),-.0008) for x,y in [(.221,.009),(.181,.029)]],[(.218,.01,-.019),(.162,.057,-.031),(.12,.053,-.025),(.181,.030,-.018)],parent='spine_front',rays=14)
    f.eye('MigratedEye',(.337,.042,.024),(0,.12,.993),radius=.0103,iris=(.47,.34,.12))
    f.eye('LowerOcularEye',(.309,-.006,.029),(0,-.10,.995),radius=.0110,iris=(.47,.34,.12))
    pts=[(.249-.028*math.sin(t),-.014+.074*math.cos(t),.029-.004*math.cos(t)) for t in [math.pi*i/30 for i in range(31)]]
    f.gill('ocular',pts,width=.0010)
    pts=[(.257-.017*math.sin(t),.019+.060*math.cos(t),-.018) for t in [math.pi*i/22 for i in range(23)]]
    f.gill('blind',pts,width=.00065)
    ridge=f.material('HeadBoneRidge',(.37,.315,.21),.65)
    for i in range(6):
        x=.303-i*.0106;y=.014+i*.0042;z=.032+i*.0002
        f.ellipsoid('BonyHeadKnob_%d'%i,(x,y,z),(.006,.0034,.0025),ridge,'head')
    # Plaice's mouth is smaller than the large oblique olive-flounder mouth.
    lip=f.material('PlaiceLip',(.33,.29,.19),.62)
    f.tube('SmallTerminalMouth',[(.458,.007,.001),(.449,-.011,.005),(.435,-.026,.004),(.421,-.03,.005)],.0012,f.mats['dark'],'head',8)
    f.tube('SmallLowerJaw',[(.456,.005,-.003),(.447,-.012,-.005),(.432,-.024,-.006),(.420,-.028,-.004)],.0014,lip,'jaw',8)
