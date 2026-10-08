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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
    'runtime loader refuses BLEND instead of rendering an opaque approximation',
    () async {
      await expectLater(
        ModelByteLoader.load(
          Uint8List.fromList(
            coloredGlb(
              edit: (j) {
                j['materials'][0]['alphaMode'] = 'BLEND';
              },
            ),
          ),
        ),
        throwsFormatException,
      );
    },
  );
  for (final change in <String, void Function(Map<String, dynamic>)>{
    'oversized color count': (j) => j['accessors'][1]['count'] = 4,
    'normalized float color': (j) => j['accessors'][1]['normalized'] = true,
    'missing MASK cutoff': (j) => j['materials'][0].remove('alphaCutoff'),
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
