# 湖泊与日本近海鱼种：百科核查台账

核查日期：2026-10-03。对应 `game/data/encyclopedia_a.json`，16个物种，schema_version 1。

## 资料口径

- 文字依据物种数据库、机构页面和研究论文重新撰写；没有复制长段原文或第三方照片。
- `typical_size` 区分 common length、地区常见值、成鱼样本与性成熟长度。缺可靠成年典型值时直说缺失，没有用游戏尺寸代替。
- TL为全长，FL为叉长，SL为标准长。未注明的量法不猜测、不换算。
- 最大长度与体重是独立的已发表报告或数据库汇录，不保证为同一个体，也不宣称是本次重新认证的当代世界纪录。野生、养殖或垂钓背景未知时不擅自补全。
- 红眼鱼与日本沙鮻的最大体重为 null，分别因为异常数据和缺少可用报告。缺失典型成年尺寸的物种在字段中单独说明。
- 主体分类使用当前接受科名；只在旧分类或来源体系真正有差异时保留必要注释。
- 不含游戏遭遇概率、钓点调校、体重模型、鱼饵权重或玩家统计；既有游戏数据未改。

## 逐种来源与字段覆盖

### common_carp · Cyprinus carpio

按现行物种概念描述，没有据旧中文泛称扩大东亚原生范围；北美引入史采用国家公园资料。

正文537字符（其中汉字464）；2条来源。

