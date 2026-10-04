#!/usr/bin/env python3
"""Combine one complete run with only the exact35-icon test-manifest rerun.

This never rewrites a failed run. It rejects any production/input change, any
other failed suite, any additional test edit, or a missing normal/tall rerun.
"""
if not __debug__:
    raise RuntimeError('Unoptimized Python is required for acceptance assertions')
import argparse
import datetime
import hashlib
import json
from pathlib import Path
from run_full_catalog_qa import ROOT, SUITES, manifest

TEST = 'game/tests/ui_style_tests.gd'
NEW_IDS = ['large_fish_chunk','whole_mackerel','large_squid','large_surface_lure']

def sha(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def read(path): return json.loads(Path(path).read_text())

def assemble(full, style, tall):
    inputs = manifest()
    base = read(full/'summary.json')
    before = read(full/'runtime_before_sha256.json')
    after = read(full/'runtime_after_sha256.json')
    assert before == after and base['runtime_unchanged'] and not base['runtime_changes']
    assert not base['source_changes_during_import']
    assert base['selected_suites'] == [x[0] for x in SUITES], 'A complete initial suite is required'
    assert base['passed'] is False, 'Preserve the real initial result; this route is only for its exact recorded failure'
    expected_names = [x[0] for x in SUITES] + ['binary_catalog']
    assert [x['name'] for x in base['results']] == expected_names, 'Exact complete result names/order required; duplicates or omissions rejected'
    for row in base['results']:
        if row['name'] != 'ui_style':
            assert row['passed'] is True and row['exit_code'] == 0 and row['errors'] == [], 'Accepted rows must have successful exit and no errors'
    failed = [x for x in base['results'] if not x['passed']]
    assert len(failed)==1 and failed[0]['name']=='ui_style'
    assert failed[0]['passed'] is False and failed[0]['exit_code'] == 1, 'Original test failure must remain explicit'
    expected_errors = ['FAIL UI: production declares exactly31 required generated raster icons']
    expected_errors += [f'FAIL UI: {fixture}/gear: icon is a required generated bitmap: {icon}' for fixture in ['starter','discovered'] for icon in NEW_IDS]
    assert sorted(failed[0]['errors']) == sorted(expected_errors), 'No unrelated failure may be replaced'
    differences = sorted(p for p in before.keys() | inputs.keys() if before.get(p)!=inputs.get(p))
    assert differences == [TEST], 'Only the exact icon-expectation test may change; production/assets must remain byte-identical'
    previous = (ROOT/TEST).read_text()
    substitutions = [
        ('"rod_spinning", "rod_heavy", "large_fish_chunk", "whole_mackerel", "large_squid", "large_surface_lure"]','"rod_spinning", "rod_heavy"]'),
        ('REQUIRED_ICONS.size() == 35','REQUIRED_ICONS.size() == 31'),
        ('exactly35 required','exactly31 required'),
        ('"/35 distinct','"/31 distinct'),
    ]
    for current, old in substitutions:
        assert previous.count(current)==1, 'Unexpected or ambiguous test edit'
        previous=previous.replace(current,old)
    assert hashlib.sha256(previous.encode()).hexdigest()==before[TEST], 'Extra test changes are forbidden'
    for path in (ROOT/'game').rglob('*.gd'):
        if path != ROOT/TEST:
            assert 'ui_style_tests.gd' not in path.read_text(), 'Another game/test script depends on the replaced harness'
    reruns=[]
    for folder, is_tall in [(style,False),(tall,True)]:
        row=read(folder/'summary.json')
        assert row['passed'] and row['runtime_unchanged'] and not row['runtime_changes']
        assert not row['source_changes_during_import']
        assert row['selected_suites']==['ui_style'] and row['representative_tall_layout'] is is_tall
        assert read(folder/'runtime_before_sha256.json')==inputs==read(folder/'runtime_after_sha256.json'), 'Rerun inputs must exactly equal final inputs'
        assert [x['name'] for x in row['results']] == ['ui_style','binary_catalog'], 'Exact rerun result names/order required'
        assert all(x['passed'] is True and x['exit_code'] == 0 and x['errors'] == [] for x in row['results'])
        reruns.append(row)
    final_results=[]
    for row in base['results']:
        picked=next(x for x in reruns[0]['results'] if x['name']=='ui_style') if row['name']=='ui_style' else row
        final_results.append({**picked,'accepted_from':str((style if row['name']=='ui_style' else full).relative_to(ROOT))})
    assert [x['name'] for x in final_results] == expected_names
    assert all(x['passed'] is True and x['exit_code'] == 0 and x['errors'] == [] for x in final_results)
    return {'schema':1,'passed':True,'kind':'complete-run-plus-explicit-test-only-icon-manifest-rerun',
            'verified_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
            'initial_full_run_passed':False,'initial_failed_suite':'ui_style',
            'reason':'Expected generated-icon inventory was expanded from31 to35 for the four authorized new bait icons; every existing style/layout/input assertion is retained.',
            'production_and_assets_unchanged':True,'final_runtime_sha256':inputs,
            'only_changed_test':{'path':TEST,'before_sha256':before[TEST],'final_sha256':inputs[TEST],'change_verified_by_exact_inverse':True},
            'complete_suite_count':len(SUITES),'binary_catalog_audit_passed':True,'final_results':final_results,
            'tall_style_result':next(x for x in reruns[1]['results'] if x['name']=='ui_style'),
            'evidence':{str((f/'summary.json').relative_to(ROOT)):sha(f/'summary.json') for f in [full,style,tall]},
            'scope':'Combined final source/control acceptance, not a claim that the initial full batch passed unchanged. Native rendering and Android package/device checks are separate.'}

def main():
    p=argparse.ArgumentParser(description=__doc__)
    for name in ['full','style','tall','output']:p.add_argument('--'+name,type=Path,required=True)
    a=p.parse_args(); output=a.output.resolve()
    assert (ROOT/'build') in output.parents and not output.exists(), 'Use a new build evidence output'
    report=assemble(a.full.resolve(),a.style.resolve(),a.tall.resolve())
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({k:report[k] for k in ['passed','kind','complete_suite_count','production_and_assets_unchanged']},ensure_ascii=False))
if __name__=='__main__':main()
