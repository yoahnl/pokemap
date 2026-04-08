# Pokemon Write Repositories Lot 8c Mini-Fix Report

## 1. Resume executif

### Probleme exact

Le writer Pokemon restait couple a la projection globale des especes :

- `FilePokemonWriteRepository.saveSpecies()` appelait indirectement `reader.listSpeciesIndexEntries(workspace)` ;
- pour reecrire une seule espece, on reconstruisait donc tout l'index leger ;
- cela parsait tous les fichiers JSON de `data/pokemon/species/` ;
- un JSON espece invalide mais non lie pouvait faire echouer l'ecriture d'une autre espece valide.

### Correction appliquee

J'ai introduit une resolution dediee de chemin d'espece :

```dart
Future<String?> resolveSpeciesRelativePathById(
  ProjectWorkspace workspace,
  String speciesId,
)
```

Cette resolution :

- ne depend plus de `listSpeciesIndexEntries()` ;
- ne parse aucun JSON espece ;
- s'appuie uniquement sur la convention de fichiers species deja assumee ;
- retourne :
  - `relativePath` si un seul fichier correspond ;
  - `null` si aucun fichier ne correspond ;
  - une `EditorConflictException` si plusieurs fichiers correspondent.

`FilePokemonWriteRepository` utilise maintenant cette resolution dediee pour `saveSpecies()`.

### Ce qui n'a pas ete change

- aucune UI ;
- aucun provider ;
- aucun runtime ;
- aucun changement de `project.json` ;
- aucun changement de format JSON ;
- aucun changement du seed ;
- aucun ajout media ;
- aucune refonte du port de lecture ou du port d'ecriture.

## 2. Probleme initial

Dependre de `listSpeciesIndexEntries()` pour ecrire une espece etait mauvais pour trois raisons :

1. reconstruction globale inutile
   - on reconstruisait une projection globale alors qu'on voulait juste retrouver le fichier d'une espece ;
2. parsing global inutile
   - tous les JSON species etaient parses pour une operation d'ecriture ciblee ;
3. fragilite excessive
   - un fichier JSON species invalide et non concerne pouvait faire echouer la reecriture d'une espece valide.

Pour une base locale propre, ce couplage etait trop fragile.

## 3. Solution retenue

### Nouvelle strategie de resolution dediee

La resolution de chemin est maintenant centralisee dans `PokemonProjectDataReader` :

- elle scanne uniquement les noms de fichiers du dossier `data/pokemon/species/` ;
- elle ne parse pas les fichiers JSON ;
- elle utilise uniquement la convention de nommage deja supportee :
  - `<id>.json`
  - ou `*-<id>.json`

### Comportement sur 0 / 1 / plusieurs matchs

- 0 match :
  - retourne `null`
  - le writer cree un nouveau fichier selon la convention existante
- 1 match :
  - retourne le `relativePath` existant
  - le writer ecrase ce fichier
- plusieurs matchs :
  - leve une `EditorConflictException` explicite
  - aucune ecriture n'a lieu

### Pourquoi c'est mieux

- l'ecriture d'une espece existante ne depend plus de l'index global ;
- un JSON invalide non lie ne casse plus la reecriture d'une espece ciblee ;
- la logique de resolution de chemin est centralisee ;
- le writer reste petit et previsible.

## 4. Fichiers modifies

Fichiers modifies dans ce mini-fix :

- `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_editor/test/file_pokemon_write_repository_test.dart`
- `reports/pokemon-write-repositories-lot-8c-mini-fix-report.md`

Note honnete :

Le working tree contient encore d'autres changements venant du lot 8 precedent :

- `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart`
- `reports/pokemon-write-repositories-lot-8-report.md`
- `reports/pokemon-write-repositories-lot-8b-mini-fix-report.md`

Ils apparaissent dans `git status`, mais ils ne font pas partie du code modifie pour ce mini-fix 8c.

## 5. Tests reellement executes

Commandes executees :

```bash
flutter test test/file_pokemon_write_repository_test.dart
flutter test test/file_pokemon_read_repository_test.dart
flutter analyze --no-pub lib/src/application/services/pokemon_project_data_reader.dart lib/src/infrastructure/repositories/file_repositories.dart test/file_pokemon_write_repository_test.dart test/file_pokemon_read_repository_test.dart
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
git status --short
git diff --stat -- packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart packages/map_editor/test/file_pokemon_write_repository_test.dart reports/pokemon-write-repositories-lot-8c-mini-fix-report.md
git ls-files --others --exclude-standard packages/map_editor/test/file_pokemon_write_repository_test.dart reports/pokemon-write-repositories-lot-8c-mini-fix-report.md
./review_bundle.sh
```

## 6. Resultats reels des tests

### 6.1 `flutter test test/file_pokemon_write_repository_test.dart`

Sortie utile :

```text
00:01 +11: All tests passed!
```

Points verifies explicitement :

- une espece existante est reecrite meme si un JSON species non lie est invalide ;
- pas de doublon si le slug change ;
- conflit explicite si plusieurs fichiers peuvent correspondre au meme id ;
- `project.json` reste inchange ;
- rien n'est cree a la racine du monorepo ;
- le mismatch catalogue reste bien bloque avant ecriture.

### 6.2 `flutter test test/file_pokemon_read_repository_test.dart`

Sortie utile :

```text
00:01 +6: All tests passed!
```

Ce rerun confirme que le mini-fix d'ecriture n'a pas casse la lecture locale existante.

## 7. Analyse reellement executee

Commande :

```bash
flutter analyze --no-pub lib/src/application/services/pokemon_project_data_reader.dart lib/src/infrastructure/repositories/file_repositories.dart test/file_pokemon_write_repository_test.dart test/file_pokemon_read_repository_test.dart
```

Resultat :

```text
No issues found! (ran in 1.4s)
```

## 8. Verifications de perimetre

### 8.1 `project.json` reste strictement inchange

