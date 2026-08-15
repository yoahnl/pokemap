import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';
import 'package:map_runtime/src/application/runtime_pokemon_evolution_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimePokemonEvolutionLoader', () {
    late Directory tempRoot;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp(
        'runtime_evolution_loader_',
      );
    });

    tearDown(() async {
      if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
    });

    test('loads level rules in catalog order and resolves target metadata',
        () async {
      await _writeEvolution(tempRoot, <String, dynamic>{
        'speciesId': 'sproutle',
        'evolutions': <Object?>[
          <String, Object?>{
            'targetSpeciesId': 'ignored_item_mon',
            'method': 'use_item',
            'minLevel': null,
          },
          <String, Object?>{
            'targetSpeciesId': 'bloomon',
            'method': 'level_up',
            'minLevel': 16,
          },
          <String, Object?>{
            'targetSpeciesId': 'branchmon',
            'method': 'level_up',
            'minLevel': 16,
          },
        ],
      });
      await _writeSpecies(
        tempRoot,
        id: 'bloomon',
        primaryAbilityId: 'overgrow',
        secondaryAbilityId: 'chlorophyll',
      );
      await _writeSpecies(
        tempRoot,
        id: 'branchmon',
        primaryAbilityId: 'leaf_guard',
      );

      final candidates =
          await RuntimePokemonEvolutionLoader().loadLevelUpCandidates(
        projectRootDirectory: tempRoot.path,
        pokemonConfig: _config(),
        sourceSpeciesId: 'sproutle',
      );

      expect(
        candidates
            .map(
              (candidate) => (
                candidate.opportunityId,
                candidate.sourceSpeciesId,
                candidate.targetSpeciesId,
                candidate.minLevel,
              ),
            )
            .toList(growable: false),
        <(String, String, String, int)>[
          ('sproutle:levelUp:1:16:bloomon', 'sproutle', 'bloomon', 16),
          ('sproutle:levelUp:2:16:branchmon', 'sproutle', 'branchmon', 16),
        ],
      );
      expect(candidates.first.targetBaseStats.hp, 80);
      expect(candidates.first.targetPrimaryAbilityId, 'overgrow');
      expect(
        candidates.first.targetAbilityIds,
        <String>['overgrow', 'chlorophyll'],
      );
      expect(
        candidates.map((candidate) => candidate.opportunityId).toSet(),
        hasLength(candidates.length),
      );
    });

    test('returns no candidates for an explicit empty evolution catalog',
        () async {
      await _writeEvolution(tempRoot, <String, dynamic>{
        'speciesId': 'sproutle',
        'evolutions': <Object?>[],
      });

      final candidates =
          await RuntimePokemonEvolutionLoader().loadLevelUpCandidates(
        projectRootDirectory: tempRoot.path,
        pokemonConfig: _config(),
        sourceSpeciesId: 'sproutle',
      );

      expect(candidates, isEmpty);
    });

    test('loads friendship, known-move, and item conditions as typed rules',
        () async {
      await _writeEvolution(tempRoot, <String, dynamic>{
        'speciesId': 'sproutle',
        'evolutions': <Object?>[
          <String, Object?>{
            'targetSpeciesId': 'friendmon',
            'method': 'friendship',
            'minFriendship': 220,
            'minLevel': 12,
          },
          <String, Object?>{
            'targetSpeciesId': 'movemon',
            'method': 'known_move',
            'requiredMoveId': 'ancient-power',
            'minLevel': 18,
          },
          <String, Object?>{
            'targetSpeciesId': 'stonemon',
            'method': 'use_item',
            'itemId': 'leaf-stone',
          },
        ],
      });
      for (final id in <String>['friendmon', 'movemon', 'stonemon']) {
        await _writeSpecies(
          tempRoot,
          id: id,
          primaryAbilityId: 'overgrow',
        );
      }

      final loader = RuntimePokemonEvolutionLoader();
      final levelCandidates = await loader.loadLevelUpCandidates(
        projectRootDirectory: tempRoot.path,
        pokemonConfig: _config(),
        sourceSpeciesId: 'sproutle',
      );
      final itemCandidates = await loader.loadItemUseCandidates(
        projectRootDirectory: tempRoot.path,
        pokemonConfig: _config(),
        sourceSpeciesId: 'sproutle',
        itemId: 'leaf-stone',
      );

      expect(
        levelCandidates.map((candidate) => candidate.condition.kind),
        <PokemonEvolutionConditionKind>[
          PokemonEvolutionConditionKind.friendship,
          PokemonEvolutionConditionKind.knownMove,
        ],
      );
      expect(levelCandidates.first.condition.minFriendship, 220);
      expect(levelCandidates.last.condition.moveId, 'ancient-power');
      expect(itemCandidates, hasLength(1));
      expect(
        itemCandidates.single.condition.kind,
        PokemonEvolutionConditionKind.item,
      );
      expect(itemCandidates.single.condition.itemId, 'leaf-stone');
    });

    test('fails closed on malformed supported friendship and item rules',
        () async {
      await _writeEvolution(tempRoot, <String, dynamic>{
        'speciesId': 'sproutle',
        'evolutions': <Object?>[
          <String, Object?>{
            'targetSpeciesId': 'friendmon',
            'method': 'friendship',
            'minFriendship': 300,
          },
        ],
      });
      await expectLater(
        () => RuntimePokemonEvolutionLoader().loadLevelUpCandidates(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: _config(),
          sourceSpeciesId: 'sproutle',
        ),
        throwsA(isA<RuntimeBattleSetupException>()),
      );

      await _writeEvolution(tempRoot, <String, dynamic>{
        'speciesId': 'sproutle',
        'evolutions': <Object?>[
          <String, Object?>{
            'targetSpeciesId': 'stonemon',
            'method': 'use_item',
            'itemId': '',
          },
        ],
      });
      await expectLater(
        () => RuntimePokemonEvolutionLoader().loadItemUseCandidates(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: _config(),
          sourceSpeciesId: 'sproutle',
        ),
        throwsA(isA<RuntimeBattleSetupException>()),
      );
    });

    test('fails explicitly when the source evolution file is absent', () async {
      await expectLater(
        () => RuntimePokemonEvolutionLoader().loadLevelUpCandidates(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: _config(),
          sourceSpeciesId: 'sproutle',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('evolution file not found'),
          ),
        ),
      );
    });

    test('ignores a catalog containing only valid non-level methods', () async {
      await _writeEvolution(tempRoot, <String, dynamic>{
        'speciesId': 'sproutle',
        'evolutions': <Object?>[
          <String, Object?>{
            'targetSpeciesId': 'itemmon',
            'method': 'use_item',
            'minLevel': null,
            'itemId': 'leaf_stone',
          },
          <String, Object?>{
            'targetSpeciesId': 'trademon',
            'method': 'trade',
            'minLevel': null,
          },
        ],
      });

      final candidates =
          await RuntimePokemonEvolutionLoader().loadLevelUpCandidates(
        projectRootDirectory: tempRoot.path,
        pokemonConfig: _config(),
        sourceSpeciesId: 'sproutle',
      );

      expect(candidates, isEmpty);
    });

    test('fails closed on declared source mismatch or malformed level rule',
        () async {
      await _writeEvolution(tempRoot, <String, dynamic>{
        'speciesId': 'wrong_source',
        'evolutions': <Object?>[],
      });

      await expectLater(
        () => RuntimePokemonEvolutionLoader().loadLevelUpCandidates(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: _config(),
          sourceSpeciesId: 'sproutle',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('declaredId=wrong_source'),
          ),
        ),
      );

      await _writeEvolution(tempRoot, <String, dynamic>{
        'speciesId': 'sproutle',
        'evolutions': <Object?>[
          <String, Object?>{
            'targetSpeciesId': 'bloomon',
            'method': 'level_up',
            'minLevel': null,
          },
        ],
      });
      await expectLater(
        () => RuntimePokemonEvolutionLoader().loadLevelUpCandidates(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: _config(),
          sourceSpeciesId: 'sproutle',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('evolutions[0]'),
          ),
        ),
      );
    });

    test('fails closed when target species or target abilities are invalid',
        () async {
      await _writeEvolution(tempRoot, _validEvolutionJson());
      await expectLater(
        () => RuntimePokemonEvolutionLoader().loadLevelUpCandidates(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: _config(),
          sourceSpeciesId: 'sproutle',
        ),
        throwsA(isA<RuntimeBattleSetupException>()),
      );

      await _writeSpecies(
        tempRoot,
        id: 'bloomon',
        primaryAbilityId: '',
      );
      await expectLater(
        () => RuntimePokemonEvolutionLoader().loadLevelUpCandidates(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: _config(),
          sourceSpeciesId: 'sproutle',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('abilities'),
          ),
        ),
      );
    });

    test('fails with a typed setup error for non-object target abilities',
        () async {
      await _writeEvolution(tempRoot, _validEvolutionJson());
      for (final rawAbilities in <Object>[
        <Object?>[],
        'overgrow',
      ]) {
        await _writeSpecies(
          tempRoot,
          id: 'bloomon',
          primaryAbilityId: 'overgrow',
          rawAbilities: rawAbilities,
        );

        await expectLater(
          () => RuntimePokemonEvolutionLoader().loadLevelUpCandidates(
            projectRootDirectory: tempRoot.path,
            pokemonConfig: _config(),
            sourceSpeciesId: 'sproutle',
          ),
          throwsA(
            isA<RuntimeBattleSetupException>().having(
              (error) => error.debugDetails,
              'debugDetails',
              contains('abilities'),
            ),
          ),
        );
      }
    });

    test('target species invalid stats or progression fail closed', () async {
      await _writeEvolution(tempRoot, _validEvolutionJson());
      await _writeSpecies(
        tempRoot,
        id: 'bloomon',
        primaryAbilityId: 'overgrow',
        hp: 0,
      );
      await expectLater(
        () => RuntimePokemonEvolutionLoader().loadLevelUpCandidates(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: _config(),
          sourceSpeciesId: 'sproutle',
        ),
        throwsA(isA<RuntimeBattleSetupException>()),
      );

      await _writeSpecies(
        tempRoot,
        id: 'bloomon',
        primaryAbilityId: 'overgrow',
        progression: null,
      );
      await expectLater(
        () => RuntimePokemonEvolutionLoader().loadLevelUpCandidates(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: _config(),
          sourceSpeciesId: 'sproutle',
        ),
        throwsA(isA<RuntimeBattleSetupException>()),
      );
    });

    test('rejects unsafe target ids even when an external file exists',
        () async {
      for (final unsafeTargetId in <String>[
        '../target',
        'nested/target',
        r'nested\target',
        '.',
        '..',
        ' target',
      ]) {
        await _writeEvolution(tempRoot, <String, dynamic>{
          'speciesId': 'sproutle',
          'evolutions': <Object?>[
            <String, Object?>{
              'targetSpeciesId': unsafeTargetId,
              'method': 'level_up',
              'minLevel': 16,
            },
          ],
        });
        await _writeSpecies(
          tempRoot,
          id: unsafeTargetId,
          primaryAbilityId: 'overgrow',
        );

        await expectLater(
          () => RuntimePokemonEvolutionLoader().loadLevelUpCandidates(
            projectRootDirectory: tempRoot.path,
            pokemonConfig: _config(),
            sourceSpeciesId: 'sproutle',
          ),
          throwsA(
            isA<RuntimeBattleSetupException>().having(
              (error) => error.debugDetails,
              'debugDetails',
              contains('evolutions[0]'),
            ),
          ),
        );
      }
    });

    test('rejects absolute, escaping, and source-traversal paths', () async {
      for (final config in <ProjectPokemonConfig>[
        ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            evolutionsDir: tempRoot.path),
        const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            evolutionsDir: '../outside'),
      ]) {
        await expectLater(
          () => RuntimePokemonEvolutionLoader().loadLevelUpCandidates(
            projectRootDirectory: tempRoot.path,
            pokemonConfig: config,
            sourceSpeciesId: 'sproutle',
          ),
          throwsA(isA<RuntimeBattleSetupException>()),
        );
      }
      await expectLater(
        () => RuntimePokemonEvolutionLoader().loadLevelUpCandidates(
          projectRootDirectory: tempRoot.path,
          pokemonConfig: _config(),
          sourceSpeciesId: '../sproutle',
        ),
        throwsA(isA<RuntimeBattleSetupException>()),
      );
    });
  });
}

