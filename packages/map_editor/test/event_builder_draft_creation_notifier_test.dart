import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('NS-EVENT-08 EditorNotifier draft event creation', () {
    test('prepares a default object layer when a real imported map has none',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        activeMap: _mapWithoutObjectLayer(),
        activeLayerId: 'ground',
      );

      final layerId = notifier.ensureEventBuilderObjectLayer();

      final state = container.read(editorNotifierProvider);
      final layer = state.activeMap!.layers.whereType<ObjectLayer>().single;
      expect(layerId, layer.id);
      expect(layer.name, 'Événements');
      expect(state.activeLayerId, layer.id);
      expect(state.selectedMapEventId, isNull);
      expect(state.activeMap!.events, isEmpty);
      expect(state.statusMessage, 'Couche d’événements créée');
      expect(state.errorMessage, isNull);
    });

    test('creates a draft event from an explicit position and valid layer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        activeMap: _map(),
        activeLayerId: 'objects',
      );

      final created = notifier.createEventBuilderDraftEventAt(
        position: const EventPosition(layerId: 'objects', x: 2, y: 1),
      );

      final state = container.read(editorNotifierProvider);
      final events = state.activeMap!.events;
      expect(created, isNotNull);
      expect(events.map((event) => event.id), [
        'evt_existing',
        'evt_nouvel_evenement',
      ]);
      expect(state.selectedMapEventId, 'evt_nouvel_evenement');
      expect(state.statusMessage, 'Brouillon d’événement créé');

      final draft = events.last;
      expect(draft.title, 'Nouvel événement');
      expect(
          draft.position, const EventPosition(layerId: 'objects', x: 2, y: 1));
      expect(draft.pages, hasLength(1));
      expect(draft.pages.single.sceneTarget, isNull);
      expect(draft.pages.single.script, isNull);
      expect(draft.pages.single.message, isNull);
      expect(draft.pages.single.condition, isNull);
    });

    test('rejects an invalid layer without falling back to the first layer',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        activeMap: _map(),
        activeLayerId: 'objects',
      );

      final created = notifier.createEventBuilderDraftEventAt(
        position: const EventPosition(layerId: 'missing', x: 1, y: 1),
      );

      final state = container.read(editorNotifierProvider);
      expect(created, isNull);
      expect(
          state.activeMap!.events.map((event) => event.id), ['evt_existing']);
      expect(state.selectedMapEventId, isNull);
      expect(
        state.errorMessage,
        'Couche de destination introuvable pour l’événement : missing',
      );
    });
  });

  group('NS-EVENT-10 EditorNotifier event title authoring', () {
    test('renames the human title without changing the technical id or page',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        activeMap: _map(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );
      final original = notifier.state.activeMap!.events.single;
      final originalPage = original.pages.single;

      final renamed = notifier.renameEventBuilderEventTitle(
        eventId: 'evt_existing',
        title: '  Rencontre rival au port  ',
      );

      final state = container.read(editorNotifierProvider);
      final event = state.activeMap!.events.single;
      expect(state.errorMessage, isNull);
      expect(renamed, isTrue);
      expect(event.id, 'evt_existing');
      expect(event.title, 'Rencontre rival au port');
      expect(event.position, original.position);
      expect(event.type, original.type);
      expect(event.metadata, original.metadata);
      expect(event.pages, hasLength(1));
      expect(event.pages.single.sceneTarget, originalPage.sceneTarget);
      expect(event.pages.single.script, originalPage.script);
      expect(event.pages.single.message, originalPage.message);
      expect(event.pages.single.condition, originalPage.condition);
      expect(state.selectedMapEventId, 'evt_existing');
      expect(state.statusMessage, 'Événement renommé');
    });

    test('rejects an empty title without mutating the event', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        activeMap: _map(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );

      final renamed = notifier.renameEventBuilderEventTitle(
        eventId: 'evt_existing',
        title: '   ',
      );

      final state = container.read(editorNotifierProvider);
      final event = state.activeMap!.events.single;
      expect(renamed, isFalse);
      expect(event.id, 'evt_existing');
      expect(event.title, 'Événement existant');
      expect(state.selectedMapEventId, 'evt_existing');
      expect(state.errorMessage, 'Titre d’événement obligatoire.');
    });

    test('rejects an unknown event without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        activeMap: _map(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );

      final renamed = notifier.renameEventBuilderEventTitle(
        eventId: 'missing_event',
        title: 'Rencontre rival au port',
      );

      final state = container.read(editorNotifierProvider);
      expect(renamed, isFalse);
      expect(state.activeMap!.events.single.title, 'Événement existant');
      expect(state.selectedMapEventId, 'evt_existing');
      expect(state.errorMessage, 'Événement introuvable : missing_event');
    });
  });

  group('NS-EVENT-11 EditorNotifier scene action authoring', () {
    test('writes the scene target on the lowest page without changing identity',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _projectWithScenes(),
        activeMap: _mapForSceneAction(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );
      final original = notifier.state.activeMap!.events.single;
      final originalLowestPage =
          original.pages.singleWhere((page) => page.pageNumber == 2);
      final originalHigherPage =
          original.pages.singleWhere((page) => page.pageNumber == 4);

      final updated = notifier.updateEventBuilderEventSceneAction(
        eventId: 'evt_existing',
        sceneId: '  scene_rival  ',
      );

      final state = container.read(editorNotifierProvider);
      final event = state.activeMap!.events.single;
      final lowestPage =
          event.pages.singleWhere((page) => page.pageNumber == 2);
      final higherPage =
          event.pages.singleWhere((page) => page.pageNumber == 4);
      expect(state.errorMessage, isNull);
      expect(updated, isTrue);
      expect(event.id, original.id);
      expect(event.title, original.title);
      expect(event.position, original.position);
      expect(event.type, original.type);
      expect(event.metadata, original.metadata);
      expect(lowestPage.sceneTarget?.sceneId, 'scene_rival');
      expect(lowestPage.condition, originalLowestPage.condition);
      expect(lowestPage.script, originalLowestPage.script);
      expect(lowestPage.message, originalLowestPage.message);
      expect(lowestPage.metadata, originalLowestPage.metadata);
      expect(higherPage.sceneTarget, originalHigherPage.sceneTarget);
      expect(state.selectedMapEventId, 'evt_existing');
      expect(state.statusMessage, 'Scène d’événement mise à jour');
    });

    test('rejects an empty scene id without mutating the event', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _projectWithScenes(),
        activeMap: _map(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );

      final updated = notifier.updateEventBuilderEventSceneAction(
        eventId: 'evt_existing',
        sceneId: '   ',
      );

      final state = container.read(editorNotifierProvider);
      expect(updated, isFalse);
      expect(state.activeMap!.events.single.pages.single.sceneTarget?.sceneId,
          'scene_existing');
      expect(state.selectedMapEventId, 'evt_existing');
      expect(state.errorMessage, 'Scène d’événement obligatoire.');
    });

    test('rejects an unknown scene without mutating the event', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _projectWithScenes(),
        activeMap: _map(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );

      final updated = notifier.updateEventBuilderEventSceneAction(
        eventId: 'evt_existing',
        sceneId: 'scene_missing',
      );

      final state = container.read(editorNotifierProvider);
      expect(updated, isFalse);
      expect(state.activeMap!.events.single.pages.single.sceneTarget?.sceneId,
          'scene_existing');
      expect(state.selectedMapEventId, 'evt_existing');
      expect(state.errorMessage, 'Scène introuvable : scene_missing');
    });

    test('rejects an unknown event without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _projectWithScenes(),
        activeMap: _map(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );

      final updated = notifier.updateEventBuilderEventSceneAction(
        eventId: 'missing_event',
        sceneId: 'scene_rival',
      );

      final state = container.read(editorNotifierProvider);
      expect(updated, isFalse);
      expect(state.activeMap!.events.single.pages.single.sceneTarget?.sceneId,
          'scene_existing');
      expect(state.selectedMapEventId, 'evt_existing');
      expect(state.errorMessage, 'Événement introuvable : missing_event');
    });

    test('rejects an event without page without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _projectWithScenes(),
        activeMap: _mapWithoutEventPages(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_empty',
      );

      final updated = notifier.updateEventBuilderEventSceneAction(
        eventId: 'evt_empty',
        sceneId: 'scene_rival',
      );

      final state = container.read(editorNotifierProvider);
      expect(updated, isFalse);
      expect(state.activeMap!.events.single.pages, isEmpty);
      expect(state.selectedMapEventId, 'evt_empty');
      expect(
        state.errorMessage,
        'Cet événement ne contient aucune page authorable.',
      );
    });
  });

  group('NS-EVENT-12 EditorNotifier behavior authoring', () {
    test('updates reuse policy metadata on the lowest page only', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        activeMap: _mapForBehaviorAuthoring(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );
      final original = notifier.state.activeMap!.events.single;
      final originalLowestPage =
          original.pages.singleWhere((page) => page.pageNumber == 2);
      final originalHigherPage =
          original.pages.singleWhere((page) => page.pageNumber == 4);

      final updatedToReusable = notifier.updateEventBuilderEventReusePolicy(
        eventId: 'evt_existing',
        reusePolicy: EventBuilderReusePolicy.reusable,
      );

      var state = container.read(editorNotifierProvider);
      var event = state.activeMap!.events.single;
      var lowestPage = event.pages.singleWhere((page) => page.pageNumber == 2);
      var higherPage = event.pages.singleWhere((page) => page.pageNumber == 4);
      expect(state.errorMessage, isNull);
      expect(updatedToReusable, isTrue);
      expect(event.id, original.id);
      expect(event.title, original.title);
      expect(event.position, original.position);
      expect(event.type, original.type);
      expect(event.metadata, original.metadata);
      expect(lowestPage.sceneTarget, originalLowestPage.sceneTarget);
      expect(lowestPage.condition, originalLowestPage.condition);
      expect(lowestPage.script, originalLowestPage.script);
      expect(lowestPage.message, originalLowestPage.message);
      expect(lowestPage.isDisabled, originalLowestPage.isDisabled);
      expect(lowestPage.isHidden, originalLowestPage.isHidden);
      expect(lowestPage.metadata['legacyKey'], 'legacyValue');
      expect(
        lowestPage.metadata[EventBuilderMetadataKeys.schemaVersion],
        EventBuilderMetadataKeys.currentSchemaVersion,
      );
      expect(
        lowestPage.metadata[EventBuilderMetadataKeys.reusePolicy],
        EventBuilderReusePolicy.reusable.name,
      );
      expect(higherPage, originalHigherPage);
      expect(state.selectedMapEventId, 'evt_existing');
      expect(state.statusMessage, 'Comportement d’événement mis à jour');

      final updatedToOneShot = notifier.updateEventBuilderEventReusePolicy(
        eventId: 'evt_existing',
        reusePolicy: EventBuilderReusePolicy.oneShot,
      );

      state = container.read(editorNotifierProvider);
      event = state.activeMap!.events.single;
      lowestPage = event.pages.singleWhere((page) => page.pageNumber == 2);
      higherPage = event.pages.singleWhere((page) => page.pageNumber == 4);
      expect(updatedToOneShot, isTrue);
      expect(
        lowestPage.metadata[EventBuilderMetadataKeys.reusePolicy],
        EventBuilderReusePolicy.oneShot.name,
      );
      expect(
        lowestPage.metadata[EventBuilderMetadataKeys.schemaVersion],
        EventBuilderMetadataKeys.currentSchemaVersion,
      );
      expect(lowestPage.metadata['legacyKey'], 'legacyValue');
      expect(lowestPage.sceneTarget, originalLowestPage.sceneTarget);
      expect(lowestPage.condition, originalLowestPage.condition);
      expect(lowestPage.script, originalLowestPage.script);
      expect(lowestPage.message, originalLowestPage.message);
      expect(higherPage, originalHigherPage);
      expect(state.selectedMapEventId, 'evt_existing');
    });

    test('rejects an unknown event without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        activeMap: _mapForBehaviorAuthoring(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );

      final updated = notifier.updateEventBuilderEventReusePolicy(
        eventId: 'missing_event',
        reusePolicy: EventBuilderReusePolicy.reusable,
      );

      final state = container.read(editorNotifierProvider);
      final event = state.activeMap!.events.single;
      final lowestPage =
          event.pages.singleWhere((page) => page.pageNumber == 2);
      expect(updated, isFalse);
      expect(
        lowestPage.metadata[EventBuilderMetadataKeys.reusePolicy],
        EventBuilderReusePolicy.oneShot.name,
      );
      expect(state.selectedMapEventId, 'evt_existing');
      expect(state.errorMessage, 'Événement introuvable : missing_event');
    });

    test('rejects an event without page without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        activeMap: _mapWithoutEventPages(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_empty',
      );

      final updated = notifier.updateEventBuilderEventReusePolicy(
        eventId: 'evt_empty',
        reusePolicy: EventBuilderReusePolicy.reusable,
      );

      final state = container.read(editorNotifierProvider);
      expect(updated, isFalse);
      expect(state.activeMap!.events.single.pages, isEmpty);
      expect(state.selectedMapEventId, 'evt_empty');
      expect(
        state.errorMessage,
        'Cet événement ne contient aucune page authorable.',
      );
    });
  });

  group('NS-EVENT-13 EditorNotifier fact condition authoring', () {
    test('adds a true Fact condition without changing other event fields', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _projectWithFacts(),
        activeMap: _mapForFactConditions(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );
      final original = notifier.state.activeMap!.events.single;
      final originalLowestPage =
          original.pages.singleWhere((page) => page.pageNumber == 2);
      final originalHigherPage =
          original.pages.singleWhere((page) => page.pageNumber == 4);

      final added = notifier.addEventBuilderFactCondition(
        eventId: 'evt_existing',
        factId: '  fact_started  ',
        expectedValue: true,
      );

      final state = container.read(editorNotifierProvider);
      final event = state.activeMap!.events.single;
      final lowestPage =
          event.pages.singleWhere((page) => page.pageNumber == 2);
      final higherPage =
          event.pages.singleWhere((page) => page.pageNumber == 4);
      expect(state.errorMessage, isNull);
      expect(added, isTrue);
      expect(event.id, original.id);
      expect(event.title, original.title);
      expect(event.position, original.position);
      expect(event.type, original.type);
      expect(event.metadata, original.metadata);
      expect(lowestPage.condition,
          ScriptConditionFactory.flagIsSet('fact_started'));
      expect(lowestPage.sceneTarget, originalLowestPage.sceneTarget);
      expect(lowestPage.script, originalLowestPage.script);
      expect(lowestPage.message, originalLowestPage.message);
      expect(lowestPage.metadata, originalLowestPage.metadata);
      expect(higherPage, originalHigherPage);
      expect(state.selectedMapEventId, 'evt_existing');
      expect(state.statusMessage, 'Condition d’événement ajoutée');
    });

    test('adds false Fact conditions and compiles multiple conditions as allOf',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _projectWithFacts(),
        activeMap: _mapForFactConditions(
          condition: ScriptConditionFactory.flagIsSet('fact_started'),
        ),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );

      final added = notifier.addEventBuilderFactCondition(
        eventId: 'evt_existing',
        factId: 'fact_blocked',
        expectedValue: false,
      );

      final state = container.read(editorNotifierProvider);
      final condition = state.activeMap!.events.single.pages
          .singleWhere((page) => page.pageNumber == 2)
          .condition;
      expect(added, isTrue);
      expect(condition?.type, ScriptConditionType.allOf);
      expect(condition?.children, [
        ScriptConditionFactory.flagIsSet('fact_started'),
        ScriptConditionFactory.flagIsUnset('fact_blocked'),
      ]);
      expect(state.selectedMapEventId, 'evt_existing');
    });

    test('removes conditions and clears the page condition when none remain',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _projectWithFacts(),
        activeMap: _mapForFactConditions(
          condition: ScriptConditionFactory.allOf([
            ScriptConditionFactory.flagIsSet('fact_started'),
            ScriptConditionFactory.flagIsUnset('fact_blocked'),
          ]),
        ),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );

      final removedFirst = notifier.removeEventBuilderConditionAt(
        eventId: 'evt_existing',
        conditionIndex: 0,
      );

      var state = container.read(editorNotifierProvider);
      var page = state.activeMap!.events.single.pages
          .singleWhere((candidate) => candidate.pageNumber == 2);
      expect(removedFirst, isTrue);
      expect(
          page.condition, ScriptConditionFactory.flagIsUnset('fact_blocked'));
      expect(page.sceneTarget?.sceneId, 'scene_rival');
      expect(page.script, const ScriptRef(scriptId: 'script_legacy'));
      expect(page.message, 'Message legacy');
      expect(page.metadata['legacyKey'], 'legacyValue');
      expect(state.selectedMapEventId, 'evt_existing');
      expect(state.statusMessage, 'Condition d’événement retirée');

      final removedLast = notifier.removeEventBuilderConditionAt(
        eventId: 'evt_existing',
        conditionIndex: 0,
      );

      state = container.read(editorNotifierProvider);
      page = state.activeMap!.events.single.pages
          .singleWhere((candidate) => candidate.pageNumber == 2);
      expect(removedLast, isTrue);
      expect(page.condition, isNull);
      expect(page.sceneTarget?.sceneId, 'scene_rival');
      expect(page.script, const ScriptRef(scriptId: 'script_legacy'));
      expect(page.message, 'Message legacy');
      expect(page.metadata['legacyKey'], 'legacyValue');
      expect(state.selectedMapEventId, 'evt_existing');
    });

    test('rejects empty or unknown facts without mutating the event', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _projectWithFacts(),
        activeMap: _mapForFactConditions(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );

      final empty = notifier.addEventBuilderFactCondition(
        eventId: 'evt_existing',
        factId: '   ',
        expectedValue: true,
      );
      final unknown = notifier.addEventBuilderFactCondition(
        eventId: 'evt_existing',
        factId: 'fact_missing',
        expectedValue: false,
      );

      final state = container.read(editorNotifierProvider);
      final page = state.activeMap!.events.single.pages
          .singleWhere((candidate) => candidate.pageNumber == 2);
      expect(empty, isFalse);
      expect(unknown, isFalse);
      expect(page.condition, isNull);
      expect(page.metadata['legacyKey'], 'legacyValue');
      expect(state.selectedMapEventId, 'evt_existing');
      expect(state.errorMessage, 'Fact introuvable : fact_missing');
    });

    test('rejects unknown events without pages and out of range removal', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _projectWithFacts(),
        activeMap: _mapForFactConditions(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );

      final unknownEvent = notifier.addEventBuilderFactCondition(
        eventId: 'missing_event',
        factId: 'fact_started',
        expectedValue: true,
      );
      final outOfRange = notifier.removeEventBuilderConditionAt(
        eventId: 'evt_existing',
        conditionIndex: 4,
      );

      notifier.state = notifier.state.copyWith(
        activeMap: _mapWithoutEventPages(),
        selectedMapEventId: 'evt_empty',
      );
      final withoutPage = notifier.addEventBuilderFactCondition(
        eventId: 'evt_empty',
        factId: 'fact_started',
        expectedValue: true,
      );

      final state = container.read(editorNotifierProvider);
      expect(unknownEvent, isFalse);
      expect(outOfRange, isFalse);
      expect(withoutPage, isFalse);
      expect(state.activeMap!.events.single.pages, isEmpty);
      expect(state.selectedMapEventId, 'evt_empty');
      expect(
        state.errorMessage,
        'Cet événement ne contient aucune page authorable.',
      );
    });

    test('refuses to edit preserved legacy conditions', () {
      final legacyCondition = ScriptConditionFactory.allOf([
        ScriptConditionFactory.flagIsSet('fact_started'),
        ScriptConditionFactory.variableEqualsString('legacy_variable', 'yes'),
      ]);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _projectWithFacts(),
        activeMap: _mapForFactConditions(condition: legacyCondition),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );

      final added = notifier.addEventBuilderFactCondition(
        eventId: 'evt_existing',
        factId: 'fact_blocked',
        expectedValue: false,
      );
      final removed = notifier.removeEventBuilderConditionAt(
        eventId: 'evt_existing',
        conditionIndex: 0,
      );

      final state = container.read(editorNotifierProvider);
      final page = state.activeMap!.events.single.pages
          .singleWhere((candidate) => candidate.pageNumber == 2);
      expect(added, isFalse);
      expect(removed, isFalse);
      expect(page.condition, legacyCondition);
      expect(state.selectedMapEventId, 'evt_existing');
      expect(
        state.errorMessage,
        'Cette condition contient une partie avancée préservée. '
        'Elle ne peut pas être éditée partiellement.',
      );
    });
  });

  group('NS-EVENT-14 EditorNotifier event consumed condition authoring', () {
    test('adds an event consumed condition without changing other event fields',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _projectWithFacts(),
        activeMap: _mapForEventConsumedConditions(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );
      final original = notifier.state.activeMap!.events
          .singleWhere((event) => event.id == 'evt_existing');
      final originalTarget = notifier.state.activeMap!.events
          .singleWhere((event) => event.id == 'evt_rival');
      final originalLowestPage =
          original.pages.singleWhere((page) => page.pageNumber == 2);
      final originalHigherPage =
          original.pages.singleWhere((page) => page.pageNumber == 4);

      final added = notifier.addEventBuilderEventConsumedCondition(
        eventId: 'evt_existing',
        targetEventId: '  evt_rival  ',
        expectedConsumed: true,
      );

      final state = container.read(editorNotifierProvider);
      final event = state.activeMap!.events
          .singleWhere((candidate) => candidate.id == 'evt_existing');
      final target = state.activeMap!.events
          .singleWhere((candidate) => candidate.id == 'evt_rival');
      final lowestPage =
          event.pages.singleWhere((page) => page.pageNumber == 2);
      final higherPage =
          event.pages.singleWhere((page) => page.pageNumber == 4);
      expect(state.errorMessage, isNull);
      expect(added, isTrue);
      expect(event.id, original.id);
      expect(event.title, original.title);
      expect(event.position, original.position);
      expect(event.type, original.type);
      expect(event.metadata, original.metadata);
      expect(lowestPage.condition,
          ScriptConditionFactory.eventIsConsumed('evt_rival'));
      expect(lowestPage.sceneTarget, originalLowestPage.sceneTarget);
      expect(lowestPage.script, originalLowestPage.script);
      expect(lowestPage.message, originalLowestPage.message);
      expect(lowestPage.metadata, originalLowestPage.metadata);
      expect(higherPage, originalHigherPage);
      expect(target, originalTarget);
      expect(state.selectedMapEventId, 'evt_existing');
      expect(state.statusMessage, 'Condition d’événement ajoutée');
    });

    test('adds event not consumed and compiles mixed Fact and Event as allOf',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _projectWithFacts(),
        activeMap: _mapForEventConsumedConditions(
          condition: ScriptConditionFactory.flagIsSet('fact_started'),
        ),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );

      final added = notifier.addEventBuilderEventConsumedCondition(
        eventId: 'evt_existing',
        targetEventId: 'evt_rival',
        expectedConsumed: false,
      );

      final state = container.read(editorNotifierProvider);
      final condition = state.activeMap!.events
          .singleWhere((event) => event.id == 'evt_existing')
          .pages
          .singleWhere((page) => page.pageNumber == 2)
          .condition;
      expect(added, isTrue);
      expect(condition?.type, ScriptConditionType.allOf);
      expect(condition?.children, [
        ScriptConditionFactory.flagIsSet('fact_started'),
        ScriptConditionFactory.not(
          ScriptConditionFactory.eventIsConsumed('evt_rival'),
        ),
      ]);
      expect(state.selectedMapEventId, 'evt_existing');
    });

    test('removes event consumed conditions and clears the last condition', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _projectWithFacts(),
        activeMap: _mapForEventConsumedConditions(
          condition: ScriptConditionFactory.allOf([
            ScriptConditionFactory.eventIsConsumed('evt_rival'),
            ScriptConditionFactory.not(
              ScriptConditionFactory.eventIsConsumed('evt_guard'),
            ),
          ]),
        ),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );

      final removedFirst = notifier.removeEventBuilderConditionAt(
        eventId: 'evt_existing',
        conditionIndex: 0,
      );

      var state = container.read(editorNotifierProvider);
      var page = state.activeMap!.events
          .singleWhere((event) => event.id == 'evt_existing')
          .pages
          .singleWhere((candidate) => candidate.pageNumber == 2);
      expect(removedFirst, isTrue);
      expect(
        page.condition,
        ScriptConditionFactory.not(
          ScriptConditionFactory.eventIsConsumed('evt_guard'),
        ),
      );
      expect(page.sceneTarget?.sceneId, 'scene_rival');
      expect(page.script, const ScriptRef(scriptId: 'script_legacy'));
      expect(page.message, 'Message legacy');
      expect(page.metadata['legacyKey'], 'legacyValue');
      expect(state.selectedMapEventId, 'evt_existing');
      expect(state.statusMessage, 'Condition d’événement retirée');

      final removedLast = notifier.removeEventBuilderConditionAt(
        eventId: 'evt_existing',
        conditionIndex: 0,
      );

      state = container.read(editorNotifierProvider);
      page = state.activeMap!.events
          .singleWhere((event) => event.id == 'evt_existing')
          .pages
          .singleWhere((candidate) => candidate.pageNumber == 2);
      expect(removedLast, isTrue);
      expect(page.condition, isNull);
      expect(page.sceneTarget?.sceneId, 'scene_rival');
      expect(page.script, const ScriptRef(scriptId: 'script_legacy'));
      expect(page.message, 'Message legacy');
      expect(page.metadata['legacyKey'], 'legacyValue');
      expect(state.selectedMapEventId, 'evt_existing');
    });

    test('rejects empty unknown and self target events without mutating', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _projectWithFacts(),
        activeMap: _mapForEventConsumedConditions(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );

      final empty = notifier.addEventBuilderEventConsumedCondition(
        eventId: 'evt_existing',
        targetEventId: '   ',
        expectedConsumed: true,
      );
      final unknown = notifier.addEventBuilderEventConsumedCondition(
        eventId: 'evt_existing',
        targetEventId: 'evt_missing',
        expectedConsumed: false,
      );
      final self = notifier.addEventBuilderEventConsumedCondition(
        eventId: 'evt_existing',
        targetEventId: 'evt_existing',
        expectedConsumed: true,
      );

      final state = container.read(editorNotifierProvider);
      final page = state.activeMap!.events
          .singleWhere((event) => event.id == 'evt_existing')
          .pages
          .singleWhere((candidate) => candidate.pageNumber == 2);
      expect(empty, isFalse);
      expect(unknown, isFalse);
      expect(self, isFalse);
      expect(page.condition, isNull);
      expect(page.metadata['legacyKey'], 'legacyValue');
      expect(state.selectedMapEventId, 'evt_existing');
      expect(
        state.errorMessage,
        'Un événement ne peut pas se cibler lui-même dans ce lot.',
      );
    });

    test('rejects unknown source events without pages and bad indexes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _projectWithFacts(),
        activeMap: _mapForEventConsumedConditions(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );

      final unknownEvent = notifier.addEventBuilderEventConsumedCondition(
        eventId: 'missing_event',
        targetEventId: 'evt_rival',
        expectedConsumed: true,
      );
      final outOfRange = notifier.removeEventBuilderConditionAt(
        eventId: 'evt_existing',
        conditionIndex: 4,
      );

      notifier.state = notifier.state.copyWith(
        activeMap: _mapWithoutEventPages(),
        selectedMapEventId: 'evt_empty',
      );
      final withoutPage = notifier.addEventBuilderEventConsumedCondition(
        eventId: 'evt_empty',
        targetEventId: 'evt_rival',
        expectedConsumed: true,
      );

      final state = container.read(editorNotifierProvider);
      expect(unknownEvent, isFalse);
      expect(outOfRange, isFalse);
      expect(withoutPage, isFalse);
      expect(state.activeMap!.events.single.pages, isEmpty);
      expect(state.selectedMapEventId, 'evt_empty');
      expect(
        state.errorMessage,
        'Cet événement ne contient aucune page authorable.',
      );
    });

    test('refuses to edit preserved legacy conditions', () {
      final legacyCondition = ScriptConditionFactory.allOf([
        ScriptConditionFactory.eventIsConsumed('evt_rival'),
        ScriptConditionFactory.variableEqualsString('legacy_variable', 'yes'),
      ]);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _projectWithFacts(),
        activeMap: _mapForEventConsumedConditions(condition: legacyCondition),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );

      final added = notifier.addEventBuilderEventConsumedCondition(
        eventId: 'evt_existing',
        targetEventId: 'evt_guard',
        expectedConsumed: false,
      );
      final removed = notifier.removeEventBuilderConditionAt(
        eventId: 'evt_existing',
        conditionIndex: 0,
      );

      final state = container.read(editorNotifierProvider);
      final page = state.activeMap!.events
          .singleWhere((event) => event.id == 'evt_existing')
          .pages
          .singleWhere((candidate) => candidate.pageNumber == 2);
      expect(added, isFalse);
      expect(removed, isFalse);
      expect(page.condition, legacyCondition);
      expect(state.selectedMapEventId, 'evt_existing');
      expect(
        state.errorMessage,
        'Cette condition contient une partie avancée préservée. '
        'Elle ne peut pas être éditée partiellement.',
      );
    });
  });

  group('NS-EVENT-15 EditorNotifier trigger type authoring', () {
    test('updates actor object and triggerZone while preserving event fields',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        activeMap: _mapForTriggerTypeAuthoring(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );
      final original = notifier.state.activeMap!.events.single;
      final originalPages = original.pages;

      final toObject = notifier.updateEventBuilderTriggerType(
        eventId: 'evt_existing',
        type: MapEventType.object,
      );
      var state = container.read(editorNotifierProvider);
      var event = state.activeMap!.events.single;

      expect(toObject, isTrue);
      expect(event.type, MapEventType.object);
      expect(event.id, original.id);
      expect(event.title, original.title);
      expect(event.position, original.position);
      expect(event.metadata, original.metadata);
      expect(event.pages, originalPages);
      expect(event.pages.single.condition, originalPages.single.condition);
      expect(event.pages.single.sceneTarget, originalPages.single.sceneTarget);
      expect(event.pages.single.script, originalPages.single.script);
      expect(event.pages.single.message, originalPages.single.message);
      expect(event.pages.single.metadata, originalPages.single.metadata);
      expect(state.selectedMapEventId, 'evt_existing');
      expect(state.statusMessage, 'Déclencheur d’événement mis à jour');

      final toZone = notifier.updateEventBuilderTriggerType(
        eventId: 'evt_existing',
        type: MapEventType.triggerZone,
      );
      state = container.read(editorNotifierProvider);
      event = state.activeMap!.events.single;
      expect(toZone, isTrue);
      expect(event.type, MapEventType.triggerZone);
      expect(event.pages, originalPages);
      expect(state.selectedMapEventId, 'evt_existing');

      final toActor = notifier.updateEventBuilderTriggerType(
        eventId: 'evt_existing',
        type: MapEventType.actor,
      );
      state = container.read(editorNotifierProvider);
      event = state.activeMap!.events.single;
      expect(toActor, isTrue);
      expect(event.type, MapEventType.actor);
      expect(event.pages, originalPages);
      expect(state.selectedMapEventId, 'evt_existing');
    });

    test('rejects effect and unknown events without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        activeMap: _mapForTriggerTypeAuthoring(),
        activeLayerId: 'objects',
        selectedMapEventId: 'evt_existing',
      );
      final originalMap = notifier.state.activeMap;

      final effect = notifier.updateEventBuilderTriggerType(
        eventId: 'evt_existing',
        type: MapEventType.effect,
      );
      var state = container.read(editorNotifierProvider);
      expect(effect, isFalse);
      expect(state.activeMap, originalMap);
      expect(state.selectedMapEventId, 'evt_existing');
      expect(
        state.errorMessage,
        'Ce type de déclencheur n’est pas éditable dans ce lot.',
      );

      final unknown = notifier.updateEventBuilderTriggerType(
        eventId: 'missing_event',
        type: MapEventType.object,
      );
      state = container.read(editorNotifierProvider);
      expect(unknown, isFalse);
      expect(state.activeMap, originalMap);
      expect(state.selectedMapEventId, 'evt_existing');
      expect(state.errorMessage, 'Événement introuvable : missing_event');
    });
  });
}

