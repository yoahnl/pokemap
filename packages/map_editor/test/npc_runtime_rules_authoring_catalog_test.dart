import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'package:map_editor/src/features/map_entities/application/npc_runtime_rules_authoring_catalog.dart';

void main() {
  test('knownStoryFlagIds dans globalProperties enrichit le catalogue flags',
      () {
    const project = ProjectManifest(
      name: 'p',
      maps: [],
      tilesets: [],
      globalProperties: {
        'authoring.knownStoryFlagIds': ['declared_flag', 'other'],
      },
    );
    final catalog = buildNpcRuntimeAuthoringCatalog(project);
    final ids = catalog.flags.map((e) => e.id).toSet();
    expect(ids, contains('declared_flag'));
    expect(ids, contains('other'));
  });

  test('typed conditions add only Facts to the legacy flag picker', () {
    final project = ProjectManifest(
      name: 'p',
      maps: const [],
      tilesets: const [],
      scenarios: <ScenarioAsset>[
        ScenarioAsset(
          id: 'scenario',
          name: 'Scenario',
          entryNodeId: 'start',
          activationCondition: ScriptConditionFactory.allOf(<ScriptCondition>[
            ScriptConditionFactory.factEquals(
              'fact.typed',
              const NarrativeValue.string('true'),
            ),
            ScriptConditionFactory.stepCompleted('step.hidden'),
            ScriptConditionFactory.badgeOwned('badge.hidden'),
            ScriptConditionFactory.itemQuantityAtLeast('item.hidden', 1),
          ]),
          nodes: const <ScenarioNode>[
            ScenarioNode(id: 'start', type: ScenarioNodeType.start),
          ],
        ),
      ],
    );

    final ids = buildNpcRuntimeAuthoringCatalog(project)
        .flags
        .map((option) => option.id)
        .toSet();

    expect(ids, contains('fact.typed'));
    expect(ids, isNot(contains('step.hidden')));
    expect(ids, isNot(contains('badge.hidden')));
    expect(ids, isNot(contains('item.hidden')));
  });
}
