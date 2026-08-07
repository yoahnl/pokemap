import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:test/test.dart';

import '../../support/dart_subprocess.dart';
import '../../support/game_package_fixture.dart';

void main() {
  group('GamePackageInstaller recovery', () {
    late Directory root;
    late Directory supportRoot;
    late File package;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('hub-install-kill-test-');
      supportRoot = Directory(p.join(root.path, 'PokeMap'));
      package = await writeTestPackage(Directory(p.join(root.path, 'source')));
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
        );

    Future<ProcessResult> crashAt(GameInstallFaultStage stage) => Process.run(
          dartSubprocessExecutable(),
          <String>[
            '--packages=.dart_tool/package_config.json',
            'test/fixtures/atomic_install_crash_writer.dart',
            supportRoot.path,
            package.path,
            stage.name,
          ],
          workingDirectory: Directory.current.path,
        );

    test('removes abandoned staging after kill before promotion', () async {
      final process =
          await crashAt(GameInstallFaultStage.beforeVersionPromotion);
      expect(process.exitCode, 86, reason: process.stderr.toString());

      final recovery = await installer().recover();

      expect(
        recovery.map((event) => event.code),
        contains(GameInstallationRecoveryCode.abandonedStagingRemoved),
      );
      expect(
        await Directory(
          p.join(
            supportRoot.path,
            'games',
            'games.example.adventure',
            'versions',
            '1.0.0',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        (await GameLibraryStore(supportRoot: supportRoot).load()).library.games,
        isEmpty,
      );
      expect(await installer().recover(), isEmpty);
    });

    test('finishes valid promotion after kill before current pointer',
        () async {
      final process = await crashAt(GameInstallFaultStage.afterVersionPromoted);
      expect(process.exitCode, 86, reason: process.stderr.toString());
      final service = installer();
      expect(
        service.readCurrent('games.example.adventure'),
        throwsA(isA<FormatException>()),
      );

      final recovery = await service.recover();

      expect(
        recovery.map((event) => event.code),
        contains(GameInstallationRecoveryCode.promotionCompleted),
      );
      expect(
        (await service.readCurrent('games.example.adventure'))
            .gameVersion
            .toString(),
        '1.0.0',
      );
      final library = await GameLibraryStore(
        supportRoot: supportRoot,
      ).load();
      expect(library.library.games.single.gameId, 'games.example.adventure');
      expect(await service.recover(), isEmpty);
    });

    test('quarantines a hostile journal before composing its game path',
        () async {
      final transaction = Directory(
        p.join(supportRoot.path, 'games', '.transactions', 'evil'),
      );
      await transaction.create(recursive: true);
      await File(p.join(transaction.path, 'journal.json')).writeAsString(
        CanonicalJson.encode(<String, Object?>{
          'schemaVersion': 1,
          'id': 'evil',
          'state': 'versionPromoted',
          'mode': 'install',
          'activate': true,
          'gameId': '../../saves',
          'gameVersion': '1.0.0',
          'treeSha256': 'a' * 64,
          'receiptFileName': '1.0.0-${'a' * 64}.json',
          'source': 'localFile',
          'createdAt': '2026-07-25T12:00:00.000Z',
        }),
        flush: true,
      );

      final recovery = await installer().recover();

      expect(
        recovery.map((event) => event.code),
        contains(GameInstallationRecoveryCode.transactionQuarantined),
      );
      expect(await transaction.exists(), isFalse);
      expect(
        await Directory(
          p.join(supportRoot.path, 'saves', 'install-receipts'),
        ).exists(),
        isFalse,
      );
      expect(
        await Directory(
          p.join(supportRoot.path, 'games', '.transactions'),
        )
            .list()
            .map((entity) => p.basename(entity.path))
            .any((name) => name.startsWith('evil.quarantine.')),
        isTrue,
      );
      expect(await installer().recover(), isEmpty);
    });
  });
}
