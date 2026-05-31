# NS-SCENES-V1-28 — Golden Slice Selbrume Scene/Event Prep

## 1. Résumé du lot

V1-28 ajoute une preuve de readiness core, neutre et déterministe, pour vérifier la chaîne minimale :

```text
MapEventPage.sceneTarget
-> SceneAsset
-> diagnostics Scene/Event/Project
-> SceneRuntimePlan
-> SceneRuntimeExecutor
-> Dialogue.completed
-> Battle.victory / Battle.defeat
-> fins distinctes
-> Fact / World Rule authoring-ready
```

Le lot ne branche pas le runtime map, ne modifie pas `map_runtime`, ne crée pas de seed produit et ne rend pas le slice jouable en jeu.

## 2. Pourquoi V1-28 existe

Les lots V1-20 à V1-27 ont livré Facts, World Rules, lien Event -> Scene authoring-only, RuntimePlan, executor pur et intégration editor des World Rules. V1-28 vérifie que ces briques peuvent former une chaîne cohérente avant d’ajouter un hook runtime.

La question traitée est : une page d’event peut-elle cibler une scène réelle, diagnostiquée, compilable, exécutable par executor pur et reliée à une intention de conséquence Fact/WorldRule, sans données produit ni runtime map ?

## 3. Rappel du scope

Réalisé :

- read model pur `GoldenSliceReadinessReport` dans `map_core`;
- fixture de test neutre en mémoire;
- tests de readiness event -> scene -> dialogue -> battle;
- tests de branches victory et defeat via `SceneRuntimeExecutor`;
- vérification refs Dialogue/Battle, diagnostics Event/Scene/WorldRule et read model WorldRule target context;
- export public depuis `map_core.dart`;
- roadmaps V1 mises à jour.

Non réalisé :

- aucun hook `PlayableMapGame`;
- aucune mutation `GameState`;
- aucune application runtime de World Rule;
- aucun write de Fact runtime;
- aucun `StorylineStep.sceneLinkIds`;
- aucun seed produit;
- aucun import `map_battle`, `map_runtime` ou `map_gameplay`.

## 4. Gate 0 complet

Commande exécutée depuis la racine :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
c480c4f5 test(scenes): refine world rule empty state handling
ac3b389c feat(scenes): add world rules map editor integration v0
757f0ad5 docs(scenes): add V1-26-bis evidence hardening report
108b8c3c feat(scenes): add scene runtime executor MVP
c0d43712 feat(scenes): add dialogue and battle authoring ports
36494eaf feat(scenes): expand diagnostics and validator checks
061e9ebc feat(scenes): add scene runtime plan v0
540d5377 feat(scenes): add event page scene link V0
a2e14b19 docs(scenes): add V1-23 architecture decision and roadmap updates
9e85a187 feat(scenes): add payload pickers for linked assets,workdir:/Users/karim/Project/pokemonProject
```

Interprétation des sorties vides du Gate 0 :

```text
git status initial exact : Sortie : <vide>
git diff --stat initial : Sortie : <vide>
git diff --name-only initial : Sortie : <vide>
```

## 5. Changements préexistants vs changements du lot

Le worktree initial était propre. Aucun changement préexistant n’a été détecté au Gate 0.

Changements introduits par V1-28 :

- création de `packages/map_core/lib/src/read_models/golden_slice_readiness.dart`;
- création de `packages/map_core/test/golden_slice_readiness_test.dart`;
- export public dans `packages/map_core/lib/map_core.dart`;
- mise à jour de `reports/narrativeStudio/scenes/road_map_scenes.md`;
- mise à jour de `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`;
- création de ce rapport.

## 6. Fichiers lus

Fichiers d’instructions et prompt :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `/Users/karim/.codex/attachments/85770f18-a927-48a3-b8c9-87f3253c71c3/pasted-text.txt`

Rapports et roadmaps :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_27_world_rules_map_editor_integration_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_bis_scene_runtime_executor_evidence_review.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_scene_runtime_executor_mvp.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_diagnostics_validator_expansion.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_24_scene_runtime_plan_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_23_bis_event_to_scene_link_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_22_payload_pickers_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_21_linked_asset_contracts_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_20_world_rules_v0.md`

Fichiers core :

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/world_rule.dart`
- `packages/map_core/lib/src/models/narrative_fact.dart`
- `packages/map_core/lib/src/models/project_trainer.dart`
- `packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart`
- `packages/map_core/lib/src/read_models/world_rule_target_context_read_model.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart`
- `packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_executor.dart`
- `packages/map_core/lib/map_core.dart`

Tests existants :

- `packages/map_core/test/linked_asset_public_contracts_test.dart`
- `packages/map_core/test/event_scene_link_diagnostics_test.dart`
- `packages/map_core/test/scene_runtime_plan_test.dart`
- `packages/map_core/test/scene_runtime_executor_test.dart`
- `packages/map_core/test/scene_diagnostics_test.dart`
- `packages/map_core/test/world_rule_target_context_read_model_test.dart`
- `packages/map_core/test/world_rule_diagnostics_test.dart`

Audit editor/runtime en lecture seule :

- `packages/map_editor/lib/src/ui/panels/event_properties_panel.dart`
- `packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart`
- `packages/map_editor/test/event_properties_panel_scene_target_test.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`

## 7. Fichiers créés/modifiés

Créés :

- `packages/map_core/lib/src/read_models/golden_slice_readiness.dart`
- `packages/map_core/test/golden_slice_readiness_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_golden_slice_selbrume_scene_event_prep.md`

Modifiés :

- `packages/map_core/lib/map_core.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 8. Design retenu

Le design retenu est un read model pur :

```dart
GoldenSliceReadinessReport buildGoldenSliceReadinessReport(
  ProjectManifest project, {
  required List<MapData> maps,
})
```

Entrées :

- `ProjectManifest project`
- `List<MapData> maps`

Sorties :

- `eventTargets` : les pages d’event qui ciblent une Scene V1;
- `issues` : erreurs/warnings/info de readiness;
- `isReady` : vrai si aucune issue de sévérité `error`;
- `eventSceneTargetCount` : nombre de cibles Event -> Scene trouvées.

Le read model agrège et réutilise les briques existantes :

- `diagnoseEventSceneLinks`;
- `diagnoseSceneAgainstProject`;
- `diagnoseWorldRules`;
- `buildSceneRuntimePlan`;
- `buildWorldRuleTargetContextReadModel`.

Il ajoute seulement les vérifications golden-slice spécifiques :

- présence d’un DialogueNode;
- présence d’un BattleNode;
- existence refs Dialogue/Battle;
- buildabilité du plan runtime;
- atteignabilité des branches `victory` et `defeat` vers une fin;
- présence d’au moins une World Rule ciblant l’event.

## 9. Fixture contrôlée créée

Fixture neutre en mémoire :

```text
ProjectManifest
- map_test
- dialogue_test_intro
- trainer_test_rival
- fact_test_rival_defeated
- world_rule_test_unlock_gate
- scene_test_rival

MapData
- map_test
- event_gate
- page 0 -> scene_test_rival

SceneAsset
- node_start
- node_dialogue
- node_battle
- node_end_victory
- node_end_defeat
```

Transitions :

