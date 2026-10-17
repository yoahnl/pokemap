import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_dialogue_results.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionCheckpoint;
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core.dart';

import '../support/dialogue_adapter_fixture.dart';

const _source = '''
title: Accueil
---
Bonjour !
Deuxième réplique.
-> Oui
    <<outcome yes>>
-> Non
    <<outcome no>>
===
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'only text changes with the complete stable editor shape produce intents',
    () {
      final session = _workingSession();
      final next = session.current.clone();
      final line = next.document.nodes.first.steps
          .whereType<DeLineStep>()
          .first;
      line.body = 'Bonsoir !';
      session.change(next);
      expect(session.lineTextEdits, [
        DialogueLineTextEdit(
          nodeName: 'Accueil',
          lineIndex: 0,
          beforeText: 'Bonjour !',
          afterText: 'Bonsoir !',
        ),
      ]);
      session.restore(false);
      expect(session.lineTextEdits, isNull);
      session.restore(true);
      expect(session.lineTextEdits!.single.afterText, 'Bonsoir !');
    },
  );

  test('same-count identity tree metadata and choice changes cannot infer text intents', () {
    final mutations = <void Function(DialogueEditorDocument)>[
      (document) => document.nodes.first.title = 'Renamed',
      (document) => document.nodes.first.headers.add(
        const DialogueEditorNodeHeader(name: 'tags', value: 'changed'),
      ),
      (document) =>
          document.nodes.first.steps.whereType<DeLineStep>().first.speaker =
              'Other',
      (document) =>
          document.nodes.first.steps.whereType<DeLineStep>().first.characterId =
              'Other',
      (document) {
        final steps = document.nodes.first.steps;
        final first = steps.indexWhere((step) => step is DeLineStep);
        final line = steps.removeAt(first);
        steps.insert(first + 1, line);
      },
      (document) {
        final steps = document.nodes.first.steps;
        final first = steps.indexWhere((step) => step is DeLineStep);
        steps[first] = DeLineStep(id: newDialogueEditorId(), body: 'Bonsoir !');
      },
      (document) {
        final choice = document.nodes.first.steps
            .whereType<DeChoiceStep>()
            .single;
        choice.branches = choice.branches.reversed.toList();
      },
      (document) =>
          document.nodes.first.steps
                  .whereType<DeChoiceStep>()
                  .single
                  .branches
                  .first
                  .label =
              'Changed',
      (document) =>
          document.nodes.first.steps
                  .whereType<DeChoiceStep>()
                  .single
                  .branches
                  .first
                  .outcomeId =
              'no',
      (document) => document.nodes.first.steps.add(
        DeLineStep(id: newDialogueEditorId(), body: 'Inserted'),
      ),
      (document) => document.nodes.first.steps.removeWhere(
        (step) => step is DeChoiceStep,
      ),
    ];
    for (final mutate in mutations) {
      final session = _workingSession();
      final next = session.current.clone();
      next.document.nodes.first.steps.whereType<DeLineStep>().first.body =
          'Bonsoir !';
      mutate(next.document);
      session.change(next);
      expect(session.lineTextEdits, isNull);
    }
  });

  late DialogueAdapterFixture f;
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;
  late SceneWorkspaceController scenes;
  late DialogueWorkspaceController dialogues;

  setUp(() async {
    f = await DialogueAdapterFixture.create();
    final original = await f.readManifest();
    final entry = DialogueAdapterFixture.entry.copyWith(
      declaredOutcomes: const [
        DialogueDeclaredOutcome(id: 'yes', label: 'Oui'),
        DialogueDeclaredOutcome(id: 'no', label: 'Non'),
      ],
    );
    await f.file(entry.relativePath).writeAsString(_source);
    await f.writeManifest(
      original.copyWith(dialogues: [entry], scenes: [_scene()]),
    );
    maps = MapWorkspaceController(f.session, f.maps);
    await maps.initialize();
    narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: f.session, mapAdapter: f.maps),
      () {},
      (_, _) async {},
    );
    scenes = SceneWorkspaceController(
      maps,
      LocalSceneAdapter(session: f.session, mapAdapter: f.maps),
      narrative: narrative,
      changed: () {},
    );
    dialogues = DialogueWorkspaceController(
      narrative,
      LocalDialogueAdapter(session: f.session, mapAdapter: f.maps),
      changed: () {},
      sceneDrafts: () => scenes.sessions.values.map((s) => s.current).toList(),
    );
    dialogues.onPublished = (id, revision) => scenes.refreshDialogueResults(id);
  });

  tearDown(() async {
    dialogues.dispose();
    scenes.dispose();
    narrative.dispose();
    maps.dispose();
    await f.dispose();
  });

  for (final checkpoint in [
    AuthoringTransactionCheckpoint.beforeResourcePromotion,
    AuthoringTransactionCheckpoint.afterResourcePromoted,
  ]) {
    test(
      'adapter returns coherent source and policies after ordinary $checkpoint failure',
      () async {
        var failed = false;
        final port = f.adapter(
          faultInjector: (context) {
            if (!failed &&
                context.checkpoint == checkpoint &&
                context.promotionIndex == 0) {
              failed = true;
              throw StateError('ordinary publication failure');
            }
          },
        );
        final base = await port.load('gare');
        final before = (await f.readManifest()).scenes.single;
        final source = _source.replaceFirst('Bonjour !', 'Bonsoir !');
        final receipt = await port.publish(
          id: 'gare',
          base: base,
          entry: base.entry,
          source: source,
          lineTextEdits: [
            DialogueLineTextEdit(
              nodeName: 'Accueil',
              lineIndex: 0,
              beforeText: 'Bonjour !',
              afterText: 'Bonsoir !',
            ),
          ],
        );
        expect(failed, isTrue);
        expect(receipt.resources.changedPaths.toSet(), {
          'project.json',
          base.entry.relativePath,
        });
        expect(receipt.snapshot!.source, source);
        expect(await f.file(base.entry.relativePath).readAsString(), source);
        final disk = await f.readManifest();
        expect(receipt.resources.manifest, disk);
        expect(
          _payload(disk.scenes.single).linePolicies.last,
          _payload(before).linePolicies.last,
        );
        expect(
          (_payload(disk.scenes.single)
                      .linePolicies
                      .first
                      .feedback
                      .segments
                      .single
                  as DialogueTextSegment)
              .text,
          'Bonsoir !',
        );
        expect((await port.load('gare')).revision, receipt.snapshot!.revision);
      },
    );
  }

  test(
    'refreshing results retains every line choice and cancellation policy',
    () {
      expect(scenes.open('scene'), isTrue);
      final before = scenes.active!.current;
      scenes.refreshDialogueResults('gare');
      expect(scenes.active!.current, before);
      expect(scenes.active!.dirty, isFalse);
      expect(scenes.active!.canUndo, isFalse);
    },
  );

  test(
    'text publication reconciles a clean scene before refresh and save reopen',
    () async {
      expect(scenes.open('scene'), isTrue);
      final before = scenes.active!.current;
      expect(await dialogues.open('gare'), isTrue, reason: dialogues.error);
      final line = dialogues.active!.document.nodes.single.steps
          .whereType<DeLineStep>()
          .first;
      expect(dialogues.updateLine(line.id, text: 'Bonsoir !'), isTrue);
      expect(await dialogues.save(), isTrue, reason: dialogues.error);
      expect(dialogues.active!.dirty, isFalse);
      final canonical = (await f.readManifest()).scenes.single;
      expect(scenes.active!.current, canonical);
      expect(scenes.active!.base, canonical);
      expect(scenes.active!.dirty, isFalse);
      expect(scenes.active!.canUndo, isFalse);
      final afterPayload = _payload(canonical);
      final beforePayload = _payload(before);
      final feedback = afterPayload.linePolicies.first.feedback;
      expect(
        feedback.segments.single,
        DialogueTextSegment(
          'Bonsoir !',
          style:
              (beforePayload.linePolicies.first.feedback.segments.single
                      as DialogueTextSegment)
                  .style,
        ),
      );
      expect(
        feedback.revealIntervalMicros,
        beforePayload.linePolicies.first.feedback.revealIntervalMicros,
      );
      expect(afterPayload.linePolicies.last, beforePayload.linePolicies.last);
      expect(afterPayload.choicePolicies, beforePayload.choicePolicies);
      expect(
        afterPayload.declaredCancellationOutcomes,
        beforePayload.declaredCancellationOutcomes,
      );
      expect(afterPayload.expectedOutcomes, beforePayload.expectedOutcomes);
      expect(canonical.graph.edges, before.graph.edges);
      expect(scenes.active!.rename('Scène renommée après traduction'), isTrue);
      expect(await scenes.save(), isTrue, reason: scenes.error);
      expect(scenes.discard('scene'), isTrue);
      expect(scenes.open('scene'), isTrue);
      expect(_payload(scenes.active!.current), afterPayload);
      expect(await dialogues.reload(), isTrue, reason: dialogues.error);
      expect(
        dialogues.active!.document.nodes.single.steps
            .whereType<DeLineStep>()
            .first
            .id,
        line.id,
      );
      expect(dialogues.active!.source, contains('Bonsoir !'));
    },
  );

  test('renaming a dialogue with text edits publishes both through dialogue update', () async {
    expect(scenes.open('scene'), isTrue);
    final before = scenes.active!.current;
    final beforePayload = _payload(before);
    expect(await dialogues.open('gare'), isTrue, reason: dialogues.error);
    final line = dialogues.active!.document.nodes.single.steps
        .whereType<DeLineStep>()
        .first;
    expect(dialogues.rename('Conversation traduite'), isTrue);
    expect(dialogues.updateLine(line.id, text: 'Bonsoir !'), isTrue);
    expect(await dialogues.save(), isTrue, reason: dialogues.error);

    final disk = await f.readManifest();
    expect(disk.dialogues.single.name, 'Conversation traduite');
    expect(dialogues.active!.dirty, isFalse);
    expect(scenes.active!.current, disk.scenes.single);
    expect(scenes.active!.dirty, isFalse);
    final afterPayload = _payload(disk.scenes.single);
    expect(
      afterPayload.linePolicies.first.feedback,
      beforePayload.linePolicies.first.feedback.mapText((_) => 'Bonsoir !'),
    );
    expect(afterPayload.linePolicies.last, beforePayload.linePolicies.last);
    expect(afterPayload.choicePolicies, beforePayload.choicePolicies);
    expect(
      afterPayload.declaredCancellationOutcomes,
      beforePayload.declaredCancellationOutcomes,
    );
    expect(afterPayload.expectedOutcomes, beforePayload.expectedOutcomes);
    expect(disk.scenes.single.graph.edges, before.graph.edges);
    expect(await dialogues.reload(), isTrue, reason: dialogues.error);
    expect(dialogues.active!.entry.name, 'Conversation traduite');
    expect(dialogues.active!.source, contains('Bonsoir !'));
  });

  test(
    'a linked dirty scene refuses publication and retains both drafts',
    () async {
      expect(scenes.open('scene'), isTrue);
      expect(scenes.active!.rename('Brouillon de scène à garder'), isTrue);
      final sceneDraft = scenes.active!.current;
      final projectBytes = await f.file('project.json').readAsBytes();
      expect(await dialogues.open('gare'), isTrue, reason: dialogues.error);
      final line = dialogues.active!.document.nodes.single.steps
          .whereType<DeLineStep>()
          .first;
      expect(dialogues.updateLine(line.id, text: 'Bonsoir !'), isTrue);
      expect(await dialogues.save(), isFalse);
      expect(dialogues.error, contains('brouillon'));
      expect(dialogues.active!.dirty, isTrue);
      expect(scenes.active!.current, sceneDraft);
      expect(scenes.active!.dirty, isTrue);
      expect(await f.file('project.json').readAsBytes(), projectBytes);
      expect(
        await f.file(DialogueAdapterFixture.entry.relativePath).readAsString(),
        _source,
      );
    },
  );

  test(
    'an unrelated dirty scene survives the linked text publication',
    () async {
      expect(scenes.open('scene'), isTrue);
      final linked = scenes.active!;
      final other = scenes.create('Brouillon sans rapport')!;
      final draft = other.current;
      expect(await dialogues.open('gare'), isTrue, reason: dialogues.error);
      final line = dialogues.active!.document.nodes.single.steps
          .whereType<DeLineStep>()
          .first;
      dialogues.updateLine(line.id, text: 'Bonsoir !');
      expect(await dialogues.save(), isTrue, reason: dialogues.error);
      expect(other.current, draft);
      expect(other.dirty, isTrue);
      expect(linked.dirty, isFalse);
      expect(
        _payload(linked.current).linePolicies.first.feedback.segments.single,
        isA<DialogueTextSegment>().having((s) => s.text, 'text', 'Bonsoir !'),
      );
    },
  );

  test(
    'moving stable line identities cannot masquerade as two text edits',
    () async {
      final projectBytes = await f.file('project.json').readAsBytes();
      expect(await dialogues.open('gare'), isTrue, reason: dialogues.error);
      final lines = dialogues.active!.document.nodes.single.steps
          .whereType<DeLineStep>()
          .toList();
      expect(lines.length, 2);
      expect(dialogues.moveStep(lines.first.id, 1), isTrue);
      expect(
        dialogues.active!.document.nodes.single.steps
            .whereType<DeLineStep>()
            .first
            .id,
        lines.last.id,
      );
      expect(await dialogues.save(), isFalse);
      expect(await f.file('project.json').readAsBytes(), projectBytes);
      expect(
        await f.file(DialogueAdapterFixture.entry.relativePath).readAsString(),
        _source,
      );
      expect(dialogues.active!.dirty, isTrue);
    },
  );
}

DialogueWorkingSession _workingSession() {
  final entry = DialogueAdapterFixture.entry.copyWith(
    declaredOutcomes: const [
      DialogueDeclaredOutcome(id: 'yes', label: 'Oui'),
      DialogueDeclaredOutcome(id: 'no', label: 'Non'),
    ],
  );
  final document = reconcileDialogueDocumentIds(
    parseYarnToDocument(_source, entryNodeTitle: 'Accueil'),
  );
  return DialogueWorkingSession(
    DialogueWorkingState(entry, document),
    DialogueSourceSnapshot(entry: entry, source: _source, revision: 'test'),
  );
}

SceneYarnDialoguePayload _payload(SceneAsset scene) =>
    scene.graph.nodes.singleWhere((node) => node.id == 'dialogue').payload
        as SceneYarnDialoguePayload;

SceneAsset _scene() => SceneAsset(
  id: 'scene',
  name: 'Scène avec politiques',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'dialogue',
        kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(
          dialogueId: 'gare',
          yarnNodeName: 'Accueil',
          expectedOutcomes: const ['yes', 'no', 'cancel'],
          declaredCancellationOutcomes: const ['cancel'],
          choicePolicies: const [
            SceneDialogueChoicePolicy(
              nodeName: 'Accueil',
              defaultOutcomeId: 'yes',
              cancellation: SceneDialogueChoiceCancellation.branch('cancel'),
            ),
          ],
          linePolicies: [
            SceneDialogueLinePolicy(
              nodeName: 'Accueil',
              lineIndex: 0,
              feedback: DialogueLineFeedback(
                segments: [
                  DialogueTextSegment(
                    'Bonjour !',
                    style: DialogueSegmentStyle(
                      colorArgb: 0xff3050c8,
                      shadowColorArgb: 0xffd0d0c8,
                    ),
                  ),
                ],
                revealIntervalMicros: 25000,
              ),
            ),
            SceneDialogueLinePolicy(
              nodeName: 'Accueil',
              lineIndex: 1,
              feedback: DialogueLineFeedback(
                segments: [
                  DialogueTextSegment(
                    'Deuxième ',
                    style: DialogueSegmentStyle(colorArgb: 0xff3050c8),
                  ),
                  DialogueTextSegment('réplique.'),
                ],
              ),
            ),
          ],
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'entry',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'dialogue',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'complete',
        fromNodeId: 'dialogue',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final id in ['yes', 'no', 'cancel'])
        SceneEdge(
          id: id,
          fromNodeId: 'dialogue',
          fromPortId: id,
          toNodeId: 'end',
          kind: SceneEdgeKind.dialogueOutcome,
        ),
    ],
  ),
);
