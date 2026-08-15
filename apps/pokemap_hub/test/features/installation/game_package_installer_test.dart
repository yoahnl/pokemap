import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:test/test.dart';

import '../../support/game_package_fixture.dart';

void main() {
  test(
    'preserves the filesystem cause when the selected package is unreadable',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'hub-unreadable-package-',
      );
      addTearDown(() => root.delete(recursive: true));
      final packageDirectory =
          await Directory('${root.path}/blocked.avelunegame').create();
      final installer = GamePackageInstaller(
        supportRoot: Directory('${root.path}/support'),
        inspector: GamePackageInspector(
          hostCompatibility: testHostCompatibility(),
        ),
        availableDiskBytes: (_) async => 1 << 40,
        loadSmoke: (_, _) async {},
        prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
      );

      await expectLater(
        installer.install(
          File(packageDirectory.path),
          source: GamePackageInstallSource.localFile,
        ),
        throwsA(
          isA<GameInstallationException>()
              .having(
                (error) => error.diagnostic.code,
                'code',
                GameInstallationErrorCode.integrityFailed,
              )
              .having(
                (error) => error.cause,
                'cause',
                isA<FileSystemException>(),
              ),
        ),
      );
    },
  );

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
    }) => GamePackageInstaller(
      supportRoot: Directory(p.join(root.path, 'PokeMap')),
      inspector: GamePackageInspector(
        hostCompatibility: testHostCompatibility(),
      ),
      availableDiskBytes: disk ?? (_) async => 2 * 1024 * 1024 * 1024,
      loadSmoke: smoke ?? (_, _) async {},
      prepareSavesForUpdate:
          prepareSaves ?? (_, _) async => const SaveUpdatePreparation(),
      loadSmokeTimeout: smokeTimeout ?? const Duration(seconds: 30),
      now: () => DateTime.utc(2026, 7, 25, 12),
    );

    test(
      'installs a real package and publishes receipt/current/library',
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
        final library =
            await GameLibraryStore(
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
        final extraction =
            progress
                .where((event) => event.stage == GameInstallStage.extracting)
                .toList();
        expect(
          extraction.map((event) => event.completedBytes),
          orderedEquals(
            extraction.map((event) => event.completedBytes).toList()..sort(),
          ),
        );
      },
    );

    test(
      'reinstalls a Presentation media closure offline with exact hashes',
      () async {
        final mediaBytes = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
          '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        );
        final mediaSha256 = sha256.convert(mediaBytes).toString();
        final mediaPath = 'project/assets/.pokemap-store/$mediaSha256.blob';
        final mediaCatalog = ProjectMediaCatalog(
          entries: <ProjectMediaAsset>[
            ProjectMediaAsset(
              id: 'opening.poster',
              label: 'Poster ouverture',
              kind: ProjectMediaKind.poster,
              sourceAssetId: 'asset.opening.poster',
              provenance: ProjectMediaProvenance(source: 'Avelune Studio'),
              license: ProjectMediaLicense(
                identifier: 'LicenseRef-Poster',
                name: 'Poster redistribution grant',
              ),
              technicalMetadata: ProjectMediaTechnicalMetadata(
                mediaType: 'image/png',
                container: 'png',
                codec: 'png',
                sizeBytes: mediaBytes.length,
                width: 1,
                height: 1,
              ),
            ),
          ],
        );
        final package = await writeTestPackage(
          packages,
          additionalPayloadFiles: <String, List<int>>{
            'project/assets/.pokemap-media.json': utf8.encode(
              jsonEncode(mediaCatalog.toJson()),
            ),
            'presentation/cinematics/publication.json': utf8.encode(
              jsonEncode(<String, Object?>{
                'canPublish': true,
                'totalPayloadBytes': mediaBytes.length,
                'media': <Object?>[
                  <String, Object?>{
                    'id': 'opening.poster',
                    'sourceAssetId': 'asset.opening.poster',
                    'license': <String, Object?>{
                      'identifier': 'LicenseRef-Poster',
                      'name': 'Poster redistribution grant',
                    },
                  },
                ],
              }),
            ),
            mediaPath: mediaBytes,
          },
        );
        final supportRoot = Directory(p.join(root.path, 'PokeMap'));

        final result = await installer().install(
          package,
          source: GamePackageInstallSource.localFile,
        );

        final versionRoot = Directory(
          p.join(
            supportRoot.path,
            'games',
            result.game.gameId,
            'versions',
            result.game.current.gameVersion.toString(),
          ),
        );
        expect(
          await File(p.join(versionRoot.path, mediaPath)).readAsBytes(),
          mediaBytes,
        );
        expect(
          await File(
            p.join(
              versionRoot.path,
              'presentation',
              'cinematics',
              'publication.json',
            ),
          ).exists(),
          isTrue,
        );
        final healthy = await const InstalledGameVerifier().verify(
          supportRoot: supportRoot,
          gameId: result.game.gameId,
          pointer: result.game.current,
          receiptFileName: result.game.currentVersion.receiptFileName,
        );
        expect(healthy.code, InstalledGameVerificationCode.healthy);

        await File(
          p.join(versionRoot.path, mediaPath),
        ).writeAsBytes(<int>[...mediaBytes, 0], flush: true);
        final altered = await const InstalledGameVerifier().verify(
          supportRoot: supportRoot,
          gameId: result.game.gameId,
          pointer: result.game.current,
          receiptFileName: result.game.currentVersion.receiptFileName,
        );
        expect(altered.code, InstalledGameVerificationCode.sizeMismatch);
        expect(altered.affectedPaths, <String>[mediaPath]);
      },
    );

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

      await service.install(first, source: GamePackageInstallSource.localFile);
      await service.install(second, source: GamePackageInstallSource.localFile);

      final library =
          await GameLibraryStore(
            supportRoot: Directory(p.join(root.path, 'PokeMap')),
          ).load();
      expect(library.library.games.map((game) => game.gameId), <String>[
        'games.example.first',
        'games.example.second',
      ]);
    });

    test('rejects insufficient disk before creating a transaction', () async {
      final package = await writeTestPackage(packages);

      await expectLater(
        installer(
          disk: (_) async => 1,
        ).install(package, source: GamePackageInstallSource.localFile),
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
      final version1 = await writeTestPackage(packages, gameVersion: '1.0.0');
      final version2 = await writeTestPackage(packages, gameVersion: '2.0.0');
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
      final library =
          await GameLibraryStore(
            supportRoot: Directory(p.join(root.path, 'PokeMap')),
          ).load();
      expect(
        library.library.games.single.current.gameVersion.toString(),
        '1.0.0',
      );
    });

    test(
      'times out an opaque load smoke without publishing a version',
      () async {
        final package = await writeTestPackage(packages);

        await expectLater(
          installer(
            smoke: (_, _) => Completer<void>().future,
            smokeTimeout: const Duration(milliseconds: 10),
          ).install(package, source: GamePackageInstallSource.localFile),
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
      },
    );

    test('installs an update side by side after save preparation', () async {
      final version1 = await writeTestPackage(packages, gameVersion: '1.0.0');
      final version2 = await writeTestPackage(packages, gameVersion: '1.1.0');
      var prepared = false;
      final service = installer(
        prepareSaves: (current, candidate) async {
          expect(current.gameVersion.toString(), '1.0.0');
          expect(candidate.gameVersion.toString(), '1.1.0');
          prepared = true;
          return const SaveUpdatePreparation(rollbackSnapshotAvailable: true);
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
        p.join(root.path, 'PokeMap', 'games', result.game.gameId, 'versions'),
      );
      expect(
        (await versionsRoot.list().toList()).whereType<Directory>().map(
          (entry) => p.basename(entry.path),
        ),
        containsAll(<String>['1.0.0', '1.1.0']),
      );
    });

    test(
      'treats reimporting an installed side version as idempotent',
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
          (await service.readCurrent(
            result.game.gameId,
          )).gameVersion.toString(),
          '2.0.0',
        );
      },
    );

    test('does not activate update when save preparation fails', () async {
      final version1 = await writeTestPackage(packages, gameVersion: '1.0.0');
      final version2 = await writeTestPackage(packages, gameVersion: '1.1.0');
      final service = installer(
        prepareSaves: (_, _) async => throw StateError('migration failed'),
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
        (await service.readCurrent(
          'games.example.adventure',
        )).gameVersion.toString(),
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
      await service.install(first, source: GamePackageInstallSource.localFile);

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
