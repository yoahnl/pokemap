import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Emits the exact STORE-only ZIP profile used by `.pokemapgame` format v1.
abstract final class DeterministicZipEncoder {
  static Uint8List encode(List<MapEntry<String, List<int>>> entries) {
    final local = BytesBuilder(copy: false);
    final central = BytesBuilder(copy: false);
    var localOffset = 0;
    for (final entry in entries) {
      final name = utf8.encode(entry.key);
      final data = entry.value;
      final crc32 = getCrc32(data);

      final localHeader = ByteData(30)
        ..setUint32(0, 0x04034b50, Endian.little)
        ..setUint16(4, 20, Endian.little)
        ..setUint16(6, 0x0800, Endian.little)
        ..setUint16(8, 0, Endian.little)
        ..setUint16(10, 0, Endian.little)
        ..setUint16(12, 33, Endian.little)
        ..setUint32(14, crc32, Endian.little)
        ..setUint32(18, data.length, Endian.little)
        ..setUint32(22, data.length, Endian.little)
        ..setUint16(26, name.length, Endian.little)
        ..setUint16(28, 0, Endian.little);
      local
        ..add(localHeader.buffer.asUint8List())
        ..add(name)
        ..add(data);

      final centralHeader = ByteData(46)
        ..setUint32(0, 0x02014b50, Endian.little)
        ..setUint16(4, 0x0314, Endian.little)
        ..setUint16(6, 20, Endian.little)
        ..setUint16(8, 0x0800, Endian.little)
        ..setUint16(10, 0, Endian.little)
        ..setUint16(12, 0, Endian.little)
        ..setUint16(14, 33, Endian.little)
        ..setUint32(16, crc32, Endian.little)
        ..setUint32(20, data.length, Endian.little)
        ..setUint32(24, data.length, Endian.little)
        ..setUint16(28, name.length, Endian.little)
        ..setUint16(30, 0, Endian.little)
        ..setUint16(32, 0, Endian.little)
        ..setUint16(34, 0, Endian.little)
        ..setUint16(36, 0, Endian.little)
        ..setUint32(38, 0x81a40000, Endian.little)
        ..setUint32(42, localOffset, Endian.little);
      central
        ..add(centralHeader.buffer.asUint8List())
        ..add(name);
      localOffset += 30 + name.length + data.length;
    }

    final centralBytes = central.takeBytes();
    final footer = ByteData(22)
      ..setUint32(0, 0x06054b50, Endian.little)
      ..setUint16(4, 0, Endian.little)
      ..setUint16(6, 0, Endian.little)
      ..setUint16(8, entries.length, Endian.little)
      ..setUint16(10, entries.length, Endian.little)
      ..setUint32(12, centralBytes.length, Endian.little)
      ..setUint32(16, localOffset, Endian.little)
      ..setUint16(20, 0, Endian.little);
    return (local
          ..add(centralBytes)
          ..add(footer.buffer.asUint8List()))
        .takeBytes();
  }
}
