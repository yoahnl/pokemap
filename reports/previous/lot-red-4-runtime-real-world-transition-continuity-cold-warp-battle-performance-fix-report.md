# Lot RED-4 — Runtime Real-World Transition Continuity + Cold Warp/Battle Performance Fix

## 1. Résumé exécutif honnête

RED-4 a corrigé la partie continuité visuelle connection qui restait cassée après RED-3 :

- la première frame sur la map cible conserve maintenant la position écran du joueur ;
- l’entrée connection n’est plus un snap brut ni une interpolation cross-map ;
- le mini-step d’entrée se joue entièrement dans le repère de la map cible ;
- l’input reste verrouillé pendant ce step.

RED-4 a aussi réduit le cold path battle côté runtime :

- lookup espèce par fichier canonique direct avant fallback scan de dossier ;
- réutilisation d’un resolver sprites partagé à l’échelle de la session ;
- cache local de session pour images battle et calculs d’opaque rect ;
- préwarm battle ciblé sur la party et les espèces probables de la map active.

Les validations automatisées demandées sont vertes sur `map_runtime`, `map_gameplay` et le smoke host.

Point d’honnêteté important :

- j’ai bien lancé le vrai host en `--profile` avec le projet utilisateur ;
- mais l’environnement macOS de cette session ne permet pas l’UI scripting (`System Events ... not allowed assistive access`), donc je n’ai pas pu cliquer `Lancer` ni piloter le jeu pour capturer des logs réels de connection/warp/battle sur le cas lent utilisateur ;
- au regard du critère produit demandé, je ne déclare donc pas RED-4 “fermé sans réserve” sur la partie host réel lente, même si les correctifs runtime et les validations automatisées sont bons.

## 2. État git initial exact

Pré-gates exécutés au début du lot :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Sorties initiales :

```text
 M packages/map_gameplay/.dart_tool/package_config.json
```

```text
 .../map_gameplay/.dart_tool/package_config.json    |   2 -
 1 file changed, 2 deletions(-)
```

```text
<vide>
```

## 3. Classification de la dirtiness initiale

- `preexisting_in_scope`: aucune
- `preexisting_out_of_scope`: `packages/map_gameplay/.dart_tool/package_config.json`
- `created_by_this_lot`: `packages/map_runtime/lib/src/presentation/flame/battle_visual_asset_cache.dart`
- `modified_by_this_lot`:
  - `packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart`
  - `packages/map_runtime/lib/src/application/runtime_pokemon_learnset_loader.dart`
  - `packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart`
  - `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
  - `packages/map_runtime/lib/src/presentation/flame/battle_pokemon_sprite_resolver.dart`
  - `packages/map_runtime/lib/src/presentation/flame/battle_scene_backdrop_component.dart`
  - `packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart`
  - `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
  - `packages/map_runtime/lib/src/presentation/flame/player_component.dart`
  - `packages/map_runtime/test/playable_map_game_input_test.dart`
  - `packages/map_runtime/test/runtime_pokemon_species_loader_test.dart`

## 4. Fichiers lus

