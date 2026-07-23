import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_loader/src/mvp_release_command_matrix.dart';
import 'package:pokemap_loader/src/mvp_release_evidence_collector.dart';

void main() {
  test('produces deterministic JSON and Markdown linked to every criterion',
      () {
    const collector = MvpReleaseEvidenceCollector();
    final first = collector.collect(
      command: 'dart run tool/verify_mvp_release.dart --full',
      workingDirectory: '/workspace',
      releaseCandidateCommit: 'a' * 40,
      capturedAtUtc: DateTime.utc(2026, 7, 23, 12),
      projectTreeHashSha256: 'b' * 64,
      packageSha256: 'c' * 64,
      productCriteria: _productCriteria(),
      commandResults: _commandResults(),
    );
    final second = collector.collect(
      command: 'dart run tool/verify_mvp_release.dart --full',
      workingDirectory: '/workspace',
      releaseCandidateCommit: 'a' * 40,
      capturedAtUtc: DateTime.utc(2026, 7, 23, 12),
      projectTreeHashSha256: 'b' * 64,
      packageSha256: 'c' * 64,
      productCriteria: _productCriteria(),
      commandResults: _commandResults(),
    );

    expect(first.json, second.json);
    expect(first.markdown, second.markdown);
    expect(first.receipt.isReleaseSuccessful, isTrue);
    expect(first.receipt.criteria, hasLength(19));
    expect(
      first.receipt.technicalCriteria,
      hasLength(MvpReleaseGateCriterion.values.length),
    );
    expect(
      jsonDecode(first.json),
      first.receipt.toJson(),
    );
  });

  test('fails closed on failed, stale, altered or duplicate evidence', () {
    const collector = MvpReleaseEvidenceCollector();
    final good = _receipt(collector);

    expect(
      collector
          .validate(
            receipt: good,
            expectedReleaseCandidateCommit: 'a' * 40,
            expectedProjectTreeHashSha256: 'b' * 64,
            expectedPackageSha256: 'c' * 64,
            nowUtc: DateTime.utc(2026, 7, 23, 13),
          )
          .isValid,
      isTrue,
    );

    final stale = collector.validate(
      receipt: good,
      expectedReleaseCandidateCommit: 'd' * 40,
      expectedProjectTreeHashSha256: 'e' * 64,
      expectedPackageSha256: 'f' * 64,
      nowUtc: DateTime.utc(2026, 7, 26),
    );
    expect(stale.isValid, isFalse);
    expect(stale.issues.join(' '), contains('commit'));
    expect(stale.issues.join(' '), contains('tree'));
    expect(stale.issues.join(' '), contains('package'));
    expect(stale.issues.join(' '), contains('stale'));

    expect(
      () => collector.collect(
        command: 'verify',
        workingDirectory: '/workspace',
        releaseCandidateCommit: 'a' * 40,
        capturedAtUtc: DateTime.utc(2026, 7, 23, 12),
        projectTreeHashSha256: 'b' * 64,
        packageSha256: 'c' * 64,
        productCriteria: [
          ..._productCriteria(),
          _productCriteria().first,
        ],
        commandResults: _commandResults(),
      ),
      throwsA(isA<StateError>()),
    );

    final failed = collector.collect(
      command: 'verify',
      workingDirectory: '/workspace',
      releaseCandidateCommit: 'a' * 40,
      capturedAtUtc: DateTime.utc(2026, 7, 23, 12),
      projectTreeHashSha256: 'b' * 64,
      packageSha256: 'c' * 64,
      productCriteria: _productCriteria(),
      commandResults: [
        ..._commandResults().take(4),
        MvpReleaseCommandResult.validated(
          command: _spec(
            MvpReleaseGateCriterion.userScopeApproved,
            4,
          ),
          exitCode: 1,
          durationMilliseconds: 10,
          outputDigestSha256: 'f' * 64,
          source: 'test://failed',
        ),
      ],
    );
    expect(failed.receipt.isReleaseSuccessful, isFalse);
  });
}

MvpReleaseEvidenceReceipt _receipt(MvpReleaseEvidenceCollector collector) =>
    collector
        .collect(
          command: 'verify',
          workingDirectory: '/workspace',
          releaseCandidateCommit: 'a' * 40,
          capturedAtUtc: DateTime.utc(2026, 7, 23, 12),
          projectTreeHashSha256: 'b' * 64,
          packageSha256: 'c' * 64,
          productCriteria: _productCriteria(),
          commandResults: _commandResults(),
        )
        .receipt;

List<MvpProductCriterionEvidence> _productCriteria() =>
    MvpProductCriterion.values
        .map(
          (criterion) => MvpProductCriterionEvidence(
            criterion: criterion,
            status: MvpProductCriterionStatus.passed,
            summary: '${criterion.id} executed.',
            source: 'journey:${criterion.id}',
          ),
        )
        .toList(growable: false);

List<MvpReleaseCommandResult> _commandResults() =>
    MvpReleaseGateCriterion.values.indexed
        .map(
          (entry) => MvpReleaseCommandResult.validated(
            command: _spec(entry.$2, entry.$1),
            exitCode: 0,
            durationMilliseconds: 10 + entry.$1,
            outputDigestSha256: '${entry.$1}' * 64,
            source: 'test://command-${entry.$1}',
          ),
        )
        .toList(growable: false);

MvpReleaseCommandSpec _spec(MvpReleaseGateCriterion criterion, int index) =>
    MvpReleaseCommandSpec(
      id: 'command-$index',
      criterion: criterion,
      executable: 'flutter',
      arguments: ['test', 'test/$index.dart'],
      workingDirectory: '/workspace',
    );
