# Rapport — Lot 4 Pokémon : mini dataset métier de démonstration dans le workspace projet

## 1. Résumé exécutif

Ce lot ajoute un nouveau use case explicite côté `map_editor` pour générer un mini dataset Pokémon réaliste dans le **workspace projet utilisateur**, sans toucher au runtime, au combat, à l’UI ni à `project.json`.

Le lot crée un “contrat vivant” minimal autour de :

- 2 espèces : `bulbasaur`, `ivysaur`
- 2 learnsets séparés
- 2 fichiers d’évolutions séparés
- 4 catalogues enrichis : `moves`, `abilities`, `types`, `growth_rates`

Le tout reste :

- petit
- idempotent
- non destructif
- strictement confiné au workspace projet

## 2. Périmètre exact du lot

Ce lot fait uniquement :

- un nouveau use case : `SeedPokemonDemoDataUseCase`
- un test dédié : `seed_pokemon_demo_data_use_case_test.dart`
- un export dans le barrel des use cases

Ce lot ne fait pas :

- d’UI
- de provider Riverpod
- d’import Showdown / PokeAPI
- de repository Pokémon complet
- de runtime Pokémon
- de modèle Dart Pokémon global
- de branchement à `project.json`
- de données massives

## 3. Fichiers modifiés / créés

### Créés

- `packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart`
- `packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart`
- `reports/pokemon-demo-data-seed-lot-4-report.md`

### Modifié

