import 'dart:convert';
import 'dart:io';

import 'package:PokeMap_Loader/src/runtime_demo_party_seed.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildRuntimeHostLaunchDemoPartySeed', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('runtime_host_seed_');
    });

    tearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    test('returns null when demo seed is disabled', () async {
      await _writeProjectFixture(root);

      final seed = await buildRuntimeHostLaunchDemoPartySeed(
        seedDemoPokemon: false,
        projectFilePath: '${root.path}/project.json',
      );

      expect(seed, isNull);
    });

    test('builds a seeded demo party with two usable pokemon when enabled',
        () async {
      await _writeProjectFixture(
        root,
        includeSquirtle: true,
      );

      final seed = await buildRuntimeHostLaunchDemoPartySeed(
        seedDemoPokemon: true,
        projectFilePath: '${root.path}/project.json',
      );

      expect(seed, isNotNull);
      expect(seed!.members, hasLength(2));
      expect(seed.members.first.speciesId, equals('squirtle'));
      expect(seed.members.first.level, equals(kRuntimeDemoSeedLevel));
      expect(
        seed.members.first.knownMoveIds,
        equals(<String>['tackle', 'tail_whip', 'bubble', 'water_gun']),
      );
      expect(seed.members.last.speciesId, equals('bulbasaur'));
      expect(seed.members.last.currentHp, equals(kRuntimeDemoSeedCurrentHp));
      expect(
        seed.members.last.knownMoveIds,
        equals(<String>['tackle', 'growl', 'vine_whip', 'razor_leaf']),
      );
    });

    test('builds a seeded save with one usable pokemon when enabled', () async {
      await _writeProjectFixture(root);

      final seed = await buildRuntimeHostLaunchDemoPartySeed(
        seedDemoPokemon: true,
        projectFilePath: '${root.path}/project.json',
      );

      expect(seed, isNotNull);
      expect(seed!.members, hasLength(1));
      final member = seed.members.single;
      expect(member.speciesId, equals('bulbasaur'));
      expect(member.level, equals(kRuntimeDemoSeedLevel));
      expect(member.currentHp, equals(kRuntimeDemoSeedCurrentHp));
      expect(member.abilityId, equals('overgrow'));
      expect(
        member.knownMoveIds,
        equals(<String>['tackle', 'growl', 'vine_whip', 'razor_leaf']),
      );
    });

    test('prefers Squirtle over Abra when both are available', () async {
      await _writeProjectFixture(
        root,
        includeAbra: true,
        includeSquirtle: true,
      );

      final seed = await buildRuntimeHostLaunchDemoPartySeed(
        seedDemoPokemon: true,
        projectFilePath: '${root.path}/project.json',
      );

      expect(seed, isNotNull);
      final member = seed!.members.first;
      expect(member.speciesId, equals('squirtle'));
      expect(member.abilityId, equals('torrent'));
      expect(
        member.knownMoveIds,
        equals(<String>['tackle', 'tail_whip', 'bubble', 'water_gun']),
      );
    });

    test('derives a stable gender from breeding ratios when available',
        () async {
      await _writeProjectFixture(
        root,
        includeSquirtle: true,
        includeGenderRatio: true,
      );

      final seed = await buildRuntimeHostLaunchDemoPartySeed(
        seedDemoPokemon: true,
        projectFilePath: '${root.path}/project.json',
      );

      expect(seed, isNotNull);
      final member = seed!.members.first;
      expect(member.speciesId, equals('squirtle'));
      expect(member.gender, anyOf(equals('male'), equals('female')));
    });

    test(
        'resolves a preferred demo species without parsing unrelated bad species files',
        () async {
      await _writeProjectFixture(
        root,
        includeSquirtle: true,
        squirtleFileName: '0007-squirtle.json',
      );
      await File('${root.path}/data/pokemon/species/9999-broken.json')
          .writeAsString('{ definitely not valid json');

      final seed = await buildRuntimeHostLaunchDemoPartySeed(
        seedDemoPokemon: true,
        projectFilePath: '${root.path}/project.json',
      );

      expect(seed, isNotNull);
      final member = seed!.members.first;
      expect(member.speciesId, equals('squirtle'));
      expect(member.abilityId, equals('torrent'));
    });

    test('builds a demo save with seeded bag entries', () async {
      const seed = RuntimeDemoPartySeed(
        members: <RuntimeDemoPartyPokemonSeed>[
          RuntimeDemoPartyPokemonSeed(
            speciesId: 'squirtle',
            abilityId: 'torrent',
            gender: 'male',
            level: 25,
            currentHp: 60,
            knownMoveIds: <String>['tackle', 'tail_whip'],
          ),
        ],
      );

      final saveData = buildRuntimeHostLaunchDemoSaveData(
        mapId: 'lab',
        seed: seed,
      );

      expect(saveData.saveId, equals(kRuntimeDemoSeedSaveId));
      expect(saveData.currentMapId, equals('lab'));
      expect(saveData.party.members, hasLength(1));
      expect(saveData.party.members.single.speciesId, equals('squirtle'));
      expect(
          saveData.bag.entries,
          equals(const <BagEntry>[
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 5),
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
            BagEntry(
              itemId: 'super-potion',
              categoryId: 'medicine',
              quantity: 6,
            ),
            BagEntry(
              itemId: 'hyper-potion',
              categoryId: 'medicine',
              quantity: 6,
            ),
          ]));
    });

    test('loads selectable pokemon options with display names and moves',
        () async {
      await _writeProjectFixture(
        root,
        includeSquirtle: true,
      );

      final options = await loadRuntimeHostPartyBuilderOptions(
        projectFilePath: '${root.path}/project.json',
      );

      expect(options.map((option) => option.speciesId), contains('bulbasaur'));
      expect(options.map((option) => option.speciesId), contains('squirtle'));

      final bulbasaur = options.singleWhere(
        (option) => option.speciesId == 'bulbasaur',
      );
      expect(bulbasaur.displayName, equals('Bulbasaur'));
      expect(bulbasaur.label, equals('Bulbasaur (bulbasaur)'));
      expect(bulbasaur.abilityId, equals('overgrow'));
      expect(
        bulbasaur.availableMoveIds,
        equals(<String>['tackle', 'growl', 'vine_whip', 'razor_leaf']),
      );
      expect(
        bulbasaur.suggestedMoveIds,
        equals(<String>['tackle', 'growl', 'vine_whip', 'razor_leaf']),
      );
    });

    test('filters picker suggestions to moves bridgeable by the battle runtime',
        () async {
      await _writeProjectFixture(
        root,
        includeMew: true,
      );

      final options = await loadRuntimeHostPartyBuilderOptions(
        projectFilePath: '${root.path}/project.json',
      );

      final mew = options.singleWhere((option) => option.speciesId == 'mew');
      expect(
        mew.suggestedMoveIds,
        equals(<String>['pound', 'transform', 'mega_punch', 'swift']),
      );
      expect(mew.availableMoveIds, isNot(contains('baton_pass')));
      expect(mew.availableMoveIds, isNot(contains('metronome')));
      expect(
        mew.filteredMoveIds,
        equals(<String>['baton_pass', 'metronome']),
      );
      expect(mew.filteredMoveDiagnostics, hasLength(2));
      expect(mew.moveDiagnostics['transform']?.bridgeable, isTrue);
      expect(mew.moveDiagnostics['transform']?.battleEngineMethod,
          equals('s_transform'));
      expect(
        mew.moveDiagnostics['transform']?.psdkRegistryStatus,
        equals('partial'),
      );
      expect(mew.moveDiagnostics['baton_pass']?.bridgeable, isFalse);
      expect(
        mew.moveDiagnostics['baton_pass']?.reason,
        equals('unsupported_effect_kind:self_switch'),
      );
      expect(mew.moveDiagnostics['baton_pass']?.battleEngineMethod,
          equals('s_baton_pass'));
      expect(
        mew.moveDiagnostics['baton_pass']?.psdkRegistryStatus,
        equals('partial'),
      );
      expect(mew.moveDiagnostics['baton_pass']?.psdkPartial, isTrue);
    });
  });
}

