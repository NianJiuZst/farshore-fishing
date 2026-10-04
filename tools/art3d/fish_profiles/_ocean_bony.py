"""Original, source-informed ocean anatomy. Shared construction, species-authored shapes.
The helpers attach to each actual loft; no imported mesh or photographic texture.
"""
import math
import numpy as np
from mathutils import Vector


def paint(profile):
    """Deterministic species pigment, in anatomical UV coordinates."""
    sid=profile['id']; art=profile['anatomy']; feature=art.get('pigment','')
    def pigment(u,v,upper,color,height,rough):
        flank=np.sin(v*math.tau)**2
        if art['family']=='tuna':
            # Glossy smooth corselet; subdued microscopic scale normals.
            rough[:]=.32+.08*upper
            if sid=='skipjack_tuna':
                bands=np.maximum(0,np.cos((upper-.12)*math.tau*6.5))**10
                gate=np.clip((.52-upper)/.08,0,1)*np.clip((u-.02)/.08,0,1)*np.clip((.79-u)/.08,0,1)
                color*=1-.72*(bands*gate)[:,:,None]
            elif sid=='yellowfin_tuna':
                gold=np.exp(-((upper-.53)/.045)**2)*np.clip((.86-u)/.12,0,1)
                color=color*(1-gold[:,:,None]*.52)+np.array((.90,.69,.10))*gold[:,:,None]*.52
            elif sid=='pacific_bluefin_tuna':
                pale=np.maximum(0,np.sin(u*math.tau*17))**12*np.clip((.48-upper)/.14,0,1)*np.clip((.78-u)/.08,0,1)
                color=color*(1-pale[:,:,None]*.15)+np.array((.83,.86,.85))*pale[:,:,None]*.15
        if feature=='wahoo_bars':
            bars=np.maximum(0,np.cos(u*math.tau*24+.25*np.sin(v*13)))**5
            gate=flank*np.clip((upper-.25)/.14,0,1)*np.clip((.87-u)/.05,0,1)
            color*=1-.58*(bars*gate)[:,:,None]
        elif feature=='marlin_bars':
            bars=np.maximum(0,np.cos(u*math.tau*17+.15*np.sin(v*14)))**12*flank*np.clip((.84-u)/.12,0,1)
            strength=.27 if sid=='blue_marlin' else .68
            color=color*(1-bars[:,:,None]*strength)+np.array((.10,.64,.81))*bars[:,:,None]*strength
        elif feature=='sailfish_dots':
            bars=np.maximum(0,np.cos(u*math.tau*21))**14
            rows=np.maximum(0,np.cos(v*math.tau*20))**14
            marks=bars*rows*flank*np.clip((.85-u)/.1,0,1)
            color=color*(1-marks[:,:,None]*.9)+np.array((.16,.65,.89))*marks[:,:,None]*.9
        elif feature=='mahi_spots':
            gold=np.exp(-((upper-.48)/.29)**2)
            color=color*(1-gold[:,:,None]*.60)+np.array((.83,.77,.10))*gold[:,:,None]*.60
            speck=np.maximum(0,np.sin(u*577+np.cos(v*89))*np.cos(v*333-u*37)-.79)/.21
            color=color*(1-speck[:,:,None]*.90)+np.array((.02,.19,.34))*speck[:,:,None]*.9
        elif feature in ('cobia_stripe','kingfish_stripe','amberjack_stripe'):
            axis=.51 if feature!='cobia_stripe' else .53
            width=.035 if feature!='cobia_stripe' else .075
            stripe=np.exp(-((upper-axis)/width)**4)*np.clip((.99-u)/.04,0,1)
            target={'cobia_stripe':(.13,.12,.085),'kingfish_stripe':(.84,.67,.17),'amberjack_stripe':(.56,.41,.12)}[feature]
            color=color*(1-stripe[:,:,None]*.82)+np.array(target)*stripe[:,:,None]*.82
            if feature=='amberjack_stripe':
                diagonal=np.exp(-((upper-(.53+(.94-u)*1.35))/.035)**2)*np.clip((u-.76)/.07,0,1)
                color*=1-.58*diagonal[:,:,None]
        elif feature=='barracuda':
            bars=np.maximum(0,np.cos(u*math.tau*17+.48*np.sin(v*22)))**6
            color*=1-.40*(bars*np.clip((upper-.49)/.12,0,1)*np.clip((.73-u)/.05,0,1))[:,:,None]
            blot=np.maximum(0,np.sin(u*101+v*27)*np.cos(v*39)-.76)/.24
            color*=1-.60*(blot*np.clip((.5-upper)/.1,0,1)*np.clip((.72-u)/.05,0,1))[:,:,None]
        elif feature=='rooster_bands':
            bars=(np.exp(-((u-(.39+.14*(upper-.5)))/.033)**2)+np.exp(-((u-(.60+.19*(upper-.5)))/.041)**2))
            color*=1-.78*np.clip(bars*flank,0,1)[:,:,None]
        elif feature=='grouper_mottle':
            blot=(np.sin(u*37+np.cos(v*19))*np.cos(v*43+u*14)+np.sin(u*91-v*71)*.4)
            dark=np.clip((blot+.2)*1.2,0,1)
            color*=1-.54*dark[:,:,None]
            tiny=np.maximum(0,np.sin(u*637+v*29)*np.cos(v*409)-.8)/.2
            color*=1-.38*tiny[:,:,None]
        elif feature=='opah_spots':
            marks=np.zeros_like(u)
            rng=np.random.default_rng(723)
            for _ in range(150):
                x=rng.uniform(.1,.89); y=rng.uniform(0,1); r=rng.uniform(.004,.010)
                marks=np.maximum(marks,np.exp(-2*(((u-x)/r)**2+((v-y)/(r*.62))**2)))
            marks*=flank
            color=color*(1-marks[:,:,None]*.92)+np.array((.93,.88,.81))*marks[:,:,None]*.92
        elif feature=='trevally_freckles':
            dots=np.maximum(0,np.sin(u*421+v*35)*np.cos(v*363-u*39)-.90)/.10
            color*=1-.55*(dots*flank*np.clip((.88-u)/.09,0,1))[:,:,None]
        return color,height,rough
    return pigment


