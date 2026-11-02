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
  test(
    'extended Surf canvas preserves reference scale and movement origin',
    () async {
      final session = await _animatedSurfSession(extendedCanvas: true);
      final before = session.movement.spatialPosition;
      final visual = session.frame(.12);
      expect(visual.height, closeTo(3.36, 1e-9));
      expect(visual.resolvedWidth, closeTo(1.92, 1e-9));
      expect(visual.billboardVerticalOffset, closeTo(0, 1e-9));
      expect(session.movement.spatialPosition, before);
      expect(visual.y, session.movement.y);
      expect(visual.groundY, session.movement.groundY);
      session.movement.movementMode = MovementMode.walk;
      session.frame(.2);
      final walking = session.frame(0);
      expect(walking.height, 1.92);
      expect(walking.billboardVerticalOffset, 0);
    },
  );
  test(
    'spatial Surf loop advances at rest and keeps phase while moving',
    () async {
      final session = await _animatedSurfSession();
      final initial = session.movement.spatialPosition;
      expect(session.frame(0).frame.left, 32);
      expect(session.frame(.06).frame.left, 32);
      expect(session.frame(.06).frame.left, 64);
      expect(session.movement.spatialPosition, initial);
      session.movement.setInput(x: 1, z: 0);
      expect(session.frame(.04).frame.left, 64);
      expect(session.movement.x, greaterThan(initial.x));
      session.movement.releaseInput();
      final stopped = session.movement.spatialPosition;
      expect(session.frame(.02).frame.left, 64);
      expect(session.movement.spatialPosition, stopped);
      expect(session.frame(.03).frame.left, 32);
      expect(session.movement.spatialPosition, stopped);
    },
  );

  for (final lock in [
    'lifecycle',
    'dialogue',
    'interaction',
    'transfer',
    'story',
    'movement',
  ]) {
    test('spatial Surf loop freezes and resumes during $lock', () async {
      final session = await _animatedSurfSession();
      final position = session.movement.spatialPosition;
      expect(session.frame(.06).frame.left, 32);
      void setLocked(bool value) {
        switch (lock) {
          case 'lifecycle':
            session.setLifecyclePaused(value);
          case 'dialogue':
            session.dialoguePaused = value;
          case 'interaction':
            session.interactionActive.value = value;
          case 'transfer':
            session.transitioning.value = value;
          case 'story':
            session.storyInputLocked = value;
          case 'movement':
            session.movement.setPaused(value);
        }
      }

      setLocked(true);
      expect(session.frame(1).frame.left, 32);
      expect(session.movement.spatialPosition, position);
      setLocked(false);
      expect(session.frame(.06).frame.left, 64);
      expect(session.movement.spatialPosition, position);
    });
  }

  test(
    'spatial Surf loop starts after entry and exits once on dry land',
    () async {
      final session = await _animatedSurfSession(restoreSurf: false);
      final shore = session.movement.spatialPosition;
      session.beginSurf(const GridPos(x: 2, y: 2));
      expect(session.frame(.05).frame.left, 96);
      expect(session.movement.spatialPosition, shore);
      expect(session.frame(.05).frame.left, 96);
      for (var i = 0; i < 20 && session.surfTransitionActive; i++) {
        session.frame(.05);
      }
      expect(session.surfTransitionActive, isFalse);
      expect(session.movement.movementMode, MovementMode.surf);
      expect(
        session.surfWater.contains(session.movement.x, session.movement.z),
        isTrue,
      );
      session.movement.releaseInput();
      final position = session.movement.spatialPosition;
      final first = session.frame(0).frame.left;
      session.frame(.1);
      expect(session.frame(0).frame.left, isNot(first));
      expect(session.movement.spatialPosition, position);
      session.movement.setInput(x: 1, z: 0);
      for (
        var i = 0;
        i < 40 && session.movement.movementMode == MovementMode.surf;
        i++
      ) {
        session.frame(.05);
      }
      session.movement.releaseInput();
      expect(session.movement.movementMode, MovementMode.walk);
      expect(session.frame(0).frame.left, 128);
      expect(session.frame(.1).frame.left, 128);
      expect(session.frame(.1).frame.left, 0);
      expect(session.surfTransitionActive, isFalse);
    },
  );

  test(
    'spatial Surf loop starts correctly after a cold saved state restore',
    () async {
      final source = await _animatedSurfSession();
      expect(source.frame(.14).frame.left, 64);
      final movement = source.movement;
      final state = GameState(
        saveId: 'surf-loop-continue',
        currentMapId: source.bundle.map.id,
        playerPosition: GridPos(x: movement.x.floor(), y: movement.z.floor()),
        playerSpatialPosition: movement.spatialPosition,
        playerFacing: movement.facing,
        playerMovementMode: movement.movementMode,
      );
      final restored = await _animatedSurfSession(restoreSurf: false);
      await restored.restoreGameState(state);
      expect(restored.movement.spatialPosition, state.playerSpatialPosition);
      expect(restored.movement.movementMode, MovementMode.surf);
      expect(restored.surfTransitionActive, isFalse);
      expect(restored.frame(0).frame.left, 32);
      expect(restored.frame(.11).frame.left, 64);
      expect(restored.movement.spatialPosition, state.playerSpatialPosition);
    },
  );

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

Future<SpatialExplorationSession> _animatedSurfSession({
  bool restoreSurf = true,
  bool extendedCanvas = false,
}) async {
  final root = await Directory.systemTemp.createTemp('surf-loop-');
  addTearDown(() => root.delete(recursive: true));
  final path = '${root.path}/hero.png';
  await File(path).writeAsBytes(
    img.encodePng(img.Image(width: 160, height: extendedCanvas ? 56 : 32)),
  );
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
            presentationReferenceHeightPx:
                extendedCanvas && state != CharacterAnimationState.walk
                ? 32
                : null,
            loop:
                state != CharacterAnimationState.surfEnter &&
                state != CharacterAnimationState.surfExit,
            frames: [
              for (final x in switch (state) {
                CharacterAnimationState.surf ||
                CharacterAnimationState.surfIdle => [32, 64],
                CharacterAnimationState.surfEnter => [96],
                CharacterAnimationState.surfExit => [128],
                _ => [0],
              })
                CharacterAnimationFrame(
                  source: TilesetSourceRect(
                    x: x,
                    y: 0,
                    width: 32,
                    height:
                        extendedCanvas && state != CharacterAnimationState.walk
                        ? 56
                        : 32,
                  ),
                  durationMs:
                      state == CharacterAnimationState.surfEnter ||
                          state == CharacterAnimationState.surfExit
                      ? 150
                      : 100,
                ),
            ],
          ),
    ],
  );
  final project = ProjectManifest(
    name: 'Animated Surf',
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
    id: 'surf-loop-lake',
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
  if (restoreSurf) {
    await session.restoreGameState(
      GameState(
        saveId: 'surf-loop',
        currentMapId: map.id,
        playerPosition: const GridPos(x: 3, y: 2),
        playerSpatialPosition: PlayerSpatialPosition(x: 3.5, z: 2.5),
        playerFacing: EntityFacing.east,
        playerMovementMode: MovementMode.surf,
      ),
    );
  }
  return session;
}
