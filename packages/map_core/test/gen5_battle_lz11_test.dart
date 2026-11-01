import 'dart:typed_data';

import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/lz11.dart';

void main() {
  test('decodes literals and overlapping references', () {
    final bytes = Uint8List.fromList([
      0x11,
      0x0a,
      0,
      0,
      0x10,
      0x41,
      0x42,
      0x43,
      0x60,
      0x02,
    ]);
    expect(decodeGen5Lz11(bytes), 'ABCABCABCA'.codeUnits);
  });

  test('decodes both extended reference lengths and extended size', () {
    expect(
      decodeGen5Lz11(Uint8List.fromList([0x11, 18, 0, 0, 0x40, 0x41, 0, 0, 0])),
      List.filled(18, 0x41),
    );
    expect(
      decodeGen5Lz11(
        Uint8List.fromList([
          0x11,
          0,
          0,
          0,
          0x12,
          1,
          0,
          0,
          0x40,
          0x42,
          0x10,
          0,
          0,
          0,
        ]),
      ),
      List.filled(274, 0x42),
    );
  });

  test(
    'rejects truncated streams, invalid references and oversized output',
    () {
      expect(
        () => decodeGen5Lz11(Uint8List.fromList([0x11, 1, 0, 0])),
        throwsFormatException,
      );
      expect(
        () =>
            decodeGen5Lz11(Uint8List.fromList([0x11, 3, 0, 0, 0x80, 0x20, 0])),
        throwsFormatException,
      );
      expect(
        () => decodeGen5Lz11(
          Uint8List.fromList([0x11, 0, 0x10, 0]),
          maxOutputBytes: 100,
        ),
        throwsFormatException,
      );
    },
  );
}
