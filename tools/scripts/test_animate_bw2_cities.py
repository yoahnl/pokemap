from collections import defaultdict
from copy import deepcopy
from io import BytesIO
from pathlib import Path
import json
from hashlib import sha256
from tempfile import TemporaryDirectory
from types import SimpleNamespace
from unittest.mock import patch
from bisect import bisect_right
import sys
import unittest
import zipfile

from PIL import Image

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

import animate_bw2_cities as city_converter
from animate_bw2_cities import add_pattern_animations, animated_material_document, audit_staged_coverage, choose_track, combine_pattern_transform_tracks, configure_joint_playback, glb_bytes, material_identity, merge_joint_animations, merge_staged_door_index, model_names, read_glb, run, split_animated_materials
from rigidify_bw2_animation import GlbWriter, accessor_rows


class SourceFixture:
    def __init__(self):
        self.by_material = defaultdict(list)
        self.by_material['water'] = [{'material': 'water', 'clip': 'map01_02', 'frames': 2,
                                     'samples': [[1, 1, 0, 1, 0, 0], [1, 1, 0, 1, .5, 0]],
                                     'source': {'sha256': 'abc', 'origins': []}}]

    def modes(self, names, material):
        return {0}


def fixture():
    output = BytesIO()
    Image.new('RGBA', (2, 2), (10, 20, 30, 255)).save(output, 'PNG')
    binary = output.getvalue()
    document = {'asset': {'version': '2.0'}, 'buffers': [{'byteLength': len(binary)}],
                'materials': [{'name': 'water.png@1.0000000@WRAP-WRAP',
                               'pbrMetallicRoughness': {'baseColorTexture': {'index': 0},
                                                       'baseColorFactor': [1, 1, 1, .4]},
                               'alphaMode': 'BLEND'}],
                'images': [{'bufferView': 0, 'mimeType': 'image/png'}],
                'textures': [{'source': 0}],
                'bufferViews': [{'buffer': 0, 'byteLength': len(binary)}]}
    context = {'materials': {'water': {'textures': ['water.png'], 'groups': ['map_0001_01_02/terrain']}}}
    return document, binary, context


