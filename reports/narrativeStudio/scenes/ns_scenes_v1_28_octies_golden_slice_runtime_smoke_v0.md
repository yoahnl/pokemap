# NS-SCENES-V1-28-octies — Golden Slice Runtime Smoke V0

## 1. Résumé du lot

V1-28-octies ajoute un smoke test runtime contrôlé qui prouve la chaîne complète :

```text
MapEventPage.sceneTarget
-> SceneEventRuntimeHook
-> SceneRuntimeExecutor
-> SceneDialogueRuntimeAwaitableAdapter
-> SceneBattleRuntimeOutcomeAdapter
-> SceneConsequenceRuntimeWriter
-> GameState updated
```

Le lot ne modifie aucun code de production. Il ajoute uniquement un test smoke runtime neutre, met à jour les roadmaps, et documente la preuve.

## 2. Pourquoi V1-28-octies existe

Les lots précédents avaient livré séparément le hook Event -> Scene, le staging/commit des conséquences, l'adapter battle awaitable et l'adapter dialogue awaitable. Il restait à prouver que ces briques fonctionnent ensemble dans une chaîne runtime cohérente avant de brancher `StorylineStep.sceneLinkIds`.

## 3. Rappel du scope

Réalisé :

- smoke applicatif hors Flame ;
- fixture neutre en mémoire ;
- dialogue awaitable réellement pending avant completion ;
- battle awaitable victory/defeat via adapter réel ;
- conséquences `setFact` et `markEventConsumed` stagees puis commit après fin ;
- branche defeat distincte ;
- échec contrôlé sans write partiel ;
- roadmaps mises à jour.

Non réalisé :

- pas de `StorylineStep.sceneLinkIds` ;
- pas de StorylineStep comme trigger runtime ;
- pas de World Rule direct apply ;
- pas de BranchByOutcome ;
- pas d'outcome Yarn inventé ;
- pas de modification `map_core/lib/src` ;
- pas de modification `map_editor` ;
- pas de modification `map_battle` ;
- pas de modification `map_gameplay` ;
- pas de modification `examples` ;
- pas de seed produit.

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
44de8cc2 feat(scenes): add dialogue runtime awaitable adapter v0
20e51eca feat(scenes): add battle runtime outcome adapter v0
326e939c feat(scenes): add scene consequence runtime write v0
a6b46779 feat(scenes): add scene consequence model v0
d35b3987 feat(scenes): add map event sceneTarget runtime hook v0
54acda44 feat(scenes): add golden slice selbrume readiness
c480c4f5 test(scenes): refine world rule empty state handling
ac3b389c feat(scenes): add world rules map editor integration v0
757f0ad5 docs(scenes): add V1-26-bis evidence hardening report
108b8c3c feat(scenes): add scene runtime executor MVP
```

## 5. Changements préexistants vs changements du lot

Changements préexistants : aucun changement non commit au Gate 0.

Changements introduits par V1-28-octies :

- création de `packages/map_runtime/test/scene_runtime_golden_slice_smoke_test.dart` ;
- création du présent rapport ;
- mise à jour de `reports/narrativeStudio/scenes/road_map_scenes.md` ;
- mise à jour de `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`.

## 6. Fichiers lus

Instructions et prompt :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `superpowers:test-driven-development`
- `superpowers:verification-before-completion`
- `karpathy-guidelines`
- prompt joint `NS-SCENES-V1-28-octies — Golden Slice Runtime Smoke V0`

Roadmaps et rapports :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- rapport V1-28-septies Dialogue Runtime Awaitable Adapter V0
- rapport V1-28-sexies Battle Runtime Outcome Adapter V0
- rapport V1-28-quinquies Scene Consequence Runtime Write V0
- rapport V1-28-quater Scene Consequence Model V0
- rapport V1-28-ter Scene Consequence Contract Prep
- rapport V1-28-bis Event to Scene Runtime Hook V0
- rapport V1-28 Golden Slice Scene/Event Prep
- rapport V1-27 World Rules Map Editor Integration V0
- rapport V1-26 Scene Runtime Executor MVP
- rapport V1-25-bis Dialogue/Battle Ports Authoring V0

Core :

- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/scene_consequence.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_trainer.dart`
- `packages/map_core/lib/src/models/narrative_fact.dart`
- `packages/map_core/lib/src/models/world_rule.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_executor.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/map_core.dart`

Runtime :

- `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_hook_result.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_write_result.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_result.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_result.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/map_runtime.dart`

Tests :

- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`
- `packages/map_runtime/test/scene_battle_runtime_outcome_adapter_test.dart`
- `packages/map_runtime/test/scene_dialogue_runtime_awaitable_adapter_test.dart`
- `packages/map_runtime/test/scene_consequence_runtime_writer_test.dart`
- `packages/map_core/test/scene_runtime_plan_test.dart`
- `packages/map_core/test/scene_runtime_executor_test.dart`
- `packages/map_core/test/scene_consequence_model_test.dart`

## 7. Fichiers créés/modifiés

Fichiers créés :

- `packages/map_runtime/test/scene_runtime_golden_slice_smoke_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_octies_golden_slice_runtime_smoke_v0.md`

Fichiers modifiés :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 8. Design du smoke

Niveau choisi : option A, smoke applicatif hors Flame.

Justification :

- `SceneEventRuntimeHook` est la vraie brique runtime Event -> Scene ;
- `SceneRuntimeExecutor` est réel ;
- les adapters dialogue et battle sont réels ;
- les launchers sont fake uniquement pour contrôler les délais et résultats ;
- `SceneConsequenceRuntimeWriter` est appelé par le hook, pas directement par le test ;
- le test reste déterministe, rapide et non fragile vis-à-vis des overlays Flame.

## 9. Fixture neutre

IDs utilisés :

```text
map_test_runtime
event_test_scene
scene_test_runtime
dialogue_test_intro
trainer_test_guard
fact_test_scene_victory
fact_test_scene_defeat
fact_test_event_consumed
node_start
node_dialogue
node_battle
node_action_victory_fact
node_action_victory_consumed
node_action_defeat_fact
node_end_victory
node_end_defeat
```

La fixture contient :

- `ProjectManifest.dialogues` avec `dialogue_test_intro` ;
- `ProjectManifest.trainers` avec `trainer_test_guard` ;
- `ProjectManifest.facts` avec victory, defeat et consumed ;
- `ProjectManifest.scenes` avec `scene_test_runtime` ;
- `ProjectManifest.maps` avec `map_test_runtime` ;
- `MapData.events` avec `event_test_scene` et `page.sceneTarget = scene_test_runtime`.

## 10. Chaîne runtime prouvée

Le test principal prouve :

- `MapEventPage.sceneTarget` existe ;
- `SceneEventRuntimeHook` traite la page ;
- `SceneRuntimeExecutor` exécute le plan ;
- `SceneDialogueRuntimeAwaitableAdapter` est utilisé ;
- `SceneBattleRuntimeOutcomeAdapter` est utilisé ;
- `SceneConsequenceRuntimeWriter` commit les conséquences via le hook ;
- `GameState` original reste inchangé ;
- `updatedGameState` porte uniquement les writes attendus.

## 11. Dialogue awaitable prouvé

Le test victory utilise un `Completer<SceneDialogueRuntimeAwaitableResult>`.

Avant completion :

- le hook n'est pas terminé ;
- le battle n'a pas démarré ;
- aucun write n'est visible sur le `GameState` original.

Après completion :

- la Scene continue ;
- le battle démarre ;
- la branche victory est suivie.

## 12. Battle awaitable prouvé

Le battle passe par `SceneBattleRuntimeOutcomeAdapter`.

Cas couverts :

- launcher fake retourne `victory` -> port Scene `victory` ;
- launcher fake retourne `defeat` -> port Scene `defeat` ;
- launcher fake retourne failed -> callback Scene échoue proprement.

## 13. Consequences runtime write prouvé

Le smoke victory stage puis commit :

- `SceneConsequence.setFact(fact_test_scene_victory, true)` ;
- `SceneConsequence.markEventConsumed(map_test_runtime, event_test_scene)`.

Le smoke defeat stage puis commit :

- `SceneConsequence.setFact(fact_test_scene_defeat, true)`.

## 14. Transaction / no partial writes

Le smoke failure utilise :

```text
start -> dialogue -> action setFact -> battle failure
```

Résultat prouvé :

- le dialogue complète ;
- la conséquence est stagee par l'executor ;
- le battle échoue via adapter ;
- le hook retourne `failed` ;
- `updatedGameState == null` ;
- `consequenceWriteResult == null` ;
- le `GameState` original reste inchangé.

## 15. No StorylineStep

Aucun lien StorylineStep n'est branché. Le smoke vérifie que `PlayerProgression.completedStepIds` reste inchangé après le commit victory.

## 16. No World Rule direct apply

La fixture smoke ne crée aucune World Rule. Le test vérifie que `ProjectManifest.worldRules` est vide. Les conséquences écrivent seulement des Facts / consumed events dans `GameState`.

## 17. Pourquoi aucun produit dédié n'a été créé

La fixture est neutre et utilise uniquement les IDs `*_test_*` autorisés par le prompt. Aucune donnée produit, carte réelle, personnage réel ou scène produit n'est introduite.

## 18. Tests exécutés avec sorties exactes

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_runtime_golden_slice_smoke_test.dart
```

Sortie exacte :

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_runtime_golden_slice_smoke_test.dart
00:01 +0: Scene runtime golden slice smoke event sceneTarget waits for dialogue then commits victory consequences
00:01 +1: Scene runtime golden slice smoke event sceneTarget waits for dialogue then commits victory consequences
00:01 +1: Scene runtime golden slice smoke event sceneTarget follows defeat branch and commits defeat consequence
00:01 +2: Scene runtime golden slice smoke event sceneTarget follows defeat branch and commits defeat consequence
00:01 +2: Scene runtime golden slice smoke event sceneTarget failure discards staged consequences
00:01 +3: Scene runtime golden slice smoke event sceneTarget failure discards staged consequences
00:01 +3: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_event_runtime_hook_test.dart
```

Sortie exacte :

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_event_runtime_hook_test.dart
00:01 +0: SceneEventRuntimeHook ignores event pages without sceneTarget
00:01 +1: SceneEventRuntimeHook ignores event pages without sceneTarget
00:01 +1: SceneEventRuntimeHook fails clearly when sceneTarget references a missing scene
00:01 +2: SceneEventRuntimeHook fails clearly when sceneTarget references a missing scene
00:01 +2: SceneEventRuntimeHook fails before execution when scene diagnostics contain errors
00:01 +3: SceneEventRuntimeHook fails before execution when scene diagnostics contain errors
00:01 +3: SceneEventRuntimeHook fails before execution when runtime plan cannot be built
00:01 +4: SceneEventRuntimeHook fails before execution when runtime plan cannot be built
00:01 +4: SceneEventRuntimeHook executes a targeted Scene V1 through dialogue and battle victory
00:01 +5: SceneEventRuntimeHook executes a targeted Scene V1 through dialogue and battle victory
00:01 +5: SceneEventRuntimeHook executes a targeted Scene V1 through battle defeat branch
00:01 +6: SceneEventRuntimeHook executes a targeted Scene V1 through battle defeat branch
00:01 +6: SceneEventRuntimeHook does not require or promote ScenarioAsset to execute Scene V1
00:01 +7: SceneEventRuntimeHook does not require or promote ScenarioAsset to execute Scene V1
00:01 +7: SceneEventRuntimeHook does not mutate project, map or game state
00:01 +8: SceneEventRuntimeHook does not mutate project, map or game state
00:01 +8: SceneEventRuntimeHook stages setFact consequence and commits it when scene completes
00:01 +9: SceneEventRuntimeHook stages setFact consequence and commits it when scene completes
00:01 +9: SceneEventRuntimeHook stages setFact consequence and waits for pending dialogue
00:01 +10: SceneEventRuntimeHook stages setFact consequence and waits for pending dialogue
00:01 +10: SceneEventRuntimeHook stages markEventConsumed consequence and commits it on completion
00:01 +11: SceneEventRuntimeHook stages markEventConsumed consequence and commits it on completion
00:01 +11: SceneEventRuntimeHook battle victory follows victory branch and commits consequence
00:01 +12: SceneEventRuntimeHook battle victory follows victory branch and commits consequence
00:01 +12: SceneEventRuntimeHook battle defeat follows defeat branch and commits consequence
00:01 +13: SceneEventRuntimeHook battle defeat follows defeat branch and commits consequence
00:01 +13: SceneEventRuntimeHook battle failure discards staged consequence
00:01 +14: SceneEventRuntimeHook battle failure discards staged consequence
00:01 +14: SceneEventRuntimeHook discards staged consequence when later callback fails
00:01 +15: SceneEventRuntimeHook discards staged consequence when later callback fails
00:01 +15: SceneEventRuntimeHook discards staged consequence when awaitable dialogue fails
00:01 +16: SceneEventRuntimeHook discards staged consequence when awaitable dialogue fails
00:01 +16: SceneEventRuntimeHook does not commit consequences when runtime plan fails
00:01 +17: SceneEventRuntimeHook does not commit consequences when runtime plan fails
00:01 +17: SceneEventRuntimeHook does not apply World Rules or complete StorylineStep directly
00:01 +18: SceneEventRuntimeHook does not apply World Rules or complete StorylineStep directly
00:01 +18: SceneEventRuntimeHook reports callback execution failure without mutating state
00:01 +19: SceneEventRuntimeHook reports callback execution failure without mutating state
00:01 +19: SceneEventRuntimeHook keeps Scene V1 hook files independent from battle package imports
00:01 +20: SceneEventRuntimeHook keeps Scene V1 hook files independent from battle package imports
00:01 +20: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_dialogue_runtime_awaitable_adapter_test.dart
```

