# Pokemon Validation Lot 9b Mini-Fix Report

## 1. Resume executif

Ce mini-fix corrige un manque de couverture de tests du lot 9.

La logique du validateur gerait deja l'absence de `types.json`, mais il n'y
avait pas de test explicite pour prouver que :

- la validation n'explose pas ;
- une issue `catalog.types_missing` est bien remontee ;
- cette issue est un `warning` ;
- la validation des types est bien skippee proprement.

Le diff reste volontairement minuscule :

- un seul fichier de test modifie ;
- aucun changement du validateur ;
- aucun changement de l'architecture ;
- aucun changement de `project.json` ;
- aucune creation de `./data` ou `./assets` a la racine du monorepo.

## 2. Probleme exact corrige

Le lot 9 couvrait explicitement :

- le cas `moves.json` absent ;
- le cas `moves` manquant remonte en `warning`.

En revanche, la branche equivalente pour `types.json` n'etait pas verrouillee
par un test dedie.

Ce mini-fix ajoute donc un test cible pour le cas :

- suppression de `data/pokemon/catalogs/types.json` dans le workspace projet ;
- execution de la validation ;
- verification que le rapport contient `catalog.types_missing` en severite
  `warning` ;
- verification que la validation continue proprement ;
- verification qu'aucune erreur parasite `species.type_missing_in_catalog`
  n'est emise quand la validation des types est explicitement skippee.

## 3. Perimetre exact du mini-fix

Inclus :

- ajout d'un test dedie dans
  `packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart`
- reexecution des tests Pokemon lecture / ecriture / validation
- reexecution de l'analyse ciblee
- generation d'un rapport de mini-fix

Exclu volontairement :

- aucun changement du validateur
- aucun refactor
- aucune modification des ports ou repositories
- aucune modification de `project.json`
- aucune UI
- aucun runtime
- aucun import externe

## 4. Decision prise

Decision retenue :

- ne rien changer dans `PokemonProjectValidator`, car la logique existante est
  deja correcte ;
- ajouter uniquement la preuve de comportement manquante au niveau test.

Le nouveau test verifie explicitement :

1. `types.json` absent ;
2. validation qui continue ;
3. issue `catalog.types_missing` presente ;
4. severite `warning` ;
5. absence de faux positifs sur `species.type_missing_in_catalog`.

## 5. Fichiers modifies

Fichier de code/test modifie dans ce mini-fix :

- `packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart`

Nouveau rapport :

- `reports/pokemon-validation-lot-9b-mini-fix-report.md`

## 6. Commandes reellement executees

```bash
flutter test test/validate_pokemon_project_data_use_case_test.dart
flutter test test/file_pokemon_read_repository_test.dart
flutter test test/file_pokemon_write_repository_test.dart
flutter analyze --no-pub \
  lib/src/application/models/pokemon_validation_report.dart \
  lib/src/application/services/pokemon_project_validator.dart \
  lib/src/application/use_cases/validate_pokemon_project_data_use_case.dart \
  test/validate_pokemon_project_data_use_case_test.dart
git status --short
git diff --stat -- \
  packages/map_editor/lib/src/application/services/pokemon_project_validator.dart \
  packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart \
  reports/pokemon-validation-lot-9b-mini-fix-report.md
git ls-files --others --exclude-standard \
  packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart \
  reports/pokemon-validation-lot-9b-mini-fix-report.md
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
./review_bundle.sh
```

## 7. Resultats reels des tests

### 7.1 Validation lot 9

Commande :

```bash
flutter test test/validate_pokemon_project_data_use_case_test.dart
```

Resultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart
00:01 +0: ValidatePokemonProjectDataUseCase returns a valid report for the seeded demo dataset
00:01 +1: ValidatePokemonProjectDataUseCase returns a valid report for the seeded demo dataset
00:01 +1: ValidatePokemonProjectDataUseCase leaves project.json strictly unchanged
00:01 +1: ValidatePokemonProjectDataUseCase leaves project.json strictly unchanged
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/pokemon_validate_SZgkxA/project.json
00:01 +2: ValidatePokemonProjectDataUseCase leaves project.json strictly unchanged
00:01 +2: ValidatePokemonProjectDataUseCase reads from the workspace even when Directory.current points somewhere else
00:01 +3: ValidatePokemonProjectDataUseCase reads from the workspace even when Directory.current points somewhere else
00:01 +3: ValidatePokemonProjectDataUseCase reports an error when a species id is empty
00:01 +4: ValidatePokemonProjectDataUseCase reports an error when a species id is empty
00:01 +4: ValidatePokemonProjectDataUseCase reports an error when a species has duplicated types
00:01 +5: ValidatePokemonProjectDataUseCase reports an error when a species has duplicated types
00:01 +5: ValidatePokemonProjectDataUseCase reports an error when a learnset has an empty move id
00:01 +6: ValidatePokemonProjectDataUseCase reports an error when a learnset has an empty move id
00:01 +6: ValidatePokemonProjectDataUseCase reports an error when a learnset level is below one
00:01 +7: ValidatePokemonProjectDataUseCase reports an error when a learnset level is below one
00:01 +7: ValidatePokemonProjectDataUseCase reports an error when an evolution targets itself
00:01 +8: ValidatePokemonProjectDataUseCase reports an error when an evolution targets itself
00:01 +8: ValidatePokemonProjectDataUseCase reports an error when a species learnsetRef is missing locally
00:01 +9: ValidatePokemonProjectDataUseCase reports an error when a species learnsetRef is missing locally
00:01 +9: ValidatePokemonProjectDataUseCase reports an error when a species evolutionRef is missing locally
00:01 +10: ValidatePokemonProjectDataUseCase reports an error when a species evolutionRef is missing locally
00:01 +10: ValidatePokemonProjectDataUseCase reports an error when an evolution target species is absent
00:01 +11: ValidatePokemonProjectDataUseCase reports an error when an evolution target species is absent
00:01 +11: ValidatePokemonProjectDataUseCase reports an error when a learnset uses a move absent from moves catalog
00:01 +12: ValidatePokemonProjectDataUseCase reports an error when a learnset uses a move absent from moves catalog
00:01 +12: ValidatePokemonProjectDataUseCase reports an error when a species uses a type absent from types catalog
00:01 +13: ValidatePokemonProjectDataUseCase reports an error when a species uses a type absent from types catalog
00:01 +13: ValidatePokemonProjectDataUseCase reports invalid JSON as a validation issue instead of mutating data
00:01 +14: ValidatePokemonProjectDataUseCase reports invalid JSON as a validation issue instead of mutating data
00:01 +14: ValidatePokemonProjectDataUseCase adds a warning when moves catalog is absent and skips that validation
00:01 +15: ValidatePokemonProjectDataUseCase adds a warning when moves catalog is absent and skips that validation
00:01 +15: ValidatePokemonProjectDataUseCase adds a warning when types catalog is absent and skips that validation
00:01 +16: ValidatePokemonProjectDataUseCase adds a warning when types catalog is absent and skips that validation
00:01 +16: All tests passed!
```

### 7.2 Regression lecture

Commande :

```bash
flutter test test/file_pokemon_read_repository_test.dart
```

Resultat :

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_read_repository_test.dart
00:01 +0: FilePokemonReadRepository reads from the workspace project and not the monorepo root
00:01 +1: FilePokemonReadRepository reads from the workspace project and not the monorepo root
00:01 +1: FilePokemonReadRepository reads the seeded pokemon files through the repository abstraction
00:01 +2: FilePokemonReadRepository reads the seeded pokemon files through the repository abstraction
00:01 +2: FilePokemonReadRepository throws explicit error when a species file is missing
00:01 +3: FilePokemonReadRepository throws explicit error when a species file is missing
00:01 +3: FilePokemonReadRepository throws explicit error when a species json file is invalid
00:01 +4: FilePokemonReadRepository throws explicit error when a species json file is invalid
00:01 +4: FilePokemonReadRepository leaves project.json strictly unchanged
00:01 +4: FilePokemonReadRepository leaves project.json strictly unchanged
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/pokemon_repo_hSvfSa/project.json
00:01 +5: FilePokemonReadRepository leaves project.json strictly unchanged
00:01 +5: FilePokemonReadRepository does not recreate data or assets at the monorepo root
00:01 +6: FilePokemonReadRepository does not recreate data or assets at the monorepo root
00:01 +6: All tests passed!
```

