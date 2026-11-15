import 'package:map_authoring/map_authoring_local.dart';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';

Future<OpenedProject> resumeInterruptedSaves({
  required ProjectOpenService service,
  required WorkspacePolicy policy,
  required WorkspaceHandleStore handles,
  required String projectRoot,
  required OpenedProject opened,
}) async {
  if (!opened.recoveryRequired) return opened;
  final api = LocalMapAuthoringMutationApi(
    policy: policy,
    snapshotLoader: ProjectSnapshotLoader(handles: handles),
  );
  var attached = false;
  try {
    await api.attachProject(
      projectRootPath: projectRoot,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    attached = true;
    for (final operationId in opened.recoveryOperationIds) {
      await _resume(api, opened.projectHandle, operationId);
    }
  } on Object {
    throw const ProjectOpenFailure(ProjectOpenProblem.recoveryFailed);
  } finally {
    if (attached) await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
  }
  final reopened = await service.openProject(projectRoot);
  if (reopened.recoveryRequired) {
    handles.closeWorkspace(reopened.workspaceHandle);
    throw const ProjectOpenFailure(ProjectOpenProblem.recoveryFailed);
  }
  return reopened;
}

Future<void> _resume(
  LocalMapAuthoringMutationApi api,
  ProjectHandle project,
  String operationId,
) async {
  try {
    await api.recoverMutation(project, operationId: operationId);
  } on CatalogStorageException catch (error) {
    if (error.code != 'catalog.operation_discarded') rethrow;
  }
}
