import 'dart:typed_data';

final class PokemonGifInfo {
  const PokemonGifInfo(this.width, this.height, this.frameCount);
  final int width;
  final int height;
  final int frameCount;
}

final class PokemonGifInspector {
  const PokemonGifInspector(
      {this.maxFrames = 500, this.maxCanvasPixels = 32000000});
  final int maxFrames;
  final int maxCanvasPixels;

  PokemonGifInfo inspect(Uint8List bytes) {
    if (maxFrames < 1 || maxCanvasPixels < 1) {
      throw ArgumentError('GIF limits must be positive.');
    }
    Never invalid() => throw const FormatException('Invalid GIF animation.');
    bool ascii(int offset, String value) {
      if (offset + value.length > bytes.length) return false;
      for (var i = 0; i < value.length; i++) {
        if (bytes[offset + i] != value.codeUnitAt(i)) return false;
      }
      return true;
    }

    int word(int offset) => bytes[offset] | (bytes[offset + 1] << 8);
    if (bytes.length < 14 || !(ascii(0, 'GIF87a') || ascii(0, 'GIF89a'))) {
      invalid();
    }
    final width = word(6);
    final height = word(8);
    if (width == 0 ||
        height == 0 ||
        width > 2048 ||
        height > 2048 ||
        width * height > maxCanvasPixels ||
        width * height > 32000000) {
      invalid();
    }
    final global = bytes[10];
    final hasGlobal = (global & 0x80) != 0;
    var offset = 13;
    if (hasGlobal) offset += 3 * (1 << ((global & 7) + 1));
    if (offset > bytes.length) invalid();
    var frames = 0;

    void skipSubBlocks({required bool nonempty}) {
      var found = false;
      while (true) {
        if (offset >= bytes.length) invalid();
        final size = bytes[offset++];
        if (size == 0) {
          if (nonempty && !found) invalid();
          return;
        }
        if (offset + size > bytes.length) invalid();
        found = true;
        offset += size;
      }
    }

    while (offset < bytes.length) {
      final marker = bytes[offset++];
      if (marker == 0x3b) {
        if (frames == 0 || bytes.length - offset > 4096) invalid();
        while (offset < bytes.length) {
          if (bytes[offset++] != 0) invalid();
        }
        return PokemonGifInfo(width, height, frames);
      }
      if (marker == 0x21) {
        if (offset >= bytes.length) invalid();
        final label = bytes[offset++];
        if (label == 0xf9) {
          if (offset + 6 > bytes.length ||
              bytes[offset] != 4 ||
              bytes[offset + 5] != 0) {
            invalid();
          }
          offset += 6;
        } else {
          skipSubBlocks(nonempty: false);
        }
        continue;
      }
      if (marker != 0x2c || offset + 9 > bytes.length) invalid();
      final left = word(offset);
      final top = word(offset + 2);
      final frameWidth = word(offset + 4);
      final frameHeight = word(offset + 6);
      final packed = bytes[offset + 8];
      offset += 9;
      if (frameWidth == 0 ||
          frameHeight == 0 ||
          left + frameWidth > width ||
          top + frameHeight > height) {
        invalid();
      }
      if ((packed & 0x80) != 0) {
        offset += 3 * (1 << ((packed & 7) + 1));
      } else if (!hasGlobal) {
        invalid();
      }
      if (offset >= bytes.length || bytes[offset] < 2 || bytes[offset] > 8) {
        invalid();
      }
      offset++;
      skipSubBlocks(nonempty: true);
      frames++;
      if (frames > maxFrames ||
          frames > 500 ||
          width * height * frames > maxCanvasPixels ||
          width * height * frames > 32000000) {
        invalid();
      }
    }
    invalid();
  }
}
