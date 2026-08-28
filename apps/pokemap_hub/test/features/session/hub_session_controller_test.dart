import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  test('opens a player session and returns to the refreshed Hub', () async {
    var refreshCount = 0;
    final controller = HubSessionController(
      refreshHub: () async {
        refreshCount += 1;
      },
    );
    final game = _gameView();
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    expect(controller.surface, HubSessionSurface.hub);
    expect(controller.activeGame, isNull);

    expect(controller.open(game), isTrue);
    expect(controller.surface, HubSessionSurface.player);
    expect(controller.activeGame, same(game));
    expect(controller.open(game), isFalse);

    expect(await controller.returnToHub(), isTrue);
    expect(controller.surface, HubSessionSurface.hub);
    expect(controller.activeGame, isNull);
    expect(refreshCount, 1);
    expect(notifications, 2);

    expect(await controller.returnToHub(), isFalse);
    expect(refreshCount, 1);
  });
}

HubGameView _gameView() {
  final version = InstalledGameVersion(
    gameVersion: Version.parse('1.0.0'),
    treeSha256: 'a' * 64,
    installedAt: DateTime.utc(2026, 8, 28),
    receiptFileName: 'receipt.json',
    source: GamePackageInstallSource.localFile,
    signatureStatus: PackageSignatureStatus.notPresent,
  );
  return HubGameView(
    game: InstalledGame(
      gameId: 'game.controlled',
      title: 'Controlled',
      description: '',
      authorName: 'PokeMap',
      defaultLocale: 'fr',
      supportedLocales: const <String>['fr'],
      current: version.pointer,
      versions: <InstalledGameVersion>[version],
    ),
    activity: const HubGameActivity(),
  );
}
