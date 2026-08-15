import 'package:map_core/map_core.dart';

import 'player_pokemon_hydrator.dart';
import 'pokemon_stat_calculator.dart';
import 'pokemon_gameplay_rules.dart';

final class WildPokemonGenerationProfile {
  const WildPokemonGenerationProfile._({
    required this.profileId,
    required this.schemaVersion,
    required this.shinyDenominator,
  });

  static const WildPokemonGenerationProfile pokeMapBetaV1 =
      WildPokemonGenerationProfile._(
    profileId: 'pokemap-wild-v1',
    schemaVersion: 1,
    shinyDenominator: 4096,
  );

  final String profileId;
  final int schemaVersion;
  final int shinyDenominator;

  static WildPokemonGenerationProfile forRuleset(
    PokemonRulesetProfile ruleset,
  ) {
    ruleset.requireSupported();
    return pokeMapBetaV1;
  }
}

final class WildPokemonGenerationSpecies {
  const WildPokemonGenerationSpecies({
    required this.id,
    this.formId = '',
    required this.baseStats,
    required this.primaryAbilityId,
    required this.standardAbilityIds,
    required this.allowedAbilityIds,
    required this.genderRatio,
    required this.growthRateId,
    required this.baseFriendship,
  });

  final String id;
  final String formId;
  final PokemonBaseStats baseStats;
  final String primaryAbilityId;
  final List<String> standardAbilityIds;
  final List<String> allowedAbilityIds;
  final Map<String, double> genderRatio;
  final String growthRateId;
  final int baseFriendship;
}

final class WildPokemonLevelUpMove {
  const WildPokemonLevelUpMove({
    required this.moveId,
    required this.level,
  });

  final String moveId;
  final int level;
}

final class WildPokemonGenerationLearnset {
  const WildPokemonGenerationLearnset({
    this.startingMoves = const <String>[],
    this.relearnMoves = const <String>[],
    this.levelUp = const <WildPokemonLevelUpMove>[],
  });

  final List<String> startingMoves;
  final List<String> relearnMoves;
  final List<WildPokemonLevelUpMove> levelUp;
}

final class WildPokemonGenerationContext {
  const WildPokemonGenerationContext({
    required this.mapId,
    required this.sourceId,
    this.individualKey = '',
  });

  final String mapId;
  final String sourceId;
  final String individualKey;
}

final class WildPlayerPokemonGenerationResult {
  const WildPlayerPokemonGenerationResult({
    required this.pokemon,
    required this.profileId,
    required this.schemaVersion,
    required this.seed,
  });

  final PlayerPokemon pokemon;
  final String profileId;
  final int schemaVersion;
  final int seed;
}

final class WildPlayerPokemonGenerator {
  const WildPlayerPokemonGenerator({
    this.hydrator = const PlayerPokemonHydrator(),
    this.statCalculator = const PokemonStatCalculator(),
  });

  final PlayerPokemonHydrator hydrator;
  final PokemonStatCalculator statCalculator;

