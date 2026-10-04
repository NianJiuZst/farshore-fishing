#!/usr/bin/env python3
"""Accept a complete stable 1.4 run plus two precisely scoped harness repairs.

Original failures are retained. All production resources and every other test
must remain byte-identical; only the known 74-to-110 float-save harness may differ.
This is local source acceptance, not Android, signing or publication evidence.
"""
from __future__ import annotations

if not __debug__:
    raise RuntimeError('Unoptimized Python is required for acceptance assertions')

import argparse
import datetime
import hashlib
import json
from pathlib import Path
import subprocess

from run_full_catalog_qa import ROOT, SUITES, manifest

BASELINE = '7b406cccaf57c9ca213693f75860443a118ed656'
TEST = 'game/tests/ocean_float_save_tests.gd'


def read(path: Path) -> dict:
    return json.loads(path.read_text())


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def expanded_float_save_source(original: str) -> str:
    edits = [
        ('catalog.baits.size() == 12 and catalog.fish.size() == 74, "matrix contains twelve baits and seventy-four species"',
         'catalog.baits.size() == 12 and catalog.fish.size() == 111 and catalog.fish_species_count() == 110, "matrix contains twelve baits,110 fish and one excluded mammal"'),
        ('\tvar normal_max: int = int(fish.raw["normal_max_mm"])\n',
         '\tvar normal_max: int = int(fish.raw["normal_max_mm"])\n\tvar gear_id: int = 5 if float(fish.raw.get("depth_min_m",0.0)) > float(catalog.gear[4].get("max_depth_m",180.0)) else 4\n'),
        ('make_individual(fish,spot_id,region_id,bait_id,4,"day","clear")',
         'make_individual(fish,spot_id,region_id,bait_id,gear_id,"day","clear")'),
        ('\t\tfor fish: FishDefinition in catalog.fish.values():\n',
         '\t\tfor fish: FishDefinition in catalog.fish.values():\n\t\t\tif not catalog.is_fishing_species(fish): continue\n'),
        ('matrix_index == 888 and records_saved == 2664',
         'matrix_index == 1320 and records_saved == 3960'),
        ('all twelve baits by seventy-four species by three size classes persisted and reloaded twice',
         'all twelve baits by110 fish by three size classes persisted and reloaded twice; whale excluded'),
    ]
    for before, after in edits:
        assert original.count(before) == 1, 'Ambiguous or missing legacy harness substitution'
        original = original.replace(before, after)
    return original


def verify_rerun(folder: Path, names: list[str], inputs: dict[str, str]) -> dict:
    result = read(folder / 'summary.json')
    assert result['passed'] is True and result['runtime_unchanged'] is True
    assert result['runtime_changes'] == [] and result['source_changes_during_import'] == []
    assert result['selected_suites'] == names
    assert result['representative_tall_layout'] is False
    assert read(folder / 'runtime_before_sha256.json') == read(folder / 'runtime_after_sha256.json')
    assert read(folder / 'runtime_before_sha256.json') == inputs, 'Rerun source differs from the stated source snapshot'
    assert [r['name'] for r in result['results']] == names + ['binary_catalog']
    for row in result['results']:
        assert row['passed'] is True and row['exit_code'] == 0 and row['errors'] == []
        assert (ROOT / row['log']).is_file()
    return result


