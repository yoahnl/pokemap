import 'package:map_core/map_core.dart';

final class EnvironmentMaskPaintTarget {
  const EnvironmentMaskPaintTarget({
    required this.environmentLayerId,
    required this.areaId,
    required this.area,
    required this.activeLayerId,
    this.tileLayerId,
  });

  final String environmentLayerId;
  final String areaId;
  final EnvironmentArea area;
  final String activeLayerId;
  final String? tileLayerId;
}

EnvironmentMaskPaintTarget? resolveEnvironmentMaskPaintTarget({
  required MapData map,
  required String? activeLayerId,
  required String? selectedAreaId,
}) {
  final activeId = activeLayerId?.trim();
  final areaId = selectedAreaId?.trim();
  if (activeId == null ||
      activeId.isEmpty ||
      areaId == null ||
      areaId.isEmpty) {
    return null;
  }

  final activeLayer = _findLayerById(map, activeId);
  if (activeLayer is EnvironmentLayer) {
    final area = activeLayer.content.areaById(areaId);
    if (area == null) {
      return null;
    }
    return EnvironmentMaskPaintTarget(
      environmentLayerId: activeLayer.id,
      areaId: area.id,
      area: area,
      activeLayerId: activeId,
      tileLayerId: activeLayer.content.targetTileLayerId,
    );
  }

  if (activeLayer is TileLayer) {
    for (final layer in map.layers) {
      if (layer is! EnvironmentLayer ||
          layer.content.targetTileLayerId?.trim() != activeLayer.id) {
        continue;
      }
      final area = layer.content.areaById(areaId);
      if (area == null) {
        continue;
      }
      return EnvironmentMaskPaintTarget(
        environmentLayerId: layer.id,
        areaId: area.id,
        area: area,
        activeLayerId: activeId,
        tileLayerId: activeLayer.id,
      );
    }
  }

  return null;
}

MapLayer? _findLayerById(MapData map, String layerId) {
  for (final layer in map.layers) {
    if (layer.id == layerId) {
      return layer;
    }
  }
  return null;
}
