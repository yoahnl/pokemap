import 'package:map_core/map_core.dart';

import 'battle_reward.dart';
import 'game_state_mutations.dart';
import 'pokemon_experience_curve.dart';
import 'pokemon_stat_calculator.dart';

/// Terminal battle result understood by pure gameplay progression.
enum BattleProgressionOutcomeKind { victory, defeat, fled, captured }

/// Progression data for one defeated opposing Pokemon.
final class BattleProgressionDefeatedOpponent {
  const BattleProgressionDefeatedOpponent({
    required this.level,
    required this.baseExperience,
  });

  final int level;
  final int baseExperience;

  BattleProgressionDefeatedOpponent validated() {
    RangeError.checkValueInInterval(level, 1, 100, 'level');
    RangeError.checkValueInInterval(
      baseExperience,
      1,
      10000,
      'baseExperience',
    );
    return this;
  }
}

/// Catalogue and pre-battle HP projection for one player party slot.
final class BattleProgressionPartySlotMetadata {
  const BattleProgressionPartySlotMetadata({
    required this.partySlot,
    required this.growthRateId,
    required this.oldMaxHp,
    required this.baseStats,
  });

  final int partySlot;
  final String growthRateId;
  final int oldMaxHp;
  final PokemonBaseStats baseStats;

  BattleProgressionPartySlotMetadata validated() {
    RangeError.checkNotNegative(partySlot, 'partySlot');
    RangeError.checkValueInInterval(oldMaxHp, 1, 9999, 'oldMaxHp');
    PokemonExperienceCurve.fromId(growthRateId);
    baseStats.validated();
    return this;
  }
}

/// Pure projection from a battle outcome into progression inputs.
///
/// This contract intentionally has no dependency on `map_battle`. Runtime
/// adapters translate either battle engine's final state into these values.
final class BattleProgressionContext {
  BattleProgressionContext({
    required this.outcome,
    required Iterable<int> playerParticipantPartySlots,
    required Iterable<BattleProgressionDefeatedOpponent> defeatedOpponents,
    required Iterable<BattleProgressionPartySlotMetadata> partySlotMetadata,
  })  : playerParticipantPartySlots = Set<int>.unmodifiable(
          playerParticipantPartySlots,
        ),
        defeatedOpponents =
            List<BattleProgressionDefeatedOpponent>.unmodifiable(
          defeatedOpponents.map((opponent) => opponent.validated()),
        ),
        partySlotMetadata =
            Map<int, BattleProgressionPartySlotMetadata>.unmodifiable(
          _metadataBySlot(partySlotMetadata),
        ) {
    for (final slot in this.playerParticipantPartySlots) {
      RangeError.checkNotNegative(slot, 'playerParticipantPartySlots');
    }
  }

  final BattleProgressionOutcomeKind outcome;
  final Set<int> playerParticipantPartySlots;
  final List<BattleProgressionDefeatedOpponent> defeatedOpponents;
  final Map<int, BattleProgressionPartySlotMetadata> partySlotMetadata;
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

/// Atomic state and reward snapshot produced by progression.
final class BattleProgressionResult {
  factory BattleProgressionResult({
    required GameState state,
    required BattleReward appliedReward,
    required Iterable<BattlePokemonProgressionChange> changes,
  }) {
    return BattleProgressionResult._(
      state: state,
      appliedReward: appliedReward,
      changes: List<BattlePokemonProgressionChange>.unmodifiable(changes),
    );
  }

  const BattleProgressionResult._({
    required this.state,
    required this.appliedReward,
    required this.changes,
  });

  final GameState state;
  final BattleReward appliedReward;
  final List<BattlePokemonProgressionChange> changes;
}

/// Applies the FG-044/FG-045 MVP progression policy.
///
/// Policy:
/// - only actual participants receive XP; there is no Exp Share;
/// - a participant remains eligible after fainting;
/// - wild XP is `floor(level * baseExp / 7)`;
/// - trainer XP uses the classic MVP `1.5` multiplier, calculated exactly as
///   `floor(level * baseExp * 3 / 14)`;
/// - the summed XP is split equally with integer division; any remainder is
///   deliberately discarded for a stable deterministic result.
final class BattleProgressionService {
  const BattleProgressionService({
    this.statCalculator = const PokemonStatCalculator(),
    this.mutations = const GameStateMutations(),
  });

  final PokemonStatCalculator statCalculator;
  final GameStateMutations mutations;

