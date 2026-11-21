import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

import 'mvp_release_command_matrix.dart';

final class MvpReleaseEvidenceArtifacts {
  const MvpReleaseEvidenceArtifacts({
    required this.receipt,
    required this.json,
    required this.markdown,
  });

  final MvpReleaseEvidenceReceipt receipt;
  final String json;
  final String markdown;
}

final class MvpReleaseEvidenceValidation {
  const MvpReleaseEvidenceValidation(this.issues);

  final List<String> issues;

  bool get isValid => issues.isEmpty;
}

/// Creates and verifies the fail-closed automated receipt used by FG-185.
final class MvpReleaseEvidenceCollector {
  const MvpReleaseEvidenceCollector();

  MvpReleaseEvidenceArtifacts collect({
    required String command,
    required String workingDirectory,
    required String releaseCandidateCommit,
    required DateTime capturedAtUtc,
    required String projectTreeHashSha256,
    required String packageSha256,
    required Iterable<MvpProductCriterionEvidence> productCriteria,
    required Iterable<MvpReleaseCommandResult> commandResults,
  }) {
    final products = productCriteria.toList(growable: false);
    _requireExactlyOnce(
      values: products.map((item) => item.criterion),
      expected: MvpProductCriterion.values,
      label: 'product criterion',
    );
    final results = commandResults.toList(growable: false);
    if (results.isEmpty) {
      throw StateError('Release command results must not be empty.');
    }
    _requireUnique(
      results.map((item) => item.command.id),
      'release command id',
    );
    final sources = <String>[
      ...products.map((item) => item.source),
      ...results.map((item) => item.source),
    ];
    _requireUnique(sources, 'evidence source');

    final technical = <MvpReleaseGateExecutionReceipt>[];
    for (final criterion in MvpReleaseGateCriterion.values) {
      final matching = results
          .where((result) => result.command.criterion == criterion)
          .toList(growable: false);
      if (matching.isEmpty) {
        throw StateError(
          'Missing command evidence for technical criterion ${criterion.name}.',
        );
      }
      final combinedDigest = sha256
          .convert(
            utf8.encode(
              matching
                  .map(
                    (item) =>
                        '${item.command.id}\u0000${item.outputDigestSha256}',
                  )
                  .join('\n'),
            ),
          )
          .toString();
      technical.add(
        MvpReleaseGateExecutionReceipt.validated(
          criterion: criterion,
          summary: matching.every((item) => item.isSuccessful)
              ? '${matching.length} command(s) passed for ${criterion.name}.'
              : 'At least one command failed for ${criterion.name}.',
          source: matching.map((item) => item.source).join(','),
          releaseCandidateCommit: releaseCandidateCommit,
          command:
              matching.map((item) => item.command.displayCommand).join(' && '),
          exitCode: matching
              .map((item) => item.exitCode)
              .firstWhere((exitCode) => exitCode != 0, orElse: () => 0),
          outputDigestSha256: combinedDigest,
        ),
      );
    }
    final exitCode = results
        .map((item) => item.exitCode)
        .firstWhere((code) => code != 0, orElse: () => 0);
    final receipt = MvpReleaseEvidenceReceipt.validated(
      command: command,
      workingDirectory: workingDirectory,
      durationMilliseconds: results.fold(
        0,
        (total, result) => total + result.durationMilliseconds,
      ),
      exitCode: exitCode,
      releaseCandidateCommit: releaseCandidateCommit,
      capturedAtUtc: capturedAtUtc,
      source: 'tool/verify_mvp_release.dart',
      projectTreeHashSha256: projectTreeHashSha256,
      packageSha256: packageSha256,
      sources: sources,
      criteria: products,
      technicalCriteria: technical,
    );
    final json =
        '${const JsonEncoder.withIndent('  ').convert(receipt.toJson())}\n';
    return MvpReleaseEvidenceArtifacts(
      receipt: receipt,
      json: json,
      markdown: _markdown(receipt),
    );
  }

