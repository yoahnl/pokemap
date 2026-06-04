import '../authoring/cinematic_authoring_operations.dart';
import '../models/cinematic_asset.dart';
import '../models/project_manifest.dart';

enum CinematicDiagnosticSeverity {
  error,
  warning,
  info,
}

enum CinematicDiagnosticCode {
  cinematicMissingId,
  cinematicMissingTitle,
  cinematicDuplicateId,
  cinematicEmptyTimeline,
  cinematicDuplicateStepId,
  cinematicInvalidStepDuration,
  cinematicUnsupportedGameplayStep,
  cinematicTechnicalLabel,
  cinematicUnknownStorylineRef,
  cinematicUnknownChapterRef,
  cinematicUnknownMapRef,
  cinematicUnknownActorRef,
  cinematicActorMoveMissingActorRef,
  cinematicActorMoveMissingTargetRef,
  cinematicUnknownMovementTargetRef,
  cinematicActorMoveInvalidDuration,
  cinematicActorMoveInvalidMovementMode,
  cinematicActorMoveUnsupportedPathMode,
  cinematicLegacyBridge,
  cinematicScenarioBridgeNotCanonical,
}

enum CinematicDiagnosticTarget {
  cinematic,
  timeline,
  step,
  reference,
  legacyBridge,
}

final class CinematicDiagnostic {
  const CinematicDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.cinematicId,
    required this.target,
    this.stepId,
    this.referenceId,
    this.suggestedFixLabel,
  });

  final CinematicDiagnosticCode code;
  final CinematicDiagnosticSeverity severity;
  final String message;
  final String cinematicId;
  final CinematicDiagnosticTarget target;
  final String? stepId;
  final String? referenceId;
  final String? suggestedFixLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CinematicDiagnostic &&
          other.code == code &&
          other.severity == severity &&
          other.message == message &&
          other.cinematicId == cinematicId &&
          other.target == target &&
          other.stepId == stepId &&
          other.referenceId == referenceId &&
          other.suggestedFixLabel == suggestedFixLabel;

  @override
  int get hashCode => Object.hash(
        code,
        severity,
        message,
        cinematicId,
        target,
        stepId,
        referenceId,
        suggestedFixLabel,
      );
}

final class CinematicDiagnosticsReport {
  CinematicDiagnosticsReport({
    required List<CinematicDiagnostic> diagnostics,
  }) : _diagnostics = List<CinematicDiagnostic>.unmodifiable(diagnostics);

  final List<CinematicDiagnostic> _diagnostics;

  List<CinematicDiagnostic> get diagnostics => _diagnostics;

  int get count => _diagnostics.length;

  int get errorCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == CinematicDiagnosticSeverity.error)
      .length;

  int get warningCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == CinematicDiagnosticSeverity.warning)
      .length;

  int get infoCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == CinematicDiagnosticSeverity.info)
      .length;

  bool get hasDiagnostics => _diagnostics.isNotEmpty;

  bool get hasErrors => errorCount > 0;

  List<CinematicDiagnostic> byCode(CinematicDiagnosticCode code) {
    return List<CinematicDiagnostic>.unmodifiable(
      _diagnostics.where((diagnostic) => diagnostic.code == code),
    );
  }
}

CinematicDiagnosticsReport diagnoseCinematicAsset(CinematicAsset cinematic) {
  final diagnostics = <CinematicDiagnostic>[];
  _diagnoseCinematicShape(cinematic, diagnostics);
  _diagnoseTimeline(cinematic, diagnostics);
  _diagnoseLegacyBridge(cinematic, diagnostics);
  return CinematicDiagnosticsReport(diagnostics: diagnostics);
}

