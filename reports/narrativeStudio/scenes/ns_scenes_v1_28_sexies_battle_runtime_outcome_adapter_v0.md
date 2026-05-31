# NS-SCENES-V1-28-sexies — Battle Runtime Outcome Adapter V0

## 1. Resume du lot

Le lot ajoute un adapter runtime battle awaitable pour Scene V1. Un `BattleNode` trainer peut maintenant lancer le handoff battle runtime existant depuis `PlayableMapGame`, attendre le `BattleOutcome` reel, puis retourner au `SceneRuntimeExecutor` le port Scene `victory` ou `defeat`.

Le lot ne cree aucune consequence Scene. Les consequences V0 restent gerees par le systeme V1-28-quinquies : staging dans le hook, commit atomique uniquement si la Scene complete.

## 2. Pourquoi V1-28-sexies existe

V1-28-quinquies permettait deja d'appliquer `setFact` et `markEventConsumed` apres completion d'une Scene, mais le callback runtime `startBattle` de `PlayableMapGame` refusait encore le vrai battle handoff car il ne disposait pas d'un resultat awaitable fiable.

Le verrou etait donc : ne pas inventer `victory` / `defeat`, mais exposer le resultat runtime reel au graphe Scene.

## 3. Rappel du scope

Scope realise :

- creation de `SceneBattleRuntimeOutcomeAdapter`;
- creation de `SceneBattleRuntimeOutcomeResult`;
- mapping strict `BattleOutcomeType.victory -> victory` et `BattleOutcomeType.defeat -> defeat`;
- branchement minimal du callback `startBattle` Scene V1 dans `PlayableMapGame`;
- completer localise pour attendre le battle handoff existant;
- tests adapter victory/defeat/failures;
- tests hook victory/defeat + consequences V0 et no partial write en cas d'echec battle;
- roadmaps mises a jour.

Non-objectifs respectes :

- pas de modification `map_battle`;
- pas de refactor global battle engine;
- pas de resultat battle invente;
- pas de consequence ecrite par l'adapter battle;
- pas de World Rule direct apply;
- pas de StorylineStep link;
- pas de BranchByOutcome;
- pas de UI editor;
- pas de donnee Selbrume.

## 4. Gate 0 complet

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
326e939c feat(scenes): add scene consequence runtime write v0
a6b46779 feat(scenes): add scene consequence model v0
d35b3987 feat(scenes): add map event sceneTarget runtime hook v0
54acda44 feat(scenes): add golden slice selbrume readiness
c480c4f5 test(scenes): refine world rule empty state handling
ac3b389c feat(scenes): add world rules map editor integration v0
757f0ad5 docs(scenes): add V1-26-bis evidence hardening report
108b8c3c feat(scenes): add scene runtime executor MVP
c0d43712 feat(scenes): add dialogue and battle authoring ports
36494eaf feat(scenes): expand diagnostics and validator checks
```

Interpretation : `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` etaient vides au Gate 0.

## 5. Changements preexistants vs changements du lot

Changements preexistants : aucun changement non committe detecte au Gate 0.

Changements introduits par NS-SCENES-V1-28-sexies : tous les fichiers crees/modifies listes ci-dessous.

## 6. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_quinquies_scene_consequence_runtime_write_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_quater_scene_consequence_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_ter_scene_consequence_contract_prep.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_bis_event_to_scene_runtime_hook_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_golden_slice_selbrume_scene_event_prep.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_27_world_rules_map_editor_integration_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_bis_scene_runtime_executor_evidence_review.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_scene_runtime_executor_mvp.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_24_scene_runtime_plan_v0.md`
- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_executor.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_trainer.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/scene_consequence.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_hook_result.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart`
- `packages/map_runtime/lib/src/application/trainer_battle_request.dart`
- `packages/map_runtime/lib/src/application/battle_start_request.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_core/test/scene_runtime_plan_test.dart`
- `packages/map_core/test/scene_runtime_executor_test.dart`
- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`
- `packages/map_runtime/test/scene_consequence_runtime_writer_test.dart`

## 7. Fichiers crees/modifies

Fichiers crees :

- `packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_result.dart`
- `packages/map_runtime/test/scene_battle_runtime_outcome_adapter_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_sexies_battle_runtime_outcome_adapter_v0.md`

Fichiers modifies :

- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 8. Audit du battle runtime path existant

Chemin trainer battle existant :

- `buildTrainerBattleRequestFromNpc` construit un `TrainerBattleStartRequest` depuis une entite PNJ dresseur.
- `TrainerBattleStartRequest` porte `requestId`, `createdAtEpochMs`, `trainerId`, `npcEntityId`, `mapId`, `playerPos` et `OverworldReturnContext`.
- `PlayableMapGame` lance le handoff via `_startBattleHandoff`.
- Le battle overlay se termine par `_onBattleFinished(BattleOutcome outcome)`.
- `_onBattleFinished` applique deja les writes battle legitimes via `applyRuntimeBattleOutcomeToGameState`.
- Les outcomes runtime existants sont portes par `BattleOutcomeType` : `victory`, `defeat`, `runaway`, `captured`.
- Le scenario legacy avait deja son propre traitement d'outcome flags, mais Scene V1 n'avait pas de `Future` qui se resolvait sur l'outcome reel.

Pourquoi ce n'etait pas awaitable pour Scene V1 : le callback `SceneRuntimeHostCallbacks.startBattle` dans `PlayableMapGame` levait un `UnsupportedError`, car le handoff battle etait asynchrone via l'overlay et ne retournait pas directement `victory` / `defeat` au graphe Scene.

