import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_tileset_image.dart';

typedef RuntimeTilesetImageBatchLoader
    = Future<Map<String, RuntimeTilesetImage>> Function(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId,
});
typedef RuntimeUiImageDecoder = Future<ui.Image> Function(Uint8List bytes);
typedef RuntimeTilesetImageFileLoader = Future<RuntimeTilesetImage> Function(
  String absolutePath, {
  TilesetTransparentColor? transparentColor,
});
typedef RuntimeTilesetImageLoadProgressSink = void Function(
  int completed,
  int total,
);

final class RuntimeTilesetImageSingleFlightCache {
  RuntimeTilesetImageSingleFlightCache({
    required RuntimeTilesetImageBatchLoader loader,
  }) : _loader = loader;

  final RuntimeTilesetImageBatchLoader _loader;
  final Map<_RuntimeTilesetImageCacheKey, RuntimeTilesetImage> _completed =
      <_RuntimeTilesetImageCacheKey, RuntimeTilesetImage>{};
  final Map<_RuntimeTilesetImageCacheKey, Future<RuntimeTilesetImage?>>
      _inFlight =
      <_RuntimeTilesetImageCacheKey, Future<RuntimeTilesetImage?>>{};
  bool _isDisposed = false;

  Future<Map<String, RuntimeTilesetImage>> loadById(
    Map<String, String> absolutePathByTilesetId, {
    Map<String, TilesetTransparentColor> transparentColorByTilesetId =
        const <String, TilesetTransparentColor>{},
  }) {
    if (_isDisposed) {
      return Future<Map<String, RuntimeTilesetImage>>.error(
        StateError('RuntimeTilesetImageSingleFlightCache is disposed.'),
      );
    }
    if (absolutePathByTilesetId.isEmpty) {
      return Future<Map<String, RuntimeTilesetImage>>.value(
        const <String, RuntimeTilesetImage>{},
      );
    }

    final imageFutureById = <String, Future<RuntimeTilesetImage?>>{};
    final newSlotByKey =
        <_RuntimeTilesetImageCacheKey, _RuntimeTilesetImageLoadSlot>{};
    for (final entry in absolutePathByTilesetId.entries) {
      final key = _RuntimeTilesetImageCacheKey(
        normalizedAbsolutePath: p.normalize(p.absolute(entry.value)),
        transparentColor: transparentColorByTilesetId[entry.key],
      );
      final completed = _completed[key];
      if (completed != null) {
        imageFutureById[entry.key] =
            Future<RuntimeTilesetImage?>.value(completed);
        continue;
      }
      final inFlight = _inFlight[key];
      if (inFlight != null) {
        imageFutureById[entry.key] = inFlight;
        continue;
      }
      final existingNewSlot = newSlotByKey[key];
      if (existingNewSlot != null) {
        imageFutureById[entry.key] = existingNewSlot.completer.future;
        continue;
      }

      final completer = Completer<RuntimeTilesetImage?>();
      final slot = _RuntimeTilesetImageLoadSlot(
        tilesetId: entry.key,
        absolutePath: entry.value,
        transparentColor: transparentColorByTilesetId[entry.key],
        completer: completer,
      );
      newSlotByKey[key] = slot;
      _inFlight[key] = completer.future;
      imageFutureById[entry.key] = completer.future;
    }

    if (newSlotByKey.isNotEmpty) {
      _startBatch(newSlotByKey);
    }
    return _collectLoadedImages(imageFutureById);
  }

  Future<Map<String, RuntimeTilesetImage>> _collectLoadedImages(
    Map<String, Future<RuntimeTilesetImage?>> imageFutureById,
  ) async {
    final entries = imageFutureById.entries.toList(growable: false);
    final images = await Future.wait<RuntimeTilesetImage?>(
      entries.map((entry) => entry.value),
    );
    return <String, RuntimeTilesetImage>{
      for (var index = 0; index < entries.length; index += 1)
        if (images[index] != null) entries[index].key: images[index]!,
    };
  }

