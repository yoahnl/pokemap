import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../application/scene_runtime/scene_battle_runtime_outcome_adapter.dart';
import '../application/scene_runtime/scene_battle_runtime_outcome_result.dart';
import '../application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart';
import '../application/scene_runtime/scene_dialogue_runtime_awaitable_result.dart';
import '../application/scene_runtime/scene_fact_condition_runtime_resolver.dart';
import '../application/scene_runtime/scene_runtime_host_callbacks.dart';

final class SpatialSceneCallbacks
    implements SceneDialogueRuntimeLauncher, SceneBattleRuntimeLauncher {
  const SpatialSceneCallbacks({
    required this.project,
    required this.runtimeSourceId,
    required this.readGameState,
    required this.show,
    required this.battle,
    required this.interactive,
  });

  final ProjectManifest project;
  final String runtimeSourceId;
  final GameState Function() readGameState;
  final Future<SceneDialogueRuntimeAwaitableResult> Function(
      SceneDialogueRuntimeDialogueRequest request) show;
  final Future<SceneBattleRuntimeOutcomeResult> Function(
      SceneBattleRuntimeBattleRequest request) battle;
  final Future<String> Function(SceneRuntimePlanIntent intent) interactive;

  SceneRuntimeHostCallbacks build() => SceneRuntimeHostCallbacks(
        evaluateCondition: evaluateCondition,
        showDialogue: (intent) async {
          final result = await SceneDialogueRuntimeAwaitableAdapter(
                  runtimeSourceId: runtimeSourceId, launcher: this)
              .showDialogue(intent);
          if (!result.success || result.scenePortId == null) {
            throw StateError(result.message ?? 'Spatial dialogue failed.');
          }
          return result.scenePortId!;
        },
        startBattle: (intent) async {
          final result = await SceneBattleRuntimeOutcomeAdapter(
                  runtimeSourceId: runtimeSourceId,
                  defaultNpcEntityId: runtimeSourceId,
                  launcher: this)
              .startBattle(intent);
          if (!result.success || result.scenePortId == null) {
            throw StateError(result.message ?? 'Spatial battle failed.');
          }
          return result.scenePortId!;
        },
        playCinematic: (_) => throw UnsupportedError(
            'Spatial cinematic playback is unavailable.'),
        executeInteractiveCommand: interactive,
      );

  String evaluateCondition(SceneRuntimePlanIntent intent) {
    final source = intent.conditionSource;
    if (source == null) throw StateError('The Scene condition is missing.');
    final state = readGameState();
    if (source.sourceKind == SceneConditionSourceKind.inventoryItem) {
      return evaluateSceneInventoryCondition(source: source, gameState: state)
          ? 'true'
          : 'false';
    }
    if (source.sourceKind == SceneConditionSourceKind.fact) {
      return evaluateCanonicalNarrativeFactSceneCondition(
              source: source,
              gameState: state,
              resolver: NarrativeFactRuntimeResolver.fromFacts(project.facts))
          ? 'true'
          : 'false';
    }
    final value = switch (source.sourceKind) {
      SceneConditionSourceKind.factLikeStoryFlag =>
        state.storyFlags.activeFlags.contains(source.sourceId) ||
            state.progression.storyFlags.contains(source.sourceId),
      SceneConditionSourceKind.storyStepCompletion =>
        state.progression.completedStepIds.contains(source.sourceId),
      SceneConditionSourceKind.consumedEvent =>
        state.consumedEventIds.contains(source.sourceId),
      _ => throw UnsupportedError(
          'Spatial condition ${source.sourceKind.name} is unavailable.'),
    };
    final matched = switch (source.operator) {
      SceneConditionOperator.isTrue => value,
      SceneConditionOperator.isFalse => !value,
      SceneConditionOperator.equals => switch (source.value) {
          'true' || SceneConditionValues.completed => value,
          'false' || SceneConditionValues.notCompleted => !value,
          _ =>
            throw UnsupportedError('The Scene equality value is unsupported.'),
        },
    };
    return matched ? 'true' : 'false';
  }

  @override
  Future<SceneDialogueRuntimeAwaitableResult> showDialogue(
          SceneDialogueRuntimeDialogueRequest request) =>
      show(request);

  @override
  Future<SceneBattleRuntimeOutcomeResult> startTrainerBattle(
          SceneBattleRuntimeBattleRequest request) =>
      battle(request);
}
