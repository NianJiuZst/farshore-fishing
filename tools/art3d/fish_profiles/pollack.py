"""Original Pollachius pollachius: projecting jaw, arched dark line and long anal."""
import math
import numpy as np
PROFILE={
 'id':'pollack',
 'sections':[(-.39,.013,.021,.021,0),(-.32,.019,.031,.031,0),(-.23,.029,.045,.041,.001),(-.09,.044,.067,.056,.002),(.06,.055,.085,.068,.003),(.19,.061,.091,.070,.004),(.29,.056,.083,.060,.003),(.38,.040,.059,.040,.004),(.46,.024,.031,.023,.004),(.492,.012,.016,.014,.006),(.510,.003,.005,.007,.007)],
 'skin':{'back':(.20,.26,.19),'side':(.57,.53,.33),'belly':(.78,.78,.65),'pattern':'fine_scales','scale_columns':93,'scale_rows':40,'variation':.025},
 'fin_color':(.32,.34,.23),'roughness':.40,'normal_strength':.09,'swim_amplitude':.93,
 'morphology':['Elongated moderately compressed trunk; large oblique mouth with projecting lower jaw','Large yellow eyes and no chin barbel','Three dorsals with triangular first; long first anal and short second anal','Strong dark arched lateral line, bronze flanks, slightly forked broad tail'],
 'sources':['https://www.marlin.ac.uk/species/detail/9']}

def anatomy(f):
 dorsals=[('FirstDorsal',.235,.091,[(.235,0,.092),(.211,0,.165),(.171,0,.153),(.129,0,.116),(.091,0,.087)],17),('SecondDorsal',.060,-.171,[(.060,0,.086),(.022,0,.139),(-.040,0,.139),(-.111,0,.105),(-.171,0,.054)],25),('ThirdDorsal',-.197,-.357,[(-.197,0,.052),(-.235,0,.096),(-.290,0,.087),(-.336,0,.056),(-.357,0,.027)],20)]
 for name,a,b,edge,r in dorsals:f.fin(name,[f.surface(float(x),0,-.0012) for x in np.linspace(a,b,20)],edge,parent='spine_front' if a>0 else 'spine_rear',rays=r)
 for name,a,b,edge,r in [('FirstAnal',.169,-.172,[(.169,0,-.066),(.121,0,-.104),(.042,0,-.115),(-.067,0,-.101),(-.138,0,-.074),(-.172,0,-.044)],32),('SecondAnal',-.197,-.351,[(-.197,0,-.043),(-.237,0,-.078),(-.303,0,-.072),(-.351,0,-.026)],19)]:
  f.fin(name,[f.surface(float(x),math.pi,-.001) for x in np.linspace(a,b,30)],edge,parent='spine_mid',rays=r)
 f.fin('Caudal',[(-.389,0,-.021),(-.395,0,0),(-.39,0,.021)],[(-.421,0,-.053),(-.511,0,-.089),(-.500,0,-.049),(-.457,0,0),(-.501,0,.053),(-.511,0,.091),(-.421,0,.053)],bone='caudal',parent='tail',rays=28)
 line_mat=f.material('DarkGreenArchedLine',(.16,.24,.17),.49)
 pelvic=f.material('PinkGreyPelvicMembrane',(.57,.49,.43),.55)
 for s in (-1,1):
  tag='L' if s<0 else 'R'
  f.fin('ShortPectoral'+tag,[(.255,s*.054,-.012),(.236,s*.058,-.032),(.226,s*.052,-.042)],[(.255,s*.054,-.012),(.188,s*.090,-.028),(.133,s*.106,-.050),(.187,s*.078,-.071),(.226,s*.052,-.042)],parent='spine_front',rays=19)
  f.fin('ThoracicPelvic'+tag,[(.277,s*.024,-.058),(.246,s*.027,-.065)],[(.277,s*.024,-.058),(.225,s*.052,-.103),(.188,s*.041,-.115),(.221,s*.033,-.089),(.246,s*.027,-.065)],parent='spine_front',rays=11,material=pelvic)
  f.eye('LargeYellowEye'+tag,f.surface(.401,s*1.02,.001),(0,s*.91,.42),.0137,iris=(.60,.53,.22))
  f.gill(tag,[f.surface(.256+.027*((t-1.4)/1.1)**2,s*t,.001) for t in np.linspace(.38,2.59,28)],.00115)
  pts=[]
  for x in np.linspace(-.366,.260,90):
   angle=1.54-.72*math.exp(-((x-.155)/.161)**2);pts.append(f.surface(float(x),s*angle,.0007))
  f.tube('StrongArchedLine'+tag,pts,.00135,line_mat,'spine',7)
  mouth=[f.surface(float(x),s*(1.48+(.494-x)*5.1),.0007) for x in np.linspace(.494,.372,28)]
  f.tube('ObliqueMouth'+tag,mouth,.0018,f.mats['dark'],'head',8)
  f.tube('ProjectingLowerLip'+tag,[(x+.003,y,z-.002) for x,y,z in mouth],.0024,f.mats['lip'],'jaw',8)
  f.ellipsoid('Nostril'+tag,f.surface(.456,s*.83,.001),(.0022,.0016,.0012),f.mats['dark'])
 f.tube('ProtrudingLowerJawTip',[(.492,-.013,.003),(.515,0,.006),(.492,.013,.003)],.0027,f.mats['lip'],'jaw',9)