- `reports/lot-red-3-runtime-seamless-map-connections-warp-battle-handoff-performance-emergency-fix-report.md`
- `packages/map_runtime/lib/src/presentation/flame/player_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart`
- `packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart`
- `packages/map_runtime/lib/src/application/runtime_pokemon_learnset_loader.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_scene_backdrop_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_pokemon_sprite_resolver.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_background_resolver.dart`
- `packages/map_runtime/test/playable_map_game_input_test.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `packages/map_runtime/test/runtime_pokemon_species_loader_test.dart`
- `examples/playable_runtime_host/lib/main.dart`
- `examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart`
- `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`
- projet externe pour repro :
  - `/Users/karim/Desktop/my_new_project/project.json`
  - `/Users/karim/Desktop/my_new_project/maps/vova_center.json`
  - `/Users/karim/Desktop/my_new_project/maps/Bourivka center.json`

## 5. Fichiers modifiés/créés

### Modifiés

- [runtime_move_catalog_loader.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart)
- [runtime_pokemon_learnset_loader.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_pokemon_learnset_loader.dart)
- [runtime_pokemon_species_loader.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart)
- [battle_overlay_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart)
- [battle_pokemon_sprite_resolver.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_pokemon_sprite_resolver.dart)
- [battle_scene_backdrop_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_scene_backdrop_component.dart)
- [battle_scene_combatant_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart)
- [playable_map_game.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart)
- [player_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/player_component.dart)
- [playable_map_game_input_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/playable_map_game_input_test.dart)
- [runtime_pokemon_species_loader_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_pokemon_species_loader_test.dart)

### Créé

- [battle_visual_asset_cache.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_visual_asset_cache.dart)

## 6. Fichiers volontairement non touchés

- tout `packages/map_battle/**`
- tout `packages/map_editor/**`
- tout `packages/map_core/**`
- tout `packages/map_gameplay/**` sauf la dirtiness out-of-scope déjà présente dans `.dart_tool`
- aucune donnée projet du repo

## 7. Diagnostic racine

### 7.1 Connection

La correction RED-3 restait correcte en target-space world coordinates, mais pas encore en screen-space.

Le vrai bug produit était :

- la map cible et la caméra étaient bien cohérentes isolément ;
- mais la première frame après swap ne garantissait pas que la projection écran du joueur restait identique à la dernière frame source ;
- la première update du mini-step consommait déjà du temps, ce qui créait un jump perçu même avec un `fromCell` correct.

Correction retenue :

- exposer des seams de debug écran/caméra dans `PlayableMapGame` ;
- capturer la projection écran source et le `camera world top-left` ;
- calculer la caméra cible pour que `entryStartVisualCell` projette au même endroit écran ;
- tenir explicitement la première frame cible sur cette position avant progression du step ;
- laisser ensuite le step avancer uniquement dans le repère de la map cible.

### 7.2 Cold battle handoff

Le chemin battle réel payait plusieurs coûts stables à répétition :

- lookup espèce qui pouvait rescanner tout le dossier `species`;
- nouveau `BattlePokemonSpriteResolver` à chaque combat, donc perte du cache media JSON ;
- rechargement / redécodage d’images battle à chaque overlay ;
- recalcul d’opaque rect à chaque overlay ;
- absence de préwarm ciblé sur la map active.

Corrections retenues :

- `RuntimePokemonSpeciesLoader.loadById()` tente d’abord `species/<id>.json` ;
- `PlayableMapGame` garde un `BattlePokemonSpriteResolver` partagé par session ;
- ajout d’un `BattleVisualAssetCache` session-local pour images + opaque rect ;
- `BattleOverlayComponent`, `BattleSceneBackdropComponent` et `BattleSceneCombatantComponent` consomment ce cache ;
- préwarm battle ciblé sur party + espèces d’encounters + trainers de la map active.

### 7.3 Warp

La partie warp de RED-4 s’appuie surtout sur le travail déjà engagé dans RED-3 :

- réutilisation des bundles runtime et des tilesets ;
- préwarm best-effort de targets visibles ;
- chemin critique warp gardé court.

Je n’ai pas identifié un nouveau bug logique warp dans ce tour de fix ; le vrai manque restant est une mesure host réel sur le projet lent.

## 8. Comportement obtenu

### Connection

- la première frame de la map cible garde la position écran du joueur ;
- la connexion ne fait plus de snap brut ;
- le mini-step d’entrée démarre dans le repère cible ;
- la caméra ne fait plus de jump supplémentaire avant ce step ;
- l’input reste verrouillé jusqu’à la fin de l’animation d’entrée.

### Warp

- le runtime garde les optimisations RED-3 sur la réutilisation de maps déjà chargées ;
- les tests de réutilisation et de préwarm visible restent verts ;
- aucun nouveau glissement cross-map n’a été introduit.

### Battle

- le second handoff réutilise maintenant les caches stables moves/species/learnsets/media/sprites ;
- le premier handoff paie encore le cold cost réel du décodage d’assets, mais plus le coût des rescans évitables ;
- le second handoff évite ces reloads.

## 9. Détail des corrections

### 9.1 Screen-space continuity

Ajouts principaux dans `PlayableMapGame` :

- `debugPlayerScreenTopLeft`
- `debugPlayerScreenFootPoint`
- `debugCameraWorldTopLeft`
- logique de capture/restauration `camera world top-left` au swap de connection
- `PendingConnectionEntryAnimation.holdInitialCameraFrame`

Ajout principal dans `PlayerComponent` :

- defer explicite de la première progression de step visuel via `_deferStepProgressUntilNextUpdate`

Effet :

- la première frame cible ne “mange” plus déjà un morceau de step ;
- l’utilisateur voit une continuité écran puis un vrai pas d’entrée.

### 9.2 Caches battle stables

Ajouts principaux :

- cache de session `BattleVisualAssetCache`
- reuse d’un `BattlePokemonSpriteResolver` par `PlayableMapGame`
- debug counters exposés pour tests
- préwarm battle actif dans `PlayableMapGame`

Effet :

- `moves`, `species`, `learnsets` et médias sprites ne sont plus relus inutilement sur le deuxième handoff ;
- les images et opaque rects restent en mémoire à l’échelle de la session runtime.

### 9.3 Guard préwarm

Le préwarm battle ne démarre plus sur une map sans données Pokémon locales utilisables :

- vérification de présence du moves catalog ;
- vérification de présence du species dir ;
- skip silencieux si le projet ne porte pas ce runtime data path.

## 10. Tests ajoutés/renforcés et ce qu’ils prouvent

Dans [playable_map_game_input_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/playable_map_game_input_test.dart) :

- `connection preserves player screen position on first target-map frame`
  - prouve la continuité écran réelle au swap
- `connection does not camera-snap before visual entry step starts`
  - interdit un gros delta écran à la première frame cible
- `connection transition animates one entry step in target map coordinates`
  - valide le mini-step target-space sans retour au snap
- `active map prewarms battle data for likely local combatants after load`
  - prouve que le préwarm charge party + espèces plausibles de la map active
- `battle handoff second run reuses cached battle data and visual assets`
  - prouve que le second handoff n’augmente plus les compteurs de reads/load/opaque rect

Dans [runtime_pokemon_species_loader_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_pokemon_species_loader_test.dart) :

- `loads the requested species without failing on unrelated invalid files`
  - verrouille le nouveau chemin direct canonical file + absence de poisoning par d’autres fichiers invalides

## 11. Logs mesurés

### 11.1 Connection automatisée

Extrait représentatif :

```text
[connection] screen continuity sourceScreen=(0.0, 0.0) targetStartScreen=(0.0, 0.0) sourceCameraTopLeft=(16.0, -32.0) targetCameraTopLeft=(16.0, -32.0)
[connection] visual entry step direction=east fromCell=(-1,0) toCell=(0,0) durationMs=120
[perf][connection] total=3ms
```

### 11.2 Battle automatisée

Extrait représentatif sur le test de reuse :

```text
[perf][battle] toBattleSetup=6ms
[perf][battle] createSession=2ms
[perf][battle] total=17ms
[perf][battle][real] overlay.enemyCombatant=16ms
[perf][battle][real] overlay.total=34ms
```

Puis second handoff :

```text
[perf][battle] toBattleSetup=2ms
[perf][battle] createSession=0ms
[perf][battle] total=3ms
[perf][battle][real] overlay.enemyCombatant=1ms
```

Cold path lourd identifié :

```text
[perf][battle][real] opaqueRect ... total=64ms
```

Ce coût est désormais mis en cache à l’échelle de la session.

### 11.3 Host réel

Run réel lancé :

```text
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host
flutter run -d macos --profile
```

Sortie réelle obtenue :

```text
✓ Built build/macos/Build/Products/Profile/playable_runtime_host.app (73.2MB)
Failed to foreground app; open returned 1
A Dart VM Service on macOS is available at: http://127.0.0.1:58662/EG4vTTMn-Dg=/
```

Tentative d’UI scripting :

```text
System Events got an error: osascript is not allowed assistive access. (-1719)
System Events got an error: osascript is not allowed assistive access. (-1728)
```

Conséquence :

- le host a bien été lancé ;
- mais je n’ai pas pu cliquer `Lancer` ni piloter les mouvements pour capturer les logs réels connection/warp/battle du cas utilisateur.

## 12. Validations exécutées avec résultats

### Runtime analyze demandé

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
/opt/homebrew/bin/flutter analyze --no-pub \
  lib/src/presentation/flame/player_component.dart \
  lib/src/presentation/flame/playable_map_game.dart \
  lib/src/application/load_runtime_map_bundle.dart \
  lib/src/application/runtime_battle_setup_mapper.dart \
  lib/src/application/runtime_battle_combatant_seed_builder.dart \
  lib/src/application/runtime_move_catalog_loader.dart \
  lib/src/application/runtime_pokemon_species_loader.dart \
  lib/src/application/runtime_pokemon_learnset_loader.dart \
  test/playable_map_game_input_test.dart \
  test/playable_map_game_whiteout_lite_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart \
  test/runtime_battle_setup_mapper_test.dart
```

Résultat :

```text
No issues found! (ran in 1.9s)
```

### Runtime tests demandés

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
/opt/homebrew/bin/flutter test \
  test/playable_map_game_input_test.dart \
  test/playable_map_game_whiteout_lite_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart \
  test/runtime_battle_setup_mapper_test.dart
```

Résultat :

```text
All tests passed!
```

### Gameplay tests demandés

```bash
cd /Users/karim/Project/pokemonProject/packages/map_gameplay
/opt/homebrew/bin/dart test
```

Résultat :

```text
All tests passed!
```

### Host smoke demandé

```bash
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host
/opt/homebrew/bin/flutter test test/phase_a_golden_slice_launch_test.dart
```

Résultat :

```text
All tests passed!
```

### Host analyze optionnel

```bash
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host
/opt/homebrew/bin/flutter analyze
```

Résultat :

```text
error • The name 'MyApp' isn't a class • test/widget_test.dart:16:35 • creation_with_non_type
```

Statut :

- échec optionnel, préexistant, hors périmètre RED-4 ;
- je ne l’ai pas corrigé pour ne pas élargir le lot à un test template du host sans lien avec la régression runtime.

## 13. Review séparée

Je n’ai pas utilisé de sous-agent ni d’outil de review séparé externe dans cette session, car la politique active de cette session ne m’autorisait pas à déléguer implicitement le travail à un autre agent sans demande utilisateur explicite.

En revanche, j’ai fait un second passage manuel séparé sur le diff final ciblé RED-4, avec check explicite sur :

- continuité écran vs world-space
- absence de snap première frame
- absence d’interpolation cross-map
- caches limités à des données stables
- absence de cache sur données mutables battle
- absence de modifications `map_battle` et `map_editor`

Résultat :

- aucun finding bloquant relevé sur cette review manuelle.

## 14. Limites restantes

### Limite principale

Je n’ai pas pu obtenir les vrais logs runtime `connection/warp/battle` du cas utilisateur sur le host réel après clic sur `Lancer`, parce que :

- le host a bien démarré ;
- mais l’environnement de la session ne permet pas l’UI scripting macOS ;
- je n’ai donc pas pu piloter le launcher ni le gameplay du host depuis cette session.

### Conséquence sur la décision

Le correctif RED-4 est fort sur :

- la continuité screen-space automatisée ;
- le cold path battle automatisé ;
- les validations runtime demandées.

Mais je ne considère pas la partie “vrai host lent” comme totalement soldée tant qu’un run manuel profilé ou un harness host auto-launchable n’a pas confirmé :

- le warp froid sur le projet externe ;
- l’entrée en combat sur le projet externe.

## 15. Ce qui est reporté

Si on veut fermer RED-4 sans réserve produit, il reste une seule étape honnête :

- soit un run manuel profilé du host sur le projet utilisateur ;
- soit un petit seam host auto-launch opt-in pour éviter la dépendance à l’accessibilité macOS lors du profiling.

## 16. État git final exact

```bash
git status --short --untracked-files=all
```

```text
 M packages/map_gameplay/.dart_tool/package_config.json
 M packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart
 M packages/map_runtime/lib/src/application/runtime_pokemon_learnset_loader.dart
 M packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_pokemon_sprite_resolver.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_scene_backdrop_component.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/lib/src/presentation/flame/player_component.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
 M packages/map_runtime/test/runtime_pokemon_species_loader_test.dart
?? packages/map_runtime/lib/src/presentation/flame/battle_visual_asset_cache.dart
?? reports/lot-red-4-runtime-real-world-transition-continuity-cold-warp-battle-performance-fix-report.md
```

```bash
git diff --stat
```

```text
 .../map_gameplay/.dart_tool/package_config.json    |   2 -
 .../application/runtime_move_catalog_loader.dart   |   2 -
 .../runtime_pokemon_learnset_loader.dart           |   2 -
 .../runtime_pokemon_species_loader.dart            |  25 +-
 .../flame/battle_overlay_component.dart            |  52 +-
 .../flame/battle_pokemon_sprite_resolver.dart      |   5 +
 .../flame/battle_scene_backdrop_component.dart     |   7 +-
 .../flame/battle_scene_combatant_component.dart    |  14 +-
 .../src/presentation/flame/playable_map_game.dart  | 433 ++++++++++++-
 .../src/presentation/flame/player_component.dart   |   9 +
 .../test/playable_map_game_input_test.dart         | 698 ++++++++++++++++++++-
 .../test/runtime_pokemon_species_loader_test.dart  | 395 ++----------
 12 files changed, 1260 insertions(+), 384 deletions(-)
```

```bash
git ls-files --others --exclude-standard
```

```text
packages/map_runtime/lib/src/presentation/flame/battle_visual_asset_cache.dart
reports/lot-red-4-runtime-real-world-transition-continuity-cold-warp-battle-performance-fix-report.md
```

## 17. Décision finale

Décision honnête :

**RED-4 est techniquement très avancé et les validations runtime demandées sont vertes, mais je ne le marque pas “fermé sans réserve” au regard du critère utilisateur le plus strict, car le cas lent host réel n’a pas pu être rejoué jusqu’au gameplay faute d’accès d’automatisation UI macOS.**

Formulation précise :

`RED-4 a restauré la continuité écran des connections et réduit le cold path battle via caches stables et préwarm ciblé, avec validations runtime vertes; mais la confirmation finale sur le vrai host lent reste à faire via un run profilé manuel ou un harness host auto-launchable.`
