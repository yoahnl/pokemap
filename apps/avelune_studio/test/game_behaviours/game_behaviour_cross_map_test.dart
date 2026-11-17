import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';

import '../presentation/map_builder_story_support.dart';
import '../support/map_workspace_fixture.dart';
import 'game_behaviour_edit_support.dart';

void main() {
  test('returning from a separately decoded map refreshes its editor without another map read', () async {
    final record = recordOnB();
    final second = recordOnB(2);
    final fixture = await openStory(records: [record, second]);
    final port = fixture.maps.port as WorkspaceMemoryPort;
    port.saved['b'] = MapData.fromJson(
      workspaceMap('b').copyWith(entities: [storyLuth]).toJson(),
    );
    final loader = BehaviourMapLoader();
    final catalog = openCatalogue(fixture, loader);
    expect(await catalog.open(record.id), isTrue);
    final old = catalog.editor!;
    expect(old.renameBehaviour(record, 'Brouillon B'), isTrue);
    old.openBehaviour(
      old.selected!.behaviours.indexWhere((item) => item.id == second.id),
    );
    final project = fixture.maps.project;
    await fixture.maps.activate(workspaceEntries.last);
    expect(fixture.maps.project, same(project));
    expect(old.editing!.problem, isNotNull);
    await catalog.sync();
    expect(catalog.editor!.editing!.problem, isNull);
    expect(catalog.editor!.selectedBehaviour!.id, second.id);
    expect(storyCurrent(fixture, record.id).name, 'Brouillon B');
    expect(loader.reads, ['b']);
  });
  test(
    'a late creation context cannot replace an explicitly opened rule',
    () async {
      final a = storyRecord(1);
      final fixture = await openStory(records: [a]);
      final gate = Completer<MapData>();
      final loader = BehaviourMapLoader()..gate = gate;
      final catalog = openCatalogue(fixture, loader);
      final late = catalog.prepareCreation('b');
      await Future<void>.delayed(Duration.zero);
      expect(await catalog.open(a.id), isTrue);
      final editor = catalog.editor;
      gate.complete(workspaceMap('b').copyWith(entities: [storyLuth]));
      expect(await late, isFalse);
      expect(catalog.editor, same(editor));
      expect(catalog.selectedId, a.id);
      expect(fixture.story.behaviours.draft.recorded, 0);
    },
  );

  test(
    'a creation context refuses a removed source without losing other drafts',
    () async {
      final fixture = await openStory(records: [storyRecord(1)]);
      await fixture.maps.activate(workspaceEntries.last);
      fixture.maps.active!.current = workspaceMap('b')
          .copyWith(entities: [storyLuth]);
      final catalog = openCatalogue(fixture, BehaviourMapLoader());
      expect(await catalog.prepareCreation('b'), isTrue);
      final editor = catalog.editor!;
      final source = editor.elements!.byKey('entity:luth')!;
      editor.select(source);
      fixture.maps.active!.current = workspaceMap('b');
      expect(editor.addBehaviour(source), isFalse);
      expect(editor.error, isNotNull);
      expect(fixture.story.behaviours.draft.recorded, 0);
      expect(fixture.maps.active!.current.entities, isEmpty);
    },
  );
  test(
    'opening a non-first case through the catalog selects its exact identity',
    () async {
      final first = storyRecord(1);
      final second = storyRecord(2, order: 1);
      final fixture = await openStory(records: [first, second]);
      final catalog = openCatalogue(fixture, BehaviourMapLoader());
      expect(await catalog.open(second.id), isTrue);
      expect(catalog.editor!.selectedBehaviour?.id, second.id);
      expect(catalog.editor!.renameBehaviour(second, 'Deuxième cas'), isTrue);
      expect(storyCurrent(fixture, first.id), first);
      expect(storyCurrent(fixture, second.id).name, 'Deuxième cas');
    },
  );
  test('Histoire edits B while Carte keeps A and its selection', () async {
    final record = recordOnB();
    final fixture = await openStory(records: [record, storyRecord(2)]);
    fixture.story.select(storyElement(fixture));
    final active = fixture.maps.active;
    final selected = fixture.story.selected;
    final loader = BehaviourMapLoader();
    final catalog = openCatalogue(fixture, loader);
    expect(await catalog.open(record.id), isTrue);
    final editor = catalog.editor!;
    expect(editor.map!.id, 'b');
    expect(editor.selected!.id, 'luth');
    expect(editor.renameBehaviour(record, 'B modifié'), isTrue);
    expect(storyCurrent(fixture, record.id).name, 'B modifié');
    expect(fixture.maps.active, same(active));
    expect(fixture.story.selected!.key, selected!.key);
    expect(editor.rename(editor.selected!, 'Porteur interdit'), isFalse);
    fixture.story.undo();
    expect(storyCurrent(fixture, record.id), record);
    fixture.story.redo();
    expect(storyCurrent(fixture, record.id).name, 'B modifié');
    expect(fixture.ports.calls, isEmpty);
  });

  test('the unsaved version of B is used without a map read', () async {
    final record = recordOnB();
    final fixture = await openStory(records: [record]);
    await fixture.maps.activate(workspaceEntries.last);
    fixture.maps.active!.current = workspaceMap('b')
        .copyWith(entities: [storyLuth.copyWith(name: 'Luth non enregistré')]);
    final unsaved = fixture.maps.active!.current;
    await fixture.maps.activate(workspaceEntries.first);
    final loader = BehaviourMapLoader();
    final catalog = openCatalogue(fixture, loader);
    expect(await catalog.open(record.id), isTrue);
    expect(catalog.editor!.map, same(unsaved));
    expect(catalog.editor!.selected!.name, 'Luth non enregistré');
    expect(loader.reads, isEmpty);
  });

  test(
    'a deleted porter and a changed map refuse edits and simulation',
    () async {
      final record = recordOnB();
      final fixture = await openStory(records: [record]);
      await fixture.maps.activate(workspaceEntries.last);
      fixture.maps.active!.current = workspaceMap('b')
          .copyWith(entities: [storyLuth]);
      final catalog = openCatalogue(fixture, BehaviourMapLoader());
      expect(await catalog.open(record.id), isTrue);
      final old = catalog.editor!;
      fixture.maps.active!.current = workspaceMap('b');
      expect(old.renameBehaviour(record, 'Trop tard'), isFalse);
      expect(
        old.simulate(NarrativeEventSimulationInput(targetEventId: record.id)),
        isNull,
      );
      expect(await catalog.open(record.id), isFalse);
      expect(catalog.editor, isNull);
      expect(catalog.error, isNotNull);
      expect(storyCurrent(fixture, record.id), record);
      expect(fixture.story.dirty, isFalse);
    },
  );

  test('a late selection cannot replace the next editor', () async {
    final a = storyRecord(1);
    final b = recordOnB(2);
    final fixture = await openStory(records: [a, b]);
    final gate = Completer<MapData>();
    final loader = BehaviourMapLoader()..gate = gate;
    final catalog = openCatalogue(fixture, loader);
    final late = catalog.open(b.id);
    await Future<void>.delayed(Duration.zero);
    expect(await catalog.open(a.id), isTrue);
    final editor = catalog.editor;
    gate.complete(workspaceMap('b').copyWith(entities: [storyLuth]));
    expect(await late, isFalse);
    expect(catalog.editor, same(editor));
    expect(catalog.selectedId, a.id);
    expect(catalog.editor!.renameBehaviour(a, 'A actuel'), isTrue);
    expect(storyCurrent(fixture, b.id), b);
  });

  test('a failed map load keeps the draft intact and can be retried', () async {
    final record = recordOnB();
    final fixture = await openStory(records: [record]);
    final loader = BehaviourMapLoader()
      ..failure = StateError('Lecture refusée');
    final catalog = openCatalogue(fixture, loader);
    expect(await catalog.open(record.id), isFalse);
    expect(catalog.editor, isNull);
    expect(fixture.story.behaviours.draft.recorded, 0);
    loader.failure = null;
    expect(await catalog.open(record.id), isTrue);
    final closed = catalog.editor!;
    catalog.dispose();
    expect(closed.renameBehaviour(record, 'Fiche fermée'), isFalse);
    expect(storyCurrent(fixture, record.id), record);
  });
}
