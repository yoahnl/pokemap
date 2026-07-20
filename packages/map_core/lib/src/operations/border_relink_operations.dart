import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/border_feature.dart';
import '../models/border_geometry.dart';
import '../models/border_layer.dart';
import '../models/border_resolution.dart';
import '../models/border_value_objects.dart';
import '../models/border_visual_snapshot.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import 'border_feature_update_operations.dart';
import 'border_format_version.dart';
import 'border_resolver.dart';

/// The two persisted geometry families supported by Border V1.
enum BorderGeometryFamily { region, linear, gridEdgeLinear }

/// Whether a blueprint change retains geometry or needs an explicit reset.
enum BorderRelinkKind { sameFamily, requiresFamilyReset }

/// Information actually discarded by a confirmed cross-family reset.
enum BorderRelinkLoss {
  geometry,
  parameters,
  overrides,
  keepOutRegions,
  materialization,
}

/// Immutable, non-mutating proposal for changing one feature blueprint.
final class BorderFeatureRelinkPreview {
  BorderFeatureRelinkPreview._({
    required this.expectedMapId,
    required this.expectedMapSize,
    required this.layerId,
    required this.featureId,
    required this.expectedBaseFeatureFingerprint,
    required this.sourceFamily,
    required this.targetFamily,
    required this.targetTemplate,
    required this.kind,
    required List<BorderRelinkLoss> losses,
    required this.proposedFeature,
    required this.proposedRequest,
    required this.proposedResult,
  }) : losses = List<BorderRelinkLoss>.unmodifiable(losses);

  final String expectedMapId;
  final GridSize expectedMapSize;
  final String layerId;
  final String featureId;
  final String expectedBaseFeatureFingerprint;
  final BorderGeometryFamily sourceFamily;
  final BorderGeometryFamily targetFamily;
  final BorderBlueprintTemplate targetTemplate;
  final BorderRelinkKind kind;
  final List<BorderRelinkLoss> losses;
  final BorderFeature proposedFeature;
  final BorderResolutionRequest? proposedRequest;
  final BorderResolutionResult? proposedResult;

  bool get canApplyResolvedRelink =>
      kind == BorderRelinkKind.sameFamily &&
      proposedRequest != null &&
      proposedResult?.canApply == true;
}

/// Prepares either a canonical same-family preview or an explicit reset plan.
///
/// The source family comes from persisted geometry, so a removed source
/// blueprint leaves its materialization renderable until the user applies a
/// replacement. This operation itself never mutates [map].
BorderFeatureRelinkPreview prepareBorderFeatureRelink({
  required MapData map,
  required String layerId,
  required String featureId,
  required String targetBlueprintId,
  required BorderBlueprintRevision targetBlueprintRevision,
  required Iterable<BorderVisualSnapshot> visualSnapshots,
  required GridSize tileSizePx,
  required int resolverVersion,
}) {
  final normalizedLayerId = _stableId(layerId, 'layerId');
  final normalizedFeatureId = _stableId(featureId, 'featureId');
  final normalizedTargetId = _stableId(targetBlueprintId, 'targetBlueprintId');
  final feature =
      _feature(_borderLayer(map, normalizedLayerId), normalizedFeatureId);
  if (feature.blueprintId == normalizedTargetId) {
    throw const ValidationException(
      'A Border relink target must differ from the current blueprint',
    );
  }

  final sourceFamily = borderGeometryFamily(feature.geometry);
  final targetFamily =
      borderTemplateGeometryFamily(targetBlueprintRevision.definition.template);
  final baseFingerprint = computeBorderFeatureEditFingerprint(feature);

  if (sourceFamily != targetFamily) {
    final resetFeature = BorderFeature(
      id: feature.id,
      name: feature.name,
      blueprintId: normalizedTargetId,
      seed: feature.seed,
      geometry: _emptyGeometryFor(targetFamily, mapSize: map.size),
      lineSide: feature.lineSide,
      paramsOverride: null,
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
      materialization: null,
    );
    return BorderFeatureRelinkPreview._(
      expectedMapId: map.id,
      expectedMapSize: map.size,
      layerId: normalizedLayerId,
      featureId: normalizedFeatureId,
      expectedBaseFeatureFingerprint: baseFingerprint,
      sourceFamily: sourceFamily,
      targetFamily: targetFamily,
      targetTemplate: targetBlueprintRevision.definition.template,
      kind: BorderRelinkKind.requiresFamilyReset,
      losses: _actualResetLosses(feature),
      proposedFeature: resetFeature,
      proposedRequest: null,
      proposedResult: null,
    );
  }

  final targetFeature = BorderFeature(
    id: feature.id,
    name: feature.name,
    blueprintId: normalizedTargetId,
    seed: feature.seed,
    geometry: feature.geometry,
    lineSide: feature.lineSide,
    paramsOverride: feature.paramsOverride,
    overrides: feature.overrides,
    keepOutRegions: feature.keepOutRegions,
    materialization: null,
  );
  final request = BorderResolutionRequest(
    mapSize: map.size,
    tileSizePx: tileSizePx,
    blueprintId: normalizedTargetId,
    blueprintRevision: targetBlueprintRevision,
    feature: targetFeature,
    visualSnapshots: visualSnapshots,
    resolverVersion: resolverVersion,
  );
  final result = resolveBorderFeature(request);
  return BorderFeatureRelinkPreview._(
    expectedMapId: map.id,
    expectedMapSize: map.size,
    layerId: normalizedLayerId,
    featureId: normalizedFeatureId,
    expectedBaseFeatureFingerprint: baseFingerprint,
    sourceFamily: sourceFamily,
    targetFamily: targetFamily,
    targetTemplate: targetBlueprintRevision.definition.template,
    kind: BorderRelinkKind.sameFamily,
    losses: const <BorderRelinkLoss>[],
    proposedFeature: targetFeature,
    proposedRequest: request,
    proposedResult: result,
  );
}

