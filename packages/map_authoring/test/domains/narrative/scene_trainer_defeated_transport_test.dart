import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final jsonl in [false, true]) {
    test(
        'trainer defeated semantic edit is revision checked over ${jsonl ? 'JSONL' : 'direct API'}',
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
          actionId: 'scene.condition.set',
          actionVersion: 1,
          workspaceHandle: workspaceHandle,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'graph-edit',
          parameters: {
            'sceneId': 'test',
            'nodeId': 'condition',
            'conditionSource': SceneConditionSource(
                    sourceKind: SceneConditionSourceKind.trainerDefeated,
                    sourceId: 'clair',
                    operator: SceneConditionOperator.isFalse)
                .toJson()
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
      final payload = updated.scenes.first.graph.nodes
          .singleWhere((node) => node.id == 'condition')
          .payload as SceneConditionPayload;
      expect(payload.conditionSource!.sourceKind,
          SceneConditionSourceKind.trainerDefeated);
      expect(payload.conditionSource!.sourceId, 'clair');
      expect(updated.facts, isEmpty);
      expect(updated.trainers, initial.trainers);
      expect(payload.conditionSource!.operator, SceneConditionOperator.isFalse);
      expect(diagnoseScene(updated.scenes.first).hasErrors, isFalse);
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
      final current = await snapshots.load(ProjectHandle(projectHandle));
      final stable = await file.readAsBytes();
      for (final invalidId in ['missing', 'static-clair']) {
        final invalid = AuthoringRequest(
          requestId: 'invalid-$invalidId',
          actionId: request.actionId,
          actionVersion: 1,
          workspaceHandle: workspaceHandle,
          expectedRevision: current.revision,
          idempotencyKey: 'invalid-$invalidId',
          parameters: {
            ...request.parameters,
            'conditionSource':
                SceneConditionSource.trainerDefeated(trainerId: invalidId)
                    .toJson()
          },
        );
        if (jsonl) {
          final rejected = AuthoringResult.fromJson(
              jsonDecode(await worker.processLine(jsonEncode({
            'id': 'reject-$invalidId',
            'command': 'plan',
            'args': {
              'projectHandle': projectHandle,
              'request': invalid.toJson()
            },
          }))) as Map<String, dynamic>);
          expect(rejected.status, AuthoringResultStatus.failure);
          expect(
              rejected.error!.details['domainCode'], isNot('worker.internal'));
        } else {
          await expectLater(
              mutations.plan(ProjectHandle(projectHandle), invalid),
              throwsA(isA<NarrativeAuthoringException>()));
        }
        expect(await file.readAsBytes(), stable);
      }
      await api.closeWorkspace(WorkspaceHandle(workspaceHandle));
    });
  }
}

ProjectManifest fixture() => ProjectManifest(
        name: 'Trainer transport',
        maps: [],
        tilesets: [],
        trainers: const [
          ProjectTrainerEntry(
              id: 'clair', name: 'Sandra', trainerClass: 'Championne'),
          ProjectTrainerEntry(
              id: 'static-clair',
              name: 'Statique',
              trainerClass: 'Rencontre',
              tags: ['static-encounter'])
        ],
        scenes: [
          SceneAsset(
              id: 'test',
              name: 'Facing',
              graph: SceneGraph(startNodeId: 'start', nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(
                    id: 'condition',
                    kind: SceneNodeKind.condition,
                    payload: SceneConditionPayload(
                        conditionSource: SceneConditionSource.playerFacing(
                            direction: EntityFacing.north))),
                SceneNode(id: 'end', kind: SceneNodeKind.end),
              ], edges: [
                _edge('start', 'start', 'completed', 'condition',
                    SceneEdgeKind.defaultFlow),
                _edge('yes', 'condition', 'true', 'end',
                    SceneEdgeKind.conditionTrue),
                _edge('no', 'condition', 'false', 'end',
                    SceneEdgeKind.conditionFalse),
              ])),
          SceneAsset(
              id: 'other',
              name: 'Other',
              graph: SceneGraph(startNodeId: 's', nodes: [
                SceneNode(id: 's', kind: SceneNodeKind.start),
                SceneNode(id: 'e', kind: SceneNodeKind.end),
              ], edges: [
                _edge('other', 's', 'completed', 'e', SceneEdgeKind.defaultFlow)
              ])),
        ]);

SceneEdge _edge(
        String id, String from, String port, String to, SceneEdgeKind kind) =>
    SceneEdge(
        id: id, fromNodeId: from, fromPortId: port, toNodeId: to, kind: kind);
