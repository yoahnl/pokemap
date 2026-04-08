# Rapport — Mini-fix lot 7 — test portable sans chemin absolu hardcodé

## 1. Problème exact

Le test suivant contenait encore un check non portable :

- `/Users/karim/Project/pokemonProject/data`
- `/Users/karim/Project/pokemonProject/assets`

Fichier concerné :
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_read_repository_test.dart`

Pourquoi c’était mauvais :
- dépendance à un chemin propre à une machine ;
- test faux ou inutile sur une autre machine ;
- vérification de bon comportement couplée à un environnement local particulier.

## 2. Correction appliquée

Le test n’utilise plus de chemin absolu hardcodé.

À la place :
- il résout la racine du repo à partir de `Directory.current` ;
- il remonte dans l’arborescence jusqu’à trouver un marqueur de repo cohérent :
  - `AGENTS.md`
  - `packages/map_editor`
- il vérifie ensuite l’absence de `data/` et `assets/` à cette racine résolue.

Cela garde l’intention du test :
- prouver que la lecture Pokémon via le repository ne recrée pas `data/` ou `assets/` à la racine du monorepo ;
- sans dépendre d’un chemin machine spécifique.

## 3. Pourquoi la nouvelle version est portable

La nouvelle version ne dépend plus :
- du nom d’utilisateur ;
- du chemin absolu du clone ;
- d’une machine particulière.

Elle dépend seulement :
- de l’emplacement courant du repo au moment de l’exécution ;
- d’une détection locale de la racine du dépôt.

Le test reste simple :
- il n’introduit pas de nouvelle architecture ;
- il ne change pas le comportement métier ;
- il ne modifie ni le repository, ni `project.json`, ni les données seed.

## 4. Fichier modifié

Fichier de code modifié :
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_read_repository_test.dart`

Fichier de rapport ajouté :
- `/Users/karim/Project/pokemonProject/reports/pokemon-read-repositories-lot-7-mini-fix-report.md`

## 5. Commandes réellement exécutées

```bash
flutter test test/file_pokemon_read_repository_test.dart
flutter test test/list_pokedex_entries_use_case_test.dart
flutter analyze --no-pub lib/src/infrastructure/repositories/file_repositories.dart test/file_pokemon_read_repository_test.dart
git status --short
git diff --stat -- packages/map_editor/test/file_pokemon_read_repository_test.dart reports/pokemon-read-repositories-lot-7-mini-fix-report.md
git ls-files --others --exclude-standard packages/map_editor/test/file_pokemon_read_repository_test.dart reports/pokemon-read-repositories-lot-7-mini-fix-report.md
./review_bundle.sh
cat .review/review-20260408-233131.txt
cat packages/map_editor/test/file_pokemon_read_repository_test.dart
```

## 6. Résultats des validations

### Tests

```text
flutter test test/file_pokemon_read_repository_test.dart
=> All tests passed!
```

```text
flutter test test/list_pokedex_entries_use_case_test.dart
=> All tests passed!
```

### Analyse

```text
flutter analyze --no-pub lib/src/infrastructure/repositories/file_repositories.dart test/file_pokemon_read_repository_test.dart
=> No issues found! (ran in 1.1s)
```

## 7. Git status --short

Commande :

```bash
git status --short
```

Sortie au moment du mini-fix, avant création de ce rapport :

```text
 M packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
 M packages/map_editor/test/list_pokedex_entries_use_case_test.dart
?? packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
?? packages/map_editor/test/file_pokemon_read_repository_test.dart
?? reports/pokemon-read-repositories-lot-7-report.md
```

Note honnête :
- le working tree contient déjà les changements du lot 7 précédent ;
- ce mini-fix s’ajoute par-dessus ;
- le fichier de test modifié ici est déjà non suivi, donc Git ne montre pas ce mini-changement comme une modification suivie.

## 8. Git diff --stat utile

Commande :

```bash
git diff --stat -- packages/map_editor/test/file_pokemon_read_repository_test.dart reports/pokemon-read-repositories-lot-7-mini-fix-report.md
```

Sortie :

```text
[sortie vide]
```

