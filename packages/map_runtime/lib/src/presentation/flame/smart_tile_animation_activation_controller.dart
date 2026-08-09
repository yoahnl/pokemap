import 'package:map_core/map_core.dart';

final class SmartTileAnimationActivationController {
  SmartTileAnimationActivationController({
    required MapData map,
    required ProjectSmartTileCatalog catalog,
  })  : _mapSize = map.size,
        _layerById = <String, SmartTileLayer>{
          for (final layer in map.layers.whereType<SmartTileLayer>())
            layer.id: layer,
        },
        _cycleDurationMsByLayerId = _cycleDurationsByLayer(
          map: map,
          catalog: catalog,
        ),
        _patternCellIndicesByLayerId = _patternCellIndicesByLayer(map);

  final GridSize _mapSize;
  final Map<String, SmartTileLayer> _layerById;
  final Map<String, int> _cycleDurationMsByLayerId;
  final Map<String, Set<int>> _patternCellIndicesByLayerId;
  final Map<(String, int), double> _startedAtMsByCell =
      <(String, int), double>{};
  double _elapsedMs = 0;

  void update(double dt) {
    if (!dt.isFinite || dt <= 0) return;
    _elapsedMs += dt * 1000;
    _startedAtMsByCell.removeWhere((key, startedAtMs) {
      final durationMs = _cycleDurationMsByLayerId[key.$1] ?? 0;
      return durationMs <= 0 || _elapsedMs - startedAtMs >= durationMs;
    });
  }

  void onPlayerEnteredCell(GridPos cell) {
    if (cell.x < 0 ||
        cell.y < 0 ||
        cell.x >= _mapSize.width ||
        cell.y >= _mapSize.height) {
      return;
    }
    for (final layer in _layerById.values) {
      if (layer.animationActivation != SmartTileAnimationActivation.onEnter ||
          (_cycleDurationMsByLayerId[layer.id] ?? 0) <= 0 ||
          !_cellHasAuthoredValue(layer, cell)) {
        continue;
      }
      _startedAtMsByCell[(layer.id, cell.y * _mapSize.width + cell.x)] =
          _elapsedMs;
    }
  }

  int elapsedMsForCell({
    required String layerId,
    required int cellX,
    required int cellY,
    required int globalElapsedMs,
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
    final startedAtMs =
        _startedAtMsByCell[(layerId, cellY * _mapSize.width + cellX)];
    if (startedAtMs == null) return 0;
    final durationMs = _cycleDurationMsByLayerId[layerId] ?? 0;
    final elapsedMs = (_elapsedMs - startedAtMs).floor();
    if (durationMs <= 0 || elapsedMs >= durationMs) return 0;
    return elapsedMs < 0 ? 0 : elapsedMs;
  }

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
        layer.id: _maximumPresetAnimationDuration(
          presetById[layer.presetId],
          animationById,
        ),
  };
}

int _maximumPresetAnimationDuration(
  ProjectSmartTilePreset? preset,
  Map<String, ProjectSmartTileAnimation> animationById,
) {
  if (preset == null) return 0;
  var maximum = 0;
  for (final rule in preset.rules) {
    for (final candidate in rule.candidates) {
      for (final part in candidate.parts) {
        part.source.map(
          frame: (_) {},
          animation: (source) {
            final animation = animationById[source.animationId];
            if (animation == null) return;
            final duration = _animationCycleDuration(animation);
            if (duration > maximum) maximum = duration;
          },
        );
      }
    }
  }
  return maximum;
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
