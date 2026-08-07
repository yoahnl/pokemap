import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:test/test.dart';

import '../../support/game_package_fixture.dart';

void main() {
  late Directory root;
  late Directory supportRoot;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('launch-resolver-');
    supportRoot = Directory(p.join(root.path, 'PokeMap'));
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  GamePackageInstaller installer() => GamePackageInstaller(
        supportRoot: supportRoot,
        inspector: GamePackageInspector(
          hostCompatibility: testHostCompatibility(),
        ),
        availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
        loadSmoke: (_, __) async {},
        prepareSavesForUpdate: (_, __) async => const SaveUpdatePreparation(),
        now: () => DateTime.utc(2026, 7, 25, 12),
      );

  test('resolves a healthy installed game into an opaque launch context',
      () async {
    final package = await writeTestPackage(
      Directory(p.join(root.path, 'pkg')),
      requiredCapabilities: const <String>['map@1'],
    );
    final service = installer();
    final installed = await service.install(
      package,
      source: GamePackageInstallSource.localFile,
    );

    final context = await InstalledGameLaunchResolver(
      supportRoot: supportRoot,
      hostCompatibility: testHostCompatibility(),
    ).resolve(installed.game);

    expect(context.identity.gameId, installed.game.gameId);
    expect(context.project.packagePath, 'project/project.json');
    expect(context.installedVersionHandle, isNot(contains(supportRoot.path)));
    expect(
        context.grantedCapabilities, containsAll(<String>['map@1', 'map.v1']));
    expect(
      await context.assets.resolveReference(context.project),
      isA<File>(),
    );
  });

  test('refuses a locally tampered current version', () async {
    final package = await writeTestPackage(Directory(p.join(root.path, 'pkg')));
    final installed = await installer().install(
      package,
      source: GamePackageInstallSource.localFile,
    );
    await File(
      p.join(
        supportRoot.path,
        'games',
        installed.game.gameId,
        'versions',
        '1.0.0',
        'project',
        'project.json',
      ),
    ).writeAsString('tampered');

    await expectLater(
      InstalledGameLaunchResolver(
        supportRoot: supportRoot,
        hostCompatibility: testHostCompatibility(),
      ).resolve(installed.game),
      throwsA(
        isA<InstalledGameLaunchException>().having(
          (error) => error.code,
          'code',
          InstalledGameLaunchErrorCode.installationUnhealthy,
        ),
      ),
    );
  });
}
