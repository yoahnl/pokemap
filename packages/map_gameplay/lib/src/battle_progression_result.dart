import 'package:map_core/map_core.dart';

import 'battle_reward.dart';
import 'pokemon_evolution_service.dart';
import 'pokemon_stat_calculator.dart';

const _maximumKnownMoveCount = 4;

/// Catalogue-derived move that may be learned after crossing [learnedAtLevel].
///
/// Runtime owns catalogue IO. Gameplay receives only this small typed value.
final class PokemonMoveLearningCandidate {
  const PokemonMoveLearningCandidate({
    required this.opportunityId,
    required this.moveId,
    required this.learnedAtLevel,
    required this.maxPp,
  });

  final String opportunityId;
  final String moveId;
  final int learnedAtLevel;
  final int maxPp;

  PokemonMoveLearningCandidate validated() {
    final normalizedOpportunityId = opportunityId.trim();
    final normalizedMoveId = moveId.trim();
    if (normalizedOpportunityId.isEmpty) {
      throw ArgumentError.value(
        opportunityId,
        'opportunityId',
        'must not be empty',
      );
    }
    if (normalizedMoveId.isEmpty) {
      throw ArgumentError.value(moveId, 'moveId', 'must not be empty');
    }
    RangeError.checkValueInInterval(
      learnedAtLevel,
      1,
      100,
      'learnedAtLevel',
    );
    if (maxPp <= 0) {
      throw RangeError.value(maxPp, 'maxPp', 'must be strictly positive');
    }
    if (normalizedOpportunityId == opportunityId &&
        normalizedMoveId == moveId) {
      return this;
    }
    return PokemonMoveLearningCandidate(
      opportunityId: normalizedOpportunityId,
      moveId: normalizedMoveId,
      learnedAtLevel: learnedAtLevel,
      maxPp: maxPp,
    );
  }
}

/// One ordered learning opportunity for one persisted party slot.
final class BattleMoveLearningOpportunity {
  const BattleMoveLearningOpportunity({
    required this.partySlot,
    required this.candidate,
  });

  final int partySlot;
  final PokemonMoveLearningCandidate candidate;

  BattleMoveLearningOpportunity validated() {
    RangeError.checkNotNegative(partySlot, 'partySlot');
    final normalizedCandidate = candidate.validated();
    if (identical(normalizedCandidate, candidate)) return this;
    return BattleMoveLearningOpportunity(
      partySlot: partySlot,
      candidate: normalizedCandidate,
    );
  }
}

enum BattleMoveLearningPhase { awaitingDecision, awaitingReplacement }

/// Presentation-ready description of the move currently awaiting a decision.
final class PendingBattleMoveLearning {
  const PendingBattleMoveLearning({
    required this.opportunityId,
    required this.partySlot,
    required this.candidate,
    required this.phase,
  });

  final String opportunityId;
  final int partySlot;
  final PokemonMoveLearningCandidate candidate;
  final BattleMoveLearningPhase phase;
}

/// Typed decision for one exact pending move-learning request.
sealed class BattleMoveLearningDecision {
  const BattleMoveLearningDecision({
    required this.opportunityId,
    required this.partySlot,
    required this.moveId,
  });

  const factory BattleMoveLearningDecision.learn({
    required String opportunityId,
    required int partySlot,
    required String moveId,
  }) = LearnBattleMoveLearningDecision;

  const factory BattleMoveLearningDecision.replace({
    required String opportunityId,
    required int partySlot,
    required String moveId,
    required int replaceMoveIndex,
    required String expectedReplacedMoveId,
  }) = ReplaceBattleMoveLearningDecision;

  const factory BattleMoveLearningDecision.decline({
    required String opportunityId,
    required int partySlot,
    required String moveId,
  }) = DeclineBattleMoveLearningDecision;

  final String opportunityId;
  final int partySlot;
  final String moveId;
}