Future<void> _writeProjectFixture(
  Directory root, {
  bool includeAbra = false,
  bool includeSquirtle = false,
  bool includeMew = false,
  bool includeGenderRatio = false,
  String squirtleFileName = '0007-squirtle.json',
}) async {
  await File('${root.path}/project.json').writeAsString(
    jsonEncode(<String, dynamic>{
      'name': 'Runtime Host Seed Test',
      'maps': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'lab',
          'name': 'Lab',
          'relativePath': 'maps/lab.json',
        },
      ],
      'tilesets': const <Map<String, dynamic>>[],
      'pokemon': <String, dynamic>{
        'enabled': true,
        'speciesDir': 'data/pokemon/species',
        'learnsetsDir': 'data/pokemon/learnsets',
        'catalogFiles': <String, String>{
          'moves': 'data/pokemon/catalogs/moves.json',
        },
      },
    }),
  );

  await _writeJson(
    root,
    'data/pokemon/species/0001-bulbasaur.json',
    <String, dynamic>{
      'id': 'bulbasaur',
      'nationalDex': 1,
      'names': <String, String>{'en': 'Bulbasaur'},
      'typing': <String, Object>{
        'types': <String>['grass', 'poison'],
      },
      'abilities': <String, String>{'primary': 'overgrow'},
      'refs': <String, String>{
        'learnset': 'bulbasaur',
        'evolution': 'bulbasaur',
        'media': 'bulbasaur',
      },
      'classification': <String, bool>{'isEnabledInProject': true},
    },
  );

  await _writeJson(
    root,
    'data/pokemon/learnsets/bulbasaur.json',
    <String, dynamic>{
      'speciesId': 'bulbasaur',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['growl'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'vine_whip',
          'level': 5,
          'source': 'level_up',
          'versionGroup': 'demo',
        },
        <String, Object>{
          'moveId': 'razor_leaf',
          'level': 20,
          'source': 'level_up',
          'versionGroup': 'demo',
        },
      ],
    },
  );

  if (includeAbra) {
    await _writeJson(
      root,
      'data/pokemon/species/0063-abra.json',
      <String, dynamic>{
        'id': 'abra',
        'nationalDex': 63,
        'names': <String, String>{'en': 'Abra'},
        'typing': <String, Object>{
          'types': <String>['psychic'],
        },
        'abilities': <String, String>{'primary': 'synchronize'},
        'refs': <String, String>{
          'learnset': 'abra',
          'evolution': 'abra',
          'media': 'abra',
        },
        'classification': <String, bool>{'isEnabledInProject': true},
      },
    );

    await _writeJson(
      root,
      'data/pokemon/learnsets/abra.json',
      <String, dynamic>{
        'speciesId': 'abra',
        'startingMoves': <String>['teleport'],
        'relearnMoves': <String>['kinesis'],
        'levelUp': const <Map<String, Object>>[],
      },
    );
  }

  if (includeSquirtle) {
    await _writeJson(
      root,
      'data/pokemon/species/$squirtleFileName',
      <String, dynamic>{
        'id': 'squirtle',
        'nationalDex': 7,
        'names': <String, String>{'en': 'Squirtle'},
        'typing': <String, Object>{
          'types': <String>['water'],
        },
        'abilities': <String, String>{'primary': 'torrent'},
        'refs': <String, String>{
          'learnset': 'squirtle',
          'evolution': 'squirtle',
          'media': 'squirtle',
        },
        if (includeGenderRatio)
          'breeding': <String, Object>{
            'genderRatio': <String, double>{
              'male': 0.875,
              'female': 0.125,
            },
          },
        'classification': <String, bool>{'isEnabledInProject': true},
      },
    );

    await _writeJson(
      root,
      'data/pokemon/learnsets/squirtle.json',
      <String, dynamic>{
        'speciesId': 'squirtle',
        'startingMoves': <String>['tackle'],
        'relearnMoves': <String>['tail_whip'],
        'levelUp': <Map<String, Object>>[
          <String, Object>{
            'moveId': 'bubble',
            'level': 4,
            'source': 'level_up',
            'versionGroup': 'demo',
          },
          <String, Object>{
            'moveId': 'water_gun',
            'level': 7,
            'source': 'level_up',
            'versionGroup': 'demo',
          },
        ],
      },
    );
  }

  if (includeMew) {
    await _writeJson(
      root,
      'data/pokemon/species/0151-mew.json',
      <String, dynamic>{
        'id': 'mew',
        'nationalDex': 151,
        'names': <String, String>{'en': 'Mew'},
        'typing': <String, Object>{
          'types': <String>['psychic'],
        },
        'abilities': <String, String>{'primary': 'synchronize'},
        'refs': <String, String>{
          'learnset': 'mew',
          'evolution': 'mew',
          'media': 'mew',
        },
        'classification': <String, bool>{'isEnabledInProject': true},
      },
    );

    await _writeJson(
      root,
      'data/pokemon/learnsets/mew.json',
      <String, dynamic>{
        'speciesId': 'mew',
        'startingMoves': <String>['pound', 'transform'],
        'relearnMoves': <String>['mimic'],
        'levelUp': <Map<String, Object>>[
          <String, Object>{
            'moveId': 'mega_punch',
            'level': 10,
            'source': 'level_up',
            'versionGroup': 'demo',
          },
          <String, Object>{
            'moveId': 'swift',
            'level': 20,
            'source': 'level_up',
            'versionGroup': 'demo',
          },
          <String, Object>{
            'moveId': 'baton_pass',
            'level': 22,
            'source': 'level_up',
            'versionGroup': 'demo',
          },
          <String, Object>{
            'moveId': 'metronome',
            'level': 25,
            'source': 'level_up',
            'versionGroup': 'demo',
          },
        ],
      },
    );
  }

  await _writeJson(
    root,
    'data/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'entries': <Map<String, Object?>>[
        _moveEntry('tackle', 'Tackle', 40),
        _moveEntry('growl', 'Growl', 0),
        _moveEntry('vine_whip', 'Vine Whip', 45, type: 'grass'),
        _moveEntry('razor_leaf', 'Razor Leaf', 55, type: 'grass'),
        _moveEntry('tail_whip', 'Tail Whip', 0),
        _moveEntry('bubble', 'Bubble', 40, type: 'water'),
        _moveEntry('water_gun', 'Water Gun', 40, type: 'water'),
        _moveEntry('pound', 'Pound', 40),
        _moveEntry(
          'transform',
          'Transform',
          0,
          target: PokemonMoveTarget.normal,
        ),
        _moveEntry('mega_punch', 'Mega Punch', 80, accuracy: 85),
        _moveEntry(
          'swift',
          'Swift',
          60,
          target: PokemonMoveTarget.allAdjacentFoes,
          accuracy: null,
        ),
        _moveEntry(
          'baton_pass',
          'Baton Pass',
          0,
          target: PokemonMoveTarget.self,
          effects: const <PokemonMoveEffect>[
            PokemonMoveEffect.selfSwitch(),
          ],
        ),
        _moveEntry(
          'metronome',
          'Metronome',
          0,
          target: PokemonMoveTarget.self,
          supportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
          unsupportedReasons: const <String>['unsupported_mechanic:callsMove'],
        ),
      ],
    },
  );
}

