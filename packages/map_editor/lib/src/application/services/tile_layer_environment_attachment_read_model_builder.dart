import 'package:map_core/map_core.dart';

import '../models/tile_layer_environment_attachment_read_model.dart';

TileLayerEnvironmentAttachmentReadModel
    buildTileLayerEnvironmentAttachmentReadModel({
  required ProjectManifest? manifest,
  required MapData? map,
  required String? selectedLayerId,
  required String? selectedEnvironmentAreaId,
}) {
  if (manifest == null) {
    return const TileLayerEnvironmentAttachmentReadModel(
      state: TileLayerEnvironmentAttachmentState.noProject,
      emptyStateTitle: 'Aucun projet chargé',
      emptyStateMessage:
          'Ouvrez un projet avant d’utiliser une brush d’environnement.',
    );
  }
  if (map == null) {
    return const TileLayerEnvironmentAttachmentReadModel(
      state: TileLayerEnvironmentAttachmentState.noMap,
      emptyStateTitle: 'Aucune carte active',
      emptyStateMessage:
          'Sélectionnez une carte pour configurer un environnement.',
    );
  }

  final trimmedSelectedLayerId = selectedLayerId?.trim();
  if (trimmedSelectedLayerId == null || trimmedSelectedLayerId.isEmpty) {
    return const TileLayerEnvironmentAttachmentReadModel(
      state: TileLayerEnvironmentAttachmentState.noLayerSelected,
      selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.none,
      emptyStateTitle: 'Aucun layer sélectionné',
      emptyStateMessage:
          'Sélectionnez un TileLayer pour utiliser une brush d’environnement.',
    );
  }

  final selectedLayer = _findLayerById(map, trimmedSelectedLayerId);
  if (selectedLayer == null) {
    return TileLayerEnvironmentAttachmentReadModel(
      state: TileLayerEnvironmentAttachmentState.selectedLayerMissing,
      selectedLayerId: trimmedSelectedLayerId,
      selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.missing,
      emptyStateTitle: 'Layer introuvable',
      emptyStateMessage: 'Le layer sélectionné est introuvable dans la carte.',
      issues: const [
        TileLayerEnvironmentAttachmentIssue(
          severity: TileLayerEnvironmentAttachmentIssueSeverity.error,
          message: 'Le layer sélectionné est introuvable dans la carte.',
        ),
      ],
    );
  }

  if (selectedLayer is TileLayer) {
    return _buildFromTileLayerSelection(
      manifest: manifest,
      map: map,
      selectedTileLayer: selectedLayer,
      selectedEnvironmentAreaId: selectedEnvironmentAreaId,
    );
  }

  if (selectedLayer is EnvironmentLayer) {
    return _buildFromLegacyEnvironmentLayerSelection(
      manifest: manifest,
      map: map,
      selectedEnvironmentLayer: selectedLayer,
      selectedEnvironmentAreaId: selectedEnvironmentAreaId,
    );
  }

  return TileLayerEnvironmentAttachmentReadModel(
    state: TileLayerEnvironmentAttachmentState.unsupportedLayer,
    selectedLayerId: selectedLayer.id,
    selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.other,
    emptyStateTitle: 'Sélectionnez un TileLayer',
    emptyStateMessage:
        'Sélectionnez un TileLayer pour utiliser une brush d’environnement.',
  );
}

