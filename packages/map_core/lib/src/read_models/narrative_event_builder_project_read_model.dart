import 'package:meta/meta.dart' show immutable;

import '../catalogs/narrative_event_project_catalog.dart';
import '../catalogs/narrative_outcome_event_source_catalog.dart';
import '../catalogs/narrative_spatial_event_source_catalog.dart';
import '../compatibility/legacy_event_migration_models.dart';
import '../compatibility/legacy_map_event_projection.dart';
import '../compatibility/legacy_scenario_source_projection.dart';
import '../models/map_data.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/project_manifest.dart';
import '../models/scenario_asset.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/world_rule.dart';
import '../operations/build_narrative_event_project_catalog.dart';
import '../operations/narrative_event_canonical_json.dart';
import '../operations/narrative_event_registry_codec.dart';
import 'narrative_event_read_deduplication.dart';

enum NarrativeEventProjectStatus {
  draftIncomplete,
  configuredDisabledReady,
  configuredEnabledReady,
  attentionRequired,
  sourceMissing,
  referenceInvalid,
  migrationAssistanceRequired,
  migrationBlocked,
  legacyOnly,
  unsupported,
  claimInvalid,
}

enum NarrativeEventProjectOrigin {
  v2,
  legacyMapEvent,
  legacyScenario,
  legacyClaim,
}

enum NarrativeEventProjectGroupKind {
  map,
  outcomes,
  drafts,
  missingReferences,
  legacyCompatibility,
}

enum NarrativeEventProjectSummarySeverity { info, warning, error }

@immutable
final class NarrativeEventProjectReadDiagnostic {
  NarrativeEventProjectReadDiagnostic({
    required String code,
    required this.severity,
    required String message,
  })  : code = _identity(code, 'code'),
        message = _identity(message, 'message');

  final String code;
  final NarrativeEventProjectSummarySeverity severity;
  final String message;

  Map<String, Object?> toDebugJson() => {
        'code': code,
        'severity': severity.name,
        'message': message,
      };
}

@immutable
final class NarrativeEventCompatibilityOrigin {
  NarrativeEventCompatibilityOrigin({
    required this.provenance,
    required String humanLabel,
    this.migrationReceiptId,
  }) : humanLabel = _identity(humanLabel, 'humanLabel');

  final LegacySourceRef provenance;
  final String humanLabel;
  final String? migrationReceiptId;

  String get stableKey => _canonicalKey(provenance.toJson());

  Map<String, Object?> toDebugJson() => {
        'humanLabel': humanLabel,
        'provenance': provenance.toJson(),
        if (migrationReceiptId != null)
          'migrationReceiptId': migrationReceiptId,
      };
}

@immutable
final class NarrativeEventSourceSummary {
  NarrativeEventSourceSummary({
    required this.source,
    required String humanSentence,
    required String sourceTypeLabel,
    this.mapId,
    this.mapLabel,
    required this.available,
    required String debugTechnicalLabel,
  })  : humanSentence = _identity(humanSentence, 'humanSentence'),
        sourceTypeLabel = _identity(sourceTypeLabel, 'sourceTypeLabel'),
        debugTechnicalLabel =
            _identity(debugTechnicalLabel, 'debugTechnicalLabel');

  final NarrativeEventSourceRef? source;
  final String humanSentence;
  final String sourceTypeLabel;
  final String? mapId;
  final String? mapLabel;
  final bool available;
  final String debugTechnicalLabel;

  Map<String, Object?> toDebugJson() => {
        'humanSentence': humanSentence,
        'sourceTypeLabel': sourceTypeLabel,
        'available': available,
        if (mapLabel != null) 'mapLabel': mapLabel,
        if (source != null) 'source': source!.toJson(),
        'debug': {
          if (mapId != null) 'mapId': mapId,
          'technicalLabel': debugTechnicalLabel,
        },
      };
}

@immutable
final class NarrativeEventSceneSummary {
  NarrativeEventSceneSummary({
    required this.sceneId,
    required String humanLabel,
    required this.valid,
  }) : humanLabel = _identity(humanLabel, 'humanLabel');

  final String? sceneId;
  final String humanLabel;
  final bool valid;

  Map<String, Object?> toDebugJson() => {
        'humanLabel': humanLabel,
        'valid': valid,
        if (sceneId != null) 'debugSceneId': sceneId,
      };
}

@immutable
enum NarrativeEventConditionDetailKind {
  fact,
  narrativeEventConsumed,
}

@immutable
final class NarrativeEventConditionDetailSummary {
  NarrativeEventConditionDetailSummary({
    required this.kind,
    required String targetLabel,
    required this.expectedValue,
    required this.resolved,
    required String humanLabel,
  })  : targetLabel = _identity(targetLabel, 'targetLabel'),
        humanLabel = _identity(humanLabel, 'humanLabel');

  final NarrativeEventConditionDetailKind kind;
  final String targetLabel;
  final bool expectedValue;
  final bool resolved;
  final String humanLabel;

  Map<String, Object?> toDebugJson() => {
        'kind': kind.name,
        'targetLabel': targetLabel,
        'expectedValue': expectedValue,
        'resolved': resolved,
        'humanLabel': humanLabel,
      };
}

@immutable
final class NarrativeEventConditionsSummary {
  NarrativeEventConditionsSummary({
    required this.count,
    required this.valid,
    required this.unresolvedCount,
    required String humanLabel,
    List<NarrativeEventConditionDetailSummary> details = const [],
  })  : humanLabel = _identity(humanLabel, 'humanLabel'),
        details = List.unmodifiable(details);

  final int count;
  final bool valid;
  final int unresolvedCount;
  final String humanLabel;
  final List<NarrativeEventConditionDetailSummary> details;

  Map<String, Object?> toDebugJson() => {
        'count': count,
        'valid': valid,
        'unresolvedCount': unresolvedCount,
        'humanLabel': humanLabel,
        'details': [for (final detail in details) detail.toDebugJson()],
      };
}

@immutable
final class NarrativeEventLifecycleSummary {
  NarrativeEventLifecycleSummary({
    required this.reusePolicy,
    required this.enabled,
    required String humanLabel,
    this.priority,
    this.order,
    this.activeCandidateCount = 0,
  }) : humanLabel = _identity(humanLabel, 'humanLabel');

  final NarrativeEventReusePolicy? reusePolicy;
  final bool? enabled;
  final String humanLabel;
  final int? priority;
  final int? order;
  final int activeCandidateCount;

  bool get hasActiveCompetition => activeCandidateCount > 1;

  Map<String, Object?> toDebugJson() => {
        'humanLabel': humanLabel,
        if (reusePolicy != null) 'reusePolicy': reusePolicy!.name,
        if (enabled != null) 'enabled': enabled,
        if (priority != null) 'priority': priority,
        if (order != null) 'order': order,
        'activeCandidateCount': activeCandidateCount,
      };
}

@immutable
final class NarrativeEventMigrationSummary {
  NarrativeEventMigrationSummary({
    required String humanLabel,
    this.classification,
    this.claimStatus,
    this.migrationReceiptId,
  }) : humanLabel = _identity(humanLabel, 'humanLabel');

  final String humanLabel;
  final LegacyMigrationClassification? classification;
  final LegacyProjectionClaimStatus? claimStatus;
  final String? migrationReceiptId;

  Map<String, Object?> toDebugJson() => {
        'humanLabel': humanLabel,
        if (classification != null) 'classification': classification!.name,
        if (claimStatus != null) 'claimStatus': claimStatus!.name,
        if (migrationReceiptId != null)
          'migrationReceiptId': migrationReceiptId,
      };
}

@immutable
final class NarrativeEventProjectedConsequenceSummary {
  NarrativeEventProjectedConsequenceSummary({
    required this.kind,
    required String humanLabel,
    required String debugReference,
  })  : humanLabel = _identity(humanLabel, 'humanLabel'),
        debugReference = _identity(debugReference, 'debugReference');

  final SceneConsequenceKind kind;
  final String humanLabel;
  final String debugReference;

  Map<String, Object?> toDebugJson() => {
        'kind': kind.name,
        'humanLabel': humanLabel,
        'debugReference': debugReference,
      };
}

@immutable
final class NarrativeEventProjectedWorldRuleSummary {
  NarrativeEventProjectedWorldRuleSummary({
    required String ruleId,
    required String humanLabel,
    required this.enabled,
  })  : ruleId = _identity(ruleId, 'ruleId'),
        humanLabel = _identity(humanLabel, 'humanLabel');

  final String ruleId;
  final String humanLabel;
  final bool enabled;

  Map<String, Object?> toDebugJson() => {
        'humanLabel': humanLabel,
        'enabled': enabled,
        'debugRuleId': ruleId,
      };
}

@immutable
final class NarrativeEventProjectionSummary {
  NarrativeEventProjectionSummary({
    required List<String> outcomeLabels,
    required List<NarrativeEventProjectedConsequenceSummary> consequences,
    required List<NarrativeEventProjectedWorldRuleSummary> worldRules,
    required this.readOnly,
  })  : outcomeLabels = List.unmodifiable(outcomeLabels),
        consequences = List.unmodifiable(consequences),
        worldRules = List.unmodifiable(worldRules);

