# 原三海新增鱼类资料与玩法分离说明

核查日：2026-10-04。本文件覆盖 24 种；稳定 species_id 与素材路径一一对应。现有物种文件不改写。

游戏海域按特色分配，并非声明现实全球独有。真实分布、栖深与量法见 encyclopedia_g.json；尺寸体重模型、装备、饵料、遭遇权重与张力行为见 fish_g.json。全部故事为有来源的自然史或研究概述，不虚构亲历见闻。

## 逐种核查与素材形态约束

| ID / 中文名 | 学名与游戏钓点 | 游戏水层 / 行为 | 资料核查要点 |
|---|---|---|---|
| `california_sheephead` · 加州羊头鱼 | Bodianus pulcher · `pacific_reef` | 3—30 m · steady | 采用 FishBase 与 California Sea Grant 当前名 Bodianus pulcher；旧文献常用 Semicossyphus pulcher，为同一物种，ID 不变。 |
| `lingcod` · 长蛇齿单线鱼 | Ophiodon elongatus · `pacific_reef` | 10—60 m · burst | 英文 lingcod 并非鳕鱼；属六线鱼科。 |
| `cabezon` · 巨头杜父鱼 | Scorpaenichthys marmoratus · `pacific_reef` | 3—60 m · rest | 当前 FishBase 归于 Jordaniidae；旧资料可放在 Cottidae 或 Scorpaenichthyidae。俗称 sculpin，不是鲉科狮子鱼。 |
| `garibaldi` · 加里波第鱼 | Hypsypops rubicundus · `pacific_reef` | 2—30 m · burst | 以 Hypsypops rubicundus 为界，英文 garibaldi 也指意大利历史人物，不是另外一个鱼属。 |
| `kelp_greenling` · 斑点六线鱼 | Hexagrammos decagrammus · `pacific_reef` | 3—45 m · rest | 本条固定为 Hexagrammos decagrammus，不能因斑纹相近就混入同属岩六线鱼或大泷六线鱼。 |
| `pacific_halibut` · 太平洋庸鲽 | Hippoglossus stenolepis · `pacific_bluewater` | 30—180 m · steady | 与大西洋庸鲽 Hippoglossus hippoglossus 为不同种；本条为北太平洋右眼鲽。 |
| `yellow_tang` · 黄高鳍刺尾鱼 | Zebrasoma flavescens · `pacific_reef` | 3—40 m · burst | Zebrasoma flavescens 并非夏威夷全球独有；属于刺尾鱼科高鳍刺尾鱼属。 |
| `barreleye` · 管眼鱼 | Macropinna microstoma · `pacific_bluewater` | 500—700 m · rest | “管眼鱼”可泛指后肛鱼科；本条专指北太平洋 Macropinna microstoma，不把整科的三大洋分布套给本种。 |
| `turbot` · 大菱鲆 | Scophthalmus maximus · `atlantic_shelf` | 20—70 m · steady | 大菱鲆当前名 Scophthalmus maximus；Psetta maxima 为旧组合，黑海近缘种的旧亚种记录不混算。 |
| `john_dory` · 海鲂 | Zeus faber · `atlantic_shelf` | 50—90 m · rest | 本条为东北大西洋 Zeus faber；Fishes of Australia 提示部分南非、澳洲、日本旧记录涉及 Zeus japonicus，不能据旧同名记录声称全球同种。 |
| `grey_gurnard` · 灰鲂鮄 | Eutrigla gurnardus · `atlantic_shelf` | 10—90 m · rest | 当前名 Eutrigla gurnardus；旧组合 Trigla gurnardus、Chelidonichthys gurnardus 不另建收藏条目。 |
| `queen_angelfish` · 蓝额刺盖鱼 | Holacanthus ciliaris · `atlantic_shelf` | 5—65 m · steady | 以 Holacanthus ciliaris 为准；相似蓝刺盖鱼 H. bermudensis 及杂交体不当作本种。 |
| `stoplight_parrotfish` · 绿鹦嘴鱼 | Sparisoma viride · `atlantic_shelf` | 5—50 m · steady | FishBase 当前将鹦嘴鱼亚科 Scarinae 纳入 Labridae；旧图鉴常作 Scaridae。STRI 明确巴西姊妹种为 Sparisoma amplum，不能混入。 |
| `atlantic_flyingfish` · 大西洋飞鱼 | Cheilopogon melanurus · `atlantic_shelf` | 0.5—12 m · burst | 本条为 Cheilopogon melanurus；飞鱼科其他同样“四翼”的物种不能仅凭飞行轮廓混认。 |
| `atlantic_tarpon` · 大海鲢 | Megalops atlanticus · `atlantic_shelf` | 5—30 m · burst | Megalops atlanticus 为大西洋大海鲢；印度—太平洋的 M. cyprinoides 为另一种，不为增加重叠而合并。 |
| `black_scabbardfish` · 黑带鱼 | Aphanopus carbo · `atlantic_bluewater` | 250—700 m · steady | 固定 Aphanopus carbo；其他海区 Aphanopus 近缘种和白银带鱼不因带形而合并。 |
| `humphead_wrasse` · 波纹唇鱼 | Cheilinus undulatus · `indian_reef` | 3—60 m · steady | 当前 FishBase 与 WoRMS 接受 Cheilinus undulatus。Near 等 2025 年分类研究提出 Crassilabrus undulatus 新组合；来源更新与处理尚未一致，不把该新组合宣称为统一接受名。 |
| `emperor_angelfish` · 主刺盖鱼 | Pomacanthus imperator · `indian_reef` | 5—60 m · steady | Pomacanthus imperator 为本条接受名；幼鱼圆环和成鱼横纹属于同种的成长变化。 |
| `leaf_scorpionfish` · 叶须鲉 | Taenianotus triacanthus · `indian_reef` | 5—20 m · rest | Taenianotus triacanthus 是小型鲉科伏击鱼；不以枯叶轮廓混认鮟鱇鱼。 |
| `bluespotted_ribbontail_ray` · 蓝点鳐 | Taeniura lymma · `indian_reef` | 3—20 m · steady | 本种 Taeniura lymma 与蓝点为环状、常埋沙的其他魟鱼不同。盘宽 WD 与全长 TL 必须分别记录。 |
| `giant_moray` · 爪哇裸胸鳝 | Gymnothorax javanicus · `indian_reef` | 5—50 m · burst | Gymnothorax javanicus 为 giant moray，中文固定爪哇裸胸鳝；其他外形相近裸胸鳝不共用纪录。 |
| `collare_butterflyfish` · 红尾蝴蝶鱼 | Chaetodon collare · `indian_reef` | 3—20 m · burst | 接受名 Chaetodon collare；不能将相似白颈带的其他蝴蝶鱼或未接受拼写 C. collaris 合并为本种。 |
| `longhorn_cowfish` · 牛角箱鲀 | Lactoria cornuta · `indian_reef` | 3—50 m · steady | 以 Lactoria cornuta 为界，长前角与后下刺成对辨认；不把其他角箱鲀或普通河鲀混为本种。 |
| `russells_oarfish` · 拉氏皇带鱼 | Regalecus russellii · `indian_bluewater` | 40—180 m · rest | 接受名采用当前 FishBase 与 2025 年研究的 Regalecus russellii（双 l）；STRI 页面及旧 URL 用 russelii 为历史拼写。本条与 Regalecus glesne 分开，固定 ID 不变。 |

