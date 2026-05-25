# PokeMap Beta Readiness Audit

## 1. Executive summary

Verdict global: PokeMap n'est pas beta-ready.

Readiness approximative: environ 40%. Le socle technique est substantiel
(modeles de projet, GameState, runtime Flame, battle handoff, scenarios,
save/load fichier, editeur de trainers/encounters/dialogues), mais la boucle
beta attendue n'est pas prouvee de bout en bout:

`editeur -> disque -> runtime -> New Game -> exploration -> narrative -> battle -> rewards -> save/load`.

Principaux bloqueurs:

- New Game runtime absent: le host part d'une launch save, d'un seed demo ou
  d'une fixture, pas d'un flux New Game issu du projet.
- Etat initial incomplet: starter, bag de depart, argent, flags/steps initiaux
  et metadata ne sont pas pilotes par le manifest.
- Combat incomplet pour beta: pas de XP, level-up, reward contract, money,
  badges, PP/status write-back, ni PC/box pour capture pleine.
- Heal center absent: pas de `healParty`, pas de commande runtime de soin, pas
  de feedback ni de preuve save/load apres soin.
- Audio runtime absent: quelques champs metadata existent, mais pas de service
  audio, catalogue, BGM/SFX, volume/mute ou validation de fichiers.
- Validator de jouabilite absent: il existe des validateurs techniques et
  narratifs, mais pas un validator beta unique qui prouve un projet jouable.
- Golden Slice Selbrume non assemble: les documents existent, les fixtures
  runtime sont techniques/non-Selbrume.

Ce qui est solide:

- `GameState`, `SaveData`, party, bag, progression, flags et consumed events ont
  une base reelle dans `packages/map_core`.
- `map_gameplay` porte des operations pures utiles: movement, interactions,
  encounters pull-based et mutations `givePokemon`, `giveItem`, `completeStep`.
- `map_runtime` charge des projets disque, execute des scenarios, fait le
  battle handoff et applique certains resultats de combat.
- `map_battle` a un moteur teste pour victoire, defaite, fuite et capture
  minimale.
- `map_editor` sait creer/configurer trainers, encounter tables, dialogues,
  cutscenes et parties de la carte, mais pas encore en workflow beta no-code
  complet.

Ce qui est trompeur ou seulement partiel:

- Une classe existe ne prouve pas le flux beta: exemple `PlayerPokemon.level`
  existe, mais XP/level-up n'existent pas.
- Une fixture runtime existe ne prouve pas un projet cree par l'editeur.
- `musicId` et `battleThemeId` existent, mais aucun son n'est joue.
- `SaveData` et `FileGameSaveRepository` existent, mais certains chemins
  runtime restent non transactionnels ou non persistants automatiquement.
- Les roadmaps Phase 3 disent souvent "fixture technique non-Selbrume"; cela ne
  doit pas etre lu comme Selbrume jouable.

## 2. Methodology

Date: 2026-05-25.

Commit courant observe: `3ee7abf7 Ajoute P4-04 : Outcome/Battle Outcome Authoring Operations (code, tests et rapport)`.

Working tree initial avant creation des rapports:

```text
 M "MVP Selbrume/road_map_phase_4.md"
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/authoring/narrative_predicate_authoring_draft.dart
?? packages/map_core/test/narrative_predicate_authoring_draft_test.dart
```

Checklist source trouvee:

- `MVP Selbrume/checklist_beta_pokemap.md`

Roadmap mecanique lue:

- `pokemap_roadmap_mecaniques_fangame.md`

Passes utilisees:

- Passe A, orchestrateur beta: lecture checklist, grille de statut, synthese.
- Passe B, sub-agent Core data / manifest / GameState.
- Passe C, sub-agent Gameplay overworld.
- Passe D, sub-agent Runtime Flame.
- Passe E, sub-agent Editor / authoring no-code.
- Passe F, sub-agent Battle / capture / rewards / XP.
- Passe G, sub-agent Audio.
- Passe H, locale: Save/Load + Validator.
- Passe I, locale: Golden Slice Selbrume.

Limites de l'audit:

- Audit static + tests cibles. Pas de tests manuels interactifs dans l'app.
- Pas de `dart analyze` / `flutter analyze`: aucun code produit n'a ete modifie
  et les checks complets auraient depasse le besoin d'un audit cible.
- Pas de build_runner, conformement au prompt.
- Les sous-agents n'ont pas execute de tests; les tests cibles ont ete executes
  ensuite par l'orchestrateur.
- Les statuts donnent priorite au code et aux tests actuels, pas aux
  affirmations de rapports anciens.

## 3. Status matrix

