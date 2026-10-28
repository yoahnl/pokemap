import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('old project settings omit Surf configuration', () {
    final settings = ProjectSettings.fromJson({});
    expect(settings.toJson(), isNot(contains('surf')));
  });

  test('Surf settings survive native settings serialization', () {
    final surf = <String, dynamic>{
      'enabled': true,
      'requiresKnownMove': false,
      'accessMode': 'condition',
      'condition': {
        'type': 'flagIsSet',
        'params': {'flagName': 'boat_license'},
        'children': <dynamic>[],
      },
      'speedCellsPerSecond': 4.0,
    };
    final settings = ProjectSettings.fromJson({'surf': surf});
    expect(settings.toJson()['surf'], surf);
  });

  for (final state in [
    'surf_idle',
    'surf',
    'surf_enter',
    'surf_exit',
    'climb',
  ]) {
    test('Character animation preserves typed $state state', () {
      final animation = CharacterAnimation.fromJson({
        'state': state,
        'direction': 'south',
      });
      expect(animation.toJson()['state'], state);
    });
  }

  for (final surf in <Map<String, dynamic>>[
    {'enabled': 'yes'},
    {'requiresKnownMove': 1},
    {'accessMode': 'future'},
    {'speedCellsPerSecond': 0},
    {'speedCellsPerSecond': -1},
    {'speedCellsPerSecond': double.infinity},
    {'speedCellsPerSecond': '4'},
    {'condition': []},
    {'future': true},
    {'accessMode': 'condition'},
    {'accessMode': null},
    {'speedCellsPerSecond': null},
    {
      'condition': {'type': 'allOf'},
    },
    {
      'condition': {'type': 'anyOf', 'children': []},
    },
    {
      'condition': {'type': 'not', 'children': []},
    },
    {
      'condition': {'type': 'flagIsSet'},
    },
    {
      'condition': {
        'type': 'fieldAbilityUnlocked',
        'params': {'ability': 'future'},
      },
    },
    {
      'condition': {
        'type': 'moneyAtLeast',
        'params': {'amount': '-1'},
      },
    },
    {
      'condition': {
        'type': 'variableGreaterThan',
        'params': {'variableName': 'x', 'value': 'abc'},
      },
    },
    {
      'condition': {
        'type': 'flagIsSet',
        'params': {'flagName': 'x'},
        'future': true,
      },
    },
    {
      'condition': {'type': 'flagIsSet', 'params': null},
    },
    {
      'condition': {'type': 'flagIsSet', 'children': null},
    },
  ]) {
    test('rejects malformed Surf configuration $surf', () {
      expect(
        () => ProjectSettings.fromJson({'surf': surf}),
        throwsFormatException,
      );
    });
  }
  test('Surf capability leaves a legacy project unchanged', () {
    const project = ProjectManifest(name: 'Legacy', maps: [], tilesets: []);
    expect(SurfGameplayCapabilities.requiresCapability(project), isFalse);
    expect(SurfGameplayCapabilities.capabilityId, 'gameplay.surf@1');
  });

  test('Surf capability is required for every explicit Surf configuration', () {
    for (final enabled in [true, false]) {
      final project = ProjectManifest(
        name: 'Surf',
        maps: [],
        tilesets: [],
        settings: ProjectSettings(surf: ProjectSurfSettings(enabled: enabled)),
      );
      expect(SurfGameplayCapabilities.requiresCapability(project), isTrue);
    }
  });

  for (final state in [
    CharacterAnimationState.surfIdle,
    CharacterAnimationState.surf,
    CharacterAnimationState.surfEnter,
    CharacterAnimationState.surfExit,
  ]) {
    test('Surf capability protects a Character using ${state.name}', () {
      final project = ProjectManifest(
        name: 'Character',
        maps: [],
        tilesets: [],
        characters: [
          ProjectCharacterEntry(
            id: 'hero',
            name: 'Hero',
            tilesetId: 'hero',
            animations: [
              CharacterAnimation(state: state, direction: EntityFacing.south),
            ],
          ),
        ],
      );
      expect(SurfGameplayCapabilities.requiresCapability(project), isTrue);
    });
  }
}
