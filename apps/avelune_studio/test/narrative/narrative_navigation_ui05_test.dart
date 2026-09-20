import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/narrative/application/dialogue_draft_codec.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late _MapPort mapsPort;
  late _NarrativePort port;
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;
  late List<NarrativeEventRecord> records;
  setUp(() async {
    mapsPort = _MapPort();
    port = _NarrativePort();
    maps = MapWorkspaceController(workspaceSession, mapsPort);
    await maps.initialize();
    final projections = [
      for (final id in ['a', 'b'])
        NarrativeInteractionDraft(
          id: 'evt_00000000-0000-7000-8000-00000000000${id == 'a' ? 1 : 2}',
          name: id,
          mapId: id,
          source: NarrativeEventSourceRef.entityInteract(id, 'npc'),
          dialogueId: id,
        ).project(),
    ];
    records = projections.map((value) => value.event).toList();
    maps.project = maps.project!.copyWith(
      dialogues: [
        for (final id in ['a', 'b'])
          ProjectDialogueEntry(id: id, name: id, relativePath: '$id.yarn'),
      ],
      scenes: projections.map((value) => value.scene).toList(),
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: records,
        legacyClaims: [],
      ),
    );
    narrative = NarrativeWorkspaceController(
      maps,
      port,
      () {},
      (_, _) async {},
    );
  });
  tearDown(() {
    narrative.dispose();
    maps.dispose();
  });

  test('only latest dialogue opening becomes an edit session', () async {
    final gate = port.gates['a'] = Completer<void>();
    final first = narrative.openRecord(records.first);
    await port.started('a');
    expect(await narrative.openRecord(records.last), true);
    final selected = narrative.active;
    gate.complete();
    expect(await first, false);
    expect(narrative.active, same(selected));
    expect(selected!.document.current.id, 'b');
    expect(narrative.sessions.keys, [records.last.id]);
    expect(mapsPort.writes, 0);
    expect(port.publications, 0);
  });

  test('superseded map load cannot switch map or read its dialogue', () async {
    final gate = mapsPort.gates['b'] = Completer<void>();
    final first = narrative.openRecord(records.last);
    await mapsPort.started.future;
    expect(await narrative.openRecord(records.first), true);
    gate.complete();
    expect(await first, false);
    expect(maps.active!.current.id, 'a');
    expect(maps.documents.keys, ['a']);
    expect(port.reads, ['a']);
  });

  test('closing workspace during read cannot publish late state', () async {
    final gate = port.gates['a'] = Completer<void>();
    final opening = narrative.openRecord(records.first);
    await port.started('a');
    maps.dispose();
    narrative.dispose();
    gate.complete();
    expect(await opening, false);
    expect(narrative.sessions, isEmpty);
    expect(narrative.active, isNull);
  });

  test('catalogue replacement invalidates an outstanding read', () async {
    final gate = port.gates['a'] = Completer<void>();
    final opening = narrative.openRecord(records.first);
    await port.started('a');
    final replacement = maps.project!.copyWith(name: 'Autre projet');
    maps.project = replacement;
    gate.complete();
    expect(await opening, false);
    expect(maps.project, same(replacement));
    expect(narrative.sessions, isEmpty);
    expect(narrative.active, isNull);
  });

  test('explicit cancellation prevents late errors and sessions', () async {
    final gate = port.gates['a'] = Completer<void>();
    final opening = narrative.openRecord(records.first);
    await port.started('a');
    narrative.cancelOpening();
    gate.completeError(StateError('Ancienne erreur'));
    expect(await opening, false);
    expect(narrative.error, isNull);
    expect(narrative.sessions, isEmpty);
    expect(narrative.busy, false);
  });

  test(
    'localizing uses dirty source and preserves history without writes',
    () async {
      final document = maps.active!;
      document.commit(
        document.current.copyWith(
          entities: const [
            MapEntity(
              id: 'npc',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 8, y: 9),
              npc: MapEntityNpcData(),
            ),
          ],
        ),
      );
      final snapshot = document.current;
      await maps.activate(workspaceEntries.last);
      final location = await narrative.locateInteraction(records.first.id);
      expect(location!.document, same(document));
      expect(location.position, const GridPos(x: 8, y: 9));
      expect(location.entityId, 'npc');
      expect(maps.active, same(document));
      expect(document.current, same(snapshot));
      expect(document.undoCount, 1);
      expect(document.dirty, true);
      expect(narrative.sessions, isEmpty);
      expect(port.reads, isEmpty);
      expect(port.publications, 0);
      expect(mapsPort.writes, 0);
    },
  );

  test(
    'missing source produces local diagnosis and no fictitious session',
    () async {
      expect(await narrative.locateInteraction(records.first.id), isNull);
      expect(narrative.error, contains('disparu'));
      expect(await narrative.locateInteraction('unknown'), isNull);
      expect(narrative.error, contains('emplacement précis'));
      expect(narrative.sessions, isEmpty);
      expect(port.reads, isEmpty);
      expect(port.publications, 0);
    },
  );

  test(
    'resuming local draft retains edits and restores original map',
    () async {
      expect(await narrative.openRecord(records.first), true);
      final edit = narrative.active!;
      edit.change(
        dialogue: edit.current.dialogue.copyWith(
          branches: const [
            DialogueBranchDraft(
              id: 'start',
              name: 'Accueil',
              lines: [DialogueLineDraft(text: 'Texte en cours')],
            ),
          ],
        ),
      );
      final snapshot = edit.current;
      await maps.activate(workspaceEntries.last);
      expect(await narrative.openSession(edit), true);
      expect(narrative.active, same(edit));
      expect(edit.current, same(snapshot));
      expect(edit.dirty, true);
      expect(maps.active, same(edit.document));
      expect(port.reads, ['a']);
    },
  );

  test('whitespace-only steps cannot create empty stories', () {
    narrative.addStory('Histoire', [' ', '\n']);
    expect(narrative.pendingStories, isEmpty);
    narrative.addStory(' Histoire ', [' ', ' Étape ', '\n']);
    final story = narrative.pendingStories.values.single;
    expect(story.title, 'Histoire');
    expect(story.chapters.single.steps.single.title, 'Étape');
  });

  test(
    'zone localization resolves its current rectangle without editing',
    () async {
      final document = maps.active!;
      document.commit(
        document.current.copyWith(
          triggers: const [
            MapTrigger(
              id: 'zone',
              type: TriggerType.event,
              area: MapRect(
                pos: GridPos(x: 4, y: 6),
                size: GridSize(width: 5, height: 3),
              ),
            ),
          ],
        ),
      );
      await narrative.openSource(
        document,
        NarrativeEventSourceRef.triggerEnter('a', 'zone'),
        'Zone',
      );
      final id = narrative.active!.current.interaction.id;
      final snapshot = document.current;
      final location = await narrative.locateInteraction(id);
      expect(location!.triggerId, 'zone');
      expect(location.position, const GridPos(x: 6, y: 7));
      expect(document.current, same(snapshot));
      expect(document.undoCount, 1);
      expect(mapsPort.writes, 0);
      expect(port.publications, 0);
    },
  );
}

