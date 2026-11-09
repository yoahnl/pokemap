import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/core/config/avelune_host_compatibility.dart';
import 'package:pokemap_hub/pokemap_hub_player.dart';

void main() {
  for (final version in ['0_3_31_331', '0_3_37_337']) {
    for (final kind in ['overworld', 'spatial']) {
      test(
        'installs frozen $version $kind and reopens a current checkpoint',
        () async {
          final root = await Directory.systemTemp.createTemp('avelune-frozen-');
          addTearDown(() => root.delete(recursive: true));
          final source = File(
            p.join(
              '..',
              '..',
              'packages',
              'map_distribution',
              'test',
              'fixtures',
              'compatibility',
              'avelune_studio_$version',
              '$kind.avelunegame.base64',
            ),
          );
          final original = await source.readAsBytes();
          final archive = base64Decode(
            utf8.decode(original).replaceAll(RegExp(r'\s'), ''),
          );
          final package = await File(p.join(root.path, 'frozen.avelunegame'))
              .writeAsBytes(archive);
          final support = Directory(p.join(root.path, 'support'));
          var smokeLoads = 0;
          final installed = await GamePackageInstaller(
            supportRoot: support,
            inspector: GamePackageInspector(
              hostCompatibility: aveluneHostCompatibility(),
            ),
            availableDiskBytes: (_) async => 1 << 30,
            loadSmoke: (staged, _) async {
              await _load(p.join(staged.path, 'project', 'project.json'), kind);
              smokeLoads++;
            },
            prepareSavesForUpdate: (_, _) async =>
                const SaveUpdatePreparation(),
          ).install(package, source: GamePackageInstallSource.localFile);
          expect(smokeLoads, 1);
          final launch = await InstalledGameLaunchResolver(
            supportRoot: support,
            hostCompatibility: aveluneHostCompatibility(),
          ).resolve(installed.game);
          final projectFile = await launch.assets.resolveReference(
            launch.project,
          );
          final loaded = await _load(projectFile.path, kind);
          expect(loaded.project.version.name, kind == 'spatial' ? 'v9' : 'v8');
          final initial = kind == 'spatial'
              ? GameState(
                  saveId: 'f1a66236-3c7c-49e5-91e4-a77bac5d0021',
                  currentMapId: loaded.map.id,
                  playerPosition: const GridPos(x: 6, y: 6),
                  playerSpatialPosition: PlayerSpatialPosition(
                    x: 6,
                    z: 6,
                  ),
                )
              : createNewGameStateFromProject(
                  project: loaded.project,
                  startMap: loaded.map,
                  saveId: 'f1a66236-3c7c-49e5-91e4-a77bac5d0021',
                  tileWidthPx: loaded.project.settings.tileWidth,
                  tileHeightPx: loaded.project.settings.tileHeight,
                );
          final saved = initial.copyWith(playerFacing: EntityFacing.west);
          const mapper = GameStateSaveEnvelopeMapper();
          final envelope = mapper.create(
            identity: launch.identity,
            profileId: 'local',
            slotId: 'slot-1',
            saveId: 'f1a66236-3c7c-49e5-91e4-a77bac5d0021',
            createdAt: DateTime.utc(2026, 11, 9),
            updatedAt: DateTime.utc(2026, 11, 9, 0, 2),
            status: SaveStatus.active,
            playTimeSeconds: 125,
            gameState: saved,
          );
          final store = HubSaveStore(
            supportRoot: support,
            identity: launch.identity,
          );
          await store.writeVerified(envelope);
          final fresh = HubPlayerSaveGateway(
            store: HubSaveStore(
              supportRoot: support,
              identity: launch.identity,
            ),
          );
          final address = SaveSlotAddress(
            gameId: launch.identity.gameId,
            profileId: 'local',
            slotId: 'slot-1',
          );
          final summary = await fresh.readSummary(address);
          final restored = await fresh.readLaunchableEnvelope(address);
          expect(summary?.canContinue, isTrue);
          expect(summary?.playTimeSeconds, 125);
          expect(restored, isNotNull);
          expect(mapper.restore(restored!), saved);
          expect(await source.readAsBytes(), original);
          expect(await package.readAsBytes(), archive);
        },
      );
    }
  }
}

Future<({ProjectManifest project, MapData map})> _load(
  String projectPath,
  String kind,
) async {
  if (kind == 'spatial') {
    final bootstrap = SpatialExplorationBootstrap(
      projectFilePath: () async => projectPath,
    );
    try {
      final loaded = await bootstrap.prepare();
      expect(loaded.startMap.spatialScene, isNotNull);
      return (project: loaded.project, map: loaded.startMap);
    } finally {
      bootstrap.clear();
    }
  }
  final loaded = await loadRuntimeMapBundle(
      projectFilePath: projectPath, mapId: 'runtime_harbor');
  try {
    expect(loaded.map.id, 'runtime_harbor');
    return (project: loaded.manifest, map: loaded.map);
  } finally {
    loaded.projectCatalog?.dispose();
  }
}
