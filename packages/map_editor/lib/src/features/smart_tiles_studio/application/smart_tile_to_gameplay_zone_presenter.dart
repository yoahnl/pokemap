import 'package:map_core/map_core.dart';

final class TallGrassEncounterSmartTileGameplayZonePreview {
  TallGrassEncounterSmartTileGameplayZonePreview({
    required this.surfaceLabel,
    required this.sourceCellCount,
    required this.status,
    required Iterable<SmartTileGameplayZoneGenerationAssessmentMessage>
        messages,
    this.plan,
    this.assessment,
  }) : messages =
            List<SmartTileGameplayZoneGenerationAssessmentMessage>.unmodifiable(
          messages,
        );

  final String surfaceLabel;
  final int sourceCellCount;
  final SmartTileGameplayZoneGenerationAssessmentStatus status;
  final List<SmartTileGameplayZoneGenerationAssessmentMessage> messages;
  final SmartTileGameplayZoneGenerationPlan? plan;
  final SmartTileGameplayZoneGenerationAssessment? assessment;

  bool get canConfirm =>
      plan != null &&
      assessment != null &&
      status != SmartTileGameplayZoneGenerationAssessmentStatus.blocked;

  int get generatedZoneCount => plan?.generatedZones.length ?? 0;

  String get summaryTitle {
    return assessment?.summaryTitle ??
        (messages.isEmpty ? 'Plan bloqué' : messages.first.title);
  }

  String get summaryDescription {
    return assessment?.summaryDescription ??
        (messages.isEmpty ? null : messages.first.description) ??
        'Corrigez le Smart Tile avant de continuer.';
  }
}

final class SurfableWaterSmartTileGameplayZonePreview {
  SurfableWaterSmartTileGameplayZonePreview({
    required this.surfaceLabel,
    required this.sourceCellCount,
    required this.status,
    required Iterable<SmartTileGameplayZoneGenerationAssessmentMessage>
        messages,
    this.plan,
    this.assessment,
  }) : messages =
            List<SmartTileGameplayZoneGenerationAssessmentMessage>.unmodifiable(
          messages,
        );

  final String surfaceLabel;
  final int sourceCellCount;
  final SmartTileGameplayZoneGenerationAssessmentStatus status;
  final List<SmartTileGameplayZoneGenerationAssessmentMessage> messages;
  final SmartTileGameplayZoneGenerationPlan? plan;
  final SmartTileGameplayZoneGenerationAssessment? assessment;

  bool get canConfirm =>
      plan != null &&
      assessment != null &&
      status != SmartTileGameplayZoneGenerationAssessmentStatus.blocked;

  int get generatedZoneCount => plan?.generatedZones.length ?? 0;

  String get summaryTitle {
    return assessment?.summaryTitle ??
        (messages.isEmpty ? 'Plan bloqué' : messages.first.title);
  }

  String get summaryDescription {
    return assessment?.summaryDescription ??
        (messages.isEmpty ? null : messages.first.description) ??
        'Corrigez le Smart Tile avant de continuer.';
  }
}

final class LavaHazardSmartTileGameplayZonePreview {
  LavaHazardSmartTileGameplayZonePreview({
    required this.surfaceLabel,
    required this.sourceCellCount,
    required this.damagePerStep,
    required this.status,
    required Iterable<SmartTileGameplayZoneGenerationAssessmentMessage>
        messages,
    this.plan,
    this.assessment,
  }) : messages =
            List<SmartTileGameplayZoneGenerationAssessmentMessage>.unmodifiable(
          messages,
        );

  final String surfaceLabel;
  final int sourceCellCount;
  final int? damagePerStep;
  final SmartTileGameplayZoneGenerationAssessmentStatus status;
  final List<SmartTileGameplayZoneGenerationAssessmentMessage> messages;
  final SmartTileGameplayZoneGenerationPlan? plan;
  final SmartTileGameplayZoneGenerationAssessment? assessment;

  bool get canConfirm =>
      plan != null &&
      assessment != null &&
      status != SmartTileGameplayZoneGenerationAssessmentStatus.blocked;

  int get generatedZoneCount => plan?.generatedZones.length ?? 0;

  String get summaryTitle {
    return assessment?.summaryTitle ??
        (messages.isEmpty ? 'Plan bloqué' : messages.first.title);
  }

  String get summaryDescription {
    return assessment?.summaryDescription ??
        (messages.isEmpty ? null : messages.first.description) ??
        'Corrigez le Smart Tile avant de continuer.';
  }
}

