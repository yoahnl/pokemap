import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'one spatial session keeps the map BGM across three real warps',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      await fixture.runtime.load((_) {});
      await _settle();
      expect(fixture.driver.paths, [fixture.path('town.ogg')]);
      expect(fixture.driver.volumes.single, .64);
      for (final id in ['hall', 'town', 'room']) {
        final session = fixture.runtime.session!;
        await session.enterWarp(
          session.bundle.map.warps.singleWhere(
            (warp) => warp.targetMapId == id,
          ),
        );
        await _settle();
        expect(session.bundle.map.id, id);
        expect(fixture.driver.paths, [fixture.path('town.ogg')]);
        expect(fixture.driver.stopped, isEmpty);
      }
      await fixture.runtime.dispose();
      expect(fixture.driver.stopped, hasLength(1));
      expect(fixture.driver.active, isEmpty);
    },
  );
  test('spatial menu and dialogue pause keep music while lifecycle pauses the same handle', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    await fixture.runtime.load((_) {});
    await _settle();
    final handle = fixture.driver.active.single;
    await fixture.runtime.pause();
    fixture.runtime.session!.dialoguePaused = true;
    await _settle();
    expect(fixture.driver.paused, isEmpty);
    await fixture.runtime.resume();
    fixture.runtime.session!.setLifecyclePaused(true);
    await _settle();
    expect(fixture.driver.paused, [handle]);
    await fixture.runtime.setInputLock(
      RuntimeExternalInputLock.lifecycle,
      locked: true,
    );
    fixture.runtime.session!.setLifecyclePaused(false);
    await _settle();
    expect(fixture.driver.resumed, isEmpty);
    await fixture.runtime.setInputLock(
      RuntimeExternalInputLock.lifecycle,
      locked: false,
    );
    await _settle();
    expect(fixture.driver.resumed, [handle]);
    expect(fixture.driver.paths, hasLength(1));
  });

  test('standalone preferences multiply master music and source gain without restarting', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    fixture.runtime.applyPlayerPreferences(
      const PlayerPreferencesSnapshot(
        locale: 'fr',
        accessibility: GameSessionAccessibilityOptions(),
        audioMix: RuntimeAudioMix(
          masterVolume: .5,
          musicVolume: .25,
          effectsVolume: 0,
        ),
      ),
    );
    await fixture.runtime.load((_) {});
    await _settle();
    expect(fixture.driver.volumes.first, closeTo(.08, .000001));
    fixture.runtime.applyPlayerPreferences(
      const PlayerPreferencesSnapshot(
        locale: 'fr',
        accessibility: GameSessionAccessibilityOptions(),
        audioMix: RuntimeAudioMix(
          masterVolume: .8,
          musicVolume: .75,
          effectsVolume: 0,
        ),
      ),
    );
    await _settle();
    expect(fixture.driver.volumes.last, closeTo(.384, .000001));
    expect(fixture.driver.paths, hasLength(1));
  });

  test('host mixer is reused and remains owned by its host', () async {
    final mixer = RuntimeAudioMixer(
      mix: const RuntimeAudioMix(masterVolume: .5, musicVolume: .5),
    );
    final fixture = await _Fixture.create(mixer: mixer);
    addTearDown(fixture.dispose);
    fixture.runtime.applyPlayerPreferences(
      const PlayerPreferencesSnapshot(
        locale: 'fr',
        accessibility: GameSessionAccessibilityOptions(),
      ),
    );
    await fixture.runtime.load((_) {});
    await _settle();
    expect(fixture.driver.volumes.first, .16);
    await mixer.transitionTo(const RuntimeAudioMix(musicVolume: .5));
    expect(fixture.driver.volumes.last, .32);
    expect(fixture.driver.paths, hasLength(1));
    await fixture.runtime.dispose();
    await mixer.transitionTo(const RuntimeAudioMix(musicVolume: .25));
    expect(mixer.mix.musicVolume, .25);
  });

  test(
    'map changes select new music and a silent destination stops it',
    () async {
      final fixture = await _Fixture.create(
        paths: ['town.ogg', 'hall.ogg', null],
      );
      addTearDown(fixture.dispose);
      await fixture.runtime.load((_) {});
      await _settle();
      expect(fixture.driver.paths, [fixture.path('town.ogg')]);
      await fixture.next();
      expect(fixture.driver.paths, [
        fixture.path('town.ogg'),
        fixture.path('hall.ogg'),
      ]);
      expect(fixture.driver.stopped, hasLength(1));
      await fixture.next();
      expect(fixture.driver.active, isEmpty);
      expect(fixture.driver.stopped, hasLength(2));
    },
  );

  test(
    'same map path applies a new authored gain without restarting',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      await fixture.runtime.load((_) {});
      await _settle();
      final file = File('${fixture.root.path}/maps/hall.json');
      final map = MapData.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
      await file.writeAsString(
        jsonEncode(
          map
              .copyWith(mapMetadata: map.mapMetadata.copyWith(musicVolume: .25))
              .toJson(),
        ),
      );
      await fixture.next();
      expect(fixture.driver.paths, hasLength(1));
      expect(fixture.driver.volumes.last, .25);
    },
  );

  test(
    'absent map music is silent and audio failure never blocks map loading',
    () async {
      final silent = await _Fixture.create(paths: [null, null, null]);
      addTearDown(silent.dispose);
      await silent.runtime.load((_) {});
      await silent.next();
      expect(silent.driver.paths, isEmpty);
      final failure = await _Fixture.create(driver: _Driver()..fail = true);
      addTearDown(failure.dispose);
      await failure.runtime.load((_) {});
      await _settle();
      expect(failure.service.lastFailure, isA<FileSystemException>());
      await failure.next();
      expect(failure.runtime.session!.bundle.map.id, 'hall');
      expect(failure.driver.active, isEmpty);
    },
  );

  test('a destination load failure preserves the current BGM', () async {
    final fixture = await _Fixture.create(
      paths: ['town.ogg', 'hall.ogg', 'town.ogg'],
    );
    addTearDown(fixture.dispose);
    await fixture.runtime.load((_) {});
    await _settle();
    await File('${fixture.root.path}/maps/hall.json').delete();
    await fixture.next();
    expect(fixture.runtime.session!.bundle.map.id, 'room');
    expect(fixture.runtime.session!.interactionError.value, isNotNull);
    expect(fixture.driver.paths, [fixture.path('town.ogg')]);
    expect(fixture.driver.stopped, isEmpty);
  });

  for (final dispose in [false, true]) {
    test(
      'late audio start is invalidated on ${dispose ? "dispose" : "stop"}',
      () async {
        final driver = _Driver()..deferredPlay = Completer<void>();
        final fixture = await _Fixture.create(driver: driver);
        addTearDown(fixture.dispose);
        await fixture.runtime.load((_) {});
        await _settle();
        final stopping = dispose
            ? fixture.runtime.dispose()
            : fixture.runtime.stop(GameSessionExitReason.hub);
        await _settle();
        driver.deferredPlay!.complete();
        await stopping;
        await _settle();
        expect(driver.active, isEmpty);
        expect(driver.stopped, hasLength(1));
      },
    );
  }

  test('lifecycle audio backend errors remain nonfatal', () async {
    final driver = _Driver()..failPause = true;
    final fixture = await _Fixture.create(driver: driver);
    addTearDown(fixture.dispose);
    await fixture.runtime.load((_) {});
    await _settle();
    fixture.runtime.session!.setLifecyclePaused(true);
    await _settle();
    expect(fixture.service.lastFailure, isA<StateError>());
    expect(fixture.runtime.session!.bundle.map.id, 'room');
  });

  test(
    'new session restores the saved map BGM rather than the first map',
    () async {
      final fixture = await _Fixture.create(
        paths: ['town.ogg', 'hall.ogg', 'town.ogg'],
      );
      addTearDown(fixture.dispose);
      await fixture.runtime.load((_) {});
      await fixture.next();
      final checkpoint = (await fixture.runtime.captureCheckpoint())!;
      final state = gameStateFromStrictSaveJson(
        Map<String, dynamic>.from(checkpoint.state),
      );
      final restored = await _Fixture.create(
        paths: ['town.ogg', 'hall.ogg', 'town.ogg'],
        restoredState: state,
      );
      addTearDown(restored.dispose);
      await restored.runtime.load((_) {});
      await _settle();
      expect(restored.runtime.session!.bundle.map.id, 'hall');
      expect(restored.driver.paths, [restored.path('hall.ogg')]);
    },
  );
}

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

