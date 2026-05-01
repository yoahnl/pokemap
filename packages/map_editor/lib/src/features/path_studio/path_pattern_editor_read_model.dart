import 'package:map_core/map_core.dart';

import 'path_pattern_diagnostics.dart';

enum PathPatternPresetReadinessStatus {
  ready,
  needsReview,
  blocked,
}

typedef PathPatternPresetIssueCode = PathPatternDiagnosticCode;

final class PathPatternEditorReadModel {
  PathPatternEditorReadModel({
    required this.summary,
    required List<PathPatternPresetCardModel> presets,
  }) : presets = List<PathPatternPresetCardModel>.unmodifiable(presets);

  final PathPatternEditorSummary summary;
  final List<PathPatternPresetCardModel> presets;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathPatternEditorReadModel &&
            summary == other.summary &&
            _listEquals(presets, other.presets);
  }

  @override
  int get hashCode => Object.hash(summary, Object.hashAll(presets));
}

final class PathPatternEditorSummary {
  const PathPatternEditorSummary({
    required this.totalCount,
    required this.readyCount,
    required this.needsReviewCount,
    required this.blockedCount,
    required this.issueCount,
    required this.warningCount,
    required this.blockingCount,
    required this.ambiguousCount,
    required this.multiCellCenterCount,
    required this.transparentColorCount,
    required this.missingBasePathPresetCount,
    required this.duplicatePathPatternIdCount,
    required this.duplicateBasePathPresetIdCount,
  });

  final int totalCount;
  final int readyCount;
  final int needsReviewCount;
  final int blockedCount;
  final int issueCount;
  final int warningCount;
  final int blockingCount;
  final int ambiguousCount;
  final int multiCellCenterCount;
  final int transparentColorCount;
  final int missingBasePathPresetCount;
  final int duplicatePathPatternIdCount;
  final int duplicateBasePathPresetIdCount;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathPatternEditorSummary &&
            totalCount == other.totalCount &&
            readyCount == other.readyCount &&
            needsReviewCount == other.needsReviewCount &&
            blockedCount == other.blockedCount &&
            issueCount == other.issueCount &&
            warningCount == other.warningCount &&
            blockingCount == other.blockingCount &&
            ambiguousCount == other.ambiguousCount &&
            multiCellCenterCount == other.multiCellCenterCount &&
            transparentColorCount == other.transparentColorCount &&
            missingBasePathPresetCount == other.missingBasePathPresetCount &&
            duplicatePathPatternIdCount == other.duplicatePathPatternIdCount &&
            duplicateBasePathPresetIdCount ==
                other.duplicateBasePathPresetIdCount;
  }

  @override
  int get hashCode => Object.hash(
        totalCount,
        readyCount,
        needsReviewCount,
        blockedCount,
        issueCount,
        warningCount,
        blockingCount,
        ambiguousCount,
        multiCellCenterCount,
        transparentColorCount,
        missingBasePathPresetCount,
        duplicatePathPatternIdCount,
        duplicateBasePathPresetIdCount,
      );
}

final class PathPatternPresetCardModel {
  PathPatternPresetCardModel({
    required this.id,
    required this.name,
    required this.basePathPresetId,
    required this.basePathPresetName,
    required this.basePathSurfaceKindLabel,
    required this.centerPatternLabel,
    required this.centerWidth,
    required this.centerHeight,
    required this.centerCellCount,
    required this.centerFrameCount,
    required this.animatedCellCount,
    required this.transparentColorHex,
    required this.status,
    required List<PathPatternDiagnostic> diagnostics,
  }) : diagnostics = List<PathPatternDiagnostic>.unmodifiable(diagnostics);

