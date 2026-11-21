import 'package:map_core/map_core.dart';

import 'runtime_world_rule_projection_hook.dart';

final class RuntimeWorldRuleProjectionCache {
  ProjectManifest? _project;
  GameState? _gameState;
  Object? _rewardSceneContext;
  final _maps = Map<MapData, RuntimeWorldRuleProjectionState>.identity();

  RuntimeWorldRuleProjectionState resolve({
    required ProjectManifest project,
    required GameState gameState,
    required MapData map,
    PeriodicRewardSceneLookup? lookupRewardScenes,
    Object? rewardSceneContext,
  }) {
    final context = rewardSceneContext ?? lookupRewardScenes;
    if (!identical(project, _project) ||
        !_sameProjectionInputs(_gameState, gameState) ||
        !identical(context, _rewardSceneContext)) {
      _maps.clear();
      _project = project;
      _rewardSceneContext = context;
    }
    _gameState = gameState;
    final existing = _maps[map];
    if (existing != null) return existing;
    final resolved = const RuntimeWorldRuleProjectionHook().resolve(
      project: project,
      gameState: gameState,
      map: map,
      lookupRewardScenes: lookupRewardScenes,
    );
    if (_maps.length >= 8) _maps.remove(_maps.keys.first);
    _maps[map] = resolved;
    return resolved;
  }

  bool _sameProjectionInputs(GameState? previous, GameState next) =>
      identical(previous, next) ||
      previous != null &&
          identical(previous.storyFlags, next.storyFlags) &&
          identical(
            previous.narrativeFactRuntimeState,
            next.narrativeFactRuntimeState,
          ) &&
          identical(previous.progression, next.progression) &&
          previous.consumedEventIds == next.consumedEventIds &&
          identical(
            previous.narrativeEventProgress,
            next.narrativeEventProgress,
          ) &&
          identical(
            previous.mapInstanceWorldState,
            next.mapInstanceWorldState,
          ) &&
          previous.gameplayCalendarState == next.gameplayCalendarState &&
          identical(previous.periodicRewardState, next.periodicRewardState);
}
