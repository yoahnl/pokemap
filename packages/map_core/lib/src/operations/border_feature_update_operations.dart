import '../exceptions/map_exceptions.dart';
import '../models/border_feature.dart';
import '../models/border_geometry.dart';
import '../models/border_layer.dart';
import '../models/border_materialization.dart';
import '../models/border_resolution.dart';
import '../models/border_signed_int64.dart';
import '../models/border_value_objects.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import 'border_feature_json_codec.dart';
import 'border_fingerprints.dart';
import 'border_resolver.dart';
import 'narrative_event_canonical_json.dart';

/// Replaces only the authored geometry of one Border feature.
MapData updateBorderFeatureGeometry(
  MapData map, {
  required String layerId,
  required String featureId,
  required BorderFeatureGeometry geometry,
}) =>
    _updateBorderFeature(
      map,
      layerId: layerId,
      featureId: featureId,
      update: (feature) => _copyFeature(feature, geometry: geometry),
    );

/// Replaces only the deterministic seed of one Border feature.
MapData updateBorderFeatureSeed(
  MapData map, {
  required String layerId,
  required String featureId,
  required BorderSignedInt64 seed,
}) =>
    _updateBorderFeature(
      map,
      layerId: layerId,
      featureId: featureId,
      update: (feature) => _copyFeature(feature, seed: seed),
    );

/// Replaces only the authored slot overrides of one Border feature.
MapData updateBorderFeatureOverrides(
  MapData map, {
  required String layerId,
  required String featureId,
  required List<BorderSlotOverride> overrides,
}) =>
    _updateBorderFeature(
      map,
      layerId: layerId,
      featureId: featureId,
      update: (feature) => _copyFeature(feature, overrides: overrides),
    );

/// Replaces the authored parameter override, including explicitly clearing it.
MapData updateBorderFeatureParameters(
  MapData map, {
  required String layerId,
  required String featureId,
  required BorderGenerationParams? paramsOverride,
}) =>
    _updateBorderFeature(
      map,
      layerId: layerId,
      featureId: featureId,
      update: (feature) => BorderFeature(
        id: feature.id,
        name: feature.name,
        blueprintId: feature.blueprintId,
        seed: feature.seed,
        geometry: feature.geometry,
        paramsOverride: paramsOverride,
        overrides: feature.overrides,
        keepOutRegions: feature.keepOutRegions,
        materialization: feature.materialization,
      ),
    );

/// Replaces only the authored stable keep-out regions of one Border feature.
MapData updateBorderFeatureKeepOutRegions(
  MapData map, {
  required String layerId,
  required String featureId,
  required List<BorderKeepOutRegion> keepOutRegions,
}) =>
    _updateBorderFeature(
      map,
      layerId: layerId,
      featureId: featureId,
      update: (feature) => BorderFeature(
        id: feature.id,
        name: feature.name,
        blueprintId: feature.blueprintId,
        seed: feature.seed,
        geometry: feature.geometry,
        paramsOverride: feature.paramsOverride,
        overrides: feature.overrides,
        keepOutRegions: keepOutRegions,
        materialization: feature.materialization,
      ),
    );

/// Fingerprint used for optimistic Border preview application.
///
/// Unlike resolution input fingerprints, this deliberately covers the whole
/// persisted feature, including its last materialization.
String computeBorderFeatureEditFingerprint(BorderFeature feature) {
  final encodedFeature = encodeBorderFeatureJson(feature);
  _validatePortableFingerprintJson(encodedFeature, path: r'$.feature');
  return 'sha256:${narrativeEventCanonicalSha256(<String, Object?>{
        'schema': 'border-feature-edit-v1',
        'feature': encodedFeature,
      })}';
}

