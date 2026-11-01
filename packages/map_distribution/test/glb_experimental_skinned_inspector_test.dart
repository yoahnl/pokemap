import 'dart:convert';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_distribution/src/deterministic_zip_encoder.dart';
import 'package:test/test.dart';

import 'support/glb_fixture.dart';

List<int> _skinnedGlb({
  void Function(Map<String, dynamic> json, ByteData binary)? edit,
}) {
  final binary = ByteData(192);
  final positions = [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0];
  for (final (index, value) in positions.indexed) {
    binary.setFloat32(index * 4, value, Endian.little);
  }
  for (var vertex = 0; vertex < 3; vertex++) {
    binary.setFloat32(48 + vertex * 16, 1, Endian.little);
  }
  for (var index = 0; index < 4; index++) {
    binary.setFloat32(96 + (index * 5) * 4, 1, Endian.little);
  }
  binary.setFloat32(164, 1, Endian.little);
  binary.setFloat32(180, 1, Endian.little);
  final json = <String, dynamic>{
    'asset': {'version': '2.0'},
    'scene': 0,
    'scenes': [
      {
        'nodes': [0, 1]
      }
    ],
    'nodes': [
      {'mesh': 0, 'skin': 0},
      <String, dynamic>{}
    ],
    'skins': [
      {
        'joints': [1],
        'inverseBindMatrices': 3
      }
    ],
    'meshes': [
      {
        'primitives': [
          {
            'attributes': {'POSITION': 0, 'JOINTS_0': 1, 'WEIGHTS_0': 2}
          }
        ]
      }
    ],
    'buffers': [
      {'byteLength': binary.lengthInBytes}
    ],
    'bufferViews': [
      {'buffer': 0, 'byteOffset': 0, 'byteLength': 36},
      {'buffer': 0, 'byteOffset': 36, 'byteLength': 12},
      {'buffer': 0, 'byteOffset': 48, 'byteLength': 48},
      {'buffer': 0, 'byteOffset': 96, 'byteLength': 64},
      {'buffer': 0, 'byteOffset': 160, 'byteLength': 8},
      {'buffer': 0, 'byteOffset': 168, 'byteLength': 24},
    ],
    'accessors': [
      {'bufferView': 0, 'componentType': 5126, 'count': 3, 'type': 'VEC3'},
      {'bufferView': 1, 'componentType': 5121, 'count': 3, 'type': 'VEC4'},
      {'bufferView': 2, 'componentType': 5126, 'count': 3, 'type': 'VEC4'},
      {'bufferView': 3, 'componentType': 5126, 'count': 1, 'type': 'MAT4'},
      {'bufferView': 4, 'componentType': 5126, 'count': 2, 'type': 'SCALAR'},
      {'bufferView': 5, 'componentType': 5126, 'count': 2, 'type': 'VEC3'},
    ],
    'animations': [
      {
        'name': 'joint',
        'samplers': [
          {'input': 4, 'output': 5}
        ],
        'channels': [
          {
            'sampler': 0,
            'target': {'node': 1, 'path': 'translation'}
          }
        ]
      }
    ],
  };
  final mutable = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
  edit?.call(mutable, binary);
  return encodeGlb(mutable, binary.buffer.asUint8List());
}

