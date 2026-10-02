# Android 1.2.0-beta.1 full-catalog 3D build

Preparation snapshot:2026-10-02 14:58 UTC. No1.2.0-beta.1 APK has been exported at this checkpoint. Final native-render review and an explicit source freeze are still required. The released1.1.0 APK and its evidence remain preserved.

## Intended package and scope

- Version1.2.0-beta.1, versionCode3; same `org.farshore.fishing` package and dedicated release signing identity
- ARM64 phone build and separate x86_64 emulator build; minimumAPI29, targetAPI36, VIBRATE-only permission list
- Native Godot4.6.3 Mobile renderer with Android Vulkan explicitly selected and automatic OpenGL fallback disabled
- Target acceptance device: the user's Snapdragon8 Elite Android16 phone. MinimumAPI29 is an OS installation floor, not a claim that every API29 GPU is suitable
- All44 catalog species require their own rigged model and four animations, as declared by `game/data/fish_3d.json`
- One fixed rigged angler, six regional environment GLBs, and three station GLBs support6 regions and12 fishing spots
- Five rods, eight baits, and31 generated PNG UI icons; inventories and exact data bytes are audited against the frozen source
- Native library compression stays disabled; this change does not undertake APK/art size reduction

## Export and provenance gates

`content_3d_contract.py` reads the authoritative3D registry and actual GLB JSON. All44 catalog IDs must match unique species-specific GLB paths and distinct geometry-buffer fingerprints. It requires skins, joint/weight attributes, bone-targeting sampled animations, five angler clips, four clips for every fish, and embedded GLB textures. Bone counts are measured, never fixed across species. Six region assets and three station assets are derived from the world data. The older unused managed-oxbow model may remain as legacy source; it does not replace any required regional asset.

The later environment-art integration adds Poly Haven CC0 planks and an HDR panorama. The contract includes HDR as well as PNG imports, checks each downloaded source against `ASSETS_3D_ENVIRONMENT_CC0.json`, and requires the exact `data/THIRD_PARTY_ART.txt` notice in the APK. The geometry/rigs remain project-built; the CC0 environment art is identified separately. Its provenance manifest is included in the authoring backup.

Before export, the pipeline creates separate external archives for the game source and for all44 fish Blender masters, the angler master, every current shared/profile authoring Python file, and asset-provenance documentation. Both archives are read back and checked against per-file SHA256 inventories. Export runs only in a disposable project with an ordinary in-project `res://android` directory. Original production-file hashes are checked again afterward.

After isolated import, `inspect_imported_3d.gd` loads all54 required actual PackedScenes and requires MeshInstance3D geometry, Skeleton3D, skinned meshes, AnimationPlayer, and the named nonempty clips where appropriate. The angler must retain exactly one RodSocket under a BoneAttachment3D. It records hashes of the imported scenes. The final APK audit verifies that those exact inspected scene bytes and their texture payloads are present, alongside environment metadata and shaders. This is structural/resource verification; rendered animation and Android behavior need runtime evidence.

`godot_binary_settings.py` decodes scalar settings from the final APK's `project.binary`, using Godot's ECFG format. The audit rejects a non-Mobile renderer, a different Android driver, or enabled OpenGL fallback. Godot may omit unchanged default settings; Android's pinned4.6.3 driver default is Vulkan. The explicit source configuration is checked before export. The actual runtime driver must still be recorded from engine logs.

Existing identity, permission, signature,16KiB ZIP/ELF, catalog/world JSON, fish-art, icon, and font audits remain active. The APK must contain the exact frozen3D registry; model/region/station counts are taken from that contract. Static16KiB alignment does not establish a16KiB runtime-device test.

## Runtime route

Run builds sequentially, finish Gradle, then start the retained persistent officialAPI36 x86_64 AVD separately. Its prior1.1.0 package installed successfully through `adb install --no-streaming`; it was not launched before the user's requested stop. No prior final-edition gameplay/save/update pass is implied.

This cloud host has no KVM and uses software TCG with ANGLE/SwiftShader. The AVD's installed image requires2560MiB RAM and6GiB data. Earlier Android SystemUI ANRs and package-service failures are recorded in the baseline evidence. An emulator Vulkan limitation must be reported as such; do not change the phone APK to Compatibility to make a test run. Record installation, actual renderer, rendering, inputs, pause/Back, offline behavior, and retained state only when observed. Physical ARM64/Snapdragon performance remains the user's device acceptance.

## References

- [Godot4.6 project settings and renderer fallback](https://docs.godotengine.org/en/4.6/classes/class_projectsettings.html)
- [Pinned ECFG serialization implementation](https://github.com/godotengine/godot/blob/4.6.3-stable/core/config/project_settings.cpp#L989-L1052)
- [Godot binary Variant encoding](https://github.com/godotengine/godot/blob/4.6.3-stable/core/io/marshalls.cpp)

## Disk and export order

Build ARM64 first, verify its signed APK and source/authoring archive hashes, then remove only that completed disposable workspace and regenerable Gradle intermediates before creating the x86_64 workspace. Preserve its snapshot manifest and audit reports. Do not keep two full ABI workspaces simultaneously. Source archives are external and hash verified; mutable source is never hardlinked into the export copy. Emulator testing starts only after Gradle stops. Source-release ZIP creation follows completed-export cleanup.

Current preparation probes found44 distinct fish geometry fingerprints,54 required scenes,45 rigged models,271 texture sources,45 editable masters, and48 authoring Python files. These are source/structure checks, not final APK or phone-rendering results.
