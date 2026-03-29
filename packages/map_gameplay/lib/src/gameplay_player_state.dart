import 'package:map_core/map_core.dart';

import 'direction.dart';

class GameplayPlayerState {
  const GameplayPlayerState({
    required this.pos,
    required this.facing,
    this.movementMode = MovementMode.walk,
  });

  final GridPos pos;
  final Direction facing;
  final MovementMode movementMode;

  GameplayPlayerState copyWith({
    GridPos? pos,
    Direction? facing,
    MovementMode? movementMode,
  }) {
    return GameplayPlayerState(
      pos: pos ?? this.pos,
      facing: facing ?? this.facing,
      movementMode: movementMode ?? this.movementMode,
    );
  }
}
