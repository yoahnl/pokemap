import 'package:map_core/map_core.dart';

import 'items/bag_operation_result.dart';
import 'items/bag_operations.dart';
import 'items/item_catalog_snapshot.dart';
import 'pokemon_stat_calculator.dart';

enum PokemonEvolutionTriggerKind {
  levelUp,
  itemUse,
}

final class PokemonEvolutionTrigger {
  const PokemonEvolutionTrigger.levelUp()
      : kind = PokemonEvolutionTriggerKind.levelUp,
        itemId = null;

  const PokemonEvolutionTrigger.itemUse(this.itemId)
      : kind = PokemonEvolutionTriggerKind.itemUse;

  final PokemonEvolutionTriggerKind kind;
  final String? itemId;

  PokemonEvolutionTrigger validated() {
    if (kind == PokemonEvolutionTriggerKind.levelUp) return this;
    final normalizedItemId = itemId?.trim() ?? '';
    if (normalizedItemId.isEmpty) {
      throw ArgumentError.value(itemId, 'itemId', 'must not be empty');
    }
    return normalizedItemId == itemId
        ? this
        : PokemonEvolutionTrigger.itemUse(normalizedItemId);
  }
}

enum PokemonEvolutionConditionKind {
  level,
  friendship,
  item,
  knownMove,
}

/// One supported, serializable evolution condition.
///
/// V1 intentionally supports only deterministic conditions owned by current
/// player state. Runtime loaders reject malformed supported rules and ignore
/// explicitly unsupported catalogue methods.
final class PokemonEvolutionCondition {
  const PokemonEvolutionCondition.level({
    required this.minLevel,
  })  : kind = PokemonEvolutionConditionKind.level,
        minFriendship = null,
        itemId = null,
        moveId = null;

  const PokemonEvolutionCondition.friendship({
    required this.minFriendship,
    this.minLevel = 2,
  })  : kind = PokemonEvolutionConditionKind.friendship,
        itemId = null,
        moveId = null;

  const PokemonEvolutionCondition.item({
    required this.itemId,
    this.minLevel = 1,
  })  : kind = PokemonEvolutionConditionKind.item,
        minFriendship = null,
        moveId = null;

  const PokemonEvolutionCondition.knownMove({
    required this.moveId,
    this.minLevel = 2,
  })  : kind = PokemonEvolutionConditionKind.knownMove,
        minFriendship = null,
        itemId = null;

  final PokemonEvolutionConditionKind kind;
  final int minLevel;
  final int? minFriendship;
  final String? itemId;
  final String? moveId;

  PokemonEvolutionCondition validated() {
    final minimumLevel = kind == PokemonEvolutionConditionKind.item ? 1 : 2;
    RangeError.checkValueInInterval(
      minLevel,
      minimumLevel,
      100,
      'minLevel',
    );
    switch (kind) {
      case PokemonEvolutionConditionKind.level:
        return this;
      case PokemonEvolutionConditionKind.friendship:
        RangeError.checkValueInInterval(
          minFriendship!,
          1,
          255,
          'minFriendship',
        );
        return this;
      case PokemonEvolutionConditionKind.item:
        final normalizedItemId = itemId?.trim() ?? '';
        if (normalizedItemId.isEmpty) {
          throw ArgumentError.value(itemId, 'itemId', 'must not be empty');
        }
        return normalizedItemId == itemId
            ? this
            : PokemonEvolutionCondition.item(
                itemId: normalizedItemId,
                minLevel: minLevel,
              );
      case PokemonEvolutionConditionKind.knownMove:
        final normalizedMoveId = moveId?.trim() ?? '';
        if (normalizedMoveId.isEmpty) {
          throw ArgumentError.value(moveId, 'moveId', 'must not be empty');
        }
        return normalizedMoveId == moveId
            ? this
            : PokemonEvolutionCondition.knownMove(
                moveId: normalizedMoveId,
                minLevel: minLevel,
              );
    }
  }

