part of 'package:map_editor/src/ui/canvas/map_canvas.dart';

enum EditorCanvasPictureCacheDisposition { hit, miss, animated }

@immutable
final class EditorCanvasPictureCacheEvent {
  const EditorCanvasPictureCacheEvent({
    required this.cacheId,
    required this.disposition,
  });

  final String cacheId;
  final EditorCanvasPictureCacheDisposition disposition;
}

typedef EditorCanvasPictureCacheObserver =
    void Function(EditorCanvasPictureCacheEvent event);

@immutable
final class EditorCanvasPaintRevisionSnapshot {
  EditorCanvasPaintRevisionSnapshot({
    required this.mapRevision,
    required this.projectRevision,
    required this.smartTileCatalogRevision,
    required this.assetsRevision,
    required this.overlayRevision,
    required this.geometryRevision,
    required this.placedElementsRevision,
    required this.entitiesRevision,
    required Map<String, int> layerRevisions,
  }) : layerRevisions = Map<String, int>.unmodifiable(layerRevisions);

  final int mapRevision;
  final int projectRevision;
  final int smartTileCatalogRevision;
  final int assetsRevision;
  final int overlayRevision;
  final int geometryRevision;
  final int placedElementsRevision;
  final int entitiesRevision;
  final Map<String, int> layerRevisions;

  int layerRevision(String layerId) => layerRevisions[layerId] ?? 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorCanvasPaintRevisionSnapshot &&
          other.mapRevision == mapRevision &&
          other.projectRevision == projectRevision &&
          other.smartTileCatalogRevision == smartTileCatalogRevision &&
          other.assetsRevision == assetsRevision &&
          other.overlayRevision == overlayRevision &&
          other.geometryRevision == geometryRevision &&
          other.placedElementsRevision == placedElementsRevision &&
          other.entitiesRevision == entitiesRevision &&
          mapEquals(other.layerRevisions, layerRevisions);

  @override
  int get hashCode => Object.hash(
    mapRevision,
    projectRevision,
    smartTileCatalogRevision,
    assetsRevision,
    overlayRevision,
    geometryRevision,
    placedElementsRevision,
    entitiesRevision,
    Object.hashAllUnordered(
      layerRevisions.entries.map(
        (entry) => Object.hash(entry.key, entry.value),
      ),
    ),
  );
}

final class EditorCanvasPictureCacheOwner {
  EditorCanvasPictureCacheOwner({
    this.maxEntries = 64,
    this.maxRevisionMaps = 8,
    this.maxSmartTileVisualPlans = 96,
  }) : assert(maxEntries > 0),
       assert(maxRevisionMaps > 0),
       assert(maxSmartTileVisualPlans > 0);

  final int maxEntries;
  final int maxRevisionMaps;
  final int maxSmartTileVisualPlans;
  final Map<_EditorCanvasPictureCacheKey, ui.Picture> _pictures = {};
  final Map<_EditorCanvasPictureCacheSlot, _EditorCanvasPictureCacheKey>
  _latestKeyBySlot = {};
  final Map<String, _EditorCanvasMapRevisionState> _mapRevisionStates = {};
  final Map<_EditorSmartTileVisualPlanKey, SmartTileLayerVisualPlan>
  _smartTileVisualPlans = {};
  final Map<_EditorSmartTileVisualPlanSlot, _EditorSmartTileVisualPlanKey>
  _latestSmartTileVisualPlanKeyBySlot = {};
  ProjectManifest? _project;
  ProjectSmartTileCatalog? _smartTileCatalog;
  Map<String, ui.Image?>? _imagesById;
  int _nextRevision = 0;
  int _projectRevision = 0;
  int _smartTileCatalogRevision = 0;
  int _assetsRevision = 0;
  int _hitCount = 0;
  int _missCount = 0;
  int _smartTileVisualPlanBuildCount = 0;
  int _smartTileVisualPlanHitCount = 0;
  bool _disposed = false;

