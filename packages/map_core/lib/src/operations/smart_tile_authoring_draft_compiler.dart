import 'package:meta/meta.dart' show immutable;

import '../models/project_manifest.dart';
import '../models/smart_tile.dart';
import 'smart_tile_catalog_validation.dart';
import 'smart_tile_coverage.dart';

sealed class SmartTileDraftCompilationResult {
  const SmartTileDraftCompilationResult();
}

@immutable
final class SmartTileDraftCompilationSuccess
    extends SmartTileDraftCompilationResult {
  SmartTileDraftCompilationSuccess({
    required this.preset,
    required List<ProjectSmartTileAtlas> atlases,
    required List<ProjectSmartTileMaterial> materials,
    required List<ProjectSmartTileAnimation> animations,
    required this.coverage,
    required List<SmartTileDiagnostic> diagnostics,
  })  : atlases = List<ProjectSmartTileAtlas>.unmodifiable(atlases),
        materials = List<ProjectSmartTileMaterial>.unmodifiable(materials),
        animations = List<ProjectSmartTileAnimation>.unmodifiable(animations),
        diagnostics = List<SmartTileDiagnostic>.unmodifiable(diagnostics);

  final ProjectSmartTilePreset preset;
  final List<ProjectSmartTileAtlas> atlases;
  final List<ProjectSmartTileMaterial> materials;
  final List<ProjectSmartTileAnimation> animations;
  final SmartTileCoverageReport coverage;
  final List<SmartTileDiagnostic> diagnostics;
}

@immutable
final class SmartTileDraftCompilationFailure
    extends SmartTileDraftCompilationResult {
  SmartTileDraftCompilationFailure({
    required List<SmartTileDiagnostic> diagnostics,
  }) : diagnostics = List<SmartTileDiagnostic>.unmodifiable(diagnostics);

  final List<SmartTileDiagnostic> diagnostics;
}

