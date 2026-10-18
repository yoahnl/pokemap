import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_tileset_image.dart';

final defaultRuntimeResourceBudget = RuntimeResourceBudget();

typedef RuntimeTilesetImageBatchLoader =
    Future<Map<String, RuntimeTilesetImage>> Function(
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
    required this.loader,
    RuntimeResourceBudget? resourceBudget,
    this.identity = '',
  }) : resourceBudget = resourceBudget ?? RuntimeResourceBudget();

  final RuntimeTilesetImageBatchLoader loader;
  final RuntimeResourceBudget resourceBudget;
  final String identity;
  final Map<_RuntimeTilesetImageCacheKey, RuntimeTilesetImage> _completed =
      <_RuntimeTilesetImageCacheKey, RuntimeTilesetImage>{};
  final Map<_RuntimeTilesetImageCacheKey, Future<RuntimeTilesetImage?>>
  _inFlight = <_RuntimeTilesetImageCacheKey, Future<RuntimeTilesetImage?>>{};
  bool _isDisposed = false;
  Iterable<RuntimeTilesetImage> get loadedImages => _completed.values;

  Iterable<RuntimeTilesetImage> imagesForRequest(
    Map<String, String> absolutePathByTilesetId, {
    Map<String, TilesetTransparentColor> transparentColorByTilesetId = const {},
  }) sync* {
    for (final entry in absolutePathByTilesetId.entries) {
      final image =
          _completed[_RuntimeTilesetImageCacheKey(
            identity: identity,
            normalizedAbsolutePath: p.normalize(p.absolute(entry.value)),
            transparentColor: transparentColorByTilesetId[entry.key],
          )];
      if (image != null) yield image;
    }
  }

  void trimToBudget({
    required int maxBytes,
    required Iterable<RuntimeTilesetImage> retainedImages,
  }) {
    if (_isDisposed) return;
    final retained = Set<RuntimeTilesetImage>.identity()
      ..addAll(retainedImages);
    final oldestFirst = Set<RuntimeTilesetImage>.identity()
      ..addAll(_completed.values);
    var bytes = oldestFirst.fold<int>(
      0,
      (total, image) => total + image.width * image.height * 4,
    );
    for (final image in oldestFirst) {
      if (bytes <= maxBytes) break;
      if (retained.contains(image)) continue;
      bytes -= image.width * image.height * 4;
      evictImage(image);
    }
  }

  void evictImage(RuntimeTilesetImage image, {bool dispose = true}) {
    final owned = _completed.values.any((value) => identical(value, image));
    _completed.removeWhere((key, value) => identical(value, image));
    if (owned && dispose) image.dispose();
  }

  Future<Map<String, RuntimeTilesetImage>> loadById(
    Map<String, String> absolutePathByTilesetId, {
    Map<String, TilesetTransparentColor> transparentColorByTilesetId =
        const <String, TilesetTransparentColor>{},
    bool prefetch = false,
    bool Function()? isCurrent,
  }) {
    if (_isDisposed) {
      return Future<Map<String, RuntimeTilesetImage>>.error(
        StateError('RuntimeTilesetImageSingleFlightCache is disposed.'),
      );
    }
    if (!(isCurrent?.call() ?? true)) {
      return Future.error(const RuntimeResourceAdmissionException('cancelled'));
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
        identity: identity,
        normalizedAbsolutePath: p.normalize(p.absolute(entry.value)),
        transparentColor: transparentColorByTilesetId[entry.key],
      );
      final completed = _completed[key];
      if (completed != null) {
        _completed.remove(key);
        _completed[key] = completed;
        imageFutureById[entry.key] = Future<RuntimeTilesetImage?>.value(
          completed,
        );
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
      _startBatch(newSlotByKey, prefetch: prefetch, isCurrent: isCurrent);
    }
    return _collectLoadedImages(imageFutureById).then((images) {
      if (_isDisposed || !(isCurrent?.call() ?? true)) {
        throw const RuntimeResourceAdmissionException('cancelled_or_closed');
      }
      return images;
    });
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
    Map<_RuntimeTilesetImageCacheKey, _RuntimeTilesetImageLoadSlot> slotByKey, {
    required bool prefetch,
    bool Function()? isCurrent,
  }) {
    final pathById = <String, String>{
      for (final slot in slotByKey.values) slot.tilesetId: slot.absolutePath,
    };
    final transparentColorById = <String, TilesetTransparentColor>{
      for (final slot in slotByKey.values)
        if (slot.transparentColor != null)
          slot.tilesetId: slot.transparentColor!,
    };
    Future<Map<String, RuntimeTilesetImage>>.sync(
      () => identical(loader, loadTilesetImagesById)
          ? loadTilesetImagesById(
              pathById,
              transparentColorByTilesetId: transparentColorById,
              resourceBudget: resourceBudget,
              prefetch: prefetch,
              isCurrent: () => !_isDisposed,
            )
          : loader(pathById, transparentColorByTilesetId: transparentColorById),
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
    required this.identity,
    required this.normalizedAbsolutePath,
    required this.transparentColor,
  });

  final String identity;
  final String normalizedAbsolutePath;
  final TilesetTransparentColor? transparentColor;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _RuntimeTilesetImageCacheKey &&
            identity == other.identity &&
            normalizedAbsolutePath == other.normalizedAbsolutePath &&
            transparentColor == other.transparentColor;
  }

  @override
  int get hashCode =>
      Object.hash(identity, normalizedAbsolutePath, transparentColor);
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