Le test existant `leaves project.json strictly unchanged` continue de passer dans `file_pokemon_write_repository_test.dart`.

### 8.2 Rien n'est recree a la racine du monorepo

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

n'ont ete recrees a la racine du monorepo.

## 9. Etat Git utile

### 9.1 `git status --short`

```text
 M packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
 M packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
?? packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart
?? packages/map_editor/test/file_pokemon_write_repository_test.dart
?? reports/pokemon-write-repositories-lot-8-report.md
?? reports/pokemon-write-repositories-lot-8b-mini-fix-report.md
?? reports/pokemon-write-repositories-lot-8c-mini-fix-report.md
```

### 9.2 `git diff --stat` cible

Commande :

```bash
git diff --stat -- packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart packages/map_editor/test/file_pokemon_write_repository_test.dart reports/pokemon-write-repositories-lot-8c-mini-fix-report.md
```

Sortie :

```text
 .../services/pokemon_project_data_reader.dart      |  53 +++++++
 .../repositories/file_repositories.dart            | 161 +++++++++++++++++++++
 2 files changed, 214 insertions(+)
```

Note honnete :

- cette sortie ne montre pas le fichier de test ni le rapport, car ils sont encore non suivis par Git ;
- le diff est donc partiel si on le lit sans cette information.

### 9.3 `git ls-files --others --exclude-standard`

Commande :

```bash
git ls-files --others --exclude-standard packages/map_editor/test/file_pokemon_write_repository_test.dart reports/pokemon-write-repositories-lot-8c-mini-fix-report.md
```

Sortie :

```text
packages/map_editor/test/file_pokemon_write_repository_test.dart
reports/pokemon-write-repositories-lot-8c-mini-fix-report.md
```

## 10. Execution obligatoire de `./review_bundle.sh`

Commande executee :

```bash
./review_bundle.sh
```

Chemin du fichier genere :

```text
.review/review-20260409-001303.txt
```

## 11. Contenu integral du bundle

