import 'package:map_authoring/map_authoring_local.dart';

import '../domain/project_session.dart';

final class LocalProjectCatalogPartitionAdapter {
  Future<void> partition(ProjectSession session) async {
    if (session.storage != ProjectSessionStorage.manifest) {
      throw StateError('Ce projet utilise déjà un catalogue partitionné.');
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final service = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    );
    final opened = await service.openProject(session.directoryPath);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    var attached = false;
    try {
      final snapshot = await snapshots.load(opened.projectHandle);
      await mutations.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      attached = true;
      final id = 'studio_partition_${DateTime.now().microsecondsSinceEpoch}';
      final planned = await mutations.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: id,
          actionId: 'project.catalog.partition',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: id,
          parameters: const {},
        ),
      );
      final confirmation = await mutations.confirmMutation(
        opened.projectHandle,
        planId: planned.planId,
      );
      try {
        await mutations.applyMutation(
          opened.projectHandle,
          planId: planned.planId,
          operationId: id,
          confirmationToken: confirmation.confirmationToken,
        );
      } catch (failure, stack) {
        late final AuthoringMutationResult recovered;
        try {
          recovered = await mutations.recoverMutation(
            opened.projectHandle,
            operationId: id,
          );
        } catch (_) {
          Error.throwWithStackTrace(failure, stack);
        }
        if (recovered.receipt.status.name != 'applied' &&
            recovered.receipt.extensions['recoveryOutcome'] != 'resumed') {
          Error.throwWithStackTrace(failure, stack);
        }
      }
    } finally {
      if (attached) await mutations.detachWorkspace(opened.workspaceHandle);
      service.closeWorkspace(opened.workspaceHandle);
    }
  }
}
