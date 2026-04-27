# Pokemon Validation Lot 9 Report

## 1. Resume executif

### Ce qui a ete fait

Le lot 9 ajoute une premiere couche de validation locale Pokemon, petite et lisible, composee de :

- un rapport de validation structure (`PokemonValidationReport`, `PokemonValidationIssue`, `PokemonValidationSeverity`) ;
- un service applicatif dedie (`PokemonProjectValidator`) ;
- un use case simple (`ValidatePokemonProjectDataUseCase`) ;
- des extensions minimales du port de lecture Pokemon pour lister / lire les fichiers necessaires a la validation sans dupliquer la logique filesystem ;
- des tests cibles couvrant le dataset seed nominal, les erreurs metier demandees, les erreurs structurelles, `project.json`, et l’ancrage au workspace.

### Ce qui n’a pas ete fait

Ce lot ne fait pas :

- d’UI ;
- de provider Riverpod ;
- d’import externe ;
- d’ecriture correctrice ;
- de mutation automatique ;
- de validation gameplay profonde ;
- de refonte globale de l’architecture Pokemon ;
- de modification de `project.json`.

## 2. Objectif du lot

L’objectif du lot 9 etait de poser une base de validation locale Pokemon :

- deterministe ;
- sans side effects ;
- independante de l’UI ;
- exploitable avant les futurs lots d’edition et d’import ;
- capable de detecter les incoherences grossieres sans tomber dans une usine a gaz.

## 3. Architecture retenue

### 3.1 Modeles de rapport

Fichier :

- `packages/map_editor/lib/src/application/models/pokemon_validation_report.dart`

Types ajoutes :

- `PokemonValidationSeverity`
- `PokemonValidationIssue`
- `PokemonValidationReport`

Ces types permettent :

- de distinguer `error` et `warning` ;
- d’identifier chaque probleme avec un `code` ;
- de localiser le probleme via `location` ;
- de savoir rapidement si le projet est valide via `isValid`.

### 3.2 Service de validation

Fichier :

- `packages/map_editor/lib/src/application/services/pokemon_project_validator.dart`

Responsabilites :

- lire les donnees Pokemon du workspace via `PokemonReadRepository` ;
- accumuler les problemes dans un rapport ;
- ne rien ecrire ;
- ne rien corriger.

### 3.3 Use case

Fichier :

- `packages/map_editor/lib/src/application/use_cases/validate_pokemon_project_data_use_case.dart`

Ce use case ne fait qu’orchestrer l’appel au validateur et retourner le rapport.

### 3.4 Extensions minimales du port de lecture

Fichier :

- `packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`

J’ai ajoute uniquement ce qui etait necessaire pour valider proprement sans bricolage :

- `listSpeciesFiles(...)`
- `readSpeciesByRelativePath(...)`
- `listLearnsetIds(...)`
- `listEvolutionIds(...)`

Cela permet au validateur :

- d’enumerer les fichiers locaux ;
- de capturer les erreurs fichier par fichier ;
- d’accumuler les problemes au lieu d’echouer des qu’un fichier invalide apparait.

## 4. Regles reellement validees

### 4.1 Especes

Le validateur verifie :

- `species.id` non vide ;
- `nationalDex > 0` ;
- nom principal exploitable via :
  - `names['en']`
  - ou `names['fr']`
  - ou `id`
- `typing.types` non vide ;
- pas de doublon evident dans `typing.types` ;
- `learnsetRef` non vide ;
- `evolutionRef` non vide ;
- references types vers le catalogue `types` si disponible ;
- references `learnsetRef` / `evolutionRef` vers des fichiers valides existants ;
- doublons de `species.id` entre fichiers.

### 4.2 Learnsets

Le validateur verifie :

- `speciesId` non vide ;
- pas de `moveId` vide dans :
  - `startingMoves`
  - `relearnMoves`
  - `levelUp[].moveId`
- `levelUp[].level >= 1` ;
- pas de doublon exact dans `levelUp` sur :
  - `(moveId, level, source, versionGroup)`
- reference `speciesId` vers une espece valide existante ;
- references moves vers le catalogue `moves` si disponible.

### 4.3 Evolutions

Le validateur verifie :

