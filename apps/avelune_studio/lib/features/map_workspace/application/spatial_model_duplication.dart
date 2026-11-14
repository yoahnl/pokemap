part of 'spatial_model_editing_commands.dart';

extension SpatialModelDuplication on SpatialModelEditingCommands {
  void duplicate(String id) {
    _requireIndependent(id);
    final item = selected(id);
    if (item == null) throw StateError('Ce décor n’existe plus.');
    final next = SpatialModelInstance(
      id: _id(),
      modelId: item.modelId,
      position: item.position,
      rotationDegrees: item.rotationDegrees,
      scale: item.scale,
      animationIndex: item.animationIndex,
      animationLoop: item.animationLoop,
      animationSpeed: item.animationSpeed,
      blocksMovement: item.blocksMovement,
      castsShadows: item.castsShadows,
      clip: item.clip,
      visibilityCondition: item.visibilityCondition,
    );
    final source = owner(id);
    final map = source == null
        ? document.current
        : SpatialModelEditingCommands.environments.addGeneratedPlacement(
            project,
            document.current,
            layerId: source.layerId,
            areaId: source.areaId,
            placementId: next.id,
            modelId: next.modelId,
            pos: GridPos(
              x: next.position.x.floor(),
              y: next.position.z.floor(),
            ),
          );
    final model = project.models3d
        .where((model) => model.id == item.modelId)
        .firstOrNull;
    if (model?.rampProfile != null) {
      final scene = map.spatialScene!;
      final elevated =
          item.position.y -
          scene.worldHeightAt(
            item.position.x,
            item.position.z,
            excludingRampSurface: item.id,
          );
      for (var distance = 1; distance < scene.width + scene.depth; distance++) {
        for (final offset in [
          (distance, 0),
          (-distance, 0),
          (0, distance),
          (0, -distance),
        ]) {
          final x = next.position.x + offset.$1;
          final z = next.position.z + offset.$2;
          if (x < 0 || z < 0 || x >= scene.width || z >= scene.depth) continue;
          final candidate = next.copyWith(
            position: Model3dVector3(
              x: x,
              y:
                  scene.worldHeightAt(x, z, excludingRampSurface: item.id) +
                  elevated,
              z: z,
            ),
          );
          try {
            final result = SpatialModelEditingCommands.operations
                .upsertInstance(map, candidate, model: model);
            document.commit(result);
            document.selectedId = next.id;
            return;
          } on FormatException {
            continue;
          }
        }
      }
      throw StateError(
        'Aucune place libre pour dupliquer cet escalier et sa pente.',
      );
    }
    if (map.spatialScene!.navigation.ramps.any(
      (ramp) => ramp.surfaceInstanceId == item.id,
    )) {
      throw StateError(
        'Définissez le comportement Escalier dans Ressources avant de dupliquer cet ancien assemblage manuel.',
      );
    }
    document.commit(
      SpatialModelEditingCommands.operations.upsertInstance(
        map,
        next,
        model: model,
      ),
    );
    document.selectedId = next.id;
  }
}
