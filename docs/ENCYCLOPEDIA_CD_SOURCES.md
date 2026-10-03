# 密西西比与长江十二种鱼：图鉴事实审校

核查日期：2026-10-03。对应 `game/data/encyclopedia_c.json` 与 `game/data/encyclopedia_d.json`，每条的 `s1`、`s2` 等标识仅在该物种内有效。正文为依据来源重新组织的中文释义，没有复制来源照片、插图或整段文字；链接公开不等于图片获得再分发授权。

## 数据解释

- 每种均列科学种名、科、属、常见尺寸、最大长度、最大重量、生境、分布、行为、食性、独立自然史故事与字段级来源。
- TL为全长，SL为标准长，FL为叉长；资料没有明确量法时使用 `unspecified`，不自行补成全长。
- 成鱼专属统计、年龄/养殖规格、未限定年龄的“common/average”概述和极端值严格区分。没有可靠成年常见统计时明确说明，不从游戏最小/最大尺寸或体重锚点倒算。
- `max_length` 和 `max_weight` 保存具体采用来源的**报告上限或可核实大型实例**，并由文字明确数据库汇编、地区概述、钓获或标本等范围；它们不是统一标准下的全球纪录排行榜。多个来源相冲突时写清差异；两项数值通常来自独立记录，不能相乘、推算或拼成同一条鱼。
- 中文科属名作阅读辅助，科学名控制分类身份；新属没有可靠统一中文名时保留说明，不臆造定名。
- 没有把科学或科普资料中的真实捕捞、养殖操作转换为游戏现实捕鱼建议，也没有修改任何游戏数值。中华鲟继续只作虚拟保护观察并放生。

## C：密西西比流域

### 鳄雀鳝 `alligator_gar`

