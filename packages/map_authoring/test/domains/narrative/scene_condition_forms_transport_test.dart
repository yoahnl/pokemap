import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final jsonl in [false, true]) {
    test(
        'five guided condition families persist over ${jsonl ? 'JSONL' : 'API'}',
        () async {
      final fixture = jsonDecode(
        await File('test/fixtures/scene_condition_forms.json').readAsString(),
      ) as Map<String, dynamic>;
      final root = await Directory.systemTemp.createTemp('condition-forms-');
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}/project.json');
      await file.writeAsString(jsonEncode(fixture['project']));
      final mapFile = File('${root.path}/maps/hall.json');
      await mapFile.parent.create(recursive: true);
      await mapFile.writeAsString(jsonEncode(fixture['map']));
      final mapBefore = await mapFile.readAsBytes();
      final items = File('${root.path}/data/pokemon/catalogs/items.json');
      await items.parent.create(recursive: true);
      await items.writeAsString(jsonEncode(fixture['itemCatalog']));
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore();
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final api = AuthoringReadApi(
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
      final worker = JsonlWorker(api: api, mutations: mutations);
      var sequence = 0;
      Future<Map<String, Object?>> wire(
          String command, Map<String, Object?> args,
          {bool failure = false}) async {
        final result = AuthoringResult.fromJson(jsonDecode(
          await worker.processLine(jsonEncode({
            'id': 'condition-${sequence++}',
            'command': command,
            'args': args,
          })),
        ) as Map<String, dynamic>);
        expect(result.status == AuthoringResultStatus.success, !failure,
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
          projectHandle: opened.projectHandle,
        );
      }
      Future<Map<String, Object?>> plan(Map<String, dynamic> source,
          {bool failure = false}) async {
        final snapshot = await snapshots.load(ProjectHandle(projectHandle));
        final id = 'set-condition-${sequence++}';
        final request = AuthoringRequest(
          requestId: id,
          actionId: 'scene.condition.set',
          actionVersion: 1,
          workspaceHandle: workspaceHandle,
          expectedRevision: snapshot.revision,
          idempotencyKey: id,
          parameters: {
            'sceneId': 'condition_scene',
            'nodeId': 'check',
            'conditionSource': source,
          },
        );
        if (jsonl) {
          return wire(
              'plan',
              {
                'projectHandle': projectHandle,
                'request': request.toJson(),
              },
              failure: failure);
        }
        if (failure) {
          await expectLater(
            mutations.plan(ProjectHandle(projectHandle), request),
            throwsA(anyOf(
              isA<ValidationException>(),
              isA<NarrativeAuthoringException>().having(
                (error) => error.code,
                'code',
                'scene.publication_blocked',
              ),
            )),
          );
          return {};
        }
        return mutations.plan(ProjectHandle(projectHandle), request);
      }

      try {
        for (final raw in fixture['sources'] as List) {
          final source = Map<String, dynamic>.from(raw as Map);
          final before = await file.readAsBytes();
          final prepared = await plan(source);
          expect(await file.readAsBytes(), before);
          final operation = 'apply-condition-${sequence++}';
          if (jsonl) {
            await wire('apply', {
              'projectHandle': projectHandle,
              'planId': prepared['planId'],
              'operationId': operation,
            });
          } else {
            await mutations.apply(ProjectHandle(projectHandle),
                planId: prepared['planId']! as String, operationId: operation);
          }
          final saved = ProjectManifest.fromJson(
            jsonDecode(await file.readAsString()) as Map<String, dynamic>,
          );
          final scene = saved.scenes.single;
          final actual = (scene.graph.nodes
                  .singleWhere((node) => node.id == 'check')
                  .payload as SceneConditionPayload)
              .conditionSource!;
          expect(actual.toJson(), source);
          expect(scene.metadata, {'preserved': 'yes'});
          expect(scene.layout.nodeLayouts.single.x, 32);
          expect(scene.graph.edges, hasLength(3));
          expect(await mapFile.readAsBytes(), mapBefore);
        }
        for (final raw in fixture['invalidSources'] as List) {
          final before = await file.readAsBytes();
          await plan(Map<String, dynamic>.from(raw as Map), failure: true);
          expect(await file.readAsBytes(), before);
          expect(await mapFile.readAsBytes(), mapBefore);
        }
      } finally {
        await mutations.detachWorkspace(WorkspaceHandle(workspaceHandle));
        await api.closeWorkspace(WorkspaceHandle(workspaceHandle));
      }
    });
  }
}
