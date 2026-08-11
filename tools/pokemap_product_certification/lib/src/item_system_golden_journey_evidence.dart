import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/golden_item_system_journey.dart';

import 'item_system_certification.dart';
import 'item_system_execution_receipt.dart';
import 'item_system_fixture_digest.dart';

Future<ItemSystemExecutionReceipt> collectGoldenJourneyEvidence({
  required ItemSystemProofLevel level,
  required Map<String, Set<String>> requiredObservationsByCapability,
  required String producer,
  required Directory projectRootDirectory,
  required String sourceRevision,
  required DateTime recordedAtUtc,
  int rngSeed = 47,
}) async {
  final required = ItemSystemV1CertificationProfile.requiredCapabilitiesFor(
    level,
  );
  if (requiredObservationsByCapability.keys.toSet().length != required.length ||
      !requiredObservationsByCapability.keys.toSet().containsAll(required)) {
    throw ArgumentError.value(
      requiredObservationsByCapability,
      'requiredObservationsByCapability',
      'must define every required capability exactly once',
    );
  }
  final fixtureSha256 = await computeItemSystemFixtureSha256(
    projectRootDirectory,
  );
  final succeeded = <String>{};
  final failed = <String>{};
  final payload = <String, Object?>{};
  final saveRoot = await Directory.systemTemp.createTemp(
    'pokemap-item-journey-evidence-',
  );

  try {
    final journey = await GoldenItemSystemJourney.run(
      projectRootDirectory: projectRootDirectory.path,
      saveRootDirectory: p.join(saveRoot.path, 'save'),
      sourceRevision: sourceRevision,
      rngSeed: rngSeed,
    );
    if (journey.fixtureSha256 != fixtureSha256) {
      throw StateError('Golden journey and collector fixture digests differ.');
    }
    final observations = journey.observations.toSet();
    for (final entry in requiredObservationsByCapability.entries) {
      if (observations.containsAll(entry.value)) {
        succeeded.add(entry.key);
      } else {
        failed.add(entry.key);
      }
    }
    final goldenReceipt = ItemSystemGoldenFlowReceipt.fromJson(
      journey.toJson(),
    );
    payload
      ..['journeyReceiptSha256'] = goldenReceipt.receiptSha256
      ..['finalStateSha256'] = journey.finalStateSha256
      ..['rngSeed'] = journey.rngSeed
      ..['steps'] = journey.steps
      ..['observations'] = journey.observations;
  } on Object catch (error) {
    failed.addAll(required.difference(succeeded));
    payload['error'] = error.toString();
  } finally {
    if (await saveRoot.exists()) await saveRoot.delete(recursive: true);
  }

  return ItemSystemExecutionReceipt.record(
    level: level,
    sourceRevision: sourceRevision,
    fixtureSha256: fixtureSha256,
    payload: payload,
    attemptedCapabilities: required,
    succeededCapabilities: succeeded,
    failedCapabilities: failed,
    producer: producer,
    runnerVersion: '1.0.0',
    recordedAtUtc: recordedAtUtc,
  );
}