Sortie exacte :

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_dialogue_runtime_awaitable_adapter_test.dart
00:01 +0: SceneDialogueRuntimeAwaitableAdapter maps launcher completion to Scene port completed
00:01 +1: SceneDialogueRuntimeAwaitableAdapter maps launcher completion to Scene port completed
00:01 +1: SceneDialogueRuntimeAwaitableAdapter fails clearly when intent has no dialogueId
00:01 +2: SceneDialogueRuntimeAwaitableAdapter fails clearly when intent has no dialogueId
00:01 +2: SceneDialogueRuntimeAwaitableAdapter fails clearly when launcher fails
00:01 +3: SceneDialogueRuntimeAwaitableAdapter fails clearly when launcher fails
00:01 +3: SceneDialogueRuntimeAwaitableAdapter wraps thrown launcher errors as launcher failure
00:01 +4: SceneDialogueRuntimeAwaitableAdapter wraps thrown launcher errors as launcher failure
00:01 +4: SceneDialogueRuntimeAwaitableAdapter does not invent dialogue outcomes
00:01 +5: SceneDialogueRuntimeAwaitableAdapter does not invent dialogue outcomes
00:01 +5: SceneDialogueRuntimeAwaitableAdapter does not mutate GameState or apply Scene consequences directly
00:01 +6: SceneDialogueRuntimeAwaitableAdapter does not mutate GameState or apply Scene consequences directly
00:01 +6: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_battle_runtime_outcome_adapter_test.dart
```

Sortie exacte :

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_battle_runtime_outcome_adapter_test.dart
00:01 +0: SceneBattleRuntimeOutcomeAdapter maps runtime victory to Scene port victory
00:01 +1: SceneBattleRuntimeOutcomeAdapter maps runtime victory to Scene port victory
00:01 +1: SceneBattleRuntimeOutcomeAdapter maps runtime defeat to Scene port defeat
00:01 +2: SceneBattleRuntimeOutcomeAdapter maps runtime defeat to Scene port defeat
00:01 +2: SceneBattleRuntimeOutcomeAdapter fails clearly when intent has no trainerId
00:01 +3: SceneBattleRuntimeOutcomeAdapter fails clearly when intent has no trainerId
00:01 +3: SceneBattleRuntimeOutcomeAdapter fails clearly when intent and default have no npcEntityId
00:01 +4: SceneBattleRuntimeOutcomeAdapter fails clearly when intent and default have no npcEntityId
00:01 +4: SceneBattleRuntimeOutcomeAdapter fails clearly when battle kind is unsupported
00:01 +5: SceneBattleRuntimeOutcomeAdapter fails clearly when battle kind is unsupported
00:01 +5: SceneBattleRuntimeOutcomeAdapter fails clearly when launcher fails
00:01 +6: SceneBattleRuntimeOutcomeAdapter fails clearly when launcher fails
00:01 +6: SceneBattleRuntimeOutcomeAdapter does not invent victory when launcher throws
00:01 +7: SceneBattleRuntimeOutcomeAdapter does not invent victory when launcher throws
00:01 +7: SceneBattleRuntimeOutcomeAdapter does not mutate GameState or apply Scene consequences directly
00:01 +8: SceneBattleRuntimeOutcomeAdapter does not mutate GameState or apply Scene consequences directly
00:01 +8: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_consequence_runtime_writer_test.dart
```

Sortie exacte :

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_consequence_runtime_writer_test.dart
00:01 +0: SceneConsequenceRuntimeWriter setFact true activates Fact runtime key
00:01 +1: SceneConsequenceRuntimeWriter setFact true activates Fact runtime key
00:01 +1: SceneConsequenceRuntimeWriter setFact false clears Fact runtime key
00:01 +2: SceneConsequenceRuntimeWriter setFact false clears Fact runtime key
00:01 +2: SceneConsequenceRuntimeWriter setFact uses legacyFlagName when present
00:01 +3: SceneConsequenceRuntimeWriter setFact uses legacyFlagName when present
00:01 +3: SceneConsequenceRuntimeWriter setFact unknown Fact fails without mutating the original state
00:01 +4: SceneConsequenceRuntimeWriter setFact unknown Fact fails without mutating the original state
00:01 +4: SceneConsequenceRuntimeWriter markEventConsumed adds consumed event id using existing convention
00:01 +5: SceneConsequenceRuntimeWriter markEventConsumed adds consumed event id using existing convention
00:01 +5: SceneConsequenceRuntimeWriter markEventConsumed unknown map fails clearly
00:01 +6: SceneConsequenceRuntimeWriter markEventConsumed unknown map fails clearly
00:01 +6: SceneConsequenceRuntimeWriter markEventConsumed unknown event fails clearly
00:01 +7: SceneConsequenceRuntimeWriter markEventConsumed unknown event fails clearly
00:01 +7: SceneConsequenceRuntimeWriter does not apply World Rules or complete StorySteps directly
00:01 +8: SceneConsequenceRuntimeWriter does not apply World Rules or complete StorySteps directly
00:01 +8: SceneConsequenceRuntimeWriter is deterministic and idempotent for repeated same consequence
00:01 +9: SceneConsequenceRuntimeWriter is deterministic and idempotent for repeated same consequence
00:01 +9: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_plan_test.dart
```

Sortie exacte utile :

```text
00:00 +15: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_executor_test.dart
```

Sortie exacte utile :

```text
00:00 +20: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/scene_consequence_model_test.dart
```

Sortie exacte utile :

```text
00:00 +8: All tests passed!
```

## 19. Analyze avec sortie exacte

Première analyse ciblée runtime, avant correction `const` :

```text
Analyzing 5 items...

   info • Use 'const' with the constructor to improve performance. Try adding the 'const' keyword to the constructor invocation • test/scene_runtime_golden_slice_smoke_test.dart:266:17 • prefer_const_constructors

