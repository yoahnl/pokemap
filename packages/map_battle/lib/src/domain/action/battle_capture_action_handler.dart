import '../../battle_rng.dart';
import '../../capture_formula.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../battle/battle_context.dart';
import '../battle/battle_slot.dart';
import '../rng/battle_seeded_rng.dart';
import '../rng/battle_rng_streams.dart';
import '../timeline/battle_timeline_event.dart';
import 'battle_action.dart';

final class BattleCaptureActionResult {
  const BattleCaptureActionResult({
    required this.caught,
    required this.nextRng,
    required this.event,
  });

  final bool caught;
  final BattleRngStreams nextRng;
  final BattleCaptureAttemptTimelineEvent event;
}

/// Native clean-engine handler for the FG-049 capture action.
final class BattleCaptureActionHandler {
  const BattleCaptureActionHandler();

  BattleCaptureActionResult attempt({
    required BattleContext context,
    required PsdkBattleCaptureAction action,
    required PsdkBattleSlotRef target,
  }) {
    if (action.user != psdkPlayerSlot) {
      throw StateError('Only the player can submit a capture action.');
    }
    if (context.setup.isTrainerBattle || !context.setup.canCapture) {
      throw StateError('Capture is disabled for this battle.');
    }
    final opponent = context.state.battlerAt(target);
    final catchRate = opponent.catchRate;
    if (catchRate == null || catchRate < 1 || catchRate > 255) {
      throw StateError(
        'Capture-enabled PSDK battles require opponent catchRate within 1..255.',
      );
    }

    // The generic seed is injected by PsdkBattleSetup. Wrapping it in the
    // public immutable BattleRng makes both engines call the exact same pure
    // formula and advance it exactly once.
    final capture = const BattleCaptureFormula().attempt(
      targetCurrentHp: opponent.currentHp,
      targetMaxHp: opponent.maxHp,
      catchRate: catchRate,
      ballId: action.itemId,
      ballRateNumerator: action.rateNumerator,
      ballRateDenominator: action.rateDenominator,
      status: _captureStatus(opponent.majorStatus),
      rng: BattleSeededRng(state: context.rng.generic.seed),
    );
    final next = capture.nextRng;
    if (next is! BattleSeededRng) {
      throw StateError('Capture formula returned an incompatible RNG state.');
    }

    return BattleCaptureActionResult(
      caught: capture.caught,
      nextRng: context.rng.copyWith(
        generic: BattleRngStream(seed: next.state),
      ),
      event: BattleCaptureAttemptTimelineEvent(
        turn: context.turnNumber,
        attemptId: battleCaptureAttemptId(context.turnNumber),
        target: BattlePositionRef(bank: target.bank, position: target.position),
        ballId: action.itemId,
        shakes: capture.caught ? 4 : 0,
        caught: capture.caught,
      ),
    );
  }
}

BattleCaptureStatus _captureStatus(PsdkBattleMajorStatus? status) {
  return switch (status) {
    PsdkBattleMajorStatus.paralysis => BattleCaptureStatus.paralysis,
    PsdkBattleMajorStatus.burn => BattleCaptureStatus.burn,
    PsdkBattleMajorStatus.poison ||
    PsdkBattleMajorStatus.toxic =>
      BattleCaptureStatus.poison,
    PsdkBattleMajorStatus.sleep => BattleCaptureStatus.sleep,
    PsdkBattleMajorStatus.freeze => BattleCaptureStatus.freeze,
    null => BattleCaptureStatus.none,
  };
}