  void _startBatch(
    Map<_RuntimeTilesetImageCacheKey, _RuntimeTilesetImageLoadSlot> slotByKey,
  ) {
    final pathById = <String, String>{
      for (final slot in slotByKey.values) slot.tilesetId: slot.absolutePath,
    };
    final transparentColorById = <String, TilesetTransparentColor>{
      for (final slot in slotByKey.values)
        if (slot.transparentColor != null)
          slot.tilesetId: slot.transparentColor!,
    };
    Future<Map<String, RuntimeTilesetImage>>.sync(
      () => _loader(
        pathById,
        transparentColorByTilesetId: transparentColorById,
      ),
    ).then<void>(
      (loadedById) {
        if (_isDisposed) {
          final uniqueImages = Set<RuntimeTilesetImage>.identity()
            ..addAll(loadedById.values);
          for (final image in uniqueImages) {
            image.dispose();
          }
          final error = StateError(
            'RuntimeTilesetImageSingleFlightCache was disposed while loading.',
          );
          for (final entry in slotByKey.entries) {
            final key = entry.key;
            final completer = entry.value.completer;
            if (identical(_inFlight[key], completer.future)) {
              _inFlight.remove(key);
            }
            completer.completeError(error);
          }
          return;
        }
        final requestedImages = Set<RuntimeTilesetImage>.identity();
        for (final slot in slotByKey.values) {
          final image = loadedById[slot.tilesetId];
          if (image != null) {
            requestedImages.add(image);
          }
        }
        final returnedImages = Set<RuntimeTilesetImage>.identity()
          ..addAll(loadedById.values);
        for (final image in returnedImages) {
          if (!requestedImages.contains(image)) {
            image.dispose();
          }
        }
        for (final entry in slotByKey.entries) {
          final key = entry.key;
          final slot = entry.value;
          final image = loadedById[slot.tilesetId];
          if (image != null) {
            _completed[key] = image;
          }
          if (identical(_inFlight[key], slot.completer.future)) {
            _inFlight.remove(key);
          }
          slot.completer.complete(image);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        for (final entry in slotByKey.entries) {
          final key = entry.key;
          final completer = entry.value.completer;
          if (identical(_inFlight[key], completer.future)) {
            _inFlight.remove(key);
          }
          completer.completeError(error, stackTrace);
        }
      },
    );
  }

  /// Releases completed images owned by this game-scoped cache.
  ///
  /// In-flight batches cannot be cancelled. Their completion path observes the
  /// disposed state, releases late images, and fails waiting callers.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    final uniqueImages = Set<RuntimeTilesetImage>.identity()
      ..addAll(_completed.values);
    _completed.clear();
    for (final image in uniqueImages) {
      image.dispose();
    }
  }
}

final class _RuntimeTilesetImageLoadSlot {
  const _RuntimeTilesetImageLoadSlot({
    required this.tilesetId,
    required this.absolutePath,
    required this.transparentColor,
    required this.completer,
  });

  final String tilesetId;
  final String absolutePath;
  final TilesetTransparentColor? transparentColor;
  final Completer<RuntimeTilesetImage?> completer;
}

final class _RuntimeTilesetImageCacheKey {
  const _RuntimeTilesetImageCacheKey({
    required this.normalizedAbsolutePath,
    required this.transparentColor,
  });

  final String normalizedAbsolutePath;
  final TilesetTransparentColor? transparentColor;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _RuntimeTilesetImageCacheKey &&
            normalizedAbsolutePath == other.normalizedAbsolutePath &&
            transparentColor == other.transparentColor;
  }

  @override
  int get hashCode => Object.hash(normalizedAbsolutePath, transparentColor);
}

Future<ui.Image> loadImageFromFilePath(String absolutePath) async {
  final file = File(absolutePath);
  if (!await file.exists()) {
    throw AssetNotFoundException('Image not found: $absolutePath');
  }
  final bytes = await file.readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  return decodeFirstFrameAndDispose(codec);
}

Future<ui.Image> decodeFirstFrameAndDispose(ui.Codec codec) async {
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}

