import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'player_service_runtime_controller.dart' show runtimeCivilDay;

final class RuntimePeriodicRewardContext {
  RuntimePeriodicRewardContext({DateTime Function()? civilNow})
      : _civilNow = civilNow ?? DateTime.now;

  final DateTime Function() _civilNow;
  final _observed = Map<GameState, GameState>.identity();
  String? _day;

  bool refresh() {
    final day = runtimeCivilDay(_civilNow());
    if (_day == day) return false;
    final changed = _day != null;
    _day = day;
    _observed.clear();
    return changed;
  }

  GameState observe(GameState state) {
    refresh();
    final existing = _observed[state];
    if (existing != null) return existing;
    final GameState observed;
    try {
      observed = observeGameplayCalendar(state, localDay: _day!);
    } on FormatException {
      final unavailable = state.copyWith(gameplayCalendarState: const GameplayCalendarState.empty());
      _observed[state] = unavailable;
      return unavailable;
    }
    if (_observed.length >= 8) _observed.remove(_observed.keys.first);
    _observed[state] = observed;
    return observed;
  }

  String evaluateScene({
    required SceneConditionSource source,
    required GameState gameState,
    required PeriodicRewardSceneLookup lookupScenes,
  }) {
    final result = evaluateScenePeriodicRewardCondition(
      source: source,
      gameState: observe(gameState),
      lookupScenes: lookupScenes,
    );
    if (result.unavailable) {
      final reference = source.rewardReference;
      throw SceneRuntimeConditionUnavailable(
        'La disponibilité de la récompense ${reference?.rewardId ?? source.sourceId} '
        'est indisponible. Vérifiez la scène ${reference?.sceneId ?? "inconnue"}, '
        'son action ${reference?.nodeId ?? "inconnue"} et le calendrier, puis réessayez.',
      );
    }
    return result.passed ? 'true' : 'false';
  }
}