CinematicDiagnosticsReport diagnoseCinematics(
  List<CinematicAsset> cinematics,
) {
  final diagnostics = <CinematicDiagnostic>[];
  final firstById = <String, CinematicAsset>{};
  for (final cinematic in cinematics) {
    diagnostics.addAll(diagnoseCinematicAsset(cinematic).diagnostics);
    final previous = firstById[cinematic.id];
    if (previous == null) {
      firstById[cinematic.id] = cinematic;
    } else {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.cinematicDuplicateId,
          severity: CinematicDiagnosticSeverity.error,
          message: 'Plusieurs CinematicAsset utilisent le même id.',
          cinematicId: cinematic.id,
          target: CinematicDiagnosticTarget.cinematic,
          suggestedFixLabel: 'Renommer ou fusionner les cinématiques.',
        ),
      );
    }
  }
  return CinematicDiagnosticsReport(diagnostics: diagnostics);
}

CinematicDiagnosticsReport diagnoseCinematicsAgainstProject(
  ProjectManifest project,
) {
  final diagnostics =
      diagnoseCinematics(project.cinematics).diagnostics.toList(growable: true);
  final storylineIds =
      project.storylines.map((storyline) => storyline.id).toSet();
  final chapterIdsByStoryline = {
    for (final storyline in project.storylines)
      storyline.id: storyline.chapters.map((chapter) => chapter.id).toSet(),
  };
  final allChapterIds = {
    for (final storyline in project.storylines)
      for (final chapter in storyline.chapters) chapter.id,
  };
  final mapIds = project.maps.map((map) => map.id).toSet();

  for (final cinematic in project.cinematics) {
    final storylineId = cinematic.storylineId;
    if (storylineId != null &&
        storylineIds.isNotEmpty &&
        !storylineIds.contains(storylineId)) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.cinematicUnknownStorylineRef,
          severity: CinematicDiagnosticSeverity.warning,
          message: 'La cinématique référence une storyline inconnue.',
          cinematicId: cinematic.id,
          referenceId: storylineId,
          target: CinematicDiagnosticTarget.reference,
          suggestedFixLabel: 'Choisir une storyline existante.',
        ),
      );
    }

    final chapterId = cinematic.chapterId;
    if (chapterId != null && allChapterIds.isNotEmpty) {
      final knownChapters = storylineId == null
          ? allChapterIds
          : chapterIdsByStoryline[storylineId] ?? const <String>{};
      if (!knownChapters.contains(chapterId)) {
        diagnostics.add(
          CinematicDiagnostic(
            code: CinematicDiagnosticCode.cinematicUnknownChapterRef,
            severity: CinematicDiagnosticSeverity.warning,
            message: 'La cinématique référence un chapitre inconnu.',
            cinematicId: cinematic.id,
            referenceId: chapterId,
            target: CinematicDiagnosticTarget.reference,
            suggestedFixLabel: 'Choisir un chapitre existant.',
          ),
        );
      }
    }

    final mapId = cinematic.mapId;
    if (mapId != null && mapIds.isNotEmpty && !mapIds.contains(mapId)) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.cinematicUnknownMapRef,
          severity: CinematicDiagnosticSeverity.warning,
          message: 'La cinématique référence une map inconnue.',
          cinematicId: cinematic.id,
          referenceId: mapId,
          target: CinematicDiagnosticTarget.reference,
          suggestedFixLabel: 'Choisir une map existante.',
        ),
      );
    }
  }

  return CinematicDiagnosticsReport(diagnostics: diagnostics);
}

