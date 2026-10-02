# 长江流域新增鱼类与场景资料审核

核查日期：2026-10-02。此包只新增六个稳定 `species_id`，不复制或替换原有32个鱼种。新增区域 `yangtze`（长江流域）；`yangtze_river` 是淡水中游江河／通江湖泊廊道（1–35m），`yangtze_estuary` 是河口外近海盐水子场景（5–40m），不是内河盐水化。全部为虚拟游戏场景，不构成现实捕捞许可、捕鱼指南或地理定位。

## 身份与保护处理

- 中华鲟 `chinese_sturgeon`：采用 Eschmeyer 2026目录接受的 **Sinosturio sinensis**；NOAA及许多保护资料仍使用 **Acipenser sinensis**，两名指同一个请求物种，旧名保存在 `scientific_synonyms` 及介绍中。不是长江鲟（S. dabryanus）或白鲟。属江海洄游、底栖取食的鲟类，不能写成伏击型“猛鱼”。
- 长吻鮠 `longsnout_catfish`：采用 Eschmeyer 2026-08接受的 **Rhinobagrus dumerili**。**Leiocassis longirostris** 和 **Tachysurus dumerili** 为同物异名／旧组合，均保留供核查；不同渔业出版物采用不同组合，不宣称所有数据库已同步。
- 中华鲟在本作仅于 `yangtze_estuary` 的海洋阶段出现。`release_only=true`，`encounter_type=conservation_observation`，`conservation_note=保护观察：虚拟互动，不对应现实捕捞`。集成端须在结算与存档处禁止出售，只允许保护放生；这是产品规则，不是对现实保护法律的简化描述。

## 六个鱼种的科学来源与边界

### 中华鲟

