import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final referenceTime = DateTime.utc(2026, 8, 4, 12);

  setUpAll(_loadGoldenFonts);

  testWidgets('Avelune standard mobile visual gate', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(390, 844),
      snapshot: _snapshot(_games(withSaves: true)),
      referenceTime: referenceTime,
    );

    await expectLater(
      find.byKey(const ValueKey<String>('avelune-golden-root')),
      matchesGoldenFile('goldens/avelune/home_390x844.png'),
    );
  });

  testWidgets('Avelune small mobile visual gate', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(320, 568),
      snapshot: _snapshot(_games(withSaves: true)),
      referenceTime: referenceTime,
    );

    await expectLater(
      find.byKey(const ValueKey<String>('avelune-golden-root')),
      matchesGoldenFile('goldens/avelune/home_320x568.png'),
    );
  });

  testWidgets('Avelune empty-library visual gate', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(390, 844),
      snapshot: HubDashboardSnapshot.ready(
        library: GameLibrary.empty(),
        games: const <HubGameView>[],
      ),
      referenceTime: referenceTime,
    );

    await expectLater(
      find.byKey(const ValueKey<String>('avelune-golden-root')),
      matchesGoldenFile('goldens/avelune/empty_390x844.png'),
    );
  });

  testWidgets('Avelune no-save visual gate', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(430, 932),
      snapshot: _snapshot(_games(withSaves: false)),
      referenceTime: referenceTime,
    );

    await expectLater(
      find.byKey(const ValueKey<String>('avelune-golden-root')),
      matchesGoldenFile('goldens/avelune/no_save_430x932.png'),
    );
  });

  testWidgets('Avelune cartridge insertion visual gate', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(390, 844),
      snapshot: _snapshot(_games(withSaves: true)),
      referenceTime: referenceTime,
      disableAnimations: false,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-hero-cartridge')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byKey(const ValueKey<String>('avelune-golden-root')),
      matchesGoldenFile('goldens/avelune/inserting_390x844.png'),
    );
  });

  testWidgets('Avelune cartridge exchange visual gate', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(390, 844),
      snapshot: _snapshot(_games(withSaves: true)),
      referenceTime: referenceTime,
      disableAnimations: false,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('avelune-shelf-games.visual.train'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));

    await expectLater(
      find.byKey(const ValueKey<String>('avelune-golden-root')),
      matchesGoldenFile('goldens/avelune/exchange_390x844.png'),
    );
  });

  testWidgets('Avelune game details visual gate', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(390, 844),
      snapshot: _snapshot(_games(withSaves: true)),
      referenceTime: referenceTime,
    );

    await tester.longPress(
      find.byKey(const ValueKey<String>('avelune-hero-cartridge')),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey<String>('avelune-details-root')),
      matchesGoldenFile('goldens/avelune/details_390x844.png'),
    );
  });
}

Future<void> _pumpGolden(
  WidgetTester tester, {
  required Size size,
  required HubDashboardSnapshot snapshot,
  required DateTime referenceTime,
  bool disableAnimations = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final theme = applyAveluneTheme(
    PokeMapPlayerTheme.dark(reducedMotion: true),
  );
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: 'AveluneGoldenSans'),
        primaryTextTheme: theme.primaryTextTheme.apply(
          fontFamily: 'AveluneGoldenSans',
        ),
      ),
      home: RepaintBoundary(
        key: const ValueKey<String>('avelune-golden-root'),
        child: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: AveluneMobileHome(
                    productName: 'Avelune',
                    snapshot: snapshot,
                    actions: HubUiActions(
                      onImportRequested: () {},
                      onContinue: (_) {},
                      onNewGame: (_) {},
                    ),
                    referenceTime: referenceTime,
                  ),
                ),
                AveluneBottomNavigation(
                  selectedSection: HubSection.home,
                  onSectionSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(
    () => precacheImage(
      const AssetImage(kAveluneLogoAssetPath),
      tester.element(find.byType(AveluneMobileHome)),
    ),
  );
  if (disableAnimations) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
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
  await Future.wait(<Future<void>>[textLoader.load(), materialLoader.load()]);
}

List<HubGameView> _games({required bool withSaves}) => <HubGameView>[
      _view(
        id: 'selbrume',
        title: 'Selbrume',
        accentColor: '#64358A',
        installedAt: DateTime.utc(2026, 8, 3),
        lastSaveAt: withSaves ? DateTime.utc(2026, 8, 4, 10) : null,
      ),
      _view(
        id: 'train',
        title: 'Le Train de 17h42',
        accentColor: '#126E78',
        installedAt: DateTime.utc(2026, 8, 2),
        lastSaveAt: withSaves ? DateTime.utc(2026, 8, 3, 12) : null,
      ),
      _view(
        id: 'demo',
        title: 'Démo technique',
        accentColor: '#33343B',
        installedAt: DateTime.utc(2026, 8),
        lastSaveAt: withSaves ? DateTime.utc(2026, 8) : null,
      ),
    ];

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
  required String accentColor,
  required DateTime installedAt,
  required DateTime? lastSaveAt,
}) {
  final version = InstalledGameVersion(
    gameVersion: Version.parse('1.0.0'),
    treeSha256: id.padRight(64, '0').substring(0, 64),
    installedAt: installedAt,
    receiptFileName: '$id.json',
    source: GamePackageInstallSource.localFile,
    signatureStatus: PackageSignatureStatus.notPresent,
  );
  return HubGameView(
    game: InstalledGame(
      gameId: 'games.visual.$id',
      title: title,
      authorName: 'Studio Avelune',
      defaultLocale: 'fr',
      supportedLocales: const <String>['fr'],
      branding: InstalledGameBranding(accentColor: accentColor),
      description: 'Une aventure façonnée pour la console Avelune.',
      current: version.pointer,
      versions: <InstalledGameVersion>[version],
    ),
    activity: HubGameActivity(
      canContinue: lastSaveAt != null,
      lastSaveAt: lastSaveAt,
      playTimeSeconds: lastSaveAt == null ? 0 : 3720,
    ),
  );
}