1 issue found. (ran in 1.6s)
```

Analyse ciblée runtime finale :

```text
Analyzing 5 items...

No issues found! (ran in 1.2s)
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

## 20. Recherche anti-Selbrume

Commande exécutée avant création du rapport :

```text
rg ... packages/map_runtime/test/scene_runtime_golden_slice_smoke_test.dart reports/narrativeStudio/scenes/ns_scenes_v1_28_octies_golden_slice_runtime_smoke_v0.md || true
```

Sortie exacte :

```text
rg: reports/narrativeStudio/scenes/ns_scenes_v1_28_octies_golden_slice_runtime_smoke_v0.md: No such file or directory (os error 2)
```

Interprétation : le rapport n'existait pas encore. Une recherche finale est ajoutée dans l'Evidence Pack final.

## 21. Recherche anti-scope

Commande exécutée :

```text
rg ... packages/map_runtime/test/scene_runtime_golden_slice_smoke_test.dart packages/map_runtime/test/scene_event_runtime_hook_test.dart || true
```

Sortie exacte :

```text
packages/map_runtime/test/scene_event_runtime_hook_test.dart:146:    test('does not require or promote ScenarioAsset to execute Scene V1',
packages/map_runtime/test/scene_event_runtime_hook_test.dart:519:    test('does not apply World Rules or complete StorylineStep directly',
```

Interprétation : ces deux occurrences sont des assertions de garde-fou préexistantes dans `scene_event_runtime_hook_test.dart`. Le nouveau smoke test n'ajoute aucune occurrence anti-scope.

## 22. git diff --check

Sortie finale à la section 26.

## 23. git diff --stat

Sortie finale à la section 26.

## 24. git diff --name-only

Sortie finale à la section 26.

## 25. git status final exact

Sortie finale à la section 26.

## 26. Evidence Pack

### Nouveau fichier complet : `packages/map_runtime/test/scene_runtime_golden_slice_smoke_test.dart`

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('Scene runtime golden slice smoke', () {
    test(
      'event sceneTarget waits for dialogue then commits victory consequences',
      () async {
        final fixture = _goldenSmokeFixture();
        const originalGameState = GameState(
          saveId: 'save_test_runtime',
          progression: PlayerProgression(completedStepIds: ['step_before']),
        );
        final dialogueCompleter =
            Completer<SceneDialogueRuntimeAwaitableResult>();
        final runtimeCalls = <String>[];
        var hookCompleted = false;

        expect(fixture.event.pages.single.sceneTarget?.sceneId,
            'scene_test_runtime');
        expect(fixture.project.scenarios, isEmpty);
        expect(fixture.project.worldRules, isEmpty);

        final hookFuture = SceneEventRuntimeHook(
          callbacks: _adapterCallbacks(
            runtimeCalls: runtimeCalls,
            dialogueLauncher: _SmokeDialogueLauncher((request) {
              runtimeCalls.add('dialogue:${request.dialogueId}');
              return dialogueCompleter.future;
            }),
            battleLauncher: _SmokeBattleLauncher((request) {
              runtimeCalls.add('battle:${request.trainerId}:victory');
              return const SceneBattleRuntimeOutcomeResult.completed(
                port: SceneBattleRuntimeOutcomePort.victory,
              );
            }),
          ),
        )
            .runForEventPage(
          project: fixture.project,
          map: fixture.map,
          event: fixture.event,
          page: fixture.event.pages.single,
          gameState: originalGameState,
        )
            .then((result) {
          hookCompleted = true;
          return result;
        });

        await Future<void>.delayed(Duration.zero);

        expect(hookCompleted, isFalse);
        expect(runtimeCalls, ['dialogue:dialogue_test_intro']);
        expect(originalGameState.storyFlags.activeFlags, isEmpty);
        expect(originalGameState.consumedEventIds, isEmpty);

        dialogueCompleter.complete(
          const SceneDialogueRuntimeAwaitableResult.completed(),
        );

        final result = await hookFuture;

        expect(result.status, SceneEventRuntimeHookStatus.completed);
        expect(result.sceneId, 'scene_test_runtime');
        expect(result.executionResult?.status,
            SceneRuntimeExecutionStatus.completed);
        expect(result.executionResult?.finalNodeId, 'node_end_victory');
        expect(result.executionResult?.trace.map((entry) => entry.nodeId), [
          'node_start',
          'node_dialogue',
          'node_battle',
          'node_action_victory_fact',
          'node_action_victory_consumed',
          'node_end_victory',
        ]);
        expect(runtimeCalls, [
          'dialogue:dialogue_test_intro',
          'battle:trainer_test_guard:victory',
        ]);
        expect(
          result.updatedGameState?.storyFlags.activeFlags,
          contains('fact_test_scene_victory'),
        );
        expect(
          result.updatedGameState?.storyFlags.activeFlags,
          isNot(contains('fact_test_scene_defeat')),
        );
        expect(
          result.updatedGameState?.consumedEventIds,
          contains('event_test_scene'),
        );
        expect(
          result.updatedGameState?.progression.completedStepIds,
          ['step_before'],
        );
        expect(
          result.consequenceWriteResult?.appliedConsequences,
          hasLength(2),
        );
        expect(originalGameState.storyFlags.activeFlags, isEmpty);
        expect(originalGameState.consumedEventIds, isEmpty);
        expect(originalGameState.progression.completedStepIds, ['step_before']);
      },
    );

    test(
      'event sceneTarget follows defeat branch and commits defeat consequence',
      () async {
        final fixture = _goldenSmokeFixture();
        const originalGameState = GameState(saveId: 'save_test_runtime');
        final runtimeCalls = <String>[];

        final result = await SceneEventRuntimeHook(
          callbacks: _adapterCallbacks(
            runtimeCalls: runtimeCalls,
            dialogueLauncher: _SmokeDialogueLauncher((request) {
              runtimeCalls.add('dialogue:${request.dialogueId}');
              return const SceneDialogueRuntimeAwaitableResult.completed();
            }),
            battleLauncher: _SmokeBattleLauncher((request) {
              runtimeCalls.add('battle:${request.trainerId}:defeat');
              return const SceneBattleRuntimeOutcomeResult.completed(
                port: SceneBattleRuntimeOutcomePort.defeat,
              );
            }),
          ),
        ).runForEventPage(
          project: fixture.project,
          map: fixture.map,
          event: fixture.event,
          page: fixture.event.pages.single,
          gameState: originalGameState,
        );

        expect(result.status, SceneEventRuntimeHookStatus.completed);
        expect(result.executionResult?.finalNodeId, 'node_end_defeat');
        expect(result.executionResult?.trace.map((entry) => entry.nodeId), [
          'node_start',
          'node_dialogue',
          'node_battle',
          'node_action_defeat_fact',
          'node_end_defeat',
        ]);
        expect(runtimeCalls, [
          'dialogue:dialogue_test_intro',
          'battle:trainer_test_guard:defeat',
        ]);
        expect(
          result.updatedGameState?.storyFlags.activeFlags,
          contains('fact_test_scene_defeat'),
        );
        expect(
          result.updatedGameState?.storyFlags.activeFlags,
          isNot(contains('fact_test_scene_victory')),
        );
        expect(result.updatedGameState?.consumedEventIds, isEmpty);
        expect(
          result.consequenceWriteResult?.appliedConsequences,
          hasLength(1),
        );
        expect(originalGameState.storyFlags.activeFlags, isEmpty);
      },
    );

    test(
      'event sceneTarget failure discards staged consequences',
      () async {
        final fixture = _failureAfterStagedConsequenceFixture();
        const originalGameState = GameState(saveId: 'save_test_runtime');
        final runtimeCalls = <String>[];

        final result = await SceneEventRuntimeHook(
          callbacks: _adapterCallbacks(
            runtimeCalls: runtimeCalls,
            dialogueLauncher: _SmokeDialogueLauncher((request) {
              runtimeCalls.add('dialogue:${request.dialogueId}');
              return const SceneDialogueRuntimeAwaitableResult.completed();
            }),
            battleLauncher: _SmokeBattleLauncher((request) {
              runtimeCalls.add('battle:${request.trainerId}:failed');
              return const SceneBattleRuntimeOutcomeResult.failed(
                errorCode: SceneBattleRuntimeOutcomeErrorCode.launcherFailed,
                message: 'Controlled battle failure.',
              );
            }),
          ),
        ).runForEventPage(
          project: fixture.project,
          map: fixture.map,
          event: fixture.event,
          page: fixture.event.pages.single,
          gameState: originalGameState,
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
        expect(result.updatedGameState, isNull);
        expect(result.consequenceWriteResult, isNull);
        expect(runtimeCalls, [
          'dialogue:dialogue_test_intro',
          'battle:trainer_test_guard:failed',
        ]);
        expect(originalGameState.storyFlags.activeFlags, isEmpty);
        expect(originalGameState.consumedEventIds, isEmpty);
      },
    );
  });
}

