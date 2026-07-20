import 'dart:convert';

import 'package:meta/meta.dart' show immutable;

import '../catalogs/narrative_event_project_catalog.dart';
import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/project_manifest.dart';
import '../models/scenario_asset.dart';
import '../models/scene_asset.dart';
import '../operations/build_narrative_event_project_catalog.dart';
import '../operations/narrative_event_canonical_json.dart';
import '../operations/narrative_event_claim_fingerprints.dart';
import '../operations/narrative_event_registry_codec.dart';
import '../runtime/scene_runtime_plan_builder.dart';
import 'legacy_event_migration_models.dart';
import 'legacy_map_event_projection.dart';
import 'legacy_scenario_source_projection.dart';
import 'narrative_event_migration_choice.dart';
import 'narrative_event_migration_receipt.dart';
import 'narrative_event_migration_receipt_codec.dart';
import 'narrative_event_reference_mapping.dart';

part 'narrative_event_migration_planner_impl.dart';

abstract final class NarrativeEventMigrationDiagnosticCodes {
  static const staleRevision = 'staleRevision';
  static const sourceHashMismatch = 'sourceHashMismatch';
  static const projectionEvidenceMismatch = 'projectionEvidenceMismatch';
  static const corpusEvidenceMismatch = 'corpusEvidenceMismatch';
  static const unknownLegacyData = 'unknownLegacyData';
  static const partialClaim = 'partialClaim';
  static const invalidExistingClaim = 'invalidExistingClaim';
  static const incompleteCohort = 'incompleteCohort';
  static const assistanceRequired = 'assistanceRequired';
  static const lifecycleChoiceRequired = 'lifecycleChoiceRequired';
  static const choiceContradictsProjection = 'choiceContradictsProjection';
  static const reassignmentRequiresContextValidation =
      'reassignmentRequiresContextValidation';
  static const unusedChoice = 'unusedChoice';
  static const blockedProjection = 'blockedProjection';
  static const unsupportedProjection = 'unsupportedProjection';
  static const legacyOnlyProjection = 'legacyOnlyProjection';
  static const unresolvedReference = 'unresolvedReference';
  static const existingReceiptMismatch = 'existingReceiptMismatch';
  static const incrementalReceiptHistoryRequired =
      'incrementalReceiptHistoryRequired';
  static const validationCatalogMissing = 'validationCatalogMissing';
  static const validationCatalogMismatch = 'validationCatalogMismatch';
  static const validationCatalogDiagnostic = 'validationCatalogDiagnostic';
  static const sourceMissing = 'migrationSourceMissing';
  static const sourceUnavailable = 'migrationSourceUnavailable';
  static const sourceAmbiguous = 'migrationSourceAmbiguous';
  static const explicitReassignmentValidated = 'explicitReassignmentValidated';
  static const sceneMissing = 'migrationSceneMissing';
  static const sceneUnavailable = 'migrationSceneUnavailable';
  static const sceneAmbiguous = 'migrationSceneAmbiguous';
  static const factMissing = 'migrationFactMissing';
  static const factAmbiguous = 'migrationFactAmbiguous';
  static const eventMissing = 'migrationEventMissing';
  static const eventUnavailable = 'migrationEventUnavailable';
  static const eventAmbiguous = 'migrationEventAmbiguous';
  static const receiptStrictDecodeFailed = 'receiptStrictDecodeFailed';
}

enum NarrativeEventMigrationPlanStatus {
  empty,
  ready,
  assistanceRequired,
  blocked,
  alreadyPrepared,
}

enum NarrativeEventMigrationCohortClaimStatus {
  proposed,
  existing,
  absent,
  blocked,
}

/// Measurable project conditions required before deleting the legacy reader.
///
/// NSC-45 deliberately measures these conditions without changing runtime
/// policy. A product may remain in dual-read for as long as one criterion is
/// present; no UI should infer deprecation merely from a successful preview.
enum NarrativeEventLegacyRetirementCriterion {
  v2OnlyMode,
  noLegacyMapEvents,
  noLegacyScenarioSources,
  noLegacyClaims,
  noMigrationBlockers,
}

@immutable
final class NarrativeEventLegacyRetirementAssessment {
  NarrativeEventLegacyRetirementAssessment({
    required this.mode,
    required this.legacyMapEventCount,
    required this.legacyScenarioSourceCount,
    required this.legacyClaimCount,
    required this.migrationBlockerCount,
    required List<NarrativeEventLegacyRetirementCriterion> remainingCriteria,
  }) : remainingCriteria = List.unmodifiable(remainingCriteria);