  final List<String> outcomeLabels;
  final List<NarrativeEventProjectedConsequenceSummary> consequences;
  final List<NarrativeEventProjectedWorldRuleSummary> worldRules;
  final bool readOnly;

  Map<String, Object?> toDebugJson() => {
        'outcomeLabels': outcomeLabels,
        'consequences': [
          for (final consequence in consequences) consequence.toDebugJson(),
        ],
        'worldRules': [
          for (final rule in worldRules) rule.toDebugJson(),
        ],
        'readOnly': readOnly,
      };
}

@immutable
final class NarrativeEventProjectDebugFields {
  NarrativeEventProjectDebugFields({
    this.eventId,
    this.sourceTechnicalLabel,
    this.sceneId,
    required List<String> provenanceTechnicalLabels,
    required List<String> targetEventIds,
  })  : provenanceTechnicalLabels =
            List.unmodifiable(provenanceTechnicalLabels),
        targetEventIds = List.unmodifiable(targetEventIds);

  final String? eventId;
  final String? sourceTechnicalLabel;
  final String? sceneId;
  final List<String> provenanceTechnicalLabels;
  final List<String> targetEventIds;

  Map<String, Object?> toDebugJson() => {
        if (eventId != null) 'eventId': eventId,
        if (sourceTechnicalLabel != null)
          'sourceTechnicalLabel': sourceTechnicalLabel,
        if (sceneId != null) 'sceneId': sceneId,
        'provenances': provenanceTechnicalLabels,
        'targetEventIds': targetEventIds,
      };
}

@immutable
final class NarrativeEventProjectSummary {
  NarrativeEventProjectSummary({
    required String stableKey,
    required this.eventId,
    required String title,
    required this.origin,
    required this.readOnly,
    required this.enabled,
    required this.group,
    required String groupKey,
    required String groupLabel,
    required this.status,
    required this.severity,
    required this.source,
    required this.scene,
    required this.conditions,
    required this.lifecycle,
    required this.migration,
    required this.projection,
    required List<NarrativeEventCompatibilityOrigin> compatibilityOrigins,
    required List<NarrativeEventProjectReadDiagnostic> diagnostics,
    required this.debug,
  })  : stableKey = _identity(stableKey, 'stableKey'),
        title = _identity(title, 'title'),
        groupKey = _identity(groupKey, 'groupKey'),
        groupLabel = _identity(groupLabel, 'groupLabel'),
        compatibilityOrigins = List.unmodifiable(compatibilityOrigins),
        diagnostics = List.unmodifiable(diagnostics);

  final String stableKey;
  final String? eventId;
  final String title;
  final NarrativeEventProjectOrigin origin;
  final bool readOnly;
  final bool? enabled;
  final NarrativeEventProjectGroupKind group;
  final String groupKey;
  final String groupLabel;
  final NarrativeEventProjectStatus status;
  final NarrativeEventProjectSummarySeverity severity;
  final NarrativeEventSourceSummary source;
  final NarrativeEventSceneSummary scene;
  final NarrativeEventConditionsSummary conditions;
  final NarrativeEventLifecycleSummary lifecycle;
  final NarrativeEventMigrationSummary migration;
  final NarrativeEventProjectionSummary projection;
  final List<NarrativeEventCompatibilityOrigin> compatibilityOrigins;
  final List<NarrativeEventProjectReadDiagnostic> diagnostics;
  final NarrativeEventProjectDebugFields debug;

  Map<String, Object?> toDebugJson() => {
        'stableKey': stableKey,
        'title': title,
        'origin': origin.name,
        'readOnly': readOnly,
        if (enabled != null) 'enabled': enabled,
        'group': group.name,
        'status': status.name,
        'severity': severity.name,
        'source': source.toDebugJson(),
        'scene': scene.toDebugJson(),
        'conditions': conditions.toDebugJson(),
        'lifecycle': lifecycle.toDebugJson(),
        'migration': migration.toDebugJson(),
        'projection': projection.toDebugJson(),
        'compatibilityOrigins': [
          for (final value in compatibilityOrigins) value.toDebugJson(),
        ],
        'diagnostics': [
          for (final value in diagnostics) value.toDebugJson(),
        ],
        'debug': debug.toDebugJson(),
      };
}

@immutable
final class NarrativeEventProjectGroup {
  NarrativeEventProjectGroup({
    required String stableKey,
    required String label,
    required this.kind,
    required List<NarrativeEventProjectSummary> events,
  })  : stableKey = _identity(stableKey, 'stableKey'),
        label = _identity(label, 'label'),
        events = List.unmodifiable(events);

  final String stableKey;
  final String label;
  final NarrativeEventProjectGroupKind kind;
  final List<NarrativeEventProjectSummary> events;

  Map<String, Object?> toDebugJson() => {
        'stableKey': stableKey,
        'label': label,
        'kind': kind.name,
        'events': [for (final event in events) event.toDebugJson()],
      };
}

@immutable
final class NarrativeEventBuilderProjectReadModel {
  NarrativeEventBuilderProjectReadModel({
    required List<NarrativeEventProjectGroup> groups,
    required List<NarrativeEventProjectReadDiagnostic> diagnostics,
  })  : groups = List.unmodifiable(groups),
        events = List.unmodifiable([
          for (final group in groups) ...group.events,
        ]),
        _eventsByStableKey = Map.unmodifiable({
          for (final group in groups)
            for (final event in group.events) event.stableKey: event,
        }),
        diagnostics = List.unmodifiable(diagnostics);

  final List<NarrativeEventProjectGroup> groups;
  final List<NarrativeEventProjectSummary> events;
  final List<NarrativeEventProjectReadDiagnostic> diagnostics;
  final Map<String, NarrativeEventProjectSummary> _eventsByStableKey;

  NarrativeEventProjectSummary? eventByStableKey(String stableKey) =>
      _eventsByStableKey[stableKey];

  Map<String, Object?> toDebugJson() => {
        'groups': [for (final group in groups) group.toDebugJson()],
        'diagnostics': [
          for (final diagnostic in diagnostics) diagnostic.toDebugJson(),
        ],
      };
}

List<LegacyMapEventProjection> _projectCurrentLegacyMapEvents({
  required List<MapData> maps,
  required ValidatedLegacyClaimIndex claimIndex,
}) {
  return List.unmodifiable([
    for (final map in maps)
      for (final event in map.events)
        projectLegacyMapEventReadOnly(
          mapId: map.id,
          map: map,
          event: event,
          claimIndex: claimIndex,
          rawEventJson: Map<String, Object?>.from(event.toJson()),
        ),
  ]);
}

List<LegacyScenarioSourceProjection> _projectCurrentLegacyScenarioSources({
  required ProjectManifest project,
  required ValidatedLegacyClaimIndex claimIndex,
}) {
  return List.unmodifiable([
    for (final scenario in project.scenarios)
      for (final node in scenario.nodes)
        if (isLegacyScenarioSourceNode(node))
          projectLegacyScenarioSourceReadOnly(
            scenario: scenario,
            node: node,
            scenes: project.scenes,
            claimIndex: claimIndex,
          ),
  ]);
}

