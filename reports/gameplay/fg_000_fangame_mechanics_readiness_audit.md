# FG-000 — Fangame Mechanics Readiness Audit V0

## 1. Résumé exécutif

Cet audit FG-000 confirme que le repo contient une base technique solide pour un RPG Pokémon-like (modèles `GameState`/`SaveData`, rencontres, moteur de combat, handoff runtime, panel auteur pour encounters/trainers, smoke golden slice), mais la boucle fangame MVP n'est pas encore fermée côté progression (XP/level-up/evolution), stockage PC/boxes, commandes événementielles riches, économie (shop/heal), et field moves hors Surf.

Statut global proposé pour FG-000: `🧪 AUDIT` (audit réalisé sans modification de code de production/tests/fixtures, avec preuves et limites explicites).

## 2. Scope inspecté

- `packages/map_core`
- `packages/map_gameplay`
- `packages/map_battle`
- `packages/map_runtime`
- `packages/map_editor`
- `examples/playable_runtime_host`
- `reports/`
- `docs/combat/`

## 3. Sources lues

- Référentiels d'instructions:
  - `AGENTS.md`
  - `codex_rule.md`
- Roadmaps/documentation gameplay:
  - `pokemap_roadmap_mecaniques_fangame.md` (source principale, version `2026-05-22`)
  - `docs/gameplay/fangame_mechanics_roadmap.md` (absent)
  - `reports/gameplay/fangame_mechanics_roadmap.md` (absent)
- Documentation combat:
  - `docs/combat/battle-roadmap-canonical-v3.1.md`
  - `docs/combat/battle-canonical-state-v3.1.md`
- Fichiers techniques clés audités:
  - `packages/map_core/lib/src/models/game_state.dart`
  - `packages/map_core/lib/src/models/save_data.dart`
  - `packages/map_core/lib/src/models/project_manifest.dart`
  - `packages/map_core/lib/src/models/enums.dart`
  - `packages/map_core/lib/src/models/script_asset.dart`
  - `packages/map_core/lib/src/models/scenario_asset.dart`
  - `packages/map_core/lib/src/validation/validators.dart`
  - `packages/map_gameplay/lib/src/gameplay_encounter.dart`
  - `packages/map_gameplay/lib/src/surf_evaluation.dart`
  - `packages/map_gameplay/lib/src/game_state_mutations.dart`
  - `packages/map_gameplay/lib/src/script_condition_evaluator.dart`
  - `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
  - `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
  - `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart`
  - `packages/map_runtime/lib/src/application/script_command_executor.dart`
  - `packages/map_editor/lib/src/application/use_cases/encounter_table_use_cases.dart`
  - `packages/map_editor/lib/src/application/use_cases/trainer_use_cases.dart`
  - `packages/map_editor/lib/src/ui/panels/encounter_tables_panel.dart`
  - `packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`
  - `examples/playable_runtime_host/lib/main.dart`
  - `examples/playable_runtime_host/lib/src/in_game_menu.dart`
  - `examples/playable_runtime_host/golden_battle_slice/project.json`
  - `examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json`
  - `examples/playable_runtime_host/golden_battle_slice/README.md`
- Tests/fixtures lus:
  - `packages/map_core/test/game_state_persistence_test.dart`
  - `packages/map_gameplay/test/surf_evaluation_test.dart`
  - `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`
  - `packages/map_runtime/test/file_game_save_repository_test.dart`
  - `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`
  - `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`

## 4. État Git initial

Commande exécutée:

- `git status --short --untracked-files=all`

Résultat initial:

- `?? packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart`
- `?? reports/shadows/screenshots/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png`
- `?? reports/shadows/v2/shadow_v2_55_projected_building_shadow_v2_adaptive_depth_visual_review_selection_design.md`
- `?? reports/shadows/v2/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard_artifact.md`

## 5. Architecture observée