Future<List<ui.Image>> decodeRuntimeTilesetChunks(
  Iterable<Uint8List> encodedChunks, {
  RuntimeUiImageDecoder decoder = _decodeUiImageFromBytes,
}) async {
  final images = <ui.Image>[];
  try {
    for (final bytes in encodedChunks) {
      images.add(await decoder(bytes));
    }
    return images;
  } catch (_) {
    for (final image in images) {
      image.dispose();
    }
    rethrow;
  }
}

Future<RuntimeTilesetImage> loadTilesetImageFromFilePath(
  String absolutePath, {
  TilesetTransparentColor? transparentColor,
}) async {
  final file = File(absolutePath);
  if (!await file.exists()) {
    throw AssetNotFoundException('Image not found: $absolutePath');
  }
  final bytes = await file.readAsBytes();
  // Chemin principal : décodage unique par le codec moteur. L'ancien chemin
  // décodait chaque atlas via package:image (pur Dart, 10-50x plus lent, sur
  // l'isolate UI) puis re-décodait les mêmes octets côté moteur — et la
  // branche multi-chunk ré-encodait même des PNG intermédiaires.
  try {
    return await _loadTilesetImageWithUiCodec(
      bytes,
      transparentColor: transparentColor,
    );
  } catch (_) {
    // Filet de sécurité : formats que package:image accepte mais pas le
    // moteur, ou readback indisponible. Comportement d'origine conservé.
    return _loadTilesetImageWithImagePackage(
      absolutePath,
      bytes,
      transparentColor: transparentColor,
    );
  }
}

Future<RuntimeTilesetImage> _loadTilesetImageWithUiCodec(
  Uint8List bytes, {
  required TilesetTransparentColor? transparentColor,
}) async {
  final fullImage = await _decodeUiImageFromBytes(bytes);
  final width = fullImage.width;
  final height = fullImage.height;
  final chunks = buildRuntimeTilesetChunks(
    totalWidth: width,
    totalHeight: height,
  );

  if (transparentColor == null && chunks.length <= 1) {
    return RuntimeTilesetImage(
      images: <ui.Image>[fullImage],
      chunks: chunks,
      width: width,
      height: height,
    );
  }

  // Transparence et/ou découpe : une passe sur les octets RGBA plats, sans
  // objet Pixel boxé ni ré-encodage PNG.
  try {
    final byteData =
        await fullImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      throw StateError('Tileset image readback is unavailable.');
    }
    final rgba = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    if (transparentColor != null) {
      for (var offset = 0; offset < rgba.length; offset += 4) {
        if (transparentColor.matchesRgb(
          red: rgba[offset],
          green: rgba[offset + 1],
          blue: rgba[offset + 2],
        )) {
          // Convention prémultipliée du moteur : un pixel invisible doit être
          // entièrement nul, sinon son RGB résiduel teinte le blending.
          rgba[offset] = 0;
          rgba[offset + 1] = 0;
          rgba[offset + 2] = 0;
          rgba[offset + 3] = 0;
        }
      }
    }
    final images = <ui.Image>[];
    try {
      for (final chunk in chunks) {
        final chunkPixels = Uint8List.sublistView(
          rgba,
          chunk.top * width * 4,
          chunk.bottom * width * 4,
        );
        images.add(
          await _decodeImageFromRgbaPixels(
            chunkPixels,
            width: chunk.width,
            height: chunk.height,
          ),
        );
      }
    } catch (_) {
      for (final image in images) {
        image.dispose();
      }
      rethrow;
    }
    return RuntimeTilesetImage(
      images: images,
      chunks: chunks,
      width: width,
      height: height,
    );
  } finally {
    fullImage.dispose();
  }
}

Future<ui.Image> _decodeImageFromRgbaPixels(
  Uint8List pixels, {
  required int width,
  required int height,
}) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    width,
    height,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

