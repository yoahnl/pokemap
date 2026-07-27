import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

void main() {
  testWidgets(
    'preferences expose localized responsive desktop display controls',
    (tester) async {
      tester.view.physicalSize = const Size(390, 720);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(
        tester.platformDispatcher.clearTextScaleFactorTestValue,
      );
      final driver = _MemoryDisplayDriver();
      final displayController = HubDisplayPreferencesController(
        store: _MemoryDisplayStore(),
        driver: driver,
      );
      addTearDown(displayController.dispose);
      await displayController.initialize();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
          localizationsDelegates:
              PokeMapPlayerLocalizations.localizationsDelegates,
          theme: PokeMapPlayerTheme.dark(),
          home: HubShell(
            snapshot: HubDashboardSnapshot.ready(
              library: GameLibrary.empty(),
              games: const <HubGameView>[],
              section: HubSection.preferences,
            ),
            actions: const HubUiActions(),
            displayPreferencesController: displayController,
            onSectionSelected: (_) {},
            onQueryChanged: (_) {},
            onGameSelected: (_) {},
            onGameDetailsClosed: () {},
            onPreferencesChanged: (_) {},
          ),
        ),
      );

      await tester.fling(
        find.byType(ListView),
        const Offset(0, -10000),
        2400,
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const ValueKey<String>('hub-display-preferences')),
        findsOneWidget,
      );
      expect(find.text('Mode d’affichage'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('hub-display-mode')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('hub-display-mode')),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Plein écran').last);
      await tester.pump(const Duration(milliseconds: 300));

      expect(driver.applied.last.mode, HubDisplayMode.fullscreen);
      expect(tester.takeException(), isNull);
    },
  );
}

final class _MemoryDisplayStore implements HubDisplayPreferencesGateway {
  HubDisplayPreferences value = const HubDisplayPreferences();

  @override
  Future<HubDisplayPreferences> load(HubDesktopPlatform platform) async =>
      value;

  @override
  Future<void> save(
    HubDesktopPlatform platform,
    HubDisplayPreferences preferences,
  ) async {
    value = preferences;
  }
}

final class _MemoryDisplayDriver implements HubDisplayDriver {
  final applied = <HubDisplayPreferences>[];

  @override
  HubDesktopPlatform get platform => HubDesktopPlatform.macos;

  @override
  Future<void> apply(HubDisplayPreferences preferences) async {
    applied.add(preferences);
  }
}
