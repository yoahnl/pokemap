# Rapport — Lot 11b mini-fix — Nettoyage de `PokemonDatabaseIndex`

## Résumé exécutif

Le lot 11 initial était bon sur le périmètre produit, mais il avait une dette de conception réelle :
- l'index local reparsait les JSON espèces avec une factory dédiée permissive ;
- il redéfinissait localement la logique de `primaryName` ;
- il pouvait construire des entrées d'index silencieusement bancales à partir d'une espèce syntaxiquement parseable mais structurellement inutilisable.

Ce mini-fix corrige précisément ce point, sans élargir le scope :
- suppression du mini parsing parallèle du JSON pour l'index ;
- réalignement sur des modèles existants déjà présents dans le projet ;
- échec explicite si les champs minimaux exigés par l'index ne sont pas exploitables ;
- aucun changement UI/runtime/import/project config.

## Problème exact corrigé

Le défaut principal du lot 11 était dans cette chaîne :

1. `PokemonProjectDataReader.listDatabaseIndexEntries(...)` lisait chaque fichier JSON brut ;
2. `PokemonDatabaseIndexEntry.fromSpeciesJson(...)` reparsait localement les champs minimaux ;
3. cette factory redéfinissait sa propre logique de `primaryName` ;
4. elle était permissive sur :
   - `id`
   - `nationalDex`
   - `primaryName`
   - `refs`

Conséquence :
- l'index n'était pas aligné sur une source de vérité unique ;
- on entretenait une deuxième interprétation du JSON espèce ;
- une espèce syntaxiquement valide mais incomplète pouvait produire une entrée d'index vide ou dégradée au lieu d'échouer explicitement.

## Audit rapide de l'existant

### Source de vérité candidates

J'ai vérifié les briques déjà présentes :

- `PokemonSpeciesFile`
  - modèle détaillé existant ;
  - parse le JSON espèce complet ;
  - expose les refs nécessaires (`learnsetRef`, `evolutionRef`, `spriteSetRef`, `cryRef`).

- `PokemonSpeciesIndexEntry`
  - projection légère déjà existante ;
  - expose déjà :
    - `id`
    - `nationalDex`
    - `primaryName`
    - `types`
    - `relativePath`

### Source de vérité retenue

La meilleure base pour ce mini-fix est :
- `PokemonSpeciesIndexEntry` pour :
  - `id`
  - `nationalDex`
  - `primaryName`
- `PokemonSpeciesFile` pour les `refs`

Pourquoi ce choix est le bon :

1. `PokemonSpeciesIndexEntry` porte déjà l'intention "projection légère d'espèce".
2. Il est plus cohérent de réutiliser cette projection existante que de recoder une deuxième mini-projection parallèle.
3. `PokemonDatabaseIndexEntry` a encore une vraie valeur spécifique au lot 11, car il expose des `refs` que `PokemonSpeciesIndexEntry` n'a pas.
4. `PokemonSpeciesFile` reste nécessaire pour les refs, mais on n'a pas besoin de lui faire porter seul la logique de vue légère.

### Pourquoi l'ancienne solution était mauvaise

`PokemonDatabaseIndexEntry.fromSpeciesJson(...)` dupliquait une responsabilité déjà couverte ailleurs :
- elle reparse le JSON espèce ;
- elle recalculait `primaryName` ;
- elle rejouait un sous-contrat implicite du modèle espèce.

Même si la duplication était petite, elle était suffisamment réelle pour devenir une source de divergence future.

## Décisions d'architecture

### Décision 1

`PokemonDatabaseIndexEntry` est conservé.

Pourquoi :
- il porte encore une valeur spécifique au lot 11 ;
- il représente la projection "future liste Pokédex locale" ;
- il ajoute `refs` par rapport à `PokemonSpeciesIndexEntry`.

### Décision 2

`PokemonDatabaseIndexEntry` n'analyse plus le JSON brut.

Nouveau principe :
- `PokemonSpeciesFile` parse le JSON ;
- `PokemonSpeciesIndexEntry` construit la projection légère existante ;
- `PokemonDatabaseIndexEntry` assemble sa vue à partir de ces modèles déjà construits.

### Décision 3

`PokemonSpeciesIndexEntry.fromJson(...)` délègue désormais à `PokemonSpeciesFile.fromJson(...)`, puis à `PokemonSpeciesIndexEntry.fromSpeciesFile(...)`.

But :
- retirer une duplication interne dans la projection légère existante ;
- centraliser la logique de projection légère sur une espèce déjà parsée.

### Décision 4

L'index local valide explicitement son contrat minimal.

Ce mini-fix ne remplace pas le validateur Pokémon global du lot 9. Il ajoute seulement la protection minimale nécessaire au lot 11 :
- `id` non vide ;
- `nationalDex > 0` ;
- `primaryName` exploitable ;
- refs non vides :
  - `learnsetRef`
  - `evolutionRef`
  - `spriteSetRef`
  - `cryRef`

Si l'un de ces points est cassé :
- on lève une `EditorPersistenceException`
- on n'invente pas d'entrée d'index dégradée.

## Périmètre inclus

Ce mini-fix inclut uniquement :
- le réalignement de l'indexation locale sur une source de vérité existante ;
- la suppression de la factory de parsing JSON parallèle ;
- l'ajout d'un échec explicite pour les espèces structurellement invalides dans le cadre du lot 11 ;
- l'adaptation minimale des tests.

## Périmètre exclu

Je n'ai volontairement pas touché :
- l'UI ;
- les providers Riverpod ;
- le runtime ;
- les imports externes ;
- la validation Pokémon globale du lot 9 ;
- la config projet Pokémon ;
- `project.json` ;
- learnsets/evolutions/media pendant l'indexation ;
- la recherche ;
- le tri avancé ;
- le cache ;
- l'index persistant disque ;
- les lots 12 et suivants ;
- les autres changements déjà présents dans le working tree avant cette intervention.

