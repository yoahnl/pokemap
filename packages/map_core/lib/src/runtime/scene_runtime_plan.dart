import 'package:meta/meta.dart' show immutable;

import '../diagnostics/scene_diagnostics.dart';
import '../models/scene_asset.dart';

enum SceneRuntimePlanIntentKind {
  start,
  end,
  evaluateCondition,
  merge,
  showDialogue,
  startBattle,
  playCinematic,
}

enum SceneRuntimePlanDiagnosticSeverity {
  error,
  warning,
  info,
}

enum SceneRuntimePlanDiagnosticCode {
  planBuildBlockedBySceneDiagnostics,
  unsupportedAction,
  unsupportedBranchByOutcome,
  cinematicBridgeOnly,
}

@immutable
final class SceneRuntimePlan {
  SceneRuntimePlan({
    required this.sceneId,
    required this.startNodeId,
    required List<SceneRuntimePlanNode> nodes,
    required List<SceneRuntimePlanEdge> edges,
    required List<SceneOutcome> declaredOutcomes,
  })  : nodes = List<SceneRuntimePlanNode>.unmodifiable(nodes),
        edges = List<SceneRuntimePlanEdge>.unmodifiable(edges),
        declaredOutcomes = List<SceneOutcome>.unmodifiable(declaredOutcomes);

  final String sceneId;
  final String startNodeId;
  final List<SceneRuntimePlanNode> nodes;
  final List<SceneRuntimePlanEdge> edges;
  final List<SceneOutcome> declaredOutcomes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneRuntimePlan &&
          other.sceneId == sceneId &&
          other.startNodeId == startNodeId &&
          _listEquals(other.nodes, nodes) &&
          _listEquals(other.edges, edges) &&
          _listEquals(other.declaredOutcomes, declaredOutcomes);

  @override
  int get hashCode => Object.hash(
        sceneId,
        startNodeId,
        Object.hashAll(nodes),
        Object.hashAll(edges),
        Object.hashAll(declaredOutcomes),
      );
}

@immutable
final class SceneRuntimePlanNode {
  const SceneRuntimePlanNode({
    required this.id,
    required this.kind,
    required this.intent,
    this.title,
    this.description,
  });

  final String id;
  final SceneNodeKind kind;
  final SceneRuntimePlanIntent intent;
  final String? title;
  final String? description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneRuntimePlanNode &&
          other.id == id &&
          other.kind == kind &&
          other.intent == intent &&
          other.title == title &&
          other.description == description;

  @override
  int get hashCode => Object.hash(id, kind, intent, title, description);
}

@immutable
final class SceneRuntimePlanIntent {
  SceneRuntimePlanIntent._({
    required this.kind,
    this.sceneOutcomeId,
    this.conditionSource,
    this.dialogueId,
    this.yarnNodeName,
    List<String> expectedOutcomes = const <String>[],
    this.battleKind,
    this.trainerId,
    this.battleTemplateId,
    this.npcEntityId,
    List<String> battleDeclaredOutcomes = const <String>[],
    this.cinematicId,
  })  : expectedOutcomes = List<String>.unmodifiable(expectedOutcomes),
        battleDeclaredOutcomes =
            List<String>.unmodifiable(battleDeclaredOutcomes);

  factory SceneRuntimePlanIntent.start() {
    return SceneRuntimePlanIntent._(kind: SceneRuntimePlanIntentKind.start);
  }

  factory SceneRuntimePlanIntent.end({String? sceneOutcomeId}) {
    return SceneRuntimePlanIntent._(
      kind: SceneRuntimePlanIntentKind.end,
      sceneOutcomeId: sceneOutcomeId,
    );
  }

  factory SceneRuntimePlanIntent.evaluateCondition({
    required SceneConditionSource source,
  }) {
    return SceneRuntimePlanIntent._(
      kind: SceneRuntimePlanIntentKind.evaluateCondition,
      conditionSource: source,
    );
  }

  factory SceneRuntimePlanIntent.merge() {
    return SceneRuntimePlanIntent._(kind: SceneRuntimePlanIntentKind.merge);
  }

  factory SceneRuntimePlanIntent.showDialogue({
    required String dialogueId,
    String? yarnNodeName,
    List<String> expectedOutcomes = const <String>[],
  }) {
    return SceneRuntimePlanIntent._(
      kind: SceneRuntimePlanIntentKind.showDialogue,
      dialogueId: dialogueId,
      yarnNodeName: yarnNodeName,
      expectedOutcomes: expectedOutcomes,
    );
  }

