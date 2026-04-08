# Lot 6 — Façade applicative Pokédex en lecture seule

## 1. Résumé exécutif

Ce lot ajoute la première façade applicative Pokédex côté `map_editor`, en lecture seule, sans UI et sans dépendance à `project.json`.

Ce qui a été fait :

- création d’un modèle applicatif `PokedexListEntry` ;
- création d’un use case `ListPokedexEntriesUseCase` ;
- ajout d’un test dédié couvrant la liste Pokédex, le découplage filesystem, le garde-fou workspace, l’invariance de `project.json`, le mapping de `isStarterEligible` et l’échec explicite sur données invalides ;
- export du use case dans `use_cases.dart`.

Ce qui n’a pas été fait :

- aucune UI ;
- aucun provider Riverpod ;
- aucun runtime ;
- aucune modification de `project.json` ;
- aucun import externe ;
- aucune modification du seed ;
- aucune nouvelle logique Pokémon plus large que la liste Pokédex en lecture seule.

## 2. Objectif exact du lot

Le but de ce lot est de ne plus manipuler directement `PokemonProjectDataReader` dans les futurs appels applicatifs orientés Pokédex.

On introduit donc :

- un modèle de sortie métier/UI-friendly ;
- un use case applicatif simple ;
- une lecture du workspace projet utilisateur qui reste complètement séparée des détails de stockage local.

## 3. Rappel du périmètre strict

Le lot reste volontairement petit :

- uniquement côté `map_editor` ;
- aucune UI ;
- aucun provider ;
- aucun runtime ;
- aucune dépendance à `project.json` ;
- aucun changement du contrat JSON existant ;
- aucune logique de combat, de sac, d’équipe ou de dresseur.

## 4. Modèle applicatif créé

Fichier créé :

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokedex_list_entry.dart`

Modèle :

- `PokedexListEntry`

Champs exposés :

- `id`
- `nationalDex`
- `primaryName`
- `types`
- `isStarterEligible`
- `genIntroduced` (optionnel, gardé parce qu’il est déjà disponible proprement via le JSON espèce)

### Pourquoi ce modèle existe

Le lecteur local Pokémon retourne aujourd’hui :

- une projection légère technique (`PokemonSpeciesIndexEntry`) ;
- des modèles de détail liés aux JSON espèces.

La future UI n’a pas besoin de connaître :

- `relativePath`
- l’organisation du dossier `species/`
- le nom du fichier JSON

`PokedexListEntry` sert donc de frontière applicative propre entre :

- la lecture locale du workspace ;
- une future couche UI Pokédex.

## 5. Use case créé

Fichier créé :

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart`

Use case :

- `ListPokedexEntriesUseCase`

Signature :

```dart
class ListPokedexEntriesUseCase {
  Future<List<PokedexListEntry>> execute(ProjectWorkspace workspace);
}
```

### Comportement

Le use case :

1. lit la projection légère des espèces via `PokemonProjectDataReader.listSpeciesIndexEntries(...)` ;
2. relit chaque espèce détaillée via `readSpeciesById(...)` pour récupérer les champs purement métier qui n’appartiennent pas à la projection locale légère ;
3. construit des `PokedexListEntry` ;
4. trie le résultat par :
   1. `nationalDex`
   2. `id`

## 6. Mapping depuis la lecture locale vers le modèle applicatif

Mapping retenu :

- `id` ← `speciesIndexEntry.id`
- `nationalDex` ← `speciesIndexEntry.nationalDex`
- `primaryName` ← `speciesIndexEntry.primaryName`
- `types` ← `speciesIndexEntry.types`
- `isStarterEligible` ← `species.gameplayFlags.starterEligible`
- `genIntroduced` ← `species.genIntroduced`

Cette stratégie garde une responsabilité claire :

- la projection légère porte l’identité et les champs de liste naturels ;
- la lecture détail complète fournit les flags gameplay métier.

## 7. Pourquoi `relativePath` n’est pas exposé

`relativePath` reste un détail technique de stockage local.

Le modèle applicatif `PokedexListEntry` ne l’expose pas volontairement, parce que :

- la future UI n’a pas besoin de connaître le filesystem ;
- cela évite de faire fuiter la structure `data/pokemon/species/...` ;
- cela garde une frontière claire entre :
  - lecture locale technique ;
  - modèle applicatif Pokédex.

## 8. Fichiers créés / modifiés

Fichiers créés :

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokedex_list_entry.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/list_pokedex_entries_use_case_test.dart`
- `/Users/karim/Project/pokemonProject/reports/pokedex-list-use-case-lot-6-report.md`

Fichier modifié :

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/use_cases.dart`

