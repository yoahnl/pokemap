import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/src/contracts/authoring_diff.dart';
import 'package:map_authoring/src/contracts/authoring_receipt.dart';
import 'package:map_authoring/src/contracts/resource_ref.dart';
import 'package:map_authoring/src/history/authoring_history.dart';
import 'package:map_authoring/src/history/file_history_store.dart';
import 'package:test/test.dart';

void main() {
  late Directory project;
  setUp(() async {
    project = await Directory.systemTemp.createTemp('history-incremental-');
  });
  tearDown(() => project.delete(recursive: true));

  test('cold local head and entry reads do not replay 900 unrelated entries',
      () async {
    var fullReads = 0;
    var store = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
        incrementalWrites: true,
        onFullRead: () => fullReads++);
    for (var index = 0; index < 900; index++) {
      await store.append(_entry(index));
    }
    store = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
        incrementalWrites: true,
        onFullRead: () => fullReads++);
    expect((await store.latestLocalEntry(projectId: 'project'))!.entryId,
        'receipt_document_899');
    expect(
        (await store.getLocalEntry(
                projectId: 'project', entryId: 'receipt_document_450'))!
            .entryId,
        'receipt_document_450');
    await store.append(_entry(900));
    expect((await store.latestLocalEntry(projectId: 'project'))!.entryId,
        'receipt_document_900');
    expect(fullReads, 0);
  });

  test('explicit legacy preparation permits bounded cold entry and head lookup',
      () async {
    final legacy =
        await FileAuthoringHistoryStore.open(projectRoot: project.path);
    await legacy.append(_entry(1));
    await legacy.append(_entry(2));
    var fullReads = 0;
    var store = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
        incrementalWrites: true,
        onFullRead: () => fullReads++);
    await expectLater(
        store.latestLocalEntry(projectId: 'project'),
        throwsA(isA<AuthoringHistoryException>().having(
            (error) => error.code, 'code', 'history.preparation_required')));
    expect(fullReads, 0);
    await store.prepareLocalHistory();
    expect(fullReads, 1);
    store = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
        incrementalWrites: true,
        onFullRead: () => fullReads++);
    expect((await store.latestLocalEntry(projectId: 'project'))!.entryId,
        'receipt_document_2');
    expect(
        (await store.getLocalEntry(
                projectId: 'project', entryId: 'receipt_document_1'))!
            .entryId,
        'receipt_document_1');
    await store.append(_entry(3));
    await store.prepareLocalHistory();
    expect(fullReads, 1);
  });

  test('a local head publication interruption is repaired by a bounded retry',
      () async {
    final store = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
        incrementalWrites: true,
        onFullRead: () => throw StateError('global history read'));
    final fault = _HistoryPublishFault('local-head');
    await IOOverrides.runWithIOOverrides(() async {
      await expectLater(store.append(_entry(1)),
          throwsA(isA<AuthoringHistoryStoreException>()));
    }, fault);
    expect(fault.failed, isTrue);
    await expectLater(
        store.latestLocalEntry(projectId: 'project'),
        throwsA(isA<AuthoringHistoryException>().having(
            (error) => error.code, 'code', 'history.preparation_required')));
    await store.append(_entry(1));
    expect((await store.latestLocalEntry(projectId: 'project'))!.entryId,
        'receipt_document_1');
  });

  test('incremental append never reads the legacy journal', () async {
    final legacy =
        await FileAuthoringHistoryStore.open(projectRoot: project.path);
    await legacy.append(_entry(0));
    final journal = File('${project.path}/.pokemap/authoring/history.jsonl');
    final before = await journal.readAsBytes();
    final incremental = await FileAuthoringHistoryStore.open(
      projectRoot: project.path,
      incrementalWrites: true,
      onFullRead: () => throw StateError('legacy read tripwire'),
    );
    await incremental.append(_entry(1));
    await File(
            '${project.path}/.pokemap/authoring/history-entries/receipt_document_unrelated.json')
        .writeAsString('invalid unrelated content', flush: true);
    await incremental.append(_entry(2));
    await incremental.append(_entry(1));
    expect(await journal.readAsBytes(), before);
    expect(
        await File(
                '${project.path}/.pokemap/authoring/history-entries/receipt_document_1.json')
            .exists(),
        isTrue);
  });

  test('default open reads mixed entries and maintains a stable mixed cursor',
      () async {
    final legacy =
        await FileAuthoringHistoryStore.open(projectRoot: project.path);
    await legacy.append(_entry(1));
    await legacy.append(_entry(3));
    final incremental = await FileAuthoringHistoryStore.open(
        projectRoot: project.path, incrementalWrites: true);
    await incremental.append(_entry(2));
    await incremental.append(_entry(4));
    final reopened =
        await FileAuthoringHistoryStore.open(projectRoot: project.path);
    final first = await reopened.list(projectId: 'project', limit: 2);
    expect(first.entries.map((entry) => entry.entryId),
        ['receipt_document_4', 'receipt_document_3']);
    await incremental.append(_entry(0));
    await legacy.append(_entry(5));
    final second = await reopened.list(
        projectId: 'project', limit: 2, cursor: first.nextCursor);
    expect(second.entries.map((entry) => entry.entryId),
        ['receipt_document_2', 'receipt_document_1']);
    expect(second.nextCursor, isNull);
    expect(
        (await reopened.list(projectId: 'project', limit: 10))
            .entries
            .map((entry) => entry.entryId),
        [
          'receipt_document_5',
          'receipt_document_4',
          'receipt_document_3',
          'receipt_document_2',
          'receipt_document_1',
          'receipt_document_0'
        ]);
    expect(
        (await reopened.get(
                projectId: 'project', entryId: 'receipt_document_2'))!
            .toJson(),
        _entry(2).toJson());
    await expectLater(
        reopened.list(projectId: 'other', limit: 2, cursor: first.nextCursor),
        throwsA(isA<AuthoringHistoryException>()));
  });

  test('legacy cursor keeps its legacy snapshot after incremental publication',
      () async {
    final legacy =
        await FileAuthoringHistoryStore.open(projectRoot: project.path);
    await legacy.append(_entry(0));
    await legacy.append(_entry(1));
    final page = await legacy.list(projectId: 'project', limit: 1);
    final incremental = await FileAuthoringHistoryStore.open(
        projectRoot: project.path, incrementalWrites: true);
    await incremental.append(_entry(2));
    expect(
        (await legacy.list(
                projectId: 'project', limit: 1, cursor: page.nextCursor))
            .entries
            .single
            .entryId,
        'receipt_document_0');
  });

  test('incremental entry is immutable and first non undoable reason persists',
      () async {
    final incremental = await FileAuthoringHistoryStore.open(
        projectRoot: project.path, incrementalWrites: true);
    await incremental.append(_entry(1));
    final file = File(
        '${project.path}/.pokemap/authoring/history-entries/receipt_document_1.json');
    final before = await file.readAsBytes();
    final reopened =
        await FileAuthoringHistoryStore.open(projectRoot: project.path);
    expect(
        (await reopened.markNonUndoable(
                projectId: 'project',
                entryId: 'receipt_document_1',
                reason: 'history.blob_missing'))
            .nonUndoableReason,
        'history.blob_missing');
    expect(
        (await reopened.markNonUndoable(
                projectId: 'project',
                entryId: 'receipt_document_1',
                reason: 'history.other'))
            .nonUndoableReason,
        'history.blob_missing');
    expect(
        (await reopened.get(
                projectId: 'project', entryId: 'receipt_document_1'))!
            .nonUndoableReason,
        'history.blob_missing');
    expect(await file.readAsBytes(), before);
    await incremental.append(_entry(1));
  });

  test('incremental identity conflicts and corruption fail safely', () async {
    final incremental = await FileAuthoringHistoryStore.open(
        projectRoot: project.path, incrementalWrites: true);
    await incremental.append(_entry(1));
    await expectLater(
        incremental.append(_entry(1, value: 99)),
        throwsA(isA<AuthoringHistoryStoreException>().having(
            (error) => error.code, 'code', 'history.identity_conflict')));
    final file = File(
        '${project.path}/.pokemap/authoring/history-entries/receipt_document_1.json');
    final decoded =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    (decoded['entry'] as Map)['actorId'] = 'changed';
    await file.writeAsString(jsonEncode(decoded), flush: true);
    await expectLater(
        incremental.get(projectId: 'project', entryId: 'receipt_document_1'),
        throwsA(isA<AuthoringHistoryStoreException>()
            .having((error) => error.code, 'code', 'history.store_corrupt')));
    final reopened =
        await FileAuthoringHistoryStore.open(projectRoot: project.path);
    await expectLater(reopened.list(projectId: 'project', limit: 10),
        throwsA(isA<AuthoringHistoryStoreException>()));
  });

  test('default append honors an existing incremental identity', () async {
    final incremental = await FileAuthoringHistoryStore.open(
        projectRoot: project.path, incrementalWrites: true);
    await incremental.append(_entry(1));
    final legacy =
        await FileAuthoringHistoryStore.open(projectRoot: project.path);
    await legacy.append(_entry(1));
    await expectLater(legacy.append(_entry(1, value: 22)),
        throwsA(isA<AuthoringHistoryStoreException>()));
    expect((await legacy.list(projectId: 'project', limit: 10)).entries,
        hasLength(1));
  });

  test('incremental directory symlinks are refused', () async {
    final root = Directory('${project.path}/.pokemap/authoring');
    await root.create(recursive: true);
    final outside = await Directory.systemTemp.createTemp('history-outside-');
    addTearDown(() => outside.delete(recursive: true));
    await Link('${root.path}/history-entries').create(outside.path);
    final store = await FileAuthoringHistoryStore.open(
        projectRoot: project.path, incrementalWrites: true);
    await expectLater(store.append(_entry(1)),
        throwsA(isA<AuthoringHistoryStoreException>()));
    expect(await outside.list().toList(), isEmpty);
  });

  test('mixed readers reject conflicting identities across both formats',
      () async {
    final legacy =
        await FileAuthoringHistoryStore.open(projectRoot: project.path);
    await legacy.append(_entry(1));
    final incremental = await FileAuthoringHistoryStore.open(
        projectRoot: project.path,
        incrementalWrites: true,
        onFullRead: () => throw StateError('legacy read tripwire'));
    await incremental.append(_entry(1, value: 99));
    final reopened =
        await FileAuthoringHistoryStore.open(projectRoot: project.path);
    final conflict = throwsA(isA<AuthoringHistoryStoreException>()
        .having((error) => error.code, 'code', 'history.identity_conflict'));
    await expectLater(
        reopened.get(projectId: 'project', entryId: 'receipt_document_1'),
        conflict);
    await expectLater(reopened.list(projectId: 'project', limit: 10), conflict);
    await expectLater(
        reopened.markNonUndoable(
            projectId: 'project',
            entryId: 'receipt_document_1',
            reason: 'history.blob_missing'),
        conflict);
  });

  test('incremental writes reject legacy receipt identities', () async {
    final store = await FileAuthoringHistoryStore.open(
        projectRoot: project.path, incrementalWrites: true);
    final json = _entry(1).toJson();
    json['entryId'] = 'receipt_legacy';
    (json['receipt'] as Map)['receiptId'] = 'receipt_legacy';
    await expectLater(
        store.append(
            AuthoringHistoryEntry.fromJson(Map<String, dynamic>.from(json))),
        throwsA(isA<AuthoringHistoryException>().having((error) => error.code,
            'code', 'history.incremental_identity_required')));
  });

  test('concurrent incremental stores preserve every entry and generation',
      () async {
    final left = await FileAuthoringHistoryStore.open(
        projectRoot: project.path, incrementalWrites: true);
    final right = await FileAuthoringHistoryStore.open(
        projectRoot: project.path, incrementalWrites: true);
    await Future.wait([
      for (var index = 0; index < 12; index++)
        (index.isEven ? left : right).append(_entry(index))
    ]);
    final reopened =
        await FileAuthoringHistoryStore.open(projectRoot: project.path);
    final listed = await reopened.list(projectId: 'project', limit: 100);
    expect(listed.entries, hasLength(12));
    expect(listed.entries.map((entry) => entry.entryId).toSet(), hasLength(12));
  });

  test('mixed readers reject a deleted intermediate incremental entry',
      () async {
    final store = await FileAuthoringHistoryStore.open(
        projectRoot: project.path, incrementalWrites: true);
    for (var index = 0; index < 3; index++) {
      await store.append(_entry(index));
    }
    await File(
            '${project.path}/.pokemap/authoring/history-entries/receipt_document_1.json')
        .delete();
    final reopened =
        await FileAuthoringHistoryStore.open(projectRoot: project.path);
    final corrupt = throwsA(isA<AuthoringHistoryStoreException>()
        .having((error) => error.code, 'code', 'history.store_corrupt'));
    await expectLater(reopened.list(projectId: 'project', limit: 10), corrupt);
    await expectLater(
        reopened.get(projectId: 'project', entryId: 'receipt_document_2'),
        corrupt);
  });

  for (final phase in ['entry', 'complete-head']) {
    test(
        'pending $phase interruption requires exact retry before another append',
        () async {
      final store = await FileAuthoringHistoryStore.open(
          projectRoot: project.path, incrementalWrites: true);
      final fault = _HistoryPublishFault(phase);
      await expectLater(
          IOOverrides.runWithIOOverrides(() => store.append(_entry(1)), fault),
          throwsA(isA<AuthoringHistoryStoreException>()));
      expect(fault.failed, isTrue);
      final recovery = throwsA(isA<AuthoringHistoryException>()
          .having((error) => error.code, 'code', 'history.recovery_required'));
      await expectLater(store.list(projectId: 'project', limit: 10), recovery);
      await expectLater(
          store.get(projectId: 'project', entryId: 'receipt_document_1'),
          recovery);
      await expectLater(store.append(_entry(2)), recovery);
      await expectLater(
          store.append(_entry(1, value: 22)),
          throwsA(isA<AuthoringHistoryStoreException>().having(
              (error) => error.code, 'code', 'history.identity_conflict')));
      await store.append(_entry(1));
      await store.append(_entry(2));
      final page = await store.list(projectId: 'project', limit: 10);
      expect(page.entries.map((entry) => entry.entryId),
          ['receipt_document_2', 'receipt_document_1']);
      final root =
          Directory('${project.path}/.pokemap/authoring/history-entries');
      final generations = <int>[];
      await for (final file in root.list()) {
        final record = jsonDecode(await File(file.path).readAsString()) as Map;
        generations.add(record['generation'] as int);
      }
      expect(generations..sort(), [1, 2]);
    });
  }
}

