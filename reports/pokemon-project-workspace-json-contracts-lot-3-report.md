# Rapport — Lot 3 Pokémon : contrats JSON métier minimaux dans le workspace projet

## 1. Résumé exécutif

Ce lot enrichit le contrat JSON créé par `InitializePokemonProjectStorageUseCase` sans changer son périmètre :

- aucun UI
- aucun import Showdown / PokeAPI
- aucun runtime
- aucune modification de `project.json`
- aucune donnée Pokémon réelle

Le changement principal est simple :

- les catalogues JSON ne sont plus de simples coquilles `entries: []`
- ils portent maintenant un contrat minimal lisible avec `meta`
- le manifeste racine est enrichi avec `meta` et `futureDataFolders`

Ce lot reste volontairement petit : il clarifie le **contrat de stockage local**, sans commencer la modélisation Dart Pokémon ni l’import.

## 2. Rappel du périmètre strict

Ce lot ne fait que faire évoluer le bootstrap du workspace projet utilisateur via :

- `packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`

Il ne touche pas :

- au runtime
- au combat
- à l’UI
- aux providers Riverpod
- à `project.json`
- à la création automatique de projet

Le confinement au workspace projet reste inchangé :

- rien n’est créé à la racine du monorepo
- tous les chemins passent toujours par `workspace.resolveProjectRelativePath(...)`

## 3. Description du nouveau contrat JSON minimal

### 3.1 Manifeste racine

Le fichier `data/pokemon/pokemon_data_manifest.json` devient un vrai manifeste minimal avec :

- `schemaVersion`
- `kind`
- `meta`
- `catalogFiles`
- `futureDataFolders`

Contenu exact attendu :

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_data_manifest",
  "meta": {
    "description": "Root manifest for the local Pokemon data stored inside a project workspace.",
    "notes": []
  },
  "catalogFiles": {
    "moves": "catalogs/moves.json",
    "abilities": "catalogs/abilities.json",
    "items": "catalogs/items.json",
    "types": "catalogs/types.json",
    "growthRates": "catalogs/growth_rates.json",
    "natures": "catalogs/natures.json",
    "eggGroups": "catalogs/egg_groups.json",
    "habitats": "catalogs/habitats.json",
    "generations": "catalogs/generations.json",
    "versionGroups": "catalogs/version_groups.json",
    "encounterRules": "catalogs/encounter_rules.json"
  },
  "futureDataFolders": {
    "species": "species/",
    "learnsets": "learnsets/",
    "evolutions": "evolutions/",
    "spriteSets": "sprite_sets/"
  }
}
```

### 3.2 Catalogues métier minimaux

Chaque catalogue JSON porte maintenant :

- `schemaVersion`
- `kind`
- `catalog`
- `meta`
- `entries`

Forme générale :

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "<catalog_name>",
  "meta": {
    "description": "<catalog-specific description>",
    "sourcePriority": ["internal"],
    "notes": []
  },
  "entries": []
}
```

Choix de contrat :

- `sourcePriority: ["internal"]` reste volontairement honnête
- on ne prétend pas encore avoir importé Showdown ou PokeAPI
- `notes` reste présent pour préparer les lots suivants sans introduire de logique supplémentaire

## 4. Contenu exact attendu des catalogues