- `map_core` porte les modèles et validations (`GameState`, `SaveData`, `ProjectManifest`, `ProjectValidator`), dont les enums mécaniques (`MovementMode`, `FieldAbility`, `EncounterKind`).
- `map_gameplay` porte la logique pure hors UI/runtime: rencontres pondérées, conditions de scripts, mutations d'état, évaluation Surf.
- `map_battle` porte la résolution de combat indépendante de Flutter.
- `map_runtime` orchestre handoff battle, write-back, persistence disque save/load, exécution de commandes script runtime.
- `map_editor` fournit l'authoring no-code (encounters/trainers/cutscene studios), avec validation projet côté `ProjectValidator`.
- `examples/playable_runtime_host` sert de host d'intégration + smoke slice golden avec menu in-game et save/load runtime.

## 6. Inventaire par package

### 6.1 packages/map_core

- Présent:
  - modèle d'état `GameState` (party, bag, trainer, progression, flags, variables)
  - modèle de persistance `SaveData` + normalisation/migration legacy
  - modèle projet `ProjectManifest` avec `encounterTables`, `trainers`, `scripts`, `scenarios`
  - enums mécaniques `MovementMode`, `FieldAbility`, `EncounterKind`
  - `ProjectValidator` avec validations encounter/trainer/scenario
- Limites:
  - pas de modèle explicite de PC/boxes (`PokemonStorage` absent)
  - pas de modèle starter selection dédié
  - pas de modèle progression XP/exp/level-up/evolution persistant dans `PlayerPokemon`

### 6.2 packages/map_gameplay

- Présent:
  - rencontres overworld via `checkEncounterAtPlayerPosition(...)`
  - logique Surf via `evaluateSurfAttempt(...)`
  - mutations `setFlag`, `setVariable`, `unlockFieldAbility`, `warpPlayer`, etc.
  - évaluation de conditions script (`flagIsSet`, `variable*`, `partyHasMove`, etc.)
- Limites:
  - `giveItem` mutation rudimentaire via `metadata` (commentaire explicite de scope limité)
  - aucune logique PC/boxes, XP, level-up, evolution
  - pas de logique field moves hors Surf

### 6.3 packages/map_battle

- Présent:
  - moteur de combat riche + outcomes (`victory`, `defeat`, `runaway`, `captured`)
  - supports bag items battle côté moteur
  - nombreux tests battle
- Limites:
  - l'audit ne prouve pas de write-back PP/statuts vers `GameState` runtime
  - rewards progression hors combat (XP/money/badges) non prouvées en application runtime

### 6.4 packages/map_runtime

- Présent:
  - handoff vers battle via `RuntimeBattleSetupMapper`
  - write-back HP et capture minimale via `applyRuntimeBattleOutcomeToGameState`
  - save/load disque via `FileGameSaveRepository`
  - exécution script command runtime via `ScriptCommandExecutor`
  - smoke tests golden battle slice
- Limites:
  - capture refusée si party pleine (pas de fallback box)
  - pas de write-back PP/statut majeur prouvé
  - pas de shop/heal center/open PC command
  - pas de field move runtime hors Surf prouvé

### 6.5 packages/map_editor

- Présent:
  - use cases + UI no-code pour encounter tables
  - use cases + UI no-code pour trainer library/teams
  - studios narratifs (script/scenario/cutscene/step/global story)
- Limites:
  - pas d'UI no-code validée pour starter selection
  - pas de flux auteur shop/heal center prouvé dans scope audité
  - pas d'UI PC/boxes runtime-side (éditeur peut structurer des données trainers/encounters, pas gameplay loop complet)

### 6.6 examples/playable_runtime_host

- Présent:
  - menu in-game (Pokédex, Équipe, Sac, Dresseur, Sauvegarde)
  - intégration save/load callbacks dans menu
  - golden slice project + save versionnés
- Limites:
  - tests host échouent actuellement (imports `package:PokeMap_Loader/...` non résolus)
  - menus mostly lecture seule (pas de loop complète item usage/party management avancée)

### 6.7 reports / docs

- `docs/combat/` contient des références battle canoniques.
- `reports/gameplay/` était absent avant ce lot.
- Incohérence roadmap:
  - source gameplay attendue dans `docs/gameplay/...` ou `reports/gameplay/...` absente
  - roadmap principale effective trouvée en racine: `pokemap_roadmap_mecaniques_fangame.md`

## 7. Inventaire des mécaniques présentes

