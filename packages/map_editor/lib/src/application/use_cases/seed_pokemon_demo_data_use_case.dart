import 'dart:convert';

import '../ports/project_workspace.dart';
import 'initialize_pokemon_project_storage_use_case.dart';

/// Seed un mini jeu de donnees Pokemon realiste dans le workspace projet.
///
/// Ce use case reste volontairement petit :
/// - il initialise d'abord la structure locale si besoin
/// - il ecrit uniquement dans le workspace projet utilisateur
/// - il ne touche jamais a `project.json`
/// - il ne remplace jamais un fichier metier deja existant
/// - il n'enrichit un catalogue existant que s'il est encore au format
///   scaffold vide du lot precedent
class SeedPokemonDemoDataUseCase {
  const SeedPokemonDemoDataUseCase({
    this.initializeStorage = const InitializePokemonProjectStorageUseCase(),
  });

  final InitializePokemonProjectStorageUseCase initializeStorage;

  Future<void> execute(ProjectWorkspace workspace) async {
    await initializeStorage.execute(workspace);

    for (final entry in _catalogSeeds.entries) {
      await _writeCatalogIfSeedable(
        workspace,
        relativePath: 'data/pokemon/catalogs/${entry.key}.json',
        catalogName: entry.key,
        scaffoldDescription: _catalogScaffoldDescriptions[entry.key]!,
        payload: entry.value,
      );
    }

    for (final entry in _speciesSeeds.entries) {
      await _writeJsonIfAbsent(
        workspace,
        'data/pokemon/species/${entry.key}',
        entry.value,
      );
    }

    for (final entry in _learnsetSeeds.entries) {
      await _writeJsonIfAbsent(
        workspace,
        'data/pokemon/learnsets/${entry.key}',
        entry.value,
      );
    }

    for (final entry in _evolutionSeeds.entries) {
      await _writeJsonIfAbsent(
        workspace,
        'data/pokemon/evolutions/${entry.key}',
        entry.value,
      );
    }

    for (final entry in _mediaSeeds.entries) {
      await _writeJsonIfAbsent(
        workspace,
        'data/pokemon/media/${entry.key}',
        entry.value,
      );
    }
  }

  Future<void> _writeCatalogIfSeedable(
    ProjectWorkspace workspace, {
    required String relativePath,
    required String catalogName,
    required String scaffoldDescription,
    required Map<String, Object?> payload,
  }) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    if (!await workspace.fileExists(absolutePath)) {
      await _writeJsonIfAbsent(workspace, relativePath, payload);
      return;
    }

    final currentRaw = await workspace.readTextFile(absolutePath);
    final dynamic decoded = jsonDecode(currentRaw);
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    if (!_matchesBootstrapScaffold(
      decoded,
      catalogName: catalogName,
      scaffoldDescription: scaffoldDescription,
    )) {
      return;
    }

