import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_background_converter.dart';
import 'package:test/test.dart';

Uint8List _tileMap() {
  final bytes = Uint8List(36 + 64 * 64 * 2);
  bytes.setRange(0, 4, ascii.encode('RCSN'));
  bytes.setRange(16, 20, ascii.encode('NRCS'));
  final data = ByteData.sublistView(bytes);
  data.setUint16(24, 512, Endian.little);
  data.setUint16(26, 512, Endian.little);
  data.setUint32(32, bytes.length - 36, Endian.little);
  void put(int x, int y, int entry) {
    final block = (y ~/ 32) * 2 + x ~/ 32;
    final index = block * 1024 + (y % 32) * 32 + x % 32;
    data.setUint16(36 + index * 2, entry, Endian.little);
  }

  put(0, 0, 0x8001);
  put(1, 0, 0x8401);
  put(2, 0, 0x8801);
  put(3, 0, 0x9001);
  put(32, 0, 0x8002);
  put(0, 32, 0x9002);
  put(32, 32, 0x8002);
  return bytes;
}

Uint8List _tiles() {
  final atlas = image.Image(width: 16, height: 16, withPalette: true);
  for (var i = 0; i < 16; i++) {
    atlas.palette!.setRgb(i, i, i, i);
  }
  atlas.setPixelIndex(8, 0, 1);
  atlas.setPixelIndex(15, 7, 2);
  for (var y = 8; y < 16; y++) {
    for (var x = 0; x < 8; x++) {
      atlas.setPixelIndex(x, y, 3);
    }
  }
  return image.encodePng(atlas);
}

String _palette() {
  final colors = List.filled(32, '0 0 0');
  colors[1] = '255 0 0';
  colors[2] = '0 255 0';
  colors[3] = '255 255 0';
  colors[17] = '0 0 255';
  colors[19] = '255 0 255';
  return 'JASC-PAL\n0100\n32\n${colors.join('\n')}\n';
}

