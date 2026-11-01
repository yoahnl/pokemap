import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

final class Gen5IndexedAtlas {
  Gen5IndexedAtlas._(Uint8List pixels)
    : indices = Uint8List.fromList(pixels).asUnmodifiableView();

  int get width => 256;
  int get height => 128;
  final Uint8List indices;
}

final class _BoundedSink extends ByteConversionSink {
  _BoundedSink(this.limit);
  final int limit;
  final _bytes = BytesBuilder();

  @override
  void add(List<int> chunk) {
    if (_bytes.length + chunk.length > limit) {
      throw const FormatException('PNG decompressed data exceeds limit');
    }
    _bytes.add(chunk);
  }

  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    if (_bytes.length + end - start > limit) {
      throw const FormatException('PNG decompressed data exceeds limit');
    }
    add(chunk.sublist(start, end));
    if (isLast) close();
  }

  @override
  void close() {}

  Uint8List takeBytes() => _bytes.takeBytes();
}

int _crc32(Uint8List bytes, int start, int end) {
  var crc = 0xffffffff;
  for (var i = start; i < end; i++) {
    crc ^= bytes[i];
    for (var bit = 0; bit < 8; bit++) {
      crc = crc & 1 == 0 ? crc >> 1 : (crc >> 1) ^ 0xedb88320;
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}

Gen5IndexedAtlas decodeGen5IndexedAtlas(Uint8List png) {
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  if (png.length < 8 ||
      png.length > 1048576 ||
      !List.generate(8, (i) => png[i] == signature[i]).every((v) => v)) {
    throw const FormatException('Invalid indexed atlas size or signature');
  }
  final data = ByteData.sublistView(png);
  final compressed = BytesBuilder();
  var offset = 8;
  var hasHeader = false;
  var hasPalette = false;
  var hasTransparency = false;
  var hasImageData = false;
  var imageDataEnded = false;
  var ended = false;
  while (offset < png.length) {
    if (png.length - offset < 12)
      throw const FormatException('Truncated PNG chunk');
    final length = data.getUint32(offset);
    if (length > png.length - offset - 12)
      throw const FormatException('Invalid PNG chunk size');
    final typeStart = offset + 4;
    final body = offset + 8;
    final end = body + length;
    for (var i = typeStart; i < body; i++) {
      final c = png[i];
      if (!((c >= 65 && c <= 90) || (c >= 97 && c <= 122))) {
        throw const FormatException('Invalid PNG chunk type');
      }
    }
    if (png[typeStart + 2] & 0x20 != 0) {
      throw const FormatException('Invalid PNG reserved bit');
    }
    if (_crc32(png, typeStart, end) != data.getUint32(end)) {
      throw const FormatException('PNG CRC mismatch');
    }
    final name = ascii.decode(png.sublist(typeStart, body));
    if (!hasHeader && name != 'IHDR')
      throw const FormatException('Missing PNG header');
    if (hasImageData && name != 'IDAT') imageDataEnded = true;
    switch (name) {
      case 'IHDR':
        if (hasHeader ||
            length != 13 ||
            data.getUint32(body) != 256 ||
            data.getUint32(body + 4) != 128 ||
            png[body + 8] != 8 ||
            png[body + 9] != 3 ||
            png[body + 10] != 0 ||
            png[body + 11] != 0 ||
            png[body + 12] != 0) {
          throw const FormatException('Unsupported indexed PNG header');
        }
        hasHeader = true;
      case 'PLTE':
        if (hasPalette || hasImageData || length != 48) {
          throw const FormatException('Invalid indexed PNG palette');
        }
        hasPalette = true;
      case 'tRNS':
        if (!hasPalette ||
            hasTransparency ||
            hasImageData ||
            length != 1 ||
            png[body] != 0) {
          throw const FormatException('Unsupported indexed PNG transparency');
        }
        hasTransparency = true;
      case 'IDAT':
        if (!hasPalette || !hasTransparency || imageDataEnded) {
          throw const FormatException('Invalid indexed PNG image data');
        }
        compressed.add(png.sublist(body, end));
        hasImageData = true;
      case 'IEND':
        if (!hasImageData || length != 0 || end + 4 != png.length) {
          throw const FormatException('Invalid indexed PNG end');
        }
        ended = true;
      default:
        if (png[typeStart] & 0x20 == 0)
          throw const FormatException('Unsupported critical PNG chunk');
    }
    offset = end + 4;
    if (ended) break;
  }
  if (!ended) throw const FormatException('Missing PNG end');
  const expected = 257 * 128;
  final sink = _BoundedSink(expected);
  try {
    final decoder = ZLibDecoder().startChunkedConversion(sink);
    decoder.add(compressed.takeBytes());
    decoder.close();
  } catch (_) {
    throw const FormatException('Invalid or oversized PNG compressed data');
  }
  final raw = sink.takeBytes();
  if (raw.length != expected)
    throw const FormatException('Invalid indexed PNG scanline size');
  final pixels = Uint8List(256 * 128);
  int paeth(int left, int up, int upperLeft) {
    final p = left + up - upperLeft;
    final a = (p - left).abs(), b = (p - up).abs(), c = (p - upperLeft).abs();
    return a <= b && a <= c ? left : (b <= c ? up : upperLeft);
  }

  for (var y = 0; y < 128; y++) {
    final filter = raw[y * 257];
    if (filter > 4) throw const FormatException('Unsupported PNG filter');
    for (var x = 0; x < 256; x++) {
      final index = y * 256 + x;
      final left = x == 0 ? 0 : pixels[index - 1];
      final up = y == 0 ? 0 : pixels[index - 256];
      final upperLeft = x == 0 || y == 0 ? 0 : pixels[index - 257];
      final prediction = switch (filter) {
        0 => 0,
        1 => left,
        2 => up,
        3 => (left + up) ~/ 2,
        4 => paeth(left, up, upperLeft),
        _ => throw StateError('Unreachable'),
      };
      final value = (raw[y * 257 + x + 1] + prediction) & 255;
      if (value > 15)
        throw const FormatException('Indexed PNG palette index out of range');
      pixels[index] = value;
    }
  }
  return Gen5IndexedAtlas._(pixels);
}

Uint8List colorizeGen5IndexedAtlas(
  Gen5IndexedAtlas atlas,
  List<({int r, int g, int b})> palette,
) {
  if (palette.length != 16 ||
      palette.any(
        (p) => [p.r, p.g, p.b].any((channel) => channel < 0 || channel > 255),
      )) {
    throw const FormatException('Invalid indexed atlas palette');
  }
  final rgba = Uint8List(atlas.indices.length * 4);
  for (var i = 0; i < atlas.indices.length; i++) {
    final index = atlas.indices[i];
    if (index == 0) continue;
    final color = palette[index];
    final offset = i * 4;
    rgba[offset] = color.r;
    rgba[offset + 1] = color.g;
    rgba[offset + 2] = color.b;
    rgba[offset + 3] = 255;
  }
  return rgba;
}
