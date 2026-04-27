# Rapport — Lot 11 — Indexation locale Pokémon

## Résumé exécutif

Ce lot 11 ajoute une capacité d'indexation locale légère des espèces Pokémon déjà stockées dans le workspace projet utilisateur. L'objectif est de préparer une future liste Pokédex sans charger les espèces complètes ni toucher à l'UI, au runtime, aux imports externes, aux learnsets, aux évolutions ou aux médias.

Le résultat livré est volontairement petit :
- un nouveau modèle léger d'entrée d'index ;
- un service applicatif `PokemonDatabaseIndex` ;
- un point d'entrée dédié côté repository de lecture ;
- des tests ciblés sur l'indexation ;
- aucune modification de `project.json` ;
- aucune lecture de learnsets, évolutions ou médias pendant l'indexation.

## Problème traité

Avant ce lot, le projet savait déjà :
- lire les données Pokémon locales ;
- produire une projection légère orientée lecture détaillée/listing existant ;
- exposer une liste Pokédex applicative via un use case.

Mais il manquait encore une brique explicitement centrée sur l'indexation locale minimale des espèces depuis la configuration du projet. Pour les prochains lots, il fallait une base propre pour alimenter une future liste UI sans :
- charger tout le détail métier complet ;
- coupler la liste à l'arborescence technique ;
- relire learnsets/evolutions/media ;
- contourner les repositories déjà en place.

## Audit de l'existant

### Modèles Pokémon déjà présents

Les modèles de lecture Pokémon existaient déjà dans :
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`

On y trouve notamment :
- `PokemonDataManifest`
- `PokemonCatalogFile`
- `PokemonSpeciesFile`
- `PokemonLearnsetFile`
- `PokemonEvolutionFile`
- `PokemonSpeciesIndexEntry`

`PokemonSpeciesIndexEntry` existait déjà, mais son rôle reste lié à la couche de lecture locale historique et il expose encore `relativePath`, ce qui n'est pas l'intention exacte du lot 11.

### Repositories de lecture déjà présents

Le port de lecture existait déjà dans :
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`

L'implémentation filesystem existait déjà dans :
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

Le lecteur concret local existait déjà dans :
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`

### Quelle couche lit déjà `species`

La lecture détaillée et la projection légère existantes passent déjà par `PokemonProjectDataReader`, puis par `FilePokemonReadRepository`.

Comportement observé avant le lot 11 :
- lecture du manifeste Pokémon local ;
- lecture des catalogues ;
- lecture détaillée d'une espèce ;
- projection légère `PokemonSpeciesIndexEntry` ;
- erreurs explicites si un JSON `species` est invalide.

La stratégie existante du projet est donc stricte : un fichier JSON espèce invalide remonte une erreur explicite, il n'est pas ignoré silencieusement.

### Configuration Pokémon projet existante

La configuration Pokémon projet existe déjà dans le manifest projet via `ProjectPokemonConfig` dans `map_core`. Le point utile pour ce lot est surtout le répertoire configuré des espèces, exposé via `project.pokemon.speciesDir`.

Conclusion d'audit :
- le lot 11 ne devait pas reconstruire une nouvelle lecture filesystem ;
- le bon branchement est : config projet -> repository de lecture -> projection légère dédiée ;
- il fallait ajouter une projection minimale spécifique à l'index de base de données Pokémon, pas contourner les briques existantes.

## Décisions d'architecture

### Placement retenu

J'ai retenu cette architecture :
- modèle léger : `PokemonDatabaseIndexEntry` dans `application/models/`
- service applicatif : `PokemonDatabaseIndex` dans `application/services/`
- extension minimale du port `PokemonReadRepository`
- implémentation côté `FilePokemonReadRepository`
- réutilisation de `PokemonProjectDataReader` pour la lecture JSON concrète

### Pourquoi ce placement est le bon

Ce placement est cohérent avec l'état actuel du projet pour quatre raisons :

1. Le service a une responsabilité applicative claire.
Il lit la config projet et demande un index léger des espèces. Il ne sait rien du filesystem concret.

2. Le repository reste la frontière de lecture.
Le service ne dépend pas de `dart:io` et ne contourne pas l'infrastructure existante.

3. Le lecteur JSON existant n'est pas dupliqué.
On réutilise la lecture locale déjà stabilisée au lieu de recoder une nouvelle lecture des mêmes fichiers.

4. Le lot reste petit.
On n'introduit ni cache, ni UI, ni recherche, ni index persistant, ni abstraction supplémentaire inutile.

### Forme exacte de l'index

L'index expose strictement :
- `id`
- `nationalDex`
- `primaryName`
- `refs`

`refs` regroupe seulement les références déjà présentes dans le JSON espèce :
- `learnset`
- `evolution`
- `spriteSet`
- `cry`

Cela donne une base utile pour une future liste puis ouverture de détails ciblés, sans charger les données détaillées.

### Règle retenue pour le nom principal

Le lot 11 ne devait pas inventer une nouvelle règle. J'ai repris la priorité déjà implicite dans la couche de lecture locale :
- `names['en']`
- sinon `names['fr']`
- sinon n'importe quelle autre valeur non vide
- sinon `id`

Hypothèse assumée :
- le projet n'avait pas encore une règle explicite "nom d'affichage Pokédex" dédiée ;
- j'ai donc réutilisé la règle déjà la plus cohérente avec l'existant.

## Périmètre inclus

Ce lot inclut uniquement :
- le listing des fichiers `species` à partir de la config projet ;
- la construction d'un index léger d'espèces ;
- l'exposition des champs minimaux demandés ;
- des tests ciblés sur ce comportement ;
- un branchement propre sur la lecture existante.

## Périmètre exclu

Je n'ai volontairement pas touché :
- l'UI ;
- les providers Riverpod ;
- le runtime ;
- les imports externes ;
- les learnsets ;
- les évolutions ;
- les médias ;
- la validation métier avancée ;
- `project.json` ;
- la recherche texte ;
- le tri avancé ;
- le cache ;
- l'index persistant disque ;
- les lots 12 et suivants.

## Liste exacte des fichiers modifiés

Fichiers créés :
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_database_index.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_database_index.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_database_index_test.dart`

Fichiers modifiés :
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/list_pokedex_entries_use_case_test.dart`

## Explication détaillée de chaque fichier modifié

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_database_index.dart`

