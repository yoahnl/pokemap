# Rapport — Lot 8 Pokémon — Repositories d'écriture locaux

## 1. Résumé exécutif

Ce lot ajoute la capacité d’écriture locale des données Pokémon dans le workspace projet utilisateur, en restant strictement dans le périmètre d’infrastructure et d’architecture.

Ce qui a été fait :
- ajout d’un port d’écriture `PokemonWriteRepository` côté application ;
- ajout d’une implémentation concrète `FilePokemonWriteRepository` côté infrastructure ;
- ajout de sérialisations `toJson()` sur les modèles déjà stabilisés (`catalog`, `species`, `learnset`, `evolution`) ;
- ajout de tests d’intégration d’écriture pour espèces, learnsets, évolutions et catalogues ;
- garantie que tout s’écrit dans le workspace projet utilisateur, jamais à la racine du monorepo ;
- garantie que `project.json` reste inchangé.

Ce qui n’a pas été fait :
- pas d’UI ;
- pas de provider ;
- pas de runtime ;
- pas d’import externe ;
- pas de validation métier poussée ;
- pas d’écriture du manifeste ;
- pas d’écriture `media` / `sprite_sets`.

## 2. Objectif exact du lot

L’objectif du lot 8 était de créer le pendant écriture de la lecture locale Pokémon déjà en place :
- même séparation application / infrastructure ;
- même ancrage strict au `ProjectWorkspace` ;
- même exclusion de `project.json` comme stockage Pokémon ;
- même absence de dépendance au runtime ou à l’UI.

Le lot devait permettre de sauvegarder localement des JSON internes déjà au bon format pour :
- une espèce ;
- un learnset ;
- une évolution ;
- un catalogue global.

## 3. Périmètre strict

Inclus dans ce lot :
- port d’écriture ;
- implémentation filesystem/workspace ;
- sérialisation JSON stable ;
- tests ciblés ;
- analyse ciblée ;
- rapport complet.

Exclus volontairement :
- `media` / `sprite_sets` ;
- écriture du manifeste ;
- use case applicatif d’édition ;
- toute logique de merge ;
- toute validation métier complexe ;
- toute intégration UI ;
- toute modification de `project.json`.

## 4. Décisions d’architecture

### 4.1 Port d’écriture dédié

J’ai ajouté :
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart`

Ce port expose une API explicite pour écrire :
- un catalogue par clé logique ;
- une espèce ;
- un learnset ;
- une évolution.

### 4.2 Implémentation concrète côté infrastructure

J’ai ajouté dans :
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

la classe :
- `FilePokemonWriteRepository`

Cette classe :
- résout les chemins via `ProjectWorkspace` ;
- garantit l’existence des dossiers parents ;
- écrit des JSON stables avec `JsonEncoder.withIndent('  ')` ;
- écrase simplement le fichier cible ;
- ne dépend pas de `Directory.current` ;
- n’écrit jamais hors du workspace ;
- ne touche jamais à `project.json`.

### 4.3 Pas de manifeste dans ce lot

Je n’ai pas ajouté d’écriture du manifeste.

Raison :
- ce n’était pas nécessaire pour les cas d’écriture demandés ;
- le manifeste sert ici surtout de contrat de lecture/initialisation ;
- le lot 8 est volontairement limité aux fichiers métier déjà stabilisés.

### 4.4 Pas de `media` dans ce lot

Je n’ai pas inclus `media` / `sprite_sets`.

Raison :
- il n’existe pas encore de modèle Dart média réellement stabilisé dans la base actuelle ;
- le contrat de `species`, `learnset`, `evolution` et `catalog` existe déjà clairement ;
- ajouter `media` maintenant aurait poussé à inventer un modèle spéculatif juste pour “cocher la case”.

Cette exclusion est volontaire et assumée.

## 5. Liste des fichiers créés / modifiés

Créé :
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart`
- `/Users/karim/Project/pokemonProject/reports/pokemon-write-repositories-lot-8-report.md`

Modifié :
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

## 6. Explication détaillée du port d’écriture