class _MapPort extends WorkspaceMemoryPort {
  final gates = <String, Completer<void>>{};
  final started = Completer<void>();
  @override
  Future<MapWorkspaceDocument> loadMap(session, ProjectMapEntry entry) async {
    final gate = gates[entry.id];
    if (gate != null) {
      if (!started.isCompleted) started.complete();
      await gate.future;
    }
    return super.loadMap(session, entry);
  }
}

class _NarrativePort implements NarrativePort {
  final gates = <String, Completer<void>>{};
  final _started = <String, Completer<void>>{};
  final reads = <String>[];
  int publications = 0;
  Future<void> started(String id) =>
      _started.putIfAbsent(id, Completer<void>.new).future;
  @override
  Future<NarrativeDialogueSource> readDialogue(
    ProjectDialogueEntry entry,
  ) async {
    reads.add(entry.id);
    _started.putIfAbsent(entry.id, Completer<void>.new).complete();
    await gates[entry.id]?.future;
    return const DialogueDraftCodec().encode(
      DialogueDraft(
        entry: entry,
        branches: const [
          DialogueBranchDraft(
            id: 'Start',
            name: 'Début',
            lines: [DialogueLineDraft(text: 'Bonjour')],
          ),
        ],
      ),
    );
  }

  @override
  Future<NarrativePublicationReceipt> publish(NarrativePublication value) {
    publications++;
    throw UnimplementedError();
  }
}
