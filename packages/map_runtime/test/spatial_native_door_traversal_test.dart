import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'support/project_audio_test_driver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late RuntimeMapBundle outside, inside;
  late MapWarp entrance, exit;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('native-door-');
    final path = '${root.path}/hero.png';
    await File(path)
        .writeAsBytes(img.encodePng(img.Image(width: 32, height: 32)));
    final character = ProjectCharacterEntry(
      id: 'hero',
      name: 'Hero',
      tilesetId: 'unused',
      animations: [
        for (final facing in EntityFacing.values)
          for (final state in [
            CharacterAnimationState.walk,
            CharacterAnimationState.idle,
          ])
            CharacterAnimation(
              state: state,
              direction: facing,
              sourceAssetId: 'hero',
              frames: const [
                CharacterAnimationFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
                  durationMs: 100,
                ),
              ],
            ),
      ],
    );
    final model = ProjectModel3dEntry(
      id: 'door-model',
      name: 'Door',
      sourceAssetId: 'source',
      relativePath: 'assets/models3d/door-model.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3(x: -.3, y: 0, z: -.1),
          max: Model3dVector3(x: .3, y: 2, z: .1),
        ),
        meshCount: 1,
        triangleCount: 2,
        animations: [
          Model3dAnimation(index: 0, name: 'open', durationSeconds: 7 / 30),
          Model3dAnimation(index: 1, name: 'close', durationSeconds: 7 / 30),
        ],
      ),
    );
    final manifest = ProjectManifest(
      version: ProjectVersion.v9,
      name: 'Native door',
      settings: const ProjectSettings(
        dimension: ProjectDimension.threeD,
        defaultPlayerCharacterId: 'hero',
      ),
      maps: const [],
      tilesets: const [],
      models3d: [model],
      characters: [character],
    );
    entrance = MapWarp(
      id: 'entrance',
      pos: const GridPos(x: 3, y: 4),
      targetMapId: 'inside',
      targetPos: const GridPos(x: 3, y: 4),
      door: const MapWarpDoor(
        instanceId: 'door',
        openAnimationIndex: 0,
        closeAnimationIndex: 1,
        exitPos: GridPos(x: 3, y: 5),
      ),
    );
    exit = const MapWarp(
      id: 'exit',
      pos: GridPos(x: 3, y: 4),
      targetMapId: 'outside',
      targetPos: GridPos(x: 3, y: 4),
    );
    RuntimeMapBundle bundle(String id, MapWarp warp, {bool door = false}) =>
        RuntimeMapBundle(
          manifest: manifest,
          map: MapData(
            version: ProjectVersion.v9,
            id: id,
            name: id,
            size: const GridSize(width: 8, height: 8),
            warps: [warp],
            spatialScene: MapSpatialScene(
              width: 8,
              depth: 8,
              instances: [
                if (door)
                  SpatialModelInstance(
                    id: 'door',
                    modelId: model.id,
                    position: Model3dVector3(x: 3.5, y: 0, z: 4.5),
                    blocksMovement: false,
                  ),
              ],
              navigation: SpatialNavigationProfile(
                spawn: SpatialSpawn(x: 3.5, z: 5.5),
              ),
            ),
          ),
          projectRootDirectory: root.path,
          tilesetAbsolutePathsById: const {},
          characterAnimationAbsolutePathsByAssetId: {'hero': path},
        );
    outside = bundle('outside', entrance, door: true);
    inside = bundle('inside', exit);
  });

  tearDown(() => root.delete(recursive: true));

  Future<void> flush() async {
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> untilMap(SpatialExplorationSession session, String id) async {
    for (var i = 0; i < 500 && session.bundle.map.id != id; i++) {
      session.frames(1 / 60);
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(session.bundle.map.id, id);
  }

  Future<void> untilCovered(SpatialExplorationSession session) async {
    for (var i = 0; i < 180 && session.nativeDoorBlackout.value < 1; i++) {
      session.frames(1 / 60);
      await flush();
    }
    expect(session.nativeDoorBlackout.value, 1);
    await flush();
  }

  Future<SpatialExplorationGameSessionRuntime> host() async {
    final self = entrance.copyWith(targetMapId: 'outside');
    final map = outside.map.copyWith(warps: [self]);
    final manifest = outside.manifest.copyWith(
      maps: const [
        ProjectMapEntry(
          id: 'outside',
          name: 'Outside',
          relativePath: 'maps/outside.json',
        ),
      ],
      newGame: const ProjectNewGameConfig(enabled: true, startMapId: 'outside'),
    );
    final initial = outside.copyWith(map: map, manifest: manifest);
    final runtime = SpatialExplorationGameSessionRuntime(
      descriptor: GameSessionDescriptor(
        sessionId: 'native-doors',
        sessionToken: 'native-doors',
        identity: GameIdentity(
          gameId: 'org.example.native-doors',
          gameVersion: '1.0.0',
          projectFormat: ProjectFormat.v9,
          saveFormat: 1,
          compatibilityId: 'native-doors',
        ),
        profileId: 'profile',
        slotId: 'slot',
        launchMode: GameSessionLaunchMode.newGame,
        initialGameState: GameState(
          saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
          currentMapId: 'outside',
          playerPosition: const GridPos(x: 3, y: 5),
          playerSpatialPosition: PlayerSpatialPosition(x: 3.5, z: 5.5),
          trainerProfile: const TrainerProfile(
            name: 'Native doors',
            avatarCharacterId: 'hero',
          ),
        ),
        installedVersionHandle: 'installed',
        runtimeApiVersion: '1.4.0',
        grantedCapabilities: const {'map3d@1', 'map3d.gameplay@1'},
        locale: 'fr',
        accessibility: const GameSessionAccessibilityOptions(),
      ),
      projectFilePath: () async => '${root.path}/project.json',
      preloadedInitialMap: ({
        required projectFilePath,
        required descriptor,
        required initialSave,
      }) async => RuntimeInitialMapPreloadResult(bundle: initial),
      mountSession: (_) async {},
      unmountSession: (_) async {},
    );
    addTearDown(runtime.dispose);
    await runtime.load((_) {});
    await runtime.gameplayReady;
    return runtime;
  }

  Future<void> complete(
    SpatialExplorationSession session,
    Future<void> operation,
  ) async {
    var finished = false;
    operation.then((_) => finished = true);
    for (var i = 0; i < 500 && !finished; i++) {
      session.frames(1 / 120);
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(finished, isTrue);
    await operation;
  }

  test('native door cues fire for the door phases and never for a plain transfer', () async {
    final driver = ProjectAudioTestDriver();
    final audio = RuntimeProjectAudioController(mixer: RuntimeAudioMixer(), driver: driver,
      settings: ProjectAudioSettings(cues: {
        ProjectSoundCue.doorOpen: const ProjectSoundBinding(source: ProjectSoundSource.builtin),
        ProjectSoundCue.doorClose: const ProjectSoundBinding(source: ProjectSoundSource.builtin),
      }));
    addTearDown(audio.dispose);
    final session = await SpatialExplorationSession.load(outside,
      loadMap: (id) async => id == 'inside' ? inside : outside, knownMaps: [outside.map, inside.map]);
    addTearDown(session.dispose);
    session.projectAudio = audio;
    await complete(session, session.enterWarp(entrance));
    await complete(session, session.enterWarp(exit));
    await flush();
    expect(driver.paths.where((path) => path == RuntimeProjectAudioController.builtinPaths[ProjectSoundCue.doorOpen]), hasLength(1));
    expect(driver.paths.where((path) => path == RuntimeProjectAudioController.builtinPaths[ProjectSoundCue.doorClose]), hasLength(1));
    await complete(session, session.enterWarp(entrance.copyWith(door: null, transition: const MapWarpTransition(type: MapWarpTransitionType.none))));
    await flush();
    expect(driver.paths, hasLength(2));
  });

  for (final style in [
    (door: true, type: MapWarpTransitionType.fade),
    (door: true, type: MapWarpTransitionType.hgss),
    (door: true, type: MapWarpTransitionType.none),
    (door: false, type: MapWarpTransitionType.fade),
    (door: false, type: MapWarpTransitionType.hgss),
  ]) {
    test('shared departure precedes cold loading for $style', () async {
      final portal = entrance.copyWith(
        door: style.door ? entrance.door : null,
        transition: MapWarpTransition(type: style.type),
      );
      final pending = Completer<RuntimeMapBundle>();
      addTearDown(() {
        if (!pending.isCompleted) pending.complete(inside);
      });
      var loads = 0;
      late final SpatialExplorationSession session;
      session = await SpatialExplorationSession.load(
        outside.copyWith(map: outside.map.copyWith(warps: [portal])),
        loadMap: (_) {
          loads++;
          expect(session.nativeDoorBlackout.value,
              style.type == MapWarpTransitionType.none ? 0 : 1);
          return pending.future;
        },
      );
      addTearDown(session.dispose);
      final operation = session.enterWarp(portal);
      await flush();
      expect(loads, 0);
      expect(session.nativeDoorTraversalActive, isTrue);
      session.frames(.1);
      if (style.door) {
        expect(session.modelRuntimeState('outside', 'door')!.normalizedTime,
            greaterThan(0));
      } else {
        expect(session.nativeDoorBlackout.value, greaterThan(0));
      }
      expect(loads, 0);
      for (var i = 0; i < 120 && loads == 0; i++) {
        session.frames(1 / 60);
        await flush();
      }
      expect(loads, 1);
      expect(session.bundle.map.id, 'outside');
      pending.complete(inside);
      await complete(session, operation);
      expect(session.bundle.map.id, 'inside');
      expect(session.interactionError.value, isNull);
      expect(session.movement.paused, isFalse);
    });
  }

  test('cold arrival door is resolved after departure without replaying it', () async {
    final session = await SpatialExplorationSession.load(
      inside,
      loadMap: (_) async => outside,
    );
    addTearDown(session.dispose);
    final operation = session.enterWarp(exit);
    await flush();
    expect(session.nativeDoorTraversalActive, isTrue);
    session.frames(.1);
    expect(session.nativeDoorBlackout.value, greaterThan(0));
    await untilMap(session, 'outside');
    expect(session.nativeDoorBlackout.value, 1);
    expect(session.nativeDoorHeroVisible, isFalse);
    await complete(session, operation);
    expect(session.movement.x, 3.5);
    expect(session.movement.z, 5.5);
    expect(session.interactionError.value, isNull);
  });

  for (final door in [false, true]) {
    test('shared cold loading can be cancelled without awaiting I/O, door=$door', () async {
      final portal = entrance.copyWith(door: door ? entrance.door : null);
      final pending = Completer<RuntimeMapBundle>();
      var loads = 0;
      final session = await SpatialExplorationSession.load(
        outside.copyWith(map: outside.map.copyWith(warps: [portal])),
        loadMap: (_) {
          loads++;
          return pending.future;
        },
      );
      addTearDown(session.dispose);
      final original = session.movement.spatialPosition;
      var finished = false;
      final operation = session.enterWarp(portal).whenComplete(() => finished = true);
      await untilCovered(session);
      expect(loads, 1);
      session.cancelPendingTransition();
      await flush();
      expect(finished, isTrue);
      expect(session.movement.spatialPosition, original);
      expect(session.movement.paused, isFalse);
      expect(session.nativeDoorBlackout.value, 0);
      pending.complete(inside);
      await operation;
      await flush();
      expect(session.bundle.map.id, 'outside');
      expect(session.interactionError.value, isNull);
    });
  }

  for (final direction in MapWarpLadderDirection.values) {
    test(
      'native ladder $direction lifts the hero before transfer and preserves target coordinates',
      () async {
        await File('${root.path}/hero.png')
            .writeAsBytes(img.encodePng(img.Image(width: 96, height: 32)));
        final character = outside.manifest.characters.single;
        final animated = character.copyWith(
          animations: [
            ...character.animations,
            const CharacterAnimation(
              state: CharacterAnimationState.climb,
              direction: EntityFacing.north,
              sourceAssetId: 'hero',
              frames: [
                CharacterAnimationFrame(source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32), durationMs: 133),
                CharacterAnimationFrame(source: TilesetSourceRect(x: 32, y: 0, width: 32, height: 32), durationMs: 133),
                CharacterAnimationFrame(source: TilesetSourceRect(x: 64, y: 0, width: 32, height: 32), durationMs: 133),
                CharacterAnimationFrame(source: TilesetSourceRect(x: 32, y: 0, width: 32, height: 32), durationMs: 134),
              ],
            ),
          ],
        );
        final ladder = entrance.copyWith(
          door: null,
          ladder: MapWarpLadder(direction: direction, durationSeconds: .5),
        );
        final source = outside.copyWith(
          manifest: outside.manifest.copyWith(characters: [animated]),
          map: outside.map.copyWith(warps: [ladder]),
        );
        final session = await SpatialExplorationSession.load(
          source,
          loadMap: (_) async => inside,
          spatialArrival: PlayerSpatialPosition(x: 3.4375, z: 4.5),
        );
        addTearDown(session.dispose);
        final originalY = session.movement.y;
        final operation = session.enterWarp(ladder);
        await flush();
        for (var i = 0; i < 6; i++) session.frames(1 / 60);
        expect(session.frame(0).frame.left, 0);
        for (var i = 0; i < 9; i++) session.frames(1 / 60);
        final hero = session.frame(0);
        expect(session.bundle.map.id, 'outside');
        expect(hero.x, 3.4375);
        expect(hero.z, 4.5);
        expect(hero.frame.left, 32);
        expect(hero.contactShadow, isFalse);
        expect(
          hero.y,
          closeTo(
            originalY + (direction == MapWarpLadderDirection.up ? 1 : -1),
            1e-6,
          ),
        );
        expect(session.movement.y, originalY);
        expect(session.nativeDoorTraversalActive, isTrue);
        await complete(session, operation);
        expect(session.bundle.map.id, 'inside');
        expect(session.movement.x, 3.5);
        expect(session.movement.z, 4.5);
        expect(session.interactionError.value, isNull);
      },
    );
    test('cancel ladder $direction restores real source coordinates', () async {
      final ladder = entrance.copyWith(
        door: null,
        ladder: MapWarpLadder(direction: direction),
      );
      final source = outside.copyWith(
        map: outside.map.copyWith(warps: [ladder]),
      );
      final session = await SpatialExplorationSession.load(
        source,
        loadMap: (_) async => inside,
        spatialArrival: PlayerSpatialPosition(x: 3.4375, z: 4.5),
      );
      addTearDown(session.dispose);
      final operation = session.enterWarp(ladder);
      await flush();
      session.frames(.1);
      session.cancelPendingTransition();
      await operation;
      expect(session.bundle.map.id, 'outside');
      expect(session.movement.x, 3.4375);
      expect(session.movement.z, 4.5);
      expect(session.nativeDoorTraversalActive, isFalse);
      expect(session.nativeDoorBlackout.value, 0);
    });
  }

  for (final direction in MapWarpLadderDirection.values) {
    test('cold ladder $direction starts before the destination bundle finishes loading', () async {
      final ladder = entrance.copyWith(door: null, ladder: MapWarpLadder(direction: direction));
      final pending = Completer<RuntimeMapBundle>();
      var loadStarted = false;
      final session = await SpatialExplorationSession.load(outside.copyWith(map: outside.map.copyWith(warps: [ladder])), spatialArrival: PlayerSpatialPosition(x: 3.4375, z: 4.5), loadMap: (_) {loadStarted = true; return pending.future;});
      addTearDown(session.dispose);
      final operation = session.enterWarp(ladder); await flush();
      expect(loadStarted, isFalse);
      session.frames(1/60);
      final hero = session.frame(0);
      expect((hero.y - hero.groundY!).abs(), greaterThan(0), reason: 'The first visible climb frame must not wait for map I/O');
      for (var i = 0; i < 60; i++) session.frames(1/60);
      expect(session.nativeDoorBlackout.value, 1); expect(session.bundle.map.id, 'outside');
      await flush(); expect(loadStarted, isTrue);
      pending.complete(inside); await complete(session, operation);
      expect(session.interactionError.value, isNull); expect(session.bundle.map.id, 'inside');
    });
  }

  test('ladder load failure restores the source pose and removes blackout', () async {
    final ladder = entrance.copyWith(door: null, ladder: MapWarpLadder());
    final session = await SpatialExplorationSession.load(outside.copyWith(map: outside.map.copyWith(warps: [ladder])), spatialArrival: PlayerSpatialPosition(x: 3.4375, z: 4.5), loadMap: (_) async => throw StateError('load-failed'));
    addTearDown(session.dispose);
    await complete(session, session.enterWarp(ladder));
    expect(session.bundle.map.id, 'outside'); expect(session.movement.x, 3.4375); expect(session.movement.z, 4.5);
    expect(session.nativeDoorBlackout.value, 0); expect(session.nativeDoorTraversalActive, isFalse);
    expect(session.movement.paused, isFalse); expect(session.interactionError.value, isA<StateError>());
  });

  test('ladder without fade cancels safely during destination loading', () async {
    final ladder = entrance.copyWith(door: null, ladder: MapWarpLadder(), transition: const MapWarpTransition(type: MapWarpTransitionType.none));
    final pending = Completer<RuntimeMapBundle>();
    final session = await SpatialExplorationSession.load(outside.copyWith(map: outside.map.copyWith(warps: [ladder])), spatialArrival: PlayerSpatialPosition(x: 3.4375, z: 4.5), loadMap: (_) => pending.future);
    addTearDown(session.dispose);
    final operation = session.enterWarp(ladder); await flush();
    expect(session.nativeDoorTraversalActive, isTrue);
    session.cancelPendingTransition(); pending.complete(inside); await operation;
    expect(session.bundle.map.id, 'outside'); expect(session.movement.x, 3.4375);
    expect(session.movement.paused, isFalse); expect(session.transitioning.value, isFalse);
    expect(session.interactionError.value, isNull);
  });

  RuntimeMapBundle sourceWithBudget(RuntimeResourceBudget budget) =>
      RuntimeMapBundle(
        resourceBudget: budget,
        manifest: outside.manifest,
        map: outside.map,
        projectRootDirectory: outside.projectRootDirectory,
        tilesetAbsolutePathsById: outside.tilesetAbsolutePathsById,
        characterAnimationAbsolutePathsByAssetId:
            outside.characterAnimationAbsolutePathsByAssetId,
      );

  RuntimeMapBundle destinationWithUniqueImage(RuntimeResourceBudget budget) {
    final hero = inside.manifest.characters.single;
    final actor = hero.copyWith(
      id: 'destination-npc',
      animations: [
        for (final animation in hero.animations)
          animation.copyWith(sourceAssetId: 'destination-image'),
      ],
    );
    return RuntimeMapBundle(
      resourceBudget: budget,
      projectRootDirectory: inside.projectRootDirectory,
      tilesetAbsolutePathsById: inside.tilesetAbsolutePathsById,
      manifest: inside.manifest.copyWith(
        characters: [...inside.manifest.characters, actor],
      ),
      map: inside.map.copyWith(
        entities: const [
          MapEntity(
            id: 'destination-npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(characterId: 'destination-npc'),
            blocksMovement: false,
          ),
        ],
      ),
      characterAnimationAbsolutePathsByAssetId: {
        ...inside.characterAnimationAbsolutePathsByAssetId,
        'destination-image': '${root.path}/destination.png',
      },
    );
  }

  Future<void> waitFor(bool Function() condition) async {
    for (var i = 0; i < 500 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(condition(), isTrue);
  }

  test('story projection preserves native door walking frames', () async {
    final runtime = await host();
    final session = runtime.session!;
    final initialZ = session.movement.z;
    final operation = session.enterWarp(session.bundle.map.warps.single);
    var walked = false;
    try {
      for (var i = 0; i < 120 && !walked; i++) {
        final frames = session.frames(1 / 120);
        await Future<void>.delayed(const Duration(milliseconds: 1));
        final hero = frames['hero'];
        if (session.nativeDoorTraversalActive && hero != null &&
            session.movement.z != initialZ) {
          walked = true;
          expect(hero.x, session.movement.x);
          expect(hero.z, session.movement.z);
        }
      }
      expect(walked, isTrue);
    } finally {
      session.cancelPendingTransition();
      await operation;
    }
  });

  for (final startX in [3.0, 3.8125]) {
    test(
      'fractional door approach at $startX aligns outside the walls',
      () async {
        final source = outside.copyWith(
          map: outside.map.copyWith(
            spatialScene: outside.map.spatialScene!.copyWith(
              navigation: outside.map.spatialScene!.navigation.copyWith(
                blockedAreas: [
                  SpatialBlockedArea(x: 0, z: 4, width: 3, depth: 1),
                  SpatialBlockedArea(x: 4, z: 4, width: 4, depth: 1),
                ],
              ),
            ),
          ),
        );
        final session = await SpatialExplorationSession.load(
          source,
          spatialArrival: PlayerSpatialPosition(x: startX, z: 5.5),
          loadMap: (_) async => inside,
          knownMaps: [source.map, inside.map],
        );
        addTearDown(session.dispose);
        expect(session.movement.isPositionTraversable, isTrue);
        session.movement.setInput(x: 0, z: -1);
        session.frames(1 / 60);
        await untilMap(session, 'inside');
        for (var tick = 0; tick < 500 && session.transitioning.value; tick++) {
          session.frames(1 / 60);
          await flush();
        }
        expect(session.interactionError.value, isNull);
        expect(session.transitioning.value, isFalse);
        expect(
          session.movement.spatialPosition,
          PlayerSpatialPosition(x: 3.5, z: 4.5),
        );
      },
    );
  }

  test(
    'cancelling fractional door alignment restores its precise source',
    () async {
      final session = await SpatialExplorationSession.load(
        outside,
        spatialArrival: PlayerSpatialPosition(x: 3, z: 5.5),
        loadMap: (_) async => inside,
        knownMaps: [outside.map, inside.map],
      );
      addTearDown(session.dispose);
      final operation = session.enterWarp(entrance);
      await flush();
      for (var tick = 0; tick < 18; tick++) session.frames(1 / 60);
      expect(session.movement.x, greaterThan(3));
      session.cancelPendingTransition();
      await operation;
      expect(session.bundle.map.id, 'outside');
      expect(
        session.movement.spatialPosition,
        PlayerSpatialPosition(x: 3, z: 5.5),
      );
      expect(session.nativeDoorTraversalActive, isFalse);
      expect(session.interactionError.value, isNull);
    },
  );

  test('native destination decoding starts after departure and stays covered until transfer', () async {
    final budget = RuntimeResourceBudget(
      profile: const RuntimeResourceProfile(maximumConcurrentDecodes: 1),
    );
    addTearDown(budget.dispose);
    await File('${root.path}/destination.png')
        .writeAsBytes(img.encodePng(img.Image(width: 32, height: 32)));
    final destination = destinationWithUniqueImage(budget);
    final session = await SpatialExplorationSession.load(
      sourceWithBudget(budget),
      loadMap: (_) async => destination,
      knownMaps: [outside.map, destination.map],
    );
    addTearDown(session.dispose);
    final baseline = budget.residentBytes;
    final blocker = await budget.acquire();
    addTearDown(blocker.release);
    final operation = session.enterWarp(entrance);
    await flush();
    expect(budget.pendingDecodes, 0);
    expect(session.bundle.map.id, 'outside');
    expect(session.mapRevision.value, 0);
    expect(session.nativeDoorBlackout.value, 0);
    session.frames(.1);
    expect(
      session.modelRuntimeState('outside', 'door')!.normalizedTime,
      allOf(greaterThan(0), lessThan(1)),
    );
    await untilCovered(session);
    await waitFor(() => budget.pendingDecodes == 1);
    blocker.release();
    await waitFor(
      () => budget.residentBytes > baseline && budget.activeDecodes == 0,
    );
    await flush();
    await File('${root.path}/destination.png').delete();
    expect(session.bundle.map.id, 'inside');
    expect(session.nativeDoorBlackout.value, 1);
    await complete(session, operation);
    expect(session.bundle.map.id, 'inside');
    expect(session.interactionError.value, isNull);
    expect(session.movement.facing, EntityFacing.north);
    expect(session.frames(0)['inside:npc:destination-npc'], isNotNull);
    session.dispose();
    expect(budget.residentBytes, 0);
  });

  for (final corrupt in [false, true]) {
    test(
      'cancelled native preparation releases late ${corrupt ? 'failure' : 'success'} without adoption',
      () async {
        final budget = RuntimeResourceBudget(
          profile: const RuntimeResourceProfile(maximumConcurrentDecodes: 1),
        );
        addTearDown(budget.dispose);
        await File('${root.path}/destination.png').writeAsBytes(
          corrupt
              ? [1, 2, 3, 4]
              : img.encodePng(img.Image(width: 32, height: 32)),
        );
        final destination = destinationWithUniqueImage(budget);
        final session = await SpatialExplorationSession.load(
          sourceWithBudget(budget),
          loadMap: (_) async => destination,
          knownMaps: [outside.map, destination.map],
        );
        addTearDown(session.dispose);
        final baseline = budget.residentBytes;
        final original = session.movement.spatialPosition;
        final blocker = await budget.acquire();
        addTearDown(blocker.release);
        final operation = session.enterWarp(entrance);
        await untilCovered(session);
        await waitFor(() => budget.pendingDecodes == 1);
        session.frames(.1);
        session.cancelPendingTransition();
        await operation;
        expect(session.bundle.map.id, 'outside');
        expect(session.movement.spatialPosition, original);
        expect(session.movement.paused, isFalse);
        blocker.release();
        await waitFor(
          () => budget.pendingDecodes == 0 && budget.activeDecodes == 0,
        );
        await flush();
        expect(budget.residentBytes, baseline);
        expect(session.bundle.map.id, 'outside');
        expect(session.mapRevision.value, 0);
        expect(session.interactionError.value, isNull);
        expect(session.frames(0)['hero'], isNotNull);
        session.dispose();
        expect(budget.residentBytes, 0);
      },
    );
  }

  test(
    'native preparation failure restores source after covered loading',
    () async {
      final budget = RuntimeResourceBudget();
      addTearDown(budget.dispose);
      final destination = destinationWithUniqueImage(budget);
      final session = await SpatialExplorationSession.load(
        sourceWithBudget(budget),
        loadMap: (_) async => destination,
        knownMaps: [outside.map, destination.map],
      );
      addTearDown(session.dispose);
      final baseline = budget.residentBytes;
      var finished = false;
      final operation = session
          .enterWarp(entrance)
          .then((_) => finished = true);
      await complete(session, operation);
      expect(finished, isTrue);
      expect(session.bundle.map.id, 'outside');
      expect(session.mapRevision.value, 0);
      expect(session.nativeDoorBlackout.value, 0);
      expect(session.nativeDoorTraversalActive, isFalse);
      expect(session.movement.paused, isFalse);
      expect(session.interactionError.value, isA<FileSystemException>());
      expect(budget.residentBytes, baseline);
    },
  );

  test('native renderer prepares after covered departure and must finish before adoption', () async {
    final rendererReady = Completer<void>();
    final session = await SpatialExplorationSession.load(
      outside,
      loadMap: (_) async => inside,
      knownMaps: [outside.map, inside.map],
    );
    addTearDown(session.dispose);
    bool Function()? isCurrent;
    session.prepareNativeDoorDestination = (destination, current) {
      expect(destination.map.id, 'inside');
      isCurrent = current;
      return rendererReady.future;
    };
    final operation = session.enterWarp(entrance);
    await flush();
    expect(isCurrent, isNull);
    session.frames(.1);
    expect(session.modelRuntimeState('outside', 'door')!.normalizedTime,
        allOf(greaterThan(0), lessThan(1)));
    await untilCovered(session);
    expect(isCurrent, isNotNull);
    expect(isCurrent!(), isTrue);
    expect(session.bundle.map.id, 'outside');
    expect(session.mapRevision.value, 0);
    expect(session.nativeDoorBlackout.value, 1);
    rendererReady.complete();
    await complete(session, operation);
    expect(session.bundle.map.id, 'inside');
    expect(session.interactionError.value, isNull);
    expect(session.movement.paused, isFalse);
  });

  test('native destination paints fully covered after renderer admission before reveal', () async {
    final session = await SpatialExplorationSession.load(
      outside,
      loadMap: (_) async => inside,
      knownMaps: [outside.map, inside.map],
    );
    addTearDown(session.dispose);
    session.setVisibleMaps({'outside'});
    final sourcePaint = Completer<void>();
    final destinationPaint = Completer<void>();
    var paintRequests = 0;
    session.waitForNativeDoorBlackoutFrame = () {
      paintRequests++;
      return paintRequests == 1 ? sourcePaint.future : destinationPaint.future;
    };
    final operation = session.enterWarp(entrance);
    await flush();
    for (var i = 0; i < 120 && paintRequests == 0; i++) {
      session.frames(1 / 60);
      await flush();
    }
    expect(paintRequests, 1);
    expect(session.bundle.map.id, 'outside');
    expect(session.nativeDoorBlackout.value, 1);
    sourcePaint.complete();
    await untilMap(session, 'inside');
    expect(paintRequests, 1);
    session.setVisibleMaps({'inside'});
    await flush();
    expect(paintRequests, 2);
    session.frames(1);
    expect(session.nativeDoorBlackout.value, 1);
    expect(session.nativeDoorHeroVisible, isFalse);
    expect(session.nativeDoorTraversalActive, isTrue);
    expect(session.transitioning.value, isTrue);
    destinationPaint.complete();
    await flush();
    session.frames(1 / 60);
    expect(session.nativeDoorBlackout.value, 1);
    session.frames(1 / 60);
    expect(session.nativeDoorBlackout.value, lessThan(1));
    await complete(session, operation);
    expect(session.bundle.map.id, 'inside');
    expect(session.movement.paused, isFalse);
  });

  test('cancelling destination covered paint rolls back without awaiting its late frame', () async {
    final session = await SpatialExplorationSession.load(
      outside,
      loadMap: (_) async => inside,
      knownMaps: [outside.map, inside.map],
    );
    addTearDown(session.dispose);
    session.setVisibleMaps({'outside'});
    final original = session.movement.spatialPosition;
    final destinationPaint = Completer<void>();
    var paintRequests = 0;
    session.waitForNativeDoorBlackoutFrame = () {
      paintRequests++;
      return paintRequests == 1 ? Future.value() : destinationPaint.future;
    };
    var finished = false;
    final operation = session.enterWarp(entrance).then((_) => finished = true);
    await untilMap(session, 'inside');
    session.setVisibleMaps({'inside'});
    await flush();
    expect(paintRequests, 2);
    session.cancelPendingTransition();
    await flush();
    expect(finished, isTrue);
    await operation;
    expect(session.bundle.map.id, 'outside');
    expect(session.movement.spatialPosition, original);
    expect(session.nativeDoorBlackout.value, 0);
    expect(session.movement.paused, isFalse);
    destinationPaint.complete();
    await flush();
    expect(session.bundle.map.id, 'outside');
    expect(session.nativeDoorTraversalActive, isFalse);
  });

  test('native arrival excludes pre-adoption hitch from its first visible clock', () async {
    final portal = exit.copyWith(
      transition: const MapWarpTransition(type: MapWarpTransitionType.hgss),
    );
    final source = inside.copyWith(map: inside.map.copyWith(warps: [portal]));
    final session = await SpatialExplorationSession.load(
      source,
      loadMap: (_) async => outside,
      knownMaps: [source.map, outside.map],
    );
    addTearDown(session.dispose);
    session.setVisibleMaps({'inside'});
    final operation = session.enterWarp(portal);
    await untilMap(session, 'outside');
    session.setVisibleMaps({'outside'});
    await flush();
    session.frames(.108);
    expect(session.bundle.map.id, 'outside');
    expect(session.nativeDoorTraversalActive, isTrue);
    expect(session.nativeDoorBlackout.value, 1);
    expect(session.nativeDoorHeroVisible, isFalse);
    expect(session.movement.x, 3.5);
    expect(session.movement.z, 4.5);
    expect(session.modelRuntimeState('outside', 'door')!.normalizedTime, 0);
    expect(session.nativeCameraMagnification, closeTo(1.0706217739069082, 1e-12));
    session.frames(1 / 120);
    expect(session.nativeDoorBlackout.value, closeTo(23 / 24, 1e-9));
    expect(session.modelRuntimeState('outside', 'door')!.normalizedTime,
        closeTo(1 / 28, 1e-9));
    expect(session.nativeCameraMagnification,
        allOf(greaterThan(1), lessThan(1.0706217739069082)));
    expect(session.movement.z, 4.5);
    await complete(session, operation);
    expect(session.movement.z, 5.5);
    expect(session.movement.paused, isFalse);
  });

  for (final failLate in [false, true]) {
    test('cancelled native renderer ${failLate ? 'failure' : 'success'} releases candidate assets', () async {
      final budget = RuntimeResourceBudget();
      addTearDown(budget.dispose);
      await File('${root.path}/destination.png').writeAsBytes(
        img.encodePng(img.Image(width: 32, height: 32)));
      final destination = destinationWithUniqueImage(budget);
      final session = await SpatialExplorationSession.load(
        sourceWithBudget(budget),
        loadMap: (_) async => destination,
        knownMaps: [outside.map, destination.map],
      );
      addTearDown(session.dispose);
      final baseline = budget.residentBytes;
      final original = session.movement.spatialPosition;
      final rendererReady = Completer<void>();
      bool Function()? isCurrent;
      session.prepareNativeDoorDestination = (_, current) {
        isCurrent = current;
        return rendererReady.future;
      };
      final operation = session.enterWarp(entrance);
      await untilCovered(session);
      await waitFor(() => budget.residentBytes > baseline && budget.activeDecodes == 0);
      expect(isCurrent!(), isTrue);
      session.frames(.1);
      session.cancelPendingTransition();
      await operation;
      expect(isCurrent!(), isFalse);
      expect(session.bundle.map.id, 'outside');
      expect(session.movement.spatialPosition, original);
      expect(session.movement.paused, isFalse);
      if (failLate) {
        rendererReady.completeError(StateError('late renderer failure'));
      } else {
        rendererReady.complete();
      }
      await flush();
      expect(budget.residentBytes, baseline);
      expect(session.mapRevision.value, 0);
      expect(session.interactionError.value, isNull);
      expect(session.frames(0)['hero'], isNotNull);
    });
  }

  test('native renderer failure after blackout never adopts its prepared candidate', () async {
    final rendererReady = Completer<void>();
    final session = await SpatialExplorationSession.load(
      outside,
      loadMap: (_) async => inside,
      knownMaps: [outside.map, inside.map],
    );
    addTearDown(session.dispose);
    session.prepareNativeDoorDestination = (_, _) => rendererReady.future;
    final operation = session.enterWarp(entrance);
    await flush();
    for (var i = 0; i < 120; i++) {
      session.frames(1 / 60);
      await flush();
    }
    expect(session.nativeDoorBlackout.value, 1);
    expect(session.bundle.map.id, 'outside');
    final failure = StateError('renderer preparation failed after blackout');
    rendererReady.completeError(failure);
    await operation;
    expect(session.interactionError.value, same(failure));
    expect(session.bundle.map.id, 'outside');
    expect(session.mapRevision.value, 0);
    expect(session.nativeDoorBlackout.value, 0);
    expect(session.movement.paused, isFalse);
  });

  test('native renderer failure during covered decoding restores the source', () async {
    final budget = RuntimeResourceBudget(
      profile: const RuntimeResourceProfile(maximumConcurrentDecodes: 1),
    );
    addTearDown(budget.dispose);
    await File('${root.path}/destination.png').writeAsBytes(
      img.encodePng(img.Image(width: 32, height: 32)));
    final destination = destinationWithUniqueImage(budget);
    final session = await SpatialExplorationSession.load(
      sourceWithBudget(budget),
      loadMap: (_) async => destination,
      knownMaps: [outside.map, destination.map],
    );
    addTearDown(session.dispose);
    final baseline = budget.residentBytes;
    final blocker = await budget.acquire();
    addTearDown(blocker.release);
    final rendererReady = Completer<void>();
    final failure = StateError('destination GPU preparation failed');
    session.prepareNativeDoorDestination = (_, _) => rendererReady.future;
    var finished = false;
    final operation = session.enterWarp(entrance).then((_) => finished = true);
    await untilCovered(session);
    await waitFor(() => budget.pendingDecodes == 1);
    rendererReady.completeError(failure);
    await waitFor(() => finished);
    await operation;
    expect(session.interactionError.value, same(failure));
    expect(session.bundle.map.id, 'outside');
    expect(session.mapRevision.value, 0);
    expect(session.nativeDoorBlackout.value, 0);
    expect(session.nativeDoorTraversalActive, isFalse);
    expect(session.movement.paused, isFalse);
    blocker.release();
    await waitFor(() => budget.pendingDecodes == 0 && budget.activeDecodes == 0);
    await flush();
    expect(budget.residentBytes, baseline);
    expect(session.interactionError.value, same(failure));
  });

  test('ordinary unanimated passage never requests native renderer preparation', () async {
    final portal = entrance.copyWith(
      door: null,
      transition: const MapWarpTransition(type: MapWarpTransitionType.none),
    );
    final source = outside.copyWith(map: outside.map.copyWith(warps: [portal]));
    final session = await SpatialExplorationSession.load(
      source,
      loadMap: (_) async => inside,
      knownMaps: [source.map, inside.map],
    );
    addTearDown(session.dispose);
    var calls = 0;
    session.prepareNativeDoorDestination = (_, _) async => calls++;
    await session.enterWarp(portal);
    expect(calls, 0);
    expect(session.bundle.map.id, 'inside');
    expect(session.interactionError.value, isNull);
  });

  test('HGSS door camera freezes its source anchor and never leaks it into the interior', () async {
    final portal = entrance.copyWith(transition: const MapWarpTransition(type: MapWarpTransitionType.hgss), targetPos: const GridPos(x: 1, y: 2));
    final source = outside.copyWith(map: outside.map.copyWith(warps: [portal]));
    final session = await SpatialExplorationSession.load(source,
      loadMap: (_) async => inside, knownMaps: [source.map, inside.map]);
    addTearDown(session.dispose);
    session.setVisibleMaps({'outside'});
    final start = (x: session.movement.x, z: session.movement.z);
    final operation = session.enterWarp(portal);
    await flush();
    session.frames(.1);
    expect(session.nativeCameraAnchor, start);
    expect(session.nativeCameraMagnification, greaterThan(1));
    await untilMap(session, 'inside');
    expect(session.nativeCameraAnchor, isNull);
    expect(session.nativeCameraMagnification, 1);
    expect(session.movement.x, 1.5);
    session.setVisibleMaps({'inside'});
    await complete(session, operation);
    expect(session.nativeCameraMagnification, 1);
    expect(session.nativeCameraAnchor, isNull);
    expect(session.interactionError.value, isNull);
  });

  for (final type in MapWarpTransitionType.values) {
    test('plain spatial passage consumes selected $type and waits for renderer', () async {
      final transition = MapWarpTransition(type: type, durationSeconds: .6);
      final portal = entrance.copyWith(door: null, transition: transition);
      final source = outside.copyWith(map: outside.map.copyWith(warps: [portal]));
      final session = await SpatialExplorationSession.load(source,
        loadMap: (_) async => inside, knownMaps: [source.map, inside.map]);
      addTearDown(session.dispose);
      session.setVisibleMaps({'outside'});
      final operation = session.enterWarp(portal);
      await flush();
      expect(session.nativeScreenTransition, transition);
      if (type != MapWarpTransitionType.none) {
        session.frames(.1);
        expect(session.bundle.map.id, 'outside');
        expect(session.nativeDoorBlackout.value, closeTo(1 / 6, 1e-8));
        expect(session.nativeDoorHeroVisible, isTrue);
      }
      await untilMap(session, 'inside');
      if (type == MapWarpTransitionType.none) {
        await operation;
        expect(session.transitioning.value, isFalse);
        expect(session.nativeDoorBlackout.value, 0);
        expect(session.movement.paused, isFalse);
        return;
      }
      expect(session.transitioning.value, isTrue);
      expect(session.nativeDoorBlackout.value, 1);
      session.setVisibleMaps({'inside'});
      await flush();
      if (type != MapWarpTransitionType.none) {
        session.frames(1 / 120);
        expect(session.nativeDoorBlackout.value, 1);
        session.frames(.1);
        expect(session.nativeScreenRevealing, isTrue);
        expect(session.nativeDoorBlackout.value, closeTo(5 / 6, 1e-8));
      }
      await complete(session, operation);
      expect(session.interactionError.value, isNull);
      expect(session.movement.paused, isFalse);
      expect(session.nativeDoorBlackout.value, 0);
    });
  }

  test(
    'native door approach opens before the player enters its threshold',
    () async {
      final session = await SpatialExplorationSession.load(
        outside,
        loadMap: (_) async => inside,
        knownMaps: [outside.map, inside.map],
      );
      addTearDown(session.dispose);
      session.movement.setInput(x: 0, z: -1);
      session.frames(1 / 60);
      await flush();
      expect(session.nativeDoorTraversalActive, isTrue);
      expect(
        session.movement.spatialPosition,
        PlayerSpatialPosition(x: 3.5, z: 5.5),
      );
      expect(session.modelRuntimeState('outside', 'door')!.animationIndex, 0);
      session.cancelPendingTransition();
    },
  );

  test(
    'the first native door approach carries its direction into the destination',
    () async {
      final session = await SpatialExplorationSession.load(
        outside,
        loadMap: (_) async => inside,
        knownMaps: [outside.map, inside.map],
      );
      addTearDown(session.dispose);
      expect(session.movement.facing, EntityFacing.south);
      session.movement.setInput(x: 0, z: -1);
      session.frames(1 / 60);
      await untilMap(session, 'inside');
      for (var i = 0; i < 500 && session.nativeDoorTraversalActive; i++) {
        session.frames(1 / 60);
        await flush();
      }
      expect(session.nativeDoorTraversalActive, isFalse);
      expect(session.movement.facing, EntityFacing.north);
    },
  );

  test('native arrival hides the hero until its opening finishes', () async {
    final session = await SpatialExplorationSession.load(
      inside,
      loadMap: (_) async => outside,
      knownMaps: [inside.map, outside.map],
    );
    addTearDown(session.dispose);
    session.setVisibleMaps({'inside'});
    final operation = session.enterWarp(exit);
    await untilMap(session, 'outside');
    expect(session.nativeDoorHeroVisible, isFalse);
    expect(session.frames(0), isNot(contains('hero')));
    session.setVisibleMaps({'outside'});
    await flush();
    session.frames(.1);
    expect(session.nativeDoorHeroVisible, isFalse);
    expect(session.movement.z, 4.5);
    session.cancelPendingTransition();
    await operation;
  });

  test(
    'native black cover holds while the arrival renderer is pending',
    () async {
      final session = await SpatialExplorationSession.load(
        inside,
        loadMap: (_) async => outside,
        knownMaps: [inside.map, outside.map],
      );
      addTearDown(session.dispose);
      session.setVisibleMaps({'inside'});
      final operation = session.enterWarp(exit);
      await untilMap(session, 'outside');
      expect(session.nativeDoorBlackout.value, 1);
      session.frames(.8);
      expect(session.nativeDoorBlackout.value, 1);
      expect(session.nativeDoorHeroVisible, isFalse);
      expect(session.modelRuntimeState('outside', 'door')!.normalizedTime, 0);
      session.setVisibleMaps({'outside'});
      await flush();
      session.frames(.108);
      expect(session.nativeDoorBlackout.value, 1);
      session.frames(.1);
      expect(session.nativeDoorBlackout.value, closeTo(.5, 1e-6));
      session.cancelPendingTransition();
      await operation;
      expect(session.nativeDoorBlackout.value, 0);
      expect(session.nativeDoorHeroVisible, isTrue);
    },
  );

  test(
    'the source stays committed until its fully black frame is painted',
    () async {
      final painted = Completer<void>();
      var requested = false;
      final session = await SpatialExplorationSession.load(
        outside,
        loadMap: (_) async => inside,
        knownMaps: [outside.map, inside.map],
      );
      addTearDown(session.dispose);
      session.waitForNativeDoorBlackoutFrame = () {
        requested = true;
        return painted.future;
      };
      final operation = session.enterWarp(entrance);
      for (var i = 0; i < 500 && !requested; i++) {
        session.frames(1 / 60);
        await flush();
      }
      expect(requested, isTrue);
      expect(session.nativeDoorBlackout.value, 1);
      expect(session.bundle.map.id, 'outside');
      expect(session.nativeDoorHeroVisible, isFalse);
      session.frames(.8);
      await flush();
      expect(session.bundle.map.id, 'outside');
      painted.complete();
      await complete(session, operation);
      expect(session.bundle.map.id, 'inside');
      expect(session.nativeDoorBlackout.value, 0);
    },
  );

  test(
    'cancelling a pending black frame finishes without a future frame',
    () async {
      final painted = Completer<void>();
      var requested = false;
      final session = await SpatialExplorationSession.load(
        outside,
        loadMap: (_) async => inside,
        knownMaps: [outside.map, inside.map],
      );
      addTearDown(session.dispose);
      session.waitForNativeDoorBlackoutFrame = () {
        requested = true;
        return painted.future;
      };
      var finished = false;
      final operation = session.enterWarp(entrance)
        ..then((_) => finished = true);
      try {
        for (var i = 0; i < 500 && !requested; i++) {
          session.frames(1 / 60);
          await flush();
        }
        expect(requested, isTrue);
        expect(session.nativeDoorBlackout.value, 1);
        session.cancelPendingTransition();
        await flush();
        expect(finished, isTrue);
        expect(session.bundle.map.id, 'outside');
        expect(
          session.movement.spatialPosition,
          PlayerSpatialPosition(x: 3.5, z: 5.5),
        );
        expect(session.nativeDoorBlackout.value, 0);
        expect(session.movement.paused, isFalse);
      } finally {
        painted.complete();
        await operation;
      }
    },
  );

  test(
    'source pose cannot overwrite a different interior during renderer wait',
    () async {
      final portal = entrance.copyWith(targetPos: const GridPos(x: 1, y: 2));
      final source = outside.copyWith(
        map: outside.map.copyWith(warps: [portal]),
      );
      final session = await SpatialExplorationSession.load(
        source,
        loadMap: (_) async => inside,
        knownMaps: [source.map, inside.map],
      );
      addTearDown(session.dispose);
      session.setVisibleMaps({'outside'});
      final operation = session.enterWarp(portal);
      try {
        await untilMap(session, 'inside');
        final target = PlayerSpatialPosition(x: 1.5, z: 2.5);
        expect(session.movement.spatialPosition, target);
        expect(session.nativeDoorBlackout.value, 1);
        session.frames(1 / 60);
        expect(session.interactionError.value, isNull);
        expect(session.bundle.map.id, 'inside');
        expect(session.movement.spatialPosition, target);
        session.setVisibleMaps({'inside'});
        await complete(session, operation);
        expect(session.movement.spatialPosition, target);
      } finally {
        session.cancelPendingTransition();
        await operation;
      }
    },
  );

  test(
    'large frame deltas keep the open and exit endpoints observable',
    () async {
      final session = await SpatialExplorationSession.load(
        inside,
        loadMap: (_) async => outside,
        knownMaps: [inside.map, outside.map],
      );
      addTearDown(session.dispose);
      session.setVisibleMaps({'inside'});
      final operation = session.enterWarp(exit);
      await untilMap(session, 'outside');
      session.setVisibleMaps({'outside'});
      await flush();
      session.frames(.108);
      expect(session.modelRuntimeState('outside', 'door')!.normalizedTime, 0);
      session.frames(.333);
      expect(session.movement.z, 4.5);
      expect(session.nativeDoorHeroVisible, isFalse);
      expect(
        session.modelRuntimeState('outside', 'door')!.normalizedTime,
        closeTo(.5, 1e-6),
      );
      session.frames(.8);
      expect(session.movement.z, 4.5);
      expect(session.nativeDoorHeroVisible, isTrue);
      final opened = session.modelRuntimeState('outside', 'door')!;
      expect(opened.animationIndex, 0);
      expect(opened.normalizedTime, 1);
      session.frames(.8);
      expect(session.movement.z, allOf(greaterThan(4.5), lessThan(5.5)));
      expect(session.modelRuntimeState('outside', 'door')!.animationIndex, 0);
      session.frames(.8);
      expect(session.movement.z, 5.5);
      final beforeClose = session.modelRuntimeState('outside', 'door')!;
      expect(beforeClose.animationIndex, 1);
      expect(beforeClose.normalizedTime, 0);
      expect(session.nativeDoorTraversalActive, isTrue);
      await complete(session, operation);
      expect(session.nativeDoorBlackout.value, 0);
      expect(session.nativeDoorTraversalActive, isFalse);
    },
  );

  test(
    'cancelling the native source step restores exact pose and clear cover',
    () async {
      final session = await SpatialExplorationSession.load(
        outside,
        loadMap: (_) async => inside,
        knownMaps: [outside.map, inside.map],
      );
      addTearDown(session.dispose);
      final original = session.movement.spatialPosition;
      final operation = session.enterWarp(entrance);
      await flush();
      for (var i = 0; i < 60 && session.movement.z == original.z; i++) {
        session.frames(1 / 60);
        await flush();
      }
      expect(session.bundle.map.id, 'outside');
      expect(session.movement.z, allOf(greaterThan(4.5), lessThan(5.5)));
      session.cancelPendingTransition();
      await operation;
      expect(session.movement.spatialPosition, original);
      expect(session.nativeDoorBlackout.value, 0);
      expect(session.nativeDoorHeroVisible, isTrue);
      expect(session.modelRuntimeState('outside', 'door'), isNull);
      expect(session.movement.paused, isFalse);
    },
  );

  test(
    'native source door opens visibly under its own lock before transferring',
    () async {
      final session = await SpatialExplorationSession.load(
        outside,
        loadMap: (_) async => inside,
        knownMaps: [outside.map, inside.map],
      );
      addTearDown(session.dispose);
      final operation = session.enterWarp(entrance);
      await flush();
      expect(session.transitioning.value, isTrue);
      session.frames(.1);
      expect(session.bundle.map.id, 'outside');
      expect(
        session.modelRuntimeState('outside', 'door')!.normalizedTime,
        closeTo(3 / 7, 1e-9),
      );
      expect(session.storyActive.value, isFalse);
      expect(outside.manifest.scenes, isEmpty);
      expect(outside.manifest.cinematics, isEmpty);
      await complete(session, operation);
      expect(session.bundle.map.id, 'inside');
      expect(
        session.movement.spatialPosition,
        PlayerSpatialPosition(x: 3.5, z: 4.5),
      );
      expect(session.transitioning.value, isFalse);
    },
  );

  test(
    'native arrival opens then takes a physical south step and closes',
    () async {
      final session = await SpatialExplorationSession.load(
        inside,
        loadMap: (_) async => outside,
        knownMaps: [outside.map, inside.map],
      );
      addTearDown(session.dispose);
      final operation = session.enterWarp(exit);
      await flush();
      await complete(session, operation);
      expect(session.bundle.map.id, 'outside');
      expect(
        session.movement.spatialPosition,
        PlayerSpatialPosition(x: 3.5, z: 5.5),
      );
      expect(session.movement.facing, EntityFacing.south);
      expect(session.modelRuntimeState('outside', 'door'), isNull);
      expect(session.movement.paused, isFalse);
      expect(session.storyActive.value, isFalse);
    },
  );

  test(
    'arrival is published before playback and waits for renderer readiness',
    () async {
      final session = await SpatialExplorationSession.load(
        inside,
        loadMap: (_) async => outside,
        knownMaps: [outside.map, inside.map],
      );
      addTearDown(session.dispose);
      session.setVisibleMaps({'inside'});
      final published = <String>[];
      session.mapRevision.addListener(
        () => published.add(session.bundle.map.id),
      );
      final operation = session.enterWarp(exit);
      await flush();
      await untilMap(session, 'outside');
      expect(published, ['outside']);
      expect(session.bundle.map.id, 'outside');
      session.frames(5);
      expect(session.modelRuntimeState('outside', 'door')!.normalizedTime, 0);
      expect(session.movement.z, 4.5);
      session.setVisibleMaps({'outside'});
      await flush();
      session.frames(1 / 120);
      expect(session.modelRuntimeState('outside', 'door')!.normalizedTime, 0);
      session.frames(.1);
      expect(
        session.modelRuntimeState('outside', 'door')!.normalizedTime,
        closeTo(3 / 7, 1e-9),
      );
      session.cancelPendingTransition();
      await operation;
      expect(session.bundle.map.id, 'inside');
      expect(published, ['outside', 'inside']);
      expect(session.frames(0)['hero'], isNotNull);
      expect(session.movement.paused, isFalse);
    },
  );

  test(
    'renderer failure compensates an adopted arrival and unblocks input',
    () async {
      final session = await SpatialExplorationSession.load(
        inside,
        loadMap: (_) async => outside,
        knownMaps: [outside.map, inside.map],
      );
      addTearDown(session.dispose);
      session.setVisibleMaps({'inside'});
      final operation = session.enterWarp(exit);
      await flush();
      await untilMap(session, 'outside');
      final failure = StateError('GPU model load failed');
      session.reportNativeDoorRenderFailure('outside', failure);
      await operation;
      expect(session.bundle.map.id, 'inside');
      expect(session.interactionError.value, same(failure));
      expect(session.nativeDoorTraversalActive, isFalse);
      expect(session.movement.paused, isFalse);
    },
  );

  test(
    'source-only image survives cache eviction and renderer rollback',
    () async {
      final image = img.Image(width: 32, height: 32)
        ..setPixelRgba(0, 0, 255, 0, 0, 255);
      final path = '${root.path}/source-only.png';
      await File(path).writeAsBytes(img.encodePng(image));
      final actor = ProjectCharacterEntry(
        id: 'source-only-character',
        name: 'Source NPC',
        tilesetId: 'unused',
        animations: [
          for (final facing in EntityFacing.values)
            CharacterAnimation(
              state: CharacterAnimationState.walk,
              direction: facing,
              sourceAssetId: 'source-only-image',
              frames: const [
                CharacterAnimationFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
                  durationMs: 100,
                ),
              ],
            ),
        ],
      );
      final manifest = inside.manifest.copyWith(
        characters: [...inside.manifest.characters, actor],
      );
      final source = inside.copyWith(
        manifest: manifest,
        map: inside.map.copyWith(
          entities: [
            const MapEntity(
              id: 'source-only',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 1, y: 1),
              npc: MapEntityNpcData(characterId: 'source-only-character'),
              blocksMovement: false,
            ),
          ],
        ),
        characterAnimationAbsolutePathsByAssetId: {
          ...inside.characterAnimationAbsolutePathsByAssetId,
          'source-only-image': path,
        },
      );
      final destination = outside.copyWith(manifest: manifest);
      final session = await SpatialExplorationSession.load(
        source,
        loadMap: (_) async => destination,
        knownMaps: [source.map, destination.map],
      );
      addTearDown(session.dispose);
      session.setVisibleMaps({'inside'});
      final original = session.frames(0)['inside:npc:source-only']!.texture;
      final operation = session.enterWarp(exit);
      await untilMap(session, 'outside');
      session.setVisibleMaps({'outside'});
      await flush();
      session.frames(.1);
      session.cancelPendingTransition();
      await operation;
      expect(session.bundle.map.id, 'inside');
      expect(
        session.frames(0)['inside:npc:source-only']!.texture,
        same(original),
      );
    },
  );

  test(
    'host user pause freezes native playback and lifecycle input lock cancels',
    () async {
      final runtime = await host();
      final session = runtime.session!;
      final operation = session.enterWarp(session.bundle.map.warps.single);
      await flush();
      session.frames(.1);
      final partial = session.modelRuntimeState('outside', 'door');
      await runtime.pause();
      session.frames(2);
      expect(session.modelRuntimeState('outside', 'door'), partial);
      expect(session.nativeDoorTraversalActive, isTrue);
      await expectLater(runtime.captureCheckpoint(), throwsStateError);
      await runtime.resume();
      session.frames(.05);
      expect(
        session.modelRuntimeState('outside', 'door')!.normalizedTime,
        greaterThan(partial!.normalizedTime),
      );
      await runtime.setInputLock(
        RuntimeExternalInputLock.lifecycle,
        locked: true,
      );
      await operation;
      expect(session.nativeDoorTraversalActive, isFalse);
      expect(session.modelRuntimeState('outside', 'door'), isNull);
      expect(runtime.gameStateSnapshot.spatialWorldState.modelsByMap, isEmpty);
      expect(runtime.inputAuthority.value.acceptsOverworldInput, isFalse);
      await runtime.setInputLock(
        RuntimeExternalInputLock.lifecycle,
        locked: false,
      );
      expect(runtime.inputAuthority.value.acceptsOverworldInput, isTrue);
    },
  );

  test(
    'a dynamic actor blocks arrival before the destination is committed',
    () async {
      final blocked = outside.copyWith(
        map: outside.map.copyWith(
          entities: const [
            MapEntity(
              id: 'blocker',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 3, y: 5),
              npc: MapEntityNpcData(characterId: 'hero'),
            ),
          ],
        ),
      );
      final session = await SpatialExplorationSession.load(
        inside,
        loadMap: (_) async => blocked,
        knownMaps: [inside.map, blocked.map],
      );
      addTearDown(session.dispose);
      final operation = session.enterWarp(exit);
      await complete(session, operation);
      expect(session.bundle.map.id, 'inside');
      expect(session.mapRevision.value, 0);
      expect(session.interactionError.value, isNotNull);
      expect(session.movement.paused, isFalse);
    },
  );

  test(
    'an actor entering the exit path compensates the adopted native arrival',
    () async {
      var present = false;
      final blocked = outside.copyWith(
        map: outside.map.copyWith(
          entities: const [
            MapEntity(
              id: 'blocker',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 3, y: 5),
              npc: MapEntityNpcData(characterId: 'hero'),
            ),
          ],
        ),
      );
      final session = await SpatialExplorationSession.load(
        inside,
        entityIsPresent: (_, _) => present,
        loadMap: (_) async => blocked,
        knownMaps: [inside.map, blocked.map],
      );
      addTearDown(session.dispose);
      final operation = session.enterWarp(exit);
      await untilMap(session, 'outside');
      present = true;
      await complete(session, operation);
      expect(session.bundle.map.id, 'inside');
      expect(session.mapRevision.value, 2);
      expect(session.modelRuntimeState('outside', 'door'), isNull);
      expect(session.interactionError.value, isNotNull);
      expect(session.movement.paused, isFalse);
    },
  );

  test(
    'host saves the stable source until native arrival has fully finished',
    () async {
      final runtime = await host();
      final session = runtime.session!;
      final sourcePosition = runtime.gameStateSnapshot.playerSpatialPosition;
      final operation = session.enterWarp(session.bundle.map.warps.single);
      await flush();
      session.frames(7 / 30);
      await flush();
      expect(session.nativeDoorTraversalActive, isTrue);
      expect(runtime.gameStateSnapshot.playerSpatialPosition, sourcePosition);
      await complete(session, operation);
      expect(session.nativeDoorTraversalActive, isFalse);
      expect(
        runtime.gameStateSnapshot.playerSpatialPosition,
        PlayerSpatialPosition(x: 3.5, z: 5.5),
      );
      expect(runtime.gameStateSnapshot.spatialWorldState.modelsByMap, isEmpty);
    },
  );

  test(
    'a blocking door is temporarily open for arrival and restored after exit',
    () async {
      final instance = outside.map.spatialScene!.instances.single.copyWith(
        blocksMovement: true,
      );
      final blockedDoor = outside.copyWith(
        map: outside.map.copyWith(
          spatialScene: outside.map.spatialScene!.copyWith(
            instances: [instance],
          ),
        ),
      );
      final world = const SpatialWorldState.empty();
      final session = await SpatialExplorationSession.load(
        inside,
        worldStateProvider: () => world,
        loadMap: (_) async => blockedDoor,
        knownMaps: [blockedDoor.map, inside.map],
      );
      addTearDown(session.dispose);
      final operation = session.enterWarp(exit);
      await complete(session, operation);
      expect(session.interactionError.value, isNull);
      expect(session.bundle.map.id, 'outside');
      expect(session.movement.z, 5.5);
      expect(session.movement.isPositionTraversable, isTrue);
      expect(session.modelRuntimeState('outside', 'door'), isNull);
      expect(world.modelsByMap, isEmpty);
    },
  );

  test('presentation pause freezes opening and lifecycle cancellation restores rest', () async {
    final session = await SpatialExplorationSession.load(
      outside,
      loadMap: (_) async => inside,
      knownMaps: [outside.map, inside.map],
    );
    addTearDown(session.dispose);
    final operation = session.enterWarp(entrance);
    await flush();
    session.frames(.1);
    final before = session.modelRuntimeState('outside', 'door');
    session.dialoguePaused = true;
    session.frames(2);
    expect(session.modelRuntimeState('outside', 'door'), before);
    session.dialoguePaused = false;
    session.setLifecyclePaused(true);
    await operation;
    expect(session.bundle.map.id, 'outside');
    expect(session.modelRuntimeState('outside', 'door'), isNull);
    session.setLifecyclePaused(false);
    expect(session.movement.paused, isFalse);
  });

  test(
    'blocked exit rolls back without exposing a half completed destination',
    () async {
      final blocked = outside.copyWith(
        map: outside.map.copyWith(
          layers: [
            CollisionLayer(
              id: 'wall',
              name: 'Wall',
              collisions: List<bool>.filled(64, false)..[5 * 8 + 3] = true,
            ),
          ],
        ),
      );
      final session = await SpatialExplorationSession.load(
        inside,
        loadMap: (_) async => blocked,
        knownMaps: [blocked.map, inside.map],
      );
      addTearDown(session.dispose);
      final original = session.movement;
      final operation = session.enterWarp(exit);
      await complete(session, operation);
      expect(session.bundle.map.id, 'inside');
      expect(session.movement, same(original));
      expect(session.mapRevision.value, 0);
      expect(session.interactionError.value, isNotNull);
      expect(session.transitioning.value, isFalse);
      expect(session.movement.paused, isFalse);
    },
  );

  test(
    'late destination load after cancel never changes maps or leaves a pose',
    () async {
      final pending = Completer<RuntimeMapBundle>();
      final session = await SpatialExplorationSession.load(
        outside,
        loadMap: (_) => pending.future,
        knownMaps: [outside.map, inside.map],
      );
      addTearDown(session.dispose);
      final operation = session.enterWarp(entrance);
      session.cancelPendingTransition();
      pending.complete(inside);
      await operation;
      expect(session.bundle.map.id, 'outside');
      expect(session.mapRevision.value, 0);
      expect(session.modelRuntimeState('outside', 'door'), isNull);
      expect(session.movement.paused, isFalse);
    },
  );
}
