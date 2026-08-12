import 'package:map_core/map_core.dart';

enum MapCellStrokeLayerKind { tile, collision, smartTile }

final class MapCellStrokeBuffer {
  MapCellStrokeBuffer.tile({
    required MapData sourceMap,
    required String layerId,
    void Function()? onChanged,
  }) : this._(
         sourceMap: sourceMap,
         layerId: layerId,
         kind: MapCellStrokeLayerKind.tile,
         onChanged: onChanged,
       );

  MapCellStrokeBuffer.collision({
    required MapData sourceMap,
    required String layerId,
    void Function()? onChanged,
  }) : this._(
         sourceMap: sourceMap,
         layerId: layerId,
         kind: MapCellStrokeLayerKind.collision,
         onChanged: onChanged,
       );

  MapCellStrokeBuffer.smartTile({
    required MapData sourceMap,
    required String layerId,
    void Function()? onChanged,
  }) : this._(
         sourceMap: sourceMap,
         layerId: layerId,
         kind: MapCellStrokeLayerKind.smartTile,
         onChanged: onChanged,
       );

  MapCellStrokeBuffer._({
    required MapData sourceMap,
    required this.layerId,
    required this.kind,
    required void Function()? onChanged,
  }) : _sourceMap = sourceMap,
       _layerIndex = sourceMap.layers.indexWhere(
         (layer) => layer.id == layerId,
       ),
       _onChanged = onChanged {
    if (_layerIndex < 0) {
      throw ValidationException('Layer not found: $layerId');
    }
    final layer = sourceMap.layers[_layerIndex];
    if (kind == MapCellStrokeLayerKind.tile && layer is! TileLayer) {
      throw ValidationException('Active layer is not a tile layer: $layerId');
    }
    if (kind == MapCellStrokeLayerKind.collision && layer is! CollisionLayer) {
      throw ValidationException(
        'Active layer is not a collision layer: $layerId',
      );
    }
    if (kind == MapCellStrokeLayerKind.smartTile && layer is! SmartTileLayer) {
      throw ValidationException(
        'Active layer is not a Smart Tile layer: $layerId',
      );
    }
  }

  MapData _sourceMap;
  MapData get sourceMap => _sourceMap;
  final String layerId;
  final MapCellStrokeLayerKind kind;
  final int _layerIndex;
  final void Function()? _onChanged;
  final Map<int, TileLayerPaletteEntry?> _tileOverrides =
      <int, TileLayerPaletteEntry?>{};
  final List<TileLayerPaletteEntry> _tilePaletteAdditions =
      <TileLayerPaletteEntry>[];
  final Map<int, bool> _collisionOverrides = <int, bool>{};
  final Map<int, String?> _smartTileCellOverrides = <int, String?>{};
  final Map<int, String?> _smartTileHorizontalEdgeOverrides = <int, String?>{};
  final Map<int, String?> _smartTileVerticalEdgeOverrides = <int, String?>{};
  final Map<int, String?> _smartTileCornerOverrides = <int, String?>{};
  final Set<int> _smartTileTouchedCellIndices = <int>{};
  GridPos? _lastOrigin;
  int _revision = 0;
  int _fullLayerCopyCount = 0;
  int _mapMaterializationCount = 0;
  int _validationCount = 0;

  int get revision => _revision;
  int get touchedCellCount => switch (kind) {
    MapCellStrokeLayerKind.tile => _tileOverrides.length,
    MapCellStrokeLayerKind.collision => _collisionOverrides.length,
    MapCellStrokeLayerKind.smartTile => _smartTileTouchedCellIndices.length,
  };
  bool get hasChanges => switch (kind) {
    MapCellStrokeLayerKind.tile =>
      _tileOverrides.isNotEmpty || _tilePaletteAdditions.isNotEmpty,
    MapCellStrokeLayerKind.collision => _collisionOverrides.isNotEmpty,
    MapCellStrokeLayerKind.smartTile =>
      _smartTileCellOverrides.isNotEmpty ||
          _smartTileHorizontalEdgeOverrides.isNotEmpty ||
          _smartTileVerticalEdgeOverrides.isNotEmpty ||
          _smartTileCornerOverrides.isNotEmpty,
  };
  int get fullLayerCopyCount => _fullLayerCopyCount;
  int get mapMaterializationCount => _mapMaterializationCount;
  int get validationCount => _validationCount;

