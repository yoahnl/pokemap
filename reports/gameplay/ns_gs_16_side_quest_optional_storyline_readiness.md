# NS-GS-16 — Side Quest / Optional Storyline Readiness

## 1. Résumé exécutif

NS-GS-16 valide un flux générique Side Quest / Optional Storyline au niveau runtime/application, sans ajouter de code de production.

Flux prouvé :

```text
availability fact
→ entityInteract sur test_optional_quest_giver
→ scène start optionnelle
→ setFlag(test_side_quest_started_fact)
→ completeStep(test_step_side_quest_started)
→ scène objective optionnelle indépendante de l'histoire principale
→ completeStep(test_step_side_quest_objective_done)
→ fact miroir pour brancher la scène finale
→ scène finale bloquée si l'objectif manque
→ giveItem(test_item_reward) si l'objectif est terminé
→ setFlag(test_side_quest_completed_fact)
→ completeStep(test_step_side_quest_completed)
→ save/load conserve started/objective/completed/reward
→ world rule change dialogue/visibility post-quest
```

Conclusion honnête :

```text
Cas A — Side Quest readiness existe déjà via facts/steps/scenes.
Aucun Quest Engine dédié n'est créé.
Aucune UI de quêtes n'est créée.
Aucun reward engine, XP reward ou money reward n'est créé.
```

## 2. Roadmap lue et statut initial

Fichier lu avant modification :

```text
MVP Selbrume/road_map.md
```

Statut initial observé :

```text
✅ NS-GS-14   — Item Pickup / GiveItem Authoring Readiness
✅ NS-GS-15   — Key Item / Door Gate Readiness
🔜 NS-GS-16   — Side Quest / Optional Storyline Readiness
```

Le prochain lot exact indiqué était :

```text
🔜 NS-GS-16 — Side Quest / Optional Storyline Readiness
```

## 3. Périmètre exact du lot

Inclus :

```text
audit quest / storyline / facts / steps / rewards existants
caractérisation du flux side quest via ScenarioRuntimeExecutor
preuve disponibilité conditionnelle
preuve démarrage fact + step
preuve objective step optionnelle
preuve branche finale bloquée avant objectif
preuve résolution finale après objectif
preuve récompense simple via giveItem existant
preuve save/load
preuve world rule dialogue / visibilité post-quest
preuve isolation main story
rapport et roadmap
```

Exclus :

```text
Quest Engine
Quest Journal
Quest Studio complet
UI de quêtes
Side Quest Library
Reward Engine
XP rewards
money rewards
contenu final Selbrume
fixture Selbrume finale
project.json Selbrume
map_editor UI
map_battle
build_runner
```

## 4. Frontière Event / Scene / Side Quest / World Rule / Validator

Frontières appliquées :

```text
Event déclenche : entityInteract sur un giver, objectif ou reward proxy.
Scene orchestre : conditions, setFlag, completeStep, giveItem, showMessage.
Side Quest mémorise une progression optionnelle via facts/steps génériques.
World Rule projette : visibilité et dialogue conditionnels.
Validator diagnostique ; il n'exécute pas et n'a pas été modifié.
```

La side quest V0 n'est pas un moteur dédié. Elle est un pattern authorable avec les briques génériques déjà validées par NS-GS-08 à NS-GS-15.

## 5. Audit initial

Commande initiale obligatoire :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text

```

Fichiers et rapports lus :

```text
MVP Selbrume/road_map.md
reports/gameplay/ns_gs_15_key_item_door_gate_readiness.md
reports/gameplay/ns_gs_14_item_pickup_give_item_authoring_readiness.md
reports/gameplay/ns_gs_13_bis_evidence_pack_closure.md
reports/gameplay/ns_gs_13_narrative_validator_minimal_v0.md
reports/gameplay/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
reports/gameplay/ns_gs_10_world_rules_conditional_presence_readiness.md
reports/gameplay/ns_gs_09_yarn_outcome_scene_branch_readiness.md
reports/gameplay/ns_gs_08_npc_interaction_scene_authoring_readiness.md
reports/gameplay/ns_gs_07_step_completion_progression_hooks.md
```

Commandes d'audit obligatoires exécutées :

```bash
rg "quest|Quest|sideQuest|SideQuest|optional|storyline|Storyline|chapter|Chapter|step|Step|progression|completedStep|completeStep|reward|Reward" packages --type dart

rg "ScenarioRuntimeSourceEvent|entityInteract|sourceOutcome|emitOutcome|setFlag|completeStep|giveItem|openDialogue|showMessage|condition|trueBranch|falseBranch" packages/map_core packages/map_runtime --type dart

