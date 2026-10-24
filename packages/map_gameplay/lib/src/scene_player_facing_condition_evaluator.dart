import 'package:map_core/map_core.dart';

import 'direction.dart';
import 'gameplay_world_state.dart';

bool evaluateScenePlayerFacing({
  required SceneConditionSource source,
  required GameplayWorldState world,
}) =>
    evaluateScenePlayerFacingDirection(
        source: source, actualFacing: world.player.facing);

bool evaluateScenePlayerFacingDirection({
  required SceneConditionSource source,
  required Direction actualFacing,
}) {
  final direction = source.playerFacingDirection;
  if (direction == null) {
    throw ArgumentError('A player facing condition is required.');
  }
  final value = actualFacing == direction.asDirection;
  return switch (source.operator) {
    SceneConditionOperator.isTrue => value,
    SceneConditionOperator.isFalse => !value,
    SceneConditionOperator.equals =>
      throw ArgumentError('A boolean facing operator is required.'),
  };
}