/// Atomically applies a canonical same-family relink preview.
///
/// Expected-state conflicts are identity-preserving no-ops. Cross-family
/// previews are rejected and require [applyBorderFeatureFamilyReset].
MapData applyBorderFeatureRelinkPreview(
  MapData map, {
  required BorderFeatureRelinkPreview preview,
}) {
  if (preview.kind != BorderRelinkKind.sameFamily) {
    throw StateError(
      'A cross-family Border change requires explicit reset confirmation',
    );
  }
  final request = preview.proposedRequest;
  final result = preview.proposedResult;
  if (request == null || result == null || !result.canApply) {
    return map;
  }
  final target = _currentTargetOrNull(map, preview);
  if (target == null) {
    return map;
  }
  final feature = target.feature;
  if (!_fingerprintMatches(feature, preview.expectedBaseFeatureFingerprint)) {
    return map;
  }
  if (borderGeometryFamily(feature.geometry) != preview.sourceFamily ||
      preview.sourceFamily != preview.targetFamily ||
      request.mapSize != map.size ||
      request.feature.id != feature.id ||
      request.feature.blueprintId != preview.proposedFeature.blueprintId ||
      request.feature.seed != feature.seed ||
      request.feature.geometry != feature.geometry ||
      request.feature.lineSide != feature.lineSide ||
      request.feature.paramsOverride != feature.paramsOverride ||
      !_listEquals(request.feature.overrides, feature.overrides) ||
      !_listEquals(request.feature.keepOutRegions, feature.keepOutRegions)) {
    return map;
  }
  final canonicalValidation = validateBorderResolutionResultForRequest(
    request: request,
    proposedResult: result,
  );
  if (canonicalValidation.hasErrors) {
    throw const ValidationException(
      'Border relink preview result does not match canonical resolution',
    );
  }

  return _replaceFeature(
    map,
    layerIndex: target.layerIndex,
    featureIndex: target.featureIndex,
    layer: target.layer,
    feature: BorderFeature(
      id: feature.id,
      name: feature.name,
      blueprintId: request.blueprintId,
      seed: feature.seed,
      geometry: feature.geometry,
      lineSide: feature.lineSide,
      paramsOverride: feature.paramsOverride,
      overrides: feature.overrides,
      keepOutRegions: feature.keepOutRegions,
      materialization: result.materialization,
    ),
    template: preview.targetTemplate,
  );
}

/// Applies the destructive half of a cross-family blueprint change.
MapData applyBorderFeatureFamilyReset(
  MapData map, {
  required BorderFeatureRelinkPreview preview,
}) {
  if (preview.kind != BorderRelinkKind.requiresFamilyReset) {
    throw StateError('A same-family Border relink must apply its preview');
  }
  final target = _currentTargetOrNull(map, preview);
  if (target == null) {
    return map;
  }
  final feature = target.feature;
  if (!_fingerprintMatches(feature, preview.expectedBaseFeatureFingerprint) ||
      borderGeometryFamily(feature.geometry) != preview.sourceFamily ||
      preview.sourceFamily == preview.targetFamily) {
    return map;
  }
  return _replaceFeature(
    map,
    layerIndex: target.layerIndex,
    featureIndex: target.featureIndex,
    layer: target.layer,
    feature: preview.proposedFeature,
    template: preview.targetTemplate,
  );
}

BorderGeometryFamily borderGeometryFamily(BorderFeatureGeometry geometry) =>
    switch (geometry) {
      BorderRegionGeometry() => BorderGeometryFamily.region,
      BorderStrokeGeometry(:final alignment) =>
        alignment == BorderStrokeAlignment.gridEdges
            ? BorderGeometryFamily.gridEdgeLinear
            : BorderGeometryFamily.linear,
    };

