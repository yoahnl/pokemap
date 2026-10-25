import 'package:map_core/map_core.dart';

import '../presentation/flame/smart_tile_animation_activation_controller.dart';

final class SpatialSmartTileAnimationController {
  SpatialSmartTileAnimationController({
    required MapData map,
    required ProjectManifest project,
  }) : _map = map,
       _catalog = project.smartTileCatalog,
       _rasterAnimations = SmartTileAnimationActivationController(
         map: map,
         catalog: project.smartTileCatalog,
       ) {
    final layers = map.layers.whereType<SmartTileLayer>().where(
      (layer) =>
          layer.isVisible &&
          layer.opacity > 0 &&
          layer.animationActivation == SmartTileAnimationActivation.onEnter,
    );
    if (layers.isEmpty) return;
    final projection = resolveSpatialSmartTileModelProjection(
      map: map.copyWith(layers: layers.toList()),
      catalog: project.smartTileCatalog,
      sourceCellWidth: project.settings.tileWidth,
      sourceCellHeight: project.settings.tileHeight,
    );
    final models = {for (final model in project.models3d) model.id: model};
    for (final instance in projection.instances) {
      final animation = models[instance.modelId]?.inspection.animations
          .where((animation) => animation.index == instance.animationIndex)
          .firstOrNull;
      if (animation == null) continue;
      final origin = projection.cellOrigins[instance.id]!;
      _instancesByCell.putIfAbsent(origin.cell, () => []).add(instance.id);
      _durations[instance.id] = animation.durationSeconds;
      _restPoses[instance.id] = SpatialModelRuntimeState(
        modelId: instance.modelId,
        animationIndex: animation.index,
        normalizedTime: 0,
        blocksMovement: false,
      );
    }
  }

  final MapData _map;
  final ProjectSmartTileCatalog _catalog;
  final _actorCells = <String, GridPos?>{};
  final _actorAnimations = <String, SmartTileAnimationActivationController>{};
  final _instancesByCell = <GridPos, List<String>>{};
  final SmartTileAnimationActivationController _rasterAnimations;
  final _durations = <String, double>{};
  final _restPoses = <String, SpatialModelRuntimeState>{};
  final _startedAt = <String, double>{};
  double _elapsed = 0;

  void update(double dt) {
    if (!dt.isFinite || dt <= 0) return;
    _rasterAnimations.update(dt);
    for (final controller in _actorAnimations.values) {
      controller.update(dt);
    }
    _elapsed += dt;
    _startedAt.removeWhere(
      (id, startedAt) => _elapsed - startedAt >= _durations[id]!,
    );
  }

  void onPlayerEnteredCell(GridPos cell) => onActorEnteredCell(cell);

  void onActorEnteredCell(GridPos cell) {
    _rasterAnimations.onPlayerEnteredCell(cell);
    for (final id in _instancesByCell[cell] ?? const <String>[]) {
      _startedAt[id] = _elapsed;
    }
  }

  void synchronizeActorOccupancy(
    Map<String, GridPos?> cells, {
    Set<String> reactingActors = const {},
  }) {
    _actorCells.removeWhere((id, _) => !cells.containsKey(id));
    _actorAnimations.removeWhere((id, _) => !cells.containsKey(id));
    for (final entry in cells.entries) {
      final cell = entry.value;
      final controller = _actorAnimations[entry.key];
      if (controller == null) {
        final created = SmartTileAnimationActivationController(
          map: _map,
          catalog: _catalog,
        );
        created.resetPlayerOccupancy(cell);
        _actorAnimations[entry.key] = created;
      } else if (_actorCells[entry.key] != cell) {
        controller.resetPlayerOccupancy(null);
        if (cell != null) {
          controller.onPlayerEnteredCell(cell);
          controller.onPlayerStepCompleted();
          if (reactingActors.contains(entry.key)) {
            onActorEnteredCell(cell);
          }
        }
      }
      _actorCells[entry.key] = cell;
    }
  }

  ({bool active, int elapsedMs}) actorOcclusionStateForCell({
    required String layerId,
    required int cellX,
    required int cellY,
    required int globalElapsedMs,
  }) {
    final layer = _map.layers
        .whereType<SmartTileLayer>()
        .where((l) => l.id == layerId)
        .firstOrNull;
    if (layer?.animationActivation == SmartTileAnimationActivation.always) {
      return (active: true, elapsedMs: globalElapsedMs);
    }
    int? elapsed;
    for (final entry in _actorCells.entries) {
      if (entry.value != GridPos(x: cellX, y: cellY)) continue;
      final time = _actorAnimations[entry.key]!.elapsedMsForCell(
        layerId: layerId,
        cellX: cellX,
        cellY: cellY,
        globalElapsedMs: globalElapsedMs,
        channel: SmartTileRenderChannel.actorOcclusion,
      );
      if (elapsed == null || time < elapsed) {
        elapsed = time;
      }
    }
    return (active: elapsed != null, elapsedMs: elapsed ?? 0);
  }

  int rasterElapsedMsForCell({
    required String layerId,
    required int cellX,
    required int cellY,
    required int globalElapsedMs,
  }) => _rasterAnimations.elapsedMsForCell(
    layerId: layerId,
    cellX: cellX,
    cellY: cellY,
    globalElapsedMs: globalElapsedMs,
  );

  SpatialModelRuntimeState? stateFor(String instanceId) {
    final pose = _restPoses[instanceId];
    final startedAt = _startedAt[instanceId];
    if (pose == null || startedAt == null) return pose;
    return pose.copyWith(
      normalizedTime: ((_elapsed - startedAt) / _durations[instanceId]!).clamp(
        0,
        1,
      ),
    );
  }
}
