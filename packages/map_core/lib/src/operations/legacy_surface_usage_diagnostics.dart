import '../models/enums.dart';
import 'legacy_path_surface_view.dart';
import 'legacy_project_surface_catalog_view.dart';
import 'legacy_surface_usage_view.dart';

/// Diagnostic severity for legacy surface usage audit output.
///
/// This mirrors the catalog diagnostics split while keeping usage diagnostics
/// as a separate, non-persistent vocabulary:
///
/// - [warning] means the current map usage can block, break, or make a future
///   Surface migration ambiguous;
/// - [info] means the fact is useful to migration reports but is not itself
///   broken legacy data.
enum LegacySurfaceUsageDiagnosticSeverity {
  info,
  warning,
}

/// Legacy usage diagnostic family.
///
/// Terrain and path remain separate by design. Lot 9 deliberately does not add
/// a shared Surface union or collapse both families into one model.
enum LegacySurfaceUsageDiagnosticFamily {
  terrain,
  path,
}

/// Stable diagnostic codes produced by [diagnoseLegacySurfaceUsage].
///
/// These codes describe usage facts across the legacy catalog and the maps
/// analyzed by `LegacyProjectSurfaceUsageView`. They are not serialized, not
/// Freezed, and not part of the project manifest schema.
enum LegacySurfaceUsageDiagnosticCode {
  usedTerrainTypeWithoutDeclaredSurface,
  declaredTerrainSurfaceWithoutMatchingUsage,
  usedTerrainTypeWithMultipleDeclaredSurfaces,
  missingPathSurfaceUsage,
  emptyPathPresetIdUsage,
  declaredPathSurfaceWithoutUsage,
  usedPathPresetWithMultipleDeclaredSurfaces,
  usedPathSurfaceWithoutVariants,
  usedTerrainSurfaceCandidateWithoutVariants,
}

/// One read-only diagnostic emitted by a legacy surface usage audit.
///
/// A diagnostic can point at declared surface data, actual map/layer usage, or
/// both. Keeping all fields nullable avoids inventing fake ids for cases where
/// the legacy model simply does not carry a stronger reference, such as terrain
/// cells that only store [TerrainType].
final class LegacySurfaceUsageDiagnostic {
  const LegacySurfaceUsageDiagnostic({
    required this.severity,
    required this.code,
    required this.family,
    required this.message,
    this.terrainType,
    this.pathPresetId,
    this.surfaceId,
    this.surfaceName,
    this.mapId,
    this.mapName,
    this.layerIndex,
    this.layerId,
    this.layerName,
    this.detail,
  });

  /// Whether this is a migration warning or informational usage fact.
  final LegacySurfaceUsageDiagnosticSeverity severity;

  /// Stable machine-readable diagnostic code.
  final LegacySurfaceUsageDiagnosticCode code;

  /// Legacy family this diagnostic belongs to.
  final LegacySurfaceUsageDiagnosticFamily family;

  /// Short human-readable summary.
  final String message;

  /// Terrain type when the diagnostic is tied to terrain usage.
  final TerrainType? terrainType;

  /// Path preset id when the diagnostic is tied to path usage.
  final String? pathPresetId;

  /// Declared legacy surface id when one is known.
  final String? surfaceId;

  /// Declared legacy surface display name when one is known.
  final String? surfaceName;

  /// Map id from an actual usage, when applicable.
  final String? mapId;

  /// Map name from an actual usage, when applicable.
  final String? mapName;

  /// Layer index from an actual usage, when applicable.
  final int? layerIndex;

  /// Layer id from an actual usage, when applicable.
  final String? layerId;

  /// Layer name from an actual usage, when applicable.
  final String? layerName;

  /// Extra deterministic detail for reports and tests.
  final String? detail;
}

