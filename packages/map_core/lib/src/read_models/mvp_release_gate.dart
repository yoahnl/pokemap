/// The five independent evidence groups required by FG-185.
enum MvpReleaseGateCriterion {
  goldenSlice,
  projectGameplayReadiness,
  criticalPackageTests,
  postMvpLimitationsDocumented,
  userScopeApproved,
}

/// State of one release-gate evidence item.
enum MvpReleaseGateEvidenceStatus {
  passed,
  failed,
  unverified,
}

/// Provenance enforced by the FG-185 release-gate contract.
enum MvpReleaseGateEvidenceKind {
  /// A historical or documentary assertion that cannot contribute to GO.
  declaredEvidence,

  /// Evidence derived from a structurally validated execution receipt.
  executedEvidence,

  /// A fail-closed blocker synthesized by the aggregator itself.
  gateGeneratedBlocker,
}

/// Structured receipt for one externally executed release-gate criterion.
///
/// The private constructor prevents callers from relabelling an arbitrary
/// declaration as executed evidence. [validated] is pure: it only validates
/// the supplied immutable metadata and performs no process or file-system I/O.
final class MvpReleaseGateExecutionReceipt {
  const MvpReleaseGateExecutionReceipt._({
    required this.criterion,
    required this.summary,
    required this.source,
    required this.releaseCandidateCommit,
    required this.command,
    required this.exitCode,
    required this.outputDigestSha256,
  });

  /// Validates non-blank text, a full 40-hex commit, and a full 64-hex digest.
  factory MvpReleaseGateExecutionReceipt.validated({
    required MvpReleaseGateCriterion criterion,
    required String summary,
    required String source,
    required String releaseCandidateCommit,
    required String command,
    required int exitCode,
    required String outputDigestSha256,
  }) {
    _requireNonBlank('summary', summary);
    _requireNonBlank('source', source);
    _requireFullHexDigest(
      fieldName: 'releaseCandidateCommit',
      value: releaseCandidateCommit,
      length: 40,
    );
    _requireNonBlank('command', command);
    _requireFullHexDigest(
      fieldName: 'outputDigestSha256',
      value: outputDigestSha256,
      length: 64,
    );

    return MvpReleaseGateExecutionReceipt._(
      criterion: criterion,
      summary: summary.trim(),
      source: source.trim(),
      releaseCandidateCommit: releaseCandidateCommit.toLowerCase(),
      command: command.trim(),
      exitCode: exitCode,
      outputDigestSha256: outputDigestSha256.toLowerCase(),
    );
  }

  factory MvpReleaseGateExecutionReceipt.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawCriterion = json['criterion'];
    final rawSummary = json['summary'];
    final rawSource = json['source'];
    final rawCommit = json['releaseCandidateCommit'];
    final rawCommand = json['command'];
    final rawExitCode = json['exitCode'];
    final rawOutputDigest = json['outputDigestSha256'];
    if (rawCriterion is! String ||
        rawSummary is! String ||
        rawSource is! String ||
        rawCommit is! String ||
        rawCommand is! String ||
        rawExitCode is! int ||
        rawOutputDigest is! String) {
      throw const FormatException(
        'Malformed MVP release gate execution receipt.',
      );
    }
    final criterion = MvpReleaseGateCriterion.values
        .where((candidate) => candidate.name == rawCriterion)
        .firstOrNull;
    if (criterion == null) {
      throw FormatException(
        'Unknown MVP release gate criterion: $rawCriterion',
      );
    }
    try {
      return MvpReleaseGateExecutionReceipt.validated(
        criterion: criterion,
        summary: rawSummary,
        source: rawSource,
        releaseCandidateCommit: rawCommit,
        command: rawCommand,
        exitCode: rawExitCode,
        outputDigestSha256: rawOutputDigest,
      );
    } on ArgumentError catch (error) {
      throw FormatException(
        'Invalid MVP release gate execution receipt: $error',
      );
    }
  }

  final MvpReleaseGateCriterion criterion;
  final String summary;
  final String source;
  final String releaseCandidateCommit;
  final String command;
  final int exitCode;
  final String outputDigestSha256;

  Map<String, Object?> toJson() => <String, Object?>{
        'criterion': criterion.name,
        'summary': summary,
        'source': source,
        'releaseCandidateCommit': releaseCandidateCommit,
        'command': command,
        'exitCode': exitCode,
        'outputDigestSha256': outputDigestSha256,
      };
}

