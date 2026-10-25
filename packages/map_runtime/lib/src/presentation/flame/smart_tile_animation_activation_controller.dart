import 'package:map_core/map_core.dart';

final class SmartTileAnimationActivationController {
  SmartTileAnimationActivationController({
    required MapData map,
    required ProjectSmartTileCatalog catalog,
  }) : _mapSize = map.size,
       _layerById = <String, SmartTileLayer>{
         for (final layer in map.layers.whereType<SmartTileLayer>())
           layer.id: layer,
       },
       _cycleDurationMsByLayerId = _cycleDurationsByLayer(
         map: map,
         catalog: catalog,
       ),
       _occlusionDurationMsByLayerId = _cycleDurationsByLayer(
         map: map,
         catalog: catalog,
         actorOcclusionOnly: true,
       ),
       _tallGrassMaterialIds = {
         for (final material in catalog.materials)
           if (material.pathSurfaceKind == PathSurfaceKind.tallGrass)
             material.id,
       },
       _patternCellIndicesByLayerId = _patternCellIndicesByLayer(map);

  final GridSize _mapSize;
  final Map<String, SmartTileLayer> _layerById;
  final Map<String, int> _cycleDurationMsByLayerId;
  final Map<String, int> _occlusionDurationMsByLayerId;
  final Set<String> _tallGrassMaterialIds;
  final Map<String, Set<int>> _patternCellIndicesByLayerId;
  final Map<(String, int), double> _startedAtMsByCell =
      <(String, int), double>{};
  final Map<(String, int), double> _occlusionStartedAtMsByCell = {};
  GridPos? _currentPlayerCell;
  GridPos? _previousPlayerCell;
  double _elapsedMs = 0;

  void update(double dt) {
    if (!dt.isFinite || dt <= 0) return;
    _elapsedMs += dt * 1000;
    _startedAtMsByCell.removeWhere((key, startedAtMs) {
      final durationMs = _cycleDurationMsByLayerId[key.$1] ?? 0;
      return durationMs <= 0 || _elapsedMs - startedAtMs >= durationMs;
    });
    _occlusionStartedAtMsByCell.removeWhere((key, startedAtMs) {
      final durationMs = _occlusionDurationMsByLayerId[key.$1] ?? 0;
      final cell = GridPos(
        x: key.$2 % _mapSize.width,
        y: key.$2 ~/ _mapSize.width,
      );
      return _elapsedMs - startedAtMs >= durationMs &&
          cell != _currentPlayerCell &&
          cell != _previousPlayerCell;
    });
  }

  void resetPlayerOccupancy(GridPos? cell) {
    _occlusionStartedAtMsByCell.clear();
    _previousPlayerCell = null;
    _currentPlayerCell = cell;
    if (cell == null) return;
    for (final layer in _layerById.values) {
      if (!_holdsOcclusionAtCell(layer, cell)) continue;
      _occlusionStartedAtMsByCell[(
            layer.id,
            cell.y * _mapSize.width + cell.x,
          )] =
          _elapsedMs - _occlusionDurationMsByLayerId[layer.id]!;
    }
  }

  void onPlayerStepCompleted() {
    _previousPlayerCell = null;
  }

  void onPlayerEnteredCell(GridPos cell, {GridPos? previousCell}) {
    if (cell.x < 0 ||
        cell.y < 0 ||
        cell.x >= _mapSize.width ||
        cell.y >= _mapSize.height) {
      return;
    }
    _previousPlayerCell = previousCell ?? _currentPlayerCell;
    _currentPlayerCell = cell;
    for (final layer in _layerById.values) {
      if (layer.animationActivation != SmartTileAnimationActivation.onEnter ||
          (_cycleDurationMsByLayerId[layer.id] ?? 0) <= 0 ||
          !_cellHasAuthoredValue(layer, cell)) {
        continue;
      }
      _startedAtMsByCell[(layer.id, cell.y * _mapSize.width + cell.x)] =
          _elapsedMs;
      if (_holdsOcclusionAtCell(layer, cell)) {
        _occlusionStartedAtMsByCell[(
              layer.id,
              cell.y * _mapSize.width + cell.x,
            )] =
            _elapsedMs;
      }
    }
  }

  bool isAnimationActiveForCell({
    required String layerId,
    required int cellX,
    required int cellY,
    SmartTileRenderChannel channel = SmartTileRenderChannel.ground,
  }) {
    final layer = _layerById[layerId];
    if (layer == null ||
        layer.animationActivation == SmartTileAnimationActivation.always) {
      return true;
    }
    if (cellX < 0 ||
        cellY < 0 ||
        cellX >= _mapSize.width ||
        cellY >= _mapSize.height) {
      return false;
    }
    if (channel == SmartTileRenderChannel.actorOcclusion &&
        _holdsOcclusionAtCell(layer, GridPos(x: cellX, y: cellY))) {
      return _occlusionStartedAtMsByCell.containsKey((
        layerId,
        cellY * _mapSize.width + cellX,
      ));
    }
    return _startedAtMsByCell.containsKey((
      layerId,
      cellY * _mapSize.width + cellX,
    ));
  }

