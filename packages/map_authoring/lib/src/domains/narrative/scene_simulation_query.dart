import 'package:map_core/map_core.dart';

import '../../contracts/query_page.dart';
import '../../contracts/query_request.dart';
import '../../workspace/project_snapshot.dart';
import 'narrative_authoring_exception.dart';

Future<AuthoringQueryPage> querySceneSimulation(
  ProjectSnapshot snapshot,
  AuthoringQueryRequest request,
) async {
  Never reject(String message) =>
      throw NarrativeAuthoringException('scene.simulation_invalid', message);
  if (request.resourceKind != 'scene' ||
      request.operation != AuthoringQueryOperation.get ||
      request.ids.length != 1 ||
      request.cursor != null ||
      request.filters.isNotEmpty ||
      request.fieldMask.isNotEmpty ||
      request.sort.isNotEmpty ||
      request.searchTerm != null ||
      request.extensions.keys
          .any((key) => key != 'actionId' && key != 'parameters')) {
    reject('Scene simulation requires one unfiltered scene get query.');
  }
  final rawParameters = request.extensions['parameters'] ?? const {};
  if (rawParameters is! Map ||
      rawParameters.keys
          .any((key) => key != 'portsByNodeId' && key != 'maxSteps')) {
    reject(
        'Scene simulation parameters must contain portsByNodeId and maxSteps only.');
  }
  final maxSteps = rawParameters['maxSteps'] ?? 100;
  if (maxSteps is! int || maxSteps < 1 || maxSteps > 1000) {
    reject('Scene simulation maxSteps must be an integer from 1 to 1000.');
  }
  final rawPorts = rawParameters['portsByNodeId'] ?? const {};
  if (rawPorts is! Map ||
      rawPorts.entries
          .any((entry) => entry.key is! String || entry.value is! String)) {
    reject(
        'Scene simulation portsByNodeId must map node IDs to output port IDs.');
  }
  final ports = Map<String, String>.from(rawPorts);
  final matches = snapshot.manifest.scenes
      .where((scene) => scene.id == request.ids.single)
      .toList();
  if (matches.length != 1) {
    reject('Scene simulation requires one existing scene.');
  }
  final built = buildSceneRuntimePlan(matches.single);
  final plan = built.plan;
  if (!built.canBuild || plan == null) {
    throw NarrativeAuthoringException('scene.simulation_unbuildable',
        'The scene cannot build a runtime plan.',
        details: {
          'diagnostics': built.diagnostics
              .map((diagnostic) => {
                    'code': diagnostic.code.name,
                    'severity': diagnostic.severity.name,
                    'nodeId': diagnostic.nodeId,
                    'message': diagnostic.message
                  })
              .toList(),
        });
  }
  const inputKinds = {
    SceneRuntimePlanIntentKind.evaluateCondition,
    SceneRuntimePlanIntentKind.showDialogue,
    SceneRuntimePlanIntentKind.startBattle,
    SceneRuntimePlanIntentKind.playCinematic,
    SceneRuntimePlanIntentKind.playPresentationCinematic,
    SceneRuntimePlanIntentKind.executeInteractiveCommand,
    SceneRuntimePlanIntentKind.requestStructuredInteraction,
  };
  final nodes = {for (final node in plan.nodes) node.id: node};
  if (snapshot.manifest.settings.dimension != ProjectDimension.twoD &&
      plan.nodes.any((node) =>
          node.intent.interactiveCommand is SceneWhiteOutInteractiveCommand ||
          node.intent.interactiveCommand is SceneSetPropStateInteractiveCommand ||
          node.intent.kind == SceneRuntimePlanIntentKind.startBattle &&
              node.intent.battleDefeatRecovery == SceneBattleDefeatRecovery.returnToRecoveryPoint)) {
    throw NarrativeAuthoringException('scene.simulation_unsupported_dimension',
        'This Scene command is available only in a 2D project.');
  }
  for (final entry in ports.entries) {
    final node = nodes[entry.key];
    if (node == null ||
        !inputKinds.contains(node.intent.kind) ||
        !node.intent.declaredOutputPortIds.contains(entry.value)) {
      reject(
          'Scene simulation override ${entry.key} must select a declared external output port.');
    }
  }
  final used = <String>{};
  final consequences = <Map<String, Object?>>[];
  final defeatRecoveries = <Map<String, Object?>>[];
  final propMovements = <Map<String, Object?>>[];
  String? missingInput;
  String output(SceneRuntimePlanIntent intent) {
    final node =
        plan.nodes.singleWhere((node) => identical(node.intent, intent));
    final port = ports[node.id];
    if (port == null) {
      missingInput = node.id;
      throw StateError(
          'Scene simulation requires an explicit output for ${node.id}.');
    }
    used.add(node.id);
    if (intent.interactiveCommand case final SceneSetPropStateInteractiveCommand command) {
      propMovements.add({
        'nodeId': node.id,
        'command': command.toJson(),
        'selectedOutputPort': port,
        'collisionChecked': false,
        'motionExecuted': false,
      });
    }
    if (intent.interactiveCommand is SceneWhiteOutInteractiveCommand ||
        intent.kind == SceneRuntimePlanIntentKind.startBattle &&
            port == 'defeat' &&
            intent.battleDefeatRecovery == SceneBattleDefeatRecovery.returnToRecoveryPoint) {
      defeatRecoveries.add({
        'nodeId': node.id,
        'source': intent.interactiveCommand is SceneWhiteOutInteractiveCommand ? 'whiteOut' : 'battleDefeat',
        'activation': 'afterSuccessfulSceneCompletion',
      });
    }
    return port;
  }

  final result = await SceneRuntimeExecutor(
    maxSteps: maxSteps,
    callbacks: SceneRuntimeExecutionCallbacks(
      evaluateCondition: output,
      showDialogue: output,
      startBattle: output,
      playCinematic: output,
      playPresentationCinematic: output,
      executeInteractiveCommand: output,
      requestStructuredInteraction: output,
      applyConsequence: (_) => 'completed',
      applyConsequenceWithNodeId: (nodeId, consequence) {
        consequences
            .add({'nodeId': nodeId, 'consequence': consequence.toJson()});
        return 'completed';
      },
    ),
  ).execute(plan);
  final unused = ports.keys.where((id) => !used.contains(id)).toList()..sort();
  final completed =
      result.status == SceneRuntimeExecutionStatus.completed && unused.isEmpty;
  return AuthoringQueryPage(
      snapshotRevision: snapshot.revision,
      totalAvailable: 1,
      items: [
        {
          'id': plan.sceneId,
          'sceneId': plan.sceneId,
          'proofKind': 'simulation',
          'mountedPlayer': false,
          'effects': 'proposedOnly',
          'status': completed ? 'completed' : 'failed',
          'finalNodeId': result.finalNodeId,
          'sceneOutcomeId': result.sceneOutcomeId,
          'errorCode': missingInput != null
              ? 'missingInput'
              : result.errorCode?.name ??
                  (unused.isNotEmpty ? 'unusedInput' : null),
          'message': result.message ??
              (unused.isNotEmpty
                  ? 'Scene simulation did not consume inputs for ${unused.join(', ')}.'
                  : null),
          if (missingInput != null) 'missingInputNodeId': missingInput,
          'unusedInputNodeIds': unused,
          'maxSteps': maxSteps,
          'trace': result.trace
              .map((entry) => {
                    'nodeId': entry.nodeId,
                    'intentKind': entry.intentKind.name,
                    'outputPortId': entry.outputPortId
                  })
              .toList(),
          'proposedConsequences': consequences,
          'proposedDefeatRecoveries': completed ? defeatRecoveries : const [],
          'proposedPropMovements': completed ? propMovements : const [],
          'outcomesByNodeId': result.context.lastOutcomeByNodeId,
          'branchProvenance': result.context.branchProvenance
              .map((branch) => {
                    'branchNodeId': branch.branchNodeId,
                    'sourceNodeId': branch.sourceNodeId,
                    'sourceOutcome': branch.sourceOutcome,
                    'routedPortId': branch.routedPortId,
                    'usedFallback': branch.usedFallback
                  })
              .toList(),
        }
      ]);
}
