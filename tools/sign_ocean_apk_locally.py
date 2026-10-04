#!/usr/bin/env python3
"""User-operated local signing of an already aligned, verified ocean APK.

Never generates/uploads keys, changes credentials, installs apps or contacts a
network. Run on the owner's Mac after making a separate private key backup.
The input is immutable; password entry is hidden and is not an argument/env var.
"""
from pathlib import Path
import argparse
import getpass
import hashlib
import json
import re
import subprocess
import sys
import zipfile

PACKAGE = 'org.farshore.fishing.ocean'
LABEL = '远岸钓鱼·海洋'
RELEASES = {
    ('1.3.0', 7): {'catalog_parts': tuple('abcdef'), 'fish': 74, 'whale': False,
                   'regions': 9, 'spots': 18, 'gear': 5},
    ('1.4.0', 8): {'catalog_parts': tuple('abcdefgh') + ('whale',), 'fish': 110, 'whale': True,
                   'regions': 10, 'spots': 21, 'gear': 6},
}

def sha256(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream,'sha256').hexdigest()

def run(args, **kwargs):
    result=subprocess.run([str(x) for x in args], text=True, capture_output=True, **kwargs)
    if result.returncode:
        raise RuntimeError(f'{Path(args[0]).name} failed ({result.returncode}): {result.stderr.strip()}')
    return result.stdout+result.stderr

