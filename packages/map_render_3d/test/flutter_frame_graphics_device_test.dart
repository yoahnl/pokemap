import 'dart:typed_data';

import 'package:flame_3d/graphics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/flutter_frame_graphics_device.dart';

void main() {
  testWidgets('scenes retain their uniforms until every preview is painted', (
    tester,
  ) async {
    final backend = _SharedUniformBackend();
    final first = FlutterFrameGraphicsDevice(backend: backend);
    final second = FlutterFrameGraphicsDevice(backend: backend);
    final sampled = <double>[];
    var endsDuringPaint = -1;

    await tester.pumpWidget(
      CustomPaint(
        painter: _ScenesPainter(() {
          first.begin();
          final firstCamera = backend.bind(12);
          first.end();
          second.begin();
          final secondCamera = backend.bind(96);
          second.end();
          sampled
            ..clear()
            ..addAll([firstCamera.single, secondCamera.single]);
          endsDuringPaint = backend.ends;
        }),
        size: const Size(100, 100),
      ),
    );

    expect(sampled, [12, 96]);
    expect(endsDuringPaint, 0);
    expect(backend.ends, 1);
    expect(backend.cursor, 0);
  });

  testWidgets(
    'a device ends once per Flutter frame and reuses storage next frame',
    (tester) async {
      final backend = _SharedUniformBackend();
      final device = FlutterFrameGraphicsDevice(backend: backend);
      final sampled = <double>[];

      Future<void> paint(double value) => tester.pumpWidget(
        CustomPaint(
          painter: _ScenesPainter(() {
            device.begin();
            final first = backend.bind(value);
            device.end();
            device.begin();
            final second = backend.bind(value + 1);
            device.end();
            sampled
              ..clear()
              ..addAll([first.single, second.single]);
          }),
          size: const Size(100, 100),
        ),
      );

      await paint(3);
      expect(sampled, [3, 4]);
      expect(backend.ends, 1);
      expect(backend.cursor, 0);
      await paint(7);
      expect(sampled, [7, 8]);
      expect(backend.ends, 2);
      expect(backend.cursor, 0);
    },
  );

  testWidgets('all scenes advance the shared GPU buffer once per frame', (
    tester,
  ) async {
    final backend = _SharedUniformBackend(bufferCount: 4);
    final devices = List.generate(
      8,
      (_) => FlutterFrameGraphicsDevice(backend: backend),
    );
    final previousFrame = <Float64List>[];

    Future<void> paint(double value) => tester.pumpWidget(
      CustomPaint(
        painter: _ScenesPainter(() {
          for (final device in devices) {
            device.begin();
            final uniform = backend.bind(value);
            device.end();
            if (value == 3) previousFrame.add(uniform);
          }
        }),
        size: const Size(100, 100),
      ),
    );

    await paint(3);
    expect(backend.begins, 1);
    expect(backend.ends, 1);
    expect(backend.bufferIndex, 1);
    await paint(7);
    expect(backend.begins, 2);
    expect(backend.ends, 2);
    expect(backend.bufferIndex, 2);
    expect(previousFrame.map((uniform) => uniform.single), everyElement(3));
  });

  testWidgets('offscreen rendering releases its frame without a pump', (
    tester,
  ) async {
    final backend = _SharedUniformBackend();
    final device = FlutterFrameGraphicsDevice(backend: backend);
    device.begin();
    backend.bind(5);
    device.end();
    expect(backend.begins, 1);
    expect(backend.ends, 1);
    expect(backend.cursor, 0);
  });
}

class _ScenesPainter extends CustomPainter {
  _ScenesPainter(this.render);

  final VoidCallback render;

  @override
  void paint(Canvas canvas, Size size) => render();

  @override
  bool shouldRepaint(_ScenesPainter oldDelegate) => true;
}

final class _SharedUniformBackend extends GpuBackend {
  _SharedUniformBackend({int bufferCount = 1})
    : buffers = List.generate(bufferCount, (_) => Float64List(16));

  final List<Float64List> buffers;
  late final frame = _SharedFrame(this);
  int cursor = 0;
  int bufferIndex = 0;
  int begins = 0;
  int ends = 0;

  Float64List bind(double value) {
    final offset = cursor++;
    final storage = buffers[bufferIndex];
    storage[offset] = value;
    return Float64List.view(storage.buffer, offset * 8, 1);
  }

  @override
  GpuFrame beginFrame() {
    begins++;
    return frame;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

class _SharedFrame implements GpuFrame {
  _SharedFrame(this.backend);

  final _SharedUniformBackend backend;

  @override
  void end() {
    backend.ends++;
    backend.cursor = 0;
    backend.bufferIndex = (backend.bufferIndex + 1) % backend.buffers.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