class CityAnimationTests(unittest.TestCase):
    def test_partial_source_catalog_does_not_pull_unselected_pavonnay_assets(self):
        with TemporaryDirectory() as folder:
            root = Path(folder)
            (root / '.pokemap/authoring/rom').mkdir(parents=True)
            pavonnay = root / '.pokemap/authoring/pavonnay'
            pavonnay.mkdir()
            (pavonnay / 'assets_manifest.json').write_text(json.dumps({'source': {'assetId': 'unselected'}, 'models': []}))
            sources = root / 'sources'
            sources.mkdir()
            (sources / 'manifest.json').write_text(json.dumps({'assets': []}))
            contexts = city_converter.source_contexts(root, sources, {'cities': [], 'recipeRoot': '.pokemap/authoring/rom', 'includePavonnay': False})
            self.assertEqual(contexts, [])

    def test_selected_archive_member_preserves_exact_source_provenance(self):
        from bw2_city_animation_sources import read_archive
        with TemporaryDirectory() as folder:
            root = Path(folder)
            with zipfile.ZipFile(root / 'bridge.zip', 'w') as archive:
                archive.writestr('bridge.dae', b'bridge')
                archive.writestr('access.dae', b'access')
            digest = sha256((root / 'bridge.zip').read_bytes()).hexdigest()
            record = {'id': 'bridge', 'name': 'Bridge', 'local_path': 'bridge.zip', 'page_url': 'https://example.test/bridge'}
            with self.assertRaises(ValueError):
                read_archive(root, record, digest)
            data, textures, proof = read_archive(root, record, digest, 'access.dae')
            self.assertEqual(data, b'access')
            self.assertEqual(proof['member'], 'access.dae')
            self.assertEqual(proof['memberSha256'], sha256(b'access').hexdigest())
            with self.assertRaises(ValueError):
                read_archive(root, record, digest, 'missing.dae')
            with self.assertRaises(ValueError):
                read_archive(root, record, '0'*64, 'access.dae')

    def test_recipe_catalog_cannot_escape_project_authoring_root(self):
        with TemporaryDirectory() as folder:
            root = Path(folder)
            (root / '.pokemap/authoring').mkdir(parents=True)
            with self.assertRaisesRegex(ValueError, 'inside the project authoring'):
                city_converter.source_contexts(root, root / 'sources', {'recipeRoot': '../outside', 'cities': []})

    def test_recipe_catalog_cannot_follow_symlink_outside_authoring_root(self):
        with TemporaryDirectory() as folder:
            root = Path(folder)
            authoring = root / '.pokemap/authoring'
            authoring.mkdir(parents=True)
            outside = root / 'outside'
            outside.mkdir()
            (authoring / 'escape').symlink_to(outside, target_is_directory=True)
            with self.assertRaisesRegex(ValueError, 'inside the project authoring'):
                city_converter.source_contexts(root, root / 'sources', {'recipeRoot': '.pokemap/authoring/escape', 'cities': []})

    def test_authoring_root_cannot_follow_symlink_outside_project(self):
        with TemporaryDirectory() as folder:
            root = Path(folder) / 'project'
            (root / '.pokemap').mkdir(parents=True)
            outside = Path(folder) / 'outside'
            (outside / 'recipes').mkdir(parents=True)
            (root / '.pokemap/authoring').symlink_to(outside, target_is_directory=True)
            with self.assertRaisesRegex(ValueError, 'inside the project'):
                city_converter.source_contexts(root, root / 'sources', {'recipeRoot': '.pokemap/authoring/recipes', 'cities': []})

    def test_synthetic_water_group_keeps_aliases_for_source_geometry_matching(self):
        context = {'materials': {
            'sea_mizu1_1': {'textures': ['sea.png'], 'groups': ['map_0301_24_4/terrain']},
            'sea_mizu1': {'textures': ['sea.png'], 'groups': ['map_0301_24_4/terrain']}}}
        material = {'name': 'sea.png@0.5161290@WRAP-WRAP'}
        self.assertEqual(city_converter.material_candidates(material, {'kind': 'water', 'sourceGroup': 'water-0-1'}, context),
                         ['sea_mizu1_1', 'sea_mizu1'])
        self.assertEqual(city_converter.material_candidates(material, {'kind': 'object', 'sourceGroup': 'water-0-1'}, context), [])
        self.assertEqual(city_converter.material_candidates(material, {'kind': 'object', 'sourceGroup': 'map_0301_24_4/terrain'}, context),
                         ['sea_mizu1_1', 'sea_mizu1'])

    def test_native_papeloa_sea_track_preserves_opaque_alias_geometry_and_other_clips(self):
        restore = getattr(city_converter, 'restore_papeloa_native_sea_animation', None)
        self.assertTrue(callable(restore))
        document, binary, _ = fixture()
        document['samplers'] = [{'wrapS': 10497, 'wrapT': 10497, 'magFilter': 9728, 'minFilter': 9728}]
        document['textures'][0]['sampler'] = 0
        document['materials'][0]['pbrMetallicRoughness']['baseColorFactor'][3] = 16 / 31
        document['materials'].append(deepcopy(document['materials'][0]))
        document['materials'][1].update(alphaMode='OPAQUE')
        document['materials'][1]['pbrMetallicRoughness']['baseColorFactor'][3] = 1
        document['nodes'] = [{'mesh': 0}]
        document['animations'] = [{'name': 'door_op'}, {'name': 'door_cl'}]
        positions = [[-4, 0, -4], [-4, 0, 4], [4, 0, 4], [-4, 0, -4], [4, 0, 4], [4, 0, -4]]
        uv = [[x / 4, z / 4 + 1] for x, _, z in positions]
        writer = GlbWriter(document, binary)
        attributes = {'POSITION': writer.rows(positions, 'VEC3'), 'TEXCOORD_0': writer.rows(uv, 'VEC2')}
        document['meshes'] = [{'primitives': [{'material': index, 'attributes': attributes} for index in (0, 1)]}]
        document['extras'] = {'aveluneAnimationSource': {'romSha256': 'rom', 'frameRate': 60, 'materials': [{'material': 'other'}]},
                             'aveluneMaterialAnimations': {'clips': [{'name': 'ambient', 'durationSeconds': 4,
                                 'tracks': [{'materialIndex': 1, 'durationSeconds': 4, 'times': [0, 4],
                                             'transforms': [[1, 0, 0, 1, 0, 0]] * 2, 'interpolation': 'STEP'}]}]}}
        document, binary = read_glb(writer.finish())
        original = deepcopy(document)
        triangles = [[vertex[:1] + [-5.6875] + vertex[2:] + texcoord + [1, 1, 1]
                      for vertex, texcoord in zip(positions[i:i+3], uv[i:i+3])] for i in (0, 3)]
        surface = SimpleNamespace(material='sea_mizu1_1', texture='water.png', wraps=['WRAP', 'WRAP'],
                                  opacity=16/31, triangles=triangles)
        sources = SourceFixture()
        sources.inventory = {'source': {'rom_sha256': 'rom'}}
        sources.by_material['sea_mizu1_1'] = [{'clip': 'out58_ita', 'frames': 240,
            'samples': [[1, 1, 0, 1, frame / 239, 0] for frame in range(240)],
            'source': {'sha256': '2c9a5c778f2f3ee0f3fa7b4c82e5586774e8f08e5769d5ed954b5b1b21071982', 'origins': []}}]
        instance = {'position': {'x': 24, 'y': -.4375, 'z': 33}, 'scale': 1, 'rotationDegrees': 0}
        texture_bytes = binary[:original['bufferViews'][0]['byteLength']]
        result, proof = restore(document, binary, instance, [surface], {'water.png': texture_bytes}, sources)
        self.assertEqual(document, original)
        self.assertEqual(result['animations'], original['animations'])
        self.assertEqual(result['meshes'], original['meshes'])
        self.assertEqual(result['nodes'], original['nodes'])
        self.assertEqual(result['materials'][1], original['materials'][1])
        self.assertEqual(result['materials'][0]['pbrMetallicRoughness'], original['materials'][0]['pbrMetallicRoughness'])
        clips = result['extras']['aveluneMaterialAnimations']['clips']
        self.assertEqual(clips[0]['tracks'][0], original['extras']['aveluneMaterialAnimations']['clips'][0]['tracks'][0])
        track = clips[0]['tracks'][1]
        self.assertEqual(track['materialIndex'], 0)
        self.assertEqual(track['durationSeconds'], 4)
        self.assertEqual(track['times'], [frame / 60 for frame in range(241)])
        self.assertEqual(track['transforms'][-2], [1, 0, 0, 1, -1, 0])
        self.assertEqual(track['transforms'][-1], track['transforms'][0])
        self.assertEqual(proof['materialIndices'], [0])
        self.assertEqual(read_glb(glb_bytes(result, binary))[1], binary)
        repeated, repeated_proof = restore(result, binary, instance, [surface], {'water.png': texture_bytes}, sources)
        self.assertEqual(repeated, result)
        self.assertEqual(repeated_proof['addedTracks'], 0)
        bad = deepcopy(document)
        bad['extras']['aveluneMaterialAnimations']['clips'][0]['durationSeconds'] = 8
        with self.assertRaisesRegex(ValueError, 'four-second'):
            restore(bad, binary, instance, [surface], {'water.png': texture_bytes}, sources)
        shifted = deepcopy(instance)
        shifted['position']['x'] += 1
        with self.assertRaisesRegex(ValueError, 'source geometry'):
            restore(document, binary, shifted, [surface], {'water.png': texture_bytes}, sources)
        non_native = deepcopy(document)
        non_native['materials'][0]['alphaMode'] = 'OPAQUE'
        self.assertIsNone(restore(non_native, binary, instance, [surface], {'water.png': texture_bytes}, sources)[0])
        with patch.object(sources, 'modes', return_value={2}), self.assertRaisesRegex(ValueError, 'matrix mode proof'):
            restore(document, binary, instance, [surface], {'water.png': texture_bytes}, sources)
        sources.by_material['sea_mizu1_1'][0]['source']['sha256'] = 'different'
        with self.assertRaisesRegex(ValueError, 'Pinned native'):
            restore(document, binary, instance, [surface], {'water.png': texture_bytes}, sources)

    def test_fresh_generator_recommends_only_water_and_authenticated_fountain_speed(self):
        for kind, clip, speed, expected in [('water', 'map01_02', 1, .5), ('object', 'fountain_01', 1, .5),
                                           ('fountain', 'map01_02', 1, None), ('object', 'map01_02', 1, None),
                                           ('water', 'map01_02', .75, None), ('object', 'fountain_01', .75, None)]:
            with self.subTest(kind=kind, clip=clip, speed=speed), TemporaryDirectory() as folder:
                root = Path(folder)
                project, output = root / 'project', root / 'stage'
                project.mkdir()
                document, binary, context = fixture()
                (project / 'model.glb').write_bytes(glb_bytes(document, binary))
                (project / 'map.json').write_text(json.dumps({'spatialScene': {'instances': [
                    {'id': 'instance', 'modelId': 'model', 'animationIndex': 0, 'animationSpeed': speed}]}}))
                (project / 'project.json').write_text(json.dumps({'models3d': [{'id': 'model', 'relativePath': 'model.glb'}],
                                                                 'maps': [{'id': 'map', 'relativePath': 'map.json'}]}))
                source = SourceFixture()
                source.by_material['water'][0]['clip'] = clip
                source.inventory = {'source': {'rom_sha256': 'rom', 'game_code': 'IRDF', 'tool_commit': 'tool'},
                                    'animations': [{'type': 'SRT0', 'name': clip, 'sha256': 'abc', 'frames': 2,
                                                    'tracks': [{'material': 'water'}]}]}
                context.update(city='test', models={'model': {'kind': kind}})
                context['materials']['water']['groups'] = ['scene/object_1_' + clip]
                with patch('animate_bw2_cities.source_contexts', return_value=[context]), \
                     patch('animate_bw2_cities.NitroSources', return_value=source), \
                     patch('animate_bw2_cities.joint_candidates', return_value=[]), \
                     patch('animate_bw2_cities.pattern_candidates', return_value=[]), \
                     patch('animate_bw2_cities.add_pattern_animations', return_value=(None, binary, [], [])), \
                     patch('builtins.print'):
                    run(project, root / 'sources', root / 'nitro', output, {}, 60, None)
                application = json.loads((output / 'animation_application.json').read_text())
                self.assertEqual(len(application['entries']), 1)
                entry = application['entries'][0]
                self.assertEqual(entry.get('recommendedAnimationSpeed'), expected)
                report = json.loads((output / 'animation-assets.json').read_text())
                self.assertEqual(report['models'][0].get('recommendedAnimationSpeed'), expected)
                self.assertEqual(entry['recommendedAnimationIndex'], 0)
                animated, _ = read_glb(Path(entry['sourcePath']).read_bytes())
                self.assertEqual(animated['extras']['aveluneMaterialAnimations']['clips'][0]['durationSeconds'], 2 / 60)
                if expected is not None:
                    self.assertEqual(entry['provenance']['originalGameCadenceProven'], False)

    def test_fountain_speed_catalog_preserves_asset_event_clips_and_current_index(self):
        build = getattr(city_converter, 'fountain_speed_application_entry', None)
        self.assertTrue(callable(build))
        document, binary, _ = fixture()
        document['materials'][0]['extras'] = {'aveluneNitroMaterial': 'fou_01'}
        document['animations'] = [{'name': 'door_op'}, {'name': 'door_cl'}]
        document['extras'] = {'aveluneAnimationSource': {'romSha256': 'rom', 'frameRate': 60,
            'materials': [{'material': 'fou_01', 'animation': 'fountain_01', 'animationSha256': 'native', 'matrixMode': 0}]},
            'aveluneMaterialAnimations': {'schemaVersion': 1, 'clips': [{'name': 'ambient', 'durationSeconds': .35,
                'tracks': [{'materialIndex': 0, 'durationSeconds': .35, 'times': [0, .35],
                            'transforms': [[1, 0, 0, 1, 0, 0]] * 2}]}]}}
        inventory = {'source': {'rom_sha256': 'rom'}, 'animations': [{'type': 'SRT0', 'name': 'fountain_01',
            'sha256': 'native', 'frames': 21, 'tracks': [{'material': 'fou_01'}]}]}
        data = glb_bytes(document, binary)
        entry = build('fountain', Path('/stage/fountain.glb'), data, [{'animationIndex': 2, 'animationSpeed': 1}], inventory)
        self.assertEqual(entry['sourceSha256Before'], sha256(data).hexdigest())
        self.assertEqual(entry['sha256After'], entry['sourceSha256Before'])
        self.assertEqual(entry['recommendedAnimationIndex'], 2)
        self.assertEqual(entry['recommendedAnimationSpeed'], .5)
        self.assertEqual(entry['clips'], ['door_op', 'door_cl', 'ambient'])
        self.assertEqual(entry['provenance']['nativeAnimations'][0]['durationFrames'], 21)
        self.assertEqual(entry['provenance']['nativeResourcesDeclareFps'], False)
        self.assertEqual(entry['provenance']['originalGameCadenceProven'], False)
        self.assertEqual(entry['provenance']['conversionFrameRateAssumption'], 60)
        self.assertEqual(read_glb(data)[0], document)
        self.assertIsNone(build('fountain', Path('/stage/fountain.glb'), data,
                                [{'animationIndex': 2, 'animationSpeed': .75}], inventory))
        self.assertIsNone(build('fountain', Path('/stage/fountain.glb'), data,
                                [{'animationIndex': 0, 'animationSpeed': 1}], inventory))
        bad = deepcopy(inventory)
        bad['source']['rom_sha256'] = 'different'
        with self.assertRaisesRegex(ValueError, 'ROM provenance'):
            build('fountain', Path('/stage/fountain.glb'), data, [{'animationIndex': 2}], bad)

    def test_fountain_speed_catalog_rejects_unverified_water_and_accepts_native_other_axes(self):
        build = getattr(city_converter, 'fountain_speed_application_entry', None)
        self.assertTrue(callable(build))
        document, binary, _ = fixture()
        document['materials'][0]['extras'] = {'aveluneNitroMaterial': 'water'}
        document['extras'] = {'aveluneAnimationSource': {'romSha256': 'rom', 'frameRate': 60,
            'materials': [{'material': 'water', 'animation': 'out36_ita', 'animationSha256': 'native', 'matrixMode': 0}]},
            'aveluneMaterialAnimations': {'schemaVersion': 1, 'clips': [{'name': 'water', 'tracks': [{'materialIndex': 0}]}]}}
        inventory = {'source': {'rom_sha256': 'rom'}, 'animations': [{'type': 'SRT0', 'name': 'out36_ita',
            'sha256': 'native', 'frames': 240, 'tracks': [{'material': 'water'}]}]}
        self.assertIsNone(build('water', Path('/stage/water.glb'), glb_bytes(document, binary), [{'animationIndex': 0}], inventory))
        document['extras']['aveluneAnimationSource']['materials'][0]['animation'] = 'c03_fountain_01'
        inventory['animations'][0]['name'] = 'c03_fountain_01'
        inventory['animations'][0]['frames'] = 30
        entry = build('fountain', Path('/stage/fountain.glb'), glb_bytes(document, binary), [{'animationIndex': 0}], inventory)
        self.assertEqual(entry['recommendedAnimationSpeed'], .5)
        self.assertEqual(entry['provenance']['nativeAnimations'][0]['stem'], 'c03_fountain_01')
        inventory['animations'][0]['sha256'] = 'different'
        with self.assertRaisesRegex(ValueError, 'native fountain source'):
            build('fountain', Path('/stage/fountain.glb'), glb_bytes(document, binary), [{'animationIndex': 0}], inventory)

    def test_material_repair_preserves_patterns_doors_timing_and_binary(self):
        repair = getattr(city_converter, 'repair_material_animation_transforms', None)
        self.assertTrue(callable(repair))
        document, binary, _ = fixture()
        document['materials'][0]['extras'] = {'aveluneNitroMaterial': 'water'}
        document['animations'] = [{'name': 'door_op'}, {'name': 'door_cl'}]
        document['extras'] = {
            'aveluneAnimationSource': {'frameRate': 60, 'materials': [{'material': 'water', 'animation': 'map01_02',
                                      'animationSha256': 'abc', 'matrixMode': 0}]},
            'aveluneMaterialAnimations': {'schemaVersion': 1, 'clips': [{'name': 'water', 'nodeAnimationIndex': 1,
                'durationSeconds': 2 / 60, 'tracks': [{'materialIndex': 0, 'durationSeconds': 2 / 60,
                'times': [0, 1 / 60, 2 / 60], 'interpolation': 'STEP', 'textureIndices': [0, 1, 0],
                'transforms': [[1, 0, 0, 1, 0, 0], [1, 0, 0, 1, 0, -.25], [1, 0, 0, 1, 0, 0]]}]}]}}
        sources = SourceFixture()
        sources.by_material['water'][0]['samples'][1] = [1, 1, 0, 1, 0, .25]
        before = deepcopy(document)
        result, evidence = repair(document, binary, sources)
        before_track = before['extras']['aveluneMaterialAnimations']['clips'][0]['tracks'][0]
        after_track = result['extras']['aveluneMaterialAnimations']['clips'][0]['tracks'][0]
        self.assertEqual(after_track['transforms'][1], [1, 0, 0, 1, 0, .25])
        self.assertEqual({k: v for k, v in before_track.items() if k != 'transforms'},
                         {k: v for k, v in after_track.items() if k != 'transforms'})
        self.assertEqual(result['animations'], before['animations'])
        self.assertEqual(result['materials'], before['materials'])
        self.assertEqual(result['extras']['aveluneMaterialAnimations']['clips'][0]['nodeAnimationIndex'], 1)
        self.assertEqual(document, before)
        self.assertEqual(read_glb(glb_bytes(result, binary))[1][:len(binary)], binary)
        self.assertEqual(evidence[0]['changed'], True)
        again, repeated = repair(result, binary, sources)
        self.assertEqual(again, result)
        self.assertEqual(repeated[0]['changed'], False)
        bad = deepcopy(before)
        bad['extras']['aveluneMaterialAnimations']['clips'][0]['tracks'][0]['transforms'][1][-1] = 99
        with self.assertRaisesRegex(ValueError, 'Current UV transforms'):
            repair(bad, binary, sources)

    def test_joint_clip_repair_preserves_existing_door_indices_and_geometry(self):
        repair = getattr(city_converter, 'repair_joint_animation_clip', None)
        self.assertTrue(callable(repair))
        current, binary, _ = fixture()
        current['nodes'] = [{'name': 'alignment'}, {'name': 'rotor'}]
        current['meshes'] = [{'primitives': [{'material': 0}]}]
        current['animations'] = [{'name': 'ambient'}, {'name': 'door_op'}, {'name': 'door_cl'}]
        source = deepcopy(current)
        source['nodes'] = [{'name': 'rotor'}]
        writer = GlbWriter(source, binary)
        times = writer.rows([[0], [1]], 'SCALAR')
        rotations = writer.rows([[0, 0, 0, 1], [0, 0, 0, 1]], 'VEC4')
        source['animations'] = [{'name': 'ambient', 'samplers': [{'input': times, 'output': rotations}],
                                 'channels': [{'sampler': 0, 'target': {'node': 0, 'path': 'rotation'}}]}]
        restored = writer.finish()
        original = glb_bytes(current, binary)
        with patch('animate_bw2_cities.restore_joint_timeline', return_value=(restored, {'proof': True})):
            result, evidence = repair(original, restored, b'motion', 'ambient', b'model')
            document, appended = read_glb(result)
            self.assertEqual(document['animations'][1:], current['animations'][1:])
            self.assertEqual(document['animations'][0]['channels'][0]['target']['node'], 1)
            sampler = document['animations'][0]['samplers'][0]
            self.assertEqual(accessor_rows(document, appended, sampler['input']), [[0], [1]])
            self.assertEqual(accessor_rows(document, appended, sampler['output']), [[0, 0, 0, 1]] * 2)
            self.assertEqual(document['nodes'], current['nodes'])
            self.assertEqual(document['meshes'], current['meshes'])
            self.assertEqual(document['materials'], current['materials'])
            self.assertEqual(appended[:len(read_glb(original)[1])], read_glb(original)[1])
            self.assertEqual(evidence['animationIndex'], 0)
            bad = deepcopy(current)
            bad['nodes'][1]['name'] = 'other'
            with self.assertRaisesRegex(ValueError, 'node alignment'):
                repair(glb_bytes(bad, binary), restored, b'motion', 'ambient', b'model')

    def test_staging_cannot_write_inside_original_project_bundle_or_rom_extraction(self):
        for target in ['/project/stage', '/sources/stage', '/nitro/stage', '/']:
            with self.assertRaisesRegex(ValueError, 'read-only source roots'):
                run(Path('/project'), Path('/sources'), Path('/nitro'), Path(target), {}, 60, None)

    def test_door_clips_stay_selectable_without_automatic_joint_playback(self):
        door = {'animations': [{'name': 'door_op'}, {'name': 'door_cl'}]}
        self.assertIsNone(configure_joint_playback(door, 'door_op'))
        door['extras'] = {'aveluneMaterialAnimations': {'clips': [{'name': 'Water', 'nodeAnimationIndex': 0}]}}
        self.assertEqual(configure_joint_playback(door, 'door_op'), 2)
        self.assertNotIn('nodeAnimationIndex', door['extras']['aveluneMaterialAnimations']['clips'][0])

    def test_verified_wheel_ambient_clip_is_combined_with_material_motion(self):
        wheel = {'animations': [{'name': 'c04_fwheel_01'}]}
        self.assertEqual(configure_joint_playback(wheel, 'c04_fwheel_01'), 0)
        wheel['extras'] = {'aveluneMaterialAnimations': {'clips': [{'name': 'Water'}]}}
        self.assertEqual(configure_joint_playback(wheel, 'c04_fwheel_01'), 1)
        self.assertEqual(wheel['extras']['aveluneMaterialAnimations']['clips'][0]['nodeAnimationIndex'], 0)

    def test_static_coverage_distinguishes_missing_constant_and_unassociated_source_tracks(self):
        sources = SourceFixture()
        sources.by_material['constant'] = [deepcopy(sources.by_material['water'][0])]
        sources.by_material['constant'][0]['samples'] = [[1, 1, 0, 1, 0, 0]] * 2
        sources.by_material['event'] = [deepcopy(sources.by_material['water'][0])]
        sources.by_material['event'][0]['clip'] = 'cutscene'
        context = {'city': 'test', 'materials': {name: {'textures': [name + '.png'], 'groups': ['source']}
                                                for name in ['missing', 'constant', 'event']}, 'models': {}}
        with TemporaryDirectory() as folder:
            project = Path(folder)
            models, rows = [], []
            for name in context['materials']:
                document, binary, _ = fixture()
                document['materials'][0]['name'] = name + '.png'
                document['meshes'] = [{'primitives': [{'material': 0}]}]
                (project / (name + '.glb')).write_bytes(glb_bytes(document, binary))
                models.append({'id': name, 'relativePath': name + '.glb'})
                rows.append({'modelId': name, 'city': 'test', 'placedInstances': 1, 'status': 'static_source'})
                context['models'][name] = {}
            (project / 'project.json').write_text(json.dumps({'models3d': models}))
            report = {'models': rows, 'source': {}, 'projectSha256': 'proof', 'summary': {'static_source': 3}}
            with patch('animate_bw2_cities.source_contexts', return_value=[context]), patch('animate_bw2_cities.NitroSources', return_value=sources):
                result = audit_staged_coverage(project, Path('/sources'), Path('/nitro'), {}, report)
        self.assertEqual(result['staticSourceClassifications'], {'no_source_track': 1, 'constant_source_tracks': 1, 'unassociated_variable_sources': 1})
        event = next(row for row in result['staticModels'] if row['modelId'] == 'event')
        self.assertEqual(event['materials'][0]['candidateClips'], ['cutscene'])

    def test_door_consolidation_preserves_original_project_precondition_and_ambient_default(self):
        for valid in [True, False]:
            with self.subTest(valid=valid), TemporaryDirectory() as folder:
                stage = Path(folder) / 'ambient'
                stage.mkdir()
                original, binary, _ = fixture()
                original['animations'] = [{'name': 'ambient'}]
                before = glb_bytes(original, binary)
                current = stage / 'model.glb'
                current.write_bytes(before)
                after_document = deepcopy(original)
                after_document['animations'] += [{'name': 'open'}, {'name': 'close'}]
                after = glb_bytes(after_document, binary)
                door = Path(folder) / 'door.glb'
                door.write_bytes(after)
                before_sha, after_sha = sha256(before).hexdigest(), sha256(after).hexdigest()
                source_sha = 'a' * 64
                applications = {'source': {'rom_sha256': 'rom'}, 'entries': [{'modelId': 'model', 'sourcePath': str(current),
                                  'sourceSha256Before': source_sha, 'sha256After': before_sha, 'recommendedAnimationIndex': 0,
                                  'clips': ['ambient'], 'provenance': {}}]}
                report = {'models': [{'modelId': 'model', 'sha256': before_sha, 'byteLength': len(before)}],
                          'stagedAssets': [{'modelId': 'model', 'sha256': before_sha}]}
                application_file = stage / 'animation_application.json'
                application_file.write_text(json.dumps(applications))
                (stage / 'animation-assets.json').write_text(json.dumps(report))
                patch_data = {'source': {'rom_sha256': 'rom'}, 'entries': [{'modelId': 'model', 'sourcePath': str(door),
                             'inputSha256': before_sha if valid else 'b' * 64, 'sha256After': after_sha,
                             'clips': ['ambient', 'open', 'close'], 'recommendedAnimationIndex': 0, 'provenance': {'original': True}}], 'refused': []}
                patch_file = Path(folder) / 'doors.json'
                patch_file.write_text(json.dumps(patch_data))
                if valid:
                    result = merge_staged_door_index(stage, patch_file)
                    entry = result['entries'][0]
                    self.assertEqual(entry['sourceSha256Before'], source_sha)
                    self.assertEqual(entry['sha256After'], after_sha)
                    self.assertEqual(entry['recommendedAnimationIndex'], 0)
                    self.assertEqual(current.read_bytes(), after)
                else:
                    application_before = application_file.read_bytes()
                    with self.assertRaisesRegex(ValueError, 'frozen ambient asset'):
                        merge_staged_door_index(stage, patch_file)
                    self.assertEqual(application_file.read_bytes(), application_before)
                    self.assertEqual(current.read_bytes(), before)

    def test_material_animation_preserves_visual_material_and_binary(self):
        document, binary, context = fixture()
        before = deepcopy(document)
        result, evidence, unsupported = animated_material_document(document, binary, {}, context, SourceFixture(), 60)
        clip = result['extras']['aveluneMaterialAnimations']['clips'][0]
        self.assertEqual(clip['tracks'][0]['transforms'][1], [1, 0, 0, 1, -.5, 0])
        self.assertEqual(clip['tracks'][0]['durationSeconds'], 2 / 60)
        self.assertEqual(clip['tracks'][0]['times'], [0, 1 / 60, 2 / 60])
        self.assertEqual(document, before)
        self.assertEqual(result['materials'][0]['pbrMetallicRoughness'], before['materials'][0]['pbrMetallicRoughness'])
        self.assertEqual(unsupported, [])
        self.assertEqual(evidence[0]['association'], 'exact_model_source')
        self.assertEqual(read_glb(glb_bytes(result, binary))[1][:len(binary)], binary)

    def test_fountain_vertical_translation_preserves_nitro_uv_axis(self):
        document, binary, context = fixture()
        sources = SourceFixture()
        sources.by_material['water'][0].update(frames=21, samples=[[1, 1, 0, 1, 0, -frame / 20] for frame in range(21)])
        result, evidence, unsupported = animated_material_document(document, binary, {}, context, sources, 60)
        track = result['extras']['aveluneMaterialAnimations']['clips'][0]['tracks'][0]
        self.assertEqual(track['transforms'][0], [1, 0, 0, 1, 0, 0])
        self.assertEqual(track['transforms'][20], [1, 0, 0, 1, 0, -1])
        self.assertEqual(track['durationSeconds'], .35)
        self.assertEqual(evidence[0].get('uvCoordinateConvention'), 'nitro_normalized_uv')
        self.assertEqual(evidence[0].get('sourceUvConversion'), 'nitro_to_collada_v_flip_then_glb_v_flip')
        self.assertEqual(evidence[0].get('matrixConversion'), 'original_sdk_normalized_uv')
        self.assertEqual(unsupported, [])

    def test_material_rotation_and_scale_preserve_original_sdk_uv_basis(self):
        document, binary, context = fixture()
        sources = SourceFixture()
        sources.by_material['water'][0]['samples'][1] = [2, 3, 1, 0, .25, .5]
        result, _, _ = animated_material_document(document, binary, {}, context, sources, 60)
        track = result['extras']['aveluneMaterialAnimations']['clips'][0]['tracks'][0]
        self.assertEqual(track['transforms'][1], [0, -3, 2, 0, -.5, 2.5])

    def test_apicula_and_city_uv_flips_make_original_fountain_motif_descend(self):
        original_nitro_pixel_uv = [5.8125, 22.25]
        normalized_nitro_uv = [original_nitro_pixel_uv[0] / 16, original_nitro_pixel_uv[1] / 32]
        collada_uv = [normalized_nitro_uv[0], 1 - normalized_nitro_uv[1]]
        imported_glb_uv = [collada_uv[0], 1 - collada_uv[1]]
        self.assertEqual(imported_glb_uv, normalized_nitro_uv)
        document, binary, context = fixture()
        sources = SourceFixture()
        sources.by_material['water'][0].update(frames=21, samples=[[1, 1, 0, 1, 0, -frame / 20] for frame in range(21)])
        result, _, _ = animated_material_document(document, binary, {}, context, sources, 60)
        matrix = result['extras']['aveluneMaterialAnimations']['clips'][0]['tracks'][0]['transforms'][5]
        sample_v = matrix[1] * imported_glb_uv[0] + matrix[3] * imported_glb_uv[1] + matrix[5]
        self.assertEqual(sample_v, normalized_nitro_uv[1] - .25)
        top_y, top_v = 1.85827636875, .6953125
        base_y, base_v = .6875, 1.69140625
        motif_v = (top_v - matrix[5]) / matrix[3]
        motif_y = top_y + (motif_v - top_v) / (base_v - top_v) * (base_y - top_y)
        self.assertLess(motif_y, top_y)
        self.assertGreater(motif_y, base_y)

    def test_joint_merge_verifies_original_model_and_forwards_its_bytes(self):
        for valid in [True, False]:
            with self.subTest(valid=valid), TemporaryDirectory() as folder:
                output = Path(folder)
                original_document, binary, _ = fixture()
                original_document['animations'] = [{'name': 'c7_windmill_01'}]
                original = glb_bytes(original_document, binary)
                current = output / 'current.glb'
                current.write_bytes(original)
                proof = output / 'proof.glb'
                proof.write_bytes(original)
                animation = output / 'motion.nsbca'
                animation.write_bytes(b'original-joint-motion')
                model = output / 'model.nsbmd'
                model.write_bytes(b'original-model-object-order')
                record = {'modelId': 'windmill', 'clip': 'c7_windmill_01', 'currentGlb': str(current),
                          'currentGlbSha256': sha256(original).hexdigest(), 'originalAnimatedGlb': str(proof),
                          'originalAnimatedGlbSha256': sha256(original).hexdigest(), 'originalAnimation': str(animation),
                          'originalAnimationSha256': sha256(animation.read_bytes()).hexdigest(), 'originalModel': str(model),
                          'originalModelSha256': sha256(model.read_bytes()).hexdigest() if valid else 'b' * 64,
                          'sourceToCurrent': [1] * 16, 'verifiedStaticAttachments': []}
                source = {'rom_sha256': 'rom', 'game_code': 'IRDF'}
                report = {'source': source, 'frameRateEvidence': 'unmeasured',
                          'models': [{'modelId': 'windmill', 'sourceSha256': sha256(original).hexdigest(),
                                      'status': 'static_source', 'materials': []}]}
                (output / 'joint-candidates.json').write_text(json.dumps({'models': []}))
                joint_index = output / 'joints.json'
                joint_index.write_text(json.dumps({'source': source, 'converted': [record], 'refused': []}))
                (output / 'models').mkdir()
                with patch('animate_bw2_cities.restore_joint_timeline', return_value=(original, {})) as restore, \
                     patch('animate_bw2_cities.enrich_rigid_animation', return_value=(original, {})):
                    if valid:
                        merge_joint_animations(report, Path('/sources'), Path('/nitro'), output, joint_index, 60)
                        restore.assert_called_once_with(original, animation.read_bytes(), 'c7_windmill_01', model.read_bytes())
                    else:
                        with self.assertRaisesRegex(ValueError, 'digest changed'):
                            merge_joint_animations(report, Path('/sources'), Path('/nitro'), output, joint_index, 60)
                        restore.assert_not_called()

    def test_independent_track_periods_share_one_ambient_clip(self):
        document, binary, context = fixture()
        document['materials'].append(deepcopy(document['materials'][0]))
        document['materials'][1]['name'] = 'fountain.png'
        context['materials']['fountain'] = {'textures': ['fountain.png'], 'groups': ['map_0001_01_02/terrain']}
        sources = SourceFixture()
        fountain = deepcopy(sources.by_material['water'][0])
        fountain.update(material='fountain', frames=3, samples=[[1, 1, 0, 1, 0, 0], [1, 1, 0, 1, .5, 0], [1, 1, 0, 1, 1, 0]])
        sources.by_material['fountain'] = [fountain]
        result, _, _ = animated_material_document(document, binary, {}, context, sources, 60)
        clip = result['extras']['aveluneMaterialAnimations']['clips'][0]
        self.assertEqual(clip['durationSeconds'], 3 / 60)
        self.assertEqual([track['durationSeconds'] for track in clip['tracks']], [2 / 60, 3 / 60])

    def test_last_nitro_frame_holds_before_loop_wrap_without_backward_flicker(self):
        document, binary, context = fixture()
        sources = SourceFixture()
        source = sources.by_material['water'][0]
        source.update(frames=20, samples=[[1, 1, 0, 1, 0, -frame / 19] for frame in range(20)])
        result, _, _ = animated_material_document(document, binary, {}, context, sources, 60)
        track = result['extras']['aveluneMaterialAnimations']['clips'][0]['tracks'][0]
        self.assertEqual(track['interpolation'], 'STEP')
        sample = bisect_right(track['times'], 19.5 / 60) - 1
        self.assertEqual(track['transforms'][sample][-1], -1)
        sample = bisect_right(track['times'], 20 / 60) - 1
        self.assertEqual(track['transforms'][sample][-1], 0)

    def test_pattern_and_uv_periods_remain_exact_over_their_common_cycle(self):
        transform = {'materialIndex': 0, 'durationSeconds': 2 / 60, 'times': [0, 1 / 60, 2 / 60],
                     'transforms': [[1, 0, 0, 1, 0, 0], [1, 0, 0, 1, .5, 0], [1, 0, 0, 1, 0, 0]]}
        pattern = {'durationSeconds': 3 / 60, 'times': [0, 1 / 60, 3 / 60], 'textureIndices': [3, 4, 3]}
        result = combine_pattern_transform_tracks(transform, pattern, 60)
        self.assertEqual(result['durationSeconds'], 6 / 60)
        self.assertEqual(result['textureIndices'], [3, 4, 4, 3, 4, 4, 3])
        self.assertEqual([row[4] for row in result['transforms']], [0, .5, 0, .5, 0, .5, 0])

    def test_pattern_embeds_original_frames_and_preserves_existing_material_and_binary(self):
        document, binary, context = fixture()
        context['city'] = 'test'
        document['meshes'] = [{'primitives': [{'material': 0}]}]
        document['samplers'] = [{'wrapS': 10497, 'wrapT': 10497}]
        document['textures'][0]['sampler'] = 0
        output = BytesIO()
        Image.new('RGBA', (2, 2), (70, 20, 30, 255)).save(output, 'PNG')
        new_png = output.getvalue()
        decoded = {('a', 'p'): {'data': binary, 'texture': 'a', 'palette': 'p'},
                   ('b', 'p'): {'data': new_png, 'texture': 'b', 'palette': 'p'}}
        for frame in decoded.values():
            frame.update(sha256='frame', sourceModelSha256='source', bindingChanges=[], equivalentTexturePacks=[])
        decoded['b', 'p']['sha256'] = 'different'
        candidate = {'city': 'test', 'animation': 'map01_02', 'frames': 3, 'sha256': 'original', 'origins': [],
                     'tracks': [{'material': 'water', 'keys': [{'frame': 0, 'texture': 'a', 'palette': 'p'},
                                                            {'frame': 2, 'texture': 'b', 'palette': 'p'}]}]}
        before = deepcopy(document)
        with patch('animate_bw2_cities.decode_pattern_frames', return_value=decoded):
            result, new_binary, evidence, refused = add_pattern_animations(document, binary, {}, context, [candidate], Path('/nitro'), Path('/apicula'), Path('/out'), 60)
        self.assertEqual(document, before)
        self.assertEqual(new_binary[:len(binary)], binary)
        self.assertEqual(result['materials'][0]['pbrMetallicRoughness'], document['materials'][0]['pbrMetallicRoughness'])
        track = result['extras']['aveluneMaterialAnimations']['clips'][0]['tracks'][0]
        self.assertEqual(track['textureIndices'], [0, 1, 0])
        self.assertEqual(track['times'], [0, 2 / 60, 3 / 60])
        self.assertEqual(result['textures'][1]['sampler'], 0)
        self.assertEqual(refused, [])
        self.assertEqual(evidence[0]['animationSha256'], 'original')

    def test_conflicting_source_clips_are_rejected(self):
        a = deepcopy(SourceFixture().by_material['water'][0])
        a['clip'] = 'out01_ita'
        b = deepcopy(a)
        b.update(clip='out02_ita', samples=[[1, 1, 0, 1, 0, 0], [1, 1, 0, 1, 1, 0]])
        chosen, reason = choose_track('water', [a, b], set(), set())
        self.assertIsNone(chosen)
        self.assertEqual(reason, 'ambiguous_source_clip')

    def test_static_source_track_is_not_advertised_as_animation(self):
        document, binary, context = fixture()
        sources = SourceFixture()
        sources.by_material['water'][0]['samples'] = [[1, 1, 0, 1, 0, 0]] * 2
        result, _, unsupported = animated_material_document(document, binary, {}, context, sources, 60)
        self.assertIsNone(result)
        self.assertEqual(unsupported, [])

    def test_shared_texture_material_requires_exact_group(self):
        document, _, context = fixture()
        context['materials']['other'] = {'textures': ['water.png'], 'groups': ['map_0002_02_03/terrain']}
        self.assertIsNone(material_identity(document['materials'][0], {}, context))
        self.assertEqual(material_identity(document['materials'][0], {'kind': 'object', 'sourceGroup': 'map_0001_01_02/terrain'}, context), 'water')

    def test_original_map_group_and_object_name_are_resolved(self):
        self.assertEqual(model_names(['map_0001_01_02/terrain', 'map_0001_01_02/object_08_c04_fwheel_01']),
                         {'map01_02', 'c04_fwheel_01'})

    def test_broken_glb_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'header'):
            read_glb(b'broken')

    def test_synthetic_water_groups_split_same_texture_faces_without_vertex_changes(self):
        document, binary, context = fixture()
        positions = [[0, 0, 0], [1, 0, 0], [0, 0, 1], [0, 1, 0], [1, 1, 0], [0, 1, 1]]
        uvs = [[0, 0], [1, 0], [0, 1]] * 2
        colors = [[1, 1, 1, 1]] * 6
        writer = GlbWriter(document, binary)
        attributes = {'POSITION': writer.rows(positions, 'VEC3'), 'TEXCOORD_0': writer.rows(uvs, 'VEC2'),
                      'COLOR_0': writer.rows(colors, 'VEC4')}
        document['meshes'] = [{'primitives': [{'attributes': attributes, 'material': 0}]}]
        _, binary = read_glb(writer.finish())
        context['materials']['stone'] = {'textures': ['water.png'], 'groups': ['map_0001_01_02/terrain']}
        context['surfaces'] = [SimpleNamespace(material=name, group='map_0001_01_02/terrain', texture='water.png',
                                               triangles=[[positions[index] + uvs[index] + colors[index][:3] for index in range(start, start + 3)]])
                               for name, start in [('water', 0), ('stone', 3)]]
        recipe = {'kind': 'water', 'sourceGroup': 'water-0-1', 'sourceAnchorCells': [0, 0, 0]}
        result, new_binary, evidence = split_animated_materials(document, binary, recipe, context, SourceFixture())
        self.assertEqual(new_binary[:len(binary)], binary)
        self.assertEqual(len(result['meshes'][0]['primitives']), 2)
        self.assertEqual({entry['sourceMaterial'] for entry in evidence}, {'water', 'stone'})
        for primitive in result['meshes'][0]['primitives']:
            self.assertEqual(primitive['attributes'], attributes)
        animated, _, unsupported = animated_material_document(result, new_binary, {}, context, SourceFixture(), 60)
        tracks = animated['extras']['aveluneMaterialAnimations']['clips'][0]['tracks']
        self.assertEqual(len(tracks), 1)
        self.assertEqual(animated['materials'][tracks[0]['materialIndex']]['extras']['aveluneNitroMaterial'], 'water')
        self.assertEqual(unsupported, [])


if __name__ == '__main__':
    unittest.main()
