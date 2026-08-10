import 'package:map_core/map_core.dart';

import '../../../application/authoring_api/character_studio_authoring_gateway.dart';
import '../../../application/errors/application_errors.dart';
import '../../../application/ports/project_workspace.dart';

final class UpsertCinematicCharacterAnimationResult {
  const UpsertCinematicCharacterAnimationResult({
    required this.project,
    required this.stepId,
  });

  final ProjectManifest project;
  final String stepId;
}

final class UpsertCinematicCharacterAnimationUseCase {
  UpsertCinematicCharacterAnimationUseCase(this._authoring);

  final CharacterStudioAuthoringGateway _authoring;

  Future<UpsertCinematicCharacterAnimationResult> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String cinematicId,
    required CharacterCustomAnimationRuntimeCommand command,
    String? stepId,
    String? afterStepId,
    String? label,
  }) async {
    final beforeIds = _cinematic(
      project,
      cinematicId,
    ).timeline.steps.map((step) => step.id).toSet();
    final updated = await _authoring.apply(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      actionId: 'cinematic.character_animation.upsert',
      parameters: <String, Object?>{
        'cinematicId': cinematicId,
        'stepId': ?stepId,
        'afterStepId': ?afterStepId,
        'label': ?label,
        'runtimeCommand': command.toJson(),
      },
      operationLabel: 'cinematic_character_animation_upsert',
    );
    final updatedCinematic = _cinematic(updated, cinematicId);
    final resolvedStepId =
        stepId ??
        updatedCinematic.timeline.steps
            .where(
              (step) =>
                  step.kind == CinematicTimelineStepKind.actorAnimation &&
                  !beforeIds.contains(step.id),
            )
            .map((step) => step.id)
            .singleOrNull;
    if (resolvedStepId == null) {
      throw const EditorValidationException(
        'The cinematic animation mutation did not expose its stable step id',
      );
    }
    return UpsertCinematicCharacterAnimationResult(
      project: updated,
      stepId: resolvedStepId,
    );
  }
}

CinematicAsset _cinematic(ProjectManifest project, String cinematicId) {
  for (final cinematic in project.cinematics) {
    if (cinematic.id == cinematicId) return cinematic;
  }
  throw const EditorValidationException('The cinematic does not exist');
}
