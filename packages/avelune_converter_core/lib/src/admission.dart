part of '../avelune_converter_core.dart';

final class SourceIdentity {
  SourceIdentity(this.namespace, this.domain, this.sourceId) {
    _require(sourceId >= 0 && sourceId <= 2147483647, 'identity.sourceId', r'$',
        'Source identity is outside supported bounds');
  }
  final ConverterId namespace;
  final ConverterId domain;
  final int sourceId;
  ConverterId get stableId => ConverterId('s1:${canonicalHashOf([
            'avelune-converter-id-v1',
            namespace.value,
            domain.value,
            sourceId,
          ]).value}');
}

final class PlanContext {
  PlanContext({
    required this.logicalProjectNamespace,
    required this.sourceSnapshotHash,
    required this.sessionId,
    required this.targetCapabilities,
    required this.rulesHash,
    required this.decisions,
    required List<AssetCandidate> candidates,
    required this.converterVersion,
    required this.approvedPlanHash,
    required Set<int> sourceMapIds,
    required Set<ConverterId> sourceEntityIds,
    required Set<ConverterId> targetEntityIds,
    required Map<String, ConverterId> actionCapabilities,
    required Map<ConverterId, Sha256Hash> approvedCandidateHashes,
  })  : candidates = List.unmodifiable(candidates),
        sourceMapIds = Set.unmodifiable(sourceMapIds),
        sourceEntityIds = Set.unmodifiable(sourceEntityIds),
        targetEntityIds = Set.unmodifiable(targetEntityIds),
        actionCapabilities = Map.unmodifiable(actionCapabilities),
        approvedCandidateHashes = Map.unmodifiable(approvedCandidateHashes);
  final ConverterId logicalProjectNamespace;
  final ConverterId sessionId;
  final Sha256Hash sourceSnapshotHash;
  final TargetCapabilities targetCapabilities;
  final Sha256Hash rulesHash;
  final ReviewDecisions decisions;
  final List<AssetCandidate> candidates;
  final String converterVersion;
  final Sha256Hash approvedPlanHash;
  final Set<int> sourceMapIds;
  final Set<ConverterId> sourceEntityIds;
  final Set<ConverterId> targetEntityIds;
  final Map<String, ConverterId> actionCapabilities;
  final Map<ConverterId, Sha256Hash> approvedCandidateHashes;
}

final class AdmittedPlan {
  AdmittedPlan._(this.plan);
  final ConversionPlan plan;
}

abstract interface class PlanApplicationPort {
  Future<void> apply(AdmittedPlan admitted);
}

