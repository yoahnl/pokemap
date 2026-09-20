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

  NarrativeEventRecord reprioritize(NarrativeEventRecord record) {
    final json = record.toJson();
    final definition = Map<String, dynamic>.from(json['definition'] as Map);
    definition['priority'] = 42;
    return NarrativeEventRecord.fromJson({...json, 'definition': definition});
  }

  void replaceFirst(NarrativeEventRecord? record) {
    final before = maps.project!;
    maps.acceptResources(
      before,
      before.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          records: [?record, records.last],
          legacyClaims: [],
        ),
      ),
    );
  }

  test(
    'record-only publication invalidates a clean simplified session and reloads new priority',
    () async {
      expect(await narrative.openRecord(records.first), true);
      final old = narrative.active!;
      final scenes = maps.project!.scenes;
      final updated = reprioritize(records.first);
      replaceFirst(updated);
      expect(maps.project!.scenes, scenes);
      expect(narrative.sessions.containsKey(records.first.id), false);
      expect(await narrative.openSession(old), true);
      expect(narrative.active!.baseEvent, updated);
      expect(narrative.active!.current.interaction.priority, 42);
      expect(narrative.active!.dirty, false);
      expect(port.publications, 0);
    },
  );

  test(
    'record-only publication preserves dirty simplified draft and explicitly blocks stale save',
    () async {
      await narrative.openRecord(records.first);
      final edit = narrative.active!;
      edit.change(dialogue: edit.current.dialogue);
      final snapshot = edit.current;
      final updated = reprioritize(records.first);
      replaceFirst(updated);
      expect(narrative.sessions[records.first.id], same(edit));
      expect(edit.current, same(snapshot));
      expect(edit.dirty, true);
      expect(await narrative.openSession(edit), false);
      expect(narrative.error, contains('événement'));
      expect(await narrative.save(document: edit.document), false);
      expect(port.publications, 0);
      expect(maps.project!.eventRegistry!.records.first, updated);
      expect(await narrative.openRecord(records.last), true);
      expect(narrative.discardInteraction(records.first.id), true);
      expect(await narrative.openRecord(updated), true);
      expect(narrative.active!.current.interaction.priority, 42);
    },
  );

  test(
    'UI08 draft blocks edits and publication of same simplified event only',
    () async {
      await narrative.openRecord(records.first);
      final edit = narrative.active!;
      narrative.eventAccessProblem = (id) =>
          id == records.first.id ? 'Brouillon UI08' : null;
      final original = edit.current;
      edit.change(dialogue: edit.current.dialogue);
      expect(edit.current, same(original));
      expect(edit.editable, false);
      expect(edit.error, 'Brouillon UI08');
      expect(await narrative.openSession(edit), false);
      expect(await narrative.openRecord(records.last), true);
      expect(narrative.active!.editable, true);
      narrative.eventAccessProblem = null;
      expect(await narrative.openSession(edit), true);
      edit.change(dialogue: edit.current.dialogue);
      expect(narrative.interactionAccessProblem(records.first.id), isNotNull);
      expect(narrative.interactionAccessProblem(records.last.id), isNull);
      narrative.eventAccessProblem = (_) => 'Brouillon UI08';
      expect(await narrative.save(document: edit.document), false);
      expect(edit.dirty, true);
      expect(port.publications, 0);
    },
  );

  test(
    'deleted clean event is not recreated by stale open record or session',
    () async {
      await narrative.openRecord(records.first);
      final edit = narrative.active!;
      replaceFirst(null);
      expect(narrative.sessions, isEmpty);
      expect(await narrative.openRecord(records.first), false);
      expect(narrative.error, contains('introuvable'));
      expect(await narrative.openSession(edit), false);
      expect(narrative.sessions, isEmpty);
      expect(port.publications, 0);
    },
  );

  test('deleted dirty event stays recoverable without re-creation', () async {
    await narrative.openRecord(records.first);
    final edit = narrative.active!;
    edit.change(dialogue: edit.current.dialogue);
    replaceFirst(null);
    expect(narrative.sessions[records.first.id], same(edit));
    expect(edit.dirty, true);
    expect(await narrative.save(document: edit.document), false);
    expect(port.publications, 0);
    expect(await narrative.openRecord(records.last), true);
  });
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
    final started = _started.putIfAbsent(entry.id, Completer<void>.new);
    if (!started.isCompleted) started.complete();
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
