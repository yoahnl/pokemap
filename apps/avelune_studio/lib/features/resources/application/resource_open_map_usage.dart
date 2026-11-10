import 'package:map_core/map_core_domain.dart';

import 'resource_catalog.dart';

int resourceOpenMapUsage(ResourceItem item, Iterable<MapData> maps) {
  var count = 0;
  for (final map in maps) {
    if (item.model3d != null) {
      count +=
          map.spatialScene?.instances
              .where((instance) => instance.modelId == item.id)
              .length ??
          0;
    }
    if (item.element != null) {
      count += map.placedElements.where((e) => e.elementId == item.id).length;
    }
    if (item.terrain != null) {
      count += map.layers
          .whereType<SmartTileLayer>()
          .where((l) => l.presetId == item.id)
          .length;
    }
    if (item.tileset != null) {
      count += map.layers
          .whereType<TileLayer>()
          .where((l) => l.palette.any((t) => t.tilesetId == item.id))
          .length;
    }
    if (item.border != null) {
      count += map.layers
          .whereType<BorderLayer>()
          .expand((layer) => layer.content.features)
          .where((feature) => feature.blueprintId == item.id)
          .length;
    }
    if (item.environment != null) {
      count += map.layers
          .whereType<EnvironmentLayer>()
          .expand((layer) => layer.content.areas)
          .where((area) => area.presetId == item.id)
          .length;
    }
    if (item.character != null) {
      count += map.entities
          .where((entity) => entity.npc?.characterId == item.id)
          .length;
    }
  }
  return count;
}
