import 'package:meta/meta.dart' show immutable;

import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../operations/narrative_event_canonical_json.dart';
import 'narrative_event_reference_mapping.dart';

final RegExp _fingerprintPattern = RegExp(r'^sha256:[0-9a-f]{64}$');

String legacyMigrationSourceSnapshotKey(LegacySourceRef provenance) {
  return 'legacySource:${canonicalizeNarrativeEventJson(provenance.toJson())}';
}

@immutable
final class NarrativeEventMigrationSnapshot {
  NarrativeEventMigrationSnapshot({
    required String projectRevisionToken,
    required String manifestHash,
    required String corpusHash,
    required String referenceCatalogHash,
    required Map<String, String> mapHashes,
    required Map<String, String> legacySourceHashes,
    required Map<String, String> saveHashes,
  })  : projectRevisionToken = _identity(
          projectRevisionToken,
          'projectRevisionToken',
        ),
        manifestHash = _fingerprint(manifestHash, 'manifestHash'),
        corpusHash = _fingerprint(corpusHash, 'corpusHash'),
        referenceCatalogHash = _fingerprint(
          referenceCatalogHash,
          'referenceCatalogHash',
        ),
        mapHashes = _fingerprintMap(mapHashes, 'mapHashes'),
        legacySourceHashes = _fingerprintMap(
          legacySourceHashes,
          'legacySourceHashes',
        ),
        saveHashes = _fingerprintMap(saveHashes, 'saveHashes');

  factory NarrativeEventMigrationSnapshot.fromJson(Object? json) {
    final object = _object(json, 'snapshot');
    return NarrativeEventMigrationSnapshot(
      projectRevisionToken: _string(object, 'projectRevisionToken'),
      manifestHash: _string(object, 'manifestHash'),
      corpusHash: _string(object, 'corpusHash'),
      referenceCatalogHash: _string(object, 'referenceCatalogHash'),
      mapHashes: _stringMap(object['mapHashes'], 'mapHashes'),
      legacySourceHashes: _stringMap(
        object['legacySourceHashes'],
        'legacySourceHashes',
      ),
      saveHashes: _stringMap(object['saveHashes'], 'saveHashes'),
    );
  }

  final String projectRevisionToken;
  final String manifestHash;
  final String corpusHash;
  final String referenceCatalogHash;
  final Map<String, String> mapHashes;
  final Map<String, String> legacySourceHashes;
  final Map<String, String> saveHashes;

  bool sameAs(NarrativeEventMigrationSnapshot other) {
    return canonicalizeNarrativeEventJson(toJson()) ==
        canonicalizeNarrativeEventJson(other.toJson());
  }

  Map<String, Object?> toJson() => {
        'projectRevisionToken': projectRevisionToken,
        'manifestHash': manifestHash,
        'corpusHash': corpusHash,
        'referenceCatalogHash': referenceCatalogHash,
        'mapHashes': mapHashes,
        'legacySourceHashes': legacySourceHashes,
        'saveHashes': saveHashes,
      };
}

@immutable
final class NarrativeEventMigrationWritePreconditions {
  NarrativeEventMigrationWritePreconditions({
    required this.snapshot,
    this.requireProjectWritable = true,
    this.requireRegistryMigrationAllowed = true,
    this.requireNoClaimConflicts = true,
  });

  factory NarrativeEventMigrationWritePreconditions.fromJson(Object? json) {
    final object = _object(json, 'writePreconditions');
    return NarrativeEventMigrationWritePreconditions(
      snapshot: NarrativeEventMigrationSnapshot.fromJson(object['snapshot']),
      requireProjectWritable: _boolean(object, 'requireProjectWritable'),
      requireRegistryMigrationAllowed:
          _boolean(object, 'requireRegistryMigrationAllowed'),
      requireNoClaimConflicts: _boolean(object, 'requireNoClaimConflicts'),
    );
  }