def median(f,name,a,b,edge,sign=1,parent='spine_mid',rays=22,material=None):
    angle=0 if sign>0 else math.pi
    roots=[f.surface(float(x),angle,-.0005) for x in np.linspace(a,b,23)]
    edge=[tuple(roots[0])]+[(x,0,z) for x,z in edge]+[tuple(roots[-1])]
    return f.fin(name,roots,edge,parent=parent,rays=rays,material=material,
                 ray_material=material if material is not None else None)


def paired(f,name,x,length,span,down=.06,theta=1.9,base=.045,parent='spine_front',material=None,sickle=.7,rounded=False):
    for s in (-1,1):
        r0=f.surface(x,s*theta,-.0006);r1=f.surface(x-base,s*(theta+.30),-.0006)
        z=(r0.z+r1.z)*.5
        edge=[r0,(x-length*.40,s*(abs(r0.y)+span*.75),z-down*.45),
              (x-length,s*(abs(r0.y)+span),z-down),
              (x-length*sickle,s*(abs(r0.y)+span*.42),z-down*.72),r1]
        if rounded:
            edge=[r0,(x-length*.44,s*(abs(r0.y)+span*.78),z+down*.18),(x-length*.84,s*(abs(r0.y)+span),z-down*.35),(x-length,s*(abs(r0.y)+span*.87),z-down*.77),(x-length*.81,s*(abs(r0.y)+span*.58),z-down*1.04),r1]
        f.fin(name+('L' if s>0 else 'R'),[f.surface(float(t),s*(theta+.30*(x-t)/base),-.0006) for t in np.linspace(x,x-base,10)],edge,parent=parent,rays=18,material=material,ray_material=material)


