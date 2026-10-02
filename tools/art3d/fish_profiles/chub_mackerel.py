"""Original Scomber anatomy: individually authored body, fin spacing and dorsal pattern."""
import math
import numpy as np

def dorsal_pigment(u,v,upper,color,height,rough):
 phase = u*math.tau*22 + 1.58*np.sin(v*math.tau*5) + .32*np.sin(v*math.tau*11) + .40*np.sin(u*47+v*13)
 waves=np.maximum(0,np.cos(phase))**3.5
 gate=np.clip((upper-.53)/.13,0,1)*np.clip((.84-u)/.05,0,1)
 color*=1-.79*waves[:,:,None]*gate[:,:,None]
 # Restrained narrow streak at lower boundary of dorsal bars.
 border=np.exp(-((upper-.535)/.013)**2)*np.clip((.84-u)/.07,0,1)
 color*=1-.20*border[:,:,None]
 return color,height,rough

PROFILE={'id': 'chub_mackerel',
 'sections': [(-0.404, 0.009, 0.013, 0.012, 0),
              (-0.345, 0.014, 0.022, 0.02, 0),
              (-0.254, 0.027, 0.041, 0.035, 0),
              (-0.129, 0.046, 0.064, 0.051, 0.001),
              (0.009, 0.06, 0.083, 0.065, 0.001),
              (0.135, 0.063, 0.087, 0.069, 0.002),
              (0.251, 0.053, 0.076, 0.059, 0.003),
              (0.345, 0.041, 0.059, 0.044, 0.004),
              (0.416, 0.027, 0.038, 0.027, 0.004),
              (0.477, 0.014, 0.018, 0.013, 0.003),
              (0.496, 0.002, 0.004, 0.004, 0.002)],
 'skin': {'back': (0.09, 0.24, 0.3),
          'side': (0.59, 0.67, 0.68),
          'belly': (0.84, 0.87, 0.82),
          'pattern': 'fine_scales',
          'scale_columns': 116,
          'scale_rows': 58,
          'variation': 0.012},
 'fin_color': (0.34, 0.41, 0.4),
 'normal_strength': 0.06,
 'roughness': 0.34,
 'specular': 0.39,
 'coat': 0.09,
 'swim_amplitude': 0.9,
 'morphology': ['Fuller spindle body with deeper belly and a proportionally large eye',
                'Nine-to-ten-spined first dorsal base longer than the inter-dorsal gap',
                'Two main dorsals, five dorsal and five anal finlets; short pectorals and deep forked tail',
                'Two small keels per side of peduncle and no large central tuna keel',
                'Complex zigzag blue-green dorsal pattern and spotless Pacific silver belly'],
 'sources': ['https://www.fao.org/4/ac478e/ac478e08.pdf', 'https://www.fishbase.se/summary/Scomber_japonicus.html']}
PROFILE['custom_skin']=dorsal_pigment

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
 _attach(f,'FirstDorsal',[f.surface(float(x),0,-.001) for x in np.linspace(0.243,0.02,18)],[(0.243, 0, 0.077), (0.216, 0, 0.178), (0.18, 0, 0.16), (0.129, 0, 0.121), (0.07, 0, 0.094), (0.02, 0, 0.084)],parent='spine_front',rays=14)
 _attach(f,'SecondDorsal',[f.surface(float(x),0,-.001) for x in np.linspace(-0.104,-0.207,18)],[(-0.104, 0, 0.071), (-0.128, 0, 0.111), (-0.163, 0, 0.092), (-0.207, 0, 0.048)],parent='spine_rear',rays=15)
 _attach(f,'MainAnal',[f.surface(float(x),math.pi,-.001) for x in np.linspace(-0.112,-0.211,18)],[(-0.112, 0, -0.053), (-0.142, 0, -0.092), (-0.178, 0, -0.072), (-0.211, 0, -0.041)],parent='spine_rear',rays=15)
 # Exactly five anatomically separated finlets above and below the peduncle.
 for idx,x in enumerate(np.linspace(-.233,-.371,5)):
  x=float(x)
  for sign,name,theta in [(1,'DorsalFinlet',0),(-1,'AnalFinlet',math.pi)]:
   a=f.surface(x,theta,-.0007);b=f.surface(x-.024,theta,-.0007)
   _attach(f,name+str(idx+1),[a,b],[(a.x,a.y,a.z),(x-.011,0,a.z+sign*(.019-idx*.0015)),(b.x,b.y,b.z)],parent='tail' if x<-.30 else 'spine_rear',rays=5)
 _attach(f,'DeepForkedCaudal',[(-.403,0,-.012),(-.408,0,0),(-.403,0,.013)],[(-.440,0,-.040),(-.539,0,-.116),(-.516,0,-.061),(-.450,0,0),(-.516,0,.061),(-.539,0,.116),(-.440,0,.040)],bone='caudal',parent='tail',rays=27)
 keel=f.material('MinorCaudalKeels',(.40,.49,.49),.43)
 for s in (-1,1):
  tag='L' if s<0 else 'R'
  for j,theta in enumerate((1.12,2.02)):
   pts=[f.surface(float(x),s*theta,.0007) for x in np.linspace(-.302,-.404,12)]
   # Low paired ridges, never the prominent tuna central keel.
   f.tube('MinorKeel'+tag+str(j),pts,[.0008+.0013*math.sin(i/11*math.pi) for i in range(12)],keel,'spine',5)
  _attach(f,'ShortPectoral'+tag,[f.surface(0.289,s*1.52,-.0006),f.surface(0.254,s*1.89,-.0006)],[( 0.289,s*.041,-.002),(0.2,s*.083,-.022),(0.15,s*.094,-.040),(0.2,s*.063,-.052),(0.254,s*.044,-.027)],parent='spine_front',rays=16)
  _attach(f,'Pelvic'+tag,[f.surface(0.183,s*2.77,-.0005),f.surface(0.153,s*2.75,-.0005)],[f.surface(0.183,s*2.77,-.0005),(0.143,s*.042,-.107),(0.103,s*.033,-.105),f.surface(0.153,s*2.75,-.0005)],parent='spine_front',rays=9)
  f.eye('AdiposeRimEye'+tag,f.surface(0.415,s*1.16,.0008),(0,s*.96,.28),0.0146,iris=(.58,.59,.43))
  f.gill(tag,[f.surface(0.3+.022*((t-1.38)/1.1)**2,s*t,.0008) for t in np.linspace(.39,2.68,29)],.001)
  mouth=[f.surface(float(x),s*(1.59+(.484-x)*4.4),.0006) for x in np.linspace(.484,.407,22)]
  f.tube('ObliqueMouth'+tag,mouth,.0015,f.mats['dark'],'head',7)
  f.tube('LowerLip'+tag,[(x,y,z-.0015) for x,y,z in mouth],.0016,f.mats['lip'],'jaw',7)
  f.ellipsoid('Nostril'+tag,f.surface(.463,s*.98,.0007),(.0018,.0013,.001),f.mats['dark'])
 f.tube('TerminalJaw',[(.479,-.013,0),(.500,0,-.001),(.479,.013,0)],.0018,f.mats['edge'],'head',7)
