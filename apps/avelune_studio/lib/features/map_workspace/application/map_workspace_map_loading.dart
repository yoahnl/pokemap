part of 'map_workspace_controller.dart';

extension _MapWorkspaceMapLoading on MapWorkspaceController {
  Future<void> _initialize() async {
    if (project != null) return;
    try {
      final source = port;
      final manifest = !hasCompleteProject && source is MapWorkspaceScopedPort
          ? (await source.loadCatalog(session)).metadata
          : await port.loadProject(session);
      if (_disposed) return;
      _catalogNewGame = manifest.newGame;
      project = _prepareModelProjection(manifest);
      notify();
      if (manifest.maps.isNotEmpty) {
        final initial = manifest.newGame.enabled
            ? manifest.maps.singleWhere(
                (entry) => entry.id == manifest.newGame.startMapId,
                orElse: () => throw StateError(
                  'La carte de départ configurée est absente du projet.',
                ),
              )
            : manifest.maps.first;
        await activate(initial);
      }
    } catch (failure) {
      if (!_disposed) {
        error = _message(failure);
        notify();
      }
    }
  }

  Future<void> _activate(
    ProjectMapEntry entry, {
    bool Function()? isCurrent,
  }) async {
    if (_disposed || isCurrent?.call() == false) return;
    if (project != null && !_entryDocumentCurrent(entry)) {
      if (active?.base.mapId == entry.id) active = null;
      error = 'Cette carte ne figure plus dans le projet.';
      notify();
      return;
    }
    final currentEntry =
        project?.maps.where((map) => map.id == entry.id).firstOrNull ?? entry;
    final catalogEpoch = _catalogEpoch;
    final mapEpoch = _mapEpochs[entry.id];
    Future<EditableMapDocument>? pending;
    final generation = ++_generation;
    loading = true;
    error = null;
    notify();
    try {
      final cached = documents[entry.id];
      if (cached == null) {
        pending = _loading.putIfAbsent(entry.id, () async {
          final source = port;
          if (!hasCompleteProject && source is MapWorkspaceScopedPort) {
            final sourceEpoch = _modelSourceEpoch;
            final selection = await source.loadMapSelection(
              session,
              currentEntry,
            );
            _cacheSelection(entry.id, selection, sourceEpoch);
            return _prepareAtmosphere(
              EditableMapDocument(selection.document),
              currentEntry,
            );
          }
          return _prepareAtmosphere(
            EditableMapDocument(await port.loadMap(session, currentEntry)),
            currentEntry,
          );
        });
      }
      final document = cached ?? await pending!;
      document.configureFieldTraversal = port is FieldTraversalZonePort
          ? (next) => configureFieldTraversal(document, next)
          : null;
      document.modelDeletionProblem = (modelId) =>
          modelDeletionGuard?.call(document.current.id, modelId);
      document.configureSpatialModelVisibility = (instanceId, value) =>
          configureModelVisibility(document, instanceId, value);
      document.configureSpatialFieldObstacle = (instanceId, value) =>
          configureFieldObstacle(document, instanceId, value);
      final source = port;
      if (cached != null &&
          !hasCompleteProject &&
          source is MapWorkspaceScopedPort &&
          !_selections.containsKey(entry.id)) {
        final sourceEpoch = _modelSourceEpoch;
        final selection = await source.loadMapSelection(session, currentEntry);
        _cacheSelection(entry.id, selection, sourceEpoch);
      }
      if (_disposed ||
          mapEpoch != _mapEpochs[entry.id] ||
          isCurrent?.call() == false ||
          (catalogEpoch != _catalogEpoch && !_entryDocumentCurrent(entry))) {
        return;
      }
      documents[entry.id] = document;
      if (generation == _generation) {
        active = document;
        document.visualProfile = (_projectVisualProfile ?? SpatialVisualPatch())
            .overriddenBy(
              document.weatherVisuals?.preview.value ??
                  _mapVisualProfiles[entry.id] ??
                  SpatialVisualPatch(),
            );
        final selection = _selections[entry.id];
        if (!hasCompleteProject && selection != null) {
          project = _withWorkshops(_selections[entry.id]!.definitions);
          projectScope = MapWorkspaceProjectScope.mapSelection;
        }
      }
    } catch (failure) {
      if (!_disposed &&
          generation == _generation &&
          mapEpoch == _mapEpochs[entry.id] &&
          isCurrent?.call() != false) {
        error = _message(failure);
      }
    } finally {
      if (identical(_loading[entry.id], pending)) _loading.remove(entry.id);
      if (!_disposed && generation == _generation) {
        loading = false;
        notify();
      }
    }
  }

  Future<EditableMapDocument> _prepareAtmosphere(
    EditableMapDocument document,
    ProjectMapEntry entry,
  ) async {
    final editorPort = port;
    if (editorPort is MapEditorPort) {
      final editor = await MapEditorController.open(
        session,
        entry.id,
        editorPort as MapEditorPort,
      );
      if (_disposed) {
        editor.dispose();
        return document;
      }
      document.editor = editor;
    }
    if (document.current.spatialScene != null &&
        port is MapExteriorDecorationPort) {
      final exterior = await MapExteriorDecorationController.open(
        session,
        document.current,
        port as MapExteriorDecorationPort,
      );
      if (_disposed) {
        exterior.dispose();
        return document;
      }
      if (exterior.available) {
        document.exteriorDecoration = exterior;
      } else {
        exterior.dispose();
      }
    }
    final atmospherePort = port;
    if (document.current.spatialScene != null &&
        atmospherePort is MapAtmospherePort) {
      final atmosphere = await MapAtmosphereController.open(
        session,
        entry.id,
        atmospherePort as MapAtmospherePort,
      );
      if (_disposed) {
        atmosphere.dispose();
        return document;
      }
      document.atmosphere = atmosphere;
    }
    if (document.current.spatialScene != null && port is ProjectVisualsPort) {
      final visuals = port as ProjectVisualsPort;
      _projectVisualProfile ??= (await visuals.loadVisuals(session)).profile;
      _mapVisualProfiles[entry.id] = (await visuals.loadVisuals(
        session,
        map: entry,
      )).profile;
      document.visualProfile = _projectVisualProfile!.overriddenBy(
        _mapVisualProfiles[entry.id]!,
      );
    }
    return document;
  }

  Future<MapData?> _previewMap(String id) {
    if (_disposed) return Future.value(null);
    _indexVisualScope(id);
    final entry = project?.maps.where((map) => map.id == id).firstOrNull;
    if (entry == null) return Future.value(null);
    final cached = _previews[id];
    if (cached != null) return cached;
    final mapEpoch = _mapEpochs[id];
    late final Future<MapData?> pending;
    pending = () async {
      try {
        final previewPort = port;
        final sourceEpoch = _modelSourceEpoch;
        final selection = previewPort is MapWorkspacePreviewSelectionPort
            ? await (previewPort as MapWorkspacePreviewSelectionPort)
                  .loadMapPreviewSelection(session, entry)
            : null;
        final loaded =
            selection?.document ?? await port.loadMap(session, entry);
        if (_disposed ||
            mapEpoch != _mapEpochs[id] ||
            !_entryDocumentCurrent(entry)) {
          return null;
        }
        if (selection != null) {
          _cachePreviewDefinitions(id, selection.definitions, sourceEpoch);
        }
        return loaded.map;
      } on Object {
        if (identical(_previews[id], pending)) _previews.remove(id);
        rethrow;
      }
    }();
    _previews[id] = pending;
    return pending;
  }
}