```text
# REVIEW BUNDLE

Generated at: 2026-04-09 00:13:03
Repository: pokemonProject
Branch: main
Base ref: HEAD
Head commit: ff4a9289330aa2fa3cb39505270f5a7ad1aa4673

## GIT STATUS --SHORT

 M packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
 M packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
?? packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart
?? packages/map_editor/test/file_pokemon_write_repository_test.dart
?? reports/pokemon-write-repositories-lot-8-report.md
?? reports/pokemon-write-repositories-lot-8b-mini-fix-report.md
?? reports/pokemon-write-repositories-lot-8c-mini-fix-report.md

## GIT DIFF --STAT

 .../models/pokemon_project_data_models.dart        | 179 +++++++++++++++++++++
 .../services/pokemon_project_data_reader.dart      |  53 ++++++
 .../repositories/file_repositories.dart            | 161 ++++++++++++++++++
 3 files changed, 393 insertions(+)

## CHANGED FILES

packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart

## RECENT COMMITS

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
e63e6cf Add element collision authoring services and padding-based workflow

## FULL DIFF

diff --git a/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart b/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
index b96f0e9..283aca0 100644
--- a/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
+++ b/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
@@ -20,6 +20,14 @@ class PokemonDataMeta {
       notes: _readStringList(json['notes']),
     );
   }
+
+  Map<String, Object?> toJson() {
+    return <String, Object?>{
+      'description': description,
+      'sourcePriority': List<String>.from(sourcePriority),
+      'notes': List<String>.from(notes),
+    };
+  }
 }
 
 class PokemonDataManifest {
@@ -49,6 +57,16 @@ class PokemonDataManifest {
       futureDataFolders: _readStringMap(json['futureDataFolders']),
     );
   }
+
+  Map<String, Object?> toJson() {
+    return <String, Object?>{
+      'schemaVersion': schemaVersion,
+      'kind': kind,
+      'meta': meta.toJson(),
+      'catalogFiles': Map<String, String>.from(catalogFiles),
+      'futureDataFolders': Map<String, String>.from(futureDataFolders),
+    };
+  }
 }
 
 /// Catalogue Pokemon generique.
@@ -87,6 +105,18 @@ class PokemonCatalogFile {
           .toList(growable: false),
     );
   }
+
+  Map<String, Object?> toJson() {
+    return <String, Object?>{
+      'schemaVersion': schemaVersion,
+      'kind': kind,
+      'catalog': catalog,
+      'meta': meta.toJson(),
+      'entries': entries
+          .map((entry) => _deepCopyJsonMap(entry))
+          .toList(growable: false),
+    };
+  }
 }
 
 /// Projection legere d'une espece pour les futurs usages liste/index.
@@ -140,6 +170,12 @@ class PokemonSpeciesTyping {
   factory PokemonSpeciesTyping.fromJson(Map<String, dynamic> json) {
     return PokemonSpeciesTyping(types: _readStringList(json['types']));
   }
+
+  Map<String, Object?> toJson() {
+    return <String, Object?>{
+      'types': List<String>.from(types),
+    };
+  }
 }
 
 class PokemonSpeciesBaseStats {
@@ -172,6 +208,18 @@ class PokemonSpeciesBaseStats {
       bst: (json['bst'] as num?)?.toInt() ?? 0,
     );
   }
+
+  Map<String, Object?> toJson() {
+    return <String, Object?>{
+      'hp': hp,
+      'atk': atk,
+      'def': def,
+      'spa': spa,
+      'spd': spd,
+      'spe': spe,
+      'bst': bst,
+    };
+  }
 }
 
 class PokemonSpeciesAbilities {
@@ -192,6 +240,14 @@ class PokemonSpeciesAbilities {
       hidden: (json['hidden'] as String?)?.trim(),
     );
   }
+
+  Map<String, Object?> toJson() {
+    return <String, Object?>{
+      'primary': primary,
+      'secondary': secondary,
+      'hidden': hidden,
+    };
+  }
 }
 
 class PokemonSpeciesBreeding {
@@ -217,6 +273,16 @@ class PokemonSpeciesBreeding {
       hatchCycles: (json['hatchCycles'] as num?)?.toInt() ?? 0,
     );
   }
+
+  Map<String, Object?> toJson() {
+    return <String, Object?>{
+      'genderRatio': genderRatio.map(
+        (key, value) => MapEntry(key, value),
+      ),
+      'eggGroups': List<String>.from(eggGroups),
+      'hatchCycles': hatchCycles,
+    };
+  }
 }
 
 class PokemonSpeciesProgression {
@@ -240,6 +306,15 @@ class PokemonSpeciesProgression {
       baseFriendship: (json['baseFriendship'] as num?)?.toInt() ?? 0,
     );
   }
+
+  Map<String, Object?> toJson() {
+    return <String, Object?>{
+      'growthRateId': growthRateId,
+      'baseExp': baseExp,
+      'catchRate': catchRate,
+      'baseFriendship': baseFriendship,
+    };
+  }
 }
 
 class PokemonSpeciesDexContent {
@@ -263,6 +338,15 @@ class PokemonSpeciesDexContent {
       flavorText: _readOptionalTrimmedString(json['flavorText']),
     );
   }
+
+  Map<String, Object?> toJson() {
+    return <String, Object?>{
+      'heightM': heightM,
+      'weightKg': weightKg,
+      'color': color,
+      'flavorText': flavorText,
+    };
+  }
 }
 
 class PokemonSpeciesGameplayFlags {
@@ -283,6 +367,14 @@ class PokemonSpeciesGameplayFlags {
       tradeOnly: _readBool(json['tradeOnly']),
     );
   }
+
+  Map<String, Object?> toJson() {
+    return <String, Object?>{
+      'starterEligible': starterEligible,
+      'giftOnly': giftOnly,
+      'tradeOnly': tradeOnly,
+    };
+  }
 }
 
 class PokemonSpeciesSourceMeta {
@@ -300,6 +392,13 @@ class PokemonSpeciesSourceMeta {
       seedVersion: (json['seedVersion'] as num?)?.toInt(),
     );
   }
+
+  Map<String, Object?> toJson() {
+    return <String, Object?>{
+      'seededBy': seededBy,
+      'seedVersion': seedVersion,
+    };
+  }
 }
 
 class PokemonSpeciesFile {
@@ -389,6 +488,29 @@ class PokemonSpeciesFile {
       ),
     );
   }
+
+  Map<String, Object?> toJson() {
+    return <String, Object?>{
+      'id': id,
+      'slug': slug,
+      'nationalDex': nationalDex,
+      'names': Map<String, String>.from(names),
+      'speciesName': Map<String, String>.from(speciesName),
+      'genIntroduced': genIntroduced,
+      'typing': typing.toJson(),
+      'baseStats': baseStats.toJson(),
+      'abilities': abilities.toJson(),
+      'breeding': breeding.toJson(),
+      'progression': progression.toJson(),
+      'evolutionRef': evolutionRef,
+      'learnsetRef': learnsetRef,
+      'spriteSetRef': spriteSetRef,
+      'cryRef': cryRef,
+      'dexContent': dexContent.toJson(),
+      'gameplayFlags': gameplayFlags.toJson(),
+      'sourceMeta': sourceMeta.toJson(),
+    };
+  }
 }
 
 class PokemonLearnsetLevelUpEntry {
@@ -412,6 +534,15 @@ class PokemonLearnsetLevelUpEntry {
       versionGroup: (json['versionGroup'] as String?)?.trim() ?? '',
     );
   }
+
+  Map<String, Object?> toJson() {
+    return <String, Object?>{
+      'moveId': moveId,
+      'level': level,
+      'source': source,
+      'versionGroup': versionGroup,
+    };
+  }
 }
 
 class PokemonLearnsetFile {
@@ -444,6 +575,15 @@ class PokemonLearnsetFile {
           .toList(growable: false),
     );
   }
+
+  Map<String, Object?> toJson() {
+    return <String, Object?>{
+      'speciesId': speciesId,
+      'startingMoves': List<String>.from(startingMoves),
+      'relearnMoves': List<String>.from(relearnMoves),
+      'levelUp': levelUp.map((entry) => entry.toJson()).toList(growable: false),
+    };
+  }
 }
 
 class PokemonEvolutionEntry {
@@ -464,6 +604,14 @@ class PokemonEvolutionEntry {
       minLevel: (json['minLevel'] as num?)?.toInt(),
     );
   }
+
+  Map<String, Object?> toJson() {
+    return <String, Object?>{
+      'targetSpeciesId': targetSpeciesId,
+      'method': method,
+      'minLevel': minLevel,
+    };
+  }
 }
 
 class PokemonEvolutionFile {
@@ -491,6 +639,16 @@ class PokemonEvolutionFile {
           .toList(growable: false),
     );
   }
+
+  Map<String, Object?> toJson() {
+    return <String, Object?>{
+      'speciesId': speciesId,
+      'preEvolution': preEvolution,
+      'evolutions': evolutions
+          .map((entry) => entry.toJson())
+          .toList(growable: false),
+    };
+  }
 }
 
 List<String> _readStringList(Object? raw) {
@@ -551,3 +709,24 @@ double? _readDouble(Object? raw) {
 bool _readBool(Object? raw) {
   return raw == true;
 }
+
+Map<String, dynamic> _deepCopyJsonMap(Map<String, dynamic> source) {
+  return source.map(
+    (key, value) => MapEntry(key, _deepCopyJsonValue(value)),
+  );
+}
+
+Object? _deepCopyJsonValue(Object? value) {
+  if (value is Map<String, dynamic>) {
+    return _deepCopyJsonMap(value);
+  }
+  if (value is Map) {
+    return value.map(
+      (key, nestedValue) => MapEntry(key.toString(), _deepCopyJsonValue(nestedValue)),
+    );
+  }
+  if (value is List) {
+    return value.map(_deepCopyJsonValue).toList(growable: false);
+  }
+  return value;
+}
diff --git a/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart b/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
index 9e18a7c..28d5ac7 100644
--- a/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
+++ b/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
@@ -132,6 +132,52 @@ class PokemonProjectDataReader {
     return _buildSpeciesIndexEntries(workspace);
   }
 
+  Future<String?> resolveSpeciesRelativePathById(
+    ProjectWorkspace workspace,
+    String speciesId,
+  ) async {
+    final trimmedId = speciesId.trim();
+    if (trimmedId.isEmpty) {
+      throw const EditorValidationException('Pokemon species id cannot be empty');
+    }
+
+    final speciesDir = _speciesDirectory(workspace);
+    if (!await speciesDir.exists()) {
+      return null;
+    }
+
+    final normalizedId = _sanitizeSpeciesFileSegment(trimmedId);
+    final matches = <String>[];
+
+    await for (final entity in speciesDir.list(recursive: false)) {
+      if (entity is! File) continue;
+      if (p.extension(entity.path).toLowerCase() != '.json') continue;
+
+      final basename = p.basename(entity.path).toLowerCase();
+      if (basename == '$normalizedId.json' ||
+          basename.endsWith('-$normalizedId.json')) {
+        matches.add(
+          p.normalize(p.relative(entity.path, from: workspace.projectRoot)),
+        );
+      }
+    }
+
+    matches.sort();
+
+    if (matches.length > 1) {
+      throw EditorConflictException(
+        'Multiple Pokemon species files match the id "$trimmedId": '
+        '${matches.join(', ')}',
+      );
+    }
+
+    if (matches.isEmpty) {
+      return null;
+    }
+
+    return matches.single;
+  }
+
   Future<List<PokemonSpeciesIndexEntry>> _buildSpeciesIndexEntries(
     ProjectWorkspace workspace,
   ) async {
@@ -194,6 +240,13 @@ class PokemonProjectDataReader {
     );
   }
 
+  String _sanitizeSpeciesFileSegment(String value) {
+    final normalized = value.trim().toLowerCase();
+    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
+    final collapsed = safe.replaceAll(RegExp(r'_+'), '_');
+    return collapsed.replaceAll(RegExp(r'^_|_$'), '');
+  }
+
   Future<Map<String, dynamic>> _readJsonFile(
     ProjectWorkspace workspace,
     String relativePath, {
diff --git a/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart b/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
index 05893b4..9425b59 100644
--- a/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
+++ b/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
@@ -3,9 +3,12 @@ import 'dart:io';
 
 import 'package:flutter/foundation.dart';
 import 'package:map_core/map_core.dart';
+import 'package:path/path.dart' as p;
 
+import '../../application/errors/application_errors.dart';
 import '../../application/models/pokemon_project_data_models.dart';
 import '../../application/ports/pokemon_read_repository.dart';
+import '../../application/ports/pokemon_write_repository.dart';
 import '../../application/ports/project_workspace.dart';
 import '../../application/services/pokemon_project_data_reader.dart';
 import '../../domain/repositories/repositories.dart';
@@ -182,3 +185,161 @@ class FilePokemonReadRepository implements PokemonReadRepository {
     return reader.readEvolutionById(workspace, speciesId);
   }
 }
+
+/// Implémentation filesystem/workspace de l'écriture locale Pokémon.
+///
+/// Cette classe écrit uniquement les JSON déjà stabilisés à ce stade :
+/// - catalogues globaux
+/// - espèces
+/// - learnsets
+/// - évolutions
+///
+/// Elle ne touche jamais à `project.json` et n'écrit jamais hors du workspace.
+class FilePokemonWriteRepository implements PokemonWriteRepository {
+  const FilePokemonWriteRepository({
+    this.reader = const PokemonProjectDataReader(),
+  });
+
+  /// Le repository d'écriture réutilise le lecteur local existant uniquement
+  /// pour résoudre le chemin réel d'une espèce déjà présente.
+  ///
+  /// Cela évite de dupliquer une logique fragile de lookup par id au moment de
+  /// l'écriture, tout en gardant la vérité métier côté JSON.
+  final PokemonProjectDataReader reader;
+
+  static const Map<String, String> _catalogRelativePaths = <String, String>{
+    'moves': 'data/pokemon/catalogs/moves.json',
+    'abilities': 'data/pokemon/catalogs/abilities.json',
+    'items': 'data/pokemon/catalogs/items.json',
+    'types': 'data/pokemon/catalogs/types.json',
+    'growth_rates': 'data/pokemon/catalogs/growth_rates.json',
+    'natures': 'data/pokemon/catalogs/natures.json',
+    'egg_groups': 'data/pokemon/catalogs/egg_groups.json',
+    'habitats': 'data/pokemon/catalogs/habitats.json',
+    'generations': 'data/pokemon/catalogs/generations.json',
+    'version_groups': 'data/pokemon/catalogs/version_groups.json',
+    'encounter_rules': 'data/pokemon/catalogs/encounter_rules.json',
+  };
+
+  @override
+  Future<void> saveCatalogByKey(
+    ProjectWorkspace workspace,
+    String catalogKey,
+    PokemonCatalogFile catalog,
+  ) async {
+    final trimmedKey = catalogKey.trim();
+    final payloadCatalog = catalog.catalog.trim();
+    if (payloadCatalog != trimmedKey) {
+      throw EditorValidationException(
+        'Pokemon catalog key mismatch: requested "$trimmedKey" but payload is '
+        '"$payloadCatalog"',
+      );
+    }
+    final relativePath = _catalogRelativePaths[trimmedKey];
+    if (relativePath == null) {
+      throw EditorNotFoundException(
+        'Pokemon catalog write path not declared for key: $catalogKey',
+      );
+    }
+    await _writeJsonObject(workspace, relativePath, catalog.toJson());
+  }
+
+  @override
+  Future<void> saveSpecies(
+    ProjectWorkspace workspace,
+    PokemonSpeciesFile species,
+  ) async {
+    final relativePath = await _resolveSpeciesWritePath(workspace, species);
+    await _writeJsonObject(workspace, relativePath, species.toJson());
+  }
+
+  @override
+  Future<void> saveLearnset(
+    ProjectWorkspace workspace,
+    PokemonLearnsetFile learnset,
+  ) async {
+    final speciesId = learnset.speciesId.trim();
+    if (speciesId.isEmpty) {
+      throw const EditorValidationException(
+        'Pokemon learnset speciesId cannot be empty',
+      );
+    }
+    await _writeJsonObject(
+      workspace,
+      'data/pokemon/learnsets/$speciesId.json',
+      learnset.toJson(),
+    );
+  }
+
+  @override
+  Future<void> saveEvolution(
+    ProjectWorkspace workspace,
+    PokemonEvolutionFile evolution,
+  ) async {
+    final speciesId = evolution.speciesId.trim();
+    if (speciesId.isEmpty) {
+      throw const EditorValidationException(
+        'Pokemon evolution speciesId cannot be empty',
+      );
+    }
+    await _writeJsonObject(
+      workspace,
+      'data/pokemon/evolutions/$speciesId.json',
+      evolution.toJson(),
+    );
+  }
+
+  Future<void> _writeJsonObject(
+    ProjectWorkspace workspace,
+    String relativePath,
+    Map<String, Object?> payload,
+  ) async {
+    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
+    await workspace.ensureDirectoryExists(absolutePath);
+    final file = File(absolutePath);
+    await file.writeAsString(
+      const JsonEncoder.withIndent('  ').convert(payload),
+    );
+  }
+
+  Future<String> _resolveSpeciesWritePath(
+    ProjectWorkspace workspace,
+    PokemonSpeciesFile species,
+  ) async {
+    final trimmedId = species.id.trim();
+    if (trimmedId.isEmpty) {
+      throw const EditorValidationException('Pokemon species id cannot be empty');
+    }
+
+    final speciesDirectory = Directory(
+      workspace.resolveProjectRelativePath('data/pokemon/species'),
+    );
+    if (!await speciesDirectory.exists()) {
+      return 'data/pokemon/species/${_speciesFileName(species)}';
+    }
+
+    final existingPath = await reader.resolveSpeciesRelativePathById(
+      workspace,
+      trimmedId,
+    );
+    if (existingPath != null) {
+      return existingPath;
+    }
+
+    return 'data/pokemon/species/${_speciesFileName(species)}';
+  }
+
+  String _speciesFileName(PokemonSpeciesFile species) {
+    final dex = species.nationalDex.toString().padLeft(4, '0');
+    final slug = _sanitizeFileSegment(species.slug.isNotEmpty ? species.slug : species.id);
+    return '$dex-$slug.json';
+  }
+
+  String _sanitizeFileSegment(String value) {
+    final normalized = value.trim().toLowerCase();
+    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
+    final collapsed = safe.replaceAll(RegExp(r'_+'), '_');
+    final trimmed = collapsed.replaceAll(RegExp(r'^_|_$'), '');
+    return trimmed.isEmpty ? 'pokemon' : p.basename(trimmed);
+  }
+}
```

