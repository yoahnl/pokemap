import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  test(
    'collects L2 from the production Golden journey persistence flow',
    () async {
      final repositoryRoot = p.normalize(
        p.join(Directory.current.path, '../..'),
      );
      final sourceRevision = await _sourceRevision(repositoryRoot);
      final receipt = await const ItemSystemPersistenceEvidenceCollector()
          .collect(
            projectRootDirectory: Directory(
              p.join(
                repositoryRoot,
                'examples/playable_runtime_host/golden_item_system',
              ),
            ),
            sourceRevision: sourceRevision,
            recordedAtUtc: DateTime.utc(2026, 8, 12),
          );

      expect(receipt.level, ItemSystemProofLevel.persistenceL2);
      expect(receipt.verdict, ItemSystemExecutionVerdict.passed);
      expect(
        receipt.succeededCapabilities,
        ItemSystemV1CertificationProfile.requiredCapabilitiesFor(
          ItemSystemProofLevel.persistenceL2,
        ),
      );
      expect(receipt.failedCapabilities, isEmpty);
      expect(
        receipt.payload['journeyReceiptSha256'],
        matches(RegExp(r'^[0-9a-f]{64}$')),
      );
      expect(
        receipt.payload['finalStateSha256'],
        matches(RegExp(r'^[0-9a-f]{64}$')),
      );
      expect(
        receipt.payload['observations'],
        containsAll(<String>[
          'new_game_from_project',
          'pickup_scenario_applied',
          'shop_purchase_applied',
          'trainer_reward_applied',
          'strict_save_wire_written',
          'runtime_save_reloaded',
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
