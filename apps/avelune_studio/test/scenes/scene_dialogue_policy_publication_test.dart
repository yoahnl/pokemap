import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_inspector.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_linked_document.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

const _source = '''
title: Start
---
Bonjour.
Une autre ligne.
-> Oui
    <<outcome yes>>
-> Non
    <<outcome no>>
===
''';

const _entry = ProjectDialogueEntry(
  id: 'guide',
  name: 'Conversation du guide',
  relativePath: 'dialogues/guide.yarn',
  defaultStartNode: 'Start',
  declaredOutcomes: [
    DialogueDeclaredOutcome(id: 'yes', label: 'Accepter'),
    DialogueDeclaredOutcome(id: 'no', label: 'Refuser'),
  ],
);

const _empty = ProjectDialogueEntry(
  id: 'empty',
  name: 'Document sans choix',
  relativePath: 'dialogues/empty.yarn',
  defaultStartNode: 'Start',
);

void main() {
  testWidgets(
    'inspector policy edits publish through scene.upsert and cold reopen without loss',
    (tester) async {
      final fixture = (await tester.runAsync(_Fixture.create))!;
      addTearDown(() => fixture.root.delete(recursive: true));
      final session = await _mount(tester, fixture);
      final original = session.current;
      final before = _payload(original);
      final sourceBefore = (await tester.runAsync(
        fixture.sourceFile.readAsBytes,
      ))!;

      await _expand(tester, 'Comportement des choix');
      await _pick(tester, 'scene-choice-default', 'no');
      await _pick(tester, 'scene-choice-cancellation', 'disabled');
      await _tap(tester, find.byKey(const ValueKey('scene-choice-apply')));
      expect(session.error, isNull);
      expect(
        _payload(session.current).choicePolicies.single.defaultOutcomeId,
        'no',
      );
      expect(
        _payload(session.current).choicePolicies.single.cancellation.kind,
        SceneDialogueChoiceCancellationKind.disabled,
      );
      expect(_payload(session.current).linePolicies, before.linePolicies);

      await _expand(tester, 'Rythme et son des lignes');
      final cadence = find.descendant(
        of: find.byKey(const ValueKey('scene-line-reveal-ms')),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(cadence);
      await tester.enterText(cadence, '17.125');
      await tester.pump();
      await _tap(tester, find.byKey(const ValueKey('scene-line-apply')));
      expect(session.error, isNull);
      expect(session.undoCount, 2);
      final edited = _payload(session.current);
      expect(edited.linePolicies.first.feedback.revealIntervalMicros, 17125);
      expect(
        edited.linePolicies.first.feedback.segments,
        before.linePolicies.first.feedback.segments,
      );
      expect(
        edited.linePolicies.first.feedback.advance,
        before.linePolicies.first.feedback.advance,
      );
      expect(edited.linePolicies.last, before.linePolicies.last);
      expect(
        edited.declaredCancellationOutcomes,
        before.declaredCancellationOutcomes,
      );
      expect(edited.expectedOutcomes, before.expectedOutcomes);
      expect(session.current.graph.edges, original.graph.edges);
      expect(session.current.layout, original.layout);
      expect(session.current.metadata, original.metadata);

      final receipt = (await tester.runAsync(
        () => LocalSceneAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
        ).publishScene(base: original, current: session.current),
      ))!;
      expect(receipt.catalog.changedPaths, ['project.json']);
      expect(receipt.scene, session.current);
      final reopenedMaps = LocalMapWorkspaceAdapter();
      final reopened = (await tester.runAsync(
        () => reopenedMaps.loadProject(fixture.session),
      ))!;
      expect(reopened.scenes.single, session.current);
      expect(
        _payload(reopened.scenes.single).choicePolicies,
        edited.choicePolicies,
      );
      expect(
        _payload(reopened.scenes.single).linePolicies,
        edited.linePolicies,
      );
      expect(
        await tester.runAsync(fixture.sourceFile.readAsBytes),
        sourceBefore,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      final coldFixture = _Fixture(
        fixture.root,
        fixture.session,
        reopenedMaps,
        reopened,
      );
      final coldSession = await _mount(tester, coldFixture);
      await _expand(tester, 'Comportement des choix');
      expect(_select(tester, 'scene-choice-default').value, 'no');
      expect(_select(tester, 'scene-choice-cancellation').value, 'disabled');
      await _expand(tester, 'Rythme et son des lignes');
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const ValueKey('scene-line-reveal-ms')),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        '17.125',
      );
      expect(coldSession.current, session.current);
      expect(coldSession.dirty, isFalse);
    },
  );

  testWidgets('incompatible inspector retarget preserves the draft and disk', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(_Fixture.create))!;
    addTearDown(() => fixture.root.delete(recursive: true));
    final session = await _mount(tester, fixture);
    final original = session.current;
    final diskBefore = (await tester.runAsync(
      fixture.projectFile.readAsBytes,
    ))!;
    final picker = find
        .ancestor(
          of: find.text('Document de dialogue'),
          matching: find.byType(DropdownButtonFormField<String>),
        )
        .first;
    await _tap(tester, picker);
    await _tap(tester, find.text(_empty.name).last);
    expect(session.current, original);
    expect(session.error, isNotNull);
    expect(session.dirty, isFalse);
    expect(session.canUndo, isFalse);
    expect(await tester.runAsync(fixture.projectFile.readAsBytes), diskBefore);
  });
}