### 7.3 Regression ecriture

Commande :

```bash
flutter test test/file_pokemon_write_repository_test.dart
```

Resultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart
00:01 +0: FilePokemonWriteRepository saves a species file in the project workspace
00:01 +1: FilePokemonWriteRepository saves a species file in the project workspace
00:01 +1: FilePokemonWriteRepository saves a learnset file in the project workspace
00:01 +2: FilePokemonWriteRepository saves a learnset file in the project workspace
00:01 +2: FilePokemonWriteRepository saves an evolution file in the project workspace
00:01 +3: FilePokemonWriteRepository saves an evolution file in the project workspace
00:01 +3: FilePokemonWriteRepository saves a catalog file in the project workspace
00:01 +4: FilePokemonWriteRepository saves a catalog file in the project workspace
00:01 +4: FilePokemonWriteRepository writes in the workspace project and not at the monorepo root
00:01 +5: FilePokemonWriteRepository writes in the workspace project and not at the monorepo root
00:01 +5: FilePokemonWriteRepository leaves project.json strictly unchanged
00:01 +5: FilePokemonWriteRepository leaves project.json strictly unchanged
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/pokemon_write_repo_gd6MtF/project.json
00:01 +6: FilePokemonWriteRepository leaves project.json strictly unchanged
00:01 +6: FilePokemonWriteRepository overwrites the target species file predictably
00:01 +7: FilePokemonWriteRepository overwrites the target species file predictably
00:01 +7: FilePokemonWriteRepository does not create a duplicate species file when the slug changes
00:01 +8: FilePokemonWriteRepository does not create a duplicate species file when the slug changes
00:01 +8: FilePokemonWriteRepository rewrites an existing species even when another unrelated species json is invalid
00:01 +9: FilePokemonWriteRepository rewrites an existing species even when another unrelated species json is invalid
00:01 +9: FilePokemonWriteRepository throws explicit conflict when multiple species files match the same id
00:01 +10: FilePokemonWriteRepository throws explicit conflict when multiple species files match the same id
00:01 +10: FilePokemonWriteRepository throws explicit error when catalog key does not match payload
00:01 +11: FilePokemonWriteRepository throws explicit error when catalog key does not match payload
00:01 +11: All tests passed!
```

## 8. Resultat reel de flutter analyze

Commande :

```bash
flutter analyze --no-pub \
  lib/src/application/models/pokemon_validation_report.dart \
  lib/src/application/services/pokemon_project_validator.dart \
  lib/src/application/use_cases/validate_pokemon_project_data_use_case.dart \
  test/validate_pokemon_project_data_use_case_test.dart
```

Resultat :

```text
No issues found! (ran in 2.0s)
```

## 9. Verifications de perimetre

### 9.1 `project.json` inchangé

Le test `leaves project.json strictly unchanged` continue de passer dans :

- `test/validate_pokemon_project_data_use_case_test.dart`
- `test/file_pokemon_read_repository_test.dart`
- `test/file_pokemon_write_repository_test.dart`

### 9.2 Rien recree a la racine du monorepo

Commande :

```bash
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
```

Sortie :

```text
```

Conclusion :

- aucun `./data`
- aucun `./assets`

n'ont ete recrees a la racine du monorepo.

## 10. Etat Git utile

### 10.1 `git status --short`

```text
 M packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
 M packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
