import 'dart:async';

import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/dialogue_policy_publication_fixture.dart';

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

SceneNode _node(SceneEditSession session) =>
    session.current.graph.nodes.singleWhere((node) => node.id == 'talk');

SceneYarnDialoguePayload _payload(SceneEditSession session) =>
    _node(session).payload as SceneYarnDialoguePayload;

Future<bool> _retarget(
  SceneEditSession session, {
  String id = 'other',
  String start = 'Start',
  Future<RuntimeDialogueDocument> Function()? read,
  bool Function()? isActive,
}) => session.retargetDialogue(
  node: _node(session),
  original: _payload(session),
  target: ProjectDialogueEntry.fromJson({..._entry.toJson(), 'id': id}),
  start: start,
  outcomes: const ['yes', 'no', 'cancel'],
  read: read ?? () async => const YarnDialogueCompiler().compile(_source),
  isActive: isActive,
);

void main() {
  for (final newestFirst in [false, true]) {
    test(
      'latest retarget wins with newest completion first: $newestFirst',
      () async {
        final original = _scene();
        final session = SceneEditSession(original, base: original);
        final previous = Completer<RuntimeDialogueDocument>();
        final newest = Completer<RuntimeDialogueDocument>();
        final first = _retarget(session, read: () => previous.future);
        final last = _retarget(session, id: 'final', read: () => newest.future);
        final document = const YarnDialogueCompiler().compile(_source);
        if (newestFirst) {
          newest.complete(document);
          expect(await last, isTrue);
          previous.completeError(StateError('Lecture tardive refusée'));
        } else {
          previous.complete(document);
          expect(await first, isFalse);
          expect(session.current, original);
          newest.complete(document);
        }
        expect(await last, isTrue);
        expect(await first, isFalse);
        expect(_payload(session).dialogueId, 'final');
        expect(
          _payload(session).choicePolicies,
          (_node(SceneEditSession(original)).payload
                  as SceneYarnDialoguePayload)
              .choicePolicies,
        );
        expect(session.error, isNull);
        expect(session.undoCount, 1);
        session.restore(redo: false);
        expect(session.current, original);
      },
    );
  }

  test('retarget preserves policies, metadata, edges and one undo', () async {
    final original = _scene();
    final session = SceneEditSession(original, base: original);
    final payload = _payload(session);
    expect(await _retarget(session, start: 'Other'), isTrue);
    expect(_payload(session).dialogueId, 'other');
    expect(_payload(session).yarnNodeName, 'Other');
    expect(_payload(session).choicePolicies, payload.choicePolicies);
    expect(_payload(session).linePolicies, payload.linePolicies);
    expect(_payload(session).declaredCancellationOutcomes, ['cancel']);
    expect(_payload(session).expectedOutcomes, ['yes', 'no', 'cancel']);
    expect(session.current.graph.edges, original.graph.edges);
    expect(session.current.metadata, original.metadata);
    expect(session.undoCount, 1);
    session.restore(redo: false);
    expect(session.current, original);
  });

  test(
    'incompatible retarget preserves draft, project bytes and Yarn',
    () async {
      final fixture = await DialoguePolicyPublicationFixture.create();
      addTearDown(() => fixture.root.delete(recursive: true));
      final projectBefore = await fixture.projectFile.readAsBytes();
      final yarnBefore = await fixture.sourceFile.readAsBytes();
      final original = fixture.project.scenes.single;
      final session = SceneEditSession(original, base: original);
      expect(
        await _retarget(
          session,
          read: () async => const YarnDialogueCompiler().compile(
            'title: Start\n---\nVide.\n===\n',
          ),
        ),
        isFalse,
      );
      expect(session.current, original);
      expect(session.canUndo, isFalse);
      expect(session.error, isNotNull);
      expect(await fixture.projectFile.readAsBytes(), projectBefore);
      expect(await fixture.sourceFile.readAsBytes(), yarnBefore);
      expect(
        (await fixture.maps.loadProject(fixture.session)).scenes.single,
        original,
      );
    },
  );

  test('a payload changed during reading refuses the stale retarget', () async {
    final session = SceneEditSession(_scene());
    final pending = Completer<RuntimeDialogueDocument>();
    final retarget = _retarget(session, read: () => pending.future);
    final node = _node(session);
    session.replacePayload(
      node,
      SceneYarnDialoguePayload.fromJson({
        ..._payload(session).toJson(),
        'speakerHints': ['new'],
      }),
    );
    final edited = session.current;
    pending.complete(const YarnDialogueCompiler().compile(_source));
    expect(await retarget, isFalse);
    expect(session.current, edited);
    expect(session.undoCount, 1);
    expect(session.error, isNotNull);
  });

  for (final cancelReads in [false, true]) {
    test(
      'inactive request cannot publish or report errors: cancel $cancelReads',
      () async {
        final original = _scene();
        final session = SceneEditSession(original);
        final pending = Completer<RuntimeDialogueDocument>();
        var active = true;
        final retarget = _retarget(
          session,
          read: () => pending.future,
          isActive: () => active,
        );
        if (cancelReads) {
          session.cancelDialogueReads();
        } else {
          active = false;
        }
        pending.completeError(StateError('Fermé'));
        expect(await retarget, isFalse);
        expect(session.current, original);
        expect(session.error, isNull);
        expect(session.canUndo, isFalse);
      },
    );
  }

  test(
    'missing reader retains policies while a plain link can retarget',
    () async {
      final session = SceneEditSession(_scene());
      final node = _node(session);
      expect(
        await session.retargetDialogue(
          node: node,
          original: _payload(session),
          target: _entry,
          start: 'Other',
          outcomes: const [],
        ),
        isFalse,
      );
      expect(session.canUndo, isFalse);
      session.replacePayload(
        node,
        SceneYarnDialoguePayload(dialogueId: 'guide'),
      );
      final before = session.current;
      final plain = _node(session);
      expect(
        await session.retargetDialogue(
          node: plain,
          original: _payload(session),
          target: _entry,
          start: 'Other',
          outcomes: const ['yes'],
        ),
        isTrue,
      );
      expect(_payload(session).yarnNodeName, 'Other');
      expect(_payload(session).expectedOutcomes, ['yes']);
      session.restore(redo: false);
      expect(session.current, before);
    },
  );

  test('public outcome ids avoid collisions and undo preserves prior data', () {
    final original = SceneAsset.fromJson({
      ..._scene().toJson(),
      'declaredOutcomes': [
        SceneOutcome(id: 'result_3', label: 'Ancien').toJson(),
        SceneOutcome(id: 'other', label: 'Autre').toJson(),
      ],
    });
    final session = SceneEditSession(original);
    expect(session.addOutcome(''), isFalse);
    expect(session.addOutcome('Nouveau'), isTrue);
    expect(session.current.declaredOutcomes.last.id, 'result_4');
    expect(session.current.declaredOutcomes.take(2), original.declaredOutcomes);
    expect(session.undoCount, 1);
    session.restore(redo: false);
    expect(session.current, original);
  });
}
