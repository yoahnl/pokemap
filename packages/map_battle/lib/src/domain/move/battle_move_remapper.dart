import '../../psdk/domain/psdk_battle_state.dart';
import '../battle/battle_slot.dart';
import 'battle_move_data.dart';

/// Rewrites the effective user/targets after accuracy and before immunity.
///
/// Pokemon SDK performs this step in `proceed_battlers_remap`, mostly for
/// effects such as Snatch/Magic Coat that steal or reflect a move after it was
/// selected. The default implementation is intentionally neutral: FIGHT-11
/// establishes the clean-architecture seam without pretending those effects
/// have all been ported yet.
abstract interface class BattleMoveRemapper {
  BattleMoveRemapResult remap(BattleMoveRemapContext context);
}

final class BattleMoveRemapContext {
  BattleMoveRemapContext({
    required this.state,
    required this.turn,
    required this.user,
    required List<BattlePositionRef> targets,
    required this.move,
  }) : targets = List<BattlePositionRef>.unmodifiable(targets);

  final PsdkBattleState state;
  final int turn;
  final BattlePositionRef user;
  final List<BattlePositionRef> targets;
  final BattleMoveDefinition move;
}

final class BattleMoveRemapResult {
  BattleMoveRemapResult({
    required this.user,
    required List<BattlePositionRef> targets,
  }) : targets = List<BattlePositionRef>.unmodifiable(targets);

  final BattlePositionRef user;
  final List<BattlePositionRef> targets;
}

final class NoopBattleMoveRemapper implements BattleMoveRemapper {
  const NoopBattleMoveRemapper();

  @override
  BattleMoveRemapResult remap(BattleMoveRemapContext context) {
    return BattleMoveRemapResult(
      user: context.user,
      targets: context.targets,
    );
  }
}