?? packages/map_editor/lib/src/application/models/pokemon_validation_report.dart
?? packages/map_editor/lib/src/application/services/pokemon_project_validator.dart
?? packages/map_editor/lib/src/application/use_cases/validate_pokemon_project_data_use_case.dart
?? packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart
?? reports/pokemon-validation-lot-9-report.md
```

Note honnête :

- cet etat Git n'isole pas le mini-fix 9b tout seul ;
- il montre aussi l'etat non commit du lot 9, deja present dans le working tree.

### 10.2 `git diff --stat` cible

Commande :

```bash
git diff --stat -- \
  packages/map_editor/lib/src/application/services/pokemon_project_validator.dart \
  packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart \
  reports/pokemon-validation-lot-9b-mini-fix-report.md
```

Sortie :

```text
```

Note honnête :

- cette sortie est vide parce que :
  - `pokemon_project_validator.dart` n'a pas ete modifie dans ce mini-fix ;
  - `validate_pokemon_project_data_use_case_test.dart` est un fichier non suivi dans l'etat Git actuel ;
  - le rapport 9b est lui aussi non suivi.
- `git diff --stat` ne montre donc pas les changements non suivis.

### 10.3 `git ls-files --others --exclude-standard`

Commande :

```bash
git ls-files --others --exclude-standard \
  packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart \
  reports/pokemon-validation-lot-9b-mini-fix-report.md
```

Sortie :

```text
packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart
reports/pokemon-validation-lot-9b-mini-fix-report.md
```

## 11. Bundle de review

Commande executee :

```bash
./review_bundle.sh
```

Chemin du fichier genere :

```text
.review/review-20260409-215004.txt
```

Note honnête :

- le bundle reflete l'etat global non commit des lots 9 et 9b ;
- il est donc utile pour l'audit du working tree, mais pas strictement isole
  au seul mini-fix 9b ;
- il reste partiel sur les fichiers non suivis, car il est base sur les sorties
  Git standards et le diff des fichiers suivis.

Contenu integral du bundle :

```text
# REVIEW BUNDLE

Generated at: 2026-04-09 21:50:04
Repository: pokemonProject
Branch: main
Base ref: HEAD
Head commit: 318a544da73ad433130c8aaca64fea1348997ffb

## GIT STATUS --SHORT

 M packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
 M packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
?? packages/map_editor/lib/src/application/models/pokemon_validation_report.dart
?? packages/map_editor/lib/src/application/services/pokemon_project_validator.dart
?? packages/map_editor/lib/src/application/use_cases/validate_pokemon_project_data_use_case.dart
?? packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart
?? reports/pokemon-validation-lot-9-report.md
?? reports/pokemon-validation-lot-9b-mini-fix-report.md

## GIT DIFF --STAT

 .../application/ports/pokemon_read_repository.dart | 11 +++
 .../services/pokemon_project_data_reader.dart      | 85 +++++++++++++++++-----
 .../lib/src/application/use_cases/use_cases.dart   |  1 +
 .../repositories/file_repositories.dart            | 23 ++++++
 4 files changed, 102 insertions(+), 18 deletions(-)

## CHANGED FILES

packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
packages/map_editor/lib/src/application/use_cases/use_cases.dart
packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart

## RECENT COMMITS

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
fc7cf31 Enhance polygon rasterization logic and add backend cell preview to collision editor
fe5da3e Add tests for project collision profile persistence and enhance UI behavior in element collision editor
5d65444 Add element collision editor UI and rasterization services

## FULL DIFF

diff --git a/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart b/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
index 3a2ffff..1b065be 100644
--- a/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
+++ b/packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
@@ -17,16 +17,27 @@ abstract class PokemonReadRepository {
     ProjectWorkspace workspace,
   );

+  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace);
+
+  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
+    ProjectWorkspace workspace,
+    String relativePath,
+  );
+
   Future<PokemonSpeciesFile> readSpeciesById(
     ProjectWorkspace workspace,
     String speciesId,
   );

