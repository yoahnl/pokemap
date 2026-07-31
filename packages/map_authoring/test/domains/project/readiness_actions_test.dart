import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('readiness aggregates validators and only plans cited fixes', () async {
    final coreReport = ProjectGameplayReadinessReport.evaluate(
      <ProjectGameplayReadinessEvidence>[
        for (final check in ProjectGameplayReadinessCheck.values)
          ProjectGameplayReadinessEvidence(
            check: check,
            status: check == ProjectGameplayReadinessCheck.shopItems
                ? ProjectGameplayReadinessEvidenceStatus.failed
                : ProjectGameplayReadinessEvidenceStatus.passed,
            summary: check == ProjectGameplayReadinessCheck.shopItems
                ? 'No sellable item is reachable.'
                : '${check.name} is covered.',
            source: 'validator://fixture/${check.name}',
          ),
      ],
    );
    final actions = ProjectReadinessActions(
      validators: <ProjectReadinessValidatorPort>[
        MapCoreProjectReadinessAdapter(() async => coreReport),
        MapCoreMvpReleaseGateAdapter(() async => _releaseGateReport()),
      ],
    );

    final result = await actions.evaluate(
      plannedFixesByDiagnosticId: <String, ReadinessPlannedFix>{
        'gameplay.shopItems': ReadinessPlannedFix(
          actionId: 'shop.upsert',
          reason: 'Add one reachable shop inventory entry.',
          parameters: <String, Object?>{
            'shopId': 'shop.golden',
            'itemId': 'potion',
          },
        ),
      },
    );

    expect(result.isReady, isFalse);
    expect(
      result.diagnostics,
      everyElement(
        isA<AuthoringReadinessDiagnostic>().having(
          (item) => item.evidenceRef,
          'evidenceRef',
          isNotEmpty,
        ),
      ),
    );
    expect(result.plannedFixes, hasLength(1));
    expect(result.plannedFixes.single.actionId, 'shop.upsert');
    expect(
      result.diagnostics
          .singleWhere((item) => item.id == 'gameplay.shopItems')
          .plannedFix,
      isNotNull,
    );
    expect(
      result.diagnostics
          .singleWhere((item) => item.id == 'release.criticalPackageTests')
          .plannedFix,
      isNull,
    );
  });

  test('readiness rejects diagnostics without stable evidence', () {
    expect(
      () => AuthoringReadinessDiagnostic(
        id: 'release.invalid',
        severity: AuthoringReadinessSeverity.error,
        summary: 'Missing source.',
        evidenceRef: ' ',
      ),
      throwsArgumentError,
    );
  });
}

MvpReleaseGateReport _releaseGateReport() => MvpReleaseGateReport.evaluate(
      MvpReleaseGateCriterion.values.map(
        (criterion) => MvpReleaseGateEvidence.fromExecutionReceipt(
          MvpReleaseGateExecutionReceipt.validated(
            criterion: criterion,
            summary: '${criterion.name} passed.',
            source: 'test://release/${criterion.name}',
            releaseCandidateCommit: 'a' * 40,
            command: 'test ${criterion.name}',
            exitCode: 0,
            outputDigestSha256: 'b' * 64,
          ),
        ),
      ),
    );
