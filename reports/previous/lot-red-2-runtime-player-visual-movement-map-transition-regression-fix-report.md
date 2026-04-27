# Lot RED-2 Runtime Player Visual Movement / Map Transition Regression Fix

## 1. Résumé exécutif honnête

RED-2 corrige la régression visuelle runtime encore visible après RED-1 :

- léger décalage du joueur après changement de map ;
- sensation d'accélération/décélération sur les transitions `connection` ;
- instabilité visuelle du rendu joueur pendant les steps.

La cause n'était pas dans `map_battle`, ni dans le BAG battle.

Le problème venait d'un mélange de deux conventions runtime :

- `PlayerComponent.position` suivait déjà le top-left du sprite rendu via `playerPositionPx` ;
- mais le sprite enfant `OverworldActorComponent` recevait encore un offset local hérité de l'ancien modèle grille/footprint ;
- et les `connection` continuaient à lancer une interpolation visuelle après changement de map à partir d'une position encore exprimée dans le repère de la map source ;
- de plus, l'interpolation du joueur arrondissait chaque frame, ce qui créait des deltas irréguliers perceptibles.

Le correctif retenu garde une convention unique :

- `PlayerComponent.position` = top-left du sprite rendu ;
- l'acteur enfant est layouté relativement à la taille logique du sprite joueur, pas relativement à une cellule de footprint ;
- `connection` snappe désormais directement dans le repère cible ;
- les steps du joueur interpolent en `double` sans arrondi par frame.

## 2. Pré-gates initiaux exacts

Sorties exactes au démarrage de ce lot :

```bash
git status --short --untracked-files=all
```

```bash
git diff --stat
```

```bash
git ls-files --others --exclude-standard
```

## 3. Classification de la dirtiness initiale

- `preexisting_in_scope`: aucune
- `preexisting_out_of_scope`: aucune
- `created_by_this_lot`: aucun fichier au démarrage
- `modified_by_this_lot`:
  - `packages/map_runtime/lib/src/presentation/flame/player_component.dart`
  - `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
  - `packages/map_runtime/test/playable_map_game_input_test.dart`
  - `packages/map_runtime/test/player_component_test.dart`
  - ce report

## 4. Fichiers lus

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/player_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `/Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/gameplay_player_state.dart`
- `/Users/karim/Project/pokemonProject/packages/map_core/lib/src/collision/player_collision_conventions_v1.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/playable_map_game_input_test.dart`
- `/Users/karim/Project/pokemonProject/project_overview.txt`

Demandé mais indisponible dans le workspace :

- `/Users/karim/Project/pokemonProject/project_overview_old.txt`

## 5. Diagnostic racine

### 5.1 Convention visuelle réellement en place avant fix

Avant correction :

- `PlayerComponent.position` représentait déjà le top-left du sprite rendu, via `GameplayPlayerState.playerPositionPx` ;
- `PlayerComponent.size` représentait déjà la taille du sprite logique ;
- `focusPoint` utilisait le centre du sprite rendu ;
- mais l'enfant `OverworldActorComponent` recevait encore un offset local calculé comme s'il fallait le repositionner depuis une cellule grille 1x1.

Concrètement, pour un sprite joueur standard 2x2 :

- le parent était déjà placé au bon top-left ;
- puis l'enfant était de nouveau décalé vers le haut et parfois vers la gauche ;
- ce qui produisait un double-offset visuel.

### 5.2 Transition `connection` dans le mauvais repère

Dans `PlayableMapGame._handleConnection(...)` :

- le runtime changeait déjà de bundle/map/origin ;
- puis lançait encore `startStep(...)` sur `_player` ;
- avec `_moveFrom` issu de l'ancienne position écran ;
- et `_moveTo` calculé dans le repère cible.

Cela animait visuellement le joueur entre deux systèmes de coordonnées distincts.

### 5.3 Deltas de mouvement irréguliers

`PlayerComponent.update(...)` arrondissait chaque frame avec `roundToDouble()`.

Conséquence :

- deltas par frame irréguliers ;
- impression d'accélération/décélération ou de rattrapage final ;
- trajectoire moins stable visuellement qu'avant.

## 6. Convention retenue

Convention finale retenue :

- `PlayerComponent.position` reste le top-left du sprite rendu ;
- `PlayerComponent.size` reste la taille logique du sprite ;
- `focusPoint` reste le centre du sprite rendu ;
- `footPoint` est désormais dérivé de la position courante rendue du parent, pas du target state déjà commité ;
- l'acteur enfant est layouté relativement à `PlayerComponent.size`, donc sans double-offset pour le sprite standard et avec un offset dérivé propre si un sprite plus grand arrive plus tard.

Pourquoi ce choix :

- c'est la convention déjà la plus avancée dans le runtime ;
- elle reste cohérente avec `GameplayPlayerState.playerPositionPx` ;
- elle évite de rebasculer le runtime vers un ancien modèle grille au moment où le gameplay pixel-level existe déjà ;
- elle permet un correctif petit et local à `map_runtime`.

## 7. Corrections appliquées

### 7.1 `packages/map_runtime/lib/src/presentation/flame/player_component.dart`

Corrections apportées :

- `footPoint` dérive maintenant de `position` et de la taille logique du sprite courant ;
- ajout d'un layout local `_layoutActor()` basé sur `PlayerComponent.size` ;
- suppression de l'ancien offset local du joueur fondé sur `frameWidthTiles` et `footOffsetY` ;
- suppression de l'arrondi par frame dans `update(...)` ;
- suppression de l'arrondi dans `_snapToStatePosition()` ;
- relayout du child acteur lors des syncs et au démarrage de step ;
- ajout d'un getter de debug `debugActorLocalPosition`.

Effet produit :

- plus de double-offset visuel sur le sprite joueur ;
- deltas de mouvement réguliers ;
- `footPoint` cohérent avec le rendu courant pendant l'interpolation.

### 7.2 `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Corrections apportées :

