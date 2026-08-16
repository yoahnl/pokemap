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
}