final class LearnBattleMoveLearningDecision extends BattleMoveLearningDecision {
  const LearnBattleMoveLearningDecision({
    required super.opportunityId,
    required super.partySlot,
    required super.moveId,
  });
}

final class ReplaceBattleMoveLearningDecision
    extends BattleMoveLearningDecision {
  const ReplaceBattleMoveLearningDecision({
    required super.opportunityId,
    required super.partySlot,
    required super.moveId,
    required this.replaceMoveIndex,
    required this.expectedReplacedMoveId,
  });

  final int replaceMoveIndex;
  final String expectedReplacedMoveId;
}

final class DeclineBattleMoveLearningDecision
    extends BattleMoveLearningDecision {
  const DeclineBattleMoveLearningDecision({
    required super.opportunityId,
    required super.partySlot,
    required super.moveId,
  });
}

enum BattleMoveLearningChangeKind {
  automaticallyLearned,
  replacementRequested,
  learned,
  replaced,
  declined,
}

/// Observable move-learning transition for later presentation.
final class BattleMoveLearningChange {
  const BattleMoveLearningChange({
    required this.partySlot,
    required this.candidate,
    required this.kind,
    this.replacedMoveId,
  });

  final int partySlot;
  final PokemonMoveLearningCandidate candidate;
  final BattleMoveLearningChangeKind kind;
  final String? replacedMoveId;
}

/// One ordered evolution opportunity for a persisted party slot.
final class BattleEvolutionOpportunity {
  const BattleEvolutionOpportunity({
    required this.occurrenceId,
    required this.partySlot,
    required this.candidate,
    required this.sourceMaxHp,
  });

  final String occurrenceId;
  final int partySlot;
  final PokemonEvolutionCandidate candidate;
  final int sourceMaxHp;

  BattleEvolutionOpportunity validated() {
    final normalizedOccurrenceId = occurrenceId.trim();
    if (normalizedOccurrenceId.isEmpty) {
      throw ArgumentError.value(
        occurrenceId,
        'occurrenceId',
        'must not be empty',
      );
    }
    RangeError.checkNotNegative(partySlot, 'partySlot');
    RangeError.checkValueInInterval(sourceMaxHp, 1, 9999, 'sourceMaxHp');
    final normalizedCandidate = candidate.validated();
    if (normalizedOccurrenceId == occurrenceId &&
        identical(normalizedCandidate, candidate)) {
      return this;
    }
    return BattleEvolutionOpportunity(
      occurrenceId: normalizedOccurrenceId,
      partySlot: partySlot,
      candidate: normalizedCandidate,
      sourceMaxHp: sourceMaxHp,
    );
  }
}

/// Presentation-ready evolution waiting for one exact player decision.
final class PendingBattleEvolution {
  const PendingBattleEvolution({
    required this.opportunityId,
    required this.occurrenceId,
    required this.partySlot,
    required this.candidate,
    required this.sourceMaxHp,
  });

  final String opportunityId;
  final String occurrenceId;
  final int partySlot;
  final PokemonEvolutionCandidate candidate;
  final int sourceMaxHp;

  String get sourceSpeciesId => candidate.sourceSpeciesId;
  String get targetSpeciesId => candidate.targetSpeciesId;
}

/// Typed decision bound to the complete identity of a pending evolution.
sealed class BattleEvolutionDecision {
  const BattleEvolutionDecision({
    required this.opportunityId,
    required this.occurrenceId,
    required this.partySlot,
    required this.sourceSpeciesId,
    required this.targetSpeciesId,
  });

  const factory BattleEvolutionDecision.accept({
    required String opportunityId,
    required String occurrenceId,
    required int partySlot,
    required String sourceSpeciesId,
    required String targetSpeciesId,
  }) = AcceptBattleEvolutionDecision;

  const factory BattleEvolutionDecision.refuse({
    required String opportunityId,
    required String occurrenceId,
    required int partySlot,
    required String sourceSpeciesId,
    required String targetSpeciesId,
  }) = RefuseBattleEvolutionDecision;

