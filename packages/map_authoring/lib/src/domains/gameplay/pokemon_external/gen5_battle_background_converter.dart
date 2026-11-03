import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as image;

abstract final class Gen5BattleBackgroundConverter {
  static Uint8List convert({
    required Uint8List tileMap,
    required Uint8List tilesPng,
    required String palette,
    bool allowMissingPalette = false,
  }) {
    if (tileMap.length < 36 ||
        ascii.decode(tileMap.sublist(0, 4), allowInvalid: true) != 'RCSN' ||
        ascii.decode(tileMap.sublist(16, 20), allowInvalid: true) != 'NRCS') {
      throw const FormatException('Invalid background tile map');
    }
    final data = ByteData.sublistView(tileMap);
    final width = data.getUint16(24, Endian.little);
    final height = data.getUint16(26, Endian.little);
    final length = data.getUint32(32, Endian.little);
    if (!{256, 512}.contains(width) ||
        !{256, 512}.contains(height) ||
        length != width * height ~/ 32 ||
        tileMap.length != 36 + length) {
      throw const FormatException('Unsupported background tile map size');
    }
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (tilesPng.length < 33 ||
        !List.generate(8, (i) => tilesPng[i] == signature[i]).every((x) => x)) {
      throw const FormatException('Invalid background tile atlas');
    }
    final pngHeader = ByteData.sublistView(tilesPng);
    if (pngHeader.getUint32(8) != 13 ||
        ascii.decode(tilesPng.sublist(12, 16), allowInvalid: true) != 'IHDR' ||
        pngHeader.getUint32(16) == 0 ||
        pngHeader.getUint32(16) > 1024 ||
        pngHeader.getUint32(20) == 0 ||
        pngHeader.getUint32(20) > 1024 ||
        tilesPng[25] != 3) {
      throw const FormatException('Invalid background tile atlas dimensions');
    }
    final source = image.decodePng(tilesPng);
    if (source == null ||
        !source.hasPalette ||
        source.width == 0 ||
        source.height == 0 ||
        source.width > 1024 ||
        source.height > 1024 ||
        source.width % 8 != 0 ||
        source.height % 8 != 0) {
      throw const FormatException('Invalid background tile atlas');
    }
    final colors = _paletteColors(palette);
    final result = image.Image(width: width, height: height, numChannels: 4);
    final sourceColumns = source.width ~/ 8;
    final sourceTiles = sourceColumns * (source.height ~/ 8);
    final columns = width ~/ 8;
    final rows = height ~/ 8;
    final blocksPerRow = columns ~/ 32;
    for (var tileY = 0; tileY < rows; tileY++) {
      for (var tileX = 0; tileX < columns; tileX++) {
        final block = (tileY ~/ 32) * blocksPerRow + tileX ~/ 32;
        final index = block * 1024 + (tileY % 32) * 32 + tileX % 32;
        final entry = data.getUint16(36 + index * 2, Endian.little);
        final tile = entry & 0x3ff;
        if (tile >= sourceTiles) {
          throw const FormatException('Background tile is missing');
        }
        final flipX = (entry & 0x400) != 0;
        final flipY = (entry & 0x800) != 0;
        final bank = entry >> 12;
        for (var y = 0; y < 8; y++) {
          for (var x = 0; x < 8; x++) {
            final pixel = source.getPixelIndex(
              (tile % sourceColumns) * 8 + (flipX ? 7 - x : x),
              (tile ~/ sourceColumns) * 8 + (flipY ? 7 - y : y),
            );
            if (pixel == 0) continue;
            final colorIndex = (bank - 8) * 16 + pixel;
            if (pixel > 15) {
              throw const FormatException('Invalid background palette index');
            }
            if (colorIndex < 0 || colorIndex >= colors.length) {
              if (allowMissingPalette) continue;
              throw const FormatException(
                  'Background palette entry is missing');
            }
            final (r, g, b) = colors[colorIndex];
            result.setPixelRgba(tileX * 8 + x, tileY * 8 + y, r, g, b, 255);
          }
        }
      }
    }
    return image.encodePng(result);
  }

  static ({List<Uint8List> frames, List<int> durations}) convertPaletteAnimation({
    required Uint8List tileMap,
    required Uint8List tilesPng,
    required String basePalette,
    required Uint8List animationSequence,
    required String animationPalette,
    bool allowMissingPalette = false,
    bool allowMissingAnimationPalette = false,
  }) {
    if (animationSequence.length != 384) {
      throw const FormatException('Invalid background palette animation');
    }
    final end = animationSequence.indexOf(255);
    if (end < 1 || end > 32 || end >= 128) {
      throw const FormatException('Invalid background palette sequence');
    }
    final durations = <int>[];
    final data = ByteData.sublistView(animationSequence);
    var terminated = false;
    for (var offset = 128; offset + 1 < animationSequence.length; offset += 2) {
      final value = data.getUint16(offset, Endian.little);
      if (value == 0xff98) {
        terminated = true;
        break;
      }
      if (value > 255 || durations.length >= 32) {
        throw const FormatException('Invalid background palette duration');
      }
      durations.add(value);
    }
    if (!terminated || durations.length != end) {
      throw const FormatException('Mismatched background palette durations');
    }
    final base = _paletteColors(basePalette);
    final animated = _paletteColors(animationPalette);
    if (base.length < 16) {
      throw const FormatException('Background palette has no complete bank');
    }
    final frames = <Uint8List>[];
    for (final index in animationSequence.take(end)) {
      final offset = (index - 8) * 16;
      if (offset < 0 ||
          (offset + 16 > animated.length && !allowMissingAnimationPalette)) {
        throw const FormatException('Background animation palette bank is missing');
      }
      final colors = [
        if (offset + 16 > animated.length) ...base.take(16)
        else ...animated.getRange(offset, offset + 16),
        ...base.skip(16),
      ];
      final rows = colors.map((color) => '${color.$1} ${color.$2} ${color.$3}');
      frames.add(convert(
        tileMap: tileMap,
        tilesPng: tilesPng,
        palette: 'JASC-PAL\n0100\n${colors.length}\n${rows.join('\n')}\n',
        allowMissingPalette: allowMissingPalette,
      ));
    }
    return (frames: frames, durations: durations);
  }

  static List<(int, int, int)> _paletteColors(String palette) {
    final lines = const LineSplitter().convert(palette);
    if (lines.length < 4 || lines[0] != 'JASC-PAL' || lines[1] != '0100') {
      throw const FormatException('Invalid background palette');
    }
    final count = int.tryParse(lines[2].trim());
    if (count == null ||
        count < 1 ||
        count > 128 ||
        lines.length != count + 3) {
      throw const FormatException('Invalid background palette size');
    }
    final colors = <(int, int, int)>[];
    for (final line in lines.skip(3)) {
      final parts = line.trim().split(RegExp(r'\s+'));
      final values = parts.map(int.tryParse).toList();
      if (values.length != 3 ||
          values.any((v) => v == null || v < 0 || v > 255)) {
        throw const FormatException('Invalid background palette color');
      }
      colors.add((values[0]!, values[1]!, values[2]!));
    }
    return colors;
  }
}
