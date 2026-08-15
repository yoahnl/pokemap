import 'dart:convert';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

final class PresentationMediaProbeException implements Exception {
  const PresentationMediaProbeException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'PresentationMediaProbeException($code): $message';
}

final class PresentationMediaProbeResult {
  const PresentationMediaProbeResult({
    required this.mediaType,
    required this.container,
    required this.codec,
    required this.sizeBytes,
    this.audioCodec,
    this.width,
    this.height,
    this.durationMilliseconds,
  });

  final String mediaType;
  final String container;
  final String codec;
  final String? audioCodec;
  final int sizeBytes;
  final int? width;
  final int? height;
  final int? durationMilliseconds;

  ProjectMediaTechnicalMetadata toTechnicalMetadata() =>
      ProjectMediaTechnicalMetadata(
        mediaType: mediaType,
        container: container,
        codec: codec,
        audioCodec: audioCodec,
        sizeBytes: sizeBytes,
        width: width,
        height: height,
        durationMilliseconds: durationMilliseconds,
      );
}

abstract interface class PresentationMediaProbePort {
  PresentationMediaProbeResult inspect(
    List<int> bytes, {
    required String declaredMediaType,
  });
}

final class PresentationMediaHeaderProbe implements PresentationMediaProbePort {
  const PresentationMediaHeaderProbe();

  @override
  PresentationMediaProbeResult inspect(
    List<int> source, {
    required String declaredMediaType,
  }) {
    if (source.isEmpty || source.any((byte) => byte < 0 || byte > 255)) {
      throw const PresentationMediaProbeException(
        'presentation_media.magic_unknown',
        'The staged bytes do not contain a supported media signature.',
      );
    }
    final bytes = Uint8List.fromList(source);
    final result = _inspect(bytes);
    final declared = declaredMediaType.trim().toLowerCase();
    if (declared != result.mediaType) {
      throw PresentationMediaProbeException(
        'presentation_media.mime_mismatch',
        'Declared MIME $declared conflicts with observed ${result.mediaType}.',
      );
    }
    return result;
  }

  PresentationMediaProbeResult _inspect(Uint8List bytes) {
    final png = _pngDimensions(bytes);
    if (png != null) {
      return _visual(bytes, 'image/png', 'png', 'png', png);
    }
    final jpeg = _jpegDimensions(bytes);
    if (jpeg != null) {
      return _visual(bytes, 'image/jpeg', 'jpeg', 'jpeg', jpeg);
    }
    final webp = _webpDimensions(bytes);
    if (webp != null) {
      return _visual(bytes, 'image/webp', 'webp', 'webp', webp);
    }
    if (_asciiAt(bytes, 0, 'WEBVTT')) {
      try {
        utf8.decode(bytes, allowMalformed: false);
      } on FormatException {
        throw const PresentationMediaProbeException(
          'presentation_media.caption_invalid',
          'WebVTT captions must be valid UTF-8.',
        );
      }
      return PresentationMediaProbeResult(
        mediaType: 'text/vtt',
        container: 'webvtt',
        codec: 'webvtt',
        sizeBytes: bytes.length,
      );
    }
    final wav = _wav(bytes);
    if (wav != null) return wav;
    final flac = _flac(bytes);
    if (flac != null) return flac;
    final ogg = _ogg(bytes);
    if (ogg != null) return ogg;
    final mp3 = _mp3(bytes);
    if (mp3 != null) return mp3;
    final mp4 = _mp4(bytes);
    if (mp4 != null) return mp4;
    throw const PresentationMediaProbeException(
      'presentation_media.magic_unknown',
      'The staged bytes do not contain a supported media signature.',
    );
  }
}

PresentationMediaProbeResult _visual(
  Uint8List bytes,
  String mediaType,
  String container,
  String codec,
  ({int width, int height}) dimensions,
) =>
    PresentationMediaProbeResult(
      mediaType: mediaType,
      container: container,
      codec: codec,
      sizeBytes: bytes.length,
      width: dimensions.width,
      height: dimensions.height,
    );