Future<RuntimeTilesetImage> decodeRuntimeTilesetImage(
  Uint8List bytes, {
  TilesetTransparentColor? transparentColor,
  RuntimeResourceBudget? resourceBudget,
  bool prefetch = false,
  bool Function()? isCurrent,
}) async {
  final budget = resourceBudget ?? defaultRuntimeResourceBudget;
  _checkEncodedLength(bytes.length, budget);
  final reservation = await budget.acquire(
    transientBytes: bytes.length * 2,
    prefetch: prefetch,
    isCurrent: isCurrent,
  );
  return _decodeAdmittedImage(
    bytes,
    transparentColor: transparentColor,
    reservation: reservation,
    decoder: _decodeUiImageFromBytes,
  );
}

Future<RuntimeTilesetImage> loadTilesetImageFromFilePath(
  String absolutePath, {
  TilesetTransparentColor? transparentColor,
  RuntimeResourceBudget? resourceBudget,
  RuntimeUiImageDecoder? decoder,
  bool prefetch = false,
  bool Function()? isCurrent,
}) async {
  final file = File(absolutePath);
  if (!await file.exists()) {
    throw AssetNotFoundException('Image not found: $absolutePath');
  }
  final budget = resourceBudget ?? defaultRuntimeResourceBudget;
  final length = await file.length();
  _checkEncodedLength(length, budget);
  final reservation = await budget.acquire(
    transientBytes: length * 2,
    prefetch: prefetch,
    isCurrent: isCurrent,
  );
  try {
    final bytes = await readRuntimeImageFileBytes(file, length);
    return await _decodeAdmittedImage(
      bytes,
      transparentColor: transparentColor,
      reservation: reservation,
      decoder: decoder ?? _decodeUiImageFromBytes,
    );
  } catch (_) {
    reservation.release();
    rethrow;
  }
}

void _checkEncodedLength(int length, RuntimeResourceBudget budget) {
  if (length <= 0 || length > budget.profile.maximumEncodedBytes) {
    throw const RuntimeResourceAdmissionException('encoded_bytes');
  }
}

Future<Uint8List> readRuntimeImageFileBytes(File file, int length) async {
  final handle = await file.open();
  try {
    final bytes = await handle.read(length);
    if (bytes.length != length || await handle.readByte() != -1) {
      throw const RuntimeResourceAdmissionException(
        'image_changed_during_read',
      );
    }
    return bytes;
  } finally {
    await handle.close();
  }
}

Future<({int width, int height})> inspectRuntimeImageDimensions(
  Uint8List bytes,
) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.ImageDescriptor? descriptor;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    if (descriptor.width <= 0 || descriptor.height <= 0) {
      throw const RuntimeResourceAdmissionException('image_dimensions');
    }
    return (width: descriptor.width, height: descriptor.height);
  } finally {
    descriptor?.dispose();
    buffer.dispose();
  }
}

