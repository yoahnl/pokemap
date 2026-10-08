import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/platform/playtest/studio_playtest_session.dart';
import 'package:avelune_studio/platform/playtest/studio_spatial_playtest.dart';
import 'package:avelune_studio/platform/playtest/studio_spatial_playtest_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../../../../packages/map_runtime/test/session/spatial_exploration_game_session_runtime_test.dart'
    as fixtures;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late RuntimeMapBundle bundle;
  late StudioPlaytestSession saves;
  final hosts = <StudioSpatialPlaytest>[];

  setUp(() async {
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
  });

  Future<StudioSpatialPlaytest> prepare({bool restore = false}) async {
    final host = await StudioSpatialPlaytest.prepare(
      bundle: bundle,
      projectFilePath: '${root.path}/project.json',
      projectRevision: 'studio-fixture-revision',
      saves: saves,
      restore: restore,
    );
    hosts.add(host);
    return host;
  }

  tearDown(() async {
    for (final host in hosts) {
      await host.dispose();
    }
    hosts.clear();
    await root.delete(recursive: true);
  });

  test('3D direct test rejects a missing authored New Game', () async {
    bundle = bundle.copyWith(
      manifest: bundle.manifest.copyWith(
        newGame: const ProjectNewGameConfig(enabled: false),
      ),
    );
    await expectLater(
      prepare(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'diagnostic',
          contains('Configurez la nouvelle partie'),
        ),
      ),
    );
    expect(saves.hasSave, isFalse);
  });

  test(
    'selected spatial map seeds its exact feet without changing authored data',
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
      await File(
        '${root.path}/project.json',
      ).writeAsString(jsonEncode(bundle.manifest.toJson()));
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
    },
  );

  testWidgets(
    'spatial playtest fills the scene under the toolbar Column loose width',
    (tester) async {
      final host = (await tester.runAsync(prepare))!;
      await tester.runAsync(() async {
        await host.runtime.load((_) {});
        await host.runtime.gameplayReady;
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const SizedBox(height: 40),
                Expanded(
                  child: StudioSpatialPlaytestView(runtime: host.runtime),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      final sceneSize = tester.getSize(find.byType(SpatialExplorationView));
      final surfaceSize = tester.getSize(find.byType(Scaffold));
      expect(sceneSize.width, surfaceSize.width);
      expect(sceneSize.height, surfaceSize.height - 40);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Studio keyboard runs model Event V2 and save restores final pose',
    (tester) async {
      bundle = fixtures.animatedDoorBundle(bundle);
      final host = (await tester.runAsync(prepare))!;
      await tester.runAsync(() async {
        await host.runtime.load((_) {});
        await host.runtime.gameplayReady;
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudioSpatialPlaytestView(
              runtime: host.runtime,
              sceneBuilder: (_) => const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        host
            .runtime
            .overworldInteractionSnapshot!
            .primaryAction!
            .request
            .targetKind,
        RuntimeOverworldInteractionTargetKind.modelInstance,
      );
      await tester.runAsync(
        () => tester.sendKeyEvent(LogicalKeyboardKey.enter),
      );
      await tester.runAsync(
        () => fixtures.waitForValue(
          host.runtime.session!.storyActive,
          (active) => active,
        ),
      );
      await tester.runAsync(() async {
        await expectLater(host.save(), throwsStateError);
      });
      await tester.runAsync(() async => host.runtime.session!.frames(.5));
      await tester.runAsync(
        () => tester.sendKeyEvent(LogicalKeyboardKey.escape),
      );
      await tester.runAsync(() async {
        await fixtures.waitForValue(
          host.runtime.session!.storyActive,
          (active) => !active,
        );
        await fixtures.waitForValue(
          host.runtime.inputAuthority,
          (value) => value.context == RuntimeInputContext.overworld,
        );
      });
      expect(host.runtime.gameStateSnapshot.trainerProfile.money, 0);
      expect(
        host.runtime.gameStateSnapshot.spatialWorldState,
        const SpatialWorldState.empty(),
      );
      await tester.runAsync(
        () => tester.sendKeyEvent(LogicalKeyboardKey.enter),
      );
      await tester.runAsync(
        () => fixtures.waitForValue(
          host.runtime.session!.storyActive,
          (active) => active,
        ),
      );
      await tester.runAsync(() async => host.runtime.session!.frames(2));
      await tester.runAsync(() async {
        await fixtures.waitForValue(
          host.runtime.session!.storyActive,
          (active) => !active,
        );
        await fixtures.waitForValue(
          host.runtime.inputAuthority,
          (value) => value.context == RuntimeInputContext.overworld,
        );
        await Future<void>.delayed(Duration.zero);
        expect(await host.save(), isTrue);
      });
      expect(saves.hasSave, isTrue);
      final state = host.runtime.gameStateSnapshot;
      expect(state.trainerProfile.money, 25);
      expect(
        state.spatialWorldState.modelState('field', 'door')!.normalizedTime,
        1,
      );
      expect(
        state.spatialWorldState.modelState('field', 'door')!.blocksMovement,
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(host.dispose);
      final restored = (await tester.runAsync(() => prepare(restore: true)))!;
      await tester.runAsync(() async {
        await restored.runtime.load((_) {});
        await restored.runtime.gameplayReady;
      });
      expect(
        restored.runtime.gameStateSnapshot.spatialWorldState,
        state.spatialWorldState,
      );
      expect(restored.runtime.gameStateSnapshot.trainerProfile.money, 25);
      restored.runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      expect(restored.runtime.gameStateSnapshot.trainerProfile.money, 25);
    },
  );

  test(
    'Studio cinematic pause and resume preserves NPC route and checkpoint',
    () async {
      bundle = fixtures.npcCinematicBundle(bundle);
      final host = await prepare();
      await host.runtime.load((_) {});
      await fixtures.waitForStory(host.runtime);
      host.runtime.session!.frames(1);
      final intermediate = host.runtime.session!.frames(0)['npc:npc']!.x;
      await host.runtime.pause();
      host.runtime.session!.frames(10);
      expect(host.runtime.session!.frames(0)['npc:npc']!.x, intermediate);
      await host.runtime.resume();
      host.runtime.session!.frames(1);
      await host.runtime.gameplayReady;
      expect(host.runtime.session!.frames(0)['npc:npc']!.x, 6.5);
      expect(await host.save(), isTrue);
      final state = host.runtime.gameStateSnapshot;
      await host.dispose();
      final restored = await prepare(restore: true);
      await restored.runtime.load((_) {});
      await restored.runtime.gameplayReady;
      expect(restored.runtime.session!.frames(0)['npc:npc']!.x, 6.5);
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
