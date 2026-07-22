import 'package:map_battle/map_battle.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'runtime_battle_outcome_apply.dart';

/// Pure fail-closed bridge from battle lineup identities to persisted party
/// slots used by [BattleProgressionService].
///
/// This mapper deliberately does not apply progression or drive presentation.
/// Runtime orchestration remains responsible for loading opponent/species
/// metadata and invoking the gameplay service at the appropriate lifecycle
/// point.
final class RuntimeBattleProgressionContextMapper {
  const RuntimeBattleProgressionContextMapper();

  BattleProgressionContext fromLegacyOutcome({
    required RuntimeActiveBattleContext runtimeContext,
    required BattleOutcome outcome,
    required int partyLength,
    required Iterable<BattleProgressionDefeatedOpponent> defeatedOpponents,
    required Iterable<BattleProgressionPartySlotMetadata> partySlotMetadata,
  }) {
    return BattleProgressionContext(
      outcome: switch (outcome.type) {
        BattleOutcomeType.victory => BattleProgressionOutcomeKind.victory,
        BattleOutcomeType.defeat => BattleProgressionOutcomeKind.defeat,
        BattleOutcomeType.runaway => BattleProgressionOutcomeKind.fled,
        BattleOutcomeType.captured => BattleProgressionOutcomeKind.captured,
      },
      playerParticipantPartySlots: _mapParticipantLineupIndexes(
        runtimeContext: runtimeContext,
        participantLineupIndexes: outcome.playerParticipantLineupIndexes,
        partyLength: partyLength,
      ),
      defeatedOpponents: defeatedOpponents,
      partySlotMetadata: partySlotMetadata,
    );
  }

  BattleProgressionContext fromPsdkOutcome({
    required RuntimeActiveBattleContext runtimeContext,
    required PsdkBattleOutcome outcome,
    required int partyLength,
    required Iterable<BattleProgressionDefeatedOpponent> defeatedOpponents,
    required Iterable<BattleProgressionPartySlotMetadata> partySlotMetadata,
  }) {
    return BattleProgressionContext(
      outcome: switch (outcome.kind) {
        PsdkBattleOutcomeKind.victory => BattleProgressionOutcomeKind.victory,
        PsdkBattleOutcomeKind.defeat => BattleProgressionOutcomeKind.defeat,
        PsdkBattleOutcomeKind.fled => BattleProgressionOutcomeKind.fled,
      },
      playerParticipantPartySlots: _mapParticipantLineupIndexes(
        runtimeContext: runtimeContext,
        participantLineupIndexes: outcome.playerParticipantPartyIndexes,
        partyLength: partyLength,
      ),
      defeatedOpponents: defeatedOpponents,
      partySlotMetadata: partySlotMetadata,
    );
  }
}

Set<int> _mapParticipantLineupIndexes({
  required RuntimeActiveBattleContext runtimeContext,
  required Iterable<int> participantLineupIndexes,
  required int partyLength,
}) {
  if (partyLength <= 0) {
    throw StateError(
      'Battle progression requires a non-empty persisted player party.',
    );
  }

  final mapping = runtimeContext.playerPartySlotIndicesByLineupIndex;
  if (mapping.isEmpty) {
    throw StateError(
      'Battle progression requires the lineup-to-party mapping.',
    );
  }
  if (mapping.length > partyLength) {
    throw StateError(
      'Battle progression lineup mapping is longer than the player party: '
      'lineupLength=${mapping.length}, partyLength=$partyLength.',
    );
  }
  if (mapping.first != runtimeContext.playerPartyIndex) {
    throw StateError(
      'Battle progression active slot disagrees with lineup index zero: '
      'activePartySlot=${runtimeContext.playerPartyIndex}, '
      'mappedPartySlot=${mapping.first}.',
    );
  }

  final mappedPartySlots = <int>{};
  for (var lineupIndex = 0; lineupIndex < mapping.length; lineupIndex++) {
    final partySlot = mapping[lineupIndex];
    if (partySlot < 0 || partySlot >= partyLength) {
      throw StateError(
        'Battle progression lineup maps to an invalid party slot: '
        'lineupIndex=$lineupIndex, partySlot=$partySlot, '
        'partyLength=$partyLength.',
      );
    }
    if (!mappedPartySlots.add(partySlot)) {
      throw StateError(
        'Battle progression lineup maps multiple entries to party slot '
        '$partySlot.',
      );
    }
  }

  final participants = <int>{};
  for (final lineupIndex in participantLineupIndexes) {
    if (lineupIndex < 0 || lineupIndex >= mapping.length) {
      throw StateError(
        'Battle progression participant is outside the lineup mapping: '
        'lineupIndex=$lineupIndex, lineupLength=${mapping.length}.',
      );
    }
    participants.add(mapping[lineupIndex]);
  }
  return Set<int>.unmodifiable(participants);
}
