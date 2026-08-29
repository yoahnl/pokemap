import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('dispatches each closed command kind once and preserves order',
      () async {
    final calls = <SceneInteractiveCommandKind>[];
    Future<String> handler(SceneInteractiveCommand command) async {
      calls.add(command.kind);
      return 'completed';
    }

    final executor = SceneInteractiveCommandRuntimeExecutor(
      warp: handler,
      moveNpc: handler,
      openShop: handler,
      openHeal: handler,
      openPc: handler,
      playCharacterAnimation: handler,
      railJourney: handler,
    );
    for (final command in <SceneInteractiveCommand>[
      SceneInteractiveCommand.warp(
        destinationMapId: 'map.port',
        warpId: 'warp.arrival',
      ),
      SceneInteractiveCommand.moveNpc(
        mapId: 'map.port',
        entityId: 'npc.guard',
        warpId: 'warp.arrival',
      ),
      SceneInteractiveCommand.openShop(shopId: 'shop.port'),
      SceneInteractiveCommand.openHeal(),
      SceneInteractiveCommand.openPc(),
      SceneInteractiveCommand.playCharacterAnimation(
        runtimeCommand: CharacterCustomAnimationRuntimeCommand(
          actorId: 'npc.guard',
          definitionId: 'wave',
        ),
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
      expect(result, 'completed');
    }

    expect(calls, SceneInteractiveCommandKind.values);
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

SceneAsset _scene() => SceneAsset(
      id: 'scene.warp',
      name: 'Warp',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
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
            toNodeId: 'warp',
            kind: SceneEdgeKind.defaultFlow,
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
