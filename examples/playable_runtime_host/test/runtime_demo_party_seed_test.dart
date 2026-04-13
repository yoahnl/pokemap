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
  });
}

Future<void> _writeProjectFixture(Directory root) async {
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