PresentationMediaProbeResult? _wav(Uint8List bytes) {
  if (bytes.length < 44 ||
      !_asciiAt(bytes, 0, 'RIFF') ||
      !_asciiAt(bytes, 8, 'WAVE')) {
    return null;
  }
  final data = ByteData.sublistView(bytes);
  int? format;
  int? byteRate;
  int? dataSize;
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final length = data.getUint32(offset + 4, Endian.little);
    final payload = offset + 8;
    if (payload + length > bytes.length) break;
    if (_asciiAt(bytes, offset, 'fmt ') && length >= 16) {
      format = data.getUint16(payload, Endian.little);
      byteRate = data.getUint32(payload + 8, Endian.little);
    } else if (_asciiAt(bytes, offset, 'data')) {
      dataSize = length;
    }
    offset = payload + length + (length.isOdd ? 1 : 0);
  }
  if (format == null || byteRate == null || byteRate < 1 || dataSize == null) {
    return null;
  }
  final codec = switch (format) {
    1 => 'pcm',
    3 => 'pcm_float',
    0xfffe => 'pcm_extensible',
    _ => 'wav_$format',
  };
  return PresentationMediaProbeResult(
    mediaType: 'audio/wav',
    container: 'wav',
    codec: codec,
    sizeBytes: bytes.length,
    durationMilliseconds: (dataSize * 1000 / byteRate).round(),
  );
}

PresentationMediaProbeResult? _flac(Uint8List bytes) {
  if (bytes.length < 42 || !_asciiAt(bytes, 0, 'fLaC')) return null;
  final blockType = bytes[4] & 0x7f;
  final length = (bytes[5] << 16) | (bytes[6] << 8) | bytes[7];
  if (blockType != 0 || length < 34 || bytes.length < 8 + length) return null;
  final packed = ByteData.sublistView(bytes, 18, 26).getUint64(0);
  final sampleRate = packed >> 44;
  final totalSamples = packed & 0x0fffffffff;
  if (sampleRate < 1 || totalSamples < 1) return null;
  return PresentationMediaProbeResult(
    mediaType: 'audio/flac',
    container: 'flac',
    codec: 'flac',
    sizeBytes: bytes.length,
    durationMilliseconds: (totalSamples * 1000 / sampleRate).round(),
  );
}

PresentationMediaProbeResult? _ogg(Uint8List bytes) {
  if (!_asciiAt(bytes, 0, 'OggS')) return null;
  final vorbis = _indexOfAscii(bytes, '\u0001vorbis');
  final opus = _indexOfAscii(bytes, 'OpusHead');
  late final String codec;
  late final int sampleRate;
  if (vorbis >= 0 && vorbis + 16 <= bytes.length) {
    codec = 'vorbis';
    sampleRate = ByteData.sublistView(bytes).getUint32(
      vorbis + 12,
      Endian.little,
    );
  } else if (opus >= 0) {
    codec = 'opus';
    sampleRate = 48000;
  } else {
    return null;
  }
  final lastPage = _lastIndexOfAscii(bytes, 'OggS');
  if (sampleRate < 1 || lastPage < 0 || lastPage + 14 > bytes.length) {
    return null;
  }
  final granule = ByteData.sublistView(bytes).getUint64(
    lastPage + 6,
    Endian.little,
  );
  if (granule < 1) return null;
  return PresentationMediaProbeResult(
    mediaType: 'audio/ogg',
    container: 'ogg',
    codec: codec,
    sizeBytes: bytes.length,
    durationMilliseconds: (granule * 1000 / sampleRate).round(),
  );
}

