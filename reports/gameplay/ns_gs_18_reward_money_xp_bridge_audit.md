# NS-GS-18 — Reward / Money / XP Bridge Audit

## 1. Résumé exécutif

NS-GS-18 est un lot d'audit et de caractérisation, pas un lot d'implémentation reward engine.

Verdict :

- Item reward post-battle : prouvé au niveau application via `dispatchContinuation` + action scénario `giveItem` + fact/step + save/load.
- Money : partiel. `TrainerProfile.money` existe et persiste, mais aucune mutation `giveMoney`, aucune action scénario money, aucun champ trainer reward et aucun write-back post-battle money ne sont présents.
- XP / level-up : absent comme reward persistent. `PlayerPokemon.level` existe, le runtime peut dériver des moves de départ depuis un learnset pour construire un combat, mais il n'existe pas de champ XP, pas de mutation add XP, pas de level-up post-battle et pas de learn-move post-battle.
- Trainer rewards : absent comme contrat data. Les trainers ne portent pas de `reward`, `money`, `prize` ou `payout`.
- Static/boss rewards : même niveau que trainer-like NS-GS-17, c'est-à-dire reward item possible via scène après outcome, pas via pont reward dédié.

Décision : ne pas créer de système XP/money/rewards dans ce lot. Le prochain lot recommandé est `NS-GS-19 — Reward Model Minimal Design`.

## 2. Roadmap lue et statut initial

Roadmap lue avant modification :

- `MVP Selbrume/road_map.md`
- `pokemap_roadmap_mecaniques_fangame.md`

Statut initial pertinent dans `MVP Selbrume/road_map.md` :

```text
PHASE 6 — Extension gameplay
✅ NS-GS-14   — Item Pickup / GiveItem Authoring Readiness
✅ NS-GS-15   — Key Item / Door Gate Readiness
✅ NS-GS-16   — Side Quest / Optional Storyline Readiness
✅ NS-GS-17   — Static Encounter / Boss Battle Readiness
🔜 NS-GS-18   — Reward / Money / XP Bridge Audit
```

`pokemap_roadmap_mecaniques_fangame.md` a été consulté conformément à `AGENTS.md`. NS-GS-18 se rattache aux gaps de boucle fangame rewards / bag / progression / battle result, mais le lot demandé reste gouverné par la roadmap Narrative Studio `NS-GS`.

## 3. Périmètre exact du lot

Inclus :

- audit rewards / money / XP / level-up / trainer rewards ;
- caractérisation d'un reward item post-battle déjà possible par scène ;
- rapport factuel et mise à jour roadmap ;
- aucun changement de code de production.

Exclus :

- reward engine complet ;
- XP engine ;
- money system complet ;
- level-up system ;
- learn-move post-battle ;
- modification `map_battle` ;
- modification des règles de combat ;
- UI rewards ;
- contenu Selbrume final ;
- `project.json`.

## 4. Frontière Battle / Scene / Reward / GameState / Validator

Frontière maintenue :

- Battle résout et produit un `BattleOutcome`.
- Scene orchestre la continuation post-outcome et peut appliquer `giveItem`, `setFlag`, `completeStep`.
- Reward est un effet gameplay borné ; en V0 prouvé uniquement pour item via scène.
- GameState persiste `bag`, `trainerProfile.money`, `party`, `progression`, `storyFlags`.
- Validator diagnostique ; il n'exécute pas de reward et n'a pas été modifié.

## 5. Audit initial

### Git status initial exact

```text
```

La sortie était vide : aucun fichier modifié ou untracked au démarrage du lot NS-GS-18.

### Rapports lus

- `reports/gameplay/ns_gs_17_static_encounter_boss_battle_readiness.md`
- `reports/gameplay/ns_gs_16_side_quest_optional_storyline_readiness.md`
- `reports/gameplay/ns_gs_15_key_item_door_gate_readiness.md`
- `reports/gameplay/ns_gs_14_item_pickup_give_item_authoring_readiness.md`
- `reports/gameplay/ns_gs_13_bis_evidence_pack_closure.md`
- `reports/gameplay/ns_gs_13_narrative_validator_minimal_v0.md`
- `reports/gameplay/ns_gs_12_bis_evidence_pack_and_level_label_fix.md`
- `reports/gameplay/ns_gs_11_bis_evidence_pack_fix.md`
- `reports/gameplay/ns_gs_11_trainer_battle_authoring_readiness.md`

### Commandes d'audit exécutées

```bash
rg "reward|Reward|money|Money|coin|coins|gold|cash|payout|prize|experience|Experience|xp|XP|exp|levelUp|level|learnMove|learnset" packages --type dart

rg "BattleOutcome|BattleResult|applyRuntimeBattleOutcome|trainer_defeated|defeated|victory|defeat|captured|runaway" packages/map_core packages/map_runtime packages/map_battle --type dart

rg "PlayerPokemon|party|level|currentHp|maxHp|experience|exp|xp|learned|move" packages/map_core packages/map_gameplay packages/map_runtime --type dart

rg "Bag|BagEntry|giveItem|itemId|quantity|GameStateMutations|completeStep|setFlag" packages/map_core packages/map_gameplay packages/map_runtime --type dart

rg "Trainer|trainerId|reward|money|prize|lineup|team|party" packages/map_core packages/map_runtime packages/map_battle --type dart

rg "saveDataFromGameState|gameStateFromSaveData|normalizeLoadedGameState|money|bag|party|progression" packages/map_core --type dart
```

Recherches ciblées utilisées pour figer les conclusions :