  BattleProgressionResult apply({
    required GameState state,
    required BattleProgressionContext context,
    required BattleReward reward,
  }) {
    if (context.outcome != BattleProgressionOutcomeKind.victory) {
      return BattleProgressionResult(
        state: state,
        appliedReward: _emptyRewardLike(reward),
        changes: const <BattlePokemonProgressionChange>[],
      );
    }

    if (context.playerParticipantPartySlots.isEmpty) {
      throw StateError(
        'Battle progression victory requires at least one participant.',
      );
    }
    if (context.defeatedOpponents.isEmpty) {
      throw StateError(
        'Battle progression victory requires at least one defeated opponent.',
      );
    }

    final participantSlots = context.playerParticipantPartySlots.toList()
      ..sort();
    final totalExperience = _totalExperience(
      opponents: context.defeatedOpponents,
      sourceKind: reward.sourceKind,
    );
    final experiencePerParticipant = totalExperience ~/ participantSlots.length;
    final plannedGrants = <BattleExperienceGrant>[
      for (final slot in participantSlots)
        BattleExperienceGrant(
          partySlot: slot,
          experience: experiencePerParticipant,
        ),
    ];

    final nextMembers = List<PlayerPokemon>.of(state.party.members);
    final changes = <BattlePokemonProgressionChange>[];
    final effectiveGrants = <BattleExperienceGrant>[];
    for (final grant in plannedGrants) {
      final slot = grant.partySlot;
      if (slot >= nextMembers.length) {
        throw RangeError.index(slot, nextMembers, 'participantPartySlot');
      }
      final metadata = context.partySlotMetadata[slot];
      if (metadata == null) {
        throw StateError('Missing progression metadata for party slot $slot.');
      }
      final member = nextMembers[slot];
      final oldExperience = member.experience;
      if (oldExperience == null) {
        throw StateError(
          'Party slot $slot must be hydrated before battle progression.',
        );
      }
      if (member.currentHp > metadata.oldMaxHp) {
        throw StateError(
          'Party slot $slot current HP exceeds its pre-battle maximum.',
        );
      }

      final curve = PokemonExperienceCurve.fromId(metadata.growthRateId);
      final minimumForPersistedLevel =
          curve.totalExperienceForLevel(member.level);
      if (oldExperience < minimumForPersistedLevel) {
        throw StateError(
          'Party slot $slot experience is below its persisted level floor.',
        );
      }
      final capExperience = curve.totalExperienceForLevel(100);
      if (oldExperience > capExperience) {
        throw StateError(
          'Party slot $slot experience exceeds its level-100 cap.',
        );
      }
      final experienceToCap = capExperience - oldExperience;
      final newExperience =
          oldExperience >= capExperience || grant.experience >= experienceToCap
              ? capExperience
              : oldExperience + grant.experience;
      final effectiveExperience = newExperience - oldExperience;
      final newLevel = curve.levelForExperience(newExperience);
      final calculatedStats = statCalculator.calculate(
        baseStats: metadata.baseStats,
        ivs: member.ivs,
        evs: member.evs,
        level: newLevel,
      );
      final newCurrentHp = newLevel == member.level
          ? member.currentHp
          : _currentHpAfterLevelUp(
              oldCurrentHp: member.currentHp,
              oldMaxHp: metadata.oldMaxHp,
              newMaxHp: calculatedStats.maxHp,
            );

      nextMembers[slot] = member.copyWith(
        experience: newExperience,
        level: newLevel,
        currentHp: newCurrentHp,
      );
      effectiveGrants.add(
        BattleExperienceGrant(
          partySlot: slot,
          experience: effectiveExperience,
        ),
      );
      changes.add(
        BattlePokemonProgressionChange(
          partySlot: slot,
          experienceAwarded: effectiveExperience,
          oldExperience: oldExperience,
          newExperience: newExperience,
          oldLevel: member.level,
          newLevel: newLevel,
          oldMaxHp: metadata.oldMaxHp,
          newCurrentHp: newCurrentHp,
          calculatedStats: calculatedStats,
        ),
      );
    }

    final progressedState = state.copyWith(
      party: state.party.copyWith(members: nextMembers),
    );
    final appliedReward = _rewardWithExperience(reward, effectiveGrants);
    return BattleProgressionResult(
      state: mutations.applyBattleRewards(
        progressedState,
        reward: appliedReward,
      ),
      appliedReward: appliedReward,
      changes: changes,
    );
  }
}

Map<int, BattleProgressionPartySlotMetadata> _metadataBySlot(
  Iterable<BattleProgressionPartySlotMetadata> metadata,
) {
  final bySlot = <int, BattleProgressionPartySlotMetadata>{};
  for (final entry in metadata.map((entry) => entry.validated())) {
    if (bySlot.containsKey(entry.partySlot)) {
      throw ArgumentError.value(
        entry.partySlot,
        'partySlotMetadata',
        'contains a duplicate party slot',
      );
    }
    bySlot[entry.partySlot] = entry;
  }
  return bySlot;
}

int _totalExperience({
  required Iterable<BattleProgressionDefeatedOpponent> opponents,
  required BattleRewardSourceKind sourceKind,
}) {
  // Dart VM integers are arbitrary precision, while web targets use a bounded
  // safe integer range. Saturating here keeps the split deterministic across
  // both targets without allowing an authored opponent list to overflow.
  const maxSafeExperience = 0x1fffffffffffff;
  var total = 0;
  for (final opponent in opponents) {
    final validated = opponent.validated();
    final earned = switch (sourceKind) {
      BattleRewardSourceKind.wild =>
        (validated.level * validated.baseExperience) ~/ 7,
      BattleRewardSourceKind.trainer =>
        (validated.level * validated.baseExperience * 3) ~/ 14,
    };
    if (earned >= maxSafeExperience - total) return maxSafeExperience;
    total += earned;
  }
  return total;
}

int _currentHpAfterLevelUp({
  required int oldCurrentHp,
  required int oldMaxHp,
  required int newMaxHp,
}) {
  if (oldCurrentHp <= 0) return 0;
  final absoluteDamage = oldMaxHp - oldCurrentHp;
  final next = newMaxHp - absoluteDamage;
  return next < 0 ? 0 : next;
}

BattleReward _rewardWithExperience(
  BattleReward reward,
  Iterable<BattleExperienceGrant> grants,
) {
  return BattleReward(
    sourceKind: reward.sourceKind,
    trainerId: reward.trainerId,
    experienceGrants: grants,
    money: reward.money,
    itemGrants: reward.itemGrants,
    flagIds: reward.flagIds,
    badgeId: reward.badgeId,
    fieldAbilityUnlock: reward.fieldAbilityUnlock,
  );
}

BattleReward _emptyRewardLike(BattleReward reward) {
  return BattleReward(
    sourceKind: reward.sourceKind,
    trainerId: reward.trainerId,
  );
}