- `speciesId` non vide ;
- `targetSpeciesId` non vide ;
- pas d’evolution vers soi-meme ;
- si `method == 'level_up'` et `minLevel` present :
  - `minLevel >= 1`
- `speciesId` vers une espece valide existante ;
- `targetSpeciesId` vers une espece valide existante.

## 5. Choix importants

### 5.1 Comportement sur JSON invalide

Decision retenue :

- un JSON invalide ne fait **pas** planter toute la validation ;
- il remonte comme une issue dans le rapport.

Exemple :

- `species.read_error`
- `learnset.read_error`
- `evolution.read_error`

Pourquoi ce choix :

- il est plus utile pour l’editeur ;
- il permet de continuer l’audit du reste du dataset ;
- il reste deterministe et sans magie.

### 5.2 Comportement si un catalogue est absent

Decision retenue :

- absence d’un catalogue = `warning`
- et la validation de cette categorie est explicitement skippee

Exemple :

- `catalog.moves_missing`
- `catalog.types_missing`

Pourquoi :

- le prompt demandait de ne pas crasher brutalement sur ce point ;
- c’est un probleme de dependance locale, pas necessairement une corruption totale du projet.

### 5.3 Accumulation des erreurs

Decision retenue :

- la validation accumule les problemes detectables ;
- elle ne s’arrete pas a la premiere erreur ;
- seules les categories vraiment indisponibles sont skippees localement, avec issue explicite.

## 6. Fichiers crees / modifies

Crees :

- `packages/map_editor/lib/src/application/models/pokemon_validation_report.dart`
- `packages/map_editor/lib/src/application/services/pokemon_project_validator.dart`
- `packages/map_editor/lib/src/application/use_cases/validate_pokemon_project_data_use_case.dart`
- `packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart`
- `reports/pokemon-validation-lot-9-report.md`

Modifies :

- `packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`
- `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

## 7. Tests reellement executes

Commandes executees :

```bash
flutter test test/validate_pokemon_project_data_use_case_test.dart
flutter test test/file_pokemon_read_repository_test.dart
flutter test test/file_pokemon_write_repository_test.dart
```

## 8. Resultats reels des tests

### 8.1 Validation locale

Commande :

```bash
flutter test test/validate_pokemon_project_data_use_case_test.dart
```

Resultat :

```text
00:01 +15: All tests passed!
```

### 8.2 Regression lecture

Commande :

```bash
flutter test test/file_pokemon_read_repository_test.dart
```

Resultat :

```text
00:02 +6: All tests passed!
```

### 8.3 Regression ecriture

Commande :

```bash
flutter test test/file_pokemon_write_repository_test.dart
```

Resultat :

```text
00:01 +11: All tests passed!
```

## 9. Analyse reellement executee

Commande :

```bash
flutter analyze --no-pub lib/src/application/models/pokemon_validation_report.dart lib/src/application/services/pokemon_project_validator.dart lib/src/application/services/pokemon_project_data_reader.dart lib/src/application/ports/pokemon_read_repository.dart lib/src/infrastructure/repositories/file_repositories.dart lib/src/application/use_cases/validate_pokemon_project_data_use_case.dart lib/src/application/use_cases/use_cases.dart test/validate_pokemon_project_data_use_case_test.dart test/file_pokemon_read_repository_test.dart test/file_pokemon_write_repository_test.dart
```

Resultat :

```text
No issues found! (ran in 0.8s)
```

## 10. Verifications de perimetre

### 10.1 `project.json` inchangé

Le test `leaves project.json strictly unchanged` du lot 9 passe.

### 10.2 Rien recree a la racine du monorepo

Commande executee :

```bash
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
```

Sortie :

```text

```

Conclusion :

- aucun `./data`
- aucun `./assets`

n’ont ete recrees a la racine du monorepo.

## 11. Sorties Git utiles

### 11.1 `git status --short`

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

### 11.2 `git diff --stat`

Commande :

```bash
git diff --stat -- packages/map_editor/lib/src/application/models/pokemon_validation_report.dart packages/map_editor/lib/src/application/services/pokemon_project_validator.dart packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart packages/map_editor/lib/src/application/use_cases/validate_pokemon_project_data_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart reports/pokemon-validation-lot-9-report.md
```

Sortie :

```text
 .../application/ports/pokemon_read_repository.dart | 11 +++
 .../services/pokemon_project_data_reader.dart      | 85 +++++++++++++++++-----
 .../lib/src/application/use_cases/use_cases.dart   |  1 +
 .../repositories/file_repositories.dart            | 23 ++++++
 4 files changed, 102 insertions(+), 18 deletions(-)