  final NarrativeEventMigrationSnapshot snapshot;
  final bool requireProjectWritable;
  final bool requireRegistryMigrationAllowed;
  final bool requireNoClaimConflicts;

  bool matches(NarrativeEventMigrationSnapshot current) =>
      snapshot.sameAs(current);

  Map<String, Object?> toJson() => {
        'snapshot': snapshot.toJson(),
        'requireProjectWritable': requireProjectWritable,
        'requireRegistryMigrationAllowed': requireRegistryMigrationAllowed,
        'requireNoClaimConflicts': requireNoClaimConflicts,
      };
}

@immutable
final class NarrativeEventMigrationBackupPlan {
  NarrativeEventMigrationBackupPlan({
    required Map<String, String> futureDestinations,
    this.createBeforeCommit = true,
    this.noBackupCreatedInPhaseC = true,
  }) : futureDestinations = _identityMap(
          futureDestinations,
          'futureDestinations',
        ) {
    if (!this.futureDestinations.containsKey('manifest') ||
        !this.futureDestinations.containsKey('receipt')) {
      throw ArgumentError(
        'Backup plans require manifest and receipt destinations.',
      );
    }
    if (this.futureDestinations['manifest'] ==
        this.futureDestinations['receipt']) {
      throw ArgumentError(
        'Manifest and receipt backups require distinct destinations.',
      );
    }
    if (!createBeforeCommit || !noBackupCreatedInPhaseC) {
      throw ArgumentError(
        'Phase C backup plans must require a future pre-commit backup and '
        'must not claim that a backup was already created.',
      );
    }
  }

  factory NarrativeEventMigrationBackupPlan.fromJson(Object? json) {
    final object = _object(json, 'backupPlan');
    return NarrativeEventMigrationBackupPlan(
      futureDestinations: _stringMap(
        object['futureDestinations'],
        'futureDestinations',
      ),
      createBeforeCommit: _boolean(object, 'createBeforeCommit'),
      noBackupCreatedInPhaseC: _boolean(
        object,
        'noBackupCreatedInPhaseC',
      ),
    );
  }

  final Map<String, String> futureDestinations;
  final bool createBeforeCommit;
  final bool noBackupCreatedInPhaseC;

  Map<String, Object?> toJson() => {
        'futureDestinations': futureDestinations,
        'createBeforeCommit': createBeforeCommit,
        'noBackupCreatedInPhaseC': noBackupCreatedInPhaseC,
      };
}

enum NarrativeEventMigrationReceiptStatus { prepared, committed, recovered }

@immutable
final class NarrativeEventMigrationReceiptLifecycle {
  NarrativeEventMigrationReceiptLifecycle._({
    required this.status,
    required DateTime preparedAt,
    DateTime? committedAt,
    DateTime? recoveredAt,
  })  : preparedAt = preparedAt.toUtc(),
        committedAt = committedAt?.toUtc(),
        recoveredAt = recoveredAt?.toUtc() {
    if (this.committedAt != null &&
        this.committedAt!.isBefore(this.preparedAt)) {
      throw ArgumentError('committedAt cannot precede preparedAt.');
    }
    final recoveryFloor = this.committedAt ?? this.preparedAt;
    if (this.recoveredAt != null && this.recoveredAt!.isBefore(recoveryFloor)) {
      throw ArgumentError(
        'recoveredAt cannot precede the latest journal state.',
      );
    }
    switch (status) {
      case NarrativeEventMigrationReceiptStatus.prepared:
        if (this.committedAt != null || this.recoveredAt != null) {
          throw ArgumentError(
            'A prepared lifecycle cannot contain later timestamps.',
          );
        }
      case NarrativeEventMigrationReceiptStatus.committed:
        if (this.committedAt == null || this.recoveredAt != null) {
          throw ArgumentError(
            'A committed lifecycle requires only committedAt.',
          );
        }
      case NarrativeEventMigrationReceiptStatus.recovered:
        if (this.recoveredAt == null) {
          throw ArgumentError('A recovered lifecycle requires recoveredAt.');
        }
    }
  }