  MvpReleaseEvidenceValidation validate({
    required MvpReleaseEvidenceReceipt receipt,
    required String expectedReleaseCandidateCommit,
    required String expectedProjectTreeHashSha256,
    required String expectedPackageSha256,
    required DateTime nowUtc,
    Duration maxAge = const Duration(hours: 24),
  }) {
    if (!nowUtc.isUtc) {
      throw ArgumentError.value(nowUtc, 'nowUtc', 'must use UTC');
    }
    final issues = <String>[];
    if (receipt.releaseCandidateCommit !=
        expectedReleaseCandidateCommit.toLowerCase()) {
      issues.add('Receipt commit does not match the release candidate commit.');
    }
    if (receipt.projectTreeHashSha256 !=
        expectedProjectTreeHashSha256.toLowerCase()) {
      issues.add('Receipt project tree hash does not match the current tree.');
    }
    if (receipt.packageSha256 != expectedPackageSha256.toLowerCase()) {
      issues.add('Receipt package SHA does not match the release package.');
    }
    final age = nowUtc.difference(receipt.capturedAtUtc);
    if (age > maxAge) {
      issues.add('Receipt is stale (${age.inHours} hours old).');
    } else if (age < const Duration(minutes: -5)) {
      issues.add('Receipt timestamp is in the future.');
    }
    _appendCardinalityIssues(
      issues,
      values: receipt.criteria.map((item) => item.criterion),
      expected: MvpProductCriterion.values,
      label: 'product criterion',
    );
    _appendCardinalityIssues(
      issues,
      values: receipt.technicalCriteria.map((item) => item.criterion),
      expected: MvpReleaseGateCriterion.values,
      label: 'technical criterion',
    );
    for (final criterion in receipt.technicalCriteria) {
      if (criterion.releaseCandidateCommit !=
          expectedReleaseCandidateCommit.toLowerCase()) {
        issues.add(
          'Technical criterion ${criterion.criterion.name} references another commit.',
        );
      }
      if (!criterion.source
          .split(',')
          .every((source) => receipt.sources.contains(source))) {
        issues.add(
          'Technical criterion ${criterion.criterion.name} has an unlinked source.',
        );
      }
    }
    for (final criterion in receipt.criteria) {
      if (!receipt.sources.contains(criterion.source)) {
        issues.add(
          'Product criterion ${criterion.criterion.id} has an unlinked source.',
        );
      }
    }
    if (!receipt.isReleaseSuccessful) {
      issues.add('Receipt contains a failed or incomplete release criterion.');
    }
    return MvpReleaseEvidenceValidation(List.unmodifiable(issues));
  }
}

String _markdown(MvpReleaseEvidenceReceipt receipt) {
  final buffer = StringBuffer()
    ..writeln('# MVP release evidence')
    ..writeln()
    ..writeln('- Candidate: `${receipt.releaseCandidateCommit}`')
    ..writeln('- Captured: `${receipt.capturedAtUtc.toIso8601String()}`')
    ..writeln('- Project tree: `${receipt.projectTreeHashSha256}`')
    ..writeln('- Package: `${receipt.packageSha256 ?? 'missing'}`')
    ..writeln('- Exit code: `${receipt.exitCode}`')
    ..writeln('- Duration: `${receipt.durationMilliseconds} ms`')
    ..writeln()
    ..writeln('## Product criteria')
    ..writeln()
    ..writeln('| Criterion | Status | Source |')
    ..writeln('|---|---|---|');
  for (final item in receipt.criteria) {
    buffer.writeln(
      '| ${item.criterion.id} | ${item.status.name} | ${_cell(item.source)} |',
    );
  }
  buffer
    ..writeln()
    ..writeln('## Technical criteria')
    ..writeln()
    ..writeln('| Criterion | Exit | Source |')
    ..writeln('|---|---:|---|');
  for (final item in receipt.technicalCriteria) {
    buffer.writeln(
      '| ${item.criterion.name} | ${item.exitCode} | ${_cell(item.source)} |',
    );
  }
  return buffer.toString();
}

String _cell(String value) => value.replaceAll('|', r'\|');

void _requireExactlyOnce<T>({
  required Iterable<T> values,
  required Iterable<T> expected,
  required String label,
}) {
  final issues = <String>[];
  _appendCardinalityIssues(
    issues,
    values: values,
    expected: expected,
    label: label,
  );
  if (issues.isNotEmpty) throw StateError(issues.join(' '));
}

void _appendCardinalityIssues<T>(
  List<String> issues, {
  required Iterable<T> values,
  required Iterable<T> expected,
  required String label,
}) {
  final counts = <T, int>{};
  for (final value in values) {
    counts[value] = (counts[value] ?? 0) + 1;
  }
  for (final value in expected) {
    final count = counts[value] ?? 0;
    if (count == 0) {
      issues.add('Missing $label $value.');
    } else if (count > 1) {
      issues.add('Duplicate $label $value.');
    }
  }
}

void _requireUnique(Iterable<String> values, String label) {
  final list = values.toList(growable: false);
  if (list.any((value) => value.trim().isEmpty)) {
    throw StateError('$label must not be blank.');
  }
  if (list.toSet().length != list.length) {
    throw StateError('Duplicate $label.');
  }
}