Explication honnête :
- `packages/map_editor/test/file_pokemon_read_repository_test.dart` est un fichier non suivi ;
- `reports/pokemon-read-repositories-lot-7-mini-fix-report.md` n’existait pas encore au moment de cette commande ;
- `git diff --stat` n’affiche pas les fichiers non suivis ;
- il faut donc compléter la lecture avec `git status --short` et `git ls-files --others --exclude-standard`.

### Fichiers non suivis ciblés

Commande :

```bash
git ls-files --others --exclude-standard packages/map_editor/test/file_pokemon_read_repository_test.dart reports/pokemon-read-repositories-lot-7-mini-fix-report.md
```

Sortie avant création de ce rapport :

```text
packages/map_editor/test/file_pokemon_read_repository_test.dart
```

## 9. Bundle de review

Commande :

```bash
./review_bundle.sh
```

Chemin du fichier généré :

```text
.review/review-20260408-233131.txt
```

Contenu intégral :

```text
# REVIEW BUNDLE

Generated at: 2026-04-08 23:31:31
Repository: pokemonProject
Branch: main
Base ref: HEAD
Head commit: b4e651b8fc411afdeae583da66c2300243d4ff2c

## GIT STATUS --SHORT

 M packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
 M packages/map_editor/test/list_pokedex_entries_use_case_test.dart
?? packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
?? packages/map_editor/test/file_pokemon_read_repository_test.dart
?? reports/pokemon-read-repositories-lot-7-report.md

## GIT DIFF --STAT

 .../use_cases/list_pokedex_entries_use_case.dart   |  18 +-
 .../repositories/file_repositories.dart            |  60 +++++
 .../test/list_pokedex_entries_use_case_test.dart   | 296 ++++++++++++++++++---
 3 files changed, 331 insertions(+), 43 deletions(-)

## CHANGED FILES

packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart
packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
packages/map_editor/test/list_pokedex_entries_use_case_test.dart

## RECENT COMMITS

b4e651b LOT 6: Add Pokedex list use case and application model for minimal UI projection
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

## FULL DIFF

diff --git a/packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart b/packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart
index 10ce56e..db806dd 100644
--- a/packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart
+++ b/packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart
@@ -1,27 +1,31 @@
 import '../models/pokedex_list_entry.dart';
+import '../ports/pokemon_read_repository.dart';
 import '../ports/project_workspace.dart';
-import '../services/pokemon_project_data_reader.dart';
 
 /// Première façade applicative Pokédex orientée liste, en lecture seule.
 ///
 /// Le use case masque les détails de stockage local et retourne uniquement
 /// un modèle applicatif exploitable par une future UI.
 class ListPokedexEntriesUseCase {
-  const ListPokedexEntriesUseCase({
-    this.reader = const PokemonProjectDataReader(),
-  });
+  const ListPokedexEntriesUseCase(this.repository);
 
-  final PokemonProjectDataReader reader;
+  /// Le use case dépend d'un port de lecture, pas d'un lecteur filesystem
+  /// concret. L'infrastructure peut donc évoluer sans faire fuiter ses choix
+  /// dans la façade applicative Pokédex.
+  final PokemonReadRepository repository;
 
   Future<List<PokedexListEntry>> execute(ProjectWorkspace workspace) async {
-    final speciesIndexEntries = await reader.listSpeciesIndexEntries(workspace);
+    final speciesIndexEntries = await repository.listSpeciesIndexEntries(workspace);
     final pokedexEntries = <PokedexListEntry>[];
 
     for (final speciesIndexEntry in speciesIndexEntries) {
       // La liste légère donne l'identité et l'ordre. On relit ensuite l'espèce
       // détaillée pour les champs purement métier qui n'appartiennent pas à la
       // projection technique locale.
-      final species = await reader.readSpeciesById(workspace, speciesIndexEntry.id);
+      final species = await repository.readSpeciesById(
+        workspace,
+        speciesIndexEntry.id,
+      );
       pokedexEntries.add(
         PokedexListEntry(
           id: speciesIndexEntry.id,
diff --git a/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart b/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
index 24da492..05893b4 100644
--- a/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
+++ b/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
@@ -4,6 +4,10 @@ import 'dart:io';
 import 'package:flutter/foundation.dart';
 import 'package:map_core/map_core.dart';
 
+import '../../application/models/pokemon_project_data_models.dart';
+import '../../application/ports/pokemon_read_repository.dart';
+import '../../application/ports/project_workspace.dart';
+import '../../application/services/pokemon_project_data_reader.dart';
 import '../../domain/repositories/repositories.dart';
 
 class FileProjectRepository implements ProjectRepository {
@@ -122,3 +126,59 @@ class FileTilesetRepository implements TilesetRepository {
     }
   }
 }
+
+/// Implémentation filesystem/workspace de la lecture locale Pokémon.
+///
+/// Cette classe sert de frontière infrastructurelle pour les use cases :
+/// la mécanique JSON concrète reste déléguée au lecteur local existant.
+class FilePokemonReadRepository implements PokemonReadRepository {
+  const FilePokemonReadRepository({
+    this.reader = const PokemonProjectDataReader(),
+  });
+
+  final PokemonProjectDataReader reader;
+
+  @override
+  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) {
+    return reader.readManifest(workspace);
+  }
+
+  @override
+  Future<PokemonCatalogFile> readCatalogByKey(
+    ProjectWorkspace workspace,
+    String catalogKey,
+  ) {
+    return reader.readCatalogByKey(workspace, catalogKey);
+  }
+
+  @override
+  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
+    ProjectWorkspace workspace,
+  ) {
+    return reader.listSpeciesIndexEntries(workspace);
+  }
+
+  @override
+  Future<PokemonSpeciesFile> readSpeciesById(
+    ProjectWorkspace workspace,
+    String speciesId,
+  ) {
+    return reader.readSpeciesById(workspace, speciesId);
+  }
+
+  @override
+  Future<PokemonLearnsetFile> readLearnsetById(
+    ProjectWorkspace workspace,
+    String speciesId,
+  ) {
+    return reader.readLearnsetById(workspace, speciesId);
+  }
+
+  @override
+  Future<PokemonEvolutionFile> readEvolutionById(
+    ProjectWorkspace workspace,
+    String speciesId,
+  ) {
+    return reader.readEvolutionById(workspace, speciesId);
+  }
+}
diff --git a/packages/map_editor/test/list_pokedex_entries_use_case_test.dart b/packages/map_editor/test/list_pokedex_entries_use_case_test.dart
index 018d719..389c6da 100644
--- a/packages/map_editor/test/list_pokedex_entries_use_case_test.dart
+++ b/packages/map_editor/test/list_pokedex_entries_use_case_test.dart
@@ -3,6 +3,9 @@ import 'dart:io';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:map_editor/src/application/errors/application_errors.dart';
 import 'package:map_editor/src/application/models/pokedex_list_entry.dart';
+import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
+import 'package:map_editor/src/application/ports/pokemon_read_repository.dart';
+import 'package:map_editor/src/application/ports/project_workspace.dart';
 import 'package:map_editor/src/application/use_cases/list_pokedex_entries_use_case.dart';
 import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
 import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
@@ -13,14 +16,10 @@ import 'package:path/path.dart' as p;
 void main() {
   late Directory tempProjectRoot;
   late ProjectFileSystem workspace;
-  late SeedPokemonDemoDataUseCase seedUseCase;
-  late ListPokedexEntriesUseCase useCase;
 
   setUp(() async {
     tempProjectRoot = await Directory.systemTemp.createTemp('pokedex_list_');
     workspace = ProjectFileSystem(tempProjectRoot.path);
-    seedUseCase = const SeedPokemonDemoDataUseCase();
-    useCase = const ListPokedexEntriesUseCase();
   });
 
   tearDown(() async {
@@ -29,9 +28,41 @@ void main() {
     }
   });
 
-  group('ListPokedexEntriesUseCase', () {
+  group('ListPokedexEntriesUseCase with abstract repository', () {
     test('returns a sorted pokedex list from the project workspace', () async {
-      await seedUseCase.execute(workspace);
+      final repository = _RecordingPokemonReadRepository(
+        indexEntries: <PokemonSpeciesIndexEntry>[
+          const PokemonSpeciesIndexEntry(
+            id: 'ivysaur',
+            nationalDex: 2,
+            primaryName: 'Ivysaur',
+            types: <String>['grass', 'poison'],
+            relativePath: 'data/pokemon/species/0002-ivysaur.json',
+          ),
+          const PokemonSpeciesIndexEntry(
+            id: 'bulbasaur',
+            nationalDex: 1,
+            primaryName: 'Bulbasaur',
+            types: <String>['grass', 'poison'],
+            relativePath: 'data/pokemon/species/0001-bulbasaur.json',
+          ),
+        ],
+        speciesById: <String, PokemonSpeciesFile>{
+          'bulbasaur': _species(
+            id: 'bulbasaur',
+            nationalDex: 1,
+            starterEligible: true,
+            genIntroduced: 1,
+          ),
+          'ivysaur': _species(
+            id: 'ivysaur',
+            nationalDex: 2,
+            starterEligible: false,
+            genIntroduced: 1,
+          ),
+        },
+      );
+      final useCase = ListPokedexEntriesUseCase(repository);
 
       final entries = await useCase.execute(workspace);
 
@@ -46,11 +77,31 @@ void main() {
       expect(bulbasaur.primaryName, 'Bulbasaur');
       expect(bulbasaur.types, <String>['grass', 'poison']);
       expect(bulbasaur.isStarterEligible, isTrue);
+      expect(repository.workspacesSeen, everyElement(same(workspace)));
     });
 
     test('does not expose filesystem concerns in the application model',
         () async {
-      await seedUseCase.execute(workspace);
+      final repository = _RecordingPokemonReadRepository(
+        indexEntries: <PokemonSpeciesIndexEntry>[
+          const PokemonSpeciesIndexEntry(
+            id: 'bulbasaur',
+            nationalDex: 1,
+            primaryName: 'Bulbasaur',
+            types: <String>['grass', 'poison'],
+            relativePath: 'data/pokemon/species/0001-bulbasaur.json',
+          ),
+        ],
+        speciesById: <String, PokemonSpeciesFile>{
+          'bulbasaur': _species(
+            id: 'bulbasaur',
+            nationalDex: 1,
+            starterEligible: true,
+            genIntroduced: 1,
+          ),
+        },
+      );
+      final useCase = ListPokedexEntriesUseCase(repository);
 
       final entries = await useCase.execute(workspace);
       final PokedexListEntry entry = entries.first;
@@ -59,6 +110,86 @@ void main() {
       expect(() => dynamicEntry.relativePath, throwsA(isA<NoSuchMethodError>()));
     });
 
+    test('returns starter eligibility from species gameplay flags', () async {
+      final repository = _RecordingPokemonReadRepository(
+        indexEntries: <PokemonSpeciesIndexEntry>[
+          const PokemonSpeciesIndexEntry(
+            id: 'bulbasaur',
+            nationalDex: 1,
+            primaryName: 'Bulbasaur',
+            types: <String>['grass', 'poison'],
+            relativePath: 'data/pokemon/species/0001-bulbasaur.json',
+          ),
+          const PokemonSpeciesIndexEntry(
+            id: 'ivysaur',
+            nationalDex: 2,
+            primaryName: 'Ivysaur',
+            types: <String>['grass', 'poison'],
+            relativePath: 'data/pokemon/species/0002-ivysaur.json',
+          ),
+        ],
+        speciesById: <String, PokemonSpeciesFile>{
+          'bulbasaur': _species(
+            id: 'bulbasaur',
+            nationalDex: 1,
+            starterEligible: true,
+            genIntroduced: 1,
+          ),
+          'ivysaur': _species(
+            id: 'ivysaur',
+            nationalDex: 2,
+            starterEligible: false,
+            genIntroduced: 1,
+          ),
+        },
+      );
+      final useCase = ListPokedexEntriesUseCase(repository);
+
+      final entries = await useCase.execute(workspace);
+
+      final bulbasaur = entries.firstWhere((entry) => entry.id == 'bulbasaur');
+      final ivysaur = entries.firstWhere((entry) => entry.id == 'ivysaur');
+      expect(bulbasaur.isStarterEligible, isTrue);
+      expect(ivysaur.isStarterEligible, isFalse);
+    });
+
+    test('fails explicitly when repository species data is invalid', () async {
+      final repository = _RecordingPokemonReadRepository(
+        indexEntries: <PokemonSpeciesIndexEntry>[
+          const PokemonSpeciesIndexEntry(
+            id: 'bulbasaur',
+            nationalDex: 1,
+            primaryName: 'Bulbasaur',
+            types: <String>['grass', 'poison'],
+            relativePath: 'data/pokemon/species/0001-bulbasaur.json',
+          ),
+        ],
+        speciesError: const EditorPersistenceException('Invalid JSON in species'),
+      );
+      final useCase = ListPokedexEntriesUseCase(repository);
+
+      expect(
+        () => useCase.execute(workspace),
+        throwsA(
+          isA<EditorPersistenceException>().having(
+            (error) => error.message,
+            'message',
+            contains('Invalid JSON'),
+          ),
+        ),
+      );
+    });
+  });
+
+  group('ListPokedexEntriesUseCase with filesystem repository', () {
+    late SeedPokemonDemoDataUseCase seedUseCase;
+    late ListPokedexEntriesUseCase useCase;
+
+    setUp(() {
+      seedUseCase = const SeedPokemonDemoDataUseCase();
+      useCase = const ListPokedexEntriesUseCase(FilePokemonReadRepository());
+    });
+
     test('uses the workspace project data and not the monorepo root', () async {
       await seedUseCase.execute(workspace);
 
@@ -101,7 +232,10 @@ void main() {
         FileProjectRepository(),
         const FileProjectWorkspaceFactory(),
       );
-      await createProjectUseCase.execute('Pokedex List Project', tempProjectRoot.path);
+      await createProjectUseCase.execute(
+        'Pokedex List Project',
+        tempProjectRoot.path,
+      );
       await seedUseCase.execute(workspace);
 
       final projectFile = File(workspace.projectManifestPath);
@@ -112,39 +246,129 @@ void main() {
       final after = await projectFile.readAsString();
       expect(after, before);
     });
+  });
+}

class _RecordingPokemonReadRepository implements PokemonReadRepository {
  _RecordingPokemonReadRepository({
    required this.indexEntries,
    this.speciesById = const <String, PokemonSpeciesFile>{},
    this.speciesError,
  });

  final List<PokemonSpeciesIndexEntry> indexEntries;
  final Map<String, PokemonSpeciesFile> speciesById;
  final EditorApplicationException? speciesError;
  final List<ProjectWorkspace> workspacesSeen = <ProjectWorkspace>[];

  @override
  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) async {
    workspacesSeen.add(workspace);
    return indexEntries;
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    workspacesSeen.add(workspace);
    if (speciesError != null) {
      throw speciesError!;
    }
    final species = speciesById[speciesId];
    if (species == null) {
      throw EditorNotFoundException('Pokemon species not found: $speciesId');
    }
    return species;
  }

  @override
  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }
}

PokemonSpeciesFile _species({
  required String id,
  required int nationalDex,
  required bool starterEligible,
  required int genIntroduced,
}) {
  return PokemonSpeciesFile(
    id: id,
    slug: id,
    nationalDex: nationalDex,
    names: <String, String>{'en': id == 'bulbasaur' ? 'Bulbasaur' : 'Ivysaur'},
    speciesName: const <String, String>{'en': 'Seed Pokemon'},
    genIntroduced: genIntroduced,
    typing: const PokemonSpeciesTyping(types: <String>['grass', 'poison']),
    baseStats: const PokemonSpeciesBaseStats(
      hp: 45,
      atk: 49,
      def: 49,
      spa: 65,
      spd: 65,
      spe: 45,
      bst: 318,
    ),
    abilities: const PokemonSpeciesAbilities(
      primary: 'overgrow',
      hidden: 'chlorophyll',
    ),
    breeding: const PokemonSpeciesBreeding(
      genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
      eggGroups: <String>['monster', 'grass'],
      hatchCycles: 20,
    ),
    progression: const PokemonSpeciesProgression(
      growthRateId: 'medium_slow',
      baseExp: 64,
      catchRate: 45,
      baseFriendship: 50,
    ),
    evolutionRef: id,
    learnsetRef: id,
    spriteSetRef: id,
    cryRef: id,
    dexContent: const PokemonSpeciesDexContent(
      heightM: 0.7,
      weightKg: 6.9,
      color: 'green',
      flavorText: 'Demo entry',
    ),
    gameplayFlags: PokemonSpeciesGameplayFlags(
      starterEligible: starterEligible,
    ),
    sourceMeta: const PokemonSpeciesSourceMeta(
      seededBy: 'test',
      seedVersion: 1,
    ),
  );
}
```

