import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/character_studio_authoring_gateway.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/features/character_studio/application/cinematic_character_animation_use_case.dart';

void main() {
  test('cinematic animation uses the canonical semantic action', () async {
    final gateway = _RecordingGateway();
    final useCase = UpsertCinematicCharacterAnimationUseCase(gateway);
    final project = ProjectManifest(
      name: 'Cinematic authoring',
      maps: const [],
      tilesets: const [],
      cinematics: [
        CinematicAsset(
          id: 'intro',
          title: 'Introduction',
          timeline: CinematicTimeline(steps: const []),
        ),
      ],
    );
    final command = CharacterCustomAnimationRuntimeCommand(
      actorId: 'elia',
      definitionId: 'saluer',
      direction: EntityFacing.south,
      playback: CharacterCustomAnimationPlayback.repeatCount(2),
    );

    final result = await useCase.execute(
      _Workspace(),
      project,
      cinematicId: 'intro',
      command: command,
      label: 'Élia salue',
    );

    expect(gateway.actionId, 'cinematic.character_animation.upsert');
    expect(gateway.parameters, <String, Object?>{
      'cinematicId': 'intro',
      'label': 'Élia salue',
      'runtimeCommand': command.toJson(),
    });
    expect(result.stepId, 'step_character_animation_1');
    expect(
      result.project.cinematics.single.timeline.steps.single.kind,
      CinematicTimelineStepKind.actorAnimation,
    );
  });
}

final class _RecordingGateway implements CharacterStudioAuthoringGateway {
  String? actionId;
  Map<String, Object?>? parameters;

  @override
  Future<ProjectManifest> apply({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required String actionId,
    required Map<String, Object?> parameters,
    required String operationLabel,
    bool requiresConfirmation = false,
  }) async {
    this.actionId = actionId;
    this.parameters = parameters;
    final command = CharacterCustomAnimationRuntimeCommand.fromJson(
      Map<String, dynamic>.from(parameters['runtimeCommand']! as Map),
    );
    final cinematic = expectedProject.cinematics.single;
    return expectedProject.copyWith(
      cinematics: [
        cinematic.copyWith(
          timeline: CinematicTimeline(
            steps: [
              buildCinematicCharacterCustomAnimationStep(
                id: 'step_character_animation_1',
                label: parameters['label'] as String?,
                command: command,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Workspace implements ProjectWorkspace {
  @override
  String get projectRoot => '/project';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