/// Projects one isolated Studio draft into publishable canonical resources.
///
/// This operation is deterministic, performs no I/O, and never mutates the
/// draft, catalog, or manifest supplied by its caller.
SmartTileDraftCompilationResult compileSmartTileAuthoringDraft({
  required ProjectSmartTileAuthoringDraft draft,
  required ProjectSmartTileCatalog catalog,
  required ProjectManifest manifest,
}) {
  final projectTilesetIds = manifest.tilesets.map((tileset) => tileset.id);
  final diagnostics = <SmartTileDiagnostic>[
    ...validateProjectSmartTileCatalog(
      catalog: ProjectSmartTileCatalog(
        categories: catalog.categories,
        atlases: catalog.atlases,
        materials: catalog.materials,
        animations: catalog.animations,
        presets: catalog.presets,
        drafts: <ProjectSmartTileAuthoringDraft>[draft],
      ),
      projectTilesetIds: projectTilesetIds,
    ),
  ];

  final primaryAtlasId = draft.primaryAtlasId;
  if (primaryAtlasId == null || primaryAtlasId.trim().isEmpty) {
    diagnostics.add(
      _draftError(
        code: 'smart_tiles.draft.atlas_missing',
        path: r'$.smartTileCatalog.drafts[0].primaryAtlasId',
        message: 'A publishable Smart Tile draft requires a primary atlas.',
      ),
    );
  }

  final defaultMaterialId = draft.defaultMaterialId;
  if (defaultMaterialId == null || defaultMaterialId.trim().isEmpty) {
    diagnostics.add(
      _draftError(
        code: 'smart_tiles.draft.default_material_missing',
        path: r'$.smartTileCatalog.drafts[0].defaultMaterialId',
        message: 'A publishable Smart Tile draft requires a default material.',
      ),
    );
    return SmartTileDraftCompilationFailure(
      diagnostics: _uniqueDiagnostics(diagnostics),
    );
  }

  final atlases = _upsertAllById<ProjectSmartTileAtlas>(
    catalog.atlases,
    draft.atlases,
    (item) => item.id,
  );
  final materials = _upsertAllById<ProjectSmartTileMaterial>(
    catalog.materials,
    draft.materials,
    (item) => item.id,
  );
  final animations = _upsertAllById<ProjectSmartTileAnimation>(
    catalog.animations,
    draft.animations,
    (item) => item.id,
  );

  if (primaryAtlasId != null &&
      !atlases.any((atlas) => atlas.id == primaryAtlasId)) {
    diagnostics.add(
      _draftError(
        code: 'smart_tiles.draft.atlas_missing',
        path: r'$.smartTileCatalog.drafts[0].primaryAtlasId',
        message: 'Primary atlas "$primaryAtlasId" does not exist.',
      ),
    );
  }
  if (!materials.any((material) => material.id == defaultMaterialId)) {
    diagnostics.add(
      _draftError(
        code: 'smart_tiles.draft.default_material_missing',
        path: r'$.smartTileCatalog.drafts[0].defaultMaterialId',
        message: 'Default material "$defaultMaterialId" does not exist.',
      ),
    );
  }

  final preset = ProjectSmartTilePreset(
    id: draft.targetPresetId,
    name: draft.name,
    categoryId: draft.categoryId,
    usage: draft.usage,
    topology: draft.topology,
    templateHint: draft.templateHint,
    boundaryPolicy: draft.boundaryPolicy,
    status: SmartTilePresetStatus.published,
    coveragePolicy: draft.coveragePolicy,
    coverageProfile: draft.coverageProfile,
    transformPolicy: draft.transformPolicy,
    defaultMaterialId: defaultMaterialId,
    allowedMaterialIds: draft.allowedMaterialIds,
    rules: draft.rules,
    tags: draft.tags,
    sortOrder: draft.sortOrder,
    seedSalt: draft.seedSalt,
    fallbackRuleId: draft.fallbackRuleId,
  );
  final presets = _upsertAllById<ProjectSmartTilePreset>(
    catalog.presets,
    <ProjectSmartTilePreset>[preset],
    (item) => item.id,
  );
  final projectedCatalog = ProjectSmartTileCatalog(
    categories: catalog.categories,
    atlases: atlases,
    materials: materials,
    animations: animations,
    presets: presets,
  );
  diagnostics.addAll(
    validateProjectSmartTileCatalog(
      catalog: projectedCatalog,
      projectTilesetIds: projectTilesetIds,
    ),
  );

  final coverage = analyzeSmartTileCoverage(
    preset: preset,
    materials: materials,
    atlases: atlases,
    animations: animations,
  );
  final uniqueDiagnostics = _uniqueDiagnostics(diagnostics);
  if (uniqueDiagnostics.any((diagnostic) => diagnostic.isError)) {
    return SmartTileDraftCompilationFailure(
      diagnostics: uniqueDiagnostics,
    );
  }

  return SmartTileDraftCompilationSuccess(
    preset: preset,
    atlases: atlases,
    materials: materials,
    animations: animations,
    coverage: coverage,
    diagnostics: uniqueDiagnostics,
  );
}

SmartTileDiagnostic _draftError({
  required String code,
  required String path,
  required String message,
}) {
  return SmartTileDiagnostic(
    code: code,
    severity: SmartTileDiagnosticSeverity.error,
    path: path,
    message: message,
  );
}

List<T> _upsertAllById<T>(
  Iterable<T> existing,
  Iterable<T> incoming,
  String Function(T item) idOf,
) {
  final result = existing.toList(growable: true);
  for (final item in incoming) {
    final index =
        result.indexWhere((candidate) => idOf(candidate) == idOf(item));
    if (index < 0) {
      result.add(item);
    } else {
      result[index] = item;
    }
  }
  return List<T>.unmodifiable(result);
}

List<SmartTileDiagnostic> _uniqueDiagnostics(
  Iterable<SmartTileDiagnostic> diagnostics,
) {
  final seen = <String>{};
  return List<SmartTileDiagnostic>.unmodifiable(
    diagnostics.where(
      (diagnostic) => seen.add(
        '${diagnostic.severity.name}|${diagnostic.code}|${diagnostic.path}|'
        '${diagnostic.presetId}|${diagnostic.ruleId}|${diagnostic.mask}',
      ),
    ),
  );
}
