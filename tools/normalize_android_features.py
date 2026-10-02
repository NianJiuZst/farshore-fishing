"""Correct exactly four string-typed Vulkan values from Godot 4.6.3 APK export.

Pinned upstream source emits strings for required/version in _fix_manifest:
https://github.com/godotengine/godot/blob/4.6.3-stable/platform/android/export/export_plugin.cpp
Android aapt rejects those types. Meanings stay false/1 and true/0x400003; no
features or permissions are added/removed. Run before alignment and signing.
"""
from pathlib import Path
import argparse
import copy
import hashlib
import json
import os
import struct
import zipfile
from derive_android_template import manifest_attributes


def normalize_manifest(raw):
    groups = {}
    for item in manifest_attributes(raw):
        if item['element'] == 'uses-feature':
            groups.setdefault(item['element_offset'], []).append(item)
    expected = {'android.hardware.vulkan.level': {'required': ('false', 0x12, 0), 'version': ('1', 0x10, 1)},
                'android.hardware.vulkan.version': {'required': ('true', 0x12, 0xffffffff), 'version': ('0x400003', 0x11, 0x400003)}}
    found = set()
    changes = []
    output = bytearray(raw)
    for group in groups.values():
        names = [p for p in group if p['name'] == 'name']
        if not names or names[0]['raw_string'] not in expected:
            continue
        assert len(names) == 1 and names[0]['type'] == 3 and names[0]['value'] == names[0]['raw_string_index']
        feature = names[0]['raw_string']
        assert feature not in found, 'Duplicate Vulkan feature'
        found.add(feature)
        assert len(group) == 3 and {p['name'] for p in group} == {'name', 'required', 'version'}
        assert all(p['namespace'] == 'http://schemas.android.com/apk/res/android' for p in group)
        for attribute, (text, new_type, value) in expected[feature].items():
            selected = [p for p in group if p['name'] == attribute]
            assert len(selected) == 1
            old = selected[0]
            assert old['type'] == 3 and old['raw_string'] == text and old['value'] == old['raw_string_index'], 'Unexpected Vulkan type/value; refusing normalization'
            # ResXMLTree_attribute: raw value index, typed-value type and data.
            at = old['offset']
            struct.pack_into('<I', output, at - 8, 0xffffffff)
            output[at - 1] = new_type
            struct.pack_into('<I', output, at, value)
            changes.append({'feature': feature, 'attribute': attribute, 'old_type': 3,
                            'old_string': text, 'old_string_pool_index': old['value'],
                            'new_type': new_type, 'new_value': value, 'data_offset': at})
    assert found == set(expected) and len(changes) == 4, 'Expected exactly two Vulkan features/four values'
    allowed = {c['data_offset'] + n for c in changes for n in [-8,-7,-6,-5,-1,0,1,2,3]}
    actual = [i for i,(a,b) in enumerate(zip(raw, output)) if a != b]
    assert len(output) == len(raw) and set(actual).issubset(allowed)
    # Reversibility proves no hidden change outside the declared four attributes.
    restored = bytearray(output)
    for index in allowed: restored[index] = raw[index]
    assert bytes(restored) == raw
    verified = manifest_attributes(output)
    for change in changes:
        item = next(p for p in verified if p['offset'] == change['data_offset'])
        assert item['raw_string'] is None and item['type'] == change['new_type'] and item['value'] == change['new_value']
    return bytes(output), {'changes': changes, 'changed_byte_offsets': actual,
                           'all_other_manifest_bytes_identical': True, 'reversal_restores_original_manifest': True,
                           'before_sha256': hashlib.sha256(raw).hexdigest(), 'after_sha256': hashlib.sha256(output).hexdigest()}


def raw_copy(source, info, destination):
    assert not info.flag_bits & 1 and info.compress_type in {0, 8}
    source.fp.seek(info.header_offset)
    header = struct.unpack('<IHHHHHIIIHH', source.fp.read(30))
    assert header[0] == 0x04034B50
    source.fp.seek(header[-2] + header[-1], os.SEEK_CUR)
    new = copy.copy(info); new.flag_bits &= ~8; new.header_offset = destination.fp.tell()
    assert max(new.file_size,new.compress_size,new.header_offset) < zipfile.ZIP64_LIMIT
    offset=0
    while offset<len(new.extra):
        kind,length=struct.unpack_from('<HH',new.extra,offset);assert kind!=1;offset+=4+length
    assert offset==len(new.extra)
    destination._writecheck(new);destination._didModify=True
    destination.fp.write(new.FileHeader(False))
    remaining=info.compress_size
    while remaining:
        data=source.fp.read(min(1024*1024,remaining));assert data
        destination.fp.write(data);remaining-=len(data)
    destination.filelist.append(new);destination.NameToInfo[new.filename]=new;destination.start_dir=destination.fp.tell()


def normalize_apk(source, output):
    source, output = Path(source), Path(output)
    assert source.resolve() != output.resolve() and not output.exists()
    hashes = {}
    with zipfile.ZipFile(source) as before, zipfile.ZipFile(output, 'x') as after:
        names=before.namelist();assert len(names)==len(set(names)) and 'AndroidManifest.xml' in names
        assert not any(n.startswith('META-INF/') and n.upper().endswith(('.RSA','.DSA','.EC','.SF')) for n in names), 'Signed input refused'
        before.fp.seek(before.start_dir-16)
        assert before.fp.read(16)!=b'APK Sig Block 42', 'Already-signed APK refused'
        raw=before.read('AndroidManifest.xml');corrected,proof=normalize_manifest(raw)
        for info in before.infolist():
            with before.open(info) as stream: hashes[info.filename]=hashlib.file_digest(stream,'sha256').hexdigest()
            if info.filename=='AndroidManifest.xml':after.writestr(copy.copy(info),corrected)
            else:raw_copy(before,info,after)
    with zipfile.ZipFile(output) as archive:
        assert archive.namelist()==names and archive.testzip() is None
        for name in names:
            with archive.open(name) as stream: got=hashlib.file_digest(stream,'sha256').hexdigest()
            assert got==(proof['after_sha256'] if name=='AndroidManifest.xml' else hashes[name]), 'Unexpected APK member modification'
    proof.update({'upstream_version':'Godot4.6.3.stable.official.7d41c59c4',
                  'upstream_source':'https://github.com/godotengine/godot/blob/4.6.3-stable/platform/android/export/export_plugin.cpp',
                  'apk_member_count':len(names),'only_changed_member':'AndroidManifest.xml',
                  'unchanged_member_sha256':{k:v for k,v in hashes.items() if k!='AndroidManifest.xml'},
                  'permissions_changed':False,'vulkan_requirement_preserved':True})
    return proof


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source',type=Path);parser.add_argument('output',type=Path);parser.add_argument('proof',type=Path)
    args=parser.parse_args();assert not args.proof.exists()
    result=normalize_apk(args.source,args.output)
    args.proof.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({k:v for k,v in result.items() if k!='unchanged_member_sha256'},indent=2))
