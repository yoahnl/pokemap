import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  test(
    'collects L3 from production runtime services in the Golden journey',
    () async {
      final repositoryRoot = p.normalize(
        p.join(Directory.current.path, '../..'),
      );
      final sourceRevision = await _sourceRevision(repositoryRoot);
      final receipt = await const ItemSystemRuntimeEvidenceCollector().collect(
        projectRootDirectory: Directory(
          p.join(
            repositoryRoot,
            'examples/playable_runtime_host/golden_item_system',
          ),
        ),
        sourceRevision: sourceRevision,
        recordedAtUtc: DateTime.utc(2026, 8, 12),
      );

      expect(receipt.level, ItemSystemProofLevel.runtimeL3);
      expect(receipt.verdict, ItemSystemExecutionVerdict.passed);
      expect(
        receipt.succeededCapabilities,
        ItemSystemV1CertificationProfile.requiredCapabilitiesFor(
          ItemSystemProofLevel.runtimeL3,
        ),
      );
      expect(receipt.failedCapabilities, isEmpty);
      expect(
        receipt.payload['observations'],
        containsAll(<String>[
          'status_cured_overworld',
          'pp_restored_overworld',
          'battle_item_applied',
          'capture_succeeded',
          'key_item_gate_preserved',
          'tm_learned',
          'held_item_equipped',
          'passive_item_preserved',
        ]),
      );
    },
  );
}

Future<String> _sourceRevision(String repositoryRoot) async {
  final result = await Process.run('git', const <String>[
    'rev-parse',
    'HEAD',
  ], workingDirectory: repositoryRoot);
  if (result.exitCode != 0) throw StateError(result.stderr.toString());
  return result.stdout.toString().trim();
}
