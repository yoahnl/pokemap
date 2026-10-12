import 'package:map_core/map_core.dart';

bool evaluateSceneBadgeCondition({
  required SceneConditionSource source,
  required GameState gameState,
}) {
  final expected = source.badgeOwnershipExpected;
  if (expected == null) {
    throw ArgumentError.value(source, 'source', 'Invalid badge condition.');
  }
  return gameState.trainerProfile.badgeIds.contains(source.sourceId) ==
      expected;
}