SceneRuntimeHostCallbacks _adapterCallbacks({
  required List<String> runtimeCalls,
  required SceneDialogueRuntimeLauncher dialogueLauncher,
  required SceneBattleRuntimeLauncher battleLauncher,
}) {
  return SceneRuntimeHostCallbacks(
    evaluateCondition: (_) => throw StateError('Condition callback unused.'),
    showDialogue: (intent) async {
      final result = await SceneDialogueRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:golden-smoke',
        createdAtEpochMs: () => 1000,
        launcher: dialogueLauncher,
      ).showDialogue(intent);
      final scenePortId = result.scenePortId;
      if (!result.success || scenePortId == null) {
        throw StateError(result.message ?? 'Dialogue smoke failed.');
      }
      return scenePortId;
    },
    startBattle: (intent) async {
      final result = await SceneBattleRuntimeOutcomeAdapter(
        runtimeSourceId: 'scene:golden-smoke',
        defaultNpcEntityId: 'event_test_scene',
        createdAtEpochMs: () => 2000,
        launcher: battleLauncher,
      ).startBattle(intent);
      final scenePortId = result.scenePortId;
      if (!result.success || scenePortId == null) {
        throw StateError(result.message ?? 'Battle smoke failed.');
      }
      return scenePortId;
    },
    playCinematic: (_) => throw StateError('Cinematic callback unused.'),
  );
}

_GoldenSmokeFixture _goldenSmokeFixture() {
  return _fixture(scene: _goldenSmokeScene());
}

_GoldenSmokeFixture _failureAfterStagedConsequenceFixture() {
  return _fixture(scene: _failureAfterStagedConsequenceScene());
}

_GoldenSmokeFixture _fixture({required SceneAsset scene}) {
  const event = MapEventDefinition(
    id: 'event_test_scene',
    title: 'Runtime smoke event',
    position: EventPosition(layerId: 'l_base', x: 2, y: 2),
    pages: [
      MapEventPage(
        pageNumber: 0,
        sceneTarget: MapEventSceneTarget(sceneId: 'scene_test_runtime'),
      ),
    ],
  );
  final map = MapData(
    id: 'map_test_runtime',
    name: 'Runtime smoke map',
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
  final project = ProjectManifest(
    name: 'Runtime smoke project',
    maps: const [
      ProjectMapEntry(
        id: 'map_test_runtime',
        name: 'Runtime smoke map',
        relativePath: 'maps/map_test_runtime.json',
      ),
    ],
    tilesets: const [],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'dialogue_test_intro',
        name: 'Runtime smoke dialogue',
        relativePath: 'dialogues/dialogue_test_intro.yarn',
      ),
    ],
    trainers: const [
      ProjectTrainerEntry(
        id: 'trainer_test_guard',
        name: 'Runtime smoke trainer',
        trainerClass: 'Tester',
        team: [
          ProjectTrainerPokemonEntry(speciesId: 'pichu', level: 5),
        ],
      ),
    ],
    facts: [
      NarrativeFactDefinition(
        id: 'fact_test_scene_victory',
        label: 'Runtime smoke victory',
      ),
      NarrativeFactDefinition(
        id: 'fact_test_scene_defeat',
        label: 'Runtime smoke defeat',
      ),
      NarrativeFactDefinition(
        id: 'fact_test_event_consumed',
        label: 'Runtime smoke event consumed',
      ),
    ],
    scenes: [scene],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  return _GoldenSmokeFixture(project: project, map: map, event: event);
}

