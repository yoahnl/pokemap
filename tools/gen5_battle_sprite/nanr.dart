import 'dart:typed_data';

final class Gen5NitroFrame {
  const Gen5NitroFrame({
    required this.targetIndex,
    required this.duration,
    required this.marker,
    required this.transformType,
    required this.rotation,
    required this.scaleX,
    required this.scaleY,
    required this.translateX,
    required this.translateY,
  });

  final int targetIndex, duration, marker, transformType, rotation;
  final int scaleX, scaleY, translateX, translateY;
}

final class Gen5NitroSequence {
  const Gen5NitroSequence({
    required this.loopStart,
    required this.playbackType,
    required this.format,
    required this.frames,
    this.isMultiCellTimeline = false,
  });

  final int loopStart, playbackType, format;
  final List<Gen5NitroFrame> frames;
  final bool isMultiCellTimeline;
}

List<Gen5NitroSequence> decodeGen5Nanr(Uint8List bytes) =>
    _decodeAnimationBank(bytes, 'RNAN');

List<Gen5NitroSequence> decodeGen5Nmar(Uint8List bytes) =>
    _decodeAnimationBank(bytes, 'RAMN');

List<Gen5NitroSequence> _decodeAnimationBank(
  Uint8List bytes,
  String signature,
) {
  final data = ByteData.sublistView(bytes);
  void range(int offset, int length, int end) {
    if (offset < 0 || length < 0 || offset > end || length > end - offset) {
      throw const FormatException('Truncated NANR');
    }
  }

  bool magic(int offset, String value) => value.codeUnits.asMap().entries.every(
    (e) => bytes[offset + e.key] == e.value,
  );
  int u16(int at) => data.getUint16(at, Endian.little);
  int u32(int at) => data.getUint32(at, Endian.little);

  range(0, 16, bytes.length);
  if (!magic(0, signature) || u16(4) != 0xfeff || u32(8) != bytes.length) {
    throw const FormatException('Invalid NANR header');
  }
  var section = u16(12);
  for (var i = 0; i < u16(14); i++) {
    range(section, 8, bytes.length);
    final length = u32(section + 4);
    if (length < 8) throw const FormatException('Invalid NANR section');
    range(section, length, bytes.length);
    if (!magic(section, 'KNBA')) {
      section += length;
      continue;
    }
    final end = section + length;
    range(section, 24, end);
    final count = u16(section + 8);
    if (count == 0 || count > 2048) {
      throw const FormatException('Invalid NANR sequence count');
    }
    final table = section + 8 + u32(section + 12);
    final framesBase = section + 8 + u32(section + 16);
    final elementsBase = section + 8 + u32(section + 20);
    range(table, count * 16, end);
    range(framesBase, 0, end);
    range(elementsBase, 0, end);
    final elementOffsets = <int>{end - elementsBase};
    var countedFrames = 0;
    for (var s = 0; s < count; s++) {
      final entry = table + s * 16;
      final frameCount = u16(entry);
      countedFrames += frameCount;
      if (frameCount > 4096 || countedFrames > 65536) {
        throw const FormatException('Too many NANR frames');
      }
      final start = framesBase + u32(entry + 12);
      range(start, frameCount * 8, end);
      for (var f = 0; f < frameCount; f++) {
        final offset = u32(start + f * 8);
        range(elementsBase + offset, 2, end);
        elementOffsets.add(offset);
      }
    }
    final orderedOffsets = elementOffsets.toList()..sort();
    final elementEnds = <int, int>{};
    for (var i = 0; i + 1 < orderedOffsets.length; i++) {
      elementEnds[orderedOffsets[i]] = orderedOffsets[i + 1];
    }
    var totalFrames = 0;
    final sequences = <Gen5NitroSequence>[];
    for (var s = 0; s < count; s++) {
      final entry = table + s * 16;
      final frameCount = u16(entry);
      final loopStart = u16(entry + 2);
      final format = u16(entry + 4);
      if (frameCount == 0 ||
          frameCount > 4096 ||
          loopStart >= frameCount ||
          format > 3 ||
          (totalFrames += frameCount) > 65536) {
        throw const FormatException('Unsupported NANR sequence');
      }
      final start = framesBase + u32(entry + 12);
      range(start, frameCount * 8, end);
      final frames = <Gen5NitroFrame>[];
      for (var f = 0; f < frameCount; f++) {
        final at = start + f * 8;
        final offset = u32(at);
        final element = elementsBase + offset;
        final size = const [2, 16, 8, 4][format];
        final elementEnd = elementEnds[offset];
        if (elementEnd == null || size > elementEnd - offset) {
          throw const FormatException('Overlapping NANR frame elements');
        }
        range(element, size, end);
        frames.add(
          Gen5NitroFrame(
            targetIndex: u16(element),
            duration: u16(at + 4),
            marker: u16(at + 6),
            transformType: format,
            rotation: format == 1
                ? data.getInt16(element + 2, Endian.little)
                : 0,
            scaleX: format == 1
                ? data.getInt32(element + 4, Endian.little)
                : 4096,
            scaleY: format == 1
                ? data.getInt32(element + 8, Endian.little)
                : 4096,
            translateX: format == 1
                ? data.getInt16(element + 12, Endian.little)
                : format == 2
                ? data.getInt16(element + 4, Endian.little)
                : 0,
            translateY: format == 1
                ? data.getInt16(element + 14, Endian.little)
                : format == 2
                ? data.getInt16(element + 6, Endian.little)
                : 0,
          ),
        );
      }
      sequences.add(
        Gen5NitroSequence(
          loopStart: loopStart,
          playbackType: u32(entry + 8),
          format: format,
          frames: List.unmodifiable(frames),
          isMultiCellTimeline: signature == 'RAMN',
        ),
      );
    }
    return List.unmodifiable(sequences);
  }
  throw const FormatException('NANR animation section missing');
}
