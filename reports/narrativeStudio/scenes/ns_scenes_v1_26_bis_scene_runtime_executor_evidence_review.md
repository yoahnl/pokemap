# NS-SCENES-V1-26-bis — Scene Runtime Executor Evidence & Review Hardening

## 1. Resume du lot

`NS-SCENES-V1-26-bis` ferme le lot `NS-SCENES-V1-26 — Scene Runtime Executor MVP` par une review technique et un Evidence Pack complet. Le lot ne cree aucune fonctionnalite nouvelle : il audite l'executor pur ajoute en V1-26, relance les tests/analyze obligatoires, reproduit integralement les fichiers critiques `scene_runtime_executor.dart` et `scene_runtime_executor_test.dart`, puis aligne les roadmaps.

Verdict : V1-26 reste valide. `SceneRuntimeExecutor` est confirme pur, teste et non branche au runtime map.

## 2. Pourquoi V1-26-bis existe

V1-26 a ajoute le premier executor Scene V1. Le composant est critique parce qu'il deviendra le coeur d'execution des scenes. Le rapport V1-26 validait le comportement, mais son Evidence Pack ne reproduisait pas integralement les nouveaux fichiers critiques. V1-26-bis existe pour combler cette preuve, sans commencer V1-27.

## 3. Rappel du scope

Scope realise :

- audit imports/API/callbacks/transitions/intents/trace/resultat/maxSteps/non-mutation ;
- verification que l'executor reste pur `map_core` ;
- verification qu'aucun `map_runtime`, `map_battle`, Flutter, Flame, Yarn parser, disque, `GameState`, `ProjectManifest`, `ScenarioRuntimeExecutor` ou `PlayableMapGame` n'entre dans l'executor ;
- relance des tests V1-26 et du `dart analyze` cible ;
- reproduction integrale de `scene_runtime_executor.dart` et `scene_runtime_executor_test.dart` ;
- mise a jour des roadmaps avec V1-26-bis DONE ;
- V1-27 conserve comme prochain lot recommande, mais non demarre.

Non-objectifs respectes :

- pas de V1-27 ;
- pas de World Rules Map Editor Integration ;
- pas de branchement `PlayableMapGame` ;
- pas de Event -> Scene runtime trigger ;
- pas de modification `ScenarioRuntimeExecutor` ;
- pas de migration ou promotion `ScenarioAsset` ;
- pas de `StorylineStep.sceneLinkIds` ;
- pas de `map_battle` ;
- pas de `map_runtime` importe dans `map_core` ;
- pas de Yarn parser ;
- pas de mutation `GameState` ;
- pas de Fact write, World Rule projection runtime ou consequence persistante ;
- pas de donnee Selbrume.

## 4. Gate 0 complet

Commande :

```bash
pwd
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
```

Commande :

```bash
git branch --show-current
```

Sortie exacte :

```text
main
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
Sortie : <vide>
```

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
Sortie : <vide>
```

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
Sortie : <vide>
```

Commande :

```bash
git log --oneline -n 10
```

Sortie exacte :

```text
108b8c3c feat(scenes): add scene runtime executor MVP
c0d43712 feat(scenes): add dialogue and battle authoring ports
36494eaf feat(scenes): expand diagnostics and validator checks
061e9ebc feat(scenes): add scene runtime plan v0
540d5377 feat(scenes): add event page scene link V0
a2e14b19 docs(scenes): add V1-23 architecture decision and roadmap updates
9e85a187 feat(scenes): add payload pickers for linked assets,workdir:/Users/karim/Project/pokemonProject
e3325807 feat(scenes): add linked asset contracts and scene V0 node deletion
d170d0da docs(scenes): add linked-asset contracts audit and update roadmaps
48f3d520 docs(scenes): add checkpoint narrative studio direction and update roadmaps
```

## 5. Changements preexistants vs changements du lot

Changements preexistants : aucun. Gate 0 etait propre.

Changements introduits par V1-26-bis :

- creation du present rapport ;
- mise a jour de `reports/narrativeStudio/scenes/road_map_scenes.md` ;
- mise a jour de `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`.

Aucun fichier code, test, runtime, editor, gameplay, battle ou example n'a ete modifie.

## 6. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_scene_runtime_executor_mvp.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_diagnostics_validator_expansion.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_24_scene_runtime_plan_v0.md`
- `packages/map_core/lib/src/runtime/scene_runtime_executor.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart`
- `packages/map_core/test/scene_runtime_executor_test.dart`
- `packages/map_core/test/scene_runtime_plan_test.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Tous les chemins obligatoires existent.

## 7. Fichiers crees/modifies

Fichier cree :

- `reports/narrativeStudio/scenes/ns_scenes_v1_26_bis_scene_runtime_executor_evidence_review.md`

Fichiers modifies :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Fichiers code/test modifies : aucun.

## 8. Review des imports

`packages/map_core/lib/src/runtime/scene_runtime_executor.dart` importe uniquement :

```dart
import 'dart:async';

