import '../models/scene_asset.dart';
import 'scene_execution_context.dart';
import 'scene_runtime_plan.dart';

enum SceneDryRunPreviewStatus {
  completed,
  awaitingInput,
  failed,
}

final class SceneDryRunInputState {
  const SceneDryRunInputState({
    this.outputPortByNodeId = const <String, String>{},
    this.executionContext,
  });

  final Map<String, String> outputPortByNodeId;
  final SceneExecutionContext? executionContext;
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
    SceneExecutionContext? context,
  })  : trace = List<SceneDryRunTraceEntry>.unmodifiable(trace),
        acceptedOutputPortIds =
            List<String>.unmodifiable(acceptedOutputPortIds),
        context = context ?? SceneExecutionContext.empty;

  final SceneDryRunPreviewStatus status;
  final List<SceneDryRunTraceEntry> trace;
  final String? sceneOutcomeId;
  final String? awaitingNodeId;
  final List<String> acceptedOutputPortIds;
  final String? message;
  final SceneExecutionContext context;
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
  var context = input.executionContext ?? SceneExecutionContext.empty;
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
        context: context,
      );
    }

    if (current.intent.kind == SceneRuntimePlanIntentKind.branchByOutcome) {
      final branch = _previewBranch(plan, current, context);
      trace.add(
        SceneDryRunTraceEntry(
          nodeId: current.id,
          intentKind: current.intent.kind,
          outputPortId: branch.outputPortId,
        ),
      );
      if (branch.message != null) {
        return _failed(trace, branch.message!, context: context);
      }
      context = branch.context!;
      final next = _nextNode(
        plan,
        nodesById,
        current,
        branch.outputPortId!,
      );
      if (next.message != null) {
        return _failed(trace, next.message!, context: context);
      }
      current = next.node;
      continue;
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
        context: context,
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
        context: context,
      );
    }
    trace.add(
      SceneDryRunTraceEntry(
        nodeId: current.id,
        intentKind: current.intent.kind,
        outputPortId: outputPortId,
      ),
    );
    if (_recordsPreviewOutcome(current.intent.kind)) {
      context = context.recordOutcome(
        nodeId: current.id,
        outcome: outputPortId,
      );
    } else if (current.intent.kind ==
        SceneRuntimePlanIntentKind.applyConsequence) {
      context = context.markPersistentNodeApplied(current.id);
    }
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
        context: context,
      );
    }
    current = nodesById[matchingEdges.single.toNodeId];
    if (current == null) {
      return _failed(trace, 'Transition target is missing.', context: context);
    }
  }
  return _failed(
    trace,
    'Dry-run exceeded maxSteps=$maxSteps.',
    context: context,
  );
}

_PreviewBranchResult _previewBranch(
  SceneRuntimePlan plan,
  SceneRuntimePlanNode node,
  SceneExecutionContext context,
) {
  final sourceNodeId = node.intent.branchSourceNodeId;
  if (sourceNodeId == null) {
    return const _PreviewBranchResult(
      message: 'Branch is missing sourceNodeId.',
    );
  }
  final sourceOutcome = context.lastOutcomeByNodeId[sourceNodeId];
  if (sourceOutcome == null) {
    return _PreviewBranchResult(
      message: 'No recorded outcome for branch source "$sourceNodeId".',
    );
  }
  final hasExactRoute = plan.edges.any(
    (edge) => edge.fromNodeId == node.id && edge.fromPortId == sourceOutcome,
  );
  var routedPortId = sourceOutcome;
  var usedFallback = false;
  if (!hasExactRoute) {
    usedFallback = true;
    routedPortId = switch (node.intent.branchFallbackPolicy) {
      SceneBranchOutcomeFallbackPolicy.defaultRoute => 'default',
      SceneBranchOutcomeFallbackPolicy.errorRoute => 'error',
      SceneBranchOutcomeFallbackPolicy.exact || null => '',
    };
    if (routedPortId.isEmpty) {
      return _PreviewBranchResult(
        outputPortId: sourceOutcome,
        message: 'No exact route for outcome "$sourceOutcome".',
      );
    }
  }
  return _PreviewBranchResult(
    outputPortId: routedPortId,
    context: context.recordBranch(
      SceneBranchProvenanceEntry(
        branchNodeId: node.id,
        sourceNodeId: sourceNodeId,
        sourceOutcome: sourceOutcome,
        routedPortId: routedPortId,
        usedFallback: usedFallback,
      ),
    ),
  );
}

_PreviewNextNodeResult _nextNode(
  SceneRuntimePlan plan,
  Map<String, SceneRuntimePlanNode> nodesById,
  SceneRuntimePlanNode current,
  String outputPortId,
) {
  final matchingEdges = plan.edges
      .where(
        (edge) =>
            edge.fromNodeId == current.id && edge.fromPortId == outputPortId,
      )
      .toList(growable: false);
  if (matchingEdges.length != 1) {
    return _PreviewNextNodeResult(
      message: matchingEdges.isEmpty
          ? 'No transition for ${current.id}:$outputPortId.'
          : 'Ambiguous transition for ${current.id}:$outputPortId.',
    );
  }
  final node = nodesById[matchingEdges.single.toNodeId];
  return node == null
      ? const _PreviewNextNodeResult(message: 'Transition target is missing.')
      : _PreviewNextNodeResult(node: node);
}

bool _recordsPreviewOutcome(SceneRuntimePlanIntentKind kind) {
  return switch (kind) {
    SceneRuntimePlanIntentKind.evaluateCondition ||
    SceneRuntimePlanIntentKind.showDialogue ||
    SceneRuntimePlanIntentKind.startBattle ||
    SceneRuntimePlanIntentKind.playCinematic =>
      true,
    _ => false,
  };
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
  String message, {
  SceneExecutionContext? context,
}) {
  return SceneDryRunPreviewResult(
    status: SceneDryRunPreviewStatus.failed,
    trace: trace,
    message: message,
    context: context,
  );
}

final class _PreviewBranchResult {
  const _PreviewBranchResult({
    this.outputPortId,
    this.context,
    this.message,
  });

  final String? outputPortId;
  final SceneExecutionContext? context;
  final String? message;
}

final class _PreviewNextNodeResult {
  const _PreviewNextNodeResult({this.node, this.message});

  final SceneRuntimePlanNode? node;
  final String? message;
}
