import json, shutil, hashlib
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[2]
manifest=json.loads((root/'docs/ASSETS_B.json').read_text())
assets={x['asset_id']:x for x in manifest['assets']}
# Recovery from original task-visible creation transcript; sources from surviving final manifest.
# No session files or private execution history were accessed.
raw=[
('atlantic_cod','大西洋鳕','Gadus morhua',['norway'],['norway_harbor','norway_boat'],250,1050,650,2600,5,160,1,.15,'steady',.67,10,'少见','冷水近岸和峡湾底层的捕食者。下颌的一根须，像探寻海底的小触角。','三枚背鳍、两枚臀鳍；下颌须；浅色弯曲侧线；背部斑驳。',(.9,.05,1.5,1.4)),
('pollack','青鳕','Pollachius pollachius',['norway'],['norway_harbor','norway_boat'],220,900,550,1700,5,100,1,.1,'burst',.58,11,'常见','常在岩礁和海藻丛附近守候小鱼。侧线在胸鳍上方拱起，嘴部下颌略突出。','三枚背鳍、两枚臀鳍；无颏须；下颌突出；深色侧线明显弯曲。',(.6,.05,1.2,2.0)),
('saithe','绿青鳕','Pollachius virens',['norway'],['norway_harbor','norway_boat'],200,1000,600,2200,5,160,1,.15,'burst',.63,12,'常见','成群追逐小鱼的峡湾游泳健将。年轻个体常在挪威浅海岩岸附近聚集。','灰绿背、银白腹；笔直浅色侧线；三枚背鳍、两枚臀鳍；尾鳍分叉。',(.5,.05,1.3,2.1)),
('haddock','黑线鳕','Melanogrammus aeglefinus',['norway'],['norway_boat'],280,600,420,900,40,160,1,.25,'rest',.52,8,'少见','在冷水底层寻找蠕虫与小型无脊椎动物。胸鳍上方的黑斑是它醒目的记号。','黑色侧线与肩部黑斑；三枚背鳍、两枚臀鳍；第一背鳍高尖，颏须短。',(1.5,.05,1.6,.7)),
('atlantic_mackerel','大西洋鲭','Scomber scombrus',['norway','med'],['norway_harbor','norway_boat','med_boat'],200,500,350,500,2,60,0,0,'burst',.42,16,'常见','沿着水层成群游动，流线型身体适合快速追逐。挪威与地中海都能遇见这个物种。','蓝绿背上深色波状斜纹；银腹无斑；两枚主背鳍后有小鳍；深叉尾。',(.3,.05,.8,2.4)),
('atlantic_herring','大西洋鲱','Clupea harengus',['norway'],['norway_boat'],170,380,270,230,2,60,0,0,'burst',.3,15,'常见','银色鱼群在海面下闪动。船钓水层中的小型目标，深叉尾和单枚背鳍很容易辨认。','修长侧扁银身、暗蓝背；一枚背鳍；尾深叉，嘴略上翘。',(.15,.05,1.1,1.8)),
('european_plaice','欧洲鲽','Pleuronectes platessa',['norway'],['norway_harbor','norway_boat'],180,550,350,650,5,80,0,.05,'rest',.37,10,'常见','沙底上安静伏着的扁平鱼。两只眼睛都在同一侧，橙红色斑点点缀着褐色背面。','右眼侧扁平椭圆体；双眼在同一面；鲜明橙红斑点；长背臀鳍缘。',(2.2,.05,1.5,.2)),
('atlantic_wolffish','大西洋狼鱼','Anarhichas lupus',['norway'],['norway_boat'],400,1100,750,4000,100,160,2,.45,'steady',.86,5,'稀有','深水岩缝中的强壮居民，粗壮牙齿可以压碎硬壳食物。本作需要船钓深水和进阶装备。','宽大头部、犬齿状前牙；蓝灰体色与深竖带；连续长背鳍，无腹鳍，圆尾。',(.4,.05,2.4,.3)),
('european_seabass','欧洲海鲈','Dicentrarchus labrax',['med'],['med_pier','med_boat'],250,800,450,1100,1,50,1,.15,'burst',.65,9,'少见','巡游于海岸与河口的银色猎手。会捕食小鱼和甲壳动物，码头外侧也是相遇的地方。','银色修长身体，灰蓝背；两枚分离背鳍，第一背鳍带硬棘；成鱼无体侧斑点。',(.5,.05,1.4,2.2)),
('gilthead_seabream','金头鲷','Sparus aurata',['med'],['med_pier','med_boat'],220,650,380,1100,2,50,1,.1,'steady',.64,10,'少见','眼间像戴着一道金色发带。常在地中海海草、岩石和沙地附近寻找贝类等食物。','高而侧扁的银色椭圆体；金色额带；鳃盖上方黑斑，下缘略红；单枚连续背鳍。',(1.3,.1,2.4,.2)),
('saddled_seabream','黑尾海鲷','Oblada melanura',['med'],['med_pier','med_boat'],120,300,220,210,1,30,0,0,'burst',.35,15,'常见','沿着岩岸上方结伴游动。尾柄有一道白边黑鞍斑，小嘴微微上翘。','银灰略长的椭圆体；尾柄白边黑鞍斑；细纵线、略上翘的嘴；单背鳍和叉尾。',(1.0,.25,1.8,.8)),
('white_seabream','白海鲷','Diplodus sargus',['med'],['med_pier','med_boat'],150,420,270,450,1,35,0,.05,'steady',.48,13,'常见','海岸礁石与港口附近常见的小型鲷鱼。尾柄黑鞍斑和深色腹鳍帮助它与近亲区别。','高而侧扁的银灰身体；尾柄黑鞍斑未绕到底部；鳃盖黑边；腹鳍深色，幼鱼竖纹较明显。',(1.8,.1,2.0,.3)),
('annular_seabream','环尾海鲷','Diplodus annularis',['med'],['med_pier','med_boat'],100,250,160,110,1,15,0,0,'rest',.24,18,'常见','体型不大，喜欢浅水海草和安静的港湾。尾柄近乎完整的黑环与黄色腹鳍很醒目。','银体略泛黄；尾柄近乎闭合黑环；腹鳍及臀鳍前部黄色；体侧不画白海鲷幼鱼的竖纹。',(1.8,.15,1.5,.2)),
('red_mullet','红须鲷','Mullus barbatus',['med'],['med_boat'],120,300,210,160,10,60,0,.1,'rest',.32,12,'常见','用下巴的两条触须在泥沙中寻找食物。浅粉与银色鳞片，在光下显出温柔的红晕。','长体、额头陡；下颌两根白须；两枚分离背鳍，第一背鳍不带条纹；浅粉银身。',(2.0,.05,1.8,.15)),
('painted_comber','字纹鮨','Serranus scriba',['med'],['med_pier','med_boat'],100,280,180,130,1,30,0,.05,'burst',.43,11,'常见','岩礁旁的小型伏击者，头部细纹像书写的笔迹，腹部有一片淡蓝色。','头部红蓝细纹；体侧5–7条深竖带；腹部蓝斑；尾柄与尾发黄；连续棘软背鳍。',(.7,.05,1.8,1.5)),
('common_pandora','绯小鲷','Pagellus erythrinus',['med'],['med_boat'],160,450,280,450,20,60,1,.2,'steady',.51,8,'少见','在近岸较深的沙泥底寻找食物。银粉色身体和细小蓝点，像一页明亮的旅行纪念。','粉红银色侧扁体；头部近直线轮廓、吻较长；上身细蓝点；鳃盖上缘红；尾分叉。',(1.6,.05,2.0,.3))]
fish=[]
for row in raw:
 id,name,sci,reg,spots,mn,mx,am,ag,dmin,dmax,gear,cast,beh,dif,w,rar,desc,morph,bait=row
 fish.append(dict(species_id=id,name=name,scientific_name=sci,region_ids=reg,spot_ids=spots,art=f'res://assets/fish/{id}.png',thumb=f'res://assets/fish/{id}_thumb.png',description=desc,morphology=morph,sources=assets[id]['research_sources'],min_mm=mn,max_mm=mx,anchor_mm=am,anchor_g=ag,weight_model_note='游戏调校：尺寸范围为合理垂钓个体范围，按尺寸锚点立方缩放并加入温和体况变化，非科研系数或世界纪录',behavior=beh,difficulty=dif,weight=w,bait_weights=dict(zip(['worm','grain','shrimp','lure'],bait)),time_weights={'day':1.0,'dusk':1.15 if beh!='rest' else .95},weather_weights={'clear':1.0,'rain':1.05},min_gear=gear,min_cast=cast,max_cast=1.0,depth_min_m=dmin,depth_max_m=dmax,salinity='salt',rarity=rar,gameplay_note='遭遇、鱼饵倍率、时段、天气、稀有度、战斗行为与重量锚点均为游戏调校；不能据此推断现实捕捞法规。'))
