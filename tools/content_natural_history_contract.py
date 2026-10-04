"""Bind all74 offline encyclopedia facts to frozen source and exported bytes.

This is a schema, reference-integrity and packaging gate. It does not establish
the scientific truth of cited claims or decompile exported GDScript.
"""
from datetime import date
from pathlib import Path, PurePosixPath
import json
import math
import re
from urllib.parse import urlsplit

from content_fish_art_contract import local_resource, read_source, sha256

MODULE = 'scripts/fish_natural_history.gd'
DATA_FILES = tuple(f'data/encyclopedia_{part}.json' for part in 'abcdef')
DIVERSITY_DATA_FILES = tuple(f'data/encyclopedia_{part}.json' for part in 'abcdefgh') + ('data/encyclopedia_whale.json',)
TEXT_FIELDS = ('typical_size', 'habitat', 'distribution', 'behavior', 'diet')


def strict_json(raw):
    def unique_object(pairs):
        value = {}
        for key, item in pairs:
            assert key not in value, 'Duplicate encyclopedia JSON property: ' + key
            value[key] = item
        return value

    def invalid_constant(value):
        raise AssertionError('Non-finite encyclopedia JSON number: ' + value)

    return json.loads(raw, object_pairs_hook=unique_object, parse_constant=invalid_constant)


def nonempty_text(value):
    return isinstance(value, str) and bool(value.strip())


def safe_source_url(value):
    if not isinstance(value, str) or not value.startswith('https://') or len(value) > 2048:
        return False
    if '\\' in value or any(char.isspace() or ord(char) < 32 or ord(char) == 127 for char in value):
        return False
    try:
        parsed = urlsplit(value)
    except ValueError:
        return False
    # Only ordinary HTTPS DNS names, without credentials, ports or escapes.
    labels = parsed.netloc.split('.')
    return len(labels) >= 2 and all(re.fullmatch(r'[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?', label) for label in labels)


def validate_entry(entry):
    assert isinstance(entry, dict), 'Encyclopedia entry must be an object'
    species = entry.get('species_id')
    assert isinstance(species, str) and re.fullmatch(r'[a-z][a-z0-9_]*', species), 'Invalid encyclopedia species ID'
    name = entry.get('accepted_scientific_name')
    assert isinstance(name, str) and re.fullmatch(r'[A-Z][a-z]+ [a-z][a-z-]+', name), 'Accepted scientific name must be a binomial: ' + species
    sources = entry.get('sources')
    assert isinstance(sources, list) and len(sources) >= 2, 'At least two encyclopedia sources required: ' + species
    source_ids = set()
    for source in sources:
        assert isinstance(source, dict), 'Encyclopedia source must be an object: ' + species
        identifier = source.get('id')
        assert isinstance(identifier, str) and re.fullmatch(r'[A-Za-z][A-Za-z0-9_-]*', identifier) and identifier not in source_ids, 'Missing/duplicate/invalid encyclopedia source ID: ' + species
        source_ids.add(identifier)
        for field in ('title', 'publisher', 'accessed'):
            assert nonempty_text(source.get(field)), 'Missing encyclopedia source ' + field + ': ' + species
        accessed = source['accessed']
        assert re.fullmatch(r'\d{4}-\d{2}-\d{2}', accessed), 'Source access date must be ISO YYYY-MM-DD: ' + species
        try:
            date.fromisoformat(accessed)
        except ValueError as error:
            raise AssertionError('Invalid source access date: ' + species) from error
        assert safe_source_url(source.get('url')), 'Unsafe encyclopedia source URL: ' + species

    def field_with_refs(key, text_fields=('text',)):
        field = entry.get(key)
        assert isinstance(field, dict), 'Missing encyclopedia field ' + key + ': ' + species
        for text_field in text_fields:
            assert nonempty_text(field.get(text_field)), 'Missing encyclopedia ' + key + '.' + text_field + ': ' + species
        refs = field.get('source_ids')
        assert isinstance(refs, list) and refs and all(isinstance(ref, str) and ref in source_ids for ref in refs), 'Missing/undefined encyclopedia field sources for ' + key + ': ' + species
        assert len(refs) == len(set(refs)), 'Duplicate encyclopedia field source for ' + key + ': ' + species
        return field

    taxonomy = field_with_refs('taxonomy', ('family_scientific', 'family_zh', 'genus_scientific', 'genus_zh'))
    assert re.fullmatch(r'[A-Z][a-z]+', taxonomy['genus_scientific']), 'Invalid accepted genus: ' + species
    assert name.split(' ')[0] == taxonomy['genus_scientific'], 'Accepted scientific name and genus differ: ' + species
    assert re.fullmatch(r'[A-Z][a-z]+', taxonomy['family_scientific']), 'Invalid scientific family: ' + species
    if 'note' in taxonomy:
        assert nonempty_text(taxonomy['note']), 'Invalid taxonomy note: ' + species
    for key in TEXT_FIELDS:
        field_with_refs(key)
    for key, unit in (('max_length', 'value_cm'), ('max_weight', 'value_kg')):
        field = field_with_refs(key)
        assert unit in field, 'Missing encyclopedia measurement ' + unit + ': ' + species
        value = field[unit]
        assert value is None or (type(value) in (int, float) and value > 0 and (type(value) is int or math.isfinite(value))), 'Encyclopedia maximum must be a positive finite number or null: ' + species
        if key == 'max_length':
            assert field.get('length_type') in ('TL', 'FL', 'SL', 'unspecified'), 'Unknown encyclopedia length convention: ' + species
        if 'record_label' in field:
            assert nonempty_text(field['record_label']), 'Scoped encyclopedia record_label must be nonempty text: ' + species
    field_with_refs('story', ('title', 'text'))