import 'scene_runtime_plan.dart';
```

Absences confirmees :

- pas de `map_runtime` ;
- pas de `map_battle` ;
- pas de `map_gameplay` ;
- pas de Flutter ;
- pas de Flame ;
- pas de `dart:io` ;
- pas de Yarn parser ;
- pas de `ScenarioRuntimeExecutor` ;
- pas de `PlayableMapGame` ;
- pas de `GameState` ;
- pas de `ProjectManifest` ;
- pas de `SceneGraphLayout`.

## 9. Review API publique

API publique de l'executor :

- `SceneRuntimeExecutor`
- `SceneRuntimeExecutionCallbacks`
- `SceneRuntimeExecutionResult`
- `SceneRuntimeExecutionStatus`
- `SceneRuntimeExecutionTraceEntry`
- `SceneRuntimeExecutionErrorCode`
- `SceneRuntimeIntentCallback`

Cette API est suffisante pour le MVP : elle execute un `SceneRuntimePlan`, injecte les effets metier via callbacks et retourne un resultat trace. Elle n'ouvre pas encore de systeme d'effets persistants, de runtime map, de battle engine reel ou de dialogue engine reel.

Export public confirme dans `packages/map_core/lib/map_core.dart` :

```dart
export 'src/runtime/scene_runtime_plan.dart';
export 'src/runtime/scene_runtime_plan_builder.dart';
export 'src/runtime/scene_runtime_executor.dart';
```

## 10. Review callbacks

Les callbacks sont definis par :

```dart
typedef SceneRuntimeIntentCallback = FutureOr<String> Function(
  SceneRuntimePlanIntent intent,
);
```

Constats :

- callbacks synchrones acceptes : tests dialogue, battle, condition false ;
- callbacks asynchrones acceptes : tests condition true et cinematic `Future.value` ;
- exception callback transformee en `SceneRuntimeExecutionErrorCode.callbackFailed` ;
- aucun callback ne recoit `GameState`, `ProjectManifest`, `MapData`, `PlayableMapGame` ou runtime concret ;
- les callbacks ne retournent qu'un port logique ;
- l'executor ne connait pas Yarn, Battle ou Cinematic reels ;
- les intents recus sont immuables par construction (`final`, listes unmodifiable).

## 11. Review transitions

La resolution de transition se fait par correspondance exacte :

```text
currentNodeId + outputPortId
```

contre :

```text
edge.fromNodeId + edge.fromPortId
```

Comportements verifies :

- zero edge -> `missingTransition` ;
- plusieurs edges -> `ambiguousTransition` ;
- target absent -> `targetNodeMissing` ;
- aucun edge implicite ;
- aucun fallback cache ;
- aucun usage de `SceneGraphLayout`.

## 12. Review intents

Intents supportes :

- `start` -> port `completed` ;
- `merge` -> port `completed` ;
- `end` -> fin, pas de port sortant ;
- `evaluateCondition` -> callback, ports supportes `true` / `false` ;
- `showDialogue` -> callback, port supporte `completed` ;
- `startBattle` -> callback, ports supportes `victory` / `defeat` ;
- `playCinematic` -> callback, port supporte `completed`.

`unsupportedIntent` existe dans l'enum d'erreur comme garde defensive. Avec l'enum public actuel `SceneRuntimePlanIntentKind`, le switch Dart est exhaustif et ce cas n'est pas atteignable sans fabriquer un modele absurde. Aucun faux modele n'a ete ajoute pour le tester artificiellement.

## 13. Review trace

La trace est deterministe parce que l'executor suit :

1. le `startNodeId` du plan ;
2. le port produit par l'intent courant ;
3. l'edge unique correspondant a `fromNodeId + fromPortId`.

Chaque entree trace :

- `nodeId` ;
- `intentKind` ;
- `outputPortId` quand il existe.

La trace est conservee en cas d'echec apres execution d'un node, par exemple :

- `missingTransition` conserve le node et le port retourne ;
- `unsupportedPortResult` conserve le port retourne ;
- `callbackFailed` conserve le node et un port null ;
- `stepLimitExceeded` conserve les pas deja executes.

`SceneRuntimeExecutionResult` rend la trace immutable via `List.unmodifiable`.

## 14. Review resultat

`SceneRuntimeExecutionResult` expose :

- `status` : `completed` ou `failed` ;
- `sceneId` ;
- `finalNodeId` ;
- `sceneOutcomeId` ;
- `errorCode` ;
- `message` ;
- `trace`.

Resultat completed :

- `finalNodeId` correspond au node `end` atteint ;
- `sceneOutcomeId` reprend `currentNode.intent.sceneOutcomeId` si present ;
- `errorCode` et `message` sont null.

Resultat failed :

- `finalNodeId` et `sceneOutcomeId` sont null ;
- `errorCode` est renseigne ;
- `message` est lisible ;
- la trace courante est incluse.

Le message `callbackFailed` inclut l'objet d'erreur Dart, pas de stacktrace brute.

## 15. Review maxSteps

Constats :

- `maxSteps` par defaut = `100` ;
- `maxSteps < 1` refuse par `ArgumentError.value` ;
- depassement -> `SceneRuntimeExecutionErrorCode.stepLimitExceeded` ;
- pas d'analyse de cycle cachee dans l'executor ;
- les cycles restent une responsabilite diagnostics/validation, l'executor garde seulement un garde-fou runtime.

Le test `fails when maxSteps is exceeded` cree une boucle reelle `start -> merge -> start` et verifie l'arret apres trois pas.

## 16. Review non-mutation

`SceneRuntimeExecutor` ne modifie pas le plan :

- `SceneRuntimePlan.nodes` est une liste unmodifiable ;
- `SceneRuntimePlan.edges` est une liste unmodifiable ;
- `SceneRuntimePlan.declaredOutcomes` est une liste unmodifiable ;
- `SceneRuntimePlanNode`, `SceneRuntimePlanEdge` et `SceneRuntimePlanIntent` exposent des champs `final` ;
- les listes internes d'intents (`expectedOutcomes`, `battleDeclaredOutcomes`) sont unmodifiable ;
- le test `does not mutate SceneRuntimePlan` verifie que `nodes`, `edges` et `startNodeId` restent inchanges apres execution.

`SceneRuntimeExecutor` construit des index locaux (`nodesById`) et une trace locale, sans mutation de `SceneRuntimePlan`.

## 17. Tests relances avec sorties exactes

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

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
```

## 18. Tests ajoutes si applicable

Aucun test ajoute. La review n'a pas revele de comportement annonce mais non couvert justifiant une modification.

Elements deja couverts :

- callback sync et async ;
- start/end/dialogue/battle/condition/merge/cinematic ;
- missing start ;
- missing transition ;
- unsupported callback port ;
- ambiguous transition ;
- target missing ;
- callback failed ;
- maxSteps sur boucle reelle ;
- non-mutation de `SceneRuntimePlan` ;
- plan builder ignore layout ;
- Action/Branch blocked avant runtime plan.

## 19. Corrections apportees si applicable

Aucune correction code/test. Les seuls changements sont documentaires :

- rapport V1-26-bis ;
- roadmaps.

## 20. Pourquoi aucun runtime map n'a ete branche

Le scope V1-26-bis est evidence/review. `PlayableMapGame` a ete lu en audit seulement. Aucun callback concret, aucun trigger event, aucun handoff battle/dialogue/cinematic reel et aucune sauvegarde runtime ne sont ajoutes.

## 21. Pourquoi aucun ScenarioAsset n'a ete promu

L'executor consomme uniquement `SceneRuntimePlan`. Il ne convertit pas `SceneAsset` en `ScenarioAsset`, ne convertit pas `ScenarioAsset` en `SceneAsset` et ne modifie pas `ScenarioRuntimeExecutor`.

## 22. Pourquoi aucune consequence persistante n'a ete appliquee

Les callbacks retournent uniquement des ports. L'executor n'ecrit aucun Fact, ne complete aucune step, ne modifie pas `GameState`, ne projette aucune World Rule, ne donne aucun item et ne lance aucun battle engine reel.

## 23. Pourquoi aucune donnee Selbrume n'a ete creee

Les tests utilisent des fixtures generiques (`scene_test`, `dialogue_test`, `trainer_test`, `cinematic_test`, `fact_test`). Aucune scene, map, personnage, lieu ou reference Selbrume produit n'est cree.

## 24. git diff --check

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
Sortie : <vide>
```

## 25. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 .../scenes/road_map_scene_builder_authoring.md          | 17 +++++++++++++++++
 reports/narrativeStudio/scenes/road_map_scenes.md       | 17 +++++++++++++++--
 2 files changed, 32 insertions(+), 2 deletions(-)
```

## 26. git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 27. git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_26_bis_scene_runtime_executor_evidence_review.md
```

## 28. Evidence Pack complet

### Contenu complet de packages/map_core/lib/src/runtime/scene_runtime_executor.dart

```dart
import 'dart:async';

import 'scene_runtime_plan.dart';

typedef SceneRuntimeIntentCallback = FutureOr<String> Function(
  SceneRuntimePlanIntent intent,
);

enum SceneRuntimeExecutionStatus {
  completed,
  failed,
}