  int elapsedMsForCell({
    required String layerId,
    required int cellX,
    required int cellY,
    required int globalElapsedMs,
    SmartTileRenderChannel channel = SmartTileRenderChannel.ground,
  }) {
    final layer = _layerById[layerId];
    if (layer == null ||
        layer.animationActivation == SmartTileAnimationActivation.always) {
      return globalElapsedMs;
    }
    if (cellX < 0 ||
        cellY < 0 ||
        cellX >= _mapSize.width ||
        cellY >= _mapSize.height) {
      return 0;
    }
    if (channel == SmartTileRenderChannel.actorOcclusion &&
        _holdsOcclusionAtCell(layer, GridPos(x: cellX, y: cellY))) {
      final started =
          _occlusionStartedAtMsByCell[(
            layerId,
            cellY * _mapSize.width + cellX,
          )];
      if (started == null) return 0;
      final elapsed = (_elapsedMs - started).floor();
      return elapsed < 0 ? 0 : elapsed;
    }
    final startedAtMs =
        _startedAtMsByCell[(layerId, cellY * _mapSize.width + cellX)];
    if (startedAtMs == null) return 0;
    final durationMs = _cycleDurationMsByLayerId[layerId] ?? 0;
    final elapsedMs = (_elapsedMs - startedAtMs).floor();
    if (durationMs <= 0 || elapsedMs >= durationMs) return 0;
    return elapsedMs < 0 ? 0 : elapsedMs;
  }

  bool _holdsOcclusionAtCell(SmartTileLayer layer, GridPos cell) =>
      layer.animationActivation == SmartTileAnimationActivation.onEnter &&
      layer.usage == SmartTileUsage.path &&
      (_occlusionDurationMsByLayerId[layer.id] ?? 0) > 0 &&
      cell.x >= 0 &&
      cell.y >= 0 &&
      cell.x < _mapSize.width &&
      cell.y < _mapSize.height &&
      _tallGrassMaterialIds.contains(
        smartTileMaterialIdAt(layer, mapSize: _mapSize, x: cell.x, y: cell.y),
      );

  bool _cellHasAuthoredValue(SmartTileLayer layer, GridPos cell) {
    final index = cell.y * _mapSize.width + cell.x;
    return smartTileCellHasAuthoredValue(
          layer,
          mapSize: _mapSize,
          x: cell.x,
          y: cell.y,
        ) ||
        (_patternCellIndicesByLayerId[layer.id]?.contains(index) ?? false);
  }
}

Map<String, Set<int>> _patternCellIndicesByLayer(MapData map) =>
    <String, Set<int>>{
      for (final layer in map.layers.whereType<SmartTileLayer>())
        if (layer.patternStrokes.isNotEmpty)
          layer.id: <int>{
            for (final stroke in layer.patternStrokes)
              for (final cell in stroke.cells)
                if (cell.x >= 0 &&
                    cell.y >= 0 &&
                    cell.x < map.size.width &&
                    cell.y < map.size.height)
                  cell.y * map.size.width + cell.x,
          },
    };

Map<String, int> _cycleDurationsByLayer({
  required MapData map,
  required ProjectSmartTileCatalog catalog,
  bool actorOcclusionOnly = false,
}) {
  final presetById = <String, ProjectSmartTilePreset>{
    for (final preset in catalog.presets) preset.id: preset,
  };
  final animationById = <String, ProjectSmartTileAnimation>{
    for (final animation in catalog.animations) animation.id: animation,
  };
  return <String, int>{
    for (final layer in map.layers.whereType<SmartTileLayer>())
      if (layer.animationActivation == SmartTileAnimationActivation.onEnter)
        layer.id: _maximumAnimationDuration(
          [
            for (final rule
                in presetById[layer.presetId]?.rules ?? const <SmartTileRule>[])
              for (final candidate in rule.candidates) ...candidate.parts,
            for (final pattern in catalog.patterns)
              if (layer.patternStrokes.any(
                (stroke) => stroke.patternId == pattern.id,
              ))
                for (final cell in pattern.cells) ...cell.parts,
          ],
          animationById,
          actorOcclusionOnly: actorOcclusionOnly,
        ),
  };
}

int _maximumAnimationDuration(
  Iterable<SmartTileVisualPart> parts,
  Map<String, ProjectSmartTileAnimation> animationById, {
  bool actorOcclusionOnly = false,
}) {
  var maximum = 0;
  var allOnce = true;
  for (final part in parts) {
    if (actorOcclusionOnly &&
        part.channel != SmartTileRenderChannel.actorOcclusion) {
      continue;
    }
    part.source.map(
      model3d: (_) {},
      frame: (_) {},
      animation: (source) {
        final animation = animationById[source.animationId];
        if (animation == null) return;
        if (actorOcclusionOnly &&
            animation.loop != SmartTileAnimationLoop.once) {
          allOnce = false;
          return;
        }
        final duration = _animationCycleDuration(animation);
        if (duration > maximum) maximum = duration;
      },
    );
  }
  return allOnce ? maximum : 0;
}

int _animationCycleDuration(ProjectSmartTileAnimation animation) {
  var duration = animation.frames.fold<int>(
    0,
    (sum, frame) => sum + frame.durationMs,
  );
  if (animation.loop == SmartTileAnimationLoop.pingPong &&
      animation.frames.length >= 3) {
    duration += animation.frames
        .sublist(1, animation.frames.length - 1)
        .fold<int>(0, (sum, frame) => sum + frame.durationMs);
  }
  return duration;
}
