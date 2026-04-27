# Phase 10 — Lots 48 à 51

## Résumé exécutif

Les lots 48 à 51 sont couverts dans `examples/playable_runtime_host` avec une intégration minimale dans le host runtime existant :

- lot 48 : menu principal in-game
- lot 49 : écran Pokédex in-game en lecture seule
- lot 50 : écran Sac en lecture seule
- lot 51 : écran Dresseur en lecture seule

Le save system existant de la phase 9 a été réutilisé tel quel. Aucun nouveau modèle de save n’a été introduit. `project.json` n’a pas été modifié.

## Lots couverts

- lot 48 : couvert
- lot 49 : couvert
- lot 50 : couvert
- lot 51 : couvert

## Périmètre inclus

- ajout d’un bouton menu minimal dans le host runtime
- ajout d’une page de menu in-game simple
- ajout d’un chargeur runtime local pour la liste Pokédex affichée en jeu
- ajout de tests widget/data ciblés dans `examples/playable_runtime_host`
- passe de non-régression sur les tests save existants dans `packages/map_runtime`

## Périmètre exclu

- aucun lot 52+
- aucun écran de combat
- aucune édition Pokédex in-game
- aucun système vu/capturé
- aucune utilisation d’objet
- aucune modification du save format phase 9
- aucune modification de `project.json`
- aucune nouvelle architecture UI globale

## Design retenu

Le menu phase 10 est branché dans le host runtime existant, au-dessus du `GameWidget`, via une route Flutter simple.

La section Sauvegarde du menu réutilise les callbacks save/load déjà présents dans le host. Le bouton historique `Sauvegarder` reste en place et partage le même flux.

Pour le Pokédex in-game, je n’ai pas importé `PokemonDatabaseIndex` depuis `packages/map_editor`. Après audit contradictoire, cela aurait violé les frontières de packages. À la place, j’ai ajouté un chargeur runtime local au host qui lit `project.json`, résout `speciesDir` via `ProjectManifest`, parcourt `species/` et projette seulement les champs nécessaires à l’affichage en jeu.

Le Sac et le Dresseur lisent directement `GameState.bag` et `GameState.trainerProfile`, sans nouvel état global.

## Utilisation des sub-agents

Sub-agents utilisés :

- audit architecture : validation que la logique menu devait rester côté host/runtime et non dans `map_editor`
- audit UI minimale : validation qu’une route Flutter simple était le plus petit point d’intégration honnête
- audit contradictoire : rejet explicite d’une dépendance `map_editor -> runtime host` via `PokemonDatabaseIndex`
- review tests : confirmation que les tests actuels couvrent correctement les composants phase 10, avec une limite assumée sur l’absence de test end-to-end du host complet

Une seule implémentation finale a été conservée. Aucune variante concurrente n’a été laissée dans le working tree.

## Fichiers touchés

### Modifié

- `examples/playable_runtime_host/lib/main.dart`

### Créés

- `examples/playable_runtime_host/lib/src/in_game_menu.dart`
- `examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart`
- `examples/playable_runtime_host/test/in_game_menu_test.dart`
- `examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart`

### Non modifiés mais revalidés

- `packages/map_runtime/test/file_game_save_repository_test.dart`
- `packages/map_runtime/test/playable_map_game_public_getters_test.dart`

## Justification fichier par fichier

### `examples/playable_runtime_host/lib/main.dart`

- ajout du bouton d’ouverture du menu in-game
- centralisation des actions save/load pour qu’elles soient réutilisées à la fois par l’overlay historique et par le menu phase 10

### `examples/playable_runtime_host/lib/src/in_game_menu.dart`

- nouvelle page de menu in-game
- navigation minimale entre Pokédex, Sac, Dresseur et Sauvegarde
- lecture directe du snapshot `GameState`

### `examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart`

- projection légère des espèces locales pour l’écran Pokédex in-game
- lecture depuis `project.json` + `species/` sans dépendance sur le package éditeur

### `examples/playable_runtime_host/test/in_game_menu_test.dart`

- preuve de navigation entre sections
- preuve d’affichage correct des données `GameState`
- preuve que la section Sauvegarde relaie bien les callbacks fournis

### `examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart`

- preuve de lecture et tri des espèces locales depuis le projet