  Iterable<GridPos> get smartTileTouchedCells sync* {
    if (kind != MapCellStrokeLayerKind.smartTile) return;
    for (final index in _smartTileTouchedCellIndices) {
      yield GridPos(
        x: index % sourceMap.size.width,
        y: index ~/ sourceMap.size.width,
      );
    }
  }

  TileLayerPaletteEntry? tileAt(int index) {
    if (kind != MapCellStrokeLayerKind.tile) return null;
    if (_tileOverrides.containsKey(index)) return _tileOverrides[index];
    return resolveTileLayerCell(
      sourceMap.layers[_layerIndex] as TileLayer,
      index,
    );
  }

  bool collisionAt(int index) {
    if (kind != MapCellStrokeLayerKind.collision) return false;
    final override = _collisionOverrides[index];
    if (override != null) return override;
    final source = sourceMap.layers[_layerIndex] as CollisionLayer;
    return index >= 0 &&
        index < source.collisions.length &&
        source.collisions[index];
  }

  String? smartTileMaterialAt(int x, int y) {
    if (kind != MapCellStrokeLayerKind.smartTile) return null;
    _validateSmartTileCoordinate(
      x,
      y,
      sourceMap.size.width,
      sourceMap.size.height,
    );
    final index = y * sourceMap.size.width + x;
    if (_smartTileCellOverrides.containsKey(index)) {
      return _smartTileCellOverrides[index];
    }
    return smartTileMaterialIdAt(
      sourceMap.layers[_layerIndex] as SmartTileLayer,
      mapSize: sourceMap.size,
      x: x,
      y: y,
    );
  }

  SmartTileCellContext smartTileContextAt({
    required ProjectSmartTilePreset preset,
    required int x,
    required int y,
  }) {
    if (kind != MapCellStrokeLayerKind.smartTile) {
      throw StateError('The stroke does not target a Smart Tile layer');
    }
    final width = sourceMap.size.width;
    final height = sourceMap.size.height;
    _validateSmartTileCoordinate(x, y, width, height);
    if (preset.topology == SmartTileTopology.uniform ||
        preset.topology == SmartTileTopology.cardinal4 ||
        preset.topology == SmartTileTopology.blob8) {
      return SmartTileCellContext.fromCellGrid(
        width: width,
        height: height,
        x: x,
        y: y,
        materialAt: smartTileMaterialAt,
      );
    }
    SmartTileObservedSlot horizontal(int edgeX, int edgeY) =>
        SmartTileObservedSlot.inside(
          materialId: _smartTileHorizontalEdgeMaterialIdAt(edgeX, edgeY),
        );
    SmartTileObservedSlot vertical(int edgeX, int edgeY) =>
        SmartTileObservedSlot.inside(
          materialId: _smartTileVerticalEdgeMaterialIdAt(edgeX, edgeY),
        );
    SmartTileObservedSlot corner(int cornerX, int cornerY) =>
        SmartTileObservedSlot.inside(
          materialId: _smartTileCornerMaterialIdAt(cornerX, cornerY),
        );
    return switch (preset.topology) {
      SmartTileTopology.wangEdge4 => SmartTileCellContext(
        centerMaterialId: smartTileMaterialAt(x, y),
        observed: SmartTileObservedSignature(
          northEdge: horizontal(x, y),
          eastEdge: vertical(x + 1, y),
          southEdge: horizontal(x, y + 1),
          westEdge: vertical(x, y),
        ),
      ),
      SmartTileTopology.wangCorner4 => SmartTileCellContext(
        centerMaterialId: smartTileMaterialAt(x, y),
        observed: SmartTileObservedSignature(
          northEastCorner: corner(x + 1, y),
          southEastCorner: corner(x + 1, y + 1),
          southWestCorner: corner(x, y + 1),
          northWestCorner: corner(x, y),
        ),
      ),
      SmartTileTopology.wang8 => SmartTileCellContext(
        centerMaterialId: smartTileMaterialAt(x, y),
        observed: SmartTileObservedSignature(
          northEdge: horizontal(x, y),
          northEastCorner: corner(x + 1, y),
          eastEdge: vertical(x + 1, y),
          southEastCorner: corner(x + 1, y + 1),
          southEdge: horizontal(x, y + 1),
          southWestCorner: corner(x, y + 1),
          westEdge: vertical(x, y),
          northWestCorner: corner(x, y),
        ),
      ),
      SmartTileTopology.uniform ||
      SmartTileTopology.cardinal4 ||
      SmartTileTopology.blob8 => throw StateError(
        'Cell topologies are handled before lattice sampling.',
      ),
    };
  }

