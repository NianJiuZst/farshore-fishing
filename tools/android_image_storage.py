"""Losslessly park/restore the inactive official API36 image, never AVD data.

This workspace-only disk aid does not download tools, create credentials, or touch
the game. Keep its manifest/archive private build outputs, outside source delivery.
"""
from pathlib import Path, PurePosixPath
import datetime
import hashlib
import json
import os
import shutil
import stat
import sys
import tarfile

root = Path(__file__).resolve().parent.parent
image = root/'tools/android-sdk/system-images/android-36/default/x86_64'
storage = root/'build/toolchain-storage'
pointer = storage/'api36-image-storage.json'


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def inventory(base):
    result = {}
    assert base.is_dir() and not base.is_symlink()
    for path in sorted(base.rglob('*')):
        assert not path.is_symlink(), f'Unexpected symlink: {path.name}'
        if path.is_file():
            info = path.stat()
            result[str(path.relative_to(base))] = {'sha256':digest(path),'bytes':info.st_size,'mode':stat.S_IMODE(info.st_mode)}
    return result


def require_stopped():
    state = json.loads((root/'build/android-control/state.json').read_text())
    assert state.get('emulator_running') is False, 'Stop the owned emulator first'
    assert not list((root/'build/emulator-runtime/avd/running').glob('pid_*.ini')), 'Emulator advertisement still present'


def validate_archive(archive, expected, destination=None):
    found = {}
    with tarfile.open(archive, 'r:gz') as tar:
        for member in tar:
            rel = PurePosixPath(member.name)
            assert member.isfile() and not rel.is_absolute() and '..' not in rel.parts
            assert member.name in expected and member.name not in found
            with tar.extractfile(member) as stream:
                if destination is None:
                    found[member.name] = hashlib.file_digest(stream,'sha256').hexdigest()
                else:
                    target = destination/member.name
                    assert target.resolve().is_relative_to(destination.resolve())
                    target.parent.mkdir(parents=True,exist_ok=True)
                    with target.open('xb') as output: shutil.copyfileobj(stream,output)
                    target.chmod(expected[member.name]['mode'])
                    found[member.name] = digest(target)
    assert found == {p:d['sha256'] for p,d in expected.items()}, 'Archive file hashes differ'


action = sys.argv[1] if len(sys.argv) in {2,3} else ''
component = sys.argv[2] if len(sys.argv) == 3 else 'image'
assert action in {'store','restore'} and component in {'image','emulator'}, 'Usage: android_image_storage.py store|restore [image|emulator]'
if component == 'emulator':
    image = root/'tools/android-sdk/emulator'
    pointer = storage/'emulator-binaries-storage.json'
require_stopped()
storage.mkdir(parents=True,exist_ok=True)
if action == 'store':
    if pointer.exists():
        assert json.loads(pointer.read_text())['status'] == 'restored', 'A stored image already awaits restoration'
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    prefix = 'api36-default-x86_64' if component == 'image' else 'android-emulator-binaries'
    archive = storage/f'{prefix}-{stamp}.tar.gz'
    before_free = shutil.disk_usage(root).free
    expected = inventory(image)
    assert expected and ('system.img' if component == 'image' else 'emulator') in expected
    allocated = sum(p.stat().st_blocks*512 for p in image.rglob('*') if p.is_file())
    print('Archiving stopped official SDK component:',component,'files:',len(expected),'allocated bytes:',allocated,flush=True)
    with tarfile.open(archive,'x:gz',compresslevel=1) as tar:
        for name in expected: tar.add(image/name,arcname=name,recursive=False)
    archive_free = shutil.disk_usage(root).free
    validate_archive(archive,expected)
    assert inventory(image) == expected, 'Image changed while archiving'
    report = {'status':'verified_before_removal','source_relative':str(image.relative_to(root)),
              'archive_relative':str(archive.relative_to(root)),'archive_sha256':digest(archive),
              'archive_bytes':archive.stat().st_size,'source_allocated_bytes':allocated,'files':expected,
              'free_before_bytes':before_free,'free_at_archive_peak_bytes':archive_free}
    pointer.write_text(json.dumps(report,indent=2)+'\n')
    assert image.resolve().is_relative_to((root/'tools/android-sdk').resolve())
    shutil.rmtree(image)
    report.update({'status':'stored','free_after_store_bytes':shutil.disk_usage(root).free})
    pointer.write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k!='files'},indent=2))
else:
    report = json.loads(pointer.read_text())
    archive = root/report['archive_relative']
    assert archive.resolve().is_relative_to(storage.resolve())
    assert digest(archive) == report['archive_sha256'], 'SDK archive digest changed'
    if image.exists():
        assert inventory(image) == report['files'], 'Existing image does not match stored bytes'
    else:
        destination = image.with_name(image.name+'.restoring')
        assert not destination.exists(), 'A prior incomplete restore needs review'
        destination.mkdir(parents=True)
        validate_archive(archive,report['files'],destination)
        assert inventory(destination) == report['files']
        destination.rename(image)
    report['status'] = 'restored'
    report['restored_at_utc'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    pointer.write_text(json.dumps(report,indent=2)+'\n')
    print('Exact official SDK component restored:',component,'; every file hash/mode verified; archive and manifest retained')
