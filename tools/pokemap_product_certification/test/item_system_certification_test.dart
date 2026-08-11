import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/golden_item_system_journey.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  test(
    'evaluates explicit V1 evidence without over-certifying parity',
    () async {
      final repositoryRoot = p.normalize(
        p.join(Directory.current.path, '../..'),
      );
      final sourceRevision = await _sourceRevision(repositoryRoot);
      final saveRoot = await Directory.systemTemp.createTemp(
        'item-system-certification-',
      );
      addTearDown(() => saveRoot.delete(recursive: true));
      final journey = await GoldenItemSystemJourney.run(
        projectRootDirectory: p.join(
          repositoryRoot,
          'examples/playable_runtime_host/golden_item_system',
        ),
        saveRootDirectory: saveRoot.path,
        sourceRevision: sourceRevision,
        rngSeed: 47,
      );
      final goldenReceipt = ItemSystemGoldenFlowReceipt.fromJson(
        journey.toJson(),
      );
      final evidence = <ItemSystemProofLevel, ItemSystemLevelEvidence>{
        for (final level in const <ItemSystemProofLevel>[
          ItemSystemProofLevel.schemaL0,
          ItemSystemProofLevel.authoringL1,
          ItemSystemProofLevel.persistenceL2,
          ItemSystemProofLevel.runtimeL3,
        ])
          level: _completeEvidence(level, sourceRevision),
        ItemSystemProofLevel.playerUxL4: ItemSystemLevelEvidence(
          sourceRevision: sourceRevision,
          evidenceSha256: _sha('4'),
          executedCapabilities:
              ItemSystemV1CertificationProfile.requiredCapabilitiesFor(
                    ItemSystemProofLevel.playerUxL4,
                  )
                  .where((capability) => capability != 'held_item_controls')
                  .toSet(),
        ),
      };
      final transports = ItemSystemTransportEvidence(
        sourceRevision: sourceRevision,
        evidenceSha256: _sha('5'),
        executedTransportsByAction: <String, Set<ItemSystemTransport>>{
          'item.create': ItemSystemTransport.values.toSet(),
          for (final actionId
              in ItemSystemV1CertificationProfile.requiredItemActionIds.where(
                (actionId) => actionId != 'item.create',
              ))
            actionId: const <ItemSystemTransport>{
              ItemSystemTransport.directApi,
            },
        },
      );

      final result = const ItemSystemCertificationEvaluator().evaluate(
        ItemSystemCertificationRequest(
          sourceRevision: sourceRevision,
          levelEvidence: evidence,
          transportEvidence: transports,
          goldenFlowReceipt: goldenReceipt,
        ),
      );

      expect(
        result.statusFor(ItemSystemProofLevel.schemaL0).wireName,
        'CERTIFIED',
      );
      expect(
        result.statusFor(ItemSystemProofLevel.authoringL1).wireName,
        'CERTIFIED',
      );
      expect(
        result.statusFor(ItemSystemProofLevel.persistenceL2).wireName,
        'CERTIFIED',
      );
      expect(
        result.statusFor(ItemSystemProofLevel.runtimeL3).wireName,
        'CERTIFIED',
      );
      expect(
        result.statusFor(ItemSystemProofLevel.playerUxL4).wireName,
        'PARTIAL',
      );
      expect(
        result.statusFor(ItemSystemProofLevel.mcpParityL5).wireName,
        'PARTIAL',
      );
      expect(
        result.statusFor(ItemSystemProofLevel.goldenFlowL6).wireName,
        'CERTIFIED',
      );
      expect(result.overallStatus, ItemSystemCertificationStatus.partial);
      expect(result.goldenFlowReceiptSha256, hasLength(64));
      expect(result.toJson()['sourceRevision'], sourceRevision);
    },
  );

  test('model-only and incomplete transport claims fail closed', () {
    const sourceRevision = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    final result = const ItemSystemCertificationEvaluator().evaluate(
      ItemSystemCertificationRequest(
        sourceRevision: sourceRevision,
        levelEvidence: <ItemSystemProofLevel, ItemSystemLevelEvidence>{
          ItemSystemProofLevel.schemaL0: ItemSystemLevelEvidence(
            sourceRevision: sourceRevision,
            evidenceSha256:
                '0000000000000000000000000000000000000000000000000000000000000000',
            executedCapabilities: <String>{},
          ),
        },
        transportEvidence: ItemSystemTransportEvidence(
          sourceRevision: sourceRevision,
          evidenceSha256:
              '1111111111111111111111111111111111111111111111111111111111111111',
          executedTransportsByAction: <String, Set<ItemSystemTransport>>{
            'item.create': <ItemSystemTransport>{
              ItemSystemTransport.directApi,
              ItemSystemTransport.jsonl,
              ItemSystemTransport.editor,
              ItemSystemTransport.mcp,
            },
          },
        ),
      ),
    );

    expect(
      result.statusFor(ItemSystemProofLevel.schemaL0),
      ItemSystemCertificationStatus.unverified,
    );
    expect(
      result.statusFor(ItemSystemProofLevel.mcpParityL5),
      ItemSystemCertificationStatus.partial,
    );
    expect(
      result.statusFor(ItemSystemProofLevel.goldenFlowL6),
      ItemSystemCertificationStatus.missing,
    );
  });

  test('regression, blocked, deferred and not-wired states stay explicit', () {
    const revision = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    final result = const ItemSystemCertificationEvaluator().evaluate(
      ItemSystemCertificationRequest(
        sourceRevision: revision,
        levelEvidence: <ItemSystemProofLevel, ItemSystemLevelEvidence>{
          ItemSystemProofLevel.schemaL0: ItemSystemLevelEvidence(
            sourceRevision: revision,
            evidenceSha256:
                '2222222222222222222222222222222222222222222222222222222222222222',
            executedCapabilities: <String>{'catalog_schema'},
            failedCapabilities: <String>{'save_schema'},
          ),
          ItemSystemProofLevel.authoringL1: ItemSystemLevelEvidence(
            sourceRevision: revision,
            evidenceSha256:
                '3333333333333333333333333333333333333333333333333333333333333333',
            wired: false,
            executedCapabilities: <String>{},
          ),
        },
        blockedLevels: <ItemSystemProofLevel>{
          ItemSystemProofLevel.persistenceL2,
        },
        deferredLevels: <ItemSystemProofLevel>{ItemSystemProofLevel.runtimeL3},
      ),
    );

    expect(
      result.statusFor(ItemSystemProofLevel.schemaL0).wireName,
      'REGRESSED',
    );
    expect(
      result.statusFor(ItemSystemProofLevel.authoringL1).wireName,
      'NOT_WIRED',
    );
    expect(
      result.statusFor(ItemSystemProofLevel.persistenceL2).wireName,
      'BLOCKED',
    );
    expect(
      result.statusFor(ItemSystemProofLevel.runtimeL3).wireName,
      'DEFERRED',
    );
    expect(result.overallStatus, ItemSystemCertificationStatus.regressed);
  });

  test('golden receipt rejects missing executed observations', () async {
    final repositoryRoot = p.normalize(p.join(Directory.current.path, '../..'));
    final sourceRevision = await _sourceRevision(repositoryRoot);
    final saveRoot = await Directory.systemTemp.createTemp(
      'item-system-invalid-receipt-',
    );
    addTearDown(() => saveRoot.delete(recursive: true));
    final journey = await GoldenItemSystemJourney.run(
      projectRootDirectory: p.join(
        repositoryRoot,
        'examples/playable_runtime_host/golden_item_system',
      ),
      saveRootDirectory: saveRoot.path,
      sourceRevision: sourceRevision,
      rngSeed: 47,
    );
    final json = journey.toJson();
    json['observations'] = <String>['new_game_from_project'];

    expect(
      () => ItemSystemGoldenFlowReceipt.fromJson(json),
      throwsFormatException,
    );
    final tampered = journey.toJson();
    tampered['finalMoney'] = 0;
    expect(
      () => ItemSystemGoldenFlowReceipt.fromJson(tampered),
      throwsFormatException,
    );
  });
}

ItemSystemLevelEvidence _completeEvidence(
  ItemSystemProofLevel level,
  String sourceRevision,
) {
  return ItemSystemLevelEvidence(
    sourceRevision: sourceRevision,
    evidenceSha256: _sha('${level.index}'),
    executedCapabilities:
        ItemSystemV1CertificationProfile.requiredCapabilitiesFor(level),
  );
}

String _sha(String value) => value.padLeft(64, '0');

Future<String> _sourceRevision(String repositoryRoot) async {
  final result = await Process.run('git', const <String>[
    'rev-parse',
    'HEAD',
  ], workingDirectory: repositoryRoot);
  if (result.exitCode != 0) throw StateError(result.stderr.toString());
  return result.stdout.toString().trim();
}
