import '../authoring/cinematic_authoring_operations.dart';
import '../models/cinematic_asset.dart';
import '../models/enums.dart';
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
  stageMapUnknown,
  stageBackdropRequiresMap,
  actorBindingUnknownActor,
  actorBindingMissing,
  actorBindingDuplicatePlayer,
  actorBindingRequiresStageMap,
  actorBindingMapEntityMissingSource,
  actorInitialPlacementUnknownActor,
  actorInitialPlacementMissing,
  actorInitialPlacementTargetUnknown,
  actorInitialPlacementRequiresBinding,
  movementTargetBindingUnknownTarget,
  movementTargetBindingRequiresStageMap,
  movementTargetBindingMissingSource,
  actorAppearanceBindingUnknownActor,
  actorAppearanceBindingUnknownCharacter,
  actorAppearanceBindingRequiresCinematicOnly,
  cinematicOnlyCharacterMissing,
  characterLibraryUnavailable,
  characterAssetMissingSprite,
  characterAssetMissingPreviewData,
  cinematicLegacyBridge,
  cinematicScenarioBridgeNotCanonical,
  stagePointDuplicateId,
  stagePointEmptyId,
  stagePointEmptyLabel,
  stagePointInvalidCoordinate,
  stagePointOutOfMap,
  stagePointWithoutStageMap,
  actorInitialPlacementStagePointMissing,
  actorInitialPlacementStagePointWithoutStageMap,
  actorInitialPlacementStagePointOutOfMap,
  movementTargetBindingStagePointMissing,
  movementTargetBindingStagePointWithoutStageMap,
  movementTargetBindingStagePointOutOfMap,
}

enum CinematicDiagnosticTarget {
  cinematic,
  timeline,
  step,
  reference,
  stageContext,
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

CinematicDiagnosticsReport diagnoseCinematicAsset(
  CinematicAsset cinematic, {
  int? mapWidth,
  int? mapHeight,
}) {
  final diagnostics = <CinematicDiagnostic>[];
  _diagnoseCinematicShape(cinematic, diagnostics);
  _diagnoseStageContext(
    cinematic,
    diagnostics,
    mapWidth: mapWidth,
    mapHeight: mapHeight,
  );
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
  final charactersById = {
    for (final character in project.characters) character.id: character,
  };

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
          code: CinematicDiagnosticCode.stageMapUnknown,
          severity: CinematicDiagnosticSeverity.error,
          message: 'La cinématique utilise une map stage inconnue.',
          cinematicId: cinematic.id,
          referenceId: mapId,
          target: CinematicDiagnosticTarget.stageContext,
          suggestedFixLabel: 'Choisir une map existante pour le stage.',
        ),
      );
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

    _diagnoseCinematicCharacterBindingsAgainstProject(
      cinematic,
      charactersById: charactersById,
      diagnostics: diagnostics,
    );
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

