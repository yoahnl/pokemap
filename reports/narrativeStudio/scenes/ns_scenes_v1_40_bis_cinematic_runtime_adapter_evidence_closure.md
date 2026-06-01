# NS-SCENES-V1-40-bis — Cinematic Runtime Adapter Evidence Closure

Date : 2026-06-01



## 1. Résumé exécutif

Ce bis clôt le reproche documentaire sur V1-40 : le rapport initial avait été rédigé alors que les nouveaux fichiers étaient encore non trackés, donc `git diff --stat` et `git diff --name-only` ne prouvaient pas leur contenu. Entre-temps, V1-40 est présent dans le commit `b39d596f`; ce rapport prouve donc le contenu des fichiers via lecture directe et les hunks via `git diff b39d596f^ b39d596f`.

Aucun code produit n’est modifié par ce bis. Le seul fichier créé est ce rapport.

## 2. Pourquoi ce bis existe

Le retour de review est techniquement fondé : `git diff` n’inclut pas les fichiers `??`. Un Evidence Pack qui affirme que des fichiers non trackés sont complets dans le diff est insuffisant. Le bis corrige la preuve, pas le runtime.

## 3. Gate 0

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sorties :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
<vide>

git diff --stat
<vide>

git diff --name-only
<vide>

git log --oneline -n 10
b39d596f feat(narrative): add cinematic runtime adapter v0 (NS-SCENES-V1-40)
eadb0052 chore(reports): add missing screenshot for V1-15 wire anchor color code
0fe8fa1f feat(narrative): add cinematic scene builder picker v0 (NS-SCENES-V1-39)
6644def0 feat(narrative): add cinematics library v0 (NS-SCENES-V1-38)
05d631f8 feat(narrative): add cinematic asset core model v0 (NS-SCENES-V1-37)
ba7a91f3 update package_config.json
7c4667a4 feat(runtime): finalize cinematic v1 bridge decision and battle auto-switch
27ae87af chore(repo): ignore and untrack .idea workspace
1bc426a9 feat(runtime): sync gamepads plugin packages and host tests
2db4a2b4 Merge branch 'runtime-battle-bridge-psdk-restart'
```

## 4. Fichiers V1-40 préexistants avant le bis

V1-40 est déjà dans le commit `b39d596f`. Fichiers du commit :

```text
M	packages/map_runtime/lib/map_runtime.dart
A	packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart
A	packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart
M	packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
A	packages/map_runtime/test/scene_cinematic_runtime_awaitable_adapter_test.dart
M	packages/map_runtime/test/scene_event_runtime_hook_test.dart
A	reports/narrativeStudio/scenes/ns_scenes_v1_40_cinematic_runtime_adapter_v0.md
M	reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
M	reports/narrativeStudio/scenes/road_map_scenes.md
```

Stat du commit V1-40 :

```text
 packages/map_runtime/lib/map_runtime.dart          |  11 +
 .../scene_cinematic_runtime_awaitable_adapter.dart | 130 +++++++
 .../scene_cinematic_runtime_awaitable_result.dart  |  53 +++
 .../src/presentation/flame/playable_map_game.dart  |  23 +-
 ...e_cinematic_runtime_awaitable_adapter_test.dart | 265 +++++++++++++
 .../test/scene_event_runtime_hook_test.dart        | 414 ++++++++++++++++++++
 ...ns_scenes_v1_40_cinematic_runtime_adapter_v0.md | 427 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  15 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  19 +-
 9 files changed, 1346 insertions(+), 11 deletions(-)
```

Name-only du commit V1-40 :

```text
packages/map_runtime/lib/map_runtime.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/test/scene_cinematic_runtime_awaitable_adapter_test.dart
packages/map_runtime/test/scene_event_runtime_hook_test.dart
reports/narrativeStudio/scenes/ns_scenes_v1_40_cinematic_runtime_adapter_v0.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 5. Fichier créé par le bis

- `reports/narrativeStudio/scenes/ns_scenes_v1_40_bis_cinematic_runtime_adapter_evidence_closure.md`

## 6. Contenu complet — scene_cinematic_runtime_awaitable_adapter.dart

Chemin : `packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart`

```dart
import 'package:map_core/map_core.dart';

import 'scene_cinematic_runtime_awaitable_result.dart';

abstract interface class SceneCinematicRuntimePlayer {
  Future<SceneCinematicRuntimeAwaitableResult> playCinematic(
    SceneCinematicRuntimeRequest request,
  );
}

final class SceneCinematicRuntimeRequest {
  const SceneCinematicRuntimeRequest({
    required this.requestId,
    required this.createdAtEpochMs,
    required this.cinematicId,
    required this.asset,
  });

  final String requestId;
  final int createdAtEpochMs;
  final String cinematicId;
  final CinematicAsset asset;
}

final class SceneCinematicRuntimeAwaitableAdapter {
  const SceneCinematicRuntimeAwaitableAdapter({
    required this.runtimeSourceId,
    required this.project,
    required this.player,
    this.createdAtEpochMs = _systemNowMs,
  });

  final String runtimeSourceId;
  final ProjectManifest project;
  final SceneCinematicRuntimePlayer player;
  final int Function() createdAtEpochMs;

  Future<SceneCinematicRuntimeAwaitableResult> playCinematic(
    SceneRuntimePlanIntent intent,
  ) async {
    final cinematicId = intent.cinematicId?.trim();
    if (cinematicId == null || cinematicId.isEmpty) {
      return const SceneCinematicRuntimeAwaitableResult.failed(
        errorCode: SceneCinematicRuntimeAwaitableErrorCode.missingCinematicId,
        message: 'Scene cinematic intent is missing cinematicId.',
      );
    }

    final asset = _findCanonicalCinematic(cinematicId);
    if (asset == null) {
      if (_isLegacyScenarioBridge(cinematicId)) {
        return SceneCinematicRuntimeAwaitableResult.legacyBridgeAcknowledged(
          message: 'Scene cinematic "$cinematicId" uses a legacy scenario '
              'bridge; it is not a canonical CinematicAsset.',
        );
      }
      return SceneCinematicRuntimeAwaitableResult.failed(
        errorCode: SceneCinematicRuntimeAwaitableErrorCode.unknownCinematicId,
        message: 'Scene cinematic "$cinematicId" was not found.',
      );
    }

    final now = createdAtEpochMs();
    final request = SceneCinematicRuntimeRequest(
      requestId: '$runtimeSourceId:$cinematicId:$now',
      createdAtEpochMs: now,
      cinematicId: cinematicId,
      asset: asset,
    );

    try {
      return await player.playCinematic(request);
    } catch (error) {
      return SceneCinematicRuntimeAwaitableResult.failed(
        errorCode: SceneCinematicRuntimeAwaitableErrorCode.playerFailed,
        message: 'Scene cinematic player failed: $error',
      );
    }
  }

  CinematicAsset? _findCanonicalCinematic(String cinematicId) {
    for (final cinematic in project.cinematics) {
      if (cinematic.id == cinematicId) {
        return cinematic;
      }
    }
    return null;
  }

  bool _isLegacyScenarioBridge(String cinematicId) {
    for (final contract in buildCinematicPublicContracts(project)) {
      if (contract.id == cinematicId &&
          contract.sourceKind ==
              CinematicPublicContractSourceKind.scenarioBridge) {
        return true;
      }
    }
    return false;
  }
}

final class SceneCinematicRuntimeNoVisualPlayer
    implements SceneCinematicRuntimePlayer {
  const SceneCinematicRuntimeNoVisualPlayer();

  @override
  Future<SceneCinematicRuntimeAwaitableResult> playCinematic(
    SceneCinematicRuntimeRequest request,
  ) async {
    final duration = _estimatedDuration(request.asset.timeline);
    await Future<void>.delayed(duration);
    return const SceneCinematicRuntimeAwaitableResult.completed();
  }
}

Duration _estimatedDuration(CinematicTimeline timeline) {
  var totalMs = 0;
  for (final step in timeline.steps) {
    final durationMs = step.durationMs;
    if (durationMs != null && durationMs > 0) {
      totalMs += durationMs;
    }
  }
  if (totalMs <= 0) {
    return Duration.zero;
  }
  return Duration(milliseconds: totalMs);
}

int _systemNowMs() => DateTime.now().millisecondsSinceEpoch;

```

