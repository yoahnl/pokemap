import '../exceptions/map_exceptions.dart';
import '../models/border_ground_footprint.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';
import '../models/spatial_navigation.dart';
import '../models/spatial_terrain_surface.dart';
import 'spatial_border_resolution.dart';
import 'spatial_map_operations.dart';
import 'spatial_terrain_height_paint.dart';
import 'spatial_terrain_slope_cliff_cut.dart';
import 'spatial_terrain_relief_trace.dart';
import 'spatial_terrain_slope_plan.dart';

final class TerrainSlopePaint {
  const TerrainSlopePaint({
    required this.map,
    required this.plan,
    required this.surfaceId,
    required this.traces,
    required this.refreshedBorders,
    required this.staleBorders,
    required this.resolvedBorderFeatures,
  });
  final MapData map;
  final TerrainSlopePlan plan;
  final String surfaceId;
  final List<TerrainReliefTrace> traces;
  final List<String> refreshedBorders, staleBorders, resolvedBorderFeatures;
}

TerrainSlopePaint paintTerrainSlope({
  required ProjectManifest manifest,
  required MapData map,
  required GridPos from,
  required GridPos to,
  bool reanchorInstances = true,
}) => applyTerrainSlope(
  manifest: manifest,
  map: map,
  plan: planTerrainSlope(map, from, to),
  reanchorInstances: reanchorInstances,
);

TerrainSlopePaint applyTerrainSlope({
  required ProjectManifest manifest,
  required MapData map,
  required TerrainSlopePlan plan,
  bool reanchorInstances = true,
}) {
  final scene = map.spatialScene!;
  final count = scene.terrainSurfaces.surfaces.length + 1;
  if (count > maximumSpatialTerrainSurfaces) {
    throw ValidationException(
      'A map holds at most $maximumSpatialTerrainSurfaces terrain surfaces.',
      code: 'spatial.terrain.paint.surface_limit',
      details: {
        'surfaceCount': count,
        'maximum': maximumSpatialTerrainSurfaces,
      },
    );
  }
  final surface = slopeSurface(nextSpatialTerrainSurfaceId(scene), plan);
  var next = const SpatialMapOperations().upsertTerrainSurfaces(
    map,
    [surface],
    reanchorInstances: reanchorInstances,
    pinBorderOwnedInstances: true,
  );
  final cut = cutCliffsAtSlope(manifest, next, plan);
  next = cut.map;
  final refresh = refreshSpatialBordersForTerrainChange(
    manifest: manifest,
    before: map,
    after: next,
    skipFeatureKeys: cut.resolved.toSet(),
  );
  return TerrainSlopePaint(
    map: refresh.map,
    plan: plan,
    surfaceId: surface.id,
    traces: List.unmodifiable(cut.traces),
    refreshedBorders: refresh.refreshed,
    staleBorders: refresh.stale,
    resolvedBorderFeatures: List.unmodifiable([
      ...cut.resolved,
      ...refresh.resolved,
    ]),
  );
}

SpatialTerrainSurface slopeSurface(String id, TerrainSlopePlan plan) {
  final rise = (plan.upperHeight - plan.lowerHeight) / plan.length;
  final highAtOrigin =
      plan.direction == SpatialRampDirection.north ||
      plan.direction == SpatialRampDirection.west;
  final gradient = highAtOrigin ? -rise : rise;
  return SpatialTerrainSurface(
    id: id,
    x: plan.left.toDouble(),
    z: plan.top.toDouble(),
    height: highAtOrigin ? plan.upperHeight : plan.lowerHeight,
    gradientX: plan.alongX ? gradient : 0,
    gradientZ: plan.alongX ? 0 : gradient,
    closedFlanks: true,
    footprints: [
      BorderGroundFootprint(
        points: [
          BorderGroundPoint(x: 0, z: 0),
          BorderGroundPoint(x: plan.width.toDouble(), z: 0),
          BorderGroundPoint(x: plan.width.toDouble(), z: plan.depth.toDouble()),
          BorderGroundPoint(x: 0, z: plan.depth.toDouble()),
        ],
      ),
    ],
  );
}
