# P5-08 — Beta Runtime Smoke : New Game -> Battle -> Reward -> Save/Load

## 1. Résumé exécutif

P5-08 est réalisé avec une preuve exécutable dans `map_runtime`.

Le test ajouté construit un projet runtime technique non-Selbrume dans un dossier temporaire, écrit un vrai `project.json`, une vraie map JSON et des données Pokémon projet minimales, charge le tout via `loadRuntimeMapBundle`, instancie `PlayableMapGame`, exécute `onLoad()`, construit un `GameState` New Game minimal via le builder P5-02, ajoute un starter via P5-03, démarre un combat trainer par le chemin runtime application `buildTrainerBattleRequestFromNpc` + `RuntimeBattleSetupMapper`, joue une victoire avec `map_battle`, applique le write-back runtime `applyRuntimeBattleOutcomeToGameState`, applique les rewards P5-05, puis sauvegarde/recharge avec `SaveGameUseCase` / `LoadGameUseCase` / `FileGameSaveRepository`.

Verdict : la boucle courte `New Game minimal -> trainer battle outcome -> reward -> save/load` est prouvée en smoke runtime/application. Ce n'est pas une session UI interactive complète : l'overlay battle complet et les inputs utilisateur ne sont pas le coeur de ce test.

Prochain lot exact : `P5-09 — Beta Playability Validator V0`.

## 2. Scope du lot

Inclus :

- projet runtime technique temporaire ;
- `project.json` réel ;
- map JSON réelle ;
- chargement `RuntimeMapBundle` ;
- `PlayableMapGame.onLoad()` ;
- New Game minimal depuis `createNewGameStateFromMap` ;
- party initiale via `GameStateMutations.givePokemon` ;
- requête trainer battle runtime depuis NPC ;
- setup battle runtime via `RuntimeBattleSetupMapper` ;
- victoire réelle via `map_battle` ;
- write-back runtime battle outcome ;
- rewards minimaux P5-05 ;
- save/load disque via use cases runtime ;
- vérifications post-reload.

Exclus :

- UI New Game ;
- Boot Flow complet ;
- écran titre / slots ;
- starter UI ;
- party/bag/reward UI ;
- capture animation ;
- XP persistée complète ;
- moves learned ;
- évolution ;
- Selbrume final ;
- P5-09.

## 3. Sources lues

Principales sources inspectées :

