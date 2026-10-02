#!/usr/bin/env bash
# Build the native Godot Android application; release credentials never enter Godot/Gradle.
set -euo pipefail
umask 022
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
if [[ "${FARSHORE_BUILD_SPACE_GUARDED:-}" != 1 ]]; then
  exec python3 "$ROOT/tools/guard_android_build.py" "$@"
fi
ARCH="${1:-arm64}"
case "$ARCH" in
  arm64) PRESET='Android ARM64 Release'; ABI=arm64-v8a; SUFFIX=arm64 ;;
  x86_64) PRESET='Android Emulator x86_64 Release'; ABI=x86_64; SUFFIX=x86_64-test ;;
  *) echo 'Usage: tools/android_build.sh [arm64|x86_64] [output.apk]' >&2; exit 2 ;;
esac
VERSION="$(python3 - "$ROOT/game/project.godot" <<'PY'
from pathlib import Path
import re,sys
match=re.search(r'^config/version="([A-Za-z0-9._-]+)"$',Path(sys.argv[1]).read_text(),re.M)
assert match, 'A safe application version is required'
print(match.group(1))
PY
)"
OUTPUT="${2:-$ROOT/build/farshore-fishing-$VERSION-$SUFFIX.apk}"
[[ "$OUTPUT" = /* ]] || OUTPUT="$ROOT/$OUTPUT"
if [[ -z "${GODOT:-}" ]]; then
  if command -v godot >/dev/null 2>&1; then GODOT=godot
  else GODOT="$ROOT/tools/godot/Godot_v4.6.3-stable_linux.x86_64"; fi
fi
export GODOT
export JAVA_HOME="${JAVA_HOME:-$ROOT/tools/jdk/jdk-21.0.12.1+1}"
export ANDROID_HOME="${ANDROID_HOME:-$ROOT/tools/android-sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$ROOT/build/gradle-home}"
export XDG_CONFIG_HOME="$ROOT/build/env/config"
export XDG_DATA_HOME="$ROOT/build/env/data"
export XDG_CACHE_HOME="$ROOT/build/env/cache"
export ANDROID_USER_HOME="$ROOT/build/android-user"
export ANDROID_AVD_HOME="$ROOT/build/android-avd"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
SIGN_DIR="${FARSHORE_SIGNING_DIR:-$(dirname "$ROOT")/.signing-private/farshore-fishing}"
SIGN_KEY="${FARSHORE_KEYSTORE:-$SIGN_DIR/farshore-release.p12}"
SIGN_PASS_FILE="${FARSHORE_PASSWORD_FILE:-$SIGN_DIR/keystore-password.txt}"
SIGN_ALIAS="${FARSHORE_KEY_ALIAS:-farshore-release}"
BUILD_TOOLS="$ANDROID_HOME/build-tools/36.1.0"
for file in "$JAVA_HOME/bin/javac" "$BUILD_TOOLS/apksigner" "$BUILD_TOOLS/zipalign" "$BUILD_TOOLS/aapt" "$SIGN_KEY" "$SIGN_PASS_FILE"; do
  [[ -f "$file" ]] || { echo "Missing build prerequisite: $file" >&2; exit 3; }
done
[[ "$("$GODOT" --version 2>/dev/null)" == 4.6.3.stable.official.7d41c59c4 ]] || { echo 'Godot 4.6.3 official is required' >&2; exit 3; }
AUDIT="$ROOT/build/audit/$VERSION/$ARCH"
mkdir -p "$ROOT/build/logs" "$AUDIT" "$XDG_CONFIG_HOME/godot" "$XDG_DATA_HOME/godot/export_templates" "$XDG_CACHE_HOME" "$ANDROID_USER_HOME" "$GRADLE_USER_HOME" "$(dirname "$OUTPUT")"
export FARSHORE_ROOT="$ROOT" FARSHORE_EXISTING_KEY="$SIGN_KEY"
python3 "$ROOT/tools/prepare_android_environment.py"
PROJECT="$(python3 "$ROOT/tools/stage_android_project.py" "$ARCH")"
echo "Protected source snapshot created; exporting isolated project: $PROJECT"
# No --export-debug: the user has authorized one dedicated release identity only.
# Built-in signing is disabled in export_presets.cfg; signing occurs after final alignment.
UNSIGNED="$ROOT/build/farshore-$ARCH-unsigned.apk"
ALIGNED="$ROOT/build/farshore-$ARCH-aligned.apk"
"$GODOT" --headless --path "$PROJECT" --import >"$ROOT/build/logs/import-$ARCH.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|Parse Error:|Failed to load script' "$ROOT/build/logs/import-$ARCH.log"; then
  echo "Godot import failed; inspect build/logs/import-$ARCH.log" >&2; exit 4
fi
if [[ -f "$PROJECT/data/fish_3d.json" ]]; then
  "$GODOT" --headless --path "$PROJECT" --script "$ROOT/tools/inspect_imported_3d.gd" -- "$PROJECT.snapshot.json" "$AUDIT/imported-3d-scenes.json" >"$ROOT/build/logs/imported-3d-$ARCH.log" 2>&1
  if grep -Eq 'SCRIPT ERROR:|Parse Error:|Failed to load script|ERROR:' "$ROOT/build/logs/imported-3d-$ARCH.log"; then
    echo "Imported 3D structure audit failed; inspect build/logs/imported-3d-$ARCH.log" >&2; exit 4
  fi
  python3 "$ROOT/tools/content_3d_contract.py" "$PROJECT" "$AUDIT/imported-3d-scenes.json"
fi
"$GODOT" --headless --path "$PROJECT" --export-release "$PRESET" "$UNSIGNED" >"$ROOT/build/logs/export-$ARCH.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|Parse Error:|Failed to load script|Export failed|ERROR:' "$ROOT/build/logs/export-$ARCH.log"; then
  echo "Godot export reported errors; inspect build/logs/export-$ARCH.log" >&2; exit 4
fi
python3 - "$PROJECT" "$ROOT/game" <<'PY'
from pathlib import Path
import hashlib,json,sys
stage,source=Path(sys.argv[1]),Path(sys.argv[2])
origin=json.loads((stage.parent/(stage.name+'.snapshot.json')).read_text())
for rel,expected in origin['sha256'].items():
    if rel.startswith('tests/') or rel.endswith(('.import','.uid')):
        continue
    p=source/rel
    assert p.is_file(), f'Original source missing after staged export: {rel}'
    with p.open('rb') as f: got=hashlib.file_digest(f,'sha256').hexdigest()
    assert got==expected, f'Original source changed during export: {rel}'
if origin.get('authoring_backup'):
    for rel,expected in origin['authoring_backup']['sha256'].items():
        p=source.parent/rel
        with p.open('rb') as f: got=hashlib.file_digest(f,'sha256').hexdigest()
        assert got==expected, f'Original authoring file changed during export: {rel}'
print('Original production source hashes remain unchanged')
PY
python3 - "$PROJECT" "$ROOT/game" "$UNSIGNED" <<'PY'
from pathlib import Path
import shutil,sys,zipfile
stage,source,apk=map(Path,sys.argv[1:])
root=source.parent
assert stage.resolve().parent==(root/'build/android-workspaces').resolve()
assert not stage.is_symlink() and not stage.resolve().is_relative_to(source.resolve())
with zipfile.ZipFile(apk) as archive:
    assert 'AndroidManifest.xml' in archive.namelist() and 'assets/project.binary' in archive.namelist()
    assert archive.testzip() is None, 'Unsigned APK CRC validation failed'
# APK bytes and pre-export evidence are complete. Keep the source/imported scenes;
# remove only replaceable Gradle output and exported-asset copies before signing.
freed=0
for relative in ['android/build/build','android/build/src/main/assets','android/build/assetPackInstallTime/src/main/assets']:
    target=stage/relative
    if not target.exists(): continue
    assert target.resolve().is_relative_to(stage.resolve()) and not target.resolve().is_relative_to(source.resolve())
    for parent in [target,*target.parents]:
        if parent==stage.parent: break
        assert not parent.is_symlink()
    freed+=sum(p.stat().st_blocks*512 for p in target.rglob('*') if p.is_file())
    shutil.rmtree(target)
    target.mkdir(parents=True)
print('Cleared completed Gradle copies after APK CRC/source checks; allocated bytes:',freed)
PY
"$BUILD_TOOLS/zipalign" -P 16 -f 4 "$UNSIGNED" "$ALIGNED"
rm -- "$UNSIGNED"
"$BUILD_TOOLS/apksigner" sign --ks "$SIGN_KEY" --ks-key-alias "$SIGN_ALIAS" --ks-pass "file:$SIGN_PASS_FILE" --v1-signing-enabled false --v2-signing-enabled true --v3-signing-enabled true --v4-signing-enabled false --out "$OUTPUT" "$ALIGNED"
python3 "$ROOT/tools/verify_android_apk.py" "$OUTPUT" "$ABI" "$AUDIT" "$BUILD_TOOLS" "$PROJECT.snapshot.json"
cp "$PROJECT.snapshot.json" "$AUDIT/source-snapshot-manifest.json"
rm -- "$ALIGNED"
echo "Signed and verified: $OUTPUT"
sha256sum "$OUTPUT"
