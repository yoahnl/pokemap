part of 'map_workspace_controller.dart';

extension MapWorkspaceWorkshops on MapWorkspaceController {
  bool hasWorkshop(MapWorkspaceWorkshop workshop) =>
      hasCompleteProject || _workshops.contains(workshop);

  Future<void> ensureWorkshop(MapWorkspaceWorkshop workshop) {
    if (hasWorkshop(workshop) || _disposed) return Future.value();
    return _workshopLoads.putIfAbsent(workshop, () async {
      try {
        if (project == null) await initialize();
        final source = port;
        if (source is! MapWorkspaceWorkshopPort || project == null) {
          throw const MapWorkspaceFailure(
            MapWorkspaceProblem.unavailable,
            'Cet atelier ne dispose pas de lecteur ciblé.',
          );
        }
        final sourceEpoch = _modelSourceEpoch;
        final loaded = await source.loadWorkshop(session, workshop);
        if (_disposed) return;
        _workshopDefinitions = _prepareModelProjection(
          workshop.merge(
            _workshopDefinitions ?? project!,
            _prepareModelProjection(loaded.metadata, sourceEpoch: sourceEpoch),
          ),
        );
        project = _prepareModelProjection(
          workshop.merge(
            project!,
            _prepareModelProjection(loaded.metadata, sourceEpoch: sourceEpoch),
          ),
        );
        _workshops.add(workshop);
        notify();
      } finally {
        _workshopLoads.remove(workshop);
      }
    });
  }

  ProjectManifest _withWorkshops(ProjectManifest selection) {
    final loaded = _workshopDefinitions;
    final family = _resourceVisualDefinitions;
    if (loaded == null && family == null) {
      return _withSurfConfiguration(selection);
    }
    var merged = selection;
    if (loaded != null) {
      for (final workshop in _workshops) {
        merged = workshop.merge(merged, loaded);
      }
    }
    return _withSurfConfiguration(
      _prepareModelProjection(
        family == null ? merged : combineResourceVisuals(merged, family),
      ),
    );
  }

  Future<void> materializeProject() async {
    if (hasCompleteProject || _disposed) return;
    final source = port;
    if (source is! MapWorkspaceScopedPort) return;
    final sourceEpoch = _modelSourceEpoch;
    final complete = await source.materializeProject(session);
    if (_disposed) return;
    project = _prepareModelProjection(complete, sourceEpoch: sourceEpoch);
    projectScope = MapWorkspaceProjectScope.completeProject;
    _clearSelections();
    notify();
  }

  Future<void> refreshCatalogSelection() async {
    final source = port;
    if (hasCompleteProject || _disposed || source is! MapWorkspaceScopedPort) {
      return;
    }
    final catalog = await source.loadCatalog(session);
    if (_disposed) return;
    _catalogNewGame = catalog.metadata.newGame;
    _workshopDefinitions = null;
    _resourceKind = null;
    _resourceVisualDefinitions = null;
    _familyDefinitions = null;
    _resetOnDemandSelections();
    for (final workshop in _workshops.toList()) {
      if (source is MapWorkspaceWorkshopPort) {
        final sourceEpoch = _modelSourceEpoch;
        final loaded = await source.loadWorkshop(session, workshop);
        if (_disposed) return;
        _workshopDefinitions = _prepareModelProjection(
          workshop.merge(
            _workshopDefinitions ?? catalog.metadata,
            _prepareModelProjection(loaded.metadata, sourceEpoch: sourceEpoch),
          ),
        );
      }
    }
    final document = active;
    final entry = catalog.metadata.maps
        .where((entry) => entry.id == document?.base.mapId)
        .firstOrNull;
    final sourceEpoch = _modelSourceEpoch;
    final selection = entry == null
        ? null
        : await source.loadMapSelection(session, entry);
    if (_disposed) return;
    _clearSelections();
    if (selection != null) {
      _cacheSelection(entry!.id, selection, sourceEpoch);
    }
    project = _withWorkshops(
      _selections[entry?.id]?.definitions ??
          _prepareModelProjection(catalog.metadata),
    );
    projectScope = selection == null
        ? MapWorkspaceProjectScope.catalogMetadata
        : MapWorkspaceProjectScope.mapSelection;
    notify();
  }
}
