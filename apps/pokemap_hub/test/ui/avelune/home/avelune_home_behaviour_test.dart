import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pub_semver/pub_semver.dart';

// Production console-home behaviour driven through HubShell.
//
// The tests that pumped the pre-cutover AveluneMobileHome went with the widget
// itself; what remains here exercises the shipped screen.
void main() {
  testWidgets('empty Avelune home exposes the real import action',
      (tester) async {
    _setViewport(tester, const Size(390, 844));
    var imports = 0;
    final actions = HubUiActions(onImportRequested: () => imports++);
    final snapshot = HubDashboardSnapshot.ready(
      library: GameLibrary.empty(),
      games: const <HubGameView>[],
    );

    await tester.pumpWidget(
      _app(
        _shellWithController(
          snapshot: snapshot,
          actions: actions,
        ),
      ),
    );

    expect(find.byType(AveluneHomeScreen), findsOneWidget);
    expect(find.byType(AveluneConsole), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('avelune-game-shelf-add')),
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
      find.byKey(const ValueKey<String>('avelune-game-shelf-add')),
    );
    expect(imports, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile navigation contains only Home and Settings',
      (tester) async {
    _setViewport(tester, const Size(390, 844));
    HubSection? selectedSection;

    await tester.pumpWidget(
      _app(
        _shellWithController(
          snapshot: _snapshot(<HubGameView>[
            _view(id: 'aube', title: 'Aube'),
          ]),
          actions: const HubUiActions(),
          onSectionSelected: (section) => selectedSection = section,
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

  for (final size in <Size>[
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
            _shellWithController(
              snapshot: _snapshot(games),
              actions: const HubUiActions(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byKey(const ValueKey<String>('avelune-game-shelf-list')),
        findsOneWidget,
      );
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


HubShell _shellWithController({
  required HubDashboardSnapshot snapshot,
  required HubUiActions actions,
  ValueChanged<HubSection>? onSectionSelected,
}) {
  final controller = AveluneHomeController(
    snapshot: snapshot,
    actions: actions,
  );
  return HubShell(
    productName: 'Avelune',
    snapshot: snapshot,
    actions: actions,
    homeController: controller,
    onSectionSelected: onSectionSelected ?? (_) {},
  );
}
