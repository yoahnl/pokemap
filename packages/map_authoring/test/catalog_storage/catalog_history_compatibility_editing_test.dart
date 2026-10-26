import 'dart:io';

import 'package:map_authoring/src/catalog_storage/catalog_editing_session.dart';
import 'package:map_authoring/src/catalog_storage/catalog_storage_store.dart';
import 'package:map_authoring/src/history/catalog_history_retention.dart';
import 'package:map_authoring/src/history/content_blob_store.dart';
import 'package:map_authoring/src/history/file_history_store.dart';
import 'package:map_authoring/src/contracts/authoring_request.dart';
import 'package:map_authoring/src/contracts/authoring_diff.dart';
import 'package:map_authoring/src/contracts/resource_ref.dart';
import 'package:map_authoring/src/security/resource_pack_bulk_capability.dart';
import 'package:map_authoring/src/transactions/journaled_transaction.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_narrative_event_documents.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory fixture;
  late CatalogStorageStore store;
  late FileAuthoringHistoryStore history;
  late FileAuthoringContentBlobStore blobs;
  late CatalogEditingSession session;

  Future<CatalogEditingSession> open(
          {AuthoringTransactionFaultInjector? faultInjector}) =>
      CatalogEditingSession.open(
        store: store,
        projectId: 'game',
        actorId: 'author',
        history: history,
        blobs: blobs,
        incrementalHistory: true,
        faultInjector: faultInjector,
      );

  setUp(() async {
    final root = Directory('/Users/karim/Library/Caches/AveluneQA/'
        'studio-project-lifecycle/history-compatibility-editing-tests');
    await root.create(recursive: true);
    fixture = await root.createTemp('fixture-');
    final project = await Directory('${fixture.path}/project').create();
    store = await CatalogStorageStore.open(
        projectRoot: project.path,
        trustedAdmissionDirectory: Directory('${fixture.path}/admissions'));
    final metadata = CatalogMetadataDocuments.initialize([_unit('a')]);
    final factsKey = CatalogMetadataDocuments.fieldKey('facts');
    await store.publish(
        CatalogStorageBuilder().build([
          _unit('a'),
          for (final unit in metadata)
            if (unit.key != CatalogNarrativeEventDocuments.indexKey)
              unit.key == factsKey
                  ? CatalogDefinitionUnit(
                      key: unit.key,
                      payload: {...unit.payload}
                        ..remove('factRuntimeIdentitiesVersion'))
                  : unit,
        ]),
        expectedRootRevision: null);
    history = await FileAuthoringHistoryStore.open(
        projectRoot: project.path, incrementalWrites: true);
    blobs = await FileAuthoringContentBlobStore.open(projectRoot: project.path);
    session = await open();
  });

  tearDown(() async {
    await session.close();
    await fixture.delete(recursive: true);
  });

  Future<String> edit(String name, {bool bulk = false}) async {
    final before = (await session.snapshot.lookup(_key))!.payload['name'];
    final plan = await session.planPatch(
        upserts: [_unit(name)],
        publicDiff: AuthoringDiff([
          AuthoringDiffEntry(
              operation: AuthoringDiffOperation.replace,
              resource:
                  AuthoringResourceRef(kind: 'catalogHead', id: 'catalog'),
              path: '/elements/item/name',
              before: before,
              after: name),
        ]),
        request: bulk
            ? AuthoringRequest(
                requestId: 'request-$name',
                actionId: 'resource_pack.import',
                actionVersion: 1,
                workspaceHandle: 'workspace',
                expectedRevision: 'sha256:${session.snapshot.root.sha256}',
                idempotencyKey: 'change-$name')
            : null,
        idempotencyKey: 'change-$name');
    if (bulk) {
      plan.plan.bindBulkCapability(ResourcePackBulkAuthority.certifyImport(
          plan: plan.plan,
          actorId: 'author',
          projectId: 'game',
          operationId: plan.operationId,
          logicalStorageKeys: const [],
          contentBlobStorageKeys: const []));
    }
    return (await session.apply(plan)).receiptId;
  }

  for (final bulk in [false, true]) {
    test(
        'old history remains editable and redoable through repeated reopening bulk=$bulk',
        () async {
      final first = await edit('b', bulk: bulk);
      final second = await edit('c', bulk: bulk);
      final originals = {
        for (final id in [first, second])
          id: (await history.get(projectId: 'game', entryId: id))!.toJson(),
      };
      await session.prepareMetadataDocuments(force: true);
      final finalRoot = session.snapshot.root;
      final maintenance =
          CatalogHistoryRetention(store: store, history: history, blobs: blobs);
      final preview = await maintenance.preview(projectId: 'game');
      await maintenance.apply(
          projectId: 'game', expectedFingerprint: preview.fingerprint);
      expect((await history.localWindow('game'))!.entryIds, [first, second]);
      expect(session.snapshot.root, finalRoot);

      for (final pair in [(second, 'b'), (first, 'a')]) {
        await session.undo(entryId: pair.$1, idempotencyKey: 'undo-${pair.$2}');
        final head = await history.latestLocalEntry(projectId: 'game');
        expect(head!.receipt.diff.entries.single.path, '/elements/item/name');
        expect(head.receipt.diff.entries.single.after, pair.$2);
        expect((await session.snapshot.lookup(_key))!.payload['name'], pair.$2);
        final root = session.snapshot.root;
        await session.close();
        session = await open();
        await session.prepareMetadataDocuments();
        expect(session.snapshot.root, root);
        expect(await store.metadataIndexPrepared(session.snapshot), isTrue);
        await session.planPatch(
            upserts: [_unit('draft-${pair.$2}')],
            idempotencyKey: 'plan-after-reopen-${pair.$2}');
        await session.close();
        session = await open();
      }
      for (final pair in [(first, 'b'), (second, 'c')]) {
        await session.redo(entryId: pair.$1, idempotencyKey: 'redo-${pair.$2}');
        await session.close();
        session = await open();
        await session.prepareMetadataDocuments();
        expect((await session.snapshot.lookup(_key))!.payload['name'], pair.$2);
      }
      expect(session.snapshot.root, finalRoot);
      for (final id in originals.keys) {
        expect((await history.get(projectId: 'game', entryId: id))!.toJson(),
            originals[id]);
      }
    });
  }
  for (final bulk in [false, true]) {
    for (final freshAuthority in [false, true]) {
      for (final checkpoint in [
        AuthoringTransactionCheckpoint.afterReservation,
        AuthoringTransactionCheckpoint.afterResourcePromoted,
        AuthoringTransactionCheckpoint.afterJournalCommitted,
      ]) {
        test(
            'converted undo recovers after ${checkpoint.name} fresh=$freshAuthority bulk=$bulk',
            () async {
          await edit('b', bulk: bulk);
          final second = await edit('c', bulk: bulk);
          await session.prepareMetadataDocuments(force: true);
          final maintenance = CatalogHistoryRetention(
              store: store, history: history, blobs: blobs);
          final preview = await maintenance.preview(projectId: 'game');
          await maintenance.apply(
              projectId: 'game', expectedFingerprint: preview.fingerprint);
          await session.close();
          session = await open(faultInjector: (context) {
            if (context.checkpoint == checkpoint) {
              throw const AuthoringTransactionSimulatedCrash();
            }
          });
          final plan = await session.planUndo(
              entryId: second, idempotencyKey: 'crash-converted-undo');
          await expectLater(session.apply(plan),
              throwsA(isA<AuthoringTransactionSimulatedCrash>()));
          await session.close();
          if (freshAuthority) {
            store = await CatalogStorageStore.open(
                projectRoot: store.projectRoot,
                trustedAdmissionDirectory:
                    Directory('${fixture.path}/recovery-admissions'));
            await store.prepareLocalEditing();
          }
          session = await open();
          final receipt = await session.reconcile(plan.operationId);
          expect(receipt, isNotNull);
          expect((await session.snapshot.lookup(_key))!.payload['name'], 'b');
          await session.redo(entryId: second, idempotencyKey: 'redo-recovered');
          expect((await session.snapshot.lookup(_key))!.payload['name'], 'c');
        });
      }
    }
  }
}

final _key = CatalogDefinitionKey(CatalogDefinitionKind.element, 'item');
CatalogDefinitionUnit _unit(String name) =>
    CatalogDefinitionUnit(key: _key, payload: {'name': name});
