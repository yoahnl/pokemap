import 'package:map_core/map_core.dart';

final class TallGrassEncounterSurfaceGameplayZonePreview {
  TallGrassEncounterSurfaceGameplayZonePreview({
    required this.surfaceLabel,
    required this.sourceCellCount,
    required this.status,
    required Iterable<SurfaceGameplayZoneGenerationAssessmentMessage> messages,
    this.plan,
    this.assessment,
  }) : messages =
            List<SurfaceGameplayZoneGenerationAssessmentMessage>.unmodifiable(
          messages,
        );

  final String surfaceLabel;
  final int sourceCellCount;
  final SurfaceGameplayZoneGenerationAssessmentStatus status;
  final List<SurfaceGameplayZoneGenerationAssessmentMessage> messages;
  final SurfaceGameplayZoneGenerationPlan? plan;
  final SurfaceGameplayZoneGenerationAssessment? assessment;

  bool get canConfirm =>
      plan != null &&
      assessment != null &&
      status != SurfaceGameplayZoneGenerationAssessmentStatus.blocked;

  int get generatedZoneCount => plan?.generatedZones.length ?? 0;

  String get summaryTitle {
    return assessment?.summaryTitle ??
        (messages.isEmpty ? 'Plan bloqué' : messages.first.title);
  }

  String get summaryDescription {
    return assessment?.summaryDescription ??
        (messages.isEmpty ? null : messages.first.description) ??
        'Corrigez la surface avant de continuer.';
  }
}

final class SurfableWaterSurfaceGameplayZonePreview {
  SurfableWaterSurfaceGameplayZonePreview({
    required this.surfaceLabel,
    required this.sourceCellCount,
    required this.status,
    required Iterable<SurfaceGameplayZoneGenerationAssessmentMessage> messages,
    this.plan,
    this.assessment,
  }) : messages =
            List<SurfaceGameplayZoneGenerationAssessmentMessage>.unmodifiable(
          messages,
        );

  final String surfaceLabel;
  final int sourceCellCount;
  final SurfaceGameplayZoneGenerationAssessmentStatus status;
  final List<SurfaceGameplayZoneGenerationAssessmentMessage> messages;
  final SurfaceGameplayZoneGenerationPlan? plan;
  final SurfaceGameplayZoneGenerationAssessment? assessment;

  bool get canConfirm =>
      plan != null &&
      assessment != null &&
      status != SurfaceGameplayZoneGenerationAssessmentStatus.blocked;

  int get generatedZoneCount => plan?.generatedZones.length ?? 0;

  String get summaryTitle {
    return assessment?.summaryTitle ??
        (messages.isEmpty ? 'Plan bloqué' : messages.first.title);
  }

  String get summaryDescription {
    return assessment?.summaryDescription ??
        (messages.isEmpty ? null : messages.first.description) ??
        'Corrigez la surface avant de continuer.';
  }
}

final class LavaHazardSurfaceGameplayZonePreview {
  LavaHazardSurfaceGameplayZonePreview({
    required this.surfaceLabel,
    required this.sourceCellCount,
    required this.damagePerStep,
    required this.status,
    required Iterable<SurfaceGameplayZoneGenerationAssessmentMessage> messages,
    this.plan,
    this.assessment,
  }) : messages =
            List<SurfaceGameplayZoneGenerationAssessmentMessage>.unmodifiable(
          messages,
        );

  final String surfaceLabel;
  final int sourceCellCount;
  final int? damagePerStep;
  final SurfaceGameplayZoneGenerationAssessmentStatus status;
  final List<SurfaceGameplayZoneGenerationAssessmentMessage> messages;
  final SurfaceGameplayZoneGenerationPlan? plan;
  final SurfaceGameplayZoneGenerationAssessment? assessment;

  bool get canConfirm =>
      plan != null &&
      assessment != null &&
      status != SurfaceGameplayZoneGenerationAssessmentStatus.blocked;

  int get generatedZoneCount => plan?.generatedZones.length ?? 0;

