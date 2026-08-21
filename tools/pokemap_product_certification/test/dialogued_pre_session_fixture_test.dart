import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

/// BETA-CIN-083 — the reference journey, authored for real.
///
/// map_core froze `presentationDialogueReferenceFixture` as the contractual
/// state sequence of the "Noir/Blanc" journey, but only map_core's own test
/// ever read it: no project existed that a runtime could actually walk. These
/// tests build that project through the canonical semantic operations and then
/// assert what landed, because applying a wrong payload identically on every
/// transport would satisfy parity while proving nothing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the reference journey is authored by canonical operations alone',
      () async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);

    final applied = await harness.applyFixture();

    expect(
      applied,
      const DialoguedPreSessionFixture()
          .steps
          .map((step) => step.actionId)
          .toSet(),
      reason: 'every step of the declared sequence was accepted as authored',
    );
  });

  test('the authored scene carries the journey the contract describes',
      () async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    await harness.applyFixture();

    final project = await harness.project();
    final scene = project.scenes.singleWhere(
      (candidate) => candidate.id == DialoguedPreSessionFixture.sceneId,
    );

    // One cinematic, created by the action rather than written beside it.
    expect(
      project.presentationCinematics.map((asset) => asset.id),
      contains(DialoguedPreSessionFixture.cinematicId),
    );
    expect(
      project.newGame.preSessionSceneId,
      DialoguedPreSessionFixture.sceneId,
      reason: 'setAsEntrypoint made this Scene the New Game entry',
    );

    // The four cue kinds of the reference journey, each bound to its marker.
    final interactions = <String, SceneInteractionRequestKind>{
      for (final node in scene.graph.nodes)
        if (node.payload case final SceneActionPayload payload)
          if (payload.preSessionInteraction case final interaction?)
            node.id: interaction.kind,
    };
    expect(interactions, <String, SceneInteractionRequestKind>{
      DialoguedPreSessionFixture.pagesNodeId:
          SceneInteractionRequestKind.message,
      DialoguedPreSessionFixture.avatarNodeId:
          SceneInteractionRequestKind.choice,
      DialoguedPreSessionFixture.nameNodeId: SceneInteractionRequestKind.text,
      DialoguedPreSessionFixture.confirmNodeId:
          SceneInteractionRequestKind.confirmation,
      DialoguedPreSessionFixture.closingNodeId:
          SceneInteractionRequestKind.confirmation,
    });
  });

  test('the scenario covers continue, repeat, seek and stop', () async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    await harness.applyFixture();

    final project = await harness.project();
    final scene = project.scenes.singleWhere(
      (candidate) => candidate.id == DialoguedPreSessionFixture.sceneId,
    );
    final outcomes = <String>{};
    for (final node in scene.graph.nodes) {
      if (node.payload case final ScenePresentationCinematicPayload payload) {
        for (final binding in payload.interactionCueBindings) {
          for (final route in binding.outcomeRoutes) {
            outcomes.add(route.outcome.kind.wireName);
          }
        }
      }
    }
    expect(
      outcomes,
      DialoguedPreSessionFixture.coveredOutcomeWireNames,
      reason: 'BETA-CIN-083 asks the scenario itself to exercise these four',
    );
  });

  test('the confirmation reads back the draft value it will commit', () async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    await harness.applyFixture();

    final project = await harness.project();
    final scene = project.scenes.singleWhere(
      (candidate) => candidate.id == DialoguedPreSessionFixture.sceneId,
    );
    final confirmation = scene.graph.nodes.singleWhere(
      (node) => node.id == DialoguedPreSessionFixture.confirmNodeId,
    );
    final payload = confirmation.payload! as SceneActionPayload;
    expect(
      payload.preSessionInteraction!.prompt.fallbackText,
      contains('{draft.playerName}'),
      reason: 'the interpolated value is what makes the negative branch '
          'meaningful — the player must see the name before rejecting it',
    );

    // And the field it reads back is the field the text input binds.
    final nameNode = scene.graph.nodes.singleWhere(
      (node) => node.id == DialoguedPreSessionFixture.nameNodeId,
    );
    final namePayload = nameNode.payload! as SceneActionPayload;
    expect(
      namePayload.preSessionInteraction!.resultBinding?.field,
      ScenePreSessionDraftField.playerName,
    );
  });

  test('the negative confirmation replays from the name marker', () async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    await harness.applyFixture();

    final project = await harness.project();
    final scene = project.scenes.singleWhere(
      (candidate) => candidate.id == DialoguedPreSessionFixture.sceneId,
    );
    final opening = scene.graph.nodes.singleWhere(
      (node) => node.id == DialoguedPreSessionFixture.openingNodeId,
    );
    final payload = opening.payload! as ScenePresentationCinematicPayload;
    final binding = payload.interactionCueBindings.singleWhere(
      (candidate) =>
          candidate.markerId == DialoguedPreSessionFixture.confirmMarkerId,
    );
    final declined = binding.outcomeRoutes.singleWhere(
      (route) => route.outputPortId == 'declined',
    );
    expect(
      declined.outcome,
      isA<PresentationRepeatFromMarkerOutcome>().having(
        (outcome) => outcome.markerId,
        'markerId',
        DialoguedPreSessionFixture.nameMarkerId,
      ),
      reason: 'a typo must return to the input, not dead-end the cinematic',
    );
  });

  test('the seek target is an authored marker, never a raw offset', () async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    await harness.applyFixture();

    final project = await harness.project();
    final cinematic = project.presentationCinematics.singleWhere(
      (asset) => asset.id == DialoguedPreSessionFixture.cinematicId,
    );
    final markerIds = <String>{
      for (final track in cinematic.tracks)
        for (final clip in track.clips) clip.id,
    };
    expect(
      markerIds,
      contains(DialoguedPreSessionFixture.montageMarkerId),
      reason: 'the jump resolves by marker identity, so the destination has '
          'to exist as a marker',
    );
  });
}

final class _Harness {
  _Harness._(this.root, this.readApi, this.mutations, this.snapshots);

  static Future<_Harness> create() async {
    final root = await Directory.systemTemp.createTemp('cin083-fixture-');
    await const NeutralCertificationGameFixture(dialoguedPreSession: true)
        .writeAuthorWorkspace(root);
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final readApi = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    return _Harness._(
      root,
      readApi,
      LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots),
      snapshots,
    );
  }

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }

  Future<Set<String>> applyFixture() async {
    final opened = await readApi.open(root.path);
    final project = ProjectHandle(opened['projectHandle']! as String);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );

    final applied = <String>{};
    var sequence = 0;
    for (final step in const DialoguedPreSessionFixture().steps) {
      sequence += 1;
      final request = AuthoringRequest(
        requestId: 'cin083-request-$sequence',
        actionId: step.actionId,
        actionVersion: 1,
        workspaceHandle: workspace.value,
        parameters: step.parameters,
        expectedRevision: (await snapshots.load(project)).revision,
        idempotencyKey: 'cin083-idempotency-$sequence',
      );
      final plan = await mutations.plan(project, request);
      final response = await mutations.apply(
        project,
        planId: plan['planId']! as String,
        operationId: 'cin083-step-$sequence',
      );
      applied.add(
        (response['receipt']! as Map)['actionId']! as String,
      );
    }
    return applied;
  }

  Future<ProjectManifest> project() async => ProjectManifest.fromJson(
        jsonDecode(
          await File('${root.path}/project.json').readAsString(),
        ) as Map<String, dynamic>,
      );
}
