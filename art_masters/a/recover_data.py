from pathlib import Path
import json,ast
root=Path(__file__).resolve().parents[2]
assets={r['asset_id']:r for r in json.loads((root/'docs/ASSETS_A.json').read_text())}
notes={}
for node in ast.parse((root/'art_masters/a/finalize_content.py').read_text()).body:
 if isinstance(node,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='notes' for t in node.targets):notes=ast.literal_eval(node.value)
rows=[
('common_carp','鲤鱼','Cyprinus carpio','lake',['lake_shore','lake_bay'],180,900,450,1500,'steady',.45,12,0,0,1,12,'常见','常见于欧洲低地缓流与湖泊的底层，在软底寻找食物。这里表现的是普通有鳞湖鲤；各地种群也可能来自历史引入。','粗壮体形，黄褐色大鳞；口角有须，背鳍基部长，尾鳍分叉。',[1.2,2.0,.3,.15]),
('crucian_carp','欧洲鲫','Carassius carassius','lake',['lake_shore'],120,400,230,280,'rest',.18,15,0,0,1,5,'常见','喜欢植被丰富的浅水静水区。与鲤鱼不同，口角没有须。','短而高的金铜色侧扁身体，小口无须，背鳍外缘微凸，尾鳍浅叉。',[1.5,1.8,.3,.1]),
('roach','拟鲤','Rutilus rutilus','lake',['lake_shore','lake_bay'],100,380,220,160,'rest',.15,16,0,0,1,10,'常见','广布于欧洲低地湖泊与缓流，既能在岸边水草间活动，也会结群进入开阔水面。','银色侧扁身体，成鱼红色虹膜，腹鳍和臀鳍橙红，端位小口；背鳍起点约在腹鳍上方。',[1.5,1.6,.3,.2]),
('rudd','红眼鱼','Scardinius erythrophthalmus','lake',['lake_shore'],100,400,240,240,'burst',.24,12,0,0,1,5,'常见','欧洲低地水域的水草居民，取食植物、昆虫和浮游生物。金色体侧与鲜红下鳍很醒目。','略高的金银色身体，向上翘的小口，鲜红腹鳍与臀鳍，背鳍起点明显位于腹鳍之后。',[1.5,1.7,.2,.3]),
('european_perch','河鲈','Perca fluviatilis','lake',['lake_shore','lake_bay'],120,480,280,330,'burst',.42,11,0,.1,1,15,'常见','欧洲湖泊常见的掠食性鱼，幼鱼多结群。它的竖带和橙红色下鳍是很好的辨认线索。','黄绿色体侧有5至8道深色竖带，两个分开的背鳍，前背鳍末部有黑斑，下鳍橙红。',[1.3,.15,1.0,1.8]),
('northern_pike','白斑狗鱼','Esox lucius','lake',['lake_bay'],300,1100,600,1600,'burst',.72,4,1,.35,1,15,'少见','常在有植被的静水中伏击猎物。细长身体、扁平吻部和靠后的背鳍适合突然加速。','长鱼雷形身体，扁鸭嘴状吻，大口；背鳍和臀鳍靠近尾部，橄榄绿色体侧有浅色斑。',[.3,.05,.6,2.5]),
('common_bream','欧鳊','Abramis brama','lake',['lake_bay'],180,700,420,1000,'steady',.38,10,0,.15,1,15,'常见','常在湖泊和缓流水域结群活动，在底部寻找昆虫幼虫、小型甲壳类和软体动物。','高而侧扁的铜银色身体，小头与下位可伸缩口；臀鳍基部长，鳍呈灰黑色，深叉尾。',[1.8,1.6,.5,.1]),
('tench','丁鱥','Tinca tinca','lake',['lake_shore','lake_bay'],180,600,360,750,'steady',.44,7,0,.05,1,8,'少见','偏爱温暖、泥底且水草丰富的静水。细鳞藏在厚皮下，身体呈柔和的橄榄绿色。','厚实橄榄绿身体，细小嵌入鳞，小红眼，厚唇与一对短须；各鳍圆钝，尾柄粗短。',[2.0,1.5,.4,.1]),
('japanese_horse_mackerel','日本竹荚鱼','Trachurus japonicus','japan',['japan_harbor','japan_reef'],120,380,240,150,'burst',.35,14,0,.1,2,30,'常见','西北太平洋的群游鱼。近岸小型个体可在港湾与沿岸活动；随年龄增长可转向更深水。','银白色纺锤形身体，青绿背，鳃盖上后缘黑斑；侧线弯曲并具明显棱鳞，尾深叉，无小离鳍。',[.5,.1,1.8,1.4]),
('chub_mackerel','日本鲭','Scomber japonicus','japan',['japan_reef'],180,500,320,350,'burst',.50,10,1,.3,2,40,'常见','在西北太平洋沿岸与陆架水域结群游动。游戏只配置外侧礁岸可遇到的近岸群体。','流线型青蓝背，背部有曲折深条纹，银白腹无斑点；背鳍后和臀鳍后各列小离鳍，尾深叉。',[.2,.05,1.4,2.0]),
('red_seabream','真鲷','Pagrus major','japan',['japan_reef'],180,700,380,900,'steady',.58,6,1,.35,10,40,'少见','日本近海的底栖鲷科鱼，可生活在礁石和砂底。外礁较深处是本游戏的寻找线索。','粉红至赤铜色的高侧扁身体，细小蓝色斑点，连续棘状背鳍，叉形尾，尾后缘较暗。',[.8,.1,2.3,.9]),
('black_seabream','黑鲷','Acanthopagrus schlegelii','japan',['japan_harbor','japan_reef'],180,480,330,600,'steady',.52,8,1,.15,3,40,'少见','分布于西北太平洋的近岸鱼，能利用河口、港湾及礁沙混合生境。强壮的颌部可处理硬壳食物。','深灰银色的高侧扁身体，略高凸的额头，小而结实的口，连续背鳍有硬棘，尾鳍分叉。',[1.2,.2,2.0,.6]),
('japanese_seabass','日本花鲈','Lateolabrax japonicus','japan',['japan_harbor','japan_reef'],250,900,520,1500,'burst',.68,5,1,.25,5,40,'少见','日本沿岸与河口的掠食鱼，常取食小鱼和虾。这里使用日本花鲈，未把斑点花鲈混作同一种。','修长银色身体、灰绿背部，成鱼侧面通常无明显密集黑斑；大斜口下颌略突出，背鳍棘部和软条部有凹口。',[.3,.05,1.1,2.5]),
('japanese_whiting','日本沙鮻','Sillago japonica','japan',['japan_harbor'],100,290,200,70,'rest',.20,15,0,0,1,20,'常见','活动于浅海湾的沙质底，吃沙泥中的小型无脊椎动物。港内沙底是容易尝试的钓点。','细长近圆筒形银米色身体，尖吻小口，两个背鳍，后背鳍和臀鳍长而低，鳍透明，尾浅凹。',[2.2,.1,1.7,.3]),
('marbled_rockfish','褐菖鲉','Sebastiscus marmoratus','japan',['japan_reef'],120,330,230,250,'rest',.42,10,0,.1,1,30,'常见','日本沿岸岩底居民，常借斑驳体色隐蔽。背鳍棘具有毒腺，现实中观察时不要徒手抓握。','粗壮大头，宽大口，褐红色不规则大理石斑；连续背鳍前部硬棘，宽扇状胸鳍，圆尾。',[1.0,.05,2.0,1.2]),
('olive_flounder','牙鲆','Paralichthys olivaceus','japan',['japan_reef'],220,850,480,1100,'rest',.61,4,1,.35,10,40,'少见','栖息于西北太平洋沿岸沙底的扁平掠食鱼。成年个体双眼同在左侧，常伏在底部等候猎物。','长椭圆扁平身体，左眼侧朝向观察者，双眼可见；橄榄褐斑驳体色，大口，长背鳍和臀鳍沿体缘伸展。',[.6,.05,1.6,2.0]),
]
fish=[]
for id,name,sci,region,spots,mi,ma,anchor,mass,behavior,diff,weight,gear,cast,dmin,dmax,rarity,desc,morph,baits in rows:
 fish.append(dict(species_id=id,name=name,scientific_name=sci,region_ids=[region],spot_ids=spots,art=f'res://assets/fish/{id}.png',thumb=f'res://assets/fish/{id}_thumb.png',description=desc,morphology=morph,sources=assets[id]['reference_sources'],min_mm=mi,max_mm=ma,anchor_mm=anchor,anchor_g=mass,weight_model_note='游戏调校：长度为近似全长，按尺寸锚点立方缩放并作轻微体况变化；非实测科研系数，也非世界纪录范围。',behavior=behavior,difficulty=diff,weight=weight,bait_weights=dict(zip(['worm','grain','shrimp','lure'],baits)),time_weights={'day':1.,'dusk':1.2 if behavior!='rest' else 1.1},weather_weights={'clear':1.,'rain':1.1},min_gear=gear,min_cast=cast,max_cast=1.,depth_min_m=dmin,depth_max_m=dmax,salinity='fresh' if region=='lake' else 'salt',rarity=rarity,balance_note='稀有度、天气、时段、饵重、体重锚点和行为均为游戏调校，不主张是自然规律。',research_status='reviewed_2026-10-02',reachability_note=notes[id][0]))
p=root/'game/data/fish_a.json';p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(fish,ensure_ascii=False,indent=2)+'\n')
(root/'game/assets/fish').mkdir(parents=True,exist_ok=True)
print('Restored',len(fish),'fish definitions')
