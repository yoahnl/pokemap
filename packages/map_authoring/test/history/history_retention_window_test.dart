import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/src/catalog_storage/catalog_history_compatibility.dart';
import 'package:map_authoring/src/catalog_storage/catalog_storage_store.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/src/contracts/authoring_diff.dart';
import 'package:map_authoring/src/contracts/authoring_receipt.dart';
import 'package:map_authoring/src/contracts/resource_ref.dart';
import 'package:map_authoring/src/history/authoring_history.dart';
import 'package:map_authoring/src/history/file_history_store.dart';
import 'package:map_authoring/src/support/authoring_fingerprint.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late FileAuthoringHistoryStore store;

  setUp(() async {
    final task = Directory(
        '/Users/karim/Library/Caches/AveluneQA/studio-project-lifecycle/history-window-tests');
    await task.create(recursive: true);
    directory = await task.createTemp('fixture-');
    store = await FileAuthoringHistoryStore.open(
        projectRoot: directory.path, incrementalWrites: true);
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test(
      'conversion reservations survive reopen and prune with their last original receipt',
      () async {
    final a = CatalogObjectReference(sha256: 'a' * 64, byteLength: 10);
    final b = CatalogObjectReference(sha256: 'b' * 64, byteLength: 20);
    final c = CatalogObjectReference(sha256: 'c' * 64, byteLength: 30);
    final d = CatalogObjectReference(sha256: 'd' * 64, byteLength: 40);
    final e = CatalogObjectReference(sha256: 'e' * 64, byteLength: 50);
    final f = CatalogObjectReference(sha256: 'f' * 64, byteLength: 60);
    final first = _catalogEntry(1, a, b);
    final second = _catalogEntry(2, b, c);
    await store.append(first);
    await store.append(second);
    final row = AuthoringHistoryCatalogConversion(
        conversion: CatalogHistoryRootConversion(
            source: b, target: d, additionalBytes: 73),
        entryIds: [first.entryId, second.entryId]);
    await store.expireEntries(
        projectId: 'project',
        entryFingerprints: {},
        maxOperations: 2,
        catalogConversions: {b.sha256: row});
    final original = await store.localWindow('project');
    expect(original!.toJson()['schemaVersion'], 2);
    expect(original.conversionBytes, 73);
    expect(original.logicalBytes,
        original.objectBytes + 73 + original.recordBytes);
    store = await FileAuthoringHistoryStore.open(
        projectRoot: directory.path,
        incrementalWrites: true,
        onFullRead: () =>
            fail('Full history replay for converted rolling window'));
    expect(
        (await store.historyConversion(projectId: 'project', source: b))!
            .target,
        d);
    final third = _catalogEntry(3, c, e);
    await store.appendWithRetention(third, costs: {'blob:${'1' * 64}': 1});
    expect(
        (await store.localWindow('project'))!
            .catalogConversions[b.sha256]!
            .entryIds,
        {second.entryId});
    await store.appendWithRetention(_catalogEntry(4, e, f),
        costs: {'blob:${'2' * 64}': 1});
    expect((await store.localWindow('project'))!.catalogConversions, isEmpty);
    expect(
        await store.historyConversion(projectId: 'project', source: b), isNull);
    expect(
        (await store.get(projectId: 'project', entryId: first.entryId))!
            .receipt
            .toJson(),
        first.receipt.toJson());
  });

  test(
      'interrupted conversion publication keeps the previous window and retries exactly',
      () async {
    final a = CatalogObjectReference(sha256: 'a' * 64, byteLength: 10);
    final b = CatalogObjectReference(sha256: 'b' * 64, byteLength: 20);
    final c = CatalogObjectReference(sha256: 'c' * 64, byteLength: 30);
    final entry = _catalogEntry(1, a, b);
    await store.append(entry);
    await store.expireEntries(projectId: 'project', entryFingerprints: {});
    final file =
        File('${directory.path}/.pokemap/authoring/history-retention.json');
    final original = await file.readAsBytes();
    final conversions = {
      a.sha256: AuthoringHistoryCatalogConversion(
          conversion: CatalogHistoryRootConversion(
              source: a, target: c, additionalBytes: 42),
          entryIds: [entry.entryId])
    };
    final fault = _WindowPublishFault();
    await expectLater(
        IOOverrides.runWithIOOverrides(
            () => store.expireEntries(
                projectId: 'project',
                entryFingerprints: {},
                catalogConversions: conversions),
            fault),
        throwsA(anything));
    expect(fault.failed, isTrue);
    expect(await file.readAsBytes(), original);
    expect((await store.localWindow('project'))!.catalogConversions, isEmpty);
    await store.expireEntries(
        projectId: 'project',
        entryFingerprints: {},
        catalogConversions: conversions);
    final reopened = await FileAuthoringHistoryStore.open(
        projectRoot: directory.path, incrementalWrites: true);
    expect(
        (await reopened.historyConversion(projectId: 'project', source: a))!
            .target,
        c);
    expect(
        (await reopened.get(projectId: 'project', entryId: entry.entryId))!
            .receipt
            .toJson(),
        entry.receipt.toJson());
  });

  test('conversion links reject an unrelated original HEAD before publication',
      () async {
    final a = CatalogObjectReference(sha256: 'a' * 64, byteLength: 10);
    final b = CatalogObjectReference(sha256: 'b' * 64, byteLength: 20);
    final c = CatalogObjectReference(sha256: 'c' * 64, byteLength: 30);
    final d = CatalogObjectReference(sha256: 'd' * 64, byteLength: 40);
    final entry = _catalogEntry(1, a, b);
    await store.append(entry);
    await expectLater(
        store.expireEntries(
            projectId: 'project',
            entryFingerprints: {},
            catalogConversions: {
              c.sha256: AuthoringHistoryCatalogConversion(
                  conversion: CatalogHistoryRootConversion(
                      source: c, target: d, additionalBytes: 10),
                  entryIds: [entry.entryId])
            }),
        throwsA(isA<AuthoringHistoryException>().having((error) => error.code,
            'code', 'history.retention_inventory_invalid')));
    expect(await store.localWindow('project'), isNull);
    expect(
        (await store.get(projectId: 'project', entryId: entry.entryId))!
            .nonUndoableReason,
        isNull);
  });

  test(
      'old window JSON stays readable and unknown conversion bindings fail closed',
      () async {
    final first = _entry(1);
    await store.append(first);
    await store.expireEntries(projectId: 'project', entryFingerprints: {});
    final old = (await store.localWindow('project'))!.toJson();
    expect(old.containsKey('catalogConversions'), isFalse);
    expect(AuthoringHistoryWindow.fromJson(old).catalogConversions, isEmpty);
    final source = CatalogObjectReference(sha256: 'a' * 64, byteLength: 10);
    final target = CatalogObjectReference(sha256: 'b' * 64, byteLength: 20);
    final malformed = {
      ...old,
      'catalogConversions': {
        source.sha256: AuthoringHistoryCatalogConversion(
            conversion: CatalogHistoryRootConversion(
                source: source, target: target, additionalBytes: 1),
            entryIds: ['missing']).toJson()
      }
    };
    expect(() => AuthoringHistoryWindow.fromJson(malformed),
        throwsFormatException);
  });

  test('unknown future windows refuse append without changing durable bytes',
      () async {
    final first = _entry(1);
    await store.append(first);
    await store.expireEntries(projectId: 'project', entryFingerprints: {});
    final file =
        File('${directory.path}/.pokemap/authoring/history-retention.json');
    final record =
        Map<String, Object?>.from(jsonDecode(await file.readAsString()) as Map)
          ..remove('digest');
    record['schemaVersion'] = 3;
    await file.writeAsString(
        jsonEncode({
          ...record,
          'digest': computeAuthoringJsonFingerprint(record,
              logicalName: 'authoring-history-retention.json')
        }),
        flush: true);
    final original = await file.readAsBytes();
    final sequence = File(
        '${directory.path}/.pokemap/authoring/history-entries.sequence.json');
    final originalSequence = await sequence.readAsBytes();
    await expectLater(
        store.appendWithRetention(_entry(2), costs: {'blob:${'a' * 64}': 1}),
        throwsA(isA<AuthoringHistoryStoreException>().having(
            (error) => error.code, 'code', 'history.version_unsupported')));
    expect(await file.readAsBytes(), original);
    expect(await sequence.readAsBytes(), originalSequence);
  });

  test(
      'legacy writers retain receipt identities without rewriting legacy bytes',
      () async {
    store = await FileAuthoringHistoryStore.open(projectRoot: directory.path);
    final old = _renamed(_entry(1), 'receipt_legacy_old');
    await store.append(old);
    final legacy = File('${directory.path}/.pokemap/authoring/history.jsonl');
    final bytes = await legacy.readAsBytes();
    await store.expireEntries(
        projectId: 'project', entryFingerprints: {}, maxOperations: 1);
    store = await FileAuthoringHistoryStore.open(
        projectRoot: directory.path,
        onFullRead: () => fail('Legacy replay during local append'));
    final fresh = _renamed(_entry(2), 'receipt_legacy_fresh');
    await store.appendWithRetention(fresh, costs: {'blob:${'a' * 64}': 20});
    expect(await legacy.readAsBytes(), bytes);
    expect((await store.latestLocalEntry(projectId: 'project'))!.entryId,
        fresh.entryId);
    expect((await store.localWindow('project'))!.entryIds, [fresh.entryId]);
    await store.appendWithRetention(old, costs: {'blob:${'b' * 64}': 20});
    expect((await store.localWindow('project'))!.entryIds, [fresh.entryId]);
    final changed = old.toJson()..['actorId'] = 'other';
    await expectLater(
        store.appendWithRetention(
            AuthoringHistoryEntry.fromJson(Map<String, dynamic>.from(changed)),
            costs: {}),
        throwsA(isA<AuthoringHistoryStoreException>().having(
            (error) => error.code, 'code', 'history.identity_conflict')));
    expect(await legacy.readAsBytes(), bytes);
  });

  test('global heads permit undo and redo across original scopes', () async {
    final first = _entry(1);
    final second = _scoped(_entry(2), 'sidecar');
    await store.append(first);
    await store.append(second);
    await store.expireEntries(projectId: 'project', entryFingerprints: {});
    final undoSecond =
        _move(3, second, AuthoringHistoryKind.undo, second.entryId);
    await store.appendWithRetention(undoSecond, costs: {});
    expect((await store.latestLocalEntry(projectId: first.projectId))!.entryId,
        undoSecond.entryId);
    final undoFirst =
        _move(4, first, AuthoringHistoryKind.undo, undoSecond.entryId);
    await store.appendWithRetention(undoFirst, costs: {});
    store = await FileAuthoringHistoryStore.open(
        projectRoot: directory.path,
        onFullRead: () => fail('Cross-scope replay'));
    expect((await store.localWindow('sidecar'))!.cursor, 0);
    final redoFirst =
        _move(5, first, AuthoringHistoryKind.redo, undoFirst.entryId);
    await store.appendWithRetention(redoFirst, costs: {});
    final redoSecond =
        _move(6, second, AuthoringHistoryKind.redo, redoFirst.entryId);
    await store.appendWithRetention(redoSecond, costs: {});
    expect((await store.localWindow('project'))!.cursor, 2);
    expect((await store.latestLocalEntry(projectId: 'project'))!.projectId,
        'sidecar');
    expect((await store.entriesForMaintenance()).length, lessThanOrEqualTo(3));
    expect(
        (await store.getLocalEntry(
                projectId: 'sidecar', entryId: second.entryId))!
            .projectId,
        'sidecar');
  });

  test(
      'large inventories compact to fixed operation reservations before publication',
      () async {
    await store.expireEntries(projectId: 'project', entryFingerprints: {});
    final inventory = {
      for (var index = 0; index < 220000; index++)
        'catalog:${index.toRadixString(16).padLeft(64, '0')}': 1
    };
    await store.checkRetentionEntry(_entry(1), costs: inventory);
    await store.appendWithRetention(_entry(1), costs: inventory);
    store = await FileAuthoringHistoryStore.open(
        projectRoot: directory.path,
        onFullRead: () => fail('Large operation inventory replay'));
    await store.appendWithRetention(_entry(2), costs: {'blob:${'a' * 64}': 10});
    final window = (await store.localWindow('project'))!;
    expect(window.costs.values.every((cost) => cost.length == 1), isTrue);
    expect(window.objectBytes, 220010);
    expect(window.recordBytes, lessThan(2048));
    expect(
        await File(
                '${directory.path}/.pokemap/authoring/history-retention.json')
            .length(),
        window.recordBytes);
    final before = window.toJson();
    await expectLater(
        store.appendWithRetention(_entry(3),
            costs: {'blob:${'b' * 64}': 201 * 1024 * 1024}),
        throwsA(isA<AuthoringHistoryException>().having((error) => error.code,
            'code', 'history.operation_exceeds_budget')));
    await expectLater(
        store.appendWithRetention(_entry(3), costs: {'blob:${'c' * 64}': -1}),
        throwsA(isA<AuthoringHistoryException>()));
    expect((await store.localWindow('project'))!.toJson(), before);
    expect(
        await store.getLocalEntry(
            projectId: 'project', entryId: _entry(3).entryId),
        isNull);
  });

  test('explicit maintenance uses the same compact conservative accounting',
      () async {
    await store.append(_entry(1));
    await store.append(_entry(2));
    final shared = {
      for (var index = 0; index < 100000; index++)
        'catalog:${index.toRadixString(16).padLeft(64, '0')}': 1
    };
    final costs = {_entry(1).entryId: shared, _entry(2).entryId: shared};
    final metrics = await store.retentionWindowMetrics(
        projectId: 'project',
        entryIds: [_entry(1).entryId, _entry(2).entryId],
        cursor: 2,
        maxOperations: 50,
        maxBytes: 200 * 1024 * 1024,
        costs: costs);
    expect(metrics.recordBytes, lessThan(2048));
    expect(metrics.logicalBytes, 200000 + metrics.recordBytes);
    await store.expireEntries(
        projectId: 'project', entryFingerprints: {}, retainedCosts: costs);
    final window = (await store.localWindow('project'))!;
    expect(window.logicalBytes, metrics.logicalBytes);
    expect(window.recordBytes, metrics.recordBytes);
    expect(window.costs.values.every((cost) => cost.length == 1), isTrue);
  });

  test('configured maintenance ignores unrelated immutable receipt files',
      () async {
    await store.append(_entry(1));
    await store.expireEntries(projectId: 'project', entryFingerprints: {});
    final entries =
        Directory('${directory.path}/.pokemap/authoring/history-entries');
    for (var index = 0; index < 3; index++) {
      await File('${entries.path}/unrelated-$index.json')
          .writeAsString('corrupt unrelated receipt');
    }
    store = await FileAuthoringHistoryStore.open(
        projectRoot: directory.path,
        onFullRead: () => fail('Maintenance replay'));
    expect((await store.entriesForMaintenance()).map((entry) => entry.entryId),
        [_entry(1).entryId]);
    final window = (await store.localWindow('project'))!;
    final metrics = await store.retentionWindowMetrics(
        projectId: 'project',
        entryIds: window.entryIds,
        cursor: window.cursor,
        maxOperations: window.maxOperations,
        maxBytes: window.maxBytes,
        costs: window.costs);
    expect(metrics.logicalBytes, window.logicalBytes);
    expect(
        metrics.recordBytes,
        await File(
                '${directory.path}/.pokemap/authoring/history-retention.json')
            .length());
    await store.expireEntries(
        projectId: 'project',
        entryFingerprints: {},
        retainedCosts: window.costs);
  });

  test('empty automatic configuration does not replay or migrate old histories',
      () async {
    expect(await store.ensureRetentionWindowIfEmpty('project'), isTrue);
    expect((await store.localWindow('project'))!.entryIds, isEmpty);
    await expectLater(
        store.checkRetentionEntry(_entry(1),
            costs: {'blob:${'f' * 64}': 200 * 1024 * 1024 + 1}),
        throwsA(isA<AuthoringHistoryException>().having((error) => error.code,
            'code', 'history.operation_exceeds_budget')));
    expect((await store.localWindow('project'))!.entryIds, isEmpty);
    expect(
        await File(
                '${directory.path}/.pokemap/authoring/history-entries.sequence.json')
            .exists(),
        isFalse);
    final oldRoot = await directory.createTemp('old-');
    final legacy =
        await FileAuthoringHistoryStore.open(projectRoot: oldRoot.path);
    await legacy.append(_entry(1));
    final cold = await FileAuthoringHistoryStore.open(
        projectRoot: oldRoot.path,
        onFullRead: () => fail('First-save legacy migration'));
    expect(await cold.ensureRetentionWindowIfEmpty('project'), isFalse);
    expect(await cold.localWindow('project'), isNull);
  });

  test('non undoable operations establish a barrier and retain the root head',
      () async {
    await store.expireEntries(projectId: 'project', entryFingerprints: {});
    await store
        .appendWithRetention(_entry(1), costs: {'blob:${'a' * 64}': 100});
    final barrier = _entry(2).markNonUndoable('catalog.partition_not_undoable');
    await store.appendWithRetention(barrier,
        costs: {'blob:${'b' * 64}': 300 * 1024 * 1024});
    expect((await store.localWindow('project'))!.entryIds, isEmpty);
    expect((await store.latestLocalEntry(projectId: 'project'))!.entryId,
        barrier.entryId);
    expect(
        (await store.getLocalEntry(
                projectId: 'project', entryId: _entry(1).entryId))!
            .nonUndoableReason,
        'history.retention_expired');
  });

  test('expiration preserves receipts and uses bounded cold reads', () async {
    for (var index = 0; index < 4; index++) {
      await store.append(_entry(index));
    }
    await store.expireEntries(projectId: 'project', entryFingerprints: {
      for (var index = 0; index < 2; index++)
        _entry(index).entryId: computeAuthoringJsonFingerprint(
            _entry(index).toJson(),
            logicalName: 'authoring-history-entry.json'),
    });
    store = await FileAuthoringHistoryStore.open(
        projectRoot: directory.path,
        incrementalWrites: true,
        onFullRead: () => fail('Unrelated history replay'));
    expect(
        (await store.getLocalEntry(
                projectId: 'project', entryId: _entry(0).entryId))!
            .nonUndoableReason,
        'history.retention_expired');
    expect(
        (await store.getLocalEntry(
                projectId: 'project', entryId: _entry(3).entryId))!
            .nonUndoableReason,
        isNull);
    expect((await store.localWindow('project'))!.entryIds,
        [_entry(2).entryId, _entry(3).entryId]);
  });

  test('new publications evict oldest operations without replaying history',
      () async {
    await store.append(_entry(0));
    await store.expireEntries(
        projectId: 'project',
        entryFingerprints: {},
        maxOperations: 2,
        maxBytes: 10000);
    store = await FileAuthoringHistoryStore.open(
        projectRoot: directory.path,
        incrementalWrites: true,
        onFullRead: () => fail('Unrelated history replay'));
    for (var index = 1; index < 5; index++) {
      await store.appendWithRetention(_entry(index),
          costs: {'blob:${index.toRadixString(16).padLeft(64, '0')}': 100});
    }
    final window = (await store.localWindow('project'))!;
    expect(window.entryIds, [_entry(3).entryId, _entry(4).entryId]);
    expect(window.cursor, 2);
    expect(window.objectBytes, 200);
    expect(window.logicalBytes, 200 + window.recordBytes);
    expect(
        (await store.getLocalEntry(
                projectId: 'project', entryId: _entry(1).entryId))!
            .nonUndoableReason,
        'history.retention_expired');
    await store.appendWithRetention(_entry(1),
        costs: {'blob:${'1'.padLeft(64, '0')}': 100});
    expect((await store.localWindow('project'))!.entryIds, window.entryIds);
  });

  test(
      'oversized operations are rejected and reservations conservatively include shared costs',
      () async {
    await store.expireEntries(
        projectId: 'project',
        entryFingerprints: {},
        maxOperations: 50,
        maxBytes: 4000);
    final shared = 'blob:${'a'.padLeft(64, '0')}';
    await store.appendWithRetention(_entry(1), costs: {shared: 90});
    await store.appendWithRetention(_entry(2), costs: {shared: 90});
    expect((await store.localWindow('project'))!.objectBytes, 180);
    await expectLater(
        store.checkRetentionCosts(projectId: 'project', costs: {shared: 4001}),
        throwsA(isA<AuthoringHistoryException>().having((error) => error.code,
            'code', 'history.operation_exceeds_budget')));
    await expectLater(
        store.appendWithRetention(_entry(3), costs: {shared: 4001}),
        throwsA(isA<AuthoringHistoryException>()));
    expect(
        await store.getLocalEntry(
            projectId: 'project', entryId: _entry(3).entryId),
        isNull);
  });

  test('stale expiration evidence cannot change the window', () async {
    await store.append(_entry(0));
    await expectLater(
        store.expireEntries(
            projectId: 'project',
            entryFingerprints: {_entry(0).entryId: 'sha256:${'0' * 64}'}),
        throwsA(isA<AuthoringHistoryException>()
            .having((error) => error.code, 'code', 'history.retention_stale')));
    expect(await store.localWindow('project'), isNull);
  });

  test('an interrupted window publication requires exact bounded retry',
      () async {
    await store.expireEntries(projectId: 'project', entryFingerprints: {});
    final fault = _WindowPublishFault();
    final costs = {'blob:${'a'.padLeft(64, '0')}': 100};
    await expectLater(
        IOOverrides.runWithIOOverrides(
            () => store.appendWithRetention(_entry(1), costs: costs), fault),
        throwsA(isA<AuthoringHistoryStoreException>()));
    expect(fault.failed, isTrue);
    await expectLater(
        store.localWindow('project'),
        throwsA(isA<AuthoringHistoryException>().having(
            (error) => error.code, 'code', 'history.recovery_required')));
    await expectLater(store.appendWithRetention(_entry(2), costs: costs),
        throwsA(isA<AuthoringHistoryException>()));
    await store.appendWithRetention(_entry(1), costs: costs);
    expect((await store.localWindow('project'))!.entryIds, [_entry(1).entryId]);
    await store.appendWithRetention(_entry(2), costs: costs);
    expect((await store.localWindow('project'))!.entryIds,
        [_entry(1).entryId, _entry(2).entryId]);
  });

  test(
      'the physical store window bounds every historical scope without renaming it',
      () async {
    await store.expireEntries(
        projectId: 'project', entryFingerprints: {}, maxOperations: 1);
    final json = _entry(1).toJson()..['projectId'] = 'sidecar';
    await store.appendWithRetention(
        AuthoringHistoryEntry.fromJson(Map<String, dynamic>.from(json)),
        costs: {'blob:${'a'.padLeft(64, '0')}': 100});
    expect((await store.localWindow('project'))!.entryIds, [_entry(1).entryId]);
    expect(
        (await store.getLocalEntry(
                projectId: 'sidecar', entryId: _entry(1).entryId))!
            .projectId,
        'sidecar');
    await store.appendWithRetention(_entry(2),
        costs: {'blob:${'b'.padLeft(64, '0')}': 100});
    expect((await store.localWindow('sidecar'))!.entryIds, [_entry(2).entryId]);
    expect(
        (await store.getLocalEntry(
                projectId: 'sidecar', entryId: _entry(1).entryId))!
            .nonUndoableReason,
        'history.retention_expired');
  });
}

AuthoringHistoryEntry _renamed(AuthoringHistoryEntry entry, String id) {
  final json = entry.toJson()..['entryId'] = id;
  (json['receipt'] as Map)['receiptId'] = id;
  return AuthoringHistoryEntry.fromJson(Map<String, dynamic>.from(json));
}

AuthoringHistoryEntry _scoped(AuthoringHistoryEntry entry, String project) =>
    AuthoringHistoryEntry.fromJson(
        Map<String, dynamic>.from(entry.toJson()..['projectId'] = project));

AuthoringHistoryEntry _move(int index, AuthoringHistoryEntry origin,
    AuthoringHistoryKind kind, String head) {
  final json = _entry(index).toJson()
    ..['projectId'] = origin.projectId
    ..['kind'] = kind.wireName
    ..['targetEntryId'] = origin.entryId;
  (json['receipt'] as Map)['extensions'] = {
    'history': AuthoringHistoryContext(
            kind: kind,
            targetEntryId: origin.entryId,
            expectedHeadEntryId: head)
        .toJson()
  };
  return AuthoringHistoryEntry.fromJson(Map<String, dynamic>.from(json));
}

final class _WindowPublishFault extends IOOverrides {
  var failed = false;
  @override
  File createFile(String path) =>
      _WindowFaultFile(super.createFile(path), this);
}

final class _WindowFaultFile implements File {
  _WindowFaultFile(this.inner, this.fault);
  final File inner;
  final _WindowPublishFault fault;
  @override
  String get path => inner.path;
  @override
  Uri get uri => inner.uri;
  @override
  Directory get parent => inner.parent;
  @override
  Future<bool> exists() => inner.exists();
  @override
  Future<int> length() => inner.length();
  @override
  Future<FileStat> stat() => inner.stat();
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
    if (!fault.failed && path.endsWith('/history-retention.json.tmp')) {
      fault.failed = true;
      throw FileSystemException(
          'Injected window publication interruption', path);
    }
    return inner.rename(newPath);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AuthoringHistoryEntry _entry(int index) {
  final resource = AuthoringResourceRef(kind: 'fixture', id: 'item');
  String fingerprint(int value) =>
      'sha256:${value.toRadixString(16).padLeft(64, '0')}';
  final date = DateTime.utc(2026, 10, 26).add(Duration(seconds: index));
  final receipt = AuthoringReceipt(
      receiptId: 'receipt_document_$index',
      requestId: 'request-$index',
      actionId: 'fixture.history',
      actionVersion: 1,
      status: AuthoringReceiptStatus.applied,
      beforeRevision: fingerprint(index + 1),
      afterRevision: fingerprint(index + 2),
      createdAtUtc: date.toIso8601String(),
      diff: AuthoringDiff([
        AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: resource,
            path: '/name',
            before: index,
            after: index + 1)
      ]));
  return AuthoringHistoryEntry(
      entryId: receipt.receiptId,
      projectId: 'project',
      actorId: 'actor',
      planId: 'plan-$index',
      operationId: 'operation-$index',
      kind: AuthoringHistoryKind.mutation,
      receipt: receipt,
      committedAt: date,
      changes: [
        AuthoringHistoryResourceChange(
            resource: resource,
            storageKey: 'data/item.json',
            beforeRevision: fingerprint(index + 1),
            afterRevision: fingerprint(index + 2),
            beforeBlobId: fingerprint(index + 10),
            afterBlobId: fingerprint(index + 11))
      ]);
}

AuthoringHistoryEntry _catalogEntry(
    int index, CatalogObjectReference before, CatalogObjectReference after) {
  final json = _entry(index).toJson();
  final change = (json['changes'] as List).single as Map;
  String revision(CatalogObjectReference root) =>
      computeAuthoringBytesFingerprint(CatalogStorageStore.encodeHead(root),
          logicalName: CatalogStorageStore.headStorageKey);
  change['storageKey'] = CatalogStorageStore.headStorageKey;
  change['beforeRevision'] = revision(before);
  change['afterRevision'] = revision(after);
  change['beforeBlobId'] = revision(before);
  change['afterBlobId'] = revision(after);
  return AuthoringHistoryEntry.fromJson(Map<String, dynamic>.from(json));
}