def tail(f,height=.16,kind='lunate',color=None):
    x=f.sections[0][0]+.0007
    roots=[f.surface(x,math.pi,-.0005),f.surface(x,math.pi/2,-.0005),f.surface(x,0,-.0005)]
    roots=[(p.x,0,p.z) for p in roots]
    if kind=='rounded':
        edge=[(x-.022,-height*.62),(x-.092,-height),(x-.145,-height*.70),(x-.165,0),(x-.145,height*.70),(x-.092,height),(x-.022,height*.62)]
    elif kind=='truncate':
        edge=[(x-.025,-height*.55),(x-.138,-height),(x-.150,-height*.60),(x-.141,0),(x-.150,height*.60),(x-.138,height),(x-.025,height*.55)]
    elif kind=='forked':
        edge=[(x-.018,-height*.30),(x-.150,-height),(x-.138,-height*.51),(x-.066,0),(x-.138,height*.51),(x-.150,height),(x-.018,height*.30)]
    else:
        edge=[(x-.015,-height*.25),(x-.124,-height),(x-.087,-height*.51),(x-.047,0),(x-.087,height*.51),(x-.124,height),(x-.015,height*.25)]
    material=f.material('CaudalPigment',color,.43) if color else None
    f.fin('Caudal',roots,[(a,0,b) for a,b in edge],bone='caudal',parent='tail',rays=31,material=material,ray_material=material)


def face(f,eye_x=.414,eye_r=.012,gill_x=.275,mouth_end=.389,iris=(.47,.46,.32),mouth_width=.0016):
    for s in (-1,1):
        tag='L' if s>0 else 'R'
        f.eye('Eye'+tag,f.surface(eye_x,s*1.16,.0006),(0,s*.94,.34),eye_r,iris)
        f.gill('Operculum'+tag,[f.surface(float(gill_x+.024*((t-1.42)/1.10)**2),s*t,.0005) for t in np.linspace(.35,2.72,34)],.0012)
        start=f.sections[-1][0]-.010
        line=[f.surface(float(x),s*(1.61+(start-x)*3.7),.00065) for x in np.linspace(start,mouth_end,30)]
        f.tube('MouthCleft'+tag,line,mouth_width,f.mats['dark'],'head',8)
        f.tube('LowerLip'+tag,[(p.x,p.y,p.z-.0020) for p in line],mouth_width*.80,f.mats['lip'],'jaw',8)
        f.ellipsoid('Nostril'+tag,f.surface(eye_x+.039,s*.99,.0006),(.0023,.0014,.0012),f.mats['dark'])


def keel(f,central=True,minor=True):
    mat=f.material('CaudalKeel',f.profile['skin']['side'],.39)
    for s in (-1,1):
        if central:
            # A broad horizontal triangular foil, not a strand along the side.
            x=-.339;p=f.surface(x,s*math.pi/2,.0002)
            vertices=[(-.291,p.y,p.z),(-.346,s*(abs(p.y)+.029),p.z),(-.398,s*.011,p.z),(-.349,p.y,p.z+.004),(-.349,p.y,p.z-.004)]
            f.mesh('CentralPeduncleKeel'+str(s),vertices,[(0,1,3),(1,2,3),(2,0,3),(0,4,1),(1,4,2),(2,4,0)],mat,weight='spine')
        for angle in ((1.05,2.1) if minor else ()):
            pts=[f.surface(float(x),s*angle,.0005) for x in np.linspace(-.33,-.395,12)]
            f.tube('MinorKeel'+str(s)+str(angle),pts,[.0006+.0013*math.sin(i/11*math.pi) for i in range(12)],mat,'spine',6)


def finlets(f,count=8,bright=True):
    mat=f.material('FinletGold',(.78,.65,.15) if bright else (.30,.34,.31),.44)
    for i,x in enumerate(np.linspace(-.172,-.374,count)):
        x=float(x)
        for sign,name in ((1,'DorsalFinlet'),(-1,'AnalFinlet')):
            th=0 if sign>0 else math.pi;r=f.surface(x,th,-.0005)
            median(f,name+str(i+1),x,x-.017,[(x-.010,r.z+sign*(.022-i*.0012))],sign,'spine_rear' if x>-.30 else 'tail',6,mat)