- s1 [Cyprinus carpio — species summary](https://www.fishbase.se/summary/Cyprinus-carpio.html) — FishBase。支持：分类、常见尺寸、最大长度、最大体重、生境、分布、行为、食性。核查：2026-10-03。
- s2 [Common Carp — Mississippi National River & Recreation Area](https://home.nps.gov/miss/learn/nature/ascarp_common.htm) — U.S. National Park Service。支持：常见尺寸、分布、故事。核查：2026-10-03。

### crucian_carp · Carassius carassius

乙醇代谢故事采用原始实验论文，不把这种能力外推给所有鲤科鱼。

正文548字符（其中汉字451）；2条来源。

- s1 [Carassius carassius — species summary](https://www.fishbase.se/summary/270) — FishBase。支持：分类、常见尺寸、最大长度、最大体重、生境、分布、行为、食性。核查：2026-10-03。
- s2 [Extreme anoxia tolerance in crucian carp and goldfish through neofunctionalization of duplicated genes](https://www.nature.com/articles/s41598-017-07385-4) — Scientific Reports / Fagernes et al. (2017)。支持：故事。核查：2026-10-03。

### roach · Rutilus rutilus

现归雅罗鱼科；越冬迁移及捕食研究有具体地点和样本范围，不解释为所有个体必然迁移。

正文531字符（其中汉字459）；2条来源。

- s1 [Rutilus rutilus — species summary](https://www.fishbase.se/Summary/Rutilus-rutilus) — FishBase。支持：分类、常见尺寸、最大长度、最大体重、生境、分布、行为、食性。核查：2026-10-03。
- s2 [Migration confers survival benefits against avian predators for partially migratory freshwater fish](https://portal.research.lu.se/en/publications/migration-confers-survival-benefits-against-avian-predators-for-p/) — Lund University / Skov et al., Biology Letters (2013)。支持：行为、故事。核查：2026-10-03。

### rudd · Scardinius erythrophthalmus

剔除异常零克字段；另查新西兰保育部，其地方体型描述也不足以支持全球重量极值。最大长度有USGS交叉来源。

正文558字符（其中汉字455）；3条来源。

- s1 [Scardinius erythrophthalmus — species summary](https://www.fishbase.se/summary/2951) — FishBase。支持：分类、常见尺寸、最大长度、最大体重、生境、分布。核查：2026-10-03。
- s2 [Scardinius erythrophthalmus — Great Lakes Species Profile](https://nas.er.usgs.gov/queries/GreatLakes/FactSheet.aspx?Species_ID=648) — U.S. Geological Survey / NOAA GLANSIS。支持：最大长度、最大体重、生境、行为、食性、故事。核查：2026-10-03。
- s3 [Rudd facts](https://www.doc.govt.nz/nature/pests-and-threats/freshwater-pests/rudd/) — New Zealand Department of Conservation。支持：常见尺寸、最大体重。核查：2026-10-03。

### european_perch · Perca fluviatilis

标准长与全长各按原量法保留。澳大利亚博物馆质疑的夸大重量未采纳，其常见尺寸说明了地区。

正文575字符（其中汉字459）；2条来源。

- s1 [Perca fluviatilis — species summary](https://www.fishbase.se/summary/358) — FishBase。支持：分类、常见尺寸、最大长度、最大体重、生境、分布、行为、食性。核查：2026-10-03。
- s2 [Redfin, Perca fluviatilis](https://australian.museum/learn/animals/fishes/redfin-perca-fluviatilis/) — Australian Museum / Mark McGrouther。支持：常见尺寸、最大体重、分布、食性、故事。核查：2026-10-03。

### northern_pike · Esox lucius

最大雌鱼全长和另一条叉长数据并存，不混算；北美季节移动实例标明观察背景。

正文544字符（其中汉字452）；2条来源。

- s1 [Esox lucius — species summary](https://www.fishbase.se/summary/258) — FishBase。支持：分类、常见尺寸、最大长度、最大体重、生境、分布、行为、食性。核查：2026-10-03。
- s2 [Northern Pike — Mississippi National River & Recreation Area](https://home.nps.gov/miss/learn/nature/northern-pike.htm) — U.S. National Park Service。支持：常见尺寸、生境、行为、食性、故事。核查：2026-10-03。

### common_bream · Abramis brama

采用雅罗鱼科；食物与湖河连通的生活史分别有明确证据。

正文539字符（其中汉字452）；2条来源。

- s1 [Abramis brama — species summary](https://www.fishbase.se/summary/Abramis-brama) — FishBase。支持：分类、常见尺寸、最大长度、最大体重、生境、分布、行为、食性。核查：2026-10-03。
- s2 [Birdpredation, fish behavior and fish movements between lakes](https://orbit.dtu.dk/en/projects/birdpredation-fish-behavior-and-fish-movements-between-lakes-3826/) — Technical University of Denmark / DTU Aqua。支持：故事。核查：2026-10-03。

### tench · Tinca tinca

采用丁鱥科；尺寸栏与正文的极值量法不同。USFWS存档PDF交叉复核USGS的引入史。

正文559字符（其中汉字453）；3条来源。

- s1 [Tinca tinca — species summary](https://www.fishbase.se/summary/tinca-tinca.html) — FishBase。支持：分类、常见尺寸、最大长度、最大体重、生境、分布、行为、食性。核查：2026-10-03。
- s2 [Tench (Tinca tinca) — Species Profile](https://nas.er.usgs.gov/queries/factsheet.aspx?speciesid=652) — U.S. Geological Survey, Nonindigenous Aquatic Species Database。支持：常见尺寸、分布、故事。核查：2026-10-03。
- s3 [Ecological Risk Screening Summary — Tench (Tinca tinca)](https://www.fws.gov/sites/default/files/documents/Ecological-Risk-Screening-Summary-Tench.pdf) — U.S. Fish and Wildlife Service。支持：故事。核查：2026-10-03。

### japanese_horse_mackerel · Trachurus japonicus

纳入2026年东京湾原始追踪研究；新深度观测不能理解成全体鱼的日常生活深度。没有更改游戏可达范围。

正文575字符（其中汉字456）；3条来源。

- s1 [Trachurus japonicus — species summary](https://www.fishbase.se/summary/Trachurus-japonicus.html) — FishBase。支持：分类、常见尺寸、最大长度、最大体重、生境。核查：2026-10-03。
- s2 [日本竹筴魚 Trachurus japonicus](https://fishdb.sinica.edu.tw/taxon/381555-fishdb) — 中央研究院臺灣魚類資料庫。支持：分类、常见尺寸、最大长度、分布、行为、食性。核查：2026-10-03。
- s3 [Vertical Habitat Use by Japanese Jack Mackerel Trachurus japonicus Inferred From a Biologging Study in Tokyo Bay](https://onlinelibrary.wiley.com/doi/full/10.1111/fog.70035) — Fisheries Oceanography / Kinoshita et al. (2026)。支持：生境、行为、故事。核查：2026-10-03。

### chub_mackerel · Scomber japonicus

旧大西洋记录涉及另一现行物种；北美迁移实例不可当作日本渔场的固定时序。

正文556字符（其中汉字450）；2条来源。

- s1 [Scomber japonicus — species summary](https://www.fishbase.se/summary/Scomber_japonicus.html) — FishBase。支持：分类、常见尺寸、最大长度、最大体重、生境、分布、行为、食性。核查：2026-10-03。
- s2 [Pacific Mackerel](https://www.fisheries.noaa.gov/species/pacific-mackerel) — NOAA Fisheries。支持：最大长度、生境、食性、故事。核查：2026-10-03。

### red_seabream · Pagrus major

最大长度采用有量法标注的来源；另一资料的常见尺寸缺量法，保持未指定。文化与引入史来自CIESM。

正文553字符（其中汉字450）；3条来源。

- s1 [Pagrus major — species summary](https://www.fishbase.se/summary/Pagrus-major.html) — FishBase。支持：分类、常见尺寸、最大长度、最大体重、生境、分布、行为、食性。核查：2026-10-03。
- s2 [真鯛 Pagrus major](https://fishdb.sinica.edu.tw/taxon/382642-fishdb) — 中央研究院臺灣魚類資料庫。支持：分类、生境、分布、行为。核查：2026-10-03。
- s3 [Pagrus major — Atlas of Exotic Fishes in the Mediterranean](https://ciesm.org/atlas_preview/Pagrusmajor.php) — CIESM, Mediterranean Science Commission。支持：常见尺寸、分布、行为、食性、故事。核查：2026-10-03。

### black_seabream · Acanthopagrus schlegelii

由Eschmeyer物种记录核对接受名。性转换故事交代养殖研究背景，不写成每尾鱼同龄转性。活动行为仅采用公开摘要支持的结论。

正文597字符（其中汉字450）；4条来源。

- s1 [Acanthopagrus schlegelii — species summary](https://www.fishbase.se/summary/Acanthopagrus-schlegelii.html) — FishBase。支持：分类、常见尺寸、最大长度、最大体重、生境、食性。核查：2026-10-03。
- s2 [Eschmeyer’s Catalog of Fishes — Acanthopagrus schlegelii](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=15707) — California Academy of Sciences。支持：分类、分布。核查：2026-10-03。
- s3 [Horizontal movements and home range of black sea bream in the natural coast of Hiroshima Bay](https://link.springer.com/article/10.1007/s12562-024-01748-3) — Fisheries Science / Tsuyuki & Umino (2024)。支持：常见尺寸、生境、行为。核查：2026-10-03。
- s4 [Development of the Genital Duct System in the Protandrous Black Porgy](https://anatomypubs.onlinelibrary.wiley.com/doi/10.1002/ar.21339) — The Anatomical Record / Lee, Huang & Chang (2011)。支持：故事。核查：2026-10-03。

### japanese_seabass · Lateolabrax japonicus

数据库common length不能自动视为成年典型。近缘种拆分影响旧分布，正文重点采用日本明确研究。没有照抄未经交叉核查的性转换叙述。

正文566字符（其中汉字452）；3条来源。

- s1 [Lateolabrax japonicus — species summary](https://www.fishbase.se/summary/Lateolabrax_japonicus.html) — FishBase。支持：分类、常见尺寸、最大长度、最大体重、生境、分布、食性。核查：2026-10-03。
- s2 [Lateolabrax japonicus — BISMaL](https://www.godac.jamstec.go.jp/bismal/e/view/9005278) — Japan Agency for Marine-Earth Science and Technology (JAMSTEC)。支持：分类、分布。核查：2026-10-03。
- s3 [Partial migration of juvenile temperate seabass: a versatile survival strategy](https://eprints.lib.hokudai.ac.jp/repo/huscap/all/72719/) — Fisheries Science / Kasai et al. (2018), Hokkaido University repository。支持：生境、分布、行为、食性、故事。核查：2026-10-03。

### japanese_whiting · Sillago japonica

数值栏与正文关于最大长度的表述不完全一致，已在文字说明；体重保留缺值。繁殖故事限定于馆山湾研究。

正文565字符（其中汉字456）；3条来源。

- s1 [Sillago japonica — species summary](https://www.fishbase.se/summary/Sillago-japonica.html) — FishBase。支持：分类、常见尺寸、最大长度、最大体重、行为。核查：2026-10-03。
- s2 [日本沙鮻 Sillago japonica](https://fishdb.sinica.edu.tw/taxon/382628-fishdb) — 中央研究院臺灣魚類資料庫。支持：分类、最大体重、生境、分布、行为、食性。核查：2026-10-03。
- s3 [Reproduction of the Japanese Whiting, Sillago japonica, in Tateyama Bay](https://www.jstage.jst.go.jp/article/aquaculturesci1953/47/2/47_2_209/_pdf) — Aquaculture Science / Sulistiono, Watanabe & Yokota (1999)。支持：行为、故事。核查：2026-10-03。

### marbled_rockfish · Sebastiscus marmoratus

科采用Eschmeyer的Scorpaenidae，明确记录与FishBase的科级差异；两个极值原始引文不同，不能配成同一尾鱼。

正文558字符（其中汉字452）；4条来源。

- s1 [Sebastiscus marmoratus — species summary](https://www.fishbase.se/summary/Sebastiscus-marmoratus.html) — FishBase。支持：分类、常见尺寸、最大长度、最大体重、行为。核查：2026-10-03。
- s2 [石狗公 Sebastiscus marmoratus](https://fishdb.sinica.edu.tw/taxon/382891-fishdb) — 中央研究院臺灣魚類資料庫。支持：分类、常见尺寸、最大长度、生境、分布、行为、食性、故事。核查：2026-10-03。
- s3 [Eschmeyer’s Catalog of Fishes — Sebastiscus marmoratus](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=42370) — California Academy of Sciences。支持：分类、分布。核查：2026-10-03。
- s4 [The Testicular Cycle Development of Ovoviviparous Teleost, Sebastiscus marmoratus](https://www.zoores.ac.cn/article/id/675) — Zoological Research / Lin, You & Chen (2000)。支持：故事。核查：2026-10-03。

### olive_flounder · Paralichthys olivaceus

最大值没有当作成年典型；变态发育采用日本水产学会原始论文。原有NOAA文件链接目前重定向到主页，本次没有引用它。

正文575字符（其中汉字486）；3条来源。

- s1 [Paralichthys olivaceus — species summary](https://www.fishbase.se/summary/Paralichthys-olivaceus.html) — FishBase。支持：分类、常见尺寸、最大长度、最大体重、生境、分布。核查：2026-10-03。
- s2 [牙鮃 Paralichthys olivaceus](https://fishdb.sinica.edu.tw/taxon/382745-fishdb) — 中央研究院臺灣魚類資料庫。支持：分类、常见尺寸、最大长度、生境、分布、行为、食性、故事。核查：2026-10-03。
- s3 [Sensitivity of metamorphic events and morphogenesis of Japanese flounder during larval development to thyroxine](https://www.jstage.jst.go.jp/article/fishsci1994/66/5/66_5_846/_article) — Fisheries Science / Yoo, Takeuchi & Seikai (2000)。支持：生境、行为、故事。核查：2026-10-03。

## 校验结果

已解析JSON并交叉检查：16/16覆盖fish_a；species_id唯一；字段齐全；每段source_ids均指向本物种sources；每种2—4来源；数值为正数或明确null；量长类型在约定枚举内；无游戏数值和玩家统计字段；每条正文450—486汉字、531—597总字符（不含来源及故事标题）。

部分旧站点有重定向、脚本页面或偶发读取错误。核查使用同机构新物种页、出版商可读正文/摘要和机构存档；没有取得付费全文的论文，只使用公开摘要能支持的结论。