TallGrassEncounterSmartTileGameplayZonePreview
    buildTallGrassEncounterSmartTileGameplayZonePreview({
  required MapData? map,
  required SmartTileLayer? smartTileLayer,
  required String? smartTilePresetId,
  String? materialId,
  required ProjectSmartTileCatalog catalog,
  required String encounterTableId,
  SmartTileGameplayZoneGenerationAssessmentPolicy? assessmentPolicy,
}) {
  if (map == null) {
    return _blockedPreview(
      title: 'Aucune map active',
      description: 'Ouvrez une map avant de créer une zone de rencontre.',
    );
  }
  final sourceResolution = _resolveSmartTileGameplayZoneSource(
    map: map,
    layer: smartTileLayer,
    smartTilePresetId: smartTilePresetId,
    materialId: materialId,
    catalog: catalog,
  );
  if (sourceResolution case _BlockedSmartTileSource(:final issue)) {
    return _blockedPreview(
      title: issue.title,
      description: issue.description,
      surfaceLabel: issue.sourceLabel,
      sourceCellCount: issue.sourceCellCount,
    );
  }
  final resolved = sourceResolution as _ResolvedSmartTileSource;

  final normalizedEncounterTableId = encounterTableId.trim();
  if (normalizedEncounterTableId.isEmpty) {
    return _blockedPreview(
      title: 'Table de rencontres requise',
      description: 'Renseignez un encounterTableId avant de créer les zones.',
      surfaceLabel: resolved.sourceLabel,
      sourceCellCount: resolved.source.cells.length,
    );
  }

  final plan = createSmartTileGameplayZoneGenerationPlan(
    source: resolved.source,
    behavior: SmartTileGameplayZoneBehaviorDraft.encounter(
      EncounterZonePayload(
        encounterTableId: normalizedEncounterTableId,
        encounterKind: EncounterKind.walk,
      ),
    ),
    strategy: SmartTileGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: '${resolved.source.smartTilePresetId}-encounter',
    zoneNamePrefix: '${resolved.sourceLabel} - Rencontre',
    existingZones: map.gameplayZones,
  );
  final assessment = assessSmartTileGameplayZoneGenerationPlan(
    plan,
    policy: assessmentPolicy,
  );

  return TallGrassEncounterSmartTileGameplayZonePreview(
    surfaceLabel: resolved.sourceLabel,
    sourceCellCount: resolved.source.cells.length,
    status: assessment.status,
    messages: assessment.messages,
    plan: plan,
    assessment: assessment,
  );
}

SurfableWaterSmartTileGameplayZonePreview
    buildSurfableWaterSmartTileGameplayZonePreview({
  required MapData? map,
  required SmartTileLayer? smartTileLayer,
  required String? smartTilePresetId,
  String? materialId,
  required ProjectSmartTileCatalog catalog,
  SmartTileGameplayZoneGenerationAssessmentPolicy? assessmentPolicy,
}) {
  if (map == null) {
    return _blockedWaterPreview(
      title: 'Aucune map active',
      description: 'Ouvrez une map avant de créer une zone Surf.',
    );
  }
  final sourceResolution = _resolveSmartTileGameplayZoneSource(
    map: map,
    layer: smartTileLayer,
    smartTilePresetId: smartTilePresetId,
    materialId: materialId,
    catalog: catalog,
  );
  if (sourceResolution case _BlockedSmartTileSource(:final issue)) {
    return _blockedWaterPreview(
      title: issue.title,
      description: issue.description,
      surfaceLabel: issue.sourceLabel,
      sourceCellCount: issue.sourceCellCount,
    );
  }
  final resolved = sourceResolution as _ResolvedSmartTileSource;

  final plan = createSmartTileGameplayZoneGenerationPlan(
    source: resolved.source,
    behavior: const SmartTileGameplayZoneBehaviorDraft.movement(
      MovementZonePayload(requiredMode: MovementMode.surf),
    ),
    strategy: SmartTileGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: '${resolved.source.smartTilePresetId}-surf',
    zoneNamePrefix: '${resolved.sourceLabel} - Surf',
    existingZones: map.gameplayZones,
  );
  final assessment = assessSmartTileGameplayZoneGenerationPlan(
    plan,
    policy: assessmentPolicy,
  );

  return SurfableWaterSmartTileGameplayZonePreview(
    surfaceLabel: resolved.sourceLabel,
    sourceCellCount: resolved.source.cells.length,
    status: assessment.status,
    messages: assessment.messages,
    plan: plan,
    assessment: assessment,
  );
}

