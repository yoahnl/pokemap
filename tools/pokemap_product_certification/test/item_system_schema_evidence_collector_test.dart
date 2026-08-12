import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  test('collects L0 only from strict schema executions', () async {
    final repositoryRoot = p.normalize(p.join(Directory.current.path, '../..'));
    final sourceRevision = await _sourceRevision(repositoryRoot);
    final receipt = await const ItemSystemSchemaEvidenceCollector().collect(
      projectRootDirectory: Directory(
        p.join(
          repositoryRoot,
          'examples/playable_runtime_host/golden_item_system',
        ),
      ),
      sourceRevision: sourceRevision,
      recordedAtUtc: DateTime.utc(2026, 8, 12),
    );

    expect(receipt.level, ItemSystemProofLevel.schemaL0);
    expect(receipt.verdict, ItemSystemExecutionVerdict.passed);
    expect(
      receipt.succeededCapabilities,
      ItemSystemV1CertificationProfile.requiredCapabilitiesFor(
        ItemSystemProofLevel.schemaL0,
      ),
    );
    expect(receipt.failedCapabilities, isEmpty);
    expect(receipt.fixtureSha256, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(receipt.payload['catalogEntryCount'], 11);
    expect(receipt.payload['catalogEntryIds'], <String>[
      'antidote',
      'ether',
      'hidden-tonic',
      'hm-surf',
      'lab-key',
      'leftovers',
      'lucky-charm',
      'poke-ball',
      'potion',
      'revive',
      'tm-protect',
    ]);
    expect(receipt.payload['legacyCatalogRejected'], true);
    expect(receipt.payload['legacySaveRejected'], true);
    expect(receipt.payload['missingSaveSchemaRejected'], true);
    expect(receipt.payload['capabilityMatrixRejections'], <Object?>[
      <String, Object?>{
        'blockingCodes': <String>['unsupportedCapability'],
        'itemId': 'battle-ether',
        'readiness': 'unsupported',
      },
      <String, Object?>{
        'blockingCodes': <String>['unknownHeldEffect'],
        'itemId': 'unknown-held-effect',
        'readiness': 'unsupported',
      },
      <String, Object?>{
        'blockingCodes': <String>['unsupportedCapability'],
        'itemId': 'overworld-repel',
        'readiness': 'unsupported',
      },
    ]);
    expect(
      ItemSystemExecutionReceipt.fromJson(
        receipt.toJson(),
        expectedSourceRevision: sourceRevision,
        expectedFixtureSha256: receipt.fixtureSha256,
      ).payloadSha256,
      receipt.payloadSha256,
    );
  });
}

Future<String> _sourceRevision(String repositoryRoot) async {
  final result = await Process.run('git', const <String>[
    'rev-parse',
    'HEAD',
  ], workingDirectory: repositoryRoot);
  if (result.exitCode != 0) throw StateError(result.stderr.toString());
  return result.stdout.toString().trim();
}