  factory NarrativeEventMigrationReceiptLifecycle.prepared(
    DateTime preparedAt,
  ) {
    return NarrativeEventMigrationReceiptLifecycle._(
      status: NarrativeEventMigrationReceiptStatus.prepared,
      preparedAt: preparedAt,
    );
  }

  factory NarrativeEventMigrationReceiptLifecycle.fromJson(Object? json) {
    final object = _object(json, 'lifecycle');
    return NarrativeEventMigrationReceiptLifecycle._(
      status: _enumByName(
        NarrativeEventMigrationReceiptStatus.values,
        _string(object, 'status'),
        'lifecycle.status',
      ),
      preparedAt: _dateTime(object, 'preparedAt'),
      committedAt: _optionalDateTime(object['committedAt'], 'committedAt'),
      recoveredAt: _optionalDateTime(object['recoveredAt'], 'recoveredAt'),
    );
  }

  final NarrativeEventMigrationReceiptStatus status;
  final DateTime preparedAt;
  final DateTime? committedAt;
  final DateTime? recoveredAt;

  NarrativeEventMigrationReceiptLifecycle committed(DateTime at) {
    if (status != NarrativeEventMigrationReceiptStatus.prepared) {
      throw StateError('Only a prepared receipt can be committed.');
    }
    return NarrativeEventMigrationReceiptLifecycle._(
      status: NarrativeEventMigrationReceiptStatus.committed,
      preparedAt: preparedAt,
      committedAt: at,
    );
  }

  NarrativeEventMigrationReceiptLifecycle recovered(DateTime at) {
    if (status == NarrativeEventMigrationReceiptStatus.recovered) {
      throw StateError('A recovered receipt cannot be recovered twice.');
    }
    return NarrativeEventMigrationReceiptLifecycle._(
      status: NarrativeEventMigrationReceiptStatus.recovered,
      preparedAt: preparedAt,
      committedAt: committedAt,
      recoveredAt: at,
    );
  }

  Map<String, Object?> toJson() => {
        'status': status.name,
        'preparedAt': preparedAt.toIso8601String(),
        if (committedAt != null) 'committedAt': committedAt!.toIso8601String(),
        if (recoveredAt != null) 'recoveredAt': recoveredAt!.toIso8601String(),
      };
}

@immutable
final class NarrativeEventMigrationAtomicityPlan {
  NarrativeEventMigrationAtomicityPlan({
    required this.claimsMultiFileAtomicity,
    required this.manifestStagingRequired,
    required this.unitRenameOnly,
    required this.legacyMapsRemainUnchanged,
    required this.crashRecoveryUsesJournal,
    required List<String> journalStates,
  }) : journalStates = _identityList(journalStates, 'journalStates');

  factory NarrativeEventMigrationAtomicityPlan.phaseCProposal() {
    return NarrativeEventMigrationAtomicityPlan(
      claimsMultiFileAtomicity: false,
      manifestStagingRequired: true,
      unitRenameOnly: true,
      legacyMapsRemainUnchanged: true,
      crashRecoveryUsesJournal: true,
      journalStates: const ['prepared', 'committed', 'recovered'],
    );
  }

  factory NarrativeEventMigrationAtomicityPlan.fromJson(Object? json) {
    final object = _object(json, 'atomicityPlan');
    return NarrativeEventMigrationAtomicityPlan(
      claimsMultiFileAtomicity: _boolean(object, 'claimsMultiFileAtomicity'),
      manifestStagingRequired: _boolean(object, 'manifestStagingRequired'),
      unitRenameOnly: _boolean(object, 'unitRenameOnly'),
      legacyMapsRemainUnchanged: _boolean(object, 'legacyMapsRemainUnchanged'),
      crashRecoveryUsesJournal: _boolean(object, 'crashRecoveryUsesJournal'),
      journalStates: _stringList(object['journalStates'], 'journalStates'),
    );
  }

