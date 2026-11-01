import 'dart:typed_data';

import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/nmcr.dart';

void main() {
  Uint8List fixture() {
    final bytes = Uint8List(64);
    final data = ByteData.sublistView(bytes);
    bytes.setRange(0, 4, 'RCMN'.codeUnits);
    data.setUint16(4, 0xfeff, Endian.little);
    data.setUint16(6, 0x100, Endian.little);
    data.setUint32(8, bytes.length, Endian.little);
    data.setUint16(12, 16, Endian.little);
    data.setUint16(14, 1, Endian.little);
    bytes.setRange(16, 20, 'KBCM'.codeUnits);
    data.setUint32(20, 48, Endian.little);
    data.setUint16(24, 1, Endian.little);
    data.setUint32(28, 24, Endian.little);
    data.setUint16(48, 1, Endian.little);
    data.setUint16(50, 1, Endian.little);
    data.setUint16(56, 3, Endian.little);
    data.setInt16(58, -12, Endian.little);
    data.setInt16(60, 17, Endian.little);
    data.setUint16(62, 1, Endian.little);
    return bytes;
  }

  test('reads multi-cell animation references and signed offsets', () {
    final map = decodeGen5Nmcr(fixture()).single;
    expect(map.sharedAnimationCount, 1);
    final record = map.records.single;
    expect(
      [record.animationIndex, record.x, record.y, record.flags],
      [3, -12, 17, 1],
    );
    expect(record.sharedAnimationIndex, 0);
    expect(record.nodePlaybackMode, 1);
  });

  test('rejects truncated and out of bounds records', () {
    expect(
      () => decodeGen5Nmcr(Uint8List.sublistView(fixture(), 0, 63)),
      throwsFormatException,
    );
    final bytes = fixture();
    ByteData.sublistView(bytes).setUint32(52, 16, Endian.little);
    expect(() => decodeGen5Nmcr(bytes), throwsFormatException);
  });
}
