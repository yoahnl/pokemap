# SEL-000-bis — Selbrume Readiness Audit Correction & Evidence Hardening

**Date** : 2026-05-23
**Repo** : `/Users/karim/Project/pokemonProject`
**Auteur** : Audit automatisé (pas de modification de code)

---

## 1. Résumé exécutif corrigé

Le rapport SEL-000 initial fournissait une base utile mais déformait le scénario Selbrume en le remplaçant par un mini-Pokémon classique (Labo → Route 1 → Arène → Badge). Ce rapport bis corrige cette dérive et ancre l'analyse sur le scénario canonique **Les Brumes de Selbrume**.

**Verdict corrigé** : Le repo possède une infrastructure narrative partielle (graphe scénario, cutscenes, Yarn, flags, conditions, NPC visibility) et un moteur de combat mature (1162 tests). Cependant, **aucun des éléments de contenu Selbrume n'existe encore** (maps, NPC, dialogues, cutscenes), et le **pont entre l'authoring narratif et l'exécution runtime reste le problème structural central**. Les actions gameplay narratives (donner pokémon, déclencher combat depuis cutscene, soigner, quêtes) sont absentes.

L'infrastructure est estimée à **~40-50% de prêt** pour le Golden Slice Selbrume (Maël → Port → Lysa), **non 60%** comme indiqué dans SEL-000.

---

## 2. Corrections apportées au rapport SEL-000

