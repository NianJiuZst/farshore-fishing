"""Losslessly park only the inactive official NDK in persistent project storage.

Original file hashes, sizes, modes and symlink targets are retained and rechecked.
The archive is verified on persistent storage before the installed duplicate is
removed. No AVD, credentials, source, old release or unrelated paths are touched.
"""
from pathlib import Path, PurePosixPath
import argparse
import datetime
import hashlib
import json
import os
import shutil
import stat
import subprocess
import tarfile
import tempfile

FLOOR = 768 * 1024**2


def digest(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def inventory(base):
    base = Path(base)
    result = {}
    assert base.is_dir() and not base.is_symlink()
    for path in sorted(base.rglob('*')):
        item = path.lstat()
        rel = str(path.relative_to(base))
        entry = {'mode': stat.S_IMODE(item.st_mode)}
        if path.is_symlink():
            entry.update(kind='symlink', target=os.readlink(path))
            assert path.resolve().is_relative_to(base.resolve()), 'NDK link escapes component: ' + rel
        elif path.is_dir():
            entry['kind'] = 'directory'
        else:
            assert stat.S_ISREG(item.st_mode), 'Unexpected SDK entry type'
            entry.update(kind='file', bytes=item.st_size, sha256=digest(path))
        result[rel] = entry
    return result


def archive_tree(base, archive, expected):
    with tarfile.open(archive, 'x:gz', compresslevel=1) as tar:
        for name, entry in sorted(expected.items()):
            path = Path(base) / name
            item = tarfile.TarInfo(name)
            item.mode = entry['mode']
            item.mtime = int(path.lstat().st_mtime)
            if entry['kind'] == 'directory':
                item.type = tarfile.DIRTYPE
                tar.addfile(item)
            elif entry['kind'] == 'symlink':
                item.type = tarfile.SYMTYPE
                item.linkname = entry['target']
                tar.addfile(item)
            else:
                item.size = entry['bytes']
                with path.open('rb') as stream:
                    tar.addfile(item, stream)


def verify_archive(archive, expected, destination=None):
    found = {}
    with tarfile.open(archive, 'r|gz') as tar:
        for member in tar:
            name = member.name.rstrip('/')
            relative = PurePosixPath(name)
            assert not relative.is_absolute() and '..' not in relative.parts
            assert name in expected and name not in found, 'Unexpected or duplicate SDK member'
            entry = expected[name]
            assert member.mode == entry['mode']
            found[name] = dict(entry)
            path = Path(destination) / name if destination else None
            if path:
                assert not path.exists() and not path.is_symlink()
                assert path.resolve().is_relative_to(Path(destination).resolve())
                path.parent.mkdir(parents=True, exist_ok=True)
            if entry['kind'] == 'directory':
                assert member.isdir()
                if path:
                    path.mkdir(exist_ok=True)
                    path.chmod(entry['mode'])
            elif entry['kind'] == 'symlink':
                assert member.issym() and member.linkname == entry['target']
                if path:
                    assert (path.parent / member.linkname).resolve().is_relative_to(Path(destination).resolve())
                    path.symlink_to(member.linkname)
            else:
                assert member.isfile() and member.size == entry['bytes']
                with tar.extractfile(member) as stream:
                    if path:
                        with path.open('xb') as output:
                            shutil.copyfileobj(stream, output)
                        path.chmod(entry['mode'])
                        got = digest(path)
                    else:
                        got = hashlib.file_digest(stream, 'sha256').hexdigest()
                assert got == entry['sha256'], 'SDK archive hash differs: ' + name
    assert found == expected, 'SDK archive has missing members'


def require_inactive(root):
    processes = subprocess.check_output(['ps', '-eo', 'pid,args'], text=True)
    assert not any(('java' in line and ('GradleDaemon' in line or 'GradleWrapperMain' in line))
                   or ('emulator' in line and ('-avd' in line or 'qemu-system' in line))
                   for line in processes.splitlines()), 'Stop active build/emulator processes before NDK parking'
    state = json.loads((root / 'build/android-control/state.json').read_text())
    assert state.get('emulator_running') is False


def store(root):
    root = Path(root).resolve()
    source = root / 'tools/android-sdk/ndk/29.0.14206865'
    storage = root / 'build/toolchain-storage'
    pointer = storage / 'ndk-storage.json'
    require_inactive(root)
    assert not pointer.exists(), 'Existing NDK storage must be reviewed, never overwritten'
    expected = inventory(source)
    assert expected['source.properties']['kind'] == 'file'
    allocated = sum(p.lstat().st_blocks * 512 for p in source.rglob('*'))
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    tmp = Path(tempfile.mkdtemp(prefix='farshore-ndk-park-'))
    temporary = tmp / 'ndk.tar.gz'
    print('Archiving NDK:', len(expected), 'entries, allocated bytes', allocated, flush=True)
    archive_tree(source, temporary, expected)
    verify_archive(temporary, expected)
    assert inventory(source) == expected
    assert shutil.disk_usage(root).free - temporary.stat().st_size > FLOOR, 'Persistent archive would violate disk floor'
    storage.mkdir(parents=True, exist_ok=True)
    archive = storage / ('ndk-29.0.14206865-' + stamp + '.tar.gz')
    assert not archive.exists()
    with temporary.open('rb') as inp, archive.open('xb') as out:
        shutil.copyfileobj(inp, out)
    assert digest(temporary) == digest(archive)
    verify_archive(archive, expected)
    require_inactive(root)
    assert inventory(source) == expected
    report = {'status': 'verified_before_removal', 'source_relative': str(source.relative_to(root)),
              'archive_relative': str(archive.relative_to(root)), 'archive_sha256': digest(archive),
              'archive_bytes': archive.stat().st_size, 'source_allocated_bytes': allocated,
              'entries': expected, 'restore_command': 'python3 tools/park_android_ndk.py restore',
              'verified_at_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
              'free_at_persistent_archive_peak_bytes': shutil.disk_usage(root).free}
    pointer.write_text(json.dumps(report, indent=2) + '\n')
    assert source.resolve() == root / 'tools/android-sdk/ndk/29.0.14206865' and not source.is_symlink()
    shutil.rmtree(source)
    report.update(status='stored', free_after_store_bytes=shutil.disk_usage(root).free)
    pointer.write_text(json.dumps(report, indent=2) + '\n')
    temporary.unlink()
    tmp.rmdir()
    print(json.dumps({k: v for k, v in report.items() if k != 'entries'}, indent=2), flush=True)


def restore(root):
    root = Path(root).resolve()
    pointer = root / 'build/toolchain-storage/ndk-storage.json'
    report = json.loads(pointer.read_text())
    source, archive = root / report['source_relative'], root / report['archive_relative']
    assert source == root / 'tools/android-sdk/ndk/29.0.14206865'
    assert archive.resolve().parent == root / 'build/toolchain-storage'
    assert digest(archive) == report['archive_sha256']
    if source.exists():
        assert inventory(source) == report['entries']
    else:
        assert shutil.disk_usage(root).free > report['source_allocated_bytes'] + FLOOR
        temporary = source.with_name(source.name + '.restoring')
        assert not temporary.exists()
        temporary.mkdir(parents=True)
        verify_archive(archive, report['entries'], temporary)
        assert inventory(temporary) == report['entries']
        temporary.rename(source)
    report.update(status='restored', restored_at_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
    pointer.write_text(json.dumps(report, indent=2) + '\n')
    print('Exact NDK files, SHA256, modes and symlink targets restored; persistent archive retained')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['store', 'restore'])
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parent.parent)
    args = parser.parse_args()
    (store if args.action == 'store' else restore)(args.root)
