import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('JSONL creates, reads and deletes one bidirectional connection',
      () async {
    final setup = await _ConnectionJsonlSetup.create();
    addTearDown(setup.dispose);

    final opened = await setup.request(
      'open',
      args: {'projectRoot': setup.root.path},
    );
    expect(opened.status, AuthoringResultStatus.success);
    final projectHandle = ProjectHandle(
      opened.data['projectHandle']! as String,
    );
    final workspaceHandle = opened.data['workspaceHandle']! as String;
    final before = await setup.snapshots.load(projectHandle);

    final createPlan = await setup.request(
      'plan',
      args: {
        'projectHandle': projectHandle.value,
        'request': AuthoringRequest(
          requestId: 'jsonl-connection-create',
          actionId: 'connection.create_bidirectional_apply',
          actionVersion: 1,
          workspaceHandle: workspaceHandle,
          parameters: const {
            'mapId': 'alpha',
            'direction': 'east',
            'targetMapId': 'beta',
            'offset': 1,
          },
          expectedRevision: before.revision,
          idempotencyKey: 'jsonl-connection-create-v1',
        ).toJson(),
      },
    );
    expect(createPlan.status, AuthoringResultStatus.success);
    _expectTwoMapConnectionPlan(
      createPlan,
      sourceMapId: 'alpha',
      targetMapId: 'beta',
    );

    final createApply = await setup.request(
      'apply',
      args: {
        'projectHandle': projectHandle.value,
        'planId': createPlan.data['planId'],
        'operationId': 'jsonl-connection-create-operation',
      },
    );
    expect(createApply.status, AuthoringResultStatus.success);
    final connected = await setup.snapshots.load(projectHandle);
    expect(
      connected.maps.singleWhere((map) => map.id == 'alpha').connections,
      const [
        MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: 'beta',
          offset: 1,
        ),
      ],
    );
    expect(
      connected.maps.singleWhere((map) => map.id == 'beta').connections,
      const [
        MapConnection(
          direction: MapConnectionDirection.west,
          targetMapId: 'alpha',
          offset: -1,
        ),
      ],
    );
    final queriedConnections = await setup.request(
      'query',
      args: {
        'projectHandle': projectHandle.value,
        'request': AuthoringQueryRequest(
          resourceKind: 'mapConnection',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
        ).toJson(),
      },
    );
    expect(queriedConnections.status, AuthoringResultStatus.success);
    expect(
      (queriedConnections.data['items']! as List)
          .cast<Map>()
          .map((item) => item['id']),
      ['alpha:east', 'beta:west'],
    );

    final deletePlan = await setup.request(
      'plan',
      args: {
        'projectHandle': projectHandle.value,
        'request': AuthoringRequest(
          requestId: 'jsonl-connection-delete',
          actionId: 'connection.delete_bidirectional_apply',
          actionVersion: 1,
          workspaceHandle: workspaceHandle,
          parameters: const {
            'mapId': 'alpha',
            'direction': 'east',
          },
          expectedRevision: connected.revision,
          idempotencyKey: 'jsonl-connection-delete-v1',
        ).toJson(),
      },
    );
    expect(deletePlan.status, AuthoringResultStatus.success);
    _expectTwoMapConnectionPlan(
      deletePlan,
      sourceMapId: 'alpha',
      targetMapId: 'beta',
    );

    final deleteApply = await setup.request(
      'apply',
      args: {
        'projectHandle': projectHandle.value,
        'planId': deletePlan.data['planId'],
        'operationId': 'jsonl-connection-delete-operation',
      },
    );
    expect(deleteApply.status, AuthoringResultStatus.success);
    final disconnected = await setup.snapshots.load(projectHandle);
    expect(
      disconnected.maps
          .where((map) => map.id == 'alpha' || map.id == 'beta')
          .expand((map) => map.connections),
      isEmpty,
    );
  });
}

void _expectTwoMapConnectionPlan(
  AuthoringResult result, {
  required String sourceMapId,
  required String targetMapId,
}) {
  final plan = Map<String, Object?>.from(result.data['plan']! as Map);
  final changeSet = Map<String, Object?>.from(plan['changeSet']! as Map);
  final changes = (changeSet['changes']! as List)
      .cast<Map>()
      .map((change) => Map<String, Object?>.from(change))
      .toList(growable: false);
  expect(changes, hasLength(2));
  expect(
    changes.map(
      (change) => Map<String, Object?>.from(change['resource']! as Map)['id'],
    ),
    containsAll(<String>[sourceMapId, targetMapId]),
  );
  final diff = Map<String, Object?>.from(changeSet['diff']! as Map);
  final entries = (diff['entries']! as List)
      .cast<Map>()
      .map((entry) => Map<String, Object?>.from(entry))
      .toList(growable: false);
  expect(entries, hasLength(2));
  expect(entries.map((entry) => entry['path']), everyElement('/connections'));
  final preview = Map<String, Object?>.from(plan['preview']! as Map);
  expect(preview['changedMapCount'], 2);
  expect(preview['multiMapGuarantee'], 'recoverable');
}

final class _ConnectionJsonlSetup {
  const _ConnectionJsonlSetup({
    required this.root,
    required this.snapshots,
    required this.worker,
  });

  final Directory root;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  static Future<_ConnectionJsonlSetup> create() async {
    final root = await Directory.systemTemp.createTemp('jsonl-connection-');
    await Directory('${root.path}/maps').create(recursive: true);
    const maps = [
      MapData(
        id: 'alpha',
        name: 'Alpha',
        size: GridSize(width: 4, height: 3),
      ),
      MapData(
        id: 'beta',
        name: 'Beta',
        size: GridSize(width: 3, height: 3),
      ),
    ];
    const manifest = ProjectManifest(
      name: 'JSONL connection fixture',
      maps: [
        ProjectMapEntry(
          id: 'alpha',
          name: 'Alpha',
          relativePath: 'maps/alpha.json',
        ),
        ProjectMapEntry(
          id: 'beta',
          name: 'Beta',
          relativePath: 'maps/beta.json',
        ),
      ],
      tilesets: [],
    );
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );
    for (final map in maps) {
      await File('${root.path}/maps/${map.id}.json').writeAsBytes(
        encodeMapAuthoringDocument(map),
        flush: true,
      );
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
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
    return _ConnectionJsonlSetup(
      root: root,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  Future<AuthoringResult> request(
    String command, {
    Map<String, Object?> args = const {},
  }) async {
    final decoded = jsonDecode(
      await worker.processLine(
        jsonEncode({
          'id': 'jsonl-connection-$command',
          'command': command,
          'args': args,
        }),
      ),
    ) as Map<String, dynamic>;
    return AuthoringResult.fromJson(decoded);
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}
