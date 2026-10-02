"""Original Gadus morhua: full-bodied cod with five separated median fins."""
import math
import numpy as np
PROFILE={
 'id':'atlantic_cod',
 'sections':[(-.39,.017,.026,.022,0),(-.32,.025,.036,.028,0),(-.23,.036,.048,.037,.001),(-.10,.052,.071,.049,.003),(.04,.064,.088,.062,.004),(.16,.073,.101,.073,.003),(.27,.069,.092,.074,0),(.35,.057,.072,.056,-.002),(.43,.043,.042,.035,-.005),(.488,.021,.023,.020,-.009),(.507,.004,.012,.011,-.009)],
 'skin':{'back':(.24,.28,.16),'side':(.51,.49,.32),'belly':(.78,.78,.64),'pattern':'mottle','mottle_amount':.39,'feature':'spots','spot_count':205,'spot_radius':(.002,.007),'spot_color':(.12,.17,.10),'variation':.055},
 'normal_strength':.16,'roughness':.43,'fin_color':(.36,.36,.22),'fin_pattern':'spots','swim_amplitude':.87,
 'morphology':['Three separate rounded dorsal fins and two separate anal fins','Full-bellied elongated body; stout caudal peduncle and near-truncate tail','Single tapered chin barbel and upper jaw longer than lower','Pale lateral line arches over pectoral fin; olive-brown mottling and fine dark flecks'],
 'sources':['https://www.marlin.ac.uk/species/detail/2095','https://www.vims.edu/research/units/programs/multispecies_fisheries_research/speciesofinterest/atlantic-cod.php','https://www.marinespecies.org/photogallery.php?album=745&pic=40141']}

def anatomy(f):
 for name,a,b,edge,rays,parent in [
  ('FirstDorsal',.205,.045,[(.205,0,.101),(.180,0,.151),(.145,0,.166),(.103,0,.155),(.045,0,.089)],20,'spine_front'),
  ('SecondDorsal',.018,-.188,[(.018,0,.085),(-.023,0,.132),(-.071,0,.134),(-.139,0,.110),(-.188,0,.057)],24,'spine_mid'),
  ('ThirdDorsal',-.216,-.354,[(-.216,0,.054),(-.250,0,.096),(-.293,0,.090),(-.331,0,.067),(-.354,0,.032)],18,'spine_rear')]:
  f.fin(name,[f.surface(float(x),0,-.001) for x in np.linspace(a,b,20)],edge,parent=parent,rays=rays)
 for name,a,b,edge in [
  ('FirstAnal',.034,-.180,[(.034,0,-.059),(-.006,0,-.099),(-.075,0,-.103),(-.139,0,-.082),(-.180,0,-.042)]),
  ('SecondAnal',-.206,-.346,[(-.206,0,-.037),(-.235,0,-.075),(-.291,0,-.074),(-.329,0,-.052),(-.346,0,-.025)])]:
  f.fin(name,[f.surface(float(x),math.pi,-.001) for x in np.linspace(a,b,22)],edge,parent='spine_rear',rays=22)
 f.fin('Caudal',[(-.39,0,-.022),(-.394,0,0),(-.39,0,.026)],[(-.418,0,-.054),(-.490,0,-.083),(-.514,0,-.052),(-.505,0,0),(-.514,0,.055),(-.492,0,.088),(-.418,0,.057)],bone='caudal',parent='tail',rays=30)
 pale=f.material('PaleCurvedLateralLine',(.71,.72,.54),.51)
 for s in (-1,1):
  tag='L' if s<0 else 'R'
  f.fin('Pectoral'+tag,[(.247,s*.066,-.005),(.232,s*.068,-.024),(.217,s*.065,-.034)],[(.247,s*.066,-.005),(.157,s*.113,-.021),(.076,s*.139,-.050),(.131,s*.101,-.075),(.217,s*.065,-.034)],parent='spine_front',rays=19)
  f.fin('Pelvic'+tag,[(.277,s*.024,-.066),(.249,s*.031,-.072)],[(.277,s*.024,-.066),(.221,s*.056,-.111),(.155,s*.045,-.128),(.179,s*.034,-.100),(.249,s*.031,-.072)],parent='spine_front',rays=13)
  f.eye('Eye'+tag,f.surface(.399,s*1.11,.001),(0,s*.93,.36),.0105,iris=(.45,.45,.25))
  f.gill(tag,[f.surface(.262+.030*((t-1.3)/1.15)**2,s*t,.001) for t in np.linspace(.36,2.62,32)],.0013)
  line=[]
  for x in np.linspace(-.36,.253,80):
   angle=1.51-.44*math.exp(-((x-.17)/.18)**2)
   line.append(f.surface(float(x),s*angle,.00055))
  f.tube('ArchedLateralLine'+tag,line,.00105,pale,'spine',6)
  mouth=[f.surface(float(x),s*(1.62+(.491-x)*4.9),.0008) for x in np.linspace(.491,.370,28)]
  f.tube('MouthCleft'+tag,mouth,.0019,f.mats['dark'],'head',8)
  f.tube('LowerLip'+tag,[(x,y,z-.0028) for x,y,z in mouth],.0019,f.mats['lip'],'jaw',8)
  f.ellipsoid('Nostril'+tag,f.surface(.445,s*.95,.001),(.0026,.002,.0015),f.mats['dark'])
 f.tube('UpperLip',[(.483,-.024,-.005),(.507,0,-.009),(.483,.024,-.005)],.0023,f.mats['edge'],'head',8)
 f.tube('SingleChinBarbel',[(.443,0,-.040),(.437,0,-.062),(.418,0,-.091),(.399,0,-.112)], [.0033,.0026,.0014,.00022],f.mats['lip'],'jaw',9)