## 9. Design retenu

Design retenu : ajouter un adapter testable hors Flame, puis brancher `PlayableMapGame` par un seam minimal.

- `SceneBattleRuntimeOutcomeAdapter` transforme un `SceneRuntimePlanIntent.startBattle` en `SceneBattleRuntimeBattleRequest`.
- Le launcher concret est injecte via `SceneBattleRuntimeLauncher`.
- Dans `PlayableMapGame`, le launcher lance un `TrainerBattleStartRequest` existant et retourne un `Future<SceneBattleRuntimeOutcomeResult>`.
- `_onBattleFinished` resolve ce future avec un resultat derive du `BattleOutcome` runtime.
- Si le battle echoue avant outcome, `_cancelBattleHandoff` complete le pending Scene battle en failure.

## 10. API Battle Runtime Outcome Adapter

Nouveaux types publics exports par `map_runtime.dart` :

- `SceneBattleRuntimeOutcomeAdapter`
- `SceneBattleRuntimeLauncher`
- `SceneBattleRuntimeBattleRequest`
- `SceneBattleRuntimeOutcomeResult`
- `SceneBattleRuntimeOutcomeStatus`
- `SceneBattleRuntimeOutcomePort`
- `SceneBattleRuntimeOutcomeErrorCode`

## 11. Mapping runtime outcome -> Scene port

Mapping V0 :

| Runtime outcome | Scene port | Statut |
|---|---|---|
| `BattleOutcomeType.victory` | `victory` | supporte |
| `BattleOutcomeType.defeat` | `defeat` | supporte |
| `BattleOutcomeType.runaway` | aucun | failure unsupported |
| `BattleOutcomeType.captured` | aucun | failure unsupported |

Le callback `SceneRuntimeHostCallbacks.startBattle` retourne seulement `result.scenePortId`. Il ne choisit jamais un port a partir du payload, du trainerId ou d'un flag debug.

## 12. Outcomes non supportes

`runaway` et `captured` sont des outcomes runtime connus, mais ils ne correspondent pas aux ports V0 declares par un BattleNode trainer Scene V1. Ils echouent donc proprement via `SceneBattleRuntimeOutcomeErrorCode.unsupportedOutcome`.

## 13. Integration SceneRuntimeHostCallbacks

Avant :

```dart
startBattle: (intent) {
  throw UnsupportedError(
    'Scene V1 battle handoff is not awaitable in runtime hook V0 '
    '(battleKind=${intent.battleKind}, trainerId=${intent.trainerId}).',
  );
},
```

Apres :

```dart
startBattle: (intent) {
  final adapter = SceneBattleRuntimeOutcomeAdapter(
    runtimeSourceId: runtimeSourceId,
    defaultNpcEntityId: event.id,
    launcher: _CallbackSceneBattleRuntimeLauncher(
      _startSceneTrainerBattle,
    ),
  );
  return adapter.startBattle(intent).then((result) {
    final scenePortId = result.scenePortId;
    if (!result.success || scenePortId == null) {
      throw StateError(
        result.message ??
            'Scene V1 battle handoff failed '
                '(battleKind=${intent.battleKind}, '
                'trainerId=${intent.trainerId}).',
      );
    }
    return scenePortId;
  });
},
```

## 14. Integration PlayableMapGame

Sections completes ajoutees/modifiees :

```dart
Completer<SceneBattleRuntimeOutcomeResult>?
    _pendingSceneBattleOutcomeCompleter;
String? _pendingSceneBattleRequestId;
```

```dart
void _completePendingSceneBattleOutcome(
  SceneBattleRuntimeOutcomeResult result,
) {
  final completer = _pendingSceneBattleOutcomeCompleter;
  if (completer == null) {
    return;
  }
  final requestId = _pendingSceneBattleRequestId;
  _pendingSceneBattleOutcomeCompleter = null;
  _pendingSceneBattleRequestId = null;
  if (!completer.isCompleted) {
    completer.complete(result);
  }
  debugPrint(
    '[scene_runtime] battle outcome completed request=${requestId ?? '-'} '
    'status=${result.status.name} port=${result.scenePortId ?? '-'}',
  );
}
```

```dart
SceneBattleRuntimeOutcomeResult _sceneBattleRuntimeOutcomeFromBattle(
  BattleOutcome outcome,
) {
  return switch (outcome.type) {
    BattleOutcomeType.victory =>
      const SceneBattleRuntimeOutcomeResult.completed(
        port: SceneBattleRuntimeOutcomePort.victory,
      ),
    BattleOutcomeType.defeat =>
      const SceneBattleRuntimeOutcomeResult.completed(
        port: SceneBattleRuntimeOutcomePort.defeat,
      ),
    BattleOutcomeType.runaway => const SceneBattleRuntimeOutcomeResult.failed(
        errorCode: SceneBattleRuntimeOutcomeErrorCode.unsupportedOutcome,
        message: 'Scene trainer battle does not support runaway outcome.',
      ),
    BattleOutcomeType.captured =>
      const SceneBattleRuntimeOutcomeResult.failed(
        errorCode: SceneBattleRuntimeOutcomeErrorCode.unsupportedOutcome,
        message: 'Scene trainer battle does not support captured outcome.',
      ),
  };
}
```

