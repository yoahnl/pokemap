import 'package:meta/meta.dart' show immutable;

import '../catalogs/narrative_event_project_catalog.dart';
import '../catalogs/narrative_outcome_event_source_catalog.dart';
import '../catalogs/narrative_spatial_event_source_catalog.dart';
import '../models/game_state.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_occurrence.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../read_models/narrative_event_source_index.dart';
import '../read_models/narrative_event_validation_read_model.dart';
import 'narrative_event_registry_codec.dart';
import 'narrative_fact_runtime.dart';

enum NarrativeEventDispatchAuthorityBlockReason {
  invalidRegistry,
  unsupportedRegistry,
  dualReadClaimIndexRequired,
  dualReadRuntimeNotReady,
  claimIndexSnapshotMismatch,
  claimSourceProvenanceMismatch,
  invalidFactResolver,
  projectCatalogRequired,
  projectCatalogBlocked,
  projectCatalogSnapshotMismatch,
}

enum NarrativeEventDispatchReason {
  draft,
  disabled,
  sourceMismatch,
  factConditionFalse,
  narrativeEventConsumedConditionFalse,
  eventConsumed,
  eventInFlight,
  claimTombstone,
  claimTargetsIneligible,
  noEligibleCandidate,
  runtimeReferenceUnavailable,
}

sealed class NarrativeEventDispatchAuthorityPreparation {
  const NarrativeEventDispatchAuthorityPreparation();

  bool get isReady;
}

@immutable
final class NarrativeEventDispatchAuthorityBlocked
    extends NarrativeEventDispatchAuthorityPreparation {
  NarrativeEventDispatchAuthorityBlocked({
    required this.reason,
    required List<String> diagnostics,
  }) : diagnostics = List.unmodifiable(diagnostics);

  final NarrativeEventDispatchAuthorityBlockReason reason;
  final List<String> diagnostics;

  @override
  bool get isReady => false;
}

