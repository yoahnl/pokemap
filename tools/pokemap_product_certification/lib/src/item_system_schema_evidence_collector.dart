import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'item_system_certification.dart';
import 'item_system_execution_receipt.dart';
import 'item_system_fixture_digest.dart';

final class ItemSystemSchemaEvidenceCollector {
  const ItemSystemSchemaEvidenceCollector();

  Future<ItemSystemExecutionReceipt> collect({
    required Directory projectRootDirectory,
    required String sourceRevision,
    required DateTime recordedAtUtc,
  }) async {
    final required = ItemSystemV1CertificationProfile.requiredCapabilitiesFor(
      ItemSystemProofLevel.schemaL0,
    );
    final succeeded = <String>{};
    final failed = <String>{};
    final payload = <String, Object?>{};
    final errors = <String, Object?>{};
    final fixtureSha256 = await computeItemSystemFixtureSha256(
      projectRootDirectory,
    );
    final catalogFile = File(
      p.join(projectRootDirectory.path, 'data/pokemon/catalogs/items.json'),
    );
    final projectFile = File(p.join(projectRootDirectory.path, 'project.json'));

    await _execute(
      'catalog_schema',
      succeeded: succeeded,
      failed: failed,
      errors: errors,
      operation: () async {
        final catalogJson = jsonDecode(await catalogFile.readAsString());
        final catalog = decodeProjectItemCatalog(catalogJson);
        final validation = validateProjectItemCatalog(
          catalog,
          capabilityTruth: itemSystemV1CapabilityTruth,
        );
        if (validation.hasBlockingDiagnostics) {
          throw StateError('The Golden item catalog has blocking diagnostics.');
        }
        payload['catalogSchemaVersion'] = catalog.schemaVersion;
        payload['catalogEntryCount'] = catalog.entries.length;
        payload['catalogEntryIds'] =
            catalog.entries.map((entry) => entry.id).toList(growable: false)
              ..sort();
      },
    );

    late Map<String, dynamic> projectJson;
    late ProjectManifest project;
    await _execute(
      'bag_schema',
      succeeded: succeeded,
      failed: failed,
      errors: errors,
      operation: () async {
        projectJson =
            jsonDecode(await projectFile.readAsString())
                as Map<String, dynamic>;
        project = ProjectManifest.fromJson(projectJson);
        final rawBag =
            (projectJson['newGame'] as Map<String, dynamic>)['initialBag'];
        if (rawBag is! List ||
            rawBag.any(
              (entry) =>
                  entry is! Map ||
                  entry.keys.toSet().difference(<String>{
                    'itemId',
                    'quantity',
                  }).isNotEmpty,
            )) {
          throw StateError('The Golden initial Bag is not canonical.');
        }
        final bag = Bag(entries: project.newGame.initialBag).normalized();
        payload['initialBagEntryCount'] = bag.entries.length;
        payload['initialBagJson'] = bag.toJson();
      },
    );

    late Map<String, dynamic> canonicalSaveJson;
    await _execute(
      'save_schema',
      succeeded: succeeded,
      failed: failed,
      errors: errors,
      operation: () async {
        final save = SaveData(
          saveId: 'item-system-schema-proof',
          bag: Bag(entries: project.newGame.initialBag),
        ).normalized();
        canonicalSaveJson = save.toJson();
        final decoded = SaveData.fromJson(canonicalSaveJson).normalized();
        if (decoded.bag != save.bag ||
            decoded.itemSystemSchemaVersion !=
                currentItemSystemSaveSchemaVersion) {
          throw StateError('The strict Item save did not round-trip.');
        }
        payload['saveSchemaVersion'] = decoded.itemSystemSchemaVersion;
        payload['saveRoundTripBagEntryCount'] = decoded.bag.entries.length;
      },
    );

    await _execute(
      'legacy_rejection',
      succeeded: succeeded,
      failed: failed,
      errors: errors,
      operation: () async {
        final catalogJson =
            jsonDecode(await catalogFile.readAsString())
                as Map<String, dynamic>;
        final legacyCatalog =
            jsonDecode(jsonEncode(catalogJson)) as Map<String, dynamic>;
        final catalogEntries = legacyCatalog['entries'] as List<dynamic>;
        (catalogEntries.first as Map<String, dynamic>)['categoryId'] =
            'medicine';
        final legacyCatalogRejected = _throws<ProjectItemCatalogCodecException>(
          () => decodeProjectItemCatalog(legacyCatalog),
        );
        final legacySave =
            jsonDecode(jsonEncode(canonicalSaveJson)) as Map<String, dynamic>;
        final bag = legacySave['bag'] as Map<String, dynamic>;
        final entries = bag['entries'] as List<dynamic>;
        (entries.first as Map<String, dynamic>)['categoryId'] = 'medicine';
        final legacySaveRejected = _throws<UnsupportedSaveSchema>(
          () => SaveData.fromJson(legacySave),
        );
        final missingMarker =
            jsonDecode(jsonEncode(canonicalSaveJson)) as Map<String, dynamic>
              ..remove('itemSystemSchemaVersion');
        final missingSaveSchemaRejected = _throws<UnsupportedSaveSchema>(
          () => SaveData.fromJson(missingMarker),
        );
        if (!legacyCatalogRejected ||
            !legacySaveRejected ||
            !missingSaveSchemaRejected) {
          throw StateError('At least one historical Item wire was accepted.');
        }
        payload['legacyCatalogRejected'] = legacyCatalogRejected;
        payload['legacySaveRejected'] = legacySaveRejected;
        payload['missingSaveSchemaRejected'] = missingSaveSchemaRejected;
      },
    );

    await _execute(
      'capability_matrix_rejection',
      succeeded: succeeded,
      failed: failed,
      errors: errors,
      operation: () async {
        final hostileCatalog = ProjectItemCatalog(
          schemaVersion: 1,
          entries: const <ProjectItemDefinition>[
            ProjectItemDefinition(
              id: 'battle-ether',
              displayName: 'Battle Ether',
              pocketId: 'medicine',
              uses: <ProjectItemUseDefinition>[
                ProjectItemUseDefinition(
                  contexts: <ProjectItemUseContext>{
                    ProjectItemUseContext.battle,
                  },
                  target: ProjectItemTargetKind.partyMove,
                  consumption: ProjectItemConsumptionPolicy.onApplied,
                  effect: ProjectItemEffectDefinition.restorePp(
                    mode: ProjectItemAmountMode.flat,
                    amount: 10,
                  ),
                ),
              ],
            ),
            ProjectItemDefinition(
              id: 'unknown-held-effect',
              displayName: 'Unknown Held Effect',
              pocketId: 'held',
              heldEffectId: 'never_registered_effect',
            ),
            ProjectItemDefinition(
              id: 'overworld-repel',
              displayName: 'Overworld Repel',
              pocketId: 'items',
              uses: <ProjectItemUseDefinition>[
                ProjectItemUseDefinition(
                  contexts: <ProjectItemUseContext>{
                    ProjectItemUseContext.overworld,
                  },
                  target: ProjectItemTargetKind.world,
                  consumption: ProjectItemConsumptionPolicy.onApplied,
                  effect: ProjectItemEffectDefinition.repel(steps: 100),
                ),
              ],
            ),
          ],
        );
        final validation = validateProjectItemCatalog(
          hostileCatalog,
          capabilityTruth: itemSystemV1CapabilityTruth,
        );
        final rejections = <Object?>[];
        for (final itemId in const <String>[
          'battle-ether',
          'unknown-held-effect',
          'overworld-repel',
        ]) {
          final assessment = validation.assessmentFor(itemId);
          final blockingCodes =
              validation.diagnostics
                  .where(
                    (diagnostic) =>
                        diagnostic.itemId == itemId && diagnostic.isBlocking,
                  )
                  .map((diagnostic) => diagnostic.code.name)
                  .toSet()
                  .toList()
                ..sort();
          if (assessment?.readiness != ItemCapabilityReadiness.unsupported ||
              blockingCodes.isEmpty) {
            throw StateError('$itemId was not rejected by runtime truth.');
          }
          rejections.add(<String, Object?>{
            'blockingCodes': blockingCodes,
            'itemId': itemId,
            'readiness': assessment!.readiness.name,
          });
        }
        payload['capabilityMatrixRejections'] = rejections;
      },
    );

    if (errors.isNotEmpty) payload['errors'] = errors;
    return ItemSystemExecutionReceipt.record(
      level: ItemSystemProofLevel.schemaL0,
      sourceRevision: sourceRevision,
      fixtureSha256: fixtureSha256,
      payload: payload,
      attemptedCapabilities: required,
      succeededCapabilities: succeeded,
      failedCapabilities: failed,
      producer: 'item-system-schema-evidence-collector',
      runnerVersion: '1.0.0',
      recordedAtUtc: recordedAtUtc,
    );
  }
}

Future<void> _execute(
  String capability, {
  required Set<String> succeeded,
  required Set<String> failed,
  required Map<String, Object?> errors,
  required Future<void> Function() operation,
}) async {
  try {
    await operation();
    succeeded.add(capability);
  } on Object catch (error) {
    failed.add(capability);
    errors[capability] = error.toString();
  }
}

bool _throws<T extends Object>(void Function() operation) {
  try {
    operation();
    return false;
  } on T {
    return true;
  }
}
