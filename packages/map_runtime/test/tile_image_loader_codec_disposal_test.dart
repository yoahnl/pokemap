import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';

Future<Uint8List> _pngBytes() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 2, 2),
    ui.Paint()..color = const ui.Color(0xFF8844CC),
  );
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(2, 2);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

final class _TrackingCodec implements ui.Codec {
  _TrackingCodec(this.delegate);

  final ui.Codec delegate;
  int disposeCount = 0;

  @override
  int get frameCount => delegate.frameCount;

  @override
  int get repetitionCount => delegate.repetitionCount;

  @override
  Future<ui.FrameInfo> getNextFrame() => delegate.getNextFrame();

  @override
  void dispose() {
    disposeCount += 1;
    delegate.dispose();
  }
}

final class _FailingCodec implements ui.Codec {
  int disposeCount = 0;

  @override
  int get frameCount => 1;

  @override
  int get repetitionCount => 0;

  @override
  Future<ui.FrameInfo> getNextFrame() {
    return Future<ui.FrameInfo>.error(StateError('decode failed'));
  }

  @override
  void dispose() {
    disposeCount += 1;
  }
}

Future<ui.Image> _fakeImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 2, 2),
    ui.Paint()..color = const ui.Color(0xFF33AA77),
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(2, 2);
  } finally {
    picture.dispose();
  }
}

RuntimeTilesetImage _runtimeImage(ui.Image image) {
  return RuntimeTilesetImage(
    images: <ui.Image>[image],
    chunks: <RuntimeTilesetChunk>[
      RuntimeTilesetChunk(top: 0, height: image.height, width: image.width),
    ],
    width: image.width,
    height: image.height,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('decodeFirstFrameAndDispose disposes codec after success', () async {
    final codec = _TrackingCodec(
      await ui.instantiateImageCodec(await _pngBytes()),
    );

    final image = await decodeFirstFrameAndDispose(codec);

    expect(codec.disposeCount, equals(1));
    expect(image.debugDisposed, isFalse);
    image.dispose();
  });

  test('decodeFirstFrameAndDispose disposes codec after decode error',
      () async {
    final codec = _FailingCodec();

    await expectLater(
      decodeFirstFrameAndDispose(codec),
      throwsStateError,
    );

    expect(codec.disposeCount, equals(1));
  });

  test('chunk decode failure disposes images from earlier chunks', () async {
    final firstImage = await _fakeImage();
    addTearDown(() {
      if (!firstImage.debugDisposed) {
        firstImage.dispose();
      }
    });
    var decodeCount = 0;

    await expectLater(
      decodeRuntimeTilesetChunks(
        <Uint8List>[Uint8List(1), Uint8List(1)],
        decoder: (_) async {
          decodeCount += 1;
          if (decodeCount == 1) {
            return firstImage;
          }
          throw StateError('later chunk failed');
        },
      ),
      throwsStateError,
    );

    expect(firstImage.debugDisposed, isTrue);
  });

  test('batch file load failure disposes tilesets loaded earlier', () async {
    final firstImage = await _fakeImage();
    addTearDown(() {
      if (!firstImage.debugDisposed) firstImage.dispose();
    });
    var loadCount = 0;

    await expectLater(
      loadTilesetImagesById(
        const <String, String>{
          'first': '/tmp/first.png',
          'second': '/tmp/second.png',
        },
        loader: (
          path, {
          transparentColor,
        }) async {
          loadCount += 1;
          if (loadCount == 1) return _runtimeImage(firstImage);
          throw StateError('later tileset failed');
        },
      ),
      throwsStateError,
    );

    expect(firstImage.debugDisposed, isTrue);
  });

  test('single-flight cache dispose releases completed images once', () async {
    final image = await _fakeImage();
    addTearDown(() {
      if (!image.debugDisposed) image.dispose();
    });
    final runtimeImage = _runtimeImage(image);
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) async =>
          <String, RuntimeTilesetImage>{paths.keys.single: runtimeImage},
    );
    await cache.loadById(
      const <String, String>{'water': '/tmp/water.png'},
    );

    cache.dispose();
    cache.dispose();

    expect(image.debugDisposed, isTrue);
    await expectLater(
      cache.loadById(
        const <String, String>{'water': '/tmp/water.png'},
      ),
      throwsStateError,
    );
  });

  test('cache disposed in flight releases the late image', () async {
    final image = await _fakeImage();
    addTearDown(() {
      if (!image.debugDisposed) image.dispose();
    });
    final runtimeImage = _runtimeImage(image);
    final load = Completer<Map<String, RuntimeTilesetImage>>();
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) =>
          load.future,
    );
    final pending = cache.loadById(
      const <String, String>{'water': '/tmp/water.png'},
    );

    cache.dispose();
    load.complete(<String, RuntimeTilesetImage>{'water': runtimeImage});

    await expectLater(pending, throwsStateError);
    expect(image.debugDisposed, isTrue);
  });
}