TileLayerEnvironmentAttachmentReadModel _buildFromTileLayerSelection({
  required ProjectManifest manifest,
  required MapData map,
  required TileLayer selectedTileLayer,
  required String? selectedEnvironmentAreaId,
}) {
  final attachments = _environmentLayersTargeting(map, selectedTileLayer.id);
  if (attachments.isEmpty) {
    return TileLayerEnvironmentAttachmentReadModel(
      state: TileLayerEnvironmentAttachmentState.noAttachment,
      selectedLayerId: selectedTileLayer.id,
      selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
      activeTileLayerId: selectedTileLayer.id,
      activeTileLayerName: selectedTileLayer.name,
      hasValidTargetTileLayer: true,
      canEnableEnvironment: true,
      emptyStateTitle: 'Aucun environnement sur ce layer',
      emptyStateMessage:
          'Activez l’environnement pour peindre une zone organique sur ce layer.',
      primaryActionLabel: 'Activer l’environnement',
    );
  }

  final issues = <TileLayerEnvironmentAttachmentIssue>[];
  if (attachments.length > 1) {
    issues.add(
      const TileLayerEnvironmentAttachmentIssue(
        severity: TileLayerEnvironmentAttachmentIssueSeverity.warning,
        message:
            'Plusieurs environnements ciblent ce layer. Le premier sera utilisé pour l’instant.',
      ),
    );
  }

  return _buildFromResolvedAttachment(
    manifest: manifest,
    map: map,
    selectedLayerId: selectedTileLayer.id,
    selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
    activeTileLayer: selectedTileLayer,
    environmentLayer: attachments.first,
    selectedEnvironmentAreaId: selectedEnvironmentAreaId,
    isLegacyEnvironmentLayerSelection: false,
    attachmentCount: attachments.length,
    issues: issues,
  );
}

TileLayerEnvironmentAttachmentReadModel
    _buildFromLegacyEnvironmentLayerSelection({
  required ProjectManifest manifest,
  required MapData map,
  required EnvironmentLayer selectedEnvironmentLayer,
  required String? selectedEnvironmentAreaId,
}) {
  final issues = <TileLayerEnvironmentAttachmentIssue>[
    const TileLayerEnvironmentAttachmentIssue(
      severity: TileLayerEnvironmentAttachmentIssueSeverity.warning,
      message:
          'Cet environnement est attaché à un TileLayer. La prochaine UX le pilotera depuis le layer cible.',
    ),
  ];

  final targetTileLayerId =
      selectedEnvironmentLayer.content.targetTileLayerId?.trim();
  if (targetTileLayerId == null || targetTileLayerId.isEmpty) {
    issues.add(
      const TileLayerEnvironmentAttachmentIssue(
        severity: TileLayerEnvironmentAttachmentIssueSeverity.error,
        message: 'Cet environnement n’a pas encore de layer cible.',
      ),
    );
    return TileLayerEnvironmentAttachmentReadModel(
      state: TileLayerEnvironmentAttachmentState.missingTargetTileLayer,
      selectedLayerId: selectedEnvironmentLayer.id,
      selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.environment,
      attachedEnvironmentLayerId: selectedEnvironmentLayer.id,
      attachedEnvironmentLayerName: selectedEnvironmentLayer.name,
      isLegacyEnvironmentLayerSelection: true,
      hasAttachment: true,
      attachmentCount: 1,
      emptyStateTitle: 'Layer cible manquant',
      emptyStateMessage:
          'Associez cet environnement à un TileLayer avant de peindre.',
      issues: List.unmodifiable(issues),
    );
  }

  final targetLayer = _findLayerById(map, targetTileLayerId);
  if (targetLayer == null) {
    issues.add(
      const TileLayerEnvironmentAttachmentIssue(
        severity: TileLayerEnvironmentAttachmentIssueSeverity.error,
        message: 'Le layer cible de cet environnement est introuvable.',
      ),
    );
    return TileLayerEnvironmentAttachmentReadModel(
      state: TileLayerEnvironmentAttachmentState.targetTileLayerMissing,
      selectedLayerId: selectedEnvironmentLayer.id,
      selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.environment,
      attachedEnvironmentLayerId: selectedEnvironmentLayer.id,
      attachedEnvironmentLayerName: selectedEnvironmentLayer.name,
      isLegacyEnvironmentLayerSelection: true,
      hasAttachment: true,
      attachmentCount: 1,
      emptyStateTitle: 'Layer cible introuvable',
      emptyStateMessage:
          'Le TileLayer associé à cet environnement n’existe plus dans la carte.',
      issues: List.unmodifiable(issues),
    );
  }

  if (targetLayer is! TileLayer) {
    issues.add(
      const TileLayerEnvironmentAttachmentIssue(
        severity: TileLayerEnvironmentAttachmentIssueSeverity.error,
        message: 'Le layer cible de cet environnement n’est pas un TileLayer.',
      ),
    );
    return TileLayerEnvironmentAttachmentReadModel(
      state: TileLayerEnvironmentAttachmentState.targetLayerIsNotTileLayer,
      selectedLayerId: selectedEnvironmentLayer.id,
      selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.environment,
      activeTileLayerId: targetLayer.id,
      activeTileLayerName: targetLayer.name,
      attachedEnvironmentLayerId: selectedEnvironmentLayer.id,
      attachedEnvironmentLayerName: selectedEnvironmentLayer.name,
      isLegacyEnvironmentLayerSelection: true,
      hasAttachment: true,
      attachmentCount: 1,
      emptyStateTitle: 'Layer cible incompatible',
      emptyStateMessage:
          'Choisissez un TileLayer comme cible de cet environnement.',
      issues: List.unmodifiable(issues),
    );
  }

  return _buildFromResolvedAttachment(
    manifest: manifest,
    map: map,
    selectedLayerId: selectedEnvironmentLayer.id,
    selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.environment,
    activeTileLayer: targetLayer,
    environmentLayer: selectedEnvironmentLayer,
    selectedEnvironmentAreaId: selectedEnvironmentAreaId,
    isLegacyEnvironmentLayerSelection: true,
    attachmentCount: 1,
    issues: issues,
  );
}

