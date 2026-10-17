import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../domains/assets/resource_pack_import_fixture.dart';
import '../support/resource_pack_stdio_client.dart';
import '../support/resource_pack_test_gate.dart';

void main() {
  for (final reserved in [false, true]) {
    test(
        'controlled real JSONL cancellation ${reserved ? 'after' : 'before'} canonical reservation',
        () async {
      final fixture = await NativeResourcePackImportFixture.create();
      final root = fixture.source.directory.path;
      final source = await _archive(fixture);
      final gate = ResourcePackTestGate(root);
      final client =
          await ResourcePackStdioClient.start(root, controlled: true);
      try {
        final opened =
            await client.call('open', {'projectRoot': fixture.root.path});
        final plan =
            await client.planImport(opened, source, 'controlled-import');
        final before =
            await File('${fixture.root.path}/project.json').readAsBytes();
        await gate.arm(
            'reservation',
            'controlled-operation',
            reserved
                ? AuthoringTransactionCheckpoint.afterReservation
                : AuthoringTransactionCheckpoint.afterJournalStaged);
        final started = await client.pack(opened, 'start_apply',
            {'planId': plan['planId'], 'operationId': 'controlled-operation'});
        await gate.entered('reservation');
        final status =
            await client.pack(opened, 'get', {'jobId': started['jobId']});
        expect((status['snapshot'] as Map)['state'], 'running');
        expect(status['cancelAllowed'], !reserved);
        final events = await client.pack(
            opened, 'events', {'jobId': started['jobId'], 'afterSequence': 0});
        expect((events['events'] as List).length, greaterThan(1));
        if (reserved) {
          final refused = await client.pack(opened, 'cancel',
              {'jobId': started['jobId']}, 'resource_pack.cancel_not_allowed');
          expect((refused['details'] as Map)['cancelAllowed'], false);
          expect((refused['details'] as Map)['phase'], 'finalizing');
        } else {
          final accepted =
              await client.pack(opened, 'cancel', {'jobId': started['jobId']});
          expect(accepted['state'], 'cancelling');
          expect(accepted['bounded'], false);
        }
        await gate.release('reservation');
        final settled = await client.poll(opened, started);
        expect((settled['snapshot'] as Map)['state'],
            reserved ? 'succeeded' : 'cancelled',
            reason: settled.toString());
        if (reserved) {
          expect(((settled['result'] as Map)['receipt'] as Map)['status'],
              'applied');
        } else {
          expect(await File('${fixture.root.path}/project.json').readAsBytes(),
              before);
          expect(settled['result'], isNull);
        }
        expect(
            (await client.pack(opened, 'recovery_status'))['recoveryRequired'],
            false);
      } finally {
        await gate.release('reservation');
        await client.close();
        await fixture.dispose();
      }
    }, timeout: Timeout(Duration(seconds: 90)));
  }

  test(
      'controlled real JSONL late promotion failure reconstructs readonly recovery and durable replay',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    final root = fixture.source.directory.path;
    final source = await _archive(fixture);
    final gate = ResourcePackTestGate(root);
    var client = await ResourcePackStdioClient.start(root, controlled: true);
    try {
      var opened =
          await client.call('open', {'projectRoot': fixture.root.path});
      final plan = await client.planImport(opened, source, 'fault-import');
      await gate.arm('fault', 'fault-operation',
          AuthoringTransactionCheckpoint.afterResourcePromoted,
          crash: true);
      final start = await client.pack(opened, 'start_apply',
          {'planId': plan['planId'], 'operationId': 'fault-operation'});
      await gate.entered('fault');
      expect(
          (await client
              .pack(opened, 'get', {'jobId': start['jobId']}))['cancelAllowed'],
          false);
      await gate.release('fault');
      final failed = await client.poll(opened, start);
      expect((failed['snapshot'] as Map)['state'], 'failed');
      expect(failed['phase'], 'recoveryRequired');
      await client.close();
      await File('${gate.directory.path}/readonly').writeAsString('readonly');
      client = await ResourcePackStdioClient.start(root, controlled: true);
      opened = await client.call('open', {'projectRoot': fixture.root.path});
      expect(opened['readOnly'], true);
      expect((await client.pack(opened, 'recovery_status'))['recoveryRequired'],
          true);
      final denied = await client.poll(
          opened,
          await client.pack(
              opened, 'start_recovery', {'operationId': 'fault-operation'}));
      expect((denied['snapshot'] as Map)['errorCode'],
          'authorization.permission_denied');
      await client.close();
      await File('${gate.directory.path}/readonly').delete();
      client = await ResourcePackStdioClient.start(root, controlled: true);
      opened = await client.call('open', {'projectRoot': fixture.root.path});
      await client.call(
          'recover',
          {
            'projectHandle': opened['projectHandle'],
            'operationId': 'fault-operation'
          },
          error: 'resource_pack.job_required');
      final recovered = await client.result(
          opened,
          await client.pack(
              opened, 'start_recovery', {'operationId': 'fault-operation'}));
      expect((await client.pack(opened, 'recovery_status'))['recoveryRequired'],
          false);
      await gate.arm('no-promotion', 'fault-operation',
          AuthoringTransactionCheckpoint.afterResourcePromoted,
          crash: true);
      final replay = await client.result(
          opened,
          await client.pack(opened, 'start_apply',
              {'planId': plan['planId'], 'operationId': 'fault-operation'}));
      expect((replay['receipt'] as Map)['receiptId'],
          (recovered['receipt'] as Map)['receiptId']);
      expect(await File('${gate.directory.path}/entered-no-promotion').exists(),
          false);
    } finally {
      await gate.release('fault');
      await gate.release('no-promotion');
      await client.close();
      await fixture.dispose();
    }
  }, timeout: Timeout(Duration(seconds: 90)));
}

Future<String> _archive(NativeResourcePackImportFixture fixture) async {
  final path = '${fixture.source.directory.path}/source.aveluneassets';
  final sink = File(path).openWrite();
  await fixture.source.archive
      .withSource((source) => sink.addStream(sourceChunks(source)));
  await sink.close();
  return path;
}