  WildPlayerPokemonGenerationResult generate({
    required int seed,
    required WildPokemonGenerationSpecies species,
    required WildPokemonGenerationLearnset learnset,
    required Map<String, int> maxPpByMoveId,
    required int level,
    required PokemonRulesetProfile ruleset,
    required WildPokemonGenerationContext context,
    ProjectEncounterPokemonOverrides? overrides,
  }) {
    final profile = WildPokemonGenerationProfile.forRuleset(ruleset);
    final rules = PokemonGameplayRules.fromProfile(ruleset);
    final normalizedSpeciesId = species.id.trim();
    if (normalizedSpeciesId.isEmpty) {
      throw const FormatException('Wild Pokemon species id must not be empty.');
    }
    if (level < 1 || level > rules.maxLevel) {
      throw FormatException(
        'Wild Pokemon level must be between 1 and ${rules.maxLevel}.',
      );
    }
    try {
      rules.validatedFriendship(species.baseFriendship);
    } on RangeError {
      throw const FormatException(
        'Wild Pokemon base friendship must be between 0 and 255.',
      );
    }

    final standardAbilityIds = _normalizedUniqueIds(
      species.standardAbilityIds,
      label: 'standard ability',
    );
    final allowedAbilityIds = _normalizedUniqueIds(
      species.allowedAbilityIds,
      label: 'allowed ability',
    );
    final primaryAbilityId = species.primaryAbilityId.trim();
    if (standardAbilityIds.isEmpty ||
        primaryAbilityId.isEmpty ||
        standardAbilityIds.first != primaryAbilityId ||
        !allowedAbilityIds.toSet().containsAll(standardAbilityIds)) {
      throw const FormatException(
        'Wild Pokemon abilities must expose the primary ability first and remain allowed.',
      );
    }

    final rng = _WildGenerationRandom(seed);
    final randomNatureId = canonicalPokemonNatureIds[
        rng.nextInt(canonicalPokemonNatureIds.length)];
    final randomAbilityId =
        standardAbilityIds[rng.nextInt(standardAbilityIds.length)];
    final randomGender = _resolveGender(species.genderRatio, rng.nextUnit());
    final randomIvs = PokemonStatSpread(
      hp: rng.nextInt(32),
      attack: rng.nextInt(32),
      defense: rng.nextInt(32),
      specialAttack: rng.nextInt(32),
      specialDefense: rng.nextInt(32),
      speed: rng.nextInt(32),
    );
    final randomShiny = rng.nextInt(profile.shinyDenominator) == 0;

    final natureId = _resolveNature(overrides?.natureId, randomNatureId);
    final abilityId = _resolveAbility(
      overrides?.abilityId,
      randomAbilityId,
      allowedAbilityIds,
    );
    final gender = _resolveGenderOverride(
      overrides?.gender,
      randomGender,
      species.genderRatio,
    );
    final ivs = overrides?.ivs ?? randomIvs;
    _requireValidIvs(ivs);
    final isShiny =
        switch (overrides?.shinyPolicy ?? ProjectEncounterShinyPolicy.random) {
      ProjectEncounterShinyPolicy.random => randomShiny,
      ProjectEncounterShinyPolicy.never => false,
      ProjectEncounterShinyPolicy.always => true,
    };

    final learnableMoveIds = _learnableMoveIds(learnset, level);
    final authoredMoveIds = overrides?.knownMoveIds ?? const <String>[];
    final knownMoveIds = authoredMoveIds.isEmpty
        ? _lastFour(learnableMoveIds)
        : _resolveAuthoredMoveIds(authoredMoveIds, learnableMoveIds);
    for (final moveId in knownMoveIds) {
      final maxPp = maxPpByMoveId[moveId];
      if (maxPp == null || maxPp <= 0) {
        throw FormatException(
          'Wild Pokemon move "$moveId" requires a positive catalogue PP maximum.',
        );
      }
    }

    final maxHp = statCalculator
        .calculate(
          baseStats: species.baseStats,
          ivs: ivs,
          evs: const PokemonStatSpread(),
          level: level,
          naturePolicy: PokemonNatureStatPolicy.canonical,
          natureId: natureId,
        )
        .maxHp;
    final unresolvedCandidate = PlayerPokemon(
      speciesId: normalizedSpeciesId,
      formId: species.formId.trim(),
      natureId: natureId,
      abilityId: abilityId,
      gender: gender,
      level: level,
      ivs: ivs,
      knownMoveIds: knownMoveIds,
      currentPpByMoveId: <String, int>{
        for (final moveId in knownMoveIds) moveId: maxPpByMoveId[moveId]!,
      },
      currentHp: maxHp,
      isShiny: isShiny,
      friendship: species.baseFriendship,
      provenance: PlayerPokemonProvenance(
        mapId: context.mapId,
        sourceId: context.sourceId,
        metLevel: level,
      ),
    );
    final candidate = unresolvedCandidate.copyWith(
      individualId: deterministicPlayerPokemonIndividualId(
        saveId: 'wild',
        location: <Object>[
          context.mapId.trim(),
          context.sourceId.trim(),
          context.individualKey.trim(),
          normalizedSpeciesId,
          seed,
        ].join('|'),
        pokemon: unresolvedCandidate,
      ),
    );
    final hydration = hydrator.hydrate(
      pokemon: candidate,
      catalogs: PlayerPokemonHydrationCatalogs(
        speciesById: <String, PlayerPokemonHydrationSpecies>{
          normalizedSpeciesId: PlayerPokemonHydrationSpecies(
            id: normalizedSpeciesId,
            baseStats: species.baseStats,
            primaryAbilityId: primaryAbilityId,
            abilityIds: allowedAbilityIds,
            growthRateId: species.growthRateId,
          ),
        },
        maxPpByMoveId: maxPpByMoveId,
      ),
      ruleset: ruleset,
      origin: PlayerPokemonHydrationOrigin.capture,
    );
    final pokemon = hydration.pokemon;
    if (pokemon == null || hydration.hasErrors) {
      throw FormatException(
        hydration.diagnostics.map((diagnostic) => diagnostic.message).join(' '),
      );
    }
    return WildPlayerPokemonGenerationResult(
      pokemon: pokemon,
      profileId: profile.profileId,
      schemaVersion: profile.schemaVersion,
      seed: seed,
    );
  }
}

