import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/resource_pack_stdio_client.dart';

void main() {
  for (final catalog in [true, false]) {
  test('JSONL exposes bounded workshop publications catalog=$catalog',
      () async {
    final root = await Directory.systemTemp.createTemp('workshop-jsonl-');
    ResourcePackStdioClient? client;
    try {
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      final project = const ProjectManifest(name: 'Workshop', maps: [
            ProjectMapEntry(
                id: 'unread', name: 'Unread', relativePath: 'maps/missing.json')
          ], tilesets: [
            ProjectTilesetEntry(
                id: 'unread',
                name: 'Unread',
                relativePath: 'assets/missing.png')
          ], trainers: [
            ProjectTrainerEntry(
                id: 'selected', name: 'Before', trainerClass: 'Trainer')
          ]);
      if (catalog) {
        await WorkingProjectCatalog.create(store: store, projectId: 'workshop', project: project);
      } else {
        await File('${root.path}/project.json').writeAsString(jsonEncode(project.toJson()));
      }
      final descriptor = await File('${root.path}/project.json').readAsBytes();
      client = await ResourcePackStdioClient.start(root.path);
      final description = await client.call('describe', {});
      expect(
          (description['commands'] as List)
              .cast<Map>()
              .map((value) => value['id']),
          containsAll(['workshop_snapshot', 'workshop_prepare']));
      final opened = await client.call('open', {'projectRoot': root.path});
      final handle = opened['projectHandle'];
      final prepared =
          await client.call('workshop_prepare', {'projectHandle': handle});
      expect(prepared['prepared'], isTrue);
      final parameters = {
        'value': const ProjectTrainerEntry(
                id: 'selected', name: 'After', trainerClass: 'Trainer')
            .toJson()
      };
      final before = await client.call('workshop_snapshot', {
        'projectHandle': handle,
        'actionId': 'campaign.trainer.upsert',
        'parameters': parameters
      });
      expect((before['project'] as Map)['trainers'], hasLength(1));
      expect(before['maps'], isEmpty);
      final plan = await client.call('plan', {
        'projectHandle': handle,
        'request': AuthoringRequest(
                requestId: 'trainer',
                actionId: 'campaign.trainer.upsert',
                actionVersion: 1,
                workspaceHandle: opened['workspaceHandle'] as String,
                expectedRevision: before['snapshotRevision'] as String,
                idempotencyKey: 'trainer',
                parameters: parameters)
            .toJson()
      });
      await client.call('apply', {
        'projectHandle': handle,
        'planId': plan['planId'],
        'operationId': 'trainer-operation'
      });
      final after = await client.call('workshop_snapshot', {
        'projectHandle': handle,
        'actionId': 'campaign.trainer.upsert',
        'parameters': parameters
      });
      expect(
          (((after['project'] as Map)['trainers'] as List).single
              as Map)['name'],
          'After');
      if (catalog) {
        expect(await File('${root.path}/project.json').readAsBytes(), descriptor);
        expect(jsonDecode(utf8.decode(descriptor))['format'], 'avelune.working-catalog');
      } else {
        final persisted = jsonDecode(await File('${root.path}/project.json').readAsString()) as Map;
        expect(persisted['maps'], project.toJson()['maps']);
        expect(persisted['tilesets'], project.toJson()['tilesets']);
        expect((persisted['trainers'] as List).single['name'], 'After');
      }
    } finally {
      await client?.close();
      await root.delete(recursive: true);
    }
  });
  }
}
