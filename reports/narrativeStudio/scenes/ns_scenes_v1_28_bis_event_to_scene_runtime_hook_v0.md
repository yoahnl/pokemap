# NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0

## 1. Résumé du lot

V1-28-bis ajoute un hook runtime limité entre `MapEventPage.sceneTarget` et `SceneRuntimeExecutor`.

Le résultat livré :

- un service testable `SceneEventRuntimeHook` côté `map_runtime`;
- des callbacks host `SceneRuntimeHostCallbacks`;
- un résultat explicite `SceneEventRuntimeHookResult`;
- un branchement minimal dans `PlayableMapGame`;
- une règle de priorité claire : si la page active porte `sceneTarget`, le message/script legacy de cette même page n’est pas lancé automatiquement en plus;
- des tests runtime ciblés;
- les roadmaps mises à jour.

Le hook runtime lance la Scene. Il ne persiste pas encore ses conséquences.

## 2. Pourquoi V1-28-bis existe

V1-28 a prouvé en `map_core` pur qu’un event peut cibler une `SceneAsset`, que cette scène peut être diagnostiquée, compilée en `SceneRuntimePlan`, puis exécutée par `SceneRuntimeExecutor` avec des callbacks de test.

V1-28-bis répond à la question runtime suivante : quand le joueur active un event de map dont la page active possède `sceneTarget`, le runtime peut-il tenter la Scene V1 de manière contrôlée, sans convertir vers `ScenarioAsset` et sans écrire de conséquence narrative ?

Réponse : oui, avec une limite volontaire sur les adapters concrets. Le hook existe et le chemin event l’appelle. Le dialogue runtime existant peut être ouvert comme seam `completed`; le battle réel n’est pas encore awaitable proprement et reste donc refusé en production plutôt que simulé.

## 3. Rappel du scope

Réalisé :

- audit du chemin d’interaction map event dans `PlayableMapGame`;
- service applicatif runtime testable hors Flame;
- exécution `SceneRuntimePlan` via `SceneRuntimeExecutor`;
- erreurs lisibles pour scène absente, diagnostics bloquants, plan non buildable et échec executor;
- branchement minimal `page.sceneTarget != null`;
- tests neutres sans données produit;
- non-régression core relancée.

Non réalisé :

- aucun write de Fact;
- aucune application runtime de World Rule;
- aucune sauvegarde narrative;
- aucune mutation `GameState` pour conséquence narrative;
- aucun `StorylineStep.sceneLinkIds`;
- aucun `ScenarioAsset` promu ou converti;
- aucun import nouveau de `map_battle` dans le hook;
- aucun parser Yarn;
- aucun BranchByOutcome;
- aucune donnée produit.

## 4. Gate 0 complet

Commande exécutée depuis la racine avant modification :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
54acda44 feat(scenes): add golden slice selbrume readiness
c480c4f5 test(scenes): refine world rule empty state handling
ac3b389c feat(scenes): add world rules map editor integration v0
757f0ad5 docs(scenes): add V1-26-bis evidence hardening report
108b8c3c feat(scenes): add scene runtime executor MVP
c0d43712 feat(scenes): add dialogue and battle authoring ports
36494eaf feat(scenes): expand diagnostics and validator checks
061e9ebc feat(scenes): add scene runtime plan v0
540d5377 feat(scenes): add event page scene link V0
a2e14b19 docs(scenes): add V1-23 architecture decision and roadmap updates
```

Interprétation des sections vides :

```text
git status initial exact : Sortie : <vide>
git diff --stat initial : Sortie : <vide>
git diff --name-only initial : Sortie : <vide>
```

## 5. Changements préexistants vs changements du lot

Le worktree initial était propre.

Changements introduits par V1-28-bis :

- création de `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart`;
- création de `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart`;
- création de `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_hook_result.dart`;
- création de `packages/map_runtime/test/scene_event_runtime_hook_test.dart`;
- export public dans `packages/map_runtime/lib/map_runtime.dart`;
- branchement minimal dans `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`;
- mise à jour des deux roadmaps;
- création de ce rapport.

## 6. Fichiers lus

Instructions et prompt :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `/Users/karim/.codex/attachments/9665d23a-8625-4672-aed0-49280cce51fc/pasted-text.txt`

Roadmaps et rapports :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_golden_slice_selbrume_scene_event_prep.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_27_world_rules_map_editor_integration_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_bis_scene_runtime_executor_evidence_review.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_scene_runtime_executor_mvp.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_diagnostics_validator_expansion.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_24_scene_runtime_plan_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_23_bis_event_to_scene_link_v0.md`

Core :

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_executor.dart`
- `packages/map_core/lib/src/read_models/golden_slice_readiness.dart`
- `packages/map_core/lib/map_core.dart`

Runtime :

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/runtime_story_branching.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart`
- `packages/map_runtime/lib/src/application/trainer_battle_request.dart`
- `packages/map_runtime/lib/src/application/battle_start_request.dart`
- `packages/map_runtime/lib/map_runtime.dart`

Tests :

- `packages/map_core/test/golden_slice_readiness_test.dart`
- `packages/map_core/test/scene_runtime_executor_test.dart`
- `packages/map_core/test/scene_runtime_plan_test.dart`
- `packages/map_core/test/event_scene_link_diagnostics_test.dart`
- `packages/map_runtime/test/**` audité par recherche ciblée.

## 7. Fichiers créés/modifiés

Créés :

