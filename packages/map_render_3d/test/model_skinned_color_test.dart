import 'dart:convert';
import 'dart:typed_data';

import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/model_byte_loader.dart';
import 'package:map_render_3d/src/glb_renderer_layout.dart';

import '../../map_distribution/test/support/glb_fixture.dart';

final class _RecordingVertexBackend extends GpuBackend {
  late _RecordingVertexBuffer latest;

  @override
  GpuBuffer createBuffer({
    required GpuStorageMode storageMode,
    required int sizeInBytes,
  }) => latest = _RecordingVertexBuffer(sizeInBytes);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _RecordingVertexBuffer implements GpuBuffer {
  _RecordingVertexBuffer(int size) : bytes = Uint8List(size);
  final Uint8List bytes;

  @override
  void write(ByteData data, {int destinationOffsetInBytes = 0}) {
    bytes.setRange(
      destinationOffsetInBytes,
      destinationOffsetInBytes + data.lengthInBytes,
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }
}

Uint8List skinnedGlb({required bool color}) {
  final input = Uint8List.fromList(coloredGlb());
  final header = ByteData.sublistView(input);
  final size = header.getUint32(12, Endian.little);
  final json = jsonDecode(
    utf8.decode(input.sublist(20, 20 + size)),
  ) as Map<String, dynamic>;
  final binary = Uint8List(188);
  binary.setRange(0, 84, input.sublist(28 + size, 112 + size));
  final data = ByteData.sublistView(binary);
  final joints = [2, 0, 0, 0, 0, 2, 0, 0, 2, 0, 0, 0];
  final weights = <double>[.75, .25, 0, 0, .4, .6, 0, 0, 1, 0, 0, 0];
  for (var i = 0; i < joints.length; i++) {
    data.setUint16(84 + i * 2, joints[i], Endian.little);
    data.setFloat32(108 + i * 4, weights[i], Endian.little);
  }
  data.setFloat32(160, 1, Endian.little);
  data.setFloat32(176, 1, Endian.little);
  json['buffers'][0]['byteLength'] = binary.length;
  json['bufferViews'].addAll([
    {'buffer': 0, 'byteOffset': 84, 'byteLength': 24},
    {'buffer': 0, 'byteOffset': 108, 'byteLength': 48},
    {'buffer': 0, 'byteOffset': 156, 'byteLength': 8},
    {'buffer': 0, 'byteOffset': 164, 'byteLength': 24},
  ]);
  json['accessors'].addAll([
    {'bufferView': 2, 'componentType': 5123, 'count': 3, 'type': 'VEC4'},
    {'bufferView': 3, 'componentType': 5126, 'count': 3, 'type': 'VEC4'},
    {'bufferView': 4, 'componentType': 5126, 'count': 2, 'type': 'SCALAR'},
    {'bufferView': 5, 'componentType': 5126, 'count': 2, 'type': 'VEC3'},
  ]);
  final attributes = json['meshes'][0]['primitives'][0]['attributes'];
  attributes['JOINTS_0'] = 2;
  attributes['WEIGHTS_0'] = 3;
  if (!color) attributes.remove('COLOR_0');
  json['nodes'][0]['skin'] = 0;
  json['nodes'].addAll([
    {'name': 'joint-0'},
    {'name': 'joint-1'},
    {'name': 'joint-2'},
  ]);
  json['scenes'][0]['nodes'] = [0, 1, 2, 3];
  json['skins'] = [
    {
      'joints': [1, 2, 3],
    },
  ];
  json['animations'] = [
    {
      'name': 'joint motion',
      'samplers': [
        {'input': 4, 'output': 5},
      ],
      'channels': [
        {
          'sampler': 0,
          'target': {'node': 3, 'path': 'translation'},
        },
      ],
    },
  ];
  return Uint8List.fromList(encodeGlb(json, binary));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'vertex colors preserve skin palette, weights, and joint animation',
    () async {
      final baseline = await ModelByteLoader.load(skinnedGlb(color: false));
      final colored = await ModelByteLoader.load(skinnedGlb(color: true));
      final plainSurface = baseline.nodes[0]!.mesh!.surfaces.single;
      final coloredSurface = colored.nodes[0]!.mesh!.surfaces.single;
      expect(plainSurface.jointMap, {2: 0, 0: 1});
      expect(coloredSurface.jointMap, plainSurface.jointMap);
      expect(coloredSurface, isA<SpatialModelSurface>());

      final backend = _RecordingVertexBackend();
      plainSurface.createResource();
      final plainVertices = backend.latest.bytes.buffer
          .asFloat32List(0, plainSurface.verticesBytes ~/ 4)
          .toList();
      coloredSurface.createResource();
      final coloredVertices = backend.latest.bytes.buffer
          .asFloat32List(0, coloredSurface.verticesBytes ~/ 4)
          .toList();
      expect(plainVertices.sublist(12, 20), [0, 1, 1, 1, .75, .25, 0, 0]);
      for (var i = 0; i < plainSurface.vertexCount; i++) {
        expect(
          coloredVertices.sublist(i * 20 + 12, i * 20 + 20),
          plainVertices.sublist(i * 20 + 12, i * 20 + 20),
        );
        expect(coloredVertices.sublist(i * 20 + 5, i * 20 + 9), [
          .25,
          .25,
          .25,
          1,
        ]);
      }

      final plainState = AnimationState()
        ..startAnimation(baseline.animations.single)
        ..clock = .5;
      final coloredState = AnimationState()
        ..startAnimation(colored.animations.single)
        ..clock = .5;
      final plainJoints = baseline
          .processNodes(plainState)[0]!
          .jointTransforms[0]!;
      final coloredJoints = colored
          .processNodes(coloredState)[0]!
          .jointTransforms[0]!;
      expect(plainJoints.first.getTranslation().x, closeTo(.5, .0001));
      expect(
        coloredJoints.map((matrix) => matrix.storage.toList()),
        plainJoints.map((matrix) => matrix.storage.toList()),
      );
    },
  );
}
