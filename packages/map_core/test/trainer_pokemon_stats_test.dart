import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('trainer Pokemon stat overrides', () {
    test('standard members omit all three overrides from JSON', () {
      for (final overrides in [
        <String, dynamic>{},
        <String, dynamic>{'natureId': null, 'ivs': null, 'evs': null},
      ]) {
        final member = ProjectTrainerPokemonEntry.fromJson(_member(overrides));
        _expectOverrides(member.toJson(), const {});
        _expectOverrides(
          ProjectTrainerPokemonEntry.fromJson(member.toJson()).toJson(),
          const {},
        );
        expect(
          () => ProjectValidator.validate(_project([member])),
          returnsNormally,
        );
      }
    });

    test(
      'all independent override combinations survive a manifest round trip',
      () {
        for (var mask = 1; mask < 8; mask++) {
          final overrides = <String, dynamic>{
            if ((mask & 1) != 0) 'natureId': 'modest',
            if ((mask & 2) != 0) 'ivs': _ivs,
            if ((mask & 4) != 0) 'evs': _evs,
          };
          final project = _project([
            ProjectTrainerPokemonEntry.fromJson(_member(overrides)),
          ]);
          ProjectValidator.validate(project);
          final reopened = ProjectManifest.fromJson(
            jsonDecode(jsonEncode(project.toJson())) as Map<String, dynamic>,
          );
          ProjectValidator.validate(reopened);
          _expectOverrides(
            reopened.trainers.single.team.single.toJson(),
            overrides,
          );
        }
      },
    );

    for (final nature in _natures) {
      test('accepts exact canonical nature $nature', () {
        final member = ProjectTrainerPokemonEntry.fromJson(
          _member({'natureId': nature}),
        );
        ProjectValidator.validate(_project([member]));
        expect(member.toJson()['natureId'], nature);
      });
    }

    test('accepts IV bounds and the EV total of exactly 510', () {
      final overrides = {
        'ivs': {for (final stat in _stats) stat: stat == 'hp' ? 0 : 31},
        'evs': _evs,
      };
      final member = ProjectTrainerPokemonEntry.fromJson(_member(overrides));
      ProjectValidator.validate(_project([member]));
      _expectOverrides(member.toJson(), overrides);
      expect(_evs.values.reduce((sum, value) => sum + value), 510);
    });

    test('keeps overrides independent across team members and difficulty', () {
      final members = [
        ProjectTrainerPokemonEntry.fromJson(_member(_custom)),
        ProjectTrainerPokemonEntry.fromJson(_member({'natureId': 'timid'})),
        ProjectTrainerPokemonEntry.fromJson(_member(const {})),
      ];
      for (final difficulty in [1, 5, 10]) {
        final reopened = ProjectManifest.fromJson(
          jsonDecode(
                jsonEncode(_project(members, difficulty: difficulty).toJson()),
              )
              as Map<String, dynamic>,
        );
        ProjectValidator.validate(reopened);
        final trainer = reopened.trainers.single;
        expect(trainer.battleDifficulty, difficulty);
        _expectOverrides(trainer.team[0].toJson(), _custom);
        _expectOverrides(trainer.team[1].toJson(), {'natureId': 'timid'});
        _expectOverrides(trainer.team[2].toJson(), const {});
      }
    });

    test(
      'preserves team attributes and trainer rewards beside stat overrides',
      () {
        final memberJson = {
          ..._member(_custom),
          'moves': ['test_move_one', 'test_move_two'],
          'heldItemId': 'test_held_item',
          'ballItemId': 'test_ball',
          'abilityId': 'test_ability',
          'formId': 'test_form',
          'gender': 'female',
          'shiny': true,
        };
        final trainer = ProjectTrainerEntry.fromJson({
          'id': 'trainer_alpha',
          'name': 'Trainer Alpha',
          'trainerClass': 'Trainer',
          'battleDifficulty': 7,
          'moneyReward': 123,
          'rewardItemGrants': [
            {'itemId': 'test_reward', 'quantity': 2},
          ],
          'rewardFlagIds': ['test_victory'],
          'rewardBadgeId': 'test_badge',
          'team': [memberJson],
          'tags': ['synthetic'],
        });
        final project = _project([]).copyWith(
          trainers: [trainer],
          badges: const [
            BadgeDefinition(id: 'test_badge', label: 'Test Badge'),
          ],
        );
        final reopened = ProjectManifest.fromJson(
          jsonDecode(jsonEncode(project.toJson())) as Map<String, dynamic>,
        );
        final actual = reopened.trainers.single;
        expect(actual.battleDifficulty, 7);
        expect(actual.moneyReward, 123);
        expect(actual.rewardItemGrants.single.itemId, 'test_reward');
        expect(actual.rewardItemGrants.single.quantity, 2);
        expect(actual.rewardFlagIds, ['test_victory']);
        expect(actual.rewardBadgeId, 'test_badge');
        expect(actual.tags, ['synthetic']);
        final actualMember = actual.team.single.toJson();
        for (final entry in memberJson.entries) {
          expect(actualMember[entry.key], entry.value, reason: entry.key);
        }
      },
    );

    for (final entry in _invalidOverrides().entries) {
      test('rejects ${entry.key} before accepting a trainer project', () {
        final field = entry.value.keys.single;
        expect(
          () {
            final member = ProjectTrainerPokemonEntry.fromJson(
              _member(entry.value),
            );
            ProjectValidator.validate(_project([member]));
          },
          throwsA(
            anyOf(
              isA<FormatException>().having(
                (error) => error.message,
                'message',
                contains(field),
              ),
              isA<ValidationException>().having(
                (error) => error.message,
                'message',
                contains(field),
              ),
            ),
          ),
        );
      });
    }

    test(
      'trainer parsing leaves global spread and PlayerPokemon JSON unchanged',
      () {
        final spread = PokemonStatSpread.fromJson({'hp': 1.0});
        expect(spread.toJson(), {
          for (final stat in _stats) stat: stat == 'hp' ? 1 : 0,
        });
        final player = PlayerPokemon.fromJson({
          'speciesId': 'test_species',
          'natureId': 'hardy',
          'abilityId': 'test_ability',
          'ivs': {'hp': 32.0},
          'evs': {'attack': 253.0},
        });
        expect(player.ivs.hp, 32);
        expect(player.ivs.attack, 0);
        expect(player.evs.attack, 253);
        expect(player.evs.hp, 0);
        expect(PlayerPokemon.fromJson(player.toJson()), player);
      },
    );
  });
}