@immutable
final class NarrativeEventDispatchAuthorityReady
    extends NarrativeEventDispatchAuthorityPreparation {
  NarrativeEventDispatchAuthorityReady._({
    required this.occurrence,
    required this.mode,
    required NarrativeEventRegistry registry,
    required NarrativeEventSourceIndex sourceIndex,
    required NarrativeFactRuntimeResolver factResolver,
    required NarrativeEventProjectCatalog projectCatalog,
    required _LegacyClaimAuthorityResolution claimResolution,
  })  : _registry = registry,
        _sourceIndex = sourceIndex,
        _factResolver = factResolver,
        _projectCatalog = projectCatalog,
        _claimResolution = claimResolution;

  final NarrativeEventOccurrence occurrence;
  final EventSystemMode mode;
  final NarrativeEventRegistry _registry;
  final NarrativeEventSourceIndex _sourceIndex;
  final NarrativeFactRuntimeResolver _factResolver;
  final NarrativeEventProjectCatalog _projectCatalog;
  final _LegacyClaimAuthorityResolution _claimResolution;

  @override
  bool get isReady => true;

  /// Applies a deterministic map activation reset before dispatch planning.
  ///
  /// [resetEligible] must only be true for a completed spatial transition
  /// (warp/connection). Initial boot and save restore still update persisted
  /// map history, but never count as a re-entry.
  GameState applyMapActivationReset({
    required GameState gameState,
    required String activationId,
    required String mapId,
    required bool resetEligible,
  }) {
    final progress = gameState.narrativeEventProgress;
    final token = 'map:$activationId';
    if (progress.appliedNarrativeResetTokens.contains(token)) {
      return gameState;
    }
    final isReentry = resetEligible &&
        progress.activeNarrativeMapId != null &&
        progress.activeNarrativeMapId != mapId &&
        progress.visitedNarrativeMapIds.contains(mapId);
    final consumed = progress.consumedNarrativeEventIds.toSet();
    if (isReentry) {
      for (final record in _registry.records) {
        final definition = record.definitionOrNull;
        if (definition == null ||
            definition.reusePolicy != NarrativeEventReusePolicy.oneShot ||
            definition.resetPolicy is! NarrativeEventResetOnMapReentry ||
            _sourceMapId(definition.source) != mapId) {
          continue;
        }
        consumed.remove(definition.id);
      }
    }
    final visited = {...progress.visitedNarrativeMapIds, mapId};
    final updatedProgress = progress.copyWith(
      consumedNarrativeEventIds: consumed,
      activeNarrativeMapId: mapId,
      visitedNarrativeMapIds: visited,
      appliedNarrativeResetTokens: _appendResetToken(
        progress.appliedNarrativeResetTokens,
        token,
      ),
    );
    return gameState.copyWith(narrativeEventProgress: updatedProgress);
  }

  /// Applies an exact qualified-outcome reset before dispatch planning.
  GameState applyOutcomeReset({
    required GameState gameState,
    required String deliveryId,
    required NarrativeOutcomeRef outcome,
  }) {
    final progress = gameState.narrativeEventProgress;
    final token = 'outcome:$deliveryId';
    if (progress.appliedNarrativeResetTokens.contains(token)) {
      return gameState;
    }
    final consumed = progress.consumedNarrativeEventIds.toSet();
    for (final record in _registry.records) {
      final definition = record.definitionOrNull;
      final policy = definition?.resetPolicy;
      if (definition != null &&
          definition.reusePolicy == NarrativeEventReusePolicy.oneShot &&
          policy is NarrativeEventResetOnOutcomeReceived &&
          policy.outcome == outcome) {
        consumed.remove(definition.id);
      }
    }
    final updatedProgress = progress.copyWith(
      consumedNarrativeEventIds: consumed,
      appliedNarrativeResetTokens: _appendResetToken(
        progress.appliedNarrativeResetTokens,
        token,
      ),
    );
    return gameState.copyWith(narrativeEventProgress: updatedProgress);
  }

  NarrativeEventDispatchDecision plan({
    required GameState gameState,
    Set<String> inFlightNarrativeEventIds = const <String>{},
  }) {
    final source = occurrence.source;
    if (mode == EventSystemMode.legacyOnly) {
      return NarrativeEventDispatchNoMatch(
        source: source,
        mode: mode,
        legacyFallbackAllowed: true,
        reasons: const [NarrativeEventDispatchReason.noEligibleCandidate],
      );
    }
    if (_claimResolution == _LegacyClaimAuthorityResolution.tombstone) {
      return NarrativeEventDispatchClaimedButIneligible(
        source: source,
        mode: mode,
        reasons: const [NarrativeEventDispatchReason.claimTombstone],
      );
    }

    final reasons = <NarrativeEventDispatchReason>{};
    _collectStructuralReasons(source, reasons);
    for (final record in _sourceIndex.recordsFor(source)) {
      final definition = record.definitionOrNull!;
      final evaluation = _evaluateDefinition(
        definition,
        gameState,
        inFlightNarrativeEventIds,
      );
      if (evaluation.reason != null) {
        reasons.add(evaluation.reason!);
        continue;
      }
      return NarrativeEventDispatchHandled(
        source: source,
        mode: mode,
        eventId: definition.id,
        sceneId: definition.sceneId,
        reusePolicy: definition.reusePolicy,
        priority: definition.priority,
        order: definition.order,
      );
    }

    reasons.add(NarrativeEventDispatchReason.noEligibleCandidate);
    if (mode == EventSystemMode.dualRead &&
        _claimResolution == _LegacyClaimAuthorityResolution.valid) {
      reasons.add(NarrativeEventDispatchReason.claimTargetsIneligible);
      return NarrativeEventDispatchClaimedButIneligible(
        source: source,
        mode: mode,
        reasons: _sortedReasons(reasons),
      );
    }
    return NarrativeEventDispatchNoMatch(
      source: source,
      mode: mode,
      legacyFallbackAllowed: mode == EventSystemMode.dualRead,
      reasons: _sortedReasons(reasons),
    );
  }

  /// Explains the exact decision produced by [plan] for Event Builder.
  ///
  /// Candidate ordering and condition evaluation are shared with dispatch;
  /// the simulator cannot silently diverge into an editor-only truth table.
  NarrativeEventSimulationReport simulate({
    required GameState gameState,
    required String targetEventId,
    Set<String> inFlightNarrativeEventIds = const <String>{},
  }) {
    final decision = plan(
      gameState: gameState,
      inFlightNarrativeEventIds: inFlightNarrativeEventIds,
    );
    final selectedId =
        decision is NarrativeEventDispatchHandled ? decision.eventId : null;
    final records = <NarrativeEventRecord>[
      ..._sourceIndex.recordsFor(occurrence.source),
      for (final record in _registry.records)
        if (record.id == targetEventId &&
            !_sourceIndex.recordsFor(occurrence.source).contains(record))
          record,
    ];
    final candidates = <NarrativeEventSimulationCandidateTrace>[
      for (final record in records)
        _simulateRecord(
          record,
          gameState: gameState,
          selectedId: selectedId,
          inFlightNarrativeEventIds: inFlightNarrativeEventIds,
        ),
    ];
    return NarrativeEventSimulationReport(
      status: switch (decision) {
        NarrativeEventDispatchHandled() =>
          NarrativeEventSimulationStatus.handled,
        NarrativeEventDispatchClaimedButIneligible() =>
          NarrativeEventSimulationStatus.claimedButIneligible,
        NarrativeEventDispatchNoMatch() =>
          NarrativeEventSimulationStatus.noMatch,
      },
      targetEventId: targetEventId,
      source: occurrence.source,
      mode: mode,
      handledEventId: selectedId,
      sceneId:
          decision is NarrativeEventDispatchHandled ? decision.sceneId : null,
      legacyFallbackAllowed: decision.legacyFallbackAllowed,
      reasons: [
        for (final reason in decision.reasons) _simulationReason(reason)
      ],
      candidates: candidates,
      diagnostics: const [],
    );
  }

  void _collectStructuralReasons(
    NarrativeEventSourceRef source,
    Set<NarrativeEventDispatchReason> reasons,
  ) {
    for (final record in _registry.records) {
      record.when(
        draft: (draft) {
          if (draft.source == source) {
            reasons.add(NarrativeEventDispatchReason.draft);
          }
        },
        configured: (definition, enabled) {
          if (definition.source == source && !enabled) {
            reasons.add(NarrativeEventDispatchReason.disabled);
          }
        },
      );
    }
  }

  _NarrativeEventCandidateEvaluation _evaluateDefinition(
    NarrativeEventDefinition definition,
    GameState gameState,
    Set<String> inFlightNarrativeEventIds,
  ) {
    if (_projectCatalog.resolveSource(definition.source).status !=
            NarrativeEventProjectResolutionStatus.found ||
        _projectCatalog.resolveScene(definition.sceneId).status !=
            NarrativeEventProjectResolutionStatus.found) {
      return const _NarrativeEventCandidateEvaluation(
        NarrativeEventDispatchReason.runtimeReferenceUnavailable,
        [],
      );
    }
    if (inFlightNarrativeEventIds.contains(definition.id)) {
      return const _NarrativeEventCandidateEvaluation(
        NarrativeEventDispatchReason.eventInFlight,
        [],
      );
    }
    if (definition.reusePolicy == NarrativeEventReusePolicy.oneShot &&
        gameState.narrativeEventProgress.consumedNarrativeEventIds
            .contains(definition.id)) {
      return const _NarrativeEventCandidateEvaluation(
        NarrativeEventDispatchReason.eventConsumed,
        [],
      );
    }
    final traces = <NarrativeEventSimulationConditionTrace>[];
    NarrativeEventSimulationConditionTrace evaluateLeaf(
      NarrativeEventCondition condition,
      int index,
    ) {
      return condition.when(
        fact: (factId, expectedValue) {
          if (_projectCatalog.resolveFact(factId).status !=
              NarrativeEventProjectResolutionStatus.found) {
            return NarrativeEventSimulationConditionTrace(
              index: index,
              kind: NarrativeEventSimulationConditionKind.fact,
              targetId: factId,
              expectedValue: expectedValue,
              actualValue: null,
              passed: false,
              reason:
                  NarrativeEventSimulationReason.runtimeReferenceUnavailable,
            );
          }
          final resolution = _factResolver.resolve(
            factId: factId,
            runtimeState: gameState.narrativeFactRuntimeState,
            storyFlags: gameState.storyFlags,
          );
          final actual = resolution is NarrativeFactRuntimeResolved
              ? resolution.value
              : null;
          final passed = actual == expectedValue;
          return NarrativeEventSimulationConditionTrace(
            index: index,
            kind: NarrativeEventSimulationConditionKind.fact,
            targetId: factId,
            expectedValue: expectedValue,
            actualValue: actual,
            passed: passed,
            reason: passed
                ? null
                : NarrativeEventSimulationReason.factConditionFalse,
          );
        },
        narrativeEventConsumed: (eventId, expectedValue) {
          if (_projectCatalog.resolveEvent(eventId).status !=
              NarrativeEventProjectResolutionStatus.found) {
            return NarrativeEventSimulationConditionTrace(
              index: index,
              kind:
                  NarrativeEventSimulationConditionKind.narrativeEventConsumed,
              targetId: eventId,
              expectedValue: expectedValue,
              actualValue: null,
              passed: false,
              reason:
                  NarrativeEventSimulationReason.runtimeReferenceUnavailable,
            );
          }
          final consumed = gameState
              .narrativeEventProgress.consumedNarrativeEventIds
              .contains(eventId);
          final passed = consumed == expectedValue;
          return NarrativeEventSimulationConditionTrace(
            index: index,
            kind: NarrativeEventSimulationConditionKind.narrativeEventConsumed,
            targetId: eventId,
            expectedValue: expectedValue,
            actualValue: consumed,
            passed: passed,
            reason: passed
                ? null
                : NarrativeEventSimulationReason
                    .narrativeEventConsumedConditionFalse,
          );
        },
      );
    }

    var leafIndex = 0;
    _ConditionExpressionEvaluation evaluateExpression(
      NarrativeEventConditionExpression expression,
    ) {
      switch (expression) {
        case NarrativeEventConditionLeaf(:final condition):
          final trace = evaluateLeaf(condition, leafIndex++);
          traces.add(trace);
          return _ConditionExpressionEvaluation(
            passed: trace.passed,
            unavailable: trace.reason ==
                NarrativeEventSimulationReason.runtimeReferenceUnavailable,
          );
        case NarrativeEventConditionAll(:final children):
          var passed = true;
          var unavailable = false;
          for (final child in children) {
            final result = evaluateExpression(child);
            passed = passed && result.passed;
            unavailable = unavailable || result.unavailable;
          }
          return _ConditionExpressionEvaluation(
            passed: passed && !unavailable,
            unavailable: unavailable,
          );
        case NarrativeEventConditionAny(:final children):
          var passed = false;
          var unavailable = false;
          for (final child in children) {
            final result = evaluateExpression(child);
            passed = passed || result.passed;
            unavailable = unavailable || result.unavailable;
          }
          return _ConditionExpressionEvaluation(
            passed: passed,
            unavailable: !passed && unavailable,
          );
        case NarrativeEventConditionNot(:final child):
          final result = evaluateExpression(child);
          return _ConditionExpressionEvaluation(
            passed: result.unavailable ? false : !result.passed,
            unavailable: result.unavailable,
          );
      }
    }

    final expressionResult = evaluateExpression(definition.conditionExpression);
    if (expressionResult.passed) {
      return _NarrativeEventCandidateEvaluation(null, traces);
    }
    if (expressionResult.unavailable) {
      return _NarrativeEventCandidateEvaluation(
        NarrativeEventDispatchReason.runtimeReferenceUnavailable,
        traces,
      );
    }
    final representative = traces.firstWhere(
      (trace) => !trace.passed,
      orElse: () => traces.first,
    );
    return _NarrativeEventCandidateEvaluation(
      switch (representative.kind) {
        NarrativeEventSimulationConditionKind.fact =>
          NarrativeEventDispatchReason.factConditionFalse,
        NarrativeEventSimulationConditionKind.narrativeEventConsumed =>
          NarrativeEventDispatchReason.narrativeEventConsumedConditionFalse,
      },
      traces,
    );
  }

  NarrativeEventSimulationCandidateTrace _simulateRecord(
    NarrativeEventRecord record, {
    required GameState gameState,
    required String? selectedId,
    required Set<String> inFlightNarrativeEventIds,
  }) {
    return record.when(
      draft: (draft) => NarrativeEventSimulationCandidateTrace(
        eventId: draft.id,
        name: draft.name,
        configured: false,
        enabled: false,
        sourceMatches: draft.source == occurrence.source,
        reusePolicy: draft.reusePolicy,
        priority: draft.priority,
        order: draft.order,
        selected: false,
        reasons: [
          NarrativeEventSimulationReason.draft,
          if (draft.source != occurrence.source)
            NarrativeEventSimulationReason.sourceMismatch,
        ],
        conditions: const [],
      ),
      configured: (definition, enabled) {
        final sourceMatches = definition.source == occurrence.source;
        final evaluation = sourceMatches
            ? _evaluateDefinition(
                definition,
                gameState,
                inFlightNarrativeEventIds,
              )
            : const _NarrativeEventCandidateEvaluation(null, []);
        return NarrativeEventSimulationCandidateTrace(
          eventId: definition.id,
          name: definition.name,
          configured: true,
          enabled: enabled,
          sourceMatches: sourceMatches,
          reusePolicy: definition.reusePolicy,
          priority: definition.priority,
          order: definition.order,
          selected: definition.id == selectedId,
          reasons: [
            if (!enabled) NarrativeEventSimulationReason.disabled,
            if (!sourceMatches) NarrativeEventSimulationReason.sourceMismatch,
            if (enabled && sourceMatches && evaluation.reason != null)
              _simulationReason(evaluation.reason!),
          ],
          conditions: evaluation.conditions,
        );
      },
    );
  }
}

