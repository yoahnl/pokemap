part of 'narrative_event_migration_plan.dart';

abstract interface class NarrativeEventMigrationIdSource {
  String nextEventId();

  String nextReceiptId();
}

typedef NarrativeEventMigrationClock = DateTime Function();

final class NarrativeEventMigrationPlanner {
  NarrativeEventMigrationPlanner({
    required NarrativeEventMigrationIdSource ids,
    required NarrativeEventMigrationClock clock,
  })  : _ids = ids,
        _clock = clock;

  final NarrativeEventMigrationIdSource _ids;
  final NarrativeEventMigrationClock _clock;

  NarrativeEventMigrationPlan plan(
    NarrativeEventMigrationPlannerInput input,
  ) {
    final writePreconditions = NarrativeEventMigrationWritePreconditions(
      snapshot: input.currentSnapshot,
    );
    final rollbackPlan = NarrativeEventMigrationRollbackPlan.phaseCProposal();
    final pointOfNoReturn =
        NarrativeEventMigrationPointOfNoReturn.phaseCProposal();
    final unknownData = List<NarrativeEventUnknownLegacyData>.of(
      input.unknownLegacyData,
    )..sort((left, right) => left.path.compareTo(right.path));
    final existingReceiptResult = input.existingReceiptJsonBytes == null
        ? null
        : decodeNarrativeEventMigrationReceiptStrict(
            input.existingReceiptJsonBytes!,
          );
    final existingReceipt = existingReceiptResult?.receiptOrNull;
    final effectiveChoices = _effectiveMigrationChoices(
      input,
      existingReceipt,
    );
    final candidates = _buildCandidates(input, effectiveChoices)
      ..sort(_compareCandidates);
    final diagnostics = <LegacyMigrationDiagnostic>[
      for (final candidate in candidates) ...candidate.diagnostics,
    ];
    final hasCandidateDiagnosticBlock = diagnostics.any(
      (diagnostic) =>
          diagnostic.severity == LegacyMigrationDiagnosticSeverity.error,
    );

    if (existingReceiptResult != null && existingReceipt == null) {
      diagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes.receiptStrictDecodeFailed,
          LegacyMigrationDiagnosticSeverity.error,
          'The existing migration receipt must be supplied as its original '
              'strictly decodable wire bytes.',
          'existingReceiptJsonBytes',
        ),
      );
      return _planWithoutIds(
        input: input,
        candidates: candidates,
        diagnostics: diagnostics,
        writePreconditions: writePreconditions,
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
        unknownData: unknownData,
      );
    }

    if (_hasCorpusEvidenceMismatch(input, candidates, diagnostics)) {
      return _planWithoutIds(
        input: input,
        candidates: candidates,
        diagnostics: diagnostics,
        writePreconditions: writePreconditions,
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
        unknownData: unknownData,
      );
    }

    final isEmpty = input.mapEventProjections.isEmpty &&
        input.scenarioProjections.isEmpty &&
        input.references.isEmpty &&
        unknownData.isEmpty &&
        input.choices.sourceChoices.isEmpty &&
        input.choices.referenceChoices.isEmpty &&
        (input.project.eventRegistry?.legacyClaims.isEmpty ?? true) &&
        input.existingReceiptJsonBytes == null;
    if (isEmpty) {
      return NarrativeEventMigrationPlan(
        status: NarrativeEventMigrationPlanStatus.empty,
        recordsProposed: const [],
        claimsProposed: const [],
        cohorts: const [],
        items: const [],
        mappings: NarrativeEventReferenceMappings(),
        diagnostics: const [],
        writePreconditions: writePreconditions,
        backupPlan: input.backupPlan,
        receiptProposal: null,
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
        unknownLegacyData: const [],
      );
    }

    final expected = input.expectedSnapshot;
    if (expected != null && !expected.sameAs(input.currentSnapshot)) {
      diagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes.staleRevision,
          LegacyMigrationDiagnosticSeverity.error,
          'The migration snapshot no longer matches the expected revision '
              'and hashes.',
          'revisionContext',
        ),
      );
      return _planWithoutIds(
        input: input,
        candidates: candidates,
        diagnostics: diagnostics,
        writePreconditions: writePreconditions,
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
        unknownData: unknownData,
      );
    }

    final validationCatalog = input.validationCatalog;
    if (validationCatalog == null) {
      diagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes.validationCatalogMissing,
          LegacyMigrationDiagnosticSeverity.error,
          'A complete project catalog is required before migration can be '
              'prepared.',
          'validationCatalog',
        ),
      );
      return _planWithoutIds(
        input: input,
        candidates: candidates,
        diagnostics: diagnostics,
        writePreconditions: writePreconditions,
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
        unknownData: unknownData,
      );
    }

    if (_validateCatalogContext(
      input: input,
      candidates: candidates,
      catalog: validationCatalog,
      diagnostics: diagnostics,
    )) {
      return _planWithoutIds(
        input: input,
        candidates: candidates,
        diagnostics: diagnostics,
        writePreconditions: writePreconditions,
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
        unknownData: unknownData,
      );
    }

    var hasHardBlock = hasCandidateDiagnosticBlock;
    if (_appendProjectCatalogDiagnostics(
      validationCatalog,
      diagnostics,
    )) {
      hasHardBlock = true;
    }
    if (_recordUnusedChoices(
      input,
      candidates,
      diagnostics,
    )) {
      hasHardBlock = true;
    }
    if (_validateContextualIntegrity(
      candidates: candidates,
      catalog: validationCatalog,
      diagnostics: diagnostics,
    )) {
      hasHardBlock = true;
    }
    if (_validateProposedRecordClosure(
      candidates: candidates,
      catalog: validationCatalog,
      diagnostics: diagnostics,
    )) {
      hasHardBlock = true;
    }
    var hasSnapshotBlock = false;
    var assistancePending = false;

    final concernedMapIds = <String>{
      for (final map in input.maps) map.id,
    };
    for (final candidate in candidates) {
      candidate.provenance.when(
        mapEvent: (mapId, _) => concernedMapIds.add(mapId),
        scenarioSourceNode: (_, __) {},
      );
      candidate.source?.when(
        entityInteract: (mapId, _) => concernedMapIds.add(mapId),
        triggerEnter: (mapId, _) => concernedMapIds.add(mapId),
        mapEnter: concernedMapIds.add,
        outcomeReceived: (_) {},
      );
    }
    final sortedConcernedMapIds = concernedMapIds.toList()..sort();
    for (final mapId in sortedConcernedMapIds) {
      if (!input.currentSnapshot.mapHashes.containsKey(mapId)) {
        hasHardBlock = true;
        hasSnapshotBlock = true;
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.sourceHashMismatch,
            LegacyMigrationDiagnosticSeverity.error,
            'A concerned map is missing from the hash preconditions.',
            'mapHashes.$mapId',
          ),
        );
      }
    }

    for (final candidate in candidates) {
      final snapshotKey =
          legacyMigrationSourceSnapshotKey(candidate.provenance);
      final snapshotFingerprint =
          input.currentSnapshot.legacySourceHashes[snapshotKey];
      if (snapshotFingerprint != candidate.sourceFingerprint) {
        candidate.hardBlocked = true;
        hasHardBlock = true;
        hasSnapshotBlock = true;
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.sourceHashMismatch,
            LegacyMigrationDiagnosticSeverity.error,
            'The legacy source fingerprint is absent or stale in the '
                'revision context.',
            'legacySourceHashes.$snapshotKey',
          ),
        );
      }
      if (candidate.hardBlocked) hasHardBlock = true;
      _addClassificationDiagnostic(candidate, diagnostics);
    }

    if (unknownData.isNotEmpty) {
      hasHardBlock = true;
      hasSnapshotBlock = true;
      for (final unknown in unknownData) {
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.unknownLegacyData,
            LegacyMigrationDiagnosticSeverity.error,
            'Unknown legacy data is preserved in the preview and blocks '
            'migration until it is understood.',
            unknown.path,
          ),
        );
      }
    }

    if (hasSnapshotBlock) {
      return _planWithoutIds(
        input: input,
        candidates: candidates,
        diagnostics: diagnostics,
        writePreconditions: writePreconditions,
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
        unknownData: unknownData,
      );
    }

    final duplicateProvenances = <LegacySourceRef, List<_Candidate>>{};
    for (final candidate in candidates) {
      duplicateProvenances
          .putIfAbsent(candidate.provenance, () => [])
          .add(candidate);
    }
    for (final entry in duplicateProvenances.entries) {
      if (entry.value.length < 2) continue;
      hasHardBlock = true;
      for (final candidate in entry.value) {
        candidate.hardBlocked = true;
      }
      diagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes.incompleteCohort,
          LegacyMigrationDiagnosticSeverity.error,
          'The same legacy provenance was projected more than once.',
          _provenancePath(entry.key),
        ),
      );
    }

    final groups = _buildGroups(candidates);
    final registry = input.project.eventRegistry;
    if (registry != null) {
      final claimIndex = buildValidatedLegacyClaimIndex(registry);
      if (claimIndex.globalConflicts.isNotEmpty) {
        hasHardBlock = true;
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.invalidExistingClaim,
            LegacyMigrationDiagnosticSeverity.error,
            'The existing registry has global claim conflicts.',
            'eventRegistry.legacyClaims',
          ),
        );
        for (final group in groups) {
          group.hardBlocked = true;
          for (final candidate in group.candidates) {
            candidate.hardBlocked = true;
          }
        }
      }
    }

    for (final group in groups) {
      _resolveExistingClaim(
        group,
        registry,
        existingReceipt,
        diagnostics,
      );
      if (_validateExistingClaimContext(
        group: group,
        catalog: validationCatalog,
        diagnostics: diagnostics,
      )) {
        hasHardBlock = true;
      }
      if (group.hardBlocked) hasHardBlock = true;
      final groupNeedsAssistance =
          group.candidates.any((candidate) => candidate.assistancePending);
      if (group.existingClaim == null &&
          !group.canProposeClaim &&
          !groupNeedsAssistance &&
          !group.hardBlocked) {
        group.hardBlocked = true;
        for (final candidate in group.candidates) {
          candidate.hardBlocked = true;
        }
        hasHardBlock = true;
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.incompleteCohort,
            LegacyMigrationDiagnosticSeverity.error,
            'The complete source cohort cannot be represented by configured '
                'V2 target records.',
            'cohorts.${group.cohortId}',
          ),
        );
      }
    }

    NarrativeEventMigrationReceipt? reusedReceipt;
    final existingClaims = [
      for (final group in groups)
        if (group.existingClaim != null) group.existingClaim!,
    ];
    if (registry != null) {
      final exactClaimKeys = {
        for (final claim in existingClaims)
          canonicalizeNarrativeEventJson(claim.toJson()),
      };
      final orphanClaims = [
        for (final claim in registry.legacyClaims)
          if (!exactClaimKeys.contains(
            canonicalizeNarrativeEventJson(claim.toJson()),
          ))
            claim,
      ];
      if (orphanClaims.isNotEmpty) {
        hasHardBlock = true;
        for (final claim in orphanClaims) {
          diagnostics.add(
            _diagnostic(
              NarrativeEventMigrationDiagnosticCodes.invalidExistingClaim,
              LegacyMigrationDiagnosticSeverity.error,
              'An existing legacy claim has no exact characterized source '
                  'cohort in this plan.',
              'eventRegistry.legacyClaims.${claim.cohortId}',
            ),
          );
        }
      }
    }
    if (existingClaims.isNotEmpty) {
      if (existingReceipt != null &&
          _matchesAppliedReceipt(
            input: input,
            registry: registry!,
            candidates: candidates,
            existingClaims: existingClaims,
            receipt: existingReceipt,
          )) {
        reusedReceipt = existingReceipt;
      } else {
        hasHardBlock = true;
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.existingReceiptMismatch,
            LegacyMigrationDiagnosticSeverity.error,
            'Existing claims require their exact receipt, target records, and '
                'applied-state fingerprints.',
            'existingReceipt',
          ),
        );
      }
    } else if (existingReceipt != null) {
      hasHardBlock = true;
      diagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes.existingReceiptMismatch,
          LegacyMigrationDiagnosticSeverity.error,
          'The supplied receipt does not belong to any exact existing claim.',
          'existingReceipt',
        ),
      );
    }
    if (existingClaims.isNotEmpty &&
        groups.any((group) => group.existingClaim == null)) {
      hasHardBlock = true;
      diagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes
              .incrementalReceiptHistoryRequired,
          LegacyMigrationDiagnosticSeverity.error,
          'Phase C V0 cannot append cohorts to an existing prepared receipt '
              'without an explicit receipt-history model.',
          'existingReceipt',
        ),
      );
    }

    final preflightMappings = _buildReferencePreflightMappings(
      input: input,
      candidates: candidates,
      pageMappings: _buildPageMappings(candidates),
      existingReceipt: existingReceipt,
    );
    if (preflightMappings.hasBlockingMappings) {
      hasHardBlock = true;
      _recordBlockingReferenceDiagnostics(
        preflightMappings,
        diagnostics,
      );
    }

    if (hasHardBlock) {
      return _planWithoutIds(
        input: input,
        candidates: candidates,
        groups: groups,
        mappings: preflightMappings,
        diagnostics: diagnostics,
        writePreconditions: writePreconditions,
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
        unknownData: unknownData,
      );
    }

    final draftCandidates = [
      for (final candidate in candidates)
        if (candidate.assistancePending &&
            !candidate.resolved &&
            !candidate.hardBlocked &&
            candidate.targets.isNotEmpty)
          candidate,
    ];
    final usedEventIds = <String>{
      if (registry != null)
        for (final record in registry.records) record.id,
      for (final record in validationCatalog.proposedRecords) record.id,
    };
    assistancePending = draftCandidates.isNotEmpty;
    if (assistancePending) {
      final drafts = <NarrativeEventRecord>[];
      for (final candidate in draftCandidates) {
        _proposeDrafts(
          candidate: candidate,
          usedEventIds: usedEventIds,
          records: drafts,
        );
      }
      final idMappings = _buildIdMappings(candidates);
      final mappings = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: const {},
        targetEventIdsByTargetKey: _buildTargetIdsByKey(candidates),
        references: input.references,
        choices: _effectiveReferenceChoices(input, existingReceipt),
        idMappings: idMappings,
        pageMappings: _buildPageMappings(candidates),
      );
      if (mappings.hasBlockingMappings) {
        throw StateError(
          'Assistance mapping diverged from the no-ID preflight.',
        );
      }
      _sortDiagnostics(diagnostics);
      return NarrativeEventMigrationPlan(
        status: NarrativeEventMigrationPlanStatus.assistanceRequired,
        recordsProposed: drafts,
        claimsProposed: const [],
        cohorts: [for (final group in groups) group.toPublic()],
        items: [for (final candidate in candidates) candidate.toPublic()],
        mappings: mappings,
        diagnostics: diagnostics,
        writePreconditions: writePreconditions,
        backupPlan: input.backupPlan,
        receiptProposal: null,
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
        unknownLegacyData: unknownData,
      );
    }

    final groupsToPropose = [
      for (final group in groups)
        if (group.existingClaim == null &&
            group.canProposeClaim &&
            !group.hardBlocked)
          group,
    ];
    if (groupsToPropose.isNotEmpty &&
        _generatedReceiptFailsStrictPreflight(
          input: input,
          candidates: candidates,
          groupsToPropose: groupsToPropose,
          catalog: validationCatalog,
          registry: registry,
          existingReceipt: existingReceipt,
          writePreconditions: writePreconditions,
          rollbackPlan: rollbackPlan,
          pointOfNoReturn: pointOfNoReturn,
          diagnostics: diagnostics,
        )) {
      return _planWithoutIds(
        input: input,
        candidates: candidates,
        groups: groups,
        mappings: preflightMappings,
        diagnostics: diagnostics,
        writePreconditions: writePreconditions,
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
        unknownData: unknownData,
      );
    }
    final receiptId = groupsToPropose.isNotEmpty ? _nextReceiptId() : null;
    final recordsProposed = <NarrativeEventRecord>[];
    final claimsProposed = <LegacySourceClaim>[];
    final reservedRecordsBySignature = {
      for (final record in validationCatalog.proposedRecords)
        _recordSignature(record): record,
    };

    for (final group in groupsToPropose) {
      _proposeGroup(
        group: group,
        receiptId: receiptId!,
        usedEventIds: usedEventIds,
        records: recordsProposed,
        claims: claimsProposed,
        reservedRecordsBySignature: reservedRecordsBySignature,
        allocateEventId: _nextEventId,
      );
    }

    final idMappings = _buildIdMappings(candidates);
    final targetIdsByProvenance = <LegacySourceRef, List<String>>{};
    for (final candidate in candidates) {
      if (candidate.resolved && candidate.targetEventIds.isNotEmpty) {
        targetIdsByProvenance[candidate.provenance] = candidate.targetEventIds;
      }
    }

    final pageMappings = _buildPageMappings(candidates);
    final mappings = buildNarrativeEventReferenceMappings(
      targetEventIdsByProvenance: targetIdsByProvenance,
      targetEventIdsByTargetKey: _buildTargetIdsByKey(candidates),
      references: input.references,
      choices: _effectiveReferenceChoices(input, existingReceipt),
      idMappings: idMappings,
      pageMappings: pageMappings,
    );
    if (mappings.hasBlockingMappings) {
      throw StateError(
        'Reference allocation diverged from the no-ID preflight.',
      );
    }

    final cohortResults = <NarrativeEventMigrationCohort>[
      for (final group in groups) group.toPublic(),
    ];
    final items = <NarrativeEventMigrationItem>[
      for (final candidate in candidates) candidate.toPublic(),
    ];
    _sortDiagnostics(diagnostics);

    final status = groupsToPropose.isEmpty
        ? NarrativeEventMigrationPlanStatus.alreadyPrepared
        : NarrativeEventMigrationPlanStatus.ready;

    NarrativeEventMigrationReceipt? receiptProposal = reusedReceipt;
    _NarrativeEventMigrationContextAttestation? contextAttestation;
    if (status == NarrativeEventMigrationPlanStatus.ready) {
      final finalCatalog = buildNarrativeEventProjectCatalog(
        project: input.project,
        maps: input.maps,
        legacyProjections: input.mapEventProjections,
        referencedOutcomes: _candidateOutcomeReferences(candidates),
        proposedRecords: recordsProposed,
      );
      contextAttestation = _NarrativeEventMigrationContextAttestation.validate(
        catalog: finalCatalog,
        snapshot: input.currentSnapshot,
        proposedRecords: recordsProposed,
      );
      final registryAfter = _registryWithProposals(
        registry,
        recordsProposed,
        claimsProposed,
      );
      final manifestAfter = input.project.copyWith(
        eventRegistry: registryAfter,
      );
      receiptProposal = NarrativeEventMigrationReceipt(
        receiptId: receiptId!,
        isProposal: true,
        snapshot: input.currentSnapshot,
        expectedManifestHashAfter: _jsonFingerprint(manifestAfter.toJson()),
        expectedRegistryHashAfter: _jsonFingerprint(registryAfter.toJson()),
        lifecycle: NarrativeEventMigrationReceiptLifecycle.prepared(_clock()),
        cohortIds: [for (final claim in claimsProposed) claim.cohortId],
        mappings: mappings,
        sourceChoices: [
          for (final candidate in candidates)
            if (candidate.choiceApplied &&
                claimsProposed.any(
                  (claim) => claim.members.any(
                    (member) => member.provenance == candidate.provenance,
                  ),
                ))
              candidate.sourceChoice!,
        ],
        targetRecords: recordsProposed,
        targetClaims: claimsProposed,
        backupPlan: input.backupPlan,
        writePreconditions: writePreconditions,
        atomicityPlan: NarrativeEventMigrationAtomicityPlan.phaseCProposal(),
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
      );
      final targetEnabled = recordsProposed.any(
        (record) => record.when(
          draft: (_) => false,
          configured: (_, enabled) => enabled,
        ),
      );
      final strictReceipt = decodeNarrativeEventMigrationReceiptStrict(
        utf8.encode(jsonEncode(receiptProposal.toJson())),
      );
      if (targetEnabled || strictReceipt.receiptOrNull == null) {
        throw StateError(
          'Generated receipt diverged from its side-effect-free strict '
          'preflight.',
        );
      }
    }

    if (status == NarrativeEventMigrationPlanStatus.ready) {
      return NarrativeEventMigrationPlan._contextValidated(
        status: status,
        recordsProposed: recordsProposed,
        claimsProposed: claimsProposed,
        cohorts: cohortResults,
        items: items,
        mappings: mappings,
        diagnostics: diagnostics,
        writePreconditions: writePreconditions,
        backupPlan: input.backupPlan,
        receiptProposal: receiptProposal!,
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
        unknownLegacyData: unknownData,
        contextAttestation: contextAttestation!,
      );
    }
    return NarrativeEventMigrationPlan(
      status: status,
      recordsProposed: recordsProposed,
      claimsProposed: claimsProposed,
      cohorts: cohortResults,
      items: items,
      mappings: mappings,
      diagnostics: diagnostics,
      writePreconditions: writePreconditions,
      backupPlan: input.backupPlan,
      receiptProposal: receiptProposal,
      rollbackPlan: rollbackPlan,
      pointOfNoReturn: pointOfNoReturn,
      unknownLegacyData: unknownData,
    );
  }

  NarrativeEventMigrationPlan _planWithoutIds({
    required NarrativeEventMigrationPlannerInput input,
    required List<_Candidate> candidates,
    List<_Group> groups = const [],
    NarrativeEventReferenceMappings? mappings,
    required List<LegacyMigrationDiagnostic> diagnostics,
    required NarrativeEventMigrationWritePreconditions writePreconditions,
    required NarrativeEventMigrationRollbackPlan rollbackPlan,
    required NarrativeEventMigrationPointOfNoReturn pointOfNoReturn,
    required List<NarrativeEventUnknownLegacyData> unknownData,
  }) {
    for (final candidate in candidates) {
      if (candidate.sourceChoice != null) candidate.choiceApplied = false;
    }
    _sortDiagnostics(diagnostics);
    return NarrativeEventMigrationPlan(
      status: NarrativeEventMigrationPlanStatus.blocked,
      recordsProposed: const [],
      claimsProposed: const [],
      cohorts: [for (final group in groups) group.toPublic()],
      items: [for (final candidate in candidates) candidate.toPublic()],
      mappings: mappings ??
          NarrativeEventReferenceMappings(
            pageMappings: _buildPageMappings(candidates),
          ),
      diagnostics: diagnostics,
      writePreconditions: writePreconditions,
      backupPlan: input.backupPlan,
      receiptProposal: null,
      rollbackPlan: rollbackPlan,
      pointOfNoReturn: pointOfNoReturn,
      unknownLegacyData: unknownData,
    );
  }

  String _nextReceiptId() {
    final value = _ids.nextReceiptId();
    if (value.isEmpty || value.trim() != value) {
      throw ArgumentError.value(
        value,
        'nextReceiptId',
        'must return a non-empty trimmed ID',
      );
    }
    return value;
  }

  String _nextEventId(Set<String> usedEventIds) {
    for (var attempt = 0; attempt < 17; attempt++) {
      final value = _ids.nextEventId();
      if (!narrativeEventIdPattern.hasMatch(value)) {
        throw ArgumentError.value(
          value,
          'nextEventId',
          'must return a canonical Event V2 ID',
        );
      }
      if (usedEventIds.add(value)) return value;
    }
    throw StateError('Event ID generation collided 17 consecutive times.');
  }

  void _proposeGroup({
    required _Group group,
    required String receiptId,
    required Set<String> usedEventIds,
    required List<NarrativeEventRecord> records,
    required List<LegacySourceClaim> claims,
    required Map<String, NarrativeEventRecord> reservedRecordsBySignature,
    required String Function(Set<String>) allocateEventId,
  }) {
    final targetsBySignature =
        <String, NarrativeEventMigrationTargetProposal>{};
    for (final candidate in group.candidates) {
      for (final target in candidate.targets) {
        targetsBySignature.putIfAbsent(
          target.recordSignature(group.source),
          () => target,
        );
      }
    }
    final signatures = targetsBySignature.keys.toList()..sort();
    final eventIdBySignature = <String, String>{};
    for (final signature in signatures) {
      final target = targetsBySignature[signature]!;
      final reserved = reservedRecordsBySignature[signature];
      final eventId = reserved?.id ?? allocateEventId(usedEventIds);
      eventIdBySignature[signature] = eventId;
      if (reserved != null) {
        records.add(reserved);
      } else {
        final definition = NarrativeEventDefinition(
          id: eventId,
          name: target.name,
          source: group.source,
          conditions: target.conditions,
          sceneId: target.sceneId!,
          reusePolicy: target.reusePolicy!,
          priority: target.priority,
          order: target.order,
        );
        records.add(
          NarrativeEventRecord.configuredStructurallyUnchecked(
            definition,
            enabled: false,
          ),
        );
      }
    }
    for (final candidate in group.candidates) {
      for (final target in candidate.targets) {
        final targetId =
            eventIdBySignature[target.recordSignature(group.source)]!;
        candidate.addTarget(target, targetId);
      }
      candidate.resolved = true;
    }
    final targetEventIds = eventIdBySignature.values.toList()..sort();
    final claim = LegacySourceClaim(
      cohortId: group.cohortId,
      source: group.source,
      members: group.members,
      cohortFingerprint: computeLegacySourceCohortFingerprint(
        group.cohortId,
        group.members,
      ),
      targetEventIds: targetEventIds,
      migrationReceiptId: receiptId,
    );
    claims.add(claim);
    group.proposedClaim = claim;
    group.targetEventIds = targetEventIds;
  }

  bool _generatedReceiptFailsStrictPreflight({
    required NarrativeEventMigrationPlannerInput input,
    required List<_Candidate> candidates,
    required List<_Group> groupsToPropose,
    required NarrativeEventProjectCatalog catalog,
    required NarrativeEventRegistry? registry,
    required NarrativeEventMigrationReceipt? existingReceipt,
    required NarrativeEventMigrationWritePreconditions writePreconditions,
    required NarrativeEventMigrationRollbackPlan rollbackPlan,
    required NarrativeEventMigrationPointOfNoReturn pointOfNoReturn,
    required List<LegacyMigrationDiagnostic> diagnostics,
  }) {
    try {
      final simulatedCandidates = [
        for (final candidate in candidates) candidate.copyForPreflight(),
      ]..sort(_compareCandidates);
      final simulatedGroups = _buildGroups(simulatedCandidates);
      final proposedCohortIds = {
        for (final group in groupsToPropose) group.cohortId,
      };
      final simulatedGroupsToPropose = [
        for (final group in simulatedGroups)
          if (proposedCohortIds.contains(group.cohortId)) group,
      ];
      if (simulatedGroupsToPropose.length != groupsToPropose.length) {
        throw StateError('Receipt preflight lost a migration cohort.');
      }

      const simulatedReceiptId = 'evmr_00000000-0000-7000-8000-000000000001';
      final usedEventIds = <String>{
        if (registry != null)
          for (final record in registry.records) record.id,
        for (final record in catalog.proposedRecords) record.id,
      };
      var simulatedIdSequence = 1;
      String allocateSimulatedEventId(Set<String> usedIds) {
        for (var attempt = 0; attempt < 1000000; attempt++) {
          final suffix = (900000000000 + simulatedIdSequence++)
              .toString()
              .padLeft(12, '0');
          final value = 'evt_00000000-0000-7000-8000-$suffix';
          if (usedIds.add(value)) return value;
        }
        throw StateError('Receipt preflight exhausted synthetic Event IDs.');
      }

      final records = <NarrativeEventRecord>[];
      final claims = <LegacySourceClaim>[];
      final reservedRecordsBySignature = {
        for (final record in catalog.proposedRecords)
          _recordSignature(record): record,
      };
      for (final group in simulatedGroupsToPropose) {
        _proposeGroup(
          group: group,
          receiptId: simulatedReceiptId,
          usedEventIds: usedEventIds,
          records: records,
          claims: claims,
          reservedRecordsBySignature: reservedRecordsBySignature,
          allocateEventId: allocateSimulatedEventId,
        );
      }

      final targetIdsByProvenance = <LegacySourceRef, List<String>>{
        for (final candidate in simulatedCandidates)
          if (candidate.resolved && candidate.targetEventIds.isNotEmpty)
            candidate.provenance: candidate.targetEventIds,
      };
      final mappings = buildNarrativeEventReferenceMappings(
        targetEventIdsByProvenance: targetIdsByProvenance,
        targetEventIdsByTargetKey: _buildTargetIdsByKey(simulatedCandidates),
        references: input.references,
        choices: _effectiveReferenceChoices(input, existingReceipt),
        idMappings: _buildIdMappings(simulatedCandidates),
        pageMappings: _buildPageMappings(simulatedCandidates),
      );
      if (mappings.hasBlockingMappings) {
        throw StateError(
          'Receipt mapping preflight diverged from contextual validation.',
        );
      }

      final registryAfter = _registryWithProposals(
        registry,
        records,
        claims,
      );
      final manifestAfter = input.project.copyWith(
        eventRegistry: registryAfter,
      );
      final receipt = NarrativeEventMigrationReceipt(
        receiptId: simulatedReceiptId,
        isProposal: true,
        snapshot: input.currentSnapshot,
        expectedManifestHashAfter: _jsonFingerprint(manifestAfter.toJson()),
        expectedRegistryHashAfter: _jsonFingerprint(registryAfter.toJson()),
        lifecycle: NarrativeEventMigrationReceiptLifecycle.prepared(
          DateTime.utc(2000),
        ),
        cohortIds: [for (final claim in claims) claim.cohortId],
        mappings: mappings,
        sourceChoices: [
          for (final candidate in simulatedCandidates)
            if (candidate.choiceApplied &&
                claims.any(
                  (claim) => claim.members.any(
                    (member) => member.provenance == candidate.provenance,
                  ),
                ))
              candidate.sourceChoice!,
        ],
        targetRecords: records,
        targetClaims: claims,
        backupPlan: input.backupPlan,
        writePreconditions: writePreconditions,
        atomicityPlan: NarrativeEventMigrationAtomicityPlan.phaseCProposal(),
        rollbackPlan: rollbackPlan,
        pointOfNoReturn: pointOfNoReturn,
      );
      final simulatedCatalog = buildNarrativeEventProjectCatalog(
        project: input.project,
        maps: input.maps,
        legacyProjections: input.mapEventProjections,
        referencedOutcomes: _candidateOutcomeReferences(simulatedCandidates),
        proposedRecords: records,
      );
      _NarrativeEventMigrationContextAttestation.validate(
        catalog: simulatedCatalog,
        snapshot: input.currentSnapshot,
        proposedRecords: records,
      );
      final strictReceipt = decodeNarrativeEventMigrationReceiptStrict(
        utf8.encode(jsonEncode(receipt.toJson())),
      );
      if (strictReceipt.receiptOrNull != null) return false;
    } on ArgumentError catch (_) {
      // Converted below into a stable fail-closed migration diagnostic.
    } on StateError catch (_) {
      // Converted below into a stable fail-closed migration diagnostic.
    }
    diagnostics.add(
      _diagnostic(
        NarrativeEventMigrationDiagnosticCodes.receiptStrictDecodeFailed,
        LegacyMigrationDiagnosticSeverity.error,
        'The proposed migration receipt failed its side-effect-free strict '
            'wire preflight.',
        'receiptProposal',
      ),
    );
    return true;
  }

  void _proposeDrafts({
    required _Candidate candidate,
    required Set<String> usedEventIds,
    required List<NarrativeEventRecord> records,
  }) {
    for (final target in candidate.targets) {
      final eventId = _nextEventId(usedEventIds);
      records.add(
        NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: eventId,
            name: target.name,
            source: candidate.source,
            conditions: target.conditions,
            sceneId: target.sceneId,
            reusePolicy: target.reusePolicy,
            priority: target.priority,
            order: target.order,
          ),
        ),
      );
      candidate.addTarget(target, eventId);
    }
  }
}

