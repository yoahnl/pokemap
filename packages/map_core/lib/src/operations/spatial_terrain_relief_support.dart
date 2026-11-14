import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/border_feature.dart';
import '../models/border_geometry.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import 'border_template_capabilities.dart';
import 'spatial_border_resolution.dart';

typedef TerrainReliefEdge = (GridPos, GridPos);

int spatialBorderProfileLevelSpan(
  BorderBlueprintPublishedDefinition definition,
  ProjectManifest manifest,
  double levelHeight,
) {
  if (!definition.isSpatial || levelHeight <= 0) return 0;
  final models = {for (final model in manifest.models3d) model.id: model};
  var face = 0.0;
  for (final primitive in definition.primitives) {
    if (primitive.weight <= 0 ||
        primitive.role != BorderPrimitiveRole.lineStraight) {
      continue;
    }
    final model = models[primitive.sourceModelId];
    if (model == null) continue;
    final bounds = model.inspection.bounds;
    final anchor = primitive.anchorWorld ?? model.pivot;
    final span = (bounds.max.y - bounds.min.y) * model.scale;
    final height = (anchor.y - bounds.min.y) * model.scale;
    final headroom = (bounds.max.y - anchor.y) * model.scale;
    if (span <= 0 || height < span * .75 || headroom < -span * .25) continue;
    if (height > face) face = height;
  }
  return (face / levelHeight).round();
}

BorderBlueprintPublishedDefinition terrainReliefProfile(
  ProjectManifest manifest,
  MapData map,
  String blueprintId, {
  required int levels,
}) {
  final definition = manifest.borderCatalog
      .recordById(blueprintId)
      ?.latestPublished
      ?.definition;
  if (definition == null ||
      !definition.isSpatial ||
      !borderTemplateUsesStrokeGeometry(definition.template) ||
      !manifest.resourceLibraryCatalog.availableForMap(
        'borderBlueprint',
        blueprintId,
        map.id,
      )) {
    throw ValidationException(
      'Choose a published 3D cliff profile available on this map.',
      code: 'spatial.relief.profile_unavailable',
      details: {'blueprintId': blueprintId},
    );
  }
  final faces = validateSpatialDirectedFaceOrientation(
    blueprintId: blueprintId,
    definition: definition,
    manifest: manifest,
  );
  if (faces.isNotEmpty) {
    throw ValidationException(
      'This profile puts its faces on the high side; choose its right-handed variant.',
      code: 'spatial.relief.profile_faces_high_side',
      details: {'blueprintId': blueprintId, 'primitiveCount': faces.length},
    );
  }
  final span = spatialBorderProfileLevelSpan(
    definition,
    manifest,
    map.spatialScene!.levelHeight,
  );
  if (span != levels) {
    throw ValidationException(
      'This profile covers $span levels; this step needs $levels.',
      code: 'spatial.relief.profile_level_span',
      details: {
        'blueprintId': blueprintId,
        'levelSpan': span,
        'expected': levels,
      },
    );
  }
  return definition;
}

Set<TerrainReliefEdge> terrainReliefEdges(Iterable<List<GridPos>> strokes) => {
  for (final stroke in strokes)
    for (var index = 1; index < stroke.length; index++)
      _undirected(stroke[index - 1], stroke[index]),
};

Set<TerrainReliefEdge> borderFeatureEdges(BorderFeature feature) {
  final geometry = feature.geometry;
  if (geometry is! BorderStrokeGeometry ||
      geometry.alignment != BorderStrokeAlignment.gridEdges) {
    return const {};
  }
  return terrainReliefEdges([
    for (final stroke in geometry.strokes)
      [...stroke.points, if (stroke.closed) stroke.points.first],
  ]);
}

List<({String layerId, BorderFeature feature})> cliffFeaturesOnEdges(
  MapData map,
  ProjectManifest manifest,
  Set<TerrainReliefEdge> edges,
) {
  if (edges.isEmpty) return const [];
  final spans = <String, int>{};
  final levelHeight = map.spatialScene!.levelHeight;
  return [
    for (final layer in map.layers.whereType<BorderLayer>())
      for (final feature in layer.content.features)
        if ((spans[feature.blueprintId] ??= _span(
                  manifest,
                  feature.blueprintId,
                  levelHeight,
                )) >
                0 &&
            borderFeatureEdges(feature).any(edges.contains))
          (layerId: layer.id, feature: feature),
  ];
}

List<BorderStroke> terrainReliefStrokes(
  List<List<GridPos>> contours,
  BorderFeature? previous,
) {
  final geometry = previous?.geometry;
  final ids = geometry is BorderStrokeGeometry
      ? [for (final stroke in geometry.strokes) stroke.id]
      : const <String>[];
  return [
    for (final (index, points) in contours.indexed)
      BorderStroke(
        id: index < ids.length ? ids[index] : 'step-$index',
        closed: points.first == points.last,
        points: points.first == points.last
            ? points.sublist(0, points.length - 1)
            : points,
      ),
  ];
}

String terrainReliefLayerId(MapData map, String? requested) {
  if (requested != null) return requested;
  return map.layers
          .whereType<BorderLayer>()
          .where((layer) => layer.isVisible)
          .firstOrNull
          ?.id ??
      'reliefs';
}

String nextTerrainReliefFeatureId(MapData map) {
  final ids = {
    for (final layer in map.layers.whereType<BorderLayer>())
      for (final feature in layer.content.features) feature.id,
  };
  var index = 1;
  while (ids.contains('relief-$index')) {
    index++;
  }
  return 'relief-$index';
}

int _span(ProjectManifest manifest, String blueprintId, double levelHeight) {
  final definition = manifest.borderCatalog
      .recordById(blueprintId)
      ?.latestPublished
      ?.definition;
  return definition == null
      ? 0
      : spatialBorderProfileLevelSpan(definition, manifest, levelHeight);
}

TerrainReliefEdge _undirected(GridPos a, GridPos b) =>
    (a.y < b.y || a.y == b.y && a.x <= b.x) ? (a, b) : (b, a);