- New Game / état initial partiel via launch save golden + fallback runtime host.
- Save/load runtime réel (`FileGameSaveRepository` + tests E2E).
- Handoff battle runtime réel (wild + trainer) et smoke tests golden.
- Write-back HP post-battle et flag trainer defeated.
- Wild encounters walk/surf via gameplay zones + encounter tables.
- Surf (évaluation pure + activation runtime).
- Story flags/variables/conditions (modèle + mutations + evaluator + executor).
- Menu runtime minimal (Pokédex/Équipe/Sac/Dresseur/Sauvegarde) dans host.

## 8. Inventaire des mécaniques absentes ou non prouvées

- Starter selection (modèle/runtime non prouvés).
- PC/boxes/storage.
- Capture destination vers box si party pleine.
- XP distribution / level-up / learn move / evolution.
- Shops / heal center gameplay loop.
- Field moves Cut/Strength/Rock Smash/Flash/Waterfall/Dive/Fly.
- Static encounters / gift pokemon runtime fiables.
- Encounter kinds headbutt/old_rod/good_rod/super_rod/special réellement exécutés en runtime.
- Project gameplay readiness validator dédié (au-delà du validator structurel de manifest/maps).

## 9. Matrice mécanique détaillée

| Mécanique | map_core | map_gameplay | map_battle | map_runtime | map_editor | Tests/fixtures | Statut proposé | Preuve / chemin |
|---|---|---|---|---|---|---|---|---|
| 1. New Game / initial GameState | `GameState` + `SaveData` présents | N/A | N/A | Host charge save de lancement/fallback | N/A | `phase_a_golden_slice_launch_test.dart` (compile KO) + smoke runtime | 🟡 PARTIAL | `packages/map_core/lib/src/models/game_state.dart`, `examples/playable_runtime_host/lib/main.dart` |
| 2. Starter selection | Aucun modèle starter dédié prouvé | Aucun flux dédié | N/A | Aucun flux dédié trouvé | Aucun panel starter prouvé | Aucune preuve | ⬜ TODO | recherche `StarterSelection|chooseStarter` sans match |
| 3. Save / load runtime | Modèles persistance présents | N/A | N/A | `FileGameSaveRepository` save/load/delete/exists | N/A | `file_game_save_repository_test.dart` | ✅ DONE | `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart` |
| 4. Pause menu runtime | N/A | N/A | N/A | menu ouvert depuis host runtime | N/A | `in_game_menu_test.dart` (compile KO), usage manuel possible | 🟡 PARTIAL | `examples/playable_runtime_host/lib/src/in_game_menu.dart`, `examples/playable_runtime_host/lib/main.dart` |
| 5. Party runtime | `PlayerParty` présent | N/A | lineup battle présent | menu Équipe lecture seule | N/A | `runtime_battle_outcome_apply_test.dart`, `in_game_menu_test.dart` (KO) | 🟡 PARTIAL | `save_data.dart`, `in_game_menu.dart` |
| 6. PlayerPokemon persistence | `PlayerPokemon` sérialisé/normalisé | N/A | N/A | save/load + migration legacy | N/A | `save_data_test.dart`, `game_state_persistence_test.dart`, `file_game_save_repository_test.dart` | ✅ DONE | `packages/map_core/lib/src/models/save_data.dart` |
| 7. PC / boxes / storage | absent | absent | N/A | absent | absent | aucun test | ⬜ TODO | recherche `PokemonStorage` sans match |
| 8. Capture destination party/box | modèle box absent | absent | `captured` outcome existe | capture uniquement si party < 6, sinon erreur | N/A | `runtime_battle_outcome_apply_test.dart` | 🟡 PARTIAL | `runtime_battle_setup_mapper.dart` (`allowCapture`), `runtime_battle_outcome_apply.dart` |
| 9. Battle handoff runtime | N/A | rencontre -> request | setup battle robuste | mapper runtime vers `BattleSetup` | N/A | `phase_a_golden_battle_slice_smoke_test.dart`, `runtime_battle_setup_mapper_test.dart` | ✅ DONE | `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart` |
| 10. Battle write-back HP / PP / status | modèles HP/status existent | N/A | état combat complet | write-back HP uniquement prouvé | N/A | `runtime_battle_outcome_apply_test.dart` | 🟡 PARTIAL | `runtime_battle_outcome_apply.dart` (HP only) |
| 11. Battle rewards | money/badges dans profile | N/A | outcome type seulement | pas de rewards runtime explicites | N/A | pas de test reward dédié trouvé | ⬜ TODO | absence de logique reward dans `runtime_battle_outcome_apply.dart` |
| 12. XP distribution | pas de champ exp persisté | absent | moteur peut calculer combats mais pas preuve write-back XP | non prouvé | N/A | aucun test XP runtime | ⬜ TODO | recherche `addExperience|gainExperience` absente runtime |
| 13. Level-up | level dans modèle | absent | level combat entrants | pas d'application progression post-combat prouvée | N/A | aucun test level-up runtime | ⬜ TODO | absence de `levelUp` runtime |
| 14. Learn move | knownMoveIds modèle présent | conditions move présentes | moves combat présents | pas de flow learn post-level prouvé | éditeur Pokédex/learnsets existe | tests catalogues/learnset (éditeur/runtime loaders) | ⬜ TODO | `runtime_pokemon_learnset_loader.dart` sans orchestration progression |
| 15. Evolution | evolutions data côté pokemon config | absent gameplay | N/A | pas de flow evolution runtime prouvé | édition evolutions côté catalogues | tests catalogues evolutions uniquement | ⬜ TODO | absence de `evolve` runtime gameplay |
| 16. Bag runtime | modèle Bag présent | mutation giveItem basique | bag battle côté combat | menu Sac lecture seule + bag utilisé capture | N/A | `battle_bag_menu_model_test.dart`, menu host tests KO | 🟡 PARTIAL | `save_data.dart`, `in_game_menu.dart`, `runtime_battle_outcome_apply.dart` |
| 17. Item use outside battle | modèle item bag oui | giveItem mutation oui | N/A | pas de flux usage médecine hors battle prouvé | N/A | pas de test runtime usage item overworld trouvé | ⬜ TODO | absence de handler runtime item outside battle |
| 18. Battle items | N/A | N/A | support battle items présent | overlay/menus battle runtime présents | N/A | tests battle item côté map_battle/map_runtime | 🟡 PARTIAL | `packages/map_battle/...item...`, `battle_bag_menu_model_test.dart` |
| 19. Shops | pas de shop model canonique identifié | absent | N/A | pas de `openShop` | pas de panel shop prouvé | aucun | ⬜ TODO | recherche `openShop|Shop` sans flux runtime |
| 20. Heal center | heal model absent | absent | N/A | pas de `HealParty` command runtime | absent | aucun | ⬜ TODO | recherche `HealParty|Pokemon Center` sans match runtime |
| 21. Money | `TrainerProfile.money` présent | N/A | N/A | pas de reward money post-battle prouvé | affichage dans menu Dresseur | tests persistence profile | 🟡 PARTIAL | `save_data.dart`, `in_game_menu.dart` |
| 22. Badges | `TrainerProfile.badgeIds` présent | flags/mutations présentes | N/A | pas de grant badge runtime battle prouvé | affichage badges menu | tests persistence profile | 🟡 PARTIAL | `save_data.dart`, `in_game_menu.dart`, pas de flow grant |
| 23. Event commands no-code | `ScriptCommandType` présent | mutations/conditions présentes | N/A | `ScriptCommandExecutor` partiel (setFlag, variable, warp, giveItem...) | studios narratifs présents | `script_system_integration_test.dart` | 🟡 PARTIAL | `script_asset.dart`, `script_command_executor.dart` |
| 24. Dialogue conditional actions | conditions script présentes | `ScriptConditionEvaluator` présent | N/A | runtime script/dialogue hooks présents | dialogue/cutscene studios | tests script/scenario runtime | 🟡 PARTIAL | `script_condition_evaluator.dart`, `scenario_runtime_executor_test.dart` |
| 25. Trainer battles | trainer models présents | request builder via NPC | moteur trainer battle présent | handoff trainer battle + policy | trainer authoring présent | smoke golden trainer battle | ✅ DONE | `trainer_battle_request.dart`, `phase_a_golden_battle_slice_smoke_test.dart` |
| 26. Trainer defeated flags | story flags modèle | mutation setFlag | N/A | mark trainer defeated à victoire | N/A | `runtime_battle_outcome_apply_test.dart` | ✅ DONE | `runtime_battle_outcome_apply.dart`, `story_flags_manager.dart` |
| 27. Wild encounters | encounter model/tables | `checkEncounterAtPlayerPosition` | N/A | conversion encounter -> battle request | encounter table editor | smoke golden wild battle | ✅ DONE | `gameplay_encounter.dart`, `encounter_to_battle_request.dart` |
| 28. Static encounters | `EncounterKind.special/gift` enum | pas de logique dédiée prouvée | N/A | pas de flux static encounter prouvé | pas de flow dédié prouvé | aucun | ⬜ TODO | absence runtime static encounter command |
| 29. Gift Pokémon | `EncounterKind.gift` enum | absent | N/A | pas de command give pokemon runtime | pas de flow auteur dédié prouvé | aucun | ⬜ TODO | enum seul dans `enums.dart` |
| 30. Fishing / headbutt / special kinds | enums présents (`old_rod`, etc.) | pas de logique complète prouvée | N/A | exécution runtime non prouvée | encounter kind selectable en editor | aucun smoke dédié | ⬜ TODO | `enums.dart`, absence impl runtime dédiée |
| 31. Field moves Surf/Cut/Strength/Rock Smash/Flash/Waterfall/Dive/Fly | enums abilities/modes présents | Surf implémenté | N/A | Surf branché; autres moves non prouvés | N/A | `surf_evaluation_test.dart` | 🟡 PARTIAL | `surf_evaluation.dart`, absence matches runtime pour autres moves |
| 32. Gameplay zones | `MapGameplayZone` + validations | consommation zones rencontres/mouvement/hazards | N/A | runtime consomme zones dans game loop | éditeur gameplay zones | tests zones/collisions/hazards | ✅ DONE | `validators.dart`, `gameplay_encounter.dart`, tests gameplay |
| 33. Story flags / variables | modèles présents | mutations + evaluator présents | N/A | executor runtime script applique flags/variables | studios narratifs présents | tests script system | ✅ DONE | `game_state.dart`, `game_state_mutations.dart`, `script_command_executor.dart` |
| 34. Cutscenes / scenario / step studio runtime usability | `ScenarioAsset` présent | conditions scripts présentes | N/A | scenario runtime executor/cutscene runner présents | cutscene/step/global story studios | nombreux tests scenario/cutscene | 🟡 PARTIAL | `scenario_asset.dart`, `scenario_runtime_executor.dart` |
| 35. Runtime menus Party/Bag/Pokédex/Save/Options | N/A | N/A | N/A | host menu propose Pokédex/Équipe/Sac/Dresseur/Sauvegarde (pas Options) | N/A | `in_game_menu_test.dart` compile KO | 🟡 PARTIAL | `in_game_menu.dart` (pas section Options) |
| 36. Project gameplay validator | `ProjectValidator` structurel fort | N/A | N/A | pas de report “readiness gameplay” runtime | use case validation data pokedex côté editor | tests validator structurels | 🟡 PARTIAL | `validators.dart`, absence d'un validator gameplay readiness dédié |
| 37. Golden Slice / playable runtime smoke | manifest+save golden versionnés | rencontre + flow gameplay sur slice | battle session sur slice | smoke runtime bataille passe | host slice présent | `phase_a_golden_battle_slice_smoke_test.dart` passe; host test compile KO | 🟡 PARTIAL | `examples/playable_runtime_host/golden_battle_slice/*`, tests runtime |