AdmittedPlan admitPlan(ConversionPlan plan, PlanContext context) {
  _require(
      !plan.exampleOnly &&
          !context.targetCapabilities.exampleOnly &&
          !context.decisions.exampleOnly &&
          !context.candidates.any((c) => c.exampleOnly),
      'policy.exampleOnly',
      r'$',
      'Demonstration data cannot be applied');
  _require(
      plan.state == PlanState.ready && plan.approvedByHuman,
      'policy.ready',
      r'$.state',
      'Only a human-approved ready plan can be applied');
  _require(
      plan.canonicalHash == context.approvedPlanHash,
      'policy.planApproval',
      r'$',
      'Exact plan content is not approved in this context');
  _require(plan.logicalProjectNamespace == context.logicalProjectNamespace,
      'policy.namespace', r'$.logicalProjectNamespace', 'Namespace changed');
  _require(
      plan.sourceSnapshotHash == context.sourceSnapshotHash &&
          context.decisions.sourceSnapshotHash == context.sourceSnapshotHash,
      'policy.snapshot',
      r'$.sourceSnapshotHash',
      'Source snapshot changed');
  _require(
      plan.targetProfileHash == context.targetCapabilities.canonicalHash &&
          context.targetCapabilities.repository.trim().isNotEmpty &&
          context.targetCapabilities.revision.trim().isNotEmpty,
      'policy.profile',
      r'$.targetProfileHash',
      'Target profile changed or lacks identity');
  _require(
      plan.rulesHash == context.rulesHash &&
          plan.decisionsHash == context.decisions.canonicalHash &&
          plan.decisionRevision == context.decisions.revision &&
          context.decisions.sessionId == context.sessionId &&
          plan.converterVersion == context.converterVersion &&
          plan.converterVersion.isNotEmpty,
      'policy.context',
      r'$',
      'Rules, decisions, session or converter revision changed');
  _require(
      [...plan.selectedSourceMapIds, ...plan.dependencySourceMapIds]
          .every(context.sourceMapIds.contains),
      'policy.mapReference',
      r'$.selectedSourceMapIds',
      'Unknown source map');
  _unique(
      context.candidates.map((c) => c.candidateId), r'$.context.candidates');
  final candidates = {for (final c in context.candidates) c.candidateId: c};
  _require(
      context.approvedCandidateHashes.keys.every(candidates.containsKey),
      'policy.approvalReference',
      r'$.context.approvedCandidateHashes',
      'Approval receipt references an unknown candidate');
  for (final candidate in context.candidates) {
    if (candidate.state == CandidateState.approved) {
      _require(
          context.approvedCandidateHashes[candidate.candidateId] ==
              candidate.canonicalHash,
          'policy.candidateContent',
          r'$.context.approvedCandidateHashes',
          'Exact candidate content lacks a matching human approval receipt');
    }
    _require(
        candidate.sourceSnapshotHash == context.sourceSnapshotHash &&
            candidate.logicalProjectNamespace ==
                context.logicalProjectNamespace &&
            candidate.outputMode == plan.outputPolicy.assetOutputMode,
        'policy.candidateContext',
        r'$.context.candidates',
        'Candidate snapshot, namespace or output policy changed');
  }
  for (final decision in context.decisions.decisions) {
    final candidate = candidates[decision.candidateId];
    _require(
        candidate != null && candidate.revision == decision.candidateRevision,
        'policy.decisionReference',
        r'$.context.decisions',
        'Unknown or stale decision candidate');
    _require(
        decision.replacementCandidateIds.every(candidates.containsKey),
        'policy.replacementReference',
        r'$.context.decisions',
        'Unknown replacement candidate');
    if (decision.action == ReviewAction.approve) {
      _require(
          decision.humanConfirmed &&
              candidate!.state == CandidateState.approved &&
              candidate.approvedRevision == candidate.revision,
          'policy.candidateApproval',
          r'$.context.decisions',
          'Candidate approval is not current');
    }
  }
  final capabilities = {
    for (final c in context.targetCapabilities.capabilities) c.capabilityId: c,
  };
  final operations = plan.operations;
  for (var i = 0; i < operations.length; i++) {
    final operation = operations[i];
    final path = r'$.operations' '[$i]';
    _require(operation.status != OperationStatus.blocked,
        'policy.operationBlocked', path, 'Blocked operation cannot be applied');
    _require(
        operation.sourceEntityIds.every(context.sourceEntityIds.contains) &&
            operation.targetEntityIds.every(context.targetEntityIds.contains),
        'policy.entityReference',
        path,
        'Operation references an unknown entity');
    if (operation.status == OperationStatus.planned) {
      final action = operation.targetActionId;
      final capability = capabilities[context.actionCapabilities[action]];
      _require(
          action != null &&
              action.trim().isNotEmpty &&
              capability?.status == CapabilityStatus.supported,
          'policy.targetAction',
          path,
          'Action lacks an audited supported capability');
      for (final id
          in operation.sourceEntityIds.where(candidates.containsKey)) {
        final candidate = candidates[id]!;
        _require(
            candidate.state == CandidateState.approved &&
                candidate.approvedRevision == candidate.revision &&
                context.decisions.decisions.any((d) =>
                    d.candidateId == id &&
                    d.candidateRevision == candidate.revision &&
                    d.action == ReviewAction.approve &&
                    d.humanConfirmed),
            'policy.assetApproval',
            path,
            'Consuming a candidate requires current human approval');
      }
    }
  }
  final decisions = {
    for (final d in context.decisions.decisions) d.decisionId: d
  };
  final findings = plan.findings;
  for (var i = 0; i < findings.length; i++) {
    final finding = findings[i];
    final path = r'$.findings' '[$i]';
    _require(
        finding.severity != DiagnosticSeverity.error ||
            (finding.cause != DiagnosticCause.security &&
                finding.cause != DiagnosticCause.sourceInvalid),
        'policy.nonConsentable',
        path,
        'Safety and invalid-data errors cannot be consented away');
    if (finding.disposition == DiagnosticDisposition.acceptedStudyLoss) {
      final decision = decisions[finding.acceptedByDecisionId];
      _require(
          plan.requestedMode == ConversionMode.study &&
              decision != null &&
              decision.humanConfirmed &&
              decision.action == ReviewAction.keepLiteral &&
              decision.note.trim().isNotEmpty &&
              finding.sourceLocator != null &&
              candidates[decision.candidateId]!.parts.any((part) =>
                  _sameSourceLocator(part.locator, finding.sourceLocator!)),
          'policy.studyLoss',
          path,
          'Study loss lacks an applicable confirmed decision');
      continue;
    }
    final blocks = plan.requestedMode == ConversionMode.study
        ? finding.blocksStudy
        : finding.blocksPlayableSlice;
    _require(
        !blocks &&
            !(finding.severity == DiagnosticSeverity.error &&
                finding.disposition == DiagnosticDisposition.unresolved),
        'policy.diagnosticBlocked',
        path,
        'Finding blocks the requested mode');
  }
  return AdmittedPlan._(plan);
}