Le port `PokemonWriteRepository` est volontairement petit :
- `saveCatalogByKey(...)`
- `saveSpecies(...)`
- `saveLearnset(...)`
- `saveEvolution(...)`

Pourquoi ce design :
- il couvre uniquement les écritures réellement stabilisées dans le code actuel ;
- il correspond au niveau d’abstraction déjà en place pour la lecture ;
- il évite de faire dépendre les futurs use cases de `dart:io` ou de chemins concrets.

## 7. Explication détaillée de l’implémentation infrastructure

`FilePokemonWriteRepository` applique les conventions suivantes :

### 7.1 Catalogues

Les catalogues sont résolus à partir d’une map de clés logiques vers chemins :
- `moves`
- `abilities`
- `items`
- `types`
- `growth_rates`
- `natures`
- `egg_groups`
- `habitats`
- `generations`
- `version_groups`
- `encounter_rules`

Si la clé n’est pas connue :
- erreur explicite `EditorNotFoundException`

### 7.2 Espèces

Les espèces sont écrites dans :
- `data/pokemon/species/<dex sur 4 chiffres>-<slug ou id>.json`

Exemple :
- `0001-bulbasaur.json`

Le nom de fichier reste une convention de stockage, pas une vérité métier.
Dans ce lot, l’écriture d’espèce suit simplement la convention déjà présente.

### 7.3 Learnsets

Écriture dans :
- `data/pokemon/learnsets/<speciesId>.json`

### 7.4 Évolutions

Écriture dans :
- `data/pokemon/evolutions/<speciesId>.json`

### 7.5 Format JSON

Tous les fichiers sont écrits avec :
- `JsonEncoder.withIndent('  ')`

Donc :
- format lisible ;
- stable ;
- cohérent avec les autres écritures du projet.

### 7.6 Comportement d’écrasement

Le comportement est volontairement simple :
- sauvegarder un fichier réécrit totalement le fichier cible ;
- aucun merge implicite ;
- aucune logique de patch partiel.

## 8. Justification explicite de l’exclusion de `media`

`media` / `sprite_sets` est exclu de ce lot.

Justification :
- pas de modèle Dart média stabilisé dans l’état réel du projet ;
- ce lot vise une base saine, pas une fausse complétude ;
- ajouter un modèle “juste assez” pour écrire `media` aurait été spéculatif et fragile.

Conclusion :
- lot 8 couvre proprement `species`, `learnset`, `evolution`, `catalogs` ;
- `media` doit revenir dans un lot dédié quand le contrat sera réellement fixé.

## 9. Description des tests ajoutés

