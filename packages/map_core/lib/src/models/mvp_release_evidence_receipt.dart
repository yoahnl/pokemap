import '../read_models/mvp_product_criterion.dart';
import '../read_models/mvp_release_gate.dart';

/// Machine-readable receipt emitted by an actual MVP journey execution.
final class MvpReleaseEvidenceReceipt {
  const MvpReleaseEvidenceReceipt._({
    required this.command,
    required this.workingDirectory,
    required this.durationMilliseconds,
    required this.exitCode,
    required this.releaseCandidateCommit,
    required this.capturedAtUtc,
    required this.source,
    required this.projectTreeHashSha256,
    required this.packageSha256,
    required this.sources,
    required this.criteria,
    required this.technicalCriteria,
  });

  static const int currentSchemaVersion = 2;

  factory MvpReleaseEvidenceReceipt.validated({
    required String command,
    String workingDirectory = '.',
    int durationMilliseconds = 0,
    required int exitCode,
    required String releaseCandidateCommit,
    required DateTime capturedAtUtc,
    required String source,
    required String projectTreeHashSha256,
    String? packageSha256,
    Iterable<String> sources = const [],
    required Iterable<MvpProductCriterionEvidence> criteria,
    Iterable<MvpReleaseGateExecutionReceipt> technicalCriteria = const [],
  }) {
    _requireNonBlank('command', command);
    _requireNonBlank('workingDirectory', workingDirectory);
    _requireNonBlank('source', source);
    _requireHex('releaseCandidateCommit', releaseCandidateCommit, 40);
    _requireHex('projectTreeHashSha256', projectTreeHashSha256, 64);
    if (packageSha256 != null) {
      _requireHex('packageSha256', packageSha256, 64);
    }
    if (durationMilliseconds < 0) {
      throw ArgumentError.value(
        durationMilliseconds,
        'durationMilliseconds',
        'must not be negative',
      );
    }
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
    final suppliedSources = sources.toList(growable: false);
    final normalizedSources = (suppliedSources.isEmpty
            ? <String>[
                source,
                ...observations.map((observation) => observation.source),
              ]
            : suppliedSources)
        .map((item) {
      _requireNonBlank('sources', item);
      return item.trim();
    }).toList(growable: false);
    if (normalizedSources.toSet().length != normalizedSources.length) {
      throw ArgumentError.value(sources, 'sources', 'must be unique');
    }
    final technicalObservations = technicalCriteria.toList(growable: false);
    return MvpReleaseEvidenceReceipt._(
      command: command.trim(),
      workingDirectory: workingDirectory.trim(),
      durationMilliseconds: durationMilliseconds,
      exitCode: exitCode,
      releaseCandidateCommit: releaseCandidateCommit.toLowerCase(),
      capturedAtUtc: capturedAtUtc,
      source: source.trim(),
      projectTreeHashSha256: projectTreeHashSha256.toLowerCase(),
      packageSha256: packageSha256?.toLowerCase(),
      sources: List.unmodifiable(normalizedSources),
      criteria: List.unmodifiable(observations),
      technicalCriteria: List.unmodifiable(technicalObservations),
    );
  }

  factory MvpReleaseEvidenceReceipt.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != currentSchemaVersion) {
      throw FormatException(
        'Unsupported MVP release evidence schema: ${json['schemaVersion']}',
      );
    }
    final rawCommand = json['command'];
    final rawWorkingDirectory = json['workingDirectory'];
    final rawDurationMilliseconds = json['durationMilliseconds'];
    final rawExitCode = json['exitCode'];
    final rawCommit = json['releaseCandidateCommit'];
    final rawCapturedAt = json['capturedAtUtc'];
    final rawSource = json['source'];
    final rawTreeHash = json['projectTreeHashSha256'];
    final rawPackageSha = json['packageSha256'];
    final rawSources = json['sources'];
    final rawCriteria = json['criteria'];
    final rawTechnicalCriteria = json['technicalCriteria'];
    if (rawCommand is! String ||
        rawWorkingDirectory is! String ||
        rawDurationMilliseconds is! int ||
        rawExitCode is! int ||
        rawCommit is! String ||
        rawCapturedAt is! String ||
        rawSource is! String ||
        rawTreeHash is! String ||
        (rawPackageSha != null && rawPackageSha is! String) ||
        rawSources is! List ||
        rawCriteria is! List ||
        rawTechnicalCriteria is! List) {
      throw const FormatException('Malformed MVP release evidence receipt.');
    }
    final capturedAt = DateTime.tryParse(rawCapturedAt);
    if (capturedAt == null || !capturedAt.isUtc) {
      throw const FormatException('capturedAtUtc must be a UTC ISO-8601 date.');
    }
    try {
      return MvpReleaseEvidenceReceipt.validated(
        command: rawCommand,
        workingDirectory: rawWorkingDirectory,
        durationMilliseconds: rawDurationMilliseconds,
        exitCode: rawExitCode,
        releaseCandidateCommit: rawCommit,
        capturedAtUtc: capturedAt,
        source: rawSource,
        projectTreeHashSha256: rawTreeHash,
        packageSha256: rawPackageSha as String?,
        sources: rawSources.map((raw) {
          if (raw is! String) {
            throw const FormatException(
              'Every MVP release evidence source must be a string.',
            );
          }
          return raw;
        }),
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
        technicalCriteria: rawTechnicalCriteria.map((raw) {
          if (raw is! Map) {
            throw const FormatException(
              'Every technical criterion observation must be an object.',
            );
          }
          return MvpReleaseGateExecutionReceipt.fromJson(
            raw.cast<String, dynamic>(),
          );
        }),
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid MVP release evidence receipt: $error');
    }
  }

  final String command;
  final String workingDirectory;
  final int durationMilliseconds;
  final int exitCode;
  final String releaseCandidateCommit;
  final DateTime capturedAtUtc;
  final String source;
  final String projectTreeHashSha256;
  final String? packageSha256;
  final List<String> sources;
  final List<MvpProductCriterionEvidence> criteria;
  final List<MvpReleaseGateExecutionReceipt> technicalCriteria;

  int get schemaVersion => currentSchemaVersion;

  bool get isSuccessful =>
      exitCode == 0 &&
      criteria.isNotEmpty &&
      criteria.every(
        (criterion) => criterion.status == MvpProductCriterionStatus.passed,
      );

  bool get isReleaseSuccessful =>
      isSuccessful &&
      packageSha256 != null &&
      MvpReleaseGateReport.evaluate(
        technicalCriteria.map(MvpReleaseGateEvidence.fromExecutionReceipt),
      ).isGo;

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': currentSchemaVersion,
        'command': command,
        'workingDirectory': workingDirectory,
        'durationMilliseconds': durationMilliseconds,
        'exitCode': exitCode,
        'releaseCandidateCommit': releaseCandidateCommit,
        'capturedAtUtc': capturedAtUtc.toIso8601String(),
        'source': source,
        'projectTreeHashSha256': projectTreeHashSha256,
        'packageSha256': packageSha256,
        'sources': sources,
        'criteria': criteria.map((criterion) => criterion.toJson()).toList(),
        'technicalCriteria':
            technicalCriteria.map((criterion) => criterion.toJson()).toList(),
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