+  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace);
+
   Future<PokemonLearnsetFile> readLearnsetById(
     ProjectWorkspace workspace,
     String speciesId,
   );

+  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace);
+
   Future<PokemonEvolutionFile> readEvolutionById(
     ProjectWorkspace workspace,
     String speciesId,
diff --git a/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart b/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
index 28d5ac7..3be1866 100644
--- a/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
+++ b/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
@@ -106,24 +106,11 @@ class PokemonProjectDataReader {
   }

   Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) async {
-    final speciesDir = _speciesDirectory(workspace);
-    if (!await speciesDir.exists()) {
-      throw const EditorNotFoundException(
-        'Pokemon species directory not found in project workspace',
-      );
-    }
-
-    final relativePaths = <String>[];
-    await for (final entity in speciesDir.list(recursive: false)) {
-      if (entity is! File) continue;
-      if (p.extension(entity.path).toLowerCase() != '.json') continue;
-      final relativePath = p.normalize(
-        p.relative(entity.path, from: workspace.projectRoot),
-      );
-      relativePaths.add(relativePath);
-    }
-    relativePaths.sort();
-    return relativePaths;
+    return _listJsonRelativePaths(
+      workspace,
+      'data/pokemon/species',
+      label: 'Pokemon species directory',
+    );
   }

   Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
@@ -132,6 +119,29 @@ class PokemonProjectDataReader {
     return _buildSpeciesIndexEntries(workspace);
   }

+  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
+    ProjectWorkspace workspace,
+    String relativePath,
+  ) {
+    return _readSpeciesAtRelativePath(workspace, relativePath);
+  }
+
+  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) async {
+    return _listJsonFileStemIds(
+      workspace,
+      'data/pokemon/learnsets',
+      label: 'Pokemon learnsets directory',
+    );
+  }
+
+  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) async {
+    return _listJsonFileStemIds(
+      workspace,
+      'data/pokemon/evolutions',
+      label: 'Pokemon evolutions directory',
+    );
+  }
+
   Future<String?> resolveSpeciesRelativePathById(
     ProjectWorkspace workspace,
     String speciesId,
@@ -240,6 +250,45 @@ class PokemonProjectDataReader {
     );
   }