Future<void> applyConversionPlan(
    ConversionPlan plan, PlanContext context, PlanApplicationPort port) async {
  final admitted = admitPlan(plan, context);
  await port.apply(admitted);
}

final class VisionRequestContext {
  VisionRequestContext({
    required this.requestId,
    required this.sourceSnapshotHash,
    required this.inputRevision,
    required Set<ConverterId> candidateIds,
    required Set<ConverterId> sourceRegionIds,
  })  : candidateIds = Set.unmodifiable(candidateIds),
        sourceRegionIds = Set.unmodifiable(sourceRegionIds) {
    _require(inputRevision >= 1 && inputRevision <= 2147483647,
        'vision.revision', r'$', 'Invalid request revision');
  }
  final ConverterId requestId;
  final Sha256Hash sourceSnapshotHash;
  final int inputRevision;
  final Set<ConverterId> candidateIds;
  final Set<ConverterId> sourceRegionIds;
}

void validateVisionResponse(
    VisionResponse response, VisionRequestContext context) {
  _require(
      !response.exampleOnly &&
          response.requestId == context.requestId &&
          response.sourceSnapshotHash == context.sourceSnapshotHash &&
          response.inputRevision == context.inputRevision,
      'vision.context',
      r'$',
      'Response is demonstrative or belongs to another request snapshot');
  for (var i = 0; i < response.suggestions.length; i++) {
    final suggestion = response.suggestions[i];
    _require(
        suggestion.candidateIds.every(context.candidateIds.contains) &&
            suggestion.sourceRegionIds.every(context.sourceRegionIds.contains),
        'vision.allowedIds',
        r'$.suggestions' '[$i]',
        'Suggestion contains unrequested IDs');
  }
}

bool _sameSourceLocator(SourceLocator a, SourceLocator b) =>
    a.file == b.file &&
    a.mapId == b.mapId &&
    a.eventId == b.eventId &&
    a.pageIndex == b.pageIndex &&
    a.commandIndex == b.commandIndex &&
    a.tileId == b.tileId &&
    a.line == b.line;