  bool smartTileCellHasAuthoredValue(int x, int y) {
    if (smartTileMaterialAt(x, y) != null) return true;
    final layer = sourceMap.layers[_layerIndex] as SmartTileLayer;
    if (layer.field is SmartTileEdgeField ||
        layer.field is SmartTileMixedField) {
      if (_smartTileHorizontalEdgeMaterialIdAt(x, y) != null ||
          _smartTileHorizontalEdgeMaterialIdAt(x, y + 1) != null ||
          _smartTileVerticalEdgeMaterialIdAt(x, y) != null ||
          _smartTileVerticalEdgeMaterialIdAt(x + 1, y) != null) {
        return true;
      }
    }
    if (layer.field is SmartTileCornerField ||
        layer.field is SmartTileMixedField) {
      return _smartTileCornerMaterialIdAt(x, y) != null ||
          _smartTileCornerMaterialIdAt(x + 1, y) != null ||
          _smartTileCornerMaterialIdAt(x, y + 1) != null ||
          _smartTileCornerMaterialIdAt(x + 1, y + 1) != null;
    }
    return false;
  }

  bool setSmartTileMaterials({
    required Iterable<GridPos> cells,
    required String? materialId,
  }) {
    if (kind != MapCellStrokeLayerKind.smartTile) {
      throw StateError('The stroke does not target a Smart Tile layer');
    }
    final canonicalMaterialId = materialId?.trim();
    if (materialId != null &&
        (canonicalMaterialId!.isEmpty || canonicalMaterialId != materialId)) {
      throw const ValidationException('Smart Tile material must be canonical');
    }
    final layer = sourceMap.layers[_layerIndex] as SmartTileLayer;
    final width = sourceMap.size.width;
    final height = sourceMap.size.height;
    final verticalStride = width + 1;
    var changed = false;
    for (final cell in cells) {
      _validateSmartTileCoordinate(cell.x, cell.y, width, height);
      final cellIndex = cell.y * width + cell.x;
      var cellChanged = _setSmartTileOverride(
        _smartTileCellOverrides,
        cellIndex,
        materialId,
        _sourceSmartTileMaterialAt(cell.x, cell.y),
      );
      if (layer.field is SmartTileEdgeField ||
          layer.field is SmartTileMixedField) {
        for (final index in <int>[
          cell.y * width + cell.x,
          (cell.y + 1) * width + cell.x,
        ]) {
          cellChanged =
              _setSmartTileOverride(
                _smartTileHorizontalEdgeOverrides,
                index,
                materialId,
                _sourceHorizontalMaterialAtIndex(index),
              ) ||
              cellChanged;
        }
        for (final index in <int>[
          cell.y * verticalStride + cell.x,
          cell.y * verticalStride + cell.x + 1,
        ]) {
          cellChanged =
              _setSmartTileOverride(
                _smartTileVerticalEdgeOverrides,
                index,
                materialId,
                _sourceVerticalMaterialAtIndex(index),
              ) ||
              cellChanged;
        }
      }
      if (layer.field is SmartTileCornerField ||
          layer.field is SmartTileMixedField) {
        for (final index in <int>[
          cell.y * verticalStride + cell.x,
          cell.y * verticalStride + cell.x + 1,
          (cell.y + 1) * verticalStride + cell.x,
          (cell.y + 1) * verticalStride + cell.x + 1,
        ]) {
          cellChanged =
              _setSmartTileOverride(
                _smartTileCornerOverrides,
                index,
                materialId,
                _sourceCornerMaterialAtIndex(index),
              ) ||
              cellChanged;
        }
      }
      if (cellChanged) {
        _smartTileTouchedCellIndices.add(cellIndex);
        changed = true;
      }
    }
    if (changed) _publish();
    return changed;
  }