Fichier ajouté :
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart`

Cas couverts :
- sauvegarde d’une espèce ;
- sauvegarde d’un learnset ;
- sauvegarde d’une évolution ;
- sauvegarde d’un catalogue ;
- preuve que l’écriture se fait dans le workspace et non à la racine du monorepo ;
- preuve que `project.json` reste inchangé ;
- relecture des fichiers écrits ;
- écrasement simple et prévisible d’un fichier espèce.

Le test “écriture dans le workspace et pas à la racine” :
- ne hardcode aucun chemin machine ;
- résout la racine du repo de manière portable ;
- vérifie ensuite l’absence de `data/` et `assets/` au monorepo root.

## 10. Commandes réellement exécutées

```bash
flutter test test/file_pokemon_write_repository_test.dart
flutter test test/file_pokemon_read_repository_test.dart
flutter analyze --no-pub lib/src/application/models/pokemon_project_data_models.dart lib/src/application/ports/pokemon_write_repository.dart lib/src/infrastructure/repositories/file_repositories.dart test/file_pokemon_write_repository_test.dart
git status --short
git diff --stat -- packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart packages/map_editor/test/file_pokemon_write_repository_test.dart reports/pokemon-write-repositories-lot-8-report.md
git ls-files --others --exclude-standard packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart packages/map_editor/test/file_pokemon_write_repository_test.dart reports/pokemon-write-repositories-lot-8-report.md
./review_bundle.sh
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
cat .review/review-20260408-234327.txt
cat packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
cat packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart
cat packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
cat packages/map_editor/test/file_pokemon_write_repository_test.dart
```

## 11. Résultat des tests

### `flutter test test/file_pokemon_write_repository_test.dart`

Résultat :

```text
All tests passed!
```

Tests passés :
- `saves a species file in the project workspace`
- `saves a learnset file in the project workspace`
- `saves an evolution file in the project workspace`
- `saves a catalog file in the project workspace`
- `writes in the workspace project and not at the monorepo root`
- `leaves project.json strictly unchanged`
- `overwrites the target species file predictably`

### `flutter test test/file_pokemon_read_repository_test.dart`

Résultat :

```text
All tests passed!
```

Je l’ai relancé comme garde-fou pour m’assurer que la lecture locale existante reste saine après ajout de l’écriture.

## 12. Résultat de l’analyse

Commande :

```bash
flutter analyze --no-pub lib/src/application/models/pokemon_project_data_models.dart lib/src/application/ports/pokemon_write_repository.dart lib/src/infrastructure/repositories/file_repositories.dart test/file_pokemon_write_repository_test.dart
```

Résultat :

```text
No issues found! (ran in 0.8s)
```

## 13. Preuve que `project.json` est inchangé

Le test suivant le prouve explicitement :
- `leaves project.json strictly unchanged`

Stratégie du test :
- création d’un vrai projet via `CreateProjectUseCase` ;
- lecture brute de `project.json` avant écriture Pokémon ;
- écriture d’une espèce, d’un learnset, d’une évolution et d’un catalogue ;
- relecture brute de `project.json` ;
- comparaison byte-for-byte.

Résultat :
- inchangé.

## 14. Preuve que rien n’est recréé à la racine du monorepo

Vérification par test :
- `writes in the workspace project and not at the monorepo root`

Vérification manuelle complémentaire exécutée :

```bash
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
```

Sortie :

```text
[aucune sortie]
```

## 15. `git status --short`

Commande :

```bash
git status --short
```

Sortie finale après création de ce rapport :

```text
 M packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
?? packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart
?? packages/map_editor/test/file_pokemon_write_repository_test.dart
?? reports/pokemon-write-repositories-lot-8-report.md
```

## 16. `git diff --stat`

Commande :

```bash
git diff --stat -- packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart packages/map_editor/test/file_pokemon_write_repository_test.dart reports/pokemon-write-repositories-lot-8-report.md
```

Sortie :

```text
 .../models/pokemon_project_data_models.dart        | 179 +++++++++++++++++++++
 .../repositories/file_repositories.dart            | 118 ++++++++++++++
 2 files changed, 297 insertions(+)
```

Note honnête :
- `git diff --stat` ne montre pas les fichiers non suivis ;
- donc `pokemon_write_repository.dart`, `file_pokemon_write_repository_test.dart` et ce rapport n’y apparaissent pas ;
- il faut lire cette sortie avec `git status --short` et `git ls-files --others --exclude-standard`.

## 17. `git ls-files --others --exclude-standard`

Commande :

```bash
git ls-files --others --exclude-standard packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart packages/map_editor/test/file_pokemon_write_repository_test.dart reports/pokemon-write-repositories-lot-8-report.md
```

Sortie finale après création de ce rapport :

```text
packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart
packages/map_editor/test/file_pokemon_write_repository_test.dart
reports/pokemon-write-repositories-lot-8-report.md
```

## 18. Exécution obligatoire de `./review_bundle.sh`

Commande exécutée :

```bash
./review_bundle.sh
```

## 19. Chemin du fichier généré par `./review_bundle.sh`

```text
.review/review-20260408-234327.txt
```

## 20. Contenu intégral du fichier généré

```text
# REVIEW BUNDLE

Generated at: 2026-04-08 23:43:28
Repository: pokemonProject
Branch: main
Base ref: HEAD
Head commit: ff4a9289330aa2fa3cb39505270f5a7ad1aa4673

## GIT STATUS --SHORT

 M packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
?? packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart
?? packages/map_editor/test/file_pokemon_write_repository_test.dart

