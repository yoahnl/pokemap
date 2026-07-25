import 'dart:async';
import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:test/test.dart';

import '../support/game_package_fixture.dart';

void main() {
  group('GamePackageInstaller', () {
    late Directory root;
    late Directory packages;
    late List<GameInstallProgress> progress;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('hub-installer-test-');
      packages = Directory(p.join(root.path, 'selected'));
      progress = <GameInstallProgress>[];
    });

    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    GamePackageInstaller installer({
      GamePackageLoadSmoke? smoke,
      PrepareGameSavesForUpdate? prepareSaves,
      Future<int> Function(Directory root)? disk,
      Duration? smokeTimeout,
    }) =>
        GamePackageInstaller(
          supportRoot: Directory(p.join(root.path, 'PokeMap')),
          inspector: GamePackageInspector(
            hostCompatibility: testHostCompatibility(),
          ),
          availableDiskBytes: disk ?? (_) async => 2 * 1024 * 1024 * 1024,
          loadSmoke: smoke ?? (_, __) async {},
          prepareSavesForUpdate:
              prepareSaves ?? (_, __) async => const SaveUpdatePreparation(),
          loadSmokeTimeout: smokeTimeout ?? const Duration(seconds: 30),
          now: () => DateTime.utc(2026, 7, 25, 12),
        );

    test('installs a real package and publishes receipt/current/library',
        () async {
      final package = await writeTestPackage(packages);
      final service = installer();

      final result = await service.install(
        package,
        source: GamePackageInstallSource.localFile,
        onProgress: progress.add,
      );

      expect(result.alreadyInstalled, isFalse);
      expect(result.game.gameId, 'games.example.adventure');
      expect(result.game.current.gameVersion.toString(), '1.0.0');
      final gameRoot = p.join(
        root.path,
        'PokeMap',
        'games',
        'games.example.adventure',
      );
      expect(
        await File(
          p.join(gameRoot, 'versions', '1.0.0', 'project', 'project.json'),
        ).exists(),
        isTrue,
      );
      expect(await File(p.join(gameRoot, 'current.json')).exists(), isTrue);
      expect(
        await File(
          p.join(
            gameRoot,
            'install-receipts',
            result.game.currentVersion.receiptFileName,
          ),
        ).exists(),
        isTrue,
      );
      final library = await GameLibraryStore(
        supportRoot: Directory(p.join(root.path, 'PokeMap')),
      ).load();
      expect(library.library.games.single.gameId, result.game.gameId);
      expect(
        progress.map((event) => event.stage),
        containsAllInOrder(<GameInstallStage>[
          GameInstallStage.inspecting,
          GameInstallStage.checkingStorage,
          GameInstallStage.snapshotting,
          GameInstallStage.extracting,
          GameInstallStage.verifying,
          GameInstallStage.smokeLoading,
          GameInstallStage.promoting,
          GameInstallStage.updatingLibrary,
          GameInstallStage.completed,
        ]),
      );
      final extraction = progress
          .where((event) => event.stage == GameInstallStage.extracting)
          .toList();
      expect(
        extraction.map((event) => event.completedBytes),
        orderedEquals(
          extraction.map((event) => event.completedBytes).toList()..sort(),
        ),
      );
    });

    test('keeps same-title games separate by stable gameId', () async {
      final first = await writeTestPackage(
        packages,
        gameId: 'games.example.first',
        title: 'Same title',
      );
      final second = await writeTestPackage(
        packages,
        gameId: 'games.example.second',
        title: 'Same title',
      );
      final service = installer();

      await service.install(
        first,
        source: GamePackageInstallSource.localFile,
      );
      await service.install(
        second,
        source: GamePackageInstallSource.localFile,
      );

      final library = await GameLibraryStore(
        supportRoot: Directory(p.join(root.path, 'PokeMap')),
      ).load();
      expect(
        library.library.games.map((game) => game.gameId),
        <String>['games.example.first', 'games.example.second'],
      );
    });

    test('rejects insufficient disk before creating a transaction', () async {
      final package = await writeTestPackage(packages);

      await expectLater(
        installer(disk: (_) async => 1).install(
          package,
          source: GamePackageInstallSource.localFile,
        ),
        throwsA(
          isA<GameInstallationException>().having(
            (error) => error.diagnostic.code,
            'code',
            GameInstallationErrorCode.insufficientDisk,
          ),
        ),
      );
      expect(
        await Directory(
          p.join(root.path, 'PokeMap', 'games', '.transactions'),
        ).exists(),
        isFalse,
      );
    });

    test('cancels during extraction without publishing a version', () async {
      final package = await writeTestPackage(packages, extraFiles: 4);
      final cancellation = GameInstallCancellationToken();
      final cancellationProgress = <GameInstallProgress>[];

      await expectLater(
        installer().install(
          package,
          source: GamePackageInstallSource.localFile,
          cancellationToken: cancellation,
          onProgress: (event) {
            cancellationProgress.add(event);
            if (event.stage == GameInstallStage.extracting &&
                event.completedFiles == 1) {
              cancellation.cancel();
            }
          },
        ),
        throwsA(
          isA<GameInstallationException>().having(
            (error) => error.diagnostic.code,
            'code',
            GameInstallationErrorCode.cancelled,
          ),
        ),
      );
      expect(
        await Directory(
          p.join(
            root.path,
            'PokeMap',
            'games',
            'games.example.adventure',
            'versions',
          ),
        ).exists(),
        isFalse,
      );
      expect(cancellationProgress.last.stage, GameInstallStage.cancelled);
      expect(cancellationProgress.last.cancellable, isFalse);
    });

    test('keeps current and library untouched when smoke fails', () async {
      final version1 = await writeTestPackage(
        packages,
        gameVersion: '1.0.0',
      );
      final version2 = await writeTestPackage(
        packages,
        gameVersion: '2.0.0',
      );
      final service = installer();
      await service.install(
        version1,
        source: GamePackageInstallSource.localFile,
      );

      final failing = installer(
        smoke: (_, manifest) async {
          if (manifest.gameVersion.toString() == '2.0.0') {
            throw StateError('smoke failed');
          }
        },
      );
      await expectLater(
        failing.install(
          version2,
          source: GamePackageInstallSource.localFile,
          mode: GamePackageActivationMode.update,
        ),
        throwsA(
          isA<GameInstallationException>().having(
            (error) => error.diagnostic.code,
            'code',
            GameInstallationErrorCode.smokeFailed,
          ),
        ),
      );

      final current = await service.readCurrent('games.example.adventure');
      expect(current.gameVersion.toString(), '1.0.0');
      final library = await GameLibraryStore(
        supportRoot: Directory(p.join(root.path, 'PokeMap')),
      ).load();
      expect(
        library.library.games.single.current.gameVersion.toString(),
        '1.0.0',
      );
    });

    test('times out an opaque load smoke without publishing a version',
        () async {
      final package = await writeTestPackage(packages);

      await expectLater(
        installer(
          smoke: (_, __) => Completer<void>().future,
          smokeTimeout: const Duration(milliseconds: 10),
        ).install(
          package,
          source: GamePackageInstallSource.localFile,
        ),
        throwsA(
          isA<GameInstallationException>().having(
            (error) => error.diagnostic.code,
            'code',
            GameInstallationErrorCode.smokeFailed,
          ),
        ),
      );

      expect(
        await Directory(
          p.join(
            root.path,
            'PokeMap',
            'games',
            'games.example.adventure',
            'versions',
          ),
        ).exists(),
        isFalse,
      );
    });

    test('installs an update side by side after save preparation', () async {
      final version1 = await writeTestPackage(packages, gameVersion: '1.0.0');
      final version2 = await writeTestPackage(packages, gameVersion: '1.1.0');
      var prepared = false;
      final service = installer(
        prepareSaves: (current, candidate) async {
          expect(current.gameVersion.toString(), '1.0.0');
          expect(candidate.gameVersion.toString(), '1.1.0');
          prepared = true;
          return const SaveUpdatePreparation(
            rollbackSnapshotAvailable: true,
          );
        },
      );
      await service.install(
        version1,
        source: GamePackageInstallSource.localFile,
      );

      final result = await service.install(
        version2,
        source: GamePackageInstallSource.localFile,
        mode: GamePackageActivationMode.update,
      );

      expect(prepared, isTrue);
      expect(result.game.current.gameVersion.toString(), '1.1.0');
      final versionsRoot = Directory(
        p.join(
          root.path,
          'PokeMap',
          'games',
          result.game.gameId,
          'versions',
        ),
      );
      expect(
        (await versionsRoot.list().toList())
            .whereType<Directory>()
            .map((entry) => p.basename(entry.path)),
        containsAll(<String>['1.0.0', '1.1.0']),
      );
    });

    test('treats reimporting an installed side version as idempotent',
        () async {
      final version1 = await writeTestPackage(packages, gameVersion: '1.0.0');
      final version2 = await writeTestPackage(packages, gameVersion: '2.0.0');
      final service = installer();
      await service.install(
        version1,
        source: GamePackageInstallSource.localFile,
      );
      await service.install(
        version2,
        source: GamePackageInstallSource.localFile,
        mode: GamePackageActivationMode.update,
      );

      final result = await service.install(
        version1,
        source: GamePackageInstallSource.localFile,
      );

      expect(result.alreadyInstalled, isTrue);
      expect(result.game.current.gameVersion.toString(), '2.0.0');
      expect(
        (await service.readCurrent(result.game.gameId)).gameVersion.toString(),
        '2.0.0',
      );
    });

    test('does not activate update when save preparation fails', () async {
      final version1 = await writeTestPackage(packages, gameVersion: '1.0.0');
      final version2 = await writeTestPackage(packages, gameVersion: '1.1.0');
      final service = installer(
        prepareSaves: (_, __) async => throw StateError('migration failed'),
      );
      await service.install(
        version1,
        source: GamePackageInstallSource.localFile,
      );

      await expectLater(
        service.install(
          version2,
          source: GamePackageInstallSource.localFile,
          mode: GamePackageActivationMode.update,
        ),
        throwsA(
          isA<GameInstallationException>().having(
            (error) => error.diagnostic.code,
            'code',
            GameInstallationErrorCode.savePreparationFailed,
          ),
        ),
      );
      expect(
        (await service.readCurrent('games.example.adventure'))
            .gameVersion
            .toString(),
        '1.0.0',
      );
    });

    test('rejects same game/version with a different tree', () async {
      final first = await writeTestPackage(
        packages,
        gameVersion: '1.0.0',
        projectName: 'First',
      );
      final conflicting = await writeTestPackage(
        packages,
        gameVersion: '1.0.0',
        projectName: 'Changed',
      );
      final service = installer();
      await service.install(
        first,
        source: GamePackageInstallSource.localFile,
      );

      await expectLater(
        service.install(
          conflicting,
          source: GamePackageInstallSource.localFile,
        ),
        throwsA(
          isA<GameInstallationException>().having(
            (error) => error.diagnostic.code,
            'code',
            GameInstallationErrorCode.releaseConflict,
          ),
        ),
      );
    });
  });
}