final class _NarrativeEventCandidateEvaluation {
  const _NarrativeEventCandidateEvaluation(this.reason, this.conditions);

  final NarrativeEventDispatchReason? reason;
  final List<NarrativeEventSimulationConditionTrace> conditions;
}

final class _ConditionExpressionEvaluation {
  const _ConditionExpressionEvaluation({
    required this.passed,
    required this.unavailable,
  });

  final bool passed;
  final bool unavailable;
}

NarrativeEventSimulationReason _simulationReason(
  NarrativeEventDispatchReason reason,
) =>
    switch (reason) {
      NarrativeEventDispatchReason.draft =>
        NarrativeEventSimulationReason.draft,
      NarrativeEventDispatchReason.disabled =>
        NarrativeEventSimulationReason.disabled,
      NarrativeEventDispatchReason.sourceMismatch =>
        NarrativeEventSimulationReason.sourceMismatch,
      NarrativeEventDispatchReason.factConditionFalse =>
        NarrativeEventSimulationReason.factConditionFalse,
      NarrativeEventDispatchReason.narrativeEventConsumedConditionFalse =>
        NarrativeEventSimulationReason.narrativeEventConsumedConditionFalse,
      NarrativeEventDispatchReason.eventConsumed =>
        NarrativeEventSimulationReason.eventConsumed,
      NarrativeEventDispatchReason.eventInFlight =>
        NarrativeEventSimulationReason.eventInFlight,
      NarrativeEventDispatchReason.claimTombstone =>
        NarrativeEventSimulationReason.claimTombstone,
      NarrativeEventDispatchReason.claimTargetsIneligible =>
        NarrativeEventSimulationReason.claimTargetsIneligible,
      NarrativeEventDispatchReason.noEligibleCandidate =>
        NarrativeEventSimulationReason.noEligibleCandidate,
      NarrativeEventDispatchReason.runtimeReferenceUnavailable =>
        NarrativeEventSimulationReason.runtimeReferenceUnavailable,
    };

