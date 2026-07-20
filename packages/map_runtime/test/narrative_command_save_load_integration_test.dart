import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('awaitable Scene command survives save/load and resumes once', () async {
    final source = _scene();
    final encoded = jsonEncode(source.toJson());
    final loaded = SceneAsset.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
    var executions = 0;
    final interactive = SceneInteractiveCommandRuntimeExecutor(
      warp: (_) async {
        executions += 1;
        return 'completed';
      },
      openShop: (_) async => 'cancelled',
      openPc: (_) async => 'cancelled',
    );
    final plan = buildSceneRuntimePlan(loaded).plan!;

    final result = await SceneRuntimeExecutor(
      callbacks: SceneRuntimeExecutionCallbacks(
        evaluateCondition: (_) => 'false',
        showDialogue: (_) => 'completed',
        startBattle: (_) => 'victory',
        playCinematic: (_) => 'completed',
        applyConsequence: (_) => 'completed',
        executeInteractiveCommand: interactive.execute,
      ),
    ).execute(plan);

    expect(result.status, SceneRuntimeExecutionStatus.completed);
    expect(executions, 1);
    final resumed = await SceneRuntimeExecutor(
      callbacks: SceneRuntimeExecutionCallbacks(
        evaluateCondition: (_) => 'false',
        showDialogue: (_) => 'completed',
        startBattle: (_) => 'victory',
        playCinematic: (_) => 'completed',
        applyConsequence: (_) => 'completed',
        executeInteractiveCommand: interactive.execute,
      ),
    ).execute(plan, context: result.context);
    expect(resumed.status, SceneRuntimeExecutionStatus.completed);
    expect(executions, 1,
        reason: 'The durable command receipt prevents replay.');
    final command = (loaded.graph.nodes[1].payload as SceneActionPayload)
        .interactiveCommand as SceneWarpInteractiveCommand;
    expect(command.destinationMapId, 'map.lighthouse');
    expect(command.warpId, 'warp.door');
  });
}

SceneAsset _scene() => SceneAsset(
      id: 'scene.lighthouse',
      name: 'Entrée du phare',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'warp',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
              SceneInteractiveCommand.warp(
                destinationMapId: 'map.lighthouse',
                warpId: 'warp.door',
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