SceneAsset _goldenSmokeScene() {
  return SceneAsset(
    id: 'scene_test_runtime',
    name: 'Runtime smoke scene',
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
        SceneNode(
          id: 'node_action_victory_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(
              factId: 'fact_test_scene_victory',
              value: true,
            ),
          ),
        ),
        SceneNode(
          id: 'node_action_victory_consumed',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.markEventConsumed(
              mapId: 'map_test_runtime',
              eventId: 'event_test_scene',
            ),
          ),
        ),
        SceneNode(
          id: 'node_action_defeat_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(
              factId: 'fact_test_scene_defeat',
              value: true,
            ),
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
          toNodeId: 'node_action_victory_fact',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'edge_action_victory_fact_consumed',
          fromNodeId: 'node_action_victory_fact',
          fromPortId: 'completed',
          toNodeId: 'node_action_victory_consumed',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'edge_action_victory_consumed_end',
          fromNodeId: 'node_action_victory_consumed',
          fromPortId: 'completed',
          toNodeId: 'node_end_victory',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'edge_battle_defeat',
          fromNodeId: 'node_battle',
          fromPortId: 'defeat',
          toNodeId: 'node_action_defeat_fact',
          kind: SceneEdgeKind.battleDefeat,
        ),
        SceneEdge(
          id: 'edge_action_defeat_fact_end',
          fromNodeId: 'node_action_defeat_fact',
          fromPortId: 'completed',
          toNodeId: 'node_end_defeat',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        SceneNodeLayout(nodeId: 'node_start', x: 0, y: 0),
        SceneNodeLayout(nodeId: 'node_dialogue', x: 280, y: 0),
        SceneNodeLayout(nodeId: 'node_battle', x: 560, y: 0),
        SceneNodeLayout(nodeId: 'node_action_victory_fact', x: 840, y: -100),
        SceneNodeLayout(
          nodeId: 'node_action_victory_consumed',
          x: 1120,
          y: -100,
        ),
        SceneNodeLayout(nodeId: 'node_action_defeat_fact', x: 840, y: 120),
        SceneNodeLayout(nodeId: 'node_end_victory', x: 1400, y: -100),
        SceneNodeLayout(nodeId: 'node_end_defeat', x: 1120, y: 120),
      ],
    ),
  );
}

SceneAsset _failureAfterStagedConsequenceScene() {
  return SceneAsset(
    id: 'scene_test_runtime',
    name: 'Runtime smoke staged failure scene',
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
          id: 'node_action_victory_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(
              factId: 'fact_test_scene_victory',
              value: true,
            ),
          ),
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
          id: 'edge_dialogue_action_victory_fact',
          fromNodeId: 'node_dialogue',
          fromPortId: 'completed',
          toNodeId: 'node_action_victory_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_action_victory_fact_battle',
          fromNodeId: 'node_action_victory_fact',
          fromPortId: 'completed',
          toNodeId: 'node_battle',
          kind: SceneEdgeKind.actionCompleted,
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
        SceneNodeLayout(nodeId: 'node_action_victory_fact', x: 560, y: 0),
        SceneNodeLayout(nodeId: 'node_battle', x: 840, y: 0),
        SceneNodeLayout(nodeId: 'node_end_victory', x: 1120, y: -80),
        SceneNodeLayout(nodeId: 'node_end_defeat', x: 1120, y: 80),
      ],
    ),
  );
}

final class _GoldenSmokeFixture {
  const _GoldenSmokeFixture({
    required this.project,
    required this.map,
    required this.event,
  });

  final ProjectManifest project;
  final MapData map;
  final MapEventDefinition event;
}

final class _SmokeDialogueLauncher implements SceneDialogueRuntimeLauncher {
  const _SmokeDialogueLauncher(this._handler);

  final FutureOr<SceneDialogueRuntimeAwaitableResult> Function(
    SceneDialogueRuntimeDialogueRequest request,
  ) _handler;

  @override
  Future<SceneDialogueRuntimeAwaitableResult> showDialogue(
    SceneDialogueRuntimeDialogueRequest request,
  ) async {
    return _handler(request);
  }
}

final class _SmokeBattleLauncher implements SceneBattleRuntimeLauncher {
  const _SmokeBattleLauncher(this._handler);

  final FutureOr<SceneBattleRuntimeOutcomeResult> Function(
    SceneBattleRuntimeBattleRequest request,
  ) _handler;

  @override
  Future<SceneBattleRuntimeOutcomeResult> startTrainerBattle(
    SceneBattleRuntimeBattleRequest request,
  ) async {
    return _handler(request);
  }
}
```

### Contenu complet du rapport créé

Le contenu complet du rapport créé est l'ensemble du présent fichier Markdown, sections 1 à 29 incluses.

### Diff complet `road_map_scenes.md`

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index d9c1c853..7a5bdcff 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -80,16 +80,16 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-28-quinquies — Scene Consequence Runtime Write V0 | DONE | Runtime write controle pour consequences V0 : `applyConsequence` dans le plan/executor, staging dans le hook runtime, commit atomique `setFact` / `markEventConsumed`, sans World Rule direct apply ni StorylineStep link. |
 | NS-SCENES-V1-28-sexies — Battle Runtime Outcome Adapter V0 | DONE | Adapter runtime battle awaitable : trainer battle lance via le handoff existant, resultat reel mappe vers `victory` / `defeat`, failures propres, aucune consequence Scene ecrite par l'adapter. |
 | NS-SCENES-V1-28-septies — Dialogue Runtime Awaitable Adapter V0 | DONE | Adapter runtime dialogue awaitable : DialogueNode ouvre le dialogue existant, attend la fermeture reelle de l'overlay, retourne seulement `completed`, failures propres, aucune consequence Scene ecrite par l'adapter. |
-| NS-SCENES-V1-28-octies — Golden Slice Runtime Smoke V0 | TODO | Prouver la chaine runtime controlee Event -> Scene -> Dialogue awaitable -> Battle outcome -> consequences commit dans un smoke test neutre, avant StorylineStep link. |
+| NS-SCENES-V1-28-octies — Golden Slice Runtime Smoke V0 | DONE | Smoke runtime neutre prouve : Event -> Scene -> Dialogue awaitable pending/completed -> Battle victory/defeat awaitable -> consequences stagees puis commit atomique GameState. |
 | NS-SCENES-V1-29 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres builder, triggers, runtime MVP, consequence model/runtime write, battle outcome adapter, dialogue awaitable, golden slice runtime smoke et runtime hook stabilises. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-28-octies — Golden Slice Runtime Smoke V0`
+`NS-SCENES-V1-29 — StorylineStep to Scene Link`
 
-Raison : Event -> Scene, consequences runtime write, Battle awaitable et Dialogue awaitable sont maintenant connectes. Il faut prouver une chaine runtime complete dans un smoke test controle avant de brancher `StorylineStep.sceneLinkIds`.
+Raison : Event -> Scene, consequences runtime write, Battle awaitable et Dialogue awaitable sont maintenant connectes et prouves ensemble par un smoke runtime neutre. Scene V1 est assez stable pour brancher `StorylineStep.sceneLinkIds` comme lien de lecture/progression, sans remplacer Event -> Scene comme declencheur runtime.
 
-Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Selbrume Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0.
+Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Selbrume Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link.
 
 Note non bloquante : l'overview affiche encore parfois `Facts — necessite un modele` alors que Fact Registry V0 existe depuis V1-18. Ce point reste un polish d'alignement UI, pas le prochain blocage du golden slice.
 