NarrativeEventBuilderProjectReadModel
    buildNarrativeEventBuilderProjectReadModel({
  required ProjectManifest project,
  required List<MapData> maps,
}) {
  final registry = project.eventRegistry ??
      NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: const [],
        legacyClaims: const [],
      );
  final claimIndex = buildValidatedLegacyClaimIndex(registry);
  final legacyMapEvents = _projectCurrentLegacyMapEvents(
    maps: maps,
    claimIndex: claimIndex,
  );
  final legacyScenarioSources = _projectCurrentLegacyScenarioSources(
    project: project,
    claimIndex: claimIndex,
  );
  final referencedOutcomes = <NarrativeOutcomeRef>[
    for (final projection in legacyScenarioSources)
      if (projection.source != null)
        ...projection.source!.when(
          entityInteract: (_, __) => const <NarrativeOutcomeRef>[],
          triggerEnter: (_, __) => const <NarrativeOutcomeRef>[],
          mapEnter: (_) => const <NarrativeOutcomeRef>[],
          outcomeReceived: (outcome) => [outcome],
        ),
  ];
  final catalog = buildNarrativeEventProjectCatalog(
    project: project,
    maps: maps,
    legacyProjections: legacyMapEvents,
    referencedOutcomes: referencedOutcomes,
  );
  final hasBlockingDiagnostics = catalog.hasBlockingDiagnostics;
  final indexes = _ProjectReadIndexes(
    project: project,
    catalog: catalog,
  );
  final legacyInputs = <_LegacyProjectionInput>[
    for (final projection in legacyMapEvents)
      _LegacyProjectionInput.map(projection),
    for (final projection in legacyScenarioSources)
      _LegacyProjectionInput.scenario(projection),
  ]..sort(_compareLegacyInputs);
  final projectionsByProvenance = _groupBy(
    legacyInputs,
    (input) => input.provenance,
  );
  final projectDiagnostics = <NarrativeEventProjectReadDiagnostic>[
    for (final diagnostic in catalog.diagnostics)
      NarrativeEventProjectReadDiagnostic(
        code: diagnostic.code,
        severity: _projectDiagnosticSeverity(diagnostic.severity),
        message: diagnostic.message,
      ),
    for (final message in claimIndex.globalConflicts)
      NarrativeEventProjectReadDiagnostic(
        code: 'legacyClaimConflict',
        severity: NarrativeEventProjectSummarySeverity.error,
        message: _humanClaimIssue(message),
      ),
    for (final entry in projectionsByProvenance.entries)
      if (entry.value.length > 1)
        NarrativeEventProjectReadDiagnostic(
          code: 'duplicateLegacyProjection',
          severity: NarrativeEventProjectSummarySeverity.error,
          message: 'Une même origine existante possède plusieurs lectures.',
        ),
  ];

  final originsByEventId = <String, List<NarrativeEventCompatibilityOrigin>>{};
  final invalidClaims = <_InvalidClaimInput>[];
  if (claimIndex.globalConflicts.isEmpty) {
    for (final claim in registry.legacyClaims) {
      final evidenceIssues = _claimProjectionEvidenceIssues(
        claim,
        claimIndex: claimIndex,
        projectionsByProvenance: projectionsByProvenance,
      );
      if (evidenceIssues.isEmpty) {
        for (final eventId in claim.targetEventIds) {
          originsByEventId.putIfAbsent(eventId, () => []).addAll([
            for (final member in claim.members)
              _compatibilityOrigin(
                member.provenance,
                project: project,
                migrationReceiptId: claim.migrationReceiptId,
              ),
          ]);
        }
      } else {
        invalidClaims.add(
          _InvalidClaimInput(claim: claim, evidenceIssues: evidenceIssues),
        );
      }
    }
  }
  for (final origins in originsByEventId.values) {
    origins.sort(_compareCompatibilityOrigins);
  }

  final summaries = <NarrativeEventProjectSummary>[
    for (final entry in catalog.events)
      if (!entry.proposed)
        _buildV2Summary(
          entry: entry,
          hasBlockingDiagnostics: hasBlockingDiagnostics,
          indexes: indexes,
          compatibilityOrigins: originsByEventId[entry.record.id] ?? const [],
        ),
  ];

  if (claimIndex.globalConflicts.isNotEmpty) {
    summaries.add(
      _buildGlobalClaimConflictSummary(
        claims: registry.legacyClaims,
        messages: claimIndex.globalConflicts,
        project: project,
      ),
    );
  } else {
    invalidClaims.sort(_compareInvalidClaims);
    for (final input in invalidClaims) {
      summaries.add(
        _buildInvalidClaimSummary(
          claim: input.claim,
          claimIndex: claimIndex,
          additionalMessages: input.evidenceIssues,
          project: project,
        ),
      );
    }
  }

  final claimedProvenances = <LegacySourceRef>{
    for (final claim in registry.legacyClaims)
      for (final member in claim.members) member.provenance,
  };
  final seenLegacy = <String>{};
  for (final input in legacyInputs) {
    final provenanceKey = _canonicalKey(input.provenance.toJson());
    if (claimedProvenances.contains(input.provenance) ||
        !seenLegacy.add(provenanceKey)) {
      continue;
    }
    final sameProvenance =
        projectionsByProvenance[input.provenance] ?? const [];
    if (sameProvenance.length != 1 ||
        input.claimStatus != LegacyProjectionClaimStatus.absent) {
      summaries.add(
        _buildProjectionIntegritySummary(
          inputs: sameProvenance,
          project: project,
        ),
      );
      continue;
    }
    summaries.add(
      input.when(
        map: (projection) => _buildLegacyMapSummary(
          projection: projection,
          project: project,
          indexes: indexes,
        ),
        scenario: (projection) => _buildLegacyScenarioSummary(
          projection: projection,
          project: project,
          indexes: indexes,
        ),
      ),
    );
  }

  final groupsByKey = <String, List<NarrativeEventProjectSummary>>{};
  for (final summary in summaries) {
    groupsByKey.putIfAbsent(summary.groupKey, () => []).add(summary);
  }
  final groups = <NarrativeEventProjectGroup>[];
  for (final entry in groupsByKey.entries) {
    final events = entry.value..sort(_compareSummaries);
    groups.add(
      NarrativeEventProjectGroup(
        stableKey: entry.key,
        label: events.first.groupLabel,
        kind: events.first.group,
        events: events,
      ),
    );
  }
  groups.sort(_compareGroups);
  return NarrativeEventBuilderProjectReadModel(
    groups: groups,
    diagnostics: _deduplicateDiagnostics(projectDiagnostics),
  );
}

NarrativeEventProjectSummary _buildV2Summary({
  required NarrativeEventProjectEventEntry entry,
  required bool hasBlockingDiagnostics,
  required _ProjectReadIndexes indexes,
  required List<NarrativeEventCompatibilityOrigin> compatibilityOrigins,
}) {
  final record = entry.record;
  final draft = record.draftOrNull;
  final definition = record.definitionOrNull;
  final sourceRef = definition?.source ?? draft?.source;
  final resolvedSource = sourceRef == null
      ? _ResolvedSource.unconfigured()
      : indexes.resolveSource(sourceRef);
  final sceneId = definition?.sceneId ?? draft?.sceneId;
  final scene = indexes.sceneSummary(sceneId);
  final conditions = indexes.conditionsSummary(
    definition?.conditions ?? draft?.conditions ?? const [],
  );
  final lifecycle = _lifecycleSummary(
    definition?.reusePolicy ?? draft?.reusePolicy,
    enabled: record.enabledOrNull,
    priority: definition?.priority ?? draft?.priority,
    order: definition?.order ?? draft?.order,
    activeCandidateCount: indexes.activeCandidateCount(sourceRef),
  );
  final diagnostics = indexes.diagnosticsForEvent(record.id);

  final status = _v2Status(
    entry: entry,
    hasBlockingDiagnostics: hasBlockingDiagnostics,
    sourceStatus: resolvedSource.status,
    sceneSelected: sceneId != null,
    sceneValid: scene.valid,
    conditionsValid: conditions.valid,
  );
  final group = _v2Group(
    draft: draft,
    resolvedSource: resolvedSource,
    status: status,
  );
  final title = (definition?.name ?? draft?.name ?? '').trim();
  return NarrativeEventProjectSummary(
    stableKey: 'v2:${record.id}',
    eventId: record.id,
    title: title.isEmpty ? 'Événement sans nom' : title,
    origin: NarrativeEventProjectOrigin.v2,
    readOnly: false,
    enabled: record.enabledOrNull,
    group: group.kind,
    groupKey: group.key,
    groupLabel: group.label,
    status: status,
    severity: _statusSeverity(status),
    source: resolvedSource.summary,
    scene: scene,
    conditions: conditions,
    lifecycle: lifecycle,
    migration: NarrativeEventMigrationSummary(
      humanLabel: compatibilityOrigins.isEmpty
          ? draft == null
              ? 'Créé dans l’éditeur d’événements.'
              : 'Configuration en cours.'
          : 'Origines existantes liées en lecture seule.',
      claimStatus: compatibilityOrigins.isEmpty
          ? null
          : LegacyProjectionClaimStatus.valid,
    ),
    projection: indexes.projectionSummary(sceneId),
    compatibilityOrigins: compatibilityOrigins,
    diagnostics: diagnostics,
    debug: NarrativeEventProjectDebugFields(
      eventId: record.id,
      sourceTechnicalLabel:
          sourceRef == null ? null : _canonicalKey(sourceRef.toJson()),
      sceneId: sceneId,
      provenanceTechnicalLabels: [
        for (final origin in compatibilityOrigins) origin.stableKey,
      ],
      targetEventIds: const [],
    ),
  );
}

NarrativeEventProjectSummary _buildInvalidClaimSummary({
  required LegacySourceClaim claim,
  required ValidatedLegacyClaimIndex claimIndex,
  required List<String> additionalMessages,
  required ProjectManifest project,
}) {
  final origins = [
    for (final member in claim.members)
      _compatibilityOrigin(
        member.provenance,
        project: project,
        migrationReceiptId: claim.migrationReceiptId,
      ),
  ]..sort(_compareCompatibilityOrigins);
  final messages = <String>{
    ...claimIndex.invalidBySource[claim.source] ?? const [],
    for (final member in claim.members)
      ...claimIndex.invalidByProvenance[member.provenance] ?? const [],
    ...claimIndex.globalConflicts,
    ...additionalMessages,
  };
  return _buildClaimBlockerSummary(
    stableKey: 'claim:${claim.cohortId}',
    title: 'Migration à réparer',
    origins: origins,
    sourceTechnicalLabel: _canonicalKey(claim.source.toJson()),
    migrationReceiptId: claim.migrationReceiptId,
    targetEventIds: claim.targetEventIds,
    messages: messages,
  );
}

