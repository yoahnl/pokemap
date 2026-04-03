import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';

void main() {
  group('buildNarrativeWorkspaceProjection', () {
    test('splits global story and local flows, and projects steps', () {
      const project = ProjectManifest(
        name: 'test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        scenarios: <ScenarioAsset>[
          ScenarioAsset(
            id: 'global_intro',
            name: 'Global Intro',
            scope: ScenarioScope.globalStory,
            entryNodeId: 'n_start',
            metadata: <String, String>{
              'step.id': 'step.professor_intro',
              'step.name': 'Rencontrer le professeur',
              'step.cutsceneIds': 'local_professor_scene',
            },
            nodes: <ScenarioNode>[
              ScenarioNode(
                id: 'n_emit',
                payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
                binding:
                    ScenarioNodeBinding(outcomeId: 'chapter_1.intro_ready'),
              ),
            ],
          ),
          ScenarioAsset(
            id: 'local_professor_scene',
            name: 'Professor Scene',
            scope: ScenarioScope.localEventFlow,
            entryNodeId: 'n_local_start',
            nodes: <ScenarioNode>[
              ScenarioNode(
                id: 'n_source',
                payload: ScenarioNodePayload(actionKind: 'sourceOutcome'),
                binding:
                    ScenarioNodeBinding(outcomeId: 'chapter_1.intro_ready'),
              ),
              ScenarioNode(
                id: 'n_emit_local',
                payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
                binding:
                    ScenarioNodeBinding(outcomeId: 'professor_intro.completed'),
              ),
            ],
          ),
        ],
      );

      final projection = buildNarrativeWorkspaceProjection(project);

      expect(projection.globalStories.length, 1);
      expect(projection.localEventFlows.length, 1);
      expect(projection.steps.length, 1);

      final step = projection.steps.first;
      expect(step.id, 'step.professor_intro');
      expect(step.linkedCutsceneIds, contains('local_professor_scene'));

      final globalOutcome = projection.outcomes
          .where((o) => o.id == 'chapter_1.intro_ready')
          .first;
      expect(globalOutcome.scope, NarrativeOutcomeScope.mixed);
      expect(globalOutcome.emittedByScenarioIds, contains('global_intro'));
      expect(globalOutcome.consumedByScenarioIds,
          contains('local_professor_scene'));
    });
  });
}
