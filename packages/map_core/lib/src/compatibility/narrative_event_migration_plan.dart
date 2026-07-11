import 'package:meta/meta.dart' show immutable;

import '../models/map_data.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/project_manifest.dart';
import '../operations/narrative_event_canonical_json.dart';
import 'legacy_event_migration_models.dart';
import 'legacy_map_event_projection.dart';
import 'legacy_scenario_source_projection.dart';
import 'narrative_event_migration_receipt.dart';
import 'narrative_event_reference_mapping.dart';

abstract final class NarrativeEventMigrationDiagnosticCodes {
  static const staleRevision = 'staleRevision';
  static const sourceHashMismatch = 'sourceHashMismatch';
  static const corpusEvidenceMismatch = 'corpusEvidenceMismatch';
  static const unknownLegacyData = 'unknownLegacyData';
  static const partialClaim = 'partialClaim';
  static const invalidExistingClaim = 'invalidExistingClaim';
  static const incompleteCohort = 'incompleteCohort';
  static const assistanceRequired = 'assistanceRequired';
  static const lifecycleChoiceRequired = 'lifecycleChoiceRequired';
  static const choiceContradictsProjection = 'choiceContradictsProjection';
  static const unusedChoice = 'unusedChoice';
  static const blockedProjection = 'blockedProjection';
  static const unsupportedProjection = 'unsupportedProjection';
  static const legacyOnlyProjection = 'legacyOnlyProjection';
  static const unresolvedReference = 'unresolvedReference';
  static const existingReceiptMismatch = 'existingReceiptMismatch';
  static const incrementalReceiptHistoryRequired =
      'incrementalReceiptHistoryRequired';
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
final class NarrativeEventMigrationTargetProposal {
  NarrativeEventMigrationTargetProposal({
    required String name,
    this.legacyPageIndex,
    required List<NarrativeEventCondition> conditions,
    String? sceneId,
    this.reusePolicy,
    required this.priority,
    required int order,
  })  : name = _identity(name.trim(), 'name'),
        conditions = List.unmodifiable(conditions),
        sceneId = _optionalIdentity(sceneId, 'sceneId'),
        order = _nonNegative(order, 'order') {
    if (legacyPageIndex != null && legacyPageIndex! < 0) {
      throw ArgumentError.value(
        legacyPageIndex,
        'legacyPageIndex',
        'must be non-negative',
      );
    }
  }

  final String name;
  final int? legacyPageIndex;
  final List<NarrativeEventCondition> conditions;
  final String? sceneId;
  final NarrativeEventReusePolicy? reusePolicy;
  final int priority;
  final int order;

  bool get isConfigured => sceneId != null && reusePolicy != null;

  String recordSignature(NarrativeEventSourceRef source) {
    return canonicalizeNarrativeEventJson({
      'name': name,
      'source': source.toJson(),
      'conditions': [for (final condition in conditions) condition.toJson()],
      if (sceneId != null) 'sceneId': sceneId,
      if (reusePolicy != null) 'reusePolicy': reusePolicy!.name,
      'priority': priority,
      'order': order,
    });
  }

  Map<String, Object?> toJson() => {
        'name': name,
        if (legacyPageIndex != null) 'legacyPageIndex': legacyPageIndex,
        'conditions': [for (final condition in conditions) condition.toJson()],
        if (sceneId != null) 'sceneId': sceneId,
        if (reusePolicy != null) 'reusePolicy': reusePolicy!.name,
        'priority': priority,
        'order': order,
      };
}

@immutable
final class NarrativeEventMigrationSourceChoice {
  NarrativeEventMigrationSourceChoice({
    required this.provenance,
    required this.source,
    required List<NarrativeEventMigrationTargetProposal> targets,
  }) : targets = List.unmodifiable(targets) {
    if (this.targets.isEmpty) {
      throw ArgumentError.value(targets, 'targets', 'must not be empty');
    }
  }

  final LegacySourceRef provenance;
  final NarrativeEventSourceRef source;
  final List<NarrativeEventMigrationTargetProposal> targets;

