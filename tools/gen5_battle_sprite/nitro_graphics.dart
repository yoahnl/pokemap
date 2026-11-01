import 'dart:typed_data';

import 'indexed_atlas.dart';

bool _hasMagic(Uint8List bytes, int offset, String magic) => List.generate(
  4,
  (index) => bytes[offset + index] == magic.codeUnitAt(index),
).every((matches) => matches);

({int start, int end}) _findSection(
  Uint8List bytes,
  String fileMagic,
  String sectionMagic, {
  required int version,
}) {
  if (bytes.length < 16 ||
      bytes.length > 1048576 ||
      !_hasMagic(bytes, 0, fileMagic)) {
    throw const FormatException('Invalid Nitro graphics file');
  }
  final data = ByteData.sublistView(bytes);
  final headerSize = data.getUint16(12, Endian.little);
  final sectionCount = data.getUint16(14, Endian.little);
  if (data.getUint16(4, Endian.little) != 0xfeff ||
      data.getUint16(6, Endian.little) != version ||
      data.getUint32(8, Endian.little) != bytes.length ||
      headerSize != 16 ||
      sectionCount < 1 ||
      sectionCount > 32) {
    throw const FormatException('Invalid Nitro graphics header');
  }
  var offset = headerSize;
  ({int start, int end})? selected;
  for (var index = 0; index < sectionCount; index++) {
    if (offset > bytes.length - 8) {
      throw const FormatException('Truncated Nitro graphics section');
    }
    final length = data.getUint32(offset + 4, Endian.little);
    if (length < 8 || length > bytes.length - offset) {
      throw const FormatException('Invalid Nitro graphics section size');
    }
    if (_hasMagic(bytes, offset, sectionMagic)) {
      if (selected != null) {
        throw const FormatException('Duplicate Nitro graphics section');
      }
      selected = (start: offset, end: offset + length);
    }
    offset += length;
  }
  if (offset != bytes.length || selected == null) {
    throw const FormatException('Missing or invalid Nitro graphics section');
  }
  return selected;
}

Gen5IndexedAtlas decodeGen5NcgrAtlas(Uint8List bytes) {
  final section = _findSection(bytes, 'RGCN', 'RAHC', version: 0x0101);
  if (section.end - section.start < 32) {
    throw const FormatException('Truncated Nitro character section');
  }
  final data = ByteData.sublistView(bytes);
  final start = section.start;
  final length = data.getUint32(start + 24, Endian.little);
  final content = start + 8 + data.getUint32(start + 28, Endian.little);
  if (data.getUint16(start + 8, Endian.little) != 16 ||
      data.getUint16(start + 10, Endian.little) != 32 ||
      data.getUint32(start + 12, Endian.little) != 3 ||
      data.getUint32(start + 16, Endian.little) != 0 ||
      data.getUint32(start + 20, Endian.little) != 1 ||
      length != 256 * 128 ~/ 2 ||
      content < start + 32 ||
      content > section.end - length) {
    throw const FormatException('Unsupported Nitro battle atlas');
  }
  final indices = Uint8List(256 * 128);
  for (var index = 0; index < length; index++) {
    final packed = bytes[content + index];
    indices[index * 2] = packed & 15;
    indices[index * 2 + 1] = packed >> 4;
  }
  return Gen5IndexedAtlas.fromIndices(indices);
}

List<({int r, int g, int b})> decodeGen5NclrPalette(Uint8List bytes) {
  final section = _findSection(bytes, 'RLCN', 'TTLP', version: 0x0100);
  if (section.end - section.start < 24) {
    throw const FormatException('Truncated Nitro palette section');
  }
  final data = ByteData.sublistView(bytes);
  final start = section.start;
  final length = data.getUint32(start + 16, Endian.little);
  final content = start + 8 + data.getUint32(start + 20, Endian.little);
  if (data.getUint32(start + 8, Endian.little) != 0x000a0004 ||
      data.getUint32(start + 12, Endian.little) != 0 ||
      length != 32 ||
      content < start + 24 ||
      content > section.end - length) {
    throw const FormatException('Unsupported Nitro battle palette');
  }
  int expand(int value) => (value << 3) | (value >> 2);
  return List.unmodifiable(
    List.generate(16, (index) {
      final color = data.getUint16(content + index * 2, Endian.little);
      return (
        r: expand(color & 31),
        g: expand((color >> 5) & 31),
        b: expand((color >> 10) & 31),
      );
    }),
  );
}
