import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_real_weather_options.dart';
import 'package:map_player_ui/src/player/runtime_player_options.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('legacy player settings remain offline and new choices persist through both codecs', () {
    final legacy = const PlayerPreferences().toJson();
    expect(legacy, isNot(contains('realWeather')));
    expect(PlayerPreferences.fromJson(legacy).realWeather.enabled, isFalse);
    final chosen = RealWeatherPreferences(
      enabled: true,
      location: RealWeatherLocation(
        latitude: 48.86,
        longitude: 2.35,
        label: 'Paris',
        countryCode: 'FR',
      ),
    );
    final prefs = const PlayerPreferences().copyWith(realWeather: chosen);
    final reopened = PlayerPreferences.fromJson(prefs.toJson());
    expect(reopened, prefs);
    final runtime = reopened.toRuntimeSnapshot(fallbackLocale: 'fr');
    final transported =
        RuntimeCompanionPresentationCodec.decodePlayerPreferencesSnapshot(
          Map<String, dynamic>.from(
            RuntimeCompanionPresentationCodec.encodePlayerPreferencesSnapshot(
              runtime,
            ),
          ),
        );
    expect(transported.realWeather, chosen);
    expect(
      const PlayerPreferences()
          .copyWithRuntimeSnapshot(transported)
          .realWeather,
      chosen,
    );
  });
  for (final size in [const Size(390, 844), const Size(844, 390), const Size(496, 432)]) {
    testWidgets('weather category keeps its controls reachable at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final navigation = RuntimePlayerOptionsNavigation();
      addTearDown(navigation.dispose);
      await tester.pumpWidget(MaterialApp(locale: const Locale('fr'), localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates, supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        theme: PokeMapPlayerTheme.dark(), home: Scaffold(body: PlayerMenuThemeScope(child: RuntimePlayerOptions(preferences: const PlayerPreferencesSnapshot(locale: 'fr', accessibility: GameSessionAccessibilityOptions()), navigation: navigation, onChanged: (_) async {})))));
      await tester.pumpAndSettle();
      for (var index = 0; index < 5; index++) { navigation.nextTab(); await tester.pumpAndSettle(); }
      final choose = find.byKey(const ValueKey('real-weather-city'));
      for (var page = 0; page < 12 && choose.hitTestable().evaluate().isEmpty; page++) {
        final next = find.byKey(const ValueKey('player-page-next')).hitTestable();
        if (next.evaluate().isEmpty) break;
        await tester.tap(next.first); await tester.pumpAndSettle();
      }
      expect(choose.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'weather opt-in, city choice and IP reset stay usable in portrait',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final provider = _Provider();
      final service = RealWeatherService(provider: provider, cache: _Cache());
      addTearDown(service.dispose);
      var prefs = const RealWeatherPreferences();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates:
              PokeMapPlayerLocalizations.localizationsDelegates,
          supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
          theme: PokeMapPlayerTheme.dark(),
          home: Scaffold(
            body: PlayerMenuThemeScope(
              child: SingleChildScrollView(
                child: StatefulBuilder(
                  builder: (context, setState) => RuntimeRealWeatherOptions(
                    preferences: prefs,
                    service: service,
                    onChanged: (value) async => setState(() => prefs = value),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('real-weather-enabled')));
      await tester.pumpAndSettle();
      expect(prefs.enabled, isTrue);
      expect(provider.locates, 0);
      await tester.tap(find.byKey(const ValueKey('real-weather-city')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('real-weather-city-query')),
        'Paris',
      );
      await tester.tap(find.byKey(const ValueKey('real-weather-city-search')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paris, France'));
      await tester.pumpAndSettle();
      expect(prefs.location!.label, 'Paris, France');
      await tester.ensureVisible(find.byKey(const ValueKey('real-weather-ip')));
      await tester.tap(find.byKey(const ValueKey('real-weather-ip')));
      await tester.pumpAndSettle();
      expect(prefs.location, isNull);
      expect(provider.locates, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

class _Provider implements RealWeatherProvider {
  int locates = 0;
  @override
  Future<RealWeatherLocation> locate() async {
    locates++;
    throw StateError('No automatic network from a setting');
  }

  @override
  Future<List<RealWeatherLocation>> search(String query) async => [
    RealWeatherLocation(
      latitude: 48.86,
      longitude: 2.35,
      label: 'Paris, France',
    ),
  ];
  @override
  Future<RealWeatherSnapshot> fetch(
    RealWeatherLocation location,
    DateTime now,
  ) async => throw StateError('No automatic forecast from a setting');
}

class _Cache implements RealWeatherCache {
  @override
  Future<RealWeatherSnapshot?> read() async => null;
  @override
  Future<void> write(RealWeatherSnapshot snapshot) async {}
}
