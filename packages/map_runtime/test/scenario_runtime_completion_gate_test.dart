import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/scenario_runtime_completion_gate.dart';

void main() {
  group('scenarioRuntimeCompletionBlockingReason', () {
    test('returns null when runtime is fully idle', () {
      final reason = scenarioRuntimeCompletionBlockingReason(
        isOverworldFlow: true,
        flowPhaseName: 'overworld',
        isDialogueOpen: false,
        isCutsceneRunnerActive: false,
        hasPendingFollowCharacter: false,
        hasPendingMoveContinuations: false,
        hasPendingNpcWarpEntries: false,
        hasPendingTransitionMapRequest: false,
        hasPendingRuntimeWarp: false,
        hasPendingRuntimeConnection: false,
        isPlayerStepInProgress: false,
      );
      expect(reason, isNull);
    });

    test('prioritizes followCharacter as blocking reason', () {
      final reason = scenarioRuntimeCompletionBlockingReason(
        isOverworldFlow: true,
        flowPhaseName: 'overworld',
        isDialogueOpen: false,
        isCutsceneRunnerActive: false,
        hasPendingFollowCharacter: true,
        hasPendingMoveContinuations: true,
        hasPendingNpcWarpEntries: true,
        hasPendingTransitionMapRequest: true,
        hasPendingRuntimeWarp: true,
        hasPendingRuntimeConnection: true,
        isPlayerStepInProgress: true,
      );
      expect(reason, 'follow_character_active');
    });

    test('returns flow reason when not overworld', () {
      final reason = scenarioRuntimeCompletionBlockingReason(
        isOverworldFlow: false,
        flowPhaseName: 'mapTransition',
        isDialogueOpen: false,
        isCutsceneRunnerActive: false,
        hasPendingFollowCharacter: false,
        hasPendingMoveContinuations: false,
        hasPendingNpcWarpEntries: false,
        hasPendingTransitionMapRequest: false,
        hasPendingRuntimeWarp: false,
        hasPendingRuntimeConnection: false,
        isPlayerStepInProgress: false,
      );
      expect(reason, 'flow_phase_mapTransition');
    });
  });
}