Note honnete :

- le bundle n'est pas exhaustif pour ce mini-fix ;
- il ne montre pas le fichier de test untracked ni ce rapport dans le diff ;
- il inclut aussi `pokemon_project_data_models.dart`, qui vient encore du lot 8 precedent et n'a pas ete modifie par 8c.

## 12. Code integral de tous les fichiers modifies dans ce mini-fix

### 12.1 `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`

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
    final speciesDir = _speciesDirectory(workspace);
    if (!await speciesDir.exists()) {
      throw const EditorNotFoundException(
        'Pokemon species directory not found in project workspace',
      );
    }

    final relativePaths = <String>[];
    await for (final entity in speciesDir.list(recursive: false)) {
      if (entity is! File) continue;
      if (p.extension(entity.path).toLowerCase() != '.json') continue;
      final relativePath = p.normalize(
        p.relative(entity.path, from: workspace.projectRoot),
      );
      relativePaths.add(relativePath);
    }
    relativePaths.sort();
    return relativePaths;
  }

  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) async {
    return _buildSpeciesIndexEntries(workspace);
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

### 12.2 `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

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

### 12.3 `packages/map_editor/test/file_pokemon_write_repository_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late String repoRootPath;
  late ProjectFileSystem workspace;
  late InitializePokemonProjectStorageUseCase initializeStorage;
  late FilePokemonWriteRepository writeRepository;
  late FilePokemonReadRepository readRepository;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokemon_write_repo_');
    repoRootPath = _resolveRepositoryRootFromCurrentDirectory();
    workspace = ProjectFileSystem(tempProjectRoot.path);
    initializeStorage = const InitializePokemonProjectStorageUseCase();
    writeRepository = const FilePokemonWriteRepository();
    readRepository = const FilePokemonReadRepository();
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('FilePokemonWriteRepository', () {
    test('saves a species file in the project workspace', () async {
      final species = _bulbasaurSpecies();

      await writeRepository.saveSpecies(workspace, species);

      final file = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      expect(await file.exists(), isTrue);

      final decoded = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(decoded['id'], 'bulbasaur');

      final readBack = await readRepository.readSpeciesById(workspace, 'bulbasaur');
      expect(readBack.id, 'bulbasaur');
      expect(readBack.gameplayFlags.starterEligible, isTrue);
    });

    test('saves a learnset file in the project workspace', () async {
      final learnset = _bulbasaurLearnset();

      await writeRepository.saveLearnset(workspace, learnset);

      final file = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/learnsets/bulbasaur.json',
        ),
      );
      expect(await file.exists(), isTrue);

      final readBack = await readRepository.readLearnsetById(workspace, 'bulbasaur');
      expect(readBack.speciesId, 'bulbasaur');
      expect(readBack.levelUp.first.moveId, 'tackle');
      expect(readBack.levelUp.first.level, 1);
    });

    test('saves an evolution file in the project workspace', () async {
      final evolution = _bulbasaurEvolution();

      await writeRepository.saveEvolution(workspace, evolution);

      final file = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/evolutions/bulbasaur.json',
        ),
      );
      expect(await file.exists(), isTrue);

      final readBack = await readRepository.readEvolutionById(workspace, 'bulbasaur');
      expect(readBack.speciesId, 'bulbasaur');
      expect(readBack.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(readBack.evolutions.single.minLevel, 16);
    });

    test('saves a catalog file in the project workspace', () async {
      await initializeStorage.execute(workspace);
      final movesCatalog = _movesCatalog();

      await writeRepository.saveCatalogByKey(workspace, 'moves', movesCatalog);

      final file = File(
        workspace.resolveProjectRelativePath('data/pokemon/catalogs/moves.json'),
      );
      expect(await file.exists(), isTrue);

      final readBack = await readRepository.readCatalogByKey(workspace, 'moves');
      expect(readBack.catalog, 'moves');
      expect(
        readBack.entries.map((entry) => entry['id']),
        containsAll(<String>['tackle', 'growl']),
      );
    });

    test('writes in the workspace project and not at the monorepo root',
        () async {
      final species = _bulbasaurSpecies();
      final decoy = await Directory.systemTemp.createTemp('pokemon_write_decoy_');
      final originalCurrent = Directory.current;
      try {
        Directory.current = decoy.path;

        await writeRepository.saveSpecies(workspace, species);

        expect(
          File(
            workspace.resolveProjectRelativePath(
              'data/pokemon/species/0001-bulbasaur.json',
            ),
          ).existsSync(),
          isTrue,
        );
        expect(Directory(p.join(repoRootPath, 'data')).existsSync(), isFalse);
        expect(Directory(p.join(repoRootPath, 'assets')).existsSync(), isFalse);
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
      await createProjectUseCase.execute('Pokemon Write Repo Project', tempProjectRoot.path);
      await initializeStorage.execute(workspace);

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await writeRepository.saveSpecies(workspace, _bulbasaurSpecies());
      await writeRepository.saveLearnset(workspace, _bulbasaurLearnset());
      await writeRepository.saveEvolution(workspace, _bulbasaurEvolution());
      await writeRepository.saveCatalogByKey(workspace, 'moves', _movesCatalog());

      final after = await projectFile.readAsString();
      expect(after, before);
    });

    test('overwrites the target species file predictably', () async {
      final originalSpecies = _bulbasaurSpecies();
      const updatedSpecies = PokemonSpeciesFile(
        id: 'bulbasaur',
        slug: 'bulbasaur',
        nationalDex: 1,
        names: <String, String>{'en': 'Bulbasaur Updated'},
        speciesName: <String, String>{'en': 'Seed Pokemon'},
        genIntroduced: 1,
        typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
        baseStats: PokemonSpeciesBaseStats(
          hp: 45,
          atk: 49,
          def: 49,
          spa: 65,
          spd: 65,
          spe: 45,
          bst: 318,
        ),
        abilities: PokemonSpeciesAbilities(
          primary: 'overgrow',
          hidden: 'chlorophyll',
        ),
        breeding: PokemonSpeciesBreeding(
          genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
          eggGroups: <String>['monster', 'grass'],
          hatchCycles: 20,
        ),
        progression: PokemonSpeciesProgression(
          growthRateId: 'medium_slow',
          baseExp: 64,
          catchRate: 45,
          baseFriendship: 50,
        ),
        evolutionRef: 'bulbasaur',
        learnsetRef: 'bulbasaur',
        spriteSetRef: 'bulbasaur',
        cryRef: 'bulbasaur',
        dexContent: PokemonSpeciesDexContent(
          heightM: 0.7,
          weightKg: 6.9,
          color: 'green',
          flavorText: 'Updated demo entry',
        ),
        gameplayFlags: PokemonSpeciesGameplayFlags(
          starterEligible: false,
        ),
        sourceMeta: PokemonSpeciesSourceMeta(
          seededBy: 'test',
          seedVersion: 2,
        ),
      );

      await writeRepository.saveSpecies(workspace, originalSpecies);
      await writeRepository.saveSpecies(workspace, updatedSpecies);

      final readBack = await readRepository.readSpeciesById(workspace, 'bulbasaur');
      expect(readBack.names['en'], 'Bulbasaur Updated');
      expect(readBack.gameplayFlags.starterEligible, isFalse);
      expect(readBack.sourceMeta.seedVersion, 2);
    });

    test('does not create a duplicate species file when the slug changes',
        () async {
      final originalSpecies = _bulbasaurSpecies();
      const updatedSpecies = PokemonSpeciesFile(
        id: 'bulbasaur',
        slug: 'bulbizarre-custom',
        nationalDex: 1,
        names: <String, String>{'en': 'Bulbasaur Custom'},
        speciesName: <String, String>{'en': 'Seed Pokemon'},
        genIntroduced: 1,
        typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
        baseStats: PokemonSpeciesBaseStats(
          hp: 45,
          atk: 49,
          def: 49,
          spa: 65,
          spd: 65,
          spe: 45,
          bst: 318,
        ),
        abilities: PokemonSpeciesAbilities(
          primary: 'overgrow',
          hidden: 'chlorophyll',
        ),
        breeding: PokemonSpeciesBreeding(
          genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
          eggGroups: <String>['monster', 'grass'],
          hatchCycles: 20,
        ),
        progression: PokemonSpeciesProgression(
          growthRateId: 'medium_slow',
          baseExp: 64,
          catchRate: 45,
          baseFriendship: 50,
        ),
        evolutionRef: 'bulbasaur',
        learnsetRef: 'bulbasaur',
        spriteSetRef: 'bulbasaur',
        cryRef: 'bulbasaur',
        dexContent: PokemonSpeciesDexContent(
          heightM: 0.7,
          weightKg: 6.9,
          color: 'green',
          flavorText: 'Updated demo entry after slug change.',
        ),
        gameplayFlags: PokemonSpeciesGameplayFlags(
          starterEligible: true,
        ),
        sourceMeta: PokemonSpeciesSourceMeta(
          seededBy: 'test',
          seedVersion: 3,
        ),
      );

      await writeRepository.saveSpecies(workspace, originalSpecies);
      await writeRepository.saveSpecies(workspace, updatedSpecies);

      final speciesDir = Directory(
        workspace.resolveProjectRelativePath('data/pokemon/species'),
      );
      final speciesFiles = await speciesDir
          .list()
          .where((entity) => entity is File && p.extension(entity.path) == '.json')
          .cast<File>()
          .toList();

      expect(speciesFiles, hasLength(1));
      expect(p.basename(speciesFiles.single.path), '0001-bulbasaur.json');

      final readBack = await readRepository.readSpeciesById(workspace, 'bulbasaur');
      expect(readBack.id, 'bulbasaur');
      expect(readBack.slug, 'bulbizarre-custom');
      expect(readBack.names['en'], 'Bulbasaur Custom');
      expect(readBack.sourceMeta.seedVersion, 3);
    });

    test(
        'rewrites an existing species even when another unrelated species json is invalid',
        () async {
      final originalSpecies = _bulbasaurSpecies();
      const updatedSpecies = PokemonSpeciesFile(
        id: 'bulbasaur',
        slug: 'bulbasaur',
        nationalDex: 1,
        names: <String, String>{'en': 'Bulbasaur Rewritten'},
        speciesName: <String, String>{'en': 'Seed Pokemon'},
        genIntroduced: 1,
        typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
        baseStats: PokemonSpeciesBaseStats(
          hp: 45,
          atk: 49,
          def: 49,
          spa: 65,
          spd: 65,
          spe: 45,
          bst: 318,
        ),
        abilities: PokemonSpeciesAbilities(
          primary: 'overgrow',
          hidden: 'chlorophyll',
        ),
        breeding: PokemonSpeciesBreeding(
          genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
          eggGroups: <String>['monster', 'grass'],
          hatchCycles: 20,
        ),
        progression: PokemonSpeciesProgression(
          growthRateId: 'medium_slow',
          baseExp: 64,
          catchRate: 45,
          baseFriendship: 50,
        ),
        evolutionRef: 'bulbasaur',
        learnsetRef: 'bulbasaur',
        spriteSetRef: 'bulbasaur',
        cryRef: 'bulbasaur',
        dexContent: PokemonSpeciesDexContent(
          heightM: 0.7,
          weightKg: 6.9,
          color: 'green',
          flavorText: 'Rewrite succeeds despite unrelated invalid JSON.',
        ),
        gameplayFlags: PokemonSpeciesGameplayFlags(
          starterEligible: true,
        ),
        sourceMeta: PokemonSpeciesSourceMeta(
          seededBy: 'test',
          seedVersion: 4,
        ),
      );

      await writeRepository.saveSpecies(workspace, originalSpecies);

      final invalidSpeciesFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-unrelated.json',
        ),
      );
      await invalidSpeciesFile.parent.create(recursive: true);
      await invalidSpeciesFile.writeAsString('{ invalid json');

      await writeRepository.saveSpecies(workspace, updatedSpecies);

      final rewrittenFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      final decoded = jsonDecode(await rewrittenFile.readAsString())
          as Map<String, dynamic>;

      expect(decoded['id'], 'bulbasaur');
      expect((decoded['names'] as Map<String, dynamic>)['en'], 'Bulbasaur Rewritten');
      expect(
        (decoded['sourceMeta'] as Map<String, dynamic>)['seedVersion'],
        4,
      );
    });

    test('throws explicit conflict when multiple species files match the same id',
        () async {
      final originalSpecies = _bulbasaurSpecies();
      await writeRepository.saveSpecies(workspace, originalSpecies);

      final conflictingFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-bulbasaur.json',
        ),
      );
      await conflictingFile.parent.create(recursive: true);
      await conflictingFile.writeAsString('''
{
  "id": "something_else"
}
''');

      expect(
        () => writeRepository.saveSpecies(
          workspace,
          const PokemonSpeciesFile(
            id: 'bulbasaur',
            slug: 'bulbasaur',
            nationalDex: 1,
            names: <String, String>{'en': 'Bulbasaur'},
            speciesName: <String, String>{'en': 'Seed Pokemon'},
            genIntroduced: 1,
            typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
            baseStats: PokemonSpeciesBaseStats(
              hp: 45,
              atk: 49,
              def: 49,
              spa: 65,
              spd: 65,
              spe: 45,
              bst: 318,
            ),
            abilities: PokemonSpeciesAbilities(
              primary: 'overgrow',
              hidden: 'chlorophyll',
            ),
            breeding: PokemonSpeciesBreeding(
              genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
              eggGroups: <String>['monster', 'grass'],
              hatchCycles: 20,
            ),
            progression: PokemonSpeciesProgression(
              growthRateId: 'medium_slow',
              baseExp: 64,
              catchRate: 45,
              baseFriendship: 50,
            ),
            evolutionRef: 'bulbasaur',
            learnsetRef: 'bulbasaur',
            spriteSetRef: 'bulbasaur',
            cryRef: 'bulbasaur',
            dexContent: PokemonSpeciesDexContent(
              heightM: 0.7,
              weightKg: 6.9,
              color: 'green',
              flavorText: 'Conflict test.',
            ),
            gameplayFlags: PokemonSpeciesGameplayFlags(
              starterEligible: true,
            ),
            sourceMeta: PokemonSpeciesSourceMeta(
              seededBy: 'test',
              seedVersion: 5,
            ),
          ),
        ),
        throwsA(
          isA<EditorConflictException>().having(
            (error) => error.message,
            'message',
            contains('Multiple Pokemon species files match the id "bulbasaur"'),
          ),
        ),
      );
    });

    test('throws explicit error when catalog key does not match payload', () async {
      await initializeStorage.execute(workspace);
      final before = await File(
        workspace.resolveProjectRelativePath('data/pokemon/catalogs/moves.json'),
      ).readAsString();

      const abilitiesCatalog = PokemonCatalogFile(
        schemaVersion: 1,
        kind: 'pokemon_catalog',
        catalog: 'abilities',
        meta: PokemonDataMeta(
          description: 'Ability catalog for mismatch test.',
          sourcePriority: <String>['internal'],
          notes: <String>[],
        ),
        entries: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'overgrow',
            'name': 'Overgrow',
          },
        ],
      );

      expect(
        () => writeRepository.saveCatalogByKey(
          workspace,
          'moves',
          abilitiesCatalog,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon catalog key mismatch'),
          ),
        ),
      );

      final after = await File(
        workspace.resolveProjectRelativePath('data/pokemon/catalogs/moves.json'),
      ).readAsString();
      expect(after, before);
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

