import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const configuration = <String, Object?>{
  'id': 'device',
  'label': 'Travel device',
  'acquiredFactId': 'device-owned',
  'emptyMessage': 'No contacts.',
  'contacts': [
    {
      'id': 'mentor',
      'label': 'Mentor',
      'registeredFactId': 'mentor-known',
      'sceneId': 'call',
      'unavailableSceneId': 'busy'
    }
  ]
};

void main() {
  for (final jsonl in [false, true]) {
    final transport = jsonl ? 'JSONL' : 'API';
    test('$transport configures, reopens and undoes the exact contact device',
        () async {
      final h = await _Harness.create();
      addTearDown(h.dispose);
      final before = await h.document();
      final mapBytes = await h.mapFile.readAsBytes();
      final plan = await h.plan({'configuration': configuration}, jsonl);
      expect(await h.document(), before);
      final applied = await h.apply(plan, jsonl);
      expect((await h.document())['contactDevice'], configuration);
      expect(await h.mapFile.readAsBytes(), mapBytes);
      final repeated = await h.apply(plan, jsonl);
      expect((repeated['receipt'] as Map)['receiptId'],
          (applied['receipt'] as Map)['receiptId']);
      final snapshot = await h.snapshots.load(h.opened.projectHandle);
      expect(snapshot.manifest.contactDevice!.contacts.single.sceneId, 'call');
      await h.undo((applied['receipt'] as Map)['receiptId'] as String, jsonl);
      expect(await h.document(), before);
    });

    test(
        '$transport rejects broken references and unknown parameters without writes',
        () async {
      final h = await _Harness.create();
      addTearDown(h.dispose);
      final before = await h.document();
      for (final bad in [
        {
          'configuration': {...configuration, 'acquiredFactId': 'missing'}
        },
        {
          'configuration': {
            ...configuration,
            'contacts': [
              {
                'id': 'mentor',
                'label': 'Mentor',
                'registeredFactId': 'mentor-known',
                'sceneId': 'missing',
                'unavailableSceneId': 'busy'
              }
            ]
          }
        },
        {'configuration': configuration, 'network': true}
      ]) {
        await expectLater(h.plan(bad, jsonl), throwsA(anything));
        expect(await h.document(), before);
      }
    });
  }
}

final class _Harness {
  _Harness(this.root, this.file, this.mapFile, this.api, this.mutations,
      this.snapshots, this.opened, this.worker);

  final Directory root;
  final File file;
  final File mapFile;
  final AuthoringReadApi api;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final OpenedProject opened;
  final JsonlWorker worker;
  int sequence = 0;

  static Future<_Harness> create() async {
    final root = await Directory.systemTemp.createTemp('contact-device-');
    final file = File('${root.path}/project.json');
    final mapFile = File('${root.path}/maps/garden.json');
    await mapFile.parent.create();
    await mapFile.writeAsString(jsonEncode(MapData(
            id: 'garden',
            version: ProjectVersion.v9,
            name: 'Garden',
            size: const GridSize(width: 3, height: 3),
            spatialScene: MapSpatialScene(
                width: 3,
                depth: 3,
                navigation: SpatialNavigationProfile(
                    spawn: SpatialSpawn(x: 1.5, z: 1.5))))
        .toJson()));
    await file.writeAsString(jsonEncode(ProjectManifest(
      name: 'Adventure',
      version: ProjectVersion.v9,
      settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile()),
      maps: const [
        ProjectMapEntry(
            id: 'garden', name: 'Garden', relativePath: 'maps/garden.json')
      ],
      tilesets: [],
      facts: [
        NarrativeFactDefinition(id: 'device-owned', label: 'Device'),
        NarrativeFactDefinition(id: 'mentor-known', label: 'Mentor')
      ],
      scenes: [
        for (final id in ['call', 'busy'])
          SceneAsset(
              id: id,
              name: id,
              graph: SceneGraph(startNodeId: 'start', nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(id: 'end', kind: SceneNodeKind.end)
              ], edges: [
                SceneEdge(
                    id: 'e',
                    fromNodeId: 'start',
                    fromPortId: 'completed',
                    toNodeId: 'end',
                    kind: SceneEdgeKind.defaultFlow)
              ]))
      ],
    ).toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    final opened = await api.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Harness(root, file, mapFile, api, mutations, snapshots, opened,
        JsonlWorker(api: api, mutations: mutations));
  }

  Future<Map<String, Object?>> document() async =>
      Map<String, Object?>.from(jsonDecode(await file.readAsString()) as Map);

  Future<Map<String, Object?>> wire(
      String command, Map<String, Object?> args) async {
    final response = AuthoringResult.fromJson(jsonDecode(
        await worker.processLine(jsonEncode({
      'id': 'wire-${sequence++}',
      'command': command,
      'args': args
    }))) as Map<String, dynamic>);
    if (response.status != AuthoringResultStatus.success) {
      throw StateError(response.toJson().toString());
    }
    return response.data;
  }

  Future<Map<String, Object?>> plan(
      Map<String, Object?> parameters, bool jsonl) async {
    final id = 'contact-${sequence++}';
    final request = AuthoringRequest(
        requestId: id,
        actionId: 'contact_device.configure',
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: (await snapshots.load(opened.projectHandle)).revision,
        idempotencyKey: id,
        parameters: parameters);
    return jsonl
        ? wire('plan', {
            'projectHandle': opened.projectHandle.value,
            'request': request.toJson()
          })
        : mutations.plan(opened.projectHandle, request);
  }

  Future<Map<String, Object?>> apply(
      Map<String, Object?> plan, bool jsonl) async {
    final planId = plan['planId']! as String;
    return jsonl
        ? wire('apply', {
            'projectHandle': opened.projectHandle.value,
            'planId': planId,
            'operationId': 'apply-$planId'
          })
        : mutations.apply(opened.projectHandle,
            planId: planId, operationId: 'apply-$planId');
  }

  Future<void> undo(String entryId, bool jsonl) async {
    if (jsonl) {
      await wire('undo', {
        'projectHandle': opened.projectHandle.value,
        'entryId': entryId,
        'idempotencyKey': 'undo-$entryId'
      });
    } else {
      await mutations.undo(opened.projectHandle,
          entryId: entryId, idempotencyKey: 'undo-$entryId');
    }
  }

  Future<void> dispose() async {
    await mutations.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}