ProjectManifest _projectWithScenes() {
  return ProjectManifest(
    name: 'Event Builder test',
    maps: const [
      ProjectMapEntry(
        id: 'map_port',
        name: 'Port Selbrume',
        relativePath: 'maps/port.json',
      ),
    ],
    tilesets: const [],
    scripts: const [
      ProjectScriptEntry(
        id: 'script_legacy',
        name: 'Script legacy',
        asset: ScriptAsset(
          id: 'script_legacy',
          nodes: [ScriptNode(id: 'start')],
        ),
      ),
    ],
    scenes: [
      _scene('scene_existing', 'Scène existante'),
      _scene('scene_rival', 'Rencontre rival'),
    ],
  );
}

ProjectManifest _projectWithFacts() {
  return ProjectManifest(
    name: 'Event Builder test',
    maps: const [
      ProjectMapEntry(
        id: 'map_port',
        name: 'Port Selbrume',
        relativePath: 'maps/port.json',
      ),
    ],
    tilesets: const [],
    scripts: const [
      ProjectScriptEntry(
        id: 'script_legacy',
        name: 'Script legacy',
        asset: ScriptAsset(
          id: 'script_legacy',
          nodes: [ScriptNode(id: 'start')],
        ),
      ),
    ],
    scenes: [
      _scene('scene_existing', 'Scène existante'),
      _scene('scene_rival', 'Rencontre rival'),
    ],
    facts: [
      NarrativeFactDefinition(
        id: 'fact_started',
        label: 'Départ accepté',
      ),
      NarrativeFactDefinition(
        id: 'fact_blocked',
        label: 'Rival battu',
      ),
    ],
  );
}

