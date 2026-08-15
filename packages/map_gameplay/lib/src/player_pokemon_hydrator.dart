import 'package:map_core/map_core.dart';

import 'pokemon_experience_curve.dart';
import 'pokemon_stat_calculator.dart';
import 'pokemon_gameplay_rules.dart';

enum PlayerPokemonHydrationOrigin {
  newGame,
  starter,
  gift,
  capture,
  legacySave,
  scripted,
}

enum PlayerPokemonHydrationDiagnosticSeverity { warning, error }

enum PlayerPokemonHydrationDiagnosticCode {
  unsupportedRuleset,
  unknownSpecies,
  invalidLevel,
  invalidFriendship,
  invalidNature,
  invalidAbility,
  tooManyMoves,
  duplicateMove,
  emptyMoveId,
  unknownMove,
  invalidMovePp,
  negativeCurrentPp,
  ppForUnlearnedMove,
  missingGrowthRate,
  unsupportedGrowthRate,
  negativeExperience,
  inconsistentExperience,
  negativeCurrentHp,
  invalidIndividual,
  natureResolved,
  abilityResolved,
}

final class PlayerPokemonHydrationDiagnostic {
  const PlayerPokemonHydrationDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.speciesId,
    this.moveId,
  });

  final PlayerPokemonHydrationDiagnosticCode code;
  final PlayerPokemonHydrationDiagnosticSeverity severity;
  final String message;
  final String speciesId;
  final String? moveId;
}

final class PlayerPokemonHydrationSpecies {
  const PlayerPokemonHydrationSpecies({
    required this.id,
    required this.baseStats,
    required this.primaryAbilityId,
    required this.abilityIds,
    required this.growthRateId,
  });

  final String id;
  final PokemonBaseStats baseStats;
  final String primaryAbilityId;
  final List<String> abilityIds;
  final String growthRateId;
}

final class PlayerPokemonHydrationCatalogs {
  const PlayerPokemonHydrationCatalogs({
    required this.speciesById,
    required this.maxPpByMoveId,
  });

  final Map<String, PlayerPokemonHydrationSpecies> speciesById;
  final Map<String, int> maxPpByMoveId;
}

final class PlayerPokemonHydrationResult {
  PlayerPokemonHydrationResult({
    required this.pokemon,
    required List<PlayerPokemonHydrationDiagnostic> diagnostics,
  }) : diagnostics = List<PlayerPokemonHydrationDiagnostic>.unmodifiable(
          diagnostics,
        );

  final PlayerPokemon? pokemon;
  final List<PlayerPokemonHydrationDiagnostic> diagnostics;

  bool get hasErrors => diagnostics.any(
        (diagnostic) =>
            diagnostic.severity ==
            PlayerPokemonHydrationDiagnosticSeverity.error,
      );
}

final class PlayerPokemonHydrator {
  const PlayerPokemonHydrator({
    this.statCalculator = const PokemonStatCalculator(),
  });

  final PokemonStatCalculator statCalculator;