List<NarrativeEventIdMapping> _buildIdMappings(
  List<_Candidate> candidates,
) {
  final mappings = <NarrativeEventIdMapping>[
    for (final candidate in candidates)
      if (candidate.targetEventIds.isNotEmpty)
        NarrativeEventIdMapping(
          provenance: candidate.provenance,
          legacyId: _legacyId(candidate.provenance),
          targetEventIds: candidate.targetEventIds,
        ),
  ];
  mappings.sort(
    (left, right) => compareLegacySourceRefs(
      left.provenance,
      right.provenance,
    ),
  );
  return mappings;
}

Map<LegacySourceRef, Map<String, String>> _buildTargetIdsByKey(
  List<_Candidate> candidates,
) {
  return {
    for (final candidate in candidates)
      if (candidate.targetEventIdsByKey.isNotEmpty)
        candidate.provenance: Map.unmodifiable(candidate.targetEventIdsByKey),
  };
}

NarrativeEventRegistry _registryWithProposals(
  NarrativeEventRegistry? current,
  List<NarrativeEventRecord> proposedRecords,
  List<LegacySourceClaim> proposedClaims,
) {
  final records = <NarrativeEventRecord>[
    ...?current?.records,
    ...proposedRecords,
  ]..sort((left, right) => left.id.compareTo(right.id));
  final claims = <LegacySourceClaim>[
    ...?current?.legacyClaims,
    ...proposedClaims,
  ]..sort((left, right) => left.cohortId.compareTo(right.cohortId));
  return NarrativeEventRegistry(
    schemaVersion: current?.schemaVersion ?? 1,
    mode: current?.mode ?? EventSystemMode.legacyOnly,
    records: records,
    legacyClaims: claims,
  );
}

