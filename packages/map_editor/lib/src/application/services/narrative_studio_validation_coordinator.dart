import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../infrastructure/repositories/narrative_runtime_smoke_receipt_repository.dart';

final class NarrativeStudioValidationCoordinator {
  const NarrativeStudioValidationCoordinator({
    this.validatorVersion = 'narrative-validator-v1',
  });

  final String validatorVersion;

  NarrativeMultidimensionalValidationReport coordinate({
    required ProjectManifest project,
    required List<MapData> maps,
    required NarrativeProjectValidationReport projectReport,
    required String projectFingerprint,
    required NarrativeRuntimeSmokeProfile profile,
    required NarrativeRuntimeSmokeReceiptResolution runtimeReceipt,
    DateTime? generatedAt,
  }) {
    final symbolic = projectReport.symbolicReachability;
    final physical = symbolic == null
        ? null
        : validateNarrativePhysicalReachability(
            project: project,
            maps: maps,
            narrativeReport: symbolic,
          );
    final structuralDiagnostics = projectReport.diagnostics
        .where((item) => !_isNarrativeSolvabilityCode(item.code))
        .map(_projectDiagnostic)
        .toList(growable: false);
    final structuralErrors = projectReport.diagnostics.any(
      (item) =>
          item.severity == NarrativeProjectDiagnosticSeverity.error &&
          !_isNarrativeSolvabilityCode(item.code),
    );
    final narrativeDiagnostics = projectReport.diagnostics
        .where((item) => _isNarrativeSolvabilityCode(item.code))
        .map(_projectDiagnostic)
        .toList(growable: false);

    return NarrativeMultidimensionalValidationReport(
      validatorVersion: validatorVersion,
      profileId: profile.id,
      profileVersion: profile.version,
      projectFingerprint: projectFingerprint,
      generatedAt: generatedAt ?? DateTime.now().toUtc(),
      structurallyValid: NarrativeValidationDimensionResult(
        status: structuralErrors
            ? NarrativeValidationStatus.fail
            : NarrativeValidationStatus.pass,
        diagnostics: structuralDiagnostics,
      ),
      narrativelySolvable: NarrativeValidationDimensionResult(
        status: _symbolicStatus(symbolic?.verdict),
        diagnostics: narrativeDiagnostics,
        evidenceRefs: symbolic == null
            ? const []
            : ['symbolic-states:${symbolic.exploredStateCount}'],
        limitations: symbolic == null
            ? const ['La preuve symbolique n’a pas été exécutée.']
            : [for (final issue in symbolic.issues) issue.message],
      ),
      physicallyReachable: NarrativeValidationDimensionResult(
        status: _physicalStatus(physical?.verdict),
        diagnostics: physical == null
            ? const []
            : [
                for (final issue in physical.issues)
                  NarrativeMultidimensionalDiagnostic(
                    id: 'physical:${issue.code.name}:${issue.eventId ?? ''}:${issue.mapId ?? ''}',
                    code: issue.code.name,
                    severity: issue.code ==
                            NarrativePhysicalIssueCode.permanentlyBlocked
                        ? 'error'
                        : 'warning',
                    message: issue.message,
                    path: issue.mapId == null ? 'maps' : 'maps.${issue.mapId}',
                  ),
              ],
        evidenceRefs: physical == null
            ? const []
            : [
                for (final result in physical.results)
                  if (result.reachedCell != null)
                    'event:${result.eventId}@${result.mapId}:${result.reachedCell!.x},${result.reachedCell!.y}',
              ],
        limitations: physical == null
            ? const ['La preuve physique n’a pas été exécutée.']
            : const [],
      ),
      runtimeSmokeVerified: NarrativeValidationDimensionResult(
        status: runtimeReceipt.validationStatus,
        evidenceRefs: runtimeReceipt.receipt == null
            ? const []
            : [
                NarrativeRuntimeSmokeReceiptRepository.relativeReceiptPath,
                ...runtimeReceipt.receipt!.suiteIds.map((id) => 'suite:$id'),
              ],
        limitations: [
          if (runtimeReceipt.validationStatus != NarrativeValidationStatus.pass)
            runtimeReceipt.reason,
          ...?runtimeReceipt.receipt?.limitations,
        ],
      ),
    );
  }
}

NarrativeValidationStatus _symbolicStatus(NarrativeSymbolicVerdict? verdict) =>
    switch (verdict) {
      NarrativeSymbolicVerdict.pass => NarrativeValidationStatus.pass,
      NarrativeSymbolicVerdict.fail => NarrativeValidationStatus.fail,
      NarrativeSymbolicVerdict.indeterminate =>
        NarrativeValidationStatus.indeterminate,
      null => NarrativeValidationStatus.notRun,
    };

NarrativeValidationStatus _physicalStatus(
  NarrativePhysicalReachabilityVerdict? verdict,
) =>
    switch (verdict) {
      NarrativePhysicalReachabilityVerdict.pass =>
        NarrativeValidationStatus.pass,
      NarrativePhysicalReachabilityVerdict.fail =>
        NarrativeValidationStatus.fail,
      NarrativePhysicalReachabilityVerdict.indeterminate =>
        NarrativeValidationStatus.indeterminate,
      null => NarrativeValidationStatus.notRun,
    };

NarrativeMultidimensionalDiagnostic _projectDiagnostic(
  NarrativeProjectDiagnostic item,
) =>
    NarrativeMultidimensionalDiagnostic(
      id: item.stableKey,
      code: item.code,
      severity: item.severity.name,
      message: item.message,
      path: item.path,
    );

bool _isNarrativeSolvabilityCode(String code) =>
    code.startsWith('narrative') || code == 'oneShotRetryableOutcomeSoftlock';
