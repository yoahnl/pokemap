import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectGameplayReadinessReport', () {
    test('healthy fixture is playable and renders creator and agent reports',
        () {
      final report = ProjectGameplayReadinessReport.evaluate(
        _passedEvidence(),
      );

      expect(report.isPlayable, isTrue);
      expect(report.errors, isEmpty);
      expect(report.warnings, isEmpty);
      expect(
          report.infos, hasLength(ProjectGameplayReadinessCheck.values.length));
      expect(report.creatorMarkdown, contains('Projet jouable'));
      expect(report.creatorMarkdown, contains('11/11 vérifications réussies'));
      expect(report.agentMarkdown, contains('`battleBridgeCoverage`'));
      expect(report.agentMarkdown, contains('reports/gameplay/proof.md'));
    });

    test('broken fixture exposes errors and unverified checks as warnings', () {
      final evidence = <ProjectGameplayReadinessEvidence>[
        ..._passedEvidence().where(
          (item) =>
              item.check != ProjectGameplayReadinessCheck.startState &&
              item.check !=
                  ProjectGameplayReadinessCheck.starterConfiguration &&
              item.check != ProjectGameplayReadinessCheck.storyEndReachable,
        ),
        const ProjectGameplayReadinessEvidence(
          check: ProjectGameplayReadinessCheck.startState,
          status: ProjectGameplayReadinessEvidenceStatus.failed,
          summary: 'Aucune map de départ utilisable.',
          source: 'fixture:broken',
        ),
        const ProjectGameplayReadinessEvidence(
          check: ProjectGameplayReadinessCheck.starterConfiguration,
          status: ProjectGameplayReadinessEvidenceStatus.failed,
          summary: 'La configuration starter est absente.',
          source: 'fixture:broken',
        ),
      ];

      final report = ProjectGameplayReadinessReport.evaluate(evidence);

      expect(report.isPlayable, isFalse);
      expect(report.errors, hasLength(2));
      expect(report.warnings, hasLength(1));
      expect(
        report.warnings.single.check,
        ProjectGameplayReadinessCheck.storyEndReachable,
      );
      expect(report.creatorMarkdown, contains('Projet incomplet'));
      expect(report.creatorMarkdown, contains('2 erreur(s)'));
      expect(report.creatorMarkdown, contains('1 vérification(s) à confirmer'));
    });

    test('missing evidence fails closed as an unverified warning', () {
      final report = ProjectGameplayReadinessReport.evaluate(
        _passedEvidence().where(
          (item) =>
              item.check !=
              ProjectGameplayReadinessCheck.fieldAbilityUnlockReachable,
        ),
      );

      expect(report.isPlayable, isFalse);
      expect(report.warnings, hasLength(1));
      expect(
        report.warnings.single.check,
        ProjectGameplayReadinessCheck.fieldAbilityUnlockReachable,
      );
      expect(report.warnings.single.summary, contains('Aucune preuve'));
    });

    test('passed evidence without usable metadata becomes an error', () {
      final evidence = _passedEvidence()
          .map(
            (item) => item.check == ProjectGameplayReadinessCheck.shopItems
                ? const ProjectGameplayReadinessEvidence(
                    check: ProjectGameplayReadinessCheck.shopItems,
                    status: ProjectGameplayReadinessEvidenceStatus.passed,
                    summary: ' ',
                    source: '',
                  )
                : item,
          )
          .toList(growable: false);

      final report = ProjectGameplayReadinessReport.evaluate(evidence);

      expect(report.isPlayable, isFalse);
      expect(report.errors, hasLength(1));
      expect(
          report.errors.single.check, ProjectGameplayReadinessCheck.shopItems);
      expect(report.errors.single.summary, contains('inexploitable'));
    });

    test('duplicate evidence is rejected instead of laundering readiness', () {
      final report = ProjectGameplayReadinessReport.evaluate(
        <ProjectGameplayReadinessEvidence>[
          ..._passedEvidence(),
          const ProjectGameplayReadinessEvidence(
            check: ProjectGameplayReadinessCheck.eventCommands,
            status: ProjectGameplayReadinessEvidenceStatus.failed,
            summary: 'Une commande invalide contredit la preuve.',
            source: 'fixture:contradiction',
          ),
        ],
      );

      expect(report.isPlayable, isFalse);
      expect(report.errors, hasLength(1));
      expect(report.errors.single.check,
          ProjectGameplayReadinessCheck.eventCommands);
      expect(report.errors.single.summary, contains('contradictoires'));
    });
  });
}

List<ProjectGameplayReadinessEvidence> _passedEvidence() =>
    ProjectGameplayReadinessCheck.values
        .map(
          (check) => ProjectGameplayReadinessEvidence(
            check: check,
            status: ProjectGameplayReadinessEvidenceStatus.passed,
            summary: '${check.name} est vérifié.',
            source: 'reports/gameplay/proof.md',
          ),
        )
        .toList(growable: false);
