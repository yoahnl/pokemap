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
/// can describe geometry and the canonical resolved target materialization.
final class BorderBlueprintChangePreview {
  const BorderBlueprintChangePreview._({
    required this.mapIdentity,
    required this.layerId,
    required this.featureId,
    required this.before,
    required this.after,
    required this.relink,
    required this.targetRevision,
    required this.canApply,
    required this.canReset,
    required this.canCreateNewFeature,
    required this.consequence,
    required this.blockedReason,
  });

  /// Exact editor document that owned the proposal before an async confirm.
  final MapData mapIdentity;
  final String layerId;
  final String featureId;
  final BorderBlueprintFeaturePreviewState before;
  final BorderBlueprintFeaturePreviewState after;
  final BorderFeatureRelinkPreview relink;
  final BorderBlueprintRevision targetRevision;
  final bool canApply;
  final bool canReset;
  final bool canCreateNewFeature;
  final String consequence;
  final String? blockedReason;

  String get beforeBlueprintId => before.feature.blueprintId;
  String get afterBlueprintId => after.feature.blueprintId;
  String get afterBlueprintName => after.blueprintName;
  BorderBlueprintTemplate? get afterTemplate => after.template;
  List<BorderRelinkLoss> get losses => relink.losses;
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
        BorderBlueprintTemplate.postAndRailLine ||
        BorderBlueprintTemplate.connectedLine =>
          BorderStrokeGeometry(strokes: const <BorderStroke>[]),
      },
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    );

    return BorderFeatureCreationResult(
      map: upsertBorderFeature(
        map,
        layerId: layer.id,
        feature: feature,
        template: published.definition.template,
      ),
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

  /// Changes only one slot's deterministic variation in a transient draft.
  BorderFeature previewLocalVariation({
    required BorderFeature feature,
    required String slotKey,
  }) {
    final current = _overrideFor(feature, slotKey);
    return _draftWithOverride(
      feature,
      BorderSlotOverride(
        slotKey: slotKey,
        variationSalt: _nextLocalVariationSalt(
          feature: feature,
          slotKey: slotKey,
          current: current?.variationSalt ?? BorderSignedInt64.zero,
        ),
        suppressed: false,
        locked: false,
        replacementPrimitiveId: current?.replacementPrimitiveId,
        offsetDeltaPx: current?.offsetDeltaPx,
        transformOverride: current?.transformOverride,
      ),
    );
  }

  /// Selects one published primitive for a slot in a transient draft.
  BorderFeature previewReplacement({
    required BorderFeature feature,
    required String slotKey,
    required String primitiveId,
  }) {
    final current = _overrideFor(feature, slotKey);
    return _draftWithOverride(
      feature,
      BorderSlotOverride(
        slotKey: slotKey,
        variationSalt: current?.variationSalt ?? BorderSignedInt64.zero,
        suppressed: false,
        locked: false,
        replacementPrimitiveId: primitiveId,
        offsetDeltaPx: current?.offsetDeltaPx,
        transformOverride: current?.transformOverride,
      ),
    );
  }

  /// Moves one generated slot by an integer pixel delta in a transient draft.
  BorderFeature previewMove({
    required BorderFeature feature,
    required String slotKey,
    required BorderPixelOffset offset,
  }) {
    final current = _overrideFor(feature, slotKey);
    return _draftWithOverride(
      feature,
      BorderSlotOverride(
        slotKey: slotKey,
        variationSalt: current?.variationSalt ?? BorderSignedInt64.zero,
        suppressed: false,
        locked: false,
        replacementPrimitiveId: current?.replacementPrimitiveId,
        offsetDeltaPx: offset,
        transformOverride: current?.transformOverride,
      ),
    );
  }

  /// Suppresses one generated slot and clears incompatible correction fields.
  BorderFeature previewRemoval({
    required BorderFeature feature,
    required String slotKey,
  }) =>
      _draftWithOverride(
        feature,
        BorderSlotOverride(
          slotKey: slotKey,
          variationSalt: BorderSignedInt64.zero,
          suppressed: true,
          locked: false,
        ),
      );

  /// Captures one exact resolved placement as the slot's locked output.
  BorderFeature previewLock({
    required BorderFeature feature,
    required BorderResolvedPlacement placement,
  }) =>
      _draftWithOverride(
        feature,
        BorderSlotOverride(
          slotKey: placement.slotKey,
          variationSalt: BorderSignedInt64.zero,
          suppressed: false,
          locked: true,
          lockedPlacement: placement,
        ),
      );

  /// Adds a compact square keep-out mask around one selected slot.
  BorderFeature previewKeepOut({
    required BorderFeature feature,
    required BorderResolvedPlacement placement,
    required GridSize mapSize,
    required int radiusCells,
  }) {
    if (radiusCells < 0 || radiusCells > 2) {
      throw ArgumentError.value(
        radiusCells,
        'radiusCells',
        'must be between 0 and 2',
      );
    }
    final cells = List<bool>.filled(mapSize.width * mapSize.height, false);
    for (var y = placement.anchorCell.y - radiusCells;
        y <= placement.anchorCell.y + radiusCells;
        y += 1) {
      if (y < 0 || y >= mapSize.height) continue;
      for (var x = placement.anchorCell.x - radiusCells;
          x <= placement.anchorCell.x + radiusCells;
          x += 1) {
        if (x < 0 || x >= mapSize.width) continue;
        cells[y * mapSize.width + x] = true;
      }
    }
    return BorderFeature(
      id: feature.id,
      name: feature.name,
      blueprintId: feature.blueprintId,
      seed: feature.seed,
      geometry: feature.geometry,
      lineSide: feature.lineSide,
      paramsOverride: feature.paramsOverride,
      overrides: feature.overrides,
      keepOutRegions: <BorderKeepOutRegion>[
        ...feature.keepOutRegions,
        BorderKeepOutRegion(
          id: _nextKeepOutId(feature.keepOutRegions),
          region: BorderRegionGeometry(
            width: mapSize.width,
            height: mapSize.height,
            cells: cells,
          ),
        ),
      ],
      materialization: null,
    );
  }

  /// Toggles the asymmetric side as a transient feature draft.
  ///
  /// The core operation preserves authored intent and discards only the old
  /// materialization. World Maps must still resolve and Apply this draft
  /// through its shared preview transaction.
  BorderFeature previewLineSideToggle(BorderFeature feature) =>
      toggleBorderFeatureLineSide(feature);

  BorderBlueprintChangePreview previewBlueprintChange({
    required MapData map,
    required String layerId,
    required String featureId,
    required BorderBlueprintRecord? sourceBlueprint,
    required BorderBlueprintRecord targetBlueprint,
    required Iterable<BorderVisualSnapshot> visualSnapshots,
    required GridSize tileSizePx,
    int resolverVersion = borderResolverVersion,
  }) {
    final feature = _feature(_borderLayer(map, layerId), featureId);
    final published = targetBlueprint.latestPublished;
    if (published == null) {
      throw StateError('Le blueprint cible doit être publié.');
    }
    if (targetBlueprint.isDeprecated) {
      throw StateError('Le blueprint cible est obsolète.');
    }
    if (targetBlueprint.id == feature.blueprintId) {
      throw StateError('Cette bordure utilise déjà ce blueprint.');
    }
    final targetDefinition = published.definition;
    final template = targetDefinition.template;
    final sourceDefinition = sourceBlueprint?.id == feature.blueprintId
        ? sourceBlueprint?.latestPublished?.definition ??
            sourceBlueprint?.draft.definition
        : null;
    final relink = prepareBorderFeatureRelink(
      map: map,
      layerId: layerId,
      featureId: featureId,
      targetBlueprintId: targetBlueprint.id,
      targetBlueprintRevision: published,
      visualSnapshots: visualSnapshots,
      tileSizePx: tileSizePx,
      resolverVersion: resolverVersion,
    );
    final resolvedMaterialization = relink.proposedResult?.materialization;
    final afterFeature = resolvedMaterialization == null
        ? relink.proposedFeature
        : _copyFeatureWithMaterialization(
            relink.proposedFeature,
            resolvedMaterialization,
          );
    final changesFamily = relink.kind == BorderRelinkKind.requiresFamilyReset;
    final blockedReason = changesFamily
        ? 'Le passage d’une géométrie ${_familyLabel(relink.sourceFamily)} à '
            'une géométrie ${_familyLabel(relink.targetFamily)} exige de créer '
            'une nouvelle feature ou de confirmer la remise à zéro.'
        : relink.canApplyResolvedRelink
            ? null
            : 'Le nouvel aperçu résolu contient des diagnostics à corriger '
                'avant de pouvoir être appliqué.';
    final consequence = changesFamily
        ? 'La remise à zéro perd exactement : '
            '${relink.losses.map(_lossLabel).join(', ')}.'
        : relink.canApplyResolvedRelink
            ? 'Un aperçu résolu est prêt. La géométrie, les paramètres, les '
                'corrections locales et les zones d’exclusion sont conservés ; '
                'la nouvelle matérialisation sera remplacée atomiquement à '
                'l’application.'
            : 'La carte et sa matérialisation actuelle restent inchangées tant '
                'que l’aperçu résolu n’est pas valide.';

    return BorderBlueprintChangePreview._(
      mapIdentity: map,
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
      relink: relink,
      targetRevision: published,
      canApply: relink.canApplyResolvedRelink,
      canReset: changesFamily,
      canCreateNewFeature: true,
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
    return applyBorderFeatureRelinkPreview(
      map,
      preview: preview.relink,
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
    return applyBorderFeatureFamilyReset(
      map,
      preview: preview.relink,
    );
  }

  BorderFeatureCreationResult createFeatureFromBlueprintChange({
    required MapData map,
    required BorderBlueprintChangePreview preview,
    required BorderBlueprintRecord targetBlueprint,
    required String name,
  }) {
    if (!preview.canCreateNewFeature ||
        targetBlueprint.id != preview.afterBlueprintId ||
        targetBlueprint.latestPublished != preview.targetRevision ||
        targetBlueprint.isDeprecated) {
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
      lineSide: feature.lineSide,
      paramsOverride: feature.paramsOverride,
      overrides: feature.overrides,
      keepOutRegions: feature.keepOutRegions,
      materialization: feature.materialization,
    );

BorderSlotOverride? _overrideFor(BorderFeature feature, String slotKey) =>
    feature.overrides
        .where((override) => override.slotKey == slotKey)
        .firstOrNull;

BorderFeature _draftWithOverride(
  BorderFeature feature,
  BorderSlotOverride replacement,
) {
  final overrides = <BorderSlotOverride>[];
  var replaced = false;
  for (final override in feature.overrides) {
    if (override.slotKey == replacement.slotKey) {
      overrides.add(replacement);
      replaced = true;
    } else {
      overrides.add(override);
    }
  }
  if (!replaced) {
    overrides.add(replacement);
  }
  return BorderFeature(
    id: feature.id,
    name: feature.name,
    blueprintId: feature.blueprintId,
    seed: feature.seed,
    geometry: feature.geometry,
    lineSide: feature.lineSide,
    paramsOverride: feature.paramsOverride,
    overrides: overrides,
    keepOutRegions: feature.keepOutRegions,
    materialization: null,
  );
}

BorderSignedInt64 _nextLocalVariationSalt({
  required BorderFeature feature,
  required String slotKey,
  required BorderSignedInt64 current,
}) {
  final unsigned = BorderDeterministicRng.fromComponents(
    <BorderRngKeyComponent>[
      const BorderRngKeyComponent.text('border-local-variation-v1'),
      BorderRngKeyComponent.text(feature.id),
      BorderRngKeyComponent.text(slotKey),
      BorderRngKeyComponent.signedInt64(feature.seed),
      BorderRngKeyComponent.signedInt64(current),
    ],
  ).nextUint64();
  final signed =
      unsigned >= (BigInt.one << 63) ? unsigned - (BigInt.one << 64) : unsigned;
  final next = BorderSignedInt64(signed);
  if (next != current) return next;
  return current == BorderSignedInt64.maximum
      ? BorderSignedInt64.minimum
      : BorderSignedInt64(current.value + BigInt.one);
}

String _nextKeepOutId(List<BorderKeepOutRegion> keepOutRegions) {
  const base = 'border_keep_out';
  final used = <String>{for (final region in keepOutRegions) region.id};
  if (!used.contains(base)) return base;
  for (var suffix = 2;; suffix += 1) {
    final candidate = '${base}_$suffix';
    if (!used.contains(candidate)) return candidate;
  }
}

BorderFeature _copyFeatureWithMaterialization(
  BorderFeature feature,
  BorderMaterialization materialization,
) =>
    BorderFeature(
      id: feature.id,
      name: feature.name,
      blueprintId: feature.blueprintId,
      seed: feature.seed,
      geometry: feature.geometry,
      lineSide: feature.lineSide,
      paramsOverride: feature.paramsOverride,
      overrides: feature.overrides,
      keepOutRegions: feature.keepOutRegions,
      materialization: materialization,
    );

String _familyLabel(BorderGeometryFamily family) => switch (family) {
      BorderGeometryFamily.region => 'région',
      BorderGeometryFamily.linear => 'ligne',
    };

String _lossLabel(BorderRelinkLoss loss) => switch (loss) {
      BorderRelinkLoss.geometry => 'géométrie',
      BorderRelinkLoss.parameters => 'paramètres personnalisés',
      BorderRelinkLoss.overrides => 'corrections locales',
      BorderRelinkLoss.keepOutRegions => 'zones d’exclusion',
      BorderRelinkLoss.materialization => 'matérialisation',
    };

void _assertPreviewIsCurrent(
  MapData map,
  BorderBlueprintChangePreview preview,
) {
  if (!identical(map, preview.mapIdentity)) {
    throw StateError(
      'The active map changed after the blueprint preview was created',
    );
  }
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
