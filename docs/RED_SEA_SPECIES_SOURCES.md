# 红海新增物种：自然史与玩法核查

核查日期：2026-10-04。范围固定为 `fish_h.json` 的12个新增 ID，未删改历史物种、档案或个人纪录。资料条目在 `encyclopedia_h.json`，每个自然史字段都有可追溯的 `source_ids`。

红海航区是跨地点、生境及生命阶段的**游戏区域合辑**。本次只有接受学名为 *Thalassoma rueppellii* 的克氏锦鱼被所用地区志明确记为红海特有；不能把全部12种叫作现实中的“红海独有鱼”。游戏专属相遇路线也不否认物种在其他地方的真实分布。

## 资料方法与边界

逐种读取 FishBase 物种摘要，并交叉核对 NRF–SAIAB 于2022年出版的 *Coastal Fishes of the Western Indian Ocean* 第2、3、4、5卷。书籍来自[出版机构官方页面](https://saiab.ac.za/publications/coastal-fishes-of-the-western-indian/)，通过其公开 PDF 逐页核实，未用游客图片说明代替资料。每种至少包含这两套资料；特定食性和地中海移入故事另有 FishBase 食物／生态表或 CIESM 图鉴。

FishBase 的摘要、生态页和食物表是同一数据库的不同证据页，**不计成几个独立机构**；独立交叉来源是 SAIAB 地区志，部分物种另有 CIESM。网页显示的模型估算、AquaMaps 未审核地图、近亲营养级不当成物种实测纪录。最大长度为资料汇录尺度，并非已核验到2026年的即时世界纪录。

TL 为全长，SL 为标准长，两者不直接换算。所有未知或未取得可靠体重上限的 `max_weight.value_kg` 留 `null`，没有以游戏的长度—体重锚点补成“科学最大体重”。所有抽样长度、极低概率巨物、体重锚点、难度、遭遇权重、饵料、时段、天气与挣扎节奏都标明是游戏设计。

## 相遇设计

| ID／名称 | 外形与生活方式重点 | 钓点、游戏水层 | 竿门槛／节奏 | 普通尺寸；虚构上端 |
| --- | --- | --- | --- | --- |
| `red_sea_clownfish` 双带小丑鱼 | 两条白带、橙黄短高身；海葵旁守卵 | 潟湖 1–18米 | 0／停顿型0.24；虾饵、短抛 | 4.5–12；15厘米 |
| `red_sea_bannerfish` 红海马夫鱼 | 黑斜带、长白背丝；成年成对；幼鱼群聚资料不同 | 潟湖／礁墙 3–45米 | 0／平稳型0.32；虾或虫、中短抛 | 6.5–16；19.5厘米 |
| `masked_butterflyfish` 金蝴蝶鱼 | 蓝灰面罩、金黄圆盘；珊瑚屋檐下悬停 | 潟湖 3–20米 | 0／停顿型0.28；虾或虫、短抛 | 7–20.5；25厘米 |
| `sohal_surgeonfish` 索氏刺尾鱼 | 细黑横纹、橙色尾柄棘；藻食领地鱼 | 潟湖／礁墙 1–20米 | 0／冲刺型0.49；面团为游戏藻食映射 | 10–34；45厘米 |
| `arabian_picassotriggerfish` 阿拉伯炮弹鱼 | 蓝黑几何脸、白腹；近底无脊椎动物食者 | 潟湖 1–18米 | 0／停顿型0.39；虾饵、短抛 | 8.5–26；34厘米 |
| `klunzingers_wrasse` 克氏锦鱼 | 绿蓝身与粉红头纹；性相变化、好奇底质扰动 | 潟湖／礁墙 1–25米 | 0／冲刺型0.35；虫或虾、短抛 | 6.5–17.5；22.5厘米 |
| `red_sea_goatfish` 福氏副绯鲤 | 下颏双须、黑侧带和黄色尾柄黑斑；探底 | 潟湖／礁墙 1–35米 | 0／停顿型0.30；虫或虾、中短抛 | 10–24.5；30.5厘米 |
| `crocodile_flathead` 长头鳄形鲬 | 扁宽头、顶部眼、斑驳底色；埋沙伏击 | 潟湖 1–15米 | 0／停顿型0.45；虾或拟饵、短抛 | 22–62；76厘米 |
| `bluespotted_cornetfish` 鳞烟管鱼 | 极长管吻、靠后软鳍、白尾丝；捕食小鱼 | 礁墙／蓝洞 15–120米 | 1／冲刺型0.56；拟饵、较远抛 | 45–130；176厘米 |
| `yellowbar_angelfish` 黄带刺盖鱼 | 蓝身黄斑；幼鱼另有弯白纹、海绵食者 | 潟湖／礁墙 4–60米 | 0／平稳型0.46；虾或面团、分段收线 | 10–40；56厘米 |
| `blackspotted_sweetlips` 黑斑胡椒鲷 | 黄色厚唇和黑圆点；幼年条纹随生长变斑 | 礁墙／蓝洞 12–80米 | 1／停顿型0.53；虾饵、礁缘落点 | 15–43；58厘米 |
| `orbicular_batfish` 圆眼燕鱼 | 成年银灰圆盘；幼鱼褐色落叶拟态 | 潟湖／礁墙／蓝洞 3–60米 | 0／平稳型0.50；虾饵、分段收线 | 12–52；68厘米 |

计数：潟湖10种、礁墙8种、蓝洞3种。10种 `min_gear=0`，2种为1，没有把全部礁鱼放在高阶竿后面。蓝洞三个新增物种分别具有30–120、30–80、30–60米相遇窗口，旅行竿60米探深也可覆盖各自浅段；浅竿不能因装备编号较高而穿透实际探深限制。旧引擎的 `steady`、`burst`、`rest` 三种行为枚举被保留，数据没有假称实现新的独立 AI 状态。

## 需要保留的资料差异

- **克氏锦鱼命名**：FishBase 当前摘要及 SAIAB 使用 *Thalassoma rueppellii*；*T. klunzingeri* 是历史同物异名。新文件采用接受学名，保留 `klunzingers_wrasse` ID。FishBase列20厘米TL，地区志列17厘米TL，二者并列说明。
- **双带小丑鱼分布**：FishBase摘要简写红海—查戈斯；SAIAB另列亚丁湾、塞舌尔等。写明地区志更广范围，不声称红海独有。食性通过 `FoodItemsList.php` 的底藻及浮游动物记录核实，未凭小丑鱼通用印象填入。
- **红海马夫鱼长度**：FishBase和SAIAB为18厘米TL；CIESM常见10–18厘米、最大20厘米未标量法。数值字段保留18厘米TL，说明20厘米的量法限制。FishBase记幼鱼结群、SAIAB记幼鱼独游，图鉴并列保留观察差异。
- **索氏刺尾鱼水深**：FishBase所列0–20米是“通常”，总体范围上端不明；图鉴不将20米当绝对上限。
- **阿拉伯炮弹鱼水深**：已核实物种条目只明确浅水沙／碎珊瑚生境，无足够可靠的统一数值深度。游戏1–18米明确标为设计值。
- **福氏副绯鲤长度与体重**：FishBase最大28厘米TL、常见25厘米TL，地区志22厘米SL；不直接换算。数据库虽有275.30克汇录，此轮未追溯原始样本与极值适用范围，体重上限暂为 `null`。
- **长头鳄形鲬水深与伏击**：FishBase1–15米、SAIAB约到15米，CIESM另列20米；使用1–15米浅潟湖游戏窗口。CIESM同一页也有 *Sorsogona prionota*，只引用本种第一段，不移植第二种的幼鱼水深与夜间浅移记录。
- **鳞烟管鱼量法**：FishBase160厘米TL、地区志150厘米SL；尾丝和管吻令轮廓很长，但不把游戏视觉长度换算成任何一项科学量法。它广布印度—太平洋及东太平洋，亦有地中海移入记录。
- **黄带刺盖鱼量法**：FishBase50厘米标SL，SAIAB50厘米标TL。数值字段保留50厘米SL并指出差异；常见20厘米TL单列。食性另核生态表（海绵、藻类及海鞘，幼鱼小型甲壳类），不从游戏饵反推。
- **黑斑胡椒鲷水深**：SAIAB记珊瑚礁到30米，FishBase摘要55–80米、生态表又明确浅水沿岸／海草床。图鉴保留矛盾口径，游戏12–80米只表达选定相遇窗口；塞舌尔分布有争议，不当成确认记录。
- **圆眼燕鱼生命阶段和水深**：FishBase摘要0–30米，SAIAB成年10–60米、幼鱼红树林浅水。蓝洞30–60米窗口采用成年资料，不能画成褐色长鳍幼鱼无限放大。FishBase60厘米TL与地区志50厘米TL并列。

## 逐种来源

以下链接与 JSON 中的 `s1`、`s2`、`s3` 一致。PDF 链接的 `#page=` 是文件页号，标题内页码是书中印刷页码。

### 双带小丑鱼 — *Amphiprion bicinctus*

- `s1` [Amphiprion bicinctus species summary](https://www.fishbase.se/summary/Amphiprion-bicinctus.html) — FishBase Consortium；字段：taxonomy、typical_size、max_length、max_weight、habitat、distribution、behavior、story。
- `s2` [Coastal Fishes of the Western Indian Ocean (2022), vol. 4, Amphiprion bicinctus, pp. 127](https://saiab.ac.za/wp-content/uploads/2022/11/1._wiof_volume_4_text.pdf#page=131) — NRF–South African Institute for Aquatic Biodiversity (SAIAB)；字段：taxonomy、typical_size、max_length、max_weight、habitat、distribution、behavior、story。
- `s3` [Food items reported for Amphiprion bicinctus](https://www.fishbase.se/TrophicEco/FoodItemsList.php?genus=Amphiprion&species=bicinctus&vstockcode=12163) — FishBase Consortium；字段：diet。

### 红海马夫鱼 — *Heniochus intermedius*

- `s1` [Heniochus intermedius species summary](https://www.fishbase.se/summary/Heniochus-intermedius.html) — FishBase Consortium；字段：taxonomy、max_length、max_weight、habitat、distribution、behavior、diet。
- `s2` [Coastal Fishes of the Western Indian Ocean (2022), vol. 3, Heniochus intermedius, pp. 466–467](https://saiab.ac.za/wp-content/uploads/2022/11/1._wiof_volume_3_text.pdf#page=470) — NRF–South African Institute for Aquatic Biodiversity (SAIAB)；字段：taxonomy、max_length、max_weight、habitat、distribution、behavior、diet、story。
- `s3` [Heniochus intermedius, Atlas of Exotic Fishes in the Mediterranean Sea (2021), pp. 182–183](https://ciesm.org/atlas/fishes_2nd_edition/Heniochus_intermedius.pdf) — CIESM Publishers；字段：typical_size、max_length、distribution、story。

### 金蝴蝶鱼 — *Chaetodon semilarvatus*

- `s1` [Chaetodon semilarvatus species summary](https://www.fishbase.se/summary/Chaetodon-semilarvatus.html) — FishBase Consortium；字段：taxonomy、typical_size、max_length、max_weight、habitat、distribution、behavior、story。
- `s2` [Coastal Fishes of the Western Indian Ocean (2022), vol. 3, Chaetodon semilarvatus, pp. 461](https://saiab.ac.za/wp-content/uploads/2022/11/1._wiof_volume_3_text.pdf#page=465) — NRF–South African Institute for Aquatic Biodiversity (SAIAB)；字段：taxonomy、max_length、max_weight、habitat、distribution、behavior、diet、story。

### 索氏刺尾鱼 — *Acanthurus sohal*

- `s1` [Acanthurus sohal species summary](https://www.fishbase.se/summary/Acanthurus-sohal.html) — FishBase Consortium；字段：taxonomy、typical_size、max_length、max_weight、habitat、distribution、behavior、diet、story。
- `s2` [Coastal Fishes of the Western Indian Ocean (2022), vol. 5, Acanthurus sohal, pp. 228](https://saiab.ac.za/wp-content/uploads/2022/11/1._wiof_volume_5_text.pdf#page=232) — NRF–South African Institute for Aquatic Biodiversity (SAIAB)；字段：taxonomy、max_length、max_weight、habitat、distribution、behavior、story。

### 阿拉伯炮弹鱼 — *Rhinecanthus assasi*

- `s1` [Rhinecanthus assasi species summary](https://www.fishbase.se/summary/Rhinecanthus-assasi.html) — FishBase Consortium；字段：taxonomy、typical_size、max_length、max_weight、habitat、distribution、behavior、diet、story。
- `s2` [Coastal Fishes of the Western Indian Ocean (2022), vol. 5, Rhinecanthus assasi, pp. 423–424](https://saiab.ac.za/wp-content/uploads/2022/11/1._wiof_volume_5_text.pdf#page=427) — NRF–South African Institute for Aquatic Biodiversity (SAIAB)；字段：taxonomy、typical_size、max_length、max_weight、habitat、distribution、behavior、story。

### 克氏锦鱼 — *Thalassoma rueppellii*

- `s1` [Thalassoma rueppellii species summary (accepted name)](https://www.fishbase.se/summary/Thalassoma-rueppellii.html) — FishBase Consortium；字段：taxonomy、typical_size、max_length、max_weight、habitat、distribution、story。
- `s2` [Coastal Fishes of the Western Indian Ocean (2022), vol. 4, Thalassoma rueppellii, pp. 261–262](https://saiab.ac.za/wp-content/uploads/2022/11/1._wiof_volume_4_text.pdf#page=265) — NRF–South African Institute for Aquatic Biodiversity (SAIAB)；字段：taxonomy、typical_size、max_length、max_weight、habitat、distribution、behavior、diet、story。

### 福氏副绯鲤 — *Parupeneus forsskali*

- `s1` [Parupeneus forsskali species summary](https://www.fishbase.se/summary/Parupeneus-forsskali.html) — FishBase Consortium；字段：taxonomy、typical_size、max_length、max_weight、habitat、distribution、diet。
- `s2` [Coastal Fishes of the Western Indian Ocean (2022), vol. 3, Parupeneus forsskali, pp. 361; Mullidae overview p. 355](https://saiab.ac.za/wp-content/uploads/2022/11/1._wiof_volume_3_text.pdf#page=365) — NRF–South African Institute for Aquatic Biodiversity (SAIAB)；字段：taxonomy、max_length、habitat、distribution、behavior、diet、story。

### 长头鳄形鲬 — *Papilloculiceps longiceps*

- `s1` [Papilloculiceps longiceps species summary](https://www.fishbase.se/summary/Papilloculiceps-longiceps.html) — FishBase Consortium；字段：taxonomy、typical_size、max_length、max_weight、habitat、distribution。
- `s2` [Coastal Fishes of the Western Indian Ocean (2022), vol. 2, Papilloculiceps longiceps, pp. 588–589](https://saiab.ac.za/wp-content/uploads/2022/11/1._wiof_volume_2_text.pdf#page=594) — NRF–South African Institute for Aquatic Biodiversity (SAIAB)；字段：taxonomy、max_length、max_weight、habitat、distribution、behavior、story。
- `s3` [Papilloculiceps longiceps, Atlas of Exotic Fishes in the Mediterranean Sea (2021), p. 279](https://ciesm.org/atlas/fishes_2nd_edition/Papilloculiceps_longiceps.pdf) — CIESM Publishers；字段：habitat、distribution、behavior、diet、story。

### 鳞烟管鱼 — *Fistularia commersonii*

- `s1` [Fistularia commersonii species summary](https://www.fishbase.se/summary/Fistularia-commersonii.html) — FishBase Consortium；字段：taxonomy、typical_size、max_length、max_weight、habitat、distribution、behavior、diet、story。
- `s2` [Coastal Fishes of the Western Indian Ocean (2022), vol. 2, Fistularia commersonii, pp. 497](https://saiab.ac.za/wp-content/uploads/2022/11/1._wiof_volume_2_text.pdf#page=503) — NRF–South African Institute for Aquatic Biodiversity (SAIAB)；字段：taxonomy、max_length、max_weight、habitat、distribution、behavior、diet、story。

### 黄带刺盖鱼 — *Pomacanthus maculosus*

- `s1` [Pomacanthus maculosus species summary](https://www.fishbase.se/summary/Pomacanthus-maculosus.html) — FishBase Consortium；字段：taxonomy、typical_size、max_length、max_weight、habitat、distribution。
- `s2` [Coastal Fishes of the Western Indian Ocean (2022), vol. 3, Pomacanthus maculosus, pp. 440; Pomacanthus overview p. 438](https://saiab.ac.za/wp-content/uploads/2022/11/1._wiof_volume_3_text.pdf#page=444) — NRF–South African Institute for Aquatic Biodiversity (SAIAB)；字段：taxonomy、max_length、max_weight、habitat、distribution、behavior、story。
- `s3` [Ecology summary – Pomacanthus maculosus](https://www.fishbase.se/Ecology/FishEcologySummary.php?GenusName=Pomacanthus&SpeciesName=maculosus&StockCode=8214) — FishBase Consortium；字段：habitat、behavior、diet。

### 黑斑胡椒鲷 — *Plectorhinchus gaterinus*

- `s1` [Plectorhinchus gaterinus species summary](https://www.fishbase.se/summary/Plectorhinchus-gaterinus.html) — FishBase Consortium；字段：taxonomy、typical_size、max_length、max_weight、habitat、distribution、behavior。
- `s2` [Coastal Fishes of the Western Indian Ocean (2022), vol. 3, Plectorhinchus gaterinus, pp. 272–273](https://saiab.ac.za/wp-content/uploads/2022/11/1._wiof_volume_3_text.pdf#page=276) — NRF–South African Institute for Aquatic Biodiversity (SAIAB)；字段：taxonomy、max_length、max_weight、habitat、distribution、behavior、story。
- `s3` [Ecology summary – Plectorhinchus gaterinus](https://www.fishbase.se/Ecology/FishEcologySummary.php?GenusName=Plectorhinchus&SpeciesName=gaterinus&StockCode=8012) — FishBase Consortium；字段：habitat、diet。

### 圆眼燕鱼 — *Platax orbicularis*

- `s1` [Platax orbicularis species summary](https://www.fishbase.se/summary/Platax-orbicularis.html) — FishBase Consortium；字段：taxonomy、typical_size、max_length、max_weight、habitat、distribution、behavior、diet。
- `s2` [Coastal Fishes of the Western Indian Ocean (2022), vol. 5, Platax orbicularis, pp. 205–206](https://saiab.ac.za/wp-content/uploads/2022/11/1._wiof_volume_5_text.pdf#page=209) — NRF–South African Institute for Aquatic Biodiversity (SAIAB)；字段：taxonomy、typical_size、max_length、max_weight、habitat、distribution、behavior、diet、story。


## 本次验收范围

仅新增本页及两份数据文件。完整模型、动画、高清图、缩略图、目录载入和整体运行验证由集成任务验收；这里配置的是每个 ID 对应的新资源路径，不用旧图片冒充新增素材。源资料 PDF 为临时核查材料，未作为游戏打包资源添加。

- `content_natural_history_contract.validate_entry` 对12条逐一通过；108个自然史字段均有已定义引用。
- 12个 ID 与限定红海清单完全相同，与原有 `fish_a`—`fish_g` ID 无冲突；游戏学名和图鉴接受学名一致。
- JSON 严格解析无重复属性、无 NaN／Infinity；所有来源 HTTPS URL、日期、引用、分类属名、长度量法和空体重值通过现有契约。
- 21个物种／钓点映射全部与当前 world.json 真实水层重叠；逐竿校验实际探深、抛投范围和门槛，每个映射至少有一支可达竿。
- 礁湖10个物种均有入门竿可达窗口；蓝洞三个新物种都被25米纺车竿排除，60米旅行竿有浅肩窗口。
- 12种涵盖11个科；没有新增金枪鱼或鲨鱼。
- 两份数据 SHA-256：
  - `fish_h.json`：`dce42846f2e9060818b027906d54ddd5fb3c964a3c74fdfeb14ab6066cc1a27d`。
  - `encyclopedia_h.json`：`8cb4332bdb9bb60b90a1114a207112e9f076f5a11ce33de14629544f6f70fec5`。
