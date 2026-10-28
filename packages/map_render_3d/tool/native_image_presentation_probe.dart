import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame_3d/core.dart' as f3d;
import 'package:flame_3d/graphics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:map_render_3d/src/flutter_frame_graphics_device.dart';
import 'package:map_render_3d/src/spatial_depth_of_field.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: ui.Color(0xff14212c),
        child: Center(
          child: Text(
            'Avelune · Native image presentation probe',
            style: TextStyle(color: ui.Color(0xffedf4ff), fontSize: 18),
          ),
        ),
      ),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      if (!Platform.isMacOS) {
        throw UnsupportedError(
          'This ownership probe requires native macOS Flutter GPU.',
        );
      }
      await GpuBackend.initialize();
      final ownership = <String, Object?>{};
      for (final dof in [false, true]) {
        for (final protected in [false, true]) {
          ownership['${dof ? 'dof' : 'normal'}_${protected ? 'protected' : 'legacy'}'] =
              await _ownershipPair(dof: dof, protected: protected);
        }
      }
      final retention = <String, Object?>{};
      for (final dof in [false, true]) {
        retention[dof ? 'dof' : 'normal'] = await _retention(dof: dof);
      }
      final benchmarks = <String, Object?>{};
      if (const bool.fromEnvironment('NATIVE_PRESENTATION_BENCHMARK')) {
        for (final dof in [false, true]) {
          for (final protected in [false, true]) {
            final label =
                '${dof ? 'dof' : 'normal'}_${protected ? 'protected' : 'borrowed_clone'}';
            benchmarks[label] = await _benchmark(
              dof: dof,
              protected: protected,
            );
          }
        }
      }
      print(
        'NATIVE_IMAGE_PRESENTATION_RECEIPT ${jsonEncode({'schemaVersion': 1, 'pid': pid, 'os': Platform.operatingSystemVersion, 'ownership': ownership, 'retention': retention, 'synthetic1024x768': benchmarks, 'timingScope': 'CPU recording/submission and serial GPU readback measured separately; not live Studio FPS or isolated GPU copy time', 'memoryScope': 'Process RSS observations without forced GC; not a proof of bounded surface allocation or absence of leaks'})}',
      );
      exit(0);
    } on Object catch (error) {
      print(
        'NATIVE_IMAGE_PRESENTATION_FAILURE ${jsonEncode({'errorType': error.runtimeType.toString(), 'error': error.toString().replaceAll(RegExp(r'https?://[^\s]+'), '<url>')})}',
      );
      exit(1);
    }
  });
}

Future<Map<String, Object?>> _ownershipPair({
  required bool dof,
  required bool protected,
}) async {
  final sequence = _Sequence(dof: dof, protected: protected);
  const size = ui.Size(32, 32);
  final first = _HeldImage(
    sequence.render(size, _red),
    _red,
    'first-before-second',
  );
  _HeldImage? second;
  try {
    await _verify(first);
    final before = await _centerPixel(first.image);
    second = _HeldImage(sequence.render(size, _blue), _blue, 'second');
    await _verify(second);
    final latest = await _centerPixel(second.image);
    final after = await _centerPixel(first.image);
    final expectedAfter = protected ? _red : _blue;
    final actualFirst = _HeldImage(
      first.image,
      expectedAfter,
      'first-after-second',
    );
    await _verify(actualFirst);
    final preserved = _samePixel(before, after);
    if (preserved != protected) {
      throw StateError(
        'Unexpected ${dof ? 'DoF' : 'normal'} ownership result: protected=$protected, preserved=$preserved',
      );
    }
    return {
      'passed': true,
      'firstBefore': before,
      'second': latest,
      'firstAfter': after,
      'preserved': preserved,
      'expectedPreserved': protected,
    };
  } finally {
    first.dispose();
    second?.dispose();
  }
}

Future<List<int>> _centerPixel(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) throw StateError('No pixels in ownership check');
  final offset = (image.height ~/ 2 * image.width + image.width ~/ 2) * 4;
  return List.generate(4, (index) => data.getUint8(offset + index));
}

