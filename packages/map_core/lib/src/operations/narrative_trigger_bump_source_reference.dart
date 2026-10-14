import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/map_spatial_scene.dart';
import '../models/project_manifest.dart';

bool isNarrativeTriggerBumpSourceAvailable({
  required ProjectManifest project,
  required MapData map,
  required String triggerId,
}) {
  if (project.settings.dimension != ProjectDimension.twoD ||
      map.spatialScene != null ||
      map.version == ProjectVersion.v9 ||
      map.id.isEmpty ||
      map.id.trim() != map.id ||
      triggerId.isEmpty ||
      triggerId.trim() != triggerId ||
      project.maps.where((entry) => entry.id == map.id).length != 1 ||
      map.size.width <= 0 ||
      map.size.height <= 0) {
    return false;
  }
  final matches = map.triggers
      .where((trigger) => trigger.id == triggerId)
      .toList();
  if (matches.length != 1 || matches.single.type != TriggerType.event) {
    return false;
  }
  final area = matches.single.area;
  return area.pos.x >= 0 &&
      area.pos.y >= 0 &&
      area.size.width > 0 &&
      area.size.height > 0 &&
      area.pos.x + area.size.width <= map.size.width &&
      area.pos.y + area.size.height <= map.size.height;
}