def canonical_species_ids(project):
    loader = read_source(project, 'scripts/catalog.gd').decode('utf-8')
    files = list(dict.fromkeys(re.findall(r'"(fish_[a-z0-9_]+\.json)"', loader)))
    assert files, 'No authoritative fish catalog files found for encyclopedia'
    entries = []
    for filename in files:
        payload = strict_json(read_source(project, 'data/' + filename))
        assert isinstance(payload, list), 'Fish catalog must be a JSON array'
        entries.extend(payload)
    assert all(isinstance(entry, dict) and isinstance(entry.get('species_id'), str) for entry in entries), 'Invalid canonical fish entries'
    return [entry['species_id'] for entry in entries]


def natural_history_contract(project, species_ids=None):
    project = Path(project)
    ids = canonical_species_ids(project) if species_ids is None else species_ids
    expected_count = 111 if 'blue_whale' in ids else 74
    data_files = DIVERSITY_DATA_FILES if expected_count == 111 else DATA_FILES
    assert isinstance(ids, (list, tuple)) and all(isinstance(value, str) for value in ids) and len(ids) == len(set(ids)) == expected_count, 'Exact canonical species IDs required for encyclopedia'
    module = read_source(project, MODULE)
    file_list = re.findall(r'^const FILES:\s*Array\[String\]\s*=\s*\[(.*?)\]', module.decode('utf-8'), re.M | re.S)
    assert len(file_list) == 1 and re.findall(r'"([^"]+)"', file_list[0]) == ['res://' + path for path in data_files], 'Natural-history module must load exactly the canonical encyclopedia files'
    actual_files = {str(path.relative_to(project)) for path in (project/'data').glob('encyclopedia_*.json')}
    assert actual_files == set(data_files), 'Unexpected encyclopedia JSON files'
    hashes = {MODULE: sha256(module)}
    entries = []
    file_counts = {}
    for relative in data_files:
        raw = read_source(project, relative)
        payload = strict_json(raw)
        assert isinstance(payload, dict) and type(payload.get('schema_version')) is int and payload['schema_version'] == 1, 'Unsupported encyclopedia schema: ' + relative
        assert isinstance(payload.get('entries'), list) and payload['entries'], 'Missing encyclopedia entries: ' + relative
        for entry in payload['entries']:
            validate_entry(entry)
        entries.extend(payload['entries'])
        file_counts[relative] = len(payload['entries'])
        hashes[relative] = sha256(raw)
    actual_ids = [entry['species_id'] for entry in entries]
    assert len(actual_ids) == len(set(actual_ids)) == expected_count and set(actual_ids) == set(ids), 'Encyclopedia must cover exactly all canonical animals once'
    return {'schema_version': 1, 'species_count': expected_count, 'species_ids': sorted(ids),
            'module': MODULE, 'data_files': list(data_files), 'file_entry_counts': file_counts,
            'resource_sha256': hashes,
            'scope': 'All canonical animal entries; schema, safe source URLs, field references and accepted-name/genus consistency; factual review and runtime evidence remain separate'}


