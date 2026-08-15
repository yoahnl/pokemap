import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const generator = WildPlayerPokemonGenerator();
  const ruleset = PokemonRulesetProfile.pokeMapBetaV1;
  const species = WildPokemonGenerationSpecies(
    id: 'sproutle',
    formId: 'spring',
    baseStats: PokemonBaseStats(
      hp: 45,
      attack: 49,
      defense: 49,
      specialAttack: 65,
      specialDefense: 65,
      speed: 45,
    ),
    primaryAbilityId: 'overgrow',
    standardAbilityIds: <String>['overgrow', 'chlorophyll'],
    allowedAbilityIds: <String>['overgrow', 'chlorophyll', 'leaf_guard'],
    genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
    growthRateId: 'medium',
    baseFriendship: 70,
  );
  const learnset = WildPokemonGenerationLearnset(
    startingMoves: <String>['tackle', 'growl'],
    relearnMoves: <String>['defense_curl'],
    levelUp: <WildPokemonLevelUpMove>[
      WildPokemonLevelUpMove(moveId: 'vine_whip', level: 3),
      WildPokemonLevelUpMove(moveId: 'poison_powder', level: 5),
      WildPokemonLevelUpMove(moveId: 'razor_leaf', level: 7),
      WildPokemonLevelUpMove(moveId: 'growth', level: 12),
    ],
  );
  const maxPpByMoveId = <String, int>{
    'tackle': 35,
    'growl': 40,
    'defense_curl': 40,
    'vine_whip': 25,
    'poison_powder': 35,
    'razor_leaf': 25,
    'growth': 20,
  };

  test('a seed vector produces one stable and complete individual', () {
    final first = generator.generate(
      seed: 0x12345678,
      species: species,
      learnset: learnset,
      maxPpByMoveId: maxPpByMoveId,
      level: 7,
      ruleset: ruleset,
      context: const WildPokemonGenerationContext(
        mapId: 'route_01',
        sourceId: 'morning_grass',
      ),
    );
    final second = generator.generate(
      seed: 0x12345678,
      species: species,
      learnset: learnset,
      maxPpByMoveId: maxPpByMoveId,
      level: 7,
      ruleset: ruleset,
      context: const WildPokemonGenerationContext(
        mapId: 'route_01',
        sourceId: 'morning_grass',
      ),
    );

    expect(second.pokemon, first.pokemon);
    expect(first.profileId, 'pokemap-wild-v1');
    expect(first.schemaVersion, 1);
    expect(first.pokemon.speciesId, 'sproutle');
    expect(first.pokemon.individualId, startsWith('pkm_'));
    expect(first.pokemon.formId, 'spring');
    expect(first.pokemon.level, 7);
    expect(first.pokemon.natureId, 'serious');
    expect(first.pokemon.abilityId, 'chlorophyll');
    expect(first.pokemon.gender, 'male');
    expect(
      first.pokemon.ivs,
      const PokemonStatSpread(
        hp: 24,
        attack: 8,
        defense: 13,
        specialAttack: 29,
        specialDefense: 9,
        speed: 7,
      ),
    );
    expect(first.pokemon.evs, const PokemonStatSpread());
    expect(
      first.pokemon.knownMoveIds,
      <String>['defense_curl', 'vine_whip', 'poison_powder', 'razor_leaf'],
    );
    expect(
      first.pokemon.currentPpByMoveId,
      <String, int>{
        'defense_curl': 40,
        'vine_whip': 25,
        'poison_powder': 35,
        'razor_leaf': 25,
      },
    );
    expect(first.pokemon.currentHp, greaterThan(1));
    expect(first.pokemon.friendship, 70);
    expect(first.pokemon.provenance?.kind, PlayerPokemonOriginKind.unknown);
    expect(first.pokemon.provenance?.mapId, 'route_01');
    expect(first.pokemon.provenance?.sourceId, 'morning_grass');
    expect(first.pokemon.provenance?.metLevel, 7);
  });

  test('gender ratios preserve genderless and single-gender species', () {
    String genderFor(Map<String, double> ratio) => generator
        .generate(
          seed: 7,
          species: WildPokemonGenerationSpecies(
            id: 'ratio_mon',
            baseStats: species.baseStats,
            primaryAbilityId: 'only',
            standardAbilityIds: const <String>['only'],
            allowedAbilityIds: const <String>['only'],
            genderRatio: ratio,
            growthRateId: 'medium',
            baseFriendship: 50,
          ),
          learnset: const WildPokemonGenerationLearnset(),
          maxPpByMoveId: const <String, int>{},
          level: 5,
          ruleset: ruleset,
          context: const WildPokemonGenerationContext(
            mapId: 'lab',
            sourceId: 'ratio',
          ),
        )
        .pokemon
        .gender!;

    expect(genderFor(const <String, double>{'genderless': 1}), 'genderless');
    expect(genderFor(const <String, double>{'male': 1}), 'male');
    expect(genderFor(const <String, double>{'female': 1}), 'female');
  });

  test('ability selection supports one or two standard abilities', () {
    final oneAbility = generator.generate(
      seed: 1,
      species: const WildPokemonGenerationSpecies(
        id: 'single',
        baseStats: PokemonBaseStats(
          hp: 40,
          attack: 40,
          defense: 40,
          specialAttack: 40,
          specialDefense: 40,
          speed: 40,
        ),
        primaryAbilityId: 'only',
        standardAbilityIds: <String>['only'],
        allowedAbilityIds: <String>['only', 'hidden'],
        genderRatio: <String, double>{'genderless': 1},
        growthRateId: 'medium',
        baseFriendship: 50,
      ),
      learnset: const WildPokemonGenerationLearnset(),
      maxPpByMoveId: const <String, int>{},
      level: 5,
      ruleset: ruleset,
      context: const WildPokemonGenerationContext(
        mapId: 'cave',
        sourceId: 'single',
      ),
    );
    final twoAbilityIds = <String>{
      for (final seed in List<int>.generate(32, (index) => index + 1))
        generator
            .generate(
              seed: seed,
              species: species,
              learnset: const WildPokemonGenerationLearnset(),
              maxPpByMoveId: const <String, int>{},
              level: 5,
              ruleset: ruleset,
              context: const WildPokemonGenerationContext(
                mapId: 'route_01',
                sourceId: 'abilities',
              ),
            )
            .pokemon
            .abilityId,
    };

    expect(oneAbility.pokemon.abilityId, 'only');
    expect(twoAbilityIds, <String>{'overgrow', 'chlorophyll'});
    expect(twoAbilityIds, isNot(contains('leaf_guard')));
  });

  test('a species with no level-compatible move remains valid', () {
    final result = generator.generate(
      seed: 5,
      species: species,
      learnset: const WildPokemonGenerationLearnset(
        levelUp: <WildPokemonLevelUpMove>[
          WildPokemonLevelUpMove(moveId: 'growth', level: 12),
        ],
      ),
      maxPpByMoveId: const <String, int>{'growth': 20},
      level: 5,
      ruleset: ruleset,
      context: const WildPokemonGenerationContext(
        mapId: 'route_01',
        sourceId: 'empty_moves',
      ),
    );

    expect(result.pokemon.knownMoveIds, isEmpty);
    expect(result.pokemon.currentPpByMoveId, isEmpty);
  });

  test('catalog move overlaps are deduplicated before selecting the last four',
      () {
    final result = generator.generate(
      seed: 5,
      species: species,
      learnset: const WildPokemonGenerationLearnset(
        startingMoves: <String>['tackle', 'growl'],
        relearnMoves: <String>['growl', 'defense_curl'],
        levelUp: <WildPokemonLevelUpMove>[
          WildPokemonLevelUpMove(moveId: 'tackle', level: 1),
          WildPokemonLevelUpMove(moveId: 'vine_whip', level: 3),
          WildPokemonLevelUpMove(moveId: 'defense_curl', level: 4),
          WildPokemonLevelUpMove(moveId: 'razor_leaf', level: 7),
        ],
      ),
      maxPpByMoveId: maxPpByMoveId,
      level: 7,
      ruleset: ruleset,
      context: const WildPokemonGenerationContext(
        mapId: 'route_01',
        sourceId: 'overlapping_catalog',
      ),
    );

    expect(
      result.pokemon.knownMoveIds,
      <String>['growl', 'defense_curl', 'vine_whip', 'razor_leaf'],
    );
    expect(
      result.pokemon.currentPpByMoveId,
      <String, int>{
        'growl': 40,
        'defense_curl': 40,
        'vine_whip': 25,
        'razor_leaf': 25,
      },
    );
  });

  test('duplicate authored move overrides remain invalid', () {
    expect(
      () => generator.generate(
        seed: 5,
        species: species,
        learnset: learnset,
        maxPpByMoveId: maxPpByMoveId,
        level: 7,
        ruleset: ruleset,
        context: const WildPokemonGenerationContext(
          mapId: 'route_01',
          sourceId: 'duplicate_override',
        ),
        overrides: const ProjectEncounterPokemonOverrides(
          knownMoveIds: <String>['tackle', 'tackle'],
        ),
      ),
      throwsFormatException,
    );
  });

  test('authored overrides are validated and preserve shiny locks', () {
    final result = generator.generate(
      seed: 9,
      species: species,
      learnset: learnset,
      maxPpByMoveId: maxPpByMoveId,
      level: 7,
      ruleset: ruleset,
      context: const WildPokemonGenerationContext(
        mapId: 'route_01',
        sourceId: 'rare_patch',
      ),
      overrides: const ProjectEncounterPokemonOverrides(
        natureId: 'modest',
        abilityId: 'leaf_guard',
        gender: 'female',
        ivs: PokemonStatSpread(
          hp: 31,
          attack: 0,
          defense: 12,
          specialAttack: 31,
          specialDefense: 20,
          speed: 25,
        ),
        shinyPolicy: ProjectEncounterShinyPolicy.always,
        knownMoveIds: <String>['tackle', 'razor_leaf'],
      ),
    );

    expect(result.pokemon.natureId, 'modest');
    expect(result.pokemon.abilityId, 'leaf_guard');
    expect(result.pokemon.gender, 'female');
    expect(result.pokemon.isShiny, isTrue);
    expect(result.pokemon.ivs.hp, 31);
    expect(result.pokemon.knownMoveIds, <String>['tackle', 'razor_leaf']);
    expect(
      result.pokemon.currentPpByMoveId,
      <String, int>{'razor_leaf': 25, 'tackle': 35},
    );

    final randomShiny = generator.generate(
      seed: 1044,
      species: species,
      learnset: learnset,
      maxPpByMoveId: maxPpByMoveId,
      level: 7,
      ruleset: ruleset,
      context: const WildPokemonGenerationContext(
        mapId: 'route_01',
        sourceId: 'shiny_lock',
      ),
    );
    final shinyLockedOff = generator.generate(
      seed: 1044,
      species: species,
      learnset: learnset,
      maxPpByMoveId: maxPpByMoveId,
      level: 7,
      ruleset: ruleset,
      context: const WildPokemonGenerationContext(
        mapId: 'route_01',
        sourceId: 'shiny_lock',
      ),
      overrides: const ProjectEncounterPokemonOverrides(
        shinyPolicy: ProjectEncounterShinyPolicy.never,
      ),
    );
    expect(randomShiny.pokemon.isShiny, isTrue);
    expect(shinyLockedOff.pokemon.isShiny, isFalse);

    expect(
      () => generator.generate(
        seed: 9,
        species: species,
        learnset: learnset,
        maxPpByMoveId: maxPpByMoveId,
        level: 7,
        ruleset: ruleset,
        context: const WildPokemonGenerationContext(
          mapId: 'route_01',
          sourceId: 'invalid_override',
        ),
        overrides: const ProjectEncounterPokemonOverrides(
          knownMoveIds: <String>['growth'],
        ),
      ),
      throwsFormatException,
    );
  });
}