Ajoute le modèle léger du lot 11 :
- `PokemonDatabaseIndexRefs`
- `PokemonDatabaseIndexEntry`

Ce fichier est la projection applicative minimale voulue pour une future liste. Il ne remplace pas `PokemonSpeciesFile` ; il évite justement de charger tout ce modèle détaillé quand on veut juste indexer.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_database_index.dart`

Ajoute le service applicatif du lot :
- charge le `ProjectManifest`
- lit `project.pokemon.speciesDir`
- demande l'index léger au repository de lecture

Ce service ne touche pas au filesystem directement et ne lit pas learnsets/evolutions/media.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`

Ajoute une méthode dédiée :
- `listDatabaseIndexEntries(...)`

Le port de lecture reste la frontière applicative. Cela évite que le service du lot 11 parle directement au lecteur concret JSON.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`

Ajoute la lecture concrète de l'index léger :
- listing du répertoire `species` configuré ;
- lecture JSON espèce fichier par fichier ;
- projection en `PokemonDatabaseIndexEntry` ;
- tri stable par `nationalDex`, puis `id`.

Important :
- aucune lecture de learnsets ;
- aucune lecture d'évolutions ;
- aucune lecture de médias ;
- comportement strict conservé si un JSON espèce est invalide.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

Ajoute le branchement infrastructure :
- `FilePokemonReadRepository.listDatabaseIndexEntries(...)`

Cette méthode délègue au lecteur local existant, ce qui évite toute duplication de logique filesystem.

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_database_index_test.dart`

Ajoute les tests dédiés du lot 11 :
- indexation nominale ;
- extraction des champs minimaux ;
- respect du `speciesDir` configuré ;
- dossier vide ;
- JSON invalide ;
- preuve qu'on ne lit pas learnsets/evolutions/media ;
- indépendance vis-à-vis de `Directory.current` ;
- `project.json` inchangé ;
- absence de recréation de `./data` / `./assets` à la racine du monorepo.

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/list_pokedex_entries_use_case_test.dart`

Ce fichier n'a été touché que pour rester compatible avec le port `PokemonReadRepository` enrichi. Il n'y a pas eu de changement fonctionnel du use case Pokédex du lot 6.

## Tests ajoutés

Tests réellement ajoutés pour le lot 11 :
- `indexes seeded species with the minimal list projection`
- `uses the project pokemon speciesDir instead of a hardcoded path`
- `returns an empty index when the configured species directory is empty`
- `fails explicitly when a species json file is invalid`
- `does not load learnsets evolutions or media during indexing`
- `reads from the workspace project and not Directory.current`
- `leaves project.json strictly unchanged`
- `does not recreate data or assets at the monorepo root`

## Commandes réellement exécutées

### Tests

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/pokemon_database_index_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/list_pokedex_entries_use_case_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/file_pokemon_read_repository_test.dart
```

### Analyse

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub \
  lib/src/application/models/pokemon_database_index.dart \
  lib/src/application/services/pokemon_database_index.dart \
  lib/src/application/services/pokemon_project_data_reader.dart \
  lib/src/application/ports/pokemon_read_repository.dart \
  lib/src/infrastructure/repositories/file_repositories.dart \
  test/pokemon_database_index_test.dart \
  test/list_pokedex_entries_use_case_test.dart \
  test/file_pokemon_read_repository_test.dart
```

### Vérifications de périmètre et état Git

```bash
cd /Users/karim/Project/pokemonProject && git status --short
cd /Users/karim/Project/pokemonProject && git diff --stat -- \
  packages/map_editor/lib/src/application/models/pokemon_database_index.dart \
  packages/map_editor/lib/src/application/services/pokemon_database_index.dart \
  packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart \
  packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart \
  packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart \
  packages/map_editor/test/pokemon_database_index_test.dart \
  packages/map_editor/test/list_pokedex_entries_use_case_test.dart \
  reports/pokemon-database-index-lot-11-report.md
cd /Users/karim/Project/pokemonProject && git ls-files --others --exclude-standard \
  packages/map_editor/lib/src/application/models/pokemon_database_index.dart \
  packages/map_editor/lib/src/application/services/pokemon_database_index.dart \
  packages/map_editor/test/pokemon_database_index_test.dart \
  reports/pokemon-database-index-lot-11-report.md
cd /Users/karim/Project/pokemonProject && find . -maxdepth 2 \\( -path './data' -o -path './assets' \\) -print
cd /Users/karim/Project/pokemonProject && ./review_bundle.sh
```

## Résultats réels des commandes

### Résultats des tests

`flutter test test/pokemon_database_index_test.dart`

```text
00:01 +8: All tests passed!
```

Note honnête :
- une première tentative a échoué sur un problème Flutter temporaire de suppression de `macos/Flutter/ephemeral/Packages/.packages` ;
- le rerun immédiat a réussi sans changement de code.

`flutter test test/list_pokedex_entries_use_case_test.dart`

```text
00:01 +6: All tests passed!
```

`flutter test test/file_pokemon_read_repository_test.dart`

```text
00:01 +6: All tests passed!
```

### Résultat de l'analyse

```text
No issues found! (ran in 0.9s)
```

## État Git utile

Cette section a été mise à jour après création du rapport, pour refléter l'état final du lot.

### `git status --short`

```text
 M packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
 M packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
 M packages/map_editor/test/list_pokedex_entries_use_case_test.dart
?? packages/map_editor/lib/src/application/models/pokemon_database_index.dart
?? packages/map_editor/lib/src/application/services/pokemon_database_index.dart
?? packages/map_editor/test/pokemon_database_index_test.dart
?? reports/pokemon-database-index-lot-11-report.md
```

### `git diff --stat`

```text
 .../application/ports/pokemon_read_repository.dart | 12 ++++++++
 .../services/pokemon_project_data_reader.dart      | 35 ++++++++++++++++++++++
 .../repositories/file_repositories.dart            | 12 ++++++++
 .../test/list_pokedex_entries_use_case_test.dart   | 32 ++++++++++++++++++++
 4 files changed, 91 insertions(+)
