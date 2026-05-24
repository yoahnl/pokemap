# NS-GS-15 — Key Item / Door Gate Readiness

## 1. Résumé exécutif

NS-GS-15 valide un flux générique Key Item / Door Gate au niveau runtime/application sans ajouter de code de production.

Flux prouvé :

```text
key pickup générique
→ giveItem(test_item_key)
→ setFlag(test_key_fact)
→ save/load conserve Bag + fact
→ interaction test_locked_gate
→ condition de scène flagIsSet(test_key_fact)
→ branche bloquée avec showMessage si false
→ branche débloquée avec setFlag + completeStep si true
→ world rule proxy closed/open projette l'état
```

Conclusion honnête :

```text
Condition directe hasItem / bagContains : non existante et non ajoutée.
Pattern authoring recommandé : item clé → fact narratif dérivé au pickup.
Door Engine complet : non créé.
```

## 2. Roadmap lue et statut initial

Fichier lu avant modification :

```text
MVP Selbrume/road_map.md
```

Statut initial observé :

```text
✅ NS-GS-14   — Item Pickup / GiveItem Authoring Readiness
🔜 NS-GS-15   — Key Item / Door Gate Readiness
```

Le prochain lot exact indiqué était :

```text
🔜 NS-GS-15 — Key Item / Door Gate Readiness
```

## 3. Périmètre exact du lot

Inclus :

```text
audit conditions / Bag / gate / world rules
test de gate bloqué sans fact
test de gate débloqué avec fact
test de pickup clé générique via giveItem
test du pattern item → fact → gate
test save/load
test world rule closed/open proxy via fact et step
rapport et roadmap
```

Exclus :

```text
condition directe hasItem
Door Engine
système complet de clés
collisions/pathfinding
warp conditionnel
UI porte
UI inventaire
Item Catalogue
Key Item Library
map_editor UI
map_battle
project.json
contenu Selbrume final
```

## 4. Frontière Event / Scene / Bag / Gate / World Rule / Validator

Frontières appliquées :

```text
Event déclenche : entityInteract sur test_locked_gate ou test_key_pickup.
Scene orchestre : condition, message, setFlag, completeStep, giveItem.
Bag fournit l'état inventaire mais ne décide pas de la narration.
Gate V0 bloque ou laisse passer via condition de scène et facts.
World Rule projette : proxies closed/open visibles selon fact ou step.
Validator reste hors exécution et non modifié.
```

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
reports/gameplay/ns_gs_14_item_pickup_give_item_authoring_readiness.md
reports/gameplay/ns_gs_13_bis_evidence_pack_closure.md
reports/gameplay/ns_gs_13_narrative_validator_minimal_v0.md
reports/gameplay/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
reports/gameplay/ns_gs_10_world_rules_conditional_presence_readiness.md
reports/gameplay/ns_gs_07_step_completion_progression_hooks.md
```

Commandes d'audit obligatoires exécutées :

```bash
rg "hasItem|itemInBag|bagContains|Bag|bag|itemId|keyItem|door|gate|locked|unlock|blocked|condition|flagIsSet|flagIsUnset|stepCompleted|visibleWhen|hiddenWhen|interactable" packages --type dart

rg "ScriptCondition|ConditionKind|predicate|storyFlagSet|storyFlagUnset|stepCompleted|stepNotCompleted" packages/map_core packages/map_runtime --type dart

rg "MapEntityKind|MapEntity.*door|MapEntity.*item|MapEntity.*npc|hiddenWhen|visibleWhen|interaction|interactable" packages/map_core packages/map_runtime --type dart

rg "ScenarioRuntimeExecutionStatus.blocked|blocked|openDialogue|showMessage|notification|inspectorHeadline" packages/map_runtime --type dart
```

Commandes ciblées complémentaires :

```bash
rg -n "hasItem|itemInBag|bagContains|keyItem" packages/map_core/lib packages/map_gameplay/lib packages/map_runtime/lib --type dart || true
```

Sortie exacte :

```text