  final String id;
  final String name;
  final String basePathPresetId;
  final String? basePathPresetName;
  final String? basePathSurfaceKindLabel;
  final String centerPatternLabel;
  final int centerWidth;
  final int centerHeight;
  final int centerCellCount;
  final int centerFrameCount;
  final int animatedCellCount;
  final String? transparentColorHex;
  final PathPatternPresetReadinessStatus status;
  final List<PathPatternDiagnostic> diagnostics;
  List<PathPatternDiagnosticCode> get issues =>
      diagnostics.map((diagnostic) => diagnostic.code).toList(growable: false);
  bool get hasBlockingDiagnostics => diagnostics
      .any((d) => d.severity == PathPatternDiagnosticSeverity.blocking);
  int get warningCount => diagnostics
      .where((d) => d.severity == PathPatternDiagnosticSeverity.warning)
      .length;
  int get infoCount => diagnostics
      .where((d) => d.severity == PathPatternDiagnosticSeverity.info)
      .length;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathPatternPresetCardModel &&
            id == other.id &&
            name == other.name &&
            basePathPresetId == other.basePathPresetId &&
            basePathPresetName == other.basePathPresetName &&
            basePathSurfaceKindLabel == other.basePathSurfaceKindLabel &&
            centerPatternLabel == other.centerPatternLabel &&
            centerWidth == other.centerWidth &&
            centerHeight == other.centerHeight &&
            centerCellCount == other.centerCellCount &&
            centerFrameCount == other.centerFrameCount &&
            animatedCellCount == other.animatedCellCount &&
            transparentColorHex == other.transparentColorHex &&
            status == other.status &&
            _listEquals(diagnostics, other.diagnostics);
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        basePathPresetId,
        basePathPresetName,
        basePathSurfaceKindLabel,
        centerPatternLabel,
        centerWidth,
        centerHeight,
        centerCellCount,
        centerFrameCount,
        animatedCellCount,
        transparentColorHex,
        status,
        Object.hashAll(diagnostics),
      );
}