## 9. Tests réellement exécutés

Commande exécutée :

```bash
flutter test test/list_pokedex_entries_use_case_test.dart
```

Résultat réel :

- succès ;
- 6 tests passés ;
- aucune erreur.

Cas couverts :

1. retourne une liste Pokédex triée depuis le workspace projet ;
2. n’expose pas les détails filesystem dans le modèle applicatif ;
3. utilise bien les données du workspace, pas la racine du monorepo ;
4. laisse `project.json` strictement inchangé ;
5. remonte correctement `isStarterEligible` depuis les espèces ;
6. échoue explicitement si une espèce est invalide.

## 10. Résultat de l’analyse

Commande exécutée :

```bash
flutter analyze --no-pub \
  lib/src/application/models/pokedex_list_entry.dart \
  lib/src/application/use_cases/list_pokedex_entries_use_case.dart \
  lib/src/application/use_cases/use_cases.dart \
  test/list_pokedex_entries_use_case_test.dart
```

Résultat réel :

```text
No issues found! (ran in 1.3s)
```

## 11. Preuve que `project.json` est inchangé

Le test `leaves project.json strictly unchanged` :

- crée un vrai projet via le flux existant ;
- seed le mini dataset Pokémon ;
- lit `project.json` avant exécution ;
- exécute le use case ;
- relit `project.json` ;
- compare avant/après byte-for-byte.

Le test passe.

## 12. Preuve que rien n’est recréé à la racine du monorepo

Commande exécutée :

```bash
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
```

Résultat réel :

- aucune sortie.

Conclusion :

- aucun `./data` à la racine ;
- aucun `./assets` à la racine.

## 13. Sorties Git utiles

### `git status --short`

Sortie observée avant écriture du présent rapport :

```text
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
?? packages/map_editor/lib/src/application/models/pokedex_list_entry.dart
?? packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart
?? packages/map_editor/test/list_pokedex_entries_use_case_test.dart
```

### État ciblé du lot

Sortie observée avant écriture du présent rapport :

```text
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
?? packages/map_editor/lib/src/application/models/pokedex_list_entry.dart
?? packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart
?? packages/map_editor/test/list_pokedex_entries_use_case_test.dart
```

### `git diff --stat`

Commande exécutée :

```bash
git diff --stat -- \
  packages/map_editor/lib/src/application/models/pokedex_list_entry.dart \
  packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart \
  packages/map_editor/lib/src/application/use_cases/use_cases.dart \
  packages/map_editor/test/list_pokedex_entries_use_case_test.dart \
  reports/pokedex-list-use-case-lot-6-report.md
```

Sortie réelle :

```text
 packages/map_editor/lib/src/application/use_cases/use_cases.dart | 1 +
 1 file changed, 1 insertion(+)
```

Note honnête :

- `git diff --stat` ne montre ici que le fichier déjà suivi `use_cases.dart` ;
- les nouveaux fichiers non suivis n’apparaissent pas dans ce diff standard.

## 14. `./review_bundle.sh`

Commande exécutée :

```bash
./review_bundle.sh
```

Chemin du fichier généré :

- `.review/review-20260408-225848.txt`

Contenu intégral :

```text
# REVIEW BUNDLE

Generated at: 2026-04-08 22:58:48
Repository: pokemonProject
Branch: main
Base ref: HEAD
Head commit: c700532596d459d51d1dcbc4ba2c6d2463dbbc26

## GIT STATUS --SHORT

 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
?? packages/map_editor/lib/src/application/models/pokedex_list_entry.dart
?? packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart
?? packages/map_editor/test/list_pokedex_entries_use_case_test.dart

## GIT DIFF --STAT

 packages/map_editor/lib/src/application/use_cases/use_cases.dart | 1 +
 1 file changed, 1 insertion(+)

## CHANGED FILES

packages/map_editor/lib/src/application/use_cases/use_cases.dart

## RECENT COMMITS

c700532 LOT 5: Add Pokémon data models and reader service for structured JSON operations
f808d3f Seed Pokémon demo data use case with idempotent JSON generation
c4d2983 Enrich Pokémon JSON storage contract with manifest and minimal catalog structures
e266743 Add use case to initialize Pokémon project storage structure
c41fe7e Add data and assets folder structure with .gitkeep placeholders for future Pokémon content
3d81349 Add tests to confirm grid-based collision granularity limitations and document runtime constraints
8675f74 Add migration for broken legacy manual collision profiles
59dce2a Audit runtime collision logic to validate `cells` as the active source of truth
2aa52f4 Fix collision base model to support authored shapes and resolve padding-based overcapture issues
fc7cf31 Enhance polygon rasterization logic and add backend cell preview to collision editor
fe5da3e Add tests for project collision profile persistence and enhance UI behavior in element collision editor
5d65444 Add element collision editor UI and rasterization services
e63e6cf Add element collision authoring services and padding-based workflow
5f714b5 Persist last opened project state and add auto-restore support
7a137dd Remove LOT 50 demo scenario and inject logic; add FPS overlay support

## FULL DIFF

diff --git a/packages/map_editor/lib/src/application/use_cases/use_cases.dart b/packages/map_editor/lib/src/application/use_cases/use_cases.dart
index 6a4b084..6cf9874 100644
--- a/packages/map_editor/lib/src/application/use_cases/use_cases.dart
+++ b/packages/map_editor/lib/src/application/use_cases/use_cases.dart
@@ -5,6 +5,7 @@ export 'trainer_use_cases.dart';
 export 'gameplay_zone_use_cases.dart';
 export 'initialize_pokemon_project_storage_use_case.dart';
 export 'layer_use_cases.dart';
+export 'list_pokedex_entries_use_case.dart';
 export 'map_use_cases.dart';
 export 'paint_use_cases.dart';
 export 'path_layer_use_cases.dart';
```

