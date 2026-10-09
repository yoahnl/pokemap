import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/glb_fixture.dart';
import 'support/spatial_package_fixture.dart';

List<int> materialGlb({
  bool mixed = false,
  bool constantChannel = false,
  void Function(Map<String, dynamic>)? edit,
}) {
  final source = texturedGlb();
  final header = ByteData.sublistView(Uint8List.fromList(source));
  final length = header.getUint32(12, Endian.little);
  final json = jsonDecode(utf8.decode(source.sublist(20, 20 + length)))
      as Map<String, dynamic>;
  final original = source.sublist(28 + length);
  var binary = Uint8List.fromList(original);
  if (mixed) {
    binary = Uint8List(original.length + (constantChannel ? 48 : 32))
      ..setRange(0, original.length, original);
    final data = ByteData.sublistView(binary);
    data.setFloat32(original.length + 4, 2, Endian.little);
    data.setFloat32(original.length + 20, 1, Endian.little);
    if (constantChannel) {
      for (var i = 0; i < 3; i++) {
        data.setFloat32(original.length + 36 + i * 4, 1, Endian.little);
      }
    }
    final viewIndex = (json['bufferViews'] as List).length;
    final accessorIndex = (json['accessors'] as List).length;
    json['bufferViews'].addAll([
      {'buffer': 0, 'byteOffset': original.length, 'byteLength': 8},
      {'buffer': 0, 'byteOffset': original.length + 8, 'byteLength': 24},
    ]);
    json['accessors'].addAll([
      {
        'bufferView': viewIndex,
        'componentType': 5126,
        'count': 2,
        'type': 'SCALAR'
      },
      {
        'bufferView': viewIndex + 1,
        'componentType': 5126,
        'count': 2,
        'type': 'VEC3'
      },
    ]);
    json['animations'] = [
      {
        'name': 'Wheel',
        'samplers': [
          {'input': accessorIndex, 'output': accessorIndex + 1}
        ],
        'channels': [
          {
            'sampler': 0,
            'target': {'node': 0, 'path': 'translation'}
          }
        ],
      },
    ];
    if (constantChannel) {
      json['bufferViews'].addAll([
        {'buffer': 0, 'byteOffset': original.length + 32, 'byteLength': 4},
        {'buffer': 0, 'byteOffset': original.length + 36, 'byteLength': 12},
      ]);
      json['accessors'].addAll([
        {
          'bufferView': viewIndex + 2,
          'componentType': 5126,
          'count': 1,
          'type': 'SCALAR'
        },
        {
          'bufferView': viewIndex + 3,
          'componentType': 5126,
          'count': 1,
          'type': 'VEC3'
        },
      ]);
      json['animations'][0]['samplers']
          .add({'input': accessorIndex + 2, 'output': accessorIndex + 3});
      json['animations'][0]['channels'].add({
        'sampler': 1,
        'target': {'node': 0, 'path': 'scale'}
      });
    }
  }
  json['buffers'][0]['byteLength'] = binary.length;
  json['extras'] = {
    'aveluneMaterialAnimations': {
      'schemaVersion': 1,
      'clips': [
        {
          'name': 'Water and fountain',
          'durationSeconds': 4,
          if (mixed) 'nodeAnimationIndex': 0,
          'tracks': [
            {
              'materialIndex': 0,
              'durationSeconds': .35,
              'times': [0, .35],
              'transforms': [
                [1, 0, 0, 1, 0, 0],
                [1, 0, 0, 1, 0, 1]
              ],
              'interpolation': 'LINEAR',
            },
          ],
        },
      ],
    },
  };
  edit?.call(json);
  return encodeGlb(json, binary);
}

Map<String, dynamic> materialTrack(Map<String, dynamic> json) =>
    json['extras']['aveluneMaterialAnimations']['clips'][0]['tracks'][0]
        as Map<String, dynamic>;

void main() {
  test('inspects material animation without inventing a node clip', () {
    final result = const GlbModel3dInspector().inspect(materialGlb());
    expect(result.animations.single.index, 0);
    expect(result.animations.single.name, 'Water and fountain');
    expect(result.animations.single.durationSeconds, 4);
    expect(result.diagnostics, isNot(contains('bounds.static_scene_only')));
  });

  test('indexes ambient clips after ordinary node animation clips', () {
    final result =
        const GlbModel3dInspector().inspect(materialGlb(mixed: true));
    expect(result.animations.map((clip) => clip.index), [0, 1]);
    expect(result.animations.map((clip) => clip.name),
        ['Wheel', 'Water and fountain']);
    expect(result.animations.map((clip) => clip.durationSeconds), [2, 4]);
  });

  test(
      'accepts a constant channel alongside a positive duration animated channel',
      () {
    final result = const GlbModel3dInspector().inspect(
      materialGlb(mixed: true, constantChannel: true),
    );
    expect(result.animations.first.durationSeconds, 2);
  });

  test(
      'rejects a clip with only a zero time channel even if an unused sampler has duration',
      () {
    expect(
        () => const GlbModel3dInspector().inspect(materialGlb(
              mixed: true,
              constantChannel: true,
              edit: (j) => j['animations'][0]['channels'].removeAt(0),
            )),
        throwsFormatException);
  });

  final invalid = <String, void Function(Map<String, dynamic>)>{
    'untextured target': (j) =>
        j['materials'][0].remove('pbrMetallicRoughness'),
    'unknown texture switch': (j) =>
        materialTrack(j)['textureIndices'] = [0, 1],
    'unknown material': (j) => materialTrack(j)['materialIndex'] = 1,
    'missing node clip': (j) => j['extras']['aveluneMaterialAnimations']
        ['clips'][0]['nodeAnimationIndex'] = 0,
    'invalid period': (j) => materialTrack(j)['durationSeconds'] = -1,
    'oversized key list': (j) =>
        materialTrack(j)['times'] = List.filled(65537, 0),
    'unknown version': (j) =>
        j['extras']['aveluneMaterialAnimations']['schemaVersion'] = 2,
  };
  for (final entry in invalid.entries) {
    test('rejects material animation with ${entry.key}', () {
      expect(
          () => const GlbModel3dInspector()
              .inspect(materialGlb(edit: entry.value)),
          throwsFormatException);
    });
  }

  test('exports material curves intact and rebuilds their inspection metadata',
      () {
    final bytes = materialGlb(mixed: true);
    final built = const GamePackageBuilder().build(
        manifest: spatialManifest(),
        payloadFiles: spatialPayload(modelBytes: bytes));
    const GamePackageInspector().inspect(built.packageBytes);
    final archive = ZipDecoder().decodeBytes(built.packageBytes);
    final project = ProjectManifest.fromJson(jsonDecode(utf8.decode(
            archive.findFile('project/project.json')!.content as List<int>))
        as Map<String, dynamic>);
    expect(
        project.models3d.single.inspection.animations.map((clip) => clip.index),
        [0, 1]);
    expect(
        archive.findFile('project/assets/models3d/model.glb')!.content, bytes);
  });
}