StudioSelect _select(WidgetTester tester, String key) =>
    tester.widget<StudioSelect>(find.byKey(ValueKey(key)));

Future<void> _pick(WidgetTester tester, String key, String value) async {
  final label = _select(tester, key).options[value]!;
  await _tap(tester, find.byKey(ValueKey(key)));
  await _tap(tester, find.text(label).last);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

Future<void> _expand(WidgetTester tester, String title) =>
    _tap(tester, find.text(title));

Future<SceneEditSession> _mount(WidgetTester tester, _Fixture fixture) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final scene = fixture.project.scenes.single;
  final session = SceneEditSession(scene, base: scene);
  final workspace = MapWorkspaceController(fixture.session, fixture.maps)
    ..project = fixture.project;
  final narrative = NarrativeWorkspaceController(
    workspace,
    LocalNarrativeAdapter(session: fixture.session, mapAdapter: fixture.maps),
    () {},
    (_, _) async {},
  );
  addTearDown(narrative.dispose);
  addTearDown(workspace.dispose);
  final documents = SceneLinkedDocuments();
  await tester.runAsync(() async {
    for (final entry in fixture.project.dialogues) {
      await documents.readDialogueDocument(
        entry.id,
        fixture.project,
        narrative,
      );
    }
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: SizedBox(
          width: 580,
          child: StatefulBuilder(
            builder: (context, setState) => SceneInspector(
              session: session,
              project: fixture.project,
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
  await _settle(tester);
  return session;
}

SceneYarnDialoguePayload _payload(SceneAsset scene) =>
    scene.graph.nodes.singleWhere((node) => node.id == 'talk').payload
        as SceneYarnDialoguePayload;

SceneAsset _scene() => SceneAsset(
  id: 'meeting',
  name: 'Rencontre du guide',
  metadata: const {'original': 'synthetic'},
  layout: SceneGraphLayout(
    nodeLayouts: [SceneNodeLayout(nodeId: 'talk', x: 150, y: 80)],
    edgeLayouts: [SceneEdgeLayout(edgeId: 'cancel')],
  ),
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'talk',
        kind: SceneNodeKind.yarnDialogue,
        title: 'Dialogue du guide',
        payload: SceneYarnDialoguePayload(
          dialogueId: 'guide',
          yarnNodeName: 'Start',
          expectedOutcomes: const ['yes', 'no', 'cancel'],
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
                segments: [
                  DialogueTextSegment(
                    'Bonjour.',
                    style: DialogueSegmentStyle(colorArgb: 0xff123456),
                  ),
                ],
                revealIntervalMicros: 25000,
                advance: DialogueLineAdvancePolicy.autoAfterReveal(250000),
              ),
            ),
            SceneDialogueLinePolicy(
              nodeName: 'Start',
              lineIndex: 1,
              feedback: DialogueLineFeedback(revealIntervalMicros: 40000),
            ),
          ],
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start-talk',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'talk',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'completed',
        fromNodeId: 'talk',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final outcome in ['yes', 'no', 'cancel'])
        SceneEdge(
          id: outcome,
          fromNodeId: 'talk',
          fromPortId: outcome,
          toNodeId: 'end',
          kind: SceneEdgeKind.dialogueOutcome,
        ),
    ],
  ),
);

class _Fixture {
  _Fixture(this.root, this.session, this.maps, this.project);
  final Directory root;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter maps;
  final ProjectManifest project;
  File get projectFile => File('${root.path}/project.json');
  File get sourceFile => File('${root.path}/${_entry.relativePath}');

  static Future<_Fixture> create() async {
    final temporary = await Directory.systemTemp.createTemp(
      'dialogue_policy_publication_',
    );
    final root = Directory(await temporary.resolveSymbolicLinks());
    await Directory('${root.path}/dialogues').create();
    final project = ProjectManifest(
      name: 'Politiques du guide',
      maps: const [],
      tilesets: const [],
      dialogues: const [_entry, _empty],
      scenes: [_scene()],
    );
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    await File('${root.path}/${_entry.relativePath}').writeAsString(_source);
    await File('${root.path}/${_empty.relativePath}')
        .writeAsString('title: Start\n---\nSans choix.\n===\n');
    final session = ProjectSession(
      sessionId: root.path,
      name: project.name,
      directoryPath: root.path,
    );
    final maps = LocalMapWorkspaceAdapter();
    return _Fixture(root, session, maps, await maps.loadProject(session));
  }
}