```

### `git ls-files --others --exclude-standard`

```text
packages/map_editor/lib/src/application/models/pokemon_database_index.dart
packages/map_editor/lib/src/application/services/pokemon_database_index.dart
packages/map_editor/test/pokemon_database_index_test.dart
reports/pokemon-database-index-lot-11-report.md
```

### Lecture honnête de l'état Git

Le `git diff --stat` ciblé ne montre pas les nouveaux fichiers non suivis. Il faut donc le lire avec `git ls-files --others --exclude-standard` pour voir les fichiers créés du lot 11.

## Vérifications de périmètre

### `project.json` inchangé

Le test `leaves project.json strictly unchanged` compare le contenu byte-for-byte avant/après construction de l'index. Le lot 11 n'écrit donc pas dans le manifest projet.

### Rien recréé à la racine du monorepo

Le test `does not recreate data or assets at the monorepo root` vérifie que :
- `./data` n'existe pas ;
- `./assets` n'existe pas ;

et la commande `find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print` n'a rien remonté.

## Limites / hors périmètre

Non traité volontairement :
- aucune recherche texte ;
- aucun filtre ;
- aucun tri avancé configurable ;
- aucun cache mémoire ;
- aucun index persistant disque ;
- aucune lecture de learnsets/evolutions/media ;
- aucune UI ;
- aucune validation métier supplémentaire ;
- aucun ajustement des lots suivants.

Point à surveiller plus tard, hors périmètre :
- si une future UI veut un nom principal localisé différemment de la priorité actuelle (`en`, puis `fr`), il faudra formaliser cette règle au niveau produit au lieu de la laisser implicite.

## Bundle de review

### Commande exécutée

```bash
cd /Users/karim/Project/pokemonProject && ./review_bundle.sh
```

### Chemin du fichier généré

```text
.review/review-20260409-234450.txt
```

### Contenu intégral du bundle

```text
# REVIEW BUNDLE

Generated at: 2026-04-09 23:44:50
Repository: pokemonProject
Branch: main
Base ref: HEAD
Head commit: 3296be27a26caf23f307e2b4ee9d5e7ae1b6f7e8

## GIT STATUS --SHORT

 M packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
 M packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
 M packages/map_editor/test/list_pokedex_entries_use_case_test.dart
?? packages/map_editor/lib/src/application/models/pokemon_database_index.dart
?? packages/map_editor/lib/src/application/services/pokemon_database_index.dart
?? packages/map_editor/test/pokemon_database_index_test.dart
?? reports/pokemon-database-index-lot-11-report.md

## GIT DIFF --STAT

 .../application/ports/pokemon_read_repository.dart | 12 ++++++++
 .../services/pokemon_project_data_reader.dart      | 35 ++++++++++++++++++++++
 .../repositories/file_repositories.dart            | 12 ++++++++
 .../test/list_pokedex_entries_use_case_test.dart   | 32 ++++++++++++++++++++
 4 files changed, 91 insertions(+)

## CHANGED FILES

packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
packages/map_editor/test/list_pokedex_entries_use_case_test.dart

## RECENT COMMITS

3296be2 LOT 10 complet: Remove redundant injection of `pokemon` in legacy manifest migration to reduce responsibility duplication and align with existing `ProjectManifest` defaults. Added test to confirm fallback behavior.
5df1f70 LOT 10-a-b:Add lightweight Pokémon config block to project manifest with defaults and targeted tests
ed6ceb1 LOT 9: Introduce `PokemonProjectValidator` for comprehensive Pokémon project validation
318a544 LOT 8: Add `PokemonWriteRepository` with integration tests for local Pokémon data saving
ff4a928 LOT 7: Introduce `PokemonReadRepository` abstraction and add tests
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

## FULL DIFF

diff --git a/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart b/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
index 1b065be..da4640f 100644
--- a/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
+++ b/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
@@ -1,3 +1,4 @@
+import '../models/pokemon_database_index.dart';
 import '../models/pokemon_project_data_models.dart';
 import 'project_workspace.dart';
 
@@ -17,6 +18,17 @@ abstract class PokemonReadRepository {
     ProjectWorkspace workspace,
   );
 