BorderGeometryFamily borderTemplateGeometryFamily(
  BorderBlueprintTemplate template,
) =>
    switch (template) {
      BorderBlueprintTemplate.organicEdge => BorderGeometryFamily.region,
      BorderBlueprintTemplate.masonryLine ||
      BorderBlueprintTemplate.postAndRailLine ||
      BorderBlueprintTemplate.connectedLine =>
        BorderGeometryFamily.linear,
      BorderBlueprintTemplate.stoneChainLine =>
        BorderGeometryFamily.gridEdgeLinear,
    };

BorderFeatureGeometry _emptyGeometryFor(
  BorderGeometryFamily family, {
  required GridSize mapSize,
}) =>
    switch (family) {
      BorderGeometryFamily.region => BorderRegionGeometry(
          width: mapSize.width,
          height: mapSize.height,
          cells: List<bool>.filled(mapSize.width * mapSize.height, false),
        ),
      BorderGeometryFamily.linear =>
        BorderStrokeGeometry(strokes: const <BorderStroke>[]),
      BorderGeometryFamily.gridEdgeLinear => BorderStrokeGeometry(
          strokes: const <BorderStroke>[],
          alignment: BorderStrokeAlignment.gridEdges,
        ),
    };

List<BorderRelinkLoss> _actualResetLosses(BorderFeature feature) =>
    <BorderRelinkLoss>[
      BorderRelinkLoss.geometry,
      if (feature.paramsOverride != null) BorderRelinkLoss.parameters,
      if (feature.overrides.isNotEmpty) BorderRelinkLoss.overrides,
      if (feature.keepOutRegions.isNotEmpty) BorderRelinkLoss.keepOutRegions,
      if (feature.materialization != null) BorderRelinkLoss.materialization,
    ];

({
  int layerIndex,
  int featureIndex,
  BorderLayer layer,
  BorderFeature feature,
})? _currentTargetOrNull(
  MapData map,
  BorderFeatureRelinkPreview preview,
) {
  if (map.id != preview.expectedMapId || map.size != preview.expectedMapSize) {
    return null;
  }
  final layerIndex =
      map.layers.indexWhere((layer) => layer.id == preview.layerId);
  if (layerIndex < 0 || map.layers[layerIndex] is! BorderLayer) {
    return null;
  }
  final layer = map.layers[layerIndex] as BorderLayer;
  final featureIndex = layer.content.features
      .indexWhere((feature) => feature.id == preview.featureId);
  if (featureIndex < 0) {
    return null;
  }
  return (
    layerIndex: layerIndex,
    featureIndex: featureIndex,
    layer: layer,
    feature: layer.content.features[featureIndex],
  );
}

MapData _replaceFeature(
  MapData map, {
  required int layerIndex,
  required int featureIndex,
  required BorderLayer layer,
  required BorderFeature feature,
  BorderBlueprintTemplate? template,
}) {
  final features = List<BorderFeature>.from(layer.content.features);
  features[featureIndex] = feature;
  final layers = List<MapLayer>.from(map.layers);
  var minimumFormatVersion =
      minimumBorderLayerFormatVersionForFeatures(features);
  if (template == BorderBlueprintTemplate.connectedLine &&
      minimumFormatVersion < BorderLayerContent.formatVersionV2) {
    minimumFormatVersion = BorderLayerContent.formatVersionV2;
  }
  if (template == BorderBlueprintTemplate.stoneChainLine &&
      minimumFormatVersion < BorderLayerContent.formatVersionV3) {
    minimumFormatVersion = BorderLayerContent.formatVersionV3;
  }
  layers[layerIndex] = layer.copyWith(
    content: BorderLayerContent(
      formatVersion: _maximumFormatVersion(
        layer.content.formatVersion,
        minimumFormatVersion,
      ),
      features: features,
    ),
  );
  return map.copyWith(layers: layers);
}

BorderLayer _borderLayer(MapData map, String layerId) {
  final layer = map.layers.where((layer) => layer.id == layerId).firstOrNull;
  if (layer is! BorderLayer) {
    throw ValidationException('Border layer not found: $layerId');
  }
  return layer;
}

BorderFeature _feature(BorderLayer layer, String featureId) {
  final feature = layer.content.features
      .where((feature) => feature.id == featureId)
      .firstOrNull;
  if (feature == null) {
    throw ValidationException(
      'Border feature not found in layer ${layer.id}: $featureId',
    );
  }
  return feature;
}

String _stableId(String value, String field) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw ValidationException('$field must be nonblank and already trimmed');
  }
  return value;
}

bool _fingerprintMatches(BorderFeature feature, String expected) {
  try {
    return computeBorderFeatureEditFingerprint(feature) == expected;
  } on FormatException {
    return false;
  } on ValidationException {
    return false;
  }
}

bool _listEquals<T>(List<T> first, List<T> second) {
  if (identical(first, second)) {
    return true;
  }
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}

int _maximumFormatVersion(int first, int second) =>
    first > second ? first : second;