ProjectPokemonConfig _config() {
  return const ProjectPokemonConfig(
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    evolutionsDir: 'custom/evolutions',
    speciesDir: 'custom/species',
  );
}

Map<String, dynamic> _validEvolutionJson() {
  return <String, dynamic>{
    'speciesId': 'sproutle',
    'evolutions': <Object?>[
      <String, Object?>{
        'targetSpeciesId': 'bloomon',
        'method': 'level_up',
        'minLevel': 16,
      },
    ],
  };
}

Future<void> _writeEvolution(
  Directory root,
  Map<String, dynamic> json,
) async {
  final file = File(
    p.join(root.path, 'custom', 'evolutions', 'sproutle.json'),
  );
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(json));
}

Future<void> _writeSpecies(
  Directory root, {
  required String id,
  required String primaryAbilityId,
  String? secondaryAbilityId,
  int hp = 80,
  Object? progression = const <String, dynamic>{
    'growthRateId': 'medium',
    'baseExp': 100,
    'catchRate': 45,
  },
  Object? rawAbilities,
}) async {
  final file = File(p.join(root.path, 'custom', 'species', '$id.json'));
  await file.parent.create(recursive: true);
  await file.writeAsString(
    jsonEncode(<String, dynamic>{
      'schemaVersion': 1,
      'id': id,
      'typing': <String, dynamic>{
        'types': <String>['grass'],
      },
      'baseStats': <String, dynamic>{
        'hp': hp,
        'atk': 82,
        'def': 83,
        'spa': 100,
        'spd': 100,
        'spe': 80,
      },
      'abilities': rawAbilities ??
          <String, dynamic>{
            'primary': primaryAbilityId,
            'secondary': secondaryAbilityId,
            'hidden': null,
          },
      'refs': <String, dynamic>{'learnset': id},
      if (progression != null) 'progression': progression,
    }),
  );
}
