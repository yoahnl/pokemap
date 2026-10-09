import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flame_3d/graphics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';
import 'package:map_render_3d/src/glb_renderer_layout.dart';

import '../../map_distribution/test/support/glb_fixture.dart';

Uint8List sharedIndexedGlb({bool mismatchedColors = false}) {
  final binary = ByteData(300);
  final positions = [
    [0.0, 0.0, 0.0],
    [1.0, 0.0, 0.0],
    [0.0, 1.0, 0.0],
    [2.0, 0.0, 0.0],
    [3.0, 0.0, 0.0],
    [2.0, 1.0, 0.0],
  ];
  for (var i = 0; i < 6; i++) {
    for (var axis = 0; axis < 3; axis++) {
      binary.setFloat32(i * 12 + axis * 4, positions[i][axis], Endian.little);
      binary.setFloat32(
        72 + i * 12 + axis * 4,
        axis == 2 ? 1 : 0,
        Endian.little,
      );
    }
    binary.setFloat32(144 + i * 8, i / 8, Endian.little);
    binary.setFloat32(148 + i * 8, 1 - i / 8, Endian.little);
    for (var axis = 0; axis < 4; axis++) {
      binary.setFloat32(
        192 + i * 16 + axis * 4,
        axis == 3 ? 1 : i / 8,
        Endian.little,
      );
    }
  }
  for (final (i, index) in [2, 0, 1, 5, 3, 4].indexed) {
    binary.setUint16(288 + i * 2, index, Endian.little);
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
          for (final index in [4, 5])
            {
              'attributes': {
                'POSITION': 0,
                'NORMAL': 1,
                'TEXCOORD_0': 2,
                'COLOR_0': 3,
              },
              'indices': index,
              'material': 0,
            },
        ],
      },
    ],
    'materials': [
      {'pbrMetallicRoughness': {}},
    ],
    'buffers': [
      {'byteLength': binary.lengthInBytes},
    ],
    'bufferViews': [
      for (final (offset, length) in [
        (0, 72),
        (72, 72),
        (144, 48),
        (192, 96),
        (288, 6),
        (294, 6),
      ])
        {'buffer': 0, 'byteOffset': offset, 'byteLength': length},
    ],
    'accessors': [
      for (final (index, type) in ['VEC3', 'VEC3', 'VEC2', 'VEC4'].indexed)
        {
          'bufferView': index,
          'componentType': 5126,
          'count': index == 3 && mismatchedColors ? 5 : 6,
          'type': type,
        },
      for (final index in [4, 5])
        {
          'bufferView': index,
          'componentType': 5123,
          'count': 3,
          'type': 'SCALAR',
        },
    ],
  };
  return Uint8List.fromList(encodeGlb(json, binary.buffer.asUint8List()));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'indexed primitives retain original vertex identifiers across shared attribute arrays',
    () async {
      final model = await ModelByteLoader.load(sharedIndexedGlb());
      final surfaces = model.nodes.values.single.mesh!.surfaces.toList();
      expect(surfaces.map((surface) => surface.vertexCount), [3, 6]);
      expect(surfaces[0].indices, [2, 0, 1]);
      expect(surfaces[1].indices, [5, 3, 4]);
      for (final surface in surfaces) {
        final colors = (surface as SpatialModelSurface).vertexColors;
        for (final index in surface.indices) {
          expect(colors[index].r, index / 8);
        }
      }
      expect(surfaces[0].positions, [0, 0, 0, 1, 0, 0, 0, 1, 0]);
      expect(surfaces[1].positions.sublist(9), [2, 0, 0, 3, 0, 0, 2, 1, 0]);
    },
  );
  test(
    'indexed primitives reject colors whose original count differs from positions',
    () async {
      await expectLater(
        ModelByteLoader.load(sharedIndexedGlb(mismatchedColors: true)),
        throwsFormatException,
      );
    },
  );
  test(
    'MASK uses backface culling and explicit cutoff through the real loader',
    () async {
      final model = await ModelByteLoader.load(
        Uint8List.fromList(coloredGlb()),
      );
      final material =
          model.nodes.values.single.mesh!.surfaces.single.material
              as SpatialPixelMaterial;
      expect(material.cullMode, CullMode.backFace);
      expect(material.alphaCutoff, .5);
      expect(material.alphaMode, Model3dAlphaMode.mask);
    },
  );
  test(
    'real loader uploads RGB and RGBA vertex multipliers without tessellation',
    () async {
      for (final width in [3, 4]) {
        final model = await ModelByteLoader.load(
          Uint8List.fromList(coloredGlb(width: width)),
        );
        final surface = model.nodes.values.single.mesh!.surfaces.single;
        expect(surface, isA<SpatialModelSurface>());
        final colors = (surface as SpatialModelSurface).vertexColors;
        expect(colors, hasLength(3));
        expect(colors.first.r, .25);
        expect(colors.first.a, 1);
        expect(surface.vertexCount, 3);
        expect(surface.indexCount, 3);
      }
    },
  );
  test(
    'explicit two sided materials preserve both faces without extra triangles',
    () async {
      for (final mode in ['OPAQUE', 'MASK']) {
        final model = await ModelByteLoader.load(
          Uint8List.fromList(
            coloredGlb(
              edit: (j) {
                j['materials'][0]['alphaMode'] = mode;
                j['materials'][0]['doubleSided'] = true;
                if (mode == 'OPAQUE') j['materials'][0].remove('alphaCutoff');
              },
            ),
          ),
        );
        final surface = model.nodes.values.single.mesh!.surfaces.single;
        expect(surface.material.cullMode, CullMode.none);
        expect(surface.vertexCount, 3);
        expect(surface.indexCount, 3);
      }
    },
  );
  test('loader preserves independent native texture wrap axes', () async {
    final source = Uint8List.fromList(texturedGlb());
    final length = ByteData.sublistView(source).getUint32(12, Endian.little);
    final json =
        jsonDecode(utf8.decode(source.sublist(20, 20 + length)))
            as Map<String, dynamic>;
    json['samplers'] = [
      {'wrapS': 33648, 'wrapT': 33071},
    ];
    json['textures'][0]['sampler'] = 0;
    final model = await ModelByteLoader.load(
      Uint8List.fromList(encodeGlb(json, source.sublist(28 + length))),
    );
    final material =
        model.nodes.values.single.mesh!.surfaces.single.material
            as SpatialPixelMaterial;
    expect(material.wrapS, 33648);
    expect(material.wrapT, 33071);
  });
  test(
    'single sided culling follows negative node and parent determinants',
    () async {
      for (final parent in [false, true]) {
        final model = await ModelByteLoader.load(
          Uint8List.fromList(
            coloredGlb(
              edit: (j) {
                j['nodes'][0]['scale'] = parent ? [1, 1, 1] : [-1, 1, 1];
                if (parent) {
                  j['nodes'].add({
                    'scale': [-1, 1, 1],
                    'children': [0],
                  });
                  j['scenes'][0]['nodes'] = [1];
                }
              },
            ),
          ),
        );
        expect(
          model.nodes.values
              .firstWhere((node) => node.mesh != null)
              .mesh!
              .surfaces
              .single
              .material
              .cullMode,
          CullMode.frontFace,
        );
      }
    },
  );
  test(
    'runtime loader preserves translucent BLEND material and its alpha factor',
    () async {
      final model = await ModelByteLoader.load(
        Uint8List.fromList(
          coloredGlb(
            edit: (j) {
              j['materials'][0]['alphaMode'] = 'BLEND';
              j['materials'][0].remove('alphaCutoff');
              j['materials'][0]['pbrMetallicRoughness'] = {
                'baseColorFactor': [1, 1, 1, .387096763],
              };
            },
          ),
        ),
      );
      final material =
          model.nodes.values.single.mesh!.surfaces.single.material
              as SpatialPixelMaterial;
      expect(material.alphaMode, Model3dAlphaMode.blend);
      expect(material.albedoColor.a, closeTo(.387096763, .000001));
      expect(material.cullMode, CullMode.backFace);
    },
  );
  for (final change in <String, void Function(Map<String, dynamic>)>{
    'oversized color count': (j) => j['accessors'][1]['count'] = 4,
    'normalized float color': (j) => j['accessors'][1]['normalized'] = true,
    'missing MASK cutoff': (j) => j['materials'][0].remove('alphaCutoff'),
    'BLEND cutoff': (j) => j['materials'][0]['alphaMode'] = 'BLEND',
    'invalid double sided': (j) => j['materials'][0]['doubleSided'] = 'true',
  }.entries) {
    test('loader rejects ${change.key}', () async {
      await expectLater(
        ModelByteLoader.load(
          Uint8List.fromList(coloredGlb(edit: change.value)),
        ),
        throwsFormatException,
      );
    });
  }
  final fixtures = Platform.environment['AVELUNE_BW2_FIXTURES'];
  final doorFixture = Platform.environment['AVELUNE_BW2_DOOR_FIXTURE'];
  if (doorFixture != null) {
    test(
      'original child doors remain closed under ambient and play separately once',
      () async {
        final model = await ModelByteLoader.load(
          await File(doorFixture).readAsBytes(),
        );
        expect(model.animations.map((clip) => clip.name), [
          'c5_build_01',
          'door_c05_b_op',
          'door_c05_b_cl',
        ]);
        final doors = model.nodes.values
            .where((node) => node.name == 'door_l' || node.name == 'door_r')
            .toList();
        expect(doors, hasLength(2));
        expect(
          model.nodes.values.any(
            (node) => node.name == 'Verified static source geometry',
          ),
          isFalse,
        );
        final component = AnimatedModelComponent(model: model)
          ..bindAnimation(0);
        final closed = model.processNodes(component.playback);
        component.update(1.3);
        final ambient = model.processNodes(component.playback);
        for (final door in doors) {
          expect(
            ambient[door.nodeIndex]!.combinedTransform.storage,
            orderedEquals(closed[door.nodeIndex]!.combinedTransform.storage),
          );
        }
        component.play(1, loop: false);
        component.update(1);
        expect(component.playback.clock, closeTo(8 / 60, 1e-6));
        final opened = model.processNodes(component.playback);
        component.play(2, loop: false);
        final beforeClose = model.processNodes(component.playback);
        for (final door in doors) {
          expect(
            beforeClose[door.nodeIndex]!.combinedTransform.storage,
            orderedEquals(opened[door.nodeIndex]!.combinedTransform.storage),
          );
        }
        component.update(1);
        final closedAgain = model.processNodes(component.playback);
        for (final door in doors) {
          expect(
            closedAgain[door.nodeIndex]!.combinedTransform.storage,
            orderedEquals(closed[door.nodeIndex]!.combinedTransform.storage),
          );
          expect(
            opened[door.nodeIndex]!.combinedTransform.storage,
            isNot(
              orderedEquals(closed[door.nodeIndex]!.combinedTransform.storage),
            ),
          );
        }
      },
    );
  }
  if (fixtures != null) {
    test(
      'loads every authentic BW2 model with original colors and cutouts',
      () async {
        final files = Directory(fixtures)
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.glb'))
            .toList();
        expect(files, isNotEmpty);
        for (final file in files) {
          final bytes = await file.readAsBytes();
          final layout = GlbRendererLayout(normalizeGlbAccessors(bytes));
          final model = await ModelByteLoader.load(bytes);
          for (final node in model.nodes.values) {
            for (final (index, surface)
                in (node.mesh?.surfaces.toList() ?? []).indexed) {
              expect(surface, isA<SpatialModelSurface>(), reason: file.path);
              final material = surface.material as SpatialPixelMaterial;
              final primitive =
                  layout.json['meshes'][layout.json['nodes'][node
                      .nodeIndex]['mesh']]['primitives'][index];
              final profile = layout.materials[primitive['material'] as int];
              expect(
                material.cullMode,
                profile.doubleSided ? CullMode.none : CullMode.backFace,
              );
              if (material.alphaMode == Model3dAlphaMode.mask)
                expect(material.alphaCutoff, .5);
            }
          }
        }
        print('BW2 native model count: ${files.length}');
      },
    );
  }
}
