import 'package:avelune_studio/features/scenes/application/steps/scene_step_families.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_list.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_projection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_story_steps_list_test.dart'
    show linearScene, nestedScene, pumpSteps;

List<String> changedNodeIds(SceneAsset before, SceneAsset after) {
  final previous = {for (final node in before.graph.nodes) node.id: node};
  return [
    for (final node in after.graph.nodes)
      if (previous[node.id] != node) node.id,
  ];
}

Future<void> choose(WidgetTester tester, String key, String option) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> openMenu(WidgetTester tester, Finder button, String item) async {
  await tester.tap(button);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey(item)));
  await tester.pumpAndSettle();
}

List<String> rootIds(SceneAsset scene) => [
  for (final step
      in (projectSceneSteps(scene.graph) as SceneStepList).root.steps)
    step.nodeId,
];

SceneNode nodeOf(SceneAsset scene, String id) =>
    scene.graph.nodes.singleWhere((node) => node.id == id);

void main() {
  for (final (name, scene, key, option, nodeId, check) in [
    (
      'fact',
      linearScene(),
      'story-step-fact-fact',
      'Portail ouvert',
      'fact',
      (SceneNode node) => expect(
        ((node.payload as SceneActionPayload).consequence!
                as SceneSetFactConsequence)
            .factId,
        'gate',
      ),
    ),
    (
      'fact value',
      linearScene(),
      'story-step-value-fact',
      'Non',
      'fact',
      (SceneNode node) => expect(
        ((node.payload as SceneActionPayload).consequence!
                as SceneSetFactConsequence)
            .value,
        isFalse,
      ),
    ),
    (
      'trainer',
      nestedScene(),
      'story-step-trainer-fight',
      'As',
      'fight',
      (SceneNode node) =>
          expect((node.payload as SceneBattlePayload).trainerId, 'ace'),
    ),
    (
      'condition fact',
      nestedScene(),
      'story-step-condition-fact-if',
      'Rencontré',
      'if',
      (SceneNode node) => expect(
        (node.payload as SceneConditionPayload).conditionSource!.sourceId,
        'met',
      ),
    ),
    (
      'condition value',
      nestedScene(),
      'story-step-condition-value-if',
      'Faux',
      'if',
      (SceneNode node) => expect(
        (node.payload as SceneConditionPayload).conditionSource!.operator,
        SceneConditionOperator.isFalse,
      ),
    ),
  ]) {
    testWidgets('the $name form edits exactly one node', (tester) async {
      final changes = await pumpSteps(tester, scene);
      await choose(tester, key, option);
      expect(changes, hasLength(1));
      expect(changedNodeIds(scene, changes.single), [nodeId]);
      expect(changes.single.graph.edges, scene.graph.edges);
      expect(changes.single.layout, scene.layout);
      check(nodeOf(changes.single, nodeId));
    });
  }

  testWidgets('the presence form picks a map character and an effect', (
    tester,
  ) async {
    final scene = linearScene();
    final withPresence = SceneAsset.fromJson({
      ...scene.toJson(),
      'graph': SceneGraph(
        startNodeId: 'start',
        nodes: [
          for (final node in scene.graph.nodes)
            node.id == 'fact'
                ? SceneNode(
                    id: 'fact',
                    kind: SceneNodeKind.action,
                    payload: SceneActionPayload.consequence(
                      SceneConsequence.setNpcPresence(
                        mapId: 'town',
                        entityId: 'guide',
                        present: true,
                      ),
                    ),
                  )
                : node,
        ],
        edges: scene.graph.edges,
      ).toJson(),
    });
    SceneSetNpcPresenceConsequence change(SceneAsset scene) =>
        (nodeOf(scene, 'fact').payload as SceneActionPayload).consequence!
            as SceneSetNpcPresenceConsequence;
    var changes = await pumpSteps(tester, withPresence);
    await choose(tester, 'story-step-entity-fact', 'Maman');
    expect(changedNodeIds(withPresence, changes.single), ['fact']);
    expect(change(changes.single).entityId, 'mom');
    changes = await pumpSteps(tester, withPresence);
    await choose(tester, 'story-step-presence-fact', 'Disparaît');
    expect(change(changes.single).present, isFalse);
    expect(change(changes.single).entityId, 'guide');
  });

  testWidgets('« + étape » inserts a step at the end of its sequence', (
    tester,
  ) async {
    final scene = linearScene();
    final changes = await pumpSteps(tester, scene);
    await openMenu(
      tester,
      find.descendant(
        of: find.byKey(const ValueKey('story-step-add-root')),
        matching: find.text('Étape'),
      ),
      'story-step-new-showOrHide',
    );
    expect(changes, hasLength(1));
    final ids = rootIds(changes.single);
    expect(ids.take(2), ['fact', 'talk']);
    final created = nodeOf(changes.single, ids.last);
    expect(
      (created.payload as SceneActionPayload).consequence,
      isA<SceneSetNpcPresenceConsequence>(),
    );
    expect(
      changes.single.layout.nodeLayouts.map((layout) => layout.nodeId),
      contains(created.id),
    );
  });

  for (final family in [
    SceneStepFamily.rememberFact,
    SceneStepFamily.talk,
    SceneStepFamily.battle,
    SceneStepFamily.conditions,
  ]) {
    testWidgets('« + étape » inserts a ${family.name} step', (tester) async {
      final changes = await pumpSteps(tester, linearScene());
      await openMenu(
        tester,
        find.text('Étape').first,
        'story-step-new-${family.name}',
      );
      expect(changes, hasLength(1));
      final created = nodeOf(changes.single, rootIds(changes.single).last);
      expect(sceneStepFamilyOfNode(created), family);
    });
  }

  testWidgets('a step is removed from its menu', (tester) async {
    final scene = linearScene();
    final changes = await pumpSteps(tester, scene);
    await openMenu(
      tester,
      find.byKey(const ValueKey('story-step-actions-fact')),
      'story-step-remove-fact',
    );
    expect(changes, hasLength(1));
    expect(rootIds(changes.single), ['talk']);
  });

  testWidgets('a step is wrapped in « si » from its menu', (tester) async {
    final scene = linearScene();
    final changes = await pumpSteps(tester, scene);
    await openMenu(
      tester,
      find.byKey(const ValueKey('story-step-actions-talk')),
      'story-step-wrap-talk',
    );
    expect(changes, hasLength(1));
    final list = projectSceneSteps(changes.single.graph) as SceneStepList;
    final block = list.root.steps.last as SceneBlockStep;
    expect(block.kind, SceneStepBlockKind.condition);
    expect(block.branches.first.sequence.steps.single.nodeId, 'talk');
    final source =
        (nodeOf(changes.single, block.nodeId).payload as SceneConditionPayload)
            .conditionSource!;
    expect(source.sourceKind, SceneConditionSourceKind.fact);
  });

  testWidgets('a step is moved by drag', (tester) async {
    final scene = linearScene();
    final changes = await pumpSteps(tester, scene);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('story-step-drag-talk'))),
    );
    await tester.pump();
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('story-step-drop-root-0'))),
    );
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, hasLength(1));
    expect(rootIds(changes.single), ['talk', 'fact']);
  });

  testWidgets('nothing is editable when disabled', (tester) async {
    final changes = await pumpSteps(tester, linearScene(), enabled: false);
    expect(find.byIcon(Icons.drag_indicator), findsNothing);
    expect(find.byIcon(Icons.more_horiz), findsNothing);
    expect(find.text('Étape'), findsNothing);
    expect(changes, isEmpty);
  });
}