rg "MapEntityRuntimePredicateEvaluator|visibleWhen|hiddenWhen|conditionalDialogue|storyFlagSet|storyFlagUnset|stepCompleted|stepNotCompleted" packages/map_core packages/map_runtime --type dart

rg "saveDataFromGameState|gameStateFromSaveData|normalizeLoadedGameState|completedStepIds|storyFlags|bag" packages --type dart

rg "NarrativeValidation|diagnoseNarrativeProject|stepReadNeverCompleted|completeStepNeverRead|flagReadNeverProduced|setFlagNeverRead" packages/map_core --type dart
```

Observations clés issues de l'audit :

```text
packages/map_core/lib/src/models/scenario_asset.dart contient ScenarioAsset.activationCondition.
packages/map_core/lib/src/models/script_conditions.dart contient flagIsSet / flagIsUnset.
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart contient setFlag, showMessage, giveItem et completeStep.
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart contient ScenarioNodeType.condition et trueBranch/falseBranch.
packages/map_core/lib/src/models/map_entity_payloads.dart contient storyFlagSet/storyFlagUnset/stepCompleted/stepNotCompleted.
packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart lit storyFlags et completedStepIds.
packages/map_core/lib/src/operations/game_state_persistence.dart contient saveDataFromGameState, gameStateFromSaveData et normalizeLoadedGameState.
packages/map_core/lib/src/operations/narrative_validator.dart contient les diagnostics flag/step read-write V0.
```

Recherche ciblée des modèles Quest/Story côté core :

```bash
rg --files packages/map_core/lib/src/models | rg "quest|side|story"
```

Sortie exacte :

```text

```

Interprétation : pas de fichier modèle Quest / SideQuest / Storyline dédié dans `map_core/lib/src/models`.

## 6. Quest / Storyline / Step existants

Existant côté core/runtime :

```text
ScenarioAsset : scènes/scénarios avec activationCondition, nodes, edges.
ScriptCondition : flagIsSet, flagIsUnset, allOf, anyOf, not.
ScenarioRuntimeExecutor : entityInteract, condition, showMessage, setFlag, giveItem, completeStep.
GameState : storyFlags, progression.completedStepIds, bag.
Persistence : saveDataFromGameState / gameStateFromSaveData / normalizeLoadedGameState.
World Rule : MapEntityNpcVisibilityRule + MapEntityConditionalDialogue.
Narrative Validator V0 : diagnostics flag/step read-write structurels.
```

Existant côté editor, hors scope runtime de ce lot :

```text
StepStudioDocument
StepStudioStep
GlobalStoryStudioDocument
GlobalStoryChapter
```

Conclusion :

```text
Les briques runtime/application sont suffisantes pour prouver une side quest V0.
Un modèle Quest dédié existe comme besoin futur éventuel, pas comme prérequis NS-GS-16.
```

## 7. Décision après audit

Cas retenu : **Cas A — Side Quest readiness existe déjà via facts/steps/scenes**.

Raison :

```text
Une quête optionnelle peut être authorée avec :
- un fact de disponibilité ;
- une scène entityInteract conditionnée ;
- un fact de démarrage ;
- une ou plusieurs steps optionnelles ;
- une scène finale avec condition ;
- une récompense simple via giveItem ;
- un fact/step de résolution ;
- une world rule de dialogue/visibilité ;
- save/load existant.
```

Implémentation choisie :

```text
Aucun code de production.
Un test de caractérisation runtime/application.
Un rapport et une mise à jour roadmap.
```

## 8. API ajoutée ou caractérisée

API ajoutée :

```text
Aucune.
```

API/comportements caractérisés :

```text
ScenarioRuntimeExecutor.dispatch(...)
ScenarioRuntimeSourceEvent.entityInteract(...)
kScenarioActionSetFlag
kScenarioActionCompleteStep
kScenarioActionGiveItem
kScenarioActionShowMessage
ScenarioNodeType.condition avec trueBranch/falseBranch
MapEntityRuntimePredicateEvaluator.isNpcPresentOnMap(...)
MapEntityRuntimePredicateEvaluator.resolveNpcDialogue(...)
saveDataFromGameState / gameStateFromSaveData / normalizeLoadedGameState
```

## 9. Flux Side Quest validé

Le test `side_quest_optional_storyline_readiness_test.dart` valide :

```text
New Game
→ quest unavailable avant prerequisite fact
→ prerequisite fact rend la quête disponible
→ interaction giver démarre la quête
→ started fact + started step
→ objective scene complète une objective step
→ objective fact miroir permet le branch final
→ final scene bloquée si objectif absent
→ final scene résolue si objectif présent
→ giveItem donne test_item_reward
→ completion fact + completion step
→ save/load conserve tout
→ world rule change dialogue/visibility
→ main story fact non requis et non muté
→ replay empêché par activationCondition
```

## 10. Disponibilité conditionnelle

Disponibilité prouvée à deux niveaux :

```text
ScenarioAsset.activationCondition flagIsSet(test_optional_quest_available_fact)
MapEntityNpcVisibilityRule visibleWhen storyFlagSet(test_optional_quest_available_fact)
```

Sans le fact de disponibilité, `ScenarioRuntimeExecutor.dispatch` retourne :

```text
ScenarioRuntimeExecutionStatus.noMatchingSource
```

## 11. Étapes optionnelles

Steps optionnelles prouvées :

```text
test_step_side_quest_started
test_step_side_quest_objective_done
test_step_side_quest_completed
```

Limite honnête :

```text
ScriptConditionType ne possède pas stepCompleted.
Pour brancher une scène finale, le test utilise donc le pattern V0 :
completeStep(test_step_side_quest_objective_done)
+ setFlag(test_step_side_quest_objective_done)
```

La step reste utilisée pour la progression/world rule ; le fact miroir sert au branching de scène.

## 12. Résolution finale

Avant objectif :

```text
ScenarioNodeType.condition false
→ kScenarioActionShowMessage
→ status executedEffect
→ aucun completion fact
→ aucun reward
```

Après objectif :

```text
ScenarioNodeType.condition true
→ kScenarioActionGiveItem
→ kScenarioActionSetFlag(test_side_quest_completed_fact)
→ kScenarioActionCompleteStep(test_step_side_quest_completed)
→ status reachedEnd
```

## 13. Récompense simple éventuelle

Reward simple prouvée via `kScenarioActionGiveItem` existant :

```text
itemId = test_item_reward
quantity = 1
GameState.bag.entries.single.itemId == test_item_reward
GameState.bag.entries.single.quantity == 1
```

Non-objectifs maintenus :

```text
pas de reward engine
pas de XP
pas de money
pas de catalogue item dédié
```

## 14. Save / load

Save/load prouvé par :

```dart
final reloaded = normalizeLoadedGameState(
  gameStateFromSaveData(saveDataFromGameState(state)),
);
```

État conservé :

```text
test_side_quest_started_fact
test_step_side_quest_objective_done comme fact miroir
test_side_quest_completed_fact
test_step_side_quest_started
test_step_side_quest_objective_done
test_step_side_quest_completed
test_item_reward x1 dans le Bag
```

## 15. World Rule / dialogue post-quest

Projection world rule prouvée :

```text
Before completion:
resolveNpcDialogue(...) → test_dialogue_before_quest

