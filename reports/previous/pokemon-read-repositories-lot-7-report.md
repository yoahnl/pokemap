# Rapport — Lot 7 Pokémon — Repositories de lecture locaux

## 1. Résumé exécutif

Ce lot introduit une vraie séparation entre la façade applicative Pokédex et la lecture concrète du filesystem.

Concrètement :
- un port `PokemonReadRepository` a été ajouté côté application ;
- une implémentation concrète `FilePokemonReadRepository` a été ajoutée côté infrastructure ;
- `ListPokedexEntriesUseCase` dépend maintenant du port abstrait, plus de `PokemonProjectDataReader` directement ;
- des tests ciblés couvrent à la fois le use case via abstraction et le repository concret branché au workspace projet.

Ce lot n’a pas fait :
- d’UI ;
- de provider Riverpod ;
- de modification de `project.json` ;
- de runtime Pokémon ;
- d’écriture JSON ;
- d’import externe ;
- de cache global ou d’index persistant.

## 2. Problème architectural exact avant ce lot

Avant ce lot, `ListPokedexEntriesUseCase` dépendait directement de `PokemonProjectDataReader`.

Conséquences :
- le use case connaissait une implémentation concrète filesystem ;
- la frontière architecturelle entre application et infrastructure restait floue ;
- la lecture locale Pokémon était exploitable, mais pas encore correctement encapsulée derrière une abstraction dédiée ;
- les futurs use cases Pokédex auraient risqué de répliquer le même couplage.

Le besoin du lot 7 était donc de garder le comportement existant, tout en remplaçant cette dépendance directe par un port de lecture explicite.

## 3. Stratégie retenue

La stratégie retenue est volontairement petite et pragmatique :

1. créer un seul port de lecture `PokemonReadRepository` ;
2. couvrir uniquement les lectures déjà utiles ou imminentes :
   - manifeste ;
   - catalogues ;
   - liste légère des espèces ;
   - espèce par id ;
   - learnset par id ;
   - évolution par id ;
3. brancher une implémentation infrastructurelle `FilePokemonReadRepository` qui délègue au reader local existant ;
4. migrer `ListPokedexEntriesUseCase` pour qu’il dépende uniquement de ce port.

Cette approche évite deux écueils :
- une abstraction cosmétique non utilisée ;
- une explosion artificielle de interfaces et de couches.

## 4. Interfaces créées

Interface créée :
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`

Responsabilité :
- définir le contrat minimal de lecture locale Pokémon pour les use cases applicatifs ;
- masquer la mécanique filesystem / JSON concrète ;
- conserver une API lisible et directement utile à la roadmap Pokédex.

Méthodes exposées :
- `readManifest(...)`
- `readCatalogByKey(...)`
- `listSpeciesIndexEntries(...)`
- `readSpeciesById(...)`
- `readLearnsetById(...)`
- `readEvolutionById(...)`

## 5. Implémentations concrètes créées ou modifiées

Implémentation ajoutée dans :
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

Classe :
- `FilePokemonReadRepository`

Rôle :
- frontière infrastructurelle de lecture Pokémon locale ;
- délégation vers `PokemonProjectDataReader` pour conserver la logique de lecture déjà validée ;
- ancrage strict au `ProjectWorkspace`, donc aucune dépendance à `Directory.current` ni à la racine du monorepo.

## 6. Migration de `ListPokedexEntriesUseCase`

Fichier :
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart`

Avant :
- dépendance directe à `PokemonProjectDataReader`

Après :
- dépendance à `PokemonReadRepository`

Effet concret :
- le use case reste purement applicatif ;
- il garde le même comportement fonctionnel ;
- il ne connaît plus l’implémentation filesystem ;
- il continue à produire une liste Pokédex triée, sans exposer `relativePath` ni d’autres détails de stockage.

## 7. Invariants conservés