  final String opportunityId;
  final String occurrenceId;
  final int partySlot;
  final String sourceSpeciesId;
  final String targetSpeciesId;
}

final class AcceptBattleEvolutionDecision extends BattleEvolutionDecision {
  const AcceptBattleEvolutionDecision({
    required super.opportunityId,
    required super.occurrenceId,
    required super.partySlot,
    required super.sourceSpeciesId,
    required super.targetSpeciesId,
  });
}

final class RefuseBattleEvolutionDecision extends BattleEvolutionDecision {
  const RefuseBattleEvolutionDecision({
    required super.opportunityId,
    required super.occurrenceId,
    required super.partySlot,
    required super.sourceSpeciesId,
    required super.targetSpeciesId,
  });
}

enum BattleEvolutionChangeKind { evolved, refused }

/// Observable evolution transition for presentation and save orchestration.
final class BattleEvolutionChange {
  const BattleEvolutionChange({
    required this.occurrenceId,
    required this.partySlot,
    required this.candidate,
    required this.kind,
    this.result,
  });

  final String occurrenceId;
  final int partySlot;
  final PokemonEvolutionCandidate candidate;
  final BattleEvolutionChangeKind kind;
  final PokemonEvolutionResult? result;
}

/// Observable per-slot result of one XP application.
final class BattlePokemonProgressionChange {
  const BattlePokemonProgressionChange({
    required this.partySlot,
    required this.experienceAwarded,
    required this.oldExperience,
    required this.newExperience,
    required this.oldLevel,
    required this.newLevel,
    required this.oldMaxHp,
    required this.newCurrentHp,
    required this.calculatedStats,
  });

  final int partySlot;
  final int experienceAwarded;
  final int oldExperience;
  final int newExperience;
  final int oldLevel;
  final int newLevel;
  final int oldMaxHp;
  final int newCurrentHp;
  final PokemonCalculatedStats calculatedStats;

  int get levelsGained => newLevel - oldLevel;
}

/// Atomic state, reward, progression, and pending-decision snapshot.
final class BattleProgressionResult {
  factory BattleProgressionResult({
    required GameState state,
    required BattleReward appliedReward,
    required Iterable<BattlePokemonProgressionChange> changes,
    Iterable<BattleMoveLearningOpportunity> moveLearningOpportunities =
        const <BattleMoveLearningOpportunity>[],
    Iterable<BattleMoveLearningChange> moveLearningChanges =
        const <BattleMoveLearningChange>[],
    Iterable<BattleEvolutionOpportunity> evolutionOpportunities =
        const <BattleEvolutionOpportunity>[],
    Iterable<BattleEvolutionChange> evolutionChanges =
        const <BattleEvolutionChange>[],
    PokemonEvolutionService evolutionService = const PokemonEvolutionService(),
    required PokemonRulesetProfile ruleset,
  }) {
    final evolutionQueue = _validatedEvolutionQueue(evolutionOpportunities);
    final moveAdvanced = _advanceMoveLearning(
      state: state,
      opportunities: moveLearningOpportunities,
      changes: moveLearningChanges,
    );
    if (moveAdvanced.pending != null) {
      return BattleProgressionResult._(
        ruleset: ruleset,
        state: moveAdvanced.state,
        appliedReward: appliedReward,
        changes: List<BattlePokemonProgressionChange>.unmodifiable(changes),
        pendingMoveLearning: moveAdvanced.pending,
        remainingMoveLearningOpportunities: moveAdvanced.remaining,
        moveLearningChanges: moveAdvanced.changes,
        pendingEvolution: null,
        remainingEvolutionOpportunities: evolutionQueue,
        evolutionChanges:
            List<BattleEvolutionChange>.unmodifiable(evolutionChanges),
        evolutionService: evolutionService,
      );
    }
    final evolutionAdvanced = _advanceEvolution(
      state: moveAdvanced.state,
      opportunities: evolutionQueue,
      changes: evolutionChanges,
    );
    return BattleProgressionResult._(
      ruleset: ruleset,
      state: evolutionAdvanced.state,
      appliedReward: appliedReward,
      changes: List<BattlePokemonProgressionChange>.unmodifiable(changes),
      pendingMoveLearning: null,
      remainingMoveLearningOpportunities: moveAdvanced.remaining,
      moveLearningChanges: moveAdvanced.changes,
      pendingEvolution: evolutionAdvanced.pending,
      remainingEvolutionOpportunities: evolutionAdvanced.remaining,
      evolutionChanges: evolutionAdvanced.changes,
      evolutionService: evolutionService,
    );
  }

