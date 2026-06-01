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