```text
node_start.completed -> node_dialogue
node_dialogue.completed -> node_battle
node_battle.victory -> node_end_victory
node_battle.defeat -> node_end_defeat
```

## 10. Chaîne Event -> Scene prouvée

Le test `proves a controlled event to scene dialogue battle chain` vérifie :

- `report.isReady == true`;
- `report.eventSceneTargetCount == 1`;
- la cible contient `map_test`, `event_gate`, `scene_test_rival`;
- la scène existe;
- le plan runtime est buildable;
- la scène contient Dialogue et Battle;
- victory et defeat atteignent une fin;
- une World Rule cible l’event.

## 11. Diagnostics Scene / Project / Event prouvés

Le test vérifie :

- `diagnoseSceneAgainstProject(...).hasErrors == false`;
- absence de `dialogueRefUnknown`;
- absence de `battleTrainerRefUnknown`;
- `diagnoseEventSceneLinks(...).hasErrors == false`;
- `diagnoseWorldRules(...).hasErrors == false`.

Le test négatif vérifie aussi les codes :

- `goldenSliceSceneMissing`;
- `goldenSliceDialogueRefMissing`;
- `goldenSliceBattleRefMissing`;
- `goldenSliceRuntimePlanNotBuildable`;
- `goldenSliceWorldRuleMissing`;
- `goldenSliceNoEventSceneTarget`.

## 12. RuntimePlan prouvé

Le test appelle :

```dart
final planResult = buildSceneRuntimePlan(fixture.scene);
expect(planResult.canBuild, isTrue);
final plan = planResult.plan!;
```

Le plan contient au moins :

- `SceneRuntimePlanIntentKind.showDialogue`;
- `SceneRuntimePlanIntentKind.startBattle`.

Le layout n’intervient pas.

## 13. SceneRuntimeExecutor prouvé en test

Executor utilisé uniquement dans `map_core/test` avec callbacks simulés :

```dart
SceneRuntimeExecutor(
  callbacks: SceneRuntimeExecutionCallbacks(
    evaluateCondition: (_) => 'true',
    showDialogue: (_) => 'completed',
    startBattle: (_) => battleResult,
    playCinematic: (_) => 'completed',
  ),
).execute(plan);
```

Victory :

```text
node_start.completed
node_dialogue.completed
node_battle.victory
node_end_victory
```

Defeat :

```text
node_start.completed
node_dialogue.completed
node_battle.defeat
node_end_defeat
```

## 14. World Rules / Facts readiness prouvée

La fixture contient :

- `NarrativeFactDefinition(id: 'fact_test_rival_defeated')`;
- `WorldRuleDefinition(id: 'world_rule_test_unlock_gate')`;
- source Fact `fact_test_rival_defeated`;
- target `mapEvent map_test/event_gate`;
- effect `eventEnabled`.

Le test appelle :

```dart
buildWorldRuleTargetContextReadModel(
  fixture.project,
  maps: [fixture.map],
  targetKind: WorldRuleTargetKind.mapEvent,
  mapId: 'map_test',
  eventId: 'event_gate',
);
```

Résultat attendu :

- `ruleCount == 1`;
- rule id `world_rule_test_unlock_gate`;
- aucun diagnostic bloquant.

## 15. Ce qui reste non jouable

- Dialogue Yarn n’a encore que `completed`.
- Les outcomes Yarn détaillés attendront Dialogue Studio / contrat outcomes.
- Battle `victory` / `defeat` existe comme ports V0.
- Les conséquences persistantes ne sont pas exécutées.
- Les Facts et World Rules sont authoring-ready mais pas appliquées au runtime.
- Event -> Scene runtime hook n’est pas branché.
- `StorylineStep.sceneLinkIds` reste repoussé.

## 16. Pourquoi aucun runtime map n’a été branché

Le lot demandait une préparation contrôlée, pas une intégration runtime. Le read model et les tests prouvent la chaîne en `map_core` pur, avec `SceneRuntimeExecutor.execute(plan)` seulement. `PlayableMapGame` a été lu pour audit mais n’a pas été modifié.

## 17. Pourquoi aucune conséquence persistante n’a été appliquée

La relation battle victory -> Fact write n’existe pas encore comme contrat Scene V1. L’appliquer maintenant créerait une conséquence implicite et mélangerait readiness, Action/Consequence authoring et runtime GameState. La conséquence est représentée comme readiness Fact/WorldRule seulement.

## 18. Pourquoi aucune donnée produit n’a été créée

Le lot prouve la structure avec des IDs neutres de test. Aucune donnée produit, aucun dossier produit et aucun contenu narratif définitif ne sont créés ou modifiés.

Preuve par recherche ciblée dans les fichiers code/test V1-28 :

```bash
rg -n "selbrume|mael|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_core/lib/src/read_models/golden_slice_readiness.dart packages/map_core/test/golden_slice_readiness_test.dart packages/map_core/lib/map_core.dart || true
```

Sortie : <vide>

Preuve d’absence d’import runtime/battle dans les nouveaux fichiers :

```bash
rg -n "map_runtime|map_battle|PlayableMapGame|GameState" packages/map_core/lib/src/read_models/golden_slice_readiness.dart packages/map_core/test/golden_slice_readiness_test.dart || true
```

Sortie : <vide>

## 19. Tests exécutés avec sorties exactes

Commande finale :

```bash
cd packages/map_core && dart test --no-color test/golden_slice_readiness_test.dart && dart test --no-color test/event_scene_link_diagnostics_test.dart && dart test --no-color test/scene_runtime_plan_test.dart && dart test --no-color test/scene_runtime_executor_test.dart && dart test --no-color test/world_rule_target_context_read_model_test.dart && dart analyze && dart test --no-color test/linked_asset_public_contracts_test.dart && dart test --no-color test/scene_diagnostics_test.dart && dart test --no-color test/world_rule_diagnostics_test.dart
```

Sortie :

