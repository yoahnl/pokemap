import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
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
    bool countRetainedBytes = true,
  }) {
    if (_isDisposed) return;
    final retained = Set<RuntimeTilesetImage>.identity()
      ..addAll(retainedImages);
    final oldestFirst = Set<RuntimeTilesetImage>.identity()
      ..addAll(_completed.values);
    var bytes = oldestFirst.fold<int>(
      0,
      (total, image) => !countRetainedBytes && retained.contains(image)
          ? total
          : total + image.width * image.height * 4,
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
  final dimensions = _pngPrefixDimensions(bytes);
  final allocation = dimensions == null
      ? (residentBytes: 0, transientBytes: bytes.length * 2)
      : _imageAllocation(
          bytes.length,
          dimensions,
          transparentColor,
          budget.profile,
          sourceBitDepth: bytes[24],
        );
  final reservation = await budget.acquire(
    residentBytes: allocation.residentBytes,
    transientBytes: allocation.transientBytes,
    prefetch: prefetch,
    isCurrent: isCurrent,
  );
  return _decodeAdmittedImage(
    bytes,
    transparentColor: transparentColor,
    reservation: reservation,
    decoder: _decodeUiImageFromBytes,
    expectedDimensions: dimensions,
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
  final prefix = await _readPngPrefixDimensions(
    file,
    length,
    budget,
    prefetch: prefetch,
    isCurrent: isCurrent,
  );
  final dimensions = prefix?.dimensions;
  final allocation = dimensions == null
      ? (residentBytes: 0, transientBytes: length * 2)
      : _imageAllocation(
          length,
          dimensions,
          transparentColor,
          budget.profile,
          sourceBitDepth: prefix!.sourceBitDepth,
        );
  final reservation = await budget.acquire(
    residentBytes: allocation.residentBytes,
    transientBytes: allocation.transientBytes,
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
      expectedDimensions: dimensions,
    );
  } catch (_) {
    reservation.release();
    rethrow;
  }
}

({int width, int height})? _pngPrefixDimensions(Uint8List bytes) {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 33) {
    return null;
  }
  for (var index = 0; index < signature.length; index++) {
    if (bytes[index] != signature[index]) {
      return null;
    }
  }
  final header = ByteData.sublistView(bytes, 0, 33);
  if (header.getUint32(8) != 13 || header.getUint32(12) != 0x49484452) {
    return null;
  }
  return (width: header.getUint32(16), height: header.getUint32(20));
}

Future<({({int width, int height}) dimensions, int sourceBitDepth})?>
_readPngPrefixDimensions(
  File file,
  int length,
  RuntimeResourceBudget budget, {
  required bool prefetch,
  bool Function()? isCurrent,
}) async {
  final prefixLength = length < 33 ? length : 33;
  final reservation = await budget.acquire(
    transientBytes: prefixLength * 2,
    prefetch: prefetch,
    isCurrent: isCurrent,
  );
  try {
    final handle = await file.open();
    try {
      final prefix = await handle.read(prefixLength);
      if (prefix.length != prefixLength) {
        throw const RuntimeResourceAdmissionException(
          'image_changed_during_read',
        );
      }
      reservation.ensureCurrent();
      final dimensions = _pngPrefixDimensions(prefix);
      return dimensions == null
          ? null
          : (dimensions: dimensions, sourceBitDepth: prefix[24]);
    } finally {
      await handle.close();
    }
  } finally {
    reservation.release();
  }
}

