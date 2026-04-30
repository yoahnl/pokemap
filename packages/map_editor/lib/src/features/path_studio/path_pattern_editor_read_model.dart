import 'package:map_core/map_core.dart';

enum PathPatternPresetReadinessStatus {
  ready,
  needsReview,
  blocked,
}

enum PathPatternPresetIssueCode {
  missingBasePathPreset,
  duplicatePathPatternId,
  duplicateBasePathPresetId,
}

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
    required this.issueCount,
    required this.multiCellCenterCount,
    required this.transparentColorCount,
    required this.missingBasePathPresetCount,
    required this.duplicatePathPatternIdCount,
    required this.duplicateBasePathPresetIdCount,
  });

  final int totalCount;
  final int readyCount;
  final int issueCount;
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
            issueCount == other.issueCount &&
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
        issueCount,
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
    required List<PathPatternPresetIssueCode> issues,
  }) : issues = List<PathPatternPresetIssueCode>.unmodifiable(issues);

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
  final List<PathPatternPresetIssueCode> issues;

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
            _listEquals(issues, other.issues);
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
        Object.hashAll(issues),
      );
}

PathPatternEditorReadModel createPathPatternEditorReadModel({
  required ProjectManifest manifest,
}) {
  final pathPatternPresets = readProjectPathPatternPresets(manifest);
  final pathPatternIdCounts = _countPathPatternPresetIds(pathPatternPresets);
  final basePathPresetsById = _indexBasePathPresets(manifest.pathPresets);

  final cards = <PathPatternPresetCardModel>[];
  for (final preset in pathPatternPresets) {
    final issues = <PathPatternPresetIssueCode>[];
    if ((pathPatternIdCounts[preset.id] ?? 0) > 1) {
      issues.add(PathPatternPresetIssueCode.duplicatePathPatternId);
    }

    ProjectPathPreset? basePathPreset;
    final basePathMatches = basePathPresetsById[preset.basePathPresetId];
    if (basePathMatches == null || basePathMatches.isEmpty) {
      issues.add(PathPatternPresetIssueCode.missingBasePathPreset);
    } else if (basePathMatches.length > 1) {
      issues.add(PathPatternPresetIssueCode.duplicateBasePathPresetId);
    } else {
      basePathPreset = basePathMatches.single;
    }

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
        status: _statusForIssues(issues),
        issues: issues,
      ),
    );
  }

  return PathPatternEditorReadModel(
    summary: _summaryForCards(cards),
    presets: cards,
  );
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

PathPatternPresetReadinessStatus _statusForIssues(
  List<PathPatternPresetIssueCode> issues,
) {
  if (issues.isEmpty) {
    return PathPatternPresetReadinessStatus.ready;
  }
  if (issues.any(_isBlockingIssue)) {
    return PathPatternPresetReadinessStatus.blocked;
  }
  return PathPatternPresetReadinessStatus.needsReview;
}

bool _isBlockingIssue(PathPatternPresetIssueCode issue) {
  return switch (issue) {
    PathPatternPresetIssueCode.missingBasePathPreset => true,
    PathPatternPresetIssueCode.duplicatePathPatternId => true,
    PathPatternPresetIssueCode.duplicateBasePathPresetId => true,
  };
}

PathPatternEditorSummary _summaryForCards(
  List<PathPatternPresetCardModel> cards,
) {
  return PathPatternEditorSummary(
    totalCount: cards.length,
    readyCount: cards
        .where((card) => card.status == PathPatternPresetReadinessStatus.ready)
        .length,
    issueCount: cards.where((card) => card.issues.isNotEmpty).length,
    multiCellCenterCount: cards
        .where((card) => card.centerWidth > 1 || card.centerHeight > 1)
        .length,
    transparentColorCount:
        cards.where((card) => card.transparentColorHex != null).length,
    missingBasePathPresetCount: cards
        .where(
          (card) => card.issues.contains(
            PathPatternPresetIssueCode.missingBasePathPreset,
          ),
        )
        .length,
    duplicatePathPatternIdCount: cards
        .where(
          (card) => card.issues.contains(
            PathPatternPresetIssueCode.duplicatePathPatternId,
          ),
        )
        .length,
    duplicateBasePathPresetIdCount: cards
        .where(
          (card) => card.issues.contains(
            PathPatternPresetIssueCode.duplicateBasePathPresetId,
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
