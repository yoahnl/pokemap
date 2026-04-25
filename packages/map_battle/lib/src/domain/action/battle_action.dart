import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';

enum PsdkBattleActionKind {
  fight,
  switchPokemon,
  item,
  flee,
  mega,
  shift,
  preAttack,
  noAction,
  highPriorityItem,
}

sealed class PsdkBattleAction {
  const PsdkBattleAction({
    required this.kind,
    required this.user,
  });

  final PsdkBattleActionKind kind;
  final PsdkBattleSlotRef user;
}

final class PsdkBattleFightAction extends PsdkBattleAction {
  const PsdkBattleFightAction({
    required PsdkBattleSlotRef user,
    required this.target,
    required this.moveSlot,
    required this.move,
    required this.speed,
  }) : super(kind: PsdkBattleActionKind.fight, user: user);

  final PsdkBattleSlotRef target;
  final int moveSlot;
  final PsdkBattleMoveData move;
  final int speed;
}

final class PsdkBattleSwitchAction extends PsdkBattleAction {
  const PsdkBattleSwitchAction({
    required PsdkBattleSlotRef user,
    required this.partyIndex,
  }) : super(kind: PsdkBattleActionKind.switchPokemon, user: user);

  final int partyIndex;
}

final class PsdkBattleNoAction extends PsdkBattleAction {
  const PsdkBattleNoAction({
    required PsdkBattleSlotRef user,
  }) : super(kind: PsdkBattleActionKind.noAction, user: user);
}