def tuna(f):
    a=f.profile['anatomy']; dorsal=a.get('dorsal_height',.185);second=a.get('second_height',.15)
    if f.species=='dogtooth_tuna':
        median(f,'LongFirstDorsal',.242,-.019,[(.205,dorsal),(.123,.119),(.041,.086)],parent='spine_front',rays=19)
    else:median(f,'FirstDorsal',.22,.018,[(.195,dorsal),(.145,dorsal*.84),(.066,.105)],parent='spine_front',rays=16)
    gold=f.material('SecondDorsalAnalPigment',a.get('second_color',(.50,.48,.26)),.43)
    sweep=a.get('sickle_sweep')
    de=[(-.056,second*.54),(-.111,second*.82),(sweep,second),(-.168,second*.70),(-.118,second*.35)] if sweep else [(-.064,second),(-.101,second*.77)]
    ae=[(-.073,-second*.45),(-.126,-second*.71),(sweep-.010,-second*.88),(-.181,-second*.61),(-.131,-second*.30)] if sweep else [(-.078,-second*.87),(-.116,-second*.65)]
    median(f,'SecondDorsal',-.033,-.126,de,parent='spine_mid',rays=48 if sweep else 18,material=gold)
    median(f,'Anal',-.045,-.139,ae,-1,'spine_mid',48 if sweep else 18,gold)
    paired(f,'Pectoral',.274,a['pectoral_length'],a.get('pectoral_span',.077),a.get('pectoral_down',.038),1.64,.047,material=f.material('PectoralPigment',a.get('pectoral_color',(.20,.24,.29)),.45),sickle=.59)
    paired(f,'Pelvic',.172,.105,.040,.065,2.55,.035)
    finlets(f,a.get('finlets',8),a.get('bright_finlets',True));tail(f,a.get('tail_height',.175),'lunate',a.get('tail_color',(.17,.21,.26)));keel(f)
    face(f,a.get('eye_x',.404),a.get('eye_radius',.012),a.get('gill_x',.283),a.get('mouth_end',.380))
    pale=f.material('PaleSpeciesMarkings',(.83,.86,.80),.46)
    if f.species=='albacore':
        x=f.sections[0][0]+.0007;h=a.get('tail_height',.175)
        edge=[(x-.124,0,-h),(x-.087,0,-h*.51),(x-.047,0,0),(x-.087,0,h*.51),(x-.124,0,h)]
        f.tube('WhiteCaudalTrailingMargin',edge,.0017,pale,'caudal',6)
    if f.species=='dogtooth_tuna':
        for sign,bone in ((1,'seconddorsal'),(-1,'anal')):
            z=second if sign>0 else -second*.87
            f.tube('WhiteSoftFinTip'+str(sign),[(-.061,0,z-.006*sign),(-.068,0,z),(-.087,0,z-.009*sign)],.0027,pale,bone,7)
        for s in (-1,1):
            line=[f.surface(float(x),s*(1.48-.20*math.sin((x+.38)*5.4)),.00065) for x in np.linspace(-.37,.24,65)]
            f.tube('WavyLateralLine'+str(s),line,.0009,f.mats['edge'],'spine',6)
            for i,x in enumerate(np.linspace(.335,.507,17)):
                p=f.surface(float(x),s*(1.66+(.507-x)*3.6),.0010)
                f.tube('DogTooth'+str(s)+'_'+str(i),[p,(p.x+.001,p.y,p.z-.010)],[.0020,.00015],f.mats['tooth'],'head',7)


