import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  const mapper = AveluneHomeViewDataMapper();

  group('AveluneHomeViewDataMapper', () {
    test('projects empty, loading, import and safe error state', () {
      final snapshot = HubDashboardSnapshot(
        status: HubDashboardStatus.loading,
        library: GameLibrary.empty(),
        games: const <HubGameView>[],
        safeErrorMessage: 'La bibliothèque est momentanément indisponible.',
      );

      final result = mapper.map(
        snapshot: snapshot,
        canImport: true,
        canContinue: false,
        canPlay: false,
        reducedMotion: true,
      );

      expect(result.status, AveluneHomeStatus.loading);
      expect(result.games, isEmpty);
      expect(result.selectedGame, isNull);
      expect(result.recentActivity, isEmpty);
      expect(result.canImport, isTrue);
      expect(result.safeErrorMessage,
          'La bibliothèque est momentanément indisponible.');
      expect(result.reducedMotion, isTrue);
    });

    for (final count in <int>[1, 3, 10]) {
      test('projects exactly $count installed games without changing titles',
          () {
        final games = List<HubGameView>.generate(
          count,
          (index) => _game(
            index,
            title: index == count - 1
                ? 'Une aventure au nom excessivement long'
                : 'Aventure $index',
          ),
        );

        final result = mapper.map(
          snapshot: _snapshot(games),
          canImport: false,
          canContinue: true,
          canPlay: true,
          reducedMotion: false,
        );

        expect(result.games, hasLength(count));
        expect(
            result.games.last.title, 'Une aventure au nom excessivement long');
      });
    }

    test('uses cover, hero, icon then fallback without reading files', () {
      final games = <HubGameView>[
        _game(0, coverPath: '/covers/zero.webp', heroPath: '/hero/zero.webp'),
        _game(1, heroPath: '/hero/one.webp', iconPath: '/icons/one.webp'),
        _game(2, iconPath: '/icons/two.webp'),
        _game(3),
      ];

      final result = mapper.map(
        snapshot: _snapshot(games),
        canImport: false,
        canContinue: true,
        canPlay: true,
        reducedMotion: false,
      );

      expect(
        result.games.map((game) => game.artwork.kind),
        <AveluneArtworkKind>[
          AveluneArtworkKind.cover,
          AveluneArtworkKind.hero,
          AveluneArtworkKind.icon,
          AveluneArtworkKind.fallback,
        ],
      );
      expect(result.games[0].artwork.path, '/covers/zero.webp');
      expect(result.games[3].artwork.path, isNull);
    });

    test('selects latest saved game before valid Hub selection', () {
      final older = _game(
        0,
        canContinue: true,
        lastSaveAt: DateTime.utc(2026, 8, 3),
      );
      final hubSelected = _game(1);
      final latest = _game(
        2,
        canContinue: true,
        lastSaveAt: DateTime.utc(2026, 8, 4),
      );

      final result = mapper.map(
        snapshot: _snapshot(
          <HubGameView>[older, hubSelected, latest],
          selectedGameId: hubSelected.game.gameId,
        ),
        canImport: true,
        canContinue: true,
        canPlay: true,
        reducedMotion: false,
      );

      expect(result.selectedGameId, latest.game.gameId);
      expect(
        result.recentActivity.map((activity) => activity.gameId),
        <String>[latest.game.gameId, older.game.gameId],
      );
    });

    test('falls back to valid Hub selection, then first game', () {
      final first = _game(0);
      final validHubSelection = _game(1);
      final invalidHubSelection = _game(2, installationHealthy: false);

      final selected = mapper.map(
        snapshot: _snapshot(
          <HubGameView>[first, validHubSelection],
          selectedGameId: validHubSelection.game.gameId,
        ),
        canImport: true,
        canContinue: true,
        canPlay: true,
        reducedMotion: false,
      );
      final fallback = mapper.map(
        snapshot: _snapshot(
          <HubGameView>[first, invalidHubSelection],
          selectedGameId: invalidHubSelection.game.gameId,
        ),
        canImport: true,
        canContinue: true,
        canPlay: true,
        reducedMotion: false,
      );

      expect(selected.selectedGameId, validHubSelection.game.gameId);
      expect(fallback.selectedGameId, first.game.gameId);
    });

    test('maps continue, play, invalid and unavailable launch actions', () {
      final continueGame = _game(
        0,
        canContinue: true,
        lastSaveAt: DateTime.utc(2026, 8, 4),
      );
      final newGame = _game(1);
      final invalid = _game(2, installationHealthy: false);

      final available = mapper.map(
        snapshot: _snapshot(<HubGameView>[continueGame, newGame, invalid]),
        canImport: true,
        canContinue: true,
        canPlay: true,
        reducedMotion: false,
      );
      final unavailable = mapper.map(
        snapshot: _snapshot(<HubGameView>[continueGame, newGame]),
        canImport: true,
        canContinue: false,
        canPlay: false,
        reducedMotion: false,
      );

      expect(
          available.games[0].primaryAction, AvelunePrimaryAction.continueGame);
      expect(available.games[1].primaryAction, AvelunePrimaryAction.play);
      expect(available.games[2].primaryAction, AvelunePrimaryAction.disabled);
      expect(available.games[2].validity, AveluneGameValidity.invalid);
      expect(unavailable.games.map((game) => game.primaryAction),
          everyElement(AvelunePrimaryAction.disabled));
    });

    test('decodes author shell color and uses neutral fallback', () {
      final result = mapper.map(
        snapshot: _snapshot(<HubGameView>[
          _game(0, accentColor: '#126E78'),
          _game(1, accentColor: 'not-a-color'),
        ]),
        canImport: true,
        canContinue: true,
        canPlay: true,
        reducedMotion: false,
      );

      expect(result.games[0].shellColor, const Color(0xFF126E78));
      expect(result.games[1].shellColor, AveluneColors.standard.shellNeutral);
    });
  });

  group('AveluneHomeController', () {
    test('keeps mapped data stable when snapshot and selection do not change',
        () {
      final snapshot = _snapshot(<HubGameView>[_game(0), _game(1)]);
      final controller = AveluneHomeController(
        snapshot: snapshot,
        actions: const HubUiActions(),
      );
      addTearDown(controller.dispose);
      final initial = controller.viewData;
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.updateSnapshot(snapshot);
      controller.selectGame(initial.selectedGameId!);

      expect(controller.viewData, same(initial));
      expect(notifications, 0);
    });

    test('selection updates data and actions use the real Hub callbacks', () {
      final first = _game(0);
      final second = _game(
        1,
        canContinue: true,
        lastSaveAt: DateTime.utc(2026, 8, 4),
      );
      final events = <String>[];
      final controller = AveluneHomeController(
        snapshot: _snapshot(<HubGameView>[first, second]),
        actions: HubUiActions(
          onImportRequested: () => events.add('import'),
          onContinue: (game) => events.add('continue:${game.game.gameId}'),
          onNewGame: (game) => events.add('play:${game.game.gameId}'),
        ),
      );
      addTearDown(controller.dispose);

      expect(controller.selectGame(first.game.gameId), isTrue);
      expect(controller.viewData.selectedGameId, first.game.gameId);
      expect(controller.activatePrimaryAction(), isTrue);
      expect(controller.requestImport(), isTrue);
      expect(controller.selectGame(second.game.gameId), isTrue);
      expect(controller.activateRecentActivity(second.game.gameId), isTrue);

      expect(events, <String>[
        'play:${first.game.gameId}',
        'import',
        'continue:${second.game.gameId}',
      ]);
    });

    test('invalid games never invoke a launch callback', () {
      var launches = 0;
      final invalid = _game(0, installationHealthy: false);
      final controller = AveluneHomeController(
        snapshot: _snapshot(<HubGameView>[invalid]),
        actions: HubUiActions(onNewGame: (_) => launches++),
      );
      addTearDown(controller.dispose);

      expect(controller.activatePrimaryAction(), isFalse);
      expect(launches, 0);
    });
  });
}

