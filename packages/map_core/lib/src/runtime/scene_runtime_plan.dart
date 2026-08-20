import 'package:meta/meta.dart' show immutable;

import '../diagnostics/scene_diagnostics.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/scene_execution_capabilities.dart';
import '../models/scene_interactive_command.dart';
import '../models/scene_pre_session_interaction.dart';
import '../models/scene_structured_interaction.dart';

enum SceneRuntimePlanIntentKind {
  start,
  end,
  evaluateCondition,
  branchByOutcome,
  merge,
  showDialogue,
  startBattle,
  playCinematic,
  playPresentationCinematic,
  applyConsequence,
  executeInteractiveCommand,
  requestStructuredInteraction,
}

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
final class SceneRuntimePlan {
  SceneRuntimePlan({
    required this.sceneId,
    this.executionProfile = SceneExecutionProfile.world,
    required this.startNodeId,
    required List<SceneRuntimePlanNode> nodes,
    required List<SceneRuntimePlanEdge> edges,
    required List<SceneOutcome> declaredOutcomes,
  })  : nodes = List<SceneRuntimePlanNode>.unmodifiable(nodes),
        edges = List<SceneRuntimePlanEdge>.unmodifiable(edges),
        declaredOutcomes = List<SceneOutcome>.unmodifiable(declaredOutcomes);

  final String sceneId;
  final SceneExecutionProfile executionProfile;
  final String startNodeId;
  final List<SceneRuntimePlanNode> nodes;
  final List<SceneRuntimePlanEdge> edges;
  final List<SceneOutcome> declaredOutcomes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneRuntimePlan &&
          other.sceneId == sceneId &&
          other.executionProfile == executionProfile &&
          other.startNodeId == startNodeId &&
          _listEquals(other.nodes, nodes) &&
          _listEquals(other.edges, edges) &&
          _listEquals(other.declaredOutcomes, declaredOutcomes);

  @override
  int get hashCode => Object.hash(
        sceneId,
        executionProfile,
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
    this.capabilityId,
    this.title,
    this.description,
  });

  final String id;
  final SceneNodeKind kind;
  final SceneRuntimePlanIntent intent;
  final String? capabilityId;
  final String? title;
  final String? description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneRuntimePlanNode &&
          other.id == id &&
          other.kind == kind &&
          other.intent == intent &&
          other.capabilityId == capabilityId &&
          other.title == title &&
          other.description == description;

  @override
  int get hashCode =>
      Object.hash(id, kind, intent, capabilityId, title, description);
}

@immutable
final class SceneRuntimePlanIntent {
  SceneRuntimePlanIntent._({
    required this.kind,
    this.sceneOutcomeId,
    this.outcomePolicy,
    this.conditionSource,
    this.branchSourceNodeId,
    this.branchFallbackPolicy,
    List<String> branchSourceOutcomes = const <String>[],
    this.dialogueId,
    this.yarnNodeName,
    List<String> expectedOutcomes = const <String>[],
    this.battleKind,
    this.trainerId,
    this.battleTemplateId,
    this.npcEntityId,
    List<String> battleDeclaredOutcomes = const <String>[],
    this.cinematicId,
    this.presentationCinematicId,
    this.sourceNodeId,
    Map<String, String> presentationAwaitableNodeIdsByMarkerId = const {},
    this.consequence,
    this.interactiveCommand,
    this.preSessionInteraction,
  })  : branchSourceOutcomes = List<String>.unmodifiable(branchSourceOutcomes),
        expectedOutcomes = List<String>.unmodifiable(expectedOutcomes),
       battleDeclaredOutcomes = List<String>.unmodifiable(
         battleDeclaredOutcomes,
       ),
       presentationAwaitableNodeIdsByMarkerId =
           Map<String, String>.unmodifiable(
             presentationAwaitableNodeIdsByMarkerId,
           );

  factory SceneRuntimePlanIntent.start() {
    return SceneRuntimePlanIntent._(kind: SceneRuntimePlanIntentKind.start);
  }

