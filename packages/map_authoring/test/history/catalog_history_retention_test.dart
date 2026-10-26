import 'dart:io';

import 'package:map_authoring/src/catalog_storage/catalog_editing_session.dart';
import 'package:map_authoring/src/catalog_storage/catalog_generation_retention.dart';
import 'package:map_authoring/src/catalog_storage/catalog_storage_store.dart';
import 'package:map_authoring/src/history/authoring_history.dart';
import 'package:map_authoring/src/history/catalog_history_retention.dart';
import 'package:map_authoring/src/history/content_blob_store.dart';
import 'package:map_authoring/src/history/file_history_store.dart';
import 'package:map_authoring/src/ports/project_file_reader.dart';
import 'package:map_authoring/src/ports/transaction_file_gateway.dart';
import 'package:map_authoring/src/transactions/file_idempotency_store.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_narrative_event_documents.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late CatalogStorageStore store;
  late FileAuthoringHistoryStore history;
  late FileAuthoringContentBlobStore blobs;
  late CatalogEditingSession session;
  late CatalogHistoryRetention retention;
  var sequence = 0;

  setUp(() async {
    final task = Directory('/Users/karim/Library/Caches/AveluneQA/'
        'studio-project-lifecycle/retention-tests');
    await task.create(recursive: true);
    directory = await task.createTemp('fixture-');
    store = await CatalogStorageStore.open(
        projectRoot: directory.path,
        trustedAdmissionDirectory: Directory('${directory.path}-admissions'));
    history = await FileAuthoringHistoryStore.open(
        projectRoot: directory.path, incrementalWrites: true);
    blobs =
        await FileAuthoringContentBlobStore.open(projectRoot: directory.path);
    await store.publish(
        CatalogStorageBuilder().build([
          _unit('initial'),
          CatalogDefinitionUnit(key: _sharedKey, payload: {'name': 'Shared'})
        ]),
        expectedRootRevision: null);
    session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'author',
        history: history,
        blobs: blobs,
        incrementalHistory: true);
    retention =
        CatalogHistoryRetention(store: store, history: history, blobs: blobs);
  });

  tearDown(() async {
    await session.close();
    await directory.delete(recursive: true);
    final admissions = Directory('${directory.path}-admissions');
    if (await admissions.exists()) await admissions.delete(recursive: true);
  });

  Future<String> edit(String name) async {
    final plan = await session.planPatch(
        upserts: [_unit(name)], idempotencyKey: 'edit-${sequence++}');
    return (await session.apply(plan)).receiptId;
  }

  Future<
      ({
        CatalogStorageStore store,
        FileAuthoringHistoryStore history,
        FileAuthoringContentBlobStore blobs,
        CatalogEditingSession session,
        List<String> businessIds,
        String preparationId
      })> legacyFixture() async {
    final root = Directory('${directory.path}/legacy-conversion');
    await root.create();
    final legacyStore = await CatalogStorageStore.open(
        projectRoot: root.path,
        trustedAdmissionDirectory:
            Directory('${directory.path}-admissions/legacy'));
    final source = [_unit('legacy-initial')];
    await legacyStore.publish(
        CatalogStorageBuilder().build([
          ...source,
          ...CatalogMetadataDocuments.initialize(source).where(
              (unit) => unit.key != CatalogNarrativeEventDocuments.indexKey),
        ]),
        expectedRootRevision: null);
    final legacyHistory = await FileAuthoringHistoryStore.open(
        projectRoot: root.path, incrementalWrites: true);
    final legacyBlobs =
        await FileAuthoringContentBlobStore.open(projectRoot: root.path);
    final legacySession = await CatalogEditingSession.open(
        store: legacyStore,
        projectId: 'legacy-game',
        actorId: 'author',
        history: legacyHistory,
        blobs: legacyBlobs,
        incrementalHistory: true);
    addTearDown(legacySession.close);
    final ids = <String>[];
    for (final name in ['legacy-one', 'legacy-two']) {
      final plan = await legacySession
          .planPatch(upserts: [_unit(name)], idempotencyKey: name);
      ids.add((await legacySession.apply(plan)).receiptId);
    }
    await legacySession.prepareMetadataDocuments(force: true);
    final preparationId =
        (await legacyHistory.latestLocalEntry(projectId: 'legacy-game'))!
            .entryId;
    return (
      store: legacyStore,
      history: legacyHistory,
      blobs: legacyBlobs,
      session: legacySession,
      businessIds: ids,
      preparationId: preparationId
    );
  }

  test(
      'maintenance converts retained legacy roots and expires normalized metadata noops',
      () async {
    final fixture = await legacyFixture();
    final service = CatalogHistoryRetention(
        store: fixture.store, history: fixture.history, blobs: fixture.blobs);
    final before = await fixture.store.readHead();
    final originalReceipt = (await fixture.history
            .get(projectId: 'legacy-game', entryId: fixture.businessIds.first))!
        .receipt
        .toJson();
    final objects = await _objects(Directory(fixture.store.projectRoot));
    final preview = await service.preview(projectId: 'legacy-game');
    expect(preview.retainedEntryIds, fixture.businessIds);
    expect(preview.metadataOnlyExpiredEntryIds, [fixture.preparationId]);
    expect(preview.expiredEntryIds, contains(fixture.preparationId));
    expect(preview.undoCursor, 2);
    expect(preview.catalogConversions, isNotEmpty);
    expect(await _objects(Directory(fixture.store.projectRoot)), objects);
    final applied = await service.apply(
        projectId: 'legacy-game', expectedFingerprint: preview.fingerprint);
    expect(applied.convertedHistoricalGenerations,
        preview.catalogConversions.length);
    expect(applied.historicalGenerationsRequiringPreparation, isEmpty);
    expect(await fixture.store.readHead(), before);
    final window = (await fixture.history.localWindow('legacy-game'))!;
    expect(window.entryIds, fixture.businessIds);
    expect(window.cursor, 2);
    expect(window.catalogConversions.keys, preview.catalogConversions.keys);
    await CatalogGenerationRetention(store: fixture.store).collect(
        projectId: 'legacy-game',
        history: fixture.history,
        blobs: fixture.blobs);
    for (final row in window.catalogConversions.values) {
      await fixture.store.requireHistoryConversion(row.conversion);
      final source =
          (await fixture.store.openRoot(row.conversion.source)).snapshot;
      final target =
          (await fixture.store.openRoot(row.conversion.target)).snapshot;
      expect((await source.indexEntry(_key))!.reference,
          (await target.indexEntry(_key))!.reference);
      expect(await fixture.store.metadataIndexPrepared(source), isFalse);
      expect(await fixture.store.metadataIndexPrepared(target), isTrue);
      await source.objectReferences();
      await target.objectReferences();
    }
    expect(
        (await fixture.history.get(
                projectId: 'legacy-game', entryId: fixture.businessIds.first))!
            .receipt
            .toJson(),
        originalReceipt);
    final nextPreview = await service.preview(projectId: 'legacy-game');
    expect(nextPreview.expiredEntryIds, isEmpty);
    final second = await service.apply(
        projectId: 'legacy-game', expectedFingerprint: nextPreview.fingerprint);
    expect(second.collection.deletedObjects, 0);
    expect(second.deletedHistoryBlobs, 0);
    expect((await fixture.history.localWindow('legacy-game'))!.entryIds,
        fixture.businessIds);
  });

  test(
      'rolling converted history releases source roots only after their last linked receipt expires',
      () async {
    final fixture = await legacyFixture();
    final service = CatalogHistoryRetention(
        store: fixture.store, history: fixture.history, blobs: fixture.blobs);
    final preview = await service.preview(projectId: 'legacy-game');
    await service.apply(
        projectId: 'legacy-game', expectedFingerprint: preview.fingerprint);
    final window = (await fixture.history.localWindow('legacy-game'))!;
    final source = window.catalogConversions.values.first.conversion.source;
    final sourceFile = File(
        '${fixture.store.projectRoot}/catalog/objects/${source.sha256}.json');
    expect(await sourceFile.exists(), isTrue);
    await fixture.history.expireEntries(
        projectId: 'legacy-game',
        entryFingerprints: {},
        maxOperations: 2,
        retainedCosts: window.costs,
        catalogConversions: window.catalogConversions);
    for (final name in ['current-one', 'current-two']) {
      final plan = await fixture.session
          .planPatch(upserts: [_unit(name)], idempotencyKey: name);
      await fixture.session.apply(plan);
    }
    expect(
        (await fixture.history.localWindow('legacy-game'))!.catalogConversions,
        isEmpty);
    final next = await service.preview(projectId: 'legacy-game');
    final collected = await service.apply(
        projectId: 'legacy-game', expectedFingerprint: next.fingerprint);
    expect(collected.collection.deletedObjects, greaterThan(0));
    expect(await sourceFile.exists(), isFalse);
    expect((await fixture.session.snapshot.lookup(_key))!.payload['name'],
        'current-two');
  });

  test(
      'conversion budget overflow refuses before expiration or object publication',
      () async {
    final fixture = await legacyFixture();
    final service = CatalogHistoryRetention(
        store: fixture.store, history: fixture.history, blobs: fixture.blobs);
    final full = await service.preview(projectId: 'legacy-game');
    final objects = await _objects(Directory(fixture.store.projectRoot));
    final before = await fixture.store.readHead();
    final preview = await service.preview(
        projectId: 'legacy-game', maxBytes: full.retainedLogicalBytes - 256);
    expect(preview.blockedReason, 'history.conversion_exceeds_budget');
    await expectLater(
        service.apply(
            projectId: 'legacy-game',
            expectedFingerprint: preview.fingerprint,
            maxBytes: full.retainedLogicalBytes - 256),
        throwsA(isA<AuthoringHistoryException>().having((error) => error.code,
            'code', 'history.conversion_exceeds_budget')));
    expect(await fixture.store.readHead(), before);
    expect(await _objects(Directory(fixture.store.projectRoot)), objects);
    expect((await fixture.history.localWindow('legacy-game'))!.entryIds,
        [...fixture.businessIds, fixture.preparationId]);
  });

  test('preview does not expire or delete and counts a coherent suffix',
      () async {
    final ids = [await edit('one'), await edit('two'), await edit('three')];
    final objects = await _objects(directory);
    final idsBefore = await blobs.listIds();
    final preview =
        await retention.preview(projectId: 'game', maxOperations: 2);
    expect(preview.retainedEntryIds, ids.sublist(1));
    expect(preview.expiredEntryIds, contains(ids.first));
    expect(preview.undoCursor, 2);
    expect(preview.retainedLogicalBytes, greaterThan(0));
    expect(await _objects(directory), objects);
    expect(await blobs.listIds(), idsBefore);
    expect(
        (await history.get(projectId: 'game', entryId: ids.first))!
            .nonUndoableReason,
        isNull);
  });

  test('apply expires undo payloads and retains receipts and current value',
      () async {
    final ids = [await edit('one'), await edit('two'), await edit('three')];
    final preview =
        await retention.preview(projectId: 'game', maxOperations: 1);
    final beforeBlobs = await blobs.listIds();
    final result = await retention.apply(
        projectId: 'game',
        expectedFingerprint: preview.fingerprint,
        maxOperations: 1);
    expect(result.expiredEntryIds, containsAll(ids.take(2)));
    expect(result.collection.deletedObjects, greaterThan(0));
    expect(result.deletedHistoryBlobs, greaterThan(0));
    expect((await blobs.listIds()).length, lessThan(beforeBlobs.length));
    expect(
        (await history.get(projectId: 'game', entryId: ids.first))!
            .nonUndoableReason,
        'history.retention_expired');
    expect((await session.snapshot.lookup(_key))!.payload['name'], 'three');
    await session.undo(entryId: ids.last, idempotencyKey: 'undo-retained');
    expect((await session.snapshot.lookup(_key))!.payload['name'], 'two');
  });

  test('an oversized newest operation is rejected without changing anything',
      () async {
    final id = await edit('oversized');
    final preview = await retention.preview(projectId: 'game', maxBytes: 100);
    expect(preview.blockedReason, 'history.operation_exceeds_budget');
    final objects = await _objects(directory);
    final blobsBefore = await blobs.listIds();
    await expectLater(
        retention.apply(
            projectId: 'game',
            expectedFingerprint: preview.fingerprint,
            maxBytes: 100),
        throwsA(isA<AuthoringHistoryException>()));
    expect(await _objects(directory), objects);
    expect(await blobs.listIds(), blobsBefore);
    expect(
        (await history.get(projectId: 'game', entryId: id))!.nonUndoableReason,
        isNull);
  });

  test('a changed project rejects an obsolete maintenance preview', () async {
    await edit('one');
    final preview = await retention.preview(projectId: 'game');
    await edit('two');
    final before = await _objects(directory);
    await expectLater(
        retention.apply(
            projectId: 'game', expectedFingerprint: preview.fingerprint),
        throwsA(isA<AuthoringHistoryException>()
            .having((error) => error.code, 'code', 'history.retention_stale')));
    expect(await _objects(directory), before);
  });

  test('a prepared edit blocks maintenance without invalidating the plan',
      () async {
    await edit('one');
    final prepared = await session.planPatch(
        upserts: [_unit('two')], idempotencyKey: 'prepared-retention');
    await expectLater(
        retention.preview(projectId: 'game'),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.preparation_active')));
    await session.apply(prepared);
    expect((await session.snapshot.lookup(_key))!.payload['name'], 'two');
  });

  test('live readers keep their expired generation until they close', () async {
    await edit('one');
    final reader =
        await CatalogGenerationRetention(store: store).openSnapshot();
    try {
      await edit('two');
      await edit('three');
      final preview =
          await retention.preview(projectId: 'game', maxOperations: 1);
      await retention.apply(
          projectId: 'game',
          expectedFingerprint: preview.fingerprint,
          maxOperations: 1);
      expect((await reader.snapshot.lookup(_key))!.payload['name'], 'one');
    } finally {
      await reader.close();
    }
    final result = await CatalogGenerationRetention(store: store)
        .collect(projectId: 'game', history: history, blobs: blobs);
    expect(result.deletedObjects, greaterThan(0));
  });

  test('the operation limit has exact 49, 50 and 51 boundaries', () async {
    String? oldest;
    for (var index = 0; index < 49; index++) {
      final id = await edit('name-$index');
      oldest ??= id;
    }
    expect((await retention.preview(projectId: 'game')).retainedEntryIds.length,
        49);
    await edit('name-49');
    expect((await retention.preview(projectId: 'game')).retainedEntryIds.length,
        50);
    await edit('name-50');
    final preview = await retention.preview(projectId: 'game');
    expect(preview.retainedEntryIds.length, 50);
    expect(preview.retainedEntryIds, isNot(contains(oldest)));
    expect(preview.expiredEntryIds, isEmpty);
    expect(
        (await history.get(projectId: 'game', entryId: oldest!))!
            .nonUndoableReason,
        'history.retention_expired');
    expect((await history.localWindow('game'))!.entryIds.length, 50);
  });

  test('the exact byte limit remains valid after moving the undo cursor',
      () async {
    final id = await edit('one');
    final initial = await retention.preview(projectId: 'game');
    var exactBytes = initial.retainedLogicalBytes;
    var exact =
        await retention.preview(projectId: 'game', maxBytes: exactBytes);
    while (exact.retainedLogicalBytes != exactBytes) {
      exactBytes = exact.retainedLogicalBytes;
      exact = await retention.preview(projectId: 'game', maxBytes: exactBytes);
    }
    expect(exact.blockedReason, isNull);
    final below =
        await retention.preview(projectId: 'game', maxBytes: exactBytes - 1);
    expect(below.blockedReason, 'history.operation_exceeds_budget');
    await session.undo(entryId: id, idempotencyKey: 'cursor-undo');
    final undone = await retention.preview(projectId: 'game');
    expect(undone.undoCursor, 0);
    expect(undone.retainedLogicalBytes, initial.retainedLogicalBytes);
    expect(undone.retainedEntryIds, initial.retainedEntryIds);
  });

  test('cleanup can run again after publication and retained undo', () async {
    final ids = [await edit('one'), await edit('two'), await edit('three')];
    final first = await retention.preview(projectId: 'game', maxOperations: 1);
    await retention.apply(
        projectId: 'game',
        expectedFingerprint: first.fingerprint,
        maxOperations: 1);
    await session.undo(
        entryId: ids.last, idempotencyKey: 'repeat-maintenance-undo');
    final second = await retention.preview(projectId: 'game', maxOperations: 1);
    expect(second.retainedEntryIds, [ids.last]);
    expect(second.undoCursor, 0);
    await retention.apply(
        projectId: 'game',
        expectedFingerprint: second.fingerprint,
        maxOperations: 1);
    final third = await retention.preview(projectId: 'game', maxOperations: 1);
    final result = await retention.apply(
        projectId: 'game',
        expectedFingerprint: third.fingerprint,
        maxOperations: 1);
    expect(result.collection.deletedObjects, 0);
    expect(result.deletedHistoryBlobs, 0);
    await session.redo(
        entryId: ids.last, idempotencyKey: 'repeat-maintenance-redo');
    expect((await session.snapshot.lookup(_key))!.payload['name'], 'three');
  });

  test('corrupt unreachable objects fail before expiration or deletion',
      () async {
    final ids = [await edit('one'), await edit('two')];
    final orphan = CatalogStorageBuilder().build([_unit('orphan')]);
    await store.gateway.withExclusiveWriteLock(
        () => store.publishObjectsUnderLock(orphan.objects));
    final preview =
        await retention.preview(projectId: 'game', maxOperations: 1);
    final file =
        File('${directory.path}/catalog/objects/${orphan.root.sha256}.json');
    final bytes = await file.readAsBytes();
    bytes[0] = bytes[0] == 123 ? 91 : 123;
    await file.writeAsBytes(bytes, flush: true);
    final before = await _objects(directory);
    final blobIds = await blobs.listIds();
    await expectLater(
        retention.apply(
            projectId: 'game',
            expectedFingerprint: preview.fingerprint,
            maxOperations: 1),
        throwsA(isA<CatalogStorageException>()
            .having((error) => error.code, 'code', 'catalog.object_corrupt')));
    expect(await _objects(directory), before);
    expect(await blobs.listIds(), blobIds);
    expect(
        (await history.get(projectId: 'game', entryId: ids.first))!
            .nonUndoableReason,
        isNull);
  });
  test('interrupted collection resumes without old-generation replay',
      () async {
    final ids = [await edit('one'), await edit('two'), await edit('three')];
    final faulty = _InterruptedCollectionGateway(store.gateway);
    final maintenance = CatalogHistoryRetention(
        store: CatalogStorageStore(
            projectRoot: directory.path,
            reader: const LocalProjectFileReader(),
            gateway: faulty),
        history: history,
        blobs: blobs);
    final preview =
        await maintenance.preview(projectId: 'game', maxOperations: 1);
    await expectLater(
        maintenance.apply(
            projectId: 'game',
            expectedFingerprint: preview.fingerprint,
            maxOperations: 1),
        throwsA(isA<StateError>()));
    expect(faulty.deletedObjects, 1);
    expect(
        (await history.get(projectId: 'game', entryId: ids.first))!
            .nonUndoableReason,
        'history.retention_expired');
    final retry =
        await maintenance.preview(projectId: 'game', maxOperations: 1);
    await maintenance.apply(
        projectId: 'game',
        expectedFingerprint: retry.fingerprint,
        maxOperations: 1);
    await session.undo(
        entryId: ids.last, idempotencyKey: 'undo-after-cleanup-crash');
    expect((await session.snapshot.lookup(_key))!.payload['name'], 'two');
  });
  test(
      'legacy and incremental receipts retain the same expiration after reopen',
      () async {
    await session.close();
    final legacy =
        await FileAuthoringHistoryStore.open(projectRoot: directory.path);
    final old = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'author',
        history: legacy,
        blobs: blobs);
    String legacyId;
    try {
      final plan = await old.planPatch(
          upserts: [_unit('legacy')],
          idempotencyKey: 'legacy-before-retention');
      legacyId = (await old.apply(plan)).receiptId;
    } finally {
      await old.close();
    }
    await history.prepareLocalHistory();
    await FileIdempotencyStore(
            filePath: '${directory.path}/.pokemap/authoring/idempotency.jsonl')
        .prepareIncrementalStorage();
    session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'author',
        history: history,
        blobs: blobs,
        incrementalHistory: true);
    final retainedId = await edit('incremental');
    final preview =
        await retention.preview(projectId: 'game', maxOperations: 1);
    expect(preview.expiredEntryIds, contains(legacyId));
    await retention.apply(
        projectId: 'game',
        expectedFingerprint: preview.fingerprint,
        maxOperations: 1);
    final reopened = await FileAuthoringHistoryStore.open(
        projectRoot: directory.path, incrementalWrites: true);
    expect(
        (await reopened.get(projectId: 'game', entryId: legacyId))!
            .nonUndoableReason,
        'history.retention_expired');
    expect(
        (await reopened.get(projectId: 'game', entryId: retainedId))!
            .nonUndoableReason,
        isNull);
    final again = await CatalogHistoryRetention(
            store: store, history: reopened, blobs: blobs)
        .preview(projectId: 'game', maxOperations: 1);
    expect(again.retainedEntryIds, [retainedId]);
  });
  test('maintenance keeps the authoritative prefix after a divergent edit',
      () async {
    final a = await edit('A');
    final b = await edit('B');
    final initial = await retention.preview(projectId: 'game');
    await retention.apply(
        projectId: 'game', expectedFingerprint: initial.fingerprint);
    await session.undo(entryId: b, idempotencyKey: 'branch-undo-B');
    final c = await edit('C');
    final preview = await retention.preview(projectId: 'game');
    expect(preview.retainedEntryIds, [a, c]);
    expect(preview.undoCursor, 2);
    await retention.apply(
        projectId: 'game', expectedFingerprint: preview.fingerprint);
    await session.undo(entryId: c, idempotencyKey: 'branch-undo-C');
    final afterUndo = await retention.preview(projectId: 'game');
    expect(afterUndo.retainedEntryIds, [a, c]);
    expect(afterUndo.undoCursor, 1);
    await session.redo(entryId: c, idempotencyKey: 'branch-redo-C');
    expect((await session.snapshot.lookup(_key))!.payload['name'], 'C');
  });
  test('pending sidecar namespaces block maintenance before expiration',
      () async {
    final id = await edit('one');
    final pending = File('${directory.path}/.pokemap/authoring/transactions/'
        'editor_namespace/sidecar-operation/journal.json');
    await pending.parent.create(recursive: true);
    await pending.writeAsString('{}', flush: true);
    final before = await _objects(directory);
    final blobIds = await blobs.listIds();
    await expectLater(
        retention.preview(projectId: 'game'),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.recovery_required')));
    expect(await _objects(directory), before);
    expect(await blobs.listIds(), blobIds);
    expect(
        (await history.get(projectId: 'game', entryId: id))!.nonUndoableReason,
        isNull);
  });
  test('maintenance reads shared immutable objects once across retained roots',
      () async {
    await edit('one');
    await edit('two');
    await edit('three');
    final shared = (await session.snapshot.indexEntry(_sharedKey))!.reference;
    final reader = _CountingProjectReader();
    final observed = CatalogStorageStore(
        projectRoot: directory.path, reader: reader, gateway: store.gateway);
    final preview = await CatalogHistoryRetention(
            store: observed, history: history, blobs: blobs)
        .preview(projectId: 'game');
    expect(preview.retainedEntryIds.length, 3);
    expect(reader.reads['catalog/objects/${shared.sha256}.json'], 1);
  });

  test('fresh collection verification rejects a corrupted cached shared object',
      () async {
    final ids = [await edit('one'), await edit('two')];
    final preview =
        await retention.preview(projectId: 'game', maxOperations: 1);
    final shared = (await session.snapshot.indexEntry(_sharedKey))!.reference;
    final sharedPath = 'catalog/objects/${shared.sha256}.json';
    var corrupted = false;
    final reader = _CountingProjectReader(afterRead: (path) async {
      if (path == sharedPath && !corrupted) {
        corrupted = true;
        final file = File('${directory.path}/$sharedPath');
        final bytes = await file.readAsBytes();
        bytes[0] = 91;
        await file.writeAsBytes(bytes, flush: true);
      }
    });
    final observed = CatalogStorageStore(
        projectRoot: directory.path, reader: reader, gateway: store.gateway);
    final before = await _objects(directory);
    final blobIds = await blobs.listIds();
    await expectLater(
        CatalogHistoryRetention(store: observed, history: history, blobs: blobs)
            .apply(
                projectId: 'game',
                expectedFingerprint: preview.fingerprint,
                maxOperations: 1),
        throwsA(isA<CatalogStorageException>()
            .having((error) => error.code, 'code', 'catalog.object_corrupt')));
    expect(corrupted, isTrue);
    expect(reader.reads[sharedPath], greaterThanOrEqualTo(2));
    expect(await _objects(directory), before);
    expect(await blobs.listIds(), blobIds);
    expect(
        (await history.get(projectId: 'game', entryId: ids.first))!
            .nonUndoableReason,
        isNull);
  });
  test('explicit maintenance admits cold historical creation undo safely',
      () async {
    await session.prepareMetadataDocuments(force: true);
    final target = session.snapshot;
    final created =
        CatalogDefinitionKey(CatalogDefinitionKind.element, 'created');
    final plan = await session.planPatch(upserts: [
      CatalogDefinitionUnit(key: created, payload: {'name': 'Created'})
    ], idempotencyKey: 'cold-created');
    final receipt = await session.apply(plan);
    final freshStore = await CatalogStorageStore.open(
        projectRoot: directory.path,
        trustedAdmissionDirectory:
            Directory('${directory.path}-admissions/fresh'));
    await freshStore.prepareLocalEditing();
    final cold = await CatalogEditingSession.open(
        store: freshStore,
        projectId: 'game',
        actorId: 'fresh',
        history: history,
        blobs: blobs,
        incrementalHistory: true);
    try {
      await expectLater(
          cold.undo(
              entryId: receipt.receiptId,
              idempotencyKey: 'before-explicit-maintenance'),
          throwsA(anything));
      await expectLater(freshStore.restoreIndexAdmission(target),
          throwsA(isA<CatalogStorageException>()));
      final maintenance = CatalogHistoryRetention(
          store: freshStore, history: history, blobs: blobs);
      final preview = await maintenance.preview(projectId: 'game');
      expect(await freshStore.metadataIndexPrepared(target), isFalse);
      final result = await maintenance.apply(
          projectId: 'game', expectedFingerprint: preview.fingerprint);
      expect(result.toJson()['preparedHistoricalGenerations'], greaterThan(0));
      await freshStore.restoreIndexAdmission(target);
      expect(await freshStore.metadataIndexPrepared(target), isTrue);
      await cold.undo(
          entryId: receipt.receiptId,
          idempotencyKey: 'after-explicit-maintenance');
      expect(await cold.snapshot.lookup(created), isNull);
      await cold.redo(
          entryId: receipt.receiptId,
          idempotencyKey: 'redo-after-explicit-maintenance');
      expect((await cold.snapshot.lookup(created))!.payload['name'], 'Created');
    } finally {
      await cold.close();
    }
  });

  test('forged extra metadata facets never receive historical admissions',
      () async {
    final nested = Directory('${directory.path}/forged-project');
    await nested.create();
    final original = await CatalogStorageStore.open(
        projectRoot: nested.path,
        trustedAdmissionDirectory:
            Directory('${directory.path}-admissions/forged-origin'));
    final base = [_unit('initial')];
    await original.publish(
        CatalogStorageBuilder().build([
          ...base,
          ...CatalogMetadataDocuments.initialize(base),
          CatalogDefinitionUnit(
              key: CatalogMetadataDocuments.trainerItemKey('forged'),
              payload: {
                'schemaVersion': 1,
                'trainerIds': ['missing-trainer']
              })
        ]),
        expectedRootRevision: null);
    final nestedHistory = await FileAuthoringHistoryStore.open(
        projectRoot: nested.path, incrementalWrites: true);
    final nestedBlobs =
        await FileAuthoringContentBlobStore.open(projectRoot: nested.path);
    final nestedSession = await CatalogEditingSession.open(
        store: original,
        projectId: 'forged-game',
        actorId: 'author',
        history: nestedHistory,
        blobs: nestedBlobs,
        incrementalHistory: true);
    try {
      final historical = nestedSession.snapshot;
      final plan = await nestedSession.planPatch(
          upserts: [_unit('changed')], idempotencyKey: 'forged-edit');
      await nestedSession.apply(plan);
      final fresh = await CatalogStorageStore.open(
          projectRoot: nested.path,
          trustedAdmissionDirectory:
              Directory('${directory.path}-admissions/forged-fresh'));
      await fresh.prepareLocalEditing();
      final maintenance = CatalogHistoryRetention(
          store: fresh, history: nestedHistory, blobs: nestedBlobs);
      final preview = await maintenance.preview(projectId: 'forged-game');
      final result = await maintenance.apply(
          projectId: 'forged-game', expectedFingerprint: preview.fingerprint);
      expect(result.toJson()['historicalGenerationsRequiringPreparation'],
          contains(historical.root.sha256));
      expect(await fresh.metadataIndexPrepared(historical), isFalse);
      await expectLater(fresh.restoreIndexAdmission(historical),
          throwsA(isA<CatalogStorageException>()));
    } finally {
      await nestedSession.close();
    }
  });
}

