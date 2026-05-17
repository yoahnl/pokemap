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
    Map<int, List<PsdkBattleCombatant>>? parties,
    this.field = const PsdkBattleFieldState(),
    this.outcome,
  })  : _combatants = Map<PsdkBattleSlotRef, PsdkBattleCombatant>.unmodifiable(
          _hydrateCombatantAbilityEffects(combatants),
        ),
        _parties = _hydrateParties(
          combatants: combatants,
          parties: parties,
        );

  factory PsdkBattleState.fromSetup(PsdkBattleSetup setup) {
    final combatants = <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkPlayerSlot: PsdkBattleCombatant.fromSetup(setup.player),
      psdkOpponentSlot: PsdkBattleCombatant.fromSetup(setup.opponent),
    };
    return PsdkBattleState(
      combatants: combatants,
      parties: <int, List<PsdkBattleCombatant>>{
        psdkPlayerSlot.bank: <PsdkBattleCombatant>[
          for (final setup in setup.partyForBank(psdkPlayerSlot.bank))
            PsdkBattleCombatant.fromSetup(setup),
        ],
        psdkOpponentSlot.bank: <PsdkBattleCombatant>[
          for (final setup in setup.partyForBank(psdkOpponentSlot.bank))
            PsdkBattleCombatant.fromSetup(setup),
        ],
      },
      field: setup.field,
    );
  }

  final Map<PsdkBattleSlotRef, PsdkBattleCombatant> _combatants;
  final Map<int, List<PsdkBattleCombatant>> _parties;
  final PsdkBattleFieldState field;
  final PsdkBattleOutcome? outcome;

  /// Immutable observable combatant map.
  ///
  /// The engine itself remains locally mutable, but callers must not be able to
  /// rewrite state snapshots between turns.
  Map<PsdkBattleSlotRef, PsdkBattleCombatant> get combatants =>
      Map<PsdkBattleSlotRef, PsdkBattleCombatant>.unmodifiable(_combatants);

  Map<int, List<PsdkBattleCombatant>> get parties =>
      Map<int, List<PsdkBattleCombatant>>.unmodifiable(
        _parties.map(
          (bank, party) => MapEntry(
            bank,
            List<PsdkBattleCombatant>.unmodifiable(party),
          ),
        ),
      );

  List<PsdkBattleCombatant> partyForBank(int bank) {
    return List<PsdkBattleCombatant>.unmodifiable(
      _parties[bank] ?? const <PsdkBattleCombatant>[],
    );
  }

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
    Map<int, List<PsdkBattleCombatant>>? parties,
    PsdkBattleFieldState? field,
    PsdkBattleOutcome? outcome,
  }) {
    return PsdkBattleState(
      combatants: combatants ?? this.combatants,
      parties: parties ?? this.parties,
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

  List<PsdkBattleSlotRef> adjacentFoesOf(PsdkBattleSlotRef user) {
    return List<PsdkBattleSlotRef>.unmodifiable(
      foesOf(user).where((slot) => _isAdjacent(user, slot)),
    );
  }

  List<PsdkBattleSlotRef> alliesOf(PsdkBattleSlotRef user) {
    return List<PsdkBattleSlotRef>.unmodifiable(
      aliveSlots().where((slot) => slot.bank == user.bank && slot != user),
    );
  }

  List<PsdkBattleSlotRef> adjacentAlliesOf(PsdkBattleSlotRef user) {
    return List<PsdkBattleSlotRef>.unmodifiable(
      alliesOf(user).where((slot) => _isAdjacent(user, slot)),
    );
  }

  List<PsdkBattleSlotRef> adjacentSlotsOf(PsdkBattleSlotRef user) {
    return List<PsdkBattleSlotRef>.unmodifiable(
      aliveSlots().where((slot) => slot != user && _isAdjacent(user, slot)),
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

Map<int, List<PsdkBattleCombatant>> _hydrateParties({
  required Map<PsdkBattleSlotRef, PsdkBattleCombatant> combatants,
  required Map<int, List<PsdkBattleCombatant>>? parties,
}) {
  final source = parties ?? _partiesFromCombatants(combatants);
  return Map<int, List<PsdkBattleCombatant>>.unmodifiable(
    source.map(
      (bank, party) => MapEntry(
        bank,
        List<PsdkBattleCombatant>.unmodifiable(
          party.map((battler) => battler.withItemEffect(_ownerFor(bank))),
        ),
      ),
    ),
  );
}

Map<int, List<PsdkBattleCombatant>> _partiesFromCombatants(
  Map<PsdkBattleSlotRef, PsdkBattleCombatant> combatants,
) {
  final parties = <int, List<PsdkBattleCombatant>>{};
  final entries = combatants.entries.toList()
    ..sort((a, b) => _compareSlots(a.key, b.key));
  for (final entry in entries) {
    parties.putIfAbsent(entry.key.bank, () => <PsdkBattleCombatant>[]).add(
          entry.value,
        );
  }
  return parties;
}

PsdkBattleSlotRef _ownerFor(int bank) {
  return PsdkBattleSlotRef(bank: bank, position: 0);
}

bool _isAdjacent(PsdkBattleSlotRef user, PsdkBattleSlotRef target) {
  return (target.position - user.position).abs() <= 1;
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