  String get summaryTitle {
    return assessment?.summaryTitle ??
        (messages.isEmpty ? 'Plan bloqué' : messages.first.title);
  }

  String get summaryDescription {
    return assessment?.summaryDescription ??
        (messages.isEmpty ? null : messages.first.description) ??
        'Corrigez la surface avant de continuer.';
  }
}

TallGrassEncounterSurfaceGameplayZonePreview
    buildTallGrassEncounterSurfaceGameplayZonePreview({
  required MapData? map,
  required SurfaceLayer? surfaceLayer,
  required String? surfacePresetId,
  required List<ProjectSurfacePreset> presets,
  required String encounterTableId,
  SurfaceGameplayZoneGenerationAssessmentPolicy? assessmentPolicy,
}) {
  if (map == null) {
    return _blockedPreview(
      title: 'Aucune map active',
      description: 'Ouvrez une map avant de créer une zone de rencontre.',
    );
  }
  if (surfaceLayer == null) {
    return _blockedPreview(
      title: 'Aucun calque Surface actif',
      description:
          'Sélectionnez un calque Surface contenant la surface peinte.',
    );
  }

  final normalizedPresetId = surfacePresetId?.trim();
  if (normalizedPresetId == null || normalizedPresetId.isEmpty) {
    return _blockedPreview(
      title: 'Surface requise',
      description: 'Sélectionnez une surface peinte avant de créer une zone.',
    );
  }

  final preset = _findPresetById(presets, normalizedPresetId);
  if (preset == null) {
    return _blockedPreview(
      title: 'Surface absente du catalogue',
      description:
          'La surface "$normalizedPresetId" n’existe pas dans le catalogue Surface.',
      surfaceLabel: normalizedPresetId,
    );
  }

  final cells = surfaceLayer.placements
      .where(
        (placement) => placement.surfacePresetId.trim() == normalizedPresetId,
      )
      .map((placement) => GridPos(x: placement.x, y: placement.y))
      .toList(growable: false);
  if (cells.isEmpty) {
    return _blockedPreview(
      title: 'Aucune cellule peinte',
      description:
          'Cette surface n’a aucun placement dans le calque Surface ciblé.',
      surfaceLabel: preset.name,
    );
  }

  final normalizedEncounterTableId = encounterTableId.trim();
  if (normalizedEncounterTableId.isEmpty) {
    return _blockedPreview(
      title: 'Table de rencontres requise',
      description: 'Renseignez un encounterTableId avant de créer les zones.',
      surfaceLabel: preset.name,
      sourceCellCount: cells.length,
    );
  }

  final source = SurfaceGameplayZoneGenerationSource(
    surfaceLayerId: surfaceLayer.id,
    surfaceLayerName: surfaceLayer.name,
    surfacePresetId: normalizedPresetId,
    mapSize: map.size,
    cells: cells,
  );
  final plan = createSurfaceGameplayZoneGenerationPlan(
    source: source,
    behavior: SurfaceGameplayZoneBehaviorDraft.encounter(
      EncounterZonePayload(
        encounterTableId: normalizedEncounterTableId,
        encounterKind: EncounterKind.walk,
      ),
    ),
    strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: '$normalizedPresetId-encounter',
    zoneNamePrefix: '${preset.name} - Rencontre',
    existingZones: map.gameplayZones,
  );
  final assessment = assessSurfaceGameplayZoneGenerationPlan(
    plan,
    policy: assessmentPolicy,
  );

  return TallGrassEncounterSurfaceGameplayZonePreview(
    surfaceLabel: preset.name,
    sourceCellCount: source.cells.length,
    status: assessment.status,
    messages: assessment.messages,
    plan: plan,
    assessment: assessment,
  );
}