```

Preuve des conditions existantes :

```text
packages/map_core/lib/src/models/script_conditions.dart:44:  @JsonValue('flagIsSet')
packages/map_core/lib/src/models/script_conditions.dart:45:  flagIsSet,
packages/map_core/lib/src/models/script_conditions.dart:48:  @JsonValue('flagIsUnset')
packages/map_core/lib/src/models/script_conditions.dart:49:  flagIsUnset,
packages/map_core/lib/src/models/script_conditions.dart:64:  @JsonValue('fieldAbilityUnlocked')
packages/map_core/lib/src/models/script_conditions.dart:65:  fieldAbilityUnlocked,
packages/map_core/lib/src/models/script_conditions.dart:68:  @JsonValue('partyHasMove')
packages/map_core/lib/src/models/script_conditions.dart:69:  partyHasMove,
packages/map_core/lib/src/models/script_conditions.dart:76:  @JsonValue('eventIsConsumed')
packages/map_core/lib/src/models/script_conditions.dart:77:  eventIsConsumed,
packages/map_core/lib/src/models/script_conditions.dart:80:  @JsonValue('playerOnMap')
packages/map_core/lib/src/models/script_conditions.dart:81:  playerOnMap,
packages/map_gameplay/lib/src/script_condition_evaluator.dart:26:      case ScriptConditionType.flagIsSet:
packages/map_gameplay/lib/src/script_condition_evaluator.dart:28:      case ScriptConditionType.flagIsUnset:
packages/map_gameplay/lib/src/script_condition_evaluator.dart:36:      case ScriptConditionType.fieldAbilityUnlocked:
packages/map_gameplay/lib/src/script_condition_evaluator.dart:38:      case ScriptConditionType.partyHasMove:
packages/map_gameplay/lib/src/script_condition_evaluator.dart:40:      case ScriptConditionType.partyHasUsableMove:
packages/map_gameplay/lib/src/script_condition_evaluator.dart:42:      case ScriptConditionType.eventIsConsumed:
packages/map_gameplay/lib/src/script_condition_evaluator.dart:44:      case ScriptConditionType.playerOnMap:
```

Observations :

```text
ScriptConditionType ne contient pas hasItem / bagContains.
ScenarioRuntimeExecutor supporte les nodes condition et branches true/false.
ScenarioRuntimeExecutor supporte showMessage, setFlag, giveItem et completeStep.
MapEntityRuntimePredicateEvaluator supporte storyFlagSet/Unset et stepCompleted/NotCompleted.
MapEntityKind ne contient pas door ; un gate V0 doit être représenté par entité/proxy/scène.
MapEventDefinition mentionne déjà des événements de map à pages conditionnelles, mais ce lot reste sur ScenarioRuntimeExecutor car c'est le pont NS-GS courant.
```

## 6. Conditions / Bag / Gate existants

Conditions existantes utilisables :

```text
flagIsSet
flagIsUnset
variableEquals / greaterThan / lessThan
fieldAbilityUnlocked
partyHasMove / partyHasUsableMove
eventIsConsumed
playerOnMap
```

Bag existant :

```text
Bag / BagEntry dans GameState.
GameStateMutations.giveItem ajouté avant NS-GS-15 et prouvé par NS-GS-14.
saveDataFromGameState / gameStateFromSaveData conservent le Bag.
```

Gate existant :

```text
Pas de MapEntityKind.door.
Pas de Door Engine.
Pas de collision/pathfinding conditionnel.
Gate V0 authorable via entityInteract + ScenarioAsset + condition fact.
```

World Rule existante :

```text
MapEntityNpcVisibilityRule visibleWhen / hiddenWhen.
MapEntityRuntimePredicateKind storyFlagSet / storyFlagUnset / stepCompleted / stepNotCompleted.
Projection testable via proxy NPC closed/open.
```

## 7. Décision après audit

Cas retenu : **Cas B — Door Gate existe via facts, mais hasItem manque**.

Décision :

```text
Ne pas ajouter de code de production.
Ne pas modifier les modèles Freezed / JsonSerializable.
Ne pas lancer build_runner.
Ajouter uniquement un test de caractérisation runtime/application.
Documenter le pattern recommandé : giveItem d'un item clé pose aussi un fact narratif, puis la porte lit ce fact.
```

Pourquoi ne pas ajouter `hasItem` maintenant :

```text
Ajouter un nouveau ScriptConditionType demande une évolution de contrat JSON et generated files.
Le flux demandé est déjà authorable via fact/step sans créer de Door Engine.
Le lot NS-GS-15 est un readiness lot, pas un système complet de clés.
```

## 8. API ajoutée ou caractérisée

API ajoutée : aucune.

Comportements caractérisés :

```text
ScenarioRuntimeExecutor.dispatch avec source entityInteract.
ScenarioNodeType.condition avec ScriptConditionType.flagIsSet.
ScenarioEdgeKind.trueBranch / falseBranch.
kScenarioActionShowMessage.
kScenarioActionGiveItem.
kScenarioActionSetFlag.
kScenarioActionCompleteStep.
saveDataFromGameState / gameStateFromSaveData / normalizeLoadedGameState.
MapEntityRuntimePredicateEvaluator.isNpcPresentOnMap.
```

## 9. Flux Key Item / Door Gate validé

Flux validé par `packages/map_runtime/test/key_item_door_gate_readiness_test.dart` :

```text
New Game
→ key pickup scene donne test_item_key
→ key pickup scene pose test_key_fact
→ gate scene lit test_key_fact
→ false branch : showMessage(test_blocked_dialogue), aucun unlock fact/step
→ true branch : setFlag(test_gate_unlocked_fact), completeStep(test_step_gate_unlocked)
→ save/load conserve Bag + facts + step
→ world rule closed/open proxy reflète le fact ou la step
```

## 10. Pattern hasItem direct ou fact dérivé

Condition directe hasItem :

```text
Non prouvée.
Non existante.
Non ajoutée.
```

Pattern validé :

```text
giveItem(test_item_key)
→ setFlag(test_key_fact)
→ gate condition flagIsSet(test_key_fact)
```

Le test `bag key alone does not satisfy the derived fact gate` rend la limite explicite : un item dans le Bag ne suffit pas à ouvrir une scène fact-gated si l'authoring n'a pas posé le fact narratif dérivé.

## 11. Blocage / déblocage

Blocage prouvé :

```text
Sans test_key_fact, la condition de scène va vers falseBranch.
Le node test_gate_blocked_message déclenche kScenarioActionShowMessage.
Aucun unlock fact ni step n'est posé.
Deux interactions bloquées successives restent déterministes et ne mutent pas l'état.
```

Déblocage prouvé :

```text
Avec test_key_fact, la condition va vers trueBranch.
La scène pose test_gate_unlocked_fact.
La scène complète test_step_gate_unlocked.
Le flow atteint End.
```

## 12. Save / load

Preuve ciblée :

```text
Le test save/load exécute key pickup puis gate unlock.
Il convertit GameState → SaveData → GameState normalisé.
Après reload : Bag contient test_item_key x1, test_key_fact est actif, test_gate_unlocked_fact est actif, test_step_gate_unlocked est complétée.
```

## 13. World Rule / visibilité gate

Pattern world rule prouvé :

```text
test_closed_gate : hiddenWhen storyFlagSet(test_gate_unlocked_fact)
test_open_gate   : visibleWhen storyFlagSet(test_gate_unlocked_fact)
```

Résultat :

```text
Avant unlock : closed visible, open hidden.
Après unlock : closed hidden, open visible.
```

Pattern step également prouvé :

```text
test_step_closed_gate : hiddenWhen stepCompleted(test_step_gate_unlocked)
test_step_open_gate   : visibleWhen stepCompleted(test_step_gate_unlocked)
```

Limite :

```text
Le monde projeté est un proxy NPC, car les world rules existantes filtrent les NPC.
Ce lot ne crée pas de visibilité conditionnelle directe pour MapEntityKind.custom, item ou door.
```

## 14. Validator éventuel ou décision de report

Le Narrative Validator n'a pas été modifié.

Raison :

```text
Aucune nouvelle condition hasItem n'a été ajoutée.
Le pattern fact dérivé utilise déjà flagIsSet / setFlag, couverts par le validator narratif V0.
Il n'existe pas encore de registre item fiable pour valider unknown itemId.
```

Suite possible :

```text
Un futur lot dédié peut ajouter des diagnostics hasItemMissingItemId / hasItemInvalidQuantity si une condition hasItem est introduite.
```

## 15. Fichiers créés / modifiés

Créés :

```text
packages/map_runtime/test/key_item_door_gate_readiness_test.dart
reports/gameplay/ns_gs_15_key_item_door_gate_readiness.md
```

Modifié :

```text
MVP Selbrume/road_map.md
```

Aucun fichier de production modifié.

## 16. Tests ajoutés ou modifiés

Nouveau fichier :

```text
packages/map_runtime/test/key_item_door_gate_readiness_test.dart
```

Inventaire :

```text
507 lignes
SHA-256 b59a5fd36f5a54cae0bee1533435da64ef6febf413d5a4d344e3b248648d4381
11 tests
```

Liste complète des tests :

```text
door gate stays blocked without required key fact
bag key alone does not satisfy the derived fact gate
door gate opens with required key fact
door gate can set unlock fact and complete step
key pickup gives item and derives key fact
scenario can use giveItem result to unlock gate via fact pattern
save/load preserves key item, key fact, and gate unlock state
world rule pattern switches from closed gate proxy to open gate proxy
world rule pattern can project completed gate step
blocked branch is deterministic and does not mutate state
fixtures use only generic test ids
```

Fixtures exécutées :

```text
test_map
test_locked_gate
test_key_pickup
test_item_key
test_key_fact
test_gate_unlocked_fact
test_step_gate_unlocked
test_gate_scene
test_key_pickup_scene
test_closed_gate
test_open_gate
test_step_closed_gate
test_step_open_gate
test_blocked_dialogue
```

## 17. Commandes exécutées

Audit :

```bash
git status --short --untracked-files=all
rg "hasItem|itemInBag|bagContains|Bag|bag|itemId|keyItem|door|gate|locked|unlock|blocked|condition|flagIsSet|flagIsUnset|stepCompleted|visibleWhen|hiddenWhen|interactable" packages --type dart
rg "ScriptCondition|ConditionKind|predicate|storyFlagSet|storyFlagUnset|stepCompleted|stepNotCompleted" packages/map_core packages/map_runtime --type dart
rg "MapEntityKind|MapEntity.*door|MapEntity.*item|MapEntity.*npc|hiddenWhen|visibleWhen|interaction|interactable" packages/map_core packages/map_runtime --type dart
rg "ScenarioRuntimeExecutionStatus.blocked|blocked|openDialogue|showMessage|notification|inspectorHeadline" packages/map_runtime --type dart
rg -n "hasItem|itemInBag|bagContains|keyItem" packages/map_core/lib packages/map_gameplay/lib packages/map_runtime/lib --type dart || true
```

Tests :

```bash
cd packages/map_runtime && flutter test test/key_item_door_gate_readiness_test.dart
cd packages/map_runtime && flutter test test/item_pickup_give_item_readiness_test.dart
cd packages/map_runtime && flutter test test/world_rules_conditional_presence_readiness_test.dart
```

Analyze :

```bash
cd packages/map_runtime && flutter analyze
cd packages/map_runtime && flutter analyze test/key_item_door_gate_readiness_test.dart
```

Final :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

## 18. Résultats des tests

### Test ciblé NS-GS-15

Commande :

```bash
cd packages/map_runtime && flutter test test/key_item_door_gate_readiness_test.dart
```

Sortie exacte :

```text
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

