import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/presentation/flame/flame_cinematic_media_playback_adapter.dart';
import 'package:map_runtime/src/presentation/flame/player_component.dart';
import 'package:map_runtime/src/presentation/flame/overworld_render_priority.dart';
import 'package:map_runtime/src/presentation/flame/overworld_actor_component.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart' show RuntimeDialogueSessionLoader;
import 'package:map_runtime/src/presentation/flame/warp_transition_overlay_component.dart';
import 'package:path/path.dart' as p;

void main() {
  for (final npc in [false, true]) {
    test('visibility route waits for movement and explicitly restores pixels npc=$npc', () async {
      final fixture = await _fixture(sourceSize: const GridSize(width: 5, height: 5),
        saveRepository: _MemorySaveRepository(), solidCharacter: true,
        sourceEntities: npc ? [_routeDoor.copyWith(pos: const GridPos(x: 3, y: 2))] : [],
        characters: npc ? [_timingPlayerCharacter().copyWith(id: _routeDoorCharacter.id)] : []);
      final game = fixture.game;
      bool visible() => npc ? game.debugIsNpcActorVisible('route-door') == true : game.debugIsPlayerVisible;
      final execution = game.debugExecuteSceneInteractiveCommand(_actorRoute([
        {'kind': 'move', 'direction': 'north', 'durationMs': 250},
        {'kind': 'visibility', 'visible': false},
        {'kind': 'wait', 'durationMs': 250},
        {'kind': 'visibility', 'visible': true},
      ], entityId: npc ? 'route-door' : null));
      await Future<void>.delayed(Duration.zero);
      game.update(.125);
      await Future<void>.delayed(Duration.zero);
      expect(visible(), isTrue);
      for (var tick = 0; tick < 40 && visible(); tick++) {
        game.update(.025); await Future<void>.delayed(Duration.zero);
      }
      expect(visible(), isFalse);
      expect(npc ? game.debugMapEntityPosition('route-door') : game.debugPlayerGridPosition,
        npc ? const GridPos(x: 3, y: 1) : const GridPos(x: 1, y: 0));
      final actor = npc ? game.world.children.whereType<OverworldActorComponent>().single
        : game.world.children.whereType<PlayerComponent>().single;
      final sample = actor.position + actor.size / 2;
      expect((await _nativeWorldPixel(game, sample))[3], 0);
      expect(await game.saveGame(), isFalse);
      expect(await _finishActorRoute(game, execution), 'completed');
      await Future<void>.delayed(Duration.zero);
      game.update(.025);
      await Future<void>.delayed(Duration.zero);
      game.update(0);
      await game.ready();
      final restoredActor = npc ? game.world.children.whereType<OverworldActorComponent>().single
        : game.world.children.whereType<PlayerComponent>().single;
      final restoredSample = restoredActor.position + restoredActor.size / 2;
      expect((await _nativeWorldPixel(game, restoredSample))[3], greaterThan(0),
        reason: '$restoredSample pos=${restoredActor.position} size=${restoredActor.size} scale=${restoredActor.scale} visible=${visible()} present=${restoredActor is OverworldActorComponent ? restoredActor.isGameplayPresent : true} tileImages=${restoredActor is OverworldActorComponent ? restoredActor.tileImages.keys : []} children=${game.world.children.length}');
      expect(visible(), isTrue);
      expect(game.debugIsGameplayInputLocked, isFalse);
      expect(await game.saveGame(), isTrue);
    });
  }
  test('visibility route never hides a player when the previous move is blocked', () async {
    final fixture = await _fixture(sourceCollisionCells: [const GridPos(x: 0, y: 1)]);
    final game = fixture.game;
    final execution = game.debugExecuteSceneInteractiveCommand(_actorRoute([
      {'kind': 'move', 'direction': 'west', 'durationMs': 250},
      {'kind': 'visibility', 'visible': false},
    ]));
    expect(await _finishActorRoute(game, execution), 'blocked');
    expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
    expect(game.debugIsPlayerVisible, isTrue);
  });
  test('visibility route is compensated after a later scene failure', () async {
    final original = _actorRewardScene(failingDialogue: true);
    final routeScene = SceneAsset(id: original.id, name: original.name,
      graph: SceneGraph(startNodeId: original.graph.startNodeId, edges: original.graph.edges
        .where((e) => !const ['hide-blocked', 'show-blocked'].contains(e.id)).toList(),
        nodes: [for (final n in original.graph.nodes)
          if (n.id == 'hide' || n.id == 'show') SceneNode(id: n.id, kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(SceneInteractiveCommand.wait(durationMs: 1)))
          else if (n.id == 'route') SceneNode(id: n.id, kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(_actorRoute([
              {'kind': 'move', 'direction': 'west', 'durationMs': 250},
              {'kind': 'visibility', 'visible': false},
            ])))
          else n]));
    PlayableMapGame? active;
    var sawHiddenAfterMove = false;
    final fixture = await _fixture(scenes: [routeScene], dialogues: [_actorDialogueEntry], narrativeV2: true,
      dialogueSessionLoader: (_) async {
        sawHiddenAfterMove = active!.debugPlayerGridPosition == const GridPos(x: 0, y: 1) &&
          !active.debugIsPlayerVisible;
        throw StateError('Intentional failure after route visibility');
      });
    final game = active = fixture.game;
    final before = game.gameStateSnapshot.toJson();
    final result = await _finishActorScene(game, game.debugExecuteNarrativeSceneForTest(
      NarrativeSceneExecutionRequest(eventId: 'actor-event', sceneId: routeScene.id,
        executionId: 'route-visibility-rollback', gameState: game.gameStateSnapshot)));
    expect(result, isA<NarrativeSceneExecutionFailed>());
    expect(sawHiddenAfterMove, isTrue);
    expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
    expect(game.debugIsPlayerVisible, isTrue);
    expect(game.gameStateSnapshot.toJson(), before);
    expect(game.debugIsGameplayInputLocked, isFalse);
  });
  for (final cancelled in [false, true]) {
    test('native scene finalizer restores effects without a reset route cancelled=$cancelled', () async {
      final saves = _MemorySaveRepository();
      final fixture = await _fixture(warpArrival: true, narrativeV2: true,
        sourceSize: const GridSize(width: 4, height: 4), saveRepository: saves,
        scenes: [_nativeTransientScene(omitRestoration: true)]);
      final game = fixture.game;
      final execution = game.debugExecuteNarrativeSceneForTest(NarrativeSceneExecutionRequest(
        eventId: 'native-event', sceneId: 'native-transient', executionId: 'native-finalizer', gameState: game.gameStateSnapshot));
      for (var tick = 0; tick < 80 && game.gameStateSnapshot.currentMapId != 'target'; tick++) {
        await Future<void>.delayed(Duration.zero);
        game.update(.025);
      }
      expect(game.gameStateSnapshot.currentMapId, 'target');
      final player = game.world.children.whereType<PlayerComponent>().single;
      expect(player.priority, greaterThan(overworldForegroundRenderPriority));
      expect(await game.saveGame(), isFalse);
      if (cancelled) game.onRemove();
      final result = await _finishActorScene(game, execution);
      expect(result, cancelled ? isA<NarrativeSceneExecutionFailed>() : isA<NarrativeSceneExecutionCompleted>());
      expect(player.priority, overworldActorRenderPriority(player.footPoint.y));
      expect(game.debugIsGameplayInputLocked, isFalse);
      if (!cancelled) {
        expect(await game.saveGame(), isTrue);
        expect(jsonEncode(game.gameStateSnapshot.toJson()), isNot(contains('renderAboveMap')));
      }
    });
  }

  test('native NPC diagonal uses one motion and restores depth after interruption', () async {
    final fixture = await _fixture(sourceSize: const GridSize(width: 5, height: 5),
      sourceEntities: [_routeDoor.copyWith(pos: const GridPos(x: 3, y: 3))], characters: [_routeDoorCharacter]);
    final game = fixture.game;
    final actor = game.world.children.whereType<OverworldActorComponent>().single;
    final before = actor.position.clone();
    final execution = game.debugExecuteSceneInteractiveCommand(_actorRoute([
      {'kind': 'through', 'enabled': true}, {'kind': 'renderAboveMap', 'enabled': true},
      {'kind': 'moveDiagonal', 'horizontal': 'west', 'vertical': 'north', 'durationMs': 250},
    ], entityId: 'route-door'));
    await Future<void>.delayed(Duration.zero);
    game.update(.125);
    await Future<void>.delayed(Duration.zero);
    expect(actor.position.x, lessThan(before.x));
    expect(actor.position.y, lessThan(before.y));
    expect(actor.priority, greaterThan(overworldForegroundRenderPriority));
    expect(await _finishActorRoute(game, execution), 'completed');
    expect(actor.gridPos, const GridPos(x: 2, y: 2));
    expect(actor.priority, overworldActorRenderPriority(actor.depthSortY));
    final interrupted = game.debugExecuteSceneInteractiveCommand(_actorRoute([
      {'kind': 'renderAboveMap', 'enabled': true}, {'kind': 'wait', 'durationMs': 1000},
    ], entityId: 'route-door'));
    final failure = expectLater(interrupted, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    game.onRemove();
    await failure;
    expect(actor.priority, overworldActorRenderPriority(actor.depthSortY));
  });

  test('native entity scene flags cannot elevate an identically named actor after transfer', () async {
    final fixture = await _fixture(warpArrival: true, narrativeV2: true,
      sourceSize: const GridSize(width: 4, height: 4),
      sourceEntities: [_routeDoor], targetEntities: [_routeDoor], characters: [_routeDoorCharacter],
      scenes: [_nativeTransientScene(actorId: 'route-door')]);
    final game = fixture.game;
    var sourceAbove = false, targetNormal = false;
    final execution = game.debugExecuteNarrativeSceneForTest(NarrativeSceneExecutionRequest(
      eventId: 'native-event', sceneId: 'native-transient', executionId: 'native-entity-scope', gameState: game.gameStateSnapshot));
    final result = await _finishActorScene(game, execution, observe: () {
      final actors = game.world.children.whereType<OverworldActorComponent>().toList();
      if (game.gameStateSnapshot.currentMapId == 'source') {
        sourceAbove |= actors.any((actor) => actor.priority > overworldForegroundRenderPriority);
      } else if (actors.isNotEmpty) {
        targetNormal |= actors.every((actor) => actor.priority < overworldForegroundRenderPriority);
      }
    });
    expect(result, isA<NarrativeSceneExecutionCompleted>());
    expect(sourceAbove, isTrue);
    expect(targetNormal, isTrue);
    expect(game.world.children.whereType<OverworldActorComponent>()
      .every((actor) => actor.priority < overworldForegroundRenderPriority), isTrue);
  });

  test('native render priority changes foreground pixels and restores them', () async {
    final fixture = await _fixture();
    final game = fixture.game;
    final player = game.world.children.whereType<PlayerComponent>().single;
    game.update(0);
    final foreground = RectangleComponent(position: player.position.clone(), size: player.size.clone(),
      priority: overworldForegroundRenderPriority, paint: ui.Paint()..color = const ui.Color(0xFFFF0000));
    game.world.add(foreground);
    await game.ready();
    final sample = player.position + player.size / 2;
    expect(await _nativeWorldPixel(game, sample), [255, 0, 0, 255]);
    final execution = game.debugExecuteSceneInteractiveCommand(_actorRoute([
      {'kind': 'renderAboveMap', 'enabled': true}, {'kind': 'wait', 'durationMs': 100},
    ]));
    await Future<void>.delayed(Duration.zero);
    game.update(.025);
    await Future<void>.delayed(Duration.zero);
    final above = await _nativeWorldPixel(game, sample);
    expect(above, isNot([255, 0, 0, 255]));
    expect(above[2], greaterThan(0));
    expect(await _finishActorRoute(game, execution), 'completed');
    game.update(0);
    expect(await _nativeWorldPixel(game, sample), [255, 0, 0, 255]);
  });

  for (final failingAfterWarp in [false, true]) {
    test('native scene transient flags follow the player across transfer failure=$failingAfterWarp', () async {
      PlayableMapGame? active;
      final sourceBefore = <String, dynamic>{};
      final fixture = await _fixture(warpArrival: true, narrativeV2: true,
        sourceSize: const GridSize(width: 4, height: 4),
        targetEntities: const [MapEntity(id: 'solid', kind: MapEntityKind.custom,
          pos: GridPos(x: 1, y: 1), blocksMovement: true)],
        scenes: [_nativeTransientScene(failingAfterWarp: failingAfterWarp)],
        dialogues: failingAfterWarp ? [_actorDialogueEntry] : [],
        dialogueSessionLoader: (_) async => throw StateError('Failure after scoped transfer'));
      final game = fixture.game;
      active = game;
      sourceBefore.addAll(game.gameStateSnapshot.toJson());
      var sawSourceAbove = false, sawTargetAbove = false;
      final saveChecks = <Future<bool>>[];
      final execution = game.debugExecuteNarrativeSceneForTest(NarrativeSceneExecutionRequest(
        eventId: 'native-event', sceneId: 'native-transient', executionId: 'native-scope', gameState: game.gameStateSnapshot));
      final result = await _finishActorScene(game, execution, observe: () {
        final player = active!.world.children.whereType<PlayerComponent>().single;
        if (player.priority > overworldForegroundRenderPriority) {
          if (game.gameStateSnapshot.currentMapId == 'target') {
            sawTargetAbove = true;
          } else {
            sawSourceAbove = true;
          }
          if (saveChecks.isEmpty) saveChecks.add(game.saveGame());
        }
      });
      expect(sawSourceAbove, isTrue);
      expect(sawTargetAbove, isTrue);
      expect(await Future.wait(saveChecks), [false]);
      if (failingAfterWarp) {
        expect(result, isA<NarrativeSceneExecutionFailed>());
        expect(game.gameStateSnapshot.toJson(), sourceBefore);
        expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
      } else {
        expect(result, isA<NarrativeSceneExecutionCompleted>());
        expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
        expect((result as NarrativeSceneExecutionCompleted).updatedGameState.currentMapId, 'target');
      }
      final player = game.world.children.whereType<PlayerComponent>().single;
      expect(player.priority, overworldActorRenderPriority(player.footPoint.y));
      expect(game.debugIsGameplayInputLocked, isFalse);
      expect(jsonEncode(game.gameStateSnapshot.toJson()), isNot(contains('renderAboveMap')));
    });
  }

  test('native diagonal route interpolates both axes and restores render priority', () async {
    final fixture = await _fixture(sourceSize: const GridSize(width: 4, height: 4), saveRepository: _MemorySaveRepository());
    final game = fixture.game;
    final player = game.world.children.whereType<PlayerComponent>().single;
    final before = player.position.clone();
    final execution = game.debugExecuteSceneInteractiveCommand(_actorRoute([
      {'kind': 'renderAboveMap', 'enabled': true},
      {'kind': 'moveDiagonal', 'horizontal': 'east', 'vertical': 'north', 'durationMs': 250},
    ]));
    await Future<void>.delayed(Duration.zero);
    game.update(.125);
    await Future<void>.delayed(Duration.zero);
    expect(player.position.x, greaterThan(before.x));
    expect(player.position.y, lessThan(before.y));
    expect(player.priority, greaterThan(overworldForegroundRenderPriority));
    expect(await game.saveGame(), isFalse);
    expect(await _finishActorRoute(game, execution), 'completed');
    expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 0));
    expect(player.priority, overworldActorRenderPriority(player.footPoint.y));
    expect(await game.saveGame(), isTrue);
  });

  test('multiple edge neighbors select the crossing span and preserve the return', () async {
    final fixture = await _fixture(sourceSize: const GridSize(width: 2, height: 8), targetSize: const GridSize(width: 3, height: 4), offset: 4, extraConnections: const [MapConnection(direction: MapConnectionDirection.east, targetMapId: 'other')], extraMaps: const [MapData(id: 'other', name: 'Other', size: GridSize(width: 3, height: 4), connections: [MapConnection(direction: MapConnectionDirection.west, targetMapId: 'source')])]);
    await fixture.game.debugLoadRuntimeMapBundleCachedForTest('other');
    await _move(fixture.game, RuntimeInputControl.right);
    expect(fixture.game.gameStateSnapshot.currentMapId, 'other');
    expect(fixture.game.gameStateSnapshot.playerPosition, const GridPos(x: 0, y: 1));
    await _move(fixture.game, RuntimeInputControl.left);
    expect(fixture.game.gameStateSnapshot.currentMapId, 'source');
    expect(fixture.game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 1));
    for (var step = 0; step < 4; step++) {
      await _move(fixture.game, RuntimeInputControl.down);
    }
    expect(fixture.game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 5));
    await _move(fixture.game, RuntimeInputControl.right);
    expect(fixture.game.gameStateSnapshot.currentMapId, 'target');
    expect(fixture.game.gameStateSnapshot.playerPosition, const GridPos(x: 0, y: 1));
    await _move(fixture.game, RuntimeInputControl.left);
    expect(fixture.game.gameStateSnapshot.currentMapId, 'source');
    expect(fixture.game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 5));
  });
  for (final withPolicy in [false, true]) {
    for (final checkpointBusy in [false, true]) {
      for (final logicalOnly in [false, true]) {
        test(
          'entity autorun resumes and stops on its local condition '
          'checkpointBusy=$checkpointBusy logicalOnly=$logicalOnly policy=$withPolicy',
          () async {
            final activity = NarrativeRuntimeActivityGate();
            final release = Completer<void>();
            final checkpoint = checkpointBusy
                ? activity.runCheckpoint<void>(
                    NarrativeRuntimeCheckpointOperation.load,
                    () => release.future,
                  )
                : Future<void>.value();
            addTearDown(() {
              if (!release.isCompleted) release.complete();
            });
            final fixture = await _fixture(
              narrativeRuntimeActivityGate: activity,
              mapInstanceRetentionPolicy: withPolicy ? _instancePolicy() : null,
              sourceEntities: [
                logicalOnly
                    ? _routeDoor.copyWith(
                        kind: MapEntityKind.custom,
                        npc: null,
                        blocksMovement: false,
                      )
                    : _routeDoor,
              ],
              characters: logicalOnly ? const [] : const [_routeDoorCharacter],
              scenes: [
                _instanceConditionScene(
                  SceneConditionSource.mapEventInstanceBoolean(
                    mapId: 'source',
                    eventId: 'route-door',
                    key: 'A',
                  ),
                  setBefore: true,
                ),
              ],
              eventRegistry: _autorunRegistryForTest(),
            );
            final game = fixture.game;
            final activations = game.debugCompletedMapActivationDispatchCount;
            if (checkpointBusy) {
              expect(
                game
                        .gameStateSnapshot
                        .mapInstanceWorldState
                        .instancesByMapId['source']
                        ?.eventBooleans['route-door']?['A'] ??
                    false,
                isFalse,
              );
            }
            release.complete();
            await checkpoint;
            for (var tick = 0; tick < 80; tick++) {
              game.update(.025);
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }
            expect(
              game
                      .gameStateSnapshot
                      .mapInstanceWorldState
                      .instancesByMapId['source']
                      ?.eventBooleans['route-door']?['A'] ??
                  false,
              isTrue,
            );
            expect(game.debugCompletedMapActivationDispatchCount, activations);
            final committedMoney = game.gameStateSnapshot.trainerProfile.money;
            for (var tick = 0; tick < 20; tick++) {
              game.update(.025);
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }
            expect(game.gameStateSnapshot.trainerProfile.money, committedMoney);
            expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
          },
        );
      }
    }
  }
  TestWidgetsFlutterBinding.ensureInitialized();

  group('global forced actor routes barrier', () {
    test('completes immediately when no forced route exists', () async {
      final game = (await _fixture()).game;
      expect(
        await game.debugExecuteSceneInteractiveCommand(_allActorRoutes()),
        'completed',
      );
      expect(game.debugIsGameplayInputLocked, isFalse);
      expect(game.debugPendingSceneWaitCount, 0);
    });

    test('refuses a different map even when it has no routes', () async {
      final game = (await _fixture()).game;
      await expectLater(
        game.debugExecuteSceneInteractiveCommand(
          _allActorRoutes(mapId: 'target'),
        ),
        throwsStateError,
      );
      expect(game.debugIsGameplayInputLocked, isFalse);
    });

    test('waits through the entire forced player route', () async {
      final game = (await _fixture()).game;
      final route = game.debugExecuteSceneInteractiveCommand(
        _actorRoute([
          {'kind': 'wait', 'durationMs': 150},
          {'kind': 'face', 'direction': 'south', 'durationMs': 100},
        ]),
      );
      await Future<void>.delayed(Duration.zero);
      var done = false;
      final waiting = game
          .debugExecuteSceneInteractiveCommand(_allActorRoutes())
          .then((port) {
            done = true;
            return port;
          });
      await Future<void>.delayed(Duration.zero);
      expect(done, isFalse);
      expect(game.debugIsGameplayInputLocked, isTrue);
      game.update(.15);
      await Future<void>.delayed(Duration.zero);
      expect(done, isFalse);
      expect(await _finishActorRoute(game, route), 'completed');
      expect(await _finishActorRoute(game, waiting), 'completed');
      expect(game.gameStateSnapshot.playerFacing, EntityFacing.south);
      expect(game.debugIsGameplayInputLocked, isFalse);
    });

    test(
      'advances all finite NPC moves under its save and input lock',
      () async {
        final game = (await _fixture(
          sourceSize: const GridSize(width: 4, height: 4),
          sourceEntities: [_routeDoor, _barrierNpc],
          characters: const [_routeDoorCharacter],
          saveRepository: _MemorySaveRepository(),
        )).game;
        expect(
          game
              .startScriptedNpcMove(
                entityId: 'route-door',
                destination: const GridPos(x: 0, y: 0),
              )
              .state,
          ScriptedEntityMovementState.moving,
        );
        expect(
          game
              .startScriptedNpcMove(
                entityId: 'barrier-npc',
                destination: const GridPos(x: 3, y: 0),
              )
              .state,
          ScriptedEntityMovementState.moving,
        );
        final waiting = game.debugExecuteSceneInteractiveCommand(
          _allActorRoutes(),
        );
        await Future<void>.delayed(Duration.zero);
        expect(game.debugIsGameplayInputLocked, isTrue);
        expect(await game.saveGame(), isFalse);
        expect(await game.loadGame(), isFalse);
        expect(await _finishActorRoute(game, waiting), 'completed');
        expect(
          game.debugNpcGridPosition('route-door'),
          const GridPos(x: 0, y: 0),
        );
        expect(
          game.debugNpcGridPosition('barrier-npc'),
          const GridPos(x: 3, y: 0),
        );
        expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
        expect(game.debugIsGameplayInputLocked, isFalse);
        expect(await game.saveGame(), isTrue);
      },
    );

    test('does not wait for an ordinary looping patrol', () async {
      final game = (await _fixture(
        sourceEntities: const [_routeDoor],
        characters: const [_routeDoorCharacter],
      )).game;
      game.startScriptedNpcPatrol(
        entityId: 'route-door',
        waypoints: const [GridPos(x: 0, y: 0), GridPos(x: 1, y: 0)],
      );
      game.update(0);
      expect(
        await game.debugExecuteSceneInteractiveCommand(_allActorRoutes()),
        'completed',
      );
      expect(game.debugIsGameplayInputLocked, isFalse);
    });

    test(
      'also waits for forced work started while the barrier is active',
      () async {
        final game = (await _fixture(
          sourceSize: const GridSize(width: 4, height: 4),
          sourceEntities: [_barrierNpc],
          characters: const [_routeDoorCharacter],
        )).game;
        final route = game.debugExecuteSceneInteractiveCommand(
          _actorRoute([
            {'kind': 'wait', 'durationMs': 150},
          ]),
        );
        await Future<void>.delayed(Duration.zero);
        var done = false;
        final waiting = game
            .debugExecuteSceneInteractiveCommand(_allActorRoutes())
            .then((port) {
              done = true;
              return port;
            });
        await Future<void>.delayed(Duration.zero);
        game.startScriptedNpcMove(
          entityId: 'barrier-npc',
          destination: const GridPos(x: 3, y: 0),
        );
        game.update(.15);
        await Future<void>.delayed(Duration.zero);
        expect(done, isFalse);
        expect(await _finishActorRoute(game, route), 'completed');
        expect(await _finishActorRoute(game, waiting), 'completed');
        expect(
          game.debugNpcGridPosition('barrier-npc'),
          const GridPos(x: 3, y: 0),
        );
      },
    );

    test(
      'a contact Scene commits only after the other forced actor finishes',
      () async {
        final game = (await _fixture(
          sourceSize: const GridSize(width: 4, height: 4),
          sourceEntities: [_routeDoor, _barrierNpc],
          characters: const [_routeDoorCharacter],
          saveRepository: _MemorySaveRepository(),
          eventRegistry: _entityBumpRegistry(),
          scenes: [_entityBumpScene(beforeReward: _allActorRoutes())],
        )).game;
        final before = game.gameStateSnapshot.trainerProfile.money;
        game.startScriptedNpcMove(
          entityId: 'barrier-npc',
          destination: const GridPos(x: 3, y: 0),
        );
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.up),
        );
        game.update(0);
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.up),
        );
        for (
          var turn = 0;
          turn < 200 && game.debugPendingSceneWaitCount == 0;
          turn++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        expect(game.debugPendingSceneWaitCount, 1);
        expect(game.gameStateSnapshot.trainerProfile.money, before);
        expect(await game.saveGame(), isFalse);
        await _settleEntityBump(game);
        expect(
          game.debugNpcGridPosition('barrier-npc'),
          const GridPos(x: 3, y: 0),
        );
        expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
        expect(await game.saveGame(), isTrue);
      },
    );

    test(
      'interrupts when an accepted forced actor route becomes blocked',
      () async {
        final game = (await _fixture(
          sourceCollisionCells: const [GridPos(x: 1, y: 0)],
        )).game;
        final route = game.debugExecuteSceneInteractiveCommand(
          _actorRoute([
            {'kind': 'wait', 'durationMs': 100},
            {'kind': 'move', 'direction': 'north', 'durationMs': 100},
          ]),
        );
        await Future<void>.delayed(Duration.zero);
        final waiting = game.debugExecuteSceneInteractiveCommand(
          _allActorRoutes(),
        );
        final failure = expectLater(waiting, throwsStateError);
        expect(await _finishActorRoute(game, route), 'blocked');
        for (var turn = 0; turn < 3; turn++) {
          game.update(.025);
          await Future<void>.delayed(Duration.zero);
        }
        await failure;
        expect(game.debugIsGameplayInputLocked, isFalse);
      },
    );

    test('interrupts on a same-map same-position activation change', () async {
      final game = (await _fixture(
        sameMapArrival: true,
        sourceEntities: const [_routeDoor],
        characters: const [_routeDoorCharacter],
      )).game;
      game.startScriptedNpcMove(
        entityId: 'route-door',
        destination: const GridPos(x: 0, y: 0),
      );
      final waiting = game.debugExecuteSceneInteractiveCommand(
        _allActorRoutes(),
      );
      final failure = expectLater(waiting, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      expect(game.debugPendingSceneWaitCount, 1);
      final result = await _warp(
        game,
        SceneInteractiveCommand.warp(
          destinationMapId: 'source',
          warpId: 'same',
          transition: SceneWarpTransition.none,
        ),
      );
      expect(result.port, 'completed');
      for (var turn = 0; turn < 3; turn++) {
        game.update(.025);
        await Future<void>.delayed(Duration.zero);
      }
      await failure;
      expect(game.debugIsGameplayInputLocked, isFalse);
    });

    test('interrupts and releases its lock when the runtime closes', () async {
      final game = (await _fixture(
        sourceEntities: const [_routeDoor],
        characters: const [_routeDoorCharacter],
      )).game;
      game.startScriptedNpcMove(
        entityId: 'route-door',
        destination: const GridPos(x: 0, y: 0),
      );
      final waiting = game.debugExecuteSceneInteractiveCommand(
        _allActorRoutes(),
      );
      final failure = expectLater(waiting, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      expect(game.debugIsGameplayInputLocked, isTrue);
      game.onRemove();
      await failure;
      expect(game.debugIsGameplayInputLocked, isFalse);
    });
    test('an accepted finite NPC move keeps its owner when an actor route is refused', () async {
      final game = (await _fixture(
        sourceEntities: const [_routeDoor],
        characters: const [_routeDoorCharacter],
      )).game;
      final facing = game.debugNpcActorFacing('route-door');
      game.startScriptedNpcMove(
        entityId: 'route-door',
        destination: const GridPos(x: 0, y: 0),
      );
      expect(
        await game.debugExecuteSceneInteractiveCommand(
          _actorRoute([
            {'kind': 'face', 'direction': 'north'},
          ], entityId: 'route-door'),
        ),
        'blocked',
      );
      expect(game.debugNpcActorFacing('route-door'), facing);
      expect(
        game.scriptedNpcMovementStatus('route-door').state,
        ScriptedEntityMovementState.moving,
      );
      expect(
        await _finishActorRoute(
          game,
          game.debugExecuteSceneInteractiveCommand(_allActorRoutes()),
        ),
        'completed',
      );
      expect(
        game.debugNpcGridPosition('route-door'),
        const GridPos(x: 0, y: 0),
      );
    });

    test('a finite movement failure interrupts the barrier instead of completing it', () async {
      final game = (await _fixture(
        sourceEntities: const [_routeDoor],
        characters: const [_routeDoorCharacter],
      )).game;
      game.startScriptedNpcMove(
        entityId: 'route-door',
        destination: const GridPos(x: 0, y: 0),
      );
      final waiting = game.debugExecuteSceneInteractiveCommand(
        _allActorRoutes(),
      );
      final failure = expectLater(waiting, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      expect(game.debugPendingSceneWaitCount, 1);
      game.debugSetPlayerStateForTest(
        position: const GridPos(x: 0, y: 0),
        facing: Direction.east,
      );
      for (var tick = 0; tick < 4; tick++) {
        game.update(.025);
        await Future<void>.delayed(Duration.zero);
      }
      await failure;
      expect(
        game.scriptedNpcMovementStatus('route-door').state,
        ScriptedEntityMovementState.failed,
      );
      expect(
        game.debugNpcGridPosition('route-door'),
        const GridPos(x: 1, y: 0),
      );
      expect(game.debugIsGameplayInputLocked, isFalse);
    });

    test(
      'a real Scene retains the joined player route pose and its reward',
      () async {
        final game = (await _fixture(
          narrativeV2: true,
          scenes: [_entityBumpScene(beforeReward: _allActorRoutes())],
        )).game;
        final before = game.gameStateSnapshot;
        expect(
          game
              .startScriptedNpcMove(
                entityId: 'player',
                destination: const GridPos(x: 0, y: 1),
              )
              .state,
          ScriptedEntityMovementState.moving,
        );
        NarrativeSceneExecutionResult? outcome;
        final execution = game
            .debugExecuteNarrativeSceneForTest(
              NarrativeSceneExecutionRequest(
                eventId: _entityBumpEventId,
                sceneId: 'entity-bump-scene',
                executionId: 'join-forced-player',
                gameState: before,
              ),
            )
            .then((result) => outcome = result);
        for (
          var turn = 0;
          turn < 200 && game.debugPendingSceneWaitCount == 0;
          turn++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        expect(
          game.debugPendingSceneWaitCount,
          1,
          reason: outcome is NarrativeSceneExecutionFailed
              ? '${(outcome as NarrativeSceneExecutionFailed).failure}'
              : '$outcome',
        );
        for (var tick = 0; tick < 150 && outcome == null; tick++) {
          game.update(.025);
          await Future<void>.delayed(Duration.zero);
        }
        expect(outcome, isA<NarrativeSceneExecutionCompleted>());
        await execution;
        final committed =
            (outcome as NarrativeSceneExecutionCompleted).updatedGameState;
        expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 1));
        expect(committed.playerPosition, game.debugPlayerGridPosition);
        expect(
          committed.playerPixelPosition,
          game.gameStateSnapshot.playerPixelPosition,
        );
        expect(committed.playerFacing, EntityFacing.west);
        expect(
          committed.trainerProfile.money,
          before.trainerProfile.money + 100,
        );
      },
    );

    test(
      'an active actor route refuses a new finite move for the same NPC',
      () async {
        final game = (await _fixture(
          sourceEntities: const [_routeDoor],
          characters: const [_routeDoorCharacter],
        )).game;
        final route = game.debugExecuteSceneInteractiveCommand(
          _actorRoute([
            {'kind': 'wait', 'durationMs': 100},
            {'kind': 'face', 'direction': 'north'},
          ], entityId: 'route-door'),
        );
        route.ignore();
        await Future<void>.delayed(Duration.zero);
        final before = game.scriptedNpcMovementStatus('route-door');
        final refused = game.startScriptedNpcMove(
          entityId: 'route-door',
          destination: const GridPos(x: 0, y: 0),
        );
        expect(refused.state, ScriptedEntityMovementState.failed);
        expect(game.scriptedNpcMovementStatus('route-door'), same(before));
        final waiting = game.debugExecuteSceneInteractiveCommand(
          _allActorRoutes(),
        );
        expect(await _finishActorRoute(game, route), 'completed');
        expect(await _finishActorRoute(game, waiting), 'completed');
        expect(
          game.debugNpcGridPosition('route-door'),
          const GridPos(x: 1, y: 0),
        );
        expect(game.debugNpcActorFacing('route-door'), EntityFacing.north);
      },
    );
  });
  group('native trigger bump against blocked terrain', () {
    test(
      'runs once without entering the solid trigger cell or requiring a NPC',
      () async {
        final fixture = await _fixture(
          sourceCollisionCells: const [GridPos(x: 1, y: 0)],
          sourceTriggers: const [_terrainBumpTrigger],
          scenes: [_entityBumpScene()],
          eventRegistry: _triggerBumpRegistry(),
        );
        final game = fixture.game;
        final before = game.gameStateSnapshot.trainerProfile.money;
        await _bumpUp(game);
        expect(
          game.gameStateSnapshot.playerPosition,
          const GridPos(x: 1, y: 1),
        );
        expect(game.debugIsPlayerStepping, isFalse);
        expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
        await _bumpUp(game);
        expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
      },
    );

    test(
      'does not run on primary action or successful entry into the area',
      () async {
        final fixture = await _fixture(
          sourceTriggers: const [_terrainBumpTrigger],
          scenes: [_entityBumpScene()],
          eventRegistry: _triggerBumpRegistry(),
        );
        final game = fixture.game;
        final before = game.gameStateSnapshot.trainerProfile.money;
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        );
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.primary),
        );
        await _settleEntityBump(game);
        expect(game.gameStateSnapshot.trainerProfile.money, before);
        await _bumpUp(game);
        expect(
          game.gameStateSnapshot.playerPosition,
          const GridPos(x: 1, y: 0),
        );
        expect(game.gameStateSnapshot.trainerProfile.money, before);
      },
    );

    test(
      'does not reinterpret a scripted actor route as physical input',
      () async {
        final fixture = await _fixture(
          sourceCollisionCells: const [GridPos(x: 1, y: 0)],
          sourceTriggers: const [_terrainBumpTrigger],
          scenes: [_entityBumpScene()],
          eventRegistry: _triggerBumpRegistry(),
        );
        final game = fixture.game;
        final before = game.gameStateSnapshot.trainerProfile.money;
        final output = await game.debugExecuteSceneInteractiveCommand(
          _actorRoute([
            {'kind': 'move', 'direction': 'north', 'durationMs': 250},
          ]),
        );
        expect(output, 'blocked');
        expect(game.gameStateSnapshot.trainerProfile.money, before);
        expect(
          game.gameStateSnapshot.playerPosition,
          const GridPos(x: 1, y: 1),
        );
      },
    );

    test(
      'claims held input once and prevents saving while authority is pending',
      () async {
        final entered = Completer<void>();
        final release = Completer<void>();
        addTearDown(() {
          if (!release.isCompleted) release.complete();
        });
        var preparations = 0;
        final fixture = await _fixture(
          sourceCollisionCells: const [GridPos(x: 1, y: 0)],
          sourceTriggers: const [_terrainBumpTrigger],
          scenes: [_entityBumpScene()],
          eventRegistry: _triggerBumpRegistry(
            reusePolicy: NarrativeEventReusePolicy.reusable,
          ),
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind != NarrativeEventSourceKind.triggerBump) {
              return;
            }
            preparations++;
            entered.complete();
            await release.future;
          },
        );
        final game = fixture.game;
        final before = game.gameStateSnapshot.trainerProfile.money;
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.up),
        );
        game.update(.016);
        for (var tick = 0; tick < 80 && !entered.isCompleted; tick++) {
          game.update(.016);
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        expect(entered.isCompleted, isTrue);
        expect(game.debugIsGameplayInputLocked, isTrue);
        expect(await game.saveGame(), isFalse);
        for (var tick = 0; tick < 20; tick++) {
          game.update(.016);
          await Future<void>.delayed(Duration.zero);
        }
        expect(preparations, 1);
        release.complete();
        await _settleEntityBump(game);
        for (var tick = 0; tick < 20; tick++) {
          game.update(.016);
        }
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.up),
        );
        expect(preparations, 1);
        expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
      },
    );

    test('refuses contact that changed during authority preparation', () async {
      late PlayableMapGame game;
      final fixture = await _fixture(
        sourceCollisionCells: const [GridPos(x: 1, y: 0)],
        sourceTriggers: const [_terrainBumpTrigger],
        scenes: [_entityBumpScene()],
        eventRegistry: _triggerBumpRegistry(),
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind == NarrativeEventSourceKind.triggerBump) {
            game.debugSetPlayerStateForTest(
              position: const GridPos(x: 1, y: 2),
              facing: Direction.north,
            );
          }
        },
      );
      game = fixture.game;
      final before = game.gameStateSnapshot.trainerProfile.money;
      await _bumpUp(game);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 2));
      expect(game.gameStateSnapshot.trainerProfile.money, before);
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        isEmpty,
      );
    });

    test('allows its own scene warp and preserves one-shot consumption through save reload', () async {
      final repository = _MemorySaveRepository();
      Future<PlayableMapGame> create() async => (await _fixture(
        warpArrival: true,
        saveRepository: repository,
        sourceCollisionCells: const [GridPos(x: 1, y: 0)],
        sourceTriggers: const [_terrainBumpTrigger],
        scenes: [
          _entityBumpScene(
            beforeReward: _arrivalCommand(transition: SceneWarpTransition.none),
          ),
        ],
        eventRegistry: _triggerBumpRegistry(),
      )).game;
      final game = await create();
      final before = game.gameStateSnapshot.trainerProfile.money;
      await _bumpUp(game);
      expect(game.gameStateSnapshot.currentMapId, 'target');
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 0, y: 1));
      expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
      expect(await game.saveGame(), isTrue);
      final disk = await repository.load();
      expect(
        disk!.narrativeEventProgress.consumedNarrativeEventIds,
        contains(_entityBumpEventId),
      );
      game.onRemove();
      final reopened = await create();
      expect(await reopened.loadGame(), isTrue);
      await _settleEntityBump(reopened);
      expect(reopened.gameStateSnapshot.currentMapId, 'target');
      expect(reopened.gameStateSnapshot.trainerProfile.money, before + 100);
      await _move(reopened, RuntimeInputControl.left);
      await _bumpUp(reopened);
      expect(reopened.gameStateSnapshot.currentMapId, 'source');
      expect(reopened.gameStateSnapshot.trainerProfile.money, before + 100);
    });

    test(
      'drains overlapping contacts after a consumed one-shot source',
      () async {
        final fixture = await _fixture(
          sourceCollisionCells: const [GridPos(x: 1, y: 0)],
          sourceTriggers: [
            _terrainBumpTrigger.copyWith(id: 'a'),
            _terrainBumpTrigger.copyWith(id: 'z'),
          ],
          scenes: [_entityBumpScene(), _secondTriggerBumpScene()],
          eventRegistry: _overlappingTriggerBumpRegistry(),
        );
        final game = fixture.game;
        final before = game.gameStateSnapshot.trainerProfile.money;
        await _bumpUp(game);
        expect(game.gameStateSnapshot.trainerProfile.money, before + 200);
        expect(
          game.gameStateSnapshot.playerPosition,
          const GridPos(x: 1, y: 1),
        );
        await _bumpUp(game);
        expect(game.gameStateSnapshot.trainerProfile.money, before + 300);
      },
    );

    test(
      'a same-position warp cancels the rest of the captured contact queue',
      () async {
        final fixture = await _fixture(
          sameMapArrival: true,
          sourceCollisionCells: const [GridPos(x: 1, y: 0)],
          sourceTriggers: [
            _terrainBumpTrigger.copyWith(id: 'a'),
            _terrainBumpTrigger.copyWith(id: 'z'),
          ],
          scenes: [
            _entityBumpScene(
              beforeReward: SceneInteractiveCommand.warp(
                destinationMapId: 'source',
                warpId: 'same',
                arrivalFacing: EntityFacing.north,
                transition: SceneWarpTransition.none,
              ),
            ),
            _secondTriggerBumpScene(),
          ],
          eventRegistry: _overlappingTriggerBumpRegistry(),
        );
        final game = fixture.game;
        final before = game.gameStateSnapshot.trainerProfile.money;
        final activation = game.debugCompletedMapActivationDispatchCount;
        await _bumpUp(game);
        expect(game.gameStateSnapshot.currentMapId, 'source');
        expect(
          game.gameStateSnapshot.playerPosition,
          const GridPos(x: 1, y: 1),
        );
        expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
        expect(game.debugCompletedMapActivationDispatchCount, activation + 1);
      },
    );
  });

  test(
    'world Scene wait preserves an independently running world tone',
    () async {
      final fixture = await _fixture();
      final game = fixture.game;
      expect(
        await game.debugExecuteSceneInteractiveCommand(_tone(-255, 300)),
        'completed',
      );
      var completed = false;
      final waiting = game
          .debugExecuteSceneInteractiveCommand(
            SceneInteractiveCommand.wait(durationMs: 400),
          )
          .then((port) {
            completed = true;
            return port;
          });
      game.update(.15);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      expect(game.debugWorldToneValue.red, closeTo(-127.5, .0001));
      game.update(.15);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      expect(game.debugWorldToneValue.red, -255);
      game.update(.09);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      game.update(.011);
      expect(await waiting, 'completed');
      expect(game.debugWorldToneValue.red, -255);
    },
  );

  test(
    'contact Scene awaits a world wait before committing and saving',
    () async {
      final repository = _MemorySaveRepository();
      final fixture = await _fixture(
        saveRepository: repository,
        sourceEntities: const [_routeDoor],
        characters: const [_routeDoorCharacter],
        eventRegistry: _entityBumpRegistry(),
        scenes: [
          _entityBumpScene(
            beforeReward: SceneInteractiveCommand.wait(durationMs: 300),
          ),
        ],
      );
      final game = fixture.game;
      final before = game.gameStateSnapshot.trainerProfile.money;
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.up),
      );
      game.update(.016);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.up),
      );
      for (
        var turn = 0;
        turn < 200 && game.debugPendingSceneWaitCount == 0;
        turn++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(game.debugPendingSceneWaitCount, 1);
      expect(game.debugIsNarrativeSpatialDispatchInFlight, isTrue);
      expect(game.debugIsGameplayInputLocked, isTrue);
      expect(game.gameStateSnapshot.trainerProfile.money, before);
      expect(await game.saveGame(), isFalse);
      expect(await game.loadGame(), isFalse);
      game.update(.15);
      await Future<void>.delayed(Duration.zero);
      expect(game.debugPendingSceneWaitCount, 1);
      expect(game.gameStateSnapshot.trainerProfile.money, before);
      game.update(.151);
      await _settleEntityBump(game);
      expect(game.debugPendingSceneWaitCount, 0);
      expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        contains(_entityBumpEventId),
      );
      expect(game.debugIsGameplayInputLocked, isFalse);
      expect(await game.saveGame(), isTrue);
      await _bumpUp(game);
      expect(game.debugPendingSceneWaitCount, 0);
      expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
    },
  );

  test(
    'world Scene wait uses the runtime clock without actor ownership',
    () async {
      final fixture = await _fixture(
        sourceEntities: const [_routeDoor],
        characters: const [_routeDoorCharacter],
      );
      final game = fixture.game;
      final initialPosition = game.debugPlayerGridPosition;
      final initialTone = game.debugWorldToneValue;
      var completed = false;
      final waiting = game
          .debugExecuteSceneInteractiveCommand(
            SceneInteractiveCommand.fromJson({
              'kind': 'wait',
              'durationMs': 300,
            }),
          )
          .then((port) {
            completed = true;
            return port;
          });
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(completed, isFalse);
      expect(game.debugIsGameplayInputLocked, isTrue);
      expect(await game.saveGame(), isFalse);
      expect(await game.loadGame(), isFalse);
      final route = game.debugExecuteSceneInteractiveCommand(
        _actorRoute([
          {'kind': 'move', 'direction': 'west', 'durationMs': 100},
        ], entityId: 'route-door'),
      );
      expect(await _finishActorRoute(game, route), 'completed');
      expect(completed, isFalse);
      expect(game.debugIsGameplayInputLocked, isTrue);
      expect(game.debugPlayerGridPosition, initialPosition);
      expect(game.debugWorldToneValue, initialTone);
      game.update(.1);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      game.update(.2);
      expect(await waiting, 'completed');
      expect(game.debugIsGameplayInputLocked, isFalse);
      expect(game.debugPlayerGridPosition, initialPosition);
      expect(game.debugWorldToneValue, initialTone);
    },
  );

  test(
    'world Scene wait of zero completes without a fabricated frame',
    () async {
      final fixture = await _fixture();
      expect(
        await fixture.game.debugExecuteSceneInteractiveCommand(
          SceneInteractiveCommand.fromJson({'kind': 'wait', 'durationMs': 0}),
        ),
        'completed',
      );
      expect(fixture.game.debugIsGameplayInputLocked, isFalse);
    },
  );

  test('world Scene wait is interrupted when the runtime is removed', () async {
    final fixture = await _fixture();
    final game = fixture.game;
    final waiting = game.debugExecuteSceneInteractiveCommand(
      SceneInteractiveCommand.fromJson({'kind': 'wait', 'durationMs': 300}),
    );
    final failure = expectLater(waiting, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    expect(game.debugIsGameplayInputLocked, isTrue);
    game.onRemove();
    await failure;
    expect(game.debugIsGameplayInputLocked, isFalse);
  });

  test('actor face yield keeps its pose until a new runtime update', () async {
    final fixture = await _fixture();
    final game = fixture.game;
    var completed = false;
    final execution = game
        .debugExecuteSceneInteractiveCommand(
          _actorRoute([
            {'kind': 'face', 'direction': 'north', 'yieldAfter': true},
            {'kind': 'face', 'direction': 'south'},
          ]),
        )
        .then((port) {
          completed = true;
          return port;
        });
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    expect(game.gameStateSnapshot.playerFacing, EntityFacing.north);
    game.update(0);
    expect(await execution, 'completed');
    expect(game.gameStateSnapshot.playerFacing, EntityFacing.south);
    expect(game.debugIsGameplayInputLocked, isFalse);
  });

  test(
    'actor face hold duration starts after its explicit update yield',
    () async {
      final fixture = await _fixture();
      final game = fixture.game;
      var completed = false;
      final execution = game
          .debugExecuteSceneInteractiveCommand(
            _actorRoute([
              {
                'kind': 'face',
                'direction': 'north',
                'yieldAfter': true,
                'durationMs': 100,
              },
              {'kind': 'face', 'direction': 'south'},
            ]),
          )
          .then((port) {
            completed = true;
            return port;
          });
      await Future<void>.delayed(Duration.zero);
      game.update(.09);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      expect(game.gameStateSnapshot.playerFacing, EntityFacing.north);
      game.update(.09);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      expect(game.gameStateSnapshot.playerFacing, EntityFacing.north);
      game.update(.011);
      expect(await execution, 'completed');
      expect(game.gameStateSnapshot.playerFacing, EntityFacing.south);
    },
  );

  for (final running in [false, true]) {
    test(
      'trigger-enter Scene waits for the physical step running=$running',
      () async {
        late PlayableMapGame game;
        final steppingAtPreparation = <bool>[];
        final fixture = await _fixture(
          warpArrival: true,
          playerCharacter: _timingPlayerCharacter(),
          arrivalTriggerMode: MapWarpTriggerMode.sceneOnly,
          sourceTriggers: const [
            MapTrigger(
              id: 'exit',
              type: TriggerType.event,
              area: MapRect(
                pos: GridPos(x: 0, y: 1),
                size: GridSize(width: 1, height: 1),
              ),
            ),
          ],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [
              NarrativeEventRecord.configuredStructurallyUnchecked(
                NarrativeEventDefinition(
                  id: _entityBumpEventId,
                  name: 'Exit',
                  source: NarrativeEventSourceRef.triggerEnter(
                    'source',
                    'exit',
                  ),
                  sceneId: 'entity-bump-scene',
                  conditions: const [],
                  reusePolicy: NarrativeEventReusePolicy.reusable,
                  priority: 0,
                  order: 0,
                ),
                enabled: true,
              ),
            ],
            legacyClaims: const [],
          ),
          scenes: [
            _entityBumpScene(
              beforeReward: _arrivalCommand(
                transition: SceneWarpTransition.none,
              ),
            ),
          ],
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source ==
                NarrativeEventSourceRef.triggerEnter('source', 'exit')) {
              steppingAtPreparation.add(game.debugIsPlayerStepping);
            }
          },
        );
        game = fixture.game;
        final before = game.gameStateSnapshot.trainerProfile.money;
        if (running) {
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.sprint),
          );
        }
        expect(game.inputAuthoritySnapshot.sprintAccepted, running);
        expect(
          game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.left),
          ),
          isTrue,
        );
        game.update(.001);
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.left),
        );
        expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 1));
        expect(game.debugIsPlayerStepping, isTrue);
        expect(
          _components(game)
              .whereType<PlayerComponent>()
              .single
              .debugStepAnimationState,
          running ? CharacterAnimationState.run : CharacterAnimationState.walk,
        );
        expect(game.debugPendingNarrativeTriggerEntryCount, 1);
        game.update(running ? .06 : .12);
        await Future<void>.delayed(const Duration(milliseconds: 1));
        expect(game.debugIsPlayerStepping, isTrue);
        expect(steppingAtPreparation, isEmpty);
        expect(game.debugPendingNarrativeTriggerEntryCount, 1);
        expect(game.gameStateSnapshot.currentMapId, 'source');
        expect(game.gameStateSnapshot.trainerProfile.money, before);
        for (var tick = 0; tick < 120; tick++) {
          game.update(.025);
          await Future<void>.delayed(const Duration(milliseconds: 1));
          if (game.gameStateSnapshot.currentMapId == 'target' &&
              game.gameStateSnapshot.trainerProfile.money == before + 100) {
            break;
          }
        }
        expect(steppingAtPreparation, [false]);
        expect(game.gameStateSnapshot.currentMapId, 'target');
        expect(
          game.gameStateSnapshot.playerPosition,
          const GridPos(x: 0, y: 1),
        );
        expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
        expect(game.debugPendingNarrativeTriggerEntryCount, 0);
        for (var tick = 0; tick < 8; tick++) {
          game.update(.025);
          await Future<void>.delayed(Duration.zero);
        }
        expect(steppingAtPreparation, [false]);
        expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
      },
    );
  }

  test(
    'entity autorun waits for an active Scene and resumes after release',
    () async {
      final activity = NarrativeRuntimeActivityGate();
      final lease = activity.enter(NarrativeRuntimeActivity.sceneActive);
      addTearDown(lease.close);
      final fixture = await _fixture(
        narrativeRuntimeActivityGate: activity,
        sourceEntities: const [_logicalAutorunOwner],
        scenes: [
          _instanceConditionScene(_autorunBooleanSource(), setBefore: true),
        ],
        eventRegistry: _autorunRegistryForTest(),
      );
      final game = fixture.game;
      final before = game.gameStateSnapshot.trainerProfile.money;
      await _pumpAutorun(game, 10);
      expect(game.gameStateSnapshot.trainerProfile.money, before);
      expect(game.debugIsEntityAutorunInFlight, isFalse);
      lease.close();
      await _pumpAutorun(game, 20);
      expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
      expect(_autorunBoolean(game), isTrue);
    },
  );

  for (final oneShot in [false, true]) {
    test(
      'entity autorun schedules only on a new update oneShot=$oneShot',
      () async {
        final fixture = await _fixture(
          sourceEntities: const [_logicalAutorunOwner],
          scenes: [_entityBumpScene()],
          eventRegistry: _autorunRegistryForTest(
            sceneId: 'entity-bump-scene',
            conditions: const [],
            reusePolicy: oneShot
                ? NarrativeEventReusePolicy.oneShot
                : NarrativeEventReusePolicy.reusable,
          ),
        );
        final game = fixture.game;
        final before = game.gameStateSnapshot.trainerProfile.money;
        game.update(.025);
        await _waitForAutorunIdle(game);
        expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
        await Future<void>.delayed(const Duration(milliseconds: 15));
        expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
        game.update(.025);
        await _waitForAutorunIdle(game);
        expect(
          game.gameStateSnapshot.trainerProfile.money,
          before + (oneShot ? 100 : 200),
        );
      },
    );
  }

  test(
    'entity autorun retries authority preparation after a checkpoint starts',
    () async {
      final activity = NarrativeRuntimeActivityGate();
      final releaseAuthority = Completer<void>();
      final authorityEntered = Completer<void>();
      final releaseCheckpoint = Completer<void>();
      var preparations = 0;
      final fixture = await _fixture(
        sourceEntities: const [_logicalAutorunOwner],
        scenes: [
          _instanceConditionScene(_autorunBooleanSource(), setBefore: true),
        ],
        eventRegistry: _autorunRegistryForTest(),
        narrativeRuntimeActivityGate: activity,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind != NarrativeEventSourceKind.entityAutorun) {
            return;
          }
          preparations++;
          if (preparations == 1) {
            authorityEntered.complete();
            await releaseAuthority.future;
          }
        },
      );
      addTearDown(() {
        if (!releaseAuthority.isCompleted) releaseAuthority.complete();
        if (!releaseCheckpoint.isCompleted) releaseCheckpoint.complete();
      });
      final game = fixture.game;
      final before = game.gameStateSnapshot.trainerProfile.money;
      game.update(.025);
      await authorityEntered.future;
      for (var tick = 0; tick < 12; tick++) {
        game.update(.025);
        await Future<void>.delayed(Duration.zero);
      }
      expect(preparations, 1);
      expect(await game.saveGame(), isFalse);
      expect(await game.loadGame(), isFalse);
      final checkpoint = activity.runCheckpoint<void>(
        NarrativeRuntimeCheckpointOperation.load,
        () => releaseCheckpoint.future,
      );
      releaseAuthority.complete();
      await _waitForAutorunIdle(game);
      expect(_autorunBoolean(game), isFalse);
      expect(game.gameStateSnapshot.trainerProfile.money, before);
      releaseCheckpoint.complete();
      await checkpoint;
      game.update(.025);
      await _waitForAutorunIdle(game);
      expect(preparations, 2);
      expect(_autorunBoolean(game), isTrue);
      expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
    },
  );

  test(
    'entity autorun cancels a pending preparation after runtime removal',
    () async {
      final release = Completer<void>();
      final entered = Completer<void>();
      final fixture = await _fixture(
        sourceEntities: const [_logicalAutorunOwner],
        scenes: [
          _instanceConditionScene(_autorunBooleanSource(), setBefore: true),
        ],
        eventRegistry: _autorunRegistryForTest(),
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind ==
              NarrativeEventSourceKind.entityAutorun) {
            entered.complete();
            await release.future;
          }
        },
      );
      addTearDown(() {
        if (!release.isCompleted) release.complete();
      });
      final game = fixture.game;
      final before = game.gameStateSnapshot;
      game.update(.025);
      await entered.future;
      game.onRemove();
      release.complete();
      await _waitForAutorunIdle(game);
      expect(
        game.gameStateSnapshot.trainerProfile.money,
        before.trainerProfile.money,
      );
      expect(
        game.gameStateSnapshot.mapInstanceWorldState,
        before.mapInstanceWorldState,
      );
    },
  );

  test(
    'entity autorun rechecks its local condition after authority awaits',
    () async {
      final release = Completer<void>();
      final entered = Completer<void>();
      final fixture = await _fixture(
        sourceEntities: const [_logicalAutorunOwner],
        scenes: [
          _instanceConditionScene(_autorunBooleanSource(), setBefore: true),
        ],
        eventRegistry: _autorunRegistryForTest(),
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind ==
              NarrativeEventSourceKind.entityAutorun) {
            entered.complete();
            await release.future;
          }
        },
      );
      addTearDown(() {
        if (!release.isCompleted) release.complete();
      });
      final game = fixture.game;
      game.update(.025);
      await entered.future;
      final result = await game.debugExecuteNarrativeSceneForTest(
        NarrativeSceneExecutionRequest(
          eventId: _entityBumpEventId,
          sceneId: 'instance-scene',
          executionId: 'intervening-authority-condition',
          gameState: game.gameStateSnapshot,
        ),
      );
      expect(result, isA<NarrativeSceneExecutionCompleted>());
      final committed =
          (result as NarrativeSceneExecutionCompleted).updatedGameState;
      expect(
        committed.mapInstanceWorldState.eventBoolean(
          committed.mapInstanceWorldState.instanceRef('source')!,
          'route-door',
          'A',
        ),
        isTrue,
      );
      release.complete();
      await _waitForAutorunIdle(game);
      expect(
        game.gameStateSnapshot.trainerProfile.money,
        committed.trainerProfile.money,
      );
      expect(_autorunBoolean(game), isTrue);
    },
  );

  test(
    'entity autorun discards an occurrence after its active map is replaced',
    () async {
      final release = Completer<void>();
      final entered = Completer<void>();
      final fixture = await _fixture(
        sourceEntities: const [_logicalAutorunOwner],
        warpArrival: true,
        arrivalTriggerMode: MapWarpTriggerMode.sceneOnly,
        scenes: [
          _instanceConditionScene(_autorunBooleanSource(), setBefore: true),
        ],
        eventRegistry: _autorunRegistryForTest(),
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind ==
              NarrativeEventSourceKind.entityAutorun) {
            entered.complete();
            await release.future;
          }
        },
      );
      addTearDown(() {
        if (!release.isCompleted) release.complete();
      });
      final game = fixture.game;
      final before = game.gameStateSnapshot.trainerProfile.money;
      game.update(.025);
      await entered.future;
      expect(
        (await _warp(
          game,
          _arrivalCommand(transition: SceneWarpTransition.none),
        )).port,
        'completed',
      );
      expect(game.gameStateSnapshot.currentMapId, 'target');
      release.complete();
      await _waitForAutorunIdle(game);
      expect(game.gameStateSnapshot.trainerProfile.money, before);
      expect(
        game.gameStateSnapshot.mapInstanceWorldState.instanceRef('source'),
        isNull,
      );
      expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
    },
  );

  for (final onAnchor in [false, true]) {
    test(
      'entity autorun sets the local flag outside its anchor branch onAnchor=$onAnchor',
      () async {
        final fixture = await _fixture(
          sourceEntities: const [_logicalAutorunOwner],
          scenes: [_autorunAnchorScene()],
          eventRegistry: _autorunRegistryForTest(sceneId: 'autorun-anchor'),
        );
        final game = fixture.game;
        if (onAnchor) {
          game.debugSetPlayerStateForTest(
            position: const GridPos(x: 1, y: 0),
            facing: Direction.south,
          );
        }
        await _pumpAutorunUntil(game, () => _autorunBoolean(game));
        expect(_autorunBoolean(game), isTrue);
        expect(
          game.gameStateSnapshot.playerPosition,
          const GridPos(x: 1, y: 1),
        );
        expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
      },
    );
  }

  for (final sortBy in ['priority', 'order', 'eventId']) {
    test(
      'entity autorun selects across owners by $sortBy before another update',
      () async {
        const secondId = 'evt_019abcde-1400-7000-8000-000000000002';
        final seen = <String>[];
        final first = _autorunRegistryForTest(
          sceneId: 'entity-bump-scene',
          conditions: const [],
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: sortBy == 'priority' ? 2 : 0,
          order: sortBy == 'order' ? 0 : 1,
        ).records.single;
        final second = _autorunRegistryForTest(
          sceneId: 'entity-bump-scene',
          conditions: const [],
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          eventId: secondId,
          entityId: 'other-owner',
          priority: 0,
          order: 1,
        ).records.single;
        final fixture = await _fixture(
          sourceEntities: [
            _logicalAutorunOwner,
            _logicalAutorunOwner.copyWith(id: 'other-owner'),
          ],
          scenes: [_entityBumpScene()],
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: [second, first],
            legacyClaims: const [],
          ),
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind ==
                NarrativeEventSourceKind.entityAutorun) {
              seen.add(occurrence.source.toJson()['entityId']! as String);
            }
          },
        );
        final game = fixture.game;
        final before = game.gameStateSnapshot.trainerProfile.money;
        game.update(.025);
        await _waitForAutorunIdle(game);
        expect(seen, ['route-door']);
        expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
        game.update(.025);
        await _waitForAutorunIdle(game);
        expect(seen, ['route-door', 'other-owner']);
        expect(game.gameStateSnapshot.trainerProfile.money, before + 200);
      },
    );
  }

  for (final withPolicy in [false, true]) {
    test(
      'entity autorun keeps an ineligible owner quiet through movement and same-map warp policy=$withPolicy',
      () async {
        final fixture = await _fixture(
          mapInstanceRetentionPolicy: withPolicy ? _instancePolicy() : null,
          gameState: _autorunInitialState(true),
          sourceEntities: const [_logicalAutorunOwner],
          sourceWarps: const [_autorunSourceArrival],
          scenes: [
            _instanceConditionScene(_autorunBooleanSource(), setBefore: true),
          ],
          eventRegistry: _autorunRegistryForTest(),
        );
        final game = fixture.game;
        final before = game.gameStateSnapshot;
        await _move(game, RuntimeInputControl.left);
        expect(
          game.gameStateSnapshot.playerPosition,
          const GridPos(x: 0, y: 1),
        );
        final result = await _warp(
          game,
          SceneInteractiveCommand.warp(
            destinationMapId: 'source',
            warpId: 'autorun-source-arrival',
            transition: SceneWarpTransition.none,
          ),
        );
        expect(result.port, 'completed');
        await _pumpAutorun(game, 10);
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.instanceRef('source'),
          before.mapInstanceWorldState.instanceRef('source'),
        );
        expect(_autorunBoolean(game), isTrue);
        expect(
          game.gameStateSnapshot.trainerProfile.money,
          before.trainerProfile.money,
        );
        expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
      },
    );

    test(
      'entity autorun recreates its local state after a different-map warp policy=$withPolicy',
      () async {
        final fixture = await _fixture(
          mapInstanceRetentionPolicy: withPolicy ? _instancePolicy() : null,
          warpArrival: true,
          arrivalTriggerMode: MapWarpTriggerMode.sceneOnly,
          sourceWarps: const [_autorunSourceArrival],
          sourceEntities: const [_logicalAutorunOwner],
          scenes: [
            _instanceConditionScene(_autorunBooleanSource(), setBefore: true),
          ],
          eventRegistry: _autorunRegistryForTest(),
        );
        final game = fixture.game;
        final initial = game.gameStateSnapshot;
        await _pumpAutorun(game, 15);
        expect(
          game.gameStateSnapshot.trainerProfile.money,
          initial.trainerProfile.money + 100,
        );
        expect(
          (await _warp(
            game,
            _arrivalCommand(transition: SceneWarpTransition.none),
          )).port,
          'completed',
        );
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.instanceRef('source'),
          isNot(initial.mapInstanceWorldState.instanceRef('source')),
        );
        if (withPolicy) expect(_autorunBoolean(game), isFalse);
        expect(
          (await _warp(
            game,
            SceneInteractiveCommand.warp(
              destinationMapId: 'source',
              warpId: 'autorun-source-arrival',
              transition: SceneWarpTransition.none,
            ),
          )).port,
          'completed',
        );
        await _pumpAutorun(game, 15);
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.instanceRef('source'),
          isNot(initial.mapInstanceWorldState.instanceRef('source')),
        );
        expect(
          game.gameStateSnapshot.trainerProfile.money,
          initial.trainerProfile.money + 200,
        );
        expect(_autorunBoolean(game), isTrue);
      },
    );

    test(
      'entity autorun runs only on its active map and respects connection lifetime policy=$withPolicy',
      () async {
        final fixture = await _fixture(
          mapInstanceRetentionPolicy: withPolicy ? _instancePolicy() : null,
          targetEntities: const [_logicalAutorunOwner],
          scenes: [
            _instanceConditionScene(
              _autorunBooleanSource('target'),
              setBefore: true,
            ),
          ],
          eventRegistry: _autorunRegistryForTest(mapId: 'target'),
        );
        final game = fixture.game;
        final before = game.gameStateSnapshot.trainerProfile.money;
        await _pumpAutorun(game, 15);
        expect(game.gameStateSnapshot.trainerProfile.money, before);
        await _move(game, RuntimeInputControl.right);
        await _pumpAutorun(game, 15);
        expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
        final firstRef = game.gameStateSnapshot.mapInstanceWorldState
            .instanceRef('target');
        await _move(game, RuntimeInputControl.left);
        await _pumpAutorun(game, 10);
        expect(game.gameStateSnapshot.currentMapId, 'source');
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.instanceRef('target'),
          withPolicy ? firstRef : null,
        );
        await _move(game, RuntimeInputControl.right);
        await _pumpAutorun(game, 15);
        expect(
          game.gameStateSnapshot.trainerProfile.money,
          before + (withPolicy ? 100 : 200),
        );
        expect(
          game.gameStateSnapshot.mapInstanceWorldState.instanceRef('target'),
          withPolicy ? firstRef : isNot(firstRef),
        );
      },
    );
  }

  test('entity autorun does not run in a retained neighbor and resets after eviction', () async {
    final fixture = await _fixture(
      mapInstanceRetentionPolicy: _instancePolicy(),
      targetSize: const GridSize(width: 40, height: 3),
      sourceEntities: const [_logicalAutorunOwner],
      scenes: [
        _instanceConditionScene(_autorunBooleanSource(), setBefore: true),
      ],
      eventRegistry: _autorunRegistryForTest(),
    );
    final game = fixture.game;
    final before = game.gameStateSnapshot.trainerProfile.money;
    await _pumpAutorun(game, 15);
    final originalRef = game.gameStateSnapshot.mapInstanceWorldState
        .instanceRef('source');
    expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
    await _move(game, RuntimeInputControl.right);
    game.debugSetPlayerStateForTest(
      position: const GridPos(x: 25, y: 1),
      facing: Direction.east,
    );
    await _pumpAutorun(game, 10);
    expect(
      game.gameStateSnapshot.mapInstanceWorldState.instanceRef('source'),
      isNull,
    );
    game.debugSetPlayerStateForTest(
      position: const GridPos(x: 0, y: 1),
      facing: Direction.west,
    );
    await _pumpAutorun(game, 10);
    final recreatedRef = game.gameStateSnapshot.mapInstanceWorldState
        .instanceRef('source');
    expect(recreatedRef, isNotNull);
    expect(recreatedRef, isNot(originalRef));
    expect(_autorunBoolean(game), isFalse);
    expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
    await _move(game, RuntimeInputControl.left);
    await _pumpAutorun(game, 15);
    expect(
      game.gameStateSnapshot.mapInstanceWorldState.instanceRef('source'),
      recreatedRef,
    );
    expect(game.gameStateSnapshot.trainerProfile.money, before + 200);
    expect(_autorunBoolean(game), isTrue);
  });

  for (final command in [
    _actorRoute([
      {'kind': 'move', 'direction': 'west', 'durationMs': 100},
    ]),
    _arrivalCommand(transition: SceneWarpTransition.none),
  ]) {
    test(
      'entity autorun completes its own ${command.kind.name} without stale rejection',
      () async {
        final fixture = await _fixture(
          sourceEntities: const [_logicalAutorunOwner],
          warpArrival: true,
          arrivalTriggerMode: MapWarpTriggerMode.sceneOnly,
          scenes: [_entityBumpScene(beforeReward: command)],
          eventRegistry: _autorunRegistryForTest(
            sceneId: 'entity-bump-scene',
            conditions: const [],
            reusePolicy: NarrativeEventReusePolicy.oneShot,
          ),
        );
        final game = fixture.game;
        final before = game.gameStateSnapshot.trainerProfile.money;
        await _pumpAutorunUntil(
          game,
          () => game.gameStateSnapshot.trainerProfile.money == before + 100,
        );
        expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
        expect(
          game.gameStateSnapshot.currentMapId,
          command.kind == SceneInteractiveCommandKind.warp
              ? 'target'
              : 'source',
        );
        expect(
          game.gameStateSnapshot.playerPosition,
          const GridPos(x: 0, y: 1),
        );
        expect(
          game
              .gameStateSnapshot
              .narrativeEventProgress
              .consumedNarrativeEventIds,
          contains(_entityBumpEventId),
        );
        expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
      },
    );
  }

  test('entity autorun rolls back local state and a Warp before retrying a failed Scene', () async {
    var dialogueAttempts = 0;
    final fixture = await _fixture(
      sourceEntities: const [_logicalAutorunOwner],
      warpArrival: true,
      arrivalTriggerMode: MapWarpTriggerMode.sceneOnly,
      scenes: [_autorunRollbackScene()],
      dialogues: const [_actorDialogueEntry],
      eventRegistry: _autorunRegistryForTest(sceneId: 'warp-rollback-scene'),
      dialogueSessionLoader: (_) async {
        dialogueAttempts++;
        if (dialogueAttempts == 1) {
          throw StateError('First automatic Scene fails');
        }
        return DialogueSession.start([
          YarnNode(title: 'Start', steps: [YarnStepLine('Continue')]),
        ], 'Start');
      },
    );
    final game = fixture.game;
    final before = game.gameStateSnapshot;
    game.update(.025);
    for (
      var tick = 0;
      tick < 500 && game.debugIsEntityAutorunInFlight;
      tick++
    ) {
      game.update(.025);
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(game.debugIsEntityAutorunInFlight, isFalse);
    expect(dialogueAttempts, 1);
    expect(game.gameStateSnapshot.currentMapId, 'source');
    expect(
      game.gameStateSnapshot.mapInstanceWorldState,
      before.mapInstanceWorldState,
    );
    expect(_autorunBoolean(game), isFalse);
    expect(
      game.gameStateSnapshot.trainerProfile.money,
      before.trainerProfile.money,
    );
    expect(
      game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
      isEmpty,
    );
    game.update(.025);
    for (
      var tick = 0;
      tick < 500 && game.debugIsEntityAutorunInFlight;
      tick++
    ) {
      game.update(.025);
      if (game.debugFlowPhaseName == 'dialogue') {
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.primary),
        );
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.primary),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(game.debugIsEntityAutorunInFlight, isFalse);
    expect(dialogueAttempts, 2);
    expect(game.gameStateSnapshot.currentMapId, 'target');
    expect(
      game.gameStateSnapshot.trainerProfile.money,
      before.trainerProfile.money + 100,
    );
    expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
  });

  for (final withPolicy in [false, true]) {
    for (final savedValue in [false, true]) {
      test(
        'entity autorun restores pending state from a cold disk save value=$savedValue policy=$withPolicy',
        () async {
          final directory = await Directory.systemTemp.createTemp(
            'native_autorun_save_',
          );
          addTearDown(() => directory.delete(recursive: true));
          final fixture = await _fixture(
            sourceEntities: const [_logicalAutorunOwner],
            mapInstanceRetentionPolicy: withPolicy ? _instancePolicy() : null,
            gameState: _autorunInitialState(savedValue),
            saveRepository: _AutorunFileSaveRepository(directory),
            scenes: [
              _instanceConditionScene(_autorunBooleanSource(), setBefore: true),
            ],
            eventRegistry: _autorunRegistryForTest(),
          );
          final before = fixture.game.gameStateSnapshot;
          expect(await fixture.game.saveGame(), isTrue);
          fixture.game.onRemove();
          final freshRepository = _AutorunFileSaveRepository(directory);
          final disk = await freshRepository.load();
          expect(disk, isNotNull);
          expect(disk!.mapInstanceWorldState, before.mapInstanceWorldState);
          final reopened = await _fixture(
            sourceEntities: const [_logicalAutorunOwner],
            mapInstanceRetentionPolicy: withPolicy ? _instancePolicy() : null,
            gameState: disk,
            initialMapActivationReason: MapActivationReason.saveRestore,
            saveRepository: freshRepository,
            scenes: [
              _instanceConditionScene(_autorunBooleanSource(), setBefore: true),
            ],
            eventRegistry: _autorunRegistryForTest(),
          );
          expect(
            reopened.game.gameStateSnapshot.mapInstanceWorldState,
            before.mapInstanceWorldState,
          );
          await _pumpAutorun(reopened.game, 20);
          expect(
            reopened.game.gameStateSnapshot.trainerProfile.money,
            before.trainerProfile.money + (savedValue ? 0 : 100),
          );
          expect(_autorunBoolean(reopened.game), isTrue);
          expect(
            reopened.game.gameStateSnapshot.mapInstanceWorldState.instanceRef(
              'source',
            ),
            before.mapInstanceWorldState.instanceRef('source'),
          );
          expect(await reopened.game.saveGame(), isTrue);
          final persisted = await _AutorunFileSaveRepository(directory).load();
          expect(
            persisted!.mapInstanceWorldState,
            reopened.game.gameStateSnapshot.mapInstanceWorldState,
          );
        },
      );
    }

    test(
      'entity autorun resumes a pending local condition after in-session load policy=$withPolicy',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'native_autorun_reload_',
        );
        addTearDown(() => directory.delete(recursive: true));
        final fixture = await _fixture(
          sourceEntities: const [_logicalAutorunOwner],
          mapInstanceRetentionPolicy: withPolicy ? _instancePolicy() : null,
          saveRepository: _AutorunFileSaveRepository(directory),
          scenes: [
            _instanceConditionScene(_autorunBooleanSource(), setBefore: true),
          ],
          eventRegistry: _autorunRegistryForTest(),
        );
        final game = fixture.game;
        final before = game.gameStateSnapshot;
        expect(await game.saveGame(), isTrue);
        await _pumpAutorun(game, 20);
        expect(
          game.gameStateSnapshot.trainerProfile.money,
          before.trainerProfile.money + 100,
        );
        expect(await game.loadGame(), isTrue);
        expect(_autorunBoolean(game), isFalse);
        expect(
          game.gameStateSnapshot.trainerProfile.money,
          before.trainerProfile.money,
        );
        await _pumpAutorun(game, 20);
        expect(
          game.gameStateSnapshot.trainerProfile.money,
          before.trainerProfile.money + 100,
        );
        expect(_autorunBoolean(game), isTrue);
      },
    );
  }

  for (final entry in <(RuntimeInputControl, GridPos)>[
    (RuntimeInputControl.up, const GridPos(x: 1, y: 0)),
    (RuntimeInputControl.down, const GridPos(x: 1, y: 2)),
    (RuntimeInputControl.left, const GridPos(x: 0, y: 1)),
    (RuntimeInputControl.right, const GridPos(x: 2, y: 1)),
  ]) {
    test(
      'entity bump runs its scene after blocked ${entry.$1.name} input',
      () async {
        final door = _routeDoor.copyWith(
          pos: entry.$2,
          npc: _routeDoor.npc!.copyWith(facing: EntityFacing.west),
        );
        final fixture = await _fixture(
          sourceSize: const GridSize(width: 3, height: 3),
          sourceEntities: [door],
          characters: const [_routeDoorCharacter],
          scenes: [_entityBumpScene()],
          eventRegistry: _entityBumpRegistry(),
        );
        final game = fixture.game;
        final before = game.gameStateSnapshot.trainerProfile.money;
        game.handleRuntimeInputEvent(RuntimeInputEvent.press(entry.$1));
        game.update(.016);
        game.handleRuntimeInputEvent(RuntimeInputEvent.release(entry.$1));
        await _settleEntityBump(game);
        expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
        expect(
          game.gameStateSnapshot.playerPosition,
          const GridPos(x: 1, y: 1),
        );
        expect(game.debugNpcActorFacing(door.id), EntityFacing.west);
        expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
      },
    );
  }

  test('entity bump does not run from the primary action', () async {
    final fixture = await _fixture(
      sourceFacing: EntityFacing.north,
      sourceEntities: const [_routeDoor],
      characters: const [_routeDoorCharacter],
      scenes: [_entityBumpScene()],
      eventRegistry: _entityBumpRegistry(),
    );
    final game = fixture.game;
    final before = game.gameStateSnapshot.trainerProfile.money;
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.primary),
    );
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.release(RuntimeInputControl.primary),
    );
    await _settleEntityBump(game);
    expect(game.gameStateSnapshot.trainerProfile.money, before);
    expect(
      game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
      isEmpty,
    );
  });

  test(
    'entity bump claims held input once while authority is pending',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      var preparations = 0;
      final fixture = await _fixture(
        sourceEntities: const [_routeDoor],
        characters: const [_routeDoorCharacter],
        scenes: [_entityBumpScene()],
        eventRegistry: _entityBumpRegistry(
          reusePolicy: NarrativeEventReusePolicy.reusable,
        ),
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind != NarrativeEventSourceKind.entityBump) {
            return;
          }
          preparations++;
          entered.complete();
          await release.future;
        },
      );
      final game = fixture.game;
      final before = game.gameStateSnapshot.trainerProfile.money;
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.up),
      );
      game.update(.016);
      await entered.future;
      for (var tick = 0; tick < 20; tick++) {
        game.update(.016);
        await Future<void>.delayed(Duration.zero);
      }
      expect(preparations, 1);
      expect(game.gameStateSnapshot.trainerProfile.money, before);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.release(RuntimeInputControl.up),
      );
      release.complete();
      await _settleEntityBump(game);
      expect(preparations, 1);
      expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
    },
  );

  test('entity bump allows its own Scene to move the player', () async {
    final fixture = await _fixture(
      sourceEntities: const [_routeDoor],
      characters: const [_routeDoorCharacter],
      scenes: [
        _entityBumpScene(
          beforeReward: _actorRoute([
            {'kind': 'move', 'direction': 'west', 'durationMs': 100},
          ]),
        ),
      ],
      eventRegistry: _entityBumpRegistry(),
    );
    final game = fixture.game;
    final before = game.gameStateSnapshot.trainerProfile.money;
    await _bumpUp(game);
    expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 0, y: 1));
    expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
    expect(
      game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
      contains(_entityBumpEventId),
    );
    expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
  });

  test('entity bump survives its own Warp and cold save reload', () async {
    final repository = _MemorySaveRepository();
    final fixture = await _fixture(
      warpArrival: true,
      saveRepository: repository,
      sourceEntities: const [_routeDoor],
      characters: const [_routeDoorCharacter],
      scenes: [
        _entityBumpScene(
          beforeReward: SceneInteractiveCommand.warp(
            destinationMapId: 'target',
            warpId: 'arrival',
            transition: SceneWarpTransition.none,
          ),
        ),
      ],
      eventRegistry: _entityBumpRegistry(),
    );
    final game = fixture.game;
    final before = game.gameStateSnapshot.trainerProfile.money;
    await _bumpUp(game);
    expect(game.gameStateSnapshot.currentMapId, 'target');
    expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 0, y: 1));
    expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
    expect(
      game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
      contains(_entityBumpEventId),
    );
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.warp,
    );
    expect(await game.saveGame(), isTrue);
    final saved = await repository.load();
    expect(saved, isNotNull);
    game.onRemove();
    final reopened = await _fixture(
      warpArrival: true,
      saveRepository: repository,
      sourceEntities: const [_routeDoor],
      characters: const [_routeDoorCharacter],
      scenes: [
        _entityBumpScene(
          beforeReward: SceneInteractiveCommand.warp(
            destinationMapId: 'target',
            warpId: 'arrival',
            transition: SceneWarpTransition.none,
          ),
        ),
      ],
      eventRegistry: _entityBumpRegistry(),
    );
    expect(await reopened.game.loadGame(), isTrue);
    await _settleEntityBump(reopened.game);
    expect(reopened.game.gameStateSnapshot.currentMapId, 'target');
    expect(reopened.game.gameStateSnapshot.trainerProfile.money, before + 100);
    await _move(reopened.game, RuntimeInputControl.left);
    expect(reopened.game.gameStateSnapshot.currentMapId, 'source');
    await _bumpUp(reopened.game);
    expect(reopened.game.gameStateSnapshot.currentMapId, 'source');
    expect(reopened.game.gameStateSnapshot.trainerProfile.money, before + 100);
  });

  test(
    'entity bump refuses an owner that starts moving before Scene',
    () async {
      late PlayableMapGame game;
      var preparations = 0;
      final fixture = await _fixture(
        sourceEntities: const [_routeDoor],
        characters: const [_routeDoorCharacter],
        scenes: [_entityBumpScene()],
        eventRegistry: _entityBumpRegistry(),
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind != NarrativeEventSourceKind.entityBump) {
            return;
          }
          preparations++;
          final actor = _components(game)
              .whereType<OverworldActorComponent>()
              .where(
                (candidate) => candidate.character.id == _routeDoorCharacter.id,
              )
              .single;
          expect(
            actor.startGridStep(
              to: const GridPos(x: 0, y: 0),
              facing: EntityFacing.west,
              durationSeconds: 1,
            ),
            isTrue,
          );
          expect(actor.isStepping, isTrue);
        },
      );
      game = fixture.game;
      final before = game.gameStateSnapshot.trainerProfile.money;
      await _bumpUp(game);
      expect(preparations, 1);
      expect(game.gameStateSnapshot.trainerProfile.money, before);
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        isEmpty,
      );
      expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
    },
  );

  test(
    'Scene-only arrivals preserve door reentry after owner egress',
    () async {
      final fixture = await _fixture(
        warpArrival: true,
        arrivalTriggerMode: MapWarpTriggerMode.sceneOnly,
        sourceWarps: const [
          MapWarp(
            id: 'door-arrival',
            pos: GridPos(x: 1, y: 0),
            targetMapId: 'source',
            targetPos: GridPos(x: 1, y: 0),
            triggerMode: MapWarpTriggerMode.sceneOnly,
          ),
        ],
        sourceEntities: const [_routeDoor],
        characters: const [_routeDoorCharacter],
        scenes: [
          _entityBumpScene(
            beforeReward: SceneInteractiveCommand.warp(
              destinationMapId: 'target',
              warpId: 'arrival',
              transition: SceneWarpTransition.none,
            ),
          ),
        ],
        eventRegistry: _entityBumpRegistry(
          reusePolicy: NarrativeEventReusePolicy.reusable,
        ),
      );
      final game = fixture.game;
      final before = game.gameStateSnapshot.trainerProfile.money;
      await _bumpUp(game);
      expect(game.gameStateSnapshot.currentMapId, 'target');
      expect(game.gameStateSnapshot.trainerProfile.money, before + 100);
      final returned = await _warp(
        game,
        SceneInteractiveCommand.warp(
          destinationMapId: 'source',
          warpId: 'door-arrival',
          arrivalFacing: EntityFacing.south,
          arrivalCollisionOwnerEntityId: 'route-door',
          transition: SceneWarpTransition.none,
        ),
      );
      expect(returned.port, 'completed');
      expect(game.gameStateSnapshot.currentMapId, 'source');
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 0));
      expect(
        await _finishActorRoute(
          game,
          game.debugExecuteSceneInteractiveCommand(
            _actorRoute([
              {
                'kind': 'move',
                'direction': 'south',
                'durationMs': 100,
                'initialCollisionOwnerEntityId': 'route-door',
              },
            ]),
          ),
        ),
        'completed',
      );
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 1));
      await _bumpUp(game);
      expect(game.gameStateSnapshot.currentMapId, 'target');
      expect(game.gameStateSnapshot.trainerProfile.money, before + 200);
      expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
    },
  );

  test(
    'connection rejects feet collision when the cell centre is free',
    () async {
      final fixture = await _fixture(maskPixel: (16, 24));
      final target = fixture.targetWorld;
      expect(
        target.isCellCenterBlockedLegacyForGridIndexedSystems(0, 1),
        isFalse,
      );
      expect(target.worldStaticObstaclesCollidePlayerCollisionRect(), isTrue);

      await _move(fixture.game, RuntimeInputControl.right);

      _expectRejected(fixture.game, 'Connection blocked');
    },
  );

  test(
    'connection accepts free feet when the cell centre touches a mask',
    () async {
      final fixture = await _fixture(maskPixel: (16, 16));
      final target = fixture.targetWorld;
      expect(
        target.isCellCenterBlockedLegacyForGridIndexedSystems(0, 1),
        isTrue,
      );
      expect(target.worldStaticObstaclesCollidePlayerCollisionRect(), isFalse);

      await _move(fixture.game, RuntimeInputControl.right);

      _expectArrived(fixture.game, const GridPos(x: 0, y: 1));
    },
  );

  test(
    'connection rejects a present blocking entity at canonical contact',
    () async {
      final fixture = await _fixture(blockingEntity: true);
      expect(
        fixture.targetWorld.worldStaticObstaclesCollidePlayerCollisionRect(),
        isTrue,
      );

      await _move(fixture.game, RuntimeInputControl.right);

      _expectRejected(fixture.game, 'Connection blocked');
    },
  );

  test('connection accepts a through entity at the arrival', () async {
    final fixture = await _fixture(blockingEntity: false);
    expect(
      fixture.targetWorld.worldStaticObstaclesCollidePlayerCollisionRect(),
      isFalse,
    );

    await _move(fixture.game, RuntimeInputControl.right);

    _expectArrived(fixture.game, const GridPos(x: 0, y: 1));
  });

  test(
    'connection preserves the walking restriction on an authored water cell',
    () async {
      final fixture = await _fixture(water: true);
      await _move(fixture.game, RuntimeInputControl.right);
      _expectRejected(fixture.game, 'Connection blocked');
    },
  );

  test('connection accepts an authored water cell while surfing', () async {
    final fixture = await _fixture(water: true);
    fixture.game.setPlayerMovementMode(MovementMode.surf);
    await _move(fixture.game, RuntimeInputControl.right);
    _expectArrived(fixture.game, const GridPos(x: 0, y: 1));
    expect(
      fixture.game.gameStateSnapshot.playerMovementMode,
      MovementMode.surf,
    );
  });

  test(
    'connection keeps the authored offset and accepts its in-bounds arrival',
    () async {
      final fixture = await _fixture(offset: 1);

      await _move(fixture.game, RuntimeInputControl.right);

      _expectArrived(fixture.game, const GridPos(x: 0, y: 0));
    },
  );

  test(
    'project refuses an out-of-bounds connection before runtime starts',
    () async {
      await expectLater(_fixture(offset: 4), throwsA(isA<ValidationException>()));
    },
  );

  test(
    'free reciprocal connection returns through the actual input path',
    () async {
      final fixture = await _fixture();

      await _move(fixture.game, RuntimeInputControl.right);
      _expectArrived(fixture.game, const GridPos(x: 0, y: 1));
      await _move(fixture.game, RuntimeInputControl.left);

      expect(fixture.game.gameStateSnapshot.currentMapId, 'source');
      expect(
        fixture.game.gameStateSnapshot.playerPosition,
        const GridPos(x: 1, y: 1),
      );
      expect(fixture.game.gameStateSnapshot.playerFacing, EntityFacing.west);
      expect(
        fixture.game.debugRenderedPlayerFootCell,
        const GridPos(x: 1, y: 1),
      );
      expect(fixture.game.debugCompletedMapActivationDispatchCount, 3);
      expect(
        fixture.game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.connection,
      );
      expect(fixture.game.debugLastCompletedMapActivation?.mapId, 'source');
      expect(fixture.game.debugFlowPhaseName, 'overworld');
      expect(fixture.game.debugHasPendingMapTransition, isFalse);
      expect(fixture.game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
    },
  );

  test(
    'actor route advances under its input lock and awaits the complete step',
    () async {
      final fixture = await _fixture();
      final game = fixture.game;
      var completed = false;
      final execution = game
          .debugExecuteSceneInteractiveCommand(
            _actorRoute([
              {'kind': 'wait', 'durationMs': 100},
              {'kind': 'move', 'direction': 'west', 'durationMs': 250},
            ]),
          )
          .then((result) {
            completed = true;
            return result;
          });
      await Future<void>.delayed(Duration.zero);
      expect(game.debugIsGameplayInputLocked, isTrue);
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
      expect(await game.saveGame(), isFalse);
      expect(await game.loadGame(), isFalse);
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.up),
      );
      game.update(.05);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
      game.update(.05);
      await Future<void>.delayed(Duration.zero);
      expect(game.debugIsPlayerStepping, isTrue);
      game.update(.125);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      expect(await _finishActorRoute(game, execution), 'completed');
      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 1));
      expect(game.gameStateSnapshot.playerFacing, EntityFacing.west);
      expect(game.debugIsGameplayInputLocked, isFalse);
    },
  );

  test(
    'actor route through is local and never permits leaving map bounds',
    () async {
      final fixture = await _fixture();
      final game = fixture.game;
      final execution = game.debugExecuteSceneInteractiveCommand(
        _actorRoute([
          {'kind': 'through', 'enabled': true},
          {'kind': 'move', 'direction': 'east', 'durationMs': 250},
        ]),
      );
      expect(await _finishActorRoute(game, execution), 'blocked');
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
      expect(game.debugHasPendingMapTransition, isFalse);
      expect(game.gameStateSnapshot.playerFacing, EntityFacing.east);
    },
  );

  test(
    'actor route closure interrupts a pending wait instead of succeeding',
    () async {
      final fixture = await _fixture();
      final game = fixture.game;
      final execution = game.debugExecuteSceneInteractiveCommand(
        _actorRoute([
          {'kind': 'wait', 'durationMs': 1000},
          {'kind': 'move', 'direction': 'west', 'durationMs': 250},
        ]),
      );
      final expectation = expectLater(execution, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      game.onRemove();
      await expectation;
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
    },
  );

  test(
    'actor visibility changes render state without removing a blocker',
    () async {
      final fixture = await _fixture(
        sourceEntities: [_routeDoor],
        characters: [_routeDoorCharacter],
      );
      final game = fixture.game;
      final hide = SceneInteractiveCommand.fromJson({
        'kind': 'actorVisibility',
        'target': {
          'kind': 'entity',
          'mapId': 'source',
          'entityId': 'route-door',
        },
        'visible': false,
      });
      expect(await game.debugExecuteSceneInteractiveCommand(hide), 'completed');
      expect(game.debugIsNpcActorVisible('route-door'), isFalse);
      expect(
        game.debugMapEntityPosition('route-door'),
        const GridPos(x: 1, y: 0),
      );
      final blocked = game.debugExecuteSceneInteractiveCommand(
        _actorRoute([
          {'kind': 'move', 'direction': 'north', 'durationMs': 250},
        ]),
      );
      expect(await _finishActorRoute(game, blocked), 'blocked');
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
    },
  );

  test(
    'actor route can cross the door locally and restores normal collision',
    () async {
      final fixture = await _fixture(
        sourceEntities: [_routeDoor],
        characters: [_routeDoorCharacter],
      );
      final game = fixture.game;
      for (final direction in ['north', 'south']) {
        final execution = game.debugExecuteSceneInteractiveCommand(
          _actorRoute([
            {'kind': 'through', 'enabled': true},
            {'kind': 'move', 'direction': direction, 'durationMs': 250},
            {'kind': 'through', 'enabled': false},
          ]),
        );
        expect(await _finishActorRoute(game, execution), 'completed');
      }
      final blocked = game.debugExecuteSceneInteractiveCommand(
        _actorRoute([
          {'kind': 'move', 'direction': 'north', 'durationMs': 250},
        ]),
      );
      expect(await _finishActorRoute(game, blocked), 'blocked');
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
    },
  );

  test(
    'actor route changes only the targeted entity pose and holds it',
    () async {
      final fixture = await _fixture(
        sourceEntities: [_routeDoor],
        characters: [_routeDoorCharacter],
      );
      final game = fixture.game;
      var completed = false;
      final execution = game
          .debugExecuteSceneInteractiveCommand(
            _actorRoute([
              {'kind': 'face', 'direction': 'west', 'durationMs': 100},
              {'kind': 'face', 'direction': 'north', 'durationMs': 100},
            ], entityId: 'route-door'),
          )
          .then((result) {
            completed = true;
            return result;
          });
      await Future<void>.delayed(Duration.zero);
      expect(game.debugNpcActorFacing('route-door'), EntityFacing.west);
    expect(game.debugNpcVisualFacing('route-door'), EntityFacing.west);
      expect(game.gameStateSnapshot.playerFacing, EntityFacing.east);
      game.update(.05);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      expect(game.debugNpcActorFacing('route-door'), EntityFacing.west);
      expect(await _finishActorRoute(game, execution), 'completed');
      expect(game.debugNpcActorFacing('route-door'), EntityFacing.north);
    },
  );

  test('native world Tone starts immediately without changing gameplay state', () async {
    final fixture = await _fixture();
    final game = fixture.game;
    final before = game.gameStateSnapshot.toJson();
    final port = await game.debugExecuteSceneInteractiveCommand(
      SceneInteractiveCommand.fromJson({
        'kind': 'worldTone', 'red': -255, 'green': -255,
        'blue': -255, 'gray': 0, 'durationMs': 0,
      }),
    );
    expect(port, 'completed');
    expect(game.debugWorldToneValue.red, -255);
    expect(game.gameStateSnapshot.toJson(), before);
    game.update(.5);
    expect(game.debugWorldToneValue.red, -255);
  },
  );

  test('actor route refuses invalid references before its first pose change', () async {
    final fixture = await _fixture();
    final game = fixture.game;
    final before = game.gameStateSnapshot.toJson();
    for (final command in [
      _actorRoute([{'kind': 'face', 'direction': 'north'},
        ], mapId: 'target'),
      _actorRoute([{'kind': 'face', 'direction': 'north'},
        ], entityId: 'missing'),
      _actorRoute([
        {'kind': 'face', 'direction': 'north'},
        {'kind': 'sound', 'mediaAssetId': 'missing', 'gain': 1},
      ]),
    ]) {
      expect(await game.debugExecuteSceneInteractiveCommand(command), 'blocked',
        );
      expect(game.gameStateSnapshot.toJson(), before);
    }
  },
  );

  test('actor commands refuse an NPC excluded by physical World Rules', () async {
    final fixture = await _fixture(sourceEntities: [_routeDoor], characters: [_routeDoorCharacter],
      facts: [NarrativeFactDefinition(id: 'hide-door', label: 'Hide door', defaultValue: true,
          ),
        ],
      worldRules: [WorldRuleDefinition(id: 'hide-rule', label: 'Hide actor',
        source: const WorldRuleSource(kind: WorldRuleSourceKind.fact, sourceId: 'hide-door', predicate: WorldRuleSourcePredicate.isTrue,
            ),
        target: const WorldRuleTarget(kind: WorldRuleTargetKind.mapEntity, mapId: 'source', entityId: 'route-door',
            ),
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      gameState: const GameState(saveId: 'actor-presence', currentMapId: 'source', playerPosition: GridPos(x: 1, y: 1), playerFacing: EntityFacing.east,
        metadata: {'pokemap.npcPresence.source.route-door': 'present'},
        ),
    );
    final game = fixture.game;
    expect(game.debugNpcVisualFacing('route-door'), EntityFacing.south);
    expect(await game.debugExecuteSceneInteractiveCommand(_actorRoute([{'kind': 'face', 'direction': 'north'},
          ], entityId: 'route-door'),
        ), 'blocked',
      );
    expect(await game.debugExecuteSceneInteractiveCommand(SceneInteractiveCommand.fromJson({
      'kind': 'actorVisibility', 'target': {'kind': 'entity', 'mapId': 'source', 'entityId': 'route-door',
            }, 'visible': false,
    }),
        ), 'blocked',
      );
    expect(game.debugNpcActorFacing('route-door'), EntityFacing.south);
    expect(game.debugIsNpcActorVisible('route-door'), isTrue);
  },
  );

  test('actor route waits for sound startup with its exact gain before moving', () async {
    final audio = _SceneSoundPort()..gate = Completer<void>();
    final fixture = await _fixture(sceneSoundEffectPlaybackPort: audio, cinematicMediaAssets: [_doorSound()],
      );
    final game = fixture.game;
    final execution = game.debugExecuteSceneInteractiveCommand(_actorRoute([
      {'kind': 'sound', 'mediaAssetId': 'door', 'gain': .8},
      {'kind': 'move', 'direction': 'west', 'durationMs': 250},
    ]),
      );
    await audio.entered.future;
    game.update(.5);
    expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
    expect(game.debugIsPlayerStepping, isFalse);
    expect(audio.calls.single.volume, .8);
    audio.gate!.complete();
    expect(await _finishActorRoute(game, execution), 'completed');
    expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 1));
  },
  );

  test('actor route commits player movement through the real Scene executor', () async {
    final fixture = await _fixture(scenes: [_actorRewardScene()], narrativeV2: true,
      );
    final game = fixture.game;
    final moneyBefore = game.gameStateSnapshot.trainerProfile.money;
    final execution = game.debugExecuteNarrativeSceneForTest(NarrativeSceneExecutionRequest(
      eventId: 'actor-event', sceneId: 'actor-scene', executionId: 'actor-success', gameState: game.gameStateSnapshot,
    ),
      );
    final result = await _finishActorScene(game, execution);
    expect(result, isA<NarrativeSceneExecutionCompleted>(), reason: result is NarrativeSceneExecutionFailed ? result.failure.toString() : null,
      );
    final state = (result as NarrativeSceneExecutionCompleted).updatedGameState;
    expect(state.playerPosition, const GridPos(x: 0, y: 1));
    expect(state.playerFacing, EntityFacing.west);
    expect(state.trainerProfile.money, moneyBefore + 100);
    expect(game.debugIsPlayerVisible, isTrue);
  },
  );

  test('actor route failure rolls back movement and visibility without a reward', () async {
    PlayableMapGame? activeGame;
    var sawCompletedRoute = false;
    final fixture = await _fixture(scenes: [_actorRewardScene(failingDialogue: true)], dialogues: [_actorDialogueEntry], narrativeV2: true,
      dialogueSessionLoader: (_) async {
        sawCompletedRoute = activeGame!.debugPlayerGridPosition == const GridPos(x: 0, y: 1);
        throw StateError('Dialogue failed after route');
      },
    );
    final game = fixture.game;
    activeGame = game;
    final before = game.gameStateSnapshot.toJson();
    final execution = game.debugExecuteNarrativeSceneForTest(NarrativeSceneExecutionRequest(
      eventId: 'actor-event', sceneId: 'actor-scene', executionId: 'actor-rollback', gameState: game.gameStateSnapshot,
    ),
      );
    expect(await _finishActorScene(game, execution), isA<NarrativeSceneExecutionFailed>(),
      );
    expect(sawCompletedRoute, isTrue);
    expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
    expect(game.debugIsPlayerVisible, isTrue);
    expect(game.gameStateSnapshot.toJson(), before);
  },
  );

  for (final entityId in <String?>[null, 'route-door']) {
    test('map event actor route restores ${entityId ?? 'player'} after a later failure', () async {
      final activity = NarrativeRuntimeActivityGate();
      PlayableMapGame? activeGame;
      var sawCompletedRoute = false;
      final fixture = await _fixture(
        sourceFacing: EntityFacing.west,
        sourceEntities: [_routeDoor],
        characters: [_routeDoorCharacter],
        scenes: [_actorRewardScene(failingDialogue: true, entityId: entityId),
          ],
        dialogues: [_actorDialogueEntry],
        narrativeRuntimeActivityGate: activity,
        events: [_actorMapEvent],
        dialogueSessionLoader: (_) async {
          final game = activeGame!;
          sawCompletedRoute = entityId == null
              ? game.debugPlayerGridPosition == const GridPos(x: 0, y: 1)
              : game.debugNpcGridPosition(entityId) == const GridPos(x: 0, y: 0) &&
                  game.debugNpcActorFacing(entityId) == EntityFacing.west;
          throw StateError('Dialogue failed after the map event route.');
        },
      );
      final game = fixture.game;
      activeGame = game;
      final before = game.gameStateSnapshot.toJson();
      expect(game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ), isTrue,
        );
      await _finishMapEventScene(game, activity, () => sawCompletedRoute);
      expect(sawCompletedRoute, isTrue);
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
      expect(game.debugNpcGridPosition('route-door'), const GridPos(x: 1, y: 0),
        );
      expect(game.debugNpcActorFacing('route-door'), EntityFacing.south);
      expect(game.debugNpcVisualFacing('route-door'), EntityFacing.south);
      expect(game.debugIsPlayerVisible, isTrue);
      expect(game.gameStateSnapshot.toJson(), before);
      expect(game.debugIsGameplayInputLocked, isFalse);
    },
    );
  }

  test('map event actor route face hold owns a patrolling NPC until completion', () async {
    final activity = NarrativeRuntimeActivityGate();
    final fixture = await _fixture(
      sourceFacing: EntityFacing.west,
      sourceEntities: [_routeDoor.copyWith(npc: const MapEntityNpcData(
        characterId: 'route-door-character',
        movement: MapEntityNpcMovementConfig(
          mode: MapEntityNpcMovementMode.patrol,
          waypoints: [GridPos(x: 1, y: 0), GridPos(x: 0, y: 0)],
          stepDurationMs: 100,
          pauseDurationMs: 0,
        ),
      ),
          ),
        ],
      characters: [_routeDoorCharacter],
      scenes: [_actorHoldScene()],
      narrativeRuntimeActivityGate: activity,
      events: [_actorMapEvent],
    );
    final game = fixture.game;
    expect(game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.primary),
    ), isTrue,
      );
    for (var tick = 0; tick < 3000; tick++) {
      if (game.debugNpcActorFacing('route-door') == EntityFacing.north) break;
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(activity.activity, NarrativeRuntimeActivity.sceneActive);
    expect(game.debugNpcActorFacing('route-door'), EntityFacing.north);
    for (var tick = 0; tick < 3; tick++) {
      game.update(.05);
      await Future<void>.delayed(Duration.zero);
    }
    expect(activity.activity, NarrativeRuntimeActivity.sceneActive);
    expect(game.debugNpcGridPosition('route-door'), const GridPos(x: 1, y: 0),
      );
    expect(game.debugNpcVisualFacing('route-door'), EntityFacing.north);
    await _finishMapEventScene(game, activity, () => true);
    expect(game.debugIsGameplayInputLocked, isFalse);
    for (var tick = 0; tick < 30; tick++) {
      game.update(.025);
      await Future<void>.delayed(Duration.zero);
      if (game.debugNpcGridPosition('route-door') == const GridPos(x: 0, y: 0)) break;
    }
    expect(game.debugNpcGridPosition('route-door'), const GridPos(x: 0, y: 0),
      );
    },
  );

  test('native world Tone advances through a no-fade map transfer', () async {
    final fixture = await _fixture(warpArrival: true);
    final game = fixture.game;
    final port = await game.debugExecuteSceneInteractiveCommand(
      SceneInteractiveCommand.fromJson({
        'kind': 'worldTone', 'red': -255, 'green': -255,
        'blue': -255, 'gray': 0, 'durationMs': 300,
      }),
    );
    expect(port, 'completed');
    game.update(.15);
    expect(game.debugWorldToneValue.red, closeTo(-127.5, .0001));
    final warp = await _warp(game, _arrivalCommand(transition: SceneWarpTransition.none),
    );
    expect(warp.port, 'completed');
    game.update(.3);
    expect(game.debugWorldToneValue.red, -255);
    expect(game.gameStateSnapshot.currentMapId, 'target');
    await game.debugExecuteSceneInteractiveCommand(
      SceneInteractiveCommand.fromJson({
        'kind': 'worldTone', 'red': 0, 'green': 0,
        'blue': 0, 'gray': 0, 'durationMs': 300,
      }),
    );
    game.update(.15);
    expect(game.debugWorldToneValue.red, closeTo(-127.5, .0001));
    game.update(.15);
    expect(game.debugWorldToneValue.red, closeTo(0, .0001));
  });

  test('native world Tone continues after a completed Scene', () async {
    final fixture = await _fixture(scenes: [_toneScene()]);
    final game = fixture.game;
    await game.debugExecuteSceneInteractiveCommand(_tone(-100, 0));
    final result = await game.debugExecuteNarrativeSceneForTest(
      NarrativeSceneExecutionRequest(
        eventId: 'tone-event', sceneId: 'tone-scene', executionId: 'tone-success',
        gameState: game.gameStateSnapshot,
      ),
    );
    expect(result, isA<NarrativeSceneExecutionCompleted>());
    expect(game.debugWorldToneValue.red, -100);
    game.update(.15);
    expect(game.debugWorldToneValue.red, closeTo(-50, .0001));
    game.update(.3);
    expect(game.debugWorldToneValue.red, closeTo(0, .0001));
  });

  test('native world Tone restores the previous value when a Scene fails', () async {
    PlayableMapGame? activeGame;
    var sawToneBeforeFailure = false;
    final fixture = await _fixture(
      dialogueSessionLoader: (_) async {
        sawToneBeforeFailure = activeGame!.debugWorldToneValue.red == -255;
        throw StateError('Injected dialogue start failure.');
      },
      scenes: [_toneScene(failingDialogue: true)],
      dialogues: const [ProjectDialogueEntry(
        id: 'missing-file', name: 'Missing file', relativePath: 'dialogues/missing.yarn',
        declaredOutcomes: [DialogueDeclaredOutcome(id: 'done', label: 'Done'),
            ],
      ),
        ],
    );
    final game = fixture.game;
    await game.debugExecuteSceneInteractiveCommand(_tone(-100, 0));
    final before = game.gameStateSnapshot.toJson();
    activeGame = game;
    final result = await game.debugExecuteNarrativeSceneForTest(
      NarrativeSceneExecutionRequest(
        eventId: 'tone-event', sceneId: 'tone-scene', executionId: 'tone-failure',
        gameState: game.gameStateSnapshot,
      ),
    );
    expect(result, isA<NarrativeSceneExecutionFailed>());
    expect(sawToneBeforeFailure, isTrue);
    expect(game.debugWorldToneValue.red, -100);
    expect(game.gameStateSnapshot.toJson(), before);
  },
  );

  test('native world Tone is transient across an in-session save load', () async {
    final repository = _MemorySaveRepository();
    final fixture = await _fixture(saveRepository: repository);
    final game = fixture.game;
    expect(await game.saveGame(), isTrue);
    await game.debugExecuteSceneInteractiveCommand(_tone(-255, 0));
    expect(await game.loadGame(), isTrue);
    expect(game.debugWorldToneValue.red, 0);
  },
  );

  test('native world Tone is restored if a load commit fails', () async {
    final fixture = await _fixture(
      saveRepository: _MemorySaveRepository(),
      beforeLoadCommitCompletion: () async => throw StateError('Injected load commit failure.'),
    );
    final game = fixture.game;
    expect(await game.saveGame(), isTrue);
    await game.debugExecuteSceneInteractiveCommand(_tone(-100, 0));
    final before = game.gameStateSnapshot.toJson();
    expect(await game.loadGame(), isFalse);
    expect(game.debugWorldToneValue.red, -100);
    expect(game.gameStateSnapshot.toJson(), before);
  });

  test('native world Tone cannot restore a save after runtime removal', () async {
    final repository = _MemorySaveRepository()..loadGate = Completer<GameState?>();
    final fixture = await _fixture(saveRepository: repository);
    final game = fixture.game;
    expect(await game.saveGame(), isTrue);
    await game.debugExecuteSceneInteractiveCommand(_tone(-255, 0));
    final loading = game.loadGame();
    await repository.loadEntered.future;
    game.onRemove();
    repository.loadGate!.complete(GameState.fromJson(repository._savedJson!));
    expect(await loading, isFalse);
    expect(game.debugWorldToneValue.red, 0);
  },
  );

  test('native world Tone is preserved when no save can be loaded', () async {
    final fixture = await _fixture(saveRepository: _MemorySaveRepository());
    final game = fixture.game;
    await game.debugExecuteSceneInteractiveCommand(_tone(-255, 0));
    expect(await game.loadGame(), isFalse);
    expect(game.debugWorldToneValue.red, -255);
  });

  test('save load cannot complete its map activation after runtime removal', () async {
    final entered = Completer<void>();
    final gate = Completer<void>();
    final fixture = await _fixture(
      saveRepository: _MemorySaveRepository(),
      beforeLoadCommitCompletion: () async {
        entered.complete();
        await gate.future;
      },
    );
    final game = fixture.game;
    expect(await game.saveGame(), isTrue);
    await game.debugExecuteSceneInteractiveCommand(_tone(-255, 0));
    final dispatchesBefore = game.debugCompletedMapActivationDispatchCount;
    final loading = game.loadGame();
    await entered.future;
    game.onRemove();
    gate.complete();
    expect(await loading, isFalse);
    expect(game.debugCompletedMapActivationDispatchCount, dispatchesBefore);
    expect(game.debugWorldToneValue.red, 0);
  },
  );

  test('native Scene sound completes after startup with its exact gain', () async {
    final audio = _SceneSoundPort();
    final fixture = await _fixture(
      sceneSoundEffectPlaybackPort: audio,
      cinematicMediaAssets: [_doorSound()],
    );
    expect(await fixture.game.debugExecuteSceneInteractiveCommand(_sound()), 'completed',
      );
    expect(audio.calls.single.mediaAssetId, 'door');
    expect(audio.calls.single.volume, .8);
    expect(audio.calls.single.playbackId, contains(':se:0'));
  },
  );

  test('native Scene sound refuses unsuitable media before playback', () async {
    for (final media in <List<CinematicMediaAsset>>[
      [], [_doorSound(loop: true)], [_doorSound(kind: CinematicMediaAssetKind.music)],
    ]) {
      final audio = _SceneSoundPort();
      final fixture = await _fixture(
        sceneSoundEffectPlaybackPort: audio,
        cinematicMediaAssets: media,
      );
      expect(await fixture.game.debugExecuteSceneInteractiveCommand(_sound()), 'blocked',
      );
      expect(audio.calls, isEmpty);
    }
  });

  test('native Scene sound refuses an audio startup failure', () async {
    final audio = _SceneSoundPort()..gate = Completer<void>();
    final fixture = await _fixture(
      sceneSoundEffectPlaybackPort: audio,
      cinematicMediaAssets: [_doorSound()],
    );
    final execution = fixture.game.debugExecuteSceneInteractiveCommand(_sound(),
    );
    await audio.entered.future;
    audio.gate!.completeError(StateError('Injected audio startup failure.'));
    expect(await execution, 'blocked');
  });

  test('native Scene sound cannot complete after the game is removed', () async {
    final audio = _SceneSoundPort()..gate = Completer<void>();
    final fixture = await _fixture(
      sceneSoundEffectPlaybackPort: audio,
      cinematicMediaAssets: [_doorSound()],
    );
    final execution = fixture.game.debugExecuteSceneInteractiveCommand(_sound(),
      );
    await audio.entered.future;
    fixture.game.onRemove();
    audio.gate!.complete();
    expect(await execution, 'blocked');
    expect(fixture.game.debugWorldToneValue.red, 0);
  },
  );

  test('native Scene cannot commit its sound failure branch after runtime removal', () async {
    final audio = _SceneSoundPort()..gate = Completer<void>();
    final fixture = await _fixture(
      sceneSoundEffectPlaybackPort: audio,
      cinematicMediaAssets: [_doorSound()],
      scenes: [_soundRewardScene()],
    );
    final game = fixture.game;
    final before = game.gameStateSnapshot.toJson();
    final execution = game.debugExecuteNarrativeSceneForTest(
      NarrativeSceneExecutionRequest(
        eventId: 'sound-event', sceneId: 'sound-scene', executionId: 'sound-removed',
        gameState: game.gameStateSnapshot,
      ),
    );
    await audio.entered.future;
    game.onRemove();
    audio.gate!.complete();
    expect(await execution, isA<NarrativeSceneExecutionFailed>());
    expect(game.gameStateSnapshot.toJson(), before);
  },
  );

  test('native Scene can finish its sound failure branch in a live runtime', () async {
    final audio = _SceneSoundPort()..gate = Completer<void>();
    final fixture = await _fixture(
      sceneSoundEffectPlaybackPort: audio,
      cinematicMediaAssets: [_doorSound()],
      scenes: [_soundRewardScene()],
    );
    final game = fixture.game;
    final moneyBefore = game.gameStateSnapshot.trainerProfile.money;
    final execution = game.debugExecuteNarrativeSceneForTest(
      NarrativeSceneExecutionRequest(
        eventId: 'sound-event', sceneId: 'sound-scene', executionId: 'sound-failed-live',
        gameState: game.gameStateSnapshot,
      ),
    );
    await audio.entered.future;
    audio.gate!.completeError(StateError('Injected audio startup failure.'));
    final result = await execution;
    expect(result, isA<NarrativeSceneExecutionCompleted>());
    expect((result as NarrativeSceneExecutionCompleted).updatedGameState.trainerProfile.money, moneyBefore + 100,
      );
    },
  );

  test('a map event Scene cannot commit after its real sound adapter closes', () async {
    final driver = _PendingNarrativeDriver();
    final audio = FlameNarrativeSoundPlaybackAdapter(
      mediaAssets: [_doorSound()], resolvePath: (asset) => asset.relativePath,
      audioDriver: driver,
    );
    addTearDown(audio.dispose);
    final activity = NarrativeRuntimeActivityGate();
    final fixture = await _fixture(
      sourceFacing: EntityFacing.west,
      sceneSoundEffectPlaybackPort: audio,
      narrativeRuntimeActivityGate: activity,
      cinematicMediaAssets: [_doorSound()],
      scenes: [_soundRewardScene()],
      events: [MapEventDefinition(
        id: 'sound-map-event', title: 'Sound map event',
        position: const EventPosition(layerId: 'objects', x: 0, y: 1),
        pages: [MapEventPage(pageNumber: 0,
          sceneTarget: const MapEventSceneTarget(sceneId: 'sound-scene'),
              ),
            ],
      ),
        ],
    );
    final game = fixture.game;
    final before = game.gameStateSnapshot.toJson();
    expect(game.handleRuntimeInputEvent(RuntimeInputEvent.press(RuntimeInputControl.primary),
        ), isTrue,
      );
    await driver.entered.future;
    expect(activity.activity, NarrativeRuntimeActivity.sceneActive);
    game.onRemove();
    final closingAudio = audio.dispose();
    driver.gate.complete(driver.handle);
    await closingAudio;
    for (var tick = 0; tick < 200 && activity.activity != NarrativeRuntimeActivity.idle; tick++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(activity.activity, NarrativeRuntimeActivity.idle);
    expect(driver.stopped, [driver.handle]);
    expect(game.gameStateSnapshot.toJson(), before);
  },
  );

  for (final facing in EntityFacing.values) {
    test(
      'scene warp applies the authored ${facing.name} arrival facing',
      () async {
        final fixture = await _fixture(
          warpArrival: true,
          sourceFacing: facing == EntityFacing.east
              ? EntityFacing.west
              : EntityFacing.east,
        );

        final result = await _warp(
          fixture.game,
          SceneInteractiveCommand.warp(
            destinationMapId: 'target',
            warpId: 'arrival',
            arrivalFacing: facing,
            transition: SceneWarpTransition.none,
          ),
        );

        expect(result.port, 'completed');
        _expectArrived(
          fixture.game,
          const GridPos(x: 0, y: 1),
          facing: facing,
          reason: MapActivationReason.warp,
        );
      },
    );
  }

  test('scene warp preserves facing when arrival facing is omitted', () async {
    final fixture = await _fixture(
      warpArrival: true,
      sourceFacing: EntityFacing.west,
    );

    final result = await _warp(fixture.game, _arrivalCommand());

    expect(result.port, 'completed');
    _expectArrived(
      fixture.game,
      const GridPos(x: 0, y: 1),
      facing: EntityFacing.west,
      reason: MapActivationReason.warp,
    );
  });

  test('scene warp none never mounts a visual transition overlay', () async {
    final fixture = await _fixture(warpArrival: true);

    final result = await _warp(
      fixture.game,
      _arrivalCommand(transition: SceneWarpTransition.none),
    );

    expect(result.port, 'completed');
    expect(result.sawTransitionOverlay, isFalse);
    _expectArrived(
      fixture.game,
      const GridPos(x: 0, y: 1),
      reason: MapActivationReason.warp,
    );
  });

  test('a rejected same-map warp cannot report completed from unchanged state', () async {
    final fixture = await _fixture(warpArrival: true, sameMapArrival: true);
    final game = fixture.game;
    var finished = false;
    final active = game.debugExecuteSceneInteractiveCommand(_arrivalCommand())
        .whenComplete(() => finished = true);
    for (var tick = 0; tick < 40 && game.debugFlowPhaseName != 'mapTransition'; tick++) {
      game.update(0);
      await Future<void>.delayed(Duration.zero);
    }
    expect(game.debugFlowPhaseName, 'mapTransition');
    expect(game.gameStateSnapshot.currentMapId, 'source');
    final rejected = await game.debugExecuteSceneInteractiveCommand(
      SceneInteractiveCommand.warp(destinationMapId: 'source', warpId: 'same',
        transition: SceneWarpTransition.none,
        ),
    );
    for (var tick = 0; tick < 300 && !finished; tick++) {
      game.update(.016);
      await Future<void>.delayed(Duration.zero);
    }
    expect(await active, 'completed');
    expect(rejected, 'blocked');
  },
  );

  test('scene warp map default mounts its indoor fade overlay', () async {
    final fixture = await _fixture(warpArrival: true);

    final result = await _warp(fixture.game, _arrivalCommand());

    expect(result.port, 'completed');
    expect(result.sawTransitionOverlay, isTrue);
    expect(
      fixture.game.camera.viewport.children
          .whereType<WarpTransitionOverlayComponent>(),
      isEmpty,
    );
    _expectArrived(
      fixture.game,
      const GridPos(x: 0, y: 1),
      reason: MapActivationReason.warp,
    );
  });

  test(
    'scene warp rejects feet collision when the cell centre is free',
    () async {
      final fixture = await _fixture(warpArrival: true, maskPixel: (16, 24));
      expect(
        fixture.targetWorld.isCellCenterBlockedLegacyForGridIndexedSystems(
          0,
          1,
        ),
        isFalse,
      );
      expect(
        fixture.targetWorld.worldStaticObstaclesCollidePlayerCollisionRect(),
        isTrue,
      );
      final before = fixture.game.gameStateSnapshot;

      final result = await _warp(
        fixture.game,
        _arrivalCommand(arrivalFacing: EntityFacing.north),
      );

      expect(result.port, 'blocked');
      _expectRejected(fixture.game, 'La téléportation a échoué.');
      expect(fixture.game.gameStateSnapshot, before);
    },
  );

  test(
    'scene warp accepts free feet when the cell centre touches a mask',
    () async {
      final fixture = await _fixture(warpArrival: true, maskPixel: (16, 16));
      expect(
        fixture.targetWorld.isCellCenterBlockedLegacyForGridIndexedSystems(
          0,
          1,
        ),
        isTrue,
      );
      expect(
        fixture.targetWorld.worldStaticObstaclesCollidePlayerCollisionRect(),
        isFalse,
      );

      final result = await _warp(fixture.game, _arrivalCommand());

      expect(result.port, 'completed');
      _expectArrived(
        fixture.game,
        const GridPos(x: 0, y: 1),
        reason: MapActivationReason.warp,
      );
    },
  );

  test(
    'scene warp rolls back an active blocking entity without changing facing',
    () async {
      final fixture = await _fixture(warpArrival: true, blockingEntity: true);
      expect(
        fixture.targetWorld.worldStaticObstaclesCollidePlayerCollisionRect(),
        isTrue,
      );
      final before = fixture.game.gameStateSnapshot;

      final result = await _warp(
        fixture.game,
        _arrivalCommand(arrivalFacing: EntityFacing.west),
      );

      expect(result.port, 'blocked');
      _expectRejected(fixture.game, 'La téléportation a échoué.');
      expect(fixture.game.gameStateSnapshot, before);
    },
  );

  test('scene warp accepts a through entity at the arrival', () async {
    final fixture = await _fixture(warpArrival: true, blockingEntity: false);
    expect(
      fixture.targetWorld.worldStaticObstaclesCollidePlayerCollisionRect(),
      isFalse,
    );

    final result = await _warp(fixture.game, _arrivalCommand());

    expect(result.port, 'completed');
    _expectArrived(
      fixture.game,
      const GridPos(x: 0, y: 1),
      reason: MapActivationReason.warp,
    );
  });

  test(
    'a qualified logical map instance is allocated on initial boot',
    () async {
      final fixture = await _fixture(
        mapInstanceRetentionPolicy: _instancePolicy(),
      );
      final store = fixture.game.gameStateSnapshot.mapInstanceWorldState;
      expect(store.instanceRef('source'), isNotNull);
      expect(store.instanceRef('source')!.instanceId, isNotEmpty);
    },
  );

  for (final invalid in ['missing-active', 'unknown-retained']) {
    test(
      'qualified instance restore rejects $invalid before replacing the world',
      () async {
        final repository = _MemorySaveRepository();
        final fixture = await _fixture(
          mapInstanceRetentionPolicy: _instancePolicy(),
          saveRepository: repository,
        );
        final before = fixture.game.gameStateSnapshot;
        final malformed = invalid == 'missing-active'
            ? const MapInstanceWorldState.empty()
            : MapInstanceWorldState(
                instancesByMapId: {
                  ...before.mapInstanceWorldState.instancesByMapId,
                  'unknown-map': MapInstanceRuntimeState(
                    instanceId: 'unknown-instance',
                  ),
                },
              );
        await repository.save(
          before.copyWith(mapInstanceWorldState: malformed),
        );
        final stored = jsonEncode(repository._savedJson);
        expect(await fixture.game.loadGame(), isFalse);
        expect(fixture.game.gameStateSnapshot, before);
        expect(jsonEncode(repository._savedJson), stored);
        fixture.game.update(0);
        expect(fixture.game.debugFlowPhaseName, 'overworld');
      },
    );
  }

  test(
    'qualified instance save restore preserves IDs and owner boolean',
    () async {
      final repository = _MemorySaveRepository();
      final fixture = await _fixture(
        gameState: _instanceGameState(),
        mapInstanceRetentionPolicy: _instancePolicy(),
        saveRepository: repository,
        sourceEntities: const [_routeDoor],
        characters: const [_routeDoorCharacter],
      );
      final before = fixture.game.gameStateSnapshot.mapInstanceWorldState;
      expect(await fixture.game.saveGame(), isTrue);
      expect(await fixture.game.loadGame(), isTrue);
      final after = fixture.game.gameStateSnapshot.mapInstanceWorldState;
      expect(after, before);
      expect(
        after.eventBoolean(after.instanceRef('source')!, 'route-door', 'A'),
        isTrue,
      );
    },
  );

  for (final source in [
    SceneConditionSource.playerAtEntityAnchor(
      mapId: 'source',
      entityId: 'route-door',
    ),
    SceneConditionSource.mapEventInstanceBoolean(
      mapId: 'source',
      eventId: 'route-door',
      key: 'A',
    ),
  ]) {
    test(
      'instance condition ${source.sourceKind.name} is evaluated in the real Scene host',
      () async {
        final scene = _instanceConditionScene(source);
        final fixture = await _fixture(
          gameState: _instanceGameState(),
          mapInstanceRetentionPolicy: _instancePolicy(),
          narrativeV2: true,
          sourceEntities: [
            _routeDoor.copyWith(
              pos: const GridPos(x: 1, y: 1),
              blocksMovement: false,
            ),
          ],
          characters: const [_routeDoorCharacter],
          scenes: [scene],
        );
        final before = fixture.game.gameStateSnapshot;
        final result = await _finishActorScene(
          fixture.game,
          fixture.game.debugExecuteNarrativeSceneForTest(
            NarrativeSceneExecutionRequest(
              eventId: 'instance-event',
              sceneId: scene.id,
              executionId: 'instance-condition',
              gameState: before,
            ),
          ),
        );
        expect(
          result,
          isA<NarrativeSceneExecutionCompleted>(),
          reason: result is NarrativeSceneExecutionFailed
              ? result.failure.toString()
              : null,
        );
        final state =
            (result as NarrativeSceneExecutionCompleted).updatedGameState;
        expect(state.trainerProfile.money, before.trainerProfile.money + 100);
      },
    );
  }

  test(
    'instance condition sees the earlier buffered setter in the same Scene',
    () async {
      final source = SceneConditionSource.mapEventInstanceBoolean(
        mapId: 'source',
        eventId: 'route-door',
        key: 'B',
      );
      final scene = _instanceConditionScene(source, setBefore: true);
      final fixture = await _fixture(
        gameState: _instanceGameState(),
        mapInstanceRetentionPolicy: _instancePolicy(),
        narrativeV2: true,
        sourceEntities: const [_routeDoor],
        characters: const [_routeDoorCharacter],
        scenes: [scene],
      );
      final before = fixture.game.gameStateSnapshot;
      final result = await _finishActorScene(
        fixture.game,
        fixture.game.debugExecuteNarrativeSceneForTest(
          NarrativeSceneExecutionRequest(
            eventId: 'instance-event',
            sceneId: scene.id,
            executionId: 'buffered-instance',
            gameState: before,
          ),
        ),
      );
      expect(
        result,
        isA<NarrativeSceneExecutionCompleted>(),
        reason: result is NarrativeSceneExecutionFailed
            ? result.failure.toString()
            : null,
      );
      final state =
          (result as NarrativeSceneExecutionCompleted).updatedGameState;
      expect(state.trainerProfile.money, before.trainerProfile.money + 100);
      expect(
        state.mapInstanceWorldState.eventBoolean(
          state.mapInstanceWorldState.instanceRef('source')!,
          'route-door',
          'B',
        ),
        isTrue,
      );
    },
  );

  test(
    'a same map warp preserves its logical instance and event booleans',
    () async {
      final initial = _instanceGameState();
      final fixture = await _fixture(
        sameMapArrival: true,
        gameState: initial,
        mapInstanceRetentionPolicy: _instancePolicy(),
        sourceEntities: const [_routeDoor],
        characters: const [_routeDoorCharacter],
      );
      final before = fixture.game.gameStateSnapshot.mapInstanceWorldState;
      final result = await _warp(
        fixture.game,
        SceneInteractiveCommand.warp(
          destinationMapId: 'source',
          warpId: 'same',
          transition: SceneWarpTransition.none,
        ),
      );
      expect(result.port, 'completed');
      final after = fixture.game.gameStateSnapshot.mapInstanceWorldState;
      expect(after.instanceRef('source'), before.instanceRef('source'));
      expect(
        after.eventBoolean(after.instanceRef('source')!, 'route-door', 'A'),
        isTrue,
      );
    },
  );

  test(
    'a different map warp recreates target instance and clears retained flags',
    () async {
      final initial = _instanceGameState();
      final fixture = await _fixture(
        warpArrival: true,
        gameState: initial,
        mapInstanceRetentionPolicy: _instancePolicy(),
        sourceEntities: const [_routeDoor],
        characters: const [_routeDoorCharacter],
      );
      final before = fixture.game.gameStateSnapshot.mapInstanceWorldState;
      final result = await _warp(
        fixture.game,
        _arrivalCommand(transition: SceneWarpTransition.none),
      );
      expect(result.port, 'completed');
      final after = fixture.game.gameStateSnapshot.mapInstanceWorldState;
      expect(after.instanceRef('target'), isNot(before.instanceRef('target')));
      final retainedSource = after.instanceRef('source');
      if (retainedSource != null) {
        expect(retainedSource, isNot(before.instanceRef('source')));
        expect(after.eventBoolean(retainedSource, 'route-door', 'A'), isFalse);
      }
    },
  );

  test(
    'a failed warp retains the same logical instance identities and flags',
    () async {
      final initial = _instanceGameState();
      final fixture = await _fixture(
        warpArrival: true,
        blockingEntity: true,
        gameState: initial,
        mapInstanceRetentionPolicy: _instancePolicy(),
        sourceEntities: const [_routeDoor],
        characters: const [_routeDoorCharacter],
      );
      final before = fixture.game.gameStateSnapshot.mapInstanceWorldState;
      final result = await _warp(
        fixture.game,
        _arrivalCommand(transition: SceneWarpTransition.none),
      );
      expect(result.port, 'blocked');
      expect(fixture.game.gameStateSnapshot.mapInstanceWorldState, before);
    },
  );

  for (final (moveNpc, movePlayer, logicalInstances) in [
    (false, false, true),
    (true, false, true),
    (false, true, true),
    (true, false, false),
    (false, true, false),
  ]) {
    test(
      'Scene failure after a completed Warp restores logical state and actors npc=$moveNpc player=$movePlayer logical=$logicalInstances',
      () async {
        PlayableMapGame? game;
        var observedTarget = false;
        var observedPlayerRoute = false;
        var observedNpcRoute = false;
        var observedShownNpc = false;
        final initiallyHiddenNpc = moveNpc && !logicalInstances;
        final fixture = await _fixture(
          warpArrival: true,
          gameState: logicalInstances ? _instanceGameState() : null,
          mapInstanceRetentionPolicy: logicalInstances
              ? _instancePolicy()
              : null,
          sourceEntities: const [_routeDoor],
          characters: const [_routeDoorCharacter],
          scenes: [
            _warpRollbackScene(
              moveNpc: moveNpc,
              movePlayer: movePlayer,
              npcVisibility: initiallyHiddenNpc,
            ),
          ],
          dialogues: const [_actorDialogueEntry],
          narrativeV2: true,
          dialogueSessionLoader: (_) async {
            observedTarget =
                game!.gameStateSnapshot.currentMapId == 'target' &&
                game.debugPlayerGridPosition == const GridPos(x: 0, y: 1);
            throw StateError('Dialogue failed after the completed Warp');
          },
        );
        game = fixture.game;
        if (initiallyHiddenNpc) {
          expect(
            await game.debugExecuteSceneInteractiveCommand(
              SceneInteractiveCommand.actorVisibility(
                target: SceneActorTarget.entity(
                  mapId: 'source',
                  entityId: 'route-door',
                ),
                visible: false,
              ),
            ),
            'completed',
          );
          expect(game.debugIsNpcActorVisible('route-door'), isFalse);
        }
        final before = game.gameStateSnapshot;
        final result = await _finishActorScene(
          game,
          game.debugExecuteNarrativeSceneForTest(
            NarrativeSceneExecutionRequest(
              eventId: 'warp-rollback-event',
              sceneId: 'warp-rollback-scene',
              executionId:
                  'warp-rollback-$moveNpc-$movePlayer-$logicalInstances',
              gameState: before,
            ),
          ),
          observe: () {
            observedPlayerRoute |=
                game!.gameStateSnapshot.currentMapId == 'source' &&
                game.debugPlayerGridPosition == const GridPos(x: 0, y: 1);
            observedNpcRoute |=
                game.gameStateSnapshot.currentMapId == 'source' &&
                game.debugNpcGridPosition('route-door') ==
                    const GridPos(x: 0, y: 0);
            observedShownNpc |=
                game.gameStateSnapshot.currentMapId == 'source' &&
                game.debugIsNpcActorVisible('route-door') == true;
          },
        );
        if (movePlayer) expect(observedPlayerRoute, isTrue);
        if (moveNpc) expect(observedNpcRoute, isTrue);
        if (initiallyHiddenNpc) expect(observedShownNpc, isTrue);
        expect(observedTarget, isTrue);
        expect(result, isA<NarrativeSceneExecutionFailed>());
        expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
        expect(game.gameStateSnapshot.toJson(), before.toJson());
        expect(
          game.debugNpcGridPosition('route-door'),
          const GridPos(x: 1, y: 0),
        );
        expect(game.debugNpcActorFacing('route-door'), EntityFacing.south);
        expect(game.debugIsNpcActorVisible('route-door'), !initiallyHiddenNpc);
        expect(game.debugFlowPhaseName, 'overworld');
        expect(game.debugHasPendingMapTransition, isFalse);
        expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
      },
    );
  }

  test(
    'scene warp admits only its declared NPC owner at the exact arrival',
    () async {
      final owner = _routeDoor.copyWith(pos: const GridPos(x: 0, y: 1));
      final fixture = await _fixture(
        warpArrival: true,
        targetEntities: [owner],
        characters: const [_routeDoorCharacter],
      );
      expect(
        fixture.targetWorld.worldStaticObstaclesCollidePlayerCollisionRect(),
        isTrue,
      );
      final result = await _warp(
        fixture.game,
        SceneInteractiveCommand.warp(
          destinationMapId: 'target',
          warpId: 'arrival',
          arrivalCollisionOwnerEntityId: owner.id,
          transition: SceneWarpTransition.none,
        ),
      );
      expect(result.port, 'completed');
      _expectArrived(
        fixture.game,
        const GridPos(x: 0, y: 1),
        reason: MapActivationReason.warp,
      );
      expect(fixture.game.gameStateSnapshot.currentMapId, 'target');
      expect(
        fixture.targetWorld.worldStaticObstaclesCollidePlayerCollisionRect(),
        isTrue,
      );
    },
  );

  test('actor route leaves its original owner without enabling through', () async {
    final owner = _routeDoor.copyWith(pos: const GridPos(x: 0, y: 1));
    final repository = _MemorySaveRepository();
    final fixture = await _fixture(
      warpArrival: true,
      targetEntities: [owner],
      characters: const [_routeDoorCharacter],
      saveRepository: repository,
    );
    final game = fixture.game;
    final arrival = await _warp(game, SceneInteractiveCommand.warp(
      destinationMapId: 'target', warpId: 'arrival',
      arrivalCollisionOwnerEntityId: owner.id,
      transition: SceneWarpTransition.none,
    ));
    expect(arrival.port, 'completed');
    final from = game.debugPlayerWorldTopLeft;
    final execution = game.debugExecuteSceneInteractiveCommand(_actorRoute([
      {'kind': 'move', 'direction': 'east', 'durationMs': 250,
        'initialCollisionOwnerEntityId': owner.id},
    ], mapId: 'target'));
    await Future<void>.delayed(Duration.zero);
    game.update(.1);
    expect(game.debugIsPlayerStepping, isTrue);
    expect(game.debugPlayerGridPosition, owner.pos);
    expect(game.debugPlayerWorldTopLeft.x, greaterThan(from.x));
    expect(await game.saveGame(), isFalse);
    expect(await _finishActorRoute(game, execution), 'completed');
    expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
    expect(game.debugNpcGridPosition(owner.id), owner.pos);
    expect(game.debugIsGameplayInputLocked, isFalse);
    expect(await _finishActorRoute(game,
      game.debugExecuteSceneInteractiveCommand(_actorRoute([
        {'kind': 'move', 'direction': 'west', 'durationMs': 250},
      ], mapId: 'target'))), 'blocked');
    expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
    expect(await game.saveGame(), isTrue);
    expect(await _finishActorRoute(game,
      game.debugExecuteSceneInteractiveCommand(_actorRoute([
        {'kind': 'move', 'direction': 'south', 'durationMs': 250},
      ], mapId: 'target'))), 'completed');
    expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 2));
    expect(await game.loadGame(), isTrue);
    expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 1));
    expect(game.debugRenderedPlayerFootCell, const GridPos(x: 1, y: 1));
  });

  for (final blockedDestination in [false, true]) {
    test('actor route owner keeps bounds and other obstacles blocked=$blockedDestination', () async {
      final owner = _routeDoor.copyWith(pos: const GridPos(x: 0, y: 1));
      final fixture = await _fixture(
        warpArrival: true,
        targetEntities: [owner, if (blockedDestination) const MapEntity(
          id: 'other-obstacle', name: 'Other obstacle',
          kind: MapEntityKind.custom, pos: GridPos(x: 1, y: 1),
          properties: {
            mapEntityCollisionWidthProperty: '1',
            mapEntityCollisionHeightProperty: '1',
          },
        )],
        characters: const [_routeDoorCharacter],
      );
      final game = fixture.game;
      expect(fixture.targetWorld.isCellCenterBlockedLegacyForGridIndexedSystems(1, 1),
          blockedDestination);
      expect((await _warp(game, SceneInteractiveCommand.warp(
        destinationMapId: 'target', warpId: 'arrival',
        arrivalCollisionOwnerEntityId: owner.id,
        transition: SceneWarpTransition.none,
      ))).port, 'completed');
      expect(await _finishActorRoute(game,
        game.debugExecuteSceneInteractiveCommand(_actorRoute([
          {'kind': 'move', 'direction': blockedDestination ? 'east' : 'west',
            'durationMs': 250, 'initialCollisionOwnerEntityId': owner.id},
        ], mapId: 'target'))), 'blocked');
      expect(game.debugPlayerGridPosition, owner.pos);
      expect(game.debugIsPlayerStepping, isFalse);
      expect(game.debugIsGameplayInputLocked, isFalse);
    });
  }

  test('actor route owner keeps another NPC real reservation at the destination', () async {
    final owner = _routeDoor.copyWith(pos: const GridPos(x: 0, y: 1));
    final other = _routeDoor.copyWith(id: 'other-npc',
        pos: const GridPos(x: 2, y: 1), blocksMovement: false);
    final fixture = await _fixture(warpArrival: true,
        targetEntities: [owner, other], characters: const [_routeDoorCharacter]);
    final game = fixture.game;
    expect((await _warp(game, SceneInteractiveCommand.warp(
      destinationMapId: 'target', warpId: 'arrival',
      arrivalCollisionOwnerEntityId: owner.id,
      transition: SceneWarpTransition.none,
    ))).port, 'completed');
    expect(fixture.targetWorld.isCellCenterBlockedLegacyForGridIndexedSystems(1, 1),
        isFalse);
    final moving = game.startScriptedNpcMove(entityId: other.id,
        destination: const GridPos(x: 1, y: 1));
    expect(moving.state, ScriptedEntityMovementState.moving);
    game.update(.025);
    final movingActor = _components(game).whereType<OverworldActorComponent>()
        .singleWhere((candidate) => candidate.gridPos == const GridPos(x: 1, y: 1));
    expect(movingActor.isStepping, isTrue);
    expect(game.debugScriptedNpcDynamicBlockedCells(ignoreEntityId: 'player'),
        contains(const GridPos(x: 1, y: 1)));
    expect(await _finishActorRoute(game,
      game.debugExecuteSceneInteractiveCommand(_actorRoute([
        {'kind': 'move', 'direction': 'east', 'durationMs': 250,
          'initialCollisionOwnerEntityId': owner.id},
      ], mapId: 'target'))), 'blocked');
    expect(game.debugPlayerGridPosition, owner.pos);
    expect(game.debugIsGameplayInputLocked, isFalse);
  });

  test('actor route owner must be stationary before leaving its cell', () async {
    final owner = _routeDoor.copyWith(pos: const GridPos(x: 0, y: 1));
    final fixture = await _fixture(warpArrival: true,
      targetEntities: [owner], characters: const [_routeDoorCharacter]);
    final game = fixture.game;
    expect((await _warp(game, SceneInteractiveCommand.warp(
      destinationMapId: 'target', warpId: 'arrival',
      arrivalCollisionOwnerEntityId: owner.id,
      transition: SceneWarpTransition.none,
    ))).port, 'completed');
    final actor = _components(game).whereType<OverworldActorComponent>()
        .singleWhere((candidate) => candidate.character.id == _routeDoorCharacter.id);
    expect(actor.startGridStep(to: const GridPos(x: 0, y: 2),
      facing: EntityFacing.south, durationSeconds: .25), isTrue);
    expect(await _finishActorRoute(game,
      game.debugExecuteSceneInteractiveCommand(_actorRoute([
        {'kind': 'move', 'direction': 'east', 'durationMs': 250,
          'initialCollisionOwnerEntityId': owner.id},
      ], mapId: 'target'))), 'blocked');
    expect(game.debugPlayerGridPosition, owner.pos);
    expect(game.debugIsPlayerStepping, isFalse);
  });

  for (final moves in [false, true]) {
    test('actor route owner change interrupts and restores the player moves=$moves', () async {
      final owner = _routeDoor.copyWith(pos: const GridPos(x: 0, y: 1));
      final fixture = await _fixture(warpArrival: true,
        targetEntities: [owner], characters: const [_routeDoorCharacter]);
      final game = fixture.game;
      expect((await _warp(game, SceneInteractiveCommand.warp(
        destinationMapId: 'target', warpId: 'arrival',
        arrivalCollisionOwnerEntityId: owner.id,
        transition: SceneWarpTransition.none,
      ))).port, 'completed');
      final actor = _components(game).whereType<OverworldActorComponent>()
          .singleWhere((candidate) => candidate.character.id == _routeDoorCharacter.id);
      final from = game.debugPlayerWorldTopLeft;
      final execution = game.debugExecuteSceneInteractiveCommand(_actorRoute([
        {'kind': 'move', 'direction': 'east', 'durationMs': 250,
          'initialCollisionOwnerEntityId': owner.id},
      ], mapId: 'target'));
      final failure = expectLater(execution, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      game.update(.05);
      expect(game.debugIsPlayerStepping, isTrue);
      if (moves) {
        expect(actor.startGridStep(to: const GridPos(x: 0, y: 2),
          facing: EntityFacing.south, durationSeconds: .25), isTrue);
      } else {
        actor.setGameplayVisible(false);
      }
      game.update(.025);
      await failure;
      expect(game.debugPlayerGridPosition, owner.pos);
      expect(game.debugPlayerWorldTopLeft, from);
      expect(game.debugIsPlayerStepping, isFalse);
      expect(game.debugIsGameplayInputLocked, isFalse);
    });
  }

  test(
    'scene warp owner exemption does not ignore another arrival entity',
    () async {
      final owner = _routeDoor.copyWith(pos: const GridPos(x: 0, y: 1));
      final fixture = await _fixture(
        warpArrival: true,
        blockingEntity: true,
        targetEntities: [owner],
        characters: const [_routeDoorCharacter],
      );
      final before = fixture.game.gameStateSnapshot;
      final result = await _warp(
        fixture.game,
        SceneInteractiveCommand.warp(
          destinationMapId: 'target',
          warpId: 'arrival',
          arrivalCollisionOwnerEntityId: owner.id,
          transition: SceneWarpTransition.none,
        ),
      );
      expect(result.port, 'blocked');
      _expectRejected(fixture.game, 'La téléportation a échoué.');
      expect(fixture.game.gameStateSnapshot, before);
    },
  );

  test('scene warp owner exemption retains fine arrival collision', () async {
    final owner = _routeDoor.copyWith(pos: const GridPos(x: 0, y: 1));
    final fixture = await _fixture(
      warpArrival: true,
      maskPixel: (16, 24),
      targetEntities: [owner],
      characters: const [_routeDoorCharacter],
    );
    final before = fixture.game.gameStateSnapshot;
    final result = await _warp(
      fixture.game,
      SceneInteractiveCommand.warp(
        destinationMapId: 'target',
        warpId: 'arrival',
        arrivalCollisionOwnerEntityId: owner.id,
        transition: SceneWarpTransition.none,
      ),
    );
    expect(result.port, 'blocked');
    _expectRejected(fixture.game, 'La téléportation a échoué.');
    expect(fixture.game.gameStateSnapshot, before);
  });

  test(
    'scene warp preserves the walking restriction on an authored water cell',
    () async {
      final fixture = await _fixture(warpArrival: true, water: true);
      final before = fixture.game.gameStateSnapshot;

      final result = await _warp(
        fixture.game,
        _arrivalCommand(arrivalFacing: EntityFacing.south),
      );

      expect(result.port, 'blocked');
      _expectRejected(fixture.game, 'La téléportation a échoué.');
      expect(fixture.game.gameStateSnapshot, before);
    },
  );

  test('scene warp accepts an authored water cell while surfing', () async {
    final fixture = await _fixture(warpArrival: true, water: true);
    fixture.game.setPlayerMovementMode(MovementMode.surf);

    final result = await _warp(fixture.game, _arrivalCommand());

    expect(result.port, 'completed');
    _expectArrived(
      fixture.game,
      const GridPos(x: 0, y: 1),
      reason: MapActivationReason.warp,
    );
    expect(
      fixture.game.gameStateSnapshot.playerMovementMode,
      MovementMode.surf,
    );
  });

  test(
    'scene warp arrival and facing survive a serialized save and reload',
    () async {
      final repository = _MemorySaveRepository();
      final fixture = await _fixture(
        warpArrival: true,
        saveRepository: repository,
      );
      final game = fixture.game;
      game.setPlayerMovementMode(MovementMode.surf);

      final result = await _warp(
        game,
        _arrivalCommand(
          arrivalFacing: EntityFacing.north,
          transition: SceneWarpTransition.none,
        ),
      );
      expect(result.port, 'completed');
      expect(await game.saveGame(), isTrue);
      await _move(game, RuntimeInputControl.right);
      game.setPlayerMovementMode(MovementMode.walk);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 1));
      expect(game.gameStateSnapshot.playerFacing, EntityFacing.east);

      expect(await game.loadGame(), isTrue);

      expect(game.gameStateSnapshot.currentMapId, 'target');
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 0, y: 1));
      expect(game.gameStateSnapshot.playerFacing, EntityFacing.north);
      expect(game.gameStateSnapshot.playerMovementMode, MovementMode.surf);
      expect(game.debugRenderedPlayerFootCell, const GridPos(x: 0, y: 1));
      expect(
        game.debugPlayerWorldTopLeft,
        game.debugExpectedPlayerWorldTopLeft,
      );
      expect(game.debugFlowPhaseName, 'overworld');
      expect(game.debugHasPendingMapTransition, isFalse);
      expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
    },
  );
}