## Liste exacte des fichiers modifiés dans ce mini-fix

Fichiers modifiés manuellement :
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_database_index.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_database_index_test.dart`

Nouveau rapport créé :
- `/Users/karim/Project/pokemonProject/reports/pokemon-database-index-lot-11b-mini-fix-report.md`

## Fichiers volontairement non touchés

Bien qu'ils apparaissent déjà modifiés/non suivis dans le working tree global, je ne les ai pas retouchés dans ce mini-fix :
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_database_index.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/list_pokedex_entries_use_case_test.dart`
- `/Users/karim/Project/pokemonProject/reports/pokemon-database-index-lot-11-report.md`

## Justification fichier par fichier

### `pokemon_project_data_models.dart`

Changement utile :
- ajout de `PokemonSpeciesIndexEntry.fromSpeciesFile(...)`
- `PokemonSpeciesIndexEntry.fromJson(...)` délègue maintenant à `PokemonSpeciesFile.fromJson(...)`

Pourquoi :
- supprimer une duplication locale de projection légère ;
- faire reposer `PokemonSpeciesIndexEntry` sur une espèce déjà parsée.

### `pokemon_database_index.dart`

Changement utile :
- suppression de `fromSpeciesJson(...)`
- remplacement par `fromSpeciesEntry(...)`

Pourquoi :
- l'index du lot 11 ne doit plus parser le JSON ;
- il doit assembler une projection à partir de briques déjà cohérentes.

### `pokemon_project_data_reader.dart`

Changement utile :
- `listDatabaseIndexEntries(...)` parse désormais l'espèce une seule fois via `PokemonSpeciesFile`
- construit ensuite `PokemonSpeciesIndexEntry`
- valide le contrat minimal du lot 11
- assemble `PokemonDatabaseIndexEntry`

Pourquoi :
- supprimer le parser permissif parallèle ;
- faire échouer explicitement l'index si le contrat minimal n'est pas satisfaisant.

### `pokemon_database_index_test.dart`

Changements utiles :
- le test nominal vérifie maintenant explicitement l'alignement entre l'index du lot 11 et `listSpeciesIndexEntries(...)`
- ajout d'un test pour une espèce syntaxiquement valide mais structurellement invalide

Pourquoi :
- verrouiller la suppression de la logique parallèle ;
- verrouiller l'échec explicite sur données minimales invalides.

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
  lib/src/application/models/pokemon_project_data_models.dart \
  lib/src/application/models/pokemon_database_index.dart \
  lib/src/application/services/pokemon_database_index.dart \
  lib/src/application/services/pokemon_project_data_reader.dart \
  lib/src/application/ports/pokemon_read_repository.dart \
  lib/src/infrastructure/repositories/file_repositories.dart \
  test/pokemon_database_index_test.dart \
  test/list_pokedex_entries_use_case_test.dart \
  test/file_pokemon_read_repository_test.dart
```

### Vérifications de périmètre

```bash
cd /Users/karim/Project/pokemonProject && git status --short
cd /Users/karim/Project/pokemonProject && git diff --stat -- \
  packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart \
  packages/map_editor/lib/src/application/models/pokemon_database_index.dart \
  packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart \
  packages/map_editor/test/pokemon_database_index_test.dart \
  reports/pokemon-database-index-lot-11b-mini-fix-report.md
cd /Users/karim/Project/pokemonProject && git ls-files --others --exclude-standard \
  packages/map_editor/lib/src/application/models/pokemon_database_index.dart \
  packages/map_editor/test/pokemon_database_index_test.dart \
  reports/pokemon-database-index-lot-11b-mini-fix-report.md
cd /Users/karim/Project/pokemonProject && find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
cd /Users/karim/Project/pokemonProject && ./review_bundle.sh
```

## Résultats réels des commandes

### Résultats des tests

`flutter test test/pokemon_database_index_test.dart`

```text
00:01 +9: All tests passed!
```

`flutter test test/list_pokedex_entries_use_case_test.dart`

```text
00:01 +6: All tests passed!
```

`flutter test test/file_pokemon_read_repository_test.dart`

```text
00:01 +6: All tests passed!
```

### Résultat réel de l'analyse

```text
No issues found! (ran in 3.5s)
```

## Vérifications de périmètre

### `project.json`

Le test `leaves project.json strictly unchanged` continue de passer. Le mini-fix ne modifie pas le manifest projet.

### Racine du monorepo

La commande :

```bash
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
```

n'a rien retourné. Rien n'a été recréé à la racine du monorepo.

### Learnsets / évolutions / media

Le test `does not load learnsets evolutions or media during indexing` continue de passer avec des fichiers volontairement invalides dans ces répertoires. Le mini-fix n'a donc pas élargi le scope de l'indexation.

## État Git utile

### `git status --short`

```text
 M packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
 M packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
 M packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
 M packages/map_editor/test/list_pokedex_entries_use_case_test.dart
?? packages/map_editor/lib/src/application/models/pokemon_database_index.dart
?? packages/map_editor/lib/src/application/services/pokemon_database_index.dart
?? packages/map_editor/test/pokemon_database_index_test.dart
?? reports/pokemon-database-index-lot-11-report.md
?? reports/pokemon-database-index-lot-11b-mini-fix-report.md
```

### `git diff --stat` ciblé sur ce mini-fix

```text
 .../models/pokemon_project_data_models.dart        |  32 ++++--
 .../services/pokemon_project_data_reader.dart      | 125 +++++++++++++++++++--
 2 files changed, 142 insertions(+), 15 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
