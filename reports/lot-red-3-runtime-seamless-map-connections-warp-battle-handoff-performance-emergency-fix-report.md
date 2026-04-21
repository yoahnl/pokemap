# Lot RED-3 — Runtime Seamless Map Connections + Warp/Battle Handoff Performance Emergency Fix

## 1. Résumé exécutif honnête

RED-3 a remplacé le snap RED-2 des connections par un vrai pas d’entrée visuel entièrement joué dans le repère de la map cible. Le runtime ne glisse plus entre deux repères incohérents et ne retombe plus sur un snap brut pendant une connection normale.

Le lot a aussi ajouté des caches de session bornés pour :

- les bundles runtime par `mapId` ;
- les images de tilesets par path absolu ;
- le catalogue moves battle runtime ;
- les espèces Pokémon ;
- les learnsets Pokémon.

Les validations demandées sont vertes. La review séparée a remonté un vrai bug sur la réutilisation d’une map cible déjà préchargée avec un origin différent ; il a été corrigé et verrouillé par un test dédié. La re-review finale est revenue avec `No findings.`

## 2. État git initial exact

### `git status --short --untracked-files=all`

```text
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/lib/src/presentation/flame/player_component.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
?? packages/map_runtime/test/player_component_test.dart
?? reports/lot-red-2-runtime-player-visual-movement-map-transition-regression-fix-report.md
```

### `git diff --stat`

```text
 .../src/presentation/flame/playable_map_game.dart  |  19 +--
 .../src/presentation/flame/player_component.dart   |  46 ++++---
 .../test/playable_map_game_input_test.dart         | 138 +++++++++++++++++++++
 3 files changed, 174 insertions(+), 29 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
packages/map_runtime/test/player_component_test.dart
reports/lot-red-2-runtime-player-visual-movement-map-transition-regression-fix-report.md
```

## 3. Classification de la dirtiness initiale

### `preexisting_in_scope`

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/player_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/playable_map_game_input_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/player_component_test.dart`
- `/Users/karim/Project/pokemonProject/reports/lot-red-2-runtime-player-visual-movement-map-transition-regression-fix-report.md`

### `preexisting_out_of_scope`

- aucune dirtiness supplémentaire visible dans les pré-gates de ce lot

## 4. Diagnostic racine

### Connection

Le runtime RED-2 remplaçait l’ancien glissement cross-map par un snap :

- changement immédiat de `_bundle`, `_world` et `mapOrigin` ;
- `syncState(... snapToGrid: true)` ;
- log `player snapped from=... to=...`.

Cela supprimait le glissement incohérent, mais cassait le comportement produit attendu. La bonne convention est :

- vérité logique immédiatement sur la map cible ;
- vérité visuelle démarrant une case “hors bord” mais dans le repère de la map cible ;
- interpolation courte de `entryStartVisualCell -> targetPos`.

### Warp

Le chemin critique du warp relisait et remappait sans cache :

- `loadRuntimeMapBundle(...)`
- `loadTilesetImagesById(...)`
- remontage complet des layers

Le préchargement de connections était déjà lancé en best-effort et non awaité, donc le vrai coût visible venait surtout des reloads bundle/images sur le chemin critique.

### Battle handoff

Le handoff combat relisait de la donnée stable à chaque ouverture :

- moves catalog ;
- espèces ;
- learnsets ;
- résolution de genre basée sur espèces.

Il n’y avait pas de cache de session côté runtime pour ces lectures projet stables.

## 5. Fichiers lus

- `/Users/karim/Project/pokemonProject/reports/lot-red-2-runtime-player-visual-movement-map-transition-regression-fix-report.md`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/player_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_pokemon_learnset_loader.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/runtime_battle_gender_overrides.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/playable_map_game_input_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`

## 6. Fichiers modifiés/créés

