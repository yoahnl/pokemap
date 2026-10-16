import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'package:map_authoring/src/references/resource_usage_walk.dart';

void main() {
  test('warp action describes its presentation and image dependency', () {
    final action = SceneActions.descriptors.singleWhere(
      (action) => action.id == 'scene.interactive_command.set');
    final warp = action.extensions['warp'] as Map;
    expect(warp['parameters'], contains('presentation'));
    expect(warp['presentation'], containsPair('projectDimension', 'twoD'));
    expect(resourceReferencePaths({'presentation': {'illustrationElementId': 'picture'}},
      'element', 'picture'), [r'$.presentation.illustrationElementId']);
  });

  for (final jsonl in [false, true]) {
    test('illustrated warp persists through ${jsonl ? 'JSONL' : 'direct API'}',
        () async {
      final root =
          await Directory.systemTemp.createTemp('scene-warp-transport-');
      addTearDown(() => root.delete(recursive: true));
      final arrival = MapData(
        version: ProjectVersion.v8,
        id: 'centre',
        name: 'Centre',
        size: const GridSize(width: 8, height: 8),
        layers: const [],
        warps: const [
          MapWarp(
              id: 'arrival',
              pos: GridPos(x: 2, y: 3),
              targetMapId: 'centre',
              targetPos: GridPos(x: 2, y: 3),
              triggerMode: MapWarpTriggerMode.onBump)
        ],
      );
      final originalCommand = SceneInteractiveCommand.warp(
        destinationMapId: 'centre',
        warpId: 'arrival',
      );
      final scene = SceneAsset(
          id: 'transfer',
          name: 'Transfert',
          graph: SceneGraph(startNodeId: 'start', nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
                id: 'warp',
                kind: SceneNodeKind.action,
                title: 'Entrer',
                payload: SceneActionPayload.interactive(originalCommand,
                    actionKind: 'authored-transfer',
                    parameters: const {'annotation': 'keep'})),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ], edges: [
            SceneEdge(
                id: 'enter',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'warp',
                kind: SceneEdgeKind.defaultFlow),
            for (final port in ['completed', 'blocked'])
              SceneEdge(
                  id: port,
                  fromNodeId: 'warp',
                  fromPortId: port,
                  toNodeId: 'end',
                  kind: SceneEdgeKind.actionCompleted),
          ]));
      final initial = ProjectManifest(
          version: ProjectVersion.v8,
          name: 'Warp',
          maps: const [
            ProjectMapEntry(
                id: 'centre', name: 'Centre', relativePath: 'maps/centre.json')
          ],
          tilesets: const [ProjectTilesetEntry(id: 'picture-sheet', name: 'Picture',
            relativePath: 'tilesets/picture.png', source: ProjectRegularAtlasTilesetSource(
              assetId: 'picture-sheet', pixelWidth: 1, pixelHeight: 1, tileWidth: 1, tileHeight: 1))],
          elements: const [ProjectElementEntry(id: 'picture', name: 'Picture',
            tilesetId: 'picture-sheet', categoryId: 'pictures',
            frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))])],
          scenes: [
            scene
          ]);
      final file = File('${root.path}/project.json');
      await Directory('${root.path}/maps').create();
      await File('${root.path}/maps/centre.json')
          .writeAsString(jsonEncode(arrival.toJson()));
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
                await worker.processLine(jsonEncode(
                    {'id': command, 'command': command, 'args': args})))
            as Map<String, dynamic>);
        expect(result.status, AuthoringResultStatus.success,
            reason: result.toJson().toString());
        return result.data;
      }

      final opened = await api.openProject(root.path);
      await mutations.attachProject(
          projectRootPath: root.path,
          workspaceHandle: opened.workspaceHandle,
          projectHandle: opened.projectHandle);
      final snapshot = await snapshots.load(opened.projectHandle);
      final command = SceneInteractiveCommand.warp(
          destinationMapId: 'centre',
          warpId: 'arrival',
          arrivalFacing: EntityFacing.north,
          transition: SceneWarpTransition.none,
          presentation: SceneWarpPresentation(mode: SceneWarpPresentationMode.illustrated,
            illustrationElementId: 'picture'));
      final request = AuthoringRequest(
          requestId: 'warp-options',
          actionId: 'scene.interactive_command.set',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'warp-options',
          parameters: {
            'sceneId': scene.id,
            'nodeId': 'warp',
            'command': command.toJson()
          });
      final before = await file.readAsBytes();
      final plan = jsonl
          ? await wire('plan', {
              'projectHandle': opened.projectHandle.value,
              'request': request.toJson(),
            })
          : await mutations.plan(opened.projectHandle, request);
      expect(await file.readAsBytes(), before);
      if (jsonl) {
        await wire('apply', {
          'projectHandle': opened.projectHandle.value,
          'planId': plan['planId'],
          'operationId': 'apply-warp'
        });
      } else {
        await mutations.apply(opened.projectHandle,
            planId: plan['planId']! as String, operationId: 'apply-warp');
      }
      final updated = await snapshots.load(opened.projectHandle);
      final payload = updated.manifest.scenes.single.graph.nodes[1].payload
          as SceneActionPayload;
      expect(payload.interactiveCommand, command);
      expect(payload.actionKind, 'authored-transfer');
      expect(payload.parameters, {'annotation': 'keep'});
      final stable = await file.readAsBytes();
      for (final field in ['arrivalFacing', 'transition', 'warpId', 'presentation', 'missingIllustration']) {
        await expectLater(
            mutations.plan(
                opened.projectHandle,
                AuthoringRequest(
                  requestId: 'invalid-$field',
                  actionId: request.actionId,
                  actionVersion: 1,
                  workspaceHandle: opened.workspaceHandle.value,
                  expectedRevision: updated.revision,
                  idempotencyKey: 'invalid-$field',
                  parameters: {
                    'sceneId': scene.id,
                    'nodeId': 'warp',
                    'command': field == 'missingIllustration' ? {...command.toJson(), 'presentation': {...(command as SceneWarpInteractiveCommand).presentation!.toJson(), 'illustrationElementId': 'missing'}} : {...command.toJson(), field: 'missing'}
                  },
                )),
            throwsA(isA<NarrativeAuthoringException>()));
        expect(await file.readAsBytes(), stable);
      }
      await api.closeWorkspace(opened.workspaceHandle);
      final reopened = await api.openProject(root.path);
      final reloaded = await snapshots.load(reopened.projectHandle);
      expect(
          (reloaded.manifest.scenes.single.graph.nodes[1].payload
                  as SceneActionPayload)
              .interactiveCommand,
          command);
      await api.closeWorkspace(reopened.workspaceHandle);
    });
  }
}