bool _samePixel(List<int> left, List<int> right) =>
    left.length == right.length &&
    left.asMap().entries.every(
      (entry) => (entry.value - right[entry.key]).abs() <= 1,
    );

Future<Map<String, Object?>> _retention({required bool dof}) async {
  final first = _Sequence(dof: dof);
  final second = _Sequence(dof: dof);
  final held = <_HeldImage>[];
  final rssBefore = ProcessInfo.currentRss;
  var checks = 0;
  Future<void> hold(
    _Sequence sequence,
    ui.Size size,
    _Color color,
    String label,
  ) async {
    final record = _HeldImage(sequence.render(size, color), color, label);
    held.add(record);
    await _verify(record);
    checks++;
  }

  try {
    for (var index = 0; index < 12; index++) {
      await hold(
        first,
        const ui.Size(64, 48),
        _colors[index % _colors.length],
        'retained-$index',
      );
    }
    await hold(first, const ui.Size(96, 72), _red, 'resize-up-red');
    await hold(first, const ui.Size(96, 72), _blue, 'resize-up-blue');
    await hold(first, const ui.Size(64, 48), _red, 'resize-down-red');
    await hold(second, const ui.Size(64, 48), _red, 'second-view-initial');
    await hold(first, const ui.Size(64, 48), _green, 'first-view-green');
    await hold(second, const ui.Size(64, 48), _blue, 'second-view-blue');
    await hold(first, const ui.Size(64, 48), _blue, 'first-view-blue');
    await hold(second, const ui.Size(64, 48), _green, 'second-view-green');
    for (final record in held) {
      await _verify(record);
      checks++;
    }
    final rssWhileRetained = ProcessInfo.currentRss;
    final retainedCount = held.length;
    for (var index = 0; index < held.length; index += 2) {
      held[index].dispose();
    }
    for (var index = 0; index < 12; index++) {
      final record = _HeldImage(
        first.render(const ui.Size(64, 48), _colors[index % _colors.length]),
        _colors[index % _colors.length],
        'partial-release-churn-$index',
      );
      try {
        await _verify(record);
        checks++;
      } finally {
        record.dispose();
      }
    }
    for (final record in held.where((record) => !record.disposed)) {
      await _verify(record);
      checks++;
    }
    for (final record in held) {
      record.dispose();
    }
    for (var index = 0; index < 40; index++) {
      final record = _HeldImage(
        first.render(const ui.Size(64, 48), _colors[index % _colors.length]),
        _colors[index % _colors.length],
        'released-churn-$index',
      );
      try {
        await _verify(record);
        checks++;
      } finally {
        record.dispose();
      }
    }
    return {
      'passed': true,
      'initialConsecutiveRetained': 12,
      'totalRetainedImagesBeforeRelease': retainedCount,
      'resize': ['64x48', '96x72', '64x48'],
      'interleavedViews': 2,
      'partialReleaseChurnFrames': 12,
      'allReleasedChurnFrames': 40,
      'pixelAssertions': checks,
      'rssBeforeBytes': rssBefore,
      'rssWhileRetainedBytes': rssWhileRetained,
      'rssAfterReleaseChurnBytes': ProcessInfo.currentRss,
    };
  } finally {
    for (final record in held) {
      record.dispose();
    }
  }
}

Future<Map<String, Object?>> _benchmark({
  required bool dof,
  required bool protected,
}) async {
  final sequence = _Sequence(dof: dof, protected: protected);
  final submissions = <int>[];
  final completeReadbacks = <int>[];
  for (var index = 0; index < 23; index++) {
    final color = _colors[index % _colors.length];
    final timer = Stopwatch()..start();
    final image = sequence.render(const ui.Size(1024, 768), color);
    final submittedMicros = timer.elapsedMicroseconds;
    final record = _HeldImage(image, color, 'benchmark-$index');
    try {
      await _verify(record);
      timer.stop();
      if (index >= 3) {
        submissions.add(submittedMicros);
        completeReadbacks.add(timer.elapsedMicroseconds);
      }
    } finally {
      record.dispose();
    }
  }
  return {
    'sampleCount': submissions.length,
    'warmupFrames': 3,
    'pixelsPerFrame': 1024 * 768,
    'cpuRecordAndSubmitMicros': _statistics(submissions),
    'recordSubmitAndSerialReadbackMicros': _statistics(completeReadbacks),
  };
}

