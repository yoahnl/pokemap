enum HumanWalkthroughIssueSeverity { p0, p1, p2, p3 }

final class HumanWalkthroughCheckpoint {
  const HumanWalkthroughCheckpoint({
    required this.id,
    required this.passed,
    required this.evidence,
  });

  factory HumanWalkthroughCheckpoint.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final passed = json['passed'];
    final evidence = json['evidence'];
    if (id is! String || passed is! bool || evidence is! String) {
      throw const FormatException('Malformed walkthrough checkpoint.');
    }
    return HumanWalkthroughCheckpoint(
      id: id,
      passed: passed,
      evidence: evidence,
    );
  }

  final String id;
  final bool passed;
  final String evidence;

  Map<String, Object?> toJson() => {
        'id': id,
        'passed': passed,
        'evidence': evidence,
      };
}

final class HumanWalkthroughIssue {
  const HumanWalkthroughIssue({
    required this.severity,
    required this.summary,
  });

  factory HumanWalkthroughIssue.fromJson(Map<String, dynamic> json) {
    final rawSeverity = json['severity'];
    final summary = json['summary'];
    if (rawSeverity is! String || summary is! String) {
      throw const FormatException('Malformed walkthrough issue.');
    }
    final severity = HumanWalkthroughIssueSeverity.values
        .where((candidate) => candidate.name == rawSeverity)
        .firstOrNull;
    if (severity == null) {
      throw FormatException('Unknown walkthrough issue severity: $rawSeverity');
    }
    return HumanWalkthroughIssue(severity: severity, summary: summary);
  }

  final HumanWalkthroughIssueSeverity severity;
  final String summary;

  Map<String, Object?> toJson() => {
        'severity': severity.name,
        'summary': summary,
      };
}

final class HumanWalkthroughReceipt {
  const HumanWalkthroughReceipt._({
    required this.releaseCandidateCommit,
    required this.capturedAtUtc,
    required this.projectTreeHashSha256,
    required this.packageSha256,
    required this.tester,
    required this.platform,
    required this.checkpoints,
    required this.issues,
  });

  static const currentSchemaVersion = 1;

  factory HumanWalkthroughReceipt.validated({
    required String releaseCandidateCommit,
    required DateTime capturedAtUtc,
    required String projectTreeHashSha256,
    required String packageSha256,
    required String tester,
    required String platform,
    required Iterable<HumanWalkthroughCheckpoint> checkpoints,
    required Iterable<HumanWalkthroughIssue> issues,
  }) {
    _requireHex('releaseCandidateCommit', releaseCandidateCommit, 40);
    _requireHex('projectTreeHashSha256', projectTreeHashSha256, 64);
    _requireHex('packageSha256', packageSha256, 64);
    _requireText('tester', tester);
    _requireText('platform', platform);
    if (!capturedAtUtc.isUtc) {
      throw ArgumentError.value(
        capturedAtUtc,
        'capturedAtUtc',
        'must use UTC',
      );
    }
    final checkpointList = checkpoints.toList(growable: false);
    final issueList = issues.toList(growable: false);
    for (final checkpoint in checkpointList) {
      _requireText('checkpoint.id', checkpoint.id);
      _requireText('checkpoint.evidence', checkpoint.evidence);
    }
    for (final issue in issueList) {
      _requireText('issue.summary', issue.summary);
    }
    return HumanWalkthroughReceipt._(
      releaseCandidateCommit: releaseCandidateCommit.toLowerCase(),
      capturedAtUtc: capturedAtUtc,
      projectTreeHashSha256: projectTreeHashSha256.toLowerCase(),
      packageSha256: packageSha256.toLowerCase(),
      tester: tester.trim(),
      platform: platform.trim(),
      checkpoints: List.unmodifiable(checkpointList),
      issues: List.unmodifiable(issueList),
    );
  }