After completion:
resolveNpcDialogue(...) → test_dialogue_after_quest
```

Projection visibility prouvée :

```text
objective proxy visible avant completion
objective proxy caché après completion via hiddenWhen storyFlagSet(test_side_quest_completed_fact)
```

## 16. Main story isolation

Le test `main story fact is not required or mutated by optional quest` prouve que :

```text
test_main_story_fact absent au départ
quête complète exécutée
test_main_story_fact reste absent
test_side_quest_completed_fact est posé
```

Conclusion :

```text
Le flux optionnel ne dépend pas de la progression principale et ne la pollue pas.
```

## 17. Validator éventuel ou décision de report

Décision :

```text
Le Narrative Validator n'est pas modifié dans NS-GS-16.
```

Raison :

```text
Les diagnostics dédiés "quest completion impossible" ou "optional step never completed"
demanderaient un modèle Quest/SideQuest dédié.
Le validator V0 couvre déjà les erreurs structurelles utiles :
flagReadNeverProduced, setFlagNeverRead, stepReadNeverCompleted,
completeStepNeverRead, graph refs et unreachable nodes.
```

Suite possible :

```text
Quand un vrai modèle Quest/Storyline sera ajouté, un lot dédié pourra ajouter
des diagnostics spécifiques aux quêtes optionnelles.
```

## 18. Fichiers créés / modifiés

Créé :

```text
packages/map_runtime/test/side_quest_optional_storyline_readiness_test.dart
reports/gameplay/ns_gs_16_side_quest_optional_storyline_readiness.md
```

Modifié :

```text
MVP Selbrume/road_map.md
```

Non modifié :

```text
packages/map_runtime/lib
packages/map_core/lib
packages/map_gameplay/lib
packages/map_battle
packages/map_editor
examples/playable_runtime_host
```

## 19. Tests ajoutés ou modifiés

Fichier ajouté :

```text
packages/map_runtime/test/side_quest_optional_storyline_readiness_test.dart
```

Inventaire :

```text
725 lignes
SHA-256 444ed1e42d0a391fe38875c6ee3c0ab1233cbe4a2cbb8b14f9c6e0fcc81e2b67
14 tests
```

Liste complète des tests :

```text
37: optional quest is unavailable before prerequisite fact
59: optional quest becomes available after prerequisite fact
78: world rule hides optional quest giver before availability
87: starting optional quest sets started fact and step
105: optional objective step can be completed independently
128: optional quest final scene stays blocked before objective completion
153: optional quest final scene completes quest after objective step
175: optional quest can give simple item reward via giveItem
190: save/load preserves started objective completed and reward
222: world rule changes dialogue after optional quest completion
237: world rule can hide optional objective after completion
246: main story fact is not required or mutated by optional quest
256: side quest replay is prevented by completion condition
276: fixtures use only generic test ids
```

Fixture ids principaux :

```text
test_map
test_main_story_fact
test_optional_quest_available_fact
test_side_quest_started_fact
test_side_quest_completed_fact
test_optional_quest_giver
test_optional_objective_entity
test_optional_reward_entity
test_side_quest_start_scene
test_side_quest_objective_scene
test_side_quest_complete_scene
test_step_side_quest_started
test_step_side_quest_objective_done
test_step_side_quest_completed
test_item_reward
test_dialogue_before_quest
test_dialogue_after_quest
```

## 20. Commandes exécutées

Audit :

```bash
git status --short --untracked-files=all
rg "quest|Quest|sideQuest|SideQuest|optional|storyline|Storyline|chapter|Chapter|step|Step|progression|completedStep|completeStep|reward|Reward" packages --type dart
rg "ScenarioRuntimeSourceEvent|entityInteract|sourceOutcome|emitOutcome|setFlag|completeStep|giveItem|openDialogue|showMessage|condition|trueBranch|falseBranch" packages/map_core packages/map_runtime --type dart
rg "MapEntityRuntimePredicateEvaluator|visibleWhen|hiddenWhen|conditionalDialogue|storyFlagSet|storyFlagUnset|stepCompleted|stepNotCompleted" packages/map_core packages/map_runtime --type dart
rg "saveDataFromGameState|gameStateFromSaveData|normalizeLoadedGameState|completedStepIds|storyFlags|bag" packages --type dart
rg "NarrativeValidation|diagnoseNarrativeProject|stepReadNeverCompleted|completeStepNeverRead|flagReadNeverProduced|setFlagNeverRead" packages/map_core --type dart
```

Format :

```bash
dart format packages/map_runtime/test/side_quest_optional_storyline_readiness_test.dart
```

Tests :

```bash
cd packages/map_runtime && flutter test test/side_quest_optional_storyline_readiness_test.dart
cd packages/map_runtime && flutter test test/key_item_door_gate_readiness_test.dart
cd packages/map_runtime && flutter test test/item_pickup_give_item_readiness_test.dart
cd packages/map_runtime && flutter test test/world_rules_conditional_presence_readiness_test.dart
```

Analyzer :

```bash
cd packages/map_runtime && flutter analyze
cd packages/map_runtime && flutter analyze test/side_quest_optional_storyline_readiness_test.dart
```

Contrôles :

```bash
rg -n "Maël|mael|Lysa|lysa|Soline|soline|Selbrume|Bourg de Selbrume|Port des Brisants|map_bourg_selbrume|map_port_brisants|npc_mael|npc_lysa|npc_soline|trainer_lysa_port|battle_rival_port|scene_mael_intro|scene_rival_meet|yarn_mael_intro|yarn_rival_intro|Sproutle|Sparkitten|cristaux de sel|Goélise|clé du phare|cabane du phare|phare|goéland|cristaux" packages/map_runtime/test/side_quest_optional_storyline_readiness_test.dart
```

Final :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

## 21. Résultats des tests

### Test ciblé NS-GS-16

Commande :

```bash
cd packages/map_runtime && flutter test test/side_quest_optional_storyline_readiness_test.dart
```

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/side_quest_optional_storyline_readiness_test.dart
00:00 +0: Side Quest / Optional Storyline authoring readiness optional quest is unavailable before prerequisite fact
00:00 +1: Side Quest / Optional Storyline authoring readiness optional quest becomes available after prerequisite fact
00:00 +2: Side Quest / Optional Storyline authoring readiness world rule hides optional quest giver before availability
00:00 +3: Side Quest / Optional Storyline authoring readiness starting optional quest sets started fact and step
00:00 +4: Side Quest / Optional Storyline authoring readiness optional objective step can be completed independently
00:00 +5: Side Quest / Optional Storyline authoring readiness optional quest final scene stays blocked before objective completion
00:00 +6: Side Quest / Optional Storyline authoring readiness optional quest final scene completes quest after objective step
00:00 +7: Side Quest / Optional Storyline authoring readiness optional quest can give simple item reward via giveItem
00:00 +8: Side Quest / Optional Storyline authoring readiness save/load preserves started objective completed and reward
00:00 +9: Side Quest / Optional Storyline authoring readiness world rule changes dialogue after optional quest completion
00:00 +10: Side Quest / Optional Storyline authoring readiness world rule can hide optional objective after completion
00:00 +11: Side Quest / Optional Storyline authoring readiness main story fact is not required or mutated by optional quest
00:00 +12: Side Quest / Optional Storyline authoring readiness side quest replay is prevented by completion condition
00:00 +13: Side Quest / Optional Storyline authoring readiness fixtures use only generic test ids
00:00 +14: All tests passed!
```