```text
00:00 +0: loading test/golden_slice_readiness_test.dart
00:00 +0: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain
00:00 +1: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain
00:00 +1: GoldenSliceReadiness reports missing scene, dialogue, trainer, plan and world rule gaps
00:00 +2: GoldenSliceReadiness reports missing scene, dialogue, trainer, plan and world rule gaps
00:00 +2: All tests passed!
00:00 +0: loading test/event_scene_link_diagnostics_test.dart
00:00 +0: diagnoseEventSceneLinks does not report pages without scene target
00:00 +1: diagnoseEventSceneLinks does not report pages without scene target
00:00 +1: diagnoseEventSceneLinks accepts a scene target referencing an existing scene
00:00 +2: diagnoseEventSceneLinks accepts a scene target referencing an existing scene
00:00 +2: diagnoseEventSceneLinks reports missing and empty scene targets as errors
00:00 +3: diagnoseEventSceneLinks reports missing and empty scene targets as errors
00:00 +3: diagnoseEventSceneLinks warns when a disabled page targets a scene
00:00 +4: diagnoseEventSceneLinks warns when a disabled page targets a scene
00:00 +4: diagnoseEventSceneLinks warns when the target scene has scene diagnostics errors
00:00 +5: diagnoseEventSceneLinks warns when the target scene has scene diagnostics errors
00:00 +5: diagnoseEventSceneLinks errors when the target scene cannot build a runtime plan
00:00 +6: diagnoseEventSceneLinks errors when the target scene cannot build a runtime plan
00:00 +6: diagnoseEventSceneLinks warns when legacy message or script coexist with scene target
00:00 +7: diagnoseEventSceneLinks warns when legacy message or script coexist with scene target
00:00 +7: All tests passed!
00:00 +0: loading test/scene_runtime_plan_test.dart
00:00 +0: Scene runtime plan V0 builds a pure plan for a minimal valid start to end scene
00:00 +1: Scene runtime plan V0 builds a pure plan for a minimal valid start to end scene
00:00 +1: Scene runtime plan V0 ignores SceneGraphLayout when building the plan
00:00 +2: Scene runtime plan V0 ignores SceneGraphLayout when building the plan
00:00 +2: Scene runtime plan V0 preserves deterministic node and edge order from SceneGraph
00:00 +3: Scene runtime plan V0 preserves deterministic node and edge order from SceneGraph
00:00 +3: Scene runtime plan V0 scene diagnostics errors block plan building cleanly
00:00 +4: Scene runtime plan V0 scene diagnostics errors block plan building cleanly
00:00 +4: Scene runtime plan V0 condition nodes become evaluateCondition intents
00:00 +5: Scene runtime plan V0 condition nodes become evaluateCondition intents
00:00 +5: Scene runtime plan V0 merge nodes become merge intents
00:00 +6: Scene runtime plan V0 merge nodes become merge intents
00:00 +6: Scene runtime plan V0 yarn dialogue payload becomes showDialogue intent without outcomes invented
00:00 +7: Scene runtime plan V0 yarn dialogue payload becomes showDialogue intent without outcomes invented
00:00 +7: Scene runtime plan V0 battle payload becomes startBattle intent without importing battle runtime
00:00 +8: Scene runtime plan V0 battle payload becomes startBattle intent without importing battle runtime
00:00 +8: Scene runtime plan V0 battle plan preserves victory and defeat edges
00:00 +9: Scene runtime plan V0 battle plan preserves victory and defeat edges
00:00 +9: Scene runtime plan V0 cinematic payload becomes playCinematic intent with bridge warning
00:00 +10: Scene runtime plan V0 cinematic payload becomes playCinematic intent with bridge warning
00:00 +10: Scene runtime plan V0 action nodes produce unsupported diagnostics and no plan
00:00 +11: Scene runtime plan V0 action nodes produce unsupported diagnostics and no plan
00:00 +11: Scene runtime plan V0 branchByOutcome nodes produce unsupported diagnostics and no plan
00:00 +12: Scene runtime plan V0 branchByOutcome nodes produce unsupported diagnostics and no plan
00:00 +12: Scene runtime plan V0 does not mutate the original SceneAsset
00:00 +13: Scene runtime plan V0 does not mutate the original SceneAsset
00:00 +13: All tests passed!
00:00 +0: loading test/scene_runtime_executor_test.dart
00:00 +0: SceneRuntimeExecutor MVP executes start to end
00:00 +1: SceneRuntimeExecutor MVP executes start to end
00:00 +1: SceneRuntimeExecutor MVP exposes final scene outcome id from end intent
00:00 +2: SceneRuntimeExecutor MVP exposes final scene outcome id from end intent
00:00 +2: SceneRuntimeExecutor MVP executes a plan built from a SceneAsset without ProjectManifest
00:00 +3: SceneRuntimeExecutor MVP executes a plan built from a SceneAsset without ProjectManifest
00:00 +3: SceneRuntimeExecutor MVP executes start to dialogue completed to end
00:00 +4: SceneRuntimeExecutor MVP executes start to dialogue completed to end
00:00 +4: SceneRuntimeExecutor MVP executes battle victory branch
00:00 +5: SceneRuntimeExecutor MVP executes battle victory branch
00:00 +5: SceneRuntimeExecutor MVP executes battle defeat branch
00:00 +6: SceneRuntimeExecutor MVP executes battle defeat branch
00:00 +6: SceneRuntimeExecutor MVP executes condition true branch
00:00 +7: SceneRuntimeExecutor MVP executes condition true branch
00:00 +7: SceneRuntimeExecutor MVP executes condition false branch
00:00 +8: SceneRuntimeExecutor MVP executes condition false branch
00:00 +8: SceneRuntimeExecutor MVP executes merge as passthrough
00:00 +9: SceneRuntimeExecutor MVP executes merge as passthrough
00:00 +9: SceneRuntimeExecutor MVP executes cinematic completed via callback
00:00 +10: SceneRuntimeExecutor MVP executes cinematic completed via callback
00:00 +10: SceneRuntimeExecutor MVP fails when start node is missing from plan
00:00 +11: SceneRuntimeExecutor MVP fails when start node is missing from plan
00:00 +11: SceneRuntimeExecutor MVP fails when returned port has no transition
00:00 +12: SceneRuntimeExecutor MVP fails when returned port has no transition
00:00 +12: SceneRuntimeExecutor MVP fails when returned port is unsupported
00:00 +13: SceneRuntimeExecutor MVP fails when returned port is unsupported
00:00 +13: SceneRuntimeExecutor MVP fails when multiple transitions match same node and port
00:00 +14: SceneRuntimeExecutor MVP fails when multiple transitions match same node and port
00:00 +14: SceneRuntimeExecutor MVP fails when target node is missing
00:00 +15: SceneRuntimeExecutor MVP fails when target node is missing
00:00 +15: SceneRuntimeExecutor MVP fails when callback throws
00:00 +16: SceneRuntimeExecutor MVP fails when callback throws
00:00 +16: SceneRuntimeExecutor MVP fails when maxSteps is exceeded
00:00 +17: SceneRuntimeExecutor MVP fails when maxSteps is exceeded
00:00 +17: SceneRuntimeExecutor MVP does not mutate SceneRuntimePlan
00:00 +18: SceneRuntimeExecutor MVP does not mutate SceneRuntimePlan
00:00 +18: All tests passed!
00:00 +0: loading test/world_rule_target_context_read_model_test.dart
00:00 +0: WorldRuleTargetContextReadModel finds rules targeting a map event and filters other contexts
00:00 +1: WorldRuleTargetContextReadModel finds rules targeting a map event and filters other contexts
00:00 +1: WorldRuleTargetContextReadModel finds map entity and npc dialogue rules when requested
00:00 +2: WorldRuleTargetContextReadModel finds map entity and npc dialogue rules when requested
00:00 +2: WorldRuleTargetContextReadModel returns diagnostics attached to matching rules only
00:00 +3: WorldRuleTargetContextReadModel returns diagnostics attached to matching rules only
00:00 +3: WorldRuleTargetContextReadModel orders rules deterministically by priority then id
00:00 +4: WorldRuleTargetContextReadModel orders rules deterministically by priority then id
00:00 +4: WorldRuleTargetContextReadModel does not mutate ProjectManifest or require GameState
00:00 +5: WorldRuleTargetContextReadModel does not mutate ProjectManifest or require GameState
00:00 +5: All tests passed!
Analyzing map_core...
No issues found!
00:00 +0: loading test/linked_asset_public_contracts_test.dart
00:00 +0: Linked asset public contracts builds dialogue contracts from manifest dialogues
00:00 +1: Linked asset public contracts builds dialogue contracts from manifest dialogues
00:00 +1: Linked asset public contracts reports a diagnostic when dialogue label falls back to technical id
00:00 +2: Linked asset public contracts reports a diagnostic when dialogue label falls back to technical id
00:00 +2: Linked asset public contracts builds trainer battle contracts without exposing map_battle types
00:00 +3: Linked asset public contracts builds trainer battle contracts without exposing map_battle types
00:00 +3: Linked asset public contracts warns when a trainer battle has an empty team
00:00 +4: Linked asset public contracts warns when a trainer battle has an empty team
00:00 +4: Linked asset public contracts builds cinematic scenario bridge contracts from cutscene metadata
00:00 +5: Linked asset public contracts builds cinematic scenario bridge contracts from cutscene metadata
00:00 +5: Linked asset public contracts does not expose regular scenarios as cinematic contracts
00:00 +6: Linked asset public contracts does not expose regular scenarios as cinematic contracts
00:00 +6: Linked asset public contracts snapshot aggregates contracts and keeps action and branch disabled
00:00 +7: Linked asset public contracts snapshot aggregates contracts and keeps action and branch disabled
00:00 +7: Linked asset public contracts builders are deterministic and do not mutate the manifest
00:00 +8: Linked asset public contracts builders are deterministic and do not mutate the manifest
00:00 +8: All tests passed!
00:00 +0: loading test/scene_diagnostics_test.dart
00:00 +0: Scene diagnostics V1-08 minimal draft has no blocking error
00:00 +1: Scene diagnostics V1-08 minimal draft has no blocking error
00:00 +1: Scene diagnostics scene without end node emits missingEndNode error
00:00 +2: Scene diagnostics scene without end node emits missingEndNode error
00:00 +2: Scene diagnostics end outcome absent from declared outcomes emits error
00:00 +3: Scene diagnostics end outcome absent from declared outcomes emits error
00:00 +3: Scene diagnostics declared outcome never emitted by an end node emits warning
00:00 +4: Scene diagnostics declared outcome never emitted by an end node emits warning
00:00 +4: Scene diagnostics incomplete layout emits layoutMissingNode warning
00:00 +5: Scene diagnostics incomplete layout emits layoutMissingNode warning
00:00 +5: Scene diagnostics complete layout does not emit layoutMissingNode
00:00 +6: Scene diagnostics complete layout does not emit layoutMissingNode
00:00 +6: Scene diagnostics condition node without source emits blocking diagnostic
00:00 +7: Scene diagnostics condition node without source emits blocking diagnostic
00:00 +7: Scene diagnostics configured V0 condition source has no condition error
00:00 +8: Scene diagnostics configured V0 condition source has no condition error
00:00 +8: Scene diagnostics incompatible edge port emits blocking diagnostic
00:00 +9: Scene diagnostics incompatible edge port emits blocking diagnostic
00:00 +9: Scene diagnostics edge kind mismatch emits blocking diagnostic
00:00 +10: Scene diagnostics edge kind mismatch emits blocking diagnostic
00:00 +10: Scene diagnostics duplicate edge from single output port emits blocking diagnostic
00:00 +11: Scene diagnostics duplicate edge from single output port emits blocking diagnostic
00:00 +11: Scene diagnostics missing required condition output emits warning
00:00 +12: Scene diagnostics missing required condition output emits warning
00:00 +12: Scene diagnostics dialogue completed output is validated as default flow
00:00 +13: Scene diagnostics dialogue completed output is validated as default flow
00:00 +13: Scene diagnostics dialogue missing, invalid and duplicate outputs are diagnosed
00:00 +14: Scene diagnostics dialogue missing, invalid and duplicate outputs are diagnosed
00:00 +14: Scene diagnostics battle victory and defeat outputs are validated
00:00 +15: Scene diagnostics battle victory and defeat outputs are validated
00:00 +15: Scene diagnostics battle missing, invalid and duplicate outputs are diagnosed
00:00 +16: Scene diagnostics battle missing, invalid and duplicate outputs are diagnosed
00:00 +16: Scene diagnostics unreachable node and unreachable end are diagnosed
00:00 +17: Scene diagnostics unreachable node and unreachable end are diagnosed
00:00 +17: Scene diagnostics cycle reachable from start is diagnosed as unsupported warning
00:00 +18: Scene diagnostics cycle reachable from start is diagnosed as unsupported warning
00:00 +18: Scene diagnostics action and branch nodes remain unsupported authoring warnings
00:00 +19: Scene diagnostics action and branch nodes remain unsupported authoring warnings
00:00 +19: Scene diagnostics fact source references must resolve against ProjectManifest facts
00:00 +20: Scene diagnostics fact source references must resolve against ProjectManifest facts
00:00 +20: Scene diagnostics future and incomplete condition sources are diagnosed
00:00 +21: Scene diagnostics future and incomplete condition sources are diagnosed
00:00 +21: All tests passed!
00:00 +0: loading test/world_rule_diagnostics_test.dart
00:00 +0: World rule diagnostics reports unknown source and unknown target references
00:00 +1: World rule diagnostics reports unknown source and unknown target references
00:00 +1: World rule diagnostics reports effect target mismatch and raw technical labels
00:00 +2: World rule diagnostics reports effect target mismatch and raw technical labels
00:00 +2: World rule diagnostics reports unsupported predicates and conflicting same target priority
00:00 +3: World rule diagnostics reports unsupported predicates and conflicting same target priority
00:00 +3: All tests passed!
```