PresentationMediaProbeResult? _mp3(Uint8List bytes) {
  var offset = _id3PayloadEnd(bytes);
  var totalSamples = 0;
  int? sampleRate;
  var frames = 0;
  while (offset + 4 <= bytes.length) {
    final frame = _mp3Frame(bytes, offset);
    if (frame == null) {
      offset++;
      continue;
    }
    sampleRate ??= frame.sampleRate;
    if (sampleRate != frame.sampleRate) return null;
    totalSamples += frame.samples;
    frames++;
    offset += frame.length;
  }
  if (frames == 0 || sampleRate == null || totalSamples < 1) return null;
  return PresentationMediaProbeResult(
    mediaType: 'audio/mpeg',
    container: 'mp3',
    codec: 'mp3',
    sizeBytes: bytes.length,
    durationMilliseconds: (totalSamples * 1000 / sampleRate).round(),
  );
}

PresentationMediaProbeResult? _mp4(Uint8List bytes) {
  final top = _mp4Boxes(bytes, 0, bytes.length);
  if (!top.any((box) => box.type == 'ftyp')) return null;
  final boxes = <_Mp4Box>[];
  void collect(Iterable<_Mp4Box> source) {
    for (final box in source) {
      boxes.add(box);
      if (const {'moov', 'trak', 'mdia', 'minf', 'stbl'}.contains(box.type)) {
        collect(_mp4Boxes(bytes, box.payloadStart, box.end));
      }
    }
  }

  collect(top);
  final mvhd = boxes.where((box) => box.type == 'mvhd').firstOrNull;
  final duration = mvhd == null ? null : _mp4Duration(bytes, mvhd);
  final handlers = boxes
      .where((box) => box.type == 'hdlr')
      .map((box) => _ascii(bytes, box.payloadStart + 8, 4))
      .toSet();
  final isVideo = handlers.contains('vide');
  final isAudio = handlers.contains('soun');
  if ((!isVideo && !isAudio) || duration == null || duration < 1) return null;
  if (isVideo) {
    final tkhd = boxes.where((box) => box.type == 'tkhd').firstOrNull;
    final dimensions = tkhd == null ? null : _mp4Dimensions(bytes, tkhd);
    final codec = _containsAscii(bytes, 'avc1') || _containsAscii(bytes, 'avc3')
        ? 'h264'
        : _containsAscii(bytes, 'hvc1') || _containsAscii(bytes, 'hev1')
            ? 'hevc'
            : null;
    if (dimensions == null || codec == null) return null;
    return PresentationMediaProbeResult(
      mediaType: 'video/mp4',
      container: 'mp4',
      codec: codec,
      audioCodec: isAudio && _containsAscii(bytes, 'mp4a') ? 'aac' : null,
      sizeBytes: bytes.length,
      width: dimensions.width,
      height: dimensions.height,
      durationMilliseconds: duration,
    );
  }
  if (!_containsAscii(bytes, 'mp4a')) return null;
  return PresentationMediaProbeResult(
    mediaType: 'audio/mp4',
    container: 'mp4',
    codec: 'aac',
    sizeBytes: bytes.length,
    durationMilliseconds: duration,
  );
}

({int width, int height})? _pngDimensions(Uint8List bytes) {
  if (bytes.length < 24 ||
      !_startsWith(bytes, const <int>[137, 80, 78, 71, 13, 10, 26, 10]) ||
      !_asciiAt(bytes, 12, 'IHDR')) {
    return null;
  }
  final data = ByteData.sublistView(bytes);
  final width = data.getUint32(16);
  final height = data.getUint32(20);
  return width > 0 && height > 0 ? (width: width, height: height) : null;
}

({int width, int height})? _jpegDimensions(Uint8List bytes) {
  if (!_startsWith(bytes, const <int>[0xff, 0xd8])) return null;
  var offset = 2;
  while (offset + 9 <= bytes.length) {
    if (bytes[offset] != 0xff) return null;
    while (offset < bytes.length && bytes[offset] == 0xff) {
      offset++;
    }
    if (offset >= bytes.length) return null;
    final marker = bytes[offset++];
    if (marker == 0xd9 || marker == 0xda) break;
    if (offset + 2 > bytes.length) return null;
    final length = (bytes[offset] << 8) | bytes[offset + 1];
    if (length < 2 || offset + length > bytes.length) return null;
    if (_jpegSofMarkers.contains(marker) && length >= 7) {
      final height = (bytes[offset + 3] << 8) | bytes[offset + 4];
      final width = (bytes[offset + 5] << 8) | bytes[offset + 6];
      return width > 0 && height > 0 ? (width: width, height: height) : null;
    }
    offset += length;
  }
  return null;
}

