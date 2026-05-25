import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_outcome.dart';
import '../../psdk/domain/psdk_battle_setup.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../rng/battle_rng_streams.dart';
import 'battle_outcome.dart';
import 'battle_setup.dart';
import 'battle_topology.dart';

/// Mutable state owned by the clean battle application layer.
///
/// This class is intentionally not a runtime/editor contract. PSDK's Ruby
/// engine mutates a battle scene through many handlers; Lot 4 mirrors that
/// shape internally while keeping all public snapshots immutable.
final class BattleContext {
  BattleContext._({
    required this.setup,
    required this.state,
    required this.rng,
    required this.turnNumber,
  });

  factory BattleContext.fromSetup(BattleEngineSetup setup) {
    final psdkSetup = setup.psdkSetup;
    final initialState = _stateWithInitialOutcome(
      PsdkBattleState.fromSetup(psdkSetup),
    );
    return BattleContext._(
      setup: psdkSetup,
      state: initialState,
      rng: BattleRngStreams.fromPsdkSeeds(psdkSetup.rngSeeds),
      turnNumber: 0,
    );
  }

  final PsdkBattleSetup setup;
  PsdkBattleState state;
  BattleRngStreams rng;
  int turnNumber;

  bool get canBattleContinue => state.outcome == null;

  void beginTurn() {
    turnNumber += 1;
  }

  void applyStateAndRng({
    required PsdkBattleState nextState,
    required BattleRngStreams nextRng,
  }) {
    state = nextState;
    rng = nextRng;
  }

  void restore({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turnNumber,
  }) {
    this.state = state;
    this.rng = rng;
    this.turnNumber = turnNumber;
  }

  void finish(PsdkBattleOutcome outcome) {
    state = state.copyWith(outcome: outcome);
  }

  PsdkBattleOutcome? resolveOutcome() => state.outcome ?? _outcomeFor(state);
}

/// Immutable state returned outside the application layer.
///
/// The wrapped PSDK state is already immutable, but this facade carries the
/// clean engine turn number and maps outcomes to the Lot 4 public vocabulary.
final class BattlePublicState {
  BattlePublicState._({
    required PsdkBattleState state,
    required this.rngSeeds,
    required this.turnNumber,
  }) : _state = state;

  factory BattlePublicState.fromContext(BattleContext context) {
    return BattlePublicState._(
      state: context.state,
      rngSeeds: context.rng.seeds,
      turnNumber: context.turnNumber,
    );
  }

  final PsdkBattleState _state;
  final BattleRngSeeds rngSeeds;
  final int turnNumber;

  BattleEngineOutcome? get outcome {
    final outcome = _state.outcome;
    if (outcome == null) {
      return null;
    }
    return BattleEngineOutcome.fromPsdk(outcome);
  }

  bool get isFinished => outcome != null;

  BattleTopology get topology => BattleTopology.fromPsdkState(_state);

  Map<PsdkBattleSlotRef, PsdkBattleCombatant> get combatants =>
      _state.combatants;

  PsdkBattleCombatant battlerAt(PsdkBattleSlotRef slot) {
    return _state.battlerAt(slot);
  }

  /// Temporary bridge for the previous `PsdkBattleEngine` facade.
  ///
  /// Later lots should move callers to [BattlePublicState] directly, but Lot 4
  /// keeps the old smoke CLI and tests alive by exposing the exact wrapped
  /// immutable snapshot.
  PsdkBattleState get psdkState => _state;
}

PsdkBattleOutcome? _outcomeFor(PsdkBattleState state) {
  if (_bankDefeated(state, psdkOpponentSlot.bank)) {
    return const PsdkBattleOutcome(kind: PsdkBattleOutcomeKind.victory);
  }
  if (_bankDefeated(state, psdkPlayerSlot.bank)) {
    return const PsdkBattleOutcome(kind: PsdkBattleOutcomeKind.defeat);
  }
  return null;
}

bool _bankDefeated(PsdkBattleState state, int bank) {
  final activeById = <String, PsdkBattleCombatant>{
    for (final entry in state.combatants.entries)
      if (entry.key.bank == bank) entry.value.id: entry.value,
  };
  final party = state.partyForBank(bank);
  if (party.isEmpty) {
    return activeById.values.every((combatant) => combatant.isFainted);
  }
  return party.every(
    (combatant) => (activeById[combatant.id] ?? combatant).isFainted,
  );
}

PsdkBattleState _stateWithInitialOutcome(PsdkBattleState state) {
  final outcome = _outcomeFor(state);
  if (outcome == null) {
    return state;
  }
  return state.copyWith(outcome: outcome);
}