## 20. Analyze avec sortie exacte

Commande incluse dans la validation finale :

```bash
cd packages/map_core && dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
```

## 21. Visual Gate si applicable

Aucun screenshot V1-28 n’a été créé.

Justification : V1-28 est core-first/readiness-first. Aucun widget editor, aucune surface canvas, aucun panneau et aucun layout visuel n’ont été modifiés. Les visual gates pertinents pour le canvas/ports/World Rules ont déjà été livrés par V1-25-bis et V1-27 ; ce lot vérifie la cohérence core en tests.

## 22. git diff --check

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
Sortie : <vide>
```

## 23. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 packages/map_core/lib/map_core.dart                |  1 +
 .../scenes/road_map_scene_builder_authoring.md     | 21 +++++++++++++++---
 reports/narrativeStudio/scenes/road_map_scenes.md  | 25 +++++++++++++++++-----
 3 files changed, 39 insertions(+), 8 deletions(-)
```

## 24. git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
packages/map_core/lib/map_core.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 25. git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_core/lib/map_core.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/read_models/golden_slice_readiness.dart
?? packages/map_core/test/golden_slice_readiness_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_28_golden_slice_selbrume_scene_event_prep.md
```

## 26. Evidence Pack

### 26.1 Signatures publiques du fichier créé `golden_slice_readiness.dart`

Application de la clause du prompt pour fichier long : le fichier créé contient 453 lignes. Les signatures publiques, les types publics et la fonction publique sont reproduits ci-dessous.

```dart
enum GoldenSliceReadinessIssueSeverity {
  error,
  warning,
  info,
}