### Régression world rules

Commande :

```bash
cd packages/map_runtime && flutter test test/world_rules_conditional_presence_readiness_test.dart
```

Sortie exacte :

```text
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

## 19. Résultat analyzer

Commande package :

```bash
cd packages/map_runtime && flutter analyze
```

Résultat exact synthétique :

```text
exit=1
356 lignes de sortie
352 issues found. (ran in 2.6s)
```

Vérification ciblée dans la sortie package :

```bash
rg -n "key_item_door_gate_readiness_test\.dart" /tmp/ns_gs_15_map_runtime_analyze.txt || true
```

Sortie exacte :

```text

```

Conclusion :

```text
`flutter analyze` n'est pas clean au niveau package map_runtime : 352 diagnostics `info` préexistants.
Aucun diagnostic de cette sortie ne pointe vers le fichier ajouté par NS-GS-15.
```

Commande ciblée :

```bash
cd packages/map_runtime && flutter analyze test/key_item_door_gate_readiness_test.dart
```

Sortie exacte :

```text
Analyzing key_item_door_gate_readiness_test.dart...

No issues found! (ran in 1.3s)
```

## 20. Résultat git diff --check

Commande :

```bash
git diff --check
```

Sortie exacte :

```text

```

Résultat : OK.

## 21. Mise à jour road_map.md

`MVP Selbrume/road_map.md` a été mis à jour :

```text
NS-GS-15 passe en ✅.
NS-GS-16 devient le prochain lot recommandé.
Une entrée "Mise à jour NS-GS-15 — 2026-05-24" documente résultat, décision, fichiers, tests, analyzer, limites, mechanics-first et absence de contenu Selbrume.
```

## 22. Limites restantes

Limites volontaires :

```text
Pas de condition directe hasItem / bagContains.
Pas de Door Engine.
Pas de collision/pathfinding conditionnel.
Pas de warp conditionnel.
Pas de UI porte.
Pas de UI inventaire.
Pas d'Item Catalogue.
Pas de Key Item Library.
Pas de validator item ajouté.
```

Limite précise :

```text
Le gate V0 dépend d'un fact dérivé. L'authoring doit poser test_key_fact au moment du pickup ou de l'obtention de l'item clé.
```

## 23. Prochain lot recommandé

Prochain lot recommandé :

```text
NS-GS-16 — Side Quest / Optional Storyline Readiness
```

Raison :

```text
NS-GS-15 prouve maintenant qu'un état optionnel (item dérivé en fact, fact, step) peut bloquer/débloquer une interaction.
La suite naturelle est une storyline optionnelle complète qui consomme ces mêmes briques.
```

## 24. Evidence Pack

### 24.1 Git status initial exact

```text