+  /// Construit un index leger oriente liste a partir du dossier species
+  /// configure par le projet.
+  ///
+  /// Cette methode ne charge ni learnsets, ni evolutions, ni media detaille.
+  /// Elle projette seulement les champs minimaux utiles a une future liste
+  /// Pokédex locale.
+  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
+    ProjectWorkspace workspace, {
+    required String speciesDirectoryRelativePath,
+  });
+
   Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace);
 
   Future<PokemonSpeciesFile> readSpeciesByRelativePath(
diff --git a/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart b/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
index 3be1866..ba51885 100644
--- a/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
+++ b/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
@@ -4,6 +4,7 @@ import 'dart:io';
 import 'package:path/path.dart' as p;
 
 import '../errors/application_errors.dart';
+import '../models/pokemon_database_index.dart';
 import '../models/pokemon_project_data_models.dart';
 import '../ports/project_workspace.dart';
 
@@ -119,6 +120,40 @@ class PokemonProjectDataReader {
     return _buildSpeciesIndexEntries(workspace);
   }
 
+  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
+    ProjectWorkspace workspace, {
+    required String speciesDirectoryRelativePath,
+  }) async {
+    final trimmedDirectory = speciesDirectoryRelativePath.trim();
+    if (trimmedDirectory.isEmpty) {
+      throw const EditorValidationException(
+        'Pokemon species directory cannot be empty',
+      );
+    }
+
+    final entries = <PokemonDatabaseIndexEntry>[];
+    for (final relativePath in await _listJsonRelativePaths(
+      workspace,
+      trimmedDirectory,
+      label: 'Pokemon species directory',
+    )) {
+      final json = await _readJsonFile(
+        workspace,
+        relativePath,
+        label: 'Pokemon species index file',
+      );
+      entries.add(PokemonDatabaseIndexEntry.fromSpeciesJson(json));
+    }
+
+    entries.sort((left, right) {
+      final dexCompare = left.nationalDex.compareTo(right.nationalDex);
+      if (dexCompare != 0) return dexCompare;
+      return left.id.compareTo(right.id);
+    });
+
+    return entries;
+  }
+
   Future<PokemonSpeciesFile> readSpeciesByRelativePath(
     ProjectWorkspace workspace,
     String relativePath,
diff --git a/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart b/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
index 6013a8d..3f9c317 100644
--- a/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
+++ b/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
@@ -6,6 +6,7 @@ import 'package:map_core/map_core.dart';
 import 'package:path/path.dart' as p;
 
 import '../../application/errors/application_errors.dart';
+import '../../application/models/pokemon_database_index.dart';
 import '../../application/models/pokemon_project_data_models.dart';
 import '../../application/ports/pokemon_read_repository.dart';
 import '../../application/ports/pokemon_write_repository.dart';
@@ -161,6 +162,17 @@ class FilePokemonReadRepository implements PokemonReadRepository {
     return reader.listSpeciesIndexEntries(workspace);
   }
 
+  @override
+  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
+    ProjectWorkspace workspace, {
+    required String speciesDirectoryRelativePath,
+  }) {
+    return reader.listDatabaseIndexEntries(
+      workspace,
+      speciesDirectoryRelativePath: speciesDirectoryRelativePath,
+    );
+  }
+
   @override
   Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) {
     return reader.listSpeciesFiles(workspace);
diff --git a/packages/map_editor/test/list_pokedex_entries_use_case_test.dart b/packages/map_editor/test/list_pokedex_entries_use_case_test.dart
index 389c6da..44dc085 100644
--- a/packages/map_editor/test/list_pokedex_entries_use_case_test.dart
+++ b/packages/map_editor/test/list_pokedex_entries_use_case_test.dart
@@ -2,6 +2,7 @@ import 'dart:io';
 
 import 'package:flutter_test/flutter_test.dart';
 import 'package:map_editor/src/application/errors/application_errors.dart';
+import 'package:map_editor/src/application/models/pokemon_database_index.dart';
 import 'package:map_editor/src/application/models/pokedex_list_entry.dart';
 import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
 import 'package:map_editor/src/application/ports/pokemon_read_repository.dart';
@@ -269,6 +270,14 @@ class _RecordingPokemonReadRepository implements PokemonReadRepository {
     return indexEntries;
   }
 
+  @override
+  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
+    ProjectWorkspace workspace, {
+    required String speciesDirectoryRelativePath,
+  }) {
+    throw UnimplementedError();
+  }
+
   @override
   Future<PokemonSpeciesFile> readSpeciesById(
     ProjectWorkspace workspace,
@@ -313,6 +322,29 @@ class _RecordingPokemonReadRepository implements PokemonReadRepository {
   Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) {
     throw UnimplementedError();
   }
+
+  @override
+  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) {
+    throw UnimplementedError();
+  }
+
+  @override
+  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) {
+    throw UnimplementedError();
+  }
+
+  @override
+  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) {
+    throw UnimplementedError();
+  }
+
+  @override
+  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
+    ProjectWorkspace workspace,
+    String relativePath,
+  ) {
+    throw UnimplementedError();
+  }
 }
 
 PokemonSpeciesFile _species({
```

## Code intégral produit

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_database_index.dart`

```dart
/// References legeres exposees par l'index local Pokemon.
///
/// On regroupe ici uniquement les refs deja presentes dans le JSON espece.
/// Le but n'est pas d'introduire un nouveau contrat metier ; on fournit juste
/// une forme stable et lisible pour les prochains lots qui voudront afficher
/// une liste d'especes puis ouvrir des details ciblés.
class PokemonDatabaseIndexRefs {
  const PokemonDatabaseIndexRefs({
    required this.learnset,
    required this.evolution,
    required this.spriteSet,
    required this.cry,
  });

  final String learnset;
  final String evolution;
  final String spriteSet;
  final String cry;
}

/// Projection minimale d'une espece pour une future liste Pokédex.
///
/// Cette entree reste volontairement plus petite que `PokemonSpeciesFile` :
/// - pas de stats ;
/// - pas d'abilities ;
/// - pas de learnset charge ;
/// - pas de media detaille charge.
///
/// Le lot 11 ne cherche pas a remplacer les models de lecture existants.
/// Il pose seulement une projection liste, rapide a calculer, stable et
/// suffisamment explicite pour un futur outil no-code.
class PokemonDatabaseIndexEntry {
  const PokemonDatabaseIndexEntry({
    required this.id,
    required this.nationalDex,
    required this.primaryName,
    required this.refs,
  });

  final String id;
  final int nationalDex;
  final String primaryName;
  final PokemonDatabaseIndexRefs refs;

  /// Construit une entree legere directement depuis le JSON espece.
  ///
  /// On lit uniquement les champs utiles a la liste.
  /// Cela evite de materialiser `PokemonSpeciesFile` complet quand on veut juste
  /// construire un index local pour une future UI.
  factory PokemonDatabaseIndexEntry.fromSpeciesJson(Map<String, dynamic> json) {
    final names = _readStringMap(json['names']);
    final id = (json['id'] as String?)?.trim() ?? '';

    return PokemonDatabaseIndexEntry(
      id: id,
      nationalDex: (json['nationalDex'] as num?)?.toInt() ?? 0,
      primaryName: _pickPrimaryName(names) ?? id,
      refs: PokemonDatabaseIndexRefs(
        learnset: (json['learnsetRef'] as String?)?.trim() ?? '',
        evolution: (json['evolutionRef'] as String?)?.trim() ?? '',
        spriteSet: (json['spriteSetRef'] as String?)?.trim() ?? '',
        cry: (json['cryRef'] as String?)?.trim() ?? '',
      ),
    );
  }
}

Map<String, String> _readStringMap(Object? raw) {
  final map = raw as Map?;
  if (map == null) return const <String, String>{};

  final result = <String, String>{};
  for (final entry in map.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is String && value is String) {
      final trimmedKey = key.trim();
      final trimmedValue = value.trim();
      if (trimmedKey.isNotEmpty) {
        result[trimmedKey] = trimmedValue;
      }
    }
  }
  return result;
}

String? _pickPrimaryName(Map<String, String> names) {
  // On reemploie la priorite deja retenue par la couche de lecture locale :
  // `en` puis `fr`, puis toute autre valeur non vide.
  //
  // Le lot 11 ne doit pas introduire une nouvelle regle de nommage qui
  // divergerait de l'existant.
  for (final preferredKey in const <String>['en', 'fr']) {
    final value = names[preferredKey];
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }

  for (final value in names.values) {
    if (value.trim().isNotEmpty) {
      return value.trim();
    }
  }

  return null;
}
```

### Explication

Ce fichier définit la nouvelle projection minimale du lot 11. Il rend explicites les seules informations utiles pour une future liste d'espèces, sans tirer tout le détail métier.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_database_index.dart`

```dart
import '../../domain/repositories/repositories.dart';
import '../errors/application_errors.dart';
import '../models/pokemon_database_index.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/project_workspace.dart';

/// Service applicatif d'indexation locale des espèces Pokémon.
///
/// Rôle exact du lot 11 :
/// - lire la configuration projet Pokemon depuis `project.json` ;
/// - retrouver le dossier `species` declare par le projet ;
/// - demander au repository de lecture une projection legere des especes ;
/// - ne charger ni learnsets, ni evolutions, ni media detaillé.
///
/// Ce service reste volontairement petit et lisible :
/// - pas de cache ;
/// - pas de watcher ;
/// - pas d'UI ;
/// - pas de recherche ;
/// - pas de validation metier avancée.
class PokemonDatabaseIndex {
  const PokemonDatabaseIndex({
    required this.projectRepository,
    required this.pokemonReadRepository,
  });

  final ProjectRepository projectRepository;
  final PokemonReadRepository pokemonReadRepository;

  Future<List<PokemonDatabaseIndexEntry>> build(
    ProjectWorkspace workspace,
  ) async {
    final project = await projectRepository.loadProject(
      workspace.projectManifestPath,
    );

    final speciesDirectory = project.pokemon.speciesDir.trim();
    if (speciesDirectory.isEmpty) {
      throw const EditorValidationException(
        'Project pokemon speciesDir cannot be empty',
      );
    }

    // Le lot 11 reste strict :
    // on se sert uniquement de la config declarative du projet pour localiser
    // les species, puis on demande une projection legere.
    //
    // On ne lit volontairement pas les autres repertoires Pokemon ici.
    return pokemonReadRepository.listDatabaseIndexEntries(
      workspace,
      speciesDirectoryRelativePath: speciesDirectory,
    );
  }
}
```

### Explication

Ce service est l'orchestrateur applicatif du lot. Il lit la config projet et délègue toute la lecture concrète au repository.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`

```dart
import '../models/pokemon_database_index.dart';
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

  /// Construit un index leger oriente liste a partir du dossier species
  /// configure par le projet.
  ///
  /// Cette methode ne charge ni learnsets, ni evolutions, ni media detaille.
  /// Elle projette seulement les champs minimaux utiles a une future liste
  /// Pokédex locale.
  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
    ProjectWorkspace workspace, {
    required String speciesDirectoryRelativePath,
  });

  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace);

  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  );

  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  );

  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace);

  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  );

  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace);

  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  );
}
```

### Explication

Le port est enrichi du minimum nécessaire pour éviter que le nouveau service applicatif dépende du lecteur concret JSON.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
import '../models/pokemon_database_index.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/project_workspace.dart';

/// Lecteur local des donnees Pokemon stockees dans le workspace projet.
///
/// Invariants de cette couche :
/// - toutes les lectures passent par [ProjectWorkspace.projectRoot]
/// - aucun fallback implicite vers `Directory.current`
/// - aucune lecture depuis la racine du monorepo
/// - les erreurs doivent etre explicites pour que les prochains lots UI
///   puissent les afficher proprement
class PokemonProjectDataReader {
  const PokemonProjectDataReader();

  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) async {
    final json = await _readJsonFile(
      workspace,
      'data/pokemon/pokemon_data_manifest.json',
      label: 'Pokemon data manifest',
    );
    return PokemonDataManifest.fromJson(json);
  }

  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) async {
    final manifest = await readManifest(workspace);
    final relativePath = manifest.catalogFiles[catalogKey];
    if (relativePath == null || relativePath.trim().isEmpty) {
      throw EditorNotFoundException(
        'Pokemon catalog not declared in manifest: $catalogKey',
      );
    }
    final json = await _readJsonFile(
      workspace,
      'data/pokemon/$relativePath',
      label: 'Pokemon catalog "$catalogKey"',
    );
    return PokemonCatalogFile.fromJson(json);
  }

  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException('Pokemon species id cannot be empty');
    }

    final speciesPathEntry = await _resolveSpeciesIndexEntryById(workspace, trimmedId);
    final species = await _readSpeciesAtRelativePath(
      workspace,
      speciesPathEntry.relativePath,
    );
    if (species.id != trimmedId) {
      throw EditorPersistenceException(
        'Pokemon species file id mismatch for "$trimmedId": '
        '${speciesPathEntry.relativePath} contains "${species.id}"',
      );
    }
    return species;
  }

  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon learnset id cannot be empty',
      );
    }
    final json = await _readJsonFile(
      workspace,
      'data/pokemon/learnsets/$trimmedId.json',
      label: 'Pokemon learnset "$trimmedId"',
    );
    return PokemonLearnsetFile.fromJson(json);
  }

  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon evolution id cannot be empty',
      );
    }
    final json = await _readJsonFile(
      workspace,
      'data/pokemon/evolutions/$trimmedId.json',
      label: 'Pokemon evolution "$trimmedId"',
    );
    return PokemonEvolutionFile.fromJson(json);
  }

  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) async {
    return _listJsonRelativePaths(
      workspace,
      'data/pokemon/species',
      label: 'Pokemon species directory',
    );
  }

  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) async {
    return _buildSpeciesIndexEntries(workspace);
  }

  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
    ProjectWorkspace workspace, {
    required String speciesDirectoryRelativePath,
  }) async {
    final trimmedDirectory = speciesDirectoryRelativePath.trim();
    if (trimmedDirectory.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species directory cannot be empty',
      );
    }

    final entries = <PokemonDatabaseIndexEntry>[];
    for (final relativePath in await _listJsonRelativePaths(
      workspace,
      trimmedDirectory,
      label: 'Pokemon species directory',
    )) {
      final json = await _readJsonFile(
        workspace,
        relativePath,
        label: 'Pokemon species index file',
      );
      entries.add(PokemonDatabaseIndexEntry.fromSpeciesJson(json));
    }

    entries.sort((left, right) {
      final dexCompare = left.nationalDex.compareTo(right.nationalDex);
      if (dexCompare != 0) return dexCompare;
      return left.id.compareTo(right.id);
    });

    return entries;
  }

  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) {
    return _readSpeciesAtRelativePath(workspace, relativePath);
  }

  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) async {
    return _listJsonFileStemIds(
      workspace,
      'data/pokemon/learnsets',
      label: 'Pokemon learnsets directory',
    );
  }

  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) async {
    return _listJsonFileStemIds(
      workspace,
      'data/pokemon/evolutions',
      label: 'Pokemon evolutions directory',
    );
  }

  Future<String?> resolveSpeciesRelativePathById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException('Pokemon species id cannot be empty');
    }

    final speciesDir = _speciesDirectory(workspace);
    if (!await speciesDir.exists()) {
      return null;
    }

    final normalizedId = _sanitizeSpeciesFileSegment(trimmedId);
    final matches = <String>[];

    await for (final entity in speciesDir.list(recursive: false)) {
      if (entity is! File) continue;
      if (p.extension(entity.path).toLowerCase() != '.json') continue;

      final basename = p.basename(entity.path).toLowerCase();
      if (basename == '$normalizedId.json' ||
          basename.endsWith('-$normalizedId.json')) {
        matches.add(
          p.normalize(p.relative(entity.path, from: workspace.projectRoot)),
        );
      }
    }

    matches.sort();

    if (matches.length > 1) {
      throw EditorConflictException(
        'Multiple Pokemon species files match the id "$trimmedId": '
        '${matches.join(', ')}',
      );
    }

    if (matches.isEmpty) {
      return null;
    }

    return matches.single;
  }

  Future<List<PokemonSpeciesIndexEntry>> _buildSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) async {
    final entries = <PokemonSpeciesIndexEntry>[];
    for (final relativePath in await listSpeciesFiles(workspace)) {
      final json = await _readJsonFile(
        workspace,
        relativePath,
        label: 'Pokemon species index file',
      );
      entries.add(
        PokemonSpeciesIndexEntry.fromJson(
          json,
          relativePath: relativePath,
        ),
      );
    }
    entries.sort((left, right) {
      final dexCompare = left.nationalDex.compareTo(right.nationalDex);
      if (dexCompare != 0) return dexCompare;
      return left.id.compareTo(right.id);
    });
    return entries;
  }

  Future<PokemonSpeciesFile> _readSpeciesAtRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) async {
    final json = await _readJsonFile(
      workspace,
      relativePath,
      label: 'Pokemon species file',
    );
    return PokemonSpeciesFile.fromJson(json);
  }

  Future<PokemonSpeciesIndexEntry> _resolveSpeciesIndexEntryById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final matches = (await _buildSpeciesIndexEntries(workspace))
        .where((entry) => entry.id == speciesId)
        .toList(growable: false);
    if (matches.isEmpty) {
      throw EditorNotFoundException('Pokemon species not found: $speciesId');
    }
    if (matches.length > 1) {
      throw EditorConflictException(
        'Multiple Pokemon species files share the same id "$speciesId": '
        '${matches.map((entry) => entry.relativePath).join(', ')}',
      );
    }
    return matches.single;
  }

  Directory _speciesDirectory(ProjectWorkspace workspace) {
    return Directory(
      workspace.resolveProjectRelativePath('data/pokemon/species'),
    );
  }

  Future<List<String>> _listJsonRelativePaths(
    ProjectWorkspace workspace,
    String relativeDirectory, {
    required String label,
  }) async {
    final directory = Directory(
      workspace.resolveProjectRelativePath(relativeDirectory),
    );
    if (!await directory.exists()) {
      throw EditorNotFoundException('$label not found in project workspace');
    }

    final relativePaths = <String>[];
    await for (final entity in directory.list(recursive: false)) {
      if (entity is! File) continue;
      if (p.extension(entity.path).toLowerCase() != '.json') continue;
      relativePaths.add(
        p.normalize(p.relative(entity.path, from: workspace.projectRoot)),
      );
    }
    relativePaths.sort();
    return relativePaths;
  }

  Future<List<String>> _listJsonFileStemIds(
    ProjectWorkspace workspace,
    String relativeDirectory, {
      required String label,
    }) async {
      final relativePaths = await _listJsonRelativePaths(
        workspace,
        relativeDirectory,
        label: label,
      );
      return relativePaths
          .map((relativePath) => p.basenameWithoutExtension(relativePath))
          .toList(growable: false);
    }

    Future<Map<String, dynamic>> _readJsonFile(
      ProjectWorkspace workspace,
      String relativePath, {
      required String label,
    }) async {
      final filePath = workspace.resolveProjectRelativePath(relativePath);
      final file = File(filePath);
      if (!await file.exists()) {
        throw EditorNotFoundException('$label not found: $relativePath');
      }

      try {
        final content = await file.readAsString();
        final decoded = jsonDecode(content);
        if (decoded is! Map<String, dynamic>) {
          throw EditorPersistenceException(
            '$label must contain a JSON object: $relativePath',
          );
        }
        return decoded;
      } on FormatException catch (error) {
        throw EditorPersistenceException(
          'Invalid JSON in $label "$relativePath": ${error.message}',
        );
      }
    }
  }

  String _sanitizeSpeciesFileSegment(String value) {
    final sanitized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-?$'), '');

    if (sanitized.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species id must contain at least one alphanumeric character',
      );
    }

    return sanitized;
  }
