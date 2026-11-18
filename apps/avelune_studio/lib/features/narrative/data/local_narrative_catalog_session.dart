import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionFaultInjector;
import 'package:map_authoring/map_authoring_local.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';

final class LocalNarrativeCatalogContext {
  LocalNarrativeCatalogContext._(
    this.handles,
    this.opened,
    this.snapshots,
    this.api,
  );

  final WorkspaceHandleStore handles;
  final OpenedProject opened;
  final ProjectSnapshotLoader snapshots;
  final LocalMapAuthoringMutationApi api;

  static Future<LocalNarrativeCatalogContext> open({
    required ProjectSession session,
    required bool scoped,
    AuthoringTransactionFaultInjector? faultInjector,
    ProjectFileReader reader = const LocalProjectFileReader(),
  }) async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      initializeSceneOwners: false,
      catalogMetadataFields: scoped ? const {} : null,
      workshopScope: scoped,
    ).openProject(session.directoryPath);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      faultInjector: faultInjector,
      catalogFileReader: reader,
    );
    try {
      await api.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      return LocalNarrativeCatalogContext._(handles, opened, snapshots, api);
    } on Object {
      await api.detachWorkspace(opened.workspaceHandle);
      handles.closeWorkspace(opened.workspaceHandle);
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      await api.detachWorkspace(opened.workspaceHandle);
    } finally {
      handles.closeWorkspace(opened.workspaceHandle);
    }
  }
}

final class LocalNarrativeCatalogSession {
  LocalNarrativeCatalogSession({
    required this.session,
    required this.mapAdapter,
    this.faultInjector,
  }) {
    if (session.storage != ProjectSessionStorage.workingCatalog) {
      throw ArgumentError(
        'A reusable narrative session requires a working catalog.',
      );
    }
  }

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final AuthoringTransactionFaultInjector? faultInjector;
  Future<LocalNarrativeCatalogContext>? _opening;
  String? _revision;
  bool _closed = false;

  Future<void> prepare() => mapAdapter.withResourceMutation(() async {
    await obtain(await mapAdapter.resourceRevision(session));
  });

  Future<LocalNarrativeCatalogContext> obtain(String revision) async {
    if (_closed) {
      throw StateError('The narrative publication session is closed.');
    }
    if (_opening != null && _revision != revision) await discard();
    final opening = _opening ??= LocalNarrativeCatalogContext.open(
      session: session,
      scoped: true,
      faultInjector: faultInjector,
    );
    _revision = revision;
    try {
      return await opening;
    } on Object {
      if (identical(_opening, opening)) {
        _opening = null;
        _revision = null;
      }
      rethrow;
    }
  }

  void acceptRevision(String revision) => _revision = revision;

  Future<void> discard() async {
    final opening = _opening;
    _opening = null;
    _revision = null;
    if (opening != null) await (await opening).close();
  }

  Future<void> close() => mapAdapter.withResourceMutation(() async {
    if (_closed) return;
    _closed = true;
    await discard();
  });
}