### Régression NS-GS-15

Commande :

```bash
cd packages/map_runtime && flutter test test/key_item_door_gate_readiness_test.dart
```

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/key_item_door_gate_readiness_test.dart
00:00 +0: Key Item / Door Gate authoring readiness door gate stays blocked without required key fact
00:00 +1: Key Item / Door Gate authoring readiness bag key alone does not satisfy the derived fact gate
00:00 +2: Key Item / Door Gate authoring readiness door gate opens with required key fact
00:00 +3: Key Item / Door Gate authoring readiness door gate can set unlock fact and complete step
00:00 +4: Key Item / Door Gate authoring readiness key pickup gives item and derives key fact
00:00 +5: Key Item / Door Gate authoring readiness scenario can use giveItem result to unlock gate via fact pattern
00:00 +6: Key Item / Door Gate authoring readiness save/load preserves key item, key fact, and gate unlock state
00:00 +7: Key Item / Door Gate authoring readiness world rule pattern switches from closed gate proxy to open gate proxy
00:00 +8: Key Item / Door Gate authoring readiness world rule pattern can project completed gate step
00:00 +9: Key Item / Door Gate authoring readiness blocked branch is deterministic and does not mutate state
00:00 +10: Key Item / Door Gate authoring readiness fixtures use only generic test ids
00:00 +11: All tests passed!
```

### Régression NS-GS-14

Commande :

```bash
cd packages/map_runtime && flutter test test/item_pickup_give_item_readiness_test.dart
```

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart
00:00 +0: Item Pickup / GiveItem authoring readiness new game starts with empty bag
00:00 +1: Item Pickup / GiveItem authoring readiness giveItem action adds item with quantity
00:00 +2: Item Pickup / GiveItem authoring readiness giveItem action accumulates quantity when item already exists
00:00 +3: Item Pickup / GiveItem authoring readiness giveItem action blocks when itemId is missing
00:00 +4: Item Pickup / GiveItem authoring readiness giveItem action blocks when itemId is blank
00:00 +5: Item Pickup / GiveItem authoring readiness giveItem action defaults missing or invalid quantity to one
00:00 +6: Item Pickup / GiveItem authoring readiness giveItem action blocks non-positive quantity
00:00 +7: Item Pickup / GiveItem authoring readiness scenario item pickup gives item and records fact and step
00:00 +8: Item Pickup / GiveItem authoring readiness save/load preserves bag item quantity, pickup fact, and step
00:00 +9: Item Pickup / GiveItem authoring readiness scenario activation condition prevents a second pickup
00:00 +10: Item Pickup / GiveItem authoring readiness world rule pattern hides pickup proxy after pickup fact
00:00 +11: Item Pickup / GiveItem authoring readiness playable item entity interaction dispatches pickup scenario
[runtime] Map loaded: test_map, spawn at (0, 0)
[interact] Item: test_pickup_entity
[runtime] local scenario "test_pickup_scene" marked completed (predicate cutsceneCompleted).
[step_studio_trace] completion_applied scenario=test_pickup_scene origin=dispatch:entityInteract completedSteps=[test_step_pickup_done] completedCutscenes=[test_pickup_scene]
[scenario_runtime] source=entityInteract map=test_map trigger=- entity=test_pickup_entity status=reachedEnd scenario=test_pickup_scene sourceNode=test_source_pickup stopNode=test_end_pickup message=Flow terminé sur End.
00:00 +12: Item Pickup / GiveItem authoring readiness fixtures use only generic test ids
00:00 +13: All tests passed!
```