def require_natural_history_archive_members(root, files, contract=None):
    root = Path(root)
    project = root/'game'
    settings = project/'project.godot'
    formal = settings.is_file() and re.search(r'^config/version="1\.(?:2|3)\.0"\s*$', settings.read_text(), re.M)
    present = (project/MODULE).exists() or any((project/'data').glob('encyclopedia_*.json'))
    if contract is None and not formal and not present:
        return {}  # Generic regression projects and pre-encyclopedia releases.
    if contract is None:
        contract = natural_history_contract(project)
    required = {'game/' + path: value for path, value in contract['resource_sha256'].items()}
    assert set(required).issubset(files), 'Source archive omits required encyclopedia inputs: ' + ', '.join(sorted(set(required) - set(files)))
    for path, expected in required.items():
        assert files[path].get('sha256') == expected and sha256(read_source(root, path)) == expected, 'Archived encyclopedia source differs: ' + path
    return required


def verify_exported_natural_history(archive, contract, prefix='assets/'):
    names = archive.namelist()
    assert len(names) == len(set(names)), 'Duplicate archive members are forbidden'
    data_files = tuple(contract['data_files'])
    wanted = set(data_files)
    actual = {name[len(prefix):] for name in names if name.startswith(prefix) and re.fullmatch(r'data/encyclopedia_.*\.json(?:\.remap)?', name[len(prefix):])}
    assert actual == wanted, 'Export must contain exactly six unremapped encyclopedia JSON payloads'

    def read(relative):
        assert prefix + relative in names, 'Missing exported encyclopedia resource: ' + relative
        return archive.read(prefix + relative)

    hashes = contract['resource_sha256']
    for relative in data_files:
        assert sha256(read(relative)) == hashes[relative], 'Exported encyclopedia data differs from frozen source: ' + relative
    direct = prefix + MODULE in names
    remapped = prefix + MODULE + '.remap' in names
    assert direct != remapped, 'Encyclopedia module must have exactly one source or compiled remap representation'
    if direct:
        target = MODULE
        assert prefix + str(PurePosixPath(MODULE).with_suffix('.gdc')) not in names, 'Ambiguous exported encyclopedia module'
        assert sha256(read(target)) == hashes[MODULE], 'Exported encyclopedia module source differs from frozen source'
    else:
        mapping = read(MODULE + '.remap').decode('utf-8')
        matches = re.findall(r'^path="(res://[^"]+)"\s*$', mapping, re.M)
        assert len(matches) == 1, 'Invalid encyclopedia module remap'
        target = local_resource(matches[0])
        assert target == str(PurePosixPath(MODULE).with_suffix('.gdc')), 'Unexpected encyclopedia module target'
        assert read(target).startswith(b'GDSC') and len(read(target)) > 4, 'Invalid compiled encyclopedia module'
    return {'species_count': contract['species_count'], 'data_files': list(data_files),
            'data_payload_sha256': {path: hashes[path] for path in DATA_FILES},
            'module_resource': MODULE, 'module_export_target': target,
            'module_source_sha256': hashes[MODULE], 'module_payload_sha256': sha256(read(target)),
            'exact_frozen_json_bytes': True,
            'scope': 'Exact frozen JSON bytes and required source or matching compiled module; scientific and runtime validation remain separate'}


if __name__ == '__main__':
    import argparse
    import zipfile
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('project', type=Path)
    parser.add_argument('--archive', type=Path)
    parser.add_argument('--prefix', default='assets/')
    args = parser.parse_args()
    result = natural_history_contract(args.project)
    if args.archive:
        with zipfile.ZipFile(args.archive) as archive:
            result['export'] = verify_exported_natural_history(archive, result, args.prefix)
    print(json.dumps(result, indent=2))