({int width, int height})? _webpDimensions(Uint8List bytes) {
  if (bytes.length < 16 ||
      !_asciiAt(bytes, 0, 'RIFF') ||
      !_asciiAt(bytes, 8, 'WEBP')) {
    return null;
  }
  if (_asciiAt(bytes, 12, 'VP8X') && bytes.length >= 30) {
    return (width: 1 + _u24le(bytes, 24), height: 1 + _u24le(bytes, 27));
  }
  if (_asciiAt(bytes, 12, 'VP8L') && bytes.length >= 25 && bytes[20] == 0x2f) {
    return (
      width: 1 + bytes[21] + ((bytes[22] & 0x3f) << 8),
      height:
          1 + (bytes[22] >> 6) + (bytes[23] << 2) + ((bytes[24] & 0x0f) << 10),
    );
  }
  if (_asciiAt(bytes, 12, 'VP8 ') &&
      bytes.length >= 30 &&
      _startsWithAt(bytes, 23, const <int>[0x9d, 0x01, 0x2a])) {
    final width = (bytes[26] | (bytes[27] << 8)) & 0x3fff;
    final height = (bytes[28] | (bytes[29] << 8)) & 0x3fff;
    return width > 0 && height > 0 ? (width: width, height: height) : null;
  }
  return null;
}

int _id3PayloadEnd(Uint8List bytes) {
  if (bytes.length < 10 || !_asciiAt(bytes, 0, 'ID3')) return 0;
  final size = (bytes[6] << 21) | (bytes[7] << 14) | (bytes[8] << 7) | bytes[9];
  return 10 + size;
}

({int length, int samples, int sampleRate})? _mp3Frame(
  Uint8List bytes,
  int offset,
) {
  if (offset + 4 > bytes.length ||
      bytes[offset] != 0xff ||
      (bytes[offset + 1] & 0xe0) != 0xe0) {
    return null;
  }
  final versionBits = (bytes[offset + 1] >> 3) & 0x03;
  final layerBits = (bytes[offset + 1] >> 1) & 0x03;
  final bitrateIndex = (bytes[offset + 2] >> 4) & 0x0f;
  final sampleIndex = (bytes[offset + 2] >> 2) & 0x03;
  final padding = (bytes[offset + 2] >> 1) & 0x01;
  if (versionBits == 1 ||
      layerBits != 1 ||
      bitrateIndex == 0 ||
      bitrateIndex == 15 ||
      sampleIndex == 3) {
    return null;
  }
  final mpeg1 = versionBits == 3;
  final rates = versionBits == 3
      ? const <int>[44100, 48000, 32000]
      : versionBits == 2
          ? const <int>[22050, 24000, 16000]
          : const <int>[11025, 12000, 8000];
  final bitrates = mpeg1
      ? const <int>[
          0,
          32,
          40,
          48,
          56,
          64,
          80,
          96,
          112,
          128,
          160,
          192,
          224,
          256,
          320
        ]
      : const <int>[
          0,
          8,
          16,
          24,
          32,
          40,
          48,
          56,
          64,
          80,
          96,
          112,
          128,
          144,
          160
        ];
  final sampleRate = rates[sampleIndex];
  final bitrate = bitrates[bitrateIndex] * 1000;
  final length = ((mpeg1 ? 144 : 72) * bitrate ~/ sampleRate) + padding;
  if (length < 4 || offset + length > bytes.length) return null;
  return (length: length, samples: mpeg1 ? 1152 : 576, sampleRate: sampleRate);
}

