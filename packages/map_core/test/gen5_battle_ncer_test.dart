import 'dart:typed_data';

import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/ncer.dart';

void main() {
  Uint8List fixture() {
    final bytes = Uint8List(62);
    final data = ByteData.sublistView(bytes);
    bytes.setRange(0, 4, 'RECN'.codeUnits);
    data.setUint16(4, 0xfeff, Endian.little);
    data.setUint16(6, 0x100, Endian.little);
    data.setUint32(8, bytes.length, Endian.little);
    data.setUint16(12, 16, Endian.little);
    data.setUint16(14, 1, Endian.little);
    bytes.setRange(16, 20, 'KBEC'.codeUnits);
    data.setUint32(20, 46, Endian.little);
    data.setUint16(24, 1, Endian.little);
    data.setUint32(28, 24, Endian.little);
    data.setUint16(48, 1, Endian.little);
    data.setUint16(50, 7, Endian.little);
    data.setUint16(56, 0x40fe, Endian.little);
    data.setUint16(58, 0x51fd, Endian.little);
    data.setUint16(60, 0xa42a, Endian.little);
    return bytes;
  }

  test('reads cell attributes and signed object coordinates', () {
    final cells = decodeGen5Ncer(fixture());
    expect(cells, hasLength(1));
    expect(cells.single.attributes, 7);
    final object = cells.single.objects.single;
    expect([object.x, object.y, object.width, object.height], [-3, -2, 32, 8]);
    expect([object.tileIndex, object.priority, object.palette], [42, 1, 10]);
    expect(object.flipX, isTrue);
    expect(object.flipY, isFalse);
  });

  test('rejects truncated sections and unsupported cell banks', () {
    expect(
      () => decodeGen5Ncer(Uint8List.sublistView(fixture(), 0, 61)),
      throwsFormatException,
    );
    final bytes = fixture();
    ByteData.sublistView(bytes).setUint16(26, 1, Endian.little);
    expect(() => decodeGen5Ncer(bytes), throwsFormatException);
  });
}