def billfish(f):
    a=f.profile['anatomy'];sid=f.species
    if sid=='indo_pacific_sailfish':
        median(f,'SpectacularSail',.302,-.227,[(.276,.258),(.217,.350),(.139,.385),(.027,.365),(-.090,.318),(-.184,.220)],rays=47)
    elif sid=='swordfish':
        median(f,'SickleFirstDorsal',.204,.044,[(.177,.224),(.111,.246),(.108,.164),(.071,.077)],parent='spine_front',rays=23)
    else:
        peak=.264 if sid=='striped_marlin' else .218
        median(f,'LongFirstDorsal',.247,-.219,[(.205,peak),(.143,peak*.88),(.075,.133),(-.068,.084),(-.188,.062)],rays=38)
    median(f,'SecondDorsal',-.259,-.335,[(-.279,.077),(-.331,.054)],parent='tail',rays=11)
    median(f,'FirstAnal',-.073,-.161,[(-.100,-.126),(-.174,-.152),(-.133,-.065)],-1,'spine_rear',18)
    median(f,'SecondAnal',-.265,-.336,[(-.292,-.066),(-.333,-.052)],-1,'tail',11)
    paired(f,'Pectoral',.223,a.get('pectoral_length',.204),.121,.066,1.83,.036,sickle=.76)
    if sid!='swordfish':paired(f,'ThreadlikePelvic',.211,.31,.011,.018,2.77,.012,sickle=.93)
    tail(f,.175,'lunate',(.10,.17,.25));keel(f,central=sid=='swordfish',minor=sid!='swordfish')
    face(f,.338,a.get('eye_radius',.0105),.222,.326,iris=(.42,.44,.31))
    # Swordfish is a flattened broad blade; istiophorids have a nearly circular spear.
    sections=[(.380,.022,.013),(.433,.021,.012),(.535,.015,.009),(.660,.008,.005),(a['bill_tip'],.0007,.0007)]
    if sid=='swordfish':sections=[(.376,.030,.010),(.440,.028,.008),(.565,.022,.005),(.740,.012,.003),(a['bill_tip'],.0007,.0006)]
    verts=[];faces=[];uv=[];n=20
    for i,(x,w,h) in enumerate(sections):
        for j in range(n):
            t=j*math.tau/n;verts.append((x,w*math.sin(t),.004+h*math.cos(t)));uv.append((i/(len(sections)-1),j/n))
    for i in range(len(sections)-1):
        for j in range(n):k=i*n+j;faces.append((k,i*n+(j+1)%n,(i+1)*n+(j+1)%n,k+n))
    faces.extend([tuple(reversed(range(n))),tuple((len(sections)-1)*n+j for j in range(n))])
    f.mesh('BroadSword' if sid=='swordfish' else 'RoundSpearBill',verts,faces,f.material('RostrumPigment',(.21,.26,.29),.39),uv,'head')