| Bloc | Item | Statut | Confiance | Preuves | Bloquant beta ? | Notes |
|---|---|---|---|---|---|---|
| 1 Runtime | playable_runtime_host / runtime Flame existe | DONE | High | `examples/playable_runtime_host`, `PlayableMapGame`, `RuntimeMapGame`; `phase_a_golden_slice_launch_test.dart` | Non | Runtime reel existe. |
| 1 Runtime | battle handoff/runtime deja present en partie | DONE | High | `RuntimeBattleSetupMapper`, `_openBattleOverlay`, `phase_a_golden_battle_slice_smoke_test.dart`, `wild_battle_end_to_end_flow_test.dart` | Non | Handoff prouve pour slice technique; progression reste partielle. |
| 1 Runtime | charger un vrai projet disque cree par l'editeur | PARTIAL | High | `loadRuntimeMapBundle`, `ProjectRepository.saveProject`, `runtime_project_picker.dart` | Oui | Pas de smoke editeur -> projet disque -> host. |
| 1 Runtime | lancer une New Game depuis ce projet | MISSING | High | `createNewGameState` existe en gameplay; host utilise launch save/demo seed | Oui | Pas d'ecran/flow runtime New Game. |
| 1 Runtime | smoke test editeur -> disque -> runtime -> save/load | MISSING | High | Tests techniques existants, aucun smoke complet trouve | Oui | Test cle de beta. |
| 2 New Game | GameState existe avec plusieurs briques | DONE | High | `game_state.dart`, `save_data.dart`, `game_state_persistence_test.dart` | Non | Modele reel mais incomplet beta. |
| 2 New Game | ecran ou flow New Game minimal | MISSING | High | Host `main.dart`, `runtime_demo_party_seed.dart` | Oui | Pas de flow utilisateur. |
| 2 New Game | map de depart + spawn valides | PARTIAL | High | `resolveInitialPlayerSpawn`, `GameplayWorldState.fromMap` | Oui | Runtime fallback `(0,0)` si spawn invalide; pas de validator beta. |
| 2 New Game | donner un Pokemon initial / starter | PARTIAL | High | `GameStateMutations.givePokemon`, scenario action `givePokemon`, tests `give_pokemon_test.dart` | Oui | Pas de starter model/selection/runtime flow. |
| 2 New Game | initialiser bag, argent, flags, steps, metadata | PARTIAL | High | `createNewGameState` cree etats vides; `TrainerProfile.money` existe | Oui | Pas de config manifest initiale. |
| 3 Exploration | deplacement / collisions / warps | PARTIAL | High | `stepGameplayWorld`, `WarpTriggered`, runtime movement tests | Oui | Solide mais pas prouve sur Selbrume ni smoke complet. |
| 3 Exploration | interactions runtime | PARTIAL | High | `NpcInteracted`, `SignInteracted`, `ItemInteracted`, runtime callbacks | Oui | Map events pas tous branches dans pure gameplay. |
| 3 Exploration | interaction PNJ de bout en bout | PARTIAL | High | Scenario runtime, dialogue tests, NPC runtime UI | Oui | Pas de PNJ Selbrume complet. |
| 3 Exploration | interaction objet / pickup | PARTIAL | High | `giveItem`, `item_pickup_give_item_readiness_test.dart`, entity item UI | Oui | Pas de pickup beta e2e avec persistence/feedback. |
| 3 Exploration | transitions map stables | PARTIAL | Medium | Warps/connections dans gameplay/runtime | Oui | Tests pur gameplay limites; load/save position a durcir. |
| 3 Exploration | test Selbrume exploration complet | MISSING | High | Recherche Selbrume: docs seulement | Oui | Aucun projet Selbrume jouable trouve. |
| 4 Narrative | modele produit Narrative Studio | PARTIAL | High | `ScenarioAsset`, `ProjectDialogueEntry`, `NarrativeWorkspaceCanvas` | Oui | Modele/authoring existent; UX et e2e incomplets. |
| 4 Narrative | Event -> Scene -> Dialogue -> Outcome -> Fact/Step | PARTIAL | High | `ScenarioRuntimeExecutor`, `emitOutcome`, `completeStep`, P3 tests | Oui | Choice nodes et plusieurs commandes restent hors runtime. |
| 4 Narrative | world rules visibles en runtime | PARTIAL | High | P3 fact/world rule projection tests, `MapEntityRuntimePredicate` | Oui | Projection prouvee sur fixture technique, pas beta Selbrume. |
| 4 Narrative | dialogue conditionnel apres progression | PARTIAL | High | `ScriptConditionEvaluator`, conditional dialogue authoring draft | Oui | Pas de parcours beta complet. |
| 4 Narrative | persistance events/scenes consommes | PARTIAL | High | `consumedEventIds`, `completedCutsceneIds`, file save tests | Oui | Persistance existe; consumption e2e pas complet partout. |
| 5 Party | party dans GameState | DONE | High | `GameState.party`, `PlayerParty`, `game_state_persistence_test.dart` | Non | Base reelle. |
| 5 Party | menu equipe runtime minimal | PARTIAL | Medium | `in_game_menu` host tests, runtime menu components | Oui | Read-only/minimal; pas beta UX complete. |
| 5 Party | afficher PV / niveau / statut | PARTIAL | Medium | `PlayerPokemon.currentHp`, `level`, `statusId`, menu runtime | Oui | Pas de max HP persiste, statut peu branche. |
| 5 Party | gerer KO | PARTIAL | High | Battle outcome, `applyRuntimeDefeatRecoveryToGameState` | Oui | Whiteout-lite seulement, pas centre soin. |
| 5 Party | mise a jour equipe apres combat | PARTIAL | High | `runtime_battle_outcome_apply.dart`, tests runtime | Oui | HP/capture oui; PP/status/XP non. |
| 5 Party | persistance save/load | DONE | High | `file_game_save_repository_test.dart` | Non | Party preservee via GameState JSON. |
| 6 Bag | bag dans GameState | DONE | High | `GameState.bag`, `Bag`, `BagEntry` | Non | Base reelle. |
| 6 Bag | bag runtime minimal | PARTIAL | Medium | In-game menu/battle bag tests indirects | Oui | Overworld bag menu FG-061 reste a faire. |
| 6 Bag | utiliser potion | PARTIAL | High | Battle bag HP heal tests in `map_battle` | Oui | Hors combat non prouve. |
| 6 Bag | utiliser Poke Ball en combat | PARTIAL | High | `allowCapture`, capture choice, ball consumption runtime | Oui | Capture auto-success, no PC/box. |
| 6 Bag | ramasser item sur map | PARTIAL | High | `giveItem`, pickup readiness test, item entity UI | Oui | Feedback/persistence e2e beta incomplets. |
| 6 Bag | persistance save/load | DONE | High | `file_game_save_repository_test.dart` | Non | Bag preserve. |
| 7 Heal | healParty | MISSING | High | `rg healParty` sans implementation utile | Oui | Lot FG-071 requis. |
| 7 Heal | restaurer PV | MISSING | High | Pas de mutation healParty; potions/whiteout ne suffisent pas | Oui | |
| 7 Heal | restaurer PP si geres | NOT_APPLICABLE_FOR_BETA | Medium | PP non persiste dans `PlayerPokemon` actuel | Non | Si PP entre en beta, devient MISSING. |
| 7 Heal | retirer statuts | MISSING | High | `statusId` existe, pas de soin global | Oui | |
| 7 Heal | reanimer KO | MISSING | High | Whiteout-lite met un slot a 1 HP, pas un centre soin | Oui | |
| 7 Heal | appel depuis dialogue infirmiere / lit / point de soin | MISSING | High | Aucun script action heal trouve | Oui | |
| 7 Heal | feedback simple | MISSING | High | Aucun flow heal runtime | Oui | |
| 7 Heal | persistance apres save/load | MISSING | High | Pas de soin a persister | Oui | |
| 8 Wild encounters | zones de rencontre | PARTIAL | High | `EncounterZonePayload`, gameplay zones | Oui | Model/runtime existent, beta validation incomplete. |
| 8 Wild encounters | encounter tables | PARTIAL | High | `ProjectEncounterTable`, editor panel, use case tests | Oui | Species/moves validation incomplete. |
| 8 Wild encounters | declenchement runtime | PARTIAL | High | `_checkStepEncounter`, `checkEncounterAtPlayerPosition` | Oui | Pull-based; not full beta conditions. |
| 8 Wild encounters | hautes herbes / zones | PARTIAL | Medium | Zones/kinds exist | Oui | Terrain/grass semantics limited. |
| 8 Wild encounters | retour runtime apres combat | PARTIAL | High | `_onBattleFinished` resumes overworld | Oui | Rewards/persistence incomplete. |
| 8 Wild encounters | validation species/niveaux/moves | PARTIAL | Medium | Table validates ranges/weights; Pokemon validators exist | Oui | No holistic cross-validator. |
| 9 Wild battle | moteur battle | DONE | High | `packages/map_battle`, `battle_session_test.dart` | Non | Engine covered by targeted tests. |
| 9 Wild battle | wild battle | PARTIAL | High | `WildBattleStartRequest`, runtime mapper, e2e tests | Oui | Beta progression/capture formula absent. |
| 9 Wild battle | branchement runtime final | PARTIAL | High | `_openBattleOverlay`, `wild_battle_end_to_end_flow_test.dart` | Oui | "Final" false: rewards/PP/status/audio missing. |
| 9 Wild battle | resultat exploitable | PARTIAL | High | `BattleOutcome`, `applyRuntimeBattleOutcomeToGameState` | Oui | Outcome payload too small for beta rewards/XP. |
| 9 Wild battle | PV/statuts/PP ecrits dans GameState | PARTIAL | High | HP write-back tests; comment says PP/status not implemented | Oui | HP only is not enough. |
| 9 Wild battle | fuite minimale ou comportement defini | DONE | High | `BattleOutcomeType.runaway`, wild run tests | Non | Simple immediate run behavior. |
| 10 Capture | capture depuis combat sauvage | PARTIAL | High | Capture choice + runtime outcome apply tests | Oui | Auto-success, no formula. |
| 10 Capture | ajout equipe si place disponible | DONE | High | `runtime_battle_outcome_apply_test.dart`, `wild_battle_end_to_end_flow_test.dart` | Non | Works only when party has room. |
| 10 Capture | equipe pleine | PARTIAL | High | Runtime disables/rejects capture when party full | Oui | Safe rejection, not player-friendly fallback. |
| 10 Capture | PC/box minimal ou fallback | MISSING | High | No box model found; FG-022/025 TODO area | Oui | Capture full-party beta blocker. |
| 10 Capture | persistance Pokemon capture | DONE | High | File save repository captured wild persistence tests | Non | Captured in party persists. |
| 11 Trainer battle | creer dresseur sans code | PARTIAL | High | `TrainerLibraryPanel`, `trainer_use_cases_test.dart` | Oui | Some raw refs remain. |
| 11 Trainer battle | placer dresseur sur map | PARTIAL | High | NPC/entity editor and trainer refs | Oui | End-to-end authoring-to-runtime not complete. |
| 11 Trainer battle | declencher combat | PARTIAL | High | `trainerBattleRequestFromNpc`, `_triggerTrainerBattle`, tests | Oui | Needs beta smoke from no-code map. |
| 11 Trainer battle | victoire/defaite | PARTIAL | High | `BattleOutcomeType`, runtime battle tests | Oui | No reward/XP/whiteout policy beta. |
| 11 Trainer battle | marquer dresseur battu | DONE | High | `StoryFlagsManager`, runtime outcome apply tests | Non | Convention flag, not typed registry. |
| 11 Trainer battle | dialogue different apres combat | PARTIAL | High | Conditions/predicates and post-battle flag | Oui | Hook not beta-proven in Selbrume. |
| 12 Rewards | recompense apres combat | MISSING | High | `reward_bridge_readiness_test` is scenario reward, not battle reward | Oui | No formal `BattleReward`. |
| 12 Rewards | argent ou item minimal | MISSING | High | `TrainerProfile.money` stores money; battle does not mutate it | Oui | Items can be scenario-given only. |
| 12 Rewards | XP minimale | MISSING | High | No experience field in `PlayerPokemon` | Oui | FG-044 required. |
| 12 Rewards | level-up minimal | MISSING | High | Level stored, no XP/level-up apply path | Oui | FG-045 required. |
| 12 Rewards | persistance niveau / XP | MISSING | High | Level persists; XP absent | Oui | Cannot persist absent XP. |
| 12 Rewards | feedback post-combat | MISSING | High | No reward presentation path | Oui | FG-048 required. |
| 13 Audio | catalogue audio minimal | MISSING | High | No `AudioCatalog`; only metadata/source assets | Oui | |
| 13 Audio | musique de map | PARTIAL | High | `MapMetadata.musicId`, editor field, validator nonblank | Oui | No runtime playback. |
| 13 Audio | musique de combat | PARTIAL | High | `battleThemeId`, `victoryThemeId` on trainers | Oui | No runtime playback. |
| 13 Audio | SFX menu / validation | MISSING | High | No audio dependency/service | Oui | |
| 13 Audio | SFX dialogue / interaction | MISSING | High | No SFX hooks | Oui | |
| 13 Audio | SFX combat basique | MISSING | High | RMXP `seName` imported but not played | Oui | |
| 13 Audio | SFX capture | MISSING | High | No capture SFX hook | Oui | |
| 13 Audio | SFX soin equipe | MISSING | High | Heal flow absent | Oui | |
| 13 Audio | volume musique / effets / mute | MISSING | High | `ProjectSettings` has no audio settings | Oui | |
| 13 Audio | validator fichiers audio manquants | MISSING | High | No audio asset resolver/validator | Oui | |
| 14 Save/Load | sauvegarder position + map courante | DONE | High | `FileGameSaveRepository`, runtime save tests | Non | Startup use of launch save position has caveat. |
| 14 Save/Load | sauvegarder party | DONE | High | `file_game_save_repository_test.dart` | Non | |
| 14 Save/Load | sauvegarder bag | DONE | High | `file_game_save_repository_test.dart` | Non | |
| 14 Save/Load | sauvegarder story flags / facts / steps | PARTIAL | High | `storyFlags`, `completedStepIds`, script variables in GameState JSON | Oui | "Facts" not typed; legacy `SaveData` path loses some fields. |
| 14 Save/Load | sauvegarder trainers battus | DONE | High | Trainer defeated flag tests | Non | Convention-based. |
| 14 Save/Load | sauvegarder cutscenes/events consommes | PARTIAL | High | `completedCutsceneIds`, `consumedEventIds`, file save tests | Oui | Not all consumption flows beta-proven. |
| 14 Save/Load | recharger et retrouver un etat coherent | PARTIAL | High | `p3_save_load_narrative_state_roundtrip_test.dart`, file repo tests | Oui | Runtime `loadGame` non-transactional; no full beta smoke. |
| 15 Validator | validator projet jouable | MISSING | High | No holistic playable validator found | Oui | Central beta blocker. |
| 15 Validator | start map / spawn | PARTIAL | High | Spawn resolver and map validation | Oui | Not aggregated into playability report. |
| 15 Validator | warps | PARTIAL | Medium | Map validators/use cases exist | Oui | No beta route graph proof. |
| 15 Validator | PNJ references | PARTIAL | High | `diagnoseNarrativeProject`, entity/trainer/dialogue checks | Oui | Not complete project-level gate. |
| 15 Validator | dialogues/scenes/outcomes | PARTIAL | High | `narrative_validator_test.dart` | Oui | Not full runtime reachability. |
| 15 Validator | battles/trainers | PARTIAL | High | Trainer validation exists | Oui | No rewards/XP/audio coverage. |
| 15 Validator | species/moves/items | PARTIAL | Medium | Pokemon project validators and encounter validations | Oui | Not wired into one beta validator/editor surface. |
| 15 Validator | assets manquants | PARTIAL | Medium | Relative path checks and imports exist | Oui | Not all runtime assets proven. |
| 15 Validator | audio manquant | MISSING | High | No audio catalog/runtime | Oui | |
| 15 Validator | save/load compatible | PARTIAL | Medium | Save tests exist; no validator rule | Oui | Need schema/compat gate. |
| 16 Selbrume | concept Selbrume | DONE | High | `MVP Selbrume/selbrume.md`, roadmaps | Non | Concept only. |
| 16 Selbrume | slice cible | DONE | High | `MVP Selbrume/road_map_global.md`, checklist | Non | Target documented. |
| 16 Selbrume | roadmap narrative / golden slice | DONE | High | Phase 1-4 roadmaps and reports | Non | Roadmap exists. |
| 16 Selbrume | projet exemple jouable 10-20 minutes | MISSING | High | Project JSON files are technical/non-Selbrume | Oui | No real Selbrume project found. |
| 16 Selbrume | Bourg / Port jouables | MISSING | High | `rg` found docs, no playable maps | Oui | |
| 16 Selbrume | Mael fonctionnel | MISSING | High | No runtime Selbrume fixture | Oui | |
| 16 Selbrume | Lysa fonctionnelle | MISSING | High | No runtime Selbrume fixture | Oui | |
| 16 Selbrume | combat rival | MISSING | High | Battle fixtures are generic/golden technical | Oui | |
| 16 Selbrume | victory/defeat branch | PARTIAL | Medium | Scenario battle continuation fixture exists, not Selbrume | Oui | |
| 16 Selbrume | fact + step + world rule | PARTIAL | Medium | P3 fact/world rule fixture exists, not Selbrume | Oui | |
| 16 Selbrume | soin equipe quelque part | MISSING | High | Heal flow absent | Oui | |
| 16 Selbrume | audio minimal | MISSING | High | Audio runtime absent | Oui | |
| 16 Selbrume | save/reload final | PARTIAL | Medium | Technical P3 save/load exists | Oui | Not final Selbrume. |
| 16 Selbrume | validator vert | MISSING | High | No beta validator, no Selbrume project | Oui | |