  factory HumanWalkthroughReceipt.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != currentSchemaVersion) {
      throw FormatException(
        'Unsupported walkthrough receipt schema: ${json['schemaVersion']}',
      );
    }
    final commit = json['releaseCandidateCommit'];
    final capturedAt = json['capturedAtUtc'];
    final treeHash = json['projectTreeHashSha256'];
    final packageSha = json['packageSha256'];
    final tester = json['tester'];
    final platform = json['platform'];
    final checkpoints = json['checkpoints'];
    final issues = json['issues'];
    if (commit is! String ||
        capturedAt is! String ||
        treeHash is! String ||
        packageSha is! String ||
        tester is! String ||
        platform is! String ||
        checkpoints is! List ||
        issues is! List) {
      throw const FormatException('Malformed human walkthrough receipt.');
    }
    final date = DateTime.tryParse(capturedAt);
    if (date == null || !date.isUtc) {
      throw const FormatException('capturedAtUtc must be a UTC ISO-8601 date.');
    }
    try {
      return HumanWalkthroughReceipt.validated(
        releaseCandidateCommit: commit,
        capturedAtUtc: date,
        projectTreeHashSha256: treeHash,
        packageSha256: packageSha,
        tester: tester,
        platform: platform,
        checkpoints: checkpoints.map((raw) {
          if (raw is! Map) {
            throw const FormatException(
              'Every walkthrough checkpoint must be an object.',
            );
          }
          return HumanWalkthroughCheckpoint.fromJson(
            raw.cast<String, dynamic>(),
          );
        }),
        issues: issues.map((raw) {
          if (raw is! Map) {
            throw const FormatException(
              'Every walkthrough issue must be an object.',
            );
          }
          return HumanWalkthroughIssue.fromJson(raw.cast<String, dynamic>());
        }),
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid human walkthrough receipt: $error');
    }
  }

  final String releaseCandidateCommit;
  final DateTime capturedAtUtc;
  final String projectTreeHashSha256;
  final String packageSha256;
  final String tester;
  final String platform;
  final List<HumanWalkthroughCheckpoint> checkpoints;
  final List<HumanWalkthroughIssue> issues;

  int get schemaVersion => currentSchemaVersion;

  Map<String, Object?> toJson() => {
        'schemaVersion': currentSchemaVersion,
        'releaseCandidateCommit': releaseCandidateCommit,
        'capturedAtUtc': capturedAtUtc.toIso8601String(),
        'projectTreeHashSha256': projectTreeHashSha256,
        'packageSha256': packageSha256,
        'tester': tester,
        'platform': platform,
        'checkpoints':
            checkpoints.map((checkpoint) => checkpoint.toJson()).toList(),
        'issues': issues.map((issue) => issue.toJson()).toList(),
      };
}

final class HumanWalkthroughReceiptValidation {
  const HumanWalkthroughReceiptValidation(this.issues);

  final List<String> issues;

  bool get isValid => issues.isEmpty;
}

final class HumanWalkthroughReceiptValidator {
  const HumanWalkthroughReceiptValidator();

  HumanWalkthroughReceiptValidation validate({
    required HumanWalkthroughReceipt receipt,
    required String expectedReleaseCandidateCommit,
    required String expectedProjectTreeHashSha256,
    required String expectedPackageSha256,
    required Iterable<String> requiredCheckpointIds,
    required DateTime nowUtc,
    Duration maxAge = const Duration(hours: 24),
  }) {
    if (!nowUtc.isUtc) {
      throw ArgumentError.value(nowUtc, 'nowUtc', 'must use UTC');
    }
    final validationIssues = <String>[];
    if (receipt.releaseCandidateCommit !=
        expectedReleaseCandidateCommit.toLowerCase()) {
      validationIssues.add(
        'Walkthrough commit does not match the release candidate.',
      );
    }
    if (receipt.projectTreeHashSha256 !=
        expectedProjectTreeHashSha256.toLowerCase()) {
      validationIssues.add(
        'Walkthrough project tree hash does not match the current tree.',
      );
    }
    if (receipt.packageSha256 != expectedPackageSha256.toLowerCase()) {
      validationIssues.add(
        'Walkthrough package SHA does not match the release package.',
      );
    }
    final age = nowUtc.difference(receipt.capturedAtUtc);
    if (age > maxAge) {
      validationIssues.add('Walkthrough receipt is stale.');
    } else if (age < const Duration(minutes: -5)) {
      validationIssues.add('Walkthrough receipt timestamp is in the future.');
    }
    final checkpointCounts = <String, int>{};
    for (final checkpoint in receipt.checkpoints) {
      checkpointCounts[checkpoint.id] =
          (checkpointCounts[checkpoint.id] ?? 0) + 1;
      if (!checkpoint.passed) {
        validationIssues.add('Checkpoint ${checkpoint.id} failed.');
      }
    }
    for (final id in requiredCheckpointIds) {
      final count = checkpointCounts[id] ?? 0;
      if (count == 0) {
        validationIssues.add('Missing walkthrough checkpoint $id.');
      } else if (count > 1) {
        validationIssues.add('Duplicate walkthrough checkpoint $id.');
      }
    }
    if (receipt.issues.any(
      (issue) =>
          issue.severity == HumanWalkthroughIssueSeverity.p0 ||
          issue.severity == HumanWalkthroughIssueSeverity.p1,
    )) {
      validationIssues.add(
        'Walkthrough contains unresolved P0/P1 release issues.',
      );
    }
    return HumanWalkthroughReceiptValidation(
      List.unmodifiable(validationIssues),
    );
  }
}

void _requireText(String fieldName, String value) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be blank');
  }
}

void _requireHex(String fieldName, String value, int length) {
  if (!RegExp('^[0-9a-fA-F]{$length}\$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      fieldName,
      'must contain exactly $length hexadecimal characters',
    );
  }
}