/// Diagnoses migration-relevant facts in [catalog] and [usage].
///
/// This function is pure and read-only. It does not validate the source
/// manifest, does not correct missing path presets, does not de-duplicate ids,
/// and does not create a unified Surface model. It only reports how declared
/// legacy surface candidates relate to actual map usage.
List<LegacySurfaceUsageDiagnostic> diagnoseLegacySurfaceUsage({
  required LegacyProjectSurfaceCatalogView catalog,
  required LegacyProjectSurfaceUsageView usage,
}) {
  final diagnostics = <LegacySurfaceUsageDiagnostic>[];

  _addTerrainUsageDiagnostics(diagnostics, catalog, usage);
  _addDeclaredTerrainWithoutUsageDiagnostics(diagnostics, catalog, usage);
  _addMissingPathUsageDiagnostics(diagnostics, usage);
  _addUsedPathDuplicateCandidateDiagnostics(diagnostics, catalog, usage);
  _addUsedPathWithoutVariantsDiagnostics(diagnostics, usage);
  _addDeclaredPathWithoutUsageDiagnostics(diagnostics, catalog, usage);

  return List.unmodifiable(diagnostics);
}

void _addTerrainUsageDiagnostics(
  List<LegacySurfaceUsageDiagnostic> diagnostics,
  LegacyProjectSurfaceCatalogView catalog,
  LegacyProjectSurfaceUsageView usage,
) {
  for (final terrainType in _terrainTypesInUsageOrder(usage)) {
    final firstUsage = _firstTerrainUsage(usage, terrainType);
    if (firstUsage == null) {
      continue;
    }

    final candidates = catalog.terrainSurfacesByType(terrainType);
    if (candidates.isEmpty) {
      diagnostics.add(
        LegacySurfaceUsageDiagnostic(
          severity: LegacySurfaceUsageDiagnosticSeverity.warning,
          code: LegacySurfaceUsageDiagnosticCode
              .usedTerrainTypeWithoutDeclaredSurface,
          family: LegacySurfaceUsageDiagnosticFamily.terrain,
          message: 'Used terrain type has no declared terrain surface.',
          terrainType: terrainType,
          mapId: firstUsage.mapId,
          mapName: firstUsage.mapName,
          layerIndex: firstUsage.layerIndex,
          layerId: firstUsage.layerId,
          layerName: firstUsage.layerName,
          detail:
              'TerrainType ${terrainType.name} is used but no declared terrain surface matches it.',
        ),
      );
    } else {
      if (candidates.length > 1) {
        diagnostics.add(
          LegacySurfaceUsageDiagnostic(
            severity: LegacySurfaceUsageDiagnosticSeverity.warning,
            code: LegacySurfaceUsageDiagnosticCode
                .usedTerrainTypeWithMultipleDeclaredSurfaces,
            family: LegacySurfaceUsageDiagnosticFamily.terrain,
            message: 'Used terrain type has multiple declared candidates.',
            terrainType: terrainType,
            mapId: firstUsage.mapId,
            mapName: firstUsage.mapName,
            layerIndex: firstUsage.layerIndex,
            layerId: firstUsage.layerId,
            layerName: firstUsage.layerName,
            detail:
                '${candidates.length} declared terrain surfaces match TerrainType ${terrainType.name}.',
          ),
        );
      }

      for (final candidate in candidates) {
        if (candidate.hasVariants) {
          continue;
        }
        diagnostics.add(
          LegacySurfaceUsageDiagnostic(
            severity: LegacySurfaceUsageDiagnosticSeverity.warning,
            code: LegacySurfaceUsageDiagnosticCode
                .usedTerrainSurfaceCandidateWithoutVariants,
            family: LegacySurfaceUsageDiagnosticFamily.terrain,
            message: 'Used terrain surface candidate has no variants.',
            terrainType: terrainType,
            surfaceId: candidate.id,
            surfaceName: candidate.name,
            mapId: firstUsage.mapId,
            mapName: firstUsage.mapName,
            layerIndex: firstUsage.layerIndex,
            layerId: firstUsage.layerId,
            layerName: firstUsage.layerName,
            detail:
                'Terrain surface ${candidate.id} matches a used TerrainType but has no variants.',
          ),
        );
      }
    }
  }
}

