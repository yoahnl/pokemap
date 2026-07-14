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

/// Complete persisted state shown on one side of a blueprint-change preview.
final class BorderBlueprintFeaturePreviewState {
  const BorderBlueprintFeaturePreviewState({
    required this.feature,
    required this.blueprintName,
    required this.template,
  });

  final BorderFeature feature;
  final String blueprintName;
  final BorderBlueprintTemplate? template;

  bool get isMaterialized => feature.materialization != null;
}

/// Read-only proposal required before changing a feature blueprint.
///
/// The proposal never mutates the map. Applying it is a separate explicit
/// command. Both sides contain complete [BorderFeature] states so presentation
/// can describe geometry and materialization without pretending an ID swap is
/// a resolved visual preview.
final class BorderBlueprintChangePreview {
  const BorderBlueprintChangePreview._({
    required this.layerId,
    required this.featureId,
    required this.before,
    required this.after,
    required this.canApply,
    required this.canReset,
    required this.canCreateNewFeature,
    required this.consequence,
    required this.blockedReason,
  });

  final String layerId;
  final String featureId;
  final BorderBlueprintFeaturePreviewState before;
  final BorderBlueprintFeaturePreviewState after;
  final bool canApply;
  final bool canReset;
  final bool canCreateNewFeature;
  final String consequence;
  final String? blockedReason;

  String get beforeBlueprintId => before.feature.blueprintId;
  String get afterBlueprintId => after.feature.blueprintId;
  String get afterBlueprintName => after.blueprintName;
  BorderBlueprintTemplate? get afterTemplate => after.template;
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

  BorderBlueprintChangePreview previewBlueprintChange({
    required MapData map,
    required String layerId,
    required String featureId,
    required BorderBlueprintRecord? sourceBlueprint,
    required BorderBlueprintRecord targetBlueprint,
  }) {
    final feature = _feature(_borderLayer(map, layerId), featureId);
    final published = targetBlueprint.latestPublished;
    final targetDefinition =
        published?.definition ?? targetBlueprint.draft.definition;
    final template = targetDefinition.template;
    final sourceDefinition = sourceBlueprint?.id == feature.blueprintId
        ? sourceBlueprint?.latestPublished?.definition ??
            sourceBlueprint?.draft.definition
        : null;
    final sourceIsRegion = feature.geometry is BorderRegionGeometry;
    final targetIsRegion = template == BorderBlueprintTemplate.organicEdge;
    final changesFamily = sourceIsRegion != targetIsRegion;
    final sameBlueprint = targetBlueprint.id == feature.blueprintId;
    final targetIsUsable = published != null && !targetBlueprint.isDeprecated;
    final afterFeature = sameBlueprint
        ? feature
        : changesFamily
            ? _resetFeatureForTemplate(
                feature,
                blueprintId: targetBlueprint.id,
                template: template,
                mapSize: map.size,
              )
            : _relinkFeature(
                feature,
                blueprintId: targetBlueprint.id,
              );

    String? blockedReason;
    if (published == null) {
      blockedReason = 'Le blueprint cible doit être publié.';
    } else if (targetBlueprint.isDeprecated) {
      blockedReason = 'Le blueprint cible est obsolète.';
    } else if (sameBlueprint) {
      blockedReason = 'Cette bordure utilise déjà ce blueprint.';
    } else if (sourceIsRegion && !targetIsRegion) {
      blockedReason = 'Le passage d’une géométrie région à une géométrie ligne '
          'exige de créer une nouvelle feature ou de confirmer la remise à zéro.';
    } else if (!sourceIsRegion && targetIsRegion) {
      blockedReason = 'Le passage d’une géométrie ligne à une géométrie région '
          'exige de créer une nouvelle feature ou de confirmer la remise à zéro.';
    } else if (template != BorderBlueprintTemplate.organicEdge) {
      blockedReason =
          'Le changement entre blueprints linéaires sera activé avec BORD-06.';
    }

    final consequence = sameBlueprint
        ? 'Aucune modification ne sera appliquée.'
        : changesFamily
            ? 'La remise à zéro supprime la géométrie actuelle, les paramètres '
                'personnalisés, les corrections locales, les zones d’exclusion '
                'et la matérialisation. Une géométrie vide adaptée au nouveau '
                'template sera créée.'
            : 'La géométrie, les paramètres, les corrections locales et les '
                'zones d’exclusion sont conservés. L’ancienne matérialisation '
                'est supprimée et devra être régénérée avant le runtime.';

    return BorderBlueprintChangePreview._(
      layerId: layerId,
      featureId: featureId,
      before: BorderBlueprintFeaturePreviewState(
        feature: feature,
        blueprintName: sourceDefinition?.name ?? feature.blueprintId,
        template: sourceDefinition?.template,
      ),
      after: BorderBlueprintFeaturePreviewState(
        feature: afterFeature,
        blueprintName: targetDefinition.name,
        template: template,
      ),
      canApply: targetIsUsable &&
          !sameBlueprint &&
          !changesFamily &&
          template == BorderBlueprintTemplate.organicEdge,
      canReset: targetIsUsable && !sameBlueprint && changesFamily,
      canCreateNewFeature: targetIsUsable && !sameBlueprint,
      consequence: consequence,
      blockedReason: blockedReason,
    );
  }