bool _hasCorpusEvidenceMismatch(
  NarrativeEventMigrationPlannerInput input,
  List<_Candidate> candidates,
  List<LegacyMigrationDiagnostic> diagnostics,
) {
  var mismatch = false;

  void record(String message, String path) {
    mismatch = true;
    diagnostics.add(
      _diagnostic(
        NarrativeEventMigrationDiagnosticCodes.corpusEvidenceMismatch,
        LegacyMigrationDiagnosticSeverity.error,
        message,
        path,
      ),
    );
  }

  void recordMap(String message, String path) {
    mismatch = true;
    diagnostics.add(
      _diagnostic(
        NarrativeEventMigrationDiagnosticCodes.sourceHashMismatch,
        LegacyMigrationDiagnosticSeverity.error,
        message,
        path,
      ),
    );
  }

  final candidateSourceKeys = <String>{
    for (final candidate in candidates)
      legacyMigrationSourceSnapshotKey(candidate.provenance),
  };
  final snapshotSourceKeys =
      input.currentSnapshot.legacySourceHashes.keys.toSet();
  if (!_sameStrings(candidateSourceKeys, snapshotSourceKeys)) {
    record(
      'The characterized source inventory and supplied projections differ.',
      'legacySourceHashes',
    );
  }

  if (input.currentSnapshot.corpusHash !=
      _jsonFingerprint(input.characterizedCorpus)) {
    record(
      'The characterized corpus hash does not match the supplied corpus.',
      'corpusHash',
    );
  }
  if (input.currentSnapshot.manifestHash !=
      _jsonFingerprint(input.project.toJson())) {
    record(
      'The manifest hash does not match the supplied read-only project.',
      'manifestHash',
    );
  }
  if (input.currentSnapshot.referenceCatalogHash !=
      _jsonFingerprint(input.references.toJson())) {
    record(
      'The reference catalog hash does not match the supplied catalog.',
      'referenceCatalogHash',
    );
  }
  final corpusReferences = input.characterizedCorpus['references'];
  if (corpusReferences == null) {
    if (!input.references.isEmpty) {
      record(
        'A non-empty reference catalog requires the characterized corpus '
            'reference inventory.',
        'characterizedCorpus.references',
      );
    }
  } else {
    if (corpusReferences is! List) {
      record(
        'The characterized corpus references inventory must be a list.',
        'characterizedCorpus.references',
      );
    } else {
      final corpusReferencesByPath = <String, String>{};
      for (var index = 0; index < corpusReferences.length; index++) {
        final value = corpusReferences[index];
        if (value is! Map ||
            value['kind'] is! String ||
            value['path'] is! String ||
            value['rawId'] is! String ||
            value['candidates'] is! List) {
          record(
            'Every characterized reference requires kind, path, rawId, and '
                'candidates.',
            'characterizedCorpus.references[$index]',
          );
          continue;
        }
        final kind = value['kind']! as String;
        final path = value['path']! as String;
        final rawId = value['rawId']! as String;
        final mapIdValue = value['mapId'];
        final candidateValues = value['candidates']! as List;
        final candidates = <String>{};
        var candidatesValid = true;
        for (var candidateIndex = 0;
            candidateIndex < candidateValues.length;
            candidateIndex++) {
          final candidate = candidateValues[candidateIndex];
          if (candidate is! String ||
              candidate.isEmpty ||
              candidate.trim() != candidate ||
              !candidates.add(candidate)) {
            candidatesValid = false;
            record(
              'Characterized reference candidates must be unique, non-empty '
                  'trimmed strings.',
              'characterizedCorpus.references[$index].candidates'
                  '[$candidateIndex]',
            );
          }
        }
        if (kind.isEmpty ||
            kind.trim() != kind ||
            path.isEmpty ||
            path.trim() != path ||
            rawId.isEmpty ||
            rawId.trim() != rawId ||
            (mapIdValue != null &&
                (mapIdValue is! String ||
                    mapIdValue.isEmpty ||
                    mapIdValue.trim() != mapIdValue)) ||
            corpusReferencesByPath.containsKey(path) ||
            !candidatesValid) {
          record(
            'Characterized reference fields must be unique, non-empty, and '
                'trimmed.',
            'characterizedCorpus.references[$index]',
          );
          continue;
        }
        final sortedCandidates = candidates.toList()..sort();
        corpusReferencesByPath[path] = canonicalizeNarrativeEventJson({
          'kind': kind,
          'path': path,
          'rawId': rawId,
          if (mapIdValue != null) 'mapId': mapIdValue,
          'candidates': sortedCandidates,
        });
      }
      final catalogReferencesByPath = {
        for (final reference in input.references.all)
          reference.path: canonicalizeNarrativeEventJson({
            'kind': _corpusReferenceKind(reference.kind),
            'path': reference.path,
            'rawId': reference.legacyEventId,
            if (reference.mapId != null) 'mapId': reference.mapId,
            'candidates': [
              for (final provenance in reference.candidateProvenances)
                _corpusCandidateLabel(provenance),
            ]..sort(),
          }),
      };
      if (!_sameStringMap(
        corpusReferencesByPath,
        catalogReferencesByPath,
      )) {
        record(
          'The reference catalog must exactly cover the characterized corpus '
              'reference inventory, kinds, scopes, and provenances.',
          'characterizedCorpus.references',
        );
      }
    }
  }

  final mapsById = <String, MapData>{};
  for (var index = 0; index < input.maps.length; index++) {
    final map = input.maps[index];
    if (mapsById.containsKey(map.id)) {
      recordMap(
        'The supplied read-only maps contain a duplicate map ID.',
        'maps[$index].id',
      );
      continue;
    }
    mapsById[map.id] = map;
  }
  final manifestMapIds = <String>{};
  for (var index = 0; index < input.project.maps.length; index++) {
    final entry = input.project.maps[index];
    if (!manifestMapIds.add(entry.id)) {
      recordMap(
        'The read-only manifest contains a duplicate map ID.',
        'project.maps[$index].id',
      );
    }
  }
  if (!_sameStrings(manifestMapIds, mapsById.keys.toSet())) {
    recordMap(
      'The read-only manifest map inventory does not match the supplied maps.',
      'project.maps',
    );
  }
  if (!_sameStrings(
    mapsById.keys.toSet(),
    input.currentSnapshot.mapHashes.keys.toSet(),
  )) {
    recordMap(
      'The map snapshot inventory does not match the supplied read-only maps.',
      'mapHashes',
    );
  }
  for (final entry in mapsById.entries) {
    if (input.currentSnapshot.mapHashes[entry.key] !=
        _jsonFingerprint(entry.value.toJson())) {
      recordMap(
        'A supplied read-only map does not match its snapshot hash.',
        'mapHashes.${entry.key}',
      );
    }
  }
  final scenesById = <String, List<SceneAsset>>{};
  for (var index = 0; index < input.project.scenes.length; index++) {
    final scene = input.project.scenes[index];
    scenesById.putIfAbsent(scene.id, () => []).add(scene);
  }
  for (final entry in scenesById.entries) {
    if (entry.value.length > 1) {
      recordMap(
        'The read-only manifest contains a duplicate Scene ID.',
        'project.scenes.${entry.key}',
      );
    }
  }
  final claimIndex = buildValidatedLegacyClaimIndex(
    input.project.eventRegistry ??
        NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          records: const [],
          legacyClaims: const [],
        ),
  );
  final mapSourceInventory = <String>{
    for (final map in input.maps)
      for (final event in map.events)
        legacyMigrationSourceSnapshotKey(
          LegacySourceRef.mapEvent(map.id, event.id),
        ),
  };
  final projectedMapSources = <String>{
    for (final candidate in candidates)
      if (_isMapProvenance(candidate.provenance))
        legacyMigrationSourceSnapshotKey(candidate.provenance),
  };
  if (!_sameStrings(mapSourceInventory, projectedMapSources)) {
    record(
      'Every MapEvent in the supplied maps must have exactly one projection.',
      'mapEventProjections',
    );
  }
  for (final candidate in candidates) {
    candidate.provenance.when(
      mapEvent: (mapId, eventId) {
        final matches = mapsById[mapId]
                ?.events
                .where((event) => event.id == eventId)
                .toList(growable: false) ??
            const [];
        if (matches.length != 1 ||
            computeMapEventSourceFingerprint(
                  mapId: mapId,
                  event: matches.single,
                ) !=
                candidate.sourceFingerprint) {
          recordMap(
            'The MapEvent projection fingerprint does not match its '
            'read-only source.',
            _provenancePath(candidate.provenance),
          );
        } else {
          final supplied = candidate.mapProjection!;
          final canonical = projectLegacyMapEventReadOnly(
            mapId: mapId,
            map: mapsById[mapId]!,
            event: matches.single,
            claimIndex: claimIndex,
            linkedReferences: supplied.linkedReferences,
            rawEventJson: supplied.preservedEventJson,
          );
          if (!_preservedMapEventMatchesSource(
                supplied.preservedEventJson,
                matches.single,
              ) ||
              !_sameMapProjectionEvidence(canonical, supplied)) {
            candidate.hardBlocked = true;
            diagnostics.add(
              _diagnostic(
                NarrativeEventMigrationDiagnosticCodes
                    .projectionEvidenceMismatch,
                LegacyMigrationDiagnosticSeverity.error,
                'The MapEvent projection must exactly match a canonical '
                'read-only projection of the current source.',
                _provenancePath(candidate.provenance),
              ),
            );
          }
        }
        for (final target in candidate.targets) {
          final sceneId = target.sceneId;
          if (sceneId == null) continue;
          final matches = scenesById[sceneId] ?? const <SceneAsset>[];
          if (matches.length != 1 ||
              !buildSceneRuntimePlan(matches.single).canBuild) {
            recordMap(
              'The MapEvent target Scene is absent, duplicated, or not '
                  'buildable in the read-only manifest.',
              'scenes.$sceneId',
            );
          }
        }
      },
      scenarioSourceNode: (_, __) {},
    );
  }

  final scenariosById = <String, List<ScenarioAsset>>{};
  for (var index = 0; index < input.project.scenarios.length; index++) {
    final scenario = input.project.scenarios[index];
    scenariosById.putIfAbsent(scenario.id, () => []).add(scenario);
  }
  for (final entry in scenariosById.entries) {
    if (entry.value.length > 1) {
      recordMap(
        'The read-only manifest contains a duplicate Scenario ID.',
        'project.scenarios.${entry.key}',
      );
    }
  }
  final scenarioSourceInventory = <String>{
    for (final scenario in input.project.scenarios)
      for (final node in scenario.nodes)
        if (_isLegacyScenarioSourceNode(node.payload.actionKind))
          legacyMigrationSourceSnapshotKey(
            LegacySourceRef.scenarioSourceNode(scenario.id, node.id),
          ),
  };
  final projectedScenarioSources = <String>{
    for (final candidate in candidates)
      if (_isScenarioProvenance(candidate.provenance))
        legacyMigrationSourceSnapshotKey(candidate.provenance),
  };
  if (!_sameStrings(scenarioSourceInventory, projectedScenarioSources)) {
    record(
      'Every Scenario source node in the manifest must have exactly one '
          'projection.',
      'scenarioProjections',
    );
  }
  for (final candidate in candidates) {
    candidate.provenance.when(
      mapEvent: (_, __) {},
      scenarioSourceNode: (scenarioId, nodeId) {
        final scenarioMatches =
            scenariosById[scenarioId] ?? const <ScenarioAsset>[];
        final scenario =
            scenarioMatches.length == 1 ? scenarioMatches.single : null;
        final projection = candidate.scenarioProjection;
        final matchingNodes = scenario?.nodes
                .where((node) => node.id == nodeId)
                .toList(growable: false) ??
            const [];
        if (scenario == null ||
            matchingNodes.length != 1 ||
            computeScenarioSourceFingerprint(
                  scenarioId: scenarioId,
                  nodeId: nodeId,
                  scenario: scenario,
                ) !=
                candidate.sourceFingerprint) {
          recordMap(
            'The Scenario projection fingerprint does not match its '
            'read-only source.',
            _provenancePath(candidate.provenance),
          );
        } else {
          final supplied = projection!;
          final canonical = projectLegacyScenarioSourceReadOnly(
            scenario: scenario,
            node: matchingNodes.single,
            scenes: input.project.scenes,
            claimIndex: claimIndex,
            lifecycleEvidence: supplied.lifecycleEvidence,
          );
          if (!_sameScenarioProjectionEvidence(canonical, supplied)) {
            candidate.hardBlocked = true;
            diagnostics.add(
              _diagnostic(
                NarrativeEventMigrationDiagnosticCodes
                    .projectionEvidenceMismatch,
                LegacyMigrationDiagnosticSeverity.error,
                'The Scenario projection must exactly match a canonical '
                'read-only projection of the current source.',
                _provenancePath(candidate.provenance),
              ),
            );
          }
        }
        final choice = input.choices.sourceChoiceFor(candidate.provenance);
        if (scenario != null &&
            projection?.classification ==
                LegacyMigrationClassification.assisted &&
            choice != null &&
            ((choice.kind !=
                        NarrativeEventMigrationSourceChoiceKind
                            .explicitReassignment &&
                    !isCompatibleLegacyScenarioSourceChoice(
                      projection: projection!,
                      scenario: scenario,
                      selectedSource: choice.source,
                    )) ||
                !_scenarioAssistedChoiceMatchesProjection(
                  projection!,
                  choice,
                ))) {
          record(
            'The assisted Scenario choice changes Event semantics outside '
                'the characterized projection or confirms an incompatible '
                'candidate source.',
            '${_provenancePath(candidate.provenance)}.choice',
          );
        }
        if (projection?.classification ==
                LegacyMigrationClassification.autoSafe &&
            candidate.targets.isEmpty) {
          recordMap(
            'An AUTO_SAFE Scenario projection requires a currently proven '
                'Scene candidate.',
            '${_provenancePath(candidate.provenance)}.sceneCandidateId',
          );
        }
        for (final target in candidate.targets) {
          final sceneId = target.sceneId;
          if (sceneId == null) {
            if (target.isConfigured) {
              recordMap(
                'A configured Scenario migration target requires a Scene.',
                '${_provenancePath(candidate.provenance)}.targets',
              );
            }
            continue;
          }
          final matchingScenes = scenesById[sceneId] ?? const <SceneAsset>[];
          if (scenario == null ||
              matchingScenes.length != 1 ||
              !hasEquivalentLegacyScenarioSceneCandidate(
                scenario: scenario,
                sourceNodeId: nodeId,
                scene: matchingScenes.single,
              )) {
            recordMap(
              'The Scenario target Scene is absent, not buildable, or no '
                  'longer trace-equivalent in the read-only manifest.',
              'scenes.$sceneId',
            );
          }
        }
      },
    );
  }

  final saveHashes = <String, String>{};
  final referencesByPath = {
    for (final reference in input.references.all) reference.path: reference,
  };
  for (var index = 0; index < input.saveSnapshots.length; index++) {
    final snapshot = input.saveSnapshots[index];
    final saveId = snapshot['saveId'];
    if (saveId is! String || saveId.isEmpty || saveId.trim() != saveId) {
      record(
        'Every save snapshot requires a non-empty trimmed saveId.',
        'saveSnapshots[$index].saveId',
      );
      continue;
    }
    if (saveHashes.containsKey(saveId)) {
      record(
        'Save snapshot IDs must be unique.',
        'saveSnapshots[$index].saveId',
      );
      continue;
    }
    saveHashes[saveId] = _jsonFingerprint(snapshot);
    final consumedEventIds = snapshot['consumedEventIds'];
    if (consumedEventIds == null) continue;
    if (consumedEventIds is! List) {
      record(
        'consumedEventIds must remain a characterized list when present.',
        'saveSnapshots[$index].consumedEventIds',
      );
      continue;
    }
    for (var eventIndex = 0;
        eventIndex < consumedEventIds.length;
        eventIndex++) {
      final legacyEventId = consumedEventIds[eventIndex];
      final path = 'gameStates.$saveId.consumedEventIds[$eventIndex]';
      final reference = referencesByPath[path];
      if (legacyEventId is! String ||
          legacyEventId.isEmpty ||
          legacyEventId.trim() != legacyEventId ||
          reference == null ||
          reference.kind != LegacyEventReferenceKind.consumedEventState ||
          reference.legacyEventId != legacyEventId) {
        record(
          'Every consumed Event save entry requires an exact catalogued '
          'legacy reference.',
          path,
        );
      }
    }
  }
  if (!_sameStringMap(saveHashes, input.currentSnapshot.saveHashes)) {
    record(
      'The save snapshot hashes do not match the supplied saves.',
      'saveHashes',
    );
  }
  return mismatch;
}