abstract final class NarrativeEventDispatchAuthority {
  static NarrativeEventDispatchAuthorityPreparation prepare({
    required EventRegistryDecodeResult registryResult,
    required NarrativeEventOccurrence occurrence,
    required NarrativeFactRuntimeResolver factResolver,
    ValidatedLegacyClaimIndex? legacyClaimIndex,
    NarrativeEventProjectCatalog? projectCatalog,
  }) {
    final failed = registryResult.when<NarrativeEventDispatchAuthorityBlocked?>(
      absent: () => null,
      decoded: (_) => null,
      unsupported: (_, diagnostics) => NarrativeEventDispatchAuthorityBlocked(
        reason: NarrativeEventDispatchAuthorityBlockReason.unsupportedRegistry,
        diagnostics: diagnostics,
      ),
      invalid: (_, diagnostics) => NarrativeEventDispatchAuthorityBlocked(
        reason: NarrativeEventDispatchAuthorityBlockReason.invalidRegistry,
        diagnostics: diagnostics,
      ),
    );
    if (failed != null) return failed;

    final registry = registryResult.registryOrNull ??
        NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          records: const [],
          legacyClaims: const [],
        );
    if (registry.mode != EventSystemMode.legacyOnly && !factResolver.isValid) {
      return NarrativeEventDispatchAuthorityBlocked(
        reason: NarrativeEventDispatchAuthorityBlockReason.invalidFactResolver,
        diagnostics: [for (final issue in factResolver.issues) issue.message],
      );
    }
    if (registry.mode != EventSystemMode.legacyOnly && projectCatalog == null) {
      return NarrativeEventDispatchAuthorityBlocked(
        reason:
            NarrativeEventDispatchAuthorityBlockReason.projectCatalogRequired,
        diagnostics: const ['Event V2 dispatch requires a project catalog.'],
      );
    }
    if (registry.mode != EventSystemMode.legacyOnly &&
        projectCatalog!.hasBlockingDiagnostics) {
      return NarrativeEventDispatchAuthorityBlocked(
        reason:
            NarrativeEventDispatchAuthorityBlockReason.projectCatalogBlocked,
        diagnostics: [
          for (final diagnostic in projectCatalog.diagnostics)
            if (diagnostic.severity ==
                NarrativeEventProjectDiagnosticSeverity.error)
              diagnostic.code,
        ],
      );
    }
    if (registry.mode != EventSystemMode.legacyOnly &&
        !_catalogMatchesRegistry(registry, projectCatalog!)) {
      return NarrativeEventDispatchAuthorityBlocked(
        reason: NarrativeEventDispatchAuthorityBlockReason
            .projectCatalogSnapshotMismatch,
        diagnostics: const [
          'The project catalog does not match the decoded registry.',
        ],
      );
    }

