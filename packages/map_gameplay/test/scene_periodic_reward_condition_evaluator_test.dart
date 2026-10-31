import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';
import '../../map_core/test/periodic_reward_condition_evaluation_test.dart'
    show rewardReference, rewardScene, rewardState;

void main() {
  test('scene adapter preserves unknown instead of selecting the false branch',
      () {
    for (final expected in [true, false]) {
      final source = SceneConditionSource.periodicRewardAvailable(
          reference: rewardReference(), expectedValue: expected);
      final missing = evaluateScenePeriodicRewardCondition(
          source: source,
          gameState: rewardState(),
          lookupScenes: (_) => const []);
      expect(missing.passed, isFalse);
      expect(missing.unavailable, isTrue);
      final calendar = evaluateScenePeriodicRewardCondition(
          source: source,
          gameState: rewardState(initialized: false),
          lookupScenes: (_) => [rewardScene()]);
      expect(calendar.passed, isFalse);
      expect(calendar.unavailable, isTrue);
      final available = evaluateScenePeriodicRewardCondition(
          source: source,
          gameState: rewardState(),
          lookupScenes: (_) => [rewardScene()]);
      expect(available.passed, expected);
      expect(available.unavailable, isFalse);
      final claimed = evaluateScenePeriodicRewardCondition(
          source: source,
          gameState: rewardState(claimed: true),
          lookupScenes: (_) => [rewardScene()]);
      expect(claimed.passed, !expected);
      expect(claimed.unavailable, isFalse);
    }
  });
}
