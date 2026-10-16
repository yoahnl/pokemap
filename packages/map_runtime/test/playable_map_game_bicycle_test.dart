import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/player_component.dart';

import 'playable_map_game_flash_test.dart' show MemorySave, tickUntil, warp;

const bike = ProjectItemDefinition(
  id: 'custom_cycle',
  displayName: 'Vélo',
  pocketId: 'key-items',
  tags: {'key-item'},
  uses: [
    ProjectItemUseDefinition(
      contexts: {ProjectItemUseContext.overworld},
      target: ProjectItemTargetKind.world,
      consumption: ProjectItemConsumptionPolicy.never,
      effect: ProjectItemEffectDefinition.bicycle(),
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'bag and shortcut share a durable toggle, held repeats never remount',
    () async {
      final saves = <GameState>[];
      final mounted = await mountBicycle(
        checkpoint: (state) async => saves.add(state),
      );
      final game = mounted.game;
      game.pauseEngine();
      final result = await mounted.controller.useBagItemOutsideBattle(
        const RuntimePlayerPauseCommand.useBagItem(
          itemTargetId: 'custom_cycle',
        ),
      );
      expect(result.status, RuntimePlayerPauseCommandStatus.accepted);
      expect(game.gameStateSnapshot.playerMovementMode, MovementMode.bicycle);
      expect(saves.single.playerMovementMode, MovementMode.bicycle);
      expect(saves.single.bag, mounted.initial.bag);
      expect(saves.single.repelState, mounted.initial.repelState);
      expect(saves.single.escapeReturnPoint, mounted.initial.escapeReturnPoint);
      game.resumeEngine();
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(
          RuntimeInputControl.bicycle,
          isRepeat: true,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(saves, hasLength(1));
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.bicycle),
      );
      await tickUntil(game, () => saves.length == 2);
      expect(saves.last.playerMovementMode, MovementMode.walk);
    },
  );
  for (final missing in [true, false]) {
    test(
      'missing clips refuse and failed disk writes rollback: missing=$missing',
      () async {
        final mounted = await mountBicycle(
          clips: !missing,
          checkpoint: (_) async => throw StateError('disk full'),
        );
        final before = mounted.game.playerServiceGameStateSnapshot;
        final used = await mounted.controller.useBicycleShortcut();
        expect(used.status, isNot(RuntimePlayerPauseCommandStatus.accepted));
        expect(mounted.game.playerServiceGameStateSnapshot, before);
        expect(mounted.game.playerMovementMode, MovementMode.walk);
      },
    );
  }
  test(
    'busy duplicate and stale failure preserve a newer runtime state',
    () async {
      final entered = Completer<void>(), release = Completer<void>();
      final mounted = await mountBicycle(
        checkpoint: (_) async {
          entered.complete();
          await release.future;
          throw StateError('disk full');
        },
      );
      final first = mounted.controller.useBicycleShortcut();
      await entered.future;
      expect(await mounted.game.saveGame(), isFalse);
      expect(await mounted.game.loadGame(), isFalse);
      expect(
        (await mounted.controller.useBicycleShortcut()).status,
        RuntimePlayerPauseCommandStatus.unavailable,
      );
      mounted.game.setPlayerMovementMode(MovementMode.surf);
      final newer = mounted.game.playerServiceGameStateSnapshot;
      release.complete();
      expect(
        (await first).status,
        isNot(RuntimePlayerPauseCommandStatus.accepted),
      );
      expect(mounted.game.playerServiceGameStateSnapshot, newer);
    },
  );
  test(
    'bicycle movement counts one Repel unit and uses PSDK cadence',
    () async {
      final mounted = await mountBicycle(checkpoint: (_) async {});
      expect(
        (await mounted.controller.useBicycleShortcut()).status,
        RuntimePlayerPauseCommandStatus.accepted,
      );
      final game = mounted.game;
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.right),
      );
      game.update(.001);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.right),
      );
      expect(
        game.lastCommittedMovement?.movement.kind,
        CommittedMovementKind.bicycle,
      );
      expect(game.gameStateSnapshot.repelState.remainingSteps, 7);
      game.update(PlayerComponent.kBicycleStepSeconds / 2);
      expect(game.debugIsPlayerStepping, isTrue);
      game.update(PlayerComponent.kBicycleStepSeconds / 2);
      expect(game.debugIsPlayerStepping, isFalse);
      expect(PlayerComponent.kBicycleStepSeconds, closeTo(.0666667, .000001));
    },
  );
  test('Scene warp to forbidden land descends before MapEnter and preserves Rope entry', () async {
    final mounted = await mountBicycle(checkpoint: (_) async {});
    await mounted.controller.useBicycleShortcut();
    expect(await warp(mounted.game, 'cave', 'cave-entry'), 'completed');
    expect(mounted.game.playerMovementMode, MovementMode.walk);
    expect(mounted.game.gameStateSnapshot.escapeReturnPoint?.mapId, 'route');
    expect(
      mounted.game.gameStateSnapshot.escapeReturnPoint?.position,
      mounted.initial.playerPosition,
    );
  });
  test('saved bicycle without dedicated clips is refused explicitly', () async {
    await expectLater(
      mountBicycle(
        clips: false,
        initialMode: MovementMode.bicycle,
        checkpoint: (_) async {},
      ),
      throwsA(isA<StateError>()),
    );
  });
  test('forbidden saved land normalizes before mounting', () async {
    final mounted = await mountBicycle(
      clips: false,
      initialMode: MovementMode.bicycle,
      metadata: const MapMetadata(isIndoor: true),
      checkpoint: (_) async {},
    );
    expect(mounted.game.playerMovementMode, MovementMode.walk);
  });
  test('in-session bicycle load without clips preserves source state and stored bytes', () async {
    final directory = await Directory.systemTemp.createTemp(
      'bicycle-load-refused-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = _BicycleFileSave(File('${directory.path}/save.json'));
    final mounted = await mountBicycle(
      clips: false,
      repository: repository,
      checkpoint: (_) async {},
    );
    final game = mounted.game;
    final before = game.playerServiceGameStateSnapshot;
    await repository.save(
      before.copyWith(
        playerMovementMode: MovementMode.bicycle,
        playerPosition: const GridPos(x: 5, y: 4),
        playerPixelPosition: null,
      ),
    );
    final stored = await repository.file.readAsBytes();
    final logs = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) logs.add(message);
    };
    try {
      expect(await game.loadGame(), isFalse);
    } finally {
      debugPrint = previousDebugPrint;
    }
    expect(
      logs.any(
        (line) => line.contains('The saved bicycle animations are incomplete.'),
      ),
      isTrue,
      reason: logs.join('\n'),
    );
    expect(game.playerServiceGameStateSnapshot, before);
    expect(game.gameStateSnapshot, before);
    expect(game.playerMovementMode, MovementMode.walk);
    expect(await repository.file.readAsBytes(), stored);
    expect(repository.writes, 1);
  });
  test('in-session bicycle load succeeds with all eight renderable dedicated clips', () async {
    final directory = await Directory.systemTemp.createTemp(
      'bicycle-load-ready-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = _BicycleFileSave(File('${directory.path}/save.json'));
    final mounted = await mountBicycle(
      repository: repository,
      checkpoint: (_) async {},
    );
    final game = mounted.game;
    await repository.save(
      game.playerServiceGameStateSnapshot.copyWith(
        playerMovementMode: MovementMode.bicycle,
        playerPosition: const GridPos(x: 5, y: 4),
        playerPixelPosition: null,
      ),
    );
    final stored = await repository.file.readAsBytes();
    expect(await game.loadGame(), isTrue);
    expect(game.playerMovementMode, MovementMode.bicycle);
    expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 5, y: 4));
    expect(
      game.world.children
          .whereType<PlayerComponent>()
          .single
          .debugAnimationSource
          ?.imageId,
      characterAnimationRuntimeImageId('cycle'),
    );
    expect(await repository.file.readAsBytes(), stored);
    expect(repository.writes, 1);
  });
  test(
    'in-session forbidden bicycle save loads as walk without bicycle clips',
    () async {
      for (final metadata in [
        const MapMetadata(isIndoor: true),
        const MapMetadata(allowBicycle: false),
      ]) {
        final directory = await Directory.systemTemp.createTemp(
          'bicycle-load-walk-',
        );
        addTearDown(() => directory.delete(recursive: true));
        final repository = _BicycleFileSave(
          File('${directory.path}/save.json'),
        );
        final mounted = await mountBicycle(
          clips: false,
          metadata: metadata,
          repository: repository,
          checkpoint: (_) async {},
        );
        final game = mounted.game;
        await repository.save(
          game.playerServiceGameStateSnapshot.copyWith(
            playerMovementMode: MovementMode.bicycle,
            playerPosition: const GridPos(x: 5, y: 4),
            playerPixelPosition: null,
          ),
        );
        final stored = await repository.file.readAsBytes();
        expect(await game.loadGame(), isTrue);
        expect(game.playerMovementMode, MovementMode.walk);
        expect(
          game.gameStateSnapshot.playerPosition,
          const GridPos(x: 5, y: 4),
        );
        expect(await repository.file.readAsBytes(), stored);
        expect(repository.writes, 1);
      }
    },
  );
  test('unsupported host refuses with an explicit 2D reason', () async {
    const state = GameState(
      saveId: 'save',
      bag: Bag(entries: [BagEntry(itemId: 'custom_cycle', quantity: 1)]),
    );
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (_) async => fail('must not commit'),
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => throw StateError('unused'),
      itemCatalog: ItemCatalogSnapshot.fromCatalog(
        const ProjectItemCatalog(schemaVersion: 1, entries: [bike]),
      ),
    );
    addTearDown(controller.dispose);
    final used = await controller.useBicycleShortcut();
    expect(used.status, RuntimePlayerPauseCommandStatus.unavailable);
    expect(used.safeMessage, contains('2D'));
  });
}

