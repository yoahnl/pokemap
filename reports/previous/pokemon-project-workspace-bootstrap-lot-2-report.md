# Rapport — Lot 2 corrigé : initialisation Pokémon dans le workspace projet

## 1. Résumé exécutif

### Ce qui a été fait

Ce lot corrige la mauvaise direction du lot précédent en déplaçant la logique Pokémon hors de la racine du monorepo et en ajoutant un use case explicite côté `map_editor` :

- `InitializePokemonProjectStorageUseCase`

Ce use case sait initialiser, **dans le workspace d'un projet utilisateur uniquement**, la structure locale Pokémon suivante :

- `data/pokemon/species/`
- `data/pokemon/learnsets/`
- `data/pokemon/evolutions/`
- `data/pokemon/sprite_sets/`
- `data/pokemon/catalogs/`
- `assets/pokemon/sprites/`
- `assets/pokemon/cries/`
- `assets/pokemon/portraits/`

Il crée aussi, si absents :

- `data/pokemon/pokemon_data_manifest.json`
- les 11 fichiers catalogue JSON vides dans `data/pokemon/catalogs/`

Le lot inclut aussi le nettoyage ciblé de l'erreur précédente à la racine du monorepo :

- suppression de `./data/pokemon/...`
- suppression de `./assets/pokemon/...`
- suppression de `./data` et `./assets` seulement parce qu'ils étaient devenus vides

### Ce qui n'a pas été fait

Le lot ne fait volontairement pas les choses suivantes :

- pas de UI
- pas de provider Riverpod
- pas de déclenchement automatique à la création de projet
- pas de modification de `CreateProjectUseCase`
- pas de modification de `EditorNotifier.createProject()`
- pas de modification de `project.json`
- pas de modèle Dart Pokémon métier
- pas de repository Pokémon métier
- pas d'import Showdown / PokeAPI
- pas de logique runtime
- pas de données Pokémon réelles

### Pourquoi le lot reste petit

Le besoin ici est strictement infrastructurel. On ne veut pas encore brancher le système Pokémon au produit ; on veut uniquement une capacité sûre, explicite et testée pour préparer le stockage local **dans le projet utilisateur**.

## 2. Rappel explicite de l’erreur du lot précédent

La tentative précédente était mauvaise parce qu’elle créait :

- `./data/pokemon/...`
- `./assets/pokemon/...`

à la racine du monorepo source.

C’était un mauvais emplacement car ces fichiers sont des **données de projet utilisateur**, pas des fichiers du code source de l’éditeur.

La correction apportée dans ce lot est donc :

- suppression du faux contenu Pokémon à la racine du repo
- création de la structure Pokémon uniquement via `ProjectWorkspace`, donc sous `workspace.projectRoot`

## 3. Endroit exact où la correction a été ancrée

### Nouveau use case

Fichier créé :

- `packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`

Rôle :

- centraliser l’initialisation de la structure Pokémon d’un projet utilisateur
- écrire uniquement sous `workspace.projectRoot`
- laisser `project.json` intact
- rester idempotent

### Export du use case

Fichier modifié :

- `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

Rôle :

- rendre le nouveau use case visible dans le barrel existant des use cases

### Tests dédiés

Fichier créé :

- `packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart`

Rôle :

- prouver le confinement au workspace projet
- prouver l’idempotence
- prouver l’absence de pollution de `project.json`
- prouver l’absence de déclenchement automatique

## 4. Comportement exact du use case

Interface implémentée :

```dart
class InitializePokemonProjectStorageUseCase {
  Future<void> execute(ProjectWorkspace workspace);
}
```

Comportement exact :

1. Résout tous les chemins à partir de `workspace.resolveProjectRelativePath(...)`.
2. Crée les répertoires nécessaires dans le projet utilisateur.
3. Crée les JSON racines uniquement s’ils n’existent pas déjà.
4. N’écrase jamais un JSON existant.
5. N’écrit rien dans `project.json`.
6. Ne dépend pas du cwd et ne crée rien à la racine du monorepo.
7. Ne crée pas `data/pokemon/cries/`.
8. Ne recrée pas l’ancien `data/pokemon/media/`.

## 5. Liste exacte des chemins créés dans le projet utilisateur

### Répertoires

- `data/pokemon/species/`
- `data/pokemon/learnsets/`
- `data/pokemon/evolutions/`
- `data/pokemon/sprite_sets/`
- `data/pokemon/catalogs/`
- `assets/pokemon/sprites/`
- `assets/pokemon/cries/`
- `assets/pokemon/portraits/`

### Fichiers JSON

- `data/pokemon/pokemon_data_manifest.json`
- `data/pokemon/catalogs/moves.json`
- `data/pokemon/catalogs/abilities.json`
- `data/pokemon/catalogs/items.json`
- `data/pokemon/catalogs/types.json`
- `data/pokemon/catalogs/growth_rates.json`
- `data/pokemon/catalogs/natures.json`
- `data/pokemon/catalogs/egg_groups.json`
- `data/pokemon/catalogs/habitats.json`
- `data/pokemon/catalogs/generations.json`
- `data/pokemon/catalogs/version_groups.json`
- `data/pokemon/catalogs/encounter_rules.json`

## 6. Politique d’idempotence et de non-écrasement

Le use case applique une règle simple :

- si le fichier JSON cible existe déjà, il est laissé intact
- si le fichier n’existe pas, il est créé

Conséquences :

- relancer l’opération ne casse rien
- un fichier personnalisé manuellement par l’utilisateur n’est pas écrasé
- le bootstrap peut être relancé comme réparation douce sans perte de données

## 7. Formats JSON écrits

### Manifeste

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_data_manifest",
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
  }
}
```

