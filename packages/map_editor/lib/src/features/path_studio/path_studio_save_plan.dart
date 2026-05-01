import 'package:map_core/map_core.dart';

import 'path_pattern_draft.dart';
import 'path_studio_new_path_draft.dart';

enum PathStudioSaveFlowKind {
  newPath,
  legacyPathPattern,
}

enum PathStudioSaveIssueCode {
  nameRequired,
  tilesetRequired,
  centerCellsRequired,
  basePathPresetRequired,
  pathVariantMappingRequired,
  duplicatePathPatternId,
}

final class PathStudioSaveReadiness {
  PathStudioSaveReadiness({
    required this.kind,
    required this.canSaveNow,
    required List<PathStudioSaveIssueCode> issues,
  }) : issues = List<PathStudioSaveIssueCode>.unmodifiable(issues);

  final PathStudioSaveFlowKind kind;
  final bool canSaveNow;
  final List<PathStudioSaveIssueCode> issues;
}

final class PathStudioNewPathSavePlan {
  PathStudioNewPathSavePlan({
    required this.name,
    required this.proposedBasePathPresetId,
    required this.proposedPathPatternPresetId,
    required this.centerWidth,
    required this.centerHeight,
    required this.configuredCellCount,
    required this.centerCellCount,
    required this.configuredVariantCount,
    required this.requiredVariantCount,
    required List<PathStudioSaveIssueCode> issues,
    required this.centerPattern,
  }) : issues = List<PathStudioSaveIssueCode>.unmodifiable(issues);

  final String name;
  final String proposedBasePathPresetId;
  final String proposedPathPatternPresetId;
  final int centerWidth;
  final int centerHeight;
  final int configuredCellCount;
  final int centerCellCount;
  final int configuredVariantCount;
  final int requiredVariantCount;
  final List<PathStudioSaveIssueCode> issues;
  final PathCenterPattern? centerPattern;

  PathStudioSaveFlowKind get kind => PathStudioSaveFlowKind.newPath;

  bool get canSaveNow => false;

  bool get isCenterReady => centerPattern != null;

  bool get variantsReady => configuredVariantCount == requiredVariantCount;

  PathStudioSaveReadiness get readiness => PathStudioSaveReadiness(
        kind: kind,
        canSaveNow: canSaveNow,
        issues: issues,
      );
}

final class PathStudioLegacyPathPatternSaveRequest {
  const PathStudioLegacyPathPatternSaveRequest({required this.preset});

  final ProjectPathPatternPreset preset;
}

final class PathStudioLegacyPathPatternSavePlan {
  PathStudioLegacyPathPatternSavePlan({
    required this.name,
    required this.proposedPathPatternPresetId,
    required this.basePathPresetId,
    required List<PathStudioSaveIssueCode> issues,
    required this.request,
  }) : issues = List<PathStudioSaveIssueCode>.unmodifiable(issues);

  final String name;
  final String proposedPathPatternPresetId;
  final String basePathPresetId;
  final List<PathStudioSaveIssueCode> issues;
  final PathStudioLegacyPathPatternSaveRequest? request;

  PathStudioSaveFlowKind get kind => PathStudioSaveFlowKind.legacyPathPattern;

  bool get canSaveNow => request != null && issues.isEmpty;

  PathStudioSaveReadiness get readiness => PathStudioSaveReadiness(
        kind: kind,
        canSaveNow: canSaveNow,
        issues: issues,
      );
}

String pathStudioSlugifyId(String input) {
  final normalized = input.trim().toLowerCase();
  final replaced = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  final collapsed = replaced.replaceAll(RegExp(r'-+'), '-');
  final trimmed = collapsed.replaceAll(RegExp(r'^-+|-+$'), '');
  return trimmed.isEmpty ? 'path-pattern' : trimmed;
}

PathStudioNewPathSavePlan createPathStudioNewPathSavePlan({
  required ProjectManifest manifest,
  required PathStudioNewPathDraft draft,
}) {
  final baseId = pathStudioSlugifyId(draft.name);
  final patternId = '$baseId-pattern';
  final issues = <PathStudioSaveIssueCode>[];
  if (draft.name.trim().isEmpty) {
    issues.add(PathStudioSaveIssueCode.nameRequired);
  }
  if (draft.tilesetId == null || draft.tilesetId!.isEmpty) {
    issues.add(PathStudioSaveIssueCode.tilesetRequired);
  }
  if (!draft.allCenterCellsConfigured) {
    issues.add(PathStudioSaveIssueCode.centerCellsRequired);
  }
  if (!draft.allRequiredVariantsConfigured) {
    issues.add(PathStudioSaveIssueCode.pathVariantMappingRequired);
  }
  if (_hasPathPatternId(manifest, patternId) ||
      _hasPathPresetId(manifest, baseId)) {
    issues.add(PathStudioSaveIssueCode.duplicatePathPatternId);
  }

  return PathStudioNewPathSavePlan(
    name: draft.name.trim(),
    proposedBasePathPresetId: baseId,
    proposedPathPatternPresetId: patternId,
    centerWidth: draft.centerWidth,
    centerHeight: draft.centerHeight,
    configuredCellCount: draft.configuredCellCount,
    centerCellCount: draft.centerCellCount,
    configuredVariantCount: draft.configuredVariantCount,
    requiredVariantCount: draft.requiredVariantCount,
    issues: issues,
    centerPattern: createPathCenterPatternFromNewPathDraft(draft),
  );
}

