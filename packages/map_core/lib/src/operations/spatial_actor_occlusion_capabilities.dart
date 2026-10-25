import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/map_spatial_scene.dart';
import '../models/project_manifest.dart';
import 'smart_tile_layer_visual_resolver.dart';

abstract final class SpatialActorOcclusionCapabilities {
  static const capabilityId = 'map3d.actor-occlusion@1';

  static bool requiresCapability(
    ProjectManifest project, {
    Iterable<MapData> maps = const [],
  }) {
    if (project.settings.dimension != ProjectDimension.threeD) return false;
    for (final map in maps) {
      if (map.spatialScene == null) continue;
      for (final layer in map.layers.whereType<SmartTileLayer>()) {
        if (!layer.isVisible || layer.opacity <= 0) continue;
        final plan = buildSmartTileLayerVisualPlan(
          map: map,
          layer: layer,
          catalog: project.smartTileCatalog,
          pass: SmartTileVisualPass.actorOcclusion,
        );
        if (plan.resolveBatch(elapsedMs: 0).visuals.isNotEmpty) return true;
      }
    }
    return false;
  }
}