### Catalogue vide

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "<catalog_name>",
  "entries": []
}
```

## 8. Preuve que `project.json` reste inchangé

Un test dédié crée un projet via le flux existant :

- `CreateProjectUseCase`
- `FileProjectRepository`
- `FileProjectWorkspaceFactory`

Ensuite :

1. lecture brute de `project.json`
2. exécution du bootstrap Pokémon
3. relecture brute de `project.json`
4. comparaison stricte du contenu

Résultat :

- `project.json` reste strictement identique

## 9. Nettoyage effectué à la racine du monorepo

Nettoyage réellement effectué :

- suppression de `./data/pokemon/...`
- suppression de `./assets/pokemon/...`

Puis suppression des conteneurs :

- `./data`
- `./assets`

mais uniquement parce qu’ils étaient devenus vides.

Vérification exécutée :

```text
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
```

Sortie réelle :

```text
<aucune sortie>
```

Donc aucun `./data` ou `./assets` ne subsiste désormais à la racine du monorepo.

## 10. Tests réellement ajoutés

Fichier :

- `packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart`

Cas couverts :

1. création complète de la structure dans un workspace temporaire réel
2. confinement des écritures sous `workspace.projectRoot`
3. validité JSON des fichiers créés
4. idempotence
5. non-écrasement d’un fichier existant
6. invariance stricte de `project.json`
7. absence de déclenchement automatique lors de `CreateProjectUseCase`
8. garde-fou sur l’absence de `data/pokemon/cries/`
9. garde-fou sur l’absence de l’ancien `data/pokemon/media/`

## 11. Validations réellement exécutées

### Tests ciblés

Commande exécutée :

```text
flutter test test/initialize_pokemon_project_storage_use_case_test.dart
```

Résultat réel :

```text
00:01 +6: All tests passed!
```

### Analyse ciblée

Commande exécutée :

```text
flutter analyze --no-pub lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart test/initialize_pokemon_project_storage_use_case_test.dart
```

Résultat réel :

```text
No issues found! (ran in 0.8s)
```

### Tentative de formatage

Commande exécutée :

```text
dart format packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart
```

Résultat réel :

```text
zsh:1: command not found: dart
```

Je n’ai pas remplacé cette commande par un bricolage. Le lot reste validé via les tests et l’analyse ciblée.

## 12. Commandes réellement exécutées

```text
ls packages/map_editor/lib/src/application/use_cases
ls packages/map_editor/test
find data assets -maxdepth 3 \( -type d -o -type f \) | sort
sed -n '1,240p' packages/map_editor/lib/src/application/use_cases/use_cases.dart
sed -n '1,240p' packages/map_editor/pubspec.yaml
rm -rf data/pokemon assets/pokemon && rmdir data 2>/dev/null || true && rmdir assets 2>/dev/null || true
dart format packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart
flutter test test/initialize_pokemon_project_storage_use_case_test.dart
flutter analyze lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart test/initialize_pokemon_project_storage_use_case_test.dart
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
flutter analyze --no-pub lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart test/initialize_pokemon_project_storage_use_case_test.dart
git status --short
git status --short -- packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart reports/pokemon-project-workspace-bootstrap-lot-2-report.md data assets
git diff --stat -- packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart data assets reports/pokemon-project-workspace-bootstrap-lot-2-report.md
git ls-files --others --exclude-standard -- packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart reports/pokemon-project-workspace-bootstrap-lot-2-report.md
./review_bundle.sh
cat .review/review-20260408-211422.txt
```

## 13. État Git

### `git status --short`

Sortie réelle :

```text
 D assets/pokemon/cries/.gitkeep
 D assets/pokemon/portraits/.gitkeep
 D assets/pokemon/sprites/.gitkeep
 D data/pokemon/catalogs/.gitkeep
 D data/pokemon/evolutions/.gitkeep
 D data/pokemon/learnsets/.gitkeep
 D data/pokemon/media/.gitkeep
 D data/pokemon/species/.gitkeep
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
?? packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart
?? packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart
?? reports/pokemon-data-lot-2-report.md
```

### État Git ciblé sur le périmètre du lot

Commande exécutée :

```text
git status --short -- packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart reports/pokemon-project-workspace-bootstrap-lot-2-report.md data assets
```

Sortie réelle :

```text
 D assets/pokemon/cries/.gitkeep
 D assets/pokemon/portraits/.gitkeep
 D assets/pokemon/sprites/.gitkeep
 D data/pokemon/catalogs/.gitkeep
 D data/pokemon/evolutions/.gitkeep
 D data/pokemon/learnsets/.gitkeep
 D data/pokemon/media/.gitkeep
 D data/pokemon/species/.gitkeep
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
?? packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart
?? packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart
```

### `git diff --stat` utile

Commande exécutée :

```text
git diff --stat -- packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart data assets reports/pokemon-project-workspace-bootstrap-lot-2-report.md
```

Sortie réelle :

```text
 assets/pokemon/cries/.gitkeep                                    | 1 -
 assets/pokemon/portraits/.gitkeep                                | 1 -
 assets/pokemon/sprites/.gitkeep                                  | 1 -
 data/pokemon/catalogs/.gitkeep                                   | 1 -
 data/pokemon/evolutions/.gitkeep                                 | 1 -
 data/pokemon/learnsets/.gitkeep                                  | 1 -
 data/pokemon/media/.gitkeep                                      | 1 -
 data/pokemon/species/.gitkeep                                    | 1 -
 packages/map_editor/lib/src/application/use_cases/use_cases.dart | 1 +
 9 files changed, 1 insertion(+), 8 deletions(-)