```

Note honnete :

- cette sortie Git ne montre que les fichiers tracked modifies ;
- les nouveaux fichiers untracked du lot 9 n’y apparaissent donc pas.

### 11.3 `git ls-files --others --exclude-standard`

Commande :

```bash
git ls-files --others --exclude-standard packages/map_editor/lib/src/application/models/pokemon_validation_report.dart packages/map_editor/lib/src/application/services/pokemon_project_validator.dart packages/map_editor/lib/src/application/use_cases/validate_pokemon_project_data_use_case.dart packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart reports/pokemon-validation-lot-9-report.md
```

Sortie :

```text
packages/map_editor/lib/src/application/models/pokemon_validation_report.dart
packages/map_editor/lib/src/application/services/pokemon_project_validator.dart
packages/map_editor/lib/src/application/use_cases/validate_pokemon_project_data_use_case.dart
packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart
reports/pokemon-validation-lot-9-report.md
```

## 12. Execution obligatoire de `./review_bundle.sh`

Commande executee :

```bash
./review_bundle.sh
```

Fichier genere :

```text
.review/review-20260409-003030.txt
```

## 13. Contenu integral du bundle

```text
# REVIEW BUNDLE

Generated at: 2026-04-09 00:30:30
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

Note honnete :

- le bundle est partiel ;
- il n’inclut pas les nouveaux fichiers untracked du lot 9 dans le diff complet ;
- il se limite aux fichiers tracked modifies visibles par Git a ce moment.

## 14. Code integral

### 14.1 `packages/map_editor/lib/src/application/models/pokemon_validation_report.dart`

```dart
enum PokemonValidationSeverity {
  warning,
  error,
}

class PokemonValidationIssue {
  const PokemonValidationIssue({
    required this.severity,
    required this.code,
    required this.message,
    required this.location,
  });

  final PokemonValidationSeverity severity;
  final String code;
  final String message;
  final String location;
}

class PokemonValidationReport {
  const PokemonValidationReport({
    required this.issues,
  });

  final List<PokemonValidationIssue> issues;

  bool get isValid =>
      !issues.any((issue) => issue.severity == PokemonValidationSeverity.error);

  bool get hasWarnings =>
      issues.any((issue) => issue.severity == PokemonValidationSeverity.warning);

  int get errorCount => issues
      .where((issue) => issue.severity == PokemonValidationSeverity.error)
      .length;

  int get warningCount => issues
      .where((issue) => issue.severity == PokemonValidationSeverity.warning)
      .length;
}
```

### 14.2 `packages/map_editor/lib/src/application/services/pokemon_project_validator.dart`

