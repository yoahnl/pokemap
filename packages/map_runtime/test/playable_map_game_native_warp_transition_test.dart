import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_sound_effect_playback_port.dart';
import 'package:map_runtime/src/presentation/flame/warp_transition_overlay_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'map transfer stops the original SE owner without any map music controller',
    () async {
      final effects = _OwnedEffects();
      final game = await _mount(
        const MapWarpTransition(type: MapWarpTransitionType.none),
        effects: effects,
        logicalInstances: true,
      );
      final sourceInstance = game.gameStateSnapshot.mapInstanceWorldState
          .instanceRef('source');
      expect(sourceInstance, isNotNull);
      expect(
        await game.debugExecuteSceneInteractiveCommand(
          SceneInteractiveCommand.playSoundEffect(
            mediaAssetId: 'effect',
            volume: .5,
          ),
        ),
        'completed',
      );
      final sourceOwner = effects.started.single;
      expect(effects.active, contains(sourceOwner));
      var finished = false;
      final warp = game
          .debugExecuteSceneInteractiveCommand(
            SceneInteractiveCommand.warp(
              destinationMapId: 'target',
              warpId: 'passage',
              transition: SceneWarpTransition.none,
            ),
          )
          .whenComplete(() => finished = true);
      await _until(game, () => finished);
      expect(await warp, 'completed');
      expect(game.gameStateSnapshot.currentMapId, 'target');
      expect(
        game.gameStateSnapshot.mapInstanceWorldState.instanceRef('target'),
        isNotNull,
      );
      expect(effects.stopped, contains(sourceOwner));
      expect(effects.active, isEmpty);
    },
  );

  test(
    'physical 2D passage with none transfers without a visual overlay',
    () async {
      final gate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });
      final game = await _mount(
        const MapWarpTransition(type: MapWarpTransitionType.none),
        gate: gate,
      );
      await _approach(game);
      expect(game.debugFlowPhaseName, 'mapTransition');
      expect(_overlay(game), isNull);
      expect(game.debugIsGameplayInputLocked, isTrue);
      gate.complete();
      await _until(
        game,
        () =>
            game.gameStateSnapshot.currentMapId == 'target' &&
            game.debugFlowPhaseName == 'overworld',
      );
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
      expect(game.debugIsGameplayInputLocked, isFalse);
    },
  );

  test(
    'scene fade does not borrow a physical passage transition with the same ID',
    () async {
      final game = await _mount(
        const MapWarpTransition(type: MapWarpTransitionType.none),
      );
      var finished = false;
      final operation = game
          .debugExecuteSceneInteractiveCommand(
            SceneInteractiveCommand.warp(
              destinationMapId: 'target',
              warpId: 'passage',
              transition: SceneWarpTransition.mapDefault,
            ),
          )
          .whenComplete(() => finished = true);
      await _until(game, () => game.debugFlowPhaseName == 'mapTransition');
      expect(_overlay(game), isNotNull);
      await _until(game, () => finished);
      expect(await operation, 'completed');
    },
  );

  test('failed physical HGSS arrival restores source and releases the transition lock', () async {
    final game = await _mount(
      const MapWarpTransition(type: MapWarpTransitionType.hgss),
      invalidArrival: true,
    );
    await _approach(game);
    await _until(game, () => game.debugFlowPhaseName == 'overworld');
    expect(game.gameStateSnapshot.currentMapId, 'source');
    expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
    expect(game.debugIsGameplayInputLocked, isFalse);
    expect(_overlay(game), isNull);
  });

  for (final type in [MapWarpTransitionType.fade, MapWarpTransitionType.hgss]) {
    test(
      'physical 2D passage consumes authored ${type.name} duration',
      () async {
        final game = await _mount(
          MapWarpTransition(type: type, durationSeconds: 1.2),
        );
        await _approach(game);
        expect(
          _overlay(game)!.transition,
          MapWarpTransition(type: type, durationSeconds: 1.2),
        );
        await _flush();
        game.update(.3);
        await _flush();
        expect(game.gameStateSnapshot.currentMapId, 'source');
        expect(game.debugIsGameplayInputLocked, isTrue);
        await _until(
          game,
          () => game.gameStateSnapshot.currentMapId == 'target',
        );
        expect(game.debugIsGameplayInputLocked, isTrue);
        game.update(.3);
        await _flush();
        expect(game.debugFlowPhaseName, 'mapTransition');
        await _until(game, () => game.debugFlowPhaseName == 'overworld');
        expect(_overlay(game), isNull);
        expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
      },
    );
  }
}

WarpTransitionOverlayComponent? _overlay(PlayableMapGame game) => game
    .camera
    .viewport
    .children
    .whereType<WarpTransitionOverlayComponent>()
    .firstOrNull;

