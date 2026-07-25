import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../support/game_package_fixture.dart';

void main() {
  group('GameMaintenanceService', () {
    late Directory root;
    late Directory supportRoot;
    late Directory packages;
    late GamePackageInstaller installer;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('hub-maintenance-test-');
      supportRoot = Directory(p.join(root.path, 'PokeMap'));
      packages = Directory(p.join(root.path, 'packages'));
      installer = _installer(supportRoot);
    });

    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    test('detects corruption and repairs from the exact package', () async {
      final package = await writeTestPackage(packages);
      final installed = await installer.install(
        package,
        source: GamePackageInstallSource.localFile,
      );
      final projectFile = File(
        p.join(
          supportRoot.path,
          'games',
          installed.game.gameId,
          'versions',
          '1.0.0',
          'project',
          'project.json',
        ),
      );
      await projectFile.writeAsString('tampered', flush: true);
      final save = await _writeSaveSentinel(supportRoot);
      final verifier = const InstalledGameVerifier();
      expect(
        (await verifier.verify(
          supportRoot: supportRoot,
          gameId: installed.game.gameId,
          pointer: installed.game.current,
          receiptFileName: installed.game.currentVersion.receiptFileName,
        ))
            .code,
        InstalledGameVerificationCode.sizeMismatch,
      );

      final repaired = await GameMaintenanceService(
        supportRoot: supportRoot,
        installer: installer,
      ).repair(
        package,
        source: GamePackageInstallSource.localFile,
      );

      expect(repaired.game.current.gameVersion.toString(), '1.0.0');
      expect(
        (await verifier.verify(
          supportRoot: supportRoot,
          gameId: repaired.game.gameId,
          pointer: repaired.game.current,
          receiptFileName: repaired.game.currentVersion.receiptFileName,
        ))
            .code,
        InstalledGameVerificationCode.healthy,
      );
      expect(await save.readAsString(), 'keep-save');
    });

    test('rejects repair from a different version', () async {
      final installedPackage =
          await writeTestPackage(packages, gameVersion: '1.0.0');
      final wrongPackage =
          await writeTestPackage(packages, gameVersion: '1.1.0');
      await installer.install(
        installedPackage,
        source: GamePackageInstallSource.localFile,
      );

      await expectLater(
        GameMaintenanceService(
          supportRoot: supportRoot,
          installer: installer,
        ).repair(
          wrongPackage,
          source: GamePackageInstallSource.localFile,
        ),
        throwsA(
          isA<GameInstallationException>().having(
            (error) => error.diagnostic.code,
            'code',
            GameInstallationErrorCode.repairIdentityMismatch,
          ),
        ),
      );
    });

    test('rolls back only after confirmation and save restoration', () async {
      final version1 = await writeTestPackage(packages, gameVersion: '1.0.0');
      final version2 = await writeTestPackage(packages, gameVersion: '2.0.0');
      await installer.install(
        version1,
        source: GamePackageInstallSource.localFile,
      );
      await installer.install(
        version2,
        source: GamePackageInstallSource.localFile,
        mode: GamePackageActivationMode.update,
      );
      var restored = false;
      final maintenance = GameMaintenanceService(
        supportRoot: supportRoot,
        installer: installer,
        restoreSavesForRollback: (gameId, target) async {
          expect(gameId, 'games.example.adventure');
          expect(target.gameVersion.toString(), '1.0.0');
          restored = true;
        },
      );

      await expectLater(
        maintenance.rollback(
          gameId: 'games.example.adventure',
          targetVersion: Version.parse('1.0.0'),
          confirmed: false,
          compatibleSaveSnapshotAvailable: true,
        ),
        throwsA(
          isA<GameInstallationException>().having(
            (error) => error.diagnostic.code,
            'code',
            GameInstallationErrorCode.rollbackConfirmationRequired,
          ),
        ),
      );
      await expectLater(
        maintenance.rollback(
          gameId: 'games.example.adventure',
          targetVersion: Version.parse('1.0.0'),
          confirmed: true,
          compatibleSaveSnapshotAvailable: false,
        ),
        throwsA(
          isA<GameInstallationException>().having(
            (error) => error.diagnostic.code,
            'code',
            GameInstallationErrorCode.rollbackSnapshotUnavailable,
          ),
        ),
      );

      final game = await maintenance.rollback(
        gameId: 'games.example.adventure',
        targetVersion: Version.parse('1.0.0'),
        confirmed: true,
        compatibleSaveSnapshotAvailable: true,
      );

      expect(restored, isTrue);
      expect(game.current.gameVersion.toString(), '1.0.0');
      expect(
        (await installer.readCurrent(game.gameId)).gameVersion.toString(),
        '1.0.0',
      );
    });

    test('uninstalls current version only with an explicit healthy fallback',
        () async {
      final version1 = await writeTestPackage(packages, gameVersion: '1.0.0');
      final version2 = await writeTestPackage(packages, gameVersion: '2.0.0');
      await installer.install(
        version1,
        source: GamePackageInstallSource.localFile,
      );
      await installer.install(
        version2,
        source: GamePackageInstallSource.localFile,
        mode: GamePackageActivationMode.update,
      );
      final maintenance = GameMaintenanceService(
        supportRoot: supportRoot,
        installer: installer,
      );

      await expectLater(
        maintenance.uninstallVersion(
          gameId: 'games.example.adventure',
          gameVersion: Version.parse('2.0.0'),
        ),
        throwsA(
          isA<GameInstallationException>().having(
            (error) => error.diagnostic.code,
            'code',
            GameInstallationErrorCode.uninstallFallbackRequired,
          ),
        ),
      );
      final game = await maintenance.uninstallVersion(
        gameId: 'games.example.adventure',
        gameVersion: Version.parse('2.0.0'),
        fallbackVersion: Version.parse('1.0.0'),
      );

      expect(game, isNotNull);
      expect(game!.current.gameVersion.toString(), '1.0.0');
      expect(game.versions.map((version) => version.gameVersion.toString()),
          <String>['1.0.0']);
    });

    test('uninstalls a game while preserving its saves byte-for-byte',
        () async {
      final package = await writeTestPackage(packages);
      await installer.install(
        package,
        source: GamePackageInstallSource.localFile,
      );
      final save = await _writeSaveSentinel(supportRoot);

      await GameMaintenanceService(
        supportRoot: supportRoot,
        installer: installer,
      ).uninstallGame('games.example.adventure');

      expect(
        await Directory(
          p.join(
            supportRoot.path,
            'games',
            'games.example.adventure',
          ),
        ).exists(),
        isFalse,
      );
      expect(await save.readAsString(), 'keep-save');
      expect(
        (await GameLibraryStore(supportRoot: supportRoot).load()).library.games,
        isEmpty,
      );
    });
  });
}

GamePackageInstaller _installer(Directory supportRoot) => GamePackageInstaller(
      supportRoot: supportRoot,
      inspector: GamePackageInspector(
        hostCompatibility: testHostCompatibility(),
      ),
      availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
      loadSmoke: (_, __) async {},
      prepareSavesForUpdate: (_, __) async => const SaveUpdatePreparation(
        rollbackSnapshotAvailable: true,
      ),
      now: () => DateTime.utc(2026, 7, 25, 12),
    );

Future<File> _writeSaveSentinel(Directory supportRoot) async {
  final save = File(
    p.join(
      supportRoot.path,
      'saves',
      'games.example.adventure',
      'profile-a',
      'slot-a',
      'sentinel.txt',
    ),
  );
  await save.parent.create(recursive: true);
  await save.writeAsString('keep-save', flush: true);
  return save;
}
