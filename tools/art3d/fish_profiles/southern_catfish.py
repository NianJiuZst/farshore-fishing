"""Silurus meridionalis: two barbel pairs, tiny dorsal, no adipose, long anal skirt."""
import math
import numpy as np
from fish_profiles.channel_catfish import whisker
PROFILE={
 'id':'southern_catfish',
 'sections':[(-.415,.012,.031,.026,0),(-.32,.018,.041,.036,.001),(-.22,.027,.057,.049,.001),(-.09,.045,.074,.062,.003),(.06,.077,.089,.079,.003),(.19,.098,.079,.073,.001),(.30,.112,.047,.054,-.001),(.394,.099,.033,.039,0),(.463,.073,.018,.026,.004),(.496,.022,.007,.014,.006)],
 'skin':{'back':(.105,.15,.12),'side':(.32,.36,.27),'belly':(.67,.69,.49),'pattern':'mottle','mottle_amount':.19,'variation':.055},
 'roughness':.47,'fin_color':(.29,.33,.25),'swim_amplitude':1.0,
 'morphology':['Scaleless body thick in front and laterally compressed behind','Broad flattened head, large upturned mouth and exactly four barbels','Tiny soft dorsal, no adipose fin','Very long anal fin reaches shallow-notched short caudal fin'],
 'sources':['https://www.yueyang.gov.cn/uploadfiles/202302/20230223161357669.pdf','https://www.fishbase.se/summary/25308']}

def anatomy(f):
 f.fin('TinySoftDorsal',[(.235,0,.064),(.212,0,.075),(.169,0,.082)],[(.235,0,.064),(.226,0,.12),(.197,0,.119),(.169,0,.082)],parent='spine_front',rays=6)
 roots=[f.surface(float(x),math.pi) for x in np.linspace(.074,-.411,26)]
 f.fin('LongAnal',roots,[(.074,0,-.076),(.025,0,-.13),(-.11,0,-.131),(-.28,0,-.101),(-.407,0,-.063),(-.449,0,-.046)],parent='spine_rear',rays=81)
 f.fin('Caudal',[(-.414,0,-.027),(-.417,0,0),(-.414,0,.031)],[(-.501,0,-.075),(-.522,0,-.049),(-.518,0,.003),(-.531,0,.061),(-.51,0,.083)],bone='caudal',parent='tail',rays=22)
 jawmat=f.material('SouthernJawSkin',(.42,.44,.30),.46)
 f.ellipsoid('WideUpturnedLowerJaw',(.471,0,-.017),(.037,.069,.014),jawmat,'jaw')
 mouth=[(.454,-.079,-.008),(.48,-.044,-.003),(.501,0,.005),(.48,.044,-.003),(.454,.079,-.008)]
 f.tube('WideUpturnedMouth',mouth,.0022,f.mats['dark'],'head',9)
 f.tube('LowerLip',[(x+.002,y,z-.003) for x,y,z in mouth],.0028,jawmat,'jaw',9)
 for s in (-1,1):
  tag='L' if s<0 else 'R'
  f.fin('Pectoral'+tag,[f.surface(float(x),s*1.95,-.0015) for x in np.linspace(0.254,0.189,14)],[(.254,s*.093,-.029),(.165,s*.181,-.054),(.061,s*.149,-.09),(.092,s*.106,-.084),(.189,s*.083,-.045)],parent='spine_front',rays=15)
  f.fin('Pelvic'+tag,[f.surface(float(x),s*2.5,-.0015) for x in np.linspace(0.091,0.063,14)],[(.091,s*.047,-.065),(.014,s*.100,-.105),(-.018,s*.077,-.114),(.063,s*.046,-.068)],parent='spine_mid',rays=11)
  f.eye('TinyEye'+tag,f.surface(.407,s*1.06,.001),(0,s*.92,.39),.0065,iris=(.48,.46,.28))
  f.gill(tag,[f.surface(.258+.027*((t-1.1)/1.1)**2,s*t,.001) for t in np.linspace(.34,2.35,30)],.0011)
  whisker(f,'MaxillaryBarbel'+tag,[(.475,s*.058,.002),(.429,s*.104,-.004),(.339,s*.151,-.034),(.227,s*.171,-.069),(.112,s*.155,-.09)],[.004,.0032,.0023,.0011,.00018],f.mats['edge'],'head')
  whisker(f,'MandibularBarbel'+tag,[(.459,s*.037,-.037),(.427,s*.063,-.063),(.375,s*.075,-.086),(.347,s*.074,-.094)],[.0024,.0018,.0008,.00017],f.mats['lip'],'jaw')
  f.ellipsoid('Nostril'+tag,(.45,s*.047,.022),(.004,.0025,.0013),f.mats['dark'])
