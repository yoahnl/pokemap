import 'package:map_core/map_core.dart';

import 'path_studio_new_path_draft.dart';
import 'path_studio_save_plan.dart';

enum PathStudioEditPathBuildIssueCode {
  draftNotInEditMode,
  sourceIdsMissing,
  nameRequired,
  tilesetRequired,
  centerCellsRequired,
  originalBaseMissing,
  originalPatternMissing,
  duplicateBaseId,
  duplicatePatternId,
}

final class PathStudioEditPathBuildIssue {
  const PathStudioEditPathBuildIssue({
    required this.code,
    required this.title,
    required this.description,
  });

  final PathStudioEditPathBuildIssueCode code;
  final String title;
  final String description;
}

final class PathStudioEditPathBuildRequest {
  const PathStudioEditPathBuildRequest({
    required this.updatedBasePathPreset,
    required this.updatedPathPatternPreset,
    required this.originalBasePathPresetId,
    required this.originalPathPatternPresetId,
    required this.warnings,
    required this.blockingIssues,
  });

  final ProjectPathPreset updatedBasePathPreset;
  final ProjectPathPatternPreset updatedPathPatternPreset;
  final String originalBasePathPresetId;
  final String originalPathPatternPresetId;
  final List<PathStudioEditPathBuildIssue> warnings;
  final List<PathStudioEditPathBuildIssue> blockingIssues;
}

final class PathStudioEditPathBuildPlan {
  const PathStudioEditPathBuildPlan({
    required this.blockingIssues,
    required this.warnings,
    required this.canBuildRequest,
    required this.buildRequest,
  });

  final List<PathStudioEditPathBuildIssue> blockingIssues;
  final List<PathStudioEditPathBuildIssue> warnings;
  final bool canBuildRequest;
  final PathStudioEditPathBuildRequest? buildRequest;
}

