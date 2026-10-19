import 'package:map_core/map_core.dart';

import '../presentation/flame/smart_tile_animation_activation_controller.dart';

final class SpatialSmartTileAnimationController {
  SpatialSmartTileAnimationController({
    required MapData map,
    required ProjectManifest project,
  }) : _rasterAnimations = SmartTileAnimationActivationController(
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

  final _instancesByCell = <GridPos, List<String>>{};
  final SmartTileAnimationActivationController _rasterAnimations;
  final _durations = <String, double>{};
  final _restPoses = <String, SpatialModelRuntimeState>{};
  final _startedAt = <String, double>{};
  double _elapsed = 0;

  void update(double dt) {
    if (!dt.isFinite || dt <= 0) return;
    _rasterAnimations.update(dt);
    _elapsed += dt;
    _startedAt.removeWhere(
      (id, startedAt) => _elapsed - startedAt >= _durations[id]!,
    );
  }

  void onPlayerEnteredCell(GridPos cell) {
    _rasterAnimations.onPlayerEnteredCell(cell);
    for (final id in _instancesByCell[cell] ?? const <String>[]) {
      _startedAt[id] = _elapsed;
    }
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
