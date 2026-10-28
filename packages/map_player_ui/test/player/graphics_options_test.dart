import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_options.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
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
