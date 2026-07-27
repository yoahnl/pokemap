enum PersonalizationReleaseCriterion {
  installedGoldenFlow,
  safeFallbacks,
  previewRuntimeParity,
  packagePreflight,
}

enum PersonalizationReleaseEvidenceStatus {
  passed,
  failed,
  notEvaluated,
}

final class PersonalizationReleaseCriterionEvidence {
  const PersonalizationReleaseCriterionEvidence({
    required this.criterion,
    required this.status,
    required this.summary,
    required this.source,
  });

  factory PersonalizationReleaseCriterionEvidence.fromJson(
    Map<String, dynamic> json,
  ) {
    final criterion = _enumByName(
      PersonalizationReleaseCriterion.values,
      json['criterion'],
      'criterion',
    );
    final status = _enumByName(
      PersonalizationReleaseEvidenceStatus.values,
      json['status'],
      'status',
    );
    final summary = json['summary'];
    final source = json['source'];
    if (summary is! String || source is! String) {
      throw const FormatException(
        'Malformed personalization criterion evidence.',
      );
    }
    return PersonalizationReleaseCriterionEvidence(
      criterion: criterion,
      status: status,
      summary: summary,
      source: source,
    );
  }

  final PersonalizationReleaseCriterion criterion;
  final PersonalizationReleaseEvidenceStatus status;
  final String summary;
  final String source;

  Map<String, Object?> toJson() => <String, Object?>{
        'criterion': criterion.name,
        'status': status.name,
        'summary': summary,
        'source': source,
      };
}

final class PersonalizationPlatformCodecEvidence {
  const PersonalizationPlatformCodecEvidence({
    required this.platform,
    required this.videoCodec,
    required this.audioCodec,
    this.buildExitCode,
    this.launchExitCode,
    required this.source,
  });

  factory PersonalizationPlatformCodecEvidence.fromJson(
    Map<String, dynamic> json,
  ) {
    final platform = json['platform'];
    final videoCodec = json['videoCodec'];
    final audioCodec = json['audioCodec'];
    final buildExitCode = json['buildExitCode'];
    final launchExitCode = json['launchExitCode'];
    final source = json['source'];
    if (platform is! String ||
        videoCodec is! String ||
        audioCodec is! String ||
        (buildExitCode != null && buildExitCode is! int) ||
        (launchExitCode != null && launchExitCode is! int) ||
        source is! String) {
      throw const FormatException(
        'Malformed personalization platform evidence.',
      );
    }
    return PersonalizationPlatformCodecEvidence(
      platform: platform,
      videoCodec: videoCodec,
      audioCodec: audioCodec,
      buildExitCode: buildExitCode as int?,
      launchExitCode: launchExitCode as int?,
      source: source,
    );
  }

  final String platform;
  final String videoCodec;
  final String audioCodec;
  final int? buildExitCode;
  final int? launchExitCode;
  final String source;

  bool get hasCompleteEvidence =>
      buildExitCode != null && launchExitCode != null;

  bool get isSuccessful =>
      buildExitCode == 0 && launchExitCode == 0 && hasCompleteEvidence;

  Map<String, Object?> toJson() => <String, Object?>{
        'platform': platform,
        'videoCodec': videoCodec,
        'audioCodec': audioCodec,
        if (buildExitCode != null) 'buildExitCode': buildExitCode,
        if (launchExitCode != null) 'launchExitCode': launchExitCode,
        'source': source,
      };
}

/// Candidate-bound decision receipt for the PH-007 personalization gate.
///
/// The four behavioral criteria are supplied as linked observations. Platform
/// readiness is derived from build and launch exit codes so a build-only row
/// can never be promoted to GO.
final class PersonalizationReleaseGateReceipt {
  PersonalizationReleaseGateReceipt._({
    required this.releaseCandidateCommit,
    required this.capturedAtUtc,
    required this.contentTreeHashSha256,
    required this.packageSha256,
    required this.presentationSha256,
    required this.criteria,
    required this.platforms,
  });

  static const int currentSchemaVersion = 1;

