#!/usr/bin/env python3
"""Fast, filesystem-isolated tests for the catalog's final visual-review gate."""
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from audit_fish_catalog import VIEWS, visual_review_status


class ReviewGateTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.path = Path(self.tmp.name)
        self.hashes = {}
        for view in VIEWS:
            data = (view + ' reviewed pixels').encode()
            (self.path / (view + '.png')).write_bytes(data)
            self.hashes[view] = hashlib.sha256(data).hexdigest()

    def write(self, record, name='review_signoff.json'):
        record.update(glb_sha256='GLB', master_sha256='MASTER')
        (self.path / name).write_text(json.dumps(record))

    def passes(self, glb='GLB', master='MASTER'):
        return visual_review_status(self.path, glb, master)['passed']

    def test_supported_family_schemas(self):
        records = [
            {'status': 'reviewed_pass', 'reviewed_views': self.hashes},
            {'visual_result': 'pass', 'images': [
                {'view': v, 'sha256': h} for v, h in self.hashes.items()]},
            {'visual_review': 'pass', 'reviewed_views': list(VIEWS),
             'view_hashes': self.hashes},
        ]
        for record in records:
            self.write(record)
            self.assertTrue(self.passes())
            self.assertFalse(self.passes(glb='CHANGED'))
            self.assertFalse(self.passes(master='CHANGED'))

    def test_missing_review_is_not_inferred_from_images(self):
        self.assertFalse(self.passes())

    def test_changed_or_missing_image_is_rejected(self):
        self.write({'status': 'reviewed_pass', 'reviewed_views': self.hashes})
        (self.path / 'hero.png').write_bytes(b'changed pixels')
        self.assertFalse(self.passes())
        (self.path / 'hero.png').unlink()
        self.assertFalse(self.passes())

    def test_incomplete_or_failed_review_is_rejected(self):
        self.write({'status': 'reviewed_pass', 'reviewed_views': {'hero': self.hashes['hero']}})
        self.assertFalse(self.passes())
        self.write({'visual_review': 'fail', 'reviewed_views': list(VIEWS), 'view_hashes': self.hashes})
        self.assertFalse(self.passes())

    def test_visual_review_filename(self):
        self.write({'visual_review': 'pass', 'reviewed_views': list(VIEWS),
                    'view_hashes': self.hashes}, 'visual_review.json')
        self.assertTrue(self.passes())


if __name__ == '__main__':
    unittest.main()
