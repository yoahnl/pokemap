# NS-GS-14 — Item Pickup / GiveItem Authoring Readiness

## 1. Résumé exécutif

NS-GS-14 valide un flux générique Item Pickup / GiveItem authorable au niveau runtime/application.

Résultat principal :

```text
interaction item ou source entityInteract
→ scénario matching
→ action giveItem
→ GameState.bag mis à jour
→ setFlag / completeStep possibles
→ save/load conserve bag + fact + step
→ anti double pickup par condition de scénario
→ pattern world rule documenté avec proxy NPC
```

Le lot reste mechanics-first : aucun contenu final Selbrume, aucune fixture Selbrume finale, aucun `project.json` Selbrume.

## 2. Roadmap lue et statut initial

Fichier lu avant modification :

```text
MVP Selbrume/road_map.md
```

Statut initial observé :

```text
🔜 NS-GS-14 — Item Pickup / GiveItem Authoring Readiness
```

La roadmap rappelait aussi que `SEL-B1` avait déjà corrigé `giveItem → Bag`, donc le lot devait auditer l'existant avant toute implémentation.

## 3. Périmètre exact du lot

Inclus :

```text
audit giveItem / Bag / pickup existants
caractérisation de GameStateMutations.giveItem
ajout d'une action scénario minimale giveItem si nécessaire
preuve item interaction → scénario → Bag
preuve quantity
preuve save/load
preuve anti double pickup par condition
preuve world rule post-pickup au niveau pattern supporté
rapport et roadmap
```

Exclus :

```text
Item Catalogue
Bag UI
Item Studio
Shop
XP / money rewards
item effects
key item / door gate
map_editor UI
map_battle
contenu Selbrume final
project.json Selbrume
```

## 4. Frontière Event / Scene / Bag / World Rule / Validator

Frontières conservées :

```text
Event déclenche.
Scene orchestre.
Bag reçoit l'item.
Fact/Step mémorisent la progression.
World Rule projette l'état.
Validator diagnostique.
```

`giveItem` ne devient pas idempotent : il peut légitimement donner plusieurs fois le même item. L'anti double pickup est porté par `setFlag`, condition de scénario et/ou world rule.

## 5. Audit initial

Commande initiale obligatoire :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text