def pelagic(f):
    a=f.profile['anatomy'];family=a['family'];sid=f.species
    if family=='mahi':
        median(f,'ContinuousCrestDorsal',.387,-.351,[(.374,.187),(.307,.226),(.172,.224),(-.032,.177),(-.230,.113),(-.336,.066)],rays=51)
        median(f,'LongAnal',-.035,-.337,[(-.066,-.118),(-.185,-.103),(-.313,-.058)],-1,'spine_rear',35)
        paired(f,'Pectoral',.263,.181,.075,.027,1.85,.04);paired(f,'Pelvic',.244,.160,.046,.101,2.68,.04)
        tail(f,.173,'forked',(.23,.41,.23));face(f,.415,.012,.282,.374,iris=(.65,.55,.16))
    elif family in ('wahoo','barracuda'):
        if family=='wahoo':
            median(f,'LongSpinyFirstDorsal',.196,-.143,[(.168,.129),(.054,.089),(-.107,.052)],rays=29)
            median(f,'SecondDorsal',-.204,-.278,[(-.225,.090),(-.256,.068)],parent='spine_rear',rays=14)
            median(f,'Anal',-.214,-.287,[(-.244,-.084),(-.274,-.063)],-1,'spine_rear',14)
            for i,x in enumerate(np.linspace(-.295,-.378,7)):
                for s in (-1,1):
                    z=f.surface(float(x),0 if s>0 else math.pi).z
                    median(f,('Dorsal' if s>0 else 'Anal')+'Finlet'+str(i),float(x),float(x)-.008,[(float(x)-.005,z+s*.013)],s,'tail',5)
            keel(f);tail(f,.122,'lunate',(.17,.25,.32))
        else:
            median(f,'SeparatedFirstDorsal',.063,-.045,[(.039,.145),(-.002,.131)],parent='spine_mid',rays=12)
            median(f,'PosteriorDorsal',-.229,-.325,[(-.252,.111),(-.308,.091)],parent='spine_rear',rays=14)
            median(f,'PosteriorAnal',-.230,-.325,[(-.256,-.102),(-.310,-.081)],-1,'spine_rear',14)
            tail(f,.118,'forked',(.22,.27,.24))
        paired(f,'Pectoral',.244,.112,.051,.029,1.8,.025)
        paired(f,'Pelvic',.075,.089,.035,.067,2.68,.032)
        face(f,.370,.0107,.219,.301,iris=(.61,.56,.22),mouth_width=.0020)
        if family=='barracuda':
            for s in (-1,1):
                for i,x in enumerate(np.linspace(.326,.478,13)):
                    p=f.surface(float(x),s*1.85,.001)
                    f.tube('ConicalFang'+str(s)+'_'+str(i),[p,(p.x+.001,p.y,p.z-.010*(1+.3*(i%3)))],[.0019,.0002],f.mats['tooth'],'head',6)
    elif family=='cobia':
        # Cobia has isolated anterior dorsal spines, no continuous first dorsal sail.
        for i,x in enumerate(np.linspace(.178,.021,7)):
            r=f.surface(float(x),0)
            f.tube('IsolatedDorsalSpine'+str(i),[r,(x-.015,0,r.z+.026-i*.001)], [.0018,.0002],f.mats['edge'],'spine',6)
        median(f,'LongSoftDorsal',-.019,-.343,[(-.051,.120),(-.137,.100),(-.282,.064)],rays=31)
        median(f,'LongAnal',-.045,-.338,[(-.080,-.103),(-.212,-.077),(-.309,-.051)],-1,'spine_rear',27)
        paired(f,'BroadPectoral',.232,.169,.116,.016,1.74,.055,sickle=.71)
        paired(f,'Pelvic',.194,.093,.049,.068,2.6,.037)
        tail(f,.128,'lunate',(.22,.23,.19));face(f,.400,.010,.240,.351,iris=(.45,.39,.20))
    else:
        # Jacks retain separately authored deep/long bodies, forehead and fin ratios.
        h=a.get('dorsal_height',.19)
        median(f,'SpinyFirstDorsal',.184,.033,[(.155,h),(.092,h*.76)],parent='spine_front',rays=10)
        median(f,'LongSecondDorsal',.014,-.320,[(-.034,h*1.16),(-.077,h*.72),(-.242,.074)],rays=31)
        median(f,'LongAnal',-.068,-.324,[(-.099,-h*.83),(-.162,-h*.56),(-.288,-.047)],-1,'spine_rear',27)
        paired(f,'SicklePectoral',.269,a.get('pectoral_length',.226),a.get('pectoral_span',.091),.054,1.75,.047,sickle=.52)
        paired(f,'Pelvic',.179,.112,.043,.075,2.61,.041)
        tail(f,a.get('tail_height',.16),'forked',a.get('tail_color',(.45,.43,.24)))
        face(f,a.get('eye_x',.400),a.get('eye_radius',.0115),.273,a.get('mouth_end',.375),iris=(.62,.55,.24))
        if family=='rooster':
            # Seven towering, filament-tipped rays make the characteristic rooster comb.
            for i,(x,height) in enumerate(zip(np.linspace(.236,.086,7),(.242,.345,.395,.383,.344,.289,.237))):
                r=f.surface(float(x),0,-.0004)
                name='RoosterComb'+str(i+1);mat=f.material('RoosterCombPigment',(.12,.19,.22),.47)
                # Only a low basal web: the seven upper elements are tapered flexible filaments.
                median(f,name,float(x),float(x)-.013,[(float(x)-.013,r.z+.052),(float(x)-.027,r.z+.071)],parent='spine_front',rays=10,material=mat)
                points=[];radii=[]
                for j,t in enumerate(np.linspace(0,1,20)):
                    points.append((float(x)-.065*t*t-.006*t,0,r.z+(height-r.z)*t))
                    radii.append(float(.0027*(1-t)**.74+.00013))
                f.tube(name+'TaperedStreamer',points,radii,mat,('fin',name.lower()),8)
        if sid=='giant_trevally':
            scute=f.material('PeduncleScutes',(.45,.49,.45),.51)
            for s in (-1,1):
                for i,x in enumerate(np.linspace(-.165,-.374,22)):
                    r=f.surface(float(x),s*math.pi/2,.0003)
                    f.mesh('LateralScute'+str(s)+'_'+str(i),[(x+.005,r.y,r.z+.005),(x-.005,r.y,r.z),(x+.005,r.y,r.z-.005),(x,r.y+s*.003,r.z)],[(0,1,3),(1,2,3),(2,0,3)],scute,weight='spine')