  final EventSystemMode mode;
  final int legacyMapEventCount;
  final int legacyScenarioSourceCount;
  final int legacyClaimCount;
  final int migrationBlockerCount;
  final List<NarrativeEventLegacyRetirementCriterion> remainingCriteria;

  bool get readyToRemoveLegacyPath => remainingCriteria.isEmpty;
}

/// Product-facing impact summary derived from one attested migration plan.
///
/// Counts are intentionally explicit. In particular, [lossRiskCount] reports
/// data that the fail-closed planner refuses to discard; it never means that a
/// successful plan will silently lose those entries.
@immutable
final class NarrativeEventMigrationImpactPreview {
  const NarrativeEventMigrationImpactPreview({
    required this.claimCount,
    required this.collisionCount,
    required this.referenceCount,
    required this.unresolvedReferenceCount,
    required this.lossRiskCount,
    required this.confirmedChoiceCount,
    required this.legacyRuntimeActive,
    required this.retirement,
  });

  final int claimCount;
  final int collisionCount;
  final int referenceCount;
  final int unresolvedReferenceCount;
  final int lossRiskCount;
  final int confirmedChoiceCount;
  final bool legacyRuntimeActive;
  final NarrativeEventLegacyRetirementAssessment retirement;
}

@immutable
final class _NarrativeEventMigrationContextAttestation {
  _NarrativeEventMigrationContextAttestation._({
    required this.manifestHash,
    required Map<String, String> mapHashes,
    required List<String> proposedRecordJson,
    required String catalogJson,
  })  : mapHashes = Map.unmodifiable(mapHashes),
        _proposedRecordJson = List.unmodifiable(proposedRecordJson),
        _catalogJson = catalogJson;

  factory _NarrativeEventMigrationContextAttestation.validate({
    required NarrativeEventProjectCatalog catalog,
    required NarrativeEventMigrationSnapshot snapshot,
    required List<NarrativeEventRecord> proposedRecords,
  }) {
    final catalogEntries = [
      for (final entry in catalog.events)
        if (entry.proposed) entry,
    ];
    if (catalog.hasBlockingDiagnostics ||
        catalog.manifestHash != snapshot.manifestHash ||
        !_sameCanonicalJson(catalog.mapHashes, snapshot.mapHashes) ||
        proposedRecords.isEmpty ||
        !_sameCanonicalObjects(catalog.proposedRecords, proposedRecords) ||
        catalogEntries.length != proposedRecords.length ||
        catalogEntries.any(
          (entry) =>
              !entry.contextuallyValid ||
              !entry.applicableReferenceTarget ||
              entry.record.definitionOrNull == null ||
              entry.record.enabledOrNull != false,
        )) {
      throw ArgumentError(
        'A migration context attestation requires the exact current '
        'snapshot and contextually valid disabled proposals.',
      );
    }
    final recordJson = [
      for (final record in proposedRecords)
        canonicalizeNarrativeEventJson(record.toJson()),
    ]..sort();
    return _NarrativeEventMigrationContextAttestation._(
      manifestHash: catalog.manifestHash,
      mapHashes: catalog.mapHashes,
      proposedRecordJson: recordJson,
      catalogJson: canonicalizeNarrativeEventJson(catalog.toDebugJson()),
    );
  }

  final String manifestHash;
  final Map<String, String> mapHashes;
  final List<String> _proposedRecordJson;
  final String _catalogJson;

  bool proves({
    required NarrativeEventMigrationSnapshot snapshot,
    required List<NarrativeEventRecord> proposedRecords,
  }) {
    final recordJson = [
      for (final record in proposedRecords)
        canonicalizeNarrativeEventJson(record.toJson()),
    ]..sort();
    return _catalogJson.isNotEmpty &&
        manifestHash == snapshot.manifestHash &&
        _sameCanonicalJson(mapHashes, snapshot.mapHashes) &&
        _sameOrderedStrings(_proposedRecordJson, recordJson);
  }

  Map<String, Object?> toDebugJson() => {
        'manifestHash': manifestHash,
        'mapHashes': mapHashes,
        'proposedRecordJson': _proposedRecordJson,
      };
}

@immutable
final class NarrativeEventUnknownLegacyData {
  NarrativeEventUnknownLegacyData({
    required String path,
    required Object? value,
    this.provenance,
  })  : path = _identity(path, 'path'),
        value = _freezeJson(value);

