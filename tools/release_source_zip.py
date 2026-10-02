"""Create a fully verified commit-exact source ZIP without recompressing old art.

Only compressed payloads whose old ZIP bytes match the new Git blob are reused.
Every member of the result is streamed again for CRC, SHA1 and SHA256 validation.
The old ZIP is immutable. Working files must match the selected commit exactly.
"""
from pathlib import Path, PurePosixPath
import argparse
import copy
import datetime
import hashlib
import json
import os
import struct
import subprocess
import zipfile
from content_fish_art_contract import require_photo_archive_members


def digest(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def inventory(root, commit):
    resolved = subprocess.check_output(['git', 'rev-parse', commit + '^{commit}'], cwd=root, text=True).strip()
    rows = subprocess.check_output(['git', 'ls-tree', '-rlz', resolved], cwd=root).split(b'\0')
    result = {}
    for row in rows:
        if not row:
            continue
        head, name = row.split(b'\t', 1)
        mode, kind, oid, size = head.split()
        name = name.decode('utf-8')
        parts = PurePosixPath(name).parts
        assert kind == b'blob' and mode in {b'100644', b'100755'}, 'Only ordinary tracked files may ship'
        assert not name.startswith('/') and '..' not in parts
        assert not any(part in {'.git', '.signing-private', '.godot', 'android-sdk', 'jdk', 'node_modules'} for part in parts)
        assert not name.endswith(('.p12', '.jks', '.keystore', '.pem', '.key')), 'Credential-like source member rejected'
        result[name] = {'mode': mode.decode(), 'git_blob_sha1': oid.decode(), 'bytes': int(size)}
    assert result
    return resolved, result


def stream_hashes(stream, size):
    sha1 = hashlib.sha1(('blob %d\0' % size).encode())
    sha256 = hashlib.sha256()
    count = 0
    while data := stream.read(1024 * 1024):
        sha1.update(data)
        sha256.update(data)
        count += len(data)
    assert count == size, 'Source member size differs'
    return sha1.hexdigest(), sha256.hexdigest()


def verify_zip(path, files, prefix):
    found = {}
    with zipfile.ZipFile(path) as archive:
        for info in archive.infolist():
            if info.is_dir():
                assert info.filename.startswith(prefix + '/')
                continue
            assert info.filename.startswith(prefix + '/')
            relative = info.filename[len(prefix) + 1:]
            assert relative in files and relative not in found, 'Unexpected or duplicate ZIP member'
            expected = files[relative]
            assert info.file_size == expected['bytes']
            assert (info.external_attr >> 16) & 0o777 == int(expected['mode'], 8) & 0o777, 'ZIP file mode differs from commit'
            with archive.open(info) as stream:
                sha1, sha256 = stream_hashes(stream, info.file_size)
            assert sha1 == expected['git_blob_sha1'], 'ZIP differs from commit: ' + relative
            if expected.get('sha256'):
                assert sha256 == expected['sha256']
            found[relative] = {**expected, 'sha256': sha256}
    assert set(found) == set(files), 'ZIP is missing tracked commit members'
    return found


def raw_copy_member(source, info, destination, name):
    """Copy one verified deflate/stored stream, writing fresh local/central headers."""
    assert info.compress_type in {zipfile.ZIP_STORED, zipfile.ZIP_DEFLATED}
    assert not info.flag_bits & 1, 'Encrypted ZIP source refused'
    source.fp.seek(info.header_offset)
    raw = source.fp.read(30)
    header = struct.unpack('<IHHHHHIIIHH', raw)
    assert header[0] == 0x04034B50
    source.fp.seek(header[-2] + header[-1], os.SEEK_CUR)
    new = copy.copy(info)
    new.filename = name
    new.orig_filename = name
    new.flag_bits &= ~8
    new.header_offset = destination.fp.tell()
    assert max(new.file_size, new.compress_size, new.header_offset) < zipfile.ZIP64_LIMIT
    offset = 0
    while offset < len(new.extra):
        identifier, length = struct.unpack_from('<HH', new.extra, offset)
        assert identifier in {0x5455, 0x7875}, 'Unexpected ZIP extra metadata requires explicit review'
        offset += 4 + length
    assert offset == len(new.extra)
    destination._writecheck(new)
    destination._didModify = True
    destination.fp.write(new.FileHeader(False))
    remaining = info.compress_size
    while remaining:
        data = source.fp.read(min(1024 * 1024, remaining))
        assert data, 'Truncated old ZIP compressed member'
        destination.fp.write(data)
        remaining -= len(data)
    destination.filelist.append(new)
    destination.NameToInfo[new.filename] = new
    destination.start_dir = destination.fp.tell()


def create(root, commit, output, prefix, base_zip=None, base_manifest=None):
    root, output = Path(root).resolve(), Path(output).resolve()
    commit, files = inventory(root, commit)
    assert not output.exists(), 'Existing source archives are immutable'
    pending = output.with_name(output.name + '.pending')
    assert not pending.exists()
    output.parent.mkdir(parents=True, exist_ok=True)
    for name, expected in files.items():
        path = root / name
        assert path.is_file() and not path.is_symlink()
        with path.open('rb') as stream:
            sha1, sha256 = stream_hashes(stream, expected['bytes'])
        assert sha1 == expected['git_blob_sha1'], 'Uncommitted tracked change: ' + name
        expected['sha256'] = sha256
    require_photo_archive_members(root, files)
    old = None
    old_files = {}
    old_prefix = ''
    if base_zip:
        data = json.loads(Path(base_manifest).read_text())
        assert digest(base_zip) == data['source_archive']['sha256'], 'Old source ZIP digest changed'
        old = zipfile.ZipFile(base_zip)
        prefixes = {i.filename.split('/')[0] for i in old.infolist()}
        assert len(prefixes) == 1
        old_prefix = prefixes.pop()
        old_files = data['files']
    reused = changed = 0
    try:
        with zipfile.ZipFile(pending, 'x', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
            for name, expected in sorted(files.items()):
                previous = old_files.get(name, {})
                if old and previous.get('git_blob_sha1') == expected['git_blob_sha1']:
                    info = old.getinfo(old_prefix + '/' + name)
                    with old.open(info) as stream:
                        sha1, sha256 = stream_hashes(stream, expected['bytes'])
                    assert sha1 == expected['git_blob_sha1'] and sha256 == expected['sha256']
                    raw_copy_member(old, info, archive, prefix + '/' + name)
                    reused += 1
                else:
                    archive.write(root / name, prefix + '/' + name)
                    changed += 1
        verified = verify_zip(pending, files, prefix)
        for name, expected in files.items():
            assert digest(root / name) == expected['sha256'], 'Source changed while creating ZIP: ' + name
        pending.rename(output)
    finally:
        if old:
            old.close()
    return {'source_commit': commit, 'verified_at_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
            'source_archive': {'name': output.name, 'bytes': output.stat().st_size,
                               'sha256': digest(output), 'file_count': len(files),
                               'uncompressed_bytes': sum(p['bytes'] for p in files.values()),
                               'prefix': prefix, 'compressed_members_reused': reused, 'new_or_changed_members': changed,
                               'verification': 'Every member streamed for CRC, Git blob SHA1 and SHA256; exact tracked commit membership; working-source hashes rechecked'},
            'files': verified}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--commit', required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--prefix', required=True)
    parser.add_argument('--manifest', type=Path, required=True)
    parser.add_argument('--base-zip', type=Path)
    parser.add_argument('--base-manifest', type=Path)
    args = parser.parse_args()
    assert bool(args.base_zip) == bool(args.base_manifest)
    report = create(args.root, args.commit, args.output, args.prefix, args.base_zip, args.base_manifest)
    assert not args.manifest.exists(), 'Existing proof must not be overwritten'
    args.manifest.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: v for k, v in report.items() if k != 'files'}, indent=2))


if __name__ == '__main__': main()
