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
        snapshot.manifest.copyWith(
          models3d: ProjectModel3dEntries.prepare(snapshot.manifest.models3d),
        ),
        studioProjectSnapshotRevision(snapshot),
      );
    } finally {
      service.closeWorkspace(opened.workspaceHandle);
    }
  }

  Future<String> _saveSpatialPlatformChange(ProjectSession session, MapWorkspaceDocument base, MapData current) async {
    final before = base.map.spatialScene!;
    final after = current.spatialScene!;
    final changed = after.platforms.where((value) => !before.platforms.contains(value)).toList();
    if (changed.length != 1 || before.platforms.any((value) => !after.platforms.any((entry) => entry.id == value.id)) || base.map.copyWith(spatialScene: before.copyWith(platforms: after.platforms)) != current) {
      throw const MapWorkspaceFailure(MapWorkspaceProblem.unavailable, 'Enregistrez un seul mécanisme de plateforme à la fois, séparément des autres modifications. La suppression exige encore un index des scènes entrantes.');
    }
    return _withSurfAuthoring(session, (opener, opened, api, _) async {
      final project = _project(session);
      final expected = project.revision;
      await _requireProjectRevision(session, project);
      await api.attachProject(projectRootPath: session.directoryPath, workspaceHandle: opened.workspaceHandle, projectHandle: opened.projectHandle);
      const action = 'map.platform.upsert';
      final parameters = <String, Object?>{'mapId': base.mapId, 'platform': {'kind': 'spatial', ...changed.single.toJson()}};
      final snapshot = await api.readWorkshopSnapshot(opened.projectHandle, actionId: action, parameters: parameters);
      if (narrativeEventBytesFingerprint(snapshot.resourceBytes('map:${base.mapId}')) != base.revision) throw const MapWorkspaceFailure(MapWorkspaceProblem.conflict, 'La carte a changé sur le disque. Votre brouillon reste ouvert.');
      final id = 'studio_platform_${DateTime.now().microsecondsSinceEpoch}_${_editorOperations++}';
      final plan = await api.planMutation(opened.projectHandle, AuthoringRequest(requestId: id, actionId: action, actionVersion: 1, workspaceHandle: opened.workspaceHandle.value, parameters: parameters, expectedRevision: snapshot.revision, idempotencyKey: id));
      await api.applyMutation(opened.projectHandle, planId: plan.planId, operationId: id, precondition: () async {
        if (await resourceRevision(session) != expected) throw const MapWorkspaceFailure(MapWorkspaceProblem.conflict, 'Le projet a changé pendant l’enregistrement.');
      });
      final revision = await resourceRevision(session);
      _projects[session.sessionId] = _ProjectDocument(project.root, project.manifest, revision, complete: project.complete, metadataFields: project.metadataFields);
      final bytes = await _reader.readBytes(projectRoot: session.directoryPath, relativePath: _editorMapPath(session, base.mapId));
      final saved = MapData.fromJson(Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map));
      if (saved != current) throw const MapWorkspaceFailure(MapWorkspaceProblem.conflict, 'La relecture ne correspond pas à la plateforme enregistrée. Rouvrez sans écraser le fichier.');
      return narrativeEventBytesFingerprint(bytes);
    });
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
