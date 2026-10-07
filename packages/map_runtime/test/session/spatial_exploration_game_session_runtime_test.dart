import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late RuntimeMapBundle bundle;
  late SpatialExplorationGameSessionRuntime runtime;
  var mounts = 0;
  var unmounts = 0;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('spatial-session-');
    final image = img.Image(width: 32, height: 32);
    await File('${root.path}/hero.png').writeAsBytes(img.encodePng(image));
    final character = ProjectCharacterEntry(
      id: 'hero',
      name: 'Hero',
      tilesetId: 'unused',
      animations: [
        for (final direction in EntityFacing.values)
          CharacterAnimation(
              state: CharacterAnimationState.walk,
              direction: direction,
              sourceAssetId: 'hero-sheet',
              frames: const [
                CharacterAnimationFrame(
                    source:
                        TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
                    durationMs: 100),
              ]),
      ],
    );
    final map = MapData(
        version: ProjectVersion.v9,
        id: 'field',
        name: 'Field',
        size: const GridSize(width: 8, height: 8),
        layers: const [],
        spatialScene: MapSpatialScene(
            width: 8,
            depth: 8,
            navigation:
                SpatialNavigationProfile(spawn: SpatialSpawn(x: 4, z: 4))));
    bundle = RuntimeMapBundle(
        manifest: ProjectManifest(
            version: ProjectVersion.v9,
            name: 'Spatial',
            settings: const ProjectSettings(
                dimension: ProjectDimension.threeD,
                defaultPlayerCharacterId: 'hero'),
            maps: const [
              ProjectMapEntry(
                  id: 'field', name: 'Field', relativePath: 'maps/field.json')
            ],
            tilesets: const [],
            characters: [
              character
            ]),
        map: map,
        projectRootDirectory: root.path,
        tilesetAbsolutePathsById: const {},
        characterAnimationAbsolutePathsByAssetId: {
          'hero-sheet': '${root.path}/hero.png'
        });
    mounts = unmounts = 0;
    runtime = SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(),
        projectFilePath: () async => '${root.path}/project.json',
        preloadedInitialMap: (
                {required projectFilePath,
                required descriptor,
                required initialSave}) async =>
            RuntimeInitialMapPreloadResult(bundle: bundle),
        mountSession: (_) async => mounts++,
        unmountSession: (_) async => unmounts++);
  });

  tearDown(() async {
    await runtime.dispose();
    await root.delete(recursive: true);
  });

  test('routes digital inputs and sprint through authored spatial movement',
      () async {
    await runtime.load((_) {});
    expect(mounts, 1);
    final session = runtime.session!;
    expect(session.movement.x, 4);
    expect(session.movement.z, 4);
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.up));
    session.frame(.05);
    expect(session.movement.z, lessThan(4));
    runtime
        .handleInput(const RuntimeInputEvent.release(RuntimeInputControl.up));
    runtime
        .handleInput(const RuntimeInputEvent.press(RuntimeInputControl.right));
    runtime
        .handleInput(const RuntimeInputEvent.press(RuntimeInputControl.sprint));
    session.frame(.05);
    expect(session.movement.x, greaterThan(4));
    expect(session.movement.running, isTrue);
    runtime.handleInput(
        const RuntimeInputEvent.release(RuntimeInputControl.right));
    runtime.handleInput(
        const RuntimeInputEvent.release(RuntimeInputControl.sprint));
    session.frame(.05);
    expect(session.movement.moving, isFalse);
    expect(await runtime.captureCheckpoint(), isNull);
  });

  test('locks remain independent and resume requires fresh input', () async {
    await runtime.load((_) {});
    final session = runtime.session!;
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.up));
    await runtime.setInputLock(RuntimeExternalInputLock.pauseMenu,
        locked: true);
    await runtime.pause();
    await runtime.setInputLock(RuntimeExternalInputLock.lifecycle,
        locked: true);
    await runtime.resume();
    await runtime.setInputLock(RuntimeExternalInputLock.pauseMenu,
        locked: false);
    final before = session.movement.z;
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.up));
    session.frame(.05);
    expect(session.movement.z, before);
    expect(runtime.inputAuthority.value.externalLocks,
        {RuntimeExternalInputLock.lifecycle});
    await runtime.setInputLock(RuntimeExternalInputLock.lifecycle,
        locked: false);
    runtime.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.up, isRepeat: true));
    session.frame(.05);
    expect(session.movement.z, before);
    runtime.handleInput(const RuntimeInputEvent.press(RuntimeInputControl.up));
    session.frame(.05);
    expect(session.movement.z, lessThan(before));
    await runtime.stop(GameSessionExitReason.hub);
    final stopped = session.movement.z;
    runtime
        .handleInput(const RuntimeInputEvent.press(RuntimeInputControl.down));
    session.frame(.05);
    expect(session.movement.z, stopped);
    await runtime.dispose();
    await runtime.dispose();
    expect(unmounts, 1);
  });

  test('companion exposes only exploration menus and no save', () async {
    await runtime.load((_) {});
    final menu = await runtime.readCompanionMenuData();
    expect(menu.pauseDetails, isEmpty);
    expect(
        menu.pauseMenuState.isActionVisible(ProjectPauseActionId.save,
            projectDefaultVisibility: true),
        isFalse);
    expect(
        menu.pauseMenuState.isActionVisible(ProjectPauseActionId.options,
            projectDefaultVisibility: false),
        isTrue);
    expect(
        menu.pauseMenuState.isActionVisible(ProjectPauseActionId.party,
            projectDefaultVisibility: true),
        isFalse);
  });

  test('failed mount is unmounted once during disposal', () async {
    final failed = SpatialExplorationGameSessionRuntime(
      descriptor: descriptor(),
      projectFilePath: () async => '${root.path}/project.json',
      preloadedInitialMap: (
              {required projectFilePath,
              required descriptor,
              required initialSave}) async =>
          RuntimeInitialMapPreloadResult(bundle: bundle),
      mountSession: (_) async => throw StateError('GPU unavailable'),
      unmountSession: (_) async => unmounts++,
    );
    await expectLater(failed.load((_) {}), throwsStateError);
    await failed.dispose();
    await failed.dispose();
    expect(unmounts, 1);
    expect(failed.session, isNull);
  });

  test('rejects continue instead of restoring a 2D save', () async {
    final continued = SpatialExplorationGameSessionRuntime(
        descriptor: descriptor(continueGame: true),
        projectFilePath: () async => '${root.path}/project.json',
        mountSession: (_) async {},
        unmountSession: (_) async {});
    addTearDown(continued.dispose);
    await expectLater(continued.load((_) {}), throwsStateError);
    expect(continued.session, isNull);
  });
}

GameSessionDescriptor descriptor({bool continueGame = false}) =>
    GameSessionDescriptor(
        sessionId: 'session',
        sessionToken: 'token',
        identity: GameIdentity(
            gameId: 'org.example.spatial',
            gameVersion: '1.0.0',
            projectFormat: ProjectFormat.v9,
            saveFormat: 1,
            compatibilityId: 'spatial'),
        profileId: 'profile',
        slotId: 'slot',
        launchMode: continueGame
            ? GameSessionLaunchMode.continueGame
            : GameSessionLaunchMode.newGame,
        saveReadHandle: continueGame ? 'save' : null,
        installedVersionHandle: 'installed',
        runtimeApiVersion: '1.4.0',
        grantedCapabilities: const {'map3d@1'},
        locale: 'fr',
        accessibility: const GameSessionAccessibilityOptions());