enum GoldenSliceReadinessIssueCode {
  goldenSliceNoEventSceneTarget,
  goldenSliceSceneMissing,
  goldenSliceSceneHasDiagnostics,
  goldenSliceRuntimePlanNotBuildable,
  goldenSliceDialogueRefMissing,
  goldenSliceBattleRefMissing,
  goldenSliceBattleVictoryNotReachable,
  goldenSliceBattleDefeatNotReachable,
  goldenSliceWorldRuleMissing,
  goldenSliceWorldRuleHasDiagnostics,
  goldenSliceDialogueNodeMissing,
  goldenSliceBattleNodeMissing,
}

final class GoldenSliceReadinessIssue {
  const GoldenSliceReadinessIssue({
    required this.code,
    required this.severity,
    required this.message,
    this.mapId,
    this.eventId,
    this.pageNumber,
    this.sceneId,
    this.nodeId,
  });

  final GoldenSliceReadinessIssueCode code;
  final GoldenSliceReadinessIssueSeverity severity;
  final String message;
  final String? mapId;
  final String? eventId;
  final int? pageNumber;
  final String? sceneId;
  final String? nodeId;
}

final class GoldenSliceReadinessEventTarget {
  const GoldenSliceReadinessEventTarget({
    required this.mapId,
    required this.eventId,
    required this.pageNumber,
    required this.pageIndex,
    required this.sceneId,
    required this.sceneExists,
    required this.runtimePlanBuildable,
    required this.containsDialogue,
    required this.containsBattle,
    required this.battleVictoryReachable,
    required this.battleDefeatReachable,
    required this.worldRuleCount,
  });
}

final class GoldenSliceReadinessReport {
  GoldenSliceReadinessReport({
    required List<GoldenSliceReadinessEventTarget> eventTargets,
    required List<GoldenSliceReadinessIssue> issues,
  });

  final List<GoldenSliceReadinessEventTarget> eventTargets;
  final List<GoldenSliceReadinessIssue> issues;

  int get eventSceneTargetCount;
  bool get isReady;
  bool get hasIssues;
  List<GoldenSliceReadinessIssue> byCode(
    GoldenSliceReadinessIssueCode code,
  );
}

GoldenSliceReadinessReport buildGoldenSliceReadinessReport(
  ProjectManifest project, {
  required List<MapData> maps,
});
```

### 26.2 Sections de décision du fichier créé `golden_slice_readiness.dart`

La fonction publique :

```dart
GoldenSliceReadinessReport buildGoldenSliceReadinessReport(
  ProjectManifest project, {
  required List<MapData> maps,
}) {
  final scenesById = {for (final scene in project.scenes) scene.id: scene};
  final dialogueIds = project.dialogues.map((dialogue) => dialogue.id).toSet();
  final trainerIds = project.trainers.map((trainer) => trainer.id).toSet();
  final eventLinkDiagnostics = diagnoseEventSceneLinks(
    project: project,
    maps: maps,
  );
  final targets = <GoldenSliceReadinessEventTarget>[];
  final issues = <GoldenSliceReadinessIssue>[];

  // Parcours maps/events/pages avec sceneTarget, agrégation diagnostics,
  // vérification refs Dialogue/Battle, build RuntimePlan, atteignabilité
  // victory/defeat et World Rule ciblant l'event.

  if (targets.isEmpty) {
    issues.add(
      const GoldenSliceReadinessIssue(
        code: GoldenSliceReadinessIssueCode.goldenSliceNoEventSceneTarget,
        severity: GoldenSliceReadinessIssueSeverity.error,
        message: 'Aucun event de map ne cible une Scene V1.',
      ),
    );
  }

  return GoldenSliceReadinessReport(
    eventTargets: targets,
    issues: issues,
  );
}
```

Helper d’atteignabilité :

```dart
bool _isEndReachableFromPort(
  SceneAsset scene,
  String battleNodeId,
  String portId,
) {
  final nodesById = {for (final node in scene.graph.nodes) node.id: node};
  final outgoingByNode = <String, List<SceneEdge>>{};
  for (final edge in scene.graph.edges) {
    outgoingByNode.putIfAbsent(edge.fromNodeId, () => <SceneEdge>[]).add(edge);
  }

  final queue = <String>[
    for (final edge in scene.graph.edges)
      if (edge.fromNodeId == battleNodeId && edge.fromPortId == portId)
        edge.toNodeId,
  ];
  final visited = <String>{};
  while (queue.isNotEmpty) {
    final nodeId = queue.removeAt(0);
    if (!visited.add(nodeId)) {
      continue;
    }
    final node = nodesById[nodeId];
    if (node == null) {
      continue;
    }
    if (node.kind == SceneNodeKind.end) {
      return true;
    }
    for (final edge in outgoingByNode[nodeId] ?? const <SceneEdge>[]) {
      queue.add(edge.toNodeId);
    }
  }
  return false;
}
```

### 26.3 Tests ajoutés dans `golden_slice_readiness_test.dart`

Application de la clause du prompt pour fichier long : le test créé contient 411 lignes. Les tests ajoutés, la fixture et les helpers métier sont reproduits ci-dessous.

```dart
test('proves a controlled event to scene dialogue battle chain', () async {
  final fixture = _controlledFixture();
  final projectBefore = fixture.project.toJson();
  final mapBefore = fixture.map.toJson();

  final report = buildGoldenSliceReadinessReport(
    fixture.project,
    maps: [fixture.map],
  );

  expect(report.isReady, isTrue);
  expect(report.eventSceneTargetCount, 1);
  expect(report.issues, isEmpty);
  final target = report.eventTargets.single;
  expect(target.mapId, 'map_test');
  expect(target.eventId, 'event_gate');
  expect(target.sceneId, 'scene_test_rival');
  expect(target.sceneExists, isTrue);
  expect(target.runtimePlanBuildable, isTrue);
  expect(target.containsDialogue, isTrue);
  expect(target.containsBattle, isTrue);
  expect(target.battleVictoryReachable, isTrue);
  expect(target.battleDefeatReachable, isTrue);
  expect(target.worldRuleCount, 1);

  final sceneDiagnostics = diagnoseSceneAgainstProject(
    fixture.scene,
    fixture.project,
  );
  expect(sceneDiagnostics.hasErrors, isFalse);
  expect(sceneDiagnostics.byCode(SceneDiagnosticCode.dialogueRefUnknown), isEmpty);
  expect(sceneDiagnostics.byCode(SceneDiagnosticCode.battleTrainerRefUnknown), isEmpty);

  final eventDiagnostics = diagnoseEventSceneLinks(
    project: fixture.project,
    maps: [fixture.map],
  );
  expect(eventDiagnostics.hasErrors, isFalse);

  final planResult = buildSceneRuntimePlan(fixture.scene);
  expect(planResult.canBuild, isTrue);
  final plan = planResult.plan!;
  expect(
    plan.nodes.map((node) => node.intent.kind),
    containsAll([
      SceneRuntimePlanIntentKind.showDialogue,
      SceneRuntimePlanIntentKind.startBattle,
    ]),
  );

  final victory = await _execute(plan, battleResult: 'victory');
  expect(victory.status, SceneRuntimeExecutionStatus.completed);
  expect(victory.finalNodeId, 'node_end_victory');

  final defeat = await _execute(plan, battleResult: 'defeat');
  expect(defeat.status, SceneRuntimeExecutionStatus.completed);
  expect(defeat.finalNodeId, 'node_end_defeat');

  final worldRuleContext = buildWorldRuleTargetContextReadModel(
    fixture.project,
    maps: [fixture.map],
    targetKind: WorldRuleTargetKind.mapEvent,
    mapId: 'map_test',
    eventId: 'event_gate',
  );
  expect(worldRuleContext.ruleCount, 1);
  expect(worldRuleContext.rules.single.id, 'world_rule_test_unlock_gate');
  expect(worldRuleContext.hasDiagnostics, isFalse);
  expect(diagnoseWorldRules(fixture.project, maps: [fixture.map]).hasErrors, isFalse);

  expect(fixture.project.toJson(), projectBefore);
  expect(fixture.map.toJson(), mapBefore);
  expect(_fixtureIds(fixture), containsAll(_allowedFixtureIds));
});