```text
$ rg -n "reward|Reward|money|Money|prize|payout" packages/map_core/lib/src/models/project_trainer.dart packages/map_runtime/lib/src/application/battle_start_request.dart packages/map_runtime/lib/src/application/trainer_battle_request.dart packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart packages/map_battle/lib/src/battle_resolution.dart
<no output>

$ rg -n "money|Money" packages/map_core/lib/src/models/game_state.dart packages/map_core/lib/src/models/save_data.dart packages/map_core/lib/src/operations/game_state_persistence.dart packages/map_gameplay/lib/src/game_state_mutations.dart packages/map_runtime/lib/src/application packages/map_battle/lib/src/battle_resolution.dart --type dart
packages/map_core/lib/src/models/save_data.dart:240:    @Default(0) int money,
packages/map_core/lib/src/models/save_data.dart:257:    if (money < 0) {
packages/map_core/lib/src/models/save_data.dart:258:      throw StateError('TrainerProfile money must be non-negative');

$ rg -n "experience|Experience|\bxp\b|\bXP\b|\bexp\b|levelUp|learnMove|learnset" packages/map_core/lib/src/models/save_data.dart packages/map_core/lib/src/models/game_state.dart packages/map_core/lib/src/operations/game_state_persistence.dart packages/map_gameplay/lib/src/game_state_mutations.dart packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart packages/map_battle/lib/src/battle_resolution.dart --type dart
packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:9:import 'runtime_pokemon_learnset_loader.dart';
packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:12:/// Politique partagée de sélection des moves dérivés d'un learnset.
packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:22:/// - relearnMoves
packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:23:/// - levelUp <= niveau courant
packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:27:  required RuntimePokemonLearnset learnset,
packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:31:    ...learnset.startingMoves,
packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:32:    ...learnset.relearnMoves,
packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:33:    ...learnset.levelUp
packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:222:/// - la lecture species/learnsets déjà extraite en M6 ;
packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:236:    RuntimePokemonLearnsetLoader? learnsetLoader,
packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:239:        learnsetLoader = learnsetLoader ?? RuntimePokemonLearnsetLoader();
packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:242:  final RuntimePokemonLearnsetLoader learnsetLoader;
packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:397:    final learnset = await learnsetLoader.loadByRef(
packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:400:      speciesRef: species.learnsetRef,
packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:405:      learnset: learnset,

$ rg -n "giveItem|giveMoney|addExperience|levelUp|completeStep|setFlag|kScenarioActionGiveItem|kScenarioActionStartTrainerBattle" packages/map_gameplay/lib/src/game_state_mutations.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_gameplay/lib/src/game_state_mutations.dart:14:  GameState setFlag(GameState state, String flagName) {
packages/map_gameplay/lib/src/game_state_mutations.dart:137:  GameState giveItem(
packages/map_gameplay/lib/src/game_state_mutations.dart:231:  GameState completeStep(GameState state, String stepId) {
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:25:const String kScenarioActionSetFlag = 'setFlag';
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:41:const String kScenarioActionStartTrainerBattle = 'startTrainerBattle';
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:62:/// La mutation est appliquée via [GameStateMutations.giveItem].
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:64:const String kScenarioActionGiveItem = 'giveItem';
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:71:const String kScenarioActionCompleteStep = 'completeStep';
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:629:                  message: 'Action setFlag sans flagName dans "${node.id}".',
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:983:            case kScenarioActionStartTrainerBattle:
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:1105:            case kScenarioActionGiveItem:
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:1114:                  message: 'Action giveItem sans itemId dans "${node.id}".',
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:1129:                      'Action giveItem avec quantity non positive dans "${node.id}".',
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:1134:              final nextItemState = itemMutations.giveItem(
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:1166:                  message: 'Action completeStep sans stepId dans "${node.id}".',
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:1169:              // Idempotent: calling completeStep twice is safe.
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:1171:              final nextStepState = stepMutations.completeStep(
```

## 6. État actuel des rewards item

Support actuel : prouvé au niveau application par scène.

Preuves inspectées :

- `GameStateMutations.giveItem` ajoute un item au `Bag` et additionne les quantités : `packages/map_gameplay/lib/src/game_state_mutations.dart:137`.
- `ScenarioRuntimeExecutor` expose `kScenarioActionGiveItem` et applique la mutation : `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:64`, `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:1105`.
- `BagEntry` et `Bag` existent et normalisent les entrées : `packages/map_core/lib/src/models/save_data.dart:271`, `packages/map_core/lib/src/models/save_data.dart:326`.
- `saveDataFromGameState` persiste `bag` : `packages/map_core/lib/src/operations/game_state_persistence.dart:45`.

Test ajouté :

- `packages/map_runtime/test/reward_bridge_readiness_test.dart`

Ce test prouve :

```text
trainer victory flag
→ dispatchContinuation
→ condition victory
→ giveItem test_item_reward x2
→ setFlag test_reward_claimed_fact
→ completeStep test_step_reward_claimed
→ save/load conserve bag + fact + step
```

Limite : il n'existe pas encore de modèle `Reward` dédié ; c'est une composition authorable par scène.

## 7. État actuel de money

Support actuel : partiel.

Ce qui existe :

- `TrainerProfile.money` est dans `SaveData` : `packages/map_core/lib/src/models/save_data.dart:240`.
- `TrainerProfile.normalized()` refuse une monnaie négative : `packages/map_core/lib/src/models/save_data.dart:257`.
- `GameState` contient `trainerProfile` : `packages/map_core/lib/src/models/game_state.dart:88`.
- `gameStateFromSaveData` et `saveDataFromGameState` transportent `trainerProfile` : `packages/map_core/lib/src/operations/game_state_persistence.dart:16`, `packages/map_core/lib/src/operations/game_state_persistence.dart:45`.

Ce qui manque :

- pas de `GameStateMutations.giveMoney` ;
- pas de `kScenarioActionGiveMoney` ;
- pas de champ reward money dans `ProjectTrainerEntry` ;
- pas de champ money dans `TrainerBattleStartRequest` ;
- pas d'application money dans `applyRuntimeBattleOutcomeToGameState`.