```

### 24.2 Fichiers créés / modifiés

```text
MVP Selbrume/road_map.md
packages/map_runtime/test/key_item_door_gate_readiness_test.dart
reports/gameplay/ns_gs_15_key_item_door_gate_readiness.md
```

### 24.3 Diff hunk de road_map.md

```diff
 PHASE 6 — Extension gameplay
 ✅ NS-GS-14   — Item Pickup / GiveItem Authoring Readiness
-🔜 NS-GS-15   — Key Item / Door Gate Readiness
-   NS-GS-16   — Side Quest / Optional Storyline Readiness
+✅ NS-GS-15   — Key Item / Door Gate Readiness
+🔜 NS-GS-16   — Side Quest / Optional Storyline Readiness
```

```diff
-🔜 NS-GS-15 — Key Item / Door Gate Readiness
+🔜 NS-GS-16 — Side Quest / Optional Storyline Readiness
```

### 24.4 Preuve du fichier de test untracked

Commande :

```bash
git diff --no-index /dev/null packages/map_runtime/test/key_item_door_gate_readiness_test.dart || true
```

Sortie de contrôle :

```text
no_index_exit=1
     513 /tmp/ns_gs_15_key_item_test_no_index.diff
Premières lignes :
diff --git a/packages/map_runtime/test/key_item_door_gate_readiness_test.dart b/packages/map_runtime/test/key_item_door_gate_readiness_test.dart
new file mode 100644
index 00000000..416a8908
--- /dev/null
+++ b/packages/map_runtime/test/key_item_door_gate_readiness_test.dart
@@ -0,0 +1,507 @@
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_gameplay/map_gameplay.dart';
+import 'package:map_runtime/map_runtime.dart';
+import 'package:map_runtime/src/application/global_story_chapter_runtime.dart';
+import 'package:map_runtime/src/application/map_entity_runtime_predicate_evaluator.dart';
Dernières lignes :
+MapEntityRuntimePredicateEvaluator _evaluator(GameState state) {
+  return MapEntityRuntimePredicateEvaluator(
+    gameState: state,
+    chapterIndex: const GlobalStoryChapterStepIndex(chapterIdToStepIds: {}),
+  );
+}
```

Le fichier de test est couvert par :

```text
chemin exact
nombre de lignes
hash SHA-256
liste complète des 11 tests
liste des fixtures exécutées
no-index diff de contrôle
sortie complète du test ciblé
```

### 24.5 Preuve absence ids Selbrume interdits

Commande :

```bash
rg -n "Maël|mael|Lysa|lysa|Soline|soline|Selbrume|Bourg de Selbrume|Port des Brisants|map_bourg_selbrume|map_port_brisants|npc_mael|npc_lysa|npc_soline|trainer_lysa_port|battle_rival_port|scene_mael_intro|scene_rival_meet|yarn_mael_intro|yarn_rival_intro|Sproutle|Sparkitten|cristaux de sel|Goélise|clé du phare|cabane du phare|phare" packages/map_runtime/test/key_item_door_gate_readiness_test.dart
```

Sortie exacte :

```text

