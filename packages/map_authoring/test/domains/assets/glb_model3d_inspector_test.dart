import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';
import '../../support/glb_fixture.dart';

void main() {
  test('inspects actual positions through the selected scene transforms', () {
    final result = const GlbModel3dInspector().inspect(triangleGlb());
    expect(result.bounds.min.toJson(), {'x': 10.0, 'y': 2.0, 'z': -1.0});
    expect(result.bounds.max.toJson(), {'x': 14.0, 'y': 5.0, 'z': -1.0});
    expect(result.triangleCount, 1);
    expect(result.meshCount, 1);
  });
  for (final entry in <String, void Function(Map<String, dynamic>)>{
    'external buffer': (j) => j['buffers'][0]['uri'] = '../secret.bin',
    'invalid embedded image': (j) => j['images'] = [
          {'bufferView': 0, 'mimeType': 'image/png'}
        ],
    'external image': (j) => j['images'] = [
          {'uri': 'https://example.com/a.png'}
        ],
    'required extension': (j) =>
        j['extensionsRequired'] = ['KHR_draco_mesh_compression'],
    'out of range accessor': (j) => j['accessors'][0]['count'] = 100,
    'missing scene': (j) => j.remove('scene'),
    'cycle': (j) => j['nodes'][0]['children'] = [0],
    'non triangles': (j) => j['meshes'][0]['primitives'][0]['mode'] = 1,
    'sparse accessor': (j) => j['accessors'][0]['sparse'] = {},
    'false bounds': (j) => j['accessors'][0]['max'] = [1, 1, 0],
    'transparent material': (j) => j['materials'] = [
          {'alphaMode': 'BLEND'}
        ],
  }.entries) {
    test('rejects ${entry.key}', () {
      expect(
          () => const GlbModel3dInspector()
              .inspect(triangleGlb(edit: entry.value)),
          throwsFormatException);
    });
  }
  test('rejects truncated chunks', () {
    final bytes = triangleGlb();
    expect(
        () => const GlbModel3dInspector()
            .inspect(bytes.sublist(0, bytes.length - 1)),
        throwsFormatException);
  });
  test(
      'inspects animation duration and materials with static bounds diagnostics',
      () {
    final model = const GlbModel3dInspector().inspect(animatedGlb());
    expect(model.animations.single.name, 'Wind');
    expect(model.animations.single.durationSeconds, 2);
    expect(model.materials.single.name, 'Stone');
    expect(model.diagnostics, contains('bounds.static_scene_only'));
  });
  test('rejects CUBICSPLINE animation interpolation', () {
    expect(
        () => const GlbModel3dInspector().inspect(animatedGlb(
            edit: (j) => j['animations'][0]['samplers'][0]['interpolation'] =
                'CUBICSPLINE')),
        throwsFormatException);
  });
  test('rejects zero duration animation', () {
    expect(
        () => const GlbModel3dInspector().inspect(animatedGlb(edit: (j) {
              j['accessors'][1]['count'] = 1;
              j['accessors'][2]['count'] = 1;
            })),
        throwsFormatException);
  });
  test('rejects skins larger than the renderer joint palette', () {
    expect(
        () => const GlbModel3dInspector().inspect(triangleGlb(
            edit: (j) => j['skins'] = [
                  {'joints': List.generate(17, (i) => i)}
                ])),
        throwsFormatException);
  });
  test('accepts float VEC3 normals without an ignored normals diagnostic', () {
    final model = const GlbModel3dInspector().inspect(triangleGlb(
        edit: (j) =>
            j['meshes'][0]['primitives'][0]['attributes']['NORMAL'] = 0));
    expect(model.diagnostics, contains('renderer.missing_material_magenta'));
    expect(model.diagnostics, isNot(contains('renderer.ignored_normal')));
  });
  test('bounds exclude vertices not used by primitive indices', () {
    final model = const GlbModel3dInspector().inspect(triangleGlb(edit: (j) {
      j['accessors'].add({
        'bufferView': 0,
        'componentType': 5123,
        'count': 3,
        'type': 'SCALAR'
      });
      j['meshes'][0]['primitives'][0]['indices'] = 1;
    }));
    expect(model.bounds.max.toJson(), {'x': 10.0, 'y': 2.0, 'z': -1.0});
  });
  test('accepts a decoded embedded PNG texture', () {
    expect(const GlbModel3dInspector().inspect(texturedGlb()).materials,
        hasLength(1));
  });
  test('rejects oversized embedded textures before decoding', () {
    expect(
        () => const GlbModel3dInspector().inspect(texturedGlb(oversized: true)),
        throwsFormatException);
  });
  test('rejects even a single joint skin in the initial rendering profile', () {
    expect(
        () => const GlbModel3dInspector().inspect(triangleGlb(
            edit: (j) => j['skins'] = [
                  {
                    'joints': [0]
                  }
                ])),
        throwsFormatException);
  });
  test('rejects skin vertex attributes without a skin document', () {
    expect(
        () => const GlbModel3dInspector().inspect(triangleGlb(
            edit: (j) => j['meshes'][0]['primitives'][0]['attributes']
                ['WEIGHTS_0'] = 0)),
        throwsFormatException);
  });
  for (final scale in [0, -1]) {
    test('rejects animated nodes with initial scale $scale', () {
      expect(
          () => const GlbModel3dInspector().inspect(animatedGlb(edit: (j) {
                j['nodes'][0]['scale'] = [1, scale, 1];
              })),
          throwsFormatException);
    });
  }
  test('rejects animated nodes defined by a matrix', () {
    expect(
        () => const GlbModel3dInspector().inspect(animatedGlb(edit: (j) {
              j['nodes'][0].remove('translation');
              j['nodes'][0].remove('scale');
              j['nodes'][0]
                  ['matrix'] = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
            })),
        throwsFormatException);
  });
  test('keeps negative scale available on static nodes', () {
    final model = const GlbModel3dInspector().inspect(triangleGlb(edit: (j) {
      j['nodes'][0]['scale'] = [1, -1, 1];
    }));
    expect(model.bounds.min.y, -1);
    expect(model.bounds.max.y, 2);
  });
  for (final definition in [
    {'type': 'SCALAR', 'componentType': 5126, 'normalized': false},
    {'type': 'VEC3', 'componentType': 5123, 'normalized': false},
    {'type': 'VEC3', 'componentType': 5123, 'normalized': true},
  ]) {
    test('rejects invalid NORMAL accessor $definition', () {
      expect(
          () => const GlbModel3dInspector().inspect(triangleGlb(edit: (j) {
                j['accessors']
                    .add({'bufferView': 0, 'count': 3, ...definition});
                j['meshes'][0]['primitives'][0]['attributes']['NORMAL'] = 1;
              })),
          throwsFormatException);
    });
  }
}
