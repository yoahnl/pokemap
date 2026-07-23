import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MvpProductCriterion', () {
    test('defines the nineteen stable MVP criteria and maps every FG-180 check',
        () {
      expect(MvpProductCriterion.values, hasLength(19));
      expect(
        MvpProductCriterion.values.map((criterion) => criterion.id).toSet(),
        hasLength(19),
      );
      expect(
        MvpProductCriterion.values
            .map((criterion) => criterion.readinessCheck)
            .toSet(),
        ProjectGameplayReadinessCheck.values.toSet(),
      );
      expect(MvpProductCriterion.mvp01NewGame.id, 'MVP-01');
      expect(MvpProductCriterion.mvp19StoryEnd.id, 'MVP-19');
    });

    test('aggregates explicit product evidence with project evidence', () {
      final report = ProjectGameplayReadinessReport.evaluateProductCriteria(
        productEvidence: _passedProductEvidence(),
        projectEvidence: _passedProjectEvidence(),
      );

      expect(report.isPlayable, isTrue);
      expect(report.infos, hasLength(11));
      expect(
        report.diagnostics
            .singleWhere(
              (diagnostic) =>
                  diagnostic.check ==
                  ProjectGameplayReadinessCheck.battleBridgeCoverage,
            )
            .summary,
        contains('MVP-08'),
      );
    });

    test('missing or duplicate product evidence fails closed', () {
      final missing = ProjectGameplayReadinessReport.evaluateProductCriteria(
        productEvidence: _passedProductEvidence().where(
          (evidence) =>
              evidence.criterion != MvpProductCriterion.mvp15FieldAbility,
        ),
        projectEvidence: _passedProjectEvidence(),
      );
      final duplicate = ProjectGameplayReadinessReport.evaluateProductCriteria(
        productEvidence: <MvpProductCriterionEvidence>[
          ..._passedProductEvidence(),
          const MvpProductCriterionEvidence(
            criterion: MvpProductCriterion.mvp16Shop,
            status: MvpProductCriterionStatus.passed,
            summary: 'Duplicate shop claim.',
            source: 'duplicate',
          ),
        ],
        projectEvidence: _passedProjectEvidence(),
      );

      expect(missing.isPlayable, isFalse);
      expect(missing.errors.single.summary, contains('MVP-15'));
      expect(duplicate.isPlayable, isFalse);
      expect(duplicate.errors.single.summary, contains('dupliquée'));
    });

    test('failed project or journey evidence cannot become passed', () {
      final product = _passedProductEvidence()
          .map(
            (evidence) =>
                evidence.criterion == MvpProductCriterion.mvp18SaveLoad
                    ? const MvpProductCriterionEvidence(
                        criterion: MvpProductCriterion.mvp18SaveLoad,
                        status: MvpProductCriterionStatus.failed,
                        summary: 'Reload failed.',
                        source: 'journey',
                      )
                    : evidence,
          )
          .toList(growable: false);
      final report = ProjectGameplayReadinessReport.evaluateProductCriteria(
        productEvidence: product,
        projectEvidence: _passedProjectEvidence(),
      );

      expect(report.isPlayable, isFalse);
      expect(
        report.errors.map((diagnostic) => diagnostic.check),
        contains(ProjectGameplayReadinessCheck.startState),
      );
    });
  });
}

List<MvpProductCriterionEvidence> _passedProductEvidence() =>
    MvpProductCriterion.values
        .map(
          (criterion) => MvpProductCriterionEvidence(
            criterion: criterion,
            status: MvpProductCriterionStatus.passed,
            summary: '${criterion.id} passed.',
            source: 'journey:${criterion.id}',
          ),
        )
        .toList(growable: false);

List<ProjectGameplayReadinessEvidence> _passedProjectEvidence() =>
    ProjectGameplayReadinessCheck.values
        .map(
          (check) => ProjectGameplayReadinessEvidence(
            check: check,
            status: ProjectGameplayReadinessEvidenceStatus.passed,
            summary: '${check.name} exists in the project.',
            source: 'project.json',
          ),
        )
        .toList(growable: false);