void _addDeclaredTerrainWithoutUsageDiagnostics(
  List<LegacySurfaceUsageDiagnostic> diagnostics,
  LegacyProjectSurfaceCatalogView catalog,
  LegacyProjectSurfaceUsageView usage,
) {
  final usedTypes = _terrainTypesInUsageOrder(usage).toSet();
  for (final surface in catalog.terrainSurfaces) {
    if (usedTypes.contains(surface.terrainType)) {
      continue;
    }
    diagnostics.add(
      LegacySurfaceUsageDiagnostic(
        severity: LegacySurfaceUsageDiagnosticSeverity.info,
        code: LegacySurfaceUsageDiagnosticCode
            .declaredTerrainSurfaceWithoutMatchingUsage,
        family: LegacySurfaceUsageDiagnosticFamily.terrain,
        message: 'Declared terrain surface has no matching terrain usage.',
        terrainType: surface.terrainType,
        surfaceId: surface.id,
        surfaceName: surface.name,
        detail:
            'No analyzed TerrainLayer usage contains TerrainType ${surface.terrainType.name}.',
      ),
    );
  }
}

void _addMissingPathUsageDiagnostics(
  List<LegacySurfaceUsageDiagnostic> diagnostics,
  LegacyProjectSurfaceUsageView usage,
) {
  for (final missingUsage in usage.missingPathSurfaceUsages) {
    final isEmptyPresetId = missingUsage.presetId.isEmpty;
    diagnostics.add(
      LegacySurfaceUsageDiagnostic(
        severity: LegacySurfaceUsageDiagnosticSeverity.warning,
        code: isEmptyPresetId
            ? LegacySurfaceUsageDiagnosticCode.emptyPathPresetIdUsage
            : LegacySurfaceUsageDiagnosticCode.missingPathSurfaceUsage,
        family: LegacySurfaceUsageDiagnosticFamily.path,
        message: isEmptyPresetId
            ? 'Active path layer has an empty preset id.'
            : 'Active path layer references a missing path preset.',
        pathPresetId: missingUsage.presetId,
        mapId: missingUsage.mapId,
        mapName: missingUsage.mapName,
        layerIndex: missingUsage.layerIndex,
        layerId: missingUsage.layerId,
        layerName: missingUsage.layerName,
        detail: 'Active path cell count: ${missingUsage.activeCellCount}.',
      ),
    );
  }
}

void _addUsedPathDuplicateCandidateDiagnostics(
  List<LegacySurfaceUsageDiagnostic> diagnostics,
  LegacyProjectSurfaceCatalogView catalog,
  LegacyProjectSurfaceUsageView usage,
) {
  for (final presetId in _pathPresetIdsInUsageOrder(usage)) {
    final candidates = _pathSurfacesById(catalog, presetId);
    if (candidates.length <= 1) {
      continue;
    }
    final firstUsage = _firstPathUsage(usage, presetId);
    diagnostics.add(
      LegacySurfaceUsageDiagnostic(
        severity: LegacySurfaceUsageDiagnosticSeverity.warning,
        code: LegacySurfaceUsageDiagnosticCode
            .usedPathPresetWithMultipleDeclaredSurfaces,
        family: LegacySurfaceUsageDiagnosticFamily.path,
        message: 'Used path preset id has multiple declared candidates.',
        pathPresetId: presetId,
        mapId: firstUsage?.mapId,
        mapName: firstUsage?.mapName,
        layerIndex: firstUsage?.layerIndex,
        layerId: firstUsage?.layerId,
        layerName: firstUsage?.layerName,
        detail:
            '${candidates.length} declared path surfaces share the used id $presetId.',
      ),
    );
  }
}

