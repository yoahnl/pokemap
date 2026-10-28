part of 'local_map_workspace_adapter.dart';

extension _LocalProjectSurfAdapter on LocalMapWorkspaceAdapter {
  Future<ProjectSurfState> _loadSurf(ProjectSession session) =>
      LocalWorkshopReader(session, reader: _reader).read(
        metadataFields: {'settings'},
        operation: (project, _, revision) async => ProjectSurfState(
          configuration: project.settings.surf,
          revision: revision,
        ),
      );

  Future<T> _withSurfAuthoring<T>(
    ProjectSession session,
    Future<T> Function(
      ProjectOpenService opener,
      OpenedProject opened,
      LocalMapAuthoringMutationApi api,
      AuthoringReadApi reads,
    )
    operation, {
    LocalArtifactStore? artifactStore,
  }) async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: _reader,
    );
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
      policy: policy,
      fileReader: _reader,
      handles: handles,
      catalogMetadataFields: const {},
      workshopScope: true,
    );
    final opened = await opener.openProject(session.directoryPath);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      catalogFileReader: _reader,
      artifactStore: artifactStore,
    );
    final reads = AuthoringReadApi(
      openService: opener,
      snapshotLoader: snapshots,
    );
    try {
      return await operation(opener, opened, api, reads);
    } finally {
      await api.detachWorkspace(opened.workspaceHandle);
      opener.closeWorkspace(opened.workspaceHandle);
    }
  }

  Future<ProjectSurfState> _saveSurf(
    ProjectSession session,
    ProjectSurfSettings? configuration,
    String expectedRevision,
  ) async {
    if (session.storage == ProjectSessionStorage.portableCatalog) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Créez une copie de travail pour enregistrer Surf.',
      );
    }
    return _withSurfAuthoring(session, (opener, opened, api, _) async {
      final before = _project(session);
      if (before.revision != expectedRevision ||
          await resourceRevision(session) != expectedRevision) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Le projet a changé. Vos réglages Surf restent en brouillon.',
        );
      }
      await api.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      final parameters = <String, Object?>{
        'configuration': configuration?.toJson(),
      };
      final snapshot = await api.readWorkshopSnapshot(
        opened.projectHandle,
        actionId: 'surf.configure',
        parameters: parameters,
      );
      final operationId =
          'studio_surf_${DateTime.now().microsecondsSinceEpoch}_${_surfOperations++}';
      final planned = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: operationId,
          actionId: 'surf.configure',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: operationId,
        ),
      );
      await api.applyMutation(
        opened.projectHandle,
        planId: planned.planId,
        operationId: operationId,
        precondition: () async {
          if (await resourceRevision(session) != expectedRevision) {
            throw const MapWorkspaceFailure(
              MapWorkspaceProblem.conflict,
              'Le projet a changé pendant l’enregistrement. Vos réglages Surf restent en brouillon.',
            );
          }
        },
      );
      final revision = await resourceRevision(session);
      final saved = planned.projectedProject?.settings.surf ?? configuration;
      ProjectManifest update(ProjectManifest value) =>
          value.copyWith(settings: value.settings.copyWith(surf: saved));
      final current = _project(session);
      _projects[session.sessionId] = _ProjectDocument(
        current.root,
        update(current.manifest),
        revision,
        complete: current.complete,
        metadataFields: current.metadataFields,
      );
      for (final cache in [
        _resourceSelections,
        _activeMapDefinitions,
        _workshopCharacterDefinitions,
      ]) {
        if (cache[session.sessionId] case final value?) {
          cache[session.sessionId] = update(value);
        }
      }
      return ProjectSurfState(configuration: saved, revision: revision);
    });
  }

  Future<ProjectSurfReferences> _loadSurfReferences(ProjectSession session) =>
      _withSurfAuthoring(session, (opener, opened, _, reads) async {
        final facts = <String, String>{};
        String? cursor;
        do {
          final page = await reads.queryProject(
            opened.projectHandle,
            AuthoringQueryRequest(
              resourceKind: 'fact',
              operation: AuthoringQueryOperation.list,
              pageSize: 50,
              cursor: cursor,
            ),
          );
          for (final item in page.items) {
            final id = item['id'], name = item['name'];
            if (id is String && name is String) facts[id] = name;
          }
          cursor = page.nextCursor;
        } while (cursor != null);
        final badges = await LocalWorkshopReader(session, reader: _reader).read(
          metadataFields: {'badges'},
          operation: (project, _, _) async => {
            for (final badge in project.badges) badge.id: badge.label,
          },
        );
        return ProjectSurfReferences(facts: facts, badges: badges);
      });

  Future<NarrativeFactDefinition> _loadSurfFact(
    ProjectSession session,
    String id,
  ) => _withSurfAuthoring(session, (opener, opened, _, reads) async {
    final page = await reads.queryProject(
      opened.projectHandle,
      AuthoringQueryRequest(
        resourceKind: 'fact',
        operation: AuthoringQueryOperation.get,
        view: AuthoringQueryView.detail,
        ids: [id],
        pageSize: 1,
      ),
    );
    if (page.items.length != 1) {
      throw StateError('Cet état du monde est absent ou ambigu.');
    }
    return NarrativeFactDefinition.fromJson(
      Map<String, dynamic>.from(page.items.single),
    );
  });
}
