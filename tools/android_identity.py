"""Strict public Android identities; private signing material is never source data."""
from pathlib import Path
import hashlib
import json
import re

LEGACY = {'android_package_name': 'org.farshore.fishing', 'launcher_name': '远岸钓记',
          'certificate_sha256': '1afefc3a71828393c0387e27053aa695b7c46aa3236caa5cb338bfeedb2e5281'}
PREVIEW = {'android_package_name': 'org.farshore.fishing.preview', 'launcher_name': '远岸钓记·试钓版',
           'certificate_sha256': 'e0c20cecffb3dc5af682bd16b3ce8b9da2f142b1bee8d59cc2fe70da232dc284'}
FORMAL = {**PREVIEW, 'launcher_name': '远岸钓记',
          'application_version': '1.2.0', 'android_version_code': 6}


def validate_identity(identity):
    known = {p['android_package_name']: p for p in (LEGACY, PREVIEW)}
    assert identity.get('android_package_name') in known, 'Unapproved Android package'
    pinned = known[identity['android_package_name']]
    if pinned == PREVIEW and identity.get('application_version') == FORMAL['application_version']:
        pinned = FORMAL
    for field, expected in pinned.items():
        assert identity.get(field) == expected, 'Android identity mismatch: ' + field
    if identity['android_package_name'] == PREVIEW['android_package_name']:
        assert identity.get('separate_installation') is True, 'Preview-package lineage must remain separate from the legacy app'
    return dict(identity)


def expected_identity(content=None):
    if content and content.get('android_identity'):
        return validate_identity(content['android_identity'])
    return dict(LEGACY)


def project_identity(project, presets, version, code):
    path = Path(project)/'data/android_build_identity.json'
    if path.exists():
        identity = validate_identity(json.loads(path.read_text()))
        assert identity['application_version'] == version and identity['android_version_code'] == code
    else:
        identity = dict(LEGACY)
    packages = set(re.findall(r'^package/unique_name="([^"]+)"', presets, re.M))
    names = set(re.findall(r'^package/name="([^"]+)"', presets, re.M))
    assert packages == {identity['android_package_name']} and names == {identity['launcher_name']}, 'Presets differ from frozen Android identity'
    return identity
