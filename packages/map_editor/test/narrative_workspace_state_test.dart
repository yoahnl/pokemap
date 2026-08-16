import 'package:flutter_test/flutter_test.dart';
import './support/riverpod_notifier_harness.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';

void main() {
  group('NarrativeWorkspaceController', () {
    test('opens views and keeps coherent selection state', () {
      final controller = mountNarrativeWorkspaceController();

      controller.openGlobalStory(scenarioId: 'global.main');
      expect(controller.state.view, NarrativeWorkspaceView.globalStory);
      expect(controller.state.selectedGlobalStoryId, 'global.main');

      controller.openStep(
        stepId: 'step.starter',
        globalScenarioId: 'global.main',
      );
      expect(controller.state.view, NarrativeWorkspaceView.step);
      expect(controller.state.selectedStepId, 'step.starter');
      expect(controller.state.selectedGlobalStoryId, 'global.main');

      controller.openCinematics();
      expect(controller.state.view, NarrativeWorkspaceView.cinematics);

      controller.selectOutcome('starter.selected.fire');
      expect(controller.state.selectedOutcomeId, 'starter.selected.fire');
    });
  });
}
