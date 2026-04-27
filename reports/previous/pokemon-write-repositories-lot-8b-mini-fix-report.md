# Pokemon Write Repositories Lot 8b Mini-Fix Report

## 1. Resume executif

Ce mini-fix corrige deux defauts de robustesse du lot 8, sans elargir le perimetre :

1. `saveSpecies()` n'ecrit plus un nouveau fichier parasite quand le `slug` change pour une espece deja existante.
2. `saveCatalogByKey()` refuse maintenant explicitement un appel incoherent si la cle demandee ne correspond pas au `catalog` porte par le payload.

Ce mini-fix ne change pas :

- l'architecture generale du lot 8 ;
- le perimetre local au workspace projet utilisateur ;
- `project.json` ;
- l'UI ;
- le runtime ;
- le seed ;
- les imports externes.

## 2. Objectif exact du mini-fix

Le but etait de rendre l'ecriture locale Pokemon plus fiable sur deux points tres cibles :

- garantir qu'une re-sauvegarde d'espece existante se fait sur son fichier reel existant, meme si le `slug` change ;
- bloquer avant ecriture une incoherence `catalogKey` / `catalog.catalog`.

## 3. Rappel exact des deux problemes corriges

### 3.1 Duplication possible si le slug change

Avant ce mini-fix, `saveSpecies()` calculait son chemin cible a partir de :

- `nationalDex`
- `slug` ou `id`

Ce comportement pouvait creer un second fichier si :

- l'espece existait deja dans `data/pokemon/species/`
- mais qu'on la resauvegardait avec un `slug` different

Cela ouvrait la porte a une duplication de fichiers pour un meme `species.id`.

### 3.2 Mismatch possible entre `catalogKey` et `catalog.catalog`

Avant ce mini-fix, un appel de ce style etait possible :

```dart
saveCatalogByKey(workspace, 'moves', abilitiesCatalog)
```

avec un payload dont `catalog.catalog == 'abilities'`.

Le repository pouvait alors ecrire un contenu incoherent dans le mauvais fichier.

## 4. Decisions prises

### 4.1 Strategie de reutilisation du fichier species existant

La logique retenue est volontairement petite et robuste :

1. verifier que `species.id` n'est pas vide ;
2. demander au lecteur local existant `listSpeciesIndexEntries(workspace)` ;
3. filtrer les entrees dont `entry.id == species.id` ;
4. si une seule entree correspond, reutiliser **exactement** `entry.relativePath` pour l'ecriture ;
5. s'il n'y a aucune entree, creer un nouveau fichier via la convention existante :
   `data/pokemon/species/<dex sur 4 chiffres>-<slug ou id>.json`
6. s'il y a plusieurs entrees pour le meme id, lever une erreur de conflit explicite.

Ce choix garde la bonne hierarchie de verite :

- la verite metier reste `species.id` dans le JSON ;
- le nom de fichier reste une convention de stockage ;
- on ne reintroduit pas de dependance metier au basename.

### 4.2 Politique stricte sur le mismatch catalogue

Dans `saveCatalogByKey(...)`, le repository compare maintenant :

- `catalogKey.trim()`
- `catalog.catalog.trim()`

Si les deux valeurs ne correspondent pas :

- une `EditorValidationException` explicite est levee ;
- aucun fichier n'est ecrit.

Message retenu :

```text
Pokemon catalog key mismatch: requested "moves" but payload is "abilities"
```

## 5. Liste exacte des fichiers modifies dans ce mini-fix

- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_editor/test/file_pokemon_write_repository_test.dart`
- `reports/pokemon-write-repositories-lot-8b-mini-fix-report.md`

Note honnete :

- `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart`
- `reports/pokemon-write-repositories-lot-8-report.md`

etaient deja presents comme modifications / fichiers non suivis venant du lot 8. Ils ne font pas partie des modifications de code de ce mini-fix.

## 6. Explication technique detaillee

### 6.1 `FilePokemonWriteRepository`

Deux changements utiles y sont concentres :

#### A. `saveSpecies(...)`

Cette methode passe maintenant par `_resolveSpeciesWritePath(...)`, qui :

- reutilise le lecteur local Pokemon existant ;
- cherche une espece existante par `species.id` ;
- ecrit au chemin existant si l'espece existe deja ;
- ne recalcule un nouveau nom de fichier que si l'espece n'existe pas encore.

Le resultat concret :

- resauvegarder `bulbasaur` avec un nouveau `slug` n'engendre pas `0001-bulbizarre-custom.json` en plus de `0001-bulbasaur.json` ;
- le fichier deja existant est simplement ecrase a son emplacement reel.

#### B. `saveCatalogByKey(...)`

Cette methode valide maintenant la coherence entre :

- la cle de sauvegarde demandee ;
- la nature du catalogue porte par le payload.

En cas de mismatch :

- erreur explicite ;
- ecriture annulee ;
- fichier existant conserve intact.

### 6.2 Tests

Le fichier de test du repository d'ecriture a ete etendu avec deux verifications fortes :

- aucun doublon species quand seul le `slug` change ;
- erreur explicite et zero ecriture si la cle catalogue ne correspond pas au payload.

## 7. Tests ajoutes / verifies

### 7.1 Tests du mini-fix

- `does not create a duplicate species file when the slug changes`
- `throws explicit error when catalog key does not match payload`

### 7.2 Ce qu'ils prouvent

#### A. Pas de doublon species si le slug change

Le test :

1. ecrit `bulbasaur` avec `slug = bulbasaur` ;
2. reecrit la meme espece avec `slug = bulbizarre-custom` ;
3. recompte les fichiers sous `data/pokemon/species/` ;
4. verifie qu'il n'y a toujours qu'un seul fichier ;
5. verifie que la lecture par `readSpeciesById(workspace, 'bulbasaur')` continue a fonctionner ;
6. verifie que le contenu du fichier a bien ete mis a jour.

#### B. Mismatch catalogue

Le test :

1. initialise le storage Pokemon du workspace ;
2. lit le contenu initial de `data/pokemon/catalogs/moves.json` ;
3. tente `saveCatalogByKey(workspace, 'moves', abilitiesCatalog)` ;
4. attend une `EditorValidationException` explicite ;
5. relit `moves.json` ;
6. verifie que le fichier n'a pas change.

## 8. Commandes reellement executees

Voici les commandes effectivement executees pendant ce mini-fix :

```bash
sed -n '1,260p' packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
sed -n '1,320p' packages/map_editor/test/file_pokemon_write_repository_test.dart
sed -n '261,420p' packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
sed -n '321,520p' packages/map_editor/test/file_pokemon_write_repository_test.dart
git status --short
git diff --stat -- packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart packages/map_editor/test/file_pokemon_write_repository_test.dart reports/pokemon-write-repositories-lot-8b-mini-fix-report.md
git ls-files --others --exclude-standard packages/map_editor/test/file_pokemon_write_repository_test.dart reports/pokemon-write-repositories-lot-8b-mini-fix-report.md
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
flutter test test/file_pokemon_write_repository_test.dart
flutter test test/file_pokemon_read_repository_test.dart
flutter analyze --no-pub lib/src/application/models/pokemon_project_data_models.dart lib/src/application/ports/pokemon_write_repository.dart lib/src/infrastructure/repositories/file_repositories.dart test/file_pokemon_write_repository_test.dart
./review_bundle.sh
cat .review/review-20260409-000245.txt
cat packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
cat packages/map_editor/test/file_pokemon_write_repository_test.dart
```

## 9. Resultats reels des tests

### 9.1 `flutter test test/file_pokemon_write_repository_test.dart`

Resultat :

```text
00:01 +9: All tests passed!
```

Le fichier couvre bien les 2 corrections du mini-fix.

### 9.2 `flutter test test/file_pokemon_read_repository_test.dart`

Resultat :

```text
00:01 +6: All tests passed!
```

Ce rerun confirme que le mini-fix d'ecriture n'a pas casse la lecture locale existante.

## 10. Resultat reel de l'analyse

Commande :

```bash
flutter analyze --no-pub lib/src/application/models/pokemon_project_data_models.dart lib/src/application/ports/pokemon_write_repository.dart lib/src/infrastructure/repositories/file_repositories.dart test/file_pokemon_write_repository_test.dart
```

Resultat :

```text
No issues found! (ran in 0.9s)
```

## 11. Preuves complementaires de robustesse

### 11.1 Aucun doublon species si le slug change

Le test dedie prouve explicitement :

- qu'il n'y a toujours qu'un seul fichier JSON espece apres changement de slug ;
- que le fichier historique est reutilise ;
- que l'espece reste relisible proprement via `readSpeciesById(...)`.

### 11.2 Le mismatch catalogue echoue avant ecriture

Le test dedie prouve explicitement :

- qu'une erreur explicite est levee ;
- qu'aucune ecriture n'a lieu dans `moves.json`.

### 11.3 `project.json` est reste strictement inchange

Preuve :

- le test `leaves project.json strictly unchanged` du repository d'ecriture continue de passer ;
- aucune logique du mini-fix n'ecrit dans `project.json`.

### 11.4 Rien n'a ete cree a la racine du monorepo

Commande executee :

```bash
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
```

Sortie :

```text

```

Conclusion :

- aucun `./data` ;
- aucun `./assets` ;

ont ete recrees a la racine du monorepo.

## 12. Etat Git

### 12.1 `git status --short`

```text
 M packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
?? packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart
?? packages/map_editor/test/file_pokemon_write_repository_test.dart
?? reports/pokemon-write-repositories-lot-8-report.md
?? reports/pokemon-write-repositories-lot-8b-mini-fix-report.md
```

Note honnete :

- cet etat inclut encore des fichiers du lot 8 non engages ;
- le mini-fix 8b se limite en pratique a `file_repositories.dart`, `file_pokemon_write_repository_test.dart` et ce rapport.

### 12.2 `git diff --stat` cible sur le mini-fix

Commande :

```bash
git diff --stat -- packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart packages/map_editor/test/file_pokemon_write_repository_test.dart reports/pokemon-write-repositories-lot-8b-mini-fix-report.md
```

Sortie :

```text
 .../repositories/file_repositories.dart            | 167 +++++++++++++++++++++
 1 file changed, 167 insertions(+)
```

Note honnete :

- `git diff --stat` n'affiche ici que le fichier tracked `file_repositories.dart` ;
- le test et ce rapport sont encore **untracked**, donc ils n'apparaissent pas dans cette sortie.

### 12.3 `git ls-files --others --exclude-standard`

Commande :

```bash
git ls-files --others --exclude-standard packages/map_editor/test/file_pokemon_write_repository_test.dart reports/pokemon-write-repositories-lot-8b-mini-fix-report.md
```

Sortie :

```text
packages/map_editor/test/file_pokemon_write_repository_test.dart
reports/pokemon-write-repositories-lot-8b-mini-fix-report.md
```

## 13. Execution obligatoire de `./review_bundle.sh`

Commande executee :

```bash
./review_bundle.sh
```

Chemin du fichier genere :

```text
.review/review-20260409-000245.txt
```

## 14. Contenu integral du bundle genere

```text
# REVIEW BUNDLE

Generated at: 2026-04-09 00:02:45
Repository: pokemonProject
Branch: main
Base ref: HEAD
Head commit: ff4a9289330aa2fa3cb39505270f5a7ad1aa4673

## GIT STATUS --SHORT

 M packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
?? packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart
?? packages/map_editor/test/file_pokemon_write_repository_test.dart
?? reports/pokemon-write-repositories-lot-8-report.md
?? reports/pokemon-write-repositories-lot-8b-mini-fix-report.md

## GIT DIFF --STAT

 .../models/pokemon_project_data_models.dart        | 179 +++++++++++++++++++++
 .../repositories/file_repositories.dart            | 167 +++++++++++++++++++
 2 files changed, 346 insertions(+)

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
index 05893b4..5afae9a 100644
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
@@ -182,3 +185,167 @@ class FilePokemonReadRepository implements PokemonReadRepository {
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
+    final matches = (await reader.listSpeciesIndexEntries(workspace))
+        .where((entry) => entry.id == trimmedId)
+        .toList(growable: false);
+
+    if (matches.length > 1) {
+      throw EditorConflictException(
+        'Multiple Pokemon species files share the same id "$trimmedId": '
+        '${matches.map((entry) => entry.relativePath).join(', ')}',
+      );
+    }
+    if (matches.length == 1) {
+      return matches.single.relativePath;
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

Note honnete sur le bundle :

- le bundle reste partiel pour ce mini-fix ;
- il inclut correctement le fichier tracked `file_repositories.dart` ;
- il n'inclut pas le contenu complet du fichier de test untracked, ni celui de ce rapport, parce que `review_bundle.sh` se base sur les informations Git disponibles.

## 15. Code integral de tous les fichiers modifies dans ce mini-fix

### 15.1 `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

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

    final matches = (await reader.listSpeciesIndexEntries(workspace))
        .where((entry) => entry.id == trimmedId)
        .toList(growable: false);

    if (matches.length > 1) {
      throw EditorConflictException(
        'Multiple Pokemon species files share the same id "$trimmedId": '
        '${matches.map((entry) => entry.relativePath).join(', ')}',
      );
    }
    if (matches.length == 1) {
      return matches.single.relativePath;
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

### 15.2 `packages/map_editor/test/file_pokemon_write_repository_test.dart`

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

## 16. Mini conclusion honnete

Ce mini-fix rend le lot 8 sensiblement plus robuste, sans changer son role :

- une espece existante est maintenant reecrite a son emplacement reel, meme si son `slug` evolue ;
- un catalogue ne peut plus etre ecrit sous une cle incoherente ;
- `project.json` reste intact ;
- rien n'est cree a la racine du monorepo ;
- le diff reste petit et cible.

Ce qui reste volontairement simple :

- pas de merge intelligent ;
- pas de validation metier large ;
- pas de support media force artificiellement ;
- pas de nouvelle architecture lourde.

La base d'ecriture locale reste donc modeste, mais elle est maintenant plus fiable et plus previsible pour la suite.
