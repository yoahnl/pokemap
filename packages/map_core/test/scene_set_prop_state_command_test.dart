import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final json = <String, dynamic>{
    'kind': 'setPropState',
    'mapId': 'hall',
    'propIds': ['left', 'right'],
    'state': 'open',
    'durationMs': 350,
  };

  test('group movement round trips with explicit outcomes', () {
    final command = SceneInteractiveCommand.fromJson(json);
    expect(command.toJson(), json);
    expect(command.outputPortIds, ['moved', 'blocked']);
  });

  test('group movement rejects malformed and unbounded commands', () {
    for (final invalid in <Map<String, dynamic>>[
      {...json, 'propIds': <String>[]},
      {
        ...json,
        'propIds': ['left', 'left'],
      },
      {
        ...json,
        'propIds': [' left'],
      },
      {...json, 'propIds': List.generate(33, (index) => 'prop-$index')},
      {
        ...json,
        'propIds': ['left', 3],
      },
      {...json, 'durationMs': 15},
      {...json, 'durationMs': 10001},
      {...json, 'durationMs': 350.0},
      {...json, 'state': 'missing'},
      {...json, 'mapId': ' hall'},
      {...json, 'extra': true},
    ]) {
      expect(
        () => SceneInteractiveCommand.fromJson(invalid),
        throwsFormatException,
        reason: invalid.toString(),
      );
    }
  });

  test(
    'group command owns its selected props and guided values round trip',
    () {
      final ids = ['left', 'right'];
      final command =
          SceneInteractiveCommand.setPropState(
                mapId: 'hall',
                propIds: ids,
                state: MovingPropState.open,
              )
              as SceneSetPropStateInteractiveCommand;
      ids.clear();
      expect(command.propIds, ['left', 'right']);
      expect(() => command.propIds.add('extra'), throwsUnsupportedError);
      final built =
          buildScenePayloadForNarrativeCommand(
                commandId: NarrativeCommandIds.setPropState,
                parameters: {
                  'mapId': 'hall',
                  'propIds': '["left","right"]',
                  'state': 'open',
                  'durationMs': '350',
                },
              )
              as SceneActionPayload;
      expect(built.interactiveCommand, command);
      final descriptor = NarrativeCommandCatalog.canonical().byId(
        NarrativeCommandIds.setPropState,
      )!;
      expect(descriptor.fgLotId, 'FG-082');
      expect(descriptor.isPersistent, isTrue);
      expect(descriptor.isAwaitable, isTrue);
    },
  );
}