  final bool claimsMultiFileAtomicity;
  final bool manifestStagingRequired;
  final bool unitRenameOnly;
  final bool legacyMapsRemainUnchanged;
  final bool crashRecoveryUsesJournal;
  final List<String> journalStates;

  Map<String, Object?> toJson() => {
        'claimsMultiFileAtomicity': claimsMultiFileAtomicity,
        'manifestStagingRequired': manifestStagingRequired,
        'unitRenameOnly': unitRenameOnly,
        'legacyMapsRemainUnchanged': legacyMapsRemainUnchanged,
        'crashRecoveryUsesJournal': crashRecoveryUsesJournal,
        'journalStates': journalStates,
      };
}

@immutable
final class NarrativeEventMigrationRollbackPlan {
  static const phaseCConditions = [
    'The project revision token is unchanged.',
    'Manifest, map, and legacy source hashes still match the receipt.',
    'The future backup was created before commit.',
    'No V2-only progression or reference has crossed the point of no return.',
  ];

  NarrativeEventMigrationRollbackPlan({
    required this.requiresUnchangedRevision,
    required this.requiresMatchingHashes,
    required this.availableBeforePointOfNoReturn,
    required this.availableAfterPointOfNoReturn,
    required this.compensatingMigrationRequiredAfter,
    required List<String> conditions,
  }) : conditions = _identityList(conditions, 'conditions');

  factory NarrativeEventMigrationRollbackPlan.phaseCProposal() {
    return NarrativeEventMigrationRollbackPlan(
      requiresUnchangedRevision: true,
      requiresMatchingHashes: true,
      availableBeforePointOfNoReturn: true,
      availableAfterPointOfNoReturn: false,
      compensatingMigrationRequiredAfter: true,
      conditions: phaseCConditions,
    );
  }

  factory NarrativeEventMigrationRollbackPlan.fromJson(Object? json) {
    final object = _object(json, 'rollbackPlan');
    return NarrativeEventMigrationRollbackPlan(
      requiresUnchangedRevision: _boolean(object, 'requiresUnchangedRevision'),
      requiresMatchingHashes: _boolean(object, 'requiresMatchingHashes'),
      availableBeforePointOfNoReturn:
          _boolean(object, 'availableBeforePointOfNoReturn'),
      availableAfterPointOfNoReturn:
          _boolean(object, 'availableAfterPointOfNoReturn'),
      compensatingMigrationRequiredAfter:
          _boolean(object, 'compensatingMigrationRequiredAfter'),
      conditions: _stringList(object['conditions'], 'conditions'),
    );
  }

  final bool requiresUnchangedRevision;
  final bool requiresMatchingHashes;
  final bool availableBeforePointOfNoReturn;
  final bool availableAfterPointOfNoReturn;
  final bool compensatingMigrationRequiredAfter;
  final List<String> conditions;

  Map<String, Object?> toJson() => {
        'requiresUnchangedRevision': requiresUnchangedRevision,
        'requiresMatchingHashes': requiresMatchingHashes,
        'availableBeforePointOfNoReturn': availableBeforePointOfNoReturn,
        'availableAfterPointOfNoReturn': availableAfterPointOfNoReturn,
        'compensatingMigrationRequiredAfter':
            compensatingMigrationRequiredAfter,
        'conditions': conditions,
      };
}

@immutable
final class NarrativeEventMigrationPointOfNoReturn {
  static const v2OnlyProgressTrigger =
      'firstPersistedV2OnlyProgressOrReferenceNotExactlyRepresentableInLegacy';
  static const phaseCDescription =
      'Rollback stops being lossless after the first persisted V2-only '
      'progression bit or reference that cannot be represented exactly '
      'in legacy storage.';

  NarrativeEventMigrationPointOfNoReturn({
    required String trigger,
    required String description,
    required this.reached,
    required this.compensatingMigrationRequiredAfter,
  })  : trigger = _identity(trigger, 'trigger'),
        description = _identity(description, 'description');