void main() {
  test('decodes tiles, four screen blocks, flips and source palette banks', () {
    final png = Gen5BattleBackgroundConverter.convert(
      tileMap: _tileMap(),
      tilesPng: _tiles(),
      palette: _palette(),
    );
    final result = image.decodePng(png)!;
    expect((result.width, result.height), (512, 512));
    void pixel(int x, int y, int r, int g, int b, int a) {
      final value = result.getPixel(x, y);
      expect((value.r, value.g, value.b, value.a), (r, g, b, a),
          reason: 'pixel $x,$y');
    }

    pixel(0, 0, 255, 0, 0, 255);
    pixel(7, 7, 0, 255, 0, 255);
    pixel(15, 0, 255, 0, 0, 255);
    pixel(16, 7, 255, 0, 0, 255);
    pixel(24, 0, 0, 0, 255, 255);
    pixel(256, 0, 255, 255, 0, 255);
    pixel(0, 256, 255, 0, 255, 255);
    pixel(256, 256, 255, 255, 0, 255);
    pixel(40, 40, 0, 0, 0, 0);
  });

  test('rejects missing tiles, malformed palettes and truncated tile maps', () {
    final badMap = _tileMap();
    ByteData.sublistView(badMap).setUint16(36, 0x83ff, Endian.little);
    expect(
      () => Gen5BattleBackgroundConverter.convert(
          tileMap: badMap, tilesPng: _tiles(), palette: _palette()),
      throwsFormatException,
    );
    expect(
      () => Gen5BattleBackgroundConverter.convert(
          tileMap: _tileMap(), tilesPng: _tiles(), palette: 'bad'),
      throwsFormatException,
    );
    expect(
      () => Gen5BattleBackgroundConverter.convert(
          tileMap: Uint8List(20), tilesPng: _tiles(), palette: _palette()),
      throwsFormatException,
    );
    final oversizedAtlas = _tiles();
    ByteData.sublistView(oversizedAtlas).setUint32(16, 4096);
    expect(
      () => Gen5BattleBackgroundConverter.convert(
          tileMap: _tileMap(), tilesPng: oversizedAtlas, palette: _palette()),
      throwsFormatException,
    );
  });

  test('a missing palette bank is transparent only with explicit fallback', () {
    final tileMap = _tileMap();
    ByteData.sublistView(tileMap).setUint16(36, 0x0001, Endian.little);
    expect(
      () => Gen5BattleBackgroundConverter.convert(
        tileMap: tileMap,
        tilesPng: _tiles(),
        palette: _palette(),
      ),
      throwsFormatException,
    );
    final result = image.decodePng(Gen5BattleBackgroundConverter.convert(
      tileMap: tileMap,
      tilesPng: _tiles(),
      palette: _palette(),
      allowMissingPalette: true,
    ))!;
    expect(result.getPixel(0, 0).a, 0);
    expect(result.getPixel(15, 0).r, 255);
  });

  test('decodes the palette cycle into background frames and durations', () {
    final sequence = Uint8List(384);
    sequence.setRange(0, 3, [8, 9, 255]);
    final data = ByteData.sublistView(sequence);
    data.setUint16(128, 6, Endian.little);
    data.setUint16(130, 4, Endian.little);
    data.setUint16(132, 0xff98, Endian.little);
    final result = Gen5BattleBackgroundConverter.convertPaletteAnimation(
      tileMap: _tileMap(),
      tilesPng: _tiles(),
      basePalette: _palette(),
      animationSequence: sequence,
      animationPalette: _palette(),
    );
    expect(result.durations, [6, 4]);
    expect(result.frames, hasLength(2));
    final first = image.decodePng(result.frames[0])!;
    final second = image.decodePng(result.frames[1])!;
    expect((first.getPixel(0, 0).r, first.getPixel(0, 0).b), (255, 0));
    expect((second.getPixel(0, 0).r, second.getPixel(0, 0).b), (0, 255));
    expect((second.getPixel(24, 0).r, second.getPixel(24, 0).b), (0, 255));
    sequence[2] = 10;
    expect(
      () => Gen5BattleBackgroundConverter.convertPaletteAnimation(
        tileMap: _tileMap(),
        tilesPng: _tiles(),
        basePalette: _palette(),
        animationSequence: sequence.sublist(0, 130),
        animationPalette: _palette(),
      ),
      throwsFormatException,
    );
  });

  test('uses the base palette only when an animation bank is missing', () {
    final sequence = Uint8List(384);
    sequence.setRange(0, 3, [8, 10, 255]);
    final data = ByteData.sublistView(sequence);
    data.setUint16(128, 2, Endian.little);
    data.setUint16(130, 2, Endian.little);
    data.setUint16(132, 0xff98, Endian.little);
    expect(
      () => Gen5BattleBackgroundConverter.convertPaletteAnimation(
        tileMap: _tileMap(), tilesPng: _tiles(), basePalette: _palette(),
        animationSequence: sequence, animationPalette: _palette(),
      ),
      throwsFormatException,
    );
    final result = Gen5BattleBackgroundConverter.convertPaletteAnimation(
      tileMap: _tileMap(), tilesPng: _tiles(), basePalette: _palette(),
      animationSequence: sequence, animationPalette: _palette(),
      allowMissingAnimationPalette: true,
    );
    expect(result.frames, hasLength(2));
    final fallback = image.decodePng(result.frames.last)!;
    expect((fallback.getPixel(0, 0).r, fallback.getPixel(0, 0).b), (255, 0));
    sequence[1] = 7;
    expect(
      () => Gen5BattleBackgroundConverter.convertPaletteAnimation(
        tileMap: _tileMap(), tilesPng: _tiles(), basePalette: _palette(),
        animationSequence: sequence, animationPalette: _palette(),
        allowMissingAnimationPalette: true,
      ),
      throwsFormatException,
    );
  });

  test('preserves zero-length source palette frames', () {
    final sequence = Uint8List(384);
    sequence.setRange(0, 3, [8, 9, 255]);
    final data = ByteData.sublistView(sequence);
    data.setUint16(128, 4, Endian.little);
    data.setUint16(130, 0, Endian.little);
    data.setUint16(132, 0xff98, Endian.little);
    final result = Gen5BattleBackgroundConverter.convertPaletteAnimation(
      tileMap: _tileMap(), tilesPng: _tiles(), basePalette: _palette(),
      animationSequence: sequence, animationPalette: _palette(),
    );
    expect(result.durations, [4, 0]);
    expect(result.frames, hasLength(2));
  });

  test('accepts source palette frames lasting one tick', () {
    final sequence = Uint8List(384);
    sequence.setRange(0, 3, [8, 9, 255]);
    final data = ByteData.sublistView(sequence);
    data.setUint16(128, 1, Endian.little);
    data.setUint16(130, 2, Endian.little);
    data.setUint16(132, 0xff98, Endian.little);
    final result = Gen5BattleBackgroundConverter.convertPaletteAnimation(
      tileMap: _tileMap(),
      tilesPng: _tiles(),
      basePalette: _palette(),
      animationSequence: sequence,
      animationPalette: _palette(),
    );
    expect(result.durations, [1, 2]);
    expect(result.frames, hasLength(2));
  });

  test('decodes the pinned Hydro Pump, Psychic and Fire Blast backgrounds',
      () async {
    const root = 'https://raw.githubusercontent.com/fuddlesworth/pokebw2/'
        '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c/'
        'res/graphics/btlv_effvm_bg';
    const sources = {
      18: [
        '77620d53359798d5c37fe03cd5c3f3cee39d821282860b0dfe2fedb832534671',
        '1847939d42404d84ab48ab3e9f17d8f2ab22cb90e9336dd5e842a27c43d73351',
        '36628e1b031ed1795ae4274034477b3871a683b66d1a1e9dcfb4709815533bc9',
      ],
      48: [
        '518d4515f01748fd7968d9e7009c3dcff7e77bd5f5001a3df25d0824788ae636',
        'ad7c8f800ef8aa757ab467a025d0dcce2d27b9c04b437f0a31b32411774c3a36',
        '14cb00278fea00378dd1050ea8200e73a618af55e9854e794f9b5131e7bf6940',
      ],
      60: [
        '4f04be98a800bd77708f9d61e053b40cc359d687c9098b892bda5e9fe2da98f2',
        '070b1bf1dcf97e76a9377389b18fcb7fa3c0ef6d886e44a55b17d4a7b84baeb7',
        'a1f8cf530ba37f97b67cb67d63cc13492f2fd42169ac5964e63118e4e6a8d9e8',
      ],
    };
    final client = HttpClient();
    try {
      for (final entry in sources.entries) {
        final files = <Uint8List>[];
        for (var i = 0; i < 3; i++) {
          final number = (entry.key + i).toString().padLeft(3, '0');
          final extension = ['nscr', 'png', 'pal'][i];
          final request =
              await client.getUrl(Uri.parse('$root/$number.$extension'));
          final response = await request.close();
          expect(response.statusCode, 200);
          final bytes =
              Uint8List.fromList(await response.expand((x) => x).toList());
          expect(sha256.convert(bytes).toString(), entry.value[i]);
          files.add(bytes);
        }
        final png = Gen5BattleBackgroundConverter.convert(
            tileMap: files[0],
            tilesPng: files[1],
            palette: ascii.decode(files[2]));
        final result = image.decodePng(png)!;
        expect((result.width, result.height), (512, 512));
        expect(result.any((pixel) => pixel.a > 0), isTrue);
        if (Platform.environment['GEN5_BACKGROUND_EMIT'] == '${entry.key}') {
          stdout.writeln('BACKGROUND_PNG:${base64Encode(png)}');
        }
      }
    } finally {
      client.close(force: true);
    }
  }, skip: Platform.environment['GEN5_BACKGROUND_SOURCE_TEST'] != '1');
}
