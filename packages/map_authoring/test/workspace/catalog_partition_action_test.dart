import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final crashPath in <String?>[
    null,
    'catalog/HEAD.json',
    'catalog/IDENTITY.json',
    'project.json'
  ]) {
    test('canonical partition preserves data and recovers authority $crashPath',
        () async {
      final root = await Directory.systemTemp.createTemp('partition-action-');
      addTearDown(() => root.delete(recursive: true));
      final project = ProjectManifest(
          name: 'Existing project',
          version: ProjectVersion.v8,
          maps: const [],
          tilesets: const [
            ProjectTilesetEntry(
                id: 'tile', name: 'Tile', relativePath: 'assets/tile.png')
          ]);
      final original = utf8.encode(jsonEncode(project.toJson()));
      await File('${root.path}/project.json').writeAsBytes(original);
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [root.path], fileReader: reader);
      final handles = WorkspaceHandleStore();
      final loader = ProjectSnapshotLoader(handles: handles);
      final api = AuthoringReadApi(
          openService: ProjectOpenService(
              policy: policy, fileReader: reader, handles: handles),
          snapshotLoader: loader);
      final mutations = LocalMapAuthoringMutationApi(
          policy: policy,
          snapshotLoader: loader,
          faultInjector: (context) {
            if (context.checkpoint ==
                    AuthoringTransactionCheckpoint.afterResourcePromoted &&
                context.storageKey == crashPath) {
              throw const AuthoringTransactionSimulatedCrash();
            }
          });
      final worker = JsonlWorker(api: api, mutations: mutations);
      var opened = await api.openProject(root.path);
      await mutations.attachProject(
          projectRootPath: root.path,
          workspaceHandle: opened.workspaceHandle,
          projectHandle: opened.projectHandle);
      final snapshot = await loader.load(opened.projectHandle);
      final plan = await mutations.planMutation(
          opened.projectHandle,
          AuthoringRequest(
              requestId: 'partition',
              actionId: 'project.catalog.partition',
              actionVersion: 1,
              workspaceHandle: opened.workspaceHandle.value,
              expectedRevision: snapshot.revision,
              idempotencyKey: 'partition'));
      expect(
          plan.plan.changeSet.changes.map((change) => change.storageKey),
          containsAll(
              ['project.json', 'catalog/HEAD.json', 'catalog/IDENTITY.json']));
      expect(plan.plan.preview['requiresReopen'], isTrue);
      expect(await File('${root.path}/project.json').readAsBytes(), original);
      expect(await File('${root.path}/catalog/HEAD.json').exists(), isFalse);
      expect(
          await File('${root.path}/catalog/IDENTITY.json').exists(), isFalse);
      AuthoringMutationResult? applied;
      if (crashPath == null) {
        applied = await mutations.applyMutation(opened.projectHandle,
            planId: plan.planId, operationId: 'partition-project');
      } else {
        await expectLater(
            mutations.applyMutation(opened.projectHandle,
                planId: plan.planId, operationId: 'partition-project'),
            throwsA(isA<AuthoringTransactionSimulatedCrash>()));
        await mutations.detachWorkspace(opened.workspaceHandle);
        await api.closeWorkspace(opened.workspaceHandle);
        opened = await api.openProject(root.path);
        expect(opened.recoveryRequired,isTrue);
        expect(opened.recoveryOperationIds,['partition-project']);
        await expectLater(api.queryProject(opened.projectHandle,AuthoringQueryRequest(resourceKind:'project',operation:AuthoringQueryOperation.get,ids:const ['project'])),throwsA(isA<CatalogStorageException>().having((error)=>error.code,'code','catalog.recovery_required')));
        await expectLater(loader.load(opened.projectHandle),throwsA(isA<CatalogStorageException>().having((error)=>error.code,'code','catalog.recovery_required')));
        await mutations.attachProject(
            projectRootPath: root.path,
            workspaceHandle: opened.workspaceHandle,
            projectHandle: opened.projectHandle);
        applied = await mutations.recoverMutation(opened.projectHandle,
            operationId: 'partition-project');
      }
      expect(applied.receipt.actionId, 'project.catalog.partition');
      expect(
          (jsonDecode(await File('${root.path}/project.json').readAsString())
              as Map)['format'],
          'avelune.working-catalog');
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      expect(await store.gateway.listJournals(), isEmpty);
      await mutations.detachWorkspace(opened.workspaceHandle);
      await api.closeWorkspace(opened.workspaceHandle);
      opened = await api.openProject(root.path);
      await mutations.attachProject(
          projectRootPath: root.path,
          workspaceHandle: opened.workspaceHandle,
          projectHandle: opened.projectHandle);
      final restored = await loader.load(opened.projectHandle);
      expect(restored.manifest.toJson(), project.toJson());
      final replay = await mutations.applyMutation(opened.projectHandle,
          planId: plan.planId, operationId: 'partition-project');
      expect(replay.receipt.toJson(), applied.receipt.toJson());
      final history =
          await mutations.listMutationHistory(opened.projectHandle, limit: 20);
      expect(history.page.entries.single.nonUndoableReason,
          'catalog.partition_not_undoable');
      final described = jsonDecode(await worker.processLine(jsonEncode(
          {'id': 'describe', 'command': 'describe', 'args': {}}))) as Map;
      expect(
          ((described['data'] as Map)['mutationActions'] as List).where(
              (action) => (action as Map)['id'] == 'project.catalog.partition'),
          hasLength(1));
      await mutations.detachWorkspace(opened.workspaceHandle);
      await api.closeWorkspace(opened.workspaceHandle);
    });
  }
}