  bool setSmartTileMaterialAt({
    required GridPos origin,
    required String? materialId,
  }) {
    final changed = setSmartTileMaterials(
      cells: _pointsTo(origin),
      materialId: materialId,
    );
    _lastOrigin = origin;
    return changed;
  }

  void rebaseSmartTileSource(MapData map) {
    if (kind != MapCellStrokeLayerKind.smartTile ||
        map.id != sourceMap.id ||
        map.size != sourceMap.size ||
        _layerIndex >= map.layers.length ||
        map.layers[_layerIndex] is! SmartTileLayer ||
        map.layers[_layerIndex].id != layerId) {
      throw const ValidationException(
        'Smart Tile stroke cannot rebase onto an incompatible map',
      );
    }
    _sourceMap = map;
    _removeMatchingSmartTileOverrides(
      _smartTileCellOverrides,
      (index) {
        final x = index % map.size.width;
        final y = index ~/ map.size.width;
        return _sourceSmartTileMaterialAt(x, y);
      },
    );
    _removeMatchingSmartTileOverrides(
      _smartTileHorizontalEdgeOverrides,
      _sourceHorizontalMaterialAtIndex,
    );
    _removeMatchingSmartTileOverrides(
      _smartTileVerticalEdgeOverrides,
      _sourceVerticalMaterialAtIndex,
    );
    _removeMatchingSmartTileOverrides(
      _smartTileCornerOverrides,
      _sourceCornerMaterialAtIndex,
    );
    _publish();
  }

  void paintTiles({
    required GridPos origin,
    required GridSize patternSize,
    required List<TileLayerPaletteEntry?> tiles,
    bool clipToMapBounds = true,
  }) {
    if (kind != MapCellStrokeLayerKind.tile) {
      throw StateError('The stroke does not target a tile layer');
    }
    _validatePattern(patternSize, tiles.length);
    for (var i = 0; i < patternSize.width * patternSize.height; i++) {
      final tile = tiles[i];
      if (tile != null &&
          (tile.tilesetId.trim().isEmpty ||
              tile.tilesetId != tile.tilesetId.trim() ||
              tile.localTileId < 0)) {
        throw const ValidationException('Pattern tiles must be canonical');
      }
    }
    if (!clipToMapBounds) _validatePatternBounds(origin, patternSize);
    var changed = false;
    for (final point in _pointsTo(origin)) {
      changed =
          _applyTilePattern(point, patternSize, tiles, clipToMapBounds) ||
          changed;
    }
    _lastOrigin = origin;
    if (changed) _publish();
  }

  void setCollisions({
    required GridPos origin,
    required GridSize patternSize,
    required bool value,
    bool clipToMapBounds = true,
  }) {
    if (kind != MapCellStrokeLayerKind.collision) {
      throw StateError('The stroke does not target a collision layer');
    }
    _validatePattern(patternSize, patternSize.width * patternSize.height);
    if (!clipToMapBounds) _validatePatternBounds(origin, patternSize);
    var changed = false;
    for (final point in _pointsTo(origin)) {
      changed =
          _applyCollisionPattern(point, patternSize, value, clipToMapBounds) ||
          changed;
    }
    _lastOrigin = origin;
    if (changed) _publish();
  }

  void breakInterpolation() {
    _lastOrigin = null;
  }

