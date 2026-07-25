import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  test('preferences round-trip and clamp unsafe presentation values', () {
    final preferences = PlayerPreferences.fromJson(const <String, Object?>{
      'schemaVersion': 1,
      'language': 'fr',
      'theme': 'dark',
      'masterVolume': 0.8,
      'musicVolume': 0.6,
      'effectsVolume': 0.7,
      'textScale': 1.25,
      'reducedMotion': true,
      'highContrast': true,
      'hapticsEnabled': false,
      'showInputHints': true,
    });

    expect(preferences.locale, const Locale('fr'));
    expect(preferences.themeMode, ThemeMode.dark);
    expect(PlayerPreferences.fromJson(preferences.toJson()), preferences);
    expect(
      () => PlayerPreferences.fromJson(<String, Object?>{
        ...preferences.toJson(),
        'textScale': 4,
      }),
      throwsFormatException,
    );
  });

  testWidgets('French and English player labels are available', (tester) async {
    Future<void> pump(Locale locale) => tester.pumpWidget(
          MaterialApp(
            locale: locale,
            supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
            localizationsDelegates:
                PokeMapPlayerLocalizations.localizationsDelegates,
            home: Builder(
              builder: (context) => Text(
                '${context.playerL10n.continueGame}|'
                '${context.playerL10n.returnToHub}',
              ),
            ),
          ),
        );

    await pump(const Locale('fr'));
    expect(find.text('Continuer|Retour au Hub'), findsOneWidget);

    await pump(const Locale('en'));
    expect(find.text('Continue|Back to Hub'), findsOneWidget);
  });

  test('unsupported locales fall back to English', () {
    expect(
      PokeMapPlayerLocalizations.lookup(const Locale('de')).continueGame,
      'Continue',
    );
  });
}