PathPatternEditorReadModel createPathPatternEditorReadModel({
  required ProjectManifest manifest,
}) {
  final pathPatternPresets = readProjectPathPatternPresets(manifest);
  final pathPatternIdCounts = _countPathPatternPresetIds(pathPatternPresets);
  final pathPatternBaseCounts =
      _countPathPatternPresetBaseIds(pathPatternPresets);
  final basePathPresetsById = _indexBasePathPresets(manifest.pathPresets);
  final knownTilesetIds = manifest.tilesets
      .map((tileset) => tileset.id.trim())
      .where((id) => id.isNotEmpty)
      .toSet();

  final cards = <PathPatternPresetCardModel>[];
  for (final preset in pathPatternPresets) {
    final diagnostics = <PathPatternDiagnostic>[];
    int? missingVariantCount;
    bool hasCrossVariant = false;

    ProjectPathPreset? basePathPreset;
    final basePathMatches = basePathPresetsById[preset.basePathPresetId];
    if (basePathMatches == null || basePathMatches.isEmpty) {
      diagnostics.add(
        PathPatternDiagnostic(
          code: PathPatternDiagnosticCode.missingBasePathPreset,
          severity: PathPatternDiagnosticSeverity.blocking,
          title: 'Base path introuvable',
          description:
              'Ce PathPattern référence "${preset.basePathPresetId}", mais aucun ProjectPathPreset correspondant n\'existe.',
          suggestion:
              'Corrigez le basePathPresetId ou créez le path preset de base.',
          relatedId: preset.basePathPresetId,
        ),
      );
    } else if (basePathMatches.length > 1) {
      diagnostics.add(
        PathPatternDiagnostic(
          code: PathPatternDiagnosticCode.duplicateBasePathPresetId,
          severity: PathPatternDiagnosticSeverity.blocking,
          title: 'Base path ambiguë',
          description:
              'Plusieurs ProjectPathPreset partagent l\'id "${preset.basePathPresetId}".',
          suggestion:
              'Conservez un seul preset pour cet id afin d\'éviter une association ambiguë.',
          relatedId: preset.basePathPresetId,
        ),
      );
    } else {
      basePathPreset = basePathMatches.single;
      missingVariantCount = _missingNonCrossVariantCount(basePathPreset);
      hasCrossVariant = _hasCrossVariant(basePathPreset);
    }

    if ((pathPatternIdCounts[preset.id] ?? 0) > 1) {
      diagnostics.add(
        PathPatternDiagnostic(
          code: PathPatternDiagnosticCode.duplicatePathPatternId,
          severity: PathPatternDiagnosticSeverity.blocking,
          title: 'ID PathPattern dupliqué',
          description:
              'Plusieurs PathPatterns partagent exactement l\'id "${preset.id}".',
          suggestion: 'Renommez les presets pour garantir un id unique.',
          relatedId: preset.id,
        ),
      );
    }

    if ((pathPatternBaseCounts[preset.basePathPresetId] ?? 0) > 1) {
      diagnostics.add(
        PathPatternDiagnostic(
          code: PathPatternDiagnosticCode.duplicatePathPatternForBase,
          severity: PathPatternDiagnosticSeverity.blocking,
          title: 'Association ambiguë',
          description:
              'Plusieurs PathPatterns référencent "${preset.basePathPresetId}". Le rendu utilise le fallback legacy pour éviter un choix arbitraire.',
          suggestion: 'Gardez un seul PathPattern par basePathPresetId.',
          relatedId: preset.basePathPresetId,
        ),
      );
      diagnostics.add(
        PathPatternDiagnostic(
          code: PathPatternDiagnosticCode.pathPatternRenderAmbiguous,
          severity: PathPatternDiagnosticSeverity.info,
          title: 'Fallback legacy attendu',
          description:
              'Tant que l\'association reste ambiguë, le rendu PathPattern ne sera pas utilisé.',
          relatedId: preset.basePathPresetId,
        ),
      );
    }

    if (preset.centerPattern.cells.isEmpty) {
      diagnostics.add(
        const PathPatternDiagnostic(
          code: PathPatternDiagnosticCode.centerPatternEmpty,
          severity: PathPatternDiagnosticSeverity.blocking,
          title: 'Center pattern vide',
          description:
              'Le motif central ne contient aucune cellule; aucun rendu PathPattern fiable n\'est possible.',
          suggestion: 'Ajoutez au moins une cellule dans centerPattern.',
        ),
      );
    }
    final emptyCells =
        preset.centerPattern.cells.where((cell) => cell.frames.isEmpty);
    for (final cell in emptyCells) {
      diagnostics.add(
        PathPatternDiagnostic(
          code: PathPatternDiagnosticCode.cellWithoutFrames,
          severity: PathPatternDiagnosticSeverity.blocking,
          title: 'Cellule sans frame',
          description:
              'La cellule (${cell.localX},${cell.localY}) ne contient aucune frame.',
          suggestion: 'Ajoutez au moins une frame pour cette cellule.',
        ),
      );
    }

    if (basePathPreset != null) {
      final baseTilesetId = basePathPreset.tilesetId.trim();
      if (baseTilesetId.isNotEmpty &&
          !knownTilesetIds.contains(baseTilesetId)) {
        diagnostics.add(
          PathPatternDiagnostic(
            code: PathPatternDiagnosticCode.missingBaseTileset,
            severity: PathPatternDiagnosticSeverity.blocking,
            title: 'Tileset de base introuvable',
            description:
                'Le tileset "${basePathPreset.tilesetId}" du path preset de base est absent du manifest.',
            suggestion: 'Rattachez un tileset existant au path preset de base.',
            relatedId: basePathPreset.tilesetId,
          ),
        );
      }
    }

    final missingFrameTilesetIds = <String>{};
    for (final cell in preset.centerPattern.cells) {
      for (final frame in cell.frames) {
        final frameTilesetId = frame.tilesetId.trim();
        if (frameTilesetId.isEmpty) {
          continue;
        }
        if (!knownTilesetIds.contains(frameTilesetId)) {
          missingFrameTilesetIds.add(frameTilesetId);
        }
      }
    }
    for (final tilesetId in missingFrameTilesetIds) {
      diagnostics.add(
        PathPatternDiagnostic(
          code: PathPatternDiagnosticCode.missingFrameTileset,
          severity: PathPatternDiagnosticSeverity.blocking,
          title: 'Tileset de frame introuvable',
          description:
              'Une frame du centerPattern référence "$tilesetId", absent du manifest.',
          suggestion:
              'Ajoutez ce tileset au projet ou retirez l\'override tilesetId.',
          relatedId: tilesetId,
        ),
      );
    }

    if (missingVariantCount == TerrainPathVariant.values.length - 1) {
      diagnostics.add(
        const PathPatternDiagnostic(
          code: PathPatternDiagnosticCode.noVariantCoverage,
          severity: PathPatternDiagnosticSeverity.warning,
          title: 'Aucun variant legacy configuré',
          description:
              'Le rendu utilisera le centerPattern pour tous les cas de jonction.',
          suggestion:
              'Ajoutez des variants si vous avez besoin de bords spécifiques.',
        ),
      );
      diagnostics.add(
        const PathPatternDiagnostic(
          code: PathPatternDiagnosticCode.centerOnly,
          severity: PathPatternDiagnosticSeverity.info,
          title: 'Mode centre uniquement',
          description:
              'Ce preset est center-only: le motif central est appliqué partout.',
        ),
      );
    } else if ((missingVariantCount ?? 0) > 0) {
      diagnostics.add(
        PathPatternDiagnostic(
          code: PathPatternDiagnosticCode.partialVariantCoverage,
          severity: PathPatternDiagnosticSeverity.warning,
          title: 'Variants partiels',
          description:
              '${missingVariantCount ?? 0} variants legacy manquent; les cas non couverts utiliseront le centerPattern.',
          suggestion:
              'Complétez les variants requis pour réduire les fallbacks centerPattern.',
        ),
      );
    }

    if (hasCrossVariant) {
      diagnostics.add(
        const PathPatternDiagnostic(
          code: PathPatternDiagnosticCode.crossHandledByCenterPattern,
          severity: PathPatternDiagnosticSeverity.info,
          title: 'Cross géré par centerPattern',
          description:
              'Le mapping legacy cross est ignoré en mode PathPattern; le centerPattern reste utilisé.',
        ),
      );
    }

    diagnostics.add(
      PathPatternDiagnostic(
        code: PathPatternDiagnosticCode.centerPatternStats,
        severity: PathPatternDiagnosticSeverity.info,
        title: 'Résumé centerPattern',
        description:
            '${preset.centerPattern.size.width}×${preset.centerPattern.size.height}, ${preset.centerPattern.cells.length} cellules, ${_centerFrameCount(preset.centerPattern)} frames.',
      ),
    );

    cards.add(
      PathPatternPresetCardModel(
        id: preset.id,
        name: preset.name,
        basePathPresetId: preset.basePathPresetId,
        basePathPresetName: basePathPreset?.name,
        basePathSurfaceKindLabel: basePathPreset == null
            ? null
            : _pathSurfaceKindLabel(basePathPreset.surfaceKind),
        centerPatternLabel: _centerPatternLabel(preset.centerPattern),
        centerWidth: preset.centerPattern.size.width,
        centerHeight: preset.centerPattern.size.height,
        centerCellCount: preset.centerPattern.cells.length,
        centerFrameCount: _centerFrameCount(preset.centerPattern),
        animatedCellCount: _animatedCellCount(preset.centerPattern),
        transparentColorHex: preset.transparentColor?.toHexRgb(),
        status: _statusForDiagnostics(diagnostics),
        diagnostics: diagnostics,
      ),
    );
  }

  return PathPatternEditorReadModel(
    summary: _summaryForCards(cards),
    presets: cards,
  );
}