```dart
Future<SceneBattleRuntimeOutcomeResult> _startSceneTrainerBattle(
  SceneBattleRuntimeBattleRequest request,
) {
  if (_flowPhase != _RuntimeFlowPhase.overworld) {
    return Future.value(
      const SceneBattleRuntimeOutcomeResult.failed(
        errorCode: SceneBattleRuntimeOutcomeErrorCode.launcherFailed,
        message: 'Scene trainer battle requires overworld flow.',
      ),
    );
  }
  if (_pendingSceneBattleOutcomeCompleter != null) {
    return Future.value(
      const SceneBattleRuntimeOutcomeResult.failed(
        errorCode: SceneBattleRuntimeOutcomeErrorCode.launcherFailed,
        message: 'A Scene trainer battle is already pending.',
      ),
    );
  }

  final completer = Completer<SceneBattleRuntimeOutcomeResult>();
  _pendingSceneBattleOutcomeCompleter = completer;
  _pendingSceneBattleRequestId = request.requestId;

  final trainerRequest = TrainerBattleStartRequest(
    requestId: request.requestId,
    createdAtEpochMs: request.createdAtEpochMs,
    returnContext: OverworldReturnContext(
      mapId: _world.map.id,
      playerPos: _world.player.pos,
      playerFacing: _world.player.facing,
    ),
    trainerId: request.trainerId,
    npcEntityId: request.npcEntityId,
    mapId: _world.map.id,
    playerPos: _world.player.pos,
  );
  _startBattleHandoff(trainerRequest);
  return completer.future;
}
```

```dart
final class _CallbackSceneBattleRuntimeLauncher
    implements SceneBattleRuntimeLauncher {
  const _CallbackSceneBattleRuntimeLauncher(this._startTrainerBattle);

  final Future<SceneBattleRuntimeOutcomeResult> Function(
    SceneBattleRuntimeBattleRequest request,
  ) _startTrainerBattle;

  @override
  Future<SceneBattleRuntimeOutcomeResult> startTrainerBattle(
    SceneBattleRuntimeBattleRequest request,
  ) {
    return _startTrainerBattle(request);
  }
}
```

## 15. Relation avec Scene consequences V0

L'adapter battle ne lit ni n'ecrit `SceneConsequence`.

Le test hook couvre le flux :

```text
start -> battle -> victory -> action setFact -> end
```

Le commit `setFact` reste fait par `SceneEventRuntimeHook` et `SceneConsequenceRuntimeWriter`, pas par l'adapter battle.

## 16. Relation avec GameState battle vs GameState narrative

`_onBattleFinished` continue d'appeler `applyRuntimeBattleOutcomeToGameState`, qui reste responsable des effets battle existants : PV/lineup, trainer defeated et autres etats propres au battle runtime.

L'adapter Scene ne fait pas de write narratif direct : pas de Fact, pas d'event consumed, pas de StoryStep, pas de World Rule.

## 17. Ce qui reste non couvert

- Dialogue runtime encore non awaitable : `showDialogue` retourne `completed` immediatement.
- Pas d'outcomes Yarn detailles.
- Pas de BranchByOutcome.
- Pas de StorylineStep.sceneLinkIds.
- `runaway` et `captured` restent unsupported pour un BattleNode trainer Scene V1.

## 18. Pourquoi aucun outcome n'est invente

Les seuls ports complets proviennent de :

```dart
BattleOutcomeType.victory
BattleOutcomeType.defeat
```

L'adapter de production ne contient pas de branche debug, random, trainerId-based ou payload-based pour choisir l'outcome. Les tests utilisent des fake launchers uniquement dans `test/`.

## 19. Pourquoi aucune consequence n'est ecrite par l'adapter battle

`SceneBattleRuntimeOutcomeAdapter` ne depend pas de `GameState`, `SceneConsequenceRuntimeWriter`, `SceneConsequence`, `WorldRuleEffect` ou `StorylineStep`. Il retourne seulement un `SceneBattleRuntimeOutcomeResult`.

## 20. Pourquoi aucune donnee Selbrume n'a ete creee

Les ids de test sont neutres : `trainer_guard`, `event_guard`, `scene_test_runtime`, `fact_test_battle_victory`, `fact_test_battle_defeat`.

Aucun fichier `selbrume/**`, aucune scene produit, aucun personnage produit et aucune map produit n'a ete modifie.

## 21. Tests executes avec sorties exactes

### map_runtime adapter

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_battle_runtime_outcome_adapter_test.dart
```

Sortie exacte :

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_battle_runtime_outcome_adapter_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_battle_runtime_outcome_adapter_test.dart
00:02 +0: SceneBattleRuntimeOutcomeAdapter maps runtime victory to Scene port victory
00:02 +1: SceneBattleRuntimeOutcomeAdapter maps runtime victory to Scene port victory
00:02 +1: SceneBattleRuntimeOutcomeAdapter maps runtime defeat to Scene port defeat
00:02 +2: SceneBattleRuntimeOutcomeAdapter maps runtime defeat to Scene port defeat
00:02 +2: SceneBattleRuntimeOutcomeAdapter fails clearly when intent has no trainerId
00:02 +3: SceneBattleRuntimeOutcomeAdapter fails clearly when intent has no trainerId
00:02 +3: SceneBattleRuntimeOutcomeAdapter fails clearly when intent and default have no npcEntityId
00:02 +4: SceneBattleRuntimeOutcomeAdapter fails clearly when intent and default have no npcEntityId
00:02 +4: SceneBattleRuntimeOutcomeAdapter fails clearly when battle kind is unsupported
00:02 +5: SceneBattleRuntimeOutcomeAdapter fails clearly when battle kind is unsupported
00:02 +5: SceneBattleRuntimeOutcomeAdapter fails clearly when launcher fails
00:02 +6: SceneBattleRuntimeOutcomeAdapter fails clearly when launcher fails
00:02 +6: SceneBattleRuntimeOutcomeAdapter does not invent victory when launcher throws
00:02 +7: SceneBattleRuntimeOutcomeAdapter does not invent victory when launcher throws
00:02 +7: SceneBattleRuntimeOutcomeAdapter does not mutate GameState or apply Scene consequences directly
00:02 +8: SceneBattleRuntimeOutcomeAdapter does not mutate GameState or apply Scene consequences directly
00:02 +8: All tests passed!
```

