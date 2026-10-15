import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('caught Pokédex condition advertises its executable dimension', () {
    final action = SceneActions.descriptors.singleWhere(
      (value) => value.id == 'scene.condition.set',
    );
    final contract = action.extensions['pokedexCaughtCount'] as Map;
    expect(contract['projectDimension'], 'twoD');
  });

  for (final jsonl in [false, true]) {
    test(
        '${jsonl ? 'JSONL' : 'direct API'} refuses caught species publication in 3D before writes',
        () async {
      final root =
          await Directory.systemTemp.createTemp('pokedex-spatial-refusal-');
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}/project.json');
      final initial = fixture().copyWith(
        version: ProjectVersion.v9,
        settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      );
      await file.writeAsString(jsonEncode(initial.toJson()));
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [root.path], fileReader: reader);
      final handles = WorkspaceHandleStore();
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots,
      );
      final mutations = LocalMapAuthoringMutationApi(
          policy: policy, snapshotLoader: snapshots);
      final worker = JsonlWorker(api: api, mutations: mutations);
      final opened = await api.openProject(root.path);
      addTearDown(() => api.closeWorkspace(opened.workspaceHandle));
      await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );
      final node = SceneNode(
        id: 'condition',
        kind: SceneNodeKind.condition,
        payload: SceneConditionPayload(
          conditionSource: SceneConditionSource.pokedexCaughtAtLeast(
            range:
                PokedexSpeciesRange(firstNationalDex: 1, lastNationalDex: 151),
            minimum: 20,
          ),
        ),
      );
      final original = initial.scenes.first;
      final scene = SceneAsset(
        id: original.id,
        name: original.name,
        graph: SceneGraph(
          startNodeId: original.graph.startNodeId,
          nodes: [
            for (final existing in original.graph.nodes)
              if (existing.id == node.id) node else existing
          ],
          edges: original.graph.edges,
        ),
      );
      final before = await file.readAsBytes();
      for (final action in [
        'scene.condition.set',
        'scene.upsert',
        'scene.graph.patch'
      ]) {
        final request = AuthoringRequest(
          requestId: 'reject-$action',
          actionId: action,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision:
              (await snapshots.load(opened.projectHandle)).revision,
          idempotencyKey: 'reject-$action',
          parameters: switch (action) {
            'scene.upsert' => {'scene': scene.toJson()},
            'scene.graph.patch' => {
                'sceneId': scene.id,
                'upsertNodes': [node.toJson()]
              },
            _ => {
                'sceneId': scene.id,
                'nodeId': node.id,
                'conditionSource': (node.payload as SceneConditionPayload)
                    .conditionSource!
                    .toJson()
              },
          },
        );
        if (jsonl) {
          final result = AuthoringResult.fromJson(
              jsonDecode(await worker.processLine(jsonEncode({
            'id': action,
            'command': 'plan',
            'args': {
              'projectHandle': opened.projectHandle.value,
              'request': request.toJson(),
            },
          }))) as Map<String, dynamic>);
          expect(result.status, AuthoringResultStatus.failure, reason: action);
          expect(jsonEncode(result.error!.details),
              contains('conditionUnsupportedDimension'));
        } else {
          await expectLater(
            mutations.plan(opened.projectHandle, request),
            throwsA(isA<NarrativeAuthoringException>().having(
                (error) => error.code, 'code', 'scene.publication_blocked')),
            reason: action,
          );
        }
        expect(await file.readAsBytes(), before);
      }
    });

    test(
        'caught Pokédex threshold semantic edit is revision checked over ${jsonl ? 'JSONL' : 'direct API'}',
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
            'conditionSource': SceneConditionSource.pokedexCaughtAtLeast(
                    range: PokedexSpeciesRange(
                        firstNationalDex: 1, lastNationalDex: 151),
                    minimum: 20,
                    expected: false)
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
      expect(payload.conditionSource!.pokedexSpeciesRange,
          PokedexSpeciesRange(firstNationalDex: 1, lastNationalDex: 151));
      expect(payload.conditionSource!.pokedexMinimumCaughtCount, 20);
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
      await api.closeWorkspace(WorkspaceHandle(workspaceHandle));
      final reopened = await api.openProject(root.path);
      final cold = await snapshots.load(reopened.projectHandle);
      expect(cold.manifest.scenes, updated.scenes);
      await api.closeWorkspace(reopened.workspaceHandle);
    });
  }
}

ProjectManifest fixture() =>
    ProjectManifest(name: 'Facing transport', maps: [], tilesets: [], scenes: [
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
            _edge(
                'yes', 'condition', 'true', 'end', SceneEdgeKind.conditionTrue),
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