@@ -205,6 +205,20 @@ Tests : adapter dialogue awaitable, hook Scene pending/completed/failure avec co
 
 Prochain lot exact : `NS-SCENES-V1-28-octies — Golden Slice Runtime Smoke V0`.
 
+## Mise a jour V1-28-octies
+
+Statut : `NS-SCENES-V1-28-octies — Golden Slice Runtime Smoke V0` est DONE.
+
+Decision : un smoke test runtime controle prouve maintenant la chaine complete `MapEventPage.sceneTarget -> SceneEventRuntimeHook -> SceneRuntimeExecutor -> SceneDialogueRuntimeAwaitableAdapter -> SceneBattleRuntimeOutcomeAdapter -> SceneConsequenceRuntimeWriter`.
+
+Preuve : la fixture neutre utilise `map_test_runtime`, `event_test_scene`, `scene_test_runtime`, `dialogue_test_intro`, `trainer_test_guard`, `fact_test_scene_victory`, `fact_test_scene_defeat` et `fact_test_event_consumed`. Le test victory prouve que la Scene reste pending tant que le dialogue awaitable n'est pas complete, puis lance le battle awaitable, suit `victory`, stage `setFact` et `markEventConsumed`, et commit le `GameState` seulement apres la fin. Le test defeat suit `defeat` et commit seulement la consequence defeat. Le test failure prouve qu'une consequence stagee avant un battle failure n'est pas commit.
+
+Limites : smoke applicatif hors Flame pour rester deterministe ; pas de StorylineStep link, pas de World Rule direct apply, pas de BranchByOutcome, pas d'outcome Yarn invente, pas de donnees Selbrume produit, pas de modification `map_core/lib/src`, `map_editor`, `map_battle`, `map_gameplay` ou `examples`.
+
+Tests : smoke runtime octies, hook event runtime, adapters dialogue/battle, writer consequences, analyse ciblee runtime, tests core runtime-plan/executor/consequence, `map_core dart analyze`, recherches anti-Selbrume/anti-scope et `git diff --check`.
+
+Prochain lot exact : `NS-SCENES-V1-29 — StorylineStep to Scene Link`.
+
 ## Decisions V1-24
 
 - `SceneRuntimePlan`, `SceneRuntimePlanNode`, `SceneRuntimePlanIntent`, `SceneRuntimePlanEdge`, `SceneRuntimePlanDiagnostic` et `SceneRuntimePlanBuildResult` sont ajoutes dans `map_core`.
```

### Diff complet `road_map_scene_builder_authoring.md`

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 938ecea3..6f5cf45f 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-28-octies — Golden Slice Runtime Smoke V0
+NS-SCENES-V1-29 — StorylineStep to Scene Link
 ```
 
 ## Principes
@@ -59,7 +59,7 @@ NS-SCENES-V1-28-octies — Golden Slice Runtime Smoke V0
 | NS-SCENES-V1-28-quinquies | Scene Consequence Runtime Write V0 | runtime / integration | DONE : appliquer explicitement les consequences V0 au runtime via un seam controle. | Pas de World Rule direct apply, pas de battle adapter, pas de StorylineStep link, pas de giveItem/teleport. | `scene_consequence_runtime_writer.dart`, hook runtime Scene, executor/plan, tests no partial writes. | DONE : setFact true/false, markEventConsumed, no WorldRule direct apply, no writes when executor/write fails. | Ecrire trop tot dans GameState ; appliquer les World Rules au lieu de projeter ; coupler aux battle outcomes. | DONE : consequences V0 appliquees explicitement et atomiquement au runtime, sans effets magiques. | V1-28-quater. |
 | NS-SCENES-V1-28-sexies | Battle Runtime Outcome Adapter V0 | runtime / integration | DONE : fournir au Scene runtime un vrai resultat battle awaitable `victory` / `defeat` pour suivre les ports BattleNode existants. | Pas de resultat invente, pas de StorylineStep link, pas de consequence supplementaire, pas de refonte battle. | `scene_battle_runtime_outcome_adapter.dart`, result, `PlayableMapGame`, hook tests. | DONE : adapter victory/defeat/failure, hook battle branches + consequences, core non-regression, analyzes. | Coupler Scene V1 aux internes battle ; court-circuiter le flow runtime existant ; inventer une victoire. | DONE : BattleNode avance sur un outcome runtime reel et testable, sans consequence ecrite par l'adapter. | V1-28-bis, V1-28-quinquies. |
 | NS-SCENES-V1-28-septies | Dialogue Runtime Awaitable Adapter V0 | runtime / integration | DONE : rendre `showDialogue` awaitable pour que la Scene continue apres fermeture reelle du dialogue. | Pas d'outcomes Yarn inventes, pas de BranchByOutcome, pas de refactor Dialogue Studio. | `scene_dialogue_runtime_awaitable_adapter.dart`, result, `PlayableMapGame`, hook tests. | DONE : dialogue completed reel, failure propre, no consequence write partiel, pending hook prouve. | Laisser la Scene continuer trop tot ; confondre completed avec outcomes Yarn. | DONE : Dialogue.completed devient temporellement fiable depuis `DialogueOverlayComponent.onFinished`. | V1-28-bis, V1-28-sexies. |
-| NS-SCENES-V1-28-octies | Golden Slice Runtime Smoke V0 | runtime / integration | Prouver la chaine runtime controlee Event -> Scene -> Dialogue awaitable -> Battle outcome -> consequences commit. | Pas de StorylineStep link, pas de donnees Selbrume produit, pas de nouveaux payloads, pas de World Rule direct apply. | smoke test runtime cible, fixtures neutres, rapport. | Smoke test runtime complet + non-regressions hook/adapters/core. | Confondre smoke neutre et seed produit ; masquer un failure dialogue/battle. | La chaine runtime complete est prouvee avant `StorylineStep.sceneLinkIds`. | V1-28-bis, V1-28-quinquies, V1-28-sexies, V1-28-septies. |
+| NS-SCENES-V1-28-octies | Golden Slice Runtime Smoke V0 | runtime / integration | DONE : prouver la chaine runtime controlee Event -> Scene -> Dialogue awaitable -> Battle outcome -> consequences commit. | Pas de StorylineStep link, pas de donnees Selbrume produit, pas de nouveaux payloads, pas de World Rule direct apply. | `scene_runtime_golden_slice_smoke_test.dart`, rapport, roadmaps. | DONE : smoke victory pending dialogue + battle victory + commit, smoke defeat, smoke failure no partial write, non-regressions hook/adapters/core. | Confondre smoke neutre et seed produit ; masquer un failure dialogue/battle. | DONE : chaine runtime complete prouvee avant `StorylineStep.sceneLinkIds`. | V1-28-bis, V1-28-quinquies, V1-28-sexies, V1-28-septies. |
 | NS-SCENES-V1-29 | StorylineStep to Scene Link | core / editor | Brancher `StorylineStep.sceneLinkIds` vers scenes stables. | Pas de declenchement runtime par StoryStep seul, pas de lien scenario legacy. | storyline models/UI validators si necessaire. | Tests refs scene, UI disabled/enabled, diagnostics link. | Confondre step et trigger ; progression pilotant toute la scene. | StoryStep peut referencer Scene pour lecture/progression, sans remplacer Event trigger. | V1-23, V1-26, V1-28-octies. |
 
 ## Options comparees