### `moves.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "moves",
  "meta": {
    "description": "Move catalog for the local Pokemon project database.",
    "sourcePriority": ["internal"],
    "notes": []
  },
  "entries": []
}
```

### `abilities.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "abilities",
  "meta": {
    "description": "Ability catalog for the local Pokemon project database.",
    "sourcePriority": ["internal"],
    "notes": []
  },
  "entries": []
}
```

### `items.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "items",
  "meta": {
    "description": "Item catalog for the local Pokemon project database.",
    "sourcePriority": ["internal"],
    "notes": []
  },
  "entries": []
}
```

### `types.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "types",
  "meta": {
    "description": "Type catalog for the local Pokemon project database.",
    "sourcePriority": ["internal"],
    "notes": []
  },
  "entries": []
}
```

### `growth_rates.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "growth_rates",
  "meta": {
    "description": "Growth rate catalog for the local Pokemon project database.",
    "sourcePriority": ["internal"],
    "notes": []
  },
  "entries": []
}
```

### `natures.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "natures",
  "meta": {
    "description": "Nature catalog for the local Pokemon project database.",
    "sourcePriority": ["internal"],
    "notes": []
  },
  "entries": []
}
```

### `egg_groups.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "egg_groups",
  "meta": {
    "description": "Egg group catalog for the local Pokemon project database.",
    "sourcePriority": ["internal"],
    "notes": []
  },
  "entries": []
}
```

### `habitats.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "habitats",
  "meta": {
    "description": "Habitat catalog for the local Pokemon project database.",
    "sourcePriority": ["internal"],
    "notes": []
  },
  "entries": []
}
```

### `generations.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "generations",
  "meta": {
    "description": "Generation catalog for the local Pokemon project database.",
    "sourcePriority": ["internal"],
    "notes": []
  },
  "entries": []
}
```

### `version_groups.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "version_groups",
  "meta": {
    "description": "Version group catalog for the local Pokemon project database.",
    "sourcePriority": ["internal"],
    "notes": []
  },
  "entries": []
}
```

### `encounter_rules.json`

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "encounter_rules",
  "meta": {
    "description": "Encounter rule catalog for the local Pokemon project database.",
    "sourcePriority": ["internal"],
    "notes": []
  },
  "entries": []
}
```

## 5. Fichiers réellement modifiés

- `packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`
- `packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart`

## 6. Preuve que rien n’est créé à la racine du monorepo

Commande exécutée :

```text
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
```

Sortie réelle :

```text
<aucune sortie>
```

Le test `keeps enriched contract absent from the monorepo root` verrouille aussi explicitement ce point.

## 7. Preuve que `project.json` reste inchangé

Le test `leaves project.json strictly unchanged` :

1. crée un projet via `CreateProjectUseCase`
2. lit le `project.json`
3. exécute le use case
4. relit le `project.json`
5. compare le contenu brut avant/après

Résultat :

- `project.json` reste strictement identique

## 8. Tests réellement exécutés

Commande :

```text
flutter test test/initialize_pokemon_project_storage_use_case_test.dart
```

Résultat :

```text
00:01 +7: All tests passed!
```

Commandes et cas couverts :

- structure attendue dans le workspace projet
- confinement au `workspace.projectRoot`
- contrat JSON enrichi du manifeste
- contrat JSON enrichi des catalogues
- absence du contrat enrichi à la racine du monorepo
- idempotence
- non-écrasement d’un fichier existant
- `project.json` inchangé
- absence de déclenchement automatique

## 9. Analyse exécutée

Commande :

```text
flutter analyze --no-pub lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart test/initialize_pokemon_project_storage_use_case_test.dart
```

Résultat :

```text
No issues found! (ran in 0.9s)
```

## 10. Sorties Git utiles

### `git status --short`

```text
 M packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart
 M packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart
```

### État ciblé sur le lot

Commande :

```text
git status --short -- packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart reports/pokemon-project-workspace-json-contracts-lot-3-report.md
```

Sortie réelle au moment de la collecte :

```text
 M packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart
 M packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart
```

### `git diff --stat`

Commande :

```text
git diff --stat -- packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart reports/pokemon-project-workspace-json-contracts-lot-3-report.md
```

Sortie réelle :

```text
 ...nitialize_pokemon_project_storage_use_case.dart | 37 ++++++++++++++-
 ...lize_pokemon_project_storage_use_case_test.dart | 53 ++++++++++++++++++++++
 2 files changed, 89 insertions(+), 1 deletion(-)
```

## 11. Commandes réellement exécutées

```text
sed -n '1,240p' packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart
sed -n '1,320p' packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart
git status --short
flutter test test/initialize_pokemon_project_storage_use_case_test.dart
flutter analyze --no-pub lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart test/initialize_pokemon_project_storage_use_case_test.dart
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
git status --short
git status --short -- packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart reports/pokemon-project-workspace-json-contracts-lot-3-report.md
./review_bundle.sh
git diff --stat -- packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart reports/pokemon-project-workspace-json-contracts-lot-3-report.md
cat .review/review-20260408-212508.txt
```

