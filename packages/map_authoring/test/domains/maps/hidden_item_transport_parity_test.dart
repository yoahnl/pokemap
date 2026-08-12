import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('hidden item payload executes through direct API and JSONL', () async {
    final direct = await _HiddenItemHarness.create('direct');
    final jsonl = await _HiddenItemHarness.create('jsonl');
    addTearDown(direct.dispose);
    addTearDown(jsonl.dispose);

    final directReceipt = await direct.executeDirect();
    final jsonlReceipt = await jsonl.executeJsonl();

    expect(directReceipt['actionId'], 'entity.set_item_payload');
    expect(jsonlReceipt['actionId'], 'entity.set_item_payload');
    expect(directReceipt['status'], 'applied');
    expect(jsonlReceipt['status'], 'applied');
    expect(await direct.visibility(), MapEntityItemVisibility.hidden);
    expect(await jsonl.visibility(), MapEntityItemVisibility.hidden);
  });
}

final class _HiddenItemHarness {
  _HiddenItemHarness({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
  });

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  static Future<_HiddenItemHarness> create(String suffix) async {
    final root = await Directory.systemTemp.createTemp(
      'hidden-item-authoring-$suffix-',
    );
    await Directory('${root.path}/maps').create(recursive: true);
    await File('${root.path}/project.json').writeAsString(
      jsonEncode(
        const ProjectManifest(
          name: 'Hidden item transport fixture',
          maps: <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'lab',
              name: 'Lab',
              relativePath: 'maps/lab.json',
            ),
          ],
          tilesets: <ProjectTilesetEntry>[],
        ).toJson(),
      ),
    );
    await File('${root.path}/maps/lab.json').writeAsString(
      jsonEncode(
        const MapData(
          id: 'lab',
          name: 'Lab',
          size: GridSize(width: 3, height: 3),
          entities: <MapEntity>[
            MapEntity(
              id: 'secret',
              kind: MapEntityKind.item,
              pos: GridPos(x: 1, y: 1),
              item: MapEntityItemData(gameItemId: 'tonic'),
            ),
          ],
        ).toJson(),
      ),
    );
    final catalogFile = File(
      '${root.path}/data/pokemon/catalogs/items.json',
    );
    await catalogFile.parent.create(recursive: true);
    await catalogFile.writeAsString(
      jsonEncode(
        encodeProjectItemCatalog(
          const ProjectItemCatalog(
            schemaVersion: 1,
            entries: <ProjectItemDefinition>[
              ProjectItemDefinition(
                id: 'tonic',
                displayName: 'Tonic',
                pocketId: 'items',
              ),
            ],
          ),
        ),
      ),
    );
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
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
    return _HiddenItemHarness(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  Future<Map<String, Object?>> executeDirect() async {
    final opened = await readApi.openProject(root.path);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    final snapshot = await snapshots.load(opened.projectHandle);
    final plan = await mutations.plan(
      opened.projectHandle,
      _request(
        workspaceHandle: opened.workspaceHandle.value,
        revision: snapshot.revision,
        suffix: 'direct',
      ),
    );
    final applied = await mutations.apply(
      opened.projectHandle,
      planId: plan['planId']! as String,
      operationId: 'hidden-item-direct',
    );
    return Map<String, Object?>.from(applied['receipt']! as Map);
  }

  Future<Map<String, Object?>> executeJsonl() async {
    final opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    final projectHandle = opened.data['projectHandle']! as String;
    final workspaceHandle = opened.data['workspaceHandle']! as String;
    final snapshot = await snapshots.load(ProjectHandle(projectHandle));
    final planned = await _jsonl('plan', <String, Object?>{
      'projectHandle': projectHandle,
      'request': _request(
        workspaceHandle: workspaceHandle,
        revision: snapshot.revision,
        suffix: 'jsonl',
      ).toJson(),
    });
    final applied = await _jsonl('apply', <String, Object?>{
      'projectHandle': projectHandle,
      'planId': planned.data['planId'],
      'operationId': 'hidden-item-jsonl',
    });
    return Map<String, Object?>.from(applied.data['receipt']! as Map);
  }

  AuthoringRequest _request({
    required String workspaceHandle,
    required String revision,
    required String suffix,
  }) {
    return AuthoringRequest(
      requestId: 'hidden-item-$suffix',
      actionId: 'entity.set_item_payload',
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: <String, Object?>{
        'mapId': 'lab',
        'entityId': 'secret',
        'payload': const MapEntityItemData(
          gameItemId: 'tonic',
          quantity: 1,
          visibility: MapEntityItemVisibility.hidden,
        ).toJson(),
      },
      expectedRevision: revision,
      idempotencyKey: 'hidden-item-$suffix',
      dryRun: false,
    );
  }

  Future<AuthoringResult> _jsonl(
    String command,
    Map<String, Object?> args,
  ) async {
    return AuthoringResult.fromJson(
      jsonDecode(
        await worker.processLine(
          jsonEncode(<String, Object?>{
            'id': 'hidden-item-$command',
            'command': command,
            'args': args,
          }),
        ),
      ) as Map<String, dynamic>,
    );
  }

  Future<MapEntityItemVisibility> visibility() async {
    final map = MapData.fromJson(
      jsonDecode(await File('${root.path}/maps/lab.json').readAsString())
          as Map<String, dynamic>,
    );
    return map.entities.single.item!.visibility;
  }

  Future<void> dispose() async {
    await root.delete(recursive: true);
  }
}