- `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_hook_result.dart`
- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_bis_event_to_scene_runtime_hook_v0.md`

Modifiés :

- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 8. Audit du runtime event path

Chemins trouvés :

- `PlayableMapGame._handleInteract()` résout l’interaction joueur.
- Si aucune entité runtime prioritaire ne consomme l’interaction, `PlayableMapGame._tryInteractWithMapEvent()` cherche un `MapEventDefinition` sur la case visée.
- La page active est résolue via `RuntimeStoryBranching.resolveEventPage(event, _gameState)`.
- `RuntimeStoryBranching` délègue à `EventPageResolver`, qui évalue les conditions de pages via `ScriptConditionEvaluator`.
- Si la page active est désactivée, l’event ne s’exécute pas.
- Sinon `PlayableMapGame._handleMapEventInteraction(event, activePage)` déclenche le comportement.
- Avant V1-28-bis, `_handleMapEventInteraction` lançait `script`, puis `message`, puis un fallback `...`.
- Les scripts legacy passent par `_executeEventScript`, `_startScriptExecution`, `ScriptRuntimeController`, puis callbacks script.
- Les dialogues legacy projet passent par `_openScenarioDialogueById` ou `_tryOpenDialogue`.
- Les battles trainer existants passent par `BattleStartRequest` et `_startBattleHandoff`, mais le résultat `victory/defeat` n’est pas exposé sous forme de callback awaitable simple pour Scene V1.

Point d’insertion retenu :

```text
PlayableMapGame._handleMapEventInteraction
-> si page.page.sceneTarget != null
-> SceneEventRuntimeHook
-> return
```

Pourquoi ici :

- la page active est déjà connue;
- le legacy n’a pas encore été déclenché;
- le branchement est localisé;
- les events sans `sceneTarget` gardent le flux existant.

## 9. Design retenu

Le design est en deux couches :

1. `SceneEventRuntimeHook` orchestre le contrat runtime event -> scene.
2. `SceneRuntimeExecutor` reste l’executor pur du plan.

Le hook :

- lit `page.sceneTarget`;
- retourne `notHandled` si absent;
- résout `SceneAsset` dans `ProjectManifest.scenes`;
- lance `diagnoseSceneAgainstProject(scene, project)`;
- construit `buildSceneRuntimePlan(scene)`;
- exécute `SceneRuntimeExecutor.execute(plan)`;
- retourne `completed` ou `failed`.

Le hook ne lit pas `ScenarioAsset`, ne modifie pas `GameState`, ne touche pas disque et ne sauvegarde rien.

## 10. API du hook runtime

API livrée :

```dart
final class SceneEventRuntimeHook {
  SceneEventRuntimeHook({
    required SceneRuntimeHostCallbacks callbacks,
    int maxSteps = 100,
  });

  Future<SceneEventRuntimeHookResult> runForEventPage({
    required ProjectManifest project,
    required MapData map,
    required MapEventDefinition event,
    required MapEventPage page,
  });
}
```

Résultat livré :

```dart
enum SceneEventRuntimeHookStatus {
  notHandled,
  completed,
  failed,
}

enum SceneEventRuntimeHookErrorCode {
  sceneTargetMissingScene,
  sceneTargetDiagnosticsFailed,
  sceneTargetRuntimePlanFailed,
  sceneExecutionFailed,
}
```

## 11. Callbacks/adapters

`SceneRuntimeHostCallbacks` expose :

- `evaluateCondition`
- `showDialogue`
- `startBattle`
- `playCinematic`

Tests :

- les callbacks de test retournent `completed`, `victory`, `defeat`, `true`;
- le hook prouve que `SceneRuntimeExecutor` suit les branches victory et defeat.

Runtime réel dans `PlayableMapGame` :

- `evaluateCondition` lit seulement `factLikeStoryFlag`, `storyStepCompletion` et `consumedEvent` depuis le `GameState` existant, sans mutation;
- `showDialogue` ouvre le dialogue projet via `_openScenarioDialogueById` et retourne `completed`;
- `playCinematic` acknowledge le bridge et retourne `completed`;
- `startBattle` refuse par `UnsupportedError` car le handoff battle actuel n’est pas awaitable pour retourner un vrai `victory` ou `defeat`.

Ce refus est volontaire : le lot ne simule pas une victoire.

## 12. Intégration PlayableMapGame

Intégration faite dans `PlayableMapGame._handleMapEventInteraction` :

```dart
if (page.page.sceneTarget != null) {
  unawaited(_runSceneTargetForMapEvent(event, page));
  return;
}
```

Effet :

- `sceneTarget` présent : hook Scene V1 tenté;
- `sceneTarget` absent : ancien chemin script/message/fallback inchangé;
- hook échoué : notification/log contrôlé;
- aucun fallback legacy silencieux de la même page.

Pas de refactor large de `PlayableMapGame`.

## 13. Comportement sceneTarget absent

Service :

```text
page.sceneTarget == null
-> SceneEventRuntimeHookStatus.notHandled
-> aucun callback appelé
-> aucun SceneRuntimeExecutor lancé
```

Runtime :

```text
page.sceneTarget == null
-> _handleMapEventInteraction continue le flux existant script/message/fallback
```

## 14. Comportement sceneTarget présent

Service :

```text
page.sceneTarget != null
-> scene cible cherchée dans ProjectManifest.scenes
-> diagnostics projet
-> buildSceneRuntimePlan
-> SceneRuntimeExecutor
```

Runtime :

```text
page.sceneTarget != null
-> _runSceneTargetForMapEvent
-> return
-> pas de script/message legacy automatique sur cette même page
```

## 15. Gestion erreurs

Erreurs V0 :

- `sceneTargetMissingScene`
- `sceneTargetDiagnosticsFailed`
- `sceneTargetRuntimePlanFailed`
- `sceneExecutionFailed`

Le hook retourne un résultat `failed` avec message lisible. `PlayableMapGame` loggue le résultat et affiche une notification si le hook a effectivement géré la page.

## 16. Tests runtime exécutés

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_event_runtime_hook_test.dart
```

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_event_runtime_hook_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_event_runtime_hook_test.dart
00:02 +0: SceneEventRuntimeHook ignores event pages without sceneTarget
00:02 +1: SceneEventRuntimeHook ignores event pages without sceneTarget
00:02 +1: SceneEventRuntimeHook fails clearly when sceneTarget references a missing scene
00:02 +2: SceneEventRuntimeHook fails clearly when sceneTarget references a missing scene
00:02 +2: SceneEventRuntimeHook fails before execution when scene diagnostics contain errors
00:02 +3: SceneEventRuntimeHook fails before execution when scene diagnostics contain errors
00:02 +3: SceneEventRuntimeHook fails before execution when runtime plan cannot be built
00:02 +4: SceneEventRuntimeHook fails before execution when runtime plan cannot be built
00:02 +4: SceneEventRuntimeHook executes a targeted Scene V1 through dialogue and battle victory
00:02 +5: SceneEventRuntimeHook executes a targeted Scene V1 through dialogue and battle victory
00:02 +5: SceneEventRuntimeHook executes a targeted Scene V1 through battle defeat branch
00:02 +6: SceneEventRuntimeHook executes a targeted Scene V1 through battle defeat branch
00:02 +6: SceneEventRuntimeHook does not require or promote ScenarioAsset to execute Scene V1
00:02 +7: SceneEventRuntimeHook does not require or promote ScenarioAsset to execute Scene V1
00:02 +7: SceneEventRuntimeHook does not mutate project, map or game state
00:02 +8: SceneEventRuntimeHook does not mutate project, map or game state
00:02 +8: SceneEventRuntimeHook reports callback execution failure without mutating state
00:02 +9: SceneEventRuntimeHook reports callback execution failure without mutating state
00:02 +9: SceneEventRuntimeHook keeps Scene V1 hook files independent from battle package imports
00:02 +10: SceneEventRuntimeHook keeps Scene V1 hook files independent from battle package imports
00:02 +10: All tests passed!
```

TDD RED observé avant implémentation :

```text
Compilation failed ... Type 'SceneRuntimeHostCallbacks' not found.
Method not found: 'SceneEventRuntimeHook'.
Undefined name 'SceneEventRuntimeHookStatus'.
Undefined name 'SceneEventRuntimeHookErrorCode'.
```

## 17. Tests core relancés

Commande :

```bash
cd packages/map_core && dart test test/golden_slice_readiness_test.dart
```

Sortie exacte :

```text
00:00 +0: loading test/golden_slice_readiness_test.dart
00:00 +0: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain
00:00 +1: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain
00:00 +1: GoldenSliceReadiness reports missing scene, dialogue, trainer, plan and world rule gaps
00:00 +2: GoldenSliceReadiness reports missing scene, dialogue, trainer, plan and world rule gaps
00:00 +2: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_executor_test.dart
```

Sortie exacte :

```text
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
```

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_plan_test.dart
```

