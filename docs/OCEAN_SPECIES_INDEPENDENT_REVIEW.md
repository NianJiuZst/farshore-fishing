# Independent review: 30-species ocean expansion

Review date: 2026-10-04 UTC. Scope: the 30 new entries in `fish_e/f.json` and `encyclopedia_e/f.json`, their reference map, and the six fictional ocean pools. The original 44 entries were not re-audited or edited by this review.

## Result

All 30 core profiles were compared with actual authoritative source content, including numerical size fields and measurement labels, taxonomic identity, broad natural range, and diagnostic morphology. Detailed stories were checked against their cited museum, government, author-institution or research-paper content. This is a content review, separate from schema tests, asset/art sign-off and runtime/export QA.

The expansion preserves the important separation between source-scoped natural-history figures and fictional ordinary/rare game sizes. It does **not** establish 30 independently certified biological world records. FishBase maxima were checked as FishBase's published summary fields; most underlying individual measurement dossiers were not available for independent reconstruction.

### Corrections made in this review

1. Replaced erroneous `无齿双髻鲨` wording with `无沟双髻鲨` in the great-hammerhead taxonomy note and scalloped-hammerhead comparison. Removed the invented explanation of “无齿.” Added Academia Sinica's Chinese-name reference to both entries and the source map. The stable IDs and already-correct display names were unchanged. [Academia Sinica](https://fishdb.sinica.edu.tw/chi/species.php?id=383089)
2. Changed the tiger-shark note's stale claim that the game uses “虎鲨” to the accurate statement that it is also a common nickname; the display name remains 鼬鲨.
3. Corrected the 2025 mako thermal-study journal from *Functional Ecology* to *Journal of Animal Ecology*. The article and its four-animal result are real; the publication label was wrong. [Primary article](https://pmc.ncbi.nlm.nih.gov/articles/PMC12586780/)

### Two textual morphology refinements integrated

The integrator applied both corrections to `fish_e/f.json` on 2026-10-04, after this independent review:

- Great barracuda: replace “尾深叉” with a double-emarginate-tail description, retaining pale lobe tips. This is the diagnostic shape used by the cited museum profile. [Florida Museum](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/great-barracuda/)
- Whitetip reef shark: replace the unqualified “窄胸鳍” with relatively short triangular pectorals, distinguishing them from oceanic whitetip's broad rounded paddles. The cited museum explicitly describes broad triangular pectorals. [Florida Museum](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/whitetip-reef-shark/)

## Species-by-species evidence coverage

“Common” means the source's descriptive common-length field, never a newly estimated global adult mean. TL, FL and SL stay as labeled by their sources; “unspecified” is intentional where the source does not state a convention. Maximum lengths and masses are independent unless a source explicitly identifies one fish.

### 1. atlantic_bluefin_tuna — *Thunnus thynnus*

Scombridae; Atlantic-only identity. Short pectorals, bulky spindle and reddish-brown second dorsal agree with NOAA/FishBase. Common size is 200 cm FL; 458 cm TL and 684 kg are the FishBase summary fields, not a paired specimen or current global certification.

Checked evidence: [FishBase — s1](https://www.fishbase.se/summary/Thunnus-thynnus.html); [NOAA Fisheries — s2](https://www.fisheries.noaa.gov/species/western-atlantic-bluefin-tuna); [NOAA Fisheries — s3](https://www.fisheries.noaa.gov/feature-story/new-research-reveals-broad-spawning-distribution-bluefin-tuna)

### 2. pacific_bluefin_tuna — *Thunnus orientalis*

Scombridae; North-Pacific T. orientalis kept separate. Small eyes and short pectorals match NOAA. FishBase 200 cm FL common / 300 cm FL maximum / 450 kg agree with the entry; NOAA’s 150 cm, 60 kg adult overview is explicitly a different descriptive basis.

Checked evidence: [FishBase — s1](https://www.fishbase.se/summary/Thunnus-orientalis.html); [NOAA Fisheries — s2](https://www.fisheries.noaa.gov/species/pacific-bluefin-tuna); [NOAA Fisheries — s3](https://www.fisheries.noaa.gov/feature-story/overfished-sustainable-harvests-pacific-bluefin-tuna-rebound-new-highs)

### 3. yellowfin_tuna — *Thunnus albacares*

Scombridae; tropical/subtropical three-ocean range and long yellow second dorsal/anal fins checked. FishBase gives 150 cm FL common, 239 cm FL maximum and 200 kg. No conversion from an old 280 cm TL claim is made.

Checked evidence: [FishBase — s1](https://www.fishbase.se/summary/Thunnus-albacares.html); [NOAA Fisheries — s2](https://www.fisheries.noaa.gov/species/atlantic-yellowfin-tuna); [Florida Museum of Natural History — s3](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/yellowfin-tuna/)

### 4. bigeye_tuna — *Thunnus obesus*

Scombridae; worldwide warm-water oceanic distribution, robust shape and long juvenile pectorals checked. FishBase explicitly mixes 180 cm FL common with 250 cm TL maximum; 210 kg is a separate published-weight field. The 2010 tagging paper supports variable shallow/deep/intermediate days.

Checked evidence: [FishBase — s1](https://www.fishbase.se/summary/Thunnus-obesus.html); [NOAA Fisheries — s2](https://www.fisheries.noaa.gov/species/atlantic-bigeye-tuna); [Howell et al., Progress in Oceanography / NOAA — s3](https://www.st.nmfs.noaa.gov/fate/documents/Publications/sdarticle.pdf)

### 5. albacore — *Thunnus alalunga*

Scombridae; Thunnus alalunga, very long pectorals and open-ocean distribution checked. 100 cm FL common, 140 cm FL maximum and 60.3 kg match FishBase. FAO’s review directly supports trans-Pacific tag recoveries and warns that regional/seasonal length–weight relations differ.

Checked evidence: [FishBase — s1](https://www.fishbase.se/summary/Thunnus-alalunga.html); [NOAA Fisheries — s2](https://www.fisheries.noaa.gov/species/pacific-albacore-tuna); [FAO / Bartoo and Foreman — s3](https://www.fao.org/4/t1817e/T1817E09.htm)

### 6. skipjack_tuna — *Katsuwonus pelamis*

Scombridae, Katsuwonus rather than Thunnus; 4–6 lower-body dark longitudinal bands checked. FishBase gives 80 cm FL common, 110 cm FL and 34.5 kg maxima. The museum’s older 108 cm FL is not silently substituted. Canning, katsuobushi, absent swim bladder and partial heat retention are supported.

Checked evidence: [FishBase — s1](https://www.fishbase.se/summary/Katsuwonus-pelamis.html); [NOAA Fisheries — s2](https://www.fisheries.noaa.gov/species/atlantic-skipjack-tuna); [Florida Museum of Natural History — s3](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/skipjack-tuna/)

### 7. mahi_mahi — *Coryphaena hippurus*

Coryphaenidae; square-crested mature male head and long continuous dorsal agree with sources. FishBase 100 cm TL common, 210 cm TL and 40 kg checked. NOAA supports rapid first-year growth and early maturity; museum supports rapid color loss. Tropical three-ocean placement is appropriate.

Checked evidence: [FishBase — s1](https://www.fishbase.se/summary/Coryphaena-hippurus.html); [NOAA Fisheries — s2](https://www.fisheries.noaa.gov/species/pacific-mahimahi); [Florida Museum of Natural History — s3](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/dolphinfish/)

### 8. wahoo — *Acanthocybium solandri*

Scombridae; Acanthocybium solandri spelling and 沙氏刺鲅 / 棘鰆 names directly checked in Academia Sinica. Long jaws, serrated triangular teeth, finlets and about 24–30 bars match. 170 cm FL common versus 250 cm TL maximum and 83 kg remain clearly separated.

Checked evidence: [FishBase — s1](https://www.fishbase.se/summary/Acanthocybium-solandri.html); [Florida Museum of Natural History — s3](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/wahoo/); [台湾鱼类数据库／中央研究院 — s4](https://fishdb.sinica.edu.tw/taxon/382484-fishdb)

### 9. swordfish — *Xiphias gladius*

Xiphiidae; flattened bill, no pelvic fins and scaleless adult body checked. FishBase is exactly 300 cm TL common, 455 cm FL maximum and 650 kg published weight. FL’s front measuring point is not specified; the entry correctly refuses to relabel it LJFL. IGFA’s 536.15 kg rod-and-reel record has a different scope.

Checked evidence: [FishBase — s1](https://www.fishbase.se/summary/Xiphias-gladius.html); [NOAA Fisheries — s2](https://www.fisheries.noaa.gov/species/north-atlantic-swordfish); [Florida Museum of Natural History — s3](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/swordfish/); [International Game Fish Association — s4](https://igfa.org/2021/11/26/top-swords-incredible-world-records-for-broadbill-swordfish/)

### 10. blue_marlin — *Makaira nigricans*

Istiophoridae; NOAA uses Makaira nigricans in all three oceans, whereas FishBase retains an Atlantic/Indo-Pacific split. The entry discloses this. Its 290 cm TL common / 500 cm TL / 636 kg are explicitly FishBase’s Atlantic scope. NOAA supports the strong sex-size difference; 66 tags, 984 m and 203 days checked in IGFA’s research report.

Checked evidence: [FishBase — s1](https://www.fishbase.se/summary/Makaira-nigricans.html); [NOAA Fisheries — s2](https://www.fisheries.noaa.gov/species/pacific-blue-marlin); [International Game Fish Association / Stanford research collaboration — s3](https://igfa.org/2023/03/29/new-publication-on-north-atlantic-blue-marlin/)

### 11. striped_marlin — *Kajikia audax*

Istiophoridae; Kajikia audax, compressed body, high pointed dorsal and conspicuous stripes checked. Indo-Pacific routing matches NOAA/IGFA. 290 cm TL common and 420 cm TL match FishBase. IGFA’s actual species page displays 224.1 kg as its current all-tackle record; the alternative FishBase 440 kg is expressly not used as that record.

Checked evidence: [FishBase — s1](https://www.fishbase.se/summary/Kajikia-audax.html); [NOAA Fisheries — s2](https://www.fisheries.noaa.gov/species/striped-marlin); [International Game Fish Association — s3](https://igfa.org/game-fish-database/?search_term_1=164&search_type=SpeciesID); [Burns et al., Current Biology / PubMed — s4](https://pubmed.ncbi.nlm.nih.gov/38412818/)

### 12. indo_pacific_sailfish — *Istiophorus platypterus*

Istiophoridae; enormous spotted sail, slender circular-section bill and long pelvic fins checked. ICCAT 2025 supports global Istiophorus platypterus and I. albicans synonymy. FishBase’s regional 270 cm TL common, 348 cm FL and 100.2 kg remain source-scoped. Atlantic hunting studies are honestly labeled Atlantic cases.

Checked evidence: [FishBase — s1](https://www.fishbase.se/summary/Istiophorus-platypterus.html); [Di Natale et al., ICCAT SCRS/2025/021 — s3](https://www.iccat.int/Documents/CVSP/CV082_2025/n_3/CV082030021.pdf); [Domenici et al., Proceedings of the Royal Society B / University of Plymouth — s4](https://pearl.plymouth.ac.uk/bms-research/120/); [Herbert-Read et al., Proceedings of the Royal Society B / PMC — s5](https://pmc.ncbi.nlm.nih.gov/articles/PMC5124094/)

### 13. great_barracuda — *Sphyraena barracuda*

Sphyraenidae; elongated body, distant dorsals, protruding lower jaw and lower-side black spots checked. Tropical Atlantic/Indo-West-Pacific, with eastern-Pacific absence/rarity, is supported. Museum 200 cm and 50 kg are unspecified-length overview maxima; >150 cm is very large, not an adult mean. Tail wording refinement is noted below.

Checked evidence: [Florida Museum of Natural History — s1](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/great-barracuda/); [Nova Southeastern University — s3](https://nsuworks.nova.edu/occ_stuetd/32/)

### 14. giant_trevally — *Caranx ignobilis*

Carangidae; Caranx ignobilis with steep forehead, robust rear lateral-line scutes and no conspicuous rear opercular spot checked. Indo-west-central Pacific reef routing is appropriate. FishBase common 100 cm TL is kept distinct from Fishes of Australia’s 180 cm TL / 86.6 kg upper figures. Larval directional-swimming study checked.

Checked evidence: [Fishes of Australia / Museums Victoria — s1](https://fishesofaustralia.net.au/home/species/4268); [FishBase — s2](https://fishbase.se/summary/Caranx-ignobilis); [NOAA Fishery Bulletin / Australian Museum — s3](https://spo.nmfs.noaa.gov/sites/default/files/pdf-content/2006/1043/leis.pdf)

### 15. greater_amberjack — *Seriola dumerili*

Carangidae; Seriola dumerili and amber body/head bands checked. NOAA states 6 ft and 200 lb upper scales, usually encountered adults up to 40 lb; conversions to about 182.9 cm / 90.7 kg are correct and unspecified as to length convention. Atlantic shelf structures are suitable. The eight misidentified fish / 105-specimen study is accurately summarized.

Checked evidence: [NOAA Fisheries — s1](https://www.fisheries.noaa.gov/species/greater-amberjack); [NOAA Fisheries / National Systematics Laboratory — s2](https://www.fisheries.noaa.gov/feature-story/amberjack-any-other-name-rethinking-identification-and-unlocking-historical-data-four)

### 16. cobia — *Rachycentron canadum*

Rachycentridae; Rachycentron canadum, broad depressed head, 7–9 isolated dorsal spines and lunate adult tail checked. Tropical/subtropical distribution excludes central/eastern Pacific in the cited NOAA synopsis; Atlantic shelf routing is sound. Museum’s 50–120 cm / usually <=23 kg and 200 cm / 61 kg are source-scoped, not modern record certification.

Checked evidence: [NOAA Fisheries — s1](https://www.fisheries.noaa.gov/species/cobia); [Florida Museum of Natural History — s2](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/cobia/)

### 17. roosterfish — *Nematistius pectoralis*

Nematistiidae; Nematistius pectoralis with elongated comb-like anterior dorsal elements, two oblique body bands and no lateral-line scutes checked against Smithsonian. Eastern-Pacific sandy-shore routing is essential and present. Smithsonian says at least 191 cm and 51.7 kg, with no TL/FL label. FishBase common 60 cm TL / 163 cm FL / 51.7 kg fields were checked through its Swedish mirror. Single-specimen Costa Rican genomic study checked through the primary paper.

Checked evidence: [Smithsonian Tropical Research Institute — s1](https://biogeodb.stri.si.edu/sftep/en/thefishes/species/1223); [FishBase — s2](https://www.fishbase.org/summary/3550); [Genes / Smithsonian-associated research — s3](https://pmc.ncbi.nlm.nih.gov/articles/PMC8620147/)

### 18. red_snapper — *Lutjanus campechanus*

Lutjanidae; Lutjanus campechanus, triangular red head, canines and loss of juvenile dark flank spot checked. NOAA supports western-Atlantic shelf routing. LSU’s 5-year-old size variation and 1996 41-inch / 50.25-lb fish are accurately preserved (104.1 cm / 22.79 kg, unspecified convention). That example is one known paired fish, not an absolute species-length maximum.

Checked evidence: [NOAA Fisheries — s1](https://www.fisheries.noaa.gov/species/red-snapper); [Florida Fish and Wildlife Conservation Commission — s2](https://myfwc.com/wildlifehabitats/profiles/saltwater/snapper/red-snapper/); [Louisiana State University / Louisiana Sea Grant — s3](https://www.seagrantfish.lsu.edu/faqs/redsnapper/biology.htm)

### 19. giant_grouper — *Epinephelus lanceolatus*

Epinephelidae directly confirmed in OBIS/WoRMS; not Atlantic E. itajara. Museum adult gray-brown pattern, black fin spots, massive head and rounded tail checked. Its 90–165 and 180–250 cm SL color stages are not presented as averages. Quick facts explicitly give 270 cm TL and 400 kg. Indo-West-Pacific reef/cave placement is suitable.

Checked evidence: [Ocean Biodiversity Information System / WoRMS — s1](https://obis.org/taxon/218224); [Fishes of Australia / Museums Victoria — s2](https://fishesofaustralia.net.au/home/species/4672); [Australian Museum — s3](https://australian.museum/learn/animals/fishes/queensland-groper-epinephelus-lanceolatus-bloch-1790/)

### 20. dogtooth_tuna — *Gymnosarda unicolor*

Scombridae, Gymnosarda rather than Thunnus; large conical teeth, wavy lateral line and pale soft-fin tips checked. Fishes of Australia quick facts give 248 cm FL. Joshi et al. separately cite 248 cm FL (IGFA 2001) and 131 kg (Collette/Nauen); the entry avoids pairing them. Its 550-fish sample and 163.6 cm model asymptote are correctly scoped.

Checked evidence: [Fishes of Australia / Museums Victoria — s1](https://fishesofaustralia.net.au/home/species/723); [ICAR Central Marine Fisheries Research Institute — s2](https://eprints.cmfri.org.in/8990/1/Joshi_75-79.pdf)

### 21. yellowtail_kingfish — *Seriola lalandi*

Carangidae; southern Seriola lalandi scope avoids historical North-Pacific yellowtail pooling. Blue/silver body, yellow stripe/tail and lack of strong scutes checked. Fishes of Australia’s 250 cm TL / 96.8 kg are distinguished from NSW’s about 190–200 cm / 70 kg. NSW’s up-to-1-m, 10–15-kg common large catch is not mislabeled an adult mean.

Checked evidence: [Fishes of Australia / Museums Victoria — s1](https://fishesofaustralia.net.au/home/species/1662); [New South Wales Department of Primary Industries and Regional Development — s2](https://www.dpird.nsw.gov.au/fishing/fish-species/species-list/yellowtail-kingfish); [NSW Department of Primary Industries — s3](https://www.dpi.nsw.gov.au/__data/assets/pdf_file/0005/1553594/Stock-Status-Summary-2021-22-Yellowtail-Kingfish.pdf)

### 22. opah — *Lampris guttatus*

Lampridae; 2018 Lampris revision and North-Atlantic restricted scope checked. Deep compressed body, long pectorals and red fins match. The 118 cm TL NOAA illustration and 50 cm TL / 5 kg / 185 m Mediterranean specimen are examples, not maxima. FishBase explicitly warns that old complex-wide data remain mixed; both maximum fields correctly stay null.

Checked evidence: [Zootaxa — s1](https://pubmed.ncbi.nlm.nih.gov/29690102/); [NOAA Fisheries — s2](https://www.fisheries.noaa.gov/feature-story/clues-fish-auction-reveal-several-new-species-opah); [FishBase — s3](https://www.fishbase.se/summary/1072); [FishTaxa — s4](https://fishtaxa.com/index.php/FishTaxa/article/download/107/107)

### 23. great_white_shark — *Carcharodon carcharias*

Lamnidae; Carcharodon carcharias with conical snout, triangular serrated teeth, lunate tail and sharp gray/white boundary checked. Museum explicitly describes 600–640 cm as model-based/debated. NOAA’s >4,000 lb is not a measured maximum; nulls are warranted. Maturity ranges are not adult averages. Bonfil et al.’s 380 cm female / 99-day / ~11,100-km voyage checked.

Checked evidence: [Florida Museum of Natural History — s1](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/white-shark/); [NOAA Fisheries — s2](https://www.fisheries.noaa.gov/species/white-shark); [Bonfil et al. / Science (2005) — s3](https://whitesharkconservationtrust.org.nz/wp-content/uploads/2017/12/Transoceanic-Migration-Spatial-Dynamics-and-Population-Linkages-of-White-Sharks.-2005.-R.-Bonfil-M.-Meyer-M.-C.-Scholl-R.-Johnson-S.-OBrien-H.-Oosthuizen-S.-Swanson-D.-Kotze-M.-Paterson..pdf)

### 24. scalloped_hammerhead — *Sphyrna lewini*

Sphyrnidae; Sphyrna lewini, curved scalloped cephalofoil with central/lateral notches and straighter pelvic trailing edge checked. Warm coastal/semipelagic global range supports the chosen pools. FishBase gives 360 cm TL common, 430 cm TL and 152.4 kg. Hawaiʻi’s 17-minute breath-holding inference / four-minute bottom visit is correctly qualified. Chinese comparison name corrected.

Checked evidence: [Florida Museum of Natural History — s1](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/scalloped-hammerhead/); [FishBase — s2](https://www.fishbase.se/summary/Sphyrna_leweni.html); [University of Hawaiʻi at Mānoa / Royer et al. (2023) — s3](https://www.hawaii.edu/news/article.php?aId=12607); [台湾鱼类数据库／中央研究院 — s4](https://fishdb.sinica.edu.tw/chi/species.php?id=383089)

### 25. great_hammerhead — *Sphyrna mokarran*

Sphyrnidae; Sphyrna mokarran, near-straight adult head edge and very tall falcate dorsal checked. Warm global shelf/reef range supports Atlantic/Indian pools. FishBase 370 cm TL common, 610 cm TL and 449.5 kg are historical published fields. The 90% / 50–75-degree / ~10% swimming study is accurately qualified. Correct Chinese name is 无沟双髻鲨.

Checked evidence: [Florida Museum of Natural History — s1](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/great-hammerhead/); [FishBase — s2](https://www.fishbase.se/summary/Sphyrna_mokarran.html); [Payne et al. / Nature Communications (2016), James Cook University repository — s3](https://researchonline.jcu.edu.au/45487/); [台湾鱼类数据库／中央研究院 — s4](https://fishdb.sinica.edu.tw/chi/species.php?id=383089)

### 26. blue_shark — *Prionace glauca*

Carcharhinidae; Prionace glauca with slender blue body, extremely long pectorals and posterior first dorsal checked. Temperate/tropical global open-ocean routing is appropriate. FishBase 335 cm TL common, 400 cm TL and 205.9 kg retained as its fields; NOAA/museum’s ~380 cm summary differs. The 3,997-nautical-mile tag-recapture separation is not called a continuous tracked route.

Checked evidence: [Florida Museum of Natural History — s1](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/blue-shark/); [FishBase — s2](https://www.fishbase.se/summary/prionace-glauca); [NOAA Fisheries — s3](https://www.fisheries.noaa.gov/new-england-mid-atlantic/atlantic-highly-migratory-species/shark-identification-cooperative-shark); [NOAA Fisheries — s4](https://www.fisheries.noaa.gov/feature-story/updated-shark-tagging-atlas-provides-more-50-years-tagging-and-recapture-data)

### 27. shortfin_mako — *Isurus oxyrinchus*

Lamnidae; Isurus oxyrinchus distinguished from I. paucus by shorter pectorals and white mouth region; smooth hooked teeth and lunate tail checked. Museum’s male 200–215 / female 275–290 cm adult descriptions and FishBase 270 cm TL common / 445 cm TL / 505.8 kg are not conflated. Four-shark thermal study supports the story; journal metadata corrected.

Checked evidence: [Florida Museum of Natural History — s1](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/shortfin-mako/); [FishBase — s2](https://fishbase.se/summary/752); [Journal of Animal Ecology (2025), full text in PubMed Central — s3](https://pmc.ncbi.nlm.nih.gov/articles/PMC12586780/)

### 28. tiger_shark — *Galeocerdo cuvier*

Galeocerdonidae confirmed in the current Catalog of Fishes, with older Carcharhinidae usage acknowledged. Broad blunt snout, fading juvenile bars and notched cockscomb teeth checked. Meyer et al. explicitly support the occasional 550 cm TL scale, rather than a certified ceiling; 464 cm was their largest captured fish. FishBase 807.4 kg is source-scoped. Seagrass estimates checked.

Checked evidence: [Australian Museum — s1](https://australian.museum/learn/animals/fishes/tiger-shark-galeocerdo-cuvier-pron-lesueur-1822/); [FishBase — s2](https://www.fishbase.se/summary/886); [Meyer et al. / PLOS ONE (2014), PubMed abstract — s3](https://pubmed.ncbi.nlm.nih.gov/24416287/); [Gallagher et al. / Nature Communications (2022) — s4](https://www.nature.com/articles/s41467-022-33926-1); [California Academy of Sciences — s5](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?genus=Galeocerdo&tbl=species)

### 29. oceanic_whitetip_shark — *Carcharhinus longimanus*

Carcharhinidae; Carcharhinus longimanus with rounded dorsal, long broad paddle pectorals and white tips checked. NOAA supports warm global offshore upper-water habitat and occasional >1,000-m dives. FishBase 270 cm TL common, 400 cm TL and 167.4 kg are source-scoped. NOAA’s warming-water explanation supports the story without an invented fixed temperature limit.

Checked evidence: [NOAA Fisheries — s1](https://www.fisheries.noaa.gov/species/oceanic-whitetip-shark); [FishBase — s2](https://www.fishbase.se/summary/carcharhinus-longimanus.html); [NOAA Fisheries — s3](https://www.fisheries.noaa.gov/feature-story/sharks-rays-and-climate-change-impacts-habitat-prey-distribution-and-health)

### 30. whitetip_reef_shark — *Triaenodon obesus*

Carcharhinidae; Triaenodon obesus, blunt broad head, oval eyes and dorsal/upper-caudal white tips checked. Indo-Pacific reef routing is sound. FAO says 213 cm is reported and adults >160 cm are rare; FishBase’s 18.3 kg is independent. Whitney et al.’s captive 10–24% day / 42–67% night activity is not generalized to wild averages. Pectoral wording refinement noted below.

Checked evidence: [Florida Museum of Natural History — s1](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/whitetip-reef-shark/); [FishBase — s2](https://www.fishbase.se/summary/Triaenodon-obesus.html); [FAO species catalogue, hosted by Naturalis Biodiversity Center — s3](https://sharks.linnaeus.naturalis.nl/linnaeus_ng/app/views/species/taxon.php?epi=74&id=62734); [Whitney et al. / Aquatic Living Resources (2007), University of Hawaiʻi repository — s4](https://www.soest.hawaii.edu/PFRP/reprints/whitney_2007.pdf)

## Fictional geographic placement

All species have at least one sensible source-supported ocean/habitat segment within their chosen composite pools. The world descriptions explicitly avoid claiming single-site co-occurrence.

- Atlantic bluefin stays Atlantic; Pacific bluefin stays Pacific; opah stays in an explicitly northeast/northern-Atlantic segment
- Roosterfish uses an eastern-Pacific sandy-shore segment; giant trevally and giant grouper use Indo-West-Pacific reef segments; southern yellowtail kingfish uses southern-Pacific rocky habitats. A single Pacific travel pool can include these separate segments without claiming they coexist on one island
- Striped marlin and the regional sailfish entry use Pacific/Indian pools; blue marlin's all-ocean placement follows its explicitly declared NOAA single-species treatment
- Barracuda, cobia, greater amberjack and red snapper occupy Atlantic shelf/structure habitats supported by the selected sources
- Dogtooth tuna's Pacific bluewater route is read as a reef/drop-off-adjacent offshore segment. Its Indian reef route is appropriate; it is not described as naturally Atlantic
- Sharks are placed within broad supported warm/temperate ocean and reef/shelf ranges. The whitetip reef shark and oceanic whitetip shark remain ecologically and morphologically distinct
- Game depth/cast thresholds, ordinary caps, rare caps, cubic weights, bait multipliers and release-only rules are explicitly fictional mechanics. They are not natural range limits, biometric conversions or real-world fishing permissions

## Source disagreements and remaining uncertainty

1. The quoted record scopes are part of the factual content and must remain visible in the UI. A database's maximum published weight is not necessarily the current IGFA record or a physical species ceiling. This is especially important for striped marlin, blue marlin, swordfish, giant trevally, yellowtail kingfish and sharks
2. Swordfish and sailfish FishBase `FL` values do not identify the anterior landmark in their summaries. The entries correctly retain FL and avoid claiming LJFL. The review did not reconstruct those original measurements
3. Old *Lampris guttatus* literature spans a species complex. FishBase still warns of residual mixed content, and the 2019 Mediterranean paper itself retains some older broad-range language. The entry uses its documented specimen only, keeps broad ecological statements cautious, and leaves species maxima null. Pacific opah thermal results must not be imported as proven physiology of the restricted species
4. White-shark maximum sizes remain debated and model-based in the selected museum account. Null measurement maxima are honest; the fictional 680-cm game cap does not resolve the biological uncertainty
5. Red-snapper range sources differ in their treatment of the southern red-snapper complex: FishBase retains a narrower U.S./Gulf range, while NOAA and the current Catalog of Fishes give a wider western-Atlantic range. The present entry's NOAA-backed wording is supportable; it should not be expanded into a claim that every southern “red snapper” record is definitely *L. campechanus*. [Current Catalog of Fishes](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=15557), [Smithsonian qualified range](https://biogeodb.stri.si.edu/caribbean/en/thefishes/species/3686)
6. FishBase and some older museum profiles retain taxonomic, size and other historical inconsistencies. This review checked the claims actually used, rather than endorsing every statement on those pages. In particular, museum conservation-status text was not adopted as a current conservation assessment
7. The striped-marlin PubMed page initially returned an empty view; its abstract and DOI were independently recovered from the primary journal/author-institution record. The roosterfish PMC page initially returned an automated browser check; the primary MDPI article and indexed full text supplied the specimen/methods evidence. The roosterfish FishBase.org numeric URL also failed on this retrieval; the same named species summary was verified via its [Swedish mirror](https://www.fishbase.se/summary/Nematistius-pectoralis.html). These were retrieval fallbacks, not proof the original links are permanently broken. No CAPTCHA was solved. [Striped-marlin primary paper](https://www.sciencedirect.com/science/article/pii/S0960982223017402), [Roosterfish primary paper](https://www.mdpi.com/2073-4425/12/11/1710)
8. No meshes, portraits, gameplay numbers, original-44 facts, or legal/fishing guidance were approved by this scientific-text review. The visual model/art pass and final application tests remain separate release gates

## Structural verification after corrections

- `natural_history_contract('game')`: passed; 74 unique canonical encyclopedia entries; file counts 16 + 16 + 6 + 6 + 15 + 15; safe URLs, local source IDs and accepted-name/genus consistency validated
- New fish/encyclopedia ID sets: exactly 30, matching one-to-one
- New accepted binomials and story texts: 30 distinct values each
- Every new entry has nonempty taxonomy, typical-size, maximum-length, maximum-weight, habitat, distribution, behavior, diet and story fields with resolving source IDs
- Every new `normal_max_mm` is below `max_mm`; this check establishes schema separation only, not game balance or factual natural maxima
- Review writes were limited to `encyclopedia_f.json`, the corresponding reference-map lines and this report; no commit was made