  MapData commit({
    required void Function(MapData map) validate,
    List<MapPlacedElement> Function(TileLayer layer)? resolvePlacedElements,
  }) {
    if (!hasChanges) return sourceMap;
    final layers = List<MapLayer>.of(sourceMap.layers, growable: false);
    final materializedLayer = switch (kind) {
      MapCellStrokeLayerKind.tile => _materializeTileLayer(),
      MapCellStrokeLayerKind.collision => _materializeCollisionLayer(),
      MapCellStrokeLayerKind.smartTile => _materializeSmartTileLayer(),
    };
    layers[_layerIndex] = materializedLayer;
    _mapMaterializationCount += 1;
    final layerPlacedElements =
        materializedLayer is TileLayer && resolvePlacedElements != null
        ? resolvePlacedElements(materializedLayer)
        : null;
    final committed = layerPlacedElements == null
        ? sourceMap.copyWith(layers: layers)
        : sourceMap.copyWith(
            layers: layers,
            placedElements: <MapPlacedElement>[
              ...sourceMap.placedElements.where(
                (entry) => entry.layerId != layerId,
              ),
              ...layerPlacedElements,
            ],
          );
    _validationCount += 1;
    validate(committed);
    return committed;
  }

  void _validatePattern(GridSize size, int availableCells) {
    if (size.width <= 0 || size.height <= 0) {
      throw const ValidationException('Pattern size must be positive');
    }
    if (availableCells < size.width * size.height) {
      throw const ValidationException('Pattern tile data is incomplete');
    }
  }

  void _validatePatternBounds(GridPos origin, GridSize size) {
    if (!_isInBounds(origin.x, origin.y) ||
        !_isInBounds(origin.x + size.width - 1, origin.y + size.height - 1)) {
      throw const ValidationException('Paint position is outside map bounds');
    }
  }

  Iterable<GridPos> _pointsTo(GridPos target) sync* {
    final start = _lastOrigin;
    if (start == null) {
      yield target;
      return;
    }
    var x = start.x;
    var y = start.y;
    final dx = (target.x - x).abs();
    final sx = x < target.x ? 1 : -1;
    final dy = -(target.y - y).abs();
    final sy = y < target.y ? 1 : -1;
    var error = dx + dy;
    while (true) {
      yield GridPos(x: x, y: y);
      if (x == target.x && y == target.y) break;
      final doubled = error * 2;
      if (doubled >= dy) {
        error += dy;
        x += sx;
      }
      if (doubled <= dx) {
        error += dx;
        y += sy;
      }
    }
  }

  bool _applyTilePattern(
    GridPos origin,
    GridSize size,
    List<TileLayerPaletteEntry?> tiles,
    bool clipToMapBounds,
  ) {
    var changed = false;
    for (var y = 0; y < size.height; y++) {
      for (var x = 0; x < size.width; x++) {
        final mapX = origin.x + x;
        final mapY = origin.y + y;
        if (!_isInBounds(mapX, mapY)) {
          if (clipToMapBounds) continue;
          throw const ValidationException(
            'Paint position is outside map bounds',
          );
        }
        final index = mapY * sourceMap.size.width + mapX;
        final value = tiles[y * size.width + x];
        if (tileAt(index) == value) continue;
        if (value != null &&
            !(sourceMap.layers[_layerIndex] as TileLayer).palette.contains(
              value,
            ) &&
            !_tilePaletteAdditions.contains(value)) {
          _tilePaletteAdditions.add(value);
        }
        final sourceValue = resolveTileLayerCell(
          sourceMap.layers[_layerIndex] as TileLayer,
          index,
        );
        if (sourceValue == value) {
          _tileOverrides.remove(index);
        } else {
          _tileOverrides[index] = value;
        }
        changed = true;
      }
    }
    return changed;
  }

  bool _applyCollisionPattern(
    GridPos origin,
    GridSize size,
    bool value,
    bool clipToMapBounds,
  ) {
    var changed = false;
    for (var y = 0; y < size.height; y++) {
      for (var x = 0; x < size.width; x++) {
        final mapX = origin.x + x;
        final mapY = origin.y + y;
        if (!_isInBounds(mapX, mapY)) {
          if (clipToMapBounds) continue;
          throw const ValidationException(
            'Paint position is outside map bounds',
          );
        }
        final index = mapY * sourceMap.size.width + mapX;
        if (collisionAt(index) == value) continue;
        final source = sourceMap.layers[_layerIndex] as CollisionLayer;
        final sourceValue =
            index >= 0 &&
            index < source.collisions.length &&
            source.collisions[index];
        if (sourceValue == value) {
          _collisionOverrides.remove(index);
        } else {
          _collisionOverrides[index] = value;
        }
        changed = true;
      }
    }
    return changed;
  }

