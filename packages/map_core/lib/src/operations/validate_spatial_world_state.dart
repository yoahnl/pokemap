import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/map_spatial_scene.dart';
import '../models/project_manifest.dart';
import '../models/spatial_world_state.dart';

void validateSpatialWorldState({
  required SpatialWorldState state,
  required ProjectManifest project,
  required Iterable<MapData> maps,
}) {
  if (state.modelsByMap.isEmpty && state.actorsByMap.isEmpty) return;
  if (project.settings.dimension != ProjectDimension.threeD) {
    throw const FormatException(
      'A 2D save cannot contain spatial world poses.',
    );
  }
  final mapsById = {for (final map in maps) map.id: map};
  final resources = {for (final model in project.models3d) model.id: model};
  for (final entry in state.modelsByMap.entries) {
    final scene = mapsById[entry.key]?.spatialScene;
    if (scene == null)
      throw FormatException('Saved model map is missing: ${entry.key}.');
    for (final pose in entry.value.entries) {
      final instance = scene.instances
          .where((value) => value.id == pose.key)
          .firstOrNull;
      final resource = resources[pose.value.modelId];
      if (instance?.modelId != pose.value.modelId ||
          resource == null ||
          (pose.value.animationIndex != null &&
              !resource.inspection.animations.any(
                (clip) => clip.index == pose.value.animationIndex,
              ))) {
        throw FormatException(
          'Saved model pose is incompatible: ${entry.key}/${pose.key}.',
        );
      }
    }
  }
  for (final entry in state.actorsByMap.entries) {
    final map = mapsById[entry.key];
    if (map?.spatialScene == null)
      throw FormatException('Saved actor map is missing: ${entry.key}.');
    for (final pose in entry.value.entries) {
      if (!map!.entities.any(
            (entity) =>
                entity.id == pose.key && entity.kind == MapEntityKind.npc,
          ) ||
          pose.value.x >= map.size.width ||
          pose.value.z >= map.size.height) {
        throw FormatException(
          'Saved actor pose is incompatible: ${entry.key}/${pose.key}.',
        );
      }
    }
  }
}
