import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('Scene item diagnostics agree through direct and JSONL reads', () async {
    final root =
        await Directory.systemTemp.createTemp('scene_item_diagnostics_');
    addTearDown(() => root.delete(recursive: true));
    final scene = SceneAsset.fromJson({
      'id': 'items',
      'name': 'Inventory references',
      'graph': {
        'startNodeId': 'start',
        'nodes': [
          {'id': 'start', 'kind': 'start'},
          {
            'id': 'give',
            'kind': 'action',
            'payload': {
              'consequence': {
                'kind': 'giveItem',
                'itemId': 'tonic',
                'quantity': 1
              },
            }
          },
          {'id': 'end', 'kind': 'end'},
        ],
        'edges': [
          {
            'id': 'enter',
            'fromNodeId': 'start',
            'fromPortId': 'completed',
            'toNodeId': 'give',
            'kind': 'default'
          },
          {
            'id': 'leave',
            'fromNodeId': 'give',
            'fromPortId': 'completed',
            'toNodeId': 'end',
            'kind': 'actionCompleted'
          },
        ],
      },
    });
    final manifest = ProjectManifest(
        name: 'Item diagnostics',
        maps: const [],
        tilesets: const [],
        scenes: [scene]);
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    final itemFile = File('${root.path}/data/pokemon/catalogs/items.json');
    await itemFile.parent.create(recursive: true);
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: ProjectSnapshotLoader(handles: handles));
    final worker = JsonlWorker(api: api);
    addTearDown(worker.close);
    Future<Map<String, Object?>> call(
        String command, Map<String, Object?> args) async {
      final result = AuthoringResult.fromJson(jsonDecode(
              await worker.processLine(jsonEncode(
                  {'id': command, 'command': command, 'args': args})))
          as Map<String, dynamic>);
      expect(result.status, AuthoringResultStatus.success,
          reason: result.error?.toJson().toString());
      return result.data;
    }

    await itemFile.writeAsString(jsonEncode({
      'schemaVersion': 1,
      'entries': [
        {'id': 'tonic', 'displayName': 'Tonic', 'pocketId': 'medicine'}
      ]
    }));
    final opened = await call('open', {'projectRoot': root.path});
    final handle = ProjectHandle(opened['projectHandle']! as String);
    final request = AuthoringQueryRequest(
        resourceKind: 'scene',
        operation: AuthoringQueryOperation.get,
        ids: const ['items'],
        view: AuthoringQueryView.detail);
    Future<List<Map<String, Object?>>> diagnostics() async {
      final direct = await api.query(handle, request);
      final jsonl = await call('query',
          {'projectHandle': handle.value, 'request': request.toJson()});
      expect(jsonl, direct);
      final item = (jsonl['items']! as List).single as Map<String, Object?>;
      return (item['diagnostics']! as List).cast<Map<String, Object?>>();
    }

    expect((await diagnostics()).where((item) => item['severity'] == 'error'),
        isEmpty);
    await itemFile
        .writeAsString(jsonEncode({'schemaVersion': 1, 'entries': []}));
    expect(await diagnostics(),
        contains(containsPair('code', 'consequenceUnknownItem')));
    await itemFile.writeAsString('{invalid');
    expect(
        await diagnostics(),
        contains(allOf(containsPair('code', 'project.item_catalog_invalid'),
            containsPair('severity', 'error'))));
    await itemFile.delete();
    expect(
        await diagnostics(),
        contains(allOf(containsPair('code', 'project.item_catalog_missing'),
            containsPair('severity', 'error'))));
  });
}
