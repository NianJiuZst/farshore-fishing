#!/usr/bin/env python3
"""Run real GDScript float encounters; Python only isolates and summarizes.

No captures, Android exports, source imports, or production saves. Every run
records input hashes before/after; concurrent production changes invalidate it.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import hashlib
import json
import os
from pathlib import Path
import statistics
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
INPUTS = [ROOT / "game/scripts" / f for f in
          ("float_encounter.gd", "fishing_session.gd", "encounter.gd", "catalog.gd", "fish_definition.gd")]
INPUTS += sorted((ROOT / "game/data").glob("fish_[abcdef].json"))
INPUTS += [ROOT / "game/data/world.json", ROOT / "game/tests/float_encounter_tests.gd",
           ROOT / "game/tests/fishing_test_controller.gd", Path(__file__)]


def hashes():
    return {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in INPUTS}


def percentile(values, fraction):
    if not values:
        return None
    values = sorted(values)
    pos = (len(values) - 1) * fraction
    index = int(pos)
    return round(values[index] + (values[min(index + 1, len(values) - 1)] - values[index]) * (pos - index), 4)


def describe(rows):
    hooks = [r for r in rows if r["hooked"]]
    catches = [r for r in rows if r["caught"]]
    tested = [r for r in rows if r["fight_tested"]]
    return {
        "runs": len(rows), "hooked": len(hooks), "hook_rate": round(len(hooks) / len(rows), 5),
        "fight_runs": sum(r["hooked"] for r in tested), "caught": len(catches),
        "catch_rate": round(len(catches) / len(tested), 5) if tested else None,
        "hook_to_catch_rate": round(len(catches) / len(hooks), 5) if tested and hooks else None,
        "strike_seconds_p50": percentile([r["strike_seconds"] for r in rows if r["strike_seconds"] >= 0], .5),
        "hook_latency_seconds_p50": percentile([r["hook_latency_seconds"] for r in hooks], .5),
        "hook_latency_seconds_p90": percentile([r["hook_latency_seconds"] for r in hooks], .9),
        "fight_seconds_p50": percentile([r["fight_seconds"] for r in catches], .5),
        "fight_seconds_p10": percentile([r["fight_seconds"] for r in catches], .1),
        "fight_seconds_p90": percentile([r["fight_seconds"] for r in catches], .9),
        "fight_seconds_max": max((r["fight_seconds"] for r in catches), default=None),
        "timeouts": sum(r["timeout"] for r in rows),
        "failures": dict(Counter(r["failure"] for r in rows if r["failure"])),
    }


def groups(rows, keys):
    found = defaultdict(list)
    for row in rows:
        found[tuple(row[k] for k in keys)].append(row)
    return [{**dict(zip(keys, key)), **describe(group)} for key, group in sorted(found.items(), key=lambda x: str(x[0]))]


def analyze(raw):
    rows, traces = raw["runs"], raw["traces"]
    for row in rows:
        row["size_group"] = "giant" if row["size"] > 0.88 else "non_giant"
    paired = defaultdict(list)
    for row in rows:
        paired[(row["species"], row["gear"], row["seed"], row["strategy"])].append(row)
    mismatch = [{"case": list(key), "outcomes": [{k: r[k] for k in ("fps", "hooked", "caught", "strike_seconds")} for r in values]}
                for key, values in paired.items() if len({r["hooked"] for r in values}) > 1]
    bins = defaultdict(Counter)
    takes = []
    shapes = Counter()
    signatures = Counter()
    intervals = []
    contact_pulses = []
    for trace in traces:
        for name, values in trace["amplitude_bins"].items(): bins[name].update(values)
        takes.extend(trace["takes"])
        contact_pulses.extend(trace.get("contact_pulses_above_0_20_seconds", []))
        signatures.update(t["signature"] for t in trace["takes"])
        phases = trace["transitions"]
        for before, after in zip(phases, phases[1:]):
            shapes[f'{before["phase"]}->{after["phase"]}'] += 1
        for take in trace["takes"]:
            if take["visible_at"] >= 0: intervals.append(take["end"] - take["visible_at"])
    return {
        "regressions": raw["regressions"], "seed_sweep": raw.get("seed_sweep", {}), "by_strategy": groups(rows, ["strategy"]),
        "by_frame_strategy": groups(rows, ["fps", "strategy"]),
        "by_species_strategy": groups(rows, ["species", "strategy"]),
        "by_gear_strategy": groups(rows, ["gear", "strategy"]),
        "by_weather_strategy": groups(rows, ["weather", "strategy"]),
        "by_size_strategy": groups(rows, ["size_group", "strategy"]),
        "frame_hook_disagreements": mismatch,
        "passive": {
            "traces": len(traces), "complete_departures": sum(t["departed"] for t in traces),
            "no_take_casts": sum(not t["takes"] for t in traces),
            "reject_revisit_casts": sum(t["rejections"] > 0 and t["attempts"] > 1 for t in traces),
            "take_count": len(takes), "signatures": dict(signatures), "transitions": dict(shapes),
            "first_take_seconds_p10": percentile([t["takes"][0]["start"] for t in traces if t["takes"]], .1),
            "first_take_seconds_p50": percentile([t["takes"][0]["start"] for t in traces if t["takes"]], .5),
            "first_take_seconds_p90": percentile([t["takes"][0]["start"] for t in traces if t["takes"]], .9),
            "visible_possession_seconds_p10": percentile(intervals, .1),
            "visible_possession_seconds_p50": percentile(intervals, .5),
            "minimum_visible_possession_seconds": min(intervals, default=None),
            "soft_take_peak_p50": percentile([t["peak"] for t in takes if t["signature"] == "soft"], .5),
            "soft_visible_possession_seconds_min": min((t["end"]-t["visible_at"] for t in takes if t["signature"] == "soft" and t["visible_at"] >= 0), default=None),
            "contact_pulse_seconds_p50": percentile(contact_pulses, .5),
            "contact_pulse_seconds_p90": percentile(contact_pulses, .9),
            "contact_pulse_seconds_max": max(contact_pulses, default=None),
            "strong_false_seconds_p50": percentile([t["strong_false_seconds"] for t in traces], .5),
            "max_vertical_step": max((t["max_vertical_step"] for t in traces), default=None),
            "max_tilt_step": max((t.get("max_tilt_step", 0) for t in traces), default=None),
            "max_drag": max((t.get("max_drag", 0) for t in traces), default=None),
            "max_drag_step": max((t.get("max_drag_step", 0) for t in traces), default=None),
            "max_contact_amplitude": max((t.get("phase_peaks", {}).get("contact", 0) for t in traces), default=None),
            "amplitude_vs_possession": {key: {**dict(value), "ready_fraction": round(value["ready"] / sum(value.values()), 5)} for key, value in bins.items()},
        },
        "visual_failures": [r for r in rows if r["strategy"] == "visual_reactive" and not r["hooked"]][:60],
    }


def acceptance(summary):
    """Gameplay criteria supplement invariants; a low skill win rate is failure."""
    rates = {r["strategy"]: r["hook_rate"] for r in summary["by_strategy"]}
    if not rates:
        return {"passed": not summary["regressions"]["failed"], "checks": []}
    oracle = rates.get("hidden_oracle", 0)
    visual = rates.get("visual_reactive", 0)
    blind = max((v for k, v in rates.items() if k.startswith("fixed_")), default=0)
    checks = [
        {"name": "visual reader reaches at least 95% of oracle-available takes", "passed": oracle > 0 and visual >= oracle * .95},
        {"name": "visual reader exceeds every fixed-time strike by 35 percentage points", "passed": visual - blind >= .35},
        {"name": "amplitude-only strike underperforms history reader by 15 percentage points", "passed": visual - rates.get("amplitude_only", 0) >= .15},
        {"name": "zero simulation timeouts", "passed": all(r["timeouts"] == 0 for r in summary["by_strategy"])},
    ]
    frame = {(r["fps"], r["strategy"]): r for r in summary["by_frame_strategy"]}
    for fps in sorted({k[0] for k in frame}):
        available = frame.get((fps, "hidden_oracle"), {}).get("hook_rate", 0)
        observed = frame.get((fps, "visual_reactive"), {}).get("hook_rate", 0)
        checks.append({"name": f"{fps}fps observation reaches 95% of available takes", "passed": available > 0 and observed >= available * .95})
    return {"passed": not summary["regressions"]["failed"] and all(c["passed"] for c in checks), "checks": checks}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--seeds", type=int, default=8)
    parser.add_argument("--quick", action="store_true")
    parser.add_argument("--skip-fights", action="store_true")
    parser.add_argument("--regressions-only", action="store_true")
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    before = hashes()
    (output / "before_sha256.json").write_text(json.dumps(before, indent=2) + "\n")
    with tempfile.TemporaryDirectory(prefix="farshore-float-qa-") as scratch:
        env = os.environ.copy()
        env.pop("DISPLAY", None)
        for key, leaf in (("HOME", "home"), ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"), ("XDG_CONFIG_HOME", "config"), ("XDG_RUNTIME_DIR", "runtime")):
            path = Path(scratch) / leaf
            path.mkdir(mode=0o700)
            env[key] = str(path)
        command = [os.environ.get("GODOT", "godot"), "--headless", "--audio-driver", "Dummy", "--path", str(ROOT / "game"), "--script", "res://tests/float_encounter_tests.gd", "--", "--output=" + str(output / "raw.json"), "--seeds=" + str(args.seeds)]
        for option in ("quick", "skip_fights", "regressions_only"):
            if getattr(args, option): command.append("--" + option.replace("_", "-"))
        started = time.monotonic()
        with (output / "godot.log").open("w") as stream:
            process = subprocess.run(command, cwd=ROOT, env=env, stdout=stream, stderr=subprocess.STDOUT, timeout=1200)
    after = hashes()
    (output / "after_sha256.json").write_text(json.dumps(after, indent=2) + "\n")
    status = {"exit_code": process.returncode, "elapsed_seconds": round(time.monotonic()-started, 2), "stable_inputs": before == after, "changed_inputs": [p for p in before if before[p] != after[p]], "command": command}
    (output / "status.json").write_text(json.dumps(status, indent=2) + "\n")
    print(json.dumps(status, indent=2))
    if (output / "raw.json").exists():
        summary = analyze(json.loads((output / "raw.json").read_text()))
        summary["acceptance"] = acceptance(summary)
        (output / "summary.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n")
        print(json.dumps({"regressions":summary["regressions"],"by_strategy":summary["by_strategy"],"passive":summary["passive"]}, indent=2, ensure_ascii=False))
    else:
        print((output / "godot.log").read_text()[-8000:])
    return 0 if process.returncode == 0 and before == after and (output / "raw.json").exists() and summary["acceptance"]["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
