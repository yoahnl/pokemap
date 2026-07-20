import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SceneExecutionContext', () {
    test('records outcomes without mutating the previous context', () {
      final initial = SceneExecutionContext.empty;

      final updated = initial.recordOutcome(
        nodeId: 'dialogue_intro',
        outcome: 'accept',
      );

      expect(initial.lastOutcomeByNodeId, isEmpty);
      expect(initial.currentOutcome, isNull);
      expect(updated.lastOutcomeByNodeId, {'dialogue_intro': 'accept'});
      expect(updated.currentOutcome, 'accept');
    });

    test('tracks persistent nodes and branch provenance immutably', () {
      final withOutcome = SceneExecutionContext.empty.recordOutcome(
        nodeId: 'battle_rival',
        outcome: 'victory',
      );
      final withPersistentNode =
          withOutcome.markPersistentNodeApplied('reward_action');
      final completed = withPersistentNode.recordBranch(
        const SceneBranchProvenanceEntry(
          branchNodeId: 'branch_battle',
          sourceNodeId: 'battle_rival',
          sourceOutcome: 'victory',
          routedPortId: 'victory',
          usedFallback: false,
        ),
      );

      expect(withOutcome.appliedPersistentNodeIds, isEmpty);
      expect(withPersistentNode.appliedPersistentNodeIds, {'reward_action'});
      expect(completed.branchProvenance, hasLength(1));
      expect(completed.branchProvenance.single.sourceOutcome, 'victory');
      expect(completed.currentOutcome, 'victory');
    });
  });
}
