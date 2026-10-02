"""Original adult Pollachius virens with nearly straight pale lateral line."""
import math
import numpy as np
PROFILE={
 'id':'saithe',
 'sections':[(-.393,.010,.021,.020,0),(-.325,.017,.030,.027,0),(-.237,.028,.047,.035,0),(-.10,.043,.068,.046,.002),(.048,.058,.081,.055,.003),(.177,.065,.087,.061,.003),(.283,.056,.075,.057,0),(.372,.039,.052,.037,-.002),(.454,.021,.025,.023,-.002),(.494,.008,.012,.012,-.001),(.505,.002,.004,.005,0)],
 'skin':{'back':(.10,.18,.18),'side':(.38,.46,.43),'belly':(.78,.81,.76),'pattern':'fine_scales','scale_columns':97,'scale_rows':42,'variation':.022},
 'fin_color':(.23,.29,.28),'roughness':.37,'normal_strength':.08,'swim_amplitude':1.05,
 'morphology':['Muscular streamlined body with dark green-black back and silver belly','Three separate dorsal and two anal fins; first anal longer than in Atlantic cod','Nearly equal-length jaws, modest eyes and no adult chin barbel','Pale almost straight lateral line and distinctly forked caudal fin'],
 'sources':['https://www.hi.no/en/hi/temasider/species/northeast-arctic-saithe','https://www.marlin.ac.uk/species/detail/9']}

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
 for name,a,b,edge,r in [('FirstDorsal',.217,.082,[(.217,0,.089),(.183,0,.146),(.146,0,.144),(.113,0,.112),(.082,0,.083)],18),('SecondDorsal',.048,-.182,[(.048,0,.083),(.015,0,.123),(-.061,0,.119),(-.140,0,.083),(-.182,0,.057)],25),('ThirdDorsal',-.211,-.356,[(-.211,0,.053),(-.248,0,.087),(-.294,0,.077),(-.337,0,.049),(-.356,0,.026)],19)]:
  _attach(f,name,[f.surface(float(x),0,-.001) for x in np.linspace(a,b,24)],edge,parent='spine_mid',rays=r)
 for name,a,b,edge,r in [('FirstAnal',.133,-.181,[(.133,0,-.058),(.095,0,-.096),(.006,0,-.095),(-.091,0,-.078),(-.152,0,-.054),(-.181,0,-.040)],30),('SecondAnal',-.207,-.349,[(-.207,0,-.037),(-.240,0,-.070),(-.302,0,-.063),(-.349,0,-.024)],18)]:
  _attach(f,name,[f.surface(float(x),math.pi,-.001) for x in np.linspace(a,b,26)],edge,parent='spine_rear',rays=r)
 _attach(f,'ForkedCaudal',[(-.392,0,-.020),(-.397,0,0),(-.392,0,.021)],[(-.428,0,-.051),(-.516,0,-.104),(-.505,0,-.061),(-.455,0,0),(-.505,0,.063),(-.516,0,.107),(-.428,0,.051)],bone='caudal',parent='tail',rays=29)
 line=f.material('StraightWhiteLateralLine',(.73,.79,.71),.48)
 for s in (-1,1):
  tag='L' if s<0 else 'R'
  _attach(f,'Pectoral'+tag,[(.249,s*.056,-.008),(.231,s*.059,-.028),(.217,s*.054,-.038)],[(.249,s*.056,-.008),(.159,s*.102,-.024),(.091,s*.127,-.047),(.153,s*.091,-.068),(.217,s*.054,-.038)],parent='spine_front',rays=20)
  _attach(f,'Pelvic'+tag,[(.268,s*.026,-.054),(.239,s*.028,-.058)],[(.268,s*.026,-.054),(.217,s*.048,-.093),(.170,s*.039,-.106),(.210,s*.031,-.077),(.239,s*.028,-.058)],parent='spine_front',rays=12)
  f.eye('Eye'+tag,f.surface(.406,s*1.11,.001),(0,s*.94,.34),.0098,iris=(.49,.48,.29))
  f.gill(tag,[f.surface(.260+.025*((t-1.4)/1.1)**2,s*t,.001) for t in np.linspace(.36,2.62,30)],.0012)
  pts=[]
  for x in np.linspace(-.372,.265,85):
   # Solve theta for an almost horizontal pale line, with only gentle front lift.
   z=.004+.006*math.exp(-((x-.23)/.19)**2);height=float(np.interp(x,[a[0] for a in f.sections],[a[2] for a in f.sections]));theta=math.acos(min(.9,z/height));pts.append(f.surface(float(x),s*theta,.0006))
  f.tube('StraightLateralLine'+tag,pts,.00125,line,'spine',6)
  mouth=[f.surface(float(x),s*(1.60+(.495-x)*4.6),.0007) for x in np.linspace(.495,.379,27)]
  f.tube('MouthCleft'+tag,mouth,.0017,f.mats['dark'],'head',8)
  f.tube('LowerLip'+tag,[(x,y,z-.002) for x,y,z in mouth],.0018,f.mats['lip'],'jaw',8)
  f.ellipsoid('Nostril'+tag,f.surface(.459,s*.96,.001),(.0021,.0016,.0013),f.mats['dark'])
 f.tube('EvenJawTip',[(.490,-.012,0),(.506,0,0),(.490,.012,0)],.0021,f.mats['edge'],'head',8)
