/// The five independent evidence groups required by FG-185.
enum MvpReleaseGateCriterion {
  goldenSlice,
  projectGameplayReadiness,
  criticalPackageTests,
  postMvpLimitationsDocumented,
  userScopeApproved,
}

/// State of one externally produced release-gate proof.
enum MvpReleaseGateEvidenceStatus {
  passed,
  failed,
  unverified,
}

/// Evidence supplied to the FG-185 release-gate aggregator.
///
/// This object records an external proof. It does not run tests or validators
/// itself, so callers must keep [source] and [summary] tied to fresh evidence.
final class MvpReleaseGateEvidence {
  const MvpReleaseGateEvidence({
    required this.criterion,
    required this.status,
    required this.summary,
    this.source,
  });

  final MvpReleaseGateCriterion criterion;
  final MvpReleaseGateEvidenceStatus status;
  final String summary;
  final String? source;
}

/// Fail-closed decision for `FG-185 — MVP Release Gate V0`.
///
/// Every criterion must have exactly one passing proof. Missing or duplicate
/// evidence remains a blocker. Passing claims must also carry a non-empty
/// summary and source so a status flag alone cannot accidentally promote a
/// partial demonstrator to a global MVP release.
final class MvpReleaseGateReport {
  MvpReleaseGateReport._(
      Map<MvpReleaseGateCriterion, MvpReleaseGateEvidence> evidence)
      : evidenceByCriterion = Map.unmodifiable(evidence);

  factory MvpReleaseGateReport.evaluate(
    Iterable<MvpReleaseGateEvidence> evidence,
  ) {
    final suppliedByCriterion =
        <MvpReleaseGateCriterion, List<MvpReleaseGateEvidence>>{};
    for (final item in evidence) {
      suppliedByCriterion.putIfAbsent(item.criterion, () => []).add(item);
    }

    final normalized = <MvpReleaseGateCriterion, MvpReleaseGateEvidence>{};
    for (final criterion in MvpReleaseGateCriterion.values) {
      final supplied = suppliedByCriterion[criterion] ?? const [];
      normalized[criterion] = switch (supplied.length) {
        0 => MvpReleaseGateEvidence(
            criterion: criterion,
            status: MvpReleaseGateEvidenceStatus.unverified,
            summary: 'Aucune preuve fournie pour ${criterion.name}.',
          ),
        1 => _normalizeSingleEvidence(supplied.single),
        _ => MvpReleaseGateEvidence(
            criterion: criterion,
            status: MvpReleaseGateEvidenceStatus.failed,
            summary:
                'Preuves dupliquees ou contradictoires pour ${criterion.name}.',
          ),
      };
    }

    return MvpReleaseGateReport._(normalized);
  }

  final Map<MvpReleaseGateCriterion, MvpReleaseGateEvidence>
      evidenceByCriterion;

  bool get isGo => evidenceByCriterion.values.every(
        (item) => item.status == MvpReleaseGateEvidenceStatus.passed,
      );

  List<MvpReleaseGateEvidence> get blockers => List.unmodifiable(
        evidenceByCriterion.values.where(
          (item) => item.status != MvpReleaseGateEvidenceStatus.passed,
        ),
      );
}

MvpReleaseGateEvidence _normalizeSingleEvidence(
  MvpReleaseGateEvidence evidence,
) {
  // Failed and unverified proofs are already conservative. Metadata is
  // mandatory only for a claim that would otherwise contribute to a GO.
  if (evidence.status != MvpReleaseGateEvidenceStatus.passed) {
    return evidence;
  }

  if (evidence.summary.trim().isEmpty) {
    return MvpReleaseGateEvidence(
      criterion: evidence.criterion,
      status: MvpReleaseGateEvidenceStatus.failed,
      summary: 'La preuve passed ne fournit aucun resume exploitable.',
      source: evidence.source,
    );
  }

  if (evidence.source?.trim().isEmpty ?? true) {
    return MvpReleaseGateEvidence(
      criterion: evidence.criterion,
      status: MvpReleaseGateEvidenceStatus.failed,
      summary: 'La preuve passed ne fournit aucune source exploitable.',
    );
  }

  return evidence;
}