- [FishBase](https://www.fishbase.se/summary/Atractosteus-spatula.html)：Atractosteus spatula，Lepisosteidae；common length 200 cm TL，max length 260 cm TL，max published weight 137 kg。正文不用其相对较低的重量作唯一“世界纪录”。
- [USFWS物种页](https://www.fws.gov/species/alligator-gar-atractosteus-spatula)：common length 79 inches，maximum reported length 10 feet，weight up to 350 pounds。页面没列最后两项的测量端点/标本；采用305厘米与158.8千克时在正文明确该限制，与FishBase全长值并列说明。
- [TPWD物种页](https://tpwd.texas.gov/huntwild/wild/species/alg/)：2011年密西西比州327磅具体纪录、上颌双列牙齿、鱼食、幼年快速生长、洪泛植被产卵与并非年年成功补充的生活史。故事据此写河流季节连通性；没有把其近95岁估计写作实测年龄。
- [FWC物种页](https://myfwc.com/wildlifehabitats/profiles/freshwater/alligator-gar/)：淡水与沿海湾生境、繁殖和食性补充。四个来源实际页面均已打开。中国科学院的[中文分类科普](https://ihb.cas.cn/kxcb_1/kxcb/202209/t20220919_6514841.html)另核对“大雀鳝属”的中文名，但不使用其中未经独立复核的轶闻。

### 长吻雀鳝 `longnose_gar`

- [FishBase](https://www.fishbase.se/summary/Lepisosteus-osseus.html)：200 cm TL、22.8 kg、当前分类及分布。页面“common length 17.5 cm”不适于成鱼展示，未采用。
- [Florida Museum](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/longnose-gar/)：鳔辅助呼吸、侧向夹取鱼类、幼鱼吻端黏附结构、原始Esox组合；概述重量16 kg较数据库低，已明示来源差异。
- [SCDNR](https://www.dnr.sc.gov/fish/species/longnosegar.html)：average 2.5–3 feet、4 pounds，没有限制年龄，故不能标作成年均值。
- [NPS上密西西比页](https://www.nps.gov/miss/learn/nature/long-nosed-gar-lepisosteus-osseus.htm)：average 24–36 inches与当地回水分布，作为另一地区概述。四页均直接打开；不使用未加www而发生cache miss的地址。

### 弓鳍鱼 `bowfin`

- [Missouri Department of Conservation现行页](https://mdc.mo.gov/discover-nature/field-guide/emerald-bowfin)：明确学名Amia ocellicauda、Amiidae、adult 15–27 inches/1–5 pounds；水草回水、夜间活动、鳔呼吸、雄鱼护幼和分龄食性。
- [Brownstein等2022原始论文](https://pmc.ncbi.nlm.nih.gov/articles/PMC9709656/)：177个体基因组和颅骨CT支持重新区分两种现生弓鳍鱼；故事是分类研究的释义，没有写“现生物种一亿年没变化”。
- [Eakins安大略生活史数据库](https://www.ontariofishes.ca/fish_detail.php?FID=10)：当前条目标作A. ocellicauda，成人38.1–68.6 cm TL/0.6–3.3 kg，最大92.7 cm TL/9.3 kg，地方纪录83.5 cm TL/6.85 kg。它是鱼类生态学家编纂并公开列出文献的数据库，**不是省政府官方认证纪录机构**；正文因此只称文献汇编值，不假称分种后的新标本复核。
- [FishBase该新物种页](https://www.fishbase.se/summary/Amia-ocellicauda.html)：已接受物种和分布，但最大尺寸栏尚空；不把广义A. calva的109 cm、9.75 kg自动转移。四个实际页面均已打开。Eakins的[数据库首页](https://www.ontariofishes.ca/main.htm)和[作者介绍](https://www.ontariofishes.ca/about.htm)另核查出版责任与2026版本。

### 大口黑鲈 `largemouth_bass`

- [MDC现行物种页](https://mdc.mo.gov/discover-nature/field-guide/largemouth-bass)：M. nigricans、Centrarchidae，total length 10–20 inches、0.5–4.5 pounds，maximum about 24 inches/15 pounds。页面未给成年样本定义，也不是经种界检验的全球纪录表；正文逐项限定为该地区物种概述。
- [Kim、Taylor与Near 2022原始论文](https://www.nature.com/articles/s41598-022-11743-2)：M. nigricans与M. salmoides的名称处理，移殖与杂交背景。PMC入口遇验证码，仅改读论文出版社同一文章的完整公开正文，没有绕过验证。
- [Minnesota DNR](https://www.dnr.state.mn.us/minnaqua/speciesprofile/largemouthbass.html)：当地植被回水、分龄食谱、雄鱼扇水护卵和护幼约一个月。该页保留旧学名，因此仅用其当地生活史，不挪用其名称作当前分类依据。
- 三个实际页面均已打开。未直接引入常见网页所称22磅以上的“largemouth world record”，避免把佛罗里达黑鲈或杂交个体混入本物种。

### 斑点叉尾鮰 `channel_catfish`

- [FishBase](https://www.fishbase.se/summary/Ictalurus-punctatus.html)：Ictaluridae / Ictalurus，132 cm TL、26.3 kg、原生分布和深潭生境。其common 57 cm **SL**没有被误写成57 cm TL。
- [Florida Museum](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/channel-catfish/)：明确adult 15–24 inches，迁移与多年归返、食性、感觉器官。该页导语54 inches与尺寸段52 inches冲突，采用详细段132 cm TL并用FishBase和USFWS交叉验证；不沿用页面其他明显模板错误。
- [USFWS](https://www.fws.gov/species/channel-catfish-ictalurus-punctatus)：常见22 inches、最长52 inches，身体表面味蕾、繁殖与护卵。故事只按解剖感觉事实作中文比喻。
- [SCDNR当前纪录表](https://dnr.sc.gov/fish/freshrecs/records.html)：1964 Lake Moultrie，W.H. Whaley，58 pounds并标为current world's record。四个实际页面均直接打开。另以[FAO AGROVOC](https://agrovoc.fao.org/browse/agrovoc/zh/page/c_3789)可检索条目核对“真鮰属”译名。

### 扁头鲶 `flathead_catfish`

- [FishBase](https://www.fishbase.se/summary/Pylodictis-olivaris.html)：Pylodictis / Ictaluridae，155 cm TL、55.8 kg，幼鱼与成鱼微栖境差异。
- [MDC](https://mdc.mo.gov/discover-nature/field-guide/flathead-catfish)：明确adult commonly 15–45 inches、1–45 pounds（网页把weight误排成width，单位为pounds）；独居、惯用休息掩体、夜间迁往浅处、少食腐败物与亲鱼照卵。
- [USGS NAS](https://nas.er.usgs.gov/queries/FactSheet.aspx?speciesID=750)：当前索引全文可读，直接页请求失败；用其可检索的Ecology、Means of Introduction和Remarks段支持原生范围、1966年开普菲尔河投放11尾成熟鱼、约15年后成为优势捕食者的故事。该页亦指出较新历史证据不支持五大湖原生性，因此没有照抄FishBase旧的lower Great Lakes原生描述。
- [Kansas官方物种页](https://www.ksoutdoors.gov/outdoor-activities/fishing-in-kansas/what-to-fish/flathead-catfish)：搜索索引可读的原页文字列1998 Elk City Reservoir、123 pounds；直接打开403。物种生物学仍由已直接打开的FishBase与MDC承载。具体日期在不同页面有差异，正文只写经一致核对的年份，不加猜测日月。

## D：长江流域

### 分类和极值订正

1. **中华鲟名称**：2026-08-13《鱼类目录》的鲟科完整列表在 `sinensis, Acipenser` 条目最终状态明确为“Current status: Valid as Acipenser sinensis Gray 1835.”（网页文本行289–292）。`Sinosturio sinensis`列为Brownstein & Near（2025）的分类处理，不能因搜索摘要出现该组合就写成当前目录接受名。百科使用`Acipenser sinensis`、`Acipenser`、鲟属；游戏旧数据的名称由集成者另行处理。直接`spid=9762`本次403，科列表可读取，因此该科列表是运行时引用链接。另直接读过[2025原始论文](https://www.nearlab.org/uploads/1/3/3/7/133700440/190_brownstein_near2025sturgons.pdf)，正文第13–14页确实提出Sinosturio属级处理。分类存在观点差异，不把旧组合说成误认物种。
2. **鳜与鳡的科级分类**：各自按当前目录采用Sinipercidae（鳜科）和Xenocyprididae（鲴科），不沿用旧FAO/论文中的Serranidae或广义Cyprinidae。
3. **长吻鮠名称**：目录`spid=5698`当前有效名为`Rhinobagrus dumerili`、Bagridae。旧名`Leiocassis longirostris`、`Tachysurus dumerili`所关联资料可用于同种；本次未核实新属的规范中文名，字段如实说明，未自造中文名。
4. **极值不是同一量尺**：南方鲇大学实物报道的143厘米没有TL/SL说明，与FishBase约114厘米SL不能直接排序比较。此例的22.8千克有鉴定、日期及标本制作单位；正文同时披露数据库收录值较小，以及科普50千克缺少单尾凭据。长吻鮠13千克仅为农业部门概述的可达上限；并列说明FishBase收录值，未称世界纪录。其他种的长度/体重也未假设来自同一个体。



### chinese_sturgeon

- s1支持当前科、属、有效组合及2025不同属级处理；s2支持江海洄游、底栖食性、现存与历史范围。
- s3的形态与生活史段给出长度/体重的汇总上限。采用其公制值，未将NOAA简版四舍五入英制再次精确化。
- s4为郭柏福等原始论文，DOI 10.3724/SP.J.1035.2011.00940，35(6):940–945。表2的1994–1999野生繁殖亲本样本支持雄/雌平均体型；正文清楚标为历史成熟样本，而非全种常见尺寸。摘要和正文支持2009全人工繁殖故事。通过ScienceEngine官方PDF的可检索原文核查，直接PDF载入失败，不声称逐页渲染。
- 保护观察与放生不可出售为既定产品要求；未写任何现实捕捞方法或许可判断。

- s1: [Eschmeyer’s Catalog of Fishes：Acipenseridae，sinensis条目（2026-08-13版）](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?family=Acipenseridae&tbl=species) — California Academy of Sciences；核查2026-10-03
- s2: [Chinese Sturgeon](https://www.fisheries.noaa.gov/species/chinese-sturgeon) — NOAA Fisheries；核查2026-10-03
- s3: [Meadows & Coll (2013), Status Review Report of Five Foreign Sturgeon](https://repository.library.noaa.gov/view/noaa/16217/noaa_16217_DS1.pdf) — NOAA National Marine Fisheries Service；核查2026-10-03
- s4: [郭柏福等（2011）：中华鲟初次全人工繁殖的特性研究](https://doi.org/10.3724/SP.J.1035.2011.00940) — 水生生物学报 / 中国科学院水生生物研究所；核查2026-10-03

### mandarin_fish

- s1为现行分类、明确水系范围；s2为全长/重量数据库记录及视觉追踪捕食。
- s3是2009 FAO技术档案，仅采用形态、生态和注明用途/年龄的养殖尺寸，不把其过时市场数据或“当时尚无商品配合饲料”当成2026现状；档案的广义鳜类国家清单不用于扩大本种分布。
- s4为2020基因组原始研究；故事区分鳜类比较结果与斑马鱼功能验证，没有宣称一枚基因解释所有捕食行为。

- s1: [Eschmeyer’s Catalog of Fishes：Siniperca chuatsi](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=35917) — California Academy of Sciences；核查2026-10-03
- s2: [Siniperca chuatsi species summary](https://www.fishbase.se/summary/Siniperca-chuatsi) — FishBase；核查2026-10-03
- s3: [Cultured aquatic species fact sheet: Siniperca chuatsi (2009)](https://www.fao.org/fishery/docs/CDrom/aquaculture/I1129m/file/en/en_mandarinfish.htm) — Food and Agriculture Organization of the United Nations；核查2026-10-03
- s4: [He et al. (2020), Mandarin fish (Sinipercidae) genomes provide insights into innate predatory feeding](https://pmc.ncbi.nlm.nih.gov/articles/PMC7347838/) — Communications Biology；核查2026-10-03

### northern_snakehead

- s1提供当前有效名与原生国家；s2的瑞典站本次显示9.5千克，旧站8千克不作当前值。最大长度仍按其TL标注。
- s3的Smithsonian物种档案提供成熟起点、食性随发育变化及护幼；成熟长度不能替代成年常见尺寸。未照搬该美国地区的捕捞/移除规则到中国游戏。
- s4可检索的USGS原文提供原生范围、季节微生境和数周护幼；直接打开页面不稳定，核查使用官方页面搜索索引，未宣称所有内链均打开。

- s1: [Eschmeyer’s Catalog of Fishes：Channa argus](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=19483) — California Academy of Sciences；核查2026-10-03
- s2: [Channa argus species summary](https://www.fishbase.se/summary/Channa-argus.html) — FishBase；核查2026-10-03
- s3: [NEMESIS species profile: Channa argus](https://invasions.si.edu/nemesis/species_summary/166680) — Smithsonian Environmental Research Center；核查2026-10-03
- s4: [Northern Snakehead (Channa argus) species profile](https://nas.er.usgs.gov/queries/factsheet.aspx?lv=true&speciesid=2265) — U.S. Geological Survey, Nonindigenous Aquatic Species；核查2026-10-03

### yellowcheek

- s1当前科级分类优先于旧论文；s2的成熟区间和最大纪录分别展示，不把成熟区间写成成年常见体型。
- s3的220–800毫米为未分年龄的形态条目范围，只在正文明确限定用途；它支持中上层、游泳追逐与早期食性。
- s4 DOI 10.1016/j.bse.2010.08.003，原始论文摘要/出版商可检索研究段记载五采样点、140成鱼、九个标记和遗传多样性。部分全文由作者在ResearchGate提供，运行时仍指向出版商。科普性的连通保护意义为研究结论的谨慎概括，未把2010采样当2026种群丰度。

- s1: [Eschmeyer’s Catalog of Fishes：Elopichthys bambusa](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=3216) — California Academy of Sciences；核查2026-10-03
- s2: [Elopichthys bambusa species summary](https://www.fishbase.se/summary/Elopichthys-bambusa.html) — FishBase；核查2026-10-03
- s3: [鳡（2018）](https://dfz.jl.gov.cn/jltc/201805/t20180502_5217576.html) — 吉林省地方志编纂委员会；核查2026-10-03
- s4: [Abbas et al. (2010), Microsatellite diversity and population genetic structure of yellowcheek in the Yangtze River](https://www.sciencedirect.com/science/article/abs/pii/S0305197810001481) — Biochemical Systematics and Ecology；核查2026-10-03

### southern_catfish

- s1为当前有效种、旧亚种关系；s2为数据库的SL极值、体重及底层生境。
- s3是2017-10-13信阳农林学院水产学院第一方报道：2017-10-10南湾水库个体由鱼类学教师鉴定并作剥制标本，具有具体实物链。页面直接打开失败但官方站搜索索引给出完整正文；并用学院教学科研索引与相邻活动页回链确认。未将该条科普式“可达50kg”提升为有凭据的世界纪录。
- s4为Fu、Peng、Killen原始实验，DOI 10.1242/jeb.173187；PubMed/PMC直接访问出现验证页，官方索引与出版商摘要可读。结论仅限15日停食/15日恢复的实验；未宣称野外全部个体表现必然相同。

- s1: [Eschmeyer’s Catalog of Fishes：Silurus meridionalis](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=6151) — California Academy of Sciences；核查2026-10-03
- s2: [Silurus meridionalis species summary](https://www.fishbase.se/summary/Silurus_meridionalis) — FishBase；核查2026-10-03
- s3: [水产学院为南湾水库制作大型鲇鱼类标本（2017-10-13）](https://www.xyafu.edu.cn/scxy/info/1074/1557.htm) — 信阳农林学院水产学院；核查2026-10-03
- s4: [Fu, Peng & Killen (2018), Digestive and locomotor capacity show opposing responses to changing food availability in an ambush predatory fish](https://pubmed.ncbi.nlm.nih.gov/29636411/) — Journal of Experimental Biology；核查2026-10-03

### longsnout_catfish

- s1核实现行有效组合；s2仍用旧组合，但物种对应由目录核实。最大全长与重量均为已发表资料覆盖范围，未计算游戏重量公式。
- s3提供普通个体重量与13千克上限描述，并提供养殖对水质、溶氧和驯食的资料。没有野生年龄分层，不虚构典型成年体长或年龄；养殖饲料也不等于野外完整食谱。
- s4为Liu等2024 Genome Research原始研究（10.1101/gr.278476.123），支持肉食代谢特点与遗传故事；验证在斑马鱼及草鱼模型中进行，正文没有误说为野外长吻鮠基因编辑实验。
- 为保持每条四个主要来源，未纳入2012须再生故事。该研究本次也已读到国家图书馆全文，但不可把其味蕾/再生事实无来源塞入本条。

- s1: [Eschmeyer’s Catalog of Fishes：Rhinobagrus dumerili](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=5698) — California Academy of Sciences；核查2026-10-03
- s2: [Tachysurus dumerili species summary (China)](https://www.fishbase.se/country/CountrySpeciesSummary.php?c_code=156&genusname=Tachysurus&speciesname=dumerili) — FishBase；核查2026-10-03
- s3: [如何饲养长吻鮠？](https://nyncw.sh.gov.cn/bwbdscl/20190103/0009-109878.html) — 上海市农业农村委员会 / 上海三农服务热线；核查2026-10-03
- s4: [Liu et al. (2024), The Chinese longsnout catfish genome provides novel insights into the feeding preference and corresponding metabolic strategy of carnivores](https://genome.cshlp.org/content/34/7/981) — Genome Research / Cold Spring Harbor Laboratory Press；核查2026-10-03


## 校验结果

- 两个JSON均能解析；12个species_id各一次，分别与fish_c/fish_d中的六个ID完全对应。
- 每个要求字段均非空，每个字段的source_ids都能解析到该条sources；各条3–4个来源，访问日均为2026-10-03。
- 长度量法只使用TL/SL/FL/unspecified允许值，数值为正数或显式null，不在资料缺口处填游戏参数。
- 以科属说明加各节正文计算，每条约508–572个汉字（不含英文书目）；本包不是只写少数样例。
