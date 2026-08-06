import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  late Directory root;
  late InstalledGame game;
  late HubDashboardController controller;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hub-app-player-');
    game = _installedGame();
    final store = GameLibraryStore(supportRoot: root);
    await store.save(
      GameLibrary(
        revision: 1,
        updatedAt: DateTime.utc(2026, 7, 25),
        games: <InstalledGame>[game],
      ),
    );
    controller = HubDashboardController(
      libraryStore: store,
      activityReader: (_) async => HubGameActivity(
        canContinue: true,
        lastSaveAt: DateTime.utc(2026, 7, 25),
      ),
    );
    await controller.initialize();
  });

  tearDown(() async {
    controller.dispose();
    if (await root.exists()) await root.delete(recursive: true);
  });

  testWidgets(
    'New game opens the player shell and returning refreshes the Hub',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      controller.selectGame(game.gameId);

      await tester.pumpWidget(
        PokeMapHubApp(
          controller: controller,
          initializeController: false,
          playerBuilder: (context, selected, intent, onHubRequested) =>
              Scaffold(
            body: Column(
              children: <Widget>[
                Text('Lecteur ${selected.game.title}'),
                FilledButton(
                  onPressed: () => onHubRequested(),
                  child: const Text('Retour test'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
      await tester.pump();
      expect(find.text('Lecteur Aube'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);

      await tester.tap(find.text('Retour test'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Lecteur Aube'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'mobile Continue forwards an explicit resume intent to the real player',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      HubPlayerLaunchIntent? launchIntent;

      await tester.pumpWidget(
        PokeMapHubApp(
          productName: 'Avelune',
          mobileConsoleExperience: true,
          controller: controller,
          initializeController: false,
          playerBuilder: (
            context,
            selected,
            intent,
            onHubRequested,
          ) {
            launchIntent = intent;
            return Scaffold(body: Text('Lecteur ${selected.game.title}'));
          },
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('avelune-room-hero-cartridge')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump();
      await tester.pump();
      // Advance through insertion animation: align 120ms, descend 300ms,
      // latch 120ms, launch delay 80ms.
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump();
      await tester.pump();

      expect(launchIntent, HubPlayerLaunchIntent.continueGame);
      expect(find.text('Lecteur Aube'), findsOneWidget);
    },
  );

  testWidgets('mobile Settings opens the existing preferences screen',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      PokeMapHubApp(
        productName: 'Avelune',
        mobileConsoleExperience: true,
        controller: controller,
        initializeController: false,
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-nav-settings')),
    );
    await tester.pump();

    expect(controller.snapshot.section, HubSection.preferences);
    expect(find.byType(AveluneMobileHome), findsNothing);
    expect(
      find.byType(DropdownButtonFormField<PlayerLanguage>),
      findsOneWidget,
    );
  });

  testWidgets(
    'startup preference opens the most recent healthy game exactly once',
    (tester) async {
      unawaited(
        controller.updatePreferences(
          const PlayerPreferences().copyWith(
            launchMostRecentGameOnStartup: true,
          ),
        ),
      );

      await tester.pumpWidget(
        PokeMapHubApp(
          controller: controller,
          initializeController: false,
          playerBuilder: (context, selected, intent, onHubRequested) =>
              Scaffold(
            body: Column(
              children: <Widget>[
                Text('Lecteur ${selected.game.title}'),
                FilledButton(
                  onPressed: () => onHubRequested(),
                  child: const Text('Retour automatique'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Lecteur Aube'), findsOneWidget);

      await tester.tap(find.text('Retour automatique'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Lecteur Aube'), findsNothing);
      expect(find.text('PokeMap Hub'), findsOneWidget);
    },
  );
}

InstalledGame _installedGame() {
  final version = InstalledGameVersion(
    gameVersion: Version.parse('1.2.0'),
    treeSha256: 'b' * 64,
    installedAt: DateTime.utc(2026, 7, 25),
    receiptFileName: '1.2.0-${'b' * 64}.json',
    source: GamePackageInstallSource.localFile,
    signatureStatus: PackageSignatureStatus.notPresent,
  );
  return InstalledGame(
    gameId: 'games.example.aube',
    title: 'Aube',
    description: 'Une aventure générique.',
    authorName: 'Studio Brume',
    defaultLocale: 'fr',
    supportedLocales: const <String>['fr'],
    current: version.pointer,
    versions: <InstalledGameVersion>[version],
  );
}
