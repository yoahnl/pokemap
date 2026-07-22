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

    test('keeps nature handling explicitly neutral in the MVP', () {
      expect(PokemonNatureStatPolicy.values, [PokemonNatureStatPolicy.neutral]);

      final stats = const PokemonStatCalculator().calculate(
        baseStats: bulbasaur,
        ivs: const PokemonStatSpread(),
        evs: const PokemonStatSpread(),
        level: 5,
      );

      expect(stats.maxHp, 19);
      expect(stats.attack, 9);
      expect(stats.specialAttack, 11);
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
