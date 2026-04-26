import '../models/enums.dart';
import 'legacy_path_surface_view.dart';
import 'legacy_project_surface_catalog_view.dart';
import 'legacy_terrain_surface_view.dart';

/// Diagnostic severity for legacy surface catalog audit output.
///
/// V0 intentionally has only two levels:
///
/// - [warning] for structural legacy data that can block or confuse migration;
/// - [info] for facts that are useful to preserve in a future Surface model.
enum LegacySurfaceCatalogDiagnosticSeverity {
  info,
  warning,
}

/// Stable diagnostic codes produced by [diagnoseLegacySurfaceCatalog].
///
/// These codes describe legacy preset facts. They are not persisted JSON schema
/// and they do not imply any runtime behavior. Keeping them explicit makes
/// migration reports testable without introducing the future Surface model yet.
enum LegacySurfaceCatalogDiagnosticCode {
  duplicateTerrainSurfaceId,
  duplicatePathSurfaceId,
  sharedTerrainAndPathId,
  terrainSurfaceWithoutVariants,
  pathSurfaceWithoutVariants,
  terrainVariantWithoutFrames,
  pathVariantWithoutFrames,
  duplicatePathVariantMapping,
  terrainSurfaceWithWeightedVariants,
  terrainSurfaceWithAnimatedVariants,
  pathSurfaceWithAnimatedVariants,
  frameTilesetOverrideUsed,
}

/// Legacy surface family targeted by one diagnostic.
///
/// Terrain and path remain separate by design. [crossFamily] is used only for
/// facts that mention both families, such as a shared id.
enum LegacySurfaceCatalogDiagnosticFamily {
  terrain,
  path,
  crossFamily,
}

/// One read-only diagnostic emitted by a legacy surface catalog audit.
///
/// This is deliberately a small immutable Dart value, not a Freezed model and
/// not JSON. Future reporting/UI layers can map it to their own presentation
/// objects without making diagnostics part of the project manifest contract.
final class LegacySurfaceCatalogDiagnostic {
  const LegacySurfaceCatalogDiagnostic({
    required this.severity,
    required this.code,
    required this.family,
    required this.message,
    this.surfaceId,
    this.surfaceName,
    this.detail,
  });

  /// Whether this is a structural warning or informational migration fact.
  final LegacySurfaceCatalogDiagnosticSeverity severity;

  /// Stable machine-readable diagnostic code.
  final LegacySurfaceCatalogDiagnosticCode code;

  /// Legacy family this diagnostic belongs to.
  final LegacySurfaceCatalogDiagnosticFamily family;

  /// Short human-readable summary.
  final String message;

  /// Legacy surface id when the diagnostic can be tied to one id.
  final String? surfaceId;

  /// Legacy surface display name when the diagnostic can be tied to one preset.
  final String? surfaceName;

  /// Extra deterministic detail for reports and tests.
  final String? detail;
}

/// Diagnoses migration-relevant facts in [catalog].
///
/// This function is pure and read-only. It does not validate the source
/// manifest, does not fix duplicate ids, does not merge terrain/path families,
/// and does not synthesize missing variants or frames. It only reports facts
/// that future Surface Engine migration work will likely need to know.
List<LegacySurfaceCatalogDiagnostic> diagnoseLegacySurfaceCatalog(
  LegacyProjectSurfaceCatalogView catalog,
) {
  final diagnostics = <LegacySurfaceCatalogDiagnostic>[];

  _addDuplicateTerrainIdDiagnostics(diagnostics, catalog.terrainSurfaces);
  _addDuplicatePathIdDiagnostics(diagnostics, catalog.pathSurfaces);
  _addSharedTerrainAndPathIdDiagnostics(diagnostics, catalog);

  for (final surface in catalog.terrainSurfaces) {
    _addTerrainSurfaceDiagnostics(diagnostics, surface);
  }

  for (final surface in catalog.pathSurfaces) {
    _addPathSurfaceDiagnostics(diagnostics, surface);
  }

  return List.unmodifiable(diagnostics);
}

void _addDuplicateTerrainIdDiagnostics(
  List<LegacySurfaceCatalogDiagnostic> diagnostics,
  List<LegacyTerrainSurfaceView> surfaces,
) {
  final indicesById = _indicesById(surfaces, (surface) => surface.id);
  for (final entry in indicesById.entries) {
    final indices = entry.value;
    if (indices.length <= 1) {
      continue;
    }
    diagnostics.add(
      LegacySurfaceCatalogDiagnostic(
        severity: LegacySurfaceCatalogDiagnosticSeverity.warning,
        code: LegacySurfaceCatalogDiagnosticCode.duplicateTerrainSurfaceId,
        family: LegacySurfaceCatalogDiagnosticFamily.terrain,
        message: 'Duplicate terrain surface id.',
        surfaceId: entry.key,
        detail:
            '${indices.length} terrain surfaces share this id at indices ${indices.join(', ')}.',
      ),
    );
  }
}