  factory NarrativeEventMigrationPointOfNoReturn.phaseCProposal() {
    return NarrativeEventMigrationPointOfNoReturn(
      trigger: v2OnlyProgressTrigger,
      description: phaseCDescription,
      reached: false,
      compensatingMigrationRequiredAfter: true,
    );
  }

  factory NarrativeEventMigrationPointOfNoReturn.fromJson(Object? json) {
    final object = _object(json, 'pointOfNoReturn');
    return NarrativeEventMigrationPointOfNoReturn(
      trigger: _string(object, 'trigger'),
      description: _string(object, 'description'),
      reached: _boolean(object, 'reached'),
      compensatingMigrationRequiredAfter:
          _boolean(object, 'compensatingMigrationRequiredAfter'),
    );
  }

  final String trigger;
  final String description;
  final bool reached;
  final bool compensatingMigrationRequiredAfter;

  Map<String, Object?> toJson() => {
        'trigger': trigger,
        'description': description,
        'reached': reached,
        'compensatingMigrationRequiredAfter':
            compensatingMigrationRequiredAfter,
      };
}

@immutable
final class NarrativeEventMigrationReceipt {
  static const currentSchemaVersion = 1;
  static const phaseC = 'NS-EVENT-V2-PHASE-C';

  NarrativeEventMigrationReceipt({
    required String receiptId,
    this.schemaVersion = currentSchemaVersion,
    this.phase = phaseC,
    required this.isProposal,
    required this.snapshot,
    required String expectedManifestHashAfter,
    required String expectedRegistryHashAfter,
    required this.lifecycle,
    required List<String> cohortIds,
    required this.mappings,
    required List<NarrativeEventRecord> targetRecords,
    required List<LegacySourceClaim> targetClaims,
    required this.backupPlan,
    required this.writePreconditions,
    required this.atomicityPlan,
    required this.rollbackPlan,
    required this.pointOfNoReturn,
  })  : receiptId = _identity(receiptId, 'receiptId'),
        expectedManifestHashAfter = _fingerprint(
          expectedManifestHashAfter,
          'expectedManifestHashAfter',
        ),
        expectedRegistryHashAfter = _fingerprint(
          expectedRegistryHashAfter,
          'expectedRegistryHashAfter',
        ),
        cohortIds = _sortedUnique(cohortIds, 'cohortIds'),
        targetRecords = _sortedRecords(targetRecords),
        targetClaims = _sortedClaims(targetClaims) {
    if (schemaVersion != currentSchemaVersion) {
      throw ArgumentError.value(
        schemaVersion,
        'schemaVersion',
        'only schema version 1 is supported',
      );
    }
    if (phase != phaseC) {
      throw ArgumentError.value(phase, 'phase', 'must identify Phase C');
    }
    if (isProposal &&
        lifecycle.status != NarrativeEventMigrationReceiptStatus.prepared) {
      throw ArgumentError(
        'A Phase C proposal must remain in the prepared journal state.',
      );
    }
    if (isProposal &&
        (!backupPlan.noBackupCreatedInPhaseC || pointOfNoReturn.reached)) {
      throw ArgumentError(
        'A Phase C proposal cannot claim a backup or a reached point of no '
        'return.',
      );
    }
    if (!snapshot.sameAs(writePreconditions.snapshot)) {
      throw ArgumentError(
        'Receipt snapshot and write preconditions must be identical.',
      );
    }
    if (!writePreconditions.requireProjectWritable ||
        !writePreconditions.requireRegistryMigrationAllowed ||
        !writePreconditions.requireNoClaimConflicts) {
      throw ArgumentError(
        'Phase C receipts must retain every future write precondition.',
      );
    }
    if (atomicityPlan.claimsMultiFileAtomicity ||
        !atomicityPlan.manifestStagingRequired ||
        !atomicityPlan.unitRenameOnly ||
        !atomicityPlan.legacyMapsRemainUnchanged ||
        !atomicityPlan.crashRecoveryUsesJournal ||
        !_sameStrings(
          atomicityPlan.journalStates,
          const ['prepared', 'committed', 'recovered'],
        )) {
      throw ArgumentError(
        'Phase C receipts cannot claim multi-file atomicity or weaken the '
        'staging journal.',
      );
    }
    if (!rollbackPlan.requiresUnchangedRevision ||
        !rollbackPlan.requiresMatchingHashes ||
        !rollbackPlan.availableBeforePointOfNoReturn ||
        rollbackPlan.availableAfterPointOfNoReturn ||
        !rollbackPlan.compensatingMigrationRequiredAfter ||
        !_sameStrings(
          rollbackPlan.conditions,
          NarrativeEventMigrationRollbackPlan.phaseCConditions,
        )) {
      throw ArgumentError(
        'Phase C rollback is lossless only before the point of no return and '
        'while revision/hash preconditions still match.',
      );
    }
    if (!backupPlan.createBeforeCommit ||
        pointOfNoReturn.trigger !=
            NarrativeEventMigrationPointOfNoReturn.v2OnlyProgressTrigger ||
        pointOfNoReturn.description !=
            NarrativeEventMigrationPointOfNoReturn.phaseCDescription ||
        !pointOfNoReturn.compensatingMigrationRequiredAfter) {
      throw ArgumentError(
        'Phase C backup and point-of-no-return invariants cannot be weakened.',
      );
    }
    for (final mapping in mappings.allReferenceMappings) {
      if (mapping.status == NarrativeEventReferenceMappingStatus.mapped) {
        if (mapping.decision ==
            NarrativeEventReferenceCollisionDecision.cancel) {
          throw ArgumentError(
            'A mapped receipt reference cannot carry a cancel decision.',
          );
        }
        continue;
      }
      if (mapping.status ==
              NarrativeEventReferenceMappingStatus.preservedTombstone &&
          mapping.decision == null) {
        continue;
      }
      throw ArgumentError(
        'Phase C receipts require final mapped or preserved-tombstone '
        'reference mappings.',
      );
    }
    final recordIds = <String>{};
    for (final record in this.targetRecords) {
      if (!recordIds.add(record.id)) {
        throw ArgumentError('Receipt target record IDs must be unique.');
      }
      if (record.enabledOrNull == true) {
        throw ArgumentError(
          'Phase C receipt target records must remain disabled proposals.',
        );
      }
    }
    final claimCohortIds = <String>{};
    final claimedTargetIds = <String>{};
    for (final claim in this.targetClaims) {
      if (!claimCohortIds.add(claim.cohortId)) {
        throw ArgumentError('Receipt target claim cohorts must be unique.');
      }
      claimedTargetIds.addAll(claim.targetEventIds);
    }
    if (claimCohortIds.isEmpty) {
      throw ArgumentError('A migration receipt requires at least one claim.');
    }
    if (!_sameStrings(this.cohortIds, claimCohortIds.toList()..sort())) {
      throw ArgumentError(
        'Receipt cohortIds must exactly match its target claims.',
      );
    }
    if (!_sameStrings(
      recordIds.toList()..sort(),
      claimedTargetIds.toList()..sort(),
    )) {
      throw ArgumentError(
        'Receipt target records must exactly match claimed target IDs.',
      );
    }
    final recordsById = {
      for (final record in this.targetRecords) record.id: record,
    };
    for (final claim in this.targetClaims) {
      if (claim.migrationReceiptId != this.receiptId ||
          !this.cohortIds.contains(claim.cohortId)) {
        throw ArgumentError(
          'Every target claim must belong to this receipt and cohort list.',
        );
      }
      for (final targetId in claim.targetEventIds) {
        final target = recordsById[targetId]?.definitionOrNull;
        if (target == null || target.source != claim.source) {
          throw ArgumentError(
            'Every claim target must be a configured target record with the '
            'same source.',
          );
        }
      }
    }
  }

