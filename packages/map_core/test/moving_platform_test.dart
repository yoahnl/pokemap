import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'platform pose and world state round trip independently of story facts',
    () {
      final pose = MovingPlatformPose(leftPx: 96, topPx: 128, quarterTurns: 3);
      final state = const MovingPlatformWorldState.empty().withPlatform(
        mapId: 'gym',
        platformId: 'bridge',
        pose: pose,
      );
      expect(MovingPlatformWorldState.fromJson(state.toJson()), state);
      final game = GameState(saveId: 'save', movingPlatformWorldState: state);
      expect(
        gameStateFromStrictSaveJson(
          strictGameStateSaveJson(game),
        ).movingPlatformWorldState,
        state,
      );
      expect(
        gameStateFromSaveData(
          saveDataFromGameState(game),
        ).movingPlatformWorldState,
        state,
      );
    },
  );

  test('platform pose rejects invalid rotations and unknown fields', () {
    expect(
      () => MovingPlatformPose(leftPx: 0, topPx: 0, quarterTurns: 4),
      throwsFormatException,
    );
    expect(
      () => MovingPlatformPose.fromJson({
        'leftPx': 0,
        'topPx': 0,
        'quarterTurns': 0,
        'legacy': true,
      }),
      throwsFormatException,
    );
  });

  test(
    'guided command builder emits a typed platform motion with explicit outcomes',
    () {
      final payload =
          buildScenePayloadForNarrativeCommand(
                commandId: NarrativeCommandIds.movePlatform,
                parameters: {
                  'platformRef': 'gym::bridge',
                  'motion': 'rotateClockwise',
                },
              )
              as SceneActionPayload;
      final command = SceneInteractiveCommand.movePlatform(
        mapId: 'gym',
        platformId: 'bridge',
        motion: MovingPlatformMotion.rotateClockwise,
      );
      expect(payload.interactiveCommand, command);
      expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
      expect(command.outputPortIds, [
        'moved',
        'blocked',
        'notRiding',
        'rotationRequiresPivot',
      ]);
      expect(
        NarrativeCommandIds.forInteractiveCommand(command),
        NarrativeCommandIds.movePlatform,
      );
    },
  );
}