final class _Driver
    implements FlameCinematicAudioDriver, FlameCinematicAudioPausableDriver {
  final paths = <String>[];
  final volumes = <double>[];
  final stopped = <Object>[];
  final paused = <Object>[];
  final resumed = <Object>[];
  final active = <Object>{};
  Completer<void>? deferredPlay;
  bool fail = false;
  bool failPause = false;

  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    paths.add(path);
    volumes.add(volume);
    expect(loop, isTrue);
    if (fail) throw const FileSystemException('unreadable music');
    await deferredPlay?.future;
    final handle = Object();
    active.add(handle);
    return handle;
  }

  @override
  Future<void> setVolume(Object handle, double volume) async =>
      volumes.add(volume);
  @override
  Future<void> stop(Object handle) async {
    stopped.add(handle);
    active.remove(handle);
  }

  @override
  Future<void> pause(Object handle) async {
    if (failPause) throw StateError('audio pause failed');
    paused.add(handle);
  }

  @override
  Future<void> resume(Object handle) async => resumed.add(handle);
}

final class _Fixture {
  _Fixture(this.root, this.driver, this.service, this.runtime, this.bundle);
  final Directory root;
  final _Driver driver;
  final RuntimeMusicService service;
  final SpatialExplorationGameSessionRuntime runtime;
  final RuntimeMapBundle bundle;
  String path(String name) => '${root.path}/assets/music/$name';

