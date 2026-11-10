import 'dart:convert';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  test('stages ASCII and UTF-8 WebVTT with the native caption MIME', () async {
    final store = MemoryArtifactStore(maximumArtifactBytes: 1024);
    for (final content in [
      'WEBVTT',
      'WEBVTT header\n\n00:00.000 --> 00:01.000\nBonjour\n',
      'WEBVTT\theader\r\n\r\n00:00.000 --> 00:01.000\r\nBonjour\r\n',
      'WEBVTT\n\n00:00.000 --> 00:01.000\nBonjour\n',
      'WEBVTT\n\n00:00.000 --> 00:01.000\nÉté — こんにちは\n',
      'WEBVTT\r\n\r\n00:00.000 --> 00:01.000\r\nBonjour\r\n',
    ]) {
      final bytes = utf8.encode(content);
      expect(sniffArtifactMediaType(bytes), 'text/vtt');
      final inferred = await store.put(bytes);
      expect(inferred.reference.mediaType, 'text/vtt');
      expect(inferred.deduplicated, isFalse);
      final legacy =
          ContentArtifactRef.fromBytes(bytes, mediaType: 'text/plain');
      expect(inferred.reference.digest, legacy.digest);
      expect(inferred.reference.handle, legacy.handle);
      final declared = await store.put(bytes, declaredMediaType: 'text/vtt');
      expect(declared.reference.mediaType, 'text/vtt');
      expect(declared.reference.handle, inferred.reference.handle);
      expect(declared.deduplicated, isTrue);
      expect(await store.read(declared.reference.handle), bytes);
      await expectLater(
        store.put(bytes, declaredMediaType: 'text/plain'),
        throwsA(isA<ArtifactStoreException>().having(
          (error) => error.code,
          'code',
          'artifact.mime_mismatch',
        )),
      );
    }
  });

  test('caption-like text and NUL keep their original generic classifications',
      () async {
    final store = MemoryArtifactStore(maximumArtifactBytes: 1024);
    for (final content in ['WEBVTTfoo', 'WEBVTTfoo\nordinary text']) {
      final bytes = utf8.encode(content);
      expect(sniffArtifactMediaType(bytes), 'text/plain');
      expect((await store.put(bytes)).reference.mediaType, 'text/plain');
    }
    for (final bytes in [
      utf8.encode('WEBVTT\u0000'),
      utf8.encode('WEBVTT\n\u0000'),
      utf8.encode('\ufeffWEBVTT\n\n'),
    ]) {
      expect(sniffArtifactMediaType(bytes), 'application/octet-stream');
      expect((await store.put(bytes)).reference.mediaType,
          'application/octet-stream');
      final declared = await MemoryArtifactStore(maximumArtifactBytes: 1024).put(
        bytes,
        declaredMediaType: 'application/x-custom',
      );
      expect(declared.reference.mediaType, 'application/x-custom');
    }
  });

  test('ordinary text keeps its MIME and refuses a caption declaration',
      () async {
    final store = MemoryArtifactStore(maximumArtifactBytes: 1024);
    final bytes = utf8.encode('ordinary text');
    expect(sniffArtifactMediaType(bytes), 'text/plain');
    expect((await store.put(bytes)).reference.mediaType, 'text/plain');
    await expectLater(
      store.put(bytes, declaredMediaType: 'text/vtt'),
      throwsA(isA<ArtifactStoreException>().having(
        (error) => error.code,
        'code',
        'artifact.mime_mismatch',
      )),
    );
  });

  test(
      'invalid UTF-8 is not classified as captions and image bytes reject a caption MIME',
      () async {
    expect(
      sniffArtifactMediaType([...utf8.encode('WEBVTT\n'), 0xff]),
      'application/octet-stream',
    );
    final store = MemoryArtifactStore(maximumArtifactBytes: 1024);
    await expectLater(
      store.put(
        [137, 80, 78, 71, 13, 10, 26, 10],
        declaredMediaType: 'text/vtt',
      ),
      throwsA(isA<ArtifactStoreException>().having(
        (error) => error.code,
        'code',
        'artifact.mime_mismatch',
      )),
    );
  });

  test(
      'recognizes valid UTF-8 JSON objects and arrays without accepting malformed text',
      () {
    for (final document in [
      '{"name":"Ground"}',
      ' \n {"name":"Étage"}',
      '[1,2]'
    ]) {
      expect(sniffArtifactMediaType(utf8.encode(document)), 'application/json');
    }
    expect(sniffArtifactMediaType(utf8.encode('{broken')), 'text/plain');
    expect(sniffArtifactMediaType(utf8.encode('plain text')), 'text/plain');
    expect(
        sniffArtifactMediaType([0x7b, 0xff, 0x7d]), 'application/octet-stream');
  });
  test('sniffs every supported audio format from its signature', () {
    expect(sniffArtifactMediaType(<int>[0x4f, 0x67, 0x67, 0x53]), 'audio/ogg');
    expect(sniffArtifactMediaType(<int>[0xff, 0xfb, 0x94, 0xc4]), 'audio/mpeg');
    expect(
      sniffArtifactMediaType(<int>[
        0x52,
        0x49,
        0x46,
        0x46,
        0,
        0,
        0,
        0,
        0x57,
        0x41,
        0x56,
        0x45,
      ]),
      'audio/wav',
    );
    expect(sniffArtifactMediaType(<int>[0x66, 0x4c, 0x61, 0x43]), 'audio/flac');
    expect(
      sniffArtifactMediaType(
        <int>[0, 0, 0, 0x18, 0x66, 0x74, 0x79, 0x70],
      ),
      'audio/mp4',
    );
    expect(sniffArtifactMediaType(<int>[0xff, 0xf1, 0x50, 0x80]), 'audio/aac');
  });

  test('distinguishes an H.264 MP4 video from an M4A audio container', () {
    expect(sniffArtifactMediaType(_h264Mp4()), 'video/mp4');
  });
}

Uint8List _h264Mp4() {
  final ftyp = _box('ftyp', 'isom\u0000\u0000\u0000\u0000isom'.codeUnits);
  final mvhdPayload = Uint8List(20);
  ByteData.sublistView(mvhdPayload)
    ..setUint32(12, 1000)
    ..setUint32(16, 1000);
  final tkhdPayload = Uint8List(84);
  ByteData.sublistView(tkhdPayload)
    ..setUint32(tkhdPayload.length - 8, 640 << 16)
    ..setUint32(tkhdPayload.length - 4, 360 << 16);
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