## 4. Detailed audit by bloc

### Bloc 1. Runtime / lancement du jeu

Etat actuel: runtime Flame et host existent. `loadRuntimeMapBundle` charge
`project.json`, maps et tilesets depuis disque. Le host possede un picker de
projet et des launch saves. Le battle handoff est reel et teste.

Preuves code:

- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `examples/playable_runtime_host/lib/src/runtime_project_picker.dart`
- `examples/playable_runtime_host/lib/src/runtime_launch_save.dart`

Tests existants et lances:

- `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`

Trous exacts:

- Pas de flow New Game runtime.
- Pas de smoke editeur -> disque -> runtime -> save/load.
- La launch save n'est pas encore une verite de demarrage parfaite: la passe
  Runtime a releve que le host charge une map selectionnee avant la launch save
  et que `onLoad` peut ecraser la position par le spawn.

Recommandation: commencer par un smoke de projet cree par l'editeur, puis
durcir le demarrage New Game/start map/spawn avant d'ajouter des features.

### Bloc 2. New Game / etat initial

Etat actuel: `GameState` et `createNewGameState` existent, mais le builder
initialise surtout un etat vide. Les actions `givePokemon`, `giveItem` et
`completeStep` peuvent construire un etat initial via scenario, mais il manque
le produit "New Game".

