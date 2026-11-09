import '../models/map_data.dart';
import '../models/narrative_map_view.dart';

abstract final class OverworldItemCapabilities {
  static const contextualUseCapabilityId = 'gameplay.contextual-item-use@1';
  static const spatialEscapeRopeCapabilityId = 'map3d.escape-rope@1';

  static bool requiresContextualUse(Iterable<NarrativeMapView> maps) =>
      maps.any((map) => map.contextualItemUses.isNotEmpty);

  static bool requiresSpatialEscapeRope(Iterable<MapData> maps) => maps.any(
    (map) =>
        map.spatialScene != null &&
        map.mapMetadata.allowEscapeRope &&
        map.mapMetadata.escapeRopeDungeonId != null,
  );
}
