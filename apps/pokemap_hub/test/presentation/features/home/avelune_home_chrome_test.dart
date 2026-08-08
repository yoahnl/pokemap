import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

/// AVELUNE-500 chrome contract.
///
/// The cutover to `AveluneHomeScreen` dropped three elements the approved
/// prototype carries: the branded header, the hero details panel and the
/// insertion hint. None of them existed anywhere on the production path — the
/// only implementations lived in the pre-cutover `AveluneMobileHome`.
void main() {
  const iphone = Size(393, 852);
  const iphoneInsets = EdgeInsets.only(top: 47, bottom: 34);

  testWidgets('header carries the Avelune mark and wordmark', (tester) async {
    await _pumpHome(tester, size: iphone, insets: iphoneInsets);

    expect(
      find.byKey(const ValueKey<String>('avelune-home-header')),
      findsOneWidget,
    );
    expect(find.text('AVELUNE'), findsWidgets);

    final logo = tester.widget<Image>(
      find.byKey(const ValueKey<String>('avelune-home-header-mark')),
    );
    expect(
      (logo.image as AssetImage).assetName,
      AveluneMaterialCatalog.logo.path,
      reason: 'The header must use the production logo mark, not the iOS app '
          'icon the legacy home reached for.',
    );
  });

  testWidgets('header sits inside the reserved header band', (tester) async {
    await _pumpHome(tester, size: iphone, insets: iphoneInsets);

    final scene = tester.widget<AveluneRoomScene>(
      find.byType(AveluneRoomScene),
    );
    final headerRect = tester.getRect(
      find.byKey(const ValueKey<String>('avelune-home-header')),
    );

    expect(headerRect.top, greaterThanOrEqualTo(scene.geometry.headerRect.top));
    expect(
      headerRect.bottom,
      lessThanOrEqualTo(scene.geometry.headerRect.bottom + 0.5),
      reason: 'The geometry already reserves a header band; the header must '
          'live in it rather than float over the room.',
    );
  });

  testWidgets('hero details panel projects the selected game metadata',
      (tester) async {
    await _pumpHome(tester, size: iphone, insets: iphoneInsets);

    expect(
      find.byKey(const ValueKey<String>('avelune-hero-details-panel')),
      findsOneWidget,
    );
    expect(find.text('Selbrume'), findsWidgets);
    expect(find.textContaining('Dernière partie'), findsOneWidget);
  });

  testWidgets('editorial game title sits above the floating cartridge',
      (tester) async {
    await _pumpHome(tester, size: iphone, insets: iphoneInsets);

    final details = tester.getRect(
      find.byKey(const ValueKey<String>('avelune-hero-details-panel')),
    );
    final hero = tester.getRect(
      find.byKey(const ValueKey<String>('avelune-room-hero-cartridge')),
    );

    expect(details.left, lessThan(hero.left));
    expect(details.bottom, lessThanOrEqualTo(hero.top));
  });

  testWidgets('editorial metadata settles close to the hero cartridge',
      (tester) async {
    await _pumpHome(tester, size: iphone, insets: iphoneInsets);

    final session = tester.getRect(find.textContaining('Dernière partie'));
    final hero = tester.getRect(
      find.byKey(const ValueKey<String>('avelune-room-hero-cartridge')),
    );

    expect(
      hero.top - session.bottom,
      inInclusiveRange(8, 24),
      reason: 'The approved composition anchors the metadata immediately '
          'above the physical cartridge instead of floating it mid-window.',
    );
  });

  testWidgets('long editorial titles remain complete inside the hero panel',
      (tester) async {
    const longTitle = 'Pokémon SDK — Galactic Horizons';
    await _pumpHome(
      tester,
      size: iphone,
      insets: iphoneInsets,
      title: longTitle,
    );

    final fitFinder = find.byKey(
      const ValueKey<String>('avelune-hero-title-fit'),
    );
    final titleFinder = find.descendant(
      of: fitFinder,
      matching: find.text(longTitle),
    );
    final fit = tester.widget<FittedBox>(fitFinder);

    expect(titleFinder, findsOneWidget);
    expect(fit.fit, BoxFit.scaleDown);
    expect(fit.alignment, Alignment.centerLeft);
    expect(
      tester.getRect(titleFinder).width,
      lessThanOrEqualTo(tester.getRect(fitFinder).width + 0.5),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hero details panel invents no last session without a save',
      (tester) async {
    await _pumpHome(
      tester,
      size: iphone,
      insets: iphoneInsets,
      withSave: false,
    );

    expect(
      find.byKey(const ValueKey<String>('avelune-hero-details-panel')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Dernière partie'),
      findsNothing,
      reason: 'No save means no last-session row. Fabricated dates are barred.',
    );
  });

  testWidgets('details affordance reports the intent once', (tester) async {
    var requested = 0;
    await _pumpHome(
      tester,
      size: iphone,
      insets: iphoneInsets,
      onShowDetails: (_) => requested++,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-hero-details-button')),
    );
    await tester.pump();

    expect(
      requested,
      1,
      reason: 'The prototype exposes a visible details control instead of '
          'hiding it behind a long press only.',
    );
  });

  testWidgets('insertion hint invites the gesture when the hero can launch',
      (tester) async {
    await _pumpHome(tester, size: iphone, insets: iphoneInsets);

    final hint =
        find.byKey(const ValueKey<String>('avelune-library-play-hint'));
    expect(hint, findsOneWidget);
    expect(
      find.descendant(of: hint, matching: find.textContaining('Touchez')),
      findsOneWidget,
    );
  });

  testWidgets('insertion hint stays away when nothing can launch',
      (tester) async {
    await _pumpHome(
      tester,
      size: iphone,
      insets: iphoneInsets,
      launchable: false,
    );

    expect(
      find.byKey(const ValueKey<String>('avelune-insertion-hint')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('avelune-library-play-hint')),
      findsNothing,
    );
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required Size size,
  required EdgeInsets insets,
  bool withSave = true,
  bool launchable = true,
  String title = 'Selbrume',
  ValueChanged<AveluneGameViewData>? onShowDetails,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final viewData = _viewData(withSave: withSave, title: title);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: applyAveluneTheme(PokeMapPlayerTheme.dark(reducedMotion: true)),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: insets,
            viewPadding: insets,
            disableAnimations: true,
          ),
          child: AveluneHomeScreen(
            viewData: viewData,
            appearance: const AveluneAppearancePreferences(),
            onShowDetails: onShowDetails,
            onContinue: launchable ? (_) {} : null,
            onNewGame: launchable ? (_) {} : null,
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

AveluneHomeViewData _viewData({
  required bool withSave,
  String title = 'Selbrume',
}) {
  final game = AveluneGameViewData(
    id: 'selbrume',
    title: title,
    subtitle: 'Les Brumes de Selbrume',
    authorName: 'Studio Avelune',
    artwork: const AveluneArtworkViewData(kind: AveluneArtworkKind.fallback),
    shellColor: const Color(0xFF64358A),
    validity: AveluneGameValidity.available,
    primaryAction: withSave
        ? AvelunePrimaryAction.continueGame
        : AvelunePrimaryAction.play,
    isSelected: true,
    lastSaveAt:
        withSave ? DateTime.now().subtract(const Duration(hours: 2)) : null,
    playTimeSeconds: withSave ? 3720 : 0,
  );
  return AveluneHomeViewData(
    status: AveluneHomeStatus.ready,
    games: <AveluneGameViewData>[game],
    selectedGameId: game.id,
    recentActivity: const <AveluneRecentActivityViewData>[],
    import: const AveluneImportViewData.idle(canStart: true),
    safeErrorMessage: null,
    reducedMotion: true,
  );
}