SurfableWaterSurfaceGameplayZonePreview
    buildSurfableWaterSurfaceGameplayZonePreview({
  required MapData? map,
  required SurfaceLayer? surfaceLayer,
  required String? surfacePresetId,
  required List<ProjectSurfacePreset> presets,
  SurfaceGameplayZoneGenerationAssessmentPolicy? assessmentPolicy,
}) {
  if (map == null) {
    return _blockedWaterPreview(
      title: 'Aucune map active',
      description: 'Ouvrez une map avant de créer une zone Surf.',
    );
  }
  if (surfaceLayer == null) {
    return _blockedWaterPreview(
      title: 'Aucun calque Surface actif',
      description:
          'Sélectionnez un calque Surface contenant la surface peinte.',
    );
  }

  final normalizedPresetId = surfacePresetId?.trim();
  if (normalizedPresetId == null || normalizedPresetId.isEmpty) {
    return _blockedWaterPreview(
      title: 'Surface requise',
      description: 'Sélectionnez une surface peinte avant de créer une zone.',
    );
  }

  final preset = _findPresetById(presets, normalizedPresetId);
  if (preset == null) {
    return _blockedWaterPreview(
      title: 'Surface absente du catalogue',
      description:
          'La surface "$normalizedPresetId" n’existe pas dans le catalogue Surface.',
      surfaceLabel: normalizedPresetId,
    );
  }

  final cells = surfaceLayer.placements
      .where(
        (placement) => placement.surfacePresetId.trim() == normalizedPresetId,
      )
      .map((placement) => GridPos(x: placement.x, y: placement.y))
      .toList(growable: false);
  if (cells.isEmpty) {
    return _blockedWaterPreview(
      title: 'Aucune cellule peinte',
      description:
          'Cette surface n’a aucun placement dans le calque Surface ciblé.',
      surfaceLabel: preset.name,
    );
  }

  final source = SurfaceGameplayZoneGenerationSource(
    surfaceLayerId: surfaceLayer.id,
    surfaceLayerName: surfaceLayer.name,
    surfacePresetId: normalizedPresetId,
    mapSize: map.size,
    cells: cells,
  );
  final plan = createSurfaceGameplayZoneGenerationPlan(
    source: source,
    behavior: const SurfaceGameplayZoneBehaviorDraft.movement(
      MovementZonePayload(requiredMode: MovementMode.surf),
    ),
    strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: '$normalizedPresetId-surf',
    zoneNamePrefix: '${preset.name} - Surf',
    existingZones: map.gameplayZones,
  );
  final assessment = assessSurfaceGameplayZoneGenerationPlan(
    plan,
    policy: assessmentPolicy,
  );

  return SurfableWaterSurfaceGameplayZonePreview(
    surfaceLabel: preset.name,
    sourceCellCount: source.cells.length,
    status: assessment.status,
    messages: assessment.messages,
    plan: plan,
    assessment: assessment,
  );
}