enum SceneRuntimeExecutionErrorCode {
  missingStartNode,
  missingTransition,
  ambiguousTransition,
  targetNodeMissing,
  unsupportedIntent,
  unsupportedPortResult,
  callbackFailed,
  stepLimitExceeded,
}

final class SceneRuntimeExecutionCallbacks {
  const SceneRuntimeExecutionCallbacks({
    required this.evaluateCondition,
    required this.showDialogue,
    required this.startBattle,
    required this.playCinematic,
  });

  final SceneRuntimeIntentCallback evaluateCondition;
  final SceneRuntimeIntentCallback showDialogue;
  final SceneRuntimeIntentCallback startBattle;
  final SceneRuntimeIntentCallback playCinematic;
}

final class SceneRuntimeExecutionTraceEntry {
  const SceneRuntimeExecutionTraceEntry({
    required this.nodeId,
    required this.intentKind,
    this.outputPortId,
  });

  final String nodeId;
  final SceneRuntimePlanIntentKind intentKind;
  final String? outputPortId;
}

final class SceneRuntimeExecutionResult {
  SceneRuntimeExecutionResult({
    required this.status,
    required this.sceneId,
    required this.finalNodeId,
    required this.sceneOutcomeId,
    required this.errorCode,
    required this.message,
    required List<SceneRuntimeExecutionTraceEntry> trace,
  }) : trace = List<SceneRuntimeExecutionTraceEntry>.unmodifiable(trace);

  final SceneRuntimeExecutionStatus status;
  final String sceneId;
  final String? finalNodeId;
  final String? sceneOutcomeId;
  final SceneRuntimeExecutionErrorCode? errorCode;
  final String? message;
  final List<SceneRuntimeExecutionTraceEntry> trace;
}

final class SceneRuntimeExecutor {
  SceneRuntimeExecutor({
    required this.callbacks,
    this.maxSteps = 100,
  }) {
    if (maxSteps < 1) {
      throw ArgumentError.value(
        maxSteps,
        'maxSteps',
        'SceneRuntimeExecutor requires maxSteps >= 1.',
      );
    }
  }

  final SceneRuntimeExecutionCallbacks callbacks;
  final int maxSteps;

  Future<SceneRuntimeExecutionResult> execute(SceneRuntimePlan plan) async {
    final nodesById = {
      for (final node in plan.nodes) node.id: node,
    };
    final startNode = nodesById[plan.startNodeId];
    final trace = <SceneRuntimeExecutionTraceEntry>[];

    if (startNode == null) {
      return _failed(
        plan,
        SceneRuntimeExecutionErrorCode.missingStartNode,
        'Scene runtime start node "${plan.startNodeId}" is missing.',
        trace,
      );
    }

    var currentNode = startNode;
    for (var step = 0; step < maxSteps; step++) {
      final outputPortResult = await _resolveOutputPort(currentNode.intent);
      if (outputPortResult.errorCode != null) {
        trace.add(
          SceneRuntimeExecutionTraceEntry(
            nodeId: currentNode.id,
            intentKind: currentNode.intent.kind,
            outputPortId: outputPortResult.outputPortId,
          ),
        );
        return _failed(
          plan,
          outputPortResult.errorCode!,
          outputPortResult.message!,
          trace,
        );
      }

      final outputPortId = outputPortResult.outputPortId;
      trace.add(
        SceneRuntimeExecutionTraceEntry(
          nodeId: currentNode.id,
          intentKind: currentNode.intent.kind,
          outputPortId: outputPortId,
        ),
      );

      if (currentNode.intent.kind == SceneRuntimePlanIntentKind.end) {
        return SceneRuntimeExecutionResult(
          status: SceneRuntimeExecutionStatus.completed,
          sceneId: plan.sceneId,
          finalNodeId: currentNode.id,
          sceneOutcomeId: currentNode.intent.sceneOutcomeId,
          errorCode: null,
          message: null,
          trace: trace,
        );
      }

      final transition = _findTransition(
        plan,
        currentNodeId: currentNode.id,
        outputPortId: outputPortId!,
      );
      if (transition.errorCode != null) {
        return _failed(
          plan,
          transition.errorCode!,
          transition.message!,
          trace,
        );
      }

      final nextNode = nodesById[transition.edge!.toNodeId];
      if (nextNode == null) {
        return _failed(
          plan,
          SceneRuntimeExecutionErrorCode.targetNodeMissing,
          'Scene runtime target node "${transition.edge!.toNodeId}" is missing.',
          trace,
        );
      }
      currentNode = nextNode;
    }

    return _failed(
      plan,
      SceneRuntimeExecutionErrorCode.stepLimitExceeded,
      'Scene runtime exceeded maxSteps=$maxSteps.',
      trace,
    );
  }

  Future<_OutputPortResult> _resolveOutputPort(
    SceneRuntimePlanIntent intent,
  ) async {
    switch (intent.kind) {
      case SceneRuntimePlanIntentKind.start:
      case SceneRuntimePlanIntentKind.merge:
        return const _OutputPortResult(outputPortId: 'completed');
      case SceneRuntimePlanIntentKind.end:
        return const _OutputPortResult();
      case SceneRuntimePlanIntentKind.evaluateCondition:
        return _callbackOutput(
          intent,
          callbacks.evaluateCondition,
          const {'true', 'false'},
        );
      case SceneRuntimePlanIntentKind.showDialogue:
        return _callbackOutput(
          intent,
          callbacks.showDialogue,
          const {'completed'},
        );
      case SceneRuntimePlanIntentKind.startBattle:
        return _callbackOutput(
          intent,
          callbacks.startBattle,
          const {'victory', 'defeat'},
        );
      case SceneRuntimePlanIntentKind.playCinematic:
        return _callbackOutput(
          intent,
          callbacks.playCinematic,
          const {'completed'},
        );
    }
  }

  Future<_OutputPortResult> _callbackOutput(
    SceneRuntimePlanIntent intent,
    SceneRuntimeIntentCallback callback,
    Set<String> supportedOutputPorts,
  ) async {
    String outputPortId;
    try {
      outputPortId = await callback(intent);
    } catch (error) {
      return _OutputPortResult(
        errorCode: SceneRuntimeExecutionErrorCode.callbackFailed,
        message:
            'Scene runtime callback failed for ${intent.kind.name}: $error',
      );
    }

    if (!supportedOutputPorts.contains(outputPortId)) {
      return _OutputPortResult(
        outputPortId: outputPortId,
        errorCode: SceneRuntimeExecutionErrorCode.unsupportedPortResult,
        message:
            'Scene runtime callback returned unsupported port "$outputPortId" '
            'for ${intent.kind.name}.',
      );
    }

    return _OutputPortResult(outputPortId: outputPortId);
  }
}

