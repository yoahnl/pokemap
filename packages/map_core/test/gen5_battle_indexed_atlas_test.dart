import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/indexed_atlas.dart';

int _crc(List<int> data) {
  var value = 0xffffffff;
  for (final byte in data) {
    value ^= byte;
    for (var i = 0; i < 8; i++) {
      value = value & 1 == 0 ? value >> 1 : (value >> 1) ^ 0xedb88320;
    }
  }
  return (value ^ 0xffffffff) & 0xffffffff;
}

List<int> _chunk(String name, List<int> data) {
  final type = ascii.encode(name);
  final head = ByteData(4)..setUint32(0, data.length);
  final crc = ByteData(4)..setUint32(0, _crc([...type, ...data]));
  return [
    ...head.buffer.asUint8List(),
    ...type,
    ...data,
    ...crc.buffer.asUint8List(),
  ];
}

Uint8List _png({
  bool invalidIndex = false,
  int filter = 0,
  int colorType = 3,
  bool oversized = false,
  bool includeTransparency = true,
  bool corruptCompression = false,
}) {
  final header = ByteData(13)
    ..setUint32(0, 256)
    ..setUint32(4, 128)
    ..setUint8(8, 8)
    ..setUint8(9, colorType);
  final pixels = Uint8List(256 * 128);
  pixels[0] = invalidIndex ? 16 : 1;
  pixels[1] = 2;
  pixels[256] = 2;
  pixels[257] = 3;
  final raw = Uint8List(257 * 128 + (oversized ? 1 : 0));
  int paeth(int a, int b, int c) {
    final p = a + b - c;
    final x = (p - a).abs(), y = (p - b).abs(), z = (p - c).abs();
    return x <= y && x <= z ? a : (y <= z ? b : c);
  }

  for (var y = 0; y < 128; y++) {
    raw[y * 257] = filter;
    for (var x = 0; x < 256; x++) {
      final i = y * 256 + x;
      final left = x == 0 ? 0 : pixels[i - 1];
      final up = y == 0 ? 0 : pixels[i - 256];
      final corner = x == 0 || y == 0 ? 0 : pixels[i - 257];
      final prediction = switch (filter) {
        0 => 0,
        1 => left,
        2 => up,
        3 => (left + up) ~/ 2,
        4 => paeth(left, up, corner),
        _ => 0,
      };
      raw[y * 257 + x + 1] = (pixels[i] - prediction) & 255;
    }
  }
  return Uint8List.fromList([
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    ..._chunk('IHDR', header.buffer.asUint8List()),
    ..._chunk('PLTE', List<int>.filled(48, 0)),
    if (includeTransparency) ..._chunk('tRNS', [0]),
    ..._chunk('IDAT', corruptCompression ? [1, 2, 3] : zlib.encode(raw)),
    ..._chunk('IEND', []),
  ]);
}

void main() {
  test('preserves palette indices and makes index zero transparent', () {
    final image = decodeGen5IndexedAtlas(_png());
    expect((image.width, image.height), (256, 128));
    expect(image.indices.sublist(0, 3), [1, 2, 0]);
    final palette = List.generate(16, (i) => (r: i, g: 2 * i, b: 3 * i));
    final rgba = colorizeGen5IndexedAtlas(image, palette);
    expect(rgba.sublist(0, 12), [1, 2, 3, 255, 2, 4, 6, 255, 0, 0, 0, 0]);
  });

  test('recolors the same indices using the selected palette', () {
    final atlas = decodeGen5IndexedAtlas(_png());
    final normal = List.generate(16, (i) => (r: i, g: 0, b: 0));
    final shiny = List.generate(16, (i) => (r: 0, g: 0, b: i));
    expect(colorizeGen5IndexedAtlas(atlas, normal).sublist(0, 8), [
      1,
      0,
      0,
      255,
      2,
      0,
      0,
      255,
    ]);
    expect(colorizeGen5IndexedAtlas(atlas, shiny).sublist(0, 8), [
      0,
      0,
      1,
      255,
      0,
      0,
      2,
      255,
    ]);
    expect(
      () => colorizeGen5IndexedAtlas(atlas, normal.sublist(0, 15)),
      throwsFormatException,
    );
  });

  test('rejects corrupt chunks, wrong indices and non-indexed PNG', () {
    final corrupt = _png()..[30] ^= 1;
    expect(() => decodeGen5IndexedAtlas(corrupt), throwsFormatException);
    expect(
      () => decodeGen5IndexedAtlas(_png(invalidIndex: true)),
      throwsFormatException,
    );
    expect(
      () => decodeGen5IndexedAtlas(_png(colorType: 6)),
      throwsFormatException,
    );
    expect(
      () => decodeGen5IndexedAtlas(_png(includeTransparency: false)),
      throwsFormatException,
    );
    expect(
      () => decodeGen5IndexedAtlas(_png(oversized: true)),
      throwsFormatException,
    );
    expect(
      () => decodeGen5IndexedAtlas(_png(corruptCompression: true)),
      throwsFormatException,
    );
  });

  test('reconstructs all five PNG scanline filters', () {
    for (var filter = 0; filter <= 4; filter++) {
      final image = decodeGen5IndexedAtlas(_png(filter: filter));
      expect(image.indices.sublist(0, 3), [1, 2, 0]);
      expect(image.indices.sublist(256, 259), [2, 3, 0]);
    }
    expect(
      () => decodeGen5IndexedAtlas(_png(filter: 5)),
      throwsFormatException,
    );
  });
}