## 7. Contenu complet — scene_cinematic_runtime_awaitable_result.dart

Chemin : `packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart`

```dart
enum SceneCinematicRuntimeAwaitableStatus {
  completed,
  legacyBridgeAcknowledged,
  failed,
}

enum SceneCinematicRuntimeAwaitableErrorCode {
  missingCinematicId,
  unknownCinematicId,
  playerFailed,
}

final class SceneCinematicRuntimeAwaitableResult {
  const SceneCinematicRuntimeAwaitableResult._({
    required this.status,
    this.errorCode,
    this.message,
  });

  const SceneCinematicRuntimeAwaitableResult.completed()
      : this._(status: SceneCinematicRuntimeAwaitableStatus.completed);

  const SceneCinematicRuntimeAwaitableResult.legacyBridgeAcknowledged({
    required String message,
  }) : this._(
          status: SceneCinematicRuntimeAwaitableStatus.legacyBridgeAcknowledged,
          message: message,
        );

  const SceneCinematicRuntimeAwaitableResult.failed({
    required SceneCinematicRuntimeAwaitableErrorCode errorCode,
    required String message,
  }) : this._(
          status: SceneCinematicRuntimeAwaitableStatus.failed,
          errorCode: errorCode,
          message: message,
        );

  final SceneCinematicRuntimeAwaitableStatus status;
  final SceneCinematicRuntimeAwaitableErrorCode? errorCode;
  final String? message;

  bool get success => status != SceneCinematicRuntimeAwaitableStatus.failed;

  String? get scenePortId {
    return switch (status) {
      SceneCinematicRuntimeAwaitableStatus.completed => 'completed',
      SceneCinematicRuntimeAwaitableStatus.legacyBridgeAcknowledged =>
        'completed',
      SceneCinematicRuntimeAwaitableStatus.failed => null,
    };
  }
}

```

## 8. Contenu complet — scene_cinematic_runtime_awaitable_adapter_test.dart

Chemin : `packages/map_runtime/test/scene_cinematic_runtime_awaitable_adapter_test.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('SceneCinematicRuntimeAwaitableAdapter', () {
    test('resolves canonical CinematicAsset and waits for player completion',
        () async {
      final cinematic = _cinematic(
        id: 'cinematic_intro',
        title: 'Intro reveal',
      );
      final project = _project(cinematics: [cinematic]);
      final completer = Completer<SceneCinematicRuntimeAwaitableResult>();
      final requests = <SceneCinematicRuntimeRequest>[];
      final adapter = SceneCinematicRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map:event:0',
        project: project,
        createdAtEpochMs: () => 1234,
        player: _Player((request) {
          requests.add(request);
          return completer.future;
        }),
      );

      var completed = false;
      final future = adapter
          .playCinematic(
        SceneRuntimePlanIntent.playCinematic(
          cinematicId: ' cinematic_intro ',
        ),
      )
          .then((result) {
        completed = true;
        return result;
      });

      await Future<void>.delayed(Duration.zero);

      expect(completed, isFalse);
      expect(requests, hasLength(1));
      expect(
          requests.single.requestId, 'scene:map:event:0:cinematic_intro:1234');
      expect(requests.single.createdAtEpochMs, 1234);
      expect(requests.single.cinematicId, 'cinematic_intro');
      expect(requests.single.asset, cinematic);

      completer
          .complete(const SceneCinematicRuntimeAwaitableResult.completed());

      final result = await future;

      expect(result.status, SceneCinematicRuntimeAwaitableStatus.completed);
      expect(result.success, isTrue);
      expect(result.scenePortId, 'completed');
      expect(completed, isTrue);
    });

    test('passes empty timelines to the player deterministically', () async {
      final cinematic = _cinematic(
        id: 'cinematic_empty',
        title: 'Empty cinematic',
        timeline: CinematicTimeline(),
      );
      final requests = <SceneCinematicRuntimeRequest>[];
      final adapter = SceneCinematicRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map:event:0',
        project: _project(cinematics: [cinematic]),
        createdAtEpochMs: () => 1234,
        player: _Player((request) {
          requests.add(request);
          return const SceneCinematicRuntimeAwaitableResult.completed();
        }),
      );

      final result = await adapter.playCinematic(
        SceneRuntimePlanIntent.playCinematic(cinematicId: 'cinematic_empty'),
      );

      expect(result.status, SceneCinematicRuntimeAwaitableStatus.completed);
      expect(requests.single.asset.timeline.steps, isEmpty);
      expect(result.scenePortId, 'completed');
    });

    test('propagates controlled player failure without completed port',
        () async {
      final adapter = SceneCinematicRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map:event:0',
        project: _project(cinematics: [_cinematic()]),
        player: _Player((request) {
          return const SceneCinematicRuntimeAwaitableResult.failed(
            errorCode: SceneCinematicRuntimeAwaitableErrorCode.playerFailed,
            message: 'Cinematic player failed.',
          );
        }),
      );

      final result = await adapter.playCinematic(
        SceneRuntimePlanIntent.playCinematic(cinematicId: 'cinematic_intro'),
      );

      expect(result.status, SceneCinematicRuntimeAwaitableStatus.failed);
      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.playerFailed,
      );
      expect(result.scenePortId, isNull);
    });

    test('fails unknown cinematicId without launching the player', () async {
      var launched = false;
      final adapter = SceneCinematicRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map:event:0',
        project: _project(cinematics: [_cinematic()]),
        player: _Player((request) {
          launched = true;
          return const SceneCinematicRuntimeAwaitableResult.completed();
        }),
      );

      final result = await adapter.playCinematic(
        SceneRuntimePlanIntent.playCinematic(cinematicId: 'cinematic_unknown'),
      );

      expect(result.status, SceneCinematicRuntimeAwaitableStatus.failed);
      expect(
        result.errorCode,
        SceneCinematicRuntimeAwaitableErrorCode.unknownCinematicId,
      );
      expect(result.scenePortId, isNull);
      expect(launched, isFalse);
    });

    test(
        'keeps scenarioBridge legacy explicit and does not launch canonical player',
        () async {
      var launched = false;
      final adapter = SceneCinematicRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map:event:0',
        project: _project(
          scenarios: const [
            ScenarioAsset(
              id: 'scenario_cutscene',
              name: 'Bridge Cutscene',
              entryNodeId: 'scenario_start',
              metadata: {'authoring.cutsceneSchema': 'cutscene_studio_v2'},
            ),
          ],
        ),
        player: _Player((request) {
          launched = true;
          return const SceneCinematicRuntimeAwaitableResult.completed();
        }),
      );

      final result = await adapter.playCinematic(
        SceneRuntimePlanIntent.playCinematic(cinematicId: 'scenario_cutscene'),
      );

      expect(
        result.status,
        SceneCinematicRuntimeAwaitableStatus.legacyBridgeAcknowledged,
      );
      expect(result.success, isTrue);
      expect(result.scenePortId, 'completed');
      expect(launched, isFalse);
      expect(result.message, contains('legacy scenario bridge'));
    });

    test('does not mutate GameState or apply Scene consequences directly',
        () async {
      const gameState = GameState(saveId: 'save_cinematic_adapter');
      final before = gameState.toJson();
      final adapter = SceneCinematicRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map:event:0',
        project: _project(cinematics: [_cinematic()]),
        player: _Player((request) {
          return const SceneCinematicRuntimeAwaitableResult.completed();
        }),
      );

      await adapter.playCinematic(
        SceneRuntimePlanIntent.playCinematic(cinematicId: 'cinematic_intro'),
      );

      expect(gameState.toJson(), before);
      final adapterSource = File(
        'lib/src/application/scene_runtime/'
        'scene_cinematic_runtime_awaitable_adapter.dart',
      ).readAsStringSync();
      expect(adapterSource, isNot(contains('SceneConsequenceRuntimeWriter')));
      expect(adapterSource, isNot(contains('GameState')));
      expect(adapterSource, isNot(contains('setFact')));
      expect(adapterSource, isNot(contains('markEventConsumed')));
      expect(adapterSource, isNot(contains('startBattle')));
      expect(adapterSource, isNot(contains('giveItem')));
    });

    test('PlayableMapGame wires playCinematic through V1-40 adapter', () {
      final gameSource = File(
        'lib/src/presentation/flame/playable_map_game.dart',
      ).readAsStringSync();

      expect(gameSource, contains('SceneCinematicRuntimeAwaitableAdapter'));
      expect(gameSource, contains('SceneCinematicRuntimeNoVisualPlayer'));
      expect(
        gameSource,
        isNot(contains('[scene_runtime] cinematic bridge acknowledged')),
      );
    });
  });
}

CinematicAsset _cinematic({
  String id = 'cinematic_intro',
  String title = 'Intro cinematic',
  CinematicTimeline? timeline,
}) {
  return CinematicAsset(
    id: id,
    title: title,
    timeline: timeline ??
        CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'step_wait',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 100,
            ),
          ],
        ),
  );
}

ProjectManifest _project({
  List<CinematicAsset> cinematics = const [],
  List<ScenarioAsset> scenarios = const [],
}) {
  return ProjectManifest(
    name: 'Runtime cinematic test project',
    maps: const [],
    tilesets: const [],
    cinematics: cinematics,
    scenarios: scenarios,
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

final class _Player implements SceneCinematicRuntimePlayer {
  const _Player(this._handler);

  final FutureOr<SceneCinematicRuntimeAwaitableResult> Function(
    SceneCinematicRuntimeRequest request,
  ) _handler;

  @override
  Future<SceneCinematicRuntimeAwaitableResult> playCinematic(
    SceneCinematicRuntimeRequest request,
  ) async {
    return _handler(request);
  }
}

```