  factory PersonalizationReleaseGateReceipt.validated({
    required String releaseCandidateCommit,
    required DateTime capturedAtUtc,
    required String contentTreeHashSha256,
    required String packageSha256,
    required String presentationSha256,
    required Iterable<PersonalizationReleaseCriterionEvidence> criteria,
    required Iterable<PersonalizationPlatformCodecEvidence> platforms,
  }) {
    _requireHex('releaseCandidateCommit', releaseCandidateCommit, 40);
    _requireHex('contentTreeHashSha256', contentTreeHashSha256, 64);
    _requireHex('packageSha256', packageSha256, 64);
    _requireHex('presentationSha256', presentationSha256, 64);
    if (!capturedAtUtc.isUtc) {
      throw ArgumentError.value(
        capturedAtUtc,
        'capturedAtUtc',
        'must use UTC',
      );
    }

    final criterionList = criteria.toList(growable: false);
    final counts = <PersonalizationReleaseCriterion, int>{};
    for (final evidence in criterionList) {
      counts[evidence.criterion] = (counts[evidence.criterion] ?? 0) + 1;
      _requireText('criterion.summary', evidence.summary);
      _requireText('criterion.source', evidence.source);
    }
    final cardinalityIssues = <String>[];
    for (final criterion in PersonalizationReleaseCriterion.values) {
      final count = counts[criterion] ?? 0;
      if (count == 0) {
        cardinalityIssues.add('Missing criterion ${criterion.name}.');
      } else if (count > 1) {
        cardinalityIssues.add('Duplicate criterion ${criterion.name}.');
      }
    }
    if (cardinalityIssues.isNotEmpty) {
      throw StateError(cardinalityIssues.join(' '));
    }

    final platformList = platforms.toList(growable: false);
    final normalizedPlatforms = <String>{};
    for (final evidence in platformList) {
      _requireText('platform.platform', evidence.platform);
      _requireText('platform.videoCodec', evidence.videoCodec);
      _requireText('platform.audioCodec', evidence.audioCodec);
      _requireText('platform.source', evidence.source);
      if ((evidence.buildExitCode ?? 0) < 0 ||
          (evidence.launchExitCode ?? 0) < 0) {
        throw ArgumentError.value(
          evidence.toJson(),
          'platforms',
          'exit codes must not be negative',
        );
      }
      final normalized = evidence.platform.trim().toLowerCase();
      if (!normalizedPlatforms.add(normalized)) {
        throw ArgumentError.value(
          evidence.platform,
          'platforms',
          'platform rows must be unique',
        );
      }
    }

    return PersonalizationReleaseGateReceipt._(
      releaseCandidateCommit: releaseCandidateCommit.toLowerCase(),
      capturedAtUtc: capturedAtUtc,
      contentTreeHashSha256: contentTreeHashSha256.toLowerCase(),
      packageSha256: packageSha256.toLowerCase(),
      presentationSha256: presentationSha256.toLowerCase(),
      criteria: List.unmodifiable(criterionList),
      platforms: List.unmodifiable(platformList),
    );
  }

  factory PersonalizationReleaseGateReceipt.fromJson(
    Map<String, dynamic> json,
  ) {
    if (json['schemaVersion'] != currentSchemaVersion) {
      throw FormatException(
        'Unsupported personalization release receipt schema: '
        '${json['schemaVersion']}',
      );
    }
    final releaseCandidateCommit = json['releaseCandidateCommit'];
    final capturedAtUtc = json['capturedAtUtc'];
    final contentTreeHashSha256 = json['contentTreeHashSha256'];
    final packageSha256 = json['packageSha256'];
    final presentationSha256 = json['presentationSha256'];
    final criteria = json['criteria'];
    final platforms = json['platforms'];
    if (releaseCandidateCommit is! String ||
        capturedAtUtc is! String ||
        contentTreeHashSha256 is! String ||
        packageSha256 is! String ||
        presentationSha256 is! String ||
        criteria is! List ||
        platforms is! List) {
      throw const FormatException(
        'Malformed personalization release receipt.',
      );
    }
    final capturedAt = DateTime.tryParse(capturedAtUtc);
    if (capturedAt == null || !capturedAt.isUtc) {
      throw const FormatException(
        'capturedAtUtc must be a UTC ISO-8601 date.',
      );
    }
    try {
      final receipt = PersonalizationReleaseGateReceipt.validated(
        releaseCandidateCommit: releaseCandidateCommit,
        capturedAtUtc: capturedAt,
        contentTreeHashSha256: contentTreeHashSha256,
        packageSha256: packageSha256,
        presentationSha256: presentationSha256,
        criteria: criteria.map((raw) {
          if (raw is! Map) {
            throw const FormatException(
              'Every personalization criterion must be an object.',
            );
          }
          return PersonalizationReleaseCriterionEvidence.fromJson(
            raw.cast<String, dynamic>(),
          );
        }),
        platforms: platforms.map((raw) {
          if (raw is! Map) {
            throw const FormatException(
              'Every personalization platform must be an object.',
            );
          }
          return PersonalizationPlatformCodecEvidence.fromJson(
            raw.cast<String, dynamic>(),
          );
        }),
      );
      final encodedStatus = json['platformMatrixStatus'];
      final encodedDecision = json['decision'];
      if (encodedStatus != receipt.platformMatrixStatus.name ||
          encodedDecision != (receipt.isGo ? 'GO' : 'NO_GO')) {
        throw const FormatException(
          'Derived personalization release fields do not match the evidence.',
        );
      }
      return receipt;
    } on ArgumentError catch (error) {
      throw FormatException(
        'Invalid personalization release receipt: $error',
      );
    } on StateError catch (error) {
      throw FormatException(
        'Invalid personalization release receipt: $error',
      );
    }
  }

