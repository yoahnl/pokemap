import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/enums.dart';
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
    this.consequenceState,
  });

  final Map<String, String> outputPortByNodeId;
  final SceneExecutionContext? executionContext;
  final SceneDryRunConsequenceState? consequenceState;
}

final class SceneDryRunConsequenceState {
  SceneDryRunConsequenceState({
    Map<String, bool> factValueById = const <String, bool>{},
    Set<String> consumedEventKeys = const <String>{},
    Set<String> completedStoryStepIds = const <String>{},
    Map<String, int> itemQuantityById = const <String, int>{},
    Set<String> badgeIds = const <String>{},
    Set<FieldAbility> unlockedFieldAbilities = const <FieldAbility>{},
    this.money = 0,
    this.partyMemberCount = 0,
    this.partyHealed = false,
  })  : factValueById = Map<String, bool>.unmodifiable(factValueById),
        consumedEventKeys = Set<String>.unmodifiable(consumedEventKeys),
        completedStoryStepIds = Set<String>.unmodifiable(completedStoryStepIds),
        itemQuantityById = Map<String, int>.unmodifiable(itemQuantityById),
        badgeIds = Set<String>.unmodifiable(badgeIds),
        unlockedFieldAbilities =
            Set<FieldAbility>.unmodifiable(unlockedFieldAbilities);

  static final SceneDryRunConsequenceState empty =
      SceneDryRunConsequenceState();

  final Map<String, bool> factValueById;
  final Set<String> consumedEventKeys;
  final Set<String> completedStoryStepIds;
  final Map<String, int> itemQuantityById;
  final Set<String> badgeIds;
  final Set<FieldAbility> unlockedFieldAbilities;
  final int money;
  final int partyMemberCount;
  final bool partyHealed;
}

final class SceneDryRunConsequenceChange {
  const SceneDryRunConsequenceChange({
    required this.nodeId,
    required this.consequence,
    required this.beforeSummary,
    required this.afterSummary,
  });

  final String nodeId;
  final SceneConsequence consequence;
  final String beforeSummary;
  final String afterSummary;
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
    SceneDryRunConsequenceState? consequenceState,
    List<SceneDryRunConsequenceChange> consequenceChanges =
        const <SceneDryRunConsequenceChange>[],
  })  : trace = List<SceneDryRunTraceEntry>.unmodifiable(trace),
        acceptedOutputPortIds =
            List<String>.unmodifiable(acceptedOutputPortIds),
        context = context ?? SceneExecutionContext.empty,
        consequenceState =
            consequenceState ?? SceneDryRunConsequenceState.empty,
        consequenceChanges = List<SceneDryRunConsequenceChange>.unmodifiable(
          consequenceChanges,
        );

  final SceneDryRunPreviewStatus status;
  final List<SceneDryRunTraceEntry> trace;
  final String? sceneOutcomeId;
  final String? awaitingNodeId;
  final List<String> acceptedOutputPortIds;
  final String? message;
  final SceneExecutionContext context;
  final SceneDryRunConsequenceState consequenceState;
  final List<SceneDryRunConsequenceChange> consequenceChanges;
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
  var consequenceState =
      input.consequenceState ?? SceneDryRunConsequenceState.empty;
  final consequenceChanges = <SceneDryRunConsequenceChange>[];
  if (current == null) {
    return _failed(
      trace,
      'Start node "${plan.startNodeId}" is missing.',
      consequenceState: consequenceState,
      consequenceChanges: consequenceChanges,
    );
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
        consequenceState: consequenceState,
        consequenceChanges: consequenceChanges,
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
        return _failed(
          trace,
          branch.message!,
          context: context,
          consequenceState: consequenceState,
          consequenceChanges: consequenceChanges,
        );
      }
      context = branch.context!;
      final next = _nextNode(
        plan,
        nodesById,
        current,
        branch.outputPortId!,
      );
      if (next.message != null) {
        return _failed(
          trace,
          next.message!,
          context: context,
          consequenceState: consequenceState,
          consequenceChanges: consequenceChanges,
        );
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
        consequenceState: consequenceState,
        consequenceChanges: consequenceChanges,
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
        consequenceState: consequenceState,
        consequenceChanges: consequenceChanges,
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
      final consequence = current.intent.consequence;
      if (consequence == null) {
        return _failed(
          trace,
          'Action node "${current.id}" has no typed consequence.',
          context: context,
          consequenceState: consequenceState,
          consequenceChanges: consequenceChanges,
        );
      }
      if (!context.appliedPersistentNodeIds.contains(current.id)) {
        final change = _previewConsequence(
          nodeId: current.id,
          consequence: consequence,
          state: consequenceState,
        );
        if (change.message != null) {
          return _failed(
            trace,
            change.message!,
            context: context,
            consequenceState: consequenceState,
            consequenceChanges: consequenceChanges,
          );
        }
        consequenceState = change.state!;
        consequenceChanges.add(change.change!);
      }
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
        consequenceState: consequenceState,
        consequenceChanges: consequenceChanges,
      );
    }
    current = nodesById[matchingEdges.single.toNodeId];
    if (current == null) {
      return _failed(
        trace,
        'Transition target is missing.',
        context: context,
        consequenceState: consequenceState,
        consequenceChanges: consequenceChanges,
      );
    }
  }
  return _failed(
    trace,
    'Dry-run exceeded maxSteps=$maxSteps.',
    context: context,
    consequenceState: consequenceState,
    consequenceChanges: consequenceChanges,
  );
}

