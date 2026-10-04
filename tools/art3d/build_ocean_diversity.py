#!/usr/bin/env python3
"""Build 37 newly authored ocean animals without Blender or third-party meshes.

Inputs are the editable ocean_profiles.json and explicitly authored anatomical
features below. Outputs are self-contained glTF 2.0 binary meshes, packed PBR
textures, a hierarchical skin and four real skeletal animation clips.
No existing Farshore model, geometry, texture or rig is read by this builder.
Python 3 standard library + Pillow only. Run from any directory:
  python3 tools/art3d/build_ocean_diversity.py --species all
"""
import argparse
import hashlib
import io
import json
import math
import random
import struct
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PROFILE_FILE = Path(__file__).with_name("ocean_profiles.json")
OUT = ROOT / "game/assets/3d"
REVIEW = ROOT / "ownbuild/ocean-model-review"
TAU = math.tau


def add(a, b): return tuple(x + y for x, y in zip(a, b))
def sub(a, b): return tuple(x - y for x, y in zip(a, b))
def mul(a, s): return tuple(x * s for x in a)
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def cross(a, b): return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def unit(a): return mul(a, 1/max(1e-12, math.sqrt(dot(a, a))))
def lerp(a, b, t): return tuple(x*(1-t)+y*t for x, y in zip(a, b))
def clamp(v, lo=0.0, hi=1.0): return min(hi, max(lo, v))
def hexcolor(s): return tuple(int(s[i:i+2], 16)/255 for i in (0, 2, 4))


class Part:
    def __init__(self, name, material):
        self.name, self.material = name, material
        self.vertices, self.uv, self.weights, self.faces = [], [], [], []

    def vertex(self, p, uv=(0, 0), weight="spine"):
        self.vertices.append(tuple(p)); self.uv.append(tuple(uv)); self.weights.append(weight)
        return len(self.vertices)-1

    def tri(self, a, b, c): self.faces.append((a, b, c))

    def normals(self):
        result = [[0.0, 0.0, 0.0] for _ in self.vertices]
        for a, b, c in self.faces:
            n = cross(sub(self.vertices[b], self.vertices[a]), sub(self.vertices[c], self.vertices[a]))
            for k in (a, b, c):
                for j in range(3): result[k][j] += n[j]
        return [unit(n) if dot(n,n)>0 else (0,1,0) for n in result]