Sortie exacte :

```text
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
```

## 18. Analyze avec sorties exactes

Commande :

```bash
cd packages/map_runtime && flutter analyze --no-fatal-infos lib/src/application/scene_runtime/scene_event_runtime_hook.dart lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart lib/src/application/scene_runtime/scene_runtime_hook_result.dart lib/src/presentation/flame/playable_map_game.dart lib/map_runtime.dart test/scene_event_runtime_hook_test.dart
```

Sortie exacte :

```text
Analyzing 6 items...
No issues found! (ran in 2.4s)
```

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
```

## 19. Pourquoi aucun ScenarioAsset n’a été promu

Le hook ne lit pas `ProjectManifest.scenarios`. Le test `does not require or promote ScenarioAsset to execute Scene V1` vérifie que la fixture exécute une Scene V1 avec `project.scenarios` vide.

`ScenarioRuntimeExecutor` est seulement audité. Aucun fichier scenario runtime n’est modifié.

## 20. Pourquoi aucune conséquence persistante n’a été appliquée

Le service ne reçoit aucun callback de conséquence. Il ne connaît ni Fact write, ni World Rule application, ni story step completion.

Le test de non-mutation compare :

- `ProjectManifest.toJson()`;
- `MapData.toJson()`;
- `GameState.toJson()`.

Le hook runtime lance la Scene. Il ne persiste pas encore ses conséquences.

## 21. Pourquoi aucune donnée Selbrume n’a été créée

Les fixtures runtime utilisent seulement :

- `map_test_runtime`
- `event_test_scene`
- `scene_test_runtime`
- `dialogue_test_intro`
- `trainer_test_guard`

Aucun dossier produit n’est modifié. Aucun seed produit n’est ajouté.

## 22. Pourquoi StorylineStep.sceneLinkIds reste repoussé

Le déclencheur runtime prioritaire reste l’event de map via `MapEventPage.sceneTarget`.

`StorylineStep.sceneLinkIds` ne doit pas devenir le trigger principal tant que :

- le hook Event -> Scene n’est pas stabilisé;
- les consequences persistantes ne sont pas cadrées;
- le résultat battle concret n’est pas relié proprement aux outcomes Scene.

## 23. git diff --check

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
Sortie : <vide>
```

## 24. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 packages/map_runtime/lib/map_runtime.dart          |   9 ++
 .../src/presentation/flame/playable_map_game.dart  | 129 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  21 +++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 +++-
 4 files changed, 175 insertions(+), 7 deletions(-)
```

## 25. git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
packages/map_runtime/lib/map_runtime.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 26. git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart
?? packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_hook_result.dart
?? packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart
?? packages/map_runtime/test/scene_event_runtime_hook_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_28_bis_event_to_scene_runtime_hook_v0.md
```

## 27. Evidence Pack

### Contenu complet — scene_event_runtime_hook.dart

