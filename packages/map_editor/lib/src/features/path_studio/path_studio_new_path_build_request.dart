import 'package:map_core/map_core.dart';

import 'path_studio_new_path_draft.dart';
import 'path_studio_save_plan.dart';

enum PathStudioNewPathBuildIssueSeverity {
  blocking,
  warning,
}

enum PathStudioNewPathBuildIssueCode {
  nameRequired,
  tilesetRequired,
  centerCellsRequired,
  duplicateBasePathPresetId,
  duplicatePathPatternPresetId,
  noVariantMappingsConfigured,
  partialVariantCoverage,
  crossHandledByCenterPattern,
  projectPathPresetModelConstraint,
}

final class PathStudioNewPathBuildIssue {
  const PathStudioNewPathBuildIssue({
    required this.code,
    required this.severity,
    required this.title,
    required this.description,
  });

  final PathStudioNewPathBuildIssueCode code;
  final PathStudioNewPathBuildIssueSeverity severity;
  final String title;
  final String description;
}

final class PathStudioNewPathBuildRequest {
  const PathStudioNewPathBuildRequest({
    required this.basePathPreset,
    required this.pathPatternPreset,
    required this.configuredVariants,
    required this.missingVariants,
    required this.warnings,
  });

  final ProjectPathPreset basePathPreset;
  final ProjectPathPatternPreset pathPatternPreset;
  final List<TerrainPathVariant> configuredVariants;
  final List<TerrainPathVariant> missingVariants;
  final List<PathStudioNewPathBuildIssue> warnings;
}

final class PathStudioNewPathBuildPlan {
  const PathStudioNewPathBuildPlan({
    required this.proposedBasePathPresetId,
    required this.proposedPathPatternPresetId,
    required this.blockingIssues,
    required this.warnings,
    required this.canBuildRequest,
    required this.canPersistNow,
    required this.configuredVariantCount,
    required this.missingVariantCount,
    required this.requiredVariantCount,
    required this.configuredVariants,
    required this.missingVariants,
    required this.centerReady,
    required this.variantsCoverageLabel,
    required this.surfaceKind,
    required this.buildRequest,
  });

  final String proposedBasePathPresetId;
  final String proposedPathPatternPresetId;
  final List<PathStudioNewPathBuildIssue> blockingIssues;
  final List<PathStudioNewPathBuildIssue> warnings;
  final bool canBuildRequest;
  final bool canPersistNow;
  final int configuredVariantCount;
  final int missingVariantCount;
  final int requiredVariantCount;
  final List<TerrainPathVariant> configuredVariants;
  final List<TerrainPathVariant> missingVariants;
  final bool centerReady;
  final String variantsCoverageLabel;
  final PathSurfaceKind surfaceKind;
  final PathStudioNewPathBuildRequest? buildRequest;
}

