import 'scene_runtime_plan.dart';

enum SceneDryRunPreviewStatus {
  completed,
  awaitingInput,
  failed,
}

final class SceneDryRunInputState {
  const SceneDryRunInputState({
    this.outputPortByNodeId = const <String, String>{},
  });

  final Map<String, String> outputPortByNodeId;
}

final class SceneDryRunTraceEntry {
  const SceneDryRunTraceEntry({
    required this.nodeId,
    required this.intentKind,
    this.outputPortId,
  });

  final String nodeId;
  final SceneRuntimePlanIntentKind intentKind;
  final String? outputPortId;
}

final class SceneDryRunPreviewResult {
  SceneDryRunPreviewResult({
    required this.status,
    required List<SceneDryRunTraceEntry> trace,
    this.sceneOutcomeId,
    this.awaitingNodeId,
    List<String> acceptedOutputPortIds = const <String>[],
    this.message,
  })  : trace = List<SceneDryRunTraceEntry>.unmodifiable(trace),
        acceptedOutputPortIds =
            List<String>.unmodifiable(acceptedOutputPortIds);

  final SceneDryRunPreviewStatus status;
  final List<SceneDryRunTraceEntry> trace;
  final String? sceneOutcomeId;
  final String? awaitingNodeId;
  final List<String> acceptedOutputPortIds;
  final String? message;
}

SceneDryRunPreviewResult previewSceneRuntimePath(
  SceneRuntimePlan plan, {
  required SceneDryRunInputState input,
  int maxSteps = 100,
}) {
  if (maxSteps < 1) {
    throw ArgumentError.value(maxSteps, 'maxSteps', 'Must be positive.');
  }
  final nodesById = {for (final node in plan.nodes) node.id: node};
  var current = nodesById[plan.startNodeId];
  final trace = <SceneDryRunTraceEntry>[];
  if (current == null) {
    return _failed(trace, 'Start node "${plan.startNodeId}" is missing.');
  }

  for (var step = 0; step < maxSteps; step++) {
    if (current!.intent.kind == SceneRuntimePlanIntentKind.end) {
      trace.add(
        SceneDryRunTraceEntry(
          nodeId: current.id,
          intentKind: current.intent.kind,
        ),
      );
      return SceneDryRunPreviewResult(
        status: SceneDryRunPreviewStatus.completed,
        trace: trace,
        sceneOutcomeId: current.intent.sceneOutcomeId,
      );
    }

    final acceptedPorts = current.intent.declaredOutputPortIds;
    final requiresInput = _requiresExplicitInput(current.intent.kind);
    final explicitPort = input.outputPortByNodeId[current.id];
    if (requiresInput && explicitPort == null) {
      trace.add(
        SceneDryRunTraceEntry(
          nodeId: current.id,
          intentKind: current.intent.kind,
        ),
      );
      return SceneDryRunPreviewResult(
        status: SceneDryRunPreviewStatus.awaitingInput,
        trace: trace,
        awaitingNodeId: current.id,
        acceptedOutputPortIds: acceptedPorts,
        message: 'Choose an explicit output for node "${current.id}".',
      );
    }
    final outputPortId = explicitPort ?? acceptedPorts.single;
    if (!acceptedPorts.contains(outputPortId)) {
      trace.add(
        SceneDryRunTraceEntry(
          nodeId: current.id,
          intentKind: current.intent.kind,
          outputPortId: outputPortId,
        ),
      );
      return _failed(
        trace,
        'Output "$outputPortId" is unknown for node "${current.id}".',
      );
    }
    trace.add(
      SceneDryRunTraceEntry(
        nodeId: current.id,
        intentKind: current.intent.kind,
        outputPortId: outputPortId,
      ),
    );
    final matchingEdges = plan.edges
        .where(
          (edge) =>
              edge.fromNodeId == current!.id && edge.fromPortId == outputPortId,
        )
        .toList(growable: false);
    if (matchingEdges.length != 1) {
      return _failed(
        trace,
        matchingEdges.isEmpty
            ? 'No transition for ${current.id}:$outputPortId.'
            : 'Ambiguous transition for ${current.id}:$outputPortId.',
      );
    }
    current = nodesById[matchingEdges.single.toNodeId];
    if (current == null) {
      return _failed(trace, 'Transition target is missing.');
    }
  }
  return _failed(trace, 'Dry-run exceeded maxSteps=$maxSteps.');
}

bool _requiresExplicitInput(SceneRuntimePlanIntentKind kind) {
  return switch (kind) {
    SceneRuntimePlanIntentKind.evaluateCondition ||
    SceneRuntimePlanIntentKind.showDialogue ||
    SceneRuntimePlanIntentKind.startBattle =>
      true,
    _ => false,
  };
}

SceneDryRunPreviewResult _failed(
  List<SceneDryRunTraceEntry> trace,
  String message,
) {
  return SceneDryRunPreviewResult(
    status: SceneDryRunPreviewStatus.failed,
    trace: trace,
    message: message,
  );
}