Preuves code:

- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_gameplay/lib/src/new_game_state_builder.dart`
- `packages/map_gameplay/lib/src/game_state_mutations.dart`

Tests:

- `packages/map_gameplay/test/give_pokemon_test.dart`
- `packages/map_gameplay/test/complete_step_test.dart`

Trous:

- Pas de config manifest pour starter/start bag/start flags.
- Pas d'ecran runtime New Game.
- Pas de selection starter.
- Pas de validation beta du spawn obligatoire.

Recommandation: lots FG-011, FG-012, FG-013 et une regle validator start
map/spawn.

### Bloc 3. Exploration

Etat actuel: la base exploration est presente: mouvements, collisions, warps,
connections et interactions. Les zones d'encounter sont decouplees et appelees
par le runtime. L'editeur permet de placer des entites.

Preuves:

- `packages/map_gameplay/lib/src/gameplay_step.dart`
- `packages/map_gameplay/lib/src/gameplay_step_result.dart`
- `packages/map_gameplay/lib/src/gameplay_encounter.dart`
- `packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart`

Trous:

- `MapEventInteracted` existe mais tous les `map.events` ne sont pas produits
  par `stepGameplayWorld`.
- Les effects de movement et certains trigger/custom scripts restent limites.
- Pas de test Selbrume exploration.

Recommandation: verrouiller un trajet beta minimal, pas toute la parite RPG.

### Bloc 4. Narrative / events / scenes

Etat actuel: le domaine narrative est avance. `ScenarioAsset` porte le graphe,
`ScenarioRuntimeExecutor` execute un golden path, les outcomes peuvent produire
flags/steps et lancer des combats. L'editeur a Dialogue Studio, Step Studio et
Cutscene Studio.

Preuves:

- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime_executor.dart`
- `packages/map_core/lib/src/validation/narrative_validator.dart`
- `packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cutscene_studio`