  int get entryCount => _pictures.length;
  int get revisionMapCount => _mapRevisionStates.length;
  int get hitCount => _hitCount;
  int get missCount => _missCount;
  int get smartTileVisualPlanEntryCount => _smartTileVisualPlans.length;
  int get smartTileVisualPlanBuildCount => _smartTileVisualPlanBuildCount;
  int get smartTileVisualPlanHitCount => _smartTileVisualPlanHitCount;

  EditorCanvasPaintRevisionSnapshot resolveRevisions({
    required MapData map,
    required ProjectManifest? project,
    required Map<String, ui.Image?> imagesById,
    required Object overlayToken,
  }) {
    _ensureActive();
    final mapState =
        _mapRevisionStates.remove(map.id) ?? _EditorCanvasMapRevisionState();
    _mapRevisionStates[map.id] = mapState;
    while (_mapRevisionStates.length > maxRevisionMaps) {
      _mapRevisionStates.remove(_mapRevisionStates.keys.first);
    }
    if (!identical(mapState.map, map)) {
      final previousMap = mapState.map;
      mapState.map = map;
      mapState.mapRevision = ++_nextRevision;
      if (previousMap == null || previousMap.size != map.size) {
        mapState.geometryRevision = ++_nextRevision;
      }
      if (previousMap == null ||
          !listEquals(previousMap.placedElements, map.placedElements)) {
        mapState.placedElementsRevision = ++_nextRevision;
      }
      if (previousMap == null ||
          !listEquals(previousMap.entities, map.entities)) {
        mapState.entitiesRevision = ++_nextRevision;
      }
      final nextIds = <String>{};
      for (final layer in map.layers) {
        nextIds.add(layer.id);
        if (!identical(mapState.layersById[layer.id], layer)) {
          mapState.layersById[layer.id] = layer;
          mapState.layerRevisions[layer.id] = ++_nextRevision;
        }
      }
      for (final removedId
          in mapState.layersById.keys
              .where((id) => !nextIds.contains(id))
              .toList(growable: false)) {
        mapState.layersById.remove(removedId);
        mapState.layerRevisions.remove(removedId);
      }
    }
    final smartTileCatalog = project?.smartTileCatalog;
    if (_smartTileCatalog != smartTileCatalog) {
      _smartTileCatalogRevision = ++_nextRevision;
      _clearSmartTileVisualPlans();
    }
    _smartTileCatalog = smartTileCatalog;
    if (!identical(_project, project)) {
      _project = project;
      _projectRevision = ++_nextRevision;
      _clearPictures();
    }
    if (!_sameImages(_imagesById, imagesById)) {
      _imagesById = imagesById;
      _assetsRevision = ++_nextRevision;
      _clearPictures();
    }
    if (mapState.overlayToken != overlayToken) {
      mapState.overlayToken = overlayToken;
      mapState.overlayRevision = ++_nextRevision;
    }
    return EditorCanvasPaintRevisionSnapshot(
      mapRevision: mapState.mapRevision,
      projectRevision: _projectRevision,
      smartTileCatalogRevision: _smartTileCatalogRevision,
      assetsRevision: _assetsRevision,
      overlayRevision: mapState.overlayRevision,
      geometryRevision: mapState.geometryRevision,
      placedElementsRevision: mapState.placedElementsRevision,
      entitiesRevision: mapState.entitiesRevision,
      layerRevisions: mapState.layerRevisions,
    );
  }

  ui.Picture? _pictureFor(_EditorCanvasPictureCacheKey key) {
    _ensureActive();
    final picture = _pictures.remove(key);
    if (picture == null) {
      _missCount += 1;
      return null;
    }
    _hitCount += 1;
    _pictures[key] = picture;
    return picture;
  }

  void _store(_EditorCanvasPictureCacheKey key, ui.Picture picture) {
    _ensureActive();
    final previousKey = _latestKeyBySlot[key.slot];
    if (previousKey != null && previousKey != key) {
      _pictures.remove(previousKey)?.dispose();
    }
    _latestKeyBySlot[key.slot] = key;
    _pictures.remove(key)?.dispose();
    _pictures[key] = picture;
    while (_pictures.length > maxEntries) {
      final oldestKey = _pictures.keys.first;
      _pictures.remove(oldestKey)?.dispose();
      if (_latestKeyBySlot[oldestKey.slot] == oldestKey) {
        _latestKeyBySlot.remove(oldestKey.slot);
      }
    }
  }