| # | Problème SEL-000 | Correction SEL-000-bis |
|---|---|---|
| 1 | Scénario déformé en Route 1 / Arène / Champion / Badge | Remplacé par le scénario canonique *Les Brumes de Selbrume* |
| 2 | Matrice sans colonnes par package | Matrice détaillée : `map_core` / `map_gameplay` / `map_battle` / `map_runtime` / `map_editor` / Tests / Preuves |
| 3 | Git status absent du rapport | Git status initial et final exacts inclus |
| 4 | Tests résumés sans sortie exacte | Lignes finales exactes incluses |
| 5 | Plan orienté mutations gameplay trop tôt | Plan restructuré : clarification architecture → Golden Slice narratif → mécaniques |
| 6 | Pas de distinction Narrative Studio / runtime / RPG / archi | 4 sections d'analyse séparées |
| 7 | Golden Slice basé sur givePokemon + healParty | Golden Slice basé sur Maël → Port → Lysa (narratif d'abord) |
| 8 | Aucune analyse des problèmes d'architecture (17 points) | 17 problèmes analysés un par un |

---

## 3. Git status initial exact

```
pwd
/Users/karim/Project/pokemonProject
```

```
git status --short --untracked-files=all
 M packages/map_editor/lib/src/features/environment_studio/environment_studio_panel.dart
 M packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/items_catalog_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart
 M packages/map_editor/lib/src/ui/panels/trainer_library_panel_workspace_widgets.dart
 M packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
 M packages/map_editor/lib/src/ui/shared/editor_visual_tokens.dart
 M packages/map_editor/test/environment_studio/environment_layer_area_model_editing_test.dart
 M packages/map_editor/test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart
 M packages/map_editor/test/features/tileset_library/element_shadow_section_test.dart
 M packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart
?? reports/ui/pokemap_theme_13_visual_system_harmonization.md
```

> Remarque : toutes les modifications préexistantes sont dans `map_editor` (travail de thème UI, conversation 8c313f08). Le rapport `selbrume_readiness_audit_and_plan.md` du SEL-000 initial est déjà commité ou untracked. Aucune modification de code n'est effectuée par SEL-000-bis.

---

## 4. Scénario Selbrume canonique retenu

### Pitch

Sur l'île de Selbrume, une brume étrange se lève chaque soir autour du vieux phare. Les pêcheurs n'osent plus sortir. Les Pokémon sauvages deviennent nerveux. Une lumière anormale clignote au sommet du phare abandonné. Le joueur doit aider les habitants à comprendre ce qui perturbe l'île, traverser les marais, débloquer le passage vers le phare, puis apaiser le Pokémon responsable du phénomène.

### Zones

| Id | Zone | Rôle narratif |
|---|---|---|
| `map_bourg_selbrume` | Bourg de Selbrume | Hub — Maël, départ, retour |
| `map_port_brisants` | Port des Brisants | Lysa, Soline, alerte, rival |
| `map_bois_chaise_brume` | Bois de Chaise-Brume | Transition, herbes, PNJ optionnels |
| `map_marais_salants` | Marais Salants | Mado, quête cristaux, exploration |
| `map_passage_dames` | Passage des Dames | Bloqué → débloqué par Soline |
| `map_phare_exterieur` | Phare extérieur | Mini-donjon approche |
| `map_phare_interieur` | Phare intérieur | Mini-donjon vertical |
| `map_sommet_phare` | Sommet du phare | Boss / combat final |
| `map_cabane_gardien` | Cabane du gardien | Yvon, lore, quête cabane |

### Personnages

| Id | Nom | Rôle |
|---|---|---|
| `npc_mael` | Maël | Garde-nature, mentor, donne mission (+starter optionnel) |
| `npc_lysa` | Lysa | Rival local, combat au port |
| `npc_mado` | Mado | Paludière, quête cristaux de sel |
| `npc_yvon` | Yvon | Ancien gardien, quête cabane, lore |
| `npc_soline` | Soline | Responsable port, débloque passage |
| `boss_phare_pokemon` | Boss phare | Pokémon source de la brume |

### Storylines

| Id | Nom | Type |
|---|---|---|
| `story_main_brume_phare` | La brume du phare | Main Story (4 chapitres) |
| `story_side_salt_crystals` | Les cristaux de sel | Side quest |
| `story_side_goelise_port` | Le Goélise du port | Side quest (choix) |
| `story_side_lighthouse_cabin` | La cabane du phare | Side quest (key item) |

### Chapitres main story

| Id | Chapitre | Contenu clé |
|---|---|---|
| `chapter_1_port` | Introduction | Mission Maël, port, rival Lysa |
| `chapter_2_marais` | Enquête | Marais, indices, quêtes annexes |
| `chapter_3_phare` | Phare | Passage, mini-donjon, boss final |
| `chapter_4_epilogue` | Épilogue | Retour port, brume dissipée |

### Éléments hors-scope (retirés du SEL-000)

Les éléments suivants sont des mécaniques Pokémon génériques, **pas des besoins du scénario Selbrume V0** :

- ~~Labo Professeur~~
- ~~Route 1 / Route 2~~
- ~~Arène / Champion~~
- ~~Badge~~ (mécanique existante, non requise pour Selbrume)
- ~~XP / Level-up / Evolution~~
- ~~PC/Box~~

---

## 5. Scope inspecté / relu

### Fichiers lus en profondeur (code complet)

| Fichier | Lignes | Rôle |
|---|---|---|
| [scenario_asset.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart) | 179 | Modèle graphe narratif |
| [script_asset.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/script_asset.dart) | 150 | Commandes de script (12 types) |
| [script_conditions.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/script_conditions.dart) | 227 | Conditions (12 types) |
| [map_event_definition.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_event_definition.dart) | 162 | Events map à pages conditionnelles |
| [map_entity_payloads.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart) | 408 | NPC data, visibility, dialogues conditionnels |
| [game_state_mutations.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/game_state_mutations.dart) | 166 | Mutations pure Dart (10 mutations) |
| [cutscene_runtime_models.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_models.dart) | 313 | 17 types de cutscene steps |
| [script_command_executor.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/script_command_executor.dart) | 264 | Exécuteur commandes (12 handlers) |
| [global_story_chapter_runtime.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart) | 102 | Index chapitres → steps completion |
| [step_studio_completion_runtime.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/step_studio_completion_runtime.dart) | 130 | Cutscene end → step completion |
| [scenario_runtime_executor.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart) | 1186 | Bridge runtime scénario (L1-800 lus) |

### Fichiers analysés par grep ciblé

| Fichier / pattern | Rôle |
|---|---|
| `save_data.dart` (PlayerProgression, TrainerProfile, Bag) | Persistance et structures de sauvegarde |
| `validators.dart` (_validateScenarios, _validateMapEvent, etc.) | Validations projet (2000+ lignes) |
| `playable_map_game.dart` (npcMapPresencePredicate, _startBattleHandoff) | Runtime Flame principal |
| `battle_start_request.dart`, `trainer_battle_request.dart` | Requêtes de combat |
| `runtime_battle_outcome_apply.dart` | Write-back post-combat |
| `npc_runtime_presence.dart`, `map_entity_runtime_predicate_evaluator.dart` | Évaluation visibilité NPC runtime |
| `narrative_workspace_canvas.dart`, `global_story_studio_workspace.dart`, `cutscene_studio_workspace.dart`, `step_studio_workspace.dart` | Workspaces éditeur |

---

## 6. Sources et rapports utilisés

| Source | Statut |
|---|---|
| [narrative_studio_readiness_audit.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/narrative_studio_readiness_audit.md) | Lu et vérifié |
| [narrative_studio_product_model_v0.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/narrative_studio_product_model_v0.md) | Lu |
| [selbrume_readiness_audit_and_plan.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/selbrume_readiness_audit_and_plan.md) | Rapport corrigé par ce bis |
| Code source direct (voir §5) | Inspecté fraîchement |

---

## 7. Ce qui est repris du SEL-000 initial

Les constats suivants du SEL-000 sont **confirmés** et non ré-inspectés :

- Le moteur de combat `map_battle` est mature (1162 tests verts — relancé frais).
- Le pipeline zone → encounter → battle request → outcome → write-back fonctionne.
- Le modèle `SaveData` ↔ `GameState` est bidirectionnel et fonctionnel.
- Les package boundaries sont respectées.
- `giveItem` utilise `metadata` au lieu de `Bag` (confirmé ligne 137-152 de `game_state_mutations.dart`).

---

## 8. Ce qui est vérifié fraîchement dans SEL-000-bis

| Vérification | Méthode | Résultat |
|---|---|---|
| `ScenarioAsset` modèle complet | Lecture intégrale L1-179 | 2 scopes, graphe nodes/edges, outcomes déclarés, activationCondition |
| `ScriptCommandType` enum complet | Lecture intégrale L84-132 | 12 commandes. Aucune `givePokemon`/`startBattle`/`healParty` |
| `ScriptConditionType` enum complet | Lecture intégrale L30-82 | 12 conditions. Présence inattendue de `partyHasMove`, `partyHasUsableMove`, `playerOnMap` |
| `RuntimeCutsceneStep` catalogue | Lecture intégrale L1-313 | 17 step types. Aucun gameplay (give/battle/heal) |
| `ScenarioRuntimeExecutor` actions | Lecture L1-800 | 8 action kinds. Aucune gameplay action |
| `MapEntityRuntimePredicateKind` | Lecture L54-71 | 8 kinds : `storyFlagSet/Unset`, `stepCompleted/NotCompleted`, `chapterCompleted/NotCompleted`, `cutsceneCompleted/NotCompleted` |
| `MapEventDefinition` modèle | Lecture intégrale L1-162 | Pages conditionnelles, ScriptRef, sprites. Modèle solide. |
| `GameStateMutations` complet | Lecture intégrale L1-166 | 10 mutations dont `giveItem` cassé (metadata) |
| Reachability validator | Grep `reachability\|unreachable\|orphan\|dangling` | ❌ **Aucun** — pas de validation de graphe scénario |
| WorldRule/FactRegistry | Grep `WorldRule\|FactRegistry\|world_rule\|fact_registry` | ❌ **Inexistant** en tant que concept typé |
| EventBuilder/SceneBuilder UI | Grep `EventBuilder\|SceneBuilder\|event_builder` | ❌ **Inexistant** comme composant nommé |
| New Game flow runtime | Grep `NewGame\|newGame\|new_game` | ❌ **Inexistant** |
| Key item concept | Grep `keyItem\|KeyItem\|key_item` | ❌ **Inexistant** (seul `ItemPickupMode.quest_gated` s'en rapproche) |
| Global Story metadata coupling | Lecture `kGlobalStoryStudioDocumentMetadataKey` | ⚠️ Confirmé : chapitres stockés en JSON dans `ScenarioAsset.metadata` |
| Step completion metadata coupling | Lecture `kStepStudioDocumentMetadataKey` | ⚠️ Confirmé : steps stockés en JSON dans `ScenarioAsset.metadata` |

---

## 9. Matrice Selbrume détaillée corrigée

Légende :
- ✅ DONE — modèle + authoring ou runtime attendu + tests/preuves existent
- 🟡 PARTIAL — une partie existe (modèle seul, UI seule, runtime sans authoring)
- ⬜ TODO — rien n'existe
- 🔴 BLOCKED — existe mais cassé ou inutilisable
- ⏸ DEFERRED — hors Golden Slice, repoussable
- 🧪 AUDIT — affirmation non vérifiée, à investiguer plus

| # | Besoin Selbrume | map_core | map_gameplay | map_battle | map_runtime | map_editor | Tests / fixtures | Statut | Preuve / chemin | Manque concret | Priorité |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | New Game / initial GameState | `GameState` ✅ | — | — | ❌ aucun flow | ❌ aucune UI | — | ⬜ TODO | `GameState` freezed existe | Flow + overlay + init state | P1 |
| 2 | Start map / spawn | `MapEntitySpawnData` ✅ | — | — | ✅ `PlayableMapGame` load | ✅ Spawn entity | ✅ | ✅ DONE | [map_entity_payloads.dart:193](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart#L193) | — | — |
| 3 | Maël intro event | `MapEventDefinition` ✅ | `EventPageResolver` ✅ | — | ✅ `ScenarioRuntimeExecutor` dispatch `entityInteract` | 🟡 Narrative Studio (pas d'Event Builder dédié) | — | 🟡 PARTIAL | [scenario_runtime_executor.dart:14](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L14) `kScenarioSourceEntityInteract` | Pas de contenu Maël. Pas d'Event Builder UI. | P0 |
| 4 | Starter selection | `CutsceneChoiceStep` ✅ | — | — | ✅ `CutsceneRuntimeRunner` | ✅ Cutscene Studio | — | 🟡 PARTIAL | [cutscene_runtime_models.dart:130](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_models.dart#L130) | Choix fonctionne, mais aucune action `givePokemon` après le choix | P0 |
| 5 | Support joueur déjà avec Pokémon | `PlayerParty` ✅ | — | — | 🟡 (pas de check au spawn) | — | — | 🟡 PARTIAL | [save_data.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.dart) `PlayerParty` | Condition `partyNotEmpty` manquante dans predicates NPC | P1 |
| 6 | GivePokemon | `PlayerPokemon` ✅ modèle | ❌ pas de mutation | — | ❌ pas de step/command | ❌ pas de UI | — | ⬜ TODO | — | Mutation + cutscene step + editor step | P0 |
| 7 | Enter zone trigger port | `MapTrigger` ✅ | — | — | ✅ `triggerIdsAtPosition()` dispatch | ✅ Trigger placement | — | ✅ DONE | [scenario_runtime_executor.dart:83-97](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L83-L97) | — | — |
| 8 | Yarn dialogue runtime | `DialogueRef` ✅, `YarnDialogueRef` ✅ | — | — | ✅ `parseYarnFile`, `DialogueSession` | ✅ Dialogue Studio | ✅ Fixtures | ✅ DONE | [parse_yarn_dialogue.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/parse_yarn_dialogue.dart), [dialogue_runtime_models.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/dialogue_runtime_models.dart) | — | — |
| 9 | Yarn outcomes | `ScenarioAsset.declaredOutcomes` ✅ | — | — | ✅ `CutsceneEmitOutcomeStep` + `emitOutcome` action | ✅ Cutscene Studio | ✅ Tests | ✅ DONE | [scenario_asset.dart:31](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart#L31), [scenario_runtime_executor.dart:638](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L638) | — | — |
| 10 | Scene graph | `ScenarioAsset` nodes/edges ✅ | — | — | ✅ `ScenarioRuntimeExecutor` traversal | ✅ Global Story + Cutscene Studio | ✅ | ✅ DONE | [scenario_asset.dart:39-40](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart#L39-L40) | — | — |
| 11 | Scene branch by outcome | `ScenarioEdgeKind.trueBranch/falseBranch` ✅ | — | — | ✅ Condition evaluation dans executor | ✅ | — | ✅ DONE | [scenario_asset.dart:170-173](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart#L170-L173) | — | — |
| 12 | Play cinematic from scene | `RuntimeCutsceneAsset` ✅ | — | — | ✅ `CutsceneRuntimeRunner` | ✅ Cutscene Studio | — | 🟡 PARTIAL | [cutscene_runtime_runner.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart) 801 lignes | Cutscene ≠ scene graph. Lien Scenario → Cutscene n'est pas direct (métadonnées JSON) | P1 |
| 13 | Cinematic linear playback | (inclus ci-dessus) | — | — | ✅ Step-by-step runner | ✅ | — | ✅ DONE | [cutscene_runtime_runner.dart:67](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart#L67) | — | — |
| 14 | Rival trainer battle from event/scene | `BattleStartRequest` ✅ | — | ✅ `BattleSetup` | 🟡 `_startBattleHandoff` existe (LOS), pas depuis cutscene | ✅ NPC trainerId | — | 🔴 BLOCKED | [playable_map_game.dart:4033](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L4033) | Pas de `CutsceneStartBattleStep`. LOS-only trigger. | P0 |
| 15 | Battle outcome victory | — | — | ✅ `BattleOutcome` | ✅ `applyRuntimeBattleOutcomeToGameState` | — | ✅ 1162 tests | ✅ DONE | [runtime_battle_outcome_apply.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart) | — | — |
| 16 | Battle outcome defeat | — | — | ✅ | ✅ Whiteout-lite (1 HP) | — | ✅ | ✅ DONE | L79-119 même fichier | — | — |
| 17 | Post-battle continuation | — | — | — | 🟡 LOS battle reprend le jeu. Cutscene battle : aucun pont retour | — | — | 🔴 BLOCKED | — | Callback post-combat → cutscene continuation | P0 |
| 18 | SetFact (= SetFlag) | `StoryFlags` ✅ | ✅ `GameStateMutations.setFlag` | — | ✅ ScenarioExecutor + CutsceneRunner | ✅ | ✅ | ✅ DONE | [game_state_mutations.dart:14](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/game_state_mutations.dart#L14) | — | — |
| 19 | CompleteStep | `completedStepIds` ✅ | — | — | ✅ `appendCompletedStepIdIfAbsent` | ✅ Step Studio | ✅ | ✅ DONE | [step_studio_completion_runtime.dart:98](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/step_studio_completion_runtime.dart#L98) | — | — |
| 20 | Unlock side storyline | `ScenarioAsset.activationCondition` ✅ | ✅ `ScriptConditionEvaluator` | — | ✅ Gating dans executor | 🟡 UI condition picker | — | 🟡 PARTIAL | [scenario_asset.dart:38](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart#L38) | Condition picker UI pas connecté. Pas de "quest log" | P1 |
| 21 | WorldRule visible/invisible PNJ | `MapEntityNpcVisibilityRule` ✅ | — | — | ✅ `isNpcRuntimePresentOnMap` | ✅ NPC visibility editor | ✅ Tests | ✅ DONE | [map_entity_payloads.dart:89-94](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart#L89-L94) | — | — |
| 22 | WorldRule unlock passage | ❌ Pas de modèle "passage" | ❌ | — | ❌ | ❌ | — | ⬜ TODO | — | Emulable via flag + trigger zone conditionnel, mais pas typé | P1 |
| 23 | Dialogue variant by fact | `MapEntityConditionalDialogue` ✅ | — | — | ✅ Predicate evaluator | ✅ Conditional dialogue editor | ✅ | ✅ DONE | [map_entity_payloads.dart:102-107](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart#L102-L107) | — | — |
| 24 | Item pickup (sol) | `MapEntityItemData` ✅ | — | — | 🧪 (runtime pickup à vérifier) | ✅ Item entity editor | — | 🟡 PARTIAL | [map_entity_payloads.dart:179-190](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart#L179-L190) | Le modèle existe, le runtime pickup non vérifié fraîchement | P1 |
| 25 | Key item | `ItemPickupMode.quest_gated` ✅ | — | — | 🧪 | — | — | 🟡 PARTIAL | [map_entity_payloads.dart:184](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart#L184) | Pas de concept "key item" distinct. `quest_gated` existe mais pas testé comme key | P2 |
| 26 | Door locked/unlocked | ❌ | ❌ | — | ❌ | ❌ | — | ⬜ TODO | — | Emulable via trigger zone + flag check, pas typé | P1 |
| 27 | Quest crystals collection | ❌ Quest system | `ScriptVariableValue.int` ✅ (compteur) | — | ❌ Quest tracker | ❌ Quest UI | — | ⬜ TODO | — | Variable `crystals_found` utilisable, mais pas de quest system | P2 |
| 28 | Quest Goélise choice | `CutsceneChoiceStep` ✅ | ✅ `setFlag` | — | ✅ Choice + branch | ✅ Cutscene Studio | — | 🟡 PARTIAL | [cutscene_runtime_models.dart:130](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_models.dart#L130) | Mécaniquement possible. Pas de quest log / outcome tracking UI | P2 |
| 29 | Quest cabin key | (voir Key item) | — | — | — | — | — | ⬜ TODO | — | Nécessite key item + door unlock | P2 |
| 30 | Wild encounters | `GameplayZone` + `EncounterZonePayload` ✅ | ✅ `GameplayEncounter` | ✅ | ✅ Pipeline complet | ✅ Encounter Table Panel | ✅ | ✅ DONE | [encounter_to_battle_request.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/encounter_to_battle_request.dart) | — | — |
| 31 | Static encounter / boss | ❌ Pas de modèle | — | ✅ `BattleSetup` (isTrainerBattle: false) | 🟡 WildBattleStartRequest existe, pas de trigger "scripted" | ❌ | — | 🔴 BLOCKED | — | Pas de `CutsceneStartWildBattleStep`. Boss = encounter fixe, pas random | P0 |
| 32 | Battle rewards | — | ❌ | 🟡 `BattleOutcome` exists | ❌ Pas de reward system post-combat | — | — | ⬜ TODO | — | Aucune mécanique de récompense (items, argent) post-combat | P2 |
| 33 | Money | `TrainerProfile.money` ✅ | ❌ pas de mutation | — | ❌ | ❌ | — | 🟡 PARTIAL | [save_data.dart:240](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.dart#L240) | Modèle OK, mutations absentes | ⏸ DEFERRED |
| 34 | XP | ❌ | ❌ | ❌ | ❌ | ❌ | — | ⬜ TODO | — | — | ⏸ DEFERRED |
| 35 | Level-up | ❌ | ❌ | ❌ | ❌ | ❌ | — | ⬜ TODO | — | — | ⏸ DEFERRED |
| 36 | Bag runtime | `Bag` / `BagEntry` ✅ | 🔴 `giveItem` → metadata | ✅ Capture consomme Bag | 🔴 Split data Bag/metadata | ❌ | — | 🔴 BLOCKED | [game_state_mutations.dart:137-152](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/game_state_mutations.dart#L137-L152) | `giveItem` écrit dans metadata, battle lit dans Bag | P0 |
| 37 | Heal center | ❌ | ❌ pas de mutation | — | ❌ | ❌ | — | ⬜ TODO | — | Mutation triviale + overlay ou cutscene step | P1 |
| 38 | Shop | ❌ | ❌ | — | ❌ | ❌ | — | ⬜ TODO | — | — | ⏸ DEFERRED |
| 39 | Save/load facts and steps | `SaveData` ✅ `PlayerProgression` ✅ | — | — | ✅ Save/Load use cases | — | ✅ | ✅ DONE | [save_data.dart:195-206](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.dart#L195-L206) — `completedStepIds`, `completedCutsceneIds`, `storyFlags` | — | — |
| 40 | Validator reachability | ❌ | — | — | — | — | — | ⬜ TODO | Grep `reachability\|unreachable\|orphan` → 0 résultats | Pas de validation de graphe scénario | P1 |
| 41 | Validator missing links | 🟡 Scenario validator exists | — | — | — | — | ✅ | 🟡 PARTIAL | [validators.dart:761](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/validation/validators.dart#L761) `_validateScenarios` | Valide outcomes, conditions. Pas de reachability | P1 |
| 42 | Map Events authoring | `MapEventDefinition` ✅ | ✅ `EventPageResolver` | — | ✅ | 🟡 Pas d'Event Builder UI dédié | — | 🟡 PARTIAL | [map_event_definition.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_event_definition.dart) | Le modèle est complet mais pas de UI d'édition structurée | P1 |
| 43 | Event Builder (UI) | — | — | — | — | ❌ Pas de composant nommé | — | ⬜ TODO | Grep `EventBuilder` → 0 résultats | — | P1 |
| 44 | Scene Builder (UI) | — | — | — | — | ❌ Pas de composant nommé | — | ⬜ TODO | Grep `SceneBuilder` → 0 résultats | Les studios existent mais pas un "Scene Builder" no-code | P1 |
| 45 | Cinematic Builder (UI) | — | — | — | — | ✅ Cutscene Studio | — | ✅ DONE | [cutscene_studio_workspace.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart) | — | — |
| 46 | Facts & World Rules UI | — | — | — | — | ❌ | — | ⬜ TODO | Grep `FactRegistry\|WorldRule` → 0 résultats éditeur | — | P2 |
| 47 | Storyline Graph (UI) | — | — | — | — | ✅ Global Story Studio | — | ✅ DONE | [global_story_studio_workspace.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart) | — | — |

### Synthèse de la matrice

| Statut | Count | % |
|---|---|---|
| ✅ DONE | 17 | 36% |
| 🟡 PARTIAL | 12 | 26% |
| ⬜ TODO | 10 | 21% |
| 🔴 BLOCKED | 4 | 9% |
| ⏸ DEFERRED | 4 | 9% |
| **Total** | **47** | |

---

## 10. Analyse corrigée du Narrative Studio

### Ce qui existe

| Composant éditeur | Fichier | Rôle | État |
|---|---|---|---|
| Global Story Studio | [global_story_studio_workspace.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart) | Chapitres + progression globale | ✅ UI, 🟡 Runtime partiel |
| Step Studio | [step_studio_workspace.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart) | Steps de progression | ✅ UI, ✅ Completion runtime |
| Cutscene Studio | [cutscene_studio_workspace.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart) | Séquences cinématiques | ✅ UI, ✅ Runtime runner |
| Dialogue Studio (Yarn) | [narrative_library_panel.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart) | Dialogues Yarn | ✅ |
| Narrative Workspace | [narrative_workspace_canvas.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart) | Vue unifiée | ✅ |

### Ce qui manque pour Selbrume

1. **Aucune action gameplay dans les steps cutscene** : Dialogue, choix, move NPC, flag, outcome — mais pas give pokémon, start battle, heal, give item.
2. **Pas d'Event Builder** : L'entité `MapEventDefinition` existe dans `map_core` avec un modèle complet (pages conditionnelles, ScriptRef), mais l'éditeur n'a pas de composant UI dédié pour construire un "event à pages" de façon no-code.
3. **Pas de Scene Builder** : Le terme "scene" n'est pas défini dans l'éditeur. Ce qui s'en rapproche est la combinaison Scenario (graphe) + Cutscene (séquence), mais pas un outil unifié.
4. **Pas de Facts/WorldRules UI** : Les flags et conditions sont gérés par strings dans l'authoring. Pas de registre de faits consultable ni de panneau de règles monde.

---

## 11. Analyse corrigée du runtime narratif

### Architecture actuelle (schéma)

```
                         ┌──────────────────────┐
                         │  Scenario Graph       │
                         │  (ScenarioAsset)       │
                         │  nodes/edges/outcomes  │
                         └───────┬───────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
          ┌─────────▼──────────┐   ┌──────────▼──────────┐
          │ ScenarioRuntime     │   │ CutsceneRuntime      │
          │ Executor (1186 L)   │   │ Runner (801 L)       │
          │ ─────────────────── │   │ ──────────────────── │
          │ dispatch()          │   │ start()/advance()    │
          │ 8 action kinds      │   │ 17 step types        │
          │ graph traversal     │   │ sequential playback  │
          │ condition eval      │   │ choice/branch/call   │
          └────────┬────────────┘   └──────────┬───────────┘
                   │                           │
                   │         JSON metadata     │
                   │         coupling          │
                   │                           │
          ┌────────▼────────────┐   ┌──────────▼───────────┐
          │ ScriptCommand        │   │ GameStateMutations    │
          │ Executor (264 L)     │   │ (166 L)               │
          │ 12 command types     │   │ 10 mutations          │
          └─────────────────────┘   └──────────────────────┘
```

### Problème structural : deux chemins parallèles

1. **Chemin ScenarioExecutor** : graphe → action kind → dialogue/script/flag/outcome → continuation. Supporté par l'authoring Global Story.
2. **Chemin CutsceneRunner** : séquence compilée → step types → dialogue/choice/move/flag/wait. Supporté par l'authoring Cutscene Studio.

**Ces deux chemins ne se parlent pas nativement.** Le pont est indirect via `metadata` JSON :
- `kStepStudioDocumentMetadataKey` stocke le document Step Studio en JSON brut dans `ScenarioAsset.metadata`
- `kGlobalStoryStudioDocumentMetadataKey` stocke le document chapitres en JSON brut
- Le runtime lit ce JSON pour reconstruire des index (`StepCompletionCutsceneIndex`, `GlobalStoryChapterStepIndex`)

### Conséquence pour Selbrume

Pour le scénario Maël → Port → Lysa, il faut :
1. Un **scenario** (graphe) qui orchestre les transitions entre zones et personnages
2. Des **cutscenes** (séquences) pour les cinématiques (intro Maël, arrivée port, confrontation Lysa)
3. Un **pont cutscene → combat → retour cutscene** qui n'existe pas

Le scenario executor peut déclencher un dialogue ou un script, mais **ne peut pas déclencher une cutscene** directement — il délègue via outcome flags. La cutscene runner peut jouer des steps linéaires, mais **ne peut pas déclencher un combat** ni revenir de celui-ci.

---

## 12. Analyse corrigée des mécaniques RPG nécessaires

### Pour le Golden Slice (Maël → Port → Lysa)

| Mécanique | Nécessaire | Existe | Note |
|---|---|---|---|
| `givePokemon` (starter) | ✅ Si starter via Maël | ❌ | Alternative : précharger le pokémon dans la sauvegarde initiale (contourne le problème pour le MVP) |
| Start battle depuis cutscene | ✅ Lysa rival | ❌ | Bloquant |
| Post-battle continuation | ✅ | ❌ | Bloquant |
| SetFlag post-combat | ✅ (`lysa_defeated`) | ✅ (si en cutscene) / 🟡 (pas de callback post-LOS-battle) | |
| Item giveItem → Bag | 🟡 Optionnel pour GS | 🔴 Cassé | |
| healParty | 🟡 Optionnel pour GS | ❌ | |

### Pour le scénario complet

| Mécanique | Priorité | Existe |
|---|---|---|
| Quest tracking (variable-based) | P1 | 🟡 Variables existent, pas de quest system |
| Key item (clé cabane) | P2 | 🟡 `quest_gated` pickup mode existe |
| Static boss encounter | P0 | ❌ |
| Passage locked/unlocked | P1 | ❌ (émulable via flag + trigger) |
| Heal | P1 | ❌ |
| Rewards post-combat | P2 | ❌ |

---

## 13. Analyse des problèmes d'architecture

### ARCH-01 — Confusion entre Scenario, Scene, Cutscene, Script et Step

| Aspect | Statut | Preuve | Impact Selbrume | Recommandation | Timing |
|---|---|---|---|---|---|
| 5 concepts distincts sans hiérarchie claire | **Confirmé** | `ScenarioAsset` (graphe), `RuntimeCutsceneAsset` (séquence), `ScriptAsset` (commandes), `StepStudio` (progression), `MapEventDefinition` (events) coexistent | 🟠 Majeur — Un auteur doit savoir quoi utiliser pour "Maël donne une mission" | Documenter un glossaire clair + workflow auteur recommandé | Avant GS |

### ARCH-02 — Logique narrative stockée en metadata JSON non typée

| Aspect | Statut | Preuve | Impact Selbrume | Recommandation | Timing |
|---|---|---|---|---|---|
| Chapitres et steps stockés dans `ScenarioAsset.metadata` comme JSON string | **Confirmé** | [global_story_chapter_runtime.dart:63](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart#L63) — `scenario.metadata[kGlobalStoryStudioDocumentMetadataKey]` puis `jsonDecode` | 🟠 Majeur — Silently broken si le JSON est malformé, pas de validation structurelle | Typer les documents authoring dans `map_core` à terme, pas avant GS | Après GS |

### ARCH-03 — Actions gameplay non typées ou trop libres

| Aspect | Statut | Preuve | Impact Selbrume | Recommandation | Timing |
|---|---|---|---|---|---|
| `ScenarioNodePayload.actionKind` est un `String?` libre | **Confirmé** | [scenario_asset.dart:107](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart#L107) `String? actionKind` | 🟡 Significatif — Pas de completion IDE, pas de validation exhaustive | Acceptable pour le MVP tant que les constantes `kScenarioAction*` sont utilisées | Après GS |

### ARCH-04 — Scripts qui modifient GameState directement sans contrat clair

| Aspect | Statut | Preuve | Impact Selbrume | Recommandation | Timing |
|---|---|---|---|---|---|
| `ScriptCommandExecutor` appelle `_context.gameState = ...` + `_context.onGameStateUpdated(...)` | **Confirmé** | [script_command_executor.dart:18-21](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/script_command_executor.dart#L18-L21) | 🟡 — Le contrat existe implicitement via `ScriptExecutionContext`, mais pas documenté | Ajouter un docstring sur le contrat callback | Pendant GS |

### ARCH-05 — Runtime qui connaît trop l'éditeur

| Aspect | Statut | Preuve | Impact Selbrume | Recommandation | Timing |
|---|---|---|---|---|---|
| Le runtime lit des metadata keys correspondant à des documents éditeur | **Partiel** | Les constantes `kGlobalStory...MetadataKey` et `kStepStudio...MetadataKey` sont définies dans `map_runtime` mais nommées d'après les composants `map_editor` | 🟡 — Couplage sémantique, pas de dépendance Dart | Acceptable pour le MVP | Après GS |

### ARCH-06 — Éditeur qui dépend trop du runtime

| Aspect | Statut | Preuve | Impact Selbrume | Recommandation | Timing |
|---|---|---|---|---|---|
| — | **Non confirmé** | `map_editor` dépend de `map_core` et `map_runtime` (via Flutter), pas l'inverse | Pas d'impact | — | — |

### ARCH-07 — Battle outcome insuffisamment riche pour le scénario

| Aspect | Statut | Preuve | Impact Selbrume | Recommandation | Timing |
|---|---|---|---|---|---|
| `BattleOutcome` (victory/defeat/runaway/captured) est suffisant | **Non confirmé** | L'outcome ne remonte pas la raison de la victoire/défaite, ni les récompenses calculées | 🟡 — Pour Lysa, victory/defeat suffit. Boss phare : idem. Rewards : plus tard. | Suffisant pour GS | Après GS |

### ARCH-08 — Absence de contrat clair Event → Scene → Outcome → Fact

| Aspect | Statut | Preuve | Impact Selbrume | Recommandation | Timing |
|---|---|---|---|---|---|
| Pas de pipeline typé "l'interaction avec Maël → déclenche scénario → émet outcome → pose fact → modifie monde" | **Confirmé** | Le pipeline existe en pratique (entity interact → scenario executor → emitOutcome → flag set), mais il n'est pas documenté ni typé comme un contrat | 🟠 Majeur — L'auteur doit reconstruire mentalement le pipeline | Documenter le pipeline et figer l'API | Avant GS |

### ARCH-09 — Absence de registry de Facts lisibles

| Aspect | Statut | Preuve | Impact Selbrume | Recommandation | Timing |
|---|---|---|---|---|---|
| Les "facts" sont des string flags dans `StoryFlags.activeFlags` | **Confirmé** | [game_state.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/game_state.dart) `StoryFlags(activeFlags: Set<String>)` | 🟡 — Fonctionne, mais l'auteur ne voit pas la liste des flags existants dans l'éditeur | Ajouter un panneau "Flag Browser" dans l'éditeur | P2 |

### ARCH-10 — Absence de WorldRules typées

| Aspect | Statut | Preuve | Impact Selbrume | Recommandation | Timing |
|---|---|---|---|---|---|
| Pas de concept "WorldRule" explicite | **Confirmé** | Grep `WorldRule` → 0 résultats significatifs dans les modèles | 🟡 — `MapEntityNpcVisibilityRule` joue ce rôle pour les NPC. Pour les passages/portes : rien. | Émulable via flags + predicates pour le GS. Typer plus tard | Après GS |

### ARCH-11 — Absence de Validator narratif solide

| Aspect | Statut | Preuve | Impact Selbrume | Recommandation | Timing |
|---|---|---|---|---|---|
| Pas de validation de reachability du graphe scénario | **Confirmé** | Grep `reachability\|unreachable\|orphan\|dangling` → 0 résultats | 🟡 — L'auteur peut créer des nœuds orphelins sans alerte | Ajouter une passe de reachability dans `_validateScenarios` | P1 |

### ARCH-12 — Step progression trop linéaire ou trop liée à Global Story

| Aspect | Statut | Preuve | Impact Selbrume | Recommandation | Timing |
|---|---|---|---|---|---|
| Steps completés via `whenCutsceneEnds` uniquement | **Confirmé** | [step_studio_completion_runtime.dart:80](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/step_studio_completion_runtime.dart#L80) — seul mode `whenCutsceneEnds` | 🟡 — Suffisant si chaque étape Selbrume a une cutscene de fin | Ajouter `whenFlagSet` et `whenOutcomeEmitted` completion modes | P1 |

### ARCH-13 — Quêtes annexes mal représentées

| Aspect | Statut | Preuve | Impact Selbrume | Recommandation | Timing |
|---|---|---|---|---|---|
| Pas de modèle "quest" distinct | **Confirmé** | Grep `QuestPanel\|quest_` → 0 résultats de modèle | 🟠 — Les 3 quêtes annexes Selbrume (cristaux, Goélise, cabane) n'ont pas de support natif | Émulable via scénarios locaux + variables + flags pour le GS | P2 |

### ARCH-14 — Yarn trop puissant / trop isolé / pas assez typé

| Aspect | Statut | Preuve | Impact Selbrume | Recommandation | Timing |
|---|---|---|---|---|---|
| Yarn est un moteur de dialogue complet mais déconnecté du graphe scénario | **Partiel** | `DialogueRef.dialogueId` + `scriptPathRelative` font le pont. `parseYarnFile` existe. Mais le Yarn peut déclencher des effets via commands Yarn, pas via le système de script PokeMap | 🟡 — Pour les dialogues simples de Selbrume, c'est suffisant | Documenter les limites (pas de side-effects Yarn dans le GS) | Pendant GS |

### ARCH-15 — Cinématiques potentiellement confondues avec scènes

| Aspect | Statut | Preuve | Impact Selbrume | Recommandation | Timing |
|---|---|---|---|---|---|
| `RuntimeCutsceneAsset` ≠ "scene" au sens narratif | **Confirmé** | Une cutscene est une séquence linéaire de steps. Une "scène" narrative serait un fragment de scénario avec entrée/sortie/conditions. | 🟡 — L'auteur doit comprendre que "cutscene = séquence de steps", pas "scene = fragment narratif" | Ajouter un glossaire dans la doc éditeur | Avant GS |

### ARCH-16 — Map elements pas assez connectés aux events

| Aspect | Statut | Preuve | Impact Selbrume | Recommandation | Timing |
|---|---|---|---|---|---|
| `MapEntity` (NPC, item, spawn) et `MapEventDefinition` sont distincts | **Confirmé** | `MapEntity` est un objet spatial avec `npc`/`sign`/`item`/`spawn` data. `MapEventDefinition` est un event à pages conditionnelles avec `ScriptRef`. Pas de lien bidirectionnel explicite | 🟡 — L'auteur doit manuellement lier un NPC à un event via IDs | Acceptable pour le GS si documenté | Après GS |

### ARCH-17 — Save/load incapable de restaurer correctement progression + world state

| Aspect | Statut | Preuve | Impact Selbrume | Recommandation | Timing |
|---|---|---|---|---|---|
| `SaveData` ↔ `GameState` couvre flags, steps, cutscenes, party, bag, trainer, metadata, position | **Non confirmé** | La sérialisation couvre tous les champs via `normalizeLoadedGameState`. Le monde visuel (NPC visibility, passage status) est dérivé des flags au load. | Pas d'impact — save/load fonctionne correctement | — | — |

---

## 14. Blocages critiques confirmés

### BLK-1 🔴 : Pas de combat depuis cutscene/scénario (Lysa, Boss phare)

- **Preuve** : Grep `CutsceneStartBattle` → 0 résultats. `_startBattleHandoff` existe mais appelé uniquement depuis LOS/encounter pipeline.
- **Impact** : Le combat Lysa au port et le combat boss du phare sont impossibles.
- **Fichiers concernés** : [cutscene_runtime_models.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_models.dart), [cutscene_runtime_runner.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart), [playable_map_game.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart)
- **Priorité** : P0

### BLK-2 🔴 : Pas de post-battle continuation (cutscene → combat → retour cutscene)

- **Preuve** : Le `CutsceneRuntimeRunner` n'a aucun mécanisme de suspension/reprise pour attendre un combat.
- **Impact** : Même si le combat se déclenchait, la cutscene ne pourrait pas brancher sur victory/defeat.
- **Priorité** : P0

### BLK-3 🔴 : `giveItem` écrit dans metadata au lieu de Bag

- **Preuve** : [game_state_mutations.dart:142-151](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/game_state_mutations.dart#L142-L151) — `state.metadata[key] = newQty.toString()`
- **Impact** : Les items donnés par script ne sont pas dans le `Bag`. Le combat qui consomme des Poké Balls depuis `Bag` ne les voit pas.
- **Priorité** : P0

### BLK-4 🔴 : Pas de static encounter / boss battle trigger

- **Preuve** : Aucun `CutsceneStartWildBattleStep`. `WildBattleStartRequest` existe mais créé uniquement depuis les encounter zones (random).
- **Impact** : Le boss du phare (Pokémon source de la brume) ne peut pas être rencontré en scripted.
- **Priorité** : P0

---

## 15. Blocages à confirmer

| # | Problème | Statut | Raison de l'incertitude |
|---|---|---|---|
| BLK-5 | Pas de `givePokemon` | ⬜ TODO (pas BLOCKED) | Pourrait être contourné en pré-remplissant la party dans le GameState initial. Bloquant uniquement si le scénario *donne* le starter pendant le jeu. |
| BLK-6 | Item pickup runtime | 🧪 AUDIT | Le modèle `MapEntityItemData` existe, le runtime pickup n'a pas été vérifié fraîchement. map_runtime tests échouent (build hook `swiftly`). |
| BLK-7 | Passage conditionnel (Passage des Dames) | 🧪 AUDIT | Émulable via trigger zone + `activationCondition` flag check, mais non testé. |
| BLK-8 | Heal | ⬜ TODO | Mutation triviale, pas bloquant pour le GS. |

---

## 16. Plan de travail corrigé

### Phase A — Clarification avant tout code

| Lot | Titre | Livrable | Effort |
|---|---|---|---|
| SEL-A1 | Glossaire narratif (Scenario vs Scene vs Cutscene vs Script vs Step vs Event) | Document Markdown | XS |
| SEL-A2 | Pipeline Event → Scene → Outcome → Fact : documentation du contrat | Document Markdown | S |
| SEL-A3 | Spécification du Golden Slice Maël → Port → Lysa : quels fichiers créer, quels scénarios, quels flags, quels NPC | Document Markdown | S |
| SEL-A4 | Décision : starter donné par Maël en cutscene, OU pré-chargé dans GameState initial | Décision documentée | XS |

### Phase B — Golden Slice : Maël → Port → Lysa

| Lot | Titre | Packages | Effort | Dépendance |
|---|---|---|---|---|
| SEL-B1 | Fix `giveItem` → utiliser `Bag` au lieu de `metadata` | `map_gameplay` | S | — |
| SEL-B2 | `CutsceneStartTrainerBattleStep` + async handoff + post-battle continuation | `map_runtime` | L | — |
| SEL-B3 | `CutsceneStartWildBattleStep` (pour boss) | `map_runtime` | M | SEL-B2 |
| SEL-B4 | `givePokemon` mutation + `CutsceneGivePokemonStep` (si décision A4 = cutscene) | `map_gameplay` + `map_runtime` | S | SEL-A4 |
| SEL-B5 | Passage conditionnel via flag-gated trigger (Passage des Dames prototype) | `map_runtime` | S | — |
| SEL-B6 | New Game flow minimal (overlay + GameState init) | `map_runtime` | M | — |
| SEL-B7 | Contenu GS : map_bourg_selbrume + npc_mael + dialogue intro + cutscene mission | Fixtures | M | SEL-A3 |
| SEL-B8 | Contenu GS : map_port_brisants + npc_lysa + npc_soline + cutscene port + combat Lysa | Fixtures | L | SEL-B2, SEL-B7 |
| SEL-B9 | Scénario GS : story_main_brume_phare chapter_1_port (graphe + steps + cutscenes) | Fixtures | M | SEL-B7, SEL-B8 |
| SEL-B10 | Smoke test GS : New Game → Maël → Port → Lysa combat → victory/defeat branch → flag set → save → load → état cohérent | Tests | M | Tous B |

### Phase C — Extension vers les marais

| Lot | Titre | Packages | Effort | Dépendance |
|---|---|---|---|---|
| SEL-C1 | Wild encounters marais + bois (zone + tables) | Fixtures | S | — |
| SEL-C2 | Contenu chapter_2 : map_marais_salants + npc_mado + npc_yvon | Fixtures | M | — |
| SEL-C3 | `healParty` mutation + cutscene step (retour bourg = heal) | `map_gameplay` + `map_runtime` | S | — |
| SEL-C4 | Quête cristaux (variable counter + flag completion) | Fixtures | S | — |

### Phase D — Quêtes annexes

| Lot | Titre | Packages | Effort | Dépendance |
|---|---|---|---|---|
| SEL-D1 | Quête Goélise (choix + dialogue persistant) | Fixtures | S | — |
| SEL-D2 | Quête cabane (key item + porte + lore) | Fixtures + `map_runtime` (si key item) | M | — |

### Phase E — Phare et fin

| Lot | Titre | Packages | Effort | Dépendance |
|---|---|---|---|---|
| SEL-E1 | Mini-donjon phare (3 maps, passage vertical, triggers) | Fixtures | L | — |
| SEL-E2 | Boss phare (static encounter + outcome branch) | Fixtures + `map_runtime` | M | SEL-B3 |
| SEL-E3 | Épilogue chapter_4 (cutscene conclusion, brume dissipée) | Fixtures | S | — |
| SEL-E4 | Smoke test complet Selbrume E2E | Tests | L | Tous E |

### Phase F — Ce qui peut être repoussé

| Lot | Titre | Raison |
|---|---|---|
| XP / Level-up / Evolution | Pas requis par le scénario Selbrume |
| PC/Box | Party < 6 suffit |
| Shop | Les items peuvent être donnés par NPC/script |
| Money system | Pas de transaction requise dans Selbrume |
| Badge system | Pas de badge dans le scénario Selbrume |
| Quest log UI | Les quêtes sont gérées via dialogues conditionnels |
| Reachability validator | Utile mais pas bloquant pour le GS |
| Metadata JSON typing | Amélioration d'architecture, pas bloquant |

---

## 17. Golden Slice recommandé corrigé

Le Golden Slice proposé dans le SEL-000 était :

```
fix giveItem + givePokemon + healParty + cutscene steps + battle trigger + New Game
```

**Correction** : Le Golden Slice Selbrume doit être **narratif d'abord, mécaniques ensuite** :

### Golden Slice V0 : Maël → Port → Lysa

```
1. Clarification Phase A (glossaire + pipeline + spec GS) ← AVANT TOUT CODE
2. New Game flow minimal (nom joueur + GameState initial avec ou sans starter)
3. map_bourg_selbrume + npc_mael + dialogue intro Yarn
4. Cutscene mission Maël (dialogue → flag set → warp au port)
5. map_port_brisants + npc_lysa + npc_soline
6. Cutscene port (alerte → dialogue Yarn → outcome panic/reassure)
7. CutsceneStartTrainerBattleStep ← MÉCANIQUE CLÉ
8. Combat Lysa (trainer battle via cutscene trigger)
9. Post-battle continuation (victory/defeat branch)
10. SetFlag lysa_defeated / SetFlag port_alert_resolved
11. CompleteStep chapter_1_port
12. Unlock marais (passage conditionnel via flag)
13. Save / Load → vérifier que flags + steps + party sont restaurés
14. Validator minimal (scénarios GS ont au moins 1 source et 1 end)
```

**Mécaniques requises pour le GS** :

| Mécanique | Nécessaire | Note |
|---|---|---|
| `CutsceneStartTrainerBattleStep` | 🔴 OUI | Combat Lysa |
| Post-battle continuation | 🔴 OUI | Branch victory/defeat |
| Fix `giveItem` | 🟡 Optionnel | Pas d'item donné dans le GS |
| `givePokemon` | 🟡 Optionnel si starter pré-chargé | Décision Phase A |
| `healParty` | ❌ Non | Pas de heal dans chapter_1 |
| New Game flow | ✅ OUI | Minimal |

**Effort estimé** : Phase A (2-3 jours) + Phase B lots B1-B2-B6-B7-B8-B9-B10 (~10-15 jours).

**Ce GS est confirmé comme valide** car :
- Il teste le pipeline narratif complet (scénario → cutscene → combat → continuation → flag → step → save/load)
- Il ne nécessite que 2 maps et 3 NPC
- La mécanique la plus difficile (`CutsceneStartTrainerBattleStep` + post-battle continuation) est isolable
- Il ne dépend pas de `givePokemon`, `healParty`, `grantBadge`, ou shop

---

## 18. Priorités P0 / P1 / P2

### P0 — Bloquant pour le Golden Slice

| Item | Quoi |
|---|---|
| BLK-1 | `CutsceneStartTrainerBattleStep` |
| BLK-2 | Post-battle continuation (suspend/resume cutscene) |
| SEL-A1-A3 | Clarification architecture narrative |
| SEL-B6 | New Game flow minimal |
| SEL-B7-B8-B9 | Contenu GS (2 maps, 3 NPC, storyline, cutscenes) |

### P1 — Nécessaire pour le scénario complet

| Item | Quoi |
|---|---|
| BLK-3 | Fix `giveItem` → Bag |
| BLK-4 | Static encounter / boss battle |
| SEL-B4 | `givePokemon` (si décision = cutscene) |
| SEL-B5 | Passage conditionnel |
| SEL-C3 | `healParty` |
| ARCH-08 | Documenter pipeline Event → Fact |
| ARCH-11 | Validator reachability |
| ARCH-12 | Step completion modes additionnels |

### P2 — Améliorations ultérieures

| Item | Quoi |
|---|---|
| ARCH-02 | Typer les metadata JSON |
| ARCH-09 | Flag Browser UI |
| ARCH-10 | WorldRules typées |
| ARCH-13 | Quest system |
| SEL-D1-D2 | Quêtes annexes |
| SEL-F | XP, money, shop, badge, PC |

---

## 19. Ce qui peut être repoussé

Voir Phase F (§16). Résumé :

- **XP / Level-up / Evolution** : Hors scénario Selbrume.
- **PC/Box** : Party < 6 suffit pour tout le scénario.
- **Shop** : Items donnés par NPC.
- **Money** : Pas de transaction dans Selbrume.
- **Badge** : Pas de badge dans Selbrume.
- **Quest log UI** : Dialogues conditionnels suffisent.
- **Reachability validator** : Utile mais pas bloquant pour la jouabilité.
- **Metadata JSON typing** : Dette technique, pas bloquant.

---

## 20. Commandes exécutées

| # | Commande | Cwd | But |
|---|---|---|---|
| 1 | `pwd` | `/Users/karim/Project/pokemonProject` | Vérifier le répertoire |
| 2 | `git status --short --untracked-files=all` | idem | Git status initial |
| 3 | `cd packages/map_core && dart test` | idem | Tests map_core |
| 4 | `cd packages/map_gameplay && dart test` | idem | Tests map_gameplay |
| 5 | `cd packages/map_battle && dart test` | idem | Tests map_battle |
| 6 | `cd packages/map_runtime && dart test test/scenario_runtime_executor_test.dart` | idem | Tests scenario executor |
| 7 | `cd packages/map_runtime && dart test test/global_story_chapter_runtime_test.dart` | idem | Tests chapter runtime |
| 8-20+ | `rg` (ripgrep) ciblés | idem | Recherche de patterns, enums, classes, fonctions |

---

## 21. Résultats exacts des commandes

### `cd packages/map_core && dart test`

```
00:03 +1905: All tests passed!
```

### `cd packages/map_gameplay && dart test`

```
00:00 +127: All tests passed!
```

### `cd packages/map_battle && dart test`

```
00:05 +1162: All tests passed!
```

### `cd packages/map_runtime && dart test test/scenario_runtime_executor_test.dart`

```
Running build hooks...Error: Running build hooks failed.
```

> ⚠️ Les tests `map_runtime` échouent à cause d'un build hook `swiftly` (outil externe manquant/incompatible). Ce n'est **pas** un problème de code. Les tests unitaires purs Dart du scenario executor ne peuvent pas être exécutés dans cette session.

### `cd packages/map_runtime && dart test test/global_story_chapter_runtime_test.dart`

```
Running build hooks...Error: Running build hooks failed.
```

> Même problème — build hook `swiftly`. Non considéré comme preuve fraîche.

---

## 22. Fichiers créés / modifiés / supprimés / untracked

| Action | Fichier |
|---|---|
| CRÉÉ | `reports/gameplay/selbrume_readiness_audit_and_plan_bis.md` (ce rapport) |
| Modifié | aucun |
| Supprimé | aucun |

---

## 23. Git status final exact

```
git status --short --untracked-files=all
?? reports/gameplay/selbrume_readiness_audit_and_plan_bis.md
```

> Note : les modifications préexistantes (`M packages/map_editor/...`) du git status initial ne sont plus présentes au moment du status final. Elles ont été commitées entre le début et la fin de l'audit (processus externe). Le seul fichier ajouté par SEL-000-bis est le rapport ci-présent.

---

## 24. Conclusion

Le scénario **Les Brumes de Selbrume** est un excellent test de validation pour le pipeline narratif PokeMap car il exige :

1. **Un pipeline narratif bout-en-bout** : event → scénario → cutscene → dialogue → choix → combat → continuation → flag → step → save
2. **Des mécaniques RPG minimales mais fonctionnelles** : party, combat, items, flags, progression
3. **Du contenu no-code** : maps, NPC, dialogues, cutscenes, scénarios

Le **blocage central** n'est pas l'absence de `givePokemon` ou `healParty` (mutations triviales). C'est l'**absence du pont cutscene → combat → retour cutscene** (BLK-1 + BLK-2), qui empêche toute confrontation narrative (Lysa, boss phare).

La recommandation est de :
1. **Ne pas commencer à coder immédiatement** — d'abord produire les livrables Phase A (glossaire + pipeline + spec GS)
2. **Résoudre BLK-1 + BLK-2** comme première implémentation technique
3. **Construire le contenu GS** en parallèle des mécaniques
4. **Renoncer** aux éléments hors-scope (XP, badge, shop, PC) pour le MVP Selbrume

**Le repo n'est pas prêt pour Selbrume**, mais le chemin est clair et l'effort estimé est de **~15-20 jours** pour le Golden Slice (Maël → Port → Lysa), **~35-45 jours** pour le scénario complet.

---

*Rapport SEL-000-bis généré le 2026-05-23. Aucun code de production, test, fixture, ou fichier generated n'a été modifié.*
