import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_options.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets(
    'unsupported game options are absent from navigation and display',
    (tester) async {
      final navigation = RuntimePlayerOptionsNavigation();
      addTearDown(navigation.dispose);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates:
              PokeMapPlayerLocalizations.localizationsDelegates,
          supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
          theme: PokeMapPlayerTheme.dark(),
          home: Scaffold(
            body: PlayerMenuThemeScope(
              child: RuntimePlayerOptions(
                preferences: const PlayerPreferencesSnapshot(
                  locale: 'fr',
                  accessibility: GameSessionAccessibilityOptions(),
                ),
                availability: const RuntimePlayerOptionsAvailability(
                  graphics3d: false,
                  weather: false,
                  worldTime: false,
                ),
                navigation: navigation,
                onChanged: (_) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      navigation.nextTab();
      await tester.pumpAndSettle();
      expect(navigation.activeTitle, 'Affichage');
      for (final key in [
        'options-render-scale-choice',
        'options-upscaling-choice',
        'runtime-player-depth-of-field-toggle',
        'runtime-player-shadows-toggle',
        'runtime-player-fog-and-halos-toggle',
        'runtime-player-ambient-animation-toggle',
      ]) {
        expect(find.byKey(ValueKey(key)), findsNothing, reason: key);
      }
      final visited = <String?>{};
      for (var index = 0; index < 10; index++) {
        visited.add(navigation.activeTitle);
        navigation.nextTab();
        await tester.pumpAndSettle();
      }
      expect(visited, containsAll(['Général', 'Affichage', 'Son']));
      expect(visited, isNot(contains('Météo')));
      expect(visited, isNot(contains('Heure')));
      while (navigation.activeTitle != 'Général') {
        navigation.nextTab();
        await tester.pumpAndSettle();
      }
      navigation.previousTab();
      await tester.pumpAndSettle();
      expect(navigation.activeTitle, 'Accessibilité');
    },
  );

  testWidgets('hidden options stay absent from the category picker', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: PlayerMenuThemeScope(
            child: RuntimePlayerOptions(
              preferences: const PlayerPreferencesSnapshot(
                locale: 'fr',
                accessibility: GameSessionAccessibilityOptions(),
              ),
              availability: const RuntimePlayerOptionsAvailability(
                graphics3d: false,
                weather: false,
                worldTime: false,
              ),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('options-category-picker')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('options-category-weather')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('options-category-time')), findsNothing);
    expect(
      find.byKey(const ValueKey('options-category-display')),
      findsOneWidget,
    );
  });

  testWidgets('resetting 2D display keeps hidden 3D preferences', (
    tester,
  ) async {
    const graphics = RuntimeGraphicsPreferences(
      renderScalePercent: 75,
      shadows: false,
    );
    final changes = <PlayerPreferencesSnapshot>[];
    final navigation = RuntimePlayerOptionsNavigation();
    addTearDown(navigation.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: PlayerMenuThemeScope(
            child: RuntimePlayerOptions(
              preferences: const PlayerPreferencesSnapshot(
                locale: 'fr',
                accessibility: GameSessionAccessibilityOptions(),
                graphics: graphics,
                targetFramesPerSecond: 30,
              ),
              availability: const RuntimePlayerOptionsAvailability(
                graphics3d: false,
              ),
              navigation: navigation,
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    navigation.nextTab();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('options-defaults')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('options-reset-confirm')));
    await tester.pumpAndSettle();
    expect(changes.single.targetFramesPerSecond, 60);
    expect(changes.single.graphics, graphics);
  });

  test('legacy settings keep authored effects and choices persist', () {
    final legacy = const PlayerPreferences().toJson();
    expect(legacy, isNot(contains('graphics')));
    expect(
      PlayerPreferences.fromJson(legacy).graphics,
      const RuntimeGraphicsPreferences(),
    );
    const graphics = RuntimeGraphicsPreferences(
      renderScalePercent: 67,
      shadows: false,
      fogAndHalos: false,
    );
    final prefs = const PlayerPreferences().copyWith(graphics: graphics);
    final reopened = PlayerPreferences.fromJson(prefs.toJson());
    expect(reopened, prefs);
    expect(reopened.hashCode, prefs.hashCode);
    final runtime = reopened.toRuntimeSnapshot(fallbackLocale: 'fr');
    expect(runtime.graphics, graphics);
    expect(
      const PlayerPreferences().copyWithRuntimeSnapshot(runtime).graphics,
      graphics,
    );
    expect(
      () => PlayerPreferences.fromJson({
        ...legacy,
        'graphics': {'renderScalePercent': 30},
      }),
      throwsFormatException,
    );
  });

  testWidgets('display options choose a 3D scale and switch effects off', (
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
    Future<Finder> reveal(Key key) async {
      final target = find.byKey(key).hitTestable();
      for (final direction in ['previous', 'next']) {
        final turn = find
            .byKey(ValueKey('player-page-$direction'))
            .hitTestable();
        for (var page = 0; page < 12 && target.evaluate().isEmpty; page++) {
          if (turn.evaluate().isEmpty) break;
          await tester.tap(turn.last);
          await tester.pumpAndSettle();
        }
      }
      return target;
    }

    await pump();
    await tester.pumpAndSettle();
    navigation.nextTab();
    await tester.pumpAndSettle();

    await tester.tap(
      await reveal(const ValueKey('options-render-scale-choice')),
    );
    await tester.pumpAndSettle();
    await tester.tap((await reveal(const ValueKey('options-choice-75'))).last);
    await tester.pumpAndSettle();
    await pump();
    await tester.pumpAndSettle();
    expect(saved.last.graphics.renderScalePercent, 75);
    expect(saved.last.graphics.shadows, isTrue);

    await tester.tap(
      await reveal(const ValueKey('runtime-player-shadows-toggle')),
    );
    await tester.pumpAndSettle();
    await pump();
    await tester.pumpAndSettle();
    expect(
      saved.last.graphics,
      const RuntimeGraphicsPreferences(renderScalePercent: 75, shadows: false),
    );

    await tester.tap(await reveal(const ValueKey('options-upscaling-choice')));
    await tester.pumpAndSettle();
    await tester.tap(
      (await reveal(const ValueKey('options-choice-fsr1'))).last,
    );
    await tester.pumpAndSettle();
    await pump();
    await tester.pumpAndSettle();
    expect(saved.last.graphics.upscaling, RuntimeUpscaling.fsr1);
    expect(find.text('FSR 1 (AMD)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
