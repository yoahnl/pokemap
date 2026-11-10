import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:map_core/map_core_domain.dart';

VerificationReport withExtra(
  VerificationReport report,
  NarrativeProjectDiagnostic extra,
) => VerificationReport(
  requestId: report.requestId,
  savedRevision: report.savedRevision,
  generatedAt: report.generatedAt,
  validatorVersion: report.validatorVersion,
  inputFingerprint: report.inputFingerprint,
  freshnessKey: report.freshnessKey,
  isolateName: report.isolateName,
  project: NarrativeProjectValidationReport(
    diagnostics: [...report.diagnostics, extra],
    mapEventViews: const [],
  ),
  dependencies: report.dependencies,
  dimensions: report.dimensions,
  runtime: report.runtime,
  scope: report.scope,
  limitations: report.limitations,
  blockers: report.blockers,
  exclusions: report.exclusions,
  labels: report.labels,
  drafted: report.drafted,
);
