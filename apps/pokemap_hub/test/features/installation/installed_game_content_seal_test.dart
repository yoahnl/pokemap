import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/features/installation/data/repositories/installed_game_content_seal.dart';
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:test/test.dart';

import '../../support/game_package_fixture.dart';

void main() {
  late Directory root;
  late Directory supportRoot;
  late InstalledGame game;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('installed-content-seal-');
    supportRoot = Directory(p.join(root.path, 'PokeMap'));
    final package = await writeTestPackage(
      Directory(p.join(root.path, 'pkg')),
      extraFiles: 3,
    );
    game = (await GamePackageInstaller(
      supportRoot: supportRoot,
      inspector: GamePackageInspector(
        hostCompatibility: testHostCompatibility(),
      ),
      availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
      loadSmoke: (_, _) async {},
      prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
    ).install(package, source: GamePackageInstallSource.localFile)).game;
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  File seal() => InstalledGameContentSeal.fileFor(
    supportRootPath: supportRoot.path,
    gameId: game.gameId,
    receiptFileName: game.currentVersion.receiptFileName,
  );

  File installed(String relativePath) => File(
    p.joinAll([
      supportRoot.path,
      'games',
      game.gameId,
      'versions',
      game.current.gameVersion.toString(),
      ...p.posix.split(relativePath),
    ]),
  );

  Future<(InstalledGameVerification, List<String>)> verify() async {
    final hashed = <String>[];
    final verification =
        await InstalledGameVerifier(
          fileIntegrityCheck: (file, entry) async {
            hashed.add(entry.path);
            final digest = sha256.convert(await file.readAsBytes()).toString();
            return digest == entry.sha256
                ? null
                : InstalledGameVerificationCode.hashMismatch;
          },
        ).verify(
          supportRoot: supportRoot,
          gameId: game.gameId,
          pointer: game.current,
          receiptFileName: game.currentVersion.receiptFileName,
        );
    return (verification, hashed);
  }

  test(
    'a sealed install skips hashing the files that did not change',
    () async {
      if (seal().existsSync()) seal().deleteSync();
      final (first, firstHashed) = await verify();
      expect(first.isHealthy, isTrue);
      expect(firstHashed, hasLength(first.manifest!.content.files.length));
      expect(seal().existsSync(), isTrue);
      final (second, secondHashed) = await verify();
      expect(second.isHealthy, isTrue);
      expect(secondHashed, isEmpty);
    },
  );

  test(
    'a rewritten file is hashed again even with its size and mtime kept',
    () async {
      await verify();
      final project = installed('project/project.json');
      final modified = project.lastModifiedSync();
      final bytes = project.readAsBytesSync();
      bytes[bytes.length - 1] ^= 1;
      project.writeAsBytesSync(bytes, flush: true);
      project.setLastModifiedSync(modified);

      final (_, hashed) = await verify();
      expect(hashed, ['project/project.json']);
      final verification = await const InstalledGameVerifier().verify(
        supportRoot: supportRoot,
        gameId: game.gameId,
        pointer: game.current,
        receiptFileName: game.currentVersion.receiptFileName,
      );
      expect(verification.code, InstalledGameVerificationCode.hashMismatch);
      expect(verification.affectedPaths, ['project/project.json']);
    },
  );

  test('a damaged seal falls back to hashing every file', () async {
    await verify();
    seal().writeAsStringSync('not a seal');
    final (verification, hashed) = await verify();
    expect(verification.isHealthy, isTrue);
    expect(hashed, hasLength(verification.manifest!.content.files.length));
  });

  test('a rewritten manifest invalidates the whole seal', () async {
    await verify();
    final manifest = installed('game-manifest.json');
    manifest.writeAsBytesSync(manifest.readAsBytesSync(), flush: true);
    final (verification, hashed) = await verify();
    expect(verification.isHealthy, isTrue);
    expect(hashed, hasLength(verification.manifest!.content.files.length));
  });

  test('a failed verification leaves no seal behind', () async {
    if (seal().existsSync()) seal().deleteSync();
    final project = installed('project/project.json');
    final bytes = project.readAsBytesSync();
    bytes[0] ^= 1;
    project.writeAsBytesSync(bytes, flush: true);
    final verification = await const InstalledGameVerifier().verify(
      supportRoot: supportRoot,
      gameId: game.gameId,
      pointer: game.current,
      receiptFileName: game.currentVersion.receiptFileName,
    );
    expect(verification.code, InstalledGameVerificationCode.hashMismatch);
    expect(seal().existsSync(), isFalse);
  });
}