```

Note importante :

- les nouveaux fichiers non suivis du lot n’apparaissent pas dans `git diff --stat`
- c’est normal avec Git
- ils apparaissent bien dans `git status --short`
- ils apparaissent aussi dans :

```text
git ls-files --others --exclude-standard -- packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart reports/pokemon-project-workspace-bootstrap-lot-2-report.md
```

Sortie réelle :

```text
packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart
packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart
```

## 14. Fichiers modifiés / créés / supprimés

### Créés

- `packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`
- `packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart`
- `reports/pokemon-project-workspace-bootstrap-lot-2-report.md`

### Modifiés

- `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

### Supprimés

- `assets/pokemon/cries/.gitkeep`
- `assets/pokemon/portraits/.gitkeep`
- `assets/pokemon/sprites/.gitkeep`
- `data/pokemon/catalogs/.gitkeep`
- `data/pokemon/evolutions/.gitkeep`
- `data/pokemon/learnsets/.gitkeep`
- `data/pokemon/media/.gitkeep`
- `data/pokemon/species/.gitkeep`

## 15. `./review_bundle.sh`

### Commande exécutée

```text
./review_bundle.sh
```

### Fichier généré

```text
.review/review-20260408-211422.txt
```

### Contenu intégral du fichier généré

