import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MvpReleaseGateReport', () {
    test('returns GO only when every required criterion has passed evidence',
        () {
      final report = MvpReleaseGateReport.evaluate(_passedEvidence());

      expect(report.isGo, isTrue);
      expect(report.blockers, isEmpty);
      expect(
        report.evidenceByCriterion.keys,
        containsAll(MvpReleaseGateCriterion.values),
      );
    });

    test('fails closed when a required criterion has no evidence', () {
      final evidence = _passedEvidence()
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
        report.blockers.single.status,
        MvpReleaseGateEvidenceStatus.unverified,
      );
    });

    test('keeps an explicit failed criterion as a release blocker', () {
      final evidence = _passedEvidence()
          .map(
            (item) => item.criterion == MvpReleaseGateCriterion.goldenSlice
                ? const MvpReleaseGateEvidence(
                    criterion: MvpReleaseGateCriterion.goldenSlice,
                    status: MvpReleaseGateEvidenceStatus.failed,
                    summary: 'Le parcours MVP global est incomplet.',
                    source: 'reports/gameplay/fg_185_mvp_release_gate_v0.md',
                  )
                : item,
          )
          .toList(growable: false);

      final report = MvpReleaseGateReport.evaluate(evidence);

      expect(report.isGo, isFalse);
      expect(report.blockers, hasLength(1));
      expect(
        report.blockers.single.status,
        MvpReleaseGateEvidenceStatus.failed,
      );
    });

    test('rejects passed evidence without a usable summary', () {
      final evidence = _passedEvidence()
          .map(
            (item) => item.criterion == MvpReleaseGateCriterion.goldenSlice
                ? const MvpReleaseGateEvidence(
                    criterion: MvpReleaseGateCriterion.goldenSlice,
                    status: MvpReleaseGateEvidenceStatus.passed,
                    summary: '   ',
                    source: 'fresh-evidence',
                  )
                : item,
          )
          .toList(growable: false);

      final report = MvpReleaseGateReport.evaluate(evidence);

      expect(report.isGo, isFalse);
      expect(
        report.evidenceByCriterion[MvpReleaseGateCriterion.goldenSlice]?.status,
        MvpReleaseGateEvidenceStatus.failed,
      );
    });

    test('rejects passed evidence without a usable source', () {
      final evidence = _passedEvidence()
          .map(
            (item) =>
                item.criterion == MvpReleaseGateCriterion.criticalPackageTests
                    ? const MvpReleaseGateEvidence(
                        criterion: MvpReleaseGateCriterion.criticalPackageTests,
                        status: MvpReleaseGateEvidenceStatus.passed,
                        summary: 'Les suites critiques sont vertes.',
                      )
                    : item,
          )
          .toList(growable: false);

      final report = MvpReleaseGateReport.evaluate(evidence);

      expect(report.isGo, isFalse);
      expect(
        report.evidenceByCriterion[MvpReleaseGateCriterion.criticalPackageTests]
            ?.status,
        MvpReleaseGateEvidenceStatus.failed,
      );
    });

    test('rejects contradictory duplicate evidence instead of laundering it',
        () {
      final evidence = <MvpReleaseGateEvidence>[
        ..._passedEvidence(),
        const MvpReleaseGateEvidence(
          criterion: MvpReleaseGateCriterion.goldenSlice,
          status: MvpReleaseGateEvidenceStatus.failed,
          summary: 'Une seconde source contredit le GO.',
        ),
      ];

      final report = MvpReleaseGateReport.evaluate(evidence);

      expect(report.isGo, isFalse);
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
  });
}

List<MvpReleaseGateEvidence> _passedEvidence() => MvpReleaseGateCriterion.values
    .map(
      (criterion) => MvpReleaseGateEvidence(
        criterion: criterion,
        status: MvpReleaseGateEvidenceStatus.passed,
        summary: '${criterion.name} est prouve.',
        source: 'fresh-evidence',
      ),
    )
    .toList(growable: false);
