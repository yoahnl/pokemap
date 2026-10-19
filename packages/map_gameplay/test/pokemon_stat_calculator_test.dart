import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('PokemonStatCalculator', () {
    const bulbasaur = PokemonBaseStats(
      hp: 45,
      attack: 49,
      defense: 49,
      specialAttack: 65,
      specialDefense: 65,
      speed: 45,
    );

    test('calculates HP and non-HP stats with IV EV and level floors', () {
      final stats = const PokemonStatCalculator().calculate(
        baseStats: bulbasaur,
        ivs: const PokemonStatSpread(
          hp: 31,
          attack: 31,
          defense: 31,
          specialAttack: 31,
          specialDefense: 31,
          speed: 31,
        ),
        evs: const PokemonStatSpread(
          hp: 252,
          attack: 252,
          defense: 252,
          specialAttack: 252,
          specialDefense: 252,
          speed: 252,
        ),
        level: 50,
        naturePolicy: PokemonNatureStatPolicy.neutral,
      );

      expect(stats.maxHp, 152);
      expect(stats.attack, 101);
      expect(stats.defense, 101);
      expect(stats.specialAttack, 117);
      expect(stats.specialDefense, 117);
      expect(stats.speed, 97);
    });

    test('applies a canonical non-neutral nature after the stat floor', () {
      expect(
        PokemonNatureStatPolicy.values,
        [
          PokemonNatureStatPolicy.neutral,
          PokemonNatureStatPolicy.canonical,
        ],
      );

      final stats = const PokemonStatCalculator().calculate(
        baseStats: bulbasaur,
        ivs: const PokemonStatSpread(),
        evs: const PokemonStatSpread(),
        level: 50,
        naturePolicy: PokemonNatureStatPolicy.canonical,
        natureId: 'bold',
      );

      expect(stats.maxHp, 105);
      expect(stats.attack, 48);
      expect(stats.defense, 59);
      expect(stats.specialAttack, 70);
    });

    test('keeps all five canonical neutral natures neutral', () {
      const neutralIds = <String>[
        'hardy',
        'docile',
        'serious',
        'bashful',
        'quirky',
      ];

      for (final natureId in neutralIds) {
        final stats = const PokemonStatCalculator().calculate(
          baseStats: bulbasaur,
          ivs: const PokemonStatSpread(),
          evs: const PokemonStatSpread(),
          level: 50,
          naturePolicy: PokemonNatureStatPolicy.canonical,
          natureId: natureId,
        );
        expect(stats.attack, 54, reason: natureId);
        expect(stats.defense, 54, reason: natureId);
      }
    });

    test('exposes all 25 canonical natures exactly once', () {
      expect(canonicalPokemonNatureIds, hasLength(25));
      expect(canonicalPokemonNatureIds.toSet(), hasLength(25));
      expect(canonicalPokemonNatureIds, containsAll(<String>['bold', 'calm']));
    });

    test('rejects an unknown nature in canonical mode', () {
      expect(
        () => const PokemonStatCalculator().calculate(
          baseStats: bulbasaur,
          ivs: const PokemonStatSpread(),
          evs: const PokemonStatSpread(),
          level: 50,
          naturePolicy: PokemonNatureStatPolicy.canonical,
          natureId: 'invented',
        ),
        throwsArgumentError,
      );
    });

    test('defines deterministic wild and trainer opponent spreads', () {
      expect(
        PokemonOpponentStatProfile.wildV0.natureId,
        'hardy',
      );
      expect(
        PokemonOpponentStatProfile.wildV0.ivs,
        const PokemonStatSpread(),
      );
      expect(
        PokemonOpponentStatProfile.trainerV0.ivs,
        const PokemonStatSpread(
          hp: 15,
          attack: 15,
          defense: 15,
          specialAttack: 15,
          specialDefense: 15,
          speed: 15,
        ),
      );
      expect(
        PokemonOpponentStatProfile.trainerV0.evs,
        const PokemonStatSpread(),
      );
    });

    test('calculates trainer standard and independent authored overrides', () {
      const standard = ProjectTrainerPokemonEntry(
        speciesId: 'bulbasaur',
        level: 50,
      );
      const ivs = PokemonStatSpread(
        hp: 31,
        attack: 31,
        defense: 31,
        specialAttack: 31,
        specialDefense: 31,
        speed: 31,
      );
      const evs = PokemonStatSpread(hp: 252, attack: 252, speed: 6);
      final cases = [
        (member: standard, expected: [112, 61, 61, 77, 77, 57]),
        (
          member: standard.copyWith(natureId: 'adamant'),
          expected: [112, 67, 61, 69, 77, 57],
        ),
        (
          member: standard.copyWith(ivs: ivs),
          expected: [120, 69, 69, 85, 85, 65],
        ),
        (
          member: standard.copyWith(evs: evs),
          expected: [144, 93, 61, 77, 77, 58],
        ),
        (
          member: standard.copyWith(
            natureId: 'adamant',
            ivs: ivs,
            evs: evs,
          ),
          expected: [152, 111, 69, 76, 85, 66],
        ),
      ];
      for (final entry in cases) {
        final stats = calculateTrainerPokemonStats(
          member: entry.member,
          baseStats: bulbasaur,
        );
        expect(
          [
            stats.maxHp,
            stats.attack,
            stats.defense,
            stats.specialAttack,
            stats.specialDefense,
            stats.speed,
          ],
          entry.expected,
          reason: entry.member.toString(),
        );
      }
      final reset = cases.last.member.copyWith(
        natureId: null,
        ivs: null,
        evs: null,
      );
      final resetStats = calculateTrainerPokemonStats(
        member: reset,
        baseStats: bulbasaur,
      );
      expect(resetStats.maxHp, 112);
      expect(resetStats.attack, 61);
      expect(resetStats.specialAttack, 77);
    });

    test('trainer validation rejects invalid constructor overrides', () {
      const standard = ProjectTrainerPokemonEntry(
        speciesId: 'bulbasaur',
        level: 50,
      );
      for (final member in [
        standard.copyWith(natureId: ' Bold '),
        standard.copyWith(natureId: 'unknown'),
        standard.copyWith(ivs: const PokemonStatSpread(hp: 32)),
        standard.copyWith(evs: const PokemonStatSpread(hp: 253)),
        standard.copyWith(
          evs: const PokemonStatSpread(hp: 252, attack: 252, speed: 7),
        ),
      ]) {
        expect(
          () => calculateTrainerPokemonStats(
            member: member,
            baseStats: bulbasaur,
          ),
          throwsArgumentError,
        );
        expect(validateTrainerPokemonStats(member), isNotEmpty);
      }
    });

    test('preserves normalized nature lookup for non-trainer consumers', () {
      final effect = canonicalPokemonNatureEffect(' BOLD ');
      expect(effect.id, 'bold');
      expect(effect.apply(100, PokemonNatureStat.defense), 110);
      expect(effect.apply(100, PokemonNatureStat.attack), 90);
      expect(effect.apply(100, PokemonNatureStat.speed), 100);
    });

    test('rejects values outside the persisted stat contract', () {
      expect(
        () => const PokemonBaseStats(
          hp: 0,
          attack: 49,
          defense: 49,
          specialAttack: 65,
          specialDefense: 65,
          speed: 45,
        ).validated(),
        throwsRangeError,
      );
      expect(
        () => const PokemonStatCalculator().calculate(
          baseStats: bulbasaur,
          ivs: const PokemonStatSpread(hp: 32),
          evs: const PokemonStatSpread(),
          level: 50,
        ),
        throwsRangeError,
      );
      expect(
        () => const PokemonStatCalculator().calculate(
          baseStats: bulbasaur,
          ivs: const PokemonStatSpread(),
          evs: const PokemonStatSpread(speed: 253),
          level: 50,
        ),
        throwsRangeError,
      );
    });
  });
}
