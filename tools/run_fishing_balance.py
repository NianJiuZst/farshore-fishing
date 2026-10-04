#!/usr/bin/env python3
"""Execute the real seeded GDScript fishing model and summarize its outcomes.

Python only launches Godot and aggregates its JSON. It never simulates fishing.
The comprehensive grid is every legal species/gear route, min/mid/max individual,
16/30/60 Hz input sampling, and five strategies. A second randomized-seed sample
uses EncounterGenerator's unchanged size distribution. No rendering or export.
"""
from __future__ import annotations
import argparse
from collections import defaultdict, Counter
import hashlib
import json
import os
from pathlib import Path
import statistics
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
INPUTS = [ROOT / "game/scripts" / f for f in ("fishing_session.gd", "encounter.gd", "fish_definition.gd", "catalog.gd")]
INPUTS += sorted((ROOT / "game/data").glob("fish_[abcdef].json")) + [ROOT / "game/data/world.json", ROOT / "game/tests/fishing_balance_tests.gd", ROOT / "game/tests/fishing_test_controller.gd"]


def hashes():
    return {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in INPUTS}


def percentile(values, fraction):
    if not values:
        return None
    values = sorted(values)
    position = (len(values)-1)*fraction
    low = int(position)
    return round(values[low] + (values[min(low+1, len(values)-1)]-values[low])*(position-low), 3)


def summary(rows):
    caught = [r for r in rows if r["caught"]]
    durations = [r["fight_seconds"] for r in caught]
    return {"runs": len(rows), "caught": len(caught), "success_rate": round(len(caught)/len(rows), 5) if rows else None,
            "catch_seconds_p10": percentile(durations, .1), "catch_seconds_p50": percentile(durations, .5),
            "catch_seconds_p90": percentile(durations, .9), "catch_seconds_max": max(durations, default=None),
            "failures": dict(Counter(r["failure"] for r in rows if not r["caught"]))}


def grouped(rows, keys):
    groups = defaultdict(list)
    for row in rows:
        groups[tuple(row[k] for k in keys)].append(row)
    return [{**dict(zip(keys, key)), **summary(group)} for key, group in sorted(groups.items(), key=lambda x: str(x[0]))]


