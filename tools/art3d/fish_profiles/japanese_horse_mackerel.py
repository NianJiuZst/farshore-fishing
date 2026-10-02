"""Original Trachurus japonicus: scuted main lateral line, accessory line, no finlets."""
import math
import numpy as np

def scad_skin(u,v,upper,color,height,rough):
 spots=np.zeros_like(u)
 for side in (.25,.75):
  y=side+(-.095 if side<.5 else .095)
  d=((u-.756)/.014)**2+((v-y)/.038)**2
  spots=np.maximum(spots,np.clip((1-d)*4,0,1))
 color*=1-.87*spots[:,:,None]
 return color,height,rough
PROFILE={
 'id':'japanese_horse_mackerel',
 'sections':[(-.394,.009,.017,.016,0),(-.326,.017,.030,.025,0),(-.235,.028,.053,.040,0),(-.101,.040,.077,.055,.003),(.044,.049,.091,.067,.004),(.176,.052,.092,.069,.004),(.281,.044,.079,.056,.003),(.369,.032,.054,.034,.005),(.434,.020,.031,.019,.003),(.483,.010,.014,.008,0),(.502,.002,.003,.003,-.001)],
 'skin':{'back':(.14,.32,.31),'side':(.62,.72,.69),'belly':(.86,.88,.78),'pattern':'fine_scales','scale_columns':92,'scale_rows':40,'variation':.018},
 'custom_skin':scad_skin,'fin_color':(.51,.53,.31),'normal_strength':.08,'roughness':.37,'specular':.37,'swim_amplitude':.98,
 'morphology':['Moderately compressed spindle body with pointed snout and relatively large eye','Two dorsal fins, long second dorsal and anal fin; no detached finlets','Seventy-one strong lateral scutes following high anterior line and descended straight posterior line','Accessory lateral line below dorsal base, dark upper opercular spot and long sickle pectorals','Deeply forked yellow-grey tail; low narrow peduncle and two small isolated anal spines'],
 'sources':['https://fishdb.sinica.edu.tw/taxon/381555-fishdb']}

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
 _attach(f,'SpinyFirstDorsal',[f.surface(float(x),0,-.001) for x in np.linspace(.229,.069,18)],[(.229,0,.092),(.212,0,.171),(.175,0,.157),(.127,0,.113),(.069,0,.094)],parent='spine_front',rays=10)
 _attach(f,'LongSecondDorsal',[f.surface(float(x),0,-.001) for x in np.linspace(.040,-.333,35)],[(.040,0,.096),(.009,0,.144),(-.042,0,.113),(-.169,0,.089),(-.273,0,.071),(-.333,0,.032)],parent='spine_mid',rays=32)
 _attach(f,'LongAnal',[f.surface(float(x),math.pi,-.001) for x in np.linspace(.003,-.329,32)],[(.003,0,-.062),(-.030,0,-.103),(-.094,0,-.089),(-.223,0,-.067),(-.298,0,-.049),(-.329,0,-.027)],parent='spine_rear',rays=28)
 for i,x in enumerate((.052,.032)):
  p=f.surface(x,math.pi,.0004);f.tube('DetachedAnalSpine'+str(i),[p,(x-.007,0,p.z-.023),(x-.010,0,p.z-.027)],[.0013,.0008,.00012],f.mats['ray'],'spine',6)
 _attach(f,'DeepForkedCaudal',[(-.393,0,-.016),(-.399,0,0),(-.393,0,.017)],[(-.429,0,-.042),(-.537,0,-.124),(-.517,0,-.071),(-.449,0,0),(-.517,0,.074),(-.537,0,.128),(-.429,0,.043)],bone='caudal',parent='tail',rays=29)
 armor=f.material('SilverScuteArmor',(.54,.63,.58),.47)
 accessory=f.material('AccessoryLateralLine',(.29,.40,.33),.48)
 for s in (-1,1):
  tag='L' if s<0 else 'R'
  _attach(f,'SicklePectoral'+tag,[(.274,s*.043,.003),(.260,s*.047,-.012),(.246,s*.043,-.026)],[(.274,s*.043,.003),(.158,s*.102,-.001),(.011,s*.162,-.044),(-.037,s*.159,-.061),(.097,s*.105,-.062),(.246,s*.043,-.026)],parent='spine_front',rays=22)
  _attach(f,'Pelvic'+tag,[(.209,s*.019,-.062),(.182,s*.022,-.067)],[(.209,s*.019,-.062),(.161,s*.048,-.114),(.114,s*.038,-.127),(.148,s*.028,-.093),(.182,s*.022,-.067)],parent='spine_front',rays=10)
  f.eye('AdiposeMarginEye'+tag,f.surface(.404,s*1.11,.0007),(0,s*.94,.33),.0141,iris=(.68,.65,.38))
  f.gill(tag,[f.surface(.287+.021*((t-1.42)/1.1)**2,s*t,.0008) for t in np.linspace(.36,2.61,29)],.0011)
  for i,x in enumerate(np.linspace(.268,-.378,71)):
   # Main anterior line is high, descends under second dorsal, then becomes straight.
   t=np.clip((.075-x)/.18,0,1);t=t*t*(3-2*t);theta=1.03+t*.53;c=np.array(tuple(f.surface(float(x),s*theta,.0005)))
   width=.007 if x>-.08 else .010;length=.0095;height=.0011 if x>-.08 else .0020
   n=np.array((0,s*math.sin(theta),math.cos(theta)));u=np.array((1.,0,0));vv=np.cross(n,u)
   verts=[c+u*length*.5,c+vv*width*.5,c-u*length*.5,c-vv*width*.5,c+n*height-u*length*.10]
   f.mesh('LateralScute'+tag+str(i),verts,[(0,1,4),(1,2,4),(2,3,4),(3,0,4),(3,2,1,0)],armor,weight='spine')
  pts=[f.surface(float(x),s*.61,.0005) for x in np.linspace(.271,.027,34)]
  f.tube('AccessoryDorsalLine'+tag,pts,.00065,accessory,'spine',5)
  mouth=[f.surface(float(x),s*(1.61+(.488-x)*4.5),.0007) for x in np.linspace(.488,.409,21)]
  f.tube('SmallObliqueMouth'+tag,mouth,.0016,f.mats['dark'],'head',7)
  f.tube('LowerLip'+tag,[(x,y,z-.0015) for x,y,z in mouth],.0016,f.mats['lip'],'jaw',7)
  f.ellipsoid('Nostril'+tag,f.surface(.459,s*.94,.0007),(.0019,.0014,.0011),f.mats['dark'])
 f.tube('PointedJawTip',[(.482,-.012,0),(.502,0,-.002),(.482,.012,0)],.0017,f.mats['edge'],'head',7)