void _diagnoseStageContext(
  CinematicAsset cinematic,
  List<CinematicDiagnostic> diagnostics, {
  int? mapWidth,
  int? mapHeight,
}) {
  final stageContext = cinematic.stageContext;
  if (stageContext == null) {
    return;
  }
  final requiredActorIds =
      cinematic.requiredActors.map((actor) => actor.actorId).toSet();
  final movementTargetIds =
      cinematic.movementTargets.map((target) => target.targetId).toSet();

  if (stageContext.backdropMode == CinematicStageBackdropMode.projectMap &&
      cinematic.mapId == null) {
    diagnostics.add(
      CinematicDiagnostic(
        code: CinematicDiagnosticCode.stageBackdropRequiresMap,
        severity: CinematicDiagnosticSeverity.warning,
        message: 'Le décor projectMap nécessite une map stage pour la preview.',
        cinematicId: cinematic.id,
        target: CinematicDiagnosticTarget.stageContext,
        suggestedFixLabel: 'Choisir une map ou repasser le décor sur none.',
      ),
    );
  }

  final bindingActorIds = <String>{};
  final actorBindingsById = <String, CinematicActorBinding>{};
  var playerBindingCount = 0;
  final mapEntityBoundActorIds = <String>{};
  for (final binding in stageContext.actorBindings) {
    bindingActorIds.add(binding.actorId);
    actorBindingsById.putIfAbsent(binding.actorId, () => binding);
    if (!requiredActorIds.contains(binding.actorId)) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.actorBindingUnknownActor,
          severity: CinematicDiagnosticSeverity.error,
          message: 'Un binding stage référence un acteur cinematic inconnu.',
          cinematicId: cinematic.id,
          referenceId: binding.actorId,
          target: CinematicDiagnosticTarget.stageContext,
          suggestedFixLabel: 'Choisir un acteur requis existant.',
        ),
      );
    }
    if (binding.kind == CinematicActorBindingKind.player) {
      playerBindingCount++;
      if (playerBindingCount > 1) {
        diagnostics.add(
          CinematicDiagnostic(
            code: CinematicDiagnosticCode.actorBindingDuplicatePlayer,
            severity: CinematicDiagnosticSeverity.error,
            message:
                'Une cinématique V0 ne peut binder qu’un seul acteur au joueur.',
            cinematicId: cinematic.id,
            referenceId: binding.actorId,
            target: CinematicDiagnosticTarget.stageContext,
            suggestedFixLabel: 'Garder un seul binding joueur.',
          ),
        );
      }
    }
    if (binding.kind == CinematicActorBindingKind.mapEntity) {
      mapEntityBoundActorIds.add(binding.actorId);
      if (cinematic.mapId == null) {
        diagnostics.add(
          CinematicDiagnostic(
            code: CinematicDiagnosticCode.actorBindingRequiresStageMap,
            severity: CinematicDiagnosticSeverity.warning,
            message:
                'Un binding vers une entité de map nécessite une map stage.',
            cinematicId: cinematic.id,
            referenceId: binding.actorId,
            target: CinematicDiagnosticTarget.stageContext,
            suggestedFixLabel: 'Choisir une map stage ou changer le binding.',
          ),
        );
      }
      if (binding.mapEntityId == null) {
        diagnostics.add(
          CinematicDiagnostic(
            code: CinematicDiagnosticCode.actorBindingMapEntityMissingSource,
            severity: CinematicDiagnosticSeverity.error,
            message: 'Un binding mapEntity doit référencer une entité de map.',
            cinematicId: cinematic.id,
            referenceId: binding.actorId,
            target: CinematicDiagnosticTarget.stageContext,
            suggestedFixLabel: 'Choisir une entité de map.',
          ),
        );
      }
    }
  }

  for (final actorId in requiredActorIds) {
    if (!bindingActorIds.contains(actorId)) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.actorBindingMissing,
          severity: CinematicDiagnosticSeverity.warning,
          message:
              'Un acteur requis n’a pas encore de binding stage pour la preview.',
          cinematicId: cinematic.id,
          referenceId: actorId,
          target: CinematicDiagnosticTarget.stageContext,
          suggestedFixLabel: 'Binder l’acteur ou le laisser en brouillon.',
        ),
      );
    }
  }

  final appearanceActorIds = <String>{};
  for (final binding in stageContext.actorAppearanceBindings) {
    appearanceActorIds.add(binding.actorId);
    if (!requiredActorIds.contains(binding.actorId)) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.actorAppearanceBindingUnknownActor,
          severity: CinematicDiagnosticSeverity.error,
          message:
              'Une apparence Character Library référence un acteur inconnu.',
          cinematicId: cinematic.id,
          referenceId: binding.actorId,
          target: CinematicDiagnosticTarget.stageContext,
          suggestedFixLabel: 'Choisir un acteur cinematicOnly existant.',
        ),
      );
    }
    final actorBinding = actorBindingsById[binding.actorId];
    if (actorBinding == null ||
        actorBinding.kind != CinematicActorBindingKind.cinematicOnly) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode
              .actorAppearanceBindingRequiresCinematicOnly,
          severity: CinematicDiagnosticSeverity.error,
          message:
              'Une apparence Character Library est réservée aux acteurs cinematicOnly en V0.',
          cinematicId: cinematic.id,
          referenceId: binding.actorId,
          target: CinematicDiagnosticTarget.stageContext,
          suggestedFixLabel:
              'Passer l’acteur en cinematicOnly ou retirer cette apparence.',
        ),
      );
    }
  }

  for (final binding in stageContext.actorBindings) {
    if (binding.kind == CinematicActorBindingKind.cinematicOnly &&
        requiredActorIds.contains(binding.actorId) &&
        !appearanceActorIds.contains(binding.actorId)) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.cinematicOnlyCharacterMissing,
          severity: CinematicDiagnosticSeverity.warning,
          message:
              'Un acteur cinematicOnly n’a pas encore de personnage Character Library.',
          cinematicId: cinematic.id,
          referenceId: binding.actorId,
          target: CinematicDiagnosticTarget.stageContext,
          suggestedFixLabel:
              'Choisir un personnage Character Library pour la future preview.',
        ),
      );
    }
  }

  final placementActorIds = <String>{};
  for (final placement in stageContext.initialPlacements) {
    placementActorIds.add(placement.actorId);
    if (!requiredActorIds.contains(placement.actorId)) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.actorInitialPlacementUnknownActor,
          severity: CinematicDiagnosticSeverity.error,
          message:
              'Un placement initial référence un acteur cinematic inconnu.',
          cinematicId: cinematic.id,
          referenceId: placement.actorId,
          target: CinematicDiagnosticTarget.stageContext,
          suggestedFixLabel: 'Choisir un acteur requis existant.',
        ),
      );
    }
    if (placement.kind ==
            CinematicActorInitialPlacementKind.fromMovementTarget &&
        (placement.targetId == null ||
            !movementTargetIds.contains(placement.targetId))) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.actorInitialPlacementTargetUnknown,
          severity: CinematicDiagnosticSeverity.error,
          message:
              'Un placement initial référence une cible de mouvement inconnue.',
          cinematicId: cinematic.id,
          referenceId: placement.targetId,
          target: CinematicDiagnosticTarget.stageContext,
          suggestedFixLabel: 'Choisir une cible cinematic existante.',
        ),
      );
    }
    if (placement.kind == CinematicActorInitialPlacementKind.fromMapEntity &&
        !mapEntityBoundActorIds.contains(placement.actorId)) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.actorInitialPlacementRequiresBinding,
          severity: CinematicDiagnosticSeverity.warning,
          message:
              'Un placement fromMapEntity nécessite un binding acteur mapEntity.',
          cinematicId: cinematic.id,
          referenceId: placement.actorId,
          target: CinematicDiagnosticTarget.stageContext,
          suggestedFixLabel: 'Binder cet acteur à une entité de map.',
        ),
      );
    }
    if (placement.kind == CinematicActorInitialPlacementKind.stagePoint) {
      final pointId = placement.stagePointId?.trim();
      CinematicStagePoint? point;
      if (pointId != null && pointId.isNotEmpty) {
        for (final p in stageContext.stagePoints) {
          if (p.id == pointId) {
            point = p;
            break;
          }
        }
      }
      if (point == null) {
        diagnostics.add(
          CinematicDiagnostic(
            code: CinematicDiagnosticCode.actorInitialPlacementStagePointMissing,
            severity: CinematicDiagnosticSeverity.error,
            message:
                'Le placement initial de l’acteur "${placement.actorId}" référence un Stage Point inexistant "$pointId".',
            cinematicId: cinematic.id,
            referenceId: placement.actorId,
            target: CinematicDiagnosticTarget.stageContext,
            suggestedFixLabel: 'Choisir un Stage Point existant ou le recréer.',
          ),
        );
      } else {
        if (cinematic.mapId == null) {
          diagnostics.add(
            CinematicDiagnostic(
              code: CinematicDiagnosticCode
                  .actorInitialPlacementStagePointWithoutStageMap,
              severity: CinematicDiagnosticSeverity.warning,
              message:
                  'Le placement initial de l’acteur "${placement.actorId}" référence un Stage Point alors qu’aucune map stage n’est définie.',
              cinematicId: cinematic.id,
              referenceId: placement.actorId,
              target: CinematicDiagnosticTarget.stageContext,
              suggestedFixLabel: 'Définir une map stage pour la cinématique.',
            ),
          );
        } else if (mapWidth != null && mapHeight != null) {
          if (point.x < 0 ||
              point.x >= mapWidth ||
              point.y < 0 ||
              point.y >= mapHeight) {
            diagnostics.add(
              CinematicDiagnostic(
                code: CinematicDiagnosticCode.actorInitialPlacementStagePointOutOfMap,
                severity: CinematicDiagnosticSeverity.error,
                message:
                    'Le placement initial de l’acteur "${placement.actorId}" référence un Stage Point en dehors des limites de la map ($mapWidth × $mapHeight).',
                cinematicId: cinematic.id,
                referenceId: placement.actorId,
                target: CinematicDiagnosticTarget.stageContext,
                suggestedFixLabel:
                    'Repositionner le Stage Point dans les limites de la map.',
              ),
            );
          }
        }
      }
    }
  }

  for (final actorId in requiredActorIds) {
    if (!placementActorIds.contains(actorId)) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.actorInitialPlacementMissing,
          severity: CinematicDiagnosticSeverity.warning,
          message:
              'Un acteur requis n’a pas encore de position initiale preview.',
          cinematicId: cinematic.id,
          referenceId: actorId,
          target: CinematicDiagnosticTarget.stageContext,
          suggestedFixLabel:
              'Définir une position initiale ou rester en draft.',
        ),
      );
    }
  }

  for (final binding in stageContext.movementTargetBindings) {
    if (!movementTargetIds.contains(binding.targetId)) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.movementTargetBindingUnknownTarget,
          severity: CinematicDiagnosticSeverity.error,
          message:
              'Un binding de cible map-aware référence une cible inconnue.',
          cinematicId: cinematic.id,
          referenceId: binding.targetId,
          target: CinematicDiagnosticTarget.stageContext,
          suggestedFixLabel: 'Choisir une cible de mouvement existante.',
        ),
      );
    }
    if (_movementTargetBindingRequiresStageMap(binding) &&
        cinematic.mapId == null) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.movementTargetBindingRequiresStageMap,
          severity: CinematicDiagnosticSeverity.warning,
          message:
              'Un binding de cible vers mapEntity/mapEvent nécessite une map stage.',
          cinematicId: cinematic.id,
          referenceId: binding.targetId,
          target: CinematicDiagnosticTarget.stageContext,
          suggestedFixLabel:
              'Choisir une map stage ou garder une cible abstraite.',
        ),
      );
    }
    if (_movementTargetBindingRequiresStageMap(binding) &&
        binding.sourceId == null) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.movementTargetBindingMissingSource,
          severity: CinematicDiagnosticSeverity.error,
          message:
              'Un binding de cible map-aware doit référencer une source map.',
          cinematicId: cinematic.id,
          referenceId: binding.targetId,
          target: CinematicDiagnosticTarget.stageContext,
          suggestedFixLabel: 'Choisir une entité ou un event de map.',
        ),
      );
    }
    if (binding.kind == CinematicMovementTargetBindingKind.stagePoint) {
      final pointId = binding.sourceId?.trim();
      CinematicStagePoint? point;
      if (pointId != null && pointId.isNotEmpty) {
        for (final p in stageContext.stagePoints) {
          if (p.id == pointId) {
            point = p;
            break;
          }
        }
      }
      if (point == null) {
        diagnostics.add(
          CinematicDiagnostic(
            code: CinematicDiagnosticCode.movementTargetBindingStagePointMissing,
            severity: CinematicDiagnosticSeverity.error,
            message:
                'La cible de mouvement "${binding.targetId}" référence un Stage Point inexistant "$pointId".',
            cinematicId: cinematic.id,
            referenceId: binding.targetId,
            target: CinematicDiagnosticTarget.stageContext,
            suggestedFixLabel: 'Choisir un Stage Point existant ou le recréer.',
          ),
        );
      } else {
        if (cinematic.mapId == null) {
          diagnostics.add(
            CinematicDiagnostic(
              code: CinematicDiagnosticCode
                  .movementTargetBindingStagePointWithoutStageMap,
              severity: CinematicDiagnosticSeverity.warning,
              message:
                  'La cible de mouvement "${binding.targetId}" référence un Stage Point alors qu’aucune map stage n’est définie.',
              cinematicId: cinematic.id,
              referenceId: binding.targetId,
              target: CinematicDiagnosticTarget.stageContext,
              suggestedFixLabel: 'Définir une map stage pour la cinématique.',
            ),
          );
        } else if (mapWidth != null && mapHeight != null) {
          if (point.x < 0 ||
              point.x >= mapWidth ||
              point.y < 0 ||
              point.y >= mapHeight) {
            diagnostics.add(
              CinematicDiagnostic(
                code: CinematicDiagnosticCode
                    .movementTargetBindingStagePointOutOfMap,
                severity: CinematicDiagnosticSeverity.error,
                message:
                    'La cible de mouvement "${binding.targetId}" référence un Stage Point en dehors des limites de la map ($mapWidth × $mapHeight).',
                cinematicId: cinematic.id,
                referenceId: binding.targetId,
                target: CinematicDiagnosticTarget.stageContext,
                suggestedFixLabel:
                    'Repositionner le Stage Point dans les limites de la map.',
              ),
            );
          }
        }
      }
    }
  }

  if (stageContext.stagePoints.isNotEmpty) {
    if (cinematic.mapId == null) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.stagePointWithoutStageMap,
          severity: CinematicDiagnosticSeverity.warning,
          message:
              'Des Stage Points sont présents mais aucune map stage n’est définie.',
          cinematicId: cinematic.id,
          target: CinematicDiagnosticTarget.stageContext,
          suggestedFixLabel: 'Choisir une map stage ou retirer les points.',
        ),
      );
    }

    final seenPointIds = <String>{};
    for (final point in stageContext.stagePoints) {
      final id = point.id.trim();
      final label = point.label.trim();
      if (id.isEmpty) {
        diagnostics.add(
          CinematicDiagnostic(
            code: CinematicDiagnosticCode.stagePointEmptyId,
            severity: CinematicDiagnosticSeverity.error,
            message: 'Un Stage Point a un id vide.',
            cinematicId: cinematic.id,
            target: CinematicDiagnosticTarget.stageContext,
            suggestedFixLabel: 'Définir un id stable.',
          ),
        );
      } else if (!seenPointIds.add(id)) {
        diagnostics.add(
          CinematicDiagnostic(
            code: CinematicDiagnosticCode.stagePointDuplicateId,
            severity: CinematicDiagnosticSeverity.error,
            message:
                'Plusieurs Stage Points utilisent le même id : "$id".',
            cinematicId: cinematic.id,
            referenceId: id,
            target: CinematicDiagnosticTarget.stageContext,
            suggestedFixLabel:
                'Renommer le Stage Point pour avoir un id unique.',
          ),
        );
      }

      if (label.isEmpty) {
        diagnostics.add(
          CinematicDiagnostic(
            code: CinematicDiagnosticCode.stagePointEmptyLabel,
            severity: CinematicDiagnosticSeverity.error,
            message: 'Le Stage Point "$id" a un label vide.',
            cinematicId: cinematic.id,
            referenceId: id,
            target: CinematicDiagnosticTarget.stageContext,
            suggestedFixLabel: 'Renseigner un label lisible.',
          ),
        );
      }

      if (!point.x.isFinite ||
          point.x.isNaN ||
          !point.y.isFinite ||
          point.y.isNaN) {
        diagnostics.add(
          CinematicDiagnostic(
            code: CinematicDiagnosticCode.stagePointInvalidCoordinate,
            severity: CinematicDiagnosticSeverity.error,
            message:
                'Le Stage Point "$id" a des coordonnées non finies.',
            cinematicId: cinematic.id,
            referenceId: id,
            target: CinematicDiagnosticTarget.stageContext,
            suggestedFixLabel:
                'Corriger les coordonnées pour qu’elles soient finies.',
          ),
        );
      }

      if (mapWidth != null && mapHeight != null) {
        if (point.x < 0 ||
            point.x >= mapWidth ||
            point.y < 0 ||
            point.y >= mapHeight) {
          diagnostics.add(
            CinematicDiagnostic(
              code: CinematicDiagnosticCode.stagePointOutOfMap,
              severity: CinematicDiagnosticSeverity.error,
              message:
                  'Le Stage Point "$id" (${point.x}, ${point.y}) est en dehors des limites de la map ($mapWidth × $mapHeight).',
              cinematicId: cinematic.id,
              referenceId: id,
              target: CinematicDiagnosticTarget.stageContext,
              suggestedFixLabel:
                  'Repositionner le Stage Point dans les limites de la map.',
            ),
          );
        }
      }
    }
  }
}