## 9. Hunks complets — map_runtime.dart

Commande : `git diff b39d596f^ b39d596f -- packages/map_runtime/lib/map_runtime.dart`

```diff
diff --git a/packages/map_runtime/lib/map_runtime.dart b/packages/map_runtime/lib/map_runtime.dart
index 090d273b..d1686ff0 100644
--- a/packages/map_runtime/lib/map_runtime.dart
+++ b/packages/map_runtime/lib/map_runtime.dart
@@ -82,6 +82,17 @@ export 'src/application/scene_runtime/scene_dialogue_runtime_awaitable_result.da
         SceneDialogueRuntimeAwaitableErrorCode,
         SceneDialogueRuntimeAwaitableResult,
         SceneDialogueRuntimeAwaitableStatus;
+export 'src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart'
+    show
+        SceneCinematicRuntimeAwaitableAdapter,
+        SceneCinematicRuntimePlayer,
+        SceneCinematicRuntimeRequest,
+        SceneCinematicRuntimeNoVisualPlayer;
+export 'src/application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart'
+    show
+        SceneCinematicRuntimeAwaitableErrorCode,
+        SceneCinematicRuntimeAwaitableResult,
+        SceneCinematicRuntimeAwaitableStatus;
 export 'src/application/scene_runtime/scene_consequence_runtime_writer.dart'
     show SceneConsequenceRuntimeWriter;
 export 'src/application/scene_runtime/scene_consequence_runtime_write_result.dart'
```

## 10. Hunks complets — playable_map_game.dart

Commande : `git diff b39d596f^ b39d596f -- packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

```diff
diff --git a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
index 99a10ee2..58de03c9 100644
--- a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
@@ -49,6 +49,7 @@ import '../../application/runtime_psdk_battle_setup_mapper.dart';
 import '../../application/runtime_story_branching.dart';
 import '../../application/scene_runtime/scene_battle_runtime_outcome_adapter.dart';
 import '../../application/scene_runtime/scene_battle_runtime_outcome_result.dart';
+import '../../application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart';
 import '../../application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart';
 import '../../application/scene_runtime/scene_dialogue_runtime_awaitable_result.dart';
 import '../../application/scene_runtime/scene_event_runtime_hook.dart';
@@ -5272,14 +5273,22 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
         });
       },
       playCinematic: (intent) {
-        final cinematicId = intent.cinematicId?.trim();
-        if (cinematicId == null || cinematicId.isEmpty) {
-          throw StateError('Scene cinematic intent is missing cinematicId.');
-        }
-        debugPrint(
-          '[scene_runtime] cinematic bridge acknowledged id=$cinematicId',
+        final adapter = SceneCinematicRuntimeAwaitableAdapter(
+          runtimeSourceId: runtimeSourceId,
+          project: _bundle.manifest,
+          player: const SceneCinematicRuntimeNoVisualPlayer(),
         );
-        return 'completed';
+        return adapter.playCinematic(intent).then((result) {
+          final scenePortId = result.scenePortId;
+          if (!result.success || scenePortId == null) {
+            throw StateError(
+              result.message ??
+                  'Scene V1 cinematic handoff failed '
+                      '(cinematicId=${intent.cinematicId}).',
+            );
+          }
+          return scenePortId;
+        });
       },
     );
   }
```

## 11. Hunks complets — scene_event_runtime_hook_test.dart

Commande : `git diff b39d596f^ b39d596f -- packages/map_runtime/test/scene_event_runtime_hook_test.dart`

```diff
diff --git a/packages/map_runtime/test/scene_event_runtime_hook_test.dart b/packages/map_runtime/test/scene_event_runtime_hook_test.dart
index 1ee01997..539358ba 100644
--- a/packages/map_runtime/test/scene_event_runtime_hook_test.dart
+++ b/packages/map_runtime/test/scene_event_runtime_hook_test.dart
@@ -290,6 +290,192 @@ void main() {
       expect(gameState.consumedEventIds, isEmpty);
     });
 
