import '../rng/battle_rng_streams.dart';
import 'battle_action.dart';
import 'battle_action_ordering.dart';

final class PsdkBattleActionQueue {
  PsdkBattleActionQueue({
    required List<PsdkBattleAction> actions,
    PsdkBattleActionOrdering ordering = const PsdkBattleActionOrdering(),
  })  : _actions = List<PsdkBattleAction>.unmodifiable(actions),
        _ordering = ordering;

  final List<PsdkBattleAction> _actions;
  final PsdkBattleActionOrdering _ordering;

  List<PsdkBattleAction> get actions =>
      List<PsdkBattleAction>.unmodifiable(_actions);

  List<PsdkBattleAction> ordered({
    required BattleRngStreams rng,
    bool trickRoom = false,
  }) {
    return _ordering.order(
      actions: _actions,
      rng: rng,
      trickRoom: trickRoom,
    );
  }
}
