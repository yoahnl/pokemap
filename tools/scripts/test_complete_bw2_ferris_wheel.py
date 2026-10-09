import json
import math
from collections import Counter
from pathlib import Path
import unittest

from convert_bw2_door_asset import point
from rigidify_bw2_animation import GlbWriter, accessor_rows, node_worlds, read_glb
from complete_bw2_ferris_wheel import complete_ferris_wheel, primitive_rows, sample_pose


def wheel_fixture():
    d = {'asset': {'version': '2.0'}, 'buffers': [], 'bufferViews': [], 'accessors': [],
         'materials': [{} for _ in range(6)], 'meshes': [], 'nodes': [],
         'scenes': [{'nodes': [0]}], 'scene': 0}
    w = GlbWriter(d, b'')
    d['nodes'] = [{'name': 'world_root', 'children': list(range(1, 11))}]
    template = []
    for material in range(5):
        y = 0 if material == 3 else -.5
        p = [[-.2, y-.1, material*.01], [.2, y-.1, material*.01], [.2, y+.1, material*.01],
             [-.2, y-.1, material*.01], [.2, y+.1, material*.01], [-.2, y+.1, material*.01]]
        template.append({'material': material, 'attributes': {'POSITION': w.rows(p, 'VEC3'),
                         'TEXCOORD_0': w.rows([[i % 2, i % 3] for i in range(6)], 'VEC2')}})
    d['meshes'].append({'primitives': template})
    anchors = []
    for i, name in enumerate(('kago1', 'kago11', 'kago12', 'kago13', 'kago14', 'kago15', 'kago16')):
        angle = math.radians(202.5+i*22.5)
        t = [5*math.cos(angle), 10+5*math.sin(angle), 0]
        anchors.append(t)
        d['nodes'].append({'name': name, 'mesh': 0, 'translation': t})
    for name in ('pCylinder1', 'polySurface20'):
        d['nodes'].append({'name': name, 'translation': [0, 10, 0]})
    fixed = []
    for material, primitive in enumerate(template):
        values = accessor_rows(d, w.binary, primitive['attributes']['POSITION'])
        p = [[v[0]+5*math.cos(math.radians(i*22.5)), v[1]+10+5*math.sin(math.radians(i*22.5)), v[2]]
             for i in range(9) for v in values]
        fixed.append({'material': material, 'attributes': {'POSITION': w.rows(p, 'VEC3'),
                      'TEXCOORD_0': w.rows([[i % 2, i % 3] for i in range(len(p))], 'VEC2')}})
    fixed.append({'material': 5, 'attributes': {'POSITION': w.rows([[0, 0, 0], [1, 0, 0], [0, 1, 0]], 'VEC3')}})
    d['meshes'].append({'primitives': fixed})
    d['nodes'].append({'name': 'polySurface30', 'mesh': 1})
    times = w.rows([[0], [2]], 'SCALAR')
    clip = {'name': 'c04_fwheel_01', 'channels': [], 'samplers': []}
    for node in range(1, 10):
        path = 'translation' if node < 8 else 'rotation'
        values = [anchors[node-1]]*2 if path == 'translation' else [[0, 0, 0, 1], [0, 0, math.sin(-math.pi/16), math.cos(-math.pi/16)]]
        clip['samplers'].append({'input': times, 'output': w.rows(values, 'VEC3' if path == 'translation' else 'VEC4'), 'interpolation': 'LINEAR'})
        clip['channels'].append({'sampler': node-1, 'target': {'node': node, 'path': path}})
    d['animations'] = [clip, {'name': 'door', 'channels': [], 'samplers': []}]
    return w.finish()


def world_triangles(d, b, time):
    worlds = node_worlds(sample_pose(d, b, d['animations'][0], time))
    rows = []
    for node, entry in enumerate(d['nodes']):
        if 'mesh' not in entry:
            continue
        for p in d['meshes'][entry['mesh']]['primitives']:
            pos = accessor_rows(d, b, p['attributes']['POSITION'])
            for start in range(0, len(pos), 3):
                rows.append((p['material'], tuple(tuple(round(v, 5) for v in point(worlds[node], x)) for x in pos[start:start+3])))
    return sorted(rows)


def geometry_attributes(d, b):
    values = Counter()
    for node in d['nodes']:
        if 'mesh' not in node:
            continue
        for primitive in d['meshes'][node['mesh']]['primitives']:
            rows = primitive_rows(d, b, primitive)
            for index in range(len(rows['POSITION'])):
                values[(primitive['material'], tuple((name, tuple(v[index])) for name, v in sorted(rows.items())))] += 1
    return values