bool _preservedMapEventMatchesSource(
  Map<String, Object?> preservedEventJson,
  MapEventDefinition source,
) {
  try {
    final position = preservedEventJson['position'];
    final pages = preservedEventJson['pages'];
    if (position is! Map<String, Object?> ||
        position['x'] is! int ||
        position['y'] is! int ||
        pages is! List<Object?> ||
        pages.any(
          (page) => page is! Map<String, Object?> || page['pageNumber'] is! int,
        )) {
      return false;
    }
    final decoded = MapEventDefinition.fromJson(
      Map<String, dynamic>.from(preservedEventJson),
    );
    return canonicalizeNarrativeEventJson(decoded.toJson()) ==
        canonicalizeNarrativeEventJson(source.toJson());
  } on Object {
    return false;
  }
}

bool _sameMapProjectionEvidence(
  LegacyMapEventProjection canonical,
  LegacyMapEventProjection supplied,
) {
  final left = Map<String, Object?>.of(canonical.toJson());
  final right = Map<String, Object?>.of(supplied.toJson());
  for (final field in const {
    'claimStatus',
    'existingClaim',
    'linkedReferences',
    'diagnostics',
    'manualActions',
  }) {
    left.remove(field);
    right.remove(field);
  }
  return canonicalizeNarrativeEventJson(left) ==
      canonicalizeNarrativeEventJson(right);
}

bool _sameScenarioProjectionEvidence(
  LegacyScenarioSourceProjection canonical,
  LegacyScenarioSourceProjection supplied,
) {
  final left = Map<String, Object?>.of(canonical.toJson());
  final right = Map<String, Object?>.of(supplied.toJson());
  for (final field in const {
    'claimStatus',
    'existingClaim',
    'diagnostics',
    'manualActions',
  }) {
    left.remove(field);
    right.remove(field);
  }
  return canonicalizeNarrativeEventJson(left) ==
      canonicalizeNarrativeEventJson(right);
}

bool _recordUnusedChoices(
  NarrativeEventMigrationPlannerInput input,
  List<_Candidate> candidates,
  List<LegacyMigrationDiagnostic> diagnostics,
) {
  var invalid = false;
  final candidateProvenances = {
    for (final candidate in candidates) candidate.provenance,
  };
  for (final choice in input.choices.sourceChoices) {
    if (candidateProvenances.contains(choice.provenance)) continue;
    invalid = true;
    diagnostics.add(
      _diagnostic(
        NarrativeEventMigrationDiagnosticCodes.unusedChoice,
        LegacyMigrationDiagnosticSeverity.error,
        'The source choice does not match any supplied legacy projection.',
        _provenancePath(choice.provenance),
      ),
    );
  }

  final referencePaths = {
    for (final reference in input.references.all) reference.path,
  };
  for (final choice in input.choices.referenceChoices) {
    if (referencePaths.contains(choice.path)) continue;
    invalid = true;
    diagnostics.add(
      _diagnostic(
        NarrativeEventMigrationDiagnosticCodes.unusedChoice,
        LegacyMigrationDiagnosticSeverity.error,
        'The reference choice does not match the supplied reference catalog.',
        choice.path,
      ),
    );
  }
  return invalid;
}

String _jsonFingerprint(Object? value) =>
    'sha256:${narrativeEventCanonicalSha256(jsonDecode(jsonEncode(value)))}';

bool _sameStrings(Set<String> left, Set<String> right) {
  return left.length == right.length && left.containsAll(right);
}

bool _sameStringMap(Map<String, String> left, Map<String, String> right) {
  return left.length == right.length &&
      left.entries.every((entry) => right[entry.key] == entry.value);
}

bool _isMapProvenance(LegacySourceRef provenance) {
  return provenance.when(
    mapEvent: (_, __) => true,
    scenarioSourceNode: (_, __) => false,
  );
}

bool _isScenarioProvenance(LegacySourceRef provenance) {
  return provenance.when(
    mapEvent: (_, __) => false,
    scenarioSourceNode: (_, __) => true,
  );
}

bool _isLegacyScenarioSourceNode(String? actionKind) {
  return const {
    'sourceMapEnter',
    'sourceTriggerEnter',
    'sourceEntityInteract',
    'sourceOutcome',
  }.contains(actionKind);
}

NarrativeEventReferenceMappings _buildReferencePreflightMappings({
  required NarrativeEventMigrationPlannerInput input,
  required List<_Candidate> candidates,
  required List<NarrativeEventPageMapping> pageMappings,
  required NarrativeEventMigrationReceipt? existingReceipt,
}) {
  final targetsByProvenance = <LegacySourceRef, _PreflightTargets>{};
  for (final candidate in candidates) {
    if (candidate.resolved && candidate.targetEventIds.isNotEmpty) {
      final targetKeys = candidate.targetEventIdsByKey.keys.toSet();
      targetsByProvenance[candidate.provenance] = _PreflightTargets(
        tokens: targetKeys.isNotEmpty
            ? targetKeys
            : candidate.targetEventIds.toSet(),
        targetKeys: targetKeys,
        actualIds: candidate.targetEventIds.toSet(),
      );
      continue;
    }
    final source = candidate.source;
    if (!candidate.canClaim || source == null) {
      targetsByProvenance[candidate.provenance] = _PreflightTargets.empty();
      continue;
    }
    final targetKeys = {
      for (final target in candidate.targets)
        computeNarrativeEventMigrationTargetKey(
          provenance: candidate.provenance,
          targetSignature: target.recordSignature(source),
        ),
    };
    targetsByProvenance[candidate.provenance] = _PreflightTargets(
      tokens: targetKeys,
      targetKeys: targetKeys,
      actualIds: const {},
    );
  }

  final choicesByPath = {
    for (final choice in _effectiveReferenceChoices(input, existingReceipt))
      choice.path: choice,
  };

  List<NarrativeEventReferenceMapping> resolve(
    NarrativeEventReferenceDomain domain,
    List<LegacyEventReference> references,
  ) {
    final sorted = List<LegacyEventReference>.of(references)
      ..sort((left, right) => left.path.compareTo(right.path));
    return [
      for (final reference in sorted)
        _preflightReference(
          domain: domain,
          reference: reference,
          targetsByProvenance: targetsByProvenance,
          choice: choicesByPath[reference.path],
        ),
    ];
  }

  return NarrativeEventReferenceMappings(
    pageMappings: pageMappings,
    progressionMappings: resolve(
      NarrativeEventReferenceDomain.progression,
      input.references.progression,
    ),
    conditionMappings: resolve(
      NarrativeEventReferenceDomain.condition,
      input.references.conditions,
    ),
    worldRuleMappings: resolve(
      NarrativeEventReferenceDomain.worldRule,
      input.references.worldRules,
    ),
    consequenceMappings: resolve(
      NarrativeEventReferenceDomain.consequence,
      input.references.consequences,
    ),
    saveMappings: resolve(
      NarrativeEventReferenceDomain.save,
      input.references.saves,
    ),
  );
}

NarrativeEventReferenceMapping _preflightReference({
  required NarrativeEventReferenceDomain domain,
  required LegacyEventReference reference,
  required Map<LegacySourceRef, _PreflightTargets> targetsByProvenance,
  required NarrativeEventReferenceResolutionChoice? choice,
}) {
  final tokens = <String>{};
  final targetKeys = <String>{};
  final actualIds = <String>{};
  var everyCandidateHasTargets = true;
  for (final provenance in reference.candidateProvenances) {
    final targets =
        targetsByProvenance[provenance] ?? _PreflightTargets.empty();
    if (targets.tokens.isEmpty) everyCandidateHasTargets = false;
    tokens.addAll(targets.tokens);
    targetKeys.addAll(targets.targetKeys);
    actualIds.addAll(targets.actualIds);
  }

  NarrativeEventReferenceMapping result(
    NarrativeEventReferenceMappingStatus status, {
    NarrativeEventReferenceCollisionDecision? decision,
  }) {
    return NarrativeEventReferenceMapping(
      domain: domain,
      kind: reference.kind,
      path: reference.path,
      legacyEventId: reference.legacyEventId,
      mapId: reference.mapId,
      candidateProvenances: reference.candidateProvenances,
      targetEventIds: const [],
      availableTargetKeys: targetKeys.toList(),
      status: status,
      decision: decision,
    );
  }

  if (reference.candidateProvenances.isEmpty) {
    return result(
      domain == NarrativeEventReferenceDomain.progression ||
              domain == NarrativeEventReferenceDomain.save
          ? NarrativeEventReferenceMappingStatus.preservedTombstone
          : NarrativeEventReferenceMappingStatus.blocked,
    );
  }
  if (choice == null) {
    if (reference.candidateProvenances.length > 1 || tokens.length > 1) {
      return result(NarrativeEventReferenceMappingStatus.requiresChoice);
    }
    return result(
      tokens.length == 1
          ? NarrativeEventReferenceMappingStatus.readyForAllocation
          : NarrativeEventReferenceMappingStatus.blocked,
    );
  }

  switch (choice.decision) {
    case NarrativeEventReferenceCollisionDecision.cancel:
      return result(
        NarrativeEventReferenceMappingStatus.cancelled,
        decision: choice.decision,
      );
    case NarrativeEventReferenceCollisionDecision.consumeAllTargets:
      final domainAllowsAll =
          domain == NarrativeEventReferenceDomain.progression ||
              domain == NarrativeEventReferenceDomain.save;
      return result(
        domainAllowsAll && everyCandidateHasTargets && tokens.isNotEmpty
            ? NarrativeEventReferenceMappingStatus.readyForAllocation
            : NarrativeEventReferenceMappingStatus.blocked,
        decision: choice.decision,
      );
    case NarrativeEventReferenceCollisionDecision.selectedTargets:
      if (choice.selectedTargetKeys.isNotEmpty) {
        final exactStableSelection = choice.selectedTargetKeys.every(
          targetKeys.contains,
        );
        return result(
          exactStableSelection
              ? NarrativeEventReferenceMappingStatus.readyForAllocation
              : NarrativeEventReferenceMappingStatus.blocked,
          decision: choice.decision,
        );
      }
      final exactExistingSelection = choice.selectedTargetEventIds.every(
        actualIds.contains,
      );
      return result(
        exactExistingSelection
            ? NarrativeEventReferenceMappingStatus.readyForAllocation
            : NarrativeEventReferenceMappingStatus.blocked,
        decision: choice.decision,
      );
  }
}

