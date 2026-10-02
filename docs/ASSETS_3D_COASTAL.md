# Original coastal and reef fish, full catalog conversion

## Status
All 15 original species are authored and exported. Structural, weighted-skin, four-clip, loop, normalization and fin-root-contact audits pass. Whiting, marbled rockfish, mandarin fish, largemouth bass, Japanese seabass, saddled seabream and white seabream have passed complete eight-view inspection. All fifteen heroes have been inspected. Remaining angle and pose review is in progress; this document does not yet certify full visual completion.

## Authorship and provenance
All meshes and surface maps were generated from original hand-authored anatomy and pigment algorithms in Blender 4.3.2. No source photograph, external fish mesh, purchased model, unlicensed texture or add-on is included. Sources below are factual morphology references only, checked 2026-10-02. Proportions are an artistic game reconstruction, not scan metrology.

Each profile owns an independent body section list, head proportions, mouth, fin placements, fin outlines and tail. A few curve-building utilities in japanese_whiting.py are reused to loft those independently supplied curves; they do not construct a generic fish or supply a common body. All 15 body section hashes are distinct and all GLBs differ.

## Coordinate and animation contract
- Authored nose +X; exported Godot up +Y; rest X bounds are centered and exactly 1 meter total length
- Runtime scales this same fish once to its actual catalog length; no camera-size fixture is baked into geometry
- Four independently baked clips: swim 2 s, struggle 1.2 s, breach 1.4 s, landed 3 s
- Root translation is constant across each clip; fixed bind-space translation is not trajectory drift
- Real volumetric bodies, solid-thickness fin membranes, raised rays, bilateral eyes, lip meshes and weighted skin
- Fin roots use dense inset surface curves and the caudal body cap; all clips sampled at nine phases pass the 4 mm attachment gate without tolerance overrides
- Manifests and independent glb_contract.json audits identify exact GLB bytes, hashes, bounds, weighted primitives and distinct outline hashes

## Species and diagnostic anatomy

### japanese_whiting

Slender subcylindrical sand-whiting body with pointed elongated snout and small terminal mouth; Separate first XI-spined dorsal and long low second dorsal with 21-23 soft rays; Long low anal opposite second dorsal; shallow-emarginate rather than deeply forked tail; Pale sandy dorsum and silvery cream sides, pale fins.

Geometry: 31,346 triangles; 16,293 authored vertices; 11 skinned material groups; max sampled attachment distance 1.915 mm.

References:
- https://fishdb.sinica.edu.tw/taxon/382628-fishdb

### marbled_rockfish

Moderately deep stout body with broad bony head and large oblique mouth; Continuous notched dorsal with twelve anterior spines and rounded soft rear; Broad fan-shaped pectorals, rounded caudal, short three-spined anal; Irregular reddish-brown saddles; pale spotting below lateral line only; No suborbital ridge or suborbital spine and no skin flap in pectoral axil.

Geometry: 34,540 triangles; 17,960 authored vertices; 11 skinned material groups; max sampled attachment distance 1.742 mm.

References:
- https://fishesofaustralia.net.au/home/species/3136
- https://www.frontiersin.org/journals/marine-science/articles/10.3389/fmars.2022.912129/full

### mandarin_fish

Compressed high-backed body, broad oblique predatory mouth with protruding lower jaw; Brown-yellow fine-scaled sides with irregular dark blotches and eye-to-mouth markings; Hard-spined anterior dorsal and tall rounded soft posterior dorsal joined at a notch; Rounded caudal and pectorals; gill cover with two flat rear spines per side.

Geometry: 33,976 triangles; 17,668 authored vertices; 11 skinned material groups; max sampled attachment distance 1.814 mm.

References:
- https://www.fao.org/fishery/docs/CDrom/aquaculture/I1129m/file/en/en_mandarinfish.htm

### largemouth_bass

Adult olive-green elongated sunfish body and broken dark horizontal lateral stripe; Very large oblique mouth; upper jaw reaches posterior to the eye; Deep notch between low spiny dorsal and high rounded soft dorsal; Wide slightly emarginate tail and rounded rather than spear-like pectorals.

Geometry: 33,244 triangles; 17,280 authored vertices; 11 skinned material groups; max sampled attachment distance 1.794 mm.

References:
- https://www.dnr.sc.gov/fish/species/largemouthbass.html
- https://www.dnr.state.mn.us/minnaqua/speciesprofile/largemouthbass.html
- https://dnr.maryland.gov/fisheries/Documents/Reg_Changes/LargemouthBass_ScientificRenaming.pdf

### japanese_seabass

Elongated silver-green adult Japanese seabass with no dense flank spotting; Thirteen-spined dorsal joined through deep notch to elongated soft dorsal; Large oblique mouth and slightly projecting lower jaw; Forked caudal and short anal fin beneath rear soft dorsal.

Geometry: 33,592 triangles; 17,464 authored vertices; 11 skinned material groups; max sampled attachment distance 1.804 mm.

References:
- https://www.fishbase.se/summary/Lateolabrax_japonicus.html
- https://www.museum.kagoshima-u.ac.jp/ichthy/INHFJ_2022_026_034.pdf

### european_seabass

Adult silver-grey body with blue-grey back and no juvenile flank spots; Two separate dorsal fins: compact first with nine hard spines, distinct second soft fin; Moderately forked tail and broad terminal mouth; lower jaw only slightly projecting; Diffuse opercular spot and two flat opercular spines per side.

Geometry: 32,684 triangles; 16,992 authored vertices; 11 skinned material groups; max sampled attachment distance 1.847 mm.

References:
- https://www.fao.org/fishery/docs/CDrom/aquaculture/I1129m/file/en/en_europeanseabass.htm
- https://www.marlin.ac.uk/species/detail/2127

### red_seabream

