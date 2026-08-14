import 'dart:typed_data';

import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  group('PresentationMediaHeaderProbe', () {
    const probe = PresentationMediaHeaderProbe();

    test('observes PNG magic and dimensions', () {
      final result = probe.inspect(
        _png(width: 640, height: 360),
        declaredMediaType: 'image/png',
      );

      expect(result.toTechnicalMetadata().toJson(), {
        'mediaType': 'image/png',
        'container': 'png',
        'codec': 'png',
        'sizeBytes': 24,
        'width': 640,
        'height': 360,
      });
    });

    test('observes WAV codec and exact duration', () {
      final bytes = _wav(
        sampleRate: 8000,
        channels: 1,
        bitsPerSample: 8,
        sampleCount: 8000,
      );

      final result = probe.inspect(
        bytes,
        declaredMediaType: 'audio/wav',
      );

      expect(result.mediaType, 'audio/wav');
      expect(result.container, 'wav');
      expect(result.codec, 'pcm');
      expect(result.durationMilliseconds, 1000);
      expect(result.sizeBytes, bytes.length);
    });

    test('observes MP4 duration, dimensions and H.264 codec', () {
      final bytes = _mp4(width: 1920, height: 1080, durationMs: 12000);

      final result = probe.inspect(
        bytes,
        declaredMediaType: 'video/mp4',
      );

      expect(result.mediaType, 'video/mp4');
      expect(result.container, 'mp4');
      expect(result.codec, 'h264');
      expect(result.width, 1920);
      expect(result.height, 1080);
      expect(result.durationMilliseconds, 12000);
    });

    test('rejects a declared MIME that conflicts with observed magic', () {
      expect(
        () => probe.inspect(
          _png(width: 1, height: 1),
          declaredMediaType: 'video/mp4',
        ),
        throwsA(
          isA<PresentationMediaProbeException>().having(
            (error) => error.code,
            'code',
            'presentation_media.mime_mismatch',
          ),
        ),
      );
    });

    test('rejects malformed bytes instead of trusting an extension or MIME',
        () {
      expect(
        () => probe.inspect(
          const <int>[1, 2, 3, 4],
          declaredMediaType: 'video/mp4',
        ),
        throwsA(
          isA<PresentationMediaProbeException>().having(
            (error) => error.code,
            'code',
            'presentation_media.magic_unknown',
          ),
        ),
      );
    });
  });
}

Uint8List _png({required int width, required int height}) {
  final bytes = Uint8List(24)
    ..setRange(0, 8, const <int>[137, 80, 78, 71, 13, 10, 26, 10])
    ..setRange(12, 16, 'IHDR'.codeUnits);
  ByteData.sublistView(bytes)
    ..setUint32(16, width)
    ..setUint32(20, height);
  return bytes;
}

Uint8List _wav({
  required int sampleRate,
  required int channels,
  required int bitsPerSample,
  required int sampleCount,
}) {
  final blockAlign = channels * bitsPerSample ~/ 8;
  final dataSize = sampleCount * blockAlign;
  final bytes = Uint8List(44 + dataSize);
  final data = ByteData.sublistView(bytes);
  bytes
    ..setRange(0, 4, 'RIFF'.codeUnits)
    ..setRange(8, 12, 'WAVE'.codeUnits)
    ..setRange(12, 16, 'fmt '.codeUnits)
    ..setRange(36, 40, 'data'.codeUnits);
  data
    ..setUint32(4, 36 + dataSize, Endian.little)
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, channels, Endian.little)
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * blockAlign, Endian.little)
    ..setUint16(32, blockAlign, Endian.little)
    ..setUint16(34, bitsPerSample, Endian.little)
    ..setUint32(40, dataSize, Endian.little);
  return bytes;
}

Uint8List _mp4({
  required int width,
  required int height,
  required int durationMs,
}) {
  final ftyp = _box('ftyp', 'isom\u0000\u0000\u0000\u0000isom'.codeUnits);
  final mvhdPayload = Uint8List(20);
  ByteData.sublistView(mvhdPayload)
    ..setUint32(12, 1000)
    ..setUint32(16, durationMs);
  final tkhdPayload = Uint8List(84);
  ByteData.sublistView(tkhdPayload)
    ..setUint32(tkhdPayload.length - 8, width << 16)
    ..setUint32(tkhdPayload.length - 4, height << 16);
  final hdlrPayload = Uint8List(12)..setRange(8, 12, 'vide'.codeUnits);
  final stsd = _box('stsd', 'avc1'.codeUnits);
  final stbl = _box('stbl', stsd);
  final minf = _box('minf', stbl);
  final mdia = _box('mdia', <int>[..._box('hdlr', hdlrPayload), ...minf]);
  final trak = _box('trak', <int>[..._box('tkhd', tkhdPayload), ...mdia]);
  final moov = _box('moov', <int>[..._box('mvhd', mvhdPayload), ...trak]);
  return Uint8List.fromList(<int>[...ftyp, ...moov]);
}

Uint8List _box(String type, List<int> payload) {
  final bytes = Uint8List(8 + payload.length)
    ..setRange(4, 8, type.codeUnits)
    ..setRange(8, 8 + payload.length, payload);
  ByteData.sublistView(bytes).setUint32(0, bytes.length);
  return bytes;
}
