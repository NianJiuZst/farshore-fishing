# 密西西比流域扩展：来源、物种范围与美术核查

核查日期：2026-10-02。新增6个唯一物种，保留既有32种。稳定ID不因学名修订改变。

## 分区与使用边界

`bayou` 的中文显示为“密西西比流域”，是跨纬度的旅行目的地概括，不是声称六种鱼和白斑狗鱼在同一现实沼泽共存。

- `bayou_backwater`：下密西西比/路易斯安那的温暖、多水草河汊和牛轭湖，游戏深度1–8米。鳄雀鳝仅在此点。
- `bayou_channel`：上密西西比的河湾、连通回水及邻近河槽，游戏深度2–20米。水草边缘供黑鲈、长吻雀鳝和弓鳍鱼活动，较深倒木潭供鲶鱼活动。不是把整条河定义为冷水急流。
- 深度字段是选定钓点内的游戏遭遇区间，不是物种全球生态极限。钓点、装备和抛竿过滤仍须由集成测试验证。
- 体长为近似全长。min/max是合理的游戏钓获范围，非世界纪录；鳄雀鳝上限2400毫米小于FWC记述的约2.44米大型个体尺度。1400毫米/22000克只是立方体重模型的游戏锚点，并未声称来自科研回归。
- 鱼饵、天气、时段、出现权重、挣扎、稀有度、装备门槛等均明确为游戏调校。不要把这些倍率当作自然定律或现实垂钓建议。现实分布、保育状况和捕鱼法规并不由游戏奖励规则决定。
- 网页仅用于事实核查，没有下载、复制或内嵌其照片。全部鱼图为逐种独立AI生成的原创近真实手绘插画；来源公开可见不代表其图片可再分发。

## 重要分类修正

### 弓鳍鱼
2022年Brownstein等的原始研究区分了 `Amia calva` 与 `Amia ocellicauda`；后者覆盖密西西比流域，前者位于更东侧的东南沿海水系。Missouri Department of Conservation 当前物种页也使用 `Amia ocellicauda`。本游戏因此保留稳定ID `bowfin` 和中文泛称“弓鳍鱼”，学名使用适合本流域的 `Amia ocellicauda`，不机械套用旧版地方资料中的广义 `A. calva`。绘画表现雄鱼尾基眼斑，但插画不代替骨骼、牙齿或遗传检索。

### 大口黑鲈
2022年Kim等的原始研究把大口黑鲈名称厘清为 `Micropterus nigricans`，佛罗里达黑鲈为 `M. salmoides`。Maryland DNR资料确认AFS 2023已采用。部分州生境页仍使用旧学名；此处只借其形态、当地生境和本地北方支系资料，不把佛罗里达引入种和杂交个体混入这一独立物种条目。

## 逐种事实与数值边界

### 鳄雀鳝 · Atractosteus spatula