NarrativeEventProjectSummary _buildGlobalClaimConflictSummary({
  required List<LegacySourceClaim> claims,
  required List<String> messages,
  required ProjectManifest project,
}) {
  final originsByKey = <String, NarrativeEventCompatibilityOrigin>{};
  final targetEventIds = <String>{};
  for (final claim in claims) {
    targetEventIds.addAll(claim.targetEventIds);
    for (final member in claim.members) {
      final origin = _compatibilityOrigin(
        member.provenance,
        project: project,
        migrationReceiptId: claim.migrationReceiptId,
      );
      originsByKey.putIfAbsent(origin.stableKey, () => origin);
    }
  }
  final origins = originsByKey.values.toList()
    ..sort(_compareCompatibilityOrigins);
  final sortedTargets = targetEventIds.toList()
    ..sort(compareNarrativeEventUtf16);
  return _buildClaimBlockerSummary(
    stableKey: 'claim:global',
    title: 'Conflit de migration à réparer',
    origins: origins,
    sourceTechnicalLabel: 'multiple-conflicting-claims',
    targetEventIds: sortedTargets,
    messages: messages,
  );
}

NarrativeEventProjectSummary _buildProjectionIntegritySummary({
  required List<_LegacyProjectionInput> inputs,
  required ProjectManifest project,
}) {
  final first = inputs.first;
  final origin = _compatibilityOrigin(
    first.provenance,
    project: project,
  );
  final duplicate = inputs.length > 1;
  return _buildClaimBlockerSummary(
    stableKey: 'projection:${origin.stableKey}',
    title: 'Origine existante à vérifier',
    origins: [origin],
    sourceTechnicalLabel: first.source == null
        ? _canonicalKey(first.provenance.toJson())
        : _canonicalKey(first.source!.toJson()),
    targetEventIds: const [],
    messages: [
      duplicate
          ? 'Une même origine possède plusieurs lectures concurrentes.'
          : 'La lecture actuelle ne correspond à aucun lien de migration valide.',
    ],
  );
}

NarrativeEventProjectSummary _buildClaimBlockerSummary({
  required String stableKey,
  required String title,
  required List<NarrativeEventCompatibilityOrigin> origins,
  required String sourceTechnicalLabel,
  String? migrationReceiptId,
  required List<String> targetEventIds,
  required Iterable<String> messages,
}) {
  final diagnostics = <NarrativeEventProjectReadDiagnostic>[
    NarrativeEventProjectReadDiagnostic(
      code: 'legacyClaimInvalid',
      severity: NarrativeEventProjectSummarySeverity.error,
      message: 'Ce lien de migration doit être réparé avant toute utilisation.',
    ),
    for (final message in messages)
      NarrativeEventProjectReadDiagnostic(
        code: 'legacyClaimInvalidDetail',
        severity: NarrativeEventProjectSummarySeverity.error,
        message: _humanClaimIssue(message),
      ),
  ];
  return NarrativeEventProjectSummary(
    stableKey: stableKey,
    eventId: null,
    title: title,
    origin: NarrativeEventProjectOrigin.legacyClaim,
    readOnly: true,
    enabled: null,
    group: NarrativeEventProjectGroupKind.legacyCompatibility,
    groupKey: 'legacy:compatibility',
    groupLabel: 'Compatibilité existante',
    status: NarrativeEventProjectStatus.claimInvalid,
    severity: NarrativeEventProjectSummarySeverity.error,
    source: NarrativeEventSourceSummary(
      source: null,
      humanSentence: 'Lien de compatibilité invalide — vérification requise.',
      sourceTypeLabel: 'Compatibilité',
      available: false,
      debugTechnicalLabel: sourceTechnicalLabel,
    ),
    scene: NarrativeEventSceneSummary(
      sceneId: null,
      humanLabel: 'Configuration liée indisponible',
      valid: false,
    ),
    conditions: NarrativeEventConditionsSummary(
      count: 0,
      valid: false,
      unresolvedCount: 1,
      humanLabel: 'Vérification de migration requise',
    ),
    lifecycle: NarrativeEventLifecycleSummary(
      reusePolicy: null,
      enabled: null,
      humanLabel: 'Non applicable tant que le lien est invalide',
    ),
    migration: NarrativeEventMigrationSummary(
      humanLabel:
          'Lien de migration invalide ou supprimé, conservé en lecture seule.',
      claimStatus: LegacyProjectionClaimStatus.invalid,
      migrationReceiptId: migrationReceiptId,
    ),
    projection: NarrativeEventProjectionSummary(
      outcomeLabels: const [],
      consequences: const [],
      worldRules: const [],
      readOnly: true,
    ),
    compatibilityOrigins: origins,
    diagnostics: _deduplicateDiagnostics(diagnostics),
    debug: NarrativeEventProjectDebugFields(
      sourceTechnicalLabel: sourceTechnicalLabel,
      sceneId: null,
      provenanceTechnicalLabels: [
        for (final origin in origins) origin.stableKey,
      ],
      targetEventIds: targetEventIds,
    ),
  );
}

NarrativeEventProjectSummary _buildLegacyMapSummary({
  required LegacyMapEventProjection projection,
  required ProjectManifest project,
  required _ProjectReadIndexes indexes,
}) {
  final titleValue = projection.preservedEventJson['title'];
  final title = titleValue is String && titleValue.trim().isNotEmpty
      ? titleValue.trim()
      : 'Événement existant';
  final confirmedSource = projection.confirmedSource;
  final source = confirmedSource == null
      ? _ResolvedSource.unconfigured(
          sentence: 'Source à confirmer avant migration.',
          typeLabel: 'Événement existant',
          debugLabel: _canonicalKey(projection.provenance.toJson()),
        )
      : indexes.resolveSource(confirmedSource);
  final sceneIds = {
    for (final page in projection.pages)
      if (page.sceneId != null) page.sceneId!,
  };
  final scene = sceneIds.length == 1
      ? indexes.sceneSummary(sceneIds.single)
      : NarrativeEventSceneSummary(
          sceneId: null,
          humanLabel: sceneIds.isEmpty
              ? 'Scene à choisir'
              : 'Plusieurs Scenes existantes à vérifier',
          valid: false,
        );
  final conditionCount =
      projection.pages.where((page) => page.condition != null).length;
  final referencesValid =
      source.status == _ReferenceStatus.found && scene.valid;
  final effectiveClassification = referencesValid
      ? projection.classification
      : LegacyMigrationClassification.blocked;
  final status = _legacyStatus(effectiveClassification);
  final origin = _compatibilityOrigin(
    projection.provenance,
    project: project,
  );
  return _legacySummary(
    stableKey: 'legacy:${origin.stableKey}',
    title: title,
    origin: NarrativeEventProjectOrigin.legacyMapEvent,
    status: status,
    source: source.summary,
    scene: scene,
    conditions: NarrativeEventConditionsSummary(
      count: conditionCount,
      valid: effectiveClassification == LegacyMigrationClassification.autoSafe,
      unresolvedCount:
          effectiveClassification == LegacyMigrationClassification.autoSafe
              ? 0
              : conditionCount,
      humanLabel: _conditionLabel(conditionCount),
    ),
    lifecycle: NarrativeEventLifecycleSummary(
      reusePolicy: null,
      enabled: null,
      humanLabel: 'Comportement géré par le système existant',
    ),
    migration: NarrativeEventMigrationSummary(
      humanLabel: _legacyMigrationLabel(effectiveClassification),
      classification: effectiveClassification,
      claimStatus: LegacyProjectionClaimStatus.absent,
    ),
    projection: indexes.projectionSummary(
      sceneIds.length == 1 ? sceneIds.single : null,
    ),
    compatibilityOrigins: [origin],
    diagnostics: _deduplicateDiagnostics([
      ..._legacyDiagnostics(projection.diagnostics),
      if (source.status != _ReferenceStatus.found)
        NarrativeEventProjectReadDiagnostic(
          code: 'legacySourceUnavailable',
          severity: NarrativeEventProjectSummarySeverity.error,
          message: 'La source existante doit être choisie ou réparée.',
        ),
      if (!scene.valid)
        NarrativeEventProjectReadDiagnostic(
          code: 'legacySceneUnavailable',
          severity: NarrativeEventProjectSummarySeverity.error,
          message: 'Une Scene valide doit être choisie.',
        ),
    ]),
    debugSource: confirmedSource,
  );
}