void _diagnoseCinematicCharacterBindingsAgainstProject(
  CinematicAsset cinematic, {
  required Map<String, ProjectCharacterEntry> charactersById,
  required List<CinematicDiagnostic> diagnostics,
}) {
  final stageContext = cinematic.stageContext;
  if (stageContext == null) {
    return;
  }

  final hasCinematicOnlyActor = stageContext.actorBindings.any(
    (binding) => binding.kind == CinematicActorBindingKind.cinematicOnly,
  );
  if (hasCinematicOnlyActor && charactersById.isEmpty) {
    for (final binding in stageContext.actorBindings) {
      if (binding.kind != CinematicActorBindingKind.cinematicOnly) {
        continue;
      }
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.characterLibraryUnavailable,
          severity: CinematicDiagnosticSeverity.warning,
          message:
              'La Character Library est vide alors qu’un acteur cinematicOnly en dépendra.',
          cinematicId: cinematic.id,
          referenceId: binding.actorId,
          target: CinematicDiagnosticTarget.stageContext,
          suggestedFixLabel:
              'Créer un personnage dans la Character Library avant la preview.',
        ),
      );
    }
  }

  for (final binding in stageContext.actorAppearanceBindings) {
    final character = charactersById[binding.characterId];
    if (character == null) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.actorAppearanceBindingUnknownCharacter,
          severity: CinematicDiagnosticSeverity.error,
          message:
              'Une apparence cinematic référence un personnage Character Library inconnu.',
          cinematicId: cinematic.id,
          referenceId: binding.characterId,
          target: CinematicDiagnosticTarget.stageContext,
          suggestedFixLabel: 'Choisir un personnage existant.',
        ),
      );
      continue;
    }

    if (character.tilesetId.trim().isEmpty) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.characterAssetMissingSprite,
          severity: CinematicDiagnosticSeverity.warning,
          message:
              'Le personnage choisi n’a pas de tileset utilisable pour la future preview.',
          cinematicId: cinematic.id,
          referenceId: character.id,
          target: CinematicDiagnosticTarget.stageContext,
          suggestedFixLabel:
              'Associer un tileset au personnage Character Library.',
        ),
      );
    }

    if (_characterMissingPreviewData(character)) {
      diagnostics.add(
        CinematicDiagnostic(
          code: CinematicDiagnosticCode.characterAssetMissingPreviewData,
          severity: CinematicDiagnosticSeverity.warning,
          message:
              'Le personnage choisi n’a pas encore d’animation idle exploitable pour la future preview.',
          cinematicId: cinematic.id,
          referenceId: character.id,
          target: CinematicDiagnosticTarget.stageContext,
          suggestedFixLabel:
              'Ajouter au moins une animation idle avec une frame.',
        ),
      );
    }
  }
}

bool _characterMissingPreviewData(ProjectCharacterEntry character) {
  if (character.animations.isEmpty) {
    return true;
  }
  return !character.animations.any(
    (animation) =>
        animation.state == CharacterAnimationState.idle &&
        animation.frames.isNotEmpty,
  );
}

bool _movementTargetBindingRequiresStageMap(
  CinematicMovementTargetBinding binding,
) {
  return binding.kind == CinematicMovementTargetBindingKind.mapEntity ||
      binding.kind == CinematicMovementTargetBindingKind.mapEvent;
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
