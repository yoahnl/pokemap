import 'package:avelune_studio/features/events/application/behaviour/behaviour_reuse.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_catalog_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_story_catalog_support.dart';
import 'map_builder_story_support.dart';
import '../game_behaviours/game_behaviour_edit_support.dart';

void main() {
  test('contextual creation persists one inactive event without reading another map', () async {
    final operations = <String>{};
    final opened = await openStoryCatalog(
      unrelated: 400,
      faultInjector: (context) {
        operations.add(context.operationId);
      },
    );
    final loader = BehaviourMapLoader();
    final catalog = MapBuilderStoryCatalogBinding(
      story: opened.story,
      maps: loader,
      changed: () {},
    );
    addTearDown(catalog.dispose);
    expect(await catalog.prepareCreation('bourg'), isTrue);
    final editor = catalog.editor!;
    final source = editor.elements!.byKey('entity:guide-0')!;
    editor.select(source);
    expect(editor.addBehaviour(source), isTrue);
    final created = editor.selectedBehaviour!;
    expect(created.enabledOrNull, isNot(true));
    expect(created.sceneId, isNull);
    expect(loader.reads, isEmpty);
    expect(
      await opened.story.publish(storyEvents(opened.story, opened.port)),
      isTrue,
      reason: opened.story.error,
    );
    expect(operations, hasLength(1));
    final reopened = MapWorkspaceController(
      opened.session,
      LocalMapWorkspaceAdapter(),
    );
    addTearDown(reopened.dispose);
    await reopened.initialize();
    final persisted = reopened.project!.eventRegistry!.records.singleWhere(
      (record) => record.id == created.id,
    );
    expect(persisted, created);
    expect(reopened.project!.eventRegistry!.records, hasLength(402));
  });
  test(
    'a saved behaviour leaves nothing unsaved on a working catalog',
    () async {
      final opened = await openStoryCatalog();
      final story = opened.story;
      final maps = opened.maps;
      final record = maps.project!.eventRegistry!.records.single;

      expect(story.setAfter(record, BehaviourAfter.eachTime), isTrue);
      expect(story.dirty, isTrue);
      final saved = await story.publish(storyEvents(story, opened.port));
      expect(saved, isTrue, reason: story.error);

      expect(story.dirty, isFalse);
      expect(story.behaviours.changes(maps.project!), isEmpty);
      expect(
        maps
            .project!
            .eventRegistry!
            .records
            .single
            .definitionOrNull
            ?.reusePolicy,
        NarrativeEventReusePolicy.reusable,
      );
      expect(maps.project!.scenes.map((scene) => scene.id).toSet(), {
        'talk',
        'elsewhere',
      });

      final reopened = MapWorkspaceController(
        opened.session,
        LocalMapWorkspaceAdapter(),
      );
      addTearDown(reopened.dispose);
      await reopened.initialize();
      expect(
        reopened
            .project!
            .eventRegistry!
            .records
            .single
            .definitionOrNull
            ?.reusePolicy,
        NarrativeEventReusePolicy.reusable,
      );
    },
  );

  test(
    'saving a behaviour without a scene keeps the scenes in memory',
    () async {
      final opened = await openStoryCatalog();
      final maps = opened.maps;
      final before = maps.project!;
      expect(before.scenes, hasLength(2));
      final draft = NarrativeEventRecord.draft(
        NarrativeEventDraft(
          id: 'evt_019abcde-0000-7000-8000-0000000000a2',
          name: 'Brouillon',
          conditions: const [],
          priority: 0,
          order: 1,
        ),
      );

      final receipt = await opened.port.publishEvent(
        id: draft.id,
        base: null,
        current: draft,
      );
      maps.acceptResources(before, receipt.manifest);

      expect(maps.project!.scenes.map((scene) => scene.id).toSet(), {
        'talk',
        'elsewhere',
      });
      expect(
        maps.project!.eventRegistry!.records.map((record) => record.id),
        containsAll([catalogFirstEventId, draft.id]),
      );
    },
  );

  test(
    'one save publishes every changed behaviour in one transaction',
    () async {
      for (final count in [1, 20]) {
        final operations = <String>{};
        final promoted = <String>[];
        final opened = await openStoryCatalog(
          guides: 20,
          unrelated: 400,
          faultInjector: (context) {
            operations.add(context.operationId);
            if (context.storageKey case final key?) promoted.add(key);
          },
        );
        final story = opened.story;
        final project = opened.maps.project!;
        final records = [
          for (final record in project.eventRegistry!.records)
            if (record.definitionOrNull != null) record,
        ].take(count);
        for (final record in records) {
          expect(story.setAfter(record, BehaviourAfter.eachTime), isTrue);
        }
        expect(story.behaviours.changes(project), hasLength(count));
        final saved = await story.publish(storyEvents(story, opened.port));
        expect(saved, isTrue, reason: story.error);

        expect(story.dirty, isFalse);
        expect(operations, hasLength(1), reason: '$count behaviours');
        expect(promoted.where((key) => key.startsWith('maps/')), isEmpty);
        expect(
          opened.maps.project!.eventRegistry!.records.where(
            (record) =>
                record.definitionOrNull?.reusePolicy ==
                NarrativeEventReusePolicy.reusable,
          ),
          hasLength(count),
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