NarrativeEventProjectSummary _buildLegacyScenarioSummary({
  required LegacyScenarioSourceProjection projection,
  required ProjectManifest project,
  required _ProjectReadIndexes indexes,
}) {
  final scenario = indexes.scenariosById[projection.scenarioId];
  final scenarioName = scenario?.name.trim();
  final title = scenarioName == null || scenarioName.isEmpty
      ? 'Parcours existant'
      : scenarioName;
  final source = projection.source == null
      ? _ResolvedSource.unconfigured(
          sentence: 'Source à confirmer avant migration.',
          typeLabel: 'Parcours existant',
          debugLabel: _canonicalKey(projection.provenance.toJson()),
        )
      : indexes.resolveSource(projection.source!);
  final scene = indexes.sceneSummary(projection.sceneCandidateId);
  final referencesValid =
      source.status == _ReferenceStatus.found && scene.valid;
  final effectiveClassification = referencesValid
      ? projection.classification
      : LegacyMigrationClassification.blocked;
  final status = _legacyStatus(effectiveClassification);
  final origin = _compatibilityOrigin(
    projection.provenance,
    project: project,
  );
  return _legacySummary(
    stableKey: 'legacy:${origin.stableKey}',
    title: title,
    origin: NarrativeEventProjectOrigin.legacyScenario,
    status: status,
    source: source.summary,
    scene: scene,
    conditions: NarrativeEventConditionsSummary(
      count: projection.conditions.length,
      valid: effectiveClassification == LegacyMigrationClassification.autoSafe,
      unresolvedCount:
          effectiveClassification == LegacyMigrationClassification.autoSafe
              ? 0
              : projection.conditions.length,
      humanLabel: _conditionLabel(projection.conditions.length),
    ),
    lifecycle: _lifecycleSummary(
      projection.reusePolicyCandidate,
      enabled: null,
    ),
    migration: NarrativeEventMigrationSummary(
      humanLabel: _legacyMigrationLabel(effectiveClassification),
      classification: effectiveClassification,
      claimStatus: LegacyProjectionClaimStatus.absent,
    ),
    projection: indexes.projectionSummary(projection.sceneCandidateId),
    compatibilityOrigins: [origin],
    diagnostics: _deduplicateDiagnostics([
      ..._legacyDiagnostics(projection.diagnostics),
      if (source.status != _ReferenceStatus.found)
        NarrativeEventProjectReadDiagnostic(
          code: 'legacySourceUnavailable',
          severity: NarrativeEventProjectSummarySeverity.error,
          message: 'La source existante doit être choisie ou réparée.',
        ),
      if (!scene.valid)
        NarrativeEventProjectReadDiagnostic(
          code: 'legacySceneUnavailable',
          severity: NarrativeEventProjectSummarySeverity.error,
          message: 'Une Scene valide doit être choisie.',
        ),
    ]),
    debugSource: projection.source,
  );
}

NarrativeEventProjectSummary _legacySummary({
  required String stableKey,
  required String title,
  required NarrativeEventProjectOrigin origin,
  required NarrativeEventProjectStatus status,
  required NarrativeEventSourceSummary source,
  required NarrativeEventSceneSummary scene,
  required NarrativeEventConditionsSummary conditions,
  required NarrativeEventLifecycleSummary lifecycle,
  required NarrativeEventMigrationSummary migration,
  required NarrativeEventProjectionSummary projection,
  required List<NarrativeEventCompatibilityOrigin> compatibilityOrigins,
  required List<NarrativeEventProjectReadDiagnostic> diagnostics,
  required NarrativeEventSourceRef? debugSource,
}) {
  return NarrativeEventProjectSummary(
    stableKey: stableKey,
    eventId: null,
    title: title,
    origin: origin,
    readOnly: true,
    enabled: null,
    group: NarrativeEventProjectGroupKind.legacyCompatibility,
    groupKey: 'legacy:compatibility',
    groupLabel: 'Compatibilité existante',
    status: status,
    severity: _statusSeverity(status),
    source: source,
    scene: scene,
    conditions: conditions,
    lifecycle: lifecycle,
    migration: migration,
    projection: projection,
    compatibilityOrigins: compatibilityOrigins,
    diagnostics: diagnostics,
    debug: NarrativeEventProjectDebugFields(
      sourceTechnicalLabel:
          debugSource == null ? null : _canonicalKey(debugSource.toJson()),
      sceneId: scene.sceneId,
      provenanceTechnicalLabels: [
        for (final value in compatibilityOrigins) value.stableKey,
      ],
      targetEventIds: const [],
    ),
  );
}

final class _ProjectReadIndexes {
  _ProjectReadIndexes({
    required this.project,
    required this.catalog,
  })  : mapLabelsById = {
          for (final map in project.maps)
            map.id: _display(map.name, fallback: map.id),
        },
        scenariosById = {
          for (final scenario in project.scenarios) scenario.id: scenario,
        },
        _spatialBySource = _groupByPresent(
          catalog.spatialSources.options,
          (option) => option.source,
        ),
        _outcomeBySource = _groupByPresent(
          catalog.outcomeSources.options,
          (option) => option.outcome == null
              ? null
              : NarrativeEventSourceRef.outcomeReceived(option.outcome!),
        ),
        _scenesById = _groupBy(
          catalog.scenes,
          (entry) => entry.scene.id,
        ),
        _factsById = _groupBy(
          catalog.facts,
          (entry) => entry.fact.id,
        ),
        _eventsById = _groupBy(
          catalog.events,
          (entry) => entry.record.id,
        ),
        _activeCandidateCountsBySource =
            _buildActiveCandidateCounts(catalog.events),
        _diagnosticsByEventId = _indexProjectDiagnosticsByEvent(
          catalog.diagnostics,
        ),
        _projectionsBySceneId = _buildSceneProjectionIndex(
          project: project,
          catalog: catalog,
        );

  final ProjectManifest project;
  final NarrativeEventProjectCatalog catalog;
  final Map<String, String> mapLabelsById;
  final Map<String, ScenarioAsset> scenariosById;
  final Map<NarrativeEventSourceRef, List<NarrativeSpatialEventSourceOption>>
      _spatialBySource;
  final Map<NarrativeEventSourceRef, List<NarrativeOutcomeEventSourceOption>>
      _outcomeBySource;
  final Map<String, List<NarrativeEventProjectSceneEntry>> _scenesById;
  final Map<String, List<NarrativeEventProjectFactEntry>> _factsById;
  final Map<String, List<NarrativeEventProjectEventEntry>> _eventsById;
  final Map<NarrativeEventSourceRef, int> _activeCandidateCountsBySource;
  final Map<String, List<NarrativeEventProjectReadDiagnostic>>
      _diagnosticsByEventId;
  final Map<String, NarrativeEventProjectionSummary> _projectionsBySceneId;

  _ResolvedSource resolveSource(NarrativeEventSourceRef source) {
    final spatial = _spatialBySource[source] ?? const [];
    final outcomes = _outcomeBySource[source] ?? const [];
    final matchCount = spatial.length + outcomes.length;
    if (matchCount > 1) {
      return _ResolvedSource(
        status: _ReferenceStatus.ambiguous,
        summary: _missingSourceSummary(
          source,
          mapLabelsById: mapLabelsById,
          reason: 'Plusieurs sources correspondent — correction requise.',
        ),
      );
    }
    if (spatial.length == 1) {
      final option = spatial.single;
      return _ResolvedSource(
        status: option.selectable
            ? _ReferenceStatus.found
            : _ReferenceStatus.unavailable,
        summary: NarrativeEventSourceSummary(
          source: source,
          humanSentence: option.humanDescription,
          sourceTypeLabel: option.sourceTypeLabel,
          mapId: option.mapId,
          mapLabel: option.mapLabel,
          available: option.selectable,
          debugTechnicalLabel: option.debugTechnicalLabel,
        ),
      );
    }
    if (outcomes.length == 1) {
      final option = outcomes.single;
      return _ResolvedSource(
        status: option.selectable
            ? _ReferenceStatus.found
            : _ReferenceStatus.unavailable,
        summary: NarrativeEventSourceSummary(
          source: source,
          humanSentence: option.humanSourceSentence,
          sourceTypeLabel: 'Résultat',
          available: option.selectable,
          debugTechnicalLabel: option.debugTechnicalLabel,
        ),
      );
    }
    return _ResolvedSource(
      status: _ReferenceStatus.missing,
      summary: _missingSourceSummary(
        source,
        mapLabelsById: mapLabelsById,
      ),
    );
  }

  NarrativeEventSceneSummary sceneSummary(String? sceneId) {
    if (sceneId == null) {
      return NarrativeEventSceneSummary(
        sceneId: null,
        humanLabel: 'Scene à choisir',
        valid: false,
      );
    }
    final matches = _scenesById[sceneId] ?? const [];
    if (matches.length != 1) {
      return NarrativeEventSceneSummary(
        sceneId: sceneId,
        humanLabel: matches.isEmpty
            ? 'Scene introuvable'
            : 'Plusieurs Scenes portent ce nom technique',
        valid: false,
      );
    }
    final entry = matches.single;
    return NarrativeEventSceneSummary(
      sceneId: sceneId,
      humanLabel: _display(entry.scene.name, fallback: 'Scene sans nom'),
      valid: entry.buildable,
    );
  }

  NarrativeEventConditionsSummary conditionsSummary(
    List<NarrativeEventCondition> conditions,
  ) {
    var unresolved = 0;
    final details = <NarrativeEventConditionDetailSummary>[];
    for (final condition in conditions) {
      condition.when<void>(
        fact: (factId, expectedValue) {
          final matches = _factsById[factId] ?? const [];
          final resolved = matches.length == 1;
          if (!resolved) unresolved++;
          final label = resolved
              ? _display(matches.single.fact.label, fallback: 'Fact lié')
              : 'Fact introuvable';
          details.add(
            NarrativeEventConditionDetailSummary(
              kind: NarrativeEventConditionDetailKind.fact,
              targetLabel: label,
              expectedValue: expectedValue,
              resolved: resolved,
              humanLabel: '$label = ${expectedValue ? 'vrai' : 'faux'}',
            ),
          );
        },
        narrativeEventConsumed: (eventId, expectedValue) {
          final matches = _eventsById[eventId] ?? const [];
          final resolved =
              matches.length == 1 && matches.single.applicableReferenceTarget;
          if (!resolved) unresolved++;
          final record = matches.length == 1 ? matches.single.record : null;
          final label = resolved
              ? _display(
                  record!.definitionOrNull?.name ??
                      record.draftOrNull?.name ??
                      '',
                  fallback: 'Événement lié',
                )
              : 'Événement introuvable';
          details.add(
            NarrativeEventConditionDetailSummary(
              kind: NarrativeEventConditionDetailKind.narrativeEventConsumed,
              targetLabel: label,
              expectedValue: expectedValue,
              resolved: resolved,
              humanLabel: '$label = ${expectedValue ? 'joué' : 'non joué'}',
            ),
          );
        },
      );
    }
    return NarrativeEventConditionsSummary(
      count: conditions.length,
      valid: unresolved == 0,
      unresolvedCount: unresolved,
      humanLabel: unresolved == 0
          ? _conditionLabel(conditions.length)
          : '$unresolved référence${unresolved == 1 ? '' : 's'} à corriger',
      details: details,
    );
  }

