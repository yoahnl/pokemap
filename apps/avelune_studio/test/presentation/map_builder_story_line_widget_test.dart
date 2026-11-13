import 'dart:async';

import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'map_builder_story_support.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _type(WidgetTester tester, Finder field, String text) async {
  await tester.enterText(field, text);
  await tester.pump();
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
}

void main() {
  testWidgets('a line is read in the background, then edited in place', (
    tester,
  ) async {
    final fixture = await openStory(
      records: [storyRecord(1, sceneId: 'scene_talk')],
      scenes: [storyLineScene('scene_talk', 'dialogue_talk')],
      dialogues: [
        storyLineDialogue('dialogue_talk', ['Salut']),
      ],
    );
    final reading = fixture.ports.reading = Completer<void>();
    await pumpStoryInspector(tester, fixture);
    expect(_key('map-story-line-loading'), findsOneWidget);
    expect(find.text('Lecture de la réplique…'), findsOneWidget);

    reading.complete();
    await tester.pumpAndSettle();
    final field = _key('map-story-line-${storyEventId(1)}');
    expect(field, findsOneWidget);
    expect(find.text('Ce personnage dit…'), findsOneWidget);
    expect(_key('map-story-then'), findsNothing);
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: field, matching: find.byType(TextField)),
          )
          .controller!
          .text,
      'Salut',
    );

    await _type(
      tester,
      find.descendant(of: field, matching: find.byType(TextField)),
      'Bonne route !',
    );

    expect(
      [...fixture.story.behaviours.draft.touched(StoryDraftKind.dialogue)],
      ['dialogue_talk'],
    );
    final record = storyCurrent(fixture, storyEventId(1));
    expect(fixture.story.lineOf(record).text, 'Bonne route !');
  });

  testWidgets('a behaviour without a scene offers the field and the picker', (
    tester,
  ) async {
    final fixture = await openStory();
    expect(fixture.story.addBehaviour(storyElement(fixture)), isTrue);
    await pumpStoryInspector(tester, fixture);
    final created = fixture.story.selectedBehaviour!;
    expect(created.sceneId, isNull);
    final field = find.descendant(
      of: _key('map-story-line-${created.id}'),
      matching: find.byType(TextField),
    );
    expect(field, findsOneWidget);
    expect(_key('map-story-then'), findsOneWidget);
    expect(find.text('Ou lancer une scène'), findsOneWidget);

    await _type(tester, field, 'Bienvenue au bourg.');

    final linked = storyCurrent(fixture, created.id);
    expect(linked.sceneId, isNotNull);
    expect(fixture.story.lineOf(linked).state, MapStoryLineState.line);
    expect(_key('map-story-then'), findsNothing);
    expect(_key('map-story-line-${created.id}'), findsOneWidget);
  });

  testWidgets('a shared line warns and offers to detach it', (tester) async {
    final fixture = await openStory(
      records: [storyRecord(1, sceneId: 'scene_talk')],
      scenes: [
        storyLineScene('scene_talk', 'dialogue_talk'),
        storyLineScene('scene_other', 'dialogue_talk'),
      ],
      dialogues: [
        storyLineDialogue('dialogue_talk', ['Salut']),
      ],
    );
    await pumpStoryInspector(tester, fixture);
    await tester.pump();

    expect(_key('map-story-line-shared'), findsOneWidget);
    expect(find.textContaining('Réplique scene_other'), findsOneWidget);
    expect(_key('map-story-line-${storyEventId(1)}'), findsNothing);

    await tester.tap(_key('map-story-line-detach'));
    await tester.pump();

    expect(_key('map-story-line-shared'), findsNothing);
    expect(_key('map-story-line-${storyEventId(1)}'), findsOneWidget);
    expect(
      [...fixture.story.behaviours.draft.touched(StoryDraftKind.scene)],
      ['scene_talk'],
    );
  });
}
