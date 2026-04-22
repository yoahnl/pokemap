# Lot RED-5 — Runtime Connection Tile-Space Continuity + Movement Speed Restore

## 1. Resume executif honnete

RED-5 a corrige la vraie cause commune des symptomes restants sans rouvrir battle, BAG, `map_battle` ou `map_editor`.

La regression ne venait pas d’un nouveau recalcul camera dans `_handleConnection(...)`. Le coeur du bug etait que le runtime envoyait encore des `MoveIntent` a pas fixe de `16 px`, meme quand le projet courant utilisait des tiles plus grandes. Sur les maps `32 px` et `64 px`, cela creait des demi-pas ou micro-pas visuels :

- le joueur changeait de cellule logique avant d’avoir parcouru toute la largeur visuelle d’une case ;
- une connection pouvait donc se declencher alors que le sprite n’etait pas encore aligne sur la couture de map ;
- la couture decor/camera sautait encore, meme si RED-4 preservait deja le screen-space du joueur ;
- la marche paraissait plus lente ;
- les checks encounter pouvaient se repeter inutilement pour la meme cellule logique.

Le correctif RED-5 a donc :

- aligne le pas runtime joueur sur `tileWidthPx` / `tileHeightPx` du projet courant ;
- ajoute des seams de debug pour verifier la continuite tile-space, pas seulement la position ecran du joueur ;
- borne les checks/logs encounter pour ne plus repasser sur la meme cellule/logique.

## 2. Etat git initial exact

Sorties executees avant modification :

### `git status --short --untracked-files=all`

```text
 M packages/map_gameplay/.dart_tool/package_config.json
```

### `git diff --stat`

```text
 packages/map_gameplay/.dart_tool/package_config.json | 2 --
 1 file changed, 2 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
```

## 3. Classification de la dirtiness initiale

- `preexisting_in_scope`: aucune
- `preexisting_out_of_scope`: `packages/map_gameplay/.dart_tool/package_config.json`
- `created_by_this_lot`: aucun fichier au depart
- `modified_by_this_lot`: aucun fichier au depart

## 4. Fichiers lus

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/player_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/player_component_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/playable_map_game_input_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/gameplay_step.dart`
- `/Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/gameplay_intent.dart`
- `/Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/gameplay_step_result.dart`
- `/Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/gameplay_player_state.dart`
- `/Users/karim/Project/pokemonProject/packages/map_core/lib/src/collision/player_collision_conventions_v1.dart`

## 5. Fichiers modifies / crees

Modifies :

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/playable_map_game_input_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/player_component_test.dart`

Crees :

- `/Users/karim/Project/pokemonProject/reports/lot-red-5-runtime-connection-tile-space-continuity-movement-speed-restore-report.md`

## 6. Fichiers volontairement non touches

- tout `packages/map_battle/**`
- tout `packages/map_editor/**`
- tout `packages/map_core/**`
- tout `packages/map_gameplay/**`
- tout le BAG battle
- tout le handoff battle hors garde-fous de non-regression
- tout le pipeline warp/battle RED-4, hormis verification de non-regression

## 7. Comportement obtenu

Apres RED-5 :

- la marche overworld utilise a nouveau un pas complet adapte a la taille de tile du projet ;
- maintenir une direction enchaine les pas sans trou artificiel ;
- la couture de connection reste stable en tile-space sur le cas qui cassait encore RED-4 ;
- la continuite testee ne couvre plus seulement le sprite joueur, mais aussi la projection du seam de map ;
- les checks encounter ne repassent plus sur la meme cellule logique deja evaluee ;
- les logs encounter negatifs ne spamment plus par defaut.

## 8. Diagnostic racine

Le runtime fabriquait ses intentions de mouvement avec :

```text
MoveIntent(direction)
```

ce qui laissait `pixelsPerStep = 16` via `PlayerCollisionConventionsV1.defaultMoveStepPixels`.

Sur des projets dont les tiles gameplay valaient `32 px` ou `64 px`, cela produisait un decalage entre :

- la progression logique du joueur ;
- la progression visuelle du sprite ;
- le moment ou une connection se declenche.

Le bug produit restant de RED-4 venait donc surtout de cette incoherence de pas :

- RED-4 preservait bien le joueur en screen-space ;
- mais le seam decor/camera pouvait encore sauter, parce que le joueur etait deja logiquement au bord alors que visuellement il n’avait pas encore fini son tile complet.

## 9. Correctif applique

### 9.1 Pas runtime aligne sur la taille de tile

Dans `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`, `_intentFromPressedMovementControls()` cree maintenant des `MoveIntent` avec un pas dependant du projet courant :

- est / ouest : `_world.tileWidthPx`
- nord / sud : `_world.tileHeightPx`

Cela restaure :

- un pas visuel complet par cellule ;
- une vitesse percue normale ;
- une connection declenchee au bon moment visuel.

### 9.2 Garde-fous debug tile-space

Ajouts `@visibleForTesting` dans `PlayableMapGame` :

- `debugMapOriginWorldTopLeft`
- `debugMapCellWorldTopLeft(GridPos cell)`
- `debugWorldToScreen(Vector2 worldPoint)`
- `debugEncounterCheckCount`

Ces seams permettent enfin de tester la projection du decor/seam, pas seulement `debugPlayerScreenTopLeft`.

### 9.3 Checks / logs encounter bornes

Ajouts :

- compteur debug `_debugEncounterCheckCount`
- marqueur `_EncounterCheckMarker(mapId, pos, kind)`

Effet :

- pas de reevaluation encounter pour le meme triplet `map + cellule + kind`
- plus de spam des statuts negatifs encounter par defaut