Les invariants importants sont conservés :
- la vérité métier d’une espèce reste le JSON, pas le nom de fichier ;
- la lecture reste ancrée au workspace projet utilisateur ;
- aucune lecture ne dépend de `Directory.current` ;
- `project.json` reste strictement inchangé ;
- rien n’est recréé à la racine du monorepo ;
- les erreurs restent explicites.

## 8. Fichiers modifiés / créés

Fichiers de code créés ou modifiés dans ce lot :
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/list_pokedex_entries_use_case_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_read_repository_test.dart`

Fichier de rapport créé :
- `/Users/karim/Project/pokemonProject/reports/pokemon-read-repositories-lot-7-report.md`

## 9. Tests réellement exécutés

Commandes exécutées :

```bash
flutter test test/list_pokedex_entries_use_case_test.dart
flutter test test/file_pokemon_read_repository_test.dart
```

Résultats :
- `list_pokedex_entries_use_case_test.dart` : OK, 6 tests passés
- `file_pokemon_read_repository_test.dart` : OK, 6 tests passés

Points couverts :
- le use case Pokédex continue de fonctionner via un port abstrait ;
- le repository concret lit bien depuis le workspace ;
- aucune dépendance à `Directory.current` ;
- `project.json` reste inchangé ;
- erreurs explicites si fichier absent ou JSON invalide ;
- rien n’est recréé à la racine du monorepo.

## 10. Résultat de l’analyse

Commande exécutée :

```bash
flutter analyze --no-pub lib/src/application/ports/pokemon_read_repository.dart lib/src/application/use_cases/list_pokedex_entries_use_case.dart lib/src/infrastructure/repositories/file_repositories.dart test/list_pokedex_entries_use_case_test.dart test/file_pokemon_read_repository_test.dart
```

Résultat :

```text
No issues found! (ran in 1.2s)
```

## 11. Preuve que `project.json` est inchangé

Le point est couvert par deux tests réels :
- dans `list_pokedex_entries_use_case_test.dart`
- dans `file_pokemon_read_repository_test.dart`

Dans les deux cas :
- un vrai projet est créé via `CreateProjectUseCase` ;
- le contenu brut de `project.json` est lu avant l’opération ;
- la lecture Pokémon est exécutée ;
- le contenu brut est relu après ;
- le test vérifie une égalité byte-for-byte.

Aucune écriture sur `project.json` n’a été ajoutée dans ce lot.

## 12. Preuve que rien n’est recréé à la racine du monorepo

Vérification directe exécutée avant la clôture du lot :

```bash
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
```

Sortie :

```text
[aucune sortie]
```

Le point est aussi couvert par un test dédié dans `file_pokemon_read_repository_test.dart`.

## 13. Sorties Git utiles

### `git status --short`

Commande exécutée après création du rapport :

```bash
git status --short
```

Sortie :

```text
 M packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
 M packages/map_editor/test/list_pokedex_entries_use_case_test.dart
?? packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
?? packages/map_editor/test/file_pokemon_read_repository_test.dart
?? reports/pokemon-read-repositories-lot-7-report.md
```

### `git diff --stat`

Commande exécutée avant création du rapport :

```bash
git diff --stat -- packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart packages/map_editor/test/list_pokedex_entries_use_case_test.dart packages/map_editor/test/file_pokemon_read_repository_test.dart
```

Sortie :

```text
 .../use_cases/list_pokedex_entries_use_case.dart   |  18 +-
 .../repositories/file_repositories.dart            |  60 +++++
 .../test/list_pokedex_entries_use_case_test.dart   | 296 ++++++++++++++++++---
 3 files changed, 331 insertions(+), 43 deletions(-)