### Régression World Rules

Commande :

```bash
cd packages/map_runtime && flutter test test/world_rules_conditional_presence_readiness_test.dart
```

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/world_rules_conditional_presence_readiness_test.dart
00:00 +0: Facts / story flags storyFlagSet true when fact is present
00:00 +1: Facts / story flags storyFlagSet false when fact is absent
00:00 +2: Facts / story flags storyFlagUnset true when fact is absent
00:00 +3: Facts / story flags storyFlagUnset false when fact is present
00:00 +4: Steps stepCompleted true after completion
00:00 +5: Steps stepNotCompleted true before completion
00:00 +6: Steps stepNotCompleted false after completion
00:00 +7: Cutscenes cutsceneCompleted true when cutscene completed
00:00 +8: Cutscenes cutsceneCompleted false when not completed
00:00 +9: Cutscenes cutsceneNotCompleted true when not completed
00:00 +10: Cutscenes cutsceneNotCompleted false when completed
00:00 +11: Chapters chapterCompleted true when all steps completed
00:00 +12: Chapters chapterCompleted false when partial steps completed
00:00 +13: Chapters chapterNotCompleted true when chapter incomplete
00:00 +14: Chapters chapterNotCompleted false when chapter complete
00:00 +15: Conditional dialogue default dialogue when no condition matches
00:00 +16: Conditional dialogue conditional dialogue selected by fact
00:00 +17: Conditional dialogue conditional dialogue selected by step completion
00:00 +18: Conditional dialogue first matching conditional dialogue wins (priority order)
00:00 +19: Visibility rules visibleWhen: NPC present when flag set
00:00 +20: Visibility rules visibleWhen: NPC absent when flag not set
00:00 +21: Visibility rules hiddenWhen: NPC hidden when step completed
00:00 +22: Visibility rules hiddenWhen: NPC visible when step not yet completed
00:00 +23: Visibility rules always mode: NPC always present regardless of state
00:00 +24: Visibility rules no visibility rule: NPC present by default
00:00 +25: Save / reload consistency visibility rule result preserved after save/load
00:00 +26: Save / reload consistency conditional dialogue result preserved after save/load
00:00 +27: Recalculation after mutation visibility changes when flag is set
00:00 +28: Recalculation after mutation dialogue changes when step is completed
00:00 +29: Recalculation after mutation visibility changes when step is completed (hiddenWhen)
00:00 +30: does not hardcode any Selbrume ids
00:00 +31: All tests passed!
```

## 22. Résultat analyzer

Commande package :

```bash
cd packages/map_runtime && flutter analyze
```

Sortie contrôlée :

```text
Analyzing map_runtime...
352 issues found. (ran in 1.6s)
```

La commande retourne exit code 1 au niveau package à cause de diagnostics `info` préexistants.

Contrôle ciblé du fichier NS-GS-16 dans la sortie package :

```bash
rg -n "side_quest_optional_storyline_readiness_test" /tmp/ns_gs_16_map_runtime_analyze.txt || true
```

Sortie exacte :

```text