Map<String, Object> _statistics(List<int> values) {
  final ordered = [...values]..sort();
  return {
    'min': ordered.first,
    'median': ordered[(ordered.length - 1) ~/ 2],
    'p95': ordered[((ordered.length - 1) * .95).ceil()],
    'max': ordered.last,
    'mean': ordered.reduce((left, right) => left + right) / ordered.length,
  };
}

Future<void> _verify(_HeldImage record) async {
  if (record.disposed)
    throw StateError('Cannot read disposed image ${record.label}');
  final data = await record.image.toByteData(
    format: ui.ImageByteFormat.rawRgba,
  );
  if (data == null) throw StateError('No pixels for ${record.label}');
  final points = [
    (record.image.width ~/ 2, record.image.height ~/ 2),
    (record.image.width ~/ 4, record.image.height ~/ 4),
    (record.image.width * 3 ~/ 4, record.image.height * 3 ~/ 4),
  ];
  for (final point in points) {
    final offset = (point.$2 * record.image.width + point.$1) * 4;
    final actual = List.generate(4, (index) => data.getUint8(offset + index));
    if (actual.asMap().entries.any(
      (entry) => (entry.value - record.expected.rgba[entry.key]).abs() > 1,
    )) {
      throw StateError(
        '${record.label}: ${point.$1},${point.$2} expected ${record.expected.rgba}, got $actual',
      );
    }
  }
}

final class _Sequence {
  _Sequence({required this.dof, bool protected = true})
    : device = FlutterFrameGraphicsDevice(
        clearValue: _red.color,
        presentImage: protected ? null : (image) => image.clone(),
      );

  final bool dof;
  final FlutterFrameGraphicsDevice device;
  late final effect = SpatialDepthOfField(device.backend)
    ..profile = SpatialDepthOfFieldProfile(enabled: true, strength: .35);
  ui.Size? previousSize;

  ui.Image render(ui.Size size, _Color color) {
    if (previousSize == size && device.currentRenderTarget != null) {
      final target =
          (device.currentRenderTarget as dynamic).raw as gpu.RenderTarget;
      target.colorAttachments.first.clearValue = f3d.Vector4(
        color.rgba[0] / 255,
        color.rgba[1] / 255,
        color.rgba[2] / 255,
        color.rgba[3] / 255,
      );
    } else if (!identical(color, _red)) {
      throw StateError(
        'The first frame after resize must use the red clear value',
      );
    }
    late ui.Image output;
    device.guardFrame(() {
      device.begin();
      if (dof) {
        device
          ..secondaryColorClearValue = SpatialDepthOfField.depthClearValue
          ..postProcess = effect.composite;
      }
      device.beginPass(size);
      output = device.endPass();
    });
    previousSize = size;
    return output;
  }
}

final class _HeldImage {
  _HeldImage(this.image, this.expected, this.label);

  final ui.Image image;
  final _Color expected;
  final String label;
  bool disposed = false;

  void dispose() {
    if (disposed) return;
    disposed = true;
    image.dispose();
  }
}

final class _Color {
  const _Color(this.color, this.rgba);

  final ui.Color color;
  final List<int> rgba;
}

const _red = _Color(ui.Color(0xffff0000), [255, 0, 0, 255]);
const _blue = _Color(ui.Color(0xff0000ff), [0, 0, 255, 255]);
const _green = _Color(ui.Color(0xff00ff00), [0, 255, 0, 255]);
const _colors = [_red, _blue, _green];
