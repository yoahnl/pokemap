import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  test(
    'certifies nine Item actions through all four transports including Studio',
    () async {
      final repositoryRoot = p.normalize(
        p.join(Directory.current.path, '../..'),
      );
      final projectRoot = Directory(
        p.join(
          repositoryRoot,
          'tools/pokemap_render_host/golden_item_system',
        ),
      );
      const mcpRootOverride = String.fromEnvironment('POKEMAP_MCP_ROOT');
      final mcpRoot = Directory(
        mcpRootOverride.isEmpty
            ? p.join(repositoryRoot, 'tools/pokemap_mcp')
            : mcpRootOverride,
      );
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
      expect(
        receipt.verdict,
        ItemSystemExecutionVerdict.passed,
        reason: jsonEncode(receipt.payload),
      );
      expect(
        receipt.succeededCapabilities,
        ItemSystemV1CertificationProfile.requiredItemActionIds,
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
        pairs.where((pair) => pair['transport'] == 'editor'),
        hasLength(9),
      );
      for (final actionId
          in ItemSystemV1CertificationProfile.requiredItemActionIds) {
        final actionPairs = pairs.where((pair) => pair['actionId'] == actionId);
        expect(actionPairs, hasLength(4), reason: actionId);
        expect(
          actionPairs.map((pair) => pair['semanticStateSha256']).toSet(),
          hasLength(1),
          reason: actionId,
        );
      }
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
      expect(bundle['receipts'], hasLength(36));
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