  PlayerPokemonHydrationResult hydrate({
    required PlayerPokemon pokemon,
    required PlayerPokemonHydrationCatalogs catalogs,
    required PokemonRulesetProfile ruleset,
    required PlayerPokemonHydrationOrigin origin,
  }) {
    final diagnostics = <PlayerPokemonHydrationDiagnostic>[];
    final speciesId = pokemon.speciesId.trim();

    void error(
      PlayerPokemonHydrationDiagnosticCode code,
      String message, {
      String? moveId,
    }) {
      diagnostics.add(
        PlayerPokemonHydrationDiagnostic(
          code: code,
          severity: PlayerPokemonHydrationDiagnosticSeverity.error,
          message: message,
          speciesId: speciesId,
          moveId: moveId,
        ),
      );
    }

    void warning(
      PlayerPokemonHydrationDiagnosticCode code,
      String message,
    ) {
      diagnostics.add(
        PlayerPokemonHydrationDiagnostic(
          code: code,
          severity: PlayerPokemonHydrationDiagnosticSeverity.warning,
          message: message,
          speciesId: speciesId,
        ),
      );
    }

    PokemonGameplayRules? rules;
    try {
      rules = PokemonGameplayRules.fromProfile(ruleset);
    } on FormatException catch (exception) {
      error(
        PlayerPokemonHydrationDiagnosticCode.unsupportedRuleset,
        exception.message,
      );
    }

    final species = catalogs.speciesById[speciesId];
    if (species == null) {
      error(
        PlayerPokemonHydrationDiagnosticCode.unknownSpecies,
        'Pokemon species "$speciesId" is absent from the project catalog.',
      );
      return PlayerPokemonHydrationResult(
        pokemon: null,
        diagnostics: diagnostics,
      );
    }

    if (rules != null &&
        (pokemon.level < 1 || pokemon.level > rules.maxLevel)) {
      error(
        PlayerPokemonHydrationDiagnosticCode.invalidLevel,
        'Pokemon level must be between 1 and ${rules.maxLevel}.',
      );
    }
    if (rules != null) {
      try {
        rules.validatedFriendship(pokemon.friendship);
      } on RangeError {
        error(
          PlayerPokemonHydrationDiagnosticCode.invalidFriendship,
          'Pokemon friendship must be between 0 and 255.',
        );
      }
    }

    var natureId = pokemon.natureId.trim().toLowerCase();
    if (!canonicalPokemonNatureIds.contains(natureId)) {
      if (natureId.isEmpty || natureId == 'unknown') {
        natureId = 'hardy';
        warning(
          PlayerPokemonHydrationDiagnosticCode.natureResolved,
          '${origin.name} nature sentinel was resolved to hardy.',
        );
      } else {
        error(
          PlayerPokemonHydrationDiagnosticCode.invalidNature,
          'Pokemon nature "$natureId" is not canonical.',
        );
      }
    }

    final abilityIds = <String>{
      for (final abilityId in species.abilityIds)
        if (abilityId.trim().isNotEmpty) abilityId.trim(),
    };
    final primaryAbilityId = species.primaryAbilityId.trim();
    var abilityId = pokemon.abilityId.trim();
    if (!abilityIds.contains(abilityId)) {
      if ((abilityId.isEmpty || abilityId == 'unknown') &&
          abilityIds.contains(primaryAbilityId)) {
        abilityId = primaryAbilityId;
        warning(
          PlayerPokemonHydrationDiagnosticCode.abilityResolved,
          '${origin.name} ability sentinel was resolved to the species primary ability.',
        );
      } else {
        error(
          PlayerPokemonHydrationDiagnosticCode.invalidAbility,
          'Pokemon ability "$abilityId" is not valid for "$speciesId".',
        );
      }
    }

    if (pokemon.knownMoveIds.length > 4) {
      error(
        PlayerPokemonHydrationDiagnosticCode.tooManyMoves,
        'Pokemon cannot know more than four moves.',
      );
    }
    final knownMoveIds = <String>[];
    final knownMoveIdSet = <String>{};
    for (final rawMoveId in pokemon.knownMoveIds) {
      final moveId = rawMoveId.trim();
      if (moveId.isEmpty) {
        error(
          PlayerPokemonHydrationDiagnosticCode.emptyMoveId,
          'Known move ids must not be empty.',
          moveId: rawMoveId,
        );
        continue;
      }
      if (!knownMoveIdSet.add(moveId)) {
        error(
          PlayerPokemonHydrationDiagnosticCode.duplicateMove,
          'Known move "$moveId" is duplicated.',
          moveId: moveId,
        );
        continue;
      }
      final maxPp = catalogs.maxPpByMoveId[moveId];
      if (maxPp == null) {
        error(
          PlayerPokemonHydrationDiagnosticCode.unknownMove,
          'Known move "$moveId" is absent from the project catalog.',
          moveId: moveId,
        );
      } else if (maxPp <= 0) {
        error(
          PlayerPokemonHydrationDiagnosticCode.invalidMovePp,
          'Known move "$moveId" must expose a positive PP maximum.',
          moveId: moveId,
        );
      }
      knownMoveIds.add(moveId);
    }

    final persistedPp = <String, int>{};
    for (final entry
        in (pokemon.currentPpByMoveId ?? const <String, int>{}).entries) {
      final moveId = entry.key.trim();
      if (moveId.isEmpty) {
        error(
          PlayerPokemonHydrationDiagnosticCode.emptyMoveId,
          'Current PP move ids must not be empty.',
          moveId: entry.key,
        );
        continue;
      }
      if (persistedPp.containsKey(moveId)) {
        error(
          PlayerPokemonHydrationDiagnosticCode.duplicateMove,
          'Current PP move "$moveId" is duplicated after normalization.',
          moveId: moveId,
        );
        continue;
      }
      if (entry.value < 0) {
        error(
          PlayerPokemonHydrationDiagnosticCode.negativeCurrentPp,
          'Current PP must be non-negative.',
          moveId: moveId,
        );
      }
      if (!catalogs.maxPpByMoveId.containsKey(moveId)) {
        error(
          PlayerPokemonHydrationDiagnosticCode.unknownMove,
          'Current PP move "$moveId" is absent from the project catalog.',
          moveId: moveId,
        );
      } else if (!knownMoveIdSet.contains(moveId)) {
        error(
          PlayerPokemonHydrationDiagnosticCode.ppForUnlearnedMove,
          'Current PP references move "$moveId" which is not known.',
          moveId: moveId,
        );
      }
      persistedPp[moveId] = entry.value;
    }

    final currentPpByMoveId = <String, int>{};
    for (final moveId in knownMoveIds) {
      final maxPp = catalogs.maxPpByMoveId[moveId];
      if (maxPp == null || maxPp <= 0) continue;
      final currentPp = persistedPp[moveId] ?? maxPp;
      currentPpByMoveId[moveId] = currentPp.clamp(0, maxPp);
    }

    PokemonExperienceCurve? experienceCurve;
    final growthRateId = species.growthRateId.trim().toLowerCase();
    if (growthRateId.isEmpty) {
      error(
        PlayerPokemonHydrationDiagnosticCode.missingGrowthRate,
        'Pokemon species "$speciesId" has no growth rate.',
      );
    } else {
      try {
        experienceCurve = PokemonExperienceCurve.fromId(growthRateId);
      } on ArgumentError {
        error(
          PlayerPokemonHydrationDiagnosticCode.unsupportedGrowthRate,
          'Pokemon growth rate "$growthRateId" is not supported.',
        );
      }
    }

    var experience = pokemon.experience;
    if (experience != null && experience < 0) {
      error(
        PlayerPokemonHydrationDiagnosticCode.negativeExperience,
        'Pokemon experience must be non-negative.',
      );
    }
    if (experienceCurve != null &&
        pokemon.level >= 1 &&
        rules != null &&
        pokemon.level <= rules.maxLevel) {
      experience ??= experienceCurve.totalExperienceForLevel(pokemon.level);
      if (experience >= 0 &&
          experienceCurve.levelForExperience(
                experience,
                maxLevel: rules.maxLevel,
              ) !=
              pokemon.level) {
        error(
          PlayerPokemonHydrationDiagnosticCode.inconsistentExperience,
          'Pokemon experience does not resolve to persisted level ${pokemon.level}.',
        );
      }
    }

    var currentHp = pokemon.currentHp;
    if (currentHp < 0) {
      error(
        PlayerPokemonHydrationDiagnosticCode.negativeCurrentHp,
        'Pokemon current HP must be non-negative.',
      );
    } else if (pokemon.level >= 1 &&
        rules != null &&
        pokemon.level <= rules.maxLevel &&
        canonicalPokemonNatureIds.contains(natureId)) {
      try {
        final maxHp = statCalculator
            .calculate(
              baseStats: species.baseStats,
              ivs: pokemon.ivs,
              evs: pokemon.evs,
              level: pokemon.level,
              naturePolicy: PokemonNatureStatPolicy.canonical,
              natureId: natureId,
            )
            .maxHp;
        currentHp = currentHp.clamp(0, maxHp);
      } on Object catch (exception) {
        error(
          PlayerPokemonHydrationDiagnosticCode.invalidIndividual,
          'Pokemon stats cannot be calculated: $exception',
        );
      }
    }

    if (diagnostics.any(
      (diagnostic) =>
          diagnostic.severity == PlayerPokemonHydrationDiagnosticSeverity.error,
    )) {
      return PlayerPokemonHydrationResult(
        pokemon: null,
        diagnostics: diagnostics,
      );
    }

    PlayerPokemon canonical;
    try {
      canonical = pokemon
          .copyWith(
            speciesId: speciesId,
            natureId: natureId,
            abilityId: abilityId,
            knownMoveIds: knownMoveIds,
            experience: experience,
            currentPpByMoveId: currentPpByMoveId,
            currentHp: currentHp,
          )
          .normalized();
    } on Object catch (exception) {
      error(
        PlayerPokemonHydrationDiagnosticCode.invalidIndividual,
        'Pokemon individual is invalid: $exception',
      );
      return PlayerPokemonHydrationResult(
        pokemon: null,
        diagnostics: diagnostics,
      );
    }

    return PlayerPokemonHydrationResult(
      pokemon: canonical,
      diagnostics: diagnostics,
    );
  }
}
