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
  /// Lot PathPattern-41 — fichier image tileset absent sur disque.
  missingTilesetImageFile,
  /// Lot PathPattern-41 — octets présents mais décodage image impossible.
  unreadableTilesetImageFile,
  /// Lot PathPattern-41 — `TilesetSourceRect` dépasse l’atlas en pixels.
  frameSourceOutOfBounds,
  /// Lot PathPattern-41 — source autre que 1×1 tuile (aperçu V0 = 1×1).
  unsupportedPathPatternFrameSize,
  /// Lot PathPattern-41 — pas de racine projet / dimensions tuile invalides.
  assetValidationUnavailable,
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
