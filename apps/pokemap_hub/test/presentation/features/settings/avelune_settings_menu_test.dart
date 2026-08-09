import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../../support/appearance_notifier_harness.dart';

/// Settings is the approved sheet, not a section swap.
///
/// The prototype keeps the room visible behind a bottom sheet titled
/// "Paramètres Avelune" listing Apparence, Stockage, Mouvement and Diagnostics.
/// The shell used to replace the whole home with the appearance page instead,
/// with no way to reach storage, motion or diagnostics at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadGoldenFonts);

  const iphone = Size(393, 852);

  late Directory root;
  late AppearanceHarness appearanceHarness;

  // Real file I/O has to happen outside the test body: inside it, the fake
  // async zone never completes `Directory.systemTemp.createTemp`.
  setUp(() async {
    root = await Directory.systemTemp.createTemp('avelune-settings-');
    appearanceHarness = buildAppearanceHarness(
      store: AveluneAppearanceStore(supportRoot: root),
      customBackground: _FakeCustomBackground(),
    );
    await appearanceHarness.notifier.initialize();
  });

  tearDown(() async {
    appearanceHarness.dispose();
    await root.delete(recursive: true);
  });

  testWidgets('the navigation opens the settings sheet over the room', (
    tester,
  ) async {
    await _pumpShell(tester, iphone, appearanceHarness);

    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-nav-settings')),
    );
    await _settleSheet(tester);

    expect(
      find.byKey(const ValueKey<String>('avelune-settings-menu')),
      findsOneWidget,
    );
    expect(find.text('Paramètres Avelune'), findsOneWidget);
    expect(
      find.byType(AveluneRoomScene),
      findsOneWidget,
      reason: 'The sheet floats over the room; it does not replace it.',
    );
  });

  testWidgets('the sheet lists the five approved destinations', (tester) async {
    await _pumpShell(tester, iphone, appearanceHarness);
    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-nav-settings')),
    );
    await _settleSheet(tester);

    expect(find.text('Apparence'), findsOneWidget);
    expect(find.text('Stockage'), findsOneWidget);
    expect(find.text('Mouvement'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);
    expect(find.text('Aide et confidentialité'), findsOneWidget);
  });

  testWidgets('support and privacy links open the public Avelune pages', (
    tester,
  ) async {
    final openedUris = <Uri>[];
    await _pumpShell(
      tester,
      iphone,
      appearanceHarness,
      onOpenExternalUrl: (uri) async {
        openedUris.add(uri);
        return true;
      },
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-nav-settings')),
    );
    await _settleSheet(tester);

    await tester.tap(find.text('Aide et confidentialité'));
    await _settleSheet(tester);
    await tester.tap(find.text('Support'));
    await tester.pump();
    await tester.tap(find.text('Confidentialité'));
    await tester.pump();

    expect(openedUris, <Uri>[
      Uri.parse('https://yoahnl.github.io/avelune/support/'),
      Uri.parse('https://yoahnl.github.io/avelune/privacy/'),
    ]);
  });

  testWidgets('subtitles carry real state, not placeholders', (tester) async {
    await _pumpShell(tester, iphone, appearanceHarness);
    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-nav-settings')),
    );
    await _settleSheet(tester);

    // Default appearance is amber + ivory, labelled Ambre and Ivoire.
    expect(find.text('Ambre · Ivoire'), findsOneWidget);
    // Two installed games and the snapshot's real used bytes.
    expect(find.textContaining('2 jeux'), findsOneWidget);
    expect(find.textContaining('1.5 Mo'), findsOneWidget);
  });

  testWidgets('Apparence opens the real appearance settings', (tester) async {
    await _pumpShell(tester, iphone, appearanceHarness);
    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-nav-settings')),
    );
    await _settleSheet(tester);

    await tester.tap(find.text('Apparence'));
    await _settleSheet(tester);

    expect(find.byType(AveluneAppearanceSettings), findsOneWidget);
  });

  testWidgets('Stockage reports the real figures', (tester) async {
    await _pumpShell(tester, iphone, appearanceHarness);
    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-nav-settings')),
    );
    await _settleSheet(tester);

    await tester.tap(find.text('Stockage'));
    await _settleSheet(tester);

    expect(
      find.byKey(const ValueKey<String>('avelune-storage-panel')),
      findsOneWidget,
    );
    expect(find.textContaining('1.5 Mo'), findsWidgets);
  });

  testWidgets('settings sheet visual gate', (tester) async {
    await _pumpShell(tester, iphone, appearanceHarness);
    await _precacheRoomMaterials(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-nav-settings')),
    );
    await _settleSheet(tester);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../../goldens/avelune/settings_sheet_393x852.png'),
    );
  });

  testWidgets('the sheet stays on the Home section', (tester) async {
    final observed = <HubSection>[];
    await _pumpShell(
      tester,
      iphone,
      appearanceHarness,
      onSectionSelected: observed.add,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-nav-settings')),
    );
    await _settleSheet(tester);

    expect(
      observed,
      isEmpty,
      reason:
          'Opening the sheet is not a navigation change; the room stays '
          'mounted underneath and the Home tab stays selected.',
    );
  });
}

