import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pub_semver/pub_semver.dart';

import '../support/dashboard_notifier_harness.dart';

void main() {
  late Directory root;
  late InstalledGame game;
  late DashboardHarness harness;

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
    harness = buildDashboardHarness(
      libraryStore: store,
      activityReader: (_) async => HubGameActivity(
        canContinue: true,
        lastSaveAt: DateTime.utc(2026, 7, 25),
      ),
    );
    await harness.notifier.initialize();
  });

  tearDown(() async {
    harness.dispose();
    if (await root.exists()) await root.delete(recursive: true);
  });

  testWidgets(
    'New game opens the player shell and returning refreshes the Hub',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      harness.notifier.selectGame(game.gameId);

      await tester.pumpWidget(
        harness.wrap(
          PokeMapHubApp(
            controller: harness.notifier,
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
        ),
      );

      // The console launches by inserting the hero cartridge; the legacy
      // desktop "new game" button no longer exists.
      final hero = find.byKey(
        const ValueKey<String>('avelune-room-hero-cartridge'),
      );
      expect(hero, findsOneWidget);
      await tester.tap(hero);
      await _settleInsertion(tester);
      expect(find.text('Lecteur Aube'), findsOneWidget);
      expect(hero, findsNothing);

      await tester.tap(find.text('Retour test'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Lecteur Aube'), findsNothing);
      expect(hero, findsOneWidget);
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
        harness.wrap(
          PokeMapHubApp(
            productName: 'Avelune',
            controller: harness.notifier,
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
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('avelune-room-hero-cartridge')),
      );
      await _settleInsertion(tester);
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

  testWidgets('mobile Settings opens the Avelune appearance settings',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final appearanceController = AveluneAppearanceController(
      store: AveluneAppearanceStore(supportRoot: root),
      customBackground: _FakeCustomBackground(),
    );
    await tester.runAsync(() => appearanceController.initialize());
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      harness.wrap(
        PokeMapHubApp(
          productName: 'Avelune',
          controller: harness.notifier,
          initializeController: false,
          appearanceController: appearanceController,
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-nav-settings')),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    // The approved settings sheet floats over the room rather than replacing
    // it, so the section does not change.
    // The approved settings sheet floats over the room rather than replacing
    // it, so the section does not change. Rows are matched by key: this app is
    // pumped without a forced locale, so their labels are localised.
    expect(harness.snapshot.section, HubSection.home);
    for (final id in <String>[
      'appearance',
      'storage',
      'motion',
      'diagnostics',
    ]) {
      expect(
        find.byKey(ValueKey<String>('avelune-settings-row-$id')),
        findsOneWidget,
        reason: 'Row $id is missing from the settings sheet.',
      );
    }

    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-settings-row-appearance')),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(find.byType(AveluneAppearanceSettings), findsOneWidget);
  });

  testWidgets(
    'startup preference opens the most recent healthy game exactly once',
    (tester) async {
      unawaited(
        harness.notifier.updatePreferences(
          const PlayerPreferences().copyWith(
            launchMostRecentGameOnStartup: true,
          ),
        ),
      );

      // A desktop-sized window: the default 800x600 test viewport letterboxes
      // to 277 logical pixels wide, under the 280 px the room geometry needs.
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        harness.wrap(
          PokeMapHubApp(
            controller: harness.notifier,
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
        ),
      );
      await tester.pump();

      expect(find.text('Lecteur Aube'), findsOneWidget);

      await tester.tap(find.text('Retour automatique'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Lecteur Aube'), findsNothing);
      expect(find.text('POKEMAP HUB'), findsOneWidget);
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

class _FakeCustomBackground implements AveluneCustomBackgroundGateway {
  @override
  Future<AveluneCustomBackgroundImportOutcome> pickAndImport() async =>
      AveluneCustomBackgroundImportOutcome.cancelled;

  @override
  Future<bool> isCurrentValid() async => false;

  @override
  Future<void> delete() async {}

  @override
  String get imagePath => '';

  @override
  String get thumbnailPath => '';
}

/// Walks the insertion sequence the hero cartridge starts before it launches.
///
/// Driven off the tokens rather than a fixed number of pumps: the sequence was
/// re-paced to let the console run its LED colours, and `pumpAndSettle` cannot
/// be used because the controller waits on timers that schedule no frame.
Future<void> _settleInsertion(WidgetTester tester) async {
  const motion = AveluneMotionTokens.standard;
  await tester.pump();
  await tester.pump();
  for (final phase in <Duration>[
    motion.insertionAlign,
    motion.insertionDescend,
    motion.insertionLatch,
    motion.insertionLaunchDelay,
  ]) {
    await tester.pump(phase);
    await tester.pump();
  }
  await tester.pump();
}
