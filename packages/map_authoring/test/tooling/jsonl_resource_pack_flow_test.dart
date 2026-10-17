import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../domains/assets/resource_pack_import_fixture.dart';
import '../application/resource_pack_transfer_api_test.dart' show waitForJob;
import '../support/resource_pack_stdio_client.dart';

void main() {
  test(
      'JSONL correlation identities are bounded at both ASCII and UTF8 boundaries',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    final transfer = LocalResourcePackTransferApi(
        mutations: fixture.mutations, snapshotLoader: fixture.loader);
    final worker = JsonlWorker(
        api: fixture.readApi,
        mutations: fixture.mutations,
        resourcePacks: transfer);
    try {
      for (final id in [
        'x' * 128,
        'é' * 64,
        'x' * 129,
        'é' * 65,
        'x' * (256 * 1024)
      ]) {
        final response = await worker.processLine(jsonEncode({
          'id': id,
          'command': 'resource_pack',
          'args': {
            'projectHandle': fixture.opened.projectHandle.value,
            'verb': 'recovery_status',
            'input': {}
          }
        }));
        final decoded = jsonDecode(response) as Map;
        expect(utf8.encode(response).length, lessThanOrEqualTo(256 * 1024));
        if (utf8.encode(id).length <= 128) {
          expect(decoded['status'], 'success');
          expect(decoded['requestId'], id);
        } else {
          expect(decoded['requestId'], 'invalid');
          expect(decoded['status'], 'failure');
          expect(((decoded['error'] as Map)['details'] as Map)['domainCode'],
              'worker.request_id_invalid');
        }
      }
    } finally {
      await transfer.closeTransferWorkspace(fixture.opened.workspaceHandle);
      await fixture.dispose();
    }
  });
  test(
    'synchronous JSONL mutations require jobs for canonical pack provenance',
    () async {
      final fixture = await NativeResourcePackImportFixture.create();
      var transfer = LocalResourcePackTransferApi(
        mutations: fixture.mutations,
        snapshotLoader: fixture.loader,
      );
      var worker = JsonlWorker(
        api: fixture.readApi,
        mutations: fixture.mutations,
        resourcePacks: transfer,
      );
      Future<Map> command(String name, Map<String, Object?> input) async =>
          jsonDecode(
            await worker.processLine(
              jsonEncode({
                'id': name,
                'command': name,
                'args': {
                  'projectHandle': fixture.opened.projectHandle.value,
                  ...input,
                },
              }),
            ),
          ) as Map;
      try {
        final plan = await fixture.plan(await fixture.prepare());
        final before =
            await File('${fixture.root.path}/project.json').readAsBytes();
        final refused = await command('apply', {
          'planId': plan.planId,
          'operationId': 'job-only',
        });
        expect(refused['status'], 'failure', reason: refused.toString());
        expect(
          ((refused['error'] as Map)['details'] as Map)['domainCode'],
          'resource_pack.job_required',
        );
        expect(
          await File('${fixture.root.path}/project.json').readAsBytes(),
          before,
        );
        final applied = await waitForJob(
          transfer,
          fixture.opened.projectHandle,
          await transfer.transfer(
            fixture.opened.projectHandle,
            verb: 'start_apply',
            input: {'planId': plan.planId, 'operationId': 'job-only'},
          ),
        );
        final receipt = (applied['result'] as Map)['receipt'] as Map;
        for (final probe in [
          ('apply', {'planId': plan.planId, 'operationId': 'job-only'}),
          (
            'undo',
            {'entryId': receipt['receiptId'], 'idempotencyKey': 'legacy-undo'},
          ),
          ('recover', {'operationId': 'job-only'}),
        ]) {
          final response = await command(probe.$1, probe.$2);
          expect(response['status'], 'failure', reason: response.toString());
          expect(
            ((response['error'] as Map)['details'] as Map)['domainCode'],
            'resource_pack.job_required',
          );
        }
        final snapshot = await fixture.loader.load(
          fixture.opened.projectHandle,
        );
        final ordinary = await fixture.mutations.planMutation(
          fixture.opened.projectHandle,
          AuthoringRequest(
            requestId: 'ordinary',
            actionId: 'resource.family.create',
            actionVersion: 1,
            workspaceHandle: fixture.opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'ordinary',
            parameters: {'familyId': 'ordinary', 'name': 'Ordinary'},
          ),
        );
        final ordinaryApplied = await command('apply', {
          'planId': ordinary.planId,
          'operationId': 'ordinary',
        });
        expect(
          ordinaryApplied['status'],
          'success',
          reason: ordinaryApplied.toString(),
        );
        final ordinaryReceipt =
            ((ordinaryApplied['data'] as Map)['receipt'] as Map);
        final undone = await command('undo', {
          'entryId': ordinaryReceipt['receiptId'],
          'idempotencyKey': 'ordinary-undo',
        });
        expect(undone['status'], 'success', reason: undone.toString());
        await transfer.closeTransferWorkspace(fixture.opened.workspaceHandle);
        await fixture.close();
        await fixture.open();
        transfer = LocalResourcePackTransferApi(
            mutations: fixture.mutations, snapshotLoader: fixture.loader);
        worker = JsonlWorker(
            api: fixture.readApi,
            mutations: fixture.mutations,
            resourcePacks: transfer);
        final replay = await command(
            'apply', {'planId': ordinary.planId, 'operationId': 'ordinary'});
        expect(replay['status'], 'success', reason: replay.toString());
        expect((((replay['data'] as Map)['receipt'] as Map)['receiptId']),
            ordinaryReceipt['receiptId']);
      } finally {
        await transfer.closeTransferWorkspace(fixture.opened.workspaceHandle);
        await fixture.dispose();
      }
    },
  );

  test(
    'JSONL routes pack jobs and temporary queries before native snapshots',
    () async {
      final fixture = await NativeResourcePackImportFixture.create();
      final transfer = LocalResourcePackTransferApi(
        mutations: fixture.mutations,
        snapshotLoader: fixture.loader,
      );
      final worker = JsonlWorker(
        api: fixture.readApi,
        mutations: fixture.mutations,
        resourcePacks: transfer,
      );
      try {
        final response = jsonDecode(
          await worker.processLine(
            jsonEncode({
              'id': 'strict',
              'command': 'resource_pack',
              'args': {
                'projectHandle': fixture.opened.projectHandle.value,
                'verb': 'stage',
                'input': {
                  'sourcePath': '/never/read',
                  'inlineArchive': 'denied',
                },
              },
            }),
          ),
        ) as Map;
        expect(response['status'], 'failure');
        final poll = jsonDecode(
          await worker.processLine(
            jsonEncode({
              'id': 'status',
              'command': 'resource_pack',
              'args': {
                'projectHandle': fixture.opened.projectHandle.value,
                'verb': 'recovery_status',
                'input': {},
              },
            }),
          ),
        ) as Map;
        expect(poll['status'], 'success', reason: poll.toString());
      } finally {
        await transfer.closeTransferWorkspace(fixture.opened.workspaceHandle);
        await fixture.dispose();
      }
    },
  );

  test(
      'real bin stdin stdout paginates, applies history, reconstructs and replays',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    final root = fixture.source.directory.path;
    final archivePath = '$root/source.aveluneassets';
    final sink = File(archivePath).openWrite();
    await fixture.source.archive
        .withSource((source) => sink.addStream(sourceChunks(source)));
    await sink.close();
    var client = await ResourcePackStdioClient.start(root);
    try {
      var opened =
          await client.call('open', {'projectRoot': fixture.root.path});
      final planned =
          await client.planImport(opened, archivePath, 'stdio-import');
      final inspected = planned['inspection'] as Map;
      expect((inspected['pack'] as Map)['name'], isA<String>());
      expect(inspected['archiveBytes'], greaterThan(0));
      for (final section in ['families', 'authors', 'sources']) {
        final part = await client.pack(opened, 'entries', {'inspectionHandle': inspected['inspectionHandle'], 'section': section, 'limit': 1});
        expect((part['items'] as List).length, 1);
        if (part['nextCursor'] != null) await client.pack(opened, 'entries', {'inspectionHandle': inspected['inspectionHandle'], 'section': section == 'authors' ? 'families' : 'authors', 'cursor': part['nextCursor']}, 'resource_pack.cursor_invalid');
      }
      final summary = (planned['prepared'] as Map)['summary'] as Map;
      expect(summary['createdDefinitionCount'], summary['definitionCount']);
      expect(summary['sourceBytes'], greaterThan(0));

      final selection = planned['selection'] as Map;
      final first = await client.pack(opened, 'entries',
          {'inspectionHandle': inspected['inspectionHandle'], 'limit': 1});
      final entries = <String>{};
      var page = first;
      var pages = 0;
      while (true) {
        pages++;
        expect(page['returned'], 1);
        for (final row in page['items'] as List) {
          expect(entries.add('${(row as Map)['kind']}:${row['id']}'), isTrue);
        }
        if (page['nextCursor'] == null) break;
        page = await client.pack(opened, 'entries', {
          'inspectionHandle': inspected['inspectionHandle'],
          'limit': 1,
          'cursor': page['nextCursor']
        });
      }
      expect(pages, greaterThan(1));
      expect(entries.length, first['totalAvailable']);
      await client.pack(
          opened,
          'entries',
          {
            'inspectionHandle': inspected['inspectionHandle'],
            'limit': 1,
            'cursor': first['nextCursor'],
            'filter': {'kind': 'model3d'}
          },
          'resource_pack.cursor_invalid');
      final hidden = await client.pack(opened, 'entries', {
        'selectionHandle': selection['selectionHandle'],
        'filter': {'kind': 'model3d'}
      });
      expect(
          (hidden['items'] as List)
              .every((row) => (row as Map)['selected'] == false),
          isTrue);
      final visible = await client.pack(opened, 'entries', {
        'selectionHandle': selection['selectionHandle'],
        'filter': {'selected': true},
        'limit': 1
      });
      expect(visible['totalAvailable'], selection['selectedCount']);
      await client.call(
          'apply',
          {
            'projectHandle': opened['projectHandle'],
            'planId': planned['planId'],
            'operationId': 'stdio-operation'
          },
          error: 'resource_pack.job_required');
      final start = await client.pack(opened, 'start_apply',
          {'planId': planned['planId'], 'operationId': 'stdio-operation'});
      final applied = await client.result(opened, start);
      final receipt = applied['receipt'] as Map;
      for (final owner in [
        ('resourcePackInspection', inspected['inspectionHandle']),
        ('resourcePackSelection', selection['selectionHandle']),
        ('resourcePackEntry', selection['selectionHandle']),
        ('resourcePackPreview', (planned['prepared'] as Map)['previewHandle']),
        ('resourcePackJob', start['jobId']),
      ]) {
        await client.call('query', {'projectHandle': opened['projectHandle'], 'request':
          AuthoringQueryRequest(resourceKind: owner.$1, operation: AuthoringQueryOperation.list).toJson()},
          error: 'resource_pack.query_invalid');
        final owned = await client.call('query', {'projectHandle': opened['projectHandle'], 'request':
          AuthoringQueryRequest(resourceKind: owner.$1, operation: AuthoringQueryOperation.get,
              ids: [owner.$2 as String]).toJson()});
        expect((owned['items'] as List).isNotEmpty, true);
      }

      await client.pack(opened, 'cancel', {'jobId': start['jobId']},
          'resource_pack.cancel_not_allowed');
      final undone = await client.history(
          opened, 'undo', receipt['receiptId']!, 'stdio-undo');
      final redone = await client.history(
          opened, 'redo', receipt['receiptId']!, 'stdio-redo');
      final reverted = await client.history(opened, 'revert',
          (undone['receipt'] as Map)['receiptId']!, 'stdio-revert',
          expectedHeadEntryId: (redone['receipt'] as Map)['receiptId']);
      expect((reverted['receipt'] as Map)['actionId'], 'history.revert');
      await client.call(
          'undo',
          {
            'projectHandle': opened['projectHandle'],
            'entryId': receipt['receiptId'],
            'idempotencyKey': 'legacy'
          },
          error: 'resource_pack.job_required');
      await client.call(
          'recover',
          {
            'projectHandle': opened['projectHandle'],
            'operationId': 'stdio-operation'
          },
          error: 'resource_pack.job_required');
      final recovered = await client.result(
          opened,
          await client.pack(
              opened, 'start_recovery', {'operationId': 'stdio-operation'}));
      expect((recovered['receipt'] as Map)['receiptId'], receipt['receiptId']);
      final oldHandle = opened['projectHandle'];
      await client.close();
      client = await ResourcePackStdioClient.start(root);
      opened = await client.call('open', {'projectRoot': fixture.root.path});
      expect(opened['projectHandle'], isNot(oldHandle));
      await client.pack(opened, 'get', {'jobId': start['jobId']},
          'resource_pack.job_unknown');
      await client.pack(
          opened,
          'entries',
          {'inspectionHandle': inspected['inspectionHandle']},
          'resource_pack.handle_unknown');
      final replay = await client.result(
          opened,
          await client.pack(opened, 'start_apply',
              {'planId': planned['planId'], 'operationId': 'stdio-operation'}));
      expect((replay['receipt'] as Map)['receiptId'], receipt['receiptId']);
      final historyReplay = await client.result(
          opened,
          await client.pack(opened, 'start_history', {
            'operation': 'undo',
            'entryId': receipt['receiptId'],
            'operationId': 'stdio-undo',
            'expectedRevision': 'sha256:${'0' * 64}'
          }));
      expect((historyReplay['receipt'] as Map)['receiptId'],
          (undone['receipt'] as Map)['receiptId']);
    } finally {
      await client.close();
      await fixture.dispose();
    }
  }, timeout: Timeout(Duration(seconds: 90)));
}
