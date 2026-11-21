import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'installed spatial game survives independent process restarts',
    () async {
      final root = await Directory.systemTemp.createTemp('spatial-durable-');
      addTearDown(() => root.delete(recursive: true));
      final receipts = <Map<String, dynamic>>[];
      for (final phase in ['write', 'read']) {
        final process = await Process.start(
          'flutter',
          [
            'test',
            '--no-pub',
            '--reporter',
            'expanded',
            'test/fixtures/spatial_durable_restart_worker.dart',
          ],
          environment: {
            ...Platform.environment,
            'AVELUNE_SPATIAL_RESTART_ROOT': root.path,
            'AVELUNE_SPATIAL_RESTART_PHASE': phase,
          },
        );
        final stdout = process.stdout.transform(utf8.decoder).join();
        final stderr = process.stderr.transform(utf8.decoder).join();
        int code;
        try {
          code = await process.exitCode.timeout(const Duration(minutes: 3));
        } on TimeoutException {
          process.kill();
          rethrow;
        }
        final output = '${await stdout}\n${await stderr}';
        expect(code, 0, reason: '$phase process ${process.pid}:\n$output');
        final receipt =
            jsonDecode(
                  await File(p.join(root.path, '$phase.json')).readAsString(),
                )
                as Map<String, dynamic>;
        expect(receipt['phase'], phase);
        expect(receipt['sourceRemoved'], isTrue);
        expect(receipt['installedAssetsOnly'], isTrue);
        receipts.add(receipt);
      }
      expect(receipts[0]['pid'], isNot(receipts[1]['pid']));
      expect(receipts[1]['saveChecksum'], receipts[0]['saveChecksum']);
      expect(receipts[1]['position'], receipts[0]['position']);
      expect(receipts[1]['doorOpen'], isTrue);
      expect(receipts[1]['npcMoved'], isTrue);
      expect(receipts[1]['progressRestored'], isTrue);
      expect(receipts[1]['invalidLoadsPreservedBytes'], 4);
      expect(receipts[1]['corruptSaveRecoveredBackup'], isTrue);
    },
    timeout: const Timeout(Duration(minutes: 7)),
  );
}