- ajout d'un getter de debug `debugPlayerActorLocalPosition` ;
- dans `_handleConnection(...)`, suppression du `startStep(...)` cross-map ;
- `connection` fait maintenant :
  - changement de map/origin ;
  - `syncState(..., snapToGrid: true)` ;
  - resync caméra immédiat.

Effet produit :

- plus d'interpolation entre les coordonnées visuelles de la map source et celles de la map cible ;
- plus de glissement résiduel ni de petite inertie perceptible sur `connection`.

## 8. Tests ajoutés / renforcés

### 8.1 Nouveau fichier

- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/player_component_test.dart`

Tests ajoutés :

- `player actor offset is not applied twice`
- `cardinal step has stable frame deltas`

Ce qu'ils prouvent :

- le sprite joueur standard n'est plus localement décalé une seconde fois ;
- les deltas successifs pendant un step sont réguliers ;
- la fin de step atteint exactement la position attendue.

### 8.2 Renfort de `playable_map_game_input_test.dart`

Tests ajoutés :

- `connection transition does not animate from previous map visual coordinates`
- `warp transition snaps cleanly after fade and does not interpolate across maps`

Les tests RED-1 déjà présents restent utiles :

- `one cardinal step lands on the expected cell without a visual offset`
- `warp transition keeps the player visually aligned to the logical target`
- `connection transition keeps the player visually aligned to the logical target`

Ce qu'ils prouvent ensemble :

- la position finale est correcte ;
- la transition ne continue pas à bouger après swap ;
- `connection` ne réanime pas un step cross-map ;
- `warp` reste un snap propre après fade ;
- le bug n'est pas masqué par une formule de fin partagée.

## 9. Fichiers modifiés / créés

Modifiés :

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/player_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/playable_map_game_input_test.dart`

Créé :

- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/player_component_test.dart`

Volontairement non touchés :

- `packages/map_battle/**`
- `packages/map_editor/**`
- `packages/map_core/**`
- `packages/map_gameplay/**`
- logique BAG/battle

## 10. Preuve que le patch ne poursuit pas battle/BAG

Le patch ne touche pas :

- la capture ;
- les menus BAG ;
- les choix battle ;
- la logique de soin ;
- le moteur battle.

Il se borne à :

- convention de rendu joueur ;
- interpolation visuelle du joueur ;
- transition de map runtime ;
- tests de non-régression visuelle.

## 11. Validations exécutées et résultats

Commandes exécutées :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter analyze --no-pub \
  lib/src/presentation/flame/player_component.dart \
  lib/src/presentation/flame/playable_map_game.dart \
  test/player_component_test.dart \
  test/playable_map_game_input_test.dart \
  test/playable_map_game_whiteout_lite_test.dart \
  test/wild_battle_end_to_end_flow_test.dart
```

Résultat :

- `No issues found!`

```bash
cd /Users/karim/Project/pokemonProject/packages/map_gameplay
dart test
```

Résultat :

- `All tests passed!`

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter test \
  test/player_component_test.dart \
  test/playable_map_game_input_test.dart \
  test/playable_map_game_whiteout_lite_test.dart \
  test/wild_battle_end_to_end_flow_test.dart
```

Résultat :

- `All tests passed!`

```bash
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host
flutter test test/phase_a_golden_slice_launch_test.dart
```

Résultat :

- `All tests passed!`

## 12. Revue séparée

Review lancée sur :

- `player_component.dart`
- `playable_map_game.dart`
- `player_component_test.dart`
- `playable_map_game_input_test.dart`

Retour du reviewer séparé :

- `No findings.`
- limitation honnête du reviewer : il n'avait pas `flutter` dans son environnement pour rerun les tests lui-même.

## 13. Limites assumées

Ce lot ne ferme pas :

- un éventuel polish caméra plus large ;
- une refonte globale des offsets visuels de tous les actors ;
- une instrumentation plus fine des trajectoires pendant fade/transition avec capture frame par frame du host réel.

Il corrige la régression produit décrite :

- stabilité du joueur ;
- absence de glissement cross-map ;
- deltas de mouvement réguliers.

## 14. Ce qui est reporté

Reste explicitement hors scope :

- tout lot battle/BAG ;
- tout changement `map_battle` ;
- tout nouveau système collision ;
- tout nouveau système caméra.

## 15. État git final exact

```bash
git status --short --untracked-files=all
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/lib/src/presentation/flame/player_component.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
?? packages/map_runtime/test/player_component_test.dart
```

```bash
git diff --stat
 .../src/presentation/flame/playable_map_game.dart  |  19 +--
 .../src/presentation/flame/player_component.dart   |  46 ++++---
 .../test/playable_map_game_input_test.dart         | 138 +++++++++++++++++++++
 3 files changed, 174 insertions(+), 29 deletions(-)
```

```bash
git ls-files --others --exclude-standard
packages/map_runtime/test/player_component_test.dart
```

## 16. Décision finale

RED-2 est réussi.

Le runtime joueur retrouve une convention visuelle cohérente :

- pas de double-offset du sprite joueur ;
- pas d'interpolation `connection` entre ancienne et nouvelle map ;
- pas de mouvement résiduel après `warp` ;
- pas de deltas irréguliers perceptibles sur un step cardinal ;
- le correctif reste strictement borné à `map_runtime`.
