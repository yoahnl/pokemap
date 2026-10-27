import 'dart:typed_data';
import 'dart:ui';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('surfaces upload every vertex attribute in declaration order', () {
    final backend = _RecordingBackend();
    final vertices = [
      for (var i = 0; i < 5; i++)
        Vertex(
          position: Vector3(i.toDouble(), i * 2.0, -i * .5),
          texCoord: Vector2(i * .1, 1 - i * .1),
          color: Color.fromARGB(255, i * 40, 255 - i * 40, 128),
          normal: Vector3(0, 1, 0),
          joints: Vector4(i.toDouble(), 0, 0, 0),
          weights: Vector4(1, 0, 0, 0),
        ),
    ];
    final surface = Surface(
      vertices: vertices,
      indices: const [0, 1, 2, 2, 3, 4],
    );
    surface.createResource();
    final uploaded = Float32List.view(
      backend.latest.bytes.buffer,
      0,
      surface.verticesBytes ~/ 4,
    );
    expect(uploaded, [for (final vertex in vertices) ...vertex.storage]);
    expect(surface.vertexCount, vertices.length);
  });

  test('an empty surface uploads no vertex data', () {
    _RecordingBackend();
    final surface = Surface(vertices: const [], indices: const []);
    expect(surface.verticesBytes, 0);
    expect(surface.vertexCount, 0);
  });
}

final class _RecordingBackend extends GpuBackend {
  late _RecordingBuffer latest;

  @override
  GpuBuffer createBuffer({
    required GpuStorageMode storageMode,
    required int sizeInBytes,
  }) => latest = _RecordingBuffer(sizeInBytes);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _RecordingBuffer implements GpuBuffer {
  _RecordingBuffer(int size) : bytes = Uint8List(size);
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