```

Fichiers lus :

```text
MVP Selbrume/road_map.md
reports/gameplay/ns_gs_13_bis_evidence_pack_closure.md
reports/gameplay/ns_gs_13_narrative_validator_minimal_v0.md
reports/gameplay/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
reports/gameplay/ns_gs_12_editor_authored_golden_slice_validation.md
reports/gameplay/ns_gs_07_step_completion_progression_hooks.md
reports/gameplay/ns_gs_06_bis_give_pokemon_runtime_payload_hardening.md
reports/gameplay/ns_gs_06_give_pokemon_minimal.md
reports/gameplay/ns_gs_08_npc_interaction_scene_authoring_readiness.md
reports/gameplay/ns_gs_10_world_rules_conditional_presence_readiness.md
```

Recherche d'anciens rapports item / bag / pickup :

```bash
find reports -type f | grep -iE "give.*item|item.*bag|bag|pickup|inventory|sel_b1|item_pickup" || true
```

Sortie exacte :

```text
reports/analysis/psdk_fight_gap_inventory.md
reports/previous/lot-9g-battle-bag-hyper-potion-support-report.md
reports/previous/lot-9e-battle-bag-potion-turn-commit-report.md
reports/previous/lot-9c-battle-bag-medicine-target-shell-report.md
reports/previous/lot-9f-battle-bag-super-potion-support-report.md
reports/previous/lot-9b-battle-bag-capture-wiring-report.md
reports/previous/lot-9d-battle-bag-potion-real-apply-report.md
reports/previous/lot-9h-battle-bag-max-potion-support-report.md
reports/previous/lot-8a-battle-bag-menu-contract-report.md
reports/previous/lot-9a-battle-bag-menu-ui-shell-report.md
reports/shadows/v1/shadow_lot_57_selbrume_shadow_inventory_runtime_instruction_debug_report.md
reports/gameplay/ns_gs_03_content_inventory_fixture_plan.md
reports/gameplay/audit/sel_b1_fix_give_item_to_bag.md
```

Recherches obligatoires exécutées :

```bash
rg "giveItem|GiveItem|itemId|quantity|bag|Bag|inventory|pickup|picked|pickedUp|collect|collectible" packages --type dart
rg "kScenarioActionGive|kScenarioAction.*Item|Scenario.*Item|actionKind.*item|payload.params.*item" packages/map_runtime packages/map_core packages/map_gameplay --type dart
rg "GameStateMutations|setFlag|completeStep|saveDataFromGameState|gameStateFromSaveData|normalizeLoadedGameState" packages --type dart
rg "hiddenWhen|visibleWhen|MapEntityRuntimePredicateEvaluator|isNpcPresentOnMap|resolveNpcDialogue|interactable" packages/map_core packages/map_runtime --type dart
```

Observations clés :

```text
GameStateMutations.giveItem existe déjà dans map_gameplay.
Bag / BagEntry existent dans map_core et sont persistés en save/load.
ScriptCommandType.giveItem existe déjà, mais ce n'est pas une action ScenarioRuntimeExecutor.
MapEntityKind.item et MapEntityItemData existent déjà.
ItemInteracted existait côté gameplay/runtime, mais PlayableMapGame ne dispatchait pas encore de scénario pour ce cas.
Les world rules de présence existantes sont centrées sur les NPC via isNpcPresentOnMap.
```

## 6. GiveItem / Bag existants

État audité :

```text
Mutation existante : GameStateMutations.giveItem(GameState state, String itemId, int quantity)
Package : packages/map_gameplay
Comportement : trim itemId, no-op si blank, no-op si quantity <= 0, accumulation de quantité via Bag.normalized().
Catégorie : medicine pour quelques ids connus, sinon items.
Idempotence : non. Donner deux fois additionne les quantités.
Persistence : Bag est porté par GameState et SaveData.
```

Tests de caractérisation existants relancés :

```bash
cd packages/map_gameplay && dart test test/game_state_mutations_test.dart
```

Sortie exacte :

```text
00:00 +0: loading test/game_state_mutations_test.dart
00:00 +0: GameStateMutations - giveItem giveItem adds a new item to an empty Bag
00:00 +1: GameStateMutations - giveItem giveItem adds a new item of default category items
00:00 +2: GameStateMutations - giveItem giveItem accumulates quantity if the item already exists
00:00 +3: GameStateMutations - giveItem giveItem preserves other items in the Bag
00:00 +4: GameStateMutations - giveItem giveItem does nothing (no-op) when quantity <= 0
00:00 +5: GameStateMutations - giveItem giveItem does nothing (no-op) when itemId is empty or whitespace-only
00:00 +6: All tests passed!
```

## 7. Décision après audit

Cas retenu : **Cas B — GiveItem existe, mais pickup readiness manque**.

Raison :

```text
giveItem et Bag existent déjà.
La persistence Bag existe déjà.
Le pont scénario actionKind=giveItem manquait dans ScenarioRuntimeExecutor.
L'interaction runtime ItemInteracted ne dispatchait pas encore entityInteract vers ScenarioRuntimeExecutor.
```

Implémentation choisie :

```text
Ajouter la plus petite action scénario générique kScenarioActionGiveItem.
Exporter la constante depuis map_runtime.dart.
Faire que PlayableMapGame tente le dispatch scénario pour ItemInteracted, avec fallback notification si aucun scénario ne matche.
Ajouter un test runtime/application ciblé.
```

## 8. API ajoutée ou caractérisée

API ajoutée :

```dart
const String kScenarioActionGiveItem = 'giveItem';
```

Payload supporté :

```text
itemId   : obligatoire, trim, bloque si absent ou blank.
quantity : optionnel, défaut 1 si absent ou non entier, bloque si <= 0.
```

Mutation utilisée :

```dart
GameStateMutations().giveItem(context.gameState, itemId, quantity)
```

API caractérisée :

```text
GameStateMutations.giveItem
Bag.normalized
saveDataFromGameState
gameStateFromSaveData
normalizeLoadedGameState
ScenarioRuntimeSourceEvent.entityInteract
MapEntityRuntimePredicateEvaluator.isNpcPresentOnMap
PlayableMapGame.handleRuntimeInputEvent(primary)
```

## 9. Flux Item Pickup validé

Flux validé par `packages/map_runtime/test/item_pickup_give_item_readiness_test.dart` :

```text
createNewGameState
→ bag vide
→ source entityInteract(test_map, test_pickup_entity)
→ kScenarioActionGiveItem(itemId=test_item_potion, quantity=2)
→ kScenarioActionSetFlag(test_pickup_done_fact)
→ kScenarioActionCompleteStep(test_step_pickup_done)
→ GameState.bag contient test_item_potion x2
→ save/load conserve bag + fact + step
→ activationCondition flagIsUnset empêche une deuxième exécution
→ proxy NPC hiddenWhen storyFlagSet démontre le pattern world rule
→ PlayableMapGame dispatch l'interaction item vers le scénario
```

## 10. Idempotence et anti double pickup

Décision :

```text
giveItem reste non-idempotent.
```

Preuve :

```text
Le test "giveItem action accumulates quantity when item already exists" prouve que donner test_item_potion x2 sur un Bag contenant déjà x3 produit x5.
```

Anti double pickup :

```text
Le test "scenario activation condition prevents a second pickup" prouve le pattern authoring : condition flagIsUnset(test_pickup_done_fact) sur le scénario.
Premier dispatch : success, item x2.
Second dispatch : noMatchingSource, quantité reste x2.
```

## 11. Save / load

Preuve ciblée :

```text
Le test "save/load preserves bag item quantity, pickup fact, and step" convertit GameState → SaveData → GameState normalisé.
Après reload : itemId=test_item_potion, quantity=2, fact actif, step complétée.
```

## 12. World Rule / visibilité post-pickup

Limite réelle :

```text
Les helpers world rules existants exposent isNpcPresentOnMap et resolveNpcDialogue.
Le modèle générique d'entité item existe, mais la projection de présence testée en NS-GS-10 est centrée NPC.
```

Preuve fournie :

```text
Le test "world rule pattern hides pickup proxy after pickup fact" utilise un proxy NPC générique avec hiddenWhen storyFlagSet(test_pickup_done_fact).
Avant pickup : proxy visible.
Après pickup : proxy caché.
```

Conclusion honnête :

```text
L'anti double pickup runtime est prouvé par condition de scénario.
La projection visuelle post-pickup est documentée au niveau world rule NPC/proxy.
La visibilité directe des MapEntityKind.item par world rule reste un futur lot si nécessaire.
```

## 13. Validator item éventuel ou décision de report

Aucun diagnostic item ajouté au Narrative Validator dans ce lot.

Raison :

```text
Le validator V0 reste narratif structurel.
Il n'existe pas encore de registre item fiable dans ProjectManifest à valider contre unknown itemId.
Ajouter giveItemMissingItemId / invalidQuantity au validator serait possible, mais non nécessaire pour prouver le flux runtime NS-GS-14.
```

Suite possible :

```text
Un futur lot de validation item peut ajouter giveItemMissingItemId / giveItemInvalidQuantity sans créer d'Item Catalogue.
```

## 14. Fichiers créés / modifiés

Créé :

```text
packages/map_runtime/test/item_pickup_give_item_readiness_test.dart
reports/gameplay/ns_gs_14_item_pickup_give_item_authoring_readiness.md
```

Modifiés :

```text
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/map_runtime.dart
MVP Selbrume/road_map.md
```

Aucun fichier modifié dans :

```text
packages/map_core/lib
packages/map_gameplay/lib
packages/map_battle
packages/map_editor
examples/playable_runtime_host
```

## 15. Tests ajoutés ou modifiés

Nouveau fichier :

```text
packages/map_runtime/test/item_pickup_give_item_readiness_test.dart
```

Nombre de tests : 13.

Liste complète :

```text
new game starts with empty bag
giveItem action adds item with quantity
giveItem action accumulates quantity when item already exists
giveItem action blocks when itemId is missing
giveItem action blocks when itemId is blank
giveItem action defaults missing or invalid quantity to one
giveItem action blocks non-positive quantity
scenario item pickup gives item and records fact and step
save/load preserves bag item quantity, pickup fact, and step
scenario activation condition prevents a second pickup
world rule pattern hides pickup proxy after pickup fact
playable item entity interaction dispatches pickup scenario
fixtures use only generic test ids
```

Fixtures exécutées :

```text
test_map
test_pickup_entity
test_item_potion
test_pickup_done_fact
test_step_pickup_done
test_pickup_scene
test_source_pickup
test_give_item
test_set_pickup_fact
test_complete_pickup_step
test_end_pickup
test_pickup_proxy
```

Tous les ids exécutés sont génériques.

## 16. Commandes exécutées

Audit :

```bash
git status --short --untracked-files=all
find reports -type f | grep -iE "give.*item|item.*bag|bag|pickup|inventory|sel_b1|item_pickup" || true
rg "giveItem|GiveItem|itemId|quantity|bag|Bag|inventory|pickup|picked|pickedUp|collect|collectible" packages --type dart
rg "kScenarioActionGive|kScenarioAction.*Item|Scenario.*Item|actionKind.*item|payload.params.*item" packages/map_runtime packages/map_core packages/map_gameplay --type dart
rg "GameStateMutations|setFlag|completeStep|saveDataFromGameState|gameStateFromSaveData|normalizeLoadedGameState" packages --type dart
rg "hiddenWhen|visibleWhen|MapEntityRuntimePredicateEvaluator|isNpcPresentOnMap|resolveNpcDialogue|interactable" packages/map_core packages/map_runtime --type dart
```

Tests :

```bash
cd packages/map_gameplay && dart test test/game_state_mutations_test.dart
cd packages/map_runtime && flutter test test/item_pickup_give_item_readiness_test.dart
cd packages/map_runtime && flutter test test/scenario_complete_step_test.dart
cd packages/map_runtime && flutter test test/world_rules_conditional_presence_readiness_test.dart
cd packages/map_runtime && flutter test test/scenario_give_pokemon_test.dart
```

Analyze :

```bash
cd packages/map_runtime && flutter analyze
cd packages/map_runtime && flutter analyze lib/src/application/scenario_runtime/scenario_runtime_executor.dart lib/src/presentation/flame/playable_map_game.dart lib/map_runtime.dart test/item_pickup_give_item_readiness_test.dart
```

Final :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

## 17. Résultats des tests

### Test ciblé NS-GS-14

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

### Régression completeStep

Commande :

```bash
cd packages/map_runtime && flutter test test/scenario_complete_step_test.dart
```

Sortie exacte :

```text
00:00 +0: ScenarioRuntimeExecutor - completeStep action completeStep action completes a step
00:00 +1: ScenarioRuntimeExecutor - completeStep action completeStep action advances the graph
00:00 +2: ScenarioRuntimeExecutor - completeStep action completeStep action calls onGameStateUpdated
00:00 +3: ScenarioRuntimeExecutor - completeStep action completeStep action blocks when stepId missing
00:00 +4: ScenarioRuntimeExecutor - completeStep action completeStep action blocks when stepId is blank
00:00 +5: ScenarioRuntimeExecutor - completeStep action completeStep action is idempotent when run twice
00:00 +6: ScenarioRuntimeExecutor - completeStep action completeStep feeds stepCompleted predicate
00:00 +7: ScenarioRuntimeExecutor - completeStep action uncompleted step feeds stepNotCompleted predicate
00:00 +8: All tests passed!
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