void _expectRejected(PlayableMapGame game, String notification) {
  expect(game.gameStateSnapshot.currentMapId, 'source');
  expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 1));
  expect(game.gameStateSnapshot.playerFacing, EntityFacing.east);
  expect(game.debugNotificationText, notification);
  expect(game.debugCompletedMapActivationDispatchCount, 1);
  expect(
    game.debugLastCompletedMapActivation?.reason,
    MapActivationReason.initialBoot,
  );
  expect(game.debugLastCompletedMapActivation?.mapId, 'source');
  expect(game.debugFlowPhaseName, 'overworld');
  expect(game.debugHasPendingMapTransition, isFalse);
  expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
}

void _expectArrived(
  PlayableMapGame game,
  GridPos arrival, {
  EntityFacing facing = EntityFacing.east,
  MapActivationReason reason = MapActivationReason.connection,
}) {
  expect(game.gameStateSnapshot.currentMapId, 'target');
  expect(game.gameStateSnapshot.playerPosition, arrival);
  expect(game.gameStateSnapshot.playerFacing, facing);
  expect(_components(game).whereType<PlayerComponent>().single.cinematicFacing, facing,
  );
  expect(game.debugRenderedPlayerFootCell, arrival);
  expect(game.debugPlayerWorldTopLeft, game.debugExpectedPlayerWorldTopLeft);
  expect(game.debugCompletedMapActivationDispatchCount, 2);
  expect(game.debugLastCompletedMapActivation?.reason, reason);
  expect(game.debugLastCompletedMapActivation?.mapId, 'target');
  expect(game.debugFlowPhaseName, 'overworld');
  expect(game.debugHasPendingMapTransition, isFalse);
  expect(game.inputAuthoritySnapshot.acceptsRuntimeInput, isTrue);
}

