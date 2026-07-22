import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MvpReleaseGateExecutionReceipt', () {
    test('validates structured execution metadata', () {
      final receipt = _receipt(MvpReleaseGateCriterion.goldenSlice);

      expect(receipt.criterion, MvpReleaseGateCriterion.goldenSlice);
      expect(receipt.releaseCandidateCommit, _releaseCandidateCommit);
      expect(receipt.command, 'dart test test/golden_slice_test.dart');
      expect(receipt.exitCode, 0);
      expect(receipt.outputDigestSha256, _outputDigestSha256);
    });

    test('rejects invalid structured execution metadata', () {
      expect(
        () => _receipt(MvpReleaseGateCriterion.goldenSlice, summary: '   '),
        throwsArgumentError,
      );
      expect(
        () => _receipt(MvpReleaseGateCriterion.goldenSlice, source: ''),
        throwsArgumentError,
      );
      expect(
        () => _receipt(
          MvpReleaseGateCriterion.goldenSlice,
          releaseCandidateCommit: 'abc123',
        ),
        throwsArgumentError,
      );
      expect(
        () => _receipt(
          MvpReleaseGateCriterion.goldenSlice,
          releaseCandidateCommit: '${_releaseCandidateCommit}0',
        ),
        throwsArgumentError,
      );
      expect(
        () => _receipt(
          MvpReleaseGateCriterion.goldenSlice,
          releaseCandidateCommit: '$_releaseCandidateCommit\n',
        ),
        throwsArgumentError,
      );
      expect(
        () => _receipt(MvpReleaseGateCriterion.goldenSlice, command: ' '),
        throwsArgumentError,
      );
      expect(
        () => _receipt(
          MvpReleaseGateCriterion.goldenSlice,
          outputDigestSha256: 'not-a-sha256',
        ),
        throwsArgumentError,
      );
      expect(
        () => _receipt(
          MvpReleaseGateCriterion.goldenSlice,
          outputDigestSha256: '${_outputDigestSha256}0',
        ),
        throwsArgumentError,
      );
    });
  });

  group('MvpReleaseGateReport', () {
    test('never returns GO from five merely declared passed entries', () {
      final report = MvpReleaseGateReport.evaluate(_declaredPassedEvidence());

      expect(report.isGo, isFalse);
      expect(report.blockers, hasLength(MvpReleaseGateCriterion.values.length));
      expect(
        report.blockers,
        everyElement(
          isA<MvpReleaseGateEvidence>().having(
            (item) => item.evidenceKind,
            'evidenceKind',
            MvpReleaseGateEvidenceKind.declaredEvidence,
          ),
        ),
      );
    });

    test('returns GO only from five validated successful receipts', () {
      final report = MvpReleaseGateReport.evaluate(_executedEvidence());

      expect(report.isGo, isTrue);
      expect(report.blockers, isEmpty);
      expect(
        report.evidenceByCriterion.keys,
        containsAll(MvpReleaseGateCriterion.values),
      );
      expect(
        report.evidenceByCriterion.values,
        everyElement(
          isA<MvpReleaseGateEvidence>()
              .having(
                (item) => item.evidenceKind,
                'evidenceKind',
                MvpReleaseGateEvidenceKind.executedEvidence,
              )
              .having(
                (item) => item.status,
                'status',
                MvpReleaseGateEvidenceStatus.passed,
              )
              .having(
                (item) => item.executionReceipt,
                'executionReceipt',
                isNotNull,
              ),
        ),
      );
    });

    test('derives a failed execution status from a nonzero exit code', () {
      final evidence = _executedEvidence().map(
        (item) => item.criterion == MvpReleaseGateCriterion.goldenSlice
            ? _executed(
                MvpReleaseGateCriterion.goldenSlice,
                exitCode: 1,
              )
            : item,
      );

      final report = MvpReleaseGateReport.evaluate(evidence);

      expect(report.isGo, isFalse);
      expect(report.blockers, hasLength(1));
      expect(
        report.blockers.single.status,
        MvpReleaseGateEvidenceStatus.failed,
      );
      expect(report.blockers.single.executionReceipt?.exitCode, 1);
    });

    test('fails closed with a generated blocker for missing evidence', () {
      final evidence = _executedEvidence()
          .where(
            (item) =>
                item.criterion !=
                MvpReleaseGateCriterion.projectGameplayReadiness,
          )
          .toList(growable: false);

      final report = MvpReleaseGateReport.evaluate(evidence);

      expect(report.isGo, isFalse);
      expect(report.blockers, hasLength(1));
      expect(
        report.blockers.single.criterion,
        MvpReleaseGateCriterion.projectGameplayReadiness,
      );
      expect(
        report.blockers.single.evidenceKind,
        MvpReleaseGateEvidenceKind.gateGeneratedBlocker,
      );
      expect(
        report.blockers.single.status,
        MvpReleaseGateEvidenceStatus.unverified,
      );
    });

    test('rejects passed declarations without a usable summary', () {
      final evidence = _declaredPassedEvidence().map(
        (item) => item.criterion == MvpReleaseGateCriterion.goldenSlice
            ? const MvpReleaseGateEvidence.declared(
                criterion: MvpReleaseGateCriterion.goldenSlice,
                status: MvpReleaseGateEvidenceStatus.passed,
                summary: '   ',
                source: 'historical-report',
              )
            : item,
      );

      final report = MvpReleaseGateReport.evaluate(evidence);

      expect(report.isGo, isFalse);
      expect(
        report.evidenceByCriterion[MvpReleaseGateCriterion.goldenSlice]?.status,
        MvpReleaseGateEvidenceStatus.failed,
      );
    });

    test('rejects passed declarations without a usable source', () {
      final evidence = _declaredPassedEvidence().map(
        (item) => item.criterion == MvpReleaseGateCriterion.criticalPackageTests
            ? const MvpReleaseGateEvidence.declared(
                criterion: MvpReleaseGateCriterion.criticalPackageTests,
                status: MvpReleaseGateEvidenceStatus.passed,
                summary: 'Les suites critiques sont historiquement vertes.',
              )
            : item,
      );

      final report = MvpReleaseGateReport.evaluate(evidence);

      expect(report.isGo, isFalse);
      expect(
        report.evidenceByCriterion[MvpReleaseGateCriterion.criticalPackageTests]
            ?.status,
        MvpReleaseGateEvidenceStatus.failed,
      );
    });

    test('uses a generated blocker for contradictory duplicate evidence', () {
      final evidence = <MvpReleaseGateEvidence>[
        ..._executedEvidence(),
        _executed(MvpReleaseGateCriterion.goldenSlice, exitCode: 1),
      ];

      final report = MvpReleaseGateReport.evaluate(evidence);

      expect(report.isGo, isFalse);
      expect(
        report.evidenceByCriterion[MvpReleaseGateCriterion.goldenSlice]
            ?.evidenceKind,
        MvpReleaseGateEvidenceKind.gateGeneratedBlocker,
      );
      expect(
        report.evidenceByCriterion[MvpReleaseGateCriterion.goldenSlice]?.status,
        MvpReleaseGateEvidenceStatus.failed,
      );
      expect(
        report
            .evidenceByCriterion[MvpReleaseGateCriterion.goldenSlice]?.summary,
        contains('contradictoires'),
      );
    });

    test('keeps documentary Phase 10 approval at NO-GO without receipts', () {
      final report = MvpReleaseGateReport.evaluate(
        _declaredPassedEvidence(),
      );

      expect(report.isGo, isFalse);
      expect(report.blockers, hasLength(MvpReleaseGateCriterion.values.length));
    });
  });
}

