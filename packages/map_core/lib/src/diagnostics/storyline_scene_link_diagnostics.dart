import '../models/project_manifest.dart';
import '../models/storyline_asset.dart';
import '../runtime/scene_runtime_plan_builder.dart';
import 'scene_diagnostics.dart';

enum StorylineSceneLinkDiagnosticSeverity {
  error,
  warning,
  info,
}

enum StorylineSceneLinkDiagnosticCode {
  storylineStepUnknownSceneLink,
  storylineStepDuplicateSceneLink,
  storylineStepLinkedSceneHasErrors,
  storylineStepLinkedSceneNotRuntimeBuildable,
  storylineStructuredOutcomeUnknownScenario,
  storylineStructuredOutcomeUnknownOutcome,
  storylineStructuredOutcomeUnknownStepTarget,
  storylineStructuredOutcomeDuplicateStepEffect,
}

final class StorylineSceneLinkDiagnostic {
  const StorylineSceneLinkDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.storylineId,
    required this.chapterId,
    required this.stepId,
    this.sceneId,
    this.sceneLinkId,
    this.outcomeId,
    this.effectTargetId,
    this.suggestedFixLabel,
  });

  final StorylineSceneLinkDiagnosticCode code;
  final StorylineSceneLinkDiagnosticSeverity severity;
  final String message;
  final String storylineId;
  final String chapterId;
  final String stepId;
  final String? sceneId;
  final String? sceneLinkId;
  final String? outcomeId;
  final String? effectTargetId;
  final String? suggestedFixLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorylineSceneLinkDiagnostic &&
          other.code == code &&
          other.severity == severity &&
          other.message == message &&
          other.storylineId == storylineId &&
          other.chapterId == chapterId &&
          other.stepId == stepId &&
          other.sceneId == sceneId &&
          other.sceneLinkId == sceneLinkId &&
          other.outcomeId == outcomeId &&
          other.effectTargetId == effectTargetId &&
          other.suggestedFixLabel == suggestedFixLabel;

  @override
  int get hashCode => Object.hash(
        code,
        severity,
        message,
        storylineId,
        chapterId,
        stepId,
        sceneId,
        sceneLinkId,
        outcomeId,
        effectTargetId,
        suggestedFixLabel,
      );
}

final class StorylineSceneLinkDiagnosticsReport {
  StorylineSceneLinkDiagnosticsReport({
    required List<StorylineSceneLinkDiagnostic> diagnostics,
  }) : _diagnostics =
            List<StorylineSceneLinkDiagnostic>.unmodifiable(diagnostics);

  final List<StorylineSceneLinkDiagnostic> _diagnostics;

  List<StorylineSceneLinkDiagnostic> get diagnostics => _diagnostics;

  int get count => _diagnostics.length;

  int get errorCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == StorylineSceneLinkDiagnosticSeverity.error)
      .length;

  int get warningCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == StorylineSceneLinkDiagnosticSeverity.warning)
      .length;

  bool get hasDiagnostics => _diagnostics.isNotEmpty;

  bool get hasErrors => errorCount > 0;

  List<StorylineSceneLinkDiagnostic> byCode(
    StorylineSceneLinkDiagnosticCode code,
  ) {
    return List<StorylineSceneLinkDiagnostic>.unmodifiable(
      _diagnostics.where((diagnostic) => diagnostic.code == code),
    );
  }

  List<StorylineSceneLinkDiagnostic> forStep(String stepId) {
    return List<StorylineSceneLinkDiagnostic>.unmodifiable(
      _diagnostics.where((diagnostic) => diagnostic.stepId == stepId),
    );
  }
}

