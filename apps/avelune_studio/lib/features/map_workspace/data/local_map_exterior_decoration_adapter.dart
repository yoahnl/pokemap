part of 'local_map_workspace_adapter.dart';

extension _LocalMapExteriorDecorationAdapter on LocalMapWorkspaceAdapter {
  Future<LocalMapExteriorDecorationAuthoring> _exteriorAuthoring(
    ProjectSession session,
  ) => _exteriorServices.putIfAbsent(
    session.sessionId,
    () async => LocalMapExteriorDecorationAuthoring(
      policy: await WorkspacePolicy.create(
        allowedRootPaths: [session.directoryPath],
        fileReader: _reader,
      ),
      reader: _reader,
      runInWorker: _reader is LocalProjectFileReader,
      diagnosticsPort: MapAuthoringWorkerDiagnostics.port,
    ),
  );
  String _exteriorMapPath(ProjectSession session, String mapId) => p.relative(
    _loadedPaths[(session.sessionId, mapId)] ??
        (throw const MapWorkspaceFailure(
          MapWorkspaceProblem.unavailable,
          'Ouvrez la carte avant de modifier son décor extérieur.',
        )),
    from: session.directoryPath,
  );
  void _requireExteriorWritable(ProjectSession session) {
    if (session.storage == ProjectSessionStorage.portableCatalog) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Ce projet est en lecture seule. Créez une copie de travail pour modifier son décor extérieur.',
      );
    }
  }

  String _exteriorOperation() =>
      'studio_exterior_${DateTime.now().microsecondsSinceEpoch}_${_exteriorOperations++}';
  Future<MapExteriorDecorationState> _loadExteriorDecoration(
    ProjectSession session,
    String mapId,
  ) async {
    if (_exteriorMapPath(session, mapId) == 'maps/$mapId.decoration.json') {
      return const MapExteriorDecorationState(
        decoration: null,
        revision: 'reserved_map_path',
        supported: false,
      );
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(mapId)) {
      final reader = _reader;
      if (reader is! ProjectResourceProbeReader) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.unavailable,
          'La présence du décor optionnel ne peut pas être vérifiée.',
        );
      }
      final probe = await (reader as ProjectResourceProbeReader).probeResource(
        projectRoot: session.directoryPath,
        relativePath: 'maps/$mapId.decoration.json',
      );
      if (probe.status != ProjectResourceProbeStatus.missing) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.unavailable,
          'Ce décor extérieur utilise une identité non prise en charge. Les données ont été conservées.',
        );
      }
      return const MapExteriorDecorationState(
        decoration: null,
        revision: 'unsupported_legacy_identity',
        supported: false,
      );
    }
    final state = await (await _exteriorAuthoring(session)).inspect(
      projectRoot: session.directoryPath,
      mapId: mapId,
      mapRelativePath: _exteriorMapPath(session, mapId),
    );
    return MapExteriorDecorationState(
      decoration: state.decoration,
      revision: state.revision,
    );
  }

  Future<MapExteriorDecorationWrite> _configureExteriorDecoration(
    ProjectSession session,
    String mapId,
    MapExteriorDecoration? definition,
    String revision,
  ) async {
    _requireExteriorWritable(session);
    final result = await (await _exteriorAuthoring(session)).configure(
      projectRoot: session.directoryPath,
      mapId: mapId,
      mapRelativePath: _exteriorMapPath(session, mapId),
      decoration: definition,
      expectedRevision: revision,
      operationId: _exteriorOperation(),
    );
    return MapExteriorDecorationWrite(
      revision: result.afterRevision,
      receiptId: result.receipt.receiptId,
    );
  }

  Future<MapExteriorDecorationWrite> _saveExteriorDecorationSector(
    ProjectSession session,
    String mapId,
    ExteriorDecorationSector sector,
    String revision,
  ) async {
    _requireExteriorWritable(session);
    final result = await (await _exteriorAuthoring(session)).setSector(
      projectRoot: session.directoryPath,
      mapId: mapId,
      mapRelativePath: _exteriorMapPath(session, mapId),
      sector: sector,
      expectedRevision: revision,
      operationId: _exteriorOperation(),
    );
    return MapExteriorDecorationWrite(
      revision: result.afterRevision,
      receiptId: result.receipt.receiptId,
    );
  }

  Future<MapExteriorDecorationWrite> _removeExteriorDecorationSector(
    ProjectSession session,
    String mapId,
    String sectorId,
    String revision,
  ) async {
    _requireExteriorWritable(session);
    final result = await (await _exteriorAuthoring(session)).removeSector(
      projectRoot: session.directoryPath,
      mapId: mapId,
      mapRelativePath: _exteriorMapPath(session, mapId),
      sectorId: sectorId,
      expectedRevision: revision,
      operationId: _exteriorOperation(),
    );
    return MapExteriorDecorationWrite(
      revision: result.afterRevision,
      receiptId: result.receipt.receiptId,
    );
  }

  Future<MapExteriorDecorationWrite> _saveExteriorDecorationBorder(
    ProjectSession session,
    String mapId,
    ExteriorDecorationBorder border,
    String revision,
  ) async {
    _requireExteriorWritable(session);
    final result = await (await _exteriorAuthoring(session)).setBorder(
      projectRoot: session.directoryPath,
      mapId: mapId,
      mapRelativePath: _exteriorMapPath(session, mapId),
      border: border,
      expectedRevision: revision,
      operationId: _exteriorOperation(),
    );
    return MapExteriorDecorationWrite(
      revision: result.afterRevision,
      receiptId: result.receipt.receiptId,
    );
  }

  Future<MapExteriorDecorationWrite> _removeExteriorDecorationBorder(
    ProjectSession session,
    String mapId,
    String borderId,
    String revision,
  ) async {
    _requireExteriorWritable(session);
    final result = await (await _exteriorAuthoring(session)).removeBorder(
      projectRoot: session.directoryPath,
      mapId: mapId,
      mapRelativePath: _exteriorMapPath(session, mapId),
      borderId: borderId,
      expectedRevision: revision,
      operationId: _exteriorOperation(),
    );
    return MapExteriorDecorationWrite(
      revision: result.afterRevision,
      receiptId: result.receipt.receiptId,
    );
  }

  Future<MapExteriorDecorationWrite> _saveExteriorDecorationSectors(
    ProjectSession session,
    String mapId,
    List<ExteriorDecorationSector> sectors,
    List<String> removeSectorIds,
    String revision,
  ) async {
    _requireExteriorWritable(session);
    final result = await (await _exteriorAuthoring(session)).setSectors(
      projectRoot: session.directoryPath,
      mapId: mapId,
      mapRelativePath: _exteriorMapPath(session, mapId),
      sectors: sectors,
      removeSectorIds: removeSectorIds,
      expectedRevision: revision,
      operationId: _exteriorOperation(),
    );
    return MapExteriorDecorationWrite(
      revision: result.afterRevision,
      receiptId: result.receipt.receiptId,
    );
  }
}