PathStudioNewPathBuildPlan createPathStudioNewPathBuildPlan({
  required ProjectManifest manifest,
  required PathStudioNewPathDraft draft,
}) {
  final proposedBasePathPresetId = pathStudioSlugifyId(draft.name);
  final proposedPathPatternPresetId = '$proposedBasePathPresetId-pattern';
  final configuredVariants = <TerrainPathVariant>[
    for (final variant in PathStudioNewPathDraft.requiredVariants)
      if (draft.variantCellFrames[variant]?.isNotEmpty ?? false) variant,
  ];
  final missingVariants = <TerrainPathVariant>[
    for (final variant in PathStudioNewPathDraft.requiredVariants)
      if (draft.variantCellFrames[variant]?.isEmpty ?? true) variant,
  ];

  final blockingIssues = <PathStudioNewPathBuildIssue>[];
  if (draft.name.trim().isEmpty) {
    blockingIssues.add(
      const PathStudioNewPathBuildIssue(
        code: PathStudioNewPathBuildIssueCode.nameRequired,
        severity: PathStudioNewPathBuildIssueSeverity.blocking,
        title: 'Nom requis',
        description:
            'Le nom du brouillon est requis pour préparer une requête locale.',
      ),
    );
  }
  if (draft.tilesetId == null || draft.tilesetId!.isEmpty) {
    blockingIssues.add(
      const PathStudioNewPathBuildIssue(
        code: PathStudioNewPathBuildIssueCode.tilesetRequired,
        severity: PathStudioNewPathBuildIssueSeverity.blocking,
        title: 'Tileset requis',
        description:
            'Sélectionnez un tileset projet avant de préparer la requête locale.',
      ),
    );
  }
  if (!draft.allCenterCellsConfigured) {
    blockingIssues.add(
      const PathStudioNewPathBuildIssue(
        code: PathStudioNewPathBuildIssueCode.centerCellsRequired,
        severity: PathStudioNewPathBuildIssueSeverity.blocking,
        title: 'Centre incomplet',
        description:
            'Toutes les cellules du centre doivent être configurées pour construire la requête locale.',
      ),
    );
  }
  if (_hasPathPresetId(manifest, proposedBasePathPresetId)) {
    blockingIssues.add(
      const PathStudioNewPathBuildIssue(
        code: PathStudioNewPathBuildIssueCode.duplicateBasePathPresetId,
        severity: PathStudioNewPathBuildIssueSeverity.blocking,
        title: 'ID base path déjà utilisé',
        description:
            'L’identifiant proposé pour le ProjectPathPreset existe déjà dans le manifest.',
      ),
    );
  }
  if (_hasPathPatternId(manifest, proposedPathPatternPresetId)) {
    blockingIssues.add(
      const PathStudioNewPathBuildIssue(
        code: PathStudioNewPathBuildIssueCode.duplicatePathPatternPresetId,
        severity: PathStudioNewPathBuildIssueSeverity.blocking,
        title: 'ID path pattern déjà utilisé',
        description:
            'L’identifiant proposé pour le ProjectPathPatternPreset existe déjà dans le manifest.',
      ),
    );
  }

  final warnings = <PathStudioNewPathBuildIssue>[
    const PathStudioNewPathBuildIssue(
      code: PathStudioNewPathBuildIssueCode.crossHandledByCenterPattern,
      severity: PathStudioNewPathBuildIssueSeverity.warning,
      title: 'Variant cross géré par le centre',
      description:
          'TerrainPathVariant.cross n’est pas mappé ici: le centre est porté par centerPattern.',
    ),
  ];
  if (configuredVariants.isEmpty) {
    warnings.add(
      const PathStudioNewPathBuildIssue(
        code: PathStudioNewPathBuildIssueCode.noVariantMappingsConfigured,
        severity: PathStudioNewPathBuildIssueSeverity.warning,
        title: 'Aucun variant legacy configuré',
        description:
            'Le centre est prêt mais aucun bord, coin ou jonction n’est configuré.',
      ),
    );
  } else if (missingVariants.isNotEmpty) {
    warnings.add(
      const PathStudioNewPathBuildIssue(
        code: PathStudioNewPathBuildIssueCode.partialVariantCoverage,
        severity: PathStudioNewPathBuildIssueSeverity.warning,
        title: 'Couverture partielle des variants',
        description:
            'Certains variants legacy manquent: ce n’est pas bloquant pour la requête locale.',
      ),
    );
  }

  final centerPattern = createPathCenterPatternFromNewPathDraft(draft);
  PathStudioNewPathBuildRequest? buildRequest;
  if (blockingIssues.isEmpty && centerPattern != null) {
    try {
      final variants = <PathPresetVariantMapping>[
        for (final variant in configuredVariants)
          PathPresetVariantMapping(
            variant: variant,
            frames: [
              for (final f in draft.variantCellFrames[variant] ?? const <PathStudioNewPathDraftCenterFrame>[])
                f.toFrame(),
            ],
          ),
      ];
      final basePathPreset = ProjectPathPreset(
        id: proposedBasePathPresetId,
        name: draft.name.trim(),
        tilesetId: draft.tilesetId!,
        surfaceKind: draft.surfaceKind,
        variants: variants,
      );
      final pathPatternPreset = ProjectPathPatternPreset(
        id: proposedPathPatternPresetId,
        name: draft.name.trim(),
        basePathPresetId: proposedBasePathPresetId,
        centerPattern: centerPattern,
        sortOrder: manifest.pathPatternPresets.length,
      );
      buildRequest = PathStudioNewPathBuildRequest(
        basePathPreset: basePathPreset,
        pathPatternPreset: pathPatternPreset,
        configuredVariants: List<TerrainPathVariant>.unmodifiable(
          configuredVariants,
        ),
        missingVariants: List<TerrainPathVariant>.unmodifiable(missingVariants),
        warnings: List<PathStudioNewPathBuildIssue>.unmodifiable(warnings),
      );
    } catch (_) {
      blockingIssues.add(
        const PathStudioNewPathBuildIssue(
          code: PathStudioNewPathBuildIssueCode.projectPathPresetModelConstraint,
          severity: PathStudioNewPathBuildIssueSeverity.blocking,
          title: 'Contrainte du modèle ProjectPathPreset',
          description:
              'La requête locale ne peut pas être construite avec l’état actuel du brouillon.',
        ),
      );
    }
  }

  final coverageLabel = configuredVariants.isEmpty
      ? 'vide'
      : missingVariants.isEmpty
          ? 'complète'
          : 'partielle';
  return PathStudioNewPathBuildPlan(
    proposedBasePathPresetId: proposedBasePathPresetId,
    proposedPathPatternPresetId: proposedPathPatternPresetId,
    blockingIssues: List<PathStudioNewPathBuildIssue>.unmodifiable(
      blockingIssues,
    ),
    warnings: List<PathStudioNewPathBuildIssue>.unmodifiable(warnings),
    canBuildRequest: blockingIssues.isEmpty && buildRequest != null,
    canPersistNow: false,
    configuredVariantCount: configuredVariants.length,
    missingVariantCount: missingVariants.length,
    requiredVariantCount: PathStudioNewPathDraft.requiredVariants.length,
    configuredVariants: List<TerrainPathVariant>.unmodifiable(configuredVariants),
    missingVariants: List<TerrainPathVariant>.unmodifiable(missingVariants),
    centerReady: centerPattern != null,
    variantsCoverageLabel: coverageLabel,
    surfaceKind: draft.surfaceKind,
    buildRequest: buildRequest,
  );
}

bool _hasPathPatternId(ProjectManifest manifest, String id) {
  return manifest.pathPatternPresets.any((preset) => preset.id == id);
}

bool _hasPathPresetId(ProjectManifest manifest, String id) {
  return manifest.pathPresets.any((preset) => preset.id == id);
}
