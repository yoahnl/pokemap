import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_field.dart';
import '../../psdk/domain/psdk_battle_rng.dart';
import '../../psdk/domain/psdk_battle_setup.dart';

/// Clean-architecture setup accepted by the new [BattleEngine] entry point.
///
/// Lot 4 deliberately wraps the PSDK foundation setup instead of renaming the
/// legacy `BattleSetup` in place. The package already exports a historical
/// `BattleSetup` used by runtime and tests; reusing that public name here would
/// create an ambiguous API and make the migration look safer than it is.
final class BattleEngineSetup {
  BattleEngineSetup.singles({
    required PsdkBattleCombatantSetup player,
    required PsdkBattleCombatantSetup opponent,
    required PsdkBattleRngSeeds rngSeeds,
    PsdkBattleFieldState field = const PsdkBattleFieldState(),
    List<PsdkBattleCombatantSetup> playerReserves =
        const <PsdkBattleCombatantSetup>[],
    List<PsdkBattleCombatantSetup> opponentReserves =
        const <PsdkBattleCombatantSetup>[],
  }) : _psdkSetup = PsdkBattleSetup.singles(
          player: player,
          opponent: opponent,
          rngSeeds: rngSeeds,
          field: field,
          playerReserves: playerReserves,
          opponentReserves: opponentReserves,
        );

  BattleEngineSetup.fromPsdk(PsdkBattleSetup setup) : _psdkSetup = setup {
    if (!setup.isSingles) {
      throw ArgumentError(
        'Lot 4 only exposes the already-supported PSDK singles topology.',
      );
    }
  }

  final PsdkBattleSetup _psdkSetup;

  /// Internal bridge to the current PSDK foundation DTO.
  ///
  /// This getter is intentionally narrow: later lots can replace the wrapped
  /// DTO with richer banks/parties without forcing legacy `BattleSetup` callers
  /// through a breaking rename today.
  PsdkBattleSetup get psdkSetup => _psdkSetup;
}