TileLayerEnvironmentAttachmentReadModel _buildFromResolvedAttachment({
  required ProjectManifest manifest,
  required MapData map,
  required String selectedLayerId,
  required TileLayerEnvironmentSelectedLayerKind selectedLayerKind,
  required TileLayer activeTileLayer,
  required EnvironmentLayer environmentLayer,
  required String? selectedEnvironmentAreaId,
  required bool isLegacyEnvironmentLayerSelection,
  required int attachmentCount,
  required List<TileLayerEnvironmentAttachmentIssue> issues,
}) {
  final areas = environmentLayer.content.areas;
  if (areas.isEmpty) {
    return TileLayerEnvironmentAttachmentReadModel(
      state: TileLayerEnvironmentAttachmentState.noArea,
      selectedLayerId: selectedLayerId,
      selectedLayerKind: selectedLayerKind,
      activeTileLayerId: activeTileLayer.id,
      activeTileLayerName: activeTileLayer.name,
      attachedEnvironmentLayerId: environmentLayer.id,
      attachedEnvironmentLayerName: environmentLayer.name,
      isLegacyEnvironmentLayerSelection: isLegacyEnvironmentLayerSelection,
      hasAttachment: true,
      hasValidTargetTileLayer: true,
      hasMultipleAttachments: attachmentCount > 1,
      attachmentCount: attachmentCount,
      canPaintMask: false,
      emptyStateTitle: 'Aucune zone d’environnement',
      emptyStateMessage:
          'Ajoutez une zone, choisissez un preset, puis peignez le masque.',
      primaryActionLabel: 'Ajouter une zone',
      issues: List.unmodifiable(issues),
    );
  }

  final placedElementIds = map.placedElements.map((e) => e.id).toSet();
  List<TileLayerEnvironmentAreaSummary> areaSummariesFor(
    String? effectiveSelectedAreaId,
  ) {
    return _buildAreaSummaries(
      manifest: manifest,
      areas: areas,
      selectedEnvironmentAreaId: effectiveSelectedAreaId,
      placedElementIds: placedElementIds,
    );
  }

  final trimmedAreaId = selectedEnvironmentAreaId?.trim();
  final EnvironmentArea? area;
  if (trimmedAreaId != null && trimmedAreaId.isNotEmpty) {
    area = environmentLayer.content.areaById(trimmedAreaId);
    if (area == null) {
      final nextIssues = [
        ...issues,
        const TileLayerEnvironmentAttachmentIssue(
          severity: TileLayerEnvironmentAttachmentIssueSeverity.error,
          message: 'La zone d’environnement sélectionnée est introuvable.',
        ),
      ];
      return TileLayerEnvironmentAttachmentReadModel(
        state: TileLayerEnvironmentAttachmentState.selectedAreaMissing,
        selectedLayerId: selectedLayerId,
        selectedLayerKind: selectedLayerKind,
        activeTileLayerId: activeTileLayer.id,
        activeTileLayerName: activeTileLayer.name,
        attachedEnvironmentLayerId: environmentLayer.id,
        attachedEnvironmentLayerName: environmentLayer.name,
        isLegacyEnvironmentLayerSelection: isLegacyEnvironmentLayerSelection,
        hasAttachment: true,
        hasValidTargetTileLayer: true,
        hasMultipleAttachments: attachmentCount > 1,
        attachmentCount: attachmentCount,
        areaSummaries: areaSummariesFor(null),
        emptyStateTitle: 'Zone introuvable',
        emptyStateMessage:
            'La zone d’environnement sélectionnée n’existe plus sur ce layer.',
        issues: List.unmodifiable(nextIssues),
      );
    }
  } else if (areas.length == 1) {
    area = areas.first;
  } else {
    return TileLayerEnvironmentAttachmentReadModel(
      state: TileLayerEnvironmentAttachmentState.areaSelectionRequired,
      selectedLayerId: selectedLayerId,
      selectedLayerKind: selectedLayerKind,
      activeTileLayerId: activeTileLayer.id,
      activeTileLayerName: activeTileLayer.name,
      attachedEnvironmentLayerId: environmentLayer.id,
      attachedEnvironmentLayerName: environmentLayer.name,
      isLegacyEnvironmentLayerSelection: isLegacyEnvironmentLayerSelection,
      hasAttachment: true,
      hasValidTargetTileLayer: true,
      hasMultipleAttachments: attachmentCount > 1,
      attachmentCount: attachmentCount,
      areaSummaries: areaSummariesFor(null),
      emptyStateTitle: 'Sélectionnez une zone d’environnement',
      emptyStateMessage:
          'Choisissez la zone à modifier avant de peindre ou générer.',
      issues: List.unmodifiable(issues),
    );
  }

  final preset = _findEnvironmentPreset(manifest, area.presetId);
  final maskActiveCellCount = area.mask.activeCellCount;
  final hasMask = maskActiveCellCount > 0;
  final generatedPlacementIds = area.generatedPlacementIds;
  final generatedPlacementCount = generatedPlacementIds.length;
  final existingGeneratedPlacementCount =
      generatedPlacementIds.where((id) => placedElementIds.contains(id)).length;
  final missingGeneratedPlacementCount =
      generatedPlacementCount - existingGeneratedPlacementCount;
  final nextIssues = [...issues];
  if (missingGeneratedPlacementCount > 0) {
    nextIssues.add(
      TileLayerEnvironmentAttachmentIssue(
        severity: TileLayerEnvironmentAttachmentIssueSeverity.warning,
        message:
            '$missingGeneratedPlacementCount placements générés référencés sont introuvables.',
      ),
    );
  }

  if (preset == null) {
    nextIssues.add(
      const TileLayerEnvironmentAttachmentIssue(
        severity: TileLayerEnvironmentAttachmentIssueSeverity.error,
        message:
            'Le preset d’environnement utilisé par cette zone est introuvable.',
      ),
    );
    return _areaReadModel(
      state: TileLayerEnvironmentAttachmentState.missingPreset,
      selectedLayerId: selectedLayerId,
      selectedLayerKind: selectedLayerKind,
      activeTileLayer: activeTileLayer,
      environmentLayer: environmentLayer,
      area: area,
      preset: null,
      isLegacyEnvironmentLayerSelection: isLegacyEnvironmentLayerSelection,
      attachmentCount: attachmentCount,
      maskActiveCellCount: maskActiveCellCount,
      hasMask: hasMask,
      generatedPlacementCount: generatedPlacementCount,
      existingGeneratedPlacementCount: existingGeneratedPlacementCount,
      missingGeneratedPlacementCount: missingGeneratedPlacementCount,
      areaSummaries: areaSummariesFor(area.id),
      canPaintMask: true,
      canGenerate: false,
      canClearGeneratedPlacements: generatedPlacementCount > 0,
      canRegenerate: false,
      canShuffle: false,
      emptyStateTitle: 'Preset introuvable',
      emptyStateMessage:
          'Choisissez un preset disponible avant de générer cette zone.',
      issues: nextIssues,
    );
  }

  if (!hasMask) {
    return _areaReadModel(
      state: TileLayerEnvironmentAttachmentState.emptyMask,
      selectedLayerId: selectedLayerId,
      selectedLayerKind: selectedLayerKind,
      activeTileLayer: activeTileLayer,
      environmentLayer: environmentLayer,
      area: area,
      preset: preset,
      isLegacyEnvironmentLayerSelection: isLegacyEnvironmentLayerSelection,
      attachmentCount: attachmentCount,
      maskActiveCellCount: maskActiveCellCount,
      hasMask: false,
      generatedPlacementCount: generatedPlacementCount,
      existingGeneratedPlacementCount: existingGeneratedPlacementCount,
      missingGeneratedPlacementCount: missingGeneratedPlacementCount,
      areaSummaries: areaSummariesFor(area.id),
      canPaintMask: true,
      canGenerate: false,
      canClearGeneratedPlacements: generatedPlacementCount > 0,
      canRegenerate: false,
      canShuffle: false,
      emptyStateTitle: 'Masque vide',
      emptyStateMessage: 'Peignez une zone sur la carte avant de générer.',
      issues: nextIssues,
    );
  }

  if (generatedPlacementCount > 0) {
    return _areaReadModel(
      state: TileLayerEnvironmentAttachmentState.generated,
      selectedLayerId: selectedLayerId,
      selectedLayerKind: selectedLayerKind,
      activeTileLayer: activeTileLayer,
      environmentLayer: environmentLayer,
      area: area,
      preset: preset,
      isLegacyEnvironmentLayerSelection: isLegacyEnvironmentLayerSelection,
      attachmentCount: attachmentCount,
      maskActiveCellCount: maskActiveCellCount,
      hasMask: true,
      generatedPlacementCount: generatedPlacementCount,
      existingGeneratedPlacementCount: existingGeneratedPlacementCount,
      missingGeneratedPlacementCount: missingGeneratedPlacementCount,
      areaSummaries: areaSummariesFor(area.id),
      canPaintMask: true,
      canGenerate: false,
      canClearGeneratedPlacements: true,
      canRegenerate: true,
      canShuffle: true,
      emptyStateTitle: 'Placements générés',
      emptyStateMessage: 'Cette zone contient déjà des placements générés.',
      primaryActionLabel: 'Régénérer',
      issues: nextIssues,
    );
  }

  return _areaReadModel(
    state: TileLayerEnvironmentAttachmentState.ready,
    selectedLayerId: selectedLayerId,
    selectedLayerKind: selectedLayerKind,
    activeTileLayer: activeTileLayer,
    environmentLayer: environmentLayer,
    area: area,
    preset: preset,
    isLegacyEnvironmentLayerSelection: isLegacyEnvironmentLayerSelection,
    attachmentCount: attachmentCount,
    maskActiveCellCount: maskActiveCellCount,
    hasMask: true,
    generatedPlacementCount: 0,
    existingGeneratedPlacementCount: 0,
    missingGeneratedPlacementCount: 0,
    areaSummaries: areaSummariesFor(area.id),
    canPaintMask: true,
    canGenerate: true,
    canClearGeneratedPlacements: false,
    canRegenerate: false,
    canShuffle: true,
    emptyStateTitle: 'Prêt à générer',
    emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
    primaryActionLabel: 'Générer',
    issues: nextIssues,
  );
}

