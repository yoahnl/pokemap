/// Pixel dimensions decoded from the structural header of a raster asset.
///
/// Authoring only needs the trusted canvas bounds. Reading them from the
/// content-addressed bytes keeps `map_authoring` pure Dart and avoids trusting
/// user-entered atlas metadata or importing a platform image stack.
final class RasterImageDimensions {
  const RasterImageDimensions({required this.width, required this.height});

  final int width;
  final int height;
}

/// Decodes dimensions from the canonical bytes of supported raster formats.
///
/// A declared media type never suffices by itself: every branch verifies the
/// matching file signature and the bounds of the dimension-bearing header.
/// Returning `null` means the bytes cannot prove usable positive dimensions.
RasterImageDimensions? decodeRasterImageDimensions(
  List<int> bytes, {
  required String mediaType,
}) {
  final normalizedMediaType = mediaType.split(';').first.trim().toLowerCase();
  return switch (normalizedMediaType) {
    'image/png' => _pngDimensions(bytes),
    'image/jpeg' || 'image/jpg' => _jpegDimensions(bytes),
    'image/gif' => _gifDimensions(bytes),
    'image/webp' => _webpDimensions(bytes),
    _ => null,
  };
}

RasterImageDimensions? _pngDimensions(List<int> bytes) {
  const signature = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  if (bytes.length < 33 ||
      !_startsWithAt(bytes, 0, signature) ||
      _u32be(bytes, 8) != 13 ||
      !_asciiAt(bytes, 12, 'IHDR')) {
    return null;
  }
  return _positiveDimensions(
    width: _u32be(bytes, 16),
    height: _u32be(bytes, 20),
  );
}

RasterImageDimensions? _jpegDimensions(List<int> bytes) {
  if (!_startsWithAt(bytes, 0, const <int>[0xff, 0xd8])) return null;
  var offset = 2;
  while (offset < bytes.length) {
    while (offset < bytes.length && bytes[offset] != 0xff) {
      offset++;
    }
    while (offset < bytes.length && bytes[offset] == 0xff) {
      offset++;
    }
    if (offset >= bytes.length) return null;
    final marker = bytes[offset++];
    if (marker == 0x00 ||
        marker == 0x01 ||
        marker == 0xd8 ||
        (marker >= 0xd0 && marker <= 0xd7)) {
      continue;
    }
    if (marker == 0xd9 || marker == 0xda) return null;
    if (offset + 2 > bytes.length) return null;
    final segmentLength = _u16be(bytes, offset);
    if (segmentLength < 2 || offset + segmentLength > bytes.length) {
      return null;
    }
    if (_jpegStartOfFrameMarkers.contains(marker) && segmentLength >= 7) {
      return _positiveDimensions(
        width: _u16be(bytes, offset + 5),
        height: _u16be(bytes, offset + 3),
      );
    }
    offset += segmentLength;
  }
  return null;
}

RasterImageDimensions? _gifDimensions(List<int> bytes) {
  if (bytes.length < 10 ||
      !(_asciiAt(bytes, 0, 'GIF87a') || _asciiAt(bytes, 0, 'GIF89a'))) {
    return null;
  }
  return _positiveDimensions(
    width: _u16le(bytes, 6),
    height: _u16le(bytes, 8),
  );
}

RasterImageDimensions? _webpDimensions(List<int> bytes) {
  if (bytes.length < 20 ||
      !_asciiAt(bytes, 0, 'RIFF') ||
      !_asciiAt(bytes, 8, 'WEBP')) {
    return null;
  }
  final declaredLength = _u32le(bytes, 4) + 8;
  if (declaredLength > bytes.length) return null;

  if (_asciiAt(bytes, 12, 'VP8X') &&
      bytes.length >= 30 &&
      _u32le(bytes, 16) >= 10) {
    return _positiveDimensions(
      width: 1 + _u24le(bytes, 24),
      height: 1 + _u24le(bytes, 27),
    );
  }
  if (_asciiAt(bytes, 12, 'VP8L') &&
      bytes.length >= 25 &&
      _u32le(bytes, 16) >= 5 &&
      bytes[20] == 0x2f) {
    return _positiveDimensions(
      width: 1 + bytes[21] + ((bytes[22] & 0x3f) << 8),
      height:
          1 + (bytes[22] >> 6) + (bytes[23] << 2) + ((bytes[24] & 0x0f) << 10),
    );
  }
  if (_asciiAt(bytes, 12, 'VP8 ') &&
      bytes.length >= 30 &&
      _u32le(bytes, 16) >= 10 &&
      _startsWithAt(bytes, 23, const <int>[0x9d, 0x01, 0x2a])) {
    return _positiveDimensions(
      width: _u16le(bytes, 26) & 0x3fff,
      height: _u16le(bytes, 28) & 0x3fff,
    );
  }
  return null;
}

RasterImageDimensions? _positiveDimensions({
  required int width,
  required int height,
}) =>
    width > 0 && height > 0
        ? RasterImageDimensions(width: width, height: height)
        : null;

bool _asciiAt(List<int> bytes, int offset, String value) =>
    _startsWithAt(bytes, offset, value.codeUnits);

bool _startsWithAt(List<int> bytes, int offset, List<int> prefix) {
  if (offset < 0 || offset + prefix.length > bytes.length) return false;
  for (var index = 0; index < prefix.length; index++) {
    if (bytes[offset + index] != prefix[index]) return false;
  }
  return true;
}

int _u16be(List<int> bytes, int offset) =>
    (bytes[offset] << 8) | bytes[offset + 1];

int _u16le(List<int> bytes, int offset) =>
    bytes[offset] | (bytes[offset + 1] << 8);

int _u24le(List<int> bytes, int offset) =>
    bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);

int _u32be(List<int> bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];

int _u32le(List<int> bytes, int offset) =>
    bytes[offset] |
    (bytes[offset + 1] << 8) |
    (bytes[offset + 2] << 16) |
    (bytes[offset + 3] << 24);

const Set<int> _jpegStartOfFrameMarkers = <int>{
  0xc0,
  0xc1,
  0xc2,
  0xc3,
  0xc5,
  0xc6,
  0xc7,
  0xc9,
  0xca,
  0xcb,
  0xcd,
  0xce,
  0xcf,
};
