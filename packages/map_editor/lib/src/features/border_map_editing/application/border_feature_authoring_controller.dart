import 'package:map_core/map_core.dart';

/// Result of creating a persisted Border feature in one map layer.
final class BorderFeatureCreationResult {
  const BorderFeatureCreationResult({
    required this.map,
    required this.feature,
  });

  final MapData map;
  final BorderFeature feature;
}

/// Small, UI-independent authoring façade for Border feature list actions.
///
/// This controller changes Border content only. In particular, it never reads
/// or rewrites collision-layer content.
final class BorderFeatureAuthoringController {
  const BorderFeatureAuthoringController();

  BorderFeatureCreationResult createFeature({
    required MapData map,
    required String layerId,
    required BorderBlueprintRecord blueprint,
    required String name,
  }) {
    final published = blueprint.latestPublished;
    if (published == null || blueprint.isDeprecated) {
      throw StateError(
        'A new Border feature requires a non-deprecated published blueprint',
      );
    }

    final layer = _borderLayer(map, layerId);
    final id = _nextFeatureId(layer.content.features);
    final feature = BorderFeature(
      id: id,
      name: name,
      blueprintId: blueprint.id,
      seed: _seedFor(
        mapId: map.id,
        layerId: layer.id,
        featureId: id,
        blueprintId: blueprint.id,
        revision: published.revision,
      ),
      geometry: switch (published.definition.template) {
        BorderBlueprintTemplate.organicEdge => BorderRegionGeometry(
            width: map.size.width,
            height: map.size.height,
            cells: List<bool>.filled(
              map.size.width * map.size.height,
              false,
            ),
          ),
        BorderBlueprintTemplate.masonryLine ||
        BorderBlueprintTemplate.postAndRailLine =>
          BorderStrokeGeometry(strokes: const <BorderStroke>[]),
      },
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    );

    return BorderFeatureCreationResult(
      map: upsertBorderFeature(map, layerId: layer.id, feature: feature),
      feature: feature,
    );
  }

  MapData renameFeature({
    required MapData map,
    required String layerId,
    required String featureId,
    required String name,
  }) {
    final feature = _feature(_borderLayer(map, layerId), featureId);
    return upsertBorderFeature(
      map,
      layerId: layerId,
      feature: _copyFeature(feature, name: name),
    );
  }

  MapData reorderFeature({
    required MapData map,
    required String layerId,
    required String featureId,
    required int newIndex,
  }) =>
      reorderBorderFeature(
        map,
        layerId: layerId,
        featureId: featureId,
        newIndex: newIndex,
      );

  MapData deleteFeature({
    required MapData map,
    required String layerId,
    required String featureId,
  }) =>
      removeBorderFeature(
        map,
        layerId: layerId,
        featureId: featureId,
      );
}

BorderLayer _borderLayer(MapData map, String layerId) {
  final layer = map.layers.where((layer) => layer.id == layerId).firstOrNull;
  if (layer is! BorderLayer) {
    throw StateError('Border layer not found: $layerId');
  }
  return layer;
}

BorderFeature _feature(BorderLayer layer, String featureId) {
  final feature = layer.content.features
      .where((feature) => feature.id == featureId)
      .firstOrNull;
  if (feature == null) {
    throw StateError(
      'Border feature not found in layer ${layer.id}: $featureId',
    );
  }
  return feature;
}

String _nextFeatureId(List<BorderFeature> features) {
  const base = 'border_feature';
  final used = <String>{for (final feature in features) feature.id};
  if (!used.contains(base)) {
    return base;
  }
  for (var suffix = 2;; suffix += 1) {
    final candidate = '${base}_$suffix';
    if (!used.contains(candidate)) {
      return candidate;
    }
  }
}

BorderSignedInt64 _seedFor({
  required String mapId,
  required String layerId,
  required String featureId,
  required String blueprintId,
  required int revision,
}) {
  final unsigned = BorderDeterministicRng.fromComponents(
    <BorderRngKeyComponent>[
      const BorderRngKeyComponent.text('border-feature-seed-v1'),
      BorderRngKeyComponent.text(mapId),
      BorderRngKeyComponent.text(layerId),
      BorderRngKeyComponent.text(featureId),
      BorderRngKeyComponent.text(blueprintId),
      BorderRngKeyComponent.text(revision.toString()),
    ],
  ).nextUint64();
  final signed =
      unsigned >= (BigInt.one << 63) ? unsigned - (BigInt.one << 64) : unsigned;
  return BorderSignedInt64(signed);
}

BorderFeature _copyFeature(BorderFeature feature, {required String name}) =>
    BorderFeature(
      id: feature.id,
      name: name,
      blueprintId: feature.blueprintId,
      seed: feature.seed,
      geometry: feature.geometry,
      paramsOverride: feature.paramsOverride,
      overrides: feature.overrides,
      keepOutRegions: feature.keepOutRegions,
      materialization: feature.materialization,
    );
