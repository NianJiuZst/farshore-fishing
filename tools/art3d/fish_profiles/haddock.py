"""Original Melanogrammus aeglefinus: high first dorsal, thumbprint and short barbel."""
import math
import numpy as np

def haddock_skin(u,v,upper,color,height,rough):
 mask=np.zeros_like(u)
 for side in (.25,.75):
  # Characteristic shoulder mark above each pectoral, blended into real skin UVs.
  d=((u-.708)/.031)**2+((v-(side+(.020 if side>.5 else -.020)))/.049)**2
  mask=np.maximum(mask,np.clip((1.0-d)*4,0,1))
 color=color*(1-mask[:,:,None]*.88)
 return color,height,rough
PROFILE={
 'id':'haddock',
 'sections':[(-.389,.013,.025,.021,0),(-.318,.019,.037,.029,0),(-.226,.029,.057,.040,.001),(-.084,.043,.084,.056,.003),(.063,.054,.109,.070,.005),(.190,.059,.118,.073,.005),(.285,.052,.102,.058,.004),(.365,.040,.067,.038,.002),(.433,.028,.036,.022,0),(.472,.015,.022,.014,-.005),(.491,.003,.008,.006,-.007)],
 'skin':{'back':(.25,.28,.34),'side':(.60,.64,.66),'belly':(.81,.82,.75),'pattern':'fine_scales','scale_columns':94,'scale_rows':41,'variation':.025},
 'custom_skin':haddock_skin,'fin_color':(.36,.40,.43),'normal_strength':.10,'roughness':.42,'swim_amplitude':.81,
 'morphology':['Deep shoulder tapering to slender tail with a short rounded snout and small mouth','Very high triangular first dorsal with concave trailing margin, plus two lower dorsals','Dark uninterrupted lateral line and bilateral black shoulder thumbprint','Short chin barbel, two separate anal fins and moderately forked tail'],
 'sources':['https://www.marlin.ac.uk/species/detail/79','https://www.fisheries.noaa.gov/species/haddock']}

def _attach(f,name,roots,edge,**kwargs):
 """Seat fin roots on this species' actual body, including a closed tail-cap overlap."""
 if 'caudal' in name.lower():
  x=f.sections[0][0]+.0007;top=f.surface(x,0,-.0005).z;bottom=f.surface(x,math.pi,-.0005).z;cz=f.surface(x,math.pi/2).z
  roots=[(x,0,bottom),(x,0,cz),(x,0,top)]
 elif 'pectoral' in name.lower() or 'pelvic' in name.lower():
  anchored=[]
  for p in roots:
   x,y,z=map(float,p);w=abs(f.surface(x,math.pi/2).y);cz=f.surface(x,math.pi/2).z
   extent=f.surface(x,0).z-cz if z>=cz else cz-f.surface(x,math.pi).z
   theta=math.atan2(y/max(w,.001),(z-cz)/max(extent,.001))
   anchored.append(f.surface(x,theta,-.0007))
  roots=anchored
 return f.fin(name,roots,edge,**kwargs)

def anatomy(f):
 for name,a,b,edge,r in [('HighFirstDorsal',.216,.039,[(.216,0,.118),(.196,0,.240),(.164,0,.204),(.130,0,.160),(.078,0,.124),(.039,0,.106)],21),('SecondDorsal',.013,-.176,[(.013,0,.103),(-.019,0,.149),(-.071,0,.145),(-.136,0,.102),(-.176,0,.069)],23),('ThirdDorsal',-.203,-.350,[(-.203,0,.063),(-.238,0,.108),(-.286,0,.100),(-.327,0,.064),(-.350,0,.032)],20)]:
  _attach(f,name,[f.surface(float(x),0,-.001) for x in np.linspace(a,b,25)],edge,parent='spine_mid',rays=r)
 for name,a,b,edge in [('FirstAnal',.007,-.173,[(.007,0,-.063),(-.030,0,-.113),(-.083,0,-.105),(-.140,0,-.077),(-.173,0,-.047)]),('SecondAnal',-.203,-.349,[(-.203,0,-.041),(-.238,0,-.082),(-.293,0,-.073),(-.349,0,-.026)])]:
  _attach(f,name,[f.surface(float(x),math.pi,-.001) for x in np.linspace(a,b,24)],edge,parent='spine_rear',rays=22)
 _attach(f,'ForkedCaudal',[(-.388,0,-.021),(-.394,0,0),(-.389,0,.025)],[(-.422,0,-.057),(-.515,0,-.095),(-.498,0,-.045),(-.464,0,0),(-.498,0,.048),(-.515,0,.101),(-.421,0,.057)],bone='caudal',parent='tail',rays=27)
 line=f.material('BlackLateralLine',(.10,.13,.14),.52)
 for s in (-1,1):
  tag='L' if s<0 else 'R'
  _attach(f,'Pectoral'+tag,[(.267,s*.052,-.011),(.250,s*.053,-.031),(.233,s*.049,-.043)],[(.267,s*.052,-.011),(.181,s*.093,-.023),(.104,s*.115,-.048),(.164,s*.087,-.078),(.233,s*.049,-.043)],parent='spine_front',rays=20)
  _attach(f,'Pelvic'+tag,[(.282,s*.025,-.052),(.253,s*.029,-.064)],[(.282,s*.025,-.052),(.238,s*.052,-.111),(.185,s*.042,-.135),(.218,s*.031,-.093),(.253,s*.029,-.064)],parent='spine_front',rays=12)
  f.eye('LargeEye'+tag,f.surface(.394,s*1.06,.001),(0,s*.90,.42),.0128,iris=(.51,.49,.29))
  f.gill(tag,[f.surface(.275+.020*((t-1.4)/1.1)**2,s*t,.001) for t in np.linspace(.33,2.59,29)],.0012)
  pts=[f.surface(float(x),s*(1.54-.35*math.exp(-((x-.14)/.18)**2)),.00055) for x in np.linspace(-.366,.268,88)]
  f.tube('DarkContinuousLine'+tag,pts,.0013,line,'spine',7)
  mouth=[f.surface(float(x),s*(1.72+(.477-x)*5.1),.0008) for x in np.linspace(.477,.412,20)]
  f.tube('SmallMouth'+tag,mouth,.0017,f.mats['dark'],'head',8)
  f.tube('SmallLowerLip'+tag,[(x,y,z-.002) for x,y,z in mouth],.0016,f.mats['lip'],'jaw',8)
  f.ellipsoid('Nostril'+tag,f.surface(.448,s*.95,.001),(.0022,.0017,.0011),f.mats['dark'])
 f.tube('ShortChinBarbel',[(.448,0,-.023),(.439,0,-.044),(.428,0,-.060)], [.0023,.0013,.0002],f.mats['lip'],'jaw',8)
