import 'package:map_core/map_core.dart';

enum MapCellStrokeLayerKind { tile, collision }

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

  MapCellStrokeBuffer._({
    required this.sourceMap,
    required this.layerId,
    required this.kind,
    required void Function()? onChanged,
  }) : _layerIndex = sourceMap.layers.indexWhere(
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
  }

  final MapData sourceMap;
  final String layerId;
  final MapCellStrokeLayerKind kind;
  final int _layerIndex;
  final void Function()? _onChanged;
  final Map<int, TileLayerPaletteEntry?> _tileOverrides =
      <int, TileLayerPaletteEntry?>{};
  final List<TileLayerPaletteEntry> _tilePaletteAdditions =
      <TileLayerPaletteEntry>[];
  final Map<int, bool> _collisionOverrides = <int, bool>{};
  GridPos? _lastOrigin;
  int _revision = 0;
  int _fullLayerCopyCount = 0;
  int _mapMaterializationCount = 0;
  int _validationCount = 0;

  int get revision => _revision;
  int get touchedCellCount => switch (kind) {
    MapCellStrokeLayerKind.tile => _tileOverrides.length,
    MapCellStrokeLayerKind.collision => _collisionOverrides.length,
  };
  bool get hasChanges =>
      touchedCellCount > 0 || _tilePaletteAdditions.isNotEmpty;
  int get fullLayerCopyCount => _fullLayerCopyCount;
  int get mapMaterializationCount => _mapMaterializationCount;
  int get validationCount => _validationCount;

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

  bool _isInBounds(int x, int y) =>
      x >= 0 && y >= 0 && x < sourceMap.size.width && y < sourceMap.size.height;

  void _publish() {
    _revision += 1;
    _onChanged?.call();
  }
}
