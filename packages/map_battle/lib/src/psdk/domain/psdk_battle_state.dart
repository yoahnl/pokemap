import 'psdk_battle_combatant.dart';
import 'psdk_battle_field.dart';
import 'psdk_battle_outcome.dart';
import 'psdk_battle_setup.dart';
import 'psdk_battle_slots.dart';

/// Current observable state for the PSDK lane.
class PsdkBattleState {
  PsdkBattleState({
    required Map<PsdkBattleSlotRef, PsdkBattleCombatant> combatants,
    this.field = const PsdkBattleFieldState(),
    this.outcome,
  }) : _combatants = Map<PsdkBattleSlotRef, PsdkBattleCombatant>.unmodifiable(
          combatants,
        );

  factory PsdkBattleState.fromSetup(PsdkBattleSetup setup) {
    return PsdkBattleState(
      combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
        psdkPlayerSlot: PsdkBattleCombatant.fromSetup(setup.player),
        psdkOpponentSlot: PsdkBattleCombatant.fromSetup(setup.opponent),
      },
      field: setup.field,
    );
  }

  final Map<PsdkBattleSlotRef, PsdkBattleCombatant> _combatants;
  final PsdkBattleFieldState field;
  final PsdkBattleOutcome? outcome;

  /// Immutable observable combatant map.
  ///
  /// The engine itself remains locally mutable, but callers must not be able to
  /// rewrite state snapshots between turns.
  Map<PsdkBattleSlotRef, PsdkBattleCombatant> get combatants =>
      Map<PsdkBattleSlotRef, PsdkBattleCombatant>.unmodifiable(_combatants);

  PsdkBattleCombatant battlerAt(PsdkBattleSlotRef slot) {
    final combatant = _combatants[slot];
    if (combatant == null) {
      throw StateError(
        'No PSDK combatant at bank ${slot.bank}/${slot.position}.',
      );
    }
    return combatant;
  }

  PsdkBattleState replaceBattler(
    PsdkBattleSlotRef slot,
    PsdkBattleCombatant battler,
  ) {
    return copyWith(
      combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
        ..._combatants,
        slot: battler,
      },
    );
  }

  PsdkBattleState updateBattler(
    PsdkBattleSlotRef slot,
    PsdkBattleCombatant Function(PsdkBattleCombatant battler) update,
  ) {
    return replaceBattler(slot, update(battlerAt(slot)));
  }

  PsdkBattleState copyWith({
    Map<PsdkBattleSlotRef, PsdkBattleCombatant>? combatants,
    PsdkBattleFieldState? field,
    PsdkBattleOutcome? outcome,
  }) {
    return PsdkBattleState(
      combatants: combatants ?? this.combatants,
      field: field ?? this.field,
      outcome: outcome ?? this.outcome,
    );
  }
}
