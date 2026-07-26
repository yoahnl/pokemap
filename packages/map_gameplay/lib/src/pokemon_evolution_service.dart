import 'package:map_core/map_core.dart';

import 'pokemon_stat_calculator.dart';

/// One catalogue-backed level evolution available to pure gameplay.
///
/// Runtime resolves JSON and target-species metadata. Gameplay receives no
/// paths or untyped catalogue maps.
final class PokemonEvolutionCandidate {
  PokemonEvolutionCandidate({
    required this.opportunityId,
    required this.sourceSpeciesId,
    required this.targetSpeciesId,
    required this.minLevel,
    required this.targetBaseStats,
    required this.targetPrimaryAbilityId,
    required Iterable<String> targetAbilityIds,
  }) : targetAbilityIds = List<String>.unmodifiable(targetAbilityIds);

  final String opportunityId;
  final String sourceSpeciesId;
  final String targetSpeciesId;
  final int minLevel;
  final PokemonBaseStats targetBaseStats;
  final String targetPrimaryAbilityId;
  final List<String> targetAbilityIds;

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
    RangeError.checkValueInInterval(minLevel, 2, 100, 'minLevel');
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
        _sameStrings(normalizedAbilityIds, targetAbilityIds)) {
      return this;
    }
    return PokemonEvolutionCandidate(
      opportunityId: normalizedOpportunityId,
      sourceSpeciesId: normalizedSourceSpeciesId,
      targetSpeciesId: normalizedTargetSpeciesId,
      minLevel: minLevel,
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
  }) {
    final validatedCandidate = candidate.validated();
    RangeError.checkValueInInterval(sourceMaxHp, 1, 9999, 'sourceMaxHp');
    if (pokemon.speciesId != validatedCandidate.sourceSpeciesId) {
      throw StateError(
        'Evolution source does not match the current Pokemon species.',
      );
    }
    if (pokemon.level < validatedCandidate.minLevel) {
      throw StateError('Pokemon has not reached the evolution level.');
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