+  Future<List<String>> _listJsonRelativePaths(
+    ProjectWorkspace workspace,
+    String relativeDirectory, {
+    required String label,
+  }) async {
+    final directory = Directory(
+      workspace.resolveProjectRelativePath(relativeDirectory),
+    );
+    if (!await directory.exists()) {
+      throw EditorNotFoundException('$label not found in project workspace');
+    }
+
+    final relativePaths = <String>[];
+    await for (final entity in directory.list(recursive: false)) {
+      if (entity is! File) continue;
+      if (p.extension(entity.path).toLowerCase() != '.json') continue;
+      relativePaths.add(
+        p.normalize(p.relative(entity.path, from: workspace.projectRoot)),
+      );
+    }
+    relativePaths.sort();
+    return relativePaths;
+  }
+
+  Future<List<String>> _listJsonFileStemIds(
+    ProjectWorkspace workspace,
+    String relativeDirectory, {
+    required String label,
+  }) async {
+    final relativePaths = await _listJsonRelativePaths(
+      workspace,
+      relativeDirectory,
+      label: label,
+    );
+    return relativePaths
+        .map((relativePath) => p.basenameWithoutExtension(relativePath))
+        .toList(growable: false);
+  }
+
   String _sanitizeSpeciesFileSegment(String value) {
     final normalized = value.trim().toLowerCase();
     final safe = normalized.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
diff --git a/packages/map_editor/lib/src/application/use_cases/use_cases.dart b/packages/map_editor/lib/src/application/use_cases/use_cases.dart
index 6cf9874..65b2ea1 100644
--- a/packages/map_editor/lib/src/application/use_cases/use_cases.dart
+++ b/packages/map_editor/lib/src/application/use_cases/use_cases.dart
@@ -17,4 +17,5 @@ export 'project_tileset_use_cases.dart';
 export 'seed_pokemon_demo_data_use_case.dart';
 export 'terrain_preset_use_cases.dart';
 export 'terrain_use_cases.dart';
+export 'validate_pokemon_project_data_use_case.dart';
 export 'warp_use_cases.dart';
diff --git a/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart b/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
index 9425b59..6013a8d 100644
--- a/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
+++ b/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
@@ -161,6 +161,19 @@ class FilePokemonReadRepository implements PokemonReadRepository {
     return reader.listSpeciesIndexEntries(workspace);
   }

+  @override
+  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) {
+    return reader.listSpeciesFiles(workspace);
+  }
+
+  @override
+  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
+    ProjectWorkspace workspace,
+    String relativePath,
+  ) {
+    return reader.readSpeciesByRelativePath(workspace, relativePath);
+  }
+
   @override
   Future<PokemonSpeciesFile> readSpeciesById(
     ProjectWorkspace workspace,
@@ -177,6 +190,11 @@ class FilePokemonReadRepository implements PokemonReadRepository {
     return reader.readLearnsetById(workspace, speciesId);
   }

+  @override
+  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) {
+    return reader.listLearnsetIds(workspace);
+  }
+
   @override
   Future<PokemonEvolutionFile> readEvolutionById(
     ProjectWorkspace workspace,
@@ -184,6 +202,11 @@ class FilePokemonReadRepository implements PokemonReadRepository {
   ) {
     return reader.readEvolutionById(workspace, speciesId);
   }
+
+  @override
+  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) {
+    return reader.listEvolutionIds(workspace);
+  }
 }

 /// Implémentation filesystem/workspace de l'écriture locale Pokémon.