- `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

## 4. Liste exacte des fichiers métier créés dans le workspace projet

Le use case écrit dans le **workspace projet utilisateur**, jamais dans le monorepo :

### Espèces

- `data/pokemon/species/0001-bulbasaur.json`
- `data/pokemon/species/0002-ivysaur.json`

### Learnsets

- `data/pokemon/learnsets/bulbasaur.json`
- `data/pokemon/learnsets/ivysaur.json`

### Évolutions

- `data/pokemon/evolutions/bulbasaur.json`
- `data/pokemon/evolutions/ivysaur.json`

### Catalogues enrichis

- `data/pokemon/catalogs/moves.json`
- `data/pokemon/catalogs/abilities.json`
- `data/pokemon/catalogs/types.json`
- `data/pokemon/catalogs/growth_rates.json`

## 5. Description du format retenu

### 5.1 Espèces

Format retenu pour une espèce de démonstration :

- `id`
- `slug`
- `nationalDex`
- `names`
- `speciesName`
- `genIntroduced`
- `typing`
- `baseStats`
- `abilities`
- `breeding`
- `progression`
- `evolutionRef`
- `learnsetRef`
- `spriteSetRef`
- `cryRef`
- `dexContent`
- `gameplayFlags`
- `sourceMeta`

Exemple de logique :

- `bulbasaur` référence `learnsetRef: "bulbasaur"`
- `bulbasaur` référence `evolutionRef: "bulbasaur"`
- `bulbasaur` référence `spriteSetRef: "bulbasaur"`
- `bulbasaur` référence `cryRef: "bulbasaur"`

Le schéma reste volontairement crédible pour la suite, sans introduire 200 champs inutiles.

### 5.2 Learnsets

Format retenu :

- `speciesId`
- `startingMoves`
- `relearnMoves`
- `levelUp`

Les entrées `levelUp` sont explicites :

```json
{
  "moveId": "tackle",
  "level": 1,
  "source": "level_up",
  "versionGroup": "demo"
}
```

Ce point répond directement au besoin produit : pouvoir dire clairement qu’un Pokémon apprend telle attaque à tel niveau.

### 5.3 Évolutions

Format retenu :

- `speciesId`
- `preEvolution`
- `evolutions`

Pour Bulbasaur :

```json
{
  "speciesId": "bulbasaur",
  "preEvolution": null,
  "evolutions": [
    {
      "targetSpeciesId": "ivysaur",
      "method": "level_up",
      "minLevel": 16
    }
  ]
}
```

Pour Ivysaur :

- `preEvolution: "bulbasaur"`
- `evolutions: []`

### 5.4 Catalogues enrichis

Les catalogues enrichis contiennent maintenant de vraies entrées de démonstration.

#### `types.json`

Entrées créées :

- `grass`
- `poison`

Champs retenus :

- `id`
- `name`
- `names`
- `damageRelations`

#### `abilities.json`

Entrées créées :

- `overgrow`
- `chlorophyll`

Champs retenus :

- `id`
- `name`
- `names`
- `shortDesc`
- `generation`

#### `growth_rates.json`

Entrée créée :

- `medium_slow`

Champs retenus :

- `id`
- `name`
- `description`

#### `moves.json`

Entrées créées :

- `tackle`
- `growl`
- `vine_whip`
- `razor_leaf`

Champs retenus :

- `id`
- `name`
- `names`
- `type`
- `category`
- `power`
- `accuracy`
- `pp`
- `priority`
- `target`
- `shortDesc`
- `generation`

## 6. Explication des références croisées

Le mini dataset valide les liens métier suivants :

### Bulbasaur

- espèce : `learnsetRef = "bulbasaur"`
- learnset : `speciesId = "bulbasaur"`
- espèce : `evolutionRef = "bulbasaur"`
- évolution : `speciesId = "bulbasaur"`

### Ivysaur

- espèce : `learnsetRef = "ivysaur"`
- espèce : `evolutionRef = "ivysaur"`
- évolution : `preEvolution = "bulbasaur"`

### Learnset avec niveaux explicites

Bulbasaur apprend au minimum :

- `tackle`
- `growl`
- `vine_whip`
- `razor_leaf`

avec niveaux explicites et `versionGroup: "demo"`.

## 7. Comportement du use case

Le use case :

1. appelle `InitializePokemonProjectStorageUseCase`
2. s’assure donc que la structure de base existe
3. crée les fichiers métier absents
4. enrichit les catalogues globaux minimums
5. ne touche jamais à `project.json`
6. ne touche jamais à la racine du monorepo

### Règle importante sur le non-écrasement

Pour les fichiers métier :

- si le fichier existe déjà, il est laissé intact

Pour les catalogues :

- s’ils sont encore au format scaffold vide du lot précédent, ils sont enrichis une seule fois
- s’ils ont déjà été modifiés manuellement, ils sont laissés intacts

Cela permet à la fois :

- un premier seed utile sur un projet fraîchement initialisé
- un comportement non destructif quand un utilisateur commence à personnaliser le dataset

## 8. Preuve que `project.json` est inchangé

Le test `leaves project.json strictly unchanged` :

1. crée un projet via `CreateProjectUseCase`
2. lit le contenu brut de `project.json`
3. exécute `SeedPokemonDemoDataUseCase`
4. relit le contenu brut de `project.json`
5. compare avant/après

Résultat :

- `project.json` reste strictement identique

## 9. Preuve que rien n’est créé à la racine du monorepo

Commande exécutée :

```text
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
```

Sortie réelle :

```text
<aucune sortie>
```

Le test `creates nothing under the monorepo root` verrouille aussi ce point en vérifiant explicitement que les fichiers seeded n’apparaissent pas sous `Directory.current.path/data/...`.

## 10. Tests réellement exécutés

Commande :

```text
flutter test test/seed_pokemon_demo_data_use_case_test.dart
```

Résultat :

```text
00:01 +6: All tests passed!
```

Cas couverts :

1. création des fichiers métier attendus
2. aucune création à la racine du monorepo
3. validité JSON
4. cohérence des références croisées
5. présence d’entrées `levelUp` avec `moveId`, `level`, `source`, `versionGroup`
6. idempotence
7. non-écrasement d’un fichier métier
8. non-écrasement d’un catalogue modifié manuellement
9. `project.json` inchangé

## 11. Analyse exécutée

Commande :

```text
flutter analyze --no-pub lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart test/seed_pokemon_demo_data_use_case_test.dart
```

Résultat :

```text
No issues found! (ran in 1.2s)
```

## 12. Sorties Git

### `git status --short`

```text
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
?? packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart
?? packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart
```

### Sortie ciblée du lot

Commande :

```text
git status --short -- packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart reports/pokemon-demo-data-seed-lot-4-report.md
```

Sortie réelle au moment de la collecte :

```text
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
?? packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart
?? packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart
```

### `git diff --stat`

Commande :

```text
git diff --stat -- packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart reports/pokemon-demo-data-seed-lot-4-report.md
```

Sortie réelle :

```text
 packages/map_editor/lib/src/application/use_cases/use_cases.dart | 1 +
 1 file changed, 1 insertion(+)