SceneInteractiveCommand _arrivalCommand({
  EntityFacing? arrivalFacing,
  SceneWarpTransition transition = SceneWarpTransition.mapDefault,
}) => SceneInteractiveCommand.warp(
  destinationMapId: 'target',
  warpId: 'arrival',
  arrivalFacing: arrivalFacing,
  transition: transition,
);

Iterable<Component> _components(Component parent) sync* {
  yield parent;
  for (final child in parent.children) {
    yield* _components(child);
  }
}

Future<({String port, bool sawTransitionOverlay})> _warp(
  PlayableMapGame game,
  SceneInteractiveCommand command,
) async {
  var completed = false;
  var sawTransitionOverlay = false;
  final execution = game
      .debugExecuteSceneInteractiveCommand(command)
      .whenComplete(() => completed = true);
  for (var tick = 0; tick < 240; tick++) {
    game.update(.016);
    sawTransitionOverlay |= game.camera.viewport.children
        .whereType<WarpTransitionOverlayComponent>()
        .isNotEmpty;
    await Future<void>.delayed(Duration.zero);
    if (completed &&
        !game.debugHasPendingMapTransition &&
        !game.debugIsMapActivationDispatchInFlight &&
        game.debugFlowPhaseName == 'overworld') {
      game.update(0);
      return (
        port: await execution,
        sawTransitionOverlay: sawTransitionOverlay,
      );
    }
  }
  fail('Scene warp command did not settle.');
}