final class _HistoryPublishFault extends IOOverrides {
  _HistoryPublishFault(this.phase);

  final String phase;
  var failed = false;
  var headRenames = 0;

  @override
  File createFile(String path) =>
      _HistoryFaultFile(super.createFile(path), this);

  bool failRename(String path) {
    if (failed) return false;
    final entry = path.endsWith('receipt_document_1.json.tmp');
    final head = path.endsWith('history-entries.sequence.json.tmp');
    final localHead =
        path.contains('/history-local-heads/') && path.endsWith('.json.tmp');
    if (head) headRenames++;
    if ((phase == 'local-head' && localHead) ||
        (phase == 'entry' && entry) ||
        (phase == 'complete-head' && head && headRenames == 2)) {
      failed = true;
      return true;
    }
    return false;
  }
}

final class _HistoryFaultFile implements File {
  const _HistoryFaultFile(this.inner, this.fault);

  final File inner;
  final _HistoryPublishFault fault;
  @override
  String get path => inner.path;
  @override
  Uri get uri => inner.uri;
  @override
  Directory get parent => inner.parent;
  @override
  Future<bool> exists() => inner.exists();
  @override
  Future<FileStat> stat() => inner.stat();
  @override
  Future<int> length() => inner.length();
  @override
  Future<String> readAsString({Encoding encoding = utf8}) =>
      inner.readAsString(encoding: encoding);
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) =>
      inner.open(mode: mode);
  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      inner.delete(recursive: recursive);
  @override
  Future<File> rename(String newPath) {
    if (fault.failRename(path)) {
      throw FileSystemException(
          'Injected history publication interruption', path);
    }
    return inner.rename(newPath);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AuthoringHistoryEntry _entry(int index, {int? value}) {
  final resource = AuthoringResourceRef(kind: 'fixture', id: 'item-$index');
  final before = _fingerprint(index + 1);
  final after = _fingerprint(index + 101);
  final now = DateTime.utc(2026, 10, 25, 14, index);
  final receipt = AuthoringReceipt(
      receiptId: 'receipt_document_$index',
      requestId: 'request-$index',
      actionId: 'fixture.history',
      actionVersion: 1,
      status: AuthoringReceiptStatus.applied,
      beforeRevision: before,
      afterRevision: after,
      createdAtUtc: now.toIso8601String(),
      diff: AuthoringDiff([
        AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: resource,
            path: '/value',
            before: index,
            after: value ?? index + 1)
      ]));
  return AuthoringHistoryEntry(
      entryId: receipt.receiptId,
      projectId: 'project',
      actorId: 'actor',
      planId: 'plan-$index',
      operationId: 'operation-$index',
      kind: AuthoringHistoryKind.mutation,
      receipt: receipt,
      committedAt: now,
      changes: [
        AuthoringHistoryResourceChange(
            resource: resource,
            storageKey: 'data/item-$index.json',
            beforeRevision: before,
            afterRevision: after,
            beforeBlobId: _fingerprint(index + 201),
            afterBlobId: _fingerprint(index + 301))
      ]);
}

String _fingerprint(int seed) =>
    'sha256:${seed.toRadixString(16).padLeft(64, '0')}';
