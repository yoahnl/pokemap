import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import '../../support/game_package_fixture.dart';

void main() {
  group('GameLibraryStore', () {
    late Directory supportRoot;
    late GameLibraryStore store;

    setUp(() async {
      supportRoot = await Directory.systemTemp.createTemp('hub-library-test-');
      store = GameLibraryStore(supportRoot: supportRoot);
    });

    tearDown(() async {
      if (await supportRoot.exists()) {
        await supportRoot.delete(recursive: true);
      }
    });

    test('writes atomically and reads the current library', () async {
      final library = _library(revision: 1, title: 'First');

      await store.save(library);
      final read = await store.load();

      expect(read.source, GameLibrarySource.current);
      expect(read.library.toJson(), library.toJson());
      expect(
        await File(p.join(supportRoot.path, 'library.json')).exists(),
        isTrue,
      );
    });

    test('falls back to the last valid backup after current corruption',
        () async {
      await store.save(_library(revision: 1, title: 'First'));
      await store.save(_library(revision: 2, title: 'Second'));
      await File(p.join(supportRoot.path, 'library.json'))
          .writeAsString('{corrupt', flush: true);

      final read = await store.load();

      expect(read.source, GameLibrarySource.backup);
      expect(read.library.revision, 1);
      expect(read.library.games.single.title, 'First');
      expect(
        read.diagnostics.single.code,
        GameLibraryDiagnosticCode.currentCorrupt,
      );
    });

    test('returns an empty recoverable library when no registry exists',
        () async {
      final read = await store.load();

      expect(read.source, GameLibrarySource.empty);
      expect(read.library.games, isEmpty);
      expect(read.library.revision, 0);
    });

    test('rejects a symlinked support root', () async {
      if (Platform.isWindows) return;
      final outside = await Directory.systemTemp.createTemp('hub-outside-');
      final parent = await Directory.systemTemp.createTemp('hub-link-parent-');
      final link = Link(p.join(parent.path, 'PokeMap'));
      await link.create(outside.path);
      final linkedStore = GameLibraryStore(
        supportRoot: Directory(link.path),
      );
      addTearDown(() async {
        if (await parent.exists()) await parent.delete(recursive: true);
        if (await outside.exists()) await outside.delete(recursive: true);
      });

      await expectLater(
        linkedStore.save(_library(revision: 1, title: 'Unsafe')),
        throwsA(
          isA<GameLibraryStorageException>().having(
            (error) => error.code,
            'code',
            GameLibraryStorageErrorCode.unsafePath,
          ),
        ),
      );
      expect(await outside.list().isEmpty, isTrue);
    });

    test('rebuilds from healthy receipts and ignores an unreceipted directory',
        () async {
      final packageRoot = Directory(p.join(supportRoot.path, 'selected'));
      final version1 = await writeTestPackage(
        packageRoot,
        gameVersion: '1.0.0',
      );
      final version2 = await writeTestPackage(
        packageRoot,
        gameVersion: '2.0.0',
      );
      final installer = GamePackageInstaller(
        supportRoot: supportRoot,
        inspector: GamePackageInspector(
          hostCompatibility: testHostCompatibility(),
        ),
        availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
        loadSmoke: (_, _) async {},
        prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
        now: () => DateTime.utc(2026, 7, 25, 12),
      );
      await installer.install(
        version1,
        source: GamePackageInstallSource.localFile,
      );
      await installer.install(
        version2,
        source: GamePackageInstallSource.localFile,
        mode: GamePackageActivationMode.update,
      );
      await Directory(
        p.join(
          supportRoot.path,
          'games',
          'games.example.adventure',
          'versions',
          '9.9.9',
        ),
      ).create(recursive: true);
      await File(p.join(supportRoot.path, 'library.json'))
          .writeAsString('{corrupt', flush: true);
      final backup = File(p.join(supportRoot.path, 'library.backup.json'));
      if (await backup.exists()) {
        await backup.writeAsString('{corrupt', flush: true);
      }

      final recovery = await installer.recover();
      final rebuilt = (await store.load()).library;

      expect(
        recovery.map((event) => event.code),
        contains(GameInstallationRecoveryCode.libraryRebuilt),
      );
      expect(rebuilt.games.single.current.gameVersion.toString(), '2.0.0');
      expect(
        rebuilt.games.single.versions
            .map((version) => version.gameVersion.toString()),
        <String>['1.0.0', '2.0.0'],
      );
      expect(
        rebuilt.games.single.versions
            .any((version) => version.gameVersion.toString() == '9.9.9'),
        isFalse,
      );
      expect((await store.load()).source, GameLibrarySource.current);
    });
  });
}

GameLibrary _library({required int revision, required String title}) {
  final version = InstalledGameVersion(
    gameVersion: Version.parse('1.0.0'),
    treeSha256: 'a' * 64,
    installedAt: DateTime.utc(2026, 7, 25, 10),
    receiptFileName: '1.0.0-${'a' * 64}.json',
    source: GamePackageInstallSource.localFile,
    signatureStatus: PackageSignatureStatus.notPresent,
  );
  return GameLibrary(
    revision: revision,
    updatedAt: DateTime.utc(2026, 7, 25, 12, revision),
    games: <InstalledGame>[
      InstalledGame(
        gameId: 'games.example.library',
        title: title,
        authorName: 'Example',
        defaultLocale: 'fr',
        supportedLocales: const <String>['fr'],
        current: InstalledGamePointer(
          gameVersion: version.gameVersion,
          treeSha256: version.treeSha256,
        ),
        versions: <InstalledGameVersion>[version],
      ),
    ],
  );
}
