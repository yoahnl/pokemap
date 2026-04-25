import '../rng/battle_rng_streams.dart';
import 'battle_action.dart';

final class PsdkBattleActionOrdering {
  const PsdkBattleActionOrdering();

  List<PsdkBattleAction> order({
    required List<PsdkBattleAction> actions,
    required BattleRngStreams rng,
    bool trickRoom = false,
  }) {
    final indexed = <({int index, PsdkBattleAction action})>[
      for (var index = 0; index < actions.length; index += 1)
        (index: index, action: actions[index]),
    ];

    indexed.sort((left, right) {
      final bucket = _bucket(right.action).compareTo(_bucket(left.action));
      if (bucket != 0) {
        return bucket;
      }

      final movePriority =
          _movePriority(right.action).compareTo(_movePriority(left.action));
      if (movePriority != 0) {
        return movePriority;
      }

      final speed = trickRoom
          ? _speed(left.action).compareTo(_speed(right.action))
          : _speed(right.action).compareTo(_speed(left.action));
      if (speed != 0) {
        return speed;
      }

      final bank = left.action.user.bank.compareTo(right.action.user.bank);
      if (bank != 0) {
        return bank;
      }
      return left.index.compareTo(right.index);
    });

    return indexed.map((entry) => entry.action).toList(growable: false);
  }

  int _bucket(PsdkBattleAction action) {
    return switch (action.kind) {
      PsdkBattleActionKind.highPriorityItem => 80,
      PsdkBattleActionKind.switchPokemon => 70,
      PsdkBattleActionKind.mega => 60,
      PsdkBattleActionKind.fight => 50,
      PsdkBattleActionKind.item => 40,
      PsdkBattleActionKind.flee => 30,
      PsdkBattleActionKind.shift => 20,
      PsdkBattleActionKind.preAttack => 10,
      PsdkBattleActionKind.noAction => 0,
    };
  }

  int _movePriority(PsdkBattleAction action) {
    return switch (action) {
      PsdkBattleFightAction(:final move) => move.priority,
      _ => 0,
    };
  }

  int _speed(PsdkBattleAction action) {
    return switch (action) {
      PsdkBattleFightAction(:final speed) => speed,
      _ => 0,
    };
  }
}