  factory SceneRuntimePlanIntent.startBattle({
    required String battleKind,
    String? trainerId,
    String? battleTemplateId,
    String? npcEntityId,
    List<String> declaredOutcomes = const <String>[],
  }) {
    return SceneRuntimePlanIntent._(
      kind: SceneRuntimePlanIntentKind.startBattle,
      battleKind: battleKind,
      trainerId: trainerId,
      battleTemplateId: battleTemplateId,
      npcEntityId: npcEntityId,
      battleDeclaredOutcomes: declaredOutcomes,
    );
  }

  factory SceneRuntimePlanIntent.playCinematic({
    required String cinematicId,
  }) {
    return SceneRuntimePlanIntent._(
      kind: SceneRuntimePlanIntentKind.playCinematic,
      cinematicId: cinematicId,
    );
  }

  final SceneRuntimePlanIntentKind kind;
  final String? sceneOutcomeId;
  final SceneConditionSource? conditionSource;
  final String? dialogueId;
  final String? yarnNodeName;
  final List<String> expectedOutcomes;
  final String? battleKind;
  final String? trainerId;
  final String? battleTemplateId;
  final String? npcEntityId;
  final List<String> battleDeclaredOutcomes;
  final String? cinematicId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneRuntimePlanIntent &&
          other.kind == kind &&
          other.sceneOutcomeId == sceneOutcomeId &&
          other.conditionSource == conditionSource &&
          other.dialogueId == dialogueId &&
          other.yarnNodeName == yarnNodeName &&
          _listEquals(other.expectedOutcomes, expectedOutcomes) &&
          other.battleKind == battleKind &&
          other.trainerId == trainerId &&
          other.battleTemplateId == battleTemplateId &&
          other.npcEntityId == npcEntityId &&
          _listEquals(
            other.battleDeclaredOutcomes,
            battleDeclaredOutcomes,
          ) &&
          other.cinematicId == cinematicId;

  @override
  int get hashCode => Object.hash(
        kind,
        sceneOutcomeId,
        conditionSource,
        dialogueId,
        yarnNodeName,
        Object.hashAll(expectedOutcomes),
        battleKind,
        trainerId,
        battleTemplateId,
        npcEntityId,
        Object.hashAll(battleDeclaredOutcomes),
        cinematicId,
      );
}

@immutable
final class SceneRuntimePlanEdge {
  const SceneRuntimePlanEdge({
    required this.id,
    required this.fromNodeId,
    required this.fromPortId,
    required this.toNodeId,
    required this.kind,
    this.label,
  });

  final String id;
  final String fromNodeId;
  final String fromPortId;
  final String toNodeId;
  final SceneEdgeKind kind;
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneRuntimePlanEdge &&
          other.id == id &&
          other.fromNodeId == fromNodeId &&
          other.fromPortId == fromPortId &&
          other.toNodeId == toNodeId &&
          other.kind == kind &&
          other.label == label;

  @override
  int get hashCode =>
      Object.hash(id, fromNodeId, fromPortId, toNodeId, kind, label);
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
  });

  final SceneRuntimePlanDiagnosticCode code;
  final SceneRuntimePlanDiagnosticSeverity severity;
  final String message;
  final String sceneId;
  final String? nodeId;
  final String? edgeId;
  final SceneDiagnosticCode? sourceSceneDiagnosticCode;

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
          other.sourceSceneDiagnosticCode == sourceSceneDiagnosticCode;

  @override
  int get hashCode => Object.hash(
        code,
        severity,
        message,
        sceneId,
        nodeId,
        edgeId,
        sourceSceneDiagnosticCode,
      );
}

@immutable
final class SceneRuntimePlanBuildResult {
  SceneRuntimePlanBuildResult({
    required this.plan,
    required List<SceneRuntimePlanDiagnostic> diagnostics,
  }) : diagnostics = List<SceneRuntimePlanDiagnostic>.unmodifiable(
          diagnostics,
        );

  final SceneRuntimePlan? plan;
  final List<SceneRuntimePlanDiagnostic> diagnostics;

  bool get canBuild =>
      plan != null &&
      !diagnostics.any(
        (diagnostic) =>
            diagnostic.severity == SceneRuntimePlanDiagnosticSeverity.error,
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