test('reports missing scene, dialogue, trainer, plan and world rule gaps', () {
  final fixture = _controlledFixture();

  expect(
    buildGoldenSliceReadinessReport(
      fixture.project.copyWith(scenes: const []),
      maps: [fixture.map],
    ).byCode(GoldenSliceReadinessIssueCode.goldenSliceSceneMissing),
    isNotEmpty,
  );

  expect(
    buildGoldenSliceReadinessReport(
      fixture.project.copyWith(dialogues: const []),
      maps: [fixture.map],
    ).byCode(GoldenSliceReadinessIssueCode.goldenSliceDialogueRefMissing),
    isNotEmpty,
  );

  expect(
    buildGoldenSliceReadinessReport(
      fixture.project.copyWith(trainers: const []),
      maps: [fixture.map],
    ).byCode(GoldenSliceReadinessIssueCode.goldenSliceBattleRefMissing),
    isNotEmpty,
  );

  expect(
    buildGoldenSliceReadinessReport(
      fixture.project.copyWith(scenes: [_sceneWithoutEnd()]),
      maps: [fixture.map],
    ).byCode(
      GoldenSliceReadinessIssueCode.goldenSliceRuntimePlanNotBuildable,
    ),
    isNotEmpty,
  );

  expect(
    buildGoldenSliceReadinessReport(
      fixture.project.copyWith(worldRules: const []),
      maps: [fixture.map],
    ).byCode(GoldenSliceReadinessIssueCode.goldenSliceWorldRuleMissing),
    isNotEmpty,
  );

  expect(
    buildGoldenSliceReadinessReport(
      fixture.project,
      maps: [
        fixture.map.copyWith(
          events: [
            fixture.map.events.single.copyWith(
              pages: const [MapEventPage(pageNumber: 0)],
            ),
          ],
        ),
      ],
    ).byCode(GoldenSliceReadinessIssueCode.goldenSliceNoEventSceneTarget),
    isNotEmpty,
  );
});
```

### 26.4 Fixture ajoutée

```dart
const _allowedFixtureIds = {
  'map_test',
  'event_gate',
  'scene_test_rival',
  'dialogue_test_intro',
  'trainer_test_rival',
  'fact_test_rival_defeated',
  'world_rule_test_unlock_gate',
  'node_start',
  'node_dialogue',
  'node_battle',
  'node_end_victory',
  'node_end_defeat',
};
```

La fixture crée :

```dart
ProjectManifest(
  maps: const [
    ProjectMapEntry(
      id: 'map_test',
      name: 'Test Map',
      relativePath: 'maps/map_test.json',
    ),
  ],
  dialogues: const [
    ProjectDialogueEntry(
      id: 'dialogue_test_intro',
      name: 'Test Intro Dialogue',
      relativePath: 'dialogues/dialogue_test_intro.yarn',
    ),
  ],
  trainers: const [
    ProjectTrainerEntry(
      id: 'trainer_test_rival',
      name: 'Test Trainer',
      trainerClass: 'Tester',
      team: [
        ProjectTrainerPokemonEntry(speciesId: 'pichu', level: 5),
      ],
    ),
  ],
  facts: [
    NarrativeFactDefinition(
      id: 'fact_test_rival_defeated',
      label: 'Test rival defeated',
    ),
  ],
  worldRules: [
    WorldRuleDefinition(
      id: 'world_rule_test_unlock_gate',
      label: 'Unlock test gate',
      source: const WorldRuleSource(
        kind: WorldRuleSourceKind.fact,
        sourceId: 'fact_test_rival_defeated',
        predicate: WorldRuleSourcePredicate.isTrue,
      ),
      target: const WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEvent,
        mapId: 'map_test',
        eventId: 'event_gate',
        label: 'Test gate event',
      ),
      effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventEnabled),
    ),
  ],
  scenes: [scene],
  surfaceCatalog: const ProjectSurfaceCatalog.empty(),
);
```

La map de test :

```dart
MapData(
  id: 'map_test',
  name: 'Test Map',
  size: const GridSize(width: 8, height: 8),
  events: const [
    MapEventDefinition(
      id: 'event_gate',
      title: 'Test Gate',
      position: EventPosition(layerId: 'l_base', x: 2, y: 2),
      pages: [
        MapEventPage(
          pageNumber: 0,
          sceneTarget: MapEventSceneTarget(sceneId: 'scene_test_rival'),
        ),
      ],
    ),
  ],
);
```

La scène de test :

```dart
SceneAsset(
  id: 'scene_test_rival',
  name: 'Test Rival Scene',
  graph: SceneGraph(
    startNodeId: 'node_start',
    nodes: [
      SceneNode(id: 'node_start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'node_dialogue',
        kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(dialogueId: 'dialogue_test_intro'),
      ),
      SceneNode(
        id: 'node_battle',
        kind: SceneNodeKind.battle,
        payload: SceneBattlePayload(
          battleKind: 'trainer',
          trainerId: 'trainer_test_rival',
          declaredOutcomes: const ['victory', 'defeat'],
        ),
      ),
      SceneNode(id: 'node_end_victory', kind: SceneNodeKind.end),
      SceneNode(id: 'node_end_defeat', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'edge_start_dialogue',
        fromNodeId: 'node_start',
        fromPortId: 'completed',
        toNodeId: 'node_dialogue',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'edge_dialogue_battle',
        fromNodeId: 'node_dialogue',
        fromPortId: 'completed',
        toNodeId: 'node_battle',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'edge_battle_victory',
        fromNodeId: 'node_battle',
        fromPortId: 'victory',
        toNodeId: 'node_end_victory',
        kind: SceneEdgeKind.battleVictory,
      ),
      SceneEdge(
        id: 'edge_battle_defeat',
        fromNodeId: 'node_battle',
        fromPortId: 'defeat',
        toNodeId: 'node_end_defeat',
        kind: SceneEdgeKind.battleDefeat,
      ),
    ],
  ),
);
```

### 26.5 Hunk complet modifié `packages/map_core/lib/map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index fe250854..dd63ccde 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -88,6 +88,7 @@ export 'src/authoring/world_rule_authoring_operations.dart';
 export 'src/authoring/narrative_validator_authoring_adapter.dart';
 export 'src/authoring/storyline_legacy_import_preview.dart';
 export 'src/read_models/narrative_reference_picker_read_models.dart';
+export 'src/read_models/golden_slice_readiness.dart';
 export 'src/read_models/linked_asset_public_contracts.dart';
 export 'src/read_models/world_rule_target_context_read_model.dart';
 export 'src/runtime/scene_runtime_plan.dart';
