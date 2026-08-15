import '../../pokemon_battle_rules.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../rng/battle_rng_streams.dart';
import 'battle_action.dart';

final class PsdkBattleActionOrderingResult {
  const PsdkBattleActionOrderingResult({
    required this.actions,
    required this.rng,
  });

  final List<PsdkBattleAction> actions;
  final BattleRngStreams rng;
}

final class PsdkBattleActionOrdering {
  const PsdkBattleActionOrdering();

  PsdkBattleActionOrderingResult order({
    required List<PsdkBattleAction> actions,
    required BattleRngStreams rng,
    required PokemonBattleRules rules,
    bool trickRoom = false,
  }) {
    final indexed = <({int index, PsdkBattleAction action})>[
      for (var index = 0; index < actions.length; index += 1)
        (index: index, action: actions[index]),
    ];

    var nextRng = rng;
    final tieOrder = <PsdkBattleSlotRef, int>{};
    if (indexed.length == 2 &&
        _isExactFightTie(indexed[0].action, indexed[1].action)) {
      final tie = rules.resolvePsdkSpeedTie(rng);
      nextRng = tie.nextRng;
      tieOrder[indexed[0].action.user] = tie.firstActsFirst ? 0 : 1;
      tieOrder[indexed[1].action.user] = tie.firstActsFirst ? 1 : 0;
    }

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

      final leftTieOrder = tieOrder[left.action.user];
      final rightTieOrder = tieOrder[right.action.user];
      if (leftTieOrder != null && rightTieOrder != null) {
        return leftTieOrder.compareTo(rightTieOrder);
      }

      final bank = left.action.user.bank.compareTo(right.action.user.bank);
      if (bank != 0) {
        return bank;
      }
      return left.index.compareTo(right.index);
    });

    return PsdkBattleActionOrderingResult(
      actions: _withAlliedRoundChains(
        indexed.map((entry) => entry.action).toList(growable: false),
      ),
      rng: nextRng,
    );
  }

  bool _isExactFightTie(PsdkBattleAction left, PsdkBattleAction right) {
    return left is PsdkBattleFightAction &&
        right is PsdkBattleFightAction &&
        _bucket(left) == _bucket(right) &&
        _movePriority(left) == _movePriority(right) &&
        _speed(left) == _speed(right);
  }

  List<PsdkBattleAction> _withAlliedRoundChains(
    List<PsdkBattleAction> ordered,
  ) {
    final remaining = List<PsdkBattleAction>.of(ordered);
    final result = <PsdkBattleAction>[];
    while (remaining.isNotEmpty) {
      final action = remaining.removeAt(0);
      result.add(action);
      if (!_isRoundAction(action)) {
        continue;
      }

      final chained = <PsdkBattleAction>[];
      remaining.removeWhere((candidate) {
        if (_isRoundAction(candidate) &&
            candidate.user.bank == action.user.bank) {
          chained.add(candidate);
          return true;
        }
        return false;
      });
      chained.sort((left, right) => _speed(right).compareTo(_speed(left)));
      result.addAll(chained);
    }
    return List<PsdkBattleAction>.unmodifiable(result);
  }

  bool _isRoundAction(PsdkBattleAction action) {
    return switch (action) {
      PsdkBattleFightAction(:final move) =>
        move.battleEngineMethod == 's_round' || move.dbSymbol == 'round',
      _ => false,
    };
  }

  int _bucket(PsdkBattleAction action) {
    return switch (action.kind) {
      PsdkBattleActionKind.highPriorityItem => 80,
      PsdkBattleActionKind.capture => 80,
      PsdkBattleActionKind.flee => 80,
      PsdkBattleActionKind.switchPokemon => 70,
      PsdkBattleActionKind.mega => 60,
      PsdkBattleActionKind.fight => 50,
      PsdkBattleActionKind.item => 40,
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