  bool isSatisfiedBy(
    PlayerPokemon pokemon, {
    required PokemonEvolutionTrigger trigger,
  }) {
    final condition = validated();
    final event = trigger.validated();
    if (pokemon.level < condition.minLevel) return false;
    return switch (condition.kind) {
      PokemonEvolutionConditionKind.level =>
        event.kind == PokemonEvolutionTriggerKind.levelUp,
      PokemonEvolutionConditionKind.friendship =>
        event.kind == PokemonEvolutionTriggerKind.levelUp &&
            pokemon.friendship >= condition.minFriendship!,
      PokemonEvolutionConditionKind.item =>
        event.kind == PokemonEvolutionTriggerKind.itemUse &&
            event.itemId == condition.itemId,
      PokemonEvolutionConditionKind.knownMove =>
        event.kind == PokemonEvolutionTriggerKind.levelUp &&
            pokemon.knownMoveIds.contains(condition.moveId),
    };
  }
}

PokemonEvolutionCondition _resolveEvolutionCondition(
  int? minLevel,
  PokemonEvolutionCondition? condition,
) {
  if (condition != null && minLevel != null) {
    throw ArgumentError(
      'Provide either minLevel or condition, not both.',
    );
  }
  if (condition != null) return condition;
  if (minLevel != null) {
    return PokemonEvolutionCondition.level(minLevel: minLevel);
  }
  throw ArgumentError('An evolution condition is required.');
}

/// One catalogue-backed evolution available to pure gameplay.
///
/// Runtime resolves JSON and target-species metadata. Gameplay receives no
/// paths or untyped catalogue maps.
final class PokemonEvolutionCandidate {
  PokemonEvolutionCandidate({
    required this.opportunityId,
    required this.sourceSpeciesId,
    required this.targetSpeciesId,
    int? minLevel,
    PokemonEvolutionCondition? condition,
    required this.targetBaseStats,
    required this.targetPrimaryAbilityId,
    required Iterable<String> targetAbilityIds,
  })  : condition = _resolveEvolutionCondition(minLevel, condition),
        targetAbilityIds = List<String>.unmodifiable(targetAbilityIds);

  final String opportunityId;
  final String sourceSpeciesId;
  final String targetSpeciesId;
  final PokemonEvolutionCondition condition;
  final PokemonBaseStats targetBaseStats;
  final String targetPrimaryAbilityId;
  final List<String> targetAbilityIds;

  int get minLevel => condition.minLevel;

  bool isEligible(
    PlayerPokemon pokemon, {
    required PokemonEvolutionTrigger trigger,
  }) {
    return pokemon.speciesId == sourceSpeciesId &&
        condition.isSatisfiedBy(pokemon, trigger: trigger);
  }

  PokemonEvolutionCandidate validated() {
    final normalizedOpportunityId = opportunityId.trim();
    final normalizedSourceSpeciesId = sourceSpeciesId.trim();
    final normalizedTargetSpeciesId = targetSpeciesId.trim();
    final normalizedPrimaryAbilityId = targetPrimaryAbilityId.trim();
    if (normalizedOpportunityId.isEmpty) {
      throw ArgumentError.value(
        opportunityId,
        'opportunityId',
        'must not be empty',
      );
    }
    if (normalizedSourceSpeciesId.isEmpty) {
      throw ArgumentError.value(
        sourceSpeciesId,
        'sourceSpeciesId',
        'must not be empty',
      );
    }
    if (normalizedTargetSpeciesId.isEmpty ||
        normalizedTargetSpeciesId == normalizedSourceSpeciesId) {
      throw ArgumentError.value(
        targetSpeciesId,
        'targetSpeciesId',
        'must be non-empty and different from sourceSpeciesId',
      );
    }
    final validatedCondition = condition.validated();
    targetBaseStats.validated();
    if (normalizedPrimaryAbilityId.isEmpty) {
      throw ArgumentError.value(
        targetPrimaryAbilityId,
        'targetPrimaryAbilityId',
        'must not be empty',
      );
    }

    final normalizedAbilityIds = <String>[];
    final seenAbilityIds = <String>{};
    for (final rawAbilityId in targetAbilityIds) {
      final abilityId = rawAbilityId.trim();
      if (abilityId.isEmpty || !seenAbilityIds.add(abilityId)) {
        throw ArgumentError.value(
          targetAbilityIds,
          'targetAbilityIds',
          'must contain unique non-empty ids',
        );
      }
      normalizedAbilityIds.add(abilityId);
    }
    if (!seenAbilityIds.contains(normalizedPrimaryAbilityId)) {
      throw ArgumentError.value(
        targetAbilityIds,
        'targetAbilityIds',
        'must contain targetPrimaryAbilityId',
      );
    }

    if (normalizedOpportunityId == opportunityId &&
        normalizedSourceSpeciesId == sourceSpeciesId &&
        normalizedTargetSpeciesId == targetSpeciesId &&
        normalizedPrimaryAbilityId == targetPrimaryAbilityId &&
        identical(validatedCondition, condition) &&
        _sameStrings(normalizedAbilityIds, targetAbilityIds)) {
      return this;
    }
    return PokemonEvolutionCandidate(
      opportunityId: normalizedOpportunityId,
      sourceSpeciesId: normalizedSourceSpeciesId,
      targetSpeciesId: normalizedTargetSpeciesId,
      condition: validatedCondition,
      targetBaseStats: targetBaseStats,
      targetPrimaryAbilityId: normalizedPrimaryAbilityId,
      targetAbilityIds: normalizedAbilityIds,
    );
  }
}