  SmartTileLayerVisualPlan _resolveSmartTileVisualPlan({
    required MapData map,
    required SmartTileLayer layer,
    required ProjectSmartTileCatalog catalog,
    required SmartTileVisualPass pass,
    required EditorCanvasPaintRevisionSnapshot revisions,
    required double destinationCellWidth,
    required double destinationCellHeight,
    required double sourceCellWidth,
    required double sourceCellHeight,
    required SmartTilePatternOwnerIndex patternOwnerIndex,
  }) {
    _ensureActive();
    final slot = _EditorSmartTileVisualPlanSlot(
      mapId: map.id,
      layerId: layer.id,
      pass: pass,
      destinationCellWidth: destinationCellWidth,
      destinationCellHeight: destinationCellHeight,
      sourceCellWidth: sourceCellWidth,
      sourceCellHeight: sourceCellHeight,
    );
    final key = _EditorSmartTileVisualPlanKey(
      slot: slot,
      layerRevision: revisions.layerRevision(layer.id),
      smartTileCatalogRevision: revisions.smartTileCatalogRevision,
      geometryRevision: revisions.geometryRevision,
    );
    final cached = _smartTileVisualPlans.remove(key);
    if (cached != null) {
      _smartTileVisualPlanHitCount += 1;
      _smartTileVisualPlans[key] = cached;
      return cached;
    }
    final plan = buildSmartTileLayerVisualPlan(
      map: map,
      layer: layer,
      catalog: catalog,
      pass: pass,
      destinationCellWidth: destinationCellWidth,
      destinationCellHeight: destinationCellHeight,
      sourceCellWidth: sourceCellWidth,
      sourceCellHeight: sourceCellHeight,
      patternOwnerIndex: patternOwnerIndex,
    );
    _smartTileVisualPlanBuildCount += 1;
    final previousKey = _latestSmartTileVisualPlanKeyBySlot[slot];
    if (previousKey != null && previousKey != key) {
      _smartTileVisualPlans.remove(previousKey);
    }
    _latestSmartTileVisualPlanKeyBySlot[slot] = key;
    _smartTileVisualPlans[key] = plan;
    while (_smartTileVisualPlans.length > maxSmartTileVisualPlans) {
      final oldestKey = _smartTileVisualPlans.keys.first;
      _smartTileVisualPlans.remove(oldestKey);
      if (_latestSmartTileVisualPlanKeyBySlot[oldestKey.slot] == oldestKey) {
        _latestSmartTileVisualPlanKeyBySlot.remove(oldestKey.slot);
      }
    }
    return plan;
  }

  void clear() {
    _clearPictures();
    _clearSmartTileVisualPlans();
  }

  void _clearPictures() {
    for (final picture in _pictures.values) {
      picture.dispose();
    }
    _pictures.clear();
    _latestKeyBySlot.clear();
  }

  void _clearSmartTileVisualPlans() {
    _smartTileVisualPlans.clear();
    _latestSmartTileVisualPlanKeyBySlot.clear();
  }

  void dispose() {
    if (_disposed) return;
    clear();
    _mapRevisionStates.clear();
    _project = null;
    _smartTileCatalog = null;
    _imagesById = null;
    _disposed = true;
  }

  void _ensureActive() {
    if (_disposed) {
      throw StateError('EditorCanvasPictureCacheOwner is disposed.');
    }
  }
}

@immutable
final class _EditorSmartTileVisualPlanSlot {
  const _EditorSmartTileVisualPlanSlot({
    required this.mapId,
    required this.layerId,
    required this.pass,
    required this.destinationCellWidth,
    required this.destinationCellHeight,
    required this.sourceCellWidth,
    required this.sourceCellHeight,
  });

