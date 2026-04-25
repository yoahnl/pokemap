import 'battle_move_behavior.dart';

final class BattleMoveRegistry {
  BattleMoveRegistry(Iterable<BattleMoveBehavior> behaviors)
      : _behaviors = Map<String, BattleMoveBehavior>.unmodifiable(
          <String, BattleMoveBehavior>{
            for (final behavior in behaviors)
              behavior.battleEngineMethod: behavior,
          },
        );

  final Map<String, BattleMoveBehavior> _behaviors;

  BattleMoveBehavior resolve(String battleEngineMethod) {
    final behavior = _behaviors[battleEngineMethod];
    if (behavior == null) {
      throw UnsupportedBattleMoveBehavior(battleEngineMethod);
    }
    return behavior;
  }
}

final class UnsupportedBattleMoveBehavior implements Exception {
  const UnsupportedBattleMoveBehavior(this.battleEngineMethod);

  final String battleEngineMethod;

  @override
  String toString() {
    return 'Unsupported Pokemon SDK battleEngineMethod: $battleEngineMethod';
  }
}