Map<String, Object?> _moveEntry(
  String id,
  String name,
  int power, {
  String type = 'normal',
  PokemonMoveTarget target = PokemonMoveTarget.normal,
  int? accuracy = 100,
  List<PokemonMoveEffect> effects = const <PokemonMoveEffect>[],
  PokemonMoveEngineSupportLevel supportLevel =
      PokemonMoveEngineSupportLevel.structuredSupported,
  List<String> unsupportedReasons = const <String>[],
}) {
  final resolvedEffects = effects.isEmpty ? _defaultMoveEffects(id) : effects;
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: 1,
    source: 'test_runtime_fixture',
    type: type,
    category:
        power == 0 ? PokemonMoveCategory.status : PokemonMoveCategory.physical,
    target: target,
    basePower: power,
    accuracy: accuracy == null
        ? const PokemonMoveAccuracy.alwaysHits()
        : PokemonMoveAccuracy.percent(value: accuracy),
    pp: 20,
    effects: resolvedEffects,
    engineSupportLevel: supportLevel,
    unsupportedReasons: unsupportedReasons,
  ).toJson();
}

List<PokemonMoveEffect> _defaultMoveEffects(String moveId) {
  return switch (moveId) {
    'growl' => const <PokemonMoveEffect>[
        PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.target,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.attack,
              stages: -1,
            ),
          ],
        ),
      ],
    'tail_whip' => const <PokemonMoveEffect>[
        PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.target,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.defense,
              stages: -1,
            ),
          ],
        ),
      ],
    _ => const <PokemonMoveEffect>[],
  };
}

Future<void> _writeJson(
  Directory root,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final file = File.fromUri(root.uri.resolve(relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(json));
}
