# Complete photoreal fish artwork backup

This archive contains all **44 accepted fish artworks**, generated on **2026-10-02** with OpenAI's built-in image-generation tool for the Farshore Fishing encyclopedia and catch cards. Each species was generated separately; selected anatomical problems were corrected through image generation rather than recoloring or procedural drawing.

## Artwork and authoritative records

- `masters/`: 44 accepted final, full-resolution RGBA PNGs, **1,536–2,172 pixels wide**. These are the final image-generation outputs, including accepted anatomical revisions. Their original file bytes are retained.
- `runtime/`: 44 byte-identical copies of the corresponding masters, preserving all pixels and transparency.
- `thumbs/`: 44 derived RGBA PNGs with a maximum dimension of **512 pixels**, for collection grids. No full-resolution master was replaced by a thumbnail.
- `asset_manifest.json`: the authoritative 44-species index, with repository-relative artwork paths, dimensions, file-byte SHA256 hashes, alpha bounds, normalized ruler endpoints, morphology notes, and biological fact references.
- `art_provenance.json`: every accepted artwork's full generation prompt, final master path and SHA256, available anatomical-edit prompt, anatomy-review record, and biological sources.
- `validation_report.json`: the original 572/572 technical-check results and the art authors' visual-review account. This records illustrative review, not independent scientific certification.

The production set contains exactly **132 PNGs**: 44 masters, 44 runtime copies, and 44 thumbnails. An additional **four superseded generation PNGs** are retained as historical evidence in `revision_history/`, for **136 PNGs in the whole archive**. They are explicitly excluded from runtime use. No user-uploaded reference image or temporary QA composite is included.

## Generation history and anatomy revisions

The batch records cover three disjoint groups: **18 special/initial species**, **13 European species**, and **13 coastal species**. Their manifests preserve original generation details, prompts, inspection results, and the final accepted artwork identities. `generation_prompts.json`, `batch_special_prompts.json`, and `coastal_prompts.json` retain source prompt collections, including earlier prompt wording where it differs from an accepted revision. The European prompts are retained in `batch_european_manifest.json`.

`revision_history.json` preserves four superseded originals with file-byte SHA256 hashes, original generation prompts, corrective prompts, final-artwork links, and explicit `superseded_not_for_runtime` status. Three originals came from the retained rejected-generation archive; the earlier Chinese sturgeon master was recovered byte-exactly from the preceding four-species source-control checkpoint and checked against that checkpoint's manifest. `plaice_regeneration_prompt.txt` also preserves the actual accepted regeneration prompt.

The recorded targeted corrections are:

- Chinese sturgeon: four visible short barbels before the ventral mouth; its initial preview predates this final revision.
- Yellowcheek: removal of an incorrect adipose-like fin.
- Southern catfish: correction of a maxillary barbel's attachment and course so it originates at the upper lip rather than the eye.
- European plaice: regeneration with the head facing right to preserve the natural right ocular-side anatomy. It was not pixel-mirrored. The accepted prompt and the earlier prompt remain separately documented.

All other fish face left. Flatfish are shown on their natural ocular side. `manual_endpoints.json` and the three batch endpoint files retain manually reviewed nose/tail coordinates in master pixels. Manifest normalized coordinates use the entire canvas, with right/bottom-exclusive bounding boxes; ruler lengths exclude whisker extensions.

## Provenance and privacy

These are newly AI-generated, photorealistic illustrative fish assets, **not wildlife photographs or diagnostic scientific plates**. The biological URLs document species facts and morphology; they do not license the generated images. No Creative Commons or public-domain status is asserted. The generation record states that no third-party fish photograph was downloaded or embedded.

The original generation and anatomical-edit prompts, accepted images, inspection records, biological references, and hashes are retained. Private preview identifiers, provider output hints, temporary transfer metadata, and machine-specific paths have been removed. Stable relative paths and SHA256 identities replace those incidental references. `batch_coastal_partial_metadata.json` is now a sanitized accepted-output index; complete coastal provenance remains in its batch manifest.

The historical visual reviews checked full-resolution images and composites against the game's paper color (`#edf0e4`). They support game illustration quality and should not be read as a guarantee of exact fin-ray counts, taxonomy, or anatomical accuracy.

## Verification and rebuilding

Run the **read-only** archive check from this directory:

```sh
python verify_backup.py
```

It requires Python 3.9+ and Pillow. It verifies the 44-species/132-production-PNG file set and four historical generation records, dimensions, RGBA transparency, all master/runtime/thumbnail hashes, byte-identical runtime copies, recorded alpha bounds and endpoints, all 572 historical technical checks, complete batch coverage, final prompt/revision/hash consistency, matching biological references, and sanitized structured metadata. It prints a JSON result and exits nonzero on a failed check. It does not modify artwork or metadata.

`build_asset_variants.py` is an optional **mutating rebuild** tool that uses the existing manifest's names, morphology, and fact references plus the preserved master images and manual endpoints. It requires Pillow and ImageMagick's `magick` command. It replaces runtime copies, regenerates thumbnails, and refreshes the asset manifest; it does not regenerate fish art. ImageMagick versions can encode derived thumbnails differently, so the checked-in thumbnail hashes remain authoritative for this backup. Use the read-only verifier when checking the archive rather than rebuilding it.

**Runtime binding warning:** rebuilding rewrites the authoritative `asset_manifest.json` bytes. Before any future runtime integration, regenerate and revalidate the `game/data/fish_art.json` source-manifest SHA256 binding through the documented artwork import audit. The frozen manifest was not rebuilt or reformatted during this archival cleanup.
