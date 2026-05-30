import 'dart:async';

import 'scene_runtime_plan.dart';

typedef SceneRuntimeIntentCallback = FutureOr<String> Function(
  SceneRuntimePlanIntent intent,
);

enum SceneRuntimeExecutionStatus {
  completed,
  failed,
}

enum SceneRuntimeExecutionErrorCode {
  missingStartNode,
  missingTransition,
  ambiguousTransition,
  targetNodeMissing,
  unsupportedIntent,
  unsupportedPortResult,
  callbackFailed,
  stepLimitExceeded,
}

final class SceneRuntimeExecutionCallbacks {
  const SceneRuntimeExecutionCallbacks({
    required this.evaluateCondition,
    required this.showDialogue,
    required this.startBattle,
    required this.playCinematic,
  });

  final SceneRuntimeIntentCallback evaluateCondition;
  final SceneRuntimeIntentCallback showDialogue;
  final SceneRuntimeIntentCallback startBattle;
  final SceneRuntimeIntentCallback playCinematic;
}

final class SceneRuntimeExecutionTraceEntry {
  const SceneRuntimeExecutionTraceEntry({
    required this.nodeId,
    required this.intentKind,
    this.outputPortId,
  });

  final String nodeId;
  final SceneRuntimePlanIntentKind intentKind;
  final String? outputPortId;
}

final class SceneRuntimeExecutionResult {
  SceneRuntimeExecutionResult({
    required this.status,
    required this.sceneId,
    required this.finalNodeId,
    required this.sceneOutcomeId,
    required this.errorCode,
    required this.message,
    required List<SceneRuntimeExecutionTraceEntry> trace,
  }) : trace = List<SceneRuntimeExecutionTraceEntry>.unmodifiable(trace);

  final SceneRuntimeExecutionStatus status;
  final String sceneId;
  final String? finalNodeId;
  final String? sceneOutcomeId;
  final SceneRuntimeExecutionErrorCode? errorCode;
  final String? message;
  final List<SceneRuntimeExecutionTraceEntry> trace;
}

final class SceneRuntimeExecutor {
  SceneRuntimeExecutor({
    required this.callbacks,
    this.maxSteps = 100,
  }) {
    if (maxSteps < 1) {
      throw ArgumentError.value(
        maxSteps,
        'maxSteps',
        'SceneRuntimeExecutor requires maxSteps >= 1.',
      );
    }
  }

  final SceneRuntimeExecutionCallbacks callbacks;
  final int maxSteps;

  Future<SceneRuntimeExecutionResult> execute(SceneRuntimePlan plan) async {
    final nodesById = {
      for (final node in plan.nodes) node.id: node,
    };
    final startNode = nodesById[plan.startNodeId];
    final trace = <SceneRuntimeExecutionTraceEntry>[];

    if (startNode == null) {
      return _failed(
        plan,
        SceneRuntimeExecutionErrorCode.missingStartNode,
        'Scene runtime start node "${plan.startNodeId}" is missing.',
        trace,
      );
    }

    var currentNode = startNode;
    for (var step = 0; step < maxSteps; step++) {
      final outputPortResult = await _resolveOutputPort(currentNode.intent);
      if (outputPortResult.errorCode != null) {
        trace.add(
          SceneRuntimeExecutionTraceEntry(
            nodeId: currentNode.id,
            intentKind: currentNode.intent.kind,
            outputPortId: outputPortResult.outputPortId,
          ),
        );
        return _failed(
          plan,
          outputPortResult.errorCode!,
          outputPortResult.message!,
          trace,
        );
      }

      final outputPortId = outputPortResult.outputPortId;
      trace.add(
        SceneRuntimeExecutionTraceEntry(
          nodeId: currentNode.id,
          intentKind: currentNode.intent.kind,
          outputPortId: outputPortId,
        ),
      );

      if (currentNode.intent.kind == SceneRuntimePlanIntentKind.end) {
        return SceneRuntimeExecutionResult(
          status: SceneRuntimeExecutionStatus.completed,
          sceneId: plan.sceneId,
          finalNodeId: currentNode.id,
          sceneOutcomeId: currentNode.intent.sceneOutcomeId,
          errorCode: null,
          message: null,
          trace: trace,
        );
      }

      final transition = _findTransition(
        plan,
        currentNodeId: currentNode.id,
        outputPortId: outputPortId!,
      );
      if (transition.errorCode != null) {
        return _failed(
          plan,
          transition.errorCode!,
          transition.message!,
          trace,
        );
      }

      final nextNode = nodesById[transition.edge!.toNodeId];
      if (nextNode == null) {
        return _failed(
          plan,
          SceneRuntimeExecutionErrorCode.targetNodeMissing,
          'Scene runtime target node "${transition.edge!.toNodeId}" is missing.',
          trace,
        );
      }
      currentNode = nextNode;
    }

    return _failed(
      plan,
      SceneRuntimeExecutionErrorCode.stepLimitExceeded,
      'Scene runtime exceeded maxSteps=$maxSteps.',
      trace,
    );
  }

