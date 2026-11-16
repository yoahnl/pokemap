import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';

import '../presentation/map_builder_story_support.dart';
import '../support/map_workspace_fixture.dart';
import 'game_behaviour_edit_support.dart';

void main() {
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
