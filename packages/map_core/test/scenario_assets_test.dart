import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ScenarioAsset serialization', () {
    test('round-trips scenario with bindings and condition payload', () {
      final scenario = ScenarioAsset(
        id: 'intro_scenario',
        name: 'Intro Scenario',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
        declaredOutcomes: const <String>['professor_intro.completed'],
        activationCondition:
            ScriptConditionFactory.flagIsSet('story.chapter_1_started'),
        nodes: [
          const ScenarioNode(
            id: 'start',
            type: ScenarioNodeType.start,
            title: 'Start',
            position: ScenarioNodePosition(x: 120, y: 80),
          ),
          ScenarioNode(
            id: 'branch',
            type: ScenarioNodeType.condition,
            title: 'Starter check',
            position: const ScenarioNodePosition(x: 420, y: 80),
            binding: const ScenarioNodeBinding(
              scriptId: 'intro_script',
              dialogueId: 'intro_dialogue',
              mapId: 'town_square',
              eventId: 'event_professor',
              outcomeId: 'professor_intro.completed',
            ),
            payload: ScenarioNodePayload(
              condition: ScriptConditionFactory.flagIsSet('story.got_starter'),
            ),
          ),
        ],
        edges: const [
          ScenarioEdge(
            id: 'e_start_branch',
            fromNodeId: 'start',
            toNodeId: 'branch',
            label: 'next',
          ),
        ],
      );

      final json = scenario.toJson();
      final decoded = ScenarioAsset.fromJson(json);
      expect(decoded, equals(scenario));
      expect(decoded.nodes[1].payload.condition?.type,
          ScriptConditionType.flagIsSet);
      expect(decoded.scope, ScenarioScope.globalStory);
      expect(decoded.declaredOutcomes, contains('professor_intro.completed'));
    });
  });

  group('ScenarioAsset validation', () {
    test('accepts valid scenario inside project manifest', () {
      final project = _projectWithScenario(
        const ScenarioAsset(
          id: 'story_intro',
          name: 'Story Intro',
          entryNodeId: 'start',
          nodes: [
            ScenarioNode(
              id: 'start',
              type: ScenarioNodeType.start,
              title: 'Start',
              binding: ScenarioNodeBinding(
                mapId: 'town_square',
                scriptId: 'intro_script',
                dialogueId: 'intro_dialogue',
              ),
            ),
            ScenarioNode(
              id: 'decision',
              type: ScenarioNodeType.choice,
              title: 'Choose',
            ),
            ScenarioNode(
              id: 'end',
              type: ScenarioNodeType.end,
              title: 'End',
            ),
          ],
          edges: [
            ScenarioEdge(
              id: 's_to_d',
              fromNodeId: 'start',
              toNodeId: 'decision',
            ),
            ScenarioEdge(
              id: 'd_to_end_a',
              fromNodeId: 'decision',
              toNodeId: 'end',
              label: 'A',
            ),
            ScenarioEdge(
              id: 'd_to_end_b',
              fromNodeId: 'decision',
              toNodeId: 'start',
              label: 'B',
            ),
          ],
        ),
      );

      expect(() => ProjectValidator.validate(project), returnsNormally);
    });

    test('rejects entryNodeId that does not exist', () {
      final project = _projectWithScenario(
        const ScenarioAsset(
          id: 'broken',
          name: 'Broken Scenario',
          entryNodeId: 'missing',
          nodes: [
            ScenarioNode(
              id: 'start',
              type: ScenarioNodeType.start,
            ),
          ],
        ),
      );

      expect(
        () => ProjectValidator.validate(project),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects scenario binding to unknown script', () {
      final project = _projectWithScenario(
        const ScenarioAsset(
          id: 'broken',
          name: 'Broken Scenario',
          entryNodeId: 'start',
          nodes: [
            ScenarioNode(
              id: 'start',
              type: ScenarioNodeType.start,
              binding: ScenarioNodeBinding(scriptId: 'missing_script'),
            ),
          ],
        ),
      );

      expect(
        () => ProjectValidator.validate(project),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects choice node with less than two outgoing edges', () {
      final project = _projectWithScenario(
        const ScenarioAsset(
          id: 'broken',
          name: 'Broken Scenario',
          entryNodeId: 'start',
          nodes: [
            ScenarioNode(
              id: 'start',
              type: ScenarioNodeType.start,
            ),
            ScenarioNode(
              id: 'choice',
              type: ScenarioNodeType.choice,
            ),
            ScenarioNode(
              id: 'end',
              type: ScenarioNodeType.end,
            ),
          ],
          edges: [
            ScenarioEdge(
              id: 's_to_c',
              fromNodeId: 'start',
              toNodeId: 'choice',
            ),
            ScenarioEdge(
              id: 'c_to_e',
              fromNodeId: 'choice',
              toNodeId: 'end',
            ),
          ],
        ),
      );

      expect(
        () => ProjectValidator.validate(project),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects global story scenario that uses world source hook', () {
      final project = _projectWithScenario(
        const ScenarioAsset(
          id: 'global_story',
          name: 'Global Story',
          scope: ScenarioScope.globalStory,
          entryNodeId: 'start',
          nodes: [
            ScenarioNode(id: 'start', type: ScenarioNodeType.start),
            ScenarioNode(
              id: 'source_map',
              type: ScenarioNodeType.reference,
              payload: ScenarioNodePayload(actionKind: 'sourceMapEnter'),
              binding: ScenarioNodeBinding(mapId: 'town_square'),
            ),
          ],
          edges: [
            ScenarioEdge(
              id: 's_to_source',
              fromNodeId: 'start',
              toNodeId: 'source_map',
            ),
          ],
        ),
      );

      expect(
        () => ProjectValidator.validate(project),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects emitOutcome without outcomeId', () {
      final project = _projectWithScenario(
        const ScenarioAsset(
          id: 'local_flow',
          name: 'Local flow',
          scope: ScenarioScope.localEventFlow,
          entryNodeId: 'start',
          nodes: [
            ScenarioNode(id: 'start', type: ScenarioNodeType.start),
            ScenarioNode(
              id: 'emit',
              type: ScenarioNodeType.action,
              payload: ScenarioNodePayload(actionKind: 'emitOutcome'),
            ),
          ],
          edges: [
            ScenarioEdge(
                id: 's_to_emit', fromNodeId: 'start', toNodeId: 'emit'),
          ],
        ),
      );

      expect(
        () => ProjectValidator.validate(project),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

ProjectManifest _projectWithScenario(ScenarioAsset scenario) {
  return ProjectManifest(
    name: 'Scenario Project',
    maps: const [
      ProjectMapEntry(
        id: 'town_square',
        name: 'Town Square',
        relativePath: 'maps/town_square.json',
      ),
    ],
    tilesets: const [],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'intro_dialogue',
        name: 'Intro Dialogue',
        relativePath: 'dialogues/intro.yarn',
      ),
    ],
    scripts: const [
      ProjectScriptEntry(
        id: 'intro_script',
        name: 'Intro Script',
        asset: ScriptAsset(
          id: 'intro_script',
          nodes: [ScriptNode(id: 'start')],
          defaultStartNode: 'start',
        ),
      ),
    ],
    scenarios: [scenario],
  );
}
