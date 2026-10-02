"""Derive an audited ARM64 template without rebuilding or changing native code.

The official 4.6.3 template already targets API36. Its manifest minimum is raised
24 -> 29 and extractNativeLibs is disabled, while exact .so bytes become STORED.
All final APK gates remain required. Recovered code must be retested after reset.
"""
from pathlib import Path
import argparse
import copy
import hashlib
import json
import struct
import zipfile

OFFICIAL_TEMPLATE_SHA256 = 'e91ef7e517e73aec1ddcc4c455c5fd53de1837c240a7c520ac438b73874b54c1'


def string_pool(raw, offset):
    kind, header, size = struct.unpack_from('<HHI', raw, offset)
    assert kind == 1 and header == 28
    count, styles, flags, start, _ = struct.unpack_from('<IIIII', raw, offset + 8)
    utf8 = bool(flags & 0x100)
    def length(at, width):
        if width == 1:
            first = raw[at]
            return (((first & 0x7f) << 8) | raw[at + 1], at + 2) if first & 0x80 else (first, at + 1)
        first = struct.unpack_from('<H', raw, at)[0]
        return (((first & 0x7fff) << 16) | struct.unpack_from('<H', raw, at + 2)[0], at + 4) if first & 0x8000 else (first, at + 2)
    result = []
    for index in range(count):
        at = offset + start + struct.unpack_from('<I', raw, offset + header + index * 4)[0]
        chars, at = length(at, 1 if utf8 else 2)
        if utf8:
            byte_count, at = length(at, 1)
            result.append(bytes(raw[at:at + byte_count]).decode('utf-8'))
        else:
            result.append(bytes(raw[at:at + chars * 2]).decode('utf-16le'))
    return result


def manifest_attributes(raw):
    kind, header, size = struct.unpack_from('<HHI', raw, 0)
    assert kind == 3 and header == 8 and size == len(raw)
    offset, strings, found = header, None, []
    while offset < len(raw):
        kind, header, size = struct.unpack_from('<HHI', raw, offset)
        assert size >= header >= 8 and offset + size <= len(raw)
        if kind == 1:
            assert strings is None
            strings = string_pool(raw, offset)
        elif kind == 0x102:
            assert header == 16 and strings
            extension = offset + header
            _, element, attr_start, attr_size, count = struct.unpack_from('<IIHHH', raw, extension)
            assert attr_size == 20
            for index in range(count):
                at = extension + attr_start + index * attr_size
                namespace, name, value, typed_size, zero, typ, data = struct.unpack_from('<IIIHBBI', raw, at)
                assert typed_size == 8 and zero == 0
                found.append({'element': strings[element], 'element_offset': offset, 'name': strings[name],
                              'namespace': strings[namespace] if namespace != 0xffffffff else '',
                              'raw_string': strings[value] if value != 0xffffffff else None,
                              'raw_string_index': value,
                              'type': typ, 'value': data, 'offset': at + 16})
        offset += size
    assert offset == len(raw)
    return found


def patch_manifest(raw):
    attributes = manifest_attributes(raw)
    changes = [('uses-sdk', 'minSdkVersion', 0x10, 24, 29),
               ('application', 'extractNativeLibs', 0x12, 0xffffffff, 0)]
    target = [p for p in attributes if p['element'] == 'uses-sdk' and p['name'] == 'targetSdkVersion']
    assert len(target) == 1 and target[0]['value'] == 36
    result = bytearray(raw)
    proof = []
    for element, name, typ, before, after in changes:
        selected = [p for p in attributes if p['element'] == element and p['name'] == name]
        assert len(selected) == 1, 'Missing/duplicate manifest attribute: ' + name
        item = selected[0]
        assert item['type'] == typ and item['value'] == before and item['raw_string'] is None
        assert item['namespace'] == 'http://schemas.android.com/apk/res/android'
        struct.pack_into('<I', result, item['offset'], after)
        proof.append({'element': element, 'attribute': name, 'byte_offset': item['offset'], 'before': before, 'after': after})
    expected_offsets = {c['byte_offset'] + n for c in proof for n in range(4)}
    assert all(a == b or index in expected_offsets for index, (a, b) in enumerate(zip(raw, result)))
    return bytes(result), proof


def derive(source, output):
    source, output = Path(source), Path(output)
    assert not output.exists()
    proof = {'official_template_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
             'source_template': source.name, 'abi': 'arm64-v8a', 'unchanged_members': {}, 'native_members': {}, 'omitted_other_abi_members': []}
    assert proof['official_template_sha256'] == OFFICIAL_TEMPLATE_SHA256, 'Only the verified official pinned template is accepted'
    with zipfile.ZipFile(source) as before, zipfile.ZipFile(output, 'x') as after:
        assert before.testzip() is None
        for info in before.infolist():
            if info.filename.startswith('lib/') and not info.filename.startswith('lib/arm64-v8a/'):
                proof['omitted_other_abi_members'].append(info.filename)
                continue
            data = before.read(info)
            new = copy.copy(info)
            if info.filename == 'AndroidManifest.xml':
                data, proof['manifest_changes'] = patch_manifest(data)
                proof['original_manifest_sha256'] = hashlib.sha256(before.read(info)).hexdigest()
                proof['derived_manifest_sha256'] = hashlib.sha256(data).hexdigest()
            else:
                proof['unchanged_members'][info.filename] = hashlib.sha256(data).hexdigest()
            if info.filename.startswith('lib/') and info.filename.endswith('.so'):
                assert data[:6] == b'\x7fELF\x02\x01'
                new.compress_type = zipfile.ZIP_STORED
                proof['native_members'][info.filename] = {'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data), 'compression': 0}
            after.writestr(new, data)
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
        for name, expected in proof['unchanged_members'].items():
            assert hashlib.sha256(archive.read(name)).hexdigest() == expected
        for name in proof['native_members']:
            assert archive.getinfo(name).compress_type == zipfile.ZIP_STORED
        with zipfile.ZipFile(source) as original:
            assert archive.read('AndroidManifest.xml') == patch_manifest(original.read('AndroidManifest.xml'))[0]
    assert len(proof['native_members']) == 2
    proof['derived_template_sha256'] = hashlib.sha256(output.read_bytes()).hexdigest()
    return proof


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('proof', type=Path)
    args = parser.parse_args()
    proof = derive(args.source, args.output)
    assert not args.proof.exists()
    args.proof.write_text(json.dumps(proof, indent=2) + '\n')
    print(json.dumps({k: v for k, v in proof.items() if k not in {'unchanged_members', 'omitted_other_abi_members'}}, indent=2))