```

### 26.6 Diff complet `road_map_scenes.md`

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 2ddc44e1..6deadf19 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -73,16 +73,17 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-26 — Scene Runtime Executor MVP | DONE | Executor pur `map_core` pour parcourir un `SceneRuntimePlan` via callbacks condition/dialogue/battle/cinematic, trace, erreurs propres et `maxSteps`, sans branchement runtime map. |
 | NS-SCENES-V1-26-bis — Scene Runtime Executor Evidence & Review Hardening | DONE | Review/evidence hardening de V1-26 : executor confirme pur, tests/analyze relances, fichiers executor/test reproduits integralement, aucun runtime map ni V1-27 demarre. |
 | NS-SCENES-V1-27 — World Rules Map Editor Integration V0 | DONE | World Rules retrouvees depuis leurs cibles Map Editor : events, entites et dialogues PNJ, avec diagnostics, toggle enabled et creation V0 fact -> map event. |
-| NS-SCENES-V1-28 — Golden Slice Selbrume Scene/Event Prep | TODO | Preparer le slice test Lysa/rival via fixtures ou projet controle, sans hardcode produit. |
-| NS-SCENES-V1-29 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres builder, triggers, runtime MVP et golden slice stabilises. |
+| NS-SCENES-V1-28 — Golden Slice Selbrume Scene/Event Prep | DONE | Readiness core controlee : event neutre -> Scene V1 -> Dialogue.completed -> Battle.victory/defeat -> fins, refs Dialogue/Battle, World Rule/Facts et executor pur verifies sans Selbrume produit ni runtime map. |
+| NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0 | TODO | Brancher prudemment `MapEventPage.sceneTarget` au runtime map via `SceneRuntimeExecutor` et callbacks/adapters limites, sans consequences persistantes automatiques. |
+| NS-SCENES-V1-29 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres builder, triggers, runtime MVP, golden slice readiness et runtime hook stabilises. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-28 — Golden Slice Selbrume Scene/Event Prep`
+`NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0`
 
-Raison : V1-27 rend les World Rules visibles et corrigibles depuis les cibles naturelles du Map Editor sans brancher de runtime. Le prochain verrou utile est donc une preparation de golden slice controlee, en fixtures/tests et sans seed produit Selbrume, pour verifier que event -> scene -> dialogue/battle/consequence reste atteignable.
+Raison : V1-28 prouve en core pur qu'un event authoring peut cibler une Scene V1 reelle, compiler en `SceneRuntimePlan`, executer Dialogue.completed puis Battle.victory/defeat via `SceneRuntimeExecutor`, et exposer Facts/World Rules authoring-ready. Le prochain verrou est le hook runtime map limite, pas encore les StorylineStep.
 
-Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Selbrume Scene/Event Prep.
+Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Selbrume Scene/Event Prep, puis Event to Scene Runtime Hook V0.
 
 Note non bloquante : l'overview affiche encore parfois `Facts — necessite un modele` alors que Fact Registry V0 existe depuis V1-18. Ce point reste un polish d'alignement UI, pas le prochain blocage du golden slice.
 
