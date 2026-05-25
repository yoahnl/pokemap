import '../rng/battle_rng_streams.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
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

  static List<PsdkBattleAction> deferPendingShellTrapActionToEnd({
    required List<PsdkBattleAction> actions,
    required int currentIndex,
    required PsdkBattleSlotRef user,
  }) {
    final next = List<PsdkBattleAction>.of(actions);
    for (var index = currentIndex + 1; index < next.length; index += 1) {
      final action = next[index];
      if (action is PsdkBattleFightAction &&
          action.user == user &&
          action.move.battleEngineMethod == 's_shell_trap') {
        next
          ..removeAt(index)
          ..add(action);
        break;
      }
    }
    return List<PsdkBattleAction>.unmodifiable(next);
  }
}
