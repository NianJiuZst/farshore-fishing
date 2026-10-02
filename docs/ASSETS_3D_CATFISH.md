# Original catfish, bowfin, and snakehead 3D assets

This family is authored in isolated `tools/art3d/fish_profiles/*.py` modules through the shared `fish_pipeline.py`. Source geometry, UV pigment, raised fin rays, eyes, tapered barbels and weighted rigs are original. No downloaded meshes or photo textures are included in game assets. External reference images are review-only, never shipped as textures.

## Anatomy targets

- `channel_catfish` — *Ictalurus punctatus*: smooth scaleless slate-olive body, sparse spots, four pairs of barbels, upper-jaw overbite, deeply forked tail, arched long anal fin and separate small adipose fin
- `flathead_catfish` — *Pylodictis olivaris*: broad flattened head, small eyes, lower-jaw underbite, mottled yellow-brown naked skin, four barbel pairs, square-rounded tail
- `southern_catfish` — *Silurus meridionalis*: broad flattened head and large upturned mouth, exactly two barbel pairs, tiny soft dorsal and no adipose fin, laterally compressed rear body, very long anal fin and shallow-notched caudal
- `longsnout_catfish` — *Rhinobagrus dumerili* (literature also *Leiocassis longirostris*): projecting conical snout, small inferior crescent mouth, four short barbel pairs, thick adipose fin, spinous dorsal and pectorals, deeply forked caudal
- `bowfin` — *Amia ocellicauda*, retaining the established game ID: robust cylindrical olive body, scaleless rounded head, paired nasal flaps, long soft dorsal but SHORT anal, pelvic fins set back from pectorals, rounded tail, male's pale-rimmed tail-base eyespot and gular plate
- `northern_snakehead` — *Channa argus*: elongated body, flattened broad scaled head, large oblique mouth and no barbels, long dorsal AND anal, small pelvics near pectorals, round tail and irregular python-like blotches

## Verified source references

Read on 2026-10-02:

- USFWS, actual channel catfish photograph by Sam Stukel (public domain): https://www.fws.gov/media/channel-catfish
- Florida Museum, barbel number/positions, deeply forked tail and rounded anal: https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/channel-catfish/
- Florida FWC, channel catfish spots and scaleless appearance: https://myfwc.com/wildlifehabitats/profiles/freshwater/channel-catfish/
- NPS, channel/flathead comparison including jaw overbite versus underbite, tail and coloration: https://www.nps.gov/miss/learn/nature/channel-catfish-ictalurus-punctatus-and-flathead-catfish-pylodictis-olivaris.htm
- Missouri Department of Conservation, current emerald bowfin taxonomy and anatomy, with actual reference photograph inspected: https://mdc.mo.gov/discover-nature/field-guide/emerald-bowfin
- USFWS, distinguishing northern snakehead from bowfin: https://www.fws.gov/species/snakehead-channa-argus
- USFWS, actual snakehead photograph by Ryan Hagerty (public domain): https://www.fws.gov/media/invasive-snakehead-1
- USGS original northern snakehead species profile: https://nas.er.usgs.gov/queries/FactSheet.aspx?SpeciesID=2265
- Yueyang government report, Southern catfish morphology: https://www.yueyang.gov.cn/uploadfiles/202302/20230223161357669.pdf (indexed source text read; direct PDF exceeds browser fetch size)
- Ecology China, longsnout catfish morphology: https://www.eco.gov.cn/news_info/8921.html (indexed government-site text read; direct page 403)
- Park, Kim & Choi (2012), original longsnout catfish barbel study: https://doi.org/10.5657/FAS.2012.0299 (original article text mirrored by https://paperzz.com/doc/8559262/leiocassis-longirostris---e-fas; confirms four barbel pairs)

MDC and NPS/C. Iverson copyrighted reference pictures are only temporary visual QA reference. Do not package them, use them as textures, or redistribute them in a public deliverable.

## Review gate

First channel catfish and northern snakehead exports were rendered from hero, top, side, underside and animated poses. That inspection caught angular barbel curves and a floating snakehead lip; profile geometry was corrected before the remaining species were authored. Current build and approval status is recorded in each species' review directory and the completion section below. Validation JSON is evidence of actual weighted mesh deformation and matching loop endpoints, not merely action names.

All final assets must retain +X nose, Godot +Y up, normalized 1 m X extent, fixed root, and four clips: swim 2 s, struggle 1.2 s, breach 1.4 s, landed 3 s. No texture resampling or lossy texture-compression pass was performed.

## Export and binary audit checkpoint

All six native masters and exported GLBs were built and independently audited on 2026-10-02. Every GLB has a weighted skeleton, 16 bones, six embedded full-resolution material images, exactly 1 m rest X extent, and four clips with the specified durations. Every root translation track is constant. All shared weighted-deformation tests pass, including loop-seam errors below `8e-18 m`; maximum skin influences are three. Model triangle counts range from 28,986 to 33,928.

Final all-view visual inspection remains a separate gate. Hero previews caught and corrected ray-bearing adipose anatomy, regular scale-like flathead pigment, exposed pelvic roots, an unseated longsnout mouth, a floating bowfin throat plate, and an overly deep southern-catfish tail notch. Adipose lobes are now closed, rayless flesh meshes; paired roots use body-surface sampling; flathead pigment is stochastic and scale-free. No source texture was reduced or recompressed for APK size.
