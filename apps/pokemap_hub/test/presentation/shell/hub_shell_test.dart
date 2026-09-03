import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pub_semver/pub_semver.dart';

/// Shell behaviour that survives the desktop cutover.
///
/// The tests that used to live here exercised the second, desktop-only
/// interface — navigation rail, library grid, `HubGameDetailView` and the
/// preferences form. That interface is gone, so those tests went with it; the
/// console experience is covered by the Avelune suites and
/// `hub_desktop_parity_test.dart`. What remains here is the shell's own
/// responsibility: product identity, the diagnostics banner, and the install
/// modal.
void main() {
  testWidgets('the injected product identity replaces PokeMap branding',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final snapshot = HubDashboardSnapshot.ready(
      library: GameLibrary.empty(),
      games: const <HubGameView>[],
    );
    await tester.pumpWidget(_app(_shell(snapshot, productName: 'Avelune')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey<String>('avelune-home-header-wordmark')),
      findsOneWidget,
    );
    expect(find.text('PokeMap Hub'), findsNothing);
    expect(
      find.textContaining(RegExp('poke', caseSensitive: false)),
      findsNothing,
    );
  });

  testWidgets('installation errors stay visible without hiding the room',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final game = _view();
    final snapshot = HubDashboardSnapshot(
      status: HubDashboardStatus.error,
      library: GameLibrary(
        revision: 1,
        updatedAt: DateTime.utc(2026, 7, 25),
        games: <InstalledGame>[game.game],
      ),
      games: <HubGameView>[game],
      diagnostics: const <HubDiagnostic>[
        HubDiagnostic(
          code: 'install.incompatible',
          severity: HubDiagnosticSeverity.error,
          message: 'Ce jeu est incompatible.',
          recommendation: 'Le jeu installé précédemment reste disponible.',
        ),
      ],
    );

    await tester.pumpWidget(_app(_shell(snapshot)));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Ce jeu est incompatible.'), findsOneWidget);
    expect(
      find.byType(AveluneRoomScene),
      findsOneWidget,
      reason: 'An install error must not replace the library the player still '
          'has.',
    );
  });

  testWidgets('picker failures keep the library usable and expose diagnostics',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const diagnostic = HubDiagnostic(
      code: 'importPicker.missingEntitlement',
      severity: HubDiagnosticSeverity.error,
      message: 'Le sélecteur de fichiers ne peut pas s’ouvrir.',
      recommendation: 'Fermez complètement le Hub puis relancez-le.',
      technicalDetails: 'Autorisation macOS manquante.',
      logPath: '/tmp/hub-import.log',
    );
    final snapshot = HubDashboardSnapshot(
      status: HubDashboardStatus.error,
      library: GameLibrary.empty(),
      games: const <HubGameView>[],
      diagnostics: const <HubDiagnostic>[diagnostic],
    );

    await tester.pumpWidget(_app(_shell(snapshot)));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('Le sélecteur de fichiers ne peut pas s’ouvrir.'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _app(_shell(snapshot.copyWith(section: HubSection.diagnostics))),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Autorisation macOS manquante.'), findsOneWidget);
    expect(find.text('Journal : /tmp/hub-import.log'), findsOneWidget);
  });

  testWidgets('installation uses a modal progress screen with ETA and steps',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var cancellations = 0;

    await tester.pumpWidget(
      _app(
        HubShell(
          snapshot: HubDashboardSnapshot(
            status: HubDashboardStatus.installing,
            library: GameLibrary.empty(),
            games: const <HubGameView>[],
            installProgress: const GameInstallProgress(
              stage: GameInstallStage.extracting,
              completedFiles: 5,
              totalFiles: 10,
              completedBytes: 500,
              totalBytes: 1000,
              cancellable: true,
            ),
          ),
          actions: const HubUiActions(),
          onSectionSelected: (_) {},
          onCancelInstall: () => cancellations++,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 8));

    expect(
      find.byKey(const ValueKey<String>('hub-install-progress-screen')),
      findsOneWidget,
    );
    expect(find.text('45 %'), findsOneWidget);
    expect(find.textContaining('Temps restant estimé'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('hub-install-step-package-completed')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('hub-install-step-extraction-active')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Annuler'));
    expect(cancellations, 1);
  });
}

HubShell _shell(
  HubDashboardSnapshot snapshot, {
  String productName = 'PokeMap Hub',
}) {
  const actions = HubUiActions();
  return HubShell(
    productName: productName,
    snapshot: snapshot,
    actions: actions,
    referenceTime: DateTime.utc(2026, 8, 4, 12),
    homeController: AveluneHomeController(
      snapshot: snapshot,
      actions: actions,
    ),
    onSectionSelected: (_) {},
  );
}

HubGameView _view({bool canContinue = false}) {
  final version = InstalledGameVersion(
    gameVersion: Version.parse('1.2.0'),
    treeSha256: 'b' * 64,
    installedAt: DateTime.utc(2026, 7, 25),
    receiptFileName: '1.2.0-${'b' * 64}.json',
    source: GamePackageInstallSource.localFile,
    signatureStatus: PackageSignatureStatus.notPresent,
  );
  final game = InstalledGame(
    gameId: 'games.example.aube',
    title: 'Aube',
    description: 'Une aventure générique.',
    authorName: 'Studio Brume',
    defaultLocale: 'fr',
    supportedLocales: <String>['fr', 'en'],
    current: version.pointer,
    versions: <InstalledGameVersion>[version],
  );
  return HubGameView(
    game: game,
    activity: HubGameActivity(
      canContinue: canContinue,
      lastSaveAt: canContinue ? DateTime.utc(2026, 7, 25) : null,
      playTimeSeconds: canContinue ? 3720 : 0,
    ),
  );
}

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      // The shell is Avelune-only now, so the Avelune theme extension is a
      // hard requirement rather than a mobile-only decoration.
      theme: applyAveluneTheme(PokeMapPlayerTheme.dark()),
      home: child,
    );
