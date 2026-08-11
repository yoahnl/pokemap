import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  test(
    'collects L1 through real authoring reads mutations and guards',
    () async {
      final repositoryRoot = p.normalize(
        p.join(Directory.current.path, '../..'),
      );
      final projectRoot = Directory(
        p.join(
          repositoryRoot,
          'examples/playable_runtime_host/golden_item_system',
        ),
      );
      final catalog = File(
        p.join(projectRoot.path, 'data/pokemon/catalogs/items.json'),
      );
      final sourceRevision = await _sourceRevision(repositoryRoot);
      final catalogBefore = await catalog.readAsBytes();

      final receipt = await const ItemSystemAuthoringEvidenceCollector()
          .collect(
            projectRootDirectory: projectRoot,
            sourceRevision: sourceRevision,
            recordedAtUtc: DateTime.utc(2026, 8, 12),
          );

      expect(receipt.level, ItemSystemProofLevel.authoringL1);
      expect(receipt.verdict, ItemSystemExecutionVerdict.passed);
      expect(
        receipt.succeededCapabilities,
        ItemSystemV1CertificationProfile.requiredCapabilitiesFor(
          ItemSystemProofLevel.authoringL1,
        ),
      );
      expect(receipt.failedCapabilities, isEmpty);
      expect(receipt.payload['queriedResourceKinds'], <String>[
        'itemCatalog',
        'itemDefinition',
        'itemReadiness',
        'itemUsage',
      ]);
      expect(
        (receipt.payload['actionReceipts']! as List<Object?>),
        hasLength(9),
      );
      expect(
        (receipt.payload['actionReceipts']! as List<Object?>).toSet(),
        hasLength(9),
      );
      expect(
        receipt.payload['referenceGuardCode'],
        'item.delete_references_blocking',
      );
      expect(await catalog.readAsBytes(), catalogBefore);
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