```

Commande ciblée :

```bash
cd packages/map_runtime && flutter analyze test/side_quest_optional_storyline_readiness_test.dart
```

Sortie exacte :

```text
Analyzing side_quest_optional_storyline_readiness_test.dart...

No issues found! (ran in 1.3s)
```

Conclusion :

```text
Analyze package non clean : 352 diagnostics info préexistants.
Aucun diagnostic ne pointe vers le fichier ajouté par NS-GS-16.
Analyze ciblé NS-GS-16 : clean.
```

## 23. Résultat git diff --check

Commande :

```bash
git diff --check
```

Sortie exacte :

```text

```

Exit code : `0`.

## 24. Mise à jour road_map.md

Mise à jour effectuée :

```text
NS-GS-16 marqué ✅ dans la roadmap synthétique.
NS-GS-17 marqué 🔜 comme prochain lot exact.
Section "Prochain lot exact" mise à jour vers NS-GS-17.
Section "Mise à jour NS-GS-16 — 2026-05-24" ajoutée.
```

Diff roadmap :

```diff
diff --git a/MVP Selbrume/road_map.md b/MVP Selbrume/road_map.md
index 6a6aef2f..58b75a4d 100644
--- a/MVP Selbrume/road_map.md
+++ b/MVP Selbrume/road_map.md
@@ -571,23 +571,23 @@ PHASE 5 — Sécurité no-code
 PHASE 6 — Extension gameplay
 ✅ NS-GS-14   — Item Pickup / GiveItem Authoring Readiness
 ✅ NS-GS-15   — Key Item / Door Gate Readiness