Note honnête :

- le bundle est partiel pour les nouveaux fichiers non suivis ;
- c’est normal : Git montre surtout le fichier déjà suivi `use_cases.dart` dans le diff standard ;
- le bundle a été généré avant l’écriture du présent rapport.

## 15. Code intégral réalisé

### 15.1 `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokedex_list_entry.dart`

```dart
/// Projection applicative minimale d'une ligne de liste Pokédex.
///
/// Cette classe reste volontairement découplée du stockage local :
/// - aucun chemin de fichier
/// - aucun détail de workspace
/// - uniquement les champs utiles à une future UI de liste
class PokedexListEntry {
  const PokedexListEntry({
    required this.id,
    required this.nationalDex,
    required this.primaryName,
    required this.types,
    required this.isStarterEligible,
    this.genIntroduced,
  });

  final String id;
  final int nationalDex;
  final String primaryName;
  final List<String> types;
  final bool isStarterEligible;
  final int? genIntroduced;
}
```

### 15.2 `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart`

```dart
import '../models/pokedex_list_entry.dart';
import '../ports/project_workspace.dart';
import '../services/pokemon_project_data_reader.dart';

/// Première façade applicative Pokédex orientée liste, en lecture seule.
///
/// Le use case masque les détails de stockage local et retourne uniquement
/// un modèle applicatif exploitable par une future UI.
class ListPokedexEntriesUseCase {
  const ListPokedexEntriesUseCase({
    this.reader = const PokemonProjectDataReader(),
  });

  final PokemonProjectDataReader reader;

  Future<List<PokedexListEntry>> execute(ProjectWorkspace workspace) async {
    final speciesIndexEntries = await reader.listSpeciesIndexEntries(workspace);
    final pokedexEntries = <PokedexListEntry>[];

    for (final speciesIndexEntry in speciesIndexEntries) {
      // La liste légère donne l'identité et l'ordre. On relit ensuite l'espèce
      // détaillée pour les champs purement métier qui n'appartiennent pas à la
      // projection technique locale.
      final species = await reader.readSpeciesById(workspace, speciesIndexEntry.id);
      pokedexEntries.add(
        PokedexListEntry(
          id: speciesIndexEntry.id,
          nationalDex: speciesIndexEntry.nationalDex,
          primaryName: speciesIndexEntry.primaryName,
          types: speciesIndexEntry.types,
          isStarterEligible: species.gameplayFlags.starterEligible,
          genIntroduced: species.genIntroduced,
        ),
      );
    }

    pokedexEntries.sort((left, right) {
      final dexCompare = left.nationalDex.compareTo(right.nationalDex);
      if (dexCompare != 0) return dexCompare;
      return left.id.compareTo(right.id);
    });

    return pokedexEntries;
  }
}
```

### 15.3 `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/use_cases.dart`

```dart
export 'character_use_cases.dart';
export 'collision_use_cases.dart';
export 'encounter_table_use_cases.dart';
export 'trainer_use_cases.dart';
export 'gameplay_zone_use_cases.dart';
export 'initialize_pokemon_project_storage_use_case.dart';
export 'layer_use_cases.dart';
export 'list_pokedex_entries_use_case.dart';
export 'map_use_cases.dart';
export 'paint_use_cases.dart';
export 'path_layer_use_cases.dart';
export 'project_element_use_cases.dart';
export 'project_group_use_cases.dart';
export 'project_management_use_cases.dart';
export 'project_scenario_use_cases.dart';
export 'project_tileset_use_cases.dart';
export 'seed_pokemon_demo_data_use_case.dart';
export 'terrain_preset_use_cases.dart';
export 'terrain_use_cases.dart';
export 'warp_use_cases.dart';
```

