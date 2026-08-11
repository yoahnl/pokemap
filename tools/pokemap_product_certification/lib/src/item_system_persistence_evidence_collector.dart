import 'dart:io';

import 'item_system_certification.dart';
import 'item_system_execution_receipt.dart';
import 'item_system_golden_journey_evidence.dart';

final class ItemSystemPersistenceEvidenceCollector {
  const ItemSystemPersistenceEvidenceCollector();

  Future<ItemSystemExecutionReceipt> collect({
    required Directory projectRootDirectory,
    required String sourceRevision,
    required DateTime recordedAtUtc,
    int rngSeed = 47,
  }) {
    return collectGoldenJourneyEvidence(
      level: ItemSystemProofLevel.persistenceL2,
      requiredObservationsByCapability: const <String, Set<String>>{
        'new_game_items': <String>{
          'new_game_from_project',
          'initial_bag_strict',
        },
        'pickup_items': <String>{
          'pickup_scenario_applied',
          'pickup_scenario_idempotent',
        },
        'shop_items': <String>{'shop_purchase_applied', 'shop_sale_applied'},
        'reward_items': <String>{'trainer_reward_applied'},
        'save_reload': <String>{
          'strict_save_wire_written',
          'runtime_save_reloaded',
        },
      },
      producer: 'item-system-persistence-evidence-collector',
      projectRootDirectory: projectRootDirectory,
      sourceRevision: sourceRevision,
      recordedAtUtc: recordedAtUtc,
      rngSeed: rngSeed,
    );
  }
}
