# NS-SCENES-V1-28-quinquies — Scene Consequence Runtime Write V0

## 1. Resume du lot

Le lot ferme le premier write runtime controle des consequences Scene V1. Les consequences typées V0 (`setFact` et `markEventConsumed`) peuvent maintenant être compilees en intent runtime, stagees pendant l'execution d'une Scene V1, puis appliquees au `GameState` uniquement si toute la scene se termine avec succes.

Le commit logique est atomique au niveau du lot : si une consequence echoue ou si un callback plus tardif echoue, le `GameState` original est conserve. Aucune World Rule n'est appliquee directement, aucun StorylineStep n'est complete, aucun resultat battle n'est invente.

## 2. Pourquoi V1-28-quinquies existe

V1-28-quater a ajoute le modele authoring pur `SceneConsequence`, mais le runtime continuait de refuser ActionNode au runtime-plan. Le blocage suivant etait donc de transformer une consequence typée en intention executable, puis de fournir un write runtime explicite et borne.

## 3. Rappel du scope

Scope realise :

- compiler `SceneActionPayload.consequence` en intent `applyConsequence`;
- ajouter un callback executor `applyConsequence`;
- ajouter un writer runtime pour `setFact` et `markEventConsumed`;
- stager les consequences dans `SceneEventRuntimeHook`;
- commit seulement apres completion de la scene;
- passer le `GameState` courant depuis `PlayableMapGame`;
- exporter l'API runtime utile;
- tester no partial writes, refs inconnues, no World Rule direct apply et no StorylineStep completion.

Non-objectifs respectes :

- pas de World Rule direct apply;
- pas de StorylineStep link;
- pas de battle adapter;
- pas de dialogue awaitable adapter;
- pas de BranchByOutcome;
- pas de UI/editor;
- pas de donnees Selbrume;
- pas de modification `map_battle`, `map_gameplay` ou `examples`.

## 4. Gate 0 complet

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
a6b46779 feat(scenes): add scene consequence model v0
d35b3987 feat(scenes): add map event sceneTarget runtime hook v0
54acda44 feat(scenes): add golden slice selbrume readiness
c480c4f5 test(scenes): refine world rule empty state handling
ac3b389c feat(scenes): add world rules map editor integration v0
757f0ad5 docs(scenes): add V1-26-bis evidence hardening report
108b8c3c feat(scenes): add scene runtime executor MVP
c0d43712 feat(scenes): add dialogue and battle authoring ports
36494eaf feat(scenes): expand diagnostics and validator checks
061e9ebc feat(scenes): add scene runtime plan v0
```

`git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` etaient vides au Gate 0.

## 5. Changements preexistants vs changements du lot

Changements preexistants : aucun changement non commite detecte au Gate 0.

Changements du lot : tous les fichiers modifies ou crees dans ce rapport appartiennent a NS-SCENES-V1-28-quinquies.

## 6. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_24_scene_runtime_plan_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_diagnostics_validator_expansion.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_scene_runtime_executor_mvp.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_bis_scene_runtime_executor_evidence_review_hardening.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_27_world_rules_map_editor_integration_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_golden_slice_selbrume_scene_event_prep.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_bis_event_to_scene_runtime_hook_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_ter_scene_consequence_contract_prep.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_quater_scene_consequence_model_v0.md`
- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_executor.dart`
- `packages/map_core/lib/src/models/scene_consequence.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/models/narrative_fact.dart`
- `packages/map_core/lib/src/models/world_rule.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/operations/game_state_persistence.dart`
- `packages/map_core/lib/src/projection/world_rule_projection.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_hook_result.dart`
- `packages/map_runtime/lib/src/application/story_flags_manager.dart`
- `packages/map_runtime/lib/src/application/runtime_story_branching.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/application/script_command_executor.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_core/test/scene_consequence_model_test.dart`
- `packages/map_core/test/scene_runtime_plan_test.dart`
- `packages/map_core/test/scene_runtime_executor_test.dart`
- `packages/map_core/test/scene_diagnostics_test.dart`
- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`

## 7. Fichiers crees/modifies

Fichiers crees :

- `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart`
- `packages/map_runtime/test/scene_consequence_runtime_writer_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_quinquies_scene_consequence_runtime_write_v0.md`

