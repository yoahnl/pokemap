import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

const _legacyPreferences = <String, Object?>{
  'schemaVersion': 1,
  'language': 'fr',
  'theme': 'dark',
  'masterVolume': 0.4,
  'musicVolume': 0.3,
  'effectsVolume': 0.2,
  'textScale': 1.3,
  'reducedMotion': true,
  'highContrast': true,
  'hapticsEnabled': false,
  'showInputHints': false,
};

const _interfaceLocales = ['en', 'fr'];
const _followApplication = RuntimePlayerLanguageChoice.followApplication();

void main() {
  group('Player language preferences', () {
    test('reads the legacy language as an application choice', () {
      for (final language in [PlayerLanguage.fr, PlayerLanguage.system]) {
        final preferences = PlayerPreferences.fromJson({
          ..._legacyPreferences,
          'language': language.name,
        });

        expect(preferences.language, language);
        expect(preferences.playerLanguage, _followApplication);
        expect(preferences.theme, PlayerThemePreference.dark);
        expect(preferences.masterVolume, 0.4);
        expect(preferences.toJson()['language'], language.name);
        expect(preferences.toJson(), isNot(contains('playerLanguage')));
      }
    });

    test('preserves an explicit choice across app and volume changes', () {
      final preferences = PlayerPreferences.fromJson({
        ..._legacyPreferences,
        'playerLanguage': 'en',
      });
      final edited = preferences.copyWith(
        language: PlayerLanguage.en,
        masterVolume: 0.6,
      );

      expect(edited.playerLanguage, RuntimePlayerLanguageChoice.explicit('EN'));
      expect(edited.toJson()['playerLanguage'], 'en');
      final reopened = PlayerPreferences.fromJson(edited.toJson());
      expect(reopened, edited);
      expect(reopened.hashCode, edited.hashCode);
      expect(reopened.theme, PlayerThemePreference.dark);
      expect(reopened.masterVolume, 0.6);
    });

    test('removes the override when the player follows the application', () {
      final explicit = const PlayerPreferences(language: PlayerLanguage.en)
          .copyWith(playerLanguage: RuntimePlayerLanguageChoice.explicit('en'));
      final inherited = explicit.copyWith(playerLanguage: _followApplication);

      expect(inherited, isNot(explicit));
      expect(inherited.language, PlayerLanguage.en);
      expect(inherited.toJson(), isNot(contains('playerLanguage')));
      expect(PlayerPreferences.fromJson(inherited.toJson()), inherited);
    });

    test('validates and normalizes explicit BCP 47 tags', () {
      final choice = RuntimePlayerLanguageChoice.explicit(' ZH_hant_tw ');
      final same = RuntimePlayerLanguageChoice.explicit('zh-Hant-TW');

      expect(choice.languageTag, 'zh-Hant-TW');
      expect(choice, same);
      expect(choice.hashCode, same.hashCode);
      expect(_followApplication.languageTag, isNull);
      expect(_followApplication, isNot(choice));

      for (final raw in [null, 4, '', 'en--US', 'not a language tag']) {
        expect(
          () => PlayerPreferences.fromJson({
            ..._legacyPreferences,
            'playerLanguage': raw,
          }),
          throwsFormatException,
        );
      }
    });

    test('accepts script, region, extensions and private use together', () {
      final choice = RuntimePlayerLanguageChoice.explicit(
        'SR_latn_rs-u-ca-gregory-x-CUSTOM',
      );
      expect(choice.languageTag, 'sr-Latn-RS-u-ca-gregory-x-custom');
      expect(
        () => RuntimePlayerLanguageChoice.explicit('en-u-ca-gregory-u-nu-latn'),
        throwsFormatException,
      );
      expect(
        () => RuntimePlayerLanguageChoice.explicit('sl-rozaj-rozaj'),
        throwsFormatException,
      );
    });
  });

  group('resolvePlayerLocales', () {
    test('resolves application and Player independently', () {
      final resolved = _resolve(
        const PlayerPreferences(
          language: PlayerLanguage.fr,
        ).copyWith(playerLanguage: RuntimePlayerLanguageChoice.explicit('EN')),
        ['en-GB'],
      );

      expect(resolved.appLocale, 'fr');
      expect(resolved.playerLocale, 'en');
      expect(resolved.preferredContentLocales, ['en']);
    });

    test('inherits an explicit application language', () {
      final resolved = _resolve(
        const PlayerPreferences(language: PlayerLanguage.fr),
        ['en-GB'],
      );

      expect(resolved.appLocale, 'fr');
      expect(resolved.playerLocale, 'fr');
      expect(resolved.preferredContentLocales, ['fr']);
    });

    test(
      'tries the complete system tag before its base and next candidate',
      () {
        final systemLocales = ['fr_CA', 'en'];
        final resolved = _resolve(
          const PlayerPreferences(),
          systemLocales,
          appLocales: ['en', 'fr', 'FR_ca'],
        );
        systemLocales.clear();

        expect(resolved.appLocale, 'fr-CA');
        expect(resolved.playerLocale, 'fr');
        expect(resolved.preferredContentLocales, ['fr-CA', 'en']);
        expect(
          () => resolved.preferredContentLocales.add('es-MX'),
          throwsUnsupportedError,
        );
      },
    );

    test('keeps system candidates available to game content in order', () {
      final resolved = _resolve(const PlayerPreferences(), ['es-MX', 'en']);

      expect(resolved.appLocale, 'en');
      expect(resolved.playerLocale, 'en');
      expect(resolved.preferredContentLocales, ['es-MX', 'en']);
    });

    test(
      'tries the next supported candidate independently for each interface',
      () {
        final resolved = _resolve(
          const PlayerPreferences(),
          ['es-MX', 'fr', 'en'],
          appLocales: ['fr', 'es'],
        );

        expect(resolved.appLocale, 'es');
        expect(resolved.playerLocale, 'fr');
        expect(resolved.preferredContentLocales, ['es-MX', 'fr', 'en']);
      },
    );

    test(
      'uses English for missing UI matches without adding a content tag',
      () {
        final resolved = _resolve(const PlayerPreferences(), ['it-IT']);

        expect(resolved.appLocale, 'en');
        expect(resolved.playerLocale, 'en');
        expect(resolved.preferredContentLocales, ['it-IT']);
      },
    );

    test('ignores invalid system tags and accepts an empty list', () {
      for (final systemLocales in <List<String>>[
        [],
        ['  ', 'en--US', 'some random string'],
      ]) {
        final resolved = _resolve(const PlayerPreferences(), systemLocales);

        expect(resolved.appLocale, 'en');
        expect(resolved.playerLocale, 'en');
        expect(resolved.preferredContentLocales, isEmpty);
      }
    });
  });
}

PlayerLocaleResolution _resolve(
  PlayerPreferences preferences,
  Iterable<String> systemLocales, {
  Iterable<String> appLocales = _interfaceLocales,
}) => resolvePlayerLocales(
  preferences: preferences,
  systemLocales: systemLocales,
  supportedAppLocales: appLocales,
  supportedPlayerLocales: _interfaceLocales,
);