LavaHazardSurfaceGameplayZonePreview buildLavaHazardSurfaceGameplayZonePreview({
  required MapData? map,
  required SurfaceLayer? surfaceLayer,
  required String? surfacePresetId,
  required List<ProjectSurfacePreset> presets,
  required int? damagePerStep,
  SurfaceGameplayZoneGenerationAssessmentPolicy? assessmentPolicy,
}) {
  if (map == null) {
    return _blockedLavaPreview(
      title: 'Aucune map active',
      description: 'Ouvrez une map avant de créer une zone de lave.',
      damagePerStep: damagePerStep,
    );
  }
  if (surfaceLayer == null) {
    return _blockedLavaPreview(
      title: 'Aucun calque Surface actif',
      description:
          'Sélectionnez un calque Surface contenant la surface peinte.',
      damagePerStep: damagePerStep,
    );
  }

  final normalizedPresetId = surfacePresetId?.trim();
  if (normalizedPresetId == null || normalizedPresetId.isEmpty) {
    return _blockedLavaPreview(
      title: 'Surface requise',
      description: 'Sélectionnez une surface peinte avant de créer une zone.',
      damagePerStep: damagePerStep,
    );
  }

  final preset = _findPresetById(presets, normalizedPresetId);
  if (preset == null) {
    return _blockedLavaPreview(
      title: 'Surface absente du catalogue',
      description:
          'La surface "$normalizedPresetId" n’existe pas dans le catalogue Surface.',
      surfaceLabel: normalizedPresetId,
      damagePerStep: damagePerStep,
    );
  }

  final cells = surfaceLayer.placements
      .where(
        (placement) => placement.surfacePresetId.trim() == normalizedPresetId,
      )
      .map((placement) => GridPos(x: placement.x, y: placement.y))
      .toList(growable: false);
  if (cells.isEmpty) {
    return _blockedLavaPreview(
      title: 'Aucune cellule peinte',
      description:
          'Cette surface n’a aucun placement dans le calque Surface ciblé.',
      surfaceLabel: preset.name,
      damagePerStep: damagePerStep,
    );
  }

  if (damagePerStep == null || damagePerStep <= 0) {
    return _blockedLavaPreview(
      title: 'Dégâts par pas invalides',
      description:
          'Renseignez un entier strictement positif pour créer une zone de lave.',
      surfaceLabel: preset.name,
      sourceCellCount: cells.length,
      damagePerStep: damagePerStep,
    );
  }

  // Keep lava as a normal MapGameplayZone hazard: SurfaceLayer remains visual.
  final source = SurfaceGameplayZoneGenerationSource(
    surfaceLayerId: surfaceLayer.id,
    surfaceLayerName: surfaceLayer.name,
    surfacePresetId: normalizedPresetId,
    mapSize: map.size,
    cells: cells,
  );
  final plan = createSurfaceGameplayZoneGenerationPlan(
    source: source,
    behavior: SurfaceGameplayZoneBehaviorDraft.hazard(
      HazardZonePayload(
        hazardKind: HazardKind.lava,
        damagePerStep: damagePerStep,
      ),
    ),
    strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: '$normalizedPresetId-lava',
    zoneNamePrefix: '${preset.name} - Lave',
    existingZones: map.gameplayZones,
  );
  final assessment = assessSurfaceGameplayZoneGenerationPlan(
    plan,
    policy: assessmentPolicy,
  );

  return LavaHazardSurfaceGameplayZonePreview(
    surfaceLabel: preset.name,
    sourceCellCount: source.cells.length,
    damagePerStep: damagePerStep,
    status: assessment.status,
    messages: assessment.messages,
    plan: plan,
    assessment: assessment,
  );
}

ProjectSurfacePreset? _findPresetById(
  List<ProjectSurfacePreset> presets,
  String presetId,
) {
  for (final preset in presets) {
    if (preset.id.trim() == presetId) {
      return preset;
    }
  }
  return null;
}

LavaHazardSurfaceGameplayZonePreview _blockedLavaPreview({
  required String title,
  required String description,
  String surfaceLabel = 'Surface',
  int sourceCellCount = 0,
  int? damagePerStep,
}) {
  return LavaHazardSurfaceGameplayZonePreview(
    surfaceLabel: surfaceLabel,
    sourceCellCount: sourceCellCount,
    damagePerStep: damagePerStep,
    status: SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
    messages: [
      SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.error,
        title: title,
        description: description,
      ),
    ],
  );
}

SurfableWaterSurfaceGameplayZonePreview _blockedWaterPreview({
  required String title,
  required String description,
  String surfaceLabel = 'Surface',
  int sourceCellCount = 0,
}) {
  return SurfableWaterSurfaceGameplayZonePreview(
    surfaceLabel: surfaceLabel,
    sourceCellCount: sourceCellCount,
    status: SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
    messages: [
      SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.error,
        title: title,
        description: description,
      ),
    ],
  );
}

TallGrassEncounterSurfaceGameplayZonePreview _blockedPreview({
  required String title,
  required String description,
  String surfaceLabel = 'Surface',
  int sourceCellCount = 0,
}) {
  return TallGrassEncounterSurfaceGameplayZonePreview(
    surfaceLabel: surfaceLabel,
    sourceCellCount: sourceCellCount,
    status: SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
    messages: [
      SurfaceGameplayZoneGenerationAssessmentMessage(
        severity: SurfaceGameplayZoneGenerationDiagnosticSeverity.error,
        title: title,
        description: description,
      ),
    ],
  );
}
