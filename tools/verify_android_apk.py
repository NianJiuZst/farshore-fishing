"""Fail-closed inspection of the final signed APK, with machine-readable evidence."""
from pathlib import Path
import datetime
import hashlib
import json
import re
import struct
import subprocess
import sys
import tempfile
import zipfile

apk, abi, out, bt = Path(sys.argv[1]), sys.argv[2], Path(sys.argv[3]), Path(sys.argv[4])
out.mkdir(parents=True, exist_ok=True)

def run(args, filename):
    p = subprocess.run([str(a) for a in args], text=True, capture_output=True)
    (out / filename).write_text(p.stdout + p.stderr)
    if p.returncode:
        raise RuntimeError(f'{filename} failed with exit {p.returncode}')
    return p.stdout + p.stderr

badging = run([bt/'aapt', 'dump', 'badging', apk], 'badging.txt')
permissions = run([bt/'aapt', 'dump', 'permissions', apk], 'permissions.txt')
manifest = run([bt/'aapt', 'dump', 'xmltree', apk, 'AndroidManifest.xml'], 'manifest.txt')
signature = run([bt/'apksigner', 'verify', '--verbose', '--print-certs', apk], 'signature.txt')
run([bt/'zipalign', '-c', '-P', '16', '-v', '4', apk], 'zipalign16k.txt')
assert "package: name='org.farshore.fishing'" in badging, 'Unexpected package identity'
assert "sdkVersion:'29'" in badging, 'Minimum SDK must be Android 10 / API29'
assert "targetSdkVersion:'36'" in badging, 'Target SDK must be Android 16 / API36'
assert "application-debuggable" not in badging, 'Player release must not be debuggable'
requested = re.findall(r"uses-permission(?:-sdk-\d+)?: name='([^']+)'", permissions)
assert requested == ['android.permission.VIBRATE'], f'Unexpected requested permissions: {requested}'
assert 'Verified using v2 scheme (APK Signature Scheme v2): true' in signature
assert 'Verified using v3 scheme (APK Signature Scheme v3): true' in signature
libs = []
with zipfile.ZipFile(apk) as z:
    names = z.namelist()
    assert not any('.signing-private' in n or n.endswith(('.p12', '.jks', '.keystore')) for n in names)
    abis = sorted({n.split('/')[1] for n in names if n.startswith('lib/') and n.endswith('.so')})
    assert abis == [abi], f'Wrong native ABIs: {abis}'
    for name in names:
        if not name.startswith('lib/') or not name.endswith('.so'):
            continue
        raw = z.read(name)
        assert raw[:4] == b'\x7fELF' and raw[4] == 2 and raw[5] == 1, 'Expected little-endian ELF64'
        phoff = struct.unpack_from('<Q', raw, 32)[0]
        phentsize, phnum = struct.unpack_from('<HH', raw, 54)
        aligns = []
        for i in range(phnum):
            pos = phoff + i * phentsize
            typ = struct.unpack_from('<I', raw, pos)[0]
            if typ == 1:
                align = struct.unpack_from('<Q', raw, pos + 48)[0]
                assert align >= 16384, f'{name} LOAD is not 16 KiB aligned'
                aligns.append(align)
        assert aligns, 'Missing ELF LOAD segments'
        libs.append({'path': name, 'uncompressed_bytes': len(raw), 'elf_load_alignment': aligns})
    (out/'apk-file-list.txt').write_text('\n'.join(names)+'\n')
    assert 'assets/data/fish_a.json' in names and 'assets/data/fish_b.json' in names, 'Fish catalogs missing from offline APK'
    fish = []
    for name in ['assets/data/fish_a.json', 'assets/data/fish_b.json']:
        fish.extend(json.loads(z.read(name)))
    assert len({f['species_id'] for f in fish}) == 32, 'Final APK must contain 32 unique fish'
    assert any(n.endswith(('.ttf', '.otf', '.ttc', '.fontdata')) for n in names), 'Bundled font missing'
result = {
    'verified_at_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'apk': apk.name, 'bytes': apk.stat().st_size,
    'sha256': hashlib.file_digest(apk.open('rb'), 'sha256').hexdigest(),
    'package': 'org.farshore.fishing', 'min_sdk': 29, 'target_sdk': 36,
    'abi': abi, 'debuggable': False, 'permissions': requested,
    'signature_v2': True, 'signature_v3': True, 'zip_alignment_kib': 16,
    'native_libraries': libs, 'fish_species': len(fish),
    'runtime_test': 'Separate evidence required; binary inspection is not an installation test',
}
(out/'build-manifest.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
print(json.dumps(result, ensure_ascii=False, indent=2))
