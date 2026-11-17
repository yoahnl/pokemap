import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scenes/steps/scene_step_fixtures.dart';
import 'map_builder_story_support.dart';

void main() {
  testWidgets('an advanced scene stays a linked scene in the local card', (
    tester,
  ) async {
    final scene = sceneOf(
      [startNode(), factNode('fact'), dialogueNode('talk'), endNode('end')],
      [link('start', 'fact'), link('fact', 'talk'), link('talk', 'end')],
    );
    final fixture = await openStory(
      records: [storyRecord(1, sceneId: scene.id)],
      scenes: [scene],
    );
    await pumpStoryInspector(tester, fixture);
    fixture.story.openTab(MapStoryTab.behaviour);
    await tester.pumpAndSettle();
    expect(find.text(scene.name), findsOneWidget);
    expect(find.text('Modifier dans Histoire'), findsOneWidget);
    expect(
      find.byKey(ValueKey('scene-graph-preview-${scene.id}')),
      findsNothing,
    );
    expect(find.byKey(ValueKey('map-story-steps-${scene.id}')), findsNothing);
    expect(fixture.story.sceneOf(scene.id), scene);
    expect(fixture.ports.dialogueReads, isEmpty);
    expect(fixture.story.dirty, isFalse);
  });
}
