import '../exceptions/map_exceptions.dart';
import '../models/border_feature.dart';
import '../models/border_geometry.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/border_signed_int64.dart';
import '../models/project_manifest.dart';
import 'border_layer_operations.dart';
import 'spatial_border_resolution.dart';
import 'spatial_height_step_contours.dart';
import 'spatial_map_edit_intents.dart';
import 'spatial_terrain_height_paint.dart';
import 'spatial_terrain_relief_access.dart';
import 'spatial_terrain_relief_support.dart';
import 'spatial_terrain_relief_trace.dart';

final class TerrainReliefPaint {
  const TerrainReliefPaint({
    required this.map,
    required this.surfaces,
    required this.traces,
    required this.refreshedBorders,
    required this.staleBorders,
    required this.unreachable,
    required this.resolvedBorderFeatures,
  });
  final MapData map;
  final TerrainHeightPaint surfaces;
  final List<TerrainReliefTrace> traces;
  final List<String> refreshedBorders, staleBorders;
  final bool unreachable;
  final List<String> resolvedBorderFeatures;
}

TerrainReliefPaint paintTerrainRelief({
  required ProjectManifest manifest,
  required MapData map,
  required Iterable<GridPos> cells,
  required int level,
  required String blueprintId,
  String? twoLevelBlueprintId,
  String? layerId,
  bool reanchorInstances = true,
}) {
  final scene = map.spatialScene;
  if (scene == null) {
    throw const ValidationException(
      'Painting a relief requires a 3D map.',
      code: 'spatial.terrain.paint.dimension_required',
    );
  }
  final painted = cells.toSet();
  final height = level * scene.levelHeight;
  if (level < 0 || height > 1024) {
    throw ValidationException(
      'Choose a level from 0 to ${(1024 / scene.levelHeight).floor()}.',
      code: 'spatial.relief.level_invalid',
      details: {'level': level},
    );
  }
  terrainReliefProfile(manifest, map, blueprintId, levels: 1);
  if (twoLevelBlueprintId != null) {
    terrainReliefProfile(manifest, map, twoLevelBlueprintId, levels: 2);
  }
  final surfaces = paintTerrainCellsAtHeight(
    map,
    painted,
    height: height,
    reanchorInstances: reanchorInstances,
    pinBorderOwnedInstances: true,
  );
  var next = surfaces.map;
  final steps =
      {
        for (final step in [
          ...terrainHeightStepsAround(map, painted),
          ...terrainHeightStepsAround(next, painted),
        ])
          (step.lower, step.upper),
      }.toList()..sort(
        (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
      );
  final traces = <TerrainReliefTrace>[];
  final resolved = <String>[];
  final claimed = <String>{};
  for (final (lower, upper) in steps) {
    final old = terrainReliefContour(map, lower, upper, painted);
    final contour = terrainReliefContour(next, lower, upper, painted);
    if (contour.status == SpatialIntentResolutionState.ambiguous ||
        contour.status == SpatialIntentResolutionState.unsupported) {
      throw ValidationException(
        'This relief needs an explicit contour.',
        code: 'spatial.relief.step_ambiguous',
        details: {
          'lowerHeight': lower,
          'upperHeight': upper,
          'reason': contour.reason ?? contour.status.name,
          'vertices': [
            for (final cell in contour.ambiguousVertices.take(20))
              cell.toJson(),
          ],
        },
      );
    }
    final edges = terrainReliefEdges(contour.strokes);
    final matched = [
      for (final match in cliffFeaturesOnEdges(next, manifest, {
        ...terrainReliefEdges(old.strokes),
        ...edges,
      }))
        if (claimed.add('${match.layerId}/${match.feature.id}')) match,
    ];
    if (edges.isEmpty) {
      for (final match in matched) {
        next = removeBorderFeature(
          next,
          layerId: match.layerId,
          featureId: match.feature.id,
        );
        traces.add(
          terrainReliefTrace(
            lower,
            upper,
            match.layerId,
            match.feature,
            TerrainReliefTraceChange.deleted,
          ),
        );
      }
      continue;
    }
    final keep = matched.firstOrNull;
    final profileId =
        keep?.feature.blueprintId ??
        terrainReliefProfileFor(
          scene.levelHeight,
          lower,
          upper,
          blueprintId,
          twoLevelBlueprintId,
        );
    final definition = manifest.borderCatalog
        .recordById(profileId)!
        .latestPublished!
        .definition;
    final target = keep?.layerId ?? terrainReliefLayerId(next, layerId);
    if (!next.layers.any((layer) => layer.id == target)) {
      next = addBorderLayer(next, id: target, name: 'Reliefs');
    }
    final previous = keep?.feature;
    final featureId = previous?.id ?? nextTerrainReliefFeatureId(next);
    for (final extra in matched.skip(1)) {
      next = removeBorderFeature(
        next,
        layerId: extra.layerId,
        featureId: extra.feature.id,
      );
      traces.add(
        terrainReliefTrace(
          lower,
          upper,
          extra.layerId,
          extra.feature,
          TerrainReliefTraceChange.deleted,
        ),
      );
    }
    next = upsertBorderFeature(
      next,
      layerId: target,
      template: definition.template,
      feature: BorderFeature(
        id: featureId,
        name: previous?.name ?? definition.name,
        blueprintId: profileId,
        seed: previous?.seed ?? BorderSignedInt64(BigInt.zero),
        geometry: BorderStrokeGeometry(
          strokes: terrainReliefStrokes(contour.strokes, previous),
          alignment: BorderStrokeAlignment.gridEdges,
        ),
        lineSide: previous?.lineSide ?? BorderLineSide.primary,
        spatialOffsetWorld: previous?.spatialOffsetWorld,
        paramsOverride: previous?.paramsOverride,
        overrides: previous?.overrides ?? const [],
        keepOutRegions: previous?.keepOutRegions ?? const [],
        materialization: previous?.materialization,
      ),
    );
    resolved.add('$target/$featureId');
    next = materializeTerrainRelief(manifest, next, target, featureId);
    traces.add(
      TerrainReliefTrace(
        lowerHeight: lower,
        upperHeight: upper,
        layerId: target,
        featureId: featureId,
        blueprintId: profileId,
        change: previous == null
            ? TerrainReliefTraceChange.created
            : TerrainReliefTraceChange.updated,
      ),
    );
  }
  final refresh = refreshSpatialBordersForTerrainChange(
    manifest: manifest,
    before: map,
    after: next,
    skipFeatureKeys: claimed.union(resolved.toSet()),
  );
  return TerrainReliefPaint(
    map: refresh.map,
    surfaces: surfaces,
    traces: List.unmodifiable(traces),
    refreshedBorders: refresh.refreshed,
    staleBorders: refresh.stale,
    unreachable: terrainReliefUnreachable(refresh.map, painted, height),
    resolvedBorderFeatures: List.unmodifiable([
      ...resolved,
      ...refresh.resolved,
    ]),
  );
}
