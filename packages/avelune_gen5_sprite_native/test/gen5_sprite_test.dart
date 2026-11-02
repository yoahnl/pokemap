import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_gen5_sprite_native/avelune_gen5_sprite_native.dart';
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

int pngCrc(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var i = 0; i < 8; i++) {
      crc = (crc >> 1) ^ ((crc & 1) == 0 ? 0 : 0xedb88320);
    }
  }
  return crc ^ 0xffffffff;
}

Uint8List atlasWithOversizedDeflate() {
  final original = image.encodePng(
    image.Image(width: 256, height: 128, withPalette: true),
  );
  final replacement = ZLibEncoder().convert(Uint8List(2 * 1024 * 1024));
  final output = BytesBuilder()..add(original.sublist(0, 8));
  var inserted = false;
  for (var offset = 8; offset < original.length;) {
    final size = ByteData.sublistView(original, offset, offset + 4)
        .getUint32(0, Endian.big);
    final type = ascii.decode(original.sublist(offset + 4, offset + 8));
    if (type == 'IDAT') {
      if (!inserted) {
        final chunk = Uint8List(12 + replacement.length);
        final header = ByteData.sublistView(chunk);
        header.setUint32(0, replacement.length, Endian.big);
        chunk.setRange(4, 8, ascii.encode('IDAT'));
        chunk.setRange(8, 8 + replacement.length, replacement);
        header.setUint32(8 + replacement.length, pngCrc(chunk.sublist(4, 8 + replacement.length)), Endian.big);
        output.add(chunk);
        inserted = true;
      }
    } else {
      output.add(original.sublist(offset, offset + 12 + size));
    }
    offset += 12 + size;
  }
  return output.takeBytes();
}

void main() {
  test('rejects missing and wrongly sized sprite atlases', () {
    expect(
      () => Gen5NativeSprite(assets: {}, side: Gen5SpriteSide.back),
      throwsFormatException,
    );
    final wrongSize = image.encodePng(image.Image(width: 8, height: 8));
    expect(
      () => Gen5NativeSprite(
        assets: {'back.png': wrongSize},
        side: Gen5SpriteSide.back,
      ),
      throwsFormatException,
    );
  });

  test('rejects non-five-bit palettes when normalization is requested', () {
    final atlas = image.encodePng(
      image.Image(width: 256, height: 128, withPalette: true),
    );
    final palette = Uint8List.fromList(
      ascii.encode(
        'JASC-PAL\n0100\n16\n${List.filled(16, '1 0 0').join('\n')}\n',
      ),
    );
    expect(
      () => Gen5NativeSprite(
        assets: {'back.png': atlas, 'normal.pal': palette},
        side: Gen5SpriteSide.back,
        normalizeFiveBitPalette: true,
      ),
      throwsFormatException,
    );
  });

  test('rejects an indexed atlas with excessive decompressed data', () {
    expect(
      () => Gen5NativeSprite(
        assets: {'back.png': atlasWithOversizedDeflate()},
        side: Gen5SpriteSide.back,
      ),
      throwsA(isA<FormatException>().having(
        (error) => error.message,
        'message',
        contains('atlas decompression limit'),
      )),
    );
  });

  test(
    'rejects malformed compressed animation after allocating native memory',
    () {
      final atlas = image.encodePng(
        image.Image(width: 256, height: 128, withPalette: true),
      );
      final palette = Uint8List.fromList(
        ascii.encode(
          'JASC-PAL\n0100\n16\n${List.filled(16, '0 0 0').join('\n')}\n',
        ),
      );
      expect(
        () => Gen5NativeSprite(
          assets: {
            'back.png': atlas,
            'normal.pal': palette,
            'back_animations.nanr.lz11': Uint8List.fromList([0x11, 1, 0, 0]),
          },
          side: Gen5SpriteSide.back,
        ),
        throwsFormatException,
      );
    },
  );
}
