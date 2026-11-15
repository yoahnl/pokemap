part of 'spatial_model_editing_commands.dart';

extension SpatialModelCopy on SpatialModelEditingCommands {
  double elevationOf(SpatialModelInstance instance) =>
      instance.position.y -
      document.current.spatialScene!.worldHeightAt(
        instance.position.x,
        instance.position.z,
        excludingRampSurface: instance.id,
      );

  SpatialModelInstance insertCopy(
    SpatialModelInstance source, {
    required double x,
    required double z,
    required double elevation,
  }) {
    final model = project.models3d
        .where((item) => item.id == source.modelId)
        .firstOrNull;
    if (model == null) throw StateError('Cette ressource n’existe plus.');
    final anchor = _position(x, z);
    final copy = SpatialModelInstance(
      id: _id(),
      modelId: source.modelId,
      position: Model3dVector3(
        x: anchor.x,
        y: anchor.y + elevation,
        z: anchor.z,
      ),
      rotationDegrees: source.rotationDegrees,
      scale: source.scale,
      animationIndex: source.animationIndex,
      animationLoop: source.animationLoop,
      animationSpeed: source.animationSpeed,
      blocksMovement: source.blocksMovement,
      castsShadows: source.castsShadows,
      clip: source.clip,
      visibilityCondition: source.visibilityCondition,
    );
    document.commit(
      SpatialModelEditingCommands.operations.upsertInstance(
        document.current,
        copy,
        model: model,
      ),
    );
    return copy;
  }
}