_PreviewConsequenceResult _previewConsequence({
  required String nodeId,
  required SceneConsequence consequence,
  required SceneDryRunConsequenceState state,
}) {
  late final SceneDryRunConsequenceState next;
  late final String before;
  late final String after;
  switch (consequence) {
    case SceneSetFactConsequence():
      final previous = state.factValueById[consequence.factId];
      before = '${consequence.factId}=${previous ?? 'unset'}';
      after = '${consequence.factId}=${consequence.value}';
      next = _copyConsequenceState(
        state,
        factValueById: {
          ...state.factValueById,
          consequence.factId: consequence.value,
        },
      );
    case SceneMarkEventConsumedConsequence():
      final key = '${consequence.mapId}:${consequence.eventId}';
      before = '$key=${state.consumedEventKeys.contains(key)}';
      after = '$key=true';
      next = _copyConsequenceState(
        state,
        consumedEventKeys: {...state.consumedEventKeys, key},
      );
    case SceneCompleteStoryStepConsequence():
      before = '${consequence.stepId}='
          '${state.completedStoryStepIds.contains(consequence.stepId)}';
      after = '${consequence.stepId}=true';
      next = _copyConsequenceState(
        state,
        completedStoryStepIds: {
          ...state.completedStoryStepIds,
          consequence.stepId,
        },
      );
    case SceneGiveItemConsequence():
      final quantity = state.itemQuantityById[consequence.itemId] ?? 0;
      final updated = quantity + consequence.quantity;
      before = '${consequence.itemId}=$quantity';
      after = '${consequence.itemId}=$updated';
      next = _copyConsequenceState(
        state,
        itemQuantityById: {
          ...state.itemQuantityById,
          consequence.itemId: updated,
        },
      );
    case SceneTakeItemConsequence():
      final quantity = state.itemQuantityById[consequence.itemId] ?? 0;
      if (consequence.quantity <= 0 || quantity < consequence.quantity) {
        return _PreviewConsequenceResult(
          message: 'Cannot take ${consequence.quantity} '
              '"${consequence.itemId}" from dry-run quantity $quantity.',
        );
      }
      final updated = quantity - consequence.quantity;
      before = '${consequence.itemId}=$quantity';
      after = '${consequence.itemId}=$updated';
      next = _copyConsequenceState(
        state,
        itemQuantityById: {
          ...state.itemQuantityById,
          consequence.itemId: updated,
        },
      );
    case SceneGiveMoneyConsequence():
      before = 'money=${state.money}';
      after = 'money=${state.money + consequence.amount}';
      next = _copyConsequenceState(
        state,
        money: state.money + consequence.amount,
      );
    case SceneGivePokemonConsequence():
      before = 'party=${state.partyMemberCount}';
      after = 'party=${state.partyMemberCount + 1} '
          '(${consequence.speciesId} niv. ${consequence.level})';
      next = _copyConsequenceState(
        state,
        partyMemberCount: state.partyMemberCount + 1,
      );
    case SceneGiveConfiguredStarterConsequence():
      before = 'party=${state.partyMemberCount}';
      after = 'party=${state.partyMemberCount + 1} '
          '(${consequence.starterOptionId})';
      next = _copyConsequenceState(
        state,
        partyMemberCount: state.partyMemberCount + 1,
      );
    case SceneHealPartyConsequence():
      before = 'partyHealed=${state.partyHealed}';
      after = 'partyHealed=true';
      next = _copyConsequenceState(state, partyHealed: true);
    case SceneAwardBadgeConsequence():
      before = '${consequence.badgeId}='
          '${state.badgeIds.contains(consequence.badgeId)}';
      after = '${consequence.badgeId}=true';
      next = _copyConsequenceState(
        state,
        badgeIds: <String>{...state.badgeIds, consequence.badgeId},
      );
    case SceneUnlockFieldAbilityConsequence():
      before = '${consequence.ability.moveId}='
          '${state.unlockedFieldAbilities.contains(consequence.ability)}';
      after = '${consequence.ability.moveId}=true';
      next = _copyConsequenceState(
        state,
        unlockedFieldAbilities: <FieldAbility>{
          ...state.unlockedFieldAbilities,
          consequence.ability,
        },
      );
  }
  return _PreviewConsequenceResult(
    state: next,
    change: SceneDryRunConsequenceChange(
      nodeId: nodeId,
      consequence: consequence,
      beforeSummary: before,
      afterSummary: after,
    ),
  );
}

