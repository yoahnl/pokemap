import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('cinematic animation step keeps the stable definition id', () {
    final command = CharacterCustomAnimationRuntimeCommand(
      actorId: 'hero',
      definitionId: 'celebrate',
      direction: EntityFacing.east,
      playback: CharacterCustomAnimationPlayback.repeatCount(2),
      fallbackPolicy:
          CharacterCustomAnimationFallbackPolicy.restoreBaseAndComplete,
    );

    final step = buildCinematicCharacterCustomAnimationStep(
      id: 'step-celebrate',
      command: command,
      label: 'Célébrer',
    );
    final decoded = CinematicTimelineStep.fromJson(step.toJson());

    expect(decoded.kind, CinematicTimelineStepKind.actorAnimation);
    expect(decoded.actorId, 'hero');
    expect(cinematicCharacterCustomAnimationCommandOf(decoded), command);
    expect(decoded.metadata.values, isNot(contains('Célébrer')));
    expect(decoded.metadata.values, isNot(contains('Celebrate')));
  });

  test('Scene command codec uses the same bounded runtime contract', () {
    final runtimeCommand = CharacterCustomAnimationRuntimeCommand(
      actorId: 'npc-rival',
      definitionId: 'taunt',
      playback: CharacterCustomAnimationPlayback.forDuration(800),
    );
    final command = SceneCharacterCustomAnimationInteractiveCommand(
      runtimeCommand: runtimeCommand,
    );

    final decoded = SceneInteractiveCommand.fromJson(command.toJson());

    expect(decoded, command);
    expect(decoded.kind, SceneInteractiveCommandKind.playCharacterAnimation);
    expect(decoded.outputPortIds, <String>[
      'completed',
      'fallback',
      'interrupted',
      'failed',
    ]);
  });
}