def analyze(raw):
    rows = raw["runs"]
    grid = [r for r in rows if r["sample"] == "boundary"]
    randomized = [r for r in rows if r["sample"] == "random"]
    frame_groups = defaultdict(list)
    for row in grid:
        frame_groups[(row["species"], row["gear"], row["size"], row["seed"], row["strategy"])].append(row)
    disagreements = []
    max_duration_spread = 0
    for key, values in frame_groups.items():
        if len({r["caught"] for r in values}) > 1:
            disagreements.append({"case": list(key), "outcomes": [{k: r[k] for k in ("fps", "caught", "fight_seconds", "failure")} for r in values]})
        elif values and values[0]["caught"]:
            max_duration_spread = max(max_duration_spread, max(r["fight_seconds"] for r in values)-min(r["fight_seconds"] for r in values))
    result = {"regressions": raw["regressions"], "scope": raw["scope"], "legal_routes": raw["legal_routes"], "float_cases": raw["float_cases"], "wear_cases": raw["wear_cases"],
              "overall": summary(rows), "by_strategy": grouped(rows, ["strategy"]), "by_frame_strategy": grouped(grid, ["fps", "strategy"]),
              "by_size_strategy": grouped(grid, ["size", "strategy"]), "by_gear_strategy": grouped(grid, ["gear", "strategy"]),
              "by_species_strategy": grouped(rows, ["species", "strategy"]), "by_behavior_strategy": grouped(rows, ["behavior", "strategy"]), "randomized": grouped(randomized, ["strategy"]),
              "frame_outcome_disagreements": disagreements, "frame_max_success_duration_spread_seconds": round(max_duration_spread, 4),
              "reactive_failures": [r for r in rows if r["strategy"] == "behavior_aware" and not r["caught"]][:40]}
    rates = {r["strategy"]: r["success_rate"] for r in result["by_strategy"]}
    checks = []
    def check(ok, label): checks.append({"passed": bool(ok), "label": label})
    check(len({r["species"] for r in rows}) == 74, "all 74 species simulated")
    check(rates.get("behavior_aware", 0) >= .95, "observable reactive strategy wins at least 95%")
    check(not any(r["warning_time"] >= 0 for r in rows if r["strategy"] == "behavior_aware"), "active reactive fights never receive premature wear warning")
    check(rates.get("never_pull", 1) == 0, "never pulling cannot catch")
    check(rates.get("always_pull", 1) < rates.get("behavior_aware", 0)-.35, "always pulling at least 35 percentage points worse than reactive")
    check(rates.get("metronome", 1) < rates.get("behavior_aware", 0)-.20, "blind metronome at least 20 percentage points worse than reactive")
    reactive_grid = [r for r in grid if r["strategy"] == "behavior_aware"]
    pairs = defaultdict(dict)
    for row in reactive_grid: pairs[(row["species"], row["gear"], row["seed"], row["fps"])][row["size"]] = row
    ratios = [p["max"]["fight_seconds"]/p["min"]["fight_seconds"] for p in pairs.values() if p.get("max", {}).get("caught") and p.get("min", {}).get("caught")]
    check(bool(ratios) and statistics.median(ratios) >= 2, "median within-species max/min fight duration ratio at least 2")
    if {r["fps"] for r in grid} == {16, 30, 60}:
        check(not [d for d in disagreements if d["case"][-1] == "behavior_aware"], "reactive outcome invariant at 16/30/60 fps")
    giant_hold = [r for r in grid if r["size"] == "max" and r["strategy"] == "always_pull"]
    check(bool(giant_hold) and not any(r["caught"] for r in giant_hold), "continuous hard pull cannot land maximum-size giants")
    spreads = defaultdict(list)
    for key, values in frame_groups.items():
        if values and all(r["caught"] for r in values):
            spreads[key[-1]].append(max(r["fight_seconds"] for r in values)-min(r["fight_seconds"] for r in values))
    result["frame_success_duration_spread_by_strategy"] = {k: {"p50": percentile(v, .5), "p90": percentile(v, .9), "max": round(max(v), 3)} for k, v in spreads.items()}
    result["failure_examples"] = {strategy: [r for r in rows if r["strategy"] == strategy and not r["caught"]][:5] for strategy in rates}
    result["balance_checks"] = checks
    result["giant_small_duration_ratio_p50"] = percentile(ratios, .5)
    middle_ratios = [p["max"]["fight_seconds"]/p["mid"]["fight_seconds"] for p in pairs.values() if p.get("max", {}).get("caught") and p.get("mid", {}).get("caught")]
    result["giant_mid_duration_ratio_p50"] = percentile(middle_ratios, .5)
    wear = raw["wear_cases"]
    result["stale_wear_summary"] = {"runs": len(wear), "warning_seconds_p10": percentile([r["warning_at"] for r in wear if r["warning_at"] >= 0], .1), "warning_seconds_p50": percentile([r["warning_at"] for r in wear if r["warning_at"] >= 0], .5), "warning_seconds_p90": percentile([r["warning_at"] for r in wear if r["warning_at"] >= 0], .9), "earliest_break_warning_lead": min((r["warning_lead"] for r in wear if r["wear_break"]), default=None), "break_within_30s_after_warning": sum(r["wear_break"] and r["warning_lead"] <= 30 for r in wear), "note": "Observed seeded sample, not an estimated population probability; indefinite stalling accumulates risk."}
    result["passed"] = all(c["passed"] for c in checks) and not raw["regressions"]["failed"]
    return result