+    test('waits for canonical cinematic before committing following setFact',
+        () async {
+      final fixture = _fixture(
+        scene: _sceneWithCinematicThenSetFactConsequence(),
+        facts: [
+          NarrativeFactDefinition(
+            id: 'fact_test_scene_done',
+            label: 'Scene done',
+          ),
+        ],
+        cinematics: [_cinematic()],
+      );
+      const gameState = GameState(saveId: 'save_test_runtime');
+      final cinematicCompleter =
+          Completer<SceneCinematicRuntimeAwaitableResult>();
+      var hookCompleted = false;
+
+      final future = SceneEventRuntimeHook(
+        callbacks: _callbacks(
+          calls: <String>[],
+          playCinematic: _cinematicAdapterCallback(
+            fixture.project,
+            cinematicCompleter.future,
+          ),
+        ),
+      )
+          .runForEventPage(
+        project: fixture.project,
+        map: fixture.map,
+        event: fixture.event,
+        page: fixture.event.pages.single,
+        gameState: gameState,
+      )
+          .then((result) {
+        hookCompleted = true;
+        return result;
+      });
+
+      await Future<void>.delayed(Duration.zero);
+
+      expect(hookCompleted, isFalse);
+      expect(gameState.storyFlags.activeFlags, isEmpty);
+
+      cinematicCompleter.complete(
+        const SceneCinematicRuntimeAwaitableResult.completed(),
+      );
+
+      final result = await future;
+
+      expect(result.status, SceneEventRuntimeHookStatus.completed);
+      expect(
+        result.updatedGameState?.storyFlags.activeFlags,
+        contains('fact_test_scene_done'),
+      );
+      expect(gameState.storyFlags.activeFlags, isEmpty);
+    });
+
+    test(
+        'waits for canonical cinematic before committing following '
+        'markEventConsumed', () async {
+      final fixture = _fixture(
+        scene: _sceneWithCinematicThenMarkEventConsumedConsequence(),
+        cinematics: [_cinematic()],
+      );
+      const gameState = GameState(saveId: 'save_test_runtime');
+      final cinematicCompleter =
+          Completer<SceneCinematicRuntimeAwaitableResult>();
+      var hookCompleted = false;
+
+      final future = SceneEventRuntimeHook(
+        callbacks: _callbacks(
+          calls: <String>[],
+          playCinematic: _cinematicAdapterCallback(
+            fixture.project,
+            cinematicCompleter.future,
+          ),
+        ),
+      )
+          .runForEventPage(
+        project: fixture.project,
+        map: fixture.map,
+        event: fixture.event,
+        page: fixture.event.pages.single,
+        gameState: gameState,
+      )
+          .then((result) {
+        hookCompleted = true;
+        return result;
+      });
+
+      await Future<void>.delayed(Duration.zero);
+
+      expect(hookCompleted, isFalse);
+      expect(gameState.consumedEventIds, isEmpty);
+
+      cinematicCompleter.complete(
+        const SceneCinematicRuntimeAwaitableResult.completed(),
+      );
+
+      final result = await future;
+
+      expect(result.status, SceneEventRuntimeHookStatus.completed);
+      expect(
+        result.updatedGameState?.consumedEventIds,
+        contains('event_test_scene'),
+      );
+      expect(gameState.consumedEventIds, isEmpty);
+    });
+
+    test('cinematic failure discards staged consequence', () async {
+      final fixture = _fixture(
+        scene: _sceneWithSetFactConsequenceThenCinematic(),
+        facts: [
+          NarrativeFactDefinition(
+            id: 'fact_test_scene_done',
+            label: 'Scene done',
+          ),
+        ],
+        cinematics: [_cinematic()],
+      );
+      const gameState = GameState(saveId: 'save_test_runtime');
+
+      final result = await SceneEventRuntimeHook(
+        callbacks: _callbacks(
+          calls: <String>[],
+          playCinematic: _cinematicAdapterCallback(
+            fixture.project,
+            Future.value(
+              const SceneCinematicRuntimeAwaitableResult.failed(
+                errorCode: SceneCinematicRuntimeAwaitableErrorCode.playerFailed,
+                message: 'Cinematic player failed.',
+              ),
+            ),
+          ),
+        ),
+      ).runForEventPage(
+        project: fixture.project,
+        map: fixture.map,
+        event: fixture.event,
+        page: fixture.event.pages.single,
+        gameState: gameState,
+      );
+
+      expect(result.status, SceneEventRuntimeHookStatus.failed);
+      expect(
+        result.errorCode,
+        SceneEventRuntimeHookErrorCode.sceneExecutionFailed,
+      );
+      expect(result.updatedGameState, isNull);
+      expect(result.consequenceWriteResult, isNull);
+      expect(gameState.storyFlags.activeFlags, isEmpty);
+    });
+
+    test('unknown cinematic blocks without partial writes', () async {
+      final fixture = _fixture(
+        scene: _sceneWithSetFactConsequenceThenUnknownCinematic(),
+        facts: [
+          NarrativeFactDefinition(
+            id: 'fact_test_scene_done',
+            label: 'Scene done',
+          ),
+        ],
+      );
+      const gameState = GameState(saveId: 'save_test_runtime');
+
+      final result = await SceneEventRuntimeHook(
+        callbacks: _callbacks(calls: <String>[]),
+      ).runForEventPage(
+        project: fixture.project,
+        map: fixture.map,
+        event: fixture.event,
+        page: fixture.event.pages.single,
+        gameState: gameState,
+      );
+
+      expect(result.status, SceneEventRuntimeHookStatus.failed);
+      expect(
+        result.errorCode,
+        SceneEventRuntimeHookErrorCode.sceneTargetDiagnosticsFailed,
+      );
+      expect(result.executionResult, isNull);
+      expect(result.updatedGameState, isNull);
+      expect(result.consequenceWriteResult, isNull);
+      expect(gameState.storyFlags.activeFlags, isEmpty);
+    });
+
     test('battle victory follows victory branch and commits consequence',
         () async {
       final fixture = _fixture(
@@ -667,6 +853,26 @@ SceneRuntimeIntentCallback _dialogueAdapterCallback(
   };
 }
 
+SceneRuntimeIntentCallback _cinematicAdapterCallback(
+  ProjectManifest project,
+  Future<SceneCinematicRuntimeAwaitableResult> result,
+) {
+  return (intent) async {
+    final adapter = SceneCinematicRuntimeAwaitableAdapter(
+      runtimeSourceId: 'scene:test:hook',
+      project: project,
+      createdAtEpochMs: () => 1234,
+      player: _SceneTestCinematicPlayer((request) => result),
+    );
+    final cinematicResult = await adapter.playCinematic(intent);
+    final scenePortId = cinematicResult.scenePortId;
+    if (!cinematicResult.success || scenePortId == null) {
+      throw StateError(cinematicResult.message ?? 'Scene cinematic failed.');
+    }
+    return scenePortId;
+  };
+}
+
 String _portId(SceneBattleRuntimeOutcomePort port) {
   return switch (port) {
     SceneBattleRuntimeOutcomePort.victory => 'victory',
@@ -678,6 +884,7 @@ _RuntimeSceneFixture _fixture({
   bool withSceneTarget = true,
   SceneAsset? scene,
   List<NarrativeFactDefinition> facts = const [],
+  List<CinematicAsset> cinematics = const [],
 }) {
   final resolvedScene = scene ?? _scene();
   final project = ProjectManifest(
@@ -708,6 +915,7 @@ _RuntimeSceneFixture _fixture({
       ),
     ],
     facts: facts,
+    cinematics: cinematics,
     scenes: [resolvedScene],
     surfaceCatalog: const ProjectSurfaceCatalog.empty(),
   );
@@ -879,6 +1087,132 @@ SceneAsset _sceneWithMarkEventConsumedConsequence() {
   );
 }
 
+SceneAsset _sceneWithCinematicThenSetFactConsequence() {
+  return _cinematicThenActionScene(
+    payload: SceneActionPayload.consequence(
+      SceneConsequence.setFact(
+        factId: 'fact_test_scene_done',
+        value: true,
+      ),
+    ),
+  );
+}
+
+SceneAsset _sceneWithCinematicThenMarkEventConsumedConsequence() {
+  return _cinematicThenActionScene(
+    payload: SceneActionPayload.consequence(
+      SceneConsequence.markEventConsumed(
+        mapId: 'map_test_runtime',
+        eventId: 'event_test_scene',
+      ),
+    ),
+  );
+}
+
+SceneAsset _sceneWithSetFactConsequenceThenCinematic() {
+  return SceneAsset(
+    id: 'scene_test_runtime',
+    name: 'Runtime Hook Consequence Then Cinematic Scene',
+    graph: SceneGraph(
+      startNodeId: 'node_start',
+      nodes: [
+        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
+        SceneNode(
+          id: 'node_action',
+          kind: SceneNodeKind.action,
+          payload: SceneActionPayload.consequence(
+            SceneConsequence.setFact(
+              factId: 'fact_test_scene_done',
+              value: true,
+            ),
+          ),
+        ),
+        SceneNode(
+          id: 'node_cinematic',
+          kind: SceneNodeKind.cinematic,
+          payload: SceneCinematicPayload(cinematicId: 'cinematic_intro'),
+        ),
+        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
+      ],
+      edges: [
+        SceneEdge(
+          id: 'edge_start_action',
+          fromNodeId: 'node_start',
+          fromPortId: 'completed',
+          toNodeId: 'node_action',
+          kind: SceneEdgeKind.defaultFlow,
+        ),
+        SceneEdge(
+          id: 'edge_action_cinematic',
+          fromNodeId: 'node_action',
+          fromPortId: 'completed',
+          toNodeId: 'node_cinematic',
+          kind: SceneEdgeKind.actionCompleted,
+        ),
+        SceneEdge(
+          id: 'edge_cinematic_end',
+          fromNodeId: 'node_cinematic',
+          fromPortId: 'completed',
+          toNodeId: 'node_end',
+          kind: SceneEdgeKind.cinematicCompleted,
+        ),
+      ],
+    ),
+  );
+}
+
+SceneAsset _sceneWithSetFactConsequenceThenUnknownCinematic() {
+  return SceneAsset(
+    id: 'scene_test_runtime',
+    name: 'Runtime Hook Consequence Then Unknown Cinematic Scene',
+    graph: SceneGraph(
+      startNodeId: 'node_start',
+      nodes: [
+        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
+        SceneNode(
+          id: 'node_action',
+          kind: SceneNodeKind.action,
+          payload: SceneActionPayload.consequence(
+            SceneConsequence.setFact(
+              factId: 'fact_test_scene_done',
+              value: true,
+            ),
+          ),
+        ),
+        SceneNode(
+          id: 'node_cinematic',
+          kind: SceneNodeKind.cinematic,
+          payload: SceneCinematicPayload(cinematicId: 'cinematic_unknown'),
+        ),
+        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
+      ],
+      edges: [
+        SceneEdge(
+          id: 'edge_start_action',
+          fromNodeId: 'node_start',
+          fromPortId: 'completed',
+          toNodeId: 'node_action',
+          kind: SceneEdgeKind.defaultFlow,
+        ),
+        SceneEdge(
+          id: 'edge_action_cinematic',
+          fromNodeId: 'node_action',
+          fromPortId: 'completed',
+          toNodeId: 'node_cinematic',
+          kind: SceneEdgeKind.actionCompleted,
+        ),
+        SceneEdge(
+          id: 'edge_cinematic_end',
+          fromNodeId: 'node_cinematic',
+          fromPortId: 'completed',
+          toNodeId: 'node_end',
+          kind: SceneEdgeKind.cinematicCompleted,
+        ),
+      ],
+    ),
+  );
+}
+
 SceneAsset _sceneWithSetFactConsequenceThenDialogue() {
   return SceneAsset(
     id: 'scene_test_runtime',
@@ -931,6 +1265,71 @@ SceneAsset _sceneWithSetFactConsequenceThenDialogue() {
   );
 }
 
+SceneAsset _cinematicThenActionScene({
+  required SceneActionPayload payload,
+}) {
+  return SceneAsset(
+    id: 'scene_test_runtime',
+    name: 'Runtime Hook Cinematic Then Consequence Scene',
+    graph: SceneGraph(
+      startNodeId: 'node_start',
+      nodes: [
+        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
+        SceneNode(
+          id: 'node_cinematic',
+          kind: SceneNodeKind.cinematic,
+          payload: SceneCinematicPayload(cinematicId: 'cinematic_intro'),
+        ),
+        SceneNode(
+          id: 'node_action',
+          kind: SceneNodeKind.action,
+          payload: payload,
+        ),
+        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
+      ],
+      edges: [
+        SceneEdge(
+          id: 'edge_start_cinematic',
+          fromNodeId: 'node_start',
+          fromPortId: 'completed',
+          toNodeId: 'node_cinematic',
+          kind: SceneEdgeKind.defaultFlow,
+        ),
+        SceneEdge(
+          id: 'edge_cinematic_action',
+          fromNodeId: 'node_cinematic',
+          fromPortId: 'completed',
+          toNodeId: 'node_action',
+          kind: SceneEdgeKind.cinematicCompleted,
+        ),
+        SceneEdge(
+          id: 'edge_action_end',
+          fromNodeId: 'node_action',
+          fromPortId: 'completed',
+          toNodeId: 'node_end',
+          kind: SceneEdgeKind.actionCompleted,
+        ),
+      ],
+    ),
+  );
+}
+
+CinematicAsset _cinematic() {
+  return CinematicAsset(
+    id: 'cinematic_intro',
+    title: 'Intro cinematic',
+    timeline: CinematicTimeline(
+      steps: [
+        CinematicTimelineStep(
+          id: 'step_wait',
+          kind: CinematicTimelineStepKind.wait,
+          durationMs: 100,
+        ),
+      ],
+    ),
+  );
+}
+
 SceneAsset _sceneWithSetFactConsequenceThenBattle() {
   return SceneAsset(
     id: 'scene_test_runtime',
@@ -1146,3 +1545,18 @@ final class _SceneTestDialogueLauncher implements SceneDialogueRuntimeLauncher {
     return _handler(request);
   }
 }
+
+final class _SceneTestCinematicPlayer implements SceneCinematicRuntimePlayer {
+  const _SceneTestCinematicPlayer(this._handler);
+
+  final FutureOr<SceneCinematicRuntimeAwaitableResult> Function(
+    SceneCinematicRuntimeRequest request,
+  ) _handler;
+
+  @override
+  Future<SceneCinematicRuntimeAwaitableResult> playCinematic(
+    SceneCinematicRuntimeRequest request,
+  ) async {
+    return _handler(request);
+  }
+}
```

## 12. Hunks complets — road_map_scenes.md

Commande : `git diff b39d596f^ b39d596f -- reports/narrativeStudio/scenes/road_map_scenes.md`

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 9ef1a479..7c1b6152 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -94,14 +94,15 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-37 — CinematicAsset Core Model V0 | DONE | Modele core `CinematicAsset` dedie, timeline lineaire V0, `ProjectManifest.cinematics`, operations authoring, diagnostics, contrats publics canoniques + bridge scenarioBridge legacy, tests/analyze core. |
 | NS-SCENES-V1-38 — Cinematics Library V0 | DONE | Library Narrative Studio pour `CinematicAsset` canoniques : read model pur, liste/selection, metadata authoring, diagnostics/usages, bridge legacy explicite et overview aligne, sans Builder V2 ni runtime cinematic. |
 | NS-SCENES-V1-39 — Cinematic Scene Builder Picker V0 | DONE | Scene Builder peut ajouter/editer un `CinematicNode` via picker `CinematicAsset` canonique, exposer/connecter `cinematic.completed`, afficher details/diagnostics et signaler les bridges legacy sans les promouvoir. |
+| NS-SCENES-V1-40 — Cinematic Runtime Adapter V0 | DONE | Runtime Scene V1 : `playCinematic(cinematicId)` resout un `CinematicAsset` canonique, passe par un adapter awaitable/player V0, attend la completion reelle, retourne `completed`, preserve les bridges legacy explicites et bloque les refs inconnues sans commit partiel. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-40 — Cinematic Runtime Adapter V0`
+`NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract`
 
-Raison : V1-39 permet maintenant au Scene Builder de referencer un `CinematicAsset` canonique reel. Le prochain verrou logique est de remplacer l'ack bridge par un adapter runtime V0 controle qui attend une cinematic canonique et retourne `completed` proprement.
+Raison : V1-40 ferme le trou runtime awaitable. Le prochain verrou est de cadrer le vrai playback/builder cinematic sans transformer `CinematicAsset` en `ScenarioAsset`, sans timeline editor trop large et sans effets gameplay dans la cinematic.
 
-Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Selbrume Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0.
+Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Selbrume Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract.
 
 Note : l'overview n'affiche plus `Facts — necessite un modele`; Facts et Regles du monde pointent maintenant vers des workspaces actifs.
 
@@ -227,6 +228,18 @@ Limites : pas de Builder V2, pas de timeline editor, pas de runtime cinematic, p
 
 Prochain lot exact : `NS-SCENES-V1-40 — Cinematic Runtime Adapter V0`.
 
+## Mise a jour V1-40
+
+Statut : `NS-SCENES-V1-40 — Cinematic Runtime Adapter V0` est DONE.
+
+Decision : le workflow runtime normal des `CinematicNode` vise uniquement les `CinematicAsset` canoniques de `ProjectManifest.cinematics`. Le bridge `ScenarioAsset` reste legacy explicite et n'est pas promu comme canonical.
+
+Scope realise : adapter awaitable `SceneCinematicRuntimeAwaitableAdapter`, result/request/player V0, player no-visual borne, wiring `PlayableMapGame`, tests de temporalite avec `Completer`, tests no partial writes pour `setFact` et `markEventConsumed`, unknown cinematic bloque sans write.
+
+Limites : pas de Builder V2, pas de timeline editor, pas de playback visuel complet, pas de migration Scenario/Cutscene, pas de branches skipped/failed authorables, pas de donnee Selbrume.
+
+Prochain lot exact : `NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract`.
+
 ## Mise a jour V1-30-bis
 
 Statut : `NS-SCENES-V1-30-bis — Scene Node Deletion UX V0` est DONE.
```

## 13. Hunks complets — road_map_scene_builder_authoring.md

Commande : `git diff b39d596f^ b39d596f -- reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index d774d762..62651d9e 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-40 — Cinematic Runtime Adapter V0
+NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract
 ```
 
 ## Principes
@@ -73,6 +73,7 @@ NS-SCENES-V1-40 — Cinematic Runtime Adapter V0
 | NS-SCENES-V1-37 | CinematicAsset Core Model V0 | core / contract | Ajouter le modele core/storage/read contract minimal de Cinematic V1 lineaire et diagnostiquable. | Pas de Cinematic Builder V2, pas de runtime cinematic avance, pas de migration Cutscene/Scenario automatique, pas de SceneGraph bis. | `CinematicAsset`, `ProjectManifest.cinematics`, public contract, diagnostics/tests core. | DONE : JSON/manifest/read model/diagnostics/scene plan + analyze core. | Sur-modeliser la timeline ; convertir le legacy trop tot ; laisser des actions qui ecrivent le monde. | DONE : modele dedie stable, bridge legacy conserve, Scene peut viser canonical ou bridge explicite. | V1-36. |
 | NS-SCENES-V1-38 | Cinematics Library V0 | editor / read-model | Rendre les CinematicAsset visibles, navigables et diagnostiques dans Narrative Studio. | Pas de Builder V2, pas de timeline editor, pas de runtime cinematic, pas de migration legacy. | workspace/library Cinematics, liste, selection, metadata authoring, diagnostics/usages, overview/sidebar. | DONE : read model pur, Library editor, bridges legacy explicites, tests widget/read model, analyze editor/core cible, visual gate. | Confondre library avec Builder ; reactiver Cutscene Studio comme canonique. | DONE : cinematic assets visibles avant authoring avance, sans runtime ni migration. | V1-37. |
 | NS-SCENES-V1-39 | Cinematic Scene Builder Picker V0 | core / editor | Ajouter/editer un `CinematicNode` depuis un picker `CinematicAsset` canonique et rendre `cinematic.completed` authorable. | Pas de Builder V2, pas de timeline editor, pas de runtime cinematic, pas de migration legacy, pas de bridge selectionnable en workflow normal. | operations Scene cinematic, picker/inspector Scene Builder, diagnostics, tests core/editor, visual gate. | DONE : canonical-only, bridge legacy warning, completed port, tests/analyze, screenshot. | Promouvoir les bridges Scenario comme choix normal ; laisser entrer des cinematicId libres. | DONE : CinematicNode honnete, editable et connectable sans fake ref. | V1-38. |
+| NS-SCENES-V1-40 | Cinematic Runtime Adapter V0 | runtime / integration | Remplacer l'ack cinematic bridge par un adapter awaitable qui resout un `CinematicAsset` canonique, attend une completion reelle et retourne `completed`. | Pas de Builder V2, pas de timeline editor UI, pas de migration ScenarioAsset, pas de playback visuel complet, pas d'effets gameplay depuis cinematic. | adapter cinematic runtime, result/request/player V0, wiring PlayableMapGame, tests hook no partial writes, rapport. | DONE : canonical awaitable, bridge legacy explicite, unknown failed, consequences post-cinematic commit apres completion, tests/analyze. | Continuer a ack immediatement ; traiter scenarioBridge comme canonical ; laisser une cinematic ecrire le monde. | DONE : pont runtime propre Scene -> CinematicAsset -> completed. | V1-39. |
 
 ## Options comparees
 
@@ -643,6 +644,18 @@ Limites : pas de Builder V2, pas de runtime cinematic, pas de timeline editor, p
 
 Prochain lot exact : `NS-SCENES-V1-40 — Cinematic Runtime Adapter V0`.
 
+## Mise a jour V1-40
+
+Statut : `NS-SCENES-V1-40 — Cinematic Runtime Adapter V0` est DONE.
+
+Decision : le Scene runtime passe par un adapter awaitable pour les `CinematicAsset` canoniques. Les bridges `ScenarioAsset` restent legacy explicites et les refs unknown echouent proprement.
+
+Scope realise : `SceneCinematicRuntimeAwaitableAdapter`, `SceneCinematicRuntimeAwaitableResult`, request/player V0, player no-visual borne, callback `PlayableMapGame.playCinematic`, tests de temporalite et no partial writes.
+
+Limites : pas de Builder V2, pas de timeline editor UI, pas de playback visuel complet, pas de migration legacy, pas de gameplay depuis Cinematic.
+
+Prochain lot exact : `NS-SCENES-V1-41 — Cinematic Builder V0 Scope / Runtime Playback Contract`.
+
 ## Selbrume golden slice
 
 Avant le golden slice, il faut au minimum :
```

## 14. Tests relancés

### map_runtime adapter test

Commande : `cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test --reporter=compact test/scene_cinematic_runtime_awaitable_adapter_test.dart`

Exit code : `0`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_cinematic_runtime_awaitable_adapter_test.dart                                                                    
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_cinematic_runtime_awaitable_adapter_test.dart                                                                    
00:01 +0: SceneCinematicRuntimeAwaitableAdapter resolves canonical CinematicAsset and waits for player completion                                                                                      
00:01 +1: SceneCinematicRuntimeAwaitableAdapter resolves canonical CinematicAsset and waits for player completion                                                                                      
00:01 +1: SceneCinematicRuntimeAwaitableAdapter passes empty timelines to the player deterministically                                                                                                 
00:01 +2: SceneCinematicRuntimeAwaitableAdapter passes empty timelines to the player deterministically                                                                                                 
00:01 +2: SceneCinematicRuntimeAwaitableAdapter propagates controlled player failure without completed port                                                                                            
00:01 +3: SceneCinematicRuntimeAwaitableAdapter propagates controlled player failure without completed port                                                                                            
00:01 +3: SceneCinematicRuntimeAwaitableAdapter fails unknown cinematicId without launching the player                                                                                                 
00:01 +4: SceneCinematicRuntimeAwaitableAdapter fails unknown cinematicId without launching the player                                                                                                 
00:01 +4: SceneCinematicRuntimeAwaitableAdapter keeps scenarioBridge legacy explicit and does not launch canonical player                                                                              
00:01 +5: SceneCinematicRuntimeAwaitableAdapter keeps scenarioBridge legacy explicit and does not launch canonical player                                                                              
00:01 +5: SceneCinematicRuntimeAwaitableAdapter does not mutate GameState or apply Scene consequences directly                                                                                         
00:01 +6: SceneCinematicRuntimeAwaitableAdapter does not mutate GameState or apply Scene consequences directly                                                                                         
00:01 +6: SceneCinematicRuntimeAwaitableAdapter PlayableMapGame wires playCinematic through V1-40 adapter                                                                                              
00:01 +7: SceneCinematicRuntimeAwaitableAdapter PlayableMapGame wires playCinematic through V1-40 adapter                                                                                              
00:01 +7: All tests passed!                                                                                                                                                                            
```

### map_runtime hook test

Commande : `cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test --reporter=compact test/scene_event_runtime_hook_test.dart`

Exit code : `0`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_event_runtime_hook_test.dart                                                                                     
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
00:01 +11: SceneEventRuntimeHook waits for canonical cinematic before committing following setFact                                                                                                     
00:01 +12: SceneEventRuntimeHook waits for canonical cinematic before committing following setFact                                                                                                     
00:01 +12: SceneEventRuntimeHook waits for canonical cinematic before committing following markEventConsumed                                                                                           
00:01 +13: SceneEventRuntimeHook waits for canonical cinematic before committing following markEventConsumed                                                                                           
00:01 +13: SceneEventRuntimeHook cinematic failure discards staged consequence                                                                                                                         
00:01 +14: SceneEventRuntimeHook cinematic failure discards staged consequence                                                                                                                         
00:01 +14: SceneEventRuntimeHook unknown cinematic blocks without partial writes                                                                                                                       
00:01 +15: SceneEventRuntimeHook unknown cinematic blocks without partial writes                                                                                                                       
00:01 +15: SceneEventRuntimeHook battle victory follows victory branch and commits consequence                                                                                                         
00:01 +16: SceneEventRuntimeHook battle victory follows victory branch and commits consequence                                                                                                         
00:01 +16: SceneEventRuntimeHook battle defeat follows defeat branch and commits consequence                                                                                                           
00:01 +17: SceneEventRuntimeHook battle defeat follows defeat branch and commits consequence                                                                                                           
00:01 +17: SceneEventRuntimeHook battle failure discards staged consequence                                                                                                                            
00:01 +18: SceneEventRuntimeHook battle failure discards staged consequence                                                                                                                            
00:01 +18: SceneEventRuntimeHook discards staged consequence when later callback fails                                                                                                                 
00:01 +19: SceneEventRuntimeHook discards staged consequence when later callback fails                                                                                                                 
00:01 +19: SceneEventRuntimeHook discards staged consequence when awaitable dialogue fails                                                                                                             
00:01 +20: SceneEventRuntimeHook discards staged consequence when awaitable dialogue fails                                                                                                             
00:01 +20: SceneEventRuntimeHook does not commit consequences when runtime plan fails                                                                                                                  
00:01 +21: SceneEventRuntimeHook does not commit consequences when runtime plan fails                                                                                                                  
00:01 +21: SceneEventRuntimeHook does not apply World Rules or complete StorylineStep directly                                                                                                         
00:01 +22: SceneEventRuntimeHook does not apply World Rules or complete StorylineStep directly                                                                                                         
00:01 +22: SceneEventRuntimeHook reports callback execution failure without mutating state                                                                                                             
00:01 +23: SceneEventRuntimeHook reports callback execution failure without mutating state                                                                                                             
00:01 +23: SceneEventRuntimeHook keeps Scene V1 hook files independent from battle package imports                                                                                                     
00:01 +24: SceneEventRuntimeHook keeps Scene V1 hook files independent from battle package imports                                                                                                     
00:01 +24: All tests passed!                                                                                                                                                                           
```

### map_runtime golden slice smoke

Commande : `cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test --reporter=compact test/scene_runtime_golden_slice_smoke_test.dart`

Exit code : `0`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_runtime_golden_slice_smoke_test.dart                                                                             
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_runtime_golden_slice_smoke_test.dart                                                                             
00:01 +0: Scene runtime golden slice smoke event sceneTarget waits for dialogue then commits victory consequences                                                                                      
00:01 +1: Scene runtime golden slice smoke event sceneTarget waits for dialogue then commits victory consequences                                                                                      
00:01 +1: Scene runtime golden slice smoke event sceneTarget follows defeat branch and commits defeat consequence                                                                                      
00:01 +2: Scene runtime golden slice smoke event sceneTarget follows defeat branch and commits defeat consequence                                                                                      
00:01 +2: Scene runtime golden slice smoke event sceneTarget failure discards staged consequences                                                                                                      
00:01 +3: Scene runtime golden slice smoke event sceneTarget failure discards staged consequences                                                                                                      
00:01 +3: All tests passed!                                                                                                                                                                            
```

### map_core scene runtime plan

Commande : `cd /Users/karim/Project/pokemonProject/packages/map_core && dart test test/scene_runtime_plan_test.dart`

Exit code : `0`

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

### map_core scene project diagnostics

Commande : `cd /Users/karim/Project/pokemonProject/packages/map_core && dart test test/scene_project_diagnostics_test.dart`

Exit code : `0`

```text
00:00 +0: loading test/scene_project_diagnostics_test.dart                                                                                                                                             
00:00 +0: Scene project diagnostics detects missing dialogue reference without parsing Yarn                                                                                                            
00:00 +1: Scene project diagnostics detects missing dialogue reference without parsing Yarn                                                                                                            
00:00 +1: Scene project diagnostics detects missing trainer reference for trainer battle                                                                                                               
00:00 +2: Scene project diagnostics detects missing trainer reference for trainer battle                                                                                                               
00:00 +2: Scene project diagnostics detects missing cinematic public contract as error                                                                                                                 
00:00 +3: Scene project diagnostics detects missing cinematic public contract as error                                                                                                                 
00:00 +3: Scene project diagnostics accepts canonical CinematicAsset references without bridge warning                                                                                                 
00:00 +4: Scene project diagnostics accepts canonical CinematicAsset references without bridge warning                                                                                                 
00:00 +4: Scene project diagnostics keeps scenario bridge references explicit as legacy warnings                                                                                                       
00:00 +5: Scene project diagnostics keeps scenario bridge references explicit as legacy warnings                                                                                                       
00:00 +5: Scene project diagnostics detects missing world rule reference from future world state source                                                                                                
00:00 +6: Scene project diagnostics detects missing world rule reference from future world state source                                                                                                
00:00 +6: Scene project diagnostics does not import runtime or battle packages                                                                                                                         
00:00 +7: Scene project diagnostics does not import runtime or battle packages                                                                                                                         
00:00 +7: All tests passed!                                                                                                                                                                            
```

### map_core linked asset contracts

Commande : `cd /Users/karim/Project/pokemonProject/packages/map_core && dart test test/linked_asset_public_contracts_test.dart`

Exit code : `0`

```text
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
00:00 +5: Linked asset public contracts builds canonical cinematic asset contracts separately from bridges                                                                                             
00:00 +6: Linked asset public contracts builds canonical cinematic asset contracts separately from bridges                                                                                             
00:00 +6: Linked asset public contracts does not expose regular scenarios as cinematic contracts                                                                                                       
00:00 +7: Linked asset public contracts does not expose regular scenarios as cinematic contracts                                                                                                       
00:00 +7: Linked asset public contracts snapshot aggregates contracts and keeps action and branch disabled                                                                                             
00:00 +8: Linked asset public contracts snapshot aggregates contracts and keeps action and branch disabled                                                                                             
00:00 +8: Linked asset public contracts builders are deterministic and do not mutate the manifest                                                                                                      
00:00 +9: Linked asset public contracts builders are deterministic and do not mutate the manifest                                                                                                      
00:00 +9: All tests passed!                                                                                                                                                                            
```

## 15. Analyze relancé

### map_core analyze

Commande : `cd /Users/karim/Project/pokemonProject/packages/map_core && dart analyze`

Exit code : `0`

```text
Analyzing map_core...
No issues found!
```

### map_runtime targeted analyze

Commande : `cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter analyze --no-fatal-infos lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart lib/map_runtime.dart lib/src/presentation/flame/playable_map_game.dart test/scene_cinematic_runtime_awaitable_adapter_test.dart test/scene_event_runtime_hook_test.dart`

Exit code : `0`

```text
Analyzing 6 items...                                            
No issues found! (ran in 1.8s)
```

## 16. Checks anti-scope

### diff hors scope editor/battle/gameplay/examples

Commande : `git diff --name-only -- packages/map_editor packages/map_battle packages/map_gameplay examples`

Exit code : `0`

```text
<vide>
```

### anti Selbrume code V1-40

Commande : `rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart packages/map_runtime/test/scene_cinematic_runtime_awaitable_adapter_test.dart packages/map_runtime/test/scene_event_runtime_hook_test.dart packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart || true`

Exit code : `0`

```text
<vide>
```

### anti gameplay adapter/result

Commande : `rg -n "setFact|markEventConsumed|completeStoryStep|giveItem|givePokemon|teleport|startBattle|startTrainerBattle|WorldRule|worldRule" packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart || true`

Exit code : `0`

```text
<vide>
```

### anti Builder V2 code V1-40

Commande : `rg -n "Cinematic Builder|timeline editor|storyboard|drag.*cinematic|drop.*cinematic|After Effects|keyframe|scrubber|frame-perfect" packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_adapter.dart packages/map_runtime/lib/src/application/scene_runtime/scene_cinematic_runtime_awaitable_result.dart packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/test/scene_cinematic_runtime_awaitable_adapter_test.dart packages/map_runtime/test/scene_event_runtime_hook_test.dart || true`

Exit code : `0`

```text
<vide>
```

## 17. Git diff --check final

Sortie après création du rapport bis :

```text
<vide>
```

## 18. Git diff --stat final

Sortie après création du rapport bis :

```text
<vide>
```

## 19. Git diff --name-only final

Sortie après création du rapport bis :

```text
<vide>
```

## 20. Git status final

Sortie après création du rapport bis :

```text
?? reports/narrativeStudio/scenes/ns_scenes_v1_40_bis_cinematic_runtime_adapter_evidence_closure.md
```

## 21. Auto-review critique

- Est-ce que le bis a modifié du code produit ?
  Réponse : Non. Le script de clôture ne crée que ce rapport.

- Est-ce que les nouveaux fichiers V1-40 sont reproduits intégralement ?
  Réponse : Oui, les trois fichiers créés par V1-40 sont reproduits en contenu complet.

- Est-ce que le rapport prouve vraiment les fichiers non trackés ?
  Réponse : Oui pour la situation initiale du reproche : le rapport ne s’appuie plus sur `git diff` working-tree pour les fichiers nouveaux ; il lit les fichiers directement et prouve aussi le commit V1-40.

- Est-ce que les tests V1-40 passent encore ?
  Réponse : Oui, les commandes listées en section 14 ont exit code 0.

- Est-ce que l’analyze ciblé passe encore ?
  Réponse : Oui, les commandes listées en section 15 ont exit code 0.

- Est-ce qu’aucun fichier map_editor/map_gameplay/map_battle/examples n’est modifié ?
  Réponse : Oui, le check anti-scope sort vide.

- Est-ce qu’aucune donnée Selbrume n’apparaît dans le code ?
  Réponse : Oui, la recherche anti-Selbrume sur les fichiers code V1-40 sort vide.

- Est-ce que l’adapter cinematic reste sans gameplay effect ?
  Réponse : Oui, la recherche anti-gameplay dans adapter/result sort vide.

- Est-ce que V1-40 peut maintenant être commité ?
  Réponse : Oui conceptuellement ; en pratique il l’est déjà dans `b39d596f`. Le bis rend la preuve documentaire commitable séparément.

## 22. Verdict de clôture V1-40

Verdict : V1-40 est clos fonctionnellement et le reproche documentaire est traité par ce rapport bis. Le runtime cinematic canonical attend bien une completion awaitable, les bridges legacy restent explicites, les refs inconnues échouent, et les tests/analyze ciblés repassent. Le seul travail restant est de commiter ce rapport bis si l’on veut conserver cette clôture evidence-only dans l’historique.