Future<void> _move(PlayableMapGame game, RuntimeInputControl control) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.update(.016);
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
    isTrue,
  );
  for (var tick = 0; tick < 240; tick++) {
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
    if (!game.debugIsPlayerStepping &&
        !game.debugHasPendingMapTransition &&
        !game.debugIsMapActivationDispatchInFlight &&
        game.debugFlowPhaseName == 'overworld') {
      return;
    }
  }
  fail('Connection input did not settle.');
}

Future<({PlayableMapGame game, GameplayWorldState targetWorld})> _fixture({
  (int, int)? maskPixel,
  bool solidCharacter = false,
  bool? blockingEntity,
  int offset = 0,
  List<MapConnection> extraConnections = const [],
  List<MapData> extraMaps = const [],
  bool water = false,
  bool warpArrival = false,
  bool sameMapArrival = false,
  MapWarpTriggerMode arrivalTriggerMode = MapWarpTriggerMode.onBump,
  List<MapWarp> sourceWarps = const [],
  List<MapTrigger> sourceTriggers = const [],
  List<GridPos> sourceCollisionCells = const [],
  EntityFacing sourceFacing = EntityFacing.east,
  GameSaveRepository? saveRepository,
  SceneSoundEffectPlaybackPort? sceneSoundEffectPlaybackPort,
  NarrativeRuntimeActivityGate? narrativeRuntimeActivityGate,
  RuntimeDialogueSessionLoader? dialogueSessionLoader,
  Future<void> Function()? beforeLoadCommitCompletion,
  List<SceneAsset> scenes = const [],
  NarrativeEventRegistry? eventRegistry,
  GridSize sourceSize = const GridSize(width: 2, height: 3),
  GridSize targetSize = const GridSize(width: 3, height: 3),
  Future<void> Function(NarrativeEventOccurrence)? beforeNarrativeAuthorityPreparation,
  List<ProjectDialogueEntry> dialogues = const [],
  List<CinematicMediaAsset> cinematicMediaAssets = const [],
  List<MapEventDefinition> events = const [],
  List<MapEntity> sourceEntities = const [],
  List<MapEntity> targetEntities = const [],
  List<ProjectCharacterEntry> characters = const [],
  ProjectCharacterEntry? playerCharacter,
  bool narrativeV2 = false,
  MapInstanceRetentionPolicy? mapInstanceRetentionPolicy,
  List<NarrativeFactDefinition> facts = const [],
  List<WorldRuleDefinition> worldRules = const [],
  GameState? gameState,
  MapActivationReason initialMapActivationReason =
      MapActivationReason.initialBoot,
}) async {
  final root = await Directory.systemTemp.createTemp(
    'runtime_connection_canonical_arrival_',
  );
  addTearDown(() => root.delete(recursive: true));
  final source = MapData(
    id: 'source',
    name: 'Source',
    size: sourceSize,
    layers: [
      if (solidCharacter) TileLayer(id: 'objects', name: 'Objects',
        cells: List.filled(sourceSize.width * sourceSize.height, 0))
      else const MapLayer.object(id: 'objects', name: 'Objects'),
      if (sourceCollisionCells.isNotEmpty) MapLayer.collision(
        id: 'terrain-solid', name: 'Terrain',
        collisions: List.generate(sourceSize.width * sourceSize.height,
          (index) => sourceCollisionCells.contains(GridPos(x: index % sourceSize.width, y: index ~/ sourceSize.width))),
      ),
    ],
    placedElements: [if (solidCharacter) const MapPlacedElement(id: 'visibility-render-witness',
      elementId: 'original_mask', layerId: 'objects', pos: GridPos(x: 0, y: 4), applyCollision: false)],
    entities: [
      ...sourceEntities,
      MapEntity(
        id: 'start',
        name: 'Start',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: sourceFacing,
        ),
      ),
    ],
    connections: [
      ...extraConnections,
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'target',
        offset: offset,
      ),
    ],
    mapMetadata: const MapMetadata(defaultSpawnId: 'start'),
    events: events,
    triggers: sourceTriggers,
    warps: [
      ...sourceWarps,
      if (sameMapArrival)
        const MapWarp(id: 'same', pos: GridPos(x: 1, y: 1),
          targetMapId: 'source', targetPos: GridPos(x: 1, y: 1),
          triggerMode: MapWarpTriggerMode.onBump,
        ),
    ],
  );
  final target = MapData(
    id: 'target',
    name: 'Target',
    size: targetSize,
    layers: [
      TileLayer(
        id: 'objects',
        name: 'Objects',
        cells: List<int>.filled(targetSize.width * targetSize.height, 0),
      ),
    ],
    entities: [
      ...targetEntities,
      const MapEntity(
        id: 'target_start',
        name: 'Target start',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 2),
        blocksMovement: false,
        spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
      ),
      if (blockingEntity != null)
        MapEntity(
          id: 'arrival_entity',
          name: 'Arrival entity',
          kind: MapEntityKind.custom,
          pos: const GridPos(x: 0, y: 1),
          blocksMovement: blockingEntity,
          properties: const {
            mapEntityCollisionWidthProperty: '1',
            mapEntityCollisionHeightProperty: '1',
          },
        ),
    ],
    placedElements: [
      if (maskPixel != null)
        const MapPlacedElement(
          id: 'mask',
          elementId: 'original_mask',
          layerId: 'objects',
          pos: GridPos(x: 0, y: 1),
          applyCollision: true,
        ),
    ],
    connections: [
      MapConnection(
        direction: MapConnectionDirection.west,
        targetMapId: 'source',
        offset: -offset,
      ),
    ],
    gameplayZones: [
      if (water)
        const MapGameplayZone(
          id: 'water',
          name: 'Water',
          kind: GameplayZoneKind.movement,
          area: MapRect(
            pos: GridPos(x: 0, y: 1),
            size: GridSize(width: 1, height: 1),
          ),
          movement: MovementZonePayload(requiredMode: MovementMode.surf),
        ),
    ],
    warps: [
      if (warpArrival)
        MapWarp(
          id: 'arrival',
          pos: GridPos(x: 0, y: 1),
          targetMapId: arrivalTriggerMode == MapWarpTriggerMode.sceneOnly
              ? 'target'
              : 'source',
          targetPos: arrivalTriggerMode == MapWarpTriggerMode.sceneOnly
              ? const GridPos(x: 0, y: 1)
              : const GridPos(x: 1, y: 1),
          triggerMode: arrivalTriggerMode,
        ),
    ],
    mapMetadata: MapMetadata(
      defaultSpawnId: 'target_start',
      isIndoor: warpArrival,
    ),
  );
  final pixels = List<bool>.filled(32 * 32, false);
  if (maskPixel != null) pixels[maskPixel.$2 * 32 + maskPixel.$1] = true;
  final manifest = ProjectManifest(
    name: 'Canonical connection arrival fixture',
    scenes: scenes,
    dialogues: dialogues,
    cinematicMediaAssets: cinematicMediaAssets,
    characters: [...characters, ?playerCharacter],
    facts: facts,
    worldRules: worldRules,
    eventRegistry: eventRegistry ?? (narrativeV2 ? NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.v2Only, records: const [], legacyClaims: const [],
          ) : null),
    maps: [
      for (final map in [source, target, ...extraMaps])
        ProjectMapEntry(
          id: map.id,
          name: map.name,
          relativePath: 'maps/${map.id}.json',
        ),
    ],
    settings: ProjectSettings(tileWidth: 32, tileHeight: 32,
      defaultPlayerCharacterId: playerCharacter?.id,
      mapInstanceRetentionPolicy: mapInstanceRetentionPolicy,
    ),
    tilesets: const [
      ProjectTilesetEntry(
        id: 'original',
        name: 'Original',
        relativePath: 'assets/original.png',
      ),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'original', name: 'Original'),
    ],
    elements: [
      ProjectElementEntry(
        id: 'original_mask',
        name: 'Original mask',
        tilesetId: 'original',
        categoryId: 'original',
        frames: const [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
          ),
        ],
        collisionProfile: ElementCollisionProfile(
          collisionMask: ElementCollisionPixelMask(
            widthPx: 32,
            heightPx: 32,
            dataBase64: ElementCollisionMaskCodec.encodePackedBits(
              widthPx: 32,
              heightPx: 32,
              solidPixels: pixels,
            ),
          ),
        ),
      ),
    ],
  );
  ProjectValidator.validate(manifest, maps: [source, target, ...extraMaps]);
  if (eventRegistry != null) {
    final catalog = buildNarrativeSpatialEventSourceCatalog(
      project: manifest, maps: [source, target, ...extraMaps]);
    for (final record in eventRegistry.records) {
      final eventSource = record.definitionOrNull?.source;
      if (eventSource?.kind == NarrativeEventSourceKind.triggerBump ||
          eventSource?.kind == NarrativeEventSourceKind.entityBump ||
          eventSource?.kind == NarrativeEventSourceKind.entityAutorun) {
        expect(catalog.options.any((option) =>
            option.selectable && option.source == eventSource), isTrue,
          reason: 'The input test requires a genuinely available contact source.');
      }
    }
  }
  for (final scene in scenes) {
    final diagnostics = diagnoseSceneAgainstProject(scene, manifest,
      mapsById: {'source': source, 'target': target},
    );
    expect(diagnostics.hasErrors, isFalse, reason: diagnostics.diagnostics.map((d) => '${d.code}: ${d.nodeId}: ${d.message}').join('\n'),
    );
  }
  for (final map in [source, target, ...extraMaps]) {
    MapValidator.validate(map, projectDialogueContext: manifest);
  }
  await Directory(p.join(root.path, 'maps')).create();
  await Directory(p.join(root.path, 'assets')).create();
  for (final map in [source, target, ...extraMaps]) {
    await File(p.join(root.path, 'maps', '${map.id}.json'))
        .writeAsString(jsonEncode(map.toJson()));
  }
  final recorder = ui.PictureRecorder();
  final imageCanvas = ui.Canvas(recorder);
  if (solidCharacter) {
    imageCanvas.drawRect(const ui.Rect.fromLTWH(0, 0, 64, 64),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF));
  }
  final picture = recorder.endRecording();
  final imageSize = playerCharacter == null && !solidCharacter ? 32 : 64;
  final image = await picture.toImage(imageSize, imageSize);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(p.join(root.path, 'assets', 'original.png'))
      .writeAsBytes(bytes!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  for (final dialogue in dialogues) {
    final file = File(p.join(root.path, dialogue.relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsString('title: Start\n---\nHello.\n===\n');
  }
  final projectPath = p.join(root.path, 'project.json');
  await File(projectPath).writeAsString(jsonEncode(manifest.toJson()));
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectPath,
    mapId: 'source',
  );
  final game = _ConnectionGame(
    bundle: bundle,
    projectFilePath: projectPath,
    saveRepository: saveRepository,
    saveData: gameState == null ? null : saveDataFromGameState(gameState),
    sceneSoundEffectPlaybackPort: sceneSoundEffectPlaybackPort,
    narrativeRuntimeActivityGate: narrativeRuntimeActivityGate,
    dialogueSessionLoader: dialogueSessionLoader,
    beforeLoadCommitCompletion: beforeLoadCommitCompletion,
    beforeNarrativeAuthorityPreparation: beforeNarrativeAuthorityPreparation,
    initialMapActivationReason: initialMapActivationReason,
  );
  addTearDown(game.onRemove);
  game.onGameResize(Vector2(320, 240));
  await game.onLoad();
  for (var tick = 0; tick < 3000; tick++) {
    if (!game.debugIsMapActivationDispatchInFlight) break;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(game.debugIsMapActivationDispatchInFlight, isFalse);
  await game.debugLoadRuntimeMapBundleCachedForTest('target');
  for (var tick = 0; tick < 240 && !game.debugIsMapLoaded('target'); tick++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(game.debugIsMapLoaded('target'), isTrue);
  expect(game.gameStateSnapshot.currentMapId, 'source');
  expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 1));
  return (
    game: game,
    targetWorld: GameplayWorldState.initial(
      map: target,
      project: manifest,
      playerPos: const GridPos(x: 0, y: 1),
      tileWidth: 32,
      tileHeight: 32,
    ),
  );
}

ProjectCharacterEntry _timingPlayerCharacter() => ProjectCharacterEntry(
  id: 'timing-player',
  name: 'Timing player',
  tilesetId: 'original',
  frameWidth: 1,
  frameHeight: 1,
  animations: [
    for (final state in [
      CharacterAnimationState.idle,
      CharacterAnimationState.walk,
      CharacterAnimationState.run,
    ])
      for (final direction in EntityFacing.values)
        CharacterAnimation(
          state: state,
          direction: direction,
          frames: const [
            CharacterAnimationFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
            ),
          ],
        ),
  ],
);