List<int> _largeSkinnedGlb({int vertices = 3, int triangles = 1}) {
  final source = Uint8List.fromList(_skinnedGlb());
  final header = ByteData.sublistView(source);
  final jsonLength = header.getUint32(12, Endian.little);
  final json = jsonDecode(utf8.decode(source.sublist(20, 20 + jsonLength)))
      as Map<String, dynamic>;
  final original = source.sublist(28 + jsonLength);
  final commonStart = vertices * 32;
  final indicesStart = commonStart + 96;
  final binary = Uint8List(indicesStart + triangles * 6);
  binary.setRange(0, 36, original);
  binary.setRange(commonStart, commonStart + 96, original, 96);
  final data = ByteData.sublistView(binary);
  for (var vertex = 0; vertex < vertices; vertex++) {
    data.setFloat32(vertices * 16 + vertex * 16, 1, Endian.little);
  }
  for (var index = 0; index < triangles * 3; index++) {
    data.setUint16(indicesStart + index * 2, index % 3, Endian.little);
  }
  json['buffers'][0]['byteLength'] = binary.length;
  json['bufferViews'] = [
    {'buffer': 0, 'byteOffset': 0, 'byteLength': vertices * 12},
    {'buffer': 0, 'byteOffset': vertices * 12, 'byteLength': vertices * 4},
    {'buffer': 0, 'byteOffset': vertices * 16, 'byteLength': vertices * 16},
    {'buffer': 0, 'byteOffset': commonStart, 'byteLength': 64},
    {'buffer': 0, 'byteOffset': commonStart + 64, 'byteLength': 8},
    {'buffer': 0, 'byteOffset': commonStart + 72, 'byteLength': 24},
    {'buffer': 0, 'byteOffset': indicesStart, 'byteLength': triangles * 6},
  ];
  for (var index = 0; index < 3; index++) {
    json['accessors'][index]['count'] = vertices;
  }
  json['accessors'].add({
    'bufferView': 6,
    'componentType': 5123,
    'count': triangles * 3,
    'type': 'SCALAR'
  });
  json['meshes'][0]['primitives'][0]['indices'] = 6;
  return encodeGlb(json, binary);
}

List<int> _duplicateJsonKey(List<int> source) {
  final bytes = Uint8List.fromList(source);
  final oldLength = ByteData.sublistView(bytes).getUint32(12, Endian.little);
  final text = utf8.decode(bytes.sublist(20, 20 + oldLength)).trimRight();
  final duplicated =
      utf8.encode(text.replaceFirst('"asset":', '"asset":{},"asset":'));
  final newLength = (duplicated.length + 3) ~/ 4 * 4;
  final output = Uint8List(bytes.length - oldLength + newLength);
  output.setRange(0, 12, bytes);
  final header = ByteData.sublistView(output);
  header.setUint32(8, output.length, Endian.little);
  header.setUint32(12, newLength, Endian.little);
  header.setUint32(16, 0x4e4f534a, Endian.little);
  output.fillRange(20, 20 + newLength, 32);
  output.setRange(20, 20 + duplicated.length, duplicated);
  output.setRange(20 + newLength, output.length, bytes, 20 + oldLength);
  return output;
}

List<int> partitionedSkinnedGlb({int triangles = 2, int verticesPerGroup = 3}) {
  final vertices = verticesPerGroup * 2;
  final source = Uint8List.fromList(
      _largeSkinnedGlb(vertices: vertices, triangles: triangles));
  final jsonLength = ByteData.sublistView(source).getUint32(12, Endian.little);
  final json = jsonDecode(utf8.decode(source.sublist(20, 20 + jsonLength)))
      as Map<String, dynamic>;
  final binary = Uint8List.fromList(source.sublist(28 + jsonLength));
  final data = ByteData.sublistView(binary);
  for (var vertex = 0; vertex < vertices; vertex++) {
    final group = vertex ~/ verticesPerGroup;
    final local = vertex % verticesPerGroup;
    data.setFloat32(vertex * 12, local % 3 == 1 ? 1 : 0, Endian.little);
    data.setFloat32(vertex * 12 + 4, local % 3 == 2 ? 1 : 0, Endian.little);
    data.setFloat32(vertex * 12 + 8, group == 0 ? 0 : -1, Endian.little);
    for (var component = 0; component < 4; component++) {
      data.setUint8(vertices * 12 + vertex * 4 + component,
          group * 12 + local % 3 * 4 + component);
      data.setFloat32(
          vertices * 16 + vertex * 16 + component * 4, .25, Endian.little);
    }
  }
  for (var triangle = 0; triangle < triangles; triangle++) {
    final group = (triangle ~/ (verticesPerGroup ~/ 3)) % 2;
    final localTriangle = triangle % (verticesPerGroup ~/ 3);
    for (var component = 0; component < 3; component++) {
      data.setUint16(
          vertices * 32 + 96 + (triangle * 3 + component) * 2,
          group * verticesPerGroup + localTriangle * 3 + component,
          Endian.little);
    }
  }
  json['nodes'] = [
    {'mesh': 0, 'skin': 0},
    for (var i = 0; i < 24; i++) <String, dynamic>{},
  ];
  json['scenes'][0]['nodes'] = [for (var i = 0; i <= 24; i++) i];
  json['skins'] = [
    {
      'joints': [for (var i = 1; i <= 24; i++) i]
    }
  ];
  return encodeGlb(json, binary);
}

