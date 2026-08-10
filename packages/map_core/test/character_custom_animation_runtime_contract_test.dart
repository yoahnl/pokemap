import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('CharacterCustomAnimationPlayback', () {
    test('only exposes bounded completion rules', () {
      expect(
        CharacterCustomAnimationPlayback.once().completionDurationMs(
          cycleDurationMs: 450,
        ),
        450,
      );
      expect(
        CharacterCustomAnimationPlayback.repeatCount(
          3,
        ).completionDurationMs(cycleDurationMs: 450),
        1350,
      );
      expect(
        CharacterCustomAnimationPlayback.forDuration(
          725,
        ).completionDurationMs(cycleDurationMs: 450),
        725,
      );
    });

    test('rejects non-positive repeat counts and durations', () {
      expect(
        () => CharacterCustomAnimationPlayback.repeatCount(0),
        throwsArgumentError,
      );
      expect(
        () => CharacterCustomAnimationPlayback.forDuration(0),
        throwsArgumentError,
      );
    });
  });

  test('runtime command codec keeps stable ids and policies', () {
    final command = CharacterCustomAnimationRuntimeCommand(
      actorId: 'hero',
      definitionId: 'celebrate',
      direction: EntityFacing.east,
      playback: CharacterCustomAnimationPlayback.repeatCount(2),
      interruptionPolicy:
          CharacterCustomAnimationInterruptionPolicy.replaceActive,
      fallbackPolicy:
          CharacterCustomAnimationFallbackPolicy.restoreBaseAndComplete,
    );

    final decoded = CharacterCustomAnimationRuntimeCommand.fromJson(
      command.toJson(),
    );

    expect(decoded, command);
    expect(decoded.definitionId, 'celebrate');
    expect(decoded.playback.repeatCount, 2);
  });
}