    var claimResolution = _LegacyClaimAuthorityResolution.absent;
    if (registry.mode == EventSystemMode.dualRead) {
      if (legacyClaimIndex == null) {
        return NarrativeEventDispatchAuthorityBlocked(
          reason: NarrativeEventDispatchAuthorityBlockReason
              .dualReadClaimIndexRequired,
          diagnostics: const ['dualRead requires a validated claim index.'],
        );
      }
      if (!legacyClaimIndex.runtimeEvidenceValidated ||
          !legacyClaimIndex.canRunDualRead) {
        return NarrativeEventDispatchAuthorityBlocked(
          reason: NarrativeEventDispatchAuthorityBlockReason
              .dualReadRuntimeNotReady,
          diagnostics: legacyClaimIndex.globalConflicts.isEmpty
              ? const ['dualRead runtime evidence is not ready.']
              : legacyClaimIndex.globalConflicts,
        );
      }
      if (!_claimIndexMatchesRegistry(registry, legacyClaimIndex)) {
        return NarrativeEventDispatchAuthorityBlocked(
          reason: NarrativeEventDispatchAuthorityBlockReason
              .claimIndexSnapshotMismatch,
          diagnostics: const [
            'The validated claim index does not match the decoded registry.',
          ],
        );
      }
      final resolution = _resolveClaim(
        occurrence,
        legacyClaimIndex,
      );
      if (resolution == null) {
        return NarrativeEventDispatchAuthorityBlocked(
          reason: NarrativeEventDispatchAuthorityBlockReason
              .claimSourceProvenanceMismatch,
          diagnostics: const [
            'Occurrence source and provenance do not resolve to one cohort.',
          ],
        );
      }
      claimResolution = resolution;
    }