  TileLayer _materializeTileLayer() {
    _fullLayerCopyCount += 1;
    final source = sourceMap.layers[_layerIndex] as TileLayer;
    final expectedLength = sourceMap.size.width * sourceMap.size.height;
    final cells = List<int>.filled(expectedLength, 0, growable: false);
    final copyLimit = source.cells.length < expectedLength
        ? source.cells.length
        : expectedLength;
    for (var i = 0; i < copyLimit; i++) {
      cells[i] = source.cells[i];
    }
    final palette = <TileLayerPaletteEntry>[
      ...source.palette,
      ..._tilePaletteAdditions,
    ];
    final paletteCells = <TileLayerPaletteEntry, int>{
      for (var i = 0; i < palette.length; i++) palette[i]: i + 1,
    };
    for (final entry in _tileOverrides.entries) {
      final tile = entry.value;
      cells[entry.key] = tile == null
          ? 0
          : paletteCells.putIfAbsent(tile, () {
              palette.add(tile);
              return palette.length;
            });
    }
    return source.copyWith(palette: palette, cells: cells);
  }

  CollisionLayer _materializeCollisionLayer() {
    _fullLayerCopyCount += 1;
    final source = sourceMap.layers[_layerIndex] as CollisionLayer;
    final expectedLength = sourceMap.size.width * sourceMap.size.height;
    final collisions = List<bool>.filled(
      expectedLength,
      false,
      growable: false,
    );
    final copyLimit = source.collisions.length < expectedLength
        ? source.collisions.length
        : expectedLength;
    for (var i = 0; i < copyLimit; i++) {
      collisions[i] = source.collisions[i];
    }
    for (final entry in _collisionOverrides.entries) {
      collisions[entry.key] = entry.value;
    }
    return source.copyWith(collisions: collisions);
  }

  SmartTileLayer _materializeSmartTileLayer() {
    _fullLayerCopyCount += 1;
    final source = sourceMap.layers[_layerIndex] as SmartTileLayer;
    final palette = List<String>.of(source.materialPalette);
    final paletteIndices = <String, int>{
      for (var index = 0; index < palette.length; index++)
        palette[index]: index,
    };
    int materialIndex(String? materialId) {
      if (materialId == null) return 0;
      final existing = paletteIndices[materialId];
      if (existing != null) return existing;
      palette.add(materialId);
      final added = palette.length - 1;
      paletteIndices[materialId] = added;
      return added;
    }

    List<int> materialize(List<int> values, Map<int, String?> overrides) {
      final next = List<int>.of(values);
      for (final entry in overrides.entries) {
        next[entry.key] = materialIndex(entry.value);
      }
      return next;
    }

    final semanticCells = materialize(
      smartTileSemanticCells(source),
      _smartTileCellOverrides,
    );
    final field = switch (source.field) {
      SmartTileCellField() => SmartTileField.cell(semanticCells: semanticCells),
      SmartTileEdgeField(:final horizontalEdges, :final verticalEdges) =>
        SmartTileField.edge(
          semanticCells: semanticCells,
          horizontalEdges: materialize(
            horizontalEdges,
            _smartTileHorizontalEdgeOverrides,
          ),
          verticalEdges: materialize(
            verticalEdges,
            _smartTileVerticalEdgeOverrides,
          ),
        ),
      SmartTileCornerField(:final corners) => SmartTileField.corner(
        semanticCells: semanticCells,
        corners: materialize(corners, _smartTileCornerOverrides),
      ),
      SmartTileMixedField(
        :final horizontalEdges,
        :final verticalEdges,
        :final corners,
      ) =>
        SmartTileField.mixed(
          semanticCells: semanticCells,
          horizontalEdges: materialize(
            horizontalEdges,
            _smartTileHorizontalEdgeOverrides,
          ),
          verticalEdges: materialize(
            verticalEdges,
            _smartTileVerticalEdgeOverrides,
          ),
          corners: materialize(corners, _smartTileCornerOverrides),
        ),
    };
    return source.copyWith(materialPalette: palette, field: field);
  }

