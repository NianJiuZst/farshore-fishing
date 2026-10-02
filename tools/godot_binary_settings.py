"""Read scalar settings from Godot4 ECFG; safely skip other serialized Variants.

Format: official4.6.3 core/config/project_settings.cpp::_save_settings_binary.
String/bool encoding: core/io/marshalls.cpp encode_variant.
"""
import struct


def scalar_settings(raw):
    assert raw[:4] == b'ECFG', 'Expected Godot project.binary ECFG header'
    count = struct.unpack_from('<I', raw, 4)[0]
    offset = 8
    result = {}
    for _ in range(count):
        size = struct.unpack_from('<I', raw, offset)[0]; offset += 4
        key = raw[offset:offset+size].decode('utf-8'); offset += size
        size = struct.unpack_from('<I', raw, offset)[0]; offset += 4
        value = raw[offset:offset+size]; offset += size
        assert len(value) == size and size >= 4, 'Truncated ECFG Variant'
        kind = struct.unpack_from('<I', value)[0] & 0xffff
        if kind == 1:
            result[key] = bool(struct.unpack_from('<I', value, 4)[0])
        elif kind == 2:
            wide = bool(struct.unpack_from('<I', value)[0] & (1 << 16))
            result[key] = struct.unpack_from('<q' if wide else '<i', value, 4)[0]
        elif kind == 4:
            length = struct.unpack_from('<I', value, 4)[0]
            result[key] = value[8:8+length].decode('utf-8')
    assert offset == len(raw), 'Unexpected ECFG trailing bytes'
    return result
