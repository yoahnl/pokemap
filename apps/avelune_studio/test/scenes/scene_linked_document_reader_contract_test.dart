import 'package:avelune_studio/features/scenes/application/scene_linked_document_reader.dart';

import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/interaction_edit_session.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;
  late _Port port;
  late SceneLinkedDocumentReader documents;
  const entry = ProjectDialogueEntry(
    id: 'advanced',
    name: 'Original avancé',
    relativePath: 'advanced.yarn',
    defaultStartNode: 'Actual',
  );
  const raw =
      'title: Actual\n---\nVraie source originale.\n<<jump Next>>\n===\ntitle: Next\n---\nSuite originale.\n===\n';
  setUp(() async {
    maps = MapWorkspaceController(workspaceSession, WorkspaceMemoryPort());
    await maps.initialize();
    maps.project = maps.project!.copyWith(dialogues: [entry]);
    port = _Port();
    narrative = NarrativeWorkspaceController(
      maps,
      port,
      () {},
      (_, _) async {},
    );
    documents = SceneLinkedDocumentReader();
  });
  tearDown(() {
    narrative.dispose();
    maps.dispose();
  });
  InteractionEditSession local({bool readOnly = true}) {
    final session = InteractionEditSession(
      document: maps.active!,
      dialogue: DialogueDraft.blank(entry),
      interaction: NarrativeInteractionDraft(
        id: 'interaction',
        name: 'Test',
        mapId: 'a',
        source: NarrativeEventSourceRef.entityInteract('a', 'npc'),
        dialogueId: entry.id,
      ),
      readOnlySource: readOnly ? raw : null,
    );
    narrative.sessions['interaction'] = session;
    return session;
  }

  test('pending policy source read returns a newly opened local draft instead of stale disk text', () async {
    final pending = documents.readDialogueDocument(
      entry.id,
      maps.project!,
      narrative,
    );
    expect(port.reads, 1);
    final session = local(readOnly: false);
    session.change(
      dialogue: DialogueDraft(
        entry: entry,
        branches: [
          DialogueBranchDraft(
            id: 'Latest',
            name: 'Brouillon actuel',
            lines: [DialogueLineDraft(text: 'Dernier texte du brouillon.')],
          ),
        ],
      ),
    );
    final before = session.current;
    port.pending[entry.id]!.complete(
      const NarrativeDialogueSource(entry: entry, source: raw),
    );

    final document = await pending;

    expect(document.nodes, hasLength(1));
    expect(
      document.nodes.single.steps.whereType<RuntimeDialogueLine>().map(
        (line) => line.text,
      ),
      ['Dernier texte du brouillon.'],
    );
    expect(session.current, same(before));
    expect(session.dirty, isTrue);
    expect(port.reads, 1);
    expect(port.writes, 0);
  });
  test('read-only local dialogue retains its actual text and exact missing start without disk reads', () async {
    final session = local();
    final before = session.current;
    final document = await documents.readDialogueDocument(
      entry.id,
      maps.project!,
      narrative,
    );
    expect(document.nodes.map((node) => node.title), ['Actual', 'Next']);
    expect(
      document.nodes
          .expand((node) => node.steps)
          .whereType<RuntimeDialogueLine>()
          .map((line) => line.text),
      ['Vraie source originale.', 'Suite originale.'],
    );
    const source = NarrativeDialogueSource(entry: entry, source: raw);
    expect(
      selectLinkedDialogueStart(source, document, null).node!.title,
      'Actual',
    );
    final missing = selectLinkedDialogueStart(source, document, 'Missing');
    expect(missing.start, 'Missing');
    expect(missing.node, isNull);
    expect(session.current, same(before));
    expect(session.readOnlySource, raw);
    expect(session.dirty, isFalse);
    expect(port.reads, 0);
    expect(port.writes, 0);
  });

  test(
    'editable shared source is compiled without reading or publishing disk',
    () async {
      final session = local(readOnly: false);
      session.change(
        dialogue: DialogueDraft(
          entry: entry,
          branches: [
            DialogueBranchDraft(
              id: 'Draft',
              name: 'Brouillon',
              lines: [DialogueLineDraft(text: 'Texte local récent.')],
            ),
          ],
        ),
      );
      final before = session.current;
      final document = await documents.readDialogueDocument(
        entry.id,
        maps.project!,
        narrative,
      );
      expect(
        document.nodes.single.steps
            .whereType<RuntimeDialogueLine>()
            .single
            .text,
        'Texte local récent.',
      );
      expect(session.current, same(before));
      expect(session.dirty, isTrue);
      expect(port.reads, 0);
      expect(port.writes, 0);
    },
  );

  test('distinct entry requests and absent sources cannot reuse another entry result', () async {
    const other = ProjectDialogueEntry(
      id: 'other',
      name: 'Autre',
      relativePath: 'other.yarn',
    );
    maps.project = maps.project!.copyWith(dialogues: [entry, other]);
    final original = documents.readDialogueDocument(
      entry.id,
      maps.project!,
      narrative,
    );
    final latest = documents.readDialogueDocument(
      other.id,
      maps.project!,
      narrative,
    );
    port.pending[entry.id]!.complete(
      const NarrativeDialogueSource(entry: entry, source: raw),
    );
    final first = await original;
    expect(first.nodes.first.title, 'Actual');
    final failure = expectLater(latest, throwsA(isA<NarrativeFailure>()));
    port.pending[other.id]!.completeError(
      const NarrativeFailure('Source absente'),
    );
    await failure;
    await expectLater(
      documents.readDialogueDocument('missing', maps.project!, narrative),
      throwsStateError,
    );
    expect(port.reads, 2);
    expect(port.writes, 0);
  });

  test(
    'new workspace identity cannot reuse the previous source cache',
    () async {
      final pending = documents.readDialogueDocument(
        entry.id,
        maps.project!,
        narrative,
      );
      port.pending[entry.id]!.complete(
        const NarrativeDialogueSource(entry: entry, source: raw),
      );
      await pending;
      final project = maps.project;
      narrative.dispose();
      maps.dispose();
      maps = MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
        ..project = project;
      port = _Port();
      narrative = NarrativeWorkspaceController(
        maps,
        port,
        () {},
        (_, _) async {},
      );
      final next = documents.readDialogueDocument(
        entry.id,
        maps.project!,
        narrative,
      );
      expect(port.reads, 1);
      port.pending[entry.id]!.complete(
        NarrativeDialogueSource(
          entry: entry,
          source: raw.replaceAll(
            'Vraie source originale.',
            'Source de la nouvelle session.',
          ),
        ),
      );
      final document = await next;
      expect(
        document.nodes.first.steps.whereType<RuntimeDialogueLine>().first.text,
        'Source de la nouvelle session.',
      );
      expect(port.writes, 0);
    },
  );
}

class _Port implements NarrativePort {
  final pending = <String, Completer<NarrativeDialogueSource>>{};
  int reads = 0, writes = 0;
  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) {
    reads++;
    return (pending[entry.id] = Completer<NarrativeDialogueSource>()).future;
  }

  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication value,
  ) async {
    writes++;
    throw StateError('Preview must not publish');
  }
}
