import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_authoring/map_authoring.dart';

Future<List<String>> transportActionHistory(ProjectSession session) async {
  const reader = LocalProjectFileReader();
  final handles = WorkspaceHandleStore();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [session.directoryPath],
    fileReader: reader,
  );
  final opener = ProjectOpenService(
    policy: policy,
    fileReader: reader,
    handles: handles,
  );
  final opened = await opener.openProject(session.directoryPath);
  final api = LocalMapAuthoringMutationApi(
    policy: policy,
    snapshotLoader: ProjectSnapshotLoader(handles: handles),
  );
  try {
    await api.attachProject(
      projectRootPath: session.directoryPath,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    final history = await api.listMutationHistory(
      opened.projectHandle,
      limit: 100,
    );
    return [for (final entry in history.entries) entry.receipt.actionId];
  } finally {
    await api.detachWorkspace(opened.workspaceHandle);
    opener.closeWorkspace(opened.workspaceHandle);
  }
}