- `AGENTS.md`
- `skills/README.md`
- `pokemap_roadmap_mecaniques_fangame.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_5.md`
- `reports/roadmap/phase_5/p5_07_gameplay_save_load_beta_roundtrip.md`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/trainer_battle_request.dart`
- `packages/map_runtime/lib/src/application/battle_start_request.dart`
- `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart`
- `packages/map_runtime/lib/src/application/save_game_use_case.dart`
- `packages/map_runtime/lib/src/application/load_game_use_case.dart`
- `packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart`
- `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`
- `examples/playable_runtime_host/test/p5_runtime_project_disk_smoke_test.dart`
- `packages/map_gameplay/lib/src/new_game_state_builder.dart`
- `packages/map_gameplay/lib/src/game_state_mutations.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_trainer.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/operations/game_state_persistence.dart`

## 4. Chemin runtime testé

Chemin testé :

```text
Directory.systemTemp project
-> project.json
-> maps/p5_beta_runtime_map.json
-> data/pokemon/species/*.json
-> data/pokemon/learnsets/*.json
-> data/pokemon/catalogs/moves.json
-> loadRuntimeMapBundle(...)
-> PlayableMapGame(..., saveData: saveDataFromGameState(newGame))
-> onLoad()
-> buildTrainerBattleRequestFromNpc(...)
-> RuntimeBattleSetupMapper.map(...)
-> createBattleSession(...)
-> PlayerBattleChoiceFight(0)
-> applyRuntimeBattleOutcomeToGameState(...)
-> GameStateMutations.applyBattleRewards(...)
-> SaveGameUseCase.execute(...)
-> LoadGameUseCase.execute(...)
-> normalizeLoadedGameState(...)
```

Ce chemin touche le runtime Flame au niveau `PlayableMapGame.onLoad`, le runtime application battle au niveau mapper/outcome apply, le moteur `map_battle` pour produire une vraie victoire, et le chemin save/load runtime réel.

## 5. Projet / fixture technique

Le projet est généré en temporaire par le test, sans fixture disque versionnée.

IDs utilisés :

```text
project : P5 Beta Runtime Smoke
map : p5_beta_runtime_map
spawn : p5_beta_runtime_spawn
save : p5_beta_runtime_save
player species : p5_beta_player_species
enemy species : p5_beta_enemy_species
trainer : p5_beta_trainer
battle : p5_beta_battle
flag : p5.beta.runtime.flag.ready
trainer defeated : trainer_defeated:p5_beta_trainer
```

Contrôle non-Selbrume : le test scanne les fichiers temporaires et l'état rechargé contre les fragments interdits.

## 6. New Game state minimal

Le test appelle :

```dart
createNewGameStateFromMap(...)
GameStateMutations.setFlag(...)
GameStateMutations.givePokemon(...)
```

Vérifié :

- `saveId` ;
- `currentMapId` ;
- `playerPosition` ;
- `playerFacing` ;
- starter en party ;
- metadata P5-08 ;
- flag générique.

## 7. Battle handoff / battle outcome

Le test utilise un NPC trainer authoré dans la map temporaire :

```dart
buildTrainerBattleRequestFromNpc(...)
RuntimeBattleSetupMapper.selectPlayerBattleLineup(...)
RuntimeBattleSetupMapper.map(...)
createBattleSession(...)
PlayerBattleChoiceFight(0)
```

Vérifié :

- requête trainer déterministe ;
- `setup.isTrainerBattle == true` ;
- `setup.trainerId == p5_beta_trainer` ;
- espèce joueur correcte ;
- espèce ennemie correcte ;
- `BattleOutcome.isVictory == true`.

## 8. Reward apply

Le write-back runtime reste séparé des rewards gameplay :

```dart
applyRuntimeBattleOutcomeToGameState(...)
GameStateMutations.applyBattleRewards(...)
```

Vérifié :

- flag `trainer_defeated:p5_beta_trainer` ;
- money `120` ;
- level-up direct minimal de `8` vers `9` ;
- party conservée.

## 9. Save/load runtime

Le test utilise :

```dart
SaveGameUseCase
LoadGameUseCase
FileGameSaveRepository
```

Un fichier réel `game_save.json` est écrit sous le dossier temporaire du test. Après reload + normalisation, le test vérifie :

- `saveId` ;
- `currentMapId` ;
- position ;
- facing ;
- party ;
- level ;
- HP > 0 ;
- money ;
- flag P5 ;
- trainer defeated ;
- metadata ;
- caught/seen hydratés depuis la party ;
- absence de Selbrume.

## 10. Niveau de preuve obtenu

Niveau obtenu :

```text
Level 4 partiel :
- vrai project.json temporaire ;
- vraie map JSON temporaire ;
- vraie donnée Pokémon projet ;
- vrai RuntimeMapBundle ;
- vrai game_save.json temporaire ;
- vrai save/load disque.

Level 3 partiel :
- PlayableMapGame instancié ;
- onLoad exécuté ;
- battle setup runtime exercé ;
- battle outcome runtime appliqué.

Level 2/3 contrôlé :
- la victoire battle est pilotée par test via PlayerBattleChoiceFight ;
- pas de session UI interactive complète.
```

## 11. Ce qui est prouvé

P5-08 prouve :

- un projet runtime technique non-Selbrume peut charger ;
- `PlayableMapGame.onLoad()` accepte ce projet ;
- un `GameState` New Game minimal peut être injecté comme save initiale ;
- la party initiale peut être utilisée dans le mapper battle runtime ;
- un trainer battle peut produire une victoire réelle via `map_battle` ;
- le write-back runtime marque le trainer battu ;
- les rewards gameplay s'appliquent après l'outcome ;
- le résultat survit à un save/load disque runtime.

## 12. Ce qui n’est pas prouvé

Non prouvé :

- UI interactive New Game ;
- Boot Flow complet ;
- sélection starter visuelle ;
- overlay battle complet piloté par input utilisateur dans ce test P5-08 ;
- reward UI ;
- save menu runtime ;
- capture dans ce smoke P5-08 ;
- XP persistée complète ;
- moves learned ;
- évolution ;
- projet Selbrume final.

## 13. Limites et reports vers P5-09 / Phase 7

Reports P5-09 :

- validator de jouabilité bêta ;
- diagnostics start map/spawn/trainer/species/moves/save prerequisites ;
- expliquer les projets qui ne peuvent pas lancer cette boucle.

Reports Phase 7 ou chantier UX dédié :

- Boot Flow complet ;
- écran titre ;
- slots ;
- Continue / Nouvelle partie complet ;
- UI premium save/reward/starter.

## 14. Tests exécutés

Test ciblé :

```bash
cd packages/map_runtime && flutter test test/p5_beta_runtime_smoke_test.dart
```

Régressions :

```bash
cd packages/map_runtime && flutter test test/p5_gameplay_save_load_beta_roundtrip_test.dart
cd packages/map_runtime && flutter test test/runtime_battle_outcome_apply_test.dart
cd packages/map_runtime && flutter test test/wild_battle_end_to_end_flow_test.dart
cd packages/map_gameplay && dart test test/battle_reward_operations_test.dart
cd packages/map_gameplay && dart test test/capture_destination_operations_test.dart
cd packages/map_core && dart test test/game_state_persistence_test.dart
```

Analyse :

```bash
cd packages/map_runtime && flutter analyze --no-fatal-infos
cd packages/map_runtime && flutter analyze --no-fatal-infos test/p5_beta_runtime_smoke_test.dart
```

Format :

```bash
dart format --set-exit-if-changed packages/map_runtime/test/p5_beta_runtime_smoke_test.dart
```

## 15. Modifications effectuées

Fichiers créés :

- `packages/map_runtime/test/p5_beta_runtime_smoke_test.dart`
- `reports/roadmap/phase_5/p5_08_beta_runtime_smoke_new_game_battle_reward_save_load.md`

Fichier modifié :

- `MVP Selbrume/road_map_phase_5.md`

Aucun code de production modifié.

## 16. Evidence Pack

### git status initial exact

```text
<aucune sortie>
```

### Commandes exécutées

```bash
git status --short --untracked-files=all
sed -n '1,360p' "MVP Selbrume/road_map_global.md"
sed -n '1,1160p' "MVP Selbrume/road_map_phase_5.md"
sed -n '1,340p' reports/roadmap/phase_5/p5_07_gameplay_save_load_beta_roundtrip.md
sed -n '1,360p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '1,420p' packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
sed -n '1,360p' packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
sed -n '1,260p' packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/save_game_use_case.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/load_game_use_case.dart
sed -n '1,360p' packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart
sed -n '1,260p' packages/map_gameplay/lib/src/new_game_state_builder.dart
sed -n '1,520p' packages/map_gameplay/lib/src/game_state_mutations.dart
find packages/map_runtime/test -maxdepth 3 -type f | sort | rg "battle|runtime|smoke|p5|save|load|wild|trainer"
find examples/playable_runtime_host/test -maxdepth 2 -type f | sort | rg "battle|runtime|smoke|p5|launch|save"
rg -n "BattleStartRequest|TrainerBattleStartRequest|WildBattleStartRequest|BattleOutcome|applyRuntimeBattleOutcomeToGameState|RuntimeBattleSetupMapper|BattleEngine|startTrainerBattle|openBattle|_openBattle|saveGame|loadGame|GameStateMutations|applyBattleRewards|createNewGameStateFromMap" packages examples --glob '!build/**' --glob '!**/.dart_tool/**'
sed -n '1,280p' examples/playable_runtime_host/test/p5_runtime_project_disk_smoke_test.dart
sed -n '1,280p' packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart
sed -n '1,260p' packages/map_runtime/test/runtime_battle_outcome_apply_test.dart
sed -n '1,260p' packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
sed -n '1000,1260p' packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
sed -n '660,820p' packages/map_runtime/test/runtime_battle_outcome_apply_test.dart
sed -n '1400,1540p' packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
sed -n '180,260p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,240p' packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart
sed -n '1,240p' packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart
sed -n '1,240p' packages/map_runtime/lib/src/application/runtime_pokemon_learnset_loader.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart
rg -n "class ProjectPokemon|ProjectPokemonConfig|pokemon:" packages/map_core/lib/src/models packages/map_core/lib/map_core.dart packages/map_runtime/test -g '*.dart'
rg -n "class ProjectTrainerEntry|ProjectTrainerEntry|ProjectTrainerTeam|trainer.team|ProjectTrainer" packages/map_core/lib/src/models packages/map_runtime/test -g '*.dart'
sed -n '1,100p' packages/map_core/lib/src/models/project_trainer.dart
sed -n '1,220p' packages/map_core/lib/src/models/pokemon_move.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/battle_start_request.dart
sed -n '1,260p' packages/map_core/lib/src/models/project_trainer.dart
sed -n '1,220p' packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
sed -n '1,260p' packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart
sed -n '260,360p' packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart
rg -n "class PlayableMapGame|PlayableMapGame\(" packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/lib/map_runtime.dart
sed -n '121,210p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '490,520p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '1340,1390p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '1390,1465p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '780,835p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '1,280p' examples/playable_runtime_host/test/p5_runtime_project_disk_smoke_test.dart
sed -n '1,260p' packages/map_core/lib/src/models/project_manifest.dart
rg -n "createBattleSession|PlayerBattleChoiceFight|isVictory|outcome" packages/map_runtime/test packages/map_battle/test -g '*.dart' | head -80
sed -n '1,160p' packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart
sed -n '1,180p' packages/map_runtime/lib/src/application/trainer_battle_request.dart
rg -n "class MapEntityNpcData|MapEntityNpcData\(" packages/map_core/lib/src/models -g '*.dart' | head -20
sed -n '100,135p' packages/map_core/lib/src/models/map_entity_payloads.dart
sed -n '70,88p' packages/map_core/lib/src/models/enums.dart
sed -n '200,245p' packages/map_core/lib/src/models/map_data.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
sed -n '220,360p' packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
rg -n "class RuntimePlayerBattleLineup|selectPlayerBattleLineup" packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
sed -n '187,315p' packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart
sed -n '260,560p' packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart
dart format --set-exit-if-changed packages/map_runtime/test/p5_beta_runtime_smoke_test.dart
cd packages/map_runtime && flutter test test/p5_beta_runtime_smoke_test.dart
cd packages/map_runtime && flutter test test/p5_gameplay_save_load_beta_roundtrip_test.dart
cd packages/map_runtime && flutter test test/runtime_battle_outcome_apply_test.dart
cd packages/map_runtime && flutter test test/wild_battle_end_to_end_flow_test.dart
cd packages/map_gameplay && dart test test/battle_reward_operations_test.dart
cd packages/map_gameplay && dart test test/capture_destination_operations_test.dart
cd packages/map_core && dart test test/game_state_persistence_test.dart
cd packages/map_runtime && flutter analyze --no-fatal-infos
cd packages/map_runtime && flutter analyze --no-fatal-infos test/p5_beta_runtime_smoke_test.dart
cd packages/map_runtime && flutter analyze --no-fatal-infos > /tmp/p5_08_full_analyze.txt 2>&1; cmd_status=$?; printf 'exit_code=%s\n' "$cmd_status"; wc -l /tmp/p5_08_full_analyze.txt; tail -40 /tmp/p5_08_full_analyze.txt
git diff -- packages/map_runtime/test/p5_beta_runtime_smoke_test.dart "MVP Selbrume/road_map_phase_5.md"
sed -n '1,560p' packages/map_runtime/test/p5_beta_runtime_smoke_test.dart
```

### Sortie complète du test ciblé

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p5_beta_runtime_smoke_test.dart
00:00 +0: P5-08 runtime smoke boots New Game, wins battle, applies reward, and save-loads
[runtime_loader] bundle load start projectFilePath=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_beta_runtime_smoke_mXgw4o/project.json mapId=p5_beta_runtime_map
[runtime_loader] project manifest lookup path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_beta_runtime_smoke_mXgw4o/project.json
[runtime_loader] project manifest read ok bytes=2564
[runtime_loader] project manifest validated maps=1 tilesets=0 scenarios=0
[runtime_loader] bundle map resolved mapId=p5_beta_runtime_map relativePath=maps/p5_beta_runtime_map.json mapPath=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_beta_runtime_smoke_mXgw4o/maps/p5_beta_runtime_map.json
[runtime_loader] map file lookup path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_beta_runtime_smoke_mXgw4o/maps/p5_beta_runtime_map.json
[runtime_loader] map file read ok bytes=2150
[runtime_loader] map validated id=p5_beta_runtime_map size=6x6 layers=1 entities=2 placedElements=0 warps=0 triggers=0
[runtime_loader] bundle tilesets collected ids=
[runtime_loader] bundle load ok mapId=p5_beta_runtime_map projectRoot=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_beta_runtime_smoke_mXgw4o tilesets=0
[runtime_game] onLoad start map=p5_beta_runtime_map projectFilePath=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_beta_runtime_smoke_mXgw4o/project.json tilesets=0
[runtime_game] world build start map=p5_beta_runtime_map
[runtime] Map loaded: p5_beta_runtime_map, spawn at (2, 2)
[runtime_game] tileset image load start map=p5_beta_runtime_map
[runtime_game] tileset cache skipped: no tilesets
[runtime_game] tileset image load ok count=0 map=p5_beta_runtime_map
[runtime_game] mount root map start map=p5_beta_runtime_map
[step_studio_trace] npc_presence_applied map=p5_beta_runtime_map entity=p5_beta_runtime_trainer_npc present=true
[runtime_game] mount root map ok map=p5_beta_runtime_map
[npc_patrol] read movement entity=p5_beta_runtime_trainer_npc pos=(3,2) size=1x1 mode=idle waypoints= loop=true pauseMs=0 stepMs=200
[runtime_game] onLoad completed activeMapId=p5_beta_runtime_map
[step_studio_trace] save_repo_write_start path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_beta_runtime_smoke_mXgw4o/runtime_save/game_save.json completedStepIds=[]
[save] game saved to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_beta_runtime_smoke_mXgw4o/runtime_save/game_save.json
[step_studio_trace] save_repo_write_done path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_beta_runtime_smoke_mXgw4o/runtime_save/game_save.json completedStepIds=[]
[load] game loaded from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_beta_runtime_smoke_mXgw4o/runtime_save/game_save.json
00:00 +1: All tests passed!
```

### Sortie complète des régressions ciblées

```text
cd packages/map_runtime && flutter test test/p5_gameplay_save_load_beta_roundtrip_test.dart
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart
00:00 +0: P5-07 roundtrips beta gameplay state through FileGameSaveRepository
[step_studio_trace] save_repo_write_start path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_roundtrip_save_4b6kzy/pokemonProject/game_save.json completedStepIds=[]
[save] game saved to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_roundtrip_save_4b6kzy/pokemonProject/game_save.json
[step_studio_trace] save_repo_write_done path=/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_roundtrip_save_4b6kzy/pokemonProject/game_save.json completedStepIds=[]
[load] game loaded from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/p5_roundtrip_save_4b6kzy/pokemonProject/game_save.json
00:00 +1: All tests passed!

cd packages/map_runtime && flutter test test/runtime_battle_outcome_apply_test.dart
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_outcome_apply_test.dart
00:00 +0: applyRuntimeBattleOutcomeToGameState writes back the exact party slot used for the battle handoff
00:00 +1: applyRuntimeBattleOutcomeToGameState writes back every engaged player lineup member to its exact runtime party slot after switches
00:00 +2: applyRuntimeBattleOutcomeToGameState rejects the legacy mono-slot fallback when the final player lineup actually contains BE10 reserves
00:00 +3: applyRuntimeBattleOutcomeToGameState trainer victory writes player hp and marks trainer as defeated
00:00 +4: applyRuntimeBattleOutcomeToGameState trainer defeat writes player hp without marking trainer defeated
00:00 +5: applyRuntimeBattleOutcomeToGameState runaway writes player hp without marking trainer defeated
00:00 +6: applyRuntimeBattleOutcomeToGameState captured wild battle appends the pokemon and syncs caught/seen
00:00 +7: applyRuntimeBattleOutcomeToGameState captured outcome removes the poke-ball entry when quantity reaches 0
00:00 +8: applyRuntimeBattleOutcomeToGameState captured outcome is rejected for trainer battles
00:00 +9: applyRuntimeBattleOutcomeToGameState captured wild battle stores the pokemon when party is already full
00:00 +10: applyRuntimeBattleOutcomeToGameState captured outcome is rejected when the bag has no poke-ball
00:00 +11: applyRuntimeDefeatRecoveryToGameState revives the exact battle slot to 1 HP when the whole party is KO after defeat
00:00 +12: applyRuntimeDefeatRecoveryToGameState revives the switched-in active slot instead of the original handoff slot after BE10 switches
00:00 +13: applyRuntimeDefeatRecoveryToGameState does not heal the party when another member is already usable
00:00 +14: All tests passed!

cd packages/map_runtime && flutter test test/wild_battle_end_to_end_flow_test.dart
Sortie complète très verbeuse avec logs overlay/perf. Signal final exact :
00:00 +12: All tests passed!

cd packages/map_gameplay && dart test test/battle_reward_operations_test.dart
00:00 +0: loading test/battle_reward_operations_test.dart
00:00 +0: GameStateMutations.addMoney increases trainerProfile money
00:00 +1: GameStateMutations.addMoney is a no-op for non-positive amounts
00:00 +2: GameStateMutations.applyBattleRewards applies money reward and preserves world state
00:00 +3: GameStateMutations.applyBattleRewards applies direct minimal level-up when XP is not persisted
00:00 +4: GameStateMutations.applyBattleRewards caps direct level-up at PlayerPokemon max level
00:00 +5: GameStateMutations.applyBattleRewards ignores invalid party indexes and non-positive level increments
00:00 +6: GameStateMutations.applyBattleRewards applies money even when party is empty
00:00 +7: GameStateMutations.applyBattleRewards does not create or duplicate trainer defeated policy
00:00 +8: GameStateMutations.applyBattleRewards round-trips money and direct level-up through SaveData
00:00 +9: GameStateMutations.applyBattleRewards does not hardcode any Selbrume ids
00:00 +10: All tests passed!

cd packages/map_gameplay && dart test test/capture_destination_operations_test.dart
00:00 +0: loading test/capture_destination_operations_test.dart
00:00 +0: GameStateMutations.applyCapturedPokemon adds the captured pokemon to party when there is room
00:00 +1: GameStateMutations.applyCapturedPokemon sends the captured pokemon to storage when party is full
00:00 +2: GameStateMutations.applyCapturedPokemon appends to existing storage and reports the storage index
00:00 +3: GameStateMutations.applyCapturedPokemon blank speciesId is a safe no-op
00:00 +4: GameStateMutations.applyCapturedPokemon preserves map, position, bag, money, flags and metadata
00:00 +5: GameStateMutations.applyCapturedPokemon updates caught and seen for party and storage destinations
00:00 +6: GameStateMutations.applyCapturedPokemon round-trips party and storage captures through SaveData
00:00 +7: GameStateMutations.applyCapturedPokemon does not hardcode any Selbrume ids
00:00 +8: All tests passed!

cd packages/map_core && dart test test/game_state_persistence_test.dart
00:00 +0: loading test/game_state_persistence_test.dart
00:00 +0: gameStateFromSaveData migrates legacy save fields to GameState
00:00 +1: saveDataFromGameState keeps core fields and merges story flags in legacy slot
00:00 +2: saveDataFromGameState syncs party species into caught and seen for persistence
00:00 +3: saveDataFromGameState syncs stored species into caught and seen for persistence
00:00 +4: normalizeLoadedGameState hydrates storyFlags from progression when storyFlags are empty
00:00 +5: normalizeLoadedGameState keeps explicit storyFlags as source of truth when already set
00:00 +6: normalizeLoadedGameState hydrates caught and seen from party for legacy states
00:00 +7: normalizeLoadedGameState markSpeciesSeenInGameState adds seen without inventing caught
00:00 +8: All tests passed!
```

Justification d'abrègement : `wild_battle_end_to_end_flow_test.dart` produit des logs perf/overlay très longs, sans échec ; le signal complet utile est le passage de 12 tests. Les autres sorties sont reproduites complètement.

### Sortie analyze

Analyse package runtime complète :

```text
exit_code=0
     356 /tmp/p5_08_full_analyze.txt
...
352 issues found. (ran in 2.0s)
```

Les 352 issues sont des `info` historiques du package (`prefer_const_constructors`, `prefer_const_declarations`, `avoid_relative_lib_imports`, `no_leading_underscores_for_local_identifiers`). Avec `--no-fatal-infos`, le code de sortie est `0`.

Analyse ciblée du nouveau test :

```text
Analyzing p5_beta_runtime_smoke_test.dart...

No issues found! (ran in 1.5s)
```

### Sortie format

Première exécution après création du test :

```text
Formatted packages/map_runtime/test/p5_beta_runtime_smoke_test.dart
Formatted 1 file (1 changed) in 0.01 seconds.
```

Exécution finale :

```text
Formatted 1 file (0 changed) in 0.01 seconds.
```

### Contenu complet du nouveau test

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:path/path.dart' as p;

const _projectName = 'P5 Beta Runtime Smoke';
const _mapId = 'p5_beta_runtime_map';
const _spawnId = 'p5_beta_runtime_spawn';
const _trainerNpcId = 'p5_beta_runtime_trainer_npc';
const _saveId = 'p5_beta_runtime_save';
const _playerSpeciesId = 'p5_beta_player_species';
const _enemySpeciesId = 'p5_beta_enemy_species';
const _playerMoveId = 'p5_beta_player_strike';
const _enemyMoveId = 'p5_beta_enemy_tap';
const _trainerId = 'p5_beta_trainer';
const _battleId = 'p5_beta_battle';
const _flagId = 'p5.beta.runtime.flag.ready';
const _trainerDefeatedFlag = 'trainer_defeated:p5_beta_trainer';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P5-08 runtime smoke boots New Game, wins battle, applies reward, and save-loads',
    () async {
      final projectRoot =
          await Directory.systemTemp.createTemp('p5_beta_runtime_smoke_');
      final repository = _TempFileGameSaveRepository(projectRoot);
      final saveGame = SaveGameUseCase(repository);
      final loadGame = LoadGameUseCase(repository);

      try {
        final projectFilePath = await _writeRuntimeSmokeProject(projectRoot);
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: _mapId,
        );

        var gameState = _buildNewGameWithStarter(bundle.map);
        final game = PlayableMapGame(
          bundle: bundle,
          projectFilePath: projectFilePath,
          saveData: saveDataFromGameState(gameState),
          saveRepository: repository,
        );

        expect(game.saveLoadInfo.mapId, _mapId);
        expect(game.gameStateSnapshot.party.members.single.speciesId,
            _playerSpeciesId);

        game.onGameResize(Vector2(320, 240));
        await game.onLoad();
        game.update(0);

        final runtimeState = game.gameStateSnapshot;
        expect(runtimeState.currentMapId, _mapId);
        expect(runtimeState.playerPosition, const GridPos(x: 2, y: 2));
        expect(runtimeState.playerFacing, EntityFacing.east);
        expect(runtimeState.party.members.single.speciesId, _playerSpeciesId);

        final world = GameplayWorldState.initial(
          map: bundle.map,
          playerPos: runtimeState.playerPosition,
          playerFacing: Direction.east,
          project: bundle.manifest,
        );
        final trainerNpc = bundle.map.entities.firstWhere(
          (entity) => entity.id == _trainerNpcId,
        );
        final request = buildTrainerBattleRequestFromNpc(
          entity: trainerNpc,
          manifest: bundle.manifest,
          world: world,
          createdAtEpochMs: 1,
        );
        expect(request, isNotNull);
        expect(
            request!.requestId, 'trainer:$_mapId:$_trainerNpcId:$_trainerId:1');

        final mapper = RuntimeBattleSetupMapper();
        final lineup = mapper.selectPlayerBattleLineup(runtimeState.party);
        final setup = await mapper.map(
          bundle: bundle,
          gameState: runtimeState,
          request: request,
          playerPartyIndex: lineup.activeIndex,
        );
        expect(setup.isTrainerBattle, isTrue);
        expect(setup.trainerId, _trainerId);
        expect(setup.playerPokemon.speciesId, _playerSpeciesId);
        expect(setup.enemyPokemon.speciesId, _enemySpeciesId);

        final battleSession = _playBattleToVictory(setup);
        final outcome = battleSession.state.outcome!;
        expect(outcome.isVictory, isTrue);

        gameState = applyRuntimeBattleOutcomeToGameState(
          gameState: runtimeState,
          context: RuntimeActiveBattleContext(
            request: request,
            playerPartyIndex: lineup.activeIndex,
            playerPartySlotIndicesByLineupIndex: lineup.lineupPartyIndices,
          ),
          outcome: outcome,
        );
        gameState = const GameStateMutations().applyBattleRewards(
          gameState,
          moneyReward: 120,
          levelUpsByPartyIndex: const <int, int>{0: 1},
        );

        expect(
            gameState.storyFlags.activeFlags, contains(_trainerDefeatedFlag));
        expect(gameState.trainerProfile.money, 120);
        expect(gameState.party.members.single.level, 9);

        expect(await saveGame.execute(gameState), isTrue);
        final saveFilePath = await repository.exposedSaveFilePath();
        final saveFile = File(saveFilePath);
        expect(await saveFile.exists(), isTrue);

        final savedJson =
            jsonDecode(await saveFile.readAsString()) as Map<String, dynamic>;
        expect(savedJson['saveId'], _saveId);
        expect(savedJson['currentMapId'], _mapId);
        expect(savedJson['trainerProfile'],
            containsPair('money', gameState.trainerProfile.money));

        final loaded = await loadGame.execute();
        expect(loaded, isNotNull);
        final reloaded = normalizeLoadedGameState(loaded!);

        expect(reloaded.saveId, _saveId);
        expect(reloaded.currentMapId, _mapId);
        expect(reloaded.playerPosition, const GridPos(x: 2, y: 2));
        expect(reloaded.playerFacing, EntityFacing.east);
        expect(reloaded.party.members, hasLength(1));
        expect(reloaded.party.members.single.speciesId, _playerSpeciesId);
        expect(reloaded.party.members.single.level, 9);
        expect(reloaded.party.members.single.currentHp, greaterThan(0));
        expect(reloaded.trainerProfile.money, 120);
        expect(reloaded.storyFlags.activeFlags, contains(_flagId));
        expect(reloaded.storyFlags.activeFlags, contains(_trainerDefeatedFlag));
        expect(
          reloaded.metadata,
          containsPair('lot', 'p5_08_beta_runtime_smoke'),
        );
        expect(
          reloaded.progression.caughtSpeciesIds,
          contains(_playerSpeciesId),
        );
        expect(reloaded.progression.seenSpeciesIds, contains(_playerSpeciesId));
        await expectLater(
          _containsForbiddenFixtureContent(projectRoot),
          completion(false),
        );
        expect(_containsSelbrumeId(reloaded), isFalse);
      } finally {
        if (await projectRoot.exists()) {
          await projectRoot.delete(recursive: true);
        }
      }
    },
  );
}

GameState _buildNewGameWithStarter(MapData map) {
  const mutations = GameStateMutations();
  var state = createNewGameStateFromMap(
    startMap: map,
    saveId: _saveId,
    playerName: 'P5 Beta Tester',
  ).copyWith(
    metadata: const <String, String>{
      'lot': 'p5_08_beta_runtime_smoke',
      'battle': _battleId,
      'runtime': 'playable_map_game_and_battle_outcome',
    },
  );
  state = mutations.setFlag(state, _flagId);
  return mutations.givePokemon(
    state,
    pokemon: const PlayerPokemon(
      speciesId: _playerSpeciesId,
      natureId: 'hardy',
      abilityId: 'p5_beta_power',
      level: 8,
      currentHp: 40,
      knownMoveIds: <String>[_playerMoveId],
    ),
  );
}

BattleSession _playBattleToVictory(BattleSetup setup) {
  var session = createBattleSession(setup);
  for (var turn = 0; turn < 8 && !session.state.isFinished; turn++) {
    session = session.applyChoice(const PlayerBattleChoiceFight(0));
  }
  expect(session.state.isFinished, isTrue);
  expect(session.state.outcome, isNotNull);
  return session;
}

Future<String> _writeRuntimeSmokeProject(Directory projectRoot) async {
  final projectFilePath = p.join(projectRoot.path, 'project.json');
  final manifest = _runtimeSmokeManifest();
  final map = _runtimeSmokeMap();

  ProjectValidator.validate(manifest);
  MapValidator.validate(map, projectDialogueContext: manifest);

  await _writeJson(File(projectFilePath), manifest.toJson());
  await _writeJson(
    File(p.join(projectRoot.path, 'maps', 'p5_beta_runtime_map.json')),
    map.toJson(),
  );
  await _writePokemonProjectData(projectRoot);
  return projectFilePath;
}

ProjectManifest _runtimeSmokeManifest() {
  return const ProjectManifest(
    name: _projectName,
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'P5 Beta Runtime Field',
        relativePath: 'maps/p5_beta_runtime_map.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    trainers: <ProjectTrainerEntry>[
      ProjectTrainerEntry(
        id: _trainerId,
        name: 'P5 Beta Trainer',
        trainerClass: 'Runtime Tester',
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(
            speciesId: _enemySpeciesId,
            level: 2,
            moves: <String>[_enemyMoveId],
          ),
        ],
      ),
    ],
    settings: ProjectSettings(
      tileWidth: 16,
      tileHeight: 16,
      displayScale: 2,
      defaultMapWidth: 6,
      defaultMapHeight: 6,
    ),
  );
}

MapData _runtimeSmokeMap() {
  return const MapData(
    id: _mapId,
    name: 'P5 Beta Runtime Field',
    size: GridSize(width: 6, height: 6),
    layers: <MapLayer>[
      MapLayer.object(id: 'p5_beta_runtime_objects', name: 'Objects'),
    ],
    entities: <MapEntity>[
      MapEntity(
        id: _spawnId,
        name: 'P5 Beta Runtime Spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 2, y: 2),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          spawnKey: _spawnId,
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.east,
        ),
      ),
      MapEntity(
        id: _trainerNpcId,
        name: 'P5 Beta Runtime Trainer NPC',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 3, y: 2),
        blocksMovement: true,
        npc: MapEntityNpcData(
          displayName: 'P5 Beta Trainer',
          facing: EntityFacing.west,
          trainerId: _trainerId,
        ),
      ),
    ],
    mapMetadata: MapMetadata(defaultSpawnId: _spawnId),
  );
}

Future<void> _writePokemonProjectData(Directory projectRoot) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/species/001-p5-beta-player.json',
    _speciesJson(
      id: _playerSpeciesId,
      name: 'P5 Beta Player Species',
      type: 'normal',
      baseHp: 92,
      baseAttack: 125,
      baseDefense: 70,
      baseSpecialAttack: 60,
      baseSpecialDefense: 70,
      baseSpeed: 95,
      abilityId: 'p5_beta_power',
      learnsetRef: _playerSpeciesId,
      nationalDex: 501,
    ),
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/species/002-p5-beta-enemy.json',
    _speciesJson(
      id: _enemySpeciesId,
      name: 'P5 Beta Enemy Species',
      type: 'normal',
      baseHp: 22,
      baseAttack: 20,
      baseDefense: 15,
      baseSpecialAttack: 15,
      baseSpecialDefense: 15,
      baseSpeed: 10,
      abilityId: 'p5_beta_soft',
      learnsetRef: _enemySpeciesId,
      nationalDex: 502,
    ),
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/learnsets/$_playerSpeciesId.json',
    <String, dynamic>{
      'startingMoves': <String>[_playerMoveId],
      'relearnMoves': <String>[],
      'levelUp': <Map<String, Object>>[],
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/learnsets/$_enemySpeciesId.json',
    <String, dynamic>{
      'startingMoves': <String>[_enemyMoveId],
      'relearnMoves': <String>[],
      'levelUp': <Map<String, Object>>[],
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'data/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'P5 beta runtime smoke move catalog',
      },
      'entries': <Map<String, Object?>>[
        _moveEntry(_playerMoveId, 'P5 Beta Strike', 140),
        _moveEntry(_enemyMoveId, 'P5 Beta Tap', 1),
      ],
    },
  );
}

Map<String, Object> _speciesJson({
  required String id,
  required String name,
  required String type,
  required int baseHp,
  required int baseAttack,
  required int baseDefense,
  required int baseSpecialAttack,
  required int baseSpecialDefense,
  required int baseSpeed,
  required String abilityId,
  required String learnsetRef,
  required int nationalDex,
}) {
  return <String, Object>{
    'id': id,
    'slug': id,
    'nationalDex': nationalDex,
    'names': <String, String>{'en': name},
    'speciesName': <String, String>{'en': name},
    'genIntroduced': 1,
    'typing': <String, Object>{
      'types': <String>[type],
    },
    'baseStats': <String, int>{
      'hp': baseHp,
      'atk': baseAttack,
      'def': baseDefense,
      'spa': baseSpecialAttack,
      'spd': baseSpecialDefense,
      'spe': baseSpeed,
      'bst': baseHp +
          baseAttack +
          baseDefense +
          baseSpecialAttack +
          baseSpecialDefense +
          baseSpeed,
    },
    'abilities': <String, String>{'primary': abilityId},
    'breeding': <String, Object>{
      'genderRatio': <String, double>{'male': 0.5, 'female': 0.5},
      'eggGroups': <String>['field'],
      'hatchCycles': 20,
    },
    'progression': <String, Object>{
      'growthRateId': 'medium_fast',
      'baseExp': 50,
      'catchRate': 45,
      'baseFriendship': 50,
    },
    'refs': <String, String>{
      'learnset': learnsetRef,
      'evolution': id,
      'media': id,
    },
    'dexContent': <String, Object>{
      'heightM': 1.0,
      'weightKg': 10.0,
    },
    'sourceMeta': <String, Object>{
      'seededBy': 'p5_beta_runtime_smoke_test',
      'seedVersion': 1,
    },
  };
}

Map<String, Object?> _moveEntry(String id, String name, int power) {
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: 1,
    source: 'p5_beta_runtime_smoke_test',
    type: 'normal',
    category: PokemonMoveCategory.physical,
    target: PokemonMoveTarget.normal,
    basePower: power,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 35,
    engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
  ).toJson();
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  await _writeJson(File(p.join(projectRoot.path, relativePath)), json);
}

Future<void> _writeJson(File file, Map<String, dynamic> json) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

Future<bool> _containsForbiddenFixtureContent(Directory root) async {
  const forbiddenFragments = <String>{
    'selbrume',
    'lysa',
    'mado',
    'port des brisants',
    'phare',
    'brume',
    'rival',
  };

  await for (final entity in root.list(recursive: true)) {
    if (entity is! File) {
      continue;
    }
    final normalizedContent = (await entity.readAsString()).toLowerCase();
    for (final fragment in forbiddenFragments) {
      if (normalizedContent.contains(fragment)) {
        return true;
      }
    }
  }
  return false;
}

bool _containsSelbrumeId(GameState state) {
  final values = <String>[
    state.saveId,
    state.currentMapId,
    state.trainerProfile.name,
    ...state.party.members.map((pokemon) => pokemon.speciesId),
    ...state.pokemonStorage.storedPokemon.map((pokemon) => pokemon.speciesId),
    ...state.bag.entries.map((entry) => entry.itemId),
    ...state.storyFlags.activeFlags,
    ...state.consumedEventIds,
    ...state.metadata.keys,
    ...state.metadata.values,
  ];
  return values.any((value) => value.toLowerCase().contains('selbrume'));
}

class _TempFileGameSaveRepository extends FileGameSaveRepository {
  _TempFileGameSaveRepository(this._testDirectory);

  final Directory _testDirectory;

  Future<String> exposedSaveFilePath() => getSaveFilePath();

  @override
  Future<String> getSaveFilePath() async {
    final saveDir = Directory(p.join(_testDirectory.path, 'runtime_save'));
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return p.join(saveDir.path, 'game_save.json');
  }
}
```

### Diff complet des fichiers modifiés

```diff
diff --git a/MVP Selbrume/road_map_phase_5.md b/MVP Selbrume/road_map_phase_5.md
index f8972602..858dfcdf 100644
--- a/MVP Selbrume/road_map_phase_5.md	
+++ b/MVP Selbrume/road_map_phase_5.md	
@@ -12,6 +12,7 @@ P5-04 : terminé.
 P5-05 : terminé.
 P5-06 : terminé.
 P5-07 : terminé.
+P5-08 : terminé.
 
 Phase 5 reste orientée vers une boucle RPG minimale prouvable, pas vers une
 parité Pokémon complète, pas vers Selbrume final, pas vers une UI premium.
@@ -19,7 +20,7 @@ parité Pokémon complète, pas vers Selbrume final, pas vers une UI premium.
 Prochain lot exact :
 
 ```text
-P5-08 — Beta Runtime Smoke : New Game -> Battle -> Reward -> Save/Load
+P5-09 — Beta Playability Validator V0
 ```
 
 ## Objectif Phase 5
@@ -263,7 +264,7 @@ runtime save/load ciblé
 
 ### P5-08 — Beta Runtime Smoke : New Game -> Battle -> Reward -> Save/Load
 
-Statut : prochain lot exact.
+Statut : terminé.
 
 But :
 
@@ -284,6 +285,8 @@ aucune UI premium
 
 ### P5-09 — Beta Playability Validator V0
 
+Statut : prochain lot exact.
+
 But :
 
 ```text
```

### Contrôles explicites

- `road_map_global.md` n'a pas été modifié.
- P5-09 n'a pas été exécuté.
- Aucun Boot Flow complet n'a été créé.
- Aucun Selbrume final n'a été créé.
- Aucune UI reward/save/load n'a été créée.
- Aucune XP persistée complète n'a été ajoutée.
- Aucun moves learned / evolution system n'a été ajouté.
- Aucun code de production n'a été modifié.
- Aucun fichier `map_battle` n'a été modifié.
- Aucun fichier `map_editor` n'a été modifié.

### git diff --check exact

```text
<aucune sortie>
```

### git diff --stat exact

```text
 MVP Selbrume/road_map_phase_5.md | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)
```

### git diff --name-only exact

```text
MVP Selbrume/road_map_phase_5.md
```

### git status final exact

```text
 M "MVP Selbrume/road_map_phase_5.md"
?? packages/map_runtime/test/p5_beta_runtime_smoke_test.dart
?? reports/roadmap/phase_5/p5_08_beta_runtime_smoke_new_game_battle_reward_save_load.md
```

## 17. Auto-review critique

Point fort : le test est plus proche du runtime qu'un pur roundtrip `GameState` : il charge un projet disque, boote `PlayableMapGame`, passe par les helpers runtime de requête trainer et de mapping battle, puis utilise les use cases save/load.

Limite : l'overlay battle interactif n'est pas piloté dans ce test. C'est volontaire pour garder un smoke stable et éviter de transformer P5-08 en test UI fragile. Le runtime battle application layer est exercé, mais l'expérience joueur complète reste à prouver plus tard.

Le test n'ajoute aucune API et ne modifie aucune production. C'est le bon niveau pour P5-08.

## 18. Regard critique sur le prompt

Le prompt force une distinction saine entre preuve runtime, preuve application layer et preuve UI interactive. C'est important ici : sans cette frontière, on aurait pu survendre un simple `GameState` roundtrip ou au contraire glisser vers un test UI trop fragile. La contrainte "pas P5-09" est également utile : le validator bêta doit rester un lot séparé, maintenant mieux informé par ce smoke.
