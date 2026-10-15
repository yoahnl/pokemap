import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('regional map read-only contract is discoverable on canonical actions',
      () {
    for (final id in [
      'scene.interactive_command.set',
      'scene.upsert',
      'scene.graph.patch'
    ]) {
      final descriptor =
          SceneActions.descriptors.singleWhere((entry) => entry.id == id);
      expect(descriptor.extensions['openRegionalMap'], {
        'projectDimension': 'twoD',
        'parameters': [],
        'mode': 'readOnly',
        'fastTravel': false,
        'completion': 'closed',
        'persistent': false,
        'outputPorts': ['completed', 'cancelled'],
      });
    }
  });

  for (final jsonl in [false, true]) {
    for (final spatial in [false, true]) {
      test(
          'regional map ${jsonl ? 'JSONL' : 'API'} ${spatial ? 'refuses 3D before writes' : 'persists and cold reopens'}',
          () async {
        final root =
            await Directory.systemTemp.createTemp('regional-map-command-');
        addTearDown(() => root.delete(recursive: true));
        final file = File('${root.path}/project.json');
        final initial = ProjectManifest(
            version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
            settings: ProjectSettings(
                dimension:
                    spatial ? ProjectDimension.threeD : ProjectDimension.twoD),
            name: 'Regional map transport',
            maps: const [],
            tilesets: const [],
            regionalMap: ProjectRegionalMapCatalog(regions: [
              ProjectRegionDefinition(id: 'kanto', label: 'Kanto'),
            ]));
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
        Future<AuthoringResult> wire(
                String command, Map<String, Object?> args) async =>
            AuthoringResult.fromJson(
                jsonDecode(await worker.processLine(jsonEncode({
              'id': 'map-$command',
              'command': command,
              'args': args,
            }))) as Map<String, dynamic>);
        final opened = await api.openProject(root.path);
        await mutations.attachProject(
            projectRootPath: root.path,
            workspaceHandle: opened.workspaceHandle,
            projectHandle: opened.projectHandle);
        final before = await file.readAsBytes();
        final snapshot = await snapshots.load(opened.projectHandle);
        final scene = _scene();
        final request = AuthoringRequest(
            requestId: 'regional-map',
            actionId: 'scene.upsert',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'regional-map',
            parameters: {'scene': scene.toJson()});
        if (spatial) {
          if (jsonl) {
            final result = await wire('plan', {
              'projectHandle': opened.projectHandle.value,
              'request': request.toJson()
            });
            expect(result.status, AuthoringResultStatus.failure);
            expect(jsonEncode(result.error!.details),
                contains('commandUnsupportedDimension'));
          } else {
            await expectLater(
                mutations.plan(opened.projectHandle, request),
                throwsA(isA<NarrativeAuthoringException>().having(
                    (error) => error.code,
                    'code',
                    'scene.publication_blocked')));
          }
          expect(await file.readAsBytes(), before);
          await api.closeWorkspace(opened.workspaceHandle);
          return;
        }
        late Map<String, Object?> plan;
        if (jsonl) {
          final result = await wire('plan', {
            'projectHandle': opened.projectHandle.value,
            'request': request.toJson()
          });
          expect(result.status, AuthoringResultStatus.success,
              reason: result.toJson().toString());
          plan = result.data;
        } else {
          plan = await mutations.plan(opened.projectHandle, request);
        }
        expect(await file.readAsBytes(), before);
        if (jsonl) {
          final applied = await wire('apply', {
            'projectHandle': opened.projectHandle.value,
            'planId': plan['planId'],
            'operationId': 'regional-map-apply'
          });
          expect(applied.status, AuthoringResultStatus.success,
              reason: applied.toJson().toString());
        } else {
          await mutations.apply(opened.projectHandle,
              planId: plan['planId']! as String,
              operationId: 'regional-map-apply');
        }
        await api.closeWorkspace(opened.workspaceHandle);
        final reopened = await api.openProject(root.path);
        final loaded = await snapshots.load(reopened.projectHandle);
        expect(loaded.manifest.regionalMap!.toJson(),
            initial.regionalMap!.toJson());
        final saved = loaded.manifest.scenes.single;
        expect(saved, scene);
        expect(
            (saved.graph.nodes[1].payload as SceneActionPayload)
                .interactiveCommand,
            SceneInteractiveCommand.openRegionalMap());
        expect(diagnoseScene(saved).hasErrors, isFalse);
        await api.closeWorkspace(reopened.workspaceHandle);
      });
    }
  }
}

SceneAsset _scene() => SceneAsset(
    id: 'wall-map',
    name: 'Town Map',
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
          id: 'map',
          kind: SceneNodeKind.action,
          payload: buildScenePayloadForNarrativeCommand(
              commandId: 'openRegionalMap', parameters: const {})),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [
      SceneEdge(
          id: 'start',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'map',
          kind: SceneEdgeKind.defaultFlow),
      for (final port in ['completed', 'cancelled'])
        SceneEdge(
            id: port,
            fromNodeId: 'map',
            fromPortId: port,
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted),
    ]));