  factory NarrativeEventMigrationReceipt.fromJson(Object? json) {
    final object = _object(json, 'receipt');
    return NarrativeEventMigrationReceipt(
      receiptId: _string(object, 'receiptId'),
      schemaVersion: _integer(object, 'schemaVersion'),
      phase: _string(object, 'phase'),
      isProposal: _boolean(object, 'isProposal'),
      snapshot: NarrativeEventMigrationSnapshot.fromJson(object['snapshot']),
      expectedManifestHashAfter: _string(
        object,
        'expectedManifestHashAfter',
      ),
      expectedRegistryHashAfter: _string(
        object,
        'expectedRegistryHashAfter',
      ),
      lifecycle: NarrativeEventMigrationReceiptLifecycle.fromJson(
        object['lifecycle'],
      ),
      cohortIds: _stringList(object['cohortIds'], 'cohortIds'),
      mappings: NarrativeEventReferenceMappings.fromJson(object['mappings']),
      targetRecords: _list(object['targetRecords'], 'targetRecords')
          .map(NarrativeEventRecord.fromJson)
          .toList(),
      targetClaims: _list(object['targetClaims'], 'targetClaims')
          .map(LegacySourceClaim.fromJson)
          .toList(),
      backupPlan: NarrativeEventMigrationBackupPlan.fromJson(
        object['backupPlan'],
      ),
      writePreconditions: NarrativeEventMigrationWritePreconditions.fromJson(
        object['writePreconditions'],
      ),
      atomicityPlan: NarrativeEventMigrationAtomicityPlan.fromJson(
        object['atomicityPlan'],
      ),
      rollbackPlan: NarrativeEventMigrationRollbackPlan.fromJson(
        object['rollbackPlan'],
      ),
      pointOfNoReturn: NarrativeEventMigrationPointOfNoReturn.fromJson(
        object['pointOfNoReturn'],
      ),
    );
  }