  final String path;
  final Object? value;
  final LegacySourceRef? provenance;

  Map<String, Object?> toJson() => {
        'path': path,
        if (provenance != null) 'provenance': provenance!.toJson(),
        'value': value,
      };
}

@immutable
final class NarrativeEventMigrationItem {
  NarrativeEventMigrationItem({
    required this.provenance,
    required this.classification,
    required this.source,
    required String sourceFingerprint,
    required this.choiceApplied,
    this.choiceKind,
    this.reassignmentReason,
    required this.resolved,
    required List<String> targetEventIds,
  })  : sourceFingerprint = _identity(
          sourceFingerprint,
          'sourceFingerprint',
        ),
        targetEventIds = _sortedUnique(targetEventIds, 'targetEventIds') {
    if (choiceKind ==
            NarrativeEventMigrationSourceChoiceKind.explicitReassignment &&
        _optionalIdentity(reassignmentReason, 'reassignmentReason') == null) {
      throw ArgumentError(
        'Explicit source reassignments require a human reason.',
      );
    }
    if (choiceKind !=
            NarrativeEventMigrationSourceChoiceKind.explicitReassignment &&
        reassignmentReason != null) {
      throw ArgumentError(
        'Only explicit source reassignments can carry a reason.',
      );
    }
  }

  final LegacySourceRef provenance;
  final LegacyMigrationClassification classification;
  final NarrativeEventSourceRef? source;
  final String sourceFingerprint;
  final bool choiceApplied;
  final NarrativeEventMigrationSourceChoiceKind? choiceKind;
  final String? reassignmentReason;
  final bool resolved;
  final List<String> targetEventIds;

  Map<String, Object?> toJson() => {
        'provenance': provenance.toJson(),
        'classification': classification.name,
        if (source != null) 'source': source!.toJson(),
        'sourceFingerprint': sourceFingerprint,
        'choiceApplied': choiceApplied,
        if (choiceKind != null) 'choiceKind': choiceKind!.name,
        if (reassignmentReason != null)
          'reassignmentReason': reassignmentReason,
        'resolved': resolved,
        'targetEventIds': targetEventIds,
      };
}

@immutable
final class NarrativeEventMigrationCohort {
  NarrativeEventMigrationCohort({
    required String cohortId,
    required this.source,
    required List<LegacySourceClaimMember> members,
    required this.classification,
    required this.complete,
    required this.claimStatus,
    required List<String> targetEventIds,
    required this.claim,
  })  : cohortId = _identity(cohortId, 'cohortId'),
        members = _sortedMembers(members),
        targetEventIds = _sortedUnique(targetEventIds, 'targetEventIds') {
    if ((claimStatus == NarrativeEventMigrationCohortClaimStatus.proposed ||
            claimStatus == NarrativeEventMigrationCohortClaimStatus.existing) &&
        claim == null) {
      throw ArgumentError('Proposed and existing cohort states require claim.');
    }
    if (!complete &&
        claimStatus == NarrativeEventMigrationCohortClaimStatus.proposed) {
      throw ArgumentError('An incomplete cohort cannot propose a claim.');
    }
  }

  final String cohortId;
  final NarrativeEventSourceRef source;
  final List<LegacySourceClaimMember> members;
  final LegacyMigrationClassification classification;
  final bool complete;
  final NarrativeEventMigrationCohortClaimStatus claimStatus;
  final List<String> targetEventIds;
  final LegacySourceClaim? claim;

  Map<String, Object?> toJson() => {
        'cohortId': cohortId,
        'source': source.toJson(),
        'members': [for (final member in members) member.toJson()],
        'classification': classification.name,
        'complete': complete,
        'claimStatus': claimStatus.name,
        'targetEventIds': targetEventIds,
        if (claim != null) 'claim': claim!.toJson(),
      };
}

