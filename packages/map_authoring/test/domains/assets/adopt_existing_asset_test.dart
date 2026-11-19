import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../workspace/catalog_map_lifecycle_fixture.dart';
import 'resource_information_fixture.dart';

void main() {
  test('recovery rechecks the project source after a process interruption',
      () async {
    final root =
        await Directory.systemTemp.createTemp('asset-adoption-recovery-');
    addTearDown(() => root.delete(recursive: true));
    await File('${root.path}/project.json').writeAsString(jsonEncode(
        const ProjectManifest(name: 'Recovery', maps: [], tilesets: [])
            .toJson()));
    const path = 'assets/LICENSE.txt';
    final file = File('${root.path}/$path');
    await file.parent.create(recursive: true);
    final bytes = utf8.encode('Original');
    await file.writeAsBytes(bytes);
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final opened = await ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles)
        .openProject(root.path);
    final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
        faultInjector: (stage) {
          if (stage.checkpoint ==
              AuthoringTransactionCheckpoint.afterJournalPrepared) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    addTearDown(() async {
      await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
    });
    final staged =
        await api.artifacts.put(bytes, declaredMediaType: 'text/plain');
    final parameters = {
      'artifactHandle': staged.reference.handle,
      'assetId': 'license',
      'logicalPath': path,
      'adoptExisting': true
    };
    final snapshot = await api.readWorkshopSnapshot(opened.projectHandle,
        actionId: 'asset.import', parameters: parameters);
    final plan = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: 'register',
            workspaceHandle: opened.workspaceHandle.value,
            actionId: 'asset.import',
            actionVersion: 1,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'register',
            parameters: parameters));
    await expectLater(
        api.applyMutation(opened.projectHandle,
            planId: plan.planId, operationId: 'register'),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()));
    await file.writeAsString('New file');
    await expectLater(
        api.recoverMutation(opened.projectHandle, operationId: 'register'),
        throwsA(isA<AuthoringRevisionConflict>()));
    final register = File('${root.path}/$assetCatalogStorageKey');
    expect(await register.exists(), isFalse);
    expect(await file.readAsString(), 'New file');
    await file.writeAsBytes(bytes);
    await api.recoverMutation(opened.projectHandle, operationId: 'register');
    expect(
        AssetCatalog.fromJson(jsonDecode(await register.readAsString()))
            .findByLogicalPath(path)
            ?.id,
        'license');
  });

  for (final catalog in [false, true]) {
    test(
        'asset adoption preserves original bytes and checks stale files (catalog $catalog)',
        () async {
      late final Directory root;
      late final LocalMapAuthoringMutationApi api;
      late final ProjectHandle project;
      late final String workspace;
      if (catalog) {
        final fixture = await CatalogMapLifecycleFixture.open(3);
        addTearDown(fixture.close);
        root = fixture.root;
        api = fixture.api;
        project = fixture.opened.projectHandle;
        workspace = fixture.opened.workspaceHandle.value;
      } else {
        final fixture =
            await ResourceInformationFixture.create(const ProjectManifest(
          name: 'Presentation media',
          maps: [],
          tilesets: [],
        ));
        addTearDown(fixture.dispose);
        root = fixture.root;
        api = fixture.mutations;
        project = ProjectHandle(fixture.project);
        workspace = fixture.workspace;
        final descriptor = File('${root.path}/project.json');
        final manifest = ProjectManifest.fromJson(
            jsonDecode(await descriptor.readAsString()));
        await descriptor
            .writeAsString(jsonEncode(manifest.copyWith(maps: const [
          ProjectMapEntry(
              id: 'other', name: 'Other', relativePath: 'maps/other.json'),
        ]).toJson()));
        final other = File('${root.path}/maps/other.json');
        await other.parent.create(recursive: true);
        await other.writeAsString('unrelated map must not be decoded');
      }

      const path = 'assets/presentation/LICENSE.txt';
      final source = File('${root.path}/$path');
      await source.parent.create(recursive: true);
      final bytes = utf8.encode('Original license text');
      final staged =
          await api.artifacts.put(bytes, declaredMediaType: 'text/plain');
      final parameters = {
        'artifactHandle': staged.reference.handle,
        'assetId': 'license',
        'logicalPath': path,
        'adoptExisting': true,
      };
      Future<AuthoringMutationPlanResult> plan(String id) async {
        final snapshot = await api.readWorkshopSnapshot(project,
            actionId: 'asset.import', parameters: parameters);
        return api.planMutation(
            project,
            AuthoringRequest(
              requestId: id,
              workspaceHandle: workspace,
              actionId: 'asset.import',
              actionVersion: 1,
              expectedRevision: snapshot.revision,
              idempotencyKey: id,
              parameters: parameters,
              extensions: const {'workshopScope': true},
            ));
      }

      final mismatch = throwsA(isA<AssetActionException>()
          .having((error) => error.code, 'code', 'asset.adoption_mismatch'));
      await expectLater(plan('missing-file'), mismatch);
      await source.writeAsString('Other license');
      await expectLater(plan('wrong-file'), mismatch);
      await source.writeAsBytes(bytes);
      final stale = await plan('stale-file');
      await source.writeAsString('New license');
      await expectLater(
          api.applyMutation(project,
              planId: stale.planId, operationId: 'stale-file'),
          throwsA(catalog
              ? isA<CatalogStorageException>().having((error) => error.code,
                  'code', 'catalog.project_revision_conflict')
              : isA<AuthoringPlanException>()
                  .having((error) => error.code, 'code', 'plan.stale')));
      final register = File('${root.path}/$assetCatalogStorageKey');
      expect(await register.exists(), isFalse);
      expect(await source.readAsString(), 'New license');

      await source.writeAsBytes(bytes);
      final accepted = await plan('register');
      expect(accepted.plan.changeSet.changes.map((change) => change.storageKey),
          isNot(contains(path)));
      final applied = await api.applyMutation(project,
          planId: accepted.planId, operationId: 'register');
      expect(
          AssetCatalog.fromJson(jsonDecode(await register.readAsString()))
              .findByLogicalPath(path)
              ?.id,
          'license');
      expect(await source.readAsBytes(), bytes);
      await api.undoMutation(project,
          entryId: applied.receipt.receiptId, idempotencyKey: 'undo-register');
      expect(await register.exists(), isFalse);
      expect(await source.readAsBytes(), bytes);
      await source.writeAsString('Revised after undo');
      await expectLater(
          api.redoMutation(project,
              entryId: applied.receipt.receiptId, idempotencyKey: 'redo-stale'),
          throwsA(isA<AuthoringRevisionConflict>()));
      expect(await register.exists(), isFalse);
      expect(await source.readAsString(), 'Revised after undo');
      await source.writeAsBytes(bytes);
      await api.redoMutation(project,
          entryId: applied.receipt.receiptId, idempotencyKey: 'redo-restored');
      expect(
          AssetCatalog.fromJson(jsonDecode(await register.readAsString()))
              .findByLogicalPath(path)
              ?.id,
          'license');
    });
  }
}
