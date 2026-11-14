import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/platform/playtest/studio_playtest_session.dart';
import 'package:avelune_studio/platform/playtest/studio_spatial_playtest.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart'
    show AveluneRuntimeCompatibility;
import 'package:map_runtime/map_runtime.dart';

late Directory root;
late RuntimeMapBundle bundle;
late StudioPlaytestSession saves;
final hosts = <StudioSpatialPlaytest>[];

Future<void> setUpSpatialPlaytest() async {
  root = await Directory.systemTemp.createTemp('studio-spatial-gameplay-');
  final png = img.encodePng(img.Image(width: 32, height: 32));
  await File('${root.path}/hero.png').writeAsBytes(png);
  final artifact = ContentArtifactRef.fromBytes(png, mediaType: 'image/png');
  final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
  await blob.parent.create(recursive: true);
  await blob.writeAsBytes(png);
  await File('${root.path}/$assetCatalogStorageKey').writeAsString(
    jsonEncode(
      AssetCatalog(
        records: [
          AssetRecord(
            id: 'hero-sheet',
            logicalPath: 'hero.png',
            artifact: artifact,
          ),
        ],
      ).toJson(),
    ),
  );
  final hero = ProjectCharacterEntry(
    id: 'hero',
    name: 'Héros',
    tilesetId: 'hero-atlas',
    animations: [
      for (final direction in EntityFacing.values)
        CharacterAnimation(
          state: CharacterAnimationState.walk,
          direction: direction,
          sourceAssetId: 'hero-sheet',
          frames: const [
            CharacterAnimationFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
              durationMs: 100,
            ),
          ],
        ),
    ],
  );
  final map = MapData(
    version: ProjectVersion.v9,
    id: 'field',
    name: 'Terrain',
    size: const GridSize(width: 8, height: 8),
    entities: [
      MapEntity(
        id: 'npc',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 4, y: 2),
        npc: MapEntityNpcData(characterId: 'hero'),
      ),
    ],
    spatialScene: MapSpatialScene(
      width: 8,
      depth: 8,
      navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 4, z: 4)),
    ),
  );
  bundle = RuntimeMapBundle(
    manifest: ProjectManifest(
      version: ProjectVersion.v9,
      name: 'Studio 3D',
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        defaultPlayerCharacterId: 'hero',
        spatialCamera: SpatialCameraProfile(),
      ),
      newGame: const ProjectNewGameConfig(enabled: true, startMapId: 'field'),
      maps: const [
        ProjectMapEntry(
          id: 'field',
          name: 'Terrain',
          relativePath: 'field.json',
        ),
      ],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'hero-atlas',
          name: 'Héros',
          relativePath: 'hero.png',
        ),
      ],
      characters: [hero],
    ),
    map: map,
    projectRootDirectory: root.path,
    tilesetAbsolutePathsById: {'hero-atlas': '${root.path}/hero.png'},
    characterAnimationAbsolutePathsByAssetId: {
      'hero-sheet': '${root.path}/hero.png',
    },
  );
  saves = StudioPlaytestSession();
}

Future<StudioSpatialPlaytest> prepare({bool restore = false}) async {
  final host = await StudioSpatialPlaytest.prepare(
    bundle: bundle,
    projectFilePath: '${root.path}/project.json',
    projectRevision: 'studio-fixture-revision',
    saves: saves,
    restore: restore,
  );
  hosts.add(host);
  expect(
    host.runtime.descriptor.grantedCapabilities,
    contains(SpatialSceneLightingCapabilities.pointLightShadowsCapabilityId),
  );
  expect(
    host.runtime.descriptor.grantedCapabilities,
    containsAll(AveluneRuntimeCompatibility.host().capabilities),
  );
  expect(
    host.runtime.descriptor.grantedCapabilities,
    containsAll([
      SpatialGameplayCapabilities.periodicRewardConditionCapabilityId,
      SpatialGameplayCapabilities.deferredCraftingCapabilityId,
      CharacterAnimationCanvasCapabilities.capabilityId,
      SpatialModelInstance.conditionalVisibilityCapabilityId,
      SpatialModelInstance.manualEnvironmentEntityBindingCapabilityId,
      PlayerJournalCapabilities.capabilityId,
    ]),
  );
  return host;
}

Future<void> tearDownSpatialPlaytest() async {
  for (final host in hosts) {
    await host.dispose();
  }
  hosts.clear();
  await root.delete(recursive: true);
}
