import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/dialogue_draft_codec.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/features/scenes/application/scene_linked_document_reader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'changing dialogue retains stale wires until explicit correction or undo',
    () async {
      final base = Ui06SceneFixture.buildScene();
      final original = SceneAsset.fromJson({
        ...base.toJson(),
        'graph': {
          ...base.graph.toJson(),
          'nodes': [
            for (final node in base.graph.nodes)
              if (node.id == 'welcome')
                {
                  ...node.toJson(),
                  'payload': SceneYarnDialoguePayload(
                    dialogueId: 'old',
                    expectedOutcomes: ['old-result'],
                    speakerHints: ['guide'],
                  ).toJson(),
                }
              else
                node.toJson(),
          ],
          'edges': [
            for (final edge in base.graph.edges)
              if (edge.fromNodeId == 'welcome')
                {
                  ...edge.toJson(),
                  'fromPortId': 'old-result',
                  'kind': 'dialogueOutcome',
                }
              else
                edge.toJson(),
          ],
        },
      });
      final session = SceneEditSession(original, base: original);
      final project = ProjectManifest(
        name: 'Inspector',
        maps: const [],
        tilesets: const [],
        scenes: [original],
        dialogues: const [
          ProjectDialogueEntry(
            id: 'old',
            name: 'Ancien dialogue',
            relativePath: 'old.yarn',
            declaredOutcomes: [
              DialogueDeclaredOutcome(
                id: 'old-result',
                label: 'Ancien résultat',
              ),
            ],
          ),
          ProjectDialogueEntry(
            id: 'new',
            name: 'Nouveau dialogue',
            relativePath: 'new.yarn',
          ),
        ],
      );
      final node = original.graph.nodes.singleWhere(
        (node) => node.id == 'welcome',
      );
      expect(
        await session.retargetDialogue(
          node: node,
          original: node.payload as SceneYarnDialoguePayload,
          target: project.dialogues.last,
          start: null,
          outcomes: const [],
        ),
        isTrue,
      );
      expect(session.current.graph.edges, original.graph.edges);
      expect(session.current.layout, original.layout);
      expect(session.current.metadata, original.metadata);
      final payload =
          session.current.graph.nodes
                  .firstWhere((node) => node.id == 'welcome')
                  .payload
              as SceneYarnDialoguePayload;
      expect(payload.dialogueId, 'new');
      expect(payload.speakerHints, ['guide']);
      expect(
        session.current.graph.edges
            .where((edge) => edge.fromNodeId == 'welcome')
            .map((edge) => edge.fromPortId),
        everyElement('old-result'),
      );
      expect(session.undoCount, 1);
      session.restore(redo: false);
      expect(session.current, original);
    },
  );

  test('linked reader loads one exact document caches it and preserves missing or selected starts', () async {
    final source = const DialogueDraftCodec().encode(
      DialogueDraft(
        entry: const ProjectDialogueEntry(
          id: 'linked',
          name: 'Accueil',
          relativePath: 'linked.yarn',
        ),
        branches: const [
          DialogueBranchDraft(
            id: 'Start',
            name: 'Accueil',
            lines: [DialogueLineDraft(text: 'Bienvenue en gare.')],
          ),
          DialogueBranchDraft(
            id: 'Other',
            name: 'Autre départ',
            lines: [DialogueLineDraft(text: 'Un autre accueil.')],
          ),
        ],
      ),
    );
    final project = ProjectManifest(
      name: 'Linked',
      maps: const [],
      tilesets: const [],
      dialogues: [source.entry],
    );
    final maps = MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
      ..project = project;
    addTearDown(maps.dispose);
    final port = _DialoguePort(source);
    final narrative = NarrativeWorkspaceController(
      maps,
      port,
      () {},
      (_, _) async {},
    );
    addTearDown(narrative.dispose);
    final documents = SceneLinkedDocumentReader();
    final compiled = await documents.readDialogueDocument(
      'linked',
      project,
      narrative,
    );
    final missing = selectLinkedDialogueStart(source, compiled, 'Missing');
    expect(missing.start, 'Missing');
    expect(missing.node, isNull);
    final selected = selectLinkedDialogueStart(source, compiled, 'Other');
    expect(selected.node!.title, 'Other');
    final again = await documents.readDialogueDocument(
      'linked',
      project,
      narrative,
    );
    expect(again, same(compiled));
    expect(
      compiled.nodes
          .expand((node) => node.steps)
          .whereType<RuntimeDialogueLine>()
          .map((line) => line.text),
      ['Bienvenue en gare.', 'Un autre accueil.'],
    );
    expect(port.reads, 1);
    expect(port.writes, 0);
    expect(narrative.sessions, isEmpty);
    expect(
      selectLinkedDialogueStart(source, again, 'Other').node,
      same(selected.node),
    );
  });
}

class _DialoguePort implements NarrativePort {
  _DialoguePort(this.source);
  final NarrativeDialogueSource source;
  int reads = 0, writes = 0;
  @override
  Future<NarrativeDialogueSource> readDialogue(
    ProjectDialogueEntry entry,
  ) async {
    reads++;
    expect(entry.id, source.entry.id);
    return source;
  }

  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) async {
    writes++;
    throw StateError('Preview must not publish');
  }
}
