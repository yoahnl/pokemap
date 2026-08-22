import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/game_export.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

/// BETA-CIN-086 — a raw placeholder can no longer reach a certified package.
///
/// The Night Watch package was built, certified, installed and played with
/// `{draft.playerName}` printed verbatim in a confirmation the player had to
/// answer. Two nets both had a hole: a malformed reference is not recognised as
/// a reference at all, so it never lands in `missingReferences`, and
/// `missingReferences` itself is consumed by nothing.
///
/// map_core's own test pins the diagnostic. This one pins the CONSEQUENCE,
/// because a diagnostic nobody acts on is exactly what let this ship: author
/// the journey through the canonical actions with the defect in it, then try to
/// export.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an export carrying a malformed placeholder is refused', () async {
    final root = await Directory.systemTemp.createTemp('cin086-interp-');
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

    // The journey exactly as authored, with the canonical reference degraded
    // back to the single-brace form that shipped.
    var degraded = false;
    final steps = <DialoguedPreSessionAuthoringStep>[
      for (final step in const DialoguedPreSessionFixture().steps)
        if (step.parameters['interaction'] case final interaction?
            when jsonEncode(interaction).contains(r'{{draft.playerName}}'))
          () {
            degraded = true;
            return DialoguedPreSessionAuthoringStep(
              actionId: step.actionId,
              parameters: <String, Object?>{
                ...step.parameters,
                'interaction': jsonDecode(
                  jsonEncode(interaction)
                      .replaceAll(r'{{draft.playerName}}', r'{draft.playerName}'),
                ),
              },
            );
          }()
        else
          step,
    ];
    expect(
      degraded,
      isTrue,
      reason: 'the fixture no longer carries the reference this test degrades, '
          'so the test would prove nothing',
    );

    var sequence = 0;
    for (final step in steps) {
      sequence += 1;
      final plan = await mutations.plan(
        project,
        AuthoringRequest(
          requestId: 'interp-$sequence',
          actionId: step.actionId,
          actionVersion: 1,
          workspaceHandle: workspace.value,
          parameters: step.parameters,
          expectedRevision: (await snapshots.load(project)).revision,
          idempotencyKey: 'interp-$sequence',
        ),
      );
      await mutations.apply(
        project,
        planId: plan['planId']! as String,
        operationId: 'interp-$sequence',
      );
    }

    // The defect really is in the project, or the refusal below could come
    // from anywhere.
    final manifest = ProjectManifest.fromJson(
      jsonDecode(
        await File(p.join(projectRoot.path, 'project.json')).readAsString(),
      ) as Map<String, dynamic>,
    );
    final prompts = <String>[
      for (final scene in manifest.scenes)
        for (final node in scene.graph.nodes)
          if (node.payload case final SceneActionPayload payload)
            if (payload.preSessionInteraction?.prompt.fallbackText
                case final text?)
              text,
    ];
    expect(prompts, contains(contains(r'{draft.playerName}')));

    await expectLater(
      const GamePackageExportService().exportToFile(
        projectRoot: projectRoot,
        profile: const NeutralCertificationGameFixture(
          dialoguedPreSession: true,
        ).exportProfile,
        outputFile: File(p.join(root.path, 'degraded.avelunegame')),
      ),
      throwsA(
        isA<GamePackageExportException>()
            .having((error) => error.code, 'code', 'gameplayReadinessFailed')
            .having(
              (error) => error.message,
              'message',
              contains('{{draft.playerName}}'),
            ),
      ),
      reason: 'the export must refuse, and its message must say the correct '
          'form rather than only that something is wrong',
    );
  }, timeout: const Timeout(Duration(minutes: 6)));
}
