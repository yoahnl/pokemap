import 'dart:typed_data';

import 'package:archive/archive.dart' show ZLibDecoder, getCrc32;

import 'raster_image_dimensions.dart';

const _pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];

bool isCertainlyDecodablePng(
    List<int> bytes, RasterImageDimensions dimensions) {
  if (bytes.length < _pngSignature.length) return false;
  for (var index = 0; index < _pngSignature.length; index++) {
    if (bytes[index] != _pngSignature[index]) return false;
  }
  final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  final view = ByteData.sublistView(data);
  final idat = <Uint8List>[];
  var colorType = -1;
  var bits = 0;
  var paletteLength = 0;
  var offset = _pngSignature.length;
  while (true) {
    if (data.length - offset < 12) return false;
    final length = view.getUint32(offset);
    if (length > data.length - offset - 12) return false;
    final start = offset + 8;
    final end = start + length;
    for (var index = offset + 4; index < start; index++) {
      final letter = data[index] | 32;
      if (letter < 0x61 || letter > 0x7a) return false;
    }
    final type = String.fromCharCodes(data, offset + 4, start);
    bool checksumMatches() =>
        getCrc32(Uint8List.sublistView(data, offset + 4, end)) ==
        view.getUint32(end);
    if ((colorType < 0) != (type == 'IHDR')) return false;
    switch (type) {
      case 'IHDR':
        if (length != 13 ||
            !checksumMatches() ||
            view.getUint32(start) != dimensions.width ||
            view.getUint32(start + 4) != dimensions.height ||
            dimensions.width < 1 ||
            dimensions.height < 1 ||
            data[start + 10] != 0 ||
            data[start + 11] != 0 ||
            data[start + 12] != 0) {
          return false;
        }
        bits = data[start + 8];
        colorType = data[start + 9];
        final supportedBits = switch (colorType) {
          0 => const [1, 2, 4, 8, 16],
          2 || 4 || 6 => const [8, 16],
          3 => const [1, 2, 4, 8],
          _ => const <int>[],
        };
        if (!supportedBits.contains(bits)) return false;
      case 'PLTE':
        if (length == 0 ||
            length % 3 != 0 ||
            length > 768 ||
            !checksumMatches()) {
          return false;
        }
        paletteLength = length;
      case 'tRNS':
        final validLength = switch (colorType) {
          0 => length == 2,
          2 => length == 6,
          3 => true,
          _ => false,
        };
        if (!validLength || !checksumMatches()) return false;
      case 'IDAT':
        if (colorType == 3 && paletteLength == 0 || !checksumMatches()) {
          return false;
        }
        idat.add(Uint8List.sublistView(data, start, end));
      case 'IEND':
        return idat.isNotEmpty &&
            _scanlinesAreDecodable(idat, colorType, bits, dimensions);
      case 'pHYs':
        if (length != 9) return false;
      case 'gAMA':
        if (length != 4) return false;
      case 'bKGD':
        final validBackground = switch (colorType) {
          0 || 4 => length == 2,
          2 || 6 => length == 6,
          _ => length == 1 && data[start] * 3 + 2 < paletteLength,
        };
        if (!validBackground) return false;
      case 'iCCP':
        final terminator = data.indexOf(0, start);
        if (terminator < 0 || terminator > end - 2) return false;
      case 'acTL' || 'fcTL' || 'fdAT':
        return false;
    }
    offset = end + 4;
  }
}

bool _scanlinesAreDecodable(List<Uint8List> idat, int colorType, int bits,
    RasterImageDimensions dimensions) {
  final channels = switch (colorType) {
    2 => 3,
    4 => 2,
    6 => 4,
    _ => 1,
  };
  final stride = 1 + ((dimensions.width * channels * bits + 7) >> 3);
  final compressed = BytesBuilder(copy: false);
  for (final chunk in idat) {
    compressed.add(chunk);
  }
  final List<int> scanlines;
  try {
    scanlines = const ZLibDecoder().decodeBytes(compressed.takeBytes());
  } on Object {
    return false;
  }
  if (scanlines.length != dimensions.height * stride) return false;
  for (var index = 0; index < scanlines.length; index += stride) {
    if (scanlines[index] > 4) return false;
  }
  return true;
}
