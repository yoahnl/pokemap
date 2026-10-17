import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import 'playable_map_game_flash_test.dart' show MemorySave, tickUntil;

const fishingTool = ProjectItemDefinition(
  id: 'tool',
  displayName: 'Outil',
  pocketId: 'custom',
  tags: {'key-item'},
  uses: [
    ProjectItemUseDefinition(
      contexts: {ProjectItemUseContext.overworld},
      target: ProjectItemTargetKind.world,
      consumption: ProjectItemConsumptionPolicy.never,
      effect: ProjectItemEffectDefinition.fishing(
        rodKind: ProjectFishingRodKind.oldRod,
      ),
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bag closes before casting, cancellation releases only the fishing lock',
    () async {
      final mounted = await mountFishing();
      final game = mounted.game;
      game.pauseEngine();
      game.setExternalInputLock(
        RuntimeExternalInputLock.pauseMenu,
        locked: true,
      );
      final used = await mounted.controller.useBagItemOutsideBattle(
        const RuntimePlayerPauseCommand.useBagItem(itemTargetId: 'tool'),
      );
      expect(used.status, RuntimePlayerPauseCommandStatus.accepted);
      expect(used.resumeGameplay, isTrue);
      expect(game.fishingPhase, FishingAttemptPhase.casting);
      game.update(5);
      expect(game.fishingPhase, FishingAttemptPhase.casting);
      expect(mounted.random.doubleCalls, 0);
      expect(await game.saveGame(), isFalse);
      expect(await game.loadGame(), isFalse);
      expect(game.canCapturePlayerCheckpoint, isFalse);
      expect(
        (await mounted.controller.useBagItemOutsideBattle(
          const RuntimePlayerPauseCommand.useBagItem(itemTargetId: 'tool'),
        )).status,
        RuntimePlayerPauseCommandStatus.unavailable,
      );
      game.setExternalInputLock(
        RuntimeExternalInputLock.pauseMenu,
        locked: false,
      );
      game.resumeEngine();
      game.update(.4);
      expect(game.fishingPhase, FishingAttemptPhase.waiting);
      expect(game.inputAuthoritySnapshot.canCancelWorldAction, isTrue);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.secondary),
      );
      expect(game.fishingPhase, isNull);
      expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
      game.update(5);
      expect(mounted.random.doubleCalls, 0);
      expect(game.debugPendingBattleRequest, isNull);
      expect(game.canCapturePlayerCheckpoint, isTrue);
      expect(await game.saveGame(), isTrue);
      expect(game.gameStateSnapshot.bag, mounted.initial.bag);
      expect(game.gameStateSnapshot.repelState, mounted.initial.repelState);
    },
  );

  test('invalid water refuses before bicycle descent or RNG', () async {
    final saves = <GameState>[];
    final mounted = await mountFishing(
      water: false,
      initialMode: MovementMode.bicycle,
      checkpoint: (state) async => saves.add(state),
    );
    final result = await mounted.controller.useBagItemOutsideBattle(
      const RuntimePlayerPauseCommand.useBagItem(itemTargetId: 'tool'),
    );
    expect(result.status, RuntimePlayerPauseCommandStatus.unavailable);
    expect(result.safeMessage, contains('eau'));
    expect(mounted.game.playerMovementMode, MovementMode.bicycle);
    expect(mounted.game.fishingPhase, isNull);
    expect(mounted.random.doubleCalls, 0);
    expect(saves, isEmpty);
  });

  test(
    'stale state and lifecycle cancellation cannot resurrect a pending bite',
    () async {
      for (final lifecycle in [false, true]) {
        final mounted = await mountFishing();
        final game = mounted.game;
        await mounted.controller.useBagItemOutsideBattle(
          const RuntimePlayerPauseCommand.useBagItem(itemTargetId: 'tool'),
        );
        game.update(.4);
        if (lifecycle) {
          game.setExternalInputLock(
            RuntimeExternalInputLock.lifecycle,
            locked: true,
          );
          expect(game.canCapturePlayerCheckpoint, isTrue);
          game.setExternalInputLock(
            RuntimeExternalInputLock.lifecycle,
            locked: false,
          );
        } else {
          game.setPlayerMovementMode(MovementMode.surf);
        }
        game.update(1);
        game.update(.7);
        expect(mounted.random.doubleCalls, 0);
        expect(game.fishingPhase, isNull);
        expect(game.debugPendingBattleRequest, isNull);
      }
    },
  );

  test(
    'no bite resolves once, restores movement and retains progression',
    () async {
      final mounted = await mountFishing(chance: 0);
      final game = mounted.game;
      await mounted.controller.useBagItemOutsideBattle(
        const RuntimePlayerPauseCommand.useBagItem(itemTargetId: 'tool'),
      );
      game.update(.4);
      game.update(1);
      expect(game.fishingPhase, FishingAttemptPhase.noBite);
      game.update(.7);
      expect(game.fishingPhase, isNull);
      expect(mounted.random.doubleCalls, 1);
      expect(mounted.random.intCalls, 0);
      expect(game.debugPendingBattleRequest, isNull);
      expect(game.playerMovementMode, MovementMode.walk);
      expect(game.gameStateSnapshot.repelState, mounted.initial.repelState);
      expect(
        game.gameStateSnapshot.escapeReturnPoint,
        mounted.initial.escapeReturnPoint,
      );
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.down),
      );
      game.update(.01);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.down),
      );
      game.update(.2);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 2, y: 3));
    },
  );

  test('fishing hands the real front-water encounter to the native battle queue once', () async {
    final mounted = await mountFishing(battleData: true);
    final game = mounted.game;
    await mounted.controller.useBagItemOutsideBattle(
      const RuntimePlayerPauseCommand.useBagItem(itemTargetId: 'tool'),
    );
    game.update(.4);
    game.update(1);
    expect(game.fishingPhase, FishingAttemptPhase.bite);
    expect(mounted.random.doubleCalls, 1);
    game.update(.7);
    expect(game.debugFlowPhaseName, 'battleTransition');
    await tickUntil(game, () => game.debugActiveBattleRequest != null);
    final request =
        game.debugPendingBattleRequest ?? game.debugActiveBattleRequest;
    expect(request, isA<WildBattleStartRequest>());
    final wild = request! as WildBattleStartRequest;
    expect(wild.encounterKind, EncounterKind.oldRod);
    expect(wild.returnContext.playerPos, mounted.initial.playerPosition);
    expect(wild.playerPos, mounted.initial.playerPosition);
    expect(wild.generatedPokemon, isNotNull);
    expect(game.fishingPhase, isNull);
    expect(mounted.random.doubleCalls, 1);
    game.debugResetBattleForTest();
  });

  test('lifecycle interrupts a pending durable dismount without resurrecting fishing', () async {
    final entered = Completer<void>(), release = Completer<void>();
    final mounted = await mountFishing(
      initialMode: MovementMode.bicycle,
      checkpoint: (_) async {
        entered.complete();
        await release.future;
      },
    );
    final game = mounted.game;
    final use = mounted.controller.useBagItemOutsideBattle(
      const RuntimePlayerPauseCommand.useBagItem(itemTargetId: 'tool'),
    );
    await entered.future;
    expect(game.canCapturePlayerCheckpoint, isFalse);
    game.setExternalInputLock(RuntimeExternalInputLock.lifecycle, locked: true);
    expect(
      game.inputAuthoritySnapshot.externalLocks,
      contains(RuntimeExternalInputLock.lifecycle),
    );
    expect(
      game.debugInputLockSnapshot.activeTokens.where(
        (token) => token.owner == RuntimeInputLockOwner.playerService,
      ),
      isEmpty,
    );
    game.pauseEngine();
    expect(game.isPaused, isTrue);
    expect(game.canCapturePlayerCheckpoint, isFalse);
    release.complete();
    final result = await use;
    expect(result.status, RuntimePlayerPauseCommandStatus.unavailable);
    expect(game.fishingPhase, isNull);
    expect(game.canCapturePlayerCheckpoint, isTrue);
    expect(game.playerMovementMode, MovementMode.walk);
    expect(mounted.random.doubleCalls, 0);
    expect(
      game.inputAuthoritySnapshot.externalLocks,
      contains(RuntimeExternalInputLock.lifecycle),
    );
    expect(
      game.debugInputLockSnapshot.activeTokens.where(
        (token) => token.owner == RuntimeInputLockOwner.lifecycle,
      ),
      hasLength(1),
    );
    expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isFalse);
    game.setExternalInputLock(
      RuntimeExternalInputLock.lifecycle,
      locked: false,
    );
    game.resumeEngine();
    expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
  });

  for (final fail in [false, true]) {
    test(
      'bicycle descends durably before casting; save failure rolls back: $fail',
      () async {
        final saves = <GameState>[];
        final mounted = await mountFishing(
          initialMode: MovementMode.bicycle,
          checkpoint: (state) async {
            if (fail) throw StateError('disk full');
            saves.add(state);
          },
        );
        final result = await mounted.controller.useBagItemOutsideBattle(
          const RuntimePlayerPauseCommand.useBagItem(itemTargetId: 'tool'),
        );
        expect(
          result.status,
          fail
              ? RuntimePlayerPauseCommandStatus.unavailable
              : RuntimePlayerPauseCommandStatus.accepted,
        );
        expect(
          mounted.game.playerMovementMode,
          fail ? MovementMode.bicycle : MovementMode.walk,
        );
        expect(mounted.random.doubleCalls, 0);
        if (!fail) {
          expect(saves.single.playerMovementMode, MovementMode.walk);
          mounted.game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.secondary),
          );
          expect(mounted.game.playerMovementMode, MovementMode.walk);
        }
        expect(mounted.game.gameStateSnapshot.bag, mounted.initial.bag);
        expect(
          mounted.game.gameStateSnapshot.repelState,
          mounted.initial.repelState,
        );
        expect(
          mounted.game.gameStateSnapshot.escapeReturnPoint,
          mounted.initial.escapeReturnPoint,
        );
      },
    );
  }
}