Conclusion : money est un état persistant, pas encore un reward bridge.

## 8. État actuel de XP / level-up

Support actuel : absent comme système reward.

Ce qui existe :

- `PlayerPokemon.level` existe : `packages/map_core/lib/src/models/save_data.dart:107`.
- `knownMoveIds` existe : `packages/map_core/lib/src/models/save_data.dart:110`.
- Le builder de combattants runtime peut sélectionner des moves d'un learnset pour démarrer un combat : `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:12`, `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:27`.

Ce qui manque :

- aucun champ `experience` / `xp` dans `PlayerPokemon` ;
- aucune mutation `addExperience` ;
- aucun calcul level-up post-battle ;
- aucun learn-move post-battle ;
- aucun write-back XP depuis `BattleOutcome`.

Conclusion : le niveau est un attribut de Pokémon, pas encore une progression XP.

## 9. État actuel des rewards trainer

Support actuel : absent comme modèle reward.

Preuves :

- `ProjectTrainerEntry` porte id/name/class/difficulté/background/character/portrait/theme/team/tags, mais pas reward : `packages/map_core/lib/src/models/project_trainer.dart:29`.
- `TrainerBattleStartRequest` porte trainerId/npcEntityId/mapId/playerPos, mais pas reward : `packages/map_runtime/lib/src/application/battle_start_request.dart:106`.
- `buildTrainerBattleRequestFromNpc` ne lit aucun champ reward : `packages/map_runtime/lib/src/application/trainer_battle_request.dart:17`.
- Recherche ciblée `reward|money|prize|payout` sur trainer/request/outcome : aucune sortie.

Le seul effet automatique trainer post-victory observé est `trainer_defeated:{trainerId}` via `StoryFlagsManager`, appliqué dans `applyRuntimeBattleOutcomeToGameState` : `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:225`.

## 10. État actuel des rewards static/boss

Support actuel : partiel via pattern scène.

NS-GS-17 a prouvé un boss trainer-like authorable, pas un vrai static wild authorable. NS-GS-18 ajoute seulement la preuve que la continuation post-battle peut donner un item.

Ce qui est prouvé :

```text
trainer-like boss outcome victory
→ battle:<battleId>:victory
→ dispatchContinuation
→ giveItem / setFlag / completeStep
```

Ce qui n'est pas prouvé :

- reward automatique sur `WildBattleStartRequest` ;
- reward automatique sur capture ;
- reward table static/boss ;
- XP/money static/boss.

## 11. État actuel post-battle continuation

Support actuel : solide pour orchestration narrative, borné pour rewards.

Preuves :

- `startTrainerBattle` suspend le graphe avec un effet battle : `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart:983`.
- `BattleOutcomeType` expose `victory`, `defeat`, `runaway`, `captured`, sans payload reward : `packages/map_battle/lib/src/battle_resolution.dart:409`.
- `BattleOutcome` transporte `type` + `finalState`, sans reward : `packages/map_battle/lib/src/battle_resolution.dart:434`.
- `applyRuntimeBattleOutcomeToGameState` écrit les PV, gère capture sauvage minimale et marque trainer defeated, mais son commentaire exclut explicitement les récompenses : `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:160`.

Conclusion : la continuation post-battle est le bon pont authorable actuel ; le résultat battle lui-même ne transporte pas de reward.

## 12. Tests ajoutés ou caractérisés

Fichier ajouté :

- `packages/map_runtime/test/reward_bridge_readiness_test.dart`

Liste complète des 5 tests :

```text
trainer victory continuation can give item reward
trainer victory continuation can complete reward fact and step
save load preserves post battle item reward fact and step
post battle item reward does not imply money xp or level up
fixtures use only generic reward bridge ids
```

Premiers runs de développement :

- Un premier run a échoué parce que le test utilisait une API `ScenarioAsset` obsolète ; corrigé dans le test uniquement.
- Un deuxième run a échoué parce que `setFlag` lit `ScenarioNodeBinding.flagName`, pas `payload.params`; corrigé dans le test uniquement.

Ces corrections n'ont modifié aucun code de production.

## 13. Matrice de readiness

| Domaine | Statut | Preuve | Limite |
|---|---|---|---|
| Item reward post-battle | Prouvé application-level | Nouveau test NS-GS-18 | Via scène, pas modèle `Reward` |
| Bag persistence | Prouvé | Nouveau test + `game_state_persistence.dart` | Pas de Bag UI |
| Fact/step post-reward | Prouvé | Nouveau test | Registry step absent |
| Money state | Partiel | `TrainerProfile.money` | Pas de mutation/action/reward bridge |
| Money persistence | Présent | `trainerProfile` save/load | Pas testé comme reward car pas de reward money |
| XP state | Absent | absence de champ XP dans `PlayerPokemon` | Niveau seul présent |
| Level-up | Absent | pas de mutation / write-back | Hors scope NS-GS-18 |
| Learn move post-battle | Absent | learnset seulement pour seed battle | Pas de post-battle apprendre attaque |
| Trainer rewards | Absent | `ProjectTrainerEntry` sans reward | Design requis |
| Static/boss rewards | Partiel | pattern trainer-like + scène | Pas de static wild reward |
| BattleOutcome rewards | Absent | `BattleOutcome` type + finalState seulement | Pas de payload rewards |
| Runtime write-back rewards | Absent | `applyRuntimeBattleOutcomeToGameState` sans reward | Capture consomme Poké Ball, pas reward |
| Validator reward diagnostics | Absent volontaire | pas de modèle reward stable | Futur lot après design |

## 14. Gaps et risques

Gaps :

- pas de contrat reward commun ;
- pas de décision sur l'ownership de l'application reward : runtime write-back direct ou scène ;
- pas de modèle money reward ;
- pas de modèle XP / experience curve / level-up / learn move ;
- pas de rewards trainer/static dans les données projet ;
- pas de validator reward.

