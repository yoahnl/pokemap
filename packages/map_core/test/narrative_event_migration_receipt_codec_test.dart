import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NS-EVENT-V2 Phase D D0-A migration choice contract', () {
    test('round-trips an explicit candidate confirmation', () {
      final choice = NarrativeEventMigrationSourceChoice.confirmCandidate(
        provenance: LegacySourceRef.mapEvent('map_a', 'legacy_a'),
        source: NarrativeEventSourceRef.entityInteract('map_a', 'npc_a'),
        targets: [_target()],
      );

      expect(
        choice.kind,
        NarrativeEventMigrationSourceChoiceKind.confirmCandidate,
      );
      expect(choice.reassignmentReason, isNull);
      expect(choice.toJson()['kind'], 'confirmCandidate');
      expect(
        NarrativeEventMigrationSourceChoice.fromJson(choice.toJson()).toJson(),
        choice.toJson(),
      );
    });

    test('requires and preserves a human reason for explicit reassignment', () {
      final choice = NarrativeEventMigrationSourceChoice.explicitReassignment(
        provenance: LegacySourceRef.mapEvent('map_a', 'legacy_a'),
        source: NarrativeEventSourceRef.triggerEnter('map_a', 'zone_a'),
        targets: [_target()],
        reason: 'La source legacy désigne désormais la zone du quai.',
      );

      expect(
        choice.kind,
        NarrativeEventMigrationSourceChoiceKind.explicitReassignment,
      );
      expect(
        choice.reassignmentReason,
        'La source legacy désigne désormais la zone du quai.',
      );
      expect(
        NarrativeEventMigrationSourceChoice.fromJson(choice.toJson()).toJson(),
        choice.toJson(),
      );
      expect(
        () => NarrativeEventMigrationSourceChoice.explicitReassignment(
          provenance: LegacySourceRef.mapEvent('map_a', 'legacy_a'),
          source: NarrativeEventSourceRef.triggerEnter('map_a', 'zone_a'),
          targets: [_target()],
          reason: '   ',
        ),
        throwsArgumentError,
      );
    });
  });

  group('NS-EVENT-V2 Phase D D0-A strict receipt codec', () {
    test('decodes a known receipt and preserves canonical round-trip', () {
      final receipt = _receipt();
      final bytes = utf8.encode(jsonEncode(receipt.toJson()));

      final result = decodeNarrativeEventMigrationReceiptStrict(bytes);

      expect(_state(result), 'decoded');
      expect(result.receiptOrNull, isNotNull);
      expect(result.originalJsonBytes, bytes);
      expect(result.toJson(), receipt.toJson());
      expect(
        result.receiptOrNull!.sourceChoices.single.kind,
        NarrativeEventMigrationSourceChoiceKind.confirmCandidate,
      );
    });

    test('classifies future fields, schemas, and enums as unsupported', () {
      final futureRoot = _receiptJson()..['futureField'] = true;
      final futureNested = _receiptJson();
      (futureNested['snapshot']! as Map<String, Object?>)['futureHash'] =
          _hash('9');
      final futureMapping = _receiptJson();
      final mappings = futureMapping['mappings']! as Map<String, Object?>;
      final idMapping =
          (mappings['ids']! as List<Object?>).single as Map<String, Object?>;
      idMapping['futureMappingField'] = true;
      final futureSchema = _receiptJson()..['schemaVersion'] = 99;
      final futureEnum = _receiptJson();
      (futureEnum['lifecycle']! as Map<String, Object?>)['status'] =
          'futureStatus';

      for (final raw in [
        futureRoot,
        futureNested,
        futureMapping,
        futureSchema,
        futureEnum,
      ]) {
        final bytes = utf8.encode(jsonEncode(raw));
        final result = decodeNarrativeEventMigrationReceiptStrict(bytes);

        expect(_state(result), 'unsupported');
        expect(result.receiptOrNull, isNull);
        expect(result.originalJsonBytes, bytes);
        expect(result.rawReceiptJson, raw);
        expect(() => result.toJson(), throwsStateError);
        expect(
          () => result.originalJsonBytes.add(0),
          throwsUnsupportedError,
        );
      }
    });

    test('classifies malformed known data as invalid without rewriting it', () {
      final missing = _receiptJson()..remove('snapshot');
      final wrongType = _receiptJson()..['cohortIds'] = 'not-a-list';
      final invalidInvariant = _receiptJson();
      (invalidInvariant['targetRecords']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .single['enabled'] = true;
      final invalidChoiceAttribution = _receiptJson();
      final sourceChoice =
          (invalidChoiceAttribution['sourceChoices']! as List<Object?>).single
              as Map<String, Object?>;
      final sourceChoiceTarget = (sourceChoice['targets']! as List<Object?>)
          .single as Map<String, Object?>;
      sourceChoiceTarget['name'] = 'Autre cible';
      final unknownMappedTarget = _receiptJson();
      final unknownMappings =
          unknownMappedTarget['mappings']! as Map<String, Object?>;
      final unknownIdMapping = (unknownMappings['ids']! as List<Object?>).single
          as Map<String, Object?>;
      unknownIdMapping['targetEventIds'] = [
        'evt_018f0000-0000-7000-8000-000000000099',
      ];
      final foreignProvenance = _receiptJson();
      final foreignMappings =
          foreignProvenance['mappings']! as Map<String, Object?>;
      final foreignIdMapping = (foreignMappings['ids']! as List<Object?>).single
          as Map<String, Object?>;
      foreignIdMapping['provenance'] =
          LegacySourceRef.mapEvent('map_b', 'legacy_b').toJson();

      for (final raw in [
        missing,
        wrongType,
        invalidInvariant,
        invalidChoiceAttribution,
        unknownMappedTarget,
        foreignProvenance,
      ]) {
        final bytes = utf8.encode(jsonEncode(raw));
        final result = decodeNarrativeEventMigrationReceiptStrict(bytes);

        expect(_state(result), 'invalid');
        expect(result.receiptOrNull, isNull);
        expect(result.originalJsonBytes, bytes);
        expect(result.rawReceiptJson, raw);
        expect(() => result.toJson(), throwsStateError);
      }
    });

    test('rejects literal and escaped duplicate keys before jsonDecode', () {
      final encoded = jsonEncode(_receiptJson());
      final literalDuplicate = encoded.replaceFirst(
        '"snapshot":{',
        '"snapshot":{"manifestHash":"${_hash('0')}",',
      );
      final escapedDuplicate = encoded.replaceFirst(
        '"snapshot":{',
        '"snapshot":{"manifest\\u0048ash":"${_hash('0')}",',
      );
      final mappingDuplicate = encoded.replaceFirst(
        '"ids":[{',
        '"ids":[{"legacyId":"legacy_duplicate",',
      );

      for (final source in [
        literalDuplicate,
        escapedDuplicate,
        mappingDuplicate,
      ]) {
        final bytes = utf8.encode(source);
        final result = decodeNarrativeEventMigrationReceiptStrict(bytes);

        expect(_state(result), 'invalid');
        expect(result.originalJsonBytes, bytes);
        expect(
          result.diagnostics.join('\n'),
          contains(r'Duplicate JSON key at $.'),
        );
      }
    });

    test('classifies malformed JSON as invalid and preserves original bytes',
        () {
      final bytes = utf8.encode('{"receiptId":');

      final result = decodeNarrativeEventMigrationReceiptStrict(bytes);

      expect(_state(result), 'invalid');
      expect(result.originalJsonBytes, bytes);
      expect(result.receiptOrNull, isNull);
      expect(() => result.toJson(), throwsStateError);
    });
  });
}

