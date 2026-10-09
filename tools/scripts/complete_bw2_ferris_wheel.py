import argparse
from bisect import bisect_right
from collections import Counter, defaultdict
from copy import deepcopy
from hashlib import sha256
import json
import math
from pathlib import Path
import struct

from convert_bw2_door_asset import IDENTITY, point, slerp
from rigidify_bw2_animation import GlbWriter, accessor_rows, node_local, read_glb


CABIN_NAMES = ('kago1', 'kago11', 'kago12', 'kago13', 'kago14', 'kago15', 'kago16')


def sample_pose(document, binary, clip, time):
    pose = deepcopy(document)
    for channel in clip['channels']:
        sampler = clip['samplers'][channel['sampler']]
        if sampler.get('interpolation', 'LINEAR') not in ('LINEAR', 'STEP'):
            raise ValueError('Unsupported wheel interpolation')
        times = [row[0] for row in accessor_rows(document, binary, sampler['input'])]
        values = accessor_rows(document, binary, sampler['output'])
        if len(times) != len(values) or not times:
            raise ValueError('Animation sample counts disagree')
        left = max(0, min(bisect_right(times, time)-1, len(times)-1))
        value = values[left]
        if left < len(times)-1 and time > times[left] and sampler.get('interpolation', 'LINEAR') != 'STEP':
            amount = (time-times[left])/(times[left+1]-times[left])
            if channel['target']['path'] == 'rotation':
                value = slerp(value, values[left+1], amount)
            else:
                value = [a+(b-a)*amount for a, b in zip(value, values[left+1])]
        pose['nodes'][channel['target']['node']][channel['target']['path']] = value
    return pose


def primitive_rows(document, binary, primitive):
    if primitive.get('mode', 4) != 4:
        raise ValueError('Wheel geometry must use triangles')
    rows = {name: accessor_rows(document, binary, index) for name, index in primitive['attributes'].items()}
    indices = [row[0] for row in accessor_rows(document, binary, primitive['indices'])] if 'indices' in primitive else range(len(rows['POSITION']))
    if len(indices) % 3:
        raise ValueError('Wheel triangle count is invalid')
    return {name: [values[index] for index in indices] for name, values in rows.items()}