### Modifiés par RED-3

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/player_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/runtime_battle_gender_overrides.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_pokemon_learnset_loader.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/playable_map_game_input_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`

### Créé par ce lot

- `/Users/karim/Project/pokemonProject/reports/lot-red-3-runtime-seamless-map-connections-warp-battle-handoff-performance-emergency-fix-report.md`

### Dirtiness générée par les validations

- `/Users/karim/Project/pokemonProject/packages/map_gameplay/.dart_tool/package_config.json`

Ce fichier n’a pas été modifié à la main. Il a été touché par les validations `dart test` du package gameplay et reste documenté tel quel.

## 7. Fichiers volontairement non touchés

- `packages/map_battle/**`
- `packages/map_editor/**`
- `packages/map_gameplay/lib/**`
- `packages/map_runtime/test/player_component_test.dart`
- `/Users/karim/Project/pokemonProject/reports/lot-red-2-runtime-player-visual-movement-map-transition-regression-fix-report.md`

## 8. Convention retenue

La convention RED-2 est conservée, mais stabilisée :

- `PlayerComponent.position` = top-left du sprite monde rendu ;
- `GameplayPlayerState.playerPositionPx` reste la vérité logique pour le rendu joueur ;
- `OverworldActorComponent` enfant reste centré horizontalement et aligné en bas dans le sprite, sans réintroduire l’ancien double-offset ;
- les connections n’utilisent plus un snap final pour masquer un repère incohérent ;
- les connections démarrent désormais un pas visuel depuis une cellule hors borne mais en coordonnées de la map cible.

## 9. Comportement obtenu

### Connection

Le runtime calcule maintenant :

- `targetPos` logique sur la map cible ;
- `entryStartVisualCell = targetPos - delta(direction)` ;
- un `fromWorldTopLeft` dans le repère cible ;
- un `startVisualStepFromWorldTopLeft(...)` vers l’état logique cible.

Le flow garde `_flowPhase == mapTransition` jusqu’à la fin du pas visuel, donc l’input reste verrouillé pendant l’entrée.

### Warp

Le warp réutilise :

- les bundles déjà chargés par `mapId` ;
- les images de tilesets déjà chargées par path absolu.

Le flow fonctionnel reste identique :

- fade out ;
- swap de map ;
- placement joueur ;
- fade in ;
- reprise overworld.

### Battle handoff

Le handoff battle réutilise localement :

- le move catalog ;
- les espèces ;
- les learnsets ;
- la résolution genre via le même loader espèces partagé.

La capture, le battle core et l’editor ne sont pas modifiés.

## 10. Logs observés

### Connection cible

Extrait validation :

```text
[connection] visual entry step direction=east fromCell=(-1,0) toCell=(0,0) durationMs=120
```

### Connection avec target préchargée rebasée

Extrait validation :

```text
[connection] origin mismatch target=shared_target existing=(2, 0) expected=(2, 2)
[connection] visual entry step direction=east fromCell=(-1,0) toCell=(0,0) durationMs=120
```

### Warp froid

Extrait validation :

```text
[perf][warp] loadBundle=7ms
[perf][warp] loadTilesets=0ms
[perf][warp] mountMap=0ms
[perf][warp] total=23ms
```

### Warp avec données déjà chargées

Extrait validation :

```text
[perf][warp] loadBundle=0ms
[perf][warp] loadTilesets=0ms
[perf][warp] total=6ms
```

### Battle

Le profilage `[perf][battle]` a bien été instrumenté dans `_openBattleOverlay(...)`, mais la suite automatisée relancée ici ne traverse pas un handoff `PlayableMapGame` complet qui émet ces logs. La preuve automatique de la réduction de reload battle vient donc des compteurs de lecture ajoutés aux loaders runtime et du test de cache `RuntimeBattleSetupMapper`.

## 11. Tests ajoutés ou renforcés

### `playable_map_game_input_test.dart`

- `connection transition animates one entry step in target map coordinates`
- `connection transition west and east use target-space entry start cells`
- `connection transition keeps input locked until visual entry step completes`
- `warp to already loaded map reuses cached map visuals`
- `connection transition rebases a preloaded target map before the entry step`

Ces tests prouvent :

- pas de snap direct sur connection normale ;
- pas d’interpolation cross-map ;
- calcul correct des cellules de départ côté cible ;
- verrouillage input pendant l’entrée ;
- réutilisation cache bundle/images sur warp ;
- correction du cas limite “target déjà préchargée avec le mauvais origin”.

### `runtime_battle_setup_mapper_test.dart`

- `reuses local pokemon catalog cache on second battle mapping`

Ce test prouve que deux mappings successifs réutilisent la donnée stable :

- `moveCatalogLoader.debugActualReadCount == 1`
- `speciesLoader.debugActualReadCount == 2`
- `learnsetLoader.debugActualReadCount == 1`

sur deux mappings identiques consécutifs.

### Tests existants adaptés

- `wild_battle_end_to_end_flow_test.dart`
- `phase_a_golden_battle_slice_smoke_test.dart`

Ces fichiers ont été adaptés uniquement parce que `RuntimeBattleSetupMapper` n’est plus instanciable en `const`.

## 12. Validations exécutées et résultats

### Analyse runtime

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter analyze --no-pub \
  lib/src/presentation/flame/player_component.dart \
  lib/src/presentation/flame/playable_map_game.dart \
  lib/src/presentation/flame/runtime_battle_gender_overrides.dart \
  lib/src/application/load_runtime_map_bundle.dart \
  lib/src/application/runtime_battle_setup_mapper.dart \
  lib/src/application/runtime_battle_combatant_seed_builder.dart \
  lib/src/application/runtime_pokemon_species_loader.dart \
  lib/src/application/runtime_pokemon_learnset_loader.dart \
  lib/src/application/runtime_move_catalog_loader.dart \
  test/playable_map_game_input_test.dart \
  test/playable_map_game_whiteout_lite_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart \
  test/runtime_battle_setup_mapper_test.dart
```

Résultat : `No issues found!`

### Tests runtime

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter test \
  test/playable_map_game_input_test.dart \
  test/playable_map_game_whiteout_lite_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart \
  test/runtime_battle_setup_mapper_test.dart
```

Résultat : vert.

### Tests gameplay

```bash
cd /Users/karim/Project/pokemonProject/packages/map_gameplay
dart test
```

Résultat : vert.

### Host example

```bash
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host
flutter test test/phase_a_golden_slice_launch_test.dart
```

Résultat : vert.

## 13. Review séparée

### Première review

Finding réel remonté :

- `[P2] Reusing a preloaded connection target after an origin mismatch can place the entry animation in the wrong map space`

Impact :

- `_ensureConnectionTargetLoaded(...)` retournait une map déjà montée même si son `origin` ne correspondait pas à la connection en cours ;
- `_handleConnection(...)` calculait alors le `entryStartTopLeft` depuis un repère cible erroné.

Correction appliquée :

- ajout de `_repositionLoadedMap(...)` ;
- rebasing immédiat d’une target déjà chargée quand `expected origin != existing origin` ;
- test `connection transition rebases a preloaded target map before the entry step`.

### Re-review

Résultat :

```text
No findings.
```

## 14. Limites assumées

- Le profilage battle est instrumenté mais la suite automatique relancée ici ne déclenche pas un vrai `_openBattleOverlay(...)` via `PlayableMapGame`, donc il n’y a pas de log `[perf][battle]` observé dans ce report.
- Le cache bundles/images est volontairement limité à la session runtime courante.
- Le lot ne touche pas `map_gameplay` ni `map_battle`, même si certains coûts de contenu projet pourraient encore vivre plus loin que cette surface.

## 15. Ce qui est reporté

- tout nouveau polish visuel non demandé sur le joueur ou la caméra ;
- toute refonte plus large du cycle de vie des maps montées ;
- toute optimisation plus profonde du handoff battle au-delà des caches de données stables ;
- tout travail battle/BAG non directement lié au déblocage/perf runtime de RED-3.

## 16. État git final exact

### `git status --short --untracked-files=all`

```text
 M packages/map_gameplay/.dart_tool/package_config.json
 M packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart
 M packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
 M packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart
 M packages/map_runtime/lib/src/application/runtime_pokemon_learnset_loader.dart
 M packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/lib/src/presentation/flame/player_component.dart
 M packages/map_runtime/lib/src/presentation/flame/runtime_battle_gender_overrides.dart
 M packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
 M packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
?? packages/map_runtime/test/player_component_test.dart
?? reports/lot-red-2-runtime-player-visual-movement-map-transition-regression-fix-report.md
?? reports/lot-red-3-runtime-seamless-map-connections-warp-battle-handoff-performance-emergency-fix-report.md
```

### `git diff --stat`

```text
 .../map_gameplay/.dart_tool/package_config.json    |   2 -
 .../runtime_battle_combatant_seed_builder.dart     |   9 +-
 .../application/runtime_battle_setup_mapper.dart   |  10 +-
 .../application/runtime_move_catalog_loader.dart   | 135 +++--
 .../runtime_pokemon_learnset_loader.dart           |  89 ++--
 .../runtime_pokemon_species_loader.dart            | 121 ++--
 .../src/presentation/flame/playable_map_game.dart  | 487 ++++++++++++---
 .../src/presentation/flame/player_component.dart   |  69 ++-
 .../flame/runtime_battle_gender_overrides.dart     |  16 +-
 .../phase_a_golden_battle_slice_smoke_test.dart    |   2 +-
 .../test/playable_map_game_input_test.dart         | 654 ++++++++++++++++++++-
 .../test/runtime_battle_setup_mapper_test.dart     |  48 +-
 .../test/wild_battle_end_to_end_flow_test.dart     |   2 +-
 13 files changed, 1375 insertions(+), 269 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
packages/map_runtime/test/player_component_test.dart
reports/lot-red-2-runtime-player-visual-movement-map-transition-regression-fix-report.md
reports/lot-red-3-runtime-seamless-map-connections-warp-battle-handoff-performance-emergency-fix-report.md
```

## 17. Décision finale

**RED-3 réussi.**

Le runtime joue maintenant un vrai pas d’entrée fluide dans le repère de la map cible, sans snap de connection normale. Les warps réutilisent les bundles et tilesets déjà chargés, le handoff battle met en cache uniquement la donnée projet stable, et la surface runtime/host demandée est verte sans toucher `map_battle` ni `map_editor`.
