import 'dart:typed_data';

import 'package:flame_3d/model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/glb_renderer_layout.dart';
import 'package:map_render_3d/src/model_byte_loader.dart';
import 'package:map_render_3d/src/spatial_clipped_model_cache.dart';
import 'package:map_render_3d/src/spatial_model_source_admission.dart';
import 'package:map_render_3d/src/spatial_model_triangle_clip.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';

import '../../map_authoring/test/support/glb_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the real loader retains source attributes without COLOR_0', () async {
    final model = await ModelByteLoader.load(_floorGlb());
    final surface = model.nodes.values.single.mesh!.surfaces.single;
    expect(surface, isA<SpatialModelSurface>());
    expect(
      (surface as SpatialModelSurface).vertexColors.every(
        (c) => c.r == 1 && c.g == 1 && c.b == 1 && c.a == 1,
      ),
      isTrue,
    );
    expect(surface.positions[1], -.125);
  });

  test(
    'the renderer receives a real one-cell model rather than the full floor',
    () async {
      final model = await ModelByteLoader.load(_floorGlb());
      final clipped = SpatialClippedModelCache().resolve(
        model,
        SpatialModelClipRect(left: 0, top: 0, right: 1, bottom: 1),
      );
      expect(clipped, isNotNull);
      expect(clipped!.bounds.max.x, 1);
      expect(clipped.bounds.max.z, 1);
      expect(clipped.bounds.min.y, -.125);
      final surface = clipped.model.nodes.values.single.mesh!.surfaces.single;
      expect(surface.positions.where((value) => value == 2), isEmpty);
    },
  );

  for (final colors in [false, true]) {
    test(
      'clipping retains affine UV, RGBA and normals with COLOR_0=$colors',
      () async {
        final model = await ModelByteLoader.load(_floorGlb(colors: colors));
        final before = _surface(model);
        final positions = before.positions.toList();
        final originalAttributes = before.clipVertices;
        final result = SpatialClippedModelCache().resolve(model, _cell)!;
        final surface = _surface(result.model);
        expect(surface.material, same(before.material));
        expect(surface.materialIndex, before.materialIndex);
        expect(surface.vertexColors, same(surface.vertexColors));
        expect(() => surface.vertexColors.clear(), throwsUnsupportedError);
        for (final vertex in surface.clipVertices) {
          expect(vertex.y, -.125);
          expect(vertex.u, closeTo(vertex.x * 2 - 2, 1e-6));
          expect(vertex.v, closeTo(vertex.z * 2 - 3, 1e-6));
          expect(vertex.r, colors ? .5 : 1);
          expect(vertex.g, vertex.r);
          expect(vertex.b, vertex.r);
          expect(vertex.a, 1);
          expect(vertex.normal, (x: 0.0, y: 1.0, z: 0.0));
        }
        expect(before.positions, positions);
        expect(
          before.clipVertices.map((v) => (v.u, v.v, v.y)),
          originalAttributes.map((v) => (v.u, v.v, v.y)),
        );
        expect(result.retainedBytes, surface.retainedGeometryBytes);
      },
    );
  }

  test('material alpha, culling and sampler identity are preserved', () async {
    final model = await ModelByteLoader.load(
      _floorGlb(
        edit: (json) {
          json['materials'][0]['alphaMode'] = 'MASK';
          json['materials'][0]['alphaCutoff'] = .5;
          json['materials'][0]['doubleSided'] = true;
        },
      ),
    );
    final material = _surface(model).material as SpatialPixelMaterial;
    final result = SpatialClippedModelCache().resolve(model, _cell)!;
    final retained = _surface(result.model).material as SpatialPixelMaterial;
    expect(retained, same(material));
    expect(retained.alphaMode, material.alphaMode);
    expect(retained.alphaCutoff, .5);
    expect(retained.cullMode, material.cullMode);
    expect(retained.wrapS, material.wrapS);
    expect(retained.wrapT, material.wrapT);
    expect(retained.albedoTexture, same(material.albedoTexture));
  });

  test(
    'parent affine transforms cut model-space XZ and retain local vertices',
    () async {
      final model = await ModelByteLoader.load(
        _floorGlb(
          edit: (json) {
            json['nodes'] = [
              {
                'name': 'root',
                'translation': [10, 2, 20],
                'children': [1],
              },
              {
                'name': 'floor',
                'mesh': 0,
                'scale': [2, 1, 3],
              },
            ];
          },
        ),
      );
      final matrices = [
        for (final node in model.nodes.values) node.transform.storage.toList(),
      ];
      final result = SpatialClippedModelCache().resolve(
        model,
        const SpatialModelClipRect(left: 10, top: 20, right: 12, bottom: 23),
      )!;
      expect(result.bounds.min.x, 10);
      expect(result.bounds.max.x, 12);
      expect(result.bounds.min.z, 20);
      expect(result.bounds.max.z, 23);
      expect(result.bounds.min.y, 1.875);
      expect(result.bounds.max.y, 1.875);
      expect(result.model.nodes[1]!.parentNodeIndex, 0);
      expect(
        _surface(result.model).clipVertices
            .every((v) => v.x >= 0 && v.x <= 1 && v.z >= 0 && v.z <= 1),
        isTrue,
      );
      expect([
        for (final node in model.nodes.values) node.transform.storage.toList(),
      ], matrices);
      for (final entry in model.nodes.entries) {
        expect(
          result.model.nodes[entry.key]!.transform,
          isNot(same(entry.value.transform)),
        );
      }
    },
  );

  test(
    'fractional heights remain distinct after loader and clipping',
    () async {
      final model = await ModelByteLoader.load(
        _floorGlb(heightValues: [-.125, -.1240234375, -.1240234375, -.125]),
      );
      final result = SpatialClippedModelCache().resolve(
        model,
        const SpatialModelClipRect(left: 0, top: 0, right: 2, bottom: 2),
      )!;
      expect(result.bounds.min.y, -.125);
      expect(result.bounds.max.y, -.1240234375);
      expect(
        _surface(result.model).clipVertices.map((v) => v.y).toSet().length,
        2,
      );
    },
  );

  test(
    'adjacent cells share exact source gradient and repeat UV at their seam',
    () async {
      final source = await ModelByteLoader.load(
        _floorGlb(
          colors: true,
          colorValues: [
            [.2, .3, .4, .5],
            [.8, .7, .6, 1],
            [.8, .7, .6, 1],
            [.2, .3, .4, .5],
          ],
        ),
      );
      final cache = SpatialClippedModelCache();
      final cells = [
        cache.resolve(
          source,
          const SpatialModelClipRect(left: 0, top: 0, right: 1, bottom: 2),
        )!,
        cache.resolve(
          source,
          const SpatialModelClipRect(left: 1, top: 0, right: 2, bottom: 2),
        )!,
      ];
      final seam = [
        for (final cell in cells)
          _surface(cell.model).clipVertices
              .where((v) => v.x == 1)
              .map((v) => (v.y, v.z, v.u, v.v, v.r, v.g, v.b, v.a))
              .toSet(),
      ];
      expect(seam[0], seam[1]);
      expect(seam[0], isNotEmpty);
      for (final cell in cells) {
        for (final vertex in _surface(cell.model).clipVertices) {
          expect(vertex.r, closeTo(.2 + vertex.x * .3, 1e-6));
          expect(vertex.g, closeTo(.3 + vertex.x * .2, 1e-6));
          expect(vertex.b, closeTo(.4 + vertex.x * .1, 1e-6));
          expect(vertex.a, closeTo(.5 + vertex.x * .25, 1e-6));
          expect(vertex.u, closeTo(vertex.x * 2 - 2, 1e-6));
          expect(vertex.v, closeTo(vertex.z * 2 - 3, 1e-6));
        }
      }
    },
  );

  test(
    'LRU shares a result, distinguishes sources and bounds empty entries',
    () async {
      final source = await ModelByteLoader.load(_floorGlb());
      final other = await ModelByteLoader.load(_floorGlb());
      final cache = SpatialClippedModelCache(maximumEntries: 2);
      final first = cache.resolve(source, _cell);
      expect(cache.resolve(source, _cell), same(first));
      expect(cache.hits, 1);
      expect(cache.misses, 1);
      expect(cache.resolve(other, _cell), isNot(same(first)));
      expect(cache.entryCount, 2);
      expect(cache.resolve(source, _empty), isNull);
      expect(cache.entryCount, 2);
      expect(cache.resolve(source, _empty), isNull);
      expect(cache.hits, 2);
      expect(cache.resolve(source, _cell), isNot(same(first)));
      expect(cache.misses, 4);
      expect(cache.entryCount, 2);
      cache.releaseSource(source);
      expect(cache.entryCount, 0);
      expect(cache.retainedBytes, 0);
    },
  );

  test(
    'retained typed geometry bytes evict LRU and clear releases entries',
    () async {
      final source = await ModelByteLoader.load(_floorGlb());
      final sample = SpatialClippedModelCache().resolve(source, _cell)!;
      final cache = SpatialClippedModelCache(
        maximumRetainedBytes: sample.retainedBytes,
      );
      final first = cache.resolve(source, _cell);
      final second = cache.resolve(
        source,
        const SpatialModelClipRect(left: 1, top: 1, right: 2, bottom: 2),
      );
      expect(second, isNotNull);
      expect(cache.entryCount, 1);
      expect(cache.retainedBytes, sample.retainedBytes);
      expect(cache.resolve(source, _cell), isNot(same(first)));
      cache.clear();
      expect(cache.entryCount, 0);
      expect(cache.retainedBytes, 0);
      expect(cache.misses, 3);
    },
  );

  test(
    'unqualified model objects cannot enter the static clipping cache',
    () async {
      final source = await ModelByteLoader.load(_floorGlb());
      final unknown = Model(nodes: source.nodes, animations: const []);
      expect(
        () => SpatialClippedModelCache().resolve(unknown, _cell),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'reason',
            contains('unqualified_source'),
          ),
        ),
      );
    },
  );

  for (final (reason, sourceDocument) in <(String, Map<String, dynamic>)>[
    (
      'geometry_animation',
      {
        'animations': [{}],
      },
    ),
    (
      'skin',
      {
        'skins': [{}],
      },
    ),
    (
      'skin',
      {
        'nodes': [
          {'skin': 0},
        ],
      },
    ),
    (
      'morph',
      {
        'nodes': [
          {
            'weights': [0],
          },
        ],
      },
    ),
    (
      'morph',
      {
        'meshes': [
          {
            'weights': [0],
          },
        ],
      },
    ),
    (
      'morph',
      {
        'meshes': [
          {
            'primitives': [
              {'targets': []},
            ],
          },
        ],
      },
    ),
    (
      'skin_attributes',
      {
        'meshes': [
          {
            'primitives': [
              {
                'attributes': {'JOINTS_0': 0},
              },
            ],
          },
        ],
      },
    ),
    (
      'non_triangle_primitive',
      {
        'meshes': [
          {
            'primitives': [
              {'mode': 5},
            ],
          },
        ],
      },
    ),
  ]) {
    test(
      'source admission rejects $reason even without parsed animation index: $sourceDocument',
      () async {
        final source = await ModelByteLoader.load(_floorGlb());
        registerSpatialModelClipSource(
          source,
          sourceDocument,
          hasMaterialAnimations: false,
        );
        expect(source.animations, isEmpty);
        expect(
          () => SpatialClippedModelCache().resolve(source, _cell),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'reason',
              contains(reason),
            ),
          ),
        );
      },
    );
  }

  test(
    'real loader material animation is rejected rather than silently frozen',
    () async {
      final model = await ModelByteLoader.load(
        _floorGlb(
          edit: (json) {
            json['extras'] = {
              'aveluneMaterialAnimations': {
                'schemaVersion': 1,
                'clips': [
                  {
                    'name': 'scroll',
                    'durationSeconds': 1,
                    'tracks': [
                      {
                        'materialIndex': 0,
                        'times': [0, 1],
                        'transforms': [
                          [1, 0, 0, 1, 0, 0],
                          [1, 0, 0, 1, .5, .25],
                        ],
                        'interpolation': 'LINEAR',
                      },
                    ],
                  },
                ],
              },
            };
          },
        ),
      );
      expect(model.animations, isEmpty);
      expect(
        () => SpatialClippedModelCache().resolve(model, _cell),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'reason',
            contains('material_animation'),
          ),
        ),
      );
    },
  );

  test('real node animation is rejected before clipping', () async {
    final source = await ModelByteLoader.load(
      Uint8List.fromList(animatedGlb()),
    );
    expect(source.animations, isNotEmpty);
    expect(
      () => SpatialClippedModelCache().resolve(source, _cell),
      throwsFormatException,
    );
  });

  test(
    'singular or nonfinite node transforms fail without caching geometry',
    () async {
      final source = await ModelByteLoader.load(_floorGlb());
      final cache = SpatialClippedModelCache();
      source.nodes.values.single.transform[0] = 0;
      expect(() => cache.resolve(source, _cell), throwsFormatException);
      source.nodes.values.single.transform[0] = double.nan;
      expect(() => cache.resolve(source, _cell), throwsFormatException);
      expect(cache.entryCount, 0);
      expect(cache.retainedBytes, 0);
    },
  );

  test('invalid clip and all geometry budgets fail closed', () async {
    final source = await ModelByteLoader.load(_floorGlb());
    for (final clip in [
      const SpatialModelClipRect(
        left: 0,
        top: 0,
        right: double.infinity,
        bottom: 1,
      ),
      const SpatialModelClipRect(left: 1, top: 0, right: 0, bottom: 1),
    ]) {
      expect(
        () => SpatialClippedModelCache().resolve(source, clip),
        throwsFormatException,
      );
    }
    for (final cache in [
      SpatialClippedModelCache(maximumInputVertices: 3),
      SpatialClippedModelCache(maximumInputTriangles: 1),
      SpatialClippedModelCache(maximumOutputVertices: 3),
      SpatialClippedModelCache(maximumOutputTriangles: 1),
      SpatialClippedModelCache(maximumRetainedBytes: 1),
    ]) {
      expect(() => cache.resolve(source, _cell), throwsFormatException);
      expect(cache.entryCount, 0);
      expect(cache.retainedBytes, 0);
    }
    expect(
      () => SpatialClippedModelCache(maximumEntries: 0),
      throwsFormatException,
    );
    expect(
      () => SpatialClippedModelCache(maximumOutputVertices: 65536),
      throwsFormatException,
    );
  });
}

