enum HubDiagnosticSeverity { information, warning, error }

/// Cross-cutting diagnostic contract.
///
/// Lives in `core/` rather than in a feature because `installation` and `saves`
/// both raise it, and the dashboard only aggregates what they report.
final class HubDiagnostic {
  const HubDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.recommendation,
    this.gameId,
    this.technicalDetails,
    this.logPath,
  });

  final String code;
  final HubDiagnosticSeverity severity;
  final String message;
  final String recommendation;
  final String? gameId;
  final String? technicalDetails;
  final String? logPath;
}