void _recordBlockingReferenceDiagnostics(
  NarrativeEventReferenceMappings mappings,
  List<LegacyMigrationDiagnostic> diagnostics,
) {
  for (final mapping in mappings.allReferenceMappings) {
    if (mapping.status == NarrativeEventReferenceMappingStatus.mapped ||
        mapping.status ==
            NarrativeEventReferenceMappingStatus.readyForAllocation ||
        mapping.status ==
            NarrativeEventReferenceMappingStatus.preservedTombstone) {
      continue;
    }
    diagnostics.add(
      _diagnostic(
        NarrativeEventMigrationDiagnosticCodes.unresolvedReference,
        LegacyMigrationDiagnosticSeverity.error,
        'The legacy reference requires an explicit valid mapping.',
        mapping.path,
      ),
    );
  }
}

final class _PreflightTargets {
  const _PreflightTargets({
    required this.tokens,
    required this.targetKeys,
    required this.actualIds,
  });

  const _PreflightTargets.empty()
      : tokens = const {},
        targetKeys = const {},
        actualIds = const {};

  final Set<String> tokens;
  final Set<String> targetKeys;
  final Set<String> actualIds;
}

bool _validateCatalogContext({
  required NarrativeEventMigrationPlannerInput input,
  required List<_Candidate> candidates,
  required NarrativeEventProjectCatalog catalog,
  required List<LegacyMigrationDiagnostic> diagnostics,
}) {
  final expectedCatalog = buildNarrativeEventProjectCatalog(
    project: input.project,
    maps: input.maps,
    legacyProjections: input.mapEventProjections,
    referencedOutcomes: _candidateOutcomeReferences(candidates),
    proposedRecords: catalog.proposedRecords,
  );
  final snapshotMatches =
      catalog.manifestHash == input.currentSnapshot.manifestHash &&
          _sameStringMap(catalog.mapHashes, input.currentSnapshot.mapHashes);
  final contentMatches = canonicalizeNarrativeEventJson(
        catalog.toDebugJson(),
      ) ==
      canonicalizeNarrativeEventJson(expectedCatalog.toDebugJson());
  if (snapshotMatches && contentMatches) return false;
  diagnostics.add(
    _diagnostic(
      NarrativeEventMigrationDiagnosticCodes.validationCatalogMismatch,
      LegacyMigrationDiagnosticSeverity.error,
      'The project catalog does not describe the exact manifest, maps, and '
          'source inventories bound to the current migration snapshot.',
      'validationCatalog',
    ),
  );
  return true;
}

List<NarrativeOutcomeRef> _candidateOutcomeReferences(
  List<_Candidate> candidates,
) {
  final byKey = <String, NarrativeOutcomeRef>{};
  for (final candidate in candidates) {
    candidate.source?.when<void>(
      entityInteract: (_, __) {},
      triggerEnter: (_, __) {},
      mapEnter: (_) {},
      outcomeReceived: (outcome) {
        byKey[canonicalizeNarrativeEventJson(outcome.toJson())] = outcome;
      },
    );
  }
  final keys = byKey.keys.toList()..sort();
  return [for (final key in keys) byKey[key]!];
}

bool _validateProposedRecordClosure({
  required List<_Candidate> candidates,
  required NarrativeEventProjectCatalog catalog,
  required List<LegacyMigrationDiagnostic> diagnostics,
}) {
  final targetSignatures = <String>{};
  for (final candidate in candidates) {
    final source = candidate.source;
    if (source == null) continue;
    for (final target in candidate.targets) {
      if (target.isConfigured) {
        targetSignatures.add(target.recordSignature(source));
      }
    }
  }
  final proposedBySignature = <String, List<NarrativeEventRecord>>{};
  for (final record in catalog.proposedRecords) {
    proposedBySignature
        .putIfAbsent(_recordSignature(record), () => [])
        .add(record);
  }
  var blocked = false;
  for (final entry in proposedBySignature.entries) {
    if (entry.value.length == 1 && targetSignatures.contains(entry.key)) {
      continue;
    }
    blocked = true;
    for (final candidate in candidates) {
      candidate.hardBlocked = true;
      candidate.choiceApplied = false;
    }
    final ids = entry.value.map((record) => record.id).toList()
      ..sort(compareNarrativeEventUtf16);
    diagnostics.add(
      _diagnostic(
        entry.value.length > 1
            ? NarrativeEventMigrationDiagnosticCodes.eventAmbiguous
            : NarrativeEventMigrationDiagnosticCodes.eventUnavailable,
        LegacyMigrationDiagnosticSeverity.error,
        entry.value.length > 1
            ? 'Several proposed Event records represent the same migration '
                'target signature.'
            : 'A proposed Event record is not an exact target of this '
                'atomic migration plan.',
        'validationCatalog.proposedRecords.${ids.join(',')}',
      ),
    );
  }
  return blocked;
}

bool _appendProjectCatalogDiagnostics(
  NarrativeEventProjectCatalog catalog,
  List<LegacyMigrationDiagnostic> diagnostics,
) {
  var blocked = false;
  for (final diagnostic in catalog.diagnostics) {
    final severity = switch (diagnostic.severity) {
      NarrativeEventProjectDiagnosticSeverity.info =>
        LegacyMigrationDiagnosticSeverity.info,
      NarrativeEventProjectDiagnosticSeverity.warning =>
        LegacyMigrationDiagnosticSeverity.warning,
      NarrativeEventProjectDiagnosticSeverity.error =>
        LegacyMigrationDiagnosticSeverity.error,
    };
    if (severity == LegacyMigrationDiagnosticSeverity.error) blocked = true;
    diagnostics.add(
      _diagnostic(
        '${NarrativeEventMigrationDiagnosticCodes.validationCatalogDiagnostic}'
            '.${diagnostic.code}',
        severity,
        diagnostic.message,
        'validationCatalog.${diagnostic.path}',
      ),
    );
  }
  return blocked;
}

bool _validateContextualIntegrity({
  required List<_Candidate> candidates,
  required NarrativeEventProjectCatalog catalog,
  required List<LegacyMigrationDiagnostic> diagnostics,
}) {
  var blocked = false;
  for (final candidate in candidates) {
    final choice = candidate.sourceChoice;
    if (choice != null) candidate.choiceApplied = false;
    final requiresValidation = !candidate.assistancePending || choice != null;
    if (!requiresValidation) continue;
    final source = candidate.source;
    if (source == null) {
      blocked = _blockContextualCandidate(
        candidate: candidate,
        diagnostics: diagnostics,
        code: NarrativeEventMigrationDiagnosticCodes.sourceMissing,
        message: 'The proposed migration source is missing.',
        path: '${_provenancePath(candidate.provenance)}.source',
      );
      continue;
    }

    final sourceResolution = catalog.resolveSource(source);
    switch (sourceResolution.status) {
      case NarrativeEventProjectResolutionStatus.found:
        break;
      case NarrativeEventProjectResolutionStatus.missing:
        blocked = _blockContextualCandidate(
          candidate: candidate,
          diagnostics: diagnostics,
          code: NarrativeEventMigrationDiagnosticCodes.sourceMissing,
          message: 'The proposed migration source does not exist.',
          path: '${_provenancePath(candidate.provenance)}.source',
        );
        break;
      case NarrativeEventProjectResolutionStatus.unavailable:
        blocked = _blockContextualCandidate(
          candidate: candidate,
          diagnostics: diagnostics,
          code: NarrativeEventMigrationDiagnosticCodes.sourceUnavailable,
          message: 'The proposed migration source is not selectable.',
          path: '${_provenancePath(candidate.provenance)}.source',
        );
        break;
      case NarrativeEventProjectResolutionStatus.ambiguous:
        blocked = _blockContextualCandidate(
          candidate: candidate,
          diagnostics: diagnostics,
          code: NarrativeEventMigrationDiagnosticCodes.sourceAmbiguous,
          message: 'The proposed migration source is not unique.',
          path: '${_provenancePath(candidate.provenance)}.source',
        );
        break;
    }
    if (candidate.hardBlocked) continue;

    for (var targetIndex = 0;
        targetIndex < candidate.targets.length;
        targetIndex++) {
      final target = candidate.targets[targetIndex];
      final targetPath =
          '${_provenancePath(candidate.provenance)}.targets.$targetIndex';
      final sceneId = target.sceneId;
      if (sceneId != null) {
        final sceneResolution = catalog.resolveScene(sceneId);
        switch (sceneResolution.status) {
          case NarrativeEventProjectResolutionStatus.found:
            break;
          case NarrativeEventProjectResolutionStatus.missing:
            blocked = _blockContextualCandidate(
              candidate: candidate,
              diagnostics: diagnostics,
              code: NarrativeEventMigrationDiagnosticCodes.sceneMissing,
              message: 'The target Scene does not exist.',
              path: '$targetPath.sceneId',
            );
            break;
          case NarrativeEventProjectResolutionStatus.unavailable:
            blocked = _blockContextualCandidate(
              candidate: candidate,
              diagnostics: diagnostics,
              code: NarrativeEventMigrationDiagnosticCodes.sceneUnavailable,
              message: 'The target Scene is not buildable.',
              path: '$targetPath.sceneId',
            );
            break;
          case NarrativeEventProjectResolutionStatus.ambiguous:
            blocked = _blockContextualCandidate(
              candidate: candidate,
              diagnostics: diagnostics,
              code: NarrativeEventMigrationDiagnosticCodes.sceneAmbiguous,
              message: 'The target Scene identity is duplicated.',
              path: '$targetPath.sceneId',
            );
            break;
        }
      }

      for (var conditionIndex = 0;
          conditionIndex < target.conditions.length;
          conditionIndex++) {
        final condition = target.conditions[conditionIndex];
        condition.when<void>(
          fact: (factId, _) {
            final resolution = catalog.resolveFact(factId);
            switch (resolution.status) {
              case NarrativeEventProjectResolutionStatus.found:
                return;
              case NarrativeEventProjectResolutionStatus.missing:
              case NarrativeEventProjectResolutionStatus.unavailable:
                blocked = _blockContextualCandidate(
                  candidate: candidate,
                  diagnostics: diagnostics,
                  code: NarrativeEventMigrationDiagnosticCodes.factMissing,
                  message: 'The target Fact does not exist.',
                  path: '$targetPath.conditions.$conditionIndex.factId',
                );
                return;
              case NarrativeEventProjectResolutionStatus.ambiguous:
                blocked = _blockContextualCandidate(
                  candidate: candidate,
                  diagnostics: diagnostics,
                  code: NarrativeEventMigrationDiagnosticCodes.factAmbiguous,
                  message: 'The target Fact identity is duplicated.',
                  path: '$targetPath.conditions.$conditionIndex.factId',
                );
                return;
            }
          },
          narrativeEventConsumed: (eventId, _) {
            final resolution = catalog.resolveEvent(eventId);
            switch (resolution.status) {
              case NarrativeEventProjectResolutionStatus.found:
                return;
              case NarrativeEventProjectResolutionStatus.missing:
                blocked = _blockContextualCandidate(
                  candidate: candidate,
                  diagnostics: diagnostics,
                  code: NarrativeEventMigrationDiagnosticCodes.eventMissing,
                  message: 'The referenced Event does not exist.',
                  path: '$targetPath.conditions.$conditionIndex.eventId',
                );
                return;
              case NarrativeEventProjectResolutionStatus.unavailable:
                blocked = _blockContextualCandidate(
                  candidate: candidate,
                  diagnostics: diagnostics,
                  code: NarrativeEventMigrationDiagnosticCodes.eventUnavailable,
                  message:
                      'The referenced Event is a draft or belongs to a cycle.',
                  path: '$targetPath.conditions.$conditionIndex.eventId',
                );
                return;
              case NarrativeEventProjectResolutionStatus.ambiguous:
                blocked = _blockContextualCandidate(
                  candidate: candidate,
                  diagnostics: diagnostics,
                  code: NarrativeEventMigrationDiagnosticCodes.eventAmbiguous,
                  message: 'The referenced Event identity is duplicated.',
                  path: '$targetPath.conditions.$conditionIndex.eventId',
                );
                return;
            }
          },
        );
      }
    }
    if (!candidate.hardBlocked && choice != null) {
      candidate.choiceApplied = true;
      if (choice.kind ==
          NarrativeEventMigrationSourceChoiceKind.explicitReassignment) {
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes
                .explicitReassignmentValidated,
            LegacyMigrationDiagnosticSeverity.info,
            'The explicit source reassignment and all target references '
                'were validated against the project catalog; its human '
                'reason remains preserved.',
            '${_provenancePath(candidate.provenance)}.source',
          ),
        );
      }
    }
  }
  return blocked;
}

bool _blockContextualCandidate({
  required _Candidate candidate,
  required List<LegacyMigrationDiagnostic> diagnostics,
  required String code,
  required String message,
  required String path,
}) {
  candidate.hardBlocked = true;
  diagnostics.add(
    _diagnostic(
      code,
      LegacyMigrationDiagnosticSeverity.error,
      message,
      path,
    ),
  );
  return true;
}