```

## 12. Code integral modifie dans ce mini-fix

### 12.1 `packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/models/pokemon_validation_report.dart';
import 'package:map_editor/src/application/services/pokemon_project_validator.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/application/use_cases/validate_pokemon_project_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late String repoRootPath;
  late ProjectFileSystem workspace;
  late SeedPokemonDemoDataUseCase seedUseCase;
  late ValidatePokemonProjectDataUseCase validateUseCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokemon_validate_');
    repoRootPath = _resolveRepositoryRootFromCurrentDirectory();
    workspace = ProjectFileSystem(tempProjectRoot.path);
    seedUseCase = const SeedPokemonDemoDataUseCase();
    validateUseCase = const ValidatePokemonProjectDataUseCase(
      PokemonProjectValidator(
        FilePokemonReadRepository(),
      ),
    );
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('ValidatePokemonProjectDataUseCase', () {
    test('returns a valid report for the seeded demo dataset', () async {
      await seedUseCase.execute(workspace);

      final report = await validateUseCase.execute(workspace);

      expect(report.isValid, isTrue);
      expect(report.errorCount, 0);
      expect(report.issues, isEmpty);
    });

    test('leaves project.json strictly unchanged', () async {
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );
      await createProjectUseCase.execute('Pokemon Validation Project', tempProjectRoot.path);
      await seedUseCase.execute(workspace);

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await validateUseCase.execute(workspace);

      final after = await projectFile.readAsString();
      expect(after, before);
    });

    test(
        'reads from the workspace even when Directory.current points somewhere else',
        () async {
      await seedUseCase.execute(workspace);

      final decoy = await Directory.systemTemp.createTemp('pokemon_validate_decoy_');
      final originalCurrent = Directory.current;
      try {
        await Directory(
          p.join(decoy.path, 'data', 'pokemon', 'species'),
        ).create(recursive: true);
        await File(
          p.join(decoy.path, 'data', 'pokemon', 'species', '0001-bulbasaur.json'),
        ).writeAsString('{ invalid json');

        Directory.current = decoy.path;

        final report = await validateUseCase.execute(workspace);

        expect(report.isValid, isTrue);
        expect(Directory(p.join(repoRootPath, 'data')).existsSync(), isFalse);
        expect(Directory(p.join(repoRootPath, 'assets')).existsSync(), isFalse);
      } finally {
        Directory.current = originalCurrent.path;
        if (await decoy.exists()) {
          await decoy.delete(recursive: true);
        }
      }
    });

    test('reports an error when a species id is empty', () async {
      await seedUseCase.execute(workspace);
      await _mutateJsonFile(
        workspace,
        'data/pokemon/species/0001-bulbasaur.json',
        (json) => json['id'] = '',
      );

      final report = await validateUseCase.execute(workspace);

      expect(_hasIssue(report, 'species.id_empty'), isTrue);
    });

    test('reports an error when a species has duplicated types', () async {
      await seedUseCase.execute(workspace);
      await _mutateJsonFile(
        workspace,
        'data/pokemon/species/0001-bulbasaur.json',
        (json) => (json['typing'] as Map<String, dynamic>)['types'] =
            <String>['grass', 'grass'],
      );

      final report = await validateUseCase.execute(workspace);

      expect(_hasIssue(report, 'species.type_duplicate'), isTrue);
    });

    test('reports an error when a learnset has an empty move id', () async {
      await seedUseCase.execute(workspace);
      await _mutateJsonFile(
        workspace,
        'data/pokemon/learnsets/bulbasaur.json',
        (json) => ((json['levelUp'] as List<Object?>).first
            as Map<String, dynamic>)['moveId'] = '',
      );

      final report = await validateUseCase.execute(workspace);

      expect(_hasIssue(report, 'learnset.level_up_move_empty'), isTrue);
    });

    test('reports an error when a learnset level is below one', () async {
      await seedUseCase.execute(workspace);
      await _mutateJsonFile(
        workspace,
        'data/pokemon/learnsets/bulbasaur.json',
        (json) => ((json['levelUp'] as List<Object?>).first
            as Map<String, dynamic>)['level'] = 0,
      );

      final report = await validateUseCase.execute(workspace);

      expect(_hasIssue(report, 'learnset.level_up_level_invalid'), isTrue);
    });

    test('reports an error when an evolution targets itself', () async {
      await seedUseCase.execute(workspace);
      await _mutateJsonFile(
        workspace,
        'data/pokemon/evolutions/bulbasaur.json',
        (json) => ((json['evolutions'] as List<Object?>).first
            as Map<String, dynamic>)['targetSpeciesId'] = 'bulbasaur',
      );

      final report = await validateUseCase.execute(workspace);

      expect(_hasIssue(report, 'evolution.self_target'), isTrue);
    });

    test('reports an error when a species learnsetRef is missing locally',
        () async {
      await seedUseCase.execute(workspace);
      await _mutateJsonFile(
        workspace,
        'data/pokemon/species/0001-bulbasaur.json',
        (json) => json['learnsetRef'] = 'missing_learnset',
      );

      final report = await validateUseCase.execute(workspace);

      expect(_hasIssue(report, 'species.learnset_ref_missing'), isTrue);
    });

    test('reports an error when a species evolutionRef is missing locally',
        () async {
      await seedUseCase.execute(workspace);
      await _mutateJsonFile(
        workspace,
        'data/pokemon/species/0001-bulbasaur.json',
        (json) => json['evolutionRef'] = 'missing_evolution',
      );

      final report = await validateUseCase.execute(workspace);

      expect(_hasIssue(report, 'species.evolution_ref_missing'), isTrue);
    });

    test('reports an error when an evolution target species is absent', () async {
      await seedUseCase.execute(workspace);
      await _mutateJsonFile(
        workspace,
        'data/pokemon/evolutions/bulbasaur.json',
        (json) => ((json['evolutions'] as List<Object?>).first
            as Map<String, dynamic>)['targetSpeciesId'] = 'venusaur',
      );

      final report = await validateUseCase.execute(workspace);

      expect(_hasIssue(report, 'evolution.target_species_missing'), isTrue);
    });

    test('reports an error when a learnset uses a move absent from moves catalog',
        () async {
      await seedUseCase.execute(workspace);
      await _mutateJsonFile(
        workspace,
        'data/pokemon/learnsets/bulbasaur.json',
        (json) => ((json['levelUp'] as List<Object?>).first
            as Map<String, dynamic>)['moveId'] = 'mystery_move',
      );

      final report = await validateUseCase.execute(workspace);

      expect(_hasIssue(report, 'learnset.move_missing_in_catalog'), isTrue);
    });

    test('reports an error when a species uses a type absent from types catalog',
        () async {
      await seedUseCase.execute(workspace);
      await _mutateJsonFile(
        workspace,
        'data/pokemon/species/0001-bulbasaur.json',
        (json) => (json['typing'] as Map<String, dynamic>)['types'] =
            <String>['shadow'],
      );

      final report = await validateUseCase.execute(workspace);

      expect(_hasIssue(report, 'species.type_missing_in_catalog'), isTrue);
    });

    test('reports invalid JSON as a validation issue instead of mutating data',
        () async {
      await seedUseCase.execute(workspace);
      await _writeRawFile(
        workspace,
        'data/pokemon/species/0001-bulbasaur.json',
        '{ invalid json',
      );

      final report = await validateUseCase.execute(workspace);

      expect(report.isValid, isFalse);
      expect(_hasIssue(report, 'species.read_error'), isTrue);
      expect(
        report.issues.any((issue) => issue.message.contains('Invalid JSON')),
        isTrue,
      );
    });

    test('adds a warning when moves catalog is absent and skips that validation',
        () async {
      await seedUseCase.execute(workspace);
      final movesCatalog = File(
        workspace.resolveProjectRelativePath('data/pokemon/catalogs/moves.json'),
      );
      await movesCatalog.delete();

      final report = await validateUseCase.execute(workspace);

      expect(_hasIssue(report, 'catalog.moves_missing'), isTrue);
      expect(
        report.issues.any(
          (issue) => issue.severity == PokemonValidationSeverity.warning,
        ),
        isTrue,
      );
    });

    test('adds a warning when types catalog is absent and skips that validation',
        () async {
      await seedUseCase.execute(workspace);
      final typesCatalog = File(
        workspace.resolveProjectRelativePath('data/pokemon/catalogs/types.json'),
      );
      await typesCatalog.delete();

      final report = await validateUseCase.execute(workspace);

      expect(report.isValid, isTrue);
      expect(_hasIssue(report, 'catalog.types_missing'), isTrue);
      expect(
        report.issues.any(
          (issue) =>
              issue.code == 'catalog.types_missing' &&
              issue.severity == PokemonValidationSeverity.warning,
        ),
        isTrue,
      );
      expect(_hasIssue(report, 'species.type_missing_in_catalog'), isFalse);
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

Future<void> _mutateJsonFile(
  ProjectFileSystem workspace,
  String relativePath,
  void Function(Map<String, dynamic> json) update,
) async {
  final file = File(workspace.resolveProjectRelativePath(relativePath));
  final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  update(json);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

Future<void> _writeRawFile(
  ProjectFileSystem workspace,
  String relativePath,
  String content,
) async {
  final file = File(workspace.resolveProjectRelativePath(relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}

bool _hasIssue(PokemonValidationReport report, String code) {
  return report.issues.any((issue) => issue.code == code);
}
```

## 13. Mini conclusion honnête

Ce mini-fix 9b reste exactement a la bonne taille :

- un seul comportement verrouille en plus ;
- zero changement architectural ;
- zero refactor ;
- zero derive produit.

On a maintenant une preuve explicite que l'absence de `types.json` est geree
comme l'absence de `moves.json` :

- warning clair ;
- validation qui continue ;
- skip propre de la categorie concernee.