final _key = CatalogDefinitionKey(CatalogDefinitionKind.element, 'item');
final _sharedKey =
    CatalogDefinitionKey(CatalogDefinitionKind.element, 'shared');

CatalogDefinitionUnit _unit(String name) =>
    CatalogDefinitionUnit(key: _key, payload: {'name': name});

Future<Set<String>> _objects(Directory directory) async => {
      await for (final item
          in Directory('${directory.path}/catalog/objects').list())
        item.uri.pathSegments.last,
    };

final class _InterruptedCollectionGateway implements TransactionFileGateway {
  _InterruptedCollectionGateway(this.delegate);
  final TransactionFileGateway delegate;
  var deletedObjects = 0;
  var interrupted = false;

  @override
  Future<T> withExclusiveWriteLock<T>(Future<T> Function() operation) =>
      delegate.withExclusiveWriteLock(operation);

  @override
  Future<void> promoteStaged(
      {required String operationId,
      required String storageKey,
      required TransactionPayloadKind kind,
      required String? expectedCurrentRevision}) async {
    await delegate.promoteStaged(
        operationId: operationId,
        storageKey: storageKey,
        kind: kind,
        expectedCurrentRevision: expectedCurrentRevision);
    if (storageKey.startsWith('catalog/objects/')) {
      deletedObjects++;
      if (!interrupted) {
        interrupted = true;
        throw StateError('injected collection interruption');
      }
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      switch (invocation.memberName) {
        #listJournals => delegate.listJournals(),
        #readResource =>
          delegate.readResource(invocation.positionalArguments[0] as String),
        #readResourceRevision => delegate
            .readResourceRevision(invocation.positionalArguments[0] as String),
        #deleteTransaction => delegate
            .deleteTransaction(invocation.positionalArguments[0] as String),
        #stagePayload => delegate.stagePayload(
            operationId: invocation.namedArguments[#operationId] as String,
            storageKey: invocation.namedArguments[#storageKey] as String,
            kind: invocation.namedArguments[#kind] as TransactionPayloadKind,
            bytes: invocation.namedArguments[#bytes] as List<int>?),
        _ => super.noSuchMethod(invocation),
      };
}

final class _CountingProjectReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  _CountingProjectReader({this.afterRead});
  final Future<void> Function(String path)? afterRead;
  final reads = <String, int>{};
  final inner = const LocalProjectFileReader();
  @override
  bool get supportsStreamingResources => true;
  @override
  Future<String> canonicalizeDirectory(String path) =>
      inner.canonicalizeDirectory(path);
  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      inner.probeResource(projectRoot: projectRoot, relativePath: relativePath);
  @override
  Future<List<int>> readBytes(
          {required String projectRoot, required String relativePath}) =>
      throw StateError('Unbounded read');
  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) async* {
    reads.update(relativePath, (value) => value + 1, ifAbsent: () => 1);
    yield* inner.openRead(projectRoot: projectRoot, relativePath: relativePath);
    await afterRead?.call(relativePath);
  }
}
