import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/src/spatial/spatial_exploration_bootstrap.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:pokemap_hub/core/config/avelune_host_compatibility.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late File package;
  late Directory support;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('spatial-installer-');
    support = Directory(p.join(root.path, 'support'));
    final project = Directory(p.join(root.path, 'authoring'));
    final original = Directory(
      p.normalize(p.join(Directory.current.path, '..', 'hgss_first_map')),
    );
    await for (final file in original.list(
      recursive: true,
      followLinks: false,
    )) {
      final path = p.relative(file.path, from: original.path);
      if (file is! File || path.startsWith('.pokemap${p.separator}')) continue;
      final target = File(p.join(project.path, path));
      await target.parent.create(recursive: true);
      await file.copy(target.path);
    }
    package = File(p.join(root.path, 'exploration.avelunegame'));
    await const CanonicalGamePackageExportService().exportToFile(
      projectRoot: project,
      profile: GamePackageExportProfile(
        gameId: 'games.test.spatial-install',
        gameVersion: '0.1.0',
        title: 'Exploration',
        authorName: 'Test',
        defaultLocale: 'fr',
        supportedLocales: ['fr'],
      ),
      outputFile: package,
      mode: GamePackageExportMode.localTest,
    );
    await project.delete(recursive: true);
  });
  tearDown(() async => root.delete(recursive: true));

  GamePackageInstaller installer() => GamePackageInstaller(
    supportRoot: support,
    inspector: GamePackageInspector(
      hostCompatibility: aveluneHostCompatibility(),
    ),
    availableDiskBytes: (_) async => 1 << 40,
    loadSmoke: (_, _) async {},
    prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
  );

  test(
    'installs the autonomous authored 3D exploration through staged validation',
    () async {
      final result = await installer().install(
        package,
        source: GamePackageInstallSource.localFile,
      );
      final map = File(
        p.join(
          support.path,
          'games',
          result.game.gameId,
          'versions',
          '0.1.0',
          'project',
          'maps',
          'first-map.json',
        ),
      );
      expect(map.existsSync(), isTrue);
      final model = File(
        p.join(
          p.dirname(p.dirname(map.path)),
          'assets',
          'models3d',
          'terrain.glb',
        ),
      );
      expect(model.existsSync(), isTrue);
      final bootstrap = SpatialExplorationBootstrap(
        projectFilePath:
            () async => p.join(p.dirname(p.dirname(map.path)), 'project.json'),
      );
      final prepared = await bootstrap.prepare();
      expect(prepared.startMap.id, 'first-map');
      expect(prepared.startMap.spatialScene, isNotNull);
      expect(prepared.project.newGame.enabled, isFalse);
      expect(prepared.startMap.entities.single.npc?.characterId, isNotNull);
      final dialogue = prepared.project.dialogues.single;
      expect(
        File(
          p.join(p.dirname(p.dirname(map.path)), dialogue.relativePath),
        ).existsSync(),
        isTrue,
      );
      bootstrap.clear();
    },
  );
}