Future<RuntimeTilesetImage> _loadTilesetImageWithImagePackage(
  String absolutePath,
  Uint8List bytes, {
  required TilesetTransparentColor? transparentColor,
}) async {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    final image = await loadImageFromFilePath(absolutePath);
    return RuntimeTilesetImage(
      images: <ui.Image>[image],
      chunks: buildRuntimeTilesetChunks(
        totalWidth: image.width,
        totalHeight: image.height,
      ),
      width: image.width,
      height: image.height,
    );
  }

  final displayImage = _applyTransparentColor(
    decoded,
    transparentColor: transparentColor,
  );
  final displayBytes = transparentColor == null
      ? bytes
      : Uint8List.fromList(img.encodePng(displayImage, level: 0));

  final chunks = buildRuntimeTilesetChunks(
    totalWidth: displayImage.width,
    totalHeight: displayImage.height,
  );
  if (chunks.length <= 1) {
    final image = await _decodeUiImageFromBytes(displayBytes);
    return RuntimeTilesetImage(
      images: <ui.Image>[image],
      chunks: chunks,
      width: displayImage.width,
      height: displayImage.height,
    );
  }

  final images = await decodeRuntimeTilesetChunks(chunks.map((chunk) {
    final cropped = img.copyCrop(
      displayImage,
      x: 0,
      y: chunk.top,
      width: chunk.width,
      height: chunk.height,
    );
    final chunkBytes = Uint8List.fromList(img.encodePng(cropped, level: 0));
    return chunkBytes;
  }));
  return RuntimeTilesetImage(
    images: images,
    chunks: chunks,
    width: displayImage.width,
    height: displayImage.height,
  );
}

img.Image _applyTransparentColor(
  img.Image source, {
  required TilesetTransparentColor? transparentColor,
}) {
  if (transparentColor == null) {
    return source;
  }
  final image = source.hasAlpha
      ? img.Image.from(source)
      : source.convert(
          numChannels: 4,
          alpha: 255,
        );
  for (var y = 0; y < image.height; y += 1) {
    for (var x = 0; x < image.width; x += 1) {
      final pixel = image.getPixel(x, y);
      final red = pixel.r.toInt();
      final green = pixel.g.toInt();
      final blue = pixel.b.toInt();
      if (transparentColor.matchesRgb(red: red, green: green, blue: blue)) {
        image.setPixelRgba(x, y, red, green, blue, 0);
      }
    }
  }
  return image;
}

Future<ui.Image> _decodeUiImageFromBytes(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  return decodeFirstFrameAndDispose(codec);
}

Future<Map<String, RuntimeTilesetImage>> loadTilesetImagesById(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId = const {},
  RuntimeTilesetImageFileLoader? loader,
  RuntimeTilesetImageLoadProgressSink? onProgress,
}) async {
  final load = loader ?? loadTilesetImageFromFilePath;
  // Chargements concurrents : la latence passe de la somme des décodages au
  // plus lent d'entre eux. Chaque résultat est capturé individuellement pour
  // pouvoir libérer les succès si un décodage échoue.
  final entries = absolutePathByTilesetId.entries.toList(growable: false);
  var completed = 0;
  final outcomes = await Future.wait(
    entries.map((e) async {
      try {
        final image = await load(
          e.value,
          transparentColor: transparentColorByTilesetId[e.key],
        );
        return (key: e.key, image: image, error: null, stackTrace: null);
      } catch (error, stackTrace) {
        return (
          key: e.key,
          image: null,
          error: error as Object?,
          stackTrace: stackTrace as StackTrace?,
        );
      } finally {
        completed++;
        onProgress?.call(completed, entries.length);
      }
    }),
  );
  final out = <String, RuntimeTilesetImage>{};
  Object? firstError;
  StackTrace? firstStackTrace;
  for (final outcome in outcomes) {
    final image = outcome.image;
    if (image != null) {
      out[outcome.key] = image;
    } else if (firstError == null) {
      firstError = outcome.error;
      firstStackTrace = outcome.stackTrace;
    }
  }
  if (firstError != null) {
    final uniqueImages = Set<RuntimeTilesetImage>.identity()
      ..addAll(out.values);
    for (final image in uniqueImages) {
      image.dispose();
    }
    Error.throwWithStackTrace(firstError, firstStackTrace!);
  }
  return out;
}
