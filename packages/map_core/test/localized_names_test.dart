import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolveLocalizedName', () {
    const names = <String, String>{'en': 'Thunderbolt', 'fr': 'Tonnerre'};

    test('returns the exact locale match', () {
      expect(
        resolveLocalizedName(names: names, locale: 'fr', fallback: 'X'),
        'Tonnerre',
      );
    });

    test('falls back to the language code of a regional locale', () {
      expect(
        resolveLocalizedName(names: names, locale: 'fr-CA', fallback: 'X'),
        'Tonnerre',
      );
    });

    test('normalizes underscore separators and casing', () {
      expect(
        resolveLocalizedName(names: names, locale: 'FR_ca', fallback: 'X'),
        'Tonnerre',
      );
    });

    test('returns the fallback for an unknown locale', () {
      expect(
        resolveLocalizedName(names: names, locale: 'de', fallback: 'X'),
        'X',
      );
    });

    test('returns the fallback for an empty map', () {
      expect(
        resolveLocalizedName(
          names: const <String, String>{},
          locale: 'fr',
          fallback: 'X',
        ),
        'X',
      );
    });

    test('ignores a blank translation and returns the fallback', () {
      expect(
        resolveLocalizedName(
          names: const <String, String>{'fr': '   '},
          locale: 'fr',
          fallback: 'X',
        ),
        'X',
      );
    });

    test('returns the fallback for a malformed locale', () {
      expect(
        resolveLocalizedName(names: names, locale: '', fallback: 'X'),
        'X',
      );
    });
  });

  group('resolvePokemonSpeciesName', () {
    test('tries the exact locale, base language and English in order', () {
      const names = {
        'fr-ca': 'Poussette',
        'fr': 'Pousse',
        'en': ' Sproutle ',
        'es': '   ',
      };
      for (final (locale, expected) in [
        ('FR_ca', 'Poussette'),
        ('fr-BE', 'Pousse'),
        ('es-MX', ' Sproutle '),
        ('en-GB', ' Sproutle '),
      ]) {
        expect(
          resolvePokemonSpeciesName(
            names: names,
            locale: locale,
            fallback: 'X',
          ),
          expected,
        );
      }
    });

    test(
      'keeps the fallback when English and the requested name are blank',
      () {
        expect(
          resolvePokemonSpeciesName(
            names: const {'fr-ca': ' ', 'fr': ' ', 'en': ' '},
            locale: 'fr-CA',
            fallback: ' Ancien nom ',
          ),
          ' Ancien nom ',
        );
      },
    );
  });

  group('PokemonMove.displayName', () {
    test('prefers the localized name over the canonical name', () {
      final move = _move(
        name: 'Thunderbolt',
        names: const <String, String>{'en': 'Thunderbolt', 'fr': 'Tonnerre'},
      );
      expect(move.displayName('fr'), 'Tonnerre');
    });

    test('falls back to the canonical name when the locale is missing', () {
      final move = _move(
        name: 'Thunderbolt',
        names: const <String, String>{'en': 'Thunderbolt'},
      );
      expect(move.displayName('fr'), 'Thunderbolt');
    });
  });
}

PokemonMove _move({
  required String name,
  required Map<String, String> names,
}) {
  return PokemonMove(
    id: 'thunderbolt',
    name: name,
    names: names,
    type: 'electric',
    category: PokemonMoveCategory.special,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
  );
}