### Régression givePokemon

Commande :

```bash
cd packages/map_runtime && flutter test test/scenario_give_pokemon_test.dart
```

Sortie exacte :

```text
00:00 +0: ScenarioRuntimeExecutor - givePokemon action givePokemon action adds Pokemon to party
00:00 +1: ScenarioRuntimeExecutor - givePokemon action givePokemon uses defaults for optional params
00:00 +2: ScenarioRuntimeExecutor - givePokemon action givePokemon blocks when speciesId is missing
00:00 +3: ScenarioRuntimeExecutor - givePokemon action givePokemon with preventDuplicate prevents double give
00:00 +4: ScenarioRuntimeExecutor - givePokemon action givePokemon accepts knownMoveIds from payload
00:00 +5: ScenarioRuntimeExecutor - givePokemon action givePokemon trims knownMoveIds
00:00 +6: ScenarioRuntimeExecutor - givePokemon action givePokemon accepts currentHp from payload
00:00 +7: ScenarioRuntimeExecutor - givePokemon action givePokemon defaults currentHp to level when absent
00:00 +8: ScenarioRuntimeExecutor - givePokemon action givePokemon handles invalid currentHp safely
00:00 +9: All tests passed!
```

### Régression mutation gameplay

Commande :

```bash
cd packages/map_gameplay && dart test test/game_state_mutations_test.dart
```

