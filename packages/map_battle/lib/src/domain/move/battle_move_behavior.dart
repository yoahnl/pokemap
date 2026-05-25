import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../rng/battle_rng_streams.dart';
import 'battle_move_data.dart';
import 'battle_move_prevention.dart';

final class BattleMoveBehaviorContext {
  const BattleMoveBehaviorContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.user,
    required this.target,
    required this.move,
    this.canFlee = false,
    this.moveSlot,
    this.actionOrder,
    this.isLastActionOfTurn = false,
    this.moveProcedureHooks = BattleMoveProcedureHooks.none,
    this.announcedMoveFor,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final BattleMoveDefinition move;
  final bool canFlee;
  final int? moveSlot;
  final int? actionOrder;
  final bool isLastActionOfTurn;
  final BattleMoveProcedureHooks moveProcedureHooks;
  final BattleAnnouncedMove? Function(PsdkBattleSlotRef battler)?
      announcedMoveFor;
}

final class BattleAnnouncedMove {
  const BattleAnnouncedMove({
    required this.user,
    required this.target,
    required this.moveSlot,
    required this.move,
    this.actionOrder,
  });

  final PsdkBattleSlotRef user;
  final PsdkBattleSlotRef target;
  final int moveSlot;
  final PsdkBattleMoveData move;
  final int? actionOrder;
}

final class BattleMoveBehaviorResolution {
  const BattleMoveBehaviorResolution({
    required this.state,
    required this.rng,
    required this.events,
    this.successful = true,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
  final bool successful;
}

abstract interface class BattleMoveBehavior {
  String get battleEngineMethod;

  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context);
}

abstract interface class BattleMoveUserPreventionBehavior
    implements BattleMoveBehavior {
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  );
}

typedef BattleMoveBehaviorResolver = BattleMoveBehaviorResolution Function(
  BattleMoveBehaviorContext context,
);

final class CallbackBattleMoveBehavior implements BattleMoveBehavior {
  const CallbackBattleMoveBehavior({
    required this.battleEngineMethod,
    required BattleMoveBehaviorResolver resolve,
  }) : _resolve = resolve;

  @override
  final String battleEngineMethod;
  final BattleMoveBehaviorResolver _resolve;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    return _resolve(context);
  }
}