## 10. Preuve que RED-5 ne reouvre pas RED-4

RED-5 n’a pas retouche :

- le calcul du visual entry step de connection ;
- le defer reserve au visual step de connection ;
- le handoff battle ;
- le pipeline warp.

Le lot s’est contente de corriger la semantique amont du deplacement runtime et d’ajouter les seams de verification necessaires.

## 11. Tests ajoutes / renforces et ce qu’ils prouvent

Dans `/Users/karim/Project/pokemonProject/packages/map_runtime/test/playable_map_game_input_test.dart` :

- `normal overworld walk step uses the full tile width on 32px maps`
  - prouve qu’un pas simple couvre bien toute la largeur d’une tile `32 px`
  - verrouille la disparition du demi-pas visuel

- `held directional input chains full-tile steps without an idle gap`
  - prouve qu’un maintien de direction enchaine plusieurs pas complets
  - verrouille l’absence de pause artificielle entre deux steps

- `walk encounter check runs once per completed movement step`
  - prouve qu’un pas complet ne declenche qu’un seul check encounter
  - verrouille la non-repetition sur la meme cellule logique

- `connection preserves tile-space camera continuity, not only player screen continuity`
  - prouve la couture tile-space sur un cas a deux temps qui reproduit le bug restant
  - compare le seam projete source et le seam projete cible, pas seulement le sprite joueur

Dans `/Users/karim/Project/pokemonProject/packages/map_runtime/test/player_component_test.dart` :

- `normal overworld walk step progresses on the first update`
  - prouve que le defer de premiere frame ne ralentit pas la marche normale
  - verrouille que ce defer reste reserve au visual step de transition

## 12. Mesures / logs a retenir

### Connection

Log representatif apres fix sur le cas RED-5 :

```text
[connection] screen continuity sourceScreen=(16.0, 16.0) targetStartScreen=(16.0, 16.0) sourceCameraTopLeft=(16.0, -16.0) targetCameraTopLeft=(16.0, -16.0)
```

Lecture :

- `playerScreenDeltaPx <= 1`
- `cameraDeltaPx <= 1`
- le seam projete est aussi verrouille par test a `<= 1 px`

### Movement speed

Produit retenu :

- `normalStepDurationMs = 120`
- mais avec un pas qui couvre maintenant toute la taille de tile runtime du projet

Avant RED-5 sur grandes tiles :

- `120 ms` deplaceaient seulement un sous-pas visuel

Apres RED-5 :

- `120 ms` deplacent une vraie cellule overworld

### Encounter

Apres RED-5 :

- `encounterChecksPerCompletedStep = 1`
- les statuts negatifs ne sont plus loggues par defaut

## 13. Validations executees et resultats

### Analyse ciblee

Commande :

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

Resultat :

```text
No issues found! (ran in 1.6s)
```

### Tests runtime cibles

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter test \
  test/player_component_test.dart \
  test/playable_map_game_input_test.dart \
  test/playable_map_game_whiteout_lite_test.dart \
  test/wild_battle_end_to_end_flow_test.dart
```

Resultat :

```text
All tests passed!
```

### Suite gameplay

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_gameplay
dart test
```

Resultat :

```text
All tests passed!
```

### Host

Commande :

```bash
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host
flutter test test/phase_a_golden_slice_launch_test.dart
```

Resultat :

```text
All tests passed!
```

## 14. Review separee

Review separee manuelle effectuee apres implementation sur le diff des seuls fichiers runtime touches, avec checklist RED-5 :

- continuite decor/camera, pas seulement joueur
- absence d’offset magique
- vitesse normale du joueur
- defer de premiere frame limite aux transitions
- checks encounter non redondants
- absence de regression warp/battle
- absence de modification `map_battle` / `map_editor`

Resultat :

- aucun finding

## 15. Limites assumees

- RED-5 ne retouche pas l’algorithme `_handleConnection(...)` lui-meme
- RED-5 ne reprofile pas massivement battle/warp, car les symptomes principaux restants venaient ici du pas runtime joueur
- les logs `connection` negatifs hors encounter restent visibles si on maintient une direction contre le bord sans connection ; ce n’etait pas le sujet principal du lot

## 16. Ce qui est reporte apres RED-5

Si un polish supplementaire est souhaite plus tard :

- reduire aussi le bruit des logs `[connection] no connection ...` hors mode debug
- etendre les garde-fous screen/tile-space a d’autres patterns de transition plus complexes

Mais RED-5 n’a pas besoin d’ouvrir un nouveau lot battle/warp pour etre valide.

## 17. Etat git final exact

### `git status --short --untracked-files=all`

```text
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
 M packages/map_runtime/test/player_component_test.dart
?? reports/lot-red-5-runtime-connection-tile-space-continuity-movement-speed-restore-report.md
```

### `git diff --stat`

```text
 .../src/presentation/flame/playable_map_game.dart  |  83 ++++-
 .../test/playable_map_game_input_test.dart         | 396 ++++++++++++++++++++-
 .../map_runtime/test/player_component_test.dart    |  21 ++
 3 files changed, 495 insertions(+), 5 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
reports/lot-red-5-runtime-connection-tile-space-continuity-movement-speed-restore-report.md
```

## 18. Decision finale

RED-5 est reussi.

Le saut restant de connection a ete ramene a un vrai probleme de pas runtime joueur, pas a un nouveau bug camera autonome. La marche normale retrouve une cadence et une distance de pas coherentes avec les tiles du projet, la couture decor/seam est maintenant testee explicitement, et les checks encounter ne spamment plus la meme cellule logique.