## Commandes réellement exécutées

```bash
find /Users/karim/Project/pokemonProject -name AGENTS.md -print
git status --short
git diff --stat
git log --oneline --decorate -n 12
rg -n "SaveGameUseCase|LoadGameUseCase|saveGame|loadGame|trainerProfile|bag|PokemonDatabaseIndex|project.json|speciesDir" /Users/karim/Project/pokemonProject
sed -n '1,260p' /Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/main.dart
sed -n '261,520p' /Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/main.dart
sed -n '1,320p' /Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/src/in_game_menu.dart
sed -n '321,640p' /Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/src/in_game_menu.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart
sed -n '1,260p' /Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/in_game_menu_test.dart
sed -n '1,220p' /Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart
dart format /Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/main.dart /Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/src/in_game_menu.dart /Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart /Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/in_game_menu_test.dart /Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart
flutter test test/in_game_menu_test.dart test/runtime_pokedex_loader_test.dart
flutter analyze --no-pub lib/main.dart lib/src/in_game_menu.dart lib/src/runtime_pokedex_loader.dart test/in_game_menu_test.dart test/runtime_pokedex_loader_test.dart
flutter test test/file_game_save_repository_test.dart test/playable_map_game_public_getters_test.dart
git status --short
git diff --stat
git ls-files --others --exclude-standard -- examples/playable_runtime_host/lib/src examples/playable_runtime_host/test reports/phase-10-lots-48-51-report.md
```

## Résultats réels

- `dart format`
  - `Formatted /Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/src/in_game_menu.dart`
  - `Formatted /Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart`
  - `Formatted 5 files (2 changed) in 0.02 seconds.`
  - reruns ciblés : `Formatted 2 files (0 changed) in 0.01 seconds.` puis `Formatted 1 file (0 changed) in 0.01 seconds.`

- `flutter test test/in_game_menu_test.dart test/runtime_pokedex_loader_test.dart`
  - passe finale : `All tests passed!`

- `flutter analyze --no-pub ...`
  - passe finale : `No issues found! (ran in 0.9s)`

- `flutter test test/file_game_save_repository_test.dart test/playable_map_game_public_getters_test.dart`
  - `All tests passed!`

## Incidents rencontrés

- premier test widget Pokédex trop optimiste sur la taille de surface par défaut ; corrigé en fixant une surface desktop plus réaliste
- assertion texte trop stricte sur le statut d’activation ; corrigée en `textContaining`
- deux `const` redondants signalés par l’analyse dans le test du chargeur ; retirés
- tentative initiale de lancer `flutter test` et `flutter analyze` en parallèle sur le même package : lock Flutter normal, puis relance en séquentiel

## État Git utile

`git status --short`

```text
 M examples/playable_runtime_host/lib/main.dart
?? examples/playable_runtime_host/lib/src/
?? examples/playable_runtime_host/test/
```

`git ls-files --others --exclude-standard -- examples/playable_runtime_host/lib/src examples/playable_runtime_host/test reports/phase-10-lots-48-51-report.md`

```text
examples/playable_runtime_host/lib/src/in_game_menu.dart
examples/playable_runtime_host/lib/src/runtime_pokedex_loader.dart
examples/playable_runtime_host/test/in_game_menu_test.dart
examples/playable_runtime_host/test/runtime_pokedex_loader_test.dart
```

## Limites restantes

- pas de test widget end-to-end qui charge réellement le host complet, ouvre `runtime-menu-button`, puis revient au jeu ; les tests actuels valident le menu et le chargeur au niveau composant
- l’écran Pokédex in-game n’utilise pas `PokemonDatabaseIndex` du package éditeur pour préserver les frontières de packages ; il repose sur une projection runtime locale minimale
- aucun design visuel avancé : la phase reste volontairement fonctionnelle et sobre

## Checklist finale

- [x] lots 48 à 51 couverts uniquement
- [x] aucun lot 52+
- [x] aucun changement `project.json`
- [x] aucun nouveau système de save
- [x] réutilisation de `GameState` et du pipeline save/load existant
- [x] UI minimale, sans sur-architecture
- [x] tests ciblés passent
- [x] analyse ciblée passe
- [x] sub-agents utilisés pour audit contradictoire et review
- [x] une seule implémentation finale conservée
- [x] rapport généré
