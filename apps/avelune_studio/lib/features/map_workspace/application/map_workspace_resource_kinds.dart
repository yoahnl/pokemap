part of 'map_workspace_controller.dart';

extension MapWorkspaceResourceKinds on MapWorkspaceController {
  bool hasResourceKind(String kind, {bool placeableOnly = false}) =>
      hasCompleteProject ||
      _resourceKind == kind ||
      (placeableOnly && _resourceKind == _placeableKey(kind));

  static String _placeableKey(String kind) => '$kind:placeable';

  Future<void> _ensureResourceKind(String kind, {bool placeableOnly = false}) {
    if (_disposed || hasCompleteProject) return Future.value();
    if (hasResourceKind(kind, placeableOnly: placeableOnly) &&
        _resourceKindPending == 0) {
      return Future.value();
    }
    final request = ++_resourceKindRequest;
    _resourceKindPending++;
    final operation = _resourceKindQueue.then((_) async {
      if (_disposed || request != _resourceKindRequest) return;
      await ensureWorkshop(MapWorkspaceWorkshop.resources);
      final source = port;
      if (source is! MapWorkspaceResourceKindPort) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.unavailable,
          'Cette famille ne dispose pas de lecteur ciblé.',
        );
      }
      final sourceEpoch = _modelSourceEpoch;
      final loaded = await (source as MapWorkspaceResourceKindPort)
          .loadResourceKind(session, kind, placeableOnly: placeableOnly);
      if (_disposed || request != _resourceKindRequest) return;
      final map = _selections[active?.base.mapId]?.definitions ?? project!;
      _familyDefinitions = _prepareModelProjection(
        loaded.metadata,
        sourceEpoch: sourceEpoch,
      );
      _composeResourceVisuals();
      final family = _resourceVisualDefinitions!;
      _resourceVisualDefinitions = null;
      project = _prepareModelProjection(
        mergeResourceSelection(
          project!,
          combineResourceVisuals(_withWorkshops(map), family),
          library: loaded.metadata.resourceLibraryCatalog,
        ),
      );
      _resourceKind = placeableOnly ? _placeableKey(kind) : kind;
      _resourceVisualDefinitions = family;
      _cacheVisualComposition(map, _resourceVisualDefinitions!);
      notify();
    });
    _resourceKindQueue = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation.whenComplete(() {
      _resourceKindPending--;
    });
  }

  Future<void> prefetchResourceKinds(
    Iterable<String> kinds, {
    bool placeableOnly = false,
  }) async {
    final source = port;
    if (source is! MapWorkspaceResourcePrefetchPort) return;
    for (final kind in kinds) {
      if (_disposed || hasCompleteProject) return;
      await (source as MapWorkspaceResourcePrefetchPort).prefetchResourceKind(
        session,
        kind,
        placeableOnly: placeableOnly,
      );
    }
  }

  bool get hasBorderProfiles =>
      hasResourceKind('borderBlueprint') || _borderProfilesLoaded;
  bool hasBorderBlueprint(String id) =>
      hasResourceKind('borderBlueprint') || _borderBlueprints.contains(id);

  bool hasResourceClosure(String kind, String id) =>
      hasResourceKind(kind) ||
      (_resourceKind == _placeableKey(kind) &&
          !paletteListedResourceKinds.contains(kind)) ||
      _resourceClosures.contains('$kind:$id') ||
      (kind == 'borderBlueprint' && _borderBlueprints.contains(id));

  Future<void> ensureBorderBlueprint(String id) => _ensureOnDemandSelection(
    () => hasBorderBlueprint(id),
    (source) => _borderPort(source).loadBorderBlueprint(session, id),
    () => _borderBlueprints.add(id),
  );

  Future<void> ensureResourceClosure(String kind, String id) {
    if (kind == 'borderBlueprint') return ensureBorderBlueprint(id);
    return _ensureOnDemandSelection(() => hasResourceClosure(kind, id), (
      source,
    ) {
      if (source is! MapWorkspaceResourceClosurePort) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.unavailable,
          'Cette ressource ne dispose pas de lecteur ciblé.',
        );
      }
      return (source as MapWorkspaceResourceClosurePort).loadResourceClosure(
        session,
        kind,
        id,
      );
    }, () => _resourceClosures.add('$kind:$id'));
  }

  MapWorkspaceBorderProfilePort _borderPort(MapWorkspacePort source) {
    if (source is! MapWorkspaceBorderProfilePort) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Les bordures ne disposent pas de lecteur ciblé.',
      );
    }
    return source as MapWorkspaceBorderProfilePort;
  }

  Future<void> _ensureOnDemandSelection(
    bool Function() loaded,
    Future<MapWorkspaceCatalog> Function(MapWorkspacePort source) load,
    void Function() remember,
  ) {
    if (_disposed || loaded()) return Future.value();
    final operation = _resourceKindQueue.then((_) async {
      if (_disposed || loaded()) return;
      final sourceEpoch = _modelSourceEpoch;
      final selection = await load(port);
      if (_disposed || loaded()) return;
      final prepared = _prepareModelProjection(
        selection.metadata,
        sourceEpoch: sourceEpoch,
      );
      final previous = _onDemandDefinitions;
      _onDemandDefinitions = previous == null
          ? prepared
          : _prepareModelProjection(combineResourceVisuals(previous, prepared));
      remember();
      _composeResourceVisuals();
      project = _prepareModelProjection(
        mergeBorderSelection(project!, prepared),
      );
      final map = _selections[active?.base.mapId]?.definitions ?? project!;
      _cacheVisualComposition(map, _resourceVisualDefinitions!);
      notify();
    });
    _resourceKindQueue = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  void _composeResourceVisuals() {
    final family = _familyDefinitions;
    final borders = _onDemandDefinitions;
    _resourceVisualDefinitions = family == null
        ? borders
        : borders == null
        ? family
        : _prepareModelProjection(combineResourceVisuals(family, borders));
  }

  void _resetOnDemandSelections() {
    _onDemandDefinitions = null;
    _borderProfilesLoaded = false;
    _borderBlueprints.clear();
    _resourceClosures.clear();
  }
}
