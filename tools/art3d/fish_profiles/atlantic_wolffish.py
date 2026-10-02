"""Original Anarhichas lupus: muscular broad head, canine dentition, no pelvic fins."""
import math
import numpy as np

def wolf_skin(u,v,upper,color,height,rough):
 phase=u*math.tau*9.2+.42*np.sin(v*math.tau*2)+.24*np.sin(u*47)+.12*np.sin(v*61+u*29)
 bars=np.clip((np.cos(phase)-.22)*1.6,0,1)*np.clip((.79-u)/.06,0,1)*np.clip((upper-.10)/.20,0,1)
 color*=1-bars[:,:,None]*.57
 # Irregular pores are subtle; wolffish never gets a conspicuous scale grid.
 pores=np.maximum(0,np.sin(u*517+v*67)*np.cos(v*397-u*89)-.66)
 color*=1-pores[:,:,None]*.13
 height+=pores*.025
 return color,height,rough
PROFILE={
 'id':'atlantic_wolffish',
 'sections':[(-.399,.009,.025,.023,0),(-.33,.019,.037,.031,0),(-.23,.027,.044,.036,.001),(-.09,.037,.055,.040,.003),(.06,.052,.073,.049,.004),(.19,.069,.093,.061,.006),(.30,.089,.100,.066,.009),(.39,.091,.090,.058,.009),(.454,.074,.067,.037,.018),(.494,.043,.035,.008,.029),(.511,.012,.012,.004,.031)],
 'skin':{'back':(.23,.28,.32),'side':(.44,.48,.49),'belly':(.67,.68,.64),'pattern':'smooth','variation':.055},
 'custom_skin':wolf_skin,'fin_color':(.29,.33,.34),'normal_strength':.12,'roughness':.43,'swim_amplitude':1.17,
 'morphology':['Large rounded muscular head tapering to a long eel-like trunk','Long continuous soft-spined dorsal and long anal fin; rounded caudal separated by small gap','Broad rounded paired pectorals; pelvic fins entirely absent','Canine-like front teeth and smaller crushing teeth in a strong lower jaw','Blue-grey body with dark irregular vertical bands'],
 'sources':['https://www.fisheries.noaa.gov/species/atlantic-wolffish','https://www.greateratlantic.fisheries.noaa.gov/public/public/web/NEROINET/prot_res/CandidateSpeciesProgram/atlanticwolffish_detailed.pdf','https://www.marlin.ac.uk/species/detail/1747']}

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
 _attach(f,'ContinuousDorsal',[f.surface(float(x),0,-.0013) for x in np.linspace(.30,-.397,55)],[(.30,0,.109),(.239,0,.151),(.125,0,.144),(-.019,0,.128),(-.171,0,.106),(-.295,0,.087),(-.372,0,.064),(-.399,0,.026)],parent='spine_mid',rays=61)
 _attach(f,'LongAnal',[f.surface(float(x),math.pi,-.0013) for x in np.linspace(.029,-.394,35)],[(.029,0,-.047),(-.01,0,-.085),(-.153,0,-.085),(-.294,0,-.071),(-.371,0,-.052),(-.394,0,-.025)],parent='spine_rear',rays=42)
 _attach(f,'RoundedCaudal',[(-.400,0,-.023),(-.405,0,0),(-.400,0,.025)],[(-.429,0,-.047),(-.488,0,-.046),(-.513,0,-.024),(-.519,0,.004),(-.503,0,.033),(-.471,0,.053),(-.428,0,.050)],bone='caudal',parent='tail',rays=23)
 lip=f.material('WolfJawGrey',(.44,.46,.43),.49)
 for s in (-1,1):
  tag='L' if s<0 else 'R'
  _attach(f,'BroadPectoral'+tag,[(.256,s*.077,.016),(.245,s*.080,-.019),(.239,s*.065,-.045)],[(.256,s*.077,.016),(.207,s*.164,.011),(.160,s*.192,-.011),(.136,s*.181,-.044),(.157,s*.145,-.086),(.205,s*.095,-.081),(.239,s*.065,-.045)],parent='spine_front',rays=23)
  f.eye('Eye'+tag,f.surface(.410,s*.94,.001),(0,s*.79,.62),.0102,iris=(.38,.35,.24))
  f.gill(tag,[f.surface(.247+.036*((t-1.4)/.95)**2,s*t,.0011) for t in np.linspace(.43,2.5,27)],.0018)
  f.ellipsoid('Nostril'+tag,f.surface(.472,s*.79,.001),(.0035,.0025,.0018),f.mats['dark'])
 # Independent stout lower-jaw volume leaves a real front mouth gap below upper snout.
 f.ellipsoid('LowerJaw',(.438,0,-.040),(.071,.064,.025),lip,'jaw')
 # A concave open cavity, not a glossy black sphere pasted onto the snout.
 cavity=f.material('RecessedOralTissue',(.025,.022,.020),.88)
 cavity.node_tree.nodes.get('Principled BSDF').inputs['Specular IOR Level'].default_value=.10
 verts=[];faces=[];nr=7;nt=40
 for i in range(nr+1):
  r=max(.001,i/nr)
  for j in range(nt):
   t=j*math.tau/nt;rimx=.506-.040*abs(math.sin(t))
   verts.append((.444+(rimx-.444)*r*r,.054*r*math.sin(t),-.014+.025*r*math.cos(t)))
 for i in range(nr):
  for j in range(nt):
   a=i*nt+j;b=i*nt+(j+1)%nt;faces.append((a,b,b+nt,a+nt))
 f.mesh('RecessedOpenMouth',verts,faces,cavity,weight='head')
 upper=[];lower=[]
 for t in np.linspace(-math.pi/2,math.pi/2,30):
  y=.055*math.sin(t);x=.507-.040*abs(math.sin(t))
  upper.append((x,y,.010+.010*abs(math.sin(t))))
  lower.append((x-.004,y,-.036-.010*abs(math.sin(t))))
 f.tube('UpperFleshyLip',upper,.0041,lip,'head',9)
 f.tube('LowerFleshyLip',lower,.0043,lip,'jaw',9)
 for s in (-1,1):
  # Thick tapered curved front canines and smaller posterior crushing teeth.
  for j,y in enumerate((.013,.036)):
   x=.506-j*.014;z=.008
   f.tube('UpperCanine%d_%d'%(s,j),[(x,s*y,z),(x+.001,s*y*.98,z-.014),(x-.006,s*y*.94,z-.031)], [.0042,.003,.0004],f.mats['tooth'],'head',9)
   f.tube('LowerCanine%d_%d'%(s,j),[(x-.007,s*y,-.037),(x-.004,s*y*.98,-.022),(x-.008,s*y*.94,-.007)],[.0046,.0031,.00045],f.mats['tooth'],'jaw',9)
  for j in range(4):
   f.ellipsoid('Molar%d_%d'%(s,j),(.454-j*.010,s*(.046-j*.002),-.027),(.005,.004,.007),f.mats['tooth'],'jaw')
