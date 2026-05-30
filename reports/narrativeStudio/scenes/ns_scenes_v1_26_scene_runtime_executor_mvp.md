# NS-SCENES-V1-26 — Scene Runtime Executor MVP

## 1. Resume du lot

`NS-SCENES-V1-26` ajoute un executor pur cote `map_core` capable de parcourir un `SceneRuntimePlan` deja valide via callbacks injectes. Le lot ne branche pas encore le runtime map : il prouve seulement que le plan peut etre execute de maniere controlee, testable et sans dependance Flutter/Flame/runtime.

Livraison :

- `SceneRuntimeExecutor`
- `SceneRuntimeExecutionCallbacks`
- `SceneRuntimeExecutionResult`
- `SceneRuntimeExecutionStatus`
- `SceneRuntimeExecutionTraceEntry`
- `SceneRuntimeExecutionErrorCode`

## 2. Rappel du scope

Scope realise :

- execution `start -> end` ;
- execution `dialogue.completed` ;
- execution `battle.victory` et `battle.defeat` ;
- execution `condition.true` et `condition.false` ;
- execution `merge.completed` ;
- execution `cinematic.completed` via callback ;
- trace deterministe ;
- erreurs runtime propres ;
- protection `maxSteps` ;
- export public `map_core.dart` ;
- tests core dedies ;
- roadmaps mises a jour.

Non-objectifs respectes :

- pas de branchement `PlayableMapGame` ;
- pas de trigger runtime depuis `MapEventPage.sceneTarget` ;
- pas de modification `ScenarioRuntimeExecutor` ;
- pas de promotion `ScenarioAsset` ;
- pas de `StorylineStep.sceneLinkIds` ;
- pas de `map_battle` ;
- pas de Yarn parser ;
- pas de battle engine reel ;
- pas de cinematic player reel ;
- pas de mutation `GameState`, `ProjectManifest` ou `MapData` ;
- pas de Fact write, World Rule projection runtime ou consequence persistante ;
- pas de donnees Selbrume.

## 3. Gate 0 complet

Commande :

```bash
printf 'pwd:\n'; pwd; printf '\nbranch:\n'; git branch --show-current; printf '\nstatus:\n'; git status --short --untracked-files=all; printf '\ndiff stat:\n'; git diff --stat; printf '\ndiff name-only:\n'; git diff --name-only; printf '\nlog:\n'; git log --oneline -n 10
```

Sortie exacte :

```text
pwd:
/Users/karim/Project/pokemonProject

branch:
main

status:

diff stat:

diff name-only:

log:
c0d43712 feat(scenes): add dialogue and battle authoring ports
36494eaf feat(scenes): expand diagnostics and validator checks
061e9ebc feat(scenes): add scene runtime plan v0
540d5377 feat(scenes): add event page scene link V0
a2e14b19 docs(scenes): add V1-23 architecture decision and roadmap updates
9e85a187 feat(scenes): add payload pickers for linked assets,workdir:/Users/karim/Project/pokemonProject
e3325807 feat(scenes): add linked asset contracts and scene V0 node deletion
d170d0da docs(scenes): add linked-asset contracts audit and update roadmaps
48f3d520 docs(scenes): add checkpoint narrative studio direction and update roadmaps
c9a3d6e2 docs(scenes): add roadmap checkpoint correction and roadmap updates
```

## 4. Changements preexistants vs changements du lot

Gate 0 etait propre : aucun changement preexistant dans `status`, `diff stat` ou `diff name-only`.

Tous les changements listes dans le status final appartiennent a `NS-SCENES-V1-26`.

## 5. Fichiers crees/modifies

Fichiers crees :

- `packages/map_core/lib/src/runtime/scene_runtime_executor.dart`
- `packages/map_core/test/scene_runtime_executor_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_scene_runtime_executor_mvp.md`

Fichiers modifies :