Deep compressed red-pink sparid, distinct bulged convex nape; Small terminal mouth and stout jaw ending well forward of eye; Fine blue spots across rose sides; pink-silver belly; Continuous spiny dorsal, pointed pectorals and strongly forked caudal.

Geometry: 32,110 triangles; 16,709 authored vertices; 11 skinned material groups; max sampled attachment distance 1.917 mm.

References:
- https://ciesm.org/atlas_preview/Pagrusmajor.php
- https://fishdb.sinica.edu.tw/chi/species.php?science=Pagrus+major

### black_seabream

High compressed dark-silver body with steep forehead and rounded powerful nape; Small thick-lipped terminal mouth, robust shell-crushing jaw; Faint broad adult bars under large dark-edged scales; Long continuous spiny dorsal and forked dark caudal, dark pelvic fins.

Geometry: 32,278 triangles; 16,797 authored vertices; 11 skinned material groups; max sampled attachment distance 1.837 mm.

References:
- https://fishdb.sinica.edu.tw/mobi/species.php?science=Acanthopagrus+schlegelii

### gilthead_seabream

Deep oval compressed body and smoothly curved steep forehead with small eyes; Golden transverse band between eyes; black upper opercular blotch edged red below; Low small slightly oblique mouth with thick lips; Eleven-spined continuous dorsal, long pointed pectorals and forked tail.

Geometry: 32,950 triangles; 17,149 authored vertices; 11 skinned material groups; max sampled attachment distance 1.876 mm.

References:
- https://www.fao.org/fishery/docs/DOCUMENT/aquaculture/CulturedSpecies/file/en/en_giltheadseabr.htm

### saddled_seabream

Oblong, less deep-bodied bream with short snout and proportionally large eyes; Small oblique upturned terminal mouth; White-bordered black caudal-peduncle saddle; fine longitudinal dark flank lines; Continuous dorsal with eleven spines and deeply forked uncoloured tail.

Geometry: 33,322 triangles; 17,323 authored vertices; 11 skinned material groups; max sampled attachment distance 1.879 mm.

References:
- https://doris.ffessm.fr/Especes/Oblada-melanura-Oblade-720

### white_seabream

Deep compressed silver body with high curved dorsal contour; Black caudal saddle that does not reach the underside of peduncle; Black opercular margin and dark pelvic fins; restrained adult vertical bars; Short small mouth with incisor-like front teeth and forked tail.

Geometry: 32,446 triangles; 16,885 authored vertices; 12 skinned material groups; max sampled attachment distance 1.833 mm.

References:
- https://doris.ffessm.fr/Especes/Diplodus-sargus-Sar-commun-de-Mediterranee-463

### annular_seabream

Small oval compressed silver-yellow bream with tapered head and small mouth; Nearly closed black ring around caudal peduncle, unlike open white-seabream saddle; Yellow pelvic fins and yellow anterior anal fin; Continuous moderately raised dorsal, proportionally narrow forked tail, no adult flank bars.

Geometry: 31,942 triangles; 16,621 authored vertices; 12 skinned material groups; max sampled attachment distance 1.868 mm.

References:
- https://doris.ffessm.fr/Especes/Diplodus-annularis-Sparaillon-487

### common_pandora

Oval compressed pink-silver body with longer almost straight snout, unlike convex-naped red seabream; Small low oblique mouth; snout exceeds twice eye diameter; Fine blue speckles concentrated on upper body and red upper opercular edge; Continuous twelve-spined dorsal, very long pointed pectorals and forked tail without white tips.

Geometry: 32,446 triangles; 16,885 authored vertices; 11 skinned material groups; max sampled attachment distance 1.854 mm.

References:
- https://doris.ffessm.fr/Especes/Pagellus-erythrinus-Pageot-commun-2771
- https://www.fao.org/fishery/docs/CDrom/ARTFIMED/ArtFiWeb/descript/Species/SPAPAERY.HTML

### red_mullet

Elongated relatively flat-bellied body and abrupt blunt forehead above small low mouth; Exactly two white sensory chin barbels, no longer than pectoral fins; Two clearly separated dorsals, unstriped pale first dorsal and unstriped forked caudal; Large easily shed-looking scales, pink-silver sides; no opercular spine.

Geometry: 30,402 triangles; 15,801 authored vertices; 12 skinned material groups; max sampled attachment distance 2.509 mm (including both chin-barbel base rings).

References:
- https://doris.ffessm.fr/Especes/Mullus-barbatus-Rouget-de-vase-579
- https://www.fao.org/4/x0170f/x0170f55.pdf

### painted_comber

Elongated slightly deep-bellied compressed serranid with pointed straight head; Six prominent brown flank bands, pale blue belly patch and red-blue head tracery; Yellow tail and peduncle, continuous spiny-soft dorsal; Large mouth with three small opercular spines and thoracic pelvic fins.

Geometry: 32,648 triangles; 16,976 authored vertices; 12 skinned material groups; max sampled attachment distance 1.871 mm.

References:
- https://doris.ffessm.fr/Especes/Serranus-scriba-Serran-ecriture-144

## Evidence and backups

Per-species evidence lives in ownbuild/fish3d-catalog/<id>/. Canonical assets are art_masters/3d/<id>.blend and game/assets/3d/<id>.glb. Editable source is tools/art3d/fish_profiles/<id>.py. The bounded external checkpoint is /workspace/shared/farshore-3d-checkpoints/fish/catalog/<id>/, with byte-for-byte comparisons after copy. No full-project archive is created by this batch.

Review images are generated from the saved master, not mocked. Heroes use 1200×800 at 24 samples; supporting views use 960×640 at 16 samples in the bounded batch runner (initial representative captures use 1200×800). Render settings are recorded per view. Two threads and the shared two-slot lock are used.