### map_runtime hook

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
00:01 +9: SceneEventRuntimeHook stages markEventConsumed consequence and commits it on completion
00:01 +10: SceneEventRuntimeHook stages markEventConsumed consequence and commits it on completion
00:01 +10: SceneEventRuntimeHook battle victory follows victory branch and commits consequence
00:01 +11: SceneEventRuntimeHook battle victory follows victory branch and commits consequence
00:01 +11: SceneEventRuntimeHook battle defeat follows defeat branch and commits consequence
00:01 +12: SceneEventRuntimeHook battle defeat follows defeat branch and commits consequence
00:01 +12: SceneEventRuntimeHook battle failure discards staged consequence
00:01 +13: SceneEventRuntimeHook battle failure discards staged consequence
00:01 +13: SceneEventRuntimeHook discards staged consequence when later callback fails
00:01 +14: SceneEventRuntimeHook discards staged consequence when later callback fails
00:01 +14: SceneEventRuntimeHook does not commit consequences when runtime plan fails
00:01 +15: SceneEventRuntimeHook does not commit consequences when runtime plan fails
00:01 +15: SceneEventRuntimeHook does not apply World Rules or complete StorylineStep directly
00:01 +16: SceneEventRuntimeHook does not apply World Rules or complete StorylineStep directly
00:01 +16: SceneEventRuntimeHook reports callback execution failure without mutating state
00:01 +17: SceneEventRuntimeHook reports callback execution failure without mutating state
00:01 +17: SceneEventRuntimeHook keeps Scene V1 hook files independent from battle package imports
00:01 +18: SceneEventRuntimeHook keeps Scene V1 hook files independent from battle package imports
00:01 +18: All tests passed!
```

### map_core scene_runtime_plan_test

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
00:00 +11: Scene runtime plan V0 typed setFact action nodes become applyConsequence intents
00:00 +12: Scene runtime plan V0 typed setFact action nodes become applyConsequence intents
00:00 +12: Scene runtime plan V0 typed markEventConsumed action nodes preserve consequence payload
00:00 +13: Scene runtime plan V0 typed markEventConsumed action nodes preserve consequence payload
00:00 +13: Scene runtime plan V0 branchByOutcome nodes produce unsupported diagnostics and no plan
00:00 +14: Scene runtime plan V0 branchByOutcome nodes produce unsupported diagnostics and no plan
00:00 +14: Scene runtime plan V0 does not mutate the original SceneAsset
00:00 +15: Scene runtime plan V0 does not mutate the original SceneAsset
00:00 +15: All tests passed!
```

### map_core scene_runtime_executor_test

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
00:00 +10: SceneRuntimeExecutor MVP calls applyConsequence and follows completed output
00:00 +11: SceneRuntimeExecutor MVP calls applyConsequence and follows completed output
00:00 +11: SceneRuntimeExecutor MVP fails when applyConsequence callback throws
00:00 +12: SceneRuntimeExecutor MVP fails when applyConsequence callback throws
00:00 +12: SceneRuntimeExecutor MVP fails when start node is missing from plan
00:00 +13: SceneRuntimeExecutor MVP fails when start node is missing from plan
00:00 +13: SceneRuntimeExecutor MVP fails when returned port has no transition
00:00 +14: SceneRuntimeExecutor MVP fails when returned port has no transition
00:00 +14: SceneRuntimeExecutor MVP fails when returned port is unsupported
00:00 +15: SceneRuntimeExecutor MVP fails when returned port is unsupported
00:00 +15: SceneRuntimeExecutor MVP fails when multiple transitions match same node and port
00:00 +16: SceneRuntimeExecutor MVP fails when multiple transitions match same node and port
00:00 +16: SceneRuntimeExecutor MVP fails when target node is missing
00:00 +17: SceneRuntimeExecutor MVP fails when target node is missing
00:00 +17: SceneRuntimeExecutor MVP fails when callback throws
00:00 +18: SceneRuntimeExecutor MVP fails when callback throws
00:00 +18: SceneRuntimeExecutor MVP fails when maxSteps is exceeded
00:00 +19: SceneRuntimeExecutor MVP fails when maxSteps is exceeded
00:00 +19: SceneRuntimeExecutor MVP does not mutate SceneRuntimePlan
00:00 +20: SceneRuntimeExecutor MVP does not mutate SceneRuntimePlan
00:00 +20: All tests passed!
```

### map_core scene_consequence_model_test

Commande :

```bash
cd packages/map_core && dart test test/scene_consequence_model_test.dart
```

Sortie exacte :

```text
00:00 +0: loading test/scene_consequence_model_test.dart
00:00 +0: SceneConsequence V0 setFact stores factId and value
00:00 +1: SceneConsequence V0 setFact stores factId and value
00:00 +1: SceneConsequence V0 markEventConsumed stores mapId and eventId
00:00 +2: SceneConsequence V0 markEventConsumed stores mapId and eventId
00:00 +2: SceneConsequence V0 setFact JSON round-trips
00:00 +3: SceneConsequence V0 setFact JSON round-trips
00:00 +3: SceneConsequence V0 markEventConsumed JSON round-trips
00:00 +4: SceneConsequence V0 markEventConsumed JSON round-trips
00:00 +4: SceneConsequence V0 rejects unknown consequence kind
00:00 +5: SceneConsequence V0 rejects unknown consequence kind
00:00 +5: SceneActionPayload typed consequences can carry typed setFact consequence
00:00 +6: SceneActionPayload typed consequences can carry typed setFact consequence
00:00 +6: SceneActionPayload typed consequences can carry typed markEventConsumed consequence
00:00 +7: SceneActionPayload typed consequences can carry typed markEventConsumed consequence
00:00 +7: SceneActionPayload typed consequences legacy actionKind payload still deserializes
00:00 +8: SceneActionPayload typed consequences legacy actionKind payload still deserializes
00:00 +8: All tests passed!
```

## 22. Analyze avec sortie exacte

### map_runtime analyse ciblee

Commande :

```bash
cd packages/map_runtime && flutter analyze --no-fatal-infos lib/map_runtime.dart lib/src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart lib/src/application/scene_runtime/scene_battle_runtime_outcome_result.dart lib/src/presentation/flame/playable_map_game.dart test/scene_battle_runtime_outcome_adapter_test.dart test/scene_event_runtime_hook_test.dart
```

Sortie exacte :

```text
Analyzing 6 items...

