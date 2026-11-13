import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_draft_reference_guard.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

const eventId = 'evt_0192bc3d-4e5f-7a1b-8c2d-3e4f5a6b7c8d';

ProjectManifest projectUsing(String mapId, String entityId) =>
    workspaceProject.copyWith(
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [
          NarrativeEventRecord.draft(
            NarrativeEventDraft(
              id: eventId,
              name: 'Lecture du panneau',
              source: NarrativeEventSourceRef.entityInteract(mapId, entityId),
              conditions: const [],
              priority: 0,
              order: 0,
            ),
          ),
        ],
        legacyClaims: const [],
      ),
    );

EditableMapDocument documentFor(String mapId) => EditableMapDocument(
  MapWorkspaceDocument(
    map: workspaceMap(mapId),
    revision: 'base',
    mapId: mapId,
  ),
);

void main() {
  test('a free sign is deleted and the deletion is undoable', () {
    final document = documentFor('a');
    final commands = MapEntityEditingCommands(document, workspaceProject);
    final sign = commands.place(MapEntityKind.sign, const GridPos(x: 4, y: 4));

    expect(commands.deletionProblem(sign.id), isNull);
    commands.delete(sign.id);
    expect(document.current.entities, isEmpty);

    document.restore(redo: false);
    expect(commands.selected(sign.id), isNotNull);
    document.restore(redo: true);
    expect(document.current.entities, isEmpty);
  });

  test('a referenced sign refuses to be deleted', () {
    final document = documentFor('a');
    final sign = MapEntityEditingCommands(
      document,
      workspaceProject,
    ).place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
    final guarded = MapEntityEditingCommands(
      document,
      projectUsing('a', sign.id),
    );

    expect(
      guarded.deletionProblem(sign.id),
      contains('histoire'),
      reason: 'the author is told what holds the sign',
    );
    final steps = document.undoCount;
    expect(() => guarded.delete(sign.id), throwsStateError);
    expect(
      document.current.entities,
      hasLength(1),
      reason: 'the entity and its reference both survive',
    );
    expect(
      document.undoCount,
      steps,
      reason: 'a refused deletion adds no history entry',
    );
  });

  test('a referenced player start refuses to be deleted too', () {
    final document = documentFor('a');
    final spawn = MapEntityEditingCommands(
      document,
      workspaceProject,
    ).place(MapEntityKind.spawn, const GridPos(x: 2, y: 2));
    final guarded = MapEntityEditingCommands(
      document,
      projectUsing('a', spawn.id),
    );

    expect(guarded.deletionProblem(spawn.id), isNotNull);
    expect(() => guarded.delete(spawn.id), throwsStateError);
    expect(guarded.playerStart(), isNotNull);
  });

  test('a twin id referenced on another map never blocks this one', () {
    final document = documentFor('a');
    final sign = MapEntityEditingCommands(
      document,
      workspaceProject,
    ).place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
    final commands = MapEntityEditingCommands(
      document,
      projectUsing('b', sign.id),
    );

    expect(
      commands.deletionProblem(sign.id),
      isNull,
      reason: 'the reference points at another map, not at this entity',
    );
    commands.delete(sign.id);
    expect(document.current.entities, isEmpty);
  });

  test('a target that left the document is refused at execution time', () {
    final document = documentFor('a');
    final commands = MapEntityEditingCommands(document, workspaceProject);
    final sign = commands.place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
    commands.delete(sign.id);

    final steps = document.undoCount;
    expect(
      () => commands.delete(sign.id),
      throwsStateError,
      reason: 'the command checks its target instead of trusting the button',
    );
    expect(document.undoCount, steps);
  });

  test('a dependency added after the first read is still honoured', () {
    final document = documentFor('a');
    final commands = MapEntityEditingCommands(document, workspaceProject);
    final sign = commands.place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
    expect(commands.deletionProblem(sign.id), isNull);

    final guarded = MapEntityEditingCommands(
      document,
      projectUsing('a', sign.id),
    );
    expect(
      guarded.deletionProblem(sign.id),
      isNotNull,
      reason: 'the guard reads the dependencies when it acts, not once at open',
    );
    expect(() => guarded.delete(sign.id), throwsStateError);
  });

  test('an unsaved draft target blocks deletion until released', () {
    final document = documentFor('a');
    final sign = MapEntityEditingCommands(
      document,
      workspaceProject,
    ).place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
    var sources = MapDraftReferenceSources(
      ruleTargets: [
        (mapId: 'a', kind: MapDraftReferenceKind.entity, id: sign.id),
      ],
    );
    final index = MapDraftReferenceIndex(() => sources);
    final commands = MapEntityEditingCommands(
      document,
      workspaceProject,
      draftGuard: index.guard,
    );
    final before = document.current;
    final steps = document.undoCount;
    expect(commands.deletionProblem(sign.id), contains('brouillon'));
    expect(() => commands.delete(sign.id), throwsStateError);
    expect(document.current, same(before));
    expect(document.undoCount, steps);
    sources = const MapDraftReferenceSources();
    expect(commands.deletionProblem(sign.id), isNull);
    commands.delete(sign.id);
    expect(document.current.entities, isEmpty);
  });
}
