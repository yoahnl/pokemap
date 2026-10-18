import 'package:map_core/map_core.dart';

import '../story_flags_manager.dart';

bool evaluateSceneTrainerDefeatedCondition({
  required SceneConditionSource source,
  required GameState gameState,
}) {
  final expected = source.trainerDefeatedExpected;
  if (expected == null) {
    throw ArgumentError.value(
      source,
      'source',
      'Invalid trainer victory condition.',
    );
  }
  return const StoryFlagsManager().isTrainerDefeated(
        gameState,
        source.sourceId,
      ) ==
      expected;
}