    final sourceIndex = buildNarrativeEventSourceIndex(registry.records).index;
    return NarrativeEventDispatchAuthorityReady._(
      occurrence: occurrence,
      mode: registry.mode,
      registry: registry,
      sourceIndex: sourceIndex,
      factResolver: factResolver,
      projectCatalog: projectCatalog ?? _legacyOnlyCatalog,
      claimResolution: claimResolution,
    );
  }
}

final _legacyOnlyCatalog = NarrativeEventProjectCatalog(
  manifestHash: 'legacy-only',
  mapHashes: const {},
  spatialSources: NarrativeSpatialEventSourceCatalog(
    options: const [],
    diagnostics: const [],
  ),
  outcomeSources: NarrativeOutcomeEventSourceCatalog(
    options: const [],
    diagnostics: const [],
  ),
  scenes: const [],
  facts: const [],
  events: const [],
  diagnostics: const [],
);

bool _catalogMatchesRegistry(
  NarrativeEventRegistry registry,
  NarrativeEventProjectCatalog catalog,
) {
  if (catalog.events.length != registry.records.length) return false;
  final catalogRecords = {
    for (final entry in catalog.events) entry.record.id: entry.record,
  };
  if (catalogRecords.length != registry.records.length) return false;
  for (final record in registry.records) {
    if (catalogRecords[record.id] != record) return false;
  }
  return true;
}

