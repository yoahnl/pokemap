import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NS-EVENT-V2 Phase C4 migration receipt', () {
    test('round-trips the prepared receipt through a canonical JSON golden',
        () {
      final receipt = _receipt();
      final canonical = canonicalizeNarrativeEventJson(receipt.toJson());

      expect(canonical, _receiptGolden);
      final decoded = NarrativeEventMigrationReceipt.fromJson(
        receipt.toJson(),
      );
      expect(
        canonicalizeNarrativeEventJson(decoded.toJson()),
        _receiptGolden,
      );
      expect(decoded.isProposal, isTrue);
      expect(
        decoded.lifecycle.status,
        NarrativeEventMigrationReceiptStatus.prepared,
      );
      expect(decoded.expectedManifestHashAfter, _hash('1'));
      expect(decoded.expectedRegistryHashAfter, _hash('2'));
    });

    test('requires valid expected after hashes', () {
      final missingManifestHash = _receiptJson()
        ..remove('expectedManifestHashAfter');
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(missingManifestHash),
        throwsFormatException,
      );

      final missingRegistryHash = _receiptJson()
        ..remove('expectedRegistryHashAfter');
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(missingRegistryHash),
        throwsFormatException,
      );

      final malformedManifestHash = _receiptJson();
      malformedManifestHash['expectedManifestHashAfter'] = 'sha256:${'A' * 64}';
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(malformedManifestHash),
        throwsArgumentError,
      );

      final malformedRegistryHash = _receiptJson();
      malformedRegistryHash['expectedRegistryHashAfter'] = 'sha256:short';
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(malformedRegistryHash),
        throwsArgumentError,
      );
    });

    test('models prepared, committed, and recovered without false atomicity',
        () {
      final prepared = NarrativeEventMigrationReceiptLifecycle.prepared(
        DateTime.utc(2026, 7, 11, 10),
      );
      final committed = prepared.committed(DateTime.utc(2026, 7, 11, 10, 1));
      final recovered = committed.recovered(DateTime.utc(2026, 7, 11, 10, 2));

      expect(committed.status, NarrativeEventMigrationReceiptStatus.committed);
      expect(recovered.status, NarrativeEventMigrationReceiptStatus.recovered);
      expect(
        () => committed.committed(DateTime.utc(2026, 7, 11, 10, 3)),
        throwsStateError,
      );
      expect(
        () => prepared.recovered(DateTime.utc(2026, 7, 11, 9)),
        throwsArgumentError,
      );

      final receipt = _receipt();
      expect(receipt.atomicityPlan.claimsMultiFileAtomicity, isFalse);
      expect(receipt.atomicityPlan.manifestStagingRequired, isTrue);
      expect(receipt.atomicityPlan.unitRenameOnly, isTrue);
      expect(receipt.atomicityPlan.legacyMapsRemainUnchanged, isTrue);
      expect(receipt.atomicityPlan.crashRecoveryUsesJournal, isTrue);
      expect(
        receipt.atomicityPlan.journalStates,
        ['prepared', 'committed', 'recovered'],
      );
    });

    test('rejects every dishonest atomicity claim from copied JSON', () {
      const dishonestValues = <String, Object?>{
        'claimsMultiFileAtomicity': true,
        'manifestStagingRequired': false,
        'unitRenameOnly': false,
        'legacyMapsRemainUnchanged': false,
        'crashRecoveryUsesJournal': false,
        'journalStates': ['prepared', 'committed'],
      };

      for (final entry in dishonestValues.entries) {
        final json = _receiptJson();
        _jsonObject(json, 'atomicityPlan')[entry.key] = entry.value;
        expect(
          () => NarrativeEventMigrationReceipt.fromJson(json),
          throwsArgumentError,
          reason: entry.key,
        );
      }
    });

    test('makes rollback and the point of no return explicit', () {
      final receipt = _receipt();
      final rollback = receipt.rollbackPlan;
      final point = receipt.pointOfNoReturn;

      expect(rollback.requiresUnchangedRevision, isTrue);
      expect(rollback.requiresMatchingHashes, isTrue);
      expect(rollback.availableBeforePointOfNoReturn, isTrue);
      expect(rollback.availableAfterPointOfNoReturn, isFalse);
      expect(rollback.compensatingMigrationRequiredAfter, isTrue);
      expect(point.reached, isFalse);
      expect(point.compensatingMigrationRequiredAfter, isTrue);
      expect(
        point.trigger,
        NarrativeEventMigrationPointOfNoReturn.v2OnlyProgressTrigger,
      );
      final provenance = LegacySourceRef.mapEvent('map_a', 'legacy_a');
      expect(
        receipt.writePreconditions.matches(
          _snapshot(
            legacySourceHashes: {
              legacyMigrationSourceSnapshotKey(provenance): _hash('c'),
            },
          ),
        ),
        isTrue,
      );
      expect(
        receipt.writePreconditions.matches(
          _snapshot(
            projectRevisionToken: 'revision-2',
            legacySourceHashes: {
              legacyMigrationSourceSnapshotKey(provenance): _hash('c'),
            },
          ),
        ),
        isFalse,
      );
    });

    test('requires concrete manifest and receipt backup destinations', () {
      expect(
        () => NarrativeEventMigrationBackupPlan(
          futureDestinations: const {},
        ),
        throwsArgumentError,
      );
      for (final flags in const [
        (createBeforeCommit: false, noBackupCreatedInPhaseC: true),
        (createBeforeCommit: true, noBackupCreatedInPhaseC: false),
      ]) {
        expect(
          () => NarrativeEventMigrationBackupPlan(
            futureDestinations: const {
              'manifest': 'backup/project.json',
              'receipt': 'backup/receipt.json',
            },
            createBeforeCommit: flags.createBeforeCommit,
            noBackupCreatedInPhaseC: flags.noBackupCreatedInPhaseC,
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => NarrativeEventMigrationBackupPlan(
          futureDestinations: const {'manifest': 'backup/project.json'},
        ),
        throwsArgumentError,
      );
      expect(
        () => NarrativeEventMigrationBackupPlan(
          futureDestinations: const {
            'manifest': 'backup/shared.json',
            'receipt': 'backup/shared.json',
          },
        ),
        throwsArgumentError,
      );
    });

    test('rejects every dishonest rollback claim from copied JSON', () {
      const dishonestValues = <String, Object?>{
        'requiresUnchangedRevision': false,
        'requiresMatchingHashes': false,
        'availableBeforePointOfNoReturn': false,
        'availableAfterPointOfNoReturn': true,
        'compensatingMigrationRequiredAfter': false,
      };

      for (final entry in dishonestValues.entries) {
        final json = _receiptJson();
        _jsonObject(json, 'rollbackPlan')[entry.key] = entry.value;
        expect(
          () => NarrativeEventMigrationReceipt.fromJson(json),
          throwsArgumentError,
          reason: entry.key,
        );
      }
    });

    test('rejects divergent snapshots and weakened preconditions', () {
      const preconditionFlags = [
        'requireProjectWritable',
        'requireRegistryMigrationAllowed',
        'requireNoClaimConflicts',
      ];
      for (final flag in preconditionFlags) {
        final json = _receiptJson();
        _jsonObject(json, 'writePreconditions')[flag] = false;
        expect(
          () => NarrativeEventMigrationReceipt.fromJson(json),
          throwsArgumentError,
          reason: flag,
        );
      }

      final divergentSnapshot = _receiptJson();
      final writePreconditions = _jsonObject(
        divergentSnapshot,
        'writePreconditions',
      );
      _jsonObject(writePreconditions, 'snapshot')['manifestHash'] = _hash('9');
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(divergentSnapshot),
        throwsArgumentError,
      );
    });

    test('rejects weakened point-of-no-return guarantees', () {
      final reached = _receiptJson();
      _jsonObject(reached, 'pointOfNoReturn')['reached'] = true;
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(reached),
        throwsArgumentError,
      );

      final foreignTrigger = _receiptJson();
      _jsonObject(foreignTrigger, 'pointOfNoReturn')['trigger'] =
          'someOtherPointOfNoReturn';
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(foreignTrigger),
        throwsArgumentError,
      );

      final noCompensation = _receiptJson();
      _jsonObject(
        noCompensation,
        'pointOfNoReturn',
      )['compensatingMigrationRequiredAfter'] = false;
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(noCompensation),
        throwsArgumentError,
      );

      final changedDescription = _receiptJson();
      _jsonObject(
        changedDescription,
        'pointOfNoReturn',
      )['description'] = 'A different recovery boundary.';
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(changedDescription),
        throwsArgumentError,
      );
    });

    test('rejects altered rollback conditions', () {
      final changedConditions = _receiptJson();
      _jsonObject(
        changedConditions,
        'rollbackPlan',
      )['conditions'] = ['Revision checks are optional.'];

      expect(
        () => NarrativeEventMigrationReceipt.fromJson(changedConditions),
        throwsArgumentError,
      );
    });

    test('does not expose mutable receipt collections', () {
      final receipt = _receipt();
      expect(
        () => receipt.cohortIds.add('lsc_${'f' * 64}'),
        throwsUnsupportedError,
      );
      expect(
        () => receipt.snapshot.mapHashes['map_b'] = _hash('b'),
        throwsUnsupportedError,
      );
      expect(
        () => receipt.backupPlan.futureDestinations['manifest'] = 'changed',
        throwsUnsupportedError,
      );
    });

    test('rejects a dishonest proposal lifecycle or foreign claim receipt', () {
      final committedProposal = _receipt().toJson();
      committedProposal['lifecycle'] = {
        'status': 'committed',
        'preparedAt': '2026-07-11T10:00:00.000Z',
        'committedAt': '2026-07-11T10:01:00.000Z',
      };
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(committedProposal),
        throwsArgumentError,
      );

      final foreignReceipt = _receipt().toJson();
      foreignReceipt['receiptId'] = 'evmr_foreign';
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(foreignReceipt),
        throwsArgumentError,
      );
    });

    test('rejects a foreign cohort and duplicate receipt identities', () {
      final foreignCohort = _receiptJson();
      (foreignCohort['cohortIds']! as List<Object?>).add('lsc_${'f' * 64}');
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(foreignCohort),
        throwsArgumentError,
      );

      final duplicateCohortId = _receiptJson();
      final cohortIds = duplicateCohortId['cohortIds']! as List<Object?>;
      cohortIds.add(cohortIds.single);
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(duplicateCohortId),
        throwsArgumentError,
      );

      final duplicateRecordId = _receiptJson();
      final targetRecords =
          duplicateRecordId['targetRecords']! as List<Object?>;
      targetRecords.add(_deepCopyJson(targetRecords.single));
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(duplicateRecordId),
        throwsArgumentError,
      );

      final duplicateClaimCohort = _receiptJson();
      final targetClaims =
          duplicateClaimCohort['targetClaims']! as List<Object?>;
      targetClaims.add(_deepCopyJson(targetClaims.single));
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(duplicateClaimCohort),
        throwsArgumentError,
      );

      final unclaimedRecord = _receiptJson();
      final unclaimedTargetRecords =
          unclaimedRecord['targetRecords']! as List<Object?>;
      final extra =
          _deepCopyJson(unclaimedTargetRecords.single) as Map<String, Object?>;
      final definition = _jsonObject(extra, 'definition');
      definition['id'] = 'evt_018f0000-0000-7000-8000-000000000003';
      unclaimedTargetRecords.add(extra);
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(unclaimedRecord),
        throwsArgumentError,
      );

      final emptyReceipt = _receiptJson();
      emptyReceipt['cohortIds'] = <Object?>[];
      emptyReceipt['targetClaims'] = <Object?>[];
      emptyReceipt['targetRecords'] = <Object?>[];
      expect(
        () => NarrativeEventMigrationReceipt.fromJson(emptyReceipt),
        throwsArgumentError,
      );
    });

    test('rejects enabled targets in a preparation-only receipt', () {
      final enabledTarget = _receiptJson();
      final targetRecords = enabledTarget['targetRecords']! as List<Object?>;
      final targetRecord = targetRecords.single as Map<String, Object?>;
      targetRecord['enabled'] = true;

      expect(
        () => NarrativeEventMigrationReceipt.fromJson(enabledTarget),
        throwsArgumentError,
      );
    });

    test('rejects non-final reference mappings in a prepared receipt', () {
      final unresolved = _receiptJson();
      final mappings = _jsonObject(unresolved, 'mappings');
      final progression = mappings['progression']! as List<Object?>;
      final mapping = progression.single as Map<String, Object?>;
      mapping['status'] = 'requiresChoice';
      mapping['targetEventIds'] = <Object?>[];
      mapping['decision'] = 'selectedTargets';

      expect(
        () => NarrativeEventMigrationReceipt.fromJson(unresolved),
        throwsArgumentError,
      );
    });
  });
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
  final record = NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: eventId,
      name: 'Legacy A',
      source: source,
      conditions: [NarrativeEventCondition.fact('fact_a', true)],
      sceneId: 'scene_a',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: false,
  );
  final mappings = NarrativeEventReferenceMappings(
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
    progressionMappings: [
      NarrativeEventReferenceMapping(
        domain: NarrativeEventReferenceDomain.progression,
        kind: LegacyEventReferenceKind.consumedEventState,
        path: 'gameStates.save_a.consumedEventIds[0]',
        legacyEventId: 'legacy_a',
        candidateProvenances: [provenance],
        targetEventIds: const [eventId],
        status: NarrativeEventReferenceMappingStatus.mapped,
      ),
    ],
  );

  return NarrativeEventMigrationReceipt(
    receiptId: receiptId,
    isProposal: true,
    snapshot: _snapshot(
      legacySourceHashes: {
        legacyMigrationSourceSnapshotKey(provenance): _hash('c'),
      },
    ),
    expectedManifestHashAfter: _hash('1'),
    expectedRegistryHashAfter: _hash('2'),
    lifecycle: NarrativeEventMigrationReceiptLifecycle.prepared(
      DateTime.utc(2026, 7, 11, 10),
    ),
    cohortIds: [cohortId],
    mappings: mappings,
    targetRecords: [record],
    targetClaims: [claim],
    backupPlan: NarrativeEventMigrationBackupPlan(
      futureDestinations: const {
        'manifest': 'backups/phase-c/project.json',
        'receipt': 'backups/phase-c/receipt.json',
      },
    ),
    writePreconditions: NarrativeEventMigrationWritePreconditions(
      snapshot: _snapshot(
        legacySourceHashes: {
          legacyMigrationSourceSnapshotKey(provenance): _hash('c'),
        },
      ),
    ),
    atomicityPlan: NarrativeEventMigrationAtomicityPlan.phaseCProposal(),
    rollbackPlan: NarrativeEventMigrationRollbackPlan.phaseCProposal(),
    pointOfNoReturn: NarrativeEventMigrationPointOfNoReturn.phaseCProposal(),
  );
}