Sortie exacte :

```text
00:00 +0: loading test/game_state_mutations_test.dart
00:00 +0: GameStateMutations - giveItem giveItem adds a new item to an empty Bag
00:00 +1: GameStateMutations - giveItem giveItem adds a new item of default category items
00:00 +2: GameStateMutations - giveItem giveItem accumulates quantity if the item already exists
00:00 +3: GameStateMutations - giveItem giveItem preserves other items in the Bag
00:00 +4: GameStateMutations - giveItem giveItem does nothing (no-op) when quantity <= 0
00:00 +5: GameStateMutations - giveItem giveItem does nothing (no-op) when itemId is empty or whitespace-only
00:00 +6: All tests passed!
```

## 18. Résultat analyzer

Commande package :

```bash
cd packages/map_runtime && flutter analyze
```

Résultat exact synthétique :

```text
exit=1
356 lignes de sortie
352 issues found. (ran in 1.7s)
```

Vérification ciblée dans la sortie package :

```bash
rg -n "scenario_runtime_executor\.dart|playable_map_game\.dart|map_runtime\.dart|item_pickup_give_item_readiness_test\.dart" /tmp/ns_gs_14_map_runtime_analyze.txt || true
```

Sortie exacte :

```text

```

Conclusion :

```text
`flutter analyze` n'est pas clean au niveau package map_runtime : 352 diagnostics `info` préexistants.
Aucun diagnostic de cette sortie ne pointe vers les fichiers ajoutés ou modifiés par NS-GS-14.
```

