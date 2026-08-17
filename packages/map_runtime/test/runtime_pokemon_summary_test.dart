import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/player/runtime_pokemon_summary.dart';
import 'package:flutter_test/flutter_test.dart';

const _speciesId = 'bulbasaur';
const _moveId = 'tackle';

void main() {
  group('BETA-PTY-001 canonical Pokémon summary', () {
    test('the same individual yields the same sheet from either surface', () {
      final pokemon = _pokemon();
      final builder = _builder();

      final fromParty = builder.build(pokemon, targetId: 'pokemon.indiv-1');
      final fromPc = builder.build(pokemon, targetId: 'pokemon.indiv-1');

      expect(fromParty.displayLabel, fromPc.displayLabel);
      expect(fromParty.speciesLabel, fromPc.speciesLabel);
      expect(fromParty.maxHp, fromPc.maxHp);
      expect(fromParty.stats?.speed, fromPc.stats?.speed);
      expect(
        fromParty.moves.map((move) => move.label),
        fromPc.moves.map((move) => move.label),
      );
      expect(fromParty.provenance?.originLabel, fromPc.provenance?.originLabel);
    });

    test('the species label is localized, never the raw identifier', () {
      final french = _builder(locale: 'fr-FR').build(
        _pokemon(),
        targetId: 'pokemon.indiv-1',
      );
      final english = _builder(locale: 'en-US').build(
        _pokemon(),
        targetId: 'pokemon.indiv-1',
      );

      expect(french.speciesLabel, 'Bulbizarre');
      expect(english.speciesLabel, 'Bulbasaur');
      expect(french.speciesLabel, isNot('Bulbasaur'));
    });

    test('a move carries its localized label and both PP bounds', () {
      final summary = _builder().build(
        _pokemon(currentPpByMoveId: const <String, int>{_moveId: 12}),
        targetId: 'pokemon.indiv-1',
      );

      final move = summary.moves.single;
      expect(move.label, 'Charge');
      expect(move.currentPp, 12);
      expect(move.maxPp, 35);
      expect(move.hasPpTracking, isTrue);
    });

    test('a save without PP tracking reports no PP instead of zero', () {
      final summary = _builder().build(
        _pokemon(currentPpByMoveId: null),
        targetId: 'pokemon.indiv-1',
      );

      final move = summary.moves.single;
      expect(move.currentPp, isNull);
      expect(
        move.hasPpTracking,
        isFalse,
        reason: 'zero PP would read as an exhausted move',
      );
    });

    test('unknown identifiers fall back to a humanized label', () {
      final summary = RuntimePokemonSummaryBuilder(
        locale: 'fr-FR',
        resolvers: RuntimePokemonSummaryResolvers(
          speciesLabelFor: runtimePokemonHumanizeId,
        ),
      ).build(
        _pokemon(heldItemId: 'oran_berry'),
        targetId: 'pokemon.indiv-1',
      );

      expect(summary.speciesLabel, 'Bulbasaur');
      expect(summary.heldItemLabel, 'Oran Berry');
      expect(summary.moves.single.label, 'Tackle');
      expect(
        summary.stats,
        isNull,
        reason: 'no stat resolver means no invented stats',
      );
    });

    test('a species without base stats keeps a usable HP bar', () {
      final summary = RuntimePokemonSummaryBuilder(
        locale: 'fr-FR',
        resolvers: RuntimePokemonSummaryResolvers(
          speciesLabelFor: (_) => 'Bulbizarre',
        ),
      ).build(
        _pokemon(currentHp: 17),
        targetId: 'pokemon.indiv-1',
      );

      expect(summary.maxHp, 17);
      expect(summary.currentHp, 17);
      expect(summary.hpRatio, 1);
      expect(summary.isFainted, isFalse);
    });

    test('a fainted Pokémon reports a zero ratio without a zero maximum', () {
      final summary = _builder().build(
        _pokemon(currentHp: 0),
        targetId: 'pokemon.indiv-1',
      );

      expect(summary.currentHp, 0);
      expect(summary.maxHp, greaterThan(0));
      expect(summary.hpRatio, 0);
      expect(summary.isFainted, isTrue);
    });

    test('a save predating individual ids is flagged as unstable', () {
      final withId = _builder().build(
        _pokemon(),
        targetId: 'pokemon.indiv-1',
      );
      final withoutId = _builder().build(
        _pokemon(individualId: ''),
        targetId: 'party.0',
      );

      expect(withId.hasStableIdentity, isTrue);
      expect(
        withoutId.hasStableIdentity,
        isFalse,
        reason: 'a positional target cannot survive a PC transfer',
      );
    });

    test('the experience is exposed and null stays null', () {
      expect(
        _builder().build(_pokemon(experience: 640), targetId: 'x').experience,
        640,
      );
      expect(
        _builder().build(_pokemon(experience: null), targetId: 'x').experience,
        isNull,
        reason: 'a legacy save must not be reported as zero experience',
      );
    });
  });
}

RuntimePokemonSummaryBuilder _builder({String locale = 'fr-FR'}) {
  return RuntimePokemonSummaryBuilder(
    locale: locale,
    resolvers: RuntimePokemonSummaryResolvers(
      speciesLabelFor: (speciesId) => speciesId == _speciesId
          ? (locale.startsWith('fr') ? 'Bulbizarre' : 'Bulbasaur')
          : runtimePokemonHumanizeId(speciesId),
      calculatedStatsFor: (pokemon) => const PokemonStatCalculator().calculate(
        baseStats: const PokemonBaseStats(
          hp: 45,
          attack: 49,
          defense: 49,
          specialAttack: 65,
          specialDefense: 65,
          speed: 45,
        ),
        ivs: pokemon.ivs,
        evs: pokemon.evs,
        level: pokemon.level,
        naturePolicy: PokemonNatureStatPolicy.canonical,
        natureId: pokemon.natureId,
      ),
      itemLabelFor: (itemId) => itemId == 'oran_berry' ? 'Baie Oran' : null,
      moveFor: (moveId) => moveId == _moveId
          ? const PokemonMove(
              id: _moveId,
              name: 'Tackle',
              names: <String, String>{'fr': 'Charge', 'en': 'Tackle'},
              type: 'normal',
              category: PokemonMoveCategory.physical,
              accuracy: PokemonMoveAccuracy.percent(value: 100),
              pp: 35,
            )
          : null,
    ),
  );
}

PlayerPokemon _pokemon({
  String individualId = 'indiv-1',
  int currentHp = 20,
  String heldItemId = '',
  int? experience = 120,
  Map<String, int>? currentPpByMoveId = const <String, int>{_moveId: 30},
}) {
  return PlayerPokemon(
    individualId: individualId,
    speciesId: _speciesId,
    natureId: 'hardy',
    abilityId: 'overgrow',
    gender: 'male',
    level: 12,
    experience: experience,
    knownMoveIds: const <String>[_moveId],
    currentPpByMoveId: currentPpByMoveId,
    currentHp: currentHp,
    heldItemId: heldItemId,
    nickname: 'Bulbi',
    friendship: 70,
    provenance: const PlayerPokemonProvenance(
      kind: PlayerPokemonOriginKind.captured,
      mapId: 'route_hanazuki',
      sourceId: 'tall_grass',
      ballItemId: 'poke_ball',
      metLevel: 5,
    ),
  );
}