  const BattleProgressionResult._({
    required this.ruleset,
    required this.state,
    required this.appliedReward,
    required this.changes,
    required this.pendingMoveLearning,
    required List<BattleMoveLearningOpportunity>
        remainingMoveLearningOpportunities,
    required this.moveLearningChanges,
    required this.pendingEvolution,
    required List<BattleEvolutionOpportunity> remainingEvolutionOpportunities,
    required this.evolutionChanges,
    required PokemonEvolutionService evolutionService,
  })  : _remainingMoveLearningOpportunities =
            remainingMoveLearningOpportunities,
        _remainingEvolutionOpportunities = remainingEvolutionOpportunities,
        _evolutionService = evolutionService;

  final GameState state;
  final PokemonRulesetProfile ruleset;
  PokemonRulesetReference get rulesetReference => ruleset.reference;
  final BattleReward appliedReward;
  final List<BattlePokemonProgressionChange> changes;
  final PendingBattleMoveLearning? pendingMoveLearning;
  final List<BattleMoveLearningOpportunity> _remainingMoveLearningOpportunities;
  final List<BattleMoveLearningChange> moveLearningChanges;
  final PendingBattleEvolution? pendingEvolution;
  final List<BattleEvolutionOpportunity> _remainingEvolutionOpportunities;
  final List<BattleEvolutionChange> evolutionChanges;
  final PokemonEvolutionService _evolutionService;

  int get remainingMoveLearningCount =>
      _remainingMoveLearningOpportunities.length;
  int get remainingEvolutionCount => _remainingEvolutionOpportunities.length;

