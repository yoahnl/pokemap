part of 'local_map_workspace_adapter.dart';

extension _LocalMapWorkingCatalog on LocalMapWorkspaceAdapter {
  Future<_ProjectDocument> _readCatalogProject(ProjectSession session) async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: _reader,
    );
    final handles = WorkspaceHandleStore();
    final service = ProjectOpenService(
      policy: policy,
      fileReader: _reader,
      handles: handles,
    );
    final opened = await service.openProject(session.directoryPath);
    try {
      final snapshot = await ProjectSnapshotLoader(handles: handles).load(
        opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.editorReadProjection,
      );
      if (!snapshot.materializedCatalogProject) {
        throw StateError('Le projet ne possède pas de catalogue.');
      }
      return _ProjectDocument(
        session.directoryPath,
        snapshot.manifest,
        studioProjectSnapshotRevision(snapshot),
      );
    } finally {
      service.closeWorkspace(opened.workspaceHandle);
    }
  }

  Future<String> _saveWorkingMap(
    ProjectSession session,
    _ProjectDocument project,
    MapWorkspaceDocument base,
    MapData current,
  ) async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: _reader,
    );
    final handles = WorkspaceHandleStore();
    final service = ProjectOpenService(
      policy: policy,
      fileReader: _reader,
      handles: handles,
    );
    final opened = await service.openProject(session.directoryPath);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    );
    var attached = false;
    try {
      final source = await service.catalogProject(opened.projectHandle);
      if (source == null) throw const FormatException();
      await _requireProjectRevision(session, project);
      final selection = await CatalogTargetedMapSelection.read(
        reader: source,
        mapId: current.id,
        projectedMap: current,
      );
      if (narrativeEventBytesFingerprint(selection.mapBytes) != base.revision) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'La carte a changé depuis son ouverture.',
        );
      }
      await _requireProjectRevision(session, project);
      final revision = selection.snapshotRevision;
      await api.attachProject(
        projectRootPath: session.directoryPath,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      attached = true;
      final id = 'studio_map_${DateTime.now().microsecondsSinceEpoch}';
      final planned = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: id,
          actionId: 'map.save',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: {'map': current.toJson()},
          expectedRevision: revision,
          idempotencyKey: id,
        ),
      );
      final confirmation = await api.confirmMutation(
        opened.projectHandle,
        planId: planned.planId,
      );
      try {
        await api.applyMutation(
          opened.projectHandle,
          planId: planned.planId,
          operationId: id,
          confirmationToken: confirmation.confirmationToken,
          precondition: () => _requireProjectRevision(session, project),
        );
      } catch (failure, stack) {
        late final AuthoringMutationResult recovered;
        try {
          recovered = await api.recoverMutation(
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
      if (project.complete) {
        _projects[session.sessionId] = await _readCatalogProject(session);
      } else {
        await _loadScopedCatalog(session);
      }
      final entry = _project(session).manifest.maps
          .singleWhere((entry) => entry.id == current.id);
      final reopenedSelection = await _loadScopedMapSelection(session, entry);
      if (reopenedSelection.document.map != current) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'La carte est enregistrée mais sa relecture a changé. Rouvrez sans relancer l’enregistrement.',
        );
      }
      return reopenedSelection.document.revision;
    } finally {
      if (attached) await api.detachWorkspace(opened.workspaceHandle);
      service.closeWorkspace(opened.workspaceHandle);
    }
  }
}
