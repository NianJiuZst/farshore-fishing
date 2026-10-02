"""Pylodictis olivaris with a flattened broad head and protruding lower jaw."""
import math
import numpy as np
from fish_profiles.channel_catfish import whisker, adipose_lobe
def fine_mottling(u,v,upper,color,height,rough):
 # Smooth stochastic pigment fields avoid a regular scale-like or tiled pattern.
 rng=np.random.default_rng(72951)
 def noise(nx,ny):
  grid=rng.uniform(0,1,(ny+1,nx+1));gx=u*nx;gy=v*ny
  ix=np.minimum(gx.astype(int),nx-1);iy=np.minimum(gy.astype(int),ny-1)
  tx=gx-ix;ty=gy-iy;tx=tx*tx*(3-2*tx);ty=ty*ty*(3-2*ty)
  return (grid[iy,ix]*(1-tx)+grid[iy,ix+1]*tx)*(1-ty)+(grid[iy+1,ix]*(1-tx)+grid[iy+1,ix+1]*tx)*ty
 n=.60*noise(35,18)+.30*noise(71,36)+.10*noise(137,69)
 blotch=np.clip((n-.40)*4,0,1)*np.clip((upper-.14)/.36,0,1)
 color*=1-blotch[:,:,None]*.55
 return color,height,rough

PROFILE={
 'id':'flathead_catfish',
 'sections':[(-.38,.022,.038,.035,0),(-.28,.036,.051,.046,.002),(-.16,.057,.078,.067,.004),(0,.081,.103,.084,.006),(.15,.103,.103,.082,.006),(.28,.115,.066,.067,0),(.37,.109,.043,.047,-.002),(.448,.086,.027,.032,-.005),(.490,.061,.015,.024,-.007),(.506,.010,.005,.010,-.013)],
 'skin':{'back':(.22,.20,.095),'side':(.55,.45,.22),'belly':(.79,.70,.44),'pattern':'mottle','mottle_amount':.24,'variation':.08},
 'custom_skin':fine_mottling,'roughness':.48,'fin_color':(.40,.36,.19),'swim_amplitude':.82,
 'morphology':['Exceptionally broad flattened head with small dorsolateral eyes','Protruding lower jaw, large mouth and eight barbels','Mottled ochre-brown scaleless skin','Nearly square caudal fin, small separate adipose and rounded anal'],
 'sources':['https://www.nps.gov/miss/learn/nature/channel-catfish-ictalurus-punctatus-and-flathead-catfish-pylodictis-olivaris.htm','https://www.mdwfp.com/fishing-boating/fish-id-guide/flathead-catfish']}

def anatomy(f):
 f.fin('Dorsal',[f.surface(float(x),0,-.0015) for x in np.linspace(.19,.03,14)],[(.19,0,.096),(.166,0,.203),(.085,0,.173),(.03,0,.11)],parent='spine_front',rays=13)
 adipose_lobe(f,'Adipose',-.217,-.349,.034,.007,(.36,.32,.17))
 f.fin('Anal',[f.surface(float(x),math.pi,-.0015) for x in np.linspace(-.12,-.31,16)],[(-.12,0,-.068),(-.15,0,-.125),(-.251,0,-.118),(-.31,0,-.066)],parent='spine_rear',rays=18)
 f.fin('Caudal',[(-.378,0,-.036),(-.38,0,0),(-.378,0,.037)],[(-.505,0,-.105),(-.529,0,-.073),(-.524,0,0),(-.529,0,.081),(-.505,0,.116)],bone='caudal',parent='tail',rays=25)
 jawmat=f.material('FlatheadJawSkin',(.61,.52,.31),.49)
 f.ellipsoid('BroadProtrudingJaw',(.478,0,-.025),(.037,.071,.016),jawmat,'jaw')
 mouth=[(.462,-.072,-.015),(.486,-.046,-.013),(.503,0,-.011),(.486,.046,-.013),(.462,.072,-.015)]
 f.tube('BroadMouthCleft',mouth,.0022,f.mats['dark'],'head',9)
 f.tube('LowerJawRim',[(x+.003,y,z-.004) for x,y,z in mouth],.003,jawmat,'jaw',9)
 for s in (-1,1):
  tag='L' if s<0 else 'R'
  f.fin('Pectoral'+tag,[f.surface(float(x),s*2.03,-.0015) for x in np.linspace(0.255,0.183,14)],[(.255,s*.099,-.031),(.165,s*.192,-.076),(.067,s*.162,-.097),(.095,s*.119,-.096),(.183,s*.092,-.049)],parent='spine_front',rays=17)
  f.fin('Pelvic'+tag,[f.surface(float(x),s*2.47,-.0015) for x in np.linspace(-0.014,-0.052,14)],[(-.014,s*.056,-.065),(-.09,s*.125,-.12),(-.15,s*.089,-.12),(-.052,s*.058,-.065)],parent='spine_mid',rays=13)
  f.eye('SmallEye'+tag,f.surface(.396,s*1.10,.001),(0,s*.91,.40),.0078,iris=(.57,.43,.19))
  f.gill(tag,[f.surface(.259+.025*((t-1.15)/1.04)**2,s*t,.001) for t in np.linspace(.3,2.3,30)],.0014)
  whisker(f,'MaxillaryBarbel'+tag,[(.473,s*.062,-.012),(.428,s*.111,-.018),(.341,s*.154,-.051),(.246,s*.159,-.084),(.19,s*.14,-.102)],[.004,.0033,.0022,.0011,.0002],f.mats['edge'],'head')
  whisker(f,'NasalBarbel'+tag,[(.452,s*.047,.013),(.46,s*.061,.034),(.443,s*.076,.063),(.413,s*.083,.072)],[.0018,.0015,.0009,.0002],f.mats['edge'],'head')
  whisker(f,'OuterChinBarbel'+tag,[(.466,s*.047,-.039),(.435,s*.071,-.067),(.381,s*.09,-.105),(.323,s*.091,-.125)],[.0024,.0019,.001,.00018],f.mats['lip'],'jaw')
  whisker(f,'InnerChinBarbel'+tag,[(.482,s*.02,-.04),(.463,s*.029,-.067),(.421,s*.037,-.095),(.397,s*.039,-.104)],[.002,.0017,.0008,.00016],f.mats['lip'],'jaw')
