import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/catalog_storage/catalog_revert_merge.dart';
import 'package:map_authoring/src/security/resource_pack_bulk_capability.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late CatalogStorageStore store;
  late CatalogEditingSession session;
  late File map;
  late File asset;

  Future<String> revision() async => computeAuthoringJsonFingerprint({
        'root': (await store.readHead())!.toJson(),
        'map': await map.readAsString(),
        'asset': await asset.readAsString(),
      }, logicalName: 'revert-fixture');

  Future<String> validate(
      CatalogSnapshot projected, List<AuthoringResourceChange> changes) async {
    final catalog = await PortableProjectCatalog.fromSnapshot(projected);
    final project = await catalog.exportProject();
    expect(project.tilesets.take(2).map((entry) => entry.id), ['a', 'b']);
    final change = changes
        .where((entry) => entry.storageKey == 'maps/map.json')
        .firstOrNull;
    final assetChange = changes
        .where((entry) => entry.storageKey == 'assets/picture.bin')
        .firstOrNull;
    return computeAuthoringJsonFingerprint({
      'asset': assetChange == null
          ? await asset.readAsString()
          : await utf8.decodeStream(assetChange.afterPayload!.openRead()),
      'project': project.toJson(),
      'map': change == null
          ? await map.readAsString()
          : await utf8.decodeStream(change.afterPayload!.openRead()),
    }, logicalName: 'revert-inventory');
  }

  Future<AuthoringReceipt> edit(String id, String name,
      {String? mapValue, String? assetValue, bool bulk = false}) async {
    final catalog = await PortableProjectCatalog.fromSnapshot(session.snapshot);
    final unit = (await catalog
        .lookup(CatalogDefinitionKey(CatalogDefinitionKind.tileset, id)))!;
    final updated = catalog.replaceDefinitionValue(unit, {
      ...Map<String, Object?>.from(unit.payload['value']! as Map),
      'name': name,
    });
    final changes = <AuthoringResourceChange>[
      if (mapValue != null)
        AuthoringResourceChange(
            resource: AuthoringResourceRef(kind: 'map', id: 'map'),
            storageKey: 'maps/map.json',
            beforeBytes: await map.readAsBytes(),
            afterBytes: utf8.encode(mapValue)),
    ];
    if (assetValue != null) {
      changes.add(AuthoringResourceChange(
          resource: AuthoringResourceRef(kind: 'asset', id: 'picture'),
          storageKey: 'assets/picture.bin',
          beforeBytes: await asset.readAsBytes(),
          afterBytes: utf8.encode(assetValue)));
    }
    final patch = await session.snapshot.patch(upserts: [updated]);
    final projected = await patch.nextSnapshot(
        readObject: (reference) async =>
            patch.objects[reference.sha256] ??
            await store.readObject(reference));
    final baseRevision = await revision();
    final plan = await session.planPatch(
        upserts: [updated],
        additionalChanges: changes,
        workspaceFingerprint:
            changes.isEmpty ? null : await validate(projected, changes),
        publicBaseRevision: baseRevision,
        currentProjectRevision: revision,
        request: bulk
            ? AuthoringRequest(
                requestId: 'import-$id-$name',
                actionId: 'resource_pack.import',
                actionVersion: 1,
                workspaceHandle: 'workspace',
                expectedRevision: baseRevision,
                idempotencyKey: 'edit-$id-$name')
            : null,
        idempotencyKey: 'edit-$id-$name');
    if (bulk) {
      plan.plan.bindBulkCapability(ResourcePackBulkAuthority.certifyImport(
          plan: plan.plan,
          actorId: 'test',
          projectId: 'game',
          operationId: plan.operationId,
          logicalStorageKeys: changes.map((change) => change.storageKey),
          contentBlobStorageKeys: const []));
    }
    return session.apply(plan);
  }

  Future<ProjectManifest> project() async =>
      (await PortableProjectCatalog.fromSnapshot(session.snapshot))
          .exportProject();

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('catalog-revert-');
    store = await CatalogStorageStore.open(projectRoot: directory.path);
    await WorkingProjectCatalog.create(
        store: store,
        projectId: 'game',
        project: ProjectManifest(name: 'Game', maps: const [], tilesets: [
          const ProjectTilesetEntry(id: 'a', name: 'A', relativePath: 'a.png'),
          const ProjectTilesetEntry(id: 'b', name: 'B', relativePath: 'b.png'),
        ]));
    map = File('${directory.path}/maps/map.json');
    await map.parent.create(recursive: true);
    await map.writeAsString('initial');
    asset = File('${directory.path}/assets/picture.bin');
    await asset.parent.create(recursive: true);
    await asset.writeAsString('initial-asset');
    session = await CatalogEditingSession.open(
        store: store, projectId: 'game', actorId: 'test');
  });
  tearDown(() async {
    await session.close();
    await directory.delete(recursive: true);
  });

  test(
      'revert restores target units and files while preserving independent units',
      () async {
    final target = await edit('a', 'Target', mapValue: 'target-map');
    await edit('a', 'Later', mapValue: 'later-map');
    final head = await edit('b', 'Independent');
    final root = session.snapshot.root;
    final plan = await session.planRevert(
        entryId: target.receiptId,
        expectedHeadEntryId: head.receiptId,
        operationId: 'public_revert',
        idempotencyKey: 'revert',
        publicBaseRevision: await revision(),
        currentProjectRevision: revision,
        validateProjection: validate);
    expect(session.snapshot.root, root);
    expect(await map.readAsString(), 'later-map');
    final receipt = await session.apply(plan, operationId: 'public_revert');
    expect((await session.apply(plan)).toJson(), receipt.toJson());
    expect((await project()).tilesets.map((entry) => entry.name),
        ['Target', 'Independent']);
    expect(await map.readAsString(), 'target-map');
    await session.retention.collect(
        projectId: 'game', history: session.history, blobs: session.blobs);
    await session.undo(
        entryId: receipt.receiptId, idempotencyKey: 'undo-revert');
    expect((await project()).tilesets.map((entry) => entry.name),
        ['Later', 'Independent']);
    expect(await map.readAsString(), 'later-map');
  });

  test('revert refuses stale history and no-op target before publishing',
      () async {
    final target = await edit('a', 'Target');
    await expectLater(
        session.planRevert(
            entryId: target.receiptId,
            expectedHeadEntryId: target.receiptId,
            idempotencyKey: 'noop',
            publicBaseRevision: await revision(),
            currentProjectRevision: revision,
            validateProjection: validate),
        throwsA(isA<AuthoringHistoryException>()
            .having((error) => error.code, 'code', 'history.revert_noop')));
    final head = await edit('a', 'Later');
    await expectLater(
        session.planRevert(
            entryId: target.receiptId,
            expectedHeadEntryId: target.receiptId,
            idempotencyKey: 'stale',
            publicBaseRevision: await revision(),
            currentProjectRevision: revision,
            validateProjection: validate),
        throwsA(isA<AuthoringHistoryException>()
            .having((error) => error.code, 'code', 'history.head_stale')));
    final root = session.snapshot.root;
    await expectLater(
        session.planRevert(
            entryId: target.receiptId,
            expectedHeadEntryId: head.receiptId,
            idempotencyKey: 'invalid',
            publicBaseRevision: await revision(),
            currentProjectRevision: revision,
            validateProjection: (_, __) async =>
                throw const FormatException('invalid projected map')),
        throwsFormatException);
    expect(session.snapshot.root, root);
    expect(await store.gateway.listJournals(), isEmpty);
  });
  test('certified pack revert attests its merged HEAD and rejects forged heads',
      () async {
    final target =
        await edit('a', 'Target', mapValue: 'target-map', bulk: true);
    await edit('a', 'Later', mapValue: 'later-map');
    await edit('b', 'Independent');
    final expanded = PortableCatalogPublication.encodeProject(
        (await project()).copyWith(tilesets: [
      ...(await project()).tilesets,
      const ProjectTilesetEntry(
          id: 'c', name: 'Added independently', relativePath: 'c.png')
    ]));
    final expandedSnapshot = await CatalogSnapshot.open(
        root: expanded.storage.root,
        readObject: (reference) async =>
            expanded.storage.objects[reference.sha256]!);
    final added = (await expandedSnapshot
        .lookup(CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'c')))!;
    final addition = await session
        .planPatch(upserts: [added], idempotencyKey: 'independent-addition');
    final newestHead = await session.apply(addition);
    final current = session.snapshot;
    final plan = await session.planRevert(
        entryId: target.receiptId,
        expectedHeadEntryId: newestHead.receiptId,
        idempotencyKey: 'bulk-revert',
        operationId: 'bulk_revert',
        publicBaseRevision: await revision(),
        currentProjectRevision: revision,
        validateProjection: validate);
    final capability = plan.plan.bulkCapability!;
    expect(capability.catalogRevert, isNotNull);
    expect(capability.catalogRevert!.currentRoot, current.root);
    final proof = capability.catalogRevert!;
    await expectLater(
        CatalogRevertMergeAttestation.verify(
            current: current,
            targetBefore:
                (await store.openRoot(proof.targetBeforeRoot)).snapshot,
            targetAfter: (await store.openRoot(proof.targetAfterRoot)).snapshot,
            result: (await store.openRoot(proof.targetAfterRoot)).snapshot),
        throwsFormatException);
    final forged = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(capability.toJson())) as Map);
    (forged['catalogRevert'] as Map)['resultRoot'] =
        proof.targetAfterRoot.toJson();
    expect(() => ResourcePackBulkCapability.fromJournalJson(forged),
        throwsFormatException);
    final replayed = ResourcePackBulkCapability.fromJournalJson(
        Map<String, dynamic>.from(capability.toJson()));
    expect(replayed.catalogRevert!.verified, isFalse);
    expect(
        () => ResourcePackBulkAuthority.certifyHistory(
            plan: plan.plan,
            actorId: 'test',
            projectId: 'game',
            operationId: plan.operationId,
            originEntryId: target.receiptId,
            origin: capability,
            verifiedInventory: capability.inventory,
            catalogRevert: replayed.catalogRevert),
        throwsArgumentError);
    final forgedDiff = AuthoringDiff([
      for (final entry in plan.plan.changeSet.diff.entries)
        if (entry.resource.kind == 'catalogHead')
          AuthoringDiffEntry.fromJson(
              {...entry.toJson(), 'after': proof.targetAfterHeadRevision})
        else
          entry,
    ]);
    final forgedInventory = forged['inventory'] as List;
    (forgedInventory.singleWhere((item) =>
            (item as Map)['storageKey'] == CatalogStorageStore.headStorageKey)
        as Map)['afterRevision'] = proof.targetAfterHeadRevision;
    forged['inventoryFingerprint'] = computeAuthoringJsonFingerprint(
        forgedInventory,
        logicalName: 'resource-pack-bulk-inventory.json');
    forged['diffFingerprint'] = bulkDiffFingerprint(forgedDiff);
    final forgedCapability = ResourcePackBulkCapability.fromJournalJson(forged);
    final recorder = AuthoringHistoryRecorder(
        store: session.history, blobs: session.blobs, catalogStore: store);
    await expectLater(
        recorder.requireBulkHistoryRecoveryAllowed(
            capability: forgedCapability,
            intendedReceipt: AuthoringReceipt(
                receiptId: plan.plan.receiptId,
                requestId: plan.plan.request.requestId,
                actionId: 'history.revert',
                actionVersion: 1,
                status: AuthoringReceiptStatus.planned,
                createdAtUtc: DateTime.now().toUtc().toIso8601String(),
                diff: forgedDiff)),
        throwsFormatException);
    final receipt = await session.apply(plan, operationId: 'bulk_revert');
    expect((await project()).tilesets.map((entry) => entry.name),
        ['Target', 'Independent', 'Added independently']);
    expect(await map.readAsString(), 'target-map');
    await session.retention.collect(
        projectId: 'game', history: session.history, blobs: session.blobs);
    await session.undo(
        entryId: receipt.receiptId, idempotencyKey: 'bulk-undo-revert');
    expect((await project()).tilesets.map((entry) => entry.name),
        ['Later', 'Independent', 'Added independently']);
  });

  test('revert detects concurrent external edits before reservation', () async {
    final target = await edit('a', 'Target', mapValue: 'target-map');
    final head = await edit('a', 'Later', mapValue: 'later-map');
    final root = session.snapshot.root;
    final plan = await session.planRevert(
        entryId: target.receiptId,
        expectedHeadEntryId: head.receiptId,
        idempotencyKey: 'conflict',
        publicBaseRevision: await revision(),
        currentProjectRevision: revision,
        validateProjection: validate);
    await map.writeAsString('concurrent-map');
    await expectLater(
        session.apply(plan),
        throwsA(isA<CatalogStorageException>().having((error) => error.code,
            'code', 'catalog.project_revision_conflict')));
    expect(session.snapshot.root, root);
    expect(await map.readAsString(), 'concurrent-map');
    expect(await store.gateway.listJournals(), isEmpty);
  });

  for (final bulk in [false, true]) {
    for (final compensate in [false, true]) {
      test(
          'revert interrupted after HEAD promotion recovers all resources compensate=$compensate bulk=$bulk',
          () async {
        final target = await edit('a', 'Target',
            mapValue: 'target-map', assetValue: 'target-asset', bulk: bulk);
        final head = await edit('a', 'Later',
            mapValue: 'later-map', assetValue: 'later-asset');
        await session.close();
        session = await CatalogEditingSession.open(
            store: store,
            projectId: 'game',
            actorId: 'test',
            faultInjector: (context) {
              if (context.checkpoint ==
                      AuthoringTransactionCheckpoint.afterResourcePromoted &&
                  context.storageKey == CatalogStorageStore.headStorageKey) {
                throw const AuthoringTransactionSimulatedCrash();
              }
            });
        final plan = await session.planRevert(
            entryId: target.receiptId,
            expectedHeadEntryId: head.receiptId,
            idempotencyKey: 'recover-revert',
            operationId: 'revert_recovery',
            publicBaseRevision: await revision(),
            currentProjectRevision: revision,
            validateProjection: validate);
        await expectLater(session.apply(plan),
            throwsA(isA<AuthoringTransactionSimulatedCrash>()));
        await expectLater(
            WorkingProjectCatalog.open(
                store: store,
                descriptor: WorkingProjectCatalogDescriptor(projectId: 'game')),
            throwsA(isA<CatalogStorageException>().having(
                (error) => error.code, 'code', 'catalog.recovery_required')));
        await session.close();
        session = await CatalogEditingSession.open(
            store: store, projectId: 'game', actorId: 'test');
        await session.reconcile('revert_recovery', compensate: compensate);
        expect((await project()).tilesets.first.name,
            compensate ? 'Later' : 'Target');
        expect(
            await map.readAsString(), compensate ? 'later-map' : 'target-map');
        expect(await asset.readAsString(),
            compensate ? 'later-asset' : 'target-asset');
        await session.retention.collect(
            projectId: 'game', history: session.history, blobs: session.blobs);
        if (!compensate) {
          final latest =
              (await session.history.list(projectId: 'game', limit: 1))
                  .entries
                  .single;
          expect(latest.kind, AuthoringHistoryKind.revert);
          await session.undo(
              entryId: latest.entryId, idempotencyKey: 'undo-recovered');
          expect(await map.readAsString(), 'later-map');
          expect(await asset.readAsString(), 'later-asset');
        }
      });
    }
  }
}
