# 1.2.0 independent visual review

Reviewed 2026-10-03. **Pass within the inspected desktop-render scope.** No remaining blocking float-readability, character-rendering, or quick-recast framing defect was found in the accepted evidence below. This is not Android-phone certification.

## Evidence and method

The review inspected actual image pixels, not only geometry or test counts:

- Studio character front, side, cast, release, fight, lift and close grip views in [the angler evidence](evidence/1.2.0/angler/), including 450px-wide inspection copies
- Real Main/Session/Stage stills at 720×1280 and 720×1584, plus original 450×990 movie frames
- All four float sequences at their original pixel scale, using full-screen key frames, 0.2-second sequential samples, and every 0.05-second frame around the soft contact and release recovery. The retained [soft sequence](evidence/1.2.0/visual-review/soft-1to1-5fps.png), [contact boundary](evidence/1.2.0/visual-review/soft-contact-20fps.png), and [return boundary](evidence/1.2.0/visual-review/soft-return-20fps.png) are 1:1 inspection crops, not modified gameplay cameras. Their provenance is in the [inspection manifest](evidence/1.2.0/visual-review/inspection_manifest.json)
- The rendered manual and rain-lighting snapshot, checked against [the research specification](FLOAT_BITE_RESEARCH.md), current source, and [the separate gameplay validation](FLOAT_ENCOUNTER_VALIDATION.md)

Captures use Godot 4.6.3 Mobile rendering with Mesa software Vulkan. The simulation advances at 120Hz and the movies sample at 20fps. The review did not measure real phone frame rate or operate a physical touchscreen.

## Float verdict

The final antenna has sufficient width and contrast to follow at the actual 450px movie width. It reads as one continuous colored object; the red tip and alternating markings remain distinct against the rendered water. This conclusion follows the widened native render, not merely the approximately 53px antenna-height projection at 720px width. The earlier approximately 2px-wide presentation at 450px was rejected as too fragile for comfortable band reading.

The accepted [float movie](evidence/1.2.0/float-presentation/float_only_20fps_mobile_vulkan.mp4) contains four separate, continuous examples with cuts between them:

| Movie interval | Observed result |
| --- | --- |
| 0.00–5.70s | Brief contact recovers; a developed lift exposes lower markings and the body, then returns |
| 5.70–10.85s | Contact recovers; progressive immersion removes the entire visible tip, followed by reappearance |
| 10.85–19.40s | Directed travel develops coherently while exposed length changes; the view stays fixed |
| 19.40–27.10s | Several short contacts recover; a smaller held displacement stays at a changed exposure while drifting, then recovers |

In the soft example, the contact peak is slightly greater than the held load. The visible distinction is the short recovery versus sustained displacement, not maximum movement size. The adjacent 20fps frames show a smooth response and return, without a teleport or random alternating jump. Normal wave motion is smaller and does not repeatedly cover the same number of markings as the held take.

The fishing button and observation view do not announce a hidden take. The [rain snapshot](evidence/1.2.0/float-presentation/soft_rain_lighting_720x1584.png) retains a readable red/yellow tip against the stronger water texture. The [construction inspection](evidence/1.2.0/float-presentation/float_construction_inspection_720x1280.png) shows the body, keel and fittings, but is explicitly a close inspection fixture and is not evidence of the gameplay camera.

## Character and recast verdict

The accepted [native lobby](evidence/1.2.0/angler/native-lobby.png) shows a coherent face, hair, jacket, shirt, jeans and shoes. The character has natural human proportions and recognizable cloth surfaces rather than the previous rounded mannequin silhouette. The removed floating cap, corrected lower-hand cuff, and repaired knee breakthrough are resolved in the reviewed version. Extreme studio close-ups still reveal some finger/wrist faceting; it was not a blocking defect at the inspected gameplay scale.

The corrected [quick-cast loading](evidence/1.2.0/fast-recast-native/human_cast_loading_720x1280.png) and [release](evidence/1.2.0/fast-recast-native/human_cast_release_720x1280.png) show the complete angler after an actual failure dismissal and only 50ms of charge. Original 450×990 frames also preserve this framing. The [lift](evidence/1.2.0/fast-recast-native/human_lift_720x1280.png) retains intact back, hair, arms and clothing.

Reel/fight and late landing views mainly frame rod, water and fish. The visible character portions have no new defect, but those views do not support a full-body anatomical claim. The [short recast/reel movie](evidence/1.2.0/fast-recast-native/quick_recast_and_reel_20fps_mobile_vulkan.mp4) is two excerpts, not uninterrupted play from casting to landing.

## Blocking findings resolved during review

1. The first native human had interior face colors, missing-looking hair and garment holes even though geometry tests passed. All six materials had exported as transparent BLEND. Solid body/clothing/shoes now use OPAQUE and hair/brows/eyes use cutout materials; corrected native pixels confirm the corruption is gone.
2. Early water captures preceded asynchronous normal-map readiness, while overlapping transparent float parts obscured lower paint bands. The capture now waits for the actual generated texture; the float uses opaque paint with depth attenuation/discard and non-overlapping bands. Full immersion disappears rather than leaving a ghost silhouette.
3. The initial corrected stem was still too narrow at 450px. A modest physical widening makes its markings readable without changing the observation camera.
4. The original combined capture exposed a real immediate-recast camera defect. Commit `82f7675` establishes the authored wind-up camera at the explicit cast action. The corrected native recast above and 12/12 actual-flow projection checks verify the repair; observation-camera checks remain 90/90.

## Instructions, provenance and limits

The [rendered guide](evidence/1.2.0/float-presentation/float_guide_top_720x1280.png) is legible and consistent with the observed examples: watch exposure and direction relative to water, recognize recovery, allow a small held take, and do not wait for full submersion or a fixed number of seconds. It discloses simplified tackle and that no single motion guarantees a catch. It does not promise that residual displacement after release remains hookable.

The float movie SHA-256 is `9ea62f787aa87b4aa44ccc7b0b9b4e3628daca9ee4d7d0ed3164a0afd282ab2d`. Its [manifest](evidence/1.2.0/float-presentation/deliverable_manifest.json) preserves the original capture revision and eight stable source hashes. It predates the narrowly scoped recast-camera reset; that change did not alter observation geometry, shaders, motion or WAIT/NIBBLE/BITE framing. The invalid original 104-frame human tail is excluded.

The corrected human movie SHA-256 is `7c1abfd2f377c85799d3398285fb62bfec34b3ed8d5c0034080e6539e2975e2a`. Its [evidence](evidence/1.2.0/fast-recast-native/evidence.json) reports unchanged sources, and all eight hashes were independently matched to the reviewed current files. These include character GLB `5234a26c…ecd7` and stage `0ec2a6b9…e9f8`.

Coverage is selected common-carp encounters at the lake, not a visual census of all species and locations. Rain images isolate stage-weather readability; they are not full rainy-encounter motion tests. Audio was disabled in the capture. Real-phone performance, heat, battery, touch feel and human success rates remain outside this visual review. Native logs also disclose the existing seven-texture shutdown warning; successful exit and stable hashes are not described as a warning-free run.
