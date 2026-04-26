import '../models/map_data.dart';
import '../models/project_manifest.dart';
import 'legacy_project_surface_catalog_view.dart';
import 'legacy_surface_catalog_diagnostics.dart';
import 'legacy_surface_usage_diagnostics.dart';
import 'legacy_surface_usage_view.dart';

/// Read-only audit snapshot for legacy surface migration planning.
///
/// This report is a pure assembly layer over the transitional Surface Engine
/// building blocks introduced before Lot 10:
///
/// - the declared legacy surface catalog from [ProjectManifest];
/// - the actual terrain/path usages discovered in [MapData] layers;
/// - catalog diagnostics for declared preset structure;
/// - usage diagnostics for how map layers relate to declared presets.
///
/// It is deliberately not persisted, not JSON, not Freezed, and not a unified
/// Surface model. Terrain and path remain separated inside the catalog and
/// usage views so later migration lots can decide explicitly how to model them.
final class LegacySurfaceAuditReport {
  LegacySurfaceAuditReport({
    required this.catalog,
    required this.usage,
    required List<LegacySurfaceCatalogDiagnostic> catalogDiagnostics,
    required List<LegacySurfaceUsageDiagnostic> usageDiagnostics,
    required this.summary,
  })  : catalogDiagnostics = List.unmodifiable(catalogDiagnostics),
        usageDiagnostics = List.unmodifiable(usageDiagnostics);

  /// Declared legacy terrain/path surfaces from the manifest.
  final LegacyProjectSurfaceCatalogView catalog;

  /// Actual legacy terrain/path usage discovered across analyzed maps.
  final LegacyProjectSurfaceUsageView usage;

  /// Diagnostics about declared legacy surface preset structure.
  ///
  /// This list is unmodifiable. The report does not filter, repair, or
  /// downgrade diagnostics emitted by [diagnoseLegacySurfaceCatalog].
  final List<LegacySurfaceCatalogDiagnostic> catalogDiagnostics;

  /// Diagnostics about how actual map usage relates to declared presets.
  ///
  /// This list is unmodifiable. The report preserves the exact diagnostics
  /// emitted by [diagnoseLegacySurfaceUsage].
  final List<LegacySurfaceUsageDiagnostic> usageDiagnostics;

  /// Aggregate counts for quick reporting and future UI summaries.
  final LegacySurfaceAuditSummary summary;

  /// Whether any catalog or usage diagnostic exists.
  bool get hasDiagnostics =>
      catalogDiagnostics.isNotEmpty || usageDiagnostics.isNotEmpty;

  /// Whether any catalog or usage diagnostic has warning severity.
  ///
  /// Catalog diagnostics and usage diagnostics intentionally have separate
  /// severity enums. This getter checks each enum in its own family rather
  /// than trying to collapse them into a shared type.
  bool get hasWarnings {
    return catalogDiagnostics.any(
          (diagnostic) =>
              diagnostic.severity ==
              LegacySurfaceCatalogDiagnosticSeverity.warning,
        ) ||
        usageDiagnostics.any(
          (diagnostic) =>
              diagnostic.severity ==
              LegacySurfaceUsageDiagnosticSeverity.warning,
        );
  }

  /// Whether analyzed maps contain any terrain, path, or missing path usage.
  bool get hasUsage =>
      usage.hasTerrainUsage ||
      usage.hasPathUsage ||
      usage.hasMissingPathSurfaceUsage;
}

/// Compact counts for a [LegacySurfaceAuditReport].
///
/// The summary is intentionally factual and mechanical. It does not score
/// migration readiness or hide diagnostics; it only counts the already exposed
/// catalog, usage, and warning data.
final class LegacySurfaceAuditSummary {
  const LegacySurfaceAuditSummary({
    required this.terrainSurfaceCount,
    required this.pathSurfaceCount,
    required this.terrainUsageCount,
    required this.pathUsageCount,
    required this.missingPathUsageCount,
    required this.catalogDiagnosticCount,
    required this.catalogWarningCount,
    required this.usageDiagnosticCount,
    required this.usageWarningCount,
  });

  /// Number of declared terrain surface candidates.
  final int terrainSurfaceCount;

  /// Number of declared path surface candidates.
  final int pathSurfaceCount;

  /// Number of discovered terrain usage entries.
  final int terrainUsageCount;

  /// Number of discovered path usages that resolved to a declared preset.
  final int pathUsageCount;

  /// Number of active path usages whose preset id did not resolve.
  final int missingPathUsageCount;

  /// Number of catalog diagnostics in the report.
  final int catalogDiagnosticCount;

  /// Number of catalog diagnostics with warning severity.
  final int catalogWarningCount;

  /// Number of usage diagnostics in the report.
  final int usageDiagnosticCount;

  /// Number of usage diagnostics with warning severity.
  final int usageWarningCount;
}

/// Creates a complete read-only legacy surface audit report.
///
/// This function assembles existing pure operations. It does not mutate the
/// manifest or maps, does not repair legacy data, does not filter diagnostics,
/// and does not create any persistent Surface schema. The returned report is a
/// snapshot suitable for future migration tooling, editor panels, or generated
/// audit reports.
LegacySurfaceAuditReport createLegacySurfaceAuditReport({
  required ProjectManifest manifest,
  required Iterable<MapData> maps,
}) {
  final catalog = createLegacyProjectSurfaceCatalogView(manifest);
  final usage = createLegacyProjectSurfaceUsageView(
    catalog: catalog,
    maps: maps,
  );
  final catalogDiagnostics = diagnoseLegacySurfaceCatalog(catalog);
  final usageDiagnostics = diagnoseLegacySurfaceUsage(
    catalog: catalog,
    usage: usage,
  );

  return LegacySurfaceAuditReport(
    catalog: catalog,
    usage: usage,
    catalogDiagnostics: catalogDiagnostics,
    usageDiagnostics: usageDiagnostics,
    summary: LegacySurfaceAuditSummary(
      terrainSurfaceCount: catalog.terrainSurfaces.length,
      pathSurfaceCount: catalog.pathSurfaces.length,
      terrainUsageCount: usage.terrainUsages.length,
      pathUsageCount: usage.pathUsages.length,
      missingPathUsageCount: usage.missingPathSurfaceUsages.length,
      catalogDiagnosticCount: catalogDiagnostics.length,
      catalogWarningCount: _catalogWarningCount(catalogDiagnostics),
      usageDiagnosticCount: usageDiagnostics.length,
      usageWarningCount: _usageWarningCount(usageDiagnostics),
    ),
  );
}

int _catalogWarningCount(
  List<LegacySurfaceCatalogDiagnostic> diagnostics,
) {
  return diagnostics
      .where(
        (diagnostic) =>
            diagnostic.severity ==
            LegacySurfaceCatalogDiagnosticSeverity.warning,
      )
      .length;
}

int _usageWarningCount(
  List<LegacySurfaceUsageDiagnostic> diagnostics,
) {
  return diagnostics
      .where(
        (diagnostic) =>
            diagnostic.severity == LegacySurfaceUsageDiagnosticSeverity.warning,
      )
      .length;
}
