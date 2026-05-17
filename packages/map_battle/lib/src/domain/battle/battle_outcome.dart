import '../../psdk/domain/psdk_battle_outcome.dart';

/// Terminal outcome kinds exposed by the clean battle engine.
///
/// The enum is separate from legacy `BattleOutcomeType` because Lot 4 only
/// supports the PSDK singles foundation. Capture, run and draw outcomes remain
/// legacy/runtime concerns until a later explicit migration lot ports them.
enum BattleEngineOutcomeKind {
  victory,
  defeat,
  fled,
}

/// Public terminal outcome for [BattleEngine].
final class BattleEngineOutcome {
  const BattleEngineOutcome._({
    required this.kind,
    required PsdkBattleOutcome psdkOutcome,
  }) : _psdkOutcome = psdkOutcome;

  factory BattleEngineOutcome.fromPsdk(PsdkBattleOutcome outcome) {
    return BattleEngineOutcome._(
      kind: switch (outcome.kind) {
        PsdkBattleOutcomeKind.victory => BattleEngineOutcomeKind.victory,
        PsdkBattleOutcomeKind.defeat => BattleEngineOutcomeKind.defeat,
        PsdkBattleOutcomeKind.fled => BattleEngineOutcomeKind.fled,
      },
      psdkOutcome: outcome,
    );
  }

  final BattleEngineOutcomeKind kind;
  final PsdkBattleOutcome _psdkOutcome;

  bool get isFinished => true;
  bool get isVictory => kind == BattleEngineOutcomeKind.victory;
  bool get isDefeat => kind == BattleEngineOutcomeKind.defeat;
  bool get isFled => kind == BattleEngineOutcomeKind.fled;

  /// Bridge retained for the existing PSDK facade while it delegates to the
  /// clean runner. Product code should prefer [kind].
  PsdkBattleOutcome get psdkOutcome => _psdkOutcome;
}
