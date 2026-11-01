import 'dart:typed_data';

final class Gen5NcerObject {
  const Gen5NcerObject(this.attr0, this.attr1, this.attr2);

  final int attr0;
  final int attr1;
  final int attr2;

  int get x => (attr1 & 0x1ff) >= 256 ? (attr1 & 0x1ff) - 512 : attr1 & 0x1ff;
  int get y => (attr0 & 0xff) >= 128 ? (attr0 & 0xff) - 256 : attr0 & 0xff;
  int get shape => (attr0 >> 14) & 3;
  int get size => (attr1 >> 14) & 3;
  int get width => const [
    [8, 16, 32, 64],
    [16, 32, 32, 64],
    [8, 8, 16, 32],
  ][shape][size];
  int get height => const [
    [8, 16, 32, 64],
    [8, 8, 16, 32],
    [16, 32, 32, 64],
  ][shape][size];
  int get tileIndex => attr2 & 0x3ff;
  int get priority => (attr2 >> 10) & 3;
  int get palette => (attr2 >> 12) & 15;
  bool get affine => attr0 & 0x100 != 0;
  bool get doubleSize => affine && attr0 & 0x200 != 0;
  bool get flipX => !affine && attr1 & 0x1000 != 0;
  bool get flipY => !affine && attr1 & 0x2000 != 0;
}

final class Gen5NcerCell {
  const Gen5NcerCell(this.attributes, this.objects);

  final int attributes;
  final List<Gen5NcerObject> objects;
}

List<Gen5NcerCell> decodeGen5Ncer(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  void requireRange(int offset, int size, int limit) {
    if (offset < 0 || size < 0 || offset > limit || size > limit - offset) {
      throw const FormatException('Truncated NCER');
    }
  }

  bool magic(int offset, String value) => value.codeUnits.asMap().entries.every(
    (e) => bytes[offset + e.key] == e.value,
  );

  requireRange(0, 16, bytes.length);
  if (!magic(0, 'RECN') ||
      data.getUint16(4, Endian.little) != 0xfeff ||
      data.getUint32(8, Endian.little) != bytes.length) {
    throw const FormatException('Invalid NCER header');
  }
  var section = data.getUint16(12, Endian.little);
  final sectionCount = data.getUint16(14, Endian.little);
  for (var i = 0; i < sectionCount; i++) {
    requireRange(section, 8, bytes.length);
    final length = data.getUint32(section + 4, Endian.little);
    if (length < 8) throw const FormatException('Invalid NCER section');
    requireRange(section, length, bytes.length);
    if (magic(section, 'KBEC')) {
      final end = section + length;
      requireRange(section, 32, end);
      final count = data.getUint16(section + 8, Endian.little);
      final bankType = data.getUint16(section + 10, Endian.little);
      if (count == 0 || count > 1024 || bankType != 0) {
        throw const FormatException('Unsupported NCER cell bank');
      }
      final table = section + 8 + data.getUint32(section + 12, Endian.little);
      requireRange(table, count * 8, end);
      final objectBase = table + count * 8;
      final cells = <Gen5NcerCell>[];
      for (var cell = 0; cell < count; cell++) {
        final entry = table + cell * 8;
        final objectCount = data.getUint16(entry, Endian.little);
        if (objectCount > 128)
          throw const FormatException('Too many NCER objects');
        final start = objectBase + data.getUint32(entry + 4, Endian.little);
        requireRange(start, objectCount * 6, end);
        final objects = <Gen5NcerObject>[];
        for (var j = 0; j < objectCount; j++) {
          final offset = start + j * 6;
          final object = Gen5NcerObject(
            data.getUint16(offset, Endian.little),
            data.getUint16(offset + 2, Endian.little),
            data.getUint16(offset + 4, Endian.little),
          );
          if (object.shape == 3)
            throw const FormatException('Invalid NCER object shape');
          objects.add(object);
        }
        cells.add(
          Gen5NcerCell(
            data.getUint16(entry + 2, Endian.little),
            List.unmodifiable(objects),
          ),
        );
      }
      return List.unmodifiable(cells);
    }
    section += length;
  }
  throw const FormatException('NCER cell section missing');
}
