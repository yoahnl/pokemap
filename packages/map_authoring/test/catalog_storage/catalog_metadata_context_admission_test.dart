import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/src/catalog_storage/catalog_editing_session.dart';
import 'package:map_authoring/src/catalog_storage/catalog_history_compatibility.dart';
import 'package:map_authoring/src/history/authoring_history.dart';
import 'package:map_authoring/src/catalog_storage/catalog_storage_store.dart';
import 'package:map_authoring/src/history/catalog_history_retention.dart';
import 'package:map_authoring/src/history/content_blob_store.dart';
import 'package:map_authoring/src/history/file_history_store.dart';
import 'package:map_authoring/src/support/authoring_fingerprint.dart';
import 'package:map_authoring/src/transactions/journaled_transaction.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_narrative_event_documents.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late Directory admissions;
  late CatalogStorageStore store;
  late CatalogSnapshot initial;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('metadata-context-');
    final project = await Directory('${directory.path}/project').create();
    admissions = Directory('${directory.path}/admissions');
    store = await CatalogStorageStore.open(
        projectRoot: project.path, trustedAdmissionDirectory: admissions);
    initial = (await store.publish(
            CatalogStorageBuilder().build([
              _metadata('z', 'last'),
              _metadata('a', 'first'),
              _resource('resource', 'before'),
            ]),
            expectedRootRevision: null))
        .snapshot;
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  Future<String?> revision(CatalogSnapshot snapshot) async =>
      await store.metadataContextRevision(snapshot);

  Future<String> prepare(CatalogSnapshot snapshot) async =>
      await store.gateway.withExclusiveWriteLock(
          () async => await store.prepareMetadataContextUnderLock(snapshot));

  Future<CatalogSnapshot> transition(
      CatalogSnapshot before, List<CatalogDefinitionUnit> upserts,
      {List<CatalogDefinitionKey> removals = const []}) async {
    final patch = await before.patch(upserts: upserts, removals: removals);
    final next = await patch.nextSnapshot(
        readObject: (ref) async =>
            patch.objects[ref.sha256] ?? await store.readObject(ref));
    await store.gateway.withExclusiveWriteLock(() async {
      await store.publishObjectsUnderLock(patch.objects);
      await store.publishIndexAdmissionUnderLock(next);
      await store.publishMetadataContextTransitionUnderLock(
          before: before,
          after: next,
          changedKeys: [...upserts.map((unit) => unit.key), ...removals]);
    });
    return next;
  }

  test('explicit initial identity is canonical and leaves project bytes intact',
      () async {
    final before = await _files(store.projectRoot);
    final token = await prepare(initial);
    final metadata = [_metadata('a', 'first'), _metadata('z', 'last')];
    expect(
        token,
        computeAuthoringJsonFingerprint({
          'contextVersion': 1,
          'units': [
            for (final unit in metadata) [unit.key.toJson(), _fingerprint(unit)]
          ]
        }, logicalName: 'catalog-metadata-context.json'));
    expect(await prepare(initial), token);
    expect(await _files(store.projectRoot), before);
    final reordered = CatalogStorageBuilder().build([
      _resource('other', 'unrelated'),
      ...metadata.reversed,
    ]);
    await store.publishObjectsUnderLock(reordered.objects);
    final sameMetadata = (await store.openRoot(reordered.root)).snapshot;
    await sameMetadata.validate();
    expect(await prepare(sameMetadata), token);
  });

  test('metadata delta changes identity and includes complete unit references',
      () async {
    final previous = await prepare(initial);
    final changed = _metadata('a', 'first', references: [_key('resource')]);
    final next = await transition(initial, [changed]);
    expect(
        await revision(next),
        computeAuthoringJsonFingerprint({
          'contextVersion': 1,
          'previous': previous,
          'deltas': [
            [
              changed.key.toJson(),
              _fingerprint(_metadata('a', 'first')),
              _fingerprint(changed)
            ]
          ],
        }, logicalName: 'catalog-metadata-context-delta.json'));
    expect(await revision(next), isNot(previous));
  });

  test('map resource and metadata noops preserve the token', () async {
    final token = await prepare(initial);
    final next = await transition(
        initial, [_resource('resource', 'after'), _metadata('a', 'first')]);
    expect(await revision(next), token);
  });

  test('metadata insertion and deletion use sorted effective deltas', () async {
    final token = await prepare(initial);
    final added = _metadata('m', 'middle');
    final next = await transition(initial, [added],
        removals: [_metadata('z', 'last').key]);
    expect(
        await revision(next),
        computeAuthoringJsonFingerprint({
          'contextVersion': 1,
          'previous': token,
          'deltas': [
            [added.key.toJson(), null, _fingerprint(added)],
            [
              _metadata('z', 'last').key.toJson(),
              _fingerprint(_metadata('z', 'last')),
              null
            ],
          ],
        }, logicalName: 'catalog-metadata-context-delta.json'));
  });

  test('an already attested target keeps its existing identity', () async {
    final token = await prepare(initial);
    final next = await transition(initial, [_metadata('a', 'changed')]);
    final back = await transition(next, [_metadata('a', 'first')]);
    expect(back.root, initial.root);
    expect(await revision(back), token);
  });

  test('the v3 producer cannot attest context1 or refresh a stale identity',
      () async {
    await store.publishMetadataIndexAdmissionUnderLock(initial);
    expect(await revision(initial), isNull);
    final token = await prepare(initial);
    final next = await transition(initial, [_metadata('a', 'changed')]);
    await store.publishMetadataIndexAdmissionUnderLock(next);
    expect(await revision(next), isNot(token));
  });

  test('missing context never triggers a global preparation on mutation',
      () async {
    final next = await transition(initial, [_metadata('a', 'changed')]);
    expect(await revision(initial), isNull);
    expect(await revision(next), isNull);
  });

  test('context corruption fails without modifying the project', () async {
    await prepare(initial);
    final before = await _files(store.projectRoot);
    final file = await _contextFile(admissions, initial.root.sha256);
    final original = await file.readAsString();
    for (final field in [
      'metadataRevision',
      'contextVersion',
      'projectRoot',
      'limits'
    ]) {
      final value = jsonDecode(original) as Map<String, dynamic>;
      final admission = value['admission'] as Map<String, dynamic>;
      switch (field) {
        case 'metadataRevision':
          value[field] = 'sha256:${'0' * 64}';
        case 'contextVersion':
          admission[field] = 2;
        case 'projectRoot':
          admission[field] = directory.path;
        case 'limits':
          (admission[field] as List)[0] = 1;
      }
      if (field != 'metadataRevision') {
        value['fingerprint'] = computeAuthoringJsonFingerprint({
          'admission': value['admission'],
          'metadataRevision': value['metadataRevision'],
        }, logicalName: 'trusted-catalog-metadata-context.json');
      }
      await file.writeAsString(canonicalAuthoringJson(value));
      await expectLater(revision(initial), throwsFormatException);
      expect(await _files(store.projectRoot), before);
    }
    await file.writeAsString('$original\n');
    await expectLater(revision(initial), throwsFormatException);
    expect(await _files(store.projectRoot), before);
  });

  test('a context admission belongs to the exact local project and limits',
      () async {
    await prepare(initial);
    final other = await Directory('${directory.path}/other').create();
    final foreign = await CatalogStorageStore.open(
        projectRoot: other.path, trustedAdmissionDirectory: admissions);
    await foreign.publishObjectsUnderLock(CatalogStorageBuilder().build([
      _metadata('z', 'last'),
      _metadata('a', 'first'),
      _resource('resource', 'before')
    ]).objects);
    final foreignSnapshot = (await foreign.openRoot(initial.root)).snapshot;
    expect(await foreign.metadataContextRevision(foreignSnapshot), isNull);
    final limited = await CatalogStorageStore.open(
        projectRoot: store.projectRoot,
        limits: CatalogStorageLimits(maxDefinitions: 1000),
        trustedAdmissionDirectory: admissions);
    final limitedSnapshot = (await limited.openRoot(initial.root)).snapshot;
    expect(await limited.metadataContextRevision(limitedSnapshot), isNull);
  });

  test('context publication precedes HEAD and undo redo preserve identities',
      () async {
    final token = await prepare(initial);
    final session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'author',
        incrementalHistory: true);
    addTearDown(session.close);
    final plan = await session.planPatch(
        upserts: [_metadata('a', 'changed')], idempotencyKey: 'metadata');
    expect(await store.readHead(), initial.root);
    final target = (await store.openRoot(plan.root)).snapshot;
    final after = await revision(target);
    expect(after, isNotNull);
    expect(after, isNot(token));
    final receipt = await session.apply(plan);
    await session.undo(entryId: receipt.receiptId, idempotencyKey: 'undo');
    expect(await revision(session.snapshot), token);
    await session.redo(entryId: receipt.receiptId, idempotencyKey: 'redo');
    expect(await revision(session.snapshot), after);
  });

  test(
      'required recovery refuses when both context records disappear after open',
      () async {
    await prepare(initial);
    var session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'author',
        metadataContextRequired: true,
        faultInjector: (context) {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterReservation) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    final plan = await session.planPatch(
        upserts: [_metadata('a', 'changed')],
        idempotencyKey: 'strict-recovery');
    await expectLater(session.apply(plan),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    await session.close();
    session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'author',
        metadataContextRequired: true);
    addTearDown(session.close);
    await (await _contextFile(admissions, initial.root.sha256)).delete();
    await (await _contextFile(admissions, plan.root.sha256)).delete();
    await expectLater(
        session.reconcile(plan.operationId),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.preparation_required')));
    expect(await store.readHead(), initial.root);
    expect(await store.gateway.readJournal(plan.operationId), isNotNull);
  });

  for (final compensate in [false, true]) {
    test('recovery keeps the ${compensate ? 'before' : 'after'} identity',
        () async {
      final token = await prepare(initial);
      var session = await CatalogEditingSession.open(
          store: store,
          projectId: 'game',
          actorId: 'author',
          incrementalHistory: true,
          metadataContextRequired: true,
          faultInjector: (context) {
            if (context.checkpoint ==
                AuthoringTransactionCheckpoint.afterReservation) {
              throw const AuthoringTransactionSimulatedCrash();
            }
          });
      final plan = await session.planPatch(
          upserts: [_metadata('a', 'changed')], idempotencyKey: 'metadata');
      final target = (await store.openRoot(plan.root)).snapshot;
      final after = await revision(target);
      await expectLater(session.apply(plan),
          throwsA(isA<AuthoringTransactionSimulatedCrash>()));
      expect(await store.readHead(), initial.root);
      await session.close();
      session = await CatalogEditingSession.open(
          store: store,
          projectId: 'game',
          actorId: 'author',
          incrementalHistory: true,
          metadataContextRequired: true);
      addTearDown(session.close);
      await session.reconcile(plan.operationId, compensate: compensate);
      expect(await revision(session.snapshot), compensate ? token : after);
    });
  }

  test('a missing historical structural admission requires explicit repair',
      () async {
    await prepare(initial);
    final session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'author',
        incrementalHistory: true,
        metadataContextRequired: true);
    addTearDown(session.close);
    final plan = await session.planPatch(
        upserts: [_metadata('a', 'changed')], idempotencyKey: 'metadata');
    final receipt = await session.apply(plan);
    await for (final entity in admissions.list()) {
      if (entity is! File) continue;
      final value = jsonDecode(await entity.readAsString()) as Map;
      final admission = value['admission'] as Map?;
      if (value.containsKey('storedBytes') &&
          (admission?['root'] as Map?)?['sha256'] == initial.root.sha256) {
        await entity.delete();
      }
    }
    await expectLater(
        session.undo(entryId: receipt.receiptId, idempotencyKey: 'undo'),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.preparation_required')));
    expect(await store.readHead(), plan.root);
  });

  test('explicit full publication preserves context before activating its HEAD',
      () async {
    final token = await prepare(initial);
    final published = await store.publish(
        CatalogStorageBuilder().build([
          _metadata('a', 'complete'),
          _resource('resource', 'complete'),
        ]),
        expectedRootRevision: initial.root.sha256);
    expect(await revision(published.snapshot), isNotNull);
    expect(await revision(published.snapshot), isNot(token));
    expect(
        await revision(published.snapshot), await prepare(published.snapshot));
  });

  test('failed context publication leaves HEAD unchanged and no journal active',
      () async {
    await prepare(initial);
    var session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'author',
        incrementalHistory: true,
        metadataContextRequired: true);
    final plan = await session.planPatch(
        upserts: [_metadata('a', 'changed')], idempotencyKey: 'prepare');
    await session.close();
    final file = await _contextFile(admissions, plan.root.sha256);
    await file.writeAsString('{}');
    session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'author',
        incrementalHistory: true,
        metadataContextRequired: true);
    addTearDown(session.close);
    await expectLater(
        session.planPatch(
            upserts: [_metadata('a', 'changed')], idempotencyKey: 'retry'),
        throwsFormatException);
    expect(await store.readHead(), initial.root);
    expect(await store.gateway.listJournals(), isEmpty);
    await expectLater(
        session.reconcile(plan.operationId),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.operation_unknown')));
  });

  test(
      'metadata context work reads only changed metadata units cold and repeated',
      () async {
    for (final unrelatedCount in [0, 512]) {
      final build = CatalogStorageBuilder().build([
        _metadata('scoped', 'before'),
        for (var i = 0; i < unrelatedCount; i++)
          _resource('unrelated-$i', 'unrelated'),
      ]);
      await store.publishObjectsUnderLock(build.objects);
      var base = (await store.openRoot(build.root)).snapshot;
      await base.validate();
      await store.publishIndexAdmissionUnderLock(base);
      await prepare(base);
      for (var operation = 0; operation < 2; operation++) {
        final upsert = _metadata('scoped', 'after-$operation');
        final patch = await base.patch(upserts: [upsert]);
        await store.publishObjectsUnderLock(patch.objects);
        final patched = await patch.nextSnapshot(readObject: store.readObject);
        await store.publishIndexAdmissionUnderLock(patched);
        final unitReads = <String>[];
        var objectReads = 0;
        Future<List<int>> read(CatalogObjectReference ref) async {
          final bytes = await store.readObject(ref);
          objectReads++;
          final value = jsonDecode(utf8.decode(bytes)) as Map;
          if (value['type'] == 'unit') {
            unitReads.add((value['key'] as Map)['kind'] as String);
          }
          return bytes;
        }

        final coldBase =
            (await store.openRoot(base.root, readObject: read)).snapshot;
        final coldNext =
            (await store.openRoot(patch.root, readObject: read)).snapshot;
        await store.restoreIndexAdmission(coldBase);
        await store.restoreIndexAdmission(coldNext);
        objectReads = 0;
        unitReads.clear();
        await store.publishMetadataContextTransitionUnderLock(
            before: coldBase, after: coldNext, changedKeys: [upsert.key]);
        expect(unitReads, ['catalogMetadata', 'catalogMetadata']);
        expect(objectReads, lessThanOrEqualTo(10));
        objectReads = 0;
        unitReads.clear();
        await store.publishMetadataContextTransitionUnderLock(
            before: coldBase, after: coldNext, changedKeys: [upsert.key]);
        expect(objectReads, 0);
        base = patched;
      }
    }
  });

  test('missing context and resource changes read no units during maintenance',
      () async {
    for (final prepareBase in [false, true]) {
      if (prepareBase) await prepare(initial);
      final patch =
          await initial.patch(upserts: [_resource('resource', 'changed')]);
      await store.publishObjectsUnderLock(patch.objects);
      final next = await patch.nextSnapshot(readObject: store.readObject);
      await store.publishIndexAdmissionUnderLock(next);
      var reads = 0;
      Future<List<int>> read(CatalogObjectReference ref) async {
        reads++;
        return store.readObject(ref);
      }

      final before =
          (await store.openRoot(initial.root, readObject: read)).snapshot;
      final after =
          (await store.openRoot(next.root, readObject: read)).snapshot;
      await store.restoreIndexAdmission(before);
      await store.restoreIndexAdmission(after);
      reads = 0;
      await store.publishMetadataContextTransitionUnderLock(
          before: before, after: after, changedKeys: [_key('resource')]);
      expect(reads, 0);
      expect(
          await revision(after), prepareBase ? await revision(before) : isNull);
    }
  });

  test('revert publishes a metadata identity for its effective delta',
      () async {
    await prepare(initial);
    final session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'author',
        incrementalHistory: true);
    addTearDown(session.close);
    final first = await session.apply(await session.planPatch(
        upserts: [_metadata('a', 'target')], idempotencyKey: 'first'));
    final second = await session.apply(await session.planPatch(
        upserts: [_metadata('a', 'later')], idempotencyKey: 'second'));
    final previous = await revision(session.snapshot);
    final plan = await session.planRevert(
        entryId: first.receiptId,
        expectedHeadEntryId: second.receiptId,
        idempotencyKey: 'revert',
        currentProjectRevision: () async =>
            'sha256:${session.snapshot.root.sha256}',
        validateProjection: (projected, changes) async =>
            computeAuthoringJsonFingerprint(projected.root.toJson(),
                logicalName: 'revert-context-fixture.json'));
    final target = (await store.openRoot(plan.root)).snapshot;
    expect(await revision(target), isNotNull);
    expect(await revision(target), isNot(previous));
    await session.apply(plan);
    expect(
        (await session.snapshot.lookup(_metadata('a', '').key))!
            .payload['value'],
        'target');
  });

  test('required apply refuses a corrupt context before activating HEAD',
      () async {
    await prepare(initial);
    final session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'author',
        metadataContextRequired: true);
    addTearDown(session.close);
    final plan = await session.planPatch(
        upserts: [_metadata('a', 'changed')], idempotencyKey: 'strict');
    await (await _contextFile(admissions, plan.root.sha256))
        .writeAsString('{}');
    await expectLater(session.apply(plan), throwsFormatException);
    expect(await store.readHead(), initial.root);
    expect(await store.gateway.listJournals(), isEmpty);
  });

  test(
      'legacy undo keeps its safe fallback without implicitly creating context',
      () async {
    final session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'author',
        incrementalHistory: true);
    addTearDown(session.close);
    final plan = await session.planPatch(
        upserts: [_metadata('a', 'changed')], idempotencyKey: 'legacy');
    final receipt = await session.apply(plan);
    final token = await prepare(session.snapshot);
    await session.undo(entryId: receipt.receiptId, idempotencyKey: 'undo');
    expect(await revision(session.snapshot), isNull);
    await session.redo(entryId: receipt.receiptId, idempotencyKey: 'redo');
    expect(await revision(session.snapshot), token);
  });

  test('optional legacy mutations ignore corrupt context without reusing it',
      () async {
    await prepare(initial);
    await (await _contextFile(admissions, initial.root.sha256))
        .writeAsString('{}');
    final projectBefore = await _files(store.projectRoot);
    await expectLater(
        CatalogEditingSession.open(
            store: store,
            projectId: 'game',
            actorId: 'strict',
            metadataContextRequired: true),
        throwsFormatException);
    expect(await _files(store.projectRoot), projectBefore);
    final session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'author',
        incrementalHistory: true);
    addTearDown(session.close);
    final plan = await session.planPatch(
        upserts: [_metadata('a', 'changed')], idempotencyKey: 'legacy');
    await session.apply(plan);
    expect(await revision(session.snapshot), isNull);
    await expectLater(
        CatalogEditingSession.open(
            store: store,
            projectId: 'game',
            actorId: 'contextual',
            metadataContextRequired: true),
        throwsA(isA<CatalogStorageException>().having(
            (error) => error.code, 'code', 'catalog.preparation_required')));
  });

  test(
      'conversion preparation rejects stale windows and budget overflow intact',
      () async {
    final history = await FileAuthoringHistoryStore.open(
        projectRoot: store.projectRoot, incrementalWrites: true);
    final session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'author',
        history: history,
        incrementalHistory: true);
    addTearDown(session.close);
    final plan = await session.planPatch(
        upserts: [_metadata('a', 'changed')], idempotencyKey: 'metadata');
    final receipt = await session.apply(plan);
    final window = (await history.localWindow('game'))!;
    final before = await _files(store.projectRoot);
    final conversion = AuthoringHistoryCatalogConversion(
        conversion: CatalogHistoryRootConversion(
            source: initial.root,
            target: plan.root,
            additionalBytes: window.maxBytes),
        entryIds: [receipt.receiptId]);
    await expectLater(
        history.prepareCatalogConversions(
            projectId: 'game',
            expectedWindowFingerprint: 'sha256:${'0' * 64}',
            catalogConversions: {initial.root.sha256: conversion}),
        throwsA(isA<AuthoringHistoryException>()
            .having((error) => error.code, 'code', 'history.retention_stale')));
    await expectLater(
        history.prepareCatalogConversions(
            projectId: 'game',
            expectedWindowFingerprint: computeAuthoringJsonFingerprint(
                window.toJson(),
                logicalName: 'catalog-context-history-window.json'),
            catalogConversions: {initial.root.sha256: conversion}),
        throwsA(isA<AuthoringHistoryException>().having((error) => error.code,
            'code', 'history.conversion_exceeds_budget')));
    expect(await _files(store.projectRoot), before);
    expect((await history.localWindow('game'))!.toJson(), window.toJson());
  });

  test('an over-budget navigable preparation publishes no current context',
      () async {
    final units = [_metadata('legacy-budget', 'before')];
    await store.publish(
        CatalogStorageBuilder().build([
          ...units,
          ...CatalogMetadataDocuments.initialize(units).where(
              (unit) => unit.key != CatalogNarrativeEventDocuments.indexKey),
        ]),
        expectedRootRevision: initial.root.sha256);
    final history = await FileAuthoringHistoryStore.open(
        projectRoot: store.projectRoot, incrementalWrites: true);
    final blobs = await FileAuthoringContentBlobStore.open(
        projectRoot: store.projectRoot);
    final session = await CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'author',
        history: history,
        blobs: blobs,
        incrementalHistory: true);
    addTearDown(session.close);
    await session.apply(await session.planPatch(
        upserts: [_metadata('legacy-budget', 'after')],
        idempotencyKey: 'budget'));
    final window = (await history.localWindow('game'))!;
    await history.expireEntries(
        projectId: 'game',
        entryFingerprints: const {},
        maxOperations: window.maxOperations,
        maxBytes: window.logicalBytes + 1,
        cursor: window.cursor,
        retainedCosts: window.costs);
    final before = await _files(store.projectRoot);
    final snapshot = session.snapshot;
    expect(await revision(snapshot), isNull);
    await expectLater(
        CatalogHistoryRetention(store: store, history: history, blobs: blobs)
            .prepareNavigableAdmissions(projectId: 'game'),
        throwsA(isA<AuthoringHistoryException>().having((error) => error.code,
            'code', 'history.conversion_exceeds_budget')));
    expect(await revision(snapshot), isNull);
    expect(await _files(store.projectRoot), before);
    expect(await store.readHead(), snapshot.root);
  });

  for (final undoBusiness in [false, true]) {
    test(
        'explicit legacy history preparation and save after ${undoBusiness ? 'business undo' : 'preparation undo'}',
        () async {
      final source = [_metadata('legacy', 'before')];
      final legacy = CatalogStorageBuilder().build([
        ...source,
        ...CatalogMetadataDocuments.initialize(source).where(
            (unit) => unit.key != CatalogNarrativeEventDocuments.indexKey),
      ]);
      await store.publish(legacy, expectedRootRevision: initial.root.sha256);
      final history = await FileAuthoringHistoryStore.open(
          projectRoot: store.projectRoot, incrementalWrites: true);
      final blobs = await FileAuthoringContentBlobStore.open(
          projectRoot: store.projectRoot);
      final session = await CatalogEditingSession.open(
          store: store,
          projectId: 'game',
          actorId: 'author',
          history: history,
          blobs: blobs,
          incrementalHistory: true);
      addTearDown(session.close);
      await prepare(session.snapshot);
      final edit = await session.planPatch(
          upserts: [_metadata('legacy', 'after')], idempotencyKey: 'legacy');
      final receipt = await session.apply(edit);
      await session.prepareMetadataDocuments(force: true);
      await (await _contextFile(admissions, session.snapshot.root.sha256))
          .delete();
      final before = await _files(store.projectRoot);
      final windowBefore = (await history.localWindow('game'))!;
      expect(windowBefore.catalogConversions, isEmpty);
      final service =
          CatalogHistoryRetention(store: store, history: history, blobs: blobs);
      await service.prepareNavigableAdmissions(projectId: 'game');
      final window = (await history.localWindow('game'))!;
      final activeUnit = _metadata('legacy', 'after');
      expect(
          await revision(session.snapshot),
          computeAuthoringJsonFingerprint({
            'contextVersion': 1,
            'units': [
              [activeUnit.key.toJson(), _fingerprint(activeUnit)]
            ],
          }, logicalName: 'catalog-metadata-context.json'));
      expect(window.entryIds, windowBefore.entryIds);
      expect(window.cursor, windowBefore.cursor);
      expect(window.catalogConversions, isNotEmpty);
      final oldBookkeeping = {...windowBefore.toJson()}
        ..remove('catalogConversions')
        ..remove('schemaVersion');
      final newBookkeeping = {...window.toJson()}
        ..remove('catalogConversions')
        ..remove('schemaVersion');
      expect(newBookkeeping, oldBookkeeping);
      expect(window.toJson()['schemaVersion'], 2);
      await service.prepareNavigableAdmissions(projectId: 'game');
      expect((await history.localWindow('game'))!.toJson(), window.toJson());
      final after = await _files(store.projectRoot);
      for (final entry in before.entries) {
        if (entry.key.endsWith('/history-retention.json')) continue;
        expect(after[entry.key], entry.value, reason: entry.key);
      }
      final preparation = (await history.latestLocalEntry(projectId: 'game'))!;
      await session.undo(
          entryId: preparation.entryId, idempotencyKey: 'undo-prepare');
      expect(await revision(session.snapshot), isNotNull);
      final originalRoot = session.snapshot.root;
      expect(await store.metadataIndexPrepared(session.snapshot), isFalse);
      await session.redo(
          entryId: preparation.entryId, idempotencyKey: 'redo-prepare');
      expect(session.snapshot.root, isNot(originalRoot));
      await session.undo(
          entryId: preparation.entryId, idempotencyKey: 'undo-prepare-again');
      expect(session.snapshot.root, originalRoot);
      if (undoBusiness) {
        await session.undo(
            entryId: receipt.receiptId, idempotencyKey: 'undo-legacy');
      }
      final token = await revision(session.snapshot);
      expect(token, isNotNull);
      final saved = await session.planPatch(
          upserts: [_metadata('legacy', 'saved')], idempotencyKey: 'save');
      await session.apply(saved);
      expect(await revision(session.snapshot), isNot(token));
    });
  }
}

