import 'dart:typed_data';
import 'dart:ui';
import 'package:flame_3d/core.dart';
import 'package:flame_3d/resources.dart';
import 'package:flame_3d/model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/map_render_3d.dart';
import '../../map_authoring/test/support/glb_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('material without PBR uses the glTF default white surface', () async {
    final model = await ModelByteLoader.load(Uint8List.fromList(animatedGlb()));
    final material =
        model.nodes.values.single.mesh!.surfaces.single.material
            as UnlitMaterial;
    expect(material.albedoColor, const Color(0xFFFFFFFF));
  });
  test(
    'interleaved positions and normals with offset load through real parser',
    () async {
      final binary = ByteData(72);
      final values = [
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        1.0,
      ];
      for (var i = 0; i < values.length; i++) {
        binary.setFloat32(i * 4, values[i], Endian.little);
      }
      final bytes = encodeGlb({
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
        'buffers': [
          {'byteLength': 72},
        ],
        'bufferViews': [
          {'buffer': 0, 'byteLength': 72, 'byteStride': 24},
        ],
        'accessors': [
          {
            'bufferView': 0,
            'byteOffset': 0,
            'componentType': 5126,
            'count': 3,
            'type': 'VEC3',
          },
          {
            'bufferView': 0,
            'byteOffset': 12,
            'componentType': 5126,
            'count': 3,
            'type': 'VEC3',
          },
        ],
        'meshes': [
          {
            'primitives': [
              {
                'attributes': {'POSITION': 0, 'NORMAL': 1},
              },
            ],
          },
        ],
      }, binary.buffer.asUint8List());
      final model = await ModelByteLoader.load(Uint8List.fromList(bytes));
      expect(model.nodes.values.single.mesh!.surfaces.single.vertexCount, 3);
    },
  );
  test(
    'absolute animated scale replaces bind scale and final timestamp is safe',
    () async {
      final bytes = animatedGlb(
        edit: (json) {
          json['animations'][0]['channels'][0]['target']['path'] = 'scale';
        },
      );
      final data = ByteData.sublistView(Uint8List.fromList(bytes));
      final bin = 28 + data.getUint32(12, Endian.little);
      for (var i = 0; i < 6; i++) {
        data.setFloat32(bin + 44 + i * 4, 2, Endian.little);
      }
      final model = await ModelByteLoader.load(data.buffer.asUint8List());
      final state = AnimationState()
        ..startAnimation(model.animations.single)
        ..clock = 2;
      final transform = model
          .processNodes(state)
          .values
          .single
          .combinedTransform;
      final scale = Vector3.zero();
      transform.decompose(Vector3.zero(), Quaternion.identity(), scale);
      expect(scale.x, closeTo(2, 0.0001));
      expect(scale.y, closeTo(2, 0.0001));
      expect(scale.z, closeTo(2, 0.0001));
      state.update(100);
      expect(() => model.processNodes(state), returnsNormally);
    },
  );
}