## 10. Tests et fixtures utiles existants

- `packages/map_core/test/game_state_persistence_test.dart`
- `packages/map_core/test/save_data_test.dart`
- `packages/map_gameplay/test/surf_evaluation_test.dart`
- `packages/map_gameplay/test/script_system_integration_test.dart`
- `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`
- `packages/map_runtime/test/file_game_save_repository_test.dart`
- `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`
- `examples/playable_runtime_host/golden_battle_slice/project.json`
- `examples/playable_runtime_host/golden_battle_slice/runtime_host_launch_save.json`
- `examples/playable_runtime_host/golden_battle_slice/README.md`

## 11. Risques et dettes bloquantes

- **Boucle progression cassée**: XP/level-up/learn/evolution non prouvés.
- **Capture non scalable**: capture refusée party pleine (pas de PC/box fallback).
- **Runtime host tests cassés**: imports `package:PokeMap_Loader/...` non résolus dans `examples/playable_runtime_host/test/*`.
- **Économie gameplay incomplète**: pas de shop/heal center runtime prouvés.
- **Field gating incomplet**: Surf seul réellement prouvé, autres field moves absents côté runtime.
- **Validator gameplay MVP manquant**: `ProjectValidator` valide la cohérence de données, pas la jouabilité bout-en-bout.