Tests:

- `packages/map_runtime/test/p3_scenario_runtime_golden_path_test.dart`
- `packages/map_runtime/test/p3_save_load_narrative_state_roundtrip_test.dart`
- `packages/map_core/test/narrative_validator_test.dart`
- `packages/map_editor/test/dialogue_editor_validation_test.dart`
- `packages/map_editor/test/cutscene_studio_authoring_test.dart`

Trous:

- Certains nodes/blocks restent placeholders ou raw/script-like.
- Choice nodes runtime non supportes dans le perimetre observe.
- La persistence de consumed events existe, mais pas encore prouvee dans le
  parcours Selbrume complet.

Recommandation: figer le sous-ensemble narrative beta et le valider par
scenario Selbrume, plutot que poursuivre l'expansion authoring.

### Bloc 5. Party / equipe

Etat actuel: party et PlayerPokemon existent et persistent. Le runtime ecrit
les HP apres combat, peut ajouter une capture et gere une defaite minimale.

Preuves:

- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`
- `packages/map_runtime/test/file_game_save_repository_test.dart`

Trous:

- Pas de `maxHp` persiste dans `PlayerPokemon`.
- Pas d'XP/current experience.
- Pas de PP write-back.
- Pas de status write-back complet.
- Pas de PC/boxes.

Recommandation: completer juste le contrat de persistance minimum requis par
combat, capture et heal, sans chercher la parite Pokemon complete.

### Bloc 6. Bag / inventaire

Etat actuel: bag model et persistence sont presents. Les battle items peuvent
soigner en combat. `giveItem` fournit une base pickup/reward.

Preuves:

- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_gameplay/lib/src/game_state_mutations.dart`
- `packages/map_battle/test/battle_session_test.dart`
- `packages/map_runtime/test/item_pickup_give_item_readiness_test.dart`

Trous:

- Overworld bag menu non termine.
- Potion hors combat non prouvee.
- Item pickup no-code encore raw ID.
- Pas de registry d'effets item beta.

Recommandation: implementer un petit registry d'effets beta et un menu bag
minimal avant de multiplier les items.

### Bloc 7. Soin equipe / Centre Pokemon

Etat actuel: absent. Les potions en combat et le whiteout-lite ne remplacent pas
un soin d'equipe.

Preuves:

- `rg healParty` n'a pas trouve d'implementation utile.
- `PlayerPokemon.statusId` existe mais aucun flow de soin global.

Trous:

- `healParty`.
- Commande scenario/dialogue pour soin.
- Point de soin map.
- Feedback.
- Test save/reload apres soin.

Recommandation: lot beta dedie, petit mais bloquant.

