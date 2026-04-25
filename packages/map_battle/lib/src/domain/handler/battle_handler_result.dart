import '../../psdk/domain/psdk_battle_state.dart';
import '../../psdk/domain/psdk_battle_timeline.dart';
import '../rng/battle_rng_streams.dart';

final class BattleHandlerResult {
  BattleHandlerResult({
    required this.state,
    required this.rng,
    List<PsdkBattleEvent> events = const <PsdkBattleEvent>[],
    this.applied = true,
    this.reason,
    this.amount = 0,
  }) : events = List<PsdkBattleEvent>.unmodifiable(events);

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
  final bool applied;
  final String? reason;
  final int amount;
}