```dart
import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../models/pokemon_validation_report.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/project_workspace.dart';

class PokemonProjectValidator {
  const PokemonProjectValidator(this.repository);

  final PokemonReadRepository repository;

  Future<PokemonValidationReport> validate(ProjectWorkspace workspace) async {
    final collector = _PokemonValidationIssueCollector();

    final speciesRecords = await _loadSpecies(workspace, collector);
    final learnsetRecords = await _loadLearnsets(workspace, collector);
    final evolutionRecords = await _loadEvolutions(workspace, collector);

    final speciesIds = <String, int>{};
    for (final record in speciesRecords) {
      final speciesId = record.species.id.trim();
      if (speciesId.isEmpty) {
        continue;
      }
      speciesIds.update(speciesId, (count) => count + 1, ifAbsent: () => 1);
    }

    for (final entry in speciesIds.entries) {
      if (entry.value > 1) {
        collector.addError(
          'species.duplicate_id',
          'Multiple species files share the id "${entry.key}".',
          'species:${entry.key}',
        );
      }
    }

    final validSpeciesIds = speciesIds.keys.toSet();
    final validLearnsetIds = learnsetRecords
        .map((record) => record.learnset.speciesId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final validEvolutionIds = evolutionRecords
        .map((record) => record.evolution.speciesId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final record in speciesRecords) {
      final species = record.species;
      if (species.learnsetRef.trim().isNotEmpty &&
          !validLearnsetIds.contains(species.learnsetRef.trim())) {
        collector.addError(
          'species.learnset_ref_missing',
          'Species "${species.id}" references a missing learnset '
          '"${species.learnsetRef}".',
          record.location,
        );
      }
      if (species.evolutionRef.trim().isNotEmpty &&
          !validEvolutionIds.contains(species.evolutionRef.trim())) {
        collector.addError(
          'species.evolution_ref_missing',
          'Species "${species.id}" references a missing evolution '
          '"${species.evolutionRef}".',
          record.location,
        );
      }
    }

    for (final record in learnsetRecords) {
      final speciesId = record.learnset.speciesId.trim();
      if (speciesId.isNotEmpty && !validSpeciesIds.contains(speciesId)) {
        collector.addError(
          'learnset.species_missing',
          'Learnset "${record.fileId}" references missing species "$speciesId".',
          record.location,
        );
      }
    }

    for (final record in evolutionRecords) {
      final evolution = record.evolution;
      final speciesId = evolution.speciesId.trim();
      if (speciesId.isNotEmpty && !validSpeciesIds.contains(speciesId)) {
        collector.addError(
          'evolution.species_missing',
          'Evolution "${record.fileId}" references missing species "$speciesId".',
          record.location,
        );
      }

      for (final entry in evolution.evolutions) {
        final targetSpeciesId = entry.targetSpeciesId.trim();
        if (targetSpeciesId.isNotEmpty &&
            !validSpeciesIds.contains(targetSpeciesId)) {
          collector.addError(
            'evolution.target_species_missing',
            'Evolution "${speciesId.isEmpty ? record.fileId : speciesId}" '
            'targets missing species "$targetSpeciesId".',
            record.location,
          );
        }
      }
    }

    final movesCatalogIds = await _loadCatalogEntryIds(
      workspace,
      collector,
      catalogKey: 'moves',
      location: 'catalog:moves',
      missingCatalogCode: 'catalog.moves_missing',
      unreadableCatalogCode: 'catalog.moves_unreadable',
      missingCatalogMessage:
          'Moves catalog is unavailable; move reference validation was skipped.',
      unreadableCatalogMessage:
          'Moves catalog could not be read; move reference validation was skipped.',
    );

    if (movesCatalogIds != null) {
      for (final record in learnsetRecords) {
        final usedMoveIds = <String>{
          ...record.learnset.startingMoves.map((value) => value.trim()),
          ...record.learnset.relearnMoves.map((value) => value.trim()),
          ...record.learnset.levelUp.map((entry) => entry.moveId.trim()),
        }..remove('');

        for (final moveId in usedMoveIds) {
          if (!movesCatalogIds.contains(moveId)) {
            collector.addError(
              'learnset.move_missing_in_catalog',
              'Learnset "${record.fileId}" references move "$moveId" '
              'which is absent from the moves catalog.',
              record.location,
            );
          }
        }
      }
    }

    final typesCatalogIds = await _loadCatalogEntryIds(
      workspace,
      collector,
      catalogKey: 'types',
      location: 'catalog:types',
      missingCatalogCode: 'catalog.types_missing',
      unreadableCatalogCode: 'catalog.types_unreadable',
      missingCatalogMessage:
          'Types catalog is unavailable; type reference validation was skipped.',
      unreadableCatalogMessage:
          'Types catalog could not be read; type reference validation was skipped.',
    );

    if (typesCatalogIds != null) {
      for (final record in speciesRecords) {
        for (final typeId in record.species.typing.types.map((value) => value.trim())) {
          if (typeId.isEmpty) {
            continue;
          }
          if (!typesCatalogIds.contains(typeId)) {
            collector.addError(
              'species.type_missing_in_catalog',
              'Species "${record.species.id}" references type "$typeId" '
              'which is absent from the types catalog.',
              record.location,
            );
          }
        }
      }
    }

    return PokemonValidationReport(
      issues: collector.build(),
    );
  }

  Future<List<_LoadedSpeciesRecord>> _loadSpecies(
    ProjectWorkspace workspace,
    _PokemonValidationIssueCollector collector,
  ) async {
    final speciesFiles = await _safeListFiles(
      collector,
      code: 'species.directory_unreadable',
      message:
          'Pokemon species directory could not be listed; species validation may be incomplete.',
      location: 'species',
      loader: () => repository.listSpeciesFiles(workspace),
    );

    final records = <_LoadedSpeciesRecord>[];
    for (final relativePath in speciesFiles) {
      try {
        final species = await repository.readSpeciesByRelativePath(
          workspace,
          relativePath,
        );
        final location = 'species:$relativePath';
        _validateSpecies(species, location, collector);
        records.add(
          _LoadedSpeciesRecord(
            relativePath: relativePath,
            location: location,
            species: species,
          ),
        );
      } on EditorApplicationException catch (error) {
        collector.addError(
          'species.read_error',
          error.message,
          'species:$relativePath',
        );
      }
    }
    return records;
  }

  Future<List<_LoadedLearnsetRecord>> _loadLearnsets(
    ProjectWorkspace workspace,
    _PokemonValidationIssueCollector collector,
  ) async {
    final learnsetIds = await _safeListFiles(
      collector,
      code: 'learnsets.directory_unreadable',
      message:
          'Pokemon learnsets directory could not be listed; learnset validation may be incomplete.',
      location: 'learnsets',
      loader: () => repository.listLearnsetIds(workspace),
    );

    final records = <_LoadedLearnsetRecord>[];
    for (final fileId in learnsetIds) {
      try {
        final learnset = await repository.readLearnsetById(workspace, fileId);
        final location = 'learnset:$fileId';
        _validateLearnset(learnset, location, collector);
        records.add(
          _LoadedLearnsetRecord(
            fileId: fileId,
            location: location,
            learnset: learnset,
          ),
        );
      } on EditorApplicationException catch (error) {
        collector.addError(
          'learnset.read_error',
          error.message,
          'learnset:$fileId',
        );
      }
    }
    return records;
  }

  Future<List<_LoadedEvolutionRecord>> _loadEvolutions(
    ProjectWorkspace workspace,
    _PokemonValidationIssueCollector collector,
  ) async {
    final evolutionIds = await _safeListFiles(
      collector,
      code: 'evolutions.directory_unreadable',
      message:
          'Pokemon evolutions directory could not be listed; evolution validation may be incomplete.',
      location: 'evolutions',
      loader: () => repository.listEvolutionIds(workspace),
    );

    final records = <_LoadedEvolutionRecord>[];
    for (final fileId in evolutionIds) {
      try {
        final evolution = await repository.readEvolutionById(workspace, fileId);
        final location = 'evolution:$fileId';
        _validateEvolution(evolution, location, collector);
        records.add(
          _LoadedEvolutionRecord(
            fileId: fileId,
            location: location,
            evolution: evolution,
          ),
        );
      } on EditorApplicationException catch (error) {
        collector.addError(
          'evolution.read_error',
          error.message,
          'evolution:$fileId',
        );
      }
    }
    return records;
  }

  Future<List<String>> _safeListFiles(
    _PokemonValidationIssueCollector collector, {
    required String code,
    required String message,
    required String location,
    required Future<List<String>> Function() loader,
  }) async {
    try {
      return await loader();
    } on EditorApplicationException catch (error) {
      collector.addError(
        code,
        '$message ${error.message}',
        location,
      );
      return const <String>[];
    }
  }

  Future<Set<String>?> _loadCatalogEntryIds(
    ProjectWorkspace workspace,
    _PokemonValidationIssueCollector collector, {
    required String catalogKey,
    required String location,
    required String missingCatalogCode,
    required String unreadableCatalogCode,
    required String missingCatalogMessage,
    required String unreadableCatalogMessage,
  }) async {
    try {
      final catalog = await repository.readCatalogByKey(workspace, catalogKey);
      return catalog.entries
          .map((entry) => (entry['id'] as String?)?.trim() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } on EditorNotFoundException catch (error) {
      collector.addWarning(
        missingCatalogCode,
        '$missingCatalogMessage ${error.message}',
        location,
      );
      return null;
    } on EditorApplicationException catch (error) {
      collector.addError(
        unreadableCatalogCode,
        '$unreadableCatalogMessage ${error.message}',
        location,
      );
      return null;
    }
  }

  void _validateSpecies(
    PokemonSpeciesFile species,
    String location,
    _PokemonValidationIssueCollector collector,
  ) {
    if (species.id.trim().isEmpty) {
      collector.addError(
        'species.id_empty',
        'Species id cannot be empty.',
        location,
      );
    }

    if (species.nationalDex <= 0) {
      collector.addError(
        'species.national_dex_invalid',
        'Species "${species.id}" must have nationalDex > 0.',
        location,
      );
    }

    final primaryName = _pickPrimarySpeciesName(species);
    if (primaryName == null || primaryName.isEmpty) {
      collector.addError(
        'species.display_name_missing',
        'Species "${species.id}" does not expose a usable primary name.',
        location,
      );
    }

    final nonEmptyTypes = species.typing.types
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty)
        .toList(growable: false);
    if (nonEmptyTypes.isEmpty) {
      collector.addError(
        'species.types_empty',
        'Species "${species.id}" must define at least one type.',
        location,
      );
    }

    final duplicateTypes = _findDuplicateValues(nonEmptyTypes);
    for (final duplicateType in duplicateTypes) {
      collector.addError(
        'species.type_duplicate',
        'Species "${species.id}" declares duplicate type "$duplicateType".',
        location,
      );
    }

    if (species.learnsetRef.trim().isEmpty) {
      collector.addError(
        'species.learnset_ref_empty',
        'Species "${species.id}" must define a learnsetRef.',
        location,
      );
    }

    if (species.evolutionRef.trim().isEmpty) {
      collector.addError(
        'species.evolution_ref_empty',
        'Species "${species.id}" must define an evolutionRef.',
        location,
      );
    }
  }

  void _validateLearnset(
    PokemonLearnsetFile learnset,
    String location,
    _PokemonValidationIssueCollector collector,
  ) {
    if (learnset.speciesId.trim().isEmpty) {
      collector.addError(
        'learnset.species_id_empty',
        'Learnset speciesId cannot be empty.',
        location,
      );
    }

    for (final moveId in learnset.startingMoves) {
      if (moveId.trim().isEmpty) {
        collector.addError(
          'learnset.starting_move_empty',
          'Learnset "${learnset.speciesId}" contains an empty starting move id.',
          location,
        );
      }
    }

    for (final moveId in learnset.relearnMoves) {
      if (moveId.trim().isEmpty) {
        collector.addError(
          'learnset.relearn_move_empty',
          'Learnset "${learnset.speciesId}" contains an empty relearn move id.',
          location,
        );
      }
    }

    final levelUpKeys = <String>{};
    for (final entry in learnset.levelUp) {
      if (entry.moveId.trim().isEmpty) {
        collector.addError(
          'learnset.level_up_move_empty',
          'Learnset "${learnset.speciesId}" contains a level-up entry with an empty moveId.',
          location,
        );
      }
      if (entry.level < 1) {
        collector.addError(
          'learnset.level_up_level_invalid',
          'Learnset "${learnset.speciesId}" contains a level-up entry with level < 1.',
          location,
        );
      }

      final key = '${entry.moveId.trim()}|${entry.level}|${entry.source.trim()}|'
          '${entry.versionGroup.trim()}';
      if (!levelUpKeys.add(key)) {
        collector.addError(
          'learnset.level_up_duplicate',
          'Learnset "${learnset.speciesId}" contains a duplicate level-up entry '
          'for (${entry.moveId}, ${entry.level}, ${entry.source}, ${entry.versionGroup}).',
          location,
        );
      }
    }
  }

  void _validateEvolution(
    PokemonEvolutionFile evolution,
    String location,
    _PokemonValidationIssueCollector collector,
  ) {
    if (evolution.speciesId.trim().isEmpty) {
      collector.addError(
        'evolution.species_id_empty',
        'Evolution speciesId cannot be empty.',
        location,
      );
    }

    for (final entry in evolution.evolutions) {
      final targetSpeciesId = entry.targetSpeciesId.trim();
      if (targetSpeciesId.isEmpty) {
        collector.addError(
          'evolution.target_species_empty',
          'Evolution "${evolution.speciesId}" contains an empty targetSpeciesId.',
          location,
        );
      }
      if (targetSpeciesId.isNotEmpty &&
          targetSpeciesId == evolution.speciesId.trim()) {
        collector.addError(
          'evolution.self_target',
          'Evolution "${evolution.speciesId}" cannot target itself.',
          location,
        );
      }
      if (entry.method.trim() == 'level_up' &&
          entry.minLevel != null &&
          entry.minLevel! < 1) {
        collector.addError(
          'evolution.min_level_invalid',
          'Evolution "${evolution.speciesId}" has level_up with minLevel < 1.',
          location,
        );
      }
    }
  }

  String? _pickPrimarySpeciesName(PokemonSpeciesFile species) {
    final englishName = species.names['en']?.trim();
    if (englishName != null && englishName.isNotEmpty) {
      return englishName;
    }

    final frenchName = species.names['fr']?.trim();
    if (frenchName != null && frenchName.isNotEmpty) {
      return frenchName;
    }

    final speciesId = species.id.trim();
    if (speciesId.isNotEmpty) {
      return speciesId;
    }

    return null;
  }

  Set<String> _findDuplicateValues(List<String> values) {
    final seen = <String>{};
    final duplicates = <String>{};
    for (final value in values) {
      if (!seen.add(value)) {
        duplicates.add(value);
      }
    }
    return duplicates;
  }
}

class _LoadedSpeciesRecord {
  const _LoadedSpeciesRecord({
    required this.relativePath,
    required this.location,
    required this.species,
  });

  final String relativePath;
  final String location;
  final PokemonSpeciesFile species;
}

class _LoadedLearnsetRecord {
  const _LoadedLearnsetRecord({
    required this.fileId,
    required this.location,
    required this.learnset,
  });

  final String fileId;
  final String location;
  final PokemonLearnsetFile learnset;
}

class _LoadedEvolutionRecord {
  const _LoadedEvolutionRecord({
    required this.fileId,
    required this.location,
    required this.evolution,
  });

  final String fileId;
  final String location;
  final PokemonEvolutionFile evolution;
}

class _PokemonValidationIssueCollector {
  final List<PokemonValidationIssue> _issues = <PokemonValidationIssue>[];

  void addError(String code, String message, String location) {
    _issues.add(
      PokemonValidationIssue(
        severity: PokemonValidationSeverity.error,
        code: code,
        message: message,
        location: location,
      ),
    );
  }

  void addWarning(String code, String message, String location) {
    _issues.add(
      PokemonValidationIssue(
        severity: PokemonValidationSeverity.warning,
        code: code,
        message: message,
        location: location,
      ),
    );
  }

  List<PokemonValidationIssue> build() {
    final issues = List<PokemonValidationIssue>.from(_issues);
    issues.sort((left, right) {
      final severityCompare =
          _severityRank(left.severity).compareTo(_severityRank(right.severity));
      if (severityCompare != 0) {
        return severityCompare;
      }

      final locationCompare = left.location.compareTo(right.location);
      if (locationCompare != 0) {
        return locationCompare;
      }

      final codeCompare = left.code.compareTo(right.code);
      if (codeCompare != 0) {
        return codeCompare;
      }

      return left.message.compareTo(right.message);
    });
    return issues;
  }

  int _severityRank(PokemonValidationSeverity severity) {
    switch (severity) {
      case PokemonValidationSeverity.error:
        return 0;
      case PokemonValidationSeverity.warning:
        return 1;
    }
  }
}
```