const _cell = SpatialModelClipRect(left: 0, top: 0, right: 1, bottom: 1);
const _empty = SpatialModelClipRect(left: 4, top: 4, right: 5, bottom: 5);

SpatialModelSurface _surface(Model model) =>
    model.nodes.values
            .where((node) => node.mesh != null)
            .single
            .mesh!
            .surfaces
            .single
        as SpatialModelSurface;

Uint8List _floorGlb({
  bool colors = false,
  List<double>? heightValues,
  List<List<double>>? colorValues,
  void Function(Map<String, dynamic>)? edit,
}) {
  final binary = ByteData(204);
  const positions = <double>[
    0,
    -.125,
    0,
    2,
    -.125,
    0,
    2,
    -.125,
    2,
    0,
    -.125,
    2,
  ];
  const uvs = <double>[-2, -3, 2, -3, 2, 1, -2, 1];
  for (var index = 0; index < positions.length; index++) {
    binary.setFloat32(
      index * 4,
      index % 3 == 1 && heightValues != null
          ? heightValues[index ~/ 3]
          : positions[index],
      Endian.little,
    );
    binary.setFloat32(48 + index * 4, index % 3 == 1 ? 1 : 0, Endian.little);
  }
  for (var index = 0; index < uvs.length; index++) {
    binary.setFloat32(96 + index * 4, uvs[index], Endian.little);
  }
  for (var index = 0; index < 16; index++) {
    binary.setFloat32(
      128 + index * 4,
      colorValues?[index ~/ 4][index % 4] ?? (index % 4 == 3 ? 1 : .5),
      Endian.little,
    );
  }
  for (final (index, value) in [0, 1, 2, 0, 2, 3].indexed) {
    binary.setUint16(192 + index * 2, value, Endian.little);
  }
  final json = <String, dynamic>{
    'asset': {'version': '2.0'},
    'scene': 0,
    'scenes': [
      {
        'nodes': [0],
      },
    ],
    'nodes': [
      {'mesh': 0},
    ],
    'meshes': [
      {
        'primitives': [
          {
            'attributes': {
              'POSITION': 0,
              'NORMAL': 1,
              'TEXCOORD_0': 2,
              if (colors) 'COLOR_0': 3,
            },
            'indices': 4,
            'material': 0,
          },
        ],
      },
    ],
    'materials': [
      <String, dynamic>{'pbrMetallicRoughness': <String, dynamic>{}},
    ],
    'buffers': [
      {'byteLength': 204},
    ],
    'bufferViews': [
      for (final (offset, length) in [
        (0, 48),
        (48, 48),
        (96, 32),
        (128, 64),
        (192, 12),
      ])
        {'buffer': 0, 'byteOffset': offset, 'byteLength': length},
    ],
    'accessors': [
      for (final (index, type) in ['VEC3', 'VEC3', 'VEC2', 'VEC4'].indexed)
        {'bufferView': index, 'componentType': 5126, 'count': 4, 'type': type},
      {'bufferView': 4, 'componentType': 5123, 'count': 6, 'type': 'SCALAR'},
    ],
  };
  edit?.call(json);
  return Uint8List.fromList(encodeGlb(json, binary.buffer.asUint8List()));
}
