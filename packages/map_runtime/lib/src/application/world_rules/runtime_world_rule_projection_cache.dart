import 'package:map_core/map_core.dart';

import 'runtime_world_rule_projection_hook.dart';

final class RuntimeWorldRuleProjectionCache {
  ProjectManifest? _project;
  GameState? _gameState;
  final _maps = Map<MapData, RuntimeWorldRuleProjectionState>.identity();

  RuntimeWorldRuleProjectionState resolve({
    required ProjectManifest project,
    required GameState gameState,
    required MapData map,
  }) {
    if (!identical(project, _project) || !identical(gameState, _gameState)) {
      _maps.clear();
      _project = project;
      _gameState = gameState;
    }
    final existing = _maps[map];
    if (existing != null) return existing;
    final resolved = const RuntimeWorldRuleProjectionHook().resolve(
      project: project,
      gameState: gameState,
      map: map,
    );
    if (_maps.length >= 8) _maps.remove(_maps.keys.first);
    _maps[map] = resolved;
    return resolved;
  }
}
