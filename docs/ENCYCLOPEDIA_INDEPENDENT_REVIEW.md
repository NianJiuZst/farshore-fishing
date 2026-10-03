# Independent encyclopedia content review

Review date: 2026-10-03 UTC. Scope: all 44 entries in `encyclopedia_a.json` through `encyclopedia_d.json`, their three source ledgers, and the read-only rendering of natural-history size fields. This review made no production-data or gameplay changes.

## Result and limits

The content is substantially researched, with species-specific habitat, diet, behavior, and stories rather than a small set of sample entries. All 44 complete entries were read. Field-to-source coverage and internal factual scope were reviewed for every entry. Independent browsing concentrated on recently changed taxonomy, disputed sizes, and selected original-research stories; this is not a claim to have independently reproduced every measurement or reopened every cited source.

The initial pass found three concrete corrections and one material source conflict. These were sent to the integrator immediately and all four resolutions were independently read back from production data. The changed maximum labels now distinguish database reports, regional/profile upper sizes, and an IGFA angling record. See the resolution section for final scope and remaining editorial opportunities.

No gameplay size, weight formula, catch record, or encounter probability was used as biological evidence. The rendering inspected during the review preserves TL, FL, SL, and unspecified length types and keeps natural history separate from personal catches. Its initial heading, “文献中的极值”, nevertheless makes the provenance of the headline number important: a regional overview or one large specimen must not silently become a species-wide maximum.

## Corrections found

### 1. Southern catfish: one specimen placed in species-maximum fields

