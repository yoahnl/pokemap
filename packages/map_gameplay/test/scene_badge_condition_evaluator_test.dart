import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  for (final owned in [false, true]) {
    for (final expected in [false, true]) {
      test(
          'badge condition reads trainer profile owned=$owned expected=$expected',
          () {
        final state = GameState(
          saveId: 'badge',
          trainerProfile: TrainerProfile(
            name: 'Johto',
            badgeIds: owned ? ['mineral'] : [],
          ),
          storyFlags: StoryFlags(activeFlags: owned ? {} : {'mineral'}),
        );
        final source = SceneConditionSource(
          sourceKind: SceneConditionSourceKind.badge,
          sourceId: 'mineral',
          operator: expected
              ? SceneConditionOperator.isTrue
              : SceneConditionOperator.isFalse,
        );
        expect(
          evaluateSceneBadgeCondition(source: source, gameState: state),
          owned == expected,
        );
        expect(
          evaluateSceneBadgeCondition(
            source: source,
            gameState: GameState.fromJson(state.toJson()),
          ),
          owned == expected,
        );
      });
    }
  }

  test('badge condition rejects an unsupported comparison', () {
    expect(
      () => evaluateSceneBadgeCondition(
        source: SceneConditionSource(
          sourceKind: SceneConditionSourceKind.badge,
          sourceId: 'mineral',
          operator: SceneConditionOperator.equals,
          value: 'true',
        ),
        gameState: const GameState(saveId: 'badge'),
      ),
      throwsArgumentError,
    );
  });
}
