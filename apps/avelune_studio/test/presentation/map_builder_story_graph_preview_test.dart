import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../scenes/steps/scene_step_fixtures.dart';
import 'map_builder_story_support.dart';

void main() {
  testWidgets('a behaviour that runs a scene shows its graph preview, not a '
      'list of steps', (tester) async {
    final scene = sceneOf(
      [startNode(), factNode('fact'), dialogueNode('talk'), endNode('end')],
      [link('start', 'fact'), link('fact', 'talk'), link('talk', 'end')],
    );
    final fixture = await openStory(
      records: [storyRecord(1, sceneId: scene.id)],
      scenes: [scene],
    );
    await pumpStoryInspector(tester, fixture);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('map-story-then')), findsOne);
    expect(find.byKey(ValueKey('scene-graph-preview-${scene.id}')), findsOne);
    for (final id in ['start', 'fact', 'talk', 'end']) {
      expect(find.byKey(ValueKey('scene-graph-card-$id')), findsOne);
    }
    expect(find.textContaining('4 étapes'), findsOne);
    expect(find.byKey(ValueKey('map-story-steps-${scene.id}')), findsNothing);
  });
}
