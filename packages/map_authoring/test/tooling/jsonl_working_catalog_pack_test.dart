import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../domains/assets/resource_pack_import_fixture.dart';
import '../support/resource_pack_stdio_client.dart';

void main() {
  test(
      'real JSONL pack jobs retain the working descriptor through import and history',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    ResourcePackStdioClient? client;
    try {
      final manifest =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      await fixture.close();
      final store =
          await CatalogStorageStore.open(projectRoot: fixture.root.path);
      await WorkingProjectCatalog.create(
          store: store,
          projectId: 'working-pack',
          project: manifest,
          expectedProjectRevision:
              await store.gateway.readResourceRevision('project.json'));
      final descriptor =
          await File('${fixture.root.path}/project.json').readAsBytes();
      final archivePath =
          '${fixture.source.directory.path}/source.aveluneassets';
      final sink = File(archivePath).openWrite();
      await fixture.source.archive
          .withSource((source) => sink.addStream(sourceChunks(source)));
      await sink.close();
      client =
          await ResourcePackStdioClient.start(fixture.source.directory.path);
      var opened =
          await client.call('open', {'projectRoot': fixture.root.path});
      final plan =
          await client.planImport(opened, archivePath, 'working-pack-import');
      await client.call(
          'apply',
          {
            'projectHandle': opened['projectHandle'],
            'planId': plan['planId'],
            'operationId': 'working-pack-apply'
          },
          error: 'resource_pack.job_required');
      final applied = await client.result(
          opened,
          await client.pack(opened, 'start_apply',
              {'planId': plan['planId'], 'operationId': 'working-pack-apply'}));
      expect((applied['receipt'] as Map)['actionId'], 'resource_pack.import');
      expect(await File('${fixture.root.path}/project.json').readAsBytes(),
          descriptor);
      final history = await client.call(
          'history', {'projectHandle': opened['projectHandle'], 'limit': 20});
      expect(history['entries'], isNotEmpty);
      final undone = await client.history(opened, 'undo',
          (applied['receipt'] as Map)['receiptId'], 'working-pack-undo');
      expect((undone['receipt'] as Map)['actionId'], 'history.undo');
      await client.history(opened, 'redo',
          (applied['receipt'] as Map)['receiptId'], 'working-pack-redo');
      expect(await File('${fixture.root.path}/project.json').readAsBytes(),
          descriptor);
      final library = await client.call('query', {
        'projectHandle': opened['projectHandle'],
        'request': AuthoringQueryRequest(
                resourceKind: 'element',
                operation: AuthoringQueryOperation.list)
            .toJson()
      });
      final element = (library['items'] as List).first as Map;
      final rename = await client.call('plan', {
        'projectHandle': opened['projectHandle'],
        'request': AuthoringRequest(
            requestId: 'rename-pack',
            actionId: 'catalog.definition.update',
            actionVersion: 1,
            workspaceHandle: opened['workspaceHandle'] as String,
            expectedRevision: library['snapshotRevision'] as String,
            idempotencyKey: 'rename-pack',
            parameters: {
              'resourceKind': 'element',
              'id': element['id'],
              'name': 'Changed after import'
            }).toJson()
      });
      await client.call('apply', {
        'projectHandle': opened['projectHandle'],
        'planId': rename['planId'],
        'operationId': 'rename-pack'
      });
      final maps = await client.call('query', {
        'projectHandle': opened['projectHandle'],
        'request': AuthoringQueryRequest(
            resourceKind: 'project',
            operation: AuthoringQueryOperation.get,
            ids: const ['project'],
            view: AuthoringQueryView.detail,
            extensions: const {'materializeProject': true}).toJson()
      });
      final mapPlan = await client.call('plan', {
        'projectHandle': opened['projectHandle'],
        'request': AuthoringRequest(
            requestId: 'independent-map',
            actionId: 'map.create',
            actionVersion: 1,
            workspaceHandle: opened['workspaceHandle'] as String,
            expectedRevision: maps['snapshotRevision'] as String,
            idempotencyKey: 'independent-map',
            parameters: const {
              'mapId': 'independent',
              'name': 'Independent',
              'width': 8,
              'height': 6
            }).toJson()
      });
      final mapApplied = await client.call('apply', {
        'projectHandle': opened['projectHandle'],
        'planId': mapPlan['planId'],
        'operationId': 'independent-map'
      });
      final reverted = await client.history(opened, 'revert',
          (applied['receipt'] as Map)['receiptId'], 'working-pack-revert',
          expectedHeadEntryId: (mapApplied['receipt'] as Map)['receiptId']);
      expect((reverted['receipt'] as Map)['actionId'], 'history.revert');
      final preserved = await client.call('query', {
        'projectHandle': opened['projectHandle'],
        'request': AuthoringQueryRequest(
            resourceKind: 'map',
            operation: AuthoringQueryOperation.get,
            ids: const ['independent']).toJson()
      });
      expect((preserved['items'] as List).single,
          containsPair('name', 'Independent'));
      expect(await File('${fixture.root.path}/project.json').readAsBytes(),
          descriptor);
      await client
          .call('close', {'workspaceHandle': opened['workspaceHandle']});
      opened = await client.call('open', {'projectRoot': fixture.root.path});
      final replay = await client.result(
          opened,
          await client.pack(opened, 'start_apply',
              {'planId': plan['planId'], 'operationId': 'working-pack-apply'}));
      expect((replay['receipt'] as Map)['receiptId'],
          (applied['receipt'] as Map)['receiptId']);
      expect(await File('${fixture.root.path}/project.json').readAsBytes(),
          descriptor);
      await client
          .call('close', {'workspaceHandle': opened['workspaceHandle']});
    } finally {
      await client?.close();
      await fixture.dispose();
    }
  }, timeout: const Timeout(Duration(seconds: 90)));
}
