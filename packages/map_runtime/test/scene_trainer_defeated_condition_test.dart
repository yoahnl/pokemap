import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_trainer_defeated_condition.dart';
import 'package:map_runtime/src/spatial/spatial_scene_callbacks.dart';

void main() {
  for (final expected in [true, false]) {
    test(
      'trainer victory uses only the canonical flag and survives reload $expected',
      () {
        final source = SceneConditionSource.trainerDefeated(
          trainerId: 'clair',
          expected: expected,
        );
        var state = const GameState(
          saveId: 'condition-test',
          progression: PlayerProgression(
            storyFlags: ['trainer_defeated:clair'],
          ),
        );
        expect(
          evaluateSceneTrainerDefeatedCondition(
            source: source,
            gameState: state,
          ),
          !expected,
        );
        state = const StoryFlagsManager().markTrainerDefeated(state, 'other');
        expect(
          evaluateSceneTrainerDefeatedCondition(
            source: source,
            gameState: state,
          ),
          !expected,
        );
        state = const StoryFlagsManager().markTrainerDefeated(state, 'clair');
        expect(
          evaluateSceneTrainerDefeatedCondition(
            source: source,
            gameState: state,
          ),
          expected,
        );
        final loaded = GameState.fromJson(state.toJson());
        expect(
          evaluateSceneTrainerDefeatedCondition(
            source: source,
            gameState: loaded,
          ),
          expected,
        );
        expect(loaded.narrativeFactRuntimeState.overridesByFactId, isEmpty);
        expect(
          loaded.storyFlags.activeFlags,
          contains('trainer_defeated:clair'),
        );
        expect(
          evaluateSceneTrainerDefeatedCondition(
            source: source,
            gameState: const StoryFlagsManager().unmarkTrainerDefeated(
              loaded,
              'clair',
            ),
          ),
          !expected,
        );
      },
    );
  }
  test('another condition kind cannot be interpreted as a trainer', () {
    expect(
      () => evaluateSceneTrainerDefeatedCondition(
        source: SceneConditionSource.playerFacing(
          direction: EntityFacing.north,
        ),
        gameState: const GameState(saveId: 'condition-test'),
      ),
      throwsArgumentError,
    );
  });
  test('spatial callback reads the live canonical trainer flag without a shadow fact', () {
    var state = const GameState(saveId: 'condition-test');
    final host = SpatialSceneCallbacks(
      project: const ProjectManifest(name: 'Spatial', maps: [], tilesets: []),
      runtimeSourceId: 'condition-test',
      readGameState: () => state,
      show: (_) async => const SceneDialogueRuntimeAwaitableResult.completed(),
      battle: (_) async => const SceneBattleRuntimeOutcomeResult.completed(
        port: SceneBattleRuntimeOutcomePort.victory,
      ),
      interactive: (_) async => 'completed',
    );
    final source = SceneConditionSource.trainerDefeated(trainerId: 'clair');
    final intent = SceneRuntimePlanIntent.evaluateCondition(source: source);
    expect(host.evaluateCondition(intent), 'false');
    state = const StoryFlagsManager().markTrainerDefeated(state, 'clair');
    expect(host.evaluateCondition(intent), 'true');
    state = GameState.fromJson(state.toJson());
    expect(host.evaluateCondition(intent), 'true');
    state = const StoryFlagsManager().unmarkTrainerDefeated(state, 'clair');
    expect(host.evaluateCondition(intent), 'false');
  });
}