  BattleProgressionResult resolvePendingMoveLearning(
    BattleMoveLearningDecision decision,
  ) {
    final pending = pendingMoveLearning;
    if (pending == null) {
      throw StateError('No move learning decision is pending.');
    }
    if (decision.opportunityId != pending.opportunityId ||
        decision.partySlot != pending.partySlot ||
        decision.moveId != pending.candidate.moveId) {
      throw StateError(
        'Move learning decision does not match the current pending request.',
      );
    }

    final member = _partyMemberAt(state, pending.partySlot);
    late final GameState decisionState;
    late final BattleMoveLearningChange decisionChange;
    switch (decision) {
      case LearnBattleMoveLearningDecision():
        if (pending.phase != BattleMoveLearningPhase.awaitingDecision) {
          throw StateError(
            'Move learning is already awaiting a replacement choice.',
          );
        }
        final replacementRequested = BattleMoveLearningChange(
          partySlot: pending.partySlot,
          candidate: pending.candidate,
          kind: BattleMoveLearningChangeKind.replacementRequested,
        );
        return BattleProgressionResult._(
          ruleset: ruleset,
          state: state,
          appliedReward: appliedReward,
          changes: changes,
          pendingMoveLearning: PendingBattleMoveLearning(
            opportunityId: pending.opportunityId,
            partySlot: pending.partySlot,
            candidate: pending.candidate,
            phase: BattleMoveLearningPhase.awaitingReplacement,
          ),
          remainingMoveLearningOpportunities:
              _remainingMoveLearningOpportunities,
          moveLearningChanges: List<BattleMoveLearningChange>.unmodifiable(
            <BattleMoveLearningChange>[
              ...moveLearningChanges,
              replacementRequested,
            ],
          ),
          pendingEvolution: null,
          remainingEvolutionOpportunities: _remainingEvolutionOpportunities,
          evolutionChanges: evolutionChanges,
          evolutionService: _evolutionService,
        );
      case ReplaceBattleMoveLearningDecision():
        if (pending.phase != BattleMoveLearningPhase.awaitingReplacement) {
          throw StateError(
            'A move replacement must be accepted before choosing a move.',
          );
        }
        final replaced = _replaceLearnedMove(
          member: member,
          candidate: pending.candidate,
          replaceMoveIndex: decision.replaceMoveIndex,
          expectedReplacedMoveId: decision.expectedReplacedMoveId,
        );
        decisionState = _replacePartyMember(
          state,
          pending.partySlot,
          replaced.member,
        );
        decisionChange = BattleMoveLearningChange(
          partySlot: pending.partySlot,
          candidate: pending.candidate,
          kind: BattleMoveLearningChangeKind.replaced,
          replacedMoveId: replaced.replacedMoveId,
        );
      case DeclineBattleMoveLearningDecision():
        decisionState = state;
        decisionChange = BattleMoveLearningChange(
          partySlot: pending.partySlot,
          candidate: pending.candidate,
          kind: BattleMoveLearningChangeKind.declined,
        );
    }

    final advanced = _advanceMoveLearning(
      state: decisionState,
      opportunities: _remainingMoveLearningOpportunities,
      changes: <BattleMoveLearningChange>[
        ...moveLearningChanges,
        decisionChange,
      ],
    );
    if (advanced.pending != null) {
      return BattleProgressionResult._(
        ruleset: ruleset,
        state: advanced.state,
        appliedReward: appliedReward,
        changes: changes,
        pendingMoveLearning: advanced.pending,
        remainingMoveLearningOpportunities: advanced.remaining,
        moveLearningChanges: advanced.changes,
        pendingEvolution: null,
        remainingEvolutionOpportunities: _remainingEvolutionOpportunities,
        evolutionChanges: evolutionChanges,
        evolutionService: _evolutionService,
      );
    }
    final evolutionAdvanced = _advanceEvolution(
      state: advanced.state,
      opportunities: _remainingEvolutionOpportunities,
      changes: evolutionChanges,
    );
    return BattleProgressionResult._(
      ruleset: ruleset,
      state: evolutionAdvanced.state,
      appliedReward: appliedReward,
      changes: changes,
      pendingMoveLearning: null,
      remainingMoveLearningOpportunities: advanced.remaining,
      moveLearningChanges: advanced.changes,
      pendingEvolution: evolutionAdvanced.pending,
      remainingEvolutionOpportunities: evolutionAdvanced.remaining,
      evolutionChanges: evolutionAdvanced.changes,
      evolutionService: _evolutionService,
    );
  }

