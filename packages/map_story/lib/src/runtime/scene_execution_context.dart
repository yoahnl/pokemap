import 'package:meta/meta.dart' show immutable;

@immutable
final class SceneBranchProvenanceEntry {
  const SceneBranchProvenanceEntry({
    required this.branchNodeId,
    required this.sourceNodeId,
    required this.sourceOutcome,
    required this.routedPortId,
    required this.usedFallback,
  });

  final String branchNodeId;
  final String sourceNodeId;
  final String sourceOutcome;
  final String routedPortId;
  final bool usedFallback;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneBranchProvenanceEntry &&
          other.branchNodeId == branchNodeId &&
          other.sourceNodeId == sourceNodeId &&
          other.sourceOutcome == sourceOutcome &&
          other.routedPortId == routedPortId &&
          other.usedFallback == usedFallback;

  @override
  int get hashCode => Object.hash(
        branchNodeId,
        sourceNodeId,
        sourceOutcome,
        routedPortId,
        usedFallback,
      );
}

/// In-memory state carried while one Scene executes.
///
/// This state deliberately is not part of a save file: runtime checkpoints are
/// blocked while a Scene is awaiting host input. Only the state before the
/// Scene starts and the committed state after an End node are persistable.
@immutable
final class SceneExecutionContext {
  SceneExecutionContext({
    Map<String, String> lastOutcomeByNodeId = const <String, String>{},
    this.currentOutcome,
    Set<String> appliedPersistentNodeIds = const <String>{},
    List<SceneBranchProvenanceEntry> branchProvenance =
        const <SceneBranchProvenanceEntry>[],
  })  : lastOutcomeByNodeId = Map<String, String>.unmodifiable(
          lastOutcomeByNodeId,
        ),
        appliedPersistentNodeIds = Set<String>.unmodifiable(
          appliedPersistentNodeIds,
        ),
        branchProvenance = List<SceneBranchProvenanceEntry>.unmodifiable(
          branchProvenance,
        );

  static final SceneExecutionContext empty = SceneExecutionContext();

  final Map<String, String> lastOutcomeByNodeId;
  final String? currentOutcome;
  final Set<String> appliedPersistentNodeIds;
  final List<SceneBranchProvenanceEntry> branchProvenance;

  SceneExecutionContext recordOutcome({
    required String nodeId,
    required String outcome,
  }) {
    return SceneExecutionContext(
      lastOutcomeByNodeId: <String, String>{
        ...lastOutcomeByNodeId,
        nodeId: outcome,
      },
      currentOutcome: outcome,
      appliedPersistentNodeIds: appliedPersistentNodeIds,
      branchProvenance: branchProvenance,
    );
  }

  SceneExecutionContext markPersistentNodeApplied(String nodeId) {
    return SceneExecutionContext(
      lastOutcomeByNodeId: lastOutcomeByNodeId,
      currentOutcome: currentOutcome,
      appliedPersistentNodeIds: <String>{
        ...appliedPersistentNodeIds,
        nodeId,
      },
      branchProvenance: branchProvenance,
    );
  }

  SceneExecutionContext recordBranch(SceneBranchProvenanceEntry entry) {
    return SceneExecutionContext(
      lastOutcomeByNodeId: lastOutcomeByNodeId,
      currentOutcome: entry.sourceOutcome,
      appliedPersistentNodeIds: appliedPersistentNodeIds,
      branchProvenance: <SceneBranchProvenanceEntry>[
        ...branchProvenance,
        entry,
      ],
    );
  }
}