```text
# REVIEW BUNDLE

Generated at: 2026-04-08 21:14:22
Repository: pokemonProject
Branch: main
Base ref: HEAD
Head commit: c41fe7e193eb012febd35c14069563181f0b24eb

## GIT STATUS --SHORT

 D assets/pokemon/cries/.gitkeep
 D assets/pokemon/portraits/.gitkeep
 D assets/pokemon/sprites/.gitkeep
 D data/pokemon/catalogs/.gitkeep
 D data/pokemon/evolutions/.gitkeep
 D data/pokemon/learnsets/.gitkeep
 D data/pokemon/media/.gitkeep
 D data/pokemon/species/.gitkeep
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
?? packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart
?? packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart
?? reports/pokemon-data-lot-2-report.md

## GIT DIFF --STAT

 assets/pokemon/cries/.gitkeep                                    | 1 -
 assets/pokemon/portraits/.gitkeep                                | 1 -
 assets/pokemon/sprites/.gitkeep                                  | 1 -
 data/pokemon/catalogs/.gitkeep                                   | 1 -
 data/pokemon/evolutions/.gitkeep                                 | 1 -
 data/pokemon/learnsets/.gitkeep                                  | 1 -
 data/pokemon/media/.gitkeep                                      | 1 -
 data/pokemon/species/.gitkeep                                    | 1 -
 packages/map_editor/lib/src/application/use_cases/use_cases.dart | 1 +
 9 files changed, 1 insertion(+), 8 deletions(-)

## CHANGED FILES

assets/pokemon/cries/.gitkeep
assets/pokemon/portraits/.gitkeep
assets/pokemon/sprites/.gitkeep
data/pokemon/catalogs/.gitkeep
data/pokemon/evolutions/.gitkeep
data/pokemon/learnsets/.gitkeep
data/pokemon/media/.gitkeep
data/pokemon/species/.gitkeep
packages/map_editor/lib/src/application/use_cases/use_cases.dart

## RECENT COMMITS

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
27ab0c1 Add detailed tracing for world changes in Step Studio

## FULL DIFF

diff --git a/assets/pokemon/cries/.gitkeep b/assets/pokemon/cries/.gitkeep
deleted file mode 100644
index 8b13789..0000000
--- a/assets/pokemon/cries/.gitkeep
+++ /dev/null
@@ -1 +0,0 @@
-
diff --git a/assets/pokemon/portraits/.gitkeep b/assets/pokemon/portraits/.gitkeep
deleted file mode 100644
index 8b13789..0000000
--- a/assets/pokemon/portraits/.gitkeep
+++ /dev/null
@@ -1 +0,0 @@
-
diff --git a/assets/pokemon/sprites/.gitkeep b/assets/pokemon/sprites/.gitkeep
deleted file mode 100644
index 8b13789..0000000
--- a/assets/pokemon/sprites/.gitkeep
+++ /dev/null
@@ -1 +0,0 @@
-
diff --git a/data/pokemon/catalogs/.gitkeep b/data/pokemon/catalogs/.gitkeep
deleted file mode 100644
index 8b13789..0000000
--- a/data/pokemon/catalogs/.gitkeep
+++ /dev/null
@@ -1 +0,0 @@
-
diff --git a/data/pokemon/evolutions/.gitkeep b/data/pokemon/evolutions/.gitkeep
deleted file mode 100644
index 8b13789..0000000
--- a/data/pokemon/evolutions/.gitkeep
+++ /dev/null
@@ -1 +0,0 @@
-
diff --git a/data/pokemon/learnsets/.gitkeep b/data/pokemon/learnsets/.gitkeep
deleted file mode 100644
index 8b13789..0000000
--- a/data/pokemon/learnsets/.gitkeep
+++ /dev/null
@@ -1 +0,0 @@
-
diff --git a/data/pokemon/media/.gitkeep b/data/pokemon/media/.gitkeep
deleted file mode 100644
index 8b13789..0000000
--- a/data/pokemon/media/.gitkeep
+++ /dev/null
@@ -1 +0,0 @@
-
diff --git a/data/pokemon/species/.gitkeep b/data/pokemon/species/.gitkeep
deleted file mode 100644
index 8b13789..0000000
--- a/data/pokemon/species/.gitkeep
+++ /dev/null
@@ -1 +0,0 @@
-
diff --git a/packages/map_editor/lib/src/application/use_cases/use_cases.dart b/packages/map_editor/lib/src/application/use_cases/use_cases.dart
index 68cca2a..01bb007 100644
--- a/packages/map_editor/lib/src/application/use_cases/use_cases.dart
+++ b/packages/map_editor/lib/src/application/use_cases/use_cases.dart
@@ -3,6 +3,7 @@ export 'collision_use_cases.dart';
 export 'encounter_table_use_cases.dart';
 export 'trainer_use_cases.dart';
 export 'gameplay_zone_use_cases.dart';
+export 'initialize_pokemon_project_storage_use_case.dart';
 export 'layer_use_cases.dart';
 export 'map_use_cases.dart';
 export 'paint_use_cases.dart';
```

### Note honnête sur le bundle

Le bundle montre aussi un changement hors périmètre immédiat de cette implémentation :

- `?? reports/pokemon-data-lot-2-report.md`

Ce fichier provient de la tentative précédente déjà présente dans le working tree. Je ne l’ai pas supprimé, conformément à la consigne de ne pas toucher aux anciens rapports sans demande explicite.

Le bundle ne montre pas le nouveau rapport courant, car il a été généré avant l’écriture de ce fichier.

## 16. Mini résumé final

### Ce qui a été fait

- ajout d’un use case explicite et idempotent pour initialiser la structure Pokémon dans le projet utilisateur
- ajout de tests ciblés et réels
- nettoyage de l’erreur précédente à la racine du monorepo
- validation ciblée via tests, analyse et bundle de revue

### Ce qui n’a pas été fait

- aucun branchement UI
- aucun auto-déclenchement
- aucune modification de `project.json`
- aucun modèle Pokémon métier
- aucun runtime Pokémon
- aucun import externe
- aucune opération Git d’écriture