List<String> _normalizedUniqueIds(
  Iterable<String> values, {
  required String label,
}) {
  final result = <String>[];
  final seen = <String>{};
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isEmpty || !seen.add(normalized)) {
      throw FormatException(
          'Wild Pokemon $label ids must be nonblank and unique.');
    }
    result.add(normalized);
  }
  return List<String>.unmodifiable(result);
}

String _resolveNature(String? authoredNatureId, String fallback) {
  final normalized = authoredNatureId?.trim().toLowerCase() ?? '';
  if (normalized.isEmpty) return fallback;
  if (!canonicalPokemonNatureIds.contains(normalized)) {
    throw FormatException(
        'Unsupported authored wild Pokemon nature "$normalized".');
  }
  return normalized;
}

String _resolveAbility(
  String? authoredAbilityId,
  String fallback,
  List<String> allowedAbilityIds,
) {
  final normalized = authoredAbilityId?.trim() ?? '';
  if (normalized.isEmpty) return fallback;
  if (!allowedAbilityIds.contains(normalized)) {
    throw FormatException(
        'Unsupported authored wild Pokemon ability "$normalized".');
  }
  return normalized;
}

String _resolveGender(Map<String, double> rawRatio, double roll) {
  final ratio = <String, double>{
    for (final entry in rawRatio.entries)
      entry.key.trim().toLowerCase(): entry.value,
  };
  if (ratio.values.any((value) => !value.isFinite || value < 0)) {
    throw const FormatException(
        'Wild Pokemon gender ratios must be finite and non-negative.');
  }
  final male = ratio['male'] ?? 0;
  final female = ratio['female'] ?? 0;
  final genderless = ratio['genderless'] ?? 0;
  if (genderless > 0 && (male > 0 || female > 0)) {
    throw const FormatException(
        'Wild Pokemon genderless ratio cannot be mixed with male or female.');
  }
  final total = male + female;
  if (genderless > 0 || total <= 0) return 'genderless';
  if (female <= 0) return 'male';
  if (male <= 0) return 'female';
  return roll < male / total ? 'male' : 'female';
}

