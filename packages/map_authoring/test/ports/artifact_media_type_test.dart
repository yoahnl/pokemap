import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
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
