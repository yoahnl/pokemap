import 'package:meta/meta.dart' show immutable;

import '../diagnostics/scene_diagnostics.dart';
import '../models/scene_asset.dart';
import '../models/scene_execution_capabilities.dart';

enum SceneRuntimePlanDiagnosticSeverity { error, warning, info }

enum SceneRuntimePlanDiagnosticCode {
  planBuildBlockedBySceneDiagnostics,
  unsupportedAction,
  unsupportedBranchByOutcome,
  branchSourceMissing,
  branchSourceUnknown,
  branchSourceHasNoOutcomes,
  cinematicBridgeOnly,
}

@immutable
final class SceneRuntimePlanDiagnostic {
  const SceneRuntimePlanDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.sceneId,
    this.nodeId,
    this.edgeId,
    this.sourceSceneDiagnosticCode,
    this.capabilityIssueCode,
  });

  final SceneRuntimePlanDiagnosticCode code;
  final SceneRuntimePlanDiagnosticSeverity severity;
  final String message;
  final String sceneId;
  final String? nodeId;
  final String? edgeId;
  final SceneDiagnosticCode? sourceSceneDiagnosticCode;
  final SceneExecutionCapabilityIssueCode? capabilityIssueCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneRuntimePlanDiagnostic &&
          other.code == code &&
          other.severity == severity &&
          other.message == message &&
          other.sceneId == sceneId &&
          other.nodeId == nodeId &&
          other.edgeId == edgeId &&
          other.sourceSceneDiagnosticCode == sourceSceneDiagnosticCode &&
          other.capabilityIssueCode == capabilityIssueCode;

  @override
  int get hashCode => Object.hash(
        code,
        severity,
        message,
        sceneId,
        nodeId,
        edgeId,
        sourceSceneDiagnosticCode,
        capabilityIssueCode,
      );
}

@immutable
final class SceneRuntimeCompilationCheck {
  SceneRuntimeCompilationCheck({
    required List<SceneRuntimePlanDiagnostic> diagnostics,
  }) : diagnostics = List<SceneRuntimePlanDiagnostic>.unmodifiable(diagnostics);

  final List<SceneRuntimePlanDiagnostic> diagnostics;

  bool get canCompile => !diagnostics.any(
        (diagnostic) =>
            diagnostic.severity == SceneRuntimePlanDiagnosticSeverity.error,
      );
}

SceneRuntimeCompilationCheck checkSceneRuntimeCompilation(SceneAsset scene) {
  final diagnostics = <SceneRuntimePlanDiagnostic>[];
  final sceneDiagnostics = diagnoseScene(scene);
  final nodeById = <String, SceneNode>{
    for (final node in scene.graph.nodes) node.id: node,
  };

  for (final diagnostic in sceneDiagnostics.diagnostics) {
    if (diagnostic.severity != SceneDiagnosticSeverity.error) {
      continue;
    }
    diagnostics.add(
      SceneRuntimePlanDiagnostic(
        code: SceneRuntimePlanDiagnosticCode.planBuildBlockedBySceneDiagnostics,
        severity: SceneRuntimePlanDiagnosticSeverity.error,
        message: 'La scène ne peut pas être compilée: ${diagnostic.message}',
        sceneId: scene.id,
        nodeId: diagnostic.nodeId,
        edgeId: diagnostic.edgeId,
        sourceSceneDiagnosticCode: diagnostic.code,
        capabilityIssueCode: diagnostic.capabilityIssueCode,
      ),
    );
  }

  for (final node in scene.graph.nodes) {
    switch (node.kind) {
      case SceneNodeKind.action:
        final payload = node.payload;
        if (payload is! SceneActionPayload ||
            (payload.consequence == null &&
                payload.interactiveCommand == null &&
                payload.preSessionInteraction == null)) {
          diagnostics.add(
            SceneRuntimePlanDiagnostic(
              code: SceneRuntimePlanDiagnosticCode.unsupportedAction,
              severity: SceneRuntimePlanDiagnosticSeverity.error,
              message:
                  'ActionNode legacy sans conséquence ou commande typée reste non exécutable.',
              sceneId: scene.id,
              nodeId: node.id,
            ),
          );
        }
      case SceneNodeKind.branchByOutcome:
        final payload = node.payload as SceneBranchByOutcomePayload;
        final sourceNodeId = payload.sourceNodeId;
        if (sourceNodeId == null) {
          diagnostics.add(
            SceneRuntimePlanDiagnostic(
              code: SceneRuntimePlanDiagnosticCode.branchSourceMissing,
              severity: SceneRuntimePlanDiagnosticSeverity.error,
              message: 'BranchByOutcome doit choisir un nœud source.',
              sceneId: scene.id,
              nodeId: node.id,
            ),
          );
          break;
        }
        final sourceNode = nodeById[sourceNodeId];
        if (sourceNode == null) {
          diagnostics.add(
            SceneRuntimePlanDiagnostic(
              code: SceneRuntimePlanDiagnosticCode.branchSourceUnknown,
              severity: SceneRuntimePlanDiagnosticSeverity.error,
              message: 'BranchByOutcome référence un nœud source introuvable.',
              sceneId: scene.id,
              nodeId: node.id,
            ),
          );
          break;
        }
        if (declaredSceneNodeOutcomePorts(sourceNode).isEmpty) {
          diagnostics.add(
            SceneRuntimePlanDiagnostic(
              code: SceneRuntimePlanDiagnosticCode.branchSourceHasNoOutcomes,
              severity: SceneRuntimePlanDiagnosticSeverity.error,
              message:
                  'Le nœud source de BranchByOutcome ne produit aucun outcome.',
              sceneId: scene.id,
              nodeId: node.id,
            ),
          );
        }
      case SceneNodeKind.cinematic:
        diagnostics.add(
          SceneRuntimePlanDiagnostic(
            code: SceneRuntimePlanDiagnosticCode.cinematicBridgeOnly,
            severity: SceneRuntimePlanDiagnosticSeverity.warning,
            message:
                'CinematicNode est compilé comme intent déclaratif bridgeOnly.',
            sceneId: scene.id,
            nodeId: node.id,
          ),
        );
      case SceneNodeKind.presentationCinematic:
        break;
      case SceneNodeKind.start:
      case SceneNodeKind.end:
      case SceneNodeKind.yarnDialogue:
      case SceneNodeKind.condition:
      case SceneNodeKind.battle:
      case SceneNodeKind.merge:
        break;
    }
  }

  return SceneRuntimeCompilationCheck(diagnostics: diagnostics);
}

List<String> declaredSceneNodeOutcomePorts(SceneNode node) {
  return switch (node.payload) {
    SceneYarnDialoguePayload(:final expectedOutcomes) => <String>[
      'completed',
      for (final outcome in expectedOutcomes)
        if (outcome != 'completed') outcome,
    ],
    SceneBattlePayload(:final declaredOutcomes) =>
      declaredOutcomes.isEmpty
          ? const <String>['victory', 'defeat']
          : declaredOutcomes,
    SceneConditionPayload() => const <String>['true', 'false'],
    SceneActionPayload(:final interactiveCommand?) =>
      interactiveCommand.outputPortIds,
    SceneActionPayload(:final preSessionInteraction?) =>
      preSessionInteraction.outputPortIds,
    SceneStartPayload() ||
    SceneActionPayload() ||
    SceneCinematicPayload() ||
    ScenePresentationCinematicPayload() ||
    SceneMergePayload() ||
    SceneEndPayload() ||
    SceneBranchByOutcomePayload() => const <String>[],
    _ => const <String>[],
  };
}
