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

At this export checkpoint, final all-view visual inspection was still pending; completed acceptance is recorded below. Hero previews caught and corrected ray-bearing adipose anatomy, regular scale-like flathead pigment, exposed pelvic roots, an unseated longsnout mouth, a floating bowfin throat plate, and an overly deep southern-catfish tail notch. Adipose lobes are now closed, rayless flesh meshes; paired roots use body-surface sampling; flathead pigment is stochastic and scale-free. No source texture was reduced or recompressed for APK size.

## Dynamic contact correction checkpoint

The strengthened membrane-and-ray attachment audit samples nine frames of each of four clips. It found small, real dorsal-root placement gaps in channel catfish and flathead catfish. Their manually entered dorsal/anal root coordinates were replaced with dense samples of the actual body surface and 1.5 mm authored underlap; no body outline, fin outer edge, species marking, or audit tolerance was relaxed. All six now pass the unchanged 4 mm normalized-rest-length limit (worst distances 2.123, 2.122, 3.456, 3.670, 2.103, 2.077 mm respectively for channel, flathead, southern, longsnout, bowfin, snakehead). Invalid candidates were blocked from promotion with Blender `--python-exit-code 1`.

The canonical models and masters were regenerated atomically for this numeric checkpoint. Updated all-angle/pose review followed as a separate gate; its completed outcome is recorded below. Android package/device acceptance remains separate.


## Final visual acceptance — passed

Completed 2026-10-02 on the contact-corrected frozen masters. All **48 actual 1200 × 800 renders at 32 samples** were inspected: hero, side, top, underside, swim, struggle, breach and landed for each species. No detached membrane/ray geometry or unseated eyes, mouths, barbels or throat plate was found in these inspected views. The species-specific anatomy and silhouettes remain distinct. No canonical model, source profile or texture was changed during this final review.

Every species also retains its passing **36-pose** membrane-and-ray contact audit, with the unchanged **4 mm** normalized-length limit. Hash-bound visual records tie the exact GLB, native master, source profile, builder manifest, attachment validation, independent binary audit and every rendered image together. These results close the source-asset visual/contact gates; they do not claim Android package or device-runtime acceptance.

| Species | Views inspected | Worst contact, mm | Accepted GLB SHA-256 prefix |
|---|---:|---:|---|
| `channel_catfish` | 8/8 | 2.123 | `79eadc9f2e788e9c` |
| `flathead_catfish` | 8/8 | 2.122 | `c34087572690a8e8` |
| `southern_catfish` | 8/8 | 3.456 | `198e629f0409a34e` |
| `longsnout_catfish` | 8/8 | 3.670 | `6cc5c4479b8770ea` |
| `bowfin` | 8/8 | 2.103 | `b41e73e0603fc5da` |
| `northern_snakehead` | 8/8 | 2.077 | `fdceece8f75f0f39` |

Evidence lives in `ownbuild/fish3d-catalog/<species>/visual_review.json`, `contact_sheet.png`, `validation.json`, `manifest.json` and `glb_audit.json`. The contact sheets are labeled QA previews assembled from the inspected originals; game textures and native geometry retain their original quality. `channel_catfish/certify_views.py` checks render completion, freshness and all hash bindings before recording an explicitly inspected review.

### Verified durable evidence

- Contact-corrected source/master/GLB backup: `/workspace/shared/farshore-catfish-3d-backup/family-contact-20261002T1424Z.tar.gz`; SHA-256 `bf1dbc67b5f2f68c7219572e8e52a63a8833fb04e57edecdc4e3fc1ff1236652`. All 18 current canonical profiles, masters and GLBs were independently byte-compared against this archive during final review.
- Compact final visual-evidence backup: `/workspace/shared/farshore-catfish-3d-backup/family-visual-final-20261002T1528Z.tar.gz`, with an adjacent `.verified.json` file containing the archive/member hashes. This bounded pack contains review metadata, six contact sheets, this document and the audit helpers. Native asset payloads remain in the already-verified contact backup. External reference photographs are not included.
