import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_documents.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('JSONL and typed API edit locks without admitting project content',
      () async {
    final root = await Directory.systemTemp.createTemp('map-editor-jsonl-');
    addTearDown(() => root.delete(recursive: true));
    await Directory('${root.path}/maps').create();
    final project = File('${root.path}/project.json');
    final map = File('${root.path}/maps/bourg.json');
    await project.writeAsString('undecodable project');
    await map.writeAsString('undecodable map');
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: const LocalProjectFileReader(),
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(
      handles: handles,
      fingerprintCache: ProjectSnapshotFingerprintCache(),
      snapshotCache: ProjectSnapshotCache(),
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    final worker = JsonlWorker(
      api: AuthoringReadApi(
        openService: ProjectOpenService(
          policy: policy,
          fileReader: const LocalProjectFileReader(),
          handles: handles,
        ),
        snapshotLoader: snapshots,
      ),
      mutations: mutations,
      mapEditor: LocalMapEditorAuthoring(policy: policy),
      mapElementOrder: LocalMapElementOrderAuthoring(policy: policy),
    );
    addTearDown(worker.close);
    var sequence = 0;
    Future<Map<String, dynamic>> call(String command, Map<String, Object?> args,
        {bool failure = false}) async {
      final response = jsonDecode(await worker.processLine(jsonEncode({
        'id': 'editor-${sequence++}',
        'command': command,
        'args': args,
      }))) as Map<String, dynamic>;
      expect(response['status'], failure ? 'failure' : 'success',
          reason: jsonEncode(response));
      return response[failure ? 'error' : 'data'] as Map<String, dynamic>;
    }

    final description = await call('describe', {});
    expect((description['mapEditorAuthoring'] as Map)['id'], 'map.editor.set');
    final lifecycleIds = {
      'map.create',
      'map.duplicate',
      'map.rename',
      'map.delete_apply'
    };
    final lifecycleActions = (description['mutationActions'] as List)
        .cast<Map>()
        .where((action) => lifecycleIds.contains(action['id']))
        .toList();
    expect(lifecycleActions, hasLength(4));
    for (final action in lifecycleActions) {
      expect(
          action['resourceKinds'], containsAll(['mapAtmosphere', 'mapEditor']));
      expect((action['extensions'] as Map)['associatedDocuments'],
          ['mapAtmosphere', 'mapEditor']);
    }

    final initial = await mutations.inspectMapEditor(
        projectRoot: root.path, mapId: 'bourg');
    expect(initial.state.lockedElements, isEmpty);
    final state = MapEditorState(
      lockedElements: {'decor:back-particles'},
      lockedFamilies: {'decor'},
    );
    final input = <String, Object?>{
      'projectRoot': root.path,
      'mapId': 'bourg',
      'expectedRevision': initial.revision,
      'state': state.toJson(),
      'operationId': 'editor-jsonl-lock',
    };
    final changed = await call('map_editor_set', input);
    final receiptId = (changed['receipt'] as Map)['receiptId'] as String;
    expect(changed['afterState'], state.toJson());
    final reread = await mutations.inspectMapEditor(
        projectRoot: root.path, mapId: 'bourg');
    expect(reread.state, state);
    final replay = await call('map_editor_set', input);
    expect((replay['receipt'] as Map)['receiptId'], receiptId);
    await call('map_editor_set', {...input, 'operationId': 'editor-stale'},
        failure: true);
    await call(
        'map_editor_set',
        {
          ...input,
          'expectedRevision': reread.revision,
          'operationId': 'editor-unknown-property',
          'state': {'arbitrary': true},
        },
        failure: true);
    final undone = await mutations.undoMapEditor(
      projectRoot: root.path,
      mapId: 'bourg',
      receiptId: receiptId,
      expectedRevision: reread.revision,
      operationId: 'editor-api-undo',
    );
    expect(undone.afterRevision, initial.revision);
    final observed = await call('map_editor_inspect', {
      'projectRoot': root.path,
      'mapId': 'bourg',
    });
    expect(observed['state'], MapEditorState().toJson());
    expect(await project.readAsString(), 'undecodable project');
    expect(await map.readAsString(), 'undecodable map');
    final mapData = MapData(
      id: 'bourg',
      name: 'Bourg',
      size: const GridSize(width: 2, height: 2),
      layers: const [
        TileLayer(id: 'front', name: 'Front'),
        TileLayer(id: 'back', name: 'Back'),
      ],
      placedElements: const [
        MapPlacedElement(
            id: 'particles',
            layerId: 'front',
            elementId: 'particles',
            pos: GridPos(x: 0, y: 0)),
        MapPlacedElement(
            id: 'tree',
            layerId: 'front',
            elementId: 'tree',
            pos: GridPos(x: 0, y: 0),
            visualOrder: 1),
      ],
    );
    await map.writeAsString(
        jsonEncode({...mapData.toJson(), 'futureField': 'keep'}));
    final stack = await mutations.inspectMapElementOrder(
        projectRoot: root.path, mapId: 'bourg');
    final layered = await mutations.reorderMapElements(
      projectRoot: root.path,
      mapId: 'bourg',
      expectedRevision: stack.revision,
      kind: 'layers',
      frontFirstIds: ['back', 'front'],
      operationId: 'editor-api-order',
    );
    expect(layered.afterMap.layers.map((layer) => layer.id), ['back', 'front']);
    final decorated = await call('map_elements_reorder', {
      'projectRoot': root.path,
      'mapId': 'bourg',
      'expectedRevision': layered.afterRevision,
      'kind': 'decor',
      'layerId': 'front',
      'frontFirstIds': ['particles', 'tree'],
      'operationId': 'editor-jsonl-order',
    });
    final afterMap = decorated['afterMap'] as Map;
    expect(afterMap['futureField'], 'keep');
    expect(
        (afterMap['placedElements'] as List)
            .map((element) => (element as Map)['visualOrder']),
        [1, 0]);
    final undoOrder = await call('map_elements_undo', {
      'projectRoot': root.path,
      'mapId': 'bourg',
      'expectedRevision': decorated['afterRevision'],
      'receiptId': (decorated['receipt'] as Map)['receiptId'],
      'operationId': 'editor-jsonl-order-undo',
    });
    expect(undoOrder['afterMap'], layered.receipt.diff.entries.single.after);
    final reloadedOrder = await mutations.inspectMapElementOrder(
        projectRoot: root.path, mapId: 'bourg');
    expect(undoOrder['afterRevision'], reloadedOrder.revision);
    expect(await project.readAsString(), 'undecodable project');
  });
}
