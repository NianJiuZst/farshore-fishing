"""Shared small anatomical authoring helpers, not a complete fish template.
Each species authors its own body loft, fin layout, mouth, pigment and diagnostic features.
"""
import math
import numpy as np
from mathutils import Vector

def paired_fin(f,name,xfront,xrear,theta,extension,sweep,drop,parent='spine_front',rays=18,material=None):
    for sign,tag in [(-1,'R'),(1,'L')]:
        roots=[f.surface(float(x),sign*theta,-.0012) for x in np.linspace(xfront,xrear,11)]
        middle=roots[len(roots)//2];edge=[roots[0],middle+Vector((-sweep*.4,sign*extension*.72,drop*.65)),middle+Vector((-sweep,sign*extension,drop)),roots[-1]+Vector((-sweep*.42,sign*extension*.20,drop*.30)),roots[-1]]
        f.fin(name+'_'+tag,roots,edge,parent=parent,rays=rays,material=material)

def median_fin(f,name,xfront,xrear,edge,parent='spine_mid',rays=20,material=None,upper=True,ray_material=None):
    roots=[f.surface(float(x),0 if upper else math.pi,-.001) for x in np.linspace(xfront,xrear,18)]
    f.fin(name,roots,edge,parent=parent,rays=rays,material=material,ray_material=ray_material)

def caudal(f,root_x,root_half,outline,rays=27):
    cap_x=f.sections[0][0]+.0015
    roots=[f.surface(cap_x,0,-.0006),(cap_x,0,f.surface(cap_x,math.pi/2).z),f.surface(cap_x,math.pi,-.0006)]
    f.fin('Caudal',roots,[(x,0,z) for x,z in outline],bone='caudal',parent='tail',rays=rays)

def eye_pair(f,x,theta=1.15,radius=.010,iris=(.43,.34,.13)):
    for sign,tag in [(-1,'R'),(1,'L')]:
        p=f.surface(x,sign*theta,.0004);f.eye('Eye_'+tag,p,(0,sign*math.sin(theta),math.cos(theta)),radius,iris)

def gill_pair(f,x,width=.001,reach=.033):
    for sign,tag in [(-1,'R'),(1,'L')]:
        pts=[f.surface(x-reach*math.sin(math.pi*t),sign*(.38+2.27*t),.0006) for t in np.linspace(0,1,32)]
        f.gill(tag,pts,width)

def small_mouth(f,x,width,z,angle=0,radius=.0015):
    # Subtle upper and lower lips following a shallow forward-facing arc.
    upper=[];lower=[]
    for t in np.linspace(0,math.pi,24):
        y=width*math.cos(t);xx=x+.0028*math.sin(t);zz=z+angle*(xx-x)
        upper.append((xx,y,zz+.0034*math.sin(t)));lower.append((xx,y,zz-.0037*math.sin(t)))
    f.tube('MouthCrease',[(x, -width, z),(x+.002,0,z),(x,width,z)],radius*.75,f.mats['dark'],'head',7)
    f.tube('UpperLip',upper,radius,f.mats['lip'],'head',8);f.tube('LowerLip',lower,radius,f.mats['lip'],'jaw',8)

def jaw_loft(f,name,sections,material=None):
    # x, center_y, half_width, half_height, center_z, increasing x.
    a=np.array(sections);n,m=38,28;verts=[];faces=[];uv=[]
    for i,x in enumerate(np.linspace(a[0,0],a[-1,0],n+1)):
        cy,w,h,z=[np.interp(x,a[:,0],a[:,k]) for k in range(1,5)]
        for j in range(m+1):
            t=math.tau*j/m;verts.append((x,cy+w*math.sin(t),z+h*math.cos(t)));uv.append(((x-f.sections[0][0])/(f.sections[-1][0]-f.sections[0][0]),j/m))
    for i in range(n):
        for j in range(m):k=i*(m+1)+j;faces.append((k,k+1,k+m+2,k+m+1))
    faces.extend((tuple(reversed(range(m+1))),tuple(n*(m+1)+j for j in range(m+1))))
    return f.mesh(name,verts,faces,material or f.mats['skin'],uv,'jaw')

def taper_barbel(f,name,points,radius=.002,weight='jaw'):
    from build_fish import resample
    dense=resample(points,21);f.tube(name,dense,np.linspace(radius,.0002,len(dense)).tolist(),f.mats['lip'],weight,8)
