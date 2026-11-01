import 'dart:typed_data';

Uint8List decodeGen5Lz11(Uint8List input, {int maxOutputBytes = 1048576}) {
  var position = 0;
  int readByte() {
    if (position >= input.length) {
      throw const FormatException('Truncated LZ11 stream');
    }
    return input[position++];
  }

  if (readByte() != 0x11) {
    throw const FormatException('Invalid LZ11 signature');
  }
  var outputLength = readByte() | readByte() << 8 | readByte() << 16;
  if (outputLength == 0) {
    outputLength =
        readByte() | readByte() << 8 | readByte() << 16 | readByte() << 24;
  }
  if (outputLength <= 0 || outputLength > maxOutputBytes) {
    throw const FormatException('Invalid LZ11 output length');
  }
  final output = Uint8List(outputLength);
  var written = 0;
  while (written < outputLength) {
    final flags = readByte();
    for (var bit = 7; bit >= 0 && written < outputLength; bit--) {
      if (flags & (1 << bit) == 0) {
        output[written++] = readByte();
        continue;
      }
      final first = readByte();
      final marker = first >> 4;
      late int length;
      late int distance;
      if (marker == 0) {
        final second = readByte();
        final third = readByte();
        length = ((first & 15) << 4 | second >> 4) + 17;
        distance = ((second & 15) << 8 | third) + 1;
      } else if (marker == 1) {
        final second = readByte();
        final third = readByte();
        final fourth = readByte();
        length = ((first & 15) << 12 | second << 4 | third >> 4) + 273;
        distance = ((third & 15) << 8 | fourth) + 1;
      } else {
        final second = readByte();
        length = marker + 1;
        distance = ((first & 15) << 8 | second) + 1;
      }
      if (distance > written) {
        throw const FormatException('Invalid LZ11 back-reference');
      }
      for (var i = 0; i < length && written < outputLength; i++) {
        output[written] = output[written - distance];
        written++;
      }
    }
  }
  return output;
}