- `packages/map_core/lib/map_core.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 6. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_diagnostics_validator_expansion.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_24_scene_runtime_plan_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_23_bis_event_to_scene_link_v0.md`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart`
- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/scene_runtime_plan_test.dart`
- `packages/map_core/test/scene_authoring_operations_test.dart`
- `packages/map_core/test/scene_diagnostics_test.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Tous les chemins obligatoires existaient.

## 7. Design retenu

Le design reste `core-first` :

- `SceneRuntimePlan` est l'entree unique ;
- `SceneRuntimeExecutor` ne lit ni projet, ni disque, ni layout ;
- les effets concrets sont representes par callbacks ;
- les callbacks retournent seulement un `fromPortId` logique ;
- l'executor resout ensuite l'edge exacte `fromNodeId + fromPortId`.

Le design ne tente pas de resoudre les cycles ou de valider tout le graph : V1-25 garde le role diagnostic, V1-26 ajoute seulement une protection `maxSteps`.

## 8. Placement choisi : map_core ou map_runtime

Placement choisi : `map_core`.

Justification :

- l'executor est pur Dart ;
- il depend uniquement de `SceneRuntimePlan` ;
- il est testable sans Flutter, Flame, `PlayableMapGame`, `ScenarioRuntimeExecutor`, Yarn ou `map_battle` ;
- il prepare le futur branchement runtime sans le faire.

`map_runtime` a ete lu pour audit seulement. Aucun fichier `map_runtime/**` n'a ete modifie.

## 9. API SceneRuntimeExecutor

API publique ajoutee :

```dart
final class SceneRuntimeExecutor {
  SceneRuntimeExecutor({
    required SceneRuntimeExecutionCallbacks callbacks,
    int maxSteps = 100,
  });

  Future<SceneRuntimeExecutionResult> execute(SceneRuntimePlan plan);
}
```

`maxSteps < 1` est refuse par `ArgumentError`.

## 10. Callbacks

API publique ajoutee :

```dart
typedef SceneRuntimeIntentCallback = FutureOr<String> Function(
  SceneRuntimePlanIntent intent,
);

final class SceneRuntimeExecutionCallbacks {
  const SceneRuntimeExecutionCallbacks({
    required this.evaluateCondition,
    required this.showDialogue,
    required this.startBattle,
    required this.playCinematic,
  });
}
```

Les callbacks peuvent etre sync ou async.

## 11. Intents supportes

Support V0 :

- `start` : suit `completed` sans callback ;
- `merge` : suit `completed` sans callback ;
- `end` : termine avec `completed` ;
- `evaluateCondition` : callback, ports `true` / `false` ;
- `showDialogue` : callback, port `completed` ;
- `startBattle` : callback, ports `victory` / `defeat` ;
- `playCinematic` : callback, port `completed`.

## 12. Transitions / edges

Resolution :

```text
currentNodeId + outputPortId -> edge.fromNodeId + edge.fromPortId
```

Regles runtime :

- zero edge : `missingTransition` ;
- plusieurs edges : `ambiguousTransition` ;
- cible absente : `targetNodeMissing` ;
- aucun edge implicite ;
- aucune correction automatique.

## 13. Trace et resultat

Trace minimale :

```dart
final class SceneRuntimeExecutionTraceEntry {
  final String nodeId;
  final SceneRuntimePlanIntentKind intentKind;
  final String? outputPortId;
}
```

Resultat minimal :

```dart
final class SceneRuntimeExecutionResult {
  final SceneRuntimeExecutionStatus status;
  final String sceneId;
  final String? finalNodeId;
  final String? sceneOutcomeId;
  final SceneRuntimeExecutionErrorCode? errorCode;
  final String? message;
  final List<SceneRuntimeExecutionTraceEntry> trace;
}
```

## 14. Gestion des erreurs

Codes V0 :

- `missingStartNode`
- `missingTransition`
- `ambiguousTransition`
- `targetNodeMissing`
- `unsupportedIntent`
- `unsupportedPortResult`
- `callbackFailed`
- `stepLimitExceeded`

Les exceptions callback sont converties en resultat `failed` avec `callbackFailed`.

Note : `unsupportedIntent` est expose pour compatibilite defensive future. Les intents actuels de `SceneRuntimePlanIntentKind` sont tous couverts par l'executor.

## 15. Protection cycles / maxSteps

Par defaut :

```text
maxSteps = 100
```

Si la limite est atteinte :

```text
status = failed
errorCode = stepLimitExceeded
```

L'executor ne fait pas d'analyse de graph ; il protege seulement contre une boucle runtime infinie.

## 16. Pourquoi aucun runtime map n'a ete branche

Le lot doit prouver l'execution d'un `SceneRuntimePlan`, pas relier `MapEventPage.sceneTarget` a `PlayableMapGame`. Aucun code Flutter, Flame ou runtime map n'est ajoute.

## 17. Pourquoi aucun ScenarioAsset n'a ete promu

`ScenarioAsset` reste legacy/bridge. L'executor consomme uniquement `SceneRuntimePlan`, qui vient du modele `SceneAsset` V1.

## 18. Pourquoi aucune consequence persistante n'a ete appliquee

Les callbacks retournent seulement un port de sortie. L'executor ne modifie pas `GameState`, ne set aucun Fact, ne complete aucun Step, ne donne aucun item et ne projette aucune World Rule.

## 19. Pourquoi aucune donnee Selbrume n'a ete creee

Les tests utilisent uniquement des IDs generiques autorises :

```text
scene_test
node_start
node_dialogue
node_battle
node_condition
node_merge
node_cinematic
node_end
node_end_victory
node_end_defeat
dialogue_test
trainer_test
cinematic_test
```

Aucune donnee Mael, Lysa, Selbrume, Port des Brisants ou rival n'est creee.

## 20. Tests executes avec sorties exactes

### RED TDD

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_executor_test.dart
```

Sortie RED attendue :

```text
Failed to load "test/scene_runtime_executor_test.dart":
test/scene_runtime_executor_test.dart:302:1: Error: Type 'SceneRuntimeExecutionCallbacks' not found.
SceneRuntimeExecutionCallbacks _callbacks({
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/scene_runtime_executor_test.dart:14:28: Error: Method not found: 'SceneRuntimeExecutor'.
      final result = await SceneRuntimeExecutor(
                           ^^^^^^^^^^^^^^^^^^^^
test/scene_runtime_executor_test.dart:18:29: Error: Undefined name 'SceneRuntimeExecutionStatus'.
      expect(result.status, SceneRuntimeExecutionStatus.completed);
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^
Some tests failed.
```

### scene_runtime_executor_test.dart

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_executor_test.dart
```

Sortie :

```text
00:00 +0: loading test/scene_runtime_executor_test.dart
00:00 +18: All tests passed!
```

### scene_runtime_plan_test.dart

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_plan_test.dart
```

Sortie :

```text
00:00 +0: loading test/scene_runtime_plan_test.dart
00:00 +13: All tests passed!
```

## 21. Analyze avec sortie exacte

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

## 22. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

## 23. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart                |  1 +
 .../scenes/road_map_scene_builder_authoring.md     | 20 ++++++++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md  | 22 ++++++++++++++++++----
 3 files changed, 37 insertions(+), 6 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis. Ils sont visibles dans le `git status final`.

## 24. git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_core/lib/map_core.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Note : `git diff --name-only` ne liste pas les fichiers non suivis. Ils sont visibles dans le `git status final`.

## 25. git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/runtime/scene_runtime_executor.dart
?? packages/map_core/test/scene_runtime_executor_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_26_scene_runtime_executor_mvp.md
```

## 26. Evidence Pack

### Fichiers crees

`packages/map_core/lib/src/runtime/scene_runtime_executor.dart`

```text
Contenu : modele public d'executor, callbacks, resultat, trace, codes d'erreurs, traversal et helpers prives.
Lignes : 314.
```

Hunks critiques :

```dart
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
```

```dart
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
    // traversal pur de SceneRuntimePlan
  }
}
```

`packages/map_core/test/scene_runtime_executor_test.dart`

```text
Contenu : tests TDD de l'executor Scene V1.
Lignes : 584.
```

Cas couverts :

```text
executes start -> end
exposes final scene outcome id
executes a plan built from a SceneAsset without ProjectManifest
executes start -> dialogue.completed -> end
executes battle victory branch
executes battle defeat branch
executes condition true branch
executes condition false branch
executes merge as passthrough
executes cinematic completed via callback
records deterministic trace
fails missingStartNode
fails missingTransition
fails unsupportedPortResult
fails ambiguousTransition
fails targetNodeMissing
fails callbackFailed
fails stepLimitExceeded
does not mutate SceneRuntimePlan
```

`reports/narrativeStudio/scenes/ns_scenes_v1_26_scene_runtime_executor_mvp.md`

```text
Contenu : present rapport.
```

### Fichiers modifies

`packages/map_core/lib/map_core.dart`

```diff
 export 'src/runtime/scene_runtime_plan.dart';
 export 'src/runtime/scene_runtime_plan_builder.dart';
+export 'src/runtime/scene_runtime_executor.dart';
 export 'src/projection/world_rule_projection.dart';
```

Roadmaps :

```text
V1-26 marque DONE.
Prochain lot recommande : NS-SCENES-V1-27 — World Rules Map Editor Integration V0.
```

### Diff equivalent /dev/null des nouveaux fichiers

Nouveaux fichiers :

```text
packages/map_core/lib/src/runtime/scene_runtime_executor.dart
packages/map_core/test/scene_runtime_executor_test.dart
reports/narrativeStudio/scenes/ns_scenes_v1_26_scene_runtime_executor_mvp.md
```

Les hunks critiques et les tests couverts sont reproduits ci-dessus.

## 27. Auto-review critique

- Est-ce que j'ai modifie `PlayableMapGame` ? Non.
- Est-ce que j'ai branche Event -> Scene runtime ? Non.
- Est-ce que j'ai modifie `ScenarioRuntimeExecutor` ? Non.
- Est-ce que j'ai promu `ScenarioAsset` ? Non.
- Est-ce que j'ai branche `StorylineStep.sceneLinkIds` ? Non.
- Est-ce que j'ai importe `map_battle` ? Non.
- Est-ce que j'ai importe `map_runtime` dans `map_core` ? Non.
- Est-ce que j'ai lu le disque depuis l'executor ? Non.
- Est-ce que j'ai parse Yarn ? Non.
- Est-ce que j'ai modifie `GameState` ? Non.
- Est-ce que j'ai applique des Facts/World Rules/consequences ? Non.
- Est-ce que j'ai invente des outcomes Yarn ? Non.
- Est-ce que j'ai cree des donnees Selbrume ? Non.
- Est-ce que l'executor suit uniquement les ports retournes par callbacks ? Oui.
- Est-ce que les erreurs sont retournees proprement ? Oui.
- Est-ce que `maxSteps` protege des cycles ? Oui.
- Est-ce que le prochain lot reste bien V1-27 et n'a pas ete demarre ? Oui.

Critique : `unsupportedIntent` est expose comme code defensif mais n'est pas atteignable avec les intents publics actuels, car `SceneRuntimePlanIntentKind` ne contient que des kinds supportes. C'est documente et preferable a l'ajout artificiel d'un intent fake.

## 28. Limites et prochain lot recommande

Limites :

- executor non branche a `PlayableMapGame` ;
- aucun trigger Event -> Scene runtime ;
- aucun effet persistant ;
- aucun parser Yarn ;
- aucun battle runtime ;
- aucune application Fact/World Rule.

Prochain lot recommande :

```text
NS-SCENES-V1-27 — World Rules Map Editor Integration V0
```

V1-27 n'est pas demarre.
