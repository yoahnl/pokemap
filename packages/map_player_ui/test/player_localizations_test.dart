import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  test('touch side survives storage and runtime preference updates', () {
    const defaults = PlayerPreferences();
    final mirrored = defaults.copyWith(leftHandedTouchControls: true);
    final restored = PlayerPreferences.fromJson(mirrored.toJson());
    expect(restored, mirrored);
    expect(restored, isNot(defaults));
    final snapshot = restored.toRuntimeSnapshot(fallbackLocale: 'fr');
    expect(snapshot.leftHandedTouchControls, isTrue);
    expect(snapshot.copyWith(locale: 'en').leftHandedTouchControls, isTrue);
    expect(
      restored.copyWithRuntimeSnapshot(snapshot.copyWith(
          leftHandedTouchControls: false)).leftHandedTouchControls,
      isFalse,
    );
    expect(
      () => PlayerPreferences.fromJson({
        ...mirrored.toJson(),
        'leftHandedTouchControls': 'true',
      }),
      throwsFormatException,
    );
  });

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
      'touchControlsOpacity': 0.45,
    });

    expect(preferences.locale, const Locale('fr'));
    expect(preferences.themeMode, ThemeMode.dark);
    expect(preferences.touchControlsOpacity, 0.45);
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
                '${context.playerL10n.returnToHub}|'
                '${context.playerL10n.quests}|${context.playerL10n.profile}',
              ),
            ),
          ),
        );

    await pump(const Locale('fr'));
    expect(find.text('Continuer|Retour au Hub|Quêtes|Profil'), findsOneWidget);

    await pump(const Locale('en'));
    expect(find.text('Continue|Back to Hub|Quests|Profile'), findsOneWidget);
  });

  test('unsupported locales fall back to English', () {
    expect(
      PokeMapPlayerLocalizations.lookup(const Locale('de')).continueGame,
      'Continue',
    );
  });
}