@@ -100,6 +101,20 @@ Tests : `cd packages/map_core && dart test test/world_rule_test.dart && dart tes
 
 Prochain lot exact : `NS-SCENES-V1-28 — Golden Slice Selbrume Scene/Event Prep`.
 
+## Mise a jour V1-28
+
+Statut : `NS-SCENES-V1-28 — Golden Slice Selbrume Scene/Event Prep` est DONE.
+
+Decision : le lot ajoute un read model pur `GoldenSliceReadinessReport` cote `map_core` pour verifier une chaine controlee `MapEventPage.sceneTarget -> SceneAsset -> SceneRuntimePlan -> SceneRuntimeExecutor`, avec Dialogue.completed, Battle.victory/defeat, refs Dialogue/Battle, Facts et World Rules authoring-ready.
+
+Preuve : la fixture neutre utilise `map_test`, `event_gate`, `scene_test_rival`, `dialogue_test_intro`, `trainer_test_rival`, `fact_test_rival_defeated` et `world_rule_test_unlock_gate`. Elle ne modifie pas `selbrume/**`, ne branche pas runtime map et n'applique aucune consequence persistante.
+
+Limites : Dialogue Yarn reste limite a `completed`, les outcomes Yarn detailles et BranchByOutcome restent futurs, les consequences persistantes ne sont pas executees, les Facts/World Rules ne sont pas appliquees au runtime et `StorylineStep.sceneLinkIds` reste reporte.
+
+Tests : `golden_slice_readiness_test`, diagnostics Event->Scene, Scene runtime plan, Scene runtime executor, World Rule target context, contrats linked assets, diagnostics Scene/WorldRule et `dart analyze`.
+
+Prochain lot exact : `NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0`.
+
 ## Decisions V1-24
```

### 26.7 Diff complet `road_map_scene_builder_authoring.md`

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 41bb65b3..6070f0ee 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-27 — World Rules Map Editor Integration V0
+NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0
 ```
 
 ## Principes
@@ -52,8 +52,9 @@ NS-SCENES-V1-27 — World Rules Map Editor Integration V0
 | NS-SCENES-V1-26 | Scene Runtime Executor MVP | core | DONE : executer un sous-ensemble `SceneRuntimePlan` via callbacks limites condition/dialogue/cinematic/battle, avec trace, erreurs et `maxSteps`. | Pas de branchement PlayableMapGame, pas Event -> Scene runtime, pas de ScenarioAsset, pas de consequences persistantes. | `scene_runtime_executor.dart`, tests executor. | DONE : start/end/dialogue/battle/condition/merge/cinematic, erreurs transitions/callback/cycle, no layout/project. | Refaire ScenarioRuntimeExecutor ; effets persistants implicites ; importer runtime/battle. | DONE : executor pur map_core, callbacks explicites, aucun ScenarioAsset canonique, aucun runtime map. | V1-24, V1-25, V1-25-bis. |
 | NS-SCENES-V1-26-bis | Scene Runtime Executor Evidence & Review Hardening | review / evidence | Fermer V1-26 avec audit imports/API/callbacks/transitions/intents/trace/resultat/maxSteps/non-mutation et Evidence Pack complet. | Pas de V1-27, pas de runtime map, pas de nouvelle feature, pas de ScenarioAsset, pas de consequences persistantes. | rapport V1-26-bis, roadmaps. | DONE : executor/test reproduits integralement dans le rapport, tests/analyze relances, `git diff --check` final. | Review trop legere sur un futur coeur runtime ; evidence incomplete. | DONE : V1-26 confirme, aucun runtime map branche, V1-27 reste TODO. | V1-26. |
 | NS-SCENES-V1-27 | World Rules Map Editor Integration V0 | editor / core | Rendre les World Rules visibles/configurables depuis les maps, entites, PNJ et events cibles. | Pas de runtime Scene complet, pas de collision/warp dynamique, pas de seed Selbrume. | map/entity inspectors, world rule read model, diagnostics, creation event V0. | DONE : read model cible pur, EventPropertiesPanel creation/toggle, EntityPropertiesPanel affichage/toggle, tests core/editor/analyze/visual gate. | World Rules inutilisables si seulement en overview ; UI trop large. | DONE : les rules peuvent etre inspectees depuis leur cible map sans exposer flags bruts ni brancher runtime. | V1-20, V1-25 utile. |
-| NS-SCENES-V1-28 | Golden Slice Selbrume Scene/Event Prep | mixed / fixtures | Preparer le slice Lysa/rival en fixtures ou projet controle : event -> scene -> dialogue/outcome -> combat/consequence. | Pas de seed produit hardcode, pas de raccourci runtime. | fixtures tests, reports Selbrume. | Golden tests atteignabilite, diagnostics, event trigger prep. | Mettre des donnees Selbrume dans le produit ; scope trop large. | Slice de test prouve la chaine, sans hardcode produit. | V1-22, V1-23, V1-26, V1-27. |
-| NS-SCENES-V1-29 | StorylineStep to Scene Link | core / editor | Brancher `StorylineStep.sceneLinkIds` vers scenes stables. | Pas de declenchement runtime par StoryStep seul, pas de lien scenario legacy. | storyline models/UI validators si necessaire. | Tests refs scene, UI disabled/enabled, diagnostics link. | Confondre step et trigger ; progression pilotant toute la scene. | StoryStep peut referencer Scene pour lecture/progression, sans remplacer Event trigger. | V1-23, V1-26, V1-28. |
+| NS-SCENES-V1-28 | Golden Slice Selbrume Scene/Event Prep | mixed / fixtures | Preparer le slice Lysa/rival en fixtures ou projet controle : event -> scene -> dialogue/outcome -> combat/consequence. | Pas de seed produit hardcode, pas de raccourci runtime. | fixtures tests, reports Selbrume. | DONE : readiness core event -> scene -> Dialogue.completed -> Battle.victory/defeat -> fins, refs et World Rules authoring. | Mettre des donnees Selbrume dans le produit ; scope trop large. | DONE : slice neutre prouve la chaine, sans hardcode produit, sans runtime map. | V1-22, V1-23, V1-26, V1-27. |
+| NS-SCENES-V1-28-bis | Event to Scene Runtime Hook V0 | runtime / integration | Brancher prudemment `MapEventPage.sceneTarget` au runtime map via `SceneRuntimeExecutor` et callbacks/adapters limites. | Pas de consequences persistantes automatiques, pas de StorylineStep link, pas de ScenarioAsset, pas de seed Selbrume. | `map_runtime` event interaction path, adapters dialogue/battle limites, tests runtime cibles. | Tests event page active -> scene executor, dialogue completed, battle victory/defeat mocks/adapters, no GameState consequence. | Brancher trop large ; appliquer World Rules/runtime consequences trop tot ; casser legacy events. | Un event authoring peut lancer une Scene V1 en runtime controle, sans consequences persistantes implicites. | V1-26, V1-28. |
+| NS-SCENES-V1-29 | StorylineStep to Scene Link | core / editor | Brancher `StorylineStep.sceneLinkIds` vers scenes stables. | Pas de declenchement runtime par StoryStep seul, pas de lien scenario legacy. | storyline models/UI validators si necessaire. | Tests refs scene, UI disabled/enabled, diagnostics link. | Confondre step et trigger ; progression pilotant toute la scene. | StoryStep peut referencer Scene pour lecture/progression, sans remplacer Event trigger. | V1-23, V1-26, V1-28-bis. |
 
 ## Options comparees
 
@@ -364,6 +365,20 @@ Tests : core WorldRule existants + read model cible, editor event/entity/overvie
 
 Prochain lot exact : `NS-SCENES-V1-28 — Golden Slice Selbrume Scene/Event Prep`.
 
+## Mise a jour V1-28
+
+Statut : `NS-SCENES-V1-28 — Golden Slice Selbrume Scene/Event Prep` est DONE.
+
+Decision : le lot reste core-first et ajoute `GoldenSliceReadinessReport` dans `map_core` pour verifier une fixture neutre event -> scene -> dialogue -> battle -> victory/defeat, avec diagnostics existants, `SceneRuntimePlan`, `SceneRuntimeExecutor`, refs Dialogue/Battle et World Rules/Facts authoring-ready.
+
+Fixture : `map_test`, `event_gate`, `scene_test_rival`, `dialogue_test_intro`, `trainer_test_rival`, `fact_test_rival_defeated`, `world_rule_test_unlock_gate`. Aucun contenu produit Selbrume, aucun `selbrume/**`, aucun runtime map.
+
+Limites : pas de Dialogue outcomes avances, pas de BranchByOutcome, pas de consequences persistantes, pas de Fact write runtime, pas d'application World Rule runtime, pas de StorylineStep link.
+
+Tests : `golden_slice_readiness_test`, Event->Scene diagnostics, Scene runtime plan, Scene runtime executor, linked asset contracts, Scene diagnostics, WorldRule diagnostics, WorldRule target context, `dart analyze`.
+
+Prochain lot exact : `NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0`.
+
 ## Selbrume golden slice
```

## 27. Auto-review critique

- Est-ce que j’ai modifié `selbrume/**` ? Non.
- Est-ce que j’ai créé des données Maël/Lysa/Port des Brisants ? Non.
- Est-ce que j’ai modifié `map_runtime` ? Non.
- Est-ce que j’ai branché `PlayableMapGame` ? Non.
- Est-ce que j’ai branché Event -> Scene runtime ? Non.
- Est-ce que j’ai appliqué une World Rule au runtime ? Non.
- Est-ce que j’ai muté `GameState` ? Non.
- Est-ce que j’ai importé `map_battle` ? Non.
- Est-ce que j’ai inventé des outcomes Yarn ? Non, seul `completed` est utilisé.
- Est-ce que j’ai activé `BranchByOutcome` ? Non.
- Est-ce que j’ai promu `ScenarioAsset` ? Non.
- Est-ce que les fixtures sont neutres ? Oui.
- Est-ce que la chaîne Event -> Scene -> Dialogue -> Battle -> victory/defeat est prouvée ? Oui, par test core.
- Est-ce que les gaps runtime/consequence sont explicitement documentés ? Oui.
- Est-ce que le prochain lot n’a pas été démarré ? Oui.

Critique : le read model est volontairement orienté golden slice. Il ne remplace pas un validator projet global. C’est acceptable pour V1-28, mais V1-28-bis devra éviter de transformer cette readiness en runtime implicite.

## 28. Limites restantes

- Le read model ne lance pas de dialogue Yarn réel.
- Le read model ne lance pas de combat réel.
- Le read model ne produit aucun Fact runtime.
- Le read model n’applique aucune World Rule au monde.
- Les branches Yarn détaillées restent hors scope.
- La conséquence victory -> Fact doit être cadrée dans un futur lot Action/Consequence ou Scene Outcomes to Facts.
- Le hook `MapEventPage.sceneTarget` -> `SceneRuntimeExecutor` reste le prochain verrou.

## 29. Prochain lot recommandé

`NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0`

Raison : V1-28 prouve que la chaîne core est prête. Le prochain verrou réel est d’appeler prudemment `SceneRuntimeExecutor` depuis le chemin runtime d’un event map, avec callbacks/adapters limités, sans conséquence persistante automatique et sans `StorylineStep.sceneLinkIds`.
