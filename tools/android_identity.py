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
# New independent signer created/backed up by the owner on their Mac.
# Only the PUBLIC certificate digest is stored here; no private material.
OCEAN = {'android_package_name': 'org.farshore.fishing.ocean',
         'launcher_name': '远岸钓鱼·海洋', 'certificate_sha256': 'a1996b606b1de5ec3ffd52edff64ec60b0434099d414c8893fa93b585c6ad716',
         'application_version': '1.3.0', 'android_version_code': 7,
         'signing_status': 'owner_local_key_public_certificate_pinned'}


def validate_identity(identity, *, require_signer=True):
    known = {p['android_package_name']: p for p in (LEGACY, PREVIEW, OCEAN)}
    assert identity.get('android_package_name') in known, 'Unapproved Android package'
    pinned = known[identity['android_package_name']]
    if pinned == PREVIEW:
        if identity.get('application_version') == FORMAL['application_version']: pinned = FORMAL
    for field, expected in pinned.items():
        assert identity.get(field) == expected, 'Android identity mismatch: ' + field
    if pinned == OCEAN and require_signer:
        assert isinstance(pinned['certificate_sha256'], str) and re.fullmatch(r'[0-9a-f]{64}', pinned['certificate_sha256']), 'Ocean release signer is not provisioned and pinned; source-only identity is not release authorization'
    if identity['android_package_name'] in {PREVIEW['android_package_name'], OCEAN['android_package_name']}:
        assert identity.get('separate_installation') is True, 'Separate Android app must not overwrite either earlier package'
    return dict(identity)


def expected_identity(content=None):
    if content and content.get('android_identity'):
        return validate_identity(content['android_identity'])
    return dict(LEGACY)


def project_identity(project, presets, version, code):
    path = Path(project)/'data/android_build_identity.json'
    if path.exists():
        # Source content can be audited before signing. Every actual builder/APK
        # verifier calls expected_identity() again with the strict signer gate.
        identity = validate_identity(json.loads(path.read_text()), require_signer=False)
        assert identity['application_version'] == version and identity['android_version_code'] == code
    else:
        identity = dict(LEGACY)
    packages = set(re.findall(r'^package/unique_name="([^"]+)"', presets, re.M))
    names = set(re.findall(r'^package/name="([^"]+)"', presets, re.M))
    assert packages == {identity['android_package_name']} and names == {identity['launcher_name']}, 'Presets differ from frozen Android identity'
    return identity
