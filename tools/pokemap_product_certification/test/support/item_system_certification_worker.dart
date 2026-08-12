import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  test(
    'writes executable Item System V1 certification artifacts',
    () async {
      const repositoryRoot = String.fromEnvironment('POKEMAP_REPOSITORY_ROOT');
      const projectRoot = String.fromEnvironment('POKEMAP_ITEM_PROJECT_ROOT');
      const mcpRoot = String.fromEnvironment('POKEMAP_MCP_ROOT');
      const outputPath = String.fromEnvironment(
        'POKEMAP_ITEM_CERTIFICATION_OUTPUT',
      );
      const receiptPath = String.fromEnvironment(
        'POKEMAP_ITEM_TRANSPORT_RECEIPTS_OUTPUT',
      );
      for (final entry in <String, String>{
        'POKEMAP_REPOSITORY_ROOT': repositoryRoot,
        'POKEMAP_ITEM_PROJECT_ROOT': projectRoot,
        'POKEMAP_MCP_ROOT': mcpRoot,
        'POKEMAP_ITEM_CERTIFICATION_OUTPUT': outputPath,
        'POKEMAP_ITEM_TRANSPORT_RECEIPTS_OUTPUT': receiptPath,
      }.entries) {
        if (entry.value.isEmpty) {
          throw StateError('Missing ${entry.key}.');
        }
      }
      final sourceRevision = await _sourceRevision(repositoryRoot);
      final result = await const ItemSystemV1CertificationRunner().run(
        repositoryRootDirectory: Directory(repositoryRoot),
        projectRootDirectory: Directory(projectRoot),
        mcpPackageRootDirectory: Directory(mcpRoot),
        sourceRevision: sourceRevision,
        recordedAtUtc: DateTime.now().toUtc(),
      );
      expect(result.technicalCertificationPassed, isTrue);
      final l5 = result.executionReceipts[ItemSystemProofLevel.mcpParityL5];
      if (l5 == null) throw StateError('The L5 receipt is missing.');
      final bundle = const ItemSystemTransportEvidenceCollector()
          .buildParityReceiptBundle(l5);
      await _writeJson(File(outputPath), result.toJson());
      await _writeJson(File(receiptPath), bundle);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<String> _sourceRevision(String repositoryRoot) async {
  final result = await Process.run('git', const <String>[
    'rev-parse',
    'HEAD',
  ], workingDirectory: repositoryRoot);
  if (result.exitCode != 0) {
    throw StateError('Unable to resolve Git revision: ${result.stderr}');
  }
  return result.stdout.toString().trim();
}

Future<void> _writeJson(File file, Map<String, Object?> json) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(json)}\n',
    flush: true,
  );
}
