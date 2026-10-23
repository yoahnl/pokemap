import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'stop effects declares its owner scope without admitting media parameters',
    () {
      final wire = {'kind': 'stopSoundEffects', 'scope': 'map'};
      final command = SceneInteractiveCommand.fromJson(wire);
      expect(command.toJson(), wire);
      expect(command.outputPortIds, ['completed', 'blocked']);
      expect(
        () => SceneInteractiveCommand.fromJson({...wire, 'volume': .5}),
        throwsA(anything),
      );
    },
  );
  test('world audio preserves channels scope and both-channel memories', () {
    for (final wire in <Map<String, dynamic>>[
      {
        'kind': 'sceneMusic',
        'operation': 'play',
        'channel': 'ambience',
        'scope': 'map',
        'mediaAssetId': 'rain',
        'volume': .4,
      },
      {
        'kind': 'sceneMusic',
        'operation': 'stop',
        'channel': 'music',
        'scope': 'map',
      },
      {
        'kind': 'sceneMusic',
        'operation': 'memorize',
        'channel': 'both',
        'scope': 'map',
      },
      {
        'kind': 'sceneMusic',
        'operation': 'restoreMemorized',
        'channel': 'both',
        'scope': 'map',
      },
    ]) {
      final command =
          SceneInteractiveCommand.fromJson(wire)
              as SceneMusicInteractiveCommand;
      expect(command.scope, SceneMusicScope.map);
      expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
      expect(command.toJson()['channel'], wire['channel']);
      expect(command.toJson()['scope'], 'map');
    }
  });

  test('both channels cannot play stop fade or restore a baseline', () {
    for (final operation in ['play', 'stop', 'fadeOut', 'restore']) {
      expect(
        () => SceneInteractiveCommand.fromJson({
          'kind': 'sceneMusic',
          'operation': operation,
          'channel': 'both',
          'scope': 'map',
          if (operation == 'play') ...{'mediaAssetId': 'rain', 'volume': .4},
          if (operation == 'fadeOut') 'durationMs': 100,
        }),
        throwsA(anything),
      );
    }
  });

  test('world audio rejects unknown channels scopes and operation fields', () {
    for (final extra in <Map<String, dynamic>>[
      {'channel': 'bgm'},
      {'scope': 'global'},
      {'volume': .5},
      {'durationMs': 0},
    ]) {
      expect(
        () => SceneInteractiveCommand.fromJson({
          'kind': 'sceneMusic',
          'operation': 'memorize',
          ...extra,
        }),
        throwsA(anything),
      );
    }
  });
}