List<_Candidate> _buildCandidates(
  NarrativeEventMigrationPlannerInput input,
  NarrativeEventMigrationChoices choices,
) {
  final result = <_Candidate>[];
  for (final projection in input.mapEventProjections) {
    final choice = choices.sourceChoiceFor(projection.provenance);
    final candidateDiagnostics = <LegacyMigrationDiagnostic>[
      ...projection.diagnostics,
    ];
    final confirmed = projection.confirmedSource;
    final existingSource = projection.existingClaim?.source;
    var source = confirmed ?? existingSource;
    var hardBlocked = _isHardClassification(projection.classification) ||
        projection.claimStatus == LegacyProjectionClaimStatus.invalid ||
        (projection.claimStatus == LegacyProjectionClaimStatus.valid &&
            projection.existingClaim == null);
    final targets = <NarrativeEventMigrationTargetProposal>[];
    var assistancePending = false;
    var choiceApplied = false;
    final explicitReassignment = choice?.kind ==
        NarrativeEventMigrationSourceChoiceKind.explicitReassignment;
    if (explicitReassignment) {
      source = choice!.source;
      targets.addAll(choice.targets);
      assistancePending = targets.any((target) => !target.isConfigured);
    } else if (choice != null) {
      source ??= choice.source;
      if (confirmed != null && confirmed != choice.source) {
        hardBlocked = true;
        source = confirmed;
        candidateDiagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.choiceContradictsProjection,
            LegacyMigrationDiagnosticSeverity.error,
            'The candidate confirmation contradicts the source already '
            'confirmed by the projection.',
            _provenancePath(projection.provenance),
          ),
        );
      }
    }
    if (projection.classification == LegacyMigrationClassification.autoSafe) {
      final target = _autoMapTarget(projection);
      if (explicitReassignment) {
        hardBlocked = true;
        candidateDiagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.choiceContradictsProjection,
            LegacyMigrationDiagnosticSeverity.error,
            'An AUTO_SAFE MapEvent cannot be reassigned without first '
            'becoming an assisted projection.',
            _provenancePath(projection.provenance),
          ),
        );
      } else if (source == null || target == null) {
        hardBlocked = true;
      } else if (choice == null) {
        assistancePending = true;
        targets.add(target);
      } else if (choice.kind !=
              NarrativeEventMigrationSourceChoiceKind.confirmCandidate ||
          !_mapProjectionContainsSource(projection, choice.source) ||
          !_mapLifecycleChoiceMatches(choice, target, source)) {
        hardBlocked = true;
        candidateDiagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.choiceContradictsProjection,
            LegacyMigrationDiagnosticSeverity.error,
            'The MapEvent choice changes more than its unresolved lifecycle.',
            _provenancePath(projection.provenance),
          ),
        );
      } else {
        choiceApplied = true;
        targets.addAll(choice.targets);
      }
    } else if (projection.classification ==
        LegacyMigrationClassification.assisted) {
      if (choice != null) {
        if (!explicitReassignment) {
          source = choice.source;
          targets.addAll(choice.targets);
          assistancePending = targets.any((target) => !target.isConfigured);
          if (choice.kind !=
                  NarrativeEventMigrationSourceChoiceKind.confirmCandidate ||
              !_mapProjectionContainsSource(projection, choice.source)) {
            hardBlocked = true;
            candidateDiagnostics.add(
              _diagnostic(
                NarrativeEventMigrationDiagnosticCodes
                    .choiceContradictsProjection,
                LegacyMigrationDiagnosticSeverity.error,
                'The candidate confirmation is not one of the sources '
                'exposed by the MapEvent projection.',
                _provenancePath(projection.provenance),
              ),
            );
          } else {
            choiceApplied = true;
          }
        }
      } else {
        assistancePending = true;
        targets.add(_draftMapTarget(projection));
      }
    } else if (choice != null) {
      hardBlocked = true;
      candidateDiagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes.unusedChoice,
          LegacyMigrationDiagnosticSeverity.error,
          'A source choice cannot override a blocked legacy projection.',
          _provenancePath(projection.provenance),
        ),
      );
    }
    result.add(
      _Candidate(
        provenance: projection.provenance,
        classification: projection.classification,
        source: source,
        sourceFingerprint: projection.sourceFingerprint,
        choiceApplied: choiceApplied,
        assistancePending: assistancePending,
        hardBlocked: hardBlocked,
        targets: targets,
        sourceChoice: choice,
        mapProjection: projection,
        diagnostics: candidateDiagnostics,
      ),
    );
  }
  for (final projection in input.scenarioProjections) {
    final choice = choices.sourceChoiceFor(projection.provenance);
    final candidateDiagnostics = <LegacyMigrationDiagnostic>[
      ...projection.diagnostics,
    ];
    final projectedSource = projection.source;
    final existingSource = projection.existingClaim?.source;
    var source = projectedSource ?? existingSource;
    var hardBlocked = _isHardClassification(projection.classification) ||
        projection.claimStatus == LegacyProjectionClaimStatus.invalid ||
        (projection.claimStatus == LegacyProjectionClaimStatus.valid &&
            projection.existingClaim == null);
    final targets = <NarrativeEventMigrationTargetProposal>[];
    var assistancePending = false;
    var choiceApplied = false;
    final explicitReassignment = choice?.kind ==
        NarrativeEventMigrationSourceChoiceKind.explicitReassignment;
    if (explicitReassignment) {
      source = choice!.source;
      targets.addAll(choice.targets);
      assistancePending = targets.any((target) => !target.isConfigured);
    } else if (choice != null) {
      source ??= choice.source;
      if (projectedSource != null && projectedSource != choice.source) {
        hardBlocked = true;
        source = projectedSource;
        candidateDiagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.choiceContradictsProjection,
            LegacyMigrationDiagnosticSeverity.error,
            'The candidate confirmation contradicts the Scenario source.',
            _provenancePath(projection.provenance),
          ),
        );
      }
    }
    if (projection.classification == LegacyMigrationClassification.autoSafe) {
      final target = _autoScenarioTarget(projection);
      if (explicitReassignment) {
        hardBlocked = true;
        candidateDiagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.choiceContradictsProjection,
            LegacyMigrationDiagnosticSeverity.error,
            'An AUTO_SAFE Scenario cannot be reassigned without first '
            'becoming an assisted projection.',
            _provenancePath(projection.provenance),
          ),
        );
      } else if (source == null || target == null) {
        hardBlocked = true;
      } else if (choice != null) {
        hardBlocked = true;
        candidateDiagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.unusedChoice,
            LegacyMigrationDiagnosticSeverity.error,
            'An AUTO_SAFE Scenario projection does not accept target overrides.',
            _provenancePath(projection.provenance),
          ),
        );
      } else {
        targets.add(target);
      }
    } else if (projection.classification ==
        LegacyMigrationClassification.assisted) {
      if (choice != null) {
        if (!explicitReassignment) {
          source = choice.source;
          targets.addAll(choice.targets);
          assistancePending = targets.any((target) => !target.isConfigured);
          if (choice.kind !=
                  NarrativeEventMigrationSourceChoiceKind.confirmCandidate ||
              projectedSource == null ||
              projectedSource != choice.source) {
            hardBlocked = true;
            candidateDiagnostics.add(
              _diagnostic(
                NarrativeEventMigrationDiagnosticCodes
                    .choiceContradictsProjection,
                LegacyMigrationDiagnosticSeverity.error,
                'The candidate confirmation does not match the Scenario '
                'projection source.',
                _provenancePath(projection.provenance),
              ),
            );
          } else {
            choiceApplied = true;
          }
        }
      } else {
        assistancePending = true;
        targets.add(_draftScenarioTarget(projection));
      }
    } else if (choice != null) {
      hardBlocked = true;
      candidateDiagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes.unusedChoice,
          LegacyMigrationDiagnosticSeverity.error,
          'A source choice cannot override a blocked legacy projection.',
          _provenancePath(projection.provenance),
        ),
      );
    }
    result.add(
      _Candidate(
        provenance: projection.provenance,
        classification: projection.classification,
        source: source,
        sourceFingerprint: projection.sourceFingerprint,
        choiceApplied: choiceApplied,
        assistancePending: assistancePending,
        hardBlocked: hardBlocked,
        targets: targets,
        sourceChoice: choice,
        scenarioProjection: projection,
        diagnostics: candidateDiagnostics,
      ),
    );
  }
  return result;
}

bool _mapProjectionContainsSource(
  LegacyMapEventProjection projection,
  NarrativeEventSourceRef source,
) {
  return projection.sourceCandidates.any(
    (candidate) => candidate.source == source,
  );
}

NarrativeEventMigrationTargetProposal? _autoMapTarget(
  LegacyMapEventProjection projection,
) {
  if (projection.pages.length != 1) return null;
  final page = projection.pages.single;
  if (page.sceneId == null ||
      page.condition != null ||
      page.script != null ||
      page.message != null ||
      page.isHidden ||
      page.isDisabled) {
    return null;
  }
  return NarrativeEventMigrationTargetProposal(
    name: _mapProjectionName(projection),
    legacyPageIndex: page.pageIndex,
    conditions: const [],
    sceneId: page.sceneId,
    reusePolicy: null,
    priority: 0,
    order: page.pageIndex,
  );
}

bool _mapLifecycleChoiceMatches(
  NarrativeEventMigrationSourceChoice choice,
  NarrativeEventMigrationTargetProposal projected,
  NarrativeEventSourceRef source,
) {
  if (choice.source != source || choice.targets.length != 1) return false;
  final selected = choice.targets.single;
  return selected.name == projected.name &&
      selected.legacyPageIndex == projected.legacyPageIndex &&
      selected.sceneId == projected.sceneId &&
      selected.reusePolicy != null &&
      selected.priority == projected.priority &&
      selected.order == projected.order &&
      canonicalizeNarrativeEventJson([
            for (final condition in selected.conditions) condition.toJson(),
          ]) ==
          canonicalizeNarrativeEventJson([
            for (final condition in projected.conditions) condition.toJson(),
          ]);
}

NarrativeEventMigrationTargetProposal _draftMapTarget(
  LegacyMapEventProjection projection,
) {
  final page = projection.pages.length == 1 ? projection.pages.single : null;
  return NarrativeEventMigrationTargetProposal(
    name: _mapProjectionName(projection),
    legacyPageIndex: page?.pageIndex,
    conditions: const [],
    sceneId: page?.sceneId,
    reusePolicy: null,
    priority: 0,
    order: page?.pageIndex ?? 0,
  );
}

NarrativeEventMigrationTargetProposal? _autoScenarioTarget(
  LegacyScenarioSourceProjection projection,
) {
  final sceneId = projection.sceneCandidateId;
  final reusePolicy = projection.reusePolicyCandidate;
  if (sceneId == null || reusePolicy == null) return null;
  return NarrativeEventMigrationTargetProposal(
    name: _scenarioProjectionName(projection),
    conditions: const [],
    sceneId: sceneId,
    reusePolicy: reusePolicy,
    priority: 0,
    order: 0,
  );
}

bool _scenarioAssistedChoiceMatchesProjection(
  LegacyScenarioSourceProjection projection,
  NarrativeEventMigrationSourceChoice choice,
) {
  if (choice.targets.length != 1) return false;
  final selected = choice.targets.single;
  final projectedReusePolicy = projection.reusePolicyCandidate;
  return selected.name == _scenarioProjectionName(projection) &&
      selected.legacyPageIndex == null &&
      selected.conditions.isEmpty &&
      selected.sceneId == projection.sceneCandidateId &&
      (projectedReusePolicy == null
          ? selected.reusePolicy != null
          : selected.reusePolicy == projectedReusePolicy) &&
      selected.priority == 0 &&
      selected.order == 0;
}

NarrativeEventMigrationTargetProposal _draftScenarioTarget(
  LegacyScenarioSourceProjection projection,
) {
  return NarrativeEventMigrationTargetProposal(
    name: _scenarioProjectionName(projection),
    conditions: const [],
    sceneId: projection.sceneCandidateId,
    reusePolicy: projection.reusePolicyCandidate,
    priority: 0,
    order: 0,
  );
}

List<_Group> _buildGroups(List<_Candidate> candidates) {
  final bySource = <String, _Group>{};
  for (final candidate in candidates) {
    final source = candidate.source;
    if (source == null) continue;
    final key = canonicalizeNarrativeEventJson(source.toJson());
    bySource.putIfAbsent(key, () => _Group(source)).candidates.add(candidate);
  }
  final keys = bySource.keys.toList()..sort();
  return [
    for (final key in keys) bySource[key]!..finalize(),
  ];
}

void _resolveExistingClaim(
  _Group group,
  NarrativeEventRegistry? registry,
  NarrativeEventMigrationReceipt? existingReceipt,
  List<LegacyMigrationDiagnostic> diagnostics,
) {
  if (registry == null) return;
  final expectedProvenances = {
    for (final member in group.members) member.provenance,
  };
  final relevant = registry.legacyClaims.where((claim) {
    if (claim.source == group.source) return true;
    return claim.members.any(
      (member) => expectedProvenances.contains(member.provenance),
    );
  }).toList();
  if (relevant.isEmpty) return;
  if (relevant.length == 1 && _isExactClaim(relevant.single, group, registry)) {
    final claim = relevant.single;
    group.existingClaim = claim;
    group.targetEventIds = claim.targetEventIds;
    group.hardBlocked =
        group.candidates.any((candidate) => candidate.hardBlocked);
    final recordsById = {
      for (final record in registry.records) record.id: record,
    };
    for (final candidate in group.candidates) {
      final receiptMappings = existingReceipt?.mappings.idMappings
              .where((mapping) => mapping.provenance == candidate.provenance)
              .toList(growable: false) ??
          const <NarrativeEventIdMapping>[];
      final receiptTargetIds = receiptMappings.length == 1 &&
              receiptMappings.single.targetEventIds.every(
                claim.targetEventIds.contains,
              )
          ? receiptMappings.single.targetEventIds
          : null;
      final configuredTargets = candidate.assistancePending
          ? const <NarrativeEventMigrationTargetProposal>[]
          : [
              for (final target in candidate.targets)
                if (target.isConfigured) target,
            ];
      candidate.targetEventIds = [];
      candidate.targetEventIdsByKey.clear();
      if (configuredTargets.isEmpty) {
        if (receiptTargetIds == null) {
          candidate.targetEventIds = List.of(claim.targetEventIds);
        } else {
          for (final targetId in receiptTargetIds) {
            candidate.addTarget(
              _targetProposalFromDefinition(
                recordsById[targetId]!.definitionOrNull!,
              ),
              targetId,
            );
          }
        }
      } else {
        for (final target in configuredTargets) {
          final signature = target.recordSignature(group.source);
          final matchingIds = [
            for (final targetId in claim.targetEventIds)
              if (_recordSignature(recordsById[targetId]!) == signature)
                targetId,
          ];
          if (matchingIds.length == 1) {
            candidate.addTarget(target, matchingIds.single);
          }
        }
      }
      candidate.resolved = true;
      candidate.pageTargetIds.clear();
      if (receiptTargetIds != null && existingReceipt != null) {
        for (final pageMapping in existingReceipt.mappings.pageMappings) {
          final targetId = pageMapping.targetEventId;
          if (pageMapping.provenance == candidate.provenance &&
              pageMapping.status == NarrativeEventPageMappingStatus.mapped &&
              targetId != null &&
              candidate.targetEventIds.contains(targetId)) {
            candidate.pageTargetIds[pageMapping.pageIndex] = [targetId];
          }
        }
      }
      if (candidate.mapProjection?.pages.length == 1 &&
          candidate.targetEventIds.length == 1 &&
          candidate.pageTargetIds.isEmpty) {
        candidate
            .pageTargetIds[candidate.mapProjection!.pages.single.pageIndex] = [
          candidate.targetEventIds.single
        ];
      }
    }
    return;
  }
  group.hardBlocked = true;
  for (final candidate in group.candidates) {
    candidate.hardBlocked = true;
  }
  diagnostics.add(
    _diagnostic(
      NarrativeEventMigrationDiagnosticCodes.partialClaim,
      LegacyMigrationDiagnosticSeverity.error,
      'An existing claim overlaps this source without covering the exact '
          'complete cohort and valid targets.',
      'eventRegistry.legacyClaims.${group.cohortId}',
    ),
  );
}