String _resolveGenderOverride(
  String? authoredGender,
  String fallback,
  Map<String, double> ratio,
) {
  final normalized = authoredGender?.trim().toLowerCase() ?? '';
  if (normalized.isEmpty) return fallback;
  if (!const <String>{'male', 'female', 'genderless'}.contains(normalized)) {
    throw FormatException(
        'Unsupported authored wild Pokemon gender "$normalized".');
  }
  final possible = _resolveGender(
    ratio,
    normalized == 'female' ? 0.999999999 : 0,
  );
  final normalizedRatio = <String, double>{
    for (final entry in ratio.entries)
      entry.key.trim().toLowerCase(): entry.value,
  };
  final male = normalizedRatio['male'] ?? 0;
  final female = normalizedRatio['female'] ?? 0;
  final allowed = switch (normalized) {
    'male' => male > 0,
    'female' => female > 0,
    _ => possible == 'genderless',
  };
  if (!allowed) {
    throw FormatException(
      'Authored wild Pokemon gender "$normalized" is incompatible with the species ratio.',
    );
  }
  return normalized;
}

void _requireValidIvs(PokemonStatSpread ivs) {
  final values = <int>[
    ivs.hp,
    ivs.attack,
    ivs.defense,
    ivs.specialAttack,
    ivs.specialDefense,
    ivs.speed,
  ];
  if (values.any((value) => value < 0 || value > 31)) {
    throw const FormatException('Wild Pokemon IVs must be between 0 and 31.');
  }
}

List<String> _learnableMoveIds(
  WildPokemonGenerationLearnset learnset,
  int level,
) {
  final ordered = <String>[
    ...learnset.startingMoves,
    ...learnset.relearnMoves,
    ...learnset.levelUp
        .where((entry) => entry.level <= level)
        .map((entry) => entry.moveId),
  ];
  return _normalizedCatalogMoves(ordered);
}

List<String> _resolveAuthoredMoveIds(
  Iterable<String> authoredMoveIds,
  List<String> learnableMoveIds,
) {
  final normalized = _normalizedAuthoredMoves(authoredMoveIds);
  if (normalized.length > 4) {
    throw const FormatException(
        'A wild Pokemon cannot know more than four authored moves.');
  }
  final learnable = learnableMoveIds.toSet();
  final unsupported = normalized.where((moveId) => !learnable.contains(moveId));
  if (unsupported.isNotEmpty) {
    throw FormatException(
      'Authored wild Pokemon moves are not learnable at this level: ${unsupported.join(', ')}.',
    );
  }
  return normalized;
}

List<String> _normalizedCatalogMoves(Iterable<String> values) {
  final normalized = <String>[];
  final seen = <String>{};
  for (final value in values) {
    final moveId = value.trim();
    if (moveId.isEmpty) {
      throw const FormatException('Wild Pokemon move ids must not be empty.');
    }
    if (seen.add(moveId)) {
      normalized.add(moveId);
    }
  }
  return List<String>.unmodifiable(normalized);
}

List<String> _normalizedAuthoredMoves(Iterable<String> values) {
  final normalized = <String>[];
  final seen = <String>{};
  for (final value in values) {
    final moveId = value.trim();
    if (moveId.isEmpty) {
      throw const FormatException('Wild Pokemon move ids must not be empty.');
    }
    if (!seen.add(moveId)) {
      throw FormatException('Wild Pokemon move "$moveId" is duplicated.');
    }
    normalized.add(moveId);
  }
  return List<String>.unmodifiable(normalized);
}

List<String> _lastFour(List<String> values) {
  if (values.length <= 4) return values;
  return List<String>.unmodifiable(values.sublist(values.length - 4));
}

final class _WildGenerationRandom {
  _WildGenerationRandom(int seed)
      : _state = (seed & 0xffffffff) == 0 ? 0x6d2b79f5 : seed & 0xffffffff;

  int _state;

  int nextInt(int maximum) {
    if (maximum <= 0) {
      throw ArgumentError.value(maximum, 'maximum', 'Must be positive.');
    }
    return _nextUint32() % maximum;
  }

  double nextUnit() => _nextUint32() / 0x100000000;

  int _nextUint32() {
    var value = _state;
    value ^= (value << 13) & 0xffffffff;
    value ^= value >> 17;
    value ^= (value << 5) & 0xffffffff;
    _state = value & 0xffffffff;
    return _state;
  }
}