void _addDuplicatePathIdDiagnostics(
  List<LegacySurfaceCatalogDiagnostic> diagnostics,
  List<LegacyPathSurfaceView> surfaces,
) {
  final indicesById = _indicesById(surfaces, (surface) => surface.id);
  for (final entry in indicesById.entries) {
    final indices = entry.value;
    if (indices.length <= 1) {
      continue;
    }
    diagnostics.add(
      LegacySurfaceCatalogDiagnostic(
        severity: LegacySurfaceCatalogDiagnosticSeverity.warning,
        code: LegacySurfaceCatalogDiagnosticCode.duplicatePathSurfaceId,
        family: LegacySurfaceCatalogDiagnosticFamily.path,
        message: 'Duplicate path surface id.',
        surfaceId: entry.key,
        detail:
            '${indices.length} path surfaces share this id at indices ${indices.join(', ')}.',
      ),
    );
  }
}

void _addSharedTerrainAndPathIdDiagnostics(
  List<LegacySurfaceCatalogDiagnostic> diagnostics,
  LegacyProjectSurfaceCatalogView catalog,
) {
  final pathIds = catalog.pathSurfaces.map((surface) => surface.id).toSet();
  final seenTerrainIds = <String>{};

  for (final surface in catalog.terrainSurfaces) {
    final id = surface.id;
    if (!seenTerrainIds.add(id) || !pathIds.contains(id)) {
      continue;
    }
    diagnostics.add(
      LegacySurfaceCatalogDiagnostic(
        severity: LegacySurfaceCatalogDiagnosticSeverity.info,
        code: LegacySurfaceCatalogDiagnosticCode.sharedTerrainAndPathId,
        family: LegacySurfaceCatalogDiagnosticFamily.crossFamily,
        message: 'Terrain and path surfaces share an id.',
        surfaceId: id,
        detail:
            'A terrain surface and a path surface both use this id; the catalog keeps families separate.',
      ),
    );
  }
}

void _addTerrainSurfaceDiagnostics(
  List<LegacySurfaceCatalogDiagnostic> diagnostics,
  LegacyTerrainSurfaceView surface,
) {
  if (!surface.hasVariants) {
    diagnostics.add(
      LegacySurfaceCatalogDiagnostic(
        severity: LegacySurfaceCatalogDiagnosticSeverity.warning,
        code: LegacySurfaceCatalogDiagnosticCode.terrainSurfaceWithoutVariants,
        family: LegacySurfaceCatalogDiagnosticFamily.terrain,
        message: 'Terrain surface has no variants.',
        surfaceId: surface.id,
        surfaceName: surface.name,
      ),
    );
  }

  for (var index = 0; index < surface.variants.length; index += 1) {
    final variant = surface.variants[index];
    if (!variant.hasFrames) {
      diagnostics.add(
        LegacySurfaceCatalogDiagnostic(
          severity: LegacySurfaceCatalogDiagnosticSeverity.warning,
          code: LegacySurfaceCatalogDiagnosticCode.terrainVariantWithoutFrames,
          family: LegacySurfaceCatalogDiagnosticFamily.terrain,
          message: 'Terrain variant has no frames.',
          surfaceId: surface.id,
          surfaceName: surface.name,
          detail: 'Terrain variant index $index has no frames.',
        ),
      );
    }
  }

  if (surface.hasWeightedVariants) {
    diagnostics.add(
      LegacySurfaceCatalogDiagnostic(
        severity: LegacySurfaceCatalogDiagnosticSeverity.info,
        code: LegacySurfaceCatalogDiagnosticCode
            .terrainSurfaceWithWeightedVariants,
        family: LegacySurfaceCatalogDiagnosticFamily.terrain,
        message: 'Terrain surface uses weighted variants.',
        surfaceId: surface.id,
        surfaceName: surface.name,
        detail:
            'At least one variant weight differs from the default weight 1.',
      ),
    );
  }

  if (surface.hasAnimatedVariants) {
    diagnostics.add(
      LegacySurfaceCatalogDiagnostic(
        severity: LegacySurfaceCatalogDiagnosticSeverity.info,
        code: LegacySurfaceCatalogDiagnosticCode
            .terrainSurfaceWithAnimatedVariants,
        family: LegacySurfaceCatalogDiagnosticFamily.terrain,
        message: 'Terrain surface has animated variants.',
        surfaceId: surface.id,
        surfaceName: surface.name,
      ),
    );
  }

  final overrideDetail = _firstTerrainTilesetOverrideDetail(surface);
  if (overrideDetail != null) {
    diagnostics.add(
      LegacySurfaceCatalogDiagnostic(
        severity: LegacySurfaceCatalogDiagnosticSeverity.info,
        code: LegacySurfaceCatalogDiagnosticCode.frameTilesetOverrideUsed,
        family: LegacySurfaceCatalogDiagnosticFamily.terrain,
        message: 'Terrain surface uses a frame tileset override.',
        surfaceId: surface.id,
        surfaceName: surface.name,
        detail: overrideDetail,
      ),
    );
  }
}

