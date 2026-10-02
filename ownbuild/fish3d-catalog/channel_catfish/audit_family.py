"""Read-only final GLB catalog audit; original assets only, no texture conversion."""
from pathlib import Path
import struct,json,hashlib
root=Path(__file__).resolve().parents[3]
ids=['channel_catfish','flathead_catfish','southern_catfish','longsnout_catfish','bowfin','northern_snakehead']
for sid in ids:
 fn=root/'game/assets/3d'/f'{sid}.glb'
 if not fn.exists():continue
 b=fn.read_bytes();magic,version,size=struct.unpack_from('<4sII',b);n,typ=struct.unpack_from('<II',b,12);g=json.loads(b[20:20+n]);fail=[]
 anim={a['name']:a for a in g.get('animations',[])}
 if set(anim)!={'swim','struggle','breach','landed'}:fail.append('animation names')
 binstart=20+n+8
 def values(index):
  ac=g['accessors'][index];bv=g['bufferViews'][ac['bufferView']];off=binstart+bv.get('byteOffset',0)+ac.get('byteOffset',0);count=ac['count'];dim={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[ac['type']];stride=bv.get('byteStride',dim*4)
  return [struct.unpack_from('<'+'f'*dim,b,off+i*stride) for i in range(count)]
 translations=[];durations={}
 for a in g.get('animations',[]):
  times=[row[0] for sampler in a['samplers'] for row in values(sampler['input'])];durations[a['name']]=max(times)-min(times)
  expected={'swim':2.0,'struggle':1.2,'breach':1.4,'landed':3.0}[a['name']]
  if abs(durations[a['name']]-expected)>1e-5:fail.append('clip duration '+a['name'])
  for c in a.get('channels',[]):
   if c['target']['path']!='translation':continue
   rows=values(a['samplers'][c['sampler']]['output']);variance=max(max(r[j] for r in rows)-min(r[j] for r in rows) for j in range(3));name=g['nodes'][c['target']['node']].get('name')
   if name=='root':translations.append({'clip':a['name'],'root_translation_range_m':variance})
   if variance>1e-5:fail.append('unexpected translation variation '+str(name))
 allpos=[];skinned=0;tri=0
 for mesh in g.get('meshes',[]):
  for p in mesh['primitives']:
   attrs=p['attributes'];ac=g['accessors'][attrs['POSITION']];allpos.append((ac['min'],ac['max']))
   if not {'JOINTS_0','WEIGHTS_0'}<=set(attrs):fail.append('unskinned primitive')
   else:skinned+=1
   tri+=g['accessors'][p['indices']]['count']//3
 length=max(x[1][0] for x in allpos)-min(x[0][0] for x in allpos)
 if abs(length-1)>1e-5:fail.append('rest X extent')
 if not g.get('skins'):fail.append('missing skin')
 evidence={'species':sid,'glb_sha256':hashlib.sha256(b).hexdigest(),'glb_bytes':len(b),'glb_version':version,'animations':durations,'root_motion_tests':translations,'skinned_primitives':skinned,'rest_x_extent_m':length,'triangles':tri,'embedded_images':len(g.get('images',[])),'failures':fail}
 (root/'ownbuild/fish3d-catalog'/sid/'glb_audit.json').write_text(json.dumps(evidence,indent=2))
 print(json.dumps(evidence))
 assert not fail,(sid,fail)
