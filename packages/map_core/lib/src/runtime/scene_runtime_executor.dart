import 'dart:async';

import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import 'scene_execution_context.dart';
import 'scene_runtime_plan.dart';

typedef SceneRuntimeIntentCallback = FutureOr<String> Function(
  SceneRuntimePlanIntent intent,
);

typedef SceneRuntimeConsequenceCallback = FutureOr<String> Function(
  SceneConsequence consequence,
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
  missingBranchSourceOutcome,
  unroutedOutcome,
  callbackFailed,
  stepLimitExceeded,
}

final class SceneRuntimeExecutionCallbacks {
  const SceneRuntimeExecutionCallbacks({
    required this.evaluateCondition,
    required this.showDialogue,
    required this.startBattle,
    required this.playCinematic,
    required this.applyConsequence,
  });

  final SceneRuntimeIntentCallback evaluateCondition;
  final SceneRuntimeIntentCallback showDialogue;
  final SceneRuntimeIntentCallback startBattle;
  final SceneRuntimeIntentCallback playCinematic;
  final SceneRuntimeConsequenceCallback applyConsequence;
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
    SceneExecutionContext? context,
  })  : trace = List<SceneRuntimeExecutionTraceEntry>.unmodifiable(trace),
        context = context ?? SceneExecutionContext.empty;

  final SceneRuntimeExecutionStatus status;
  final String sceneId;
  final String? finalNodeId;
  final String? sceneOutcomeId;
  final SceneRuntimeExecutionErrorCode? errorCode;
  final String? message;
  final List<SceneRuntimeExecutionTraceEntry> trace;
  final SceneExecutionContext context;
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

  Future<SceneRuntimeExecutionResult> execute(
    SceneRuntimePlan plan, {
    SceneExecutionContext? context,
  }) async {
    final nodesById = {
      for (final node in plan.nodes) node.id: node,
    };
    final startNode = nodesById[plan.startNodeId];
    final trace = <SceneRuntimeExecutionTraceEntry>[];
    var executionContext = context ?? SceneExecutionContext.empty;

    if (startNode == null) {
      return _failed(
        plan,
        SceneRuntimeExecutionErrorCode.missingStartNode,
        'Scene runtime start node "${plan.startNodeId}" is missing.',
        trace,
        context: executionContext,
      );
    }

    var currentNode = startNode;
    for (var step = 0; step < maxSteps; step++) {
      final outputPortResult = await _resolveOutputPort(
        plan,
        currentNode,
        executionContext,
      );
      executionContext = outputPortResult.context ?? executionContext;
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
          context: executionContext,
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
          context: executionContext,
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
          context: executionContext,
        );
      }

      final nextNode = nodesById[transition.edge!.toNodeId];
      if (nextNode == null) {
        return _failed(
          plan,
          SceneRuntimeExecutionErrorCode.targetNodeMissing,
          'Scene runtime target node "${transition.edge!.toNodeId}" is missing.',
          trace,
          context: executionContext,
        );
      }
      currentNode = nextNode;
    }

    return _failed(
      plan,
      SceneRuntimeExecutionErrorCode.stepLimitExceeded,
      'Scene runtime exceeded maxSteps=$maxSteps.',
      trace,
      context: executionContext,
    );
  }

  Future<_OutputPortResult> _resolveOutputPort(
    SceneRuntimePlan plan,
    SceneRuntimePlanNode node,
    SceneExecutionContext context,
  ) async {
    final intent = node.intent;
    switch (intent.kind) {
      case SceneRuntimePlanIntentKind.start:
      case SceneRuntimePlanIntentKind.merge:
        return const _OutputPortResult(outputPortId: 'completed');
      case SceneRuntimePlanIntentKind.end:
        return const _OutputPortResult();
      case SceneRuntimePlanIntentKind.evaluateCondition:
        return _recordCallbackOutcome(
          node.id,
          context,
          await _callbackOutput(
            intent,
            callbacks.evaluateCondition,
            const {'true', 'false'},
          ),
        );
      case SceneRuntimePlanIntentKind.branchByOutcome:
        return _branchOutput(plan, node, context);
      case SceneRuntimePlanIntentKind.showDialogue:
        return _recordCallbackOutcome(
          node.id,
          context,
          await _callbackOutput(
            intent,
            callbacks.showDialogue,
            {'completed', ...intent.expectedOutcomes},
          ),
        );
      case SceneRuntimePlanIntentKind.startBattle:
        return _recordCallbackOutcome(
          node.id,
          context,
          await _callbackOutput(
            intent,
            callbacks.startBattle,
            intent.declaredOutputPortIds.toSet(),
          ),
        );
      case SceneRuntimePlanIntentKind.playCinematic:
        return _recordCallbackOutcome(
          node.id,
          context,
          await _callbackOutput(
            intent,
            callbacks.playCinematic,
            const {'completed'},
          ),
        );
      case SceneRuntimePlanIntentKind.applyConsequence:
        return _consequenceCallbackOutput(node.id, intent, context);
    }
  }

  _OutputPortResult _recordCallbackOutcome(
    String nodeId,
    SceneExecutionContext context,
    _OutputPortResult result,
  ) {
    final outputPortId = result.outputPortId;
    if (result.errorCode != null || outputPortId == null) return result;
    return _OutputPortResult(
      outputPortId: outputPortId,
      context: context.recordOutcome(nodeId: nodeId, outcome: outputPortId),
    );
  }

  _OutputPortResult _branchOutput(
    SceneRuntimePlan plan,
    SceneRuntimePlanNode node,
    SceneExecutionContext context,
  ) {
    final intent = node.intent;
    final sourceNodeId = intent.branchSourceNodeId;
    if (sourceNodeId == null) {
      return const _OutputPortResult(
        errorCode: SceneRuntimeExecutionErrorCode.unsupportedIntent,
        message: 'Scene branch intent is missing sourceNodeId.',
      );
    }
    final sourceOutcome = context.lastOutcomeByNodeId[sourceNodeId];
    if (sourceOutcome == null) {
      return _OutputPortResult(
        errorCode: SceneRuntimeExecutionErrorCode.missingBranchSourceOutcome,
        message: 'Scene branch "${node.id}" has no recorded outcome for '
            'source "$sourceNodeId".',
      );
    }
    final hasExactRoute = plan.edges.any(
      (edge) => edge.fromNodeId == node.id && edge.fromPortId == sourceOutcome,
    );
    var routedPortId = sourceOutcome;
    var usedFallback = false;
    if (!hasExactRoute) {
      usedFallback = true;
      routedPortId = switch (intent.branchFallbackPolicy) {
        SceneBranchOutcomeFallbackPolicy.defaultRoute => 'default',
        SceneBranchOutcomeFallbackPolicy.errorRoute => 'error',
        SceneBranchOutcomeFallbackPolicy.exact || null => '',
      };
      if (routedPortId.isEmpty) {
        return _OutputPortResult(
          outputPortId: sourceOutcome,
          errorCode: SceneRuntimeExecutionErrorCode.unroutedOutcome,
          message: 'Scene branch "${node.id}" has no exact route for '
              'outcome "$sourceOutcome".',
        );
      }
    }
    return _OutputPortResult(
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

  Future<_OutputPortResult> _consequenceCallbackOutput(
    String nodeId,
    SceneRuntimePlanIntent intent,
    SceneExecutionContext context,
  ) async {
    if (context.appliedPersistentNodeIds.contains(nodeId)) {
      return _OutputPortResult(
        outputPortId: 'completed',
        context: context,
      );
    }
    final consequence = intent.consequence;
    if (consequence == null) {
      return _OutputPortResult(
        errorCode: SceneRuntimeExecutionErrorCode.unsupportedIntent,
        message: 'Scene runtime consequence intent is missing consequence.',
      );
    }
    String outputPortId;
    try {
      outputPortId = await callbacks.applyConsequence(consequence);
    } catch (error) {
      return _OutputPortResult(
        errorCode: SceneRuntimeExecutionErrorCode.callbackFailed,
        message:
            'Scene runtime callback failed for ${intent.kind.name}: $error',
      );
    }
    if (outputPortId != 'completed') {
      return _OutputPortResult(
        outputPortId: outputPortId,
        errorCode: SceneRuntimeExecutionErrorCode.unsupportedPortResult,
        message:
            'Scene runtime callback returned unsupported port "$outputPortId" '
            'for ${intent.kind.name}.',
      );
    }
    return _OutputPortResult(
      outputPortId: outputPortId,
      context: context.markPersistentNodeApplied(nodeId),
    );
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
  List<SceneRuntimeExecutionTraceEntry> trace, {
  required SceneExecutionContext context,
}) {
  return SceneRuntimeExecutionResult(
    status: SceneRuntimeExecutionStatus.failed,
    sceneId: plan.sceneId,
    finalNodeId: null,
    sceneOutcomeId: null,
    errorCode: errorCode,
    message: message,
    trace: trace,
    context: context,
  );
}

final class _OutputPortResult {
  const _OutputPortResult({
    this.outputPortId,
    this.errorCode,
    this.message,
    this.context,
  });

  final String? outputPortId;
  final SceneRuntimeExecutionErrorCode? errorCode;
  final String? message;
  final SceneExecutionContext? context;
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