Map<String, int> _countPathPatternPresetBaseIds(
  List<ProjectPathPatternPreset> presets,
) {
  final counts = <String, int>{};
  for (final preset in presets) {
    counts[preset.basePathPresetId] =
        (counts[preset.basePathPresetId] ?? 0) + 1;
  }
  return counts;
}

Map<String, int> _countPathPatternPresetIds(
  List<ProjectPathPatternPreset> presets,
) {
  final counts = <String, int>{};
  for (final preset in presets) {
    counts[preset.id] = (counts[preset.id] ?? 0) + 1;
  }
  return counts;
}

Map<String, List<ProjectPathPreset>> _indexBasePathPresets(
  List<ProjectPathPreset> presets,
) {
  final byId = <String, List<ProjectPathPreset>>{};
  for (final preset in presets) {
    byId.putIfAbsent(preset.id, () => []).add(preset);
  }
  return byId;
}

String _centerPatternLabel(PathCenterPattern pattern) {
  return '${pattern.size.width}×${pattern.size.height}';
}

int _centerFrameCount(PathCenterPattern pattern) {
  return pattern.cells.fold(
    0,
    (total, cell) => total + cell.frames.length,
  );
}

int _animatedCellCount(PathCenterPattern pattern) {
  return pattern.cells.where((cell) => cell.frames.length > 1).length;
}