const _releaseCandidateCommit = '0123456789abcdef0123456789abcdef01234567';
const _outputDigestSha256 =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

List<MvpReleaseGateEvidence> _declaredPassedEvidence() =>
    MvpReleaseGateCriterion.values
        .map(
          (criterion) => MvpReleaseGateEvidence.declared(
            criterion: criterion,
            status: MvpReleaseGateEvidenceStatus.passed,
            summary: '${criterion.name} est déclaré comme prouvé.',
            source: 'reports/gameplay/historical-evidence.md',
          ),
        )
        .toList(growable: false);

List<MvpReleaseGateEvidence> _executedEvidence() =>
    MvpReleaseGateCriterion.values.map(_executed).toList(growable: false);

MvpReleaseGateEvidence _executed(
  MvpReleaseGateCriterion criterion, {
  int exitCode = 0,
}) =>
    MvpReleaseGateEvidence.fromExecutionReceipt(
      _receipt(criterion, exitCode: exitCode),
    );

MvpReleaseGateExecutionReceipt _receipt(
  MvpReleaseGateCriterion criterion, {
  String? summary,
  String? source,
  String? releaseCandidateCommit,
  String? command,
  int exitCode = 0,
  String? outputDigestSha256,
}) =>
    MvpReleaseGateExecutionReceipt.validated(
      criterion: criterion,
      summary: summary ?? '${criterion.name} a été exécuté.',
      source: source ?? 'ci://release-gate/${criterion.name}',
      releaseCandidateCommit: releaseCandidateCommit ?? _releaseCandidateCommit,
      command: command ?? 'dart test test/golden_slice_test.dart',
      exitCode: exitCode,
      outputDigestSha256: outputDigestSha256 ?? _outputDigestSha256,
    );
