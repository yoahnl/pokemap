import 'dart:convert';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:test/test.dart';

void main() {
  test('finite audio artifacts own their exact bytes and enforce probed MIME',
      () {
    final bytes = _wav();
    final artifact = NativeArtifact(bytes: bytes, mediaType: 'audio/wav');
    final expected = List<int>.of(bytes);
    bytes[44] = 0;
    expect(artifact.bytes, expected);
    expect(() => artifact.bytes[44] = 0, throwsUnsupportedError);
    expect(
        () => NativeArtifact(bytes: expected, mediaType: 'audio/ogg'),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.artifact.audio')));
  });

  test('truncated sounds and oversized audio cannot enter a native draft', () {
    expect(
        () => NativeArtifact(
            bytes: _wav().sublist(0, 43), mediaType: 'audio/wav'),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.artifact.audio')));
    expect(
        () => NativeArtifact(
            bytes: _wav(),
            mediaType: 'audio/wav',
            limits: const NativeWriteLimits(maxArtifactBytes: 128)),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.quota.artifact')));
  });
}

Uint8List _wav() {
  final bytes = Uint8List(8044);
  final data = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, utf8.encode('RIFF'));
  data.setUint32(4, bytes.length - 8, Endian.little);
  bytes.setRange(8, 16, utf8.encode('WAVEfmt '));
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 8000, Endian.little);
  data.setUint32(28, 8000, Endian.little);
  data.setUint16(32, 1, Endian.little);
  data.setUint16(34, 8, Endian.little);
  bytes.setRange(36, 40, utf8.encode('data'));
  data.setUint32(40, 8000, Endian.little);
  bytes.fillRange(44, bytes.length, 128);
  return bytes;
}