```dart
import 'package:map_core/map_core.dart';

import 'scene_runtime_host_callbacks.dart';
import 'scene_runtime_hook_result.dart';

final class SceneEventRuntimeHook {
  SceneEventRuntimeHook({
    required this.callbacks,
    this.maxSteps = 100,
  }) {
    if (maxSteps < 1) {
      throw ArgumentError.value(
        maxSteps,
        'maxSteps',
        'SceneEventRuntimeHook requires maxSteps >= 1.',
      );
    }
  }

  final SceneRuntimeHostCallbacks callbacks;
  final int maxSteps;

  Future<SceneEventRuntimeHookResult> runForEventPage({
    required ProjectManifest project,
    required MapData map,
    required MapEventDefinition event,
    required MapEventPage page,
  }) async {
    final sceneTarget = page.sceneTarget;
    if (sceneTarget == null) {
      return const SceneEventRuntimeHookResult.notHandled();
    }

    final sceneId = sceneTarget.sceneId;
    final scene = _findScene(project, sceneId);
    if (scene == null) {
      return SceneEventRuntimeHookResult.failed(
        errorCode: SceneEventRuntimeHookErrorCode.sceneTargetMissingScene,
        sceneId: sceneId,
        message: 'Scene V1 "$sceneId" referenced by event "${event.id}" '
            'on map "${map.id}" was not found.',
      );
    }

    final diagnostics = diagnoseSceneAgainstProject(scene, project);
    if (diagnostics.hasErrors) {
      return SceneEventRuntimeHookResult.failed(
        errorCode: SceneEventRuntimeHookErrorCode.sceneTargetDiagnosticsFailed,
        sceneId: sceneId,
        message: 'Scene V1 "$sceneId" referenced by event "${event.id}" '
            'on map "${map.id}" has blocking diagnostics.',
      );
    }

    final planResult = buildSceneRuntimePlan(scene);
    if (!planResult.canBuild) {
      return SceneEventRuntimeHookResult.failed(
        errorCode: SceneEventRuntimeHookErrorCode.sceneTargetRuntimePlanFailed,
        sceneId: sceneId,
        message: 'Scene V1 "$sceneId" referenced by event "${event.id}" '
            'on map "${map.id}" cannot build a runtime plan.',
      );
    }

    final executionResult = await SceneRuntimeExecutor(
      callbacks: callbacks.toExecutionCallbacks(),
      maxSteps: maxSteps,
    ).execute(planResult.plan!);

    if (executionResult.status == SceneRuntimeExecutionStatus.completed) {
      return SceneEventRuntimeHookResult.completed(
        sceneId: sceneId,
        executionResult: executionResult,
      );
    }

    return SceneEventRuntimeHookResult.failed(
      errorCode: SceneEventRuntimeHookErrorCode.sceneExecutionFailed,
      sceneId: sceneId,
      message: executionResult.message ??
          'Scene V1 "$sceneId" referenced by event "${event.id}" '
              'on map "${map.id}" failed during execution.',
      executionResult: executionResult,
    );
  }
}

SceneAsset? _findScene(ProjectManifest project, String sceneId) {
  for (final scene in project.scenes) {
    if (scene.id == sceneId) {
      return scene;
    }
  }
  return null;
}
```

### Contenu complet — scene_runtime_host_callbacks.dart

```dart
import 'package:map_core/map_core.dart';

final class SceneRuntimeHostCallbacks {
  const SceneRuntimeHostCallbacks({
    required this.evaluateCondition,
    required this.showDialogue,
    required this.startBattle,
    required this.playCinematic,
  });

  final SceneRuntimeIntentCallback evaluateCondition;
  final SceneRuntimeIntentCallback showDialogue;
  final SceneRuntimeIntentCallback startBattle;
  final SceneRuntimeIntentCallback playCinematic;

  SceneRuntimeExecutionCallbacks toExecutionCallbacks() {
    return SceneRuntimeExecutionCallbacks(
      evaluateCondition: evaluateCondition,
      showDialogue: showDialogue,
      startBattle: startBattle,
      playCinematic: playCinematic,
    );
  }
}
```

### Contenu complet — scene_runtime_hook_result.dart

```dart
import 'package:map_core/map_core.dart';

enum SceneEventRuntimeHookStatus {
  notHandled,
  completed,
  failed,
}

enum SceneEventRuntimeHookErrorCode {
  sceneTargetMissingScene,
  sceneTargetDiagnosticsFailed,
  sceneTargetRuntimePlanFailed,
  sceneExecutionFailed,
}

final class SceneEventRuntimeHookResult {
  const SceneEventRuntimeHookResult._({
    required this.status,
    this.errorCode,
    this.sceneId,
    this.message,
    this.executionResult,
  });

  const SceneEventRuntimeHookResult.notHandled()
      : this._(status: SceneEventRuntimeHookStatus.notHandled);

  const SceneEventRuntimeHookResult.completed({
    required String sceneId,
    required SceneRuntimeExecutionResult executionResult,
  }) : this._(
          status: SceneEventRuntimeHookStatus.completed,
          sceneId: sceneId,
          executionResult: executionResult,
        );

  const SceneEventRuntimeHookResult.failed({
    required SceneEventRuntimeHookErrorCode errorCode,
    required String sceneId,
    required String message,
    SceneRuntimeExecutionResult? executionResult,
  }) : this._(
          status: SceneEventRuntimeHookStatus.failed,
          errorCode: errorCode,
          sceneId: sceneId,
          message: message,
          executionResult: executionResult,
        );

  final SceneEventRuntimeHookStatus status;
  final SceneEventRuntimeHookErrorCode? errorCode;
  final String? sceneId;
  final String? message;
  final SceneRuntimeExecutionResult? executionResult;

  bool get handled => status != SceneEventRuntimeHookStatus.notHandled;

  bool get success => status == SceneEventRuntimeHookStatus.completed;
}
```