Risques si on implémente trop tôt :

- coupler `map_battle` à la narration ;
- mélanger battle resolution et progression narrative ;
- hardcoder des règles Pokémon incomplètes ;
- créer une API reward difficile à migrer.

## 15. Décision : implémenter maintenant ou découper

Décision : découper.

NS-GS-18 ajoute un test de caractérisation pour le seul pont sûr : item reward post-battle via scène. Le reste doit passer par design minimal avant implémentation.

Prochain lot recommandé :

```text
NS-GS-19 — Reward Model Minimal Design
```

Objectif recommandé pour NS-GS-19 :

- décider si un reward est une action scénario, une donnée trainer, un effet post-battle ou une combinaison ;
- définir une structure minimale `Reward` sans XP engine complet ;
- définir le statut de money ;
- définir le statut XP/level-up/learn-move ;
- préciser comment le validator pourra diagnostiquer les reward refs.

## 16. Fichiers créés / modifiés

Créés :

- `packages/map_runtime/test/reward_bridge_readiness_test.dart`
- `reports/gameplay/ns_gs_18_reward_money_xp_bridge_audit.md`

Modifiés :

- `MVP Selbrume/road_map.md`

Non modifiés :

- `packages/map_runtime/lib`
- `packages/map_core/lib`
- `packages/map_gameplay/lib`
- `packages/map_battle/lib`
- `packages/map_editor`

## 17. Commandes exécutées

Audit :

```bash
git status --short --untracked-files=all
rg "reward|Reward|money|Money|coin|coins|gold|cash|payout|prize|experience|Experience|xp|XP|exp|levelUp|level|learnMove|learnset" packages --type dart
rg "BattleOutcome|BattleResult|applyRuntimeBattleOutcome|trainer_defeated|defeated|victory|defeat|captured|runaway" packages/map_core packages/map_runtime packages/map_battle --type dart
rg "PlayerPokemon|party|level|currentHp|maxHp|experience|exp|xp|learned|move" packages/map_core packages/map_gameplay packages/map_runtime --type dart
rg "Bag|BagEntry|giveItem|itemId|quantity|GameStateMutations|completeStep|setFlag" packages/map_core packages/map_gameplay packages/map_runtime --type dart
rg "Trainer|trainerId|reward|money|prize|lineup|team|party" packages/map_core packages/map_runtime packages/map_battle --type dart
rg "saveDataFromGameState|gameStateFromSaveData|normalizeLoadedGameState|money|bag|party|progression" packages/map_core --type dart
```

Tests et analyze :

```bash
cd packages/map_runtime && flutter test test/reward_bridge_readiness_test.dart
cd packages/map_runtime && flutter test test/trainer_battle_authoring_readiness_test.dart test/item_pickup_give_item_readiness_test.dart test/static_encounter_boss_battle_readiness_test.dart
cd packages/map_runtime && flutter test test/static_encounter_boss_battle_readiness_test.dart
cd packages/map_runtime && flutter analyze test/reward_bridge_readiness_test.dart
rg -n "Maël|mael|Lysa|lysa|Soline|soline|Selbrume|Bourg de Selbrume|Port des Brisants|map_bourg_selbrume|map_port_brisants|npc_mael|npc_lysa|npc_soline|trainer_lysa_port|battle_rival_port|scene_mael_intro|scene_rival_meet|yarn_mael_intro|yarn_rival_intro|Sproutle|Sparkitten|cristaux de sel|Goélise|clé du phare|cabane du phare|phare|goéland|cristaux|Pokémon du phare" packages/map_runtime/test/reward_bridge_readiness_test.dart
```

Evidence final :