## 12. `./review_bundle.sh` obligatoire

Commande exécutée :

```text
./review_bundle.sh
```

Chemin du fichier généré :

```text
.review/review-20260408-212508.txt
```

## 13. Contenu intégral du fichier généré

```text
# REVIEW BUNDLE

Generated at: 2026-04-08 21:25:08
Repository: pokemonProject
Branch: main
Base ref: HEAD
Head commit: e266743995ed6d368f9c469c7fc8c24c5f6e301a

## GIT STATUS --SHORT

 M packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart
 M packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart

## GIT DIFF --STAT

 ...nitialize_pokemon_project_storage_use_case.dart | 37 ++++++++++++++-
 ...lize_pokemon_project_storage_use_case_test.dart | 53 ++++++++++++++++++++++
 2 files changed, 89 insertions(+), 1 deletion(-)

## CHANGED FILES

packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart
packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart

## RECENT COMMITS

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
13127d3 Implement runtime completion gating for cutscenes in Step Studio
0587713 Implement defensive validation for Step Studio document persistence
650270b Implement auto-fix for completion normalization and enhance save validation in Step Studio

## FULL DIFF

diff --git a/packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart b/packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart
index 6ffb82f..676baf4 100644
--- a/packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart
+++ b/packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart
@@ -14,6 +14,24 @@ import '../ports/project_workspace.dart';
 class InitializePokemonProjectStorageUseCase {
   const InitializePokemonProjectStorageUseCase();
 
+  static const Map<String, String> _catalogDescriptions = <String, String>{
+    'moves': 'Move catalog for the local Pokemon project database.',
+    'abilities': 'Ability catalog for the local Pokemon project database.',
+    'items': 'Item catalog for the local Pokemon project database.',
+    'types': 'Type catalog for the local Pokemon project database.',
+    'growth_rates':
+        'Growth rate catalog for the local Pokemon project database.',
+    'natures': 'Nature catalog for the local Pokemon project database.',
+    'egg_groups': 'Egg group catalog for the local Pokemon project database.',
+    'habitats': 'Habitat catalog for the local Pokemon project database.',
+    'generations':
+        'Generation catalog for the local Pokemon project database.',
+    'version_groups':
+        'Version group catalog for the local Pokemon project database.',
+    'encounter_rules':
+        'Encounter rule catalog for the local Pokemon project database.',
+  };
+
   static const Map<String, String> _catalogFiles = <String, String>{
     'moves': 'catalogs/moves.json',
     'abilities': 'catalogs/abilities.json',
@@ -52,18 +70,35 @@ class InitializePokemonProjectStorageUseCase {
       <String, Object?>{
         'schemaVersion': 1,
         'kind': 'pokemon_data_manifest',
+        'meta': <String, Object?>{
+          'description':
+              'Root manifest for the local Pokemon data stored inside a project workspace.',
+          'notes': const <Object?>[],
+        },
         'catalogFiles': _catalogFiles,
+        'futureDataFolders': const <String, String>{
+          'species': 'species/',
+          'learnsets': 'learnsets/',
+          'evolutions': 'evolutions/',
+          'spriteSets': 'sprite_sets/',
+        },
       },
     );
 
     for (final entry in _catalogFiles.entries) {
+      final catalogName = _catalogNameForManifestKey(entry.key);
       await _writeJsonIfAbsent(
         workspace,
         'data/pokemon/${entry.value}',
         <String, Object?>{
           'schemaVersion': 1,
           'kind': 'pokemon_catalog',
-          'catalog': _catalogNameForManifestKey(entry.key),
+          'catalog': catalogName,
+          'meta': <String, Object?>{
+            'description': _catalogDescriptions[catalogName]!,
+            'sourcePriority': const <String>['internal'],
+            'notes': const <Object?>[],
+          },
           'entries': const <Object?>[],
         },
       );
diff --git a/packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart b/packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart
index 4146d91..041af07 100644
--- a/packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart
+++ b/packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart
@@ -109,6 +109,17 @@ void main() {
       );
       expect(manifest['schemaVersion'], 1);
       expect(manifest['kind'], 'pokemon_data_manifest');
+      expect(manifest['meta'], <String, Object?>{
+        'description':
+            'Root manifest for the local Pokemon data stored inside a project workspace.',
+        'notes': <Object?>[],
+      });
+      expect(manifest['futureDataFolders'], <String, Object?>{
+        'species': 'species/',
+        'learnsets': 'learnsets/',
+        'evolutions': 'evolutions/',
+        'spriteSets': 'sprite_sets/',
+      });
 
       final catalogFiles = manifest['catalogFiles'] as Map<String, dynamic>;
       expect(catalogFiles.keys, containsAll(<String>[
@@ -132,10 +143,36 @@ void main() {
         expect(catalog['schemaVersion'], 1);
         expect(catalog['kind'], 'pokemon_catalog');
         expect(catalog['catalog'], entry.key);
+        expect(catalog['meta'], <String, Object?>{
+          'description': _expectedCatalogDescriptions[entry.key]!,
+          'sourcePriority': <Object?>['internal'],
+          'notes': <Object?>[],
+        });
         expect(catalog['entries'], isEmpty);
       }
     });
 
+    test('keeps enriched contract absent from the monorepo root', () async {
+      await useCase.execute(workspace);
+
+      final rootManifest = File(
+        p.join(Directory.current.path, 'data', 'pokemon',
+            'pokemon_data_manifest.json'),
+      );
+      final rootMoves = File(
+        p.join(
+          Directory.current.path,
+          'data',
+          'pokemon',
+          'catalogs',
+          'moves.json',
+        ),
+      );
+
+      expect(await rootManifest.exists(), isFalse);
+      expect(await rootMoves.exists(), isFalse);
+    });
+
     test('is idempotent and never overwrites an existing json file', () async {
       await useCase.execute(workspace);
 
@@ -242,6 +279,22 @@ const Map<String, String> _expectedCatalogs = <String, String>{
   'encounter_rules': 'data/pokemon/catalogs/encounter_rules.json',
 };
 
+const Map<String, String> _expectedCatalogDescriptions = <String, String>{
+  'moves': 'Move catalog for the local Pokemon project database.',
+  'abilities': 'Ability catalog for the local Pokemon project database.',
+  'items': 'Item catalog for the local Pokemon project database.',
+  'types': 'Type catalog for the local Pokemon project database.',
+  'growth_rates': 'Growth rate catalog for the local Pokemon project database.',
+  'natures': 'Nature catalog for the local Pokemon project database.',
+  'egg_groups': 'Egg group catalog for the local Pokemon project database.',
+  'habitats': 'Habitat catalog for the local Pokemon project database.',
+  'generations': 'Generation catalog for the local Pokemon project database.',
+  'version_groups':
+      'Version group catalog for the local Pokemon project database.',
+  'encounter_rules':
+      'Encounter rule catalog for the local Pokemon project database.',
+};
+
 Future<Map<String, dynamic>> _readJsonMap(String path) async {
   final raw = await File(path).readAsString();
   return jsonDecode(raw) as Map<String, dynamic>;
```

## 14. Note honnête sur les limites du bundle

Dans ce lot précis, le bundle est propre :

- les fichiers modifiés sont tous des fichiers suivis
- `git diff` et `git diff --stat` reflètent correctement le périmètre

Il n’y a donc pas ici de limite particulière liée à des fichiers non suivis invisibles dans le diff.

## 15. Mini résumé final

### Ce qui a été fait

- enrichissement du manifeste JSON minimal
- enrichissement des catalogues JSON minimaux
- ajout de tests ciblés sur le nouveau contrat
- maintien strict de l’idempotence
- maintien strict du confinement au workspace projet
- maintien strict de l’invariance de `project.json`

### Ce qui n’a pas été fait

- aucune UI
- aucune donnée Pokémon réelle
- aucun modèle Dart Pokémon métier
- aucun import distant
- aucun runtime Pokémon
- aucune modification de `project.json`
- aucune opération Git d’écriture
