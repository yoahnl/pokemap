import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  testWidgets('empty home guides the player to package import', (tester) async {
    var imports = 0;
    await tester.pumpWidget(
      _app(
        HubShell(
          snapshot: HubDashboardSnapshot.ready(
            library: GameLibrary.empty(),
            games: const <HubGameView>[],
          ),
          actions: HubUiActions(
            onImportRequested: () => imports++,
          ),
          onSectionSelected: (_) {},
          onQueryChanged: (_) {},
          onGameSelected: (_) {},
          onGameDetailsClosed: () {},
          onPreferencesChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Votre bibliothèque vous attend'), findsOneWidget);
    expect(find.textContaining('.pokemapgame'), findsOneWidget);
    await tester.tap(find.text('Importer un jeu').first);
    expect(imports, 1);
    expect(find.textContaining('workspace'), findsNothing);
    expect(find.textContaining('seed'), findsNothing);
    expect(find.textContaining('FPS'), findsNothing);
  });

  testWidgets('wide library uses rail, grid, and opens a complete detail',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final game = _view(canContinue: true);
    var selected = '';
    await tester.pumpWidget(
      _app(
        HubShell(
          snapshot: HubDashboardSnapshot.ready(
            library: GameLibrary(
              revision: 1,
              updatedAt: DateTime.utc(2026, 7, 25),
              games: <InstalledGame>[game.game],
            ),
            games: <HubGameView>[game],
            section: HubSection.library,
          ),
          actions: const HubUiActions(),
          onSectionSelected: (_) {},
          onQueryChanged: (_) {},
          onGameSelected: (gameId) => selected = gameId,
          onGameDetailsClosed: () {},
          onPreferencesChanged: (_) {},
        ),
      ),
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('hub-library-grid')), findsOneWidget);
    await tester.tap(find.text('Aube'));
    expect(selected, 'games.example.aube');

    await tester.pumpWidget(
      _app(
        HubShell(
          snapshot: HubDashboardSnapshot.ready(
            library: GameLibrary(
              revision: 1,
              updatedAt: DateTime.utc(2026, 7, 25),
              games: <InstalledGame>[game.game],
            ),
            games: <HubGameView>[game],
            selectedGameId: game.game.gameId,
          ),
          actions: const HubUiActions(),
          onSectionSelected: (_) {},
          onQueryChanged: (_) {},
          onGameSelected: (_) {},
          onGameDetailsClosed: () {},
          onPreferencesChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Une aventure générique.'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
    expect(find.text('Nouvelle partie'), findsOneWidget);
    expect(find.text('Réparer'), findsOneWidget);
    expect(find.text('Mettre à jour'), findsOneWidget);
    expect(find.text('Gérer les sauvegardes'), findsOneWidget);
    expect(find.text('Désinstaller'), findsOneWidget);
  });

  testWidgets('compact portrait uses bottom navigation without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
        child: _app(
          HubShell(
            snapshot: HubDashboardSnapshot.ready(
              library: GameLibrary(
                revision: 1,
                updatedAt: DateTime.utc(2026, 7, 25),
                games: <InstalledGame>[_view().game],
              ),
              games: <HubGameView>[_view()],
            ),
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

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled Continue exposes a player-safe explanation',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final game = _view(canContinue: false);
    await tester.pumpWidget(
      _app(
        HubGameDetailView(
          game: game,
          actions: const HubUiActions(),
          onBack: () {},
        ),
      ),
    );

    final semantics = tester.getSemantics(
      find.byKey(
        const ValueKey<String>('player-action-semantics-Continuer'),
      ),
    );
    expect(semantics.hint, contains('Aucune sauvegarde'));
  });

  testWidgets('English locale translates Hub preferences', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        theme: PokeMapPlayerTheme.light(),
        home: HubShell(
          snapshot: HubDashboardSnapshot.ready(
            library: GameLibrary.empty(),
            games: const <HubGameView>[],
            section: HubSection.preferences,
          ),
          actions: const HubUiActions(),
          onSectionSelected: (_) {},
          onQueryChanged: (_) {},
          onGameSelected: (_) {},
          onGameDetailsClosed: () {},
          onPreferencesChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Preferences'), findsWidgets);
    expect(find.text('Global settings for the Hub and games.'), findsOneWidget);
    expect(find.text('System language'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Master volume'), findsOneWidget);
    expect(find.text('Réglages globaux du Hub et des jeux.'), findsNothing);
  });

  testWidgets('installation errors stay visible without hiding installed games',
      (tester) async {
    final game = _view();
    await tester.pumpWidget(
      _app(
        HubShell(
          snapshot: HubDashboardSnapshot(
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
                recommendation:
                    'Le jeu installé précédemment reste disponible.',
              ),
            ],
          ),
          actions: const HubUiActions(),
          onSectionSelected: (_) {},
          onQueryChanged: (_) {},
          onGameSelected: (_) {},
          onGameDetailsClosed: () {},
          onPreferencesChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Ce jeu est incompatible.'), findsOneWidget);
    expect(find.text('Aube'), findsOneWidget);
  });

  testWidgets(
      'picker failures keep the empty library usable and expose diagnostics',
      (tester) async {
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

    await tester.pumpWidget(
      _app(
        HubShell(
          snapshot: snapshot,
          actions: const HubUiActions(),
          onSectionSelected: (_) {},
          onQueryChanged: (_) {},
          onGameSelected: (_) {},
          onGameDetailsClosed: () {},
          onPreferencesChanged: (_) {},
        ),
      ),
    );

    expect(
      find.text('Le sélecteur de fichiers ne peut pas s’ouvrir.'),
      findsOneWidget,
    );
    expect(find.text('Importer un jeu'), findsWidgets);

    await tester.pumpWidget(
      _app(
        HubShell(
          snapshot: snapshot.copyWith(section: HubSection.diagnostics),
          actions: const HubUiActions(),
          onSectionSelected: (_) {},
          onQueryChanged: (_) {},
          onGameSelected: (_) {},
          onGameDetailsClosed: () {},
          onPreferencesChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Autorisation macOS manquante.'), findsOneWidget);
    expect(find.text('Journal : /tmp/hub-import.log'), findsOneWidget);
  });

  testWidgets(
      'installation uses a modal progress screen with percent ETA and steps',
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
          onQueryChanged: (_) {},
          onGameSelected: (_) {},
          onGameDetailsClosed: () {},
          onPreferencesChanged: (_) {},
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
      find.byKey(
        const ValueKey<String>('hub-install-step-package-completed'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('hub-install-step-extraction-active'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Annuler'));
    expect(cancellations, 1);
  });
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
      theme: PokeMapPlayerTheme.light(),
      home: child,
    );
