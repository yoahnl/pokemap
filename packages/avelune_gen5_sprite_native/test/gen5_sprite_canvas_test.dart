import 'dart:convert';
import 'dart:typed_data';

import 'package:avelune_gen5_sprite_native/avelune_gen5_sprite_native.dart';
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import 'native_admission_test.dart' as fixture;

Uint8List compressed(Uint8List data) {
  final result = BytesBuilder()
    ..add([0x11, data.length & 255, data.length >> 8, 0]);
  for (var i = 0; i < data.length; i += 8) {
    result.addByte(0);
    result.add(data.sublist(i, (i + 8).clamp(0, data.length)));
  }
  return result.takeBytes();
}

void main() {
  test('renders body parts beyond the original 128 pixel canvas', () {
    final palette = image.PaletteUint8(16, 4)
      ..setRgba(0, 0, 0, 0, 0)
      ..setRgba(1, 255, 255, 255, 255);
    final atlas = image.Image(
      width: 256,
      height: 128,
      withPalette: true,
      palette: palette,
    );
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        atlas.setPixelIndex(x, y, 1);
      }
    }
    final info = fixture.rectangles();
    ByteData.sublistView(info)
      ..setInt32(36, 70 * 256, Endian.little)
      ..setInt32(44, 8 * 4096, Endian.little)
      ..setInt32(48, 8 * 4096, Endian.little);
    final sprite = Gen5NativeSprite(
      side: Gen5SpriteSide.front,
      assets: {
        'front.png': image.encodePng(atlas),
        'front_animations.nanr.lz11': compressed(fixture.animations('RNAN')),
        'front_cells.ncer': fixture.cells(),
        'front_multi_cells.nmcr': fixture.maps(),
        'front_multi_animations.nmar': fixture.animations('RAMN'),
        'front_info.bin': info,
        'normal.pal': Uint8List.fromList(
          ascii.encode(
            'JASC-PAL\n0100\n16\n0 0 0\n255 255 255\n${List.filled(14, '0 0 0').join('\n')}\n',
          ),
        ),
      },
    );
    addTearDown(sprite.dispose);
    final pixels = sprite.renderIndexed(0);
    expect(pixels.length, 256 * 256);
    expect(pixels[128 * 256 + 128], 1);
    expect(pixels[128 * 256 + 198], 1);
  });
}