HubDashboardSnapshot _snapshot(
  List<HubGameView> games, {
  String? selectedGameId,
}) =>
    HubDashboardSnapshot.ready(
      library: GameLibrary(
        revision: 1,
        updatedAt: DateTime.utc(2026, 8, 5),
        games: games.map((view) => view.game).toList(growable: false),
      ),
      games: games,
      selectedGameId: selectedGameId,
      preferences: const PlayerPreferences(),
    );

HubGameView _game(
  int index, {
  String? title,
  String? accentColor,
  bool canContinue = false,
  DateTime? lastSaveAt,
  bool installationHealthy = true,
  String? coverPath,
  String? heroPath,
  String? iconPath,
}) {
  final gameId = 'games.example.$index';
  final version = InstalledGameVersion(
    gameVersion: Version.parse('1.0.0'),
    treeSha256: index.toString().padLeft(64, '0'),
    installedAt: DateTime.utc(2026, 8, 1 + index),
    receiptFileName: '$index.json',
    source: GamePackageInstallSource.localFile,
    signatureStatus: PackageSignatureStatus.notPresent,
  );
  return HubGameView(
    game: InstalledGame(
      gameId: gameId,
      title: title ?? 'Game $index',
      description: 'Description $index',
      authorName: 'Studio $index',
      defaultLocale: 'fr',
      supportedLocales: const <String>['fr'],
      branding: InstalledGameBranding(accentColor: accentColor),
      current: version.pointer,
      versions: <InstalledGameVersion>[version],
    ),
    activity: HubGameActivity(
      canContinue: canContinue,
      lastSaveAt: lastSaveAt,
      installationHealthy: installationHealthy,
      coverPath: coverPath,
      heroPath: heroPath,
      iconPath: iconPath,
    ),
  );
}
