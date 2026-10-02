"""Original Clupea harengus: one dorsal, subtle ventral scutes and upturned mouth."""
import math
import numpy as np
PROFILE={
 'id':'atlantic_herring',
 'sections':[(-.378,.010,.021,.018,0),(-.302,.017,.035,.028,.001),(-.202,.024,.054,.044,.002),(-.077,.032,.071,.060,.003),(.056,.038,.079,.071,.003),(.184,.041,.080,.074,.005),(.278,.037,.068,.062,.008),(.355,.029,.051,.042,.009),(.418,.021,.033,.025,.010),(.477,.010,.014,.009,.013),(.497,.002,.003,.004,.014)],
 'skin':{'back':(.16,.29,.37),'side':(.70,.76,.75),'belly':(.87,.89,.82),'pattern':'fine_scales','scale_columns':69,'scale_rows':33,'variation':.018},
 'fin_color':(.48,.52,.42),'normal_strength':.13,'roughness':.35,'specular':.43,'coat':.09,'swim_amplitude':.90,
 'morphology':['Slender laterally compressed silver body with blue-green back','Exactly one dorsal fin; pelvic fin insertion behind dorsal origin and short posterior anal','Large eye, smooth rounded gill cover and slightly projecting upturned lower jaw','Deep forked tail; weak belly scutes form no conspicuous knife-like keel','No finlets, no barbels, no flank spots and no armored lateral line'],
 'sources':['https://www.fao.org/4/ac482e/ac482e20.pdf','https://www.marlin.ac.uk/species/detail/45','https://www.fisheries.noaa.gov/species/atlantic-herring']}

def anatomy(f):
 f.fin('SingleDorsal',[f.surface(float(x),0,-.001) for x in np.linspace(.134,-.046,24)],[(.134,0,.084),(.113,0,.180),(.074,0,.161),(.025,0,.108),(-.046,0,.076)],parent='spine_mid',rays=20)
 f.fin('ShortAnal',[f.surface(float(x),math.pi,-.001) for x in np.linspace(-.165,-.312,24)],[(-.165,0,-.048),(-.186,0,-.094),(-.221,0,-.077),(-.286,0,-.054),(-.312,0,-.026)],parent='spine_rear',rays=22)
 f.fin('DeepForkedCaudal',[(-.378,0,-.018),(-.383,0,0),(-.378,0,.021)],[(-.424,0,-.044),(-.533,0,-.126),(-.508,0,-.068),(-.435,0,0),(-.508,0,.071),(-.533,0,.128),(-.424,0,.047)],bone='caudal',parent='tail',rays=28)
 weak_scute=f.material('SubtleBellyScutes',(.77,.80,.73),.48)
 for i,x in enumerate(np.linspace(.227,-.157,33)):
  c=np.array(tuple(f.surface(float(x),math.pi,.00005)));length=.011;width=.006;height=.00045
  verts=[c+np.array((length/2,0,0)),c+np.array((0,width/2,.0001)),c+np.array((-length/2,0,0)),c+np.array((0,-width/2,.0001)),c+np.array((-.001,0,-height))]
  f.mesh('WeakVentralScute%02d'%i,verts,[(0,1,4),(1,2,4),(2,3,4),(3,0,4),(3,2,1,0)],weak_scute,weight='spine')
 for s in (-1,1):
  tag='L' if s<0 else 'R'
  f.fin('Pectoral'+tag,[(.266,s*.033,-.018),(.254,s*.032,-.035),(.237,s*.027,-.049)],[(.266,s*.033,-.018),(.189,s*.069,-.040),(.095,s*.086,-.079),(.181,s*.057,-.083),(.237,s*.027,-.049)],parent='spine_front',rays=17)
  f.fin('AbdominalPelvic'+tag,[(.012,s*.019,-.065),(-.015,s*.020,-.064)],[(.012,s*.019,-.065),(-.025,s*.044,-.114),(-.073,s*.032,-.119),(-.043,s*.023,-.082),(-.015,s*.020,-.064)],parent='spine_mid',rays=10)
  f.eye('LargeSilverEye'+tag,f.surface(.390,s*1.19,.0008),(0,s*.96,.27),.0152,iris=(.72,.72,.54))
  f.gill(tag,[f.surface(.278+.027*((t-1.43)/1.12)**2,s*t,.001) for t in np.linspace(.33,2.61,30)],.001)
  mouth=[f.surface(float(x),s*(1.38+(.482-x)*6.2),.0007) for x in np.linspace(.482,.406,23)]
  f.tube('UpturnedMouth'+tag,mouth,.0016,f.mats['dark'],'head',7)
  f.tube('ProjectingLowerLip'+tag,[(x+.002,y,z-.0018) for x,y,z in mouth],.0018,f.mats['lip'],'jaw',7)
  f.ellipsoid('Nostril'+tag,f.surface(.452,s*1.02,.0008),(.0017,.0013,.0010),f.mats['dark'])
 f.tube('UpturnedJawTip',[(.478,-.010,.013),(.504,0,.019),(.478,.010,.013)],.0020,f.mats['lip'],'jaw',8)
