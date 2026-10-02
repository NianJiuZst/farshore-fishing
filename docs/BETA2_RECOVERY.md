# Beta.2 recovery checkpoint

On 2026-10-02 at about18:51UTC the cloud executor was replaced by an older workspace snapshot. The live checkout, local Git commits, recordings, local archives, toolchain additions and release-signing directory were absent afterward. This happened before the new gameplay APK or full source ZIP export began. A local archive outside a build directory protected against build cleanup but did not survive replacement of the entire executor.

The published private GitHub beta.1 commit c7b2b0b612908d85c9a161dfa66dc721de46b222 remains the baseline. Its1,922 tracked files were cloned again. Beta.2 changes are being reconstructed from the available authoring context and will be retested. Earlier observed test reports must not be represented as regenerated logs or as certification of reconstructed bytes unless their hashes match and that boundary is stated.

This is a durable work-in-progress source checkpoint, not a release or an Android runtime validation. No credentials or signing material are included. The original signing key is absent; a replacement identity or package change requires explicit authorization and cannot silently replace the installed game's identity.
