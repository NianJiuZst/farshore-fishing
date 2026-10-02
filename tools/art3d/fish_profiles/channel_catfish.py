"""Original Ictalurus punctatus geometry, based on USFWS/NPS anatomy references."""
import math
import numpy as np

def whisker(f,name,points,radius,material,weight,rings=8):
 points=np.array(points); dense=[]; radii=[]
 for i in range(len(points)-1):
  p0,p1,p2,p3=points[max(0,i-1)],points[i],points[i+1],points[min(len(points)-1,i+2)]
  for t in np.linspace(0,1,7,endpoint=False):
   dense.append(.5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t))
   radii.append(float(radius[i]*(1-t)+radius[i+1]*t))
 dense.append(points[-1]);radii.append(radius[-1]);f.tube(name,dense,radii,material,weight,rings)

def gill_curve(f,s,front=.25):
 return [f.surface(front+.025*((t-.9)/1.4)**2,s*t,.001) for t in np.linspace(.4,2.2,28)]
def adipose_lobe(f,name,x_front,x_rear,height,width,color):
 """Closed fleshy rayless lobe, embedded root, smoothly rounded longitudinal outline."""
 vertices=[];faces=[];n=24;m=14
 for i in range(n+1):
  t=i/n;x=x_front+(x_rear-x_front)*t
  root=f.surface(x,0).z-.003
  h=height*math.sin(math.pi*t)**.72
  w=max(.0003,width*math.sin(math.pi*t)**.8)
  for j in range(m):
   th=2*math.pi*j/m;c=math.cos(th)
   vertices.append((x,w*math.sin(th),root+(h*c if c>=0 else .006*c)))
 for i in range(n):
  for j in range(m):
   a=i*m+j;b=i*m+(j+1)%m;faces.append((a,b,b+m,a+m))
 faces.append(tuple(range(m-1,-1,-1)));faces.append(tuple(n*m+j for j in range(m)))
 f.mesh(name,vertices,faces,f.material(name+'Flesh',color,.49),weight='spine')

PROFILE = {
 'id':'channel_catfish',
 'sections':[(-.38,.018,.032,.03,0),(-.31,.030,.046,.040,0),(-.21,.045,.065,.055,.002),(-.08,.064,.082,.071,.005),(.06,.079,.094,.078,.007),(.18,.082,.09,.075,.004),(.28,.077,.072,.064,0),(.37,.066,.05,.046,-.004),(.445,.047,.028,.027,-.009),(.485,.013,.011,.009,-.01)],
 'skin':{'back':(.125,.16,.155),'side':(.38,.40,.32),'belly':(.79,.76,.62),'pattern':'smooth','feature':'spots','spot_count':70,'spot_radius':(.003,.006),'spot_color':(.035,.047,.045),'variation':.055},
 'roughness':.46,'fin_color':(.40,.39,.29),'swim_amplitude':.90,
 'morphology':['Scaleless smooth slate-olive body with sparse black spots','Eight tapered barbels: nasal, maxillary and two mandibular pairs','Deeply forked tail, arched anal fin, separate small adipose fin','Narrow sloping head, subterminal mouth, spine-bearing dorsal and pectorals'],
 'sources':['https://www.fws.gov/media/channel-catfish','https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/channel-catfish/','https://myfwc.com/wildlifehabitats/profiles/freshwater/channel-catfish/']}

def anatomy(f):
 f.fin('Dorsal',[(.21,0,.087),(.15,0,.097),(.06,0,.096)],[(.21,0,.089),(.18,0,.205),(.075,0,.142),(.06,0,.096)],parent='spine_front',rays=14)
 f.tube('DorsalLeadingSpine',[(.207,0,.088),(.19,0,.151),(.18,0,.203)],.0015,f.mats['ray'],weight='dorsal')
 adipose_lobe(f,'Adipose',-.206,-.329,.036,.006,(.27,.30,.24))
 f.fin('Anal',[(-.075,0,-.066),(-.18,0,-.06),(-.31,0,-.040)],[(-.075,0,-.067),(-.13,0,-.143),(-.23,0,-.128),(-.31,0,-.055)],parent='spine_rear',rays=28)
 f.fin('Caudal',[(-.378,0,-.031),(-.38,0,0),(-.378,0,.032)],[(-.535,0,-.128),(-.507,0,-.059),(-.445,0,0),(-.51,0,.073),(-.535,0,.142)],bone='caudal',parent='tail',rays=30)
 for s in (-1,1):
  tag='L' if s<0 else 'R'
  f.fin('Pectoral'+tag,[f.surface(float(x),s*1.95,-.0015) for x in np.linspace(0.24,0.16,14)],[(.24,s*.067,-.03),(.155,s*.168,-.081),(.07,s*.14,-.076),(.16,s*.073,-.043)],parent='spine_front',rays=17)
  f.fin('Pelvic'+tag,[f.surface(float(x),s*2.47,-.0015) for x in np.linspace(0.015,-0.028,14)],[(-.012,s*.054,-.064),(-.075,s*.105,-.122),(-.11,s*.061,-.11),(-.028,s*.052,-.063)],parent='spine_mid',rays=13)
  f.eye('Eye'+tag,f.surface(.392,s*1.12,.001),(0,s*.94,.33),.0085,iris=(.61,.56,.35))
  f.gill(tag,gill_curve(f,s),.0012)
  whisker(f,'MaxillaryBarbel'+tag,[(.461,s*.027,-.016),(.435,s*.060,-.025),(.371,s*.101,-.055),(.304,s*.11,-.096),(.273,s*.099,-.11)],[.0035,.003,.002,.0011,.00018],f.mats['edge'],'head',8)
  whisker(f,'NasalBarbel'+tag,[(.447,s*.026,.012),(.456,s*.041,.027),(.445,s*.055,.049),(.422,s*.064,.055)],[.0015,.0012,.0008,.00015],f.mats['edge'],'head',7)
  whisker(f,'OuterChinBarbel'+tag,[(.446,s*.025,-.034),(.42,s*.046,-.064),(.379,s*.066,-.087),(.341,s*.067,-.095)],[.002,.0017,.001,.00015],f.mats['lip'],'jaw',7)
  whisker(f,'InnerChinBarbel'+tag,[(.460,s*.010,-.029),(.45,s*.017,-.056),(.424,s*.026,-.079),(.395,s*.028,-.085)],[.0018,.0015,.0008,.00015],f.mats['lip'],'jaw',7)
  f.ellipsoid('Nostril'+tag,(.461,s*.024,.012),(.003,.003,.0013),f.mats['dark'])
 mouth=[(.441,-.041,-.025),(.469,-.025,-.023),(.482,0,-.021),(.469,.025,-.023),(.441,.041,-.025)]
 f.tube('MouthRecess',mouth,.0028,f.mats['dark'],'head',8)
 f.tube('LowerLip',[(x-.002,y,z-.003) for x,y,z in mouth],.0024,f.mats['lip'],'jaw',8)