### Bloc 8. Rencontres sauvages

Etat actuel: encounter tables, zones et runtime trigger existent. L'editeur peut
creer des tables et les zones peuvent pointer vers une table.

Preuves:

- `packages/map_core/lib/src/models/project_encounter_table.dart`
- `packages/map_core/lib/src/models/map_gameplay_zone_payloads.dart`
- `packages/map_gameplay/lib/src/gameplay_encounter.dart`
- `packages/map_editor/test/encounter_table_use_cases_test.dart`

Trous:

- Conditions d'encounter limitees.
- Validation species/moves/items non centralisee.
- Pas de repel/cooldown/consumed encounters/static encounter beta.

Recommandation: viser rencontre herbe simple + validation stricte, repousser
fishing/headbutt/repel si non necessaires a Selbrume.

### Bloc 9. Combat sauvage

Etat actuel: moteur battle et branchement wild runtime existent. Le runtime
ouvre l'overlay, recoit un outcome et reprend l'overworld.

Preuves:

- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

Trous:

- Outcome trop pauvre pour rewards/XP.
- HP write-back oui, PP/status non.
- Fuite immediate simple, pas formule.

Recommandation: declarer la fuite simple comme beta acceptable, mais faire
Battle Persistence Contract + rewards/XP minimal.

### Bloc 10. Capture

Etat actuel: capture minimale fonctionne si wild battle, party non pleine et
poke-ball disponible. Le Pokemon est ajoute a la party et la ball est consommee.

Preuves:

- `BattleSession.applyChoice`
- `RuntimeBattleSetupMapper`
- `applyRuntimeBattleOutcomeToGameState`
- `wild_battle_end_to_end_flow_test.dart`

Trous:

- Capture toujours reussie quand autorisee.
- Pas de formule/catch rate.
- Pas de PC/box.
- Party pleine = capture rejetee/desactivee, pas de fallback UX.

Recommandation: pour beta, soit PC Box V0, soit fallback explicite "party
pleine" avec feedback; le prompt beta demande au minimum l'un des deux.

### Bloc 11. Combat dresseur

Etat actuel: editor trainer library, trainer request runtime et battle handoff
existent. La victoire peut marquer le trainer comme battu via flag.

Preuves:

- `packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart`
- `packages/map_runtime/lib/src/application/trainer_battle_request.dart`
- `packages/map_runtime/test/trainer_battle_request_test.dart`
- `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`

Trous:

- Pas de smoke no-code complet trainer on map -> battle -> reward -> dialogue.
- Pas de rewards/money/badges/XP.
- Dialogue post-combat conditionnel pas prouve dans Selbrume.

Recommandation: fermer un seul dresseur rival beta avant trainer rematch ou
IA avancee.

### Bloc 12. Recompenses / progression

Etat actuel: manquant cote battle. Des scenarios peuvent donner des items apres
des flags, mais le battle outcome ne porte pas de reward contract.

Preuves:

- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_runtime/test/reward_bridge_readiness_test.dart`
- `packages/map_core/lib/src/models/save_data.dart`

Trous:

- No `BattleReward`.
- No XP field.
- No level-up apply.
- No money/badge payout.
- No post-battle presentation.

Recommandation: plus gros bloc beta apres New Game. Ne pas attendre la parite
complete: XP + level-up + money/item minimal suffisent.

### Bloc 13. Audio

Etat actuel: audio runtime absent. Il existe seulement des champs metadata:
`MapMetadata.musicId`, `ProjectTrainerEntry.battleThemeId`,
`victoryThemeId`, Pokemon cry refs importes et RMXP `seName` dans les timings.

Preuves:

- `packages/map_core/lib/src/models/map_metadata.dart`
- `packages/map_core/lib/src/models/project_trainer.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_sdk_rmxp_animation_catalog.dart`
- `packages/map_editor/lib/src/ui/panels/map_properties_panel.dart`

Trous:

- No dependency/service runtime.
- No asset bundle audio.
- No BGM map/battle.
- No SFX menu/dialogue/combat/capture/heal.
- No volume/mute.
- No missing audio validator.

Recommandation: audio minimal doit etre un lot beta separe et tres borne.

### Bloc 14. Save / Load

Etat actuel: repository fichier et use cases existent. Les tests ciblent party,
bag, position, flags, consumed events et scenarios. Le runtime menu expose
save/load.

Preuves:

- `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart`
- `packages/map_runtime/lib/src/application/save_game_use_case.dart`
- `packages/map_runtime/lib/src/application/load_game_use_case.dart`
- `packages/map_runtime/test/file_game_save_repository_test.dart`
- `packages/map_runtime/test/p3_save_load_narrative_state_roundtrip_test.dart`

Trous:

- Chemin `SaveData` legacy perd `scriptVariables`/`consumedEventIds`, alors que
  le repository runtime GameState JSON les preserve.
- `PlayableMapGame.loadGame` est documente non transactionnel/no rollback.
- Resultats de combat non auto-sauvegardes.
- No full beta reload smoke.

Recommandation: durcir les transactions et definir la forme canonique de save
avant Selbrume final.

### Bloc 15. Validator de jouabilite

Etat actuel: validateurs techniques reels mais disperses.

Preuves:

- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_core/lib/src/validation/narrative_validator.dart`
- `packages/map_editor/lib/src/application/use_cases/validate_pokemon_project_data_use_case.dart`

Trous:

- No single `PlayableProjectValidator`.
- Pas d'UI editeur exposee pour un rapport beta global.
- Pas de validation audio.
- Pas de preuve que start map/spawn/warps/NPC/dialogue/scenario/trainer/species
  /moves/items/assets/save-load sont verts ensemble.

Recommandation: construire un validator agregateur beta avec diagnostics
actionnables, expose dans l'editeur.

