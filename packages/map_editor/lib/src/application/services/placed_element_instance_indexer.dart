import 'package:map_core/map_core.dart';

class PlacedElementInstanceIndexer {
  const PlacedElementInstanceIndexer();

  MapData syncAllTileLayers({
    required MapData map,
    required ProjectManifest project,
  }) {
    var next = map;
    for (final layer in map.layers) {
      if (layer is! TileLayer) {
        continue;
      }
      next = syncLayer(
        map: next,
        project: project,
        layerId: layer.id,
      );
    }
    return next;
  }

  MapData syncLayer({
    required MapData map,
    required ProjectManifest project,
    required String layerId,
  }) {
    final preservedGenerated =
        _environmentGeneratedPlacedElementsForLayer(map, layerId);
    final layer = map.layers
        .whereType<TileLayer>()
        .where((entry) => entry.id == layerId)
        .firstOrNull;
    if (layer == null) {
      return replaceMapPlacedElementsForLayer(
        map,
        layerId: layerId,
        instances: const [],
      );
    }
    final layerTilesetId = (layer.tilesetId ?? map.tilesetId).trim();
    if (layerTilesetId.isEmpty) {
      return _replaceLayerPlacedElements(
        map,
        layerId: layerId,
        preservedGenerated: preservedGenerated,
        indexedInstances: const [],
      );
    }

    final elements = project.elements
        .where(
          (entry) =>
              _resolveElementPrimaryTilesetId(entry) == layerTilesetId &&
              entry.frames.primarySource.width > 0 &&
              entry.frames.primarySource.height > 0,
        )
        .toList(growable: true)
      ..sort((a, b) {
        final areaA =
            a.frames.primarySource.width * a.frames.primarySource.height;
        final areaB =
            b.frames.primarySource.width * b.frames.primarySource.height;
        final areaCompare = areaB.compareTo(areaA);
        if (areaCompare != 0) {
          return areaCompare;
        }
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) {
          return sortCompare;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    if (elements.isEmpty) {
      return _replaceLayerPlacedElements(
        map,
        layerId: layerId,
        preservedGenerated: preservedGenerated,
        indexedInstances: const [],
      );
    }

    final mapWidth = map.size.width;
    final mapHeight = map.size.height;
    if (mapWidth <= 0 || mapHeight <= 0) {
      return _replaceLayerPlacedElements(
        map,
        layerId: layerId,
        preservedGenerated: preservedGenerated,
        indexedInstances: const [],
      );
    }

    final columnsByTilesetId = _resolveTilesetColumns(project);
    final baselineColumns = columnsByTilesetId[layerTilesetId] ?? 0;
    final columns = _resolveLayerTilesetColumns(
      layer: layer,
      mapWidth: mapWidth,
      mapHeight: mapHeight,
      elements: elements,
      minimumColumns: baselineColumns,
    );
    if (columns <= 0) {
      return map;
    }

    final existingByKey = <String, MapPlacedElement>{};
    final existingByPos = <String, MapPlacedElement>{};
    for (final existing in map.placedElements) {
      if (existing.layerId != layerId) {
        continue;
      }
      existingByKey[_keyFor(
        layerId: existing.layerId,
        elementId: existing.elementId,
        pos: existing.pos,
      )] = existing;
      existingByPos[_keyForPos(layerId: existing.layerId, pos: existing.pos)] =
          existing;
    }

    final covered =
        List<bool>.filled(mapWidth * mapHeight, false, growable: false);
    final instances = <MapPlacedElement>[];
    final preservedPositions = <String>{};
    for (final instance in preservedGenerated) {
      preservedPositions.add(
        _keyForPos(layerId: instance.layerId, pos: instance.pos),
      );
    }

    for (var y = 0; y < mapHeight; y++) {
      for (var x = 0; x < mapWidth; x++) {
        final index = y * mapWidth + x;
        if (covered[index]) {
          continue;
        }
        final tileId = _tileAt(
          tiles: layer.tiles,
          mapWidth: mapWidth,
          mapHeight: mapHeight,
          x: x,
          y: y,
        );
        if (tileId <= 0) {
          continue;
        }
        ProjectElementEntry? matched;
        TilesetSourceRect? source;
        for (final element in elements) {
          final candidateSource = element.frames.primarySource;
          if (x + candidateSource.width > mapWidth ||
              y + candidateSource.height > mapHeight) {
            continue;
          }
          if (!_canUseCells(
            covered: covered,
            mapWidth: mapWidth,
            x: x,
            y: y,
            width: candidateSource.width,
            height: candidateSource.height,
          )) {
            continue;
          }
          final matches = _matchesElementPatternAt(
            layer: layer,
            mapWidth: mapWidth,
            mapHeight: mapHeight,
            originX: x,
            originY: y,
            source: candidateSource,
            tilesetColumns: columns,
          );
          if (!matches) {
            continue;
          }
          matched = element;
          source = candidateSource;
          break;
        }
        if (matched == null || source == null) {
          continue;
        }

        final pos = GridPos(x: x, y: y);
        final posKey = _keyForPos(layerId: layerId, pos: pos);
        if (preservedPositions.contains(posKey)) {
          _markCellsAsCovered(
            covered: covered,
            mapWidth: mapWidth,
            x: x,
            y: y,
            width: source.width,
            height: source.height,
          );
          continue;
        }
        final key = _keyFor(
          layerId: layerId,
          elementId: matched.id,
          pos: pos,
        );
        final existing = existingByKey[key] ?? existingByPos[posKey];
        final instance = existing ??
            MapPlacedElement(
              id: buildMapPlacedElementId(
                layerId: layerId,
                elementId: matched.id,
                pos: pos,
              ),
              layerId: layerId,
              elementId: matched.id,
              pos: pos,
              applyCollision: true,
            );
        instances.add(
          existing == null
              ? instance
              : instance.copyWith(
                  layerId: layerId,
                  elementId: matched.id,
                  pos: pos,
                ),
        );
        _markCellsAsCovered(
          covered: covered,
          mapWidth: mapWidth,
          x: x,
          y: y,
          width: source.width,
          height: source.height,
        );
      }
    }

    instances.sort((a, b) {
      final yCompare = a.pos.y.compareTo(b.pos.y);
      if (yCompare != 0) {
        return yCompare;
      }
      final xCompare = a.pos.x.compareTo(b.pos.x);
      if (xCompare != 0) {
        return xCompare;
      }
      return a.elementId.compareTo(b.elementId);
    });

    return _replaceLayerPlacedElements(
      map,
      layerId: layerId,
      preservedGenerated: preservedGenerated,
      indexedInstances: instances,
    );
  }

  List<MapPlacedElement> _environmentGeneratedPlacedElementsForLayer(
    MapData map,
    String layerId,
  ) {
    final generatedIds = <String>{};
    for (final layer in map.layers.whereType<EnvironmentLayer>()) {
      for (final area in layer.content.areas) {
        for (final id in area.generatedPlacementIds) {
          final trimmed = id.trim();
          if (trimmed.isNotEmpty) {
            generatedIds.add(trimmed);
          }
        }
      }
    }
    if (generatedIds.isEmpty) {
      return const <MapPlacedElement>[];
    }
    return map.placedElements
        .where(
          (entry) =>
              entry.layerId == layerId && generatedIds.contains(entry.id),
        )
        .toList(growable: false);
  }

  MapData _replaceLayerPlacedElements(
    MapData map, {
    required String layerId,
    required List<MapPlacedElement> preservedGenerated,
    required List<MapPlacedElement> indexedInstances,
  }) {
    final preservedIds = preservedGenerated.map((entry) => entry.id).toSet();
    return replaceMapPlacedElementsForLayer(
      map,
      layerId: layerId,
      instances: [
        ...preservedGenerated,
        ...indexedInstances.where((entry) => !preservedIds.contains(entry.id)),
      ],
    );
  }

  Map<String, int> _resolveTilesetColumns(ProjectManifest project) {
    final tileWidth = project.settings.tileWidth;
    if (tileWidth <= 0) {
      return const {};
    }
    final out = <String, int>{};
    for (final tileset in project.tilesets) {
      final maxRight = _maxFrameRightForTileset(
        project: project,
        tilesetId: tileset.id,
      );
      if (maxRight > 0) {
        out[tileset.id] = maxRight;
      }
    }
    return out;
  }

  int _maxFrameRightForTileset({
    required ProjectManifest project,
    required String tilesetId,
  }) {
    var maxRight = 0;
    for (final element in project.elements) {
      if (_resolveElementPrimaryTilesetId(element) != tilesetId) {
        continue;
      }
      final source = element.frames.primarySource;
      final right = source.x + source.width;
      if (right > maxRight) {
        maxRight = right;
      }
    }
    for (final entry in project.tilesets) {
      if (entry.id != tilesetId) {
        continue;
      }
      for (final palette in entry.paletteEntries) {
        final source = palette.frames.primarySource;
        final right = source.x + source.width;
        if (right > maxRight) {
          maxRight = right;
        }
      }
    }
    return maxRight;
  }

  String _resolveElementPrimaryTilesetId(ProjectElementEntry entry) {
    final frameTilesetId = entry.frames.primaryFrame.tilesetId.trim();
    if (frameTilesetId.isNotEmpty) {
      return frameTilesetId;
    }
    return entry.tilesetId.trim();
  }

  int _resolveLayerTilesetColumns({
    required TileLayer layer,
    required int mapWidth,
    required int mapHeight,
    required List<ProjectElementEntry> elements,
    required int minimumColumns,
  }) {
    if (elements.isEmpty) {
      return minimumColumns;
    }
    final minColumns = minimumColumns > 0 ? minimumColumns : 1;
    final uniqueTileIds = <int>{};
    for (final tileId in layer.tiles) {
      if (tileId > 0) {
        uniqueTileIds.add(tileId);
      }
    }
    if (uniqueTileIds.isEmpty) {
      return minColumns;
    }
    final candidates = <int>{minColumns};
    final verticalDiffCandidates = _collectVerticalDiffCandidates(
      layer: layer,
      mapWidth: mapWidth,
      mapHeight: mapHeight,
    );
    for (final candidate in verticalDiffCandidates) {
      if (candidate < minColumns || candidate > 4096) {
        continue;
      }
      candidates.add(candidate);
    }
    for (final tileId in uniqueTileIds) {
      for (final element in elements) {
        final source = element.frames.primarySource;
        if (source.y <= 0) {
          continue;
        }
        final numerator = tileId - source.x - 1;
        if (numerator <= 0) {
          continue;
        }
        if (numerator % source.y != 0) {
          continue;
        }
        final candidate = numerator ~/ source.y;
        if (candidate < minColumns) {
          continue;
        }
        if (candidate > 4096) {
          continue;
        }
        candidates.add(candidate);
      }
    }
    if (candidates.length == 1) {
      return minColumns;
    }

    final sortedCandidates = candidates.toList(growable: false)..sort();
    var bestColumns = minColumns;
    var bestScore = _scoreColumns(
      layer: layer,
      mapWidth: mapWidth,
      mapHeight: mapHeight,
      elements: elements,
      columns: minColumns,
    );

    for (final candidate in sortedCandidates) {
      if (candidate == minColumns) {
        continue;
      }
      final score = _scoreColumns(
        layer: layer,
        mapWidth: mapWidth,
        mapHeight: mapHeight,
        elements: elements,
        columns: candidate,
      );
      if (score > bestScore) {
        bestScore = score;
        bestColumns = candidate;
      }
    }
    return bestColumns;
  }

  Set<int> _collectVerticalDiffCandidates({
    required TileLayer layer,
    required int mapWidth,
    required int mapHeight,
  }) {
    final out = <int>{};
    for (var y = 0; y < mapHeight - 1; y++) {
      for (var x = 0; x < mapWidth; x++) {
        final top = _tileAt(
          tiles: layer.tiles,
          mapWidth: mapWidth,
          mapHeight: mapHeight,
          x: x,
          y: y,
        );
        final bottom = _tileAt(
          tiles: layer.tiles,
          mapWidth: mapWidth,
          mapHeight: mapHeight,
          x: x,
          y: y + 1,
        );
        if (top <= 0 || bottom <= 0) {
          continue;
        }
        final diff = bottom - top;
        if (diff <= 0) {
          continue;
        }
        out.add(diff);
      }
    }
    return out;
  }

  int _scoreColumns({
    required TileLayer layer,
    required int mapWidth,
    required int mapHeight,
    required List<ProjectElementEntry> elements,
    required int columns,
  }) {
    var score = 0;
    for (var originY = 0; originY < mapHeight; originY++) {
      for (var originX = 0; originX < mapWidth; originX++) {
        final tileId = _tileAt(
          tiles: layer.tiles,
          mapWidth: mapWidth,
          mapHeight: mapHeight,
          x: originX,
          y: originY,
        );
        if (tileId <= 0) {
          continue;
        }
        for (final element in elements) {
          final source = element.frames.primarySource;
          if (originX + source.width > mapWidth ||
              originY + source.height > mapHeight) {
            continue;
          }
          final expectedTopLeft = source.y * columns + source.x + 1;
          if (tileId != expectedTopLeft) {
            continue;
          }
          if (_matchesElementPatternAt(
            layer: layer,
            mapWidth: mapWidth,
            mapHeight: mapHeight,
            originX: originX,
            originY: originY,
            source: source,
            tilesetColumns: columns,
          )) {
            score++;
          }
        }
      }
    }
    return score;
  }

  bool _matchesElementPatternAt({
    required TileLayer layer,
    required int mapWidth,
    required int mapHeight,
    required int originX,
    required int originY,
    required TilesetSourceRect source,
    required int tilesetColumns,
  }) {
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final tileId = _tileAt(
          tiles: layer.tiles,
          mapWidth: mapWidth,
          mapHeight: mapHeight,
          x: originX + x,
          y: originY + y,
        );
        final expectedTileId =
            (source.y + y) * tilesetColumns + (source.x + x) + 1;
        if (tileId != expectedTileId) {
          return false;
        }
      }
    }
    return true;
  }

