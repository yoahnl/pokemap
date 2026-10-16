import 'package:map_authoring/src/transactions/local_authoring_payload.dart';
import 'dart:io';

import 'package:map_authoring/src/history/content_blob_store.dart';
import 'package:map_authoring/src/support/authoring_fingerprint.dart';
import 'package:test/test.dart';

void main() {
  test('durable history streams stored payload and restores an owned image',
      () async {
    final directory = await Directory.systemTemp.createTemp('history-stream-');
    addTearDown(() => directory.delete(recursive: true));
    final store =
        await FileAuthoringContentBlobStore.open(projectRoot: directory.path);
    final bytes =
        List<int>.generate(2 * 1024 * 1024 + 11, (index) => index % 251);
    final source = await captureAuthoringPayload(
        storageKey: 'assets/model.glb',
        chunks: Stream.value(bytes),
        byteLength: bytes.length);
    final retained = await store.putPayload(source);
    await source.release();
    expect(
        retained.id,
        computeAuthoringBytesFingerprint(bytes,
            logicalName: 'authoring-history-blob'));
    expect(await store.contains(retained.id), isTrue);
    final reopened =
        await FileAuthoringContentBlobStore.open(projectRoot: directory.path);
    final restored = await reopened.capturePayload(retained.id,
        storageKey: 'assets/model.glb');
    addTearDown(restored!.release);
    expect(restored.isInline, isFalse);
    await store.prune(retainIds: {});
    expect(await restored.readBytes(), bytes);
    expect(await store.contains(retained.id), isFalse);
  });

  test('contains verifies retained content and rejects corruption', () async {
    final directory = await Directory.systemTemp.createTemp('history-corrupt-');
    addTearDown(() => directory.delete(recursive: true));
    final store =
        await FileAuthoringContentBlobStore.open(projectRoot: directory.path);
    final retained = await store.put([1, 2, 3]);
    final file = File(
        '${directory.path}/.pokemap/authoring/blobs/${retained.id.substring(7)}.blob');
    await file.writeAsBytes([1, 2, 4]);
    await expectLater(store.contains(retained.id),
        throwsA(isA<AuthoringContentBlobStoreException>()));
  });
}
