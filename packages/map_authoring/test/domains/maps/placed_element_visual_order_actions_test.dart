import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'canonical JSONL plans and persists forward/backward without gameplay reorder',
      () async {
    final root = await Directory.systemTemp.createTemp('visual-order-');
    addTearDown(() => root.delete(recursive: true));
    final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 3, height: 3),
        layers: const [
          MapLayer.tile(
              id: 'decor', name: 'Decor', cells: [0, 0, 0, 0, 0, 0, 0, 0, 0])
        ],
        placedElements: [
          for (final id in ['a', 'b'])
            MapPlacedElement(
                id: id,
                elementId: 'prop',
                layerId: 'decor',
                pos: const GridPos(x: 1, y: 1),
                properties: const {'preserved': 'yes'})
        ]);
    final manifest = ProjectManifest(name: 'Order', maps: const [
      ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')
    ], tilesets: const [
      ProjectTilesetEntry(id: 'ts', name: 'TS', relativePath: 'assets/ts.png')
    ], elementCategories: const [
      ProjectElementCategory(id: 'cat', name: 'Cat')
    ], elements: const [
      ProjectElementEntry(
          id: 'prop',
          name: 'Prop',
          tilesetId: 'ts',
          categoryId: 'cat',
          frames: [
            TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1))
          ])
    ]);
    await Directory('${root.path}/maps').create();
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    final mapFile = File('${root.path}/maps/map.json');
    await mapFile.writeAsString(jsonEncode(map.toJson()));
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
    final worker = JsonlWorker(api: api, mutations: mutations);
    final described = await _call(worker, 'describe');
    final actions = (described.data['mutationActions']! as List).cast<Map>();
    for (final id in [
      'placed_element.bring_forward',
      'placed_element.send_backward'
    ]) {
      expect(actions.any((action) => action['id'] == id), isTrue);
    }
    final opened = await _call(worker, 'open', {'projectRoot': root.path});
    expect(opened.status, AuthoringResultStatus.success);
    final handle = opened.data['projectHandle']! as String;
    for (final forward in [true, false]) {
      final snapshot = await snapshots.load(ProjectHandle(handle));
      final request = AuthoringRequest(
          requestId: 'order-$forward',
          actionId: forward
              ? 'placed_element.bring_forward'
              : 'placed_element.send_backward',
          actionVersion: 1,
          workspaceHandle: opened.data['workspaceHandle']! as String,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'order-$forward',
          dryRun: false,
          parameters: const {
            'mapId': 'map',
            'instanceId': 'a',
            'x': 1,
            'y': 1
          });
      final planned = await _call(worker, 'plan',
          {'projectHandle': handle, 'request': request.toJson()});
      expect(planned.status, AuthoringResultStatus.success,
          reason: planned.toJson().toString());
      final applied = await _call(worker, 'apply', {
        'projectHandle': handle,
        'planId': planned.data['planId'],
        'operationId': 'apply-$forward'
      });
      expect(applied.status, AuthoringResultStatus.success,
          reason: applied.toJson().toString());
      final saved = MapData.fromJson(
          jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>);
      expect(saved.placedElements.map((e) => e.id), ['a', 'b']);
      expect(
          sortMapPlacedElementsForPainting(saved.placedElements)
              .map((e) => e.id),
          forward ? ['b', 'a'] : ['a', 'b']);
      expect(saved.placedElements.first.properties,
          map.placedElements.first.properties);
    }
    await _call(worker, 'close', {'projectHandle': handle});
  });
}

Future<AuthoringResult> _call(JsonlWorker worker, String command,
        [Map<String, Object?> args = const {}]) async =>
    AuthoringResult.fromJson(jsonDecode(await worker.processLine(
            jsonEncode({'id': command, 'command': command, 'args': args})))
        as Map<String, dynamic>);