StorylineSceneLinkDiagnosticsReport diagnoseStorylineSceneLinks({
  required ProjectManifest project,
}) {
  final sceneById = {
    for (final scene in project.scenes) scene.id: scene,
  };
  final scenarioById = {
    for (final scenario in project.scenarios) scenario.id: scenario,
  };
  final diagnostics = <StorylineSceneLinkDiagnostic>[];

  for (final storyline in project.storylines) {
    final stepIds = <String>{
      for (final chapter in storyline.chapters)
        for (final step in chapter.steps) step.id,
    };
    for (final chapter in storyline.chapters) {
      for (final step in chapter.steps) {
        final seenSceneIds = <String>{};
        for (final sceneId in step.sceneLinkIds) {
          if (!seenSceneIds.add(sceneId)) {
            diagnostics.add(
              StorylineSceneLinkDiagnostic(
                code: StorylineSceneLinkDiagnosticCode
                    .storylineStepDuplicateSceneLink,
                severity: StorylineSceneLinkDiagnosticSeverity.warning,
                message:
                    'L’étape narrative référence plusieurs fois la même Scene V1: $sceneId.',
                storylineId: storyline.id,
                chapterId: chapter.id,
                stepId: step.id,
                sceneId: sceneId,
                suggestedFixLabel: 'Retirer les doublons de liens Scene.',
              ),
            );
          }

          final scene = sceneById[sceneId];
          if (scene == null) {
            diagnostics.add(
              StorylineSceneLinkDiagnostic(
                code: StorylineSceneLinkDiagnosticCode
                    .storylineStepUnknownSceneLink,
                severity: StorylineSceneLinkDiagnosticSeverity.error,
                message:
                    'L’étape narrative référence une Scene V1 introuvable: $sceneId.',
                storylineId: storyline.id,
                chapterId: chapter.id,
                stepId: step.id,
                sceneId: sceneId,
                suggestedFixLabel: 'Choisir une Scene V1 existante.',
              ),
            );
            continue;
          }

          if (diagnoseScene(scene).hasErrors) {
            diagnostics.add(
              StorylineSceneLinkDiagnostic(
                code: StorylineSceneLinkDiagnosticCode
                    .storylineStepLinkedSceneHasErrors,
                severity: StorylineSceneLinkDiagnosticSeverity.warning,
                message:
                    'La Scene V1 liée contient des erreurs de diagnostics.',
                storylineId: storyline.id,
                chapterId: chapter.id,
                stepId: step.id,
                sceneId: sceneId,
                suggestedFixLabel: 'Corriger la Scene liée.',
              ),
            );
          }

          final planResult = buildSceneRuntimePlan(scene);
          if (!planResult.canBuild) {
            diagnostics.add(
              StorylineSceneLinkDiagnostic(
                code: StorylineSceneLinkDiagnosticCode
                    .storylineStepLinkedSceneNotRuntimeBuildable,
                severity: StorylineSceneLinkDiagnosticSeverity.warning,
                message:
                    'La Scene V1 liée ne peut pas encore produire de SceneRuntimePlan.',
                storylineId: storyline.id,
                chapterId: chapter.id,
                stepId: step.id,
                sceneId: sceneId,
                suggestedFixLabel:
                    'Garder le lien authoring ou corriger la Scene avant runtime.',
              ),
            );
          }
        }
      }
    }

    for (final sceneLink in storyline.sceneLinks) {
      final scenarioId = sceneLink.sceneRef?.targetId;
      final scenario = scenarioId == null ? null : scenarioById[scenarioId];
      if (scenarioId != null && scenario == null) {
        diagnostics.add(
          StorylineSceneLinkDiagnostic(
            code: StorylineSceneLinkDiagnosticCode
                .storylineStructuredOutcomeUnknownScenario,
            severity: StorylineSceneLinkDiagnosticSeverity.error,
            message:
                'Le lien structuré référence un Scenario introuvable: $scenarioId.',
            storylineId: storyline.id,
            chapterId: sceneLink.chapterId,
            stepId: sceneLink.stepId ?? '',
            sceneId: scenarioId,
            sceneLinkId: sceneLink.id,
            suggestedFixLabel: 'Choisir un Scenario existant.',
          ),
        );
      }

      for (final outcomeLink in sceneLink.outcomeLinks) {
        if (scenario != null &&
            !scenario.declaredOutcomes.contains(outcomeLink.outcomeId)) {
          diagnostics.add(
            StorylineSceneLinkDiagnostic(
              code: StorylineSceneLinkDiagnosticCode
                  .storylineStructuredOutcomeUnknownOutcome,
              severity: StorylineSceneLinkDiagnosticSeverity.error,
              message:
                  'Le résultat ${outcomeLink.outcomeId} n’est pas déclaré par le Scenario $scenarioId.',
              storylineId: storyline.id,
              chapterId: sceneLink.chapterId,
              stepId: sceneLink.stepId ?? '',
              sceneId: scenarioId,
              sceneLinkId: sceneLink.id,
              outcomeId: outcomeLink.outcomeId,
              suggestedFixLabel: 'Choisir un résultat déclaré par le Scenario.',
            ),
          );
        }

        final seenStepEffects = <String>{};
        for (final effect in outcomeLink.effects) {
          if (effect.type != StorylineEffectType.activateStep &&
              effect.type != StorylineEffectType.completeStep) {
            continue;
          }
          if (!stepIds.contains(effect.targetId)) {
            diagnostics.add(
              StorylineSceneLinkDiagnostic(
                code: StorylineSceneLinkDiagnosticCode
                    .storylineStructuredOutcomeUnknownStepTarget,
                severity: StorylineSceneLinkDiagnosticSeverity.error,
                message:
                    'L’effet ${effect.type.name} cible une étape introuvable: ${effect.targetId}.',
                storylineId: storyline.id,
                chapterId: sceneLink.chapterId,
                stepId: sceneLink.stepId ?? '',
                sceneId: scenarioId,
                sceneLinkId: sceneLink.id,
                outcomeId: outcomeLink.outcomeId,
                effectTargetId: effect.targetId,
                suggestedFixLabel: 'Choisir une étape de la Storyline.',
              ),
            );
          }
          final key = '${effect.type.name}:${effect.targetId}';
          if (!seenStepEffects.add(key)) {
            diagnostics.add(
              StorylineSceneLinkDiagnostic(
                code: StorylineSceneLinkDiagnosticCode
                    .storylineStructuredOutcomeDuplicateStepEffect,
                severity: StorylineSceneLinkDiagnosticSeverity.warning,
                message:
                    'Le résultat répète l’effet ${effect.type.name} vers ${effect.targetId}.',
                storylineId: storyline.id,
                chapterId: sceneLink.chapterId,
                stepId: sceneLink.stepId ?? '',
                sceneId: scenarioId,
                sceneLinkId: sceneLink.id,
                outcomeId: outcomeLink.outcomeId,
                effectTargetId: effect.targetId,
                suggestedFixLabel: 'Retirer l’effet structuré en double.',
              ),
            );
          }
        }
      }
    }
  }

  return StorylineSceneLinkDiagnosticsReport(diagnostics: diagnostics);
}
