import '../contracts/query_page.dart';
import '../contracts/query_request.dart';
import '../ports/project_file_reader.dart';
import '../workspace/workspace_policy.dart';
import '../workspace/project_open_service.dart';
import '../workspace/project_snapshot_loader.dart';
import '../workspace/workspace_handle_store.dart';
import 'authoring_read_api.dart';

final class LocalPeriodicRewardChoiceReader {
  const LocalPeriodicRewardChoiceReader({required this.projectRootPath, this.fileReader = const LocalProjectFileReader()});

  final String projectRootPath;
  final ProjectFileReader fileReader;

  Future<AuthoringQueryPage> query(AuthoringQueryRequest request) async {
    final policy = await WorkspacePolicy.create(allowedRootPaths: [projectRootPath], fileReader: fileReader);
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(policy: policy, fileReader: fileReader, handles: handles,
      catalogMetadataFields: const {}, workshopScope: true, initializeSceneOwners: false);
    final api = AuthoringReadApi(openService: opener, snapshotLoader: ProjectSnapshotLoader(handles: handles));
    final opened = await api.openProject(projectRootPath);
    try { return await api.queryProject(opened.projectHandle, request); }
    finally { opener.closeWorkspace(opened.workspaceHandle); }
  }
}