Future<void> _pumpShell(
  WidgetTester tester,
  Size size,
  AppearanceHarness appearance, {
  ValueChanged<HubSection>? onSectionSelected,
  Future<bool> Function(Uri)? onOpenExternalUrl,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final games = <HubGameView>[
    _view(id: 'selbrume', title: 'Selbrume', canContinue: true),
    _view(id: 'train', title: 'Le Train de 17h42'),
  ];
  final snapshot = HubDashboardSnapshot.ready(
    library: GameLibrary(
      revision: 1,
      updatedAt: DateTime.utc(2026, 8, 4),
      games: games.map((view) => view.game).toList(growable: false),
    ),
    games: games,
    storage: const HubStorageSnapshot(
      usedBytes: 1572864,
      availableBytes: 10485760,
    ),
  );
  final actions = HubUiActions(
    onImportRequested: () {},
    onContinue: (_) {},
    onNewGame: (_) {},
  );

  await tester.pumpWidget(
    appearance.wrap(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('fr'),
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        theme: () {
          final theme = applyAveluneTheme(
            PokeMapPlayerTheme.dark(reducedMotion: true),
          );
          return theme.copyWith(
            textTheme: theme.textTheme.apply(fontFamily: 'AveluneGoldenSans'),
            primaryTextTheme: theme.primaryTextTheme.apply(
              fontFamily: 'AveluneGoldenSans',
            ),
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
          appearanceController: appearance.notifier,
          onSectionSelected: onSectionSelected ?? (_) {},
          onOpenExternalUrl: onOpenExternalUrl,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

/// Bounded pumps: pumpAndSettle never returns in this shell, which keeps
/// indeterminate progress indicators alive in some states.
Future<void> _settleSheet(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> _precacheRoomMaterials(WidgetTester tester) async {
  final room = find.byType(AveluneRoomScene);
  final context = tester.element(room);
  await tester.runAsync(
    () => Future.wait<void>(<Future<void>>[
      for (final asset in AveluneMaterialCatalog.cartridgeLayers)
        precacheImage(AssetImage(asset.path), context),
      for (final asset in AveluneMaterialCatalog.consoleLayers)
        precacheImage(AssetImage(asset.path), context),
      precacheImage(
        const AssetImage(kAveluneFallbackArtworkAssetPath),
        context,
      ),
      precacheImage(
        const AssetImage('assets/avelune/room/backgrounds/amber.webp'),
        context,
      ),
      precacheImage(
        const AssetImage('assets/avelune/room/furniture/credenza_ivory.webp'),
        context,
      ),
    ]),
  );
  await tester.pump(const Duration(milliseconds: 100));
  _markSubtreeNeedsPaint(tester.renderObject(room));
  await tester.pump();
}

void _markSubtreeNeedsPaint(RenderObject object) {
  object.markNeedsPaint();
  object.visitChildren(_markSubtreeNeedsPaint);
}

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

class _FakeCustomBackground implements AveluneCustomBackgroundGateway {
  @override
  Future<AveluneCustomBackgroundImportOutcome> pickAndImport(
    AveluneBackgroundSource source,
  ) async => AveluneCustomBackgroundImportOutcome.cancelled;

  @override
  Future<bool> isCurrentValid() async => false;

  @override
  Future<void> delete() async {}

  @override
  String get imagePath => '';

  @override
  String get thumbnailPath => '';
}

Future<void> _loadGoldenFonts() async {
  final bytes =
      await File(
        '../../packages/map_editor/assets/fonts/pokemap_capture_sans_regular.ttf',
      ).readAsBytes();
  final textLoader = FontLoader('AveluneGoldenSans')..addFont(
    Future<ByteData>.value(ByteData.sublistView(Uint8List.fromList(bytes))),
  );
  final materialLoader = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  // The Avelune surfaces draw Cupertino glyphs; without its font every icon
  // records as an empty box in the goldens.
  // The family name has to carry the package prefix: CupertinoIcons
  // declares a fontPackage, so Flutter resolves it as
  // `packages/cupertino_icons/CupertinoIcons`.
  final cupertinoLoader = FontLoader('packages/cupertino_icons/CupertinoIcons')
    ..addFont(
      rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
    );
  await Future.wait<void>(<Future<void>>[
    textLoader.load(),
    materialLoader.load(),
    cupertinoLoader.load(),
  ]);
}