packages/map_editor/lib/src/application/models/pokemon_database_index.dart
packages/map_editor/test/pokemon_database_index_test.dart
reports/pokemon-database-index-lot-11b-mini-fix-report.md
```

### Lecture honnête de l'état Git

Le working tree contient encore des changements plus anciens liés au lot 11 initial :
- `pokemon_read_repository.dart`
- `file_repositories.dart`
- `list_pokedex_entries_use_case_test.dart`
- `pokemon_database_index.dart`
- `pokemon_database_index_test.dart`
- `pokemon_database_index.dart`
- `pokemon_database_index_test.dart`
- le rapport initial du lot 11

Je ne les ai pas tous modifiés dans ce mini-fix. Le `git status --short` les montre donc encore, mais ce n'est pas la preuve qu'ils appartiennent tous à cette intervention.

Autre point honnête :
- le `git diff --stat` ciblé ne montre pas les fichiers non suivis ;
- il faut le lire avec `git ls-files --others --exclude-standard` pour voir `pokemon_database_index.dart`, `pokemon_database_index_test.dart` et ce nouveau rapport.

## Bundle de review

### Commande

```bash
cd /Users/karim/Project/pokemonProject && ./review_bundle.sh
```

### Chemin du bundle

```text
.review/review-20260410-104911.txt
```

### Contenu intégral du bundle

```text
# REVIEW BUNDLE

Generated at: 2026-04-10 10:49:11
Repository: pokemonProject
Branch: main
Base ref: HEAD
Head commit: 3296be27a26caf23f307e2b4ee9d5e7ae1b6f7e8

## GIT STATUS --SHORT

 M packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
 M packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
 M packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
 M packages/map_editor/test/list_pokedex_entries_use_case_test.dart
?? packages/map_editor/lib/src/application/models/pokemon_database_index.dart
?? packages/map_editor/lib/src/application/services/pokemon_database_index.dart
?? packages/map_editor/test/pokemon_database_index_test.dart
?? reports/pokemon-database-index-lot-11-report.md
?? reports/pokemon-database-index-lot-11b-mini-fix-report.md

## GIT DIFF --STAT

 .../models/pokemon_project_data_models.dart        |  32 ++++--
 .../application/ports/pokemon_read_repository.dart |  12 ++
 .../services/pokemon_project_data_reader.dart      | 125 +++++++++++++++++++--
 .../repositories/file_repositories.dart            |  12 ++
 .../test/list_pokedex_entries_use_case_test.dart   |  32 ++++++
 5 files changed, 198 insertions(+), 15 deletions(-)

## CHANGED FILES

packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
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

diff --git a/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart b/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
index 283aca0..3d4ad76 100644
--- a/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
+++ b/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
@@ -146,15 +146,31 @@ class PokemonSpeciesIndexEntry {
     Map<String, dynamic> json, {
     required String relativePath,
   }) {
-    final names = _readStringMap(json['names']);
+    // Cette factory legacy reste disponible pour les call sites qui ont
+    // encore du JSON brut, mais elle délègue désormais au vrai modèle espèce.
+    //
+    // On évite ainsi d'entretenir deux projections concurrentes du même JSON :
+    // la version détaillée `PokemonSpeciesFile` reste la source de vérité.
+    return PokemonSpeciesIndexEntry.fromSpeciesFile(
+      PokemonSpeciesFile.fromJson(json),
+      relativePath: relativePath,
+    );
+  }
+
+  /// Construit la projection légère à partir d'une espèce déjà parsée.
+  ///
+  /// Le but est de centraliser la logique de projection liste sur une source
+  /// de vérité unique, plutôt que de reparser le JSON dans plusieurs modèles.
+  factory PokemonSpeciesIndexEntry.fromSpeciesFile(
+    PokemonSpeciesFile species, {
+    required String relativePath,
+  }) {
     return PokemonSpeciesIndexEntry(
-      id: (json['id'] as String?)?.trim() ?? '',
-      nationalDex: (json['nationalDex'] as num?)?.toInt() ?? 0,
-      primaryName: _pickPrimaryName(names) ?? (json['id'] as String?)?.trim() ?? '',
-      types: PokemonSpeciesTyping.fromJson(
-        (json['typing'] as Map?)?.cast<String, dynamic>() ??
-            const <String, dynamic>{},
-      ).types,
+      id: species.id.trim(),
+      nationalDex: species.nationalDex,
+      primaryName:
+          _pickPrimaryName(species.names) ?? species.id.trim(),
+      types: List<String>.from(species.typing.types),
       relativePath: relativePath,
     );
   }
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
index 3be1866..bc89ef9 100644
--- a/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
+++ b/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
@@ -4,6 +4,7 @@ import 'dart:io';
 import 'package:path/path.dart' as p;
 
 import '../errors/application_errors.dart';
+import '../models/pokemon_database_index.dart';
 import '../models/pokemon_project_data_models.dart';
 import '../ports/project_workspace.dart';
 