-🔜 NS-GS-16   — Side Quest / Optional Storyline Readiness
-   NS-GS-17   — Static Encounter / Boss Battle Readiness
+✅ NS-GS-16   — Side Quest / Optional Storyline Readiness
+🔜 NS-GS-17   — Static Encounter / Boss Battle Readiness
    NS-GS-18   — Reward / Money / XP Bridge Audit
 ```
 
 # Prochain lot exact
 
 ```text
-🔜 NS-GS-16 — Side Quest / Optional Storyline Readiness
+🔜 NS-GS-17 — Static Encounter / Boss Battle Readiness
 ```
 
 Périmètre :
 
 ```text
-Caractériser ou ajouter le flux générique Side Quest / Optional Storyline :
-quête annexe conditionnelle, steps optionnels, récompense simple,
-dialogue final, world rules liées et preuves runtime/application.
+Caractériser ou ajouter le flux générique Static Encounter / Boss Battle :
+interactable ou trigger lance un combat static/boss, outcomes victory/defeat/capture,
+post-battle facts, one-shot, save/load et world rules liées.
 Pas de fixtures Selbrume finales.
 Tests obligatoires.
 Mettre à jour MVP Selbrume/road_map.md.
@@ -838,3 +838,21 @@ Mettre à jour MVP Selbrume/road_map.md.
 | Mechanics-first | ✅ Brique générique authorable. Aucun contenu Selbrume final. Aucune fixture Selbrume finale. Aucun `project.json` Selbrume généré. |
 | Prochain lot | NS-GS-16 — Side Quest / Optional Storyline Readiness |
 | Rapport | `reports/gameplay/ns_gs_15_key_item_door_gate_readiness.md` |
+
+---
+
+# Mise à jour NS-GS-16 — 2026-05-24
+
+| Champ | Détail |
+|---|---|
+| Lot exécuté | NS-GS-16 — Side Quest / Optional Storyline Readiness |
+| Résultat | Flux générique Side Quest / Optional Storyline validé sans nouveau code de production : disponibilité conditionnelle → start fact/step → objective step optionnelle → final scene bloquée ou résolue → giveItem reward simple → completion fact/step → save/load → world rule dialogue/visibilité. |
+| Décision | Cas A : le pattern existe déjà via `ScenarioAsset`, `ScenarioRuntimeExecutor`, facts, `completeStep`, `giveItem`, save/load et `MapEntityRuntimePredicateEvaluator`. Aucun Quest Engine, Quest Studio, Quest UI ou reward engine n'a été ajouté. |
+| Fichiers | `packages/map_runtime/test/side_quest_optional_storyline_readiness_test.dart`, rapport NS-GS-16, `MVP Selbrume/road_map.md` |
+| Tests exécutés | `cd packages/map_runtime && flutter test test/side_quest_optional_storyline_readiness_test.dart` ; `cd packages/map_runtime && flutter test test/key_item_door_gate_readiness_test.dart` ; `cd packages/map_runtime && flutter test test/item_pickup_give_item_readiness_test.dart` ; `cd packages/map_runtime && flutter test test/world_rules_conditional_presence_readiness_test.dart` |
+| Analyzer | `cd packages/map_runtime && flutter analyze` → 352 diagnostics `info` préexistants au niveau package ; analyze ciblé du test NS-GS-16 → No issues found. |
+| git diff --check | À reporter dans `reports/gameplay/ns_gs_16_side_quest_optional_storyline_readiness.md` Evidence Pack final. |
+| Limites | Pas de modèle Quest dédié ; pas de Quest Journal/UI ; pas de reward engine ; pas de XP/money. Les conditions de scénario lisent des facts, donc l'objectif optionnel est représenté par step + fact miroir pour brancher la scène finale. |
+| Mechanics-first | ✅ Brique générique authorable. Aucun contenu Selbrume final. Aucune fixture Selbrume finale. Aucun `project.json` Selbrume généré. |
+| Prochain lot | NS-GS-17 — Static Encounter / Boss Battle Readiness |
+| Rapport | `reports/gameplay/ns_gs_16_side_quest_optional_storyline_readiness.md` |
```

## 25. Limites restantes

Limites assumées :

```text
Pas de Quest Engine.
Pas de Quest Journal.
Pas de Quest Studio complet.
Pas de modèle SideQuest dédié dans map_core.
Pas de reward engine.
Pas de XP / money rewards.
Pas de validation statique dédiée "quest completion impossible".
Pas de Flame-level PlayableMapGame complet pour ce flux.
```

Limite technique utile :

```text
Scenario conditions lisent des facts, pas directement completedStepIds.
Pour la scène finale, le pattern V0 est donc step optionnelle + fact miroir.
Les world rules peuvent lire directement stepCompleted / stepNotCompleted.
```

## 26. Prochain lot recommandé

Prochain lot recommandé :

```text
NS-GS-17 — Static Encounter / Boss Battle Readiness
```

Raison :

```text
NS-GS-16 est utilisable et testé au niveau runtime/application.
La progression optionnelle, la reward simple, save/load et world rules sont prouvés.
Le prochain trou mécanique naturel est le combat static/boss authorable.
```

## 27. Evidence Pack

### Git status initial

```text