void _addUsedPathWithoutVariantsDiagnostics(
  List<LegacySurfaceUsageDiagnostic> diagnostics,
  LegacyProjectSurfaceUsageView usage,
) {
  for (final pathUsage in usage.pathUsages) {
    if (pathUsage.surface.hasVariants) {
      continue;
    }
    diagnostics.add(
      LegacySurfaceUsageDiagnostic(
        severity: LegacySurfaceUsageDiagnosticSeverity.warning,
        code: LegacySurfaceUsageDiagnosticCode.usedPathSurfaceWithoutVariants,
        family: LegacySurfaceUsageDiagnosticFamily.path,
        message: 'Used path surface has no variants.',
        pathPresetId: pathUsage.presetId,
        surfaceId: pathUsage.surface.id,
        surfaceName: pathUsage.surface.name,
        mapId: pathUsage.mapId,
        mapName: pathUsage.mapName,
        layerIndex: pathUsage.layerIndex,
        layerId: pathUsage.layerId,
        layerName: pathUsage.layerName,
        detail: 'Active path cell count: ${pathUsage.activeCellCount}.',
      ),
    );
  }
}

void _addDeclaredPathWithoutUsageDiagnostics(
  List<LegacySurfaceUsageDiagnostic> diagnostics,
  LegacyProjectSurfaceCatalogView catalog,
  LegacyProjectSurfaceUsageView usage,
) {
  final usedPathIds = _pathPresetIdsInUsageOrder(usage).toSet();
  for (final surface in catalog.pathSurfaces) {
    if (usedPathIds.contains(surface.id)) {
      continue;
    }
    diagnostics.add(
      LegacySurfaceUsageDiagnostic(
        severity: LegacySurfaceUsageDiagnosticSeverity.info,
        code: LegacySurfaceUsageDiagnosticCode.declaredPathSurfaceWithoutUsage,
        family: LegacySurfaceUsageDiagnosticFamily.path,
        message: 'Declared path surface has no matching path usage.',
        pathPresetId: surface.id,
        surfaceId: surface.id,
        surfaceName: surface.name,
        detail:
            'No analyzed PathLayer usage resolves to path preset id ${surface.id}.',
      ),
    );
  }
}

List<TerrainType> _terrainTypesInUsageOrder(
  LegacyProjectSurfaceUsageView usage,
) {
  final seen = <TerrainType>{};
  final ordered = <TerrainType>[];
  for (final terrainUsage in usage.terrainUsages) {
    final type = terrainUsage.terrainType;
    if (type == TerrainType.none || !seen.add(type)) {
      continue;
    }
    ordered.add(type);
  }
  return ordered;
}

LegacyTerrainSurfaceUsage? _firstTerrainUsage(
  LegacyProjectSurfaceUsageView usage,
  TerrainType type,
) {
  for (final terrainUsage in usage.terrainUsages) {
    if (terrainUsage.terrainType == type) {
      return terrainUsage;
    }
  }
  return null;
}

List<String> _pathPresetIdsInUsageOrder(
  LegacyProjectSurfaceUsageView usage,
) {
  final seen = <String>{};
  final ordered = <String>[];
  for (final pathUsage in usage.pathUsages) {
    final id = pathUsage.presetId;
    if (!seen.add(id)) {
      continue;
    }
    ordered.add(id);
  }
  return ordered;
}

LegacyPathSurfaceUsage? _firstPathUsage(
  LegacyProjectSurfaceUsageView usage,
  String presetId,
) {
  for (final pathUsage in usage.pathUsages) {
    if (pathUsage.presetId == presetId) {
      return pathUsage;
    }
  }
  return null;
}

List<LegacyPathSurfaceView> _pathSurfacesById(
  LegacyProjectSurfaceCatalogView catalog,
  String id,
) {
  return catalog.pathSurfaces
      .where((surface) => surface.id == id)
      .toList(growable: false);
}
