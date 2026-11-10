import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_dialogue_choice_policy_draft.dart';
import 'package:avelune_studio/features/scenes/application/scene_dialogue_line_policy_draft.dart';
import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/dialogue_policy_publication_fixture.dart';

void main() {
  final document = const YarnDialogueCompiler().compile(dialoguePolicySource);

  test('choice draft keeps invalid defaults explicit until repaired', () {
    final scene = dialoguePolicyScene();
    final payload = dialoguePolicyPayload(scene);
    final draft = SceneDialogueChoicePolicyDraft(
      scene: scene,
      nodeId: 'talk',
      payload: payload,
      document: document,
    );
    expect(draft.choices, {'yes': 'Oui', 'no': 'Non'});
    expect(draft.targets, {'cancel': 'Branche 1'});
    draft.defaultOutcome = 'missing';
    expect(draft.prepared, isNull);
    expect(payload.choicePolicies.single.defaultOutcomeId, 'yes');
    draft.defaultOutcome = 'no';
    expect(draft.prepared!.defaultOutcomeId, 'no');
    expect(
      draft.prepared!.cancellation,
      const SceneDialogueChoiceCancellation.branch('cancel'),
    );
  });

  test(
    'line draft preserves segments, other policies and exact fractional timing',
    () {
      final payload = dialoguePolicyPayload(dialoguePolicyScene());
      final draft = SceneDialogueLinePolicyDraft(
        project: ProjectManifest(name: 'Dialogue', maps: [], tilesets: []),
        payload: payload,
        document: document,
      );
      draft.revealMs = '17,125';
      expect(draft.feedback.revealIntervalMicros, 17125);
      expect(
        draft.feedback.segments,
        payload.linePolicies.first.feedback.segments,
      );
      expect(
        draft.feedback.advance,
        payload.linePolicies.first.feedback.advance,
      );
      draft.revealMs = '1.0001';
      expect(() => draft.feedback, throwsFormatException);
      expect(payload.linePolicies.first.feedback.revealIntervalMicros, 25000);
    },
  );

  test('headless policy edits publish and cold reopen without touching Yarn or unrelated data', () async {
    final fixture = await DialoguePolicyPublicationFixture.create();
    addTearDown(() => fixture.root.delete(recursive: true));
    final sourceBefore = await fixture.sourceFile.readAsBytes();
    final original = fixture.project.scenes.single;
    final session = SceneEditSession(original, base: original);
    final before = dialoguePolicyPayload(original);
    final choice =
        SceneDialogueChoicePolicyDraft(
            scene: original,
            nodeId: 'talk',
            payload: before,
            document: document,
          )
          ..defaultOutcome = 'no'
          ..cancellation = SceneDialogueChoiceCancellationKind.disabled;
    expect(
      session.mutate(
        (scene) => updateSceneDialogueChoicePolicy(
          scene,
          nodeId: 'talk',
          dialogue: document,
          choicePolicy: choice.prepared!,
        ),
      ),
      isTrue,
      reason: session.error,
    );
    final line = SceneDialogueLinePolicyDraft(
      project: fixture.project,
      payload: dialoguePolicyPayload(session.current),
      document: document,
    )..revealMs = '17.125';
    expect(
      session.mutate(
        (scene) => updateSceneDialogueLinePolicy(
          scene,
          nodeId: 'talk',
          dialogue: document,
          linePolicy: line.prepared,
        ),
      ),
      isTrue,
      reason: session.error,
    );
    final edited = dialoguePolicyPayload(session.current);
    expect(session.undoCount, 2);
    expect(edited.choicePolicies.single.defaultOutcomeId, 'no');
    expect(
      edited.choicePolicies.single.cancellation.kind,
      SceneDialogueChoiceCancellationKind.disabled,
    );
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
    final receipt = await LocalSceneAdapter(
      session: fixture.session,
      mapAdapter: fixture.maps,
    ).publishScene(base: original, current: session.current);
    expect(receipt.catalog.changedPaths, ['project.json']);
    final reopened = await LocalMapWorkspaceAdapter().loadProject(
      fixture.session,
    );
    expect(reopened.scenes.single, session.current);
    expect(await fixture.sourceFile.readAsBytes(), sourceBefore);
  });
}
