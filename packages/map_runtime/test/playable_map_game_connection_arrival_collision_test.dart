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
import 'package:map_runtime/src/presentation/flame/overworld_actor_component.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart' show RuntimeDialogueSessionLoader;
import 'package:map_runtime/src/presentation/flame/warp_transition_overlay_component.dart';
import 'package:path/path.dart' as p;

void main() {
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
    'connection refuses an out-of-bounds offset before changing the map',
    () async {
      final fixture = await _fixture(offset: 4);

      await _move(fixture.game, RuntimeInputControl.right);

      _expectRejected(fixture.game, 'Connection invalid');
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
  bool? blockingEntity,
  int offset = 0,
  bool water = false,
  bool warpArrival = false,
  bool sameMapArrival = false,
  MapWarpTriggerMode arrivalTriggerMode = MapWarpTriggerMode.onBump,
  List<MapWarp> sourceWarps = const [],
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
    layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
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
      MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'target',
        offset: offset,
      ),
    ],
    mapMetadata: const MapMetadata(defaultSpawnId: 'start'),
    events: events,
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
    characters: characters,
    facts: facts,
    worldRules: worldRules,
    eventRegistry: eventRegistry ?? (narrativeV2 ? NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.v2Only, records: const [], legacyClaims: const [],
          ) : null),
    maps: [
      for (final map in [source, target])
        ProjectMapEntry(
          id: map.id,
          name: map.name,
          relativePath: 'maps/${map.id}.json',
        ),
    ],
    settings: ProjectSettings(tileWidth: 32, tileHeight: 32,
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
  ProjectValidator.validate(manifest, maps: [source, target]);
  if (eventRegistry != null) {
    final catalog = buildNarrativeSpatialEventSourceCatalog(
      project: manifest, maps: [source, target]);
    for (final record in eventRegistry.records) {
      final eventSource = record.definitionOrNull?.source;
      if (eventSource?.kind == NarrativeEventSourceKind.entityBump ||
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
    expect(diagnostics.hasErrors, isFalse, reason: diagnostics.diagnostics.toString(),
    );
  }
  for (final map in [source, target]) {
    MapValidator.validate(map, projectDialogueContext: manifest);
  }
  await Directory(p.join(root.path, 'maps')).create();
  await Directory(p.join(root.path, 'assets')).create();
  for (final map in [source, target]) {
    await File(p.join(root.path, 'maps', '${map.id}.json'))
        .writeAsString(jsonEncode(map.toJson()));
  }
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder);
  final picture = recorder.endRecording();
  final image = await picture.toImage(32, 32);
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
