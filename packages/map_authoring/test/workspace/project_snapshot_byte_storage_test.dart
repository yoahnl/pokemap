import 'dart:typed_data';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

ProjectSnapshot snapshotBytes(List<int> bytes) => ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_compact_bytes'),
    revision: 'sha256:${List.filled(64, 'a').join()}',
    manifest:
        const ProjectManifest(name: 'Compact bytes', maps: [], tilesets: []),
    maps: const [],
    resourceFingerprints: {'project': 'sha256:${List.filled(64, 'b').join()}'},
    resourceBytes: {'project': bytes});

void main() {
  test(
      'direct snapshot bytes use immutable byte storage without mutable aliases',
      () {
    for (final input in <List<int>>[
      <int>[0, 1, 127, 128, 255],
      Uint8List.fromList([0, 1, 127, 128, 255]),
    ]) {
      final snapshot = snapshotBytes(input);
      final bytes = snapshot.resourceBytes('project');
      expect(bytes, isA<Uint8List>());
      final typed = bytes as Uint8List;
      expect(typed.lengthInBytes, input.length);
      expect(identical(bytes, snapshot.inlineResourceBytes['project']), isTrue);
      input[0] = 17;
      expect(bytes, [0, 1, 127, 128, 255]);
      expect(() => bytes[0] = 9, throwsUnsupportedError);
      expect(() => bytes.fillRange(0, 1, 9), throwsUnsupportedError);
      expect(() => typed.buffer.asUint8List()[0] = 9, throwsUnsupportedError);
      expect(() => typed.buffer.asByteData().setUint8(0, 9),
          throwsUnsupportedError);
      expect(() => Uint8List.sublistView(typed)[0] = 9, throwsUnsupportedError);
      final detached = typed.sublist(0);
      detached[0] = 23;
      expect(bytes, [0, 1, 127, 128, 255]);
    }
  });

  test('direct byte storage validates ranges before typed conversion', () {
    expect(() => snapshotBytes([-1, 0]), throwsArgumentError);
    expect(() => snapshotBytes([0, 256]), throwsArgumentError);
    expect(snapshotBytes([]).resourceBytes('project'), isEmpty);
    final bytes = List<int>.generate(1048576, (index) => index % 256);
    final frozen = snapshotBytes(bytes).resourceBytes('project') as Uint8List;
    expect(frozen.lengthInBytes, bytes.length);
    expect(frozen, bytes);
  });
}
