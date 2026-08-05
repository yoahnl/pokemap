import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  testWidgets('empty Avelune home exposes the real import action',
      (tester) async {
    _setViewport(tester, const Size(390, 844));
    var imports = 0;

    await tester.pumpWidget(
      _app(
        HubShell(
          productName: 'Avelune',
          mobileConsoleExperience: true,
          snapshot: HubDashboardSnapshot.ready(
            library: GameLibrary.empty(),
            games: const <HubGameView>[],
          ),
          actions: HubUiActions(onImportRequested: () => imports++),
          onSectionSelected: (_) {},
          onQueryChanged: (_) {},
          onGameSelected: (_) {},
          onGameDetailsClosed: () {},
          onPreferencesChanged: (_) {},
        ),
      ),
    );

    expect(find.byType(AveluneMobileHome), findsOneWidget);
    expect(find.byType(AveluneConsole), findsOneWidget);
    expect(find.text('Aucun jeu installé'), findsOneWidget);
    expect(find.text('Aucune activité récente'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('avelune-hero-cartridge')),
        findsNothing);
    expect(
      find.byKey(const ValueKey<String>('avelune-add-game-cartridge')),
      findsOneWidget,
    );
    expect(find.byType(AveluneBottomNavigation), findsOneWidget);
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.text('Bibliothèque'), findsNothing);
    expect(find.text('Diagnostics'), findsNothing);
    final systemOverlay = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byWidgetPredicate(
        (widget) => widget is AnnotatedRegion<SystemUiOverlayStyle>,
      ),
    );
    expect(systemOverlay.value.statusBarIconBrightness, Brightness.light);
    expect(
      systemOverlay.value.systemNavigationBarIconBrightness,
      Brightness.light,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-empty-import')),
    );
    expect(imports, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('packaged materials create physical console and shelf depth',
      (tester) async {
    _setViewport(tester, const Size(390, 844));
    final game = _view(
      id: 'aube',
      title: 'Aube',
      installedAt: DateTime.utc(2026, 8),
    );

    await tester.pumpWidget(
      _app(
        AveluneMobileHome(
          productName: 'Avelune',
          snapshot: _snapshot(<HubGameView>[game]),
          actions: HubUiActions(onNewGame: (_) {}),
        ),
      ),
    );

    for (final key in <String>[
      'avelune-console-material-texture',
      'avelune-console-wear-texture',
      'avelune-console-silhouette',
      'avelune-console-insertion-well',
      'avelune-console-slot-lip',
      'avelune-console-faceplate',
      'avelune-hero-wood-dock',
      'avelune-furniture-bridge',
      'avelune-furniture-drawers',
      'avelune-game-cabinet',
      'avelune-shelf-cavity',
      'avelune-shelf-top-rail',
      'avelune-shelf-wood-texture',
      'avelune-shelf-plinth',
      'avelune-recent-wood-frame',
    ]) {
      expect(find.byKey(ValueKey<String>(key)), findsOneWidget);
    }

    final materialImages = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .whereType<AssetImage>()
        .map((image) => image.assetName)
        .toSet();
    expect(
      materialImages,
      containsAll(<String>{
        'assets/avelune/materials/matte_abs_grain.webp',
        'assets/avelune/materials/aged_abs_wear.webp',
        'assets/avelune/materials/dark_walnut_satin.webp',
      }),
    );

    final well = tester.getRect(
      find.byKey(
        const ValueKey<String>('avelune-console-insertion-well'),
      ),
    );
    final lip = tester.getRect(
      find.byKey(const ValueKey<String>('avelune-console-slot-lip')),
    );
    final console = tester.getRect(find.byType(AveluneConsole));
    expect(well.center.dx, closeTo(console.center.dx, 1));
    expect(lip.top, lessThan(well.bottom));
    expect(lip.bottom, greaterThan(well.top));
    final cabinet = tester.getRect(
      find.byKey(const ValueKey<String>('avelune-game-cabinet')),
    );
    final cavity = tester.getRect(
      find.byKey(const ValueKey<String>('avelune-shelf-cavity')),
    );
    final plinth = tester.getRect(
      find.byKey(const ValueKey<String>('avelune-shelf-plinth')),
    );
    final shelfCartridge = tester.getRect(
      find.byKey(
        const ValueKey<String>('avelune-shelf-games.example.aube'),
      ),
    );
    expect(cavity.left, greaterThan(cabinet.left));
    expect(cavity.right, lessThan(cabinet.right));
    expect(plinth.bottom, closeTo(cabinet.bottom, 1));
    expect(shelfCartridge.bottom, closeTo(plinth.top, 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting a shelf cartridge exchanges the hero before launch',
      (tester) async {
    _setViewport(tester, const Size(390, 844));
    final first = _view(
      id: 'aube',
      title: 'Aube',
      installedAt: DateTime.utc(2026, 8),
    );
    final second = _view(
      id: 'train',
      title: 'Le Train de 17h42',
      accentColor: '#126E78',
      installedAt: DateTime.utc(2026, 8, 2),
    );
    String? launched;
    var imports = 0;

    await tester.pumpWidget(
      _app(
        AveluneMobileHome(
          productName: 'Avelune',
          snapshot: _snapshot(<HubGameView>[first, second]),
          actions: HubUiActions(
            onImportRequested: () => imports++,
            onNewGame: (game) => launched = game.game.gameId,
          ),
          referenceTime: DateTime.utc(2026, 8, 4, 12),
        ),
      ),
    );

    expect(
      tester
          .widget<AveluneCartridge>(
            find.byKey(
              const ValueKey<String>('avelune-hero-cartridge'),
            ),
          )
          .title,
      'Le Train de 17h42',
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-shelf-games.example.aube')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));

    expect(
      find.byKey(const ValueKey<String>('avelune-cartridge-exchange')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('avelune-cartridge-exchange'),
        ),
        matching: find.byType(AveluneCartridge),
      ),
      findsNWidgets(2),
    );
    final incomingExchange = tester.widget<FractionalTranslation>(
      find
          .ancestor(
            of: find.byWidgetPredicate(
              (widget) => widget is AveluneCartridge && widget.title == 'Aube',
            ),
            matching: find.byType(FractionalTranslation),
          )
          .first,
    );
    final outgoingExchange = tester.widget<FractionalTranslation>(
      find
          .ancestor(
            of: find.byWidgetPredicate(
              (widget) =>
                  widget is AveluneCartridge &&
                  widget.title == 'Le Train de 17h42',
            ),
            matching: find.byType(FractionalTranslation),
          )
          .first,
    );
    expect(incomingExchange.translation.dx, greaterThan(0));
    expect(outgoingExchange.translation.dx, lessThan(0));
    final homeScrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const ValueKey<String>('avelune-home-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(homeScrollable.position.pixels, 0);
    await tester.pump(const Duration(milliseconds: 520));

    final hero = tester.widget<AveluneCartridge>(
      find.byKey(const ValueKey<String>('avelune-hero-cartridge')),
    );
    expect(hero.title, 'Aube');
    expect(hero.displaySize, AveluneCartridgeDisplaySize.hero);
    expect(find.text('Insérer pour jouer'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('avelune-primary-action')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-hero-cartridge')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    expect(launched, isNull);
    final insertion = tester.widget<Transform>(
      find.byKey(const ValueKey<String>('avelune-inserting-cartridge')),
    );
    expect(insertion.transform.storage[13], greaterThan(0));
    final firstInsertionProgress = tester
        .widget<AveluneConsole>(find.byType(AveluneConsole))
        .insertionProgress;
    expect(firstInsertionProgress, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 80));
    final secondInsertionProgress = tester
        .widget<AveluneConsole>(find.byType(AveluneConsole))
        .insertionProgress;
    expect(secondInsertionProgress, greaterThan(firstInsertionProgress));
    await _finishCartridgeInsertion(tester);
    expect(launched, 'games.example.aube');

    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-add-game-cartridge')),
    );
    expect(imports, 1);
  });

  testWidgets('Continue and recent activity use existing latest-save data',
      (tester) async {
    _setViewport(tester, const Size(390, 844));
    final older = _view(
      id: 'aube',
      title: 'Aube',
      canContinue: true,
      lastSaveAt: DateTime.utc(2026, 8, 3, 12),
    );
    final latest = _view(
      id: 'selbrume',
      title: 'Les Brumes de Selbrume',
      canContinue: true,
      lastSaveAt: DateTime.utc(2026, 8, 4, 10),
      accentColor: '#663399',
    );
    final continued = <String>[];

    await tester.pumpWidget(
      _app(
        AveluneMobileHome(
          productName: 'Avelune',
          snapshot: _snapshot(<HubGameView>[older, latest]),
          actions: HubUiActions(
            onContinue: (game) => continued.add(game.game.gameId),
          ),
          referenceTime: DateTime.utc(2026, 8, 4, 12),
        ),
      ),
    );

    final hero = tester.widget<AveluneCartridge>(
      find.byKey(const ValueKey<String>('avelune-hero-cartridge')),
    );
    expect(hero.title, 'Les Brumes de Selbrume');
    expect(find.text('Insérer pour continuer'), findsOneWidget);
    expect(find.text('Dernière partie • Il y a 2 h'), findsOneWidget);
    expect(find.text('ACTIVITÉ RÉCENTE'), findsOneWidget);
    expect(find.text('Dernière sauvegarde'), findsNWidgets(2));

    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-hero-cartridge')),
    );
    await tester.pump();
    await _finishCartridgeInsertion(tester);
    expect(continued, <String>['games.example.selbrume']);

    await tester.drag(
      find.byKey(const ValueKey<String>('avelune-home-scroll')),
      const Offset(0, -720),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.byKey(
        const ValueKey<String>('avelune-activity-games.example.aube'),
      ),
    );
    expect(
      continued,
      <String>['games.example.selbrume', 'games.example.aube'],
    );
  });

  testWidgets('invalid games stay selectable but cannot claim a launch',
      (tester) async {
    _setViewport(tester, const Size(390, 844));
    final healthy = _view(id: 'aube', title: 'Aube');
    final invalid = _view(
      id: 'invalide',
      title: 'Jeu cassé',
      installationHealthy: false,
    );
    var launchCount = 0;

    await tester.pumpWidget(
      _app(
        AveluneMobileHome(
          productName: 'Avelune',
          snapshot: _snapshot(<HubGameView>[healthy, invalid]),
          actions: HubUiActions(onNewGame: (_) => launchCount++),
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('avelune-shelf-games.example.invalide'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 520));

    expect(find.text('JEU INDISPONIBLE'), findsOneWidget);
    expect(
      find.text('Certains fichiers nécessaires sont manquants.'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-hero-cartridge')),
      warnIfMissed: false,
    );
    expect(launchCount, 0);
  });

  testWidgets('mobile navigation contains only Home and Settings',
      (tester) async {
    _setViewport(tester, const Size(390, 844));
    HubSection? selectedSection;

    await tester.pumpWidget(
      _app(
        HubShell(
          productName: 'Avelune',
          mobileConsoleExperience: true,
          snapshot: _snapshot(<HubGameView>[
            _view(id: 'aube', title: 'Aube'),
          ]),
          actions: const HubUiActions(),
          onSectionSelected: (section) => selectedSection = section,
          onQueryChanged: (_) {},
          onGameSelected: (_) {},
          onGameDetailsClosed: () {},
          onPreferencesChanged: (_) {},
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-nav-settings')),
    );
    expect(selectedSection, HubSection.preferences);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('personalization accent colors the canonical cartridge shell',
      (tester) async {
    _setViewport(tester, const Size(390, 844));
    final game = _view(
      id: 'aube',
      title: 'Aube',
      accentColor: '#126E78',
    );

    await tester.pumpWidget(
      _app(
        AveluneMobileHome(
          productName: 'Avelune',
          snapshot: _snapshot(<HubGameView>[game]),
          actions: HubUiActions(onNewGame: (_) {}),
        ),
      ),
    );

    final context = tester.element(find.byType(AveluneMobileHome));
    final expected = aveluneShellColorFor(context, game);
    final cartridges = tester
        .widgetList<AveluneCartridge>(find.byType(AveluneCartridge))
        .where((cartridge) => cartridge.gameId == game.game.gameId);
    expect(cartridges, isNotEmpty);
    expect(
      cartridges.map((cartridge) => cartridge.shellColor).toSet(),
      <Color?>{expected},
    );
  });

  testWidgets('hero insertion remains accessible with reduced motion',
      (tester) async {
    _setViewport(tester, const Size(320, 568));
    final semantics = tester.ensureSemantics();
    final game = _view(
      id: 'aube',
      title: 'Aube',
      canContinue: true,
      lastSaveAt: DateTime.utc(2026, 8, 4, 10),
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          disableAnimations: true,
          textScaler: TextScaler.linear(1.3),
        ),
        child: _app(
          AveluneMobileHome(
            productName: 'Avelune',
            snapshot: _snapshot(<HubGameView>[game]),
            actions: HubUiActions(onContinue: (_) {}),
            referenceTime: DateTime.utc(2026, 8, 4, 12),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 4));

    final action = find.byKey(
      const ValueKey<String>('avelune-hero-cartridge'),
    );
    final node = tester.getSemantics(action);
    expect(node.label, contains('Insérer pour continuer'));
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);

    final gesture = await tester.startGesture(tester.getCenter(action));
    await tester.pump(kLongPressTimeout);
    await gesture.up();
    await tester.pump();
    expect(find.byType(AveluneGameDetailsScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('avelune-details-hero-flight')),
      findsNothing,
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
    semantics.dispose();
  });

  testWidgets('long press opens real game details through artwork Hero',
      (tester) async {
    _setViewport(tester, const Size(390, 844));
    final game = _view(
      id: 'aube',
      title: 'Aube',
      description: 'Une aventure au bord des nuages.',
      canContinue: true,
      lastSaveAt: DateTime.utc(2026, 8, 4, 10),
    );

    await tester.pumpWidget(
      _app(
        AveluneMobileHome(
          productName: 'Avelune',
          snapshot: _snapshot(<HubGameView>[game]),
          actions: HubUiActions(onContinue: (_) {}),
          referenceTime: DateTime.utc(2026, 8, 4, 12),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('avelune-hero-artwork')),
      findsOneWidget,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey<String>('avelune-hero-cartridge')),
      ),
    );
    await tester.pump(kLongPressTimeout);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 120));

    expect(
      find.byKey(const ValueKey<String>('avelune-details-hero-flight')),
      findsOneWidget,
    );
    await tester.pumpAndSettle();

    expect(find.byType(AveluneGameDetailsScreen), findsOneWidget);
    expect(find.text('Une aventure au bord des nuages.'), findsOneWidget);
    expect(find.text('Studio Avelune'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('avelune-details-artwork')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('avelune-details-hero-flight')),
      findsNothing,
    );
    final fallback = tester.widget<Image>(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('avelune-details-artwork'),
        ),
        matching: find.byKey(
          const ValueKey<String>('avelune-fallback-artwork'),
        ),
      ),
    );
    expect(
      (fallback.image as AssetImage).assetName,
      'assets/avelune/artwork/fallback_moonlit_path.webp',
    );
  });

  for (final size in <Size>[
    const Size(320, 568),
    const Size(375, 667),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    testWidgets('console home stays scrollable at ${size.width}x${size.height}',
        (tester) async {
      _setViewport(tester, size);
      final games = List<HubGameView>.generate(
        10,
        (index) => _view(
          id: 'game-$index',
          title: index == 4
              ? 'Une aventure au nom excessivement long'
              : 'Aventure $index',
          canContinue: index.isEven,
          lastSaveAt: index.isEven
              ? DateTime.utc(2026, 8, 4).subtract(Duration(hours: index + 1))
              : null,
        ),
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: _app(
            HubShell(
              productName: 'Avelune',
              mobileConsoleExperience: true,
              snapshot: _snapshot(games),
              actions: const HubUiActions(),
              onSectionSelected: (_) {},
              onQueryChanged: (_) {},
              onGameSelected: (_) {},
              onGameDetailsClosed: () {},
              onPreferencesChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(AveluneGameShelf), findsOneWidget);
      final shelfCartridges = find.byWidgetPredicate(
        (widget) =>
            widget is AveluneCartridge &&
            widget.displaySize == AveluneCartridgeDisplaySize.shelf,
      );
      expect(shelfCartridges.evaluate().length, lessThan(games.length + 1));
      final visibleSizes = shelfCartridges
          .evaluate()
          .map((element) => tester.getSize(find.byElementPredicate(
                (candidate) => identical(candidate, element),
              )))
          .toList(growable: false);
      expect(visibleSizes.toSet(), hasLength(1));
      expect(tester.takeException(), isNull);
    });
  }
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
  DateTime? lastSaveAt,
  bool installationHealthy = true,
  String? accentColor,
  DateTime? installedAt,
  String? description,
}) {
  final version = InstalledGameVersion(
    gameVersion: Version.parse('1.0.0'),
    treeSha256: id.padRight(64, '0').substring(0, 64),
    installedAt: installedAt ?? DateTime.utc(2026, 8),
    receiptFileName: '$id.json',
    source: GamePackageInstallSource.localFile,
    signatureStatus: PackageSignatureStatus.notPresent,
  );
  return HubGameView(
    game: InstalledGame(
      gameId: 'games.example.$id',
      title: title,
      description: description,
      authorName: 'Studio Avelune',
      defaultLocale: 'fr',
      supportedLocales: const <String>['fr'],
      branding: InstalledGameBranding(accentColor: accentColor),
      current: version.pointer,
      versions: <InstalledGameVersion>[version],
    ),
    activity: HubGameActivity(
      canContinue: canContinue,
      lastSaveAt: lastSaveAt,
      playTimeSeconds: canContinue ? 3720 : 0,
      installationHealthy: installationHealthy,
    ),
  );
}

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: child,
    );

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _finishCartridgeInsertion(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 380));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 180));
  await tester.pump();
}