LavaHazardSmartTileGameplayZonePreview
    buildLavaHazardSmartTileGameplayZonePreview({
  required MapData? map,
  required SmartTileLayer? smartTileLayer,
  required String? smartTilePresetId,
  String? materialId,
  required ProjectSmartTileCatalog catalog,
  required int? damagePerStep,
  SmartTileGameplayZoneGenerationAssessmentPolicy? assessmentPolicy,
}) {
  if (map == null) {
    return _blockedLavaPreview(
      title: 'Aucune map active',
      description: 'Ouvrez une map avant de créer une zone de lave.',
      damagePerStep: damagePerStep,
    );
  }
  final sourceResolution = _resolveSmartTileGameplayZoneSource(
    map: map,
    layer: smartTileLayer,
    smartTilePresetId: smartTilePresetId,
    materialId: materialId,
    catalog: catalog,
  );
  if (sourceResolution case _BlockedSmartTileSource(:final issue)) {
    return _blockedLavaPreview(
      title: issue.title,
      description: issue.description,
      surfaceLabel: issue.sourceLabel,
      sourceCellCount: issue.sourceCellCount,
      damagePerStep: damagePerStep,
    );
  }
  final resolved = sourceResolution as _ResolvedSmartTileSource;

  if (damagePerStep == null || damagePerStep <= 0) {
    return _blockedLavaPreview(
      title: 'Dégâts par pas invalides',
      description:
          'Renseignez un entier strictement positif pour créer une zone de lave.',
      surfaceLabel: resolved.sourceLabel,
      sourceCellCount: resolved.source.cells.length,
      damagePerStep: damagePerStep,
    );
  }

  final plan = createSmartTileGameplayZoneGenerationPlan(
    source: resolved.source,
    behavior: SmartTileGameplayZoneBehaviorDraft.hazard(
      HazardZonePayload(
        hazardKind: HazardKind.lava,
        damagePerStep: damagePerStep,
      ),
    ),
    strategy: SmartTileGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: '${resolved.source.smartTilePresetId}-lava',
    zoneNamePrefix: '${resolved.sourceLabel} - Lave',
    existingZones: map.gameplayZones,
  );
  final assessment = assessSmartTileGameplayZoneGenerationPlan(
    plan,
    policy: assessmentPolicy,
  );

  return LavaHazardSmartTileGameplayZonePreview(
    surfaceLabel: resolved.sourceLabel,
    sourceCellCount: resolved.source.cells.length,
    damagePerStep: damagePerStep,
    status: assessment.status,
    messages: assessment.messages,
    plan: plan,
    assessment: assessment,
  );
}

sealed class _SmartTileSourceResolution {}

final class _ResolvedSmartTileSource extends _SmartTileSourceResolution {
  _ResolvedSmartTileSource({required this.source, required this.sourceLabel});

  final SmartTileGameplayZoneGenerationSource source;
  final String sourceLabel;
}

final class _BlockedSmartTileSource extends _SmartTileSourceResolution {
  _BlockedSmartTileSource(this.issue);

  final _SmartTileSourceIssue issue;
}

final class _SmartTileSourceIssue {
  const _SmartTileSourceIssue({
    required this.title,
    required this.description,
    this.sourceLabel = 'Smart Tile',
  });

  final String title;
  final String description;
  final String sourceLabel;
  int get sourceCellCount => 0;
}