const _routeDoor = MapEntity(
  id: 'route-door',
  name: 'Route door',
  kind: MapEntityKind.npc,
  pos: GridPos(x: 1, y: 0),
  npc: MapEntityNpcData(characterId: 'route-door-character'),
  properties: {
    mapEntityCollisionWidthProperty: '1',
    mapEntityCollisionHeightProperty: '1',
  },
);
const _routeDoorCharacter = ProjectCharacterEntry(
  id: 'route-door-character',
  name: 'Route door',
  tilesetId: 'original',
);

MapInstanceRetentionPolicy _instancePolicy() => MapInstanceRetentionPolicy(
  viewportWidthTiles: 16,
  viewportHeightTiles: 12,
  marginTiles: 6,
  clampViewportToMapIds: const {},
);

SceneAsset _instanceConditionScene(
  SceneConditionSource source, {
  bool setBefore = false,
}) => SceneAsset(
  id: 'instance-scene',
  name: 'Instance',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      if (setBefore)
        SceneNode(
          id: 'set',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload(
            consequence: SceneConsequence.setMapEventInstanceBoolean(
              mapId: source.mapId!,
              eventId: source.sourceId,
              key: source.key!,
              value: true,
            ),
          ),
        ),
      SceneNode(
        id: 'condition',
        kind: SceneNodeKind.condition,
        payload: SceneConditionPayload(conditionSource: source),
      ),
      SceneNode(
        id: 'reward',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload(
          consequence: SceneConsequence.giveMoney(amount: 100),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end, payload: SceneEndPayload()),
    ],
    edges: [
      SceneEdge(
        id: 'begin',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: setBefore ? 'set' : 'condition',
        kind: SceneEdgeKind.defaultFlow,
      ),
      if (setBefore)
        SceneEdge(
          id: 'set-done',
          fromNodeId: 'set',
          fromPortId: 'completed',
          toNodeId: 'condition',
          kind: SceneEdgeKind.actionCompleted,
        ),
      SceneEdge(
        id: 'yes',
        fromNodeId: 'condition',
        fromPortId: 'true',
        toNodeId: 'reward',
        kind: SceneEdgeKind.conditionTrue,
      ),
      SceneEdge(
        id: 'no',
        fromNodeId: 'condition',
        fromPortId: 'false',
        toNodeId: 'end',
        kind: SceneEdgeKind.conditionFalse,
      ),
      SceneEdge(
        id: 'reward-done',
        fromNodeId: 'reward',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
    ],
  ),
);

