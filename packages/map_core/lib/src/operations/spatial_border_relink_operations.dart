import '../exceptions/map_exceptions.dart';
import '../models/border_diagnostics.dart';
import '../models/border_feature.dart';
import '../models/border_geometry.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import '../models/project_model3d.dart';
import 'border_layer_operations.dart';
import 'border_linear_lattice.dart';
import 'border_resolver.dart';
import 'spatial_border_resolution.dart';

MapData relinkSpatialBorderFeature(
  MapData map, {
  required ProjectManifest manifest,
  required String layerId,
  required String featureId,
  required String targetBlueprintId,
  bool reverseStrokes = false,
  bool clearVerticalOffset = false,
  Map<String, String> replacementPrimitiveIdsBySlot = const {},
  int resolverVersion = borderResolverVersion,
}) {
  final source = map.layers
      .whereType<BorderLayer>()
      .where((layer) => layer.id == layerId)
      .firstOrNull
      ?.content
      .featureById(featureId);
  final target = manifest.borderCatalog.recordById(targetBlueprintId);
  final sourceDefinition = manifest.borderCatalog
      .recordById(source?.blueprintId ?? '')
      ?.latestPublished
      ?.definition;
  if (map.spatialScene == null ||
      source == null ||
      sourceDefinition?.isSpatial != true ||
      target == null ||
      target.isDeprecated ||
      target.latestPublished?.definition.isSpatial != true ||
      source.blueprintId == targetBlueprintId ||
      sourceDefinition!.template !=
          target.latestPublished!.definition.template) {
    throw const ValidationException(
      'Spatial Border relink requires compatible published profiles',
    );
  }
  var geometry = source.geometry;
  if (reverseStrokes) {
    if (geometry is! BorderStrokeGeometry) {
      throw const ValidationException(
        'Only explicit Border strokes can be reversed',
      );
    }
    geometry = BorderStrokeGeometry(
      alignment: geometry.alignment,
      strokes: [
        for (final stroke in geometry.strokes)
          _reversedStroke(stroke, sourceDefinition.sequenceLength),
      ],
    );
  }
  final replacementSlots = source.overrides
      .where((o) => o.replacementPrimitiveId != null)
      .map((o) => o.slotKey)
      .toSet();
  if (replacementPrimitiveIdsBySlot.keys.any(
        (slot) => !replacementSlots.contains(slot),
      ) ||
      (reverseStrokes &&
          replacementSlots.any(
            (slot) => !replacementPrimitiveIdsBySlot.containsKey(slot),
          ))) {
    throw const ValidationException(
      'Every replacement must have an explicit slot mapping when reversing contours; foreign mappings are refused',
    );
  }
  if (source.overrides.any(
    (o) =>
        o.locked ||
        (reverseStrokes &&
            (o.transformOverride != null || o.offsetDeltaPx != null)),
  )) {
    throw const ValidationException(
      'Locked or transformed Border overrides cannot be safely remapped',
    );
  }
  final overrides = [
    for (final override in source.overrides)
      BorderSlotOverride(
        slotKey: override.slotKey,
        variationSalt: override.variationSalt,
        suppressed: override.suppressed,
        locked: false,
        replacementPrimitiveId:
            replacementPrimitiveIdsBySlot[override.slotKey] ??
            override.replacementPrimitiveId,
        offsetDeltaPx: override.offsetDeltaPx,
        transformOverride: override.transformOverride,
      ),
  ];
  final offset = source.spatialOffsetWorld;
  final candidate = upsertBorderFeature(
    map,
    layerId: layerId,
    feature: BorderFeature(
      id: source.id,
      name: source.name,
      blueprintId: targetBlueprintId,
      seed: source.seed,
      geometry: geometry,
      lineSide: source.lineSide,
      spatialOffsetWorld: clearVerticalOffset && offset != null
          ? Model3dVector3(x: offset.x, y: 0, z: offset.z)
          : offset,
      paramsOverride: source.paramsOverride,
      overrides: overrides,
      keepOutRegions: source.keepOutRegions,
      materialization: source.materialization,
    ),
  );
  final sourceKeys = resolveSpatialBorderFeatureBaseSlotKeys(
    manifest: manifest,
    map: map,
    layerId: layerId,
    featureId: featureId,
  );
  final targetKeys = resolveSpatialBorderFeatureBaseSlotKeys(
    manifest: manifest,
    map: candidate,
    layerId: layerId,
    featureId: featureId,
  );
  for (final override in overrides) {
    if (!sourceKeys.contains(override.slotKey) ||
        !targetKeys.contains(override.slotKey)) {
      throw ValidationException(
        'Border override cannot be remapped: ${override.slotKey}',
      );
    }
  }
  final resolved = resolveSpatialBorderFeature(
    manifest: manifest,
    map: candidate,
    layerId: layerId,
    featureId: featureId,
    resolverVersion: resolverVersion,
  );
  if (!resolved.result.canApply) {
    final errors = resolved.result.diagnostics
        .where((d) => d.severity == BorderDiagnosticSeverity.error)
        .map((d) => '${d.code}:${d.slotKey ?? featureId}')
        .take(8)
        .join(', ');
    throw ValidationException(
      'Spatial Border relink cannot preserve its corrections: $errors',
    );
  }
  return applySpatialBorderFeaturePreview(
    candidate,
    manifest: manifest,
    proposedResult: resolved,
  );
}

BorderStroke _reversedStroke(BorderStroke stroke, int sequenceLength) {
  final lineage = resolveBorderStrokeLineageIdentityV1(stroke);
  final points = stroke.closed
      ? [stroke.points.first, ...stroke.points.skip(1).toList().reversed]
      : stroke.points.reversed.toList();
  final offset = sequenceLength == 2 && !stroke.closed
      ? lineage.sourceEdgeOffset +
            buildBorderLinearLatticeV1(
              stroke: stroke,
              tileSizePx: const GridSize(width: 1, height: 1),
              preserveTraversal: true,
            ).nodes.length -
            1
      : lineage.sourceEdgeOffset;
  return BorderStroke(
    id: lineage.preserveTraversal || (offset % sequenceLength != 0)
        ? buildBorderPreservedStrokeIdV1(
            authoredStrokeId: lineage.authoredStrokeId,
            sourceEdgeOffset: lineage.wrapLength == null
                ? offset
                : offset % lineage.wrapLength!,
            wrapLength: lineage.wrapLength,
            orderedPoints: points,
          )
        : stroke.id,
    points: points,
    closed: stroke.closed,
  );
}