List<int> unsignedShortSkinnedGlb() {
  final source = Uint8List.fromList(_skinnedGlb());
  final jsonLength = ByteData.sublistView(source).getUint32(12, Endian.little);
  final json = jsonDecode(utf8.decode(source.sublist(20, 20 + jsonLength)))
      as Map<String, dynamic>;
  final original = source.sublist(28 + jsonLength);
  final binary = Uint8List(original.length + 24)
    ..setRange(0, original.length, original);
  json['buffers'][0]['byteLength'] = binary.length;
  json['bufferViews'][1]['byteOffset'] = original.length;
  json['bufferViews'][1]['byteLength'] = 24;
  json['accessors'][1]['componentType'] = 5123;
  json['skins'][0].remove('inverseBindMatrices');
  json['skins'][0]['skeleton'] = 1;
  json['animations'][0]['samplers'][0]['interpolation'] = 'STEP';
  json['bufferViews'].add({'buffer': 0, 'byteOffset': 168, 'byteLength': 24});
  json['accessors'].add(
      {'bufferView': 6, 'componentType': 5126, 'count': 3, 'type': 'VEC2'});
  json['meshes'][0]['primitives'][0]['attributes'].addAll({
    'NORMAL': 0,
    'TEXCOORD_0': 6,
    'COLOR_0': 0,
  });
  return encodeGlb(json, binary);
}

List<int> _manyJointInstances(int extraInstances) => _skinnedGlb(edit: (j, _) {
      j['nodes'] = [
        {'mesh': 0, 'skin': 0},
        for (var joint = 1; joint <= 100; joint++)
          {
            if (joint < 100) 'children': [joint + 1]
          },
        for (var i = 0; i < extraInstances; i++) {'mesh': 0, 'skin': 0},
      ];
      j['scenes'][0]['nodes'] = [
        0,
        1,
        for (var i = 0; i < extraInstances; i++) i + 101,
      ];
      j['skins'] = [
        {
          'joints': [for (var joint = 1; joint <= 100; joint++) joint],
          'skeleton': 1,
        }
      ];
    });

Map<String, List<int>> _packagePayload(String modelPath, List<int> model) {
  final project = ProjectManifest.fromJson({
    'name': 'Skeletal inspection test',
    'version': 'v8',
    'maps': <Object>[],
    'tilesets': <Object>[],
    'pokemon': const ProjectPokemonConfig(
      enabled: false,
      ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    ).toJson(),
  });
  final publication = PortableCatalogPublication.encodeProject(project);
  return {
    'project/project.json': CanonicalJson.encodeUtf8(publication.descriptor),
    for (final object in publication.storage.objects.entries)
      'project/catalog/objects/${object.key}.json': object.value,
    modelPath: model,
  };
}

GamePackageManifest _manifest(Map<String, List<int>> payload) =>
    const GamePackageManifestCodec().decodeJson({
      'packageFormat': 1,
      'gameId': 'games.example.skinned',
      'gameVersion': '1.0.0',
      'title': 'Skeletal inspection test',
      'author': {'name': 'Test'},
      'compatibility': {
        'minHubVersion': '1.0.0',
        'runtimeApi': '>=1.0.0 <2.0.0',
        'projectFormat': 'v8',
        'saveFormat': 1,
        'compatibilityId': 'main',
        'requiredCapabilities': ['catalog.partitioned@2'],
      },
      'locales': {
        'default': 'fr',
        'supported': ['fr']
      },
      'content': const GamePackageInventoryBuilder().build(payload).toJson(),
    });