({int residentBytes, int transientBytes}) _imageAllocation(
  int encodedLength,
  ({int width, int height}) dimensions,
  TilesetTransparentColor? transparentColor,
  RuntimeResourceProfile profile, {
  int sourceBitDepth = 8,
}) {
  return runtimeTilesetImageAllocation(
    encodedLength: encodedLength,
    width: dimensions.width,
    height: dimensions.height,
    transformRgba: transparentColor != null,
    sourceBitDepth: sourceBitDepth,
    profile: profile,
  );
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
  ({int width, int height})? expectedDimensions,
}) async {
  RuntimeTilesetImage? image;
  try {
    reservation.ensureCurrent();
    if (expectedDimensions != null &&
        _pngPrefixDimensions(bytes) != expectedDimensions) {
      throw const RuntimeResourceAdmissionException('image_dimensions_changed');
    }
    final dimensions = await inspectRuntimeImageDimensions(bytes);
    if (expectedDimensions != null && dimensions != expectedDimensions) {
      throw const RuntimeResourceAdmissionException('image_dimensions_changed');
    }
    final png = _pngPrefixDimensions(bytes);
    final allocation = _imageAllocation(
      bytes.length,
      dimensions,
      transparentColor,
      reservation.profile,
      sourceBitDepth: png == null ? 8 : bytes[24],
    );
    reservation.resize(
      residentBytes: allocation.residentBytes,
      transientBytes: allocation.transientBytes,
    );
    image = png != null && dimensions.height > runtimeTilesetChunkHeight
        ? await _loadChunkedPng(
            bytes,
            dimensions,
            transparentColor,
            reservation,
          )
        : await _loadTilesetImageWithUiCodec(
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

void _validatePngInflation(
  Uint8List bytes,
  ({int width, int height}) dimensions,
) {
  final bits = bytes[24];
  final colorType = bytes[25];
  final channels = switch (colorType) {
    0 || 3 => 1,
    2 => 3,
    4 => 2,
    6 => 4,
    _ => 0,
  };
  final legalBits = colorType == 0
      ? const [1, 2, 4, 8, 16]
      : colorType == 3
      ? const [1, 2, 4, 8]
      : const [8, 16];
  if (channels == 0 ||
      !legalBits.contains(bits) ||
      bytes[26] != 0 ||
      bytes[27] != 0 ||
      bytes[28] > 1) {
    throw const RuntimeResourceAdmissionException('png_format');
  }
  final passes = bytes[28] == 0
      ? const [(0, 0, 1, 1)]
      : const [
          (0, 0, 8, 8),
          (4, 0, 8, 8),
          (0, 4, 4, 8),
          (2, 0, 4, 4),
          (0, 2, 2, 4),
          (1, 0, 2, 2),
          (0, 1, 1, 2),
        ];
  var expected = 0;
  for (final pass in passes) {
    final w = dimensions.width <= pass.$1
        ? 0
        : (dimensions.width - pass.$1 + pass.$3 - 1) ~/ pass.$3;
    final h = dimensions.height <= pass.$2
        ? 0
        : (dimensions.height - pass.$2 + pass.$4 - 1) ~/ pass.$4;
    if (w != 0 && h != 0) {
      expected += (((w * channels * bits + 7) ~/ 8) + 1) * h;
    }
  }
  final counter = _PngInflationCounter(expected);
  final inflater = ZLibCodec().decoder.startChunkedConversion(counter);
  final data = ByteData.sublistView(bytes);
  var offset = 8;
  var chunks = 0;
  var foundData = false;
  var dataEnded = false;
  var ended = false;
  var closed = false;
  try {
    while (offset < bytes.length) {
      if (++chunks > 4096 || offset > bytes.length - 12) {
        throw const RuntimeResourceAdmissionException('png_chunks');
      }
      final length = data.getUint32(offset);
      if (length > bytes.length - offset - 12) {
        throw const RuntimeResourceAdmissionException('png_chunks');
      }
      final type = data.getUint32(offset + 4);
      if ((offset == 8 && (type != 0x49484452 || length != 13)) ||
          (offset != 8 && type == 0x49484452)) {
        throw const RuntimeResourceAdmissionException('png_chunks');
      }
      if (type == 0x6163544c || type == 0x6663544c || type == 0x66644154) {
        throw const RuntimeResourceAdmissionException('png_animation');
      }
      if (type == 0x49444154) {
        if (dataEnded) {
          throw const RuntimeResourceAdmissionException('png_chunks');
        }
        foundData = true;
        for (
          var start = offset + 8;
          start < offset + 8 + length;
          start += 1024
        ) {
          final end = start + 1024 < offset + 8 + length
              ? start + 1024
              : offset + 8 + length;
          inflater.add(Uint8List.sublistView(bytes, start, end));
        }
      } else if (foundData) {
        dataEnded = true;
      }
      offset += length + 12;
      if (type == 0x49454e44) {
        ended = length == 0 && offset == bytes.length;
        break;
      }
    }
    closed = true;
    inflater.close();
    if (!ended || !foundData || counter.count != expected) {
      throw const RuntimeResourceAdmissionException('png_scanlines');
    }
  } on RuntimeResourceAdmissionException {
    rethrow;
  } on Object {
    throw const RuntimeResourceAdmissionException('png_scanlines');
  } finally {
    if (!closed) {
      try {
        inflater.close();
      } on Object {}
    }
  }
}

final class _PngInflationCounter extends ByteConversionSinkBase {
  _PngInflationCounter(this.expected);
  final int expected;
  int count = 0;
  @override
  void add(List<int> chunk) {
    if (chunk.length > expected - count) {
      throw const RuntimeResourceAdmissionException('png_scanlines');
    }
    count += chunk.length;
  }

  @override
  void close() {}
}

Uint8List _decodePngRgba(
  Uint8List bytes,
  ({int width, int height}) dimensions,
  TilesetTransparentColor? transparentColor,
) {
  _validatePngInflation(bytes, dimensions);
  final decoded = img.decodePng(bytes, frame: 0);
  if (decoded == null ||
      decoded.width != dimensions.width ||
      decoded.height != dimensions.height) {
    throw const RuntimeResourceAdmissionException('decoded_dimensions_changed');
  }
  final rgba = decoded
      .convert(format: img.Format.uint8, numChannels: 4)
      .toUint8List();
  for (var offset = 0; offset < rgba.length; offset += 4) {
    final alpha =
        transparentColor?.matchesRgb(
              red: rgba[offset],
              green: rgba[offset + 1],
              blue: rgba[offset + 2],
            ) ==
            true
        ? 0
        : rgba[offset + 3];
    for (var channel = 0; channel < 3; channel++) {
      rgba[offset + channel] = (rgba[offset + channel] * alpha + 127) ~/ 255;
    }
    rgba[offset + 3] = alpha;
  }
  return rgba;
}

Future<RuntimeTilesetImage> _loadChunkedPng(
  Uint8List bytes,
  ({int width, int height}) dimensions,
  TilesetTransparentColor? transparentColor,
  RuntimeResourceReservation reservation,
) async {
  final rgba = await Isolate.run(
    () => _decodePngRgba(bytes, dimensions, transparentColor),
  );
  final chunks = buildRuntimeTilesetChunks(
    totalWidth: dimensions.width,
    totalHeight: dimensions.height,
  );
  final images = <ui.Image>[];
  try {
    for (final chunk in chunks) {
      reservation.ensureCurrent();
      final pixels = Uint8List.sublistView(
        rgba,
        chunk.top * dimensions.width * 4,
        chunk.bottom * dimensions.width * 4,
      );
      images.add(
        await _decodeImageFromRgbaPixels(
          pixels,
          width: chunk.width,
          height: chunk.height,
        ),
      );
    }
    return RuntimeTilesetImage(
      images: images,
      chunks: chunks,
      width: dimensions.width,
      height: dimensions.height,
    );
  } catch (_) {
    for (final image in images) {
      image.dispose();
    }
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
