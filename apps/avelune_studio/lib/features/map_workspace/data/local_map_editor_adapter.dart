part of 'local_map_workspace_adapter.dart';

extension _LocalMapEditorAdapter on LocalMapWorkspaceAdapter {
  Future<LocalMapElementOrderAuthoring> _elementOrderAuthoring(
    ProjectSession session,
  ) => _elementOrderServices.putIfAbsent(session.sessionId, () async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: _reader,
    );
    return LocalMapElementOrderAuthoring(
      policy: policy,
      reader: _reader,
      runInWorker: _reader is LocalProjectFileReader,
      diagnosticsPort: MapAuthoringWorkerDiagnostics.port,
    );
  });

  void _requireEditorWritable(ProjectSession session) {
    if (session.storage == ProjectSessionStorage.portableCatalog) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Ce projet est en lecture seule. Créez une copie de travail pour modifier ses éléments.',
      );
    }
  }

  Future<MapElementOrderWorkspaceReceipt> _reorderMapElements(
    ProjectSession session,
    MapWorkspaceDocument base,
    String kind,
    List<String> frontFirstIds,
    String? layerId,
  ) async {
    _requireEditorWritable(session);
    final service = await _elementOrderAuthoring(session);
    final path = _editorMapPath(session, base.mapId);
    final mutation = await service.reorderFromFileRevision(
      projectRoot: session.directoryPath,
      mapId: base.mapId,
      mapRelativePath: path,
      expectedFileRevision: base.revision,
      kind: kind,
      frontFirstIds: frontFirstIds,
      layerId: layerId,
      operationId:
          'studio_order_${DateTime.now().microsecondsSinceEpoch}_${_editorOperations++}',
    );
    return MapElementOrderWorkspaceReceipt(
      document: MapWorkspaceDocument(
        map: mutation.afterMap,
        revision: mutation.fileRevision,
        mapId: base.mapId,
      ),
      receiptId: mutation.receipt.receiptId,
      documentRevision: mutation.afterRevision,
    );
  }

  Future<MapElementOrderWorkspaceReceipt> _undoMapElementOrder(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapElementOrderWorkspaceReceipt receipt,
  ) async {
    _requireEditorWritable(session);
    final service = await _elementOrderAuthoring(session);
    final mutation = await service.undoReceipt(
      projectRoot: session.directoryPath,
      mapId: base.mapId,
      mapRelativePath: _editorMapPath(session, base.mapId),
      receiptId: receipt.receiptId,
      expectedRevision: receipt.documentRevision,
      operationId:
          'studio_order_undo_${DateTime.now().microsecondsSinceEpoch}_${_editorOperations++}',
    );
    return MapElementOrderWorkspaceReceipt(
      document: MapWorkspaceDocument(
        map: mutation.afterMap,
        revision: mutation.fileRevision,
        mapId: base.mapId,
      ),
      receiptId: mutation.receipt.receiptId,
      documentRevision: mutation.afterRevision,
    );
  }

  Future<LocalMapEditorAuthoring> _editorAuthoring(ProjectSession session) =>
      _editorServices.putIfAbsent(session.sessionId, () async {
        final policy = await WorkspacePolicy.create(
          allowedRootPaths: [session.directoryPath],
          fileReader: _reader,
        );
        return LocalMapEditorAuthoring(
          policy: policy,
          reader: _reader,
          runInWorker: _reader is LocalProjectFileReader,
          diagnosticsPort: MapAuthoringWorkerDiagnostics.port,
        );
      });

  String _editorMapPath(ProjectSession session, String mapId) => p.relative(
    _loadedPaths[(session.sessionId, mapId)] ??
        (throw const MapWorkspaceFailure(
          MapWorkspaceProblem.unavailable,
          'Ouvrez cette carte avant de modifier ses éléments.',
        )),
    from: session.directoryPath,
  );

  Future<MapEditorWorkspaceState> _loadEditorState(
    ProjectSession session,
    String mapId,
  ) async {
    final authoring = await _editorAuthoring(session);
    final result = await authoring.inspect(
      projectRoot: session.directoryPath,
      mapId: mapId,
      mapRelativePath: _editorMapPath(session, mapId),
    );
    return MapEditorWorkspaceState(
      state: result.state,
      revision: result.revision,
    );
  }

  Future<MapEditorWorkspaceState> _saveEditorState(
    ProjectSession session,
    String mapId,
    MapEditorState state,
    String expectedRevision,
  ) async {
    if (session.storage == ProjectSessionStorage.portableCatalog) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Ce projet est en lecture seule. Créez une copie de travail pour verrouiller ses éléments.',
      );
    }
    final authoring = await _editorAuthoring(session);
    final result = await authoring.set(
      projectRoot: session.directoryPath,
      mapId: mapId,
      mapRelativePath: _editorMapPath(session, mapId),
      expectedRevision: expectedRevision,
      state: state,
      operationId:
          'studio_editor_${DateTime.now().microsecondsSinceEpoch}_${_editorOperations++}',
    );
    return MapEditorWorkspaceState(
      state: result.afterState,
      revision: result.afterRevision,
    );
  }
}