Fichiers modifies :

- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_executor.dart`
- `packages/map_core/test/golden_slice_readiness_test.dart`
- `packages/map_core/test/scene_runtime_plan_test.dart`
- `packages/map_core/test/scene_runtime_executor_test.dart`
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_hook_result.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 8. Design retenu

Design retenu : `SceneRuntimePlan` porte une intention declarative `applyConsequence`. `SceneRuntimeExecutor` ne sait pas ecrire dans le `GameState`; il appelle seulement un callback explicite. Le hook runtime map stage les consequences dans une liste locale. Apres completion de la scene, le hook appelle un writer runtime dedie qui produit un nouveau `GameState`.

Ce design garde `map_core` pur et empeche les writes partiels : l'executor ne mute rien, le hook ne commit rien avant completion, le writer retourne le `GameState` original en cas d'echec.

## 9. RuntimePlan / Executor support consequence intent

`SceneRuntimePlanIntentKind.applyConsequence` a ete ajoute. Une `SceneActionPayload` avec `consequence != null` est compilee par `buildSceneRuntimePlan` en `SceneRuntimePlanIntent.applyConsequence`.

Les ActionNode legacy sans consequence typée restent refuses avec diagnostic `unsupportedAction`.

Section modifiee centrale :

```dart
factory SceneRuntimePlanIntent.applyConsequence({
  required SceneConsequence consequence,
}) {
  return SceneRuntimePlanIntent._(
    kind: SceneRuntimePlanIntentKind.applyConsequence,
    consequence: consequence,
  );
}
```

Executor :

```dart
typedef SceneRuntimeConsequenceCallback = FutureOr<String> Function(
  SceneConsequence consequence,
);
```

La sortie supportee est uniquement `completed`.

## 10. Staging / commit des consequences

`SceneEventRuntimeHook` stage :

```dart
final pendingConsequences = <SceneConsequence>[];
final executionResult = await SceneRuntimeExecutor(
  callbacks: callbacks.toExecutionCallbacks(
    applyConsequence: (consequence) {
      pendingConsequences.add(consequence);
      return 'completed';
    },
  ),
  maxSteps: maxSteps,
).execute(planResult.plan!);
```

Commit uniquement apres completion :

```dart
final writeResult = SceneConsequenceRuntimeWriter(
  project: project,
  mapsById: {map.id: map},
).applyAll(gameState, pendingConsequences);
```

Si `executionResult.status != completed`, la liste stagee est abandonnee.

## 11. Writer runtime setFact

`setFact` :

- verifie que `factId` existe dans `ProjectManifest.facts`;
- utilise `legacyFlagName` si present, sinon `fact.id`;
- ecrit via `GameStateMutations.setFlag` ou `clearFlag`;
- retourne une erreur `unknownFact` si la Fact manque.

## 12. Writer runtime markEventConsumed

`markEventConsumed` :

- verifie que `mapId` existe dans `ProjectManifest.maps`;
- verifie que `mapsById[mapId]` est disponible;
- verifie que `eventId` existe dans la map;
- utilise la convention existante `GameState.consumedEventIds` avec l'id brut de l'event;
- retourne `unknownMap` ou `unknownEvent` sinon.

## 13. Integration SceneEventRuntimeHook

Le hook :

- passe `mapsById: {map.id: map}` aux diagnostics projet;
- refuse diagnostics et runtime-plan invalides avant execution;
- stage les consequences via callback executor;
- exige un `GameState` si la scene produit des consequences;
- retourne `updatedGameState` seulement apres write reussi;
- retourne `sceneConsequenceWriteFailed` si le commit echoue.

## 14. Integration PlayableMapGame

`PlayableMapGame` transmet `_gameState` au hook et remplace `_gameState` par `result.updatedGameState` uniquement si le hook reussit.

```dart
gameState: _gameState,
```

```dart
} else if (result.updatedGameState != null) {
  _gameState = result.updatedGameState!;
}
```

## 15. Transaction / no partial writes

Le writer applique les consequences sur une variable locale `nextState`. Si une etape echoue, il retourne un result failed avec le `gameState` original et `appliedConsequences: const []`.

Le hook ne met jamais a jour le `GameState` de `PlayableMapGame` si l'execution de scene echoue ou si le write echoue.

## 16. Ce qui reste non couvert

- vrai resultat battle awaitable `victory` / `defeat`;
- outcomes Yarn detailles;
- BranchByOutcome runtime;
- completion de StorylineStep;
- application runtime des World Rules au monde visible;
- save disque automatique du nouveau `GameState`.

## 17. Pourquoi aucune World Rule n'est appliquee directement

Une Scene ecrit uniquement des faits ou de l'etat persistant simple. Les World Rules restent une projection du monde depuis ces sources. Le test `does not apply World Rules or complete StorySteps directly` couvre ce choix : ajouter une Fact ne complete pas d'etape et n'applique pas directement l'effet de World Rule.

## 18. Pourquoi aucun StorylineStep n'est complete

`StorylineStep.sceneLinkIds` reste reporte. Completer une step depuis ce lot melangerait consequence runtime, progression narrative et declenchement Scene. Aucune API de completion Step n'a ete appelee ou ajoutee.

## 19. Pourquoi aucun battle adapter n'a ete code

Le BattleNode expose deja `victory` / `defeat` dans le graph, mais V1-28-quinquies ne devait pas inventer un outcome. Le prochain lot recommande est dedie a ce verrou : `NS-SCENES-V1-28-sexies — Battle Runtime Outcome Adapter V0`.

## 20. Pourquoi aucune donnee Selbrume n'a ete creee

Les tests ajoutés utilisent des ids neutres : `fact_gate_open`, `map_test`, `event_gate`, `scene_test`. Aucun fichier `selbrume/**` n'a ete modifie.

## 21. Tests executes avec sorties exactes

Commande :

```bash
cd packages/map_core && dart test test/scene_consequence_model_test.dart
```

Sortie utile exacte :

```text
00:00 +8: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_plan_test.dart
```

Sortie utile exacte :

```text
00:00 +15: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_executor_test.dart
```

Sortie utile exacte :

```text
00:00 +20: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/scene_diagnostics_test.dart
```

Sortie utile exacte :

```text
00:00 +24: All tests passed!
```

Commande groupee de confirmation :

```bash
cd packages/map_core && NO_COLOR=1 dart test -r compact test/scene_consequence_model_test.dart test/scene_runtime_plan_test.dart test/scene_runtime_executor_test.dart test/scene_diagnostics_test.dart && NO_COLOR=1 dart analyze
```

Sortie finale exacte :

```text
00:00 +67: All tests passed!
Analyzing map_core...
No issues found!
```

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_consequence_runtime_writer_test.dart
```

Sortie utile exacte :

```text
00:02 +9: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_event_runtime_hook_test.dart
```

Sortie utile exacte :

```text
00:01 +15: All tests passed!
```

Commande groupee de confirmation :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_consequence_runtime_writer_test.dart test/scene_event_runtime_hook_test.dart && flutter analyze --no-fatal-infos lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart lib/src/application/scene_runtime/scene_event_runtime_hook.dart lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart lib/src/application/scene_runtime/scene_runtime_hook_result.dart lib/src/presentation/flame/playable_map_game.dart lib/map_runtime.dart test/scene_consequence_runtime_writer_test.dart test/scene_event_runtime_hook_test.dart
```

Sortie finale exacte :

```text
00:02 +24: All tests passed!
Analyzing 9 items...
No issues found! (ran in 1.6s)
```

Note : une premiere execution Flutter concurrente a echoue avec un verrou/native asset manquant pendant que deux tests Flutter tournaient en parallele. Les tests ont ete relances sequentiellement puis en groupe controle, et passent.

## 22. Analyze avec sortie exacte

Core :

```text
Analyzing map_core...
No issues found!
```

Runtime cible :

```text
Analyzing 9 items...
No issues found! (ran in 1.6s)
```

## 23. Recherche anti-Selbrume

Commande ciblee sur les fichiers du lot :

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_core/lib/src/runtime/scene_runtime_plan.dart packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart packages/map_core/lib/src/runtime/scene_runtime_executor.dart packages/map_core/test/golden_slice_readiness_test.dart packages/map_core/test/scene_runtime_plan_test.dart packages/map_core/test/scene_runtime_executor_test.dart packages/map_core/test/scene_diagnostics_test.dart packages/map_runtime/lib/map_runtime.dart packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_hook_result.dart packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/test/scene_consequence_runtime_writer_test.dart packages/map_runtime/test/scene_event_runtime_hook_test.dart || true
```

Sortie : <vide>

## 24. Recherche anti-scope

Commande :

```bash
rg -n "StorylineStep|sceneLinkIds|BranchByOutcome|giveItem|teleport|WorldRuleEffect|projectWorldRuleEffects|map_battle" packages/map_core/lib/src/runtime packages/map_runtime/lib/src/application/scene_runtime packages/map_runtime/test/scene_consequence_runtime_writer_test.dart packages/map_runtime/test/scene_event_runtime_hook_test.dart || true
```

Sortie exacte :

```text
packages/map_runtime/test/scene_consequence_runtime_writer_test.dart:226:              effect: const WorldRuleEffect(
packages/map_runtime/test/scene_consequence_runtime_writer_test.dart:227:                kind: WorldRuleEffectKind.eventHidden,
packages/map_runtime/test/scene_event_runtime_hook_test.dart:299:    test('does not apply World Rules or complete StorylineStep directly',
packages/map_runtime/test/scene_event_runtime_hook_test.dart:371:        expect(File(path).readAsStringSync(), isNot(contains('map_battle')));
packages/map_core/lib/src/runtime/scene_runtime_plan.dart:27:  unsupportedBranchByOutcome,
packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart:45:            code: SceneRuntimePlanDiagnosticCode.unsupportedBranchByOutcome,
packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart:47:            message: 'BranchByOutcome attend un mapping outcome -> edge futur.',
packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart:138:        'BranchByOutcome must be blocked before runtime intent creation.',
```

Interpretation : les occurrences sont soit des tests de non-application directe, soit le blocage existant de BranchByOutcome dans le runtime-plan. Aucune implementation `projectWorldRuleEffects`, `map_battle`, `giveItem`, `teleport` ou `sceneLinkIds` n'a ete ajoutee.

## 25. git diff --check

Commande finale :

```bash
git diff --check
```

Sortie : <vide>

## 26. git diff --stat

Sortie avant ajout de ce rapport :

```text
 .../lib/src/runtime/scene_runtime_executor.dart    |  41 ++++
 .../lib/src/runtime/scene_runtime_plan.dart        |  17 +-
 .../src/runtime/scene_runtime_plan_builder.dart    |  38 ++-
 .../map_core/test/golden_slice_readiness_test.dart |   1 +
 .../map_core/test/scene_runtime_executor_test.dart | 101 ++++++++
 .../map_core/test/scene_runtime_plan_test.dart     |  59 ++++-
 packages/map_runtime/lib/map_runtime.dart          |   7 +
 .../scene_runtime/scene_event_runtime_hook.dart    |  50 +++-
 .../scene_runtime/scene_runtime_hook_result.dart   |  13 +
 .../scene_runtime_host_callbacks.dart              |   5 +-
 .../src/presentation/flame/playable_map_game.dart  |   3 +
 .../test/scene_event_runtime_hook_test.dart        | 264 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  21 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  25 +-
 14 files changed, 610 insertions(+), 35 deletions(-)
```

Les fichiers non suivis du lot sont listes dans le statut final.

## 27. git diff --name-only

Sortie avant ajout de ce rapport :

```text
packages/map_core/lib/src/runtime/scene_runtime_executor.dart
packages/map_core/lib/src/runtime/scene_runtime_plan.dart
packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart
packages/map_core/test/golden_slice_readiness_test.dart
packages/map_core/test/scene_runtime_executor_test.dart
packages/map_core/test/scene_runtime_plan_test.dart
packages/map_runtime/lib/map_runtime.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_hook_result.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/test/scene_event_runtime_hook_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 28. git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale exacte :

```text
 M packages/map_core/lib/src/runtime/scene_runtime_executor.dart
 M packages/map_core/lib/src/runtime/scene_runtime_plan.dart
 M packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart
 M packages/map_core/test/golden_slice_readiness_test.dart
 M packages/map_core/test/scene_runtime_executor_test.dart
 M packages/map_core/test/scene_runtime_plan_test.dart
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_hook_result.dart
 M packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/scene_event_runtime_hook_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart
?? packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart
?? packages/map_runtime/test/scene_consequence_runtime_writer_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_28_quinquies_scene_consequence_runtime_write_v0.md
```

## 29. Evidence Pack

### Contenu complet des fichiers crees

`packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart`

```dart
import 'package:map_core/map_core.dart';

enum SceneConsequenceRuntimeWriteStatus {
  applied,
  failed,
}

enum SceneConsequenceRuntimeWriteErrorCode {
  unknownFact,
  unknownMap,
  unknownEvent,
}

final class SceneConsequenceRuntimeWriteResult {
  SceneConsequenceRuntimeWriteResult._({
    required this.status,
    required this.gameState,
    required List<SceneConsequence> appliedConsequences,
    this.errorCode,
    this.message,
    this.failedConsequence,
  }) : appliedConsequences =
            List<SceneConsequence>.unmodifiable(appliedConsequences);

  SceneConsequenceRuntimeWriteResult.applied({
    required GameState gameState,
    required List<SceneConsequence> appliedConsequences,
  }) : this._(
          status: SceneConsequenceRuntimeWriteStatus.applied,
          gameState: gameState,
          appliedConsequences: appliedConsequences,
        );

  SceneConsequenceRuntimeWriteResult.failed({
    required GameState gameState,
    required SceneConsequenceRuntimeWriteErrorCode errorCode,
    required String message,
    required SceneConsequence failedConsequence,
    required List<SceneConsequence> appliedConsequences,
  }) : this._(
          status: SceneConsequenceRuntimeWriteStatus.failed,
          gameState: gameState,
          errorCode: errorCode,
          message: message,
          failedConsequence: failedConsequence,
          appliedConsequences: appliedConsequences,
        );

  final SceneConsequenceRuntimeWriteStatus status;
  final GameState gameState;
  final List<SceneConsequence> appliedConsequences;
  final SceneConsequenceRuntimeWriteErrorCode? errorCode;
  final String? message;
  final SceneConsequence? failedConsequence;

  bool get success => status == SceneConsequenceRuntimeWriteStatus.applied;
}
```

`packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'scene_consequence_runtime_write_result.dart';

final class SceneConsequenceRuntimeWriter {
  const SceneConsequenceRuntimeWriter({
    required this.project,
    this.mapsById = const <String, MapData>{},
    this.mutations = const GameStateMutations(),
  });

  final ProjectManifest project;
  final Map<String, MapData> mapsById;
  final GameStateMutations mutations;

  SceneConsequenceRuntimeWriteResult applyAll(
    GameState gameState,
    List<SceneConsequence> consequences,
  ) {
    var nextState = gameState;
    final applied = <SceneConsequence>[];
    for (final consequence in consequences) {
      final step = _apply(nextState, consequence);
      if (step.errorCode != null) {
        return SceneConsequenceRuntimeWriteResult.failed(
          gameState: gameState,
          errorCode: step.errorCode!,
          message: step.message!,
          failedConsequence: consequence,
          appliedConsequences: const <SceneConsequence>[],
        );
      }
      nextState = step.gameState!;
      applied.add(consequence);
    }
    return SceneConsequenceRuntimeWriteResult.applied(
      gameState: nextState,
      appliedConsequences: applied,
    );
  }

  _SceneConsequenceRuntimeWriteStep _apply(
    GameState gameState,
    SceneConsequence consequence,
  ) {
    return switch (consequence.kind) {
      SceneConsequenceKind.setFact => _applySetFact(
          gameState,
          consequence as SceneSetFactConsequence,
        ),
      SceneConsequenceKind.markEventConsumed => _applyMarkEventConsumed(
          gameState,
          consequence as SceneMarkEventConsumedConsequence,
        ),
    };
  }

  _SceneConsequenceRuntimeWriteStep _applySetFact(
    GameState gameState,
    SceneSetFactConsequence consequence,
  ) {
    final fact = _findFact(consequence.factId);
    if (fact == null) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.unknownFact,
        'Scene consequence setFact references unknown Fact '
        '"${consequence.factId}".',
      );
    }
    final runtimeKey = fact.legacyFlagName ?? fact.id;
    final nextState = consequence.value
        ? mutations.setFlag(gameState, runtimeKey)
        : mutations.clearFlag(gameState, runtimeKey);
    return _SceneConsequenceRuntimeWriteStep.applied(nextState);
  }

  _SceneConsequenceRuntimeWriteStep _applyMarkEventConsumed(
    GameState gameState,
    SceneMarkEventConsumedConsequence consequence,
  ) {
    final projectHasMap =
        project.maps.any((map) => map.id == consequence.mapId);
    final mapData = mapsById[consequence.mapId];
    if (!projectHasMap || mapData == null) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.unknownMap,
        'Scene consequence markEventConsumed references unknown map '
        '"${consequence.mapId}".',
      );
    }
    final hasEvent =
        mapData.events.any((event) => event.id == consequence.eventId);
    if (!hasEvent) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.unknownEvent,
        'Scene consequence markEventConsumed references unknown event '
        '"${consequence.eventId}" on map "${consequence.mapId}".',
      );
    }
    return _SceneConsequenceRuntimeWriteStep.applied(
      mutations.markEventConsumed(gameState, consequence.eventId),
    );
  }

  NarrativeFactDefinition? _findFact(String factId) {
    for (final fact in project.facts) {
      if (fact.id == factId) {
        return fact;
      }
    }
    return null;
  }
}

final class _SceneConsequenceRuntimeWriteStep {
  const _SceneConsequenceRuntimeWriteStep._({
    this.gameState,
    this.errorCode,
    this.message,
  });

  const _SceneConsequenceRuntimeWriteStep.applied(GameState gameState)
      : this._(gameState: gameState);

  const _SceneConsequenceRuntimeWriteStep.failed(
    SceneConsequenceRuntimeWriteErrorCode errorCode,
    String message,
  ) : this._(
          errorCode: errorCode,
          message: message,
        );

  final GameState? gameState;
  final SceneConsequenceRuntimeWriteErrorCode? errorCode;
  final String? message;
}
```

`packages/map_runtime/test/scene_consequence_runtime_writer_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('SceneConsequenceRuntimeWriter', () {
    test('setFact true activates Fact runtime key', () {
      const state = GameState(saveId: 'save_test');
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(
              id: 'fact_gate_open',
              label: 'Gate open',
            ),
          ],
        ),
      );

      final result = writer.applyAll(
        state,
        [
          SceneConsequence.setFact(factId: 'fact_gate_open', value: true),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(
          result.gameState.storyFlags.activeFlags, contains('fact_gate_open'));
      expect(state.storyFlags.activeFlags, isEmpty);
    });

    test('setFact false clears Fact runtime key', () {
      const state = GameState(
        saveId: 'save_test',
        storyFlags: StoryFlags(activeFlags: {'fact_gate_open'}),
      );
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(
              id: 'fact_gate_open',
              label: 'Gate open',
            ),
          ],
        ),
      );

      final result = writer.applyAll(
        state,
        [
          SceneConsequence.setFact(factId: 'fact_gate_open', value: false),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(
        result.gameState.storyFlags.activeFlags,
        isNot(contains('fact_gate_open')),
      );
      expect(state.storyFlags.activeFlags, contains('fact_gate_open'));
    });

    test('setFact uses legacyFlagName when present', () {
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(
              id: 'fact_gate_open',
              label: 'Gate open',
              legacyFlagName: 'legacy_gate_flag',
            ),
          ],
        ),
      );

      final result = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [
          SceneConsequence.setFact(factId: 'fact_gate_open', value: true),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(
        result.gameState.storyFlags.activeFlags,
        contains('legacy_gate_flag'),
      );
      expect(
        result.gameState.storyFlags.activeFlags,
        isNot(contains('fact_gate_open')),
      );
    });

    test('setFact unknown Fact fails without mutating the original state', () {
      const state = GameState(saveId: 'save_test');
      final writer = SceneConsequenceRuntimeWriter(project: _project());

      final result = writer.applyAll(
        state,
        [
          SceneConsequence.setFact(factId: 'fact_missing', value: true),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(
        result.errorCode,
        SceneConsequenceRuntimeWriteErrorCode.unknownFact,
      );
      expect(result.gameState, state);
      expect(state.storyFlags.activeFlags, isEmpty);
    });

    test('markEventConsumed adds consumed event id using existing convention',
        () {
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          maps: const [
            ProjectMapEntry(
              id: 'map_test',
              name: 'Map Test',
              relativePath: 'maps/map_test.json',
            ),
          ],
        ),
        mapsById: {
          'map_test': _map(events: [_event('event_gate')]),
        },
      );

      final result = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [
          SceneConsequence.markEventConsumed(
            mapId: 'map_test',
            eventId: 'event_gate',
          ),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(result.gameState.consumedEventIds, contains('event_gate'));
      expect(
        result.gameState.consumedEventIds,
        isNot(contains('map_test:event_gate')),
      );
    });

    test('markEventConsumed unknown map fails clearly', () {
      final writer = SceneConsequenceRuntimeWriter(project: _project());

      final result = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [
          SceneConsequence.markEventConsumed(
            mapId: 'map_missing',
            eventId: 'event_gate',
          ),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(
        result.errorCode,
        SceneConsequenceRuntimeWriteErrorCode.unknownMap,
      );
    });

    test('markEventConsumed unknown event fails clearly', () {
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          maps: const [
            ProjectMapEntry(
              id: 'map_test',
              name: 'Map Test',
              relativePath: 'maps/map_test.json',
            ),
          ],
        ),
        mapsById: {
          'map_test': _map(events: [_event('event_other')]),
        },
      );

      final result = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [
          SceneConsequence.markEventConsumed(
            mapId: 'map_test',
            eventId: 'event_gate',
          ),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.failed);
      expect(
        result.errorCode,
        SceneConsequenceRuntimeWriteErrorCode.unknownEvent,
      );
    });

    test('does not apply World Rules or complete StorySteps directly', () {
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(
              id: 'fact_gate_open',
              label: 'Gate open',
            ),
          ],
          worldRules: [
            WorldRuleDefinition(
              id: 'world_rule_gate',
              label: 'Gate world rule',
              source: const WorldRuleSource(
                kind: WorldRuleSourceKind.fact,
                sourceId: 'fact_gate_open',
                predicate: WorldRuleSourcePredicate.isTrue,
              ),
              target: const WorldRuleTarget(
                kind: WorldRuleTargetKind.mapEvent,
                mapId: 'map_test',
                eventId: 'event_gate',
              ),
              effect: const WorldRuleEffect(
                kind: WorldRuleEffectKind.eventHidden,
              ),
            ),
          ],
        ),
      );
      const state = GameState(
        saveId: 'save_test',
        progression: PlayerProgression(completedStepIds: ['already_done']),
      );

      final result = writer.applyAll(
        state,
        [
          SceneConsequence.setFact(factId: 'fact_gate_open', value: true),
        ],
      );

      expect(result.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(result.gameState.progression.completedStepIds, ['already_done']);
      expect(
          result.gameState.storyFlags.activeFlags, contains('fact_gate_open'));
    });

    test('is deterministic and idempotent for repeated same consequence', () {
      final writer = SceneConsequenceRuntimeWriter(
        project: _project(
          facts: [
            NarrativeFactDefinition(
              id: 'fact_gate_open',
              label: 'Gate open',
            ),
          ],
        ),
      );
      final consequence =
          SceneConsequence.setFact(factId: 'fact_gate_open', value: true);

      final first = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [consequence, consequence],
      );
      final second = writer.applyAll(
        const GameState(saveId: 'save_test'),
        [consequence, consequence],
      );

      expect(first.status, SceneConsequenceRuntimeWriteStatus.applied);
      expect(first.gameState, second.gameState);
      expect(first.gameState.storyFlags.activeFlags, hasLength(1));
      expect(
        first.gameState.storyFlags.activeFlags,
        contains('fact_gate_open'),
      );
    });
  });
}

ProjectManifest _project({
  List<ProjectMapEntry> maps = const [],
  List<NarrativeFactDefinition> facts = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'Scene consequence runtime writer test',
    maps: maps,
    tilesets: const [],
    facts: facts,
    worldRules: worldRules,
  );
}

MapData _map({List<MapEventDefinition> events = const []}) {
  return MapData(
    id: 'map_test',
    name: 'Map Test',
    size: const GridSize(width: 4, height: 4),
    events: events,
  );
}

MapEventDefinition _event(String id) {
  return MapEventDefinition(
    id: id,
    position: const EventPosition(layerId: 'l_base', x: 1, y: 1),
    pages: const [MapEventPage(pageNumber: 0)],
  );
}
```

### Sections completes modifiees

`SceneRuntimeExecutionCallbacks` contient maintenant `applyConsequence`, et `SceneRuntimeExecutor` traite `SceneRuntimePlanIntentKind.applyConsequence` avec sortie `completed` uniquement.

`SceneRuntimeHostCallbacks.toExecutionCallbacks` exige le callback consequence au moment du hook, afin que le host runtime ne puisse pas oublier le seam.

`SceneEventRuntimeHookResult` expose `updatedGameState` et `consequenceWriteResult`.

`PlayableMapGame` applique le `updatedGameState` uniquement en retour de hook reussi.

### Diff fonctionnel principal

```diff
+typedef SceneRuntimeConsequenceCallback = FutureOr<String> Function(
+  SceneConsequence consequence,
+);
+
 final class SceneRuntimeExecutionCallbacks {
   const SceneRuntimeExecutionCallbacks({
     required this.evaluateCondition,
     required this.showDialogue,
     required this.startBattle,
     required this.playCinematic,
+    required this.applyConsequence,
   });
```

```diff
+      case SceneRuntimePlanIntentKind.applyConsequence:
+        return _consequenceCallbackOutput(intent);
```

```diff
+    final pendingConsequences = <SceneConsequence>[];
     final executionResult = await SceneRuntimeExecutor(
-      callbacks: callbacks.toExecutionCallbacks(),
+      callbacks: callbacks.toExecutionCallbacks(
+        applyConsequence: (consequence) {
+          pendingConsequences.add(consequence);
+          return 'completed';
+        },
+      ),
       maxSteps: maxSteps,
     ).execute(planResult.plan!);
```

```diff
+      final writeResult = SceneConsequenceRuntimeWriter(
+        project: project,
+        mapsById: {map.id: map},
+      ).applyAll(gameState, pendingConsequences);
```

### Diff roadmaps

`road_map_scenes.md` marque V1-28-quinquies DONE, ajoute V1-28-sexies TODO et recommande `NS-SCENES-V1-28-sexies — Battle Runtime Outcome Adapter V0`.

`road_map_scene_builder_authoring.md` marque V1-28-quinquies DONE, ajoute V1-28-sexies et deplace la dependance StorylineStep apres le futur battle outcome adapter.

## 30. Auto-review critique

Points solides :

- le write est explicite et borne;
- le core reste pur;
- le hook commit seulement apres completion;
- les erreurs de refs Fact/map/event sont testees;
- les tests prouvent l'absence de World Rule direct apply et de StorylineStep completion;
- aucun resultat battle n'est invente.

Points a surveiller :

- `markEventConsumed` suit la convention existante d'id event brut; si le runtime veut un jour distinguer deux events de meme id sur deux maps, il faudra migrer la convention;
- le `GameState` mis a jour n'est pas encore persiste disque automatiquement;
- l'outcome battle reste le prochain verrou pour le golden slice jouable.

## 31. Limites restantes

- pas de save automatique;
- pas de World Rule runtime apply;
- pas de StorylineStep completion;
- pas de Battle runtime outcome adapter;
- pas de BranchByOutcome;
- pas de Yarn outcomes detailles.

## 32. Prochain lot recommande

`NS-SCENES-V1-28-sexies — Battle Runtime Outcome Adapter V0`

Justification : la Scene peut maintenant ecrire ses consequences V0 de facon controlee. Pour que le golden slice progresse proprement, le BattleNode doit maintenant recevoir un vrai resultat `victory` / `defeat` depuis le runtime battle, sans outcome invente.
