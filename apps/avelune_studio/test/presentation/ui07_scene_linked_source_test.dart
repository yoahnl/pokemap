import 'dart:async';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/dialogue_draft_codec.dart';
import 'package:avelune_studio/features/narrative/application/interaction_edit_session.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_linked_document.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;
  late _Port port;
  late SceneLinkedDocuments documents;
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
    documents = SceneLinkedDocuments();
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

  Future<void> pump(
    WidgetTester tester, {
    String id = 'advanced',
    String? start,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: documents.dialoguePreview(
            SceneYarnDialoguePayload(dialogueId: id, yarnNodeName: start),
            maps.project!,
            narrative,
            detailed: true,
            onStartChanged: (_) {},
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'read-only source and starts are original, never blank replacement',
    (tester) async {
      final source = NarrativeDialogueSource(entry: entry, source: raw);
      expect(const DialogueDraftCodec().decode(source), isNull);
      expect(const YarnDialogueCompiler().compile(raw).nodes, hasLength(2));
      final session = local();
      final before = session.current;
      await pump(tester);
      expect(find.text('Vraie source originale.'), findsOneWidget);
      expect(find.text('Suite originale.'), findsOneWidget);
      expect(find.text('Original avancé'), findsOneWidget);
      expect(
        find.textContaining('point de départ référencé est absent'),
        findsNothing,
      );
      expect(session.current, same(before));
      expect(session.readOnlySource, raw);
      expect(session.dirty, false);
      expect(port.reads, 0);
      expect(port.writes, 0);
    },
  );

  testWidgets(
    'editable local draft is shown without reading or publishing disk',
    (tester) async {
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
      await pump(tester);
      expect(find.text('Texte local récent.'), findsOneWidget);
      expect(find.textContaining('brouillon partagé'), findsOneWidget);
      expect(session.current, same(before));
      expect(session.dirty, true);
      expect(port.reads, 0);
      expect(port.writes, 0);
    },
  );

  testWidgets(
    'rapid navigation never displays an old source for another entry',
    (tester) async {
      const other = ProjectDialogueEntry(
        id: 'other',
        name: 'Autre',
        relativePath: 'other.yarn',
      );
      maps.project = maps.project!.copyWith(dialogues: [entry, other]);
      await pump(tester);
      await pump(tester, id: 'other');
      port.pending['advanced']!.complete(
        const NarrativeDialogueSource(entry: entry, source: raw),
      );
      await tester.pump();
      expect(find.text('Vraie source originale.'), findsNothing);
      port.pending['other']!.completeError(
        const NarrativeFailure('Source absente'),
      );
      await tester.pump();
      expect(find.textContaining('Source absente'), findsOneWidget);
      expect(find.text('Original avancé'), findsNothing);
      await pump(tester, id: 'missing');
      expect(find.textContaining('Dialogue indisponible'), findsOneWidget);
      expect(find.textContaining('Source absente'), findsNothing);
      expect(port.reads, 2);
      expect(port.writes, 0);
    },
  );

  testWidgets('new workspace identity cannot reuse the previous source cache', (
    tester,
  ) async {
    await pump(tester);
    port.pending['advanced']!.complete(
      const NarrativeDialogueSource(entry: entry, source: raw),
    );
    await tester.pump();
    expect(find.text('Vraie source originale.'), findsOneWidget);
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
    await pump(tester);
    expect(port.reads, 1);
    expect(find.text('Vraie source originale.'), findsNothing);
    port.pending['advanced']!.complete(
      NarrativeDialogueSource(
        entry: entry,
        source: raw.replaceAll(
          'Vraie source originale.',
          'Source de la nouvelle session.',
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Source de la nouvelle session.'), findsOneWidget);
    expect(find.text('Vraie source originale.'), findsNothing);
    expect(port.writes, 0);
  });

  testWidgets('missing start reports absence without picking another node', (
    tester,
  ) async {
    local();
    await pump(tester, start: 'Missing');
    expect(
      find.textContaining('point de départ référencé est absent'),
      findsOneWidget,
    );
    expect(find.text('Vraie source originale.'), findsOneWidget);
    expect(port.writes, 0);
  });
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
