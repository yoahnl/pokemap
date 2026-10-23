import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/parse_yarn_dialogue.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/presentation/flame/overworld_actor_component.dart';

const _id = 'walker';
const _mapId = 'fixed-route-center';
const _origin = GridPos(x: 2, y: 2);
const _east = GridPos(x: 3, y: 2);
const _pageRoute = MapEntityNpcMovementConfig(
  mode: MapEntityNpcMovementMode.fixedRoute,
  routeSteps: [
    MapEntityNpcRouteStep.move(direction: EntityFacing.east),
    MapEntityNpcRouteStep.move(direction: EntityFacing.west),
  ],
  pauseDurationMs: 1600,
  stepDurationMs: 250,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a page change and return invalidates the old pending player contact',
    () async {
      var bundle = _bundle(
        v2: true,
        contactEvent: true,
        pageMovement: const MapEntityNpcMovementConfig(),
      );
      final original = bundle.manifest.scenes.single;
      final transient = SceneAsset(
        id: 'transient-page',
        name: 'Transient page',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            ...original.graph.nodes,
            SceneNode(
              id: 'hold',
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(dialogueId: 'talk'),
            ),
          ],
          edges: [
            for (final edge in original.graph.edges)
              if (edge.id != 'done') edge,
            SceneEdge(
              id: 'hold',
              fromNodeId: 'stop',
              fromPortId: 'completed',
              toNodeId: 'hold',
              kind: SceneEdgeKind.actionCompleted,
            ),
            SceneEdge(
              id: 'end',
              fromNodeId: 'hold',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      );
      bundle = bundle.copyWith(
        manifest: bundle.manifest.copyWith(scenes: [original, transient]),
      );
      late PlayableMapGame game;
      var transientFinished = false;
      game = await _load(
        bundle,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind != NarrativeEventSourceKind.entityBump) {
            return;
          }
          final result = await game.debugExecuteNarrativeSceneForTest(
            NarrativeSceneExecutionRequest(
              eventId: 'evt_019abcde-1600-7000-8000-000000000001',
              sceneId: transient.id,
              executionId: 'temporary-page',
              gameState: game.gameStateSnapshot,
            ),
          );
          expect(result, isA<NarrativeSceneExecutionCompleted>());
          transientFinished = true;
        },
      );
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 2, y: 3),
        facing: Direction.north,
      );
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.up),
      );
      game.update(.016);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.up),
      );
      await _until(game, () => game.debugFlowPhaseName == 'dialogue');
      _confirm(game);
      await _until(
        game,
        () =>
            transientFinished && !game.debugIsNarrativeSpatialDispatchInFlight,
      );
      final state = game.gameStateSnapshot.mapInstanceWorldState;
      expect(
        state.eventBoolean(
          state.instanceRef(_mapId)!,
          _id,
          'npc.autonomousRouteStopped',
        ),
        isFalse,
      );
      expect(game.debugIsGameplayInputLocked, isFalse);
    },
  );

  for (final startsOnNpcContact in [false, true]) {
    test(
      'autonomous contact follows page policy and is latched starts=$startsOnNpcContact',
      () async {
        var preparations = 0;
        final game = await _load(
          _bundle(
            v2: true,
            contactEvent: true,
            startsOnNpcContact: startsOnNpcContact,
          ),
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind == NarrativeEventSourceKind.entityBump) {
              preparations++;
            }
          },
        );
        game.debugSetPlayerStateForTest(
          position: _east,
          facing: Direction.north,
        );
        await _pump(game, milliseconds: 8500);
        final instances = game.gameStateSnapshot.mapInstanceWorldState;
        expect(
          instances.eventBoolean(
            instances.instanceRef(_mapId)!,
            _id,
            'npc.autonomousRouteStopped',
          ),
          startsOnNpcContact,
        );
        expect(preparations, startsOnNpcContact ? 1 : 0);
        expect(game.debugMapEntityPosition(_id), _origin);
        expect(game.debugIsGameplayInputLocked, isFalse);
      },
    );
  }

  test('player contact interrupts moving NPC before dispatch without a late commit', () async {
    var preparations = 0;
    final game = await _load(
      _bundle(v2: true, contactEvent: true),
      beforeNarrativeAuthorityPreparation: (occurrence) async {
        if (occurrence.source.kind == NarrativeEventSourceKind.entityBump) {
          preparations++;
        }
      },
    );
    await _until(
      game,
      () => game.debugNpcActorFacing(_id) == EntityFacing.east,
    );
    game.debugSetPlayerStateForTest(
      position: const GridPos(x: 2, y: 3),
      facing: Direction.north,
    );
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.up),
    );
    game.update(.016);
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.up),
    );
    await _until(game, () => preparations > 0);
    await _pump(game, milliseconds: 400);
    expect(game.debugMapEntityPosition(_id), _origin);
    expect(game.debugNpcGridPosition(_id), _origin);
    expect(preparations, 1);
    expect(game.debugIsGameplayInputLocked, isFalse);
  });

  test(
    'a different page with equal route restarts at its first command',
    () async {
      final game = await _load(_bundle(v2: true, pageMovement: _pageRoute));
      await _until(game, () => game.debugMapEntityPosition(_id) == _east);
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 0, y: 4),
        facing: Direction.north,
      );
      _interact(game);
      await _until(game, () {
        final instances = game.gameStateSnapshot.mapInstanceWorldState;
        return instances.eventBoolean(
          instances.instanceRef(_mapId)!,
          _id,
          'npc.autonomousRouteStopped',
        );
      });
      await _until(game, () => game.debugMapEntityPosition(_id) != _east);
      expect(game.debugMapEntityPosition(_id), const GridPos(x: 4, y: 2));
    },
  );

  test('local stationary page survives save restore but a recreated instance moves', () async {
    final bundle = _bundle(
      v2: true,
      pageMovement: const MapEntityNpcMovementConfig(),
    );
    final first = await _load(bundle);
    first.debugSetPlayerStateForTest(
      position: const GridPos(x: 0, y: 4),
      facing: Direction.north,
    );
    _interact(first);
    await _until(first, () {
      final instances = first.gameStateSnapshot.mapInstanceWorldState;
      return instances.eventBoolean(
        instances.instanceRef(_mapId)!,
        _id,
        'npc.autonomousRouteStopped',
      );
    });
    final saved = gameStateFromStrictSaveJson(
      strictGameStateSaveJson(first.gameStateSnapshot),
    );
    final restored = await _load(bundle, state: saved);
    await _pump(restored, milliseconds: 5000);
    expect(restored.debugMapEntityPosition(_id), _origin);
    final reset = saved.copyWith(
      mapInstanceWorldState: setupDifferentMapInstance(
        state: saved.mapInstanceWorldState,
        targetMapId: _mapId,
        allocateId: (_) => 'fresh-visit',
      ),
    );
    final recreated = await _load(bundle, state: reset);
    await _until(
      recreated,
      () => recreated.debugMapEntityPosition(_id) == _east,
    );
    expect(saved.storyFlags, reset.storyFlags);
  });

  test('complete local program changes appearance collision trigger and movement across restore and eviction', () async {
    final bundle = _bundle(
      v2: true,
      contactEvent: true,
      startsOnNpcContact: true,
      pageMovement: const MapEntityNpcMovementConfig(),
      pageAppearanceChange: true,
    );
    var preparations = 0;
    final first = await _load(
      bundle,
      beforeNarrativeAuthorityPreparation: (occurrence) async {
        if (occurrence.source.kind == NarrativeEventSourceKind.entityBump) {
          preparations++;
        }
      },
    );
    final original = first.world.children
        .whereType<OverworldActorComponent>()
        .single;
    final originalFacts = first.gameStateSnapshot.narrativeFactRuntimeState;
    first.debugSetPlayerStateForTest(position: _east, facing: Direction.west);
    await _until(first, () {
      final state = first.gameStateSnapshot.mapInstanceWorldState;
      return state.eventBoolean(
        state.instanceRef(_mapId)!,
        _id,
        'npc.autonomousRouteStopped',
      );
    });
    await _pump(first, milliseconds: 5000);
    final changed = first.world.children
        .whereType<OverworldActorComponent>()
        .single;
    expect(identical(changed, original), isTrue);
    expect(changed.character.id, 'alternate-character');
    expect(first.debugNpcVisualFacing(_id), EntityFacing.west);
    expect(first.debugMapEntityPosition(_id), _origin);
    first.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.left),
    );
    first.update(.016);
    first.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.left),
    );
    await _until(
      first,
      () =>
          first.debugPlayerGridPosition == _origin &&
          !first.debugIsPlayerStepping,
    );
    expect(preparations, 1);
    expect(first.gameStateSnapshot.narrativeFactRuntimeState, originalFacts);
    final saved = gameStateFromStrictSaveJson(
      strictGameStateSaveJson(first.gameStateSnapshot),
    );
    final retained = await _load(bundle, state: saved);
    await _pump(retained, milliseconds: 5000);
    expect(
      retained.world.children
          .whereType<OverworldActorComponent>()
          .single
          .character
          .id,
      'alternate-character',
    );
    expect(retained.debugNpcVisualFacing(_id), EntityFacing.west);
    expect(retained.debugMapEntityPosition(_id), _origin);
    expect(retained.debugIsGameplayInputLocked, isFalse);
    final elsewhere = retainMapInstance(
      state: saved.mapInstanceWorldState,
      mapId: 'elsewhere',
      allocateId: (_) => 'elsewhere-visit',
    );
    final evicted = updateMapInstanceRetention(
      state: elsewhere,
      activeMap: MapInstanceMapGeometry(
        mapId: 'elsewhere',
        originTiles: const GridPos(x: 100, y: 100),
        sizeTiles: const GridSize(width: 8, height: 5),
      ),
      directConnectedMaps: [
        MapInstanceMapGeometry(
          mapId: _mapId,
          originTiles: const GridPos(x: 0, y: 0),
          sizeTiles: bundle.map.size,
        ),
      ],
      logicalViewport: MapInstanceLogicalViewport(
        leftTiles: 100,
        topTiles: 100,
      ),
      policy: bundle.manifest.settings.mapInstanceRetentionPolicy!,
      settled: true,
      allocateId: (_) => 'unused',
    );
    expect(evicted.instanceRef(_mapId), isNull);
    final reset = saved.copyWith(
      playerPosition: const GridPos(x: 0, y: 4),
      playerPixelPosition: null,
      mapInstanceWorldState: setupDifferentMapInstance(
        state: evicted,
        targetMapId: _mapId,
        allocateId: (_) => 'after-eviction',
      ),
    );
    final recreated = await _load(bundle, state: reset);
    expect(
      recreated.world.children
          .whereType<OverworldActorComponent>()
          .single
          .character
          .id,
      'npc-character',
    );
    await _until(
      recreated,
      () => recreated.debugMapEntityPosition(_id) == _east,
    );
    final instances = recreated.gameStateSnapshot.mapInstanceWorldState;
    expect(
      instances.eventBoolean(
        instances.instanceRef(_mapId)!,
        _id,
        'npc.autonomousRouteStopped',
      ),
      isFalse,
    );
    expect(
      recreated.gameStateSnapshot.narrativeFactRuntimeState,
      originalFacts,
    );
  });

  for (final nextMovement in [
    const MapEntityNpcMovementConfig(),
    const MapEntityNpcMovementConfig(
      mode: MapEntityNpcMovementMode.fixedRoute,
      routeSteps: [MapEntityNpcRouteStep.move(direction: EntityFacing.west)],
      pauseDurationMs: 1600,
      stepDurationMs: 250,
    ),
  ]) {
    test(
      'page change cancels in-flight route before ${nextMovement.mode.name}',
      () async {
        final game = await _load(_bundle(v2: true, pageMovement: nextMovement));
        await _until(
          game,
          () => game.debugNpcActorFacing(_id) == EntityFacing.east,
        );
        expect(game.debugMapEntityPosition(_id), _origin);
        game.debugSetPlayerStateForTest(
          position: const GridPos(x: 0, y: 4),
          facing: Direction.north,
        );
        _interact(game);
        await _until(game, () {
          final instances = game.gameStateSnapshot.mapInstanceWorldState;
          return instances.eventBoolean(
            instances.instanceRef(_mapId)!,
            _id,
            'npc.autonomousRouteStopped',
          );
        });
        await _pump(game, milliseconds: 500);
        expect(game.debugMapEntityPosition(_id), _origin);
        expect(game.debugNpcGridPosition(_id), _origin);
        expect(game.debugNpcVisualFacing(_id), EntityFacing.north);
        if (nextMovement.mode == MapEntityNpcMovementMode.idle) {
          await _pump(game, milliseconds: 5000);
          expect(game.debugMapEntityPosition(_id), _origin);
        } else {
          await _until(
            game,
            () => game.debugMapEntityPosition(_id) == const GridPos(x: 1, y: 2),
          );
        }
        expect(game.debugIsGameplayInputLocked, isFalse);
      },
    );
  }

  Map<String, Object?>? normalState;
  for (final speed in PlaytestSpeed.values) {
    test(
      '×${speed.multiplier} preserves seeded autonomous movement over equal simulation time',
      () async {
        final random = math.Random(42);
        final encounters = _CountingRandom([37]);
        final game = await _load(
          _bundle(randomMove: true),
          npcRouteRandom: random,
          encounterRandom: encounters,
        );
        game.setTestSpeed(speed);
        for (var tick = 0; tick < 420 ~/ speed.multiplier; tick++) {
          game.update(1 / 60);
          await Future<void>.delayed(Duration.zero);
        }
        final state = <String, Object?>{
          'position': game.debugMapEntityPosition(_id),
          'facing': game.debugNpcActorFacing(_id),
          'runtimePositions': game.debugRuntimeNpcPositions,
          'nextRandom': random.nextInt(100000),
          'encounterDraws': encounters.draws,
        };
        normalState ??= state;
        expect(state, normalState);
        expect(encounters.draws, 0);
      },
    );
  }

  for (final blocked in [false, true]) {
    test(
      'native random move ${blocked ? 'waits at collision' : 'animates and commits'} in Player',
      () async {
        final movementRandom = _CountingRandom([1]);
        final encounters = _CountingRandom([37]);
        final game = await _load(
          _bundle(randomMove: true, blockEast: blocked),
          npcRouteRandom: movementRandom,
          encounterRandom: encounters,
        );
        if (blocked) {
          await _pump(game, milliseconds: 5000);
          expect(game.debugMapEntityPosition(_id), _origin);
          expect(game.debugNpcActorFacing(_id), EntityFacing.east);
          expect(movementRandom.draws, greaterThan(1));
        } else {
          await _until(game, () => game.debugMapEntityPosition(_id) == _east);
          expect(game.debugNpcVisualFacing(_id), EntityFacing.east);
          game.setExternalInputLock(
            RuntimeExternalInputLock.playerService,
            locked: true,
          );
          final stopped = game.debugMapEntityPosition(_id);
          final draws = movementRandom.draws;
          await _pump(game, milliseconds: 6000);
          expect(game.debugMapEntityPosition(_id), stopped);
          expect(movementRandom.draws, draws);
        }
        expect(encounters.draws, 0);
      },
    );
  }

  test(
    'Player uses initial wait, direct step and post-completion cadence',
    () async {
      final game = await _load(_bundle());
      await _pump(game, milliseconds: 1200);
      expect(game.debugMapEntityPosition(_id), _origin);
      await _until(game, () => game.debugMapEntityPosition(_id) == _east);
      expect(game.debugNpcVisualFacing(_id), EntityFacing.east);
      await _pump(game, milliseconds: 1200);
      expect(game.debugMapEntityPosition(_id), _east);
      await _until(game, () => game.debugMapEntityPosition(_id) == _origin);
      expect(game.debugNpcVisualFacing(_id), EntityFacing.west);
    },
  );

  test(
    'blocked cardinal move turns but never detours or skips its command',
    () async {
      final game = await _load(_bundle(blockEast: true));
      await _pump(game, milliseconds: 7000);
      expect(game.debugMapEntityPosition(_id), _origin);
      expect(game.debugNpcActorFacing(_id), EntityFacing.east);
      expect(game.debugNpcVisualFacing(_id), EntityFacing.east);
      expect(game.debugRuntimeNpcPositions[_id], _origin);
    },
  );

  test(
    'random facing uses its dedicated RNG without consuming encounter draws',
    () async {
      final routeRandom = _CountingRandom([1, 2]);
      final encounterRandom = _CountingRandom([31, 32]);
      final game = await _load(
        _bundle(randomFacing: true),
        npcRouteRandom: routeRandom,
        encounterRandom: encounterRandom,
      );
      await _pump(game, milliseconds: 7000);
      expect(routeRandom.draws, 4);
      expect(game.debugNpcActorFacing(_id), EntityFacing.west);
      expect(game.debugMapEntityPosition(_id), _origin);
      expect(encounterRandom.draws, 0);
      expect(encounterRandom.nextInt(100), 31);
    },
  );

  test('owning Scene activity suspends random facing across gaps without dialogue or cinematic overlays', () async {
    final activity = NarrativeRuntimeActivityGate();
    final random = _CountingRandom([1, 2, 3]);
    final game = await _load(
      _bundle(randomFacing: true),
      npcRouteRandom: random,
      narrativeRuntimeActivityGate: activity,
    );
    await _pump(game, milliseconds: 600);
    final before = game.debugNpcActorFacing(_id);
    final lease = activity.enter(NarrativeRuntimeActivity.sceneActive);
    addTearDown(lease.close);
    for (var fragment = 0; fragment < 3; fragment++) {
      await _pump(game, milliseconds: 6000);
      expect(game.debugFlowPhaseName, 'overworld');
      expect(game.debugNpcActorFacing(_id), before);
      expect(game.debugMapEntityPosition(_id), _origin);
      expect(random.draws, 0);
    }
    lease.close();
    await _pump(game, milliseconds: 700);
    expect(random.draws, 0);
    await _until(game, () => random.draws > 0);
    expect(game.debugNpcActorFacing(_id), isNot(before));
  });

  for (final lock in RuntimeExternalInputLock.values) {
    test(
      'native ${lock.name} lock freezes autonomous cadence and resumes',
      () async {
        final game = await _load(_bundle());
        await _pump(game, milliseconds: 600);
        game.setExternalInputLock(lock, locked: true);
        await _pump(game, milliseconds: 6000);
        expect(game.debugMapEntityPosition(_id), _origin);
        game.setExternalInputLock(lock, locked: false);
        await _pump(game, milliseconds: 700);
        expect(game.debugMapEntityPosition(_id), _origin);
        await _until(game, () => game.debugMapEntityPosition(_id) == _east);
      },
    );
  }

  for (final duringStep in [false, true]) {
    test(
      'Town Map awaits close and pauses the route ${duringStep ? 'during a step' : 'before a step'}',
      () async {
        final game = await _load(_bundle());
        if (duringStep) {
          await _until(
            game,
            () => game.debugNpcVisualFacing(_id) == EntityFacing.east,
          );
          expect(game.debugMapEntityPosition(_id), _origin);
        }
        final controller = PlayerServiceRuntimeController.contextual(
          currentGameState: () => game.playerServiceGameStateSnapshot,
          commitAndSave: (_) async =>
              fail('Reading the map cannot write a save.'),
          setInputLocked: (locked) => game.setExternalInputLock(
            RuntimeExternalInputLock.playerService,
            locked: locked,
          ),
          loadRecoveryCaps: (_) async =>
              throw StateError('No healing requested.'),
        );
        addTearDown(controller.dispose);
        game.setPlayerServiceRuntimeController(controller);
        final open = controller.openRegionalMap(
          request: const OpenRegionalMapService(interactionId: 'wall.map'),
          detail: RuntimePlayerPauseDetailSnapshot(
            section: RuntimePlayerPauseSection.map,
            title: 'Kanto',
            regionalMap: RuntimePlayerRegionMapSnapshot(
              regions: [
                RuntimePlayerRegionSnapshot(
                  id: 'kanto',
                  label: 'Kanto',
                  points: [
                    const RuntimePlayerMapPointSnapshot(
                      id: 'center',
                      label: 'Center',
                      status: RuntimePlayerMapPointStatus.current,
                      u: .5,
                      v: .5,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        var closed = false;
        open.then((_) => closed = true);
        await _pump(game, milliseconds: 6000);
        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.debugMapEntityPosition(_id), _origin);
        expect(closed, false);
        final snapshot = controller.worldServiceSnapshot!;
        await controller.dispatchWorldService(
          RuntimeWorldServiceCommand(
            action: RuntimeWorldServiceAction.close,
            snapshotRevision: snapshot.revision,
          ),
        );
        expect((await open).status, PlayerServiceRuntimeStatus.completed);
        await _pump(game, milliseconds: 1200);
        expect(game.debugMapEntityPosition(_id), _origin);
        await _until(game, () => game.debugMapEntityPosition(_id) == _east);
      },
    );
  }

  test('voluntary talk interrupts only its owner and resumes after native dialogue', () async {
    final game = await _load(_bundle());
    await _pump(game, milliseconds: 1200);
    game.debugSetPlayerStateForTest(
      position: const GridPos(x: 2, y: 3),
      facing: Direction.north,
    );
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.primary),
    );
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.primary),
    );
    await _until(game, () => game.debugFlowPhaseName == 'dialogue');
    expect(game.debugNpcActorFacing(_id), EntityFacing.south);
    expect(game.debugNpcVisualFacing(_id), EntityFacing.south);
    await _pump(game, milliseconds: 6000);
    expect(game.debugMapEntityPosition(_id), _origin);
    _confirm(game);
    await _until(game, () => game.debugFlowPhaseName == 'overworld');
    await _pump(game, milliseconds: 1200);
    expect(game.debugMapEntityPosition(_id), _origin);
    await _until(game, () => game.debugMapEntityPosition(_id) == _east);
  });

  test(
    'turning on the spot detects a stationary player before victory',
    () async {
      final game = await _load(_bundle(trainer: true, turnOnly: true));
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 0, y: 2),
        facing: Direction.east,
      );
      await _until(game, () => game.debugIsGameplayInputLocked, maxTicks: 120);
      expect(game.debugNpcActorFacing(_id), EntityFacing.west);
      expect(game.debugMapEntityPosition(_id), _origin);
      expect(game.debugPendingBattleRequest, isNull);
      expect(game.debugFlowPhaseName, 'overworld');
    },
  );

  test(
    'a completed cardinal step spots the stationary player before victory',
    () async {
      final game = await _load(_bundle(trainer: true));
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 4, y: 2),
        facing: Direction.west,
      );
      await _until(game, () => game.debugIsGameplayInputLocked, maxTicks: 150);
      expect(game.debugNpcActorFacing(_id), EntityFacing.east);
      expect(game.debugMapEntityPosition(_id), _east);
      expect(game.debugPendingBattleRequest, isNull);
    },
  );

  test(
    'native defeated guard keeps moving trainer talkable without another spot',
    () async {
      final game = await _load(_bundle(trainer: true, turnOnly: true));
      game.debugMarkTrainerAsDefeated('jeremy');
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 0, y: 2),
        facing: Direction.east,
      );
      await _pump(game, milliseconds: 7000);
      expect(game.debugIsGameplayInputLocked, false);
      expect(game.debugPendingBattleRequest, isNull);
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 2, y: 3),
        facing: Direction.north,
      );
      _interact(game);
      await _until(game, () => game.debugFlowPhaseName == 'dialogue');
      expect(game.debugNpcVisualFacing(_id), EntityFacing.south);
      _confirm(game);
      await _until(game, () => game.debugFlowPhaseName == 'overworld');
      await _pump(game, milliseconds: 1700);
      expect(game.debugNpcActorFacing(_id), EntityFacing.west);
      expect(game.debugMapEntityPosition(_id), _origin);
      expect(game.debugPendingBattleRequest, isNull);
    },
  );

  test(
    'instance suspension survives save data and clears only on a new instance',
    () async {
      var instances = setupDifferentMapInstance(
        state: const MapInstanceWorldState.empty(),
        targetMapId: _mapId,
        allocateId: (_) => 'visit-1',
      );
      instances = instances.setEventBoolean(
        instances.instanceRef(_mapId)!,
        _id,
        'npc.autonomousRouteStopped',
        true,
      );
      final saved = GameState(
        saveId: 'fixed-route-save',
        currentMapId: _mapId,
        playerPosition: const GridPos(x: 0, y: 4),
        mapInstanceWorldState: instances,
      );
      final restored = gameStateFromStrictSaveJson(
        strictGameStateSaveJson(saved),
      );
      final first = await _load(_bundle(suspend: true), state: restored);
      await _pump(first, milliseconds: 7000);
      expect(first.debugMapEntityPosition(_id), _origin);
      expect(first.debugNpcVisualFacing(_id), EntityFacing.north);
      final next = setupDifferentMapInstance(
        state: restored.mapInstanceWorldState,
        targetMapId: _mapId,
        allocateId: (_) => 'visit-2',
      );
      final second = await _load(
        _bundle(suspend: true),
        state: restored.copyWith(mapInstanceWorldState: next),
      );
      await _until(second, () => second.debugMapEntityPosition(_id) == _east);
      await _pump(first, milliseconds: 7000);
      expect(first.debugMapEntityPosition(_id), _origin);
      expect(
        second.gameStateSnapshot.mapInstanceWorldState
            .instanceRef(_mapId)!
            .instanceId,
        'visit-2',
      );
    },
  );

  test(
    'a real buffered scene stops a pending step without a late position commit',
    () async {
      final game = await _load(_bundle(suspend: true, v2: true));
      await _until(
        game,
        () => game.debugNpcActorFacing(_id) == EntityFacing.east,
      );
      expect(game.debugMapEntityPosition(_id), _origin);
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 0, y: 4),
        facing: Direction.north,
      );
      _interact(game);
      await _until(game, () {
        final store = game.gameStateSnapshot.mapInstanceWorldState;
        return store.eventBoolean(
          store.instanceRef(_mapId)!,
          _id,
          'npc.autonomousRouteStopped',
        );
      });
      await _pump(game, milliseconds: 7000);
      expect(game.debugMapEntityPosition(_id), _origin);
      final store = game.gameStateSnapshot.mapInstanceWorldState;
      expect(
        store.eventBoolean(
          store.instanceRef(_mapId)!,
          _id,
          'npc.autonomousRouteStopped',
        ),
        true,
      );
      expect(game.debugNpcGridPosition(_id), _origin);
    },
  );
}