Commande ciblée sur les fichiers NS-GS-14 :

```bash
cd packages/map_runtime && flutter analyze lib/src/application/scenario_runtime/scenario_runtime_executor.dart lib/src/presentation/flame/playable_map_game.dart lib/map_runtime.dart test/item_pickup_give_item_readiness_test.dart
```

Sortie exacte :

```text
Analyzing 4 items...

No issues found! (ran in 1.4s)
```

## 19. Résultat git diff --check

Commande :

```bash
git diff --check
```

Sortie exacte :

```text

```

Résultat : OK.

## 20. Mise à jour road_map.md

`MVP Selbrume/road_map.md` a été mis à jour :

```text
NS-GS-14 passe en ✅.
NS-GS-15 devient le prochain lot recommandé.
Une entrée "Mise à jour NS-GS-14 — 2026-05-24" documente résultat, décision, fichiers, tests, analyzer, limites, mechanics-first et absence de contenu Selbrume.
```

## 21. Limites restantes

Limites volontaires :

```text
Pas d'Item Catalogue.
Pas de validation unknown itemId par registre.
Pas de Bag UI.
Pas de pickup UI dédiée.
Pas d'item effects.
Pas de shop.
Pas de rewards XP/money.
Pas de key item / door gate.
Pas de project.json Selbrume.
```

Limite technique précise :

```text
La world rule de visibilité prouvée est le pattern NPC/proxy existant.
La présence directe des MapEntityKind.item par world rule n'est pas encore une API dédiée.
```

## 22. Prochain lot recommandé

Prochain lot recommandé :

```text
NS-GS-15 — Key Item / Door Gate Readiness
```

Raison :

```text
NS-GS-14 donne maintenant un item au Bag et peut poser fact/step.
La suite naturelle est d'utiliser ce state pour débloquer/bloquer une porte ou interaction générique.
```

## 23. Evidence Pack

### 23.1 Git status initial exact

```text

```

### 23.2 Fichiers créés / modifiés

```text
MVP Selbrume/road_map.md
packages/map_runtime/lib/map_runtime.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/test/item_pickup_give_item_readiness_test.dart
reports/gameplay/ns_gs_14_item_pickup_give_item_authoring_readiness.md
```

### 23.3 Diff hunks des fichiers de production modifiés

```diff
diff --git a/packages/map_runtime/lib/map_runtime.dart b/packages/map_runtime/lib/map_runtime.dart
@@
         kScenarioActionStartTrainerBattle,
         kScenarioActionGivePokemon,
+        kScenarioActionGiveItem,
         kScenarioActionCompleteStep,
```

