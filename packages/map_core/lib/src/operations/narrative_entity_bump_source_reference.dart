import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/map_spatial_scene.dart';
import '../models/project_manifest.dart';
import 'map_entity_collision_footprint.dart';
import 'scene_actor_reference.dart';

bool isNarrativeEntityBumpSourceAvailable({
  required ProjectManifest project,
  required MapData map,
  required String entityId,
}) {
  if (project.settings.dimension != ProjectDimension.twoD ||
      map.spatialScene != null ||
      map.version == ProjectVersion.v9 ||
      map.id.isEmpty ||
      map.id.trim() != map.id ||
      entityId.isEmpty ||
      entityId.trim() != entityId ||
      project.maps.where((entry) => entry.id == map.id).length != 1) {
    return false;
  }
  final entities = map.entities
      .where((entity) => entity.id == entityId)
      .toList();
  if (entities.length != 1) {
    return false;
  }
  final entity = entities.single;
  if (!entity.blocksMovement ||
      !isSceneActorEntityReferenceAvailable(project, entity) ||
      entity.size.width <= 0 ||
      entity.size.height <= 0) {
    return false;
  }
  final footprint = resolveEntityCollisionFootprint(entity);
  return footprint.size.width > 0 &&
      footprint.size.height > 0 &&
      footprint.pos.x >= 0 &&
      footprint.pos.y >= 0 &&
      footprint.pos.x + footprint.size.width <= map.size.width &&
      footprint.pos.y + footprint.size.height <= map.size.height;
}
