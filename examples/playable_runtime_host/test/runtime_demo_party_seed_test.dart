import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:playable_runtime_host/src/runtime_demo_party_seed.dart';

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

    test('builds a seeded save with one usable pokemon when enabled', () async {
      await _writeProjectFixture(root);

      final seed = await buildRuntimeHostLaunchDemoPartySeed(
        seedDemoPokemon: true,
        projectFilePath: '${root.path}/project.json',
      );

      expect(seed, isNotNull);
      expect(seed!.speciesId, equals('bulbasaur'));
      expect(seed.level, equals(kRuntimeDemoSeedLevel));
      expect(seed.currentHp, equals(kRuntimeDemoSeedCurrentHp));
      expect(seed.abilityId, equals('overgrow'));
      expect(
        seed.knownMoveIds,
        equals(<String>['tackle', 'growl', 'vine_whip']),
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
      expect(seed!.speciesId, equals('squirtle'));
      expect(seed.abilityId, equals('torrent'));
      expect(
        seed.knownMoveIds,
        equals(<String>['tackle', 'tail_whip', 'bubble', 'water_gun']),
      );
    });

    test('derives a stable gender from breeding ratios when available', () async {
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
      expect(seed!.speciesId, equals('squirtle'));
      expect(seed.gender, anyOf(equals('male'), equals('female')));
    });
  });
}

Future<void> _writeProjectFixture(
  Directory root, {
  bool includeAbra = false,
  bool includeSquirtle = false,
  bool includeGenderRatio = false,
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
      'data/pokemon/species/0007-squirtle.json',
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
