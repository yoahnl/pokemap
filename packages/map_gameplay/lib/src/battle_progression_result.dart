import 'package:map_core/map_core.dart';

import 'battle_reward.dart';
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
  }) {
    final advanced = _advanceMoveLearning(
      state: state,
      opportunities: moveLearningOpportunities,
      changes: moveLearningChanges,
    );
    return BattleProgressionResult._(
      state: advanced.state,
      appliedReward: appliedReward,
      changes: List<BattlePokemonProgressionChange>.unmodifiable(changes),
      pendingMoveLearning: advanced.pending,
      remainingMoveLearningOpportunities: advanced.remaining,
      moveLearningChanges: advanced.changes,
    );
  }

  const BattleProgressionResult._({
    required this.state,
    required this.appliedReward,
    required this.changes,
    required this.pendingMoveLearning,
    required List<BattleMoveLearningOpportunity>
        remainingMoveLearningOpportunities,
    required this.moveLearningChanges,
  }) : _remainingMoveLearningOpportunities = remainingMoveLearningOpportunities;

  final GameState state;
  final BattleReward appliedReward;
  final List<BattlePokemonProgressionChange> changes;
  final PendingBattleMoveLearning? pendingMoveLearning;
  final List<BattleMoveLearningOpportunity> _remainingMoveLearningOpportunities;
  final List<BattleMoveLearningChange> moveLearningChanges;

  int get remainingMoveLearningCount =>
      _remainingMoveLearningOpportunities.length;

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
    return BattleProgressionResult._(
      state: advanced.state,
      appliedReward: appliedReward,
      changes: changes,
      pendingMoveLearning: advanced.pending,
      remainingMoveLearningOpportunities: advanced.remaining,
      moveLearningChanges: advanced.changes,
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
