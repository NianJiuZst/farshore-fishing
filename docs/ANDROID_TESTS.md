# Android beta verification status

Evidence snapshot:2026-10-02 17:20 UTC. Target:1.2.0-beta.1/code3. Both the ARM64 phone APK and the separate x86_64 test APK are signed and pass the complete static audit. Runtime findings below concern the software x86_64 emulator; they do not establish physical Snapdragon8 Elite behavior.

| Check | Current beta result |
|---|---|
| Frozen runtime inputs | Same 1,044-file inventory as final desktop baseline/tall acceptance |
| Source registry and GLB contract | Passed:44 distinct fish,45 rigs,54 required scenes |
| Exact imported scene payloads | Passed:54/54 actual exported scenes match the structural Skeleton3D/AnimationPlayer/skin audit |
| Editable source/provenance |45 Blender masters and current generators protected in a fully reread exact-member/hash archive; game archive also fully reverified |
| Signed APK identity | Both ABIs:org.farshore.fishing,1.2.0-beta.1/code3,release/non-debuggable,min29/target36 |
| Permissions/signatures/alignment | Passed:VIBRATE only,expected certificate,v2/v3,16KiB ZIP and ELF alignment |
| Packaged rendering settings | Passed:Mobile/Vulkan,OpenGL fallback disabled,portrait expand,requested4×MSAA |
| Cross-ABI game-content equality | Passed:1,012 identical Godot asset files; only native code and Gradle-generated baseline profiles differ |
| Android16 guest | Official API36 x86_64 guest booted;4096-byte pages;software TCG,ANGLE/SwiftShader |
| Android16 beta installation/start/rendering | Blocked:streamed install timed out after240seconds;guest retained1.1.0/code2;beta was not launched |
| Android gameplay,touch/scroll,Back,pause/resume,offline play | Unverified:beta installation did not complete |
| Android saved-progress retention across update | Not yet verified |
| Physical ARM64/Snapdragon8 Elite performance/driver behavior | Not verified;no physical phone is attached |

## Evidence and boundaries

`evidence/1.2.0-beta.1/android/` contains both ABI manifests,badging,binary Android manifests,signature checks,16KiB alignment reports,exact imported-scene audits,and the cross-ABI asset-equality proof. `APK_BUILD_MANIFEST.json` identifies the downloadable ARM64 package; `APK_EMULATOR_BUILD_MANIFEST.json` identifies the test-only x86_64 package.

Desktop/headless/Vulkan QA is recorded separately in the parent release evidence. It is not substituted for Android-device testing. Static16KiB alignment does not establish a16KiB Android-device test:the actual x86_64 guest reports4096-byte pages.

The retained official API36 emulator required21 image files and399 emulator files to be restored from fully verified lossless archives. Its first launch stopped at the emulator's own disk preflight. A bounded hash-verified relocation of unused NDK files provided enough headroom;those files were restored during the subsequent install attempt to release tmpfs memory. No source,AVD userdata,or adb authentication data was deleted. The emulator ran after Gradle had stopped,with independent768MiB root,512MiB tmpfs,and1GiB available-memory floors.

The preceding1.1.0/code2 package was observed installed in the retained AVD before the beta update. That historical package had not been launched before the earlier stop,so an in-place upgrade alone cannot establish saved-game retention. Historical1.0.0 rendering/SystemUI ANR findings remain in `ANDROID_BASELINE_RUNTIME.md`;they do not validate this beta.

## Terminal Android16 runtime result

The unchanged persistent API36 guest completed boot in272,281ms under software TCG. It reported480×854 at213dpi and4,096-byte memory pages. Before update,the package manager confirmed1.1.0/code2. The first update request was rejected while Android was still booting;after boot completed,a streamed `adb install -r` of the573,412,957-byte signed beta timed out at240seconds. A subsequent package-manager read still reported1.1.0/code2. The beta was never launched.

Android's own `com.android.phone` process logged an ANR with99% total guest CPU usage,and the final screenshot visibly shows “System UI isn't responding” over the Android launcher. These are Android-system/software-emulation failures;there is no beta game-crash or beta-rendering result. The planned non-streaming fallback would require extra APK staging space beyond the remaining safe disk/RAM budget,so it was not attempted. No graphics-quality reduction was made.

The owned emulator was stopped cleanly with snapshots disabled. AVD userdata and authentication remain intact. Original verified SDK archives and temporarily parked NDK files were restored to their prior locations;SDK image/emulator binaries were returned to their lossless parked state without creating new archives. The signed ARM64 player APK and signed x86_64 test APK remain intact.

Evidence:`evidence/1.2.0-beta.1/android/runtime/summary.json`,the exact before/after package reads,the install timeout,Android-system ANR log,the labeled `system-ui-anr.png` frame,and resource-guard/storage-finalization records. Physical Android16/Snapdragon8 Elite installation,actual Vulkan rendering,input,save/update retention,and performance remain the next acceptance step.