### Bloc 16. Golden Slice Selbrume

Etat actuel: concept et roadmaps existent. Aucun projet Selbrume jouable n'a ete
trouve. Les fixtures `golden_battle_slice`, `p3_narrative_smoke_slice` et
`packages/map_runtime/test/fixtures/p3_*` sont techniques et non-Selbrume.

Preuves:

- `MVP Selbrume/selbrume.md`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_3.md` mentionne plusieurs fois "fixture
  technique non-Selbrume" et "ne pas creer Selbrume final".
- Project JSON trouves: `examples/playable_runtime_host/golden_battle_slice/project.json`,
  `examples/playable_runtime_host/p3_narrative_smoke_slice/project.json`,
  `packages/map_runtime/test/fixtures/p3_*`.

Trous:

- Pas de maps Bourg/Port jouables.
- Pas de Mael/Lysa fonctionnels.
- Pas de combat rival Selbrume.
- Pas de heal/audio/validator green Selbrume.
- Pas de save/reload final Selbrume.

Recommandation: ne pas creer Selbrume avant New Game, heal, rewards/XP, audio
minimal et validator beta.

## 5. End-to-end flow analysis

Flux cible:

`editeur -> disque -> runtime -> New Game -> exploration -> narrative -> battle -> reward -> save/load`

Etat reel par segment:

| Segment | Etat | Verdict |
|---|---|---|
| Editeur -> disque | Repositories et use cases existent pour projet, maps, trainers, encounters, dialogues | PARTIAL |
| Disque -> runtime | `loadRuntimeMapBundle` charge manifest/maps et tests techniques passent | PARTIAL |
| Runtime -> New Game | Host lance launch save/demo seed; pas de New Game produit | MISSING |
| New Game -> exploration | Spawn resolver existe; validation/fallback pas beta | PARTIAL |
| Exploration -> narrative | Scenario executor et event/source bridges existent | PARTIAL |
| Narrative -> battle | `startTrainerBattle` et battle continuation existent en fixture technique | PARTIAL |
| Battle -> reward | HP/capture/trainer defeated; no reward/XP/money | MISSING |
| Reward -> save/load | Save peut persister ce qui existe; rewards/XP absents | PARTIAL/MISSING |
| Full smoke | Aucun test editeur -> disque -> runtime -> New Game -> save/load | MISSING |

Conclusion: la chaine casse surtout a New Game, rewards/XP, heal/audio,
validator et assembly Selbrume. Les maillons techniques sont bons, mais la
preuve beta n'existe pas.

## 6. Beta blockers

1. Absence de New Game runtime et d'etat initial manifest-driven.
2. Absence de smoke editeur -> disque -> runtime -> save/load.
3. Start map/spawn non gate par validator beta et launch save startup truth a
   durcir.
4. Pas de `healParty` ni centre de soin.
5. Pas de PC/box ou fallback UX suffisant pour capture pleine.
6. Pas de XP, level-up, rewards, money/badges, reward presentation.
7. Pas de battle persistence contract complet: PP/status/held-item/XP.
8. Pas d'audio runtime minimal.
9. Pas de playable project validator expose dans l'editeur.
10. Pas de projet Selbrume reel avec Bourg/Port/Mael/Lysa/rival battle.

## 7. Non-blocking polish

- Capture formula exacte: beta peut commencer avec formule simple ou deterministic
  si documentee.
- Fishing/headbutt/repel/static encounters avances.
- Trainer rematch policy.
- Evolution et move learning avances, sauf si indispensables au slice.
- UI editor totalement no-code pour tous les champs secondaires.
- Battle parity target complet.
- Audio riche et mixage avance.
- Shadows/surfaces/tileset polish hors besoins directs du slice.

## 8. Unknowns

- Le comportement exact visuel/UX du menu party/bag runtime n'a pas ete teste
  manuellement.
- L'etat de performance runtime sur un projet volumineux n'a pas ete mesure.
- La provenance/licence des assets audio SDK source n'a pas ete auditee.
- Les rapports anciens peuvent contenir des decisions utiles non relues en
  entier; cet audit a priorise code/tests.
- La correction exacte du startup `launch save` demande un test dedie.

## 9. Evidence pack

Commandes read-only ou audit-only lancees:

```text
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 5
find . -maxdepth 3 -name "pubspec.yaml" -print
find . -type d \( -name .git -o -name .dart_tool -o -name build \) -prune -o \( -iname '*selbrume*' -o -iname '*golden*' -o -iname '*bourg*' -o -iname '*port*' -o -iname '*lysa*' -o -iname '*mael*' \) -print
rg "GameState|ProjectManifest|party|bag|heal|healParty|starter|new game|NewGame|save|load|encounter|wild|capture|trainer|reward|xp|level|audio|music|sound|validator|diagnostic|Selbrume|Lysa|Mael"
rg -n "FG-[0-9]+|New Game|starter|party|bag|heal|encounter|capture|trainer|reward|XP|level|audio|save|validator|Selbrume|Golden" pokemap_roadmap_mecaniques_fangame.md "MVP Selbrume" -g '*.md'
```

Test command results:

```text
cd packages/map_core && dart test test/game_state_persistence_test.dart test/narrative_validator_test.dart --reporter=compact
Result: PASS, 00:00 +28: All tests passed!

cd packages/map_gameplay && dart test test/complete_step_test.dart test/give_pokemon_test.dart --reporter=compact
Result: PASS, 00:00 +30: All tests passed!

cd packages/map_battle && dart test test/battle_session_test.dart test/battle_session_flow_test.dart --reporter=compact
Result: PASS, 00:00 +50: All tests passed!