    await workspace.writeTextFile(
      absolutePath,
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  bool _matchesBootstrapScaffold(
    Map<String, dynamic> json, {
    required String catalogName,
    required String scaffoldDescription,
  }) {
    final meta = json['meta'];
    final entries = json['entries'];
    if (meta is! Map<String, dynamic>) return false;
    if (entries is! List || entries.isNotEmpty) return false;

    final sourcePriority = meta['sourcePriority'];
    final notes = meta['notes'];
    if (json['schemaVersion'] != 1) return false;
    if (json['kind'] != 'pokemon_catalog') return false;
    if (json['catalog'] != catalogName) return false;
    if (meta['description'] != scaffoldDescription) return false;
    if (sourcePriority is! List || sourcePriority.length != 1) return false;
    if (sourcePriority.single != 'internal') return false;
    if (notes is! List || notes.isNotEmpty) return false;
    return true;
  }

  Future<void> _writeJsonIfAbsent(
    ProjectWorkspace workspace,
    String relativePath,
    Map<String, Object?> payload,
  ) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    if (await workspace.fileExists(absolutePath)) {
      return;
    }
    await workspace.writeTextFile(
      absolutePath,
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }
}

const Map<String, String> _catalogScaffoldDescriptions = <String, String>{
  'moves': 'Move catalog for the local Pokemon project database.',
  'abilities': 'Ability catalog for the local Pokemon project database.',
  'items': 'Item catalog for the local Pokemon project database.',
  'types': 'Type catalog for the local Pokemon project database.',
  'growth_rates': 'Growth rate catalog for the local Pokemon project database.',
  'natures': 'Nature catalog for the local Pokemon project database.',
  'egg_groups': 'Egg group catalog for the local Pokemon project database.',
  'habitats': 'Habitat catalog for the local Pokemon project database.',
  'generations': 'Generation catalog for the local Pokemon project database.',
  'version_groups':
      'Version group catalog for the local Pokemon project database.',
  'encounter_rules':
      'Encounter rule catalog for the local Pokemon project database.',
};

const Map<String, Map<String, Object?>> _catalogSeeds =
    <String, Map<String, Object?>>{
  'types': <String, Object?>{
    'schemaVersion': 1,
    'kind': 'pokemon_catalog',
    'catalog': 'types',
    'meta': <String, Object?>{
      'description': 'Type catalog for the local Pokemon project database.',
      'sourcePriority': <String>['internal'],
      'notes': <Object?>[
        'Demo seed data used to validate local Pokemon contracts.',
      ],
    },
    'entries': <Object?>[
      <String, Object?>{
        'id': 'grass',
        'name': 'Grass',
        'names': <String, String>{
          'fr': 'Plante',
          'en': 'Grass',
        },
        'damageRelations': <String, Object?>{
          'weakTo': <String>['fire', 'ice', 'poison', 'flying', 'bug'],
          'resists': <String>['water', 'electric', 'grass', 'ground'],
        },
      },
      <String, Object?>{
        'id': 'poison',
        'name': 'Poison',
        'names': <String, String>{
          'fr': 'Poison',
          'en': 'Poison',
        },
        'damageRelations': <String, Object?>{
          'weakTo': <String>['ground', 'psychic'],
          'resists': <String>['grass', 'fighting', 'poison', 'bug', 'fairy'],
        },
      },
    ],
  },
  'abilities': <String, Object?>{
    'schemaVersion': 1,
    'kind': 'pokemon_catalog',
    'catalog': 'abilities',
    'meta': <String, Object?>{
      'description': 'Ability catalog for the local Pokemon project database.',
      'sourcePriority': <String>['internal'],
      'notes': <Object?>[
        'Demo seed data used to validate local Pokemon contracts.',
      ],
    },
    'entries': <Object?>[
      <String, Object?>{
        'id': 'overgrow',
        'name': 'Overgrow',
        'names': <String, String>{
          'fr': 'Engrais',
          'en': 'Overgrow',
        },
        'shortDesc': 'Boosts Grass-type moves when the Pokemon is low on HP.',
        'generation': 3,
      },
      <String, Object?>{
        'id': 'chlorophyll',
        'name': 'Chlorophyll',
        'names': <String, String>{
          'fr': 'Chlorophylle',
          'en': 'Chlorophyll',
        },
        'shortDesc': 'Doubles Speed in harsh sunlight.',
        'generation': 3,
      },
    ],
  },
  'growth_rates': <String, Object?>{
    'schemaVersion': 1,
    'kind': 'pokemon_catalog',
    'catalog': 'growth_rates',
    'meta': <String, Object?>{
      'description':
          'Growth rate catalog for the local Pokemon project database.',
      'sourcePriority': <String>['internal'],
      'notes': <Object?>[
        'Demo seed data used to validate local Pokemon contracts.',
      ],
    },
    'entries': <Object?>[
      <String, Object?>{
        'id': 'medium_slow',
        'name': 'Medium Slow',
        'description': 'Uses the classic medium-slow experience curve.',
      },
    ],
  },
  'moves': <String, Object?>{
    'schemaVersion': 1,
    'kind': 'pokemon_catalog',
    'catalog': 'moves',
    'meta': <String, Object?>{
      'description': 'Move catalog for the local Pokemon project database.',
      'sourcePriority': <String>['internal'],
      'notes': <Object?>[
        'Demo seed data used to validate local Pokemon contracts.',
      ],
    },
    'entries': <Object?>[
      <String, Object?>{
        'id': 'tackle',
        'name': 'Tackle',
        'names': <String, String>{
          'fr': 'Charge',
          'en': 'Tackle',
        },
        'type': 'normal',
        'category': 'physical',
        'power': 40,
        'accuracy': 100,
        'pp': 35,
        'priority': 0,
        'target': 'adjacent_opponent',
        'shortDesc': 'A physical attack in which the user charges and slams.',
        'generation': 1,
      },
      <String, Object?>{
        'id': 'growl',
        'name': 'Growl',
        'names': <String, String>{
          'fr': 'Rugissement',
          'en': 'Growl',
        },
        'type': 'normal',
        'category': 'status',
        'power': null,
        'accuracy': 100,
        'pp': 40,
        'priority': 0,
        'target': 'adjacent_opponent',
        'shortDesc': 'Lowers the target Attack by one stage.',
        'generation': 1,
      },
      <String, Object?>{
        'id': 'vine_whip',
        'name': 'Vine Whip',
        'names': <String, String>{
          'fr': 'Fouet Lianes',
          'en': 'Vine Whip',
        },
        'type': 'grass',
        'category': 'physical',
        'power': 45,
        'accuracy': 100,
        'pp': 25,
        'priority': 0,
        'target': 'adjacent_opponent',
        'shortDesc': 'Strikes the target with slender, whiplike vines.',
        'generation': 1,
      },
      <String, Object?>{
        'id': 'razor_leaf',
        'name': 'Razor Leaf',
        'names': <String, String>{
          'fr': 'Tranch’Herbe',
          'en': 'Razor Leaf',
        },
        'type': 'grass',
        'category': 'physical',
        'power': 55,
        'accuracy': 95,
        'pp': 25,
        'priority': 0,
        'target': 'all_adjacent_opponents',
        'shortDesc':
            'Sharp-edged leaves are launched to slash at the opposing team.',
        'generation': 1,
      },
    ],
  },
};

const Map<String, Map<String, Object?>> _speciesSeeds =
    <String, Map<String, Object?>>{
  '0001-bulbasaur.json': <String, Object?>{
    'id': 'bulbasaur',
    'slug': 'bulbasaur',
    'nationalDex': 1,
    'names': <String, String>{
      'fr': 'Bulbizarre',
      'en': 'Bulbasaur',
    },
    'speciesName': <String, String>{
      'fr': 'Pokémon Graine',
      'en': 'Seed Pokemon',
    },
    'genIntroduced': 1,
    'typing': <String, Object?>{
      'types': <String>['grass', 'poison'],
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
    'abilities': <String, Object?>{
      'primary': 'overgrow',
      'secondary': null,
      'hidden': 'chlorophyll',
    },
    'breeding': <String, Object?>{
      'genderRatio': <String, double>{
        'male': 0.875,
        'female': 0.125,
      },
      'eggGroups': <String>['monster', 'grass'],
      'hatchCycles': 20,
    },
    'progression': <String, Object?>{
      'growthRateId': 'medium_slow',
      'baseExp': 64,
      'catchRate': 45,
      'baseFriendship': 50,
    },
    'refs': <String, Object?>{
      'learnset': 'bulbasaur',
      'evolution': 'bulbasaur',
      'media': 'bulbasaur',
    },
    'dexContent': <String, Object?>{
      'heightM': 0.7,
      'weightKg': 6.9,
      'color': 'green',
      'flavorText':
          'A strange seed was planted on its back at birth. The plant sprouts and grows with this Pokemon.',
    },
    'gameplayFlags': <String, Object?>{
      'starterEligible': true,
      'giftOnly': false,
      'tradeOnly': false,
    },
    'sourceMeta': <String, Object?>{
      'seededBy': 'SeedPokemonDemoDataUseCase',
      'seedVersion': 1,
    },
  },
  '0002-ivysaur.json': <String, Object?>{
    'id': 'ivysaur',
    'slug': 'ivysaur',
    'nationalDex': 2,
    'names': <String, String>{
      'fr': 'Herbizarre',
      'en': 'Ivysaur',
    },
    'speciesName': <String, String>{
      'fr': 'Pokémon Graine',
      'en': 'Seed Pokemon',
    },
    'genIntroduced': 1,
    'typing': <String, Object?>{
      'types': <String>['grass', 'poison'],
    },
    'baseStats': <String, Object?>{
      'hp': 60,
      'atk': 62,
      'def': 63,
      'spa': 80,
      'spd': 80,
      'spe': 60,
      'bst': 405,
    },
    'abilities': <String, Object?>{
      'primary': 'overgrow',
      'secondary': null,
      'hidden': 'chlorophyll',
    },
    'breeding': <String, Object?>{
      'genderRatio': <String, double>{
        'male': 0.875,
        'female': 0.125,
      },
      'eggGroups': <String>['monster', 'grass'],
      'hatchCycles': 20,
    },
    'progression': <String, Object?>{
      'growthRateId': 'medium_slow',
      'baseExp': 142,
      'catchRate': 45,
      'baseFriendship': 50,
    },
    'refs': <String, Object?>{
      'learnset': 'ivysaur',
      'evolution': 'ivysaur',
      'media': 'ivysaur',
    },
    'dexContent': <String, Object?>{
      'heightM': 1.0,
      'weightKg': 13.0,
      'color': 'green',
      'flavorText':
          'When the bulb on its back grows large, it appears to lose the ability to stand on its hind legs.',
    },
    'gameplayFlags': <String, Object?>{
      'starterEligible': false,
      'giftOnly': false,
      'tradeOnly': false,
    },
    'sourceMeta': <String, Object?>{
      'seededBy': 'SeedPokemonDemoDataUseCase',
      'seedVersion': 1,
    },
  },
};

const Map<String, Map<String, Object?>> _learnsetSeeds =
    <String, Map<String, Object?>>{
  'bulbasaur.json': <String, Object?>{
    'speciesId': 'bulbasaur',
    'startingMoves': <String>['tackle', 'growl'],
    'relearnMoves': <String>['tackle', 'growl', 'vine_whip', 'razor_leaf'],
    'levelUp': <Object?>[
      <String, Object?>{
        'moveId': 'tackle',
        'level': 1,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
      <String, Object?>{
        'moveId': 'growl',
        'level': 3,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
      <String, Object?>{
        'moveId': 'vine_whip',
        'level': 7,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
      <String, Object?>{
        'moveId': 'razor_leaf',
        'level': 13,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
    ],
    'tm': <Object?>[
      <String, Object?>{
        'moveId': 'growl',
        'versionGroup': 'demo',
      },
    ],
    'tutor': <Object?>[],
    'egg': <Object?>[],
    'event': <Object?>[],
    'transfer': <Object?>[],
  },
  'ivysaur.json': <String, Object?>{
    'speciesId': 'ivysaur',
    'startingMoves': <String>['tackle', 'growl', 'vine_whip'],
    'relearnMoves': <String>['tackle', 'growl', 'vine_whip', 'razor_leaf'],
    'levelUp': <Object?>[
      <String, Object?>{
        'moveId': 'tackle',
        'level': 1,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
      <String, Object?>{
        'moveId': 'growl',
        'level': 1,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
      <String, Object?>{
        'moveId': 'vine_whip',
        'level': 1,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
      <String, Object?>{
        'moveId': 'razor_leaf',
        'level': 20,
        'source': 'level_up',
        'versionGroup': 'demo',
      },
    ],
    'tm': <Object?>[],
    'tutor': <Object?>[],
    'egg': <Object?>[],
    'event': <Object?>[],
    'transfer': <Object?>[],
  },
};

const Map<String, Map<String, Object?>> _evolutionSeeds =
    <String, Map<String, Object?>>{
  'bulbasaur.json': <String, Object?>{
    'speciesId': 'bulbasaur',
    'preEvolution': null,
    'evolutions': <Object?>[
      <String, Object?>{
        'targetSpeciesId': 'ivysaur',
        'method': 'level_up',
        'minLevel': 16,
        'itemId': null,
        'requiredMoveId': null,
        'conditionText': <String, String>{
          'fr': 'Évolue au niveau 16',
          'en': 'Evolves at level 16',
        },
      },
    ],
  },
  'ivysaur.json': <String, Object?>{
    'speciesId': 'ivysaur',
    'preEvolution': 'bulbasaur',
    'evolutions': <Object?>[],
  },
};

const Map<String, Map<String, Object?>> _mediaSeeds =
    <String, Map<String, Object?>>{
  'bulbasaur.json': <String, Object?>{
    'speciesId': 'bulbasaur',
    'defaultFormId': 'base',
    'variants': <String, Object?>{
      'base': <String, Object?>{
        'frontStatic': 'assets/pokemon/sprites/bulbasaur/front.png',
        'backStatic': 'assets/pokemon/sprites/bulbasaur/back.png',
        'frontShinyStatic': 'assets/pokemon/sprites/bulbasaur/front_shiny.png',
        'backShinyStatic': 'assets/pokemon/sprites/bulbasaur/back_shiny.png',
        'icon': 'assets/pokemon/sprites/bulbasaur/icon.png',
        'party': 'assets/pokemon/sprites/bulbasaur/party.png',
        'overworld': 'assets/pokemon/sprites/bulbasaur/overworld.png',
        'portrait': 'assets/pokemon/portraits/bulbasaur.png',
        'cry': 'assets/pokemon/cries/bulbasaur.ogg',
        'animations': <String, Object?>{
          'battleFront': <String, Object?>{
            'sheet': 'assets/pokemon/sprites/bulbasaur/battle_front_sheet.png',
            'animationId': 'battle_front',
          },
          'battleBack': <String, Object?>{
            'sheet': 'assets/pokemon/sprites/bulbasaur/battle_back_sheet.png',
            'animationId': 'battle_back',
          },
        },
      },
    },
  },
  'ivysaur.json': <String, Object?>{
    'speciesId': 'ivysaur',
    'defaultFormId': 'base',
    'variants': <String, Object?>{
      'base': <String, Object?>{
        'frontStatic': 'assets/pokemon/sprites/ivysaur/front.png',
        'backStatic': 'assets/pokemon/sprites/ivysaur/back.png',
        'icon': 'assets/pokemon/sprites/ivysaur/icon.png',
        'party': 'assets/pokemon/sprites/ivysaur/party.png',
        'overworld': 'assets/pokemon/sprites/ivysaur/overworld.png',
        'portrait': 'assets/pokemon/portraits/ivysaur.png',
        'cry': 'assets/pokemon/cries/ivysaur.ogg',
        'animations': <String, Object?>{
          'battleFront': <String, Object?>{
            'sheet': 'assets/pokemon/sprites/ivysaur/battle_front_sheet.png',
            'animationId': 'battle_front',
          },
        },
      },
    },
  },
};