```

### 24.6 Git diff --check final

Commande :

```bash
git diff --check
```

Sortie exacte :

```text

```

Résultat : OK.

### 24.7 Git diff --stat final

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 MVP Selbrume/road_map.md | 30 ++++++++++++++++++++++++------
 1 file changed, 24 insertions(+), 6 deletions(-)
```

### 24.8 Git diff --name-only final

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
MVP Selbrume/road_map.md
```

### 24.9 Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M "MVP Selbrume/road_map.md"
?? packages/map_runtime/test/key_item_door_gate_readiness_test.dart
?? reports/gameplay/ns_gs_15_key_item_door_gate_readiness.md
```

### 24.10 Preuve du rapport untracked

Commande :

```bash
git diff --no-index /dev/null reports/gameplay/ns_gs_15_key_item_door_gate_readiness.md || true
```

Sortie de contrôle :

```text
report_no_index_exit=1
Premières lignes :
diff --git a/reports/gameplay/ns_gs_15_key_item_door_gate_readiness.md b/reports/gameplay/ns_gs_15_key_item_door_gate_readiness.md
new file mode 100644
--- /dev/null
+++ b/reports/gameplay/ns_gs_15_key_item_door_gate_readiness.md
+# NS-GS-15 — Key Item / Door Gate Readiness
Dernières lignes :
+NS-GS-15 est validable.
+PokeMap dispose d'un flux générique Key Item / Door Gate authorable via fact dérivé, condition de scène et projection world rule.
+Prochain lot recommandé : NS-GS-16 — Side Quest / Optional Storyline Readiness.
```

## 25. Auto-review critique

Checklist :

```text
✅ Roadmap lue avant modification.
✅ Audit conditions / Bag / gate / world rules effectué.
✅ Aucun code de production modifié.
✅ Aucun contenu Selbrume final.
✅ Aucun project.json généré.
✅ Pas de Door Engine.
✅ Pas de collision/pathfinding.
✅ Pas de UI.
✅ Pas d'Item Catalogue.
✅ Pattern fact dérivé documenté honnêtement.
✅ Blocage prouvé.
✅ Déblocage prouvé.
✅ Save/load prouvé.
✅ World rule fact et step prouvées par proxy.
✅ Tests ciblés verts.
✅ Analyzer ciblé du nouveau test clean.
⚠️ Condition directe hasItem non prouvée et non ajoutée.
⚠️ Analyze package map_runtime non clean : 352 diagnostics info préexistants, aucun sur le fichier NS-GS-15.
```

Verdict :

```text
NS-GS-15 est validable.
PokeMap dispose d'un flux générique Key Item / Door Gate authorable via fact dérivé, condition de scène et projection world rule.
Prochain lot recommandé : NS-GS-16 — Side Quest / Optional Storyline Readiness.
```
