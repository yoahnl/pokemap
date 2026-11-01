import 'dart:typed_data';

final class Gen5NmcrRecord {
  const Gen5NmcrRecord(this.animationIndex, this.x, this.y, this.flags);

  final int animationIndex, x, y, flags;

  int get sharedAnimationIndex => (flags >> 8) & 0xff;
  int get nodePlaybackMode => flags & 0xf;
}

final class Gen5NmcrMap {
  const Gen5NmcrMap(this.sharedAnimationCount, this.records);

  final int sharedAnimationCount;
  final List<Gen5NmcrRecord> records;
}

List<Gen5NmcrMap> decodeGen5Nmcr(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  void range(int offset, int length, int end) {
    if (offset < 0 || length < 0 || offset > end || length > end - offset) {
      throw const FormatException('Truncated NMCR');
    }
  }

  bool magic(int offset, String value) => value.codeUnits.asMap().entries.every(
    (e) => bytes[offset + e.key] == e.value,
  );
  int u16(int at) => data.getUint16(at, Endian.little);
  int u32(int at) => data.getUint32(at, Endian.little);
  int i16(int at) => data.getInt16(at, Endian.little);

  range(0, 16, bytes.length);
  if (!magic(0, 'RCMN') || u16(4) != 0xfeff || u32(8) != bytes.length) {
    throw const FormatException('Invalid NMCR header');
  }
  var section = u16(12);
  for (var i = 0; i < u16(14); i++) {
    range(section, 8, bytes.length);
    final length = u32(section + 4);
    if (length < 8) throw const FormatException('Invalid NMCR section');
    range(section, length, bytes.length);
    if (!magic(section, 'KBCM')) {
      section += length;
      continue;
    }
    final end = section + length;
    range(section, 24, end);
    final count = u16(section + 8);
    if (count == 0 || count > 2048) {
      throw const FormatException('Invalid NMCR map count');
    }
    final table = section + 8 + u32(section + 12);
    range(table, count * 8, end);
    final recordBase = table + count * 8;
    final maps = <Gen5NmcrMap>[];
    var total = 0;
    for (var map = 0; map < count; map++) {
      final entry = table + map * 8;
      final recordCount = u16(entry);
      total += recordCount;
      if (recordCount > 4096 || total > 65536) {
        throw const FormatException('Too many NMCR records');
      }
      final start = recordBase + u32(entry + 4);
      range(start, recordCount * 8, end);
      final records = <Gen5NmcrRecord>[];
      for (var record = 0; record < recordCount; record++) {
        final at = start + record * 8;
        records.add(
          Gen5NmcrRecord(u16(at), i16(at + 2), i16(at + 4), u16(at + 6)),
        );
      }
      maps.add(Gen5NmcrMap(u16(entry + 2), List.unmodifiable(records)));
    }
    return List.unmodifiable(maps);
  }
  throw const FormatException('NMCR map section missing');
}