void _diagnoseCinematicShape(
  CinematicAsset cinematic,
  List<CinematicDiagnostic> diagnostics,
) {
  if (cinematic.id.trim().isEmpty) {
    diagnostics.add(
      CinematicDiagnostic(
        code: CinematicDiagnosticCode.cinematicMissingId,
        severity: CinematicDiagnosticSeverity.error,
        message: 'La cinématique doit avoir un id stable.',
        cinematicId: cinematic.id,
        target: CinematicDiagnosticTarget.cinematic,
        suggestedFixLabel: 'Définir un id de cinématique.',
      ),
    );
  }
  if (cinematic.title.trim().isEmpty) {
    diagnostics.add(
      CinematicDiagnostic(
        code: CinematicDiagnosticCode.cinematicMissingTitle,
        severity: CinematicDiagnosticSeverity.error,
        message: 'La cinématique doit avoir un titre lisible.',
        cinematicId: cinematic.id,
        target: CinematicDiagnosticTarget.cinematic,
        suggestedFixLabel: 'Renseigner un titre auteur.',
      ),
    );
  }
  if (cinematic.title == cinematic.id) {
    diagnostics.add(
      CinematicDiagnostic(
        code: CinematicDiagnosticCode.cinematicTechnicalLabel,
        severity: CinematicDiagnosticSeverity.warning,
        message: 'Le titre de la cinématique ressemble à un id technique.',
        cinematicId: cinematic.id,
        target: CinematicDiagnosticTarget.cinematic,
        suggestedFixLabel: 'Utiliser un titre lisible par un auteur.',
      ),
    );
  }
}

void _diagnoseTimeline(
  CinematicAsset cinematic,
  List<CinematicDiagnostic> diagnostics,
) {
  if (cinematic.timeline.steps.isEmpty) {
    diagnostics.add(
      CinematicDiagnostic(
        code: CinematicDiagnosticCode.cinematicEmptyTimeline,
        severity: CinematicDiagnosticSeverity.warning,
        message: 'La timeline de cinématique est vide.',
        cinematicId: cinematic.id,
        target: CinematicDiagnosticTarget.timeline,
        suggestedFixLabel: 'Ajouter au moins une étape visuelle.',
      ),
    );
    return;
  }

  final stepIds = <String>{};
  final requiredActorIds =
      cinematic.requiredActors.map((actor) => actor.actorId).toSet();
  final movementTargetIds =
      cinematic.movementTargets.map((target) => target.targetId).toSet();
  for (final step in cinematic.timeline.steps) {
    if (!stepIds.add(step.id)) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.cinematicDuplicateStepId,
          severity: CinematicDiagnosticSeverity.error,
          message: 'Deux étapes de timeline utilisent le même id.',
          cinematicId: cinematic.id,
          stepId: step.id,
          target: CinematicDiagnosticTarget.step,
          suggestedFixLabel: 'Renommer une étape de timeline.',
        ),
      );
    }
    _diagnoseStepDuration(cinematic, step, diagnostics);
    final legacyKind = step.metadata['legacy.kind']?.trim() ??
        step.metadata['legacyKind']?.trim();
    if (legacyKind != null &&
        _forbiddenGameplayStepKinds.contains(legacyKind)) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.cinematicUnsupportedGameplayStep,
          severity: CinematicDiagnosticSeverity.error,
          message:
              'Une étape legacy transporte une action de gameplay interdite dans une Cinematic.',
          cinematicId: cinematic.id,
          stepId: step.id,
          referenceId: legacyKind,
          target: CinematicDiagnosticTarget.step,
          suggestedFixLabel:
              'Déplacer cette conséquence dans une Scene ou une Action.',
        ),
      );
    }
    final actorId = step.actorId;
    if (actorId != null && !requiredActorIds.contains(actorId)) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.cinematicUnknownActorRef,
          severity: CinematicDiagnosticSeverity.error,
          message: 'Une étape cinematic référence un acteur inconnu.',
          cinematicId: cinematic.id,
          stepId: step.id,
          referenceId: actorId,
          target: CinematicDiagnosticTarget.reference,
          suggestedFixLabel:
              'Choisir un acteur requis existant dans la cinématique.',
        ),
      );
    }
    if (step.kind == CinematicTimelineStepKind.actorMove) {
      _diagnoseActorMoveStep(
        cinematic,
        step,
        movementTargetIds: movementTargetIds,
        diagnostics: diagnostics,
      );
    }
  }
}