def markdown(report):
    lines = ["# Fishing skill balance evidence", "", "Actual production GDScript, seeded RNG, isolated save environment. Python only aggregates results.", "",
             "Scope: " + report["scope"], "", "## Strategy outcomes", "", "| Strategy | Runs | Catch rate | Catch duration p10 / p50 / p90 (s) |", "|---|---:|---:|---:|"]
    for r in report["by_strategy"]:
        lines.append(f'| {r["strategy"]} | {r["runs"]} | {100*r["success_rate"]:.1f}% | {r["catch_seconds_p10"]} / {r["catch_seconds_p50"]} / {r["catch_seconds_p90"]} |')
    lines += ["", "## Regression and balance gates", ""]
    for check in report["balance_checks"]: lines.append(f'- {"PASS" if check["passed"] else "FAIL"}: {check["label"]}')
    lines += [f'- Regression assertions: {report["regressions"]["checks"]-len(report["regressions"]["failed"])}/{report["regressions"]["checks"]}',
              f'- Frame-rate outcome disagreements: {len(report["frame_outcome_disagreements"])}',
              f'- Maximum successful-duration spread across frames: {report["frame_max_success_duration_spread_seconds"]} s',
              f'- Median same-species, same-gear maximum/minimum size duration ratio: {report["giant_small_duration_ratio_p50"]}',
              f'- Median same-species, same-gear maximum/middle size duration ratio: {report["giant_mid_duration_ratio_p50"]}',
              f'- Visual-only hook trials: {sum(r["hooked_from_float"] for r in report["float_cases"])}/{len(report["float_cases"])}',
              f'- Organic stale-wear trials: {report["stale_wear_summary"]}',  "", "## Interpretation and limits", "",
              "The fight matrix deliberately hooks correctly before comparing fight policies, so blind-policy failure is not inflated by early strikes. Separate regressions exercise early/late strikes and held input. Boundary fixtures take a real generated record and deterministically select catalog min/mid/max sizes; random samples retain production EncounterGenerator sampling. All equipment combinations have a verified candidate route through the actual encounter filter. The reactive policy samples visible cues at15Hz and queues responses for170ms (about170–267ms total with frame quantization). Windup detection waits for visible warning amplitude0.15; active surge detection waits for amplitude0.08. The reactive policy reads only player-observable fight phase/tension; it cannot read the next phase, RNG, stamina target, or wear roll. Stamina, wear and RNG may be recorded for diagnostics but never drive that policy.",
              "", "These are mechanics/control checks. They do not certify rendered visibility, Android behavior, localization legibility, or save settlement integration. Those require the separate integration and visual suites.", ""]
    if report["regressions"]["failed"]: lines += ["## Failed regressions", *["- "+s for s in report["regressions"]["failed"]], ""]
    if report["reactive_failures"]: lines += ["## Representative reactive failures", "", "```json", json.dumps(report["reactive_failures"][:10], ensure_ascii=False, indent=2), "```", ""]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True, help="New evidence directory (prefer /tmp during iteration)")
    parser.add_argument("--quick", action="store_true", help="One grid seed, 30 fps only; explicitly narrowed scope")
    parser.add_argument("--regressions-only", action="store_true")
    parser.add_argument("--timeout", type=int, default=1200)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    before = hashes()
    started = time.monotonic()
    with tempfile.TemporaryDirectory(prefix="farshore-balance-") as temp:
        env = os.environ.copy()
        env.pop("DISPLAY", None)
        for key, leaf in [("HOME", "home"), ("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"), ("XDG_CONFIG_HOME", "config")]:
            path = Path(temp) / leaf
            path.mkdir()
            env[key] = str(path)
        command = [os.environ.get("GODOT", "godot"), "--headless", "--audio-driver", "Dummy", "--path", str(ROOT / "game"), "--script", "res://tests/fishing_balance_tests.gd", "--", "--output="+str(output / "raw.json")]
        if args.quick: command += ["--quick"]
        if args.regressions_only: command += ["--regressions-only"]
        with (output / "godot.log").open("w") as stream:
            stream.write("COMMAND: "+" ".join(command)+"\n"); stream.flush()
            try: code = subprocess.run(command, cwd=ROOT, env=env, stdout=stream, stderr=subprocess.STDOUT, timeout=args.timeout).returncode
            except subprocess.TimeoutExpired: code = 124
    log = (output / "godot.log").read_text()
    errors = [line for line in log.splitlines() if "SCRIPT ERROR:" in line or line.startswith("ERROR:")]
    if (output / "raw.json").exists():
        raw = json.loads((output / "raw.json").read_text())
        report = analyze(raw) if raw["runs"] else {"passed": not raw["regressions"]["failed"], **raw}
    else: report = {"passed": False, "blocker": "Godot did not produce results"}
    after = hashes()
    changed = [p for p in before if before[p] != after[p]]
    report.update({"exit_code": code, "engine_errors": errors, "seconds": round(time.monotonic()-started, 2), "source_sha256": before, "source_changes_during_run": changed})
    report["passed"] = report["passed"] and code == 0 and not errors and not changed
    (output / "summary.json").write_text(json.dumps(report, ensure_ascii=False, indent=2)+"\n")
    if "by_strategy" in report: (output / "summary.md").write_text(markdown(report))
    print(json.dumps({"passed": report["passed"], "seconds": report["seconds"], "summary": str(output / "summary.json"), "engine_errors": errors, "source_changes_during_run": changed}, ensure_ascii=False))
    if "by_strategy" in report: print(json.dumps(report["by_strategy"], ensure_ascii=False))
    return 0 if report["passed"] else 1

if __name__ == "__main__": raise SystemExit(main())