_TransitionResult _findTransition(
  SceneRuntimePlan plan, {
  required String currentNodeId,
  required String outputPortId,
}) {
  final matches = plan.edges
      .where(
        (edge) =>
            edge.fromNodeId == currentNodeId && edge.fromPortId == outputPortId,
      )
      .toList(growable: false);

  if (matches.isEmpty) {
    return _TransitionResult(
      errorCode: SceneRuntimeExecutionErrorCode.missingTransition,
      message: 'Scene runtime has no transition from "$currentNodeId" '
          'through port "$outputPortId".',
    );
  }

  if (matches.length > 1) {
    return _TransitionResult(
      errorCode: SceneRuntimeExecutionErrorCode.ambiguousTransition,
      message: 'Scene runtime has multiple transitions from "$currentNodeId" '
          'through port "$outputPortId".',
    );
  }

  return _TransitionResult(edge: matches.single);
}

SceneRuntimeExecutionResult _failed(
  SceneRuntimePlan plan,
  SceneRuntimeExecutionErrorCode errorCode,
  String message,
  List<SceneRuntimeExecutionTraceEntry> trace,
) {
  return SceneRuntimeExecutionResult(
    status: SceneRuntimeExecutionStatus.failed,
    sceneId: plan.sceneId,
    finalNodeId: null,
    sceneOutcomeId: null,
    errorCode: errorCode,
    message: message,
    trace: trace,
  );
}

final class _OutputPortResult {
  const _OutputPortResult({
    this.outputPortId,
    this.errorCode,
    this.message,
  });

  final String? outputPortId;
  final SceneRuntimeExecutionErrorCode? errorCode;
  final String? message;
}

final class _TransitionResult {
  const _TransitionResult({
    this.edge,
    this.errorCode,
    this.message,
  });

  final SceneRuntimePlanEdge? edge;
  final SceneRuntimeExecutionErrorCode? errorCode;
  final String? message;
}
```

### Contenu complet de packages/map_core/test/scene_runtime_executor_test.dart

```dart
import 'dart:async';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SceneRuntimeExecutor MVP', () {
    test('executes start to end', () async {
      final plan = _plan(
        nodes: [_startNode(), _endNode()],
        edges: [_edge('edge_start_end', 'node_start', 'completed', 'node_end')],
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(result.sceneId, 'scene_test');
      expect(result.finalNodeId, 'node_end');
      expect(result.sceneOutcomeId, isNull);
      expect(result.errorCode, isNull);
      expect(
        result.trace.map((entry) => (entry.nodeId, entry.outputPortId)),
        [('node_start', 'completed'), ('node_end', null)],
      );
    });

    test('exposes final scene outcome id from end intent', () async {
      final plan = _plan(
        nodes: [
          _startNode(),
          _endNode(sceneOutcomeId: 'scene_done'),
        ],
        edges: [_edge('edge_start_end', 'node_start', 'completed', 'node_end')],
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(result.finalNodeId, 'node_end');
      expect(result.sceneOutcomeId, 'scene_done');
    });

    test('executes a plan built from a SceneAsset without ProjectManifest',
        () async {
      final scene = SceneAsset(
        id: 'scene_test',
        name: 'Runtime Executor Test Scene',
        graph: SceneGraph(
          startNodeId: 'node_start',
          nodes: [
            SceneNode(id: 'node_start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'node_dialogue',
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(dialogueId: 'dialogue_test'),
            ),
            SceneNode(
              id: 'node_battle',
              kind: SceneNodeKind.battle,
              payload: SceneBattlePayload(
                battleKind: 'trainer',
                trainerId: 'trainer_test',
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
            SceneNodeLayout(nodeId: 'node_start', x: 1000, y: -80),
            SceneNodeLayout(nodeId: 'node_dialogue', x: -300, y: 440),
            SceneNodeLayout(nodeId: 'node_battle', x: 0, y: 0),
          ],
        ),
      );
      final plan = buildSceneRuntimePlan(scene).plan!;

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(startBattle: (_) => 'defeat'),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(result.finalNodeId, 'node_end_defeat');
      expect(result.trace.map((entry) => entry.nodeId), [
        'node_start',
        'node_dialogue',
        'node_battle',
        'node_end_defeat',
      ]);
    });

    test('executes start to dialogue completed to end', () async {
      final plan = _plan(
        nodes: [_startNode(), _dialogueNode(), _endNode()],
        edges: [
          _edge('edge_start_dialogue', 'node_start', 'completed',
              'node_dialogue'),
          _edge('edge_dialogue_end', 'node_dialogue', 'completed', 'node_end'),
        ],
      );
      var dialogueCalls = 0;

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(
          showDialogue: (intent) {
            dialogueCalls++;
            expect(intent.dialogueId, 'dialogue_test');
            return 'completed';
          },
        ),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(dialogueCalls, 1);
      expect(
        result.trace.map((entry) => entry.nodeId),
        ['node_start', 'node_dialogue', 'node_end'],
      );
    });

    test('executes battle victory branch', () async {
      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(startBattle: (_) => 'victory'),
      ).execute(_battleBranchPlan());

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(result.finalNodeId, 'node_end_victory');
      expect(
        result.trace.map((entry) => (entry.nodeId, entry.outputPortId)),
        [
          ('node_start', 'completed'),
          ('node_battle', 'victory'),
          ('node_end_victory', null),
        ],
      );
    });

    test('executes battle defeat branch', () async {
      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(startBattle: (_) => 'defeat'),
      ).execute(_battleBranchPlan());

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(result.finalNodeId, 'node_end_defeat');
      expect(
        result.trace.map((entry) => (entry.nodeId, entry.outputPortId)),
        [
          ('node_start', 'completed'),
          ('node_battle', 'defeat'),
          ('node_end_defeat', null),
        ],
      );
    });

    test('executes condition true branch', () async {
      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(evaluateCondition: (_) async => 'true'),
      ).execute(_conditionBranchPlan());

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(result.finalNodeId, 'node_end_victory');
      expect(result.trace[1].outputPortId, 'true');
    });

    test('executes condition false branch', () async {
      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(evaluateCondition: (_) => 'false'),
      ).execute(_conditionBranchPlan());

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(result.finalNodeId, 'node_end_defeat');
      expect(result.trace[1].outputPortId, 'false');
    });

    test('executes merge as passthrough', () async {
      final plan = _plan(
        nodes: [_startNode(), _mergeNode(), _endNode()],
        edges: [
          _edge('edge_start_merge', 'node_start', 'completed', 'node_merge'),
          _edge('edge_merge_end', 'node_merge', 'completed', 'node_end'),
        ],
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(
        result.trace.map((entry) => (entry.nodeId, entry.outputPortId)),
        [
          ('node_start', 'completed'),
          ('node_merge', 'completed'),
          ('node_end', null),
        ],
      );
    });

    test('executes cinematic completed via callback', () async {
      final plan = _plan(
        nodes: [_startNode(), _cinematicNode(), _endNode()],
        edges: [
          _edge('edge_start_cinematic', 'node_start', 'completed',
              'node_cinematic'),
          _edge(
            'edge_cinematic_end',
            'node_cinematic',
            'completed',
            'node_end',
            kind: SceneEdgeKind.cinematicCompleted,
          ),
        ],
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(playCinematic: (_) => Future.value('completed')),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(result.finalNodeId, 'node_end');
      expect(result.trace[1].outputPortId, 'completed');
    });

    test('fails when start node is missing from plan', () async {
      final plan = _plan(
        nodes: [_endNode()],
        edges: const [],
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.failed);
      expect(result.errorCode, SceneRuntimeExecutionErrorCode.missingStartNode);
      expect(result.trace, isEmpty);
    });

    test('fails when returned port has no transition', () async {
      final plan = _plan(
        nodes: [_startNode(), _dialogueNode(), _endNode()],
        edges: [
          _edge('edge_start_dialogue', 'node_start', 'completed',
              'node_dialogue'),
        ],
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(showDialogue: (_) => 'completed'),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.failed);
      expect(
          result.errorCode, SceneRuntimeExecutionErrorCode.missingTransition);
      expect(result.trace.last.nodeId, 'node_dialogue');
      expect(result.trace.last.outputPortId, 'completed');
    });

    test('fails when returned port is unsupported', () async {
      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(showDialogue: (_) => 'accept'),
      ).execute(_dialoguePlan());

      expect(result.status, SceneRuntimeExecutionStatus.failed);
      expect(
        result.errorCode,
        SceneRuntimeExecutionErrorCode.unsupportedPortResult,
      );
      expect(result.trace.last.nodeId, 'node_dialogue');
      expect(result.trace.last.outputPortId, 'accept');
    });

    test('fails when multiple transitions match same node and port', () async {
      final plan = _plan(
        nodes: [_startNode(), _endNode(), _endNode(id: 'node_end_defeat')],
        edges: [
          _edge('edge_start_end', 'node_start', 'completed', 'node_end'),
          _edge(
              'edge_start_end_2', 'node_start', 'completed', 'node_end_defeat'),
        ],
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.failed);
      expect(
        result.errorCode,
        SceneRuntimeExecutionErrorCode.ambiguousTransition,
      );
    });

    test('fails when target node is missing', () async {
      final plan = _plan(
        nodes: [_startNode()],
        edges: [
          _edge('edge_start_missing', 'node_start', 'completed', 'node_end'),
        ],
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.failed);
      expect(
          result.errorCode, SceneRuntimeExecutionErrorCode.targetNodeMissing);
    });

    test('fails when callback throws', () async {
      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(
          showDialogue: (_) => throw StateError('dialogue failed'),
        ),
      ).execute(_dialoguePlan());

      expect(result.status, SceneRuntimeExecutionStatus.failed);
      expect(result.errorCode, SceneRuntimeExecutionErrorCode.callbackFailed);
      expect(result.message, contains('dialogue failed'));
      expect(result.trace.last.nodeId, 'node_dialogue');
      expect(result.trace.last.outputPortId, isNull);
    });

    test('fails when maxSteps is exceeded', () async {
      final plan = _plan(
        nodes: [_startNode(), _mergeNode()],
        edges: [
          _edge('edge_start_merge', 'node_start', 'completed', 'node_merge'),
          _edge('edge_merge_start', 'node_merge', 'completed', 'node_start'),
        ],
      );

      final result = await SceneRuntimeExecutor(
        callbacks: _callbacks(),
        maxSteps: 3,
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.failed);
      expect(
          result.errorCode, SceneRuntimeExecutionErrorCode.stepLimitExceeded);
      expect(result.trace.map((entry) => entry.nodeId), [
        'node_start',
        'node_merge',
        'node_start',
      ]);
    });

    test('does not mutate SceneRuntimePlan', () async {
      final plan = _dialoguePlan();
      final beforeNodes = List<SceneRuntimePlanNode>.of(plan.nodes);
      final beforeEdges = List<SceneRuntimePlanEdge>.of(plan.edges);

      await SceneRuntimeExecutor(
        callbacks: _callbacks(showDialogue: (_) => 'completed'),
      ).execute(plan);

      expect(plan.nodes, beforeNodes);
      expect(plan.edges, beforeEdges);
      expect(plan.startNodeId, 'node_start');
    });
  });
}

