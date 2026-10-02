# Android export-path incident and safeguards

## Observed incident

On2026-10-02, the first game export used `gradle_build/gradle_build_directory="res://../tools/android-gradle"` to keep Android build outputs outside the project. During the official Godot4.6.3 Gradle export, `game/` source files disappeared and the exporter emitted file-open errors. The attempted APK was rejected. No package from that attempt was delivered.

The original production modules were recovered from the live Godot process, fish/scenery images were restored with matching hashes, remaining entry/audio/font resources were restored, and functional tests were rerun. The authoritative recovered checkpoint is the separately retained source archive plus its SHA256 recorded by the main task. Signing material was outside the project and unaffected.

## Source-level explanation

Official source reviewed:

- [Android exporter cleanup](https://github.com/godotengine/godot/blob/4.6.3-stable/platform/android/export/export_plugin.cpp#L3388-L3414)
- [Gradle directory construction](https://github.com/godotengine/godot/blob/4.6.3-stable/editor/export/export_template_manager.cpp#L778-L786)
- [Unix directory changes and resource-root handling](https://github.com/godotengine/godot/blob/4.6.3-stable/drivers/unix/dir_access_unix.cpp#L343-L385)
- [Directory access path/open implementation](https://github.com/godotengine/godot/blob/4.6.3-stable/core/io/dir_access.cpp)

The exporter appends `build/` to the configured Gradle directory, then recursively erases its APK and AAB asset directories before copying resources. These operations use resource-scoped directory access. The Unix implementation can revert a directory change that resolves outside the resource root to its previous directory while returning success. An out-of-project `res://../...` path therefore cannot safely be used for this cleanup flow. The observed deletion is consistent with cleanup operating at the resource root. This is a source-level diagnosis, not a claim that an upstream fix has been reviewed or released.

## Enforced replacement workflow

1. Archive the complete source tree outside the entire project, with a per-file SHA256 inventory; default sibling `farshore-fishing-checkpoints/`, configurable by `FARSHORE_BACKUP_DIR`. Reject any backup directory that resolves inside the project. Earlier internal snapshots are preserved as historical evidence
2. Copy source into a newly created disposable directory under `build/android-workspaces/`
3. Read the archive back and verify every file against the source inventory; record the archive SHA256. Compare the source inventory before/after copying and verify the copy matches; abort on concurrent changes
4. Extract the matching official Android source template under that copy's ordinary `android/build/`
5. Configure only `res://android`; reject parent traversals and any other Gradle directory value
6. Resolve both recursive-cleanup targets, asserting they are strictly inside the disposable copy, never inside the original source, and have no symlinked path components
7. Import/export only the disposable copy; never pass the primary `game/` as the export project
8. Fail on any exporter error, check original production-file hashes again, align/sign, and audit the final APK

The isolated minimal probe using the standard in-project directory built successfully and preserved its source hash. The subsequently staged full game export also left original production hashes unchanged.

## Recovery and distribution boundaries

- Source snapshots and final game deliverables contain no signing key or password
- Gradle intermediates and SDK/JDK installations are reproducible caches, not source deliverables
- A build success is not an emulator or phone runtime pass; those results are recorded separately
- Do not reintroduce an out-of-project `res://../` Gradle path, even if the target directory exists
