import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/state/scene_consequence_catalog_providers.dart';

void main() {
  test('story step consequence catalog keeps human labels and stable IDs', () {
    final catalogs =
        const SceneConsequenceCatalogs.unavailable().withStorySteps(
      [
        NarrativeStoryStepPickerOption(
          stepId: 'step_leave_port',
          humanLabel: 'Quitter le port',
          description: 'Objectif de départ.',
          sourceScenarioId: 'story_main',
          sourceScenarioLabel: 'Histoire principale',
          sourceKind: NarrativeStoryStepPickerSource.stepStudio,
          order: 0,
          linkedCutsceneIds: const <String>[],
          expectedOutcomeIds: const <String>[],
          emittedOutcomeIds: const <String>[],
          debugTechnicalLabel: 'story_main:chapter_port:step_leave_port',
        ),
      ],
    );

    expect(catalogs.storySteps.isReady, isTrue);
    expect(catalogs.storySteps.options.single.id, 'step_leave_port');
    expect(catalogs.storySteps.options.single.label, 'Quitter le port');
  });
}
