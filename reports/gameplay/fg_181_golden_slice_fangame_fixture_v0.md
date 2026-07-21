# FG-181 — Golden Slice Fangame Fixture V0

Date: 2026-07-21

Proposed status: **DONE**

## Résumé exécutif

Une Golden Slice autonome et versionnée existe désormais sous
`examples/playable_runtime_host/golden_fangame_slice`. Elle contient exactement
trois maps, une configuration New Game avec trois starters, une rencontre
sauvage, un trainer et un walkthrough ordonné couvrant les treize preuves du
parcours MVP. Elle n'embarque aucun raster : seules les données Pokémon et
moves strictement nécessaires sont versionnées.

## Scope et décisions

- Lot exact : `FG-181 — Golden Slice Fangame Fixture V0`.
- Les fichiers utilisent les codecs et validateurs de production.
- La fixture décrit le contenu; FG-182 exécutera les mécaniques.
- Aucun tileset, rendu ou polish n'est nécessaire à la gate mécanique.
- La fixture historique `golden_battle_slice` reste inchangée pour préserver
  les smokes Phase A.

## Audit initial

- Branche : `main`.
- HEAD initial : `739e0ab7`.
- Worktree initial : propre.
- La fixture historique ne comportait qu'une map et ne couvrait ni New Game,
  shop/heal, progression, field unlock, sauvegarde ni mini-fin.
- Selbrume couvre une campagne plus grande, mais n'est pas une fixture minimale
  de 2–3 maps; la nouvelle fixture isole donc la preuve globale.

## Inventaire des fichiers

| Fichier | Rôle |
|---|---|
| `golden_fangame_slice/project.json` | Manifest, New Game, starters, encounter, trainer, Pokémon config |
| `golden_fangame_slice/maps/golden_town.json` | Départ, guide, shop et heal actors |
| `golden_fangame_slice/maps/golden_route.json` | Zone de rencontre et rival |
| `golden_fangame_slice/maps/golden_summit.json` | Conclusion et badge keeper |
| `golden_fangame_slice/walkthrough.json` | Treize checkpoints ordonnés et leur preuve attendue |
| `golden_fangame_slice/data/pokemon/**` | Trois espèces, trois learnsets, quatre moves minimaux |
| `test/golden_fangame_slice_fixture_test.dart` | Validation disque, codecs, maps, références et walkthrough |
| `reports/gameplay/fg_181_golden_slice_fangame_fixture_v0.md` | Evidence Pack du lot |

## TDD et résultats

RED initial : le dossier `golden_fangame_slice` était absent et le test a
échoué avec `Expected: true / Actual: false`.

Un second RED utile a détecté un `existingPartyFactId` sans définition. La
référence inutile a été retirée au lieu d'ajouter un faux Fact.

Commandes :

```bash
cd examples/playable_runtime_host
flutter test test/golden_fangame_slice_fixture_test.dart
flutter analyze
```

Résultats exacts :

```text
+1: All tests passed!
No issues found! (ran in 3.6s)
```

## Passes obligatoires

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS — fixture séparée, aucun moteur parallèle |
| Implémentation | PASS — trois maps et données minimales |
| Tests | PASS — manifest et chaque map validés par les APIs de production |
| Build / Validation | PASS — test ciblé et analyse host verts |
| Critique | PASS — le walkthrough décrit la preuve, FG-182 doit encore l'exécuter |

## Limites et risques

- Les maps sont mécaniques et sans rendu raster, conformément au DoD.
- Les acteurs shop/heal sont des points d'intention; l'état sera muté par les
  services de production dans le smoke FG-182.
- Les transitions visuelles entre maps ne sont pas un critère de ce lot.
- La roadmap canonique n'est pas modifiée.

## Annexe — contenu complet des fichiers créés

