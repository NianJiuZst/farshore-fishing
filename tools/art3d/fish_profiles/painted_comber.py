"""Serranus scriba: original pointed Mediterranean serranid, blue belly patch and head tracery."""
import math
import numpy as np
from mathutils import Vector
from fish_profiles.japanese_whiting import paired,median,caudal,eyes,gills,mouth,crest

def pigment(u,v,upper,color,height,rough):
    bars=np.maximum(0,np.cos(u*math.tau*7.3+np.sin(v*17)*.16))**5*np.clip((.78-u)*12,0,1)*np.clip((u-.15)*20,0,1)
    color*=1-.68*bars[:,:,None]
    blue=np.exp(-((u-.47)/.14)**4-((upper-.32)/.16)**4)
    color=color*(1-blue[:,:,None]*.90)+np.array([.30,.49,.80])*blue[:,:,None]*.90
    head=np.clip((u-.73)/.07,0,1)
    wave=np.sin(v*81+u*45+np.sin(u*85)*1.6)
    ink=np.exp(-(wave/.18)**2)*head
    color=color*(1-ink[:,:,None]*.80)+np.array([.26,.46,.66])*ink[:,:,None]*.80
    red=np.exp(-((wave-.48)/.15)**2)*head
    color=color*(1-red[:,:,None]*.58)+np.array([.72,.24,.13])*red[:,:,None]*.58
    yellow=np.clip((.14-u)/.10,0,1)
    color=color*(1-yellow[:,:,None]*.65)+np.array([.76,.64,.19])*yellow[:,:,None]*.65
    return color,height,rough
PROFILE={'id':'painted_comber','sections':[(-.351,.019,.034,.031,0),(-.269,.030,.060,.049,0),(-.157,.045,.099,.078,.002),(-.024,.060,.131,.101,.005),(.109,.067,.150,.106,.006),(.235,.063,.137,.092,.005),(.324,.051,.098,.062,.001),(.405,.033,.046,.028,-.002),(.482,.016,.013,.012,-.012)],'skin':{'back':(.61,.37,.24),'side':(.81,.59,.37),'belly':(.82,.74,.52),'pattern':'fine_scales','scale_columns':71,'scale_rows':32,'variation':.035},'custom_skin':pigment,'fin_color':(.74,.59,.24),'roughness':.44,'normal_strength':.19,'head_start':.75,'head_end':.86,'morphology':['Elongated slightly deep-bellied compressed serranid with pointed straight head','Six prominent brown flank bands, pale blue belly patch and red-blue head tracery','Yellow tail and peduncle, continuous spiny-soft dorsal','Large mouth with three small opercular spines and thoracic pelvic fins'],'sources':['https://doris.ffessm.fr/Especes/Serranus-scriba-Serran-ecriture-144']}
def anatomy(f):
    crest(f,'DorsalSpiny',.251,-.086,[.020,.058,.074,.080,.076,.069,.061,.051,.042],notch=.029)
    dorsal=f.material('ComberWarmDorsal',(.64,.40,.25),.48)
    median(f,'DorsalSoft',-.088,-.283,[(-.088,0,.149),(-.129,0,.205),(-.219,0,.172),(-.284,0,.052)],'spine_rear',25,material=dorsal)
    median(f,'Anal',-.129,-.266,[(-.129,0,-.084),(-.162,0,-.147),(-.223,0,-.137),(-.267,0,-.043)],'spine_rear',19,upper=False)
    caudal(f,[(-.389,.058),(-.489,.089),(-.514,.050),(-.512,0),(-.514,-.049),(-.488,-.087),(-.389,-.054)],27)
    paired(f,'Pectoral',.273,.221,1.95,.056,.106,-.046,rays=20)
    paired(f,'Pelvic',.236,.192,2.52,.040,.081,-.056,rays=15)
    eyes(f,.373,1.12,.0182,(.76,.40,.12));gills(f,.285,.033,.0011)
    f.ellipsoid('MouthCavity',(.484,0,-.012),(.0025,.015,.012),f.mats['dark'],'head')
    f.ellipsoid('LowerJaw',(.448,0,-.026),(.048,.023,.012),f.mats['skin'],'jaw')
    for sign,tag in ((-1,'R'),(1,'L')):
        f.tube('MouthCrease'+tag,[(.487,sign*.013,-.007),(.443,sign*.029,-.017),(.371,sign*.049,-.030)],[.0018,.0020,.0010],f.mats['dark'],'head',8)
        f.tube('LowerLip'+tag,[(.493,0,-.016),(.481,sign*.015,-.025),(.426,sign*.029,-.038),(.373,sign*.040,-.035)],[.0018,.0022,.0018,.0010],f.mats['lip'],'jaw',8)
        for th in (.83,1.23,1.59):
            p=f.surface(.273,sign*th,.001);f.tube('OpercularSpine'+tag+str(th),[p,p+Vector((-.019,sign*.005,.002))],[.0019,.0002],f.mats['edge'],'head',7)