SceneRuntimeExecutionCallbacks _callbacks({
  FutureOr<String> Function(SceneRuntimePlanIntent intent)? evaluateCondition,
  FutureOr<String> Function(SceneRuntimePlanIntent intent)? showDialogue,
  FutureOr<String> Function(SceneRuntimePlanIntent intent)? startBattle,
  FutureOr<String> Function(SceneRuntimePlanIntent intent)? playCinematic,
}) {
  return SceneRuntimeExecutionCallbacks(
    evaluateCondition: evaluateCondition ?? (_) => 'true',
    showDialogue: showDialogue ?? (_) => 'completed',
    startBattle: startBattle ?? (_) => 'victory',
    playCinematic: playCinematic ?? (_) => 'completed',
  );
}

SceneRuntimePlan _dialoguePlan() {
  return _plan(
    nodes: [_startNode(), _dialogueNode(), _endNode()],
    edges: [
      _edge('edge_start_dialogue', 'node_start', 'completed', 'node_dialogue'),
      _edge('edge_dialogue_end', 'node_dialogue', 'completed', 'node_end'),
    ],
  );
}

SceneRuntimePlan _battleBranchPlan() {
  return _plan(
    nodes: [
      _startNode(),
      _battleNode(),
      _endNode(id: 'node_end_victory'),
      _endNode(id: 'node_end_defeat'),
    ],
    edges: [
      _edge('edge_start_battle', 'node_start', 'completed', 'node_battle'),
      _edge(
        'edge_battle_victory',
        'node_battle',
        'victory',
        'node_end_victory',
        kind: SceneEdgeKind.battleVictory,
      ),
      _edge(
        'edge_battle_defeat',
        'node_battle',
        'defeat',
        'node_end_defeat',
        kind: SceneEdgeKind.battleDefeat,
      ),
    ],
  );
}

SceneRuntimePlan _conditionBranchPlan() {
  return _plan(
    nodes: [
      _startNode(),
      _conditionNode(),
      _endNode(id: 'node_end_victory'),
      _endNode(id: 'node_end_defeat'),
    ],
    edges: [
      _edge(
        'edge_start_condition',
        'node_start',
        'completed',
        'node_condition',
      ),
      _edge(
        'edge_condition_true',
        'node_condition',
        'true',
        'node_end_victory',
        kind: SceneEdgeKind.conditionTrue,
      ),
      _edge(
        'edge_condition_false',
        'node_condition',
        'false',
        'node_end_defeat',
        kind: SceneEdgeKind.conditionFalse,
      ),
    ],
  );
}

SceneRuntimePlan _plan({
  required List<SceneRuntimePlanNode> nodes,
  required List<SceneRuntimePlanEdge> edges,
}) {
  return SceneRuntimePlan(
    sceneId: 'scene_test',
    startNodeId: 'node_start',
    nodes: nodes,
    edges: edges,
    declaredOutcomes: const [],
  );
}

SceneRuntimePlanNode _startNode() {
  return SceneRuntimePlanNode(
    id: 'node_start',
    kind: SceneNodeKind.start,
    intent: SceneRuntimePlanIntent.start(),
  );
}

