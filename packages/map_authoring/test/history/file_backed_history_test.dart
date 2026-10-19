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

  test('retains intact bytes after a transient metadata timestamp change',
      () async {
    final directory = await Directory.systemTemp.createTemp('history-metadata-');
    addTearDown(() => directory.delete(recursive: true));
    final store =
        await FileAuthoringContentBlobStore.open(projectRoot: directory.path);
    final overrides = _BlobMetadataOverrides();
    final retained = await IOOverrides.runWithIOOverrides(
        () => store.put([1, 2, 3]), overrides);
    final restored = await store.get(retained.id);
    addTearDown(restored!.release);
    expect(await restored.readBytes(), [1, 2, 3]);
    expect(await store.contains(retained.id), isTrue);
  });

  test('rejects a blob whose metadata timestamps keep changing', () async {
    final directory = await Directory.systemTemp.createTemp('history-unstable-');
    addTearDown(() => directory.delete(recursive: true));
    final store =
        await FileAuthoringContentBlobStore.open(projectRoot: directory.path);
    await expectLater(
        IOOverrides.runWithIOOverrides(() => store.put([1, 2, 3]),
            _BlobMetadataOverrides(persistent: true)),
        throwsA(isA<AuthoringContentBlobStoreException>()
            .having((error) => error.code, 'code', 'history.blob_corrupt')));
    expect(await store.listIds(), isEmpty);
  });

  test('rejects changed bytes during a metadata verification retry', () async {
    final directory = await Directory.systemTemp.createTemp('history-race-');
    addTearDown(() => directory.delete(recursive: true));
    final store =
        await FileAuthoringContentBlobStore.open(projectRoot: directory.path);
    await expectLater(
        IOOverrides.runWithIOOverrides(() => store.put([1, 2, 3]),
            _BlobMetadataOverrides(corruptOnSecondStat: true)),
        throwsA(isA<AuthoringContentBlobStoreException>()
            .having((error) => error.code, 'code', 'history.blob_corrupt')));
    expect(await store.listIds(), isEmpty);
  });
}

final class _BlobMetadataOverrides extends IOOverrides {
  _BlobMetadataOverrides(
      {this.persistent = false, this.corruptOnSecondStat = false});

  final bool persistent;
  final bool corruptOnSecondStat;
  var _observations = 0;

  @override
  Future<FileStat> stat(String path) async {
    final result = await super.stat(path);
    if (!path.endsWith('.blob.tmp')) return result;
    _observations++;
    if (corruptOnSecondStat && _observations == 2) {
      await File(path).writeAsBytes([1, 2, 4], flush: true);
    }
    final tick = persistent ? _observations : (_observations == 1 ? 0 : 1);
    return _MetadataFileStat(
        result, DateTime.fromMicrosecondsSinceEpoch(1000000 + tick));
  }
}

final class _MetadataFileStat implements FileStat {
  const _MetadataFileStat(this.original, this.changed);

  final FileStat original;
  @override
  final DateTime changed;
  @override
  DateTime get modified => original.modified;
  @override
  DateTime get accessed => original.accessed;
  @override
  FileSystemEntityType get type => original.type;
  @override
  int get mode => original.mode;
  @override
  int get size => original.size;
  @override
  String modeString() => original.modeString();
}