  factory SceneRuntimePlanIntent.end({
    String? sceneOutcomeId,
    SceneOutcomePolicy? outcomePolicy,
  }) {
    return SceneRuntimePlanIntent._(
      kind: SceneRuntimePlanIntentKind.end,
      sceneOutcomeId: sceneOutcomeId,
      outcomePolicy: outcomePolicy,
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

  factory SceneRuntimePlanIntent.branchByOutcome({
    required String sourceNodeId,
    required SceneBranchOutcomeFallbackPolicy fallbackPolicy,
    required List<String> sourceOutcomes,
  }) {
    return SceneRuntimePlanIntent._(
      kind: SceneRuntimePlanIntentKind.branchByOutcome,
      branchSourceNodeId: sourceNodeId,
      branchFallbackPolicy: fallbackPolicy,
      branchSourceOutcomes: sourceOutcomes,
    );
  }

  factory SceneRuntimePlanIntent.merge() {
    return SceneRuntimePlanIntent._(kind: SceneRuntimePlanIntentKind.merge);
  }

  factory SceneRuntimePlanIntent.showDialogue({
    required String dialogueId,
    String? yarnNodeName,
    String? sourceNodeId,
    List<String> expectedOutcomes = const <String>[],
  }) {
    return SceneRuntimePlanIntent._(
      kind: SceneRuntimePlanIntentKind.showDialogue,
      dialogueId: dialogueId,
      yarnNodeName: yarnNodeName,
      sourceNodeId: sourceNodeId,
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

  factory SceneRuntimePlanIntent.playCinematic({required String cinematicId}) {
    return SceneRuntimePlanIntent._(
      kind: SceneRuntimePlanIntentKind.playCinematic,
      cinematicId: cinematicId,
    );
  }

  factory SceneRuntimePlanIntent.playPresentationCinematic({
    required String presentationCinematicId,
    String? sourceNodeId,
    Map<String, String> awaitableNodeIdsByMarkerId = const {},
  }) {
    return SceneRuntimePlanIntent._(
      kind: SceneRuntimePlanIntentKind.playPresentationCinematic,
      presentationCinematicId: presentationCinematicId,
      sourceNodeId: sourceNodeId,
      presentationAwaitableNodeIdsByMarkerId: awaitableNodeIdsByMarkerId,
    );
  }

  factory SceneRuntimePlanIntent.applyConsequence({
    required SceneConsequence consequence,
  }) {
    return SceneRuntimePlanIntent._(
      kind: SceneRuntimePlanIntentKind.applyConsequence,
      consequence: consequence,
    );
  }

  factory SceneRuntimePlanIntent.executeInteractiveCommand({
    required SceneInteractiveCommand command,
  }) {
    return SceneRuntimePlanIntent._(
      kind: SceneRuntimePlanIntentKind.executeInteractiveCommand,
      interactiveCommand: command,
    );
  }

  factory SceneRuntimePlanIntent.requestStructuredInteraction({
    required ScenePreSessionInteractionSpec interaction,
    String? sourceNodeId,
  }) {
    return SceneRuntimePlanIntent._(
      kind: SceneRuntimePlanIntentKind.requestStructuredInteraction,
      preSessionInteraction: interaction,
      sourceNodeId: sourceNodeId,
    );
  }

  final SceneRuntimePlanIntentKind kind;
  final String? sceneOutcomeId;
  final SceneOutcomePolicy? outcomePolicy;
  final SceneConditionSource? conditionSource;
  final String? branchSourceNodeId;
  final SceneBranchOutcomeFallbackPolicy? branchFallbackPolicy;
  final List<String> branchSourceOutcomes;
  final String? dialogueId;
  final String? yarnNodeName;
  final List<String> expectedOutcomes;
  final String? battleKind;
  final String? trainerId;
  final String? battleTemplateId;
  final String? npcEntityId;
  final List<String> battleDeclaredOutcomes;
  final String? cinematicId;
  final String? presentationCinematicId;
  final String? sourceNodeId;
  final Map<String, String> presentationAwaitableNodeIdsByMarkerId;
  final SceneConsequence? consequence;
  final SceneInteractiveCommand? interactiveCommand;
  final ScenePreSessionInteractionSpec? preSessionInteraction;

  List<String> get declaredOutputPortIds => switch (kind) {
        SceneRuntimePlanIntentKind.start ||
        SceneRuntimePlanIntentKind.merge ||
        SceneRuntimePlanIntentKind.playCinematic ||
        SceneRuntimePlanIntentKind.playPresentationCinematic ||
    SceneRuntimePlanIntentKind.applyConsequence => const ['completed'],
        SceneRuntimePlanIntentKind.executeInteractiveCommand =>
          interactiveCommand?.outputPortIds ?? const <String>[],
        SceneRuntimePlanIntentKind.requestStructuredInteraction =>
          preSessionInteraction?.outputPortIds ?? const <String>[],
        SceneRuntimePlanIntentKind.evaluateCondition => const ['true', 'false'],
        SceneRuntimePlanIntentKind.branchByOutcome => [
            ...branchSourceOutcomes,
            if (branchFallbackPolicy ==
                    SceneBranchOutcomeFallbackPolicy.defaultRoute &&
                !branchSourceOutcomes.contains('default'))
              'default',
      if (branchFallbackPolicy == SceneBranchOutcomeFallbackPolicy.errorRoute &&
                !branchSourceOutcomes.contains('error'))
              'error',
          ],
        SceneRuntimePlanIntentKind.showDialogue => [
            'completed',
            for (final outcome in expectedOutcomes)
              if (outcome != 'completed') outcome,
          ],
    SceneRuntimePlanIntentKind.startBattle =>
      battleDeclaredOutcomes.isEmpty
            ? const ['victory', 'defeat']
            : battleDeclaredOutcomes,
        SceneRuntimePlanIntentKind.end => const [],
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneRuntimePlanIntent &&
          other.kind == kind &&
          other.sceneOutcomeId == sceneOutcomeId &&
          other.outcomePolicy == outcomePolicy &&
          other.conditionSource == conditionSource &&
          other.branchSourceNodeId == branchSourceNodeId &&
          other.branchFallbackPolicy == branchFallbackPolicy &&
          _listEquals(other.branchSourceOutcomes, branchSourceOutcomes) &&
          other.dialogueId == dialogueId &&
          other.yarnNodeName == yarnNodeName &&
          _listEquals(other.expectedOutcomes, expectedOutcomes) &&
          other.battleKind == battleKind &&
          other.trainerId == trainerId &&
          other.battleTemplateId == battleTemplateId &&
          other.npcEntityId == npcEntityId &&
          _listEquals(other.battleDeclaredOutcomes, battleDeclaredOutcomes) &&
          other.cinematicId == cinematicId &&
          other.presentationCinematicId == presentationCinematicId &&
          other.sourceNodeId == sourceNodeId &&
          _mapEquals(
            other.presentationAwaitableNodeIdsByMarkerId,
            presentationAwaitableNodeIdsByMarkerId,
          ) &&
          other.consequence == consequence &&
          other.interactiveCommand == interactiveCommand &&
          other.preSessionInteraction == preSessionInteraction;

  @override
  int get hashCode => Object.hash(
        kind,
        sceneOutcomeId,
        outcomePolicy,
        conditionSource,
        branchSourceNodeId,
        branchFallbackPolicy,
        Object.hashAll(branchSourceOutcomes),
        dialogueId,
        yarnNodeName,
        Object.hashAll(expectedOutcomes),
        battleKind,
        trainerId,
        battleTemplateId,
        npcEntityId,
        Object.hashAll(battleDeclaredOutcomes),
        cinematicId,
        Object.hash(
          presentationCinematicId,
          sourceNodeId,
          Object.hashAllUnordered(
            presentationAwaitableNodeIdsByMarkerId.entries.map(
              (entry) => Object.hash(entry.key, entry.value),
            ),
          ),
        ),
        consequence,
        interactiveCommand,
        preSessionInteraction,
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

String sceneExecutionCapabilityForRuntimeIntent(
  SceneExecutionProfile profile,
  SceneRuntimePlanIntent intent,
) {
  return switch (intent.kind) {
    SceneRuntimePlanIntentKind.start => SceneExecutionCapabilityIds.flowStart,
    SceneRuntimePlanIntentKind.end => SceneExecutionCapabilityIds.flowEnd,
    SceneRuntimePlanIntentKind.evaluateCondition =>
      SceneExecutionCapabilityIds.worldCondition,
    SceneRuntimePlanIntentKind.showDialogue => switch (profile) {
      SceneExecutionProfile.world => SceneExecutionCapabilityIds.worldDialogue,
      SceneExecutionProfile.preSession =>
        SceneExecutionCapabilityIds.inputMessage,
    },
    SceneRuntimePlanIntentKind.startBattle =>
      SceneExecutionCapabilityIds.worldBattle,
    SceneRuntimePlanIntentKind.playCinematic =>
      SceneExecutionCapabilityIds.worldCinematic,
    SceneRuntimePlanIntentKind.playPresentationCinematic =>
      SceneExecutionCapabilityIds.presentationCinematic,
    SceneRuntimePlanIntentKind.applyConsequence ||
    SceneRuntimePlanIntentKind.executeInteractiveCommand =>
      SceneExecutionCapabilityIds.worldAction,
    SceneRuntimePlanIntentKind.requestStructuredInteraction => switch (
        intent.preSessionInteraction!.kind
      ) {
        SceneInteractionRequestKind.message =>
          SceneExecutionCapabilityIds.inputMessage,
        SceneInteractionRequestKind.choice =>
          SceneExecutionCapabilityIds.inputChoice,
        SceneInteractionRequestKind.text =>
          SceneExecutionCapabilityIds.inputText,
        SceneInteractionRequestKind.confirmation =>
          SceneExecutionCapabilityIds.inputConfirmation,
        SceneInteractionRequestKind.selection =>
          SceneExecutionCapabilityIds.inputSelection,
      },
    SceneRuntimePlanIntentKind.branchByOutcome => switch (profile) {
      SceneExecutionProfile.world => SceneExecutionCapabilityIds.worldBranch,
        SceneExecutionProfile.preSession =>
          SceneExecutionCapabilityIds.flowBranch,
      },
    SceneRuntimePlanIntentKind.merge => switch (profile) {
        SceneExecutionProfile.world => SceneExecutionCapabilityIds.worldMerge,
      SceneExecutionProfile.preSession => SceneExecutionCapabilityIds.flowMerge,
      },
  };
}

@immutable
final class SceneRuntimePlanBuildResult {
  SceneRuntimePlanBuildResult({
    required this.plan,
    required List<SceneRuntimePlanDiagnostic> diagnostics,
  }) : diagnostics = List<SceneRuntimePlanDiagnostic>.unmodifiable(diagnostics);

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

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}
