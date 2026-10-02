# Android 1.2 two-fish 3D trial

Preparation snapshot:2026-10-02 11:58 UTC. No1.2.0 APK has been exported at this checkpoint; final artwork, native-render review, and source freeze are required first. The released1.1.0 APK and its evidence remain preserved.

## Intended package and scope

- Version1.2.0, versionCode3; same `org.farshore.fishing` package and dedicated release signing identity
- ARM64 phone build and separate x86_64 emulator build; minimumAPI29, targetAPI36, VIBRATE-only permission list
- Native Godot4.6.3 Mobile renderer with Android Vulkan explicitly selected and automatic OpenGL fallback disabled
- Target acceptance device: the user's Snapdragon8 Elite Android16 phone. MinimumAPI29 is an OS installation floor, not a claim that every API29 GPU is suitable
- One fixed rigged angler, two playable rigged fish (`common_carp`, `alligator_gar`), and one3D trial location
- The44-entry legacy catalog,6 regions, and12 old spots remain data; they are not44 converted3D fish or12 playable3D locations
- Native library compression stays disabled; this change does not undertake APK/art size reduction

## Export and provenance gates

`content_3d_contract.py` reads the authoritative trial adapter and actual GLB JSON. It requires skins, joint/weight attributes, bone-targeting sampled animations, the five angler clips, the four clips for each fish, and embedded GLB textures. It records the environment GLB, exported texture sources, and all3D shader hashes.

The later environment-art integration adds Poly Haven CC0 planks and an HDR panorama. The contract includes HDR as well as PNG imports, checks each downloaded source against `ASSETS_3D_ENVIRONMENT_CC0.json`, and requires the exact `data/THIRD_PARTY_ART.txt` notice in the APK. The geometry/rigs remain project-built; the CC0 environment art is identified separately. Its provenance manifest is included in the authoring backup.

Before export, the pipeline creates separate external archives for the game source and for the three editable Blender masters plus generator/asset-documentation files. Both archives are read back and checked against per-file SHA256 inventories. Export runs only in a disposable project with an ordinary in-project `res://android` directory. Original production-file hashes are checked again afterward.

After isolated import, `inspect_imported_3d.gd` loads the four actual PackedScenes and requires MeshInstance3D geometry, Skeleton3D, skinned meshes, AnimationPlayer, and the named nonempty clips where appropriate. It records hashes of the imported scenes. The final APK audit verifies that those exact inspected scene bytes and their texture payloads are present, alongside environment metadata and shaders. This is structural/resource verification; rendered animation and Android behavior need runtime evidence.

`godot_binary_settings.py` decodes scalar settings from the final APK's `project.binary`, using Godot's ECFG format. The audit rejects a non-Mobile renderer, a different Android driver, or enabled OpenGL fallback. Godot may omit unchanged default settings; Android's pinned4.6.3 driver default is Vulkan. The explicit source configuration is checked before export. The actual runtime driver must still be recorded from engine logs.

Existing identity, permission, signature,16KiB ZIP/ELF, legacy-data, fish-art, icon, and font audits remain active. Static16KiB alignment does not establish a16KiB runtime-device test.

## Runtime route

Run builds sequentially, finish Gradle, then start the retained persistent officialAPI36 x86_64 AVD separately. Its prior1.1.0 package installed successfully through `adb install --no-streaming`; it was not launched before the user's requested stop. No prior final-edition gameplay/save/update pass is implied.

This cloud host has no KVM and uses software TCG with ANGLE/SwiftShader. The AVD's installed image requires2560MiB RAM and6GiB data. Earlier Android SystemUI ANRs and package-service failures are recorded in the baseline evidence. An emulator Vulkan limitation must be reported as such; do not change the phone APK to Compatibility to make a test run. Record installation, actual renderer, rendering, inputs, pause/Back, offline behavior, and retained state only when observed. Physical ARM64/Snapdragon performance remains the user's device acceptance.

## References

- [Godot4.6 project settings and renderer fallback](https://docs.godotengine.org/en/4.6/classes/class_projectsettings.html)
- [Pinned ECFG serialization implementation](https://github.com/godotengine/godot/blob/4.6.3-stable/core/config/project_settings.cpp#L989-L1052)
- [Godot binary Variant encoding](https://github.com/godotengine/godot/blob/4.6.3-stable/core/io/marshalls.cpp)