- Entry: `southern_catfish`; fields: `max_length.value_cm = 143`, `max_weight.value_kg = 22.8`
- Primary evidence: the [2017 university report](https://www.xyafu.edu.cn/scxy/info/1074/1557.htm) identifies a single fish caught on 2017-10-10 in Nanwan Reservoir and prepared as a specimen. It does not designate that fish as the species maximum. The article separately gives an unsourced species overview of up to 50 kg
- The original text candidly says it is an example, but the populated maximum metrics still elevate its status
- Recommended resolution: both numerical maximum fields null; retain the identified specimen's length and weight together in clearly labeled example text. Do not convert its unspecified length to TL. FishBase's 114 cm SL cannot be ordered directly against 143 cm with unknown measurement endpoints
- Integrator accepted this resolution

### 2. Chub mackerel: Atlantic range conflicts with accepted species scope

- Entry: `chub_mackerel`; field: `distribution.text`; initial phrase: “东南大西洋海域”
- [Current Eschmeyer entry](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?genus=Scomber&species=japonicus&tbl=species) lists Indian Ocean and Pacific localities. Its Indian Ocean scope includes South Africa, Mozambique, Madagascar, and India
- The [IUCN species treatment](https://doi.org/10.2305/IUCN.UK.2011-2.RLTS.T170306A6737373.en) explicitly distinguishes Atlantic *Scomber colias*. The entry's own taxonomy note already makes this distinction
- Recommended resolution: remove southeast Atlantic from the accepted distribution; retain the catalog-supported Indian/Pacific range with a current taxonomic reference

### 3. Japanese horse mackerel: recapture count versus usable datasets

- Entry: `japanese_horse_mackerel`; field: `story.text`; initial phrase: “后来回收9尾”
- [Original 2026 paper, section 3.1](https://onlinelibrary.wiley.com/doi/full/10.1111/fog.70035): 90 fish released; 11 recapture reports; data recovered from nine tags, while two tags yielded no retrievable data
- Recommended resolution: say that usable tracking data came from nine recaptured fish, or report 11 recaptures and nine usable datasets separately
- The paper independently supports 348 m maximum observed depth, 25.5–35.0 cm release fork length of recaptured fish, deeper daytime swimming, and the qualified size–depth relationship. These are study observations, not population-wide size limits

### 4. Gilthead seabream: contradictory IGFA-derived weight

- Entry: `gilthead_seabream`; field: `max_weight`; initial headline: 17.2 kg
- [FishBase](https://www.fishbase.se/summary/1164) really does report 17.2 kg and points to its IGFA-2001 reference. This is not a transcription error by the writer
- [IGFA's own species page](https://igfa.org/game-fish-database/?search_term_1=206&search_type=SpeciesID) lists a current all-tackle record of 7.36 kg
- This direct-source discrepancy is more specific than the original “current record not checked” disclaimer. It does not prove that no non-angling individual could exceed 7.36 kg, and the older 17.2 kg specimen was not independently traced
- Recommended resolution: show 7.36 kg only with an explicit IGFA all-tackle/angling-record label and preserve the uncorroborated historical database conflict in the detail text; alternatively leave the species-wide numeric maximum null. Do not relabel the angling record as the absolute biological maximum
- Integrator accepted the explicitly labeled IGFA option

## Other maximum fields requiring visible scope

These are provenance distinctions, not new claims that the underlying source values are false.

| Entry | Field(s) | Required interpretation |
|---|---|---|
| `largemouth_bass` | length, weight | Missouri species-profile overview, approximately 24 inches and 15 lb; neither a global pure-*M. nigricans* record nor a species ceiling. Prefer 61 cm to the false precision of 60.96 cm because the source says approximately |
| `alligator_gar` | length, weight | USFWS overview limits, 10 feet and 350 lb; length method and original specimens are unspecified. Retain separate FishBase TL and TPWD specimen context |
| `bowfin` | length, weight | Ontario life-history compilation under the current name; not a newly verified world-record specimen after the species split |
| `longsnout_catfish` | weight | Shanghai agriculture overview limit of 13 kg, not a documented individual or angling certification |
| `saddled_seabream` | weight | FishBase's recorded 0.525 kg; DORIS separately gives 0.7–0.8 kg without specimen particulars, so 0.525 is not an absolute species ceiling |
| `japanese_whiting` | length | FishBase's numerical field is 30 cm, while its text mentions unspecified individuals exceeding 30 cm. Keep the limitation visible |
| `pollack`, `atlantic_wolffish`, `white_seabream`, `common_pandora` | weight | Historical FishBase/IGFA-2001 compilation values; do not label them current certified records without direct verification |
| `european_seabass` | length | Historical FishBase/IGFA-2001 value; same date/scope distinction |
| Other FishBase maxima | corresponding fields | A reported database maximum, not a guaranteed physiological ceiling; length and weight are independent unless paired specimen evidence is supplied |

`rudd`, `japanese_whiting`, and `painted_comber` initially have null maximum weights for stated evidence gaps. This is preferable to zero or inferred values. Painted comber correctly rejects a study sample's 108.99 g maximum as a species maximum.

As a supplementary check, the [IGFA December 2023 record list](https://igfa.org/wp-content/uploads/2023/12/IARecentRecordsDec-2023.pdf) identifies a 9.53 kg northern snakehead all-tackle record; the [Maryland primary report](https://news.maryland.gov/dnr/2023/07/07/eastern-shore-angler-catches-maryland-state-record-snakehead/) gives 21.0 lb and biological identification. The entry's FishBase 9.5 kg is consistent at its stated precision; this is not an additional required numeric correction.

## Independent taxonomy and conservation checks

- [*Amia ocellicauda*](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=16366): current Eschmeyer accepted species, Amiidae, including Great Lakes and Mississippi basin. The split from broad *A. calva* is appropriate here
- [*Micropterus nigricans*](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=19779): current Eschmeyer accepted species, Centrarchidae; the [2022 original paper](https://www.nature.com/articles/s41598-022-11743-2) supports keeping Florida bass and admixed populations distinct. Do not transfer the traditional combined largemouth record automatically
- [*Acipenser sinensis*](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?family=Acipenseridae&tbl=species): the catalog's final current status retains this combination while citing *Sinosturio sinensis* as the 2025 alternative. The encyclopedia makes the distinction correctly
- [*Rhinobagrus dumerili*](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=5698): current accepted combination; retaining an unverified Chinese genus name as Latin rather than inventing one is appropriate
- [*Oblada melanurus*](https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=20002): current accepted combination. The older *melanura* source URLs do not by themselves imply a different species
- [WoRMS *Paralichthys olivaceus*](https://marinespecies.org/aphia.php?id=275816&p=taxdetails) also independently confirms that accepted name
- [NOAA Chinese sturgeon profile](https://www.fisheries.noaa.gov/species/chinese-sturgeon) supports the river/sea life cycle, benthic diet, and qualified present versus historical range. Its population numbers are dated; the encyclopedia wisely does not present them as 2026 abundance
- [NOAA's 2013 status review](https://repository.library.noaa.gov/view/noaa/16217/noaa_16217_DS1.pdf), morphology section, gives 5 m and 450 kg without a length-method designation, supporting the current unspecified-length treatment. The 2011 original reproduction paper's indexed primary abstract supports 18,000 second-generation juveniles; the DOI request itself was temporarily unsuccessful during this review

## Complete entry-by-entry coverage

Every row below includes a read of taxonomy, ordinary size, length/weight evidence, habitat, distribution, behavior, diet, story, and source references. “No new issue” means no additional internal/source-scope problem found in this pass, not that every underlying source was independently remeasured or reread.

| ID | Coverage and disposition |
|---|---|
| common_carp | Species-scope warning and North American introduction story fit cited material; all-age common length is not presented as adult mean; no new issue |
| crucian_carp | Distinguishes related *Carassius*; original anoxia-metabolism story and separate extrema; no new issue |
| roach | Leuciscidae and qualified partial migration; university research abstract independently supports reduced avian predation for stream migrants; no new issue |
| rudd | Zero-weight anomaly rejected; regional ordinary size and seasonal dietary story qualified; no new issue |
| european_perch | 60 cm SL preserved separately from ordinary TL and museum size context; unsupported 10.4 kg anecdote excluded; no new issue |
| northern_pike | Female 150 cm TL and male/unsexed 137 cm FL kept distinct; regional seasonal story; no new issue |
| common_bream | Regional winter migration and year variation independently supported by DTU project page; no new issue |
| tench | 84 cm TL versus 70 cm SL preserved; introduction history has USGS/FWS support; no new issue |
| japanese_horse_mackerel | Original study independently checked; correct recapture/data count as finding 3 |
| chub_mackerel | Remove Atlantic species-scope conflict as finding 2; North American migration story is geographically qualified |
| red_seabream | SL maximum not conflated with TL common length; culture/introduction story has CIESM source; no new issue |
| black_seabream | Accepted spelling versus study spelling acknowledged; six-fish movement sample and cultivated sex-change study properly scoped; no new issue |
| japanese_seabass | Related *L. maculatus* range and aquaculture records excluded; juvenile migration story retains regional scope; no new issue |
| japanese_whiting | Null weight and numerical/prose length discrepancy disclosed; record label needed as above |
| marbled_rockfish | Family-system difference disclosed; live-bearing story species-specific; adult ordinary size gap explicit; no new issue |
| olive_flounder | Accepted species independently checked; developmental eye-migration story and SL/TL distinctions coherent; no new issue |
| atlantic_cod | Habitat/diet/wooden-cod history have database, MarLIN, and NOAA coverage; no new issue |
| pollack | Predatory sequence supported by behavioral source; historic IGFA-derived weight must retain historical label |
| saithe | Northeastern Arctic profile's upper size is not adult mean; stated FishBase weight is independent; no new issue |
| haddock | NOAA adult size scope explicit; floating eggs and fecundity story not turned into recruitment claims; no new issue |
| atlantic_mackerel | FL used for common and maximum length; aggregation example not generalized; no new issue |
| atlantic_herring | SL preserved; demersal adhesive egg story distinguished from pelagic adult habitat; no new issue |
| european_plaice | TL common length versus SL maximum preserved; disputed Mediterranean occurrence not asserted; tagged migration story qualified; no new issue |
| atlantic_wolffish | Maturity threshold not adult ordinary size; guard-parent story is natural history rather than invented anecdote; historical weight label needed |
| european_seabass | Wild size not replaced by aquaculture market weight; FAO salt-pond history; historical length label needed |
| gilthead_seabream | Reproductive story scoped to species and culture context; direct IGFA weight conflict as finding 4 |
| saddled_seabream | Accepted spelling independently checked; DORIS adult range and juvenile tail-mark observation; conflicting weight scopes require visible distinction |
| white_seabream | Avoids merged Atlantic/South African distributions; historic maximum may predate clarified species limits, so retain database/historical scope |
| annular_seabream | Explicit adult size; nonfunctional hermaphroditism result limited to sampled population, not generalized functional sex change; no new issue |
| red_mullet | Mullidae versus Sparidae distinguished; sensory barbels and attendant feeding behavior species-specific; no new issue |
| painted_comber | Sample maximum excluded, eastern Atlantic misidentification acknowledged; research and cleaning observations kept separate; no new issue |
| common_pandora | SL not converted to TL; reproductive timing qualified; historical weight label needed. Standardize the Chinese *Pagrus* genus name with red_seabream for consistency if desired |
| alligator_gar | Floodplain spawning story distinct from oversimplified monster narrative; overview maxima require visible scope |
| longnose_gar | Infant attachment organ and later predation are coherent; common lengths are regional all-age references; no new maximum-type issue |
| bowfin | Current taxonomy independently checked; regional adult size and compilation maxima must retain provenance |
| largemouth_bass | Current taxonomy independently checked; Missouri upper values need regional labels and rounded display |
| channel_catfish | Explicit adult range; source's inconsistent introductory length resolved against detailed sources; record and taste-bud story coherent |
| flathead_catfish | Explicit regional adult range; introductions, original range, and 123 lb record separated; no new issue |
| chinese_sturgeon | Current taxonomy and 5 m/450 kg source independently checked; historic mature-broodstock samples not called current ordinary mean; conservation/game status kept explicit |
| mandarin_fish | Farm age/parent sizes are explicitly cultivated; zebrafish validation not misrepresented as direct wild-fish intervention; no new issue |
| northern_snakehead | Maturity threshold not ordinary adult size; parental care and invasive/native contexts distinguished; 9.5 kg consistent with verified 9.53 kg record precision |
| yellowcheek | Morphological sample range and maturity range not adult ordinary sizes; sampling localities not present abundance; no new issue |
| southern_catfish | Identified specimen is not a species maximum; finding 1. Fifteen-day laboratory responses are appropriately qualified |
| longsnout_catfish | Current taxon independently checked; farm overview and experimental models kept distinct; 13 kg needs source-overview label |

## Completeness and readability

- IDs exactly match the 16 + 16 + 6 + 6 game species; no duplicate or missing encyclopedia IDs
- Every required section has nonempty source IDs resolving within that species. Each species has 2–4 sources
- Initial body length, excluding source bibliography and story title: A 450–486 Han characters; B 437–458; C 532–572; D 505–559. These are broadly near the requested 500-character scale; adding boilerplate to hit a number would worsen the text
- Explicit ordinary-adult references occur in six entries: haddock, saddled seabream, annular seabream, bowfin, channel catfish, flathead catfish. Chinese sturgeon adds historical mature broodstock; mandarin adds cultivated age/broodstock context. Many remaining entries offer an all-age common-length figure or clearly state that ordinary adult data were not obtained. Therefore the deliverable should not be described as 44 independently verified adult size ranges
- The initial prose contains 88 “不能” and 36 “不是” occurrences. Taxonomic, sampling, and measurement qualifications often matter; repeated hypothetical misconceptions often do not. Examples of removable padding include northern snakehead's “耐低氧” versus “不需要呼吸”, southern catfish's “无限期挨饿”, cod's wooden fish not proving modern abundance, and painted comber's cleaning not removing every parasite
- State a limitation once near the relevant data, and use a shared TL/FL/SL explanation. Keep hard cautions where scope actually changes the meaning of the number. Prefer filling ordinary-size gaps with additional credible local adult evidence when available over asking for an impossible single global adult average
- No source photos or externally authored long passages were copied by this review

## Resolution readback

Readback completed on 2026-10-03 after the integrator's edits:

1. `southern_catfish`: both numeric maxima are null; the 143 cm / 22.8 kg pair is explicitly one identified 2017 specimen. Its unreported measurement method remains unspecified
2. `chub_mackerel`: southeast Atlantic removed from the accepted range, current Indian/Pacific catalog scope inserted, and the actual Eschmeyer entry added as a third source
3. `japanese_horse_mackerel`: story now distinguishes 11 recapture reports from nine usable recording tags
4. `gilthead_seabream`: 7.36 kg is explicitly captioned “IGFA垂钓纪录”; the FishBase 17.2 kg conflict remains visible in the supporting text; IGFA's actual species page is added as a fourth source
5. `largemouth_bass`: 61 cm and 6.8 kg are captioned as Missouri profile limits; rounding no longer adds unsupported precision. USFWS gar limits, life-history bowfin compilation values, Shanghai longsnout-catfish limits, the saddled-seabream database value, and the Japanese-whiting numerical field also have explicit source-scope labels
6. The renderer's shared heading is now “最大尺寸与记录范围”; default captions explicitly identify database extrema; TL/FL/SL/unspecified measurement methods remain visible; natural history remains separate from personal catch snapshots

All 44 source-reference and ID-coverage checks were repeated after these edits: exact correspondence with the game species, 2–4 sources per species, every section's references resolving locally, and positive numeric values or explicit nulls. No outstanding blocking factual issue remains in the reviewed content scope. This is content-review clearance, not a new assertion that every source's historical size report is a modern certified world record.

Final integrator readback: both Chinese-sturgeon metrics now carry “NOAA状态报告上限”, because these values come from a status report rather than a database. The numeric evidence independently verified above is unchanged. This caption edit was checked from the final JSON after the independent reviewer finished.

The ordinary-adult size gaps and repetitive cautionary prose documented above remain editorial opportunities. They do not authorize filling unknown values or erasing genuine taxonomy, location, sample, or measurement qualifications. This reviewer changed only this report and made no commits, pushes, history edits, production JSON changes, or gameplay changes.
