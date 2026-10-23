import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_inspector.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_linked_document.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

const _source = '''
title: Start
---
Bonjour.
-> Oui
    <<outcome yes>>
-> Non
    <<outcome no>>
===
title: Other
---
Un autre départ.
===
''';

const _entry = ProjectDialogueEntry(
  id: 'guide',
  name: 'Guide',
  relativePath: 'guide.yarn',
  defaultStartNode: 'Start',
  declaredOutcomes: [
    DialogueDeclaredOutcome(id: 'yes', label: 'Accepter'),
    DialogueDeclaredOutcome(id: 'no', label: 'Refuser'),
  ],
);

SceneAsset _scene() => SceneAsset(
  id: 'meeting',
  name: 'Rencontre',
  metadata: const {'author': 'test'},
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(
        id: 'start',
        kind: SceneNodeKind.start,
        payload: SceneStartPayload(),
      ),
      SceneNode(
        id: 'talk',
        kind: SceneNodeKind.yarnDialogue,
        title: 'Parler au guide',
        payload: SceneYarnDialoguePayload(
          dialogueId: 'guide',
          yarnNodeName: 'Start',
          expectedOutcomes: const ['yes', 'no', 'cancel'],
          speakerHints: const ['guide'],
          choicePolicies: const [
            SceneDialogueChoicePolicy(
              nodeName: 'Start',
              defaultOutcomeId: 'yes',
              cancellation: SceneDialogueChoiceCancellation.branch('cancel'),
            ),
          ],
          linePolicies: [
            SceneDialogueLinePolicy(
              nodeName: 'Start',
              lineIndex: 0,
              feedback: DialogueLineFeedback(
                segments: [DialogueTextSegment('Bonjour.')],
                revealIntervalMicros: 25000,
                advance: DialogueLineAdvancePolicy.autoAfterReveal(250000),
              ),
            ),
          ],
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end, payload: SceneEndPayload()),
    ],
    edges: [
      SceneEdge(
        id: 'start-talk',
        fromNodeId: 'start',
        fromPortId: 'next',
        toNodeId: 'talk',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final outcome in ['yes', 'no', 'cancel'])
        SceneEdge(
          id: 'talk-$outcome',
          fromNodeId: 'talk',
          fromPortId: outcome,
          toNodeId: 'end',
          kind: SceneEdgeKind.dialogueOutcome,
        ),
    ],
  ),
);

void main() {
  for (final newestFirst in [false, true]) {
    testWidgets(
      'latest document selection wins when newest completes first: $newestFirst',
      (tester) async {
        final previous = Completer<NarrativeDialogueSource>();
        final newest = Completer<NarrativeDialogueSource>();
        final port = _DelayedPort(previous, newest);
        final (session, original) = await _mount(tester, port: port);
        await _select(tester, 'Document de dialogue', 'Autre guide');
        await _select(tester, 'Document de dialogue', 'Guide final');
        if (newestFirst) {
          newest.complete(
            NarrativeDialogueSource(
              entry: _other('final', 'Guide final'),
              source: _source,
            ),
          );
          await tester.pumpAndSettle();
          previous.completeError(StateError('Lecture tardive refusée'));
        } else {
          previous.complete(
            NarrativeDialogueSource(
              entry: _other('other', 'Autre guide'),
              source: _source,
            ),
          );
          await tester.pumpAndSettle();
          expect(session.current, original);
          newest.complete(
            NarrativeDialogueSource(
              entry: _other('final', 'Guide final'),
              source: _source,
            ),
          );
        }
        await tester.pumpAndSettle();
        expect(_payload(session).dialogueId, 'final');
        expect(
          _payload(session).choicePolicies,
          _originalPayload(original).choicePolicies,
        );
        expect(session.error, isNull);
        expect(session.undoCount, 1);
      },
    );
  }
  testWidgets(
    'changing the linked start preserves every dialogue policy and undo',
    (tester) async {
      final (session, original) = await _mount(tester);
      await _select(tester, 'Départ du dialogue', 'Other');
      expect(_payload(session).yarnNodeName, 'Other');
      expect(
        _payload(session).choicePolicies,
        _originalPayload(original).choicePolicies,
      );
      expect(
        _payload(session).linePolicies,
        _originalPayload(original).linePolicies,
      );
      expect(_payload(session).declaredCancellationOutcomes, ['cancel']);
      expect(session.current.graph.edges, original.graph.edges);
      expect(session.current.metadata, original.metadata);
      expect(session.undoCount, 1);
      session.restore(redo: false);
      expect(session.current, original);
    },
  );

  testWidgets(
    'replacing with a compatible document retains cancellation and feedback',
    (tester) async {
      final (session, original) = await _mount(tester);
      await _select(tester, 'Document de dialogue', 'Autre guide');
      expect(_payload(session).dialogueId, 'other');
      expect(
        _payload(session).choicePolicies,
        _originalPayload(original).choicePolicies,
      );
      expect(
        _payload(session).linePolicies,
        _originalPayload(original).linePolicies,
      );
      expect(_payload(session).expectedOutcomes, ['yes', 'no', 'cancel']);
      expect(session.current.graph.edges, original.graph.edges);
      expect(session.error, isNull);
    },
  );

  testWidgets(
    'an incompatible document is rejected without losing the saved policies',
    (tester) async {
      final (session, original) = await _mount(tester);
      await _select(tester, 'Document de dialogue', 'Sans choix');
      expect(session.current, original);
      expect(session.error, isNotNull);
      expect(session.canUndo, isFalse);
    },
  );
}