_SmartTileSourceResolution _resolveSmartTileGameplayZoneSource({
  required MapData map,
  required SmartTileLayer? layer,
  required String? smartTilePresetId,
  required String? materialId,
  required ProjectSmartTileCatalog catalog,
}) {
  if (layer == null) {
    return _BlockedSmartTileSource(
      const _SmartTileSourceIssue(
        title: 'Aucun calque Smart Tile actif',
        description: 'Sélectionnez un calque Smart Tile peint.',
      ),
    );
  }
  final presetId = smartTilePresetId?.trim() ?? '';
  if (presetId.isEmpty) {
    return _BlockedSmartTileSource(
      const _SmartTileSourceIssue(
        title: 'Preset Smart Tile requis',
        description: 'Sélectionnez un preset publié avant de créer une zone.',
      ),
    );
  }
  ProjectSmartTilePreset? preset;
  for (final candidate in catalog.presets) {
    if (candidate.id == presetId) {
      preset = candidate;
      break;
    }
  }
  if (preset == null ||
      preset.status != SmartTilePresetStatus.published ||
      layer.presetId != preset.id ||
      layer.usage != preset.usage) {
    return _BlockedSmartTileSource(
      _SmartTileSourceIssue(
        title: 'Preset Smart Tile indisponible',
        description: 'Le preset "$presetId" ne correspond pas au calque actif.',
        sourceLabel: presetId,
      ),
    );
  }
  final selectedMaterialId = materialId?.trim().isNotEmpty == true
      ? materialId!.trim()
      : preset.defaultMaterialId;
  ProjectSmartTileMaterial? material;
  for (final candidate in catalog.materials) {
    if (candidate.id == selectedMaterialId) {
      material = candidate;
      break;
    }
  }
  final paletteIndex = layer.materialPalette.indexOf(selectedMaterialId);
  if (material == null ||
      material.isEmpty ||
      !preset.allowedMaterialIds.contains(selectedMaterialId) ||
      paletteIndex < 0) {
    return _BlockedSmartTileSource(
      _SmartTileSourceIssue(
        title: 'Matériau Smart Tile indisponible',
        description: 'Le matériau "$selectedMaterialId" ne peut pas être '
            'utilisé sur ce calque.',
        sourceLabel: preset.name,
      ),
    );
  }
  final field = layer.field;
  if (field is! SmartTileCellField) {
    return _BlockedSmartTileSource(
      _SmartTileSourceIssue(
        title: 'Champ Wang non pris en charge',
        description: 'La génération de zones depuis un champ Wang arrivera '
            'avec STN-05.',
        sourceLabel: '${preset.name} · ${material.name}',
      ),
    );
  }
  final expectedCellCount = map.size.width * map.size.height;
  if (field.semanticCells.length != expectedCellCount) {
    return _BlockedSmartTileSource(
      _SmartTileSourceIssue(
        title: 'Champ Smart Tile invalide',
        description: 'La taille du champ ne correspond pas à celle de la map.',
        sourceLabel: '${preset.name} · ${material.name}',
      ),
    );
  }
  final cells = <GridPos>[];
  for (var index = 0; index < field.semanticCells.length; index++) {
    if (field.semanticCells[index] != paletteIndex) continue;
    cells.add(
      GridPos(x: index % map.size.width, y: index ~/ map.size.width),
    );
  }
  final sourceLabel = '${preset.name} · ${material.name}';
  if (cells.isEmpty) {
    return _BlockedSmartTileSource(
      _SmartTileSourceIssue(
        title: 'Aucune cellule peinte',
        description: 'Ce matériau n’est peint nulle part sur le calque actif.',
        sourceLabel: sourceLabel,
      ),
    );
  }
  return _ResolvedSmartTileSource(
    sourceLabel: sourceLabel,
    source: SmartTileGameplayZoneGenerationSource(
      smartTileLayerId: layer.id,
      smartTileLayerName: layer.name,
      smartTilePresetId: preset.id,
      materialId: selectedMaterialId,
      mapSize: map.size,
      cells: cells,
    ),
  );
}

LavaHazardSmartTileGameplayZonePreview _blockedLavaPreview({
  required String title,
  required String description,
  String surfaceLabel = 'Surface',
  int sourceCellCount = 0,
  int? damagePerStep,
}) {
  return LavaHazardSmartTileGameplayZonePreview(
    surfaceLabel: surfaceLabel,
    sourceCellCount: sourceCellCount,
    damagePerStep: damagePerStep,
    status: SmartTileGameplayZoneGenerationAssessmentStatus.blocked,
    messages: [
      SmartTileGameplayZoneGenerationAssessmentMessage(
        severity: SmartTileGameplayZoneGenerationDiagnosticSeverity.error,
        title: title,
        description: description,
      ),
    ],
  );
}

SurfableWaterSmartTileGameplayZonePreview _blockedWaterPreview({
  required String title,
  required String description,
  String surfaceLabel = 'Surface',
  int sourceCellCount = 0,
}) {
  return SurfableWaterSmartTileGameplayZonePreview(
    surfaceLabel: surfaceLabel,
    sourceCellCount: sourceCellCount,
    status: SmartTileGameplayZoneGenerationAssessmentStatus.blocked,
    messages: [
      SmartTileGameplayZoneGenerationAssessmentMessage(
        severity: SmartTileGameplayZoneGenerationDiagnosticSeverity.error,
        title: title,
        description: description,
      ),
    ],
  );
}

TallGrassEncounterSmartTileGameplayZonePreview _blockedPreview({
  required String title,
  required String description,
  String surfaceLabel = 'Surface',
  int sourceCellCount = 0,
}) {
  return TallGrassEncounterSmartTileGameplayZonePreview(
    surfaceLabel: surfaceLabel,
    sourceCellCount: sourceCellCount,
    status: SmartTileGameplayZoneGenerationAssessmentStatus.blocked,
    messages: [
      SmartTileGameplayZoneGenerationAssessmentMessage(
        severity: SmartTileGameplayZoneGenerationDiagnosticSeverity.error,
        title: title,
        description: description,
      ),
    ],
  );
}
