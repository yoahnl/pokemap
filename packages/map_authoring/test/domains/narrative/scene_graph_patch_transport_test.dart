import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'scene_graph_patch_test.dart' show fixture;

void main() {
  for (final jsonl in [false, true]) {
    test(
        'fine graph edit is atomic and revision checked over ${jsonl ? 'JSONL' : 'direct API'}',
        () async {
      final root =
          await Directory.systemTemp.createTemp('scene-graph-transport-');
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}/project.json');
      final initial = fixture();
      await file.writeAsString(jsonEncode(initial.toJson()));
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [root.path], fileReader: reader);
      final handles = WorkspaceHandleStore();
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final api = AuthoringReadApi(
          openService: ProjectOpenService(
              policy: policy, fileReader: reader, handles: handles),
          snapshotLoader: snapshots);
      final mutations = LocalMapAuthoringMutationApi(
          policy: policy, snapshotLoader: snapshots);
      final worker = JsonlWorker(api: api, mutations: mutations);
      Future<Map<String, Object?>> wire(
          String command, Map<String, Object?> args) async {
        final result = AuthoringResult.fromJson(jsonDecode(
            await worker.processLine(jsonEncode({
          'id': 'graph-$command',
          'command': command,
          'args': args
        }))) as Map<String, dynamic>);
        expect(result.status, AuthoringResultStatus.success,
            reason: result.toJson().toString());
        return result.data;
      }

      late String projectHandle;
      late String workspaceHandle;
      if (jsonl) {
        final opened = await wire('open', {'projectRoot': root.path});
        projectHandle = opened['projectHandle']! as String;
        workspaceHandle = opened['workspaceHandle']! as String;
      } else {
        final opened = await api.openProject(root.path);
        projectHandle = opened.projectHandle.value;
        workspaceHandle = opened.workspaceHandle.value;
        await mutations.attachProject(
            projectRootPath: root.path,
            workspaceHandle: opened.workspaceHandle,
            projectHandle: opened.projectHandle);
      }
      final snapshot = await snapshots.load(ProjectHandle(projectHandle));
      final request = AuthoringRequest(
          requestId: 'graph-edit',
          actionId: 'scene.graph.patch',
          actionVersion: 1,
          workspaceHandle: workspaceHandle,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'graph-edit',
          parameters: {
            'sceneId': 'test',
            'upsertNodes': [
              SceneNode(id: 'end', kind: SceneNodeKind.end, title: 'Reviewed')
                  .toJson()
            ]
          });
      final before = await file.readAsBytes();
      final plan = jsonl
          ? await wire('plan',
              {'projectHandle': projectHandle, 'request': request.toJson()})
          : await mutations.plan(ProjectHandle(projectHandle), request);
      expect(await file.readAsBytes(), before);
      if (jsonl) {
        await wire('apply', {
          'projectHandle': projectHandle,
          'planId': plan['planId'],
          'operationId': 'apply-graph'
        });
      } else {
        await mutations.apply(ProjectHandle(projectHandle),
            planId: plan['planId']! as String, operationId: 'apply-graph');
      }
      final updated = ProjectManifest.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>);
      expect(updated.scenes.first.graph.nodes.last.title, 'Reviewed');
      expect(updated.scenes.first.layout, initial.scenes.first.layout);
      expect(updated.scenes.last, initial.scenes.last);
      await expectLater(
          mutations.plan(
              ProjectHandle(projectHandle),
              AuthoringRequest(
                  requestId: 'stale-graph',
                  actionId: request.actionId,
                  actionVersion: 1,
                  workspaceHandle: workspaceHandle,
                  expectedRevision: snapshot.revision,
                  idempotencyKey: 'stale-graph',
                  parameters: request.parameters)),
          throwsA(isA<AuthoringPlanException>()
              .having((error) => error.code, 'code', 'plan.stale')));
      expect(
          ProjectManifest.fromJson(
              jsonDecode(await file.readAsString()) as Map<String, dynamic>),
          updated);
      await api.closeWorkspace(WorkspaceHandle(workspaceHandle));
    });
  }
}
