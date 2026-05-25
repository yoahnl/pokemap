import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../rng/battle_rng_streams.dart';

final class BattleHandlerContext {
  const BattleHandlerContext({
    required this.state,
    required this.rng,
    required this.turn,
    required this.user,
    this.actionOrder,
    this.targetActionOrder,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int turn;
  final PsdkBattleSlotRef user;
  final int? actionOrder;
  final int? targetActionOrder;
}