TileLayerEnvironmentAttachmentReadModel _areaReadModel({
  required TileLayerEnvironmentAttachmentState state,
  required String selectedLayerId,
  required TileLayerEnvironmentSelectedLayerKind selectedLayerKind,
  required TileLayer activeTileLayer,
  required EnvironmentLayer environmentLayer,
  required EnvironmentArea area,
  required EnvironmentPreset? preset,
  required bool isLegacyEnvironmentLayerSelection,
  required int attachmentCount,
  required int maskActiveCellCount,
  required bool hasMask,
  required int generatedPlacementCount,
  required int existingGeneratedPlacementCount,
  required int missingGeneratedPlacementCount,
  required List<TileLayerEnvironmentAreaSummary> areaSummaries,
  required bool canPaintMask,
  required bool canGenerate,
  required bool canClearGeneratedPlacements,
  required bool canRegenerate,
  required bool canShuffle,
  required String emptyStateTitle,
  required String emptyStateMessage,
  required List<TileLayerEnvironmentAttachmentIssue> issues,
  String? primaryActionLabel,
}) {
  return TileLayerEnvironmentAttachmentReadModel(
    state: state,
    selectedLayerId: selectedLayerId,
    selectedLayerKind: selectedLayerKind,
    activeTileLayerId: activeTileLayer.id,
    activeTileLayerName: activeTileLayer.name,
    attachedEnvironmentLayerId: environmentLayer.id,
    attachedEnvironmentLayerName: environmentLayer.name,
    isLegacyEnvironmentLayerSelection: isLegacyEnvironmentLayerSelection,
    hasAttachment: true,
    hasValidTargetTileLayer: true,
    hasMultipleAttachments: attachmentCount > 1,
    attachmentCount: attachmentCount,
    selectedEnvironmentAreaId: area.id,
    selectedEnvironmentAreaName: area.name,
    selectedPresetId: area.presetId,
    selectedPresetName: preset?.name,
    maskActiveCellCount: maskActiveCellCount,
    hasMask: hasMask,
    hasGeneratedPlacements: generatedPlacementCount > 0,
    generatedPlacementCount: generatedPlacementCount,
    existingGeneratedPlacementCount: existingGeneratedPlacementCount,
    missingGeneratedPlacementCount: missingGeneratedPlacementCount,
    areaSummaries: areaSummaries,
    canPaintMask: canPaintMask,
    canGenerate: canGenerate,
    canClearGeneratedPlacements: canClearGeneratedPlacements,
    canRegenerate: canRegenerate,
    canShuffle: canShuffle,
    emptyStateTitle: emptyStateTitle,
    emptyStateMessage: emptyStateMessage,
    primaryActionLabel: primaryActionLabel,
    issues: List.unmodifiable(issues),
    selectedAreaEffectiveParams:
        preset == null ? null : area.paramsOverride ?? preset.defaultParams,
    selectedAreaDefaultParams: preset?.defaultParams,
    selectedAreaParamsOverride: area.paramsOverride,
    selectedAreaHasParamsOverride: area.paramsOverride != null,
    selectedAreaSeed: area.seed,
    canEditSelectedAreaGenerationParams: preset != null,
  );
}