/// Evidence supplied to the FG-185 release-gate aggregator.
///
/// Documentary evidence and executed evidence have separate construction
/// paths. In particular, callers cannot freely supply the kind or status of
/// executed evidence: both are derived by [fromExecutionReceipt].
final class MvpReleaseGateEvidence {
  const MvpReleaseGateEvidence._({
    required this.criterion,
    required this.evidenceKind,
    required this.status,
    required this.summary,
    required this.source,
    required this.executionReceipt,
  });

  /// Creates an explicitly documentary assertion.
  ///
  /// Its status records what the document claims. Even a `passed` declaration
  /// remains a blocker because it has no validated execution receipt.
  const MvpReleaseGateEvidence.declared({
    required this.criterion,
    required this.status,
    required this.summary,
    this.source,
  })  : evidenceKind = MvpReleaseGateEvidenceKind.declaredEvidence,
        executionReceipt = null;

  /// Creates executed evidence exclusively from a validated receipt.
  factory MvpReleaseGateEvidence.fromExecutionReceipt(
    MvpReleaseGateExecutionReceipt receipt,
  ) =>
      MvpReleaseGateEvidence._(
        criterion: receipt.criterion,
        evidenceKind: MvpReleaseGateEvidenceKind.executedEvidence,
        status: receipt.exitCode == 0
            ? MvpReleaseGateEvidenceStatus.passed
            : MvpReleaseGateEvidenceStatus.failed,
        summary: receipt.summary,
        source: receipt.source,
        executionReceipt: receipt,
      );

  /// Creates a synthetic blocker that cannot be confused with a declaration.
  const MvpReleaseGateEvidence._gateGeneratedBlocker({
    required this.criterion,
    required this.status,
    required this.summary,
  })  : evidenceKind = MvpReleaseGateEvidenceKind.gateGeneratedBlocker,
        source = null,
        executionReceipt = null;

  final MvpReleaseGateCriterion criterion;
  final MvpReleaseGateEvidenceKind evidenceKind;
  final MvpReleaseGateEvidenceStatus status;
  final String summary;
  final String? source;
  final MvpReleaseGateExecutionReceipt? executionReceipt;
}

/// Fail-closed decision for `FG-185 — MVP Release Gate V0`.
///
/// Every criterion must have exactly one successful executed receipt. Missing,
/// duplicate, failed, unverified, or merely declared evidence remains a
/// blocker. The aggregator stays pure and never executes or reads the receipt
/// source itself.
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
        0 => MvpReleaseGateEvidence._gateGeneratedBlocker(
            criterion: criterion,
            status: MvpReleaseGateEvidenceStatus.unverified,
            summary: 'Aucune preuve fournie pour ${criterion.name}.',
          ),
        1 => _normalizeSingleEvidence(supplied.single),
        _ => MvpReleaseGateEvidence._gateGeneratedBlocker(
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

  bool get isGo => evidenceByCriterion.values.every(_contributesToGo);

  List<MvpReleaseGateEvidence> get blockers => List.unmodifiable(
        evidenceByCriterion.values.where((item) => !_contributesToGo(item)),
      );
}

bool _contributesToGo(MvpReleaseGateEvidence evidence) {
  final receipt = evidence.executionReceipt;
  return evidence.evidenceKind == MvpReleaseGateEvidenceKind.executedEvidence &&
      evidence.status == MvpReleaseGateEvidenceStatus.passed &&
      receipt != null &&
      receipt.exitCode == 0;
}

MvpReleaseGateEvidence _normalizeSingleEvidence(
  MvpReleaseGateEvidence evidence,
) {
  // Receipt metadata has already been validated by its only public factory.
  // Non-passing evidence is already conservative and needs no promotion path.
  if (evidence.status != MvpReleaseGateEvidenceStatus.passed ||
      evidence.evidenceKind == MvpReleaseGateEvidenceKind.executedEvidence) {
    return evidence;
  }

  if (evidence.summary.trim().isEmpty) {
    return MvpReleaseGateEvidence.declared(
      criterion: evidence.criterion,
      status: MvpReleaseGateEvidenceStatus.failed,
      summary: 'La declaration passed ne fournit aucun resume exploitable.',
      source: evidence.source,
    );
  }

  if (evidence.source?.trim().isEmpty ?? true) {
    return MvpReleaseGateEvidence.declared(
      criterion: evidence.criterion,
      status: MvpReleaseGateEvidenceStatus.failed,
      summary: 'La declaration passed ne fournit aucune source exploitable.',
    );
  }

  return evidence;
}

void _requireNonBlank(String fieldName, String value) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be blank');
  }
}

void _requireFullHexDigest({
  required String fieldName,
  required String value,
  required int length,
}) {
  if (!RegExp('^[0-9a-fA-F]{$length}\$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      fieldName,
      'must contain exactly $length hexadecimal characters',
    );
  }
}
