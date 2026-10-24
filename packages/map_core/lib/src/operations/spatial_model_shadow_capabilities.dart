import '../models/map_data.dart';
import '../models/project_manifest.dart';
import 'spatial_smart_tile_models.dart';

abstract final class SpatialModelShadowCapabilities {
  static const capabilityId = 'map3d.shadows@1';

  static bool requiresCapability(
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
        final model = models[instance.modelId];
        if (model != null && instance.effectiveCastsShadows(model)) return true;
      }
    }
    return false;
  }
}