List<TileLayerEnvironmentAreaSummary> _buildAreaSummaries({
  required ProjectManifest manifest,
  required List<EnvironmentArea> areas,
  required String? selectedEnvironmentAreaId,
  required Set<String> placedElementIds,
}) {
  final selectedId = selectedEnvironmentAreaId?.trim();
  return List.unmodifiable(
    [
      for (final area in areas)
        _areaSummary(
          manifest: manifest,
          area: area,
          isSelected: selectedId != null &&
              selectedId.isNotEmpty &&
              area.id == selectedId,
          placedElementIds: placedElementIds,
        ),
    ],
  );
}

TileLayerEnvironmentAreaSummary _areaSummary({
  required ProjectManifest manifest,
  required EnvironmentArea area,
  required bool isSelected,
  required Set<String> placedElementIds,
}) {
  final preset = _findEnvironmentPreset(manifest, area.presetId);
  final generatedPlacementCount = area.generatedPlacementIds.length;
  final existingGeneratedPlacementCount = area.generatedPlacementIds
      .where((id) => placedElementIds.contains(id))
      .length;
  return TileLayerEnvironmentAreaSummary(
    id: area.id,
    name: area.name,
    presetId: area.presetId,
    presetName: preset?.name,
    isSelected: isSelected,
    maskActiveCellCount: area.mask.activeCellCount,
    generatedPlacementCount: generatedPlacementCount,
    missingGeneratedPlacementCount:
        generatedPlacementCount - existingGeneratedPlacementCount,
    hasMissingPreset: preset == null,
  );
}

MapLayer? _findLayerById(MapData map, String layerId) {
  for (final layer in map.layers) {
    if (layer.id == layerId) {
      return layer;
    }
  }
  return null;
}

List<EnvironmentLayer> _environmentLayersTargeting(
  MapData map,
  String tileLayerId,
) {
  return [
    for (final layer in map.layers)
      if (layer is EnvironmentLayer &&
          layer.content.targetTileLayerId == tileLayerId)
        layer,
  ];
}

EnvironmentPreset? _findEnvironmentPreset(
  ProjectManifest manifest,
  String presetId,
) {
  for (final preset in manifest.environmentPresets) {
    if (preset.id == presetId) {
      return preset;
    }
  }
  return null;
}
