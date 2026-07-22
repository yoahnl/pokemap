import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('PokemonExperienceCurve', () {
    test('supports the seven canonical project growth ids at level 100', () {
      const expected = <String, int>{
        'fast': 800000,
        'fast_then_very_slow': 1640000,
        'medium': 1000000,
        'medium_fast': 1000000,
        'medium_slow': 1059860,
        'slow': 1250000,
        'slow_then_very_fast': 600000,
      };

      for (final entry in expected.entries) {
        final curve = PokemonExperienceCurve.fromId(entry.key);
        expect(curve.totalExperienceForLevel(100), entry.value);
      }
    });

    test('uses the exact erratic piecewise boundaries', () {
      final curve = PokemonExperienceCurve.fromId('slow_then_very_fast');

      expect(curve.totalExperienceForLevel(50), 125000);
      expect(curve.totalExperienceForLevel(51), 131324);
      expect(curve.totalExperienceForLevel(68), 257834);
      expect(curve.totalExperienceForLevel(69), 267406);
      expect(curve.totalExperienceForLevel(98), 583539);
      expect(curve.totalExperienceForLevel(99), 591882);
    });

    test('uses the exact fluctuating piecewise boundaries', () {
      final curve = PokemonExperienceCurve.fromId('fast_then_very_slow');

      expect(curve.totalExperienceForLevel(15), 1957);
      expect(curve.totalExperienceForLevel(16), 2457);
      expect(curve.totalExperienceForLevel(35), 42017);
      expect(curve.totalExperienceForLevel(36), 46656);
    });

    test('clamps the negative medium-slow level-one threshold to zero', () {
      final curve = PokemonExperienceCurve.fromId('medium_slow');

      expect(curve.totalExperienceForLevel(1), 0);
      expect(curve.levelForExperience(0), 1);
    });

    test('resolves levels from cumulative experience and caps huge totals', () {
      final curve = PokemonExperienceCurve.fromId('medium');

      expect(curve.levelForExperience(7), 1);
      expect(curve.levelForExperience(8), 2);
      expect(curve.levelForExperience(26), 2);
      expect(curve.levelForExperience(27), 3);
      expect(curve.levelForExperience(1 << 62), 100);
    });

    test('rejects unsupported ids, invalid levels and negative experience', () {
      expect(
        () => PokemonExperienceCurve.fromId('unknown'),
        throwsArgumentError,
      );
      final curve = PokemonExperienceCurve.fromId('fast');
      expect(() => curve.totalExperienceForLevel(0), throwsRangeError);
      expect(() => curve.totalExperienceForLevel(101), throwsRangeError);
      expect(() => curve.levelForExperience(-1), throwsRangeError);
    });
  });
}
