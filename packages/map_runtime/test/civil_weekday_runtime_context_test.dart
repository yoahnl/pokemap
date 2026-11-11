import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_story/map_story.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test(
    'civil weekday refresh changes Scene and model visibility without saving',
    () {
      var now = DateTime(2026, 11, 5, 23, 59);
      final context = RuntimePeriodicRewardContext(civilNow: () => now);
      const state = GameState(saveId: 'unchanged');
      final before = state.toJson();
      final source = SceneConditionSource.civilWeekday(
        weekday: CivilWeekday.friday,
        expectedValue: true,
      );
      final expression = NarrativeEventConditionExpression.leaf(
        NarrativeEventCondition.civilWeekday(
          weekday: CivilWeekday.friday,
          expectedValue: true,
        ),
      );
      final project = ProjectManifest(
        name: 'Weekday',
        maps: const [],
        tilesets: const [],
      );
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 2, height: 2),
        spatialScene: MapSpatialScene(
          width: 2,
          depth: 2,
          instances: [
            SpatialModelInstance(
              id: 'tree',
              modelId: 'tree',
              position: Model3dVector3.zero,
              visibilityCondition: expression,
            ),
          ],
        ),
      );
      final presentation = PresentationConditionContext(
        project: project,
        map: map,
      );
      final visibility = SpatialModelVisibilityProjection(
        project: project,
        map: map,
      );
      expect(
        SpatialGameplayCapabilities.requiresCivilWeekdayCondition(
          project,
          maps: [map],
        ),
        isTrue,
      );
      String output() => context.evaluateScene(
        source: source,
        gameState: state,
        lookupScenes: (_) =>
            throw StateError('A civil day has no reward dependency'),
      );
      expect(output(), 'false');
      expect(visibility.isPresent(context.observe(state), 'tree'), isFalse);
      expect(
        presentation.evaluate(expression, context.observe(state)).passed,
        isFalse,
      );
      now = DateTime(2026, 11, 6, 0, 1);
      expect(output(), 'true');
      expect(visibility.isPresent(context.observe(state), 'tree'), isTrue);
      expect(context.refresh(), isTrue);
      expect(
        presentation.evaluate(expression, context.observe(state)).passed,
        isTrue,
      );
      expect(context.refresh(), isFalse);
      final fridaySave = context.observe(state).toJson();
      now = DateTime(2026, 11, 7, 0, 1);
      expect(context.refresh(), isTrue);
      expect(output(), 'false');
      expect(visibility.isPresent(context.observe(state), 'tree'), isFalse);
      expect(
        presentation.evaluate(expression, context.observe(state)).passed,
        isFalse,
      );
      expect(state.toJson(), before);
      final resumed = GameState.fromJson(fridaySave);
      final reopened = RuntimePeriodicRewardContext(civilNow: () => now);
      expect(
        reopened.evaluateScene(
          source: source,
          gameState: resumed,
          lookupScenes: (_) => const [],
        ),
        'false',
      );
    },
  );

  test('overflow calendar is unavailable for both weekday expectations', () {
    final context = RuntimePeriodicRewardContext(
      civilNow: () => DateTime(2026, 11, 6),
    );
    final state = GameState(
      saveId: 'save',
      gameplayCalendarState: GameplayCalendarState(
        observedLocalDay: '2026-11-05',
        dayRevision: GameplayCalendarState.maximumRevision,
      ),
    );
    for (final expected in [false, true]) {
      expect(
        () => context.evaluateScene(
          source: SceneConditionSource.civilWeekday(
            weekday: CivilWeekday.friday,
            expectedValue: expected,
          ),
          gameState: state,
          lookupScenes: (_) => const [],
        ),
        throwsA(isA<SceneRuntimeConditionUnavailable>()),
      );
    }
    expect(state.gameplayCalendarState.observedLocalDay, '2026-11-05');
  });
}