bool _validateExistingClaimContext({
  required _Group group,
  required NarrativeEventProjectCatalog catalog,
  required List<LegacyMigrationDiagnostic> diagnostics,
}) {
  final claim = group.existingClaim;
  if (claim == null) return false;
  var blocked = false;
  for (final targetId in claim.targetEventIds) {
    final resolution = catalog.resolveEvent(targetId);
    if (resolution.status == NarrativeEventProjectResolutionStatus.found) {
      continue;
    }
    blocked = true;
    group.hardBlocked = true;
    for (final candidate in group.candidates) {
      candidate.hardBlocked = true;
      candidate.choiceApplied = false;
    }
    diagnostics.add(
      _diagnostic(
        switch (resolution.status) {
          NarrativeEventProjectResolutionStatus.missing =>
            NarrativeEventMigrationDiagnosticCodes.eventMissing,
          NarrativeEventProjectResolutionStatus.unavailable =>
            NarrativeEventMigrationDiagnosticCodes.eventUnavailable,
          NarrativeEventProjectResolutionStatus.ambiguous =>
            NarrativeEventMigrationDiagnosticCodes.eventAmbiguous,
          NarrativeEventProjectResolutionStatus.found =>
            throw StateError('A found claim target cannot be invalid.'),
        },
        LegacyMigrationDiagnosticSeverity.error,
        'An existing claim target must remain unique, configured, and '
            'contextually valid before its receipt can be reused.',
        'eventRegistry.legacyClaims.${claim.cohortId}.$targetId',
      ),
    );
  }
  return blocked;
}

bool _isExactClaim(
  LegacySourceClaim claim,
  _Group group,
  NarrativeEventRegistry registry,
) {
  if (claim.source != group.source || claim.cohortId != group.cohortId) {
    return false;
  }
  if (claim.members.length != group.members.length) return false;
  for (var index = 0; index < group.members.length; index++) {
    if (claim.members[index] != group.members[index]) return false;
  }
  final actualSignatures = <String>[];
  for (final targetId in claim.targetEventIds) {
    final matches = registry.records.where((record) => record.id == targetId);
    if (matches.length != 1) return false;
    final record = matches.single;
    if (record.enabledOrNull == true) return false;
    final definition = record.definitionOrNull;
    if (definition == null || definition.source != group.source) return false;
    actualSignatures.add(_recordSignature(record));
  }
  final expectedSignatures = <String>{
    for (final candidate in group.candidates)
      if (!candidate.assistancePending)
        for (final target in candidate.targets)
          if (target.isConfigured) target.recordSignature(group.source),
  };
  if (actualSignatures.length != actualSignatures.toSet().length ||
      (expectedSignatures.isNotEmpty &&
          !_sameStrings(expectedSignatures, actualSignatures.toSet()))) {
    return false;
  }
  return true;
}

String _recordSignature(NarrativeEventRecord record) {
  final definition = record.definitionOrNull;
  if (definition == null) return 'draft:${record.id}';
  return canonicalizeNarrativeEventJson({
    'name': definition.name,
    'source': definition.source.toJson(),
    'conditions': [
      for (final condition in definition.conditions) condition.toJson(),
    ],
    'sceneId': definition.sceneId,
    'reusePolicy': definition.reusePolicy.name,
    'priority': definition.priority,
    'order': definition.order,
  });
}

bool _matchesAppliedReceipt({
  required NarrativeEventMigrationPlannerInput input,
  required NarrativeEventRegistry registry,
  required List<_Candidate> candidates,
  required List<LegacySourceClaim> existingClaims,
  required NarrativeEventMigrationReceipt receipt,
}) {
  if (!receipt.isProposal ||
      receipt.lifecycle.status !=
          NarrativeEventMigrationReceiptStatus.prepared) {
    return false;
  }
  final expectedAtomicity =
      NarrativeEventMigrationAtomicityPlan.phaseCProposal();
  final expectedRollback = NarrativeEventMigrationRollbackPlan.phaseCProposal();
  final expectedPointOfNoReturn =
      NarrativeEventMigrationPointOfNoReturn.phaseCProposal();
  if (canonicalizeNarrativeEventJson(receipt.backupPlan.toJson()) !=
          canonicalizeNarrativeEventJson(input.backupPlan.toJson()) ||
      canonicalizeNarrativeEventJson(receipt.atomicityPlan.toJson()) !=
          canonicalizeNarrativeEventJson(expectedAtomicity.toJson()) ||
      canonicalizeNarrativeEventJson(receipt.rollbackPlan.toJson()) !=
          canonicalizeNarrativeEventJson(expectedRollback.toJson()) ||
      canonicalizeNarrativeEventJson(receipt.pointOfNoReturn.toJson()) !=
          canonicalizeNarrativeEventJson(expectedPointOfNoReturn.toJson())) {
    return false;
  }
  if (receipt.expectedManifestHashAfter != input.currentSnapshot.manifestHash ||
      receipt.expectedManifestHashAfter !=
          _jsonFingerprint(input.project.toJson()) ||
      receipt.expectedRegistryHashAfter !=
          _jsonFingerprint(registry.toJson())) {
    return false;
  }
  final before = receipt.snapshot;
  final current = input.currentSnapshot;
  if (before.projectRevisionToken != current.projectRevisionToken ||
      before.corpusHash != current.corpusHash ||
      before.referenceCatalogHash != current.referenceCatalogHash ||
      !_sameStringMap(before.mapHashes, current.mapHashes) ||
      !_sameStringMap(
        before.legacySourceHashes,
        current.legacySourceHashes,
      ) ||
      !_sameStringMap(before.saveHashes, current.saveHashes)) {
    return false;
  }

  final sortedExistingClaims = List<LegacySourceClaim>.of(existingClaims)
    ..sort((left, right) => left.cohortId.compareTo(right.cohortId));
  if (!_sameCanonicalValues(sortedExistingClaims, receipt.targetClaims)) {
    return false;
  }
  final recordsById = {
    for (final record in registry.records) record.id: record
  };
  for (final expected in receipt.targetRecords) {
    final actual = recordsById[expected.id];
    if (actual == null ||
        canonicalizeNarrativeEventJson(actual.toJson()) !=
            canonicalizeNarrativeEventJson(expected.toJson())) {
      return false;
    }
  }
  if (!_receiptSourceChoicesMatchCurrentEvidence(
    candidates: candidates,
    receipt: receipt,
  )) {
    return false;
  }
  if (!_receiptTargetsMatchCurrentEvidence(
    input: input,
    candidates: candidates,
    registry: registry,
    receipt: receipt,
  )) {
    return false;
  }
  final targetsByProvenance = <LegacySourceRef, List<String>>{
    for (final candidate in candidates)
      if (candidate.resolved && candidate.targetEventIds.isNotEmpty)
        candidate.provenance: candidate.targetEventIds,
  };
  final expectedMappings = buildNarrativeEventReferenceMappings(
    targetEventIdsByProvenance: targetsByProvenance,
    targetEventIdsByTargetKey: _buildTargetIdsByKey(candidates),
    references: input.references,
    choices: _effectiveReferenceChoices(input, receipt),
    idMappings: _buildIdMappings(candidates),
    pageMappings: _buildPageMappings(candidates),
  );
  if (expectedMappings.hasBlockingMappings ||
      canonicalizeNarrativeEventJson(expectedMappings.toJson()) !=
          canonicalizeNarrativeEventJson(receipt.mappings.toJson())) {
    return false;
  }
  return true;
}

bool _receiptSourceChoicesMatchCurrentEvidence({
  required List<_Candidate> candidates,
  required NarrativeEventMigrationReceipt receipt,
}) {
  final claimedProvenances = <LegacySourceRef>{
    for (final claim in receipt.targetClaims)
      for (final member in claim.members) member.provenance,
  };
  final claimedCandidates = [
    for (final candidate in candidates)
      if (claimedProvenances.contains(candidate.provenance)) candidate,
  ];
  if (receipt.schemaVersion ==
      NarrativeEventMigrationReceipt.legacySchemaVersion) {
    return claimedCandidates.every(
      (candidate) =>
          candidate.classification != LegacyMigrationClassification.assisted,
    );
  }
  if (claimedCandidates.any(
    (candidate) =>
        (candidate.classification == LegacyMigrationClassification.assisted &&
            candidate.sourceChoice == null) ||
        (candidate.sourceChoice != null && !candidate.choiceApplied),
  )) {
    return false;
  }
  final expected = [
    for (final candidate in claimedCandidates)
      if (candidate.sourceChoice != null) candidate.sourceChoice!.toJson(),
  ]..sort(
      (left, right) => canonicalizeNarrativeEventJson(left).compareTo(
        canonicalizeNarrativeEventJson(right),
      ),
    );
  final actual = [
    for (final choice in receipt.sourceChoices) choice.toJson(),
  ]..sort(
      (left, right) => canonicalizeNarrativeEventJson(left).compareTo(
        canonicalizeNarrativeEventJson(right),
      ),
    );
  if (expected.length != actual.length) return false;
  for (var index = 0; index < expected.length; index++) {
    if (canonicalizeNarrativeEventJson(expected[index]) !=
        canonicalizeNarrativeEventJson(actual[index])) {
      return false;
    }
  }
  return true;
}

List<NarrativeEventReferenceResolutionChoice> _effectiveReferenceChoices(
  NarrativeEventMigrationPlannerInput input,
  NarrativeEventMigrationReceipt? existingReceipt,
) {
  final choicesByPath = <String, NarrativeEventReferenceResolutionChoice>{
    for (final choice in input.choices.referenceChoices) choice.path: choice,
  };
  if (existingReceipt != null) {
    for (final mapping in existingReceipt.mappings.allReferenceMappings) {
      final decision = mapping.decision;
      if (mapping.status != NarrativeEventReferenceMappingStatus.mapped ||
          decision == null ||
          choicesByPath.containsKey(mapping.path) ||
          (decision ==
                  NarrativeEventReferenceCollisionDecision.selectedTargets &&
              mapping.targetEventIds.isEmpty)) {
        continue;
      }
      choicesByPath[mapping.path] = switch (decision) {
        NarrativeEventReferenceCollisionDecision.consumeAllTargets =>
          NarrativeEventReferenceResolutionChoice(
            path: mapping.path,
            decision: decision,
          ),
        NarrativeEventReferenceCollisionDecision.selectedTargets =>
          NarrativeEventReferenceResolutionChoice(
            path: mapping.path,
            decision: decision,
            selectedTargetEventIds: mapping.targetEventIds,
          ),
        NarrativeEventReferenceCollisionDecision.cancel =>
          NarrativeEventReferenceResolutionChoice(
            path: mapping.path,
            decision: decision,
          ),
      };
    }
  }
  final paths = choicesByPath.keys.toList()..sort();
  return [for (final path in paths) choicesByPath[path]!];
}

NarrativeEventMigrationChoices _effectiveMigrationChoices(
  NarrativeEventMigrationPlannerInput input,
  NarrativeEventMigrationReceipt? existingReceipt,
) {
  final sourceChoicesByProvenance =
      <LegacySourceRef, NarrativeEventMigrationSourceChoice>{
    for (final choice in input.choices.sourceChoices) choice.provenance: choice,
  };
  for (final choice in existingReceipt?.sourceChoices ??
      const <NarrativeEventMigrationSourceChoice>[]) {
    sourceChoicesByProvenance.putIfAbsent(
      choice.provenance,
      () => choice,
    );
  }
  final provenances = sourceChoicesByProvenance.keys.toList()
    ..sort(compareLegacySourceRefs);
  return NarrativeEventMigrationChoices(
    sourceChoices: [
      for (final provenance in provenances)
        sourceChoicesByProvenance[provenance]!,
    ],
    referenceChoices: input.choices.referenceChoices,
  );
}

bool _receiptTargetsMatchCurrentEvidence({
  required NarrativeEventMigrationPlannerInput input,
  required List<_Candidate> candidates,
  required NarrativeEventRegistry registry,
  required NarrativeEventMigrationReceipt receipt,
}) {
  final claimedProvenances = <LegacySourceRef>{
    for (final claim in receipt.targetClaims)
      for (final member in claim.members) member.provenance,
  };
  for (final claim in receipt.targetClaims) {
    final mappedTargetIds = <String>{};
    for (final member in claim.members) {
      final mappings = receipt.mappings.idMappings
          .where((mapping) => mapping.provenance == member.provenance)
          .toList(growable: false);
      if (mappings.length != 1 ||
          mappings.single.targetEventIds.any(
            (targetId) => !claim.targetEventIds.contains(targetId),
          )) {
        return false;
      }
      mappedTargetIds.addAll(mappings.single.targetEventIds);
    }
    if (!_sameStrings(mappedTargetIds, claim.targetEventIds.toSet())) {
      return false;
    }
  }
  final recordsById = <String, List<NarrativeEventRecord>>{};
  for (final record in registry.records) {
    recordsById.putIfAbsent(record.id, () => []).add(record);
  }
  final scenesById = <String, List<SceneAsset>>{};
  for (final scene in input.project.scenes) {
    scenesById.putIfAbsent(scene.id, () => []).add(scene);
  }
  final scenariosById = <String, List<ScenarioAsset>>{};
  for (final scenario in input.project.scenarios) {
    scenariosById.putIfAbsent(scenario.id, () => []).add(scenario);
  }

  for (final candidate in candidates) {
    if (!claimedProvenances.contains(candidate.provenance)) continue;
    final mappingMatches = receipt.mappings.idMappings
        .where((mapping) => mapping.provenance == candidate.provenance)
        .toList(growable: false);
    if (mappingMatches.length != 1) return false;
    final definitions = <NarrativeEventDefinition>[];
    for (final targetId in mappingMatches.single.targetEventIds) {
      final recordMatches =
          recordsById[targetId] ?? const <NarrativeEventRecord>[];
      if (recordMatches.length != 1 ||
          recordMatches.single.enabledOrNull == true) {
        return false;
      }
      final definition = recordMatches.single.definitionOrNull;
      final source = candidate.source;
      if (definition == null || source == null || definition.source != source) {
        return false;
      }
      final sceneMatches =
          scenesById[definition.sceneId] ?? const <SceneAsset>[];
      if (sceneMatches.length != 1 ||
          !buildSceneRuntimePlan(sceneMatches.single).canBuild) {
        return false;
      }
      definitions.add(definition);
    }
    if (definitions.isEmpty) return false;

    final valid = candidate.provenance.when(
      mapEvent: (_, __) => _receiptMapTargetsMatchCurrentEvidence(
        candidate,
        definitions,
      ),
      scenarioSourceNode: (scenarioId, nodeId) {
        final scenarioMatches =
            scenariosById[scenarioId] ?? const <ScenarioAsset>[];
        final projection = candidate.scenarioProjection;
        if (scenarioMatches.length != 1 || projection == null) return false;
        final scenario = scenarioMatches.single;
        for (final definition in definitions) {
          final scene = scenesById[definition.sceneId]!.single;
          if (!hasEquivalentLegacyScenarioSceneCandidate(
            scenario: scenario,
            sourceNodeId: nodeId,
            scene: scene,
          )) {
            return false;
          }
        }
        final targets = [
          for (final definition in definitions)
            _targetProposalFromDefinition(definition),
        ];
        switch (candidate.classification) {
          case LegacyMigrationClassification.autoSafe:
            final projected = _autoScenarioTarget(projection);
            return projected != null &&
                targets.length == 1 &&
                targets.single.recordSignature(definitions.single.source) ==
                    projected.recordSignature(definitions.single.source);
          case LegacyMigrationClassification.assisted:
            final explicitReassignment = candidate.sourceChoice?.kind ==
                NarrativeEventMigrationSourceChoiceKind.explicitReassignment;
            return (explicitReassignment ||
                    isCompatibleLegacyScenarioSourceChoice(
                      projection: projection,
                      scenario: scenario,
                      selectedSource: definitions.single.source,
                    )) &&
                _scenarioAssistedChoiceMatchesProjection(
                  projection,
                  NarrativeEventMigrationSourceChoice.confirmCandidate(
                    provenance: candidate.provenance,
                    source: definitions.single.source,
                    targets: targets,
                  ),
                );
          case LegacyMigrationClassification.blocked:
          case LegacyMigrationClassification.unsupported:
          case LegacyMigrationClassification.legacyOnly:
            return false;
        }
      },
    );
    if (!valid) return false;
  }
  return true;
}