  BattleProgressionResult resolvePendingEvolution(
    BattleEvolutionDecision decision,
  ) {
    final pending = pendingEvolution;
    if (pending == null) {
      throw StateError('No evolution decision is pending.');
    }
    if (pendingMoveLearning != null) {
      throw StateError('Move learning must be resolved before evolution.');
    }
    if (decision.opportunityId != pending.opportunityId ||
        decision.occurrenceId != pending.occurrenceId ||
        decision.partySlot != pending.partySlot ||
        decision.sourceSpeciesId != pending.sourceSpeciesId ||
        decision.targetSpeciesId != pending.targetSpeciesId) {
      throw StateError(
        'Evolution decision does not match the current pending request.',
      );
    }

    final opportunity = BattleEvolutionOpportunity(
      occurrenceId: pending.occurrenceId,
      partySlot: pending.partySlot,
      candidate: pending.candidate,
      sourceMaxHp: pending.sourceMaxHp,
    );
    late final GameState decisionState;
    late final BattleEvolutionChange decisionChange;
    late final List<BattleEvolutionOpportunity> remaining;
    switch (decision) {
      case AcceptBattleEvolutionDecision():
        final evolved = _evolutionService.evolve(
          ruleset: ruleset,
          pokemon: _partyMemberAt(state, pending.partySlot),
          candidate: pending.candidate,
          sourceMaxHp: opportunity.sourceMaxHp,
        );
        decisionState = _replacePartyMember(
          state,
          pending.partySlot,
          evolved.pokemon,
        );
        decisionChange = BattleEvolutionChange(
          occurrenceId: pending.occurrenceId,
          partySlot: pending.partySlot,
          candidate: pending.candidate,
          kind: BattleEvolutionChangeKind.evolved,
          result: evolved,
        );
        // Accepting one branch makes every other branch from the old source
        // stale. No next-chain evolution is invented by gameplay.
        remaining = List<BattleEvolutionOpportunity>.unmodifiable(
          _remainingEvolutionOpportunities.where(
            (entry) =>
                entry.partySlot != pending.partySlot ||
                entry.candidate.sourceSpeciesId != pending.sourceSpeciesId,
          ),
        );
      case RefuseBattleEvolutionDecision():
        decisionState = state;
        decisionChange = BattleEvolutionChange(
          occurrenceId: pending.occurrenceId,
          partySlot: pending.partySlot,
          candidate: pending.candidate,
          kind: BattleEvolutionChangeKind.refused,
        );
        remaining = _remainingEvolutionOpportunities;
    }

    final advanced = _advanceEvolution(
      state: decisionState,
      opportunities: remaining,
      changes: <BattleEvolutionChange>[
        ...evolutionChanges,
        decisionChange,
      ],
    );
    return BattleProgressionResult._(
      ruleset: ruleset,
      state: advanced.state,
      appliedReward: appliedReward,
      changes: changes,
      pendingMoveLearning: null,
      remainingMoveLearningOpportunities: const <BattleMoveLearningOpportunity>[],
      moveLearningChanges: moveLearningChanges,
      pendingEvolution: advanced.pending,
      remainingEvolutionOpportunities: advanced.remaining,
      evolutionChanges: advanced.changes,
      evolutionService: _evolutionService,
    );
  }
}

final class _MoveLearningAdvanceResult {
  const _MoveLearningAdvanceResult({
    required this.state,
    required this.pending,
    required this.remaining,
    required this.changes,
  });

  final GameState state;
  final PendingBattleMoveLearning? pending;
  final List<BattleMoveLearningOpportunity> remaining;
  final List<BattleMoveLearningChange> changes;
}

final class _EvolutionAdvanceResult {
  const _EvolutionAdvanceResult({
    required this.state,
    required this.pending,
    required this.remaining,
    required this.changes,
  });

  final GameState state;
  final PendingBattleEvolution? pending;
  final List<BattleEvolutionOpportunity> remaining;
  final List<BattleEvolutionChange> changes;
}

_EvolutionAdvanceResult _advanceEvolution({
  required GameState state,
  required Iterable<BattleEvolutionOpportunity> opportunities,
  required Iterable<BattleEvolutionChange> changes,
}) {
  final queue = _validatedEvolutionQueue(opportunities);
  final appliedChanges = List<BattleEvolutionChange>.unmodifiable(changes);
  if (queue.isEmpty) {
    return _EvolutionAdvanceResult(
      state: state,
      pending: null,
      remaining: const <BattleEvolutionOpportunity>[],
      changes: appliedChanges,
    );
  }

  final opportunity = queue.first;
  final member = _partyMemberAt(state, opportunity.partySlot);
  if (member.speciesId != opportunity.candidate.sourceSpeciesId) {
    throw StateError(
      'Evolution opportunity source does not match the party member.',
    );
  }
  if (member.level < opportunity.candidate.minLevel) {
    throw StateError('Evolution opportunity is below its minimum level.');
  }
  if (member.currentHp < 0 || member.currentHp > opportunity.sourceMaxHp) {
    throw StateError('Evolution source HP is outside its projected maximum.');
  }
  return _EvolutionAdvanceResult(
    state: state,
    pending: PendingBattleEvolution(
      opportunityId: opportunity.candidate.opportunityId,
      occurrenceId: opportunity.occurrenceId,
      partySlot: opportunity.partySlot,
      candidate: opportunity.candidate,
      sourceMaxHp: opportunity.sourceMaxHp,
    ),
    remaining: List<BattleEvolutionOpportunity>.unmodifiable(queue.skip(1)),
    changes: appliedChanges,
  );
}

