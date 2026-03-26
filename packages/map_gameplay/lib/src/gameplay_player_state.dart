import 'package:map_core/map_core.dart';

import 'direction.dart';

class GameplayPlayerState {
  const GameplayPlayerState({
    required this.pos,
    required this.facing,
  });

  final GridPos pos;
  final Direction facing;

  GameplayPlayerState copyWith({GridPos? pos, Direction? facing}) {
    return GameplayPlayerState(
      pos: pos ?? this.pos,
      facing: facing ?? this.facing,
    );
  }
}