sealed class NarrativeEventDispatchDecision {
  NarrativeEventDispatchDecision({
    required this.source,
    required this.mode,
    required this.legacyFallbackAllowed,
    required List<NarrativeEventDispatchReason> reasons,
  }) : reasons = List.unmodifiable(reasons);

  final NarrativeEventSourceRef source;
  final EventSystemMode mode;
  final bool legacyFallbackAllowed;
  final List<NarrativeEventDispatchReason> reasons;
}

@immutable
final class NarrativeEventDispatchHandled
    extends NarrativeEventDispatchDecision {
  NarrativeEventDispatchHandled({
    required super.source,
    required super.mode,
    required this.eventId,
    required this.sceneId,
    required this.reusePolicy,
    required this.priority,
    required this.order,
  }) : super(legacyFallbackAllowed: false, reasons: const []);

  final String eventId;
  final String sceneId;
  final NarrativeEventReusePolicy reusePolicy;
  final int priority;
  final int order;
}

@immutable
final class NarrativeEventDispatchClaimedButIneligible
    extends NarrativeEventDispatchDecision {
  NarrativeEventDispatchClaimedButIneligible({
    required super.source,
    required super.mode,
    required super.reasons,
  }) : super(legacyFallbackAllowed: false);
}

@immutable
final class NarrativeEventDispatchNoMatch
    extends NarrativeEventDispatchDecision {
  NarrativeEventDispatchNoMatch({
    required super.source,
    required super.mode,
    required super.legacyFallbackAllowed,
    required super.reasons,
  });
}

