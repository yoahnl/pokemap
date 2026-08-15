import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('direct and JSONL validation expose the same Pokemon gate', () async {
    final root = await Directory.systemTemp.createTemp(
      'pokemon-catalog-validation-',
    );
    addTearDown(() => root.delete(recursive: true));
    await _writeFixture(root);

    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final api = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    );
    final worker = JsonlWorker(api: api);
    final opened = await api.openProject(root.path);

    final direct = await api.validate(opened.projectHandle);
    final transported = AuthoringResult.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
          await worker.processLine(
            jsonEncode(<String, Object?>{
              'id': 'pokemon-validation',
              'command': 'validate',
              'args': <String, Object?>{
                'projectHandle': opened.projectHandle.value,
              },
            }),
          ),
        ) as Map,
      ),
    );

    expect(transported.status, AuthoringResultStatus.success);
    expect(transported.data, direct);
    expect(direct['valid'], isFalse);
    final pokemon = Map<String, Object?>.from(direct['pokemonCatalog']! as Map);
    expect(pokemon['canPlaytest'], isFalse);
    expect(pokemon['canExport'], isFalse);
    final diagnostics = (pokemon['diagnostics']! as List)
        .map((value) => Map<String, Object?>.from(value as Map))
        .toList(growable: false);
    final missingAbility = diagnostics.singleWhere(
      (diagnostic) =>
          diagnostic['code'] == 'species.ability_missing_in_catalog',
    );
    expect(missingAbility['severity'], 'error');
    expect(missingAbility['path'], contains('custom/species'));
    expect(missingAbility['recommendedAction'], isNotEmpty);
    final missingItem = diagnostics.singleWhere(
      (diagnostic) => diagnostic['code'] == 'evolution.item_missing',
    );
    expect(missingItem['path'], contains('custom/evolutions'));
    final invalidLevel = diagnostics.singleWhere(
      (diagnostic) => diagnostic['code'] == 'learnset.level_up_level_invalid',
    );
    expect(invalidLevel['path'], contains('custom/learnsets'));
  });
}

Future<void> _writeFixture(Directory root) async {
  final pokemon = const ProjectPokemonConfig(
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    speciesDir: 'custom/species',
    learnsetsDir: 'custom/learnsets',
    evolutionsDir: 'custom/evolutions',
    mediaDir: 'custom/media',
    catalogFiles: <String, String>{
      'types': 'custom/catalogs/types.json',
      'abilities': 'custom/catalogs/abilities.json',
      'moves': 'custom/catalogs/moves.json',
      'growth_rates': 'custom/catalogs/growth_rates.json',
      'items': 'custom/catalogs/items.json',
    },
  );
  final manifest = ProjectManifest(
    name: 'Pokemon validation transport fixture',
    maps: const [],
    tilesets: const [],
    pokemon: pokemon,
  );
  await _writeJson(root, 'project.json', manifest.toJson());
  for (final entry in <String, List<String>>{
    'types': <String>['grass'],
    'abilities': <String>['overgrow'],
    'moves': <String>['tackle'],
    'growth_rates': <String>['medium_slow'],
  }.entries) {
    await _writeJson(root, 'custom/catalogs/${entry.key}.json', {
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': entry.key,
      'meta': <String, Object?>{'description': entry.key},
      'entries': <Object?>[
        for (final id in entry.value) <String, Object?>{'id': id},
      ],
    });
  }
  await _writeJson(root, 'custom/catalogs/items.json', {
    'schemaVersion': 1,
    'entries': <Object?>[
      <String, Object?>{
        'id': 'leaf-stone',
        'displayName': 'Leaf Stone',
        'aliases': <String>[],
        'pocketId': 'items',
        'tags': <String>[],
        'uses': <Object?>[],
      },
    ],
  });
  await _writeJson(root, 'custom/species/sproutle.json', {
    'schemaVersion': 1,
    'id': 'sproutle',
    'slug': 'sproutle',
    'nationalDex': 1,
    'names': <String, String>{'en': 'Sproutle'},
    'speciesName': <String, String>{'en': 'Seed Pokemon'},
    'genIntroduced': 1,
    'typing': <String, Object?>{
      'types': <String>['grass'],
    },
    'baseStats': <String, Object?>{
      'hp': 45,
      'atk': 49,
      'def': 49,
      'spa': 65,
      'spd': 65,
      'spe': 45,
      'bst': 318,
    },
    'abilities': <String, Object?>{'primary': 'missing-ability'},
    'breeding': <String, Object?>{
      'genderRatio': <String, double>{},
    },
    'progression': <String, Object?>{
      'growthRateId': 'medium_slow',
      'baseExp': 64,
      'catchRate': 45,
      'baseFriendship': 50,
    },
    'forms': <String, Object?>{
      'baseFormId': 'sproutle',
      'isBaseForm': true,
      'formId': 'base',
      'otherForms': <String>[],
    },
    'refs': <String, Object?>{
      'learnset': 'sproutle',
      'evolution': 'sproutle',
      'media': 'sproutle',
    },
  });
  await _writeJson(root, 'custom/learnsets/sproutle.json', {
    'schemaVersion': 1,
    'speciesId': 'sproutle',
    'startingMoves': <String>['tackle'],
    'levelUp': <Object?>[
      <String, Object?>{
        'moveId': 'tackle',
        'level': 101,
        'source': 'level_up',
        'versionGroup': 'beta',
      },
    ],
  });
  await _writeJson(root, 'custom/evolutions/sproutle.json', {
    'schemaVersion': 1,
    'speciesId': 'sproutle',
    'evolutions': <Object?>[
      <String, Object?>{
        'targetSpeciesId': 'sproutle-evolved',
        'method': 'use_item',
        'itemId': 'missing-stone',
      },
    ],
  });
  await _writeJson(root, 'custom/media/sproutle.json', {
    'schemaVersion': 1,
    'speciesId': 'sproutle',
    'defaultFormId': 'base',
    'variants': <String, Object?>{
      'base': <String, Object?>{
        'frontStatic': 'assets/pokemon/sproutle-front.png',
        'backStatic': 'assets/pokemon/sproutle-back.png',
      },
    },
  });
}

Future<void> _writeJson(
  Directory root,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final file = File('${root.path}/$relativePath');
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(json));
}
