import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/spatial/spatial_surf_water.dart';

import 'support/project_audio_test_driver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Surf uses authored water zones and bounded coordinates', () {
    final map = MapData(
      id: 'water',
      name: 'Water',
      size: const GridSize(width: 8, height: 6),
      gameplayZones: [
        MapGameplayZone(
          id: 'lake',
          kind: GameplayZoneKind.movement,
          area: const MapRect(
            pos: GridPos(x: 2, y: 1),
            size: GridSize(width: 3, height: 2),
          ),
          movement: const MovementZonePayload(requiredMode: MovementMode.surf),
        ),
      ],
    );
    final water = SpatialSurfWater.fromMap(map);
    expect(water.contains(2.5, 1.5), isTrue);
    expect(water.contains(4.999, 2.999), isTrue);
    expect(water.contains(5, 2), isFalse);
    expect(water.contains(-1, 2), isFalse);
    expect(water.contains(double.nan, 2), isFalse);
    expect(
      water.facingWater(1.5, 1.5, EntityFacing.east),
      const GridPos(x: 2, y: 1),
    );
    expect(water.facingWater(1.5, 1.5, EntityFacing.west), isNull);
  });

  test('masked water keeps authored dry holes traversable', () {
    final map = MapData(
      id: 'masked',
      name: 'Masked',
      size: const GridSize(width: 4, height: 4),
      gameplayZones: [
        MapGameplayZone(
          id: 'pond',
          kind: GameplayZoneKind.movement,
          area: const MapRect(
            pos: GridPos(x: 1, y: 1),
            size: GridSize(width: 2, height: 2),
          ),
          cellMask: const [GridPos(x: 0, y: 0)],
          movement: const MovementZonePayload(requiredMode: MovementMode.surf),
        ),
      ],
    );
    final water = SpatialSurfWater.fromMap(map);
    expect(water.contains(1.5, 1.5), isTrue);
    expect(water.contains(2.5, 2.5), isFalse);
    final classic = GameplayWorldState.initial(
      map: map,
      playerPos: const GridPos(x: 0, y: 0),
    );
    expect(classic.isWaterCell(1, 1), isTrue);
    expect(classic.isWaterCell(2, 2), isFalse);
  });

  test('spatial Surf restores water mode before validating Continue and uses Character clips', () async {
    final root = await Directory.systemTemp.createTemp('surf-session-');
    addTearDown(() => root.delete(recursive: true));
    final path = '${root.path}/hero.png';
    await File(path)
        .writeAsBytes(img.encodePng(img.Image(width: 160, height: 32)));
    final character = ProjectCharacterEntry(
      id: 'hero',
      name: 'Hero',
      tilesetId: 'unused',
      animations: [
        for (final facing in EntityFacing.values)
          for (final state in [
            CharacterAnimationState.walk,
            CharacterAnimationState.surfIdle,
            CharacterAnimationState.surf,
            CharacterAnimationState.surfEnter,
            CharacterAnimationState.surfExit,
          ])
            CharacterAnimation(
              state: state,
              direction: facing,
              sourceAssetId: 'hero',
              frames: [
                CharacterAnimationFrame(
                  source: TilesetSourceRect(
                    x: state == CharacterAnimationState.walk
                        ? 0
                        : state == CharacterAnimationState.surfIdle
                        ? 32
                        : state == CharacterAnimationState.surf
                        ? 64
                        : state == CharacterAnimationState.surfEnter
                        ? 96
                        : 128,
                    y: 0,
                    width: 32,
                    height: 32,
                  ),
                  durationMs: 200,
                ),
              ],
            ),
      ],
    );
    final project = ProjectManifest(
      name: 'Generic Surf',
      maps: const [],
      tilesets: const [],
      settings: const ProjectSettings(
        dimension: ProjectDimension.threeD,
        defaultPlayerCharacterId: 'hero',
        surf: ProjectSurfSettings(
          requiresKnownMove: false,
          accessMode: ProjectSurfAccessMode.always,
        ),
      ),
      characters: [character],
    );
    final map = MapData(
      id: 'lake',
      name: 'Lake',
      size: const GridSize(width: 8, height: 6),
      spatialScene: MapSpatialScene(width: 8, depth: 6),
      gameplayZones: [
        MapGameplayZone(
          id: 'water',
          kind: GameplayZoneKind.movement,
          area: const MapRect(
            pos: GridPos(x: 2, y: 1),
            size: GridSize(width: 4, height: 3),
          ),
          movement: const MovementZonePayload(requiredMode: MovementMode.surf),
        ),
      ],
    );
    final bundle = RuntimeMapBundle(
      manifest: project,
      map: map,
      projectRootDirectory: root.path,
      tilesetAbsolutePathsById: const {},
      characterAnimationAbsolutePathsByAssetId: {'hero': path},
    );
    addTearDown(bundle.resourceBudget.dispose);
    final session = await SpatialExplorationSession.load(
      bundle,
      arrival: const GridPos(x: 1, y: 2),
      facing: EntityFacing.east,
    );
    addTearDown(session.dispose);
    final driver = ProjectAudioTestDriver();
    final audio = RuntimeProjectAudioController(
      mixer: RuntimeAudioMixer(),
      driver: driver,
      settings: ProjectAudioSettings(
        cues: {
          for (final cue in [
            ProjectSoundCue.overworldStep,
            ProjectSoundCue.surfEnter,
            ProjectSoundCue.surfExit,
          ])
            cue: const ProjectSoundBinding(source: ProjectSoundSource.builtin),
        },
      ),
    );
    addTearDown(audio.dispose);
    session.projectAudio = audio;

    expect(session.surfTarget, const GridPos(x: 2, y: 2));
    session.movement.setInput(x: 1, z: 0);
    for (var i = 0; i < 20; i++) {
      session.frame(.05);
    }
    expect(session.movement.x, lessThan(2));
    session.beginSurf(const GridPos(x: 2, y: 2));
    final shore = session.movement.x;
    session.movement.setInput(x: -1, z: 0);
    expect(session.frame(.05).frame.left, 96);
    expect(session.movement.x, shore);
    for (var i = 0; i < 8; i++) {
      session.frame(.05);
    }
    expect(session.movement.x, greaterThanOrEqualTo(2));
    expect(session.surfTransitionActive, isFalse);
    session.movement.setInput(x: 0, z: 0);
    await session.restoreGameState(
      GameState(
        saveId: 'saved',
        currentMapId: 'lake',
        playerPosition: const GridPos(x: 3, y: 2),
        playerSpatialPosition: PlayerSpatialPosition(x: 3.5, z: 2.5),
        playerFacing: EntityFacing.east,
        playerMovementMode: MovementMode.surf,
      ),
    );
    expect(session.movement.movementMode, MovementMode.surf);
    session.frame(.05);
    expect(session.frame(0).frame.left, 32);
    session.movement.setInput(x: 1, z: 0, run: true);
    expect(session.frame(.05).frame.left, 64);
    expect(session.movement.running, isFalse);
    for (var i = 0; i < 25; i++) {
      session.frame(.05);
    }
    expect(session.movement.movementMode, MovementMode.walk);
    await Future<void>.delayed(Duration.zero);
    expect(
      driver.paths.where(
        (path) =>
            path ==
            RuntimeProjectAudioController.builtinPaths[ProjectSoundCue
                .surfEnter],
      ),
      hasLength(1),
    );
    expect(
      driver.paths.where(
        (path) =>
            path ==
            RuntimeProjectAudioController.builtinPaths[ProjectSoundCue
                .surfExit],
      ),
      hasLength(1),
    );
    expect(
      driver.paths.where(
        (path) =>
            path ==
            RuntimeProjectAudioController.builtinPaths[ProjectSoundCue
                .overworldStep],
      ),
      isNotEmpty,
    );
  });
}
