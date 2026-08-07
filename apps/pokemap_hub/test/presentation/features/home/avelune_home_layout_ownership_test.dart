import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pub_semver/pub_semver.dart';

final Finder _navPill = find.byKey(const ValueKey<String>('avelune-nav-pill'));

// AVELUNE-500 regression contract.
//
// The bottom navigation must float above the room scene instead of stealing
// layout height from it. When it steals height, the safe-area insets are
// subtracted twice and `navigationRect` is reserved for a bar that lives
// outside the scene, which drops a 393x852 iPhone from `regular` to `compact`
// and shrinks every object in the room.
void main() {
  const iphone = Size(393, 852);
  const iphoneInsets = EdgeInsets.only(top: 47, bottom: 34);

  testWidgets('room scene owns the full viewport on a 393x852 iPhone',
      (tester) async {
    await _pumpConsoleShell(tester, size: iphone, insets: iphoneInsets);

    final scene = tester.widget<AveluneRoomScene>(find.byType(AveluneRoomScene));

    expect(
      scene.geometry.viewportSize.height,
      iphone.height,
      reason: 'The scene must lay out against the whole screen, not the screen '
          'minus the bottom navigation.',
    );
    expect(
      scene.geometry.sizeClass,
      AveluneHomeSizeClass.regular,
      reason: 'A 393x852 iPhone leaves 771 logical pixels of content, which is '
          'above the 700 px regular threshold.',
    );
    expect(scene.geometry.hidesNonEssentialMetadata, isFalse);
    expect(scene.geometry.heroCartridgeSize.height, 148);
  });

  testWidgets('bottom navigation floats over the scene as an inset pill',
      (tester) async {
    await _pumpConsoleShell(tester, size: iphone, insets: iphoneInsets);

    final sceneRect = tester.getRect(find.byType(AveluneRoomScene));
    final navRect = tester.getRect(_navPill);

    expect(
      sceneRect.height,
      iphone.height,
      reason: 'The room scene must paint edge to edge behind the navigation.',
    );
    expect(
      sceneRect.overlaps(navRect),
      isTrue,
      reason: 'The navigation must overlay the scene, not sit below it.',
    );
    expect(
      navRect.left,
      greaterThan(0),
      reason: 'The approved prototype uses an inset floating pill, not a '
          'full-bleed bar.',
    );
    expect(navRect.right, lessThan(iphone.width));
  });

  testWidgets('floating navigation stays inside the reserved band',
      (tester) async {
    await _pumpConsoleShell(tester, size: iphone, insets: iphoneInsets);

    final scene = tester.widget<AveluneRoomScene>(find.byType(AveluneRoomScene));
    final navRect = tester.getRect(_navPill);

    expect(
      navRect.top,
      greaterThanOrEqualTo(scene.geometry.navigationRect.top),
      reason: 'The pill must not creep into the recent-activity band that the '
          'geometry reserves above it.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('details control opens the real game details screen',
      (tester) async {
    await _pumpConsoleShell(tester, size: iphone, insets: iphoneInsets);

    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-hero-details-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byType(AveluneGameDetailsScreen),
      findsOneWidget,
      reason: 'The production shell never wired any details route after the '
          'AVELUNE-500 cutover.',
    );
    expect(find.text('Selbrume'), findsWidgets);
  });
}

Future<void> _pumpConsoleShell(
  WidgetTester tester, {
  required Size size,
  required EdgeInsets insets,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final games = <HubGameView>[
    _view(id: 'selbrume', title: 'Selbrume', canContinue: true),
    _view(id: 'train', title: 'Le Train de 17h42'),
    _view(id: 'demo', title: 'Démo technique'),
  ];
  final snapshot = _snapshot(games);
  const actions = HubUiActions();

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: applyAveluneTheme(PokeMapPlayerTheme.dark()),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: insets,
            viewPadding: insets,
          ),
          child: HubShell(
            productName: 'Avelune',
            snapshot: snapshot,
            actions: actions,
            homeController: AveluneHomeController(
              snapshot: snapshot,
              actions: actions,
            ),
            onSectionSelected: (_) {},
          ),
        ),
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