## 12. Proposition de statuts initiaux pour la roadmap

- FG-000
  - Statut proposé: `🧪 AUDIT`
  - Justification: audit réalisé, preuves collectées, aucun changement de code produit/tests/fixtures.
  - Preuve: ce rapport + commandes section 14/15.

- FG-001
  - Statut proposé: `⬜ TODO`
  - Justification: pas de fichier roadmap canonique intégré dans `docs/gameplay` ni `reports/gameplay` hors ce rapport d'audit.
  - Preuve: recherche `docs/gameplay/*.md` et `reports/gameplay/*.md` (absents avant création du présent rapport).

- FG-010 à FG-016
  - Statut proposé: `🟡 PARTIAL`
  - Justification: boot/save/load/menu partiellement présents, starter/new game builder dédié non prouvé.
  - Preuve: `file_game_save_repository.dart`, `in_game_menu.dart`, absence `StarterSelection`.

- FG-020 à FG-030
  - Statut proposé: `⬜ TODO`
  - Justification: persistance Pokémon partielle OK mais PC/boxes/capture->box/menu party avancé non clos.
  - Preuve: absence `PokemonStorage`; capture limitée party<6.

- FG-040 à FG-051
  - Statut proposé: `⬜ TODO`
  - Justification: HP write-back présent mais PP/status/rewards/XP/level-up/evolution non prouvés.
  - Preuve: `runtime_battle_outcome_apply.dart` (HP only + capture minimal).