/// Atomically applies a coherent Border preview to one unchanged base feature.
///
/// Expected-state conflicts are identity-preserving no-ops. A successful
/// result whose receipt does not exactly describe [proposedRequest] and its
/// output is programmer/data corruption and therefore throws.
MapData applyBorderFeaturePreview(
  MapData map, {
  required String expectedMapId,
  required String layerId,
  required String featureId,
  required String expectedBaseFeatureFingerprint,
  required BorderResolutionRequest proposedRequest,
  required BorderResolutionResult proposedResult,
}) {
  if (!proposedResult.canApply) {
    return map;
  }
  if (map.id != expectedMapId || map.size != proposedRequest.mapSize) {
    return map;
  }

  final layerIndex = map.layers.indexWhere((layer) => layer.id == layerId);
  if (layerIndex < 0 || map.layers[layerIndex] is! BorderLayer) {
    return map;
  }
  final layer = map.layers[layerIndex] as BorderLayer;
  final featureIndex = layer.content.features.indexWhere(
    (feature) => feature.id == featureId,
  );
  if (featureIndex < 0 ||
      proposedRequest.feature.id != featureId ||
      proposedRequest.blueprintId !=
          layer.content.features[featureIndex].blueprintId ||
      proposedRequest.feature.blueprintId !=
          layer.content.features[featureIndex].blueprintId) {
    return map;
  }

  final currentFeature = layer.content.features[featureIndex];
  String currentFeatureFingerprint;
  try {
    currentFeatureFingerprint =
        computeBorderFeatureEditFingerprint(currentFeature);
  } on FormatException {
    return map;
  } on ValidationException {
    // An unhashable persisted base cannot satisfy optimistic concurrency.
    // Treat it like every other expected-state conflict instead of leaking a
    // canonicalization failure through the normal preview-apply workflow.
    return map;
  }
  if (currentFeatureFingerprint != expectedBaseFeatureFingerprint) {
    return map;
  }

  final materialization = proposedResult.materialization!;
  _validatePreviewResult(proposedRequest, proposedResult);

  final updatedFeature = BorderFeature(
    id: currentFeature.id,
    name: currentFeature.name,
    blueprintId: currentFeature.blueprintId,
    seed: proposedRequest.feature.seed,
    geometry: proposedRequest.feature.geometry,
    paramsOverride: proposedRequest.feature.paramsOverride,
    overrides: proposedRequest.feature.overrides,
    keepOutRegions: proposedRequest.feature.keepOutRegions,
    materialization: materialization,
  );
  final features = List<BorderFeature>.from(layer.content.features);
  features[featureIndex] = updatedFeature;
  final layers = List<MapLayer>.from(map.layers);
  layers[layerIndex] = layer.copyWith(
    content: BorderLayerContent(
      formatVersion: layer.content.formatVersion,
      features: features,
    ),
  );
  return map.copyWith(layers: layers);
}

final BigInt _maximumPortableJsonInteger = BigInt.parse('9007199254740991');

void _validatePortableFingerprintJson(
  Object? value, {
  required String path,
}) {
  switch (value) {
    case int value:
      if (BigInt.from(value).abs() > _maximumPortableJsonInteger) {
        throw ValidationException(
          '$path must be within the portable I-JSON integer range',
        );
      }
    case List<Object?> values:
      for (var index = 0; index < values.length; index += 1) {
        _validatePortableFingerprintJson(
          values[index],
          path: '$path[$index]',
        );
      }
    case Map<String, Object?> values:
      for (final entry in values.entries) {
        _validatePortableFingerprintJson(
          entry.value,
          path: '$path.${entry.key}',
        );
      }
    default:
      break;
  }
}

void _validatePreviewResult(
  BorderResolutionRequest request,
  BorderResolutionResult proposedResult,
) {
  final canonicalValidation = validateBorderResolutionResultForRequest(
    request: request,
    proposedResult: proposedResult,
  );
  if (canonicalValidation.hasErrors) {
    throw const ValidationException(
      'Border preview result does not match canonical resolution',
    );
  }
  final materialization = proposedResult.materialization!;
  final revision = request.blueprintRevision;
  if (revision == null) {
    throw const ValidationException(
      'A successful Border preview requires a published blueprint revision',
    );
  }
  final receipt = materialization.receipt;
  final expectedComponents = computeBorderInputFingerprints(request);
  final expectedInput = computeBorderAggregateInputFingerprint(
    resolverVersion: request.resolverVersion,
    blueprintRevision: revision.revision,
    components: expectedComponents,
  );
  final expectedOutput = computeBorderOutputFingerprint(
    ground: materialization.ground,
    placements: materialization.placements,
  );
  if (receipt.resolverVersion != request.resolverVersion ||
      receipt.blueprintRevision != revision.revision ||
      receipt.components != expectedComponents ||
      receipt.inputFingerprint != expectedInput ||
      receipt.outputFingerprint != expectedOutput) {
    throw const ValidationException(
      'Border preview result receipt does not match its resolution request',
    );
  }
  if (!_previewOutputStructureIsValid(request, materialization)) {
    throw const ValidationException(
      'Border preview result output structure is invalid for its map context',
    );
  }
  final availableSnapshotIds = <String>{
    for (final snapshot in request.visualSnapshots) snapshot.id,
  };
  if (materialization.ground.any(
        (cell) => !availableSnapshotIds.contains(cell.visualSnapshotId),
      ) ||
      materialization.placements.any(
        (placement) =>
            !availableSnapshotIds.contains(placement.visualSnapshotId),
      )) {
    throw const ValidationException(
      'Border preview result references an unavailable visual snapshot',
    );
  }
}

