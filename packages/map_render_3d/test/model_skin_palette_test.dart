import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/model_byte_loader.dart';

import '../../map_distribution/test/support/glb_fixture.dart';

const jointIndices = <List<int>>[
  [0, 1, 2, 3],
  [4, 5, 6, 7],
  [8, 9, 10, 11],
  [12, 13, 14, 15],
  [0, 16, 17, 18],
  [1, 20, 21, 19],
];

List<List<double>> weights({bool extraJoint = false}) => [
  [.25, .25, .25, .25],
  [.25, .25, .25, .25],
  [.25, .25, .25, .25],
  [.25, .25, .25, .25],
  if (extraJoint) [.999999, .000001, 0, 0] else [1, 0, 0, 0],
  [1, 0, 0, 0],
];

Uint8List paletteGlb(
  List<List<int>> joints,
  List<List<double>> weights, {
  int? weightCount,
}) {
  final count = joints.length;
  final positionsLength = count * 12;
  final jointsLength = count * 8;
  final weightsLength = count * 16;
  final binary = ByteData(positionsLength + jointsLength + weightsLength);
  for (var i = 0; i < count; i++) {
    binary.setFloat32(i * 12, (i % 3 == 1 ? 1 : 0).toDouble(), Endian.little);
    binary.setFloat32(
      i * 12 + 4,
      (i % 3 == 2 ? 1 : 0).toDouble(),
      Endian.little,
    );
    for (var k = 0; k < 4; k++) {
      binary.setUint16(
        positionsLength + i * 8 + k * 2,
        joints[i][k],
        Endian.little,
      );
      binary.setFloat32(
        positionsLength + jointsLength + i * 16 + k * 4,
        weights[i][k],
        Endian.little,
      );
    }
  }
  final json = <String, dynamic>{
    'asset': {'version': '2.0'},
    'scene': 0,
    'scenes': [
      {
        'nodes': [for (var i = 0; i <= 22; i++) i],
      },
    ],
    'nodes': [
      {'mesh': 0, 'skin': 0},
      for (var i = 0; i < 22; i++)
        {
          'translation': [i.toDouble(), 0, 0],
        },
    ],
    'skins': [
      {
        'joints': [for (var i = 1; i <= 22; i++) i],
      },
    ],
    'meshes': [
      {
        'primitives': [
          {
            'attributes': {'POSITION': 0, 'JOINTS_0': 1, 'WEIGHTS_0': 2},
          },
        ],
      },
    ],
    'buffers': [
      {'byteLength': binary.lengthInBytes},
    ],
    'bufferViews': [
      {'buffer': 0, 'byteOffset': 0, 'byteLength': positionsLength},
      {'buffer': 0, 'byteOffset': positionsLength, 'byteLength': jointsLength},
      {
        'buffer': 0,
        'byteOffset': positionsLength + jointsLength,
        'byteLength': weightsLength,
      },
    ],
    'accessors': [
      {'bufferView': 0, 'componentType': 5126, 'count': count, 'type': 'VEC3'},
      {'bufferView': 1, 'componentType': 5123, 'count': count, 'type': 'VEC4'},
      {
        'bufferView': 2,
        'componentType': 5126,
        'count': weightCount ?? count,
        'type': 'VEC4',
      },
    ],
  };
  return Uint8List.fromList(encodeGlb(json, binary.buffer.asUint8List()));
}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _VertexShader extends VertexShader {
  _VertexShader() : super.fromAsset('unused');
  final jointMatrices = <String, Matrix4>{};
  @override
  void setMatrix4(String key, Matrix4 matrix) {
    if (key.startsWith('JointMatrices.')) jointMatrices[key] = matrix.clone();
  }
}

final class _FragmentShader extends FragmentShader {
  _FragmentShader() : super.fromAsset('unused');
  @override
  void setTexture(String key, Texture texture) {}
  @override
  void setColor(String key, Color color) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sixteen active joints exclude every zero-weight filler', () async {
    final inputWeights = weights();
    final model = await ModelByteLoader.load(
      paletteGlb(jointIndices, inputWeights),
    );
    final surface = model.nodes[0]!.mesh!.surfaces.single;
    final map = surface.jointMap!;
    expect(map.keys.toSet(), {for (var i = 0; i < 16; i++) i});
    expect(map.values.toSet(), {for (var i = 0; i < 16; i++) i});
    for (var i = 0; i < jointIndices.length; i++) {
      final skin = surface.vertexSkin(i);
      for (var k = 0; k < 4; k++) {
        expect(skin.weights.storage[k], closeTo(inputWeights[i][k], 1e-7));
        if (inputWeights[i][k] == 0) {
          expect(skin.joints.storage[k], map[jointIndices[i][k]] ?? 0);
        } else {
          expect(skin.joints.storage[k], map[jointIndices[i][k]]);
        }
      }
    }
    final matrices = model
        .processNodes(AnimationState())[0]!
        .jointTransforms[0]!;
    expect(matrices.length, 16);
    for (final entry in map.entries) {
      expect(matrices[entry.value].getTranslation().x, entry.key);
    }
    final vertexShader = _VertexShader();
    final material = UnlitMaterial()
      ..vertexShader = vertexShader
      ..fragmentShader = _FragmentShader();
    final context = RenderContext3D(GraphicsDevice(backend: _UnusedBackend()));
    context.jointsInfo.jointTransforms = matrices;
    expect(() => material.apply(context), returnsNormally);
    expect(vertexShader.jointMatrices.length, 16);
  });

  test('a tiny nonzero weight retains the seventeenth joint', () async {
    final inputWeights = weights(extraJoint: true);
    final model = await ModelByteLoader.load(
      paletteGlb(jointIndices, inputWeights),
    );
    final surface = model.nodes[0]!.mesh!.surfaces.single;
    expect(surface.jointMap!.length, 17);
    expect(surface.jointMap, contains(16));
    final skin = surface.vertexSkin(4);
    expect(skin.weights.y, closeTo(.000001, 1e-10));
    expect(skin.joints.y, surface.jointMap![16]);
    final matrices = model
        .processNodes(AnimationState())[0]!
        .jointTransforms[0]!;
    final material = UnlitMaterial()
      ..vertexShader = _VertexShader()
      ..fragmentShader = _FragmentShader();
    final context = RenderContext3D(GraphicsDevice(backend: _UnusedBackend()));
    context.jointsInfo.jointTransforms = matrices;
    expect(
      () => material.apply(context),
      throwsA(
        predicate((Object e) => e.toString().contains('At most 16 joints')),
      ),
    );
  });

  test('unused nonzero joint indices never require a palette entry', () async {
    final joints = [
      for (var i = 0; i < 3; i++) [1, 19, 20, 21],
    ];
    final inputWeights = [
      for (var i = 0; i < 3; i++) <double>[1, 0, 0, 0],
    ];
    final model = await ModelByteLoader.load(paletteGlb(joints, inputWeights));
    final surface = model.nodes[0]!.mesh!.surfaces.single;
    expect(surface.jointMap, {1: 0});
    for (var i = 0; i < 3; i++) {
      expect(surface.vertexSkin(i).joints.storage, [0, 0, 0, 0]);
    }
  });

  test(
    'mismatched joint and weight counts fail before building a model',
    () async {
      await expectLater(
        ModelByteLoader.load(
          paletteGlb(jointIndices, weights(), weightCount: 5),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('counts do not match'),
          ),
        ),
      );
    },
  );
}
