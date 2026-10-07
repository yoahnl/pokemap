import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'native exploration resolves dedicated character assets and authored frame timing',
      () async {
    final root = await Directory.systemTemp.createTemp('spatial-runtime-');
    addTearDown(() => root.delete(recursive: true));
    final image = img.Image(width: 128, height: 64);
    final path = '${root.path}/hero.png';
    await File(path).writeAsBytes(img.encodePng(image));
    final character = ProjectCharacterEntry(
        id: 'hero',
        name: 'Héros',
        tilesetId: 'unused',
        animations: [
          for (final direction in [
            EntityFacing.north,
            EntityFacing.south,
            EntityFacing.east,
            EntityFacing.west
          ])
            for (final state in CharacterAnimationState.values)
              CharacterAnimation(
                  state: state,
                  direction: direction,
                  sourceAssetId: 'hero-sheet',
                  frames: const [
                    CharacterAnimationFrame(
                        source: TilesetSourceRect(
                            x: 0, y: 0, width: 32, height: 32),
                        durationMs: 50),
                    CharacterAnimationFrame(
                        source: TilesetSourceRect(
                            x: 64, y: 16, width: 32, height: 32),
                        durationMs: 100)
                  ])
        ]);
    final scene = MapSpatialScene(
        width: 8,
        depth: 8,
        navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 4, z: 4)));
    final manifest = ProjectManifest(
        version: ProjectVersion.v9,
        name: 'Spatial',
        settings: const ProjectSettings(
            dimension: ProjectDimension.threeD,
            defaultPlayerCharacterId: 'hero'),
        maps: const [],
        tilesets: const [],
        characters: [character]);
    final bundle = RuntimeMapBundle(
        manifest: manifest,
        map: MapData(
            version: ProjectVersion.v9,
            id: 'map',
            name: 'Map',
            size: const GridSize(width: 8, height: 8),
            layers: const [],
            spatialScene: scene),
        projectRootDirectory: root.path,
        tilesetAbsolutePathsById: const {},
        characterAnimationAbsolutePathsByAssetId: {'hero-sheet': path});
    final session = await SpatialExplorationSession.load(bundle);
    addTearDown(session.dispose);
    expect(session.bundle.map, bundle.map);
    expect(session.frame(0).frame, const Rect.fromLTWH(0, 0, 32, 32));
    session.movement.setInput(x: 0, z: -1);
    final first = session.frame(.05);
    expect(first.frame, const Rect.fromLTWH(64, 16, 32, 32));
    expect(first.z, lessThan(4));
    session.movement.setInput(x: 1, z: 0, run: true);
    session.frame(.05);
    expect(session.movement.running, isTrue);
    session.movement.releaseInput();
    expect(session.frame(.05).frame, const Rect.fromLTWH(0, 0, 32, 32));
    session.movement.setPaused(true);
    final paused = session.frame(0);
    expect(session.frame(1).x, paused.x);
  });
  test('3D test rejects missing player instead of inventing an atlas',
      () async {
    final bundle = RuntimeMapBundle(
        manifest: const ProjectManifest(
            version: ProjectVersion.v9,
            name: 'Missing hero',
            maps: [],
            tilesets: [],
            settings: ProjectSettings(dimension: ProjectDimension.threeD)),
        map: MapData(
            version: ProjectVersion.v9,
            id: 'map',
            name: 'Map',
            size: const GridSize(width: 2, height: 2),
            spatialScene: MapSpatialScene(width: 2, depth: 2)),
        projectRootDirectory: '/unused',
        tilesetAbsolutePathsById: const {});
    await expectLater(SpatialExplorationSession.load(bundle), throwsStateError);
  });
}
