#!/usr/bin/env python3
"""Farshore original fish authoring pipeline v1. Single shared-library owner.
Isolated profiles provide anatomy. Legacy approved carp/gar are never overwritten.
"""
import bpy,bmesh,math,json,sys,importlib.util,argparse,hashlib,os,struct
import numpy as np
from pathlib import Path
from mathutils import Vector,Quaternion
from mathutils.bvhtree import BVHTree
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).parent))
import build_fish as core
TAU=math.tau
PROTECTED={'common_carp','alligator_gar'}
PIPELINE_SHA256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest()

def load_profile(species):
    path=Path(__file__).parent/'fish_profiles'/f'{species}.py'
    spec=importlib.util.spec_from_file_location('profile_'+species,path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    assert module.PROFILE['id']==species
    return module

def material_map(profile,fin=False):
    skin=profile['skin']; species=profile['id'];w,h=(1024,512) if fin else (2048,1024)
    u,v=np.meshgrid(np.arange(w,dtype=np.float32)/w,np.arange(h,dtype=np.float32)/h)
    seed=int(hashlib.sha256(species.encode()).hexdigest()[:8],16);rng=np.random.default_rng(seed)
    # Deterministic smooth multi-octave pigment, never a copied photo or decal fish.
    noise=sum(np.sin(u*TAU*(k*3.71+1.2)+np.sin(v*TAU*(k*2.51+1.7))+rng.uniform(0,TAU))*np.cos(v*TAU*(k*4.91+1.9)+rng.uniform(0,TAU))/(k**1.25) for k in range(1,7))/2.0
    upper=(np.cos(v*TAU)+1)*.5
    flat_width=None
    if profile.get('flatfish') and not fin:
        sections=np.asarray(profile['sections']);xx=sections[0,0]+u*(sections[-1,0]-sections[0,0]);flat_width=np.interp(xx,sections[:,0],sections[:,1]);yy=np.sin(v*TAU)*flat_width
        noise=np.zeros_like(u)
        for k,freq in enumerate((7,13,23,41,73,127)):
            angle=rng.uniform(0,TAU);a=u*np.cos(angle)+yy*np.sin(angle);b=-u*np.sin(angle)+yy*np.cos(angle)
            noise+=np.sin(a*TAU*freq+rng.uniform(0,TAU))*np.cos(b*TAU*freq*.71+rng.uniform(0,TAU))/(1.8**k)
        noise/=1.6
    if fin:
        color=np.array(profile.get('fin_color',skin['side']))[None,None,:]*np.ones((h,w,1))
        color*= (.80+.10*np.sin(u*TAU*23)**10+.10*(1-v))[:,:,None]
        height=.05*np.sin(u*TAU*23)**10
        if profile.get('fin_pattern')=='spots':
            for i in range(38):
                x,y=rng.uniform(0,1),rng.uniform(.2,.97);rx,ry=rng.uniform(.012,.045),rng.uniform(.012,.05)
                d=np.exp(-2*(((u-x)/rx)**2+((v-y)/ry)**2));color*=1-.63*d[:,:,None]
        rough=np.full((h,w),.51,dtype=np.float32)
    else:
        back,side,belly=[np.array(skin[k]) for k in ('back','side','belly')]
        color=np.where((upper<.5)[:,:,None],belly*(1-upper[:,:,None]*2)+side*upper[:,:,None]*2,side*(2-upper[:,:,None]*2)+back*(upper[:,:,None]*2-1))
        pattern=skin.get('pattern','fine_scales');height=np.zeros((h,w),dtype=np.float32)
        head=np.clip((u-profile.get('head_start',.72))/(profile.get('head_end',.84)-profile.get('head_start',.72)),0,1)
        gate=1-head
        if pattern in ('scales','fine_scales','diamond'):
            if pattern=='diamond':
                a=u*skin.get('scale_columns',50)+v*18;b=u*skin.get('scale_columns',50)-v*18
                edge=np.minimum(np.minimum(a%1,1-a%1),np.minimum(b%1,1-b%1));seam=np.exp(-(edge/.035)**2)
                cells=(np.sin(np.floor(a)*33.2+np.floor(b)*61.5)*193.83)%1
                height=(.3-.3*seam)*gate
            else:
                n=skin.get('scale_columns',35 if pattern=='scales' else 65);rows=skin.get('scale_rows',22 if pattern=='scales' else 30)
                row=np.floor(v*rows);sy=(v*rows)%1-.5;sx=(u*n+(row%2)*.5)%1-.5
                d=sx-(.49-1.94*sy*sy);seam=np.exp(-(d/.033)**2)
                rim=np.exp(-((d+.05)/.04)**2);height=(.30+.14*rim-.35*seam)*gate
                cells=(np.sin(np.floor(u*n+(row%2)*.5)*31.3+row*29.17)*433.17)%1
            color*=1-.30*seam[:,:,None]*gate[:,:,None]
            color*=1+(.13*(cells-.5)*gate)[:,:,None]
        if pattern in ('mottle','flatfish'):
            pigment=np.clip((noise+.14)*1.6,0,1)
            amount=.38 if pattern=='flatfish' else skin.get('mottle_amount',.32)
            color*=1-amount*pigment[:,:,None]
            color+=np.maximum(0,noise-.20)[:,:,None]*.06
        if pattern=='flatfish':
            dorsal=np.clip((upper-.47)/.12,0,1)
            colored=color*(.9+.15*noise[:,:,None])
            color=colored*dorsal[:,:,None]+belly[None,None,:]*(1-dorsal[:,:,None])
            height+=dorsal*(.015*np.sin(u*734+v*182)+noise*.025)
        else:height+=noise*.015
        # Features can be combined with any scale/skin pattern.
        feature=skin.get('feature',pattern)
        if feature=='bars':
            n=skin.get('bar_count',7);bars=np.maximum(0,np.cos(u*TAU*n+np.sin(v*14)*.28))**skin.get('bar_sharpness',4)
            color*=1-skin.get('bar_strength',.55)*bars[:,:,None]*gate[:,:,None]
        elif feature=='waves':
            waves=np.maximum(0,np.cos(u*TAU*skin.get('wave_count',20)+np.sin(v*TAU*6)*.8+noise*.5))**5
            color*=1-.65*waves[:,:,None]*np.clip((upper-.54)/.17,0,1)[:,:,None]*gate[:,:,None]
        elif feature=='spots' or (pattern=='flatfish' and skin.get('spot_color')):
            spots=np.zeros((h,w),dtype=np.float32)
            for i in range(skin.get('spot_count',85)):
                x,y=rng.uniform(*skin.get('spot_u_range',(.05,.90))),rng.uniform(0,1);r=rng.uniform(*skin.get('spot_radius',(.003,.013)))
                if pattern=='flatfish':
                    sec=np.asarray(profile['sections']);wx=float(np.interp(sec[0,0]+x*(sec[-1,0]-sec[0,0]),sec[:,0],sec[:,1]));cy=(y*2-1)*wx*.90
                    d=np.exp(-3*(((u-x)/r)**2+((yy-cy)/r)**2))
                else:
                    dy=np.minimum(abs(v-y),1-abs(v-y));d=np.exp(-3*(((u-x)/r)**2+(dy/(r*1.8))**2))
                spots=np.maximum(spots,d)
            spots*=np.clip((upper-(.50 if pattern=='flatfish' else .1))/.2,0,1)
            c=np.array(skin.get('spot_color',(.035,.045,.031)));color=color*(1-spots[:,:,None]*.85)+c*spots[:,:,None]*.85
        if skin.get('lateral_line'):
            line_height=skin.get('lateral_curve',.10)+skin.get('lateral_arch',0)*np.exp(-((u-.64)/.16)**2)
            line=np.exp(-((abs(np.cos(v*TAU))-line_height)/.018)**2)*gate
            c=np.array(skin['lateral_line']);color=color*(1-line[:,:,None]*.7)+c*line[:,:,None]*.7
        color*=1+noise[:,:,None]*skin.get('variation',.045)
        rough=np.full((h,w),profile.get('roughness',.43),dtype=np.float32)+noise*.025
        if callable(profile.get('custom_skin')):color,height,rough=profile['custom_skin'](u,v,upper,color,height,rough)
    color=np.clip(color,0,1);name=species+('_Fin' if fin else '_Skin')
    m=core.mat(name,tuple(skin['side']),.45,0)
    pbr=m.node_tree.nodes.get('Principled BSDF')
    pbr.inputs['Coat Weight'].default_value=profile.get('coat',.06)
    pbr.inputs['Specular IOR Level'].default_value=profile.get('specular',.30)
    im=core.packed_image(name+'_BaseColor',color)
    gy,gx=np.gradient(height);nx=-gx*16;ny=-gy*16;nz=np.ones_like(nx);norm=np.sqrt(nx*nx+ny*ny+1)
    nm=core.packed_image(name+'_Normal',np.stack((nx/norm*.5+.5,ny/norm*.5+.5,nz/norm*.5+.5),2),True)
    rm=core.packed_image(name+'_Roughness',np.repeat(np.clip(rough,0,1)[:,:,None],3,2),True)
    ns=m.node_tree.nodes;lk=m.node_tree.links;p=ns.get('Principled BSDF')
    for image,socket in ((im,'Base Color'),(rm,'Roughness')):
        tex=ns.new('ShaderNodeTexImage');tex.image=image;lk.new(tex.outputs['Color'],p.inputs[socket])
    tex=ns.new('ShaderNodeTexImage');tex.image=nm;n=ns.new('ShaderNodeNormalMap');n.inputs['Strength'].default_value=profile.get('normal_strength',.28);lk.new(tex.outputs['Color'],n.inputs['Color']);lk.new(n.outputs['Normal'],p.inputs['Normal'])
    return m

class Fish:
    def __init__(self,profile):
        self.profile=profile;self.species=profile['id'];self.sections=profile['sections'];self.bones={};self.fin_bones=[];self.attachment_groups={}
        self.review=ROOT/'ownbuild/fish3d-catalog'/self.species;self.review.mkdir(parents=True,exist_ok=True)
        bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.preferences.filepaths.save_version=0
        core.SPEC=self.species;core.PROFILES=self.sections;core.MESHES=[];core.WEIGHTS={}
        self.mats={'skin':material_map(profile),'fin':material_map(profile,True),'ray':self.material('SoftFinRays',tuple(np.array(profile.get('fin_color',profile['skin']['side']))*.85),.54),'edge':self.material('AnatomicalRims',tuple(np.array(profile['skin']['side'])*.9),.47),'dark':self.material('MouthGillRecess',(.018,.022,.018),.54),'lip':self.material('MouthTissue',tuple(np.array(profile['skin']['belly'])*.68),.48),'tooth':self.material('NaturalIvory',(.72,.73,.59),.42)}
        if profile.get('flatfish'):
            verts=[];uv=[];faces=[];nx,na=112,128;lo,hi=self.sections[0][0],self.sections[-1][0]
            for i in range(nx+1):
                for j in range(na+1):verts.append(core.surface(lo+(hi-lo)*i/nx,TAU*j/na));uv.append((i/nx,j/na))
            for i in range(nx):
                for j in range(na):a=i*(na+1)+j;faces.append((a,a+1,a+na+2,a+na+1))
            faces.extend((tuple(range(na,-1,-1)),tuple(nx*(na+1)+j for j in range(na+1))))
            core.mesh('FlattenedVolumetricBody',verts,faces,self.mats['skin'],uv,'spine')
        else:core.body(self.mats['skin'])
        body=core.MESHES[-1];marker=body.data.attributes.new('fs_body_surface','INT','POINT');marker.data.foreach_set('value',[1]*len(body.data.vertices))
        self.bone('root',(0,0,0),(0,0,.06),None)
        self.bone('head',(.25,0,0),(.46,0,0),'root')
        for name,head,tail,parent in [('spine_front',(.25,0,0),(.045,0,0),'root'),('spine_mid',(.045,0,0),(-.145,0,0),'spine_front'),('spine_rear',(-.145,0,0),(-.30,0,0),'spine_mid'),('tail',(-.30,0,0),(-.40,0,0),'spine_rear'),('caudal',(-.38,0,0),(-.49,0,0),'tail'),('jaw',(.32,0,-.025),(.48,0,-.025),'head')]:self.bone(name,head,tail,parent)
    def material(self,name,color,roughness=.45,metallic=0,color_space='srgb'):
        existing=bpy.data.materials.get(name)
        if existing:return existing
        rgb=tuple(float(c) for c in color)
        if color_space=='srgb':rgb=tuple(c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in rgb)
        elif color_space!='linear':raise ValueError('color_space must be srgb or linear')
        mat=core.mat(name,rgb,roughness,metallic);pbr=mat.node_tree.nodes.get('Principled BSDF');pbr.inputs['Specular IOR Level'].default_value=.30;pbr.inputs['Coat Weight'].default_value=.06
        return mat
    def surface(self,x,theta,inflate=0):return core.surface(x,theta,inflate)
    def mesh(self,name,vertices,faces,material=None,uv=None,weight='spine'):return core.mesh(name,vertices,faces,material or self.mats['skin'],uv,weight)
    def tube(self,name,points,radius,material=None,weight='spine',rings=7):return core.tube(name,points,radius,material or self.mats['edge'],weight,rings)
    def ellipsoid(self,name,center,scale,material=None,weight='head'):return core.sphere(name,center,scale,material or self.mats['skin'],weight,32,16)
    def bone(self,name,head,tail,parent='head'):
        if name in self.bones:return
        self.bones[name]=(head,tail,parent)
    def fin(self,name,roots,edge,bone=None,parent='spine_mid',rays=20,material=None,ray_material=None):
        bn=bone or name.lower();r=Vector(roots[len(roots)//2]);e=Vector(edge[len(edge)//2])
        if (e-r).length<.01:e=r+Vector((-.03,0,.03))
        self.bone(bn,r,e,parent)
        if bn not in self.fin_bones and bn!='caudal':self.fin_bones.append(bn)
        before=len(core.MESHES);membrane=core.fin(name,roots,edge,bn,material or self.mats['fin'],ray_material or self.mats['ray'],rays)
        aid=len(self.attachment_groups)+1;self.attachment_groups[aid]={'name':name,'bone':bn}
        for ob in core.MESHES[before:]:
            uv=ob.data.uv_layers.active.data;root_ids=set()
            for poly in ob.data.polygons:
                for li,vi in zip(poly.loop_indices,poly.vertices):
                    if uv[li].uv.y<1e-6:root_ids.add(vi)
            marker=ob.data.attributes.new('fs_attachment','INT','POINT');kind=ob.data.attributes.new('fs_attachment_kind','INT','POINT')
            for vi in root_ids:marker.data[vi].value=aid;kind.data[vi].value=1 if ob==membrane else 2
        return membrane
    def eye(self,name,center,normal,radius=.01,iris=(.45,.32,.12)):
        n=Vector(normal).normalized();c=Vector(center);u=n.cross(Vector((1,0,0)))
        if u.length<.1:u=n.cross(Vector((0,0,1)))
        u.normalize();v=n.cross(u).normalized()
        def oval(nm,depth,rad,width,material):
            verts=[];faces=[];uv=[];N,M=28,14
            for i in range(M+1):
                th=math.pi*i/M
                for j in range(N+1):
                    ph=TAU*j/N;p=c+n*depth+n*(math.cos(th)*width)+(u*math.cos(ph)+v*math.sin(ph))*math.sin(th)*rad
                    verts.append(p);uv.append((j/N,i/M))
            for i in range(M):
                for j in range(N):a=i*(N+1)+j;faces.append((a,a+1,a+N+2,a+N+1))
            return self.mesh(name+nm,verts,faces,material,uv,'head')
        oval('_Socket',-radius*.10,radius*1.04,radius*.26,self.mats['dark'])
        iris_mat=self.material(name+'_Iris',iris,.33,.02);pupil_mat=self.material(name+'_Pupil',(.003,.006,.006),.23)
        rim_mat=self.material('NaturalDarkOrbitalRim',tuple(np.array(self.profile['skin']['side'])*.46),.59)
        for mat in (iris_mat,pupil_mat,rim_mat):
            pbr=mat.node_tree.nodes.get('Principled BSDF');pbr.inputs['Coat Weight'].default_value=0;pbr.inputs['Specular IOR Level'].default_value=.18
        oval('_Iris',radius*.04,radius*.89,radius*.23,iris_mat)
        oval('_Pupil',radius*.25,radius*.51,radius*.065,pupil_mat)
        pts=[c+n*(radius*.13)+(u*math.cos(t)+v*math.sin(t))*radius*1.0 for t in np.linspace(0,TAU,33)]
        self.tube(name+'_Rim',pts,radius*.065,rim_mat,'head',6)
    def gill(self,name,points,width=.001,parent='head'):
        bn='gill_'+name;r=Vector(points[len(points)//2]);self.bone(bn,r,r+Vector((-.02,.01,-.025)),parent)
        self.tube(name+'_GillSeam',points,width*1.1,self.mats['dark'],bn,7)
        self.tube(name+'_GillEdge',[Vector(p)+Vector((.002,0,0)) for p in points],width*.7,self.mats['edge'],bn,6)
    def scute(self,name,x,theta,length=.025,width=.017,height=.008):
        c=self.surface(x,theta,.0004);n=Vector((0,math.sin(theta),math.cos(theta))).normalized();u=Vector((1,0,0));v=n.cross(u)
        # Rhomboid bony base and offset keel, not generic spheres along a backbone.
        verts=[c+u*length*.5,c+v*width*.5,c-u*length*.5,c-v*width*.5,c+n*height+u*length*.06]
        faces=[(0,1,4),(1,2,4),(2,3,4),(3,0,4),(3,2,1,0)]
        ob=self.mesh(name,verts,faces,self.material('BonePlate',(.39,.415,.39),.63),weight='spine')
        for poly in ob.data.polygons:poly.use_smooth=False
        return ob
    def rig(self):
        if self.profile.get('mirror_y'):
            for ob in core.MESHES:
                for v in ob.data.vertices:v.co.y=-v.co.y
            self.bones={name:((h[0],-h[1],h[2]),(t[0],-t[1],t[2]),parent) for name,(h,t,parent) in self.bones.items()}
        for ob in core.MESHES:
            bm=bmesh.new();bm.from_mesh(ob.data)
            if ob.name in ('Body_SculptedLoft','FlattenedVolumetricBody'):bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-7)
            bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(ob.data);bm.free()
        bpy.ops.object.armature_add(enter_editmode=True,location=(0,0,0));rig=bpy.context.object;rig.name='FishRig';eb=rig.data.edit_bones;eb.remove(eb[0])
        for name,(head,tail,parent) in self.bones.items():b=eb.new(name);b.head=head;b.tail=tail
        for name,(_,_,parent) in self.bones.items():
            if parent:eb[name].parent=eb[parent]
        bpy.ops.object.mode_set(mode='OBJECT');rig.show_in_front=True;core.bind(rig)
        lo=min(v.co.x for o in core.MESHES for v in o.data.vertices);hi=max(v.co.x for o in core.MESHES for v in o.data.vertices);scale=1/(hi-lo);offset=(hi+lo)*.5
        for o in core.MESHES:
            for v in o.data.vertices:v.co.x=(v.co.x-offset)*scale;v.co.y*=scale;v.co.z*=scale
        bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
        for b in rig.data.edit_bones:
            for attr in ('head','tail'):
                p=getattr(b,attr);setattr(b,attr,((p.x-offset)*scale,p.y*scale,p.z*scale))
        bpy.ops.object.mode_set(mode='OBJECT')
        # Merge by actual material to bound draw calls without reducing topology.
        groups={}
        for o in core.MESHES:groups.setdefault(o.data.materials[0],[]).append(o)
        merged=[]
        for material,objects in groups.items():
            bpy.ops.object.select_all(action='DESELECT')
            for o in objects:o.select_set(True)
            bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();ob=bpy.context.object;ob.name=material.name+'_Geometry';merged.append(ob)
        core.MESHES=merged;self.rig_object=rig;rig['attachment_groups']=json.dumps(self.attachment_groups);self.animate();return rig
    def animate(self):
        rig=self.rig_object;rig.animation_data_create();vertical=self.profile.get('bend_axis')=='vertical'
        for name,(duration,amp) in {'swim':(60,.12),'struggle':(36,.36),'breach':(42,.25),'landed':(90,.022)}.items():
            action=bpy.data.actions.new(name);rig.animation_data.action=action
            for frame in range(1,duration+2):
                t=(frame-1)/duration;phase=TAU*t
                for b in rig.pose.bones:b.rotation_mode='XYZ';b.rotation_euler=(0,0,0);b.location=(0,0,0)
                for i,bn in enumerate(('head','spine_front','spine_mid','spine_rear','tail','caudal')):
                    strength=[-.15,.22,.60,.95,1.05,.63][i];value=amp*strength*math.sin(phase-i*.62)*self.profile.get('swim_amplitude',1)
                    setattr(rig.pose.bones[bn].rotation_euler,'x' if vertical else 'z',value)
                    if name in ('struggle','breach'):setattr(rig.pose.bones[bn].rotation_euler,'z' if vertical else 'x',amp*.16*math.sin(phase*2-i*.4))
                for i,bn in enumerate(self.fin_bones):
                    b=rig.pose.bones[bn];factor=.055 if name=='landed' else .16
                    b.rotation_euler.y=factor*math.sin(phase-i*.51)
                    b.rotation_euler.z=.035*math.sin(phase-i*.4)
                for bn in self.bones:
                    if bn.startswith('gill_'):rig.pose.bones[bn].rotation_euler.y=.025*(.5+.5*math.sin(phase*2))
                rig.pose.bones['jaw'].rotation_euler.x=-(.065 if name in ('struggle','landed') else .018)*(.5+.5*math.sin(phase*2+.3))
                for b in rig.pose.bones:b.keyframe_insert(data_path='rotation_euler',frame=frame,group=b.name)
            for fc in action.fcurves:
                for key in fc.keyframe_points:key.interpolation='LINEAR'
            track=rig.animation_data.nla_tracks.new();track.name=name;track.strips.new(name,1,action);track.mute=True
        rig.animation_data.action=None
        for b in rig.pose.bones:b.rotation_euler=(0,0,0)
    def validate(self):
        rig=self.rig_object;scene=bpy.context.scene;report={'species':self.species,'clips':{},'failures':[]}
        def verts(frame):
            scene.frame_set(frame);bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();out=[]
            for o in core.MESHES:
                ev=o.evaluated_get(dg);me=ev.to_mesh();out.extend(v.co.copy() for v in me.vertices);ev.to_mesh_clear()
            return out
        for name in ('swim','struggle','breach','landed'):
            a=bpy.data.actions[name];rig.animation_data.action=a;start,end=map(int,a.frame_range);p=verts(start);q=verts(start+(end-start)//4);r=verts(end)
            delta=max((x-y).length for x,y in zip(p,q));seam=max((x-y).length for x,y in zip(p,r));report['clips'][name]={'seconds':(end-start)/30,'max_skin_displacement_m':delta,'loop_seam_m':seam}
            if delta<.0005 or seam>1e-5:report['failures'].append(name+' deformation/loop error')
        # Persistent root tags survive material consolidation; closest deformed body check.
        tolerance=self.profile.get('attachment_tolerance_m',.004)
        contacts={str(i):{'name':v['name'],'bone':v['bone'],'membrane_roots':0,'ray_roots':0,'membrane_max_distance_m':0,'ray_max_distance_m':0,'max_distance_m':0,'rest_distance_m':0,'worst_clip':'','worst_frame':0} for i,v in self.attachment_groups.items()}
        roots={};body_objects=[]
        for ob in core.MESHES:
            tags=ob.data.attributes.get('fs_attachment');kinds=ob.data.attributes.get('fs_attachment_kind');body=ob.data.attributes.get('fs_body_surface')
            if body:body_objects.append((ob,[list(p.vertices) for p in ob.data.polygons if all(body.data[i].value==1 for i in p.vertices)]))
            if tags:
                roots[ob]=[(i,str(t.value),kinds.data[i].value) for i,t in enumerate(tags.data) if t.value>0]
                for _,aid,kind in roots[ob]:contacts[aid]['membrane_roots' if kind==1 else 'ray_roots']+=1
        def contact_sample(clip,frame):
            scene.frame_set(frame);bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get();verts=[];faces=[]
            for ob,polys in body_objects:
                ev=ob.evaluated_get(dg);me=ev.to_mesh();offset=len(verts);verts.extend(v.co.copy() for v in me.vertices);faces.extend([[i+offset for i in p] for p in polys]);ev.to_mesh_clear()
            bvh=BVHTree.FromPolygons(verts,faces)
            for ob,items in roots.items():
                ev=ob.evaluated_get(dg);me=ev.to_mesh()
                for vi,aid,kind in items:
                    near=bvh.find_nearest(me.vertices[vi].co);distance=near[3] if near[0] is not None else 1e9;r=contacts[aid]
                    kind_key='membrane_max_distance_m' if kind==1 else 'ray_max_distance_m';r[kind_key]=max(r[kind_key],distance)
                    if clip=='rest':r['rest_distance_m']=max(r['rest_distance_m'],distance)
                    if distance>r['max_distance_m']:r.update(max_distance_m=distance,worst_clip=clip,worst_frame=frame)
                ev.to_mesh_clear()
        rig.animation_data.action=None
        for b in rig.pose.bones:b.rotation_euler=(0,0,0)
        contact_sample('rest',1)
        for clip in ('swim','struggle','breach','landed'):
            action=bpy.data.actions[clip];rig.animation_data.action=action;start,end=map(int,action.frame_range)
            for phase in range(9):contact_sample(clip,round(start+(end-start)*phase/8))
        report['attachments']={'tolerance_m':tolerance,'samples_per_clip':9,'groups':contacts}
        for r in contacts.values():
            if r['max_distance_m']>tolerance:report['failures'].append('Detached '+r['name']+': %.5fm in %s frame%d'%(r['max_distance_m'],r['worst_clip'],r['worst_frame']))
        rig.animation_data.action=None
        for b in rig.pose.bones:b.rotation_euler=(0,0,0)
        scene.frame_set(1);bpy.context.view_layer.update()
        weights=[sum(g.weight for g in v.groups) for o in core.MESHES for v in o.data.vertices];report['weight_sum_min']=min(weights);report['weight_sum_max']=max(weights)
        if min(weights)<.999 or max(weights)>1.001:report['failures'].append('skin weight sum')
        report['max_influences']=max(len(v.groups) for o in core.MESHES for v in o.data.vertices)
        if getattr(self,'audit_existing',False):
            master=ROOT/'art_masters/3d'/f'{self.species}.blend';runtime=ROOT/'game/assets/3d'/f'{self.species}.glb'
            report['master_sha256']=hashlib.sha256(master.read_bytes()).hexdigest()
            if runtime.exists():report['glb_sha256']=hashlib.sha256(runtime.read_bytes()).hexdigest()
        report['attachment_tag_version']=1
        (self.review/'validation.json').write_text(json.dumps(report,indent=2))
        if report['failures']:
            staging=self.review/'staging';staging.mkdir(exist_ok=True);bpy.ops.wm.save_as_mainfile(filepath=str(staging/'attachment_failure.blend'),copy=True)
        assert not report['failures'],report
    def export(self):
        self.rig();self.validate();rig=self.rig_object;s=bpy.context.scene;s.render.fps=30;s.frame_start=1;s.frame_end=91
        for o in core.MESHES:o.data.calc_loop_triangles()
        bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
        for o in core.MESHES:o.select_set(True)
        bpy.context.view_layer.objects.active=rig;glb=ROOT/'game/assets/3d'/f'{self.species}.glb'
        staging=self.review/'staging';staging.mkdir(exist_ok=True);candidate=staging/glb.name
        bpy.ops.export_scene.gltf(filepath=str(candidate),export_format='GLB',use_selection=True,export_yup=True,export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_frame_range=False,export_anim_slide_to_zero=True,export_skins=True,export_all_influences=False,export_def_bones=True,export_extras=True)
        raw=candidate.read_bytes();magic,version,total=struct.unpack_from('<4sII',raw);assert magic==b'glTF' and version==2 and total==len(raw),'Incomplete candidate GLB'
        json_size,json_type=struct.unpack_from('<II',raw,12);assert json_type==0x4E4F534A
        document=json.loads(raw[20:20+json_size]);assert set(a['name'] for a in document.get('animations',[]))=={'swim','struggle','breach','landed'}
        assert document.get('skins') and all('skin' in node for node in document['nodes'] if 'mesh' in node),'Unskinned candidate mesh'
        self.camera=core.setup_scene()
        bpy.ops.object.light_add(type='AREA',location=(.10,-.25,-1.2));light=bpy.context.object;light.name='REVIEW_UndersideFill';light.data.energy=42;light.data.size=1.3;light.rotation_euler=(Vector((0,0,0))-light.location).to_track_quat('-Z','Y').to_euler();light.hide_render=True
        if self.profile.get('flatfish'):
            for ob in bpy.data.objects:
                if ob.type=='LIGHT' and ob.name!='REVIEW_UndersideFill':ob.data.energy*=.50
        s.render.resolution_x=1200;s.render.resolution_y=800;s.cycles.samples=32
        floor=bpy.data.objects['REVIEW_Backdrop'];floor.location.z=-.25 if not self.profile.get('flatfish') else -.10
        core.point_cam(self.camera,(.60,-1.8,.55) if not self.profile.get('flatfish') else (.58,-.8,1.8))
        master=ROOT/'art_masters/3d'/f'{self.species}.blend';master_candidate=staging/master.name
        bpy.ops.wm.save_as_mainfile(filepath=str(master_candidate),copy=True,compress=bool(self.profile.get('compress_master',False)))
        assert master_candidate.stat().st_size>10000,'Incomplete master candidate'
        os.replace(master_candidate,master);os.replace(candidate,glb)
        manifest={'species':self.species,'pipeline_sha256':PIPELINE_SHA256,'triangles':sum(len(o.data.loop_triangles) for o in core.MESHES),'vertices':sum(len(o.data.vertices) for o in core.MESHES),'bones':list(self.bones),'skinned_meshes':len(core.MESHES),'materials':len(set(o.data.materials[0].name for o in core.MESHES)),'forward':'+X','godot_up':'+Y','rest_length_m':1,'morphology':self.profile['morphology'],'sources':self.profile['sources'],'glb_bytes':glb.stat().st_size,'glb_sha256':hashlib.sha256(glb.read_bytes()).hexdigest(),'flatfish':bool(self.profile.get('flatfish')),'ocular_side':self.profile.get('ocular_side','bilateral')}
        (self.review/'manifest.json').write_text(json.dumps(manifest,indent=2))
        validation_path=self.review/'validation.json';report=json.loads(validation_path.read_text());report['glb_sha256']=manifest['glb_sha256'];report['master_sha256']=hashlib.sha256(master.read_bytes()).hexdigest();validation_path.write_text(json.dumps(report,indent=2))
        print('FISH_PROFILE_READY '+json.dumps(manifest),flush=True)
    def render(self,quality=32,requested_views=None):
        s=bpy.context.scene;s.cycles.samples=quality;rig=self.rig_object
        model_meshes=[ob for ob in bpy.data.objects if ob.type=='MESH' and ob.parent==rig]
        bpy.data.objects['REVIEW_Backdrop'].location.z=min(v.co.z for ob in model_meshes for v in ob.data.vertices)-.06
        if 'REVIEW_UndersideFill' not in bpy.data.objects:
            bpy.ops.object.light_add(type='AREA',location=(.10,-.25,-1.2));light=bpy.context.object;light.name='REVIEW_UndersideFill';light.data.energy=42;light.data.size=1.3;light.rotation_euler=(Vector((0,0,0))-light.location).to_track_quat('-Z','Y').to_euler();light.hide_render=True
        views=[('hero',(.60,-1.8,.55) if not self.profile.get('flatfish') else (.58,-.8,1.8)),('side',(0,-2,.04)),('top',(0,0,2)),('underside',(0,0,-2))]
        for name,pos in views:
            if requested_views and name not in requested_views:continue
            core.point_cam(self.camera,pos)
            if name=='top':self.camera.rotation_euler=(0,0,0)
            bpy.data.objects['REVIEW_Backdrop'].hide_render=name=='underside'
            bpy.data.objects['REVIEW_UndersideFill'].hide_render=name!='underside'
            s.render.filepath=str(self.review/(name+'.png'));bpy.ops.render.render(write_still=True)
        bpy.data.objects['REVIEW_Backdrop'].hide_render=False
        bpy.data.objects['REVIEW_UndersideFill'].hide_render=True
        for clip,frame in [('swim',16),('struggle',10),('breach',12),('landed',24)]:
            if requested_views and ('pose_'+clip) not in requested_views:continue
            rig.animation_data.action=bpy.data.actions[clip];s.frame_set(frame);core.point_cam(self.camera,(.40,-1.6,.65) if not self.profile.get('flatfish') else (.45,-.7,1.8));s.render.filepath=str(self.review/('pose_'+clip+'.png'));bpy.ops.render.render(write_still=True)
        rig.animation_data.action=None

def tag_legacy_contacts(fish):
    """Audit-only tags derived from approved master UV roots, without saving or modifying art."""
    fish.attachment_groups={};bone_ids={};rig=fish.rig_object
    fin_names={b.name for b in rig.data.bones if b.name in ('dorsal','anal','caudal') or b.name.startswith(('pectoral_','pelvic_'))}
    for ob in core.MESHES:
        mats=[m.name for m in ob.data.materials]
        if any('ScaledSkin' in name for name in mats):
            marker=ob.data.attributes.get('fs_body_surface') or ob.data.attributes.new('fs_body_surface','INT','POINT');marker.data.foreach_set('value',[1]*len(ob.data.vertices))
        kind=1 if any('FinMembrane' in name for name in mats) else (2 if any(name=='FinRays' for name in mats) else 0)
        if not kind:continue
        uv=ob.data.uv_layers.active.data;root=set()
        for poly in ob.data.polygons:
            for li,vi in zip(poly.loop_indices,poly.vertices):
                if uv[li].uv.y<1e-6:root.add(vi)
        adjacency=[[] for _ in ob.data.vertices]
        for edge in ob.data.edges:
            a,b=edge.vertices;adjacency[a].append(b);adjacency[b].append(a)
        visited=set();tag=ob.data.attributes.get('fs_attachment') or ob.data.attributes.new('fs_attachment','INT','POINT');type_tag=ob.data.attributes.get('fs_attachment_kind') or ob.data.attributes.new('fs_attachment_kind','INT','POINT')
        for start in range(len(adjacency)):
            if start in visited:continue
            stack=[start];visited.add(start);component=[]
            while stack:
                vi=stack.pop();component.append(vi)
                for other in adjacency[vi]:
                    if other not in visited:visited.add(other);stack.append(other)
            sampled=set(component)&root
            if not sampled:continue
            influences={name:0 for name in fin_names}
            for vi in component:
                for group in ob.data.vertices[vi].groups:
                    name=ob.vertex_groups[group.group].name
                    if name in influences:influences[name]+=group.weight
            name=max(influences,key=influences.get)
            if name not in bone_ids:
                aid=len(bone_ids)+1;bone_ids[name]=aid;fish.attachment_groups[aid]={'name':name,'bone':name}
            aid=bone_ids[name]
            for vi in sampled:tag.data[vi].value=aid;type_tag.data[vi].value=kind

def run(species,no_render=False,views=None,samples=32):
    if species in PROTECTED:raise ValueError('Approved legacy fish are protected from catalog runner')
    module=load_profile(species);fish=Fish(module.PROFILE);module.anatomy(fish);fish.export()
    if not no_render:fish.render(samples,views)
    return fish
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--species',required=True);p.add_argument('--no-render',action='store_true');p.add_argument('--review-existing',action='store_true');p.add_argument('--validate-existing',action='store_true');p.add_argument('--views',default='');p.add_argument('--samples',type=int,default=32);args=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    views=set(args.views.split(',')) if args.views else None
    if args.review_existing or args.validate_existing:
        module=load_profile(args.species) if args.species not in PROTECTED else None;bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art_masters/3d'/f'{args.species}.blend'))
        fish=Fish.__new__(Fish);fish.profile=module.PROFILE if module else {'id':args.species};fish.species=args.species;fish.review=ROOT/'ownbuild/fish3d-catalog'/args.species;fish.review.mkdir(parents=True,exist_ok=True);fish.rig_object=bpy.data.objects['FishRig'];fish.camera=bpy.data.objects['REVIEW_Camera']
        if args.validate_existing:
            fish.audit_existing=True
            core.MESHES=[ob for ob in bpy.data.objects if ob.type=='MESH' and ob.parent==fish.rig_object]
            if args.species in PROTECTED:tag_legacy_contacts(fish)
            else:fish.attachment_groups=json.loads(fish.rig_object['attachment_groups'])
            fish.validate()
        else:fish.render(args.samples,views)
    else:run(args.species,args.no_render,views,args.samples)