@immutable
final class NarrativeEventMigrationPlannerInput {
  NarrativeEventMigrationPlannerInput({
    required this.project,
    required List<MapData> maps,
    required List<LegacyMapEventProjection> mapEventProjections,
    required List<LegacyScenarioSourceProjection> scenarioProjections,
    required this.references,
    required this.currentSnapshot,
    this.expectedSnapshot,
    required this.choices,
    required Map<String, Object?> characterizedCorpus,
    required List<Map<String, Object?>> saveSnapshots,
    required List<NarrativeEventUnknownLegacyData> unknownLegacyData,
    required this.backupPlan,
    List<int>? existingReceiptJsonBytes,
    this.validationCatalog,
  })  : maps = List.unmodifiable(maps),
        mapEventProjections = List.unmodifiable(mapEventProjections),
        scenarioProjections = List.unmodifiable(scenarioProjections),
        characterizedCorpus = _freezeMap(characterizedCorpus),
        saveSnapshots = List.unmodifiable([
          for (final snapshot in saveSnapshots) _freezeMap(snapshot),
        ]),
        unknownLegacyData = List.unmodifiable(unknownLegacyData),
        existingReceiptJsonBytes = existingReceiptJsonBytes == null
            ? null
            : List.unmodifiable(existingReceiptJsonBytes);

  final ProjectManifest project;
  final List<MapData> maps;
  final List<LegacyMapEventProjection> mapEventProjections;
  final List<LegacyScenarioSourceProjection> scenarioProjections;
  final NarrativeEventReferenceCatalog references;
  final NarrativeEventMigrationSnapshot currentSnapshot;
  final NarrativeEventMigrationSnapshot? expectedSnapshot;
  final NarrativeEventMigrationChoices choices;
  final Map<String, Object?> characterizedCorpus;
  final List<Map<String, Object?>> saveSnapshots;
  final List<NarrativeEventUnknownLegacyData> unknownLegacyData;
  final NarrativeEventMigrationBackupPlan backupPlan;

  /// Original receipt wire bytes. The planner always strict-decodes these;
  /// callers cannot bypass duplicate-key and future-schema detection by
  /// supplying an already-normalized object.
  final List<int>? existingReceiptJsonBytes;
  final NarrativeEventProjectCatalog? validationCatalog;
}

@immutable
final class NarrativeEventMigrationPlan {
  NarrativeEventMigrationPlan({
    required NarrativeEventMigrationPlanStatus status,
    required List<NarrativeEventRecord> recordsProposed,
    required List<LegacySourceClaim> claimsProposed,
    required List<NarrativeEventMigrationCohort> cohorts,
    required List<NarrativeEventMigrationItem> items,
    required NarrativeEventReferenceMappings mappings,
    required List<LegacyMigrationDiagnostic> diagnostics,
    required NarrativeEventMigrationWritePreconditions writePreconditions,
    required NarrativeEventMigrationBackupPlan backupPlan,
    required NarrativeEventMigrationReceipt? receiptProposal,
    required NarrativeEventMigrationRollbackPlan rollbackPlan,
    required NarrativeEventMigrationPointOfNoReturn pointOfNoReturn,
    required List<NarrativeEventUnknownLegacyData> unknownLegacyData,
  }) : this._(
          status: status,
          recordsProposed: recordsProposed,
          claimsProposed: claimsProposed,
          cohorts: cohorts,
          items: items,
          mappings: mappings,
          diagnostics: diagnostics,
          writePreconditions: writePreconditions,
          backupPlan: backupPlan,
          receiptProposal: receiptProposal,
          rollbackPlan: rollbackPlan,
          pointOfNoReturn: pointOfNoReturn,
          unknownLegacyData: unknownLegacyData,
          contextAttestation: null,
        );

  NarrativeEventMigrationPlan._contextValidated({
    required NarrativeEventMigrationPlanStatus status,
    required List<NarrativeEventRecord> recordsProposed,
    required List<LegacySourceClaim> claimsProposed,
    required List<NarrativeEventMigrationCohort> cohorts,
    required List<NarrativeEventMigrationItem> items,
    required NarrativeEventReferenceMappings mappings,
    required List<LegacyMigrationDiagnostic> diagnostics,
    required NarrativeEventMigrationWritePreconditions writePreconditions,
    required NarrativeEventMigrationBackupPlan backupPlan,
    required NarrativeEventMigrationReceipt receiptProposal,
    required NarrativeEventMigrationRollbackPlan rollbackPlan,
    required NarrativeEventMigrationPointOfNoReturn pointOfNoReturn,
    required List<NarrativeEventUnknownLegacyData> unknownLegacyData,
    required _NarrativeEventMigrationContextAttestation contextAttestation,
  }) : this._(
          status: status,
          recordsProposed: recordsProposed,
          claimsProposed: claimsProposed,
          cohorts: cohorts,
          items: items,
          mappings: mappings,
          diagnostics: diagnostics,
          writePreconditions: writePreconditions,
          backupPlan: backupPlan,
          receiptProposal: receiptProposal,
          rollbackPlan: rollbackPlan,
          pointOfNoReturn: pointOfNoReturn,
          unknownLegacyData: unknownLegacyData,
          contextAttestation: contextAttestation,
        );