bool _previewOutputStructureIsValid(
  BorderResolutionRequest request,
  BorderMaterialization materialization,
) {
  for (final cell in materialization.ground) {
    if (!_previewCellIsInsideMap(
      cell.x,
      cell.y,
      request.mapSize.width,
      request.mapSize.height,
    )) {
      return false;
    }
  }
  final canvasWidth = BigInt.from(request.mapSize.width) *
      BigInt.from(request.tileSizePx.width);
  final canvasHeight = BigInt.from(request.mapSize.height) *
      BigInt.from(request.tileSizePx.height);
  for (final placement in materialization.placements) {
    if (!_previewCellIsInsideMap(
          placement.anchorCell.x,
          placement.anchorCell.y,
          request.mapSize.width,
          request.mapSize.height,
        ) ||
        BigInt.from(placement.stableOrderKey.anchorRowMajor) !=
            BigInt.from(placement.anchorCell.y) *
                    BigInt.from(request.mapSize.width) +
                BigInt.from(placement.anchorCell.x) ||
        !_previewRectIntersectsCanvas(
          placement.opaqueWorldBoundsPx.x,
          placement.opaqueWorldBoundsPx.y,
          placement.opaqueWorldBoundsPx.width,
          placement.opaqueWorldBoundsPx.height,
          canvasWidth,
          canvasHeight,
        )) {
      return false;
    }
  }
  return true;
}

bool _previewCellIsInsideMap(int x, int y, int width, int height) =>
    x >= 0 && y >= 0 && x < width && y < height;

bool _previewRectIntersectsCanvas(
  int x,
  int y,
  int width,
  int height,
  BigInt canvasWidth,
  BigInt canvasHeight,
) {
  final left = BigInt.from(x);
  final top = BigInt.from(y);
  return left < canvasWidth &&
      top < canvasHeight &&
      left + BigInt.from(width) > BigInt.zero &&
      top + BigInt.from(height) > BigInt.zero;
}

MapData _updateBorderFeature(
  MapData map, {
  required String layerId,
  required String featureId,
  required BorderFeature Function(BorderFeature feature) update,
}) {
  final normalizedLayerId = layerId.trim();
  final normalizedFeatureId = featureId.trim();
  if (normalizedLayerId.isEmpty || normalizedFeatureId.isEmpty) {
    throw const ValidationException(
      'Border layer and feature IDs must be non-empty',
    );
  }
  final layerIndex = map.layers.indexWhere(
    (layer) => layer.id == normalizedLayerId,
  );
  if (layerIndex < 0) {
    throw ValidationException('Layer not found: $normalizedLayerId');
  }
  final layer = map.layers[layerIndex];
  if (layer is! BorderLayer) {
    throw ValidationException(
      'Layer is not a border layer: $normalizedLayerId',
    );
  }
  final featureIndex = layer.content.features.indexWhere(
    (feature) => feature.id == normalizedFeatureId,
  );
  if (featureIndex < 0) {
    throw ValidationException(
      'Border feature not found in layer $normalizedLayerId: '
      '$normalizedFeatureId',
    );
  }

  final features = List<BorderFeature>.from(layer.content.features);
  features[featureIndex] = update(features[featureIndex]);
  final layers = List<MapLayer>.from(map.layers);
  layers[layerIndex] = layer.copyWith(
    content: BorderLayerContent(
      formatVersion: layer.content.formatVersion,
      features: features,
    ),
  );
  return map.copyWith(layers: layers);
}

BorderFeature _copyFeature(
  BorderFeature feature, {
  BorderSignedInt64? seed,
  BorderFeatureGeometry? geometry,
  List<BorderSlotOverride>? overrides,
}) =>
    BorderFeature(
      id: feature.id,
      name: feature.name,
      blueprintId: feature.blueprintId,
      seed: seed ?? feature.seed,
      geometry: geometry ?? feature.geometry,
      paramsOverride: feature.paramsOverride,
      overrides: overrides ?? feature.overrides,
      keepOutRegions: feature.keepOutRegions,
      materialization: feature.materialization,
    );