### 15.4 `/Users/karim/Project/pokemonProject/packages/map_editor/test/list_pokedex_entries_use_case_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokedex_list_entry.dart';
import 'package:map_editor/src/application/use_cases/list_pokedex_entries_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late SeedPokemonDemoDataUseCase seedUseCase;
  late ListPokedexEntriesUseCase useCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokedex_list_');
    workspace = ProjectFileSystem(tempProjectRoot.path);
    seedUseCase = const SeedPokemonDemoDataUseCase();
    useCase = const ListPokedexEntriesUseCase();
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('ListPokedexEntriesUseCase', () {
    test('returns a sorted pokedex list from the project workspace', () async {
      await seedUseCase.execute(workspace);

      final entries = await useCase.execute(workspace);

      expect(entries, hasLength(2));
      expect(entries.map((entry) => entry.id).toList(), <String>[
        'bulbasaur',
        'ivysaur',
      ]);

      final bulbasaur = entries.first;
      expect(bulbasaur.nationalDex, 1);
      expect(bulbasaur.primaryName, 'Bulbasaur');
      expect(bulbasaur.types, <String>['grass', 'poison']);
      expect(bulbasaur.isStarterEligible, isTrue);
    });

    test('does not expose filesystem concerns in the application model',
        () async {
      await seedUseCase.execute(workspace);

      final entries = await useCase.execute(workspace);
      final PokedexListEntry entry = entries.first;
      final dynamic dynamicEntry = entry;

      expect(() => dynamicEntry.relativePath, throwsA(isA<NoSuchMethodError>()));
    });

    test('uses the workspace project data and not the monorepo root', () async {
      await seedUseCase.execute(workspace);

      final decoy = await Directory.systemTemp.createTemp('pokedex_decoy_');
      final originalCurrent = Directory.current;
      try {
        await Directory(
          p.join(decoy.path, 'data', 'pokemon', 'species'),
        ).create(recursive: true);
        await File(
          p.join(decoy.path, 'data', 'pokemon', 'species', '0003-venusaur.json'),
        ).writeAsString('''
{
  "id": "venusaur",
  "nationalDex": 3,
  "names": {"en": "Venusaur"},
  "typing": {"types": ["grass", "poison"]}
}
''');

        Directory.current = decoy.path;

        final entries = await useCase.execute(workspace);

        expect(entries.map((entry) => entry.id), isNot(contains('venusaur')));
        expect(entries.map((entry) => entry.id), containsAll(<String>[
          'bulbasaur',
          'ivysaur',
        ]));
      } finally {
        Directory.current = originalCurrent.path;
        if (await decoy.exists()) {
          await decoy.delete(recursive: true);
        }
      }
    });

    test('leaves project.json strictly unchanged', () async {
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );
      await createProjectUseCase.execute('Pokedex List Project', tempProjectRoot.path);
      await seedUseCase.execute(workspace);

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await useCase.execute(workspace);

      final after = await projectFile.readAsString();
      expect(after, before);
    });

    test('returns starter eligibility from species gameplay flags', () async {
      await seedUseCase.execute(workspace);

      final entries = await useCase.execute(workspace);

      final bulbasaur = entries.firstWhere((entry) => entry.id == 'bulbasaur');
      final ivysaur = entries.firstWhere((entry) => entry.id == 'ivysaur');

      expect(bulbasaur.isStarterEligible, isTrue);
      expect(ivysaur.isStarterEligible, isFalse);
    });

    test('fails explicitly when species data is invalid', () async {
      await seedUseCase.execute(workspace);

      final speciesFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0002-ivysaur.json',
        ),
      );
      await speciesFile.writeAsString('{ invalid json');

      expect(
        () => useCase.execute(workspace),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
    });
  });
}
```

## 16. Mini conclusion

Ce lot ajoute enfin une première capacité Pokédex exploitable côté application :

- une liste métier ;
- en lecture seule ;
- découplée du filesystem ;
- prête pour une future UI sans exposer les détails de stockage local.

La base reste volontairement simple :

- pas de provider ;
- pas d’UI ;
- pas de runtime ;
- pas de cache ;
- pas de sur-ingénierie.

On a donc maintenant une première API Pokédex propre, stable et strictement bornée au périmètre demandé.
