import 'direction.dart';

sealed class GameplayIntent {
  const GameplayIntent();
}

final class MoveIntent extends GameplayIntent {
  const MoveIntent(this.direction);
  final Direction direction;
}

final class InteractIntent extends GameplayIntent {
  const InteractIntent();
}