  Map<String, Object?> toJson() => {
        'provenance': provenance.toJson(),
        'source': source.toJson(),
        'targets': [for (final target in targets) target.toJson()],
      };
}

@immutable
final class NarrativeEventMigrationChoices {
  NarrativeEventMigrationChoices({
    List<NarrativeEventMigrationSourceChoice> sourceChoices = const [],
    List<NarrativeEventReferenceResolutionChoice> referenceChoices = const [],
  })  : sourceChoices = List.unmodifiable(sourceChoices),
        referenceChoices = List.unmodifiable(referenceChoices) {
    final provenances = <LegacySourceRef>{};
    for (final choice in this.sourceChoices) {
      if (!provenances.add(choice.provenance)) {
        throw ArgumentError.value(
          choice.provenance.toJson(),
          'sourceChoices',
          'a provenance can only have one source choice',
        );
      }
    }
    final paths = <String>{};
    for (final choice in this.referenceChoices) {
      if (!paths.add(choice.path)) {
        throw ArgumentError.value(
          choice.path,
          'referenceChoices',
          'a path can only have one reference choice',
        );
      }
    }
  }

  factory NarrativeEventMigrationChoices.empty() =>
      NarrativeEventMigrationChoices();

  final List<NarrativeEventMigrationSourceChoice> sourceChoices;
  final List<NarrativeEventReferenceResolutionChoice> referenceChoices;

  NarrativeEventMigrationSourceChoice? sourceChoiceFor(
    LegacySourceRef provenance,
  ) {
    for (final choice in sourceChoices) {
      if (choice.provenance == provenance) return choice;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
        'sourceChoices': [
          for (final choice in sourceChoices) choice.toJson(),
        ],
        'referenceChoices': [
          for (final choice in referenceChoices) choice.toJson(),
        ],
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
    required this.resolved,
    required List<String> targetEventIds,
  })  : sourceFingerprint = _identity(
          sourceFingerprint,
          'sourceFingerprint',
        ),
        targetEventIds = _sortedUnique(targetEventIds, 'targetEventIds');

  final LegacySourceRef provenance;
  final LegacyMigrationClassification classification;
  final NarrativeEventSourceRef? source;
  final String sourceFingerprint;
  final bool choiceApplied;
  final bool resolved;
  final List<String> targetEventIds;

  Map<String, Object?> toJson() => {
        'provenance': provenance.toJson(),
        'classification': classification.name,
        if (source != null) 'source': source!.toJson(),
        'sourceFingerprint': sourceFingerprint,
        'choiceApplied': choiceApplied,
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
    this.existingReceipt,
  })  : maps = List.unmodifiable(maps),
        mapEventProjections = List.unmodifiable(mapEventProjections),
        scenarioProjections = List.unmodifiable(scenarioProjections),
        characterizedCorpus = _freezeMap(characterizedCorpus),
        saveSnapshots = List.unmodifiable([
          for (final snapshot in saveSnapshots) _freezeMap(snapshot),
        ]),
        unknownLegacyData = List.unmodifiable(unknownLegacyData);

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
  final NarrativeEventMigrationReceipt? existingReceipt;
}

@immutable
final class NarrativeEventMigrationPlan {
  NarrativeEventMigrationPlan({
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
  })  : recordsProposed = _sortedRecords(recordsProposed),
        claimsProposed = _sortedClaims(claimsProposed),
        cohorts = List.unmodifiable(cohorts),
        items = List.unmodifiable(items),
        diagnostics = List.unmodifiable(diagnostics),
        unknownLegacyData = List.unmodifiable(unknownLegacyData);

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

  bool get canApply =>
      status == NarrativeEventMigrationPlanStatus.ready &&
      receiptProposal != null;

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
        'rollbackPlan': rollbackPlan.toJson(),
        'pointOfNoReturn': pointOfNoReturn.toJson(),
        'unknownLegacyData': [
          for (final value in unknownLegacyData) value.toJson(),
        ],
      };
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

int _nonNegative(int value, String name) {
  if (value < 0) {
    throw ArgumentError.value(value, name, 'must be non-negative');
  }
  return value;
}