void _diagnoseStepDuration(
  CinematicAsset cinematic,
  CinematicTimelineStep step,
  List<CinematicDiagnostic> diagnostics,
) {
  if (step.kind == CinematicTimelineStepKind.actorMove) {
    return;
  }
  final durationMs = step.durationMs;
  if (durationMs == null) {
    return;
  }
  final minDurationMs = _diagnosticDurationMinimumMs(step);
  final isBelowMinimum =
      minDurationMs == null ? durationMs < 0 : durationMs < minDurationMs;
  final isAboveMaximum = durationMs > cinematicTimelineMaximumDurationMs;
  if (!isBelowMinimum && !isAboveMaximum) {
    return;
  }
  final message = minDurationMs == null
      ? 'Une durée cinematic ne peut pas être négative.'
      : 'Une durée cinematic doit être comprise entre '
          '$minDurationMs ms et $cinematicTimelineMaximumDurationMs ms.';
  final suggestedFixLabel = minDurationMs == null
      ? 'Utiliser une durée en millisecondes positive.'
      : 'Choisir une durée entre '
          '$minDurationMs ms et $cinematicTimelineMaximumDurationMs ms.';
  diagnostics.add(
    CinematicDiagnostic(
      code: CinematicDiagnosticCode.cinematicInvalidStepDuration,
      severity: CinematicDiagnosticSeverity.error,
      message: message,
      cinematicId: cinematic.id,
      stepId: step.id,
      target: CinematicDiagnosticTarget.step,
      suggestedFixLabel: suggestedFixLabel,
    ),
  );
}

int? _diagnosticDurationMinimumMs(CinematicTimelineStep step) {
  if (cinematicTimelineBasicBlockKindOf(step) != null ||
      isCinematicTimelineActorFacingStep(step)) {
    return cinematicTimelineMinimumDurationMs;
  }
  return null;
}

void _diagnoseActorMoveStep(
  CinematicAsset cinematic,
  CinematicTimelineStep step, {
  required Set<String> movementTargetIds,
  required List<CinematicDiagnostic> diagnostics,
}) {
  final actorId = step.actorId;
  if (actorId == null || actorId.trim().isEmpty) {
    diagnostics.add(
      CinematicDiagnostic(
        code: CinematicDiagnosticCode.cinematicActorMoveMissingActorRef,
        severity: CinematicDiagnosticSeverity.error,
        message: 'Un déplacement acteur doit référencer un acteur requis.',
        cinematicId: cinematic.id,
        stepId: step.id,
        target: CinematicDiagnosticTarget.reference,
        suggestedFixLabel: 'Choisir un acteur requis existant.',
      ),
    );
  }

  final targetId = step.targetId;
  if (targetId == null || targetId.trim().isEmpty) {
    diagnostics.add(
      CinematicDiagnostic(
        code: CinematicDiagnosticCode.cinematicActorMoveMissingTargetRef,
        severity: CinematicDiagnosticSeverity.error,
        message:
            'Un déplacement acteur doit référencer une cible authoring stable.',
        cinematicId: cinematic.id,
        stepId: step.id,
        target: CinematicDiagnosticTarget.reference,
        suggestedFixLabel: 'Choisir une cible de déplacement existante.',
      ),
    );
  } else if (!movementTargetIds.contains(targetId)) {
    diagnostics.add(
      CinematicDiagnostic(
        code: CinematicDiagnosticCode.cinematicUnknownMovementTargetRef,
        severity: CinematicDiagnosticSeverity.error,
        message: 'Un déplacement acteur référence une cible inconnue.',
        cinematicId: cinematic.id,
        stepId: step.id,
        referenceId: targetId,
        target: CinematicDiagnosticTarget.reference,
        suggestedFixLabel: 'Choisir une cible de déplacement existante.',
      ),
    );
  }

  final durationMs = step.durationMs;
  if (durationMs == null ||
      durationMs < cinematicTimelineActorMoveMinimumDurationMs ||
      durationMs > cinematicTimelineMaximumDurationMs) {
    diagnostics.add(
      CinematicDiagnostic(
        code: CinematicDiagnosticCode.cinematicActorMoveInvalidDuration,
        severity: CinematicDiagnosticSeverity.error,
        message: 'Un déplacement acteur doit durer entre '
            '$cinematicTimelineActorMoveMinimumDurationMs ms et '
            '$cinematicTimelineMaximumDurationMs ms.',
        cinematicId: cinematic.id,
        stepId: step.id,
        target: CinematicDiagnosticTarget.step,
        suggestedFixLabel: 'Choisir une durée entre '
            '$cinematicTimelineActorMoveMinimumDurationMs ms et '
            '$cinematicTimelineMaximumDurationMs ms.',
      ),
    );
  }

  if (cinematicTimelineActorMovementModeOf(step) == null) {
    final mode =
        step.metadata[cinematicTimelineActorMovementModeMetadataKey]?.trim();
    diagnostics.add(
      CinematicDiagnostic(
        code: CinematicDiagnosticCode.cinematicActorMoveInvalidMovementMode,
        severity: CinematicDiagnosticSeverity.error,
        message:
            'Un déplacement acteur doit utiliser un mode marche ou course.',
        cinematicId: cinematic.id,
        stepId: step.id,
        referenceId: mode,
        target: CinematicDiagnosticTarget.step,
        suggestedFixLabel: 'Choisir marche ou course.',
      ),
    );
  }

  if (cinematicTimelineActorPathModeOf(step) !=
      CinematicTimelineActorPathMode.direct) {
    final pathMode =
        step.metadata[cinematicTimelineActorPathModeMetadataKey]?.trim();
    diagnostics.add(
      CinematicDiagnostic(
        code: CinematicDiagnosticCode.cinematicActorMoveUnsupportedPathMode,
        severity: CinematicDiagnosticSeverity.error,
        message: 'Le seul chemin supporté en V0 est direct.',
        cinematicId: cinematic.id,
        stepId: step.id,
        referenceId: pathMode,
        target: CinematicDiagnosticTarget.step,
        suggestedFixLabel: 'Revenir au pathMode direct.',
      ),
    );
  }
}