- FG-060 à FG-071
  - Statut proposé: `⬜ TODO`
  - Justification: bag lecture seule et capture ball OK, mais usage hors combat/shop/heal center absents.
  - Preuve: absence `openShop`/`HealParty` runtime.

- FG-080 à FG-094
  - Statut proposé: `🟡 PARTIAL`
  - Justification: socle script commands + conditions présent, mais catalogue no-code complet (give pokemon/heal/start static/open shop/open PC etc.) non prouvé.
  - Preuve: `script_asset.dart`, `script_command_executor.dart` (commands limitées).

- FG-100 à FG-108
  - Statut proposé: `🟡 PARTIAL`
  - Justification: walk/surf encounter flow prouvé, static/gift/fishing/headbutt et validations authoring avancées non closes.
  - Preuve: `gameplay_encounter.dart`, enums `EncounterKind`, absence flux runtime dédiés.

- FG-120 à FG-129
  - Statut proposé: `🟡 PARTIAL`
  - Justification: pattern Surf présent, autres field moves non prouvés runtime.
  - Preuve: `surf_evaluation.dart`, absence matches runtime Cut/Strength/RockSmash/Flash/Waterfall/Dive/Fly.

- FG-140 à FG-144
  - Statut proposé: `🟡 PARTIAL`
  - Justification: trainer battles + defeated flags présents; rematch/dialogue post-battle/badge grant workflow non prouvés.
  - Preuve: `runtime_battle_outcome_apply.dart`, `trainer_library_panel.dart`.

- FG-160 à FG-165
  - Statut proposé: `🟡 PARTIAL`
  - Justification: menu runtime partiel (pas Options complètes ni conventions input finalisées dans audit).
  - Preuve: `in_game_menu.dart`, `examples/playable_runtime_host/lib/main.dart`.

- FG-180 à FG-185
  - Statut proposé: `⬜ TODO`
  - Justification: smoke golden battle slice partiel existe, mais pas de report readiness gameplay complet ni e2e mini-histoire terminable.
  - Preuve: `phase_a_golden_battle_slice_smoke_test.dart`, absence report readiness dédié.