SceneRuntimePlanNode _dialogueNode() {
  return SceneRuntimePlanNode(
    id: 'node_dialogue',
    kind: SceneNodeKind.yarnDialogue,
    intent: SceneRuntimePlanIntent.showDialogue(dialogueId: 'dialogue_test'),
  );
}

SceneRuntimePlanNode _battleNode() {
  return SceneRuntimePlanNode(
    id: 'node_battle',
    kind: SceneNodeKind.battle,
    intent: SceneRuntimePlanIntent.startBattle(
      battleKind: 'trainer',
      trainerId: 'trainer_test',
      declaredOutcomes: const ['victory', 'defeat'],
    ),
  );
}

SceneRuntimePlanNode _conditionNode() {
  return SceneRuntimePlanNode(
    id: 'node_condition',
    kind: SceneNodeKind.condition,
    intent: SceneRuntimePlanIntent.evaluateCondition(
      source: SceneConditionSource(
        sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
        sourceId: 'fact_test',
        operator: SceneConditionOperator.isTrue,
      ),
    ),
  );
}

SceneRuntimePlanNode _mergeNode() {
  return SceneRuntimePlanNode(
    id: 'node_merge',
    kind: SceneNodeKind.merge,
    intent: SceneRuntimePlanIntent.merge(),
  );
}

SceneRuntimePlanNode _cinematicNode() {
  return SceneRuntimePlanNode(
    id: 'node_cinematic',
    kind: SceneNodeKind.cinematic,
    intent: SceneRuntimePlanIntent.playCinematic(
      cinematicId: 'cinematic_test',
    ),
  );
}

SceneRuntimePlanNode _endNode({
  String id = 'node_end',
  String? sceneOutcomeId,
}) {
  return SceneRuntimePlanNode(
    id: id,
    kind: SceneNodeKind.end,
    intent: SceneRuntimePlanIntent.end(sceneOutcomeId: sceneOutcomeId),
  );
}

SceneRuntimePlanEdge _edge(
  String id,
  String fromNodeId,
  String fromPortId,
  String toNodeId, {
  SceneEdgeKind kind = SceneEdgeKind.defaultFlow,
}) {
  return SceneRuntimePlanEdge(
    id: id,
    fromNodeId: fromNodeId,
    fromPortId: fromPortId,
    toNodeId: toNodeId,
    kind: kind,
  );
}
```

### Sections completes modifiees de road_map_scenes.md

```text
| NS-SCENES-V1-26-bis — Scene Runtime Executor Evidence & Review Hardening | DONE | Review/evidence hardening de V1-26 : executor confirme pur, tests/analyze relances, fichiers executor/test reproduits integralement, aucun runtime map ni V1-27 demarre. |
```

```text
Raison : V1-26-bis a confirme l'evidence et la surete de l'executor pur V1-26 sans demarrer V1-27. Avant le golden slice complet, les World Rules doivent maintenant devenir visibles/configurables depuis leurs cibles map/entity/event pour que les consequences ne restent pas de simples lignes abstraites dans l'overview.

Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0.
```

```text
## Decisions V1-26-bis

- `SceneRuntimeExecutor` V1-26 est confirme comme pur : il importe seulement `dart:async` et `scene_runtime_plan.dart`.
- L'audit confirme l'absence de `map_runtime`, `map_battle`, `map_gameplay`, Flutter, Flame, disque, Yarn parser, `ScenarioRuntimeExecutor`, `PlayableMapGame`, `GameState` et `ProjectManifest` dans l'executor.
- Les callbacks restent la seule frontiere metier : condition, dialogue, battle et cinematic retournent des ports, puis l'executor suit uniquement `currentNodeId + outputPortId`.
- La trace, les erreurs, `maxSteps`, la non-mutation de `SceneRuntimePlan` et les listes immuables sont documentes dans un Evidence Pack complet.
- Aucun test ou correctif code supplementaire n'a ete necessaire apres review ; les tests V1-26 ont ete relances.
- Aucun `PlayableMapGame`, Event -> Scene runtime trigger, `ScenarioRuntimeExecutor`, `StorylineStep.sceneLinkIds`, import `map_battle`, mutation `GameState`, Fact write, World Rule projection runtime, consequence persistante, fake ref ou donnee Selbrume n'est ajoute.
- Tests executes : `cd packages/map_core && dart test test/scene_runtime_executor_test.dart`, `cd packages/map_core && dart test test/scene_runtime_plan_test.dart`, `cd packages/map_core && dart analyze`, verification finale `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-27 — World Rules Map Editor Integration V0`.
```

### Sections completes modifiees de road_map_scene_builder_authoring.md

```text
| NS-SCENES-V1-26-bis | Scene Runtime Executor Evidence & Review Hardening | review / evidence | Fermer V1-26 avec audit imports/API/callbacks/transitions/intents/trace/resultat/maxSteps/non-mutation et Evidence Pack complet. | Pas de V1-27, pas de runtime map, pas de nouvelle feature, pas de ScenarioAsset, pas de consequences persistantes. | rapport V1-26-bis, roadmaps. | DONE : executor/test reproduits integralement dans le rapport, tests/analyze relances, `git diff --check` final. | Review trop legere sur un futur coeur runtime ; evidence incomplete. | DONE : V1-26 confirme, aucun runtime map branche, V1-27 reste TODO. | V1-26. |
```

```text
## Mise a jour V1-26-bis

Statut : `NS-SCENES-V1-26-bis — Scene Runtime Executor Evidence & Review Hardening` est DONE.

Decision : V1-26 est confirme apres audit/evidence. `SceneRuntimeExecutor` reste un executor pur de `SceneRuntimePlan`, sans import runtime/battle/gameplay/editor, sans `ProjectManifest`, sans layout, sans disque, sans Yarn parser, sans battle engine et sans consequence persistante.

Evidence : le rapport V1-26-bis reproduit integralement `packages/map_core/lib/src/runtime/scene_runtime_executor.dart` et `packages/map_core/test/scene_runtime_executor_test.dart`, documente les reviews imports/API/callbacks/transitions/intents/trace/resultat/maxSteps/non-mutation et relance les tests/analyze V1-26.

Corrections code : aucune. La review n'a pas trouve de faille concrete justifiant une modification de l'executor ou des tests.

Limites : V1-27 n'est pas commence. Aucun `PlayableMapGame`, Event -> Scene runtime trigger, `ScenarioRuntimeExecutor`, `ScenarioAsset`, `StorylineStep.sceneLinkIds`, Fact write, World Rule projection runtime ou donnee Selbrume n'est ajoute.

Tests : `cd packages/map_core && dart test test/scene_runtime_executor_test.dart`, `cd packages/map_core && dart test test/scene_runtime_plan_test.dart`, `cd packages/map_core && dart analyze`, `git diff --check`.

