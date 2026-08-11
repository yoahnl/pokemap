import 'dart:io';

import 'item_system_certification.dart';
import 'item_system_execution_receipt.dart';
import 'item_system_golden_journey_evidence.dart';

final class ItemSystemRuntimeEvidenceCollector {
  const ItemSystemRuntimeEvidenceCollector();

  Future<ItemSystemExecutionReceipt> collect({
    required Directory projectRootDirectory,
    required String sourceRevision,
    required DateTime recordedAtUtc,
    int rngSeed = 47,
  }) {
    return collectGoldenJourneyEvidence(
      level: ItemSystemProofLevel.runtimeL3,
      requiredObservationsByCapability: const <String, Set<String>>{
        'overworld_medicine': <String>{
          'status_cured_overworld',
          'pp_restored_overworld',
          'hp_healed_overworld',
          'revived_overworld',
        },
        'battle_medicine': <String>{
          'battle_damage_applied',
          'battle_item_applied',
        },
        'capture': <String>{'capture_succeeded'},
        'key_item_gate': <String>{'key_item_gate_preserved'},
        'move_machine': <String>{'tm_learned'},
        'held_item': <String>{'held_item_equipped'},
        'passive_item': <String>{'passive_item_preserved'},
      },
      producer: 'item-system-runtime-evidence-collector',
      projectRootDirectory: projectRootDirectory,
      sourceRevision: sourceRevision,
      recordedAtUtc: recordedAtUtc,
      rngSeed: rngSeed,
    );
  }
}