  final String mapId;
  final String layerId;
  final SmartTileVisualPass pass;
  final double destinationCellWidth;
  final double destinationCellHeight;
  final double sourceCellWidth;
  final double sourceCellHeight;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _EditorSmartTileVisualPlanSlot &&
          other.mapId == mapId &&
          other.layerId == layerId &&
          other.pass == pass &&
          other.destinationCellWidth == destinationCellWidth &&
          other.destinationCellHeight == destinationCellHeight &&
          other.sourceCellWidth == sourceCellWidth &&
          other.sourceCellHeight == sourceCellHeight;

  @override
  int get hashCode => Object.hash(
    mapId,
    layerId,
    pass,
    destinationCellWidth,
    destinationCellHeight,
    sourceCellWidth,
    sourceCellHeight,
  );
}

@immutable
final class _EditorSmartTileVisualPlanKey {
  const _EditorSmartTileVisualPlanKey({
    required this.slot,
    required this.layerRevision,
    required this.smartTileCatalogRevision,
    required this.geometryRevision,
  });

  final _EditorSmartTileVisualPlanSlot slot;
  final int layerRevision;
  final int smartTileCatalogRevision;
  final int geometryRevision;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _EditorSmartTileVisualPlanKey &&
          other.slot == slot &&
          other.layerRevision == layerRevision &&
          other.smartTileCatalogRevision == smartTileCatalogRevision &&
          other.geometryRevision == geometryRevision;

  @override
  int get hashCode => Object.hash(
    slot,
    layerRevision,
    smartTileCatalogRevision,
    geometryRevision,
  );
}

final class _EditorCanvasMapRevisionState {
  final Map<String, MapLayer> layersById = {};
  final Map<String, int> layerRevisions = {};
  MapData? map;
  Object? overlayToken;
  int mapRevision = 0;
  int overlayRevision = 0;
  int geometryRevision = 0;
  int placedElementsRevision = 0;
  int entitiesRevision = 0;
}

bool _sameImages(
  Map<String, ui.Image?>? previous,
  Map<String, ui.Image?> next,
) {
  if (identical(previous, next)) return true;
  if (previous == null || previous.length != next.length) return false;
  for (final entry in next.entries) {
    if (!previous.containsKey(entry.key) ||
        !identical(previous[entry.key], entry.value)) {
      return false;
    }
  }
  return true;
}

@immutable
final class _EditorCanvasPictureCacheSlot {
  const _EditorCanvasPictureCacheSlot({
    required this.mapId,
    required this.cacheId,
    required this.visibleBounds,
    required this.zoom,
    required this.tileWidth,
    required this.tileHeight,
  });

  final String mapId;
  final String cacheId;
  final EditorMapVisibleCellBounds visibleBounds;
  final double zoom;
  final double tileWidth;
  final double tileHeight;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _EditorCanvasPictureCacheSlot &&
          other.mapId == mapId &&
          other.cacheId == cacheId &&
          other.visibleBounds.left == visibleBounds.left &&
          other.visibleBounds.top == visibleBounds.top &&
          other.visibleBounds.right == visibleBounds.right &&
          other.visibleBounds.bottom == visibleBounds.bottom &&
          other.zoom == zoom &&
          other.tileWidth == tileWidth &&
          other.tileHeight == tileHeight;

  @override
  int get hashCode => Object.hash(
    mapId,
    cacheId,
    visibleBounds.left,
    visibleBounds.top,
    visibleBounds.right,
    visibleBounds.bottom,
    zoom,
    tileWidth,
    tileHeight,
  );
}

@immutable
final class _EditorCanvasPictureCacheKey {
  const _EditorCanvasPictureCacheKey({
    required this.slot,
    required this.revisionToken,
  });

  final _EditorCanvasPictureCacheSlot slot;
  final Object revisionToken;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _EditorCanvasPictureCacheKey &&
          other.slot == slot &&
          other.revisionToken == revisionToken;

  @override
  int get hashCode => Object.hash(slot, revisionToken);
}
