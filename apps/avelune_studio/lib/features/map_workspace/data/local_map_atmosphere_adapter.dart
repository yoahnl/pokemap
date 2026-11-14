part of 'local_map_workspace_adapter.dart';

extension _LocalMapAtmosphereAdapter on LocalMapWorkspaceAdapter {
  Future<LocalMapAtmosphereAuthoring> _atmosphereAuthoring(
    ProjectSession session,
  ) => _atmosphereServices.putIfAbsent(session.sessionId, () async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: _reader,
    );
    return LocalMapAtmosphereAuthoring(policy: policy, reader: _reader);
  });

  Future<MapAtmosphereState> _loadAtmosphere(
    ProjectSession session,
    String mapId,
  ) async {
    final service = await _atmosphereAuthoring(session);
    final state = await service.inspect(
      projectRoot: session.directoryPath,
      mapId: mapId,
      mapRelativePath: p.relative(
        _loadedPaths[(session.sessionId, mapId)] ??
            (throw const MapWorkspaceFailure(
              MapWorkspaceProblem.unavailable,
              'Ouvrez la carte avant de régler son ambiance.',
            )),
        from: session.directoryPath,
      ),
    );
    return MapAtmosphereState(
      settings: state.settings,
      revision: state.revision,
    );
  }

  Future<MapAtmosphereState> _saveAtmosphere(
    ProjectSession session,
    String mapId,
    SpatialAtmosphereSettings settings,
    String expectedRevision,
  ) async {
    if (session.storage == ProjectSessionStorage.portableCatalog) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Ce projet est en lecture seule. Créez une copie de travail pour régler son ambiance.',
      );
    }
    final service = await _atmosphereAuthoring(session);
    final result = await service.set(
      projectRoot: session.directoryPath,
      mapId: mapId,
      mapRelativePath: p.relative(
        _loadedPaths[(session.sessionId, mapId)] ??
            (throw const MapWorkspaceFailure(
              MapWorkspaceProblem.unavailable,
              'Ouvrez la carte avant de régler son ambiance.',
            )),
        from: session.directoryPath,
      ),
      settings: settings,
      expectedRevision: expectedRevision,
      operationId:
          'studio_atmosphere_${DateTime.now().microsecondsSinceEpoch}_${_atmosphereOperations++}',
    );
    return MapAtmosphereState(
      settings: result.afterSettings,
      revision: result.afterRevision,
    );
  }
}
