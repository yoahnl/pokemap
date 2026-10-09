import hashlib
from bisect import bisect_right
import math
from pathlib import Path
import struct


def unpack(data, offset, fmt):
    size = struct.calcsize(fmt)
    if offset < 0 or offset + size > len(data):
        raise ValueError('Nitro field is outside the source container')
    return struct.unpack_from(fmt, data, offset)


def text_name(data):
    value = data.split(b'\0', 1)[0].decode('ascii')
    if not value:
        raise ValueError('Empty Nitro resource name')
    return value


def dictionary(data, offset, width):
    dummy, count, size = unpack(data, offset, '<BBH')
    if dummy != 0 or size < 12 or offset + size > len(data):
        raise ValueError('Invalid Nitro resource dictionary')
    entries = offset + 12 + count * 4
    actual, names_offset = unpack(data, entries, '<HH')
    if actual != width:
        raise ValueError('Unexpected Nitro resource entry width')
    start = entries + 4
    names = entries + names_offset
    if names < start + count * width or names + count * 16 > offset + size:
        raise ValueError('Invalid Nitro resource name table')
    return [(data[start + i * width:start + (i + 1) * width],
             text_name(data[names + i * 16:names + (i + 1) * 16]))
            for i in range(count)]


def blocks(data):
    if len(data) < 20 or data[4:6] != b'\xff\xfe':
        raise ValueError('Invalid Nitro container signature')
    size, header, count = unpack(data, 8, '<IHH')
    if size != len(data) or header != 16:
        raise ValueError('Invalid Nitro container size')
    result = []
    for offset in unpack(data, 16, '<' + 'I' * count):
        length = unpack(data, offset + 4, '<I')[0]
        if length < 8 or offset + length > len(data):
            raise ValueError('Invalid Nitro block bounds')
        result.append((data[offset:offset + 4], offset))
    return result


def signed(value, bits):
    return value - (1 << bits) if value & (1 << (bits - 1)) else value


def channel_samples(data, base, duration, flags, offset, rotation=False):
    if flags & 0x0fff0000:
        raise ValueError('Unsupported Nitro SRT component flags')
    if flags & 0x20000000:
        return [(0, offset if rotation else signed(offset, 32) / 4096)]
    step = 4 if flags & 0x80000000 else 2 if flags & 0x40000000 else 1
    fmt = '<I' if rotation else '<h' if flags & 0x10000000 else '<i'
    width = struct.calcsize(fmt)
    boundary = flags & 0xffff if step > 1 else duration
    if boundary > duration or boundary % step:
        raise ValueError('Invalid compressed Nitro SRT boundary')
    frames = list(range(0, boundary, step)) + list(range(boundary, duration))
    return [(frame, value if rotation else value / 4096)
            for index, frame in enumerate(frames)
            for value in unpack(data, base + offset + index * width, fmt)]


def interpolate(samples, frame, rotation=False):
    def decode(value):
        return (signed(value & 0xffff, 16) / 4096, signed(value >> 16, 16) / 4096) if rotation else (value,)

    if len(samples) == 1 or frame <= samples[0][0]:
        return decode(samples[0][1])
    if frame >= samples[-1][0]:
        return decode(samples[-1][1])
    index = bisect_right([sample[0] for sample in samples], frame) - 1
    left, a = samples[index]
    right, b = samples[index + 1]
    t = (frame - left) / (right - left)
    return tuple(x + (y - x) * t for x, y in zip(decode(a), decode(b)))


def read_srt(data):
    if data[:4] != b'BTA0':
        raise ValueError('Expected Nitro material animation')
    result = []
    for kind, block in blocks(data):
        if kind != b'SRT0':
            continue
        for entry, name in dictionary(data, block + 8, 4):
            base = block + struct.unpack('<I', entry)[0]
            if data[base:base + 4] != b'M\0AT':
                raise ValueError('Invalid Nitro SRT animation signature')
            duration = unpack(data, base + 4, '<H')[0]
            if duration < 1:
                raise ValueError('Empty Nitro material animation')
            tracks = []
            for raw, material in dictionary(data, base + 8, 40):
                channels = [channel_samples(data, base, duration, *struct.unpack_from('<II', raw, i * 8), rotation=i == 2)
                            for i in range(5)]
                samples = []
                for frame in range(duration):
                    u = interpolate(channels[0], frame)[0]
                    v = interpolate(channels[1], frame)[0]
                    sine, cosine = interpolate(channels[2], frame, rotation=True)
                    tu = interpolate(channels[3], frame)[0]
                    tv = interpolate(channels[4], frame)[0]
                    samples.append([u, v, sine, cosine, tu, tv])
                tracks.append({'material': material, 'samples': samples})
            result.append({'name': name, 'frames': duration, 'tracks': tracks})
    return result