- 稳定ID：`alligator_gar`；钓点：`bayou_backwater`
- 生境解释：仅下密西西比/路易斯安那温暖、植被丰富的河汊；不放入上密西西比冷水钓点。
- 形态重点：短而宽的鳄状吻，粗壮圆筒身体和菱形硬鳞；背鳍、臀鳍后移，圆尾及鳍上有深色斑点。
- 游戏长度：650–2400毫米；游戏体重锚点：1400毫米/22000克；装备门槛2，抛竿0.55–1，深度1–8米
- [USFWS: Alligator Gar](https://www.fws.gov/species/alligator-gar-atractosteus-spatula)：学名、密西西比流域南部范围、菱形硬鳞和大型体形
- [MDWFP: Alligator Gar](https://www.mdwfp.com/fishing-boating/fish-id-guide/alligator-gar)：南密西西比、河汊与牛轭湖、宽吻和鳍部斑点；有真实大型个体记录
- [FWC: Alligator Gar](https://myfwc.com/wildlifehabitats/profiles/freshwater/alligator-gar/)：约2.44米大型尺寸背景及后移鱼鳍；不是体重科研回归来源

### 长吻雀鳝 · Lepisosteus osseus

- 稳定ID：`longnose_gar`；钓点：`bayou_backwater / bayou_channel`
- 生境解释：上下游均有分布；上游钓点取河湾缓流边缘，而非急流主槽。
- 形态重点：吻极细长，长度超过其余头部；细长橄榄褐色身体，体侧和后方鱼鳍散布黑斑，圆尾，背鳍明显后移。
- 游戏长度：450–1500毫米；游戏体重锚点：900毫米/3500克；装备门槛1，抛竿0.25–1，深度1–10米
- [NPS: Long-nosed Gar](https://www.nps.gov/miss/learn/nature/long-nosed-gar-lepisosteus-osseus.htm)：上密西西比泛洪湖与大河回水栖境、细长吻和分布
- [SCDNR: Longnose Gar](https://dnr.sc.gov/fish/species/longnosegar.html)：吻长超过其余头部两倍、体色黑斑、缓流水域与鱼食
- [Florida Museum: Longnose Gar](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/longnose-gar/)：北美分布、菱形硬鳞、体长可超过游戏上限

### 弓鳍鱼 · Amia ocellicauda

- 稳定ID：`bowfin`；钓点：`bayou_backwater / bayou_channel`
- 生境解释：回水和牛轭湖优先；上游河湾仅取植被缓水边缘，不表示偏好急流主槽。
- 形态重点：橄榄色细长身体带深色斑驳，长软条背鳍与短臀鳍形成对比；圆尾，雄鱼尾基有浅色环绕的黑色眼斑。
- 游戏长度：280–850毫米；游戏体重锚点：500毫米/1500克；装备门槛1，抛竿0.1–1，深度1–8米
- [Missouri Department of Conservation: Emerald Bowfin](https://mdc.mo.gov/discover-nature/field-guide/emerald-bowfin)：当前学名 Amia ocellicauda；密西西比低地、回水/牛轭湖生境、形态
- [Brownstein et al. 2022: Hidden species diversity in an iconic living fossil vertebrate](https://pmc.ncbi.nlm.nih.gov/articles/PMC9709656/)：2022物种界定；Amia ocellicauda 覆盖密西西比流域，Amia calva 为更东侧沿海支系

### 大口黑鲈 · Micropterus nigricans

- 稳定ID：`largemouth_bass`；钓点：`bayou_backwater / bayou_channel`
- 生境解释：取上下游河湾的植被和倒木缓水，不把上游钓点解释成纯冷水急流。
- 形态重点：绿色体侧有断续黑色横带，上颌后缘超过眼睛；背鳍硬棘部与软条部之间凹缺明显，尾鳍较宽。
- 游戏长度：180–650毫米；游戏体重锚点：400毫米/1200克；装备门槛1，抛竿0.05–1，深度1–10米
- [MDWFP: Largemouth Bass](https://www.mdwfp.com/fishing-boating/fish-id-guide/largemouth-bass)：密西西比本地大口黑鲈形态、缓流与掩体生境；该页沿用旧学名
- [Minnesota DNR: Largemouth Bass profile](https://www.dnr.state.mn.us/minnaqua/speciesprofile/largemouthbass.html)：上游水草丰富的河流回水和湖湾；该页沿用旧学名
- [Kim et al. 2022: Phylogenomics and species delimitation of Black Basses](https://pmc.ncbi.nlm.nih.gov/articles/PMC9170712/)：当前种界与命名：大口黑鲈 Micropterus nigricans，佛罗里达黑鲈 M. salmoides
- [Maryland DNR: Largemouth Bass Scientific Renaming](https://dnr.maryland.gov/fisheries/Documents/Reg_Changes/LargemouthBass_ScientificRenaming.pdf)：核实AFS 2023对大口黑鲈学名变更的采用

### 斑点叉尾鮰 · Ictalurus punctatus

- 稳定ID：`channel_catfish`；钓点：`bayou_backwater / bayou_channel`
- 生境解释：上下密西西比河流、回水和河湾可达；深度为钓点子区间。
- 形态重点：无鳞的灰橄榄色身体，浅腹与分散黑斑；口边有须，尾鳍深叉，臀鳍后缘圆弧，背后有小脂鳍。
- 游戏长度：250–1000毫米；游戏体重锚点：550毫米/2000克；装备门槛1，抛竿0.1–1，深度1–18米
- [MDWFP Fish ID Guide: Channel Catfish, p.21](https://www.mdwfp.com/sites/default/files/2024-12/Fish%20ID%20Guide_0.pdf)：物种身份、河流牛轭湖生境、黑斑、深叉尾和圆臀鳍；成年大鱼斑点可消退
- [NPS: Channel and Flathead Catfish, Mississippi National River](https://www.nps.gov/miss/learn/nature/channel-catfish-ictalurus-punctatus-and-flathead-catfish-pylodictis-olivaris.htm)：上密西西比存在、栖境和两种鲶鱼的区别

### 扁头鲶 · Pylodictis olivaris

- 稳定ID：`flathead_catfish`；钓点：`bayou_backwater / bayou_channel`
- 生境解释：上游河湾深槽及下游河汊较深的倒木坑；浅于3米部分不作为遭遇区。
- 形态重点：宽扁头、突出的下颌和小眼；黄褐色无鳞身体带不规则斑驳，长口须，小脂鳍；尾缘近方或微圆，不深叉。
- 游戏长度：350–1350毫米；游戏体重锚点：750毫米/8000克；装备门槛2，抛竿0.35–1，深度3–20米
- [MDWFP: Flathead Catfish](https://www.mdwfp.com/fishing-boating/fish-id-guide/flathead-catfish)：大型体形、宽扁头和突下颌；河流深潭、水下掩体及牛轭湖生境
- [NPS: Channel and Flathead Catfish, Mississippi National River](https://www.nps.gov/miss/learn/nature/channel-catfish-ictalurus-punctatus-and-flathead-catfish-pylodictis-olivaris.htm)：上密西西比存在、栖境和两种鲶鱼的区别

## 既有物种的跨区依据（由集成者修改既有数据）

- `common_carp`：鲤鱼在美国是历史引入种，不是原生北美鱼。[NPS Common Carp](https://home.nps.gov/miss/learn/nature/ascarp_common.htm) 说明19世纪引入与密西西比河早期记录，适合上游河湾/回水的软底环境；应在图鉴文案明确“引入”，可放 `bayou_channel`。不要覆盖原有欧洲湖泊范围。
- `northern_pike`：白斑狗鱼在上密西西比地区的河流和泛洪湖有记录。[NPS Northern Pike](https://home.nps.gov/miss/learn/nature/northern-pike.htm) 明确公园内的常见性、水草掩体与盛夏较冷、含氧深水利用。只增加 `bayou_channel`，不加入温暖路易斯安那河汊。2–20米是季节性河湾到较深水的游戏范围，并非声称其总偏好深槽。
- 上述两种加上本文件6种，地区可以达到8种，而每个单独钓点不必强行塞入全部8种。

## 素材审核与交付

逐张生成提示词、原始输出路径、源网页、license声明、完整文件SHA-256、透明通道统计和形态审核保存在 `docs/ASSETS_C.json`；原画位于 `art_masters/c/`。运行鱼图为宽1024像素，缩略图宽256像素，均按比例重采样并保留原生alpha。不得把缩略图、大小或花色变体计算为新物种。

场景按生态分区：`bayou.png` 为虚构下游柏树河汊，用于地区海报和 `bayou_backwater`；新增 `bayou_channel.png` 专供上密西西比河湾，表现温带落叶泛洪林、柳/杨/银槭、较高处的橡树与低矮林地石灰岩崖壁，不包含落羽杉、柏膝或西班牙苔。上游钓点还必须禁用下游专属的 `bayou_foreground.png`。两幅均为一般生态环境插画，不是具体地点摄影。

上游背景植被依据 [USGS 泛洪林研究](https://www.usgs.gov/centers/upper-midwest-environmental-sciences-center/science/forest-landscape-ecology-upper)，河谷崖壁和地理范围依据 [USFWS 上密西西比河保护区](https://www.fws.gov/refuge/upper-mississippi-river/about-us)。此分场景避免把白斑狗鱼的上游栖地画成路易斯安那柏树沼泽。