```

### Explication

Le changement important est la nouvelle méthode `listDatabaseIndexEntries(...)`. Le reste du fichier n'a pas été refactoré hors périmètre.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/errors/application_errors.dart';
import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokemon_project_data_models.dart';
import '../../application/ports/pokemon_read_repository.dart';
import '../../application/ports/pokemon_write_repository.dart';
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
  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
    ProjectWorkspace workspace, {
    required String speciesDirectoryRelativePath,
  }) {
    return reader.listDatabaseIndexEntries(
      workspace,
      speciesDirectoryRelativePath: speciesDirectoryRelativePath,
    );
  }

  @override
  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) {
    return reader.listSpeciesFiles(workspace);
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) {
    return reader.readSpeciesByRelativePath(workspace, relativePath);
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
  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) {
    return reader.listLearnsetIds(workspace);
  }

  @override
  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) {
    return reader.readEvolutionById(workspace, speciesId);
  }

  @override
  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) {
    return reader.listEvolutionIds(workspace);
  }
}

/// Implémentation filesystem/workspace de l'écriture locale Pokémon.
///
/// Cette classe écrit uniquement les JSON déjà stabilisés à ce stade :
/// - catalogues globaux
/// - espèces
/// - learnsets
/// - évolutions
///
/// Elle ne touche jamais à `project.json` et n'écrit jamais hors du workspace.
class FilePokemonWriteRepository implements PokemonWriteRepository {
  const FilePokemonWriteRepository({
    this.reader = const PokemonProjectDataReader(),
  });

  /// Le repository d'écriture réutilise le lecteur local existant uniquement
  /// pour résoudre le chemin réel d'une espèce déjà présente.
  ///
  /// Cela évite de dupliquer une logique fragile de lookup par id au moment de
  /// l'écriture, tout en gardant la vérité métier côté JSON.
  final PokemonProjectDataReader reader;

  static const Map<String, String> _catalogRelativePaths = <String, String>{
    'moves': 'data/pokemon/catalogs/moves.json',
    'abilities': 'data/pokemon/catalogs/abilities.json',
    'items': 'data/pokemon/catalogs/items.json',
    'types': 'data/pokemon/catalogs/types.json',
    'growth_rates': 'data/pokemon/catalogs/growth_rates.json',
    'natures': 'data/pokemon/catalogs/natures.json',
    'egg_groups': 'data/pokemon/catalogs/egg_groups.json',
    'habitats': 'data/pokemon/catalogs/habitats.json',
    'generations': 'data/pokemon/catalogs/generations.json',
    'version_groups': 'data/pokemon/catalogs/version_groups.json',
    'encounter_rules': 'data/pokemon/catalogs/encounter_rules.json',
  };

  @override
  Future<void> saveCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
    PokemonCatalogFile catalog,
  ) async {
    final normalizedKey = catalogKey.trim();
    final normalizedCatalog = catalog.catalog.trim();
    if (normalizedKey != normalizedCatalog) {
      throw EditorValidationException(
        'Pokemon catalog key mismatch: requested "$normalizedKey" '
        'but payload is "$normalizedCatalog"',
      );
    }

    final relativePath = _catalogRelativePaths[normalizedKey];
    if (relativePath == null) {
      throw EditorNotFoundException(
        'Pokemon catalog path not configured for "$normalizedKey"',
      );
    }
    await _writeJson(
      workspace,
      relativePath,
      catalog.toJson(),
    );
  }

  @override
  Future<void> saveSpecies(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) async {
    final existingRelativePath = await reader.resolveSpeciesRelativePathById(
      workspace,
      species.id,
    );

    final relativePath =
        existingRelativePath ?? _defaultSpeciesRelativePathFor(species);

    await _writeJson(
      workspace,
      relativePath,
      species.toJson(),
    );
  }

  @override
  Future<void> saveLearnset(
    ProjectWorkspace workspace,
    PokemonLearnsetFile learnset,
  ) {
    return _writeJson(
      workspace,
      'data/pokemon/learnsets/${learnset.speciesId}.json',
      learnset.toJson(),
    );
  }

  @override
  Future<void> saveEvolution(
    ProjectWorkspace workspace,
    PokemonEvolutionFile evolution,
  ) {
    return _writeJson(
      workspace,
      'data/pokemon/evolutions/${evolution.speciesId}.json',
      evolution.toJson(),
    );
  }

  String _defaultSpeciesRelativePathFor(PokemonSpeciesFile species) {
    final fileSafeSegment = _sanitizeSpeciesFileSegment(
      species.slug.trim().isNotEmpty ? species.slug : species.id,
    );
    final dexNumber = species.nationalDex.toString().padLeft(4, '0');
    return 'data/pokemon/species/$dexNumber-$fileSafeSegment.json';
  }

  String _sanitizeSpeciesFileSegment(String value) {
    final sanitized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-?$'), '');

    if (sanitized.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species file segment must contain at least one '
        'alphanumeric character',
      );
    }

    return sanitized;
  }

  Future<void> _writeJson(
    ProjectWorkspace workspace,
    String relativePath,
    Map<String, dynamic> json,
  ) async {
    final path = workspace.resolveProjectRelativePath(relativePath);
    final file = File(path);
    await workspace.ensureDirectoryExists(p.dirname(path));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(json),
    );
  }
}
```