  int activeCandidateCount(NarrativeEventSourceRef? source) {
    if (source == null) return 0;
    return _activeCandidateCountsBySource[source] ?? 0;
  }

  List<NarrativeEventProjectReadDiagnostic> diagnosticsForEvent(
    String eventId,
  ) =>
      _diagnosticsByEventId[eventId] ?? const [];

  NarrativeEventProjectionSummary projectionSummary(String? sceneId) {
    return _projectionsBySceneId[sceneId] ??
        NarrativeEventProjectionSummary(
          outcomeLabels: const [],
          consequences: const [],
          worldRules: const [],
          readOnly: true,
        );
  }
}

Map<String, List<NarrativeEventProjectReadDiagnostic>>
    _indexProjectDiagnosticsByEvent(
  List<NarrativeEventProjectDiagnostic> diagnostics,
) {
  const prefix = 'eventRegistry.records.';
  final result = <String, List<NarrativeEventProjectReadDiagnostic>>{};
  for (final diagnostic in diagnostics) {
    if (!diagnostic.path.startsWith(prefix)) continue;
    final remainder = diagnostic.path.substring(prefix.length);
    final separator = remainder.indexOf('.');
    final eventId =
        separator < 0 ? remainder : remainder.substring(0, separator);
    if (eventId.isEmpty) continue;
    result.putIfAbsent(eventId, () => []).add(
          NarrativeEventProjectReadDiagnostic(
            code: diagnostic.code,
            severity: _projectDiagnosticSeverity(diagnostic.severity),
            message: diagnostic.message,
          ),
        );
  }
  return {
    for (final entry in result.entries)
      entry.key: _deduplicateDiagnostics(entry.value),
  };
}

Map<String, NarrativeEventProjectionSummary> _buildSceneProjectionIndex({
  required ProjectManifest project,
  required NarrativeEventProjectCatalog catalog,
}) {
  final outcomesBySceneId = <String, Set<String>>{};
  for (final option in catalog.outcomeSources.options) {
    final outcome = option.outcome;
    if (outcome?.producerKind != NarrativeOutcomeProducerKind.scene) continue;
    outcomesBySceneId
        .putIfAbsent(outcome!.producerId, () => <String>{})
        .add(option.outcomeLabel);
  }
  final factLabels = {
    for (final fact in project.facts) fact.id: fact.label,
  };
  final rulesBySource =
      <(WorldRuleSourceKind, String), List<WorldRuleDefinition>>{};
  for (final rule in project.worldRules) {
    rulesBySource.putIfAbsent(
        (rule.source.kind, rule.source.sourceId), () => []).add(rule);
  }
  final scenesById = _groupBy(project.scenes, (scene) => scene.id);
  final result = <String, NarrativeEventProjectionSummary>{};
  for (final entry in scenesById.entries) {
    if (entry.value.length != 1) continue;
    final scene = entry.value.single;
    final consequences = <NarrativeEventProjectedConsequenceSummary>[];
    final rulesById = <String, NarrativeEventProjectedWorldRuleSummary>{};
    final seenConsequences = <String>{};
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is! SceneActionPayload || payload.consequence == null) {
        continue;
      }
      final consequence = payload.consequence!;
      final summary = switch (consequence) {
        SceneSetFactConsequence(:final factId, :final value, :final label) =>
          NarrativeEventProjectedConsequenceSummary(
            kind: consequence.kind,
            humanLabel:
                'Définit « ${label ?? factLabels[factId] ?? 'Fact lié'} » à ${value ? 'vrai' : 'faux'}.',
            debugReference: 'fact:${_debugIdentity(factId)}',
          ),
        SceneMarkEventConsumedConsequence(
          :final mapId,
          :final eventId,
          :final label,
        ) =>
          NarrativeEventProjectedConsequenceSummary(
            kind: consequence.kind,
            humanLabel:
                'Marque « ${label ?? 'Événement de map lié'} » comme joué.',
            debugReference:
                'map:${_debugIdentity(mapId)}:event:${_debugIdentity(eventId)}',
          ),
        SceneCompleteStoryStepConsequence(:final stepId, :final label) =>
          NarrativeEventProjectedConsequenceSummary(
            kind: consequence.kind,
            humanLabel: 'Termine « ${label ?? 'Étape narrative liée'} ».',
            debugReference: 'storyStep:${_debugIdentity(stepId)}',
          ),
        _ => null,
      };
      if (summary == null) continue;
      final consequenceKey = _projectedConsequenceKey(consequence);
      if (!seenConsequences.add(consequenceKey)) continue;
      consequences.add(summary);
      final sourceKey = switch (consequence) {
        SceneSetFactConsequence(:final factId) => (
            WorldRuleSourceKind.fact,
            factId
          ),
        SceneMarkEventConsumedConsequence(:final eventId) => (
            WorldRuleSourceKind.consumedEvent,
            eventId
          ),
        SceneCompleteStoryStepConsequence() => null,
        _ => null,
      };
      if (sourceKey == null) continue;
      for (final rule in rulesBySource[sourceKey] ?? const []) {
        rulesById.putIfAbsent(
          rule.id,
          () => NarrativeEventProjectedWorldRuleSummary(
            ruleId: rule.id,
            humanLabel: rule.label,
            enabled: rule.enabled,
          ),
        );
      }
    }
    consequences.sort((left, right) {
      final label = compareNarrativeEventUtf16(
        left.humanLabel,
        right.humanLabel,
      );
      return label != 0
          ? label
          : compareNarrativeEventUtf16(
              left.debugReference,
              right.debugReference,
            );
    });
    final worldRules = rulesById.values.toList()
      ..sort((left, right) {
        final label = compareNarrativeEventUtf16(
          left.humanLabel,
          right.humanLabel,
        );
        return label != 0
            ? label
            : compareNarrativeEventUtf16(left.ruleId, right.ruleId);
      });
    final outcomes = (outcomesBySceneId[scene.id] ?? const <String>{}).toList()
      ..sort(compareNarrativeEventUtf16);
    result[scene.id] = NarrativeEventProjectionSummary(
      outcomeLabels: outcomes,
      consequences: consequences,
      worldRules: worldRules,
      readOnly: true,
    );
  }
  return result;
}

String _projectedConsequenceKey(SceneConsequence consequence) {
  return switch (consequence) {
    SceneSetFactConsequence(:final factId, :final value) =>
      'setFact|${_debugIdentity(factId)}|$value',
    SceneMarkEventConsumedConsequence(:final mapId, :final eventId) =>
      'markEventConsumed|${_debugIdentity(mapId)}|${_debugIdentity(eventId)}',
    SceneCompleteStoryStepConsequence(:final stepId) =>
      'completeStoryStep|${_debugIdentity(stepId)}',
    _ => 'unsupported|${consequence.kind.name}',
  };
}

String _debugIdentity(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '<invalid>' : trimmed;
}

enum _ReferenceStatus { found, unavailable, missing, ambiguous, unconfigured }

final class _ResolvedSource {
  const _ResolvedSource({required this.status, required this.summary});

  factory _ResolvedSource.unconfigured({
    String sentence = 'Source non choisie.',
    String typeLabel = 'À configurer',
    String debugLabel = 'unconfigured',
  }) {
    return _ResolvedSource(
      status: _ReferenceStatus.unconfigured,
      summary: NarrativeEventSourceSummary(
        source: null,
        humanSentence: sentence,
        sourceTypeLabel: typeLabel,
        available: false,
        debugTechnicalLabel: debugLabel,
      ),
    );
  }

  final _ReferenceStatus status;
  final NarrativeEventSourceSummary summary;
}

final class _GroupDescriptor {
  const _GroupDescriptor(this.kind, this.key, this.label);

  final NarrativeEventProjectGroupKind kind;
  final String key;
  final String label;
}

final class _LegacyProjectionInput {
  const _LegacyProjectionInput._({this.mapProjection, this.scenarioProjection});

  const _LegacyProjectionInput.map(LegacyMapEventProjection projection)
      : this._(mapProjection: projection);

  const _LegacyProjectionInput.scenario(
    LegacyScenarioSourceProjection projection,
  ) : this._(scenarioProjection: projection);

