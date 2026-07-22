import 'package:map_core/map_core.dart';

/// Origine gameplay explicite d'une récompense de combat.
enum BattleRewardSourceKind { wild, trainer }

/// XP attribuée à un slot exact de l'équipe joueur.
final class BattleExperienceGrant {
  const BattleExperienceGrant({
    required this.partySlot,
    required this.experience,
  });

  final int partySlot;
  final int experience;

  BattleExperienceGrant validated() {
    if (partySlot < 0) {
      throw ArgumentError.value(
        partySlot,
        'partySlot',
        'must be non-negative',
      );
    }
    if (experience < 0) {
      throw ArgumentError.value(
        experience,
        'experience',
        'must be non-negative',
      );
    }
    return this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BattleExperienceGrant &&
          partySlot == other.partySlot &&
          experience == other.experience;

  @override
  int get hashCode => Object.hash(partySlot, experience);
}

/// Quantité typée d'un item accordé après le combat.
final class BattleRewardItemGrant {
  const BattleRewardItemGrant({
    required this.itemId,
    required this.quantity,
  });

  final String itemId;
  final int quantity;

  BattleRewardItemGrant validated() {
    final normalizedItemId = itemId.trim();
    if (normalizedItemId.isEmpty) {
      throw ArgumentError.value(itemId, 'itemId', 'must not be empty');
    }
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'must be positive');
    }
    if (normalizedItemId == itemId) {
      return this;
    }
    return BattleRewardItemGrant(
      itemId: normalizedItemId,
      quantity: quantity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BattleRewardItemGrant &&
          itemId == other.itemId &&
          quantity == other.quantity;

  @override
  int get hashCode => Object.hash(itemId, quantity);
}

/// Contrat pur des récompenses produites par la résolution d'un combat.
///
/// Ce modèle ne dépend volontairement pas de `map_battle`. Le runtime pourra
/// convertir un outcome battle vers ce contrat, puis les prochains lots
/// appliqueront la progression et sa présentation de façon transactionnelle.
final class BattleReward {
  factory BattleReward({
    required BattleRewardSourceKind sourceKind,
    String? trainerId,
    Iterable<BattleExperienceGrant> experienceGrants = const [],
    int money = 0,
    Iterable<BattleRewardItemGrant> itemGrants = const [],
    Iterable<String> flagIds = const [],
    String? badgeId,
    FieldAbility? fieldAbilityUnlock,
  }) {
    final normalizedTrainerId = trainerId?.trim();
    switch (sourceKind) {
      case BattleRewardSourceKind.wild:
        if (trainerId != null) {
          throw ArgumentError.value(
            trainerId,
            'trainerId',
            'must be absent for a wild battle reward',
          );
        }
      case BattleRewardSourceKind.trainer:
        if (normalizedTrainerId == null || normalizedTrainerId.isEmpty) {
          throw ArgumentError.value(
            trainerId,
            'trainerId',
            'must identify the defeated trainer',
          );
        }
    }
    if (money < 0) {
      throw ArgumentError.value(money, 'money', 'must be non-negative');
    }

    final normalizedExperienceGrants = experienceGrants
        .map((grant) => grant.validated())
        .toList(growable: false)
      ..sort((left, right) => left.partySlot.compareTo(right.partySlot));
    final occupiedSlots = <int>{};
    for (final grant in normalizedExperienceGrants) {
      if (!occupiedSlots.add(grant.partySlot)) {
        throw ArgumentError.value(
          grant.partySlot,
          'experienceGrants',
          'contains a duplicate party slot',
        );
      }
    }

    final normalizedItemGrants = itemGrants
        .map((grant) => grant.validated())
        .toList(growable: false)
      ..sort((left, right) => left.itemId.compareTo(right.itemId));
    final grantedItemIds = <String>{};
    for (final grant in normalizedItemGrants) {
      if (!grantedItemIds.add(grant.itemId)) {
        throw ArgumentError.value(
          grant.itemId,
          'itemGrants',
          'contains a duplicate item id',
        );
      }
    }
    final normalizedFlagIds = <String>{};
    for (final rawFlagId in flagIds) {
      final flagId = rawFlagId.trim();
      if (flagId.isEmpty) {
        throw ArgumentError.value(rawFlagId, 'flagIds', 'must not be empty');
      }
      normalizedFlagIds.add(flagId);
    }
    final sortedFlagIds = normalizedFlagIds.toList(growable: false)..sort();

    final normalizedBadgeId = badgeId?.trim();
    if (badgeId != null && normalizedBadgeId!.isEmpty) {
      throw ArgumentError.value(badgeId, 'badgeId', 'must not be empty');
    }

    return BattleReward._(
      sourceKind: sourceKind,
      trainerId: normalizedTrainerId,
      experienceGrants: List<BattleExperienceGrant>.unmodifiable(
        normalizedExperienceGrants,
      ),
      money: money,
      itemGrants: List<BattleRewardItemGrant>.unmodifiable(
        normalizedItemGrants,
      ),
      flagIds: List<String>.unmodifiable(sortedFlagIds),
      badgeId: normalizedBadgeId,
      fieldAbilityUnlock: fieldAbilityUnlock,
    );
  }

  const BattleReward._({
    required this.sourceKind,
    required this.trainerId,
    required this.experienceGrants,
    required this.money,
    required this.itemGrants,
    required this.flagIds,
    required this.badgeId,
    required this.fieldAbilityUnlock,
  });

  final BattleRewardSourceKind sourceKind;
  final String? trainerId;
  final List<BattleExperienceGrant> experienceGrants;
  final int money;
  final List<BattleRewardItemGrant> itemGrants;

  /// Flags à positionner. La collection est dédupliquée : la récompense est
  /// donc idempotente même si une source auteur répète un flag.
  final List<String> flagIds;
  final String? badgeId;
  final FieldAbility? fieldAbilityUnlock;

  bool get isEmpty =>
      experienceGrants.isEmpty &&
      money == 0 &&
      itemGrants.isEmpty &&
      flagIds.isEmpty &&
      badgeId == null &&
      fieldAbilityUnlock == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BattleReward &&
          sourceKind == other.sourceKind &&
          trainerId == other.trainerId &&
          _listsHaveEqualContent(
            experienceGrants,
            other.experienceGrants,
          ) &&
          money == other.money &&
          _listsHaveEqualContent(itemGrants, other.itemGrants) &&
          _listsHaveEqualContent(flagIds, other.flagIds) &&
          badgeId == other.badgeId &&
          fieldAbilityUnlock == other.fieldAbilityUnlock;

  @override
  int get hashCode => Object.hash(
        sourceKind,
        trainerId,
        Object.hashAll(experienceGrants),
        money,
        Object.hashAll(itemGrants),
        Object.hashAll(flagIds),
        badgeId,
        fieldAbilityUnlock,
      );
}

bool _listsHaveEqualContent<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