  bool _setSmartTileOverride(
    Map<int, String?> overrides,
    int index,
    String? value,
    String? sourceValue,
  ) {
    final current = overrides.containsKey(index)
        ? overrides[index]
        : sourceValue;
    if (current == value) return false;
    if (sourceValue == value) {
      overrides.remove(index);
    } else {
      overrides[index] = value;
    }
    return true;
  }

  void _removeMatchingSmartTileOverrides(
    Map<int, String?> overrides,
    String? Function(int index) sourceValueAt,
  ) {
    for (final entry in overrides.entries.toList(growable: false)) {
      if (sourceValueAt(entry.key) == entry.value) {
        overrides.remove(entry.key);
      }
    }
  }

  String? _sourceSmartTileMaterialAt(int x, int y) => smartTileMaterialIdAt(
    sourceMap.layers[_layerIndex] as SmartTileLayer,
    mapSize: sourceMap.size,
    x: x,
    y: y,
  );

  String? _sourceHorizontalMaterialAtIndex(int index) {
    final source = sourceMap.layers[_layerIndex] as SmartTileLayer;
    return _materialIdForIndex(source, smartTileHorizontalEdges(source)[index]);
  }

  String? _sourceVerticalMaterialAtIndex(int index) {
    final source = sourceMap.layers[_layerIndex] as SmartTileLayer;
    return _materialIdForIndex(source, smartTileVerticalEdges(source)[index]);
  }

  String? _sourceCornerMaterialAtIndex(int index) {
    final source = sourceMap.layers[_layerIndex] as SmartTileLayer;
    return _materialIdForIndex(source, smartTileCorners(source)[index]);
  }

  String? _smartTileHorizontalEdgeMaterialIdAt(int x, int y) {
    final width = sourceMap.size.width;
    _validateSmartTileCoordinate(x, y, width, sourceMap.size.height + 1);
    final index = y * width + x;
    return _smartTileHorizontalEdgeOverrides.containsKey(index)
        ? _smartTileHorizontalEdgeOverrides[index]
        : _sourceHorizontalMaterialAtIndex(index);
  }

  String? _smartTileVerticalEdgeMaterialIdAt(int x, int y) {
    final width = sourceMap.size.width + 1;
    _validateSmartTileCoordinate(x, y, width, sourceMap.size.height);
    final index = y * width + x;
    return _smartTileVerticalEdgeOverrides.containsKey(index)
        ? _smartTileVerticalEdgeOverrides[index]
        : _sourceVerticalMaterialAtIndex(index);
  }

  String? _smartTileCornerMaterialIdAt(int x, int y) {
    final width = sourceMap.size.width + 1;
    _validateSmartTileCoordinate(x, y, width, sourceMap.size.height + 1);
    final index = y * width + x;
    return _smartTileCornerOverrides.containsKey(index)
        ? _smartTileCornerOverrides[index]
        : _sourceCornerMaterialAtIndex(index);
  }

  String? _materialIdForIndex(SmartTileLayer layer, int index) =>
      index <= 0 || index >= layer.materialPalette.length
      ? null
      : layer.materialPalette[index];

  void _validateSmartTileCoordinate(int x, int y, int width, int height) {
    if (x < 0 || y < 0 || x >= width || y >= height) {
      throw RangeError(
        'Smart Tile coordinate ($x, $y) is outside $width x $height',
      );
    }
  }

  bool _isInBounds(int x, int y) =>
      x >= 0 && y >= 0 && x < sourceMap.size.width && y < sourceMap.size.height;

  void _publish() {
    _revision += 1;
    _onChanged?.call();
  }
}