  int _tileAt({
    required List<int> tiles,
    required int mapWidth,
    required int mapHeight,
    required int x,
    required int y,
  }) {
    if (x < 0 || y < 0 || x >= mapWidth || y >= mapHeight) {
      return 0;
    }
    final index = y * mapWidth + x;
    if (index < 0 || index >= tiles.length) {
      return 0;
    }
    return tiles[index];
  }

  bool _canUseCells({
    required List<bool> covered,
    required int mapWidth,
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    for (var row = 0; row < height; row++) {
      for (var col = 0; col < width; col++) {
        final index = (y + row) * mapWidth + (x + col);
        if (index < 0 || index >= covered.length) {
          return false;
        }
        if (covered[index]) {
          return false;
        }
      }
    }
    return true;
  }

  void _markCellsAsCovered({
    required List<bool> covered,
    required int mapWidth,
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    for (var row = 0; row < height; row++) {
      for (var col = 0; col < width; col++) {
        final index = (y + row) * mapWidth + (x + col);
        if (index < 0 || index >= covered.length) {
          continue;
        }
        covered[index] = true;
      }
    }
  }

  String _keyFor({
    required String layerId,
    required String elementId,
    required GridPos pos,
  }) {
    return '$layerId::$elementId::${pos.x}::${pos.y}';
  }

  String _keyForPos({
    required String layerId,
    required GridPos pos,
  }) {
    return '$layerId::${pos.x}::${pos.y}';
  }
}

extension on Iterable<TileLayer> {
  TileLayer? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