bool _receiptMapTargetsMatchCurrentEvidence(
  _Candidate candidate,
  List<NarrativeEventDefinition> definitions,
) {
  final projection = candidate.mapProjection;
  final source = candidate.source;
  if (projection == null || source == null) return false;
  switch (candidate.classification) {
    case LegacyMigrationClassification.autoSafe:
      final projected = _autoMapTarget(projection);
      if (projected == null) return false;
      return _mapLifecycleChoiceMatches(
        NarrativeEventMigrationSourceChoice.confirmCandidate(
          provenance: candidate.provenance,
          source: source,
          targets: [
            for (final definition in definitions)
              _targetProposalFromDefinition(
                definition,
                legacyPageIndex: projected.legacyPageIndex,
              ),
          ],
        ),
        projected,
        source,
      );
    case LegacyMigrationClassification.assisted:
      return true;
    case LegacyMigrationClassification.blocked:
    case LegacyMigrationClassification.unsupported:
    case LegacyMigrationClassification.legacyOnly:
      return false;
  }
}

NarrativeEventMigrationTargetProposal _targetProposalFromDefinition(
  NarrativeEventDefinition definition, {
  int? legacyPageIndex,
}) {
  return NarrativeEventMigrationTargetProposal(
    name: definition.name,
    legacyPageIndex: legacyPageIndex,
    conditions: definition.conditions,
    sceneId: definition.sceneId,
    reusePolicy: definition.reusePolicy,
    priority: definition.priority,
    order: definition.order,
  );
}

String _corpusReferenceKind(LegacyEventReferenceKind kind) {
  return switch (kind) {
    LegacyEventReferenceKind.consumedEventState => 'GameState.consumedEventIds',
    LegacyEventReferenceKind.scriptCondition => 'ScriptCondition',
    LegacyEventReferenceKind.worldRuleSource => 'WorldRuleDefinition.source',
    LegacyEventReferenceKind.worldRuleTarget => 'WorldRuleDefinition.target',
    LegacyEventReferenceKind.sceneConsequence => 'SceneConsequence',
    LegacyEventReferenceKind.scenarioNodeBinding => 'ScenarioNodeBinding',
    LegacyEventReferenceKind.scriptCommand => 'ScriptCommand',
    LegacyEventReferenceKind.metadata => 'metadata',
    LegacyEventReferenceKind.validatorDiagnostic => 'EventSceneLinkDiagnostic',
  };
}

String _corpusCandidateLabel(LegacySourceRef provenance) {
  return provenance.when(
    mapEvent: (mapId, eventId) => '$mapId:$eventId',
    scenarioSourceNode: (scenarioId, nodeId) =>
        'scenarioSourceNode:$scenarioId:$nodeId',
  );
}

bool _sameCanonicalValues(List<Object> left, List<Object> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    final leftJson = switch (left[index]) {
      LegacySourceClaim value => value.toJson(),
      NarrativeEventRecord value => value.toJson(),
      _ => throw StateError('Unsupported canonical comparison value.'),
    };
    final rightJson = switch (right[index]) {
      LegacySourceClaim value => value.toJson(),
      NarrativeEventRecord value => value.toJson(),
      _ => throw StateError('Unsupported canonical comparison value.'),
    };
    if (canonicalizeNarrativeEventJson(leftJson) !=
        canonicalizeNarrativeEventJson(rightJson)) {
      return false;
    }
  }
  return true;
}

List<NarrativeEventPageMapping> _buildPageMappings(
  List<_Candidate> candidates,
) {
  final result = <NarrativeEventPageMapping>[];
  for (final candidate in candidates) {
    final projection = candidate.mapProjection;
    if (projection == null) continue;
    for (final page in projection.pages) {
      final targets = candidate.pageTargetIds[page.pageIndex] ?? const [];
      final canMap = candidate.resolved && targets.length == 1;
      result.add(
        NarrativeEventPageMapping(
          provenance: candidate.provenance,
          pageIndex: page.pageIndex,
          pageNumber: page.pageNumber,
          status: canMap
              ? NarrativeEventPageMappingStatus.mapped
              : NarrativeEventPageMappingStatus.preservedLegacy,
          targetEventId: canMap ? targets.single : null,
          sceneId: canMap ? page.sceneId : null,
          preservedPageJson: page.toJson(),
        ),
      );
    }
  }
  result.sort((left, right) {
    final provenance = compareLegacySourceRefs(
      left.provenance,
      right.provenance,
    );
    if (provenance != 0) return provenance;
    return left.pageIndex.compareTo(right.pageIndex);
  });
  return result;
}

void _addClassificationDiagnostic(
  _Candidate candidate,
  List<LegacyMigrationDiagnostic> diagnostics,
) {
  final path = _provenancePath(candidate.provenance);
  switch (candidate.classification) {
    case LegacyMigrationClassification.autoSafe:
      if (candidate.hardBlocked) {
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.blockedProjection,
            LegacyMigrationDiagnosticSeverity.error,
            'The AUTO_SAFE projection lacks a complete exact V2 target.',
            path,
          ),
        );
      } else if (candidate.assistancePending) {
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.lifecycleChoiceRequired,
            LegacyMigrationDiagnosticSeverity.warning,
            'The legacy MapEvent lifecycle must be chosen explicitly.',
            path,
          ),
        );
      }
    case LegacyMigrationClassification.assisted:
      if (candidate.assistancePending) {
        diagnostics.add(
          _diagnostic(
            NarrativeEventMigrationDiagnosticCodes.assistanceRequired,
            LegacyMigrationDiagnosticSeverity.warning,
            'This projection requires an explicit source or target choice.',
            path,
          ),
        );
      }
    case LegacyMigrationClassification.blocked:
      diagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes.blockedProjection,
          LegacyMigrationDiagnosticSeverity.error,
          'The legacy projection remains blocked.',
          path,
        ),
      );
    case LegacyMigrationClassification.unsupported:
      diagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes.unsupportedProjection,
          LegacyMigrationDiagnosticSeverity.error,
          'The legacy behavior is outside the V0 migration contract.',
          path,
        ),
      );
    case LegacyMigrationClassification.legacyOnly:
      diagnostics.add(
        _diagnostic(
          NarrativeEventMigrationDiagnosticCodes.legacyOnlyProjection,
          LegacyMigrationDiagnosticSeverity.error,
          'The legacy behavior must remain under its compatibility adapter.',
          path,
        ),
      );
  }
}

LegacyMigrationDiagnostic _diagnostic(
  String code,
  LegacyMigrationDiagnosticSeverity severity,
  String message,
  String path,
) {
  return LegacyMigrationDiagnostic(
    code: code,
    severity: severity,
    message: message,
    path: path,
  );
}

void _sortDiagnostics(List<LegacyMigrationDiagnostic> diagnostics) {
  diagnostics.sort((left, right) {
    var comparison = left.path.compareTo(right.path);
    if (comparison != 0) return comparison;
    comparison = left.code.compareTo(right.code);
    if (comparison != 0) return comparison;
    return left.message.compareTo(right.message);
  });
}

bool _isHardClassification(LegacyMigrationClassification value) {
  return value == LegacyMigrationClassification.blocked ||
      value == LegacyMigrationClassification.unsupported ||
      value == LegacyMigrationClassification.legacyOnly;
}

int _classificationRank(LegacyMigrationClassification value) {
  return switch (value) {
    LegacyMigrationClassification.autoSafe => 0,
    LegacyMigrationClassification.assisted => 1,
    LegacyMigrationClassification.legacyOnly => 2,
    LegacyMigrationClassification.blocked => 3,
    LegacyMigrationClassification.unsupported => 4,
  };
}

int _compareCandidates(_Candidate left, _Candidate right) =>
    compareLegacySourceRefs(left.provenance, right.provenance);

String _mapProjectionName(LegacyMapEventProjection projection) {
  final title = projection.preservedEventJson['title'];
  if (title is String && title.trim().isNotEmpty) return title.trim();
  final name = projection.preservedEventJson['name'];
  if (name is String && name.trim().isNotEmpty) return name.trim();
  return 'Legacy ${_legacyId(projection.provenance)}';
}

String _scenarioProjectionName(LegacyScenarioSourceProjection projection) {
  final name = projection.preservedScenarioJson['name'];
  if (name is String && name.trim().isNotEmpty) return name.trim();
  return 'Legacy ${projection.scenarioId}:${projection.nodeId}';
}

String _legacyId(LegacySourceRef provenance) {
  return provenance.when(
    mapEvent: (mapId, eventId) => eventId,
    scenarioSourceNode: (scenarioId, nodeId) => '$scenarioId:$nodeId',
  );
}

String _provenancePath(LegacySourceRef provenance) {
  return provenance.when(
    mapEvent: (mapId, eventId) => 'maps.$mapId.events.$eventId',
    scenarioSourceNode: (scenarioId, nodeId) =>
        'scenarios.$scenarioId.nodes.$nodeId',
  );
}

final class _Candidate {
  _Candidate({
    required this.provenance,
    required this.classification,
    required this.source,
    required this.sourceFingerprint,
    required this.choiceApplied,
    required this.assistancePending,
    required this.hardBlocked,
    required this.targets,
    required this.sourceChoice,
    this.mapProjection,
    this.scenarioProjection,
    required List<LegacyMigrationDiagnostic> diagnostics,
  }) : diagnostics = List.unmodifiable(diagnostics);

  final LegacySourceRef provenance;
  final LegacyMigrationClassification classification;
  final NarrativeEventSourceRef? source;
  final String sourceFingerprint;
  bool choiceApplied;
  bool assistancePending;
  bool hardBlocked;
  final List<NarrativeEventMigrationTargetProposal> targets;
  final NarrativeEventMigrationSourceChoice? sourceChoice;
  final LegacyMapEventProjection? mapProjection;
  final LegacyScenarioSourceProjection? scenarioProjection;
  final List<LegacyMigrationDiagnostic> diagnostics;
  List<String> targetEventIds = [];
  final Map<String, String> targetEventIdsByKey = {};
  final Map<int, List<String>> pageTargetIds = {};
  bool resolved = false;

  bool get canClaim =>
      !hardBlocked &&
      !assistancePending &&
      source != null &&
      targets.isNotEmpty &&
      targets.every((target) => target.isConfigured);

  _Candidate copyForPreflight() => _Candidate(
        provenance: provenance,
        classification: classification,
        source: source,
        sourceFingerprint: sourceFingerprint,
        choiceApplied: choiceApplied,
        assistancePending: assistancePending,
        hardBlocked: hardBlocked,
        targets: targets,
        sourceChoice: sourceChoice,
        mapProjection: mapProjection,
        scenarioProjection: scenarioProjection,
        diagnostics: diagnostics,
      );

  void addTarget(
    NarrativeEventMigrationTargetProposal target,
    String eventId,
  ) {
    if (!targetEventIds.contains(eventId)) targetEventIds.add(eventId);
    targetEventIds.sort();
    final targetSource = source;
    if (targetSource != null) {
      final targetKey = computeNarrativeEventMigrationTargetKey(
        provenance: provenance,
        targetSignature: target.recordSignature(targetSource),
      );
      targetEventIdsByKey[targetKey] = eventId;
    }
    final pageIndex = target.legacyPageIndex;
    if (pageIndex != null) {
      final targets = pageTargetIds.putIfAbsent(pageIndex, () => []);
      if (!targets.contains(eventId)) targets.add(eventId);
      targets.sort();
    }
  }

  NarrativeEventMigrationItem toPublic() {
    return NarrativeEventMigrationItem(
      provenance: provenance,
      classification: classification,
      source: source,
      sourceFingerprint: sourceFingerprint,
      choiceApplied: choiceApplied,
      choiceKind: sourceChoice?.kind,
      reassignmentReason: sourceChoice?.reassignmentReason,
      resolved: resolved,
      targetEventIds: targetEventIds,
    );
  }
}

final class _Group {
  _Group(this.source);

  final NarrativeEventSourceRef source;
  final List<_Candidate> candidates = [];
  late List<LegacySourceClaimMember> members;
  late String cohortId;
  late LegacyMigrationClassification classification;
  bool hardBlocked = false;
  LegacySourceClaim? existingClaim;
  LegacySourceClaim? proposedClaim;
  List<String> targetEventIds = [];

  bool get canProposeClaim =>
      !hardBlocked &&
      existingClaim == null &&
      candidates.isNotEmpty &&
      candidates.every((candidate) => candidate.canClaim);

  void finalize() {
    candidates.sort(_compareCandidates);
    members = [
      for (final candidate in candidates)
        LegacySourceClaimMember(
          provenance: candidate.provenance,
          sourceFingerprint: candidate.sourceFingerprint,
        ),
    ]..sort((left, right) => compareLegacySourceRefs(
          left.provenance,
          right.provenance,
        ));
    cohortId = computeLegacySourceCohortId(
      source,
      [for (final member in members) member.provenance],
    );
    classification = candidates.first.classification;
    for (final candidate in candidates.skip(1)) {
      if (_classificationRank(candidate.classification) >
          _classificationRank(classification)) {
        classification = candidate.classification;
      }
    }
    hardBlocked = candidates.any((candidate) => candidate.hardBlocked);
  }

  NarrativeEventMigrationCohort toPublic() {
    final claim = proposedClaim ?? existingClaim;
    final status = proposedClaim != null
        ? NarrativeEventMigrationCohortClaimStatus.proposed
        : existingClaim != null
            ? NarrativeEventMigrationCohortClaimStatus.existing
            : hardBlocked
                ? NarrativeEventMigrationCohortClaimStatus.blocked
                : NarrativeEventMigrationCohortClaimStatus.absent;
    return NarrativeEventMigrationCohort(
      cohortId: cohortId,
      source: source,
      members: members,
      classification: classification,
      complete: claim != null || canProposeClaim,
      claimStatus: status,
      targetEventIds: targetEventIds,
      claim: claim,
    );
  }
}