/// Pure result of accepting one evolution.
final class PokemonEvolutionResult {
  const PokemonEvolutionResult({
    required this.pokemon,
    required this.previousMaxHp,
    required this.calculatedStats,
  });

  final PlayerPokemon pokemon;
  final int previousMaxHp;
  final PokemonCalculatedStats calculatedStats;
}

/// Applies one previously resolved evolution without catalogue IO.
final class PokemonEvolutionService {
  const PokemonEvolutionService({
    this.statCalculator = const PokemonStatCalculator(),
  });

  final PokemonStatCalculator statCalculator;

  PokemonEvolutionResult evolve({
    required PlayerPokemon pokemon,
    required PokemonEvolutionCandidate candidate,
    required int sourceMaxHp,
    PokemonEvolutionTrigger trigger = const PokemonEvolutionTrigger.levelUp(),
  }) {
    final validatedCandidate = candidate.validated();
    RangeError.checkValueInInterval(sourceMaxHp, 1, 9999, 'sourceMaxHp');
    if (pokemon.speciesId != validatedCandidate.sourceSpeciesId) {
      throw StateError(
        'Evolution source does not match the current Pokemon species.',
      );
    }
    if (!validatedCandidate.isEligible(pokemon, trigger: trigger)) {
      throw StateError('Pokemon does not meet the evolution condition.');
    }
    if (pokemon.currentHp < 0 || pokemon.currentHp > sourceMaxHp) {
      throw StateError('Pokemon current HP is outside its source maximum.');
    }

    // Evolution keeps the same persisted identity and stat determinants. The
    // target species therefore receives the exact canonical nature modifier
    // instead of momentarily using a neutral projection.
    final targetStats = statCalculator.calculate(
      baseStats: validatedCandidate.targetBaseStats,
      ivs: pokemon.ivs,
      evs: pokemon.evs,
      level: pokemon.level,
      naturePolicy: PokemonNatureStatPolicy.canonical,
      natureId: pokemon.natureId,
    );
    final abilityId =
        validatedCandidate.targetAbilityIds.contains(pokemon.abilityId)
            ? pokemon.abilityId
            : validatedCandidate.targetPrimaryAbilityId;
    final targetCurrentHp = _preserveHpRatio(
      currentHp: pokemon.currentHp,
      sourceMaxHp: sourceMaxHp,
      targetMaxHp: targetStats.maxHp,
    );

    return PokemonEvolutionResult(
      pokemon: pokemon.copyWith(
        speciesId: validatedCandidate.targetSpeciesId,
        abilityId: abilityId,
        currentHp: targetCurrentHp,
      ),
      previousMaxHp: sourceMaxHp,
      calculatedStats: targetStats,
    );
  }
}

enum PokemonEvolutionItemUseFailure {
  invalidRequest,
  invalidTarget,
  insufficientQuantity,
  protectedKeyItem,
  conditionNotMet,
  ambiguousCandidate,
}

final class PokemonEvolutionItemUseResult {
  const PokemonEvolutionItemUseResult._({
    required this.state,
    this.failure,
    this.evolution,
    this.consumptionReceipt,
  });

