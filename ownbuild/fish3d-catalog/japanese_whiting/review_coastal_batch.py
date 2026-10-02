"""Read-only saved-master review runner, locking one view at a time. No canonical exports."""
import bpy,fcntl,importlib.util,json,sys,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'tools/art3d'))
import fish_pipeline as pipeline
IDS='mandarin_fish largemouth_bass japanese_seabass european_seabass red_seabream black_seabream gilthead_seabream saddled_seabream white_seabream annular_seabream common_pandora red_mullet painted_comber'.split()
VIEWS=['hero','side','top','underside','pose_swim','pose_struggle','pose_breach','pose_landed']
def load(s):
    module=pipeline.load_profile(s);bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art_masters/3d'/f'{s}.blend'))
    fish=pipeline.Fish.__new__(pipeline.Fish);fish.profile=module.PROFILE;fish.species=s;fish.review=ROOT/'ownbuild/fish3d-catalog'/s;fish.rig_object=bpy.data.objects['FishRig'];fish.camera=bpy.data.objects['REVIEW_Camera']
    return fish

def render(fish,view):
    if (fish.review/'review_render_settings.json').exists() and view in json.loads((fish.review/'review_render_settings.json').read_text()) and (fish.review/(view+'.png')).exists():return
    percentage=100 if view=='hero' or fish.species=='japanese_whiting' else 80
    samples=24 if view=='hero' else 16
    lock=None
    while lock is None:
        for path in ('/tmp/farshore-fish3d-render.lock','/tmp/farshore-fish3d-render-b.lock'):
            candidate=open(path,'w')
            try:fcntl.flock(candidate,fcntl.LOCK_EX|fcntl.LOCK_NB);lock=candidate;break
            except BlockingIOError:candidate.close()
        if lock is None:time.sleep(.4)
    with lock:
        s=bpy.context.scene;s.render.threads_mode='FIXED';s.render.threads=2;s.render.resolution_percentage=percentage
        fish.render(samples,{view})
        fcntl.flock(lock,fcntl.LOCK_UN)
    print('COASTAL_REVIEW_READY',fish.species,view,flush=True);time.sleep(.8)
    p=fish.review/'review_render_settings.json';d=json.loads(p.read_text()) if p.exists() else {}
    d[view]={'samples':samples,'resolution_percentage':percentage,'master':str(ROOT/'art_masters/3d'/f'{fish.species}.blend')}
    p.write_text(json.dumps(d,indent=2))

fish=load('japanese_whiting')
for view in ('side','underside','hero','top'):render(fish,view)
# Deliver all distinct silhouette heroes early, then complete alternate angles and poses.
for species in IDS:render(load(species),'hero')
for species in IDS:
    fish=load(species)
    for view in VIEWS[1:]:render(fish,view)
print('COASTAL_BATCH_COMPLETE',flush=True)
