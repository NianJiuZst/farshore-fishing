"""Independent GLB structure/normalization/animation contract audit for this authored batch."""
import ast,hashlib,json,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
IDS='japanese_whiting marbled_rockfish mandarin_fish largemouth_bass japanese_seabass european_seabass red_seabream black_seabream gilthead_seabream saddled_seabream white_seabream annular_seabream common_pandora red_mullet painted_comber'.split()
outline_hashes=set();glb_hashes=set();geometry_hashes=set()
for species in IDS:
 p=ROOT/'game/assets/3d'/f'{species}.glb';data=p.read_bytes();magic,version,length=struct.unpack_from('<4sII',data);assert magic==b'glTF' and version==2 and length==len(data)
 jl,jt=struct.unpack_from('<II',data,12);assert jt==0x4e4f534a;d=json.loads(data[20:20+jl]);bl,bt=struct.unpack_from('<II',data,20+jl);assert bt==0x004e4942;blob=data[28+jl:28+jl+bl]
 def values(index):
  a=d['accessors'][index];view=d['bufferViews'][a['bufferView']];base=view.get('byteOffset',0)+a.get('byteOffset',0);width={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']];fmt={5126:'f',5125:'I',5123:'H',5121:'B'}[a['componentType']];size=struct.calcsize(fmt)*width;stride=view.get('byteStride',size)
  return [struct.unpack_from('<'+fmt*width,blob,base+i*stride) for i in range(a['count'])]
 clips=[a['name'] for a in d['animations']];assert sorted(clips)==sorted(['swim','struggle','breach','landed'])
 skin_nodes=[n for n in d['nodes'] if 'mesh' in n and 'skin' in n];assert skin_nodes
 all_positions=[];weighted_primitives=0
 for node in skin_nodes:
  for primitive in d['meshes'][node['mesh']]['primitives']:
   attrs=primitive['attributes'];assert 'JOINTS_0' in attrs and 'WEIGHTS_0' in attrs;weighted_primitives+=1
   all_positions+=values(attrs['POSITION'])
   for w in values(attrs['WEIGHTS_0']):assert abs(sum(w)-1)<.001
 position_sha=hashlib.sha256(b''.join(struct.pack('<fff',*v) for v in sorted(all_positions))).hexdigest();assert position_sha not in geometry_hashes;geometry_hashes.add(position_sha)
 mins=[min(v[j] for v in all_positions) for j in range(3)];maxs=[max(v[j] for v in all_positions) for j in range(3)]
 assert abs(maxs[0]-mins[0]-1)<1e-5 and abs(maxs[0]+mins[0])<1e-5,(species,mins,maxs)
 root_nodes={i for i,n in enumerate(d['nodes']) if n.get('name')=='root'};root_motion=0.0;root_channels=[]
 for clip in d['animations']:
  for ch in clip['channels']:
   if ch['target']['node'] in root_nodes:
    path=ch['target']['path'];vals=values(clip['samplers'][ch['sampler']]['output']);root_channels.append(path)
    if path=='translation':root_motion=max(root_motion,max(abs(x-y) for v in vals for x,y in zip(v,vals[0])))
 assert root_motion<1e-7
 glb_hash=hashlib.sha256(data).hexdigest();assert glb_hash not in glb_hashes;glb_hashes.add(glb_hash)
 source=ast.parse((ROOT/'tools/art3d/fish_profiles'/f'{species}.py').read_text())
 profile=next(n.value for n in source.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='PROFILE' for t in n.targets))
 sections=ast.literal_eval(next(val for key,val in zip(profile.keys,profile.values) if isinstance(key,ast.Constant) and key.value=='sections'))
 outline=hashlib.sha256(json.dumps(sections).encode()).hexdigest();assert outline not in outline_hashes;outline_hashes.add(outline)
 result={'species':species,'glb_sha256':glb_hash,'weighted_primitives':weighted_primitives,'skin_nodes':len(skin_nodes),'four_clips':clips,'root_translation_drift_m':root_motion,'root_channels':root_channels,'rest_bounds_glb':{'min':mins,'max':maxs},'normalized_x_length_m':maxs[0]-mins[0],'unique_geometry_position_sha256':position_sha,'unique_outline_sha256':outline,'passed':True}
 (ROOT/'ownbuild/fish3d-catalog'/species/'glb_contract.json').write_text(json.dumps(result,indent=2));print(species,'PASS',len(data),weighted_primitives)
print('15/15 independent GLB contract audits passed')
