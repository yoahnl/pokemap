import 'dart:async';
import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:test/test.dart';

import '../../support/game_package_fixture.dart';

void main() {
  late Directory root;
  late Directory supportRoot;

  setUp(() async {
    root = await Directory.systemTemp.createTemp(
      'installed-verifier-concurrency-',
    );
    supportRoot = Directory(p.join(root.path, 'PokeMap'));
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('checks installed payload files with bounded concurrency', () async {
    final package = await writeTestPackage(
      Directory(p.join(root.path, 'pkg')),
      extraFiles: 3,
    );
    final installed = await GamePackageInstaller(
      supportRoot: supportRoot,
      inspector: GamePackageInspector(
        hostCompatibility: testHostCompatibility(),
      ),
      availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
      loadSmoke: (_, _) async {},
      prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
    ).install(
      package,
      source: GamePackageInstallSource.localFile,
    );
    final gate = Completer<void>();
    var activeChecks = 0;
    var maxActiveChecks = 0;
    var startedChecks = 0;
    final verifier = InstalledGameVerifier(
      maxConcurrentFileChecks: 2,
      fileIntegrityCheck: (file, entry) async {
        startedChecks++;
        activeChecks++;
        if (activeChecks > maxActiveChecks) {
          maxActiveChecks = activeChecks;
        }
        try {
          await gate.future;
          return null;
        } finally {
          activeChecks--;
        }
      },
    );

    final verification = verifier.verify(
      supportRoot: supportRoot,
      gameId: installed.game.gameId,
      pointer: installed.game.current,
      receiptFileName: installed.game.currentVersion.receiptFileName,
    );
    try {
      await _waitUntil(() => startedChecks >= 2);
      expect(maxActiveChecks, 2);
    } finally {
      gate.complete();
    }

    expect((await verification).isHealthy, isTrue);
  });

  test('still rejects same-size payload tampering in isolate workers',
      () async {
    final package = await writeTestPackage(Directory(p.join(root.path, 'pkg')));
    final installed = await GamePackageInstaller(
      supportRoot: supportRoot,
      inspector: GamePackageInspector(
        hostCompatibility: testHostCompatibility(),
      ),
      availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
      loadSmoke: (_, _) async {},
      prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
    ).install(
      package,
      source: GamePackageInstallSource.localFile,
    );
    final projectFile = File(
      p.join(
        supportRoot.path,
        'games',
        installed.game.gameId,
        'versions',
        installed.game.current.gameVersion.toString(),
        'project',
        'project.json',
      ),
    );
    final bytes = await projectFile.readAsBytes();
    bytes[bytes.length - 1] ^= 1;
    await projectFile.writeAsBytes(bytes, flush: true);

    final verification = await const InstalledGameVerifier().verify(
      supportRoot: supportRoot,
      gameId: installed.game.gameId,
      pointer: installed.game.current,
      receiptFileName: installed.game.currentVersion.receiptFileName,
    );

    expect(verification.code, InstalledGameVerificationCode.hashMismatch);
    expect(verification.affectedPaths, ['project/project.json']);
  });
}

Future<void> _waitUntil(bool Function() predicate) async {
  for (var attempt = 0; attempt < 1000; attempt++) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Condition was not reached before the test timeout.');
}
