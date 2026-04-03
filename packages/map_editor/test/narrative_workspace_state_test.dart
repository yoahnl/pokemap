import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';

void main() {
  group('NarrativeWorkspaceController', () {
    test('opens views and keeps coherent selection state', () {
      final controller = NarrativeWorkspaceController();
      addTearDown(controller.dispose);

      controller.openGlobalStory(scenarioId: 'global.main');
      expect(controller.state.view, NarrativeWorkspaceView.globalStory);
      expect(controller.state.selectedGlobalStoryId, 'global.main');

      controller.openStep(
          stepId: 'step.starter', globalScenarioId: 'global.main');
      expect(controller.state.view, NarrativeWorkspaceView.step);
      expect(controller.state.selectedStepId, 'step.starter');
      expect(controller.state.selectedGlobalStoryId, 'global.main');

      controller.openCutscene(cutsceneScenarioId: 'cutscene.professor_intro');
      expect(controller.state.view, NarrativeWorkspaceView.cutscene);
      expect(controller.state.selectedCutsceneId, 'cutscene.professor_intro');

      controller.selectOutcome('starter.selected.fire');
      expect(controller.state.selectedOutcomeId, 'starter.selected.fire');
    });
  });
}