PathStudioLegacyPathPatternSavePlan createPathStudioLegacyPathPatternSavePlan({
  required ProjectManifest manifest,
  required PathPatternDraft draft,
}) {
  final patternId = pathStudioSlugifyId(draft.name);
  final issues = <PathStudioSaveIssueCode>[];
  if (draft.name.trim().isEmpty) {
    issues.add(PathStudioSaveIssueCode.nameRequired);
  }
  if (draft.basePathPresetId.trim().isEmpty ||
      !_hasPathPresetId(manifest, draft.basePathPresetId)) {
    issues.add(PathStudioSaveIssueCode.basePathPresetRequired);
  }
  if (_hasPathPatternId(manifest, patternId) ||
      _hasPathPresetId(manifest, patternId)) {
    issues.add(PathStudioSaveIssueCode.duplicatePathPatternId);
  }

  final request = issues.isEmpty
      ? PathStudioLegacyPathPatternSaveRequest(
          preset: ProjectPathPatternPreset(
            id: patternId,
            name: draft.name.trim(),
            basePathPresetId: draft.basePathPresetId,
            centerPattern: draft.centerPattern,
            transparentColor: draft.transparentColor,
            categoryId: draft.categoryId,
            sortOrder: draft.sortOrder,
          ),
        )
      : null;

  return PathStudioLegacyPathPatternSavePlan(
    name: draft.name.trim(),
    proposedPathPatternPresetId: patternId,
    basePathPresetId: draft.basePathPresetId,
    issues: issues,
    request: request,
  );
}

PathCenterPattern? createPathCenterPatternFromNewPathDraft(
  PathStudioNewPathDraft draft,
) {
  if (!draft.allCenterCellsConfigured) {
    return null;
  }
  return PathCenterPattern(
    size: PathCenterPatternSize(
      width: draft.centerWidth,
      height: draft.centerHeight,
    ),
    cells: [
      for (final cell in draft.cells)
        PathCenterPatternCell(
          localX: cell.localX,
          localY: cell.localY,
          frames: [cell.tile!.toFrame()],
        ),
    ],
  );
}

String pathStudioSaveIssueLabel(PathStudioSaveIssueCode issue) {
  return switch (issue) {
    PathStudioSaveIssueCode.nameRequired => 'Nom requis',
    PathStudioSaveIssueCode.tilesetRequired => 'Tileset requis',
    PathStudioSaveIssueCode.centerCellsRequired =>
      'Cellules du centre à configurer',
    PathStudioSaveIssueCode.basePathPresetRequired => 'Path de base requis',
    PathStudioSaveIssueCode.pathVariantMappingRequired =>
      'Configuration des bords à venir',
    PathStudioSaveIssueCode.duplicatePathPatternId =>
      'ID PathPattern déjà utilisé',
  };
}

String pathStudioSaveIssueDescription(PathStudioSaveIssueCode issue) {
  return switch (issue) {
    PathStudioSaveIssueCode.nameRequired =>
      'Le nom du brouillon doit être renseigné avant une préparation de sauvegarde.',
    PathStudioSaveIssueCode.tilesetRequired =>
      'Le nouveau chemin doit choisir un tileset avant de préparer ses données.',
    PathStudioSaveIssueCode.centerCellsRequired =>
      'Chaque cellule requise du centre doit recevoir une tuile.',
    PathStudioSaveIssueCode.basePathPresetRequired =>
      'Le motif legacy doit référencer un path existant du projet.',
    PathStudioSaveIssueCode.pathVariantMappingRequired =>
      'Le centre est préparé localement. La configuration des bords, coins et jonctions arrivera dans un prochain lot.',
    PathStudioSaveIssueCode.duplicatePathPatternId =>
      'L’identifiant proposé entre en collision avec un id déjà présent dans le projet.',
  };
}

bool _hasPathPatternId(ProjectManifest manifest, String id) {
  return manifest.pathPatternPresets.any((preset) => preset.id == id);
}

bool _hasPathPresetId(ProjectManifest manifest, String id) {
  return manifest.pathPresets.any((preset) => preset.id == id);
}