### `examples/playable_runtime_host/golden_fangame_slice/data/pokemon/catalogs/moves.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "moves",
  "meta": {
    "description": "FG-181 Golden Fangame Slice move catalog",
    "notes": [
      "Only moves consumed by the versioned Golden Fangame Slice are included."
    ]
  },
  "entries": [
    {
      "id": "tackle",
      "name": "Tackle",
      "names": {
        "en": "Tackle"
      },
      "generation": 1,
      "source": "phase_a_golden_slice",
      "type": "normal",
      "category": "physical",
      "target": "normal",
      "basePower": 40,
      "accuracy": {
        "kind": "percent",
        "value": 100
      },
      "pp": 35,
      "engineSupportLevel": "structured_supported"
    },
    {
      "id": "growl",
      "name": "Growl",
      "names": {
        "en": "Growl"
      },
      "generation": 1,
      "source": "phase_a_golden_slice",
      "type": "normal",
      "category": "status",
      "target": "allAdjacentFoes",
      "basePower": 0,
      "accuracy": {
        "kind": "percent",
        "value": 100
      },
      "pp": 40,
      "effects": [
        {
          "kind": "modify_stats",
          "targetScope": "target",
          "stageChanges": [
            {
              "stat": "attack",
              "stages": -1
            }
          ]
        }
      ],
      "engineSupportLevel": "structured_supported"
    },
    {
      "id": "vine_whip",
      "name": "Vine Whip",
      "names": {
        "en": "Vine Whip"
      },
      "generation": 1,
      "source": "phase_a_golden_slice",
      "type": "grass",
      "category": "physical",
      "target": "normal",
      "basePower": 45,
      "accuracy": {
        "kind": "percent",
        "value": 100
      },
      "pp": 25,
      "engineSupportLevel": "structured_supported"
    },
    {
      "id": "water_gun",
      "name": "Water Gun",
      "names": {
        "en": "Water Gun"
      },
      "generation": 1,
      "source": "fg_181_golden_fangame_slice",
      "type": "water",
      "category": "special",
      "target": "normal",
      "basePower": 40,
      "accuracy": {
        "kind": "percent",
        "value": 100
      },
      "pp": 25,
      "engineSupportLevel": "structured_supported"
    }
  ]
}
```

### `examples/playable_runtime_host/golden_fangame_slice/data/pokemon/learnsets/aquaphin.json`

```json
{
  "speciesId": "aquaphin",
  "startingMoves": [
    "tackle",
    "water_gun"
  ],
  "relearnMoves": [],
  "levelUp": []
}
```

### `examples/playable_runtime_host/golden_fangame_slice/data/pokemon/learnsets/sparkitten.json`

```json
{
  "speciesId": "sparkitten",
  "startingMoves": [
    "tackle"
  ],
  "relearnMoves": [
    "growl"
  ],
  "levelUp": []
}
```

### `examples/playable_runtime_host/golden_fangame_slice/data/pokemon/learnsets/sproutle.json`

```json
{
  "speciesId": "sproutle",
  "startingMoves": [
    "tackle"
  ],
  "relearnMoves": [
    "growl"
  ],
  "levelUp": [
    {
      "moveId": "vine_whip",
      "level": 5,
      "source": "level_up",
      "versionGroup": "phase_a"
    }
  ]
}
```

### `examples/playable_runtime_host/golden_fangame_slice/data/pokemon/species/001-sproutle.json`

```json
{
  "id": "sproutle",
  "slug": "sproutle",
  "nationalDex": 1,
  "names": {
    "en": "Sproutle"
  },
  "speciesName": {
    "en": "Seedling"
  },
  "genIntroduced": 1,
  "typing": {
    "types": [
      "grass"
    ]
  },
  "baseStats": {
    "hp": 45,
    "atk": 49,
    "def": 49,
    "spa": 65,
    "spd": 65,
    "spe": 45,
    "bst": 318
  },
  "abilities": {
    "primary": "overgrow"
  },
  "breeding": {
    "genderRatio": {
      "male": 0.875,
      "female": 0.125
    },
    "eggGroups": [
      "monster",
      "grass"
    ],
    "hatchCycles": 20
  },
  "progression": {
    "growthRateId": "medium_slow",
    "baseExp": 64,
    "catchRate": 45,
    "baseFriendship": 50
  },
  "refs": {
    "learnset": "sproutle",
    "evolution": "sproutle",
    "media": "sproutle"
  },
  "dexContent": {
    "heightM": 0.7,
    "weightKg": 6.9
  },
  "classification": {
    "isEnabledInProject": true
  },
  "gameplayFlags": {
    "starterEligible": true
  },
  "sourceMeta": {
    "seededBy": "phase_a_golden_slice",
    "seedVersion": 1
  }
}
```

### `examples/playable_runtime_host/golden_fangame_slice/data/pokemon/species/004-sparkitten.json`

```json
{
  "id": "sparkitten",
  "slug": "sparkitten",
  "nationalDex": 4,
  "names": {
    "en": "Sparkitten"
  },
  "speciesName": {
    "en": "Ember Cat"
  },
  "genIntroduced": 1,
  "typing": {
    "types": [
      "fire"
    ]
  },
  "baseStats": {
    "hp": 35,
    "atk": 52,
    "def": 43,
    "spa": 60,
    "spd": 50,
    "spe": 65,
    "bst": 305
  },
  "abilities": {
    "primary": "blaze"
  },
  "breeding": {
    "genderRatio": {
      "male": 0.875,
      "female": 0.125
    },
    "eggGroups": [
      "field"
    ],
    "hatchCycles": 20
  },
  "progression": {
    "growthRateId": "medium_slow",
    "baseExp": 62,
    "catchRate": 45,
    "baseFriendship": 50
  },
  "refs": {
    "learnset": "sparkitten",
    "evolution": "sparkitten",
    "media": "sparkitten"
  },
  "dexContent": {
    "heightM": 0.6,
    "weightKg": 8.5
  },
  "classification": {
    "isEnabledInProject": true
  },
  "sourceMeta": {
    "seededBy": "phase_a_golden_slice",
    "seedVersion": 1
  }
}
```

### `examples/playable_runtime_host/golden_fangame_slice/data/pokemon/species/007-aquaphin.json`

```json
{
  "id": "aquaphin",
  "slug": "aquaphin",
  "nationalDex": 7,
  "names": {
    "en": "Aquaphin"
  },
  "speciesName": {
    "en": "Wave Calf"
  },
  "genIntroduced": 1,
  "typing": {
    "types": [
      "water"
    ]
  },
  "baseStats": {
    "hp": 44,
    "atk": 48,
    "def": 65,
    "spa": 50,
    "spd": 64,
    "spe": 43,
    "bst": 314
  },
  "abilities": {
    "primary": "torrent"
  },
  "breeding": {
    "genderRatio": {
      "male": 0.875,
      "female": 0.125
    },
    "eggGroups": [
      "monster",
      "water_1"
    ],
    "hatchCycles": 20
  },
  "progression": {
    "growthRateId": "medium_slow",
    "baseExp": 63,
    "catchRate": 45,
    "baseFriendship": 50
  },
  "refs": {
    "learnset": "aquaphin",
    "evolution": "aquaphin",
    "media": "aquaphin"
  },
  "dexContent": {
    "heightM": 0.5,
    "weightKg": 9
  },
  "classification": {
    "isEnabledInProject": true
  },
  "gameplayFlags": {
    "starterEligible": true
  },
  "sourceMeta": {
    "seededBy": "fg_181_golden_fangame_slice",
    "seedVersion": 1
  }
}
```

### `examples/playable_runtime_host/golden_fangame_slice/maps/golden_route.json`

```json
{
  "id": "golden_route",
  "name": "Golden Route",
  "size": {
    "width": 6,
    "height": 5
  },
  "version": "v1",
  "entities": [
    {
      "id": "spawn_route",
      "name": "spawn_route",
      "kind": "spawn",
      "pos": {
        "x": 0,
        "y": 2
      },
      "blocksMovement": false,
      "spawn": {
        "role": "player_start",
        "facing": "east"
      }
    },
    {
      "id": "npc_golden_rival",
      "name": "Mira",
      "kind": "npc",
      "pos": {
        "x": 4,
        "y": 2
      },
      "npc": {
        "displayName": "Mira",
        "facing": "west",
        "trainerId": "trainer_golden_rival"
      }
    }
  ],
  "gameplayZones": [
    {
      "id": "golden_grass_zone",
      "name": "Golden Grass",
      "kind": "encounter",
      "area": {
        "pos": {
          "x": 2,
          "y": 1
        },
        "size": {
          "width": 2,
          "height": 2
        }
      },
      "encounter": {
        "encounterTableId": "golden_grass",
        "encounterKind": "walk"
      }
    }
  ],
  "mapMetadata": {
    "defaultSpawnId": "spawn_route"
  }
}
```

### `examples/playable_runtime_host/golden_fangame_slice/maps/golden_summit.json`

```json
{
  "id": "golden_summit",
  "name": "Golden Summit",
  "size": {
    "width": 6,
    "height": 5
  },
  "version": "v1",
  "entities": [
    {
      "id": "spawn_summit",
      "name": "spawn_summit",
      "kind": "spawn",
      "pos": {
        "x": 1,
        "y": 2
      },
      "blocksMovement": false,
      "spawn": {
        "role": "player_start",
        "facing": "east"
      }
    },
    {
      "id": "npc_badge_keeper",
      "name": "Badge Keeper",
      "kind": "npc",
      "pos": {
        "x": 3,
        "y": 2
      },
      "npc": {
        "displayName": "Badge Keeper",
        "facing": "south"
      }
    }
  ],
  "mapMetadata": {
    "defaultSpawnId": "spawn_summit"
  }
}
```

### `examples/playable_runtime_host/golden_fangame_slice/maps/golden_town.json`

```json
{
  "id": "golden_town",
  "name": "Golden Town",
  "size": {
    "width": 6,
    "height": 5
  },
  "version": "v1",
  "entities": [
    {
      "id": "spawn_town",
      "name": "spawn_town",
      "kind": "spawn",
      "pos": {
        "x": 1,
        "y": 2
      },
      "blocksMovement": false,
      "spawn": {
        "role": "player_start",
        "facing": "east"
      }
    },
    {
      "id": "npc_starter_guide",
      "name": "Starter Guide",
      "kind": "npc",
      "pos": {
        "x": 2,
        "y": 2
      },
      "npc": {
        "displayName": "Starter Guide",
        "facing": "south"
      }
    },
    {
      "id": "npc_shopkeeper",
      "name": "Shopkeeper",
      "kind": "npc",
      "pos": {
        "x": 3,
        "y": 2
      },
      "npc": {
        "displayName": "Shopkeeper",
        "facing": "south"
      }
    },
    {
      "id": "npc_healer",
      "name": "Healer",
      "kind": "npc",
      "pos": {
        "x": 4,
        "y": 2
      },
      "npc": {
        "displayName": "Healer",
        "facing": "south"
      }
    }
  ],
  "mapMetadata": {
    "defaultSpawnId": "spawn_town"
  }
}
```

### `examples/playable_runtime_host/golden_fangame_slice/project.json`

```json
{
  "name": "Golden Fangame Slice",
  "version": "v1",
  "maps": [
    {
      "id": "golden_town",
      "name": "Golden Town",
      "relativePath": "maps/golden_town.json",
      "role": "interior",
      "sortOrder": 0
    },
    {
      "id": "golden_route",
      "name": "Golden Route",
      "relativePath": "maps/golden_route.json",
      "role": "exterior",
      "sortOrder": 1
    },
    {
      "id": "golden_summit",
      "name": "Golden Summit",
      "relativePath": "maps/golden_summit.json",
      "role": "interior",
      "sortOrder": 2
    }
  ],
  "tilesets": [],
  "encounterTables": [
    {
      "id": "golden_grass",
      "name": "Golden Grass",
      "encounterKind": "walk",
      "entries": [
        {
          "speciesId": "sparkitten",
          "minLevel": 4,
          "maxLevel": 4,
          "weight": 1
        }
      ]
    }
  ],
  "trainers": [
    {
      "id": "trainer_golden_rival",
      "name": "Mira",
      "trainerClass": "Rival",
      "battleDifficulty": 4,
      "team": [
        {
          "speciesId": "sparkitten",
          "level": 5,
          "moves": [
            "tackle",
            "growl"
          ]
        }
      ]
    }
  ],
  "pokemon": {
    "enabled": true,
    "dataRoot": "data/pokemon",
    "speciesDir": "data/pokemon/species",
    "learnsetsDir": "data/pokemon/learnsets",
    "evolutionsDir": "data/pokemon/evolutions",
    "mediaDir": "data/pokemon/media",
    "catalogFiles": {
      "moves": "data/pokemon/catalogs/moves.json"
    }
  },
  "newGame": {
    "enabled": true,
    "startMapId": "golden_town",
    "startSpawnId": "spawn_town",
    "playerName": "Golden Player",
    "startingMoney": 1000,
    "initialBag": [
      {
        "itemId": "poke-ball",
        "categoryId": "capture",
        "quantity": 5
      },
      {
        "itemId": "potion",
        "categoryId": "medicine",
        "quantity": 1
      }
    ],
    "initialParty": [],
    "initialFacts": {},
    "starterOptions": [
      {
        "id": "starter_sproutle",
        "label": "Sproutle",
        "pokemon": {
          "speciesId": "sproutle",
          "natureId": "bold",
          "abilityId": "overgrow",
          "level": 5,
          "knownMoveIds": [
            "tackle",
            "growl"
          ],
          "currentHp": 20
        }
      },
      {
        "id": "starter_sparkitten",
        "label": "Sparkitten",
        "pokemon": {
          "speciesId": "sparkitten",
          "natureId": "brave",
          "abilityId": "blaze",
          "level": 5,
          "knownMoveIds": [
            "tackle",
            "growl"
          ],
          "currentHp": 19
        }
      },
      {
        "id": "starter_aquaphin",
        "label": "Aquaphin",
        "pokemon": {
          "speciesId": "aquaphin",
          "natureId": "calm",
          "abilityId": "torrent",
          "level": 5,
          "knownMoveIds": [
            "tackle",
            "water_gun"
          ],
          "currentHp": 21
        }
      }
    ]
  },
  "settings": {
    "tileWidth": 16,
    "tileHeight": 16,
    "displayScale": 2,
    "defaultMapWidth": 6,
    "defaultMapHeight": 5
  }
}
```

### `examples/playable_runtime_host/golden_fangame_slice/walkthrough.json`

```json
{
  "schemaVersion": 1,
  "projectId": "golden_fangame_slice",
  "steps": [
    {
      "id": "new_game",
      "label": "Lancer une nouvelle partie",
      "proof": "GameState créé depuis ProjectNewGameConfig."
    },
    {
      "id": "starter_chosen",
      "label": "Choisir un starter",
      "proof": "Le starter authoré rejoint la party."
    },
    {
      "id": "wild_encounter",
      "label": "Déclencher une rencontre",
      "proof": "La zone golden_grass résout sparkitten."
    },
    {
      "id": "wild_battle_completed",
      "label": "Terminer le combat sauvage",
      "proof": "Une session de combat réelle atteint un résultat."
    },
    {
      "id": "capture_completed",
      "label": "Capturer le Pokémon",
      "proof": "La capture écrit dans la party ou le storage."
    },
    {
      "id": "trainer_defeated",
      "label": "Battre Mira",
      "proof": "Le combat trainer produit une victoire."
    },
    {
      "id": "level_up_proved",
      "label": "Prouver la progression",
      "proof": "La récompense augmente niveau et argent."
    },
    {
      "id": "shop_used",
      "label": "Acheter une potion",
      "proof": "La transaction retire l'argent et ajoute l'objet."
    },
    {
      "id": "heal_center_used",
      "label": "Soigner l'équipe",
      "proof": "Le recovery point restaure les HP et statuts."
    },
    {
      "id": "badge_flag_acquired",
      "label": "Obtenir le badge/flag",
      "proof": "Le flag golden.badge.tide est actif."
    },
    {
      "id": "surf_unlocked",
      "label": "Débloquer Surf",
      "proof": "FieldAbility.surf est persistée."
    },
    {
      "id": "save_reloaded",
      "label": "Sauvegarder et recharger",
      "proof": "Le JSON de sauvegarde restitue l'état complet."
    },
    {
      "id": "story_end_reached",
      "label": "Atteindre la mini-fin",
      "proof": "Le flag golden.story.completed est actif."
    }
  ]
}
```

### `examples/playable_runtime_host/test/golden_fangame_slice_fixture_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FG-181 fixture is a valid minimal three-map fangame', () async {
    final root = p.join(Directory.current.path, 'golden_fangame_slice');
    final projectPath = p.join(root, 'project.json');

    expect(await File(projectPath).exists(), isTrue);
    final projectJson = jsonDecode(await File(projectPath).readAsString())
        as Map<String, dynamic>;
    final project = ProjectManifest.fromJson(projectJson);
    ProjectValidator.validate(project);

    expect(project.version, ProjectVersion.v1);
    expect(project.maps, hasLength(3));
    expect(project.tilesets, isEmpty);
    expect(project.newGame.enabled, isTrue);
    expect(project.newGame.initialParty, isEmpty);
    expect(project.newGame.starterOptions, hasLength(3));
    expect(project.encounterTables, hasLength(1));
    expect(project.trainers, hasLength(1));

    final loadedMaps = <String, MapData>{};
    for (final entry in project.maps) {
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectPath,
        mapId: entry.id,
      );
      MapValidator.validate(
        bundle.map,
        projectDialogueContext: project,
      );
      loadedMaps[entry.id] = bundle.map;
      expect(bundle.tilesetAbsolutePathsById, isEmpty);
    }

    expect(loadedMaps.keys, <String>{
      'golden_town',
      'golden_route',
      'golden_summit',
    });
    expect(
      loadedMaps['golden_route']!
          .gameplayZones
          .where((zone) => zone.kind == GameplayZoneKind.encounter),
      hasLength(1),
    );
    expect(
      loadedMaps['golden_route']!.entities.where(
            (entity) => entity.npc?.trainerId == 'trainer_golden_rival',
          ),
      hasLength(1),
    );

    final walkthroughFile = File(p.join(root, 'walkthrough.json'));
    final walkthrough = jsonDecode(await walkthroughFile.readAsString())
        as Map<String, dynamic>;
    expect(walkthrough['schemaVersion'], 1);
    expect(walkthrough['projectId'], 'golden_fangame_slice');
    final steps =
        (walkthrough['steps'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(
      steps.map((step) => step['id']),
      orderedEquals(const <String>[
        'new_game',
        'starter_chosen',
        'wild_encounter',
        'wild_battle_completed',
        'capture_completed',
        'trainer_defeated',
        'level_up_proved',
        'shop_used',
        'heal_center_used',
        'badge_flag_acquired',
        'surf_unlocked',
        'save_reloaded',
        'story_end_reached',
      ]),
    );
    for (final step in steps) {
      expect((step['label'] as String).trim(), isNotEmpty);
      expect((step['proof'] as String).trim(), isNotEmpty);
    }

    final rasterAssets = await Directory(root)
        .list(recursive: true)
        .where((entry) => entry is File)
        .map((entry) => p.extension(entry.path).toLowerCase())
        .where((extension) =>
            const {'.png', '.jpg', '.jpeg', '.webp'}.contains(extension))
        .toList();
    expect(rasterAssets, isEmpty);
  });
}
```

