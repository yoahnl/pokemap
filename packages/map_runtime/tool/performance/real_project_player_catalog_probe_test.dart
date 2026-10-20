import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'real_project_player_catalog_probe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final source = Platform.environment['POKEMAP_REAL_PROJECT'] ?? '';
  final output = Platform.environment['POKEMAP_CATALOG_PROBE_OUTPUT'] ?? '';
  final maps = Platform.environment['POKEMAP_CATALOG_PROBE_MAPS'];
  test(
    'measures the real Player catalog and bundle route without source writes',
    () async {
      expect(
        output,
        isNotEmpty,
        reason: 'Set POKEMAP_CATALOG_PROBE_OUTPUT outside the source project.',
      );
      final receipt = await runRealProjectPlayerCatalogProbe(
        projectDirectory: source,
        outputPath: output,
        mapIds: maps?.split(','),
      );
      stdout.writeln(
        'PLAYER_CATALOG_PROBE=$output status=${receipt['status']}',
      );
      expect(receipt['status'], 'completed', reason: '${receipt['error']}');
    },
    skip: source.isEmpty ? 'Set POKEMAP_REAL_PROJECT to opt in.' : false,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