void _interact(PlayableMapGame game) {
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.press(RuntimeInputControl.primary),
  );
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.release(RuntimeInputControl.primary),
  );
}

void _confirm(PlayableMapGame game) {
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.press(RuntimeInputControl.primary),
  );
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.release(RuntimeInputControl.primary),
  );
}

RuntimeMapBundle _bundle({
  bool blockEast = false,
  bool trainer = false,
  bool turnOnly = false,
  bool randomFacing = false,
  bool randomMove = false,
  bool suspend = false,
  bool v2 = false,
  MapEntityNpcMovementConfig? pageMovement,
  bool contactEvent = false,
  bool startsOnNpcContact = false,
  bool pageAppearanceChange = false,
}) => RuntimeMapBundle(
  projectRootDirectory: '/tmp/fixed-route-player',
  tilesetAbsolutePathsById: const {},
  manifest: ProjectManifest(
    name: 'Native fixed routes',
    settings: ProjectSettings(
      mapInstanceRetentionPolicy: MapInstanceRetentionPolicy(
        viewportWidthTiles: 8,
        viewportHeightTiles: 5,
        marginTiles: 0,
      ),
    ),
    eventRegistry: v2
        ? NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [
              NarrativeEventRecord.configuredStructurallyUnchecked(
                NarrativeEventDefinition(
                  id: 'evt_019abcde-1600-7000-8000-000000000001',
                  name: 'Stop current route',
                  source: contactEvent
                      ? NarrativeEventSourceRef.entityBump(_mapId, _id)
                      : NarrativeEventSourceRef.entityInteract(
                          _mapId,
                          'stop-switch',
                        ),
                  sceneId: 'stop-route',
                  conditions: [
                    if (pageAppearanceChange)
                      NarrativeEventCondition.mapEventInstanceBoolean(
                        mapId: _mapId,
                        eventId: _id,
                        key: 'npc.autonomousRouteStopped',
                        expectedValue: false,
                      ),
                  ],
                  reusePolicy: NarrativeEventReusePolicy.reusable,
                  priority: 0,
                  order: 0,
                ),
                enabled: true,
              ),
            ],
            legacyClaims: const [],
          )
        : null,
    maps: const [
      ProjectMapEntry(
        id: _mapId,
        name: 'Center',
        relativePath: 'maps/center.json',
      ),
    ],
    tilesets: const [],
    characters: const [
      ProjectCharacterEntry(
        id: 'npc-character',
        name: 'NPC',
        tilesetId: 'npc-sheet',
      ),
      ProjectCharacterEntry(
        id: 'alternate-character',
        name: 'Alternate',
        tilesetId: 'npc-sheet',
      ),
    ],
    dialogues: const [
      ProjectDialogueEntry(id: 'talk', name: 'Talk', relativePath: 'talk.yarn'),
    ],
    trainers: [
      if (trainer)
        const ProjectTrainerEntry(
          id: 'jeremy',
          name: 'Jeremy',
          trainerClass: 'Hiker',
          team: [ProjectTrainerPokemonEntry(speciesId: 'machop', level: 20)],
        ),
    ],
    scenes: [
      SceneAsset(
        id: 'stop-route',
        name: 'Stop this instance route',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'stop',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setMapEventInstanceBoolean(
                  mapId: _mapId,
                  eventId: _id,
                  key: 'npc.autonomousRouteStopped',
                  value: true,
                ),
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'begin',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'stop',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'done',
              fromNodeId: 'stop',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
          ],
        ),
      ),
    ],
  ),
  map: MapData(
    id: _mapId,
    name: 'Center',
    size: const GridSize(width: 8, height: 5),
    layers: [
      MapLayer.collision(
        id: 'floor',
        name: 'Floor',
        collisions: List.generate(
          40,
          (index) => blockEast && index == 2 * 8 + 3,
        ),
      ),
    ],
    entities: [
      if (v2)
        const MapEntity(
          id: 'stop-switch',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 0, y: 3),
        ),
      const MapEntity(
        id: 'spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 0, y: 4),
        blocksMovement: false,
        spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
      ),
      MapEntity(
        id: _id,
        kind: MapEntityKind.npc,
        pos: _origin,
        presentation: pageMovement == null && !contactEvent
            ? null
            : MapEntityPresentation(
                variants: [
                  if (pageMovement != null)
                    MapEntityPresentationVariant(
                      id: 'changed',
                      condition: NarrativeEventConditionExpression.leaf(
                        NarrativeEventCondition.mapEventInstanceBoolean(
                          mapId: _mapId,
                          eventId: _id,
                          key: 'npc.autonomousRouteStopped',
                          expectedValue: true,
                        ),
                      ),
                      characterId: pageAppearanceChange
                          ? 'alternate-character'
                          : 'npc-character',
                      blocksMovement: !pageAppearanceChange,
                      interactionMode: pageAppearanceChange
                          ? MapEntityInteractionMode.overlap
                          : MapEntityInteractionMode.front,
                      facing: pageAppearanceChange
                          ? EntityFacing.west
                          : EntityFacing.north,
                      movement: pageMovement,
                    ),
                  MapEntityPresentationVariant(
                    id: 'moving',
                    condition: NarrativeEventConditionExpression.all([]),
                    characterId: 'npc-character',
                    blocksMovement: true,
                    startsOnNpcContact: startsOnNpcContact,
                    facing: EntityFacing.north,
                    movement: const MapEntityNpcMovementConfig(
                      mode: MapEntityNpcMovementMode.fixedRoute,
                      routeSteps: [
                        MapEntityNpcRouteStep.move(
                          direction: EntityFacing.east,
                        ),
                        MapEntityNpcRouteStep.move(
                          direction: EntityFacing.west,
                        ),
                      ],
                      pauseDurationMs: 1600,
                      stepDurationMs: 250,
                    ),
                  ),
                ],
              ),
        npc: MapEntityNpcData(
          characterId: 'npc-character',
          facing: EntityFacing.north,
          dialogue: const DialogueRef(dialogueId: 'talk'),
          defeatDialogueRef: const DialogueRef(dialogueId: 'talk'),
          trainerId: trainer ? 'jeremy' : null,
          lineOfSightRange: trainer ? 4 : 0,
          movement: MapEntityNpcMovementConfig(
            mode: MapEntityNpcMovementMode.fixedRoute,
            routeSteps: randomFacing
                ? const [MapEntityNpcRouteStep.randomFacing()]
                : randomMove
                ? const [MapEntityNpcRouteStep.randomMove()]
                : turnOnly
                ? const [
                    MapEntityNpcRouteStep.face(direction: EntityFacing.west),
                    MapEntityNpcRouteStep.face(direction: EntityFacing.north),
                  ]
                : const [
                    MapEntityNpcRouteStep.move(direction: EntityFacing.east),
                    MapEntityNpcRouteStep.move(direction: EntityFacing.west),
                  ],
            suspendWhenInstanceBoolean: suspend
                ? MapEntityNpcRouteInstanceBoolean(
                    key: 'npc.autonomousRouteStopped',
                  )
                : null,
            pauseDurationMs: 1600,
            stepDurationMs: 250,
          ),
        ),
      ),
    ],
  ),
);

