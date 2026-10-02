# Animated transparent 3D fish previews

`game/scripts/fish_preview_3d.gd` is a `SubViewportContainer` used for individual fish detail and catch pages. Set its layout/minimum size in the parent and call `set_species(species_id)` before or after adding it. The same species is idempotent; a changed species frees the previous instance before loading its unique registry GLB. Missing species emits `model_unavailable`, leaving an empty preview rather than substituting another fish.

It renders an actual weighted mesh and `AnimationPlayer` swim animation inside an isolated transparent `SubViewport` and `World3D`. A separate orthographic camera, ambient illumination and three directional studio lights reveal its volume; no ReflectionProbe or image cutout is used. A small automatic turn reveals form while keeping the silhouette readable. Flatfish receive an elevated camera so their ocular face can be examined. The control uses `MOUSE_FILTER_IGNORE` and the viewport disables GUI input, preserving page-owned touch scrolling. Only one model exists per preview at any time.

Validation on 2026-10-02: `tests/fish_preview_tests.gd` passed25/25 checks, including repeated replacements, exactly one model, unknown-species handling, active animation and touch ownership. `build/fish-preview/actual_preview.png` is an actual desktop Mobile/Vulkan render of the existing carp/gar meshes and was visually inspected. Its render log exited cleanly without ReflectionProbe warnings. This is not Android hardware performance certification.

Official API references: [SubViewport](https://docs.godotengine.org/en/4.6/classes/class_subviewport.html), [Environment](https://docs.godotengine.org/en/4.6/classes/class_environment.html).

`measurement_endpoints()` returns two global-canvas points by projecting the normalized model rest-length landmarks through the current pivot/camera. The ruler follows actual displayed model placement rather than the full transparent viewport width; animated bends do not rewrite the physical length stored on a catch.
