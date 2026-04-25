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
  })  : combatants =
            Map<PsdkBattleSlotRef, PsdkBattleCombatantSetup>.unmodifiable(
          <PsdkBattleSlotRef, PsdkBattleCombatantSetup>{
            psdkPlayerSlot: player,
            psdkOpponentSlot: opponent,
          },
        ),
        isSingles = true;

  final Map<PsdkBattleSlotRef, PsdkBattleCombatantSetup> combatants;
  final PsdkBattleRngSeeds rngSeeds;
  final PsdkBattleFieldState field;
  final bool isSingles;

  PsdkBattleCombatantSetup get player => combatants[psdkPlayerSlot]!;
  PsdkBattleCombatantSetup get opponent => combatants[psdkOpponentSlot]!;
}