### 加州羊头鱼 · `california_sheephead`

成熟雄鱼头部和尾段近黑，中段红橙，白下巴、红眼与隆起额头突出；犬齿外露，身体厚实，连续背鳍；雌鱼较小且多为粉红色。

**现实生境：** 多在岩礁与巨藻林活动，常见 3—30 米；FishBase 另收录至 150 米的范围。游戏浅窗取常见礁区，并未压低所有现实记录。

**玩法：** 白天用虾饵探 3—30 米礁缘；持续控线，保护观察完成后放归。 普通游戏尺寸 25—70 厘米，低概率虚构巨物上端 100 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Bodianus pulcher — species summary](https://www.fishbase.se/summary/Semicossyphus-pulcher.html) — FishBase；支持 taxonomy, max_length, max_weight, habitat, distribution, diet, conservation。
- s2: [California sheephead](https://www.montereybayaquarium.org/animals-the-ocean/animals-a-to-z/california-sheephead) — Monterey Bay Aquarium；支持 typical_size, distribution, behavior, diet, story, morphology。
- s3: [California Sheephead](https://caseagrant.ucsd.edu/seafood-profiles/california-sheephead) — California Sea Grant / UC San Diego；支持 taxonomy, typical_size, habitat, behavior, story, morphology, conservation。

### 长蛇齿单线鱼 · `lingcod`

长身、宽大头与深口裂，颌上大小尖齿交错；眼上短皮瓣，棕灰或铜褐底色带不规则深斑，长连续背鳍与宽胸鳍，尾端近截形。

**现实生境：** 成鱼常在近岸岩礁，阿拉斯加介绍的常见约 9—101 米；FishBase 全部记录范围为潮间带至 475 米，幼鱼可用浅湾软底。

**玩法：** 拟饵沿礁区 10—60 米搜寻；突然冲刺时及时放松，再在停顿中收线。 普通游戏尺寸 40—115 厘米，低概率虚构巨物上端 165 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Ophiodon elongatus — species summary](https://www.fishbase.se/summary/Ophiodon-elongatus) — FishBase；支持 taxonomy, max_length, max_weight, habitat, distribution, diet, morphology。
- s2: [Lingcod species profile](https://www.adfg.alaska.gov/index.cfm?adfg=lingcod.printerfriendly) — Alaska Department of Fish and Game；支持 typical_size, habitat, distribution, behavior, diet, morphology。
- s3: [Submersible Observations on Lingcod Nests](https://spo.nmfs.noaa.gov/sites/default/files/pdf-content/MFR/mfr551/mfr5513.pdf) — O’Connell / NOAA Marine Fisheries Review (1993)；支持 story。

### 巨头杜父鱼 · `cabezon`

头部非常宽大、口阔，皮肤无鳞；眼后和吻部具肉质皮瓣，宽扇形胸鳍；褐、绿或红色底上有深色斑驳，尾端微圆，贴底轮廓厚重。

**现实生境：** 潮间带至约 200 米的岩礁、沙泥底与海藻林近底环境。成鱼常利用近岸立体结构伏击，并非必须住在洞穴。

**玩法：** 虾饵近中抛探底；停顿时收线，起身挣扎时留出余量。 普通游戏尺寸 20—70 厘米，低概率虚构巨物上端 108 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Scorpaenichthys marmoratus — species summary](https://www.fishbase.se/summary/Scorpaenichthys-marmoratus.html) — FishBase；支持 taxonomy, max_length, max_weight, habitat, distribution, diet。
- s2: [Cabezon](https://caseagrant.ucsd.edu/seafood-profiles/cabezon) — California Sea Grant / UC San Diego；支持 typical_size, max_length, habitat, behavior, diet, story, morphology。

### 加里波第鱼 · `garibaldi`

短而高的侧扁椭圆体，成鱼通体鲜橙，连续背鳍，尾鳍浅凹近心形；幼鱼带电蓝点与蓝鳍缘，模型以无蓝点成鱼为准。

**现实生境：** 清澈近岸岩礁与巨藻林，FishBase 记录深度 0—30 米；常靠礁缝与小洞活动。

**玩法：** 浅礁近抛，辨认橙色领地主；短促摆脱后再收线，完成观察自动放归。 普通游戏尺寸 10—28 厘米，低概率虚构巨物上端 39 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Hypsypops rubicundus — species summary](https://www.fishbase.se/summary/Hypsypops-rubicundus.html) — FishBase；支持 taxonomy, max_length, max_weight, habitat, distribution, behavior, diet。
- s2: [Garibaldi](https://www.montereybayaquarium.org/animals-the-ocean/animals-a-to-z/garibaldi) — Monterey Bay Aquarium；支持 typical_size, max_length, max_weight, habitat, distribution, behavior, diet, story, morphology, conservation。

最大体重未获得可靠数值，JSON 保留 null。

### 斑点六线鱼 · `kelp_greenling`

修长纺锤体、长连续背鳍，眼上肉质小皮瓣，尾鳍圆至截形；雄鱼灰褐底有不规则蓝点及褐缘，雌鱼金褐点更密、鳍偏橙黄；模型选雄鱼蓝点型。

**现实生境：** 近岸岩区与巨藻林，也见于沙底；FishBase 栖深上端约 46 米，浅端没有确定数值。本作 3—45 米是其中的虚拟窗口。

**玩法：** 虫饵浅礁中抛；利用休息段稳收，是分辨底层小鱼的好窗口。 普通游戏尺寸 17—43 厘米，低概率虚构巨物上端 65 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Hexagrammos decagrammus — species summary](https://www.fishbase.se/summary/Hexagrammos-decagrammus) — FishBase；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, behavior, diet。
- s2: [Kelp greenling](https://wdfw.wa.gov/species-habitats/species/hexagrammos-decagrammus) — Washington Department of Fish and Wildlife；支持 typical_size, max_length, max_weight, behavior, story, morphology。

### 太平洋庸鲽 · `pacific_halibut`

极侧扁的菱形扁体，两眼在右侧；有眼面灰褐斑驳、盲面白，背臀鳍沿两侧形成长边，口大、胸鳍较小，尾鳍略呈月弧。

**现实生境：** 利用多种底质，幼鱼在浅岸，随生长进入深水；成鱼夏季浅水取食、冬季向大陆坡深处产卵。FishBase 全部栖深记录可达 1200 米。

**玩法：** 外海 30—180 米拟饵或鱼肉类饵寻底；宽扁身持续施力，留意大鱼张力。 普通游戏尺寸 55—190 厘米，低概率虚构巨物上端 285 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Hippoglossus stenolepis — species summary](https://www.fishbase.se/summary/Hippoglossus-stenolepis.html) — FishBase；支持 taxonomy, max_length, max_weight, habitat, distribution, morphology。
- s2: [Pacific Halibut](https://www.fisheries.noaa.gov/species/pacific-halibut) — NOAA Fisheries；支持 typical_size, habitat, distribution, behavior, diet, story, morphology。

### 黄高鳍刺尾鱼 · `yellow_tang`

通体明黄、侧扁高身，背鳍与臀鳍撑开成帆，吻略尖、小口；尾柄两侧白色刀状刺，尾鳍浅凹，不能画成黄蓝混色的拟刺尾鱼。

**现实生境：** 珊瑚丰富的潟湖与向海外礁，常见记录约 3—46 米；通常在岩礁上方取食藻类。

**玩法：** 谷物类游戏植物饵在浅礁近抛；小体型短促冲刺，轻收更稳。 普通游戏尺寸 7—18 厘米，低概率虚构巨物上端 26 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Zebrasoma flavescens — species summary](https://www.fishbase.se/summary/Zebrasoma-flavescens.html) — FishBase；支持 taxonomy, max_length, max_weight, habitat, distribution, behavior, diet, morphology。
- s2: [Size at maturity for yellow tang from the Oahu aquarium fishery](https://repository.library.noaa.gov/view/noaa/32596) — Schemmel (2021) / Environmental Biology of Fishes / NOAA repository；支持 typical_size, max_weight, story。

最大体重未获得可靠数值，JSON 保留 null。

### 管眼鱼 · `barreleye`

短小深褐身、透明充液头罩，头内一对绿色管状眼可向上或前方转动；吻前两黑点是嗅孔而非眼，口很小；宽透明胸鳍支持悬停。

**现实生境：** 北太平洋深水中层。MBARI 加州 ROV 常见观察为 600—800 米；FishBase 汇总更宽的 16—1267 米记录。游戏 500—700 米为明确改编窗口，不能称 500 米是普遍典型栖深。

**玩法：** 5 号深海竿探 500—700 米；600—700 米覆盖 MBARI 观察水层，低张力停顿控线后完成保护观察。 普通游戏尺寸 4.5—14 厘米，低概率虚构巨物上端 18 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Macropinna microstoma — species summary](https://fishbase.se/summary/2704) — FishBase；支持 taxonomy, max_length, max_weight, habitat, distribution。
- s2: [Barreleye fish](https://www.mbari.org/animal/barreleye-fish/) — Monterey Bay Aquarium Research Institute (MBARI)；支持 typical_size, max_length, max_weight, habitat, distribution, diet。
- s3: [Researchers solve mystery of deep-sea fish with tubular eyes and transparent head](https://www.mbari.org/news/researchers-solve-mystery-of-deep-sea-fish-with-tubular-eyes-and-transparent-head/) — MBARI / Robison and Reisenbichler (2008)；支持 typical_size, habitat, behavior, diet, story, morphology, conservation。

最大体重未获得可靠数值，JSON 保留 null。

### 大菱鲆 · `turbot`

近圆盘形侧扁体，两眼在左侧、右侧卧底；有眼面沙褐至灰色细斑、散生骨瘤，盲面白；背鳍从吻前起，背臀鳍沿体缘但不连至尾下，尾鳍短而密斑。

**现实生境：** 常在大陆架沙、砾或贝壳砾底，偶见泥底与混合岩沙底，也可入半咸水。FishBase 栖深 20—70 米，MarLIN 介绍约 20—80 米。

**玩法：** 虾饵或拟饵探 20—70 米沙底；圆扁身持续抗线，稳住张力逐段收回。 普通游戏尺寸 20—80 厘米，低概率虚构巨物上端 115 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Scophthalmus maximus — species summary](https://www.fishbase.se/summary/Scophthalmus-maximus.html) — FishBase；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, diet。
- s2: [Turbot](https://www.marlin.ac.uk/species/detail/1917) — Marine Biological Association / MarLIN；支持 taxonomy, typical_size, max_length, habitat, distribution, behavior, story, morphology。

### 海鲂 · `john_dory`

极侧扁高身，橄榄黄至银褐体侧有浅圈围绕的蓝黑圆斑；口大且能前伸，长背棘及高出棘端的膜丝，背臀鳍基部骨盾，胸鳍较小，尾鳍圆至微截形。

**现实生境：** 近底生活，常靠大陆架底部活动；FishBase 记录 5—400 米、通常 50—150 米，游戏取原陆架可达的 50—90 米一段。

**玩法：** 50—90 米陆架拟饵慢探；休息段收线，看到突袭摆身时暂缓。 普通游戏尺寸 16—65 厘米，低概率虚构巨物上端 98 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Zeus faber — species summary](https://www.fishbase.se/summary/Zeus-faber.html) — FishBase；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, diet。
- s2: [John Dory](https://fishesofaustralia.net.au/home/species/1492) — Museums Victoria / Fishes of Australia / Bray 2025；支持 taxonomy, typical_size, max_length, distribution, behavior, diet, story, morphology。

### 灰鲂鮄 · `grey_gurnard`

头大且额部斜陡，体向尾渐细；灰褐略带红、白色小点、腹面乳白；前背鳍小且带大黑斑，后背鳍长；短胸鳍下三根独立肉质鳍条，侧线鳞隆起带刺，尾近截形。

**现实生境：** 多在沙底，也见岩底和泥底；沿岸至约 140 米较常见，FishBase 另有伊奥尼亚海深至 340 米记录。

**玩法：** 虫或虾饵探 10—90 米沙泥底；小幅挣扎后利用停顿收线。 普通游戏尺寸 10—35 厘米，低概率虚构巨物上端 65 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Eutrigla gurnardus — species summary](https://www.fishbase.se/summary/Eutrigla-gurnardus.html) — FishBase；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, diet。
- s2: [Grey gurnard](https://www.marlin.ac.uk/species/detail/162) — Marine Biological Association / MarLIN；支持 taxonomy, typical_size, max_length, habitat, morphology。
- s3: [Ontogeny of acoustic and feeding behaviour in the grey gurnard](https://researchportal.ulisboa.pt/en/publications/ontogeny-of-acoustic-and-feeding-behaviour-in-the-grey-gurnard-eu/) — Amorim and Hawkins (2005) / University of Lisbon / Ethology；支持 behavior, story。

### 蓝额刺盖鱼 · `queen_angelfish`

高身侧扁椭圆体、圆钝头、小刷状齿口，连续背鳍和臀鳍后端拖长；蓝绿底带黄橙鳞缘，额头黑斑有亮蓝环与点，尾鳍和胸鳍黄；模型用成鱼，不保留幼鱼蓝竖带。

**现实生境：** 近底珊瑚礁，常在海扇与珊瑚间独游或成对；由浅岸至约 70 米的深礁。

**玩法：** 浅陆架礁区 5—65 米近中抛；平稳控线观察黄尾与皇冠斑。 普通游戏尺寸 9—35 厘米，低概率虚构巨物上端 52 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Holacanthus ciliaris — species summary](https://www.fishbase.se/summary/Holacanthus-ciliaris.html) — FishBase；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, diet。
- s2: [Queen Angelfish](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/queen-angelfish/) — Florida Museum of Natural History / Patton and Bester；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, behavior, diet, story, morphology。

### 绿鹦嘴鱼 · `stoplight_parrotfish`

厚实中高侧扁体、大鳞、前吻鹦嘴状融合齿板；模型用终末相雄鱼：绿头绿身，颊部紫条、鳃盖上黄点、粉红蓝缘背臀鳍，尾基黄斑且尾鳍有黄色月弧，成鱼尾缘凹。

**现实生境：** 清水珊瑚礁；幼鱼亦在附近海草床。FishBase 常用 3—50 米，STRI 另汇总 0—107 米；游戏浅窗不覆盖全部记录。

**玩法：** 白天谷物类游戏植物饵探礁面 5—50 米；持续拉力中匀速收线。 普通游戏尺寸 14—46 厘米，低概率虚构巨物上端 72 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Sparisoma viride — species summary](https://www.fishbase.se/summary/Sparisoma-viride.html) — FishBase；支持 taxonomy, typical_size, max_length, max_weight, habitat, behavior, diet, story。
- s2: [Stoplight Parrotfish](https://biogeodb.stri.si.edu/caribbean/en/thefishes/species/3926) — Smithsonian Tropical Research Institute / Shorefishes of the Greater Caribbean；支持 taxonomy, max_length, habitat, distribution, morphology。

### 大西洋飞鱼 · `atlantic_flyingfish`

修长近矩形截面的银色体，上暗下白、小钝头小口；胸鳍极长、腹鳍也长，形成四翼轮廓；胸鳍灰有淡三角横带与透明窄缘，腹鳍透明，背鳍低短；深叉尾下叶明显长于上叶。

**现实生境：** 近岸和外海的表层游泳鱼；STRI 主要水层 0—5 米，FishBase 收录 0—20 米。0.5—12 米游戏窗口覆盖机构的近表层段并取 FishBase 较宽记录；浅钓时优先 0.5—5 米。

**玩法：** 陆架近表层 0.5—12 米搜寻；短促冲刺时松线，停顿再收，留意四翼轮廓。 普通游戏尺寸 12—29 厘米，低概率虚构巨物上端 38 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Cheilopogon melanurus — species summary](https://www.fishbase.se/summary/Cheilopogon-melanurus.html) — FishBase；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, behavior, story。
- s2: [Atlantic Flyingfish](https://biogeodb.stri.si.edu/caribbean/en/thefishes/species/3334) — Smithsonian Tropical Research Institute / Shorefishes of the Greater Caribbean；支持 taxonomy, max_length, max_weight, habitat, distribution, behavior, diet, story, morphology。

最大体重未获得可靠数值，JSON 保留 null。

### 大海鲢 · `atlantic_tarpon`

粗壮修长侧扁体、非常大的银鳞，背深蓝绿黑、腹侧亮银；大口向上、下颌突出，单背鳍末条拉成长丝，尾深叉两叶近等长，鳍灰暗且无硬棘。

**现实生境：** 主要利用沿岸、海湾、河口、红树林潟湖，可进入淡水。FishBase 记录 0—40 米、通常 0—15 米；改造的鳔能帮助在缺氧水中呼吸空气。

**玩法：** 浅陆架 5—30 米拟饵；银色巨体冲刺时放松，休息再收，观察完成必须放归。 普通游戏尺寸 50—220 厘米，低概率虚构巨物上端 295 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Megalops atlanticus — species summary](https://www.fishbase.se/summary/1079) — FishBase；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, behavior, diet, conservation。
- s2: [Tarpon](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/tarpon/) — Florida Museum of Natural History；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, behavior, diet, story, morphology。

### 黑带鱼 · `black_scabbardfish`

极长且侧扁的带状体，宽长吻和外露尖獠牙；皮肤铜黑带虹彩、口腔和鳃腔黑，长低背鳍与臀鳍、尾鳍分叉；成年完全无腹鳍，幼鱼才有单棘，不能画成常见白银带鱼的尖细无尾末端。

**现实生境：** 深水中层；FishBase 记录 200—2300 米、通常 700—1300 米。游戏 250—700 米只选较浅记录段，并非宣称通常生活在 250 米。

**玩法：** 5 号深海竿探 250—700 米浅端深水记录；细长身持续拉线，700 米靠近资料通常水层的上缘。 普通游戏尺寸 45—135 厘米，低概率虚构巨物上端 175 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Aphanopus carbo — species summary](https://www.fishbase.se/summary/Aphanopus-carbo.html) — FishBase；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, behavior, diet, morphology。
- s2: [Peixe-espada-preto / Aphanopus carbo](https://museubiodiversidade.uevora.pt/elenco-de-especies/biodiversidade-actual/animais/aphanopus-carbo/) — Universidade de Évora / Museu Virtual da Biodiversidade；支持 taxonomy, max_weight, story, morphology。

最大体重未获得可靠数值，JSON 保留 null。

### 波纹唇鱼 · `humphead_wrasse`

厚实高身，成年大鱼额部有明显肉质隆起，厚唇、犬齿与圆尾；橄榄绿鳞片带深竖纹，头部蓝绿色弯曲线纹、眼后两条暗线；幼鱼额头不夸张，模型选大型成鱼。

**现实生境：** 成鱼常在陡峭外礁坡、航道与潟湖，活动于 2—60 米；资料全部范围 0—100 米。幼鱼可利用珊瑚枝、藻类和海草中的庇护。

**玩法：** 礁坡 3—60 米虾饵慢探；隆额巨体持续拉线，完成保护观察后必须放归。 普通游戏尺寸 35—180 厘米，低概率虚构巨物上端 250 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Cheilinus undulatus — species summary](https://www.fishbase.se/summary/Cheilinus-undulatus.html) — FishBase；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, behavior, diet, story, morphology, conservation。
- s2: [Phylogenetic Taxonomy of Wrasses and Parrotfishes (Labridae)](https://www.nearlab.org/uploads/1/3/3/7/133700440/199_near_et_al2025wrasse_taxonomy.pdf) — Near et al. (2025) / Bulletin of the Peabody Museum of Natural History / Yale University；支持 taxonomy, behavior, story, morphology。
- s3: [Cheilinus undulatus — taxon details](https://www.marinespecies.org/aphia.php?id=218945&p=taxdetails) — World Register of Marine Species；支持 taxonomy, story。

### 主刺盖鱼 · `emperor_angelfish`

高身侧扁椭圆体、额部陡、口小；成鱼蓝底密集黄横纹，黑色眼罩带浅缘，胸鳍基后另有深色竖带，黄尾；幼鱼为深蓝底蓝白同心弧环，模型保留成鱼横纹。

**现实生境：** 清澈潟湖、水道与向海礁坡，资料范围 1—100 米。幼鱼常在岩沿、洞隙下，成鱼利用珊瑚丰富的庇护结构。

**玩法：** 礁缘 5—60 米慢探；平稳控线，注意成鱼横纹与幼鱼圆环的区别。 普通游戏尺寸 10—35 厘米，低概率虚构巨物上端 48 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Pomacanthus imperator — species summary](https://www.fishbase.se/summary/Pomacanthus-imperator.html) — FishBase；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, behavior, diet。
- s2: [Emperor Angelfish](https://fishesofaustralia.net.au/home/species/653) — Museums Victoria / Fishes of Australia；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, behavior, diet, story, morphology。

最大体重未获得可靠数值，JSON 保留 null。

### 叶须鲉 · `leaf_scorpionfish`

体小且强烈侧扁，长基底高背鳍以第三、四硬棘突出，背鳍软部连到尾鳍；皮肤无鳞而有细小突起、嘴周细皮瓣，尾小；颜色可黄、白、红或褐，模型选黄褐落叶色，保留细口裂与眼。

**现实生境：** 珊瑚礁上藻丛、海草及岩块间。FishBase 通常 5—20 米、全部范围 5—135 米；澳洲机构范围浅端为 1 米，游戏取两者常见交集。

**玩法：** 虫或虾饵浅礁慢探；以落叶摇摆的停顿窗口收线，避免只等高速冲刺。 普通游戏尺寸 3—8.5 厘米，低概率虚构巨物上端 13 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Taenianotus triacanthus — species summary](https://www.fishbase.se/summary/Taenianotus-triacanthus.html) — FishBase；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, behavior, diet, morphology。
- s2: [Leaf Scorpionfish](https://fishesofaustralia.net.au/home/species/3342) — Museums Victoria / Fishes of Australia；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, behavior, diet, story, morphology。

最大体重未获得可靠数值，JSON 保留 null。

### 蓝点鳐 · `bluespotted_ribbontail_ray`

椭圆盘形身体，背黄褐至橄榄色、亮蓝圆点，腹白；眼较大且后方具喷水孔，嘴和五对鳃孔在腹面；尾短粗渐细、两侧蓝条、尾下宽鳍褶延伸到末端，中后段尾刺；不加普通鱼的背鳍与扇形尾鳍。

**现实生境：** 浅珊瑚礁、近礁沙地及洞隙，FishBase 范围 0—20 米。退潮时常靠洞或岩沿庇护，资料称它很少埋入沙底。

**玩法：** 虫或虾饵探浅礁沙地 3—20 米；鳐盘持续摆动，观察完成后放归。 普通游戏尺寸 28—70 厘米，低概率虚构巨物上端 100 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Taeniura lymma — species summary](https://www.fishbase.se/summary/Taeniura-lymma.html) — FishBase；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, behavior, diet, story, morphology, conservation。
- s2: [Bluespotted Ribbontail Ray](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/bluespotted-ribbontail-ray/) — Florida Museum of Natural History / Bester；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, behavior, diet, story, morphology。

最大体重未获得可靠数值，JSON 保留 null。

### 爪哇裸胸鳝 · `giant_moray`

粗壮长鳗体、宽大颌与尖牙，小眼、窄圆鳃孔并有醒目黑斑；黄褐底，成年体侧大豹斑、头部细点；背臀尾鳍连成边缘，胸鳍与腹鳍缺失，不能添普通海鱼的成对侧鳍。

**现实生境：** 潟湖、向海珊瑚礁、礁坡与陡坎洞隙，范围 0—50 米；幼鱼也可进入潮间带。

**玩法：** 拟饵沿 5—50 米礁洞边搜寻；长身突然冲刺时松线，停顿再收。 普通游戏尺寸 50—230 厘米，低概率虚构巨物上端 330 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Gymnothorax javanicus — species summary](https://www.fishbase.se/summary/Gymnothorax-javanicus.html) — FishBase；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, behavior, diet, morphology。
- s2: [Giant Moray](https://fishesofaustralia.net.au/home/species/2041) — Museums Victoria / Fishes of Australia；支持 taxonomy, typical_size, max_length, habitat, distribution, morphology。
- s3: [Interspecific Communicative and Coordinated Hunting between Groupers and Giant Moray Eels in the Red Sea](https://journals.plos.org/plosbiology/article?id=10.1371/journal.pbio.0040431) — Bshary et al. (2006) / PLOS Biology；支持 behavior, diet, story。

### 红尾蝴蝶鱼 · `collare_butterflyfish`

高身近圆侧扁体，短尖吻、陡额；深褐体带细淡斜网纹，头后明显白色宽带至胸，眼部黑带前缘白，吻与下颌黑白相间；尾红、近外缘黑带、最外缘白，背臀鳍连续而有深浅缘。

**现实生境：** 浅珊瑚礁边缘与上部礁坡，范围 1—20 米；幼鱼可进入河口。孟加拉国资料在圣马丁岛珊瑚生态系统收录本种。

**玩法：** 浅礁 3—20 米近抛；短促摆身后再收线，白颈带配红尾是辨认组合。 普通游戏尺寸 6.5—17 厘米，低概率虚构巨物上端 24 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Chaetodon collare — species summary](https://www.fishbase.se/summary/Chaetodon-collare.html) — FishBase；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, behavior, diet。
- s2: [Chaetodon collare — Redtail butterflyfish](https://marinebiodiversity.org.bd/species/chaetodon-collare/) — Aquatic Bioresource Research Lab / Sher-e-Bangla Agricultural University / Marine Biodiversity Portal of Bangladesh；支持 taxonomy, typical_size, max_weight, habitat, distribution, story, morphology。

最大体重未获得可靠数值，JSON 保留 null。

### 牛角箱鲀 · `longhorn_cowfish`

硬质近四棱箱形躯壳，头前一对向前伸长角，躯壳后下方另一对长刺；绿橄榄、黄至橙底带蓝点，小口、小胸鳍，短背臀鳍靠后、尾柄伸出壳外；模型不能只给普通鱼额头装两根角。

**现实生境：** 沿岸沙泥底、港湾、河口及近礁有藻区；幼鱼也可进入河流和半咸水。范围 1—100 米，通常在 1—50 米。

**玩法：** 虫或虾饵沿浅礁沙地 3—50 米慢探；保持均匀张力，观察小鳍驱动的硬壳身。 普通游戏尺寸 10—40 厘米，低概率虚构巨物上端 56 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Lactoria cornuta — species summary](https://www.fishbase.se/summary/Lactoria-cornuta.html) — FishBase；支持 taxonomy, typical_size, max_length, max_weight, habitat, distribution, behavior, diet, morphology。
- s2: [Longhorn Cowfish](https://fishesofaustralia.net.au/home/species/837) — Museums Victoria / Fishes of Australia；支持 taxonomy, max_length, max_weight, habitat, distribution, behavior, diet, story, morphology。

最大体重未获得可靠数值，JSON 保留 null。

### 拉氏皇带鱼 · `russells_oarfish`

极长且强烈侧扁的银色带身，斜暗条、短横纹或圆斑，头蓝黑；红色背鳍从头顶一直延到尾端，前方两个鳍冠，第一冠为数条膜连鳍条、第二为一根独立长条；腹鳍为极长单鳍条且有皮瓣；没有臀鳍，成年通常没有尾鳍；胸鳍小而披针状、近头下方，不加扇形尾鳍。

**现实生境：** 上层至中层大洋水体；STRI 范围 15—1000 米、通常浅于 200 米。游戏 40—180 米取可靠资料可达段，不强行把全部皇带鱼压在六百米。

**玩法：** 2 号探深竿探外海 40—180 米；长鳍波动后留意休息窗口，完成巨带观察后放归。 普通游戏尺寸 150—600 厘米，低概率虚构巨物上端 1000 厘米；数值与真实自然史资料分开。

**来源字段：**
- s1: [Regalecus russellii — species summary](https://www.fishbase.se/summary/Regalecus-russelii.html) — FishBase；支持 taxonomy, max_length, max_weight。
- s2: [Regalecus russelii — The Oarfish](https://biogeodb.stri.si.edu/sftep/en/thefishes/species/5806) — Smithsonian Tropical Research Institute / Shorefishes of the Eastern Pacific；支持 max_length, max_weight, habitat, distribution, behavior, diet, morphology, conservation。
- s3: [First record of oarfish Regalecus russellii from Sri Lankan waters, Indian Ocean](https://www.researchgate.net/publication/393566216_First_record_of_oarfish_Regalecus_russellii_Actinopterygii_Lampriformes_Regalecidae_from_Sri_Lankan_waters_Indian_Ocean) — Rathnasuriya and Hapuarachchi (2025) / Acta Ichthyologica et Piscatoria 55:145–150 / Ocean University of Sri Lanka；支持 taxonomy, typical_size, distribution, behavior, story, morphology。

最大体重未获得可靠数值，JSON 保留 null。

## 校验与访问限制

- 24 个固定 scope ID 一一对应两份 JSON；三海各 8 种。逐条 `content_natural_history_contract.validate_entry` 全部通过，附加形态与保护字段引用也已自检；合计 55 个来源条目，每种至少 2 个机构、研究或数据库来源。
- 24 种均能在分配的原钓点，以声明的最低装备、合法抛投和水层窗口进入筛选。行为分配为持续拉力 10 种、冲刺 7 种、停顿 7 种；这三个行为族是现有游戏张力调校，不宣称实测运动数据。
- 管眼鱼 500—700 米须 5 号深海竿，MBARI 介绍常见 600—800 米；黑带鱼 250—700 米须 5 号竿，FishBase 通常 700—1300 米，本作只取较浅记录段。皇带鱼 40—180 米在 STRI 的通常浅于 200 米范围内，飞鱼 0.5—12 米保留 FB 0—20 与 STRI 0—5 米两种口径。
- 11 种最大体重缺少可靠数值而保留 null：加里波第鱼、黄高鳍刺尾鱼、管眼鱼、大西洋飞鱼、黑带鱼、主刺盖鱼、叶须鲉、蓝点鳐、红尾蝴蝶鱼、牛角箱鲀、拉氏皇带鱼。灰鲂鮄 956 克已正确换算成 0.956 千克；不从游戏尺寸模型反推任何真实最大值。
- 太平洋庸鲽 363 千克属于 FishBase 收录上限，该页面此字段未列具体参考号，未做原始个体纪录认证。皇带鱼 STRI 的 272 千克未能展开原始个体证据，本次采用更保守的 null。箱鲀的 `Max weight: 46 cm TL` 为标签与单位不匹配，不能改写为重量。
- WDFW 六线鱼页及 WoRMS 波纹唇鱼详情页在本次浏览工具中返回 403；已利用其公开机构搜索索引核对，未宣称详情全文成功下载。WoRMS 接受名另与 FishBase 对照，2025 分类论文全文可读。六线鱼第二源的复核范围较受限，后续人工完整访问可进一步确认来源。
- 拉氏皇带鱼研究全文通过作者 ResearchGate 镜像核读，原刊为 Acta Ichthyologica et Piscatoria，DOI `10.3897/aiep.55.148496`。红尾蝴蝶鱼第二源由 Sher-e-Bangla Agricultural University 的 ABR Lab 维护，页面列出孟加拉国调查与国家图鉴参考，不是销售站点。
- 7 种完成后必须放归。加州羊头鱼、加里波第鱼、大海鲢、波纹唇鱼的条目分别明确来源的风险或地区保护；管眼鱼、蓝点鳐、皇带鱼的放归另属本作自愿保护设计，未将无危状态误写为全球濒危或普遍禁捕。
- `min_mm`、`normal_max_mm`、`max_mm`、`anchor_mm`、`anchor_g`、饵料与权重仅用于游戏；形态资料帮助模型与插画辨认，不保证每个年龄阶段都使用同一色型。24 种新增分配在三海之间无重复，真实自然分布仍可跨海域。既有物种 ID 和纪录不因新增文件被删除。
