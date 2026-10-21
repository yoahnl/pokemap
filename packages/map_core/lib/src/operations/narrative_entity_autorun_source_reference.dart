import '../models/enums.dart';
import '../models/narrative_map_view.dart';
import '../models/map_spatial_scene.dart';
import '../models/project_manifest.dart';

bool isNarrativeEntityAutorunSourceAvailable({
  required ProjectManifest project,
  required NarrativeMapView map,
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
  return map.entities.where((entity) => entity.id == entityId).length == 1;
}