void _diagnoseLegacyBridge(
  CinematicAsset cinematic,
  List<CinematicDiagnostic> diagnostics,
) {
  final bridge = cinematic.legacyBridge;
  if (bridge == null) {
    return;
  }
  diagnostics.add(
    CinematicDiagnostic(
      code: CinematicDiagnosticCode.cinematicLegacyBridge,
      severity: CinematicDiagnosticSeverity.warning,
      message:
          'Cette Cinematic porte un bridge legacy ; elle reste canonique, mais la provenance doit être revue.',
      cinematicId: cinematic.id,
      referenceId: bridge.scenarioId,
      target: CinematicDiagnosticTarget.legacyBridge,
      suggestedFixLabel: 'Vérifier la timeline canonique avant runtime.',
    ),
  );
  if (bridge.sourceKind == CinematicLegacyBridgeSourceKind.scenarioAsset ||
      bridge.sourceKind == CinematicLegacyBridgeSourceKind.cutsceneStudio) {
    diagnostics.add(
      CinematicDiagnostic(
        code: CinematicDiagnosticCode.cinematicScenarioBridgeNotCanonical,
        severity: CinematicDiagnosticSeverity.info,
        message:
            'Le bridge Scenario/Cutscene n’est pas la source de vérité runtime Cinematic V1.',
        cinematicId: cinematic.id,
        referenceId: bridge.scenarioId,
        target: CinematicDiagnosticTarget.legacyBridge,
        suggestedFixLabel:
            'Conserver le bridge comme provenance, pas comme exécution.',
      ),
    );
  }
}

const Set<String> _forbiddenGameplayStepKinds = {
  'branch',
  'condition',
  'battle',
  'setFact',
  'markEventConsumed',
  'completeStoryStep',
  'giveItem',
  'teleport',
  'script',
  'scenario',
  'worldRule',
};