List<BattleEvolutionOpportunity> _validatedEvolutionQueue(
  Iterable<BattleEvolutionOpportunity> opportunities,
) {
  final identities = <({int partySlot, String occurrenceId})>{};
  final queue = <BattleEvolutionOpportunity>[];
  for (final opportunity in opportunities) {
    final validated = opportunity.validated();
    final identity = (
      partySlot: validated.partySlot,
      occurrenceId: validated.occurrenceId,
    );
    if (!identities.add(identity)) {
      throw ArgumentError.value(
        identity,
        'evolutionOpportunities',
        'contains a duplicate party-slot occurrence identity',
      );
    }
    queue.add(validated);
  }
  return List<BattleEvolutionOpportunity>.unmodifiable(queue);
}

_MoveLearningAdvanceResult _advanceMoveLearning({
  required GameState state,
  required Iterable<BattleMoveLearningOpportunity> opportunities,
  required Iterable<BattleMoveLearningChange> changes,
}) {
  final queue = _validatedMoveLearningQueue(opportunities);
  final appliedChanges = <BattleMoveLearningChange>[...changes];
  var nextState = state;

  for (var index = 0; index < queue.length; index++) {
    final opportunity = queue[index];
    final member = _partyMemberAt(nextState, opportunity.partySlot);
    if (member.knownMoveIds.contains(opportunity.candidate.moveId)) {
      continue;
    }
    if (member.knownMoveIds.length >= _maximumKnownMoveCount) {
      return _MoveLearningAdvanceResult(
        state: nextState,
        pending: PendingBattleMoveLearning(
          opportunityId: opportunity.candidate.opportunityId,
          partySlot: opportunity.partySlot,
          candidate: opportunity.candidate,
          phase: BattleMoveLearningPhase.awaitingDecision,
        ),
        remaining: List<BattleMoveLearningOpportunity>.unmodifiable(
          queue.skip(index + 1),
        ),
        changes: List<BattleMoveLearningChange>.unmodifiable(appliedChanges),
      );
    }

    nextState = _replacePartyMember(
      nextState,
      opportunity.partySlot,
      _appendLearnedMove(member, opportunity.candidate),
    );
    appliedChanges.add(
      BattleMoveLearningChange(
        partySlot: opportunity.partySlot,
        candidate: opportunity.candidate,
        kind: BattleMoveLearningChangeKind.automaticallyLearned,
      ),
    );
  }

  return _MoveLearningAdvanceResult(
    state: nextState,
    pending: null,
    remaining: const <BattleMoveLearningOpportunity>[],
    changes: List<BattleMoveLearningChange>.unmodifiable(appliedChanges),
  );
}

List<BattleMoveLearningOpportunity> _validatedMoveLearningQueue(
  Iterable<BattleMoveLearningOpportunity> opportunities,
) {
  final identities = <({int partySlot, String opportunityId})>{};
  final queue = <BattleMoveLearningOpportunity>[];
  for (final opportunity in opportunities) {
    final validated = opportunity.validated();
    final identity = (
      partySlot: validated.partySlot,
      opportunityId: validated.candidate.opportunityId,
    );
    if (!identities.add(identity)) {
      throw ArgumentError.value(
        identity,
        'moveLearningOpportunities',
        'contains a duplicate party-slot opportunity identity',
      );
    }
    queue.add(validated);
  }
  return List<BattleMoveLearningOpportunity>.unmodifiable(queue);
}