class CompleteFerrisWheelTests(unittest.TestCase):
    def test_splits_nine_cabins_and_preserves_start_geometry_and_other_clip(self):
        original = wheel_fixture()
        before, bb = read_glb(original)
        completed, receipt = complete_ferris_wheel(original)
        after, ab = read_glb(completed)
        self.assertEqual(receipt['cabins'], 16)
        self.assertEqual(receipt['staticCabinTriangles'], [10]*9)
        self.assertAlmostEqual(receipt['periodSeconds'], 32, places=5)
        self.assertEqual(after['animations'][1], before['animations'][1])
        self.assertEqual(after['materials'], before['materials'])
        self.assertTrue(ab.startswith(bb))
        self.assertEqual(world_triangles(before, bb, 0), world_triangles(after, ab, 0))
        self.assertEqual(geometry_attributes(before, bb), geometry_attributes(after, ab))
        self.assertEqual(after['meshes'][1]['primitives'], before['meshes'][1]['primitives'][-1:])

    def test_all_cabins_move_upright_and_close_without_seam(self):
        completed, r = complete_ferris_wheel(wheel_fixture())
        d, b = read_glb(completed)
        first = world_triangles(d, b, 0)
        self.assertEqual(first, world_triangles(d, b, r['periodSeconds']))
        for time in (0, 4, 8, 16, 24, 31.9):
            pose = sample_pose(d, b, d['animations'][0], time)
            worlds = node_worlds(pose)
            for node in r['cabinNodes']:
                world = worlds[node]
                self.assertEqual([world[k] for k in (0, 5, 10)], [1, 1, 1])
                self.assertTrue(all(abs(world[row*4+col]) < 1e-8 for row in range(3) for col in range(3) if row != col))
            for index, node in enumerate(r['cabinNodes']):
                translation = pose['nodes'][node].get('translation', [0, 0, 0])
                hinge = translation if index < 7 else [a+b for a, b in zip(translation, r['cabinHingesLocal'][index])]
                self.assertAlmostEqual(math.dist(hinge[:2], r['wheelCenterLocal'][:2]), 5, places=5)
        self.assertNotEqual(first, world_triangles(d, b, 1))
        initial = sample_pose(d, b, d['animations'][0], 0)
        moved = sample_pose(d, b, d['animations'][0], 8)
        for node in r['cabinNodes']:
            self.assertNotEqual(initial['nodes'][node].get('translation'), moved['nodes'][node].get('translation'))

    def test_rejects_ambiguous_geometry_and_repeated_completion(self):
        original = wheel_fixture()
        d, b = read_glb(original)
        d['meshes'][1]['primitives'][0]['attributes']['POSITION'] = d['meshes'][0]['primitives'][0]['attributes']['POSITION']
        with self.assertRaisesRegex(ValueError, 'nine'):
            complete_ferris_wheel(GlbWriter(d, b).finish())
        completed, _ = complete_ferris_wheel(original)
        with self.assertRaisesRegex(ValueError, 'already'):
            complete_ferris_wheel(completed)

    def test_rejects_non_constant_cabin_orientation(self):
        d, b = read_glb(wheel_fixture())
        d['nodes'][1]['rotation'] = [0, 0, .5, .8660254]
        with self.assertRaisesRegex(ValueError, 'identity'):
            complete_ferris_wheel(GlbWriter(d, b).finish())

    def test_authentic_staging_geometry(self):
        path = Path('/Users/karim/Desktop/pokeMap Project/pokemon_nb2/.pokemap/authoring/animation-repair-20261010/animation_application.json')
        if not path.is_file():
            self.skipTest('Authentic BW2 source staging is unavailable')
        e = next(e for e in json.loads(path.read_text())['entries'] if e['modelId'] == 'unys-meanville-02-object-0014')
        before, bb = read_glb(Path(e['sourcePath']).read_bytes())
        completed, r = complete_ferris_wheel(Path(e['sourcePath']).read_bytes())
        after, ab = read_glb(completed)
        self.assertEqual(r['staticCabinTriangles'], [78]*9)
        self.assertEqual(r['triangleCount'], 2144)
        self.assertEqual(world_triangles(before, bb, 0), world_triangles(after, ab, 0))
        self.assertEqual(geometry_attributes(before, bb), geometry_attributes(after, ab))
        self.assertEqual(world_triangles(after, ab, 0), world_triangles(after, ab, r['periodSeconds']))
        self.assertGreater(r['periodSeconds'], 30)
        self.assertLess(r['periodSeconds'], 30.2)


if __name__ == '__main__':
    unittest.main()