def reef(f):
    a=f.profile['anatomy'];sid=f.species
    if sid=='giant_grouper':
        median(f,'SpinyDorsal',.258,.005,[(.232,.169),(.176,.170),(.100,.159),(.034,.147)],rays=12)
        median(f,'RoundedSoftDorsal',.011,-.281,[(-.033,.184),(-.135,.186),(-.239,.139)],rays=22)
        median(f,'RoundedAnal',-.101,-.274,[(-.138,-.141),(-.214,-.145),(-.259,-.096)],-1,'spine_rear',17)
        paired(f,'BroadRoundedPectoral',.265,.184,.115,.085,1.86,.059,sickle=.70,rounded=True)
        paired(f,'Pelvic',.192,.147,.067,.096,2.55,.057)
        tail(f,.132,'rounded',(.34,.32,.23));face(f,.384,.011,.275,.302,iris=(.46,.40,.21),mouth_width=.0034)
        # Thick superior lip and prognathous lower jaw; asymmetric cheek ridge.
        for s in (-1,1):
            pts=[f.surface(float(x),s*(1.62+(.49-x)*3.4),.0018) for x in np.linspace(.485,.315,33)]
            f.tube('HeavyMaxillaryLip'+str(s),pts,.0040,f.mats['lip'],'head',10)
            f.tube('PreopercularRidge'+str(s),[f.surface(.315+.016*math.cos(t),s*t,.0015) for t in np.linspace(.65,2.4,23)],.0020,f.mats['edge'],'head',7)
    else:
        median(f,'SpinyDorsal',.244,-.018,[(.224,.179),(.197,.190),(.166,.190),(.129,.183),(.093,.172),(.054,.161),(.016,.151)],rays=27)
        for i,(x,z) in enumerate(zip(np.linspace(.222,.017,9),(.181,.189,.193,.191,.185,.179,.171,.162,.153))):
            r=f.surface(float(x),0,-.0005)
            f.tube('DorsalSpine'+str(i+1),[r,(float(x)-.006,0,z)], [.0015,.00016],f.mats['edge'],('fin','spinydorsal'),6)
        median(f,'SoftDorsal',-.013,-.267,[(-.050,.176),(-.114,.183),(-.201,.160),(-.237,.124)],rays=23)
        median(f,'Anal',-.083,-.268,[(-.127,-.163),(-.214,-.145)],-1,'spine_rear',17)
        paired(f,'LongPectoral',.272,.230,.093,.077,1.83,.051,sickle=.48)
        paired(f,'Pelvic',.194,.136,.046,.105,2.61,.046)
        tail(f,.137,'forked',(.66,.20,.20));face(f,.400,.014,.274,.357,iris=(.70,.22,.12),mouth_width=.0021)
        for s in (-1,1):
            p=f.surface(.454,s*1.76,.002)
            f.tube('Canine'+str(s),[p,(p.x,p.y,p.z-.010)],[.0023,.0002],f.mats['tooth'],'head',7)


def opah(f):
    red=f.material('VermilionFins',(.80,.23,.16),.42)
    median(f,'HighCurvedDorsal',.190,-.305,[(.166,.346),(.09,.370),(.015,.329),(-.055,.269),(-.138,.208),(-.213,.151),(-.280,.097)],rays=45,material=red)
    median(f,'LongCurvedAnal',-.001,-.302,[(-.042,-.264),(-.167,-.198),(-.259,-.100)],-1,'spine_rear',32,red)
    paired(f,'WingPectoral',.255,.254,.221,.029,1.62,.070,material=red,sickle=.76)
    paired(f,'Pelvic',.175,.192,.074,.168,2.58,.051,material=red,sickle=.84)
    tail(f,.132,'forked',(.80,.23,.16));face(f,.387,.022,.250,.373,iris=(.76,.28,.15),mouth_width=.0024)


def anatomy(f):
    family=f.profile['anatomy']['family']
    if family=='tuna':tuna(f)
    elif family=='billfish':billfish(f)
    elif family=='reef':reef(f)
    elif family=='opah':opah(f)
    else:pelagic(f)