  final String receiptId;
  final int schemaVersion;
  final String phase;
  final bool isProposal;
  final NarrativeEventMigrationSnapshot snapshot;
  final String expectedManifestHashAfter;
  final String expectedRegistryHashAfter;
  final NarrativeEventMigrationReceiptLifecycle lifecycle;
  final List<String> cohortIds;
  final NarrativeEventReferenceMappings mappings;
  final List<NarrativeEventRecord> targetRecords;
  final List<LegacySourceClaim> targetClaims;
  final NarrativeEventMigrationBackupPlan backupPlan;
  final NarrativeEventMigrationWritePreconditions writePreconditions;
  final NarrativeEventMigrationAtomicityPlan atomicityPlan;
  final NarrativeEventMigrationRollbackPlan rollbackPlan;
  final NarrativeEventMigrationPointOfNoReturn pointOfNoReturn;

  Map<String, Object?> toJson() => {
        'receiptId': receiptId,
        'schemaVersion': schemaVersion,
        'phase': phase,
        'isProposal': isProposal,
        'snapshot': snapshot.toJson(),
        'expectedManifestHashAfter': expectedManifestHashAfter,
        'expectedRegistryHashAfter': expectedRegistryHashAfter,
        'lifecycle': lifecycle.toJson(),
        'cohortIds': cohortIds,
        'mappings': mappings.toJson(),
        'targetRecords': [for (final record in targetRecords) record.toJson()],
        'targetClaims': [for (final claim in targetClaims) claim.toJson()],
        'backupPlan': backupPlan.toJson(),
        'writePreconditions': writePreconditions.toJson(),
        'atomicityPlan': atomicityPlan.toJson(),
        'rollbackPlan': rollbackPlan.toJson(),
        'pointOfNoReturn': pointOfNoReturn.toJson(),
      };
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

List<NarrativeEventRecord> _sortedRecords(
  List<NarrativeEventRecord> values,
) {
  final sorted = List<NarrativeEventRecord>.of(values)
    ..sort((left, right) => left.id.compareTo(right.id));
  for (var index = 1; index < sorted.length; index++) {
    if (sorted[index - 1].id == sorted[index].id) {
      throw ArgumentError.value(values, 'targetRecords', 'duplicate event ID');
    }
  }
  return List.unmodifiable(sorted);
}

List<LegacySourceClaim> _sortedClaims(List<LegacySourceClaim> values) {
  final sorted = List<LegacySourceClaim>.of(values)
    ..sort((left, right) => left.cohortId.compareTo(right.cohortId));
  for (var index = 1; index < sorted.length; index++) {
    if (sorted[index - 1].cohortId == sorted[index].cohortId) {
      throw ArgumentError.value(values, 'targetClaims', 'duplicate cohort ID');
    }
  }
  return List.unmodifiable(sorted);
}

Map<String, String> _fingerprintMap(
  Map<String, String> values,
  String name,
) {
  final keys = values.keys.toList()..sort();
  return Map.unmodifiable({
    for (final key in keys)
      _identity(key, '$name.key'): _fingerprint(values[key]!, '$name.$key'),
  });
}

Map<String, String> _identityMap(
  Map<String, String> values,
  String name,
) {
  final keys = values.keys.toList()..sort();
  return Map.unmodifiable({
    for (final key in keys)
      _identity(key, '$name.key'): _identity(values[key]!, '$name.$key'),
  });
}

List<String> _sortedUnique(List<String> values, String name) {
  final sorted = values.map((value) => _identity(value, name)).toList()..sort();
  for (var index = 1; index < sorted.length; index++) {
    if (sorted[index - 1] == sorted[index]) {
      throw ArgumentError.value(values, name, 'must not contain duplicates');
    }
  }
  return List.unmodifiable(sorted);
}

List<String> _identityList(List<String> values, String name) =>
    List.unmodifiable([
      for (final value in values) _identity(value, name),
    ]);

String _fingerprint(String value, String name) {
  if (!_fingerprintPattern.hasMatch(value)) {
    throw ArgumentError.value(
      value,
      name,
      'must use sha256:<64 lowercase hex>',
    );
  }
  return value;
}

String _identity(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}

Map<String, Object?> _object(Object? value, String path) {
  if (value is! Map) throw FormatException('$path must be an object.');
  return {
    for (final entry in value.entries) _key(entry.key, path): entry.value,
  };
}

String _key(Object? value, String path) {
  if (value is! String) throw FormatException('$path keys must be strings.');
  return value;
}

List<Object?> _list(Object? value, String path) {
  if (value is! List) throw FormatException('$path must be a list.');
  return List<Object?>.from(value);
}

String _string(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! String) throw FormatException('$key must be a String.');
  return value;
}

int _integer(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! int) throw FormatException('$key must be an int.');
  return value;
}

bool _boolean(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! bool) throw FormatException('$key must be a bool.');
  return value;
}

List<String> _stringList(Object? value, String path) {
  return _list(value, path).map((item) {
    if (item is! String) throw FormatException('$path must contain strings.');
    return item;
  }).toList();
}

Map<String, String> _stringMap(Object? value, String path) {
  final object = _object(value, path);
  return object.map((key, item) {
    if (item is! String) {
      throw FormatException('$path.$key must be a String.');
    }
    return MapEntry(key, item);
  });
}

DateTime _dateTime(Map<String, Object?> object, String key) {
  final value = _string(object, key);
  return _parseDateTime(value, key);
}

DateTime? _optionalDateTime(Object? value, String path) {
  if (value == null) return null;
  if (value is! String) throw FormatException('$path must be a String.');
  return _parseDateTime(value, path);
}

DateTime _parseDateTime(String value, String path) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc) {
    throw FormatException('$path must be an ISO-8601 UTC timestamp.');
  }
  return parsed;
}

T _enumByName<T extends Enum>(List<T> values, String name, String path) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('$path has unsupported value "$name".');
}
