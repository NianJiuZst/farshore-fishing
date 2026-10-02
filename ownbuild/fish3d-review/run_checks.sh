#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
REVIEW="$ROOT/ownbuild/fish3d-review"
CHECK="$REVIEW/import_check"
blender -b --python "$REVIEW/verify_blender.py" > "$REVIEW/verify_blender.log" 2>&1
mkdir -p "$CHECK/config" "$CHECK/user-data" "$CHECK/cache"
cp game/assets/3d/common_carp.glb game/assets/3d/alligator_gar.glb "$CHECK/"
export XDG_CONFIG_HOME="$CHECK/config" XDG_DATA_HOME="$CHECK/user-data" XDG_CACHE_HOME="$CHECK/cache"
godot --headless --editor --path "$CHECK" --import --quit > "$CHECK/import.log" 2>&1
godot --headless --path "$CHECK" --script check.gd > "$REVIEW/godot_check.log" 2>&1
cp "$CHECK/godot_import_report.json" "$REVIEW/godot_import_report.json"
python - <<'PY'
import json
p='ownbuild/fish3d-review/godot_import_report.json'
r=json.load(open(p))
assert not r['failures'],r['failures']
print('PASS: Both fish, four clips, all bones, meshes, and loop seams verified')
PY