  final String releaseCandidateCommit;
  final DateTime capturedAtUtc;
  final String contentTreeHashSha256;
  final String packageSha256;
  final String presentationSha256;
  final List<PersonalizationReleaseCriterionEvidence> criteria;
  final List<PersonalizationPlatformCodecEvidence> platforms;

  int get schemaVersion => currentSchemaVersion;

  PersonalizationReleaseEvidenceStatus get platformMatrixStatus {
    if (platforms.isEmpty ||
        platforms.any((evidence) => !evidence.hasCompleteEvidence)) {
      return PersonalizationReleaseEvidenceStatus.notEvaluated;
    }
    if (platforms.any((evidence) => !evidence.isSuccessful)) {
      return PersonalizationReleaseEvidenceStatus.failed;
    }
    return PersonalizationReleaseEvidenceStatus.passed;
  }

  bool get isGo =>
      criteria.every(
        (evidence) =>
            evidence.status == PersonalizationReleaseEvidenceStatus.passed,
      ) &&
      platformMatrixStatus == PersonalizationReleaseEvidenceStatus.passed;

  List<String> get blockers {
    final result = <String>[
      for (final evidence in criteria)
        if (evidence.status != PersonalizationReleaseEvidenceStatus.passed)
          '${evidence.criterion.name}: ${evidence.status.name} — '
              '${evidence.summary}',
    ];
    if (platforms.isEmpty) {
      result.add('Platform build and launch evidence is missing.');
    }
    for (final evidence in platforms) {
      final platform = evidence.platform.trim();
      if (evidence.buildExitCode == null) {
        result.add('$platform build evidence is missing.');
      } else if (evidence.buildExitCode != 0) {
        result.add(
          '$platform build exit code ${evidence.buildExitCode}.',
        );
      }
      if (evidence.launchExitCode == null) {
        result.add('$platform launch evidence is missing.');
      } else if (evidence.launchExitCode != 0) {
        result.add(
          '$platform launch exit code ${evidence.launchExitCode}.',
        );
      }
    }
    return List.unmodifiable(result);
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': currentSchemaVersion,
        'releaseCandidateCommit': releaseCandidateCommit,
        'capturedAtUtc': capturedAtUtc.toIso8601String(),
        'contentTreeHashSha256': contentTreeHashSha256,
        'packageSha256': packageSha256,
        'presentationSha256': presentationSha256,
        'criteria': criteria.map((evidence) => evidence.toJson()).toList(),
        'platforms': platforms.map((evidence) => evidence.toJson()).toList(),
        'platformMatrixStatus': platformMatrixStatus.name,
        'decision': isGo ? 'GO' : 'NO_GO',
      };
}

T _enumByName<T extends Enum>(
  Iterable<T> values,
  Object? raw,
  String field,
) {
  if (raw is! String) {
    throw FormatException('$field must be a string.');
  }
  for (final value in values) {
    if (value.name == raw) return value;
  }
  throw FormatException('Unsupported $field: $raw.');
}

void _requireHex(String field, String value, int length) {
  if (!RegExp('^[0-9a-fA-F]{$length}' r'$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      field,
      'must contain exactly $length hexadecimal characters',
    );
  }
}

void _requireText(String field, String value) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, field, 'must not be blank');
  }
}