def face_centers(rows):
    parents = list(range(len(rows)//3))

    def root(index):
        while parents[index] != index:
            index = parents[index]
        return index

    welded = {}
    for index, position in enumerate(rows):
        key = tuple(round(value, 6) for value in position)
        if key in welded:
            parents[root(index//3)] = root(welded[key])
        welded[key] = index//3
    groups = defaultdict(list)
    for index, position in enumerate(rows):
        groups[root(index//3)].append(position)
    if len(groups) != 9 or any(len(values) != 6 for values in groups.values()):
        raise ValueError('Expected nine separate static cabin faces')
    return [[(min(p[axis] for p in values)+max(p[axis] for p in values))/2 for axis in range(3)]
            for values in groups.values()]


def z_angle(rotation):
    if abs(rotation[0])+abs(rotation[1]) > 1e-6:
        raise ValueError('Wheel rotor must rotate around Z')
    return 2*math.atan2(rotation[2], rotation[3])


def complete_ferris_wheel(source_glb, animation_index=0):
    source, binary = read_glb(source_glb)
    if source.get('extras', {}).get('aveluneWheelCompletion'):
        raise ValueError('Wheel is already complete')
    clip = source['animations'][animation_index]
    if clip['name'] != 'c04_fwheel_01':
        raise ValueError('Expected the authentic c04_fwheel_01 clip')
    names = {node.get('name'): index for index, node in enumerate(source['nodes'])}
    if any(sum(node.get('name') == name for node in source['nodes']) != 1 for name in (*CABIN_NAMES, 'world_root', 'polySurface30', 'pCylinder1', 'polySurface20')):
        raise ValueError('Wheel joint names are missing or ambiguous')
    cabins = [names[name] for name in CABIN_NAMES]
    fixed_node = names['polySurface30']
    parent = names['world_root']
    if not all(node in source['nodes'][parent].get('children', []) for node in cabins+[fixed_node, names['pCylinder1'], names['polySurface20']]):
        raise ValueError('Wheel parts must share the native parent')
    initial = sample_pose(source, binary, clip, 0)
    if max(abs(a-b) for a, b in zip(node_local(initial['nodes'][fixed_node]), IDENTITY)) > 1e-7:
        raise ValueError('Static wheel geometry must use the native identity transform')
    for node in cabins:
        rotation = initial['nodes'][node].get('rotation', [0, 0, 0, 1])
        if max(abs(a-b) for a, b in zip(rotation, [0, 0, 0, 1])) > 1e-7:
            raise ValueError('Cabin source orientation must be identity')
    channels = {(channel['target']['node'], channel['target']['path']): channel for channel in clip['channels']}
    if len(channels) != len(clip['channels']):
        raise ValueError('Wheel animation has duplicate targets')
    duration = max(row[0] for sampler in clip['samplers'] for row in accessor_rows(source, binary, sampler['input']))
    for node in cabins:
        for path in ('rotation', 'scale'):
            channel = channels.get((node, path))
            if channel is None:
                continue
            sampler = clip['samplers'][channel['sampler']]
            values = accessor_rows(source, binary, sampler['output'])
            if any(max(abs(a-b) for a, b in zip(value, values[0])) > 1e-7 for value in values):
                raise ValueError('Cabin source orientation and scale must stay constant identity or authored scale')
    for node in (parent, fixed_node, names['pCylinder1'], names['polySurface20']):
        for path in ('translation', 'rotation', 'scale'):
            if path == 'rotation' and node in (names['pCylinder1'], names['polySurface20']):
                continue
            channel = channels.get((node, path))
            if channel is None:
                continue
            sampler = clip['samplers'][channel['sampler']]
            values = accessor_rows(source, binary, sampler['output'])
            if any(max(abs(a-b) for a, b in zip(value, values[0])) > 1e-7 for value in values):
                raise ValueError('Wheel reference parent, base, and rotor pivots must stay constant')
    reference = []
    for node in (names['pCylinder1'], names['polySurface20']):
        sampler = clip['samplers'][channels[node, 'rotation']['sampler']]
        times = [row[0] for row in accessor_rows(source, binary, sampler['input'])]
        values = accessor_rows(source, binary, sampler['output'])
        angles = [z_angle(value) for value in values]
        delta = sum(math.remainder(b-a, 2*math.pi) for a, b in zip(angles, angles[1:]))
        if not 0 < abs(delta) < math.pi or times[0] != 0 or times[-1] <= 0:
            raise ValueError('Wheel reference rotation interval is invalid')
        reference.append((node, values[0], delta, times[-1]))
    if abs(reference[0][2]-reference[1][2]) > 1e-6 or reference[0][3] != reference[1][3]:
        raise ValueError('Wheel rotors do not share their source cadence')
    delta = reference[0][2]
    period = struct.unpack('<f', struct.pack('<f', duration*2*math.pi/abs(delta)))[0]
    steps = math.ceil(period*60)
    times = [period*index/steps for index in range(steps+1)]
    direction = math.copysign(1, delta)
    center = initial['nodes'][names['pCylinder1']]['translation']
    fixed_mesh = source['nodes'][fixed_node]['mesh']
    fixed_primitives = source['meshes'][fixed_mesh]['primitives']
    front = [primitive for primitive in fixed_primitives if primitive.get('material') == 0]
    if len(front) != 1:
        raise ValueError('Expected nine static faces in one material primitive')
    centers = face_centers(primitive_rows(source, binary, front[0])['POSITION'])
    grouped = [[] for _ in centers]
    counters = [Counter() for _ in centers]
    kept = []
    for primitive in fixed_primitives:
        if primitive.get('material') not in range(5):
            kept.append(deepcopy(primitive))
            continue
        rows = primitive_rows(source, binary, primitive)
        partitions = defaultdict(list)
        for start in range(0, len(rows['POSITION']), 3):
            owners = {min(range(9), key=lambda index: sum((position[axis]-centers[index][axis])**2 for axis in (0, 1)))
                      for position in rows['POSITION'][start:start+3]}
            if len(owners) != 1:
                raise ValueError('Static cabin triangle has ambiguous spatial ownership')
            owner = owners.pop()
            partitions[owner].extend(range(start, start+3))
            counters[owner][primitive['material']] += 1
        for owner, indices in partitions.items():
            grouped[owner].append((primitive, {name: [values[index] for index in indices] for name, values in rows.items()}))
    if any(counter != counters[0] or set(counter) != set(range(5)) for counter in counters):
        raise ValueError('Static cabins do not share complete material geometry')
    template = next(primitive for primitive in source['meshes'][source['nodes'][cabins[1]]['mesh']]['primitives'] if primitive.get('material') == 3)
    transform = node_local(initial['nodes'][cabins[1]])
    positions = [point(transform, position) for position in primitive_rows(source, binary, template)['POSITION']]
    template_anchor = initial['nodes'][cabins[1]]['translation']
    offset = [sum(position[axis] for position in positions)/len(positions)-template_anchor[axis] for axis in range(3)]
    anchors = []
    for group in grouped:
        positions = [position for primitive, rows in group if primitive['material'] == 3 for position in rows['POSITION']]
        anchors.append([sum(position[axis] for position in positions)/len(positions)-offset[axis] for axis in range(3)])
    all_anchors = [initial['nodes'][node]['translation'] for node in cabins]+anchors
    radii = [math.dist(anchor[:2], center[:2]) for anchor in all_anchors]
    if min(radii) <= 0 or max(radii)-min(radii) > max(radii)*.02:
        raise ValueError('Cabin hinge positions do not follow the native wheel radius')
    output = deepcopy(source)
    writer = GlbWriter(output, binary)
    output_clip = output['animations'][animation_index]
    time_accessor = writer.rows([[time] for time in times], 'SCALAR')

    def replace_channel(node, path, values):
        channel = next((channel for channel in output_clip['channels'] if channel['target'] == {'node': node, 'path': path}), None)
        sampler = {'input': time_accessor, 'output': writer.rows(values, 'VEC4' if path == 'rotation' else 'VEC3'), 'interpolation': 'LINEAR'}
        output_clip['samplers'].append(sampler)
        if channel is None:
            channel = {'target': {'node': node, 'path': path}}
            output_clip['channels'].append(channel)
        channel['sampler'] = len(output_clip['samplers'])-1

    def orbit(anchor):
        values = []
        x, y = anchor[0]-center[0], anchor[1]-center[1]
        for time in times:
            angle = direction*2*math.pi*time/period
            values.append([center[0]+x*math.cos(angle)-y*math.sin(angle), center[1]+x*math.sin(angle)+y*math.cos(angle), anchor[2]])
        values[0] = list(anchor)
        values[-1] = list(anchor)
        return values

    for node in cabins:
        output['nodes'][node].update({path: initial['nodes'][node].get(path, fallback)
                                      for path, fallback in (('translation', [0, 0, 0]), ('rotation', [0, 0, 0, 1]), ('scale', [1, 1, 1]))})
        replace_channel(node, 'translation', orbit(initial['nodes'][node]['translation']))
    output['meshes'][fixed_mesh]['primitives'] = kept
    for index, (group, anchor) in enumerate(zip(grouped, anchors)):
        primitives = []
        for primitive, rows in group:
            converted = deepcopy(primitive)
            converted.pop('indices', None)
            converted['attributes'] = {name: writer.rows(values, 'VEC'+str(len(values[0]))) for name, values in rows.items()}
            primitives.append(converted)
        output['meshes'].append({'primitives': primitives})
        node = len(output['nodes'])
        output['nodes'].append({'name': f'kago_static_{index+1:02}', 'mesh': len(output['meshes'])-1})
        output['nodes'][parent]['children'].append(node)
        cabins.append(node)
        replace_channel(node, 'translation', [[value[axis]-anchor[axis] for axis in range(3)] for value in orbit(anchor)])
    for node, first, _, _ in reference:
        angle = z_angle(first)
        values = [[0, 0, math.sin((angle+direction*2*math.pi*time/period)/2), math.cos((angle+direction*2*math.pi*time/period)/2)] for time in times]
        values[0] = first
        values[-1] = [-value for value in first]
        replace_channel(node, 'rotation', values)
    triangle_count = sum(len(primitive_rows(output, writer.binary, primitive)['POSITION'])//3
                         for node in output['nodes'] if 'mesh' in node for primitive in output['meshes'][node['mesh']]['primitives'])
    source_triangle_count = sum(len(primitive_rows(source, binary, primitive)['POSITION'])//3
                                for node in source['nodes'] if 'mesh' in node for primitive in source['meshes'][node['mesh']]['primitives'])
    if triangle_count != source_triangle_count:
        raise ValueError('Wheel completion changed its geometry count')
    receipt = {'cabins': 16, 'cabinNodes': cabins, 'staticCabinTriangles': [sum(counter.values()) for counter in counters],
               'triangleCount': triangle_count, 'periodSeconds': period, 'sourcePeriodSeconds': duration,
               'sourceAngularDeltaDegrees': math.degrees(delta), 'keyframes': len(times),
               'staticCabinMaterialTriangles': dict(counters[0]), 'cabinHingesLocal': all_anchors,
               'wheelCenterLocal': center, 'hingePolicy': 'Static cabin connector centroids use the source animated cabin connector offset',
               'cadenceEvidence': 'Full cycle derived from source GLB angular delta and timeline duration; not a measured Nintendo full-wheel cycle',
               'sourceSha256': sha256(source_glb).hexdigest(), 'sourceClipIndex': animation_index}
    output.setdefault('extras', {})['aveluneWheelCompletion'] = receipt
    return writer.finish(), receipt


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--receipt', type=Path, required=True)
    args = parser.parse_args()
    completed, receipt = complete_ferris_wheel(args.source.read_bytes())
    receipt['sha256After'] = sha256(completed).hexdigest()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(completed)
    args.receipt.write_text(json.dumps(receipt, indent=2)+'\n')
    print(json.dumps(receipt, indent=2))


if __name__ == '__main__':
    main()
