part of 'map_atmosphere_editing.dart';

extension MapAtmosphereChoices on MapAtmosphereEditing {
  Map<String, (String, Model3dVector3)> get haloChoices {
    final choices = <String, (String, Model3dVector3)>{};
    final models = {
      for (final model in project?.models3d ?? <ProjectModel3dEntry>[])
        model.id: model,
    };
    for (final instance
        in map.spatialScene?.instances ?? <SpatialModelInstance>[]) {
      final model = models[instance.modelId];
      if (model == null) continue;
      final bounds = model.inspection.bounds;
      choices[instance.id] = (
        model.name,
        model.light?.localPosition ??
            Model3dVector3(
              x: (bounds.min.x + bounds.max.x) / 2,
              y: (bounds.min.y + bounds.max.y) / 2,
              z: bounds.max.z + .04,
            ),
      );
    }
    return choices;
  }

  Map<String, (String, SpatialAtmosphereMaterialTarget)> materials({
    required bool ground,
  }) {
    final choices = <String, (String, SpatialAtmosphereMaterialTarget)>{};
    final project = this.project;
    if (project == null) return choices;
    if (ground) {
      final ids = {
        for (final layer in map.layers.whereType<TileLayer>())
          for (final entry in layer.palette) entry.tilesetId,
      };
      for (final tile in project.tilesets.where(
        (tile) => ids.contains(tile.id),
      )) {
        choices['ground:${tile.id}'] = (
          'Sol · ${tile.name}',
          SpatialAtmosphereMaterialTarget.groundTileset(tile.id),
        );
      }
    }
    for (final instance
        in map.spatialScene?.instances ?? <SpatialModelInstance>[]) {
      final model = project.models3d
          .where((model) => model.id == instance.modelId)
          .firstOrNull;
      if (model == null) continue;
      for (final material in model.inspection.materials) {
        choices['${instance.id}:${material.name}'] = (
          '${model.name} · ${material.name} · ${instance.id}',
          SpatialAtmosphereMaterialTarget(
            instanceId: instance.id,
            materialName: material.name,
          ),
        );
      }
    }
    return choices;
  }

  ProjectModel3dEntry? modelOf(String instanceId) {
    final instance = map.spatialScene?.instances
        .where((item) => item.id == instanceId)
        .firstOrNull;
    if (instance == null) return null;
    return project?.models3d
        .where((model) => model.id == instance.modelId)
        .firstOrNull;
  }

  List<SpatialAtmosphereMaterialTarget> instanceMaterials(String instanceId) =>
      [
        for (final material
            in modelOf(instanceId)?.inspection.materials ??
                const <Model3dMaterial>[])
          SpatialAtmosphereMaterialTarget(
            instanceId: instanceId,
            materialName: material.name,
          ),
      ];

  List<(String, SpatialAtmosphereMaterialTarget)> groundMaterials() {
    final ids = {
      for (final layer in map.layers.whereType<TileLayer>())
        for (final entry in layer.palette) entry.tilesetId,
    };
    return [
      for (final tile in project?.tilesets ?? const <ProjectTilesetEntry>[])
        if (ids.contains(tile.id))
          (tile.name, SpatialAtmosphereMaterialTarget.groundTileset(tile.id)),
    ];
  }
}