SceneAsset _warpRollbackScene({
  required bool moveNpc,
  bool movePlayer = false,
  bool npcVisibility = false,
}) => SceneAsset(
  id: 'warp-rollback-scene',
  name: 'Warp rollback',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      if (moveNpc)
        SceneNode(
          id: 'hide',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload(
            interactiveCommand: SceneInteractiveCommand.actorVisibility(
              target: SceneActorTarget.entity(
                mapId: 'source',
                entityId: 'route-door',
              ),
              visible: npcVisibility,
            ),
          ),
        ),
      if (moveNpc || movePlayer)
        SceneNode(
          id: 'route',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload(
            interactiveCommand: _actorRoute([
              {'kind': 'move', 'direction': 'west', 'durationMs': 50},
              {'kind': 'wait', 'durationMs': 100},
            ], entityId: moveNpc ? 'route-door' : null),
          ),
        ),
      SceneNode(
        id: 'warp',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload(
          interactiveCommand: SceneInteractiveCommand.warp(
            destinationMapId: 'target',
            warpId: 'arrival',
            transition: SceneWarpTransition.none,
          ),
        ),
      ),
      SceneNode(
        id: 'dialogue',
        kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(
          dialogueId: _actorDialogueEntry.id,
          yarnNodeName: 'Start',
          expectedOutcomes: ['done'],
        ),
      ),
      SceneNode(
        id: 'reward',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload(
          consequence: SceneConsequence.giveMoney(amount: 100),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end, payload: SceneEndPayload()),
    ],
    edges: [
      SceneEdge(
        id: 'begin',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: moveNpc ? 'hide' : (movePlayer ? 'route' : 'warp'),
        kind: SceneEdgeKind.defaultFlow,
      ),
      if (moveNpc)
        for (final port in ['completed', 'blocked']) ...[
          SceneEdge(
            id: 'hide-$port',
            fromNodeId: 'hide',
            fromPortId: port,
            toNodeId: 'route',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      if (moveNpc || movePlayer)
        for (final port in ['completed', 'blocked'])
          SceneEdge(
            id: 'route-$port',
            fromNodeId: 'route',
            fromPortId: port,
            toNodeId: 'warp',
            kind: SceneEdgeKind.actionCompleted,
          ),
      for (final port in ['completed', 'blocked'])
        SceneEdge(
          id: 'warp-$port',
          fromNodeId: 'warp',
          fromPortId: port,
          toNodeId: 'dialogue',
          kind: SceneEdgeKind.actionCompleted,
        ),
      SceneEdge(
        id: 'dialogue-done',
        fromNodeId: 'dialogue',
        fromPortId: 'done',
        toNodeId: 'reward',
        kind: SceneEdgeKind.dialogueOutcome,
      ),
      SceneEdge(
        id: 'dialogue-completed',
        fromNodeId: 'dialogue',
        fromPortId: 'completed',
        toNodeId: 'reward',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'rewarded',
        fromNodeId: 'reward',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
    ],
  ),
);

GameState _instanceGameState() => GameState(
  saveId: 'instance-save',
  currentMapId: 'source',
  playerPosition: const GridPos(x: 1, y: 1),
  playerFacing: EntityFacing.east,
  mapInstanceWorldState: MapInstanceWorldState(
    instancesByMapId: {
      'source': MapInstanceRuntimeState(
        instanceId: 'source-instance',
        eventBooleans: const {
          'route-door': {'A': true},
        },
      ),
      'target': MapInstanceRuntimeState(instanceId: 'target-instance'),
    },
  ),
);

SceneInteractiveCommand _actorRoute(
  List<Map<String, dynamic>> steps, {
  String? entityId,
  bool skippable = false,
  String mapId = 'source',
}) => SceneInteractiveCommand.fromJson({
  'kind': 'actorRoute',
  'target': {
    'kind': entityId == null ? 'player' : 'entity',
    'mapId': mapId,
    'entityId': ?entityId,
  },
  'steps': steps,
  'skippable': skippable,
});

final _barrierNpc = _routeDoor.copyWith(
  id: 'barrier-npc',
  name: 'Barrier NPC',
  pos: const GridPos(x: 3, y: 2),
);

SceneInteractiveCommand _allActorRoutes({String mapId = 'source'}) =>
    SceneInteractiveCommand.fromJson({
      'kind': 'waitForActorRoutes',
      'mapId': mapId,
    });

Future<String> _finishActorRoute(
  PlayableMapGame game,
  Future<String> execution,
) async {
  String? result;
  Object? failure;
  var done = false;
  execution.then(
    (value) {
      result = value;
      done = true;
    },
    onError: (Object error) {
      failure = error;
      done = true;
    },
  );
  for (var tick = 0; tick < 120 && !done; tick++) {
    await Future<void>.delayed(Duration.zero);
    if (!done) game.update(.025);
  }
  if (failure != null) throw failure!;
  expect(
    done,
    isTrue,
    reason: 'Actor route did not settle under the runtime clock.',
  );
  return result!;
}

Future<NarrativeSceneExecutionResult> _finishActorScene(PlayableMapGame game, Future<NarrativeSceneExecutionResult> execution, {
  void Function()? observe,
}) async {
  NarrativeSceneExecutionResult? result;
  execution.then((value) => result = value);
  for (var tick = 0; tick < 120 && result == null; tick++) {
    await Future<void>.delayed(Duration.zero);
    if (result == null) game.update(.025);
    observe?.call();
  }
  expect(result, isNotNull, reason: 'Actor Scene did not settle.');
  return result!;
}

Future<List<int>> _nativeWorldPixel(PlayableMapGame game, Vector2 sample) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  for (final child in game.world.children) {
    child.renderTree(canvas);
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(512, 512);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final offset = (sample.y.floor() * 512 + sample.x.floor()) * 4;
    return data!.buffer.asUint8List().sublist(offset, offset + 4);
  } finally {
    image.dispose();
    picture.dispose();
  }
}

SceneAsset _nativeTransientScene({bool failingAfterWarp = false, bool omitRestoration = false, String? actorId}) {
  SceneInteractiveCommand scoped(String mapId, List<Map<String, Object?>> steps, {String? entityId}) =>
    SceneInteractiveCommand.fromJson({'kind': 'actorRoute', 'target': {'kind': entityId == null ? 'player' : 'entity', 'mapId': mapId, 'entityId': ?entityId},
      'steps': steps, 'skippable': false, 'transientScope': 'scene'});
  final commands = <SceneInteractiveCommand>[
    scoped('source', [
      {'kind': 'through', 'enabled': true}, {'kind': 'renderAboveMap', 'enabled': true},
      {'kind': 'wait', 'durationMs': 50},
    ], entityId: actorId),
    SceneInteractiveCommand.warp(destinationMapId: 'target', warpId: 'arrival', transition: SceneWarpTransition.none),
    scoped('target', [
      {'kind': 'wait', 'durationMs': 50},
      {'kind': 'move', 'direction': 'east', 'durationMs': 100},
    ]),
    if (!failingAfterWarp && !omitRestoration) scoped('target', [
      {'kind': 'through', 'enabled': false}, {'kind': 'renderAboveMap', 'enabled': false},
      {'kind': 'wait', 'durationMs': 50},
    ]),
  ];
  return SceneAsset(id: 'native-transient', name: 'Native transient', graph: SceneGraph(startNodeId: 'start', nodes: [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    for (var index = 0; index < commands.length; index++) SceneNode(id: 'step$index', kind: SceneNodeKind.action,
      payload: SceneActionPayload.interactive(commands[index])),
    if (failingAfterWarp) SceneNode(id: 'fail', kind: SceneNodeKind.yarnDialogue,
      payload: SceneYarnDialoguePayload(dialogueId: _actorDialogueEntry.id, yarnNodeName: 'Start', expectedOutcomes: ['done'])),
    SceneNode(id: 'end', kind: SceneNodeKind.end, payload: SceneEndPayload()),
  ], edges: [
    SceneEdge(id: 'begin', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'step0', kind: SceneEdgeKind.defaultFlow),
    for (var index = 0; index < commands.length; index++) SceneEdge(id: 'step$index', fromNodeId: 'step$index',
      fromPortId: 'completed', toNodeId: index + 1 < commands.length ? 'step${index + 1}' : failingAfterWarp ? 'fail' : 'end',
      kind: SceneEdgeKind.actionCompleted),
    if (failingAfterWarp) SceneEdge(id: 'fail-end', fromNodeId: 'fail', fromPortId: 'done', toNodeId: 'end', kind: SceneEdgeKind.dialogueOutcome),
  ]));
}

SceneAsset _actorRewardScene({bool failingDialogue = false, String? entityId,
}) => SceneAsset(
  id: 'actor-scene', name: 'Actor scene', graph: SceneGraph(startNodeId: 'start', nodes: [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    SceneNode(id: 'hide', kind: SceneNodeKind.action, payload: SceneActionPayload(interactiveCommand: SceneInteractiveCommand.fromJson({'kind': 'actorVisibility', 'target': {'kind': 'player', 'mapId': 'source'}, 'visible': false,
          }),
        ),
      ),
    SceneNode(id: 'route', kind: SceneNodeKind.action, payload: SceneActionPayload(interactiveCommand: _actorRoute([{'kind': 'move', 'direction': 'west', 'durationMs': 250},
          ], entityId: entityId),
        ),
      ),
    SceneNode(id: 'show', kind: SceneNodeKind.action, payload: SceneActionPayload(interactiveCommand: SceneInteractiveCommand.fromJson({'kind': 'actorVisibility', 'target': {'kind': 'player', 'mapId': 'source'}, 'visible': true,
          }),
        ),
      ),
    if (failingDialogue) SceneNode(id: 'dialogue', kind: SceneNodeKind.yarnDialogue, payload: SceneYarnDialoguePayload(dialogueId: _actorDialogueEntry.id, yarnNodeName: 'Start', expectedOutcomes: ['done'],
          ),
        ),
    SceneNode(id: 'reward', kind: SceneNodeKind.action, payload: SceneActionPayload(consequence: SceneConsequence.giveMoney(amount: 100),
        ),
      ),
    SceneNode(id: 'end', kind: SceneNodeKind.end, payload: SceneEndPayload()),
  ], edges: [
    SceneEdge(id: 'begin', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'hide', kind: SceneEdgeKind.defaultFlow,
      ),
    for (final port in ['completed', 'blocked']) ...[
      SceneEdge(id: 'hide-$port', fromNodeId: 'hide', fromPortId: port, toNodeId: 'route', kind: SceneEdgeKind.actionCompleted,
        ),
      SceneEdge(id: 'route-$port', fromNodeId: 'route', fromPortId: port, toNodeId: 'show', kind: SceneEdgeKind.actionCompleted,
        ),
      SceneEdge(id: 'show-$port', fromNodeId: 'show', fromPortId: port, toNodeId: failingDialogue ? 'dialogue' : 'reward', kind: SceneEdgeKind.actionCompleted,
        ),
    ],
    if (failingDialogue) SceneEdge(id: 'dialogue-done', fromNodeId: 'dialogue', fromPortId: 'completed', toNodeId: 'reward', kind: SceneEdgeKind.defaultFlow,
        ),
    if (failingDialogue) SceneEdge(id: 'dialogue-outcome', fromNodeId: 'dialogue', fromPortId: 'done', toNodeId: 'reward', kind: SceneEdgeKind.dialogueOutcome,
        ),
    SceneEdge(id: 'rewarded', fromNodeId: 'reward', fromPortId: 'completed', toNodeId: 'end', kind: SceneEdgeKind.actionCompleted,
      ),
  ],
  ),
);

final _actorMapEvent = MapEventDefinition(
  id: 'actor-map-event',
  title: 'Actor map event',
  position: const EventPosition(layerId: 'objects', x: 0, y: 1),
  pages: [MapEventPage(pageNumber: 0,
    sceneTarget: const MapEventSceneTarget(sceneId: 'actor-scene'),
    ),
  ],
);

SceneAsset _actorHoldScene() => SceneAsset(
  id: 'actor-scene',
  name: 'Actor hold scene',
  graph: SceneGraph(startNodeId: 'start', nodes: [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    SceneNode(id: 'hold', kind: SceneNodeKind.action, payload: SceneActionPayload(
      interactiveCommand: _actorRoute([
        {'kind': 'face', 'direction': 'north', 'durationMs': 400},
      ], entityId: 'route-door'),
    ),
      ),
    SceneNode(id: 'end', kind: SceneNodeKind.end, payload: SceneEndPayload()),
  ], edges: [
    SceneEdge(id: 'start-hold', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'hold', kind: SceneEdgeKind.defaultFlow,
      ),
    for (final port in ['completed', 'blocked'])
      SceneEdge(id: 'hold-$port', fromNodeId: 'hold', fromPortId: port, toNodeId: 'end', kind: SceneEdgeKind.actionCompleted,
        ),
  ],
  ),
);

Future<void> _finishMapEventScene(PlayableMapGame game, NarrativeRuntimeActivityGate activity, bool Function() observed,
) async {
  for (var tick = 0; tick < 3000; tick++) {
    if (observed() && activity.activity == NarrativeRuntimeActivity.idle) break;
    game.update(.025);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(observed(), isTrue, reason: 'The route must run before the Scene failure.',
  );
  expect(activity.activity, NarrativeRuntimeActivity.idle);
}

const _actorDialogueEntry = ProjectDialogueEntry(id: 'actor-dialogue', name: 'Actor dialogue', relativePath: 'dialogues/actor.yarn', declaredOutcomes: [DialogueDeclaredOutcome(id: 'done', label: 'Done')],
);

final class _ConnectionGame extends PlayableMapGame {
  _ConnectionGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveRepository,
    super.saveData,
    super.sceneSoundEffectPlaybackPort,
    super.narrativeRuntimeActivityGate,
    super.dialogueSessionLoader,
    super.beforeLoadCommitCompletion,
    super.beforeNarrativeAuthorityPreparation,
    super.initialMapActivationReason,
  });

  @override
  bool get isLoaded => true;
}

