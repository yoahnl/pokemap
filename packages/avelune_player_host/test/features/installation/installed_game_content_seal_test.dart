import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:avelune_player_host/features/installation/data/repositories/installed_game_content_seal.dart';
import 'package:avelune_player_host/avelune_player_host.dart';
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

  test('a rewritten file with the same size is hashed again', () async {
    await verify();
    final project = installed('project/project.json');
    final bytes = project.readAsBytesSync();
    bytes[bytes.length - 1] ^= 1;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    project.writeAsBytesSync(bytes, flush: true);

    final (verification, hashed) = await verify();
    expect(hashed, ['project/project.json']);
    expect(verification.code, InstalledGameVerificationCode.hashMismatch);
    expect(verification.affectedPaths, ['project/project.json']);
  });

  Future<void> relabel(Iterable<File> files) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    for (final file in files) {
      final mode = (file.statSync().mode & 0x1ff).toRadixString(8);
      expect(Process.runSync('chmod', ['000', file.path]).exitCode, 0);
      expect(Process.runSync('chmod', [mode, file.path]).exitCode, 0);
    }
  }

  List<File> installedFiles(InstalledGameVerification verification) => [
    installed('game-manifest.json'),
    for (final entry in verification.manifest!.content.files)
      installed(entry.path),
  ];

  test('an install relabeled as a whole keeps its seal', () async {
    final (first, _) = await verify();
    await relabel(installedFiles(first));

    final (verification, hashed) = await verify();
    expect(verification.isHealthy, isTrue);
    expect(hashed, isEmpty);
    final (_, again) = await verify();
    expect(again, isEmpty);
  });

  test('a partly relabeled install keeps its seal', () async {
    final (first, _) = await verify();
    final files = installedFiles(first);
    await relabel(files.take(files.length ~/ 2));

    final (verification, hashed) = await verify();
    expect(verification.isHealthy, isTrue);
    expect(hashed, isEmpty);
  });

  test('a relabeled install hashes only its resized file', () async {
    final (first, _) = await verify();
    final project = installed('project/project.json');
    project.writeAsBytesSync([...project.readAsBytesSync(), 32], flush: true);
    await relabel(installedFiles(first));

    final (verification, hashed) = await verify();
    expect(hashed, ['project/project.json']);
    expect(verification.code, InstalledGameVerificationCode.hashMismatch);
    expect(verification.affectedPaths, ['project/project.json']);
  });

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