Prochain lot exact : `NS-SCENES-V1-27 — World Rules Map Editor Integration V0`.
```

### Diff complet de road_map_scenes.md et road_map_scene_builder_authoring.md

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index ba5d186e..5542d942 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -50,6 +50,7 @@ NS-SCENES-V1-27 — World Rules Map Editor Integration V0
 | NS-SCENES-V1-25 | Diagnostics / Validator Expansion | core / editor | DONE : diagnostics refs projet, ports V0, duplicates, unreachable/cycles et Event -> Scene readiness renforces. | Pas de correction auto, pas de Validator global complet si trop large. | `scene_diagnostics.dart`, `event_scene_link_diagnostics.dart`, tests diagnostics/runtime-plan. | DONE : tests refs inconnues, missing outputs, unreachable, cycles, severity, fact/world rule/event refs. | Trop bloquer les drafts ; confusion warning/error. | DONE : erreurs runtime bloquantes explicites, warnings authoring conserves pour drafts, builder runtime-plan reste pur. | V1-22, V1-23, V1-24. |
 | NS-SCENES-V1-25-bis | Dialogue/Battle Ports Authoring V0 | core / editor | Rendre `yarnDialogue.completed` et `battle.victory/defeat` authorables, diagnostiques et connectables visuellement avant runtime executor. | Pas de runtime Scene, pas de parsing Yarn, pas de BranchByOutcome authoring, pas de Cinematic/Action ports nouveaux, pas de Selbrume. | `scene_authoring_operations.dart`, `scene_diagnostics.dart`, runtime-plan tests, graph view, Scenes widget tests, screenshot V1-25-bis. | DONE : ports authorables, edges derives, diagnostics warning/error, runtime-plan preserve, canvas drag/drop Dialogue/Battle, visual gate. | Inventer des outcomes Yarn ; rendre le battle runtime-aware ; ouvrir Branch trop tot. | DONE : Dialogue et Battle deviennent branchables sans fake refs, sans execution et sans nouveau moteur. | V1-22, V1-24, V1-25. |
 | NS-SCENES-V1-26 | Scene Runtime Executor MVP | core | DONE : executer un sous-ensemble `SceneRuntimePlan` via callbacks limites condition/dialogue/cinematic/battle, avec trace, erreurs et `maxSteps`. | Pas de branchement PlayableMapGame, pas Event -> Scene runtime, pas de ScenarioAsset, pas de consequences persistantes. | `scene_runtime_executor.dart`, tests executor. | DONE : start/end/dialogue/battle/condition/merge/cinematic, erreurs transitions/callback/cycle, no layout/project. | Refaire ScenarioRuntimeExecutor ; effets persistants implicites ; importer runtime/battle. | DONE : executor pur map_core, callbacks explicites, aucun ScenarioAsset canonique, aucun runtime map. | V1-24, V1-25, V1-25-bis. |
+| NS-SCENES-V1-26-bis | Scene Runtime Executor Evidence & Review Hardening | review / evidence | Fermer V1-26 avec audit imports/API/callbacks/transitions/intents/trace/resultat/maxSteps/non-mutation et Evidence Pack complet. | Pas de V1-27, pas de runtime map, pas de nouvelle feature, pas de ScenarioAsset, pas de consequences persistantes. | rapport V1-26-bis, roadmaps. | DONE : executor/test reproduits integralement dans le rapport, tests/analyze relances, `git diff --check` final. | Review trop legere sur un futur coeur runtime ; evidence incomplete. | DONE : V1-26 confirme, aucun runtime map branche, V1-27 reste TODO. | V1-26. |
 | NS-SCENES-V1-27 | World Rules Map Editor Integration V0 | editor / core | Rendre les World Rules visibles/configurables depuis les maps, entites, PNJ et events cibles. | Pas de runtime Scene complet, pas de collision/warp dynamique, pas de seed Selbrume. | map/entity inspectors, world rule pickers, diagnostics. | Tests affichage contextuel, picker target, refs inconnues, overview toujours coherent. | World Rules inutilisables si seulement en overview ; UI trop large. | Les rules peuvent etre inspectees depuis leur cible map sans exposer flags bruts. | V1-20, V1-25 utile. |
 | NS-SCENES-V1-28 | Golden Slice Selbrume Scene/Event Prep | mixed / fixtures | Preparer le slice Lysa/rival en fixtures ou projet controle : event -> scene -> dialogue/outcome -> combat/consequence. | Pas de seed produit hardcode, pas de raccourci runtime. | fixtures tests, reports Selbrume. | Golden tests atteignabilite, diagnostics, event trigger prep. | Mettre des donnees Selbrume dans le produit ; scope trop large. | Slice de test prouve la chaine, sans hardcode produit. | V1-22, V1-23, V1-26, V1-27. |
 | NS-SCENES-V1-29 | StorylineStep to Scene Link | core / editor | Brancher `StorylineStep.sceneLinkIds` vers scenes stables. | Pas de declenchement runtime par StoryStep seul, pas de lien scenario legacy. | storyline models/UI validators si necessaire. | Tests refs scene, UI disabled/enabled, diagnostics link. | Confondre step et trigger ; progression pilotant toute la scene. | StoryStep peut referencer Scene pour lecture/progression, sans remplacer Event trigger. | V1-23, V1-26, V1-28. |
@@ -333,6 +334,22 @@ Tests : `cd packages/map_core && dart test test/scene_runtime_executor_test.dart

 Prochain lot exact : `NS-SCENES-V1-27 — World Rules Map Editor Integration V0`.

+## Mise a jour V1-26-bis
+
+Statut : `NS-SCENES-V1-26-bis — Scene Runtime Executor Evidence & Review Hardening` est DONE.
+
+Decision : V1-26 est confirme apres audit/evidence. `SceneRuntimeExecutor` reste un executor pur de `SceneRuntimePlan`, sans import runtime/battle/gameplay/editor, sans `ProjectManifest`, sans layout, sans disque, sans Yarn parser, sans battle engine et sans consequence persistante.
+
+Evidence : le rapport V1-26-bis reproduit integralement `packages/map_core/lib/src/runtime/scene_runtime_executor.dart` et `packages/map_core/test/scene_runtime_executor_test.dart`, documente les reviews imports/API/callbacks/transitions/intents/trace/resultat/maxSteps/non-mutation et relance les tests/analyze V1-26.
+
+Corrections code : aucune. La review n'a pas trouve de faille concrete justifiant une modification de l'executor ou des tests.
+
+Limites : V1-27 n'est pas commence. Aucun `PlayableMapGame`, Event -> Scene runtime trigger, `ScenarioRuntimeExecutor`, `ScenarioAsset`, `StorylineStep.sceneLinkIds`, Fact write, World Rule projection runtime ou donnee Selbrume n'est ajoute.
+
+Tests : `cd packages/map_core && dart test test/scene_runtime_executor_test.dart`, `cd packages/map_core && dart test test/scene_runtime_plan_test.dart`, `cd packages/map_core && dart analyze`, `git diff --check`.
+
+Prochain lot exact : `NS-SCENES-V1-27 — World Rules Map Editor Integration V0`.
+
 ## Selbrume golden slice

 Avant le golden slice, il faut au minimum :
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 910876b2..d6eb371d 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -71,6 +71,7 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-25 — Diagnostics / Validator Expansion | DONE | Diagnostics Scene V1 renforces : ports V0, duplicates, unreachable/cycles, refs projet Dialogue/Battle/Cinematic/Facts/World Rules et readiness Event -> Scene via SceneRuntimePlan. |
 | NS-SCENES-V1-25-bis — Dialogue/Battle Ports Authoring V0 | DONE | Ports authorables Dialogue.completed et Battle.victory/defeat ajoutes aux sources de verite, diagnostics, runtime-plan preservation et canvas visual-port, sans runtime ni outcomes Yarn inventes. |
 | NS-SCENES-V1-26 — Scene Runtime Executor MVP | DONE | Executor pur `map_core` pour parcourir un `SceneRuntimePlan` via callbacks condition/dialogue/battle/cinematic, trace, erreurs propres et `maxSteps`, sans branchement runtime map. |
