import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_state.dart';
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../dev/marionette_main.dart' as marionette;

void main() {
  test('QA context exposes installed version and save availability', () {
    final game = InstalledGame(
      gameId: 'games.local.train1742',
      title: 'Le Train de 17h42',
      authorName: 'PokeMap',
      defaultLocale: 'fr',
      supportedLocales: const <String>['fr'],
      current: InstalledGamePointer(
        gameVersion: Version(0, 1, 2),
        treeSha256: 'sha256:tree',
      ),
      versions: const <InstalledGameVersion>[],
    );
    final dashboard = HubDashboardSnapshot.ready(
      library: GameLibrary.empty(),
      games: <HubGameView>[
        HubGameView(
          game: game,
          activity: const HubGameActivity(canContinue: true),
        ),
      ],
      selectedGameId: game.gameId,
    );

    expect(
      marionette.hubQaContext(
        supportRoot: Directory('/qa/pokemap-hub'),
        dashboard: dashboard,
      ),
      <String, Object?>{
        'supportRoot': '/qa/pokemap-hub',
        'status': 'ready',
        'selectedGameId': 'games.local.train1742',
        'games': <Map<String, Object?>>[
          <String, Object?>{
            'gameId': 'games.local.train1742',
            'gameVersion': '0.1.2',
            'title': 'Le Train de 17h42',
            'canContinue': true,
          },
        ],
      },
    );
  });
}
