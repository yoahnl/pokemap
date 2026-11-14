import 'package:map_core/map_core_domain.dart';

enum VerificationProblemSeverity { error, warning, info }

final class VerificationProblem {
  const VerificationProblem({
    required this.code,
    required this.severity,
    required this.message,
    required this.destination,
    this.mapId,
    this.eventId,
    this.sceneId,
    this.stepId,
    this.factId,
    this.worldRuleId,
  });

  final String code;
  final VerificationProblemSeverity severity;
  final String message;
  final NarrativeProjectDiagnosticDestination destination;
  final String? mapId;
  final String? eventId;
  final String? sceneId;
  final String? stepId;
  final String? factId;
  final String? worldRuleId;
}

List<VerificationProblem> verificationProblems(
  NarrativeProjectValidationReport report,
  NarrativeValidationDimensionResult? physical,
) {
  final problems = <VerificationProblem>[
    for (final item in report.diagnostics)
      VerificationProblem(
        code: item.code,
        severity: switch (item.severity) {
          NarrativeProjectDiagnosticSeverity.error =>
            VerificationProblemSeverity.error,
          NarrativeProjectDiagnosticSeverity.warning =>
            VerificationProblemSeverity.warning,
          NarrativeProjectDiagnosticSeverity.info =>
            VerificationProblemSeverity.info,
        },
        message: item.message,
        destination: item.destination,
        mapId: item.mapId,
        eventId: item.eventId,
        sceneId: item.sceneId,
        stepId: item.stepId,
        factId: item.factId,
        worldRuleId: item.worldRuleId,
      ),
    for (final item in physical?.diagnostics ?? const [])
      VerificationProblem(
        code: item.code,
        severity: item.severity == 'error'
            ? VerificationProblemSeverity.error
            : VerificationProblemSeverity.warning,
        message: item.message,
        destination: item.path.startsWith('maps.')
            ? NarrativeProjectDiagnosticDestination.map
            : NarrativeProjectDiagnosticDestination.overview,
        mapId: item.path.startsWith('maps.') ? item.path.substring(5) : null,
      ),
  ];
  return [
    for (final severity in VerificationProblemSeverity.values)
      ...problems.where((problem) => problem.severity == severity),
  ];
}
