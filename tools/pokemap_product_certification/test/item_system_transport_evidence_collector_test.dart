import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  test(
    'collects all 36 action transport pairs from real executions',
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
      final mcpRoot = Directory(p.join(repositoryRoot, 'tools/pokemap_mcp'));
      final sourceRevision = await _sourceRevision(repositoryRoot);
      final catalogFile = File(
        p.join(projectRoot.path, 'data/pokemon/catalogs/items.json'),
      );
      final catalogBefore = await catalogFile.readAsBytes();
      final build = await Process.run('npm', const <String>[
        'run',
        'build',
      ], workingDirectory: mcpRoot.path);
      expect(build.exitCode, 0, reason: build.stderr.toString());

      const collector = ItemSystemTransportEvidenceCollector();
      final receipt = await collector.collect(
        projectRootDirectory: projectRoot,
        mcpPackageRootDirectory: mcpRoot,
        sourceRevision: sourceRevision,
        recordedAtUtc: DateTime.utc(2026, 8, 12),
      );

      expect(receipt.level, ItemSystemProofLevel.mcpParityL5);
      expect(receipt.verdict, ItemSystemExecutionVerdict.passed);
      expect(
        receipt.succeededCapabilities,
        ItemSystemV1CertificationProfile.requiredCapabilitiesFor(
          ItemSystemProofLevel.mcpParityL5,
        ),
      );
      expect(receipt.failedCapabilities, isEmpty);
      final pairs = (receipt.payload['transportPairs']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(pairs, hasLength(36));
      expect(
        pairs.map((pair) => '${pair['actionId']}@${pair['transport']}').toSet(),
        hasLength(36),
      );
      expect(pairs.where((pair) => pair['transport'] == 'mcp'), hasLength(9));
      expect(
        pairs,
        everyElement(
          isA<Map<String, Object?>>()
              .having(
                (pair) => pair['receiptSha256'],
                'receiptSha256',
                matches(RegExp(r'^[0-9a-f]{64}$')),
              )
              .having(
                (pair) => pair['semanticStateSha256'],
                'semanticStateSha256',
                matches(RegExp(r'^[0-9a-f]{64}$')),
              ),
        ),
      );
      final executorDigests = Map<String, Object?>.from(
        receipt.payload['transportExecutorSha256']! as Map,
      );
      expect(executorDigests.keys, <String>{
        'direct_api',
        'jsonl',
        'editor',
        'mcp',
      });
      expect(
        executorDigests.values,
        everyElement(matches(RegExp(r'^[0-9a-f]{64}$'))),
      );
      final bundle = collector.buildParityReceiptBundle(receipt);
      expect(bundle['sourceRevision'], sourceRevision);
      expect(
        bundle['receipts'],
        isA<List<Object?>>().having((items) => items.length, 'length', 36),
      );
      expect(await catalogFile.readAsBytes(), catalogBefore);
    },
    timeout: const Timeout(Duration(minutes: 3)),
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
