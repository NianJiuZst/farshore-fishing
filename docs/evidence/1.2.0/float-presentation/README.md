# Final float presentation evidence

`float_only_20fps_mobile_vulkan.mp4` is the approved float-only demonstration:450×990,20fps,542frames,27.1seconds. It is four segmented selected encounters, **not one continuous cast**. Each excerpt itself runs continuously with the real Main/Session/Stage and no forced float outputs. The observation camera and fishing button remain unchanged through the hidden encounter transitions. No labels were added to the movie.

| Time | Example |
|---|---|
|0.00–5.70s|Contact, lift take and return|
|5.70–10.85s|Contact, full submersion and return|
|10.85–19.40s|Contact, lateral travel and released load|
|19.40–27.10s|Brief contact followed by a smaller held displacement and return|

The soft sequence deliberately includes a contact peak around0.267 and a held load around0.24. Duration/continuity distinguishes them; maximum size alone does not. The final source model also permits rejection/revisiting and other outcomes covered by the separate gameplay matrix.

The720px stills show normal and19.8:9 framing, colored band exposure, full submersion, lateral travel, the manual guide, and a labeled construction inspection. The close construction view is an explicit inspection fixture, not the gameplay camera. Rain stills hold a real encounter snapshot and change stage weather only, isolating readability rather than rain balance.

`deliverable_manifest.json` contains movie SHA-256, dimensions and segment frames. `original_capture_evidence.json` preserves the complete original646-frame trace and the source hashes checked before/after capture. The excluded104-frame human tail is not part of this demonstration. It exposed a genuine fast-recast camera issue subsequently fixed in `_begin_cast`; before/after actualUI regression logs are included. Observation code and geometry were unchanged by that fix and the90-check observation suite passed again. The original stage hash therefore records the capture revision, not the later release stage.

Rendering is actual desktop Godot4.6.3 Mobile with Mesa lavapipe Vulkan. It is not Android hardware, phone FPS, thermal or touch-feel certification. The capture waits for the real512px NoiseTexture2D image, then for rendering to settle. The known seven-texture shutdown warning remains disclosed in the native log; the process exited0 and source hashes stayed unchanged.