def assemble(full: Path, balance: Path, floating: Path) -> dict:
    inputs = manifest()
    base = read(full / 'summary.json')
    before = read(full / 'runtime_before_sha256.json')
    after = read(full / 'runtime_after_sha256.json')
    assert before == after and base['runtime_unchanged'] is True and base['runtime_changes'] == []
    assert base['source_changes_during_import'] == []
    assert base['passed'] is False, 'This route must preserve the real failed initial result'
    names = [row[0] for row in SUITES]
    assert base['selected_suites'] == names
    assert [r['name'] for r in base['results']] == ['import'] + names + ['binary_catalog']
    failed = {r['name']: r for r in base['results'] if not r['passed']}
    assert set(failed) == {'fishing_balance', 'ocean_float_save'}, 'Any other failure must be investigated'
    assert failed['fishing_balance']['exit_code'] == 2
    assert failed['fishing_balance']['errors'] == [
        'FAIL FISHING BALANCE: explicit output path provided',
        'FAIL: cannot write evidence output ',
    ]
    assert failed['ocean_float_save']['exit_code'] == 1
    assert failed['ocean_float_save']['errors'] == [
        'FAIL: matrix contains twelve baits and seventy-four species',
    ]
    for row in base['results']:
        assert (ROOT / row['log']).is_file()
        if row['name'] not in failed:
            assert row['passed'] is True and row['exit_code'] == 0 and row['errors'] == []
    changes = sorted(p for p in before.keys() | inputs.keys() if before.get(p) != inputs.get(p))
    assert changes == [TEST], 'Only the precise float-save harness may change; all production inputs remain exact'
    original = subprocess.check_output(['git', 'show', BASELINE + ':' + TEST], cwd=ROOT).decode()
    assert hashlib.sha256(original.encode()).hexdigest() == before[TEST]
    assert (ROOT / TEST).read_text() == expanded_float_save_source(original), 'Additional or weakened test edits refused'
    for path in (ROOT / 'game').rglob('*.gd'):
        if path != ROOT / TEST:
            assert 'ocean_float_save_tests.gd' not in path.read_text(), 'An accepted suite depends on the repaired harness'
    balance_result = verify_rerun(balance, ['fishing_balance'], before)
    float_result = verify_rerun(floating, ['ocean_float_save'], inputs)
    assert any('FISHING_BALANCE_TESTS: 70/70' in line for row in balance_result['results'] for line in row['summary_lines'])
    assert any('generated records=3960' in line for row in float_result['results'] for line in row['summary_lines'])
    result_rows = []
    for row in base['results']:
        if row['name'] in failed:
            rerun = balance_result if row['name'] == 'fishing_balance' else float_result
            replacement = next(r for r in rerun['results'] if r['name'] == row['name'])
            result_rows.append({**replacement, 'original_failure': row, 'acceptance': 'exact independent harness repair'})
        else:
            result_rows.append(row)
    evidence = []
    for folder in [full, balance, floating]:
        for name in ['summary.json', 'runtime_before_sha256.json', 'runtime_after_sha256.json']:
            file = folder / name
            evidence.append({'path': str(file.relative_to(ROOT)), 'sha256': sha(file)})
        for row in read(folder / 'summary.json')['results']:
            file = ROOT / row['log']
            evidence.append({'path': str(file.relative_to(ROOT)), 'sha256': sha(file)})
    return {
        'passed': True, 'accepted_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
        'scope': '37 canonical Godot source suites, actual imported resources and binary audit; stable final production; only two exact harness failures replaced by passing independent reruns',
        'android_device_or_export_claim': False, 'publication_or_signing': False,
        'production_inputs_unchanged': True, 'unchanged_input_files': len(before) - 1,
        'test_only_changes': [{ 'path': TEST, 'before_sha256': before[TEST], 'after_sha256': inputs[TEST]}],
        'selected_suites': names, 'results': result_rows, 'evidence_files': evidence,
        'additional_desktop_native_visual_evidence': 'docs/evidence/ocean-diversity/native/',
        'platform_diagnostics': 'Exact macOS public-system-CA diagnostic retained in each offline headless log; unrelated errors fail acceptance',
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--full', type=Path, required=True)
    parser.add_argument('--balance', type=Path, required=True)
    parser.add_argument('--float-save', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = assemble(args.full.resolve(), args.balance.resolve(), args.float_save.resolve())
    assert not args.output.exists(), 'Accepted evidence is immutable'
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'passed': True, 'suites': len(result['selected_suites']), 'output': str(args.output)}, ensure_ascii=False))


if __name__ == '__main__':
    main()