```

Note honnête :
- `git diff --stat` n’inclut pas les fichiers non suivis ;
- pour ce lot, le port `pokemon_read_repository.dart`, le test `file_pokemon_read_repository_test.dart` et ce rapport sont des fichiers non suivis ;
- ils apparaissent donc via `git status --short` et `git ls-files --others --exclude-standard`, pas dans le `diff --stat`.

### `git ls-files --others --exclude-standard`

Commande exécutée avant création du rapport :

```bash
git ls-files --others --exclude-standard packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart packages/map_editor/test/file_pokemon_read_repository_test.dart reports/pokemon-read-repositories-lot-7-report.md
```

Sortie :

```text
packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
packages/map_editor/test/file_pokemon_read_repository_test.dart
reports/pokemon-read-repositories-lot-7-report.md
```

## 14. Bundle de review

Commande exécutée :

```bash
./review_bundle.sh
```

Chemin du fichier généré :

```text
.review/review-20260408-231910.txt
```

Contenu intégral du bundle :

```text
# REVIEW BUNDLE

Generated at: 2026-04-08 23:19:10
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
- le bundle a été généré avant l’écriture de ce rapport ;
- il ne contient donc pas ce fichier de rapport ;
- il ne liste pas non plus les fichiers non suivis dans `git diff --stat`, ce qui est le comportement normal de Git.

## 15. Code intégral réalisé

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`

```dart
import '../models/pokemon_project_data_models.dart';
import 'project_workspace.dart';

/// Contrat de lecture des données Pokémon locales d'un projet utilisateur.
///
/// Cette abstraction sert de frontière pour les use cases applicatifs :
/// ils n'ont pas à connaître la stratégie de lecture JSON ni le filesystem.
abstract class PokemonReadRepository {
  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace);

  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  );

  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  );

  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  );

  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  );

  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  );
}
```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart`

