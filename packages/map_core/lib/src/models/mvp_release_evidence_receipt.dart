import '../read_models/mvp_product_criterion.dart';

/// Machine-readable receipt emitted by an actual MVP journey execution.
final class MvpReleaseEvidenceReceipt {
  const MvpReleaseEvidenceReceipt._({
    required this.command,
    required this.exitCode,
    required this.releaseCandidateCommit,
    required this.capturedAtUtc,
    required this.source,
    required this.projectTreeHashSha256,
    required this.criteria,
  });

  static const int currentSchemaVersion = 1;

  factory MvpReleaseEvidenceReceipt.validated({
    required String command,
    required int exitCode,
    required String releaseCandidateCommit,
    required DateTime capturedAtUtc,
    required String source,
    required String projectTreeHashSha256,
    required Iterable<MvpProductCriterionEvidence> criteria,
  }) {
    _requireNonBlank('command', command);
    _requireNonBlank('source', source);
    _requireHex('releaseCandidateCommit', releaseCandidateCommit, 40);
    _requireHex('projectTreeHashSha256', projectTreeHashSha256, 64);
    if (!capturedAtUtc.isUtc) {
      throw ArgumentError.value(
        capturedAtUtc,
        'capturedAtUtc',
        'must use UTC',
      );
    }
    final observations = criteria.toList(growable: false);
    for (final observation in observations) {
      _requireNonBlank('criterion.summary', observation.summary);
      _requireNonBlank('criterion.source', observation.source);
    }
    return MvpReleaseEvidenceReceipt._(
      command: command.trim(),
      exitCode: exitCode,
      releaseCandidateCommit: releaseCandidateCommit.toLowerCase(),
      capturedAtUtc: capturedAtUtc,
      source: source.trim(),
      projectTreeHashSha256: projectTreeHashSha256.toLowerCase(),
      criteria: List.unmodifiable(observations),
    );
  }

  factory MvpReleaseEvidenceReceipt.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != currentSchemaVersion) {
      throw FormatException(
        'Unsupported MVP release evidence schema: ${json['schemaVersion']}',
      );
    }
    final rawCommand = json['command'];
    final rawExitCode = json['exitCode'];
    final rawCommit = json['releaseCandidateCommit'];
    final rawCapturedAt = json['capturedAtUtc'];
    final rawSource = json['source'];
    final rawTreeHash = json['projectTreeHashSha256'];
    final rawCriteria = json['criteria'];
    if (rawCommand is! String ||
        rawExitCode is! int ||
        rawCommit is! String ||
        rawCapturedAt is! String ||
        rawSource is! String ||
        rawTreeHash is! String ||
        rawCriteria is! List) {
      throw const FormatException('Malformed MVP release evidence receipt.');
    }
    final capturedAt = DateTime.tryParse(rawCapturedAt);
    if (capturedAt == null || !capturedAt.isUtc) {
      throw const FormatException('capturedAtUtc must be a UTC ISO-8601 date.');
    }
    try {
      return MvpReleaseEvidenceReceipt.validated(
        command: rawCommand,
        exitCode: rawExitCode,
        releaseCandidateCommit: rawCommit,
        capturedAtUtc: capturedAt,
        source: rawSource,
        projectTreeHashSha256: rawTreeHash,
        criteria: rawCriteria.map((raw) {
          if (raw is! Map) {
            throw const FormatException(
              'Every MVP criterion observation must be an object.',
            );
          }
          return MvpProductCriterionEvidence.fromJson(
            raw.cast<String, dynamic>(),
          );
        }),
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid MVP release evidence receipt: $error');
    }
  }

  final String command;
  final int exitCode;
  final String releaseCandidateCommit;
  final DateTime capturedAtUtc;
  final String source;
  final String projectTreeHashSha256;
  final List<MvpProductCriterionEvidence> criteria;

  int get schemaVersion => currentSchemaVersion;

  bool get isSuccessful =>
      exitCode == 0 &&
      criteria.isNotEmpty &&
      criteria.every(
        (criterion) => criterion.status == MvpProductCriterionStatus.passed,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': currentSchemaVersion,
        'command': command,
        'exitCode': exitCode,
        'releaseCandidateCommit': releaseCandidateCommit,
        'capturedAtUtc': capturedAtUtc.toIso8601String(),
        'source': source,
        'projectTreeHashSha256': projectTreeHashSha256,
        'criteria': criteria.map((criterion) => criterion.toJson()).toList(),
      };
}

void _requireNonBlank(String fieldName, String value) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be blank');
  }
}

void _requireHex(String fieldName, String value, int length) {
  if (!RegExp('^[0-9a-fA-F]{$length}' r'$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      fieldName,
      'must contain exactly $length hexadecimal characters',
    );
  }
}