Future<
  ({
    PlayableMapGame game,
    PlayerServiceRuntimeController controller,
    GameState initial,
  })
>
mountBicycle({
  bool clips = true,
  GameSaveRepository? repository,
  MovementMode initialMode = MovementMode.walk,
  MapMetadata metadata = const MapMetadata(),
  required Future<void> Function(GameState) checkpoint,
}) async {
  final root = await Directory.systemTemp.createTemp('runtime-bicycle-');
  addTearDown(() => root.delete(recursive: true));
  final route = MapData(
    id: 'route',
    name: 'Route',
    size: const GridSize(width: 10, height: 8),
    mapMetadata: metadata,
  );
  const cave = MapData(
    id: 'cave',
    name: 'Cave',
    size: GridSize(width: 10, height: 8),
    mapMetadata: MapMetadata(isIndoor: true, escapeRopeDungeonId: 'dungeon'),
    warps: [
      MapWarp(
        id: 'cave-entry',
        pos: GridPos(x: 3, y: 3),
        targetMapId: 'route',
        targetPos: GridPos(x: 3, y: 3),
        triggerMode: MapWarpTriggerMode.onBump,
      ),
    ],
  );
  final manifest = ProjectManifest(
    name: 'Bicycle',
    tilesets: [],
    settings: const ProjectSettings(defaultPlayerCharacterId: 'hero'),
    characters: [
      ProjectCharacterEntry(
        id: 'hero',
        name: 'Hero',
        tilesetId: 'hero',
        animations: [
          if (clips)
            for (final state in [
              CharacterAnimationState.bicycleIdle,
              CharacterAnimationState.bicycle,
            ])
              for (final direction in EntityFacing.values)
                CharacterAnimation(
                  state: state,
                  direction: direction,
                  sourceAssetId: 'cycle',
                  frames: [
                    for (var i = 0; i < 4; i++)
                      CharacterAnimationFrame(
                        source: TilesetSourceRect(
                          x: i * 32,
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
    maps: [
      const ProjectMapEntry(
        id: 'route',
        name: 'Route',
        relativePath: 'route.json',
      ),
      const ProjectMapEntry(
        id: 'cave',
        name: 'Cave',
        relativePath: 'cave.json',
      ),
    ],
  );
  final initial = GameState(
    saveId: 'bicycle',
    currentMapId: 'route',
    playerMovementMode: initialMode,
    playerPosition: const GridPos(x: 3, y: 3),
    bag: const Bag(entries: [BagEntry(itemId: 'custom_cycle', quantity: 1)]),
    repelState: RepelState.active(itemId: 'repel', steps: 8),
  );
  final bundle = RuntimeMapBundle(
    manifest: manifest,
    map: route,
    projectRootDirectory: root.path,
    tilesetAbsolutePathsById: {},
    characterAnimationAbsolutePathsByAssetId: {
      'cycle': '${root.path}/cycle.png',
    },
  );
  await File('${root.path}/project.json')
      .writeAsString(jsonEncode(manifest.toJson()));
  final game = _BicycleGame(
    bundle: bundle,
    saveData: saveDataFromGameState(initial),
    saveRepository: repository ?? MemorySave(),
    initialMapActivationReason: MapActivationReason.saveRestore,
    overworldCheckpointWriter: checkpoint,
    projectFilePath: '${root.path}/project.json',
    runtimeTilesetImageLoader:
        (paths, {transparentColorByTilesetId = const {}}) async => {
          'character-animation:cycle': RuntimeTilesetImage(
            images: [],
            chunks: [],
            width: 128,
            height: 128,
          ),
        },
    runtimeMapBundleLoader: ({
      required projectFilePath,
      required mapId,
    }) async => bundle.copyWith(map: mapId == 'cave' ? cave : route),
  );
  final controller = PlayerServiceRuntimeController.contextual(
    currentGameState: () => game.playerServiceGameStateSnapshot,
    commitAndSave: game.commitAndSavePlayerServiceState,
    setInputLocked: (locked) => game.setExternalInputLock(
      RuntimeExternalInputLock.playerService,
      locked: locked,
    ),
    loadRecoveryCaps: (_) async => throw StateError('unused'),
    itemCatalog: ItemCatalogSnapshot.fromCatalog(
      const ProjectItemCatalog(schemaVersion: 1, entries: [bike]),
    ),
  );
  game.setPlayerServiceRuntimeController(controller);
  addTearDown(controller.dispose);
  addTearDown(game.onRemove);
  game.onGameResize(Vector2(640, 480));
  await game.onLoad();
  await tickUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
  return (game: game, controller: controller, initial: initial);
}

final class _BicycleFileSave implements GameSaveRepository {
  _BicycleFileSave(this.file);
  final File file;
  int writes = 0;

  @override
  Future<void> save(GameState state) async {
    writes++;
    await file.writeAsString(jsonEncode(state.toJson()), flush: true);
  }

  @override
  Future<GameState?> load() async => !await file.exists()
      ? null
      : GameState.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
        );

  @override
  Future<bool> exists() => file.exists();

  @override
  Future<void> delete() => file.delete();
}

class _BicycleGame extends PlayableMapGame {
  _BicycleGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveData,
    super.saveRepository,
    super.initialMapActivationReason,
    super.overworldCheckpointWriter,
    super.runtimeTilesetImageLoader,
    super.runtimeMapBundleLoader,
  });
  @override
  bool get isLoaded => true;
}