- FG-200 à FG-207
  - Statut proposé: `⏸ DEFERRED`
  - Justification: hors MVP selon roadmap racine.
  - Preuve: `pokemap_roadmap_mecaniques_fangame.md` section Phase 11.

## 13. Recommandation pour le prochain lot

Recommandation: `FG-001 — Roadmap Tracker Repo Integration V0`.

Condition de recommandation respectée: audit exploitable produit, mais absence de fichier roadmap canonique dans `docs/gameplay/` ou `reports/gameplay/` à corriger d'abord côté documentation de pilotage.

## 14. Commandes exécutées

- `pwd && git status --short --untracked-files=all`
- `dart --version && flutter --version`
- `dart analyze && dart test` (map_core/map_gameplay/map_battle)
- `dart test test/game_state_persistence_test.dart test/save_data_test.dart -r expanded`
- `dart test -r expanded` (`packages/map_gameplay`)
- `dart test test/battle_session_flow_test.dart test/battle_switch_test.dart test/battle_spikes_test.dart -r expanded`
- `flutter test test/runtime_battle_outcome_apply_test.dart test/file_game_save_repository_test.dart test/phase_a_golden_battle_slice_smoke_test.dart`
- `flutter test test/phase_a_golden_slice_launch_test.dart test/in_game_menu_test.dart`
- recherches `rg` ciblées (présence/absence starter, storage, rewards, field moves, validator, menus, golden slice)

## 15. Résultats exacts des commandes

- `pwd && git status --short --untracked-files=all`
  - cwd: `/Users/karim/Project/pokemonProject`
  - git status initial: 4 fichiers untracked préexistants (lot shadows/runtime tool), aucun fichier tracked modifié.
- `dart --version && flutter --version`
  - Dart `3.11.5`, Flutter `3.41.9`.
- `dart analyze` map_gameplay
  - `2 issues found` (warning path dependency + info lint no_leading_underscores).
- `dart analyze` map_battle
  - `3 issues found` (warnings dans `tmp_mirror.dart`).
- `dart test test/game_state_persistence_test.dart test/save_data_test.dart -r expanded`
  - `+30: All tests passed!`
- `dart test -r expanded` map_gameplay
  - `+127: All tests passed!`
- `dart test ...` map_battle ciblé
  - `+47: All tests passed!`
- `flutter test ...` map_runtime ciblé
  - `+31: All tests passed!`
- `flutter test ...` playable_runtime_host
  - échec compilation:
    - `Couldn't resolve the package 'PokeMap_Loader'`
    - imports non résolus dans `test/phase_a_golden_slice_launch_test.dart` et `test/in_game_menu_test.dart`
    - résultat: `Some tests failed.`

## 16. Fichiers créés / modifiés / supprimés / untracked

- Créé:
  - `reports/gameplay/fg_000_fangame_mechanics_readiness_audit.md`
- Modifiés/supprimés par ce lot:
  - aucun
- Untracked préexistants conservés (hors scope audit):
  - `packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart`
  - `reports/shadows/screenshots/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png`
  - `reports/shadows/v2/shadow_v2_55_projected_building_shadow_v2_adaptive_depth_visual_review_selection_design.md`
  - `reports/shadows/v2/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard_artifact.md`

## 17. État Git final

Commande exécutée:

- `git status --short --untracked-files=all`

Résultat final attendu de ce lot:

- conservation des 4 untracked préexistants
- ajout d'un nouveau fichier audit:
  - `?? reports/gameplay/fg_000_fangame_mechanics_readiness_audit.md`
- aucun fichier tracked modifié/supprimé.

## 18. Conclusion

Le repo est techniquement avancé sur les fondations et le battle/runtime slice, mais la readiness fangame Pokémon-like complète reste `🟡 PARTIAL` à l'échelle produit: la progression RPG (XP/level/evolution), la boucle collection stockage (PC/box), l'économie/soins, et une partie des commandes événementielles/field moves ne sont pas encore prouvées comme jouables de bout en bout.

FG-000 peut être considéré clôturable en tant qu'audit (`🧪 AUDIT`) avec ce rapport; la suite recommandée est FG-001 pour verrouiller l'intégration roadmap canonique avant d'enchaîner les lots mécaniques.
