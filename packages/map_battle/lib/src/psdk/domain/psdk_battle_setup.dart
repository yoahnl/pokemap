import 'psdk_battle_combatant.dart';
import 'psdk_battle_field.dart';
import 'psdk_battle_rng.dart';
import 'psdk_battle_slots.dart';

/// Input setup for the parallel PSDK engine.
///
/// Only singles are accepted in this first tranche. The named constructor is a
/// deliberate guardrail: callers cannot accidentally build a half-supported
/// multi battle and receive misleading events.
class PsdkBattleSetup {
  PsdkBattleSetup.singles({
    required PsdkBattleCombatantSetup player,
    required PsdkBattleCombatantSetup opponent,
    required this.rngSeeds,
    this.field = const PsdkBattleFieldState(),
    this.canFlee = false,
    List<PsdkBattleCombatantSetup> playerReserves =
        const <PsdkBattleCombatantSetup>[],
    List<PsdkBattleCombatantSetup> opponentReserves =
        const <PsdkBattleCombatantSetup>[],
  })  : combatants =
            Map<PsdkBattleSlotRef, PsdkBattleCombatantSetup>.unmodifiable(
          <PsdkBattleSlotRef, PsdkBattleCombatantSetup>{
            psdkPlayerSlot: player,
            psdkOpponentSlot: opponent,
          },
        ),
        parties = Map<int, List<PsdkBattleCombatantSetup>>.unmodifiable(
          <int, List<PsdkBattleCombatantSetup>>{
            psdkPlayerSlot.bank: List<PsdkBattleCombatantSetup>.unmodifiable(
              <PsdkBattleCombatantSetup>[player, ...playerReserves],
            ),
            psdkOpponentSlot.bank: List<PsdkBattleCombatantSetup>.unmodifiable(
              <PsdkBattleCombatantSetup>[opponent, ...opponentReserves],
            ),
          },
        ),
        isSingles = true;

  final Map<PsdkBattleSlotRef, PsdkBattleCombatantSetup> combatants;
  final Map<int, List<PsdkBattleCombatantSetup>> parties;
  final PsdkBattleRngSeeds rngSeeds;
  final PsdkBattleFieldState field;
  final bool canFlee;
  final bool isSingles;

  PsdkBattleCombatantSetup get player => combatants[psdkPlayerSlot]!;
  PsdkBattleCombatantSetup get opponent => combatants[psdkOpponentSlot]!;

  List<PsdkBattleCombatantSetup> partyForBank(int bank) {
    return List<PsdkBattleCombatantSetup>.unmodifiable(
      parties[bank] ?? const <PsdkBattleCombatantSetup>[],
    );
  }
}