final class _MemorySaveRepository implements GameSaveRepository {
  Map<String, dynamic>? _savedJson;
  Completer<GameState?>? loadGate;
  final loadEntered = Completer<void>();

  @override
  Future<void> save(GameState state) async => _savedJson = state.toJson();

  @override
  Future<GameState?> load() async {
    if (!loadEntered.isCompleted) loadEntered.complete();
    return loadGate == null
        ? (_savedJson == null ? null : GameState.fromJson(_savedJson!))
        : await loadGate!.future;
  }

  @override
  Future<bool> exists() async => _savedJson != null;

  @override
  Future<void> delete() async => _savedJson = null;
}

SceneInteractiveCommand _tone(double red, int durationMs) =>
    SceneInteractiveCommand.fromJson({
      'kind': 'worldTone', 'red': red, 'green': red,
      'blue': red, 'gray': 0, 'durationMs': durationMs,
    });

SceneInteractiveCommand _sound() => SceneInteractiveCommand.fromJson({
  'kind': 'playSoundEffect', 'mediaAssetId': 'door', 'volume': .8,
});

CinematicMediaAsset _doorSound({
  bool loop = false,
  CinematicMediaAssetKind kind = CinematicMediaAssetKind.sound,
}) => CinematicMediaAsset(
  id: 'door', label: 'Door', kind: kind, relativePath: 'assets/door.wav',
  loopByDefault: loop,
);

