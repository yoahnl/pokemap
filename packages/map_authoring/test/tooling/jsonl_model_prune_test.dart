import 'dart:io';

import 'package:test/test.dart';

import '../support/create_duplicate_model_fixture.dart' as seed;
import '../support/resource_pack_stdio_client.dart';

void main() {
  test('JSONL previews confirms prunes and restores an unused library model',
      () async {
    final base =
        Directory('/Users/karim/Library/Caches/AveluneQA/catalog-model-delete');
    await base.create(recursive: true);
    final root = await base.createTemp('jsonl-');
    ResourcePackStdioClient? client;
    try {
      await seed.main([root.path]);
      final mapBytes = await File('${root.path}/maps/field.json').readAsBytes();
      client = await ResourcePackStdioClient.start(root.path);
      final opened = await client.call('open', {'projectRoot': root.path});
      final handle = opened['projectHandle'];
      await client.call('workshop_prepare',
          {'projectHandle': handle, 'scope': 'resourceIndexes'});
      final parameters = {
        'modelIds': ['same']
      };
      final snapshot = await client.call('workshop_snapshot', {
        'projectHandle': handle,
        'actionId': 'model3d.prune_unused',
        'parameters': parameters,
        'includeDocuments': false,
      });
      final plan = await client.call('plan', {
        'projectHandle': handle,
        'request': {
          'requestId': 'prune',
          'actionId': 'model3d.prune_unused',
          'actionVersion': 1,
          'workspaceHandle': opened['workspaceHandle'],
          'parameters': parameters,
          'expectedRevision': snapshot['snapshotRevision'],
          'idempotencyKey': 'prune',
          'dryRun': false,
          'extensions': snapshot['planExtensions'],
        }
      });
      final preview = (plan['plan'] as Map)['preview'] as Map;
      expect(preview['executionScope'], 'explicit_library_maintenance');
      expect(preview['deletedModelIds'], ['same']);
      expect(
          await File('${root.path}/assets/models3d/same.glb').exists(), isTrue);
      final confirmed = await client
          .call('confirm', {'projectHandle': handle, 'planId': plan['planId']});
      final result = await client.call('apply', {
        'projectHandle': handle,
        'planId': plan['planId'],
        'operationId': 'prune',
        'confirmationToken': confirmed['confirmationToken']
      });
      expect(await File('${root.path}/assets/models3d/same.glb').exists(),
          isFalse);
      expect(
          await File('${root.path}/maps/field.json').readAsBytes(), mapBytes);
      await client.call('undo', {
        'projectHandle': handle,
        'entryId': (result['receipt'] as Map)['receiptId'],
        'idempotencyKey': 'undo-prune'
      });
      expect(
          await File('${root.path}/assets/models3d/same.glb').exists(), isTrue);
      await client
          .call('close', {'workspaceHandle': opened['workspaceHandle']});
    } finally {
      await client?.close();
      await root.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
