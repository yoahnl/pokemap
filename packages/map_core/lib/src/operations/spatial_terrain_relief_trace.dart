import '../exceptions/map_exceptions.dart';
import '../models/border_feature.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';
import 'spatial_border_resolution.dart';
import 'spatial_height_step_contours.dart';

enum TerrainReliefTraceChange { created, updated, deleted }

final class TerrainReliefTrace {
  const TerrainReliefTrace({
    required this.lowerHeight,
    required this.upperHeight,
    required this.layerId,
    required this.featureId,
    required this.blueprintId,
    required this.change,
  });
  final double lowerHeight, upperHeight;
  final String layerId, featureId, blueprintId;
  final TerrainReliefTraceChange change;
}

HeightStepContours terrainReliefContour(
  MapData map,
  double lower,
  double upper,
  Set<GridPos> cells,
) => computeHeightStepEdges(
  map,
  lowerHeight: lower,
  upperHeight: upper,
  cells: cells,
  exactHeights: true,
);

String terrainReliefProfileFor(
  double levelHeight,
  double lower,
  double upper,
  String oneLevel,
  String? twoLevels,
) {
  final levels = (upper - lower) / levelHeight;
  final rounded = levels.round();
  final details = {
    'lowerHeight': lower,
    'upperHeight': upper,
    'levels': levels,
  };
  if ((levels - rounded).abs() > 1e-6) {
    throw ValidationException(
      'This step does not match the map level height.',
      code: 'spatial.relief.step_not_level',
      details: details,
    );
  }
  if (rounded == 1) return oneLevel;
  if (rounded == 2 && twoLevels != null) return twoLevels;
  throw ValidationException(
    rounded == 2
        ? 'This two-level step needs a two-level profile.'
        : 'This step is higher than two levels.',
    code: rounded == 2
        ? 'spatial.relief.two_level_profile_missing'
        : 'spatial.relief.step_too_high',
    details: details,
  );
}

MapData materializeTerrainRelief(
  ProjectManifest manifest,
  MapData map,
  String layerId,
  String featureId,
) {
  final resolved = resolveSpatialBorderFeature(
    manifest: manifest,
    map: map,
    layerId: layerId,
    featureId: featureId,
  );
  final diagnostics = resolved.result.diagnostics;
  final codes = [for (final diagnostic in diagnostics) diagnostic.code];
  if (!resolved.result.canApply) {
    throw ValidationException(
      'The cliff profile cannot follow this contour.',
      code: 'spatial.relief.trace_refused',
      details: {'featureId': featureId, 'diagnostics': codes.take(20).toList()},
    );
  }
  final mismatches = codes.where(_faceMismatches.contains).toSet();
  if (mismatches.isNotEmpty) {
    throw ValidationException(
      'The cliff profile does not resolve this height step safely.',
      code: 'spatial.relief.profile_incompatible',
      details: {'featureId': featureId, 'diagnostics': mismatches.toList()},
    );
  }
  return applySpatialBorderFeaturePreview(
    map,
    manifest: manifest,
    proposedResult: resolved,
  );
}

const _faceMismatches = {
  'border.spatial.face_crown_mismatch',
  'border.spatial.face_base_mismatch',
  'border.spatial.face_on_land_side',
  'border.spatial.face_mass_on_land_side',
};

TerrainReliefTrace terrainReliefTrace(
  double lower,
  double upper,
  String layerId,
  BorderFeature feature,
  TerrainReliefTraceChange change,
) => TerrainReliefTrace(
  lowerHeight: lower,
  upperHeight: upper,
  layerId: layerId,
  featureId: feature.id,
  blueprintId: feature.blueprintId,
  change: change,
);