@@ -465,6 +465,18 @@ Tests : adapter dialogue awaitable, hook pending/completed/failure avec conseque
 
 Prochain lot exact : `NS-SCENES-V1-28-octies — Golden Slice Runtime Smoke V0`.
 
+## Mise a jour V1-28-octies
+
+Statut : `NS-SCENES-V1-28-octies — Golden Slice Runtime Smoke V0` est DONE.
+
+Decision : le smoke reste applicatif hors Flame et utilise les vraies briques runtime testables : `SceneEventRuntimeHook`, `SceneRuntimeExecutor`, `SceneDialogueRuntimeAwaitableAdapter`, `SceneBattleRuntimeOutcomeAdapter` et `SceneConsequenceRuntimeWriter`.
+
+Preuve : le test neutre couvre la branche victory avec dialogue pending puis completed, battle awaitable victory, `setFact`, `markEventConsumed` et commit atomique du `GameState`; la branche defeat commit seulement le Fact defeat; le cas failure abandonne une consequence stagee sans write partiel.
+
+Limites : pas de runtime Flame complet, pas de StorylineStep link, pas de World Rule direct apply, pas de BranchByOutcome, pas d'outcome Yarn invente, pas de donnee Selbrume produit.
+
+Prochain lot exact : `NS-SCENES-V1-29 — StorylineStep to Scene Link`.
+
 ## Selbrume golden slice
 
 Avant le golden slice, il faut au minimum :
```

### Commandes finales

Commande :

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_runtime/test/scene_runtime_golden_slice_smoke_test.dart reports/narrativeStudio/scenes/ns_scenes_v1_28_octies_golden_slice_runtime_smoke_v0.md || true
```

Sortie exacte :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_28_octies_golden_slice_runtime_smoke_v0.md:126:54acda44 feat(scenes): add golden slice selbrume readiness
```

Interprétation : l'unique occurrence vient du `git log --oneline -n 10` capturé au Gate 0. Le smoke test créé ne contient aucune donnée produit Selbrume.

Commande :

```bash
rg -n "StorylineStep|sceneLinkIds|projectWorldRuleEffects|WorldRuleEffect|BranchByOutcome|accepted|refused|choice_|giveItem|teleport|ScenarioAsset|ScenarioRuntimeExecutor" packages/map_runtime/test/scene_runtime_golden_slice_smoke_test.dart packages/map_runtime/test/scene_event_runtime_hook_test.dart || true
```

Sortie exacte :

```text
packages/map_runtime/test/scene_event_runtime_hook_test.dart:146:    test('does not require or promote ScenarioAsset to execute Scene V1',
packages/map_runtime/test/scene_event_runtime_hook_test.dart:519:    test('does not apply World Rules or complete StorylineStep directly',
```

Interprétation : ces deux occurrences sont des tests de garde-fou préexistants dans `scene_event_runtime_hook_test.dart`. Le smoke test créé ne branche pas `StorylineStep.sceneLinkIds`, ne déclenche pas World Rules directement, et n'utilise pas `ScenarioAsset`.

Commande :

```bash
git diff --check
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
 .../scenes/road_map_scene_builder_authoring.md     | 16 ++++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md  | 22 ++++++++++++++++++----
 2 files changed, 32 insertions(+), 6 deletions(-)
```

Note : `git diff --stat` n'inclut pas les fichiers non suivis. Le statut final les liste explicitement.

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Note : `git diff --name-only` n'inclut pas les fichiers non suivis. Le statut final les liste explicitement.

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_runtime/test/scene_runtime_golden_slice_smoke_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_28_octies_golden_slice_runtime_smoke_v0.md
```

## 27. Auto-review critique

- Est-ce que j'ai créé des données produit ? Non, seulement des IDs neutres `*_test_*`.
- Est-ce que j'ai branché `StorylineStep.sceneLinkIds` ? Non.
- Est-ce que j'ai utilisé StorylineStep comme trigger runtime ? Non.
- Est-ce que j'ai appliqué une World Rule directement ? Non.
- Est-ce que j'ai inventé un outcome Yarn ? Non.
- Est-ce que j'ai activé BranchByOutcome ? Non.
- Est-ce que j'ai modifié `map_battle` ? Non.
- Est-ce que j'ai modifié `map_editor` ? Non.
- Est-ce que j'ai modifié `map_core/lib/src` ? Non.
- Est-ce que le smoke utilise bien Dialogue awaitable ? Oui, via `SceneDialogueRuntimeAwaitableAdapter`.
- Est-ce que le smoke prouve que la Scene reste pending pendant le dialogue ? Oui, `hookCompleted` reste `false` avant completion du `Completer`.
- Est-ce que le smoke utilise bien Battle awaitable ? Oui, via `SceneBattleRuntimeOutcomeAdapter`.
- Est-ce que le smoke commit les conséquences uniquement à la fin ? Oui, via `SceneEventRuntimeHook` et `SceneConsequenceRuntimeWriter`.
- Est-ce que le smoke couvre un échec sans write partiel ? Oui.
- Est-ce que le prochain lot n'a pas été démarré ? Oui.

## 28. Limites restantes

- Le smoke est applicatif hors Flame, pas un test d'interaction `PlayableMapGame`.
- Les launchers dialogue/battle sont fake, mais les adapters et le hook sont réels.
- Aucun outcome Yarn détaillé n'est couvert.
- Aucun branchement StorylineStep n'est fait.
- Aucune World Rule n'est projetée au runtime.

## 29. Prochain lot recommandé

`NS-SCENES-V1-29 — StorylineStep to Scene Link`

Raison : la chaîne runtime complète est prouvée. On peut maintenant brancher les StorylineSteps comme liens de lecture/progression, sans les transformer en déclencheurs runtime à la place des Events.