### Explication

Le seul changement utile pour le lot 11 dans ce fichier est l'implémentation du nouveau point d'entrée de lecture. Le reste du fichier est recopié ici parce que le rapport doit montrer le code complet du fichier modifié.

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_database_index_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/services/pokemon_database_index.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late String repoRootPath;
  late ProjectFileSystem workspace;
  late FileProjectRepository projectRepository;
  late FilePokemonReadRepository pokemonReadRepository;
  late PokemonDatabaseIndex indexService;
  late CreateProjectUseCase createProjectUseCase;
  late SeedPokemonDemoDataUseCase seedUseCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokemon_index_');
    repoRootPath = _resolveRepositoryRootFromCurrentDirectory();
    workspace = ProjectFileSystem(tempProjectRoot.path);
    projectRepository = FileProjectRepository();
    pokemonReadRepository = const FilePokemonReadRepository();
    indexService = PokemonDatabaseIndex(
      projectRepository: projectRepository,
      pokemonReadRepository: pokemonReadRepository,
    );
    createProjectUseCase = CreateProjectUseCase(
      projectRepository,
      const FileProjectWorkspaceFactory(),
    );
    seedUseCase = const SeedPokemonDemoDataUseCase();
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('PokemonDatabaseIndex', () {
    test('indexes seeded species with the minimal list projection', () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      final entries = await indexService.build(workspace);

      expect(entries, hasLength(2));

      final bulbasaur = entries.firstWhere((entry) => entry.id == 'bulbasaur');
      expect(bulbasaur.nationalDex, 1);
      expect(bulbasaur.primaryName, 'Bulbasaur');
      expect(
        bulbasaur.refs,
        isA<PokemonDatabaseIndexRefs>()
            .having((refs) => refs.learnset, 'learnset', 'bulbasaur')
            .having((refs) => refs.evolution, 'evolution', 'bulbasaur')
            .having((refs) => refs.spriteSet, 'spriteSet', 'bulbasaur')
            .having((refs) => refs.cry, 'cry', 'bulbasaur'),
      );
    });

    test('uses the project pokemon speciesDir instead of a hardcoded path',
        () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      final originalManifest = await projectRepository.loadProject(
        workspace.projectManifestPath,
      );
      const customSpeciesDir = 'data/pokemon/custom_species';

      // On deplace seulement les species pour prouver que le service lit la
      // config projet, pas le chemin historique hardcode de la couche legacy.
      final originalSpeciesDir = Directory(
        workspace.resolveProjectRelativePath(originalManifest.pokemon.speciesDir),
      );
      final targetSpeciesDir = Directory(
        workspace.resolveProjectRelativePath(customSpeciesDir),
      );
      await targetSpeciesDir.create(recursive: true);

      await for (final entity in originalSpeciesDir.list(recursive: false)) {
        if (entity is File) {
          await entity.rename(p.join(targetSpeciesDir.path, p.basename(entity.path)));
        }
      }

      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-decoy.json',
        ),
      ).create(recursive: true);
      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-decoy.json',
        ),
      ).writeAsString('''
{
  "id": "decoy",
  "nationalDex": 9999,
  "names": {
    "en": "Decoy"
  },
  "learnsetRef": "decoy",
  "evolutionRef": "decoy",
  "spriteSetRef": "decoy",
  "cryRef": "decoy"
}
''');

      final updatedManifest = originalManifest.copyWith(
        pokemon: originalManifest.pokemon.copyWith(
          speciesDir: customSpeciesDir,
        ),
      );
      await projectRepository.saveProject(
        updatedManifest,
        workspace.projectManifestPath,
      );

      final entries = await indexService.build(workspace);

      expect(entries.map((entry) => entry.id), containsAll(<String>[
        'bulbasaur',
        'ivysaur',
      ]));
      expect(entries.map((entry) => entry.id), isNot(contains('decoy')));
    });

    test('returns an empty index when the configured species directory is empty',
        () async {
      await createProjectUseCase.execute(
        'Pokemon Empty Index Project',
        tempProjectRoot.path,
      );

      final manifest = await projectRepository.loadProject(
        workspace.projectManifestPath,
      );
      const customSpeciesDir = 'data/pokemon/empty_species';
      await Directory(
        workspace.resolveProjectRelativePath(customSpeciesDir),
      ).create(recursive: true);
      await projectRepository.saveProject(
        manifest.copyWith(
          pokemon: manifest.pokemon.copyWith(speciesDir: customSpeciesDir),
        ),
        workspace.projectManifestPath,
      );

      final entries = await indexService.build(workspace);

      expect(entries, isEmpty);
    });

    test('fails explicitly when a species json file is invalid', () async {
      await createProjectUseCase.execute(
        'Pokemon Invalid Species Index Project',
        tempProjectRoot.path,
      );

      final invalidSpeciesDir = Directory(
        workspace.resolveProjectRelativePath('data/pokemon/species'),
      );
      await invalidSpeciesDir.create(recursive: true);
      await File(
        p.join(invalidSpeciesDir.path, '0001-bulbasaur.json'),
      ).writeAsString('{ invalid json');

      expect(
        () => indexService.build(workspace),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
    });

    test('does not load learnsets evolutions or media during indexing',
        () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/learnsets/bulbasaur.json',
        ),
      ).writeAsString('{ invalid json');
      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/evolutions/bulbasaur.json',
        ),
      ).writeAsString('{ invalid json');

      await Directory(
        workspace.resolveProjectRelativePath('data/pokemon/media'),
      ).create(recursive: true);
      await File(
        workspace.resolveProjectRelativePath('data/pokemon/media/bulbasaur.json'),
      ).writeAsString('{ invalid json');

      final entries = await indexService.build(workspace);

      expect(entries.map((entry) => entry.id), contains('bulbasaur'));
      expect(entries.map((entry) => entry.id), contains('ivysaur'));
    });

    test('reads from the workspace project and not Directory.current', () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      final decoy = await Directory.systemTemp.createTemp('pokemon_index_decoy_');
      final originalCurrent = Directory.current;
      try {
        await Directory(
          p.join(decoy.path, 'data', 'pokemon', 'species'),
        ).create(recursive: true);
        await File(
          p.join(decoy.path, 'data', 'pokemon', 'species', '9999-decoy.json'),
        ).writeAsString('''
{
  "id": "decoy",
  "nationalDex": 9999,
  "names": {
    "en": "Decoy"
  },
  "learnsetRef": "decoy",
  "evolutionRef": "decoy",
  "spriteSetRef": "decoy",
  "cryRef": "decoy"
}
''');

        Directory.current = decoy.path;

        final entries = await indexService.build(workspace);

        expect(entries.any((entry) => entry.id == 'decoy'), isFalse);
        expect(entries.any((entry) => entry.id == 'bulbasaur'), isTrue);
      } finally {
        Directory.current = originalCurrent.path;
        if (await decoy.exists()) {
          await decoy.delete(recursive: true);
        }
      }
    });

    test('leaves project.json strictly unchanged', () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await indexService.build(workspace);

      final after = await projectFile.readAsString();
      expect(after, before);
    });

    test('does not recreate data or assets at the monorepo root', () async {
      await _createProjectAndSeedDemoData(
        createProjectUseCase,
        seedUseCase,
        workspace,
        tempProjectRoot.path,
      );

      await indexService.build(workspace);

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

Future<void> _createProjectAndSeedDemoData(
  CreateProjectUseCase createProjectUseCase,
  SeedPokemonDemoDataUseCase seedUseCase,
  ProjectFileSystem workspace,
  String projectRootPath,
) async {
  await createProjectUseCase.execute(
    'Pokemon Database Index Project',
    projectRootPath,
  );
  await seedUseCase.execute(workspace);
}
```

### Explication

Ce fichier prouve le comportement réel attendu du lot 11. Il couvre le nominal, le strict minimum des champs, les limites de périmètre et la robustesse de l'ancrage workspace.

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/list_pokedex_entries_use_case_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
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
  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
    ProjectWorkspace workspace, {
    required String speciesDirectoryRelativePath,
  }) {
    throw UnimplementedError();
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

  @override
  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) {
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

### Explication

Ce fichier n'a pas été étendu fonctionnellement. Il a seulement été ajusté pour satisfaire l'interface de lecture enrichie sans casser les tests existants du lot 6.

## Conclusion honnête

Le lot 11 reste volontairement petit :
- on indexe les espèces locales ;
- on expose seulement l'identité minimale utile à une future liste ;
- on s'appuie proprement sur la config projet et sur les repositories déjà présents ;
- on ne touche ni aux détails métier complets, ni à l'UI, ni au runtime.

La base est maintenant plus saine pour les prochains lots Pokédex parce qu'on dispose d'une vraie projection légère explicite, construite depuis les données locales du projet, sans charger learnsets/evolutions/media.