PokemonSpeciesFile _bulbasaurSpecies() {
  return const PokemonSpeciesFile(
    id: 'bulbasaur',
    slug: 'bulbasaur',
    nationalDex: 1,
    names: <String, String>{'en': 'Bulbasaur', 'fr': 'Bulbizarre'},
    speciesName: <String, String>{'en': 'Seed Pokemon'},
    genIntroduced: 1,
    typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
    baseStats: PokemonSpeciesBaseStats(
      hp: 45,
      atk: 49,
      def: 49,
      spa: 65,
      spd: 65,
      spe: 45,
      bst: 318,
    ),
    abilities: PokemonSpeciesAbilities(
      primary: 'overgrow',
      hidden: 'chlorophyll',
    ),
    breeding: PokemonSpeciesBreeding(
      genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
      eggGroups: <String>['monster', 'grass'],
      hatchCycles: 20,
    ),
    progression: PokemonSpeciesProgression(
      growthRateId: 'medium_slow',
      baseExp: 64,
      catchRate: 45,
      baseFriendship: 50,
    ),
    evolutionRef: 'bulbasaur',
    learnsetRef: 'bulbasaur',
    spriteSetRef: 'bulbasaur',
    cryRef: 'bulbasaur',
    dexContent: PokemonSpeciesDexContent(
      heightM: 0.7,
      weightKg: 6.9,
      color: 'green',
      flavorText: 'A strange seed was planted on its back at birth.',
    ),
    gameplayFlags: PokemonSpeciesGameplayFlags(
      starterEligible: true,
    ),
    sourceMeta: PokemonSpeciesSourceMeta(
      seededBy: 'test',
      seedVersion: 1,
    ),
  );
}

