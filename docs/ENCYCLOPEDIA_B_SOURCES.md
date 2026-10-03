# B组鱼类自然史百科：来源与审核

核查日期：2026-10-03。覆盖 `game/data/fish_b.json` 全部16个 species_id；生物学资料独立存于 `game/data/encyclopedia_b.json`，未使用游戏尺寸、鱼饵倍率、重量锚点或玩家统计作为自然史证据。

## 编写与数字规则

- 全文为原创中文概括；每一信息分区均有本条局部 source_ids，来源保留机构、标题、实际URL和访问日期。未复制照片、长引文或原页面大段译文。
- FishBase的 common length 明确标为“常见长度项”，不偷换成成熟个体平均值。只有DORIS明确写 adulte、NOAA明确写 at maturity 的地方才给成年口径；各海区、样本及量法保持限定。
- TL是总长；FL是叉长；SL是标准体长，不含尾鳍。最大长度与最大重量为独立报告，未假定同尾；不使用游戏公式补数。
- 最大值采用已核查资料库汇总口径，不声称等于当前世界纪录。部分来自历史垂钓数据库，已明确标记来源年代。出处链：[FishBase参考文献40637：IGFA截至2001年的垂钓纪录数据库](https://www.fishbase.se/references/FBRefSummary.php?ID=40637)。对应青鳕、狼鱼、金头鲷、白海鲷及绯小鲷的重量，以及欧洲海鲈的长度。
- 大西洋狼鱼的常见成鱼尺寸在所查页面中不可得，明确写未提供；约50—60厘米为成熟门槛，未当成典型成鱼尺寸。字纹鮨最大重量为null；研究采样最大值不当物种极值。
- 黑尾海鲷重量来源存在差异：FishBase给0.525千克，DORIS提0.7—0.8千克却未在该段给个体凭证；两者均在条目注明。绯小鲷的3.2与3.24千克也保留来源精度差异，不宣称是两条独立纪录。
- 中文科属采用常见中文译名，科学名称才是分类锚点。狼鱼科亦称狼鳚科，须鲷科亦称羊鱼科；未把俗名中的“鲷”理解成一律属于Sparidae。

## 分类与证据的重要修正

1. `saddled_seabream`接受名为 **Oblada melanurus**。旧游戏资料和DORIS使用Oblada melanura；当前FishBase数字ID页、WoRMS/WoRCS名录及Eschmeyer目录支持melanurus。species_id保持不变。Eschmeyer页面完整分类条目由搜索索引返回，直接打开曾502；另已实际打开FishBase现名页与WoRCS名录，交叉确认改名。
2. Diplodus sargus的历史广义范围包含如今独立的D. cadenati、D. capensis等；采用DORIS整理后的地中海／黑海范围，不照抄FishBase残留的宽分布。
3. Serranus scriba与东大西洋近似种S. papilionaceus曾混淆；未把旧加那利群岛样本研究直接用于字纹鮨。本条生殖证据采用亚得里亚海原始研究。
4. 环尾海鲷的“会变性”不能泛化。2011年组织学论文把所研究样本归为非功能性雌雄同体；条目用这一限定研究讲明证据层级，而未复制DORIS较宽泛的性转变叙述。
5. 未采用DORIS字纹鮨条目中未充分核验的自体受精猜测或卵黏石描述；仅使用其直接观察的清洁行为、食性及栖地。

## 阅读范围与网页限制

16种FishBase实际物种页均已打开；MarLIN、NOAA、IMR、DORIS、FAO使用的实际页面/PDF亦已打开。个别中文命名页或目录正文受站点限制时，使用工具返回的完整索引条目作辅助，并以其他实际打开的科学分类来源核对。

- 2011年组织学论文的出版社页面直接返回403；已读取出版社搜索索引中的完整摘要，只使用摘要明确支持的研究地点和性系统判断，不声称通读付费全文。
- 台湾鱼类资料库Mullidae页直接出现验证码，未尝试解决或绕过；其数据库索引返回了中文科名。没有使用该科的一般生态描述替代Mullus barbatus本种证据。
- FAO AGROVOC金头鲷条目直接抓取失败，但其索引明确列出上位中文概念“鲷属”；科学分类另由FishBase及FAO物种页交叉支持。
- 所有旧版来源只用于稳定自然史与已发表历史数据；不采用页面中的旧捕捞法规、贸易量或保护评估充当2026年现况。

## 逐种来源索引

### atlantic_cod · Gadus morhua

- 科／属：鳕科 Gadidae／鳕属 Gadus
- 故事主题：议会厅里的木鳕鱼
- s1：[Gadus morhua species summary](https://www.fishbase.se/summary/Gadus-morhua.html)，FishBase（访问 2026-10-03）
- s2：[Atlantic cod](https://www.marlin.ac.uk/species/detail/2095)，Marine Biological Association · MarLIN（访问 2026-10-03）
- s3：[Atlantic Cod](https://www.fisheries.noaa.gov/species/atlantic-cod)，NOAA Fisheries（访问 2026-10-03）

### pollack · Pollachius pollachius

- 科／属：鳕科 Gadidae／青鳕属 Pollachius
- 故事主题：从鱼群下方突然出击
- s1：[Pollachius pollachius species summary](https://www.fishbase.se/summary/34)，FishBase（访问 2026-10-03）
- s2：[Pollack](https://www.marlin.ac.uk/species/detail/9)，Marine Biological Association · MarLIN（访问 2026-10-03）

### saithe · Pollachius virens

- 科／属：鳕科 Gadidae／青鳕属 Pollachius
- 故事主题：跟着鲱鱼远行
- s1：[Pollachius virens species summary](https://www.fishbase.se/summary/1343)，FishBase（访问 2026-10-03）
- s2：[Northeast Arctic saithe](https://www.hi.no/en/hi/temasider/species/northeast-arctic-saithe)，Institute of Marine Research, Norway（访问 2026-10-03）

### haddock · Melanogrammus aeglefinus

- 科／属：鳕科 Gadidae／黑线鳕属 Melanogrammus
- 故事主题：黑色“指印”旁的新生命
- s1：[Melanogrammus aeglefinus species summary](https://www.fishbase.se/summary/Melanogrammus-aeglefinus.html)，FishBase（访问 2026-10-03）
- s2：[Haddock](https://www.marlin.ac.uk/species/detail/79)，Marine Biological Association · MarLIN（访问 2026-10-03）
- s3：[Haddock](https://www.fisheries.noaa.gov/species/haddock)，NOAA Fisheries（访问 2026-10-03）

### atlantic_mackerel · Scomber scombrus

- 科／属：鲭科 Scombridae／鲭属 Scomber
- 故事主题：几公里长的银色鱼群
- s1：[Scomber scombrus species summary](https://www.fishbase.se/summary/Scomber-scombrus.html)，FishBase（访问 2026-10-03）
- s2：[Atlantic mackerel](https://www.marlin.ac.uk/species/detail/44)，Marine Biological Association · MarLIN（访问 2026-10-03）

### atlantic_herring · Clupea harengus

- 科／属：鲱科 Clupeidae／鲱属 Clupea
- 故事主题：海底铺起鱼卵地毯
- s1：[Clupea harengus species summary](https://www.fishbase.se/summary/clupea-harengus.html)，FishBase（访问 2026-10-03）
- s2：[Atlantic herring](https://www.marlin.ac.uk/species/detail/45)，Marine Biological Association · MarLIN（访问 2026-10-03）
- s3：[Atlantic Herring](https://www.fisheries.noaa.gov/species/atlantic-herring)，NOAA Fisheries（访问 2026-10-03）

### european_plaice · Pleuronectes platessa

- 科／属：鲽科 Pleuronectidae／鲽属 Pleuronectes
- 故事主题：电子标签揭开的迁移
- s1：[Pleuronectes platessa species summary](https://www.fishbase.se/summary/Pleuronectes-platessa.html)，FishBase（访问 2026-10-03）
- s2：[Plaice](https://www.marlin.ac.uk/species/detail/2172)，Marine Biological Association · MarLIN（访问 2026-10-03）
- s3：[Subdivision of the North Sea plaice population: evidence from electronic tags](https://www.cefas.co.uk/publications/posters/30096web.pdf)，Cefas · Hunter, Metcalfe, Arnold & Reynolds（访问 2026-10-03）

### atlantic_wolffish · Anarhichas lupus

- 科／属：狼鱼科 Anarhichadidae／狼鱼属 Anarhichas
- 故事主题：凶悍牙齿背后的守卵父亲
- s1：[Anarhichas lupus species summary](https://www.fishbase.se/summary/Anarhichas-lupus.html)，FishBase（访问 2026-10-03）
- s2：[Wolf fish or Catfish](https://www.marlin.ac.uk/species/detail/1747)，Marine Biological Association · MarLIN（访问 2026-10-03）
- s3：[狼鱼科 Anarhichadidae](https://agrovoc.fao.org/browse/agrovoc/zh/page/c_44200)，FAO AGROVOC（访问 2026-10-03）

### european_seabass · Dicentrarchus labrax

- 科／属：狼鲈科 Moronidae／舌齿鲈属 Dicentrarchus
- 故事主题：盐田也曾是鱼塘
- s1：[Dicentrarchus labrax species summary](https://www.fishbase.se/summary/Dicentrarchus-labrax.html)，FishBase（访问 2026-10-03）
- s2：[Dicentrarchus labrax cultured aquatic species fact sheet](https://www.fao.org/fishery/docs/CDrom/aquaculture/I1129m/file/en/en_europeanseabass.htm)，FAO · M. Bagni（访问 2026-10-03）
- s3：[拉汉鱼典：Dicentrarchus labrax](https://fishdb.sinica.edu.tw/chi/chinesequer2.php?R1=&T1=&cn=&dere=asc&fm=&gc=&me=&orderby=family_ch&page=361&pz=25&vn=)，中央研究院 · 台湾鱼类资料库（访问 2026-10-03）

### gilthead_seabream · Sparus aurata

- 科／属：鲷科 Sparidae／鲷属 Sparus
- 故事主题：一生中转换繁殖角色
- s1：[Sparus aurata species summary](https://www.fishbase.se/summary/Sparus-aurata.html)，FishBase（访问 2026-10-03）
- s2：[Sparus aurata cultured aquatic species fact sheet](https://www.fao.org/fishery/docs/DOCUMENT/aquaculture/CulturedSpecies/file/en/en_giltheadseabr.htm)，FAO（访问 2026-10-03）
- s3：[金头鲷（动物）与上位概念鲷属](https://agrovoc.review.fao.org/browse/agrovoc/zh/page/c_36080)，FAO AGROVOC（访问 2026-10-03）

### saddled_seabream · Oblada melanurus

- 科／属：鲷科 Sparidae／尾斑鲷属 Oblada
- 故事主题：一厘米幼鱼的黑尾标记
- s1：[Oblada melanurus species summary](https://fishbase.se/summary/850)，FishBase（访问 2026-10-03）
- s2：[Oblada melanura · Oblade](https://doris.ffessm.fr/Especes/Oblada-melanura-Oblade-720)，FFESSM · DORIS（访问 2026-10-03）
- s3：[Eschmeyer's Catalog of Fishes: Sparus melanurus](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=20002)，California Academy of Sciences（访问 2026-10-03）
- s4：[WoRCS taxon list: Oblada melanura accepted as Oblada melanurus](https://www.marinespecies.org/worcs/aphia.php?p=taxlist&pid=146419&rComp=%3E%3D&tRank=220)，WoRMS / VLIZ（访问 2026-10-03）

### white_seabream · Diplodus sargus

- 科／属：鲷科 Sparidae／重牙鲷属 Diplodus
- 故事主题：曾被当成同种的邻居
- s1：[Diplodus sargus species summary](https://www.fishbase.se/summary/Diplodus-sargus.html)，FishBase（访问 2026-10-03）
- s2：[Diplodus sargus · Sar commun de Méditerranée](https://doris.ffessm.fr/Especes/Diplodus-sargus-Sar-commun-de-Mediterranee-463)，FFESSM · DORIS（访问 2026-10-03）
- s3：[Diplodus taxon list and accepted species](https://www.marinespecies.org/aphia.php?p=taxlist&tName=Diplodus)，WoRMS Editorial Board（访问 2026-10-03）

### annular_seabream · Diplodus annularis

- 科／属：鲷科 Sparidae／重牙鲷属 Diplodus
- 故事主题：看到两种组织，不等于会变性
- s1：[Diplodus annularis species summary](https://www.fishbase.se/summary/Diplodus-annularis.html)，FishBase（访问 2026-10-03）
- s2：[Diplodus annularis · Sparaillon](https://doris.ffessm.fr/Especes/Diplodus-annularis-Sparaillon-487)，FFESSM · DORIS（访问 2026-10-03）
- s3：[The Use of Histological Techniques to Study the Reproductive Biology of the Hermaphroditic Mediterranean Fishes Coris julis, Serranus scriba, and Diplodus annularis (2011)](https://onlinelibrary.wiley.com/doi/10.1080/19425120.2011.556927)，Marine and Coastal Fisheries · Alonso-Fernández et al.（访问 2026-10-03）

### red_mullet · Mullus barbatus

- 科／属：须鲷科 Mullidae／羊鱼属 Mullus
- 故事主题：翻泥者身后的跟随者
- s1：[Mullus barbatus species summary](https://www.fishbase.se/summary/Mullus-barbatus.html)，FishBase（访问 2026-10-03）
- s2：[Mullus barbatus · Rouget de vase](https://doris.ffessm.fr/Especes/Mullus-barbatus-Rouget-de-vase-579)，FFESSM · DORIS（访问 2026-10-03）
- s3：[Mullidae and Mullus barbatus identification sheets, pp.1195–1197](https://www.fao.org/4/x0170f/x0170f55.pdf)，FAO（访问 2026-10-03）
- s4：[Mullidae · 须鲷科／羊鱼科](https://fishdb.sinica.edu.tw/taxon/6382-fishdb)，中央研究院 · 台湾鱼类资料库（访问 2026-10-03）

### painted_comber · Serranus scriba

- 科／属：鮨科 Serranidae／鮨属 Serranus
- 故事主题：张大嘴巴等清洁
- s1：[Serranus scriba species summary](https://www.fishbase.se/summary/Serranus-scriba.html)，FishBase（访问 2026-10-03）
- s2：[Serranus scriba · Serran-écriture](https://doris.ffessm.fr/Especes/Serranus-scriba-Serran-ecriture-144)，FFESSM · DORIS（访问 2026-10-03）
- s3：[Reproductive period and histological analysis of Serranus scriba in Trogir Bay (2005)](https://acta.izor.hr/ojs/index.php/acta/article/view/130)，Acta Adriatica · Zorica, Sinovčić & Čikeš Keč（访问 2026-10-03）

### common_pandora · Pagellus erythrinus

- 科／属：鲷科 Sparidae／小鲷属 Pagellus
- 故事主题：先成为母鱼的成长路线
- s1：[Pagellus erythrinus species summary](https://www.fishbase.se/summary/Pagellus-erythrinus.html)，FishBase（访问 2026-10-03）
- s2：[Pagellus erythrinus · Pageot commun](https://doris.ffessm.fr/Especes/Pagellus-erythrinus-Pageot-commun-2771)，FFESSM · DORIS（访问 2026-10-03）
- s3：[Pagellus erythrinus identification sheet](https://www.fao.org/fishery/docs/CDrom/ARTFIMED/ArtFiWeb/descript/Species/SPAPAERY.HTML)，FAO（访问 2026-10-03）
- s4：[拉汉鱼典：Pagellus erythrinus](https://fishdb.sinica.edu.tw/chi/chinesequer2.php?R1=&T1=&cn=&dere=desc&fm=&gc=&me=&orderby=is_accepted_name&page=216&pz=100&vn=)，中央研究院 · 台湾鱼类资料库（访问 2026-10-03）

## 验证结果

- JSON可解析，schema_version为1，16个唯一species_id与fish_b.json完全对应。
- 全部分区引用非空，source_ids均指向同条存在的来源；每种2—4个来源。
- 最大值为数字或明确null；长度类型逐条为TL、FL或SL；未在物种间偷换测量口径。
- 唯一需要显示层注意的科学名变化是Oblada melanura → Oblada melanurus。
