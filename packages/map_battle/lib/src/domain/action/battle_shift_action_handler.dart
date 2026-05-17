import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../handler/battle_handler_context.dart';
import '../handler/battle_handler_result.dart';
import 'battle_action.dart';

final class BattleShiftActionHandler {
  const BattleShiftActionHandler();

  BattleHandlerResult shift({
    required BattleHandlerContext context,
    required PsdkBattleShiftAction action,
  }) {
    _validateShift(context: context, action: action);

    final user = context.state.battlerAt(action.user).copyWith(
          hasJustShifted: true,
        );
    final target = context.state.battlerAt(action.target).copyWith(
          hasJustShifted: true,
        );
    final shiftedState = context.state.copyWith(
      combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
        ...context.state.combatants,
        action.user: target,
        action.target: user,
      },
      parties: _replacePartySnapshots(
        state: context.state,
        bank: action.user.bank,
        battlers: <PsdkBattleCombatant>[user, target],
      ),
    );
    return BattleHandlerResult(
      state: shiftedState,
      rng: context.rng,
    );
  }

  void _validateShift({
    required BattleHandlerContext context,
    required PsdkBattleShiftAction action,
  }) {
    if (action.user == action.target) {
      throw ArgumentError.value(
        action.target,
        'target',
        'shift target must be a different active slot',
      );
    }
    if (action.user.bank != action.target.bank) {
      throw ArgumentError.value(
        action.target,
        'target',
        'shift target must be on the same bank',
      );
    }
    if ((action.user.position - action.target.position).abs() != 1) {
      throw ArgumentError.value(
        action.target,
        'target',
        'shift target must be adjacent',
      );
    }
    context.state.battlerAt(action.user);
    context.state.battlerAt(action.target);
  }
}

Map<int, List<PsdkBattleCombatant>> _replacePartySnapshots({
  required PsdkBattleState state,
  required int bank,
  required List<PsdkBattleCombatant> battlers,
}) {
  final party = state.partyForBank(bank);
  if (party.isEmpty) {
    return state.parties;
  }

  final byId = <String, PsdkBattleCombatant>{
    for (final battler in battlers) battler.id: battler,
  };
  return <int, List<PsdkBattleCombatant>>{
    ...state.parties,
    bank: <PsdkBattleCombatant>[
      for (final battler in party) byId[battler.id] ?? battler,
    ],
  };
}
