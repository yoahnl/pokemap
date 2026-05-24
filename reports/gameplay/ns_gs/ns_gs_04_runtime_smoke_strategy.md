# NS-GS-04 — Runtime Smoke Strategy

---

## 1. Résumé exécutif

Ce lot définit le **contrat de preuve officiel** du Golden Slice Selbrume V0. Il ne crée aucun test, aucune fixture, aucun code. Il fixe :

- **Quoi tester** : chaque maillon du pipeline Spawn → Maël → Starter → Port → Lysa → Battle → Outcome → Save/Load.
- **Comment tester** : unit tests purs (map_core, map_gameplay), scenario runtime tests (map_runtime), host smoke tests (playable_runtime_host).
- **Quand tester** : chaque lot (NS-GS-05 à NS-GS-12) a ses propres tests ; NS-GS-12 les combine.
- **Pourquoi des tests intermédiaires** : NS-GS-12 seul ne suffit pas. Un bug dans GivePokemon (NS-GS-06) casse tout le pipeline mais serait invisible si seul le smoke test final existait. Les tests unitaires isolent chaque maillon.
- **Comment éviter un faux positif** : ne pas utiliser de fixtures "magiques" pré-remplies qui contournent le pipeline. Tester aussi le chemin defeat, pas seulement victory.

GivePokemon est la dépendance critique : sans lui, le combat ne peut pas avoir lieu (party vide → crash).

Après review, le prochain lot est **NS-GS-05 — New Game Minimal Runtime**.

---

## 2. Sources et méthode

### Documents lus

| Document | Chemin |
|---|---|
| NS-GS-01 | [ns_gs_01_golden_slice_exact_specification.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/ns_gs_01_golden_slice_exact_specification.md) |
| NS-GS-02 | [ns_gs_02_starter_initial_party_decision.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/ns_gs_02_starter_initial_party_decision.md) |
| NS-GS-03 | [ns_gs_03_content_inventory_fixture_plan.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/ns_gs_03_content_inventory_fixture_plan.md) |

### Tests existants repérés

