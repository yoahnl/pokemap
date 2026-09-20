import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/dialogue_draft_codec.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_inspector.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_linked_document.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  testWidgets(
    'changing dialogue retains stale wires until explicit correction or undo',
    (tester) async {
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
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 500,
              child: StatefulBuilder(
                builder: (context, setState) => SceneInspector(
                  session: session,
                  project: project,
                  nodeId: 'welcome',
                  edgeId: null,
                  changed: () => setState(() {}),
                  onDocument: (_) {},
                  onDelete: () {},
                  onDuplicate: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nouveau dialogue').last);
      await tester.pumpAndSettle();
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
        find.textContaining('Des connexions utilisent des résultats absents'),
        findsOneWidget,
      );
      expect(session.undoCount, 1);
      session.restore(redo: false);
      expect(session.current, original);
    },
  );

  testWidgets(
    'linked start picker loads one exact document and shares its cached preview',
    (tester) async {
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
      final maps = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      )..project = project;
      addTearDown(maps.dispose);
      final port = _DialoguePort(source);
      final narrative = NarrativeWorkspaceController(
        maps,
        port,
        () {},
        (_, _) async {},
      );
      final documents = SceneLinkedDocuments();
      String? chosen;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: Column(
              children: [
                documents.dialoguePreview(
                  SceneYarnDialoguePayload(
                    dialogueId: 'linked',
                    yarnNodeName: 'Missing',
                  ),
                  project,
                  narrative,
                  onStartChanged: (value) => chosen = value,
                ),
                Builder(
                  builder: (context) => TextButton(
                    onPressed: () => documents.open(
                      context,
                      SceneNode(
                        id: 'dialogue',
                        kind: SceneNodeKind.yarnDialogue,
                        payload: SceneYarnDialoguePayload(dialogueId: 'linked'),
                      ),
                      project,
                      narrative,
                    ),
                    child: const Text('Document exact'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(port.reads, 1);
      expect(
        find.textContaining('point de départ référencé est absent'),
        findsOneWidget,
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other').last);
      await tester.pumpAndSettle();
      expect(chosen, 'Other');
      await tester.tap(find.text('Document exact'));
      await tester.pumpAndSettle();
      expect(find.text('Bienvenue en gare.'), findsOneWidget);
      expect(find.text('Un autre accueil.'), findsOneWidget);
      expect(port.reads, 1);
      expect(port.writes, 0);
      expect(narrative.sessions, isEmpty);
      await tester.tap(find.text('Retour à la scène'));
      await tester.pumpAndSettle();
      expect(chosen, 'Other');
    },
  );

  testWidgets('cinematic preview describes real steps without raw JSON', (
    tester,
  ) async {
    final project = ProjectManifest(
      name: 'Cinematic',
      maps: const [],
      tilesets: const [],
      cinematics: [Ui06SceneFixture.buildCinematic()],
    );
    final documents = SceneLinkedDocuments();
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => documents.open(
                context,
                SceneNode(
                  id: 'cinematic',
                  kind: SceneNodeKind.cinematic,
                  payload: SceneCinematicPayload(
                    cinematicId: Ui06SceneFixture.cinematicId,
                  ),
                ),
                project,
                null,
              ),
              child: const Text('Aperçu'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Aperçu'));
    await tester.pumpAndSettle();
    expect(find.text('Un instant avant le départ'), findsOneWidget);
    expect(find.text('1. Attendre'), findsOneWidget);
    expect(find.text('100 ms'), findsOneWidget);
    expect(find.textContaining('durées explicites 0.1 s'), findsOneWidget);
    expect(find.textContaining('timeline :'), findsNothing);
    await tester.tap(find.text('Retour à la scène'));
    await tester.pumpAndSettle();
    expect(find.text('Aperçu'), findsOneWidget);
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
