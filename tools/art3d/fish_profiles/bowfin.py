"""Amia ocellicauda (stable bowfin game ID), with short anal and male tail eyespot."""
import math
import numpy as np

def bowfin_skin(u,v,upper,color,height,rough):
 gate=np.clip((.80-u)/.10,0,1)
 mottles=np.clip((np.sin(u*119+np.sin(v*61))*np.sin(v*133-u*41)+.18)*1.2,0,1)*gate
 color*=1-mottles[:,:,None]*.32
 # Male's black eyespot on upper tail base, pale ochre outer rim, both sides.
 for center in (.17,.83):
  d=((u-.073)/.029)**2+((v-center)/.069)**2
  rim=np.clip((1.48-d)*5,0,1);spot=np.clip((1-d)*7,0,1)
  color=color*(1-rim[:,:,None]*.72)+np.array((.65,.59,.24))*rim[:,:,None]*.72
  color=color*(1-spot[:,:,None]*.95)+np.array((.018,.024,.014))*spot[:,:,None]*.95
 return color,height,rough

PROFILE={
 'id':'bowfin',
 'sections':[(-.387,.031,.050,.037,.003),(-.30,.041,.062,.047,.004),(-.19,.054,.083,.062,.006),(-.045,.071,.094,.074,.009),(.11,.084,.096,.081,.011),(.23,.087,.079,.071,.006),(.33,.078,.061,.058,.003),(.414,.062,.044,.042,0),(.467,.039,.027,.027,-.002),(.493,.010,.008,.011,-.005)],
 'skin':{'back':(.13,.19,.09),'side':(.41,.46,.24),'belly':(.69,.71,.41),'pattern':'fine_scales','scale_columns':62,'scale_rows':28,'variation':.055},
 'custom_skin':bowfin_skin,'head_start':.75,'head_end':.82,'roughness':.47,'fin_color':(.30,.36,.16),'fin_pattern':'spots','swim_amplitude':.98,
 'morphology':['Robust cylindrical body and rounded scaleless head','Long soft dorsal but distinctly short anal fin; rounded caudal','Pelvic fins well behind pectorals, unlike snakehead','Paired nasal flaps, underside bony gular plate and pale-rimmed male tail-base eyespot'],
 'sources':['https://mdc.mo.gov/discover-nature/field-guide/emerald-bowfin','https://pmc.ncbi.nlm.nih.gov/articles/PMC9709656/','https://www.fws.gov/species/snakehead-channa-argus']}

def anatomy(f):
 f.fin('LongDorsal',[f.surface(float(x),0,-.0015) for x in np.linspace(.184,-.369,38)],[(.184,0,.088),(.133,0,.152),(-.045,0,.153),(-.225,0,.127),(-.344,0,.101),(-.376,0,.054)],parent='spine_mid',rays=49)
 f.fin('ShortAnal',[f.surface(float(x),math.pi,-.001) for x in np.linspace(-.19,-.29,14)],[(-.19,0,-.058),(-.22,0,-.112),(-.284,0,-.117),(-.325,0,-.089),(-.29,0,-.042)],parent='spine_rear',rays=12)
 f.fin('Caudal',[(-.385,0,-.035),(-.389,0,.006),(-.386,0,.052)],[(-.432,0,-.091),(-.499,0,-.092),(-.537,0,-.053),(-.545,0,.011),(-.527,0,.076),(-.478,0,.11),(-.413,0,.101)],bone='caudal',parent='tail',rays=27)
 plate=f.material('GularPlate',(.54,.58,.31),.56)
 f.ellipsoid('BonyGularPlate',(.349,0,-.052),(.088,.038,.009),plate,'jaw')
 for s in (-1,1):
  tag='L' if s<0 else 'R'
  f.fin('Pectoral'+tag,[(.255,s*.071,-.023),(.232,s*.075,-.035),(.209,s*.068,-.043)],[(.255,s*.071,-.023),(.19,s*.146,-.033),(.11,s*.151,-.067),(.091,s*.116,-.083),(.156,s*.080,-.078),(.209,s*.068,-.043)],parent='spine_front',rays=18)
  f.fin('Pelvic'+tag,[(-.02,s*.05,-.064),(-.06,s*.05,-.064)],[(-.02,s*.05,-.064),(-.089,s*.116,-.101),(-.15,s*.082,-.104),(-.06,s*.05,-.064)],parent='spine_mid',rays=13)
  f.eye('Eye'+tag,f.surface(.397,s*1.14,.001),(0,s*.94,.34),.009,iris=(.55,.44,.16))
  f.gill(tag,[f.surface(.255+.030*((t-1.10)/1.03)**2,s*t,.001) for t in np.linspace(.35,2.33,30)],.0014)
  pts=[f.surface(float(x),s*(1.64+(.482-x)*2.6),.0008) for x in np.linspace(.482,.34,29)]
  f.tube('LargeMouthCleft'+tag,pts,.0018,f.mats['dark'],'head',8)
  f.tube('LowerJawLip'+tag,[(x,y,z-.002) for x,y,z in pts],.0022,f.mats['edge'],'jaw',8)
  f.ellipsoid('Nostril'+tag,(.452,s*.035,.018),(.0035,.0025,.0018),f.mats['dark'])
  f.tube('NasalFlap'+tag,[(.453,s*.035,.020),(.465,s*.038,.025),(.469,s*.038,.030)],[.002,.0017,.0007],f.mats['edge'],'head',7)
 f.tube('RoundedTerminalLip',[(.48,-.025,-.004),(.495,0,-.004),(.48,.025,-.004)],.0025,f.mats['edge'],'head',8)
