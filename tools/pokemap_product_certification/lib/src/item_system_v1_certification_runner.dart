import 'dart:io';

import 'item_system_authoring_evidence_collector.dart';
import 'item_system_certification.dart';
import 'item_system_execution_receipt.dart';
import 'item_system_fixture_digest.dart';
import 'item_system_golden_journey_evidence.dart';
import 'item_system_persistence_evidence_collector.dart';
import 'item_system_player_evidence_collector.dart';
import 'item_system_runtime_evidence_collector.dart';
import 'item_system_schema_evidence_collector.dart';
import 'item_system_transport_evidence_collector.dart';

final class ItemSystemV1CertificationRunner {
  const ItemSystemV1CertificationRunner();

  Future<ItemSystemCertificationResult> run({
    required Directory repositoryRootDirectory,
    required Directory projectRootDirectory,
    required Directory mcpPackageRootDirectory,
    required String sourceRevision,
    required DateTime recordedAtUtc,
    int rngSeed = 47,
  }) async {
    final fixtureSha256 = await computeItemSystemFixtureSha256(
      projectRootDirectory,
    );
    final receipts = <ItemSystemProofLevel, ItemSystemExecutionReceipt>{};
    receipts[ItemSystemProofLevel.schemaL0] =
        await const ItemSystemSchemaEvidenceCollector().collect(
          projectRootDirectory: projectRootDirectory,
          sourceRevision: sourceRevision,
          recordedAtUtc: recordedAtUtc,
        );
    receipts[ItemSystemProofLevel.authoringL1] =
        await const ItemSystemAuthoringEvidenceCollector().collect(
          projectRootDirectory: projectRootDirectory,
          sourceRevision: sourceRevision,
          recordedAtUtc: recordedAtUtc,
        );
    receipts[ItemSystemProofLevel.persistenceL2] =
        await const ItemSystemPersistenceEvidenceCollector().collect(
          projectRootDirectory: projectRootDirectory,
          sourceRevision: sourceRevision,
          recordedAtUtc: recordedAtUtc,
          rngSeed: rngSeed,
        );
    receipts[ItemSystemProofLevel.runtimeL3] =
        await const ItemSystemRuntimeEvidenceCollector().collect(
          projectRootDirectory: projectRootDirectory,
          sourceRevision: sourceRevision,
          recordedAtUtc: recordedAtUtc,
          rngSeed: rngSeed,
        );
    receipts[ItemSystemProofLevel.playerUxL4] =
        await const ItemSystemPlayerEvidenceCollector().collect(
          repositoryRootDirectory: repositoryRootDirectory,
          projectRootDirectory: projectRootDirectory,
          sourceRevision: sourceRevision,
          recordedAtUtc: recordedAtUtc,
        );
    receipts[ItemSystemProofLevel.mcpParityL5] =
        await const ItemSystemTransportEvidenceCollector().collect(
          projectRootDirectory: projectRootDirectory,
          mcpPackageRootDirectory: mcpPackageRootDirectory,
          sourceRevision: sourceRevision,
          recordedAtUtc: recordedAtUtc,
        );
    receipts[ItemSystemProofLevel.goldenFlowL6] =
        await collectGoldenJourneyEvidence(
          level: ItemSystemProofLevel.goldenFlowL6,
          requiredObservationsByCapability: <String, Set<String>>{
            for (final observation
                in ItemSystemV1CertificationProfile.requiredGoldenObservations)
              observation: <String>{observation},
          },
          producer: 'item-system-golden-flow-evidence-collector',
          projectRootDirectory: projectRootDirectory,
          sourceRevision: sourceRevision,
          recordedAtUtc: recordedAtUtc,
          rngSeed: rngSeed,
        );
    return const ItemSystemCertificationEvaluator().evaluate(
      ItemSystemCertificationRequest(
        sourceRevision: sourceRevision,
        fixtureSha256: fixtureSha256,
        executionReceipts: receipts,
      ),
    );
  }
}