@@ -119,6 +120,58 @@ class PokemonProjectDataReader {
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
+      final species = await _readSpeciesAtRelativePath(
+        workspace,
+        relativePath,
+      );
+      final speciesIndexEntry = PokemonSpeciesIndexEntry.fromSpeciesFile(
+        species,
+        relativePath: relativePath,
+      );
+
+      // Le lot 11 ne doit plus accepter silencieusement une espèce parseable
+      // mais inutilisable pour la future liste. On vérifie donc ici le contrat
+      // minimal exact de l'index local.
+      _validateSpeciesForDatabaseIndex(
+        species: species,
+        speciesIndexEntry: speciesIndexEntry,
+        relativePath: relativePath,
+      );
+
+      entries.add(
+        PokemonDatabaseIndexEntry.fromSpeciesEntry(
+          speciesIndexEntry: speciesIndexEntry,
+          species: species,
+        ),
+      );
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
@@ -193,14 +246,10 @@ class PokemonProjectDataReader {
   ) async {
     final entries = <PokemonSpeciesIndexEntry>[];
     for (final relativePath in await listSpeciesFiles(workspace)) {
-      final json = await _readJsonFile(
-        workspace,
-        relativePath,
-        label: 'Pokemon species index file',
-      );
+      final species = await _readSpeciesAtRelativePath(workspace, relativePath);
       entries.add(
-        PokemonSpeciesIndexEntry.fromJson(
-          json,
+        PokemonSpeciesIndexEntry.fromSpeciesFile(
+          species,
           relativePath: relativePath,
         ),
       );
@@ -225,6 +274,68 @@ class PokemonProjectDataReader {
     return PokemonSpeciesFile.fromJson(json);
   }
 
+  void _validateSpeciesForDatabaseIndex({
+    required PokemonSpeciesFile species,
+    required PokemonSpeciesIndexEntry speciesIndexEntry,
+    required String relativePath,
+  }) {
+    // Cette validation reste volontairement petite. Elle ne remplace pas le
+    // validateur Pokémon global : elle protège seulement le contrat minimal
+    // exigé par l'index local du lot 11.
+    if (speciesIndexEntry.id.trim().isEmpty) {
+      throw EditorPersistenceException(
+        'Pokemon species index file must define a non-empty id: $relativePath',
+      );
+    }
+
+    if (speciesIndexEntry.nationalDex <= 0) {
+      throw EditorPersistenceException(
+        'Pokemon species index file must define nationalDex > 0: $relativePath',
+      );
+    }
+
+    if (speciesIndexEntry.primaryName.trim().isEmpty) {
+      throw EditorPersistenceException(
+        'Pokemon species index file must define an exploitable primary name: '
+        '$relativePath',
+      );
+    }
+
+    _validateDatabaseIndexRef(
+      value: species.learnsetRef,
+      refName: 'learnsetRef',
+      relativePath: relativePath,
+    );
+    _validateDatabaseIndexRef(
+      value: species.evolutionRef,
+      refName: 'evolutionRef',
+      relativePath: relativePath,
+    );
+    _validateDatabaseIndexRef(
+      value: species.spriteSetRef,
+      refName: 'spriteSetRef',
+      relativePath: relativePath,
+    );
+    _validateDatabaseIndexRef(
+      value: species.cryRef,
+      refName: 'cryRef',
+      relativePath: relativePath,
+    );
+  }
+
+  void _validateDatabaseIndexRef({
+    required String value,
+    required String refName,
+    required String relativePath,
+  }) {
+    if (value.trim().isEmpty) {
+      throw EditorPersistenceException(
+        'Pokemon species index file must define a non-empty $refName: '
+        '$relativePath',
+      );
+    }
+  }
+
   Future<PokemonSpeciesIndexEntry> _resolveSpeciesIndexEntryById(
     ProjectWorkspace workspace,
     String speciesId,
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

## Hors périmètre / non traité

Je n'ai pas traité, volontairement :
- le fait que `PokemonSpeciesFile.fromJson(...)` reste globalement permissif sur bien d'autres champs du contrat espèce ;
- l'éventuelle convergence future entre le validateur du lot 9 et les validations minimales spécifiques au lot 11 ;
- l'ajout d'un vrai modèle de vue Pokédex plus riche ;
- l'optimisation mémoire ou performance plus poussée ;
- toute logique de recherche.

## Code intégral des fichiers modifiés

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`

```dart
/// Metadonnees communes des JSON Pokemon locaux.
///
/// On garde ce modele volontairement petit : il capture seulement les champs
/// reels deja presents dans le manifeste et les catalogues seeds jusqu'ici.
class PokemonDataMeta {
  const PokemonDataMeta({
    required this.description,
    this.sourcePriority = const <String>[],
    this.notes = const <String>[],
  });

  final String description;
  final List<String> sourcePriority;
  final List<String> notes;

  factory PokemonDataMeta.fromJson(Map<String, dynamic> json) {
    return PokemonDataMeta(
      description: (json['description'] as String?)?.trim() ?? '',
      sourcePriority: _readStringList(json['sourcePriority']),
      notes: _readStringList(json['notes']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'description': description,
      'sourcePriority': List<String>.from(sourcePriority),
      'notes': List<String>.from(notes),
    };
  }
}

class PokemonDataManifest {
  const PokemonDataManifest({
    required this.schemaVersion,
    required this.kind,
    required this.meta,
    required this.catalogFiles,
    required this.futureDataFolders,
  });

  final int schemaVersion;
  final String kind;
  final PokemonDataMeta meta;
  final Map<String, String> catalogFiles;
  final Map<String, String> futureDataFolders;

  factory PokemonDataManifest.fromJson(Map<String, dynamic> json) {
    return PokemonDataManifest(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 0,
      kind: (json['kind'] as String?)?.trim() ?? '',
      meta: PokemonDataMeta.fromJson(
        (json['meta'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      catalogFiles: _readStringMap(json['catalogFiles']),
      futureDataFolders: _readStringMap(json['futureDataFolders']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'kind': kind,
      'meta': meta.toJson(),
      'catalogFiles': Map<String, String>.from(catalogFiles),
      'futureDataFolders': Map<String, String>.from(futureDataFolders),
    };
  }
}

/// Catalogue Pokemon generique.
///
/// On garde `entries` en JSON brut pour ce lot afin d'eviter de sur-typer
/// prematurement tous les referentiels globaux. Les lots suivants pourront
/// specialiser certains catalogues si cela apporte une vraie valeur.
class PokemonCatalogFile {
  const PokemonCatalogFile({
    required this.schemaVersion,
    required this.kind,
    required this.catalog,
    required this.meta,
    required this.entries,
  });

  final int schemaVersion;
  final String kind;
  final String catalog;
  final PokemonDataMeta meta;
  final List<Map<String, dynamic>> entries;

  factory PokemonCatalogFile.fromJson(Map<String, dynamic> json) {
    final rawEntries = (json['entries'] as List?) ?? const <Object?>[];
    return PokemonCatalogFile(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 0,
      kind: (json['kind'] as String?)?.trim() ?? '',
      catalog: (json['catalog'] as String?)?.trim() ?? '',
      meta: PokemonDataMeta.fromJson(
        (json['meta'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      entries: rawEntries
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList(growable: false),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'kind': kind,
      'catalog': catalog,
      'meta': meta.toJson(),
      'entries': entries
          .map((entry) => _deepCopyJsonMap(entry))
          .toList(growable: false),
    };
  }
}

/// Projection legere d'une espece pour les futurs usages liste/index.
///
/// Cette entree est volontairement beaucoup plus petite que [PokemonSpeciesFile].
/// Elle suffit pour :
/// - lister les Pokemon disponibles ;
/// - afficher un nom et des types ;
/// - resoudre ensuite le chemin detail sans reparcourir naivement tout le
///   dossier pour chaque lecture.
class PokemonSpeciesIndexEntry {
  const PokemonSpeciesIndexEntry({
    required this.id,
    required this.nationalDex,
    required this.primaryName,
    required this.types,
    required this.relativePath,
  });

  final String id;
  final int nationalDex;
  final String primaryName;
  final List<String> types;
  final String relativePath;

  factory PokemonSpeciesIndexEntry.fromJson(
    Map<String, dynamic> json, {
    required String relativePath,
  }) {
    // Cette factory legacy reste disponible pour les call sites qui ont
    // encore du JSON brut, mais elle délègue désormais au vrai modèle espèce.
    //
    // On évite ainsi d'entretenir deux projections concurrentes du même JSON :
    // la version détaillée `PokemonSpeciesFile` reste la source de vérité.
    return PokemonSpeciesIndexEntry.fromSpeciesFile(
      PokemonSpeciesFile.fromJson(json),
      relativePath: relativePath,
    );
  }

  /// Construit la projection légère à partir d'une espèce déjà parsée.
  ///
  /// Le but est de centraliser la logique de projection liste sur une source
  /// de vérité unique, plutôt que de reparser le JSON dans plusieurs modèles.
  factory PokemonSpeciesIndexEntry.fromSpeciesFile(
    PokemonSpeciesFile species, {
    required String relativePath,
  }) {
    return PokemonSpeciesIndexEntry(
      id: species.id.trim(),
      nationalDex: species.nationalDex,
      primaryName:
          _pickPrimaryName(species.names) ?? species.id.trim(),
      types: List<String>.from(species.typing.types),
      relativePath: relativePath,
    );
  }
}

class PokemonSpeciesTyping {
  const PokemonSpeciesTyping({
    this.types = const <String>[],
  });

  final List<String> types;

  factory PokemonSpeciesTyping.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesTyping(types: _readStringList(json['types']));
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'types': List<String>.from(types),
    };
  }
}

class PokemonSpeciesBaseStats {
  const PokemonSpeciesBaseStats({
    required this.hp,
    required this.atk,
    required this.def,
    required this.spa,
    required this.spd,
    required this.spe,
    required this.bst,
  });

  final int hp;
  final int atk;
  final int def;
  final int spa;
  final int spd;
  final int spe;
  final int bst;

  factory PokemonSpeciesBaseStats.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesBaseStats(
      hp: (json['hp'] as num?)?.toInt() ?? 0,
      atk: (json['atk'] as num?)?.toInt() ?? 0,
      def: (json['def'] as num?)?.toInt() ?? 0,
      spa: (json['spa'] as num?)?.toInt() ?? 0,
      spd: (json['spd'] as num?)?.toInt() ?? 0,
      spe: (json['spe'] as num?)?.toInt() ?? 0,
      bst: (json['bst'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'hp': hp,
      'atk': atk,
      'def': def,
      'spa': spa,
      'spd': spd,
      'spe': spe,
      'bst': bst,
    };
  }
}

class PokemonSpeciesAbilities {
  const PokemonSpeciesAbilities({
    required this.primary,
    this.secondary,
    this.hidden,
  });

  final String primary;
  final String? secondary;
  final String? hidden;

  factory PokemonSpeciesAbilities.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesAbilities(
      primary: (json['primary'] as String?)?.trim() ?? '',
      secondary: (json['secondary'] as String?)?.trim(),
      hidden: (json['hidden'] as String?)?.trim(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'primary': primary,
      'secondary': secondary,
      'hidden': hidden,
    };
  }
}

class PokemonSpeciesBreeding {
  const PokemonSpeciesBreeding({
    required this.genderRatio,
    this.eggGroups = const <String>[],
    this.hatchCycles = 0,
  });

  final Map<String, double> genderRatio;
  final List<String> eggGroups;
  final int hatchCycles;

  factory PokemonSpeciesBreeding.fromJson(Map<String, dynamic> json) {
    final rawGenderRatio =
        (json['genderRatio'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    return PokemonSpeciesBreeding(
      genderRatio: rawGenderRatio.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      eggGroups: _readStringList(json['eggGroups']),
      hatchCycles: (json['hatchCycles'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'genderRatio': genderRatio.map(
        (key, value) => MapEntry(key, value),
      ),
      'eggGroups': List<String>.from(eggGroups),
      'hatchCycles': hatchCycles,
    };
  }
}

class PokemonSpeciesProgression {
  const PokemonSpeciesProgression({
    required this.growthRateId,
    required this.baseExp,
    required this.catchRate,
    required this.baseFriendship,
  });

  final String growthRateId;
  final int baseExp;
  final int catchRate;
  final int baseFriendship;

  factory PokemonSpeciesProgression.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesProgression(
      growthRateId: (json['growthRateId'] as String?)?.trim() ?? '',
      baseExp: (json['baseExp'] as num?)?.toInt() ?? 0,
      catchRate: (json['catchRate'] as num?)?.toInt() ?? 0,
      baseFriendship: (json['baseFriendship'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'growthRateId': growthRateId,
      'baseExp': baseExp,
      'catchRate': catchRate,
      'baseFriendship': baseFriendship,
    };
  }
}

class PokemonSpeciesDexContent {
  const PokemonSpeciesDexContent({
    this.heightM,
    this.weightKg,
    this.color,
    this.flavorText,
  });

  final double? heightM;
  final double? weightKg;
  final String? color;
  final String? flavorText;

  factory PokemonSpeciesDexContent.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesDexContent(
      heightM: _readDouble(json['heightM']),
      weightKg: _readDouble(json['weightKg']),
      color: _readOptionalTrimmedString(json['color']),
      flavorText: _readOptionalTrimmedString(json['flavorText']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'heightM': heightM,
      'weightKg': weightKg,
      'color': color,
      'flavorText': flavorText,
    };
  }
}

class PokemonSpeciesGameplayFlags {
  const PokemonSpeciesGameplayFlags({
    this.starterEligible = false,
    this.giftOnly = false,
    this.tradeOnly = false,
  });

  final bool starterEligible;
  final bool giftOnly;
  final bool tradeOnly;

  factory PokemonSpeciesGameplayFlags.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesGameplayFlags(
      starterEligible: _readBool(json['starterEligible']),
      giftOnly: _readBool(json['giftOnly']),
      tradeOnly: _readBool(json['tradeOnly']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'starterEligible': starterEligible,
      'giftOnly': giftOnly,
      'tradeOnly': tradeOnly,
    };
  }
}

class PokemonSpeciesSourceMeta {
  const PokemonSpeciesSourceMeta({
    this.seededBy,
    this.seedVersion,
  });

  final String? seededBy;
  final int? seedVersion;

  factory PokemonSpeciesSourceMeta.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesSourceMeta(
      seededBy: _readOptionalTrimmedString(json['seededBy']),
      seedVersion: (json['seedVersion'] as num?)?.toInt(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'seededBy': seededBy,
      'seedVersion': seedVersion,
    };
  }
}

class PokemonSpeciesFile {
  const PokemonSpeciesFile({
    required this.id,
    required this.slug,
    required this.nationalDex,
    required this.names,
    required this.speciesName,
    required this.genIntroduced,
    required this.typing,
    required this.baseStats,
    required this.abilities,
    required this.breeding,
    required this.progression,
    required this.evolutionRef,
    required this.learnsetRef,
    required this.spriteSetRef,
    required this.cryRef,
    required this.dexContent,
    required this.gameplayFlags,
    required this.sourceMeta,
  });

  final String id;
  final String slug;
  final int nationalDex;
  final Map<String, String> names;
  final Map<String, String> speciesName;
  final int genIntroduced;
  final PokemonSpeciesTyping typing;
  final PokemonSpeciesBaseStats baseStats;
  final PokemonSpeciesAbilities abilities;
  final PokemonSpeciesBreeding breeding;
  final PokemonSpeciesProgression progression;
  final String evolutionRef;
  final String learnsetRef;
  final String spriteSetRef;
  final String cryRef;
  final PokemonSpeciesDexContent dexContent;
  final PokemonSpeciesGameplayFlags gameplayFlags;
  final PokemonSpeciesSourceMeta sourceMeta;

  factory PokemonSpeciesFile.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesFile(
      id: (json['id'] as String?)?.trim() ?? '',
      slug: (json['slug'] as String?)?.trim() ?? '',
      nationalDex: (json['nationalDex'] as num?)?.toInt() ?? 0,
      names: _readStringMap(json['names']),
      speciesName: _readStringMap(json['speciesName']),
      genIntroduced: (json['genIntroduced'] as num?)?.toInt() ?? 0,
      typing: PokemonSpeciesTyping.fromJson(
        (json['typing'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      baseStats: PokemonSpeciesBaseStats.fromJson(
        (json['baseStats'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      abilities: PokemonSpeciesAbilities.fromJson(
        (json['abilities'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      breeding: PokemonSpeciesBreeding.fromJson(
        (json['breeding'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      progression: PokemonSpeciesProgression.fromJson(
        (json['progression'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      evolutionRef: (json['evolutionRef'] as String?)?.trim() ?? '',
      learnsetRef: (json['learnsetRef'] as String?)?.trim() ?? '',
      spriteSetRef: (json['spriteSetRef'] as String?)?.trim() ?? '',
      cryRef: (json['cryRef'] as String?)?.trim() ?? '',
      dexContent: PokemonSpeciesDexContent.fromJson(
        (json['dexContent'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      gameplayFlags: PokemonSpeciesGameplayFlags.fromJson(
        (json['gameplayFlags'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      sourceMeta: PokemonSpeciesSourceMeta.fromJson(
        (json['sourceMeta'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'slug': slug,
      'nationalDex': nationalDex,
      'names': Map<String, String>.from(names),
      'speciesName': Map<String, String>.from(speciesName),
      'genIntroduced': genIntroduced,
      'typing': typing.toJson(),
      'baseStats': baseStats.toJson(),
      'abilities': abilities.toJson(),
      'breeding': breeding.toJson(),
      'progression': progression.toJson(),
      'evolutionRef': evolutionRef,
      'learnsetRef': learnsetRef,
      'spriteSetRef': spriteSetRef,
      'cryRef': cryRef,
      'dexContent': dexContent.toJson(),
      'gameplayFlags': gameplayFlags.toJson(),
      'sourceMeta': sourceMeta.toJson(),
    };
  }
}

class PokemonLearnsetLevelUpEntry {
  const PokemonLearnsetLevelUpEntry({
    required this.moveId,
    required this.level,
    required this.source,
    required this.versionGroup,
  });

  final String moveId;
  final int level;
  final String source;
  final String versionGroup;

  factory PokemonLearnsetLevelUpEntry.fromJson(Map<String, dynamic> json) {
    return PokemonLearnsetLevelUpEntry(
      moveId: (json['moveId'] as String?)?.trim() ?? '',
      level: (json['level'] as num?)?.toInt() ?? 0,
      source: (json['source'] as String?)?.trim() ?? '',
      versionGroup: (json['versionGroup'] as String?)?.trim() ?? '',
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'moveId': moveId,
      'level': level,
      'source': source,
      'versionGroup': versionGroup,
    };
  }
}

class PokemonLearnsetFile {
  const PokemonLearnsetFile({
    required this.speciesId,
    this.startingMoves = const <String>[],
    this.relearnMoves = const <String>[],
    this.levelUp = const <PokemonLearnsetLevelUpEntry>[],
  });

  final String speciesId;
  final List<String> startingMoves;
  final List<String> relearnMoves;
  final List<PokemonLearnsetLevelUpEntry> levelUp;

  factory PokemonLearnsetFile.fromJson(Map<String, dynamic> json) {
    final rawLevelUp = (json['levelUp'] as List?) ?? const <Object?>[];
    return PokemonLearnsetFile(
      speciesId: (json['speciesId'] as String?)?.trim() ?? '',
      startingMoves: _readStringList(json['startingMoves']),
      relearnMoves: _readStringList(json['relearnMoves']),
      levelUp: rawLevelUp
          .whereType<Map>()
          .map(
            (entry) =>
                PokemonLearnsetLevelUpEntry.fromJson(
                  entry.cast<String, dynamic>(),
                ),
          )
          .toList(growable: false),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'speciesId': speciesId,
      'startingMoves': List<String>.from(startingMoves),
      'relearnMoves': List<String>.from(relearnMoves),
      'levelUp': levelUp.map((entry) => entry.toJson()).toList(growable: false),
    };
  }
}

class PokemonEvolutionEntry {
  const PokemonEvolutionEntry({
    required this.targetSpeciesId,
    required this.method,
    this.minLevel,
  });

  final String targetSpeciesId;
  final String method;
  final int? minLevel;

  factory PokemonEvolutionEntry.fromJson(Map<String, dynamic> json) {
    return PokemonEvolutionEntry(
      targetSpeciesId: (json['targetSpeciesId'] as String?)?.trim() ?? '',
      method: (json['method'] as String?)?.trim() ?? '',
      minLevel: (json['minLevel'] as num?)?.toInt(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'targetSpeciesId': targetSpeciesId,
      'method': method,
      'minLevel': minLevel,
    };
  }
}

class PokemonEvolutionFile {
  const PokemonEvolutionFile({
    required this.speciesId,
    this.preEvolution,
    this.evolutions = const <PokemonEvolutionEntry>[],
  });

  final String speciesId;
  final String? preEvolution;
  final List<PokemonEvolutionEntry> evolutions;

  factory PokemonEvolutionFile.fromJson(Map<String, dynamic> json) {
    final rawEvolutions = (json['evolutions'] as List?) ?? const <Object?>[];
    return PokemonEvolutionFile(
      speciesId: (json['speciesId'] as String?)?.trim() ?? '',
      preEvolution: (json['preEvolution'] as String?)?.trim(),
      evolutions: rawEvolutions
          .whereType<Map>()
          .map(
            (entry) =>
                PokemonEvolutionEntry.fromJson(entry.cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'speciesId': speciesId,
      'preEvolution': preEvolution,
      'evolutions': evolutions
          .map((entry) => entry.toJson())
          .toList(growable: false),
    };
  }
}

List<String> _readStringList(Object? raw) {
  final list = raw as List?;
  if (list == null) return const <String>[];
  return list
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
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

String? _readOptionalTrimmedString(Object? raw) {
  final value = raw as String?;
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

double? _readDouble(Object? raw) {
  final value = raw as num?;
  return value?.toDouble();
}

bool _readBool(Object? raw) {
  return raw == true;
}

Map<String, dynamic> _deepCopyJsonMap(Map<String, dynamic> source) {
  return source.map(
    (key, value) => MapEntry(key, _deepCopyJsonValue(value)),
  );
}

Object? _deepCopyJsonValue(Object? value) {
  if (value is Map<String, dynamic>) {
    return _deepCopyJsonMap(value);
  }
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(key.toString(), _deepCopyJsonValue(nestedValue)),
    );
  }
  if (value is List) {
    return value.map(_deepCopyJsonValue).toList(growable: false);
  }
  return value;
}
```

### Explication

Le changement utile de ce fichier est la centralisation de la projection légère sur une espèce déjà parsée.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_database_index.dart`

```dart
import 'pokemon_project_data_models.dart';

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

  /// Construit l'entree specifique au lot 11 a partir d'une source de vérité
  /// déjà existante.
  ///
  /// Le mini-fix 11b retire volontairement le mini parsing parallèle du JSON :
  /// - `PokemonSpeciesIndexEntry` fournit déjà `id`, `nationalDex` et
  ///   `primaryName` ;
  /// - `PokemonSpeciesFile` reste la source de vérité pour les refs.
  ///
  /// Cette factory ne décide donc plus comment parser le JSON ni comment
  /// calculer le nom principal. Elle assemble seulement une projection plus
  /// petite destinée à une future liste locale.
  factory PokemonDatabaseIndexEntry.fromSpeciesEntry({
    required PokemonSpeciesIndexEntry speciesIndexEntry,
    required PokemonSpeciesFile species,
  }) {
    return PokemonDatabaseIndexEntry(
      id: speciesIndexEntry.id,
      nationalDex: speciesIndexEntry.nationalDex,
      primaryName: speciesIndexEntry.primaryName,
      refs: PokemonDatabaseIndexRefs(
        learnset: species.learnsetRef.trim(),
        evolution: species.evolutionRef.trim(),
        spriteSet: species.spriteSetRef.trim(),
        cry: species.cryRef.trim(),
      ),
    );
  }
}
```

### Explication

Le fichier ne parse plus le JSON espèce. Il assemble l'entrée d'index à partir de modèles déjà cohérents.

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
      final species = await _readSpeciesAtRelativePath(
        workspace,
        relativePath,
      );
      final speciesIndexEntry = PokemonSpeciesIndexEntry.fromSpeciesFile(
        species,
        relativePath: relativePath,
      );

      // Le lot 11 ne doit plus accepter silencieusement une espèce parseable
      // mais inutilisable pour la future liste. On vérifie donc ici le contrat
      // minimal exact de l'index local.
      _validateSpeciesForDatabaseIndex(
        species: species,
        speciesIndexEntry: speciesIndexEntry,
        relativePath: relativePath,
      );

      entries.add(
        PokemonDatabaseIndexEntry.fromSpeciesEntry(
          speciesIndexEntry: speciesIndexEntry,
          species: species,
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
      final species = await _readSpeciesAtRelativePath(workspace, relativePath);
      entries.add(
        PokemonSpeciesIndexEntry.fromSpeciesFile(
          species,
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

  void _validateSpeciesForDatabaseIndex({
    required PokemonSpeciesFile species,
    required PokemonSpeciesIndexEntry speciesIndexEntry,
    required String relativePath,
  }) {
    // Cette validation reste volontairement petite. Elle ne remplace pas le
    // validateur Pokémon global : elle protège seulement le contrat minimal
    // exigé par l'index local du lot 11.
    if (speciesIndexEntry.id.trim().isEmpty) {
      throw EditorPersistenceException(
        'Pokemon species index file must define a non-empty id: $relativePath',
      );
    }

    if (speciesIndexEntry.nationalDex <= 0) {
      throw EditorPersistenceException(
        'Pokemon species index file must define nationalDex > 0: $relativePath',
      );
    }

    if (speciesIndexEntry.primaryName.trim().isEmpty) {
      throw EditorPersistenceException(
        'Pokemon species index file must define an exploitable primary name: '
        '$relativePath',
      );
    }

    _validateDatabaseIndexRef(
      value: species.learnsetRef,
      refName: 'learnsetRef',
      relativePath: relativePath,
    );
    _validateDatabaseIndexRef(
      value: species.evolutionRef,
      refName: 'evolutionRef',
      relativePath: relativePath,
    );
    _validateDatabaseIndexRef(
      value: species.spriteSetRef,
      refName: 'spriteSetRef',
      relativePath: relativePath,
    );
    _validateDatabaseIndexRef(
      value: species.cryRef,
      refName: 'cryRef',
      relativePath: relativePath,
    );
  }

  void _validateDatabaseIndexRef({
    required String value,
    required String refName,
    required String relativePath,
  }) {
    if (value.trim().isEmpty) {
      throw EditorPersistenceException(
        'Pokemon species index file must define a non-empty $refName: '
        '$relativePath',
      );
    }
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

  String _sanitizeSpeciesFileSegment(String value) {
    final normalized = value.trim().toLowerCase();
    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
    final collapsed = safe.replaceAll(RegExp(r'_+'), '_');
    return collapsed.replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<Map<String, dynamic>> _readJsonFile(
    ProjectWorkspace workspace,
    String relativePath, {
    required String label,
  }) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    final file = File(absolutePath);
    if (!await file.exists()) {
      throw EditorNotFoundException('$label not found: $relativePath');
    }

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw EditorPersistenceException(
          '$label is not a JSON object: $relativePath',
        );
      }
      return decoded;
    } on EditorPersistenceException {
      rethrow;
    } on FileSystemException catch (error) {
      throw EditorPersistenceException(
        'Failed to read $label at $relativePath: $error',
      );
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Invalid JSON in $label at $relativePath: $error',
      );
    }
  }
}
```

### Explication

Le reader est le point où l'on retire la duplication de parsing et où l'on rend explicite le contrat minimal exigé par le lot 11.

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
      final speciesIndexEntries =
          await pokemonReadRepository.listSpeciesIndexEntries(workspace);

      expect(entries, hasLength(2));

      final bulbasaur = entries.firstWhere((entry) => entry.id == 'bulbasaur');
      final bulbasaurSpeciesIndex = speciesIndexEntries.firstWhere(
        (entry) => entry.id == 'bulbasaur',
      );
      expect(bulbasaur.nationalDex, 1);
      expect(bulbasaur.primaryName, 'Bulbasaur');
      expect(bulbasaur.id, bulbasaurSpeciesIndex.id);
      expect(bulbasaur.nationalDex, bulbasaurSpeciesIndex.nationalDex);
      expect(bulbasaur.primaryName, bulbasaurSpeciesIndex.primaryName);
      expect(
        bulbasaur.refs,
        isA<PokemonDatabaseIndexRefs>()
            .having((refs) => refs.learnset, 'learnset', 'bulbasaur')
            .having((refs) => refs.evolution, 'evolution', 'bulbasaur')
            .having((refs) => refs.spriteSet, 'spriteSet', 'bulbasaur')
            .having((refs) => refs.cry, 'cry', 'bulbasaur'),
      );
    });

    test(
        'fails explicitly when a species json is syntactically valid but structurally invalid',
        () async {
      await createProjectUseCase.execute(
        'Pokemon Structurally Invalid Species Index Project',
        tempProjectRoot.path,
      );

      final speciesDir = Directory(
        workspace.resolveProjectRelativePath('data/pokemon/species'),
      );
      await speciesDir.create(recursive: true);
      await File(
        p.join(speciesDir.path, '0001-invalid.json'),
      ).writeAsString('''
{
  "id": "",
  "nationalDex": 0,
  "names": {},
  "typing": {"types": ["grass"]},
  "learnsetRef": "",
  "evolutionRef": "",
  "spriteSetRef": "",
  "cryRef": ""
}
''');

      expect(
        () => indexService.build(workspace),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('non-empty id'),
          ),
        ),
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

Les tests verrouillent à la fois l'alignement sur la source de vérité retenue et l'échec explicite sur structure invalide.

## Conclusion honnête

Ce mini-fix garde le lot 11 exactement dans son rôle :
- indexation locale légère ;
- aucune UI ;
- aucune lecture hors espèces ;
- aucune mutation ;
- aucune extension produit.

La dette principale du lot 11 est désormais corrigée :
- plus de mini-parser parallèle du JSON ;
- plus de logique parallèle de `primaryName` ;
- plus d'acceptation silencieuse de données minimales bancales pour l'index.