SceneDryRunConsequenceState _copyConsequenceState(
  SceneDryRunConsequenceState state, {
  Map<String, bool>? factValueById,
  Set<String>? consumedEventKeys,
  Set<String>? completedStoryStepIds,
  Map<String, int>? itemQuantityById,
  Set<String>? badgeIds,
  Set<FieldAbility>? unlockedFieldAbilities,
  int? money,
  int? partyMemberCount,
  bool? partyHealed,
}) {
  return SceneDryRunConsequenceState(
    factValueById: factValueById ?? state.factValueById,
    consumedEventKeys: consumedEventKeys ?? state.consumedEventKeys,
    completedStoryStepIds: completedStoryStepIds ?? state.completedStoryStepIds,
    itemQuantityById: itemQuantityById ?? state.itemQuantityById,
    badgeIds: badgeIds ?? state.badgeIds,
    unlockedFieldAbilities:
        unlockedFieldAbilities ?? state.unlockedFieldAbilities,
    money: money ?? state.money,
    partyMemberCount: partyMemberCount ?? state.partyMemberCount,
    partyHealed: partyHealed ?? state.partyHealed,
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
  SceneDryRunConsequenceState? consequenceState,
  List<SceneDryRunConsequenceChange> consequenceChanges =
      const <SceneDryRunConsequenceChange>[],
}) {
  return SceneDryRunPreviewResult(
    status: SceneDryRunPreviewStatus.failed,
    trace: trace,
    message: message,
    context: context,
    consequenceState: consequenceState,
    consequenceChanges: consequenceChanges,
  );
}

final class _PreviewConsequenceResult {
  const _PreviewConsequenceResult({this.state, this.change, this.message});

  final SceneDryRunConsequenceState? state;
  final SceneDryRunConsequenceChange? change;
  final String? message;
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