String _state(NarrativeEventMigrationReceiptDecodeResult result) {
  return result.when(
    decoded: (_) => 'decoded',
    unsupported: (_, __, ___) => 'unsupported',
    invalid: (_, __, ___) => 'invalid',
  );
}

NarrativeEventMigrationTargetProposal _target() {
  return NarrativeEventMigrationTargetProposal(
    name: 'Legacy A',
    conditions: const [],
    sceneId: 'scene_a',
    reusePolicy: NarrativeEventReusePolicy.oneShot,
    priority: 0,
    order: 0,
  );
}

NarrativeEventMigrationReceipt _receipt() {
  final provenance = LegacySourceRef.mapEvent('map_a', 'legacy_a');
  final source = NarrativeEventSourceRef.entityInteract('map_a', 'npc_a');
  const eventId = 'evt_018f0000-0000-7000-8000-000000000001';
  const receiptId = 'evmr_018f0000-0000-7000-8000-000000000002';
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: _hash('c'),
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  final snapshot = _snapshot(
    legacySourceHashes: {
      legacyMigrationSourceSnapshotKey(provenance): _hash('c'),
    },
  );
  final record = NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: eventId,
      name: 'Legacy A',
      source: source,
      conditions: const [],
      sceneId: 'scene_a',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: false,
  );
  final claim = LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(
      cohortId,
      [member],
    ),
    targetEventIds: const [eventId],
    migrationReceiptId: receiptId,
  );
  final choice = NarrativeEventMigrationSourceChoice.confirmCandidate(
    provenance: provenance,
    source: source,
    targets: [_target()],
  );

  return NarrativeEventMigrationReceipt(
    receiptId: receiptId,
    isProposal: true,
    snapshot: snapshot,
    expectedManifestHashAfter: _hash('1'),
    expectedRegistryHashAfter: _hash('2'),
    lifecycle: NarrativeEventMigrationReceiptLifecycle.prepared(
      DateTime.utc(2026, 7, 11, 10),
    ),
    cohortIds: [cohortId],
    mappings: NarrativeEventReferenceMappings(
      idMappings: [
        NarrativeEventIdMapping(
          provenance: provenance,
          legacyId: 'legacy_a',
          targetEventIds: const [eventId],
        ),
      ],
      pageMappings: [
        NarrativeEventPageMapping(
          provenance: provenance,
          pageIndex: 0,
          pageNumber: 1,
          status: NarrativeEventPageMappingStatus.mapped,
          targetEventId: eventId,
          sceneId: 'scene_a',
          preservedPageJson: const {'pageNumber': 1},
        ),
      ],
    ),
    sourceChoices: [choice],
    targetRecords: [record],
    targetClaims: [claim],
    backupPlan: NarrativeEventMigrationBackupPlan(
      futureDestinations: const {
        'manifest': 'backups/phase-c/project.json',
        'receipt': 'backups/phase-c/receipt.json',
      },
    ),
    writePreconditions: NarrativeEventMigrationWritePreconditions(
      snapshot: snapshot,
    ),
    atomicityPlan: NarrativeEventMigrationAtomicityPlan.phaseCProposal(),
    rollbackPlan: NarrativeEventMigrationRollbackPlan.phaseCProposal(),
    pointOfNoReturn: NarrativeEventMigrationPointOfNoReturn.phaseCProposal(),
  );
}

NarrativeEventMigrationSnapshot _snapshot({
  Map<String, String> legacySourceHashes = const {},
}) {
  return NarrativeEventMigrationSnapshot(
    projectRevisionToken: 'revision-1',
    manifestHash: _hash('a'),
    corpusHash: _hash('d'),
    referenceCatalogHash: _hash('e'),
    mapHashes: {'map_a': _hash('b')},
    legacySourceHashes: legacySourceHashes,
    saveHashes: {'save_a': _hash('f')},
  );
}

Map<String, Object?> _receiptJson() {
  return jsonDecode(jsonEncode(_receipt().toJson())) as Map<String, Object?>;
}

String _hash(String character) => 'sha256:${character * 64}';