def nitro_affine(sample, mode, width=1, height=1):
    if width <= 0 or height <= 0:
        raise ValueError('Invalid Nitro texture dimensions')
    su, sv, sine, cosine, tu, tv = sample
    if mode == 0:
        a, b, c, d = su * cosine, -sv * sine, su * sine, sv * cosine
        tx = su * (-.5 * cosine - .5 * sine + .5 - tu)
        ty = sv * (-.5 * cosine + .5 * sine - .5 + tv) + 1
    elif mode == 2:
        a, b, c, d = su * cosine, sv * sine, -su * sine, sv * cosine
        tx = -su * cosine * (tu + .5) - su * sine * height / width * (tv - .5) + .5
        ty = -sv * sine * width / height * (tu + .5) + sv * cosine * (tv - .5) + .5
    else:
        raise ValueError('Unsupported Nitro texture matrix mode')
    values = [a, b, c, d, tx, ty]
    if not all(math.isfinite(value) for value in values):
        raise ValueError('Nonfinite Nitro texture matrix')
    return values


def read_model_materials(data):
    result = []
    if data[:4] != b'BMD0':
        raise ValueError('Expected Nitro model')
    for kind, block in blocks(data):
        if kind != b'MDL0':
            continue
        for entry, name in dictionary(data, block + 8, 4):
            base = block + struct.unpack('<I', entry)[0]
            section = base + unpack(data, base + 8, '<I')[0]
            mode = unpack(data, base + 0x16, '<B')[0]
            materials = [material for _, material in dictionary(data, section + 4, 4)]
            result.append({'name': name, 'textureMatrixMode': mode, 'materials': materials})
    return result


def retarget_material_texture(data, model_name, material_name, texture, palette):
    if any(not value or len(value.encode('ascii')) > 16 for value in [texture, palette]):
        raise ValueError('Invalid Nitro texture or palette name')
    output = bytearray(data)
    changes = []
    for kind, block in blocks(data):
        if kind != b'MDL0':
            continue
        for entry, name in dictionary(data, block + 8, 4):
            if name != model_name:
                continue
            base = block + struct.unpack('<I', entry)[0]
            section = base + unpack(data, base + 8, '<I')[0]
            materials = [material for _, material in dictionary(data, section + 4, 4)]
            if material_name not in materials:
                raise ValueError('Target Nitro material is absent from source model')
            material_index = materials.index(material_name)
            for kind, replacement, field in [('texture', texture, 0), ('palette', palette, 2)]:
                offset = section + unpack(data, section + field, '<H')[0]
                entries = dictionary(data, offset, 4)
                table = offset + 12 + len(entries) * 4
                names_offset = table + unpack(data, table + 2, '<H')[0]
                matches = []
                for index, (raw, old_name) in enumerate(entries):
                    indexes, count, _ = struct.unpack('<HBB', raw)
                    bound = unpack(data, section + indexes, '<' + 'B' * count)
                    if material_index in bound:
                        matches.append((index, old_name))
                if len(matches) != 1:
                    raise ValueError('Ambiguous original material texture binding')
                index, old_name = matches[0]
                start = names_offset + index * 16
                output[start:start + 16] = replacement.encode('ascii').ljust(16, b'\0')
                changes.append({'kind': kind, 'from': old_name, 'to': replacement, 'offset': start})
    if len(changes) != 2:
        raise ValueError('Original model texture bindings were not found')
    return bytes(output), changes


def verified_source(root, record):
    paths = record.get('extracted_files', [])
    if not paths or any(Path(name).name != name for name in paths):
        raise ValueError('Invalid extracted Nitro source path')
    data = (root / 'nitro-original' / paths[0]).read_bytes()
    if hashlib.sha256(data).hexdigest() != record['sha256']:
        raise ValueError('Nitro source digest changed after inventory')
    return data