```bash
git diff --no-index /dev/null packages/map_runtime/test/reward_bridge_readiness_test.dart || true
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

## 18. Résultats des tests

### Test ciblé NS-GS-18

Commande :

```bash
cd packages/map_runtime && flutter test test/reward_bridge_readiness_test.dart
```

Sortie finale :

```text
Waiting for another flutter command to release the startup lock...
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/reward_bridge_readiness_test.dart
00:00 +0: Reward bridge readiness trainer victory continuation can give item reward
00:00 +1: Reward bridge readiness trainer victory continuation can complete reward fact and step
00:00 +2: Reward bridge readiness save load preserves post battle item reward fact and step
00:00 +3: Reward bridge readiness post battle item reward does not imply money xp or level up
00:00 +4: Reward bridge readiness fixtures use only generic reward bridge ids
00:00 +5: All tests passed!
```

### Régressions proches

Commande :

```bash
cd packages/map_runtime && flutter test test/trainer_battle_authoring_readiness_test.dart test/item_pickup_give_item_readiness_test.dart test/static_encounter_boss_battle_readiness_test.dart
```

Sortie observée :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/trainer_battle_authoring_readiness_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_runtime/test/trainer_battle_authoring_readiness_test.dart: Scene action → battle effect startTrainerBattle produces battle effect with correct ids
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_runtime/test/trainer_battle_authoring_readiness_test.dart: Scene action → battle effect graph suspends at battle node (no leak past)
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_runtime/test/trainer_battle_authoring_readiness_test.dart: Scene action → battle effect result has non-null scenarioId/sourceNodeId/stopNodeId
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_runtime/test/trainer_battle_authoring_readiness_test.dart: Battle outcome flags victory flag format: battle:<battleId>:victory
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_runtime/test/trainer_battle_authoring_readiness_test.dart: Battle outcome flags defeat flag format: battle:<battleId>:defeat
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_runtime/test/trainer_battle_authoring_readiness_test.dart: Battle outcome flags flee flag format: battle:<battleId>:flee
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_runtime/test/trainer_battle_authoring_readiness_test.dart: Battle outcome flags captured flag format: battle:<battleId>:captured
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_runtime/test/trainer_battle_authoring_readiness_test.dart: Scenario continuation after battle victory: continuation sets flag and completes step
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_runtime/test/trainer_battle_authoring_readiness_test.dart: Scenario continuation after battle defeat: continuation sets flag and completes step
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_runtime/test/trainer_battle_authoring_readiness_test.dart: Scenario continuation after battle victory continuation opens dialogue on branch if present
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_runtime/test/trainer_battle_authoring_readiness_test.dart: Save / reload preserves battle outcome flags battle outcome flags survive save/load round-trip
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_runtime/test/trainer_battle_authoring_readiness_test.dart: Save / reload preserves battle outcome flags defeat flags also survive save/load
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_runtime/test/trainer_battle_authoring_readiness_test.dart: does not hardcode any Selbrume ids
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness new game starts with empty bag
00:00 +14: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness giveItem action adds item with quantity
00:00 +15: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness giveItem action accumulates quantity when item already exists
00:00 +16: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness giveItem action blocks when itemId is missing
00:00 +17: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness giveItem action blocks when itemId is blank
00:00 +18: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness giveItem action defaults missing or invalid quantity to one
00:00 +19: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness giveItem action blocks non-positive quantity
00:00 +20: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness scenario item pickup gives item and records fact and step
00:00 +21: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness save/load preserves bag item quantity, pickup fact, and step
00:00 +22: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness scenario activation condition prevents a second pickup
00:00 +23: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness world rule pattern hides pickup proxy after pickup fact
00:00 +24: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness playable item entity interaction dispatches pickup scenario
00:00 +25: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness playable item entity interaction dispatches pickup scenario
00:00 +26: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness playable item entity interaction dispatches pickup scenario
00:00 +27: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness playable item entity interaction dispatches pickup scenario
00:00 +28: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness playable item entity interaction dispatches pickup scenario
00:00 +29: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness playable item entity interaction dispatches pickup scenario
[runtime] Map loaded: test_map, spawn at (0, 0)
00:00 +30: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness playable item entity interaction dispatches pickup scenario
00:00 +31: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness playable item entity interaction dispatches pickup scenario
00:00 +32: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness playable item entity interaction dispatches pickup scenario
00:00 +33: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness playable item entity interaction dispatches pickup scenario
00:00 +34: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness playable item entity interaction dispatches pickup scenario
00:00 +35: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness playable item entity interaction dispatches pickup scenario
00:00 +36: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness playable item entity interaction dispatches pickup scenario
00:00 +37: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness playable item entity interaction dispatches pickup scenario
[interact] Item: test_pickup_entity
[runtime] local scenario "test_pickup_scene" marked completed (predicate cutsceneCompleted).
[step_studio_trace] completion_applied scenario=test_pickup_scene origin=dispatch:entityInteract completedSteps=[test_step_pickup_done] completedCutscenes=[test_pickup_scene]
[scenario_runtime] source=entityInteract map=test_map trigger=- entity=test_pickup_entity status=reachedEnd scenario=test_pickup_scene sourceNode=test_source_pickup stopNode=test_end_pickup message=Flow terminé sur End.
00:00 +38: /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart: Item Pickup / GiveItem authoring readiness fixtures use only generic test ids
00:00 +39: All tests passed!
```

Le troisième chemin demandé dans cette commande n'a pas été pris par Flutter dans ce run multi-fichiers ; il a donc été relancé séparément.

Commande :

```bash
cd packages/map_runtime && flutter test test/static_encounter_boss_battle_readiness_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/static_encounter_boss_battle_readiness_test.dart
00:00 +0: Static Encounter / Boss Battle authoring readiness static boss proxy is available before resolution
00:00 +1: Static Encounter / Boss Battle authoring readiness entity interaction launches trainer-like boss battle effect
00:00 +2: Static Encounter / Boss Battle authoring readiness battle effect carries generic battle trainer and npc ids
00:00 +3: Static Encounter / Boss Battle authoring readiness battle node suspends graph before post-battle facts
00:00 +4: Static Encounter / Boss Battle authoring readiness victory outcome completes static encounter path
00:00 +5: Static Encounter / Boss Battle authoring readiness defeat outcome completes defeat branch without resolution step
00:00 +6: Static Encounter / Boss Battle authoring readiness flee outcome can branch when supplied by battle outcome convention
00:00 +7: Static Encounter / Boss Battle authoring readiness captured outcome can complete one-shot path when supplied
00:00 +8: Static Encounter / Boss Battle authoring readiness one-shot condition prevents replay after victory or capture
00:00 +9: Static Encounter / Boss Battle authoring readiness save load preserves static encounter victory resolution
00:00 +10: Static Encounter / Boss Battle authoring readiness world rule hides encounter proxy after post-battle fact
00:00 +11: Static Encounter / Boss Battle authoring readiness world rule changes post-battle dialogue after victory
00:00 +12: Static Encounter / Boss Battle authoring readiness fixtures use only generic test ids
00:00 +13: All tests passed!
```

## 19. Résultat analyzer

Commande :

```bash
cd packages/map_runtime && flutter analyze test/reward_bridge_readiness_test.dart
```

Sortie finale :

```text
Analyzing reward_bridge_readiness_test.dart...                  
No issues found! (ran in 1.4s)
```

## 20. Résultat git diff --check

Résultat final à jour :

```text
```

## 21. Mise à jour road_map.md

Mise à jour prévue / appliquée :

- `NS-GS-18` passe de prochain lot à lot exécuté ;
- le résumé indique que le pont item reward post-battle est prouvé via scène ;
- money est classé partiel ;
- XP/level-up/learn-move sont classés absents comme système reward ;
- aucun reward engine complet n'est créé ;
- prochain lot recommandé : `NS-GS-19 — Reward Model Minimal Design`.

Hunks exacts :

