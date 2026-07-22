import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MvpReleaseGateReport', () {
    test('never returns GO from five merely declared passed entries', () {
      final report = MvpReleaseGateReport.evaluate(
        _passedEvidence(
          evidenceKind: MvpReleaseGateEvidenceKind.declaredEvidence,
        ),
      );

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

    test('returns GO only when every criterion has executed passed evidence',
        () {
      final report = MvpReleaseGateReport.evaluate(
        _passedEvidence(
          evidenceKind: MvpReleaseGateEvidenceKind.executedEvidence,
        ),
      );

      expect(report.isGo, isTrue);
      expect(report.blockers, isEmpty);
      expect(
        report.evidenceByCriterion.keys,
        containsAll(MvpReleaseGateCriterion.values),
      );
    });

    test('fails closed when a required criterion has no evidence', () {
      final evidence = _passedEvidence(
        evidenceKind: MvpReleaseGateEvidenceKind.executedEvidence,
      )
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
      final evidence = _passedEvidence(
        evidenceKind: MvpReleaseGateEvidenceKind.executedEvidence,
      )
          .map(
            (item) => item.criterion == MvpReleaseGateCriterion.goldenSlice
                ? const MvpReleaseGateEvidence(
                    criterion: MvpReleaseGateCriterion.goldenSlice,
                    evidenceKind: MvpReleaseGateEvidenceKind.executedEvidence,
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
      final evidence = _passedEvidence(
        evidenceKind: MvpReleaseGateEvidenceKind.executedEvidence,
      )
          .map(
            (item) => item.criterion == MvpReleaseGateCriterion.goldenSlice
                ? const MvpReleaseGateEvidence(
                    criterion: MvpReleaseGateCriterion.goldenSlice,
                    evidenceKind: MvpReleaseGateEvidenceKind.executedEvidence,
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
      final evidence = _passedEvidence(
        evidenceKind: MvpReleaseGateEvidenceKind.executedEvidence,
      )
          .map(
            (item) => item.criterion ==
                    MvpReleaseGateCriterion.criticalPackageTests
                ? const MvpReleaseGateEvidence(
                    criterion: MvpReleaseGateCriterion.criticalPackageTests,
                    evidenceKind: MvpReleaseGateEvidenceKind.executedEvidence,
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
        ..._passedEvidence(
          evidenceKind: MvpReleaseGateEvidenceKind.executedEvidence,
        ),
        const MvpReleaseGateEvidence(
          criterion: MvpReleaseGateCriterion.goldenSlice,
          evidenceKind: MvpReleaseGateEvidenceKind.executedEvidence,
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

    test('keeps documentary Phase 10 approval at NO-GO without a receipt', () {
      final report = MvpReleaseGateReport.evaluate(
        <MvpReleaseGateEvidence>[
          const MvpReleaseGateEvidence(
            criterion: MvpReleaseGateCriterion.goldenSlice,
            evidenceKind: MvpReleaseGateEvidenceKind.declaredEvidence,
            status: MvpReleaseGateEvidenceStatus.passed,
            summary: 'Le parcours Golden Slice FG-182 passe de bout en bout.',
            source:
                'reports/gameplay/fg_182_golden_slice_end_to_end_smoke_v0.md',
          ),
          const MvpReleaseGateEvidence(
            criterion: MvpReleaseGateCriterion.projectGameplayReadiness,
            evidenceKind: MvpReleaseGateEvidenceKind.declaredEvidence,
            status: MvpReleaseGateEvidenceStatus.passed,
            summary: 'Les onze checks FG-180 disposent de preuves valides.',
            source:
                'reports/gameplay/fg_180_project_gameplay_readiness_report_v0.md',
          ),
          const MvpReleaseGateEvidence(
            criterion: MvpReleaseGateCriterion.criticalPackageTests,
            evidenceKind: MvpReleaseGateEvidenceKind.declaredEvidence,
            status: MvpReleaseGateEvidenceStatus.passed,
            summary: 'Les suites critiques sont vertes.',
            source: 'reports/gameplay/fg_183_regression_matrix_v0.md',
          ),
          const MvpReleaseGateEvidence(
            criterion: MvpReleaseGateCriterion.postMvpLimitationsDocumented,
            evidenceKind: MvpReleaseGateEvidenceKind.declaredEvidence,
            status: MvpReleaseGateEvidenceStatus.passed,
            summary: 'La Phase 11 documente les capacités différées.',
            source: 'pokemap_roadmap_mecaniques_fangame.md#phase-11',
          ),
          const MvpReleaseGateEvidence(
            criterion: MvpReleaseGateCriterion.userScopeApproved,
            evidenceKind: MvpReleaseGateEvidenceKind.declaredEvidence,
            status: MvpReleaseGateEvidenceStatus.passed,
            summary: 'Le périmètre MVP et ses exclusions sont approuvés.',
            source:
                'reports/gameplay/fg_185_mvp_release_gate_v0.md#approval-record',
          ),
        ],
      );

      expect(report.isGo, isFalse);
      expect(report.blockers, hasLength(MvpReleaseGateCriterion.values.length));
    });
  });
}

List<MvpReleaseGateEvidence> _passedEvidence({
  required MvpReleaseGateEvidenceKind evidenceKind,
}) =>
    MvpReleaseGateCriterion.values
        .map(
          (criterion) => MvpReleaseGateEvidence(
            criterion: criterion,
            evidenceKind: evidenceKind,
            status: MvpReleaseGateEvidenceStatus.passed,
            summary: '${criterion.name} est prouve.',
            source: 'fresh-evidence',
          ),
        )
        .toList(growable: false);