final class _FixedRouteGame extends PlayableMapGame {
  _FixedRouteGame({
    required super.bundle,
    super.initialGameState,
    super.initialMapActivationReason,
    super.encounterRandom,
    super.npcRouteRandom,
    super.narrativeRuntimeActivityGate,
    super.beforeNarrativeAuthorityPreparation,
  }) : super(
         projectFilePath: '/tmp/fixed-route-player/project.json',
         dialogueSessionLoader: (_) async => DialogueSession.start(
           parseYarnFile(
             'title: Start\n---\nEvery type is stronger than some types.\n===\n',
           ),
           'Start',
         ),
       );
  @override
  bool get isLoaded => true;
}

Future<PlayableMapGame> _load(
  RuntimeMapBundle bundle, {
  GameState? state,
  math.Random? encounterRandom,
  math.Random? npcRouteRandom,
  NarrativeRuntimeActivityGate? narrativeRuntimeActivityGate,
  Future<void> Function(NarrativeEventOccurrence occurrence)?
  beforeNarrativeAuthorityPreparation,
}) async {
  final game = _FixedRouteGame(
    bundle: bundle,
    initialGameState: state,
    encounterRandom: encounterRandom,
    npcRouteRandom: npcRouteRandom,
    narrativeRuntimeActivityGate: narrativeRuntimeActivityGate,
    beforeNarrativeAuthorityPreparation: beforeNarrativeAuthorityPreparation,
    initialMapActivationReason: state == null
        ? MapActivationReason.initialBoot
        : MapActivationReason.saveRestore,
  );
  addTearDown(game.onRemove);
  game.onGameResize(Vector2(320, 240));
  await game.onLoad();
  await _until(
    game,
    () =>
        game.debugCompletedMapActivationDispatchCount > 0 &&
        !game.debugIsMapActivationDispatchInFlight,
    maxTicks: 2000,
  );
  return game;
}

Future<void> _pump(PlayableMapGame game, {required int milliseconds}) async {
  for (var elapsed = 0; elapsed < milliseconds; elapsed += 16) {
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _until(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 300,
}) async {
  for (var tick = 0; tick < maxTicks; tick++) {
    if (done()) return;
    game.update(.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Native fixed route did not reach the expected Player state.');
}

final class _CountingRandom implements math.Random {
  _CountingRandom(this.values);
  final List<int> values;
  var draws = 0;
  @override
  int nextInt(int max) => values[draws++ % values.length] % max;
  @override
  bool nextBool() => nextInt(2) == 0;
  @override
  double nextDouble() => nextInt(1000000) / 1000000;
}
