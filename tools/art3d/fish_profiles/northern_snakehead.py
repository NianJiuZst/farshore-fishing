"""Original Channa argus: scaled depressed head, Python-like pigment and long anal fin."""
import math
import numpy as np

def snake_skin(u,v,upper,color,height,rough):
 # Two staggered ragged bands of dark saddles on each flank, not vertical perch bars.
 mask=np.zeros_like(u)
 for side in (.25,.75):
  for row,offset in ((0,0),(1,.047)):
   for i in range(8):
    x=.10+i*.091+offset+.008*math.sin(i*3.2);y=side+(-.044 if row==0 else .055)+.014*math.sin(i*4.7)
    dx=(u-x)/(.043+.011*math.sin(i*2.));dy=(v-y)/(.057 if row==0 else .042)
    d=dx*dx+dy*dy+.22*np.sin(u*301+v*143)+.17*np.cos(v*335-u*177)
    mask=np.maximum(mask,np.clip((1.05-d)*5,0,1))
 # Narrow streaks across broad head; retain naturally scaled head.
 head=np.clip((u-.78)/.08,0,1)
 streak=np.maximum(0,np.cos(v*math.tau*9+u*24))**10*head
 flank=np.clip((upper-.09)/.2,0,1)
 mask=np.maximum(mask,streak*.8)*flank
 color=color*(1-mask[:,:,None]*.70)
 return color,height,rough

PROFILE={
 'id':'northern_snakehead',
 'sections':[(-.39,.022,.040,.032,0),(-.31,.029,.049,.040,.001),(-.21,.038,.064,.050,.002),(-.07,.052,.072,.058,.004),(.08,.065,.08,.064,.005),(.20,.074,.073,.061,.006),(.30,.079,.052,.052,.004),(.39,.068,.038,.041,.006),(.46,.047,.027,.029,.009),(.495,.025,.014,.017,.009),(.508,.007,.006,.009,.009)],
 'skin':{'back':(.15,.17,.095),'side':(.39,.40,.25),'belly':(.68,.67,.46),'pattern':'fine_scales','scale_columns':78,'scale_rows':34,'variation':.055},
 'head_start':1.1,'head_end':1.2,'custom_skin':snake_skin,'roughness':.38,'fin_color':(.25,.28,.17),'fin_pattern':'spots','swim_amplitude':1.05,
 'morphology':['Long cylindrical body, flattened broad scaled snake-like head','Large terminal mouth extending behind the eye; no sensory barbels','Long dorsal AND long anal fins; small pelvic fins close behind pectorals','Rounded caudal fin and paired rows of irregular python-like dark blotches'],
 'sources':['https://nas.er.usgs.gov/queries/FactSheet.aspx?SpeciesID=2265','https://www.fws.gov/species/snakehead-channa-argus','https://www.fws.gov/media/invasive-snakehead-1']}

def anatomy(f):
 f.fin('LongDorsal',[f.surface(float(x),0,-.0015) for x in np.linspace(.24,-.38,40)],[(.24,0,.066),(.17,0,.127),(.02,0,.127),(-.19,0,.118),(-.35,0,.091),(-.38,0,.044)],parent='spine_mid',rays=50)
 f.fin('LongAnal',[f.surface(float(x),math.pi,-.0015) for x in np.linspace(.095,-.38,32)],[(.095,0,-.059),(.03,0,-.107),(-.16,0,-.11),(-.33,0,-.080),(-.38,0,-.035)],parent='spine_rear',rays=32)
 f.fin('Caudal',[(-.388,0,-.032),(-.391,0,0),(-.389,0,.040)],[(-.43,0,-.077),(-.51,0,-.072),(-.546,0,-.035),(-.552,0,.012),(-.527,0,.072),(-.474,0,.087),(-.42,0,.078)],bone='caudal',parent='tail',rays=27)
 for s in (-1,1):
  tag='L' if s<0 else 'R'
  f.fin('Pectoral'+tag,[(.24,s*.066,-.016),(.217,s*.07,-.033),(.20,s*.066,-.042)],[(.24,s*.066,-.016),(.19,s*.131,-.024),(.107,s*.156,-.051),(.081,s*.123,-.067),(.13,s*.086,-.065),(.20,s*.066,-.042)],parent='spine_front',rays=20)
  f.fin('Pelvic'+tag,[(.16,s*.029,-.057),(.135,s*.032,-.060)],[(.16,s*.029,-.057),(.101,s*.066,-.090),(.081,s*.043,-.099),(.135,s*.032,-.060)],parent='spine_front',rays=10)
  f.eye('Eye'+tag,f.surface(.397,s*1.10,.001),(0,s*.91,.42),.009,iris=(.41,.35,.16))
  f.gill(tag,[f.surface(.222+.022*((t-1.20)/.94)**2,s*t,.001) for t in np.linspace(.4,2.25,28)],.0015)
  # Large oblique mouth extends below and behind eye.
  pts=[f.surface(x,s*(1.55+(.494-x)*3.1),.0008) for x in np.linspace(.494,.355,28)]
  f.tube('MouthCleft'+tag,pts,.0022,f.mats['dark'],'head',8)
  f.tube('LowerJawLip'+tag,[(x,y,z-.002) for x,y,z in pts],.0018,f.mats['edge'],'jaw',8)
  f.ellipsoid('Nostril'+tag,(.467,s*.036,.026),(.003,.002,.0015),f.mats['dark'])
 f.tube('TerminalLip',[(.492,-.025,.009),(.507,0,.009),(.492,.025,.009)],.0025,f.mats['edge'],'head',8)
