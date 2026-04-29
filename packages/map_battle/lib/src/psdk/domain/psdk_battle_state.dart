import 'psdk_battle_combatant.dart';
import 'psdk_battle_field.dart';
import 'psdk_battle_outcome.dart';
import 'psdk_battle_setup.dart';
import 'psdk_battle_slots.dart';
import '../../domain/effect/ability/ability_effect.dart';

/// Current observable state for the PSDK lane.
class PsdkBattleState {
  PsdkBattleState({
    required Map<PsdkBattleSlotRef, PsdkBattleCombatant> combatants,
    this.field = const PsdkBattleFieldState(),
    this.outcome,
  }) : _combatants = Map<PsdkBattleSlotRef, PsdkBattleCombatant>.unmodifiable(
          _hydrateCombatantAbilityEffects(combatants),
        );

  factory PsdkBattleState.fromSetup(PsdkBattleSetup setup) {
    return PsdkBattleState(
      combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
        psdkPlayerSlot:
            PsdkBattleCombatant.fromSetup(setup.player).withAbilityEffect(
          psdkPlayerSlot,
        ),
        psdkOpponentSlot:
            PsdkBattleCombatant.fromSetup(setup.opponent).withAbilityEffect(
          psdkOpponentSlot,
        ),
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

  List<PsdkBattleSlotRef> aliveSlots() {
    final slots = <PsdkBattleSlotRef>[
      for (final entry in _combatants.entries)
        if (!entry.value.isFainted) entry.key,
    ];
    slots.sort(_compareSlots);
    return List<PsdkBattleSlotRef>.unmodifiable(slots);
  }

  List<PsdkBattleSlotRef> foesOf(PsdkBattleSlotRef user) {
    return List<PsdkBattleSlotRef>.unmodifiable(
      aliveSlots().where((slot) => slot.bank != user.bank),
    );
  }

  List<PsdkBattleSlotRef> alliesOf(PsdkBattleSlotRef user) {
    return List<PsdkBattleSlotRef>.unmodifiable(
      aliveSlots().where((slot) => slot.bank == user.bank && slot != user),
    );
  }

  List<PsdkBattleSlotRef> adjacentAlliesOf(PsdkBattleSlotRef user) {
    return List<PsdkBattleSlotRef>.unmodifiable(
      alliesOf(user).where(
        (slot) => (slot.position - user.position).abs() <= 1,
      ),
    );
  }

  bool get weatherEffectsSuppressed {
    return _combatants.values.any(
      (battler) =>
          !battler.isFainted &&
          battler.abilityEffects.any(
            (effect) => effect.suppressesWeatherEffects,
          ),
    );
  }

  bool isWeatherEffectActive(PsdkBattleWeatherId id) {
    return !weatherEffectsSuppressed && field.isWeatherActive(id);
  }
}

int _compareSlots(PsdkBattleSlotRef left, PsdkBattleSlotRef right) {
  final bank = left.bank.compareTo(right.bank);
  if (bank != 0) {
    return bank;
  }
  return left.position.compareTo(right.position);
}

Map<PsdkBattleSlotRef, PsdkBattleCombatant> _hydrateCombatantAbilityEffects(
  Map<PsdkBattleSlotRef, PsdkBattleCombatant> combatants,
) {
  return <PsdkBattleSlotRef, PsdkBattleCombatant>{
    for (final entry in combatants.entries)
      entry.key:
          entry.value.withAbilityEffect(entry.key).withItemEffect(entry.key),
  };
}