  final LegacyMapEventProjection? mapProjection;
  final LegacyScenarioSourceProjection? scenarioProjection;

  LegacySourceRef get provenance =>
      mapProjection?.provenance ?? scenarioProjection!.provenance;

  LegacyProjectionClaimStatus get claimStatus =>
      mapProjection?.claimStatus ?? scenarioProjection!.claimStatus;

  LegacySourceClaim? get existingClaim =>
      mapProjection?.existingClaim ?? scenarioProjection!.existingClaim;

  String get sourceFingerprint =>
      mapProjection?.sourceFingerprint ?? scenarioProjection!.sourceFingerprint;

  NarrativeEventSourceRef? get source =>
      mapProjection?.confirmedSource ?? scenarioProjection?.source;

  T when<T>({
    required T Function(LegacyMapEventProjection projection) map,
    required T Function(LegacyScenarioSourceProjection projection) scenario,
  }) {
    final mapValue = mapProjection;
    return mapValue == null ? scenario(scenarioProjection!) : map(mapValue);
  }

  String get debugJson => when(
        map: (value) => _canonicalKey(value.toJson()),
        scenario: (value) => _canonicalKey(value.toJson()),
      );
}

final class _InvalidClaimInput {
  const _InvalidClaimInput({
    required this.claim,
    required this.evidenceIssues,
  });

  final LegacySourceClaim claim;
  final List<String> evidenceIssues;
}

List<String> _claimProjectionEvidenceIssues(
  LegacySourceClaim claim, {
  required ValidatedLegacyClaimIndex claimIndex,
  required Map<LegacySourceRef, List<_LegacyProjectionInput>>
      projectionsByProvenance,
}) {
  final issues = <String>[];
  if (claimIndex.validBySource[claim.source] != claim) {
    issues.add('Le lien de migration n’est pas valide dans ce projet.');
  }
  for (final member in claim.members) {
    if (claimIndex.validByProvenance[member.provenance] != claim) {
      issues.add('Une origine du lien n’est pas validée par le projet.');
    }
    final projections = projectionsByProvenance[member.provenance] ?? const [];
    if (projections.length != 1) {
      issues.add(
        projections.isEmpty
            ? 'Une origine du lien ne possède plus de lecture courante.'
            : 'Une origine du lien possède plusieurs lectures concurrentes.',
      );
      continue;
    }
    final projection = projections.single;
    if (projection.sourceFingerprint != member.sourceFingerprint) {
      issues.add('Le contenu d’une origine a changé depuis la migration.');
    }
    if (projection.claimStatus != LegacyProjectionClaimStatus.valid ||
        projection.existingClaim != claim) {
      issues.add(
        'La lecture courante ne confirme pas exactement ce lien.',
      );
    }
  }
  final unique = issues.toSet().toList()..sort(compareNarrativeEventUtf16);
  return List.unmodifiable(unique);
}

NarrativeEventProjectStatus _v2Status({
  required NarrativeEventProjectEventEntry entry,
  required bool hasBlockingDiagnostics,
  required _ReferenceStatus sourceStatus,
  required bool sceneSelected,
  required bool sceneValid,
  required bool conditionsValid,
}) {
  if (sourceStatus == _ReferenceStatus.missing) {
    return NarrativeEventProjectStatus.sourceMissing;
  }
  if (sourceStatus != _ReferenceStatus.found &&
      sourceStatus != _ReferenceStatus.unconfigured) {
    return NarrativeEventProjectStatus.referenceInvalid;
  }
  if (entry.draft) {
    if ((sceneSelected && !sceneValid) || !conditionsValid) {
      return NarrativeEventProjectStatus.referenceInvalid;
    }
    return NarrativeEventProjectStatus.draftIncomplete;
  }
  if (!sceneValid || !conditionsValid || !entry.contextuallyValid) {
    return NarrativeEventProjectStatus.referenceInvalid;
  }
  if (hasBlockingDiagnostics) {
    return NarrativeEventProjectStatus.attentionRequired;
  }
  return entry.record.enabledOrNull == true
      ? NarrativeEventProjectStatus.configuredEnabledReady
      : NarrativeEventProjectStatus.configuredDisabledReady;
}

_GroupDescriptor _v2Group({
  required NarrativeEventDraft? draft,
  required _ResolvedSource resolvedSource,
  required NarrativeEventProjectStatus status,
}) {
  if (status == NarrativeEventProjectStatus.sourceMissing ||
      status == NarrativeEventProjectStatus.referenceInvalid) {
    return const _GroupDescriptor(
      NarrativeEventProjectGroupKind.missingReferences,
      'references:missing',
      'Références à corriger',
    );
  }
  if (resolvedSource.status == _ReferenceStatus.unconfigured) {
    return const _GroupDescriptor(
      NarrativeEventProjectGroupKind.drafts,
      'drafts:unconfigured',
      'Brouillons sans source',
    );
  }
  if (resolvedSource.summary.mapId != null) {
    return _GroupDescriptor(
      NarrativeEventProjectGroupKind.map,
      'map:${resolvedSource.summary.mapId}',
      resolvedSource.summary.mapLabel ?? 'Map sans nom',
    );
  }
  if (resolvedSource.summary.source?.kind ==
      NarrativeEventSourceKind.outcomeReceived) {
    return const _GroupDescriptor(
      NarrativeEventProjectGroupKind.outcomes,
      'outcomes:nonspatial',
      'Résultats et sources non spatiales',
    );
  }
  if (draft != null) {
    return const _GroupDescriptor(
      NarrativeEventProjectGroupKind.drafts,
      'drafts:unconfigured',
      'Brouillons sans source',
    );
  }
  return const _GroupDescriptor(
    NarrativeEventProjectGroupKind.missingReferences,
    'references:missing',
    'Références à corriger',
  );
}

NarrativeEventProjectStatus _legacyStatus(
  LegacyMigrationClassification classification,
) {
  return switch (classification) {
    LegacyMigrationClassification.autoSafe ||
    LegacyMigrationClassification.legacyOnly =>
      NarrativeEventProjectStatus.legacyOnly,
    LegacyMigrationClassification.assisted =>
      NarrativeEventProjectStatus.migrationAssistanceRequired,
    LegacyMigrationClassification.blocked =>
      NarrativeEventProjectStatus.migrationBlocked,
    LegacyMigrationClassification.unsupported =>
      NarrativeEventProjectStatus.unsupported,
  };
}

NarrativeEventProjectSummarySeverity _statusSeverity(
  NarrativeEventProjectStatus status,
) {
  return switch (status) {
    NarrativeEventProjectStatus.configuredDisabledReady ||
    NarrativeEventProjectStatus.configuredEnabledReady ||
    NarrativeEventProjectStatus.legacyOnly =>
      NarrativeEventProjectSummarySeverity.info,
    NarrativeEventProjectStatus.draftIncomplete ||
    NarrativeEventProjectStatus.attentionRequired ||
    NarrativeEventProjectStatus.migrationAssistanceRequired =>
      NarrativeEventProjectSummarySeverity.warning,
    _ => NarrativeEventProjectSummarySeverity.error,
  };
}

NarrativeEventSourceSummary _missingSourceSummary(
  NarrativeEventSourceRef source, {
  required Map<String, String> mapLabelsById,
  String? reason,
}) {
  return source.when(
    entityInteract: (mapId, entityId) => NarrativeEventSourceSummary(
      source: source,
      humanSentence: reason ??
          'Source introuvable — l’entité « $entityId » n’existe plus.',
      sourceTypeLabel: 'Interaction avec un élément',
      mapId: mapId,
      mapLabel: mapLabelsById[mapId] ?? 'Map introuvable',
      available: false,
      debugTechnicalLabel: _canonicalKey(source.toJson()),
    ),
    triggerEnter: (mapId, triggerId) => NarrativeEventSourceSummary(
      source: source,
      humanSentence: reason ??
          'Source introuvable — la zone « $triggerId » n’existe plus.',
      sourceTypeLabel: 'Entrée dans une zone',
      mapId: mapId,
      mapLabel: mapLabelsById[mapId] ?? 'Map introuvable',
      available: false,
      debugTechnicalLabel: _canonicalKey(source.toJson()),
    ),
    mapEnter: (mapId) => NarrativeEventSourceSummary(
      source: source,
      humanSentence: reason ?? 'Source introuvable — cette map n’existe plus.',
      sourceTypeLabel: 'Entrée de map',
      mapId: mapId,
      mapLabel: mapLabelsById[mapId] ?? 'Map introuvable',
      available: false,
      debugTechnicalLabel: _canonicalKey(source.toJson()),
    ),
    outcomeReceived: (outcome) => NarrativeEventSourceSummary(
      source: source,
      humanSentence: reason ??
          'Résultat introuvable — son producteur n’est plus disponible.',
      sourceTypeLabel: 'Résultat',
      available: false,
      debugTechnicalLabel: _canonicalKey(outcome.toJson()),
    ),
  );
}