  MapData applyBlueprintChange({
    required MapData map,
    required BorderBlueprintChangePreview preview,
  }) {
    if (!preview.canApply) {
      throw StateError(
        preview.blockedReason ?? 'The Border blueprint change is blocked',
      );
    }
    _assertPreviewIsCurrent(map, preview);
    return upsertBorderFeature(
      map,
      layerId: preview.layerId,
      feature: preview.after.feature,
    );
  }

  MapData resetFeatureForBlueprintChange({
    required MapData map,
    required BorderBlueprintChangePreview preview,
  }) {
    if (!preview.canReset) {
      throw StateError(
        preview.blockedReason ?? 'The Border blueprint reset is unavailable',
      );
    }
    _assertPreviewIsCurrent(map, preview);
    return upsertBorderFeature(
      map,
      layerId: preview.layerId,
      feature: preview.after.feature,
    );
  }

  BorderFeatureCreationResult createFeatureFromBlueprintChange({
    required MapData map,
    required BorderBlueprintChangePreview preview,
    required BorderBlueprintRecord targetBlueprint,
    required String name,
  }) {
    if (!preview.canCreateNewFeature ||
        targetBlueprint.id != preview.afterBlueprintId) {
      throw StateError(
        preview.blockedReason ??
            'The Border blueprint cannot create a separate feature',
      );
    }
    _assertPreviewIsCurrent(map, preview);
    return createFeature(
      map: map,
      layerId: preview.layerId,
      blueprint: targetBlueprint,
      name: name,
    );
  }
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

BorderFeature _copyFeature(
  BorderFeature feature, {
  String? name,
  String? blueprintId,
}) =>
    BorderFeature(
      id: feature.id,
      name: name ?? feature.name,
      blueprintId: blueprintId ?? feature.blueprintId,
      seed: feature.seed,
      geometry: feature.geometry,
      paramsOverride: feature.paramsOverride,
      overrides: feature.overrides,
      keepOutRegions: feature.keepOutRegions,
      materialization: feature.materialization,
    );

BorderFeature _relinkFeature(
  BorderFeature feature, {
  required String blueprintId,
}) =>
    BorderFeature(
      id: feature.id,
      name: feature.name,
      blueprintId: blueprintId,
      seed: feature.seed,
      geometry: feature.geometry,
      paramsOverride: feature.paramsOverride,
      overrides: feature.overrides,
      keepOutRegions: feature.keepOutRegions,
      materialization: null,
    );

BorderFeature _resetFeatureForTemplate(
  BorderFeature feature, {
  required String blueprintId,
  required BorderBlueprintTemplate template,
  required GridSize mapSize,
}) =>
    BorderFeature(
      id: feature.id,
      name: feature.name,
      blueprintId: blueprintId,
      seed: feature.seed,
      geometry: switch (template) {
        BorderBlueprintTemplate.organicEdge => BorderRegionGeometry(
            width: mapSize.width,
            height: mapSize.height,
            cells: List<bool>.filled(mapSize.width * mapSize.height, false),
          ),
        BorderBlueprintTemplate.masonryLine ||
        BorderBlueprintTemplate.postAndRailLine =>
          BorderStrokeGeometry(strokes: const <BorderStroke>[]),
      },
      paramsOverride: null,
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
      materialization: null,
    );

void _assertPreviewIsCurrent(
  MapData map,
  BorderBlueprintChangePreview preview,
) {
  final feature = _feature(
    _borderLayer(map, preview.layerId),
    preview.featureId,
  );
  if (feature != preview.before.feature) {
    throw StateError(
      'The Border feature changed after the blueprint preview was created',
    );
  }
}