  NarrativeEventMigrationPlan._({
    required this.status,
    required List<NarrativeEventRecord> recordsProposed,
    required List<LegacySourceClaim> claimsProposed,
    required List<NarrativeEventMigrationCohort> cohorts,
    required List<NarrativeEventMigrationItem> items,
    required this.mappings,
    required List<LegacyMigrationDiagnostic> diagnostics,
    required this.writePreconditions,
    required this.backupPlan,
    required this.receiptProposal,
    required this.rollbackPlan,
    required this.pointOfNoReturn,
    required List<NarrativeEventUnknownLegacyData> unknownLegacyData,
    required _NarrativeEventMigrationContextAttestation? contextAttestation,
  })  : recordsProposed = _sortedRecords(recordsProposed),
        claimsProposed = _sortedClaims(claimsProposed),
        cohorts = List.unmodifiable(cohorts),
        items = List.unmodifiable(items),
        diagnostics = List.unmodifiable(diagnostics),
        unknownLegacyData = List.unmodifiable(unknownLegacyData),
        _contextAttestation = contextAttestation {
    if (status != NarrativeEventMigrationPlanStatus.ready &&
        contextAttestation != null) {
      throw ArgumentError(
        'Only a ready migration plan can carry a context attestation.',
      );
    }
    if (status == NarrativeEventMigrationPlanStatus.ready &&
        !_isStrongReadyState()) {
      throw ArgumentError(
        'A ready migration plan requires an exact disabled receipt closure '
        'with no blocking diagnostics, mappings, or unknown data.',
      );
    }
  }

  final NarrativeEventMigrationPlanStatus status;
  final List<NarrativeEventRecord> recordsProposed;
  final List<LegacySourceClaim> claimsProposed;
  final List<NarrativeEventMigrationCohort> cohorts;
  final List<NarrativeEventMigrationItem> items;
  final NarrativeEventReferenceMappings mappings;
  final List<LegacyMigrationDiagnostic> diagnostics;
  final NarrativeEventMigrationWritePreconditions writePreconditions;
  final NarrativeEventMigrationBackupPlan backupPlan;
  final NarrativeEventMigrationReceipt? receiptProposal;
  final NarrativeEventMigrationRollbackPlan rollbackPlan;
  final NarrativeEventMigrationPointOfNoReturn pointOfNoReturn;
  final List<NarrativeEventUnknownLegacyData> unknownLegacyData;
  final _NarrativeEventMigrationContextAttestation? _contextAttestation;

  bool get canApply =>
      status == NarrativeEventMigrationPlanStatus.ready &&
      _isStrongReadyState();