NarrativeEventMigrationSnapshot _snapshot({
  String projectRevisionToken = 'revision-1',
  Map<String, String> legacySourceHashes = const {},
}) {
  return NarrativeEventMigrationSnapshot(
    projectRevisionToken: projectRevisionToken,
    manifestHash: _hash('a'),
    corpusHash: _hash('d'),
    referenceCatalogHash: _hash('e'),
    mapHashes: {'map_a': _hash('b')},
    legacySourceHashes: legacySourceHashes,
    saveHashes: {'save_a': _hash('f')},
  );
}

String _hash(String character) => 'sha256:${character * 64}';

Map<String, Object?> _receiptJson() {
  return _deepCopyJson(_receipt().toJson()) as Map<String, Object?>;
}

Map<String, Object?> _jsonObject(
  Map<String, Object?> json,
  String key,
) {
  return json[key]! as Map<String, Object?>;
}

Object? _deepCopyJson(Object? value) => jsonDecode(jsonEncode(value));

const _receiptGolden =
    r'{"atomicityPlan":{"claimsMultiFileAtomicity":false,"crashRecoveryUsesJournal":true,"journalStates":["prepared","committed","recovered"],"legacyMapsRemainUnchanged":true,"manifestStagingRequired":true,"unitRenameOnly":true},'
    r'"backupPlan":{"createBeforeCommit":true,"futureDestinations":{"manifest":"backups/phase-c/project.json","receipt":"backups/phase-c/receipt.json"},"noBackupCreatedInPhaseC":true},'
    r'"cohortIds":["lsc_12536fa79346f0d0d0b4a2b8128859cdb911e05763077c6680b1badd122ffb2a"],'
    r'"expectedManifestHashAfter":"sha256:1111111111111111111111111111111111111111111111111111111111111111",'
    r'"expectedRegistryHashAfter":"sha256:2222222222222222222222222222222222222222222222222222222222222222",'
    r'"isProposal":true,'
    r'"lifecycle":{"preparedAt":"2026-07-11T10:00:00.000Z","status":"prepared"},'
    r'"mappings":{"conditions":[],"consequences":[],"ids":[{"legacyId":"legacy_a","provenance":{"eventId":"legacy_a","kind":"mapEvent","mapId":"map_a"},"targetEventIds":["evt_018f0000-0000-7000-8000-000000000001"]}],'
    r'"pages":[{"pageIndex":0,"pageNumber":1,"preservedPageJson":{"pageNumber":1},"provenance":{"eventId":"legacy_a","kind":"mapEvent","mapId":"map_a"},"sceneId":"scene_a","status":"mapped","targetEventId":"evt_018f0000-0000-7000-8000-000000000001"}],'
    r'"progression":[{"candidateProvenances":[{"eventId":"legacy_a","kind":"mapEvent","mapId":"map_a"}],"domain":"progression","kind":"consumedEventState","legacyEventId":"legacy_a","path":"gameStates.save_a.consumedEventIds[0]","status":"mapped","targetEventIds":["evt_018f0000-0000-7000-8000-000000000001"]}],"saves":[],"worldRules":[]},'
    r'"phase":"NS-EVENT-V2-PHASE-C",'
    r'"pointOfNoReturn":{"compensatingMigrationRequiredAfter":true,"description":"Rollback stops being lossless after the first persisted V2-only progression bit or reference that cannot be represented exactly in legacy storage.","reached":false,"trigger":"firstPersistedV2OnlyProgressOrReferenceNotExactlyRepresentableInLegacy"},'
    r'"receiptId":"evmr_018f0000-0000-7000-8000-000000000002",'
    r'"rollbackPlan":{"availableAfterPointOfNoReturn":false,"availableBeforePointOfNoReturn":true,"compensatingMigrationRequiredAfter":true,"conditions":["The project revision token is unchanged.","Manifest, map, and legacy source hashes still match the receipt.","The future backup was created before commit.","No V2-only progression or reference has crossed the point of no return."],"requiresMatchingHashes":true,"requiresUnchangedRevision":true},'
    r'"schemaVersion":1,'
    r'"snapshot":{"corpusHash":"sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd","legacySourceHashes":{"legacySource:{\"eventId\":\"legacy_a\",\"kind\":\"mapEvent\",\"mapId\":\"map_a\"}":"sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"},"manifestHash":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","mapHashes":{"map_a":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"},"projectRevisionToken":"revision-1","referenceCatalogHash":"sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee","saveHashes":{"save_a":"sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"}},'
    r'"targetClaims":[{"cohortFingerprint":"sha256:8ed85ba1d8ea0549a2b2f20de4de94429b267d7267593c054684ccf175366006","cohortId":"lsc_12536fa79346f0d0d0b4a2b8128859cdb911e05763077c6680b1badd122ffb2a","members":[{"provenance":{"eventId":"legacy_a","kind":"mapEvent","mapId":"map_a"},"sourceFingerprint":"sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"}],"migrationReceiptId":"evmr_018f0000-0000-7000-8000-000000000002","source":{"entityId":"npc_a","kind":"entityInteract","mapId":"map_a"},"targetEventIds":["evt_018f0000-0000-7000-8000-000000000001"]}],'
    r'"targetRecords":[{"definition":{"conditions":[{"expectedValue":true,"factId":"fact_a","kind":"fact"}],"id":"evt_018f0000-0000-7000-8000-000000000001","name":"Legacy A","order":0,"priority":0,"reusePolicy":"oneShot","sceneId":"scene_a","source":{"entityId":"npc_a","kind":"entityInteract","mapId":"map_a"}},"enabled":false,"state":"configured"}],'
    r'"writePreconditions":{"requireNoClaimConflicts":true,"requireProjectWritable":true,"requireRegistryMigrationAllowed":true,"snapshot":{"corpusHash":"sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd","legacySourceHashes":{"legacySource:{\"eventId\":\"legacy_a\",\"kind\":\"mapEvent\",\"mapId\":\"map_a\"}":"sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"},"manifestHash":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","mapHashes":{"map_a":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"},"projectRevisionToken":"revision-1","referenceCatalogHash":"sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee","saveHashes":{"save_a":"sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"}}}}';
