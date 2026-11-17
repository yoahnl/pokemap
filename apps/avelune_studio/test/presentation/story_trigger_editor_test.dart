import 'dart:convert';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_catalog_port.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_port.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';

import 'map_builder_story_support.dart';
import 'story_trigger_support.dart';
import '../dialogues/dialogue_catalog_support.dart';

void main() {
  for (final occupied in [false, true]) {
    testWidgets(
      'central source move preserves selection through undo and redo (occupied: $occupied)',
      (tester) async {
        final fixture = await centralTriggerFixture(
          await openStory(
            records: [
              storyRecord(1),
              if (occupied)
                storyRecord(
                  2,
                  order: 1,
                  source: NarrativeEventSourceRef.entityInteract('a', 'other'),
                ),
            ],
            entities: [
              storyLuth,
              storyLuth.copyWith(id: 'other', name: 'Autre guide'),
            ],
          ),
          storyEventId(1),
        );
        await pumpTrigger(tester, fixture);
        tester
            .widget<StudioSelect>(triggerKey('story-trigger-source'))
            .onChanged!('entity:other');
        await tester.pump();
        fixture.story.undo();
        await tester.pump();
        expect(fixture.story.selected?.id, 'luth');
        expect(fixture.story.selectedBehaviour?.id, storyEventId(1));
        fixture.story.redo();
        await tester.pump();
        expect(fixture.story.selected?.id, 'other');
        expect(fixture.story.selectedBehaviour?.id, storyEventId(1));
      },
    );
  }
  testWidgets(
    'moving to a conflicting source explains the preserved disabled edit',
    (tester) async {
      final fixture = await openStory(
        records: [
          storyRecord(1),
          storyRecord(
            2,
            source: NarrativeEventSourceRef.entityInteract('a', 'other'),
          ),
        ],
        entities: [
          storyLuth,
          storyLuth.copyWith(id: 'other', name: 'Autre guide'),
        ],
      );
      await pumpTrigger(tester, fixture);
      tester
          .widget<StudioSelect>(triggerKey('story-trigger-source'))
          .onChanged!('entity:other');
      await tester.pump();
      expect(storyCurrent(fixture, storyEventId(1)).enabledOrNull, isFalse);
      expect(storyCurrent(fixture, storyEventId(2)).enabledOrNull, isTrue);
      expect(find.textContaining('désactivé'), findsWidgets);
      expect(fixture.story.repairError, isNotNull);
    },
  );
  testWidgets(
    'localized shared dialogue previews source, translation and configured fallback',
    (tester) async {
      final document = catalogDialogue('shared');
      final fixture = await openStory(
        records: [storyRecord(1, sceneId: 'line')],
        scenes: [
          storyLineScene('line', 'shared'),
          storyLineScene('other', 'shared'),
        ],
        dialogues: [
          DialogueSourceSnapshot(
            entry: document.entry,
            source: document.source,
            revision: document.revision!,
          ),
        ],
      );
      String? opened;
      var available = false;
      var fallback = 'en';
      var reads = 0;
      await pumpTrigger(
        tester,
        fixture,
        loadLanguages: () async {
          reads++;
          if (!available) throw StateError('temporary profile failure');
          return DialogueCatalogLanguages(
            locales: ['fr', 'en', 'es'],
            fallback: fallback,
          );
        },
        openDialogue: (id) async {
          opened = id;
        },
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Les langues du jeu sont indisponibles'),
        findsOneWidget,
      );
      available = true;
      tester
          .widget<StudioButton>(triggerKey('story-trigger-preview-refresh'))
          .onPressed!();
      await tester.pumpAndSettle();
      expect(find.text('Bonjour le monde.'), findsOneWidget);
      tester
          .widget<StudioSelect>(triggerKey('story-trigger-preview-language'))
          .onChanged!('en');
      await tester.pump();
      expect(find.text('Hello world.'), findsOneWidget);
      tester
          .widget<StudioSelect>(triggerKey('story-trigger-preview-language'))
          .onChanged!('es');
      await tester.pump();
      expect(find.text('Hello world.'), findsOneWidget);
      expect(find.text('Repli : EN'), findsOneWidget);
      fallback = 'fr';
      tester
          .widget<StudioButton>(triggerKey('story-trigger-preview-refresh'))
          .onPressed!();
      await tester.pumpAndSettle();
      expect(find.text('Bonjour le monde.'), findsOneWidget);
      expect(find.text('Repli : FR'), findsOneWidget);
      expect(reads, 3);
      final link = triggerKey('story-open-dialogue-shared');
      await tester.ensureVisible(link);
      await tester.tap(link);
      expect(opened, 'shared');
      expect(fixture.story.dirty, isFalse);
    },
  );

  testWidgets(
    'creating a simple scene stages scene, dialogue and association atomically',
    (tester) async {
      final fixture = await openStory();
      await fixture.story.prepare();
      fixture.story.addBehaviour(storyElement(fixture));
      await pumpTrigger(tester, fixture);
      final create = triggerKey('story-trigger-scene-create');
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      final field = find.descendant(
        of: triggerKey('story-trigger-scene-text'),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, 'Bienvenue dans cette scène.');
      await tester.pump();
      await tester.tap(triggerKey('story-trigger-scene-confirm'));
      await tester.pumpAndSettle();
      final record = fixture.story.selectedBehaviour!;
      final scene = fixture.story.sceneOf(record.sceneId!)!;
      expect(scene.graph.nodes.map((node) => node.kind), [
        SceneNodeKind.start,
        SceneNodeKind.yarnDialogue,
        SceneNodeKind.end,
      ]);
      final line = fixture.story.lineOf(record).line!;
      final identified = readLocalizedDialogue(
        source: line.dialogue.source,
        sourceLocale: 'fr',
      );
      expect(identified.localization.units.single.id, isNotEmpty);
      expect(
        identified.localization.units.single.source,
        'Bienvenue dans cette scène.',
      );
      expect(fixture.maps.project!.scenes, hasLength(1));
      expect(fixture.maps.project!.dialogues, isEmpty);
      fixture.story.undo();
      expect(fixture.story.selectedBehaviour!.sceneId, isNull);
      fixture.story.redo();
      expect(fixture.story.selectedBehaviour!.sceneId, scene.id);
      expect(
        fixture.story.lineOf(fixture.story.selectedBehaviour!).line!.dialogueId,
        line.dialogueId,
      );
    },
  );
  testWidgets('ALORS always selects a scene and previews its text read only', (
    tester,
  ) async {
    final fixture = await openStory(
      records: [storyRecord(1, sceneId: 'line')],
      scenes: [storyLineScene('line', 'welcome')],
      dialogues: [
        storyLineDialogue('welcome', ['Bienvenue !']),
      ],
    );
    await pumpTrigger(tester, fixture);
    await tester.pumpAndSettle();
    expect(triggerKey('map-story-then'), findsOneWidget);
    expect(triggerKey('map-story-line-${storyEventId(1)}'), findsNothing);
    expect(find.text('Bienvenue !'), findsOneWidget);
    expect(triggerKey('story-trigger-preview-language'), findsOneWidget);
    final before = storyCurrent(fixture, storyEventId(1));
    tester.widget<StudioSelect>(triggerKey('map-story-then')).onChanged!(
      'scene-plain',
    );
    await tester.pump();
    final after = storyCurrent(fixture, before.id);
    final expected =
        jsonDecode(jsonEncode(before.toJson())) as Map<String, dynamic>;
    (expected['definition'] as Map<String, dynamic>)['sceneId'] = 'scene-plain';
    expect(after.toJson(), expected);
    expect(find.text('Bienvenue !'), findsNothing);
    expect(fixture.story.behaviours.draft.touchedRefs, hasLength(1));
  });

  testWidgets(
    'simple OR is editable and scene changes preserve nested conditions',
    (tester) async {
      final expression = NarrativeEventConditionExpression.any([
        NarrativeEventConditionExpression.leaf(
          NarrativeEventCondition.fact('met', true),
        ),
        NarrativeEventConditionExpression.leaf(
          NarrativeEventCondition.fact('gate', false),
        ),
      ]);
      final fixture = await openStory(
        records: [storyRecord(1, expression: expression)],
        facts: [
          NarrativeFactDefinition(id: 'met', label: 'Rencontré'),
          NarrativeFactDefinition(id: 'gate', label: 'Porte ouverte'),
        ],
      );
      await pumpTrigger(tester, fixture);
      final junction = tester.widget<StudioSelect>(
        triggerKey('map-story-condition-junction'),
      );
      expect(junction.value, 'any');
      junction.onChanged!('all');
      await tester.pump();
      expect(
        storyCurrent(fixture, storyEventId(1)).expression,
        isA<NarrativeEventConditionAll>(),
      );
      fixture.story.undo();
      expect(storyCurrent(fixture, storyEventId(1)).expression, expression);
    },
  );

  testWidgets(
    'QUAND offers real carriers and retains the selected event after a move',
    (tester) async {
      final fixture = await openStory(
        records: [storyRecord(1)],
        entities: [
          storyLuth,
          storyLuth.copyWith(id: 'other', name: 'Autre guide'),
        ],
      );
      await pumpTrigger(tester, fixture);
      final source = tester.widget<StudioSelect>(
        triggerKey('story-trigger-source'),
      );
      expect(source.options.values, contains('Autre guide'));
      source.onChanged!('entity:other');
      await tester.pump();
      expect(fixture.story.selectedBehaviour?.id, storyEventId(1));
      expect(
        fixture.story.selectedBehaviour?.source,
        NarrativeEventSourceRef.entityInteract('a', 'other'),
      );
      expect(triggerKey('story-trigger-block-then'), findsOneWidget);
    },
  );
}