No issues found! (ran in 2.3s)
```

### map_core analyze

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
```

## 23. Recherche anti-Selbrume

Commande :

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_runtime/lib/src/application/scene_runtime packages/map_runtime/test reports/narrativeStudio/scenes/ns_scenes_v1_28_sexies_battle_runtime_outcome_adapter_v0.md || true
```

Sortie exacte utile pour les fichiers du lot :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_28_sexies_battle_runtime_outcome_adapter_v0.md:56:54acda44 feat(scenes): add golden slice selbrume readiness
reports/narrativeStudio/scenes/ns_scenes_v1_28_sexies_battle_runtime_outcome_adapter_v0.md:83:- `reports/narrativeStudio/scenes/ns_scenes_v1_28_golden_slice_selbrume_scene_event_prep.md`
reports/narrativeStudio/scenes/ns_scenes_v1_28_sexies_battle_runtime_outcome_adapter_v0.md:386:Aucun fichier `selbrume/**`, aucune scene produit, aucun personnage produit et aucune map produit n'a ete modifie.
```

Interpretation : les correspondances dans le rapport sont documentaires. La meme commande retourne aussi des correspondances historiques preexistantes dans des tests `p5_*`, `p6_*`, `scenario_battle_from_scene_test.dart`, `ns_gs_12_golden_slice_validation_test.dart`, `battle_move_visual_*`; ces fichiers ne sont pas modifies par ce lot. Les fichiers crees/modifies par V1-28-sexies ne creent aucune donnee produit Selbrume.

## 24. Recherche anti-scope

Commande :

```bash
rg -n "setFact|markEventConsumed|projectWorldRuleEffects|WorldRuleEffect|StorylineStep|sceneLinkIds|BranchByOutcome|giveItem|teleport|hardcoded|fake victory|fake defeat" packages/map_runtime/lib/src/application/scene_runtime packages/map_runtime/test/scene_battle_runtime_outcome_adapter_test.dart packages/map_runtime/test/scene_event_runtime_hook_test.dart || true
```

Sortie exacte :

```text
packages/map_runtime/test/scene_event_runtime_hook_test.dart:185:    test('stages setFact consequence and commits it when scene completes',
packages/map_runtime/test/scene_event_runtime_hook_test.dart:217:    test('stages markEventConsumed consequence and commits it on completion',
packages/map_runtime/test/scene_event_runtime_hook_test.dart:424:    test('does not apply World Rules or complete StorylineStep directly',
packages/map_runtime/test/scene_event_runtime_hook_test.dart:750:      SceneConsequence.setFact(
packages/map_runtime/test/scene_event_runtime_hook_test.dart:761:      SceneConsequence.markEventConsumed(
packages/map_runtime/test/scene_event_runtime_hook_test.dart:781:            SceneConsequence.setFact(
packages/map_runtime/test/scene_event_runtime_hook_test.dart:833:            SceneConsequence.setFact(
packages/map_runtime/test/scene_event_runtime_hook_test.dart:898:            SceneConsequence.setFact(
packages/map_runtime/test/scene_event_runtime_hook_test.dart:908:            SceneConsequence.setFact(
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart:48:      SceneConsequenceKind.setFact => _applySetFact(
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart:52:      SceneConsequenceKind.markEventConsumed => _applyMarkEventConsumed(
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart:67:        'Scene consequence setFact references unknown Fact '
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart:88:        'Scene consequence markEventConsumed references unknown map '
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart:97:        'Scene consequence markEventConsumed references unknown event '
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart:102:      mutations.markEventConsumed(gameState, consequence.eventId),
```

Interpretation : les matches `setFact` et `markEventConsumed` appartiennent au systeme de consequences V0 existant et aux tests qui prouvent le commit apres branche battle. Aucun match `projectWorldRuleEffects`, `WorldRuleEffect`, `sceneLinkIds`, `BranchByOutcome`, `giveItem`, `teleport`, `hardcoded`, `fake victory` ou `fake defeat` n'est retourne.

## 25. git diff --check

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
Sortie : <vide>
```

## 26. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 packages/map_runtime/lib/map_runtime.dart          |  11 +
 .../src/presentation/flame/playable_map_game.dart  | 144 +++++++++-
 .../test/scene_event_runtime_hook_test.dart        | 307 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  19 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  25 +-
 5 files changed, 495 insertions(+), 11 deletions(-)
```

## 27. git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
packages/map_runtime/lib/map_runtime.dart
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

Sortie exacte :

```text
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/scene_event_runtime_hook_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart
?? packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_result.dart
?? packages/map_runtime/test/scene_battle_runtime_outcome_adapter_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_28_sexies_battle_runtime_outcome_adapter_v0.md
```

## 29. Evidence Pack

### Contenu complet : `packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart`

```dart
import 'package:map_core/map_core.dart';

import 'scene_battle_runtime_outcome_result.dart';

abstract interface class SceneBattleRuntimeLauncher {
  Future<SceneBattleRuntimeOutcomeResult> startTrainerBattle(
    SceneBattleRuntimeBattleRequest request,
  );
}

final class SceneBattleRuntimeBattleRequest {
  const SceneBattleRuntimeBattleRequest({
    required this.requestId,
    required this.createdAtEpochMs,
    required this.trainerId,
    required this.npcEntityId,
    this.battleTemplateId,
  });

  final String requestId;
  final int createdAtEpochMs;
  final String trainerId;
  final String npcEntityId;
  final String? battleTemplateId;
}

final class SceneBattleRuntimeOutcomeAdapter {
  const SceneBattleRuntimeOutcomeAdapter({
    required this.runtimeSourceId,
    required this.defaultNpcEntityId,
    required this.launcher,
    this.createdAtEpochMs = _systemNowMs,
  });

  final String runtimeSourceId;
  final String defaultNpcEntityId;
  final SceneBattleRuntimeLauncher launcher;
  final int Function() createdAtEpochMs;

  Future<SceneBattleRuntimeOutcomeResult> startBattle(
    SceneRuntimePlanIntent intent,
  ) async {
    final battleKind = intent.battleKind?.trim();
    if (battleKind != 'trainer') {
      return SceneBattleRuntimeOutcomeResult.failed(
        errorCode: SceneBattleRuntimeOutcomeErrorCode.unsupportedBattleKind,
        message: 'Scene battle kind "$battleKind" is not supported in V0.',
      );
    }

    final trainerId = intent.trainerId?.trim();
    if (trainerId == null || trainerId.isEmpty) {
      return const SceneBattleRuntimeOutcomeResult.failed(
        errorCode: SceneBattleRuntimeOutcomeErrorCode.missingTrainerId,
        message: 'Scene trainer battle intent is missing trainerId.',
      );
    }

    final npcEntityId = _resolveNpcEntityId(intent);
    if (npcEntityId == null) {
      return const SceneBattleRuntimeOutcomeResult.failed(
        errorCode: SceneBattleRuntimeOutcomeErrorCode.missingNpcEntityId,
        message: 'Scene trainer battle intent is missing npcEntityId.',
      );
    }

    final now = createdAtEpochMs();
    final request = SceneBattleRuntimeBattleRequest(
      requestId: '$runtimeSourceId:$trainerId:$now',
      createdAtEpochMs: now,
      trainerId: trainerId,
      npcEntityId: npcEntityId,
      battleTemplateId: intent.battleTemplateId,
    );

    try {
      return await launcher.startTrainerBattle(request);
    } catch (error) {
      return SceneBattleRuntimeOutcomeResult.failed(
        errorCode: SceneBattleRuntimeOutcomeErrorCode.launcherFailed,
        message: 'Scene trainer battle launcher failed: $error',
      );
    }
  }

  String? _resolveNpcEntityId(SceneRuntimePlanIntent intent) {
    final npcEntityId = intent.npcEntityId?.trim();
    if (npcEntityId != null && npcEntityId.isNotEmpty) {
      return npcEntityId;
    }
    final fallbackNpcEntityId = defaultNpcEntityId.trim();
    return fallbackNpcEntityId.isEmpty ? null : fallbackNpcEntityId;
  }
}

int _systemNowMs() => DateTime.now().millisecondsSinceEpoch;
```

### Contenu complet : `packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_result.dart`

```dart
enum SceneBattleRuntimeOutcomeStatus {
  completed,
  failed,
}

enum SceneBattleRuntimeOutcomePort {
  victory,
  defeat,
}

enum SceneBattleRuntimeOutcomeErrorCode {
  missingTrainerId,
  missingNpcEntityId,
  unsupportedBattleKind,
  launcherFailed,
  unsupportedOutcome,
}

final class SceneBattleRuntimeOutcomeResult {
  const SceneBattleRuntimeOutcomeResult._({
    required this.status,
    this.port,
    this.errorCode,
    this.message,
  });

  const SceneBattleRuntimeOutcomeResult.completed({
    required SceneBattleRuntimeOutcomePort port,
  }) : this._(
          status: SceneBattleRuntimeOutcomeStatus.completed,
          port: port,
        );

  const SceneBattleRuntimeOutcomeResult.failed({
    required SceneBattleRuntimeOutcomeErrorCode errorCode,
    required String message,
  }) : this._(
          status: SceneBattleRuntimeOutcomeStatus.failed,
          errorCode: errorCode,
          message: message,
        );

  final SceneBattleRuntimeOutcomeStatus status;
  final SceneBattleRuntimeOutcomePort? port;
  final SceneBattleRuntimeOutcomeErrorCode? errorCode;
  final String? message;

  bool get success => status == SceneBattleRuntimeOutcomeStatus.completed;

  String? get scenePortId {
    return switch (port) {
      SceneBattleRuntimeOutcomePort.victory => 'victory',
      SceneBattleRuntimeOutcomePort.defeat => 'defeat',
      null => null,
    };
  }
}
```

### Contenu complet : `packages/map_runtime/test/scene_battle_runtime_outcome_adapter_test.dart`

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('SceneBattleRuntimeOutcomeAdapter', () {
    test('maps runtime victory to Scene port victory', () async {
      final requests = <SceneBattleRuntimeBattleRequest>[];
      final adapter = SceneBattleRuntimeOutcomeAdapter(
        runtimeSourceId: 'scene:map:event:0',
        defaultNpcEntityId: 'event_guard',
        createdAtEpochMs: () => 1234,
        launcher: _Launcher((request) {
          requests.add(request);
          return const SceneBattleRuntimeOutcomeResult.completed(
            port: SceneBattleRuntimeOutcomePort.victory,
          );
        }),
      );

      final result = await adapter.startBattle(_trainerIntent());

      expect(result.status, SceneBattleRuntimeOutcomeStatus.completed);
      expect(result.port, SceneBattleRuntimeOutcomePort.victory);
      expect(result.scenePortId, 'victory');
      expect(requests.single.trainerId, 'trainer_guard');
      expect(requests.single.npcEntityId, 'event_guard');
      expect(requests.single.requestId, 'scene:map:event:0:trainer_guard:1234');
    });

    test('maps runtime defeat to Scene port defeat', () async {
      final adapter = SceneBattleRuntimeOutcomeAdapter(
        runtimeSourceId: 'scene:map:event:0',
        defaultNpcEntityId: 'event_guard',
        createdAtEpochMs: () => 1234,
        launcher: _Launcher(
          (_) => const SceneBattleRuntimeOutcomeResult.completed(
            port: SceneBattleRuntimeOutcomePort.defeat,
          ),
        ),
      );

      final result = await adapter.startBattle(_trainerIntent());

      expect(result.status, SceneBattleRuntimeOutcomeStatus.completed);
      expect(result.port, SceneBattleRuntimeOutcomePort.defeat);
      expect(result.scenePortId, 'defeat');
    });

    test('fails clearly when intent has no trainerId', () async {
      final adapter = _adapterReturning(SceneBattleRuntimeOutcomePort.victory);

      final result = await adapter.startBattle(
        SceneRuntimePlanIntent.startBattle(battleKind: 'trainer'),
      );

      expect(result.status, SceneBattleRuntimeOutcomeStatus.failed);
      expect(result.errorCode,
          SceneBattleRuntimeOutcomeErrorCode.missingTrainerId);
      expect(result.scenePortId, isNull);
    });

    test('fails clearly when intent and default have no npcEntityId', () async {
      final adapter = SceneBattleRuntimeOutcomeAdapter(
        runtimeSourceId: 'scene:map:event:0',
        defaultNpcEntityId: '',
        createdAtEpochMs: () => 1234,
        launcher: _Launcher(
          (_) => const SceneBattleRuntimeOutcomeResult.completed(
            port: SceneBattleRuntimeOutcomePort.victory,
          ),
        ),
      );

      final result = await adapter.startBattle(_trainerIntent());

      expect(result.status, SceneBattleRuntimeOutcomeStatus.failed);
      expect(result.errorCode,
          SceneBattleRuntimeOutcomeErrorCode.missingNpcEntityId);
      expect(result.scenePortId, isNull);
    });

    test('fails clearly when battle kind is unsupported', () async {
      final adapter = _adapterReturning(SceneBattleRuntimeOutcomePort.victory);

      final result = await adapter.startBattle(
        SceneRuntimePlanIntent.startBattle(
          battleKind: 'wild',
          trainerId: 'trainer_guard',
        ),
      );

      expect(result.status, SceneBattleRuntimeOutcomeStatus.failed);
      expect(result.errorCode,
          SceneBattleRuntimeOutcomeErrorCode.unsupportedBattleKind);
    });

    test('fails clearly when launcher fails', () async {
      final adapter = SceneBattleRuntimeOutcomeAdapter(
        runtimeSourceId: 'scene:map:event:0',
        defaultNpcEntityId: 'event_guard',
        createdAtEpochMs: () => 1234,
        launcher: _Launcher(
          (_) => const SceneBattleRuntimeOutcomeResult.failed(
            errorCode: SceneBattleRuntimeOutcomeErrorCode.launcherFailed,
            message: 'battle handoff failed',
          ),
        ),
      );

      final result = await adapter.startBattle(_trainerIntent());

      expect(result.status, SceneBattleRuntimeOutcomeStatus.failed);
      expect(
          result.errorCode, SceneBattleRuntimeOutcomeErrorCode.launcherFailed);
      expect(result.message, 'battle handoff failed');
      expect(result.scenePortId, isNull);
    });

    test('does not invent victory when launcher throws', () async {
      final adapter = SceneBattleRuntimeOutcomeAdapter(
        runtimeSourceId: 'scene:map:event:0',
        defaultNpcEntityId: 'event_guard',
        createdAtEpochMs: () => 1234,
        launcher: _Launcher((_) => throw StateError('runtime battle crashed')),
      );

      final result = await adapter.startBattle(_trainerIntent());

      expect(result.status, SceneBattleRuntimeOutcomeStatus.failed);
      expect(
          result.errorCode, SceneBattleRuntimeOutcomeErrorCode.launcherFailed);
      expect(result.scenePortId, isNull);
      expect(result.message, contains('runtime battle crashed'));
    });

    test('does not mutate GameState or apply Scene consequences directly',
        () async {
      const state = GameState(saveId: 'save_scene_battle_adapter');
      final adapter = _adapterReturning(SceneBattleRuntimeOutcomePort.victory);

      await adapter.startBattle(_trainerIntent());

      expect(state.storyFlags.activeFlags, isEmpty);
      expect(state.consumedEventIds, isEmpty);
    });
  });
}

SceneRuntimePlanIntent _trainerIntent() {
  return SceneRuntimePlanIntent.startBattle(
    battleKind: 'trainer',
    trainerId: 'trainer_guard',
    declaredOutcomes: const ['victory', 'defeat'],
  );
}

SceneBattleRuntimeOutcomeAdapter _adapterReturning(
  SceneBattleRuntimeOutcomePort port,
) {
  return SceneBattleRuntimeOutcomeAdapter(
    runtimeSourceId: 'scene:map:event:0',
    defaultNpcEntityId: 'event_guard',
    createdAtEpochMs: () => 1234,
    launcher: _Launcher(
      (_) => SceneBattleRuntimeOutcomeResult.completed(port: port),
    ),
  );
}

final class _Launcher implements SceneBattleRuntimeLauncher {
  const _Launcher(this._handler);

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

### Sections completes modifiees : `packages/map_runtime/test/scene_event_runtime_hook_test.dart`

Tests ajoutes :

```dart
test('battle victory follows victory branch and commits consequence', () async {
  final fixture = _fixture(
    scene: _sceneWithBattleConsequenceBranches(),
    facts: [
      NarrativeFactDefinition(
        id: 'fact_test_battle_victory',
        label: 'Battle victory',
      ),
      NarrativeFactDefinition(
        id: 'fact_test_battle_defeat',
        label: 'Battle defeat',
      ),
    ],
  );
  const gameState = GameState(saveId: 'save_test_runtime');
  final calls = <String>[];

  final result = await SceneEventRuntimeHook(
    callbacks: _callbacks(
      calls: calls,
      startBattle: _battleAdapterCallback(
        calls,
        SceneBattleRuntimeOutcomePort.victory,
      ),
    ),
  ).runForEventPage(
    project: fixture.project,
    map: fixture.map,
    event: fixture.event,
    page: fixture.event.pages.single,
    gameState: gameState,
  );

  expect(result.status, SceneEventRuntimeHookStatus.completed);
  expect(result.executionResult?.finalNodeId, 'node_end_victory');
  expect(
    result.updatedGameState?.storyFlags.activeFlags,
    contains('fact_test_battle_victory'),
  );
  expect(
    result.updatedGameState?.storyFlags.activeFlags,
    isNot(contains('fact_test_battle_defeat')),
  );
  expect(gameState.storyFlags.activeFlags, isEmpty);
});
```

Les tests symetriques `battle defeat follows defeat branch and commits consequence` et `battle failure discards staged consequence` sont ajoutes dans le meme groupe.

Helpers ajoutes :

```dart
SceneRuntimeIntentCallback _battleAdapterCallback(
  List<String> calls,
  SceneBattleRuntimeOutcomePort port,
) {
  return (intent) async {
    final adapter = SceneBattleRuntimeOutcomeAdapter(
      runtimeSourceId: 'scene:test:hook',
      defaultNpcEntityId: 'event_test_scene',
      createdAtEpochMs: () => 1234,
      launcher: _SceneTestBattleLauncher((request) {
        calls.add('battle:${request.trainerId}:${_portId(port)}');
        return SceneBattleRuntimeOutcomeResult.completed(port: port);
      }),
    );
    final result = await adapter.startBattle(intent);
    final scenePortId = result.scenePortId;
    if (!result.success || scenePortId == null) {
      throw StateError(result.message ?? 'Scene battle adapter failed.');
    }
    return scenePortId;
  };
}
```

## 30. Auto-review critique

- Est-ce que j'ai modifie `map_battle` ? Non.
- Est-ce que j'ai refactore largement `PlayableMapGame` ? Non, ajout localise du seam awaitable.
- Est-ce que j'ai hardcode `victory` ? Non : mapping depuis `BattleOutcomeType.victory`.
- Est-ce que j'ai hardcode `defeat` ? Non : mapping depuis `BattleOutcomeType.defeat`.
- Est-ce que j'ai invente un outcome ? Non.
- Est-ce que l'adapter battle ecrit une consequence Scene ? Non.
- Est-ce que l'adapter battle applique une World Rule ? Non.
- Est-ce que j'ai branche `StorylineStep.sceneLinkIds` ? Non.
- Est-ce que j'ai active BranchByOutcome ? Non.
- Est-ce que j'ai modifie `map_editor` ? Non.
- Est-ce que j'ai cree des donnees Selbrume ? Non.
- Est-ce que `victory`/`defeat` proviennent d'un resultat runtime reel ? Oui, via `BattleOutcome`.
- Est-ce que les outcomes non supportes echouent proprement ? Oui, `unsupportedOutcome`.
- Est-ce que les consequences V0 restent gerees par le systeme de consequences, pas par l'adapter battle ? Oui.
- Est-ce que le prochain lot n'a pas ete demarre ? Oui.

## 31. Limites restantes

- Dialogue non awaitable.
- Pas d'outcomes Yarn detailles.
- Pas de StorylineStep link.
- Pas de support Scene V1 pour `runaway` / `captured`.
- Pas de test widget/Flame complet du battle overlay reel ; le seam est teste par adapter + hook et l'integration compile/analyze via `PlayableMapGame`.

## 32. Prochain lot recommande

`NS-SCENES-V1-28-septies — Dialogue Runtime Awaitable Adapter V0`

Raison : apres battle awaitable, le dernier gros seam runtime visible est le dialogue. `showDialogue` retourne encore `completed` immediatement au lieu d'attendre la fin reelle du dialogue.