### Contenu complet — scene_event_runtime_hook_test.dart

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('SceneEventRuntimeHook', () {
    test('ignores event pages without sceneTarget', () async {
      final fixture = _fixture(withSceneTarget: false);
      final calls = <String>[];

      final result = await SceneEventRuntimeHook(
        callbacks: _callbacks(calls: calls),
      ).runForEventPage(
        project: fixture.project,
        map: fixture.map,
        event: fixture.event,
        page: fixture.event.pages.single,
      );

      expect(result.status, SceneEventRuntimeHookStatus.notHandled);
      expect(result.handled, isFalse);
      expect(calls, isEmpty);
    });

    test('fails clearly when sceneTarget references a missing scene', () async {
      final fixture = _fixture();

      final result = await SceneEventRuntimeHook(
        callbacks: _callbacks(calls: <String>[]),
      ).runForEventPage(
        project: fixture.project.copyWith(scenes: const []),
        map: fixture.map,
        event: fixture.event,
        page: fixture.event.pages.single,
      );

      expect(result.status, SceneEventRuntimeHookStatus.failed);
      expect(
        result.errorCode,
        SceneEventRuntimeHookErrorCode.sceneTargetMissingScene,
      );
      expect(result.sceneId, 'scene_test_runtime');
      expect(result.executionResult, isNull);
    });

    test('fails before execution when scene diagnostics contain errors',
        () async {
      final fixture = _fixture(scene: _sceneWithoutEnd());
      final calls = <String>[];

      final result = await SceneEventRuntimeHook(
        callbacks: _callbacks(calls: calls),
      ).runForEventPage(
        project: fixture.project,
        map: fixture.map,
        event: fixture.event,
        page: fixture.event.pages.single,
      );

      expect(result.status, SceneEventRuntimeHookStatus.failed);
      expect(
        result.errorCode,
        SceneEventRuntimeHookErrorCode.sceneTargetDiagnosticsFailed,
      );
      expect(result.executionResult, isNull);
      expect(calls, isEmpty);
    });

    test('fails before execution when runtime plan cannot be built', () async {
      final fixture = _fixture(scene: _sceneWithUnsupportedAction());
      final calls = <String>[];

      final result = await SceneEventRuntimeHook(
        callbacks: _callbacks(calls: calls),
      ).runForEventPage(
        project: fixture.project,
        map: fixture.map,
        event: fixture.event,
        page: fixture.event.pages.single,
      );

      expect(result.status, SceneEventRuntimeHookStatus.failed);
      expect(
        result.errorCode,
        SceneEventRuntimeHookErrorCode.sceneTargetRuntimePlanFailed,
      );
      expect(result.executionResult, isNull);
      expect(calls, isEmpty);
    });

    test('executes a targeted Scene V1 through dialogue and battle victory',
        () async {
      final fixture = _fixture();
      final calls = <String>[];

      final result = await SceneEventRuntimeHook(
        callbacks: _callbacks(calls: calls, battleResult: 'victory'),
      ).runForEventPage(
        project: fixture.project,
        map: fixture.map,
        event: fixture.event,
        page: fixture.event.pages.single,
      );

      expect(result.status, SceneEventRuntimeHookStatus.completed);
      expect(result.handled, isTrue);
      expect(result.success, isTrue);
      expect(result.sceneId, 'scene_test_runtime');
      expect(result.executionResult?.status,
          SceneRuntimeExecutionStatus.completed);
      expect(result.executionResult?.finalNodeId, 'node_end_victory');
      expect(calls, [
        'dialogue:dialogue_test_intro',
        'battle:trainer_test_guard',
      ]);
    });

    test('executes a targeted Scene V1 through battle defeat branch', () async {
      final fixture = _fixture();

      final result = await SceneEventRuntimeHook(
        callbacks: _callbacks(calls: <String>[], battleResult: 'defeat'),
      ).runForEventPage(
        project: fixture.project,
        map: fixture.map,
        event: fixture.event,
        page: fixture.event.pages.single,
      );

      expect(result.status, SceneEventRuntimeHookStatus.completed);
      expect(result.executionResult?.finalNodeId, 'node_end_defeat');
      expect(
        result.executionResult?.trace.map((entry) => entry.nodeId),
        [
          'node_start',
          'node_dialogue',
          'node_battle',
          'node_end_defeat',
        ],
      );
    });

    test('does not require or promote ScenarioAsset to execute Scene V1',
        () async {
      final fixture = _fixture();

      expect(fixture.project.scenarios, isEmpty);

      final result = await SceneEventRuntimeHook(
        callbacks: _callbacks(calls: <String>[]),
      ).runForEventPage(
        project: fixture.project,
        map: fixture.map,
        event: fixture.event,
        page: fixture.event.pages.single,
      );

      expect(result.status, SceneEventRuntimeHookStatus.completed);
      expect(fixture.project.scenarios, isEmpty);
    });

    test('does not mutate project, map or game state', () async {
      final fixture = _fixture();
      final projectBefore = fixture.project.toJson();
      final mapBefore = fixture.map.toJson();
      const gameState = GameState(saveId: 'save_test_runtime');
      final gameStateBefore = gameState.toJson();

      await SceneEventRuntimeHook(
        callbacks: _callbacks(calls: <String>[]),
      ).runForEventPage(
        project: fixture.project,
        map: fixture.map,
        event: fixture.event,
        page: fixture.event.pages.single,
      );

      expect(fixture.project.toJson(), projectBefore);
      expect(fixture.map.toJson(), mapBefore);
      expect(gameState.toJson(), gameStateBefore);
    });

    test('reports callback execution failure without mutating state', () async {
      final fixture = _fixture();

      final result = await SceneEventRuntimeHook(
        callbacks: _callbacks(
          calls: <String>[],
          startBattle: (_) => throw StateError('battle seam unavailable'),
        ),
      ).runForEventPage(
        project: fixture.project,
        map: fixture.map,
        event: fixture.event,
        page: fixture.event.pages.single,
      );

      expect(result.status, SceneEventRuntimeHookStatus.failed);
      expect(
        result.errorCode,
        SceneEventRuntimeHookErrorCode.sceneExecutionFailed,
      );
      expect(
        result.executionResult?.errorCode,
        SceneRuntimeExecutionErrorCode.callbackFailed,
      );
    });

    test('keeps Scene V1 hook files independent from battle package imports',
        () {
      const hookFiles = [
        'lib/src/application/scene_runtime/scene_event_runtime_hook.dart',
        'lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart',
        'lib/src/application/scene_runtime/scene_runtime_hook_result.dart',
      ];

      for (final path in hookFiles) {
        expect(File(path).readAsStringSync(), isNot(contains('map_battle')));
      }
    });
  });
}