void _addPathSurfaceDiagnostics(
  List<LegacySurfaceCatalogDiagnostic> diagnostics,
  LegacyPathSurfaceView surface,
) {
  if (!surface.hasVariants) {
    diagnostics.add(
      LegacySurfaceCatalogDiagnostic(
        severity: LegacySurfaceCatalogDiagnosticSeverity.warning,
        code: LegacySurfaceCatalogDiagnosticCode.pathSurfaceWithoutVariants,
        family: LegacySurfaceCatalogDiagnosticFamily.path,
        message: 'Path surface has no variants.',
        surfaceId: surface.id,
        surfaceName: surface.name,
      ),
    );
  }

  for (var index = 0; index < surface.variants.length; index += 1) {
    final mapping = surface.variants[index];
    if (!mapping.hasFrames) {
      diagnostics.add(
        LegacySurfaceCatalogDiagnostic(
          severity: LegacySurfaceCatalogDiagnosticSeverity.warning,
          code: LegacySurfaceCatalogDiagnosticCode.pathVariantWithoutFrames,
          family: LegacySurfaceCatalogDiagnosticFamily.path,
          message: 'Path variant mapping has no frames.',
          surfaceId: surface.id,
          surfaceName: surface.name,
          detail:
              'Path mapping index $index for variant ${mapping.variant.name} has no frames.',
        ),
      );
    }
  }

  _addDuplicatePathVariantDiagnostics(diagnostics, surface);

  if (surface.hasAnimatedVariants) {
    diagnostics.add(
      LegacySurfaceCatalogDiagnostic(
        severity: LegacySurfaceCatalogDiagnosticSeverity.info,
        code:
            LegacySurfaceCatalogDiagnosticCode.pathSurfaceWithAnimatedVariants,
        family: LegacySurfaceCatalogDiagnosticFamily.path,
        message: 'Path surface has animated variants.',
        surfaceId: surface.id,
        surfaceName: surface.name,
      ),
    );
  }

  final overrideDetail = _firstPathTilesetOverrideDetail(surface);
  if (overrideDetail != null) {
    diagnostics.add(
      LegacySurfaceCatalogDiagnostic(
        severity: LegacySurfaceCatalogDiagnosticSeverity.info,
        code: LegacySurfaceCatalogDiagnosticCode.frameTilesetOverrideUsed,
        family: LegacySurfaceCatalogDiagnosticFamily.path,
        message: 'Path surface uses a frame tileset override.',
        surfaceId: surface.id,
        surfaceName: surface.name,
        detail: overrideDetail,
      ),
    );
  }
}

void _addDuplicatePathVariantDiagnostics(
  List<LegacySurfaceCatalogDiagnostic> diagnostics,
  LegacyPathSurfaceView surface,
) {
  final indicesByVariant = <TerrainPathVariant, List<int>>{};
  for (var index = 0; index < surface.variants.length; index += 1) {
    final variant = surface.variants[index].variant;
    (indicesByVariant[variant] ??= <int>[]).add(index);
  }

  for (final entry in indicesByVariant.entries) {
    final indices = entry.value;
    if (indices.length <= 1) {
      continue;
    }
    diagnostics.add(
      LegacySurfaceCatalogDiagnostic(
        severity: LegacySurfaceCatalogDiagnosticSeverity.warning,
        code: LegacySurfaceCatalogDiagnosticCode.duplicatePathVariantMapping,
        family: LegacySurfaceCatalogDiagnosticFamily.path,
        message: 'Path surface has duplicate variant mappings.',
        surfaceId: surface.id,
        surfaceName: surface.name,
        detail:
            'TerrainPathVariant ${entry.key.name} appears at mapping indices ${indices.join(', ')}.',
      ),
    );
  }
}

Map<String, List<int>> _indicesById<T>(
  List<T> surfaces,
  String Function(T surface) idOf,
) {
  final result = <String, List<int>>{};
  for (var index = 0; index < surfaces.length; index += 1) {
    final id = idOf(surfaces[index]);
    (result[id] ??= <int>[]).add(index);
  }
  return result;
}

String? _firstTerrainTilesetOverrideDetail(
  LegacyTerrainSurfaceView surface,
) {
  for (var variantIndex = 0;
      variantIndex < surface.variants.length;
      variantIndex += 1) {
    final variant = surface.variants[variantIndex];
    for (final frame in variant.frames) {
      if (frame.tilesetId.isNotEmpty) {
        return 'tilesetId override "${frame.tilesetId}" used in terrain variant index $variantIndex.';
      }
    }
  }
  return null;
}

String? _firstPathTilesetOverrideDetail(
  LegacyPathSurfaceView surface,
) {
  for (var mappingIndex = 0;
      mappingIndex < surface.variants.length;
      mappingIndex += 1) {
    final mapping = surface.variants[mappingIndex];
    for (final frame in mapping.frames) {
      if (frame.tilesetId.isNotEmpty) {
        return 'tilesetId override "${frame.tilesetId}" used in path mapping index $mappingIndex for variant ${mapping.variant.name}.';
      }
    }
  }
  return null;
}