Future<RuntimeTilesetImage> _decodeAdmittedImage(
  Uint8List bytes, {
  required TilesetTransparentColor? transparentColor,
  required RuntimeResourceReservation reservation,
  required RuntimeUiImageDecoder decoder,
}) async {
  RuntimeTilesetImage? image;
  try {
    reservation.ensureCurrent();
    final dimensions = await inspectRuntimeImageDimensions(bytes);
    final pixels = runtimeImageRgbaByteLength(
      dimensions.width,
      dimensions.height,
      maximumBytes:
          reservation.profile.maximumResidentBytes <
              (reservation.profile.maximumTransientBytes - bytes.length * 2) ~/
                  4
          ? reservation.profile.maximumResidentBytes
          : (reservation.profile.maximumTransientBytes - bytes.length * 2) ~/ 4,
    );
    reservation.resize(
      residentBytes: pixels,
      transientBytes: bytes.length * 2 + pixels * 4,
    );
    image = await _loadTilesetImageWithUiCodec(
      bytes,
      transparentColor: transparentColor,
      decoder: decoder,
    );
    if (image.width != dimensions.width || image.height != dimensions.height) {
      throw const RuntimeResourceAdmissionException(
        'decoded_dimensions_changed',
      );
    }
    reservation.ensureCurrent();
    image.addDisposeListener(reservation.release);
    reservation.commit();
    return image;
  } catch (_) {
    image?.dispose();
    reservation.release();
    rethrow;
  }
}

Future<RuntimeTilesetImage> _loadTilesetImageWithUiCodec(
  Uint8List bytes, {
  required TilesetTransparentColor? transparentColor,
  RuntimeUiImageDecoder decoder = _decodeUiImageFromBytes,
}) async {
  final fullImage = await decoder(bytes);
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
    final byteData = await fullImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
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

Future<ui.Image> _decodeUiImageFromBytes(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  return decodeFirstFrameAndDispose(codec);
}

Future<Map<String, RuntimeTilesetImage>> loadTilesetImagesById(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId = const {},
  RuntimeTilesetImageFileLoader? loader,
  RuntimeTilesetImageLoadProgressSink? onProgress,
  RuntimeResourceBudget? resourceBudget,
  bool prefetch = false,
  bool Function()? isCurrent,
}) async {
  final budget = resourceBudget ?? defaultRuntimeResourceBudget;
  final RuntimeTilesetImageFileLoader load =
      loader ??
      (path, {transparentColor}) => loadTilesetImageFromFilePath(
        path,
        transparentColor: transparentColor,
        resourceBudget: budget,
        prefetch: prefetch,
        isCurrent: isCurrent,
      );
  final entries = absolutePathByTilesetId.entries.toList(growable: false);
  var completed = 0;
  Object? progressError;
  StackTrace? progressStack;
  final outcomes =
      <
        ({
          String key,
          RuntimeTilesetImage? image,
          Object? error,
          StackTrace? stackTrace,
        })
      >[];
  var next = 0;
  Future<void> worker() async {
    while (next < entries.length) {
      final e = entries[next++];
      try {
        if (!(isCurrent?.call() ?? true)) {
          throw const RuntimeResourceAdmissionException('cancelled');
        }
        final image = await load(
          e.value,
          transparentColor: transparentColorByTilesetId[e.key],
        );
        if (!(isCurrent?.call() ?? true)) {
          image.dispose();
          throw const RuntimeResourceAdmissionException('cancelled');
        }
        outcomes.add((key: e.key, image: image, error: null, stackTrace: null));
      } catch (error, stackTrace) {
        outcomes.add((
          key: e.key,
          image: null,
          error: error as Object?,
          stackTrace: stackTrace as StackTrace?,
        ));
      } finally {
        completed++;
        try {
          onProgress?.call(completed, entries.length);
        } catch (error, stack) {
          progressError ??= error;
          progressStack ??= stack;
        }
      }
    }
  }

  await Future.wait([
    for (
      var index = 0;
      index < budget.profile.maximumConcurrentDecodes && index < entries.length;
      index++
    )
      worker(),
  ]);
  final out = <String, RuntimeTilesetImage>{};
  Object? firstError = progressError;
  StackTrace? firstStackTrace = progressStack;
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