```

### Inventaire fichiers

```text
CRÉÉ    packages/map_runtime/test/side_quest_optional_storyline_readiness_test.dart
CRÉÉ    reports/gameplay/ns_gs_16_side_quest_optional_storyline_readiness.md
MODIFIÉ MVP Selbrume/road_map.md
```

### Preuve absence ids interdits dans le test NS-GS-16

Commande :

```bash
rg -n "Maël|mael|Lysa|lysa|Soline|soline|Selbrume|Bourg de Selbrume|Port des Brisants|map_bourg_selbrume|map_port_brisants|npc_mael|npc_lysa|npc_soline|trainer_lysa_port|battle_rival_port|scene_mael_intro|scene_rival_meet|yarn_mael_intro|yarn_rival_intro|Sproutle|Sparkitten|cristaux de sel|Goélise|clé du phare|cabane du phare|phare|goéland|cristaux" packages/map_runtime/test/side_quest_optional_storyline_readiness_test.dart
```

Sortie exacte :

```text

```

### Nouveau fichier de test

```text
packages/map_runtime/test/side_quest_optional_storyline_readiness_test.dart
725 lignes
SHA-256 444ed1e42d0a391fe38875c6ee3c0ab1233cbe4a2cbb8b14f9c6e0fcc81e2b67
```

Commande de preuve no-index exécutée après écriture du rapport :

```bash
git diff --no-index /dev/null packages/map_runtime/test/side_quest_optional_storyline_readiness_test.dart || true
```

Résultat no-index :

```text
exit_code=1
731 lignes dans /tmp/ns_gs_16_test_noindex.diff
SHA-256 e26aec8d156c2f0e931adcfe254f5d93a880c1af7fa67218e5cbe6af0117c533
```

### Rapport NS-GS-16

Commande de preuve no-index exécutée après écriture du rapport :

```bash
git diff --no-index /dev/null reports/gameplay/ns_gs_16_side_quest_optional_storyline_readiness.md || true
```

Résultat no-index :

```text
exit_code=1
993 lignes dans /tmp/ns_gs_16_report_noindex.diff
SHA-256 f989660cb73ba927d34a50e51fffb2de4226423c963c5dc2187bf1e5a52764c3
```

### git diff --stat

```text
MVP Selbrume/road_map.md | 30 ++++++++++++++++++++++++------
1 file changed, 24 insertions(+), 6 deletions(-)
```

### git diff --name-only

```text
MVP Selbrume/road_map.md
```

### git status final

```text
 M "MVP Selbrume/road_map.md"
?? packages/map_runtime/test/side_quest_optional_storyline_readiness_test.dart
?? reports/gameplay/ns_gs_16_side_quest_optional_storyline_readiness.md
```

## 28. Auto-review critique

Checklist :

```text
✅ Scope mechanics-first.
✅ Aucun contenu final Selbrume créé.
✅ Aucune fixture Selbrume finale créée.
✅ Aucun project.json Selbrume généré.
✅ Aucun code de production modifié.
✅ Aucun Quest Engine créé.
✅ Aucune UI de quêtes créée.
✅ Aucun reward engine créé.
✅ Pas de XP / money rewards.
✅ Tests ciblés NS-GS-16 passent.
✅ Régressions NS-GS-14/15/world rules passent.
✅ Analyze ciblé du nouveau test clean.
⚠️ Analyze package map_runtime reste non clean à cause de 352 diagnostics info préexistants.
✅ road_map.md mis à jour.
✅ NS-GS-17 recommandé seulement après validation du flux NS-GS-16.
```

Verdict :

```text
NS-GS-16 est validé au niveau runtime/application.
PokeMap dispose d'un flux générique Side Quest / Optional Storyline authorable
via facts, steps, scènes, giveItem, save/load et world rules.
```