List<_Mp4Box> _mp4Boxes(Uint8List bytes, int start, int end) {
  final boxes = <_Mp4Box>[];
  final data = ByteData.sublistView(bytes);
  var offset = start;
  while (offset + 8 <= end) {
    var size = data.getUint32(offset);
    final type = _ascii(bytes, offset + 4, 4);
    var header = 8;
    if (size == 1) {
      if (offset + 16 > end) return const <_Mp4Box>[];
      final large = data.getUint64(offset + 8);
      if (large > 0x7fffffff) return const <_Mp4Box>[];
      size = large;
      header = 16;
    } else if (size == 0) {
      size = end - offset;
    }
    if (size < header || offset + size > end) return const <_Mp4Box>[];
    boxes.add(
      _Mp4Box(
        type: type,
        payloadStart: offset + header,
        end: offset + size,
      ),
    );
    offset += size;
  }
  return offset == end ? boxes : const <_Mp4Box>[];
}

int? _mp4Duration(Uint8List bytes, _Mp4Box box) {
  final data = ByteData.sublistView(bytes);
  if (box.payloadStart + 20 > box.end) return null;
  final version = bytes[box.payloadStart];
  final timescaleOffset = box.payloadStart + (version == 1 ? 20 : 12);
  final durationOffset = box.payloadStart + (version == 1 ? 24 : 16);
  if (durationOffset + (version == 1 ? 8 : 4) > box.end) return null;
  final timescale = data.getUint32(timescaleOffset);
  final duration = version == 1
      ? data.getUint64(durationOffset)
      : data.getUint32(durationOffset);
  if (timescale < 1 || duration < 1) return null;
  return (duration * 1000 / timescale).round();
}

({int width, int height})? _mp4Dimensions(Uint8List bytes, _Mp4Box box) {
  if (box.end - box.payloadStart < 8) return null;
  final data = ByteData.sublistView(bytes);
  final width = data.getUint32(box.end - 8) >> 16;
  final height = data.getUint32(box.end - 4) >> 16;
  return width > 0 && height > 0 ? (width: width, height: height) : null;
}

bool _containsAscii(Uint8List bytes, String value) =>
    _indexOfAscii(bytes, value) >= 0;

int _indexOfAscii(Uint8List bytes, String value) {
  final needle = ascii.encode(value);
  for (var offset = 0; offset + needle.length <= bytes.length; offset++) {
    if (_startsWithAt(bytes, offset, needle)) return offset;
  }
  return -1;
}

int _lastIndexOfAscii(Uint8List bytes, String value) {
  final needle = ascii.encode(value);
  for (var offset = bytes.length - needle.length; offset >= 0; offset--) {
    if (_startsWithAt(bytes, offset, needle)) return offset;
  }
  return -1;
}

bool _asciiAt(Uint8List bytes, int offset, String value) =>
    _startsWithAt(bytes, offset, ascii.encode(value));

String _ascii(Uint8List bytes, int offset, int length) {
  if (offset < 0 || offset + length > bytes.length) return '';
  return ascii.decode(bytes.sublist(offset, offset + length),
      allowInvalid: true);
}

bool _startsWith(Uint8List bytes, List<int> prefix) =>
    _startsWithAt(bytes, 0, prefix);

bool _startsWithAt(Uint8List bytes, int offset, List<int> prefix) {
  if (offset < 0 || offset + prefix.length > bytes.length) return false;
  for (var index = 0; index < prefix.length; index++) {
    if (bytes[offset + index] != prefix[index]) return false;
  }
  return true;
}

int _u24le(Uint8List bytes, int offset) =>
    bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);

final class _Mp4Box {
  const _Mp4Box({
    required this.type,
    required this.payloadStart,
    required this.end,
  });

  final String type;
  final int payloadStart;
  final int end;
}

const Set<int> _jpegSofMarkers = <int>{
  0xc0,
  0xc1,
  0xc2,
  0xc3,
  0xc5,
  0xc6,
  0xc7,
  0xc9,
  0xca,
  0xcb,
  0xcd,
  0xce,
  0xcf,
};
