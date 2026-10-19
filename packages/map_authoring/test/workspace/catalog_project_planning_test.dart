import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'materialized catalog authoring bytes never replace physical descriptor preimages',
      () {
    final descriptor = utf8.encode(jsonEncode(
        WorkingProjectCatalogDescriptor(projectId: 'planning').toJson()));
    final project = ProjectManifest(
        name: 'Complete project',
        version: ProjectVersion.v8,
        maps: const [],
        tilesets: const [
          ProjectTilesetEntry(
              id: 'tile', name: 'Tile', relativePath: 'tile.png')
        ]);
    final snapshot = ProjectSnapshot(
        projectHandle: const ProjectHandle('prj_planning'),
        revision: 'sha256:${'a' * 64}',
        manifest: project,
        materializedCatalogProject: true,
        maps: const [],
        resourceFingerprints: {
          'project': computeAuthoringBytesFingerprint(descriptor,
              logicalName: 'project.json')
        },
        resourceStorageKeys: const {
          'project': 'project.json'
        },
        resourceBytes: {
          'project': descriptor
        });
    expect(snapshot.resourceBytes('project'), descriptor);
    expect(jsonDecode(utf8.decode(snapshot.authoringProjectBytes)),
        project.toJson());
    expect(
        jsonDecode(utf8.decode(snapshot
            .rebind(const ProjectHandle('renewed'))
            .authoringProjectBytes)),
        project.toJson());
    final after = encodeProjectAuthoringDocument(
        snapshot, project.copyWith(name: 'Renamed project'));
    expect((jsonDecode(utf8.decode(after)) as Map)['tilesets'], hasLength(1));
    expect((jsonDecode(utf8.decode(after)) as Map)['name'], 'Renamed project');
    expect(snapshot.resourceBytes('project'), descriptor);
  });
  test(
      'working project actions create and edit real maps without replacing the descriptor',
      () async {
    final root = await Directory.systemTemp.createTemp('working-actions-');
    addTearDown(() => root.delete(recursive: true));
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
        store: store,
        projectId: 'working-actions',
        project: ProjectManifest(
            name: 'Working',
            version: ProjectVersion.v8,
            maps: const [],
            tilesets: const []));
    final descriptor = await File('${root.path}/project.json').readAsBytes();
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final loader = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: loader);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: loader);
    final opened = await api.openProject(root.path);
    addTearDown(() async {
      await mutations.detachWorkspace(opened.workspaceHandle);
      await api.closeWorkspace(opened.workspaceHandle);
    });
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final before = await loader.load(opened.projectHandle);
    final plan = await mutations.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: 'create-map',
            actionId: 'map.create',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: before.revision,
            idempotencyKey: 'create-map',
            parameters: const {
              'mapId': 'garden',
              'name': 'Garden',
              'width': 8,
              'height': 6
            }));
    expect(
        plan.plan.changeSet.changes
            .any((change) => change.storageKey == 'project.json'),
        isFalse);
    expect(plan.plan.changeSet.changes.map((change) => change.storageKey),
        contains('catalog/HEAD.json'));
    expect(plan.plan.changeSet.changes.map((change) => change.storageKey),
        contains('maps/garden.json'));
    final result = await mutations.applyMutation(opened.projectHandle,
        planId: plan.planId, operationId: 'create-garden');
    expect(result.snapshotRevision, isNotNull);
    expect(await File('${root.path}/project.json').readAsBytes(), descriptor);
    final maps = await api.queryProject(
        opened.projectHandle,
        AuthoringQueryRequest(
            resourceKind: 'map',
            operation: AuthoringQueryOperation.get,
            ids: const ['garden'],
            view: AuthoringQueryView.detail));
    expect(maps.items.single['name'], 'Garden');
    final after = await loader.load(opened.projectHandle);
    expect(after.manifest.maps.single.id, 'garden');
    expect(after.maps.single.size.width, 8);
    final changedMap = after.maps.single.copyWith(
        properties: {...after.maps.single.properties, 'note': 'saved'});
    final savedPlan = await mutations.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: 'save-map',
            actionId: 'map.save',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: (await api.queryProject(
                    opened.projectHandle,
                    AuthoringQueryRequest(
                        resourceKind: 'map',
                        operation: AuthoringQueryOperation.get,
                        ids: const ['garden'])))
                .snapshotRevision,
            idempotencyKey: 'save-map',
            parameters: {'map': changedMap.toJson()}));
    expect(savedPlan.projectedProject, isNull);
    expect(savedPlan.toJson().containsKey('projectedProject'), isFalse);
    expect(savedPlan.plan.changeSet.changes.map((change) => change.storageKey),
        containsAll(['catalog/HEAD.json', 'maps/garden.json']));
    final saved = await mutations.applyMutation(opened.projectHandle,
        planId: savedPlan.planId, operationId: 'save-garden');
    expect(
        (await loader.load(opened.projectHandle))
            .maps
            .single
            .properties['note'],
        'saved');
    await mutations.undoMutation(opened.projectHandle,
        entryId: saved.receipt.receiptId, idempotencyKey: 'undo-save-garden');
    expect(
        (await loader.load(opened.projectHandle))
            .maps
            .single
            .properties['note'],
        isNull);

    final staleBefore = await loader.load(opened.projectHandle);
    final staleMap = staleBefore.maps.single.copyWith(properties: {
      ...staleBefore.maps.single.properties,
      'stale': 'proposal'
    });
    final stalePlan = await mutations.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: 'stale-map',
            actionId: 'map.save',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: (await api.queryProject(
                    opened.projectHandle,
                    AuthoringQueryRequest(
                        resourceKind: 'map',
                        operation: AuthoringQueryOperation.get,
                        ids: const ['garden'])))
                .snapshotRevision,
            idempotencyKey: 'stale-map',
            parameters: {'map': staleMap.toJson()}));
    final mapFile = File('${root.path}/maps/garden.json');
    final beforeMap = await mapFile.readAsBytes();
    final beforeHead =
        await File('${root.path}/catalog/HEAD.json').readAsBytes();
    await mapFile.writeAsString(jsonEncode(staleBefore.maps.single
        .copyWith(properties: {'external': 'changed'}).toJson()));
    await expectLater(
        mutations.applyMutation(opened.projectHandle,
            planId: stalePlan.planId, operationId: 'stale-map-operation'),
        throwsA(anyOf(
            isA<CatalogStorageException>(), isA<AuthoringPlanException>())));
    expect(
        await File('${root.path}/catalog/HEAD.json').readAsBytes(), beforeHead);
    expect(await store.gateway.listJournals(), isEmpty);
    await mapFile.writeAsBytes(beforeMap);
    final limited = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: loader,
        authorizationLimits:
            const AuthoringSecurityLimits(maxTouchedResources: 1));
    await limited.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final limitedSnapshot = await loader.load(opened.projectHandle);
    final limitedPlan = await limited.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: 'denied-map',
            actionId: 'map.save',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: (await api.queryProject(
                    opened.projectHandle,
                    AuthoringQueryRequest(
                        resourceKind: 'map',
                        operation: AuthoringQueryOperation.get,
                        ids: const ['garden'])))
                .snapshotRevision,
            idempotencyKey: 'denied-map',
            parameters: {
              'map': limitedSnapshot.maps.single
                  .copyWith(properties: {'denied': 'change'}).toJson()
            }));
    await expectLater(
        limited.applyMutation(opened.projectHandle,
            planId: limitedPlan.planId, operationId: 'denied-map-operation'),
        throwsA(isA<AuthoringAuthorizationException>().having(
            (error) => error.code,
            'code',
            'authorization.too_many_resources')));
    expect(
        await File('${root.path}/catalog/HEAD.json').readAsBytes(), beforeHead);
    expect(await store.gateway.listJournals(), isEmpty);
    await limited.detachWorkspace(opened.workspaceHandle);
    final replay = await mutations.applyMutation(opened.projectHandle,
        planId: plan.planId, operationId: 'create-garden');
    expect(replay.receipt.toJson(), result.receipt.toJson());
    final audit =
        await (await FileAuthoringAuditLog.open(projectRoot: root.path))
            .readAll();
    expect(
        audit
            .where((record) => record.planId == stalePlan.planId)
            .map((record) => record.decision),
        [AuthoringAuditDecision.failed]);
    expect(
        audit
            .where((record) => record.planId == limitedPlan.planId)
            .map((record) => record.decision),
        [AuthoringAuditDecision.denied]);
    final createdAudit =
        audit.where((record) => record.planId == plan.planId).toList();
    expect(createdAudit.map((record) => record.decision),
        [AuthoringAuditDecision.succeeded, AuthoringAuditDecision.succeeded]);
    expect(createdAudit.last.details['idempotentReplay'], isTrue);

    await mutations.undoMutation(opened.projectHandle,
        entryId: result.receipt.receiptId, idempotencyKey: 'undo-garden');
    expect((await loader.load(opened.projectHandle)).manifest.maps, isEmpty);
    expect(await File('${root.path}/project.json').readAsBytes(), descriptor);
  });
  test(
      'targeted map query plan apply and replay avoid every unrelated map document',
      () async {
    final root = await Directory.systemTemp.createTemp('targeted-map-api-');
    addTearDown(() => root.delete(recursive: true));
    final map = MapData(
        id: 'target',
        name: 'Target',
        size: const GridSize(width: 8, height: 6));
    await Directory('${root.path}/maps').create();
    await File('${root.path}/maps/target.json')
        .writeAsString(jsonEncode(map.toJson()));
    await File('${root.path}/maps/unrelated.json')
        .writeAsString('invalid unrelated map');
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
        store: store,
        projectId: 'targeted-map-api',
        project: ProjectManifest(
            name: 'Targeted',
            version: ProjectVersion.v8,
            maps: const [
              ProjectMapEntry(
                  id: 'target',
                  name: 'Target',
                  relativePath: 'maps/target.json'),
              ProjectMapEntry(
                  id: 'unrelated',
                  name: 'Unrelated',
                  relativePath: 'maps/unrelated.json')
            ],
            tilesets: const []));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final loader = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: loader);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: loader);
    final opened = await api.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final list = await api.queryProject(
        opened.projectHandle,
        AuthoringQueryRequest(
            resourceKind: 'map', operation: AuthoringQueryOperation.list));
    expect(list.returned, 2);
    await expectLater(
        api.queryProject(
            opened.projectHandle,
            AuthoringQueryRequest(
                resourceKind: 'map',
                operation: AuthoringQueryOperation.get,
                ids: const ['target'],
                filters: const {'name': 'Other'})),
        throwsA(isA<AuthoringQueryException>().having(
            (error) => error.code, 'code', 'query.resource_not_found')));
    final query = AuthoringQueryRequest(
        resourceKind: 'map',
        operation: AuthoringQueryOperation.get,
        ids: const ['target'],
        view: AuthoringQueryView.detail);
    final before = await api.queryProject(opened.projectHandle, query);
    expect(before.items.single['revision'], before.snapshotRevision);
    final plan = await mutations.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: 'targeted-save',
            actionId: 'map.save',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: before.snapshotRevision,
            idempotencyKey: 'targeted-save',
            parameters: {
              'map': map.copyWith(properties: {'saved': true}).toJson()
            }));
    final applied = await mutations.applyMutation(opened.projectHandle,
        planId: plan.planId, operationId: 'targeted-save');
    final after = await api.queryProject(opened.projectHandle, query);
    expect(applied.snapshotRevision, after.snapshotRevision);
    expect(after.items.single['properties'], {'saved': true});
    final replay = await mutations.applyMutation(opened.projectHandle,
        planId: plan.planId, operationId: 'targeted-save');
    expect(replay.snapshotRevision, after.snapshotRevision);
    await File('${root.path}/maps/target.json').writeAsString(
        jsonEncode(map.copyWith(properties: {'external': true}).toJson()));
    await expectLater(
        mutations.planMutation(
            opened.projectHandle,
            AuthoringRequest(
                requestId: 'stale-target',
                actionId: 'map.save',
                actionVersion: 1,
                workspaceHandle: opened.workspaceHandle.value,
                expectedRevision: after.snapshotRevision,
                idempotencyKey: 'stale-target',
                parameters: {
                  'map': map.copyWith(properties: {'proposal': true}).toJson()
                })),
        throwsA(isA<AuthoringPlanException>()
            .having((error) => error.code, 'code', 'plan.stale')));
    expect(await File('${root.path}/maps/unrelated.json').readAsString(),
        'invalid unrelated map');
    await mutations.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
  });
  test(
      'a fresh workspace exposes recovery before allowing reads of a mixed catalog transaction',
      () async {
    final root = await Directory.systemTemp.createTemp('working-recovery-');
    addTearDown(() => root.delete(recursive: true));
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
        store: store,
        projectId: 'recovery-project',
        project: ProjectManifest(
            name: 'Recovery',
            version: ProjectVersion.v8,
            maps: const [],
            tilesets: const []));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final loader = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: loader);
    final crash = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: loader,
        faultInjector: (context) {
          if (context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted &&
              context.storageKey == CatalogStorageStore.headStorageKey) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    final opened = await api.openProject(root.path);
    await crash.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    final before = await loader.load(opened.projectHandle);
    final plan = await crash.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: 'crash',
            actionId: 'map.create',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: before.revision,
            idempotencyKey: 'crash',
            parameters: const {'mapId': 'recovered', 'width': 4, 'height': 4}));
    await expectLater(
        crash.applyMutation(opened.projectHandle,
            planId: plan.planId, operationId: 'recoverable-map'),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    await crash.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
    final reopened = await api.openProject(root.path);
    expect(reopened.recoveryRequired, isTrue);
    expect(reopened.recoveryOperationIds, contains('recoverable-map'));
    await expectLater(
        api.queryProject(
            reopened.projectHandle,
            AuthoringQueryRequest(
                resourceKind: 'map', operation: AuthoringQueryOperation.list)),
        throwsA(isA<CatalogStorageException>()
            .having((e) => e.code, 'code', 'catalog.recovery_required')));
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: loader);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: reopened.workspaceHandle,
        projectHandle: reopened.projectHandle);
    final recovered = await mutations.recoverMutation(reopened.projectHandle,
        operationId: 'recoverable-map');
    expect(recovered.snapshotRevision, isNotNull);
    expect((await loader.load(reopened.projectHandle)).maps.single.id,
        'recovered');
    await mutations.detachWorkspace(reopened.workspaceHandle);
    await api.closeWorkspace(reopened.workspaceHandle);
  });
}
