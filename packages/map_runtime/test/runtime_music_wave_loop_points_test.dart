import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/player/runtime_music_loop_points.dart';

void main() {
  late Directory directory;
  var fileNumber = 0;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('wave-loop-points-');
  });

  tearDown(() {
    directory.deleteSync(recursive: true);
  });

  String writeWave({
    int rate = 48000,
    int start = 10,
    int end = 39,
    int loopType = 0,
    int frames = 64,
    int format = 1,
    int bits = 16,
    bool includeFormat = true,
    bool includeLoop = true,
    bool loopFirst = false,
    bool oddChunk = false,
    void Function(ByteData bytes)? mutate,
    int? truncateLength,
    int? prefixPadding,
  }) {
    final blockAlign = 2 * (bits ~/ 8);
    final fmt = ByteData(16)
      ..setUint16(0, format, Endian.little)
      ..setUint16(2, 2, Endian.little)
      ..setUint32(4, rate, Endian.little)
      ..setUint32(8, rate * blockAlign, Endian.little)
      ..setUint16(12, blockAlign, Endian.little)
      ..setUint16(14, bits, Endian.little);
    final smpl = ByteData(60)
      ..setUint32(8, rate == 0 ? 0 : (1000000000 / rate).round(), Endian.little)
      ..setUint32(28, 1, Endian.little)
      ..setUint32(40, loopType, Endian.little)
      ..setUint32(44, start, Endian.little)
      ..setUint32(48, end, Endian.little);
    final chunks = <Uint8List>[
      if (oddChunk) _chunk('JUNK', Uint8List.fromList([1, 2, 3])),
      if (prefixPadding != null) _chunk('JUNK', Uint8List(prefixPadding)),
      if (loopFirst && includeLoop) _chunk('smpl', smpl.buffer.asUint8List()),
      if (includeFormat) _chunk('fmt ', fmt.buffer.asUint8List()),
      if (!loopFirst && includeLoop) _chunk('smpl', smpl.buffer.asUint8List()),
    ];
    final body = BytesBuilder()..add('WAVE'.codeUnits);
    for (final chunk in chunks) {
      body.add(chunk);
    }
    body.add('data'.codeUnits);
    body.add(
      (ByteData(
        4,
      )..setUint32(0, frames * blockAlign, Endian.little)).buffer.asUint8List(),
    );
    final content = BytesBuilder()
      ..add('RIFF'.codeUnits)
      ..add(
        (ByteData(4)
              ..setUint32(0, body.length + frames * blockAlign, Endian.little))
            .buffer
            .asUint8List(),
      )
      ..add(body.takeBytes());
    final bytes = content.takeBytes();
    mutate?.call(ByteData.sublistView(bytes));
    final file = File('${directory.path}/music-${fileNumber++}.wav')
      ..writeAsBytesSync(bytes);
    final handle = file.openSync(mode: FileMode.append);
    try {
      handle.truncateSync(truncateLength ?? bytes.length + frames * blockAlign);
    } finally {
      handle.closeSync();
    }
    return file.path;
  }

  test('reads inclusive PCM smpl bounds at the authored sample rate', () {
    final path = writeWave(start: 645360, end: 3096239, frames: 3096240);

    final points = readRuntimeMusicLoopPoints(path);

    expect(points, isNotNull);
    expect(points!.sampleRate, 48000);
    expect(points.startSample, 645360);
    expect(points.lengthSamples, 2450880);
    expect(points.start, const Duration(milliseconds: 13445));
    expect(points.end, const Duration(milliseconds: 64505));
  });

  test('handles chunk padding and smpl before fmt', () {
    final points = readRuntimeMusicLoopPoints(
      writeWave(oddChunk: true, loopFirst: true),
    );

    expect(points?.lengthSamples, 30);
    expect(points?.sampleRate, 48000);
  });

  test('reads standard stereo PCM 24 bit sampler metadata', () {
    final points = readRuntimeMusicLoopPoints(writeWave(bits: 24));

    expect(points?.startSample, 10);
    expect(points?.lengthSamples, 30);
    expect(points?.sampleRate, 48000);
  });

  test('accepts a one sample forward loop', () {
    expect(
      readRuntimeMusicLoopPoints(writeWave(start: 0, end: 0))?.lengthSamples,
      1,
    );
  });

  test('rejects unsupported loops and inverted or out of data bounds', () {
    for (final path in [
      writeWave(loopType: 1),
      writeWave(start: 40, end: 39),
      writeWave(end: 64),
    ]) {
      expect(readRuntimeMusicLoopPoints(path), isNull);
    }
  });

  test('requires valid PCM format and a loop chunk', () {
    for (final path in [
      writeWave(rate: 0),
      writeWave(format: 6),
      writeWave(bits: 12),
      writeWave(includeFormat: false),
      writeWave(includeLoop: false),
    ]) {
      expect(readRuntimeMusicLoopPoints(path), isNull);
    }
  });

  test('rejects truncated RIFF files', () {
    for (final length in [0, 11, 43, 100, 120]) {
      expect(
        readRuntimeMusicLoopPoints(writeWave(truncateLength: length)),
        isNull,
      );
    }
  });

  test('rejects chunk lengths and loop counts outside the RIFF boundary', () {
    for (final offset in [4, 16, 40, 72]) {
      final path = writeWave(
        mutate: (bytes) => bytes.setUint32(offset, 0xffffffff, Endian.little),
      );
      expect(readRuntimeMusicLoopPoints(path), isNull);
    }
  });

  test('rejects fractional and finite sampler loops', () {
    for (final offset in [96, 100]) {
      final path = writeWave(
        mutate: (bytes) => bytes.setUint32(offset, 1, Endian.little),
      );
      expect(readRuntimeMusicLoopPoints(path), isNull);
    }
  });

  test('rejects malformed PCM alignment and byte rate', () {
    for (final offset in [28, 32]) {
      final path = writeWave(
        mutate: (bytes) => bytes.setUint16(offset, 0, Endian.little),
      );
      expect(readRuntimeMusicLoopPoints(path), isNull);
    }
  });

  test('keeps metadata reads within the configured prefix', () {
    final path = writeWave(prefixPadding: 128);

    expect(readRuntimeMusicLoopPoints(path, maxPrefixBytes: 64), isNull);
    expect(
      readRuntimeMusicLoopPoints(path, maxPrefixBytes: 512)?.lengthSamples,
      30,
    );
    expect(readRuntimeMusicLoopPoints(path, maxPrefixBytes: 0), isNull);
  });

  test('does not interpret Vorbis text as a malformed WAV loop', () {
    final path = writeWave(
      includeLoop: false,
      prefixPadding: 64,
      mutate: (bytes) {
        final fake = 'LOOPSTART=10 LOOPLENGTH=30'.codeUnits;
        bytes.buffer.asUint8List().setRange(20, 20 + fake.length, fake);
      },
    );

    expect(readRuntimeMusicLoopPoints(path), isNull);
  });
}

Uint8List _chunk(String name, Uint8List payload) {
  return (BytesBuilder()
        ..add(name.codeUnits)
        ..add(
          (ByteData(
            4,
          )..setUint32(0, payload.length, Endian.little)).buffer.asUint8List(),
        )
        ..add(payload)
        ..add(payload.length.isOdd ? [0] : <int>[]))
      .takeBytes();
}
