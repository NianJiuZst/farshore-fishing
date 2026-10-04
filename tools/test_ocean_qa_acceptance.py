#!/usr/bin/env python3
"""Read-only regression tests for the combined QA evidence acceptance gate.

All manifests, summary files, source text and filesystem listings are mocked.
No Godot process, production data, recorded evidence or source file is changed.
Run: python3 tools/test_ocean_qa_acceptance.py
"""
import copy
import hashlib
from pathlib import Path
import unittest
from unittest.mock import patch

import assemble_ocean_qa_acceptance as gate


class AcceptanceGateTests(unittest.TestCase):
    def setUp(self):
        self.root = Path('/virtual/ocean-qa')
        self.full, self.style, self.tall = [
            self.root / 'build' / leaf for leaf in ('full', 'style', 'tall')
        ]
        self.old_source = (
            'icons = ["rod_spinning", "rod_heavy"]\n'
            'REQUIRED_ICONS.size() == 31\n'
            'exactly31 required\n'
            '"/31 distinct\n'
        )
        self.source = (
            'icons = ["rod_spinning", "rod_heavy", "large_fish_chunk", '
            '"whole_mackerel", "large_squid", "large_surface_lure"]\n'
            'REQUIRED_ICONS.size() == 35\n'
            'exactly35 required\n'
            '"/35 distinct\n'
        )
        self.before = {
            gate.TEST: self.digest(self.old_source),
            'game/scripts/main.gd': self.digest('unchanged production'),
        }
        self.current = {**self.before, gate.TEST: self.digest(self.source)}
        names = [row[0] for row in gate.SUITES]
        full_summary = self.summary(names, False)
        full_summary['passed'] = False
        original_failure = next(row for row in full_summary['results']
                                if row['name'] == 'ui_style')
        original_failure.update(passed=False, exit_code=1, errors=[
            'FAIL UI: production declares exactly31 required generated raster icons',
            *[f'FAIL UI: {fixture}/gear: icon is a required generated bitmap: {icon}'
              for fixture in ('starter', 'discovered')
              for icon in ('large_fish_chunk', 'whole_mackerel',
                           'large_squid', 'large_surface_lure')],
        ])
        self.files = {}
        for folder, summary, manifest in (
            (self.full, full_summary, self.before),
            (self.style, self.summary(['ui_style'], False), self.current),
            (self.tall, self.summary(['ui_style'], True), self.current),
        ):
            self.files[folder / 'summary.json'] = copy.deepcopy(summary)
            for leaf in ('runtime_before_sha256.json', 'runtime_after_sha256.json'):
                self.files[folder / leaf] = copy.deepcopy(manifest)

    @staticmethod
    def digest(text):
        return hashlib.sha256(text.encode()).hexdigest()

    @staticmethod
    def summary(names, tall):
        return {
            'passed': True,
            'runtime_unchanged': True,
            'runtime_changes': [],
            'source_changes_during_import': [],
            'selected_suites': names,
            'representative_tall_layout': tall,
            'results': [dict(name=name, passed=True, exit_code=0, errors=[])
                        for name in [*names, 'binary_catalog']],
        }

    def rows(self, folder):
        return self.files[folder / 'summary.json']['results']

    def row(self, folder, name):
        return next(row for row in self.rows(folder) if row['name'] == name)

    def assemble(self):
        with patch.object(gate, 'ROOT', self.root), \
             patch.object(gate, 'manifest', return_value=copy.deepcopy(self.current)), \
             patch.object(gate, 'read', side_effect=lambda p: copy.deepcopy(self.files[p])), \
             patch.object(gate, 'sha', return_value='0' * 64), \
             patch.object(Path, 'read_text', return_value=self.source), \
             patch.object(Path, 'rglob', return_value=[self.root / gate.TEST]):
            return gate.assemble(self.full, self.style, self.tall)

    def reject(self):
        with self.assertRaises(AssertionError):
            self.assemble()

    def test_accepts_exact_test_only_rerun_and_preserves_failure(self):
        untouched = copy.deepcopy(self.files)
        result = self.assemble()
        self.assertIs(result['passed'], True)
        self.assertIs(result['initial_full_run_passed'], False)
        self.assertEqual(len(result['final_results']), len(gate.SUITES) + 1)
        self.assertEqual(self.files, untouched)

    def test_rejects_missing_suite_replaced_by_duplicate(self):
        self.row(self.full, 'core')['name'] = 'camera_aspect'
        self.reject()

    def test_rejects_missing_binary_audit(self):
        self.row(self.full, 'binary_catalog')['name'] = 'unrelated'
        self.reject()

    def test_rejects_pass_true_with_nonzero_exit(self):
        self.row(self.full, 'core')['exit_code'] = 1
        self.reject()

    def test_rejects_pass_true_with_errors(self):
        self.row(self.full, 'core')['errors'] = ['FAIL: synthetic']
        self.reject()

    def test_rejects_rerun_nonzero_exit(self):
        self.row(self.style, 'ui_style')['exit_code'] = 1
        self.reject()

    def test_rejects_missing_tall_audit(self):
        self.rows(self.tall).pop()
        self.reject()

    def test_rejects_unrelated_original_failure(self):
        self.row(self.full, 'core').update(passed=False, exit_code=1,
                                           errors=['FAIL: unrelated'])
        self.reject()

    def test_rejects_extra_production_change(self):
        self.current['game/scripts/main.gd'] = self.digest('changed production')
        self.reject()

    def test_rejects_extra_test_edit_even_with_updated_rerun_manifests(self):
        self.source += '# extra edit\n'
        self.current[gate.TEST] = self.digest(self.source)
        for folder in (self.style, self.tall):
            for leaf in ('runtime_before_sha256.json', 'runtime_after_sha256.json'):
                self.files[folder / leaf] = copy.deepcopy(self.current)
        self.reject()

    def test_rejects_stale_rerun_inputs(self):
        self.files[self.style / 'runtime_before_sha256.json'] = copy.deepcopy(self.before)
        self.reject()

    def test_rejects_additional_original_style_error(self):
        self.row(self.full, 'ui_style')['errors'].append('FAIL UI: unrelated')
        self.reject()

    def test_rejects_missing_tall_layout(self):
        self.files[self.tall / 'summary.json']['representative_tall_layout'] = False
        self.reject()

    def test_rejects_rewritten_original_batch_pass(self):
        self.files[self.full / 'summary.json']['passed'] = True
        self.reject()


if __name__ == '__main__':
    unittest.main(verbosity=2)
