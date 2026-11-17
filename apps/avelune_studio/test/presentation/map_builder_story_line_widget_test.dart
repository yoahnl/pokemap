import 'dart:async';

import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'map_builder_story_support.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _cards(WidgetTester tester, StoryFixture fixture) async {
  await pumpStoryInspector(tester, fixture);
  fixture.story.openTab(MapStoryTab.behaviour);
  await tester.pump();
}

void main() {
  testWidgets('a local line card does not load or edit its shared document', (
    tester,
  ) async {
    final fixture = await openStory(
      records: [storyRecord(1, sceneId: 'scene_talk')],
      scenes: [storyLineScene('scene_talk', 'dialogue_talk')],
      dialogues: [
        storyLineDialogue('dialogue_talk', ['Salut']),
      ],
    );
    fixture.ports.reading = Completer<void>();
    final opened = <String>[];
    fixture.story.openInStory = (id) async => opened.add(id);
    await _cards(tester, fixture);
    expect(_key('map-story-line-loading'), findsNothing);
    expect(_key('map-story-line-${storyEventId(1)}'), findsNothing);
    expect(find.text('Réplique scene_talk'), findsOneWidget);
    expect(fixture.ports.dialogueReads, isEmpty);
    await tester.tap(_key('map-interaction-trigger-open-${storyEventId(1)}'));
    await tester.pump();
    expect(opened, [storyEventId(1)]);
    expect(fixture.ports.dialogueReads, isEmpty);
    expect(fixture.story.dirty, isFalse);
  });

  testWidgets(
    'a scene-less draft offers completion without inventing content',
    (tester) async {
      final fixture = await openStory();
      expect(fixture.story.addBehaviour(storyElement(fixture)), isTrue);
      await _cards(tester, fixture);
      final created = fixture.story.selectedBehaviour!;
      expect(created.sceneId, isNull);
      expect(find.text('Aucune scène choisie'), findsOneWidget);
      expect(find.text('Compléter dans Histoire'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(
        fixture.story.behaviours.project(fixture.maps.project!).scenes,
        hasLength(1),
      );
      expect(
        fixture.story.behaviours.project(fixture.maps.project!).dialogues,
        isEmpty,
      );
      expect(fixture.ports.dialogueReads, isEmpty);
    },
  );

  testWidgets(
    'removing a shared-line link preserves both scenes and the document',
    (tester) async {
      final fixture = await openStory(
        records: [storyRecord(1, sceneId: 'scene_talk')],
        scenes: [
          storyLineScene('scene_talk', 'shared'),
          storyLineScene('scene_other', 'shared'),
        ],
        dialogues: [
          storyLineDialogue('shared', ['Salut']),
        ],
      );
      await _cards(tester, fixture);
      final before = fixture.story.behaviours.project(fixture.maps.project!);
      await tester.tap(
        _key('map-interaction-trigger-actions-${storyEventId(1)}'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retirer le déclencheur'));
      await tester.pumpAndSettle();
      final after = fixture.story.behaviours.project(fixture.maps.project!);
      expect(after.scenes, before.scenes);
      expect(after.dialogues, before.dialogues);
      expect(fixture.ports.sources['shared']!.source, contains('Salut'));
      fixture.story.undo();
      await tester.pump();
      expect(storyCurrent(fixture, storyEventId(1)).sceneId, 'scene_talk');
      expect(fixture.story.dirty, isFalse);
    },
  );
}
