import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../../../../packages/map_runtime/test/session/spatial_exploration_game_session_runtime_test.dart'
    as fixtures;
import 'studio_spatial_gameplay_playtest_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(setUpSpatialPlaytest);

  tearDown(tearDownSpatialPlaytest);

  test(
    'selected spatial map reuses the manifest and seeds its exact feet',
    () async {
      final authored = bundle.map;
      final other = authored.copyWith(
        id: 'other',
        entities: [],
        spatialScene: MapSpatialScene(
          width: 8,
          depth: 8,
          navigation: SpatialNavigationProfile(
            spawn: SpatialSpawn(x: 6.25, z: 5.75),
          ),
        ),
      );
      bundle = bundle.copyWith(
        map: other,
        manifest: bundle.manifest.copyWith(
          maps: [
            ...bundle.manifest.maps,
            ProjectMapEntry(
              id: 'other',
              name: 'Autre terrain',
              relativePath: 'other.json',
            ),
          ],
        ),
      );
      final mapFile = File('${root.path}/field.json');
      await mapFile.writeAsString(jsonEncode(authored.toJson()));
      final before = await mapFile.readAsString();
      final host = await prepare();
      await host.runtime.load((_) {});
      await host.runtime.gameplayReady;
      expect(host.runtime.gameStateSnapshot.currentMapId, 'other');
      expect(host.runtime.session!.movement.x, 6.25);
      expect(host.runtime.session!.movement.z, 5.75);
      expect(
        host.runtime.gameStateSnapshot.playerPosition,
        const GridPos(x: 6, y: 5),
      );
      expect(saves.hasSave, isFalse);
      expect(await mapFile.readAsString(), before);
      expect(await File('${root.path}/other.json').exists(), isFalse);
      expect(await File('${root.path}/project.json').exists(), isFalse);
    },
  );

  test(
    'restore from another selected map reuses the loaded manifest',
    () async {
      final host = await prepare();
      await host.runtime.load((_) {});
      await host.runtime.gameplayReady;
      expect(await host.save(), isTrue);
      final savedState = host.runtime.gameStateSnapshot;
      await host.dispose();
      final authored = bundle.map;
      final other = authored.copyWith(id: 'other', entities: []);
      bundle = bundle.copyWith(
        map: other,
        manifest: bundle.manifest.copyWith(
          maps: [
            ...bundle.manifest.maps,
            const ProjectMapEntry(
              id: 'other',
              name: 'Autre terrain',
              relativePath: 'other.json',
            ),
          ],
        ),
      );
      await File('${root.path}/field.json')
          .writeAsString(jsonEncode(authored.toJson()));
      await File('${root.path}/other.json')
          .writeAsString(jsonEncode(other.toJson()));
      final restored = await prepare(restore: true);
      await restored.runtime.load((_) {});
      await restored.runtime.gameplayReady;
      final restoredState = restored.runtime.gameStateSnapshot;
      expect(restoredState.saveId, savedState.saveId);
      expect(restoredState.currentMapId, savedState.currentMapId);
      expect(
        restoredState.playerSpatialPosition,
        savedState.playerSpatialPosition,
      );
      expect(restoredState.playerFacing, savedState.playerFacing);
      expect(restoredState.trainerProfile, savedState.trainerProfile);
      expect(
        restoredState.spatialWorldState.toJson(),
        savedState.spatialWorldState.toJson(),
      );
      expect(restored.runtime.session!.bundle.map.id, 'field');
      expect(await File('${root.path}/project.json').exists(), isFalse);
    },
  );

  for (final restore in [false, true]) {
    test('scoped map catalog resolves another map, restore=$restore', () async {
      final authored = fixtures.animatedDoorBundle(bundle);
      final other = bundle.map.copyWith(id: 'other', entities: []);
      final project = authored.manifest.copyWith(
        maps: [
          ...authored.manifest.maps,
          const ProjectMapEntry(
            id: 'other',
            name: 'Autre terrain',
            relativePath: 'other.json',
          ),
        ],
      );
      await File('${root.path}/project.json')
          .writeAsString(jsonEncode(project.toJson()));
      await File('${root.path}/field.json')
          .writeAsString(jsonEncode(authored.map.toJson()));
      await File('${root.path}/other.json')
          .writeAsString(jsonEncode(other.toJson()));
      if (restore) {
        bundle = authored.copyWith(manifest: project);
        final host = await prepare();
        await host.runtime.load((_) {});
        await host.runtime.gameplayReady;
        expect(await host.save(), isTrue);
      }
      final catalog = await RuntimeProjectCatalog.open(
        '${root.path}/project.json',
      );
      addTearDown(catalog.dispose);
      final scoped = await catalog.manifestForMap(other);
      expect(scoped.models3d, isEmpty);
      expect(project.models3d, isNotEmpty);
      bundle = RuntimeMapBundle(
        manifest: scoped,
        map: other,
        projectRootDirectory: bundle.projectRootDirectory,
        tilesetAbsolutePathsById: bundle.tilesetAbsolutePathsById,
        characterAnimationAbsolutePathsByAssetId:
            bundle.characterAnimationAbsolutePathsByAssetId,
        projectCatalog: catalog,
      );
      final host = await prepare(restore: restore);
      await host.runtime.load((_) {});
      await host.runtime.gameplayReady;
      expect(
        host.runtime.gameStateSnapshot.currentMapId,
        restore ? 'field' : 'other',
      );
      if (restore) {
        expect(host.runtime.session!.bundle.manifest.models3d, isNotEmpty);
      }
    });
  }

  test(
    'Studio cinematic pause and resume preserves NPC route and checkpoint',
    () async {
      bundle = fixtures.npcCinematicBundle(bundle);
      final host = await prepare();
      await host.runtime.load((_) {});
      await fixtures.waitForStory(host.runtime);
      host.runtime.session!.frames(1);
      final intermediate = host.runtime.session!.frames(0)['field:npc:npc']!.x;
      await host.runtime.pause();
      host.runtime.session!.frames(10);
      expect(host.runtime.session!.frames(0)['field:npc:npc']!.x, intermediate);
      await host.runtime.resume();
      host.runtime.session!.frames(1);
      await host.runtime.gameplayReady;
      expect(host.runtime.session!.frames(0)['field:npc:npc']!.x, 6.5);
      expect(await host.save(), isTrue);
      final state = host.runtime.gameStateSnapshot;
      await host.dispose();
      final restored = await prepare(restore: true);
      await restored.runtime.load((_) {});
      await restored.runtime.gameplayReady;
      expect(restored.runtime.session!.frames(0)['field:npc:npc']!.x, 6.5);
      expect(
        restored.runtime.gameStateSnapshot.spatialWorldState,
        state.spatialWorldState,
      );
      expect(restored.runtime.gameStateSnapshot.trainerProfile.money, 25);
      await saves.delete();
      expect(saves.hasSave, isFalse);
      expect(saves.spatialSave, isNull);
    },
  );
}
