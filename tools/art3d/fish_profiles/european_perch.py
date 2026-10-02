"""Perca fluviatilis: separate spiny/soft dorsals, flank bars, orange lower fins."""
import math,numpy as np
from fish_profiles._freshwater import paired_fin,median_fin,caudal,eye_pair,gill_pair,small_mouth,jaw_loft
PROFILE={'id':'european_perch','sections':[(-.36,.015,.031,.027,0),(-.28,.027,.060,.047,0),(-.17,.048,.091,.068,.002),(-.035,.069,.132,.099,.004),(.10,.074,.155,.108,.008),(.22,.069,.146,.096,.009),(.313,.055,.100,.068,.003),(.401,.033,.052,.030,-.002),(.475,.013,.016,.013,-.004)],'skin':{'back':(.13,.23,.11),'side':(.54,.61,.25),'belly':(.78,.80,.58),'pattern':'fine_scales','scale_columns':62,'scale_rows':29,'feature':'bars','bar_count':7,'bar_strength':.72,'bar_sharpness':5,'variation':.06},'fin_color':(.77,.28,.063),'roughness':.46,'head_start':.78,'head_end':.88,'morphology':['Seven dark vertical flank bars on yellow-green body','Two separated dorsal fins, tall hard-spined front dorsal','Single dark spot toward rear of first dorsal','Orange-red lower fins and tail, no barbels','Humped anterior back and moderately large terminal mouth'],'sources':['https://www.fishbase.se/summary/358']}
def anatomy(f):
 dorsal=f.material('PerchOliveDorsal',(.43,.47,.28),.51)
 from build_fish import packed_image
 u,v=np.meshgrid(np.arange(1024)/1024,np.arange(512)/512);color=np.ones((512,1024,3))*np.array([.43,.47,.28]);mask=np.exp(-2*(((u-.89)/.10)**2+((v-.61)/.24)**2));color=color*(1-mask[:,:,None]*.98)+np.array([.016,.024,.013])*mask[:,:,None]*.98
 im=packed_image('PerchDorsalPosteriorMark',color);tex=dorsal.node_tree.nodes.new('ShaderNodeTexImage');tex.image=im;dorsal.node_tree.links.new(tex.outputs['Color'],dorsal.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
 dorsal_ray=f.material('PerchDorsalSpines',(.40,.43,.25),.51)
 roots=[f.surface(float(x),0,-.001) for x in np.linspace(.213,-.084,26)];edge=[]
 xs=np.linspace(.213,-.084,15)
 for i,x in enumerate(xs):
  base=f.surface(float(x),0,-.001);h=.065+.075*math.sin(math.pi*i/(len(xs)-1))
  edge.append((x,0,base.z+h))
  if i<len(xs)-1:edge.append(((x+xs[i+1])*.5,0,base.z+h-.025))
 f.fin('Dorsal_spiny',roots,edge,bone='dorsal_spiny',parent='spine_front',rays=31,material=dorsal,ray_material=dorsal_ray)
 for i,x in enumerate(xs):
  base=f.surface(float(x),0,-.001);h=.065+.075*math.sin(math.pi*i/(len(xs)-1));f.tube('DorsalSpine%02d'%i,[base,(x-.003,0,base.z+h*.6),(x,0,base.z+h+.003)],[.0016,.0010,.00025],dorsal_ray,'dorsal_spiny',7)
 soft_dorsal=f.material('PerchSoftDorsal',(.43,.47,.28),.51)
 median_fin(f,'Dorsal_soft',-.111,-.249,[(-.11,0,.11),(-.15,0,.202),(-.215,0,.172),(-.256,0,.063)],'spine_rear',21,soft_dorsal,ray_material=dorsal_ray)
 # The diagnostic rear black mark is baked into the membrane, never a floating button.
 median_fin(f,'Anal',-.14,-.258,[(-.14,0,-.076),(-.176,0,-.166),(-.246,0,-.130),(-.268,0,-.051)],'spine_rear',20,upper=False)
 caudal(f,-.357,.030,[(-.44,.105),(-.509,.127),(-.478,.066),(-.451,0),(-.482,-.061),(-.509,-.116),(-.440,-.100)],28)
 paired_fin(f,'Pectoral',.27,.224,2.03,.057,.086,-.090,'spine_front',20)
 paired_fin(f,'Pelvic',.171,.123,2.48,.046,.061,-.073,'spine_front',19)
 eye_pair(f,.355,1.12,.0111,(.71,.43,.08));gill_pair(f,.279,.0011,.036)
 jaw_loft(f,'PerchLowerJaw',[(.355,0,.036,.011,-.028),(.405,0,.029,.009,-.023),(.477,0,.011,.0035,-.011)])
 for sign in (-1,1):f.tube('PerchGape'+str(sign),[(.352,sign*.040,-.014),(.405,sign*.031,-.015),(.478,sign*.011,-.006)],.0011,f.mats['dark'],'head',7)