const _stats = [
  'hp',
  'attack',
  'defense',
  'specialAttack',
  'specialDefense',
  'speed',
];

const _natures = [
  'hardy',
  'lonely',
  'brave',
  'adamant',
  'naughty',
  'bold',
  'docile',
  'relaxed',
  'impish',
  'lax',
  'timid',
  'hasty',
  'serious',
  'jolly',
  'naive',
  'modest',
  'mild',
  'quiet',
  'bashful',
  'rash',
  'calm',
  'gentle',
  'sassy',
  'careful',
  'quirky',
];

const _ivs = {
  'hp': 31,
  'attack': 0,
  'defense': 1,
  'specialAttack': 7,
  'specialDefense': 23,
  'speed': 30,
};

const _evs = {
  'hp': 252,
  'attack': 0,
  'defense': 4,
  'specialAttack': 0,
  'specialDefense': 2,
  'speed': 252,
};

const _custom = {'natureId': 'modest', 'ivs': _ivs, 'evs': _evs};

Map<String, dynamic> _member(Map<String, dynamic> overrides) => {
  'speciesId': 'test_species',
  'level': 50,
  ...overrides,
};

ProjectManifest _project(
  List<ProjectTrainerPokemonEntry> members, {
  int difficulty = 5,
}) => ProjectManifest(
  name: 'Synthetic trainer stats',
  maps: const [],
  tilesets: const [],
  trainers: [
    ProjectTrainerEntry(
      id: 'trainer_alpha',
      name: 'Trainer Alpha',
      trainerClass: 'Trainer',
      battleDifficulty: difficulty,
      team: members,
    ),
  ],
);

void _expectOverrides(
  Map<String, dynamic> member,
  Map<String, dynamic> overrides,
) {
  for (final key in ['natureId', 'ivs', 'evs']) {
    if (overrides.containsKey(key)) {
      expect(member[key], overrides[key], reason: key);
    } else {
      expect(member.containsKey(key), isFalse, reason: key);
    }
  }
}

Map<String, Map<String, dynamic>> _invalidOverrides() {
  final cases = <String, Map<String, dynamic>>{};
  for (final value in <Object>[
    '',
    ' ',
    ' modest ',
    'Modest',
    'unknown_nature',
    1,
    true,
    [],
    {},
  ]) {
    cases['natureId ${jsonEncode(value)}'] = {'natureId': value};
  }
  for (final field in ['ivs', 'evs']) {
    final standard = {for (final stat in _stats) stat: 0};
    for (final value in <Object>[true, 1, 1.0, '15', [], {}]) {
      cases['$field non-spread ${jsonEncode(value)}'] = {field: value};
    }
    cases['$field unknown stat'] = {
      field: {...standard, 'accuracy': 0},
    };
    for (final stat in _stats) {
      cases['$field missing $stat'] = {
        field: {...standard}..remove(stat),
      };
      final invalidValues = <Object?>[
        null,
        true,
        '1',
        1.0,
        1.5,
        -1,
        field == 'ivs' ? 32 : 253,
      ];
      for (final value in invalidValues) {
        cases['$field.$stat ${jsonEncode(value)}'] = {
          field: {...standard, stat: value},
        };
      }
    }
  }
  cases['evs total 511'] = {
    'evs': {..._evs, 'defense': 5},
  };
  return cases;
}
