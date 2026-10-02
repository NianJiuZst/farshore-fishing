"""Manifest-equal, fully reread source archives; existing backups stay immutable."""
from pathlib import Path, PurePosixPath
import hashlib
import json
import tarfile


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def check_source(base, expected):
    for name, wanted in expected.items():
        relative = PurePosixPath(name)
        assert not relative.is_absolute() and '..' not in relative.parts
        path = base/name
        assert path.is_file() and not path.is_symlink() and path.resolve().is_relative_to(base.resolve())
        assert digest(path) == wanted, f'Source changed before/while verifying backup: {name}'


def verify_members(archive, expected, prefix=''):
    found = {}
    with tarfile.open(archive, 'r|gz') as tar:
        for member in tar:
            assert member.isfile() and member.name.startswith(prefix), 'Unexpected archive entry type/path'
            name = member.name[len(prefix):]
            assert name in expected and name not in found, f'Unexpected or duplicate archive member: {name}'
            with tar.extractfile(member) as stream:
                found[name] = hashlib.file_digest(stream, 'sha256').hexdigest()
    assert found == expected, 'Archive membership/content differs from current frozen inventory'


def verified_backup(base, expected, folder, label, stamp, prefix='', candidates=(), require_reuse=False):
    base, folder = Path(base), Path(folder).resolve()
    assert label in {'game','authoring'}
    check_source(base, expected)
    rejected = []
    for candidate in candidates:
        if candidate.get('sha256') != expected:
            continue
        archive = Path(candidate['archive'])
        if archive.resolve().parent != folder or archive.is_symlink() or not archive.name.endswith('.tar.gz'):
            rejected.append({'archive':str(archive),'reason':'Archive path is outside the approved backup directory'})
            continue
        try:
            actual = digest(archive)
            if candidate.get('archive_sha256') and actual != candidate['archive_sha256']:
                raise AssertionError('Whole-archive digest changed')
            verify_members(archive, expected, prefix)
        except (OSError, EOFError, tarfile.TarError, AssertionError) as error:
            rejected.append({'archive':str(archive),'reason':str(error)})
            continue
        check_source(base, expected)
        return {'archive':str(archive),'archive_sha256':actual,'sha256':expected,
                'reused':True,'rejected_candidates':rejected}
    assert not require_reuse, 'No fully verified manifest-equal backup exists; refusing a new archive in constrained-space mode'
    folder.mkdir(parents=True,exist_ok=True)
    archive = folder/f'{label}-{stamp}.tar.gz'
    pending = archive.with_name(archive.name+'.pending')
    assert not archive.exists() and not pending.exists(), 'Refusing to overwrite a source backup'
    with tarfile.open(pending,'x:gz') as tar:
        for name in sorted(expected): tar.add(base/name,arcname=prefix+name,recursive=False)
    verify_members(pending,expected,prefix)
    check_source(base,expected)
    pending.rename(archive)
    return {'archive':str(archive),'archive_sha256':digest(archive),'sha256':expected,
            'reused':False,'rejected_candidates':rejected}


def prior_proofs(workspaces):
    game, authoring = [], []
    for path in sorted(Path(workspaces).glob('*.snapshot.json'),reverse=True):
        data = json.loads(path.read_text())
        if data.get('archive') and data.get('sha256'):
            game.append({key:data[key] for key in ['archive','sha256','archive_sha256'] if key in data})
        if data.get('authoring_backup'):
            authoring.append(data['authoring_backup'])
    return game, authoring
