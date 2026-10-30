import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/spatial/spatial_story_playback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('real spatial session carries hero and first companion then resumes following at the dock', () async {
    final root = Directory(
      '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7/platforms/session',
    );
    await root.create(recursive: true);
    addTearDown(() => root.delete(recursive: true));
    final path = '${root.path}/actors.png';
    await File(path)
        .writeAsBytes(img.encodePng(img.Image(width: 32, height: 32)));
    final project = ProjectManifest(
      name: 'Route platforms',
      version: ProjectVersion.v9,
      maps: const [],
      tilesets: const [],
      settings: const ProjectSettings(
        dimension: ProjectDimension.threeD,
        defaultPlayerCharacterId: 'hero',
      ),
      characters: [
        for (final id in ['hero', 'companion'])
          ProjectCharacterEntry(
            id: id,
            name: id,
            tilesetId: 'unused',
            animations: [
              for (final facing in EntityFacing.values)
                for (final motion in [
                  CharacterAnimationState.idle,
                  CharacterAnimationState.walk,
                ])
                  CharacterAnimation(
                    state: motion,
                    direction: facing,
                    sourceAssetId: 'actors',
                    frames: const [
                      CharacterAnimationFrame(
                        source: TilesetSourceRect(
                          x: 0,
                          y: 0,
                          width: 32,
                          height: 32,
                        ),
                        durationMs: 100,
                      ),
                    ],
                  ),
            ],
          ),
      ],
      partyCompanion: const ProjectPartyCompanionConfig(
        enabled: true,
        mappings: [
          PartyCompanionVisual(
            speciesId: 'bird',
            formId: 'default',
            characterId: 'companion',
          ),
        ],
      ),
    );
    final platform = SpatialPlatformDefinition(
      id: 'ride',
      name: 'Ride',
      instanceId: 'deck',
      x: 2,
      z: 2,
      width: 3,
      depth: 3,
      height: 0,
      durationMs: 1000,
      routes: [
        SpatialPlatformRoute(
          id: 'main',
          waypoints: [
            SpatialPlatformStop(x: 0, z: 0),
            SpatialPlatformStop(x: 1, z: 1),
            SpatialPlatformStop(x: 4, z: 1),
          ],
        ),
      ],
    );
    final map = MapData(
      id: 'room',
      name: 'Room',
      size: const GridSize(width: 14, height: 10),
      spatialScene: MapSpatialScene(
        width: 14,
        depth: 10,
        navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 3, z: 3)),
        instances: [
          SpatialModelInstance(
            id: 'deck',
            modelId: 'deck-model',
            position: Model3dVector3(x: 3, y: 0, z: 3),
            blocksMovement: false,
          ),
        ],
        platforms: [platform],
      ),
    );
    final bundle = RuntimeMapBundle(
      manifest: project,
      map: map,
      projectRootDirectory: root.path,
      tilesetAbsolutePathsById: const {},
      characterAnimationAbsolutePathsByAssetId: {'actors': path},
    );
    var state = GameState(
      saveId: 'test',
      currentMapId: 'room',
      playerPosition: const GridPos(x: 3, y: 3),
      playerSpatialPosition: PlayerSpatialPosition(x: 3, z: 3),
      party: PlayerParty(
        members: [
          PlayerPokemon(
            individualId: 'one',
            speciesId: 'bird',
            formId: 'default',
            natureId: 'hardy',
            abilityId: 'natural',
            currentHp: 10,
          ),
        ],
      ),
    );
    final session = await SpatialExplorationSession.load(
      bundle,
      presentationStateProvider: () => state,
    );
    addTearDown(session.dispose);
    session.movement.setInput(x: 1, z: 0);
    for (var frame = 0; frame < 16; frame++) {
      session.frames(.025);
    }
    session.movement.releaseInput();
    state = state.copyWith(
      playerSpatialPosition: session.movement.spatialPosition,
      playerPosition: GridPos(
        x: session.movement.x.floor(),
        y: session.movement.z.floor(),
      ),
    );
    expect(session.frames(0), contains('party-companion'));
    final original = state;
    final story = SpatialStoryPlayback(
      session: session,
      readGameState: () => state,
      writeGameState: (value) => state = value,
    );
    addTearDown(story.dispose);
    final ride = story.playPlatform(
      SceneInteractiveCommand.movePlatform(
        mapId: 'room',
        platformId: 'ride',
        motion: MovingPlatformMotion.forward,
      ),
    );
    expect(session.storyActive.value, isTrue);
    for (var frame = 0; frame < 20; frame++) {
      session.frames(.025);
    }
    expect(state, original);
    expect(
      session.frames(0)['hero']!.x,
      greaterThan(original.playerSpatialPosition!.x),
    );
    expect(session.companionPosition!.x, greaterThan(3));
    session.setLifecyclePaused(true);
    final paused = session.companionPosition!;
    session.frames(.5);
    expect(session.companionPosition!.x, paused.x);
    session.setLifecyclePaused(false);
    for (var frame = 0; frame < 20; frame++) {
      session.frames(.025);
    }
    expect(await ride, 'moved');
    expect(
      state.playerSpatialPosition!.x,
      original.playerSpatialPosition!.x + 4,
    );
    expect(session.platformTransportActive, isFalse);
    final companion = session.companionPosition!;
    await session.restoreGameState(state);
    session.movement.setInput(x: 1, z: 0);
    for (var frame = 0; frame < 20; frame++) {
      session.frames(.025);
      state = state.copyWith(
        playerSpatialPosition: session.movement.spatialPosition,
      );
    }
    session.movement.releaseInput();
    expect(session.companionPosition!.x, greaterThan(companion.x));
    expect(
      session.frames(0).keys.where((value) => value == 'party-companion'),
      hasLength(1),
    );
  });
}