SceneRuntimeHostCallbacks _callbacks({
  required List<String> calls,
  String battleResult = 'victory',
  SceneRuntimeIntentCallback? evaluateCondition,
  SceneRuntimeIntentCallback? showDialogue,
  SceneRuntimeIntentCallback? startBattle,
  SceneRuntimeIntentCallback? playCinematic,
}) {
  return SceneRuntimeHostCallbacks(
    evaluateCondition: evaluateCondition ??
        (intent) {
          calls.add('condition:${intent.conditionSource?.sourceId}');
          return 'true';
        },
    showDialogue: showDialogue ??
        (intent) {
          calls.add('dialogue:${intent.dialogueId}');
          return 'completed';
        },
    startBattle: startBattle ??
        (intent) {
          calls.add('battle:${intent.trainerId}');
          return battleResult;
        },
    playCinematic: playCinematic ??
        (intent) {
          calls.add('cinematic:${intent.cinematicId}');
          return 'completed';
        },
  );
}

_RuntimeSceneFixture _fixture({
  bool withSceneTarget = true,
  SceneAsset? scene,
}) {
  final resolvedScene = scene ?? _scene();
  final project = ProjectManifest(
    name: 'Scene runtime hook test project',
    maps: const [
      ProjectMapEntry(
        id: 'map_test_runtime',
        name: 'Runtime Test Map',
        relativePath: 'maps/map_test_runtime.json',
      ),
    ],
    tilesets: const [],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'dialogue_test_intro',
        name: 'Test Intro Dialogue',
        relativePath: 'dialogues/dialogue_test_intro.yarn',
      ),
    ],
    trainers: const [
      ProjectTrainerEntry(
        id: 'trainer_test_guard',
        name: 'Test Guard',
        trainerClass: 'Tester',
        team: [
          ProjectTrainerPokemonEntry(speciesId: 'pichu', level: 5),
        ],
      ),
    ],
    scenes: [resolvedScene],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  final event = MapEventDefinition(
    id: 'event_test_scene',
    title: 'Test Scene Event',
    position: const EventPosition(layerId: 'l_base', x: 2, y: 2),
    pages: [
      MapEventPage(
        pageNumber: 0,
        message: 'Legacy message must stay bypassed when sceneTarget exists.',
        sceneTarget: withSceneTarget
            ? const MapEventSceneTarget(sceneId: 'scene_test_runtime')
            : null,
      ),
    ],
  );
  final map = MapData(
    id: 'map_test_runtime',
    name: 'Runtime Test Map',
    size: const GridSize(width: 8, height: 8),
    layers: [
      MapLayer.tile(
        id: 'l_base',
        name: 'Base',
        tiles: List<int>.filled(64, 0),
      ),
    ],
    events: [event],
  );
  return _RuntimeSceneFixture(project: project, map: map, event: event);
}

SceneAsset _scene() {
  return SceneAsset(
    id: 'scene_test_runtime',
    name: 'Runtime Hook Test Scene',
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
            trainerId: 'trainer_test_guard',
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
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 0, y: 0),
        SceneNodeLayout(nodeId: 'node_dialogue', x: 280, y: 0),
        SceneNodeLayout(nodeId: 'node_battle', x: 560, y: 0),
        SceneNodeLayout(nodeId: 'node_end_victory', x: 840, y: -90),
        SceneNodeLayout(nodeId: 'node_end_defeat', x: 840, y: 90),
      ],
    ),
  );
}

SceneAsset _sceneWithoutEnd() {
  return SceneAsset(
    id: 'scene_test_runtime',
    name: 'Runtime Hook Test Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
      ],
    ),
  );
}