| Test file | Package | Pertinence |
|---|---|---|
| [game_state_mutations_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/test/game_state_mutations_test.dart) | map_gameplay | giveItem déjà testé — patron pour givePokemon |
| [game_state_persistence_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/test/game_state_persistence_test.dart) | map_core | save/load round-trip, flags migration |
| [save_data_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/test/save_data_test.dart) | map_core | PlayerPokemon, PlayerParty, PlayerProgression sérialization |
| [scenario_assets_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/test/scenario_assets_test.dart) | map_core | ScenarioAsset validation |
| [scenario_conditions_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/test/scenario_conditions_test.dart) | map_runtime | trainerDefeated flag convention |
| [trainer_battle_request_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/test/trainer_battle_request_test.dart) | map_runtime | buildTrainerBattleRequestFromNpc |
| [trainer_defeated_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/test/trainer_defeated_test.dart) | map_runtime | trainer defeated flag, interaction fallback |
| [runtime_battle_outcome_apply_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_outcome_apply_test.dart) | map_runtime | applyRuntimeBattleOutcomeToGameState |
| [cutscene_runtime_runner_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/test/cutscene_runtime_runner_test.dart) | map_runtime | cutscene branching, gotoIfFlag, gotoIfOutcome |
| [global_story_chapter_runtime_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/test/global_story_chapter_runtime_test.dart) | map_runtime | chapter step index |
| [step_studio_completion_runtime_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/test/step_studio_completion_runtime_test.dart) | map_runtime | step completion via cutscene end |
| [step_studio_world_presence_runtime_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/test/step_studio_world_presence_runtime_test.dart) | map_runtime | NPC world presence rules |
| [step_studio_save_reload_visibility_integration_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/test/step_studio_save_reload_visibility_integration_test.dart) | map_runtime | visibility persist after save/load |
| [npc_map_presence_predicate_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/test/npc_map_presence_predicate_test.dart) | map_gameplay | NPC presence predicate filtering |
| [phase_a_golden_battle_slice_smoke_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart) | map_runtime | Existing Phase A golden slice smoke |
| [phase_a_golden_slice_launch_test.dart](file:///Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart) | playable_runtime_host | Host launch save validation |
| [runtime_launch_save_test.dart](file:///Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/runtime_launch_save_test.dart) | playable_runtime_host | Save loading mechanism |

### Limites de l'audit

- Pas de tests lancés.
- Pas de build_runner lancé.
- Audit ciblé sur les fichiers test pertinents pour le Golden Slice.

---

## 3. Décisions héritées de NS-GS-01/02/03

| Décision | Source |
|---|---|
| Maël est un PNJ mentor, pas le joueur | NS-GS-01 |
| Le joueur commence sans Pokémon (party vide) | NS-GS-02-bis |
| Maël donne réellement le starter en jeu (Option A) | NS-GS-02-bis |
| GivePokemon (NS-GS-06) est obligatoire avant NS-GS-12 | NS-GS-02-bis |
| `fact_starter_received` attendu après don | NS-GS-03 |
| `fact_mission_started` attendu après mission | NS-GS-03 |
| Lysa dépend de `fact_starter_received` + `fact_mission_started` | NS-GS-03-bis |
| `yarn_rival_intro` produit `confident` / `hesitant` / `aggressive` | NS-GS-03-bis |
| `cinematic_rival_smiles` et `cinematic_rival_teases` sont canoniques | NS-GS-03-bis |
| starterCandidate = `sproutle` (confirmable/remplaçable) | NS-GS-02 |
| rivalPokemonCandidate = `sparkitten` (confirmable/remplaçable) | NS-GS-02 |

---

## 4. Périmètre de preuve du Golden Slice

| Maillon | À prouver | Automatisé ? | Lot validateur | Notes |
|---|---|---|---|---|
| Initial state party vide | `GameState.party.members` est vide | Oui (unit) | NS-GS-05 | Assertion triviale |
| Interaction Maël possible | `entity_mael_bourg` accessible, déclenche `scene_mael_intro` | Oui (scenario test) | NS-GS-08 | entityInteract source |
| GivePokemon ajoute le starter | `party.members.length == 1`, speciesId correct | Oui (unit) | NS-GS-06 | Mutation testable isolément |
| `fact_starter_received` posé | `storyFlags.activeFlags` contient le flag | Oui (unit + scenario) | NS-GS-06/08 | setFlag action |
| `fact_mission_started` posé | `storyFlags.activeFlags` contient le flag | Oui (unit + scenario) | NS-GS-08 | setFlag action |
| Save/load du starter reçu | Party identique après save → reload | Oui (unit) | NS-GS-06 | game_state_persistence round-trip |
| Warp Bourg → Port | Transition map fonctionne | Manuel (V0) | NS-GS-08/09 | Visual + runtime |
| Lysa invisible avant starter/mission | `wr_lysa_invisible_before_starter_or_mission` bloque présence | Oui (predicate test) | NS-GS-10 | npc_map_presence_predicate pattern |
| Lysa visible après starter/mission | `wr_lysa_visible_before_battle` autorise présence | Oui (predicate test) | NS-GS-10 | Même pattern |
| `yarn_rival_intro` outcomes posture | Dialogue retourne `confident`/`hesitant`/`aggressive` | Oui (scenario test) | NS-GS-09 | openDialogue + outcome routing |
| `cinematic_rival_smiles`/`teases` branchées | Branch pré-combat route correctement | Oui (scenario test) | NS-GS-09 | gotoIfOutcome cutscene step |
| `startTrainerBattle` déclenché | `ScenarioRuntimeEffectType.battle` émis | Oui (scenario test) | NS-GS-11 | Existant dans SEL-B2 tests |
| Battle outcome flag posé | `battle:battle_rival_port:victory` ou `:defeat` dans flags | Oui (unit) | NS-GS-11 | scenarioBattleOutcomeFlagName |
| Scenario continuation après battle | `dispatchContinuation` reprend le graphe | Oui (scenario test) | NS-GS-11 | SEL-B2 pattern |
| Victory branch | setFlag `fact_rival_defeated`, dialogue win | Oui (scenario test) | NS-GS-12 | Branch condition test |
| Defeat branch | setFlag `fact_rival_lost`, dialogue loss | Oui (scenario test) | NS-GS-12 | Branch condition test |
| `fact_rival_battle_done` posé | Flag present after both branches | Oui (unit) | NS-GS-12 | Vérifié en post-merge |
| Dialogue conditionnel Lysa après battle | `MapEntityConditionalDialogue` route correctement | Oui (predicate test) | NS-GS-10 | conditional dialogue eval |
| Save/load final cohérent | Full state round-trip preserves all flags, party, position | Oui (unit) | NS-GS-12 | game_state_persistence |

---

## 5. Niveaux de tests recommandés

| Niveau | Package | Objectif | Exemple de preuve | Lot concerné |
|---|---|---|---|---|
| **L1 — Unit pur map_core** | `map_core` | Modèles, sérialisation, persistence | PlayerPokemon round-trip, SaveData normalization | NS-GS-05, NS-GS-06 |
| **L2 — Unit pur map_gameplay** | `map_gameplay` | Mutations GameState, predicates NPC | givePokemon mutation, npc presence predicate | NS-GS-06, NS-GS-10 |
| **L3 — Scenario runtime map_runtime** | `map_runtime` | ScenarioRuntimeExecutor, cutscene branching, battle handoff | scenario execute → effect type, dispatchContinuation | NS-GS-08, NS-GS-09, NS-GS-11 |
| **L4 — Save/load integration** | `map_core` + `map_runtime` | Cycle save → reload → état identique | game_state_persistence round-trip avec starter | NS-GS-06, NS-GS-12 |
| **L5 — Battle handoff map_runtime** | `map_runtime` | startTrainerBattle → outcome → flag → continuation | Phase A smoke test pattern extended | NS-GS-11 |
| **L6 — Host smoke playable_runtime_host** | `playable_runtime_host` | Projet Selbrume charge et lance un combat | runtime_host_launch_save pattern | NS-GS-12 |
| **L7 — Validation manuelle** | — | Visuel : map, sprites, dialogues, flow | Vérification humaine du rendu | NS-GS-12 |

---

## 6. Stratégie NS-GS-05 — New Game Minimal Runtime

NS-GS-05 doit prouver que le GameState initial est correct.

| Test futur | Package probable | Assertion | Type |
|---|---|---|---|
| `initial_state_party_empty` | map_core ou map_gameplay | `gameState.party.members.isEmpty == true` | L1 unit |
| `initial_state_map_id` | map_core ou map_gameplay | `gameState.currentMapId == 'map_bourg_selbrume'` | L1 unit |
| `initial_state_bag_empty` | map_core ou map_gameplay | `gameState.bag.entries.isEmpty == true` | L1 unit |
| `initial_state_flags_empty` | map_core ou map_gameplay | `gameState.storyFlags.activeFlags.isEmpty == true` | L1 unit |
| `initial_state_progression_empty` | map_core ou map_gameplay | `gameState.progression.completedStepIds.isEmpty` et `completedCutsceneIds.isEmpty` et `storyFlags.isEmpty` | L1 unit |
| `initial_state_no_consumed_events` | map_core ou map_gameplay | `gameState.consumedEventIds.isEmpty == true` | L1 unit |
| `initial_state_save_load_roundtrip` | map_core | saveData → gameState → saveData identique | L4 integration |

---

## 7. Stratégie NS-GS-06 — GivePokemon Minimal

NS-GS-06 est la **dépendance critique**. Ses tests doivent être les plus solides.

| Test futur | Package probable | Assertion | Bloquant pour NS-GS-12 ? |
|---|---|---|---|
| `give_pokemon_adds_starter` | map_gameplay | Party vide → givePokemon(sproutle, L5) → `party.members.length == 1` | ✅ Oui |
| `give_pokemon_species_correct` | map_gameplay | `party.members[0].speciesId == 'sproutle'` | ✅ Oui |
| `give_pokemon_level_correct` | map_gameplay | `party.members[0].level == 5` | ✅ Oui |
| `give_pokemon_moves_correct` | map_gameplay | `party.members[0].knownMoveIds == ['tackle', 'growl']` | ✅ Oui |
| `give_pokemon_hp_valid` | map_gameplay | `party.members[0].currentHp > 0` | ✅ Oui |
| `give_pokemon_noop_empty_species` | map_gameplay | givePokemon('', L5) → party inchangée ou erreur | ⚠️ Non bloquant mais recommandé |
| `give_pokemon_prevents_duplicate` | map_gameplay | Si `fact_starter_received` posé ou party non vide → pas de redon | ✅ Oui |
| `give_pokemon_save_load` | map_core | Save → reload → party identique avec starter | ✅ Oui |
| `give_pokemon_from_scenario` | map_runtime | ScenarioAsset action GivePokemon → party.members.length == 1 | ✅ Oui |

### Non-objectifs de test NS-GS-06

```text
Pas de test UI riche.
Pas de test choix starter.
Pas de test PC/échange.
Pas de test multi-Pokémon.
Pas de test calcul HP depuis base stats.
```

---

## 8. Stratégie NS-GS-08 — Bourg Selbrume / Maël Content

| Preuve future | Type | Assertion | Notes |
|---|---|---|---|
| `map_bourg_selbrume_loads` | L6 host / L3 runtime | Map charge sans erreur | Smoke test |
| `entity_mael_bourg_exists` | L3 runtime | Entity id present dans map data | Vérifiable par inspection JSON |
| `mael_interaction_triggers_scene` | L3 scenario | entityInteract(map_bourg_selbrume, entity_mael_bourg) → scene_mael_intro exécutée | ScenarioRuntimeExecutor test |
| `scene_mael_calls_give_pokemon` | L3 scenario | scene_mael_intro contient node GivePokemon | Scenario graph test |
| `fact_starter_received_set` | L3 scenario | Après exécution, `storyFlags` contient `fact_starter_received` | setFlag action test |
| `fact_mission_started_set` | L3 scenario | Après exécution, `storyFlags` contient `fact_mission_started` | setFlag action test |
| `mael_no_re_gift` | L3 scenario | Deuxième interaction → pas de givePokemon | Condition anti-redon |
| `mael_encouragement_after_gift` | L3 scenario | Après `fact_starter_received`, interaction → yarn_mael_encouragement | Conditional dialogue |
| `warp_to_port_exists` | L3 runtime ou inspection | entity_exit_to_port present, destination valide | Map JSON inspection |

---

## 9. Stratégie NS-GS-09 — Port Brisants / Lysa Content

| Preuve future | Type | Assertion | Notes |
|---|---|---|---|
| `map_port_brisants_loads` | L6 host / L3 runtime | Map charge sans erreur | Smoke test |
| `entity_lysa_port_exists` | L3 runtime | Entity id present dans map data | JSON inspection |
| `entity_soline_port_exists` | L3 runtime | Entity id present | JSON inspection |
| `lysa_hidden_no_starter` | L2 predicate | NOT `fact_starter_received` → NPC absent | npc_map_presence_predicate pattern |
| `lysa_hidden_no_mission` | L2 predicate | `fact_starter_received` mais NOT `fact_mission_started` → NPC absent | Predicate test |
| `lysa_visible_with_both_facts` | L2 predicate | `fact_starter_received` AND `fact_mission_started` → NPC present | Predicate test |
| `rival_meet_triggers_scene` | L3 scenario | entityInteract → scene_rival_meet exécutée | Scenario test |
| `yarn_rival_intro_outcomes` | L3 scenario | yarn_rival_intro expose `confident`, `hesitant`, `aggressive` | Dialogue outcome test |
| `cinematic_smiles_for_confident` | L3 scenario/cutscene | outcome `confident` → cinematic_rival_smiles | gotoIfOutcome branch test |
| `cinematic_teases_for_hesitant` | L3 scenario/cutscene | outcome `hesitant` → cinematic_rival_teases | gotoIfOutcome branch test |
| `cinematic_teases_for_aggressive` | L3 scenario/cutscene | outcome `aggressive` → cinematic_rival_teases | Same cutscene |

---

## 10. Stratégie NS-GS-10 — Storyline Chapter 1 Wiring

| Preuve future | Type | Assertion | Notes |
|---|---|---|---|
| `storyline_exists` | L3 runtime | `story_main_brume_phare` indexé dans metadata | Chapter runtime test |
| `chapter_1_exists` | L3 runtime | `chapter_1_port` indexé avec steps | Chapter runtime test |
| `steps_exist` | L3 runtime | step_intro_selbrume, step_go_to_port, step_rival_battle indexés | Step completion test |
| `step_completion_via_cutscene_end` | L3 runtime | scene_mael_intro atteint end → step_intro_selbrume complété | step_studio_completion pattern |
| `world_rule_lysa_visibility` | L2 predicate | Predicate évalue correctement avec flags | npc_map_presence_predicate test |
| `world_rule_mael_conditional_dialogue` | L2 predicate | Predicate route dialogue selon flags | Conditional dialogue eval |

> [!WARNING]
> Le runtime actuel supporte principalement `whenCutsceneEnds` pour la completion de steps.
> Si NS-GS-10 veut `whenFlagSet` ou `whenOutcomeEmitted`, il faudra vérifier si un lot intermédiaire (NS-GS-07) est nécessaire.
> En V0, `whenCutsceneEnds` est suffisant si chaque step est lié à un scénario local.

---

## 11. Stratégie NS-GS-11 — Battle Lysa Authoring Fixture

| Preuve future | Type | Assertion | Notes |
|---|---|---|---|
| `trainer_lysa_in_manifest` | L1 unit | `trainer_lysa_port` present dans ProjectManifest.trainers | JSON/model test |
| `trainer_has_team` | L1 unit | team non vide, au moins 1 Pokémon | Trainer validation test |
| `trainer_species_valid` | L1 unit | sparkitten (ou candidat) existe dans species dir | Species lookup |
| `trainer_battle_request_builds` | L5 battle | buildTrainerBattleRequestFromNpc retourne non-null pour trainer_lysa_port | Existing pattern |
| `start_trainer_battle_from_scenario` | L5 battle | ScenarioRuntimeEffectType.battle émis avec battleId=battle_rival_port | Scenario test |
| `battle_outcome_victory_flag` | L5 battle | `battle:battle_rival_port:victory` dans storyFlags après victoire | scenarioBattleOutcomeFlagName test |
| `battle_outcome_defeat_flag` | L5 battle | `battle:battle_rival_port:defeat` dans storyFlags après défaite | scenarioBattleOutcomeFlagName test |
| `scenario_continues_after_battle` | L5 battle | dispatchContinuation reprend le graphe | SEL-B2 pattern |
| `flee_handled` | L5 battle | flee → interdit ou defeat-like selon décision | Décision ouverte §24 NS-GS-03 |

---

## 12. Stratégie NS-GS-12 — Golden Slice Smoke Test

### Golden path victory

| Étape | Action | Assertion |
|---|---|---|
| 1. Initial state | Charger save initiale (party vide) | `party.members.isEmpty`, `currentMapId == 'map_bourg_selbrume'`, `storyFlags.activeFlags.isEmpty` |
| 2. Interact Maël | entityInteract(entity_mael_bourg) | scene_mael_intro exécutée |
| 3. GivePokemon | scene exécute givePokemon | `party.members.length == 1`, `speciesId == starterCandidate` |
| 4. Flags Maël | scene pose flags | `fact_starter_received` et `fact_mission_started` dans storyFlags |
| 5. Save/load mid | Save → reload | Party + flags identiques |
| 6. Warp to Port | Transition map | `currentMapId == 'map_port_brisants'` |
| 7. Lysa visible | Predicate check | Lysa visible car both facts posés |
| 8. Interact Lysa | entityInteract(entity_lysa_port) | scene_rival_meet exécutée |
| 9. Posture choice | yarn_rival_intro → confident | outcome `confident` disponible |
| 10. Cinematic | cinematic_rival_smiles | Branchement correct |
| 11. Battle start | startTrainerBattle | ScenarioRuntimeEffectType.battle, trainerId=trainer_lysa_port |
| 12. Battle plays | Combat joué | BattleOutcome retourné |
| 13. Victory outcome | BattleOutcome.victory | `battle:battle_rival_port:victory` posé |
| 14. Continuation | dispatchContinuation | Graphe reprend, branch victory |
| 15. Victory flags | setFlag | `fact_rival_defeated` et `fact_rival_battle_done` posés |
| 16. Dialogue win | openDialogue | yarn_rival_after_win ouvert |
| 17. Final save/load | Save → reload | Tous flags, party, position preservés |

### Golden path defeat

| Étape | Action | Assertion |
|---|---|---|
| 1–10. | Identique à victory | Mêmes assertions |
| 11. Battle start | startTrainerBattle | Même |
| 12. Battle plays | Combat joué | BattleOutcome retourné |
| 13. Defeat outcome | BattleOutcome.defeat | `battle:battle_rival_port:defeat` posé |
| 14. Continuation | dispatchContinuation | Graphe reprend, branch defeat |
| 15. Defeat flags | setFlag | `fact_rival_lost` et `fact_rival_battle_done` posés |
| 16. Dialogue loss | openDialogue | yarn_rival_after_loss ouvert |
| 17. Final save/load | Save → reload | Tous flags, party, position preservés |

---

## 13. Scénarios de test obligatoires

| ID test | Nom | Niveau | Package | Lot | Bloquant ? |
|---|---|---|---|---|---|
| GS-T01 | `initial_state_party_empty` | L1 | map_core/map_gameplay | NS-GS-05 | ✅ |
| GS-T02 | `give_pokemon_adds_starter` | L2 | map_gameplay | NS-GS-06 | ✅ |
| GS-T03 | `give_pokemon_prevents_duplicate` | L2 | map_gameplay | NS-GS-06 | ✅ |
| GS-T04 | `save_load_starter_received` | L4 | map_core | NS-GS-06 | ✅ |
| GS-T05 | `mael_scene_sets_starter_and_mission_facts` | L3 | map_runtime | NS-GS-08 | ✅ |
| GS-T06 | `lysa_hidden_before_starter` | L2 | map_gameplay | NS-GS-10 | ✅ |
| GS-T07 | `lysa_visible_after_starter_and_mission` | L2 | map_gameplay | NS-GS-10 | ✅ |
| GS-T08 | `rival_intro_outcomes_route_to_cinematics` | L3 | map_runtime | NS-GS-09 | ⚠️ Non bloquant V0 |
| GS-T09 | `start_trainer_battle_from_scene` | L5 | map_runtime | NS-GS-11 | ✅ |
| GS-T10 | `battle_victory_sets_flags_and_continues` | L5 | map_runtime | NS-GS-11/12 | ✅ |
| GS-T11 | `battle_defeat_sets_flags_and_continues` | L5 | map_runtime | NS-GS-11/12 | ✅ |
| GS-T12 | `final_save_load_victory` | L4 | map_core | NS-GS-12 | ✅ |
| GS-T13 | `final_save_load_defeat` | L4 | map_core | NS-GS-12 | ✅ |

---

## 14. Assertions minimales par étape

| Étape du GS | Assertions minimales | Échec bloquant ? |
|---|---|---|
| Initial state | `party.members.isEmpty`, `currentMapId == 'map_bourg_selbrume'`, `storyFlags.activeFlags.isEmpty`, `bag.entries.isEmpty` | ✅ |
| After Maël / starter | `party.members.length == 1`, `party.members[0].speciesId == starterCandidate`, `storyFlags` contient `fact_starter_received` | ✅ |
| After mission | `storyFlags` contient `fact_mission_started` | ✅ |
| After Port arrival | `currentMapId == 'map_port_brisants'` | ✅ |
| Before Lysa interaction | Lysa visible seulement si `fact_starter_received` + `fact_mission_started` | ✅ |
| After rival dialogue posture | outcome ∈ {`confident`, `hesitant`, `aggressive`} | ⚠️ Non bloquant V0 si ShowMessage fallback |
| After battle start | `ScenarioRuntimeEffectType.battle` émis, `battleId == 'battle_rival_port'` | ✅ |
| After battle victory | `battle:battle_rival_port:victory` posé, `fact_rival_defeated` posé, `fact_rival_battle_done` posé | ✅ |
| After battle defeat | `battle:battle_rival_port:defeat` posé, `fact_rival_lost` posé, `fact_rival_battle_done` posé | ✅ |
| After final save/load | State identique après round-trip | ✅ |

---

## 15. Fixtures nécessaires

| Fixture | À créer dans quel lot | Contenu | Utilisée par |
|---|---|---|---|
| `selbrume_initial_save.json` | NS-GS-05 | Party vide, bag vide, map_bourg_selbrume, flags vides | GS-T01, NS-GS-12 |
| `selbrume_after_mael.json` | NS-GS-12 | Party=[starterCandidate L5], fact_starter_received, fact_mission_started | GS-T05, NS-GS-12 |
| `selbrume_after_victory.json` | NS-GS-12 | Party, fact_rival_defeated, fact_rival_battle_done, battle:battle_rival_port:victory | GS-T12, NS-GS-12 |
| `selbrume_after_defeat.json` | NS-GS-12 | Party, fact_rival_lost, fact_rival_battle_done, battle:battle_rival_port:defeat | GS-T13, NS-GS-12 |
| `selbrume_project.json` | NS-GS-08 | ProjectManifest Selbrume avec maps, trainers, pokemon config | NS-GS-08..12 |

> [!IMPORTANT]
> Aucune fixture ne doit être créée dans NS-GS-04.

---

## 16. Tests automatisés vs validation manuelle

### Automatisé obligatoire

| Preuve | Pourquoi | Lot |
|---|---|---|
| GivePokemon mutation | Dépendance critique — party vide → crash combat | NS-GS-06 |
| Save/load starter | Le Pokémon doit survivre un cycle save/reload | NS-GS-06 |
| Battle outcome flags | Flags auto-générés doivent être corrects | NS-GS-11 |
| Scenario continuation | Le graphe doit reprendre après battle | NS-GS-11 |
| World rule Lysa (predicate) | Lysa ne doit pas apparaître sans starter | NS-GS-10 |
| Victory state flags | fact_rival_defeated + fact_rival_battle_done | NS-GS-12 |
| Defeat state flags | fact_rival_lost + fact_rival_battle_done | NS-GS-12 |
| Final save/load round-trip | Tout l'état doit survivre | NS-GS-12 |

### Validation manuelle acceptable en V0

| Preuve | Pourquoi | Lot |
|---|---|---|
| Qualité visuelle de la map | Le rendu visuel ne peut pas être testé par assertion | NS-GS-12 |
| Qualité du dialogue | Le texte placeholder n'a pas besoin d'assertions strictes | NS-GS-08/09 |
| Mise en scène cinematic | ShowMessage + Wait vérifié visuellement | NS-GS-09 |
| Positionnement exact des sprites | Dépend du tileset et du layout visual | NS-GS-08/09 |
| Warp transition fluide | Transition de map visuellement correcte | NS-GS-12 |
| Emotes NPC | Optionnel en V0, hors scope test | post-GS |

---

## 17. Commandes recommandées par package

| Package | Commande future | Lot | Pourquoi |
|---|---|---|---|
| `map_core` | `cd packages/map_core && dart test` | NS-GS-05, NS-GS-06 | Modèles, save/load, sérialisation |
| `map_core` | `cd packages/map_core && dart analyze` | NS-GS-05, NS-GS-06 | Static analysis |
| `map_gameplay` | `cd packages/map_gameplay && dart test` | NS-GS-06 | givePokemon mutation, NPC predicates |
| `map_gameplay` | `cd packages/map_gameplay && dart analyze` | NS-GS-06 | Static analysis |
| `map_runtime` | `cd packages/map_runtime && flutter test` | NS-GS-08, NS-GS-09, NS-GS-11 | Scenario runtime, battle handoff, cutscenes |
| `map_runtime` | `cd packages/map_runtime && flutter analyze` | NS-GS-08, NS-GS-09, NS-GS-11 | Static analysis |
| `playable_runtime_host` | `cd examples/playable_runtime_host && flutter test` | NS-GS-12 | Host launch, Selbrume project |
| `map_battle` | `cd packages/map_battle && dart test` | NS-GS-11 | Battle engine (si modifié) |

> [!NOTE]
> Ces commandes ne doivent PAS être lancées dans NS-GS-04. Elles sont listées pour référence future.

---

## 18. Critères de passage / blocage

| Gate | Conditions de passage | Bloque |
|---|---|---|
| **Gate A** — NS-GS-04 accepted | Stratégie de preuve validée par review | NS-GS-05 |
| **Gate B** — Initial state green | GS-T01 passe (party vide, flags vides, map correcte) | NS-GS-06 |
| **Gate C** — GivePokemon green | GS-T02, GS-T03, GS-T04 passent (mutation + save/load) | NS-GS-08 |
| **Gate D** — Maël content green | GS-T05 passe (scene_mael_intro pose les flags) | NS-GS-09 |
| **Gate E** — Lysa gated green | GS-T06, GS-T07 passent (visibility predicate) | NS-GS-11 |
| **Gate F** — Battle handoff green | GS-T09, GS-T10, GS-T11 passent (battle start + outcome + continuation) | NS-GS-12 |
| **Gate G** — Save/load green | GS-T04, GS-T12, GS-T13 passent (round-trip à chaque étape) | NS-GS-12 |
| **Gate H** — Golden Slice green | Tous les GS-T* passent, les deux chemins (victory + defeat) validés | GS V0 livré |

---

## 19. Matrice de traçabilité inventaire → preuve

| Élément inventaire (NS-GS-03) | Preuve requise | Test ID | Lot validateur |
|---|---|---|---|
| Party initiale vide | Party empty assertion | GS-T01 | NS-GS-05 |
| GivePokemon mutation | Mutation ajoute starter | GS-T02 | NS-GS-06 |
| Anti-doublon starter | Pas de redon | GS-T03 | NS-GS-06 |
| `fact_starter_received` | Flag posé après don | GS-T05 | NS-GS-08 |
| `fact_mission_started` | Flag posé après mission | GS-T05 | NS-GS-08 |
| scene_mael_intro | Scénario exécuté | GS-T05 | NS-GS-08 |
| Lysa world rule | Predicate bloque/autorise | GS-T06 + GS-T07 | NS-GS-10 |
| `yarn_rival_intro` outcomes | 3 outcomes routés | GS-T08 | NS-GS-09 |
| `cinematic_rival_smiles` | Branch confident | GS-T08 | NS-GS-09 |
| `cinematic_rival_teases` | Branch hesitant/aggressive | GS-T08 | NS-GS-09 |
| `trainer_lysa_port` | Trainer résolvable | GS-T09 | NS-GS-11 |
| `battle_rival_port` | Battle lance et produit outcome | GS-T10 + GS-T11 | NS-GS-11 |
| Victory branch | Flags victory posés | GS-T10 | NS-GS-12 |
| Defeat branch | Flags defeat posés | GS-T11 | NS-GS-12 |
| Save/load victory | Round-trip preserves | GS-T12 | NS-GS-12 |
| Save/load defeat | Round-trip preserves | GS-T13 | NS-GS-12 |

---

## 20. Risques et garde-fous

| Risque | Impact | Garde-fou test | Lot |
|---|---|---|---|
| Faux positif smoke test (fixture magique) | Fort — GS semble vert mais ne fonctionne pas | Utiliser fixtures construites par le pipeline, pas pré-remplies | NS-GS-12 |
| GivePokemon fonctionne en unit mais pas via ScenarioAsset | Fort — mutation OK mais pas câblée | Test L3 : exécuter scene_mael_intro et vérifier party | NS-GS-08 |
| Starter donné deux fois | Moyen — Pokémon dupliqué | GS-T03 : anti-doublon explicite | NS-GS-06 |
| Starter perdu au reload | Fort — progression perdue | GS-T04 : save → reload → party identique | NS-GS-06 |
| Lysa accessible sans starter | Fort — combat avec party vide | GS-T06 : predicate bloque sans fact_starter_received | NS-GS-10 |
| Outcome rival ignoré | Moyen — cinematic incorrecte | GS-T08 : vérifier routing | NS-GS-09 |
| Battle outcome flag posé mais scenario non continué | Fort — jeu bloqué | GS-T10/T11 : vérifier dispatchContinuation | NS-GS-11 |
| Defeat path non testé | Fort — seul victory vérifié | GS-T11 + GS-T13 : chemins victory ET defeat | NS-GS-12 |
| Victory path seulement testé | Fort — defeat pourrait crasher | Deux golden paths obligatoires | NS-GS-12 |
| Fixtures trop magiques | Moyen — contournent le pipeline | Construire les fixtures étape par étape | NS-GS-12 |
| Validation manuelle trop large | Moyen — faux positif humain | Limiter au visuel ; automatiser la logique | NS-GS-12 |

---

## 21. Hors scope de la stratégie V0

```text
Choix complet de starter (3 starters, UI sélection)
Test e2e graphique complet (screenshot comparison)
Validation esthétique des maps (tileset, décor)
Boss phare
Wild encounters
XP / level-up avancé
PC / shop / heal center
Capture
Quêtes annexes
Validator narratif complet
UI starter selection overlay
Pokédex complet
Évolutions
Badges
Money / économie
Field moves
Test de performance / frame rate
Test multi-plateforme (iOS, Android, Web)
```

---

## 22. Recommandation finale

```text
NS-GS-04 ne crée rien.
NS-GS-04 fixe le contrat de preuve du Golden Slice Selbrume V0.

13 scénarios de test sont définis (GS-T01 à GS-T13).
8 gates de passage sont définies (Gate A à Gate H).
7 niveaux de tests sont recommandés (L1 à L7).
2 golden paths sont documentés (victory + defeat).
19 maillons du pipeline sont tracés.

Après review, on peut passer à NS-GS-05 — New Game Minimal Runtime.
NS-GS-05 doit respecter Gate B (initial state green).
NS-GS-04 ne code pas NS-GS-05.
```

---

## 23. Evidence Pack

### Git status initial

```bash
$ git status --short --untracked-files=all
(working tree propre — aucune modification non rapportée)
```

### Fichier créé

```text
reports/gameplay/ns_gs_04_runtime_smoke_strategy.md
```

### Tests existants repérés

```text
packages/map_gameplay/test/game_state_mutations_test.dart (giveItem tests — patron pour givePokemon)
packages/map_core/test/game_state_persistence_test.dart (save/load round-trip)
packages/map_core/test/save_data_test.dart (PlayerPokemon, PlayerParty sérialisation)
packages/map_core/test/scenario_assets_test.dart (ScenarioAsset validation)
packages/map_runtime/test/scenario_conditions_test.dart (conditions)
packages/map_runtime/test/trainer_battle_request_test.dart (battle request builder)
packages/map_runtime/test/trainer_defeated_test.dart (defeated flag)
packages/map_runtime/test/runtime_battle_outcome_apply_test.dart (battle outcome)
packages/map_runtime/test/cutscene_runtime_runner_test.dart (cutscene branching)
packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart (Phase A smoke)
packages/map_runtime/test/step_studio_completion_runtime_test.dart (step completion)
packages/map_runtime/test/step_studio_world_presence_runtime_test.dart (NPC presence)
packages/map_gameplay/test/npc_map_presence_predicate_test.dart (NPC predicate)
examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart (host launch)
```

### Git status/diff final

```bash
$ git diff --check
(sortie vide — pas de whitespace errors)
EXIT:0

$ git diff --stat
(sortie vide — le fichier est untracked, pas staged)

$ git diff --name-only
(sortie vide — pas de fichier tracked modifié)

$ git status --short --untracked-files=all
?? reports/gameplay/ns_gs_04_runtime_smoke_strategy.md
```

### Confirmations

```text
Un seul fichier créé : reports/gameplay/ns_gs_04_runtime_smoke_strategy.md
Aucun code modifié.
Aucune fixture modifiée.
Aucun test modifié.
Aucun build_runner lancé.
Aucune opération Git d'écriture effectuée.
```

---

## 24. Auto-review

| Question | Réponse |
|---|---|
| Le rapport définit-il comment prouver le Golden Slice ? | ✅ 13 tests, 8 gates, 2 golden paths, 19 maillons tracés |
| Le lot reste-t-il documentaire ? | ✅ Un seul fichier MD créé, aucun code |
| Maël est-il bien PNJ et non joueur ? | ✅ Vocabulaire strict, pas de confusion |
| GivePokemon est-il testé comme dépendance obligatoire ? | ✅ GS-T02/T03/T04 + Gate C |
| La party initiale vide est-elle testée ? | ✅ GS-T01 + Gate B |
| Lysa est-elle conditionnée à fact_starter_received + fact_mission_started ? | ✅ GS-T06/T07 + Gate E |
| Les outcomes rival sont-ils testés ? | ✅ GS-T08 |
| Victory et defeat sont-ils tous deux testés ? | ✅ GS-T10/T11 + GS-T12/T13 + 2 golden paths |
| Save/load est-il testé aux bons endroits ? | ✅ Après starter (GS-T04), après victory (GS-T12), après defeat (GS-T13) |
| NS-GS-05 sait-il quoi faire ensuite ? | ✅ Gate B définie, tests futurs listés (§6) |
| Y a-t-il une dette restante ? | ⚠️ GS-T08 (outcomes posture) non bloquant V0. Décision ouverte flee. |

---

*Fin du document NS-GS-04.*
