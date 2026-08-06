import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pub_semver/pub_semver.dart';

/// Desktop must render the same console experience as mobile.
///
/// The shell used to branch on `mobileConsoleExperience`: phones got the Avelune
/// room while desktop got a separate navigation rail, library grid, game detail
/// view and preferences form. That second interface is gone; there is one home.
///
/// Because the room geometry is portrait and scroll-free, and the credenza is
/// sized off the content width, a landscape window letterboxes the scene rather
/// than stretching it.
void main() {
  setUpAll(_loadGoldenFonts);

  testWidgets('desktop renders the Avelune room, not a legacy rail',
      (tester) async {
    await _pumpShell(tester, const Size(1440, 900));

    expect(find.byType(AveluneRoomScene), findsOneWidget);
    expect(find.byType(AveluneBottomNavigation), findsOneWidget);
    expect(
      find.byType(NavigationRail),
      findsNothing,
      reason: 'The desktop navigation rail is part of the removed interface.',
    );
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('wide windows letterbox the scene to the portrait ratio',
      (tester) async {
    const size = Size(1440, 900);
    await _pumpShell(tester, size);

    final sceneRect = tester.getRect(find.byType(AveluneRoomScene));
    final expectedWidth = size.height * kAvelunePortraitAspectRatio;

    expect(sceneRect.width, closeTo(expectedWidth, 0.5));
    expect(sceneRect.height, closeTo(size.height, 0.5));
    expect(
      sceneRect.center.dx,
      closeTo(size.width / 2, 0.5),
      reason: 'The letterboxed scene must be centred in the window.',
    );
  });

  testWidgets('portrait viewports are not letterboxed', (tester) async {
    const size = Size(393, 852);
    await _pumpShell(tester, size);

    final sceneRect = tester.getRect(find.byType(AveluneRoomScene));
    expect(sceneRect.width, closeTo(size.width, 0.5));
    expect(sceneRect.height, closeTo(size.height, 0.5));
  });

  testWidgets('the desktop home is byte-identical in structure to mobile',
      (tester) async {
    await _pumpShell(tester, const Size(1280, 800));

    // The very keys the mobile gate asserts on.
    expect(
      find.byKey(const ValueKey<String>('avelune-home-header')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('avelune-hero-details-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('avelune-nav-pill')),
      findsOneWidget,
    );
    expect(find.byType(AveluneConsole), findsOneWidget);
  });

  testWidgets('the letterbox is filled with the room, not black bars',
      (tester) async {
    await _pumpShell(tester, const Size(1440, 900));

    expect(
      find.byKey(const ValueKey<String>('avelune-letterbox-backdrop')),
      findsOneWidget,
      reason: 'Flat black beside the scene reads as dead space on a desktop '
          'window; the room extends into it instead.',
    );
  });

  testWidgets('portrait viewports paint no backdrop', (tester) async {
    await _pumpShell(tester, const Size(393, 852));

    expect(
      find.byKey(const ValueKey<String>('avelune-letterbox-backdrop')),
      findsNothing,
      reason: 'Nothing to fill when the scene already spans the screen.',
    );
  });

  testWidgets('desktop visual gate', (tester) async {
    await _pumpShell(tester, const Size(1280, 800));
    await expectLater(
      find.byType(HubShell),
      matchesGoldenFile('goldens/avelune/desktop_home_1280x800.png'),
    );
  });

  testWidgets('a window below the supported minimum explains itself',
      (tester) async {
    await _pumpShell(tester, const Size(240, 320));

    expect(
      find.byKey(const ValueKey<String>('avelune-viewport-too-small')),
      findsOneWidget,
      reason: 'The room geometry rejects viewports under 280x480. Desktop '
          'windows are freely resizable, so the shell must say so instead of '
          'throwing.',
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpShell(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final games = <HubGameView>[
    _view(id: 'selbrume', title: 'Selbrume', canContinue: true),
    _view(id: 'train', title: 'Le Train de 17h42'),
  ];
  final snapshot = _snapshot(games);
  final actions = HubUiActions(
    onImportRequested: () {},
    onContinue: (_) {},
    onNewGame: (_) {},
  );

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: () {
        final theme =
            applyAveluneTheme(PokeMapPlayerTheme.dark(reducedMotion: true));
        return theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: 'AveluneGoldenSans'),
          primaryTextTheme:
              theme.primaryTextTheme.apply(fontFamily: 'AveluneGoldenSans'),
        );
      }(),
      home: HubShell(
        productName: 'Avelune',
        snapshot: snapshot,
        actions: actions,
        referenceTime: DateTime.utc(2026, 8, 4, 12),
        homeController: AveluneHomeController(
          snapshot: snapshot,
          actions: actions,
        ),
        onSectionSelected: (_) {},
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

HubDashboardSnapshot _snapshot(List<HubGameView> games) =>
    HubDashboardSnapshot.ready(
      library: GameLibrary(
        revision: 1,
        updatedAt: DateTime.utc(2026, 8, 4),
        games: games.map((view) => view.game).toList(growable: false),
      ),
      games: games,
    );

HubGameView _view({
  required String id,
  required String title,
  bool canContinue = false,
}) {
  final version = InstalledGameVersion(
    gameVersion: Version.parse('1.0.0'),
    treeSha256: id.padRight(64, '0').substring(0, 64),
    installedAt: DateTime.utc(2026, 8),
    receiptFileName: '$id.json',
    source: GamePackageInstallSource.localFile,
    signatureStatus: PackageSignatureStatus.notPresent,
  );
  return HubGameView(
    game: InstalledGame(
      gameId: 'games.example.$id',
      title: title,
      description: 'Les Brumes de $title',
      authorName: 'Studio Avelune',
      defaultLocale: 'fr',
      supportedLocales: const <String>['fr'],
      branding: const InstalledGameBranding(),
      current: version.pointer,
      versions: <InstalledGameVersion>[version],
    ),
    activity: HubGameActivity(
      canContinue: canContinue,
      lastSaveAt: canContinue ? DateTime.utc(2026, 8, 4, 10) : null,
      playTimeSeconds: canContinue ? 3720 : 0,
      installationHealthy: true,
    ),
  );
}

Future<void> _loadGoldenFonts() async {
  final bytes = await File(
    '../../packages/map_editor/assets/fonts/pokemap_capture_sans_regular.ttf',
  ).readAsBytes();
  final textLoader = FontLoader('AveluneGoldenSans')
    ..addFont(
      Future<ByteData>.value(ByteData.sublistView(Uint8List.fromList(bytes))),
    );
  final materialLoader = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait<void>(<Future<void>>[
    textLoader.load(),
    materialLoader.load(),
  ]);
}