## GIT DIFF --STAT

 .../models/pokemon_project_data_models.dart        | 179 +++++++++++++++++++++
 .../repositories/file_repositories.dart            | 118 ++++++++++++++
 2 files changed, 297 insertions(+)

## CHANGED FILES

packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
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
diff --git a/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart b/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
index 05893b4..8e16074 100644
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
@@ -182,3 +185,118 @@ class FilePokemonReadRepository implements PokemonReadRepository {
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
+  const FilePokemonWriteRepository();
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
+    final relativePath = 'data/pokemon/species/${_speciesFileName(species)}';
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

Note honnête :
- le bundle n’inclut pas les fichiers non suivis dans `git diff --stat` ;
- il ne contient donc pas `pokemon_write_repository.dart`, le test d’écriture non suivi, ni ce rapport ;
- il faut lire le bundle avec `git status --short` et `git ls-files --others --exclude-standard`.

## 21. Note honnête si le bundle est partiel à cause de fichiers non suivis

Oui, le bundle est partiel pour ce lot :
- `pokemon_write_repository.dart` est non suivi ;
- `file_pokemon_write_repository_test.dart` est non suivi ;
- `pokemon-write-repositories-lot-8-report.md` est créé après les premières commandes Git et n’apparaît pas dans le bundle.

Ce n’est pas un échec du lot, c’est une limite normale de ce que Git montre selon la commande utilisée.

## 22. Code intégral de TOUS les fichiers créés ou modifiés dans ce lot

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
    final names = _readStringMap(json['names']);
    return PokemonSpeciesIndexEntry(
      id: (json['id'] as String?)?.trim() ?? '',
      nationalDex: (json['nationalDex'] as num?)?.toInt() ?? 0,
      primaryName: _pickPrimaryName(names) ?? (json['id'] as String?)?.trim() ?? '',
      types: PokemonSpeciesTyping.fromJson(
        (json['typing'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ).types,
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

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart`

```dart
import '../models/pokemon_project_data_models.dart';
import 'project_workspace.dart';

/// Contrat d'écriture des données Pokémon locales d'un projet utilisateur.
///
/// Cette frontière garde les use cases applicatifs découplés de `dart:io`
/// et du layout concret du workspace. Le contrat reste volontairement petit :
/// il couvre uniquement les fichiers JSON déjà stabilisés à ce stade.
abstract class PokemonWriteRepository {
  /// Écrit un catalogue global dans `data/pokemon/catalogs/...`.
  ///
  /// Le `catalogKey` représente la clé logique utilisée dans le manifeste
  /// local (`moves`, `abilities`, `types`, etc.).
  Future<void> saveCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
    PokemonCatalogFile catalog,
  );

  /// Écrit une espèce Pokémon dans `data/pokemon/species/...`.
  ///
  /// Le fichier cible suit la convention déjà présente dans le projet :
  /// `<nationalDex sur 4 chiffres>-<slug ou id>.json`.
  Future<void> saveSpecies(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  );

  /// Écrit un learnset dans `data/pokemon/learnsets/<speciesId>.json`.
  Future<void> saveLearnset(
    ProjectWorkspace workspace,
    PokemonLearnsetFile learnset,
  );

  /// Écrit une évolution dans `data/pokemon/evolutions/<speciesId>.json`.
  Future<void> saveEvolution(
    ProjectWorkspace workspace,
    PokemonEvolutionFile evolution,
  );
}
```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

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
  const FilePokemonWriteRepository();

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
    final relativePath = 'data/pokemon/species/${_speciesFileName(species)}';
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

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/file_pokemon_write_repository_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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

## 23. Mini conclusion honnête

Le lot 8 apporte une vraie base d’écriture locale Pokémon propre :
- port d’écriture côté application ;
- implémentation filesystem côté infrastructure ;
- sérialisation stable ;
- tests réels de sauvegarde et de relecture.

Ce lot reste volontairement simple :
- pas de merge ;
- pas de validation métier lourde ;
- pas de `media` ;
- pas de touche à `project.json`.

La base est maintenant prête pour les prochains lots applicatifs d’édition ou d’orchestration, sans casser la séparation architecturelle déjà posée.
