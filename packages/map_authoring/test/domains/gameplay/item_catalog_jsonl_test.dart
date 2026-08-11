import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('direct API and JSONL expose the same canonical item semantics',
      () async {
    final direct = await _ItemTransportHarness.create('direct');
    final jsonl = await _ItemTransportHarness.create('jsonl');
    addTearDown(direct.dispose);
    addTearDown(jsonl.dispose);

    final directOpened = await direct.readApi.openProject(direct.root.path);
    await direct.mutations.attachProject(
      projectRootPath: direct.root.path,
      workspaceHandle: directOpened.workspaceHandle,
      projectHandle: directOpened.projectHandle,
    );
    final directSnapshot = await direct.snapshots.load(
      directOpened.projectHandle,
    );
    final directRequest = _createRequest(
      workspaceHandle: directOpened.workspaceHandle.value,
      revision: directSnapshot.revision,
      suffix: 'direct',
    );
    final directPlan = await direct.mutations.plan(
      directOpened.projectHandle,
      directRequest,
    );
    final directApplied = await direct.mutations.apply(
      directOpened.projectHandle,
      planId: directPlan['planId']! as String,
      operationId: 'operation-item-direct',
    );

    final described = await _request(jsonl.worker, 'describe');
    final resourceKinds = (described.data['resourceKinds']! as List)
        .cast<Map<String, Object?>>()
        .map((descriptor) => descriptor['id'])
        .toSet();
    expect(
      resourceKinds,
      containsAll(<String>{
        'itemCatalog',
        'itemDefinition',
        'itemUsage',
        'itemReadiness',
      }),
    );
    final actionIds = (described.data['mutationActions']! as List)
        .cast<Map<String, Object?>>()
        .map((descriptor) => descriptor['id'])
        .whereType<String>()
        .where((id) => id.startsWith('item.'))
        .toSet();
    expect(actionIds, _durableItemActionIds);

    final jsonlOpened = await _request(
      jsonl.worker,
      'open',
      args: <String, Object?>{'projectRoot': jsonl.root.path},
    );
    final projectHandle = jsonlOpened.data['projectHandle']! as String;
    final workspaceHandle = jsonlOpened.data['workspaceHandle']! as String;
    final definitions = await _query(
      jsonl.worker,
      projectHandle: projectHandle,
      request: AuthoringQueryRequest(
        resourceKind: 'itemDefinition',
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail,
      ),
    );
    final usages = await _query(
      jsonl.worker,
      projectHandle: projectHandle,
      request: AuthoringQueryRequest(
        resourceKind: 'itemUsage',
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail,
      ),
    );
    final readiness = await _query(
      jsonl.worker,
      projectHandle: projectHandle,
      request: AuthoringQueryRequest(
        resourceKind: 'itemReadiness',
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail,
      ),
    );
    expect(definitions.data['returned'], 1);
    expect(usages.data['returned'], 1);
    expect(readiness.data['returned'], 1);

    final jsonlRequest = _createRequest(
      workspaceHandle: workspaceHandle,
      revision: definitions.data['snapshotRevision']! as String,
      suffix: 'jsonl',
    );
    final jsonlPlan = await _request(
      jsonl.worker,
      'plan',
      args: <String, Object?>{
        'projectHandle': projectHandle,
        'request': jsonlRequest.toJson(),
      },
    );
    final jsonlApplied = await _request(
      jsonl.worker,
      'apply',
      args: <String, Object?>{
        'projectHandle': projectHandle,
        'planId': jsonlPlan.data['planId'],
        'operationId': 'operation-item-jsonl',
      },
    );
    final simulation = await _query(
      jsonl.worker,
      projectHandle: projectHandle,
      request: AuthoringQueryRequest(
        resourceKind: 'itemDefinition',
        operation: AuthoringQueryOperation.get,
        ids: const <String>['field-tonic'],
        view: AuthoringQueryView.detail,
        extensions: const <String, Object?>{
          'actionId': 'item.simulate',
          'parameters': <String, Object?>{
            'itemId': 'field-tonic',
            'context': 'overworld',
          },
        },
      ),
    );

    expect(
      (directApplied['receipt']! as Map)['actionId'],
      'item.create',
    );
    expect(
      (jsonlApplied.data['receipt']! as Map)['actionId'],
      'item.create',
    );
    expect(
      ((simulation.data['items']! as List).single as Map)['simulation'],
      containsPair('context', 'overworld'),
    );
    expect(await direct.catalogIds(), <String>['potion', 'field-tonic']);
    expect(await jsonl.catalogIds(), <String>['potion', 'field-tonic']);
  });
}

const _durableItemActionIds = <String>{
  'item.create',
  'item.update',
  'item.clone',
  'item.delete_apply',
  'item.set_overworld_effect',
  'item.set_battle_effect',
  'item.set_held_effect',
  'item.set_capture_effect',
  'item.set_tm_hm_move',
};

AuthoringRequest _createRequest({
  required String workspaceHandle,
  required String revision,
  required String suffix,
}) {
  return AuthoringRequest(
    requestId: 'item-create-$suffix',
    actionId: 'item.create',
    actionVersion: 1,
    workspaceHandle: workspaceHandle,
    parameters: <String, Object?>{
      'definition': const ProjectItemDefinition(
        id: 'field-tonic',
        displayName: 'Field Tonic',
        pocketId: 'medicine',
        buyPrice: 300,
      ).toJson(),
    },
    expectedRevision: revision,
    idempotencyKey: 'item-create-$suffix',
  );
}

Future<AuthoringResult> _query(
  JsonlWorker worker, {
  required String projectHandle,
  required AuthoringQueryRequest request,
}) {
  return _request(
    worker,
    'query',
    args: <String, Object?>{
      'projectHandle': projectHandle,
      'request': request.toJson(),
    },
  );
}

Future<AuthoringResult> _request(
  JsonlWorker worker,
  String command, {
  Map<String, Object?> args = const <String, Object?>{},
}) async {
  final response = await worker.processLine(
    jsonEncode(<String, Object?>{
      'id': 'item-$command',
      'command': command,
      'args': args,
    }),
  );
  return AuthoringResult.fromJson(
    jsonDecode(response) as Map<String, dynamic>,
  );
}

final class _ItemTransportHarness {
  _ItemTransportHarness({
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

  static Future<_ItemTransportHarness> create(String suffix) async {
    final root = await Directory.systemTemp.createTemp(
      'item-authoring-$suffix-',
    );
    await File('${root.path}/project.json').writeAsString(
      jsonEncode(
        const ProjectManifest(
          name: 'Item transport fixture',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          newGame: ProjectNewGameConfig(
            initialBag: <BagEntry>[
              BagEntry(itemId: 'potion', quantity: 1),
            ],
          ),
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
                id: 'potion',
                displayName: 'Potion',
                pocketId: 'medicine',
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
    return _ItemTransportHarness(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  Future<List<String>> catalogIds() async {
    final decoded = jsonDecode(
      await File(
        '${root.path}/data/pokemon/catalogs/items.json',
      ).readAsString(),
    ) as Map<String, dynamic>;
    return decodeProjectItemCatalog(decoded)
        .entries
        .map((definition) => definition.id)
        .toList(growable: false);
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}
