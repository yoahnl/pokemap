import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_options.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  const noon = RuntimeWorldTimePreferences(chosenMinuteOfDay: 720);

  test(
    'legacy settings keep real time and a chosen hour persists everywhere',
    () {
      final legacy = const PlayerPreferences().toJson();
      expect(legacy, isNot(contains('worldTime')));
      expect(
        PlayerPreferences.fromJson(legacy).worldTime,
        const RuntimeWorldTimePreferences(),
      );
      final prefs = const PlayerPreferences().copyWith(worldTime: noon);
      final reopened = PlayerPreferences.fromJson(prefs.toJson());
      expect(reopened, prefs);
      final runtime = reopened.toRuntimeSnapshot(fallbackLocale: 'fr');
      expect(runtime.worldTime, noon);
      expect(
        const PlayerPreferences().copyWithRuntimeSnapshot(runtime).worldTime,
        noon,
      );
      expect(
        () => PlayerPreferences.fromJson({
          ...legacy,
          'worldTime': {'chosenMinuteOfDay': 1440},
        }),
        throwsFormatException,
      );
    },
  );

  testWidgets('the time category chooses an hour and returns to real time', (
    tester,
  ) async {
    final navigation = RuntimePlayerOptionsNavigation();
    addTearDown(navigation.dispose);
    var preferences = const PlayerPreferencesSnapshot(
      locale: 'fr',
      accessibility: GameSessionAccessibilityOptions(),
    );
    final saved = <PlayerPreferencesSnapshot>[];
    Future<void> pump() => tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: PlayerMenuThemeScope(
            child: RuntimePlayerOptions(
              preferences: preferences,
              navigation: navigation,
              onChanged: (value) async {
                saved.add(value);
                preferences = value;
              },
            ),
          ),
        ),
      ),
    );
    await pump();
    await tester.pumpAndSettle();
    for (var index = 0; index < 6; index++) {
      navigation.nextTab();
      await tester.pumpAndSettle();
    }
    expect(find.text('Heure du monde'), findsOneWidget);
    expect(find.text('Heure réelle'), findsOneWidget);

    Future<void> choose(String id) async {
      await tester.tap(find.byKey(const ValueKey('options-world-time-choice')));
      await tester.pumpAndSettle();
      final option = find.byKey(ValueKey('options-choice-$id')).hitTestable();
      for (final direction in ['previous', 'next']) {
        final turn = find
            .byKey(ValueKey('player-page-$direction'))
            .hitTestable();
        for (var page = 0; page < 12 && option.evaluate().isEmpty; page++) {
          if (turn.evaluate().isEmpty) break;
          await tester.tap(turn.last);
          await tester.pumpAndSettle();
        }
      }
      await tester.tap(option.last);
      await tester.pumpAndSettle();
      await pump();
      await tester.pumpAndSettle();
    }

    await choose('720');
    expect(saved.last.worldTime, noon);
    expect(find.text('12:00'), findsOneWidget);

    await choose('real');
    expect(saved.last.worldTime, const RuntimeWorldTimePreferences());
    expect(find.text('Heure réelle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
