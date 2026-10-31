import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'scene_periodic_reward_durable_host_test.dart' show availabilityScene;

void main() {
  final reference = PeriodicRewardReference(sceneId: 'puzzle', nodeId: 'claim', rewardId: 'tree');
  final source = SceneConditionSource.periodicRewardAvailable(reference: reference, expectedValue: true);
  for (final expected in [false, true]) {
    test('unresolved reference stays unavailable expected=$expected', () {
      final context = RuntimePeriodicRewardContext(civilNow: () => DateTime(2026, 10, 31));
      final source = SceneConditionSource.periodicRewardAvailable(reference: reference, expectedValue: expected);
      for (final scenes in [<SceneAsset>[], [availabilityScene(), availabilityScene()]]) {
        expect(() => context.evaluateScene(source: source, gameState: const GameState(saveId: 'test'), lookupScenes: (_) => scenes), throwsA(isA<SceneRuntimeConditionUnavailable>()));
      }
    });
  }
  test('calendar view advances without mutating source or repeating allocations', () {
    var now = DateTime(2026, 10, 30, 23, 59);
    final context = RuntimePeriodicRewardContext(civilNow: () => now);
    const state = GameState(saveId: 'test');
    final first = context.observe(state);
    expect(state.gameplayCalendarState.isInitialized, isFalse);
    expect(first.gameplayCalendarState.observedLocalDay, '2026-10-30');
    expect(context.observe(state), same(first));
    now = now.add(const Duration(minutes: 2));
    expect(context.refresh(), isTrue);
    final tomorrow = context.observe(state);
    expect(tomorrow.gameplayCalendarState.observedLocalDay, '2026-10-31');
    expect(context.observe(state), same(tomorrow));
    expect(context.refresh(), isFalse);
  });
  test('calendar overflow is an unavailable derived view, never an unhandled render error', () {
    final context = RuntimePeriodicRewardContext(civilNow: () => DateTime(2026, 10, 31));
    final state = GameState(saveId: 'test', gameplayCalendarState: GameplayCalendarState(observedLocalDay: '2026-10-30', dayRevision: GameplayCalendarState.maximumRevision));
    expect(() => context.observe(state), returnsNormally);
    expect(() => context.evaluateScene(source: source, gameState: state, lookupScenes: (_) => [availabilityScene()]), throwsA(isA<SceneRuntimeConditionUnavailable>()));
    expect(state.gameplayCalendarState.dayRevision, GameplayCalendarState.maximumRevision);
  });
}
