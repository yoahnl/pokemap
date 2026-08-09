import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_editor/game_export.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'second neutral game exports, loses its source and installs offline',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'pokemap-phase8-neutral-',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final authorRoot = Directory(p.join(root.path, 'author-workspace'));
      final supportRoot = Directory(p.join(root.path, 'application-support'));
      final packageFile = File(p.join(root.path, 'neutral-1.0.0.avelunegame'));
      final fixture = NeutralCertificationGameFixture();
      await fixture.writeAuthorWorkspace(authorRoot);

      final artifact = await const GamePackageExportService().exportToFile(
        projectRoot: authorRoot,
        profile: fixture.exportProfile,
        outputFile: packageFile,
      );
      expect(artifact.certification.isCertified, isTrue);
      expect(artifact.manifest.gameId, fixture.gameId);
      expect(artifact.scrubbedSecretFieldCount, greaterThanOrEqualTo(2));

      await authorRoot.delete(recursive: true);
      expect(await authorRoot.exists(), isFalse);

      final progress = <GameInstallProgress>[];
      final installed =
          await GamePackageInstaller(
            supportRoot: supportRoot,
            inspector: GamePackageInspector(
              hostCompatibility: fixture.hostCompatibility,
            ),
            availableDiskBytes: (_) async => 1024 * 1024 * 1024,
            prepareSavesForUpdate: (_, __) async =>
                const SaveUpdatePreparation(rollbackSnapshotAvailable: true),
            loadSmoke: (stagedVersionRoot, manifest) async {
              final projectFile = File(
                p.join(stagedVersionRoot.path, 'project', 'project.json'),
              );
              final project = ProjectManifest.fromJson(
                jsonDecode(await projectFile.readAsString())
                    as Map<String, dynamic>,
              );
              expect(project.newGame.enabled, isTrue);
              expect(project.newGame.startMapId, fixture.mapId);
              final bundle = await loadRuntimeMapBundle(
                projectFilePath: projectFile.path,
                mapId: fixture.mapId,
              );
              expect(bundle.map.mapMetadata.defaultSpawnId, fixture.spawnId);
            },
          ).install(
            packageFile,
            source: GamePackageInstallSource.localExport,
            onProgress: progress.add,
          );

      expect(installed.game.gameId, fixture.gameId);
      expect(installed.receipt.packageSha256, artifact.packageSha256);
      expect(
        installed.receipt.treeSha256,
        artifact.manifest.content.treeSha256,
      );
      expect(progress.last.stage, GameInstallStage.completed);
      expect(
        await File(
          p.join(
            supportRoot.path,
            'games',
            fixture.gameId,
            'versions',
            fixture.gameVersion,
            'project',
            'project.json',
          ),
        ).exists(),
        isTrue,
      );
      final installedVersion = Directory(
        p.join(
          supportRoot.path,
          'games',
          fixture.gameId,
          'versions',
          fixture.gameVersion,
        ),
      );
      await for (final entity in installedVersion.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File ||
            !const <String>{
              '.json',
              '.txt',
            }.contains(p.extension(entity.path))) {
          continue;
        }
        expect(
          await entity.readAsString(),
          isNot(contains(fixture.authorSecret)),
          reason: p.relative(entity.path, from: installedVersion.path),
        );
      }
      expect(await authorRoot.exists(), isFalse);
    },
  );
}
