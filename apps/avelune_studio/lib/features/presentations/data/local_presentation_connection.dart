import 'package:map_authoring/map_authoring.dart';
import '../../project_session/domain/project_session.dart';

class LocalPresentationConnection {
  LocalPresentationConnection(
    this.handles,
    this.opened,
    this.snapshots,
    this.api,
  );
  final WorkspaceHandleStore handles;
  final OpenedProject opened;
  final ProjectSnapshotLoader snapshots;
  final LocalMapAuthoringMutationApi api;
  static Future<LocalPresentationConnection> open(
    ProjectSession session,
    ArtifactStore artifacts,
    AuthoringTransactionFaultInjector? faultInjector,
  ) async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ).openProject(session.directoryPath);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      artifactStore: artifacts,
      faultInjector: faultInjector,
    );
    await api.attachProject(
      projectRootPath: session.directoryPath,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    return LocalPresentationConnection(handles, opened, snapshots, api);
  }

  Future<ProjectSnapshot> read() => snapshots.load(opened.projectHandle);
  Future<void> close() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
  }
}
