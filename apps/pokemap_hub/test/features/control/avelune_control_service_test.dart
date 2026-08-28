import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  test('projects Hub state and launches an installed healthy game', () async {
    var dashboard = _dashboard();
    final session = HubSessionController(refreshHub: () async {});
    final service = AveluneControlService(
      readDashboard: () => dashboard,
      sessionController: session,
      installPackage: (_) async {},
    )..observeDashboard(dashboard);

    final initial = service.state();
    expect(initial.surface, AveluneControlSurface.hub);
    expect(initial.dashboardStatus, 'ready');
    expect(initial.activeGameId, isNull);
    expect(initial.games.single.gameId, 'game.controlled');

    final launched = service.launch('game.controlled');
    expect(launched.surface, AveluneControlSurface.player);
    expect(launched.activeGameId, 'game.controlled');
    expect(session.activeGame?.game.gameId, 'game.controlled');

    final returned = await service.returnToHub();
    expect(returned.surface, AveluneControlSurface.hub);

    dashboard = _dashboard(status: HubDashboardStatus.error);
    expect(
      () => service.launch('game.controlled'),
      throwsA(
        isA<AveluneControlException>().having(
          (error) => error.code,
          'code',
          AveluneControlErrorCode.hubNotReady,
        ),
      ),
    );
  });

  test('observes complete install transitions without UI inference', () {
    var dashboard = _dashboard();
    final service = AveluneControlService(
      readDashboard: () => dashboard,
      sessionController: HubSessionController(refreshHub: () async {}),
      installPackage: (_) async {},
    )..observeDashboard(dashboard);

    dashboard = _dashboard(status: HubDashboardStatus.installing);
    service.observeDashboard(dashboard);
    expect(service.state().install.status, AveluneControlInstallStatus.running);
    expect(service.state().install.generation, 0);

    dashboard = _dashboard();
    service.observeDashboard(dashboard);
    expect(
      service.state().install.status,
      AveluneControlInstallStatus.succeeded,
    );
    expect(service.state().install.generation, 1);

    dashboard = _dashboard(status: HubDashboardStatus.installing);
    service.observeDashboard(dashboard);
    dashboard = _dashboard(
      status: HubDashboardStatus.error,
      safeErrorMessage: 'Package invalide',
    );
    service.observeDashboard(dashboard);
    final failed = service.state().install;
    expect(failed.status, AveluneControlInstallStatus.failed);
    expect(failed.generation, 2);
    expect(failed.message, 'Package invalide');
  });

  test('installs a staged package through the dashboard importer', () async {
    var dashboard = _dashboard();
    File? imported;
    late AveluneControlService service;
    service = AveluneControlService(
      readDashboard: () => dashboard,
      sessionController: HubSessionController(refreshHub: () async {}),
      installPackage: (package) async {
        imported = package;
        dashboard = _dashboard(status: HubDashboardStatus.installing);
        service.observeDashboard(dashboard);
        dashboard = _dashboard();
        service.observeDashboard(dashboard);
      },
    )..observeDashboard(dashboard);
    final package = File('${Directory.systemTemp.path}/controlled.avelunegame');

    final result = await service.install(package);

    expect(imported, same(package));
    expect(result.install.generation, 1);
    expect(result.install.status, AveluneControlInstallStatus.succeeded);
  });

  test('rejects unknown and unhealthy games with stable codes', () {
    final session = HubSessionController(refreshHub: () async {});
    var dashboard = _dashboard();
    final service = AveluneControlService(
      readDashboard: () => dashboard,
      sessionController: session,
      installPackage: (_) async {},
    )..observeDashboard(dashboard);

    expect(
      () => service.launch('missing'),
      throwsA(
        isA<AveluneControlException>().having(
          (error) => error.code,
          'code',
          AveluneControlErrorCode.gameNotFound,
        ),
      ),
    );

    dashboard = _dashboard(healthy: false);
    expect(
      () => service.launch('game.controlled'),
      throwsA(
        isA<AveluneControlException>().having(
          (error) => error.code,
          'code',
          AveluneControlErrorCode.gameUnavailable,
        ),
      ),
    );
  });

  test('serializes a compact protocol snapshot', () {
    final dashboard = _dashboard();
    final service = AveluneControlService(
      readDashboard: () => dashboard,
      sessionController: HubSessionController(refreshHub: () async {}),
      installPackage: (_) async {},
    )..observeDashboard(dashboard);

    expect(service.state().toJson(), <String, Object?>{
      'protocolVersion': 1,
      'dashboardStatus': 'ready',
      'surface': 'hub',
      'activeGameId': null,
      'install': <String, Object?>{
        'generation': 0,
        'status': 'idle',
        'message': null,
      },
      'games': <Map<String, Object?>>[
        <String, Object?>{
          'gameId': 'game.controlled',
          'title': 'Controlled',
          'gameVersion': '1.0.0',
          'canContinue': true,
          'installationHealthy': true,
        },
      ],
    });
  });
}

HubDashboardSnapshot _dashboard({
  HubDashboardStatus status = HubDashboardStatus.ready,
  bool healthy = true,
  String? safeErrorMessage,
}) {
  final version = InstalledGameVersion(
    gameVersion: Version.parse('1.0.0'),
    treeSha256: 'a' * 64,
    installedAt: DateTime.utc(2026, 8, 28),
    receiptFileName: 'receipt.json',
    source: GamePackageInstallSource.localFile,
    signatureStatus: PackageSignatureStatus.notPresent,
  );
  final game = InstalledGame(
    gameId: 'game.controlled',
    title: 'Controlled',
    description: '',
    authorName: 'PokeMap',
    defaultLocale: 'fr',
    supportedLocales: const <String>['fr'],
    current: version.pointer,
    versions: <InstalledGameVersion>[version],
  );
  return HubDashboardSnapshot(
    status: status,
    library: GameLibrary(
      revision: 1,
      updatedAt: DateTime.utc(2026, 8, 28),
      games: <InstalledGame>[game],
    ),
    games: <HubGameView>[
      HubGameView(
        game: game,
        activity: HubGameActivity(
          canContinue: true,
          installationHealthy: healthy,
        ),
      ),
    ],
    safeErrorMessage: safeErrorMessage,
  );
}
