enum PathPatternDiagnosticSeverity {
  blocking,
  warning,
  info,
}

enum PathPatternDiagnosticCode {
  missingBasePathPreset,
  duplicateBasePathPresetId,
  duplicatePathPatternForBase,
  duplicatePathPatternId,
  missingBaseTileset,
  missingFrameTileset,
  centerPatternEmpty,
  cellWithoutFrames,
  centerOnly,
  partialVariantCoverage,
  noVariantCoverage,
  crossHandledByCenterPattern,
  pathPatternRenderAmbiguous,
  centerPatternStats,
}

final class PathPatternDiagnostic {
  const PathPatternDiagnostic({
    required this.code,
    required this.severity,
    required this.title,
    required this.description,
    this.suggestion,
    this.relatedId,
  });

  final PathPatternDiagnosticCode code;
  final PathPatternDiagnosticSeverity severity;
  final String title;
  final String description;
  final String? suggestion;
  final String? relatedId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathPatternDiagnostic &&
            code == other.code &&
            severity == other.severity &&
            title == other.title &&
            description == other.description &&
            suggestion == other.suggestion &&
            relatedId == other.relatedId;
  }

  @override
  int get hashCode => Object.hash(
        code,
        severity,
        title,
        description,
        suggestion,
        relatedId,
      );
}