  static Future<_Fixture> create({
    RuntimeAudioMixer? mixer,
    GameState? restoredState,
    List<String?> paths = const ['town.ogg', 'town.ogg', 'town.ogg'],
    _Driver? driver,
  }) async {
    final root = await Directory.systemTemp.createTemp('spatial-map-music-');
    await File('${root.path}/hero.png')
        .writeAsBytes(img.encodePng(img.Image(width: 32, height: 32)));
    final character = ProjectCharacterEntry(
      id: 'hero',
      name: 'Hero',
      tilesetId: 'hero',
      animations: [
        for (final direction in EntityFacing.values)
          CharacterAnimation(
            state: CharacterAnimationState.walk,
            direction: direction,
            frames: const [
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
                durationMs: 100,
              ),
            ],
          ),
      ],
    );
    const ids = ['room', 'hall', 'town'];
    final maps = [
      for (var i = 0; i < ids.length; i++)
        MapData(
          version: ProjectVersion.v9,
          id: ids[i],
          name: ids[i],
          size: const GridSize(width: 8, height: 8),
          mapMetadata: MapMetadata(
            musicPath: paths[i] == null ? null : 'assets/music/${paths[i]}',
            musicVolume: .64,
          ),
          warps: [
            MapWarp(
              id: 'next',
              pos: const GridPos(x: 5, y: 4),
              targetMapId: ids[(i + 1) % ids.length],
              targetPos: const GridPos(x: 2, y: 3),
              transition: const MapWarpTransition(
                type: MapWarpTransitionType.none,
              ),
            ),
          ],
          spatialScene: MapSpatialScene(
            width: 8,
            depth: 8,
            navigation: SpatialNavigationProfile(
              spawn: SpatialSpawn(x: 4, z: 4),
            ),
          ),
        ),
    ];
    final project = ProjectManifest(
      version: ProjectVersion.v9,
      name: 'Spatial music',
      settings: const ProjectSettings(
        dimension: ProjectDimension.threeD,
        defaultPlayerCharacterId: 'hero',
      ),
      newGame: const ProjectNewGameConfig(enabled: true, startMapId: 'room'),
      maps: [
        for (final map in maps)
          ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
      ],
      tilesets: const [
        ProjectTilesetEntry(id: 'hero', name: 'Hero', relativePath: 'hero.png'),
      ],
      characters: [character],
    );
    await Directory('${root.path}/maps').create();
    for (final map in maps) {
      await File('${root.path}/maps/${map.id}.json')
          .writeAsString(jsonEncode(map.toJson()));
    }
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    final bundle = RuntimeMapBundle(
      manifest: project,
      map: restoredState == null
          ? maps.first
          : maps.singleWhere((map) => map.id == restoredState.currentMapId),
      projectRootDirectory: root.path,
      tilesetAbsolutePathsById: {'hero': '${root.path}/hero.png'},
    );
    final audio = driver ?? _Driver();
    late RuntimeMusicService service;
    final runtime = SpatialExplorationGameSessionRuntime(
      descriptor: GameSessionDescriptor(
        sessionId: 'music',
        sessionToken: 'token',
        identity: GameIdentity(
          gameId: 'org.example.music',
          gameVersion: '1.0.0',
          projectFormat: ProjectFormat.v9,
          saveFormat: 1,
          compatibilityId: 'music',
        ),
        profileId: 'profile',
        slotId: 'slot',
        launchMode: restoredState == null
            ? GameSessionLaunchMode.newGame
            : GameSessionLaunchMode.continueGame,
        saveReadHandle: restoredState == null ? null : 'save',
        installedVersionHandle: 'installed',
        runtimeApiVersion: '1.4.0',
        grantedCapabilities: const {'map3d@1'},
        locale: 'fr',
        accessibility: const GameSessionAccessibilityOptions(),
        initialGameState: restoredState != null
            ? null
            : GameState(
                saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
                currentMapId: 'room',
                playerPosition: const GridPos(x: 4, y: 4),
                playerSpatialPosition: PlayerSpatialPosition(x: 4, z: 4),
              ),
      ),
      projectFilePath: () async => '${root.path}/project.json',
      initialSave: () async => restoredState == null
          ? null
          : const GameStateSaveEnvelopeMapper().create(
              identity: GameIdentity(
                gameId: 'org.example.music',
                gameVersion: '1.0.0',
                projectFormat: ProjectFormat.v9,
                saveFormat: 1,
                compatibilityId: 'music',
              ),
              profileId: 'profile',
              slotId: 'slot',
              saveId: restoredState.saveId,
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
              status: SaveStatus.active,
              playTimeSeconds: 1,
              gameState: restoredState,
            ),
      audioMixer: mixer,
      musicServiceFactory: (mixer) => service = RuntimeMusicService(
        driver: audio,
        mixer: mixer,
        fadeDelay: (_) async {},
      ),
      preloadedInitialMap: ({
        required projectFilePath,
        required descriptor,
        required initialSave,
      }) async => RuntimeInitialMapPreloadResult(bundle: bundle),
      mountSession: (_) async {},
      unmountSession: (_) async {},
    );
    return _Fixture(root, audio, service, runtime, bundle);
  }

  Future<void> next() async {
    final session = runtime.session!;
    await session.enterWarp(session.bundle.map.warps.single);
    await _settle();
  }

  Future<void> dispose() async {
    await runtime.dispose();
    await service.dispose();
    await root.delete(recursive: true);
  }
}
