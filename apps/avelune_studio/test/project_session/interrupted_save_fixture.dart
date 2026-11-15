import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

Future<void> leaveInterruptedSceneSave(
  String root,
  SceneAsset scene, {
  required String operationId,
}) async {
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [root],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore();
  final opened = await ProjectOpenService(
    policy: policy,
    fileReader: reader,
    handles: handles,
    initializeSceneOwners: false,
    catalogMetadataFields: const {},
    workshopScope: true,
  ).openProject(root);
  final api = LocalMapAuthoringMutationApi(
    policy: policy,
    snapshotLoader: ProjectSnapshotLoader(handles: handles),
    faultInjector: (context) {
      if (context.checkpoint ==
          AuthoringTransactionCheckpoint.afterJournalPrepared) {
        throw const AuthoringTransactionSimulatedCrash();
      }
    },
  );
  await api.attachProject(
    projectRootPath: root,
    workspaceHandle: opened.workspaceHandle,
    projectHandle: opened.projectHandle,
  );
  try {
    final fields = {'scene': scene.toJson()};
    final snapshot = await api.readWorkshopSnapshot(
      opened.projectHandle,
      actionId: 'scene.upsert',
      parameters: fields,
    );
    final planned = await api.planMutation(
      opened.projectHandle,
      AuthoringRequest(
        requestId: operationId,
        actionId: 'scene.upsert',
        actionVersion: 1,
        extensions: const {'workshopScope': true},
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: snapshot.revision,
        idempotencyKey: operationId,
        parameters: jsonDecode(jsonEncode(fields)) as Map<String, dynamic>,
      ),
    );
    await expectLater(
      api.applyMutation(
        opened.projectHandle,
        planId: planned.planId,
        operationId: operationId,
      ),
      throwsA(isA<AuthoringTransactionSimulatedCrash>()),
    );
  } finally {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
  }
  expect(
    await Directory('$root/.pokemap/authoring/transactions/$operationId')
        .exists(),
    isTrue,
  );
}

Future<void> setCatalogWritable(String root, {required bool writable}) async {
  final result = await Process.run('chmod', [
    writable ? 'u+w' : 'a-w',
    '$root/catalog',
  ]);
  expect(result.exitCode, 0);
  if (!writable) {
    addTearDown(() => Process.run('chmod', ['u+w', '$root/catalog']));
  }
}
