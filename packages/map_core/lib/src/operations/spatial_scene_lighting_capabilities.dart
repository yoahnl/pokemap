import '../models/map_data.dart';
import '../models/project_manifest.dart';
import 'spatial_model_shadow_capabilities.dart';
import 'spatial_smart_tile_models.dart';

abstract final class SpatialSceneLightingCapabilities {
  static const dayNightCapabilityId = 'map3d.day-night@1';
  static const pointLightCapabilityId = 'map3d.point-light@1';
  static const pointLightShadowsCapabilityId = 'map3d.point-light-shadows@1';

  static bool requiresPointLightShadows(
    ProjectManifest project, {
    Iterable<MapData> maps = const [],
  }) => requiresPointLights(project, maps: maps) &&
      SpatialModelShadowCapabilities.requiresCapability(project, maps: maps);

  static bool requiresDayNight(
    ProjectManifest project, {
    Iterable<MapData> maps = const [],
  }) => maps.any((map) => map.spatialScene?.dayNightCycle != null);

  static bool requiresPointLights(
    ProjectManifest project, {
    Iterable<MapData> maps = const [],
  }) {
    final models = {for (final model in project.models3d) model.id: model};
    for (final map in maps) {
      final scene = map.spatialScene;
      if (scene == null) continue;
      for (final instance in [
        ...scene.instances,
        ...resolveSpatialSmartTileInstances(
          map: map,
          catalog: project.smartTileCatalog,
          sourceCellWidth: project.settings.tileWidth,
          sourceCellHeight: project.settings.tileHeight,
        ),
      ]) {
        final light = models[instance.modelId]?.light;
        if (light != null && light.intensity > 0) return true;
      }
    }
    return false;
  }
}
