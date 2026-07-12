import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Maximum decoded or allocated raster canvas size accepted by this service.
const rasterAssetPixelBudget = 64 * 1024 * 1024;

enum RasterAssetAnchor { topLeft, center, bottomCenter }

enum RasterAssetResizeMode { none, containNearest }

final class RasterAssetGridNormalizationRequest {
  const RasterAssetGridNormalizationRequest({
    required this.bytes,
    required this.gridWidth,
    required this.gridHeight,
    this.targetWidth,
    this.targetHeight,
    this.anchor = RasterAssetAnchor.bottomCenter,
    this.resizeMode = RasterAssetResizeMode.none,
    this.trimTransparentBorder = false,
  });

  final Uint8List bytes;
  final int gridWidth;
  final int gridHeight;
  final int? targetWidth;
  final int? targetHeight;
  final RasterAssetAnchor anchor;
  final RasterAssetResizeMode resizeMode;
  final bool trimTransparentBorder;
}

Uint8List normalizeRasterAssetToGrid(
  RasterAssetGridNormalizationRequest request,
) {
  _validateDimensions(request);

  if (_containsPngAnimationControlChunk(request.bytes)) {
    throw const FormatException('Animated PNG assets are not supported.');
  }

  var source = _toRgba(_decodeSourceWithinPixelBudget(request.bytes));
  if (request.trimTransparentBorder) {
    source = _trimTransparentBorder(source);
  }

  final hasTarget = request.targetWidth != null;
  final targetWidth =
      request.targetWidth ?? _nextMultiple(source.width, request.gridWidth);
  final targetHeight =
      request.targetHeight ?? _nextMultiple(source.height, request.gridHeight);
  _ensurePixelBudget(
    targetWidth,
    targetHeight,
    label: 'Target raster canvas',
  );

  if (request.resizeMode == RasterAssetResizeMode.containNearest) {
    if (!hasTarget) {
      throw ArgumentError(
        'containNearest requires targetWidth and targetHeight.',
      );
    }
    source = _resizeContainedNearest(source, targetWidth, targetHeight);
  } else if (source.width > targetWidth || source.height > targetHeight) {
    throw ArgumentError(
      'Source ${source.width}x${source.height} does not fit '
      'target ${targetWidth}x$targetHeight with resize mode none.',
    );
  }

  final canvas = img.Image(
    width: targetWidth,
    height: targetHeight,
    numChannels: 4,
  );
  final (offsetX, offsetY) = switch (request.anchor) {
    RasterAssetAnchor.topLeft => (0, 0),
    RasterAssetAnchor.center => (
        (targetWidth - source.width) ~/ 2,
        (targetHeight - source.height) ~/ 2,
      ),
    RasterAssetAnchor.bottomCenter => (
        (targetWidth - source.width) ~/ 2,
        targetHeight - source.height,
      ),
  };
  _copyPixels(source, canvas, offsetX: offsetX, offsetY: offsetY);
  return Uint8List.fromList(img.encodePng(canvas));
}

void _validateDimensions(RasterAssetGridNormalizationRequest request) {
  if (request.gridWidth <= 0 || request.gridHeight <= 0) {
    throw ArgumentError('Grid dimensions must be positive.');
  }

  final hasTargetWidth = request.targetWidth != null;
  final hasTargetHeight = request.targetHeight != null;
  if (hasTargetWidth != hasTargetHeight) {
    throw ArgumentError(
      'targetWidth and targetHeight must be supplied together.',
    );
  }
  if (!hasTargetWidth) {
    return;
  }

  final targetWidth = request.targetWidth!;
  final targetHeight = request.targetHeight!;
  if (targetWidth <= 0 || targetHeight <= 0) {
    throw ArgumentError('Target dimensions must be positive.');
  }
  if (targetWidth % request.gridWidth != 0 ||
      targetHeight % request.gridHeight != 0) {
    throw ArgumentError('Target dimensions must be grid multiples.');
  }
  _ensurePixelBudget(
    targetWidth,
    targetHeight,
    label: 'Target raster canvas',
  );
}