Uint8List _rawPackage(Map<String, List<int>> payload) {
  final files = {
    'game-manifest.json': const GamePackageManifestCodec()
        .encodeCanonicalUtf8(_manifest(payload)),
    ...payload,
  };
  final entries = files.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return DeterministicZipEncoder.encode(entries);
}

final class _MemoryPackageSource implements RandomAccessPackageSource {
  _MemoryPackageSource(this.bytes);
  final Uint8List bytes;
  @override
  int get length => bytes.length;
  @override
  Uint8List readAtSync(int offset, int length) =>
      Uint8List.sublistView(bytes, offset, offset + length);
}

void main() {
  test('skeletal inspection remains disabled by default', () {
    expect(() => const GlbModel3dInspector().inspect(_skinnedGlb()),
        throwsFormatException);
  });

  test('explicit experimental profile inspects a supported skeletal model', () {
    const inspector = GlbModel3dInspector(experimentalSkinnedModels: true);
    final result = inspector.inspect(_skinnedGlb());
    expect(result.meshCount, 1);
    expect(result.triangleCount, 1);
    expect(result.animations.single.name, 'joint');
    expect(result.diagnostics, contains('bounds.static_scene_only'));
  });

  test('both profiles retain identical inspection for existing models', () {
    final bytes = animatedGlb();
    final baseline = const GlbModel3dInspector().inspect(bytes).toJson();
    final experimental = const GlbModel3dInspector(
      experimentalSkinnedModels: true,
    ).inspect(bytes).toJson();
    expect(experimental, baseline);
  });

  test('enforces the skinned geometry limits without weakening old quotas', () {
    const inspector = GlbModel3dInspector(experimentalSkinnedModels: true);
    expect(() => inspector.inspect(_largeSkinnedGlb(vertices: 65535)),
        returnsNormally);
    expect(() => inspector.inspect(_largeSkinnedGlb(vertices: 65536)),
        throwsFormatException);
    expect(() => inspector.inspect(_largeSkinnedGlb(triangles: 200001)),
        throwsFormatException);
  });

  test('inspects a partitionable model with 24 active joints', () {
    final inspection =
        const GlbModel3dInspector(experimentalSkinnedModels: true)
            .inspect(partitionedSkinnedGlb());
    expect(inspection.triangleCount, 2);
    expect(inspection.animations.single.name, 'joint');
    expect(inspection.diagnostics, contains('bounds.static_scene_only'));
  });

  test('enforces actual partition surface and output-vertex limits', () {
    const inspector = GlbModel3dInspector(experimentalSkinnedModels: true);
    expect(() => inspector.inspect(partitionedSkinnedGlb(triangles: 1024)),
        returnsNormally);
    final partitionLimit = throwsA(isA<FormatException>()
        .having((error) => error.message, 'message', contains('partition')));
    expect(() => inspector.inspect(partitionedSkinnedGlb(triangles: 1025)),
        partitionLimit);
    expect(
        () => inspector.inspect(
            partitionedSkinnedGlb(triangles: 85 * 785, verticesPerGroup: 255)),
        partitionLimit);
  });

  test('bounds total joint instances even with deep shared skeletons', () {
    const inspector = GlbModel3dInspector(experimentalSkinnedModels: true);
    expect(() => inspector.inspect(_manyJointInstances(654)), returnsNormally);
    expect(
        () => inspector.inspect(_manyJointInstances(655)),
        throwsA(isA<FormatException>().having((error) => error.message,
            'message', contains('Skin joints exceed the scene limits'))));
  });

  test('supports unsigned-short joints, STEP and tightly packed attributes',
      () {
    final inspection =
        const GlbModel3dInspector(experimentalSkinnedModels: true)
            .inspect(unsignedShortSkinnedGlb());
    expect(inspection.triangleCount, 1);
    expect(inspection.animations.single.name, 'joint');
  });

  test('the experimental profile rejects ambiguous duplicate JSON keys', () {
    expect(
        () => const GlbModel3dInspector(experimentalSkinnedModels: true)
            .inspect(_duplicateJsonKey(_skinnedGlb())),
        throwsFormatException);
  });

  test('the experimental profile bounds GLB JSON complexity', () {
    final source = _skinnedGlb(edit: (json, _) {
      json['extras'] = {'unused': List.filled(50000, 0)};
    });
    expect(
        () => const GlbModel3dInspector(experimentalSkinnedModels: true)
            .inspect(source),
        throwsFormatException);
  });

  test('builders and every package inspector keep skeletal GLBs closed',
      () async {
    const inspector = GamePackageInspector();
    for (final path in [
      'project/assets/model.glb',
      'project/assets/.pokemap-store/${'a' * 64}.blob',
    ]) {
      final legacy = _packagePayload(path, triangleGlb());
      final legacyBuilt = const GamePackageBuilder().build(
        manifest: _manifest(legacy),
        payloadFiles: legacy,
      );
      final legacyBytes = Uint8List.fromList(legacyBuilt.packageBytes);
      final memory = inspector.inspect(legacyBytes);
      final sync =
          inspector.inspectSourceSync(_MemoryPackageSource(legacyBytes));
      final parallel = await inspector.inspectSourceParallel(
        () async => _MemoryPackageSource(legacyBytes),
        workers: 3,
      );
      expect(sync.receipt.toJson(), memory.receipt.toJson());
      expect(parallel.receipt.toJson(), memory.receipt.toJson());

      final payload = _packagePayload(path, _skinnedGlb());
      final match = throwsA(isA<GamePackageFormatException>()
          .having((error) => error.code, 'code', 'invalidModel3d')
          .having((error) => error.path, 'path', path));
      expect(
          () => const GamePackageBuilder()
              .build(manifest: _manifest(payload), payloadFiles: payload),
          match);
      final bytes = _rawPackage(payload);
      expect(() => inspector.inspect(bytes), match);
      expect(() => inspector.inspectSourceSync(_MemoryPackageSource(bytes)),
          match);
      await expectLater(
          inspector.inspectSourceParallel(
              () async => _MemoryPackageSource(bytes),
              workers: 3),
          match);
    }
  });

  final cases = <String, void Function(Map<String, dynamic>, ByteData)>{
    'missing weights': (j, _) =>
        j['meshes'][0]['primitives'][0]['attributes'].remove('WEIGHTS_0'),
    'extra joints': (j, _) =>
        j['meshes'][0]['primitives'][0]['attributes']['JOINTS_1'] = 1,
    'extra weights': (j, _) =>
        j['meshes'][0]['primitives'][0]['attributes']['WEIGHTS_1'] = 2,
    'unsupported texture coordinates': (j, _) {
      j['bufferViews'].add({'buffer': 0, 'byteOffset': 168, 'byteLength': 24});
      j['accessors'].add(
          {'bufferView': 6, 'componentType': 5126, 'count': 3, 'type': 'VEC2'});
      j['meshes'][0]['primitives'][0]['attributes']['TEXCOORD_1'] = 6;
    },
    'ignored tangent': (j, _) =>
        j['meshes'][0]['primitives'][0]['attributes']['TANGENT'] = 0,
    'unsupported optional extension': (j, _) =>
        j['extensionsUsed'] = ['EXT_meshopt_compression'],
    'joint type': (j, _) => j['accessors'][1]['componentType'] = 5120,
    'normalized joints': (j, _) => j['accessors'][1]['normalized'] = true,
    'normalized weights': (j, _) {
      j['accessors'][2]['componentType'] = 5121;
      j['accessors'][2]['normalized'] = true;
    },
    'joint out of range': (_, b) => b.setUint8(36, 1),
    'zero weights': (_, b) => b.setFloat32(48, 0, Endian.little),
    'unbalanced weights': (_, b) => b.setFloat32(48, .5, Endian.little),
    'negative weights': (_, b) => b.setFloat32(48, -.5, Endian.little),
    'skin without mesh': (j, _) {
      j['nodes'][0].remove('mesh');
      j['nodes'].add({'mesh': 1});
      j['scenes'][0]['nodes'].add(2);
      j['meshes'].add({
        'primitives': [
          {
            'attributes': {'POSITION': 0}
          }
        ]
      });
    },
    'empty skinned mesh': (j, _) {
      j['meshes'][0]['primitives'] = [];
      j['nodes'].add({'mesh': 1});
      j['scenes'][0]['nodes'].add(2);
      j['meshes'].add({
        'primitives': [
          {
            'attributes': {'POSITION': 0}
          }
        ]
      });
    },
    'weights without skin': (j, _) => j['nodes'][0].remove('skin'),
    'missing joint': (j, _) => j['skins'][0]['joints'] = [3],
    'duplicate joint': (j, _) => j['skins'][0]['joints'] = [1, 1],
    'unreachable joint': (j, _) => j['scenes'][0]['nodes'] = [0],
    'cyclic node dependency': (j, _) {
      j['scenes'][0]['nodes'] = [0];
      j['nodes'][0]['children'] = [1];
    },
    'invalid inverse matrix': (_, b) => b.setFloat32(108, .5, Endian.little),
    'wrong inverse accessor': (j, _) =>
        j['skins'][0]['inverseBindMatrices'] = 2,
    'inverse matrix count': (j, _) {
      j['nodes'].add(<String, dynamic>{});
      j['scenes'][0]['nodes'].add(2);
      j['skins'][0]['joints'] = [1, 2];
    },
    'incomplete accessor stride': (j, _) =>
        j['bufferViews'][1]['byteLength'] = 13,
    'interleaved accessor stride': (j, _) {
      j['bufferViews'][0]['byteStride'] = 16;
      j['bufferViews'][0]['byteLength'] = 48;
    },
    'skeleton outside joint ancestry': (j, _) {
      j['nodes'].add(<String, dynamic>{});
      j['scenes'][0]['nodes'].add(2);
      j['skins'][0]['skeleton'] = 2;
    },
    'skeleton in sibling branch': (j, _) {
      j['nodes'].addAll([<String, dynamic>{}, <String, dynamic>{}]);
      j['scenes'][0]['nodes'] = [0, 1];
      j['nodes'][1]['children'] = [2, 3];
      j['skins'][0]['joints'] = [2];
      j['skins'][0]['skeleton'] = 3;
    },
    'nonpositive animated scale': (j, _) =>
        j['animations'][0]['channels'][0]['target']['path'] = 'scale',
    'nonunit animated rotation': (j, b) {
      j['accessors'].add(
          {'bufferView': 3, 'componentType': 5126, 'count': 3, 'type': 'VEC4'});
      j['animations'][0]['samplers'][0]['output'] = 6;
      j['animations'][0]['channels'][0]['target']['path'] = 'rotation';
      j['accessors'][4]['count'] = 3;
      j['bufferViews'][4]['byteLength'] = 12;
      b.setFloat32(168, 2, Endian.little);
      b.setFloat32(96, .5, Endian.little);
    },
    'animation outside the default scene': (j, _) {
      j['nodes'].add(<String, dynamic>{});
      j['animations'][0]['channels'][0]['target']['node'] = 2;
    },
    'unsupported interpolation': (j, _) =>
        j['animations'][0]['samplers'][0]['interpolation'] = 'CUBICSPLINE',
  };
  const inspector = GlbModel3dInspector(experimentalSkinnedModels: true);
  for (final entry in cases.entries) {
    test('rejects ${entry.key}', () {
      expect(() => inspector.inspect(_skinnedGlb(edit: entry.value)),
          throwsFormatException);
    });
  }
}