### 14.3 `packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`

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

### 14.4 `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
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

### 14.5 `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/errors/application_errors.dart';
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
    final trimmedKey = catalogKey.trim();
    final payloadCatalog = catalog.catalog.trim();
    if (payloadCatalog != trimmedKey) {
      throw EditorValidationException(
        'Pokemon catalog key mismatch: requested "$trimmedKey" but payload is '
        '"$payloadCatalog"',
      );
    }
    final relativePath = _catalogRelativePaths[trimmedKey];
    if (relativePath == null) {
      throw EditorNotFoundException(
        'Pokemon catalog write path not declared for key: $catalogKey',
      );
    }
    await _writeJsonObject(workspace, relativePath, catalog.toJson());
  }

  @override
  Future<void> saveSpecies(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) async {
    final relativePath = await _resolveSpeciesWritePath(workspace, species);
    await _writeJsonObject(workspace, relativePath, species.toJson());
  }

  @override
  Future<void> saveLearnset(
    ProjectWorkspace workspace,
    PokemonLearnsetFile learnset,
  ) async {
    final speciesId = learnset.speciesId.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon learnset speciesId cannot be empty',
      );
    }
    await _writeJsonObject(
      workspace,
      'data/pokemon/learnsets/$speciesId.json',
      learnset.toJson(),
    );
  }

  @override
  Future<void> saveEvolution(
    ProjectWorkspace workspace,
    PokemonEvolutionFile evolution,
  ) async {
    final speciesId = evolution.speciesId.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon evolution speciesId cannot be empty',
      );
    }
    await _writeJsonObject(
      workspace,
      'data/pokemon/evolutions/$speciesId.json',
      evolution.toJson(),
    );
  }

  Future<void> _writeJsonObject(
    ProjectWorkspace workspace,
    String relativePath,
    Map<String, Object?> payload,
  ) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    await workspace.ensureDirectoryExists(absolutePath);
    final file = File(absolutePath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  Future<String> _resolveSpeciesWritePath(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) async {
    final trimmedId = species.id.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException('Pokemon species id cannot be empty');
    }

    final speciesDirectory = Directory(
      workspace.resolveProjectRelativePath('data/pokemon/species'),
    );
    if (!await speciesDirectory.exists()) {
      return 'data/pokemon/species/${_speciesFileName(species)}';
    }

    final existingPath = await reader.resolveSpeciesRelativePathById(
      workspace,
      trimmedId,
    );
    if (existingPath != null) {
      return existingPath;
    }

    return 'data/pokemon/species/${_speciesFileName(species)}';
  }

  String _speciesFileName(PokemonSpeciesFile species) {
    final dex = species.nationalDex.toString().padLeft(4, '0');
    final slug = _sanitizeFileSegment(species.slug.isNotEmpty ? species.slug : species.id);
    return '$dex-$slug.json';
  }

  String _sanitizeFileSegment(String value) {
    final normalized = value.trim().toLowerCase();
    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
    final collapsed = safe.replaceAll(RegExp(r'_+'), '_');
    final trimmed = collapsed.replaceAll(RegExp(r'^_|_$'), '');
    return trimmed.isEmpty ? 'pokemon' : p.basename(trimmed);
  }
}
```

### 14.6 `packages/map_editor/lib/src/application/use_cases/validate_pokemon_project_data_use_case.dart`

```dart
import '../models/pokemon_validation_report.dart';
import '../ports/project_workspace.dart';
import '../services/pokemon_project_validator.dart';

class ValidatePokemonProjectDataUseCase {
  const ValidatePokemonProjectDataUseCase(this.validator);

  final PokemonProjectValidator validator;

  Future<PokemonValidationReport> execute(ProjectWorkspace workspace) {
    return validator.validate(workspace);
  }
}
```

### 14.7 `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

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
export 'validate_pokemon_project_data_use_case.dart';
export 'warp_use_cases.dart';
```

### 14.8 `packages/map_editor/test/validate_pokemon_project_data_use_case_test.dart`

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

## 15. Mini conclusion honnête

Le lot 9 pose une base de validation locale utile sans partir dans l’usine a gaz :

- un seul rapport structure ;
- un seul service de validation ;
- un use case simple ;
- zero mutation ;
- zero dependance UI ;
- zero changement de `project.json`.

Ce qui reste volontairement simple :

- la validation n’essaie pas d’etre exhaustive sur toutes les regles Pokemon officielles ;
- les catalogues globaux restent peu types ;
- on ne corrige rien automatiquement ;
- on ne fait ni import ni edition.

La base est maintenant suffisamment propre pour les prochains lots d’edition et d’import, sans melanger lecture filesystem, validation metier lourde et UI.
