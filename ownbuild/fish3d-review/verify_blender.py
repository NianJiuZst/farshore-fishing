import bpy,json,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
reports={}
for fish in ('common_carp','alligator_gar'):
    bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art_masters/3d'/f'{fish}.blend'))
    rig=bpy.data.objects['FishRig'];scene=bpy.context.scene
    meshes=[o for o in bpy.data.objects if o.type=='MESH' and o.parent==rig]
    def vertices(frame):
        scene.frame_set(frame);bpy.context.view_layer.update();dg=bpy.context.evaluated_depsgraph_get()
        points=[]
        for ob in meshes:
            ev=ob.evaluated_get(dg);me=ev.to_mesh();points.extend(v.co.copy() for v in me.vertices);ev.to_mesh_clear()
        return points
    weights=[sum(g.weight for g in v.groups) for o in meshes for v in o.data.vertices]
    clips={}
    for name in ('swim','struggle','breach','landed'):
        action=bpy.data.actions[name];rig.animation_data.action=action
        start,end=map(int,action.frame_range)
        a=vertices(start);b=vertices(start+(end-start)//4);c=vertices(end)
        delta=[(p-q).length for p,q in zip(a,b)];seam=max((p-q).length for p,q in zip(a,c))
        assert max(delta)>.001,(fish,name,'no skinned movement')
        assert seam<1e-5,(fish,name,'loop seam',seam)
        assert rig.pose.bones['root'].location.length<1e-8
        clips[name]={'start':start,'end':end,'seconds':(end-start)/30,'maximum_skin_displacement_m':max(delta),'rms_skin_displacement_m':math.sqrt(sum(d*d for d in delta)/len(delta)),'loop_seam_m':seam}
    reports[fish]={'skin_vertices':len(weights),'weight_sum_min':min(weights),'weight_sum_max':max(weights),'max_influences':max(len(v.groups) for o in meshes for v in o.data.vertices),'clips':clips}
    assert min(weights)>.999 and max(weights)<1.001
out=ROOT/'ownbuild/fish3d-review/blender_skinning_report.json';out.write_text(json.dumps(reports,indent=2));print('BLENDER_SKINNING_PASS '+json.dumps(reports))
