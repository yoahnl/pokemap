import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('NS-EVENT-08 EditorNotifier draft event creation', () {
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