```diff
diff --git a/MVP Selbrume/road_map.md b/MVP Selbrume/road_map.md
index 02247140..bf917175 100644
--- a/MVP Selbrume/road_map.md	
+++ b/MVP Selbrume/road_map.md	
@@ -573,20 +573,21 @@ PHASE 6 — Extension gameplay
 ✅ NS-GS-15   — Key Item / Door Gate Readiness
 ✅ NS-GS-16   — Side Quest / Optional Storyline Readiness
 ✅ NS-GS-17   — Static Encounter / Boss Battle Readiness
-🔜 NS-GS-18   — Reward / Money / XP Bridge Audit
+✅ NS-GS-18   — Reward / Money / XP Bridge Audit
+🔜 NS-GS-19   — Reward Model Minimal Design
 ```
 
 # Prochain lot exact
 
 ```text
-🔜 NS-GS-18 — Reward / Money / XP Bridge Audit
+🔜 NS-GS-19 — Reward Model Minimal Design
 ```
 
 Périmètre :
 
 ```text
-Auditer le pont rewards post-combat :
-XP, money rewards, post-battle rewards, give item after battle,
+Stabiliser le modèle minimal des rewards avant implémentation :
+item reward, money, XP/level-up, ownership scène/runtime,
 sans créer de reward engine complet.
 Pas de fixtures Selbrume finales.
 Tests obligatoires.
@@ -874,3 +875,21 @@ Mettre à jour MVP Selbrume/road_map.md.
 | Mechanics-first | ✅ Brique générique authorable caractérisée. Aucun contenu Selbrume final. Aucune fixture Selbrume finale. Aucun `project.json` Selbrume généré. |
 | Prochain lot | NS-GS-18 — Reward / Money / XP Bridge Audit |
 | Rapport | `reports/gameplay/ns_gs_17_static_encounter_boss_battle_readiness.md` |
+
+---
+
+# Mise à jour NS-GS-18 — 2026-05-24
+
+| Champ | Détail |
+|---|---|
+| Lot exécuté | NS-GS-18 — Reward / Money / XP Bridge Audit |
+| Résultat | Audit rewards/money/XP livré. Le pont item reward post-battle est prouvé au niveau application via battle outcome flag → `dispatchContinuation` → `giveItem` → fact/step → save/load. |
+| Décision | Cas B/C : item reward post-battle possible via scène ; money existe seulement comme état persistant ; XP/level-up/learn-move post-battle absents ; trainer/static rewards sans contrat data. Aucun reward engine ajouté. |
+| Fichiers | `packages/map_runtime/test/reward_bridge_readiness_test.dart`, rapport NS-GS-18, `MVP Selbrume/road_map.md` |
+| Tests exécutés | `cd packages/map_runtime && flutter test test/reward_bridge_readiness_test.dart` ; régressions `trainer_battle_authoring_readiness_test.dart`, `item_pickup_give_item_readiness_test.dart`, `static_encounter_boss_battle_readiness_test.dart` |
+| Analyzer | `cd packages/map_runtime && flutter analyze test/reward_bridge_readiness_test.dart` → No issues found. |
+| git diff --check | Passé ; sortie vide. |
+| Limites | Pas de modèle `Reward`; pas de `giveMoney`; pas de `kScenarioActionGiveMoney`; pas de champs trainer reward ; pas de XP field ; pas de level-up / learn-move post-battle ; pas de validator reward. |
+| Mechanics-first | ✅ Audit + test générique uniquement. Aucun contenu Selbrume final. Aucune fixture Selbrume finale. Aucun `project.json` Selbrume généré. |
+| Prochain lot | NS-GS-19 — Reward Model Minimal Design |
+| Rapport | `reports/gameplay/ns_gs_18_reward_money_xp_bridge_audit.md` |
```

## 22. Prochain lot recommandé

```text
NS-GS-19 — Reward Model Minimal Design
```

Pourquoi :

- item reward post-battle est prouvé via scène ;
- money existe seulement comme état persistant ;
- XP/level-up n'a pas de modèle ;
- trainer/static rewards n'ont pas de contrat data ;
- il faut stabiliser le modèle avant de brancher un runtime reward bridge.

## 23. Evidence Pack

### Fichiers créés / modifiés

```text
Créé   packages/map_runtime/test/reward_bridge_readiness_test.dart
Créé   reports/gameplay/ns_gs_18_reward_money_xp_bridge_audit.md
Modifié MVP Selbrume/road_map.md
```

### Preuve absence ids Selbrume interdits dans le nouveau test

Commande :

```bash
rg -n "Maël|mael|Lysa|lysa|Soline|soline|Selbrume|Bourg de Selbrume|Port des Brisants|map_bourg_selbrume|map_port_brisants|npc_mael|npc_lysa|npc_soline|trainer_lysa_port|battle_rival_port|scene_mael_intro|scene_rival_meet|yarn_mael_intro|yarn_rival_intro|Sproutle|Sparkitten|cristaux de sel|Goélise|clé du phare|cabane du phare|phare|goéland|cristaux|Pokémon du phare" packages/map_runtime/test/reward_bridge_readiness_test.dart
```

Sortie :

```text
```

La sortie vide signifie qu'aucune chaîne interdite n'est présente dans `reward_bridge_readiness_test.dart`.

### Inventaire du nouveau test

```text
$ wc -l packages/map_runtime/test/reward_bridge_readiness_test.dart
     299 packages/map_runtime/test/reward_bridge_readiness_test.dart

$ rg -n "test\('" packages/map_runtime/test/reward_bridge_readiness_test.dart
19:    test('trainer victory continuation can give item reward', () {
34:    test('trainer victory continuation can complete reward fact and step', () {
49:    test('save load preserves post battle item reward fact and step', () {
69:    test('post battle item reward does not imply money xp or level up', () {
84:    test('fixtures use only generic reward bridge ids', () {
```