  bool _isStrongReadyState() {
    final receipt = receiptProposal;
    if (receipt == null ||
        _contextAttestation == null ||
        !_contextAttestation.proves(
          snapshot: receipt.snapshot,
          proposedRecords: recordsProposed,
        ) ||
        !receipt.isProposal ||
        receipt.lifecycle.status !=
            NarrativeEventMigrationReceiptStatus.prepared ||
        recordsProposed.isEmpty ||
        claimsProposed.isEmpty ||
        items.isEmpty ||
        items.any(
          (item) =>
              !item.resolved ||
              item.source == null ||
              item.targetEventIds.isEmpty,
        ) ||
        cohorts.isEmpty ||
        cohorts.any(
          (cohort) =>
              !cohort.complete ||
              cohort.claimStatus !=
                  NarrativeEventMigrationCohortClaimStatus.proposed ||
              cohort.claim == null ||
              cohort.targetEventIds.isEmpty,
        ) ||
        mappings.hasBlockingMappings ||
        unknownLegacyData.isNotEmpty ||
        diagnostics.any(
          (diagnostic) =>
              diagnostic.severity == LegacyMigrationDiagnosticSeverity.error,
        ) ||
        recordsProposed.any(
          (record) =>
              record.definitionOrNull == null || record.enabledOrNull != false,
        )) {
      return false;
    }
    final cohortClaims = [for (final cohort in cohorts) cohort.claim!];
    if (cohorts.any((cohort) => !_cohortMatchesClaim(cohort))) return false;
    final claimByProvenance = <LegacySourceRef, LegacySourceClaim>{};
    for (final claim in claimsProposed) {
      for (final member in claim.members) {
        if (claimByProvenance.containsKey(member.provenance)) return false;
        claimByProvenance[member.provenance] = claim;
      }
    }
    final mappingByProvenance = <LegacySourceRef, NarrativeEventIdMapping>{};
    for (final mapping in mappings.idMappings) {
      if (mappingByProvenance.containsKey(mapping.provenance)) return false;
      mappingByProvenance[mapping.provenance] = mapping;
    }
    final choiceByProvenance = {
      for (final choice in receipt.sourceChoices) choice.provenance: choice,
    };
    final itemProvenances = <LegacySourceRef>{};
    for (final item in items) {
      if (!itemProvenances.add(item.provenance)) return false;
      final claim = claimByProvenance[item.provenance];
      final mapping = mappingByProvenance[item.provenance];
      final choice = choiceByProvenance[item.provenance];
      final matchingMembers = claim?.members
              .where((value) => value.provenance == item.provenance)
              .toList(growable: false) ??
          const <LegacySourceClaimMember>[];
      if (claim == null ||
          matchingMembers.length != 1 ||
          mapping == null ||
          (item.classification != LegacyMigrationClassification.autoSafe &&
              item.classification != LegacyMigrationClassification.assisted) ||
          item.sourceFingerprint != matchingMembers.single.sourceFingerprint ||
          item.source != claim.source ||
          !_sameOrderedStrings(item.targetEventIds, mapping.targetEventIds) ||
          mapping.targetEventIds.any(
            (targetId) => !claim.targetEventIds.contains(targetId),
          ) ||
          item.choiceApplied != (choice != null)) {
        return false;
      }
      if (choice == null) {
        if (item.choiceKind != null || item.reassignmentReason != null) {
          return false;
        }
      } else if (item.source != choice.source ||
          item.choiceKind != choice.kind ||
          item.reassignmentReason != choice.reassignmentReason) {
        return false;
      }
    }
    if (itemProvenances.length != claimByProvenance.length ||
        !itemProvenances.containsAll(claimByProvenance.keys) ||
        mappingByProvenance.length != claimByProvenance.length ||
        !mappingByProvenance.keys.toSet().containsAll(claimByProvenance.keys)) {
      return false;
    }
    final claimedTargetIds = {
      for (final claim in claimsProposed) ...claim.targetEventIds,
    };
    return items.every(
          (item) => claimedTargetIds.containsAll(item.targetEventIds),
        ) &&
        _sameCanonicalObjects(recordsProposed, receipt.targetRecords) &&
        _sameCanonicalObjects(claimsProposed, receipt.targetClaims) &&
        _sameCanonicalObjects(cohortClaims, claimsProposed) &&
        _sameCanonicalJson(mappings.toJson(), receipt.mappings.toJson()) &&
        _sameCanonicalJson(
          writePreconditions.toJson(),
          receipt.writePreconditions.toJson(),
        ) &&
        _sameCanonicalJson(backupPlan.toJson(), receipt.backupPlan.toJson()) &&
        _sameCanonicalJson(
          rollbackPlan.toJson(),
          receipt.rollbackPlan.toJson(),
        ) &&
        _sameCanonicalJson(
          pointOfNoReturn.toJson(),
          receipt.pointOfNoReturn.toJson(),
        );
  }

  List<NarrativeEventRecord> get draftsProposed => List.unmodifiable([
        for (final record in recordsProposed)
          if (record.draftOrNull != null) record,
      ]);

  List<NarrativeEventMigrationItem> get autoSafeItems =>
      _itemsWith(LegacyMigrationClassification.autoSafe);
  List<NarrativeEventMigrationItem> get assistedItems =>
      _itemsWith(LegacyMigrationClassification.assisted);
  List<NarrativeEventMigrationItem> get blockedItems =>
      _itemsWith(LegacyMigrationClassification.blocked);
  List<NarrativeEventMigrationItem> get unsupportedItems =>
      _itemsWith(LegacyMigrationClassification.unsupported);
  List<NarrativeEventMigrationItem> get legacyOnlyItems =>
      _itemsWith(LegacyMigrationClassification.legacyOnly);

  List<NarrativeEventMigrationItem> _itemsWith(
    LegacyMigrationClassification classification,
  ) {
    return List.unmodifiable([
      for (final item in items)
        if (item.classification == classification) item,
    ]);
  }