PathStudioEditPathBuildPlan createPathStudioEditPathBuildPlan({
  required ProjectManifest manifest,
  required PathStudioNewPathDraft draft,
}) {
  final blocking = <PathStudioEditPathBuildIssue>[];
  final warnings = <PathStudioEditPathBuildIssue>[];
  if (!draft.isEditMode) {
    blocking.add(
      const PathStudioEditPathBuildIssue(
        code: PathStudioEditPathBuildIssueCode.draftNotInEditMode,
        title: 'Brouillon non éditable',
        description: 'Le brouillon courant n’est pas en mode modification.',
      ),
    );
  }
  final source = draft.source;
  if (source == null) {
    blocking.add(
      const PathStudioEditPathBuildIssue(
        code: PathStudioEditPathBuildIssueCode.sourceIdsMissing,
        title: 'Source d’édition manquante',
        description:
            'Les identifiants originaux sont absents pour ce brouillon.',
      ),
    );
  }
  if (draft.name.trim().isEmpty) {
    blocking.add(
      const PathStudioEditPathBuildIssue(
        code: PathStudioEditPathBuildIssueCode.nameRequired,
        title: 'Nom requis',
        description: 'Le nom du chemin est requis pour enregistrer.',
      ),
    );
  }
  if (draft.tilesetId == null || draft.tilesetId!.isEmpty) {
    blocking.add(
      const PathStudioEditPathBuildIssue(
        code: PathStudioEditPathBuildIssueCode.tilesetRequired,
        title: 'Tileset requis',
        description: 'Le tileset doit être sélectionné.',
      ),
    );
  }
  if (!draft.allCenterCellsConfigured) {
    blocking.add(
      const PathStudioEditPathBuildIssue(
        code: PathStudioEditPathBuildIssueCode.centerCellsRequired,
        title: 'Centre incomplet',
        description: 'Toutes les cellules du centre doivent être configurées.',
      ),
    );
  }
  if (source != null) {
    final originalBaseIndex = manifest.pathPresets.indexWhere(
      (preset) => preset.id == source.originalBasePathPresetId,
    );
    if (originalBaseIndex < 0) {
      blocking.add(
        const PathStudioEditPathBuildIssue(
          code: PathStudioEditPathBuildIssueCode.originalBaseMissing,
          title: 'Base path introuvable',
          description: 'Le ProjectPathPreset original est introuvable.',
        ),
      );
    }
    final originalPatternIndex = manifest.pathPatternPresets.indexWhere(
      (preset) => preset.id == source.originalPathPatternPresetId,
    );
    if (originalPatternIndex < 0) {
      blocking.add(
        const PathStudioEditPathBuildIssue(
          code: PathStudioEditPathBuildIssueCode.originalPatternMissing,
          title: 'PathPattern introuvable',
          description: 'Le ProjectPathPatternPreset original est introuvable.',
        ),
      );
    }

    final baseOwnerId = source.originalBasePathPresetId;
    if (manifest.pathPresets.any(
      (preset) =>
          preset.id == draft.basePathPresetId && preset.id != baseOwnerId,
    )) {
      blocking.add(
        const PathStudioEditPathBuildIssue(
          code: PathStudioEditPathBuildIssueCode.duplicateBaseId,
          title: 'ID base path en collision',
          description:
              'Un autre ProjectPathPreset utilise déjà cet identifiant.',
        ),
      );
    }
    final patternOwnerId = source.originalPathPatternPresetId;
    if (manifest.pathPatternPresets.any(
      (preset) =>
          preset.id == draft.pathPatternPresetId && preset.id != patternOwnerId,
    )) {
      blocking.add(
        const PathStudioEditPathBuildIssue(
          code: PathStudioEditPathBuildIssueCode.duplicatePatternId,
          title: 'ID path pattern en collision',
          description:
              'Un autre ProjectPathPatternPreset utilise déjà cet identifiant.',
        ),
      );
    }
  }

  final centerPattern = createPathCenterPatternFromNewPathDraft(draft);
  if (centerPattern == null || source == null || blocking.isNotEmpty) {
    return PathStudioEditPathBuildPlan(
      blockingIssues: List<PathStudioEditPathBuildIssue>.unmodifiable(blocking),
      warnings: List<PathStudioEditPathBuildIssue>.unmodifiable(warnings),
      canBuildRequest: false,
      buildRequest: null,
    );
  }

  final updatedVariantMappings = <PathPresetVariantMapping>[
    ...draft.preservedVariantMappings,
    for (final variant in PathStudioNewPathDraft.requiredVariants)
      if (draft.variantTiles[variant] case final tile?)
        PathPresetVariantMapping(
          variant: variant,
          frames: [tile.toFrame()],
        ),
  ];

  final updatedBase = ProjectPathPreset(
    id: draft.basePathPresetId,
    name: draft.name.trim(),
    tilesetId: draft.tilesetId!,
    surfaceKind: draft.surfaceKind,
    variants: updatedVariantMappings,
  );
  final updatedPattern = ProjectPathPatternPreset(
    id: draft.pathPatternPresetId,
    name: draft.name.trim(),
    basePathPresetId: draft.basePathPresetId,
    centerPattern: centerPattern,
  );

  return PathStudioEditPathBuildPlan(
    blockingIssues: List<PathStudioEditPathBuildIssue>.unmodifiable(blocking),
    warnings: List<PathStudioEditPathBuildIssue>.unmodifiable(warnings),
    canBuildRequest: true,
    buildRequest: PathStudioEditPathBuildRequest(
      updatedBasePathPreset: updatedBase,
      updatedPathPatternPreset: updatedPattern,
      originalBasePathPresetId: source.originalBasePathPresetId,
      originalPathPatternPresetId: source.originalPathPatternPresetId,
      warnings: List<PathStudioEditPathBuildIssue>.unmodifiable(warnings),
      blockingIssues: List<PathStudioEditPathBuildIssue>.unmodifiable(blocking),
    ),
  );
}