(root/'game/data').mkdir(parents=True,exist_ok=True)
(root/'game/assets/fish').mkdir(parents=True,exist_ok=True)
(root/'game/data/fish_b.json').write_text(json.dumps(fish,ensure_ascii=False,indent=2)+'\n')
for a in manifest['assets']:
 im=Image.open(root/a['master_path'])
 im.thumbnail((1024,1024),Image.Resampling.LANCZOS);im.save(root/a['runtime_path'])
 assert hashlib.sha256((root/a['runtime_path']).read_bytes()).hexdigest()==a['runtime_sha256'], a['asset_id']+' hash mismatch'
 assert list(im.size)==a['runtime_dimensions'] and im.mode=='RGBA'
 im.thumbnail((256,256),Image.Resampling.LANCZOS);im.save(root/a['thumbnail_path'])
 assert list(im.size)==a['thumbnail_dimensions'] and im.mode=='RGBA'
backup=Path('/workspace/shared/farshore-recovery-backup/b')
(backup/'assets/fish').mkdir(parents=True,exist_ok=True)
(backup/'data').mkdir(parents=True,exist_ok=True)
shutil.copy2(root/'game/data/fish_b.json',backup/'data/fish_b.json')
for a in manifest['assets']:
 for key in ['runtime_path','thumbnail_path']:
  shutil.copy2(root/a[key],backup/'assets/fish'/Path(a[key]).name)
assert len(fish)==16==len({f['species_id'] for f in fish})
assert len(list((backup/'assets/fish').glob('*.png')))==32
checks=[]
for f in fish:
 assert f['min_mm']<f['anchor_mm']<f['max_mm']
 assert 0<=f['min_cast']<=.85 and 0<=f['difficulty']<=1
 for key in ['art','thumb']:
  p=root/'game'/f[key][6:]; assert p.exists()
  b=backup/'assets/fish'/p.name
  assert p.read_bytes()==b.read_bytes()
  checks.append({'path':str(p.relative_to(root)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
assert (root/'game/data/fish_b.json').read_bytes()==(backup/'data/fish_b.json').read_bytes()
(backup/'RECOVERY_VERIFIED.json').write_text(json.dumps({'species':16,'png_files':32,'pre_loss_main_texture_hashes_matched':16,'data_sha256':hashlib.sha256((backup/'data/fish_b.json').read_bytes()).hexdigest(),'files':checks},indent=2)+'\n')
print('VERIFIED: 16 species +32 PNG files restored; all16 main textures exactly match pre-loss SHA256;32 backup images byte-identical; JSON backup byte-identical.')
print('Backup:',backup)