```dart
import '../models/pokedex_list_entry.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/project_workspace.dart';

/// Première façade applicative Pokédex orientée liste, en lecture seule.
///
/// Le use case masque les détails de stockage local et retourne uniquement
/// un modèle applicatif exploitable par une future UI.
class ListPokedexEntriesUseCase {
  const ListPokedexEntriesUseCase(this.repository);

  /// Le use case dépend d'un port de lecture, pas d'un lecteur filesystem
  /// concret. L'infrastructure peut donc évoluer sans faire fuiter ses choix
  /// dans la façade applicative Pokédex.
  final PokemonReadRepository repository;

  Future<List<PokedexListEntry>> execute(ProjectWorkspace workspace) async {
    final speciesIndexEntries = await repository.listSpeciesIndexEntries(workspace);
    final pokedexEntries = <PokedexListEntry>[];

    for (final speciesIndexEntry in speciesIndexEntries) {
      // La liste légère donne l'identité et l'ordre. On relit ensuite l'espèce
      // détaillée pour les champs purement métier qui n'appartiennent pas à la
      // projection technique locale.
      final species = await repository.readSpeciesById(
        workspace,
        speciesIndexEntry.id,
      );
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

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import '../../application/models/pokemon_project_data_models.dart';
import '../../application/ports/pokemon_read_repository.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/services/pokemon_project_data_reader.dart';
import '../../domain/repositories/repositories.dart';

class FileProjectRepository implements ProjectRepository {
  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    debugPrint('FileProjectRepository: Validating and saving project to $path');
    ProjectValidator.validate(project);
    final file = File(path);
    if (!await file.parent.exists()) await file.parent.create(recursive: true);
    final json = project.toJson();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }

  @override
  Future<ProjectManifest> loadProject(String path) async {
    debugPrint('FileProjectRepository: Loading project from $path');
    final file = File(path);
    if (!await file.exists()) {
      throw const ProjectLoadException('Project file not found');
    }
    final content = await file.readAsString();
    try {
      final json = migrateProjectManifestJson(
        jsonDecode(content) as Map<String, dynamic>,
      );
      final manifest = ProjectManifest.fromJson(json);
      ProjectValidator.validate(manifest);
      return manifest;
    } catch (e) {
      throw ProjectLoadException('Failed to load project: $e');
    }
  }
}

class FileMapRepository implements MapRepository {
  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    debugPrint('FileMapRepository: Validating and saving map to $path');
    MapValidator.validate(
      map,
      projectDialogueContext: projectDialogueContext,
    );
    final file = File(path);
    if (!await file.parent.exists()) await file.parent.create(recursive: true);
    final json = map.toJson();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }

  @override
  Future<MapData> loadMap(String path) async {
    debugPrint('FileMapRepository: Loading map from $path');
    final file = File(path);
    if (!await file.exists()) {
      throw MapLoadException('Map file not found: $path');
    }
    final content = await file.readAsString();
    try {
      final json = migrateMapDataJson(
        jsonDecode(content) as Map<String, dynamic>,
      );
      final map = MapData.fromJson(json);
      MapValidator.validate(map);
      return map;
    } catch (e) {
      throw MapLoadException('Failed to load map: $e');
    }
  }

  @override
  Future<void> deleteMap(String path) async {
    debugPrint('FileMapRepository: Deleting map at $path');
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> renameMap(String oldPath, String newPath) async {
    debugPrint('FileMapRepository: Renaming map from $oldPath to $newPath');
    final file = File(oldPath);
    if (await file.exists()) {
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await file.rename(newPath);
    }
  }
}

class FileTilesetRepository implements TilesetRepository {
  @override
  Future<void> saveTileset(TilesetConfig tileset, String path) async {
    final file = File(path);
    if (!await file.parent.exists()) await file.parent.create(recursive: true);
    final json = tileset.toJson();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }

  @override
  Future<TilesetConfig> loadTileset(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const AssetNotFoundException('Tileset file not found');
    }
    final content = await file.readAsString();
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      return TilesetConfig.fromJson(json);
    } catch (e) {
      throw const ValidationException('Failed to load tileset');
    }
  }
}

/// Implémentation filesystem/workspace de la lecture locale Pokémon.
///
/// Cette classe sert de frontière infrastructurelle pour les use cases :
/// la mécanique JSON concrète reste déléguée au lecteur local existant.
class FilePokemonReadRepository implements PokemonReadRepository {
  const FilePokemonReadRepository({
    this.reader = const PokemonProjectDataReader(),
  });

  final PokemonProjectDataReader reader;

  @override
  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) {
    return reader.readManifest(workspace);
  }

  @override
  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) {
    return reader.readCatalogByKey(workspace, catalogKey);
  }

  @override
  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) {
    return reader.listSpeciesIndexEntries(workspace);
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    return reader.readSpeciesById(workspace, speciesId);
  }

  @override
  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    return reader.readLearnsetById(workspace, speciesId);
  }

  @override
  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    return reader.readEvolutionById(workspace, speciesId);
  }
}
```

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/list_pokedex_entries_use_case_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokedex_list_entry.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_read_repository.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/list_pokedex_entries_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokedex_list_');
    workspace = ProjectFileSystem(tempProjectRoot.path);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('ListPokedexEntriesUseCase with abstract repository', () {
    test('returns a sorted pokedex list from the project workspace', () async {
      final repository = _RecordingPokemonReadRepository(
        indexEntries: <PokemonSpeciesIndexEntry>[
          const PokemonSpeciesIndexEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            relativePath: 'data/pokemon/species/0002-ivysaur.json',
          ),
          const PokemonSpeciesIndexEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            relativePath: 'data/pokemon/species/0001-bulbasaur.json',
          ),
        ],
        speciesById: <String, PokemonSpeciesFile>{
          'bulbasaur': _species(
            id: 'bulbasaur',
            nationalDex: 1,
            starterEligible: true,
            genIntroduced: 1,
          ),
          'ivysaur': _species(
            id: 'ivysaur',
            nationalDex: 2,
            starterEligible: false,
            genIntroduced: 1,
          ),
        },
      );
      final useCase = ListPokedexEntriesUseCase(repository);

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
      expect(repository.workspacesSeen, everyElement(same(workspace)));
    });

    test('does not expose filesystem concerns in the application model',
        () async {
      final repository = _RecordingPokemonReadRepository(
        indexEntries: <PokemonSpeciesIndexEntry>[
          const PokemonSpeciesIndexEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            relativePath: 'data/pokemon/species/0001-bulbasaur.json',
          ),
        ],
        speciesById: <String, PokemonSpeciesFile>{
          'bulbasaur': _species(
            id: 'bulbasaur',
            nationalDex: 1,
            starterEligible: true,
            genIntroduced: 1,
          ),
        },
      );
      final useCase = ListPokedexEntriesUseCase(repository);

      final entries = await useCase.execute(workspace);
      final PokedexListEntry entry = entries.first;
      final dynamic dynamicEntry = entry;

      expect(() => dynamicEntry.relativePath, throwsA(isA<NoSuchMethodError>()));
    });

    test('returns starter eligibility from species gameplay flags', () async {
      final repository = _RecordingPokemonReadRepository(
        indexEntries: <PokemonSpeciesIndexEntry>[
          const PokemonSpeciesIndexEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            relativePath: 'data/pokemon/species/0001-bulbasaur.json',
          ),
          const PokemonSpeciesIndexEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            relativePath: 'data/pokemon/species/0002-ivysaur.json',
          ),
        ],
        speciesById: <String, PokemonSpeciesFile>{
          'bulbasaur': _species(
            id: 'bulbasaur',
            nationalDex: 1,
            starterEligible: true,
            genIntroduced: 1,
          ),
          'ivysaur': _species(
            id: 'ivysaur',
            nationalDex: 2,
            starterEligible: false,
            genIntroduced: 1,
          ),
        },
      );
      final useCase = ListPokedexEntriesUseCase(repository);

      final entries = await useCase.execute(workspace);

      final bulbasaur = entries.firstWhere((entry) => entry.id == 'bulbasaur');
      final ivysaur = entries.firstWhere((entry) => entry.id == 'ivysaur');
      expect(bulbasaur.isStarterEligible, isTrue);
      expect(ivysaur.isStarterEligible, isFalse);
    });

    test('fails explicitly when repository species data is invalid', () async {
      final repository = _RecordingPokemonReadRepository(
        indexEntries: <PokemonSpeciesIndexEntry>[
          const PokemonSpeciesIndexEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            relativePath: 'data/pokemon/species/0001-bulbasaur.json',
          ),
        ],
        speciesError: const EditorPersistenceException('Invalid JSON in species'),
      );
      final useCase = ListPokedexEntriesUseCase(repository);

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

  group('ListPokedexEntriesUseCase with filesystem repository', () {
    late SeedPokemonDemoDataUseCase seedUseCase;
    late ListPokedexEntriesUseCase useCase;

    setUp(() {
      seedUseCase = const SeedPokemonDemoDataUseCase();
      useCase = const ListPokedexEntriesUseCase(FilePokemonReadRepository());
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
      await createProjectUseCase.execute(
        'Pokedex List Project',
        tempProjectRoot.path,
      );
      await seedUseCase.execute(workspace);

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await useCase.execute(workspace);

      final after = await projectFile.readAsString();
      expect(after, before);
    });
  });
}

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

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_read_repository_test.dart`

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
  late ProjectFileSystem workspace;
  late SeedPokemonDemoDataUseCase seedUseCase;
  late FilePokemonReadRepository repository;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokemon_repo_');
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

      expect(Directory('/Users/karim/Project/pokemonProject/data').existsSync(), isFalse);
      expect(Directory('/Users/karim/Project/pokemonProject/assets').existsSync(), isFalse);
    });
  });
}
```

## 16. Conclusion honnête

Ce lot fait exactement ce qu’il devait faire :
- il introduit une vraie abstraction de lecture Pokémon locale ;
- il fournit une implémentation concrète workspace/filesystem ;
- il retire la dépendance directe du use case Pokédex au reader concret.

Ce lot ne fait volontairement pas :
- d’écriture ;
- d’UI ;
- de provider ;
- de runtime ;
- de refactor plus large de toute la pile Pokémon.

La base est maintenant plus saine pour la suite :
- les use cases applicatifs peuvent dépendre d’un port stable ;
- l’infrastructure de lecture locale reste confinée à son implémentation concrète ;
- la suite de la roadmap Pokédex pourra évoluer sans réintroduire de couplage direct au filesystem.