+| NS-SCENES-V1-26-bis — Scene Runtime Executor Evidence & Review Hardening | DONE | Review/evidence hardening de V1-26 : executor confirme pur, tests/analyze relances, fichiers executor/test reproduits integralement, aucun runtime map ni V1-27 demarre. |
 | NS-SCENES-V1-27 — World Rules Map Editor Integration V0 | TODO | Rendre les World Rules visibles/configurables depuis le contexte map/entity/event sans brancher de runtime Scene. |
 | NS-SCENES-V1-28 — Golden Slice Selbrume Scene/Event Prep | TODO | Preparer le slice test Lysa/rival via fixtures ou projet controle, sans hardcode produit. |
 | NS-SCENES-V1-29 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres builder, triggers, runtime MVP et golden slice stabilises. |
@@ -79,9 +80,9 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr

 `NS-SCENES-V1-27 — World Rules Map Editor Integration V0`

-Raison : V1-26 a pose un executor pur et testable pour `SceneRuntimePlan`, sans branchement `PlayableMapGame` ni consequences persistantes. Avant le golden slice complet, les World Rules doivent maintenant devenir visibles/configurables depuis leurs cibles map/entity/event pour que les consequences ne restent pas de simples lignes abstraites dans l'overview.
+Raison : V1-26-bis a confirme l'evidence et la surete de l'executor pur V1-26 sans demarrer V1-27. Avant le golden slice complet, les World Rules doivent maintenant devenir visibles/configurables depuis leurs cibles map/entity/event pour que les consequences ne restent pas de simples lignes abstraites dans l'overview.

-Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis World Rules Map Editor Integration V0.
+Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0.

 Note non bloquante : l'overview affiche encore parfois `Facts — necessite un modele` alors que Fact Registry V0 existe depuis V1-18. Ce point reste un polish d'alignement UI, pas le prochain blocage du golden slice.

@@ -140,6 +141,18 @@ Prochain lot exact : `NS-SCENES-V1-26 — Scene Runtime Executor MVP`.

 Prochain lot exact : `NS-SCENES-V1-27 — World Rules Map Editor Integration V0`.

+## Decisions V1-26-bis
+
+- `SceneRuntimeExecutor` V1-26 est confirme comme pur : il importe seulement `dart:async` et `scene_runtime_plan.dart`.
+- L'audit confirme l'absence de `map_runtime`, `map_battle`, `map_gameplay`, Flutter, Flame, disque, Yarn parser, `ScenarioRuntimeExecutor`, `PlayableMapGame`, `GameState` et `ProjectManifest` dans l'executor.
+- Les callbacks restent la seule frontiere metier : condition, dialogue, battle et cinematic retournent des ports, puis l'executor suit uniquement `currentNodeId + outputPortId`.
+- La trace, les erreurs, `maxSteps`, la non-mutation de `SceneRuntimePlan` et les listes immuables sont documentes dans un Evidence Pack complet.
+- Aucun test ou correctif code supplementaire n'a ete necessaire apres review ; les tests V1-26 ont ete relances.
+- Aucun `PlayableMapGame`, Event -> Scene runtime trigger, `ScenarioRuntimeExecutor`, `StorylineStep.sceneLinkIds`, import `map_battle`, mutation `GameState`, Fact write, World Rule projection runtime, consequence persistante, fake ref ou donnee Selbrume n'est ajoute.
+- Tests executes : `cd packages/map_core && dart test test/scene_runtime_executor_test.dart`, `cd packages/map_core && dart test test/scene_runtime_plan_test.dart`, `cd packages/map_core && dart analyze`, verification finale `git diff --check`.
+
+Prochain lot exact : `NS-SCENES-V1-27 — World Rules Map Editor Integration V0`.
+
 ## Decisions V1-23-bis

 - `MapEventPage` porte maintenant un `sceneTarget` explicite vers une `SceneAsset` reelle ; aucun `sceneId` global n'est ajoute sur `MapEventDefinition`.
```

### Sorties finales Git

Les sorties finales sont reproduites dans les sections 24 a 27.

## 29. Auto-review critique

- Est-ce que j'ai demarre V1-27 ? Non.
- Est-ce que j'ai modifie `PlayableMapGame` ? Non.
- Est-ce que j'ai branche Event -> Scene runtime ? Non.
- Est-ce que j'ai modifie `ScenarioRuntimeExecutor` ? Non.
- Est-ce que j'ai promu `ScenarioAsset` ? Non.
- Est-ce que j'ai branche `StorylineStep.sceneLinkIds` ? Non.
- Est-ce que j'ai importe `map_battle` ? Non.
- Est-ce que j'ai importe `map_runtime` dans `map_core` ? Non.
- Est-ce que l'executor lit le disque ? Non.
- Est-ce que l'executor parse Yarn ? Non.
- Est-ce que l'executor modifie `GameState` ? Non.
- Est-ce que l'executor applique des Facts/World Rules/consequences ? Non.
- Est-ce que le rapport contient `scene_runtime_executor.dart` en entier ? Oui.
- Est-ce que le rapport contient `scene_runtime_executor_test.dart` en entier ? Oui.
- Est-ce que les tests V1-26 ont ete relances ? Oui.
- Est-ce que les roadmaps indiquent clairement que V1-27 n'est pas commence ? Oui.

Point critique : `unsupportedIntent` reste defensif et non testable directement avec les enums publics actuels sans fabriquer un faux modele. C'est documente et acceptable pour ce bis.

## 30. Verdict final sur V1-26

V1-26 est confirme.

`SceneRuntimeExecutor` est un executor pur de `SceneRuntimePlan`, limite au parcours par callbacks et ports explicites. Il ne branche pas encore le runtime map et ne cree aucune consequence persistante. Les preuves de fichiers, tests, analyze, roadmaps et diffs sont maintenant suffisamment completes pour fermer V1-26.

## 31. Limites restantes

- Le runtime map n'utilise pas encore `SceneRuntimeExecutor`.
- Event -> Scene runtime trigger reste non branche.
- Les callbacks reels dialogue/battle/cinematic/condition restent a definir dans un futur lot runtime.
- `unsupportedIntent` est defensif mais inatteignable avec le modele public actuel.
- Les consequences persistantes Facts/World Rules/StorySteps restent hors scope.

## 32. Prochain lot recommande

Prochain lot recommande :

```text
NS-SCENES-V1-27 — World Rules Map Editor Integration V0
```

Ne pas demarrer V1-27 dans V1-26-bis.