Future<
  ({
    PlayableMapGame game,
    PlayerServiceRuntimeController controller,
    GameState initial,
    FishingRandom random,
  })
>
mountFishing({
  double chance = 1,
  bool water = true,
  bool battleData = false,
  MovementMode initialMode = MovementMode.walk,
  Future<void> Function(GameState)? checkpoint,
}) async {
  final root = await Directory.systemTemp.createTemp('runtime-fishing-');
  addTearDown(() => root.delete(recursive: true));
  final referenceRoot = Directory(
    '../../examples/playable_runtime_host/golden_battle_slice',
  ).absolute;
  final referenceProject = battleData
      ? ProjectManifest.fromJson(
          jsonDecode(
            await File('${referenceRoot.path}/project.json').readAsString(),
          ) as Map<String, dynamic>,
        )
      : null;
  final referenceState = battleData
      ? gameStateFromSaveData(
          SaveData.fromJson(
            jsonDecode(
              await File('${referenceRoot.path}/runtime_host_launch_save.json')
                  .readAsString(),
            ) as Map<String, dynamic>,
          ),
        )
      : null;
  final map = MapData(
    id: 'shore',
    name: 'Shore',
    size: const GridSize(width: 8, height: 8),
    gameplayZones: [
      if (water)
        const MapGameplayZone(
          id: 'water',
          name: 'Water',
          kind: GameplayZoneKind.movement,
          area: MapRect(
            pos: GridPos(x: 3, y: 2),
            size: GridSize(width: 1, height: 1),
          ),
          movement: MovementZonePayload(requiredMode: MovementMode.surf),
        ),
      const MapGameplayZone(
        id: 'fish',
        name: 'Fish',
        kind: GameplayZoneKind.encounter,
        area: MapRect(
          pos: GridPos(x: 3, y: 2),
          size: GridSize(width: 1, height: 1),
        ),
        encounter: EncounterZonePayload(
          encounterKind: EncounterKind.oldRod,
          encounterTableId: 'rod',
        ),
      ),
    ],
  );
  final manifest =
      (referenceProject ??
              const ProjectManifest(name: 'Fishing', maps: [], tilesets: []))
          .copyWith(
            name: 'Fishing',
            maps: [
              const ProjectMapEntry(
                id: 'shore',
                name: 'Shore',
                relativePath: 'shore.json',
              ),
            ],
            tilesets: [],
            encounterTables: [
              ProjectEncounterTable(
                id: 'rod',
                name: 'Rod',
                encounterKind: EncounterKind.oldRod,
                chancePerStep: chance,
                entries: const [
                  ProjectEncounterEntry(
                    speciesId: 'sparkitten',
                    minLevel: 5,
                    maxLevel: 5,
                  ),
                ],
              ),
            ],
          );
  final initial = GameState(
    saveId: 'fishing',
    currentMapId: 'shore',
    playerPosition: const GridPos(x: 2, y: 2),
    playerFacing: EntityFacing.east,
    playerMovementMode: MovementMode.walk,
    party: referenceState?.party ?? const PlayerParty(),
    bag: const Bag(entries: [BagEntry(itemId: 'tool', quantity: 1)]),
    repelState: RepelState.active(itemId: 'repel', steps: 8),
    escapeReturnPoint: const EscapeReturnPoint(
      dungeonId: 'cave',
      mapId: 'outside',
      position: GridPos(x: 1, y: 1),
      facing: EntityFacing.south,
    ),
  );
  final bundle = RuntimeMapBundle(
    manifest: manifest,
    map: map,
    projectRootDirectory: battleData ? referenceRoot.path : root.path,
    tilesetAbsolutePathsById: {},
  );
  await File('${root.path}/project.json')
      .writeAsString(jsonEncode(manifest.toJson()));
  final random = FishingRandom();
  final game = _FishingGame(
    bundle: bundle,
    projectFilePath: '${root.path}/project.json',
    saveData: saveDataFromGameState(initial),
    saveRepository: MemorySave(),
    initialMapActivationReason: MapActivationReason.saveRestore,
    overworldCheckpointWriter: checkpoint,
    encounterRandom: random,
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
      const ProjectItemCatalog(schemaVersion: 1, entries: [fishingTool]),
    ),
  );
  game.setPlayerServiceRuntimeController(controller);
  addTearDown(controller.dispose);
  addTearDown(game.onRemove);
  game.onGameResize(Vector2(640, 480));
  await game.onLoad();
  await tickUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
  if (initialMode != MovementMode.walk) game.setPlayerMovementMode(initialMode);
  return (game: game, controller: controller, initial: initial, random: random);
}

class _FishingGame extends PlayableMapGame {
  _FishingGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveData,
    super.saveRepository,
    super.initialMapActivationReason,
    super.overworldCheckpointWriter,
    super.encounterRandom,
  });
  @override
  bool get isLoaded => true;
}

class FishingRandom implements Random {
  final delegate = Random(42);
  int doubleCalls = 0, intCalls = 0;
  @override
  double nextDouble() {
    doubleCalls++;
    return delegate.nextDouble();
  }

  @override
  int nextInt(int max) {
    intCalls++;
    return delegate.nextInt(max);
  }

  @override
  bool nextBool() => delegate.nextBool();
}
