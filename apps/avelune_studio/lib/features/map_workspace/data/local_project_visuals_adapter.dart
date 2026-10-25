part of 'local_map_workspace_adapter.dart';

extension _LocalProjectVisualsAdapter on LocalMapWorkspaceAdapter {
  Future<LocalVisualSettingsAuthoring> _visualAuthoring(
    ProjectSession session,
  ) => _visualServices.putIfAbsent(
    session.sessionId,
    () async => LocalVisualSettingsAuthoring(
      policy: await WorkspacePolicy.create(
        allowedRootPaths: [session.directoryPath],
        fileReader: _reader,
      ),
      reader: _reader,
    ),
  );

  Future<ProjectVisualsState> _loadVisuals(
    ProjectSession session,
    ProjectMapEntry? map,
  ) async {
    final value = await (await _visualAuthoring(session)).inspect(
      projectRoot: session.directoryPath,
      mapId: map?.id ?? LocalVisualSettingsAuthoring.projectScopeId,
      mapRelativePath: map?.relativePath,
    );
    return ProjectVisualsState(
      profile: value.settings,
      revision: value.revision,
    );
  }

  Future<ProjectVisualsState> _saveVisuals(
    ProjectSession session,
    SpatialVisualPatch profile,
    String revision,
    ProjectMapEntry? map,
  ) async {
    _requireWritableVisuals(session);
    final value = await (await _visualAuthoring(session)).set(
      projectRoot: session.directoryPath,
      mapId: map?.id ?? LocalVisualSettingsAuthoring.projectScopeId,
      mapRelativePath: map?.relativePath,
      settings: profile,
      expectedRevision: revision,
      operationId:
          'studio_visual_${DateTime.now().microsecondsSinceEpoch}_${_visualOperations++}',
    );
    return ProjectVisualsState(
      profile: value.afterSettings,
      revision: value.afterRevision,
      receiptId: value.receipt.receiptId,
    );
  }

  Future<ProjectVisualsState> _undoVisuals(
    ProjectSession session,
    String receiptId,
    String revision,
    ProjectMapEntry? map,
  ) async {
    _requireWritableVisuals(session);
    final value = await (await _visualAuthoring(session)).undoReceipt(
      projectRoot: session.directoryPath,
      mapId: map?.id ?? LocalVisualSettingsAuthoring.projectScopeId,
      mapRelativePath: map?.relativePath,
      receiptId: receiptId,
      expectedRevision: revision,
      operationId:
          'studio_visual_undo_${DateTime.now().microsecondsSinceEpoch}_${_visualOperations++}',
    );
    return ProjectVisualsState(
      profile: value.afterSettings,
      revision: value.afterRevision,
      receiptId: value.receipt.receiptId,
    );
  }

  void _requireWritableVisuals(ProjectSession session) {
    if (session.storage == ProjectSessionStorage.portableCatalog) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Créez une copie de travail pour enregistrer ces réglages.',
      );
    }
  }
}
