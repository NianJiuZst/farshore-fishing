# Angler source, licensing, and tool selection

The formal 1.2.0 angler is a derivative of the MakeHuman Community's CC0 human and system assets. It is not wholly original character geometry. Farshore authors the fitting, compact runtime bone mapping, closed hand pose, clothing adjustments, review stage, and fishing performances.

## Selected official source

- MPFB repository: https://github.com/makehumancommunity/mpfb2
- Inspected source commit: `afb9f530a7c2741dedb8df0ebae2e0b183caec21` (MPFB 2.0.17 source)
- Exact license statement: https://github.com/makehumancommunity/mpfb2/blob/afb9f530a7c2741dedb8df0ebae2e0b183caec21/LICENSE.md
- Full asset dedication: `ASSETS_3D_MAKEHUMAN_CC0.md`, copied from that commit's `LICENSE.ASSETS.md`
- Official system-pack inventory, including each selected asset's CC0 entry: https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html
- Download: https://files.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip
- Exact archive, original selected-file, base-mesh, and derivative SHA-256 values: `ASSETS_3D_ANGLER_PROVENANCE.json`

MPFB's code is GPL-3.0-or-later. Its license separately dedicates the base mesh, targets, textures, rigs, clothing data, and generated graphical output to CC0 1.0. The program code is used as an authoring tool only and is not bundled into the Android game or the repository. The repository redistributes selected graphical derivatives, packed texture data, and Farshore's own authoring scripts. CC0 permits their use, modification, commercial Android distribution, and public GitHub redistribution without requiring the game to adopt the tool's GPL license.

The selected system files also contain explicit September 2020 CC0 notices identifying Data Collection AB, Joel Palmius, and Jonas Hauquier as the rights holders at that release. Attribution is retained for traceability even though CC0 does not require it.

| Element | Selected CC0 asset |
| --- | --- |
| Human topology and shape targets | MPFB/MakeHuman `hm08` base mesh and bundled adult macro targets |
| Skin | `middleage_caucasian_male` |
| Eyes | `low-poly`, `brown` material / `brown_eye.png` |
| Eyebrows | `eyebrow001` |
| Hair | `short02` |
| Field jacket, shirt, jeans | `male_casualsuit05` |
| Outdoor shoes | `shoes02` |

Only shader-connected textures are exported. Godot’s configured import mode extracts those seven embedded images into tracked `game/assets/3d/angler_*.png` files, whose exact hashes are also recorded. The input inventory also records the original garment AO map, but this game-engine material does not connect or export that map. No downloaded reference photographs, whole asset pack, third-party program code, paid asset, new account, or API credential is committed.

## Alternatives examined

- MakeHuman/MPFB was selected because its official CC0 system library provides an anatomically modeled human, skin, eyes, clothes, shoes, and reusable rig weights in one compatible pipeline. MPFB directly works with the installed Blender 4.3.2. See https://static.makehumancommunity.org/mpfb/faq/why_use.html
- Blender Studio provides a realistic male base mesh under CC-BY, with a strong anatomical sculpting foundation. Its referenced download is a base mesh rather than this complete fitted and textured character pipeline, so it would require more clothing and rig work. It is a credible alternative if its attribution requirements are retained: https://studio.blender.org/training/realistic-human-research/use-of-base-meshes/
- MB-Lab is an open-source human generator, but its published license page assigns AGPL-3.0 to the model database and default generated 3D output. That is a different redistribution regime from the selected CC0 assets; it was not introduced into this project: https://mb-lab-docs.readthedocs.io/en/latest/license.html

These are distinctions between actual code and output licenses, not a claim that every asset found on a community website has the same license. Only the enumerated official CC0 assets are used here.

## Rebuilding the initial human source

The normal character build uses the committed `art_masters/3d/angler_human_source.blend` and needs Blender only. This source retains the adult shape keys, original MakeHuman rig/weights, garment fit, and all selected full-resolution packed textures.

For an optional rebuild from upstream:

1. Obtain the official MPFB repository at the exact commit above and the official asset archive above. Verify the archive and selected-file hashes against the provenance inventory.
2. Extract the system assets to an authoring directory outside the tracked repository.
3. Set `MPFB_SOURCE_DIR` to the repository root and `MAKEHUMAN_ASSET_DIR` to the extracted asset root. The preparation script checks the MPFB commit before enabling its code.
4. Run `XDG_CONFIG_HOME="$PWD/build/mpfb-config" blender --background --python tools/art3d/prepare_angler_human_source.py`.
5. Run the ordinary build described in `ASSETS_3D_ANGLER.md` and repeat the actual-pixel and imported-GLB checks.

The script's MPFB user/cache directory is isolated under `build/mpfb-authoring`. Packed images make the source and runtime independent of the original authoring machine's file paths. Rebuilds preserve geometry and animation behavior; binary Blender/glTF metadata can differ between rebuilds, so release hashes are recorded for the exact delivered files.