  Map<String, Object?> toJson() => {
        'status': status.name,
        'canApply': canApply,
        'recordsProposed': [
          for (final record in recordsProposed) record.toJson(),
        ],
        'draftsProposed': [
          for (final record in draftsProposed) record.toJson(),
        ],
        'claimsProposed': [
          for (final claim in claimsProposed) claim.toJson(),
        ],
        'cohorts': [for (final cohort in cohorts) cohort.toJson()],
        'items': [for (final item in items) item.toJson()],
        'mappings': mappings.toJson(),
        'diagnostics': [
          for (final diagnostic in diagnostics) diagnostic.toJson(),
        ],
        'writePreconditions': writePreconditions.toJson(),
        'backupPlan': backupPlan.toJson(),
        if (receiptProposal != null)
          'receiptProposal': receiptProposal!.toJson(),
        if (_contextAttestation != null)
          'contextAttestation': _contextAttestation.toDebugJson(),
        'rollbackPlan': rollbackPlan.toJson(),
        'pointOfNoReturn': pointOfNoReturn.toJson(),
        'unknownLegacyData': [
          for (final value in unknownLegacyData) value.toJson(),
        ],
      };
}

bool _cohortMatchesClaim(NarrativeEventMigrationCohort cohort) {
  final claim = cohort.claim;
  return claim != null &&
      cohort.cohortId == claim.cohortId &&
      cohort.source == claim.source &&
      _sameOrderedStrings(cohort.targetEventIds, claim.targetEventIds) &&
      _sameCanonicalJson(
        [for (final member in cohort.members) member.toJson()],
        [for (final member in claim.members) member.toJson()],
      );
}

List<NarrativeEventRecord> _sortedRecords(
  List<NarrativeEventRecord> records,
) {
  final sorted = List<NarrativeEventRecord>.of(records)
    ..sort((left, right) => left.id.compareTo(right.id));
  return List.unmodifiable(sorted);
}

List<LegacySourceClaim> _sortedClaims(List<LegacySourceClaim> claims) {
  final sorted = List<LegacySourceClaim>.of(claims)
    ..sort((left, right) => left.cohortId.compareTo(right.cohortId));
  return List.unmodifiable(sorted);
}

bool _sameCanonicalObjects(List<Object> left, List<Object> right) {
  if (left.length != right.length) return false;
  String encode(Object value) {
    if (value is NarrativeEventRecord) {
      return canonicalizeNarrativeEventJson(value.toJson());
    }
    if (value is LegacySourceClaim) {
      return canonicalizeNarrativeEventJson(value.toJson());
    }
    throw ArgumentError.value(value, 'value', 'unsupported canonical type');
  }

  final encodedLeft = left.map(encode).toList()..sort();
  final encodedRight = right.map(encode).toList()..sort();
  for (var index = 0; index < encodedLeft.length; index++) {
    if (encodedLeft[index] != encodedRight[index]) return false;
  }
  return true;
}

bool _sameCanonicalJson(Object? left, Object? right) =>
    canonicalizeNarrativeEventJson(left) ==
    canonicalizeNarrativeEventJson(right);

bool _sameOrderedStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

List<LegacySourceClaimMember> _sortedMembers(
  List<LegacySourceClaimMember> members,
) {
  final sorted = List<LegacySourceClaimMember>.of(members)
    ..sort((left, right) => compareLegacySourceRefs(
          left.provenance,
          right.provenance,
        ));
  return List.unmodifiable(sorted);
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

Map<String, Object?> _freezeMap(Map<String, Object?> value) {
  return Map.unmodifiable({
    for (final entry in value.entries) entry.key: _freezeJson(entry.value),
  });
}

Object? _freezeJson(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is List) {
    return List.unmodifiable([for (final item in value) _freezeJson(item)]);
  }
  if (value is Map) {
    return Map.unmodifiable({
      for (final entry in value.entries)
        _jsonKey(entry.key): _freezeJson(entry.value),
    });
  }
  throw ArgumentError.value(value, 'value', 'must contain JSON values only');
}

String _jsonKey(Object? value) {
  if (value is! String) {
    throw ArgumentError.value(value, 'JSON key', 'must be a String');
  }
  return value;
}

String _identity(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}

String? _optionalIdentity(String? value, String name) {
  if (value == null) return null;
  return _identity(value, name);
}
