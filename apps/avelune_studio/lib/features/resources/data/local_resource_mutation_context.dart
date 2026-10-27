part of 'local_resource_adapter.dart';

final class _ResourceMutationProfiles {
  ProjectSnapshotLoadProfileSink? sink;

  void emit(ProjectSnapshotLoadProfile profile) => sink?.call(profile);
}

final class _LocalResourceMutationContext {
  _LocalResourceMutationContext({
    required this.handles,
    required this.openService,
    required this.opened,
    required this.snapshots,
    required this.fingerprints,
    required this.cache,
    required this.profiles,
    required this.artifacts,
    required this.api,
    required this.projectRoot,
  });

  final WorkspaceHandleStore handles;
  final ProjectOpenService openService;
  final OpenedProject opened;
  final ProjectSnapshotLoader snapshots;
  final ProjectSnapshotFingerprintCache fingerprints;
  final ProjectSnapshotCache cache;
  final _ResourceMutationProfiles profiles;
  final LocalArtifactStore artifacts;
  final LocalMapAuthoringMutationApi api;
  final String projectRoot;
  bool attached = false;
  bool closed = false;

  static Future<_LocalResourceMutationContext> create(
    ProjectSession session,
  ) async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final openService = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      catalogMetadataFields: const {},
    );
    final opened = await openService.openProject(session.directoryPath);
    try {
      final profiles = _ResourceMutationProfiles();
      final fingerprints = ProjectSnapshotFingerprintCache();
      final cache = ProjectSnapshotCache();
      final snapshots = ProjectSnapshotLoader(
        handles: handles,
        profileSink: profiles.emit,
        fingerprintCache: fingerprints,
        snapshotCache: cache,
      );
      final artifacts = LocalArtifactStore(
        allowedSourceRoots: [session.directoryPath],
        maximumArtifactBytes: maximumAuthoringArtifactBytesV1,
      );
      return _LocalResourceMutationContext(
        handles: handles,
        openService: openService,
        opened: opened,
        snapshots: snapshots,
        fingerprints: fingerprints,
        cache: cache,
        profiles: profiles,
        artifacts: artifacts,
        api: LocalMapAuthoringMutationApi(
          policy: policy,
          snapshotLoader: snapshots,
          artifactStore: artifacts,
        ),
        projectRoot: session.directoryPath,
      );
    } on Object {
      openService.closeWorkspace(opened.workspaceHandle);
      rethrow;
    }
  }

  Future<void> attach() async {
    if (attached) return;
    try {
      await api.attachProject(
        projectRootPath: projectRoot,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      attached = true;
    } on Object {
      await close();
      rethrow;
    }
  }

  Future<void> close() async {
    if (closed) return;
    closed = true;
    profiles.sink = null;
    try {
      await api.detachWorkspace(opened.workspaceHandle);
    } finally {
      fingerprints.clear();
      cache.clear();
      openService.closeWorkspace(opened.workspaceHandle);
    }
  }
}

extension _LocalResourceContext on LocalResourceAdapter {
  Future<_LocalResourceMutationContext> _requireMutationContext() async {
    _requireAvailable();
    final current = _mutationContext;
    if (current != null && !current.closed) {
      try {
        current.handles.requireActiveProject(current.opened.projectHandle);
        return current;
      } on WorkspaceHandleException catch (failure) {
        if (failure.code != 'workspace.handle_expired' &&
            failure.code != 'workspace.handle_unknown') {
          rethrow;
        }
        await current.close();
      }
    }
    _mutationContext = null;
    final created = await _LocalResourceMutationContext.create(session);
    if (_disposed) {
      await created.close();
      _requireAvailable();
    }
    _mutationContext = created;
    return created;
  }

  Future<void> _closeMutationContext() {
    if (_resourceMutationActive) return Future.value();
    final context = _mutationContext;
    _mutationContext = null;
    return _mutationContextClosing ??= context?.close() ?? Future.value();
  }
}
