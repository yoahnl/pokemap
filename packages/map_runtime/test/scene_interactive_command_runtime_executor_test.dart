import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('dispatches each closed command kind once and preserves order',
      () async {
    final calls = <SceneInteractiveCommandKind>[];
    Future<String> handler(SceneInteractiveCommand command) async {
      calls.add(command.kind);
      return command.outputPortIds.first;
    }

    final executor = SceneInteractiveCommandRuntimeExecutor(
      giveItem: handler,
      warp: handler,
      wait: handler,
      waitForActorRoutes: handler,
      moveNpc: handler,
      movePlatform: handler,
      openShop: handler,
      openHeal: handler,
      openPc: handler,
      openWorldService: (request) async {
        calls.add(switch (request) {
          OpenShopService() => SceneInteractiveCommandKind.openShop,
          OpenHealService() => SceneInteractiveCommandKind.openHeal,
          OpenPcService() => SceneInteractiveCommandKind.openPc,
            OpenPartyTradeService() =>
              SceneInteractiveCommandKind.openPartyTrade,
          OpenRegionalMapService() => SceneInteractiveCommandKind.openRegionalMap,
          _ => throw StateError('Unexpected service'),
        });
        return 'completed';
      },
      playCharacterAnimation: handler,
      playModelAnimation: handler,
      railJourney: handler,
      worldTone: handler,
      playSoundEffect: handler,
      actorRoute: handler,
      actorVisibility: handler,
    );
    for (final command in <SceneInteractiveCommand>[
      SceneInteractiveCommand.giveItem(itemId: 'tm23', quantity: 1),
      SceneInteractiveCommand.warp(
        destinationMapId: 'map.port',
        warpId: 'warp.arrival',
      ),
      SceneInteractiveCommand.wait(durationMs: 400),
      SceneInteractiveCommand.waitForActorRoutes(mapId: 'map.port'),
      SceneInteractiveCommand.worldTone(red: -255, green: -255, blue: -255, gray: 0, durationMs: 300),
      SceneInteractiveCommand.playSoundEffect(mediaAssetId: 'door', volume: .8),
      SceneInteractiveCommand.actorRoute(target: SceneActorTarget.player(mapId: 'map.port'), steps: [SceneActorRouteStep.wait(durationMs: 0)]),
      SceneInteractiveCommand.actorVisibility(target: SceneActorTarget.player(mapId: 'map.port'), visible: false),
      SceneInteractiveCommand.moveNpc(
        mapId: 'map.port',
        entityId: 'npc.guard',
        warpId: 'warp.arrival',
      ),
      SceneInteractiveCommand.movePlatform(
        mapId: 'map.port',
        platformId: 'platform',
        motion: MovingPlatformMotion.forward,
      ),
      SceneInteractiveCommand.openShop(shopId: 'shop.port'),
      SceneInteractiveCommand.openHeal(),
      SceneInteractiveCommand.openPc(),
      SceneInteractiveCommand.openRegionalMap(),
        SceneInteractiveCommand.openPartyTrade(),
      SceneInteractiveCommand.playCharacterAnimation(
        runtimeCommand: CharacterCustomAnimationRuntimeCommand(
          actorId: 'npc.guard',
          definitionId: 'wave',
        ),
      ),
      SceneInteractiveCommand.playModelAnimation(
        mapId: 'map.port',
        instanceId: 'door',
        animationIndex: 0,
        blocksMovementAfter: false,
      ),
      SceneInteractiveCommand.railJourney(
        commandId: 'board-t1',
        journeyId: 'T1',
        operation: SceneRailJourneyOperation.begin,
        direction: RailJourneyDirection.outbound,
        doorSide: RailJourneyDoorSide.west,
      ),
    ]) {
      final result = await executor.execute(
        SceneRuntimePlanIntent.executeInteractiveCommand(command: command),
      );
      expect(result, command.outputPortIds.first);
    }

    expect(calls, SceneInteractiveCommandKind.values);
  });

  test('presentation commands require their dedicated consumer', () async {
    final executor = SceneInteractiveCommandRuntimeExecutor(warp: (_) async => 'completed');
    for (final command in <SceneInteractiveCommand>[
      SceneInteractiveCommand.wait(durationMs: 0),
      SceneInteractiveCommand.waitForActorRoutes(mapId: 'map.port'),
      SceneInteractiveCommand.worldTone(red: 0, green: 0, blue: 0, gray: 0, durationMs: 300),
      SceneInteractiveCommand.playSoundEffect(mediaAssetId: 'door', volume: .8),
      SceneInteractiveCommand.actorRoute(target: SceneActorTarget.player(mapId: 'map.port'), steps: [SceneActorRouteStep.wait(durationMs: 0)]),
      SceneInteractiveCommand.actorVisibility(target: SceneActorTarget.player(mapId: 'map.port'), visible: false),
    ]) {
      await expectLater(executor.execute(SceneRuntimePlanIntent.executeInteractiveCommand(command: command)), throwsStateError);
    }
  });

  test('regional map awaits its world service before advancing the scene', () async {
    final release = Completer<String>();
    var calls = 0;
    var finished = false;
    final executor = SceneInteractiveCommandRuntimeExecutor(
        warp: (_) async => 'completed',
        openWorldService: (request) {
          expect(request, isA<OpenRegionalMapService>());
          expect(request.kind, RuntimeWorldServiceKind.regionalMap);
          calls++;
          return release.future;
        });
    final execution = executor.execute(SceneRuntimePlanIntent.executeInteractiveCommand(
        command: SceneInteractiveCommand.openRegionalMap()));
    execution.then((_) => finished = true);
    await Future<void>.delayed(Duration.zero);
    expect(finished, isFalse);
    expect(calls, 1);
    release.complete('completed');
    expect(await execution, 'completed');
  });

  test(
    'forced actor route barrier is awaited before a following warp',
    () async {
      final calls = <String>[];
      final entered = Completer<void>();
      final release = Completer<String>();
      final commandExecutor = SceneInteractiveCommandRuntimeExecutor(
        waitForActorRoutes: (command) async {
          expect(
            (command as SceneWaitForActorRoutesInteractiveCommand).mapId,
            'map.port',
          );
          calls.add('routes:start');
          entered.complete();
          final port = await release.future;
          calls.add('routes:end');
          return port;
        },
        warp: (_) async {
          calls.add('warp');
          return 'completed';
        },
      );
      final running =
          SceneRuntimeExecutor(
            callbacks: SceneRuntimeExecutionCallbacks(
              evaluateCondition: (_) => 'false',
              showDialogue: (_) => 'completed',
              startBattle: (_) => 'victory',
              playCinematic: (_) => 'completed',
              applyConsequence: (_) => 'completed',
              executeInteractiveCommand: commandExecutor.execute,
            ),
          ).execute(
            buildSceneRuntimePlan(
              _scene(
                beforeWarp: SceneInteractiveCommand.waitForActorRoutes(
                  mapId: 'map.port',
                ),
              ),
            ).plan!,
          );
      await entered.future.timeout(const Duration(seconds: 1));
      expect(calls, ['routes:start']);
      release.complete('completed');
      expect((await running).status, SceneRuntimeExecutionStatus.completed);
      expect(calls, ['routes:start', 'routes:end', 'warp']);
    },
  );

  test(
    'forced actor route barrier refuses an undeclared blocked result',
    () async {
      final executor = SceneInteractiveCommandRuntimeExecutor(
        warp: (_) async => 'completed',
        waitForActorRoutes: (_) async => 'blocked',
      );
      await expectLater(
        executor.execute(
          SceneRuntimePlanIntent.executeInteractiveCommand(
            command: SceneInteractiveCommand.waitForActorRoutes(
              mapId: 'map.port',
            ),
          ),
        ),
        throwsStateError,
      );
    },
  );

  test('forced actor route barrier preserves consumer failure', () async {
    final failure = StateError('Interrupted forced routes.');
    final executor = SceneInteractiveCommandRuntimeExecutor(
      warp: (_) async => 'completed',
      waitForActorRoutes: (_) async => throw failure,
    );
    await expectLater(
      executor.execute(
        SceneRuntimePlanIntent.executeInteractiveCommand(
          command: SceneInteractiveCommand.waitForActorRoutes(
            mapId: 'map.port',
          ),
        ),
      ),
      throwsA(same(failure)),
    );
  });

  test('Scene wait is awaited before the following command', () async {
    final calls = <String>[];
    final entered = Completer<void>();
    final release = Completer<String>();
    final commandExecutor = SceneInteractiveCommandRuntimeExecutor(
      wait: (command) async {
        expect((command as SceneWaitInteractiveCommand).durationMs, 400);
        calls.add('wait:start');
        entered.complete();
        final port = await release.future;
        calls.add('wait:end');
        return port;
      },
      warp: (_) async {
        calls.add('warp');
        return 'completed';
      },
    );
    var completed = false;
    final running = SceneRuntimeExecutor(
      callbacks: SceneRuntimeExecutionCallbacks(
        evaluateCondition: (_) => 'false',
        showDialogue: (_) => 'completed',
        startBattle: (_) => 'victory',
        playCinematic: (_) => 'completed',
        applyConsequence: (_) => 'completed',
        executeInteractiveCommand: commandExecutor.execute,
      ),
    ).execute(buildSceneRuntimePlan(
      _scene(beforeWarp: SceneInteractiveCommand.wait(durationMs: 400)),
    ).plan!).then((result) {
      completed = true;
      return result;
    });
    await entered.future.timeout(const Duration(seconds: 1));
    expect(calls, ['wait:start']);
    expect(completed, isFalse);
    release.complete('completed');
    final result = await running;
    expect(result.status, SceneRuntimeExecutionStatus.completed);
    expect(calls, ['wait:start', 'wait:end', 'warp']);
  });

  test('Scene wait refuses a blocked output port', () async {
    final command = SceneInteractiveCommand.wait(durationMs: 400);
    final executor = SceneInteractiveCommandRuntimeExecutor(
      warp: (_) async => 'completed',
      wait: (_) async => 'blocked',
    );
    expect(command.outputPortIds, ['completed']);
    await expectLater(
      executor.execute(
        SceneRuntimePlanIntent.executeInteractiveCommand(command: command),
      ),
      throwsStateError,
    );
  });

  test('Scene wait propagates its consumer failure', () async {
    final failure = StateError('Wait consumer failed.');
    final executor = SceneInteractiveCommandRuntimeExecutor(
      warp: (_) async => 'completed',
      wait: (_) async => throw failure,
    );
    await expectLater(
      executor.execute(
        SceneRuntimePlanIntent.executeInteractiveCommand(
          command: SceneInteractiveCommand.wait(durationMs: 400),
        ),
      ),
      throwsA(same(failure)),
    );
  });

  test('custom character animation is awaited through its dedicated handler',
      () async {
    SceneCharacterCustomAnimationInteractiveCommand? received;
    final executor = SceneInteractiveCommandRuntimeExecutor(
      warp: (_) async => 'completed',
      playCharacterAnimation: (command) async {
        received = command as SceneCharacterCustomAnimationInteractiveCommand;
        return 'fallback';
      },
    );
    final command = SceneInteractiveCommand.playCharacterAnimation(
      runtimeCommand: CharacterCustomAnimationRuntimeCommand(
        actorId: 'npc.guard',
        definitionId: 'wave',
      ),
    );

    final output = await executor.execute(
      SceneRuntimePlanIntent.executeInteractiveCommand(command: command),
    );

    expect(output, 'fallback');
    expect(received?.runtimeCommand.definitionId, 'wave');
  });

  test('projects Scene services into typed world requests', () async {
    final requests = <RuntimeWorldServiceRequest>[];
    final executor = SceneInteractiveCommandRuntimeExecutor(
      warp: (_) async => 'completed',
      openWorldService: (request) async {
        requests.add(request);
        return 'cancelled';
      },
    );

    await executor.execute(
      SceneRuntimePlanIntent.executeInteractiveCommand(
        command: SceneInteractiveCommand.openShop(shopId: 'shop.port'),
      ),
    );
    await executor.execute(
      SceneRuntimePlanIntent.executeInteractiveCommand(
        command: SceneInteractiveCommand.openHeal(
          requiresConfirmation: false,
        ),
      ),
    );
    await executor.execute(
      SceneRuntimePlanIntent.executeInteractiveCommand(
        command: SceneInteractiveCommand.openPc(storageId: 'regional'),
      ),
    );

    expect(
      requests,
      <Object>[
        isA<OpenShopService>()
            .having((value) => value.shopId, 'shopId', 'shop.port')
            .having(
              (value) => value.interactionId,
              'interactionId',
              'scene.openShop:shop.port',
            ),
        isA<OpenHealService>()
            .having(
              (value) => value.requiresConfirmation,
              'requiresConfirmation',
              isFalse,
            )
            .having(
              (value) => value.interactionId,
              'interactionId',
              'scene.openHeal',
            ),
        isA<OpenPcService>()
            .having((value) => value.storageId, 'storageId', 'regional')
            .having(
              (value) => value.interactionId,
              'interactionId',
              'scene.openPc:regional',
            ),
      ],
    );
  });

  test('invalid result fails explicitly before Scene progression', () async {
    var calls = 0;
    final executor = SceneInteractiveCommandRuntimeExecutor(
      warp: (_) async {
        calls += 1;
        return 'victory';
      },
      openShop: (_) async => 'cancelled',
      openPc: (_) async => 'cancelled',
    );

    await expectLater(
      executor.execute(
        SceneRuntimePlanIntent.executeInteractiveCommand(
          command: SceneInteractiveCommand.warp(
            destinationMapId: 'map.port',
            warpId: 'warp.arrival',
          ),
        ),
      ),
      throwsStateError,
    );
    expect(calls, 1);
  });

  test('Scene executor awaits command and resumes on explicit port', () async {
    final commandExecutor = SceneInteractiveCommandRuntimeExecutor(
      warp: (_) async => 'completed',
      openShop: (_) async => 'cancelled',
      openPc: (_) async => 'cancelled',
    );
    final scene = _scene();
    final result = await SceneRuntimeExecutor(
      callbacks: SceneRuntimeExecutionCallbacks(
        evaluateCondition: (_) => 'false',
        showDialogue: (_) => 'completed',
        startBattle: (_) => 'victory',
        playCinematic: (_) => 'completed',
        applyConsequence: (_) => 'completed',
        executeInteractiveCommand: commandExecutor.execute,
      ),
    ).execute(buildSceneRuntimePlan(scene).plan!);

    expect(result.status, SceneRuntimeExecutionStatus.completed);
    expect(
      result.trace.map((entry) => entry.intentKind),
      [
        SceneRuntimePlanIntentKind.start,
        SceneRuntimePlanIntentKind.executeInteractiveCommand,
        SceneRuntimePlanIntentKind.end,
      ],
    );
  });
}

SceneAsset _scene({SceneInteractiveCommand? beforeWarp}) => SceneAsset(
      id: 'scene.warp',
      name: 'Warp',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          if (beforeWarp != null)
            SceneNode(
              id: 'wait',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.interactive(beforeWarp),
            ),
          SceneNode(
            id: 'warp',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
              SceneInteractiveCommand.warp(
                destinationMapId: 'map.port',
                warpId: 'arrival',
              ),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start-warp',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: beforeWarp == null ? 'warp' : 'wait',
            kind: SceneEdgeKind.defaultFlow,
          ),
          if (beforeWarp != null)
            SceneEdge(
              id: 'wait-warp',
              fromNodeId: 'wait',
              fromPortId: 'completed',
              toNodeId: 'warp',
              kind: SceneEdgeKind.actionCompleted,
            ),
          SceneEdge(
            id: 'warp-end',
            fromNodeId: 'warp',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    );