img.Image _decodeSourceWithinPixelBudget(Uint8List bytes) {
  try {
    final decoder = img.findDecoderForData(bytes);
    if (decoder == null) {
      throw const FormatException('Expected valid raster image bytes.');
    }
    final info = decoder.startDecode(bytes);
    if (info == null) {
      throw const FormatException('Expected valid raster image bytes.');
    }
    _ensureSourcePixelBudget(info.width, info.height);
    final decoded = decoder.decode(bytes, frame: 0);
    if (decoded == null) {
      throw const FormatException('Expected valid raster image bytes.');
    }
    return decoded;
  } on FormatException {
    rethrow;
  } on RangeError {
    throw const FormatException('Expected valid raster image bytes.');
  } on Exception {
    throw const FormatException('Expected valid raster image bytes.');
  }
}

img.Image _toRgba(img.Image source) {
  return source.convert(
    format: img.Format.uint8,
    numChannels: 4,
    alpha: source.hasAlpha ? null : 255,
  );
}

img.Image _trimTransparentBorder(img.Image source) {
  var left = source.width;
  var top = source.height;
  var right = -1;
  var bottom = -1;

  for (var y = 0; y < source.height; y += 1) {
    for (var x = 0; x < source.width; x += 1) {
      if (source.getPixel(x, y).a.toInt() == 0) {
        continue;
      }
      left = math.min(left, x);
      top = math.min(top, y);
      right = math.max(right, x);
      bottom = math.max(bottom, y);
    }
  }

  if (right < left || bottom < top) {
    throw StateError('Cannot trim a fully transparent raster asset.');
  }

  _ensurePixelBudget(
    right - left + 1,
    bottom - top + 1,
    label: 'Trimmed raster asset',
  );
  final trimmed = img.Image(
    width: right - left + 1,
    height: bottom - top + 1,
    numChannels: 4,
  );
  for (var y = 0; y < trimmed.height; y += 1) {
    for (var x = 0; x < trimmed.width; x += 1) {
      _setPixel(trimmed, x, y, source.getPixel(left + x, top + y));
    }
  }
  return trimmed;
}

img.Image _resizeContainedNearest(
  img.Image source,
  int targetWidth,
  int targetHeight,
) {
  final scale = math.min(
    targetWidth / source.width,
    targetHeight / source.height,
  );
  final width = math.min(
    targetWidth,
    math.max(1, (source.width * scale).round()),
  );
  final height = math.min(
    targetHeight,
    math.max(1, (source.height * scale).round()),
  );
  _ensurePixelBudget(width, height, label: 'Resized raster asset');
  return img.copyResize(
    source,
    width: width,
    height: height,
    interpolation: img.Interpolation.nearest,
  );
}

void _copyPixels(
  img.Image source,
  img.Image destination, {
  required int offsetX,
  required int offsetY,
}) {
  for (var y = 0; y < source.height; y += 1) {
    for (var x = 0; x < source.width; x += 1) {
      _setPixel(
        destination,
        x + offsetX,
        y + offsetY,
        source.getPixel(x, y),
      );
    }
  }
}

void _setPixel(img.Image image, int x, int y, img.Pixel pixel) {
  image.setPixelRgba(
    x,
    y,
    pixel.r.toInt(),
    pixel.g.toInt(),
    pixel.b.toInt(),
    pixel.a.toInt(),
  );
}

int _nextMultiple(int value, int multiple) =>
    ((value + multiple - 1) ~/ multiple) * multiple;

void _ensureSourcePixelBudget(int width, int height) {
  if (width <= 0 || height <= 0 || width > rasterAssetPixelBudget ~/ height) {
    throw const FormatException(
      'Raster source dimensions exceed the $rasterAssetPixelBudget '
      'pixel budget.',
    );
  }
}

void _ensurePixelBudget(
  int width,
  int height, {
  required String label,
}) {
  if (width <= 0 || height <= 0 || width > rasterAssetPixelBudget ~/ height) {
    throw ArgumentError(
      '$label exceeds the $rasterAssetPixelBudget pixel budget.',
    );
  }
}

bool _containsPngAnimationControlChunk(Uint8List bytes) {
  const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < signature.length) {
    return false;
  }
  for (var index = 0; index < signature.length; index += 1) {
    if (bytes[index] != signature[index]) {
      return false;
    }
  }

  var offset = signature.length;
  while (offset + 12 <= bytes.length) {
    final length = (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    final chunkEnd = offset + 12 + length;
    if (length < 0 || chunkEnd > bytes.length) {
      return false;
    }
    if (bytes[offset + 4] == 97 &&
        bytes[offset + 5] == 99 &&
        bytes[offset + 6] == 84 &&
        bytes[offset + 7] == 76) {
      return true;
    }
    offset = chunkEnd;
  }
  return false;
}
