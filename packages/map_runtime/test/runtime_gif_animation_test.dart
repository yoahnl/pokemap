import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_runtime/src/infrastructure/runtime_gif_atlas.dart';
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

Uint8List _gifWithFrames(int count) {
  final palette = img.PaletteUint8(2, 4)
    ..setRgba(0, 0, 0, 0, 255)
    ..setRgba(1, 255, 255, 255, 255);
  final frame = img.Image(
    width: 2,
    height: 2,
    withPalette: true,
    palette: palette,
  );
  final encoder = img.GifEncoder();
  for (var i = 0; i < count; i++) {
    encoder.addFrame(frame);
  }
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

Uint8List _threeFrameGif() {
  final red = img.Image(width: 2, height: 2);
  final blue = img.Image(width: 2, height: 2);
  final green = img.Image(width: 2, height: 2);
  img.fill(red, color: img.ColorRgb8(255, 0, 0));
  img.fill(blue, color: img.ColorRgb8(0, 0, 255));
  img.fill(green, color: img.ColorRgb8(0, 255, 0));
  final encoder = img.GifEncoder(
    repeat: 0,
    dither: img.DitherKernel.none,
    quantizerType: img.QuantizerType.octree,
  );
  encoder.addFrame(red, duration: 10);
  encoder.addFrame(blue, duration: 20);
  encoder.addFrame(green, duration: 10);
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

RuntimeResourceBudget _largeFrameBudget(int resident) => RuntimeResourceBudget(
  profile: RuntimeResourceProfile(
    maximumResidentBytes: resident,
    maximumTransientBytes: 2 * 1024 * 1024,
    maximumEncodedBytes: 1024 * 1024,
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

  test('plays up to 500 frames without bypassing the resident budget', () async {
    for (final count in [338, 500]) {
      final budget = _largeFrameBudget(count * 16);
      final animation = await decodeRuntimeGif(
        _gifWithFrames(count),
        resourceBudget: budget,
      );
      expect(animation.frameCount, count);
      expect(budget.residentBytes, count * 16);
      animation.dispose();
      expect(budget.residentBytes, 0);
    }

    final small = _largeFrameBudget(338 * 16 - 1);
    await expectLater(
      decodeRuntimeGif(_gifWithFrames(338), resourceBudget: small),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(small.residentBytes, 0);
    expect(small.transientBytes, 0);
  });

  test('keeps the 512 frame explicit override while defaulting to 500', () async {
    final bytes = _gifWithFrames(501);
    final budget = _largeFrameBudget(512 * 16);
    await expectLater(
      decodeRuntimeGif(bytes, resourceBudget: budget),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    final animation = await decodeRuntimeGif(
      _gifWithFrames(512),
      resourceBudget: budget,
      maximumFrames: 512,
    );
    expect(animation.frameCount, 512);
    animation.dispose();
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
  });

  test('loads a GIF with more than 256 frames from a file', () async {
    final root = Directory(
      Platform.environment['AVELUNE_QA_ROOT'] ?? Directory.systemTemp.path,
    );
    final directory = await root.createTemp('gif-many-frames-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/sample.gif');
    await file.writeAsBytes(_gifWithFrames(338));
    final budget = _largeFrameBudget(338 * 16);
    final animation = await loadRuntimeGifFromFilePath(
      file.path,
      resourceBudget: budget,
    );
    expect(animation.frameCount, 338);
    animation.dispose();
    expect(budget.residentBytes, 0);
  });

  test('loads a bounded GIF from a file and releases its resources', () async {
    final root = Directory(
      Platform.environment['AVELUNE_QA_ROOT'] ?? Directory.systemTemp.path,
    );
    final directory = await root.createTemp('gif-file-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/sample.gif');
    await file.writeAsBytes(_gif());
    final budget = _budget(32);
    final animation = await loadRuntimeGifFromFilePath(
      file.path,
      resourceBudget: budget,
    );
    expect(animation.frameCount, 2);
    expect(await _pixel(animation.frameAt(const Duration(milliseconds: 100))), [
      0,
      0,
      255,
      255,
    ]);
    animation.dispose();
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
    final small = RuntimeResourceBudget(
      profile: const RuntimeResourceProfile(maximumEncodedBytes: 8),
    );
    await expectLater(
      loadRuntimeGifFromFilePath(file.path, resourceBudget: small),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(small.residentBytes, 0);
    expect(small.transientBytes, 0);
  });

  test('releases file admission when the GIF is invalid', () async {
    final root = Directory(
      Platform.environment['AVELUNE_QA_ROOT'] ?? Directory.systemTemp.path,
    );
    final directory = await root.createTemp('gif-invalid-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/invalid.gif');
    await file.writeAsBytes([1, 2, 3]);
    final budget = _budget(32);
    await expectLater(
      loadRuntimeGifFromFilePath(file.path, resourceBudget: budget),
      throwsFormatException,
    );
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
    expect(budget.activeDecodes, 0);
  });

  test('disposes a file GIF frame completed after cancellation', () async {
    final root = Directory(
      Platform.environment['AVELUNE_QA_ROOT'] ?? Directory.systemTemp.path,
    );
    final directory = await root.createTemp('gif-cancelled-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/sample.gif');
    await file.writeAsBytes(_gif());
    final budget = _budget(32);
    final image = Completer<ui.Image>();
    final gate = Completer<void>();
    var current = true;
    final loading = loadRuntimeGifFromFilePath(
      file.path,
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

  test('packs frames into one image with a timed source rectangle', () async {
    final budget = _budget(160);
    final animation = await decodeRuntimeGif(_gif(), resourceBudget: budget);
    final atlas = await buildRuntimeGifAtlas(animation, maximumDimension: 8);
    expect(atlas, isNotNull);
    expect(atlas!.sourceAt(Duration.zero), const ui.Rect.fromLTWH(1, 1, 2, 2));
    expect(
      atlas.sourceAt(const Duration(milliseconds: 100)),
      const ui.Rect.fromLTWH(5, 1, 2, 2),
    );
    expect(
      atlas.sourceAt(const Duration(milliseconds: 300)),
      const ui.Rect.fromLTWH(1, 1, 2, 2),
    );
    final bytes = (await atlas.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    expect(bytes.sublist(0, 4), [255, 0, 0, 255]);
    expect(bytes.sublist(16, 20), [0, 0, 255, 255]);
    expect(bytes.sublist(44, 48), [255, 0, 0, 255]);
    expect(bytes.sublist(48, 52), [0, 0, 255, 255]);
    expect(budget.residentBytes, 160);
    animation.dispose();
    expect(budget.residentBytes, 128);
    final image = atlas.image;
    atlas.dispose();
    atlas.dispose();
    expect(image.debugDisposed, isTrue);
    expect(budget.residentBytes, 0);
    expect(() => atlas.sourceAt(Duration.zero), throwsStateError);
  });

  test(
    'keeps the original animation available if an atlas cannot fit',
    () async {
      final budget = _budget(32);
      final animation = await decodeRuntimeGif(_gif(), resourceBudget: budget);
      expect(
        await buildRuntimeGifAtlas(animation, maximumDimension: 4),
        isNull,
      );
      expect(
        await buildRuntimeGifAtlas(animation, maximumDimension: 8),
        isNull,
      );
      expect(
        await _pixel(animation.frameAt(const Duration(milliseconds: 100))),
        [0, 0, 255, 255],
      );
      expect(budget.residentBytes, 32);
      animation.dispose();
      expect(budget.residentBytes, 0);
    },
  );

  test('keeps the animation if atlas allocation fails', () async {
    final budget = _budget(160);
    final animation = await decodeRuntimeGif(_gif(), resourceBudget: budget);
    final atlas = await buildRuntimeGifAtlas(
      animation,
      maximumDimension: 8,
      rasterizer: (_, _, _) async => throw StateError('allocation failed'),
    );
    expect(atlas, isNull);
    expect(await _pixel(animation.frameAt(const Duration(milliseconds: 100))), [
      0,
      0,
      255,
      255,
    ]);
    expect(budget.residentBytes, 32);
    expect(budget.transientBytes, 0);
    animation.dispose();
    expect(budget.residentBytes, 0);
  });

  test('avoids unused atlas cells when the memory budget is tight', () async {
    final budget = _budget(240);
    final animation = await decodeRuntimeGif(
      _threeFrameGif(),
      resourceBudget: budget,
    );
    final atlas = await buildRuntimeGifAtlas(animation, maximumDimension: 12);
    expect(atlas, isNotNull);
    expect(atlas!.image.width * atlas.image.height, 48);
    expect(budget.residentBytes, 240);
    atlas.dispose();
    animation.dispose();
    expect(budget.residentBytes, 0);
  });

  test(
    'reuses the stage texture when the atlas source rectangle changes',
    () async {
      final budget = _budget(1024);
      final animation = await decodeRuntimeGif(_gif(), resourceBudget: budget);
      final atlas = (await buildRuntimeGifAtlas(
        animation,
        maximumDimension: 8,
      ))!;
      animation.dispose();
      final cache = BattleStageTextureCache(resourceBudget: budget);
      final firstRect = atlas.sourceAt(Duration.zero);
      cache.sync({atlas.image});
      await cache.settled;
      final texture = cache.textureFor(atlas.image);
      expect(texture, isNotNull);
      final secondRect = atlas.sourceAt(const Duration(milliseconds: 100));
      expect(secondRect, isNot(firstRect));
      cache.sync({atlas.image});
      await cache.settled;
      expect(identical(cache.textureFor(atlas.image), texture), isTrue);
      expect(cache.diagnostics.startedImports, 1);
      expect(cache.diagnostics.evictions, 0);
      cache.close();
      atlas.dispose();
      expect(budget.residentBytes, 0);
      expect(budget.transientBytes, 0);
    },
  );

  test('rejects an atlas whose decoded dimensions changed', () async {
    final budget = _budget(160);
    final animation = await decodeRuntimeGif(_gif(), resourceBudget: budget);
    late ui.Image wrongImage;
    final atlas = await buildRuntimeGifAtlas(
      animation,
      maximumDimension: 8,
      rasterizer: (picture, _, _) async =>
          wrongImage = await picture.toImage(1, 1),
    );
    expect(atlas, isNull);
    expect(wrongImage.debugDisposed, isTrue);
    expect(budget.residentBytes, 32);
    animation.dispose();
    expect(budget.residentBytes, 0);
  });

  test('disposes a late atlas after the animation is removed', () async {
    final budget = _budget(160);
    final animation = await decodeRuntimeGif(_gif(), resourceBudget: budget);
    final rendered = Completer<ui.Image>();
    final gate = Completer<void>();
    final building = buildRuntimeGifAtlas(
      animation,
      maximumDimension: 8,
      rasterizer: (picture, width, height) async {
        final image = await picture.toImage(width, height);
        rendered.complete(image);
        await gate.future;
        return image;
      },
    );
    final rejected = expectLater(
      building,
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    final image = await rendered.future;
    animation.dispose();
    gate.complete();
    await rejected;
    expect(image.debugDisposed, isTrue);
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

  test('preserves transparency when packing frames into an atlas', () async {
    final budget = _budget(160);
    final animation = await decodeRuntimeGif(
      _transparentGif(),
      resourceBudget: budget,
    );
    final atlas = (await buildRuntimeGifAtlas(animation, maximumDimension: 8))!;
    final bytes = (await atlas.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    expect(bytes[55], 0);
    expect(bytes.sublist(88, 92), [0, 0, 255, 255]);
    atlas.dispose();
    animation.dispose();
    expect(budget.residentBytes, 0);
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