CatalogDefinitionKey _key(String id) =>
    CatalogDefinitionKey(CatalogDefinitionKind.element, id);

CatalogDefinitionUnit _resource(String id, String name) =>
    CatalogDefinitionUnit(key: _key(id), payload: {'id': id, 'name': name});

CatalogDefinitionUnit _metadata(String id, String value,
        {List<CatalogDefinitionKey> references = const []}) =>
    CatalogDefinitionUnit(
        key: CatalogDefinitionKey(CatalogDefinitionKind.catalogMetadata, id),
        payload: {'id': id, 'value': value},
        references: references);

String _fingerprint(CatalogDefinitionUnit unit) =>
    computeAuthoringJsonFingerprint(unit.toJson(),
        logicalName: 'catalog-metadata-unit.json');

Future<Map<String, String>> _files(String path) async => {
      await for (final entity in Directory(path).list(recursive: true))
        if (entity is File && !entity.path.endsWith('.lock'))
          entity.path.substring(path.length):
              base64.encode(await entity.readAsBytes()),
    };

Future<File> _contextFile(Directory directory, String root) async {
  await for (final file in directory.list()) {
    if (file is! File) continue;
    final value = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final admission = value['admission'] as Map?;
    if (admission?['contextVersion'] == 1 &&
        (admission?['root'] as Map?)?['sha256'] == root) {
      return file;
    }
  }
  throw StateError('Missing context admission');
}