Future<void> _flush() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _until(PlayableMapGame game, bool Function() condition) async {
  for (var i = 0; i < 500 && !condition(); i++) {
    game.update(.016);
    await _flush();
  }
  expect(condition(), isTrue);
}

Future<void> _approach(PlayableMapGame game) async {
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.press(RuntimeInputControl.right),
  );
  game.update(.016);
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.release(RuntimeInputControl.right),
  );
  await _until(game, () => game.debugFlowPhaseName == 'mapTransition');
}

Future<PlayableMapGame> _mount(
  MapWarpTransition transition, {
  Completer<void>? gate,
  bool invalidArrival = false,
  SceneOwnedSoundEffectPlaybackPort? effects,
  bool logicalInstances = false,
}) async {
  final maps = [
    for (final id in ['source', 'target'])
      MapData(
        id: id,
        name: id,
        size: const GridSize(width: 5, height: 5),
        layers: [
          TileLayer(id: 'base', name: 'Base', cells: List.filled(25, 0)),
        ],
        entities: [
          const MapEntity(
            id: 'spawn',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 1, y: 1),
            blocksMovement: false,
            spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
          ),
        ],
        mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
        warps: id == 'source'
            ? [
                MapWarp(
                  id: 'passage',
                  pos: const GridPos(x: 2, y: 1),
                  targetMapId: 'target',
                  targetPos: GridPos(x: 1, y: invalidArrival ? 6 : 1),
                  transition: transition,
                ),
              ]
            : [
                const MapWarp(
                  id: 'passage',
                  pos: GridPos(x: 1, y: 1),
                  targetMapId: 'target',
                  targetPos: GridPos(x: 1, y: 1),
                  triggerMode: MapWarpTriggerMode.sceneOnly,
                ),
              ],
      ),
  ];
  final project = ProjectManifest(
    name: 'Native transitions',
    settings: ProjectSettings(
      mapInstanceRetentionPolicy: logicalInstances
          ? MapInstanceRetentionPolicy(
              viewportWidthTiles: 20,
              viewportHeightTiles: 20,
              marginTiles: 0,
            )
          : null,
    ),
    cinematicMediaAssets: [
      CinematicMediaAsset(
        id: 'effect',
        label: 'Effect',
        kind: CinematicMediaAssetKind.sound,
        relativePath: 'effect.wav',
      ),
    ],
    maps: [
      for (final map in maps)
        ProjectMapEntry(
          id: map.id,
          name: map.name,
          relativePath: 'maps/${map.id}.json',
        ),
    ],
    tilesets: [],
  );
  RuntimeMapBundle bundle(String id) => RuntimeMapBundle(
    manifest: project,
    map: maps.firstWhere((map) => map.id == id),
    projectRootDirectory: '/tmp',
    tilesetAbsolutePathsById: const {},
  );
  final game = _LoadedGame(
    bundle: bundle('source'),
    projectFilePath: '/tmp/native-transitions/project.json',
    sceneSoundEffectPlaybackPort: effects,
    runtimeMapBundleLoader: ({required projectFilePath, required mapId}) async {
      if (mapId == 'target') await gate?.future;
      return bundle(mapId);
    },
    runtimeTilesetImageLoader: (
      _, {
      transparentColorByTilesetId = const {},
    }) async => const {},
  );
  addTearDown(game.onRemove);
  game.onGameResize(Vector2(640, 480));
  await game.onLoad();
  await _until(game, () => !game.debugIsMapActivationDispatchInFlight);
  return game;
}

final class _LoadedGame extends PlayableMapGame {
  _LoadedGame({
    required super.bundle,
    required super.projectFilePath,
    required super.runtimeMapBundleLoader,
    required super.runtimeTilesetImageLoader,
    super.sceneSoundEffectPlaybackPort,
  });
  @override
  bool get isLoaded => true;
}

final class _OwnedEffects implements SceneOwnedSoundEffectPlaybackPort {
  final started = <Object>[];
  final stopped = <Object>[];
  final active = <Object>{};
  @override
  Future<void> playOwnedSoundEffect(
    String mediaAssetId, {
    required double volume,
    required String playbackId,
    required Object owner,
    Object? sceneOwner,
  }) async {
    started.add(owner);
    active.add(owner);
  }

  @override
  Future<void> stopOwnedSoundEffects(Object owner) async {
    stopped.add(owner);
    active.remove(owner);
  }

  @override
  Future<void> playSoundEffect(
    String mediaAssetId, {
    required double volume,
    required String playbackId,
  }) async {
    throw StateError('Expected the owned sound playback path.');
  }
}