Note honnête :
- le bundle reflète l’état du working tree au moment de son exécution ;
- il ne montre pas ce mini-rapport, créé ensuite ;
- il ne montre pas non plus le mini-changement dans `file_pokemon_read_repository_test.dart` via `git diff --stat`, car ce fichier est non suivi.

## 10. Code intégral modifié pour ce mini-fix

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late String repoRootPath;
  late ProjectFileSystem workspace;
  late SeedPokemonDemoDataUseCase seedUseCase;
  late FilePokemonReadRepository repository;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokemon_repo_');
    repoRootPath = _resolveRepositoryRootFromCurrentDirectory();
    workspace = ProjectFileSystem(tempProjectRoot.path);
    seedUseCase = const SeedPokemonDemoDataUseCase();
    repository = const FilePokemonReadRepository();
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('FilePokemonReadRepository', () {
    test('reads from the workspace project and not the monorepo root', () async {
      await seedUseCase.execute(workspace);

      final decoy = await Directory.systemTemp.createTemp('pokemon_repo_decoy_');
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

        final entries = await repository.listSpeciesIndexEntries(workspace);
        final species = await repository.readSpeciesById(workspace, 'bulbasaur');

        expect(entries.map((entry) => entry.id), isNot(contains('venusaur')));
        expect(species.id, 'bulbasaur');
      } finally {
        Directory.current = originalCurrent.path;
        if (await decoy.exists()) {
          await decoy.delete(recursive: true);
        }
      }
    });

    test('reads the seeded pokemon files through the repository abstraction',
        () async {
      await seedUseCase.execute(workspace);

      final manifest = await repository.readManifest(workspace);
      final species = await repository.readSpeciesById(workspace, 'bulbasaur');
      final learnset = await repository.readLearnsetById(workspace, 'bulbasaur');
      final evolution = await repository.readEvolutionById(workspace, 'bulbasaur');
      final moves = await repository.readCatalogByKey(workspace, 'moves');

      expect(manifest.kind, 'pokemon_data_manifest');
      expect(species.id, 'bulbasaur');
      expect(learnset.speciesId, 'bulbasaur');
      expect(evolution.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(
        moves.entries.map((entry) => entry['id']),
        containsAll(<String>['tackle', 'growl', 'vine_whip', 'razor_leaf']),
      );
    });

    test('throws explicit error when a species file is missing', () async {
      await seedUseCase.execute(workspace);

      expect(
        () => repository.readSpeciesById(workspace, 'venusaur'),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon species not found'),
          ),
        ),
      );
    });

    test('throws explicit error when a species json file is invalid', () async {
      await seedUseCase.execute(workspace);

      final speciesFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      await speciesFile.writeAsString('{ invalid json');

      expect(
        () => repository.readSpeciesById(workspace, 'bulbasaur'),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
    });

    test('leaves project.json strictly unchanged', () async {
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );
      await createProjectUseCase.execute('Pokemon Repo Project', tempProjectRoot.path);
      await seedUseCase.execute(workspace);

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await repository.readSpeciesById(workspace, 'bulbasaur');
      await repository.readCatalogByKey(workspace, 'moves');

      final after = await projectFile.readAsString();
      expect(after, before);
    });

    test('does not recreate data or assets at the monorepo root', () async {
      await seedUseCase.execute(workspace);

      await repository.listSpeciesIndexEntries(workspace);

      expect(Directory(p.join(repoRootPath, 'data')).existsSync(), isFalse);
      expect(Directory(p.join(repoRootPath, 'assets')).existsSync(), isFalse);
    });
  });
}

String _resolveRepositoryRootFromCurrentDirectory() {
  var current = Directory.current.absolute;

  while (true) {
    final agentsFile = File(p.join(current.path, 'AGENTS.md'));
    final mapEditorDir = Directory(p.join(current.path, 'packages', 'map_editor'));
    if (agentsFile.existsSync() && mapEditorDir.existsSync()) {
      return current.path;
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError(
        'Could not resolve repository root from Directory.current: '
        '${Directory.current.path}',
      );
    }
    current = parent;
  }
}
```