```

### Pourquoi ce diff est partiel

Le bundle et `git diff --stat` n’affichent ici que :

- la modification du fichier suivi `use_cases.dart`

Ils n’affichent pas :

- `seed_pokemon_demo_data_use_case.dart`
- `seed_pokemon_demo_data_use_case_test.dart`
- ce rapport

car ces fichiers sont encore **non suivis** par Git.

Commande utile exécutée pour le prouver :

```text
git ls-files --others --exclude-standard -- packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart reports/pokemon-demo-data-seed-lot-4-report.md
```

Sortie réelle :

```text
packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart
packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart
```

## 13. Commandes réellement exécutées

```text
sed -n '1,260p' packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart
sed -n '1,360p' packages/map_editor/test/initialize_pokemon_project_storage_use_case_test.dart
sed -n '1,240p' packages/map_editor/lib/src/application/use_cases/use_cases.dart
git status --short
flutter test test/seed_pokemon_demo_data_use_case_test.dart
flutter analyze --no-pub lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart test/seed_pokemon_demo_data_use_case_test.dart
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
git status --short
git status --short -- packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart reports/pokemon-demo-data-seed-lot-4-report.md
git diff --stat -- packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart reports/pokemon-demo-data-seed-lot-4-report.md
./review_bundle.sh
cat .review/review-20260408-213637.txt
git ls-files --others --exclude-standard -- packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart reports/pokemon-demo-data-seed-lot-4-report.md
```

## 14. `./review_bundle.sh` obligatoire

Commande exécutée :

```text
./review_bundle.sh
```

Chemin du fichier généré :

```text
.review/review-20260408-213637.txt
```

## 15. Contenu intégral du fichier généré

```text
# REVIEW BUNDLE

Generated at: 2026-04-08 21:36:37
Repository: pokemonProject
Branch: main
Base ref: HEAD
Head commit: c4d298328e24865ad98461fcec4812c704c96dc8

## GIT STATUS --SHORT

 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
?? packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart
?? packages/map_editor/test/seed_pokemon_demo_data_use_case_test.dart

## GIT DIFF --STAT

 packages/map_editor/lib/src/application/use_cases/use_cases.dart | 1 +
 1 file changed, 1 insertion(+)

## CHANGED FILES

packages/map_editor/lib/src/application/use_cases/use_cases.dart

## RECENT COMMITS

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
7a137dd Remove LOT 50 demo scenario and inject logic; add FPS overlay support
13127d3 Implement runtime completion gating for cutscenes in Step Studio
0587713 Implement defensive validation for Step Studio document persistence

## FULL DIFF

diff --git a/packages/map_editor/lib/src/application/use_cases/use_cases.dart b/packages/map_editor/lib/src/application/use_cases/use_cases.dart
index 01bb007..6a4b084 100644
--- a/packages/map_editor/lib/src/application/use_cases/use_cases.dart
+++ b/packages/map_editor/lib/src/application/use_cases/use_cases.dart
@@ -13,6 +13,7 @@ export 'project_group_use_cases.dart';
 export 'project_management_use_cases.dart';
 export 'project_scenario_use_cases.dart';
 export 'project_tileset_use_cases.dart';
+export 'seed_pokemon_demo_data_use_case.dart';
 export 'terrain_preset_use_cases.dart';
 export 'terrain_use_cases.dart';
 export 'warp_use_cases.dart';
```

## 16. Mini résumé final

### Ce qui a été fait

- ajout d’un use case explicite pour seed un mini dataset Pokémon réaliste
- création de deux espèces, deux learnsets, deux fichiers d’évolution
- enrichissement minimum de `moves`, `abilities`, `types`, `growth_rates`
- validation des références croisées et des niveaux d’apprentissage
- maintien du confinement au workspace projet
- maintien du non-écrasement et de l’idempotence

### Ce qui n’a pas été fait

- aucune UI
- aucun import externe
- aucun runtime
- aucune modification de `project.json`
- aucun modèle Dart Pokémon complet
- aucune opération Git d’écriture