  Future<_OutputPortResult> _resolveOutputPort(
    SceneRuntimePlanIntent intent,
  ) async {
    switch (intent.kind) {
      case SceneRuntimePlanIntentKind.start:
      case SceneRuntimePlanIntentKind.merge:
        return const _OutputPortResult(outputPortId: 'completed');
      case SceneRuntimePlanIntentKind.end:
        return const _OutputPortResult();
      case SceneRuntimePlanIntentKind.evaluateCondition:
        return _callbackOutput(
          intent,
          callbacks.evaluateCondition,
          const {'true', 'false'},
        );
      case SceneRuntimePlanIntentKind.showDialogue:
        return _callbackOutput(
          intent,
          callbacks.showDialogue,
          const {'completed'},
        );
      case SceneRuntimePlanIntentKind.startBattle:
        return _callbackOutput(
          intent,
          callbacks.startBattle,
          const {'victory', 'defeat'},
        );
      case SceneRuntimePlanIntentKind.playCinematic:
        return _callbackOutput(
          intent,
          callbacks.playCinematic,
          const {'completed'},
        );
    }
  }

  Future<_OutputPortResult> _callbackOutput(
    SceneRuntimePlanIntent intent,
    SceneRuntimeIntentCallback callback,
    Set<String> supportedOutputPorts,
  ) async {
    String outputPortId;
    try {
      outputPortId = await callback(intent);
    } catch (error) {
      return _OutputPortResult(
        errorCode: SceneRuntimeExecutionErrorCode.callbackFailed,
        message:
            'Scene runtime callback failed for ${intent.kind.name}: $error',
      );
    }

    if (!supportedOutputPorts.contains(outputPortId)) {
      return _OutputPortResult(
        outputPortId: outputPortId,
        errorCode: SceneRuntimeExecutionErrorCode.unsupportedPortResult,
        message:
            'Scene runtime callback returned unsupported port "$outputPortId" '
            'for ${intent.kind.name}.',
      );
    }

    return _OutputPortResult(outputPortId: outputPortId);
  }
}

_TransitionResult _findTransition(
  SceneRuntimePlan plan, {
  required String currentNodeId,
  required String outputPortId,
}) {
  final matches = plan.edges
      .where(
        (edge) =>
            edge.fromNodeId == currentNodeId && edge.fromPortId == outputPortId,
      )
      .toList(growable: false);

  if (matches.isEmpty) {
    return _TransitionResult(
      errorCode: SceneRuntimeExecutionErrorCode.missingTransition,
      message: 'Scene runtime has no transition from "$currentNodeId" '
          'through port "$outputPortId".',
    );
  }

  if (matches.length > 1) {
    return _TransitionResult(
      errorCode: SceneRuntimeExecutionErrorCode.ambiguousTransition,
      message: 'Scene runtime has multiple transitions from "$currentNodeId" '
          'through port "$outputPortId".',
    );
  }

  return _TransitionResult(edge: matches.single);
}

SceneRuntimeExecutionResult _failed(
  SceneRuntimePlan plan,
  SceneRuntimeExecutionErrorCode errorCode,
  String message,
  List<SceneRuntimeExecutionTraceEntry> trace,
) {
  return SceneRuntimeExecutionResult(
    status: SceneRuntimeExecutionStatus.failed,
    sceneId: plan.sceneId,
    finalNodeId: null,
    sceneOutcomeId: null,
    errorCode: errorCode,
    message: message,
    trace: trace,
  );
}

final class _OutputPortResult {
  const _OutputPortResult({
    this.outputPortId,
    this.errorCode,
    this.message,
  });

  final String? outputPortId;
  final SceneRuntimeExecutionErrorCode? errorCode;
  final String? message;
}

final class _TransitionResult {
  const _TransitionResult({
    this.edge,
    this.errorCode,
    this.message,
  });

  final SceneRuntimePlanEdge? edge;
  final SceneRuntimeExecutionErrorCode? errorCode;
  final String? message;
}
