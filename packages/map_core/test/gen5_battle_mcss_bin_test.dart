import 'dart:typed_data';

import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/mcss_bin.dart';

void main() {
  Uint8List fixture() {
    final bytes = Uint8List(64);
    final data = ByteData.sublistView(bytes);
    data.setUint32(0, 1, Endian.little);
    data.setUint16(4, 41, Endian.little);
    data.setUint16(6, 37, Endian.little);
    data.setInt16(8, -3, Endian.little);
    data.setInt16(10, 2, Endian.little);
    for (var i = 0; i < 12; i++) {
      data.setInt32(12 + i * 4, (i - 2) * 4096, Endian.little);
    }
    bytes.setRange(60, 64, [2, 7, 3, 5]);
    return bytes;
  }

  test('preserves dimensions, signed offsets, both quads and idle tail', () {
    final bin = decodeGen5McssBin(fixture());
    expect([bin.width, bin.height, bin.offsetX, bin.offsetY], [41, 37, -3, 2]);
    expect(bin.cells, hasLength(1));
    expect(bin.cells.single.primary.x, -8192);
    expect(bin.cells.single.primary.textureY, 12288);
    expect(bin.cells.single.secondary.width, 24576);
    expect(bin.cells.single.secondary.textureY, 36864);
    expect(bin.tail, [2, 7, 3, 5]);
    expect(bin.idleNodeIndices, [3, 5]);
  });

  test('rejects truncated cells and truncated idle node lists', () {
    expect(
      () => decodeGen5McssBin(Uint8List.sublistView(fixture(), 0, 59)),
      throwsFormatException,
    );
    final bytes = fixture()..[60] = 3;
    expect(() => decodeGen5McssBin(bytes), throwsFormatException);
  });

  test('keeps sentinel tail without interpreting it as a count', () {
    final bytes = fixture()..[60] = 255;
    expect(decodeGen5McssBin(bytes).idleNodeIndices, isEmpty);
  });
}
