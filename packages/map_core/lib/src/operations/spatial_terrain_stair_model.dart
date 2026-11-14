import '../exceptions/map_exceptions.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';
import '../models/project_model3d.dart';
import '../models/spatial_navigation.dart';

final _stairName = RegExp(r'escalier|stair|marche|steps', caseSensitive: false);

final class TerrainStairModel {
  const TerrainStairModel({
    required this.model,
    required this.acrossCells,
    required this.alongCells,
    required this.levels,
    required this.nativeDirection,
  });

  final ProjectModel3dEntry model;
  final int acrossCells, alongCells, levels;
  final SpatialRampDirection nativeDirection;
}

TerrainStairModel? terrainStairModelGeometry(
  ProjectModel3dEntry model,
  double levelHeight,
) {
  final bounds = model.inspection.bounds;
  final sizeX = (bounds.max.x - bounds.min.x) * model.scale;
  final sizeY = (bounds.max.y - bounds.min.y) * model.scale;
  final sizeZ = (bounds.max.z - bounds.min.z) * model.scale;
  final alongX = sizeX < sizeZ - 1e-6;
  final along = (alongX ? sizeX : sizeZ).round();
  final across = ((alongX ? sizeZ : sizeX) + 1e-6).floor();
  final levels = levelHeight <= 0 ? 0 : (sizeY / levelHeight).round();
  if (along < 1 || across < 1 || levels < 1 || along > 8 || across > 8) {
    return null;
  }
  return TerrainStairModel(
    model: model,
    acrossCells: across,
    alongCells: along,
    levels: levels,
    nativeDirection: alongX
        ? SpatialRampDirection.west
        : SpatialRampDirection.north,
  );
}

List<TerrainStairModel> terrainStairCandidates(
  ProjectManifest manifest,
  MapData map,
) {
  final levelHeight = map.spatialScene?.levelHeight;
  if (levelHeight == null) return const [];
  final library = manifest.resourceLibraryCatalog;
  return [
    for (final model in manifest.models3d)
      if (_stairName.hasMatch(model.name) &&
          model.rampProfile == null &&
          library.availableForMap('model3d', model.id, map.id))
        ?terrainStairModelGeometry(model, levelHeight),
  ]..sort((a, b) => a.model.name.compareTo(b.model.name));
}

TerrainStairModel terrainStairModel(
  ProjectManifest manifest,
  MapData map,
  String modelId,
) {
  final model = manifest.models3d.where((m) => m.id == modelId).firstOrNull;
  final geometry =
      model == null ||
          !manifest.resourceLibraryCatalog.availableForMap(
            'model3d',
            modelId,
            map.id,
          )
      ? null
      : terrainStairModelGeometry(model, map.spatialScene!.levelHeight);
  if (geometry == null) {
    throw ValidationException(
      'Choose a stair model available on this map.',
      code: 'spatial.stair.model_unavailable',
      details: {'modelId': modelId},
    );
  }
  return geometry;
}