PokemonLearnsetFile _bulbasaurLearnset() {
  return const PokemonLearnsetFile(
    speciesId: 'bulbasaur',
    startingMoves: <String>['tackle', 'growl'],
    relearnMoves: <String>['tackle', 'growl', 'vine_whip'],
    levelUp: <PokemonLearnsetLevelUpEntry>[
      PokemonLearnsetLevelUpEntry(
        moveId: 'tackle',
        level: 1,
        source: 'level_up',
        versionGroup: 'demo',
      ),
      PokemonLearnsetLevelUpEntry(
        moveId: 'vine_whip',
        level: 7,
        source: 'level_up',
        versionGroup: 'demo',
      ),
    ],
  );
}

PokemonEvolutionFile _bulbasaurEvolution() {
  return const PokemonEvolutionFile(
    speciesId: 'bulbasaur',
    preEvolution: null,
    evolutions: <PokemonEvolutionEntry>[
      PokemonEvolutionEntry(
        targetSpeciesId: 'ivysaur',
        method: 'level_up',
        minLevel: 16,
      ),
    ],
  );
}

PokemonCatalogFile _movesCatalog() {
  return const PokemonCatalogFile(
    schemaVersion: 1,
    kind: 'pokemon_catalog',
    catalog: 'moves',
    meta: PokemonDataMeta(
      description: 'Move catalog for the local Pokemon project database.',
      sourcePriority: <String>['internal'],
      notes: <String>['Write repository integration test data.'],
    ),
    entries: <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'tackle',
        'name': 'Tackle',
        'names': <String, String>{'en': 'Tackle', 'fr': 'Charge'},
        'type': 'normal',
        'category': 'physical',
        'power': 40,
        'accuracy': 100,
        'pp': 35,
        'priority': 0,
        'target': 'adjacent',
        'shortDesc': 'A physical attack in which the user charges and slams.',
        'generation': 1,
      },
      <String, dynamic>{
        'id': 'growl',
        'name': 'Growl',
        'names': <String, String>{'en': 'Growl', 'fr': 'Rugissement'},
        'type': 'normal',
        'category': 'status',
        'power': null,
        'accuracy': 100,
        'pp': 40,
        'priority': 0,
        'target': 'adjacent',
        'shortDesc': 'Lowers the target Attack by one stage.',
        'generation': 1,
      },
    ],
  );
}
```

## 13. Mini conclusion honnete

Le mini-fix 8c nettoie le dernier couplage fragile du writer species :

- l'ecriture d'une espece existante ne depend plus de la reconstruction de l'index leger global ;
- un JSON species invalide non lie ne casse plus la reecriture d'une espece ciblee ;
- le comportement de non-duplication si le slug change reste bon ;
- le conflit multiple reste explicite ;
- `project.json` reste intact ;
- rien n'est cree a la racine du monorepo.

Ce qui reste volontairement simple :

- pas d'index persistant ;
- pas de cache ;
- pas de merge intelligent ;
- pas de validation metier large ;
- pas de changement du contrat JSON.

On a donc un mini-fix petit, cible, et plus sain pour la suite.
