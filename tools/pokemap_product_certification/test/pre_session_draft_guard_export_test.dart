import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/game_export.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

/// A draft guard the Studio offers can actually ship — BETA-CIN-083 follow-up.
///
/// `scene.preSession.condition.insert` is exposed on all four transports and in
/// the Studio, but the project it produced was refused by the export: the
/// symbolic solver could not prove a `newGameDraft` condition and the reference
/// index reported its sourceId as a legacy external reference at error
/// severity. An author adding the guard got a game that could not be packaged
/// and a diagnostic they had no way to act on.
///
/// map_core's unit tests pin the two layers. This one pins the consequence,
/// because that is what an author actually experiences: author the guard
/// through the canonical action, then export.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const guardNodeId = 'has_name';
  const missingNameEndNodeId = 'end_missing_name';

  test('a pre-session with a draft guard exports certified', () async {
    final root = await Directory.systemTemp.createTemp('cin083-guard-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final projectRoot = Directory(p.join(root.path, 'project'));
    await const NeutralCertificationGameFixture(dialoguedPreSession: true)
        .writeAuthorWorkspace(projectRoot);

    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[projectRoot.path],
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
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    final opened = await readApi.open(projectRoot.path);
    final project = ProjectHandle(opened['projectHandle']! as String);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    await mutations.attachProject(
      projectRootPath: projectRoot.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );

    // The declared journey, plus the guard the ticket's scope deliberately
    // leaves out — inserted early, because once a confirmation sits in front
    // of `end` nothing can be inserted there any more.
    final steps = <DialoguedPreSessionAuthoringStep>[
      ...const DialoguedPreSessionFixture().steps.take(2),
      const DialoguedPreSessionAuthoringStep(
        actionId: 'scene.preSession.condition.insert',
        parameters: <String, Object?>{
          'sceneId': DialoguedPreSessionFixture.sceneId,
          'nodeId': guardNodeId,
          'targetNodeId': DialoguedPreSessionFixture.endNodeId,
          'falseEndNodeId': missingNameEndNodeId,
          'draftField': 'playerName',
          'operator': 'isTrue',
        },
      ),
      ...const DialoguedPreSessionFixture().steps.skip(2),
    ];

    var sequence = 0;
    for (final step in steps) {
      sequence += 1;
      final plan = await mutations.plan(
        project,
        AuthoringRequest(
          requestId: 'guard-$sequence',
          actionId: step.actionId,
          actionVersion: 1,
          workspaceHandle: workspace.value,
          parameters: step.parameters,
          expectedRevision: (await snapshots.load(project)).revision,
          idempotencyKey: 'guard-$sequence',
        ),
      );
      await mutations.apply(
        project,
        planId: plan['planId']! as String,
        operationId: 'guard-$sequence',
      );
    }

    // The guard really is in the project, or this test would prove nothing.
    final manifest = ProjectManifest.fromJson(
      jsonDecode(
        await File(p.join(projectRoot.path, 'project.json')).readAsString(),
      ) as Map<String, dynamic>,
    );
    final scene = manifest.scenes.singleWhere(
      (candidate) => candidate.id == DialoguedPreSessionFixture.sceneId,
    );
    final guard = scene.graph.nodes.singleWhere(
      (node) => node.id == guardNodeId,
    );
    final payload = guard.payload as SceneConditionPayload;
    expect(
      payload.conditionSource?.sourceKind,
      SceneConditionSourceKind.newGameDraft,
    );
    expect(payload.conditionSource?.sourceId, 'playerName');

    final artifact = await const GamePackageExportService().exportToFile(
      projectRoot: projectRoot,
      profile: const NeutralCertificationGameFixture(
        dialoguedPreSession: true,
      ).exportProfile,
      outputFile: File(p.join(root.path, 'guarded.avelunegame')),
    );
    expect(
      artifact.certification.isCertified,
      isTrue,
      reason: 'the guard used to make the export fail outright with '
          'gameplayReadinessFailed',
    );
  }, timeout: const Timeout(Duration(minutes: 6)));
}
