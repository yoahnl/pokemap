import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/infrastructure/runtime_gif_animation.dart';

Uint8List _gif({int repeat = 0}) {
  final red = img.Image(width: 2, height: 2);
  final blue = img.Image(width: 2, height: 2);
  img.fill(red, color: img.ColorRgb8(255, 0, 0));
  img.fill(blue, color: img.ColorRgb8(0, 0, 255));
  final encoder = img.GifEncoder(
    repeat: repeat,
    dither: img.DitherKernel.none,
    quantizerType: img.QuantizerType.octree,
  );
  encoder.addFrame(red, duration: 10);
  encoder.addFrame(blue, duration: 20);
  return encoder.finish()!;
}

Uint8List _transparentGif() {
  final palette = img.PaletteUint8(4, 4)
    ..setRgba(0, 0, 0, 0, 0)
    ..setRgba(1, 255, 0, 0, 255)
    ..setRgba(2, 0, 0, 255, 255)
    ..setRgba(3, 255, 255, 255, 255);
  final red = img.Image(
    width: 2,
    height: 2,
    withPalette: true,
    palette: palette,
  );
  final blue = img.Image(
    width: 2,
    height: 2,
    withPalette: true,
    palette: palette,
  );
  red.setPixelIndex(1, 0, 1);
  red.setPixelIndex(0, 1, 1);
  red.setPixelIndex(1, 1, 1);
  blue.setPixelIndex(1, 1, 2);
  final encoder = img.GifEncoder(
    repeat: 0,
    dispose: 2,
    dither: img.DitherKernel.none,
    quantizerType: img.QuantizerType.octree,
  );
  encoder.addFrame(red, duration: 10);
  encoder.addFrame(blue, duration: 20);
  return encoder.finish()!;
}

RuntimeResourceBudget _budget(int resident) => RuntimeResourceBudget(
  profile: RuntimeResourceProfile(
    maximumResidentBytes: resident,
    maximumTransientBytes: 65536,
    maximumEncodedBytes: 65536,
    maximumConcurrentDecodes: 1,
  ),
);

Future<List<int>> _pixel(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List().take(4).toList();
}

final class _DelayedCodec implements ui.Codec {
  _DelayedCodec(this._inner, this._image, this._gate);

  final ui.Codec _inner;
  final Completer<ui.Image> _image;
  final Future<void> _gate;

  @override
  int get frameCount => _inner.frameCount;

  @override
  int get repetitionCount => _inner.repetitionCount;

  @override
  Future<ui.FrameInfo> getNextFrame() async {
    final frame = await _inner.getNextFrame();
    if (!_image.isCompleted) _image.complete(frame.image);
    await _gate;
    return frame;
  }

  @override
  void dispose() => _inner.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'plays decoded frames at their durations and releases ownership',
    () async {
      final budget = _budget(32);
      final animation = await decodeRuntimeGif(_gif(), resourceBudget: budget);
      final first = animation.frameAt(Duration.zero);
      final second = animation.frameAt(const Duration(milliseconds: 100));
      expect(animation.frameCount, 2);
      expect(animation.repetitionCount, -1);
      expect(await _pixel(first), [255, 0, 0, 255]);
      expect(await _pixel(second), [0, 0, 255, 255]);
      expect(
        identical(animation.frameAt(const Duration(milliseconds: 99)), first),
        isTrue,
      );
      expect(
        identical(animation.frameAt(const Duration(milliseconds: 299)), second),
        isTrue,
      );
      expect(
        identical(animation.frameAt(const Duration(milliseconds: 300)), first),
        isTrue,
      );
      expect(budget.residentBytes, 32);
      expect(budget.transientBytes, 0);
      animation.dispose();
      animation.dispose();
      expect(first.debugDisposed, isTrue);
      expect(second.debugDisposed, isTrue);
      expect(budget.residentBytes, 0);
      expect(() => animation.frameAt(Duration.zero), throwsStateError);
    },
  );

  test('rejects a GIF that exceeds the decoded frame budget', () async {
    final budget = _budget(31);
    await expectLater(
      decodeRuntimeGif(_gif(), resourceBudget: budget),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
    expect(budget.activeDecodes, 0);
  });

  test('keeps transparent pixels transparent in the later frame', () async {
    final animation = await decodeRuntimeGif(
      _transparentGif(),
      resourceBudget: _budget(32),
    );
    final frame = animation.frameAt(const Duration(milliseconds: 100));
    final bytes = (await frame.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    expect(bytes[3], 0);
    expect(bytes.sublist(12, 16), [0, 0, 255, 255]);
    animation.dispose();
  });

  test('holds the last frame after a finite number of repetitions', () async {
    final budget = _budget(32);
    final animation = await decodeRuntimeGif(
      _gif(repeat: 1),
      resourceBudget: budget,
    );
    final first = animation.frameAt(Duration.zero);
    final last = animation.frameAt(const Duration(milliseconds: 100));
    expect(animation.repetitionCount, 1);
    expect(
      identical(animation.frameAt(const Duration(milliseconds: 300)), first),
      isTrue,
    );
    expect(
      identical(animation.frameAt(const Duration(milliseconds: 600)), last),
      isTrue,
    );
    expect(
      identical(animation.frameAt(const Duration(hours: 1)), last),
      isTrue,
    );
    expect(
      () => animation.frameAt(const Duration(microseconds: -1)),
      throwsArgumentError,
    );
    animation.dispose();
  });

  test('releases admission when the request is cancelled', () async {
    final budget = _budget(32);
    await expectLater(
      decodeRuntimeGif(_gif(), resourceBudget: budget, isCurrent: () => false),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
    expect(budget.activeDecodes, 0);
  });

  test('disposes a frame that completes after cancellation', () async {
    final budget = _budget(32);
    final image = Completer<ui.Image>();
    final gate = Completer<void>();
    var current = true;
    final loading = decodeRuntimeGif(
      _gif(),
      resourceBudget: budget,
      isCurrent: () => current,
      codecFactory: (bytes) async => _DelayedCodec(
        await ui.instantiateImageCodec(bytes),
        image,
        gate.future,
      ),
    );
    final rejected = expectLater(
      loading,
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    final frame = await image.future;
    current = false;
    gate.complete();
    await rejected;
    expect(frame.debugDisposed, isTrue);
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
    expect(budget.activeDecodes, 0);
  });

  test(
    'rejects non-GIF input and a frame count over the configured limit',
    () async {
      final budget = _budget(64);
      await expectLater(
        decodeRuntimeGif(Uint8List.fromList([1, 2, 3]), resourceBudget: budget),
        throwsFormatException,
      );
      await expectLater(
        decodeRuntimeGif(_gif(), resourceBudget: budget, maximumFrames: 1),
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
      expect(budget.residentBytes, 0);
      expect(budget.transientBytes, 0);
      expect(budget.activeDecodes, 0);
    },
  );
}
