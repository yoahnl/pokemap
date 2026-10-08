import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  ScenePlayModelAnimationInteractiveCommand build(Map<String, String> values) =>
      (buildScenePayloadForNarrativeCommand(
                    commandId: NarrativeCommandIds.playModelAnimation,
                    parameters: {
                      'mapId': 'village',
                      'instanceId': 'porte',
                      'animationIndex': '0',
                      ...values,
                    },
                  )
                  as SceneActionPayload)
              .interactiveCommand!
          as ScenePlayModelAnimationInteractiveCommand;

  test('guided animation defaults preserve the existing passage', () {
    final command = build({});
    expect(command.speed, 1);
    expect(command.blocksMovementAfter, isNull);
    expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
    expect(command.outputPortIds, ['completed', 'blocked', 'cancelled']);
  });

  for (final blocked in [true, false]) {
    test('guided animation explicitly sets passage to $blocked', () {
      final command = build({
        'speed': '.25',
        'blocksMovementAfter': '$blocked',
      });
      expect(command.speed, .25);
      expect(command.blocksMovementAfter, blocked);
    });
  }

  for (final speed in ['0', '-1', '16.1', 'NaN', 'Infinity', 'invalid']) {
    test('guided animation rejects invalid speed $speed', () {
      expect(() => build({'speed': speed}), throwsFormatException);
    });
  }
  test('guided animation rejects malformed clip and collision values', () {
    expect(() => build({'animationIndex': 'open'}), throwsFormatException);
    expect(() => build({'blocksMovementAfter': 'maybe'}), throwsArgumentError);
  });
}
