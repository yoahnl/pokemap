import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart' as local;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('history maintenance requires project write permission even for preview',
      () async {
    final fixture = await _Fixture.open(readOnlyActor: true);
    addTearDown(fixture.close);
    final head =
        await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes();
    await expectLater(
        fixture.api.maintainHistory(fixture.projectHandle,
            expectedRevision: fixture.revision),
        throwsA(isA<AuthoringAuthorizationException>().having(
            (error) => error.code, 'code', 'authorization.permission_denied')));
    expect(await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes(),
        head);
  });

  test('history maintenance previews defaults without loading missing maps',
      () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    final before =
        await File('${fixture.root.path}/project.json').readAsBytes();
    final result = await fixture.api.maintainHistory(fixture.projectHandle,
        expectedRevision: fixture.revision);
    expect(result['operationLimit'], 50);
    expect(result['byteLimit'], 200 * 1024 * 1024);
    expect(result['retainedEntryIds'], isEmpty);
    expect(
        await File('${fixture.root.path}/project.json').readAsBytes(), before);
    expect(
        await File('${fixture.root.path}/maps/missing.json').exists(), isFalse);
    for (final parameters in [
      {'apply': true},
      {'maxOperations': 51},
      {'maxBytes': 200 * 1024 * 1024 + 1},
    ]) {
      await expectLater(
          fixture.api.maintainHistory(fixture.projectHandle,
              expectedRevision: fixture.revision,
              apply: parameters['apply'] as bool? ?? false,
              maxOperations: parameters['maxOperations'] as int? ?? 50,
              maxBytes: parameters['maxBytes'] as int? ?? 200 * 1024 * 1024),
          throwsFormatException);
    }
  });

  test('history maintenance refuses an obsolete current revision', () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    await expectLater(
        fixture.api.maintainHistory(fixture.projectHandle,
            expectedRevision: 'sha256:${'0' * 64}'),
        throwsA(isA<AuthoringHistoryException>()
            .having((error) => error.code, 'code', 'history.retention_stale')));
  });

  for (final sidecar in ['editor', 'visuals', 'atmosphere']) {
    test(
        'maintenance preserves past and future $sidecar undo and catalog writes',
        () async {
      final fixture = await _Fixture.open();
      addTearDown(fixture.close);
      await Directory('${fixture.root.path}/maps').create();
      await File('${fixture.root.path}/maps/missing.json')
          .writeAsString('Map contents must remain unread');
      final editor = local.LocalMapEditorAuthoring(policy: fixture.policy);
      final visuals =
          local.LocalVisualSettingsAuthoring(policy: fixture.policy);
      final atmosphere =
          local.LocalMapAtmosphereAuthoring(policy: fixture.policy);
      Future<AuthoringReceipt> saveSidecar(int index) async {
        switch (sidecar) {
          case 'editor':
            final before = await editor.inspect(
                projectRoot: fixture.root.path, mapId: 'missing');
            return (await editor.set(
                    projectRoot: fixture.root.path,
                    mapId: 'missing',
                    expectedRevision: before.revision,
                    state:
                        MapEditorState(lockedElements: {'model:lamp-$index'}),
                    operationId: 'editor-$index'))
                .receipt;
          case 'visuals':
            final before =
                await visuals.inspect(projectRoot: fixture.root.path);
            return (await visuals.set(
                    projectRoot: fixture.root.path,
                    expectedRevision: before.revision,
                    settings: SpatialVisualPatch.fromJson(
                        {'weatherEnabled': index == 0}),
                    operationId: 'visuals-$index'))
                .receipt;
          default:
            final before = await atmosphere.inspect(
                projectRoot: fixture.root.path, mapId: 'missing');
            return (await atmosphere.set(
                    projectRoot: fixture.root.path,
                    mapId: 'missing',
                    expectedRevision: before.revision,
                    settings: SpatialAtmosphereSettings(windowsLit: index == 0),
                    operationId: 'atmosphere-$index'))
                .receipt;
        }
      }

      Future<void> undoSidecar(
          AuthoringReceipt receipt, String operation) async {
        switch (sidecar) {
          case 'editor':
            final before = await editor.inspect(
                projectRoot: fixture.root.path, mapId: 'missing');
            await editor.undoReceipt(
                projectRoot: fixture.root.path,
                mapId: 'missing',
                expectedRevision: before.revision,
                receiptId: receipt.receiptId,
                operationId: operation);
          case 'visuals':
            final before =
                await visuals.inspect(projectRoot: fixture.root.path);
            await visuals.undoReceipt(
                projectRoot: fixture.root.path,
                expectedRevision: before.revision,
                receiptId: receipt.receiptId,
                operationId: operation);
          default:
            final before = await atmosphere.inspect(
                projectRoot: fixture.root.path, mapId: 'missing');
            await atmosphere.undoReceipt(
                projectRoot: fixture.root.path,
                mapId: 'missing',
                expectedRevision: before.revision,
                receiptId: receipt.receiptId,
                operationId: operation);
        }
      }

      Future<Object> inspectSidecar() async => switch (sidecar) {
            'editor' => (await editor.inspect(
                    projectRoot: fixture.root.path, mapId: 'missing'))
                .toJson(),
            'visuals' =>
              (await visuals.inspect(projectRoot: fixture.root.path)).toJson(),
            _ => (await atmosphere.inspect(
                    projectRoot: fixture.root.path, mapId: 'missing'))
                .toJson(),
          };

      final first = await _saveCatalog(fixture, 'first');
      final past = await saveSidecar(0);
      Future<Map<String, Object?>> preview() async =>
          fixture.api.maintainHistory(fixture.projectHandle,
              expectedRevision: await _revision(fixture));
      final proposed = await preview();
      expect(proposed['retainedEntryIds'],
          containsAll([first.receiptId, past.receiptId]));
      await fixture.api.maintainHistory(fixture.projectHandle,
          expectedRevision: await _revision(fixture),
          apply: true,
          expectedFingerprint: proposed['fingerprint'] as String);
      final intermediate = await _saveCatalog(fixture, 'intermediate');
      final untouched = await inspectSidecar();
      await expectLater(
          undoSidecar(past, 'blocked-undo'),
          throwsA(isA<AuthoringHistoryException>().having(
              (error) => error.code, 'code', 'history.redo_branch_diverged')));
      expect(await inspectSidecar(), untouched);
      final store =
          await CatalogStorageStore.open(projectRoot: fixture.root.path);
      final catalog = await CatalogEditingSession.open(
          store: store,
          projectId: 'maintenance-api',
          actorId: 'local_cli',
          incrementalHistory: true);
      try {
        await catalog.undo(
            entryId: intermediate.receiptId,
            idempotencyKey: 'undo-intermediate');
      } finally {
        await catalog.close();
      }
      final future = await saveSidecar(1);
      final history = await FileAuthoringHistoryStore.open(
          projectRoot: fixture.root.path, incrementalWrites: true);
      expect((await history.localWindow('maintenance-api'))!.entryIds,
          containsAll([first.receiptId, past.receiptId, future.receiptId]));
      await undoSidecar(future, 'undo-future');
      await undoSidecar(past, 'undo-past');
      final branch = await _saveCatalog(fixture, 'branch');
      final repeated = await preview();
      expect(repeated['retainedEntryIds'], [first.receiptId, branch.receiptId]);
      await fixture.api.maintainHistory(fixture.projectHandle,
          expectedRevision: await _revision(fixture),
          apply: true,
          expectedFingerprint: repeated['fingerprint'] as String);
      expect(
          await File('${fixture.root.path}/maps/missing.json').readAsString(),
          'Map contents must remain unread');
    });
  }
}

