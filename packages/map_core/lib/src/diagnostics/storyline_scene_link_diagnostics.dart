import '../models/project_manifest.dart';
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
    this.suggestedFixLabel,
  });

  final StorylineSceneLinkDiagnosticCode code;
  final StorylineSceneLinkDiagnosticSeverity severity;
  final String message;
  final String storylineId;
  final String chapterId;
  final String stepId;
  final String? sceneId;
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
  final diagnostics = <StorylineSceneLinkDiagnostic>[];

  for (final storyline in project.storylines) {
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
  }

  return StorylineSceneLinkDiagnosticsReport(diagnostics: diagnostics);
}