PathPatternPresetReadinessStatus _statusForDiagnostics(
  List<PathPatternDiagnostic> diagnostics,
) {
  if (diagnostics.any(
    (d) => d.severity == PathPatternDiagnosticSeverity.blocking,
  )) {
    return PathPatternPresetReadinessStatus.blocked;
  }
  if (diagnostics.any(
    (d) => d.severity == PathPatternDiagnosticSeverity.warning,
  )) {
    return PathPatternPresetReadinessStatus.needsReview;
  }
  return PathPatternPresetReadinessStatus.ready;
}

int _missingNonCrossVariantCount(ProjectPathPreset preset) {
  final configured = {
    for (final variant in preset.variants) variant.variant,
  };
  final expected = TerrainPathVariant.values
      .where((variant) => variant != TerrainPathVariant.cross);
  return expected.where((variant) => !configured.contains(variant)).length;
}

bool _hasCrossVariant(ProjectPathPreset preset) {
  return preset.variants.any(
    (variant) => variant.variant == TerrainPathVariant.cross,
  );
}

PathPatternEditorSummary _summaryForCards(
  List<PathPatternPresetCardModel> cards,
) {
  return PathPatternEditorSummary(
    totalCount: cards.length,
    readyCount: cards
        .where((card) => card.status == PathPatternPresetReadinessStatus.ready)
        .length,
    needsReviewCount: cards
        .where(
          (card) => card.status == PathPatternPresetReadinessStatus.needsReview,
        )
        .length,
    blockedCount: cards
        .where(
            (card) => card.status == PathPatternPresetReadinessStatus.blocked)
        .length,
    issueCount: cards
        .where(
          (card) =>
              card.status == PathPatternPresetReadinessStatus.blocked ||
              card.status == PathPatternPresetReadinessStatus.needsReview,
        )
        .length,
    warningCount:
        cards.fold<int>(0, (total, card) => total + card.warningCount),
    blockingCount: cards.fold<int>(
      0,
      (total, card) =>
          total +
          card.diagnostics
              .where(
                (diagnostic) =>
                    diagnostic.severity ==
                    PathPatternDiagnosticSeverity.blocking,
              )
              .length,
    ),
    ambiguousCount: cards
        .where(
          (card) => card.issues.contains(
            PathPatternDiagnosticCode.duplicatePathPatternForBase,
          ),
        )
        .length,
    multiCellCenterCount: cards
        .where((card) => card.centerWidth > 1 || card.centerHeight > 1)
        .length,
    transparentColorCount:
        cards.where((card) => card.transparentColorHex != null).length,
    missingBasePathPresetCount: cards
        .where(
          (card) => card.issues.contains(
            PathPatternDiagnosticCode.missingBasePathPreset,
          ),
        )
        .length,
    duplicatePathPatternIdCount: cards
        .where(
          (card) => card.issues.contains(
            PathPatternDiagnosticCode.duplicatePathPatternId,
          ),
        )
        .length,
    duplicateBasePathPresetIdCount: cards
        .where(
          (card) => card.issues.contains(
            PathPatternDiagnosticCode.duplicateBasePathPresetId,
          ),
        )
        .length,
  );
}

String _pathSurfaceKindLabel(PathSurfaceKind surfaceKind) {
  return switch (surfaceKind) {
    PathSurfaceKind.path => 'Chemin',
    PathSurfaceKind.road => 'Route',
    PathSurfaceKind.water => 'Eau',
    PathSurfaceKind.tallGrass => 'Hautes herbes',
    PathSurfaceKind.ice => 'Glace',
    PathSurfaceKind.lava => 'Lave',
    PathSurfaceKind.swamp => 'Marais',
    PathSurfaceKind.rails => 'Rails',
    PathSurfaceKind.bridge => 'Pont',
    PathSurfaceKind.special => 'Spécial',
    PathSurfaceKind.custom => 'Personnalisé',
  };
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i += 1) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}