```diff
diff --git a/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart b/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
@@
 const String kScenarioActionGivePokemon = 'givePokemon';
 
+/// Action scénario : donne un item au joueur.
+///
+/// Paramètres lus depuis `ScenarioNodePayload.params` :
+/// - `itemId` (obligatoire) : identifiant de l'item.
+/// - `quantity` (optionnel, défaut 1) : quantité à ajouter au Bag.
+///
+/// La mutation est appliquée via [GameStateMutations.giveItem].
+/// L'anti double pickup reste porté par un flag/condition/world rule.
+const String kScenarioActionGiveItem = 'giveItem';
+
@@
+            case kScenarioActionGiveItem:
+              final itemId = node.payload.params['itemId']?.trim() ?? '';
+              if (itemId.isEmpty) {
+                return ScenarioRuntimeExecutionResult(
+                  status: ScenarioRuntimeExecutionStatus.blocked,
+                  effect: const ScenarioRuntimeEffect.none(),
+                  scenarioId: scenario.id,
+                  sourceNodeId: sourceId,
+                  stopNodeId: node.id,
+                  message: 'Action giveItem sans itemId dans "${node.id}".',
+                );
+              }
+              final quantity = int.tryParse(
+                    node.payload.params['quantity']?.trim() ?? '',
+                  ) ??
+                  1;
+              if (quantity <= 0) {
+                return ScenarioRuntimeExecutionResult(
+                  status: ScenarioRuntimeExecutionStatus.blocked,
+                  effect: const ScenarioRuntimeEffect.none(),
+                  scenarioId: scenario.id,
+                  sourceNodeId: sourceId,
+                  stopNodeId: node.id,
+                  message:
+                      'Action giveItem avec quantity non positive dans "${node.id}".',
+                );
+              }
+
+              const itemMutations = GameStateMutations();
+              final nextItemState = itemMutations.giveItem(
+                context.gameState,
+                itemId,
+                quantity,
+              );
+              context.gameState = nextItemState;
+              context.onGameStateUpdated(nextItemState);
+              final nextAfterItem = _pickLinearNextNodeId(
+                nodeId: node.id,
+                edges: scenario.edges,
+              );
+              if (nextAfterItem == null) {
+                return ScenarioRuntimeExecutionResult(
+                  status: ScenarioRuntimeExecutionStatus.reachedEnd,
+                  effect: const ScenarioRuntimeEffect.none(),
+                  scenarioId: scenario.id,
+                  sourceNodeId: sourceId,
+                  stopNodeId: node.id,
+                  message: 'Item "$itemId" x$quantity donné. Fin du flow.',
+                );
+              }
+              currentNodeId = nextAfterItem;
```

```diff
diff --git a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
@@
       case ItemInteracted(:final entity):
         debugPrint('[interact] Item: ${entity.id}');
-        _showNotification(entity.inspectorHeadline);
+        scenarioHandledEntityInteraction =
+            _tryDispatchScenarioEntityInteraction(
+          entity.id,
+        );
+        if (!scenarioHandledEntityInteraction) {
+          _showNotification(entity.inspectorHeadline);
+        }
```

### 23.4 Preuve du fichier de test untracked

Inventaire :

```text
Chemin : packages/map_runtime/test/item_pickup_give_item_readiness_test.dart
Lignes : 474
Tests : 13
Project fixture disque repo : non
project.json Selbrume : non
Fichiers temporaires : uniquement Directory.systemTemp dans le test PlayableMapGame
```

Commande de preuve non-index :

```bash
git diff --no-index /dev/null packages/map_runtime/test/item_pickup_give_item_readiness_test.dart || true
```

Sortie de contrôle :

```text
test_no_index_exit=1
     480 /tmp/ns_gs_14_item_pickup_test_no_index.diff
Premières lignes :
diff --git a/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart b/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart
new file mode 100644
index 00000000..042db8a2
--- /dev/null
+++ b/packages/map_runtime/test/item_pickup_give_item_readiness_test.dart
@@ -0,0 +1,474 @@
+import 'dart:convert';
+import 'dart:io';
+
+import 'package:flame/components.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_gameplay/map_gameplay.dart';
+import 'package:map_runtime/map_runtime.dart';
+import 'package:map_runtime/src/application/global_story_chapter_runtime.dart';
+import 'package:map_runtime/src/application/map_entity_runtime_predicate_evaluator.dart';
+import 'package:path/path.dart' as p;
Dernières lignes :
+class _LoadedPlayableMapGame extends PlayableMapGame {
+  _LoadedPlayableMapGame({
+    required super.bundle,
+    required super.projectFilePath,
+  });
+
+  @override
+  bool get isLoaded => true;
+}
```

