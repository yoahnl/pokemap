import 'package:map_core/map_core.dart';

export 'placed_element_placement_origin.dart';

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
    final layer = map.layers
        .whereType<TileLayer>()
        .where((entry) => entry.id == layerId)
        .firstOrNull;
    if (layer == null) {
      return map;
    }
    return replaceMapPlacedElementsForLayer(
      map,
      layerId: layerId,
      instances: resolveLayerInstances(
        map: map,
        project: project,
        layer: layer,
      ),
    );
  }

  List<MapPlacedElement> resolveLayerInstances({
    required MapData map,
    required ProjectManifest project,
    required TileLayer layer,
  }) {
    final layerId = layer.id;
    final protectedPlacements = _protectedPlacedElementsForLayer(map, layerId);
    final elements = project.elements
        .where(
          (entry) =>
              _resolveElementPrimaryTilesetId(entry).isNotEmpty &&
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
      return protectedPlacements;
    }

    final mapWidth = map.size.width;
    final mapHeight = map.size.height;
    if (mapWidth <= 0 || mapHeight <= 0) {
      return protectedPlacements;
    }

    final columnsByTilesetId = _resolveTilesetColumns(project);
    final existingByKey = <String, MapPlacedElement>{};
    final existingByPos = <String, MapPlacedElement>{};
    final reservedPlacementIds = <String>{
      for (final existing in map.placedElements) existing.id,
    };
    for (final existing in map.placedElements) {
      if (existing.layerId != layerId || !_isTileIndexed(existing)) {
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
    for (final instance in protectedPlacements) {
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
        final tile = _entryAt(
          layer: layer,
          mapWidth: mapWidth,
          mapHeight: mapHeight,
          x: x,
          y: y,
        );
        if (tile == null) {
          continue;
        }
        ProjectElementEntry? matched;
        TilesetSourceRect? source;
        for (final element in elements) {
          final elementTilesetId = _resolveElementPrimaryTilesetId(element);
          if (elementTilesetId != tile.tilesetId) continue;
          final columns = columnsByTilesetId[elementTilesetId] ?? 0;
          if (columns <= 0) continue;
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
            tilesetId: elementTilesetId,
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
              id: _reserveUniquePlacementId(
                buildMapPlacedElementId(
                  layerId: layerId,
                  elementId: matched.id,
                  pos: pos,
                ),
                reservedPlacementIds,
              ),
              layerId: layerId,
              elementId: matched.id,
              pos: pos,
              applyCollision: true,
              properties: const {
                pokemapPlacementOriginProperty: pokemapPlacementOriginTileIndex,
              },
            );
        instances.add(
          existing == null
              ? instance
              : instance.copyWith(
                  layerId: layerId,
                  elementId: matched.id,
                  pos: pos,
                  properties: {
                    ...instance.properties,
                    pokemapPlacementOriginProperty:
                        pokemapPlacementOriginTileIndex,
                  },
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

    final protectedIds = protectedPlacements.map((entry) => entry.id).toSet();
    final protectedPositions = protectedPlacements
        .map((entry) => _keyForPos(layerId: entry.layerId, pos: entry.pos))
        .toSet();
    return <MapPlacedElement>[
      ...protectedPlacements,
      ...instances.where(
        (entry) =>
            !protectedIds.contains(entry.id) &&
            !protectedPositions.contains(
              _keyForPos(layerId: entry.layerId, pos: entry.pos),
            ),
      ),
    ];
  }

  List<MapPlacedElement> _protectedPlacedElementsForLayer(
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
    return map.placedElements
        .where(
          (entry) =>
              entry.layerId == layerId &&
              (generatedIds.contains(entry.id) || !_isTileIndexed(entry)),
        )
        .toList(growable: false);
  }

  bool _isTileIndexed(MapPlacedElement entry) =>
      entry.properties[pokemapPlacementOriginProperty] ==
      pokemapPlacementOriginTileIndex;

  String _reserveUniquePlacementId(String baseId, Set<String> reservedIds) {
    if (reservedIds.add(baseId)) {
      return baseId;
    }
    var suffix = 2;
    while (!reservedIds.add('${baseId}_$suffix')) {
      suffix += 1;
    }
    return '${baseId}_$suffix';
  }

  Map<String, int> _resolveTilesetColumns(ProjectManifest project) {
    final tileWidth = project.settings.tileWidth;
    if (tileWidth <= 0) {
      return const {};
    }
    final out = <String, int>{};
    for (final tileset in project.tilesets) {
      final source = tileset.source;
      if (source is ProjectRegularAtlasTilesetSource) {
        out[tileset.id] = source.columns;
      }
    }
    return out;
  }

  String _resolveElementPrimaryTilesetId(ProjectElementEntry entry) {
    final frameTilesetId = entry.frames.primaryFrame.tilesetId.trim();
    if (frameTilesetId.isNotEmpty) {
      return frameTilesetId;
    }
    return entry.tilesetId.trim();
  }

  bool _matchesElementPatternAt({
    required TileLayer layer,
    required int mapWidth,
    required int mapHeight,
    required int originX,
    required int originY,
    required TilesetSourceRect source,
    required int tilesetColumns,
    required String tilesetId,
  }) {
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final tile = _entryAt(
          layer: layer,
          mapWidth: mapWidth,
          mapHeight: mapHeight,
          x: originX + x,
          y: originY + y,
        );
        final expectedTileId = (source.y + y) * tilesetColumns + (source.x + x);
        if (tile?.tilesetId != tilesetId ||
            tile?.localTileId != expectedTileId) {
          return false;
        }
      }
    }
    return true;
  }

  TileLayerPaletteEntry? _entryAt({
    required TileLayer layer,
    required int mapWidth,
    required int mapHeight,
    required int x,
    required int y,
  }) {
    if (x < 0 || y < 0 || x >= mapWidth || y >= mapHeight) {
      return null;
    }
    final index = y * mapWidth + x;
    return resolveTileLayerCell(layer, index);
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
