import 'dart:async';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('large resource fingerprints retain canonical framing on worker',
      () async {
    final bytes = Uint8List.fromList(
      List<int>.generate(300 * 1024, (index) => index % 251),
    );
    final executor = ProjectSnapshotDecodeExecutor();
    final expected = (NarrativeProjectFingerprintBuilder()
          ..startEntry(
              relativePath: 'maps/route.json', byteLength: bytes.length)
          ..addBytes(bytes)
          ..endEntry())
        .close();
    final actual = await executor.fingerprintResource(
      bytes,
      relativePath: 'maps/route.json',
    );
    expect(actual, expected);
    expect(executor.diagnostics.workerOperations, 1);
    expect(executor.diagnostics.localOperations, 0);
  });

  test('large asset verification retains content identity on worker', () async {
    final bytes = Uint8List.fromList(
      List<int>.generate(300 * 1024, (index) => index % 239),
    );
    final executor = ProjectSnapshotDecodeExecutor();
    final expected =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png');
    final actual =
        await executor.inspectArtifact(bytes, mediaType: 'image/png');
    expect(actual, expected);
    expect(executor.diagnostics.workerOperations, 1);
    expect(executor.diagnostics.workerFailures, 0);
  });

  test('small resource sequence yields instead of starving event loop',
      () async {
    final executor = ProjectSnapshotDecodeExecutor();
    final bytes = Uint8List(8 * 1024);
    var eventDelivered = false;
    final timer = Timer(Duration.zero, () => eventDelivered = true);
    try {
      for (var index = 0; index < 2560; index++) {
        await executor.fingerprintResource(bytes, relativePath: 'small.json');
        if (eventDelivered) break;
      }
      expect(eventDelivered, isTrue);
      expect(executor.diagnostics.workerOperations, 0);
    } finally {
      timer.cancel();
    }
  });
}