NarrativeEventLifecycleSummary _lifecycleSummary(
  NarrativeEventReusePolicy? policy, {
  required bool? enabled,
  int? priority,
  int? order,
  int activeCandidateCount = 0,
}) {
  return NarrativeEventLifecycleSummary(
    reusePolicy: policy,
    enabled: enabled,
    priority: priority,
    order: order,
    activeCandidateCount: activeCandidateCount,
    humanLabel: switch (policy) {
      NarrativeEventReusePolicy.oneShot => 'Une seule fois',
      NarrativeEventReusePolicy.reusable => 'Réutilisable',
      null => 'Comportement à choisir',
    },
  );
}

Map<NarrativeEventSourceRef, int> _buildActiveCandidateCounts(
  List<NarrativeEventProjectEventEntry> entries,
) {
  final result = <NarrativeEventSourceRef, int>{};
  for (final entry in entries) {
    final definition = entry.record.definitionOrNull;
    if (definition == null ||
        entry.record.enabledOrNull != true ||
        !entry.applicableReferenceTarget) {
      continue;
    }
    result.update(definition.source, (count) => count + 1, ifAbsent: () => 1);
  }
  return result;
}

String _legacyMigrationLabel(LegacyMigrationClassification classification) {
  return switch (classification) {
    LegacyMigrationClassification.autoSafe =>
      'Élément existant prêt pour une migration contrôlée.',
    LegacyMigrationClassification.assisted =>
      'Une confirmation est nécessaire avant migration.',
    LegacyMigrationClassification.blocked =>
      'La migration est bloquée tant que les erreurs persistent.',
    LegacyMigrationClassification.unsupported =>
      'Cette configuration n’est pas prise en charge.',
    LegacyMigrationClassification.legacyOnly =>
      'Conservé dans le système existant en lecture seule.',
  };
}

NarrativeEventCompatibilityOrigin _compatibilityOrigin(
  LegacySourceRef provenance, {
  required ProjectManifest project,
  String? migrationReceiptId,
}) {
  final mapLabels = {
    for (final map in project.maps)
      map.id: _display(map.name, fallback: map.id),
  };
  final scenarioLabels = {
    for (final scenario in project.scenarios)
      scenario.id: _display(scenario.name, fallback: scenario.id),
  };
  return NarrativeEventCompatibilityOrigin(
    provenance: provenance,
    migrationReceiptId: migrationReceiptId,
    humanLabel: provenance.when(
      mapEvent: (mapId, _) =>
          'Événement existant — ${mapLabels[mapId] ?? 'Map introuvable'}',
      scenarioSourceNode: (scenarioId, _) =>
          'Parcours existant — ${scenarioLabels[scenarioId] ?? 'Source introuvable'}',
    ),
  );
}

List<NarrativeEventProjectReadDiagnostic> _legacyDiagnostics(
  List<LegacyMigrationDiagnostic> diagnostics,
) {
  return _deduplicateDiagnostics([
    for (final diagnostic in diagnostics)
      NarrativeEventProjectReadDiagnostic(
        code: diagnostic.code,
        severity: switch (diagnostic.severity) {
          LegacyMigrationDiagnosticSeverity.info =>
            NarrativeEventProjectSummarySeverity.info,
          LegacyMigrationDiagnosticSeverity.warning =>
            NarrativeEventProjectSummarySeverity.warning,
          LegacyMigrationDiagnosticSeverity.error =>
            NarrativeEventProjectSummarySeverity.error,
        },
        message: _legacyDiagnosticHumanMessage(diagnostic),
      ),
  ]);
}

String _legacyDiagnosticHumanMessage(LegacyMigrationDiagnostic diagnostic) {
  return switch (diagnostic.code) {
    LegacyScenarioDiagnosticCodes.lifecycleEvidenceMissing =>
      'Le comportement de réutilisation doit être confirmé.',
    LegacyScenarioDiagnosticCodes.sceneCandidateMissing ||
    LegacyScenarioDiagnosticCodes.sceneNotBuildable ||
    LegacyMapEventDiagnosticCodes.missingSceneTarget =>
      'Une Scene valide doit être choisie.',
    'claimFingerprintStale' =>
      'Le contenu existant a changé depuis la migration.',
    'invalidClaim' ||
    'globalClaimConflict' =>
      'Le lien de migration doit être réparé.',
    _ => switch (diagnostic.severity) {
        LegacyMigrationDiagnosticSeverity.info =>
          'Information de compatibilité disponible.',
        LegacyMigrationDiagnosticSeverity.warning =>
          'Cette configuration existante doit être vérifiée.',
        LegacyMigrationDiagnosticSeverity.error =>
          'Cette configuration existante doit être réparée.',
      },
  };
}

List<NarrativeEventProjectReadDiagnostic> _deduplicateDiagnostics(
  Iterable<NarrativeEventProjectReadDiagnostic> values,
) {
  return deduplicateNarrativeEventReadValues(
    values: values,
    keyOf: (value) =>
        '${value.code}\u0000${value.severity.name}\u0000${value.message}',
    compare: (left, right) {
      for (final comparison in [
        left.severity.index.compareTo(right.severity.index),
        compareNarrativeEventUtf16(left.code, right.code),
        compareNarrativeEventUtf16(left.message, right.message),
      ]) {
        if (comparison != 0) return comparison;
      }
      return 0;
    },
  );
}

NarrativeEventProjectSummarySeverity _projectDiagnosticSeverity(
  NarrativeEventProjectDiagnosticSeverity severity,
) {
  return switch (severity) {
    NarrativeEventProjectDiagnosticSeverity.info =>
      NarrativeEventProjectSummarySeverity.info,
    NarrativeEventProjectDiagnosticSeverity.warning =>
      NarrativeEventProjectSummarySeverity.warning,
    NarrativeEventProjectDiagnosticSeverity.error =>
      NarrativeEventProjectSummarySeverity.error,
  };
}

String _humanClaimIssue(String message) {
  if (message.contains(' is absent.')) {
    return 'Un événement lié n’existe plus.';
  }
  if (message.contains(' is still a draft.')) {
    return 'Un événement lié est encore incomplet.';
  }
  if (message.contains(' uses a different source.')) {
    return 'Un événement lié utilise une autre source.';
  }
  if (message.contains('global cohort/source/provenance conflict') ||
      message.contains('shared by cohorts')) {
    return 'Plusieurs liens de migration se contredisent.';
  }
  return message;
}

String _conditionLabel(int count) => switch (count) {
      0 => 'Aucune condition',
      1 => '1 condition',
      _ => '$count conditions',
    };

String _display(String value, {required String fallback}) {
  final trimmed = value.trim();
  if (trimmed.isNotEmpty) return trimmed;
  final fallbackTrimmed = fallback.trim();
  return fallbackTrimmed.isEmpty ? 'Sans nom' : fallbackTrimmed;
}

String _identity(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(value, name, 'must be non-empty and trimmed');
  }
  return value;
}

String _canonicalKey(Object? value) {
  try {
    return canonicalizeNarrativeEventJson(value);
  } on FormatException {
    return value.toString();
  }
}

Map<K, List<V>> _groupBy<K, V>(
  Iterable<V> values,
  K Function(V value) keyOf,
) {
  final result = <K, List<V>>{};
  for (final value in values) {
    result.putIfAbsent(keyOf(value), () => []).add(value);
  }
  return result;
}

Map<K, List<V>> _groupByPresent<K, V>(
  Iterable<V> values,
  K? Function(V value) keyOf,
) {
  final result = <K, List<V>>{};
  for (final value in values) {
    final key = keyOf(value);
    if (key != null) result.putIfAbsent(key, () => []).add(value);
  }
  return result;
}

int _compareCompatibilityOrigins(
  NarrativeEventCompatibilityOrigin left,
  NarrativeEventCompatibilityOrigin right,
) {
  return compareNarrativeEventUtf16(left.stableKey, right.stableKey);
}

int _compareClaims(LegacySourceClaim left, LegacySourceClaim right) {
  return compareNarrativeEventUtf16(left.cohortId, right.cohortId);
}

int _compareInvalidClaims(_InvalidClaimInput left, _InvalidClaimInput right) {
  return _compareClaims(left.claim, right.claim);
}

int _compareLegacyInputs(
  _LegacyProjectionInput left,
  _LegacyProjectionInput right,
) {
  for (final comparison in [
    compareLegacySourceRefs(left.provenance, right.provenance),
    compareNarrativeEventUtf16(left.debugJson, right.debugJson),
  ]) {
    if (comparison != 0) return comparison;
  }
  return 0;
}

int _compareSummaries(
  NarrativeEventProjectSummary left,
  NarrativeEventProjectSummary right,
) {
  for (final comparison in [
    compareNarrativeEventUtf16(left.title, right.title),
    compareNarrativeEventUtf16(left.eventId ?? '', right.eventId ?? ''),
    compareNarrativeEventUtf16(left.stableKey, right.stableKey),
  ]) {
    if (comparison != 0) return comparison;
  }
  return 0;
}

int _compareGroups(
  NarrativeEventProjectGroup left,
  NarrativeEventProjectGroup right,
) {
  for (final comparison in [
    left.kind.index.compareTo(right.kind.index),
    compareNarrativeEventUtf16(left.label, right.label),
    compareNarrativeEventUtf16(left.stableKey, right.stableKey),
  ]) {
    if (comparison != 0) return comparison;
  }
  return 0;
}
