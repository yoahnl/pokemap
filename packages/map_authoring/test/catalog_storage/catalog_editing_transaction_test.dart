import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/transactions/authoring_payload.dart';
import 'package:map_authoring/src/security/resource_pack_bulk_capability.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late CatalogStorageStore store;
  late CatalogEditingSession session;
  late File map;
  const before =
      'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const after =
      'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

  Future<CatalogEditingSession> open(
          {AuthoringTransactionFaultInjector? fault}) =>
      CatalogEditingSession.open(
          store: store,
          projectId: 'game',
          actorId: 'test',
          faultInjector: fault);

  AuthoringResourceChange change({String path = 'maps/one.json'}) =>
      AuthoringResourceChange(
          resource: AuthoringResourceRef(kind: 'map', id: 'one'),
          storageKey: path,
          beforeBytes: utf8.encode('before'),
          afterBytes: utf8.encode('after'));

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('catalog-transaction-');
    store = await CatalogStorageStore.open(projectRoot: directory.path);
    await WorkingProjectCatalog.create(
        store: store,
        projectId: 'game',
        project:
            ProjectManifest(name: 'Game', maps: const [], tilesets: const []));
    map = File('${directory.path}/maps/one.json');
    await map.parent.create(recursive: true);
    await map.writeAsString('before');
    session = await open();
  });
  tearDown(() async {
    await session.close();
    await directory.delete(recursive: true);
  });

  test(
      'map-only transaction has a real head and restores all images after reopening',
      () async {
    final root = session.snapshot.root;
    final request = AuthoringRequest(
        requestId: 'request',
        workspaceHandle: 'workspace',
        actionId: 'map.save',
        actionVersion: 1,
        expectedRevision: before,
        idempotencyKey: 'map-edit');
    final plan = await session.planPatch(
        additionalChanges: [change()],
        workspaceFingerprint: after,
        publicBaseRevision: before,
        currentProjectRevision: () async => before,
        request: request,
        idempotencyKey: 'map-edit');
    expect(plan.root, isNot(root));
    expect(plan.plan.baseRevision, before);
    expect(plan.plan.changeSet.changes, hasLength(2));
    final receipt = await session.apply(plan);
    expect(await map.readAsString(), 'after');
    expect((await session.apply(plan)).toJson(), receipt.toJson());
    await session.close();
    session = await open();
    await session.retention.collect(
        projectId: 'game', history: session.history, blobs: session.blobs);
    await session.undo(entryId: receipt.receiptId, idempotencyKey: 'undo-map');
    expect(await map.readAsString(), 'before');
    expect(session.snapshot.root, root);
    await session.close();
    session = await open();
    await session.redo(entryId: receipt.receiptId, idempotencyKey: 'redo-map');
    expect(await map.readAsString(), 'after');
    final working = await WorkingProjectCatalog.open(
        store: store,
        descriptor: WorkingProjectCatalogDescriptor(projectId: 'game'));
    expect((await working.exportProject()).name, 'Game');
  });

  test(
      'history plans use the shared apply hooks and external operation identity',
      () async {
    final edit = await session.planPatch(
        additionalChanges: [change()],
        workspaceFingerprint: after,
        publicBaseRevision: before,
        currentProjectRevision: () async => before,
        idempotencyKey: 'edit-history-hooks');
    final receipt = await session.apply(edit);
    final undo = await session.planUndo(
        entryId: receipt.receiptId, idempotencyKey: 'plan-undo');
    var reserved = false;
    await session.apply(undo,
        operationId: 'external_undo', beforeReservation: () => reserved = true);
    expect(reserved, isTrue);
    expect(undo.operationId, 'external_undo');
    expect(await map.readAsString(), 'before');
    final redo = await session.planRedo(
        entryId: receipt.receiptId, idempotencyKey: 'plan-redo');
    await session.apply(redo, operationId: 'external_redo');
    expect(await map.readAsString(), 'after');
  });

  test('managed editing admission and an update do not read unrelated units',
      () async {
    final units = [
      for (var index = 0; index < 40; index++)
        CatalogDefinitionUnit(
            key: CatalogDefinitionKey(
                CatalogDefinitionKind.element, 'element-$index'),
            payload: {'id': 'element-$index', 'name': 'Before'})
    ];
    final build = CatalogStorageBuilder().build(units);
    await session.close();
    final isolated =
        await Directory.systemTemp.createTemp('catalog-admission-');
    addTearDown(() => isolated.delete(recursive: true));
    final initial = await CatalogStorageStore.open(projectRoot: isolated.path);
    await initial.publish(build, expectedRootRevision: null);
    await initial.gateway.withExclusiveWriteLock(() =>
        CatalogGenerationRetention(store: initial)
            .bindProjectUnderLock('game'));
    final initialEntry = await (await initial.openRoot(build.root))
        .snapshot
        .indexEntry(units.first.key);
    final reader = _CountingCatalogReader();
    final counted = CatalogStorageStore(
        projectRoot: isolated.path, reader: reader, gateway: initial.gateway);
    final edit = await CatalogEditingSession.open(
        store: counted, projectId: 'game', actorId: 'test');
    addTearDown(edit.close);
    final unitPaths = {
      for (final object in build.objects.entries)
        if ((jsonDecode(utf8.decode(object.value)) as Map)['type'] == 'unit')
          'catalog/objects/${object.key}.json'
    };
    expect(reader.paths.where(unitPaths.contains), isEmpty);
    final changed = CatalogDefinitionUnit(
        key: units.first.key,
        payload: {'id': units.first.key.id, 'name': 'After'});
    final plan =
        await edit.planPatch(upserts: [changed], idempotencyKey: 'targeted');
    await edit.apply(plan);
    final first = await edit.snapshot.indexEntry(units.first.key);
    final allowed = {
      'catalog/objects/${first!.reference.sha256}.json',
      'catalog/objects/${initialEntry!.reference.sha256}.json'
    };
    expect(
        reader.paths.where(
            (path) => unitPaths.contains(path) && !allowed.contains(path)),
        isEmpty);
  });

  test('compensation restores changed units and every external resource image',
      () async {
    final root = session.snapshot.root;
    final shell = (await session.snapshot.lookup(CatalogDefinitionKey(
        CatalogDefinitionKind.catalogMetadata, 'publication-shell')))!;
    final updated = CatalogDefinitionUnit(
        key: shell.key,
        references: shell.references,
        payload: {
          ...shell.payload,
          'value': {
            ...Map<String, Object?>.from(shell.payload['value']! as Map),
            'name': 'Changed'
          }
        });
    final asset = File('${directory.path}/assets/new.bin');
    final created = AuthoringResourceChange(
        resource: AuthoringResourceRef(kind: 'asset', id: 'new'),
        storageKey: 'assets/new.bin',
        beforeBytes: null,
        afterBytes: [1, 2, 3]);
    await session.close();
    session = await open(fault: (context) {
      if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted &&
          context.storageKey == 'maps/one.json') {
        throw const AuthoringTransactionSimulatedCrash();
      }
    });
    final plan = await session.planPatch(
        upserts: [updated],
        additionalChanges: [change(), created],
        workspaceFingerprint: after,
        publicBaseRevision: before,
        currentProjectRevision: () async => before,
        idempotencyKey: 'mixed');
    await expectLater(session.apply(plan),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    expect(await map.readAsString(), 'after');
    expect(await asset.readAsBytes(), [1, 2, 3]);
    await session.close();
    session = await open();
    await session.reconcile(plan.operationId, compensate: true);
    expect(session.snapshot.root, root);
    expect(await map.readAsString(), 'before');
    expect(await asset.exists(), isFalse);
    final working = await WorkingProjectCatalog.open(
        store: store,
        descriptor: WorkingProjectCatalogDescriptor(projectId: 'game'));
    expect((await working.exportProject()).name, 'Game');
  });

  test('trusted project revision is checked again before reservation',
      () async {
    var revision = before;
    final plan = await session.planPatch(
        additionalChanges: [change()],
        workspaceFingerprint: after,
        publicBaseRevision: before,
        currentProjectRevision: () async => revision,
        idempotencyKey: 'stale');
    revision = after;
    await expectLater(
        session.apply(plan),
        throwsA(isA<CatalogStorageException>().having((error) => error.code,
            'code', 'catalog.project_revision_conflict')));
    expect(await map.readAsString(), 'before');
    expect(await store.gateway.listJournals(), isEmpty);
  });

  test(
      'additional resource CAS and trusted hooks cannot overwrite concurrent changes',
      () async {
    final root = session.snapshot.root;
    final plan = await session.planPatch(
        additionalChanges: [change()],
        workspaceFingerprint: after,
        publicBaseRevision: before,
        currentProjectRevision: () async => before,
        idempotencyKey: 'file-cas');
    await map.writeAsString('external');
    await expectLater(
        session.apply(plan), throwsA(isA<AuthoringRevisionConflict>()));
    expect(await store.readHead(), root);
    expect(await map.readAsString(), 'external');
    expect(await store.gateway.listJournals(), isEmpty);
    await map.writeAsString('before');
    await expectLater(
        session.apply(plan, precondition: () async {
          throw StateError('job cancelled');
        }),
        throwsStateError);
    expect(await store.readHead(), root);
    expect(await store.gateway.listJournals(), isEmpty);
    var reserved = 0;
    var prepared = 0;
    await session.apply(plan, beforeReservation: () {
      reserved++;
    }, preparationCheck: () {
      prepared++;
    });
    expect(reserved, 1);
    expect(prepared, greaterThan(0));
  });

  test('working readers refuse the gap between head and map promotion',
      () async {
    final descriptor = WorkingProjectCatalogDescriptor(projectId: 'game');
    final reader =
        await WorkingProjectCatalog.open(store: store, descriptor: descriptor);
    await session.close();
    session = await open(fault: (context) {
      if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted &&
          context.storageKey == CatalogStorageStore.headStorageKey) {
        throw const AuthoringTransactionSimulatedCrash();
      }
    });
    final plan = await session.planPatch(
        additionalChanges: [change()],
        workspaceFingerprint: after,
        publicBaseRevision: before,
        currentProjectRevision: () async => before,
        idempotencyKey: 'read-gap');
    await expectLater(session.apply(plan),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    expect(await map.readAsString(), 'before');
    final blocked = isA<CatalogStorageException>()
        .having((error) => error.code, 'code', 'catalog.recovery_required');
    await expectLater(
        WorkingProjectCatalog.open(store: store, descriptor: descriptor),
        throwsA(blocked));
    await expectLater(reader.search(), throwsA(blocked));
    final identity = await WorkingProjectCatalog.inspectIdentity(
        store: store, descriptor: descriptor);
    expect(identity.name, 'Game');
    expect(identity.projectId, 'game');
    expect(identity.root, plan.root);
    await session.close();
    session = await open();
    await session.reconcile(plan.operationId);
    final recovered =
        await WorkingProjectCatalog.open(store: store, descriptor: descriptor);
    expect((await recovered.exportProject()).name, 'Game');
    expect(await map.readAsString(), 'after');
  });

  test('certified bulk history restores the head and its external inventory',
      () async {
    final asset = File('${directory.path}/assets/imported.bin');
    final created = AuthoringResourceChange(
        resource: AuthoringResourceRef(kind: 'asset', id: 'imported'),
        storageKey: 'assets/imported.bin',
        beforeBytes: null,
        afterBytes: [1, 2, 3]);
    final plan = await session.planPatch(
        additionalChanges: [created],
        workspaceFingerprint: after,
        publicBaseRevision: before,
        currentProjectRevision: () async => before,
        idempotencyKey: 'bulk',
        request: AuthoringRequest(
            requestId: 'bulk-request',
            workspaceHandle: 'workspace',
            actionId: 'resource_pack.import',
            actionVersion: 1,
            expectedRevision: before,
            idempotencyKey: 'bulk'));
    final receipt = await session.apply(plan, precondition: () async {
      plan.plan.bindBulkCapability(ResourcePackBulkAuthority.certifyImport(
          plan: plan.plan,
          actorId: 'test',
          projectId: 'game',
          operationId: plan.operationId,
          logicalStorageKeys: ['assets/imported.bin'],
          contentBlobStorageKeys: const []));
    });
    expect(await asset.exists(), isTrue);
    await session.close();
    session = await open();
    await session.undo(entryId: receipt.receiptId, idempotencyKey: 'bulk-undo');
    expect(await asset.exists(), isFalse);
    await session.close();
    session = await open();
    await session.redo(entryId: receipt.receiptId, idempotencyKey: 'bulk-redo');
    expect(await asset.readAsBytes(), [1, 2, 3]);
  });

  test('reserved descriptor and catalog paths cannot be additional changes',
      () async {
    for (final path in [
      'project.json',
      'PROJECT.JSON',
      'catalog/HEAD.json',
      'Catalog/objects/x.json'
    ]) {
      await expectLater(
          session.planPatch(
              additionalChanges: [change(path: path)],
              workspaceFingerprint: after,
              publicBaseRevision: before,
              currentProjectRevision: () async => before,
              idempotencyKey: 'reserved-$path'),
          throwsA(isA<CatalogStorageException>().having(
              (error) => error.code, 'code', 'catalog.reserved_resource')));
    }
  });

  test(
      'reframing transfers payload ownership once and preserves public identities',
      () async {
    var releases = 0;
    final owner = AuthoringPayloadOwner()
      ..onRelease(() {
        releases++;
      });
    final staged = File('${directory.path}/staged-after.bin');
    await staged.writeAsString('after');
    final bytes = AuthoringPayload.inline(utf8.encode('after'),
        storageKey: 'maps/one.json');
    final stored = await AuthoringPayload.verifiedSource(
        storageKey: 'maps/one.json',
        byteLength: bytes.byteLength,
        rawSha256: bytes.rawSha256,
        openRead: staged.openRead,
        release: () async {
          await staged.delete();
        });
    final retainedChange = AuthoringResourceChange.withPayloads(
        resource: AuthoringResourceRef(kind: 'map', id: 'one'),
        storageKey: 'maps/one.json',
        beforePayload: AuthoringPayload.inline(utf8.encode('before'),
            storageKey: 'maps/one.json'),
        afterPayload: stored);
    final now = DateTime.now().toUtc();
    final original = AuthoringPlan(
        planId: 'public-plan',
        receiptId: 'public-receipt',
        request: AuthoringRequest(
            requestId: 'request',
            workspaceHandle: 'workspace',
            actionId: 'map.save',
            actionVersion: 1,
            expectedRevision: before,
            idempotencyKey: 'public'),
        baseRevision: before,
        seed: 42,
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 5)),
        changeSet: AuthoringChangeSet(
            changes: [retainedChange],
            diff: AuthoringDiff([
              AuthoringDiffEntry(
                  operation: AuthoringDiffOperation.replace,
                  resource: AuthoringResourceRef(kind: 'map', id: 'one'),
                  path: '/value',
                  before: 'before',
                  after: 'after')
            ])),
        payloadOwner: owner,
        preview: {'map': 'one'});
    final auxiliary = AuthoringPlanStore()..save(original);
    final plan = await session.planPatch(
        additionalChanges: original.changeSet.changes,
        workspaceFingerprint: after,
        publicBaseRevision: before,
        publicPlan: original,
        currentProjectRevision: () async => before,
        idempotencyKey: 'public');
    expect(plan.plan.planId, original.planId);
    expect(plan.plan.receiptId, original.receiptId);
    expect(plan.plan.seed, 42);
    expect(plan.plan.preview, {'map': 'one'});
    expect(original.applicable, isFalse);
    expect(() => original.reframeChangeSet(changeSet: plan.plan.changeSet),
        throwsStateError);
    await auxiliary.discard(original.planId);
    expect(releases, 0);
    expect(await staged.exists(), isTrue);
    await session.apply(plan);
    expect(await map.readAsString(), 'after');
    expect(releases, 1);
    expect(await staged.exists(), isFalse);
  });

  for (final checkpoint in AuthoringTransactionCheckpoint.values) {
    test('multi-resource recovery at ${checkpoint.name}', () async {
      await session.close();
      session = await open(fault: (context) {
        if (context.checkpoint == checkpoint) {
          throw const AuthoringTransactionSimulatedCrash();
        }
      });
      final plan = await session.planPatch(
          additionalChanges: [change()],
          workspaceFingerprint: after,
          publicBaseRevision: before,
          currentProjectRevision: () async => before,
          idempotencyKey: 'crash');
      await expectLater(session.apply(plan),
          throwsA(isA<AuthoringTransactionSimulatedCrash>()));
      await session.close();
      session = await open();
      await session.retention.collect(
          projectId: 'game', history: session.history, blobs: session.blobs);
      await session.reconcile(plan.operationId);
      final reserved = checkpoint.index >=
          AuthoringTransactionCheckpoint.afterReservation.index;
      expect(await map.readAsString(), reserved ? 'after' : 'before');
    });
  }
}

final class _CountingCatalogReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
  @override
  Future<List<int>> readBytes(
          {required String projectRoot, required String relativePath}) =>
      throw StateError('Unbounded catalog reads are forbidden.');
  @override
  bool get supportsStreamingResources => true;
  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }
}