### Diff no-index du nouveau test

Commande :

```bash
git diff --no-index /dev/null packages/map_runtime/test/reward_bridge_readiness_test.dart || true
```

Sortie complète :

```diff
diff --git a/packages/map_runtime/test/reward_bridge_readiness_test.dart b/packages/map_runtime/test/reward_bridge_readiness_test.dart
new file mode 100644
index 00000000..06737c48
--- /dev/null
+++ b/packages/map_runtime/test/reward_bridge_readiness_test.dart
@@ -0,0 +1,299 @@
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_gameplay/map_gameplay.dart';
+import 'package:map_runtime/map_runtime.dart';
+
+const String _testMapId = 'test_map';
+const String _testBattleId = 'test_reward_battle';
+const String _testTrainerId = 'test_reward_trainer';
+const String _testNpcEntityId = 'test_reward_npc';
+const String _testRewardItemId = 'test_item_reward';
+const String _testRewardFact = 'test_reward_claimed_fact';
+const String _testRewardStep = 'test_step_reward_claimed';
+const String _testPlayerSpeciesId = 'test_player_species';
+
+void main() {
+  group('Reward bridge readiness', () {
+    const executor = ScenarioRuntimeExecutor();
+
+    test('trainer victory continuation can give item reward', () {
+      var state = _initialState(money: 500);
+
+      _startBattle(executor, state);
+      final result = _continueAfterVictory(
+        executor,
+        state: state,
+        onUpdate: (next) => state = next,
+      );
+
+      expect(result.success, isTrue);
+      expect(state.bag.entries.single.itemId, _testRewardItemId);
+      expect(state.bag.entries.single.quantity, 2);
+    });
+
+    test('trainer victory continuation can complete reward fact and step', () {
+      var state = _initialState();
+
+      _startBattle(executor, state);
+      final result = _continueAfterVictory(
+        executor,
+        state: state,
+        onUpdate: (next) => state = next,
+      );
+
+      expect(result.success, isTrue);
+      expect(state.storyFlags.activeFlags, contains(_testRewardFact));
+      expect(state.progression.completedStepIds, contains(_testRewardStep));
+    });
+
+    test('save load preserves post battle item reward fact and step', () {
+      var state = _initialState(money: 500);
+
+      _continueAfterVictory(
+        executor,
+        state: state,
+        onUpdate: (next) => state = next,
+      );
+
+      final reloaded = normalizeLoadedGameState(
+        gameStateFromSaveData(saveDataFromGameState(state)),
+      );
+
+      expect(reloaded.bag.entries.single.itemId, _testRewardItemId);
+      expect(reloaded.bag.entries.single.quantity, 2);
+      expect(reloaded.storyFlags.activeFlags, contains(_testRewardFact));
+      expect(reloaded.progression.completedStepIds, contains(_testRewardStep));
+      expect(reloaded.trainerProfile.money, 500);
+    });
+
+    test('post battle item reward does not imply money xp or level up', () {
+      var state = _initialState(money: 500, level: 7);
+
+      _continueAfterVictory(
+        executor,
+        state: state,
+        onUpdate: (next) => state = next,
+      );
+
+      final member = state.party.members.single;
+      expect(state.trainerProfile.money, 500);
+      expect(member.level, 7);
+      expect(member.knownMoveIds, <String>['test_move']);
+    });
+
+    test('fixtures use only generic reward bridge ids', () {
+      final fixtureIds = <String>{
+        _testMapId,
+        _testBattleId,
+        _testTrainerId,
+        _testNpcEntityId,
+        _testRewardItemId,
+        _testRewardFact,
+        _testRewardStep,
+        _testPlayerSpeciesId,
+      };
+
+      for (final id in fixtureIds) {
+        expect(id, startsWith('test_'));
+      }
+    });
+  });
+}
+
+GameState _initialState({int money = 0, int level = 5}) {
+  return createNewGameState(
+    startMapId: _testMapId,
+    saveId: 'test_reward_save',
+  ).copyWith(
+    trainerProfile: TrainerProfile(name: 'Test Player', money: money),
+    party: PlayerParty(
+      members: <PlayerPokemon>[
+        PlayerPokemon(
+          speciesId: _testPlayerSpeciesId,
+          natureId: 'test_nature',
+          abilityId: 'test_ability',
+          level: level,
+          knownMoveIds: const <String>['test_move'],
+          currentHp: 12,
+        ),
+      ],
+    ),
+  );
+}
+
+ScenarioRuntimeExecutionResult _startBattle(
+  ScenarioRuntimeExecutor executor,
+  GameState state,
+) {
+  return executor.dispatch(
+    scenarios: [_rewardScenario()],
+    sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
+      mapId: _testMapId,
+      entityId: _testNpcEntityId,
+    ),
+    context: _context(
+      state,
+      onUpdate: (_) {},
+    ),
+  );
+}
+
+ScenarioRuntimeExecutionResult _continueAfterVictory(
+  ScenarioRuntimeExecutor executor, {
+  required GameState state,
+  required void Function(GameState next) onUpdate,
+}) {
+  final stateWithVictory = state.copyWith(
+    storyFlags: StoryFlags(
+      activeFlags: <String>{
+        ...state.storyFlags.activeFlags,
+        scenarioBattleOutcomeFlagName(
+          _testBattleId,
+          kBattleOutcomeSuffixVictory,
+        ),
+      },
+    ),
+  );
+
+  return executor.dispatchContinuation(
+    scenarios: [_rewardScenario()],
+    scenarioId: 'test_reward_bridge_scene',
+    sourceNodeId: 'test_source_reward_battle',
+    context: _context(stateWithVictory, onUpdate: onUpdate),
+    resumeAfterNodeId: 'test_start_reward_battle',
+  );
+}
+
+ScenarioRuntimeExecutionContext _context(
+  GameState state, {
+  required void Function(GameState next) onUpdate,
+}) {
+  return ScenarioRuntimeExecutionContext(
+    gameState: state,
+    onGameStateUpdated: onUpdate,
+    openDialogue: (_, {startNode, runtimeSourceId}) => false,
+    runScript: (_, {startNode, runtimeSourceId}) => false,
+    showMessage: (_) {},
+  );
+}
+
+ScenarioAsset _rewardScenario() {
+  final victoryFlag = scenarioBattleOutcomeFlagName(
+    _testBattleId,
+    kBattleOutcomeSuffixVictory,
+  );
+
+  return ScenarioAsset(
+    id: 'test_reward_bridge_scene',
+    name: 'Test Reward Bridge Scene',
+    entryNodeId: 'test_start',
+    nodes: <ScenarioNode>[
+      const ScenarioNode(id: 'test_start', type: ScenarioNodeType.start),
+      const ScenarioNode(
+        id: 'test_source_reward_battle',
+        type: ScenarioNodeType.reference,
+        payload: ScenarioNodePayload(
+          actionKind: kScenarioSourceEntityInteract,
+        ),
+        binding: ScenarioNodeBinding(
+          mapId: _testMapId,
+          entityId: _testNpcEntityId,
+        ),
+      ),
+      const ScenarioNode(
+        id: 'test_start_reward_battle',
+        type: ScenarioNodeType.action,
+        binding: ScenarioNodeBinding(
+          trainerId: _testTrainerId,
+          entityId: _testNpcEntityId,
+        ),
+        payload: ScenarioNodePayload(
+          actionKind: kScenarioActionStartTrainerBattle,
+          params: <String, String>{'battleId': _testBattleId},
+        ),
+      ),
+      ScenarioNode(
+        id: 'test_condition_reward_victory',
+        type: ScenarioNodeType.condition,
+        payload: ScenarioNodePayload(
+          condition: ScriptCondition(
+            type: ScriptConditionType.flagIsSet,
+            params: <String, String>{
+              ScriptConditionParams.flagName: victoryFlag,
+            },
+          ),
+        ),
+      ),
+      const ScenarioNode(
+        id: 'test_give_reward_item',
+        type: ScenarioNodeType.action,
+        payload: ScenarioNodePayload(
+          actionKind: kScenarioActionGiveItem,
+          params: <String, String>{
+            'itemId': _testRewardItemId,
+            'quantity': '2',
+          },
+        ),
+      ),
+      const ScenarioNode(
+        id: 'test_set_reward_fact',
+        type: ScenarioNodeType.action,
+        binding: ScenarioNodeBinding(flagName: _testRewardFact),
+        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
+      ),
+      const ScenarioNode(
+        id: 'test_complete_reward_step',
+        type: ScenarioNodeType.action,
+        payload: ScenarioNodePayload(
+          actionKind: kScenarioActionCompleteStep,
+          params: <String, String>{
+            'stepId': _testRewardStep,
+          },
+        ),
+      ),
+      const ScenarioNode(
+        id: 'test_reward_end',
+        type: ScenarioNodeType.end,
+      ),
+    ],
+    edges: const <ScenarioEdge>[
+      ScenarioEdge(
+        id: 'test_edge_source_to_battle',
+        fromNodeId: 'test_source_reward_battle',
+        toNodeId: 'test_start_reward_battle',
+      ),
+      ScenarioEdge(
+        id: 'test_edge_battle_to_condition',
+        fromNodeId: 'test_start_reward_battle',
+        toNodeId: 'test_condition_reward_victory',
+      ),
+      ScenarioEdge(
+        id: 'test_edge_reward_victory_true',
+        fromNodeId: 'test_condition_reward_victory',
+        toNodeId: 'test_give_reward_item',
+        kind: ScenarioEdgeKind.trueBranch,
+      ),
+      ScenarioEdge(
+        id: 'test_edge_reward_victory_false',
+        fromNodeId: 'test_condition_reward_victory',
+        toNodeId: 'test_reward_end',
+        kind: ScenarioEdgeKind.falseBranch,
+      ),
+      ScenarioEdge(
+        id: 'test_edge_reward_item_to_fact',
+        fromNodeId: 'test_give_reward_item',
+        toNodeId: 'test_set_reward_fact',
+      ),
+      ScenarioEdge(
+        id: 'test_edge_reward_fact_to_step',
+        fromNodeId: 'test_set_reward_fact',
+        toNodeId: 'test_complete_reward_step',
+      ),
+      ScenarioEdge(
+        id: 'test_edge_reward_step_to_end',
+        fromNodeId: 'test_complete_reward_step',
+        toNodeId: 'test_reward_end',
+      ),
+    ],
+  );
+}
```

### Git diff --stat final

```text
 MVP Selbrume/road_map.md | 27 +++++++++++++++++++++++----
 1 file changed, 23 insertions(+), 4 deletions(-)
```

### Git diff --name-only final

```text
MVP Selbrume/road_map.md
```

### Git status final exact

```text
 M "MVP Selbrume/road_map.md"
?? packages/map_runtime/test/reward_bridge_readiness_test.dart
?? reports/gameplay/ns_gs_18_reward_money_xp_bridge_audit.md
```

## 24. Auto-review critique

- Scope mechanics-first respecté : oui.
- Aucun contenu Selbrume final : oui.
- Aucun `project.json` généré : oui.
- Aucun code `map_battle` modifié : oui.
- Aucun code de production modifié : oui.
- Reward engine complet créé : non.
- Money/XP inventés : non.
- Item reward post-battle prouvé : oui, via scène.
- Money classé honnêtement : oui, état persistant sans bridge.
- XP/level-up classés honnêtement : oui, absents comme reward system.
- Limite principale : le test prouve le pattern authorable actuel, pas un modèle reward unifié.
- Suite recommandée : `NS-GS-19 — Reward Model Minimal Design`.
