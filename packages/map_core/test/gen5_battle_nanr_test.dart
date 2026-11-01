import 'dart:typed_data';

import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/nanr.dart';

void main() {
  Uint8List fixture() {
    final bytes = Uint8List(96);
    final data = ByteData.sublistView(bytes);
    bytes.setRange(0, 4, 'RNAN'.codeUnits);
    data.setUint16(4, 0xfeff, Endian.little);
    data.setUint16(6, 0x100, Endian.little);
    data.setUint32(8, bytes.length, Endian.little);
    data.setUint16(12, 16, Endian.little);
    data.setUint16(14, 1, Endian.little);
    bytes.setRange(16, 20, 'KNBA'.codeUnits);
    data.setUint32(20, 80, Endian.little);
    data.setUint16(24, 1, Endian.little);
    data.setUint16(26, 1, Endian.little);
    data.setUint32(28, 24, Endian.little);
    data.setUint32(32, 40, Endian.little);
    data.setUint32(36, 48, Endian.little);
    data.setUint16(48, 1, Endian.little);
    data.setUint16(52, 1, Endian.little);
    data.setUint32(56, 2, Endian.little);
    data.setUint16(68, 9, Endian.little);
    data.setUint16(70, 3, Endian.little);
    data.setUint16(72, 4, Endian.little);
    data.setInt16(74, -12, Endian.little);
    data.setInt32(76, 4096, Endian.little);
    data.setInt32(80, 8192, Endian.little);
    data.setInt16(84, -3, Endian.little);
    data.setInt16(86, 5, Endian.little);
    return bytes;
  }

  test('reads frame timing and affine transform', () {
    final sequence = decodeGen5Nanr(fixture()).single;
    expect(sequence.playbackType, 2);
    final frame = sequence.frames.single;
    expect([frame.targetIndex, frame.duration, frame.marker], [4, 9, 3]);
    expect([frame.rotation, frame.scaleX, frame.scaleY], [-12, 4096, 8192]);
    expect([frame.translateX, frame.translateY], [-3, 5]);
  });

  test('rejects truncated and out of bounds data', () {
    expect(
      () => decodeGen5Nanr(Uint8List.sublistView(fixture(), 0, 90)),
      throwsFormatException,
    );
    final bytes = fixture();
    ByteData.sublistView(bytes).setUint32(64, 200, Endian.little);
    expect(() => decodeGen5Nanr(bytes), throwsFormatException);
  });

  test('rejects an element that overlaps the next element', () {
    final bytes = Uint8List(112)..setRange(0, 64, fixture());
    final data = ByteData.sublistView(bytes);
    data.setUint32(8, bytes.length, Endian.little);
    data.setUint32(20, 96, Endian.little);
    data.setUint32(36, 56, Endian.little);
    data.setUint16(48, 2, Endian.little);
    data.setUint32(72, 4, Endian.little);
    expect(() => decodeGen5Nanr(bytes), throwsFormatException);
  });

  test('reads NMAR timeline map indices without accepting it as NANR', () {
    final bytes = fixture()..setRange(0, 4, 'RAMN'.codeUnits);
    expect(decodeGen5Nmar(bytes).single.frames.single.targetIndex, 4);
    expect(() => decodeGen5Nanr(bytes), throwsFormatException);
  });
}