  const PokemonEvolutionItemUseResult.success(
    GameState state,
    PokemonEvolutionResult evolution,
    ItemConsumptionReceipt consumptionReceipt,
  ) : this._(
          state: state,
          evolution: evolution,
          consumptionReceipt: consumptionReceipt,
        );

  const PokemonEvolutionItemUseResult.failed(
    GameState state,
    PokemonEvolutionItemUseFailure failure,
  ) : this._(state: state, failure: failure);

  final GameState state;
  final PokemonEvolutionItemUseFailure? failure;
  final PokemonEvolutionResult? evolution;
  final ItemConsumptionReceipt? consumptionReceipt;

  bool get isSuccess => failure == null;
}

/// Atomically evolves one party member and consumes exactly one matching item.
final class PokemonEvolutionItemOperations {
  const PokemonEvolutionItemOperations({
    this.evolutionService = const PokemonEvolutionService(),
  });

  final PokemonEvolutionService evolutionService;
  static const _bagOperations = BagOperations();

  PokemonEvolutionItemUseResult useItem(
    GameState state, {
    required String itemId,
    required int partyIndex,
    required PokemonEvolutionCandidate candidate,
    required int sourceMaxHp,
    required ItemCatalogSnapshot itemCatalog,
  }) {
    final normalizedItemId = itemId.trim();
    if (normalizedItemId.isEmpty || sourceMaxHp <= 0) {
      return PokemonEvolutionItemUseResult.failed(
        state,
        PokemonEvolutionItemUseFailure.invalidRequest,
      );
    }
    final definition = itemCatalog.definitionFor(normalizedItemId);
    if (definition == null) {
      return PokemonEvolutionItemUseResult.failed(
        state,
        PokemonEvolutionItemUseFailure.invalidRequest,
      );
    }
    if (partyIndex < 0 || partyIndex >= state.party.members.length) {
      return PokemonEvolutionItemUseResult.failed(
        state,
        PokemonEvolutionItemUseFailure.invalidTarget,
      );
    }
    if (_bagOperations.quantityOf(state.bag, normalizedItemId) <= 0) {
      return PokemonEvolutionItemUseResult.failed(
        state,
        PokemonEvolutionItemUseFailure.insufficientQuantity,
      );
    }
    final pokemon = state.party.members[partyIndex];
    final trigger = PokemonEvolutionTrigger.itemUse(normalizedItemId);
    if (!candidate.validated().isEligible(pokemon, trigger: trigger)) {
      return PokemonEvolutionItemUseResult.failed(
        state,
        PokemonEvolutionItemUseFailure.conditionNotMet,
      );
    }

    final evolution = evolutionService.evolve(
      pokemon: pokemon,
      candidate: candidate,
      sourceMaxHp: sourceMaxHp,
      trigger: trigger,
    );
    final consumption = _bagOperations.consume(
      BagConsumeRequest(
        bag: state.bag,
        itemId: normalizedItemId,
        quantity: 1,
        itemTags: definition.tags,
        reason: ItemConsumptionReason.appliedEffect,
      ),
    );
    if (!consumption.isSuccess) {
      return PokemonEvolutionItemUseResult.failed(
        state,
        consumption.failure == BagOperationFailure.protectedKeyItem
            ? PokemonEvolutionItemUseFailure.protectedKeyItem
            : PokemonEvolutionItemUseFailure.insufficientQuantity,
      );
    }
    final nextMembers = [...state.party.members];
    nextMembers[partyIndex] = evolution.pokemon;
    return PokemonEvolutionItemUseResult.success(
      state.copyWith(
        party: PlayerParty(members: nextMembers).normalized(),
        bag: consumption.bag,
      ),
      evolution,
      consumption.consumptionReceipt!,
    );
  }
}

/// Preserves the exact HP ratio using nearest-integer, half-up rounding.
///
/// KO remains KO, full health remains full, and every living Pokemon is
/// clamped to at least one HP.
int _preserveHpRatio({
  required int currentHp,
  required int sourceMaxHp,
  required int targetMaxHp,
}) {
  if (currentHp == 0) return 0;
  if (currentHp >= sourceMaxHp) return targetMaxHp;
  final numerator = currentHp * targetMaxHp;
  final rounded = ((2 * numerator) + sourceMaxHp) ~/ (2 * sourceMaxHp);
  return rounded.clamp(1, targetMaxHp).toInt();
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