Future<String> _revision(_Fixture fixture) async =>
    'sha256:${(await (await CatalogStorageStore.open(projectRoot: fixture.root.path)).readHead())!.sha256}';

Future<AuthoringReceipt> _saveCatalog(_Fixture fixture, String name) async {
  final store = await CatalogStorageStore.open(projectRoot: fixture.root.path);
  final editing = await CatalogEditingSession.open(
      store: store,
      projectId: 'maintenance-api',
      actorId: 'local_cli',
      incrementalHistory: true);
  try {
    return await editing.apply(await editing.planPatch(upserts: [
      CatalogDefinitionUnit(
          key: CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'selected'),
          payload: {'name': name})
    ], idempotencyKey: 'catalog-$name'));
  } finally {
    await editing.close();
  }
}

final class _Fixture {
  _Fixture(this.root, this.api, this.policy, this.handles, this.projectHandle,
      this.workspaceHandle, this.revision);

  final Directory root;
  final LocalMapAuthoringMutationApi api;
  final WorkspacePolicy policy;
  final WorkspaceHandleStore handles;
  final ProjectHandle projectHandle;
  final WorkspaceHandle workspaceHandle;
  final String revision;

  static Future<_Fixture> open({bool readOnlyActor = false}) async {
    final taskRoot = Directory(Platform.environment['AVELUNE_QA_ROOT'] ??
        '${Platform.environment['HOME']}/Library/Caches/AveluneQA/studio-project-lifecycle');
    await taskRoot.create(recursive: true);
    final root = await taskRoot.createTemp('maintenance-api-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
        store: store,
        projectId: 'maintenance-api',
        project: ProjectManifest(name: 'Maintenance', maps: const [
          ProjectMapEntry(
              id: 'missing', name: 'Missing', relativePath: 'maps/missing.json')
        ], tilesets: const []));
    const files = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: files);
    final opened = await ProjectOpenService(
        policy: policy,
        fileReader: files,
        handles: handles,
        catalogMetadataFields: {}).openProject(root.path);
    final api = LocalMapAuthoringMutationApi(
        policy: policy,
        actor: readOnlyActor
            ? AuthoringActor(
                actorId: 'reader',
                permissions: [AuthoringPermissionScope.projectRead])
            : null,
        snapshotLoader: ProjectSnapshotLoader(handles: handles));
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(root, api, policy, handles, opened.projectHandle,
        opened.workspaceHandle, 'sha256:${(await store.readHead())!.sha256}');
  }

  Future<void> close() async {
    await api.detachWorkspace(workspaceHandle);
    handles.closeWorkspace(workspaceHandle);
    await root.delete(recursive: true);
  }
}