PlayerPokemon _partyMemberAt(GameState state, int partySlot) {
  if (partySlot < 0 || partySlot >= state.party.members.length) {
    throw RangeError.index(
      partySlot,
      state.party.members,
      'moveLearningPartySlot',
    );
  }
  return state.party.members[partySlot];
}

PlayerPokemon _appendLearnedMove(
  PlayerPokemon member,
  PokemonMoveLearningCandidate candidate,
) {
  if (member.knownMoveIds.contains(candidate.moveId)) return member;
  if (member.knownMoveIds.length >= _maximumKnownMoveCount) {
    throw StateError('Pokemon already knows four moves.');
  }
  final currentPp = _validatedMutableCurrentPp(member);
  currentPp[candidate.moveId] = candidate.maxPp;
  return member.copyWith(
    knownMoveIds: <String>[...member.knownMoveIds, candidate.moveId],
    currentPpByMoveId: currentPp,
  );
}

({PlayerPokemon member, String replacedMoveId}) _replaceLearnedMove({
  required PlayerPokemon member,
  required PokemonMoveLearningCandidate candidate,
  required int replaceMoveIndex,
  required String expectedReplacedMoveId,
}) {
  final currentPp = _validatedMutableCurrentPp(member);
  if (member.knownMoveIds.contains(candidate.moveId)) {
    throw StateError('Pokemon already knows ${candidate.moveId}.');
  }
  if (replaceMoveIndex < 0 || replaceMoveIndex >= member.knownMoveIds.length) {
    throw RangeError.index(
      replaceMoveIndex,
      member.knownMoveIds,
      'replaceMoveIndex',
    );
  }
  final replacedMoveId = member.knownMoveIds[replaceMoveIndex];
  if (expectedReplacedMoveId.isEmpty ||
      expectedReplacedMoveId != replacedMoveId) {
    throw StateError(
      'Move replacement does not match the selected existing move.',
    );
  }

  currentPp
    ..remove(replacedMoveId)
    ..[candidate.moveId] = candidate.maxPp;
  final knownMoveIds = <String>[...member.knownMoveIds]..[replaceMoveIndex] =
      candidate.moveId;
  return (
    member: member.copyWith(
      knownMoveIds: knownMoveIds,
      currentPpByMoveId: currentPp,
    ),
    replacedMoveId: replacedMoveId,
  );
}

Map<String, int> _validatedMutableCurrentPp(PlayerPokemon member) {
  final knownMoveIds = member.knownMoveIds;
  final knownMoveIdSet = <String>{};
  for (final moveId in knownMoveIds) {
    if (moveId.isEmpty || moveId.trim() != moveId) {
      throw StateError(
        'Pokemon known move ids must be non-empty and normalized.',
      );
    }
    if (!knownMoveIdSet.add(moveId)) {
      throw StateError('Pokemon known move ids must be unique.');
    }
  }

  final currentPp = member.currentPpByMoveId;
  if (currentPp == null && knownMoveIds.isNotEmpty) {
    throw StateError(
      'Pokemon current PP must be hydrated before learning a move.',
    );
  }
  if (currentPp == null) return <String, int>{};
  if (currentPp.length != knownMoveIdSet.length) {
    throw StateError(
      'Pokemon current PP keys must exactly match its known moves.',
    );
  }
  for (final entry in currentPp.entries) {
    if (entry.key.isEmpty || entry.key.trim() != entry.key) {
      throw StateError('Pokemon current PP keys must be normalized.');
    }
    if (!knownMoveIdSet.contains(entry.key)) {
      throw StateError(
        'Pokemon current PP keys must exactly match its known moves.',
      );
    }
    if (entry.value < 0) {
      throw StateError('Pokemon current PP values must be non-negative.');
    }
  }
  return <String, int>{...currentPp};
}

GameState _replacePartyMember(
  GameState state,
  int partySlot,
  PlayerPokemon member,
) {
  final members = <PlayerPokemon>[...state.party.members]..[partySlot] = member;
  return state.copyWith(party: state.party.copyWith(members: members));
}
