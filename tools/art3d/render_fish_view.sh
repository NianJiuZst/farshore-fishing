#!/usr/bin/env bash
# Two bounded 2-thread render slots. Slot A is compatible with the original lock.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SPECIES="${1:?species ID required}"
VIEW="${2:?view or comma-separated views required}"
SAMPLES="${3:-32}"
cd "$ROOT"
while :; do
  for LOCK in /tmp/farshore-fish3d-render.lock /tmp/farshore-fish3d-render-b.lock; do
    (
      flock -n 9 || exit 75
      exec blender -t 2 -b --python-exit-code 1 --python tools/art3d/fish_pipeline.py -- --species "$SPECIES" --review-existing --views "$VIEW" --samples "$SAMPLES"
    ) 9>"$LOCK"
    STATUS=$?
    if [ "$STATUS" -ne 75 ]; then
      # Release both file descriptors before a brief handover window for queued peers.
      sleep 0.8
      exit "$STATUS"
    fi
  done
  sleep 0.4
done