SceneAsset _toneScene({bool failingDialogue = false}) => SceneAsset(
  id: 'tone-scene', name: 'Tone scene',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'tone', kind: SceneNodeKind.action,
        payload: SceneActionPayload(interactiveCommand: _tone(failingDialogue ? -255 : 0, failingDialogue ? 0 : 300,
          ),
        ),
      ),
      if (failingDialogue) SceneNode(id: 'dialogue', kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(dialogueId: 'missing-file', yarnNodeName: 'Start', expectedOutcomes: ['done'],
          ),
        ),
      SceneNode(id: 'end', kind: SceneNodeKind.end, payload: SceneEndPayload()),
    ],
    edges: [
      SceneEdge(id: 'begin', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'tone', kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(id: 'done', fromNodeId: 'tone', fromPortId: 'completed', toNodeId: failingDialogue ? 'dialogue' : 'end', kind: SceneEdgeKind.actionCompleted,
      ),
      SceneEdge(id: 'blocked', fromNodeId: 'tone', fromPortId: 'blocked', toNodeId: 'end', kind: SceneEdgeKind.actionCompleted,
      ),
      if (failingDialogue) SceneEdge(id: 'dialogue-completed', fromNodeId: 'dialogue', fromPortId: 'completed', toNodeId: 'end', kind: SceneEdgeKind.defaultFlow,
        ),
      if (failingDialogue) SceneEdge(id: 'dialogue-done', fromNodeId: 'dialogue', fromPortId: 'done', toNodeId: 'end', kind: SceneEdgeKind.dialogueOutcome,
        ),
    ],
  ),
);

SceneAsset _soundRewardScene() => SceneAsset(
  id: 'sound-scene', name: 'Sound scene',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'sound', kind: SceneNodeKind.action,
        payload: SceneActionPayload(interactiveCommand: _sound()),
      ),
      SceneNode(id: 'reward', kind: SceneNodeKind.action,
        payload: SceneActionPayload(consequence: SceneConsequence.giveMoney(amount: 100),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end, payload: SceneEndPayload()),
    ],
    edges: [
      SceneEdge(id: 'begin', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'sound', kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(id: 'started', fromNodeId: 'sound', fromPortId: 'completed', toNodeId: 'reward', kind: SceneEdgeKind.actionCompleted,
      ),
      SceneEdge(id: 'blocked', fromNodeId: 'sound', fromPortId: 'blocked', toNodeId: 'reward', kind: SceneEdgeKind.actionCompleted,
      ),
      SceneEdge(id: 'rewarded', fromNodeId: 'reward', fromPortId: 'completed', toNodeId: 'end', kind: SceneEdgeKind.actionCompleted,
      ),
    ],
  ),
);

final class _PendingNarrativeDriver
    implements FlameCinematicAudioDriver, FlameCinematicAudioLoopDriver {
  final handle = Object();
  final entered = Completer<void>();
  final gate = Completer<Object>();
  final stopped = <Object>[];

  @override
  Future<Object> play(String path, {required double volume, required bool loop,
  }) {
    entered.complete();
    return gate.future;
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Future<void> stop(Object handle) async => stopped.add(handle);

  @override
  Stream<void> onComplete(Object handle) => const Stream<void>.empty();

  @override
  Future<void> seekAndResume(Object handle, Duration position) async {}
}

final class _SceneSoundPort implements SceneSoundEffectPlaybackPort {
  final calls = <({String mediaAssetId, double volume, String playbackId})>[];
  final entered = Completer<void>();
  Completer<void>? gate;

  @override
  Future<void> playSoundEffect(String mediaAssetId, {
    required double volume, required String playbackId,
  }) async {
    calls.add((mediaAssetId: mediaAssetId, volume: volume, playbackId: playbackId,
    ));
    if (!entered.isCompleted) entered.complete();
    await gate?.future;
  }
}

const _entityBumpEventId = 'evt_019abcde-1400-7000-8000-000000000001';

NarrativeEventRegistry _entityBumpRegistry({
  NarrativeEventReusePolicy reusePolicy = NarrativeEventReusePolicy.oneShot,
}) => NarrativeEventRegistry(
  schemaVersion: 1,
  mode: EventSystemMode.v2Only,
  records: [
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: _entityBumpEventId,
        name: 'Contact',
        source: NarrativeEventSourceRef.fromJson({
          'kind': 'entityBump',
          'mapId': 'source',
          'entityId': 'route-door',
        }),
        sceneId: 'entity-bump-scene',
        conditions: const [],
        reusePolicy: reusePolicy,
        priority: 0,
        order: 0,
      ),
      enabled: true,
    ),
  ],
  legacyClaims: const [],
);

SceneAsset _entityBumpScene({SceneInteractiveCommand? beforeReward}) =>
    SceneAsset(
      id: 'entity-bump-scene',
      name: 'Contact',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          if (beforeReward != null)
            SceneNode(
              id: 'before',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload(interactiveCommand: beforeReward),
            ),
          SceneNode(
            id: 'reward',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload(
              consequence: SceneConsequence.giveMoney(amount: 100),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: beforeReward == null ? 'reward' : 'before',
            kind: SceneEdgeKind.defaultFlow,
          ),
          if (beforeReward != null) ...[
            SceneEdge(
              id: 'before-completed',
              fromNodeId: 'before',
              fromPortId: 'completed',
              toNodeId: 'reward',
              kind: SceneEdgeKind.actionCompleted,
            ),
            if (beforeReward.outputPortIds.contains('blocked'))
              SceneEdge(
              id: 'before-blocked',
              fromNodeId: 'before',
              fromPortId: 'blocked',
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
          ],
          SceneEdge(
            id: 'reward',
            fromNodeId: 'reward',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    );

Future<void> _settleEntityBump(PlayableMapGame game) async {
  for (var tick = 0; tick < 300; tick++) {
    game.update(.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    if (!game.debugIsNarrativeSpatialDispatchInFlight &&
        !game.debugIsPlayerStepping &&
        !game.debugHasPendingMapTransition &&
        !game.debugIsMapActivationDispatchInFlight &&
        !game.debugIsNarrativeOutcomeWorkInFlight &&
        game.debugFlowPhaseName == 'overworld') {
      return;
    }
  }
  fail('Entity bump did not settle.');
}

Future<void> _bumpUp(PlayableMapGame game) async {
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.press(RuntimeInputControl.up),
  );
  game.update(.016);
  game.handleRuntimeInputEvent(
    const RuntimeInputEvent.release(RuntimeInputControl.up),
  );
  await _settleEntityBump(game);
}

NarrativeEventRegistry _autorunRegistryForTest({
  String mapId = 'source',
  String entityId = 'route-door',
  String eventId = _entityBumpEventId,
  String sceneId = 'instance-scene',
  List<NarrativeEventCondition>? conditions,
  NarrativeEventReusePolicy reusePolicy = NarrativeEventReusePolicy.reusable,
  int priority = 0,
  int order = 0,
}) => NarrativeEventRegistry(
  schemaVersion: 1,
  mode: EventSystemMode.v2Only,
  records: [
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: eventId,
        name: 'Automatic event',
        source: NarrativeEventSourceRef.entityAutorun(mapId, entityId),
        sceneId: sceneId,
        conditions:
            conditions ??
            [
              NarrativeEventCondition.mapEventInstanceBoolean(
                mapId: mapId,
                eventId: entityId,
                key: 'A',
                expectedValue: false,
              ),
            ],
        reusePolicy: reusePolicy,
        priority: priority,
        order: order,
      ),
      enabled: true,
    ),
  ],
  legacyClaims: const [],
);

const _logicalAutorunOwner = MapEntity(
  id: 'route-door',
  name: 'Logical automatic event',
  kind: MapEntityKind.custom,
  pos: GridPos(x: 1, y: 0),
  blocksMovement: false,
);

const _autorunSourceArrival = MapWarp(
  id: 'autorun-source-arrival',
  pos: GridPos(x: 1, y: 1),
  targetMapId: 'source',
  targetPos: GridPos(x: 1, y: 1),
  triggerMode: MapWarpTriggerMode.sceneOnly,
);

SceneConditionSource _autorunBooleanSource([String mapId = 'source']) =>
    SceneConditionSource.mapEventInstanceBoolean(
      mapId: mapId,
      eventId: 'route-door',
      key: 'A',
    );

bool _autorunBoolean(PlayableMapGame game, [String mapId = 'source']) {
  final state = game.gameStateSnapshot.mapInstanceWorldState;
  return state.eventBoolean(state.instanceRef(mapId)!, 'route-door', 'A');
}

GameState _autorunInitialState(bool value) => GameState(
  saveId: 'autorun-save',
  currentMapId: 'source',
  playerPosition: const GridPos(x: 1, y: 1),
  playerFacing: EntityFacing.east,
  mapInstanceWorldState: MapInstanceWorldState(
    instancesByMapId: {
      'source': MapInstanceRuntimeState(
        instanceId: 'autorun-initial-instance',
        eventBooleans: {
          'route-door': {'A': value},
        },
      ),
    },
  ),
);

Future<void> _pumpAutorun(PlayableMapGame game, int ticks) async {
  for (var tick = 0; tick < ticks; tick++) {
    game.update(.025);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  await _waitForAutorunIdle(game);
}

Future<void> _waitForAutorunIdle(PlayableMapGame game) async {
  for (var tick = 0; tick < 1000 && game.debugIsEntityAutorunInFlight; tick++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(game.debugIsEntityAutorunInFlight, isFalse);
}

Future<void> _pumpAutorunUntil(
  PlayableMapGame game,
  bool Function() completed,
) async {
  for (var tick = 0; tick < 500; tick++) {
    if (completed() &&
        !game.debugIsEntityAutorunInFlight &&
        !game.debugIsMapActivationDispatchInFlight) {
      break;
    }
    game.update(.025);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(completed(), isTrue);
  expect(game.debugIsEntityAutorunInFlight, isFalse);
}

SceneAsset _autorunRollbackScene() {
  final scene = _warpRollbackScene(moveNpc: false);
  return SceneAsset(
    id: scene.id,
    name: scene.name,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: [
        ...scene.graph.nodes,
        SceneNode(
          id: 'set-local',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload(
            consequence: SceneConsequence.setMapEventInstanceBoolean(
              mapId: 'source',
              eventId: 'route-door',
              key: 'A',
              value: true,
            ),
          ),
        ),
      ],
      edges: [
        for (final edge in scene.graph.edges)
          edge.fromNodeId == 'start'
              ? SceneEdge.fromJson({...edge.toJson(), 'toNodeId': 'set-local'})
              : edge,
        SceneEdge(
          id: 'set-local-completed',
          fromNodeId: 'set-local',
          fromPortId: 'completed',
          toNodeId: 'warp',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _autorunAnchorScene() => SceneAsset(
  id: 'autorun-anchor',
  name: 'Automatic arrival',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'anchor',
        kind: SceneNodeKind.condition,
        payload: SceneConditionPayload(
          conditionSource: SceneConditionSource.playerAtEntityAnchor(
            mapId: 'source',
            entityId: 'route-door',
          ),
        ),
      ),
      SceneNode(
        id: 'route',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload(
          interactiveCommand: _actorRoute([
            {'kind': 'move', 'direction': 'south', 'durationMs': 100},
          ]),
        ),
      ),
      SceneNode(
        id: 'set',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload(
          consequence: SceneConsequence.setMapEventInstanceBoolean(
            mapId: 'source',
            eventId: 'route-door',
            key: 'A',
            value: true,
          ),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'anchor',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'on-anchor',
        fromNodeId: 'anchor',
        fromPortId: 'true',
        toNodeId: 'route',
        kind: SceneEdgeKind.conditionTrue,
      ),
      SceneEdge(
        id: 'away-anchor',
        fromNodeId: 'anchor',
        fromPortId: 'false',
        toNodeId: 'set',
        kind: SceneEdgeKind.conditionFalse,
      ),
      for (final port in ['completed', 'blocked'])
        SceneEdge(
          id: 'route-$port',
          fromNodeId: 'route',
          fromPortId: port,
          toNodeId: 'set',
          kind: SceneEdgeKind.actionCompleted,
        ),
      SceneEdge(
        id: 'set',
        fromNodeId: 'set',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
    ],
  ),
);

final class _AutorunFileSaveRepository extends FileGameSaveRepository {
  _AutorunFileSaveRepository(this.directory);

  final Directory directory;

  @override
  Future<String> getSaveFilePath() async =>
      p.join(directory.path, 'game_save.json');
}

const _terrainBumpTrigger = MapTrigger(
  id: 'terrain-contact',
  name: 'Door threshold',
  type: TriggerType.event,
  area: MapRect(pos: GridPos(x: 1, y: 0), size: GridSize(width: 1, height: 1)),
);

NarrativeEventRegistry _triggerBumpRegistry({
  NarrativeEventReusePolicy reusePolicy = NarrativeEventReusePolicy.oneShot,
}) => NarrativeEventRegistry(
  schemaVersion: 1,
  mode: EventSystemMode.v2Only,
  records: [
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: _entityBumpEventId,
        name: 'Terrain contact',
        source: NarrativeEventSourceRef.triggerBump(
          'source',
          'terrain-contact',
        ),
        sceneId: 'entity-bump-scene',
        conditions: const [],
        reusePolicy: reusePolicy,
        priority: 0,
        order: 0,
      ),
      enabled: true,
    ),
  ],
  legacyClaims: const [],
);

SceneAsset _secondTriggerBumpScene() => SceneAsset.fromJson({
  ..._entityBumpScene().toJson(),
  'id': 'second-contact-scene',
});

NarrativeEventRegistry _overlappingTriggerBumpRegistry() =>
    NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        for (final entry in [
          (
            id: _entityBumpEventId,
            triggerId: 'a',
            sceneId: 'entity-bump-scene',
            policy: NarrativeEventReusePolicy.oneShot,
          ),
          (
            id: 'evt_019abcde-1400-7000-8000-000000000002',
            triggerId: 'z',
            sceneId: 'second-contact-scene',
            policy: NarrativeEventReusePolicy.reusable,
          ),
        ])
          NarrativeEventRecord.configuredStructurallyUnchecked(
            NarrativeEventDefinition(
              id: entry.id,
              name: entry.triggerId,
              source: NarrativeEventSourceRef.triggerBump(
                'source',
                entry.triggerId,
              ),
              sceneId: entry.sceneId,
              conditions: const [],
              reusePolicy: entry.policy,
              priority: 0,
              order: 0,
            ),
            enabled: true,
          ),
      ],
      legacyClaims: const [],
    );