def inspect_apk(apk, bt):
    badge=run([bt/'aapt','dump','badging',apk])
    version_match=re.search(r"versionName='([^']+)'",badge)
    code_match=re.search(r"versionCode='(\d+)'",badge)
    if not version_match or not code_match: raise ValueError('Missing APK version/code')
    version,code=version_match.group(1),int(code_match.group(1))
    release=RELEASES.get((version,code))
    if release is None: raise ValueError('Unreviewed ocean version/code pair')
    for expected in [f"package: name='{PACKAGE}'", f"application-label:'{LABEL}'", "sdkVersion:'29'", "targetSdkVersion:'36'"]:
        if expected not in badge: raise ValueError('Unexpected APK identity: '+expected)
    if 'application-debuggable' in badge: raise ValueError('Debuggable APK rejected')
    permissions=run([bt/'aapt','dump','permissions',apk])
    if re.findall(r"uses-permission(?:-sdk-\d+)?: name='([^']+)'",permissions)!=['android.permission.VIBRATE']:
        raise ValueError('Unexpected APK permissions')
    run([bt/'zipalign','-c','-P','16','4',apk])
    with zipfile.ZipFile(apk) as archive:
        names=archive.namelist()
        if len(names)!=len(set(names)) or archive.testzip() is not None: raise ValueError('Invalid APK ZIP')
        abis=sorted({n.split('/')[1] for n in names if n.startswith('lib/') and n.endswith('.so')})
        if abis!=['arm64-v8a']: raise ValueError('Unexpected APK architecture')
        if any(n.endswith(('.p12','.jks','.keystore','.key','.pem')) or '.signing-private' in n for n in names):
            raise ValueError('Credential-like APK member rejected')
        identity=json.loads(archive.read('assets/data/android_build_identity.json'))
        if (identity.get('android_package_name')!=PACKAGE or identity.get('application_version')!=version
                or identity.get('android_version_code')!=code):
            raise ValueError('Bundled identity differs')
        fish=[]
        for part in release['catalog_parts']: fish+=json.loads(archive.read(f'assets/data/fish_{part}.json'))
        world=json.loads(archive.read('assets/data/world.json'))
        total=release['fish'] + int(release['whale'])
        ordinary=[f for f in fish if f.get('animal_kind','fish')=='fish' and f.get('fishing_enabled',True) is True]
        if (len(fish)!=total or len({f['species_id'] for f in fish})!=total or len(ordinary)!=release['fish']
                or len(world['baits'])!=12 or len(world['regions'])!=release['regions']
                or len(world['spots'])!=release['spots'] or len(world['gear'])!=release['gear']):
            raise ValueError('Incomplete ocean catalog')
        if release['whale']:
            whales=[f for f in fish if f['species_id']=='blue_whale']
            if (len(whales)!=1 or whales[0].get('animal_kind')!='mammal'
                    or whales[0].get('fishing_enabled') is not False
                    or whales[0].get('encounter_type')!='fantasy_challenge'):
                raise ValueError('Independent blue whale challenge required')
    return identity

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--input',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--build-tools',type=Path,required=True,help='Official Android build-tools36.0.0+ directory with zipalign -P16 support')
    p.add_argument('--keystore',type=Path,required=True,help='Existing owner-controlled PKCS12; no key is generated')
    p.add_argument('--alias',default='farshore-ocean')
    p.add_argument('--expected-input-sha256',required=True)
    p.add_argument('--expected-certificate-sha256',required=True,help='Public certificate fingerprint from the owner')
    p.add_argument('--backup-confirmed',action='store_true',help='Owner has separately verified a recoverable private backup')
    a=p.parse_args()
    if not a.backup_confirmed: p.error('Make and verify your own private key backup first, then add --backup-confirmed')
    if not a.input.is_file() or not a.keystore.is_file(): p.error('Existing unsigned input and owner-controlled key required')
    if a.output.exists() or a.output.resolve()==a.input.resolve(): p.error('Output must be a new file, distinct from input')
    if not re.fullmatch('[0-9a-f]{64}',a.expected_certificate_sha256): p.error('Expected public certificate must be lowercase SHA256')
    if sha256(a.input)!=a.expected_input_sha256: p.error('Unsigned APK hash differs from the verified transfer')
    identity=inspect_apk(a.input,a.build_tools)
    if identity.get('certificate_sha256')!=a.expected_certificate_sha256: p.error('Bundled certificate is not the approved public fingerprint')
    password=getpass.getpass('Local keystore password (hidden; never uploaded): ')
    if not password: p.error('Empty password rejected')
    a.output.parent.mkdir(parents=True,exist_ok=True)
    try:
        run([a.build_tools/'apksigner','sign','--ks',a.keystore,'--ks-key-alias',a.alias,
             '--ks-pass','stdin','--key-pass','stdin','--v1-signing-enabled','false',
             '--v2-signing-enabled','true','--v3-signing-enabled','true',
             '--v4-signing-enabled','false','--out',a.output,a.input],input=password+'\n'+password+'\n')
    finally:
        password=None
    proof=run([a.build_tools/'apksigner','verify','--min-sdk-version','24','--verbose','--print-certs',a.output])
    for expected in ['Verified using v2 scheme (APK Signature Scheme v2): true','Verified using v3 scheme (APK Signature Scheme v3): true','Signer #1 certificate SHA-256 digest: '+a.expected_certificate_sha256]:
        if expected not in proof: raise ValueError('Signed APK verification failed: '+expected)
    inspect_apk(a.output,a.build_tools)
    if sha256(a.input)!=a.expected_input_sha256: raise ValueError('Immutable unsigned input changed')
    report={'package':PACKAGE,'version':identity['application_version'],'version_code':identity['android_version_code'],'unsigned_sha256':a.expected_input_sha256,'signed_sha256':sha256(a.output),'bytes':a.output.stat().st_size,'certificate_sha256':a.expected_certificate_sha256,'v2_v3_verified':True,'zipalign_16k_verified':True,'private_material_uploaded':False}
    a.output.with_suffix('.signing-verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(report,ensure_ascii=False,indent=2))
    print('Keep the keystore and backup private. Only the signed APK and this public report may be returned.')
if __name__=='__main__':
    try: main()
    except (ValueError,RuntimeError,KeyError) as exc:
        print('SIGNING BLOCKED: '+str(exc),file=sys.stderr)
        sys.exit(1)