cd packages/map_runtime && flutter test test/file_game_save_repository_test.dart test/runtime_battle_outcome_apply_test.dart test/wild_battle_end_to_end_flow_test.dart test/trainer_battle_request_test.dart test/p3_save_load_narrative_state_roundtrip_test.dart test/p3_scenario_runtime_golden_path_test.dart test/phase_a_golden_battle_slice_smoke_test.dart
Result: PASS, 00:01 +53: All tests passed!

cd examples/playable_runtime_host && flutter test test/phase_a_golden_slice_launch_test.dart test/p3_narrative_smoke_slice_test.dart
Result: PASS, 00:00 +2: All tests passed!

cd packages/map_editor && flutter test test/encounter_table_use_cases_test.dart test/trainer_use_cases_test.dart test/dialogue_editor_validation_test.dart test/cutscene_studio_authoring_test.dart test/step_studio_authoring_test.dart
Result: PASS, 00:00 +30: All tests passed!
```

Note tooling:

- `mcp__dart__.run_tests` a ete tente, mais a refuse les roots car aucun root
  Dart enregistre n'etait disponible dans cette session. Les tests ont donc ete
  lances via commandes package-scoped.

Fichiers principaux inspectes:

```text
MVP Selbrume/checklist_beta_pokemap.md
MVP Selbrume/selbrume.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_3.md
pokemap_roadmap_mecaniques_fangame.md
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_trainer.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_core/lib/src/validation/narrative_validator.dart
packages/map_gameplay/lib/src/new_game_state_builder.dart
packages/map_gameplay/lib/src/gameplay_step.dart
packages/map_gameplay/lib/src/gameplay_encounter.dart
packages/map_gameplay/lib/src/game_state_mutations.dart
packages/map_battle/lib/src/battle_session.dart
packages/map_battle/lib/src/battle_resolution.dart
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
packages/map_runtime/lib/src/application/scenario_runtime_executor.dart
packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart
packages/map_editor/lib/src/ui/panels/encounter_tables_panel.dart
packages/map_editor/lib/src/ui/panels/map_properties_panel.dart
packages/map_editor/lib/src/ui/canvas/dialogue_studio_workspace.dart
examples/playable_runtime_host/lib/main.dart
examples/playable_runtime_host/lib/src/runtime_project_picker.dart
examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart
```

Git status initial:

```text
 M "MVP Selbrume/road_map_phase_4.md"
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/authoring/narrative_predicate_authoring_draft.dart
?? packages/map_core/test/narrative_predicate_authoring_draft_test.dart
```

## Auto-critique

Ce que mon audit prouve reellement:

- Les classes, fonctions, tests et fixtures cites existent dans le repo actuel.
- Les tests cibles listes ci-dessus passent dans cette session.
- Les grands flux New Game, rewards/XP, heal, audio, validator beta et Selbrume
  final ne sont pas prouves par le code actuel.

Ce que mon audit ne prouve pas:

- Il ne prouve pas la stabilite visuelle interactive sur desktop/mobile.
- Il ne prouve pas la performance.
- Il ne prouve pas toutes les branches de chaque editeur.
- Il ne prouve pas la qualite UX no-code finale.

Zones ou je peux me tromper:

- Un flow cache non reference par les termes recherches peut exister, mais les
  tests et exports publics ne l'ont pas rendu visible.
- Certains rapports anciens peuvent contenir des decisions non codees que je
  n'ai pas traitees comme verite.
- Le niveau "beta acceptable" pour PP/status/audio peut etre ajuste produit.

Hypotheses faites:

- La beta exige un parcours jouable prouve, pas seulement des briques.
- Selbrume doit etre un vrai projet runtime, pas une fixture technique generique.
- Le fallback party pleine de capture doit etre visible et testable pour etre
  accepte comme beta.

Zones necessitant un audit plus profond:

- Test interactif runtime des menus party/bag/save/load.
- Audit exact du startup `launch save` vs map selection.
- Audit des assets et chemins relatifs sur un projet cree par l'editeur.
- Audit legal/technique des assets audio source.

Decisions de roadmap discutables:

- La roadmap propose de faire audio avant Selbrume final; on peut le repousser
  si la beta accepte un mode muet, mais la checklist le marque explicitement.
- La roadmap propose un fallback capture pleine avant PC complet; si la beta
  veut une experience Pokemon-like stricte, PC Box V0 doit remplacer ce fallback.
- XP/level-up minimal peut etre borne tres petit; move learning/evolution peuvent
  attendre si le slice 10-20 minutes n'en a pas besoin.

## Prompt critique

Elements ambigus:

- "Beta fonctionnelle" ne precise pas si audio est bloquant ou peut etre beta
  polish. La checklist le rend bloquant par prudence.
- "PC/box minimal ou fallback" laisse le choix produit ouvert.
- "Golden Slice Selbrume 10-20 minutes" ne donne pas le contenu exact attendu.

Elements trop larges:

- L'audit couvre neuf axes techniques et un roadmap complet; c'est plus proche
  d'un pre-release review que d'une simple checklist.
- Demander le contenu complet des fichiers en reponse finale peut devenir moins
  utile que les artefacts Markdown eux-memes.

Elements interpretes:

- Les sous-agents H/I ont ete simules localement car la limite de threads avait
  ete atteinte.
- `DONE` a ete reserve aux items prouves par code/tests; les briques partielles
  sont restees `PARTIAL`.
- Les rapports anciens n'ont ete utilises que comme contexte, pas comme preuve
  de readiness.

Corrections proposees pour un futur prompt:

- Preciser si audio est release blocker ou beta polish.
- Fournir une definition executable du parcours Selbrume cible.
- Demander une matrice CSV/Markdown separee si toutes les lignes doivent etre
  traitees par outil.
- Autoriser explicitement ou non les tests longs/analyze complets.