SceneAsset _sceneWithUnsupportedAction() {
  return SceneAsset(
    id: 'scene_test_runtime',
    name: 'Runtime Hook Unsupported Action Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_action',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload(actionKind: 'runtime_test_action'),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_action',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_action',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_action_end',
          fromNodeId: 'node_action',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

final class _RuntimeSceneFixture {
  const _RuntimeSceneFixture({
    required this.project,
    required this.map,
    required this.event,
  });

  final ProjectManifest project;
  final MapData map;
  final MapEventDefinition event;
}
```

### Sections modifiées — map_runtime.dart

```dart
export 'src/application/scene_runtime/scene_event_runtime_hook.dart'
    show SceneEventRuntimeHook;
export 'src/application/scene_runtime/scene_runtime_host_callbacks.dart'
    show SceneRuntimeHostCallbacks;
export 'src/application/scene_runtime/scene_runtime_hook_result.dart'
    show
        SceneEventRuntimeHookErrorCode,
        SceneEventRuntimeHookResult,
        SceneEventRuntimeHookStatus;
```

### Sections modifiées — PlayableMapGame

```dart
import '../../application/scene_runtime/scene_event_runtime_hook.dart';
import '../../application/scene_runtime/scene_runtime_host_callbacks.dart';
```

```dart
  void _handleMapEventInteraction(
    MapEventDefinition event,
    ActiveEventPage page,
  ) {
    if (page.page.sceneTarget != null) {
      unawaited(_runSceneTargetForMapEvent(event, page));
      return;
    }

    if (page.page.script != null) {
      final message = page.page.message?.trim();
      if (message != null && message.isNotEmpty) {
        _showNotification(message);
      }
      _executeEventScript(event, page, page.page.script!);
    } else if (page.page.message != null && page.page.message!.isNotEmpty) {
      _showNotification(page.page.message!);
    } else {
      _showNotification('...');
    }
  }
```

```dart
  Future<void> _runSceneTargetForMapEvent(
    MapEventDefinition event,
    ActiveEventPage page,
  ) async {
    final result = await SceneEventRuntimeHook(
      callbacks: _buildSceneRuntimeHostCallbacks(
        event: event,
        page: page,
      ),
    ).runForEventPage(
      project: _bundle.manifest,
      map: _bundle.map,
      event: event,
      page: page.page,
    );

    debugPrint(
      '[scene_runtime] event=${event.id} page=${page.pageIndex} '
      'status=${result.status.name} scene=${result.sceneId ?? '-'} '
      'message=${result.message ?? '-'}',
    );

    if (!result.success && result.handled) {
      _showNotification(result.message ?? 'Scene V1 impossible.');
    }
  }
```

Les méthodes `_buildSceneRuntimeHostCallbacks`, `_resolveSceneConditionOutput` et `_matchesSceneConditionEquals` sont ajoutées dans la même zone de code et reproduites dans le diff complet du fichier modifié.

### Diff complet des fichiers modifiés

```diff
diff --git a/packages/map_runtime/lib/map_runtime.dart b/packages/map_runtime/lib/map_runtime.dart
index 0876ef61..4b25cbed 100644
--- a/packages/map_runtime/lib/map_runtime.dart
+++ b/packages/map_runtime/lib/map_runtime.dart
@@ -57,6 +57,15 @@ export 'src/application/story_flags_manager.dart' show StoryFlagsManager;
 export 'src/application/scenario_conditions.dart' show ScenarioConditions;
 export 'src/application/runtime_story_branching.dart'
     show RuntimeStoryBranching;
+export 'src/application/scene_runtime/scene_event_runtime_hook.dart'
+    show SceneEventRuntimeHook;
+export 'src/application/scene_runtime/scene_runtime_host_callbacks.dart'
+    show SceneRuntimeHostCallbacks;
+export 'src/application/scene_runtime/scene_runtime_hook_result.dart'
+    show
+        SceneEventRuntimeHookErrorCode,
+        SceneEventRuntimeHookResult,
+        SceneEventRuntimeHookStatus;
 export 'src/application/scenario_runtime/scenario_runtime_models.dart'
     show
         ScenarioRuntimeSourceType,
diff --git a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
index 5a127537..dfef9305 100644
--- a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
@@ -45,6 +45,8 @@ import '../../application/runtime_move_catalog_loader.dart';
 import '../../application/runtime_pokemon_learnset_loader.dart';
 import '../../application/runtime_pokemon_species_loader.dart';
 import '../../application/runtime_story_branching.dart';
+import '../../application/scene_runtime/scene_event_runtime_hook.dart';
+import '../../application/scene_runtime/scene_runtime_host_callbacks.dart';
 import '../../application/scenario_runtime/scenario_runtime_executor.dart';
 import '../../application/scenario_runtime/scenario_runtime_models.dart';
 import '../../application/scenario_runtime/scenario_battle_outcome_flags.dart';
@@ -4870,6 +4872,11 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     MapEventDefinition event,
     ActiveEventPage page,
   ) {
+    if (page.page.sceneTarget != null) {
+      unawaited(_runSceneTargetForMapEvent(event, page));
+      return;
+    }
+
     if (page.page.script != null) {
       final message = page.page.message?.trim();
       if (message != null && message.isNotEmpty) {
@@ -4883,6 +4890,128 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     }
   }
 
+  Future<void> _runSceneTargetForMapEvent(
+    MapEventDefinition event,
+    ActiveEventPage page,
+  ) async {
+    try {
+      final result = await SceneEventRuntimeHook(
+        callbacks: _buildSceneRuntimeHostCallbacks(
+          event: event,
+          page: page,
+        ),
+      ).runForEventPage(
+        project: _bundle.manifest,
+        map: _bundle.map,
+        event: event,
+        page: page.page,
+      );
+
+      debugPrint(
+        '[scene_runtime] event=${event.id} page=${page.pageIndex} '
+        'status=${result.status.name} scene=${result.sceneId ?? '-'} '
+        'message=${result.message ?? '-'}',
+      );
+
+      if (!result.success && result.handled) {
+        _showNotification(result.message ?? 'Scene V1 impossible.');
+      }
+    } catch (error, stackTrace) {
+      debugPrint(
+        '[scene_runtime] unhandled hook error event=${event.id} '
+        'page=${page.pageIndex} error=$error\n$stackTrace',
+      );
+      _showNotification('Scene V1 impossible.');
+    }
+  }
+
+  SceneRuntimeHostCallbacks _buildSceneRuntimeHostCallbacks({
+    required MapEventDefinition event,
+    required ActiveEventPage page,
+  }) {
+    final runtimeSourceId =
+        'scene:${_bundle.map.id}:${event.id}:${page.pageIndex}';
+    return SceneRuntimeHostCallbacks(
+      evaluateCondition: _resolveSceneConditionOutput,
+      showDialogue: (intent) {
+        final dialogueId = intent.dialogueId?.trim();
+        if (dialogueId == null || dialogueId.isEmpty) {
+          throw StateError('Scene dialogue intent is missing dialogueId.');
+        }
+        final opened = _openScenarioDialogueById(
+          dialogueId,
+          startNode: intent.yarnNodeName,
+          runtimeSourceId: runtimeSourceId,
+        );
+        if (!opened) {
+          throw StateError('Scene dialogue "$dialogueId" could not open.');
+        }
+        return 'completed';
+      },
+      startBattle: (intent) {
+        throw UnsupportedError(
+          'Scene V1 battle handoff is not awaitable in runtime hook V0 '
+          '(battleKind=${intent.battleKind}, trainerId=${intent.trainerId}).',
+        );
+      },
+      playCinematic: (intent) {
+        final cinematicId = intent.cinematicId?.trim();
+        if (cinematicId == null || cinematicId.isEmpty) {
+          throw StateError('Scene cinematic intent is missing cinematicId.');
+        }
+        debugPrint(
+          '[scene_runtime] cinematic bridge acknowledged id=$cinematicId',
+        );
+        return 'completed';
+      },
+    );
+  }
+
+  String _resolveSceneConditionOutput(SceneRuntimePlanIntent intent) {
+    final source = intent.conditionSource;
+    if (source == null) {
+      throw StateError('Scene condition intent is missing a condition source.');
+    }
+
+    final value = switch (source.sourceKind) {
+      SceneConditionSourceKind.factLikeStoryFlag =>
+        _gameState.storyFlags.activeFlags.contains(source.sourceId) ||
+            _gameState.progression.storyFlags.contains(source.sourceId),
+      SceneConditionSourceKind.storyStepCompletion =>
+        _gameState.progression.completedStepIds.contains(source.sourceId),
+      SceneConditionSourceKind.consumedEvent =>
+        _gameState.consumedEventIds.contains(source.sourceId),
+      _ => throw UnsupportedError(
+          'Scene condition source ${source.sourceKind.name} is not supported '
+          'by runtime hook V0.',
+        ),
+    };
+
+    final matched = switch (source.operator) {
+      SceneConditionOperator.isTrue => value,
+      SceneConditionOperator.isFalse => !value,
+      SceneConditionOperator.equals =>
+        _matchesSceneConditionEquals(source, value),
+    };
+    return matched ? 'true' : 'false';
+  }
+
+  bool _matchesSceneConditionEquals(
+    SceneConditionSource source,
+    bool resolvedValue,
+  ) {
+    return switch (source.value) {
+      'true' => resolvedValue,
+      'false' => !resolvedValue,
+      SceneConditionValues.completed => resolvedValue,
+      SceneConditionValues.notCompleted => !resolvedValue,
+      _ => throw UnsupportedError(
+          'Scene condition equality value "${source.value}" is not supported '
+          'by runtime hook V0.',
+        ),
+    };
+  }
+
   void _executeEventScript(
     MapEventDefinition event,
     ActiveEventPage page,
```

### git final

`git diff --check` :

```text
Sortie : <vide>
```

`git diff --stat` :

```text
 packages/map_runtime/lib/map_runtime.dart          |   9 ++
 .../src/presentation/flame/playable_map_game.dart  | 129 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  21 +++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 +++-
 4 files changed, 175 insertions(+), 7 deletions(-)
```

`git diff --name-only` :

```text
packages/map_runtime/lib/map_runtime.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

`git status --short --untracked-files=all` :

```text
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart
?? packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_hook_result.dart
?? packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart
?? packages/map_runtime/test/scene_event_runtime_hook_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_28_bis_event_to_scene_runtime_hook_v0.md
```

Recherche anti-données produit demandée :

```bash
rg -n "selbrume|mael|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_runtime packages/map_core reports/narrativeStudio/scenes/ns_scenes_v1_28_bis_event_to_scene_runtime_hook_v0.md || true
```

Interprétation de la sortie : la commande remonte des occurrences préexistantes dans des tests/outils hors scope déjà présents dans `packages/map_core` et `packages/map_runtime`, ainsi que des mentions conceptuelles dans ce rapport. Les nouveaux fichiers V1-28-bis n’ajoutent pas de donnée produit. La vérification dédiée aux fichiers du hook est aussi couverte par le test `keeps Scene V1 hook files independent from battle package imports`, et les fixtures runtime V1-28-bis utilisent uniquement des IDs neutres.

Recherche ciblée sur les fichiers V1-28-bis et les fichiers runtime touchés :

```bash
rg -n "selbrume|mael|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_runtime/lib/src/application/scene_runtime packages/map_runtime/test/scene_event_runtime_hook_test.dart packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/lib/map_runtime.dart || true
```

Sortie exacte :

```text
Sortie : <vide>
```

## 28. Auto-review critique

- Est-ce que j’ai modifié `selbrume/**` ? Non.
- Est-ce que j’ai créé des données produit spécifiques ? Non.
- Est-ce que j’ai promu `ScenarioAsset` ? Non.
- Est-ce que j’ai modifié `ScenarioRuntimeExecutor` ? Non.
- Est-ce que j’ai branché `StorylineStep.sceneLinkIds` ? Non.
- Est-ce que j’ai importé `map_battle` dans le hook ? Non ; test statique ajouté sur les fichiers du hook.
- Est-ce que j’ai inventé des outcomes Yarn ? Non.
- Est-ce que j’ai activé `BranchByOutcome` ? Non.
- Est-ce que j’ai appliqué une World Rule au runtime ? Non.
- Est-ce que j’ai écrit un Fact au runtime ? Non.
- Est-ce que j’ai muté `GameState` pour une conséquence narrative ? Non.
- Est-ce que les events sans `sceneTarget` gardent leur comportement legacy ? Oui, le code legacy reste après le early return ciblé.
- Est-ce que les events avec `sceneTarget` passent par le hook Scene V1 ? Oui.
- Est-ce que les erreurs Scene V1 sont lisibles ? Oui, via `SceneEventRuntimeHookErrorCode` et `message`.
- Est-ce que le prochain lot n’a pas été démarré ? Oui.

Point critique : le callback battle réel dans `PlayableMapGame` n’est pas encore awaitable. Le choix sûr a été de refuser plutôt que d’inventer `victory` ou `defeat`.

## 29. Limites restantes

- Le dialogue runtime est ouvert via le chemin existant mais `SceneRuntimeExecutor` ne l’attend pas encore réellement.
- Le battle handoff réel ne retourne pas encore un résultat awaitable pour Scene V1.
- Aucune conséquence persistante n’est appliquée.
- `ActionNode`, `BranchByOutcome`, outcomes Yarn détaillés et runtime World Rules restent hors scope.
- Aucun test Flame complet sur `PlayableMapGame` n’a été ajouté : le seam applicatif est testé directement, car instancier le jeu complet pour cette interaction aurait dépassé le scope minimal.

## 30. Prochain lot recommandé

Prochain lot recommandé :

```text
NS-SCENES-V1-28-ter — Scene Consequence Contract Prep
```

Justification : après le hook runtime, il faut cadrer comment les outcomes d’une Scene deviennent des conséquences persistantes futures : Fact, World Rule, StoryStep, Action/Consequence. Il ne faut pas improviser des writes runtime sous prétexte que le hook peut démarrer une scène.