class Animal:
    def __init__(self, profile):
        self.p = profile; self.parts = []; self.features = []
        self.rings = profile["rings"]
        # An authored axis chain works for long eels as well as rigid reef fish.
        self.bones = []
        self.bone("root", (0, 0, 0), None)
        self.bone("head", (.31, 0, 0), "root")
        self.bone("spine_front", (.17, 0, 0), "root")
        self.bone("spine_mid", (.025, 0, 0), "spine_front")
        self.bone("spine_rear", (-.12, 0, 0), "spine_mid")
        self.bone("tail_base", (-.255, 0, 0), "spine_rear")
        self.bone("tail_mid", (-.37, 0, 0), "tail_base")
        self.bone("tail_tip", (-.47, 0, 0), "tail_mid")
        self.bone("jaw", (.32, -.04, 0), "head")
        if profile["kind"] not in ("whale", "ray"):
            self.bone("gill_L", (.25, -.015, .045), "head")
            self.bone("gill_R", (.25, -.015, -.045), "head")
        self.axial = [("head", .31), ("spine_front", .17), ("spine_mid", .025),
                      ("spine_rear", -.12), ("tail_base", -.255),
                      ("tail_mid", -.37), ("tail_tip", -.47)]

    def bone(self, name, origin, parent):
        if any(b["name"] == name for b in self.bones): return name
        self.bones.append({"name": name, "origin": tuple(origin), "parent": parent})
        return name

    def part(self, name, material):
        part = Part(name, material); self.parts.append(part); self.features.append(name)
        return part

    def interp(self, x):
        arr = self.rings
        if x <= arr[0][0]: return arr[0][1:]
        if x >= arr[-1][0]: return arr[-1][1:]
        for i, (a, b) in enumerate(zip(arr, arr[1:])):
            if a[0] <= x <= b[0]:
                t=(x-a[0])/(b[0]-a[0]); out=[]
                for j in range(1, 5):
                    p0=arr[max(0, i-1)]; p3=arr[min(len(arr)-1, i+2)]
                    m1=(b[j]-p0[j])/(b[0]-p0[0]); m2=(p3[j]-a[j])/(p3[0]-a[0])
                    v=(2*t**3-3*t*t+1)*a[j]+(t**3-2*t*t+t)*(b[0]-a[0])*m1+(-2*t**3+3*t*t)*b[j]+(t**3-t*t)*(b[0]-a[0])*m2
                    out.append(max(.00015, v) if j<4 else v)
                return out
        raise AssertionError(x)

    def surface(self, x, angle, inflate=0):
        w, top, bottom, center=self.interp(x); c, s=math.cos(angle), math.sin(angle)
        power=self.p.get("cross_section_power", 1.0)
        c=math.copysign(abs(c)**power, c); s=math.copysign(abs(s)**power, s)
        return (x, center+(top if c>=0 else bottom)*c+inflate*c, (w+inflate)*s)

    def body(self):
        part=self.part("AuthoredVolumetricBody", "skin")
        n=self.p.get("longitudinal_segments", 88); m=48
        lo, hi=self.rings[0][0], self.rings[-1][0]
        for i in range(n+1):
            x=lo+(hi-lo)*i/n
            for j in range(m+1):
                part.vertex(self.surface(x, TAU*j/m), (i/n, j/m))
        for i in range(n):
            for j in range(m):
                a=i*(m+1)+j; part.tri(a, a+1, a+m+2); part.tri(a, a+m+2, a+m+1)
        for start, reverse in ((0, True), (n*(m+1), False)):
            center=part.vertex((lo if reverse else hi, self.interp(lo if reverse else hi)[3], 0), (.0 if reverse else 1, .5))
            for j in range(m):
                part.tri(center, start+j+1 if reverse else start+j, start+j if reverse else start+j+1)

    def sphere(self, name, origin, scale, material, weight="head", seg=24, rows=12):
        part=self.part(name, material)
        for i in range(rows+1):
            lat=math.pi*i/rows
            for j in range(seg+1):
                a=TAU*j/seg
                part.vertex((origin[0]+scale[0]*math.sin(lat)*math.cos(a),
                             origin[1]+scale[1]*math.cos(lat),
                             origin[2]+scale[2]*math.sin(lat)*math.sin(a)), (j/seg, i/rows), weight)
        for i in range(rows):
            for j in range(seg):
                k=i*(seg+1)+j
                if i>0: part.tri(k, k+1, k+seg+2)
                if i<rows-1: part.tri(k, k+seg+2, k+seg+1)
        return part

    def tube(self, name, points, radius, material, weight="spine", sides=8):
        part=self.part(name, material)
        for i, p in enumerate(points):
            tangent=unit(sub(points[min(len(points)-1,i+1)], points[max(0,i-1)]))
            u=cross(tangent, (0,1,0))
            if dot(u,u)<.01: u=cross(tangent,(0,0,1))
            u=unit(u); v=unit(cross(tangent,u)); r=radius if isinstance(radius,(int,float)) else radius[i]
            for j in range(sides+1):
                a=TAU*j/sides
                part.vertex(add(p, add(mul(u,r*math.cos(a)), mul(v,r*math.sin(a)))),(j/sides, i/max(1,len(points)-1)),weight)
        for i in range(len(points)-1):
            for j in range(sides):
                k=i*(sides+1)+j; part.tri(k,k+1,k+sides+2); part.tri(k,k+sides+2,k+sides+1)
        for i, reverse in ((0, True),(len(points)-1, False)):
            center=part.vertex(points[i],(.5,i/max(1,len(points)-1)),weight); start=i*(sides+1)
            for j in range(sides): part.tri(center,start+j if reverse else start+j+1,start+j+1 if reverse else start+j)
        return part

    @staticmethod
    def sample(points, count):
        # Linear interpolation keeps authored spines/fin corners intentional.
        d=[0.0]
        for a,b in zip(points,points[1:]): d.append(d[-1]+math.sqrt(dot(sub(a,b),sub(a,b))))
        if d[-1]<1e-8: return [points[0]]*count
        out=[]
        for j in range(count):
            q=d[-1]*j/(count-1)
            i=next((i for i in range(len(d)-1) if d[i]<=q<=d[i+1]),len(d)-2)
            out.append(lerp(points[i],points[i+1],(q-d[i])/max(1e-12,d[i+1]-d[i])))
        return out

    def fin(self, name, roots, edge, rays=22, material="fin", parent=None, flutter=True):
        roots=self.sample(roots,rays); edge=self.sample(edge,rays)
        if parent is None: parent=min(self.axial,key=lambda v:abs(v[1]-sum(p[0] for p in roots)/rays))[0]
        bone=name.lower(); self.bone(bone, roots[rays//2],parent)
        if self.p["kind"]=="whale":
            # Mammal appendages are thick, rayless hydrofoils, not fish fin
            # membranes. Both shells and every boundary are closed geometry.
            part=self.part(name+"_SolidHydrofoil","skin");steps=8;layer=rays*steps
            for sign in (-1,1):
                for i,(root,tip) in enumerate(zip(roots,edge)):
                    for j in range(steps):
                        t=j/(steps-1);p=lerp(root,tip,t)
                        thickness=.0007+.005*math.sin(math.pi*t)*math.sin(math.pi*i/(rays-1))
                        thickness_vector=(0,0,sign*thickness) if name=="Dorsal" else (0,sign*thickness,0)
                        part.vertex(add(p,thickness_vector),(i/(rays-1),t),(bone,t*.65))
            for sign,offset in ((-1,0),(1,layer)):
                for i in range(rays-1):
                    for j in range(steps-1):
                        k=offset+i*steps+j
                        for tri in ((k,k+steps,k+steps+1),(k,k+steps+1,k+1)):
                            part.faces.append(tri if sign==1 else tuple(reversed(tri)))
            perimeter=list(range(steps))+[i*steps+steps-1 for i in range(1,rays)]+[(rays-1)*steps+j for j in range(steps-2,-1,-1)]+[i*steps for i in range(rays-2,0,-1)]
            for k,nextk in zip(perimeter,perimeter[1:]+perimeter[:1]):
                part.tri(k,nextk,nextk+layer);part.tri(k,nextk+layer,k+layer)
            return
        part=self.part(name+"_CamberedMembrane",material); steps=6
        for i,(root,tip) in enumerate(zip(roots,edge)):
            for j in range(steps):
                t=j/(steps-1); p=lerp(root,tip,t)
                camber=.0016*math.sin(math.pi*t)*math.sin(math.pi*i/(rays-1))
                # A convex membrane and raised fin rays have actual geometry.
                if abs(tip[2]-root[2])>abs(tip[1]-root[1]): p=add(p,(0,camber,0))
                else: p=add(p,(0,0,camber))
                part.vertex(p,(i/(rays-1),t),(bone,t*.65) if flutter else "spine")
        for i in range(rays-1):
            for j in range(steps-1):
                k=i*steps+j;part.tri(k,k+steps,k+steps+1);part.tri(k,k+steps+1,k+1)
        for i,(root,tip) in enumerate(zip(roots,edge)):
            self.tube(name+"_RaisedRay_%02d"%i,[lerp(root,tip,t/4) for t in range(5)],
                      [.00075*(1-t/4*.72) for t in range(5)],"ray",(bone,.55) if flutter else "spine",5)
        # A continuous fine rim removes a cut-paper edge at inspection distance.
        self.tube(name+"_SolidRim",edge,.00065,"ray",(bone,.55) if flutter else "spine",6)

    def fins(self):
        for f in self.p["fins"]:
            if f["kind"] in ("dorsal","anal"):
                direction=1 if f["kind"]=="dorsal" else -1
                lo,hi=f["range"]
                roots=[self.surface(lo+(hi-lo)*j/24,0 if direction==1 else math.pi,-.0008) for j in range(25)]
                edge=[(x,y,0) for x,y in f["edge"]]
                self.fin(f["name"],roots,edge,f.get("rays",25),flutter=f.get("flutter",True))
            elif f["kind"]=="caudal":
                x=f["root_x"]
                if self.p["kind"]=="flatfish":
                    roots=[self.surface(x,math.pi/2),(x,0,0),self.surface(x,-math.pi/2)]
                    edge=[(x,0,z) for x,z in f["edge"]]
                else:
                    roots=[self.surface(x,0),(x,0,0),self.surface(x,math.pi)]
                    edge=[(x,y,0) for x,y in f["edge"]]
                self.fin(f["name"],roots,edge,f.get("rays",27),parent="tail_tip")
            elif f["kind"]=="paired":
                for side in (-1,1):
                    if "attach_x" in f:
                        angle=side*f.get("attach_angle",1.87)
                        if self.p["kind"]=="flatfish":angle=f.get("attach_angle",.3) if side==1 else math.pi-f.get("attach_angle",.3)
                        roots=[self.surface(x,angle,-.0008) for x in f["attach_x"]]
                    else:roots=[(x,y,z*side) for x,y,z in f["roots"]]
                    edge=[(x,y*side if self.p["kind"]=="flatfish" else y,z*side) for x,y,z in f["edge"]]
                    self.fin(f["name"]+("_L" if side==1 else "_R"),roots,edge,f.get("rays",16),parent=f.get("parent"))
            elif f["kind"]=="flat_edge":
                side=f["side"];lo,hi=f["range"]
                roots=[self.surface(lo+(hi-lo)*j/30,side*math.pi/2,-.001) for j in range(31)]
                self.fin(f["name"],roots,[(x,0,z*side) for x,z in f["edge"]],f.get("rays",34),flutter=f.get("flutter",False))
            else: raise ValueError(f["kind"])

    def eyes(self):
        kind=self.p["kind"]
        if kind=="barreleye": return
        x,y,r=self.p["eye"]
        if kind in ("flatfish","ray"):
            for side in (-1,1):
                z=(.033 if kind=="ray" else .028)*side
                if kind=="flatfish": xoff=-.055 if side==-1 else 0; z+=(.015 if self.p["eyed_side"]=="right" else -.015)
                else: xoff=0
                yy=self.interp(x+xoff)[1]+self.interp(x+xoff)[3]
                self.sphere("OcularSocket_"+str(side),(x+xoff,yy,z),(r*1.4,r*.65,r*1.3),"crease")
                self.sphere("UpwardIris_"+str(side),(x+xoff,yy+r*.35,z),(r,r*.5,r),"iris")
                self.sphere("UpwardPupil_"+str(side),(x+xoff,yy+r*.78,z),(r*.46,r*.18,r*.52),"pupil")
        elif kind=="flathead":
            for side in (-1,1):
                z=side*.048; yy=self.interp(x)[1]+self.interp(x)[3]
                self.sphere("HighSetEyeSocket_"+str(side),(x,yy,z),(r*1.5,r,r*1.4),"skin")
                self.sphere("HighSetIris_"+str(side),(x+.003,yy+r*.55,z),(r,r*.5,r),"iris")
                self.sphere("HighSetPupil_"+str(side),(x+.004,yy+r*.88,z),(r*.5,r*.18,r*.52),"pupil")
        else:
            w,top,bot,cy=self.interp(x); z=w*math.sqrt(max(.15,1-((y-cy)/max(top,bot))**2))
            for side in (-1,1):
                self.sphere("RecessedEyeSocket_"+str(side),(x,y,z*side),(r*1.35,r*1.3,r*.42),"crease")
                self.sphere("Iris_"+str(side),(x+.0006,y,(z+r*.2)*side),(r,r,r*.28),"iris")
                self.sphere("Pupil_"+str(side),(x+.0012,y,(z+r*.44)*side),(r*.49,r*.58,r*.14),"pupil")
                self.sphere("EyeCatchlight_"+str(side),(x+r*.24,y+r*.31,(z+r*.58)*side),(r*.10,r*.1,r*.05),"glint",seg=12,rows=6)
                pts=[(x+r*1.16*math.cos(a*TAU/32),y+r*1.13*math.sin(a*TAU/32),(z+r*.18)*side) for a in range(33)]
                self.tube("RaisedOrbitalRim_"+str(side),pts,.00085,"ray","head",6)

    def face(self):
        kind=self.p["kind"]; mouth=self.p["mouth"]; x,y,w,h=mouth
        if kind not in ("whale","ray","barreleye"):
            self.sphere("OralCavity",(x-.003,y,0),(.006,h,w),"crease","jaw")
            for upper in (True,False):
                pts=[(x+.002*math.sin(t*math.pi/20),y+(1 if upper else -1)*h*math.sin(t*math.pi/20),w*math.cos(t*math.pi/20)) for t in range(21)]
                self.tube("UpperLip" if upper else "ArticulatedLowerLip",pts,self.p.get("lip_thickness",.002),"lip","head" if upper else "jaw",8)
        if kind not in ("whale","ray","barreleye","moray","flatfish"):
            gx=self.p.get("gill_x",.265)
            for side in (-1,1):
                pts=[self.surface(gx-.026*math.sin(t*math.pi/24),(.4+2.33*t/24)*side,.0005) for t in range(25)]
                self.tube("OperculumSeam_"+str(side),pts,.0014,"crease","gill_L" if side==1 else "gill_R",6)
                self.tube("SculptedOperculumRim_"+str(side),[add(p,(.003,0,0)) for p in pts],.0008,"ray","gill_L" if side==1 else "gill_R",6)
        if self.p.get("teeth"):
            for side in (-1,1):
                for j in range(self.p["teeth"]):
                    t=(j+.5)/self.p["teeth"]; xx=x-.008-.064*t; zz=side*w*(1-.35*t)
                    self.tube("FunctionalTooth_%s_%02d"%(side,j),[(xx,y-h*.35,zz),(xx+.001,y+h*.45,zz)],[.0015,.0001],"ivory","jaw",6)

    def anatomy(self):
        kind=self.p["kind"]; sid=self.p["id"]
        if kind=="barreleye":
            # These are actual upward green tubular eyes inside a transparent
            # fluid shield. The two black marks on the face are olfactory organs.
            for side in (-1,1):
                self.tube("GreenTubularEye_"+str(side),[(.245,.032,side*.033),(.247,.062,side*.033),(.25,.097,side*.033)], [.011,.013,.016],"green_eye","head",24)
                self.sphere("UpwardEyeLens_"+str(side),(.25,.098,side*.033),(.018,.009,.018),"green_eye")
                self.sphere("RealGreenEyePupil_"+str(side),(.252,.104,side*.033),(.010,.003,.010),"pupil")
                self.sphere("OlfactoryCapsule_"+str(side),(.403,.012,side*.028),(.013,.008,.009),"crease")
            self.sphere("TransparentCranialShield",(.265,.062,0),(.162,.102,.087),"glass","head",48,24)
            rim=[(.265+.158*math.cos(j*TAU/48),.043,.086*math.sin(j*TAU/48)) for j in range(49)]
            self.tube("ShieldAttachmentRim",rim,.0008,"ray","head",6)
        elif kind=="cowfish":
            for side in (-1,1):
                self.tube("AnteriorOrbitalHorn_"+str(side),[(.35,.076,side*.064),(.405,.124,side*.08),(.46,.172,side*.087)], [.013,.009,.0004],"ivory","head",12)
                self.tube("PosteriorArmorSpine_"+str(side),[(-.22,-.044,side*.083),(-.29,-.071,side*.10),(-.36,-.094,side*.104)], [.012,.007,.0005],"ivory","spine",12)
        elif kind=="moray":
            for side in (-1,1):
                self.tube("TubularAnteriorNaris_"+str(side),[(.454,.016,side*.030),(.462,.033,side*.033)], [.0028,.0021],"lip","head",10)
                self.sphere("SmallMorayGillOpening_"+str(side),(.278,-.024,side*.052),(.008,.012,.002),"crease")
        elif kind=="ray":
            self.tube("RibbonTail",[(-.17,0,0),(-.29,-.004,0),(-.43,-.006,0),(-.60,-.005,0)],[.012,.008,.0045,.001],"skin","spine",16)
            self.tube("TailVenomSpine",[(-.35,.003,0),(-.412,.015,0),(-.438,.021,0)],[.003,.0015,.00015],"ivory","tail_mid",8)
            for side in (-1,1):
                self.sphere("Spiracle_"+str(side),(.237,.031,side*.063),(.016,.003,.009),"crease")
                for i in range(5):
                    self.tube("VentralGillSlit_%s_%s"%(side,i),[(.17-i*.022,-.021,side*.063),(.17-i*.022,-.022,side*.096)],.0018,"crease","head",6)
            self.tube("VentralRayMouth",[(.305,-.026,-.024),(.311,-.029,0),(.305,-.026,.024)],.002,"crease","jaw",6)
        elif kind=="whale":
            # Flukes lie in XZ, unlike all ray-finned fish caudals.
            for side in (-1,1):
                roots=[(-.365,.005,0),(-.405,0,side*.03),(-.455,0,side*.014)]
                edge=[(-.385,0,side*.034),(-.407,.002,side*.080),(-.461,-.004,side*.121),(-.495,-.010,side*.103),(-.488,-.008,side*.045),(-.469,-.002,side*.009)]
                self.fin("HorizontalFluke"+("_L" if side==1 else "_R"),roots,edge,30,"skin",parent="tail_tip")
            for j in range(31):
                angle=math.pi+(-.69+j/30*1.38)
                points=[self.surface(.428-.61*i/40,angle,-.00035) for i in range(41)]
                self.tube("VentralRorqualPleat_%02d"%j,points,.00064,"crease","spine",5)
            for side in (-1,1):
                # Paired blowholes, raised nasal rims and a broad U-shaped snout.
                self.sphere("PairedBlowhole_"+str(side),(.335,.076,side*.009),(.014,.0015,.006),"crease")
                self.tube("BlowholeRim_"+str(side),[(.335+.014*math.cos(j*TAU/24),.077,side*.009+.006*math.sin(j*TAU/24)) for j in range(25)],.0008,"skin","head",6)
                pts=[self.surface(.477-.26*i/35,(math.pi/2+0.27)*side,.00035) for i in range(36)]
                self.tube("LongBaleenJawLine_"+str(side),pts,.001,"crease","jaw",6)
            self.tube("RostralMedianRidge",[self.surface(.46-.26*i/28,0,.0009) for i in range(29)],.0012,"skin","head",8)
        elif kind=="oarfish":
            # Ribbon body and continuous red dorsal, with long crown rays.
            for i in range(7):
                xx=.40-i*.016
                self.tube("ElongateRedCrownRay_%02d"%i,[(xx,.052,0),(xx-.015,.108+i*.004,0),(xx-.049,.19-i*.011,.003)], [.0018,.0013,.00025],"red","head",7)
            for side in (-1,1):
                self.tube("StreamingPelvicRay_"+str(side),[(.337,-.042,side*.007),(.29,-.096,side*.017),(.18,-.158,side*.019),(.11,-.165,side*.012)],[.0022,.0013,.0006,.00025],"red","jaw",7)
        elif kind=="cornetfish":
            self.tube("ElongateTubularSnout",[(.13,.008,0),(.25,.008,0),(.38,.007,0),(.506,.006,0)],[.012,.009,.0065,.005],"skin","head",20)
            self.tube("CaudalThread",[(-.46,0,0),(-.61,-.001,0),(-.77,-.004,0),(-.94,-.011,0)],[.0018,.0011,.00065,.0001],"ray","tail_tip",7)
        if self.p.get("barbels"):
            for side in (-1,1):
                x,y,w,h=self.p["mouth"]
                self.tube("PairedSensoryBarbel_"+str(side),[(x-.015,y-h,side*.012),(x-.053,y-h-.029,side*.022),(x-.12,y-h-.046,side*.028)], [.0024,.0014,.0003],"ivory","jaw",8)
        if self.p.get("free_pectoral_rays"):
            for side in (-1,1):
                for j in range(3):
                    self.tube("FreeWalkingPectoralRay_%s_%s"%(side,j),[(.24-j*.012,-.047,side*.038),(.207-j*.018,-.076,side*(.10+j*.018)),(.23-j*.025,-.123,side*(.13+j*.018))],[.0026,.002,.00045],"ray","pectoral_l" if side==1 else "pectoral_r",8)
        if self.p.get("beak"):
            self.sphere("FusedUpperParrotBeak",(.468,-.012,0),(.025,.019,.028),"ivory","head")
            self.sphere("FusedLowerParrotBeak",(.468,-.037,0),(.021,.015,.024),"ivory","jaw")
            self.tube("BeakOcclusion",[(.489,-.027,-.021),(.494,-.028,0),(.489,-.027,.021)],.001,"crease","jaw",6)
        if self.p.get("tubercles"):
            seed=random.Random(sid)
            for i in range(self.p["tubercles"]):
                xx=seed.uniform(-.21,.33); angle=seed.uniform(-1.23,1.23)
                p=self.surface(xx,angle,.0004); self.sphere("DermalTubercle_%02d"%i,p,(.004,.004,.004),"skin","spine",12,6)
        if self.p.get("head_ridges"):
            for side in (-1,1):
                for k in range(3):
                    pts=[self.surface(.37-.22*j/16,side*(.4+k*.30),.002) for j in range(17)]
                    self.tube("CranialBonyRidge_%s_%s"%(side,k),pts,.0022,"ray","head",8)
        if self.p.get("caudal_spines"):
            for side in (-1,1):
                p=self.surface(-.274,side*math.pi/2,.001)
                self.tube("RetractableCaudalScalpel_"+str(side),[p,add(p,(.025,.005,side*.006)),add(p,(.043,.008,side*.008))],[.0023,.0018,.0001],"ivory","tail_base",8)
        if self.p.get("dorsal_filament"):
            self.tube("TrailingDorsalFilament",[(-.09,.088,0),(-.17,.113,.002),(-.27,.09,.001),(-.33,.069,0)],[.0016,.0012,.00065,.00015],"ray","spine",7)
        if self.p.get("leaf_appendages"):
            for side in (-1,1):
                for j in range(4):
                    self.tube("LeafDermalAppendage_%s_%s"%(side,j),[(.38-j*.026,-.053,side*.032),(.395-j*.024,-.073,side*.040),(.38-j*.029,-.096,side*.046)],[.0035,.0022,.0002],"skin","head",7)

    def weight(self, spec, x):
        def axial():
            if x>=self.axial[0][1]: return {"head":1.0}
            if x<=self.axial[-1][1]: return {"tail_tip":1.0}
            for (na,a),(nb,b) in zip(self.axial,self.axial[1:]):
                if b<=x<=a:
                    t=(a-x)/(a-b);t=t*t*(3-2*t);return {na:1-t,nb:t}
            raise AssertionError(x)
        if spec=="spine": return axial()
        if isinstance(spec,tuple):
            bone,amount=spec;w={k:v*(1-amount) for k,v in axial().items()};w[bone]=w.get(bone,0)+amount;return w
        return {spec:1.0}

    def normalize(self):
        lo=min(v[0] for p in self.parts for v in p.vertices); hi=max(v[0] for p in self.parts for v in p.vertices)
        self.offset=(lo+hi)/2; self.scale=1/(hi-lo)
        self.raw_extents=(lo,hi)
        # Resolve weights in authored space, then normalize geometry AND rig.
        self.weight_indices={b["name"]:i for i,b in enumerate(self.bones)}
        for part in self.parts:
            part.weights=[self.weight(w,p[0]) for w,p in zip(part.weights,part.vertices)]
            part.vertices=[((x-self.offset)*self.scale,y*self.scale,z*self.scale) for x,y,z in part.vertices]
        for bone in self.bones:
            x,y,z=bone["origin"];bone["origin"]=((x-self.offset)*self.scale,y*self.scale,z*self.scale)
        mx,my,_,_=self.p["mouth"]
        self.mouth_offset=[(mx-self.offset)*self.scale,my*self.scale,0]

    def build(self):
        self.body();self.fins();self.eyes();self.face();self.anatomy();self.normalize()
        return self


def make_texture(profile, fin=False):
    w,h=(512,256) if fin else (1024,512)
    dorsal,side,belly=[hexcolor(v) for v in profile["palette"]]
    fincolor=hexcolor(profile.get("fin_color",profile["palette"][1]))
    pattern=profile["pattern"]; sid=profile["id"]
    pix=[]; heights=[]; rough=[]
    scales=profile.get("scale_rows",22); columns=profile.get("scale_columns",43)
    head=profile.get("head_uv",.70)
    for j in range(h):
        v=j/(h-1);theta=v*TAU;cosv=math.cos(theta); ss=abs(math.sin(theta))
        row=int(v*scales);sy=v*scales%1-.5
        for i in range(w):
            u=i/(w-1)
            if fin:
                c=mul(fincolor,.73+.25*(1-v)); seam=(.5+.5*math.sin(u*TAU*profile.get("fin_ray_count",24)))**14
                c=mul(c,1+.12*seam); height=.10*seam
                if pattern in ("sweetlips","cowfish","cabezon","lingcod","greenling","moray"):
                    spots=math.sin(u*95+math.sin(v*13))*math.sin(v*65-u*7)
                    if spots>.78:c=mul(c,.22)
                if profile.get("fin_edge") and v>.88:c=hexcolor(profile["fin_edge"])
                if sid=="russells_oarfish":c=hexcolor("d83b34")
                rr=.48
            else:
                c=lerp(side,dorsal,cosv**1.4) if cosv>0 else lerp(side,belly,(-cosv)**1.2)
                sx=(u*columns+(row%2)*.5)%1-.5
                d=sx-(.46-1.72*sy*sy); seam=math.exp(-(d/.045)**2); rim=math.exp(-((d+.075)/.065)**2)
                headmask=clamp((head-u)/.05)
                scale_strength=profile.get("scale_strength",.35)
                c=mul(c,1-scale_strength*.28*seam*headmask+.065*rim*headmask)
                height=(.30+.16*rim-.34*seam)*headmask*scale_strength
                noise=math.sin(u*719+v*139)*math.sin(u*349-v*277)
                c=mul(c,1+.030*noise); height+=.012*noise
                rr=profile.get("roughness",.38)+.06*max(0,cosv)+.012*noise
                # Each named pattern has explicit anatomical masks, authored
                # colors and proportions; these are never borrowed fish skins.
                if pattern=="sheephead":
                    if u>.70 or u<.15:c=lerp(c,hexcolor("181d1b"),.92)
                    elif .20<u<.69:c=lerp(c,hexcolor("b83a39"),.87)
                    if u>.84 and cosv<-.3:c=hexcolor("e9dfcf")
                elif pattern in ("lingcod","cabezon","greenling","flathead","turbot","halibut"):
                    mott=math.sin(u*59+math.sin(v*33))*math.cos(v*43+u*11)+.5*math.sin(u*139-v*89)
                    c=mul(c,1+.24*mott)
                    if pattern=="greenling" and u>.63 and ss>.45 and mott>.55:c=lerp(c,hexcolor("5c9cac"),.80)
                    if pattern in ("turbot","halibut") and cosv<0:c=lerp(c,hexcolor("ede8d6"),(-cosv)**.25)
                elif pattern=="garibaldi":
                    c=mul(c,1+.06*math.sin(u*53+v*49))
                elif pattern=="yellow_tang":
                    if u>.80:c=lerp(c,hexcolor("f4d634"),.25)
                elif pattern=="dory":
                    if .36<u<.55 and abs(ss-.95)<.11:c=lerp(c,hexcolor("1b2220"),.94)
                    c=mul(c,1+.1*math.sin(u*100+v*50))
                elif pattern=="gurnard":
                    c=mul(c,1+.15*math.sin(u*87)*math.cos(v*93));
                    if .13<abs(v-.25)<.16 and .13<u<.7:c=lerp(c,hexcolor("c8c5b1"),.35)
                elif pattern=="queen":
                    if u>.70 and cosv>.18:c=lerp(c,hexcolor("172544"),.86)
                    if u>.77 and cosv>.56 and cosv<.87:c=hexcolor("54c1dd")
                    if u<.13:c=hexcolor("e6be3a")
                elif pattern=="parrot":
                    if u>.70 and abs(math.sin(theta*3+u*16))<.20:c=lerp(c,hexcolor("e27c94"),.86)
                    if u<.17 and cosv>.08:c=lerp(c,hexcolor("ddc453"),.88)
                    if .42<u<.6 and cosv<-.30:c=lerp(c,hexcolor("a86260"),.85)
                elif pattern in ("flying","tarpon","scabbard","oarfish"):
                    c=mul(c,1+.035*math.cos(u*135+v*110))
                    if pattern=="oarfish":
                        c=mul(c,1-.25*max(0,math.sin(u*57+v*11))**7)
                elif pattern=="wrasse_maze":
                    maze=abs(math.sin(v*84+math.sin(u*45)*2.4+math.sin(u*113)*.35))
                    if maze<.18 and (u>.67 or ss>.25):c=lerp(c,hexcolor("beaa64"),.68)
                elif pattern in ("emperor","sohal"):
                    stripe=math.sin(v*TAU*(13 if pattern=="emperor" else 21)+.5*math.sin(u*9))
                    if u<.72 and ss>.35:c=lerp(c,hexcolor("edd456" if pattern=="emperor" else "1f3546"),clamp((stripe-.10)*4))
                    if pattern=="emperor" and u>.77:
                        c=hexcolor("e5e5d5") if u>.91 else hexcolor("141d30")
                    if pattern=="sohal" and .69<u<.78 and cosv<.20:c=lerp(c,hexcolor("de7837"),.80)
                elif pattern=="leaf":
                    c=mul(c,1+.18*math.sin(u*65+v*25)*math.cos(v*71));height+=.04*math.sin(u*77+v*34)
                elif pattern=="ray":
                    if cosv>0:
                        spot=math.sin(u*78+math.sin(v*25))*math.sin(v*85-u*11)
                        if spot>.78:c=lerp(c,hexcolor("35a7e1"),.94)
                    else:c=lerp(c,hexcolor("e6dfbd"),(-cosv)**.25)
                elif pattern=="moray":
                    spot=math.sin(u*147+math.sin(v*97))*math.cos(v*154-u*41)
                    if spot>.46:c=mul(c,.23)
                elif pattern=="collare":
                    if .70<u<.81:c=lerp(c,hexcolor("e4dfc2"),.92)
                    if u>.81:c=mul(c,.28)
                    c=mul(c,1+.22*rim*headmask)
                elif pattern=="cowfish":
                    cell=math.cos(u*93+math.cos(v*69))*math.cos(v*87)
                    if cell>.81:c=lerp(c,hexcolor("7ec3c5"),.86)
                    height+=.08*math.sin(u*87+v*23)**2*math.cos(v*70)**2
                elif pattern=="clown":
                    if .31<u<.43 or .75<u<.85:c=hexcolor("eee9d6")
                    elif .28<u<.46 or .72<u<.88:c=lerp(c,hexcolor("242a22"),.90)
                elif pattern=="banner":
                    xx=u+.095*math.cos(theta)
                    if .35<xx<.50 or .70<xx<.82:c=hexcolor("182421")
                    if u<.18:c=hexcolor("dfbb2f")
                elif pattern=="masked":
                    if .77<u<.86:c=lerp(c,hexcolor("556f83"),.87)
                    c=mul(c,1+.045*math.sin(v*130))
                elif pattern=="picasso":
                    if .47<u<.75 and cosv<.40 and cosv>-.75:c=lerp(c,hexcolor("283d39"),.94)
                    if u>.74 and abs(math.sin(v*41+u*20))<.25:c=hexcolor("48a6c0")
                    if .77<u<.90 and cosv<-.08:c=lerp(c,hexcolor("d28b35"),.88)
                elif pattern=="klunzinger":
                    if u<.73 and abs(math.sin(v*69+u*6))<.29:c=lerp(c,hexcolor("ca756e"),.78)
                    if u>.70 and abs(math.sin(v*27+u*27))<.19:c=hexcolor("1cc3d2")
                elif pattern=="goatfish":
                    if abs(cosv)<.23:c=lerp(c,hexcolor("d8ad37"),.94)
                    if .17<u<.25 and abs(cosv)<.45:c=lerp(c,hexcolor("142020"),.98)
                elif pattern=="cornet":
                    if cosv>0 and math.sin(u*151)*math.cos(v*101)>.75:c=lerp(c,hexcolor("429baa"),.9)
                elif pattern=="yellowbar":
                    if .36<u<.51 and cosv<.85 and cosv>-.85:c=hexcolor("ecbd3b")
                    if u>.73:c=mul(c,1+.10*math.sin(v*89+u*35))
                elif pattern=="sweetlips":
                    spot=math.sin(u*91+math.sin(v*21))*math.sin(v*112-u*19)
                    if spot>.79:c=lerp(c,hexcolor("263733"),.97)
                elif pattern=="batfish":
                    if .38<u<.49 or .77<u<.86:c=lerp(c,hexcolor("2a3634"),.90)
                elif pattern=="whale":
                    mott=math.sin(u*51+math.sin(v*21)*2)*math.cos(v*41+u*13)+.6*math.sin(u*94-v*37)
                    c=mul(c,1+.11*mott);height=.011*math.sin(u*431+v*281)
                elif pattern=="barreleye":
                    c=mul(c,1+.07*math.sin(u*81+v*67))
                else: raise ValueError("Unknown authored pigment pattern: "+pattern)
            pix.append(tuple(round(clamp(k)*255) for k in c)); heights.append(height)
            rough.append((255,round(clamp(rr)*255),round(profile.get("metallic",.035)*255)))
    color=Image.new("RGB",(w,h));color.putdata(pix)
    normal_pixels=[];strength=16 if fin else 9
    for j in range(h):
        for i in range(w):
            nx=(heights[j*w+max(0,i-1)]-heights[j*w+min(w-1,i+1)])*strength
            ny=(heights[max(0,j-1)*w+i]-heights[min(h-1,j+1)*w+i])*strength
            n=unit((nx,ny,1));normal_pixels.append(tuple(round((k*.5+.5)*255) for k in n))
    normal=Image.new("RGB",(w,h));normal.putdata(normal_pixels)
    rm=Image.new("RGB",(w,h));rm.putdata(rough)
    def png(im):
        buf=io.BytesIO();im.save(buf,format="PNG",compress_level=6);return buf.getvalue()
    return [png(color),png(normal),png(rm)]


class GLB:
    def __init__(self):
        self.data=bytearray();self.g={"asset":{"version":"2.0","generator":"Farshore original ocean modeller / Python + Pillow"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[],"meshes":[],"materials":[],"skins":[],"animations":[],"bufferViews":[],"accessors":[],"buffers":[],"images":[],"textures":[],"samplers":[{"magFilter":9729,"minFilter":9987,"wrapS":10497,"wrapT":10497}]}

    def view(self, raw, target=None):
        while len(self.data)%4:self.data.append(0)
        n=len(self.g["bufferViews"]);d={"buffer":0,"byteOffset":len(self.data),"byteLength":len(raw)}
        if target:d["target"]=target
        self.g["bufferViews"].append(d);self.data.extend(raw);return n

    def accessor(self, vals, comp, typ, target=None, limits=False):
        size={"SCALAR":1,"VEC2":2,"VEC3":3,"VEC4":4,"MAT4":16}[typ]
        rows=[(v,) if size==1 else tuple(v) for v in vals]
        flat=[x for row in rows for x in row]
        fmt={5126:"f",5125:"I",5123:"H"}[comp]
        view=self.view(struct.pack("<"+fmt*len(flat),*flat),target)
        a={"bufferView":view,"componentType":comp,"count":len(rows),"type":typ}
        if limits:a["min"]=[min(r[j] for r in rows) for j in range(size)];a["max"]=[max(r[j] for r in rows) for j in range(size)]
        self.g["accessors"].append(a);return len(self.g["accessors"])-1

    def texture(self, raw, name):
        self.g["images"].append({"bufferView":self.view(raw),"mimeType":"image/png","name":name})
        self.g["textures"].append({"sampler":0,"source":len(self.g["images"])-1})
        return len(self.g["textures"])-1

    def materials(self, a):
        self.mat={}
        for slot,fin in (("skin",False),("fin",True)):
            textures=make_texture(a.p,fin); ids=[self.texture(t,a.p["id"]+"_"+slot+"_"+k) for t,k in zip(textures,("basecolor","normal","metallic_roughness"))]
            m={"name":a.p["id"]+"_"+slot,"pbrMetallicRoughness":{"baseColorTexture":{"index":ids[0]},"metallicRoughnessTexture":{"index":ids[2]},"metallicFactor":1,"roughnessFactor":1},"normalTexture":{"index":ids[1],"scale":.35 if fin else .45},"doubleSided":fin}
            self.mat[slot]=len(self.g["materials"]);self.g["materials"].append(m)
        colors={"ray":a.p.get("fin_color",a.p["palette"][1]),"crease":"101b1b","iris":a.p.get("iris_color","b39b46"),"pupil":"030708","glint":"dcebf2","lip":a.p.get("lip_color",a.p["palette"][1]),"ivory":"e0d8ac","green_eye":"71af32","red":"c7362e","glass":"94ccc0"}
        for slot,color in colors.items():
            rr=.18 if slot in ("iris","pupil","glint","green_eye") else .45
            c=list(hexcolor(color))+[.20 if slot=="glass" else 1.0]
            m={"name":a.p["id"]+"_"+slot,"pbrMetallicRoughness":{"baseColorFactor":c,"metallicFactor":.05 if slot=="iris" else 0,"roughnessFactor":.10 if slot=="glass" else rr}}
            if slot=="glass":m["alphaMode"]="BLEND";m["doubleSided"]=True
            self.mat[slot]=len(self.g["materials"]);self.g["materials"].append(m)

    def model(self, a):
        self.materials(a)
        self.g["nodes"]=[{"name":a.p["id"],"children":[1,2],"extras":{"original_authored_profile":a.p["id"],"anatomy":a.features,"normalized_length_m":1.0}},
                         {"name":"SkinnedAnatomy","mesh":0,"skin":0},
                         {"name":"AnimalRig","children":[3]}]
        node_by_name={b["name"]:3+i for i,b in enumerate(a.bones)}
        bone_by_name={b["name"]:b for b in a.bones}
        for b in a.bones:
            pos=b["origin"]
            if b["parent"]:pos=sub(pos,bone_by_name[b["parent"]]["origin"])
            self.g["nodes"].append({"name":b["name"],"translation":list(pos),"rotation":[0,0,0,1]})
        for b in a.bones:
            if b["parent"]:self.g["nodes"][node_by_name[b["parent"]]].setdefault("children",[]).append(node_by_name[b["name"]])
        # Identity bind orientations; these matrices exactly invert the rest
        # joint world translations. Stored in glTF column-major order.
        ibms=[]
        for b in a.bones:
            x,y,z=b["origin"];ibms.append((1,0,0,0,0,1,0,0,0,0,1,0,-x,-y,-z,1))
        self.g["skins"].append({"name":"SpeciesSkin","joints":[node_by_name[b["name"]] for b in a.bones],"skeleton":node_by_name["root"],"inverseBindMatrices":self.accessor(ibms,5126,"MAT4")})
        grouped={}
        for part in a.parts:
            dest=grouped.setdefault(part.material,Part(part.material,part.material));offset=len(dest.vertices)
            dest.vertices+=part.vertices;dest.uv+=part.uv;dest.weights+=part.weights
            dest.faces += [tuple(v+offset for v in tri) for tri in part.faces]
        primitives=[]
        for slot,p in grouped.items():
            normals=p.normals();joints=[];weights=[]
            for w in p.weights:
                w={k:v for k,v in w.items() if v>1e-7};items=sorted(w.items(),key=lambda v:-v[1])[:4]; total=sum(v for k,v in items)
                jj=[a.weight_indices[k] for k,v in items];ww=[v/total for k,v in items]
                while len(jj)<4:jj.append(0);ww.append(0)
                joints.append(jj);weights.append(ww)
            attrs={"POSITION":self.accessor(p.vertices,5126,"VEC3",34962,True),"NORMAL":self.accessor(normals,5126,"VEC3",34962),"TEXCOORD_0":self.accessor(p.uv,5126,"VEC2",34962),"JOINTS_0":self.accessor(joints,5123,"VEC4",34962),"WEIGHTS_0":self.accessor(weights,5126,"VEC4",34962)}
            primitives.append({"attributes":attrs,"indices":self.accessor([i for f in p.faces for i in f],5125,"SCALAR",34963),"material":self.mat[slot],"mode":4})
        self.g["meshes"].append({"name":a.p["id"]+"_MergedPBRSurfaces","primitives":primitives})
        self.animate(a,node_by_name)
        self.g["extras"]={"editable_source":"tools/art3d/ocean_profiles.json","species_id":a.p["id"],"anatomical_features":a.features,"fantasy_encounter_only":a.p["kind"]=="whale"}
        self.g["buffers"]=[{"byteLength":len(self.data)}]
        return self

    def animate(self,a,node_by_name):
        style=a.p["motion"]; aquatic=a.p["kind"]=="whale"
        durations={"swim":2.4 if aquatic else 1.8,"struggle":1.2,"breach":1.6,"landed":3.0}
        for clip,duration in durations.items():
            count=49;time=[duration*i/(count-1) for i in range(count)];input_acc=self.accessor(time,5126,"SCALAR",limits=True)
            animation={"name":clip,"samplers":[],"channels":[],"extras":{"state": "surface_glide" if aquatic and clip=="landed" else clip,"motion_style":style}}
            amp={"swim":.11,"struggle":.31,"breach":.22,"landed":.025}[clip]
            if style in ("anguilliform","ribbon"):amp*=1.28
            if style in ("reef","boxfish","flatfish","ray"):amp*=.58
            if aquatic:amp*=.48
            for bi,b in enumerate(a.bones):
                name=b["name"];rot=[]
                for i in range(count):
                    t=i/(count-1);wave=t*TAU*(2 if clip=="struggle" else 1);angle=0;axis=(0,1,0)
                    if name in dict(a.axial):
                        k=next(j for j,(n,x) in enumerate(a.axial) if n==name)
                        strength=[.03,.08,.28,.52,.78,1.0,.75][k]
                        if style=="anguilliform":strength=[.10,.29,.45,.63,.82,1.0,.85][k]
                        angle=amp*strength*math.sin(wave-k*.67)
                        axis=(0,0,1) if aquatic or style=="flatfish" else (0,1,0)
                    elif "pectoral" in name or "horizontalfluke" in name or "diskwing" in name:
                        side=-1 if name.endswith("_r") else 1
                        axis=(1,0,0);angle=side*(.12 if clip!="landed" else .025)*math.sin(wave+.45)
                        if style in ("ray","boxfish","reef"):angle*=1.45
                        if aquatic:angle*=.25
                    elif name.startswith("dorsal") or name.startswith("anal"):
                        axis=(1,0,0);angle=.028*math.sin(wave-.65)
                        if style=="ribbon":angle*=2
                    elif name.startswith("gill"):
                        axis=(0,1,0);angle=(1 if name.endswith("L") else -1)*(.032 if clip=="landed" else .015)*(.5+.5*math.sin(wave*2))
                    elif name=="jaw":
                        axis=(0,0,1);angle=-.025*(.5+.5*math.sin(wave*2+.4))
                        if style in ("anguilliform","benthic"):angle*=1.8
                        if aquatic:angle=0
                    elif name=="root":
                        axis=(1,0,0);angle=(.02 if clip=="swim" else .07 if clip=="struggle" else .03)*math.sin(wave)
                        if aquatic:angle*=.28
                    else:
                        axis=(1,0,0);angle=.035*math.sin(wave-1.1)
                    s=math.sin(angle/2);rot.append((axis[0]*s,axis[1]*s,axis[2]*s,math.cos(angle/2)))
                output=self.accessor(rot,5126,"VEC4")
                animation["samplers"].append({"input":input_acc,"output":output,"interpolation":"LINEAR"})
                animation["channels"].append({"sampler":len(animation["samplers"])-1,"target":{"node":node_by_name[name],"path":"rotation"}})
            self.g["animations"].append(animation)

    def save(self,path):
        js=json.dumps(self.g,separators=(",",":"),ensure_ascii=False).encode("utf8")
        js+=b" "*((-len(js))%4);binraw=bytes(self.data)+b"\0"*((-len(self.data))%4)
        raw=struct.pack("<4sII",b"glTF",2,12+8+len(js)+8+len(binraw))+struct.pack("<I4s",len(js),b"JSON")+js+struct.pack("<I4s",len(binraw),b"BIN\0")+binraw
        path.parent.mkdir(parents=True,exist_ok=True);candidate=path.with_suffix(".glb.tmp");candidate.write_bytes(raw);candidate.replace(path)
        return raw


def build(profile):
    a=Animal(profile).build();glb=GLB().model(a);path=OUT/(profile["id"]+".glb");raw=glb.save(path)
    stats={"id":profile["id"],"file":str(path.relative_to(ROOT)),"sha256":hashlib.sha256(raw).hexdigest(),"vertices":sum(len(p.vertices) for p in a.parts),"triangles":sum(len(p.faces) for p in a.parts),"surfaces":len(glb.g["meshes"][0]["primitives"]),"bones":[b["name"] for b in a.bones],"animation_clips":{anim["name"]:glb.g["accessors"][anim["samplers"][0]["input"]]["max"][0] for anim in glb.g["animations"]},"length_m":1.0,"mouth_offset_normalized":a.mouth_offset,"dimensions_m":[max(v[i] for p in a.parts for v in p.vertices)-min(v[i] for p in a.parts for v in p.vertices) for i in range(3)],"anatomical_features":a.features,"original_procedural_asset":True,"source_profile_sha256":hashlib.sha256(json.dumps(profile,sort_keys=True).encode()).hexdigest(),"bytes":len(raw)}
    REVIEW.mkdir(parents=True,exist_ok=True);(REVIEW/(profile["id"]+"_stats.json")).write_text(json.dumps(stats,indent=2)+"\n")
    return stats


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument("--species",default="all");parser.add_argument("--update-manifest",action="store_true");args=parser.parse_args()
    profiles=json.loads(PROFILE_FILE.read_text())["species"]
    wanted=profiles if args.species=="all" else [p for p in profiles if p["id"] in args.species.split(",")]
    if not wanted:raise SystemExit("Unknown species; no fallback mesh exists.")
    stats=[]
    for p in wanted:
        result=build(p);stats.append(result);print("OCEAN_MODEL_READY "+json.dumps({k:result[k] for k in ("id","vertices","triangles","surfaces","bytes")}),flush=True)
    if args.update_manifest:
        path=ROOT/"game/data/fish_3d.json";manifest=json.loads(path.read_text())
        for s in stats:
            profile=next(p for p in profiles if p["id"]==s["id"])
            manifest["models"][s["id"]]={"scene":"res://assets/3d/"+s["id"]+".glb","rest_length_m":1.0,"asymmetric_flatfish":profile["kind"]=="flatfish","mouth_offset_normalized":s["mouth_offset_normalized"],"authoring_source":"tools/art3d/ocean_profiles.json","generator_source":"tools/art3d/build_ocean_diversity.py","motion_style":profile["motion"]}
            if profile["kind"]=="flatfish":manifest["models"][s["id"]]["eyed_side"]=profile["eyed_side"]
            if profile["kind"]=="whale":manifest["models"][s["id"]]["presentation_type"]="aquatic_giant_mammal"
        path.write_text(json.dumps(manifest,indent=2)+"\n")
    (REVIEW/"build_summary.json").write_text(json.dumps(stats,indent=2)+"\n")


if __name__=="__main__":main()
