# Adaptive mobile layout and native4x MSAA

The production project now uses `canvas_items` with `stretch/aspect="expand"`, retaining the720×1280 baseline while filling a representative720×1584 (19.8:9) window without letterboxing. No device model is inferred or certified.

The stage preserves the original16:9 horizontal scene coverage. Its authored vertical-FOV transition is still blended exactly as before, then converted to an equivalent horizontal FOV at720/1280 and applied with Camera3D.KEEP_WIDTH. The720×1280 projection is unchanged; taller displays gain vertical space rather than cropping large fish horizontally. Camera timing, targets, fish sizes, tackle, mechanics, rewards and save code are unchanged.

`rendering/anti_aliasing/quality/msaa_3d=2` enables native4x MSAA on the actual main viewport. The existing separate fish previews retain4x MSAA. No resolution reduction or extra postprocessing was added.

## Verification contract

- `camera_aspect_tests.gd`:531 projection/configuration checks cover all seven authored FOVs and120 transition samples at720×1280,720×1584,1440×3168 and900×1200
- `slice3d_tests.gd -- --tall`: actual44-fish/12-spot gameplay, live main MSAA setting, expanded logical viewport, width-preserving camera and each species' minimum/maximum landing framing
- `ui_style_tests.gd -- --tall`: all pages,96-unit touch targets, captions, Back/zoom/result paths and synthetic104px-top/80px-bottom inset stress
- `touch_scroll_tests.gd -- --production --require-full --tall`: real Viewport touch/drag, all long-page scrolling and final action reachability; a taller Settings page that genuinely fits is checked for visible final action instead of being forced to scroll
- Omit `--tall` to retain and rerun the baseline720×1280 checks

Synthetic insets test layout behavior only. They are not values returned by a real Android DisplayServer or proof of hardware cutout handling. Desktop llvmpipe rendering does not certify Android16, a particular phone or Snapdragon performance.

## Reproducible actual Main screenshots

Use `tools/capture_full44_main.gd` through `tools/render_godot.py` with a fresh absolute `--output=` directory. `--tall` selects720×1584. `--first-run` captures a genuine empty-save lake lobby with default starter gear, no seeded unlocks/catches and an enabled Start. Without it, the harness seeds only Norway/rod ownership, then generates, fights, lands and disposes a normal Atlantic-cod encounter to capture four actual Main frames.

The image manifest records physical/logical sizes, actual renderer/MSAA, strict44 readiness, ordinary recipe, catch and runtime hashes. Existing evidence directories are never overwritten. This is reproducible production UI evidence, never a fake scene, readiness override or a claim about a user's own catch.

Final frozen pass counts and renderer caveats belong in `3D_ACCEPTANCE.md`; development runs are not substituted for the final hash-bound gate.

Focused expanded-layout checkpoint: both physical/logical sizes pass native-scene full44 minimum/maximum framing and UI safe-inset checks. The touch fixture was corrected after measuring that the baseline carp detail has196px overflow while the taller page fits entirely (0px overflow). Baseline still requires the original overflowing drag; the tall case requires all content visible and proves TouchScroll recognized the real drag without the3D preview intercepting it. Focused touch results are132/132 baseline and130/130 tall. These focused results do not replace the final frozen aggregate.