Le diff no-index du test ajouté contient 480 lignes pour 474 lignes de fichier. Le rapport inclut l'inventaire complet des tests, fixtures, helpers et assertions ci-dessous afin de rendre le fichier non suivi vérifiable sans s'appuyer sur un simple `--stat`.

Résumé vérifiable du contenu ajouté :

```text
imports : dart:convert, dart:io, flame/components, flutter_test, map_core, map_gameplay, map_runtime, global_story_chapter_runtime, map_entity_runtime_predicate_evaluator, path
constantes : _testMapId, _testPickupEntityId, _testItemId, _testPickupFact, _testPickupStep
helpers : _dispatch, _context, _pickupScenario, _edge, _pickupProxyNpc, _evaluator, _runtimePickupMap, _writeRuntimeProject, _LoadedPlayableMapGame
fixtures : uniquement ids test_*
assertions principales : Bag vide, quantity, accumulation, blocage itemId, default quantity, blocage quantity <=0, fact, step, save/load, anti double pickup, world rule proxy, PlayableMapGame dispatch item.
```

### 23.5 Preuve absence ids Selbrume interdits

Commande :

```bash
rg -n "Maël|mael|Lysa|lysa|Soline|soline|Selbrume|Bourg de Selbrume|Port des Brisants|map_bourg_selbrume|map_port_brisants|npc_mael|npc_lysa|npc_soline|trainer_lysa_port|battle_rival_port|scene_mael_intro|scene_rival_meet|yarn_mael_intro|yarn_rival_intro|Sproutle|Sparkitten|cristaux de sel|Goélise|clé du phare|cabane du phare" packages/map_runtime/test/item_pickup_give_item_readiness_test.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/lib/map_runtime.dart
```

Sortie exacte :

```text

```

### 23.6 Git diff --check final

Commande :

```bash
git diff --check
```

Sortie exacte :

```text

```

Résultat : OK.

### 23.7 Git diff --stat final

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 MVP Selbrume/road_map.md                           | 30 ++++++--
 packages/map_runtime/lib/map_runtime.dart          |  1 +
 .../scenario_runtime_executor.dart                 | 79 +++++++++++++++++++---
 .../src/presentation/flame/playable_map_game.dart  |  8 ++-
 4 files changed, 100 insertions(+), 18 deletions(-)
```

### 23.8 Git diff --name-only final

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
MVP Selbrume/road_map.md
packages/map_runtime/lib/map_runtime.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
```

### 23.9 Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M "MVP Selbrume/road_map.md"
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
?? packages/map_runtime/test/item_pickup_give_item_readiness_test.dart
?? reports/gameplay/ns_gs_14_item_pickup_give_item_authoring_readiness.md
```

## 24. Auto-review critique

Checklist :

```text
✅ Roadmap lue avant modification.
✅ Audit giveItem / Bag effectué avant code.
✅ Cas B choisi explicitement.
✅ Aucune fixture Selbrume finale.
✅ Aucun project.json Selbrume.
✅ Aucun contenu final Selbrume.
✅ Pas d'Item Catalogue.
✅ Pas de Bag UI.
✅ Pas de shop.
✅ Pas de key item / door gate.
✅ Pas de modification map_editor.
✅ Pas de modification map_battle.
✅ Tests ciblés verts.
✅ Analyzer ciblé des fichiers NS-GS-14 clean.
⚠️ Analyze package map_runtime non clean : 352 diagnostics info préexistants, aucun sur les fichiers NS-GS-14.
⚠️ World rule directe sur MapEntityKind.item non prouvée ; pattern proxy NPC documenté.
```

Verdict :

```text
NS-GS-14 est validable.
Le flux générique Item Pickup / GiveItem authorable est prouvé au niveau runtime/application.
Prochain lot recommandé : NS-GS-15 — Key Item / Door Gate Readiness.
```