enum _LegacyClaimAuthorityResolution { absent, valid, tombstone }

_LegacyClaimAuthorityResolution? _resolveClaim(
  NarrativeEventOccurrence occurrence,
  ValidatedLegacyClaimIndex index,
) {
  final sourceResolution = index.resolveSource(occurrence.source);
  final provenance = occurrence.provenance;
  if (provenance == null) {
    return switch (sourceResolution) {
      LegacyClaimSourceAbsent() => _LegacyClaimAuthorityResolution.absent,
      LegacyClaimSourceValid() => _LegacyClaimAuthorityResolution.valid,
      LegacyClaimSourceTombstone() => _LegacyClaimAuthorityResolution.tombstone,
    };
  }
  final provenanceResolution = index.resolveProvenance(provenance);
  if (sourceResolution is LegacyClaimSourceAbsent &&
      provenanceResolution is LegacyClaimProvenanceAbsent) {
    return _LegacyClaimAuthorityResolution.absent;
  }
  if (sourceResolution is LegacyClaimSourceValid &&
      provenanceResolution is LegacyClaimProvenanceValid &&
      sourceResolution.cohortId == provenanceResolution.cohortId) {
    return _LegacyClaimAuthorityResolution.valid;
  }
  if (sourceResolution is LegacyClaimSourceTombstone &&
      provenanceResolution is LegacyClaimProvenanceTombstone &&
      sourceResolution.cohortId != null &&
      sourceResolution.cohortId == provenanceResolution.cohortId) {
    return _LegacyClaimAuthorityResolution.tombstone;
  }
  return null;
}

bool _claimIndexMatchesRegistry(
  NarrativeEventRegistry registry,
  ValidatedLegacyClaimIndex index,
) {
  final claimsBySource = <NarrativeEventSourceRef, LegacySourceClaim>{
    for (final claim in registry.legacyClaims) claim.source: claim,
  };
  if (claimsBySource.length != registry.legacyClaims.length) return false;
  for (final entry in index.validBySource.entries) {
    if (claimsBySource[entry.key] != entry.value) return false;
  }
  for (final source in index.invalidBySource.keys) {
    if (!claimsBySource.containsKey(source)) return false;
  }
  for (final claim in registry.legacyClaims) {
    final isValid = index.validBySource[claim.source] == claim;
    final isInvalid = index.invalidBySource.containsKey(claim.source);
    if (isValid == isInvalid) return false;
    if (_claimIsStructurallyInvalid(claim, registry.records) && isValid) {
      return false;
    }
  }
  for (final entry in index.validByProvenance.entries) {
    final claim = entry.value;
    if (claimsBySource[claim.source] != claim ||
        !claim.members.any((member) => member.provenance == entry.key)) {
      return false;
    }
  }
  return true;
}

bool _claimIsStructurallyInvalid(
  LegacySourceClaim claim,
  List<NarrativeEventRecord> records,
) {
  final byId = {for (final record in records) record.id: record};
  for (final targetId in claim.targetEventIds) {
    final target = byId[targetId]?.definitionOrNull;
    if (target == null || target.source != claim.source) return true;
  }
  return false;
}

List<NarrativeEventDispatchReason> _sortedReasons(
  Set<NarrativeEventDispatchReason> reasons,
) {
  final result = reasons.toList()
    ..sort((left, right) => left.index.compareTo(right.index));
  return result;
}

String? _sourceMapId(NarrativeEventSourceRef source) {
  return source.when(
    entityInteract: (mapId, _) => mapId,
    triggerEnter: (mapId, _) => mapId,
    mapEnter: (mapId) => mapId,
    outcomeReceived: (_) => null,
  );
}

List<String> _appendResetToken(List<String> tokens, String token) {
  final result = [...tokens, token];
  if (result.length > 256) {
    result.removeRange(0, result.length - 256);
  }
  return result;
}