SceneAsset _scene(String id, String name) {
  return SceneAsset(
    id: id,
    name: name,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

MapData _map() {
  return const MapData(
    id: 'map_port',
    name: 'Port Selbrume',
    size: GridSize(width: 4, height: 3),
    layers: [
      MapLayer.tile(
        id: 'ground',
        name: 'Sol',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      MapLayer.object(id: 'objects', name: 'Objets'),
    ],
    events: [
      MapEventDefinition(
        id: 'evt_existing',
        title: 'Événement existant',
        position: EventPosition(layerId: 'objects', x: 0, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_existing'),
          ),
        ],
      ),
    ],
  );
}

MapData _mapForSceneAction() {
  return MapData(
    id: 'map_port',
    name: 'Port Selbrume',
    size: const GridSize(width: 4, height: 3),
    layers: const [
      MapLayer.tile(
        id: 'ground',
        name: 'Sol',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      MapLayer.object(id: 'objects', name: 'Objets'),
    ],
    events: [
      MapEventDefinition(
        id: 'evt_existing',
        title: 'Événement existant',
        position: const EventPosition(layerId: 'objects', x: 0, y: 0),
        metadata: {'scope': 'event'},
        pages: [
          const MapEventPage(
            pageNumber: 4,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_existing'),
          ),
          MapEventPage(
            pageNumber: 2,
            condition: ScriptConditionFactory.flagIsSet('fact_started'),
            script: const ScriptRef(scriptId: 'script_legacy'),
            message: 'Message legacy',
            metadata: {'reusePolicy': 'oneShot'},
          ),
        ],
      ),
    ],
  );
}

MapData _mapForBehaviorAuthoring() {
  return MapData(
    id: 'map_port',
    name: 'Port Selbrume',
    size: const GridSize(width: 4, height: 3),
    layers: const [
      MapLayer.tile(
        id: 'ground',
        name: 'Sol',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      MapLayer.object(id: 'objects', name: 'Objets'),
    ],
    events: [
      MapEventDefinition(
        id: 'evt_existing',
        title: 'Événement existant',
        position: const EventPosition(layerId: 'objects', x: 0, y: 0),
        metadata: {'scope': 'event'},
        pages: [
          const MapEventPage(
            pageNumber: 4,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_existing'),
            metadata: {'untouched': 'higher'},
          ),
          MapEventPage(
            pageNumber: 2,
            condition: ScriptConditionFactory.flagIsSet('fact_started'),
            script: const ScriptRef(scriptId: 'script_legacy'),
            message: 'Message legacy',
            sceneTarget: const MapEventSceneTarget(sceneId: 'scene_rival'),
            metadata: const {
              'legacyKey': 'legacyValue',
              EventBuilderMetadataKeys.reusePolicy: 'oneShot',
            },
          ),
        ],
      ),
    ],
  );
}

MapData _mapForFactConditions({ScriptCondition? condition}) {
  return MapData(
    id: 'map_port',
    name: 'Port Selbrume',
    size: const GridSize(width: 4, height: 3),
    layers: const [
      MapLayer.tile(
        id: 'ground',
        name: 'Sol',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      MapLayer.object(id: 'objects', name: 'Objets'),
    ],
    events: [
      MapEventDefinition(
        id: 'evt_existing',
        title: 'Événement existant',
        position: const EventPosition(layerId: 'objects', x: 0, y: 0),
        metadata: {'scope': 'event'},
        pages: [
          const MapEventPage(
            pageNumber: 4,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_existing'),
            metadata: {'untouched': 'higher'},
          ),
          MapEventPage(
            pageNumber: 2,
            condition: condition,
            script: const ScriptRef(scriptId: 'script_legacy'),
            message: 'Message legacy',
            sceneTarget: const MapEventSceneTarget(sceneId: 'scene_rival'),
            metadata: const {
              'legacyKey': 'legacyValue',
              EventBuilderMetadataKeys.reusePolicy: 'oneShot',
            },
          ),
        ],
      ),
    ],
  );
}

MapData _mapForEventConsumedConditions({ScriptCondition? condition}) {
  return MapData(
    id: 'map_port',
    name: 'Port Selbrume',
    size: const GridSize(width: 4, height: 3),
    layers: const [
      MapLayer.tile(
        id: 'ground',
        name: 'Sol',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      MapLayer.object(id: 'objects', name: 'Objets'),
    ],
    events: [
      MapEventDefinition(
        id: 'evt_existing',
        title: 'Événement existant',
        position: const EventPosition(layerId: 'objects', x: 0, y: 0),
        metadata: {'scope': 'event'},
        pages: [
          const MapEventPage(
            pageNumber: 4,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_existing'),
            metadata: {'untouched': 'higher'},
          ),
          MapEventPage(
            pageNumber: 2,
            condition: condition,
            script: const ScriptRef(scriptId: 'script_legacy'),
            message: 'Message legacy',
            sceneTarget: const MapEventSceneTarget(sceneId: 'scene_rival'),
            metadata: const {
              'legacyKey': 'legacyValue',
              EventBuilderMetadataKeys.reusePolicy: 'oneShot',
            },
          ),
        ],
      ),
      const MapEventDefinition(
        id: 'evt_rival',
        title: 'Rival au port',
        position: EventPosition(layerId: 'objects', x: 1, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_existing'),
          ),
        ],
      ),
      const MapEventDefinition(
        id: 'evt_guard',
        title: 'Garde endormi',
        position: EventPosition(layerId: 'objects', x: 2, y: 0),
        pages: [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_existing'),
          ),
        ],
      ),
    ],
  );
}

MapData _mapForTriggerTypeAuthoring() {
  return MapData(
    id: 'map_port',
    name: 'Port Selbrume',
    size: const GridSize(width: 4, height: 3),
    layers: const [
      MapLayer.tile(
        id: 'ground',
        name: 'Sol',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      MapLayer.object(id: 'objects', name: 'Objets'),
    ],
    events: [
      MapEventDefinition(
        id: 'evt_existing',
        title: 'Événement existant',
        type: MapEventType.actor,
        position: const EventPosition(layerId: 'objects', x: 0, y: 0),
        metadata: {'scope': 'event'},
        pages: [
          MapEventPage(
            pageNumber: 0,
            condition: ScriptConditionFactory.flagIsSet('fact_started'),
            script: const ScriptRef(scriptId: 'script_legacy'),
            message: 'Message legacy',
            sceneTarget: const MapEventSceneTarget(sceneId: 'scene_existing'),
            metadata: const {
              'legacyKey': 'legacyValue',
              EventBuilderMetadataKeys.reusePolicy: 'oneShot',
            },
          ),
        ],
      ),
    ],
  );
}

MapData _mapWithoutEventPages() {
  return const MapData(
    id: 'map_port',
    name: 'Port Selbrume',
    size: GridSize(width: 4, height: 3),
    layers: [
      MapLayer.tile(
        id: 'ground',
        name: 'Sol',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      MapLayer.object(id: 'objects', name: 'Objets'),
    ],
    events: [
      MapEventDefinition(
        id: 'evt_empty',
        title: 'Event sans page',
        position: EventPosition(layerId: 'objects', x: 0, y: 0),
        pages: [],
      ),
    ],
  );
}

MapData _mapWithoutObjectLayer() {
  return const MapData(
    id: 'map_port',
    name: 'Port Selbrume',
    size: GridSize(width: 4, height: 3),
    layers: [
      MapLayer.tile(
        id: 'ground',
        name: 'Sol',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
    ],
    events: [],
  );
}