[NOAA Fisheries物种档案](https://www.fisheries.noaa.gov/species/chinese-sturgeon)明确长江淡水及中国海岸海水分布、灰黑背、腹面口、四根须及上尾叶较长。NOAA的[五种外国鲟类状态报告](https://repository.library.noaa.gov/view/noaa/16217/noaa_16217_DS1.pdf)提供骨板和鳍条形态与底栖食性背景。科学分类按[Eschmeyer目录](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=9762)和作者公开的[Brownstein & Near 2025原始分类论文](https://www.nearlab.org/uploads/1/3/3/7/133700440/190_brownstein_near2025sturgons.pdf)。目录搜索索引可读，直接页面偶发403；论文与NOAA作为交叉核验。游戏800–2400mm、1400mm/18000g锚点只是虚拟观察体型，未抄用或拟造科研长度重量系数。

### 鳜

[FAO养殖物种档案](https://www.fao.org/fishery/docs/CDrom/aquaculture/I1129m/file/en/en_mandarinfish.htm)用于 Siniperca chuatsi 身份、侧扁体、大口、突出下颌、黄褐斑纹、棘软背鳍和圆尾；[中国科学院水生生物研究所期刊原始研究](https://ssswxb.ihb.ac.cn/article/doi/10.7541/2018.136)记录长江中游牛山湖的鳜。选择淡水1–15m；FAO跨东北亚描述有时同时讨论近缘鳜类，本作中国长江归属另有具体样本证据，不据此随意扩展国家。

### 乌鳢

[USGS物种档案](https://nas.er.usgs.gov/queries/FactSheet.aspx?SpeciesID=2265)和[USGS Circular 1251](https://pubs.usgs.gov/circ/2004/1251/report.pdf)用于 Channa argus 身份、长背／臀鳍、扁头、深色斑块和中国至长江支流原生分布。选择淡水1–8m的缓流与植被边缘。没有将美国入侵分布当作中国原产来源，也不混为斑鳢或弓鳍鱼。

### 鳡

[Abbas等长江实测种群研究](https://www.sciencedirect.com/science/article/abs/pii/S0305197810001481)包含洞庭、鄱阳、东湖等中下游样点并描述大型游泳性食鱼生态。[吉林官方地方志条目](https://dfz.jl.gov.cn/jltc/201805/t20180502_5217576.html)描述尖吻大口、无须、黄颊、小而靠后的背鳍与深叉尾，仅作为形态依据，未把吉林记录错称长江证据。[Eschmeyer身份条目](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=3216)确认 Elopichthys bambusa。淡水1–20m为游戏范围。检索发现商业百科把鳡误标成 Luciobrama macrocephalus；该说法未采用。

### 南方鲇

[嘉陵江亲鱼的原始遗传研究](https://www.sciencedirect.com/science/article/abs/pii/S004484861932705X)明确 Silurus meridionalis 及长江支流采样；[岳阳市公开环境资料](https://www.yueyang.gov.cn/uploadfiles/202302/20230223161357669.pdf)的物种条目描述洞庭湖及四水分布、两对须、短小背鳍、长臀鳍和微凹尾。大PDF直接读取超过工具大小上限，物种条目经可检索原文摘录核对；不声称逐页审阅整份环境报告。淡水2–30m为游戏底层子生境。游戏体型不取代实测鱼类鉴定。

### 长吻鮠

[Eschmeyer现名条目](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=5698)直接明确长江流域淡水分布及 Rhinobagrus dumerili 名称；[旧名条目](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=5910)完整列出名称沿革。四对须参考[Park等2012原始组织学论文 DOI](https://doi.org/10.5657/FAS.2012.0299)，其[韩国研究文献索引](https://www.kci.go.kr/kciportal/ci/sereArticleSearch/ciSereArtiView.kci?sereArticleSearchBean.artiId=ART001726436)确认作者、卷期与研究身份。论文全文可检索摘录明确四对须。吻、脂鳍、无鳞和叉尾还与农业部SC 1040-2000物种标准的可检索原文交叉核对；[农业部官方标准目录](https://yyj.moa.gov.cn/kjzl/201904/t20190419_6210546.htm)确认该标准存在。[上海农委说明](https://nyncw.sh.gov.cn/bwbdscl/20190103/0009-109878.html)提供一般质量背景。[上海海洋大学种质普查材料](https://wyxy.shou.edu.cn/_upload/article/files/e1/64/0e9f65ac480f81b7d1dda7b3721e/cd94ead1-0a57-40f8-ba32-2f526a8a5efd.pdf)作为补充形态参考，其大PDF未能全文载入；不以它单独支持形态结论。淡水2–30m为本作可达范围。

## 两个已存在鱼种的长江重叠建议

由集成负责人修改既有数据，不在 fish_d.json 内重复：

- `common_carp` → `yangtze_river`，淡水。原始[种群遗传研究](https://pubmed.ncbi.nlm.nih.gov/23079816/)取样于湖北石首及江苏扬州长江野生种群；[2022–2023年沅水调查](https://ssswxb.ihb.ac.cn/cn/article/doi/10.7541/2025.2024.0328)也列 Cyprinus carpio 为优势种。原有欧洲低地介绍应扩为跨欧亚／包括中国河湖，不能让文字暗示仅欧洲。
- `black_seabream` → `yangtze_estuary`，盐水。中国渔业研究机构的[东海黑鲷eDNA原始研究](https://www.frontiersin.org/journals/marine-science/articles/10.3389/fmars.2022.848950/full)在长江口渔场、舟山等区发现黑鲷信号，主要相关水深20–40m。它支持河口外近海区域存在；eDNA不能保证某个具体岸点、时刻必定有鱼，不能扩到淡水上游。

六个新增物种加上述两个真实重叠种使长江区域达到至少八种；是否全部实际可达须由集成端依据盐度、深度、装备和抛距组合测试。

## 数值、素材和验证约定

- `min_gear`均为0或1，所有`min_cast`≤0.28，`difficulty`位于0..1。遇鱼深度在指定区域范围内，盐度与唯一钓点一致。
- 尺寸范围、长度重量锚点、天气／饵／时段倍率、行为及稀有度都是明确标注的游戏参数。历史科研采样不能视为今日捕捞许可。
- 六张鱼图均由内置 image_gen 分别单次生成，透明alpha，左向、完整鱼体；原画1536×1024，运行图1024px宽，缩略图256px宽。没有外部照片复制、伪造路径或下载图冒充生成。
- `yangtze.png`由内置 image_gen 单次生成，原画1536×1024，运行1440×960；画面是长江河湖廊道的虚构地区合成，不是河口实景地图。另增独立 `yangtze_estuary.png` 表现河口外近海：开阔海面、低平远岸和泥沙水色，同样为1536×1024原画、1440×960运行图；由 `yangtze_estuary` 钓点的场景覆写选择。
- `docs/ASSETS_D.json`记录每张实际路径、完整提示词、来源、alpha统计、尺寸、SHA-256和形态人工审核；`art_masters/d/generation_inputs.json`保留生成输入及原始返回路径。alpha原样保留，仅做Lanczos比例缩放。
- 保护交互的禁止出售、既有存档兼容、区域列表及Android包由集成测试验证，不在本素材包中假称已经验证。