SceneYarnDialoguePayload _payload(SceneEditSession s) =>
    _originalPayload(s.current);
SceneYarnDialoguePayload _originalPayload(SceneAsset s) =>
    s.graph.nodes.singleWhere((n) => n.id == 'talk').payload
        as SceneYarnDialoguePayload;

ProjectDialogueEntry _other(String id, String name) =>
    ProjectDialogueEntry.fromJson({
      ..._entry.toJson(),
      'id': id,
      'name': name,
      'relativePath': '$id.yarn',
    });

Future<(SceneEditSession, SceneAsset)> _mount(
  WidgetTester tester, {
  NarrativePort? port,
}) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final original = _scene();
  final session = SceneEditSession(original, base: original);
  final other = _other('other', 'Autre guide');
  final newest = _other('final', 'Guide final');
  const empty = ProjectDialogueEntry(
    id: 'empty',
    name: 'Sans choix',
    relativePath: 'empty.yarn',
  );
  final project = ProjectManifest(
    name: 'Politiques',
    maps: const [],
    tilesets: const [],
    scenes: [original],
    dialogues: [_entry, other, newest, empty],
  );
  final maps = MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
    ..project = project;
  addTearDown(maps.dispose);
  final sourcePort =
      port ??
      _Port({
        'guide': const NarrativeDialogueSource(entry: _entry, source: _source),
        'other': NarrativeDialogueSource(entry: other, source: _source),
        'final': NarrativeDialogueSource(entry: newest, source: _source),
        'empty': const NarrativeDialogueSource(
          entry: empty,
          source: 'title: Start\n---\nVide.\n===\n',
        ),
      });
  final narrative = NarrativeWorkspaceController(
    maps,
    sourcePort,
    () {},
    (_, _) async {},
  );
  final documents = SceneLinkedDocuments();
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: SizedBox(
          width: 520,
          child: StatefulBuilder(
            builder: (context, setState) => SceneInspector(
              session: session,
              project: project,
              nodeId: 'talk',
              edgeId: null,
              documents: documents,
              narrative: narrative,
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
  await tester.pumpAndSettle();
  return (session, original);
}

Future<void> _select(WidgetTester tester, String label, String value) async {
  final field = find
      .ancestor(
        of: find.text(label),
        matching: find.byType(DropdownButtonFormField<String>),
      )
      .first;
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}

class _Port implements NarrativePort {
  _Port(this.sources);
  final Map<String, NarrativeDialogueSource> sources;

  @override
  Future<NarrativeDialogueSource> readDialogue(
    ProjectDialogueEntry entry,
  ) async => sources[entry.id]!;

  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) => throw StateError('Inspector drafts do not publish');
}

class _DelayedPort implements NarrativePort {
  _DelayedPort(this.previous, this.newest);
  final Completer<NarrativeDialogueSource> previous, newest;

  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) =>
      switch (entry.id) {
        'other' => previous.future,
        'final' => newest.future,
        _ => Future.value(
          const NarrativeDialogueSource(entry: _entry, source: _source),
        ),
      };

  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) => throw StateError('Read only');
}
