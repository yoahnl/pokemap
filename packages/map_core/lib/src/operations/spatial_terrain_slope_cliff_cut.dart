import '../exceptions/map_exceptions.dart';
import '../models/border_geometry.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import 'border_feature_update_operations.dart';
import 'border_layer_operations.dart';
import 'border_stroke_edge_cut.dart';
import 'spatial_border_resolution.dart';
import 'spatial_terrain_relief_trace.dart';
import 'spatial_terrain_slope_plan.dart';

typedef SlopeCliffCut = ({
  MapData map,
  List<TerrainReliefTrace> traces,
  List<String> resolved,
});

Set<(GridPos, GridPos)> slopeHighEndEdges(TerrainSlopePlan plan) {
  final (dx, dy) = slopeClimb(plan.direction);
  return {
    for (final cell in plan.highSide)
      switch ((dx, dy)) {
        (0, -1) => (
          GridPos(x: cell.x, y: cell.y + 1),
          GridPos(x: cell.x + 1, y: cell.y + 1),
        ),
        (0, 1) => (
          GridPos(x: cell.x, y: cell.y),
          GridPos(x: cell.x + 1, y: cell.y),
        ),
        (1, 0) => (
          GridPos(x: cell.x, y: cell.y),
          GridPos(x: cell.x, y: cell.y + 1),
        ),
        _ => (
          GridPos(x: cell.x + 1, y: cell.y),
          GridPos(x: cell.x + 1, y: cell.y + 1),
        ),
      },
  };
}

SlopeCliffCut cutCliffsAtSlope(
  ProjectManifest manifest,
  MapData map,
  TerrainSlopePlan plan,
) {
  final edges = slopeHighEndEdges(plan);
  bool cut(GridPos a, GridPos b) =>
      edges.contains((a, b)) || edges.contains((b, a));
  var next = map;
  final traces = <TerrainReliefTrace>[];
  final resolved = <String>[];
  for (final layer in map.layers.whereType<BorderLayer>()) {
    for (final feature in layer.content.features) {
      final geometry = feature.geometry;
      if (geometry is! BorderStrokeGeometry ||
          geometry.alignment != BorderStrokeAlignment.gridEdges) {
        continue;
      }
      final remaining = cutBorderStrokeEdges(geometry, cut);
      if (identical(remaining, geometry)) continue;
      if (remaining.strokes.isEmpty) {
        next = removeBorderFeature(
          next,
          layerId: layer.id,
          featureId: feature.id,
        );
        traces.add(
          _trace(
            plan,
            layer.id,
            feature.id,
            feature.blueprintId,
            TerrainReliefTraceChange.deleted,
          ),
        );
        continue;
      }
      next = updateBorderFeatureGeometry(
        next,
        layerId: layer.id,
        featureId: feature.id,
        geometry: remaining,
      );
      next = _materialize(manifest, next, layer.id, feature.id);
      resolved.add('${layer.id}/${feature.id}');
      traces.add(
        _trace(
          plan,
          layer.id,
          feature.id,
          feature.blueprintId,
          TerrainReliefTraceChange.updated,
        ),
      );
    }
  }
  return (map: next, traces: traces, resolved: resolved);
}

MapData _materialize(
  ProjectManifest manifest,
  MapData map,
  String layerId,
  String featureId,
) {
  var proposed = map;
  var result = resolveSpatialBorderFeature(
    manifest: manifest,
    map: proposed,
    layerId: layerId,
    featureId: featureId,
  );
  final orphaned = {
    for (final issue in result.result.diagnostics)
      if (issue.code == 'border.spatial.override_slot_missing') issue.slotKey,
  };
  if (orphaned.isNotEmpty) {
    final feature = proposed.layers
        .whereType<BorderLayer>()
        .singleWhere((layer) => layer.id == layerId)
        .content
        .features
        .singleWhere((feature) => feature.id == featureId);
    proposed = updateBorderFeatureOverrides(
      proposed,
      layerId: layerId,
      featureId: featureId,
      overrides: [
        for (final override in feature.overrides)
          if (!orphaned.contains(override.slotKey)) override,
      ],
    );
    result = resolveSpatialBorderFeature(
      manifest: manifest,
      map: proposed,
      layerId: layerId,
      featureId: featureId,
    );
  }
  if (!result.result.canApply) {
    throw ValidationException(
      'The cliff cannot be cut here.',
      code: 'spatial.relief.trace_refused',
      details: {
        'featureId': featureId,
        'diagnostics': [
          for (final issue in result.result.diagnostics.take(20)) issue.code,
        ],
      },
    );
  }
  return applySpatialBorderFeaturePreview(
    proposed,
    manifest: manifest,
    proposedResult: result,
  );
}

TerrainReliefTrace _trace(
  TerrainSlopePlan plan,
  String layerId,
  String featureId,
  String blueprintId,
  TerrainReliefTraceChange change,
) => TerrainReliefTrace(
  lowerHeight: plan.lowerHeight,
  upperHeight: plan.upperHeight,
  layerId: layerId,
  featureId: featureId,
  blueprintId: blueprintId,
  change: change,
);
